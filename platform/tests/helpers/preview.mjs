// Explicit disposable browser acceptance server. Cannot start with production credentials alone.
import {
  createPool,
  createCommunityStore,
  createGameSaveStore,
  migrate,
  assertMigrationsCurrent,
  listPublicChapters,
} from "@755/database";
import { randomUUID } from "node:crypto";
import { readFile } from "node:fs/promises";
import { buildApp } from "../../apps/api/dist/app.js";
import { mockOidc } from "./oidc.mjs";
if (!process.env.TEST_DATABASE_URL)
  throw new Error(
    "Set TEST_DATABASE_URL to a disposable database for test preview.",
  );
const schema = "platform_browser_test_" + randomUUID().replaceAll("-", "");
const admin = createPool(process.env.TEST_DATABASE_URL);
await admin.query(`CREATE SCHEMA "${schema}"`);
const pool = createPool(process.env.TEST_DATABASE_URL, {
  options: `-c search_path=${schema}`,
});
let mock, app;
async function cleanup() {
  await app?.close();
  await mock?.close();
  await pool.end();
  await admin.query(`DROP SCHEMA "${schema}" CASCADE`);
  await admin.end();
}
try {
  await migrate(pool);
  mock = await mockOidc();
  app = await buildApp({
    catalog: { listPublicChapters: () => listPublicChapters(pool) },
    community: createCommunityStore(pool),
    gameSaves: createGameSaveStore(pool),
    checkReady: () => assertMigrationsCurrent(pool),
    // A different host keeps test cookies separate from the ordinary 127.0.0.1 preview.
    publicOrigin: "http://localhost:3101",
    authing: mock.provider,
    operators: ["operator"],
    serveWeb: true,
    gameExportDir: process.env.GAME_TEST_EXPORT_DIR,
    gameUrl: "http://localhost:3101/game/",
  });
  if (!process.env.GAME_TEST_EXPORT_DIR) {
  // Navigation acceptance fixture, explicitly not a Godot export or playable game.
  app.get("/game/", (_request, reply) => reply.type("text/html").send(`<!doctype html>
    <html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
    <title>仅测试：游戏导航适配</title><body><h1>仅测试：游戏导航适配</h1>
    <p>此页验证真实导航脚本与共享会话，不包含 Godot 引擎或游戏。</p>
    <button id="community-entry">共创平台 ↗</button><button id="account-entry">玩家账号</button>
    <canvas id="canvas" tabindex="0" aria-label="测试焦点目标"></canvas>
    <script src="/test-player-account.js"></script></body></html>`));
  app.get("/test-player-account.js", async (_request, reply) => reply.type("text/javascript").send(
    await readFile(new URL("../../../godot_native/web/player-account.js", import.meta.url), "utf8") + `
    document.getElementById('community-entry').addEventListener('click', () => window.__GODOT_755_ACCOUNT__.openCommunity());
    document.getElementById('account-entry').addEventListener('click', () => window.__GODOT_755_ACCOUNT__.showAccount());
    `,
  ));
  }
  await app.listen({ host: "127.0.0.1", port: 3101 });
  console.log(
    "Disposable browser test ready: http://localhost:3101 (mock identity provider, isolated schema and browser cookie host)",
  );
} catch (error) {
  await cleanup();
  throw error;
}
let stopping = false;
for (const signal of ["SIGINT", "SIGTERM"])
  process.on(signal, async () => {
    if (stopping) return;
    stopping = true;
    await cleanup();
    process.exit();
  });
