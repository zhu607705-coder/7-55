# Dorm modular candidate — 2026-10-21

This is a **reviewable reconstruction candidate**, not a replacement of the production dorm plate or collision map. Open `res://scenes/dorm_modular_preview.tscn` for source/candidate comparison. Space toggles the real later-story paper's run cycle; E separates the furniture groups; R resets. These controls never change story state or grant items.

## Evidence before reconstruction

- Canonical room: `src/assets/rpg/interiors/dorm_hub.png`, 941×1672. Four joined right-side desks, left-side bed assemblies, sink, cabinets, bin and props are baked into one PNG.
- Earlier `interiors/source/dorm_hub_*` files are alternate generated/reference PNGs, not editable layers. `ui/dorm_room.png` is a different UI reference. No dorm `.blend`, `.psd` or `.aseprite` source exists in this checkout. Blender sources found belong to the stairwell and Qizhen bank, not this room.
- Existing `assets/native/dorm_cabinet` is a cabinet-animation overlay, not a whole modular room.
- Real sink layout cannot be confirmed from these assets. The candidate retains the game-art sink and names it `sink_unverified`; it does not claim photographic fidelity to the user's actual dorm.
- **0755 folded paper**: `scripts/presentation/c3_paper_art.gd` literally renders the source-authored 64×50 resting paper and four walking poses. Existing pickup, narrative, close-view and defense consumers already share it. The independent practice node invokes that same renderer, with no copied drawing instructions or generated replacement.
- Yellow desktop note, theater paper sprites, `chapter35_live_paper_*` photo evidence and Chapter 4 `sign_in_record_paper` are distinct assets. This preview does not rewrite them or assume all paper-shaped story objects are identical.

## Structure

`dorm_modular_candidate.tscn` contains editable independent StaticBody2D roots for 18 main objects, plus 20 separate tabletop/shelf prop Sprite2Ds. Each object has a bottom-center pivot, atlas region and candidate-only collision. Props are parented to the corresponding furniture. Four desk regions share exact adjacent seams. Nearest sampling and uniform scaling preserve the projection; no unequal axis stretching is used. Root `Furnishings` uses y sorting. The independent paper is a separate node with the existing renderer and reduced-motion support.

The room plate is clean of furniture. AtlasTexture regions retain original generated alpha; no Python image masks, chroma removal or post-generation image painting were used. The reproducible `tools/dorm_modular/build_scene.py` writes scene/manifest **text only**.

## Generation provenance and limitations

Built-in imagegen edits used the original room as the reference. Stages:
1. Extract beds, sink, shelves, gray cabinet, bin, four desks, chairs, backpack and balcony plant onto true alpha; retain source top-down style and arrangement.
2. Remove all furniture from the room while retaining walls/window/door/balcony and blue floor.
3. Extract 16 tabletop/shelf object types into a transparent grid, with no labels or background.
4. Remove loose contents from extracted desks and shelves, leaving bare furniture bases.

Final files: `clean_room.png` (941×1672), `furniture_atlas.png` (941×1671), `props_atlas.png` (1254×1254). The model did **not** maintain exact original pixel coordinates or requested grid dimensions; atlas regions were measured against the actual output. Furniture has one uniform .9 transform and explicit registration. Generated art is not lossless extraction and has small edge/style changes. Do not reuse production collision coordinates on this candidate without review.

The sink towel/soap remain in its base assembly, ladders remain with their beds, and walls/window/door remain in the clean plate. Those are explicit remaining decomposition tasks, not claimed independent objects. Original production art, world geometry, progression, UI and save schema are unchanged. No full campaign or real-device acceptance is implied.

## Verification

Run source synchronization before Godot import, then:

```
godot --headless --path godot_native --script res://tests/test_dorm_modular.gd
godot --headless --path godot_native --script res://tests/test_canteen_paper_art.gd
node godot_native/tests/verify_canteen_paper_art_source.mjs
```

The dedicated `Dorm modular candidate proof` workflow renders source/candidate comparison, separated objects and all five canonical paper poses using actual Godot 4.6.3 + Xvfb. This is visual review evidence, not production route acceptance.
