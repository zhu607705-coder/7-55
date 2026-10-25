# Native validation: stages, safe concurrency and evidence

The runner defaults to **full**, with **2 workers**. `NATIVE_TEST_JOBS=1..4`
is an explicit cap, not a promise that four heavy engines are faster. Do not run
heavy bundlers/import/export jobs against the same writable project concurrently.
`user://` isolation does **not** isolate `res://`, fixtures or `.godot`.

```text
source sync → complete media conversion/receipt
                       ↓
mandatory preflight: prepared inputs → save isolation → import/parse
                    → startup → every GDScript parses
                       ↓
selected fixture producers (exclusive, ordered)
                       ↓
selected GD readers (continuous bounded workers)
                       ↓
source/persistence checks (exclusive)
                       ↓
full final acceptance; separate browser/GPU/export gates still required
```

`sync_source.mjs`, `convert_media.sh` and `validate_native.mjs` share one atomic
workspace lock. A second operation fails, rather than touching the live project's
outputs. An interrupted owner can leave a lock: inspect
`.validation/runner.lock/owner.*`, verify the process is stopped, then remove that
lock deliberately. Do not auto-delete a lock by age. Independent worktrees must
have independent writable generated assets and import caches (not hardlinks).

## Commands and scope

Prepare a Git checkout once, then repeat preparation when its inputs change:

```sh
npm ci --ignore-scripts
npm run native:sync
npm run native:media
export GODOT_BIN=/absolute/path/to/pinned/Godot_4.7.1
export GODOT_TEST_REPORT=/absolute/path/outside-repo/native-report.json
node godot_native/tools/validate_native.mjs --profile north-targeted --plan
node godot_native/tools/validate_native.mjs --profile north-targeted
node godot_native/tools/validate_native.mjs --profile north --resume
node godot_native/tools/validate_native.mjs --profile full --resume
```

| Profile | Selected coverage beyond mandatory preflight |
| --- | --- |
| `preflight` | None; useful for finding setup/parse failures first |
| `north-targeted` | Four exact `test_north_*` object/preview regressions |
| `north` | Those four plus explicit world, collision, picking, movement, lifecycle and mobile-floor checks |
| `changed` | Explicit test IDs, known module mapping and producer dependencies; unknown/shared runtime changes escalate to full |
| `full` (default) | Every registered native stage; final local acceptance scope |

`--plan` and `--list` print JSON and execute **nothing**. All planned rows say
`not-run`, never pass. Each profile retains preflight; later profiles can reuse
eligible successful stages only under the exact identity rules below.

```sh
# Exact stage IDs, not a substring such as “north” (which also matches BUCT).
node godot_native/tools/validate_native.mjs --profile changed \
  --test 'Source oracle tests/verify_source_model_parity.mjs' --plan
node godot_native/tools/validate_native.mjs --profile changed \
  --changed-file godot_native/scripts/objects/north_prop_scene.gd --plan
# Includes base-to-worktree tracked changes and new nonignored files.
node godot_native/tools/validate_native.mjs --profile changed \
  --changed-since COMMIT --plan
```

The audited north mapping is deliberately small. `world.gd` has 48 direct GD
consumers; edits to it, state/save/shared code, new helpers or unclassified paths
fall back to full. A narrow north run is useful early feedback, **not** evidence
that a shared world change needs only north tests. Full remains required before
final acceptance, including when a user supplies an incomplete changed-file list.

`--filter REGEX` is retained as a **raw diagnostic**. It cannot be combined with
profile/changed/test selection. It does not add preflight or producer closure,
and can read existing fixtures. It always reports partial evidence, even when the
regex matches every stage. Use formal profiles for acceptance.

## Prepared inputs and dependency order

Preflight compares every source asset with its manifest and copied bytes, source
JSON after authored Chinese revisions, initial state and item catalog. Complete
media conversion now writes `.validation/media-prepared.json`; preflight checks
converter/source/output hashes and both complete-stream receipts. Mere `.ogv`
existence is insufficient. An older prepared checkout without the receipt must
run `native:media` once; this patch does not synthesize provenance for old files.

The explicit producer manifest is in `native_validation_plan.mjs`; output hashes
are in `native_validation_identity.mjs`. No inferred whole-program graph is used.

| Producer and output | Proven consumer examples |
| --- | --- |
| `test_canteen_defense.gd:22,51`: `fixtures/canteen_defense.json`, `canteen_defense_snapshots.json` | `smoke_canteen_defense_ui.gd:22`; `test_canteen_defense_owners.gd:54`; `test_canteen_defense_world_return.gd:20`; `test_canteen_paper_effects.gd:110`; victory camera/pose; `test_chapter3.gd:86`; `test_chapter3_narrative.gd:114`; defense/paper-effects source oracles |
| `test_minigame_models.gd:42,52,81,129–130`: chase, four rhythm and four kayak JSON traces | `test_bike_chase_arrival.gd:26`; `test_mobile_bike_chase.gd:99`; `test_native_chase_integration.gd:102`; `test_lake_fishing_water.gd:74`; `test_qizhen_branches.gd:54`; `test_chapter3.gd:100,204`; `verify_source_model_parity.mjs:13,18` |
| `export_lake_live_source_fixtures.mjs:45`: `fixtures/lake_live_source.json` | `test_lake_live_world.gd:50` |

The lake exporter ignores `--check` and writes; it now runs exclusively **before**
its readers. Some native consumers previously sorted before their producer.
Selected producers now run first in authored relative order. A producer failure
blocks dependent consumers instead of allowing stale fixtures to pass. The
historical photo-consumer barrier is retained conservatively; its checked-in
fixture is read-only in this tree. Independent failures do not erase unrelated
coverage. Mandatory-preflight failure blocks the remaining selected stages.

## Resume is evidence reuse, not label reuse

Reports remain JSON row arrays with a schema-2 `.meta.json` sidecar. Each row has
an explicit `result`: `not-run`, `pass`, `failed`, `blocked`, or `deduplicated`.
`reused: true` identifies an earlier pass reused under the same identity. The
summary distinguishes selected coverage from the complete catalog;
`fullSuitePassed` cannot be true for a filtered or narrow run.

Preflight runs on every formal attempt. Reuse then requires identical:

- tracked **and untracked** relevant source/test/runner bytes, filenames and modes;
- generated assets/data, imported resources and actual Node dependency bytes;
- Godot executable hash/version, Node/Python/Bash executable identities, platform;
- effective command arguments, worker count and environment-value hash;
- required producer output bytes (missing or changed outputs invalidate reuse).

The environment itself is not written to the report, only its hash. Known
externally supplied fixture/source/output controls deny resume and force serial
execution; external Node/Python/LD loaders deny resume as well. CI run metadata
stays fingerprinted but does not force serial execution. No blanket `GITHUB_*`
exemption is used. Legacy label-only reports are refused. Mismatches are refused
without overwriting the prior report. Use a new report for changed content.
A final input recheck detects mutation during execution, invalidates reuse and
fails exact-content completion. This is intentionally conservative, not a general
build cache. Content hashing costs time; do not claim it is free.

## Removed repetition, not regression coverage

Native CI no longer repeats six deterministic catalog `--check` commands and the
two source replay oracles already owned by the native runner. The save-normalizer
build, audio generation/diff guard and lake preparation remain distinct.
`test_buct_haidian.gd` and `test_buct_rongmao.gd` are audited byte-identical and do
not inspect their own path. When both match the audited SHA-256, only the Haidian
entry executes; the other reports `deduplicated` with its evidence owner. Both
files remain. Any byte divergence executes both again. GPU, exported-PCK,
ordinary browser, mobile, library and streaming-failure/retry gates are retained.

## Validation of this change (2026-10-25)

- Deterministic Node tests cover slot refill, caps 1–4, ordered exclusive writers,
  failure drain/blocking, profile closure/full fallback, new-file/input/environment/
  executable/args/producer mismatches, external input denial and workspace locks.
- Actual Godot `4.7.1.stable.official.a13da4feb`: save-isolation check passed in
  1,115 ms. Two real GD model tests passed with jobs=2: observation comparison
  started at `14:38:37.323Z` (1,215 ms); theater rehearsal at `14:38:37.340Z`
  (1,144 ms). Their overlap proves engine invocation through the pool. This was
  raw diagnostic coverage: **2 passed, 528 not-run**, not formal/full acceptance.
- That two-stage report took 12,110 ms overall, including strict input hashing.
  No full-suite speedup is claimed. Slot-refill improvement is deterministic
  scheduler evidence, not a fabricated gameplay benchmark.
- The unchanged gameplay base `a179494` / tree `e99f7a94` passed the **old** runner's
  529 stages in 3,235,450 ms (jobs=2). That is baseline evidence only, not a full
  execution of this new harness. Existing media was copied independently for the
  smoke; no media re-encode or bulk import was repeated. The new formal prepared
  input check correctly rejects the absent new media receipt in that old copy.
