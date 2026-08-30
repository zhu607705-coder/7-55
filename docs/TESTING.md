# Validation Strategy

The repository uses dependency-light executable contract validators rather than a Jest, Vitest, pytest, or unittest suite. Runtime and release validators use the existing TypeScript, Node, Vite, and browser toolchain. Python under `scripts/` is reserved for deterministic map and art generation or calibration.

Assertion counts are diagnostic output only. They do not represent line, branch, interaction, or user-journey coverage.

## Canonical entry points

| Command | Use it when | Scope |
| --- | --- | --- |
| `npm run validate:quick` | Editing localized source, UI copy, task guidance, or DEV checkpoint metadata | TypeScript, exported text freshness, guidance ownership, checkpoint assignment |
| `npm run validate:critical` | Changing controllers, saves, shared input, bridges, progression, Phaser behavior, doors, or reality-mode rules | Executable gameplay and lifecycle contracts without rebuilding deliverables |
| `npm run validate:extended` | Auditing low-frequency authored content and generated assets | Text, guidance, DEV coverage, character silhouettes, Qizhen journal, stair materials |
| `npm run validate:release` | Preparing a delivery, PR, push, or offline artifact | Critical and repository contracts, media, maps, production build, Chromium smoke, single-file build and verification |

The suite catalog and execution order live in `scripts/run-validation-suite.mjs`. A validator is registered once and referenced by suite key; CI and local release validation call the same entry point. The single-file build command owns a 6144 MB Node heap budget because embedding the complete offline media set exceeds Node's default heap on clean GitHub runners.

## Blocking validation layers

Every pull request and every non-documentation push to `main` runs `npm run validate:release`, which contains the following layers.

### Critical gameplay behavior

```bash
npm run validate:critical
```

This suite executes production TypeScript through Vite SSR or esbuild and checks observable state transitions, rejected actions, idempotency, save/reload behavior, migration behavior, order independence, cancellation, retry, and failure recovery.

| Surface | Blocking behavior evidence |
| --- | --- |
| Chapter 2 | CC98 identity gate, bounded lockout, task handoff, save migration |
| Chapter 3 | Theater spotlight timing, Qizhen rain safety, fishing, swan pressure, order-independent tool branches |
| Chapter 3.5 | Parallel evidence orders, invalid attempts, persistence normalization |
| Cross-chapter RPG | Facing-agnostic interaction, light/dark order, door collision and occlusion, pursuit audio lifecycle |
| Chapter 4 | Warmup readiness, guard presentation isolation, effective interactions, story, topology, runtime, task closure |

### Repository contracts

The map, media, asset, topology, story, runtime, interaction, type-check, and artifact validators remain blocking. These protect authored datasets and deployment contracts. Source-text searches, exact counts, hashes, and file-shape checks belong to this layer and must not be described as gameplay coverage.

### Browser smoke

After the offline single file is built and structurally verified, `scripts/verify-browser-smoke.mjs` launches that exact `demo/index.html` through Vite preview and an available Chromium executable. Discovery covers explicit environment variables, the Playwright headless-shell cache, and common system Chrome, Chromium, or Edge locations. It checks:

- mobile phone boot at `390 × 844`;
- the Chapter 3 theater RPG checkpoint at `1440 × 900`;
- the Chapter 4 opening RPG checkpoint at `1440 × 900`;
- valid, non-trivial screenshots with the requested dimensions;
- distinct screenshots for distinct checkpoints.

The DOM is intentionally not dumped because serializing the 258 MB inline script would test browser-output throughput instead of game rendering. `verify:single` owns the HTML, title, inline-script, inline-style, and embedded-resource structure checks; the browser smoke owns visual boot and route differentiation for the same artifact. Together they prove offline-bundle startup and routing in Chromium. They do not establish full playthrough correctness, pixel-level visual equivalence, audio audibility, or Firefox and WebKit compatibility.

## Extended authoring audit

The manual `workflow_dispatch` run additionally executes:

```bash
npm run validate:extended
```

This suite checks generated text freshness, task-guidance ownership, developer checkpoint assignment, source-to-runtime character silhouettes, Qizhen journal authoring, and Chapter 4 stair-material integrity. These checks are valuable during content and asset audits. Running them manually avoids turning every implementation refactor into an expensive asset-authoring pass.

## What deserves executable validation

A blocking behavior validator should identify one product risk and include the relevant combinations of:

1. valid progression;
2. invalid or locked input with zero unintended writes;
3. repeated execution and idempotency;
4. save and reload;
5. legacy migration when stored formats are involved;
6. alternate action order when the design permits it;
7. cancellation, retry, or recovery for lifecycle-sensitive behavior.

Prefer exported models and controllers over source-code regular expressions. Use source scans only for repository policies that cannot be observed through runtime behavior. Avoid fixed assertion totals as a success criterion unless the exact cardinality is itself a published contract.

Prioritize these surfaces:

1. controller-owned progression, save normalization, migrations, and order-independent puzzle facts;
2. keyboard, pointer, touch, modal, DEV, visibility, shutdown, and scene-remount input lifecycles;
3. source-pixel collisions, reachable checkpoint spawns, doors, occlusion, and floor/map boundaries;
4. audio registration, cancellation, route transitions, and missing media;
5. direct `file://` startup, embedded resources, and the same runtime used by HTTP builds.

## Change-to-suite routing

| Changed area | Minimum local command | Additional evidence before delivery |
| --- | --- | --- |
| Copy, task hints, DEV catalog | `npm run validate:quick` | Browser inspection when layout or navigation changes |
| Controller, `GameState`, `SaveStore`, migration | `npm run validate:critical` | Save/reload and legacy-state browser scenario |
| Shared input, modal, shell, bridge, Phaser lifecycle | `npm run validate:critical` | Real keyboard and pointer/touch replay in Blink, Gecko, and WebKit |
| Collision, doors, projection, world bounds | Relevant contract validator plus `validate:critical` | Solid/clear source-pixel samples and real player-body movement |
| Audio manifest, voice, pursuit cues | Relevant audio verifier | Real browser unlock, cancel, route-exit, and audibility inspection |
| Generated text or authored visual asset | `npm run validate:extended` | Visual inspection of the changed scene or asset consumer |
| CI, build, dependencies, release artifact | `npm run validate:release` | Direct-open final `demo/index.html` and complete navigation chain |

## Checks that do not justify their maintenance cost

- CSS or DOM snapshots that fail on harmless presentation changes without proving a product risk;
- source-string assertions where a controller, state transition, or built artifact can be executed directly;
- exact assertion, dialogue, task, or asset counts unless the count is an explicit product contract;
- large image, audio, or map regeneration on every PR when stable output contracts can be checked instead;
- duplicated Python test cases or a second test-only dependency stack for behavior already executable through Node and the production modules.

## Remaining gaps

The current suite still lacks an automated start-to-finish playthrough, reusable pointer and keyboard input replay inside Phaser, collision replay against rendered worlds, audio audibility verification, and automated Firefox/WebKit CI runs. These gaps require a release-grade browser harness with explicit runtime and artifact budgets. Until that harness exists, shared-shell, input, Phaser, collision, audio, and navigation changes require recorded real-browser checks in Blink, Gecko, and WebKit at the project viewport matrix.
