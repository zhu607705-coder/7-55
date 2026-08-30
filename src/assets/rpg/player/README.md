# RPG Player Artwork

- `player_down_0.png` through `player_down_7.png`: front-facing continuous eight-phase walk cycle.
- `player_up_0.png` through `player_up_7.png`: back-facing continuous eight-phase walk cycle.
- `player_side_0.png` through `player_side_11.png`: right-facing continuous twelve-phase walk cycle; Phaser mirrors these for left movement. Frames `1 / 4 / 7 / 10` are independently drawn transition poses. The first six frames use the near-side support leg and the second six swap to the far-side support leg, with opposite arm swing and foreground/background trouser shading.
- Every runtime frame is a transparent `96 x 128` PNG with at least two pixels of transparent head and foot safety padding. The doubled source resolution keeps the existing world-space size and collision footprint while avoiding the former `48 x 64` upscale blur.
- `source/student_walk_gpt_image_sheet.png` and `source/student_walk_transparent.png` remain the previous four-phase source references.
- `source/player_walk_24pose_transparent_v2.png` remains the active base source sheet. `source/player_side_transition_01_v3.png`, `23_v3`, `45_v3`, and `67_v3` add four genuine RGBA transition drawings for the side cycle.
- `scripts/build-rpg-player-frames.py` is the deterministic frame builder. It extracts the base silhouettes, fills the eighth up frame by mirroring the fifth up source pose, inserts the four side transitions, and normalizes the side silhouette heights to a symmetric `104 / 103 / 102 / 101 / 102 / 103` pattern for each half stride.
- `npm run verify:rpg-character-sprites` runs the dependency-free Node sprite validator for complete silhouettes, real alpha, head/foot padding, aspect ratio, source/output overlap, exact side gait heights, and the recovered up-frame mapping. `npm run verify:rpg-player` also requires all 28 runtime images to have unique hashes.

Phaser owns frame switching, direction mirroring, movement speed, collision bodies, and animation timing.
`RpgPlayerAnimator` in `src/scenes/rpg/RpgPlayerTextures.ts` is the shared runtime owner for all RPG scenes. Down/up keep eight frames at about `9.1 FPS`; side walking uses twelve actual drawings at about `13.6 FPS`. All directions keep the same `880ms` stride duration, and direction changes still insert a short original-pose / transition-pose / target-pose sequence.
