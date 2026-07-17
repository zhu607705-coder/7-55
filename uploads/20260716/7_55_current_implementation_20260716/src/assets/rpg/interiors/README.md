# RPG Interior Artwork

## Ownership

- `dorm_hub.png`: runtime dorm artwork, fixed at `960 x 540` for the Phaser canvas.
- `library_interior.png`: runtime library artwork, fixed at `1500 x 900` for the library world.
- `source/dorm_hub_gpt_image_open_aisle_rpg.png`: current open-aisle dorm source. Phaser places the campus card on the right-side desk at runtime.
- `source/dorm_hub_gpt_image_empty_table_rpg.png`: previous central-table source retained for comparison.
- `source/dorm_hub_gpt_image_table_card_reference.png`: visual reference used to model the Phaser card sprite.
- `source/library_interior_gpt_image_rpg.png`: current library source.
- `source/`: older GPT Image outputs remain as source history.

## Runtime Rules

- GPT Image owns the rendered room artwork.
- Phaser owns collisions, player movement, labels, hotspots, quest markers, and state transitions.
- Gameplay coordinates must be updated in the scene model when an artwork layout changes.
- MiniMax is audio-only. Room lifecycle events may select music, but audio completion never advances gameplay.
