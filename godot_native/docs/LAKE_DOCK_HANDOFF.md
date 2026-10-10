# Restore the dock-to-lake handoff

An earned locker/cord save exposed three disconnected pieces of the same journey. The teacher still answered but had no visible body, the lake phone repeated the completed four-stroke tutorial, and the collapsed inventory rail covered the first line of guidance. After observing the net-frame reflection, the message also suggested casting at that same ripple, although the real cast is in the channel.

The native view now restores the original teacher, shows the current goal and applicable source controls, and places the lake page's collapsed bag outside the reading area. A small inset keeps its first glyph clear of the phone border. The observed net-frame reminder directs the player to the actual ripple below the raft in the channel north of the main lake. It gives no recipe or later puzzle solution.

## Source correspondence and intentional clarification

- `QizhenLakeScene.ts` imports `guard_check_watch_2frame.png`, uses 96×128 frames 0–1 at 2 fps, a 0.52 scale, target-local foot offset +46 and target.y+48 depth. Native rendering uses the same 30,279-byte PNG (SHA-256 `183820b808dc7ea801cb878687aa6537c34225910569b37a421ed4755d5d346e`), frame geometry and ordering. The nearest-target scale remains 1.08; a selected nonmatching item dims it to 0.3. Reduced motion holds its first original frame. No collider is added.
- The original boarding target itself has no persistent sprite or pulse. This change does not invent a docked boat/marker. Its nearby action text reuses `prompts.board` and `prompts.needLight`.
- First boarding retains `boarding.instruction` and the original four forward strokes. Completed boarding reuses `boarding.controls`; no tutorial fact, stroke requirement, audio cue, simulation, collision or proof owner changes.
- **Inherited source inconsistency, deliberately corrected:** `QizhenLakeModel.ts` places `qizhen_reflection_item_3` at open_water (910,360), but `qizhen_fishing_item_3` at channel (640,575). The source `reflection.correct`/`lightWater` text suggests casting at the observed spot. The new location sentence is an explicit clarification, not a claim that the original prose agreed. Dark observation still records only the existing `net_frame` fact. Light mode before observation only explains that this is a reflection; the phone reveals the route only after the fact exists. The target locations, accepted item and controller remain unchanged.
- Only the lake page opts into the existing reading-safe bag anchor and body inset. Expanded drawer, item metadata, selection, inspection, drag, combination and other page anchors remain unchanged.

## Validation

Nine affected scripts pass: handoff 43, reading bag 258, Chapter 3 world layers 129, world object picking 53, live lake differential/world 4,370, main-shell lake input 17, terminal feedback 21, fishing focus return 32, and Replay handoff layout 60. These verify state/range guards, source sprite geometry/loop, no new solid, existing item/proof ownership, read-only clue retention, drawer relocation cancellation, and unaffected world returns. The initial driver named a nonexistent focus script; that file-not-found record is retained, and the correctly named focus script and remaining layout script passed afterward. No runtime change was needed for that runner correction.

Actual CUA used unchanged earned save copies. The main C4 save remains at 07:54:05 (`520d4d56…c75460`), 270 operated / 10 formal; this slice does not claim a new fishing catch. Baseline: original published PR67-equivalent Linux package at 1180×812 and a normal 430×860 reload. Candidate: actual 430 teacher interaction and light/dark reboarding, 390 bag open/scroll/cord inspection/close/Tasks/return, and desktop travel from the retained clue to the north channel. A physical rod drag into the ripple below the raft opened the correct net-frame challenge; X returned normally. Inventory and all lake facts except visited zone/safe entry stayed unchanged. Baseline navigation was source-assisted, so this is not first-time discoverability acceptance.

The earlier candidate body was flush against the phone edge; actual pixel review caught the clipped first glyph. The final lake-only inset was then checked at desktop and 390. Final exported verification is recorded below. All actual sessions used Dummy audio: no PCM, hearing or subjective intelligibility claim. The existing long kayak status line remains cramped in portrait and is not accepted as repaired by this change.


## Final exported boundary

Fresh official Linux export exited 0. Its runtime digest is `19d89dd3591b936ba748a45edd09ba5e95b2ec817047622551827eb580abb439`; PCK is 583,714,156 bytes, SHA-256 `f5f7d13f7cfe260d1912daf8a0a9857070f3a63368cc98d963fbe91b36f92a1a`. All 43 focused checks pass against the packed resources. The final actual 430 normal reload preserves the earned channel/observation/items, readable inset and collapsed bag clearance. Bag open/close and Return work; ordinary A/D paddles and Save/close succeed. No catch or loss was added.

**Separate inherited pointer limitation:** mouse/touchpad clicks on the visible portrait paddle rectangles do not move the boat, whereas A/D immediately moves the same live boat. Both bound-window and physical desktop clicks were tried. The unchanged mouse branch has no kayak-paddle handler; ScreenTouch and keyboard have one. This does not establish a real-finger failure. A separate pointer-parity repair is pending, so this validation is not blanket mobile-input acceptance.
