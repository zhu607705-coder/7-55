# All-map spatial review

Run from this checkout with Godot 4.7.1 available as `GODOT_BIN`:

```sh
WORLD_SPACE_CAPTURE_DIR=/absolute/output/folder node godot_native/samples/world_space_review/run.mjs --resolution 1440x900
```

Repeat with `--resolution 390x844` and a different output folder. This launches
the real native world, original objects and controllers under an isolated DEV
save. The logical world viewport remains 960×540. Each source map receives an
overview, an ordinary input contact capture and an overlay-free actual capture;
`evidence.json` records the checks and invalid-frame count. The developer setup
does not demonstrate earning the story gates. Use the normal game for play.

See `docs/WORLD_SPACE.md` for the shared grounding and depth contract.
