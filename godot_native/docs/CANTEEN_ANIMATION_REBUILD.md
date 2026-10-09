# Canteen animation rebuild

Source audit: 2026-10-09. Native integration base: `fddb08c8`.

## Non-negotiable authority

`chapters/chapter3.gd` remains the inventory, payment, correct-tray, order,
recipe, defense-proof and chapter-progression authority. Presentation observes
accepted facts. Loading, cancelling, hiding or completing an animation must
never create an item or repeat a reward. The active defense is the original
60-second moving-cart model; the retired three-static-cart route stays retired.

## Full scene inventory

| Motion group | Current source/native evidence | Rebuild treatment |
| --- | --- | --- |
| 25: scattered trays, pickup, carrying | `CanteenInteriorScene.animateTrayCollection`; `chapter3_world_layers.gd` | New registered eight-pose tray art; retain original idle SVG, path and 360/100 ms pickup |
| 26: return stack and receiving auntie | `chapter3.gd` auntie branch; `c3_return_stack_pose.gd` | New real tray turn/lay poses; stack stays rigid; retain 320/160 ms return and original reward facts |
| 27: dispensers | `chapter3.gd` drink-take branch; `c3_canteen_device_panel.gd` | Add accepted-action-only eight-pose panel closeup; retain machine identity and immediate inventory grant |
| 28: mixer | `c3_mixer_motion.gd`, `canteen_mixer_performance.gd` | Preserve reviewed separated layers and completion continuity from PRs 89 and 93 |
| 29: lightbox/third queue column | `c3_promo_timeline.gd`; original `animatePromoAndQueueShift` | Reuse four insertion frames, three bubbles and prompt effects; audit stepping/turn continuity separately |
| 30: pickup package/paper finale | original `animatePaperBurst`; `canteen_defense.gd` | Restore existing five push, five shake and eight burst frames plus exact 11.38-second cinematic |
| Arrival paper discovery and escape | `c3_scene_session.gd`, `c3_canteen_paper_view.gd` | Retain authored route, surprise, folded-leg poses and camera ownership; verify rendered continuity |
| Ambient light NPCs | `chapter3_world_layers.gd` | Reuse actual frame pairs for 4 counter, 12 queue, 8 seated, 6 extra seated, 1 return NPC; preserve occlusion |
| Shadow auntie and mode transition | native layers and original `createDarkModeLayer` | Retain three shadow frames and 180 ms fade; audit source blue fibers |
| Order receipt | controller and print SFX at +420 ms | Existing grant remains authoritative; physical print art is a separate presentation gap |
| Active pushcart defense | `canteen_defense_model.gd` and source runtime | Preserve 4-direction/4-frame actor and deterministic model; use native scene furniture where available |
| Defense paper run and impact | model and `c3_paper_art.gd` | Restore authored folded-leg drawing instead of body-only bob; preserve contact proof |
| Defense win and paper escape | `c3_narrative_session.gd` | Preserve replay validation, southeast escape and dialogue gates |
| Southeast door/player exit | `interior_door_layer.gd`, native object scene | Audit real hinge poses separately; preserve sensor, 38% threshold and authored traversal |

The six anchor numbers are a convenient visual index, not a complete list of
scene motion. Reused artwork is recorded as reused, not claimed as newly
regenerated. Source-only gaps are kept separate from native-port omissions.

## Tray batch

- Source idle and carried geometry remains the original 28x28 SVG
- One SVG-derived source cell and seven independently generated pose cells are
  uniformly registered into
  a 512x256 RGBA atlas (4 columns, 2 rows, 128x128 cells)
- Source-frame zero is retained in the atlas for identity checks, while runtime
  frame zero uses the unchanged SVG for exact endpoint pixels
- Pickup returns to frame zero; return progresses through all eight poses
- Only the transient top tray moves. The stacked furniture never squashes
- Original approach/contact/weight/settle boundaries and shortened reduced
  motion are preserved
- File-local provenance stores the original source paths, method/date, generated
  source hash, registration values and final atlas hash. No private account or
  conversation links are published

## Verification

`tests/test_canteen_tray_frames.gd` checks frame regions, source endpoint
identity, normal/reduced timing, path continuity, rigid-stack invariants,
stateless sampling, genuine alpha, cell clipping and eight distinct frames.
The existing return lifecycle, tray pickup continuity, scene layering and
controller tests remain required. Focused tests alone do not establish GUI or
whole-game acceptance.

## Dispenser batch

- Eight reference-guided bottle/stream fill poses registered as true RGBA8
- The original pre-selection drink panel remains unchanged. After the real
  controller grants a new item, an optional 640 ms closeup plays in that panel
- Fixed spout, backplate and drip grille are separate crops from the original
  world-machine image. The bottle stays independently animated; its stream
  meets the spout and its base rests above the grille
- A per-cell interior/stream color mask follows the actual fill level, retains
  the original alpha and glass highlights, and uses the three source drink colors
- The item is granted immediately. Repeated Take is locked; Escape, Close,
  reload or context changes cancel without dispatching any completion action
- Reduced motion holds one stable full-bottle pose for 160 ms
- The world observer retains compatibility with hidden deferred-closing panels.
  An active closeup owns its presentation; closing it cannot cause a second pour
- World machine positions, physical player occlusion, controller facts and the
  approved mixer behavior are unchanged

The first complete-shell GUI check found that Main defers its State.changed
refresh. The observer now reads its already-bound live state synchronously at
State.action_completed rather than requiring a preceding render sync. A real
main.tscn + State.act regression covers that order, not a custom stub alone.

## Acceptance record

- 1,325 tray art/path/alpha-picking checks passed
- 1,315 full drink controller, main-shell, frame, cancellation and reentry checks passed
- 3,492 existing routed device-control checks passed across 1280x720, 960x540,
  390x844, 430x860 and 844x390, including the optional post-grant tail
- Native GUI: tray pickup and rigid-stack return; all three drink colors;
  390x844 double-click suppression, owned reentry and Escape cancellation
- Independent static reviews cover tray registration, observer lifetime, panel
  input/lifecycle and color-mask registration. Compact bay bounds were corrected
  and inspected in the native graphical renderer
- Actual clips preserve recorded frame timestamps. They use declared prerequisite
  fixtures and real input through the original controller, not an earned full
  campaign traversal or synthetic interpolation

Required whole-suite CI is a separate gate. This batch does not claim that every
canteen visual or the wider interface has completed its remaining polish.
