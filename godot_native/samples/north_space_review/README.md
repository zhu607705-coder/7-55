# Floor-wide spatial quality gate

This uses the actual native world in an isolated developer save. Red shows the
non-ground complement of the continuous floor envelope, cyan shows the existing
physical solids, yellow shows authored occlusion baselines, and green shows the
complete shared player foot rectangle. The overlay is sample-only.

```sh
GODOT_BIN=/absolute/path/to/Godot_4.7.1 node godot_native/samples/north_space_review/run.mjs
```

Use `-- --overview --floor=A3` to inspect a whole floor; A1 and A2 are supported.
Use `-- --demo` for real keyboard approaches to the elevator wall and its side.
`NORTH_SPACE_CAPTURE_DIR` writes actual viewport images and state evidence outside
the repository. Normal movement, click/touch routing, collision, controller gates
and restore recovery use the production world code.

The shared model is `scripts/space/north_floor_space.gd` with source-pixel ground
regions in `data/native/north-floor-space.json`. Existing interior collisions,
dynamic furniture and authored occlusion masks remain their original geometry.
This gate establishes the exterior fence and consistent foot-based depth. It is
not a claim that every room's interior art/solid boundary has been accepted.
