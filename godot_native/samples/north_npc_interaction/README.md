# Actual teaching-building NPC interaction preview

This opens the formal native game, including its original A3 reference teacher,
player movement, collision, object picking and controller dialogue. It uses a
disposable developer checkpoint; it does not read or overwrite a campaign save.

After native source/media preparation and asset import:

```sh
GODOT_BIN=/absolute/path/to/Godot_4.7.1 node godot_native/samples/north_npc_interaction/run.mjs
```

Walk up the classroom aisle with WASD/arrows and press Space near the teacher.
Normal touch-to-approach and interaction also use the original world controls.
The separate portrait interaction review remains in `north_clean_rebuild_preview`.

For a repeatable real-input demonstration, append `-- --demo`. Godot's movie
writer options go before `--`; `NPC_PREVIEW_CAPTURE_DIR` optionally saves actual
viewport stills and controller evidence outside the repository.
Add `--touch` after `--demo` to exercise a real screen-touch event on the NPC's
visible pixels instead of the Space interaction.
