# Schedule workbench: independent generated objects

Ten original transparent PNGs generated through the ChatGPT web interface on 2026-10-31. Each distinct scene object is a separate texture and runtime Sprite2D. The seven task/tool/result images in `../schedule_generated` remain separate objects too.

| Texture | Purpose |
| --- | --- |
| tabletop | Empty wooden work surface; uniformly scaled, sides extend beyond the viewport |
| board | Empty three-lane schedule board |
| tray | Three tool recesses and a lower glove compartment |
| cradle | Reusable empty output/reserve-camera recess |
| card | Empty draggable task magnet |
| cover, page | Notebook cover and separate blank reading page |
| starter_base, starter_cap | Fixed housing and independently moving press surface |
| wrench | Undo affordance |

The generation brief requested consistent wood, cream paper, blue-grey metal, a shallow front view, no lettering, no embedded tools, and transparent exteriors. Rejected RGB/checkerboard and mismatched candidates are not included. `manifest.json` records exact original SHA-256, source dimensions, visible crop regions, and logical bounds. No original pixels were repainted, recolored, stretched, or background-removed locally. The soft alpha and texture colors are not claimed to meet a strict binary-alpha or small-palette specification.

`ScheduleSceneVisuals` creates independent object nodes. The view owns gestures; the unchanged schedule model alone owns placement, trial state, artifact production, completion, and saves. Held objects follow the pointer directly with their pickup offset. Release settlement lasts 120 ms; cancelled gestures restore their authoritative positions. The starter is a press control for start/pause/resume, not a compass or angular-input crank. Its cap moves separately. The notebook opens its generated page over 160 ms. Reduced motion snaps these presentation transitions.

Short Chinese task names, beat headings, progress marks, focus/drop targets, and navigation remain native accessible interface elements. This is the first complete Schedule workbench sample, not a claim that all 25 rooms have generated object art.
