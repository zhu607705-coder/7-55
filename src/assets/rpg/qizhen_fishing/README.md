# Qizhen fishing artwork — 2026-09-06

Active consumer: `src/scenes/rpg/LakeFishingRitualVisual.ts`. Generated using the built-in imagegen tool, not an API fallback. The environment and actor are separate layers. No image owns game state, item placement, collision, or completion.

- `qizhen_fishing_dawn_environment.png`: 1672×941 RGB decorative lake environment; no dynamic game actors or UI.
- `player_blue_fishing_skiff.png`: 1548×1016 RGBA actor and skiff, genuine transparent background. Runtime rods and line start from the authored hand location. The image is uniformly scaled and never stretched.
- Identity references: `../player/player_side_0.png` and `../player/player_down_0.png`. Preserve black tousled hair, blue jacket, white undershirt, charcoal trousers, black backpack and black/white shoes.

## Environment prompt

Create a polished game environment bitmap ONLY, widescreen 16:9 landscape. A premium pixel-art illustrated background for a surreal fishing mini-game at Qizhen Lake, Zhejiang University Zijingang campus, early golden morning transitioning to blue teal water. Crisp hand-authored 16-bit pixel clusters with intricate material texture, atmospheric layered lighting, subtle dithering, no blur, mature indie game art. Broad calm open lake occupying central 65% and bottom center for dynamic runtime objects; reflective teal/turquoise water with tiny golden highlights and an abstract oversized underwater shadow; distant campus modern buildings and warmly lit lecture hall silhouettes on horizon upper quarter; a slim pale arched pedestrian bridge on the right reflected in water; willow branches framing upper corners, reeds and lotus leaves only in bottom corners. Slight magical unease, spacious central fishing area. NO humans, boats, kayaks, fish, swans, fishing rods or lines, moving props, circles, targets, user interface, letters, text, numbers, logos or border. Palette: deep petrol teal, muted forest green, pale celadon, saffron gold.

## Actor prompt

Create one transparent game sprite of exactly the existing black-haired blue-jacket player, preserving the same identity and detailed chibi pixel-art style from the side/front references. Preserve tousled black hair, youthful face, large head proportions, dark blue open jacket, white undershirt, charcoal trousers, black backpack and black-and-white sneakers. Change only his pose: seated in a small wooden fishing skiff, three-quarter side view facing right, knees bent, body slightly forward. Two hands reach together to the right at chest level; do not draw a rod, line or reel because these will be independent animated objects. Entire boat and seated character visible, no cropping; restrained wooden-plank pixel shading. No mustard/yellow/brown jacket, hat, glasses, beard or different character. Transparent alpha background, no water, landscape, external ground shadow, labels or text. Crisp pixel clusters and outlines matching the references, not vector or realistic adult art. One clean sprite.

## Alpha correction prompt

Remove the entire white/light-gray checkerboard background. Preserve exactly the blue-jacket black-haired boy, pose, face, backpack, clothing, hands and wooden boat. Output real transparent alpha around the silhouette, not white, gray or a rendered checkerboard. Do not redraw or add anything. The final selected output was verified RGBA with transparent corner pixels.
