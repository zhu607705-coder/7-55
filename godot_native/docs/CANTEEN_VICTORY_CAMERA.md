# Canteen victory camera and same-room handoff

## Original source authority

- `src/scenes/rpg/CanteenInteriorModel.ts:8–11` defines the room as 1672 × 941 source pixels
- `src/scenes/rpg/RpgRenderResolution.ts:3–4` defines the 960 × 540 logical viewport
- `CanteenInteriorScene.ts:3746–3756`, inside `startDefense`, stops player following, clears the deadzone, sets `min(960 / 1672, 540 / 941) * 0.985`, and centers on `(836, 470.5)`
- The resulting logical zoom is `0.565249734325186`
- `animateDefenseVictory` (`3828–3849`), `finishDefense` (`3789–3801`), the three 1200 ms dialogue beats (`2137–2144`), and `beginCanteenExit` (`2359–2394`) never restore the exploration camera. The room remains fully visible through paper flight, hold, dialogue, door wait and scripted player exit

`tests/verify_canteen_victory_source.mjs` executes the original camera setup block and the original victory, finish, dialogue and exit methods. Its camera stub records follow/deadzone/center/logical zoom. All 112 existing paper samples and the actual source exit completion must retain the initial full-room shot. The door wait is computed from the source door constructor and authored duration, rather than a newly selected timing.

## Native implementation

`c3_narrative_host.gd` owns the source full-room camera only while the accepted `canteen_escape` capability remains valid for its state and scene. `world._update_camera()` consults that owner before applying exploration follow/pan. The host releases ownership before restoring exploration, so the restore cannot immediately reacquire the old shot. A late release cannot overwrite a different scene or replacement state.

Main already gives this cinematic the canonical 960 × 540 surface in desktop and compact layouts. That contract is unchanged. The existing subtitle physical-size compensation remains in use; world-camera zoom never scales the subtitle font.

The defense activity hides the world frame. `world._process()` therefore returns before reducing `transition_alpha`; an old entry fade can remain at 1 for the whole defense. On return, the normal 500 ms fade can obscure the reduced-motion 160 ms victory flight. Only the attachment of a valid `canteen_escape` clears that stale fade. Ordinary scene changes and same-scene reloads still initialize their entry fade to 1.

No model, proof validator, controller facts, reward, paper pose, route, duration, mixer artwork or drink observer is changed.

## Verification

- New `test_canteen_victory_camera.gd`: 1122 checks, 0 failures. real Main plus the controller-validated checked-in 60-second defense proof. Covers normal/reduced motion; desktop, portrait and landscape; flight start/destination/current-point visibility; full hold; focus pause; live same-session resize; all dialogue text and physical font sizes; scripted exit; cancel/retry; same-scene replacement; new-scene camera ownership; selective fade clearance; and unchanged facts/items
- Camera checks inspect the existing transform without calling its mutating setter
- Negative control: removing only the new world camera hook in a temporary runtime yields 144 failures out of 1122 checks and exit code 1. Restoring the exact original bytes and rerunning produces 1122 checks, 0 failures
- All 14 existing focused regression scripts passed. Coverage includes victory pose, Chapter 3 narrative and actual shell, portrait narrative contract, promo integration, defense world return, canteen scene lifecycle, pickup continuity/cinematic, scene and subtitle readability, mixer continuity/layer separation, and drink observer lifecycle

Run the source check from a complete checkout:

```sh
node godot_native/tests/verify_canteen_victory_source.mjs
```

For a sparse native checkout, set `CANTEEN_SOURCE_ROOT` to the complete original source checkout. Run native checks against an asset-synced project with an isolated user-data directory:

```sh
XDG_DATA_HOME=/tmp/canteen-camera-test-profile/data \
XDG_CONFIG_HOME=/tmp/canteen-camera-test-profile/config \
XDG_CACHE_HOME=/tmp/canteen-camera-test-profile/cache \
XDG_STATE_HOME=/tmp/canteen-camera-test-profile/state \
LP_NUM_THREADS=2 godot --headless --path godot_native \
  --script res://tests/test_canteen_victory_camera.gd
```

These are source-executed and headless native integration checks. They are not a manual GUI campaign, physical-device test, or visual acceptance of the final frame capture.


## Final combined GUI acceptance, 2026-10-09

Normal 1180×812 and reduced 390×844 native captures each completed the original
3,600-input trace in real time. Both actual proofs were accepted by the original
controller; all three authored dialogue lines were visible in order and the
ordinary exit returned to campus. The portrait run included a human pause,
viewport change and resume. The footage is labeled automated source input
replay, not a manually earned campaign win.

Per-frame records include world camera, zoom, stale-fade opacity, paper pose,
player position and the door's logical departure predicate. The full source
camera and zero stale-fade opacity persist through visible flight. This predicate
is not treated as a separate physical collision wall. Captures preserve actual
render timing and gaps, without added holds or interpolated frames.
