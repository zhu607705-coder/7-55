# Native save compatibility

## Supported input and API

scripts/save_migration.gd provides a non-mutating decode(payload, defaults).
Pass **raw file text** to retain strict browser JSON syntax checks. Parsed
dictionaries are also accepted. The result contains ok, state when successful,
message, optional warnings, optional stores, and source_version.
A failed import never changes files or the supplied defaults.

Supported source formats:

- Original SaveStore envelopes, versions **2 through 35**, including the
  source's numeric version coercion
- The source's unversioned legacy state
- Explicit browser-storage backups: an object with format equal to
  "7-55-browser-storage" and a storage dictionary; or a dictionary containing
  the original primary/backup localStorage keys

Native format/version validation remains in State. Do not route native
snapshots through browser normalization: that would discard native-only
progress and replay proofs.

After successful decoding, State must validate the full native snapshot
before installing it or writing anything. It must also validate any returned
separate CC98 stores before applying them. The migration module itself never
opens a user's save or writes any save/store file.

## Source-exact normalization without a browser runtime

tools/build-save-normalizer.mjs extracts the pure load normalization and
persistent snapshot functions from src/core/SaveStore.ts, bundles their
actual helper dependencies, and compiles their syntax to a closed instruction
table. Ten source dependency hashes are embedded in
data/native/save_normalizer.json. Unsupported source syntax is a build error.

scripts/save_normalizer_vm.gd evaluates that checked-in table with GDScript.
There is no JavaScript engine, Node process, React, Phaser, browser, network,
external command, arbitrary object call, or runtime source-code parsing.
Incoming save data can never supply the instruction table. Unknown operations
and exhausted instruction budgets fail closed.

All original story, item, wallet, battery, weather/rain, photo recipe/journal,
interlude, clock, access, and chapter normalization comes from those source
functions. The native adapter adds only presentation state and provenance.
The source's persistent-snapshot sanitation clears controlCenterOpen,
inventoryOpen, and selectedItem. Native selected items, transient dialogs,
coordinates, developer state, and proof objects are never copied from a
browser payload.

Rebuild and check:

    node godot_native/tools/build-save-normalizer.mjs
    node godot_native/tools/build-save-normalizer.mjs --check

These are development commands. Published games only need the GDScript and
checked-in JSON data.

## Transport and completion provenance

Browser saves predate native minigame replay transcripts. A nonempty native
dictionary or a late chapter phase is not evidence.

native.save_import records the source version, original Chapter 4 record,
source-normalizer hash, explicit legacy completion, and the intersection of
actual raw and normalized transport/stair facts. Imported elevator transport
requires all four actual classroom/history/calibration prerequisites.
Imported stair proof requires actual A3-reference and solved-stair facts.

The explicit original **pre-v25 completed** migration is retained. It restores
the authored exterior-closure waiting state, not a newly acknowledged ending.
This is the only legacy-completion exception. Ordinary saves gain no missing
stair proof from their phase. Actual v35 completion survives only when the
source's causal facts, answers, power-grid state, submissions, and final
acknowledgement agree.

Call validate_import_proof(state, kind) for elevator, stair, or closure.
It reruns the original normalizer on the retained source Chapter 4 record and
checks the resulting provenance and current facts. It is a consistency
validator, not cryptographic anti-cheat. Native minigame results still require
their native replay validators.

## Primary/backup recovery and separate CC98 edits

decode_with_backup(primary, backup, defaults) selects the valid primary,
otherwise the valid backup. A recovered result carries source_selection
equal to "backup" and a warning. Browser storage bundles use the same rule for
seven_fifty_five_state and seven_fifty_five_state_backup.
The caller owns atomic installation and primary repair; it must not destroy
a valid backup while repairing a damaged primary.

The browser stores editable posts outside GameState:

- seven-fifty-five.cc98-posts.v2
- seven-fifty-five.cc98-quest-post-overrides.v1

When a storage bundle includes these keys, decode returns optional stores
with posts (Array) and questPostOverrides (Dictionary), preserving the edits.
scripts/data/cc98_store.gd owns validation and persistence through its static
validate_bundle(stores) and import_bundle(stores) functions.
A plain SaveStore envelope cannot contain these independently stored edits
and returns no stores; importing it must leave existing CC98 edits alone.

## Defensive boundaries and known differences

The original progression normalization is differential-tested, not
reimplemented approximately. The native input boundary additionally rejects:

- Input larger than 8 MiB, aggregate structures above the native resource
  budget, nesting beyond 24, and collections above 10,000 entries
- Non-finite values, unsupported future versions, and malformed envelopes
- NUL and lone UTF-16 surrogate text that Godot cannot preserve faithfully

The strict JSON guard rejects syntax accepted by Godot's permissive parser
but rejected by browser JSON.parse, including trailing commas, leading-zero
numbers, a decimal point without digits, and literal control characters in
strings. These safeguards are explicit rejection boundaries, not silent
progression repairs. Normalizer version changes require regeneration,
differential testing, and review of the recorded source hashes.

## Reproducible verification

    node godot_native/tests/verify_save_migration.mjs
    node godot_native/tests/verify_save_migration.mjs --exhaustive

The oracle uses the actual original SaveStore.load and SaveStore.save,
including persistent UI sanitation. It also verifies that native defaults
match createInitialGameState. Tests create their own temporary HOME,
XDG directories, fixture corpus, and save data; they never read or replace
real user saves.

The exhaustive run compares all **117 source-authored developer checkpoints
at every version 2–35**, plus explicit completion, malformed/fuzzed states,
numeric version coercion, actual v35 completion, A2/A3 false proofs and
legitimate transport, phone battery, rain and interlude persistence, transient
UI, backup selection, separate CC98 edits, and provenance tampering.
The final hardened exhaustive run passed **4,223 cases with zero differences**.
The focused suite passed 569 cases. Additional boundary probes verify safe
rejection of NUL, lone surrogates, non-finite numbers, and permissive JSON syntax.


## Actual native persistence regression

Run without fixture arguments; the test refuses to write unless Godot's user data
is under `/tmp`. Use a unique directory so no existing player saves are touched:

    isolated=$(mktemp -d /tmp/755-save-integration-XXXXXX)
    HOME="$isolated/home" XDG_DATA_HOME="$isolated/data" \
      XDG_CONFIG_HOME="$isolated/config" godot --headless --path godot_native \
      --script res://tests/test_save_integration.gd

The test sends all 117 compressed source checkpoints and three representative
snapshots for each version 2–35 through `State.import_save` as actual JSON files,
then resets State and reloads the native autosave. It also exercises native
export/import, exact source-normalized journal strings, genuine browser
A2/completion provenance after JSON's integer-to-float conversion, actual native
elevator transport after browser import, replay-validated native stairs,
malformed input nonmutation, simulated atomic-write failure, invalid-state write
protection, real primary/backup recovery, and independent CC98 edit coexistence.

Proof equality is over parsed JSON values, not strict Godot dictionary integer
versus float identity; extra keys and altered values still fail. Save and export
validate their state and serialized size/grammar before touching their
destination. Native load uses the same strict syntax boundary as explicit import.

Final standalone result: **1,765 checks, 231 actual-file browser imports, 0 failures**.
A separate 362-case selection from the original SaveStore oracle also passes both
decoder comparison and actual-file State import without source-state differences.

Genuine native elevator travel uses the active controller's two-classroom plus
calibration gate and the native completion marker; dark history observation may
remain undone and is never fabricated on reload. Browser-origin transport
continues to require its complete normalized provenance. The migration decoder
never trusts an incoming browser payload's native marker.
