# Shared map space contract

The active native `data/worlds.json` contains eight world types and thirteen
source plates/variants: dorm, north-up campus, library, canteen, theater,
side-view Qizhen approach, four lake zones, and teaching-building A1/A2/A3.
All use `scripts/space/world_space.gd`, backed by `data/native/world-space.json`.
`north_floor_space.gd` retains the measured floor data and its public API while
delegating common geometry/depth to `spatial_rules.gd`.

## Ground and boundaries

- On foot, the complete original `player_metrics.gd` rectangle must lie in the
  union of registered ground. Exact rectangle subtraction catches holes between
  samples and preserves seams between adjacent floor pieces. The dorm uses its
  original source-to-world transform and excludes the black exterior gutters.
- Library ground reaches the original solid wall bases at y=828. The painted
  wall face at y=803 is foreground, not an earlier collision boundary. The
  existing entrance aperture and controller-owned sliding leaves remain in use.
- Theater stage/backstage ground likewise reaches the source wall base at
  y=55. The curtain face does not close the approved chest-side stand or turn
  the clear path behind independent props into an air wall.
- North-up campus and the side-view approach keep separate source masks and
  projections. Every cell overlapped by the complete feet is tested; a centre
  and four corners are insufficient. Route segments check all cell-edge changes.
- Lake walking stays on dock land and the visible wooden pier. Water travel
  requires the existing kayak. The full 83×67 hull AABB at its current heading
  must be covered by the zone's authored water areas; centre containment alone
  is insufficient. Existing banks, props, entry headings, chase and zone gates
  still apply. Boats keep their own shape rather than borrowing human feet.
  Legacy rendered-zone aliases select the same basin as the visible plate.
- Existing source solids, native furniture, dynamic NPCs, doors and story gates
  supplement the ground envelope. A foreground image is never itself a new
  full-body wall. Existing safe recovery validates the same ground query.
- Ordinary keyboard input sweeps both axes to contact with substeps and a
  contact refinement. Click/touch routes include the complement of the ground
  union. The same query prevents large-frame movement through thin blockers.

## Ground depth

All ordinary world target/foreground comparisons use the physical foot bottom,
or the kayak hull bottom while boating. Exact contact retains the existing
behind-baseline convention. Source-authored animation/effect layer depths are
converted through `legacy_baseline`; clues, flights and authored overlays retain
their established presentation layers. Grounded Chapter 3 NPCs carry their real
rendered foot position and sort with independent theater props. The library
staff/counter and dock cupboard also compare physical baselines.
Independently painted target art sorts by ground depth even when both objects
are on the same side of the player; paint and alpha picking follow that exact
order. The lake's existing coincident observation/operation priority is retained.

Player and grounded NPC paint passes consume the same registered source covers.
Native canteen furniture and independently rebuilt theater props keep their own
actor planes; retired opaque source crops are excluded from those replacements.
Campus buildings use only the source-enabled landmark polygons. Side-view
facades stay background; its source foreground props remain separate.

## Campus artwork maps

The BUCT, Haidian/Rongmao, Changping and Chaoyang pilot maps retain their original
native feet pivots and circle radii (3, or 1.65 for the small pilot). Shared
`polygon_ground.gd` compiles only the exposed boundary of the paving union;
internal seams create no air walls. Strict interior tests during compilation
avoid `Geometry2D`'s inclusive edge tolerance erasing oblique boundaries.
The existing Haidian street join has one inserted boundary vertex to close a
subpixel triangular gap in otherwise continuous source paving; its original
vertices and all route waypoints remain intact.

The established building/trunk navigation polygons already include the foot
radius; they are not inflated twice. A `paving_navigation.gd` adapter connects
the existing AStar grid samples only when the entire swept circle is legal.
Ordinary input uses the same clearance and validates native separation before
accepting a moved pose. The pilot retains its authored route records, with
nearby legal foot goals for the two historical edge-touching waypoints.

## Verification and review

`tests/test_world_space.gd` covers every registered formal variant, perimeter
contact, whole-mask occupancy, ground holes and seams, rotated hull overhang,
source projection separation, oblique circle boundaries and unchanged story
state during geometry queries. Existing library/theater door, lake differential
and pursuit, source object, native NPC and campus travel tests remain required.
The full runner automatically discovers the new test.
The teaching-building guard also keeps its original physical foot rectangle
inside the ground union, uses exterior voids in navigation, and receives the
shared source foreground covers without requiring a later player paint pass.

`samples/world_space_review/run.mjs` launches the actual world with an isolated
developer save at a fixed 960×540 logical viewport. It captures all thirteen
maps, tests ordinary keyboard/touch/paddle input and records invalid frames.
Set `WORLD_SPACE_CAPTURE_DIR` to an absolute output folder; run at 1440×900 and
390×844 for the desktop/scaled viewport review. Overviews show non-ground in
red, source depth baselines in yellow and full feet/hull in green. The separate
`*_actual.png` captures hide the developer overlay.

This establishes a common spatial rule, not a new art acceptance for every
legacy silhouette. It does not integrate the separate A3 clean-base prototype,
replace source controller gates, export Godot Web, publish a release or establish
physical mobile-device acceptance.
