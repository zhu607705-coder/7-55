# RPG Interior Artwork

## Ownership

- `dorm_hub.png`: selected runtime dorm artwork, fixed at `941 x 1672` as a tall top-down world rendered through the `960 x 540` Phaser camera.
- `library_interior.png`: runtime library artwork, fixed at `1500 x 900` for the library world.
- `canteen_interior.png`: runtime canteen artwork, fixed at `1672 x 941`; the southeast doorway is the campus-map entrance and return point.
- `source/dorm_hub_user_selected_topdown.png`: canonical dorm source selected by the user. It has two bunk-bed groups along the left wall and four desks along the right wall.
- `source/dorm_hub_gpt_image_open_aisle_rpg.png`: superseded open-aisle candidate retained for comparison.
- `source/dorm_hub_gpt_image_empty_table_rpg.png`: previous central-table source retained for comparison.
- `source/dorm_hub_gpt_image_table_card_reference.png`: visual reference used to model the Phaser card sprite.
- `source/library_interior_gpt_image_rpg.png`: current library source.
- `source/`: older GPT Image outputs remain as source history.

## Runtime Rules

- The selected bitmap owns the rendered dorm architecture and furniture.
- Phaser owns the `960 x 540` camera, source-pixel collisions, player movement, labels, hotspots, interaction animation overlays, quest markers, and state transitions.
- Gameplay coordinates must be updated in the scene model when an artwork layout changes.
- Dorm coordinates are authored against the original `941 x 1672` image in `DormHubModel.ts`; do not resize the bitmap independently from that model.
- Canteen collisions, occlusion crops, table aisles, interaction targets, and checkpoint spawns are authored once against the original `1672 x 941` image in `CanteenInteriorModel.ts`; do not resize or independently crop the runtime bitmap.
- MiniMax is audio-only. Room lifecycle events may select music, but audio completion never advances gameplay.
