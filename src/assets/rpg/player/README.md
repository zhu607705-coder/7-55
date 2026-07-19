# RPG Player Artwork

- `player_down_0.png`, `player_down_1.png`: front-facing idle and walking step.
- `player_up_0.png`, `player_up_1.png`: back-facing idle and walking step.
- `player_side_0.png`, `player_side_1.png`: right-facing idle and walking step; Phaser mirrors these for left movement.
- Every runtime frame is a transparent `48 x 64` PNG with the feet aligned to the bottom edge.
- `source/student_walk_gpt_image_sheet.png` is the original GPT Image output.
- `source/student_walk_transparent.png` is the cleaned source sheet used to produce runtime frames.

Phaser owns frame switching, direction mirroring, movement speed, collision bodies, and animation timing.
`RpgPlayerAnimator` in `src/scenes/rpg/RpgPlayerTextures.ts` is the shared runtime owner for all three RPG scenes. It runs walking poses at `12.5 FPS` and inserts a short original-pose / transition-pose / target-pose sequence whenever the facing direction changes.
