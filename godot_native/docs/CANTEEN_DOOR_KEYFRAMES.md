# Southeast canteen door hinge poses

Source audit: 2026-10-09. Base: `bf8861f365f38c50b3a3b5aed1f985de685a4c1b`.

## Scope and source identity

The native southeast door uses `assets/native/canteen_objects/canteen_double_door.png`,
a 1254×1254 RGBA image with SHA-256
`d2f5df50b71e106a84335807b703ae6b3385cc2fb5f96c805c9a09dc799cf36d`.
The registered source crop is `[244,232,1010,1023]`, or 766×791 pixels.
The original closed image, dark metal, two blue-glass windows, handles, lintel,
jambs and hinges are the identity reference. Unused faint pixels outside that
source crop are not part of the native door.

The existing southeast anchor is `(1349,900)` and its uniform scale is `88/766`.
The art therefore occupies `(1305,809.1279373,88,90.8720627)` when closed.
The separate gameplay opening remains `(1305,795,88,105)`. That pre-existing
visual/source-height difference must not be repaired by stretching the artwork
or changing the gameplay sensor.

## Hinge and registration contract

- Two vertical outside hinge axes are visible near source x=313 and x=939
- The left and right closed leaves meet near source x=627
- Each leaf rotates independently about its outside vertical axis
- The moving center edges describe a projected swing, including a lower-edge
  excursion and a visible thickness edge; no whole-image horizontal squash
- The original lintel, jambs and stationary hinge plates remain fixed
- Every pose uses the same cell size, source scale and hinge registration
- The closed runtime endpoint paints the original source texture directly
- Open leaves remain opaque; opening never fades the entire frame away

The source reference uses a 1024×1024 transparent canvas. Its unchanged 766×791
crop begins at `(128,80)`. The resulting native canvas is placed at the original
crop's top-left minus `(128,80) * (88/766)`, with the same uniform source scale.
Moving cells are uniformly registered at 512×512, with a cell-to-source factor of 2.
The source closed endpoint and original frame keep full resolution.
This supplies lower padding for the physical leaf swing without moving the door.

## Authority that remains unchanged

`interior_door_layer.gd` owns the existing linear progress, SineInOut visual
progress, 460 ms normal/120 ms reduced duration, interruption/reversal behavior,
approach bounds, hold-open hysteresis, story escape cue and 38% logical departure/passable threshold.
The source `RpgInteriorDoor` exposes 38% as its debug passable state and uses
`passableDelayMs` in `beginCanteenExit` (175 ms normal, 46 ms reduced). It is not
a separate dynamic collision wall. Native `world.can_stand` and independent-object
collision do not consume `doors.passable()`, consistent with the original
sensor-ahead-of-departure arrangement. This batch adds no physical collision gate.
Its original canteen phase gate and theater behavior remain unchanged.
The new helper samples the existing `visual_progress` and the existing logical passable state.
At full travel, linear progress 0.38 corresponds to SineInOut visual progress
0.31593772365766093. Uniform frame indexing is not a valid clearance contract:
generated leaf angles and silhouette widths must be measured first.

The player has an unchanged 19.5-world-pixel foot width. A 512-pixel moving cell
uses a factor of `2 * 88 / 766` world pixels per cell pixel, so its conservative
centered passage needs at least 85 transparent cell pixels at the first passable
pose. Scan the entire moving-leaf height, including handles and opened lower tips.
Register a monotonic pose order, select the first measured foot-passable pose,
and map that pose to the original 38% logical threshold. Before the threshold, cap selection below
that pose; after it, keep selection at or beyond it. This gate-aware clamp also
covers interrupted reversals, where linear and eased progress have different
starting values. It must not change the logical departure threshold itself.

No changes to `main.gd`, controller, model, shared runtime, layout, colliders,
exit anchor, rewards, inventory, save facts or scene transition sequence belong
to this batch. The west door stays the original static source object.

## Acceptance gates

1. Pixel-exact closed source; unchanged static-frame pixels; true RGBA8 alpha
2. Eight genuinely distinct registered poses and stable outside hinge axes
3. No clipped opened tips, residual closed leaf, background box or frame drift
4. Uniform render scale, full leaf opacity, forward/reverse deterministic sampling
5. Existing sensors, 460/120 ms duration and 38% passability remain authoritative
6. Interrupted opening, repeated approach/leave, reduced motion and reentry
7. Native desktop/mobile visual inspection and exact-commit native test suite

Generated-source provenance records methods, date, geometry and hashes only.
Private account or conversation addresses are never part of the repository.

## Registered batch evidence

The accepted web sheet is 1774×887 RGBA. It supplies seven new non-closed
physical leaf poses; the first runtime pose is the unchanged source. The moving
atlas is 2048×1024 RGBA8. The generated frame is not used.

Measured centered clear widths are 0, 1.61, 9.42, 21.37, 33.78, 41.59, 46.18 and
48.94 world pixels. Pose 3 is the first passable pose. The measurements include
handles and lower tips across cell y=82..486, with an alpha threshold of 8/255.

The source-art tests and full native integration tests are separate files so that
registration can be checked without importing or launching the whole game. Native
execution and graphical acceptance must be recorded only after they actually run.

## Focused validation

2026-10-09: isolated Godot 4.6.3 raw-image/helper test passed **4,267 checks,
0 failures**, without editor import or shared-cache access. It checks actual
alpha clearance, fixed registration, source-frame pixels and stateless cue/gate
sampling. Mounted renderer tests pass 79 checks, and the existing interior-door tests
pass 24 checks. Independent pixel/registration review found no blockers.

Real native GUI acceptance covers approach/hold hysteresis, retreat, reversal
before full opening, full closure, fully-open same-scene save import/reload,
portrait reduced motion, and the ordinary timed narrative departure. Capture
metadata retains actual progress, visual progress and the logical departure
predicate; no physical-collision inference is made from that predicate.

Normal and reduced source-input replay runs each completed 3,600 original
inputs and the original controller accepted both proofs. All three narrative
lines were visible before campus departure. These are automated source-input
replays, explicitly not manually earned wins. The source narrative waits
175/46 ms before its existing 300/120 ms Stepped walk. Ordinary exit clicks
already use a different immediate scene-change path; this patch changes neither.

Known retained UI limitation: the existing bottom instruction HUD covers part
of the doorway. Full-frame evidence retains it. Final remote CI remains a PR
acceptance gate; no physical-mobile hardware test is claimed.


### Recorded departure sampling limits

The source starts the scripted walk after a fixed 175/46 ms timer; it does not
poll the logical predicate as a dynamic movement gate. In the final wide and
reduced portrait recordings, the first sampled movement toward the distant door
occurred at door progress 0.326087 and 0.300926 respectively, before a later
sample reported the predicate true. This is not a physical threshold-crossing
measurement. The fixed source wait and route are preserved; no new collision or
movement gate is introduced to change this sampled update-order relationship.

Portrait still uses a small source-logical full-room view, and the existing HUD
covers lower door detail. These are retained presentation limitations, not a
claim of complete mobile visual adaptation.
