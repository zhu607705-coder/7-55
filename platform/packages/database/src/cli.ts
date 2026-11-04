import { createPool, migrate } from "./index.js";

if (!process.env.DATABASE_URL) {
  console.error("Set DATABASE_URL before running platform migrations.");
  process.exitCode = 1;
} else {
  const pool = createPool(process.env.DATABASE_URL);
  try {
    const applied = await migrate(pool);
    console.log(
      applied.length
        ? `Applied: ${applied.join(", ")}`
        : "Database is up to date.",
    );
  } catch {
    console.error(
      "Migration failed. Check database access and migration history; no partial batch was committed.",
    );
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
}
