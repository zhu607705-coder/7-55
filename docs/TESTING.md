# Validation Strategy

The repository uses dependency-light executable contract validators rather than a Jest, Vitest, pytest, or unittest suite. Runtime and release validators use the existing TypeScript, Node, Vite, and browser toolchain. Python under `scripts/` is reserved for deterministic map and art generation or calibration.

Assertion counts are diagnostic output only. They do not represent line, branch, interaction, or user-journey coverage.

## Godot and retained-source validation (2026-10-22)

`main` now contains the Godot integration after the external merge of #105.
`.github/workflows/godot-native-ci.yml` pins Godot 4.7.1, synchronizes source
assets/state, checks catalogs, converts media, runs `validate_native.mjs`, and
checks selected original TypeScript models plus the registered GPU/PCK/replay
stages. Follow `godot_native/README.md` for prerequisites. Shared source/controller
changes require relevant checks in both runtimes.

The sections below describe the retained Web-source validators; they do not prove
that the production Godot WASM game works. `deploy-pages.yml` builds the actual
Godot 4.7.1 Web export with matching verified templates. Its PR path builds and
accepts the export without configuring or deploying Pages. Production publication
remains a separate guarded job for allowed release refs. The unchanged initial
payload and deferred-pack budgets are 100,000,000 and 24,000,000 bytes.

For the branch-consolidation candidate, the real-browser gate retains the ordinary
six-case acceptance, adds three `mobile-world` cases (including portrait/landscape
and DPR 1/3), and runs the existing deferred-transport failure/retry scenario.
Fixtures come from the native campaign controller recorder, with exact SHA and
scope recorded. Constructing these fixtures is not a browser four-chapter playthrough.
See `godot_native/docs/BRANCH_CONSOLIDATION.md` and each exact-head CI artifact for
what actually ran; adding a gate is not a passing result.

Native Linux headless tests, cross-exported Windows artifacts and emulated touch
checks do not establish Windows execution, physical phone acceptance or full
visual/manual chapter parity. Keep historical evidence under its original engine
and SHA; assertion totals alone are not acceptance evidence.

Native staging and safe concurrency are documented in [NATIVE_VALIDATION_STAGES.md](../godot_native/docs/NATIVE_VALIDATION_STAGES.md). `native:plan` is nonexecuting; the native runner keeps full as the default and rejects stale/label-only resume evidence.

## Canonical Web entry points

| Command | Use it when | Scope |
| --- | --- | --- |
| `npm run validate:quick` | Editing localized source, UI copy, task guidance, or DEV checkpoint metadata | TypeScript, exported text freshness, guidance ownership, checkpoint assignment |
| `npm run validate:critical` | Changing controllers, saves, shared input, bridges, progression, Phaser behavior, doors, or reality-mode rules | Executable gameplay and lifecycle contracts without rebuilding deliverables |
| `npm run validate:extended` | Auditing low-frequency authored content and generated assets | Text, guidance, DEV coverage, character silhouettes, Qizhen journal, stair materials |
| `npm run validate:release` | Preparing a delivery, PR, push, or offline artifact | Critical and repository contracts, media, maps, production build, Chromium smoke, single-file build and verification |

The suite catalog and execution order live in `scripts/run-validation-suite.mjs`. A validator is registered once and referenced by suite key; CI and local release validation call the same entry point. The single-file build command owns a 6144 MB Node heap budget because embedding the complete offline media set exceeds Node's default heap on clean GitHub runners.

## Blocking validation layers

Changes to the retained Web source, its build tools, shared assets/controllers,
root dependencies or unknown game inputs run `npm run validate:release`, which
contains the following layers. Native-only `godot_native/` changes and native-only
workflow changes do not rebuild the independent React/Phaser deliverable. They
still run the applicable native and actual Godot Web workflows. Manual Web CI
dispatch keeps the full release and extended suites available.
The shared button CSS and theater test driver under `godot_native/` are explicit
exceptions because retained Web imports them. Keep this shared-input list current
when adding another dependency across those directories.

The shared product classifier compares the PR base with the synthetic merge tree
that CI actually tests. A newer change on `main` is not attributed to an older PR
branch. Pushes compare before/after; missing comparison information runs all
products conservatively. Routing changes have executable Git-history fixtures.

For native, cross-PR and actual Godot Web checks, a newer commit on the same PR
cancels its obsolete run. Other PRs, mainline runs and Pages publication are not
cancelled. Actual browser cases, timeouts and final coverage requirements remain
unchanged. The four phone consumers use one receipt validator rather than four
copies of the same implementation.

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

The Chapter 4 screenshot waits for its `entry` warmup to be ready, the actual map and input to be live, and the blocking prologue overlay to leave. A canvas alone is insufficient; later `transport` preloading may continue in the background.

Chapter 3 and Chapter 4 states are external test fixtures, normalized through the real `SaveStore.save`/`load` transaction and placed in an isolated browser profile before boot. The production application loads them as ordinary version-35 saves; the smoke does not add a product test hook or use a checkpoint URL to establish progress. Every case also supplies a conflicting `devCheckpoint` URL and sends both developer keyboard shortcuts, asserting that the URL cannot change the loaded chapter and no developer panel or controller hook appears. Development entry remains limited to Vite development mode and its existing path restriction.

A fourth case boots a valid CC98 save with all eight legacy QA session records. It verifies that production removes only these temporary records, hides CC98 maintenance, persists the real exit button's transition to the phone home screen, and retains that transition after an actual reload. State-write tests separately construct the store before cleanup, prove the stale marker blocks subsequent saves, and verify that cleanup neither writes formal save bytes nor restores the QA backup.

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
| Retained Web build, root dependencies, release artifact | `npm run validate:release` | Direct-open final `demo/index.html` and complete navigation chain |
| CI routing or orchestration | Affected routing/workflow tests, including rejection cases | Run the changed workflows; preserve their existing gameplay cases and publication guards |

## Practical change, retry and merge rules

- Start with the observable risk and the affected consumers. Prioritize broken gameplay, saves, delivery or safety. Batch secondary differences; do not create a separate process for cosmetic issues.
- Choose validation from actual dependencies, not directory names alone. Native-only changes use native and real Godot Web checks. Retained-Web or shared inputs use the affected retained suite too; unknown dependencies stay conservative. Documentation-only changes need review, not an unrelated game rebuild.
- Match evidence to the claim. Script fixtures prove the harness; source counts and hashes prove inventory and identity. Changed interaction, lifecycle or save behavior needs real input, the resulting state and save/reload where relevant. Keep meaningful failure cases and complete affected coverage.
- Inspect the first failing step and its logs, report and screenshot before changing a gate. Separate a product defect, a wrong/stale test expectation and an infrastructure interruption. A timeout alone does not establish which one occurred. Fix the demonstrated cause; do not remove assertions or extend gameplay limits merely to get green.
- Retry only the affected job when evidence supports a transient interruption or a retry diagnostic. Reuse its explicitly identified producer and unchanged artifact hashes. Preserve the failed result. A changed implementation or harness requires a new-head run; an old pass is not evidence for new bytes. Do not repeatedly restart the full pipeline until it passes.
- Before merging, check the current head, current base and interacting PRs. The affected checks must cover their combined tree and must have finished successfully, with no missing/cancelled coverage or unresolved real blocker. Recheck an overlapping base update; do not repeat expensive validation just for metadata when the tested input tree is unchanged.
- CI success does not grant merge, deployment or access-change authority. Use the current task authorization, keep independent changes intact, and report the actual merged commit and any untested boundary. No extra approval document, fixed assertion total or duplicated source-string gate is required.

## Checks that do not justify their maintenance cost

- CSS or DOM snapshots that fail on harmless presentation changes without proving a product risk;
- source-string assertions where a controller, state transition, or built artifact can be executed directly;
- exact assertion, dialogue, task, or asset counts unless the count is an explicit product contract;
- large image, audio, or map regeneration on every PR when stable output contracts can be checked instead;
- duplicated Python test cases or a second test-only dependency stack for behavior already executable through Node and the production modules.

## Remaining gaps

The current suite still lacks an automated start-to-finish playthrough, reusable pointer and keyboard input replay inside Phaser, collision replay against rendered worlds, audio audibility verification, and automated Firefox/WebKit CI runs. These gaps require a release-grade browser harness with explicit runtime and artifact budgets. Until that harness exists, shared-shell, input, Phaser, collision, audio, and navigation changes require recorded real-browser checks in Blink, Gecko, and WebKit at the project viewport matrix.
