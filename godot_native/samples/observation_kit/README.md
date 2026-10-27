# Observation kit · Godot 4.7.1

Four small helpers, not a campaign framework. `library_time` is the first consumer.
Each sample keeps its own `res://` root, model, objects and completion rules.
The paper and raking-light samples are not refactored by this change.

| Reuse | Contract | Not provided |
| --- | --- | --- |
| `camera_rig.gd` | `configure(camera, viewport_size, focus, width_span, min_height=0) -> Basis`; fixed 50° elevation, 8° yaw; orthographic width with optional minimum height | Level framing, camera movement or automatic acceptance |
| `pointer_owners.gd` | `owners`, `start(id, object) -> bool`, `release(id)`, `clear()`, `has_owner(object) -> bool`; mouse ID −1, touch IDs ≥0 | Hit tests, valid-object list, pause or puzzle rules |
| `history_surface.gd` | `viewport(parent)` creates a private World3D; `image(parent, viewport)` displays it without consuming input | A history recorder, mutable world sharing or proof that a clue was visible |
| `capture_inputs.gd` | `touch`, `drag`, `mouse_button`, `mouse_move` submit ordinary `InputEvent`s | Direct model writes or a substitute for real rendering |

## New sample: five steps

1. Create one standalone directory under `samples/` with its own `project.godot`, scene and local model. Pin 4.7.1 and disable touch-to-mouse emulation. Do not import production saves or campaign autoloads.
2. Run `node godot_native/samples/observation_kit/tools/sync_kit.mjs sample_name`. This copies only the four helpers into `sample_name/kit`. Load them as `res://kit/...`; never load a sibling project's `res://` paths.
3. Build a fresh world for the present and every snapshot. Construct separate meshes, materials and lights. Snapshot setup takes immutable recorded values, never the present model. Moving a window changes its screen rectangle only.
4. In the view, route visible native controls before scene hits. Reject `DEVICE_ID_EMULATION`, assign owners only after a visible hit, and retain each owner until release. Clear owners on cancel, focus loss, pause, viewport resize or leaving the usable surface. Resume must be explicit and must not restore stale contacts. Mouse interaction may use sequential drags.
5. Keep the puzzle's observation and selection checks in its own model/view boundary. Account for other windows, menu occlusion and 3D occluders. A hidden clue cannot count as observed. Never complete from a timer, animation or window movement alone. Verify `sync_kit.mjs sample_name --check` in that sample's CI.

## Acceptance and recording

- Run `GODOT_BIN=/path/to/godot node godot_native/samples/observation_kit/tools/test_kit.mjs` to check camera, resolved World3D isolation, ownership and ordinary input delivery. The runner creates and removes its own temporary project and XDG directories.
- Run headless model, ownership, world-isolation and save-sentinel checks in temporary XDG directories. Headless success is **not** visual acceptance.
- Use a GitHub-hosted runner with pinned Godot 4.7.1, Xvfb and Mesa. Run the sample with `--rendering-method gl_compatibility --fixed-fps 30 --write-movie ...avi`. A capture script must reject a `headless` display or missing video adapter and drive ordinary input through `capture_inputs.gd`.
- Record the exact source SHA. Encode the AVI to MP4; retain entry, interaction, occlusion, failure/recovery and completion frames. Inspect actual PNG pixels before making visual claims. Automated touches are not physical-phone verification.
- Exercise two simultaneous owners, sequential mouse fallback, canceled touches, background/resume, resize, moved/overlapping windows and a wrong selection that returns safely. Add a negative control where required evidence is hidden; it must not pass.
- Follow the established `raking-light-demo.yml` download checksum, graphical-tool setup and artifact pattern. Keep recording workflows read-only (`contents: read`). No merge, deployment or campaign wiring is implied.

## Provenance and limits

The camera basis, isolated SubViewport pattern, pointer exclusivity and ordinary-event
capture approach are extracted from the repository's raking-light sample reviewed
at `07174d75151845bacc1f7bb99c91c62a54d42433`. The new helpers contain no level data,
formal item IDs, file I/O, network calls or progression writes. The kit's copies are
byte-checked so each standalone source ZIP remains runnable without sibling files.
