# RPG Interior Artwork

## Ownership

- `dorm_hub.png`: selected runtime dorm artwork, fixed at `941 x 1672` as a tall top-down world rendered through the `960 x 540` Phaser camera.
- `library_interior.png`: runtime library artwork, fixed at `1500 x 900` for the library world.
- `canteen_interior.png`: runtime canteen artwork, fixed at `1672 x 941`; the southeast doorway is the campus-map entrance and return point.
- `finale/`: final-chapter environment plates and their hash manifest. The arrival arcade alone uses the approved pseudo-`2.5D` transition view; all teaching-building exploration plates use the `1672 x 941` orthographic top-down projection.
- `finale/teaching_building_floor_1.png`, `teaching_building_floor_2.png`, and `teaching_building_floor_3.png`: the three source-sized teaching-building floors. Every floor keeps one elevator centered at source `x=836`, one adjacent continuous stair core, and a clear return route. Phaser places them in one `5400 x 941` stitched world with `192px` transition gaps, then constrains the camera to the active floor while the shared transport core transfers the player between aligned landings.
- `finale/teaching_building_elevator_doors.png`: six `72 x 96` source-pixel door frames in one horizontal `432 x 96` sheet, ordered from closed to fully open. It replaces runtime-drawn flat door rectangles and stays aligned to the single elevator opening on all three floors.
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
- Final-chapter images are base environment layers only. Characters, paper, cleaning cart, attendance board, elevator doors and car, Maxwell shutter, time silhouettes, morning light, screens, scanner and interaction markers remain dynamic Phaser layers declared in `finale/finale_environment_manifest.json`.
- The stitched teaching-building map keeps the Maxwell bakery, classroom vestibules, and alumni portrait galleries in the base artwork. Their story behavior remains controller-owned and is exposed through source-pixel anchor bounds; it must not be baked into the image as prompts or quest markers.
- `npm run art:finale-environments` verifies every final-chapter plate remains exactly `1672 x 941`, validates the elevator sheet dimensions and frame contract, and rebuilds the browser asset manifest.
- MiniMax is audio-only. Room lifecycle events may select music, but audio completion never advances gameplay.
