# Co-creation platform boundaries

This platform collects player ideas and informs future 7:55 chapters. Root submission rules remain applicable.

- Work in `platform/`. Root docs and product-routing workflows are shared infrastructure; coordinate changes there explicitly.
- `apps/web` owns browser UI; `apps/api` owns HTTP, permissions and business services. `packages/contracts` contains browser-safe schemas. `packages/database` is server-only and owns SQL migrations.
- Never import game state, saves, controllers, source story JSON or game asset trees at runtime. Public chapter metadata is maintained independently; do not expose puzzle solutions or unpublished content. The user's 2026-10-23 pixel-style redesign permits curated, copied public visual assets and fonts with source provenance and licenses under `apps/web/public/`; these must not introduce a game build dependency.
- Use the Node built-in test runner, real Fastify injection and disposable PostgreSQL integration tests. No test-only framework dependency is needed.
- `npm run validate` checks import boundaries, builds/typechecks all workspaces and runs behavioral tests. `TEST_DATABASE_URL=... npm run test:database` exercises actual migrations and database-backed API behavior. Tests must never reset a shared or production schema.
- Do not fabricate accounts, votes, official chapter plans or release claims for the UI. Loading, empty and unavailable states must be distinct. Authentication and write routes stay absent until implemented and tested together.
- Append migrations; never edit an applied migration. Never migrate automatically on API startup. No credentials or generated output in Git.
- Build only directories needed now. Do not create empty feature modules or placeholder endpoints that pretend to work.
