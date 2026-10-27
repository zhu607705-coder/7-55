# Teaching-building spatial quality gate

The same rule now extends to every registered native map. See
[`WORLD_SPACE.md`](WORLD_SPACE.md) for the common authority, campus masks and
independent lake hull/paving-circle constraints.

The source plate contains floor, wall faces, elevator roofs and exterior facade
inside one 1672 × 941 image. Staying inside that image is insufficient grounding:
a gap between local colliders previously allowed walking onto the elevator wall.

`scripts/space/north_floor_space.gd` now defines one continuous ground envelope
per floor from `data/native/north-floor-space.json`. The **complete shared foot
rectangle** must be covered by the union of ground regions. Exact subtraction
checks area coverage, including narrow holes; it does not sample only a centre
or shrink the player body. The complement becomes touch-navigation obstacles.
Keyboard contact and the existing restore recovery use the same `can_stand` path.

The ground envelope supplements the existing source wall/furniture colliders,
phase geometry and runtime prop footprints. It does not reinterpret every
foreground crop as a solid. The two approved A1 passages behind the portrait
wall and the A1 entrance threshold remain explicit ground regions. A2/A3 north
wall faces and elevator tops are outside the ground envelope.

All affected native depth consumers compare the authored baseline with the
shared physical foot bottom, including source wall masks, chapter props/NPCs,
Room 204 tables, Room 301 props and generated north props. Exact contact uses
the retained source's behind-baseline convention. The original 22% wall reveal
is preserved. Player frame, scale, collision size, source coordinates, controller
gates and item/save contracts are unchanged.

Solid face registrations reference the existing source-object ID for their
rectangle and baseline. They are shared by player and NPC paint passes; the A3
lectern now hides the teacher's lower body while she stands behind it. No NPC
position is moved to conceal the problem. Source faces must be verified to
contain the object's solid surface before registration; broad source rectangles
containing floor pixels cannot be treated as transparent silhouettes.
NPCs also consume the exact same existing floor occluder array as the player,
including the A1 front counter and authored partial wall reveal. They do not
maintain an independent collection of per-character cover exceptions.

The sample in `samples/north_space_review/` displays the actual authorities at
once: red non-ground, cyan physical solids, yellow occlusion baselines and the
green full foot rectangle. It uses an isolated developer checkpoint. The overlay
is excluded from ordinary gameplay.

Verification includes continuous exterior boundaries, lift landing preservation,
full-foot contact, source passages, stale saved-pose recovery, touch-navigation
obstacles, depth/contact ordering, and real keyboard/touch attempts to climb or
route onto the lift wall. `test_north_floor_space.gd` is automatically included in
the full native runner. Relevant existing movement, object picking, source prop,
Room 301 and Chapter 4 regressions are retained.

This gate establishes the floor envelope and a common depth contract. It does
not certify every legacy furnishing silhouette or integrate the separate A3
clean-base art-review project. Full native acceptance, actual Godot Web release,
physical mobile acceptance and publishing remain separate checks.
