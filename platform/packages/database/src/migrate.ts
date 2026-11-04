import { createHash } from "node:crypto";
import { readdir, readFile } from "node:fs/promises";
import type pg from "pg";

export interface Migration {
  name: string;
  sql: string;
  checksum: string;
}
export async function readMigrations(
  directory = new URL("../migrations/", import.meta.url),
): Promise<Migration[]> {
  const names = (await readdir(directory))
    .filter((name) => /^\d{3}_[a-z0-9_]+\.sql$/.test(name))
    .sort();
  if (!names.length) throw new Error("No platform migrations found.");
  if (new Set(names.map((name) => name.slice(0, 3))).size !== names.length) {
    throw new Error("Migration numbers must be unique.");
  }
  return Promise.all(
    names.map(async (name) => {
      const sql = await readFile(new URL(name, directory), "utf8");
      return {
        name,
        sql,
        checksum: createHash("sha256").update(sql).digest("hex"),
      };
    }),
  );
}

function validateHistory(
  rows: { name: string; checksum: string }[],
  migrations: Migration[],
) {
  for (const [index, row] of rows.entries()) {
    const expected = migrations[index];
    if (
      !expected ||
      expected.name !== row.name ||
      expected.checksum !== row.checksum
    ) {
      throw new Error(
        "Migration history differs from this application. Do not edit applied SQL.",
      );
    }
  }
}

export async function assertMigrationsCurrent(pool: pg.Pool) {
  const migrations = await readMigrations();
  const { rows } = await pool.query<{ name: string; checksum: string }>(
    "SELECT name, checksum FROM platform_migrations ORDER BY name",
  );
  validateHistory(rows, migrations);
  if (rows.length !== migrations.length)
    throw new Error("Platform migrations are pending.");
}

export async function migrate(
  pool: pg.Pool,
  providedMigrations?: Migration[],
): Promise<string[]> {
  const migrations = providedMigrations ?? (await readMigrations());
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    // Transaction lock serializes runners, including initial history-table creation.
    await client.query("SELECT pg_advisory_xact_lock(755, 1)");
    await client.query(`CREATE TABLE IF NOT EXISTS platform_migrations (
      name text PRIMARY KEY, checksum text NOT NULL, applied_at timestamptz NOT NULL DEFAULT now()
    )`);
    const { rows } = await client.query<{ name: string; checksum: string }>(
      "SELECT name, checksum FROM platform_migrations ORDER BY name",
    );
    validateHistory(rows, migrations);
    const applied: string[] = [];
    for (const migration of migrations.slice(rows.length)) {
      await client.query(migration.sql);
      await client.query(
        "INSERT INTO platform_migrations (name, checksum) VALUES ($1, $2)",
        [migration.name, migration.checksum],
      );
      applied.push(migration.name);
    }
    await client.query("COMMIT");
    return applied;
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}
