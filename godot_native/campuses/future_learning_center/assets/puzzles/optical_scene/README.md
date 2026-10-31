# Independent optical apparatus parts

These eleven original PNG masters were generated independently through the approved ChatGPT webpage workflow on 2026-10-31. They are not SVGs, code-drawn prop substitutes, API-generated images, or one baked apparatus picture. `manifest.json` records byte hashes, dimensions and visible alpha bounds. Source PNG bytes are unchanged. Private conversation URLs/transcripts are not published.

The new Collab and Assembly scenes reuse earlier generated table, camera, cradles, paper and feed-control components only in their existing physical roles. Those originals remain in the Schedule asset folders and retain their own provenance.

## Registration and geometry

`optical_scene_art.gd` is the exact source-crop/pivot manifest. `optical_scene_visuals.gd` contains each object independently and preserves aspect ratio. Source crops exclude transparent margin, not painted object pixels; no stretching or generated-image repainting is used.

- The blank fixture uses a 312 × 185 containment box and a top-surface registration point. Four separate socket sprites stay at the model's fixed slot centers. An earlier baked-slot candidate was rejected because its groove spacing could not match the model with uniform scaling.
- Front baffles render 116 units wide, matching the authoritative blocking segment. Edge baffles use the fourth independently generated candidate: pivot `(512, 792)`, nominal source contact span 1310 mapped to 76.56 projected units. The rear endpoint at source y137 is **an inferred calibration**, not a directly visible measurement. The front endpoint is approximately y1447; the top end cap extends beyond the contact span. Raw-image glow is excluded from the crop's containment bounds.
- Each generated rail image contains two identical rails. An unchanged source region of one rail is instanced independently at each model lane; lane spacing is not baked into the picture. The same physical rail master supports the Assembly bracket.
- Lamp registration uses the emitting lens. Carriage registration approximates the center of its projected contact footprint `(637, 700)`, not its foremost shoe. Quarter-control registration uses its base; it is an indexed press/turn action, not a free continuously rotating dial.
- The bracket's projected contact-center calibration is `(525, 1200)`; its visible width is about28. Its perspective image is **not claimed to coincide exactly with the model's28 × 45 footprint**. During dragging or actual contact, a labelled clearance outline shows the model's occupied area. This is interaction feedback, not a replacement prop.

## Runtime boundary

Only transforms, light paths, brightness, text and interaction/clearance feedback are drawn or updated by code. Rays are clipped by the model and placed above the fixture but below solid objects. The Assembly support-removal rule is reflected by the side-light path and target illumination.

Dragging follows the pointer immediately with the original grab offset. Settle motion is at most0.12s; cancellation snaps to the unchanged model pose. Carriage travel is copied directly from the controller, including pause/contact limits. Presentation does not write progression, completion, inventory or saves.

The retained `box` helper on the base view remains solely for existing non-optical subclasses. These two optical rooms do not call it. Existing inherited rooms do not instantiate the new optical sprite layer.

## Acceptance

Source-pixel inspection and controller/state regressions are separate from graphical acceptance. The full generated-art test explicitly requires all eleven masters. Desktop/mobile and four-direction first-contact screenshots must be reviewed before claiming scene acceptance; passing a headless test alone is not visual or physical-device acceptance.

Native Godot 4.7.1 acceptance on 2026-10-31 includes actual mouse completion of both rooms (desktop Collab and 844 × 390 Assembly), plus reviewed model-contact fixtures for all four quarter turns. Root-dispatched touch tests cover all three viewport sizes, cancellation, foreign-finger rejection, immediate following and reentry. These are native tests, not a Web-export or physical-handset claim. At 390 × 844 the existing host still fits the whole 960 × 540 apparatus into a narrow band: nothing is cropped, but controls/text are too small for comfortable portrait use. Portrait usability remains a known host-layout limitation.
