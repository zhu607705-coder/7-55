# ADR: independent Godot migration and state ownership

Date: 2026-09-17. Baseline: 39ccde029b0cd25a6011739a4e4f98f8c898b2c3.
Status: experimental; not approved as the production runtime.

## Decision and scope

The owner's explicit new request authorizes this Godot experiment despite the
older root AGENTS prohibition. That exception is limited to godot-port, its data
exporter/tests, CI and this ADR. Existing web delivery, single-file packaging,
chapter logic and v35 save compatibility remain unchanged. The state-write fix
is an independent PR so either change can be reviewed/reverted without the other.

The repository already has TheaterRuntimeContract, spatial interaction helpers,
player configuration and runtime preload management. Reuse these boundaries.
Do not introduce another asset loader/cache or general event bus without a
measured gap. The new static data reader is a build-time library, not a second
runtime. Generated data is disposable; edits belong in existing source constants.

## Proposed state ownership

1. Persisted domain facts: inventory, chapter progress, solved puzzles,
   checkpoints. One authority; commands validate prerequisites and apply an
   atomic domain transition. Persist after an accepted transition.
2. Application lifecycle: active chapter/runtime and transition/loading/error
   state. An explicit coordinator owns enter/exit/disposal. Reject stale async
   completions with a generation token; do not keep parallel UI/engine authorities.
3. Transient scene state: velocity, animation time, camera, pointer, drag preview,
   focus and particles. Keep inside the scene/component; never serialize per frame.
4. Derived view state: visible prompts, available actions and journal projections.
   Compute with selectors from facts and authored content; do not persist a
   duplicate boolean for every display condition.

Do not remove existing persisted UI fields blindly: some currently contain puzzle
facts. Classify each field with save fixtures before separating schemas. Domain
rules must remain independently testable; engine nodes render effects and submit
commands. A future Godot session/autoload should be a thin owner of the domain
session, not a container for every node and every global signal.

## Reusable libraries and appropriate native replacements

Implemented separately: core/state/JsonSnapshotWriter owns immutable no-op
suppression and successful-write bookkeeping. SaveStore retains migration,
validation and storage I/O; there is no replacement persistence framework here.
Implemented here: scripts/lib/static-ts-data safely extracts literal constants
and validates spatial manifests. It never evaluates gameplay modules.

Next candidates, after collecting call-site comparisons: rectangle/coordinate
conversions with explicit units, inventory eligibility and accepted action
transitions, disposable subscriptions and scene lifecycle ownership. Similar
shape alone does not justify merging different chapter puzzle rules.

Native replacements in this slice: CharacterBody2D and CollisionShape2D for
movement/collision, InputMap for controls, Camera2D for viewport behavior,
Sprite2D regions and Y sorting for occlusion. Later reusable content can become
Godot Resources; local signals should express explicit events with an owner.
No custom physics solver, ECS, universal utils file or generic workflow engine.

## Performance evaluation, without assumed engine speedups

First measure cold/warm startup, transferred and decoded asset sizes, JS parse
and execution, p50/p95/p99 frame time, long tasks, memory after repeated scene
changes, and save latency/count. Keep device, resolution, route and asset cache
state fixed. Check scene listeners/timers after 20 enter/exit cycles. Separate
source/build sizes from actual bytes fetched before the first interaction.

State-writer no-op serialization reduction is a microbenchmark result, not FPS.
Real state changes still traverse SaveStore normalization and backup paths.
Profile those before adding debounce; preserve synchronous critical progress.

Large source scenes and SaveStore suggest responsibility boundaries, but file
length alone does not establish a runtime bottleneck. Move one tested behavior
at a time. Preserve normal web asset URLs and the explicit offline single-file
artifact contract as distinct products; do not force native packaging into the
web bundle. Godot migration must be evaluated against the same playable route.

## Campaign migration gates

A. Spatial slice: real-source data export, native parse/import, collision/input
   smoke checks and actual renderer screenshots. This PR is at this gate.
B. Theater domain: replay the same input commands against both implementations;
   compare accepted/rejected actions, facts, inventory and checkpoints. Then
   implement ticket/program/spotlight interactions and test reload recovery.
C. Phone/UI: Godot Control components, dialogue, accessibility, text/audio/video,
   touch and inventory drag/drop. Import old saves through a versioned,
   read-validate-convert path with fixtures; never overwrite unvalidated saves.
D. Remaining chapters: library, canteen, lake and chapter four, each with its own
   parity gate. The Three.js lake requires explicit 3D porting decisions.
E. Production decision: native builds and separate browser export, benchmarks,
   actual save round trips, Mac/mobile input/audio tests and complete walkthrough.

## Sources checked on 2026-09-17

- https://godotengine.org/download/linux/ (standard editor 4.7.2)
- https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html

Godot Web uses WebAssembly/WebGL2 with Compatibility rendering. Single-threaded
export is the default and avoids the multithreaded cross-origin-isolation setup.
Godot 4 C# projects currently cannot target Web. Thus this slice uses GDScript;
Web export remains a separate multi-file delivery, not the current offline HTML.
