import test from "node:test";
import assert from "node:assert/strict";
import { randomUUID, createHash } from "node:crypto";
import {
  createPool,
  migrate,
  readMigrations,
  assertMigrationsCurrent,
  listPublicChapters,
} from "@755/database";
import { buildApp, ServiceUnavailable } from "../../apps/api/dist/app.js";

if (!process.env.TEST_DATABASE_URL)
  throw new Error(
    "TEST_DATABASE_URL must point to a disposable PostgreSQL database.",
  );

test("real PostgreSQL: migrations, visibility, persistence, concurrent runners and rollback", async () => {
  const schema = `platform_test_${randomUUID().replaceAll("-", "")}`;
  const admin = createPool(process.env.TEST_DATABASE_URL);
  await admin.query(`CREATE SCHEMA "${schema}"`);
  const pool = createPool(process.env.TEST_DATABASE_URL, {
    options: `-c search_path=${schema}`,
  });
  let app;
  try {
    await assert.rejects(() => assertMigrationsCurrent(pool));
    const results = await Promise.all([migrate(pool), migrate(pool)]);
    assert.equal(results.flat().length, (await readMigrations()).length);
    assert.deepEqual(await migrate(pool), []);
    await assertMigrationsCurrent(pool);
    const chapters = await listPublicChapters(pool);
    assert.ok(chapters.some((chapter) => chapter.id === "future"));
    await pool.query(
      `INSERT INTO chapters (id,title,sort_order,kind) VALUES ('hidden-test','Unpublished test content',0,'chapter')`,
    );
    await pool.query(
      `UPDATE chapters SET description = 'Persisted public text' WHERE id = 'general'`,
    );
    app = await buildApp({
      catalog: {
        async listPublicChapters() {
          try {
            return await listPublicChapters(pool);
          } catch {
            throw new ServiceUnavailable();
          }
        },
      },
      checkReady: () => assertMigrationsCurrent(pool),
    });
    const response = await app.inject("/api/v1/chapters");
    assert.equal(response.statusCode, 200);
    assert.doesNotMatch(response.body, /Unpublished|hidden-test/);
    assert.match(response.body, /Persisted public text/);
    const secondPool = createPool(process.env.TEST_DATABASE_URL, {
      options: `-c search_path=${schema}`,
    });
    try {
      assert.ok(
        (await listPublicChapters(secondPool)).some(
          (chapter) => chapter.description === "Persisted public text",
        ),
      );
    } finally {
      await secondPool.end();
    }
    const original = await readMigrations();
    const changed = original.map((migration) => ({
      ...migration,
      checksum: "modified",
    }));
    await assert.rejects(() => migrate(pool, changed), /history differs/);
    const sql = "CREATE TABLE rollback_probe (id integer); SELECT 1/0;";
    const bad = {
      name: "999_rollback_probe.sql",
      sql,
      checksum: createHash("sha256").update(sql).digest("hex"),
    };
    await assert.rejects(() => migrate(pool, [...original, bad]));
    assert.equal(
      (await pool.query("SELECT to_regclass('rollback_probe') AS name")).rows[0]
        .name,
      null,
    );
    await assertMigrationsCurrent(pool);
    assert.equal((await app.inject("/api/ready")).statusCode, 200);
  } finally {
    await app?.close();
    await pool.end();
    await admin.query(`DROP SCHEMA "${schema}" CASCADE`);
    await admin.end();
  }
});

test("upgrade preserves legacy contributions while retiring password credentials and sessions", async () => {
  const schema = `platform_upgrade_test_${randomUUID().replaceAll("-", "")}`;
  const admin = createPool(process.env.TEST_DATABASE_URL);
  await admin.query(`CREATE SCHEMA "${schema}"`);
  const pool = createPool(process.env.TEST_DATABASE_URL, {
    options: `-c search_path=${schema}`,
  });
  try {
    const migrations = await readMigrations();
    await migrate(pool, migrations.slice(0, 2));
    const memberId = randomUUID(),
      ideaId = randomUUID();
    await pool.query(
      "INSERT INTO members(id,username,nickname,password_hash) VALUES($1,$2,$3,$4)",
      [memberId, "legacy_user", "已有投稿者", "old-password-hash"],
    );
    await pool.query(
      "INSERT INTO sessions(token_hash,member_id,expires_at) VALUES($1,$2,now()+interval '1 day')",
      ["a".repeat(64), memberId],
    );
    await pool.query(
      "INSERT INTO ideas(id,author_id,chapter_id,title,body,category) VALUES($1,$2,'general','原来的投稿','这份投稿在迁移之后也需要保留。','story')",
      [ideaId, memberId],
    );
    await migrate(pool, migrations);
    assert.equal(
      (await pool.query("SELECT count(*)::int AS n FROM sessions")).rows[0].n,
      0,
    );
    assert.equal(
      (await pool.query("SELECT nickname FROM members WHERE id=$1", [memberId]))
        .rows[0].nickname,
      "已有投稿者",
    );
    const idea = (
      await pool.query(
        "SELECT author_id,adaptation_consent,status FROM ideas WHERE id=$1",
        [ideaId],
      )
    ).rows[0];
    assert.equal(idea.author_id, memberId);
    assert.equal(idea.adaptation_consent, false);
    assert.equal(idea.status, "received");
    assert.equal(
      (await pool.query("SELECT count(*)::int AS n FROM external_identities"))
        .rows[0].n,
      0,
    );
    await assert.rejects(
      () => pool.query("SELECT password_hash FROM members"),
      (error) => error.code === "42703",
    );
  } finally {
    await pool.end();
    await admin.query(`DROP SCHEMA "${schema}" CASCADE`);
    await admin.end();
  }
});
