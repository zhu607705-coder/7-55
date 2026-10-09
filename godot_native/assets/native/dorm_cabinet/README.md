# Dorm cabinet opening art

This is a bounded art replacement for the existing native dorm cabinet. It does not add a room, interaction, reward, clue, state machine, or story gate.

- `web_atlas_source.png`: the second ChatGPT web image-generation result, 1774×887 RGBA, retained as provenance. The requested opening angles were a drawing brief, not measured geometry.
- `cabinet_opening_frames.png`: mechanically registered 1024×512 RGBA production atlas. Four columns, two rows, eight 256×256 cells. The first cell uses exact pixels from the original `dorm_hub.png`.
- `provenance.json`: source hashes, generation method/date, cell registration and source-pixel coordinates.

The original plate remains visible. The overlay changes only the source aperture `(421,249,132,140)` and the small areas where opened leaves physically occlude the lower sill. The outer cabinet, wall, curtain, bin and floor are not regenerated. No non-uniform scale or perspective warp is used. The raw atlas's half-pixel boundaries are rounded, normalized for one-pixel cell-origin differences, and uniformly scaled to source resolution.

The existing `cabinet_amount` still changes at one full opening per 260 ms. It selects the authored poses. The first 1/7 of travel fades from the exact original closed pixels into the first generated pose, avoiding a texture pop; the remaining poses play discretely in pixel-art style. Closing selects the same poses in reverse, including mid-motion reversals. Reduced motion and ordinary reload select the appropriate stable endpoint immediately. No duration, state authority, hitbox or controller predicate is changed.

Regenerate registration locally with ImageMagick:

    node godot_native/tools/dorm_cabinet/register_frames.mjs path/to/original/dorm_hub.png

The script verifies the original plate hash. It only crops, masks and uniformly scales existing pixels; new door geometry comes from the web-generated art. CI consumes the checked-in PNG and does not require ImageMagick.
