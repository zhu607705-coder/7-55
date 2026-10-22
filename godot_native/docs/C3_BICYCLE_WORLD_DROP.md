# Bicycle world item interaction

The existing Chapter 3 chain is unchanged: recover trays → earn wages and tissue → intercept the paper → clean the campus bike lock → spend the earned ¥2 → start the chase. The panel buttons from the preceding device slice remain available as an accessible alternative.

Before this patch, native Chapter 3 had a proximity anchor for the bike but no bicycle rendering or accepted-item drop target. This patch restores the source bicycle at (3220, 650), then makes the owned tissue and wages usable on that visible body. Dropping tissue removes glare and retains the tissue. Dropping wages after cleaning consumes the wage item and deducts exactly ¥2. Dark-mode drops, wrong items, misses and canceled gestures preserve both items and money. Dark code observation is still optional. Successful direct use returns control to the world without opening the lock panel; selecting an item and pressing Space near the bike provides the existing keyboard alternative.

## Source and geometry

`c3_bike_world_view.gd` contains the 16 drawing commands recorded by executing the original `BootScene.ensureCanteenTextures`. A small SVG adapter renders these commands into the same 92 × 62 texture dimensions. World placement, centered origin, y+6 depth, code glow and glare geometry match source. The body texture is also the object picker's alpha mask. Transparent corners and empty space inside the source's broad 100 px drop circle do not become hidden drop surfaces. Existing compact-pointer tolerance applies after visible-object selection. At the existing minimum zoom, that tolerance still fits within the source's 100 px upper bound. The native controller retains its existing 170 px proximity guard.

The price and balance label uses at least 14 physical px. When its source-above placement would enter the compact header, it moves beside or below the bike. Its opaque backdrop participates in visual occlusion and cannot pass a drop through to hidden objects. Scene collision, map scale, checkpoint, recipe, wallet and quest definitions are unchanged.

This restores the core source bicycle, mode indications and direct item actions. The source's optional inspection pulse and 360 ms glare-clean animation are not reproduced; the authoritative cleaned state removes glare immediately.

## Evidence

- The source exporter executes the original texture generation, bike/mode construction, inspection and inventory-drop methods. Its fixture includes source hashes, all drawing styles/coordinates, inspect boundaries and drop behavior.
- `test_c3_bike_world_drop.gd` passes 250 checks across 1440 × 900, 390 × 844, 430 × 860 and 844 × 390. It uses real inventory gestures through Main and the world SubViewport, plus alpha geometry, wrong-item, miss, cancellation, dark refusal and selected-item keyboard checks.
- Existing Chapter 3 world layers pass 129 checks; canteen controller differential passes 23 scenarios/45 steps; all 262 scripts parse.
- Sixteen graphical phase fixtures were inspected after waiting for the actual scene-entry fade. They use explicitly declared source state/stand fixtures. A previous fixture incorrectly paused the entry fade and produced dark screenshots; the runtime did not have that defect.
- A graphical process does not reliably move its OS pointer when given synthetic drag events. Therefore phase screenshots use explicit controller actions, while actual graphical drag acceptance uses CUA.
- Actual CUA started from the original `c3-canteen-bike` DEV checkpoint in a separate profile. Dragging the tissue from the visible inventory onto the bike lock removed glare, with tissue retained. Dragging wages onto the same visible bike changed the balance from ¥2.00 to ¥0.00 and removed the wages. No lock panel opened. Two screenshots preserve these outcomes.

This is bounded chapter-local acceptance. It does not claim continuous earned gameplay, physical phone hardware, ordinary-save replay of the CUA route, or final merged export acceptance. Apply after the preceding C3 canteen-device patch, then run the merged-tree checks and export through the integration lead.
