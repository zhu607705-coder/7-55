# Existing stair actor: camera-relative facing

The actor retains its last horizontal world-space movement heading. Each rendered
frame projects that heading onto the camera's horizontal right/away basis and
selects the existing front, back, or side texture. Turning the camera while the
actor is stopped therefore changes the visible body view without changing its
world heading or route.

This patch is limited to the existing four-level stair puzzle. Navigation,
mechanism states, tween durations, progression, and completion proofs are unchanged.
It does not include the separate chase prototype. Left-facing art still mirrors
the complete right-facing frame; independently drawn left and turn-transition
keyframes are not part of this patch.

## Verification

Verified with Godot 4.6.3 on target base `37c795a7702942b053f772fecfd272227b425a39`:

- `test_chapter4_stair_facing.gd`: 49 checks, zero failures. Four horizontal world
  headings across four camera positions; actual source texture selection; idle
  heading retained; camera-only change from back to side.
- `test_chapter4_stair_inputs.gd`: 136 checks, zero failures. Automated native
  input replay across all four existing levels and the final door; the existing
  controller proof validator accepts the result. This is not a manual campaign win.
- Native GUI: actual mouse controls aligned level A, then walked to
  `A_MID_ISLAND`. While stopped, the south-west camera showed the back frame and
  switching to south-east showed the side frame at the same location. The game
  exited through its Return button normally.

Run the focused suites from `godot_native`:

```sh
godot --headless --single-threaded-scene --path . --script tests/test_chapter4_stair_facing.gd
godot --headless --single-threaded-scene --path . --script tests/test_chapter4_stair_inputs.gd
```

The focused checks are not a full game regression or a performance benchmark.
