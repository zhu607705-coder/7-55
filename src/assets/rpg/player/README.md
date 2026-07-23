# RPG Player Artwork

- `player_down_0.png` through `player_down_3.png`: front-facing idle, left stride, lifted idle, and right stride.
- `player_up_0.png` through `player_up_3.png`: back-facing idle, left stride, lifted idle, and right stride.
- `player_side_0.png` through `player_side_3.png`: right-facing idle and alternating strides; Phaser mirrors these for left movement.
- Every runtime frame is a transparent `96 x 128` PNG with the feet aligned to the bottom edge. The doubled source resolution keeps the existing world-space size and collision footprint while avoiding the former `48 x 64` upscale blur.
- `source/student_walk_gpt_image_sheet.png` is the original GPT Image output.
- `source/student_walk_transparent.png` is the cleaned source sheet used to produce runtime frames.
- `scripts/build-rpg-player-frames.py` is the deterministic frame builder.

Phaser owns frame switching, direction mirroring, movement speed, collision bodies, and animation timing.
`RpgPlayerAnimator` in `src/scenes/rpg/RpgPlayerTextures.ts` is the shared runtime owner for all three RPG scenes. It runs a four-phase cycle at about `11.1 FPS` and inserts a short original-pose / transition-pose / target-pose sequence whenever the facing direction changes.
