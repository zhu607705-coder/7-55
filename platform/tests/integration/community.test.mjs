import test from "node:test";
import assert from "node:assert/strict";
import { createPool, createCommunityStore } from "@755/database";
import { buildApp } from "../../apps/api/dist/app.js";
import {
  fixture,
  request,
  expectStatus,
  cookieFrom,
  input,
  publish,
  get,
  list,
  origin,
  headers,
} from "../helpers/fixture.mjs";

test("hosted auth: signed code flow, stable identity, replay prevention and removed password endpoints", async (t) => {
  const { app, pool, mock, login, begin } = await fixture(t);
  for (const path of ["register", "login", "password"])
    expectStatus(await request(app, "POST", "/api/v1/auth/" + path, {}), 404);
  assert.equal(
    (await request(app, "GET", "/api/v1/auth/config")).json().configured,
    true,
  );
  const first = await login(
    "alice",
    {},
    "/?idea=11111111-1111-4111-8111-111111111111",
  );
  assert.match(first.response.headers.location, /\?idea=/);
  assert.match(String(first.response.headers["set-cookie"]), /HttpOnly/);
  expectStatus(
    await request(
      app,
      "PUT",
      "/api/v1/profile",
      { nickname: "校园投稿者", chapterId: "chapter-2" },
      first.cookie,
    ),
    200,
  );
  const again = await login("alice");
  assert.equal(again.user.id, first.user.id);
  assert.equal(again.user.nickname, "校园投稿者");
  assert.equal(again.user.progressOrder, 20);
  const another = await login("bob");
  assert.notEqual(another.user.id, first.user.id);
  const start = await begin(),
    callback = mock.makeCode(start.url, "replay");
  const success = expectStatus(
    await request(
      app,
      "GET",
      callback.pathname + callback.search,
      undefined,
      start.cookie,
    ),
    302,
  );
  assert.doesNotMatch(success.headers.location, /authError/);
  const before = mock.tokenCalls;
  const replay = expectStatus(
    await request(
      app,
      "GET",
      callback.pathname + callback.search,
      undefined,
      start.cookie,
    ),
    302,
  );
  assert.match(replay.headers.location, /authError=failed/);
  assert.equal(mock.tokenCalls, before);
  assert.equal(
    (
      await pool.query(
        "SELECT count(*)::int AS n FROM external_identities WHERE subject='replay'",
      )
    ).rows[0].n,
    1,
  );
  const columns = (
    await pool.query(
      "SELECT column_name FROM information_schema.columns WHERE table_schema=current_schema() AND table_name='members'",
    )
  ).rows.map((row) => row.column_name);
  assert.ok(!columns.includes("password_hash"));
  const sessions = (await pool.query("SELECT token_hash FROM sessions")).rows;
  assert.ok(sessions.every((row) => /^[a-f0-9]{64}$/.test(row.token_hash)));
  assert.ok(sessions.every((row) => !again.cookie.includes(row.token_hash)));
  assert.equal(again.user.isOperator, false);
});

test("hosted auth rejects tampered state, wrong browser, expired transactions and invalid token signatures or claims", async (t) => {
  const { app, pool, mock, begin } = await fixture(t);
  for (const claims of [
    { wrongSignature: true },
    { aud: "other-app" },
    { iss: "https://attacker.invalid/oidc" },
    { nonce: "wrong" },
    { exp: 1 },
  ]) {
    const start = await begin(),
      callback = mock.makeCode(start.url, "malicious", claims);
    const response = expectStatus(
      await request(
        app,
        "GET",
        callback.pathname + callback.search,
        undefined,
        start.cookie,
      ),
      302,
    );
    assert.match(response.headers.location, /authError=failed/);
    assert.ok(
      ![response.headers["set-cookie"]]
        .flat()
        .some((cookie) => /^755_session=[a-f0-9]{64}/.test(cookie)),
    );
  }
  for (const scenario of [
    "no-browser",
    "different-browser",
    "wrong-state",
    "duplicate-state",
    "expired",
    "bad-pkce",
  ]) {
    const start = await begin(),
      other = await begin(),
      callback = mock.makeCode(start.url, "not-signed-in");
    let cookie = start.cookie;
    if (scenario === "no-browser") cookie = undefined;
    if (scenario === "different-browser") cookie = other.cookie;
    if (scenario === "wrong-state")
      callback.searchParams.set("state", "0".repeat(64));
    if (scenario === "duplicate-state")
      callback.searchParams.append("state", callback.searchParams.get("state"));
    if (scenario === "expired")
      await pool.query(
        "UPDATE auth_transactions SET expires_at=now()-interval '1 second'",
      );
    if (scenario === "bad-pkce")
      await pool.query(
        "UPDATE auth_transactions SET verifier='wrong-verifier'",
      );
    assert.match(
      expectStatus(
        await request(
          app,
          "GET",
          callback.pathname + callback.search,
          undefined,
          cookie,
        ),
        302,
      ).headers.location,
      /authError=failed/,
      scenario,
    );
  }
  const start = await begin("/?entry=feedback"),
    state = new URL(start.url).searchParams.get("state");
  const cancelled = expectStatus(
    await request(
      app,
      "GET",
      `/api/v1/auth/callback?error=access_denied&state=${state}`,
      undefined,
      start.cookie,
    ),
    302,
  );
  assert.match(
    cancelled.headers.location,
    /entry=feedback.*authError=cancelled/,
  );
  assert.equal(
    (await pool.query("SELECT count(*)::int AS n FROM members")).rows[0].n,
    0,
  );
  for (const returnTo of [
    "https://evil.test",
    "//evil.test",
    "/api/v1/auth/callback",
    "/\\evil.test",
    "/\n",
  ])
    expectStatus(
      await request(app, "POST", "/api/v1/auth/start", { returnTo }),
      400,
    );
});

test("game login returns to the game and shares community identity and logout", async (t) => {
  const { app, login, begin } = await fixture(t);
  const fromGame = await login("shared-player", {}, "/game/?view=story#resume");
  assert.equal(fromGame.response.headers.location, origin + "/game/?view=story#resume");
  const fromCommunity = await login("shared-player");
  assert.equal(fromCommunity.user.id, fromGame.user.id);
  assert.equal(fromGame.user.isOperator, false);
  // Navigation changes the page, not the session cookie or the player's identity.
  const communitySession = expectStatus(await request(app, "GET", "/api/v1/session", undefined, fromGame.cookie), 200);
  assert.equal(communitySession.json().user.id, fromCommunity.user.id);
  expectStatus(await request(app, "POST", "/api/v1/auth/logout", {}, fromGame.cookie), 200);
  assert.equal((await request(app, "GET", "/api/v1/session", undefined, fromGame.cookie)).json().user, null);

  const cancelled = await begin("/game/?view=story#resume");
  const state = new URL(cancelled.url).searchParams.get("state");
  const back = expectStatus(await request(app, "GET", `/api/v1/auth/callback?error=access_denied&state=${state}`, undefined, cancelled.cookie), 302);
  assert.equal(back.headers.location, origin + "/game/?view=story&authError=cancelled#resume");
  for (const returnTo of ["/game/api", "/game-evil/", "/game//evil.test", "/game/../api/v1/session", "/game/%2f%2fevil.test", "https://evil.test/game/"])
    expectStatus(await request(app, "POST", "/api/v1/auth/start", { returnTo }), 400);
});

test("auth unavailable stays explicit; session revocation, expiration, operator allowlist and secure cookies", async (t) => {
  const { app, pool, login, appOptions, schema } = await fixture(t, {
    secureCookies: true,
  });
  const actor = await login("operator");
  assert.equal(actor.user.isOperator, true);
  assert.match(actor.cookie, /^__Host-755_session=/);
  assert.match(String(actor.response.headers["set-cookie"]), /; Secure/);
  const secondPool = createPool(process.env.TEST_DATABASE_URL, {
    options: `-c search_path=${schema}`,
  });
  const second = await buildApp({
    ...appOptions,
    community: createCommunityStore(secondPool),
    operators: [],
  });
  t.after(async () => {
    await second.close();
    await secondPool.end();
  });
  assert.equal(
    (
      await request(second, "GET", "/api/v1/session", undefined, actor.cookie)
    ).json().user.isOperator,
    false,
  );
  const out = expectStatus(
    await request(app, "POST", "/api/v1/auth/logout", {}, actor.cookie),
    200,
  );
  assert.match(out.json().redirectUrl, /login\/profile\/logout/);
  assert.doesNotMatch(out.body, /id_token|access_token|test-secret/);
  assert.equal(
    (
      await request(second, "GET", "/api/v1/session", undefined, actor.cookie)
    ).json().user,
    null,
  );
  const expired = await login("expired");
  await pool.query("UPDATE sessions SET expires_at=now()-interval '1 second'");
  assert.equal(
    (
      await request(app, "GET", "/api/v1/session", undefined, expired.cookie)
    ).json().user,
    null,
  );
  const unconfigured = await buildApp({ ...appOptions, authing: undefined });
  t.after(() => unconfigured.close());
  assert.equal(
    (await request(unconfigured, "GET", "/api/v1/auth/config")).json()
      .configured,
    false,
  );
  expectStatus(
    await request(unconfigured, "POST", "/api/v1/auth/start", {
      returnTo: "/",
    }),
    503,
  );
  assert.equal(
    (await request(unconfigured, "GET", "/api/v1/ideas")).json().total,
    0,
  );
});

test("participation: one-line posts, separate channels, anonymous ownership and server-side spoiler protection", async (t) => {
  const { app, login } = await fixture(t),
    alice = await login("alice"),
    bob = await login("bob");
  const idea = await publish(app, alice, {
    body: "卡住了",
    title: "门",
    channel: "feedback",
    category: "experience",
    anonymous: true,
  });
  assert.equal(idea.author.id, null);
  assert.equal(idea.author.nickname, "匿名同学");
  assert.equal(idea.isOwner, true);
  const publicIdea = await get(app, idea.id);
  assert.equal(publicIdea.isOwner, false);
  assert.equal(publicIdea.credit, null);
  assert.equal(publicIdea.adaptationConsent, null);
  const publicBody = JSON.stringify(publicIdea);
  assert.ok(!publicBody.includes(alice.user.id));
  assert.ok(!publicBody.includes(alice.user.username));
  assert.equal((await list(app, "?mine=true", alice)).total, 1);
  assert.equal((await list(app, "?channel=feedback")).total, 1);
  const spoiler = await publish(app, alice, {
    title: "谜底唯一信号",
    body: "隐秘答案ABCD",
    spoiler: true,
  });
  const preview = await get(app, spoiler.id);
  assert.equal(preview.contentHidden, true);
  assert.equal(preview.body, "");
  assert.doesNotMatch(
    JSON.stringify(await list(app)),
    /隐秘答案ABCD|谜底唯一信号/,
  );
  assert.equal(
    (await list(app, "?q=" + encodeURIComponent("隐秘答案"))).total,
    0,
  );
  assert.equal((await get(app, spoiler.id, bob, true)).body, "隐秘答案ABCD");
  assert.equal((await get(app, spoiler.id, alice)).body, "隐秘答案ABCD");
  expectStatus(
    await request(app, "POST", "/api/v1/ideas", input(), undefined),
    401,
  );
  expectStatus(await request(app, "GET", "/api/v1/ideas?mine=true"), 401);
  for (const patch of [
    { termsVersion: "old" },
    { anonymous: "true" },
    { credit: { mode: "custom", name: "" } },
    { body: " " },
    { role: "operator" },
  ])
    expectStatus(
      await request(app, "POST", "/api/v1/ideas", input(patch), alice.cookie),
      400,
    );
});

test("chapter discussion never reaches an unreached reader, including detail, search, updates and reaction endpoints", async (t) => {
  const { app, pool, login } = await fixture(t),
    alice = await login("alice"),
    bob = await login("bob");
  expectStatus(
    await request(
      app,
      "PUT",
      "/api/v1/profile",
      { nickname: "已玩过的同学", chapterId: "chapter-2" },
      alice.cookie,
    ),
    200,
  );
  const idea = await publish(app, alice, {
    channel: "chapter",
    chapterId: "chapter-2",
    body: "第二章未读讨论内容",
  });
  assert.equal((await list(app, "?channel=chapter")).total, 0);
  assert.equal((await list(app, "?channel=chapter", bob)).total, 0);
  assert.equal(
    (await list(app, "?q=" + encodeURIComponent("第二章未读"), bob)).total,
    0,
  );
  for (const suffix of ["", "?reveal=true", "/updates", "/updates?reveal=true"])
    expectStatus(
      await request(
        app,
        "GET",
        `/api/v1/ideas/${idea.id}${suffix}`,
        undefined,
        bob.cookie,
      ),
      404,
    );
  for (const [kind, body] of [
    ["like", { liked: true }],
    ["rating", { score: 5 }],
  ])
    expectStatus(
      await request(
        app,
        "PUT",
        `/api/v1/ideas/${idea.id}/${kind}`,
        body,
        bob.cookie,
      ),
      404,
    );
  expectStatus(
    await request(
      app,
      "POST",
      "/api/v1/ideas",
      input({ channel: "chapter", chapterId: "chapter-2" }),
      bob.cookie,
    ),
    400,
  );
  const feedback = await publish(app, bob, {
    channel: "feedback",
    chapterId: "chapter-4",
  });
  assert.ok(feedback.id);
  expectStatus(
    await request(
      app,
      "PUT",
      "/api/v1/profile",
      { nickname: "读到第一章", chapterId: "chapter-1" },
      bob.cookie,
    ),
    200,
  );
  assert.equal((await list(app, "?channel=chapter", bob)).total, 0);
  expectStatus(
    await request(
      app,
      "PUT",
      "/api/v1/profile",
      { nickname: "读到第二章", chapterId: "chapter-2" },
      bob.cookie,
    ),
    200,
  );
  assert.equal((await list(app, "?channel=chapter", bob)).total, 1);
  expectStatus(
    await request(
      app,
      "PUT",
      "/api/v1/profile",
      { nickname: "不能绕过", chapterId: "future" },
      bob.cookie,
    ),
    400,
  );
  await pool.query("UPDATE chapters SET is_public=false WHERE id='chapter-2'");
  expectStatus(
    await request(
      app,
      "GET",
      `/api/v1/ideas/${idea.id}?reveal=true`,
      undefined,
      alice.cookie,
    ),
    404,
  );
});

test("operator workflow: role checks, consent gate, versioned updates, public credit choice and immutable production milestone", async (t) => {
  const { app, pool, login } = await fixture(t),
    alice = await login("alice"),
    bob = await login("bob"),
    ops = await login("operator");
  let idea = await publish(app, alice, { anonymous: true, spoiler: false });
  const update = (actor, status, extra = {}) =>
    request(
      app,
      "POST",
      `/api/v1/operator/ideas/${idea.id}/updates`,
      {
        expectedRevision: idea.revision,
        status,
        note: "具体处理说明",
        playUrl: null,
        version: null,
        ...extra,
      },
      actor.cookie,
    );
  expectStatus(
    await request(app, "GET", "/api/v1/operator/ideas", undefined, bob.cookie),
    403,
  );
  expectStatus(await update(bob, "discussion"), 403);
  expectStatus(
    await update(ops, "published", {
      playUrl: "https://game.example.test",
      version: "v1",
    }),
    409,
  );
  idea = expectStatus(
    await update(ops, "discussion", { spoiler: true }),
    200,
  ).json().idea;
  expectStatus(await update(ops, "production"), 409);
  expectStatus(
    await request(
      app,
      "PUT",
      `/api/v1/ideas/${idea.id}/permissions`,
      { adaptationConsent: true, credit: { mode: "custom", name: "便签同学" } },
      bob.cookie,
    ),
    409,
  );
  idea = expectStatus(
    await request(
      app,
      "PUT",
      `/api/v1/ideas/${idea.id}/permissions`,
      { adaptationConsent: true, credit: { mode: "custom", name: "便签同学" } },
      alice.cookie,
    ),
    200,
  ).json().idea;
  const stale = idea.revision - 1;
  expectStatus(
    await update(ops, "production", { expectedRevision: stale }),
    409,
  );
  idea = expectStatus(await update(ops, "production"), 200).json().idea;
  assert.equal(idea.hasProductionStarted, true);
  assert.equal(idea.canWithdraw, false);
  expectStatus(
    await request(app, "DELETE", `/api/v1/ideas/${idea.id}`, {}, alice.cookie),
    409,
  );
  expectStatus(await update(ops, "playable"), 400);
  expectStatus(
    await update(ops, "playable", {
      playUrl: "javascript:alert(1)",
      version: "v1",
    }),
    400,
  );
  idea = expectStatus(
    await update(ops, "playable", {
      playUrl: "https://game.example.test/try",
      version: "0.2 样段",
    }),
    200,
  ).json().idea;
  let timeline = expectStatus(
    await request(
      app,
      "GET",
      `/api/v1/ideas/${idea.id}/updates?reveal=true`,
      undefined,
      bob.cookie,
    ),
    200,
  ).json().items;
  assert.equal(timeline.at(-1).credit, "便签同学");
  assert.equal(timeline.length, 3);
  assert.deepEqual(
    (await request(app, "GET", `/api/v1/ideas/${idea.id}/updates`)).json(),
    { items: [] },
  );
  expectStatus(
    await request(
      app,
      "PUT",
      `/api/v1/ideas/${idea.id}/permissions`,
      { adaptationConsent: false, credit: { mode: "anonymous", name: "" } },
      alice.cookie,
    ),
    409,
  );
  idea = expectStatus(
    await request(
      app,
      "PUT",
      `/api/v1/ideas/${idea.id}/permissions`,
      { adaptationConsent: true, credit: { mode: "anonymous", name: "" } },
      alice.cookie,
    ),
    200,
  ).json().idea;
  timeline = (
    await request(app, "GET", `/api/v1/ideas/${idea.id}/updates?reveal=true`)
  ).json().items;
  assert.equal(timeline.at(-1).credit, null);
  idea = expectStatus(await update(ops, "production"), 200).json().idea;
  idea = expectStatus(await update(ops, "discussion"), 200).json().idea;
  assert.equal((await get(app, idea.id, alice)).canWithdraw, false);
  expectStatus(
    await request(app, "DELETE", `/api/v1/ideas/${idea.id}`, {}, alice.cookie),
    409,
  );
  assert.equal(
    (
      await pool.query(
        "SELECT count(*)::int AS n FROM permission_events WHERE idea_id=$1",
        [idea.id],
      )
    ).rows[0].n,
    3,
  );
});

test("moderation, withdrawal and business-write source checks protect every channel", async (t) => {
  const { app, pool, login } = await fixture(t),
    alice = await login("alice"),
    bob = await login("bob"),
    ops = await login("operator");
  const idea = await publish(app, alice);
  const routes = [
    ["POST", "/api/v1/auth/start", { returnTo: "/" }],
    ["POST", "/api/v1/auth/logout", {}],
    ["PUT", "/api/v1/profile", { nickname: "同学", chapterId: null }],
    ["POST", "/api/v1/ideas", input()],
    [
      "PUT",
      `/api/v1/ideas/${idea.id}/permissions`,
      { adaptationConsent: true, credit: { mode: "anonymous", name: "" } },
    ],
    ["PUT", `/api/v1/ideas/${idea.id}/like`, { liked: true }],
    ["PUT", `/api/v1/ideas/${idea.id}/rating`, { score: 5 }],
    ["DELETE", `/api/v1/ideas/${idea.id}`, {}],
    [
      "PUT",
      `/api/v1/operator/ideas/${idea.id}/moderation`,
      { hidden: true, reason: "隐私" },
    ],
  ];
  for (const [method, path, body] of routes)
    for (const bad of [
      { origin: "https://attacker.invalid" },
      { "x-requested-with": "wrong" },
    ])
      expectStatus(
        await request(app, method, path, body, ops.cookie, { headers: bad }),
        403,
      );
  expectStatus(
    await request(
      app,
      "PUT",
      `/api/v1/operator/ideas/${idea.id}/moderation`,
      { hidden: true, reason: "隐私" },
      bob.cookie,
    ),
    403,
  );
  expectStatus(
    await request(
      app,
      "PUT",
      `/api/v1/operator/ideas/${idea.id}/moderation`,
      { hidden: true, reason: "投稿涉及未授权的个人信息" },
      ops.cookie,
    ),
    200,
  );
  assert.equal((await list(app)).total, 0);
  expectStatus(await request(app, "GET", `/api/v1/ideas/${idea.id}`), 404);
  expectStatus(
    await request(
      app,
      "PUT",
      `/api/v1/ideas/${idea.id}/like`,
      { liked: true },
      alice.cookie,
    ),
    404,
  );
  assert.equal(
    (
      await request(app, "GET", "/api/v1/operator/ideas", undefined, ops.cookie)
    ).json().items[0].moderated,
    true,
  );
  assert.equal(
    (await pool.query("SELECT count(*)::int AS n FROM operator_audit")).rows[0]
      .n,
    1,
  );
  expectStatus(
    await request(
      app,
      "PUT",
      `/api/v1/operator/ideas/${idea.id}/moderation`,
      { hidden: false, reason: "已完成匿名化审核，恢复展示" },
      ops.cookie,
    ),
    200,
  );
  expectStatus(
    await request(app, "DELETE", `/api/v1/ideas/${idea.id}`, {}, bob.cookie),
    409,
  );
  expectStatus(
    await request(app, "DELETE", `/api/v1/ideas/${idea.id}`, {}, alice.cookie),
    200,
  );
  assert.equal((await list(app)).total, 0);
  expectStatus(
    await request(app, "GET", `/api/v1/ideas/${idea.id}/updates`),
    404,
  );
  assert.ok(
    (await pool.query("SELECT deleted_at FROM ideas WHERE id=$1", [idea.id]))
      .rows[0].deleted_at,
  );
});

test("concurrent likes/ratings, durable search, pagination, filtered rankings and rate limits", async (t) => {
  const { app, pool, login, begin } = await fixture(t),
    alice = await login("alice"),
    bob = await login("bob");
  const popular = await publish(app, alice),
    highest = await publish(app, bob, { title: "评分更高" });
  for (const response of await Promise.all(
    Array.from({ length: 8 }, () =>
      request(
        app,
        "PUT",
        `/api/v1/ideas/${popular.id}/like`,
        { liked: true },
        bob.cookie,
      ),
    ),
  ))
    expectStatus(response, 200);
  assert.equal((await get(app, popular.id, bob)).likeCount, 1);
  for (const response of await Promise.all(
    Array.from({ length: 6 }, () =>
      request(
        app,
        "PUT",
        `/api/v1/ideas/${popular.id}/rating`,
        { score: 4 },
        bob.cookie,
      ),
    ),
  ))
    expectStatus(response, 200);
  expectStatus(
    await request(
      app,
      "PUT",
      `/api/v1/ideas/${popular.id}/rating`,
      { score: 2 },
      alice.cookie,
    ),
    200,
  );
  assert.equal((await get(app, popular.id)).ratingAverage, 3);
  expectStatus(
    await request(
      app,
      "PUT",
      `/api/v1/ideas/${highest.id}/rating`,
      { score: 5 },
      alice.cookie,
    ),
    200,
  );
  assert.equal(
    (await list(app, "?sort=likes&channel=story")).items[0].id,
    popular.id,
  );
  assert.equal(
    (await list(app, "?sort=rating&channel=story")).items[0].id,
    highest.id,
  );
  expectStatus(
    await request(
      app,
      "PUT",
      `/api/v1/ideas/${popular.id}/rating`,
      { score: null },
      bob.cookie,
    ),
    200,
  );
  assert.equal((await get(app, popular.id)).ratingCount, 1);
  const store = createCommunityStore(pool);
  for (let i = 0; i < 13; i++)
    await store.create(
      alice.user.id,
      input({
        title: i === 0 ? "100% 完整校园" : "独立投稿 " + i,
        body: i === 1 ? "O'Reilly 的校园经历" : "另一个普通的校园故事",
      }),
    );
  const first = await list(app, "?sort=new&page=1"),
    second = await list(app, "?sort=new&page=2");
  assert.equal(first.total, 15);
  assert.equal(first.items.length, 12);
  assert.equal(second.items.length, 3);
  assert.equal(
    new Set([...first.items, ...second.items].map((item) => item.id)).size,
    15,
  );
  assert.equal((await list(app, "?q=%25")).total, 1);
  assert.equal(
    (await list(app, "?q=" + encodeURIComponent("o'reilly"))).total,
    1,
  );
  assert.equal((await store.get(popular.id, alice.user.id)).likeCount, 1);
  for (const query of [
    "?page=0",
    "?sort=wrong",
    "?channel=wrong",
    "?status=unknown",
    "?mine=1",
    "?injected=true",
  ])
    expectStatus(await request(app, "GET", "/api/v1/ideas" + query), 400);
  let limited;
  for (let n = 0; n < 350; n++) {
    const response = await request(
      app,
      "POST",
      "/api/v1/auth/start",
      { returnTo: "/" },
      undefined,
      { remoteAddress: "127.0.0.89" },
    );
    if (response.statusCode === 429) {
      limited = response;
      break;
    }
    expectStatus(response, 200);
  }
  assert.ok(limited);
  assert.ok(Number(limited.headers["retry-after"]) > 0);
  assert.ok(
    (await pool.query("SELECT key FROM request_limits")).rows.every((row) =>
      /^[a-f0-9]{64}$/.test(row.key),
    ),
  );
});
