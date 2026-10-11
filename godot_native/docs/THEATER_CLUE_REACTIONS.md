# Theater clue contact animations

This change is native Godot presentation work on top of `913bd512`. It preserves the original story and controller transaction timing.

## Accepted action → visible response

- Poster: the original `greaseTissue` pixels approach the authored glass, sweep three overlapping contact paths, clear only swept oil cells, clear varied-thickness dark brown smears, expose the original ticket-half artwork, then lift its corner and withdraw
- Vent: the original fluorescent brush touches a fixed point on the existing grille; a brief handle flick releases twelve bounded grains along the existing vent-to-stage path; the paper hesitates, recoils, folds at a real two-facet hinge, then unfolds into the original fluorescent paper
- No new obstacle, escape route, puzzle, collision, clue value, item, dialogue, save field, or scene is introduced
- The paper uses original source textures and native articulated geometry. It is not advertised as a new hand-drawn multi-frame sprite sheet

## Ownership and interruptions

`chapters/chapter3.gd` is unchanged. Its accepted actions still consume the tissue or brush and commit the ticket/paper fact immediately, exactly once. `c3_theater_clue_view.gd` observes only false-to-true state edges. It does not send events or decide rewards.

Repeated attempts do not restart the response. State replacement, scene/mode/phase change, reduced motion, settings, phone hide, focus loss, and renderer removal settle the presentation. They cannot undo, repeat, or lose the accepted controller result. Restoring a completed save shows the settled result without replaying an animation.

The native `theater_clue_objects.tscn` scene contains individually addressable `OilMask`, `Tissue`, `TicketHalf`, `VentBrush`, `Powder`, and `Paper` nodes. Each owns local geometry, transforms and visibility; the paper has separately hinged polygon facets and fixed contact markers identify tissue and bristle pivots. A mouse-ignoring clipping Control limits the objects to the existing visible world area. Existing world interaction targets remain authoritative; decorative grains do not add input colliders.

The original `poster_case_front` foreground crop repaints the glass after ordinary actor-depth props. The new contact layers therefore mount as native world children through the existing post-occlusion landmark pass. Source foreground and collision data remain untouched. The normal stage paper renderer is suppressed only while its single temporary articulated-paper representation is visible.

## Verification

- `test_theater_clue_reactions.gd`: monotone physical wipe coverage, fixed brush tip, ordered hesitation/fold/unfold/mark, bounded powder, unchanged controller semantics, repeat/reload/interruption/reduced-motion behavior, single paper ownership, independent native nodes, clipping, and cancellation/removal before deferred mounting
- `test_theater_clue_main.gd`: real Main and inventory mouse/touch gestures at desktop and `390×844`, cancelled drag, controller consumption, nonmodal presentation, settings and phone interruption, reduced motion
- Existing `test_chapter3_world_layers.gd`, `test_world_object_picking.gd`, `test_world_presentation_lifecycle.gd`, and `test_chapter3.gd` are regression checks

Native visual inspection uses `test_theater_clue_main.gd -- --manual` (optional `--portrait`). F6 resets the isolated poster fixture; F7 resets the isolated vent fixture. Original inventory controls perform the action. F11 saves a native screenshot. Three live intermediate samples are also captured after each accepted action.

`capture_theater_clues.gd` produces a deterministic 30-fps native-render inspection reel after original fixture actions (poster inventory drag; vent inventory selection plus Space). It is explicitly a scene fixture, not an earned campaign playthrough. Set `THEATER_CLUE_CAPTURE_DIR` to a writable output directory. Use `--poster`, `--vent`, `--portrait`, and `--touch` to select inspection variants. Portrait fixtures pan the camera so the wide original poster target is visible. All fixture scripts use developer mode and must run with isolated HOME/XDG directories.

Full repository aggregate validation, integrated-batch compatibility, and physical mobile hardware verification are separate from these focused checks.

The portrait inspection also exposed an existing native inventory release-coordinate discrepancy, reproduced with clue nodes absent. The companion scoped input fix and native mouse/touch verification are documented in `INVENTORY_RELEASE_COORDINATES.md`; controller logic remains unchanged.
