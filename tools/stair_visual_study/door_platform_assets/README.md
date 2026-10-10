# Source-faithful fixed platforms and hinged school door

Independent render assets for the original `stair_b` scene. This folder changes
no routes, states, collision shapes, navigation links, gameplay cameras, or door
completion rules. It does not introduce a new game runtime.

In the Git repository, the consumed GLBs are committed under
`godot_native/assets/native/stair_b/`; the `assets/` paths below describe
reproducible authoring output. PNG previews and `.blend` files are not required
by the runtime. `evidence/first_render_manifest.json` is the initial checkpoint;
final verification is recorded by the other evidence files.

## Files and integration contract

- `assets/fixed_platforms.glb`: five fixed platforms in original world coordinates
- `assets/b_platform_{start,lower_base,landing,island,exit}.glb`: the same five
  objects exported separately, for a consumer that replaces source boxes by ID
- `assets/school_door.glb`: independent fixed frame and genuinely hinged leaf
- `assets/*_rgba.png`: 1024-square transparent three-quarter/reverse/bottom views;
  the door also has a 65-degree-open view
- `assets/*_albedo.png`: authored source textures, also embedded in each GLB
- `scripts/`: reproducible Blender generation and isolated Godot import check
- `evidence/`: exact validation results and artifact hashes

All GLBs use metres, glTF/Godot Y-up and original source world coordinates.
Authoring converts Godot `(x,y,z)` to Blender `(x,-z,y)`. Root transforms are
identity. Do not apply the source position a second time when instantiating.
These assets contain no collision bodies, animations, lights, or cameras.

### Platforms

The original source mesh names remain unchanged. Each mesh is under an identity
`<source_id>_fixed` root. Static rails use a separate `<source_id>_fixed_rails`
child. They must never be parented to any moving mechanism. Source slab centres,
dimensions, and walking-top planes are exact. The same byte-identical 128-square
terrazzo texture as the approved lower stair is used with nearest sampling,
metallic 0 and roughness 0.92.

| Platform | Centre (Godot) | Size | Walking top |
| --- | --- | --- | --- |
| `b_platform_start` | -4.8, 0.72, 1.6 | 4.8, 0.36, 2.4 | 0.9 |
| `b_platform_lower_base` | -2.15, 0.72, 1.35 | 1.3, 0.36, 1.5 | 0.9 |
| `b_platform_landing` | 0.85, 3.72, 1.75 | 3.4, 0.36, 3.2 | 3.9 |
| `b_platform_island` | 4.7138, 8.3637, 6.404 | 2.2, 0.36, 2.4 | 8.5437 |
| `b_platform_exit` | 4.7138, 8.3637, 7.9 | 2, 0.36, 2 | 8.5437 |

The lower pivot base has no added rail. Other platforms have short peripheral
guard segments, never a full enclosure or a new wall. Rail positions are listed
in the manifest. Small side reveals extend 2 mm beyond slab side faces only;
they do not raise a walking surface or define any collision geometry.

### Door

The actual native `chapter4_stairs.gd` `_decoration` fire-door case is the
dimension authority. The older `build_stair_sample.py` door was a historical
placeholder and is **not** used for final door dimensions.

Hierarchy:

```
school_door_assembly                         identity
  b_deco_fire_door_base                      (4.7138, 8.5437, 8.75), Y = pi
    b_deco_fire_door_frame_fixed             identity
    b_deco_fire_door_hinge                   (-0.62, 0, -0.072), Y = 0
      b_deco_fire_door_leaf                  (0.62, 1.03, 0.072)
      [leaf joinery, both handles, moving hinge halves]
```

The leaf mesh is exactly `1.24 × 2.06 × 0.14 m`. In base space its closed centre
is exactly `(0, 1.03, 0)`, matching the native source. Frame jamb centres are
`x = ±0.74`, jamb size `0.22 × 2.3 × 0.34 m`; lintel size is
`1.7 × 0.24 × 0.36 m` at local `y = 2.3`. The structural opening is 1.26 m wide.
Metal joinery and two-sided wood panels are genuine closed 3D meshes.

Animate only `b_deco_fire_door_hinge.rotation.y`. Its initial value is 0;
`PI / 2` opens it 90 degrees. The base and frame remain stationary. The world
hinge axis is through `(5.3338, 8.5437, 8.822)`, parallel to Godot Y. The existing
controller must remain the authority for opening and traversal. No rule or
completion condition is bundled with this presentation asset.

## Reproduce

Use the shared CPU lock when other asset workers are active:

```
flock /tmp/755-blender-render.lock blender -b --factory-startup -t 1 \
  --python tools/stair_visual_study/door_platform_assets/scripts/build_door_platforms.py -- \
  --output /tmp/755-door-platform-assets --render --samples 16
```

The default renders all 19 views. `--render-assets school_door,b_platform_start`
can render a selected subset. Exported geometry remains the same. The `.blend`
is a reproducible local work file and is ignored, rather than required at run
time. The GLB contains standard PBR materials and embedded PNG images; it needs
no procedural Blender shader or outside image file to display correctly.

For portability validation, copy the six separate GLBs, manifest and two PNGs
to an isolated temporary Godot project. Copy `check_door_platform_import.gd`
there. Use a writable temporary HOME, set `worker_pool/max_threads=1`, import
with `--headless --editor --import`, and run the check with `--headless --script`.
This check verifies dimensions, source coordinates, exact embedded pixels,
nearest filtering, repeated hinge motion and a 0.5 m central passage at 90
degrees. It is an asset test, not a substitute for whole-level runtime tests.

## Verified delivery checkpoint

- Blender: 308 checks; all 289 exported meshes are closed, with two incident
  faces per edge; source slab dimensions and identity ownership preserved
- Godot 4.6.3: 759 checks, 0 failures; 289 meshes, 6 textured surfaces, no
  collision bodies; exact embedded texture pixels and standard PBR factors
- Door motion: eight repeated 65/0/-65/0/90/0/65/0 degree poses; frame and axis
  remain stationary, and the 90-degree pose clears a central 0.5 × 1.75 m passage
- Independent package check: 149 checks, 0 failures; 7 self-contained GLBs and
  19 genuine RGBA images; every silhouette stays inside its image boundaries

### Known visual seam retained for source fidelity

The native door jambs overlap the lintel. Their outermost side faces meet in
the same plane. In the transparent Cycles inspection this produces a small
dark patch at the top outer corner. The exact production dimensions are
intentionally frozen for the current whole-level regression. The integration
owner will inspect the actual Godot door-open frame before deciding whether to
apply a sub-millimetre cosmetic outer-corner inset. The current assets do not
contain that change. It does not affect the tested doorway centre, leaf motion
or central passage. No GLB bytes were changed after integration handoff.

## Integrated hinge clearance correction

Rendered review exposed a door sweeping toward the waiting player. The runtime
now opens only toward positive local Y, and the mechanical axis is at the door
front surface, `(-.62, 0, -.072)`. Child offsets preserve the source closed leaf
centre and dimensions. Fixed pins and moving knuckles share this corrected axis.
The negative opening direction is not supported: it intersects the source jamb.
The door-only `door_hinge_clearance_v2` evidence supersedes earlier hinge positions;
platform evidence and all other GLB bytes are unchanged.
