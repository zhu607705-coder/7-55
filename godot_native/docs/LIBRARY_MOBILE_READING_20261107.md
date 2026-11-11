# Library world document: compact reading

Candidate based on `8e442ee5a46b347ac09130a3f270f1eadc15d392`.

The deployed 390×844 screenshot showed the 960×540 book spread reduced to
390×219. Body type was about 8.5 CSS pixels and the close target about 18.7
pixels high. Successful scrolling alone did not establish readable presentation.

The document component now keeps the existing desktop spread when its scale is
at least 0.96. Below that threshold, it shows the same green bound cover and
cream printed paper at native screen scale. Portrait stacks the cover above
the paper. Short landscape places the cover beside the paper. The authored
cover and body strings are unchanged. Compact body type is 18 pixels, and the
close target is 48 pixels high. Paper height follows wrapped text, with the
close action after the printed text. The rule retains an actual scroll end.

The existing controller still owns reading and record acknowledgement. Opening,
scrolling and resizing do not grant evidence. Resize preserves fractional
scroll progress and suppresses geometry-generated end detection. Repeated
close callbacks are ignored. No world layout, collision, item, source copy or
controller change is included.

## Focused validation

Official Godot `4.7.1.stable.official.a13da4feb`, headless Linux, with independent
source inputs and copied prepared import artifacts. Run from the repository:

```
godot --headless --path godot_native --script res://tests/test_library_world_document_mobile.gd
godot --headless --path godot_native --script res://tests/test_library_rule_action.gd
godot --headless --path godot_native --script res://tests/test_library_return_to_scene.gd
```

- Mobile document: 103 checks, zero failures. Sizes: 360×640, 390×844,
  844×390 and 1440×900. Checks include physical font/target size, wrapped lines,
  containment, actual synthesized finger swipes, drag-out cancellation, unread
  cross-breakpoint resizing, partial-scroll preservation, exact-once close,
  inventory preservation and the related entrance record.
- Rule action: 47 checks, zero failures.
- Return to scene: 156 checks, zero failures.

This is focused native evidence, not full release acceptance. The original
screen was visually inspected, but a new graphical capture was unavailable in
this execution environment. The exact candidate still requires actual Godot
Web export scrolling/closing and visual review. Real iPhone/Android touch,
Safari and physical-device readability remain untested.
