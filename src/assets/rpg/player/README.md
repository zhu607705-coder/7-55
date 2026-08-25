# RPG Player Artwork

- `player_down_0.png` through `player_down_7.png`: front-facing continuous eight-phase walk cycle.
- `player_up_0.png` through `player_up_7.png`: back-facing continuous eight-phase walk cycle.
- `player_side_0.png` through `player_side_7.png`: right-facing continuous eight-phase walk cycle; Phaser mirrors these for left movement.
- Every runtime frame is a transparent `96 x 128` PNG with at least two pixels of transparent head and foot safety padding. The doubled source resolution keeps the existing world-space size and collision footprint while avoiding the former `48 x 64` upscale blur.
- `source/student_walk_gpt_image_sheet.png` and `source/student_walk_transparent.png` remain the previous four-phase source references.
- `source/player_walk_24pose_transparent_v2.png` is the active transparent source sheet. Its silhouettes visually form six rows, but they do not obey mathematical equal-cell boundaries: the source contains eight down poses, seven up poses, and nine side poses.
- `scripts/build-rpg-player-frames.py` is the deterministic frame builder. It extracts all 24 complete silhouettes from the whole-sheet alpha channel, orders them spatially, fills the eighth up frame by mirroring the fifth up source pose, selects eight side poses, and applies one fixed uniform scale per direction group.
- `npm run verify:rpg-character-sprites` guards complete silhouettes, head/foot padding, aspect ratio, source/output overlap, stable animation scale, and the recovered up-frame mapping.

Phaser owns frame switching, direction mirroring, movement speed, collision bodies, and animation timing.
`RpgPlayerAnimator` in `src/scenes/rpg/RpgPlayerTextures.ts` is the shared runtime owner for all RPG scenes. It runs an eight-phase cycle at about `9.1 FPS` and inserts a short original-pose / transition-pose / target-pose sequence whenever the movement direction changes.
