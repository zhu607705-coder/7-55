import test from "node:test";
import assert from "node:assert/strict";
import { buildApp, ServiceUnavailable } from "../apps/api/dist/app.js";
import { readConfig } from "../apps/api/dist/config.js";
import { chapterListSchema, errorSchema } from "@755/contracts";

test("HTTP contracts, real catalog reads, unknown/write routes and error redaction", async (t) => {
  let calls = 0;
  let failure;
  const app = await buildApp({
    catalog: {
      async listPublicChapters() {
        calls++;
        if (failure) throw failure;
        return [];
      },
    },
    checkReady: async () => {
      if (failure) throw failure;
    },
  });
  t.after(() => app.close());
  assert.equal((await app.inject("/api/health")).statusCode, 200);
  assert.equal((await app.inject("/api/ready")).statusCode, 200);
  const catalog = await app.inject("/api/v1/chapters");
  assert.deepEqual(chapterListSchema.parse(catalog.json()), { items: [] });
  assert.equal(calls, 1);
  assert.equal(catalog.headers["cache-control"], "no-store");
  assert.ok(catalog.headers["x-request-id"]);
  assert.equal(catalog.headers["x-content-type-options"], "nosniff");
  assert.equal(catalog.headers["x-frame-options"], "DENY");
  for (const url of ["/api/v1/ideas", "/api/unknown", "/assets/missing.js"]) {
    const result = await app.inject(url);
    assert.equal(result.statusCode, 404);
    assert.equal(errorSchema.parse(result.json()).error.code, "NOT_FOUND");
  }
  assert.equal(
    (
      await app.inject({
        method: "POST",
        url: "/api/v1/chapters",
        payload: { is_public: true },
      })
    ).statusCode,
    404,
  );
  failure = new ServiceUnavailable(
    "postgresql://secret:password@private-host/db",
  );
  for (const url of ["/api/ready", "/api/v1/chapters"]) {
    const result = await app.inject(url);
    assert.equal(result.statusCode, 503);
    assert.equal(
      errorSchema.parse(result.json()).error.code,
      "SERVICE_UNAVAILABLE",
    );
    assert.doesNotMatch(result.body, /secret|password|private-host/);
  }
  assert.equal((await app.inject("/api/health")).statusCode, 200);
  failure = new Error("private implementation detail");
  const unexpected = await app.inject("/api/v1/chapters");
  assert.equal(unexpected.statusCode, 500);
  assert.doesNotMatch(unexpected.body, /private implementation/);
});

test("production serves built web files without swallowing missing APIs", async (t) => {
  const app = await buildApp({
    serveWeb: true,
    catalog: { listPublicChapters: async () => [] },
    checkReady: async () => {},
  });
  t.after(() => app.close());
  const index = await app.inject("/");
  assert.equal(index.statusCode, 200);
  assert.match(index.body, /共创平台/);
  assert.match(
    index.headers["content-security-policy"],
    /frame-ancestors 'none'/,
  );
  assert.match(index.headers["content-security-policy"], /object-src 'none'/);
  const asset = index.body.match(/src="([^\"]+\.js)"/)[1];
  assert.equal((await app.inject(asset)).statusCode, 200);
  assert.equal((await app.inject("/api/missing")).statusCode, 404);
});

test("environment validation fails closed without disclosing supplied values", () => {
  assert.equal(readConfig({}).port, 3001);
  assert.throws(() => readConfig({ NODE_ENV: "production" }), /DATABASE_URL/);
  assert.throws(() => readConfig({ PORT: "0" }), /PORT/);
  assert.throws(
    () => readConfig({ DATABASE_URL: "https://secret-value" }),
    (error) => !error.message.includes("secret-value"),
  );
  assert.throws(() => readConfig({ SERVE_WEB: "yes" }), /SERVE_WEB/);
  const production = {
    NODE_ENV: "production",
    DATABASE_URL: "postgresql://localhost/platform",
  };
  assert.throws(() => readConfig(production), /PUBLIC_ORIGIN/);
  for (const origin of [
    "https://example.test/",
    "https://example.test/path",
    "https://example.test?query=1",
    "https://user:private@example.test",
    "ftp://example.test",
  ]) {
    assert.throws(
      () => readConfig({ ...production, PUBLIC_ORIGIN: origin }),
      (error) =>
        /PUBLIC_ORIGIN/.test(error.message) &&
        !error.message.includes("private"),
    );
  }
  assert.throws(
    () => readConfig({ ...production, PUBLIC_ORIGIN: "http://example.test" }),
    /HTTPS/,
  );
  assert.throws(() => readConfig({ TRUST_PROXY: "true" }), /TRUST_PROXY/);
  const secure = readConfig({
    ...production,
    PUBLIC_ORIGIN: "https://community.example.test",
    TRUST_PROXY: "1",
  });
  assert.equal(secure.secureCookies, true);
  assert.equal(secure.trustProxy, 1);
  const local = readConfig({
    ...production,
    PUBLIC_ORIGIN: "http://127.0.0.1:3001",
  });
  assert.equal(local.secureCookies, false);
  assert.equal(local.trustProxy, false);
});

test("Authing configuration is optional as a unit, secrets stay server-side and unsafe links are rejected", () => {
  assert.equal(
    readConfig({
      AUTHING_ISSUER: "",
      AUTHING_CLIENT_ID: "",
      AUTHING_CLIENT_SECRET: "",
    }).authing,
    undefined,
  );
  assert.throws(
    () => readConfig({ AUTHING_CLIENT_ID: "private-client-id" }),
    /all three/,
  );
  const base = {
    AUTHING_ISSUER: "https://campus.authing.cn/oidc",
    AUTHING_CLIENT_ID: "app",
    AUTHING_CLIENT_SECRET: "secret",
  };
  assert.equal(readConfig(base).authing.issuer, base.AUTHING_ISSUER);
  for (const issuer of [
    "http://campus.authing.cn/oidc",
    "https://user:private@campus.authing.cn/oidc",
    "https://campus.authing.cn/oidc/",
    "https://campus.authing.cn/oidc?secret=1",
  ])
    assert.throws(
      () => readConfig({ ...base, AUTHING_ISSUER: issuer }),
      (error) =>
        /AUTHING_ISSUER/.test(error.message) &&
        !error.message.includes("private"),
    );
  assert.throws(
    () => readConfig({ GAME_URL: "javascript:alert(1)" }),
    /GAME_URL/,
  );
  assert.equal(
    readConfig({ OPERATOR_SUBJECTS: "one, two ," }).operators.join(","),
    "one,two",
  );
});

test("optional local game files keep exact routing and game-specific engine policy", async (t) => {
  const { mkdtemp, writeFile, rm } = await import("node:fs/promises");
  const { tmpdir } = await import("node:os");
  const { join } = await import("node:path");
  const directory = await mkdtemp(join(tmpdir(), "755-game-routing-"));
  t.after(() => rm(directory, { recursive: true, force: true }));
  await writeFile(join(directory, "build-manifest.json"), JSON.stringify({ cloudSaves: { file: "cloud-saves.js" } }));
  await writeFile(join(directory, "index.html"), "routing fixture only");
  const app = await buildApp({ serveWeb: true, gameExportDir: directory,
    catalog: { listPublicChapters: async () => [] }, checkReady: async () => {} });
  t.after(() => app.close());
  assert.equal((await app.inject("/game")).statusCode, 302);
  const game = await app.inject("/game/");
  assert.equal(game.body, "routing fixture only");
  assert.match(game.headers["content-security-policy"], /'unsafe-eval'/);
  assert.doesNotMatch((await app.inject("/")).headers["content-security-policy"], /'unsafe-eval'/);
  assert.equal((await app.inject("/game/missing.pck")).statusCode, 404);
  assert.equal((await app.inject("/game/../../secret.env")).statusCode, 404);
  assert.equal((await app.inject("/api/v1/me/game-save")).statusCode, 404);
  const local = readConfig({ LOCAL_GAME_EXPORT_DIR: directory, PUBLIC_ORIGIN: "http://127.0.0.1:3001" });
  assert.equal(local.gameUrl, "http://127.0.0.1:3001/game/");
  assert.throws(() => readConfig({ NODE_ENV: "production", LOCAL_GAME_EXPORT_DIR: directory }), /development-only/);
});
