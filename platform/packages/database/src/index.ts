import pg from "pg";
import { chapterSchema, type Chapter } from "@755/contracts";
export { migrate, readMigrations, assertMigrationsCurrent } from "./migrate.js";

export function createPool(
  connectionString: string,
  options: Partial<pg.PoolConfig> = {},
) {
  const pool = new pg.Pool({
    connectionString,
    max: 5,
    connectionTimeoutMillis: 3000,
    idleTimeoutMillis: 10_000,
    statement_timeout: 5000,
    ...options,
  });
  // Idle-client failures should not become an uncaught EventEmitter error.
  pool.on("error", () =>
    console.error("A platform database connection was lost."),
  );
  return pool;
}

export async function listPublicChapters(pool: pg.Pool): Promise<Chapter[]> {
  const result = await pool.query(`
    SELECT id, title, description, sort_order AS "sortOrder", kind
    FROM chapters WHERE is_public = true ORDER BY sort_order, id
  `);
  return result.rows.map((row: unknown) => chapterSchema.parse(row));
}
export type DatabasePool = pg.Pool;
export { createGameSaveStore, type GameSaveStore, validateSaveBundle, validateSaveImage } from "./game-saves.js";
export {
  createCommunityStore,
  CommunityError,
  type CommunityStore,
  type AuthTransaction,
} from "./community.js";
