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
| `prepare` | Exact nine fresh preflight/fixture stages; only for sealed CI preparation, never full acceptance |
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
an explicit `result`: `not-run`, `pass`, `prepared`, `failed`, `blocked`, or `deduplicated`.
`prepared` means authenticated producer evidence, not a fresh consumer pass.
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
execution; external Node/Python/LD loaders deny resume as well. CI run metadata,
the separate Web tools' `CHROME_BIN`, and deployment host metadata `USER` stay
fingerprinted but do not force native serial execution. No blanket `GITHUB_*`
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

### Hosted checkpoint and default-environment correction

- Head `502e4b716ee16ece21def45cd4be35070d153011`, tree `d99bffd5`, passed all
  four workflows. Native run `40204036543` completed **529 passed + 1 audited
  deduplicated**, with zero failed, blocked or not-run stages. Exact-content
  completion passed; Web ordinary/streaming and all five profile jobs passed.
- Its report reveals **jobs=1**, not 2: the broad conservative scan mistook
  hosted `CHROME_BIN` and `USER` for native fixture controls. Their only actual
  consumers are separate browser tools and deployment host metadata. The narrow
  correction exempts exactly these two names; native external-input denial stays
  covered. The native catalog does not execute those browser/deployment tools.
- Preserve that hosted serial baseline: runner wall **3,209.184 s**, summed
  stage time **3,195.045 s**; 481 reader stages **2,757.655 s**, 48 exclusive
  stages **437.390 s**. Observed maximum concurrent stages was **1**. This is
  not evidence of a parallel speedup, and is not compared with another host.
- Correction checks: **17/17** runner contracts and a real pinned-engine smoke
  under `CI=true USER=runner CHROME_BIN=/usr/bin/google-chrome` passed. The two
  model stages started `15:49:23.155Z` / `15:49:23.182Z` and overlapped for
  **1,199 ms**; metadata records jobs=2. This remains **2 passed, 528 not-run**.
  A complete hosted run of the corrected parallel harness remains pending.


## Bounded full-suite CI sharding (2026-10-26 candidate)

```text
source contracts ──────────────────────────────────────────┐
source/media → nine fresh preparation stages → sealed inputs│
                                              ├→ shard 0 ─┤
                                              ├→ shard 1 ─┤
                                              ├→ shard 2 ─┤
                                              ├→ shard 3 ─┤
                                              ├→ shard 4 ─┤
                                              ├→ shard 5 ─┤
                                              ├→ shard 6 ─┤
                                              ├→ shard 7 ─┤
                                              └→ GPU/PCK ─┤
                                    exact full aggregate ←┘
```

The native catalog still has **530 unchanged stage descriptors**. Preparation
owns nine entries. Eight fixed standard-hosted jobs own the remaining entries,
exactly once. Each job has two continuous workers and its own checkout, imported
cache and user-data sandbox. Exclusive stages remain exclusive inside that job;
all shared fixture writers finish before any reader artifact is published.
The same original `native-parse-and-tests` required-check name is the final gate.

`native_validation_timings.json` records durations from successful baseline run
`40251695425`, head `bd0dfab34128c18436224aa539817e4fe9be9cf2`.
Deterministic partitioning balances predicted two-worker schedules, including
exclusive barriers. Durations affect placement only, never selection, timeouts
or success. New stages receive a conservative default estimate and stay covered.
The audited identical-script pair stays together. A new unprepared cross-shard
dependency fails planning rather than silently assuming it passed elsewhere.

```sh
# Inspection does not execute tests or require a prepared artifact.
node godot_native/tools/validate_native.mjs --profile prepare --plan
node godot_native/tools/validate_native.mjs --shard 0/8 --plan
```

Execution requires a same-run sealed bundle and explicit trusted producer SHA,
producer attempt and source head/base. `native_validation_bundle.mjs` hashes
all transported bytes and records source commit/tree, run/attempt, Godot binary,
preparation reports, imports and fixed producer outputs. The v2 transport keeps
its complete logical file inventory, but does not resend exact tracked native
files or source-synced assets already available in the exact-source checkout.
Each reference binds the source path, tracked commit, bytes/hash and file mode;
synced aliases also bind the checked-in asset manifest. Missing, mutated or
misdirected references fail: there is no remote fetch or unchecked fallback.
Consumers reconstruct with ordinary private copies, never shared hardlinks,
and verify the complete resulting project, including all borrowed bytes.
Consumers verify before restoration, restore signed file modes, rerun host save isolation, then require
an exact source/dependency/import hash and frozen fixture hash. Both are checked
again at completion. Imported preparations are `prepared`, not fabricated fresh
passes. Shards cannot combine with resume, filters or focused profiles, and
cannot claim `fullSuitePassed` independently.

`native_validation_aggregate.mjs` requires every dependency job to succeed,
validates the complete catalog/partition and each owned stage identity, and emits
one full report. Missing, extra, duplicate, failed, blocked, reused, mismatched,
stale-producer or changed-input evidence fails. Failed-job reruns may reuse
successful **same-run, same-producer** fragments from earlier consumer attempts.
For each shard, only its latest available attempt counts; an unsuccessful latest
attempt cannot fall back to an older pass. Re-running preparation creates a new
producer receipt, so old fragments cannot mix with its new inputs. Cancellation
or skipped required jobs cannot produce a green aggregate. No fail-fast matrix
cancellation hides independent diagnostics.

### Complete-workflow target and resource tradeoff

The corrected baseline completed all four workflows. Native report wall time was
**1,687.530 s (28m07.530s)**, and its complete workflow took **31m23s**.
Reader-pool cumulative work was 2,566.590 s, with 387.034 s in exclusive stages.
Godot Web's full workflow took **17m14s**: its build took 516 s and the slowest
retina world/phone consumer 513 s. These are hosted measurements, not local/remote
speedup comparisons.

First sharded hosted head `bd0dfab` completed native full acceptance in **13m01s**:
530 entries =529 fresh passes + one audited alias, no omitted entries or input
drift. All six reader jobs actually reached concurrency two. That is a complete
workflow comparison with31m23s, not a comparison with the28m07s runner-only time.
Godot Web took13m21s and **failed** its isolated cold C2 phone case. The screenshot
and snapshot show a still-blocking C2 download when the original phone tap was
sent. This is not a passing full validation result. Its aggregate correctly failed.
All four workflows consumed **101.15 observed runner-minutes**, versus78.82 in
the previous successful baseline; this failed attempt is not a billed-usage quote.
Concurrent PR176/177 jobs also delayed browser dispatch, but queue time alone does
not explain the miss: Web producer441s + longest consumer215s already exceeds10m.

The follow-on candidate is bounded to **eight native reader jobs and nine Web
input consumers**, plus one native GPU/PCK job. Two slots remain for retained Web
and cross-PR validation, for a maximum20 within these workflows. Source-contract
jobs finish before consumer fanout. Other PRs can still use the same account pool;
coordinate benchmark pushes rather than cancelling their required checks.
Native placement uses measured durations only. The historical six-shard golden
uses its recorded old timings; it does not freeze the live catalog or shard count.
No persistence stage is reclassified or removed for this change.

Web groups whole existing cases by observed duration, not viewport affinity.
Each case still starts a fresh Chromium process/profile, uses ordinary input,
and writes its original independent report and receipt. All **13 logical receipt
keys and17 reports** remain required. A failed first case cannot make an unrun
second case pass; independent diagnostics can continue after the first failure,
while the required aggregate rejects any failed/missing evidence. Consumers
sparsely check out the exact tools source, but still receive and verify the entire
sealed site and fixture inventory. Missing helper files fail the closure contract.

Two preparation overlaps do not remove an import or a test:

1. `prepare_import_media.mjs` copies the unchanged converter and both complete MP4
   inputs into a temporary media project. Its media install/conversion overlaps
   a **strict** preliminary import of the source project. Media outputs never
   enter that project until both children have closed, source hashes still match,
   and both full-stream output receipts validate. The original formal import/parse
   still runs after publication. Failure/cancellation joins peers and publishes no
   success receipt; missing-media diagnostics are not ignored. Only media files
   are isolated: the existing signed APT installer still changes system packages
   on this disposable runner. Cancelling the job/group can interrupt that install;
   no durable/user machine is used.
2. `build_web.mjs --prepare-controller-fixtures` starts the two original recorders
   only after export closes. They read the frozen source/import cache, use separate
   user-data/capture directories, and overlap post-export packing in its separate
   temporary project. Both close before build success or bundle sealing. This
   overlaps about29s of the observed packaging phase, **not** the following9s
   external content checks.

A bounded same-cloud preparation experiment observed strict cold import119.460s,
complete media conversion52.068s, and combined preparation99.237s plus the retained
final import7.309s. Thus observed sequential phases total171.528s versus106.546s
for the new shape. Execution order/OS cache and CPU contention confound the exact
speedup; these are not hosted full-workflow timings or an under10m claim. All engine
runs exited0 without SCRIPT ERROR/ERROR. The C2 readiness regression has28 pure
checks; local Chromium could not start because of a platform socket restriction,
so actual cold-C2 browser acceptance remains for the next exact-head hosted run.

HTTPS-first media provisioning retains signed/trusted APT sources, TLS and
signature checks. All jobs remain standard hosted runners, with no paid runner
purchase. Repository visibility is public; account-specific artifact storage
allowance remains unverified. The736,179,678-byte sealed Web artifact is retained
once for one day and downloaded nine times (~6.626GB). The777,665,242-byte measured
native transport is needed by eight readers plus GPU (~6.999GB); it still avoids
resending~1.115GB of exactly referenced source bytes per consumer. These measured
artifact sizes come from `bd0dfab`, not a promise that future content is identical.
Actual new compute, queue time and full required-gate wall time must be recorded
from its hosted run. **The under10m target is not yet achieved.**

The integrated Retina C2-only job retains an 18-minute job / 12-minute phone
acceptance step, without changing the other duration-balanced pairs. The actual
`f7de542` hosted C2 acceptance took 536 seconds (job 578 seconds), so the prior
eight-minute step would terminate real continuous input. This is a bounded budget
for that observed slow case, not a speedup or complete new-integration acceptance.
The stronger upstream readiness contract replaces the duplicate local wait; it
also checks the imported `native.scene` against the restored dorm and retains one
additional negative case (29 phone-shard contracts). Ordinary phone visibility
still has its original 20-second input deadline and receives one real click.

Intermediate north-package PCKs/copied runtime trees are excluded from evidence
uploads; GPU proofs, JSON summaries and validation logs remain.

Acceptance must record the next exact-head hosted workflow start-to-final-gate
wall clock, queue time separately, actual summed job time and artifact sizes.
Do not report an estimate, a shard-only time or a timeout as under-ten-minute full
acceptance. No local full-suite rerun is needed to reconstruct the baseline.

## Add a future reader stage without restoring serial CI

`native_validation_registration.mjs` provides an explicit, additive reader
contract. Its registry is empty by default. The historical 530-stage subset,
ordering, barriers, and the nine preparation producers remain unchanged.
The historical golden is a separate immutable ID subset, not a live catalog-size
limit: newly discovered GD tests join scheduling and aggregation automatically.
Top-level `test_*.gd` / `smoke_*.gd` discovery remains compatible. For a new stage
with an explicit I/O or dependency contract, use a nested entry so it is not also
auto-discovered. Add a reviewed `registerStage(...)` to
`NATIVE_STAGE_REGISTRATIONS`; this example is **not enabled**:

```js
registerStage({
  id: 'Future reader contract',
  execution: 'node', // godot | node | python | bash; fixed executable mapping
  entry: 'godot_native/tests/registered/future_reader.mjs',
  inputs: ['godot_native/tests/registered/future_reader.mjs', 'src/data/items.config.json'],
  outputs: [], // or [{scope: 'sandbox', path: 'summary.json'}]
  dependencies: ['test_minigame_models.gd'], // exact stage IDs
  exclusive: false,
  resources: {slots: 1},
  durationHintMs: 15000,
})
```

- New readers use the current continuous worker pool and bounded eight-shard partition.
  Default cost is one worker slot. The global cap stays `NATIVE_TEST_JOBS=1..4`;
  CI uses two. Other slot weights/resource classes are rejected, not silently
  approximated. Use `exclusive: true` for a reviewed drain barrier, not as
  permission to write shared inputs.
- Declared reader chains are co-located. Only appended registrations receive a
  stable topological order. Missing IDs and cycles fail before execution. Ready
  independent readers can run while a prerequisite is pending; the existing
  evidence guard blocks dependents after a prerequisite fails.
  Depend on `test_buct_haidian.gd`, not its audited `test_buct_rongmao.gd` alias:
  alias evidence is finalized after dispatch, so that dependency is rejected.
- `inputs` are declarations, **not** an exhaustive affected-test map or a weaker
  fingerprint. Exact whole-input/environment identities remain authoritative.
  Explicit `--test ID` closes prerequisites. Changed files matching a declared
  input (including a directory prefix), or an exact test with a registered
  dependent, conservatively select full parallel coverage **before** prose/test
  shortcuts. Known affected-module selections also propagate to registered
  consumers via full fallback. Transitive consumers therefore cannot be omitted.
  Unknown/new runtime paths also select full parallel coverage, not a serial fallback.
- Outputs may use only the stage's private sandbox. For Node/Python/Bash, resolve
  a declared sandbox path under `GODOT_TEST_USER_DATA_DIR`; Godot uses `user://`.
  This declaration is not an OS security boundary: review the implementation;
  a process can still violate its declared I/O. `createNativeTestSandbox` supplies
  a distinct `GODOT_TEST_USER_DATA_DIR` for each invocation; do not replace it.
  No stage may share those temporary outputs with another reader. Dependency
  edges order checks; they do not create a cross-stage sandbox data channel.
- Shared writers are rejected. Adding one requires a separate audit of
  `PREPARATION_IDS`, `PRODUCER_OUTPUTS`, immutable transport, and its consumers.
  Do not disguise a writer as a reader or add fixture writes to auto-discovered
  tests. The existing final input/fixture guards remain mandatory.
- Optional duration hints apply only without a valid observed timing. They never
  change coverage. Registration metadata survives plan/report rows and is bound
  into the new stage's descriptor and execution identity; legacy descriptors and
  identities keep their existing shape.

Run the fast contract suite after registration changes:

```sh
node --test godot_native/tests/test_native_validation_registration.mjs \
  godot_native/tests/test_native_validation_runner.mjs \
  godot_native/tests/test_native_validation_shards.mjs \
  godot_native/tests/test_native_validation_workflow.mjs
```


### Real transport integration checkpoint (local candidate `1af555a`)

Pinned Godot `4.7.1.stable.official.a13da4feb` passed nine fresh preparation stages
and all 92 owned stages of shard 5/6 after restoration into an independent clean
checkout. The consumer also freshly passed its host save-isolation guard:
**93 fresh passes, 8 authenticated prepared results, 429 not-run**. Final source,
import and fixture identities were unchanged. This is partial integration, not
full acceptance; the following additive registry retains the same 530 legacy
descriptors and partition hash under its 71 passing focused contracts.

The complete logical native input set was 1,891,039,216 bytes. Verified source
references represented 1,114,980,040 bytes. A real local ZIP at deflate level 0,
with files only and normalized extracted modes, was **779,885,566 bytes**.
Measured seal time was 43.014 s; archive 3.019 s; extraction 1.702 s; full private
restore/verification 27.018 s. These are local cloud measurements, not hosted
artifact-network times. The 92-stage shard took 566.281 s with observed peak two;
its 1,033.585 summed stage-seconds are not a full-workflow or CPU-usage metric.
Do not compare this different host with the hosted 265-second shard estimate as
a controlled speedup test. New exact-head hosted timing remains required.


The additive dependency-aware scheduler was also exercised with actual pinned
Godot at local `94b4850`: observation-comparison and theater-rehearsal models
both passed, with 1,687 ms overlap at jobs=2 and no input drift. That remains
**2 passed / 528 not-run** diagnostic evidence. Subsequent changes only scoped
historical golden tests away from the live catalog count and documented results.
The final focused suite passes **72/72**, including a newly discovered 531st GD
stage entering exactly one shard without editing the historical baseline fixture.
