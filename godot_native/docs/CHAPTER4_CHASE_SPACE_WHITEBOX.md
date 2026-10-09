# Independent guard chase: integrated whitebox

This is the authorized new-space/longer-obstacle-chase whitebox. It is not the
four-level 3D projection-stair puzzle or final art. The original `c4_chase`
controller route now opens this separate space. This is an additional user-requested
chase task, not a new number in the 54-entry animation design book.

## One geometry source

`data/native/chapter4-chase-space.json` owns 3000×1540 bounds, three wide return
lanes, two connecting stair landings, nine barriers/storage blocks, safe spawns,
two logical progress gates, exit and navigation anchors. Both player and guard
use the same actual barriers. Every passage beside a barrier is 100 source pixels
wide; exact pixel positioning is not the means of lengthening the challenge.

The pure `chapter4_chase_space.gd` module derives solid wall complements,
full-body collision, swept segment legality and a cached visibility graph from
that manifest. Guard path requests use the cached graph and connect their live
endpoints. A player pressing against a legal wall cannot freeze the guard simply
because the player's original foot box is half a pixel narrower.

The original speeds remain 208 player units/s and 174 guard units/s. A continuous
safe reference route measures 9,146.54 units: approximately 43.97 seconds of
physical travel at unchanged player speed. The 80ms sampled traversal takes
44.96 seconds including endpoint sampling. These are model figures, not an
actual-player completion-time claim or a waiting timer.

## Retained story and input contracts

- Enter this separate space from the existing authorized main-stair trigger
- Keep logical platforms 0/1/2, continuous ordered passage and accepted proof
  prefixes; validate actual swept movement through the new geometry
- Keep the original caught dialogue, failure timing, attempt increment, A1
  return and A2 exit/remaining story. Do not add items or rewards
- A normal save/reentry maps the original logical platform to the corresponding
  safe spawn. Old live nonces cannot authorize new progress
- Show upcoming route and obstacle openings early. Keep the pursuer's location
  readable, including when outside the following camera, without fake distance
- Use existing pointer/touch direction input and keyboard controls. Do not add
  bottom virtual buttons. Clear held input on release, focus loss, cancellation,
  resize, retry, scene exit and final handoff
- Do not make an unimplemented final-art claim from this technical whitebox

## Initial model evidence

`tests/test_chapter4_chase_space.gd` passed 1,296 checks. It covered full and
platform-resumed routes, original actor sizes and speeds, physical obstacle
collision, 95 sampled legal target positions, continuous navigation segments,
actual model movement around a block to catch a stationary target, wall-edge
body differences, forged teleport/time/ordered-platform/accepted-prefix cases.

Initial cloud headless CPU measurements: graph construction about 12ms and
95th-percentile path query about 1.57ms. These are not rendered frame times or
user-device performance. Rendered frame times and real physical input remain separate from these model
figures.


## Native consumer and controller adapter

`chapter4_chase_space_activity.gd` extends the existing activity. It retains the
original 5,200ms capture dialogue, callback/session lifecycle and failure rules,
while using one shared geometry source for actual player motion, guard movement
and controller proof validation. The original controller issues the space
revision in each session. Old or missing geometry proofs are rejected.

The renderer uses the existing player and guard sprite assets, a following camera
with obstacle lookahead, and an edge marker at the real off-screen guard position.
The three wide corridors and two connecting stair passages fill the available
activity viewport. Direct held pointer/touch input and keyboard movement remain;
no screen-bottom virtual buttons are added. Return is the sole header control.
The gray floor, barriers and storage blocks are explicitly whitebox art.

Every swept player step is checked. Unissued trace tails may coalesce across at
most 80ms only if the replacement's entire sweep is collision-free; necessary
barrier corners and every issued proof prefix remain intact. High-refresh PCs
therefore do not exhaust the proof-point limit merely by rendering more frames.
The original two logical platform transitions
commit only after the controller accepts the continuous proof. Ordinary save and
reentry restore that accepted logical platform to its corresponding new-space
spawn with a fresh nonce. Failure still increments one attempt and returns to
A1. Escape still requires both platforms and the real exit, then hands off to A2
without granting Room 202 arrival, a final-minute reward or story completion.

## Local integration evidence (before physical GUI acceptance)

- New integration suite: 59 checks, including actual simulated movement through
  the full route, ordinary save/reload at platform one, source Main routing,
  cancellation/resume, touch ownership, resize and four viewport layouts
- Existing chase rules adapted to the new geometry: 70 checks
- Chapter 4 controller: 117 checks; guard behavior: 17; capture ownership: 64
- Audio ownership: 12 checks; retained original-view regression: 119
- Continuous native campaign: chapters 1, 2, 3 and 4, zero failures (135.52s)
- Complete native script graph: 442 scripts, zero failures

The continuous campaign uses native input events and controller actions, with
explicit spatial setup. It is an automated regression, not a physical manual
playthrough. The independent-space manual route, rendered performance and final
visual polish are still awaiting separate verification.

## Review corrections

A 10,175-sample path exposed a validation defect: giving each small time step its
own one-pixel tolerance allowed all 9,146 route units in a claimed 101.75ms.
The validator now shares one one-pixel rounding budget across the complete
trace. It accumulates only positive distance error, so waiting cannot refill the
budget. Swept collision, ordered platforms and accepted prefixes still apply.
The dense path and both platform submissions are rejected; normal sampled and
actual native-input routes remain accepted.

The new ordinary-save integration test refuses any profile outside `/tmp/`
before accessing State or seeding a checkpoint. A dedicated workspace sentinel
profile verifies exit code 2 with both `save.json` and `save.previous.json`
unchanged. No formal profile is used for that refusal test.

## First physical whitebox trial and camera correction

An actual 1180×812 cloud window verified a stationary capture and the original
A1 retry/attempt increment, physical keyboard traversal through the first three
obstacles to platform one, Escape, ordinary save, normal window closure and
ordinary reload at platform one without reseeding. The next physical attempt
turned insufficiently before a middle-corridor block and was legitimately caught.
It did not finish the full course. The process later ended with the shell's
`Killed` message; the application log contained no GDScript exception. No cause
such as OOM is established by that evidence. A read-only desktop resource sampler
is prepared for the next test, without changing system limits.

That trial exposed unnecessary camera movement while dodging: the view used to
look 180 units along each instantaneous movement direction, including sideways
steps around a block. The view now follows a separate corridor centerline with
100 units of gentle forward anticipation. It previews connecting turns
continuously, without snapping on a direction-key change. The centerline is
presentation-only, not an actor navigation path or a completion proof. Original
speeds, collisions, guard pursuit, timing and controller proof are untouched.
Stair and corner floor arrows make the next turn visible. Reduced motion removes
the anticipation offset. Physical turn readability still requires a new trial.

Focused software-renderer samples from the first trial were about 29.58 FPS for
the successful first section and 23.83 FPS for the unsuccessful resumed section.
These include actual window/screenshot overhead and do not establish user GPU
performance. The gray corridors and empty surrounding areas remain whitebox
geometry, pending the original campus-interior art pass. No final-art or complete
manual-playthrough claim is made.


## 2026-10-09 acceptance and adaptive layout

The field now fills its usable rectangle with a uniform scale and an adaptive
camera extent. The 844×390 landscape field is 828×272, instead of an approximately
387×242 fixed-aspect island. Rotation refits the camera on the current actor
immediately. Six viewport regressions cover 1440×900, 1280×720, 1180×812,
430×860, 390×844 and 844×390. The only activity button remains Return.
The visible walls are the actual collision complement. Overlapping walkable
rectangles no longer draw false wall seams across open stair turns. Railings and
storage blocks now have distinct patterns. This remains a technical whitebox;
it is not the final campus-interior art pass.

Acceptance evidence is deliberately split by input and fixture:

- Actual foreground desktop keyboard input traversed all nine obstacles in one
  chase session, committed platforms 0→1→2, and handed off to A2. Its game clock
  was about 51.5 seconds. Window-focus pauses were used between inspection steps.
  This was not a replay of model coordinates or a no-pause human speed-run.
- A stationary capture used the original dialogue delay and returned to A1 with
  exactly one attempt increment. No movement speed, capture rule or success
  threshold was relaxed.
- Actual held mouse/ground input traversed the same first obstacle at 844×390 and
  390×844. Release stopped movement; Return saved; ordinary close and reopen
  restored the saved chase state without re-importing the test fixture.
- Full native screen-touch and drag event routes in both phone orientations
  passed in the integration suite. These are automated native event tests,
  not a claim of testing real phone touchscreen hardware.
- Integration now passes 153 checks. The previous 1309 model checks, 70 retained
  chase rules, 117 Chapter 4 checks, 17 guard checks, 64 capture checks, 12 audio
  checks and 119 retained-view checks passed on the integrated baseline.
- Continuous chapters 1–4 passed 854 checks, including a new actual-file save
  and reload at the chase's A2 exit, without granting Room 202 progress.

The older GUI fixture used the source developer chase checkpoint, which omits
prior native stair-traversal proof. Its A2 save was correctly rejected by the
existing strict save validator. That fixture is not evidence of a production
save failure. Subsequent GUI persistence tests imported a pre-chase save exported
from the genuine continuous native campaign. No story-proof fields were fabricated
and the strict save validator was unchanged.

## Final-baseline checks and remaining boundary

After integration onto `1c7e200b` (PRs 97 and 98), review found that recording every
rendered frame could exceed the 20,000-point proof limit on high-refresh PCs.
The collision-checked 80ms tail coalescing above fixes that without altering
speeds, collision geometry, proof limits or story rules. The 480 FPS native
consumer regression executed 20,783 movement frames, retained 548 proof points,
and completed the original A2 handoff. A tight obstacle-corner fixture confirms
that a colliding replacement chord is rejected, and issued prefixes remain exact.

Final-baseline local results: 480 parsed scripts, 1,309 model checks, 156 consumer
checks (including both full touch-event orientations and high-refresh travel),
and 70 retained chase-rule checks passed. A separate automated native-pointer
run imported the genuinely earned pre-chase campaign save, traversed the route,
validated and saved A2, reloaded the actual file, and exported that valid boundary:
32 checks passed. This is automated input, not an additional physical manual win.

The final full integration attempt was terminated with the shell's `Killed`
message while creating Main; its 156 preceding consumer checks passed separately.
A subsequent GUI A2 launch exited before a visible world or a normal reopen could
be inspected. No cause such as OOM is established. Therefore final-baseline Main
smoke and ordinary GUI A2 reopening remain unverified locally. Earlier physical
keyboard and phone-sized pointer evidence remains as described above. Keep this
whitebox PR in draft until the final checks and review are resolved.
