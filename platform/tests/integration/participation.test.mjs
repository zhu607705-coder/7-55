import test from "node:test";
import assert from "node:assert/strict";
import { buildApp } from "../../apps/api/dist/app.js";
import {
  fixture,
  request,
  expectStatus,
  publish,
  get,
  list,
  input,
} from "../helpers/fixture.mjs";

const comments = (app, id, actor, query = "") =>
  request(
    app,
    "GET",
    `/api/v1/ideas/${id}/comments${query}`,
    undefined,
    actor?.cookie,
  );
const send = (app, id, actor, body) =>
  request(app, "POST", `/api/v1/ideas/${id}/comments`, { body }, actor?.cookie);

test("community: signed-in comments persist across API instances; anonymous author stays anonymous; validation and ownership hold", async (t) => {
  const { app, login, appOptions } = await fixture(t);
  const alice = await login("alice"),
    bob = await login("bob");
  const post = await publish(app, alice, { channel: "post", anonymous: true });
  expectStatus(await send(app, post.id, null, "游客不能发表评论"), 401);
  expectStatus(await send(app, post.id, bob, "  "), 400);
  expectStatus(await send(app, post.id, bob, "a".repeat(2001)), 400);
  expectStatus(
    await request(
      app,
      "POST",
      `/api/v1/ideas/${post.id}/comments`,
      { body: "错误来源不能提交" },
      bob.cookie,
      { headers: { origin: "https://untrusted.invalid" } },
    ),
    403,
  );
  const own = expectStatus(
    await send(app, post.id, alice, "作者来回复一下"),
    201,
  ).json().comment;
  assert.equal(own.author.id, null);
  assert.equal(own.author.nickname, "匿名作者");
  const comment = expectStatus(
    await send(app, post.id, bob, "这段解谜我也很喜欢！"),
    201,
  ).json().comment;
  assert.equal((await get(app, post.id)).commentCount, 2);
  const reopened = await buildApp(appOptions);
  try {
    const result = expectStatus(await comments(reopened, post.id), 200).json();
    assert.equal(result.total, 2);
    assert.equal(result.items[1].body, "这段解谜我也很喜欢！");
    assert.equal(result.items[0].author.id, null);
    assert.equal(result.items[0].canDelete, false);
  } finally {
    await reopened.close();
  }
  expectStatus(
    await request(
      app,
      "DELETE",
      `/api/v1/ideas/${post.id}/comments/${comment.id}`,
      {},
      alice.cookie,
    ),
    404,
  );
  expectStatus(
    await request(
      app,
      "DELETE",
      `/api/v1/ideas/${post.id}/comments/${comment.id}`,
      {},
      bob.cookie,
    ),
    200,
  );
  assert.equal((await get(app, post.id)).commentCount, 1);
  assert.equal(
    expectStatus(await comments(app, post.id), 200)
      .json()
      .items.some((c) => c.id === comment.id),
    false,
  );
});

test("comments respect spoiler, hidden and withdrawn parent visibility; operator deletion and pagination work", async (t) => {
  const { app, pool, login } = await fixture(t);
  const alice = await login("alice"),
    bob = await login("bob"),
    operator = await login("operator");
  const post = await publish(app, alice, { channel: "post", spoiler: true });
  const first = expectStatus(
    await send(app, post.id, bob, "这是剧透评论"),
    201,
  ).json().comment;
  assert.equal(
    expectStatus(await comments(app, post.id), 200).json().items.length,
    0,
  );
  assert.equal(
    expectStatus(await comments(app, post.id, null, "?reveal=true"), 200).json()
      .items.length,
    1,
  );
  assert.equal(
    expectStatus(await comments(app, post.id, alice), 200).json().items.length,
    1,
  );
  await pool.query(
    `INSERT INTO idea_comments(id,idea_id,author_id,body)
    SELECT gen_random_uuid(),$1,$2,'分页评论 '||n FROM generate_series(1,31) n`,
    [post.id, bob.user.id],
  );
  assert.equal(
    expectStatus(await comments(app, post.id, alice), 200).json().items.length,
    30,
  );
  assert.equal(
    expectStatus(await comments(app, post.id, alice, "?page=2"), 200).json()
      .items.length,
    2,
  );
  expectStatus(
    await request(
      app,
      "DELETE",
      `/api/v1/ideas/${post.id}/comments/${first.id}`,
      {},
      operator.cookie,
    ),
    200,
  );
  expectStatus(
    await request(
      app,
      "PUT",
      `/api/v1/operator/ideas/${post.id}/moderation`,
      { hidden: true, reason: "隐藏测试" },
      operator.cookie,
    ),
    200,
  );
  expectStatus(await comments(app, post.id, bob, "?reveal=true"), 404);
  expectStatus(
    await send(app, post.id, alice, "隐藏后作者也不能新增评论"),
    404,
  );
  expectStatus(
    await request(app, "DELETE", `/api/v1/ideas/${post.id}`, {}, alice.cookie),
    200,
  );
  expectStatus(await comments(app, post.id, operator, "?reveal=true"), 404);
});

test("two sections stay separate; suggestion votes are idempotent, cancellable and drive only ranking", async (t) => {
  const { app, login } = await fixture(t);
  const alice = await login("alice"),
    bob = await login("bob");
  const post = await publish(app, alice, {
    channel: "post",
    title: "游戏真好玩",
  });
  const legacy = await publish(app, alice, { channel: "story" });
  const first = await publish(app, alice, {
    channel: "suggestion",
    title: "增加双人合作解谜模式",
    category: "gameplay",
  });
  const second = await publish(app, alice, {
    channel: "suggestion",
    title: "增加校园雨夜支线剧情",
    category: "story",
  });
  assert.deepEqual(
    new Set((await list(app, "?section=community")).items.map((i) => i.id)),
    new Set([post.id, legacy.id]),
  );
  assert.deepEqual(
    new Set((await list(app, "?section=suggestions")).items.map((i) => i.id)),
    new Set([first.id, second.id]),
  );
  const vote = (id, actor, liked) =>
    request(app, "PUT", `/api/v1/ideas/${id}/like`, { liked }, actor.cookie);
  for (const result of await Promise.all(
    Array.from({ length: 8 }, () => vote(first.id, bob, true)),
  ))
    expectStatus(result, 200);
  assert.equal((await get(app, first.id)).likeCount, 1);
  expectStatus(await vote(first.id, alice, true), 200);
  expectStatus(await vote(second.id, bob, true), 200);
  assert.equal(
    (await list(app, "?section=suggestions&sort=likes")).items[0].id,
    first.id,
  );
  assert.equal((await get(app, first.id)).status, "received");
  expectStatus(await vote(first.id, bob, false), 200);
  expectStatus(await vote(first.id, alice, false), 200);
  assert.equal(
    (await list(app, "?section=suggestions&sort=likes")).items[0].id,
    second.id,
  );
  assert.equal((await get(app, first.id)).myLiked, false);
  expectStatus(
    await request(
      app,
      "POST",
      "/api/v1/ideas",
      input({ title: "短", channel: "suggestion" }),
      alice.cookie,
    ),
    400,
  );
});

test("nickname-only changes preserve existing reading progress and return the updated profile", async (t) => {
  const { app, login } = await fixture(t);
  const alice = await login("profile-test");
  expectStatus(
    await request(
      app,
      "PUT",
      "/api/v1/profile",
      { nickname: "原昵称", chapterId: "chapter-2" },
      alice.cookie,
    ),
    200,
  );
  const updated = expectStatus(
    await request(
      app,
      "PUT",
      "/api/v1/profile",
      { nickname: "新的公开昵称" },
      alice.cookie,
    ),
    200,
  ).json().user;
  assert.equal(updated.nickname, "新的公开昵称");
  assert.equal(updated.progressOrder, 20);
});
