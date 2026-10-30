# Readable object workspaces: Koala and Formula

This is a separate follow-up to the direct-manipulation patch (#195). The user
reported that the page's presentation logic was confusing. We inspected actual
960×540 game renders before changing two representative workspaces, rather than
redesigning all 25 rooms without evidence.

## Koala: follow one physical processing path

Previously the input, original target, current paper, permanent example and
multiple history rows competed for attention. The module chain sat below those
outputs, so screen position did not explain the processing order.

The new workspace shows a clamped transformed input, a connected module chain,
and adjacent original/output papers with the same token spacing. Labelled sample
cards remain physical draggable objects. The crank runs the actual chain.
Examples, intermediate frames and hints are inside the existing notebook, opened
on demand. Changing the input or chain invalidates the displayed current output;
editing a custom pattern clears stale trial frames even if it is later edited
back to the same pattern. Cards keep the same size and grab point while held;
release only commits their already-visible nearby pose.

## Formula: keep the same car identifiable

Previously similar cars, anonymous result values and distant assembly/start
positions made it unclear which configuration produced which result. The bench
became empty after placing the car, and old gold position marks competed with the
current race.

Car 1 has a round number plate and car 2 a square plate. Those identities follow
the assembled objects, track lanes and aligned distance readings. The start line
is next to the assembly bench. Configuration records remain visible while the
actual car is on the track; the fixed reference configuration is adjacent.
Old trials remain in the physical notebook rather than being drawn over the
current race. Their captions use the recorded lighting/configuration, not the
current lamp setting. Returning a car to the start clears the previous result
without deleting historical records or accumulated completion. Incoming light angle and bracket tilt are labelled by their own
objects.

## What is unchanged

- Native Godot scene and actual model-driven objects, not a text dashboard.
- Koala operators, solution conditions and per-step experiment timing.
- Formula numerical model, 30-second trial, baseline and energy accounting.
- Direct-manipulation grip, visible detent and nearby-release safeguards.
- On-demand records, close/cancel and scaled input handling.

## Verification

The final code passed all 25 isolated native suites in 64.352 seconds, including
48 Koala and 221 Formula assertions, 230 entry/close/reopen checks and 1,740
original floor assertions. 161 Node runner/bundle/workflow contracts passed.
Actual final desktop captures are retained separately from intermediate layout
candidates. Desktop mouse coverage is not physical-phone validation or a
production-story release.
