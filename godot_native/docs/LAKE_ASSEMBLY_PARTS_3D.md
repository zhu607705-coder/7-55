# Magnetic fishing-rod close-up: native object contract

`scenes/objects/lake_assembly_parts.tscn` is a baked, editor-openable Node3D scene. Its geometry is owned by the scene, appears as selectable MeshInstance3D children and needs no external texture, imported model, physics object or controller. `scripts/objects/lake_assembly_parts_3d.gd` can regenerate the geometry through `build_geometry()` and changes actual mesh/joint transforms during presentation.

## Objects and contacts

| Direct child | Rest transform | Contact marker, in the child's local space |
| --- | --- | --- |
| Rod | identity | TipAnchor (.45, 0, 0); GripAnchor (-1.44, 0, 0), on the handle centerline |
| Frame | position (.95, 0, 0) | SocketAnchor (-.5, 0, 0); ClaspSeatAnchor (.2569, .0312, -.2554); GripAnchor (.34418, .00777, .21903), centered on an intact near-facing rim segment |
| Rope | position (.45, 0, 0) | FreeEndAnchor updates as the cord is laid |
| MagneticClasp | position (1.2069, .0312, -.2554), rotation (0, 2.627, .056) radians | ContactAnchor (0, 0, 0); GripAnchor (0, .034, .204), centered on the rear bridge; separate DetentPivot |
| LeftHand / RightHand | presentation-controlled | GripAnchor (0, -.06, -.07); GraspAnchor is an alias |

The rod extends along +X. The frame lies mainly in XZ with a sagging net below Y=0. The hands point their fingers along local -Z; palm tops face +Y and blue sleeves extend along +Z. Set hand position by subtracting `hand.basis * hand.get_node("GripAnchor").position` from the desired contact, after setting hand orientation.

`get_anchor(name)` resolves `rod_tip`, `rod_grip`, `frame_socket`, `frame_grip`, `clasp_seat`, `clasp_contact`, `clasp_grip`, `rope_tip`, `left_grasp`, and `right_grasp`.

The clasp spans a chord of the oval, rather than its outside tangent. Its .056-radian roll matches the rim’s uneven heights. Actual rim-triangle ray tests place the steel sole centers .00190/.00194 units inside the surface, avoiding a light gap without burying the shoes. Keep this base roll when adding temporary detent yaw. `red_pole_contact` and `blue_pole_contact` resolve physical sole markers at local (-.10, -.0105, .010) and (.10, -.0105, .010).

## Presentation API

- `set_rope_progress(wrap, tighten)`: both inputs clamp to 0–1. Reveals one continuous swept cord, 3.35 successive turns, an over-under knot and a free tail. Tightening reduces coil radius from .118 to .074 and draws slack toward the socket. The three finer swept strands give the cord a real braided surface. Repeating the same pose does not allocate new meshes.
- `set_rod_flex(amount)`: clamps to -1–1, deforms the actual tapered shaft and surface grain, and moves the metal bindings, line guides and TipAnchor. Maximum tip displacement is ±.12 on local Y. The presentation must keep an attached Frame/Rope aligned to the changing rod tip.
- `set_hand_grip(side, amount)`: `left`/`right`, amount 0–1. Rotates three joints per finger plus the thumb, without changing the top-level hand transform.
- `MagneticClasp/DetentPivot.rotation.y` can animate the latch separately.

The root has no `_process`, input, save, inventory, controller or completion logic. The surrounding presentation owns assembly phases, joining/reparenting, lighting/camera, cancellation and final cleanup. These objects represent only the four existing recipe identities; sleeves/hands are presentation anatomy, not additional items.

## Geometry and validation

The baked scene contains 271 descendants, 214 MeshInstance3Ds and 26,386 vertices. Meshes use ordinary StandardMaterial3D roughness/metalness and no custom shader requirement. The frame's separate diagonal net strands, rim, hollow socket, oxide patches and lashings have real depth. The rod's reel includes separate spool flanges, a gold wound-line band, metal foot, axle, crank arm and dark knob. The generated reference informed the warm wood, neutral gunmetal, tan net, cream cord and chipped red/blue enamel; no image substitutes for an object mesh.

Run `godot --headless --path godot_native --script res://tests/test_lake_assembly_parts_3d.gd` after the project's ordinary import. The same scene/script/test can be copied to an asset-free temporary Godot project for lightweight checks. The test covers editable ownership, finite geometry and vertex budget, contact alignment, increasing rope geometry, tension, flex/recovery, articulated hands, allocation stability and object lifetime. These checks do not establish final camera composition or visual acceptance.
