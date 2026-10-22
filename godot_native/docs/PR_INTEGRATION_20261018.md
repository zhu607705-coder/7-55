# PR143–148 compatibility integration

Base: `godot-version` at `2c8cc05ed9297a4040c2e0916351bd9d57ee3a15`.
Working branch: `integration/pr-compatibility-20261018`.

This branch preserves all six source histories through non-fast-forward merges.
The 415 contributed source files are byte-checked by
`PR_INTEGRATION_SOURCES_20261018.json`. Production adapters are separate changes.
A merge without a text conflict does not prove that a prototype is on the story path.

## What the real entry uses

```text
entry.tscn → Continue / Main → original Chapter 3 controller
  ├─ rainy launch → original route / gust / capsize
  │    → PR145 native rescue, starting AFTER its repeated fall
  │    → original dock hold → same issued RainSession consumed once
  │    → dorm_hub / phone_home → hair dryer → original weather gate
  └─ valid live paper catch → original atomic channel transition
       → PR144 cove entrance presentation (world input and chase clock blocked)
       → original channel kayak / live escape proof
       → magnetic rod consumed → original c35_recovery
```

The rain adapter starts the sample at 2.650 seconds (`hold_hull`). The source
route already contains the capsize. It must not be shown a second time.
The normal native route is 5.650 + 12.350 + 1.600 = 19.600 seconds before
controller settlement. The legacy video fallback keeps its separate 5.875-second
video guard and 9-second watchdog. Reduced motion retains its original path.
Only RainSession can authorize completion. Renderer time, preview callbacks,
skip signals, and standalone result dictionaries cannot do so.

The swan adapter is display-only. It has no progress event. Its short cove shot
uses the validated pre-transition pose, then releases the already-established
channel state. It does not replace the formal world physics or copy preview
coordinates into the host. Focus loss keeps the blocker and freezes the shot.
The session also validates state identity, attempt, host, and kayak identity.

## Compatibility matrix

| PR | Preserved head | Source project | Real story use in this branch |
|---|---|---|---|
| 143 | `f9ecd18d290528ff311e96310bde9bc195230a18` | `godot_native` preview | Full 12-flight/input/camera preview retained; formal C4 unchanged |
| 144 | `7d9e68895787b79a9fc170e7099b20066a21bbb8` | `godot_native` preview | Pure entrance presentation after controller-validated paper catch |
| 145 | `65f07d8c02643b4b0b87fb35d821e227682d3318` | `samples/qizhen-rain-rescue-native` | Namespaced pure renderer inside original production RainSession |
| 146 | `7ec8f23b7e5e7c4af171752277624966cda3b1ec` | `examples/qizhen_playable_chase` | Old channel exercise remains an independent project |
| 147 | `9a1ca38cec283dbd73dde4e84f108e6711e8944e` | `examples/qizhen_large_world` | Large-map/input/camera exercise remains an independent project |
| 148 | `9f8f7c56f9b4c7449b06c5f1f77b7347924fdb93` | `examples/blender_stair_sample/preview` | Two-flight Blender sample remains an independent project |

PR146 and PR147 are not two revisions to copy over the same map. PR148 is an
11.42-second, two-flight sample, not a replacement for PR143's twelve flights.
Their project roots are also resource and UID namespaces. Do not flatten them.
PR141 was inspected for overlap: none of its 18 paths overlap these contributions;
it is not added to this integration.

## Gameplay replacements still require a separate decision

- Formal C4 validates a controller session, attempt and the original ordered
  two-landing trace. PR143 validates raw masks, a geometry hash and elapsed ticks.
  The identical `folded_stair_input` label in PR148 does not make its model valid
  for PR143. A replacement needs an explicit validator and old-save policy.
- Formal lake escape validates a controller-issued WorldSession bound to the
  exact world host, live kayak, zone and attempt. PR146 `next_story` and PR147
  `finished` do not satisfy it. A large-map replacement needs authored target,
  physical/proof, checkpoint and return contracts.
- Existing C4 landing-1/landing-2 saves keep their existing path. Nothing in this
  branch reinterprets them as twelve gates or a two-flight Blender completion.

## Run and verify

From the repository root:

```sh
npm ci --ignore-scripts
node godot_native/tools/sync_source.mjs
bash godot_native/tools/convert_media.sh
node scripts/verify-native-pr-integration.mjs --runtime
godot --path godot_native
```

The checker verifies immutable source hashes, project-local resource paths,
per-root UID uniqueness, clean process imports and native tests. Each process
gets isolated temporary user data. Independent project tests also preserve
formal save/previous/tmp sentinel bytes. Dynamic resource paths need runtime
coverage; the literal-path scan alone is not proof of their validity.

To open any independent project, pass its matrix path to `godot --path`.
Do not copy its scripts into `godot_native/scripts` to make it run.

Focused production tests:

- `test_pr_integration_entry.gd`: actual entry Continue button, saved authored
  checkpoint, real world Space interactions, graphical pointer skip, actual
  touch Continue after save/reload. The checkpoint/proximity placement is an
  explicit fixture, not a claim of manual whole-game playthrough.
- `test_c3_swan_entrance_shell.gd`: real fishing success through the formal host,
  blocked world clock, focus/pause/lifecycle, skip, save/reload, original escape.
- `test_rain_rescue.gd`: controller capabilities and single consumption through
  native completion, skip, cancellation, interruption and reduced motion.
- `test_rain_rescue_video_fallback.gd`: legacy decoder/timing/watchdog contract.
- `test_rain_rescue.gd -- --graphical-touch-skip`: real 390×844 root touch and
  bounded, readable captions through the original viewport container.
- `test_rain_rescue_native_renderer.gd`: deterministic pose/contact geometry,
  bounded particles and imported atlas availability.
- `verify_rain_rescue_native_source.mjs`: original and adapted source hashes,
  namespaced paths, licenses and forbidden sample-authority removal.

`tools/verify_pr_integration_pck.gd` can run as an external `--script` against
an exported `--main-pack`. Release presets exclude tests/tools. That test verifies
compiled adapters, State, JSON regions, and imported texture remaps without
source PNGs beside the PCK. A separate exported-binary startup verifies the
release template. Headless/synthetic touch checks are not a physical-phone test.

On compact screens the scene keeps its fixed 960×540 camera frame. The production
wrapper independently sizes skip to at least 44 physical pixels and reflows the
unchanged route/capsize/rescue/dock captions at 14–16 physical pixels in the original
footer. Desktop drawing is unchanged. The 390×844 graphical regression injects
actual root ScreenTouch events; it does not emit the Button signal directly.

The source rescue atlases must use `ResourceLoader.exists`, not
`FileAccess.file_exists`: PNG source bytes are not guaranteed in an exported PCK.
JSON catalog reads still use FileAccess and are covered by the export filter.
