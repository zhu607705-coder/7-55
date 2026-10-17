# Formal integration remains separate

This package is a presentation-only sample. Its only terminal signal is `preview_finished(run_id, reason)`. It has no `State`, save access, world routing, or story event forwarding. `played` and `skipped_preview` are local review labels and must never be treated as controller success.

## Existing production sequence to preserve

Rain warning → boarding attempt → wind/capsize → teacher and safety officer rescue → dorm rain-recovery / hairdryer-weather flow. This precedes the black-swan chase.

Source reference: `godot_native/scripts/controllers/c3_lake.gd` (warning, boarding, issued rescue session and consume); `godot_native/scripts/media/c3_rain_rescue_session.gd`; `godot_native/scripts/media/c3_rain_rescue.gd`; `godot_native/data/source/chapter3-qizhen-lake.content.json`.

Formal eligibility requires RPG / qizhen_lake, active boarding_tutorial, dock, on_foot, rain warning seen, safety not cleared, and rescue not completed. The controller issues a runtime-only session object and blocks input through the authored world-effect presenter.

Only that **same controller-issued session object**, its registered live presenter, monotonic duration, active eligibility, and matching state identity may be consumed. A native presentation adapter must be designed and tested separately; do not synthesize success, replace the issued object, route directly to the dorm, or forward this sample's local completion label to production.

On authorized production completion the existing consumer remains responsible for rainRescueCompleted, weatherAdjustmentRequested, capsize count, rain_recovery, dock/on_foot and the existing dorm handoff. The sample does none of these.

## Wet appearance

The existing TypeScript reference is `src/scenes/rpg/DormRainSoakedPlayerVisual.ts` with profile in `DormHubModel.ts`: eight normal droplets, three reduced-motion droplets, at most six footprints, and wet appearance active during rain_recovery while rescue completed and safety not cleared. Merely obtaining the dryer is not the dry-weather terminal fact.

This sample uses bounded native droplets/footprints only for visual review. It does not alter the formal wet-state predicate, synchronize phone records, or invent a damaged/repaired phone event.

## Acceptance before a future integration

- Retained session identity and duplicate/foreign result rejection
- Actual native animation duration and focus/pause accounting
- Skip, cancellation, scene change, presenter destruction and re-entry
- No new authority over progression or saves
- Formal transition back to the established dorm/hairdryer flow
- Visual contact, foreground water mask, narrow viewports and reduced motion
