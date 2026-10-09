# Canteen southeast door art

This replaces only the independent native southeast-door presentation. The west
door, original source texture, layout, source sensor, timing, exit gate, controller
and reward/exit sequence are unchanged.

- `web_atlas_source.png`: the accepted ChatGPT web image-generation result,
  1774×887 RGBA, eight distinct source-matched hinge poses
- `southeast_frame.png`: the full-resolution original 766×791 source crop with
  only the moving-leaf aperture cleared; original stationary hinge plates remain
- `southeast_leaves_8f.png`: 2048×1024 RGBA8 atlas, eight fixed 512×512 cells;
  only independent leaf crops, uniform scaling, translation and alpha masking
- `provenance.json`: source hashes, method/date, masks, registrations and measured
  centered passage widths; no private account or conversation data

The generated frame is discarded. Each generated leaf is registered independently
at its original outside hinge. The native original frame is composited above the
leaves. No whole-door squeeze, stretch, rotation or fade is applied at runtime.
The closed endpoint paints the full-resolution original source directly. Atlas
frame zero is only a half-resolution source-aperture reference for inspection.

The actual centered clear passage widths, measured across the complete leaf-height
band including handles and tips, are 0, 1.61, 9.42, 21.37, 33.78, 41.59, 46.18 and
48.94 world pixels. Pose 3 is the first to fit the unchanged 19.5px player feet.
Its presentation cue is aligned with the original 38% logical departure/passable threshold. Pose
selection is also constrained by the original live logical state, including
interrupted reversal. This threshold is not a separate dynamic collision wall:
the original source uses it for debug state and the 175/46ms departure delay.
No native collision predicate is changed. The original sensor and 460/120ms
clock remain untouched.
Requested angles are a drawing brief, not measured physical angle claims.

Regenerate registration with installed Pillow, then review the contact sheet:

    python godot_native/tools/canteen_door/register_frames.py
    python godot_native/tools/canteen_door/measure_aperture.py godot_native/assets/native/canteen_door/southeast_leaves_8f.png

These tools only process existing pixels. Production validation consumes checked-in
art and does not need Python or Pillow. Full native scene, desktop/mobile rendering,
interruption and lifecycle tests remain separate acceptance gates.
