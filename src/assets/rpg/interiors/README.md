# RPG Interior Artwork

## Ownership

- `dorm_hub.png`: selected runtime dorm artwork, fixed at `941 x 1672` and uniformly presented at `0.5` scale inside the `960 x 540` Phaser camera.
- `library_interior.png`: runtime library artwork, fixed at `1500 x 900` for the library world.
- `canteen_interior.png`: runtime canteen artwork, fixed at `1672 x 941`; the southeast doorway is the campus-map entrance and return point.
- `finale/`: final-chapter environment plates and their schema 3 hash/atlas manifest. The arrival arcade alone uses the approved pseudo-`2.5D` transition view; all teaching-building exploration plates use the `1672 x 941` orthographic top-down projection. The active Chapter 4 `7:55` contract lives under `finale/chapter4-755/`.
- `finale/chapter4-755/base/a1.png`, `a2.png`, and `a3.png`: the three approved source-sized teaching-building floors. Each floor owns a separately measured elevator aperture and interaction anchor, while one controller-owned transport state connects the floors.
- `finale/chapter4-755/states/`: nine opaque time-state plates. Three former `1671 x 941` sources receive one copied right-edge column; no plate is resized or interpolated.
- `finale/chapter4-755/sprites/`: five active RGBA sheets for clock states, the power panel, story items, room-204 furniture, and room-204 residuals. Every frame has an explicit source rectangle, Alpha trim, pivot, collision rule, and interaction rule in `finale/finale_environment_manifest.json`.
- Collision, occlusion, stand, arrival, physical-delta, checkpoint, and three-floor navigation geometry comes from `src/data/chapter4-three-floor-maze.layout.json` and `src/data/chapter4-temporal-maze.topology.json`; see `finale/chapter4-755/README.md` for provenance and exact hashes.
- `finale/teaching_building_elevator_doors.png`: six `72 x 96` source-pixel door frames in one horizontal `432 x 96` sheet, ordered from closed to fully open. It replaces runtime-drawn flat door rectangles and is positioned from the active floor's measured elevator layout entry.
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
- Dorm coordinates remain authored against the original `941 x 1672` image in `DormHubModel.ts`; its single `0.5` runtime transform maps the bitmap, collisions, hotspots, props, spawns, and door together. Do not resize any one of those layers independently.
- Canteen collisions, occlusion crops, table aisles, interaction targets, and checkpoint spawns are authored once against the original `1672 x 941` image in `CanteenInteriorModel.ts`; do not resize or independently crop the runtime bitmap.
- Final-chapter images are base environment layers only. Characters, paper, cleaning cart, attendance board, elevator doors and car, Maxwell shutter, time silhouettes, morning light, screens, scanner and interaction markers remain dynamic Phaser layers declared in `finale/finale_environment_manifest.json`.
- The stitched teaching-building map keeps the Maxwell bakery, classroom vestibules, and alumni portrait galleries in the base artwork. Their story behavior remains controller-owned and is exposed through source-pixel anchor bounds; it must not be baked into the image as prompts or quest markers.
- `npm run art:finale-environments` verifies approved source hashes, deterministically normalizes the formal Chapter 4 states and sprites, validates final-chapter dimensions, and rebuilds the browser asset manifest.
- `npm run chapter4:validate-assets` proves the schema 3 plate/sheet contract, including three pixel-exact copied-column transformations. `npm run chapter4:validate-topology` proves the active A1/A2/A3 room and chase routes against the approved source-pixel collision rectangles.
- The existing official “灿若星辰” closing material stays outside this generation and normalization lane; no replacement is registered here.
- MiniMax is audio-only. Room lifecycle events may select music, but audio completion never advances gameplay.
