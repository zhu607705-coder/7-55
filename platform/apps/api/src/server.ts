import {
  createPool,
  createCommunityStore,
  createGameSaveStore,
  listPublicChapters,
  assertMigrationsCurrent,
} from "@755/database";
import { buildApp, ServiceUnavailable } from "./app.js";
import { readConfig } from "./config.js";
import { createAuthingProvider } from "./modules/auth/authing.js";

async function main() {
  const config = readConfig();
  const pool = config.databaseUrl ? createPool(config.databaseUrl) : undefined;
  const app = await buildApp({
    logger: true,
    serveWeb: config.serveWeb,
    publicOrigin: config.publicOrigin,
    secureCookies: config.secureCookies,
    trustProxy: config.trustProxy,
    authing: config.authing ? createAuthingProvider(config.authing) : undefined,
    operators: config.operators,
    gameUrl: config.gameUrl,
    gameExportDir: config.gameExportDir,
    community: pool ? createCommunityStore(pool) : undefined,
    gameSaves: pool ? createGameSaveStore(pool) : undefined,
    catalog: {
      async listPublicChapters() {
        if (!pool) throw new ServiceUnavailable();
        try {
          return await listPublicChapters(pool);
        } catch {
          throw new ServiceUnavailable();
        }
      },
    },
    checkReady: async () => {
      if (!pool) throw new ServiceUnavailable();
      await assertMigrationsCurrent(pool);
    },
    close: async () => {
      await pool?.end();
    },
  });
  for (const signal of ["SIGINT", "SIGTERM"] as const) {
    process.once(signal, () => {
      void app.close().catch(() => {
        process.exitCode = 1;
      });
    });
  }
  try {
    await app.listen({ host: config.host, port: config.port });
  } catch (error) {
    await app.close();
    throw error;
  }
}

main().catch(() => {
  console.error(
    "Platform startup failed. Check configuration, build output and port availability.",
  );
  process.exitCode = 1;
});
