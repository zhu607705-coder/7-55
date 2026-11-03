import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import {
  createPool,
  createCommunityStore,
  createGameSaveStore,
  migrate,
  assertMigrationsCurrent,
  listPublicChapters,
} from "@755/database";
import { buildApp } from "../../apps/api/dist/app.js";
import { mockOidc } from "./oidc.mjs";
export const origin = "http://127.0.0.1:3001";
export const headers = { origin, "x-requested-with": "755-platform" };
export function request(app, method, url, payload, cookie, extra = {}) {
  return app.inject({
    method,
    url,
    ...(payload === undefined ? {} : { payload }),
    ...extra,
    headers: {
      ...(method === "GET" ? {} : headers),
      ...(cookie ? { cookie } : {}),
      ...extra.headers,
    },
  });
}
export const expectStatus = (response, status) => {
  assert.equal(response.statusCode, status, response.body);
  return response;
};
export function cookieFrom(response, name = "755_session") {
  const items = [response.headers["set-cookie"]].flat();
  const cookie = items.find((item) => item?.startsWith(name + "="));
  assert.ok(cookie, `Missing ${name} cookie: ${response.body}`);
  return cookie.split(";")[0];
}
export async function fixture(t, options = {}) {
  if (!process.env.TEST_DATABASE_URL)
    throw new Error("TEST_DATABASE_URL must be a disposable database.");
  const schema = "platform_community_test_" + randomUUID().replaceAll("-", ""),
    admin = createPool(process.env.TEST_DATABASE_URL);
  let pool, app, mock;
  t.after(async () => {
    await app?.close();
    await pool?.end();
    await mock?.close();
    try {
      await admin.query(`DROP SCHEMA IF EXISTS "${schema}" CASCADE`);
    } finally {
      await admin.end();
    }
  });
  await admin.query(`CREATE SCHEMA "${schema}"`);
  pool = createPool(process.env.TEST_DATABASE_URL, {
    options: `-c search_path=${schema}`,
  });
  await migrate(pool);
  mock = await mockOidc();
  const appOptions = {
    catalog: { listPublicChapters: () => listPublicChapters(pool) },
    community: createCommunityStore(pool),
    gameSaves: createGameSaveStore(pool),
    checkReady: () => assertMigrationsCurrent(pool),
    publicOrigin: origin,
    secureCookies: false,
    authing: mock.provider,
    operators: ["operator"],
    ...options,
  };
  app = await buildApp(appOptions);
  async function begin(returnTo = "/", cookie) {
    const res = expectStatus(
      await request(app, "POST", "/api/v1/auth/start", { returnTo }, cookie),
      200,
    );
    return {
      url: res.json().url,
      cookie: cookieFrom(
        res,
        options.secureCookies ? "__Host-755_auth" : "755_auth",
      ),
    };
  }
  async function login(subject = "student", claims = {}, returnTo = "/") {
    const start = await begin(returnTo),
      callback = mock.makeCode(start.url, subject, claims);
    const res = await request(
      app,
      "GET",
      callback.pathname + callback.search,
      undefined,
      start.cookie,
    );
    expectStatus(res, 302);
    if (res.headers.location.includes("authError"))
      throw new Error("Unexpected login rejection: " + res.headers.location);
    const cookie = cookieFrom(
      res,
      options.secureCookies ? "__Host-755_session" : "755_session",
    );
    const user = expectStatus(
      await request(app, "GET", "/api/v1/session", undefined, cookie),
      200,
    ).json().user;
    assert.ok(user);
    return { user, cookie, response: res };
  }
  return { app, pool, mock, schema, login, begin, appOptions };
}
export const input = (changes = {}) => ({
  title: "校园里的一个小故事",
  body: "刚考完试，自行车却怎么也骑不出教学楼。",
  chapterId: "general",
  category: "story",
  channel: "story",
  spoiler: false,
  anonymous: false,
  termsVersion: "2026-10-24",
  adaptationConsent: false,
  credit: { mode: "anonymous", name: "" },
  ...changes,
});
export async function publish(app, actor, changes = {}) {
  return expectStatus(
    await request(app, "POST", "/api/v1/ideas", input(changes), actor.cookie),
    201,
  ).json().idea;
}
export async function get(app, id, actor, reveal = false) {
  return expectStatus(
    await request(
      app,
      "GET",
      `/api/v1/ideas/${id}${reveal ? "?reveal=true" : ""}`,
      undefined,
      actor?.cookie,
    ),
    200,
  ).json().idea;
}
export async function list(app, query = "", actor) {
  return expectStatus(
    await request(
      app,
      "GET",
      "/api/v1/ideas" + query,
      undefined,
      actor?.cookie,
    ),
    200,
  ).json();
}
