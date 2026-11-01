# Spatial-review interface

This extends the existing architectural workbench. The 3D model owns the viewport; compact navigation sits at the edges. No body or hand representation is rendered. Camera changes preserve the same meter-scale geometry.

The implemented palette is warm plaster, gray floor, oak, charcoal mesh and restrained blue. Controls use the system UI stack at 12–20px; display typography is the architecture. Labels expose estimated floor calibration and manufacturer dimension sources without claiming a surveyed site model. Small tools receive expanded targets anchored to their actual projected positions, with occlusion/distance checks.

Desktop: drag to orbit in overview, select a room, enter eye-level walk, drag to look and use WASD/arrows. Mobile: left analog joystick and simultaneous right-side look drag. Cancel/focus loss clears movement. Escape or the visible floor-overview control exits; tool inspection returns to the exact observer position.

Rendered review: desktop1280x800, desktop903x862, mobile390x844 and landscape844x390 inspected from final browser captures. Eye-height furniture proportions are legible; mobile fits the entire floor by changing camera distance, not object scale. Three levels are visible in context through genuine atrium openings. 1F is not fabricated.

Impeccable detector reported one `dark-glow` warning for a modal's tinted shadow. Manual review confirms a light page (`#f3f5f2`), a nonzero20px vertical shadow offset and no glow decoration. The warning is retained in `review/impeccable_detection.json` as a detector false positive; no unreviewed design claim is made.

Known modeling limits: floor plan traces were restored from recorded numeric evidence, footprint/height/door positions remain approximate, some service/circulation zones are unmodeled, stair flights remain schematic and floor changes use overview navigation. Furniture inventory and source-specific cosmetic details are illustrative. NVIDIA candidates have not been downloaded; visible tools/furniture are locally authored from public dimensions.
