# 7:55 Project Development Report

# Chapter 3 Canteen Bike Transition Option A Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL — use superpowers:executing-plans to implement task-by-task.

**Goal:** Implement the approved full mount, playable 0–755m ride, full brake and dismount, and theater-junction handoff while limiting Hailuo 2.3 to two optional fixed macro inserts.

**Architecture:** Existing canteen facts form a start presentation gate and a finish presentation gate, so no new story phase or save version is required. One extracted Three.js rider rig renders the live chase, full-body transitions, exact anchor frames and native macro fallbacks. Hailuo media is presentation-only and can never write payment, distance, lives, completion, checkpoint or save state.

**Tech Stack:** React, TypeScript, Three.js, Phaser host integration, EventBus, AudioDirector, Vite single-file embedding, MiniMax CLI mmx 1.0.22, Hailuo 2.3, FFmpeg and browser QA.

---

## Preconditions and stop conditions

- Read docs/plans/2026-08-23-canteen-bike-transition-option-a-design.md and docs/assets/minimax-h3-canteen-755-theater/manifest.json before editing runtime code.
- Preserve all unrelated changes in the current dirty checkout.
- Do not use picture_05_chase_755m_1920x1080.png, either rejected transition raw clip, or the rejected review and promotional videos.
- Do not create a formal handoff at 700 meters.
- Do not submit M2 until the user explicitly accepts the M1 contact sheet and preview.
- Do not stage, commit, merge, rebase or push. Before any later Git mutation, fetch and present the three required local/relative/remote views for user scope selection.

## Task 1: Build a read-only transition contract verifier

**Files:**

- Create: scripts/verify-canteen-bike-transition.mjs
- Modify: package.json

**Step 1: Encode the authority boundary**

The verifier must fail when:

- payForBike() writes phase: chasing directly.
- CanteenChaseOverlay contains the old 900ms theater continuation.
- RpgGameHost lacks mutually exclusive start, ride and finish selectors.
- a 700-meter value appears in a presentation handoff condition.
- picture_05_chase_755m_1920x1080.png appears in an active media import or generation command.
- generated media calls GameStore, SaveStore, resolveChaseAttempt() or completeChase() directly.

**Step 2: Encode the timing and anchor contract**

Validate:

- Start gate has 91 frames at 24 FPS.
- Finish gate has 133 frames at 24 FPS.
- Hailuo M1 and M2 each select frames 0–29.
- A8 and A11 are the only Hailuo upload anchors.
- every declared anchor width and height is at most 5760.
- rejected media has integration_allowed=false.

**Step 3: Add the package command**

Add:

~~~json
"verify:canteen-bike-transition": "node scripts/verify-canteen-bike-transition.mjs"
~~~

**Step 4: Run the verifier before implementation**

Run:

~~~bash
npm run verify:canteen-bike-transition
~~~

Expected: fail on missing runtime selectors and missing shared-rig files. Record this as the expected red run.

## Task 2: Separate payment from the 0-meter start

**Files:**

- Modify: src/modules/ChapterThreeCanteenController.ts

**Step 1: Make payForBike() idempotent**

When phase is chase_ready and bikePaid is already true, return paid without deducting cash, consuming cafeteriaWages or repeating use_item.

On first payment:

- retain all existing mode, QR, cleaning, item and balance checks;
- consume cafeteriaWages once;
- deduct CANTEEN_BIKE_FARE_CENTS once;
- write bikePaid: true;
- keep phase: chase_ready;
- emit use_item;
- emit canteen_bike_paid with fareCents;
- do not emit canteen_chase_started.

**Step 2: Add startChase()**

Add a public method:

~~~ts
startChase(): boolean
~~~

Initial success guard:

~~~ts
state.canteenHunt.phase === "chase_ready"
  && state.canteenHunt.bikePaid
  && !state.canteenHunt.chaseCompleted
~~~

On first success:

- write phase: chasing;
- emit canteen_chase_started;
- return true.

Idempotent replay:

- phase=chasing and chaseCompleted=false returns true;
- it must not emit the event or write state again.

All other combinations return false.

**Step 3: Preserve the existing finish authority**

Do not weaken resolveChaseAttempt(). Story victory remains:

~~~ts
attempt.mode === "story" && distance === 755 && lives > 0
~~~

completeChase() remains the only method that writes theater_reached and campus_theater_junction.

**Step 4: Run focused static checks**

Run:

~~~bash
npm run typecheck
npm run verify:canteen-bike-transition
~~~

Expected: TypeScript passes; the transition verifier still fails only on later unimplemented files or selectors.

## Task 3: Extract one shared Three.js rider and bicycle rig

**Files:**

- Create: src/scenes/rpg/canteen-chase/ChaseRiderRig.ts
- Modify: src/scenes/rpg/canteen-chase/ChaseThreeRenderer.ts
- Modify: src/scenes/rpg/canteen-chase/ChasePrimitives.ts if shared primitive exports are required

**Step 1: Move the current rider construction**

Move buildRider() and RiderModel from ChaseThreeRenderer.ts into ChaseRiderRig.ts. Preserve:

- group name;
- scalar display scale 1.28;
- wheel radius and positions;
- torso, backpack, head, hair and limb colors;
- front assembly pivot;
- chase camera relationship;
- collision and steering calculations.

**Step 2: Split the hierarchy for mount and dismount**

Expose one model with explicit roots and pivots:

~~~ts
interface ChaseRiderRig {
  root: THREE.Group;
  bicycleRoot: THREE.Group;
  riderRoot: THREE.Group;
  frontAssembly: THREE.Group;
  wheels: readonly THREE.Mesh[];
  leftArm: THREE.Group;
  rightArm: THREE.Group;
  leftLeg: THREE.Group;
  rightLeg: THREE.Group;
  rightHand: THREE.Object3D;
  rightFoot: THREE.Object3D;
  rightGrip: THREE.Object3D;
  rightBrakeLever: THREE.Object3D;
  crank: THREE.Object3D;
  rightPedal: THREE.Object3D;
  chain: THREE.Object3D;
}
~~~

Add deterministic pose functions for:

- ride;
- stand_left;
- grip;
- leg_over;
- seated_balance;
- pedal_press;
- brake;
- left_foot_down;
- dismount_leg_over;
- stand_with_bike;
- push_bike.

**Step 3: Fix the canonical bicycle identity**

Use one blue frame palette across the campus anchor, chase renderer and transition renderer. Add the minimal visible geometry required by the close-ups:

- natural bare hands;
- right brake lever;
- crank;
- left and right pedals;
- short chain segment;
- small front basket;
- black tires and saddle;
- metal-gray wheel and control parts.

Do not change the chase player foot box, steering pivot, world scale or gameplay collision.

**Step 4: Reconnect ChaseThreeRenderer**

Replace local rider construction and pose math with createChaseRiderRig() and the shared ride pose. Keep existing lane movement, obstacle collision, wheel spin, camera and debug datasets.

**Step 5: Verify visual regression**

Run:

~~~bash
npm run typecheck
npm run verify:canteen-bike-transition
~~~

Open the canteen chase debug page at 0, 377 and 755 meters. Confirm:

- player center, scale and camera extent are stable;
- steering and wheel spin still update;
- lane changes and collision geometry remain unchanged;
- frame and bicycle identity are consistently blue.

Keep only requested formal anchors. Delete temporary before/after screenshots after inspection.

## Task 4: Implement the deterministic transition timeline and renderer

**Files:**

- Create: src/scenes/rpg/canteen-chase/CanteenBikeTransitionTimeline.ts
- Create: src/scenes/rpg/canteen-chase/CanteenBikeTransitionRenderer.ts
- Create: src/scenes/rpg/CanteenBikeTransitionOverlay.tsx
- Modify: src/styles/rpg.css

**Step 1: Encode the exact frame timeline**

CanteenBikeTransitionTimeline.ts exports:

- TRANSITION_FPS=24;
- start segments O1–O4 with frame ranges 0–90;
- finish segments E1–E5 with frame ranges 0–132;
- a pure frame-to-pose function;
- a pure frame-to-camera function;
- a pure frame-to-event function;
- the Hailuo segment ranges 41–70 and 10–39;
- the reduced-motion endpoints.

Frame counts must match manifest.json.

**Step 2: Build the native renderer**

CanteenBikeTransitionRenderer uses the shared rig and supports:

- stage=start or finish;
- wide mount camera;
- grip and pedal macro camera;
- clean 755-meter wide camera with the invalid foreground step removed;
- brake and front-wheel macro camera;
- full-body stop and dismount camera;
- parking movement;
- deterministic theater-door occlusion.

The single paper and all visible NPCs remain native objects. Neither appears in either macro camera.

**Step 3: Build one presentation-only React overlay**

The overlay accepts:

~~~ts
interface CanteenBikeTransitionOverlayProps {
  stage: "start" | "finish";
  events: EventBus;
  onComplete: (reason: CanteenBikeTransitionCompletionReason) => void;
}
~~~

Completion reasons:

- ended;
- timeout;
- media_error;
- play_rejected;
- reduced_motion;
- native_only.

Implement finishOnce() with a completedRef. It clears timers, pauses and disposes optional video, emits canteen_chase_presentation_finished and invokes onComplete exactly once.

**Step 4: Pause on hidden pages**

When document.visibilityState is hidden:

- pause Three.js timeline time;
- pause optional video;
- pause watchdog remaining time.

When visible:

- continue from the same frame;
- retry video.play();
- switch to native macro if play() fails.

Hidden pages must not cross O4 F090 or E5 F132.

**Step 5: Add the overlay layout**

Use the 960×540 logical RPG bounds, object-fit: contain for optional media, an opaque poster or native canvas before canplay, pointer-events: auto, touch-action: none and a z-index above all RPG controls.

At 390×844, constrain the layer to the existing mobile RPG canvas height.

**Step 6: Run the static gates**

Run:

~~~bash
npm run typecheck
npm run verify:canteen-bike-transition
~~~

Expected: both pass after the overlay and timeline are complete.

## Task 5: Insert the start, ride and finish gates in RpgGameHost

**Files:**

- Modify: src/scenes/rpg/RpgGameHost.tsx
- Modify: src/scenes/rpg/CanteenChaseOverlay.tsx

**Step 1: Replace chaseActive with mutually exclusive selectors**

Add:

~~~ts
const canteenStartTransitionActive =
  state.canteenHunt.phase === "chase_ready"
  && state.canteenHunt.bikePaid;

const canteenChaseRunActive =
  state.canteenHunt.phase === "chasing"
  && !state.canteenHunt.chaseCompleted;

const canteenFinishTransitionActive =
  state.canteenHunt.phase === "chasing"
  && state.canteenHunt.chaseCompleted
  && state.canteenHunt.chaseBestDistance >= 755;
~~~

Their OR becomes canteenExclusiveActive.

**Step 2: Render exactly one layer**

- Start gate completion calls canteenController.startChase().
- Ride attempt calls canteenController.resolveChaseAttempt().
- Finish gate completion calls canteenController.completeChase().

Add:

~~~tsx
data-canteen-handoff="start|ride|finish|none"
~~~

**Step 3: Block every input path**

Apply canteenExclusiveActive to:

- Phaser input;
- keyboard input;
- direction-stop event;
- task trigger and drawer;
- system and camera actions;
- reality mode;
- inventory drag;
- virtual direction controls;
- kayak touch controls;
- return-to-phone action.

**Step 4: Remove the old 900ms theater timer**

From CanteenChaseOverlay remove:

- onContinue;
- onContinueRef;
- theaterTransitionedRef;
- theaterTransitionTimerRef;
- enterTheater();
- scheduleTheaterEntry();
- the won-path 900ms continuation.

On a win:

- clamp distance to 755;
- emit canteen_chase_finish;
- submit the attempt once;
- publish the terminal snapshot;
- return.

Keep the lost-run 900ms restart and reset to distance 0, lives 3 and lane 1.

**Step 5: Emit the exact run-start payload**

On every story-run creation, including safe reload and failure restart, emit:

~~~ts
{
  mode: "story",
  distance: 0,
  goal: 755,
  lives: 3,
  lane: 1
}
~~~

**Step 6: Verify**

Run:

~~~bash
npm run typecheck
npm run verify:canteen-bike-transition
~~~

Expected: both pass.

## Task 6: Add audio events and fix the lost-run victory sound

**Files:**

- Modify: src/data/chapter3-canteen.audio.json
- Modify: src/modules/AudioDirector.ts only if the current event payload routing needs stage filtering
- Modify: src/scenes/rpg/CanteenBikeTransitionOverlay.tsx

**Step 1: Add presentation events**

Add or emit:

- canteen_bike_paid;
- canteen_chase_start_transition_started;
- canteen_chase_mount_detail;
- canteen_chase_brake_detail;
- canteen_chase_dismount;
- canteen_chase_paper_door;
- canteen_chase_presentation_finished.

**Step 2: Preserve music authority**

- Start transition does not start chase music.
- canteen_chase_started starts the current chase music.
- a reloaded real ride emits canteen_chase_run_started so music resumes.
- Finish transition keeps chase music until canteen_chase_completed.
- canteen_chase_completed stops chase music.

**Step 3: Move the paper burst**

Remove victory paper burst from a generic event that also fires on lost runs. Attach it to the successful finish transition event.

**Step 4: Verify**

Run:

~~~bash
npm run audio:chapter3:verify
npm run typecheck
~~~

Expected: both pass and the lost-run path has no victory burst mapping.

## Task 7: Add developer checkpoints and complete the verifier

**Files:**

- Modify: src/modules/DeveloperChannel.ts
- Modify: scripts/verify-canteen-bike-transition.mjs
- Modify: docs/gameplay-debug-walkthrough.md if checkpoint documentation is maintained there

**Step 1: Add c3-canteen-start-transition**

Seed:

- phase=chase_ready;
- bikeCodeRead=true;
- bikeLockCleaned=true;
- bikePaid=true;
- cafeteriaWages=false;
- cashCents=0;
- chaseCompleted=false;
- chaseBestDistance=0;
- rpgCheckpoint=campus_canteen_gate.

**Step 2: Keep c3-canteen-chase as the real 0-meter run**

Seed phase=chasing, bikePaid=true, chaseCompleted=false and chaseBestDistance=0.

**Step 3: Add c3-canteen-finish-transition**

Seed:

- phase=chasing;
- bikePaid=true;
- chaseCompleted=true;
- chaseAttemptCount=1;
- chaseBestDistance=755;
- chaseBestLives=2;
- chaseCollisions=1;
- rpgCheckpoint=campus_canteen_gate.

**Step 4: Keep c3-canteen-theater as the exterior checkpoint**

It remains phase=theater_reached and rpgCheckpoint=campus_theater_junction.

**Step 5: Run the completed verifier**

Run:

~~~bash
npm run verify:canteen-bike-transition
~~~

Expected: exit code 0 with explicit counts for selectors, checkpoints, timeline frames, forbidden 700-meter handoffs, disabled rejected media and anchor dimensions.

This first passing run is validation 1, so the mechanism remains a validated project-specific contract and is not yet a generalized rule.

## Task 8: Capture A7–A14 from the native renderer

**Files:**

- Create: src/tools/CanteenBikeTransitionDebug.tsx
- Modify: src/main.tsx or the existing debug-route switch
- Modify: docs/assets/minimax-h3-canteen-755-theater/manifest.json
- Add: docs/assets/minimax-h3-canteen-755-theater/anchors/picture_07_mount_wide_start_1920x1080.png
- Add: docs/assets/minimax-h3-canteen-755-theater/anchors/picture_08_mount_grip_pedal_macro_1920x1080.png
- Add: docs/assets/minimax-h3-canteen-755-theater/anchors/picture_09_chase_000m_final_1920x1080.png
- Add: docs/assets/minimax-h3-canteen-755-theater/anchors/picture_10_finish_clean_755m_1920x1080.png
- Add: docs/assets/minimax-h3-canteen-755-theater/anchors/picture_11_brake_lever_wheel_macro_1920x1080.png
- Add: docs/assets/minimax-h3-canteen-755-theater/anchors/picture_12_dismount_wide_1920x1080.png
- Add: docs/assets/minimax-h3-canteen-755-theater/anchors/subject_02_bicycle_canonical_2048x2048.png
- Add: docs/assets/minimax-h3-canteen-755-theater/anchors/subject_03_rider_action_canonical_2048x1024.png

**Step 1: Build deterministic debug controls**

Support query parameters:

- stage=start|finish;
- frame=integer;
- camera=wide|macro;
- sheet=bicycle|rider_action;
- hud=0;
- seed=fixed.

Freeze the renderer on the exact requested frame and expose data-ready=true only after the second rendered frame.

**Step 2: Capture exact frames**

Capture A7–A12 at 1920×1080 with no browser chrome, UI, alpha or scaling.

Render A13 and A14 directly from the shared rig, with a solid neutral background and exact equal cells. Do not use image generation for these sheets.

**Step 3: Validate every file**

Run ImageMagick identify and a small read-only validator to confirm:

- exact dimensions;
- PNG;
- 8-bit sRGB;
- no alpha;
- width and height at most 5760;
- manifest path exists;
- no forbidden old 755 anchor is marked active.

**Step 4: Inspect visually**

Inspect:

- player clothing and proportions;
- blue bicycle identity;
- one hand, one shoe, one pedal and one crank in A8;
- one hand, one brake lever, one fork and one wheel in A11;
- clean road in A10;
- no paper or NPC in A8 and A11;
- one paper and native NPCs only in wide views.

Temporary browser QA screenshots must be deleted. A7–A14 are requested deliverables and remain.

**Step 5: Update manifest statuses**

Change A7–A14 from capture_pending to captured_and_validated, recording dimensions, SHA-256, source frame and validation count.

## Task 9: Generate and review only Hailuo M1

**Files:**

- Create: docs/assets/minimax-h3-canteen-755-theater/prompts/m1-mount-grip-pedal.txt
- Create: docs/assets/minimax-h3-canteen-755-theater/generation/m1/raw/
- Create: docs/assets/minimax-h3-canteen-755-theater/generation/m1/review/
- Modify: docs/assets/minimax-h3-canteen-755-theater/manifest.json

**Step 1: Copy the approved M1 prompt exactly**

Copy only the M1 prompt body from prompts/hailuo23-option-a-macro-prompts.md into m1-mount-grip-pedal.txt.

**Step 2: Check authentication and quota**

Run:

~~~bash
mmx auth status
mmx quota
~~~

Do not expose the full key. If quota is unavailable, stop with anchor and prompt work intact.

**Step 3: Submit one paid task**

Run:

~~~bash
mount_prompt="$(<docs/assets/minimax-h3-canteen-755-theater/prompts/m1-mount-grip-pedal.txt)"
mmx video generate \
  --model MiniMax-Hailuo-2.3 \
  --image docs/assets/minimax-h3-canteen-755-theater/anchors/picture_08_mount_grip_pedal_macro_1920x1080.png \
  --prompt "$mount_prompt" \
  --download docs/assets/minimax-h3-canteen-755-theater/generation/m1/raw/m1_mount_grip_pedal_raw.mp4
~~~

Do not add duration, ratio, reference-image or last-frame flags to this Hailuo 2.3 path.

**Step 4: Validate the raw file**

Run:

~~~bash
ffprobe -v error \
  -show_entries stream=codec_name,pix_fmt,width,height,r_frame_rate,nb_frames \
  -show_entries format=duration \
  -of json \
  docs/assets/minimax-h3-canteen-755-theater/generation/m1/raw/m1_mount_grip_pedal_raw.mp4
~~~

Confirm H.264, yuv420p, 24 FPS, no audio and the actual returned dimensions, frame count and duration.

**Step 5: Review every frame**

Use the video-frames workflow to extract all frames to a temporary directory. Run entity-count and geometry measurements, then inspect the complete frame set. Produce:

- a five-frame join contact sheet;
- a full-sequence contact sheet;
- a machine-readable review JSON;
- a short preview using exactly frames 0–29.

Delete temporary extracted frames after review. Keep the requested contact sheets, review JSON and preview.

**Step 6: Stop for user acceptance**

Set one of:

- user_acceptance=pending and integration_allowed=false;
- user_acceptance=rejected and integration_allowed=false;
- user_acceptance=approved and integration_allowed still false until runtime derivation passes.

Do not submit M2 during this task.

## Task 10: Generate Hailuo M2 only after explicit M1 approval

**Files:**

- Create: docs/assets/minimax-h3-canteen-755-theater/prompts/m2-brake-lever-wheel.txt
- Create: docs/assets/minimax-h3-canteen-755-theater/generation/m2/raw/
- Create: docs/assets/minimax-h3-canteen-755-theater/generation/m2/review/
- Modify: docs/assets/minimax-h3-canteen-755-theater/manifest.json

Repeat Task 9 with:

- A11 as the only input image;
- the M2 prompt;
- output m2_brake_lever_wheel_raw.mp4;
- frames 0–29 as the proposed runtime interval.

The same full-frame rejection rule applies. Stop for explicit M2 visual acceptance before media integration.

## Task 11: Derive approved runtime media and embed it in the single file

**Files:**

- Add only after approval: src/assets/rpg/cinematics/chapter3-canteen/canteen_mount_grip_pedal.mp4
- Add only after approval: src/assets/rpg/cinematics/chapter3-canteen/canteen_brake_lever_wheel.mp4
- Create: src/scenes/rpg/canteen-chase/CanteenBikeTransitionMedia.ts
- Modify: src/scenes/rpg/CanteenBikeTransitionOverlay.tsx
- Modify: vite.config.ts
- Modify: src/vite-env.d.ts
- Modify: scripts/verify-canteen-bike-transition.mjs

**Step 1: Derive exactly 30 frames**

For each approved raw clip:

- select frames 0–29 only;
- scale to 960×540;
- preserve 24 FPS;
- encode H.264 yuv420p;
- remove all audio;
- use fragmented MP4 flags compatible with the existing MediaSource path.

**Step 2: Add an exact-path Vite query**

Add a chapter3-canteen-transition-embedded query that accepts only the two approved runtime MP4 paths. Do not rename or broaden the existing chapter4-h3-embedded contract.

**Step 3: Add native fallback selection**

CanteenBikeTransitionMedia.ts must expose approved status and exact asset metadata. When approval is false, import fails, MediaSource is unavailable, playback errors, or reduced motion is active, the overlay renders the native macro camera with identical frame timing.

**Step 4: Extend the verifier**

Validate runtime MP4:

- exact paths;
- 960×540;
- 24 FPS;
- 30 frames;
- H.264;
- yuv420p;
- no audio;
- expected SHA-256;
- active approval in manifest;
- no reference to rejected media.

**Step 5: Regress the Chapter 4 embed**

Run:

~~~bash
npm run chapter4:validate-story
npm run verify:canteen-bike-transition
~~~

The Chapter 4 command may still report the two previously recorded unrelated Task 7 and Task 10 failures. Confirm no new H3 embed failure is added.

## Task 12: Full browser and packaging validation

**Files:**

- Modify after successful verification: progress.md
- Modify after successful verification: project-development-report.md
- Modify after successful verification: docs/assets/minimax-h3-canteen-755-theater/README.md
- Modify after successful verification: docs/assets/minimax-h3-canteen-755-theater/manifest.json

**Step 1: Run static and packaging gates**

Run:

~~~bash
npm run verify:canteen-bike-transition
npm run audio:chapter3:verify
npm run typecheck
npm run build:single
npm run verify:single
git diff --check -- \
  src/modules/ChapterThreeCanteenController.ts \
  src/scenes/rpg/CanteenChaseOverlay.tsx \
  src/scenes/rpg/CanteenBikeTransitionOverlay.tsx \
  src/scenes/rpg/canteen-chase \
  src/scenes/rpg/RpgGameHost.tsx \
  src/data/chapter3-canteen.audio.json \
  src/modules/DeveloperChannel.ts \
  scripts/verify-canteen-bike-transition.mjs \
  docs/assets/minimax-h3-canteen-755-theater \
  docs/plans/2026-08-23-canteen-bike-transition-option-a-design.md
~~~

Expected: all task-scoped checks pass. Record unrelated pre-existing failures separately.

**Step 2: Validate the Start gate**

Use devCheckpoint=c3-canteen-start-transition in Blink, Gecko and WebKit.

Confirm:

- data-canteen-handoff=start;
- full mount action is visible;
- optional M1 or native fallback keeps the same timing;
- every input surface is blocked;
- ended and timeout each call startChase() once;
- refresh does not re-charge payment;
- first interactive payload is distance 0, goal 755, lives 3, lane 1.

**Step 3: Validate the real ride**

Use devCheckpoint=c3-canteen-chase.

Confirm:

- 0-meter start;
- 188, 377 and 566 nodes;
- no transition at 700;
- successful 755-meter finish;
- lost run restarts from 0;
- no console or page errors.

**Step 4: Validate the Finish gate**

Use devCheckpoint=c3-canteen-finish-transition.

Confirm:

- data-canteen-handoff=finish;
- no CanteenChaseOverlay mount;
- clean 755-meter wide frame;
- full brake, left-foot-down, leg-over, stand and bike-parking action;
- one native paper enters the door;
- M2 or native fallback keeps the same timing;
- ended and timeout each call completeChase() once;
- final state is theater_reached and campus_theater_junction;
- player still performs the existing theater entrance interaction.

**Step 5: Validate refresh and failure recovery**

Refresh during:

1. Start gate;
2. real ride;
3. Finish gate.

Expected:

1. Start gate replays without a second charge;
2. real ride safely restarts at 0;
3. Finish gate replays and never returns to 0.

Also force:

- media 404;
- decode error;
- play() rejection;
- MediaSource absence;
- prefers-reduced-motion.

Every case must reach the same controller-owned endpoint through the native fallback.

**Step 6: Validate viewports**

Run at:

- 1280×720;
- one non-16:9 desktop viewport;
- 390×844.

Pass conditions:

- stable 16:9 RPG bounds;
- no document overflow;
- no input leakage;
- no transparent frame revealing the underlying campus scene;
- zero new console and page errors.

**Step 7: Record evidence and clean temporary artifacts**

Update progress.md and this report with:

- exact commands and exit codes;
- browser matrix;
- media hashes and approvals;
- final single-file size and SHA-256;
- known unrelated failures;
- validation count.

Delete temporary screenshots, extracted frames, browser snapshots and local servers. Keep A7–A14, approved media, requested contact sheets and review JSON.

## Execution handoff

The design, prompt contract and implementation plan are complete. Runtime implementation begins with Task 1 and must stop after Task 9 for the user to judge M1 before any M2 paid generation.

## Completed slice: diverse transparent RPG character poses

- The Chapter 4 bakery crowd now uses an eight-frame student walk strip with per-NPC start offsets `0 / 3 / 6`, removing the synchronized repeated pose visible in the previous demo.
- MiniMax CLI `mmx 1.0.15` was exercised first. The `2048×2048` request timed out at the service and the successful `1024×1024` candidate failed the required grid, transparency, pixel-art, and prop constraints. The approved fallback produced four native-alpha source grids, stored as versioned `_v2` assets while preserving the previous sources.
- The protagonist now has three eight-frame direction groups; Phaser mirrors the side group for left movement. The Chapter 4 Three.js stair exception consumes the same 24 frames. Security-guard patrol animation expands to eight frames, and the cleaner set covers cart pushing, mopping, sign placement, light switching, rest, and idle motion.
- A follow-up visual defect was traced to the generated sheets crossing mathematical equal-cell boundaries. The previous builders cut off adjacent heads or feet and then scaled each partial silhouette to fill its target, causing visible size jumps. The protagonist source also contained eight down, seven up, and nine side components, so the old equal-cell direction mapping consumed one side pose as an up pose.
- Both builders now discover complete silhouettes over the whole source alpha plane, order them by spatial row and column, and apply one fixed uniform scale per direction group or role. Every output keeps at least two pixels of transparent head and foot padding. The eighth up frame is deterministically recovered by mirroring the fifth up source pose; eight of the nine side candidates form the side cycle. Runtime collision foot boxes, controller authority, and saves remain unchanged.
- `scripts/verify-rpg-character-sprite-integrity.py` is an executable regression gate for all four roles. It checks source component counts, head/foot padding, source/output silhouette overlap, aspect ratio, per-animation scale stability, and the recovered protagonist mapping.
- Static gates pass: `npm run verify:rpg-player`, `npm run verify:rpg-character-sprites`, `npm run chapter4:validate-assets`, `npm run typecheck`, `npm run build:single`, and `npm run verify:single`.
- Validation count: one rebuilt-single-file Chromium bakery run inspected two animation times; one rebuilt-single-file maintenance run inspected the complete protagonist, moving guard, cleaner, and cart; one contact-sheet review covered all current player directions and active NPC strips. Both browser checkpoints reported zero console errors and warnings.
- The rebuilt single-file artifact is `demo/index.html`, `247123278 bytes`, SHA-256 `b93366659343e7df98b842397075db587b5aaf84d43215976051c583b1622409`. It was loaded over local HTTP at the bakery and maintenance checkpoints. Direct `file:` automation remains outside Playwright CLI capability and is left for manual refresh confirmation.
- Reusable generation prompts, pose ordering, source paths, alpha-cleaning rules, and frame-rate contracts are recorded in `docs/plans/2026-08-22-diverse-transparent-rpg-character-sprites.md`.

## Completed implementation: Settings, desktop editing, and Chapter 4 CC98 study import

> **For Claude:** REQUIRED SUB-SKILL: Use the repository execution workflow task-by-task.

**Goal:** Turn Settings into a real pixel-phone app, add persisted desktop layout editing under deletion policy A, and connect the CC98 study board to the Chapter 4 Maxwell study-group investigation.

**Architecture:** `UiState` and `SaveStore` own normalized desktop order and optional-app visibility. A dedicated Settings scene reads existing capabilities, while Chapter 4 evidence stays in `chapter4.clueIds`; CC98 and WeChat expose controller-owned views of the same facts. Pointer Events and keyboard equivalents share one interaction contract.

**Tech Stack:** React, TypeScript, CSS, JSON content, existing `GameKit`, `SaveStore`, Chapter 4 controller/model, browser QA.

**Approved design:** `docs/plans/2026-08-18-settings-desktop-cc98-design.md`

### Task 1: Add persisted desktop layout state

**Files:** `src/core/types.ts`, `src/core/GameState.ts`, `src/core/SaveStore.ts`, `src/scenes/phone/P13_PhoneHome/index.tsx`

1. Define stable home-app IDs, default order, protected/removable policy, and normalization.
2. Add order and hidden optional IDs to `UiState` with old-save migration.
3. Replace fixed home JSX order with catalog rendering while preserving story locks and original slots.
4. Add long-press, drag-swap, keyboard move, delete confirmation, completion, and restore behavior.

### Task 2: Build the full Settings scene

**Files:** `src/core/types.ts`, `src/scenes/phone/registry.tsx`, `src/scenes/phone/P08_Settings/index.tsx`, `src/styles/scenes/p08-settings.css`, `src/scenes/phone/P13_PhoneHome/index.tsx`

1. Restore `settings` as a phone scene and route post-prologue Settings presses into it.
2. Build the searchable pixel settings index and real subpages.
3. Connect existing music, network/control-center, desktop, app restore, privacy diagnostics, and about data.
4. Keep Chapter 1 gear behavior intact.

### Task 3: Add controller-owned Settings investigation

**Files:** `src/modules/ChapterFourSettingsModel.ts`, `src/modules/ChapterFourTemporalMazeController.ts`, `src/scenes/phone/P08_Settings/index.tsx`, `src/core/QuestModel.ts`

1. Project the available records and accepted conflict set from Chapter 4 facts.
2. Validate selected records before appending the background-activity clue.
3. Record the optional desktop-layout clue without gating the main route.
4. Expose one current objective and readable repeat/error feedback.

### Task 4: Expand CC98 and connect the study-group import

**Files:** `src/data/cc98.posts.json`, `src/data/chapter4-cc98.content.json`, `src/scenes/phone/P02_CC98/index.tsx`, `src/modules/ChapterFourCc98Model.ts`, `src/modules/ChapterFourWechatModel.ts`, `src/scenes/phone/P14_Wechat/index.tsx`

1. Merge new default posts by ID so old local edits remain and newly shipped posts appear.
2. Show the Chapter 4 study thread only at its intended phase.
3. Route the existing `资料索引机` post into the same Chapter 4 study thread while the chapter is active, with a visible pending/completed import status.
4. Validate the three selected study facts, import the route into the Maxwell group, and persist one clue.
5. Render the imported summary in WeChat, while live student messages remain the route authority.

### Task 5: Verify without packaging

1. Run `npm run typecheck` and `npm run chapter4:validate-topology`.
2. Run path-scoped whitespace validation.
3. Exercise Settings entry, desktop mouse/touch/keyboard edits, deletion recovery, CC98 import, WeChat continuation, save/reload, and one old-save fixture in a real browser.
4. Inspect `430 × 860` and `390 × 844` with zero document overflow and zero console errors.
5. Record results in `progress.md`. Do not build or edit the standalone demo in this development pass.

### Completion and verification

- Persisted desktop editing is active: long press enters edit mode, pointer drag and keyboard arrows reorder applications, protected story applications ignore Delete, and only eligible optional applications render a remove control.
- Settings is a registered phone scene with eight searchable sections. Its Chapter 4 background-activity puzzle accepts the three authored 07:55 records and persists the resulting clue through `ChapterFourTemporalMazeController`.
- The CC98 feed merges shipped posts by stable ID without deleting local edits. The existing `资料索引机` row now opens the same Chapter 4 study-index thread and reports `可导入自习群 / 已导入自习群` in place. The thread validates three evidence choices, imports a compact index into the Maxwell WeChat group, and then hands route confirmation back to live student messages.
- One Blink gameplay run completed the full Settings record selection, CC98 import, WeChat archive open, and route-save chain. Desktop editing was checked with long press, protected-app Delete rejection, keyboard reordering, and navigation persistence.
- `390×844` checks of Settings, Phone Home, the expanded CC98 feed, and the legacy-post import entry reported zero document overflow; browser console errors were zero. The legacy `资料索引机` entry opened the same import panel in Blink, Firefox, and WebKit, with zero document overflow and console errors at the mobile viewport. A browser-created version-23 fixture without the new desktop fields loaded with the normalized default order and an empty hidden list.
- `npm run typecheck`, `npm run chapter4:validate-topology`, and path-scoped whitespace checks pass. Per the explicit development constraint, `npm run build:single` was not run and `demo/index.html` was not regenerated.

## Completed slice: Chapter 4 clock content expansion

- Corrected scope: the clock sequence now contains four gameplay levels with distinct internal progress; four DEV entries remain test shortcuts only.
- Level 1 rebuilds the B2-04 archive from three valid records and then selects the supported time anchor.
- Level 2 independently tunes and locks the hour and minute movements.
- Level 3 applies inverse corrections to gate, elevator, and classroom drift channels.
- Level 4 changes window width, speed, direction, and offset across three release protocols; failure resets protocol progress.
- Save version 21 persists archive clues, movement locks, corrected drift channels, and drift attempts. Version-20 saves infer completed internal facts from their existing clock step.
- Browser evidence: one full Blink playthrough reached `complete` with `3 archive clues / 2 movement locks / 3 corrected channels / 3 protocol hits`; all four DEV starts were inspected; `390×844` had zero document and scene overflow; console errors were zero.
- Delivery evidence: typecheck, Chapter 4 topology validation, scoped whitespace validation, single-file build, and single-file verification pass. The rebuilt artifact was reopened over HTTP at level 3 with the expected persisted prerequisites, zero overflow, and zero console errors. Artifact: `176572880 bytes`, SHA-256 `427c3237114b152db1f9ee900efad52961dda9b61bab02a9b74a53f0030441cc`.

## Completed slice: Chapter 4 four-stage clock calibration

- The clock page now has four controller-owned, persisted stages: target-card selection, hour/minute coarse wheels, second-only trimming, and a three-hit phase-release gate. Completing the gate writes `clock_phase_lock`, restores `08:00:00`, and closes Chapter 4.
- Four DEV checkpoints map one-to-one to those stages: `c4-clock-intro`, `c4-clock-coarse`, `c4-clock-precision`, and `c4-clock-release`. Version-19 saves migrate to the nearest matching stage under save version 20.
- The phone UI was rebuilt as an original high-contrast pixel terminal with a status ribbon, four-step rail, scene-time cards, digit reels, second ruler, timing lane, and completion ledger. The design uses the time-segment selection principle as a broad reference while keeping local art, labels, layout, and interaction rules.
- Blink validation covered every checkpoint plus one complete run from `07:55:23` to `complete`. The `699×739` scaled desktop and `390×844` mobile viewports reported zero document or clock-page overflow and zero console errors; the rebuilt offline artifact repeated the release checkpoint over local HTTP with the same result.
- `npm run typecheck`, `npm run chapter4:validate-topology`, the scoped whitespace check, `npm run build:single`, and `npm run verify:single` pass. The rebuilt standalone artifact is `176562655 bytes`.

## Completed slice: Qizhen sixth-capsize subtitle

- The persisted Qizhen `capsizeCount` remains the single threshold authority. When the count crosses from `5` to `6`, the controller emits one `qizhen_capsize_loss_subtitle_unlocked` event.
- The Qizhen Phaser scene consumes that event through the shared RPG bottom subtitle layer and displays the authored narrator line for `6500ms`. The ordinary recovery message is emitted first so it cannot replace the threshold subtitle in the same event turn.
- The count continues to cover balance-limit capsizes caused by repeated same-side strokes or excessive roll. Bank collisions remain stop-only, and black-swan contact remains a chase-attempt failure under the existing gameplay contract.
- Validation count: `1` Blink `1280×720` threshold matrix confirmed no unlock at count `5`, exactly one event/subtitle at `6`, and no repeat at `7`; `1` real-scene same-side-stroke run visibly triggered the sixth capsize subtitle during the capsize animation. Both runs reported zero page and console errors.
- `npm run typecheck`, the scoped `git diff --check`, and `npm run build:single` pass. The rebuilt `demo/index.html` mounted `qizhen_lake` with one Phaser canvas over HTTP, contained the authored line, and reported zero errors. Artifact: `176543541 bytes`, SHA-256 `23b2a49ce5f3f2cd88e6f5ca13ece3e36c4fe181a8b04ddc67821b2c191563d9`.

## Active direction: browser-only, three-floor temporal maze plus the Chapter 4 perspective stair

**Decision date:** 2026-08-09

- The active product runtime is React + TypeScript + Phaser. `RpgGameHost` mounts one Phaser canvas for campus, canteen, library, theater, Qizhen Lake, and the teaching building. The Chapter 4 misaligned-stair puzzle is the single approved Three.js surface and replaces the Phaser surface only while that puzzle is active.
- The perspective stair now permits view changes whenever the player is stationary, including stair endpoints and mechanism platforms. View input remains locked during walking, mechanism motion, perspective-edge crossing, and camera transitions. The second level assigns different views to its two upward seams: `south_west` followed by `top_oblique`.
- The second-level perspective seams now use their authored low-to-high direction for coincident-screen-space input, so Up consistently ascends on keyboard and the shared mobile D-pad. The upper landing meets the visible edge of the high platform; the exit slide waits to the side with more than `30px` of screen clearance and docks back into the original solved corridor at state `2`. Stationary players use real depth occlusion, while only the short seam-crossing animation receives a temporary foreground override.
- The perspective stair now uses three checked-in ambientCG CC0 color sources for plaster, concrete, and metal. Runtime processing converts each source to a `64×64` grayscale pixel tile, then applies the existing scene palette through `MeshBasicMaterial`; the active material contract excludes PBR maps and continuous lighting.
- Godot loading, iframe mounting, runtime selection, asset synchronization, export commands, and CI hash checks are retired. Existing Godot files remain historical reference material.
- The teaching building now uses three separate `1672×941` orthographic top-down floor plates in one `5400×941` Phaser world. The active story scope maps directly to A1, A2, and A3.
- One main elevator and one adjacent continuous stair core provide floor travel. The elevator keeps the full hall-call, wait, arrival, double-door, boarding, cabin-selection, travel, destination-opening, exit, and reset sequence.
- A1 implements airflow evidence and elevator-history synchronization. A2 implements NPC schedule observation, two independently reconfigured partitions, two wayfinding fragments, and the 203 return window. A3 implements old-signage observation, a three-slot wayfinding board whose middle slot stays empty, bridge-history observation, and the cross-floor return.
- `ChapterFourTemporalMazeController` and `ChapterFourMazeProjection` own progression and route projection. Phaser consumes the validated layout manifest, renders the current projection, and submits engine-neutral movement and action requests.
- Three authored floor-2 routes remain open against visible geometry, and the corresponding source-pixel collisions now include the two portrait-planter obstructions. Target stand positions were moved off painted walls and planters.
- Current browser verification covers the rebuilt single file in Chromium desktop, `390×844`, and a non-16:9 `1024×768` viewport, plus Firefox and WebKit desktop. All runs mounted one `16:9` Phaser canvas with no page or console errors and no document overflow.
- The Chapter 4 prologue paper now flies above head height across the arcade, entrance, lobby, and closing corridor. The former solid trail bars were replaced with broken pixel wind marks, and the lobby cleaner pursues from ground level with a stable trailing gap.
- Current single-file artifact: `180393544 bytes`, SHA-256 `c8ea0096cac447481d47e67dde1ccc21aeade4dc4d6456ad7d7441686ed9c0e5`.
- 2026-08-12 performance pass keeps gameplay assets lossless while removing retired Godot files from active Vite output, standardizing the WOFF2 pixel-font source, sharing Phaser asset guards, and caching/merging immutable Three.js chase primitives. The rebuilt single file is `176500593 bytes`, SHA-256 `d8d47703250cb18cebd08195aa7c1477618c7fccd03a9068eef7d6f28cc2bc7c`.
- The 755 m Three.js chase now reports about `192` draw calls and `72` live geometries in the checked Firefox checkpoint, compared with `805` and `861` before this pass. Dynamic riders, paper, obstacles, pedestrians, signs, and transparent shadows remain independent; only static same-material scenery is merged.
- `src/assets/rpg/campus/zijingang_campus_plate.png` is currently present and clean against the index, so the single-file build completed directly in the working tree.
- Qizhen Lake water-ripple fishing now uses real kayak-to-ripple distance without a heading gate. The same all-chapter rule applies to the dock locker, black swan, and every other interaction target. Kayak heading remains available only to locomotion physics and non-gating visual presentation, including steering, chase, roll, wakes, and captured-image composition.
- The theater ticket flow now reconciles the visible `0832` clue, provides a readable five-second second-wave wait with live network status, accepts the first deliberate pointer digit, recovers A+B half-ticket saves, and gives the gate reader a practical distance band with no facing requirement. A Chromium gameplay run completed campus-Wi-Fi failure, cellular second-wave pickup, ticket combination, and a real inventory drag through admission into `program_search`; Firefox and WebKit also loaded the repaired theater runtime without errors or overflow.
- Current verified single-file artifact after the ticket-flow repair: `176539012 bytes`, SHA-256 `f9b61e0f4563af9fbf1556ee3546870516b5de27c7f03d011cfdec61c100eba5`.

# Chapter 4 Three-Floor Temporal Campus Maze Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Convert the approved three-floor teaching-building preview into a playable campus time maze with one elevator, one adjacent stair core, a permanently walkable circulation loop, floor-specific puzzles, cross-floor evidence, save recovery, and a rebuilt single-file demo.

**Architecture:** Keep `GameState` and `ChapterFourTemporalMazeController` as the progression authority. Add a validated layout manifest and a pure `ChapterFourMazeProjection` selector that derives visible NPCs, doors, partitions, targets, dynamic collisions, and safe checkpoints from persisted facts. Phaser renders the approved floor plates and submits engine-neutral intents; runtime animation state stays scene-local.

**Tech Stack:** React, TypeScript, Phaser 3, JSON layout/content data, existing `RpgInteractionContract`, Vite single-file build, repository validator scripts, Playwright browser gameplay loop.

---

**Approved design:** `docs/plans/2026-08-09-chapter4-three-floor-temporal-maze-design.md`

**Execution precondition:** The current worktree contains many user and collaborator edits plus untracked Chapter 4 files. Do not run broad staging, reset, restore, or cleanup commands. A separate worktree cannot reproduce the untracked Chapter 4 baseline until the user authorizes a snapshot commit; execute with path-scoped edits in the current workspace or create that snapshot first.

### Task 1: Lock the three-floor layout contract with a failing validator

**Files:**
- Create: `src/data/chapter4-three-floor-maze.layout.json`
- Modify: `scripts/verify-chapter4-temporal-maze.mjs`
- Reference: `src/data/chapter4-temporal-maze.topology.json`

**Step 1: Add failing validation rules**

Extend `verify-chapter4-temporal-maze.mjs` to require:

```js
assert.equal(layout.floors.length, 3);
assert.deepEqual(layout.floors.map((floor) => floor.storyFloor), ["A1", "A2", "A3"]);
assert.equal(layout.transportCore.elevators.length, 1);
assert.equal(layout.transportCore.stairs.length, 1);
assert.ok(layout.safeRoutes.floor2South.height >= 128);
assert.ok(layout.safeRoutes.floor2East.width >= 128);
```

Also reject `B2`, `B3`, and `A4` from the three-floor runtime mapping, duplicate transport IDs, safe-route rectangles outside `1672×941`, and any authored static collision that overlaps a safe route.

**Step 2: Run the validator and confirm failure**

Run: `npm run chapter4:validate-topology`

Expected: FAIL because `chapter4-three-floor-maze.layout.json` does not exist.

**Step 3: Add the minimum layout manifest**

Define:

```json
{
  "schemaVersion": 1,
  "worldSize": { "width": 1672, "height": 941 },
  "floors": [
    { "displayFloor": 1, "storyFloor": "A1", "checkpoint": "c4_a1_lobby" },
    { "displayFloor": 2, "storyFloor": "A2", "checkpoint": "c4_a2_corridor" },
    { "displayFloor": 3, "storyFloor": "A3", "checkpoint": "c4_a3_wayfinding" }
  ],
  "transportCore": {
    "elevators": [{ "id": "main_elevator", "centerX": 836 }],
    "stairs": [{ "id": "main_stair", "left": 932, "top": 145, "right": 1070, "bottom": 252 }]
  },
  "safeRoutes": {
    "floor2West": { "left": 428, "top": 526, "right": 648, "bottom": 814 },
    "floor2East": { "left": 1006, "top": 526, "right": 1134, "bottom": 814 },
    "floor2South": { "left": 428, "top": 686, "right": 1134, "bottom": 814 }
  }
}
```

Add per-floor static collisions, dynamic gate definitions, anchor bounds, stair landings, elevator stand position, and safe spawns in the same file.

**Step 4: Run validation**

Run: `npm run chapter4:validate-topology && npm run typecheck`

Expected: PASS; no B-building story floor appears in the three-floor manifest.

**Step 5: Record a path-scoped checkpoint**

Run: `git diff --check -- src/data/chapter4-three-floor-maze.layout.json scripts/verify-chapter4-temporal-maze.mjs`

Expected: no whitespace errors. Commit only after explicit user authorization.

### Task 2: Add controller-owned maze movement and projection

**Files:**
- Create: `src/modules/ChapterFourMazeProjection.ts`
- Modify: `src/modules/ChapterFourTemporalMazeController.ts`
- Modify: `src/core/types.ts`
- Modify: `src/core/GameState.ts`
- Modify: `src/core/SaveStore.ts`
- Modify: `src/data/chapter4-temporal-maze.content.json`

**Step 1: Add failing projection checks to the validator**

Require deterministic projections for these facts:

```ts
type ChapterFourMazeRouteState =
  | "baseline"
  | "schedule_observed"
  | "corridor_reconfigured"
  | "wayfinding_aligned"
  | "return_window";
```

The selector must always keep the declared safe route open and may only activate dynamic collisions with visible door or partition IDs.

**Step 2: Run the validator and confirm failure**

Run: `npm run chapter4:validate-topology`

Expected: FAIL because the projection export is absent.

**Step 3: Implement the pure projection**

Export:

```ts
export interface ChapterFourMazeProjection {
  routeState: ChapterFourMazeRouteState;
  visibleNpcIds: string[];
  residualNpcIds: string[];
  activeDoorIds: string[];
  activePartitionIds: string[];
  activeCollisionIds: string[];
  activeTargetIds: string[];
  safeCheckpoint: RpgCheckpoint;
}

export function selectChapterFourMazeProjection(
  state: GameState["chapter4"]
): ChapterFourMazeProjection;
```

Derive route state from `phase`, `solvedPuzzleIds`, `clueIds`, `buildingTimeSeconds`, and `cycle`; do not persist duplicate derived booleans.

**Step 4: Add validated controller intents**

Add controller methods for:

- `moveWithinMaze({ floor, roomId, checkpoint, route })`
- `observeNpcSchedule()`
- `reconfigureCorridorBay(partitionId)`
- `collectWayfindingFragment(fragmentId)`
- `observeBridgeHistory()`
- `alignWayfindingBoard(order)`
- `openSecondFloorReturnWindow()`

Every accepted floor move updates `chapter4.floor`, `roomId`, `rpgCheckpoint` and emits one domain event. Wrong mode, missing evidence, invalid floor, and out-of-order requests return existing readable result classes.

**Step 5: Normalize saves**

If new stored fields remain necessary after projection work, add safe defaults and enum validation in `SaveStore`. Preserve old Chapter 4 saves at their nearest completed puzzle and safe A1/A2/A3 checkpoint.

**Step 6: Run validation**

Run: `npm run chapter4:validate-topology && npm run typecheck && git diff --check`

Expected: PASS; a simulated `A2 -> A3 -> A2` route restores `A2` with `return_window` projection.

### Task 3: Replace the floor plates with one elevator and one adjacent stair core

**Files:**
- Modify: `src/assets/rpg/interiors/finale/teaching_building_floor_1.png`
- Modify: `src/assets/rpg/interiors/finale/teaching_building_floor_2.png`
- Modify: `src/assets/rpg/interiors/finale/teaching_building_floor_3.png`
- Create: `src/assets/rpg/interiors/finale/teaching_building_elevator_doors.png`
- Modify: `scripts/build-finale-environment-manifest.mjs`
- Modify: `src/assets/rpg/interiors/finale/finale_environment_manifest.json`
- Modify: `src/assets/rpg/interiors/README.md`

The active runtime is browser-only Phaser. This task does not create or synchronize Godot copies.

**Step 1: Preserve source dimensions and make reference edits**

Use the three current floor plates as references. Maintain `1672×941`, orthographic top-down projection, nearest-neighbor pixel edges, existing room identities, lighting direction, and the source-pixel scale.

**Step 2: Rebuild the transport core on all three floors**

- Keep one elevator centered at `x=836`.
- Place one continuous stairwell immediately to its right.
- Replace the former extra elevator bays and remote stair entrances with non-interactive wall, display, or equipment details.
- Keep the corridor in front of the core clear.

**Step 3: Clear the 2F south circulation lane**

Replace the central lounge with two side seating islands above the lane. Keep `y=686..814` clear from `x=428..1134`; preserve a visible `128px` east-side route.

**Step 4: Create the door animation sheet**

Create six `72×96` frames: closed, seam-open, 25%, 50%, 75%, fully open. Each frame keeps the same door frame, center seam, cabin depth, hard highlights, and nearest-neighbor pixels.

**Step 5: Rebuild manifests and inspect the actual pixels**

Run: `npm run art:finale-environments`

Expected: all floor assets remain `1672×941`; hashes update; no resource exceeds the approved projection or format contract.

Open all three final PNGs at original resolution. Verify one elevator, one adjacent stair, no clipped walls, and a visible 2F continuous route.

### Task 4: Refactor the Phaser scene around the validated layout

**Files:**
- Modify: `src/scenes/rpg/ChapterFourTemporalMazeScene.ts`
- Modify: `src/scenes/rpg/RpgRuntimeDebug.ts`
- Reuse: `src/scenes/rpg/RpgInteractionContract.ts`

**Step 1: Make the validator reject hard-coded legacy routes**

Add checks that the scene no longer contains `west_stair`, `east_stair`, or `displayFloorFromStoryFloor()` mappings for `B2/B3/A4`.

**Step 2: Run and confirm failure**

Run: `npm run chapter4:validate-topology`

Expected: FAIL on the current two-stair and compressed-floor implementation.

**Step 3: Load layout-owned collisions and transport zones**

Replace scene-local floor collision arrays with parsed layout data. Define:

```ts
type TravelZoneId = "elevator" | "stair_up" | "stair_down";
```

Use one stairwell with floor-sensitive landings. 1F exposes `stair_up`, 2F exposes both, and 3F exposes `stair_down`.

**Step 4: Add dynamic visible collisions**

Create separate static and dynamic obstacle groups. On projection revision:

1. remove stale dynamic bodies;
2. draw or update the visible door/partition object;
3. enable the matching collision only after a close animation completes;
4. disable collision before an open animation begins.

**Step 5: Replace gray elevator rectangles**

Use the six-frame pixel door sheet. Keep the current waiting, arriving, boarding, selecting, traveling, exiting, and closing phases. Reduce door travel to the authored sheet width and keep the player behind the door frame during boarding.

**Step 6: Persist every floor transfer**

Route elevator and stair completion through `controller.moveWithinMaze()`. Remove the unhandled `chapter4_map_floor_changed` event as the sole state update.

**Step 7: Expand debug state**

Publish `routeState`, `activeCollisionIds`, `activeTargetIds`, `safeRouteRects`, `transportCore`, `currentStoryFloor`, and current safe checkpoint. Remove `mapPreviewOnly: true` and set `gameplayTargetsActive` from the projection.

**Step 8: Validate movement and source collision**

Run: `npm run typecheck && npm run chapter4:validate-topology`

Expected: PASS; all three safe spawns are clear; solid samples block; the three declared safe routes contain no active body.

### Task 5: Restore the Chapter 4 host UI and complete the 1F sequence

**Files:**
- Modify: `src/scenes/rpg/RpgGameHost.tsx`
- Modify: `src/components/temporal-maze/ElevatorTrackSyncGame.tsx`
- Modify: `src/core/QuestModel.ts`
- Modify: `src/modules/DeveloperChannel.ts`

**Step 1: Add a failing browser-state check**

At `?dev=1&devCheckpoint=c4-main-elevator`, assert that the task bar, reality toggle, and elevator track panel become available through the required state sequence.

Expected before change: FAIL because `chapter4MapPreviewOnly` hides them.

**Step 2: Replace permanent preview gating with phase gating**

Render Chapter 4 task UI and the reality toggle for the approved A1/A2/A3 phases. Keep movement locked only while a real puzzle panel or elevator cabin panel is open.

**Step 3: Reconnect the historical elevator panel**

Verify the complete chain:

```text
dark observe -> light operate -> misaligned feedback -> 81811 aligned
-> hall call -> door opens -> board -> select 2F -> arrive A2
```

**Step 4: Add DEV checkpoints**

Add or update `c4-main-elevator`, `c4-elevator-aligned`, `c4-a2-arrival`, `c4-a2-schedule-observed`, `c4-a3-wayfinding`, and `c4-a2-return-window`. Each seed includes real phase, clues, solved puzzles, floor, room, checkpoint, mode, and closed transient UI.

**Step 5: Run static checks**

Run: `npm run typecheck && git diff --check`

Expected: PASS.

### Task 6: Implement the 2F personnel schedule and walkable corridor puzzle

**Files:**
- Modify: `src/scenes/rpg/ChapterFourTemporalMazeScene.ts`
- Modify: `src/modules/ChapterFourTemporalMazeController.ts`
- Modify: `src/data/chapter4-temporal-maze.content.json`
- Reuse: `src/scenes/rpg/FinaleNpcTextures.ts`

**Step 1: Add a failing route assertion**

At the `c4-a2-arrival` projection, assert:

- floor 2 west/east/south safe routes are open;
- the player can reach 201, 202, 203, 204, open study, elevator, and stair stand positions;
- schedule targets remain inactive until dark observation.

Expected before change: FAIL on the blocked south route and missing targets.

**Step 2: Add three two-frame NPC routes**

Use existing pixel NPC textures for discussion students, a headphone student, and cleaning staff. Light mode displays current NPCs; dark mode displays route residuals and observed stops.

**Step 3: Add two visible movable partitions**

Each partition has an open/closed frame, exact bounds, stand position, required mode, and controller action. A wrong mode, excessive distance, missing observation, and repeated completion each return visible feedback.

**Step 4: Unlock the fragments and return window**

Completing the corridor reconfiguration records `corridor_bay_reconstruction`, enables two wayfinding fragments, and leaves the main loop open. After 3F completion, returning to 2F changes the 203 door state and activates the return-window target.

**Step 5: Run the gameplay loop**

Use the checked-in Playwright gameplay client with temporary action payloads. Walk the full 2F west/east/south loop, trigger both mode states, move both partitions, collect both fragments, leave by the adjacent stair, return, and enter the 203 window.

Expected: debug state and screenshot agree; no invisible wall, silent return, page error, or console error.

### Task 7: Implement the 3F wayfinding board and cross-floor return

**Files:**
- Create: `src/components/temporal-maze/WayfindingBoardGame.tsx`
- Modify: `src/scenes/rpg/RpgGameHost.tsx`
- Modify: `src/scenes/rpg/ChapterFourTemporalMazeScene.ts`
- Modify: `src/modules/ChapterFourTemporalMazeController.ts`
- Modify: `src/data/chapter4-temporal-maze.content.json`

**Step 1: Add a failing controller sequence**

Assert that the board rejects light-mode operation before old signage is observed and rejects an invalid fragment order without consuming evidence.

**Step 2: Build the accessible board panel**

Render three fragment slots, pointer/touch controls, keyboard selection, confirm, cancel, and one current-objective line. Do not list future route steps or the final destination.

**Step 3: Add dark-mode signage observation**

Activate old-signage residuals at the archive display and honor vestibule. One observation records all simultaneously visible equivalent signs.

**Step 4: Resolve bridge history**

Combine the A1 elevator time clue with A2 fragment clues. Correct alignment updates `wayfinding_fragment_board`, then observation of the resulting historical doorway updates `bridge_floor_discrimination` and unlocks the A3-to-A2 return instruction.

**Step 5: Verify the full cross-floor loop**

Run: `1F elevator -> 2F schedule -> 3F board -> 2F return window` through keyboard and touch.

Expected: the player uses both elevator and stair; prior floor state visibly changes on revisit; reloading at each safe checkpoint resumes the same objective.

### Task 8: Complete save recovery, interaction feedback, and browser acceptance

**Files:**
- Modify: `src/core/SaveStore.ts`
- Modify: `src/core/QuestModel.ts`
- Modify: `src/scenes/rpg/RpgGameHost.tsx`
- Modify: `progress.md`
- Modify: `project-development-report.md`

**Step 1: Run the static gate**

Run:

```bash
npm run chapter4:validate-topology
npm run typecheck
npm run build:single
git diff --check
```

Expected: all commands pass. If `npm run verify:single` still rejects unrelated files already present in `demo/`, use an isolated directory for the verifier and record that directory-scope limitation separately.

**Step 2: Validate save and re-entry**

For `c4-a2-arrival`, `c4-a3-wayfinding`, and `c4-a2-return-window`:

1. enter the checkpoint;
2. perform one accepted action;
3. refresh;
4. return to the phone home;
5. re-enter the RPG.

Expected: floor, room, checkpoint, mode, clues, solved puzzles, and current objective restore; task and inventory drawers reopen closed.

**Step 3: Run browser scenarios**

- Blink `1280×720`
- Blink non-`16:9` desktop viewport
- Gecko `1280×720`
- WebKit `1280×720`
- coarse-pointer `390×844`

Test movement, elevator, stair, mode switching, both puzzle panels, return-to-phone, fullscreen, save/reload, and scene re-entry. Fine-pointer layouts show no virtual direction buttons; coarse-pointer layouts retain all five touch controls.

**Step 4: Inspect screenshots and runtime text**

Capture gameplay screenshots for the single elevator, adjacent stair, 2F south route, 2F dark schedule, 3F board, and 2F return window. Open every screenshot and compare it with `render_game_to_text()`. Delete temporary screenshots after recording the result.

**Step 5: Rebuild and launch the final single file**

Run: `npm run build:single`

Open `demo/index.html` through local HTTP and direct `file://`. Repeat at least the elevator and 2F route scenarios. Record size, modification time, SHA-256, inline script/style counts, and external HTTP resource count.

**Step 6: Update the canonical report**

Append the real implementation scope, commands, browser matrix, validation count, remaining B-building boundary, final demo hash, and any known limitation to `progress.md` and this report. Do not claim the six-node B-building topology or independent stair prototype has entered the main line.

**Step 7: Commit only after authorization**

Use path-scoped staging. Do not include unrelated dirty-tree files.

## Archived prototype: Chapter 4 stairwell 3D spatial puzzles

**Goal:** Replace the rejected flat stair-rotation slice with a standalone, true-3D spatial puzzle prototype. The prototype contains exactly two levels because the current building topology has two authored stairwells: stair A and stair B.

**Current verified baseline:**

- `chapter4-monument-stair-demo.html` is the source preview entry and `demo/chapter4-monument-stair-demo.html` is its generated single-file deliverable.
- Stair A combines an entrance slide, a rotatable central staircase and an exit lift. All three must align, giving `36` possible mechanism states.
- Stair B combines two independently rotatable staircases, a middle lift and an exit slide. All four must align, giving `144` possible mechanism states.
- Three.js owns only this isolated prototype: orthographic 3D rendering, raycast interaction, mechanism animation, player path animation and local level completion.
- Movement is scene-directed: clicking the environment chooses the nearest forward route point. A broken connection makes the player walk to the current reachable edge and stop; a complete connection permits movement to the clicked point or exit. `Space` remains only as the keyboard-equivalent request to walk toward the exit.
- Each mechanism gives local aligned feedback without exposing the remaining solution. Level completion is gated by the simultaneous state of every module.
- The prototype does not mutate `GameState`, save data, quests, phone pages, or the active Phaser RPG runtime.
- Keyboard and touch controls complete the same two-level sequence. `render_game_to_text()` and `advanceTime(ms)` expose deterministic acceptance state.

**Integration boundary:** This prototype remains isolated and does not enter the current teaching-building main line. Any future reuse requires a new user approval after the base top-down map is accepted.

# Chapter 4 Three-View Pixel Stair Puzzle Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Upgrade the standalone two-level stairwell prototype into a deterministic three-view orthographic perspective puzzle with project-consistent pixel rendering, click-to-move navigation, one projected crossing in level A and two projected crossings in level B.

**Architecture:** Split the current monolithic Three.js tool into authored level data, a projection-connector graph, pixel presentation, player-sprite animation and the browser entry coordinator. The projection graph remains the only authority for temporary perspective edges; the renderer consumes its result and the movement system consumes the resulting navigation graph. The implementation stays isolated from `GameState`, saves and the main single-file build.

**Tech Stack:** TypeScript, Three.js orthographic rendering, DOM/CSS pixel HUD, Vite single-file build, existing RPG player PNG frames, deterministic browser debug hooks.

---

**Execution precondition:** Use a dedicated `codex/chapter4-stair-perspective-pixel` worktree after the current untracked prototype files are preserved through a user-authorized commit or explicit file copy. Do not modify or restore `src/assets/rpg/campus/zijingang_campus_plate.png`.

### Task 1: Extract shared puzzle types and authored level data

**Files:**
- Create: `src/tools/chapter4-monument-stair/StairTypes.ts`
- Create: `src/tools/chapter4-monument-stair/StairLevelDefinitions.ts`
- Modify: `src/tools/ChapterFourMonumentStairDemo.ts`

**Step 1: Define the state contracts**

Add `CameraViewId`, `StairDemoPhase`, `MechanismDefinition`, `NavigationNode`, `NavigationEdge`, `PerspectiveConnector`, `ProjectedConnection`, `StairLevelDefinition` and `StairDemoSnapshot`. Include the three camera IDs and the phase `camera_transition`.

**Step 2: Move level A and level B constants out of the renderer**

Encode all mechanism states, node positions, fixed edges, connector tangents, `linkGroup` values, camera whitelists, safe nodes and exit nodes in `StairLevelDefinitions.ts`. Keep `36` combinations for A and `144` for B.

**Step 3: Add source-level validation**

Implement `validateStairLevelDefinition()` to reject duplicate IDs, missing node references, perspective groups with fewer than two connectors, unsafe start/exit nodes and mechanism states outside their declared ranges.

**Step 4: Run type validation**

Run: `npm run typecheck`

Expected: TypeScript passes and the standalone entry imports both level definitions without changing visible behavior.

**Step 5: Record a checkpoint**

Run: `git diff --check`

Expected: no whitespace errors. Commit only after explicit user authorization.

### Task 2: Build the projection-connector graph

**Files:**
- Create: `src/tools/chapter4-monument-stair/StairProjectionGraph.ts`
- Modify: `src/tools/chapter4-monument-stair/StairTypes.ts`

**Step 1: Implement internal-screen projection**

Add a pure `projectConnector(connector, camera, 480, 270)` function returning screen position, projected tangent, view depth and visibility metadata.

**Step 2: Implement connection classification**

Add `classifyProjectedPair()` with the authored rules: same `linkGroup`, active-view whitelist, screen distance at most `6px`, opposing tangent tolerance `20°`, stable mechanism state and unobstructed ray.

Return one of:

```ts
type ProjectionPairState = "disconnected" | "invalid_direction" | "connected";
```

**Step 3: Implement graph rebuilding**

Build the active graph from fixed physical edges, mechanism-state edges and valid perspective edges. Return invalid-direction pairs separately for orange seam rendering.

**Step 4: Add deterministic self-check cases**

Create in-module development assertions for: over-distance rejection, wrong-group rejection, wrong-direction classification, allowed valid connection and camera whitelist rejection. Guard them behind `import.meta.env.DEV` so no test dependency is added.

**Step 5: Run validation**

Run: `npm run typecheck && npm run build:chapter4-stairs3d`

Expected: both commands pass; the generated standalone file remains self-contained.

### Task 3: Replace free camera drift with three authored view states

**Files:**
- Modify: `src/tools/ChapterFourMonumentStairDemo.ts`
- Modify: `src/tools/chapter-four-monument-stair-demo.css`

**Step 1: Remove pointer camera nudge**

Delete `pointerNudgeX`, `pointerNudgeY` and pointer-driven camera positioning. Keep pointer coordinates only for raycasting.

**Step 2: Add view controls**

Render three right-side view buttons with `data-camera-view`. Bind keyboard `1`, `2`, `3` and pointer/touch activation to the same `requestCameraView()` function.

**Step 3: Add a 480ms camera transition**

Interpolate position and `lookAt` target between authored view states. Set phase to `camera_transition`, lock mechanisms and movement, and rebuild projection edges only after the final camera matrix update.

**Step 4: Enforce safe-node switching**

Reject view changes while the player is outside a safe node or traversing a perspective edge. Keep buttons visible and disabled so the reason is readable.

**Step 5: Verify all three views**

Run the source preview and call each view through pointer and keyboard at level A start.

Expected: each transition finishes in `480ms ± 20ms`, creates a stable projection snapshot and does not drift after pointer movement.

### Task 4: Replace the linear route gate with graph-based click movement

**Files:**
- Create: `src/tools/chapter4-monument-stair/StairNavigation.ts`
- Modify: `src/tools/ChapterFourMonumentStairDemo.ts`

**Step 1: Implement shortest-path search**

Add breadth-first or Dijkstra traversal over active navigation edges. Return node IDs and edge IDs so movement can distinguish physical and perspective segments.

**Step 2: Implement reachable-edge fallback**

When the clicked node is unreachable, choose the boundary node in the current connected component whose projected position is closest to the clicked target direction.

**Step 3: Bind clicks to walk surfaces**

Tag every platform and stair surface with its nearest navigation node. Replace intersection with a single horizontal plane, because upper floors and stair treads require their real hit surfaces.

**Step 4: Lock perspective traversal**

Set `lockedPerspectiveEdgeId` while crossing a temporary edge. Preserve the character's screen position at the world-space handoff and reject camera, mechanism and reset input until the destination safe node is reached.

**Step 5: Verify blocked and valid movement**

Use `advanceTime(ms)` to run one blocked click and one projected crossing.

Expected: blocked movement ends on a graph boundary; valid movement ends on the requested node; the player never enters a node outside the active graph.

### Task 5: Convert the world renderer to the Chapter 4 pixel contract

**Files:**
- Create: `src/tools/chapter4-monument-stair/StairPixelStyle.ts`
- Modify: `src/tools/ChapterFourMonumentStairDemo.ts`
- Modify: `src/tools/chapter-four-monument-stair-demo.css`

**Step 1: Fix the internal render size**

Set the WebGL backing store to `480×270`, pixel ratio `1`, antialias `false`, and CSS display size to the `960×540` logical shell. Add `image-rendering: pixelated` and `crisp-edges` fallback.

**Step 2: Replace smooth presentation**

Remove ACES tone mapping, continuous fog, soft shadow maps, rounded geometry and continuous opacity animation. Apply the approved finite palette through flat materials and low-segment geometry.

**Step 3: Add hard pixel lighting**

Assign top, side and back-face color steps. Add low-resolution projected shadow tiles and `1–2px` dark structure edges.

**Step 4: Simplify architecture**

Keep only authored walls, columns, windows, floor signs, fire doors and sparse plants. Confirm no decoration intersects the screen-space bounds of the player, connectors or exits in any of the three views.

**Step 5: Visually compare against adjacent Chapter 4 scenes**

Compare the running stair frame with `src/assets/rpg/cinematics/chapter4-prologue/pixel/lobby_a.png` and the existing RPG player frames.

Expected: hard edges, comparable brightness, warm cream/gray-blue palette, no smooth 3D plastic appearance and no unreadable black region.

### Task 6: Replace the primitive character with the shared pixel player

**Files:**
- Create: `src/tools/chapter4-monument-stair/StairPlayerSprite.ts`
- Modify: `src/tools/ChapterFourMonumentStairDemo.ts`
- Reuse: `src/assets/rpg/player/player_down_0.png` through `player_side_3.png`

**Step 1: Load the shared player frames**

Create nearest-neighbor Three.js textures for down, up and side directions, four frames each. Disable mipmaps and set both filters to `NearestFilter`.

**Step 2: Preserve the shared timing and foot anchor**

Use `90ms` walk-frame timing and anchor the sprite at the shared foot position. Keep one constant display scale across all three orthographic views.

**Step 3: Orient frames from projected movement**

Select up/down/side and horizontal flip from the movement vector after projection through the active camera.

**Step 4: Stabilize perspective-edge crossing**

At the perspective handoff, measure pre/post projected foot position and apply a temporary world offset so visible displacement stays within `2px` at `480×270`.

**Step 5: Verify animation**

Walk the player across a physical stair, a lift, a horizontal platform and a perspective edge.

Expected: four-frame animation stays crisp; foot placement does not jitter; no primitive body remains.

### Task 7: Author level A and level B against the projection graph

**Files:**
- Modify: `src/tools/chapter4-monument-stair/StairLevelDefinitions.ts`
- Modify: `src/tools/ChapterFourMonumentStairDemo.ts`

**Step 1: Calibrate level A**

Place the entry slide, central stair, mid island and exit lift so only `south_west` creates `A_PERSPECTIVE_LINK`, followed by a physical top-view lift connection.

**Step 2: Run all level A mechanism states**

Enumerate all `36` states in a development validator.

Expected: one authored solution family reaches `A_EXIT`; no unintended projection edge appears.

**Step 3: Calibrate level B first crossing**

Place the lower stair and middle lift so only the required lower-stair state in `south_west` creates `B_LOWER_LINK`.

**Step 4: Calibrate level B invalid and valid upper crossings**

Make the east view produce `invalid_direction` and the top view plus required upper-stair state produce `B_UPPER_LINK`.

**Step 5: Run all level B mechanism states**

Enumerate all `144` states across all three views.

Expected: the authored sequence reaches `B_EXIT`; unintended physical or perspective shortcuts are absent; the invalid pair is visible in exactly one authored state/view combination.

### Task 8: Redesign the HUD and interaction feedback

**Files:**
- Modify: `src/tools/ChapterFourMonumentStairDemo.ts`
- Modify: `src/tools/chapter-four-monument-stair-demo.css`

**Step 1: Replace rounded glass panels**

Use square pixel panels, `2px` borders, offset shadows and the existing Fusion Pixel font. Remove blur and gradients.

**Step 2: Reduce persistent information**

Keep only the level title, current objective, selected mechanism controls and three view buttons. Move transient explanations into a single bottom status line.

**Step 3: Add connection feedback**

Render valid projected seams as cyan solid four-frame effects and invalid-direction seams as orange dashed three-frame effects.

**Step 4: Add input states**

Every disabled view or mechanism action exposes one short reason through the status region. Avoid queued inputs and repeated subtitles.

**Step 5: Verify mobile hit areas**

At `390×844`, confirm every view and mechanism control has at least `44×44` CSS px hit area, no overlap and no document overflow.

### Task 9: Complete deterministic hooks, build and browser acceptance

**Files:**
- Modify: `src/tools/ChapterFourMonumentStairDemo.ts`
- Modify: `progress.md`
- Modify: `project-development-report.md`

**Step 1: Expand the text snapshot**

Expose active view, player node, target node, physical edges, perspective edges, invalid pairs, mechanism values and input lock through `render_game_to_text()`.

**Step 2: Expand the debug API**

Add `setCameraView`, `setMechanismValue`, `clickNode`, `reset`, `replay` and deterministic `advanceTime` support.

**Step 3: Run static and standalone build checks**

Run:

```bash
npm run typecheck
npm run build:chapter4-stairs3d
git diff --check
```

Expected: all pass. The main `npm run build:single` may still fail only on the separately deleted IonicJian campus plate; record that boundary without restoring it.

**Step 4: Run complete browser flows**

Serve the source and generated standalone file over local HTTP. Complete both levels in Blink, Gecko and WebKit at `1280×720`, one non-`16:9` desktop viewport and `390×844`.

Expected: one valid projected edge in A, two valid projected edges plus one invalid-direction state in B, `phase=all_complete`, stable `16:9` shell, zero overflow and zero page or console errors.

**Step 5: Run accessibility and recovery checks**

Complete both levels using keyboard only, pointer only and touch emulation. Repeat with reduced motion. Trigger WebGL fallback and confirm a readable error surface.

**Step 6: Clean temporary evidence and record results**

Delete all generated QA screenshots after inspection. Update `progress.md` with validation counts, browser/version evidence and the independent/main-build boundary.

**Step 7: Commit only when authorized**

After the user approves the running two-level Demo, stage only the owned stair-design, stair-source, stair-style, standalone output and documentation files. Do not include unrelated dirty worktree changes.

## Active workstream: Chapter 4 temporal-maze playable slices

**Goal:** Convert the full Chapter 4 specification into controller-owned, save-safe gameplay. The current milestone covers the A1 airflow tutorial and the B3→B2 temporal stair alignment puzzle while preserving the six-floor building topology.

**Current verified baseline:**

- A1 arrival and airflow observation run in the generated single-file build.
- B3 stair echoes are observed in dark mode; the central stair rotates in 90-degree steps in light mode; only the vertical endpoint alignment permits passage to B2.
- The A1 west stair and the dedicated stairwell plate place fire doors on side landings and keep stair-flight continuations open.
- Chapter 4 state, save normalization, topology validation, real DEV checkpoints and quest progress are active.

**Remaining scope:** puzzles 2–6 and 8–13, the full NPC schedule, both elevators, the attendance-board logistics chain, two-cycle reset/anchor/echo behavior, spatial audio, Phaser main-line integration and the complete Blink/Gecko/WebKit acceptance matrix. The canonical itemized audit is `docs/plans/2026-08-08-chapter4-temporal-maze-gap-audit.md`.

## Active workstream: Chapter 4 section 8.1 prologue vertical slice

**Goal:** Deliver section 8.1, "纸条进入段永平教学楼", as the first complete Chapter 4 slice. It must start from the validated Qizhen Lake completion state, play the full 55-second cutscene, publish the closing-time task, persist the Chapter 4 entry fact, and hand control to the teaching-building flow without resetting existing state.

**Ownership split:**

- Kimi Code CLI owns the front-end UI and visual-performance layer for the cutscene: the full-bleed canvas composition, cinematic HUD, six-beat progress treatment, subtitle-safe region, skip/replay/task-card presentation, responsive layout, and canvas-only visual polish. Kimi must not generate PNG assets, move progression authority into UI state, or modify controller, save, quest, audio, Phaser runtime, and developer-checkpoint code.
- MiniMax CLI owns the 68-second instrumental music bed. The canonical generator, content definition, validated asset, and generated manifest remain the only accepted audio path. Failed or partial generation cannot replace the canonical manifest.
- Codex owns TypeScript state authority, controller rules, save migration, deterministic timeline, React presentation, Phaser scene contract, input and visibility lifecycle, task publication, DEV checkpoints, generated single-file build, and full browser acceptance.

**Current baseline:** The working tree already contains a deterministic six-beat canvas cutscene, Chapter 4 prologue controller, save field, audio event timeline, English voice assets, MiniMax music asset, skip/replay behavior, and `c4-prologue` checkpoints. These files are preserved and treated as unverified until rerun in the current checkout. The visual upgrade replaces only environment rendering; it does not move progression authority into the image layer.

### Task 1: Freeze section 8.1 requirements

**Files:**
- Read: `/Users/zhuhangcheng/.codex/attachments/16ae2580-aecd-4740-bb59-9457f32fba25/pasted-text.txt`
- Modify: `project-development-report.md`

**Acceptance:** The timeline remains `0-4s` fracture, `4-12s` lake exit, `12-24s` arcade, `24-32s` glass-door entry, `32-44s` wet lobby, and `44-55s` closing announcement. Final state is `phase=arrival`, `buildingTime=22:45:00`, and known node `A1_LOBBY`.

### Task 2: Implement the Kimi front-end UI pass

**Files:**
- Modify: `src/scenes/rpg/Chapter4PrologueOverlay.tsx`
- Modify: `src/scenes/rpg/chapter4-prologue/PrologueRenderer.ts`
- Modify: `src/styles/rpg.css`

**Steps:**
1. Invoke Kimi Code CLI with explicit front-end-only file ownership.
2. Keep the deterministic `960 × 540` canvas and improve the six authored shots with Canvas 2D layers, motion, lighting, depth, and scene transitions.
3. Add a compact cinematic status treatment that exposes only the current segment and elapsed progress; it must not disclose future puzzle answers.
4. Preserve the bottom subtitle safe region and keep skip, replay, and task-card controls reachable by pointer and keyboard.
5. Verify the layout at logical `960 × 540`, a non-16:9 desktop viewport, and `390 × 844` without changing controller or save logic.

### Task 3: Verify MiniMax music

**Files:**
- Verify: `src/assets/audio/chapter4/prologue/music_ch4_prologue_night_pursuit.mp3`
- Verify: `src/data/chapter4-prologue-music.audio.generated.json`
- Verify: `scripts/generate-chapter4-prologue-music-audio.mjs`

**Steps:**
1. Check MiniMax CLI authentication without exposing credentials.
2. Run the generator in `--verify-only` mode.
3. Confirm MP3 decode, `68,000 +/- 80ms`, 44.1 kHz stereo, source configuration hash, and file hash.

### Task 4: Review and integrate the Kimi UI patch

**Files:**
- Modify: `src/scenes/rpg/chapter4-prologue/PrologueRenderer.ts`
- Modify: `src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts` only if an asset-preload gate is required
- Modify: `src/styles/rpg.css`

**Steps:**
1. Review the actual Kimi diff and reject changes outside its three owned front-end files.
2. Preserve all dynamic object, subtitle, task-card, reduced-motion, skip, replay, and visibility-pause behavior.
3. Keep React local state presentation-only and do not advance or block story state based on animation completion.
4. Ensure the generated single-file build still works directly and through local HTTP.

### Task 5: Complete state and handoff rules

**Files:**
- Verify or modify: `src/modules/ChapterFourPrologueController.ts`
- Verify or modify: `src/core/types.ts`
- Verify or modify: `src/core/SaveStore.ts`
- Verify or modify: `src/App.tsx`
- Verify or modify: `src/core/DeveloperCheckpoints.ts`

**Acceptance:** Qizhen completion is required; skip and full playback converge on the same task card; confirmation preserves the complete validated `GameState`; old saves missing Chapter 4 state migrate safely; developer checkpoints remain session-only; a repeated formal entry does not replay after confirmation.

### Task 6: Rebuild and accept in real browsers

**Steps:**
1. Run Chapter 4 audio verification, `npm run typecheck`, `npm run build:single`, `npm run verify:single`, and `git diff --check`.
2. Serve the build over local HTTP and exercise `?devCheckpoint=c4-prologue` through full play, skip, replay, confirmation, reload, and return-to-phone paths.
3. Validate Blink, Gecko, and WebKit at `1280 × 720`, a non-16:9 desktop viewport, and `390 × 844`.
4. Pass only with stable `960 × 540` presentation, correct subtitle ownership, zero page or console errors, pause on hidden tab, and verified state after confirmation.
5. Delete temporary visual-QA screenshots after recording conclusions and update `progress.md` with current-run evidence.

---

## Active workstream: Qizhen Fishing Rhythm Audio Implementation Plan

> **For Codex:** Execute task-by-task in the current workspace. Preserve all pre-existing uncommitted scene changes and do not stage or commit them without explicit user instruction.

**Goal:** Generate the single 20-second MiniMax cue 《水纹 7:55》 first, derive verified beat nodes from the actual file, and prepare the audio contract for a unified fishing rhythm interface.

**Architecture:** Extend the existing Qizhen audio content and generator so the three current exploration beds remain unchanged and one fishing cue is added incrementally. Generated audio remains canonical only after decode, duration, format, configuration-hash, file-hash, and beat-grid verification. A separate beatmap JSON binds timing data to the audio SHA-256 and does not modify story progression until the music is approved. Music playback, visual judgment rings, and input judgment will share one `AudioContext.currentTime` origin when the fishing interface is implemented.

**Tech Stack:** TypeScript/JSON, Node.js scripts, MiniMax `mmx` CLI, FFmpeg/FFprobe, Web Audio timing contract.

---

## Current workspace constraint

- Active branch: `codex/bike-rush-visual-redesign`.
- Theater, Qizhen Lake, loop-transition, subtitle, quest, and `progress.md` changes already exist in the working tree.
- This task may add audio configuration, generated audio, manifests, beat-analysis scripts, beatmaps, and documentation. It must not rewrite or discard existing changes.

### Task 1: Freeze the approved music-first design

**Files:**
- Create: `docs/plans/2026-08-08-qizhen-fishing-rhythm-audio-design.md`
- Create: `project-development-report.md`

**Steps:**
1. Record the approved single-cue brief, audio-first timing authority, failure behavior, and acceptance criteria.
2. Run `git diff --check`.
3. Expected: no whitespace errors and no existing source change is removed.

### Task 2: Extend the Qizhen music contract

**Files:**
- Modify: `src/data/chapter3-qizhen.audio.content.json`
- Modify: `scripts/generate-chapter3-qizhen-audio.mjs`
- Modify: `src/data/chapter3-qizhen.audio.generated.json`

**Steps:**
1. Add `music_qizhen_fishing` at 20 seconds, 96 BPM, 4/4, eight bars, D Dorian, with 10/15/20-second landing points and the approved 7/5/5 melody phrases.
2. Change content validation from exactly three beds to four named beds while retaining uniqueness checks and assert the fishing timing contract.
3. Run `node scripts/generate-chapter3-qizhen-audio.mjs --verify-only`.
4. Expected before generation: failure naming only `music_qizhen_fishing`.

### Task 3: Generate and validate MiniMax music

**Files:**
- Create: `src/assets/audio/chapter3-qizhen/music/music_qizhen_fishing.mp3`
- Modify: `src/data/chapter3-qizhen.audio.generated.json`

**Steps:**
1. Run `mmx --version` and a non-mutating authentication/status check supported by the installed CLI.
2. Run `node scripts/generate-chapter3-qizhen-audio.mjs` without `--force` so the three validated existing beds are reused.
3. Run `ffprobe` on the new asset and confirm MP3, 44.1 kHz, stereo, and `20000±80ms`.
4. Run complete FFmpeg decode checks.
5. Run `node scripts/generate-chapter3-qizhen-audio.mjs --verify-only`.
6. Expected: all four beds verify and the generated manifest records source and file hashes.

**Current result (2026-08-11):** The installed `/opt/homebrew/bin/mmx` accepted the command and reached the MiniMax API, but the API rejected generation because the configured Token Plan had reached its usage limit. No partial MP3 or manifest was written. Rerun `MMX_BIN=/opt/homebrew/bin/mmx npm run audio:chapter3-qizhen` after quota is restored.

### Task 4: Derive beat nodes from the generated files

**Files:**
- Create: `scripts/analyze-qizhen-fishing-beats.mjs`
- Create: `src/data/chapter3-qizhen-fishing.beatmaps.json`

**Steps:**
1. Decode the MP3 to mono PCM without changing the canonical asset.
2. Detect transient energy peaks and estimate the initial beat offset and actual BPM.
3. Snap only peaks that remain consistent across the complete 20-second file.
4. Write `offsetMs`, `bpmEstimate`, `beatsMs`, `downbeatsMs`, `durationMs`, and `sourceSha256`.
5. Generate a temporary metronome-overlay review file outside the repository.
6. Listen to the overlay and adjust only the stored offset/downbeat classification when required.
7. Delete temporary overlay files after conclusions are recorded.

### Task 5: Validate the audio-first deliverable

**Files:**
- Modify: `progress.md`

**Steps:**
1. Run `npm run audio:chapter3:verify`.
2. Run `npm run typecheck`.
3. Run `git diff --check`.
4. Record duration, hashes, estimated BPM, beat count, 10/15/20-second landings, and any detected drift in `progress.md`.
5. Present the music file for user listening before implementing the fishing interface.

### Task 6: Fishing interface implementation after music approval

**Files:**
- Planned modify: `src/scenes/rpg/QizhenLakeScene.ts`
- Planned modify: `src/scenes/rpg/QizhenLakeModel.ts`
- Planned modify: `src/data/chapter3-qizhen-lake.content.json`
- Planned modify: `src/data/chapter3-qizhen.audio.json`
- Planned modify: `src/styles/rpg.css`

**Steps:**
1. Select real beat nodes from the approved beatmaps for the four catches.
2. Add AudioContext-clocked judgment, combo, retry, reduced-motion, keyboard, pointer, and touch behavior.
3. Bind the resulting domain events to music, judgment SFX, subtitles, and save-safe completion facts.
4. Validate the complete flow in Blink, Gecko, WebKit, and iOS WebKit before rebuilding `demo/index.html`.

---

## Active workstream: Chapter 4 prologue visual correction

- Current user-visible issue: the sequence was too dark and the checked-in high-resolution plates read as illustration rather than hard-edged pixel art.
- Runtime ownership: `PrologueVisualAssets.ts` loads environment plates; `PrologueRenderer.ts` owns dynamic paper, actors, light state, and transitions; `PrologueTimeline.ts` remains the timing authority.
- Production path: source plates remain at `src/assets/rpg/cinematics/chapter4-prologue/`; `npm run art:chapter4-prologue` deterministically produces the low-resolution, limited-palette runtime plates under `pixel/`.
- Transition rule: preserve paper direction and exit/entry edge across shots; use pixel reveals, the glass-door aperture, and staged light regions. Do not restore full-screen black fades.
- Paper motion rule: after the lakeside impact, paper flight stays visibly above the floor line. A separate softened shadow communicates height; outlined cyan-white wind bands and square particles communicate wind direction over both dark and reflective backgrounds. Generated plates and the fallback renderer share this rule.
- Current validation: Blink desktop/mobile, Firefox desktop, and WebKit desktop previously loaded the `960×540` sequence with no page or console errors and no horizontal overflow. The current wind-height revision has one new Blink validation across four key frames with zero page or console errors; the main single-file rebuild is currently blocked by the separately deleted `src/assets/rpg/campus/zijingang_campus_plate.png` and must be rerun after that asset decision is resolved.

---

## Completed slice: Chapter 4 A1 main-elevator replay to A2 arrival

- Stair-puzzle formal integration remains deferred. This slice continues directly from `elevator_track_sync`.
- The canonical elevator timeline is centralized in `src/modules/ChapterFourElevatorModel.ts`: selectable replay start `22:43:27–22:43:35`, correct start `22:43:31`, six-second player window, `920ms` door transition, `82%` passability threshold, and A2 arrival `22:43:50`.
- `ElevatorTrackSyncGame.tsx` renders the car, door, and player-window tracks. Dark mode records the history; light mode adjusts and starts replay. Misaligned starts remain editable and return explicit feedback.
- `ChapterFourTemporalMazeScene.ts` owns the visible door leaves, car opening, dynamic blocker, six-second hold, anti-pinch reopen, boarding lock, close, rise, floor indicator, scene restart, and A2 opening.
- Controller and save facts remain authoritative. Animation completion submits controller intents; it does not write progression directly.
- DEV coverage: `c4-elevator-aligned` and `c4-a2-arrival`.
- Current verification count: `1` complete Blink end-to-end pass at `1280×720`, `1` Blink non-16:9 smoke at `1100×760`, and `1` Blink touch-layout smoke at `390×844`. All three had zero page overflow and zero console/page errors. Gecko/WebKit runners are unavailable in the current Playwright cache, so cross-engine acceptance remains open.
- `npm run typecheck` and `npm run chapter4:validate-topology` pass. An isolated build containing the current source plus a temporary HEAD copy of the separately deleted campus plate passes `npm run build:single`; the actual worktree build remains blocked by that deletion.

---

## Completed slice: global object-distance and facing-agnostic interactions

- `RpgInteractionContract.ts` is the shared spatial authority. Proximity is measured from the player foot point to the nearest visible object edge. Mode, item identity, distance, and the real drop area may gate interaction; player facing never gates interaction. Legacy `stand` coordinates no longer gate interaction.
- Canteen, library, theater, Qizhen Lake, and all implemented Chapter 4 targets consume the rule. Qizhen kayak checks retain their continuous heading vector only for vehicle motion, chase, roll, and wakes.
- Persistent stand circles, connector lines, numbered pickup boards, and drop-label boxes were removed. Local hints use unboxed text; selected inventory items may outline only the real target bounds.
- Theater scene contract remains `1.1.0` and is consumed directly by Phaser. The retired engine bridge no longer participates in runtime selection.
- Current validation count: the global static guard scanned `256` active files with zero forbidden facing-gate matches. Three independent real-scene checks accepted interaction while the character faced away: Chapter 2 library, Chapter 3 theater, and Chapter 4 A3. All three retained the original visual facing and reported zero console/page errors.
- The earlier wrong-facing rejection evidence is historical and superseded by the all-chapter facing-agnostic rule dated 2026-08-22.

---

## Completed slice: Qizhen forward and reverse paddle contract

- Qizhen kayak input now treats left/right paddle keys as forward strokes by default. Holding `S/Down` changes either paddle to a reverse stroke; the mobile HUD exposes the same behavior through a hold modifier plus two paddle buttons.
- Signed velocity, reverse yaw, stern wake for forward travel, bow wake for reverse travel, and per-stroke directional wake pulses are implemented without adding persisted movement state.
- Boarding progression accepts only alternating forward strokes. Reverse strokes remain available for correction and produce explicit feedback without advancing the tutorial.
- Pointer ownership and scene lifecycle cleanup cover additional fingers, unrelated pointer releases, leaving the kayak, Phaser shutdown/recreate, and DEV checkpoint switching.
- Validation count: `3` desktop engines passed the same keyboard assertions, `1` mobile Blink layout passed multi-pointer reverse input, `1` boarding flow passed reverse rejection followed by four forward strokes, and `1` DEV scene-switch flow passed transient-state reset. All browser runs reported zero page and console errors.
- The isolated single-file build and verifier pass. Its exact artifact was copied to `demo/index.html`; the workspace verifier still rejects the pre-existing additional demo outputs before examining the copied artifact.

---

## Completed slice: Qizhen black-swan catch and channel collision calibration

- Pursuit now follows the measured swan-to-kayak gap. The speed curve is `168px/s` at or below `150px`, rises through smoothstep interpolation, and reaches `440px/s` at or above `360px`; the kayak maximum remains `340px/s`.
- A `4s` start grace prevents an immediate failure. After grace, a gap of `104px` triggers a visible catch, feedback, capsize animation, the `rpg_qizhen_chase_failed` controller intent, and a chase-only restart at `qizhen_chase / channel_chase`.
- Controller failure recovery resets current chase distance while preserving best distance and attempt count. Finish is checked before contact on the same frame.
- Alternating strokes now produce symmetric heading corrections around the starting direction. Repeated same-side strokes retain cumulative yaw, roll, and capsize behavior.
- The kayak collision body derives an axis-aligned bound from the rendered `83×67px` hull and heading. Runtime debug exposes body dimensions, actual gap, catch distance, grace readiness, swan speed, failure state, and source-pixel collision rectangles.
- Channel collisions were recalibrated to the visible raft, net, mooring posts, right dock, rocks, buoys, and stepped shores. Chase no longer removes raft or net collision. The safe chase start is `(1280,680)`, providing one complete visible route through the central water lane.
- Validation count: `1` final HTTP no-input run produced repeated swan-catch failures and restored `(1280,680)` with `phase=swan_chase` and `distance=0`; `1` final HTTP alternating-stroke run completed with `capsizeCount=0`, `chaseAttempts=1`, `distance=1000`, and `checkpoint=qizhen_complete`; `1` Vite collision-overlay run visually matched channel obstacle boundaries. Final single-file runs reported zero console and page errors.
- `npm run typecheck`, `git diff --check`, and isolated `npm run build:single` pass. The isolated build supplied the separately changed campus plate only inside the temporary copy. The final `demo/index.html` is `161078316 bytes`, SHA-256 `1dd891f7c6a0b4b99a95a3ea8c898debd7752debd108a88ce0f57776c4a63631`.

---

## Completed slice: Qizhen in-scene rhythm fishing runtime

- The four controller-owned catches now use a two-stage transaction. `precheckCast` validates the current scene, mode, observation, item, and story facts without mutation; the original `castAt` reward path runs only after a matching rhythm session passes and submits its session id.
- `QizhenFishingRhythmModel` owns four 96 BPM charts, timing windows, holds, tension, warnings, grades, fail sustain, and the two-failure assist mode. Runtime state remains scene-local and is cancelled on tab hiding or scene shutdown.
- `QizhenFishingRhythmVisual` keeps the kayak and source map visible, places shrinking action rings at the actual bobber, draws the bow-to-bobber tension line, and shows target, progress, tension, combo, and assist state under the shared task bar. The paper chart skips the grade animation and resolves directly into the existing chase transition.
- Desktop input uses `A/Left`, `D/Right`, and `Space`. Coarse-pointer layouts replace the kayak gesture controls with three rhythm buttons; pointer capture loss and cancellation both release holds. During the session the boat is frozen, camera is locked, and the mode toggle, inventory, normal subtitle, and paddle input are unavailable.
- Controlled-clock playback gave all four charts `S`, `passed=true`, `accuracy=1`, and final tension `50`. Real Blink keyboard play completed both the 10-second key chart and 20-second paper chart. The key was absent during the run and granted afterward. Paper completion produced exactly one capture event and one completion event, set `chaseAttempts=1`, and did not call the grade animation.
- A no-input fish run preserved `fishFeedPellets`, did not grant `smallCarp`, and left the phase at `tool_chain`. Two failed key runs activated assist on the third attempt while preserving the rod and withholding the key.
- Blink touch at `390×844` produced a perfect first hook without moving the kayak; all three buttons measured about `75×75 CSS px`, document dimensions matched the viewport, and normal overlays were hidden. Chromium, Firefox, and WebKit each accepted the first hook with zero page or console errors.
- `music_qizhen_fishing` is authored in the content contract and timeline, but MiniMax again rejected generation because the Token Plan is exhausted. Atomic generation left the canonical MP3 and manifest untouched. The playable fallback uses a low-volume metronome scheduled on the same `AudioContext.currentTime` authority; existing validated Qizhen effects temporarily cover warning, success, and failure cues.
- `npm run typecheck` and `npm run build:single` pass for the playable runtime. The generated cue and five dedicated fishing effects remain the only open part of the audio acceptance contract.

---

## Completed slice: stitched three-floor teaching building map

- The rejected one-floor preview is replaced by three `1672×941` orthographic pixel-art plates authored at the canteen/library scale. They cover the main entrance, aligned elevators and stairs, Maxwell Bakery, classroom vestibules, open learning space, archive/media/report/smart-classroom rooms, and alumni portrait galleries.
- `ChapterFourTemporalMazeScene.ts` places all three floors in one `5400×941` Phaser world with `192px` gaps. The active camera remains at source-pixel zoom `1`, follows the player, and clamps to one floor so the map reads as an explorable interior rather than a whole-floor thumbnail.
- Elevator travel supports pointer, touch, number keys, and arrow-plus-Enter selection. The west stair descends and the east stair ascends. Every travel interaction requires proximity to the visible circulation core and an upward facing direction.
- Seventeen source-pixel story anchors expose Maxwell Bakery, classroom entrances, study areas, and alumni displays for later controller-owned plot work. The current slice deliberately keeps story objectives and puzzle panels inactive.
- Verification count is `6`: three desktop visual/interaction checks, one `390×844` touch flow, one `1280×800` letterbox check, and one rebuilt single-file HTTP flow. All observed runs had one Phaser canvas, no document overflow, and zero page/console errors.
- `npm run art:finale-environments`, `npm run typecheck`, and `npm run build:single` pass. The isolated verifier reports `168597229 bytes`, `2` inline scripts, `1` inline style, SHA-256 `3d8b1129d98cdc2ca0a7f28bd638e7d18de2dac0cd3a129d434905f13aaab85e`.

---

## Completed slice: theater CC98 two-wave ticket commission

- Reaching the theater publishes a controller-owned CC98 request for a spare ticket to the student production. Accepting it unlocks the existing theater kiosk as the claim surface.
- The first release wave fails on `campus_wifi` and records `first_wave_failed`. The second wave cannot resolve until the player switches to `cellular`. If cellular data is already active for wave one, the claim resolves immediately and records `cc98TicketClaimedWave=1`.
- A successful commission grants only `theaterTicketHalfB`. Poster cleaning still grants half A, and the existing combination, admission gate, program-order, prop-box, spotlight, and Qizhen transitions remain intact.
- CC98, phone notifications, the RPG task model, the theater kiosk, and developer checkpoints consume the same `TheaterHuntState` phase. The theater RPG shell exposes a small network toggle only while a ticket wave is active.
- Save version `19` adds the commission phase and claimed wave. The legacy Qizhen migration uses the fixed version-18 cutoff and preserves any historical state that already records completion. Browser migration checks preserve v17 and v18 completed lake saves while still moving an unfinished v17 `chase_ready` save into `swan_chase`.
- One complete Blink matrix passed at `1280×720`, including wave-one Wi-Fi failure, second-wave cellular enforcement, wave-one cellular success, ticket combination, CC98 deep link, and v18 migration. One `390×844` check passed with no document overflow. The generated single-file artifact also mounted the theater Phaser canvas and accepted the network-mode change with zero page or console errors.
- `npm run typecheck`, `npm run build:single`, and `npm run verify:single` pass. Current `demo/index.html`: `176535261 bytes`, SHA-256 `632ea20628891a3d1ecfcb495030b2d2a1ce9e59004f19321816c6f1c02fcfe5`.

---

## Completed slice: theater ticket pickup recovery and handoff geometry

- Scope analyzed: the entry-ticket path inside `theater_interior`, covering kiosk code submission, wave-state transition, half-ticket recovery, quest projection, and the walk-up area in front of the gate reader.
- Confirmed defects: a correct `0832` could still fail if the hidden `ticketCodeRead` fact was false; the lobby spawn and kiosk/gate bounds made the intended standing positions read poorly; and the automatic `halfA + halfB -> temporaryTheaterTicket` merge depended on one transient event, so reload and some DEV seeds could strand the player with two halves.
- Implemented fix: correct code submission now backfills the observation fact, the lobby spawn moves above the south wall, the kiosk accepts `toward_target` facing, the gate reader gets a taller reachable interaction body, kiosk-complete state short-circuits back to inventory feedback, and `theater_interior_opened` now calls controller recovery so a resumed scene recombines the ticket if both halves are already present.
- User-visible guidance changed with the state machine: the quest model now points to CC98 acceptance, first-wave retry, enabling cellular data, recovering half A, combining the halves when needed, and dragging the finished ticket to the right-side reader. This removes the former generic “进入剧院” task while the player is still blocked at the lobby.
- Validation count: `1` Blink keyboard run at `1280×720` completed the actual route `accepted -> first_wave_failed -> delivered`, ending with `temporaryTheaterTicket=true` and the quest objective switched to gate handoff. `1` Blink pointer run opened the panel and completed the first-wave failure branch through mouse digit input, confirming the first click is no longer swallowed. `1` Blink geometry run moved from the kiosk back to the gate after second-wave success and ended with `activeTarget=theater_ticket_gate`. All three runs reported zero page and console errors. Cross-engine validation count for this repair remains `0`.
- Build evidence: `npm run typecheck`, `npm run build:single`, and `npm run verify:single` passed after the repair. Current `demo/index.html`: `176537375 bytes`, SHA-256 `f1be0073c6a2604e4a5d8d57a0809f43475da2db063bd510261aa3d7d730ef1e`.

---

## Completed slice: move both theater ticket-release waves into the phone

- The CC98 theater thread now owns the full ticket-release interaction. After accepting the commission and reading the `08:32` theater residual, the player submits wave one from the embedded phone ticket portal, opens the shared control center from that card, and submits wave two from the same page after the visible five-second wait.
- Campus Wi-Fi always records `first_wave_failed`; cellular data can win wave one immediately and shows “你的运气很好，但是钱包就没那么好了”. After a wave-two failure path, the phone portal remains resumable on cellular even though normal CC98 browsing still requires campus Wi-Fi.
- A phone win records only `cc98TicketCommissionPhase=delivered` and `cc98TicketClaimedWave`. It does not grant `theaterTicketHalfB`. The theater kiosk is now a physical pickup surface: the player enters the phone receipt code `0832`, the controller prints half B once, and the existing A+B combination and gate flow continue unchanged.
- The RPG-only network toggle, RPG wave countdown, and theater-local wave dialogue handlers were removed. Quest text, phone notifications, developer checkpoints, the CC98 network exception, theater feedback, and audio event mappings now describe the same phone-to-kiosk handoff.
- Validation count: `1` Blink real-button run completed Wi-Fi wave-one failure, control-center switch to cellular, phone wave-two success, and receipt generation with `halfB=false`. `1` independent first-wave-cellular checkpoint showed the required wallet line and `claimedWave=1`. `1` theater controller pickup run accepted `0832`, changed `halfB` from false to true, and advanced the objective to ticket combination. The inspected phone screenshot showed the mobile-data badge, wave-two receipt, `0832`, and no RPG ticket controls; console errors were `0`.
- `npm run typecheck`, `npm run build:single`, and `npm run verify:single` pass. `audio:chapter3:verify` reports only the pre-existing missing Qizhen fishing cue. The rebuilt `demo/index.html` is `176543367 bytes`, SHA-256 `262f8d69d455d15e7cac04786f8319d80f1fb1f99f96011f8e9c07d1c0fcf78c`.

---

# 启真湖 98 划船记录实施计划

> **执行要求**　使用 `executing-plans` 按顺序实施。每项完成后运行对应验证。不得手改 `demo/index.html`。进入 Git 提交阶段前，先 fetch 并分别展示工作区改动、本地独有提交、远端独有提交，由用户确认精确范围。

**目标**　把启真湖划船记录做成一条持续增长的 CC98 帖子。湖心主帖开放自由探索和钓鱼；小码头、湖心倒影、黑天鹅区作为可选补拍；追逐结束后由玩家主动总结并归档。

**架构**　TypeScript controller 保存帖子、照片、奖励和归档事实；Phaser 采集实时构图数据并负责湖面表现；React 负责相机、草稿、CC98 帖子和移动端覆盖层；存档保存有限的构图参数，照片显示时由本地素材重建。

**技术栈**　React、TypeScript、Phaser、现有 CC98 页面、`SaveStore`、`AudioDirector`、Vite 单文件构建。

## 一、玩家流程

1. 完成上船教学，划到湖心取景区。
2. 调整到低速、低侧倾状态，打开相机并拍摄湖心主图。
3. 进入 CC98 草稿页，选择标题和状态，发布唯一主帖。
4. 主帖发布后开放自由探索和钓鱼，并写入首个持久化节点。
5. 玩家可按任意顺序补拍小码头、湖心倒影、黑天鹅区；每张照片追加为同一帖内的楼主回复。
6. 两处补拍解锁一次节奏钓鱼辅助；三处补拍解锁“启真湖划船记录卡”。
7. 纸条捕获后进入黑天鹅追逐，追逐期间锁定手机和相机。
8. 追逐返回码头后开放总结。玩家可先补拍缺失地点，也可直接发布总结。
9. 总结发布后帖子归档，章节进入下一段过场。

固定规则如下。

- 主帖只成功发布一次；每个地点只追加一条楼主回复。
- 补拍顺序自由，动态回复只消费既有事实，不参与主线判定。
- 两处和三处补拍奖励各发一次。
- 钓鱼辅助在一次有效节奏钓鱼结算后消耗；取消、切页和场景关闭不消耗。
- 追逐期间拒绝手机、相机和帖子入口请求，并显示原因。
- 总结只发布一次；归档后帖子保持只读。
- 网络重试和重复点击使用幂等键，不能生成重复楼层。
- 同一会话返回湖面时恢复原位置与朝向；完整重载使用当前区域安全出生点。
- 可选补拍不阻断总结和章节结束。

## 二、状态与存档合同

帖子状态和湖区剧情阶段分开保存。现有 `QizhenLakePhase` 继续负责上船、工具链、捕获和追逐；论坛记录使用一个嵌套状态。新增 `post_chase` 阶段。追逐成功后先回码头整理记录，总结归档后再进入 `complete`。

建议类型如下。

```ts
type QizhenJournalStatus =
  | "locked"
  | "capture_ready"
  | "main_draft"
  | "open"
  | "summary_ready"
  | "archived";

type QizhenPhotoSpotId = "lake_center" | "dock" | "reflection" | "swan_cove";

interface QizhenPhotoRecipe {
  zone: QizhenLakeZone;
  cropCenterX: number;
  cropCenterY: number;
  zoomStep: 0 | 1 | 2;
  kayakX: number;
  kayakY: number;
  headingBucket: 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7;
  swanDistanceBucket?: "near" | "mid" | "far" | "gone";
  rippleClarityBucket?: "clear" | "partial" | "lost";
}

interface QizhenPhotoRecord {
  id: string;
  spotId: QizhenPhotoSpotId;
  capturedAtSeconds: number;
  tags: QizhenPhotoTag[];
  recipe: QizhenPhotoRecipe;
}

interface QizhenJournalState {
  status: QizhenJournalStatus;
  threadId: string;
  threadSeed: number;
  mainPhoto: QizhenPhotoRecord | null;
  optionalPhotos: Partial<Record<"dock" | "reflection" | "swan_cove", QizhenPhotoRecord>>;
  mainTitleId: string | null;
  mainStatusId: string | null;
  publishedSpotIds: QizhenPhotoSpotId[];
  pendingDraft: QizhenJournalDraft | null;
  summaryChoice: "safe_return" | "details_withheld" | null;
  summaryPublished: boolean;
  fishingAssistUnlocked: boolean;
  fishingAssistConsumed: boolean;
  memoryCardUnlocked: boolean;
}
```

照片不以 Base64、canvas 数据、HTML 或完整截图写入存档。`QizhenPhotoRecipe` 记录区域、裁切中心、船位、朝向档位、缩放档位和关键主体距离。帖子显示时，由本地湖区底图、船和动态主体按配方重建。这样可以控制单文件体积和 `localStorage` 占用，素材改进后也能重新渲染旧照片。

存档版本计划从 `21` 升到 `22`。旧存档补齐 journal 默认值；已经完成启真湖的旧档直接迁移为兼容归档，不能回退到拍照任务。

## 三、关键交互决定

### 1. 主帖开放钓鱼

完成上船后，任务先指向湖心拍照和发帖。`findFishingRod`、`precheckCast` 和相关工具链入口在主帖未发布时返回提示“先把湖心记录发出去，再继续找纸条。” 主帖成功后才显示自由探索目标。

### 2. 桌面与手机共用相机

- 桌面分屏下，Phaser 湖面保留在游戏侧，相机和 CC98 放在手机侧。
- 窄屏触控下，同一 React 相机组件覆盖在 `rpg-shell` 上，Phaser 暂停输入但保留实例。
- 相机关闭后恢复 canvas 焦点和划桨输入。
- 捕获期间缓慢把瞬时速度归零，防止返回游戏时船体突跳。

### 3. 动态回复可复现

回复选择器只读取 `threadSeed`、照片标签、碰撞次数、侧翻次数、黑天鹅警戒等级和发布顺序。存档保存事实和 seed，不保存选中的回复文本。相同存档刷新后得到相同帖子，不同存档可出现受控变化。

### 4. 网络与草稿

草稿编辑可以离线进行；发布时检查 `networkMode === "campus_wifi"`。失败后保留照片和全部选项，提供“打开控制中心”“返回湖面”“继续编辑”。网络恢复后由玩家手动重试，系统不自动发布。

### 5. 追逐后的整理阶段

现有 `completeEscape()` 会立即结束启真湖，与帖子总结冲突。修改步骤如下。

1. 追逐成功写入 `phase: "post_chase"`、码头安全出生点和 `journal.status: "summary_ready"`。
2. 玩家可以补拍仍缺失的地点或直接总结。
3. 黑天鹅已经离开时，黑天鹅区提供“空围栏与水痕”构图，标签为 `swan_aftermath`，仍计入三处补拍。
4. 总结发布后写入 `phase: "complete"`，再发送正式章节转场事件。

## 四、开发任务

### Task 0｜建立当前基线

**读取**　`src/core/types.ts`、`src/core/GameState.ts`、`src/core/SaveStore.ts`、`src/modules/ChapterThreeQizhenLakeController.ts`、`src/scenes/rpg/QizhenLakeScene.ts`、`src/scenes/phone/P02_CC98/index.tsx`、`src/scenes/phone/P02_CC98/ThreadPage.tsx`。

1. 记录当前分支、远端、工作区和未跟踪文件，不改变 Git 状态。
2. 运行 `npm run typecheck`，区分既有问题和新增回归。
3. 用现有 DEV 节点进入上船后、节奏钓鱼、黑天鹅追逐，记录状态快照。
4. 记录当前存档版本和单文件哈希；视觉检查后删除临时截图。

**验收**　三个起点都能稳定复现，后续回归有明确基线。

### Task 1｜状态、内容与确定性回复

**修改**　`src/core/types.ts`、`src/core/GameState.ts`、`src/data/chapter3-qizhen-lake.content.json`、`package.json`。

**新增**　`src/modules/QizhenJournalModel.ts`、`scripts/verify-qizhen-journal.mjs`。

1. 在 `QizhenLakeState` 内加入 `journal`、`dockCollisionCount`、`swanAlertLevel`；速度、侧倾和相机开关留在 runtime。
2. 内容 JSON 增加 `journal` 节，统一保存标题、状态、补拍说明、总结、网络错误、回复池和 recurring NPC。
3. Model 实现照片标签、补拍计数、奖励投影、幂等键、回复选择和归档判定。
4. 新增 `npm run qizhen:validate-journal`，检查内容 ID、四个拍摄点、奖励阈值、seed 稳定性和归档不变量。

**验收**　连续两次生成结果一致；不同 seed 产生受控变化；用户可见文案不散落在 scene 和 component 中。

### Task 2｜controller 事务与 v22 迁移

**修改**　`src/core/SaveStore.ts`、`src/modules/ChapterThreeQizhenLakeController.ts`、`src/core/GameState.ts`。

1. 增加 `precheckPhotoCapture`、`precheckJournalPublish`、`precheckJournalReply`、`precheckJournalSummary`。
2. 增加 `capturePhoto`、`saveJournalDraft`、`publishMainPost`、`publishPhotoReply`、`publishSummary`。
3. 发布操作使用 `threadId + draftId` 幂等键；重复请求返回既有结果。
4. `publishMainPost` 开放钓鱼；`publishPhotoReply` 每地点只追加一次；`publishSummary` 归档并推进章节。
5. 完成 v21 未开始、工具链中、追逐中、已完成四类迁移样本。

**验收**　重复发布不增加楼层；网络失败不修改已发布事实；旧完成档不回退。

### Task 3｜拍摄点与 Phaser 桥接

**修改**　`src/scenes/rpg/QizhenLakeModel.ts`、`src/scenes/rpg/QizhenLakeScene.ts`、`src/scenes/rpg/RpgRuntimeDebug.ts`、`src/scenes/rpg/RpgGameHost.tsx`。

1. 在四张湖区地图上定义源像素拍摄区域、建议站位和主体可见范围。
2. 湖心读取速度与侧倾；码头读取取景完整度；倒影读取水纹清晰度；黑天鹅读取真实距离。
3. Scene 发出 `qizhen_photo_session_requested`，只携带拍摄点、实时数据和构图配方。
4. Host 打开 React 相机时暂停划桨、碰撞推进和普通交互；关闭后恢复输入。
5. Debug 暴露拍摄点、速度、侧倾、标签、主体距离和相机状态。

**验收**　四处真实可达；相机画面对应当前地点；相机打开期间船不漂移；关闭后没有按键粘连。

### Task 4｜共享相机与草稿 UI

**新增**　`src/components/QizhenJournalCamera.tsx`、`src/styles/qizhen-journal-camera.css`。

**修改**　`src/scenes/rpg/RpgGameHost.tsx`、`src/App.tsx`、`src/components/PixelIcon.tsx`。

1. 提供取景框、水平参考、速度、侧倾、拍摄点名称和快门。
2. 构图欠佳时允许拍摄，并赋予“偏斜”“水纹断开”等真实标签。
3. 主帖草稿提供三个标题和三个状态；补拍草稿只选择该地点说明。
4. 支持 Pointer Events、Enter/Space、Esc/返回和 `prefers-reduced-motion`。
5. 桌面、非 16:9 和 `390×844` 使用同一组件和状态合同。

**验收**　页面无溢出；返回湖面恢复正常操作；桌面和触控端没有重复逻辑。

### Task 5｜CC98 单帖持续更新

**新增**　`src/scenes/phone/P02_CC98/QizhenJournalThread.tsx`、`src/scenes/phone/P02_CC98/cc98Types.ts`。

**修改**　`src/scenes/phone/P02_CC98/index.tsx`、`src/scenes/phone/P02_CC98/ThreadPage.tsx`、CC98 实际样式文件、`src/modules/NavIntent.ts`。

1. 抽出通用帖子与回复类型，journal 不侵入通用 ThreadPage 的数据来源。
2. 从 journal state 投影唯一主帖、楼主回复、路人回复和归档状态。
3. 提供“只看楼主”“继续补充”“返回湖面”；归档后隐藏补充入口。
4. 缩略图和详情图由同一 photo recipe 重建。
5. 任务帖继续排除在玩家可编辑帖子本地存储之外。

**验收**　所有照片都位于同一 thread；刷新和筛选不改变楼层；归档后只读。

### Task 6｜奖励与节奏钓鱼

**修改**　`src/scenes/rpg/QizhenFishingRhythmModel.ts`、`src/scenes/rpg/QizhenFishingRhythmVisual.ts`、`src/modules/ChapterThreeQizhenLakeController.ts`、`src/core/QuestModel.ts`、inventory item 配置和 `src/components/PixelIcon.tsx`。

1. 两处补拍解锁一次 journal assist。
2. 复用现有 assist timing；journal assist 与失败触发 assist 取并集，不能叠加扩大窗口。
3. 取消、切页和 shutdown 不消耗；一次有效结算后写入 consumed。
4. 三处补拍且帖子归档后授予 `qizhenRowingMemoryCard`。
5. 任务栏只显示当前目标；奖励达成时给一次短通知。

**验收**　assist 只结算一次；取消不会丢失；记录卡只获得一次。

### Task 7｜追逐锁定、总结与音效事件

**修改**　`src/modules/ChapterThreeQizhenLakeController.ts`、`src/scenes/rpg/QizhenLakeScene.ts`、`src/core/QuestModel.ts`、`src/modules/NavIntent.ts`、`src/modules/AudioDirector.ts`。

1. `swan_chase` 中拒绝 phone、camera 和 journal intents。
2. 追逐失败使用现有 checkpoint，并保留帖子、草稿和奖励。
3. 追逐成功进入 `post_chase`；总结归档后才进入 `complete`。
4. 快门、发布、通知和归档只发 domain audio events；音频缺失不阻断状态推进。

**验收**　追逐中手机打不开；失败后保留记录；成功后可补拍或总结；总结只发布一次。

### Task 8｜任务、DEV 和活人感文案审校

**修改**　`src/core/QuestModel.ts`、`src/modules/DeveloperChannel.ts`、`src/components/DeveloperChannel.tsx`、`src/data/chapter3-qizhen-lake.content.json`、`project-development-report.md`。

新增以下 DEV 节点。

- `c3-qizhen-journal-main-capture`
- `c3-qizhen-journal-main-draft`
- `c3-qizhen-journal-open`
- `c3-qizhen-journal-two-photos`
- `c3-qizhen-journal-three-photos`
- `c3-qizhen-journal-network-retry`
- `c3-qizhen-journal-summary`

每个节点种完整 scene、zone、vehicle、inventory、journal 和安全位置，保持 session-only。任务顺序固定为上船、湖心主图、发布主帖、当前工具链；补拍只显示为当前可选目标。

所有帖子、回复、提示和系统反馈使用 `human-writing` 审校，删除说明腔、重复结论和玩家无法判断来源的系统分析。学生、系统和玩家楼主保持不同语气。运行 `human-writing/scripts/check_prose.py` 后，再人工检查 `430×860` 的换行和按钮长度。

**验收**　各 DEV 节点可继续下一步；任务栏不泄露未来链条；论坛对话符合校园语境；失败提示指出下一步。

### Task 9｜端到端验收与单文件

**修改**　`docs/client-compatibility.md`（支持合同变化时）、`progress.md`。

**生成**　`demo/index.html`。

```bash
npm run qizhen:validate-journal
npm run typecheck
npm run build:single
npm run verify:single
git diff --check
```

浏览器矩阵如下。

1. Blink `1280×720` 检查主图、主帖、两处补拍、assist、追逐失败与成功、总结。
2. Blink 非 16:9 检查相机、帖子和 RPG 比例，文档不能溢出。
3. Blink `390×844` 检查触控划桨、相机覆盖层、草稿、网络重试和返回湖面。
4. Gecko `1280×720` 检查键盘、Pointer Events、帖子媒体和存档恢复。
5. WebKit 桌面和 iOS Safari 视口检查触控、safe area、音频解锁和页面隐藏时取消节奏钓鱼。
6. HTTP 与直接打开单文件都要使用同一 DEV 节点和状态推进，并保持零页面错误。
7. v21 四类迁移样本和发布连点、断网重试、刷新重试的幂等检查。

通过条件包括零 console/page error、刷新后状态一致、单文件与开发构建使用同一运行时、存档无 Base64 图片、无外部图片依赖、临时截图检查后删除，并在 `progress.md` 记录结果。

## 五、排期与首轮边界

| 阶段 | 内容 | 预估 | 验收产物 |
|---|---|---:|---|
| A | 状态、内容、迁移、controller | 1.5 天 | 可迁移存档与可验证事务 |
| B | 四个拍摄点、相机桥、构图重建 | 2 天 | 主图和三处补拍可保存 |
| C | CC98 单帖、草稿、网络重试 | 1.5 天 | 帖子完整流程 |
| D | 奖励、assist、追逐后整理 | 1 天 | 奖励与收尾流程 |
| E | DEV、文案、跨浏览器与单文件 | 1.5 天 | 可评审离线 demo |

总计约 `7.5` 个开发日。该估算基于复用现有 CC98、启真湖、节奏钓鱼和追逐模块；验证次数为 `0`，当前属于实施假说，完成 Task 0 后再校准。

首轮完整交付主帖、三处补拍、动态回复、一次钓鱼辅助、追逐锁定、总结归档、存档迁移和移动端交互。首轮不生成新湖区大图，不加入外部图片服务，不上传真实照片，不启动新的音乐生成任务。现有素材和音频事件足以验证完整玩法，美术与专属音频在流程通过后单独迭代。

实施和验收完成后，只执行 read-only fetch，并展示工作区改动、本地独有提交、远端独有提交。用户确认范围后，才允许 stage、commit、merge 或 push。

---

# 全游戏相机与相册扩展实施计划

> **与上一份计划的关系**　这一节补充并修订“启真湖 98 划船记录实施计划”。原 Task 4 中专用的 `QizhenJournalCamera.tsx` 取消，改用共享相机外壳和启真湖拍摄适配器。启真湖帖子、奖励、追逐锁定和总结规则保持不变。

**目标**　把现有图书馆取证、启真湖打卡和第四章导视牌照片放进同一个“照片”应用。玩家在场景里完成拍摄，在相册里查看和处理，再把照片交给当前剧情允许的去处。照片应用继续占用手机主页原来的位置，不增设第二个相机入口。

**首轮范围**

| 章节 | 拍摄内容 | 相册内处理 | 后续用途 |
|---|---|---|---|
| 第二章图书馆 | 022 座位书包 | 查看、调暗、生成物品识别报告 | 带回前台核验，继续 CC98 证据流程 |
| 第三章启真湖 | 湖心主图、小码头、倒影、黑天鹅区 | 查看构图标签、重拍未发布照片、选择发布内容 | CC98 主帖、楼主补充、划船记录卡 |
| 第四章教学楼 | 一楼电梯面板、二楼通道状态、三楼新旧导视牌、最终签到回执 | 与公众号通知、群聊截图和历史状态分组查看 | 电梯校准、通道核验、微信对照、章节收尾 |
| 剧场 | 只预留媒体接入口 | 暂无新增操作 | 后续确有剧情用途时再启用 |

剧场抢票收据目前仍在 CC98 和取票机流程中使用。首轮不自动把它写进相册，也不增加拍照前置条件。后续若剧情需要保存收据，可使用同一媒体合同增加 `screenshot` 类型。

## 一、统一玩家流程

```mermaid
flowchart LR
  A["RPG 场景出现可拍目标"] --> B["controller 检查章节、距离、模式和目标"]
  B -->|允许| C["共享相机进入取景状态"]
  B -->|拒绝| D["显示下一步操作"]
  C --> E["拍摄并预览"]
  E -->|重拍| C
  E -->|使用照片| F["controller 写入章节事实和媒体记录"]
  F --> G["照片应用显示新记录"]
  G --> H{"当前记录允许的操作"}
  H --> I["图书馆识别报告"]
  H --> J["启真湖发布到 CC98"]
  H --> K["教学楼发送到微信"]
```

共享流程固定为以下六步。

1. 场景只在当前剧情允许时显示拍摄入口，并给出一个明确目标。
2. controller 先检查章节、位置、距离、现实模式和重复状态。
3. 相机取得场景提供的构图数据，暂停角色移动和普通交互。
4. 玩家按下快门后先查看照片，可以重拍，也可以使用当前照片。
5. 选择使用后，controller 同时写入章节事实和稳定媒体记录。
6. 相册根据媒体来源只显示当前有效操作，处理完成后返回原场景或原手机页面。

相机关闭、页面隐藏、RPG scene shutdown 和浏览器返回都要取消未保存的拍摄会话。它们不能推进剧情，也不能留下半张照片。一次保存成功后，同一个 `sessionId` 的重复请求返回既有记录。

## 二、相机界面

### 1. 430×860 手机布局

```text
┌──────────────────────────────┐
│ 共享状态栏 40                │
├──────────────────────────────┤
│ ‹ 返回   当前拍摄目标   模式 │ 56
├──────────────────────────────┤
│                              │
│       4:3 取景画面           │ 292
│    目标框、水平线、焦点       │
│                              │
├──────────────────────────────┤
│ 当前状态或一条修正提示        │ 52
├──────────────────────────────┤
│ 0.8×       1.0×       1.4×  │ 44
├──────────────────────────────┤
│ 最近照片     快门      场景项 │ 132
├──────────────────────────────┤
│ 安全区和返回手势空间          │
└──────────────────────────────┘
```

- 顶栏只显示返回、当前拍摄目标和现实模式。浅色现场与深色残影使用文字加色块，不能只靠颜色区分。
- 取景画面使用 `4:3`，保持像素画的整数缩放和 `image-rendering: pixelated`。目标框只在可拍主体附近显示，不能覆盖整个画面。
- 缩放使用 `0.8×`、`1.0×`、`1.4×` 三档。双指缩放可以作为增强操作，三个按钮保留为所有浏览器的可靠入口。
- 快门触控范围为 `72×72px`。键盘端在相机已经打开且快门可用时接受 Enter 和 Space；界面只在这时提示对应按键。
- 左下缩略图打开刚拍照片，右下按钮由场景决定。启真湖显示水平辅助开关，图书馆显示系统亮度读数，教学楼显示当前现实模式。
- 快门动画由白色遮罩、一次短缩放和音效事件组成。启用 `prefers-reduced-motion` 后只保留 80ms 明暗反馈。

### 2. 构图反馈

构图反馈分为三种状态。

| 状态 | 画面 | 快门 | 提示原则 |
|---|---|---|---|
| 未满足剧情条件 | 灰色目标框 | 不可用 | 说明需要靠近、切换模式或先完成哪一步 |
| 可拍但构图一般 | 黄色目标框 | 可用 | 只指出当前问题，允许玩家保留真实记录 |
| 已满足建议构图 | 青色目标框 | 可用 | 显示“可以拍了”或地点名称 |

图书馆和教学楼属于证据照片，主体没有进入有效区域时不能保存。启真湖属于游玩记录，只要玩家到达拍摄区就能保存；速度、侧倾、主体位置和水纹清晰度会变成照片标签和论坛回复条件。

建议文案如下。

- 图书馆未对准　“把 022 书包放进框里。”
- 图书馆可拍　“座位号和书包都拍到了。”
- 启真湖轻微倾斜　“船还在晃，这张也能留。”
- 启真湖主图可拍　“湖心在画面里。”
- 教学楼浅色　“拍下现在的导视牌。”
- 教学楼深色　“把残影上的旧编号拍清楚。”

### 3. 拍后预览

拍后页保留整张照片、地点、时间和最多三个标签。底部只提供“重拍”和“使用照片”。玩家确认后再写入存档。启真湖照片发布以前允许覆盖同一地点的未发布版本；发布后的照片保持不变，避免帖子刷新后换图。图书馆和教学楼的证据照片每个目标只保留一条正式记录。

## 三、相册界面

### 1. 相册首页

手机应用名称继续使用“照片”。首页标题为“校园相册”，包含四个筛选项。

- 全部
- 图书馆
- 启真湖
- 教学楼

筛选项下方按章节进度和拍摄时间分组。相册使用两列卡片，每张卡片由 `4:3` 缩略图、短标题、地点和一个状态组成。建议状态只有“待处理”“可发布”“已发送”“已归档”四种；同一张卡片最多显示一个。

```text
┌──────────────────────────────┐
│ ‹ 主页       校园相册        │
├──────────────────────────────┤
│ 全部  图书馆  启真湖  教学楼 │
├──────────────────────────────┤
│ 第三章 · 启真湖              │
│ ┌──────────┐ ┌──────────┐   │
│ │ 4:3 缩略图│ │ 4:3 缩略图│   │
│ │ 湖心主图  │ │ 小码头    │   │
│ │ 可发布    │ │ 已发布    │   │
│ └──────────┘ └──────────┘   │
│ 第二章 · 图书馆              │
│ ┌──────────┐                │
│ │ 022 书包  │                │
│ │ 已处理    │                │
│ └──────────┘                │
└──────────────────────────────┘
```

空相册只显示“还没有照片”。主页图标在第一条正式媒体记录生成前保持原锁定样式和原位置。现有图书馆拍摄入口仍可以临时打开照片应用；第一张照片保存后，照片应用正式解锁。

### 2. 照片详情

详情页上半部显示完整 `4:3` 预览，下半部显示标题、地点、章节时间和标签。底部只显示当前 controller 允许的动作。

| 照片来源 | 主操作 | 次操作 |
|---|---|---|
| 图书馆 022 | 调暗并识别 | 返回图书馆 |
| 启真湖未发布照片 | 用于 98 记录 | 返回湖面 |
| 启真湖已发布照片 | 查看所在楼层 | 返回帖子 |
| 教学楼单张导视牌 | 查看另一张 | 返回三楼 |
| 教学楼成对照片 | 发送到文件传输助手 | 打开微信 |

相册不显示通用系统分享面板。每张照片只列出剧情当前允许的目的地，这样可以避免提前显示微信、CC98 或后续章节功能。返回操作携带 `returnIntent`，保证玩家回到原来的 RPG 场景、帖子楼层或微信会话。

### 3. 照片成对查看

第四章导视牌使用左右对照页。浅色当前导视牌在左，深色残影导视牌在右。玩家可以拖动中间分隔线，也可以点按“当前”“残影”切换。页面只展示现场可见内容，不提前标出答案。发送到微信后，朋友聊天继续承担差异判断和剧情推进。

## 四、共享媒体合同

章节 controller 继续拥有剧情事实。相册保存媒体索引和显示配方，不单独判断任务完成。建议在 `GameState` 增加以下合同。

```ts
type StoryMediaKind = "photo" | "screenshot" | "scan";

type StoryMediaSource =
  | "library_022_bag"
  | "qizhen_lake_center"
  | "qizhen_dock"
  | "qizhen_reflection"
  | "qizhen_swan_cove"
  | "chapter4_elevator_panel"
  | "chapter4_corridor_cycle_1"
  | "chapter4_corridor_cycle_2"
  | "chapter4_wayfinding_current"
  | "chapter4_wayfinding_residual"
  | "chapter4_attendance_receipt"
  | "chapter4_clearance_moment";

type StoryAlbumId = "library" | "qizhen" | "teaching_building";

interface StoryMediaRecord {
  id: string;
  kind: StoryMediaKind;
  chapter: 2 | 3 | 4;
  albumId: StoryAlbumId;
  source: StoryMediaSource;
  titleId: string;
  capturedAtStorySeconds: number;
  recipe: StoryMediaRecipe;
  groupId?: string;
  floorId?: string;
  realityMode?: "light" | "dark";
  chapterCycle?: number;
  tagIds: string[];
  linkedFactIds: string[];
  status: "raw" | "processed" | "shared" | "archived";
  sharedTargetIds: Array<"cc98" | "wechat" | "report">;
  revision: number;
}

interface StoryMediaState {
  records: StoryMediaRecord[];
  latestMediaId: string | null;
}
```

`StoryMediaRecipe` 使用可区分联合类型，分别保存图书馆构图、启真湖底图裁切与动态主体、教学楼当前或残影状态。存档不能写入 Base64、canvas 像素、Blob URL、完整截图或外部图片地址。运行时由本地素材重建缩略图和详情图。

稳定媒体 ID 如下。

- `photo_library_022_bag`
- `photo_qizhen_lake_center`
- `photo_qizhen_dock`
- `photo_qizhen_reflection`
- `photo_qizhen_swan_cove`
- `photo_c4_elevator_panel`
- `photo_c4_corridor_cycle_1`
- `photo_c4_corridor_cycle_2`
- `photo_c4_wayfinding_current`
- `photo_c4_wayfinding_residual`
- `scan_c4_attendance_0755`

未发布的启真湖照片重拍时增加 `revision` 并更新配方。进入 CC98 帖子后锁定当前 revision。其余证据照片的重复拍摄返回已有记录。

## 五、组件和文件安排

### 1. 新增共享模块

- `src/modules/StoryMediaModel.ts`　负责相册分组、排序、稳定 ID、可用操作和最新照片投影。
- `src/modules/StoryMediaRenderer.ts`　根据配方和本地素材绘制缩略图与详情图。
- `src/components/camera/StoryCameraShell.tsx`　负责相机状态、输入、取景框、快门和拍后预览。
- `src/components/camera/CameraViewfinder.tsx`　负责共享取景区域和目标反馈。
- `src/components/camera/CaptureReview.tsx`　负责重拍和使用照片。
- `src/styles/story-camera.css`　负责手机、桌面分屏和移动端覆盖层。

### 2. 重构照片应用

- `src/scenes/phone/P18_Photos/AlbumHome.tsx`　相册首页。
- `src/scenes/phone/P18_Photos/MediaDetail.tsx`　照片详情与当前剧情动作。
- `src/scenes/phone/P18_Photos/LibraryPhotoEditor.tsx`　承接现有亮度和识别报告流程。
- `src/scenes/phone/P18_Photos/index.tsx`　改为相册路由入口。
- `src/styles/scenes/p18-photos.css`　改为统一相册样式。

现有 `PhotoEvidenceOverlay.tsx` 中的 022 拍摄画面、快门动画、系统亮度和报告生成拆进上述三个组件。当前 `LibraryFinalsController` 的 `photoCaptured`、`photoDimmed` 和 `itemReportGenerated` 保留，迁移后仍由它们决定图书馆进度。

### 3. 场景适配器

- `src/scenes/rpg/LibraryPhotoCapture.ts`　读取 022 目标框和当前亮度状态。
- `src/scenes/rpg/QizhenPhotoCapture.ts`　读取区域、船位、速度、侧倾、倒影清晰度和黑天鹅距离。
- `src/scenes/rpg/ChapterFourPhotoCapture.ts`　读取导视牌目标、浅深模式和当前站位。

三个适配器都实现 `StoryCameraCaptureContract`。共享组件只消费拍摄目标、预览配方、可用状态和确认回调，不能直接写 `GameStore`。

```ts
interface StoryCameraCaptureContract {
  sessionId: string;
  source: StoryMediaSource;
  objectiveTextId: string;
  modeLabelId: string;
  zoomSteps: readonly number[];
  evaluate(frame: StoryCameraFrame): StoryCameraEvaluation;
  buildRecipe(frame: StoryCameraFrame): StoryMediaRecipe;
  confirm(recipe: StoryMediaRecipe): Promise<StoryMediaRecord>;
  cancel(): void;
}
```

## 六、各章节串联方式

### 1. 图书馆

1. 玩家检查 022 书包后，照片应用以拍摄会话打开。
2. 书包和座位号进入目标框后可以拍摄。
3. 选择使用照片，controller 写入 `photoCaptured` 和 `photo_library_022_bag`。
4. 相册自动打开该照片详情，继续读取系统亮度。
5. 亮度达到现有阈值后生成物品识别报告，controller 写入原有事实和道具。
6. 详情页主操作改为“返回图书馆”，前台继续验证原报告道具。

现有“37 张外卖截图，以及一张没有开花的盆栽”笑点可以保留为相册首次解锁后的装饰记录，但不能与剧情照片混在同一排序里，也不能占用正式媒体状态。若视觉上继续干扰主任务，首轮直接删掉。

### 2. 启真湖

1. Phaser 在四个拍摄区提交实时构图数据。
2. 共享相机显示湖区画面，保存后进入启真湖相册分组。
3. 湖心主图详情提供“用于 98 记录”；其余三张提供“补充到原帖”。
4. CC98 媒体选择器只显示当前帖子允许且尚未发布的启真湖照片。
5. 从帖子点照片可回到相册详情，从相册点已发布照片可回到对应楼层。
6. 追逐期间相机、相册编辑和发布操作全部锁定；只读相册可以在追逐结束后恢复。

### 3. 第四章教学楼

第四章使用四组现场资料区分楼层和时间状态。手机里的照片、截图和音频记录可以跨过 23:30 的场景复位；它们只保存已经观察到的信息，时间锚和大型签到板运输仍按原控制器规则推进。

#### 一楼运行记录

1. 玩家先在“校园后勤服务”公众号读完夜间运行通知，并保存一条 `screenshot` 记录。
2. 到主电梯前，浅色模式拍下当前楼层显示、门状态和现场时间。
3. 深色观察继续记录现有的七秒历史提示音。
4. 文件传输助手把通知截图、电梯面板照片和历史音频放在同一个“主电梯运行记录”分组。
5. 玩家根据三份材料选择重演起点。`ChapterFourTemporalMazeController` 继续检查时间和上梯窗口。

这一组让一楼承担正式通知与现场状态核验。照片缺少楼层数字或电梯门时，快门保持不可用；通知和音频缺失时，面板照片可以查看，但不能开始校准。

#### 二楼通道记录

1. 玩家在“麦斯威夜间自习群”保存东西两侧路线讨论截图。
2. 回到二楼，在当前可通行的一侧拍下走廊口、封闭标识和现场角色位置。构图不要求拍清人物面部。
3. 第一次 23:30 复位后，旧照片保留。若东西通道状态发生改变，同一机位开放第二张照片。
4. 相册用相同裁切范围并排显示两轮照片，时间和角色位置分别写在卡片下方。
5. 玩家回微信查看群聊截图，再选择当前轮次可行的通道。controller 根据 cycle、群聊事实和现场照片判断结果。

二楼照片来源使用 `photo_c4_corridor_cycle_1` 和 `photo_c4_corridor_cycle_2`。当前实现若尚未开放第二轮，首轮只要求 cycle 1；cycle 2 入口随正式时间复位机制一起启用。

#### 三楼导视记录

1. 浅色模式在三楼导视牌前拍下当前编号。
2. 深色模式在同一位置拍下残影编号。
3. 第二张保存后，相册生成成对查看入口。
4. “发送到文件传输助手”由 `ChapterFourTemporalMazeController` 检查两条媒体 ID 和原有观察事实。
5. 微信文件助手直接读取两张媒体预览，替换当前 CSS 占位图。
6. 朋友对照完成后仍由现有微信 controller 写入差异事实，相册把两条记录标为 `archived`。

#### 07:55 签到回执

最终签到成功后，终端自动生成 `scan_c4_attendance_0755`。它显示课程时间、B2-04、校园卡尾号遮罩和“签到成功”，不需要玩家再举起相机。相册把它放进“教学楼”分组的末尾。玩家从这里可以查看本章已经保存的运行通知、通道照片和导视对照，随后进入章节结束页。

#### 可选清楼片段

三段人物事件可以保存为可选照片，不参与主线判定。

- 保洁员推车进入主电梯。
- 保安提醒最后一名自习学生离开。
- 203 教室的电脑仍亮着，学生回群里确认情况。

这些入口只在事件已经发生且玩家位于可见范围时出现。照片用于补充群聊回复和“夜间清楼记录”相册分组，不提供道具或路线答案。建议回复保持短句。

- 林昊　“203 还亮着，那台大概真是我的。”
- 室友　“保洁车在西侧。你拍的时候，那边还通。”
- 陈嘉　“我撤回的是认错楼层。照片先别删。”

旧存档若已经拥有 `wayfindingPhotosArchived`，迁移时补建两条兼容媒体记录，并保持后续进度。旧存档若只有 `a3_old_signage_observed`，只补拍摄入口，不能自动生成已拍照片。已经完成第四章的旧档补建最终签到回执；可选清楼照片不补发。

## 七、导航、解锁和通知

1. `NavIntent` 增加 `requestPhotoAlbum`、`requestPhotoMedia` 和 `requestStoryCamera`，都携带 `returnIntent`。
2. 照片应用在第一条正式媒体记录保存后解锁。图书馆任务可以在解锁前直接打开一次受限拍摄页。
3. 手机主页的照片通知读取 `latestMediaId`，显示真实标题。当前固定的“看不清的书脊”通知删除。
4. 相册详情根据 controller projection 生成操作，不读取章节字段自行猜测。
5. CC98 只接收启真湖媒体，微信文件助手只接收教学楼导视牌，识别报告只接收图书馆 022 照片。
6. DEV 节点可以直接打开指定照片，但 session-only 种子不能写入正式存档。

## 八、绘制与性能规则

- 缩略图和详情图共用 `StoryMediaRenderer`。同一配方只能有一套绘制实现。
- 相册网格按进入视口再绘制。首屏最多预热六张缩略图，内存缓存最多保留二十四张，退出照片应用时释放详情大图。
- 缩略图使用固定 `240×180` 内部画布，详情图使用 `720×540`。两者从同一配方绘制，避免比例和主体位置变化。
- Canvas 2D 是相册绘制基线。不能为了照片详情再创建 Phaser 或 Three.js 实例。
- `createImageBitmap` 只作为能力检测后的加速项；Safari 15 走普通 `HTMLImageElement` 和 Canvas 2D。
- 所有素材来自单文件内已有资源或新纳入构建的本地资源。图片加载失败时显示地点、时间和“预览暂不可用”，不能阻断剧情动作。
- 相机打开时暂停 Phaser 输入；保存或退出后只恢复本次暂停的场景。触控指针、键盘按键和现实模式状态都要清零，避免返回后继续移动。

## 九、实施任务

### Task A｜建立基线和媒体清单

**读取**　`P18_Photos`、`PhotoEvidenceOverlay`、`LibraryFinalsController`、`ChapterFourWechatModel`、`ChapterFourTemporalMazeController`、启真湖 controller、`FeatureAccess`、`NavIntent` 和当前存档版本。

记录三段现有流程、工作区状态、当前单文件哈希和 DEV 起点。确认旧存档样本中图书馆照片事实与第四章微信照片事实的组合。

**验收**　三段流程都能从稳定起点复现；现有行为和计划改动可以逐项对应。

### Task B｜共享状态、配方渲染和迁移

**修改**　`src/core/types.ts`、`src/core/GameState.ts`、`src/core/SaveStore.ts`。

**新增**　`src/modules/StoryMediaModel.ts`、`src/modules/StoryMediaRenderer.ts`、`scripts/verify-story-media.mjs`。

把共享媒体状态纳入上一份启真湖计划的 v22 迁移，不再次提升版本号。迁移覆盖无照片、图书馆照片已拍、图书馆报告已生成、第四章照片已归档和启真湖旧完成档。

**验收**　稳定 ID 不重复；刷新结果一致；存档没有原始像素和外部地址；旧进度不倒退。

### Task C｜照片应用和图书馆行为迁移

**修改**　`P18_Photos/index.tsx`、`PhotoEvidenceOverlay.tsx`、`LibraryFinalsController.ts`、相关样式和 registry 合同。

**新增**　`AlbumHome.tsx`、`MediaDetail.tsx`、`LibraryPhotoEditor.tsx`。

先迁移图书馆，因为它已经具备完整拍摄和处理流程。迁移前后使用同一个 DEV 节点对照 `photoCaptured`、`photoDimmed`、`itemReportGenerated` 和背包道具。

**验收**　原图书馆任务行为一致；相册首页能打开 022 照片；亮度和报告逻辑没有复制。

### Task D｜共享相机和 RPG Host 生命周期

**新增**　三个 camera 组件、共享 CSS 和 capture contract。

**修改**　`RpgGameHost.tsx`、`App.tsx`、`PixelIcon.tsx`、`ClientCompatibility.ts`（仅在能力合同变化时）。

完成 framing、shutter、review、saving、saved 五个阶段。页面隐藏、返回、scene shutdown 和 host unmount 都执行同一个取消方法。

**验收**　桌面分屏、非 16:9 和 `390×844` 共用相同状态；退出后没有按键或触控残留；保存连点只产生一条媒体记录。

### Task E｜启真湖接入

用 `QizhenPhotoCapture.ts` 替换上一份计划中的专用 React 相机。四个拍摄点、构图标签、CC98 发布、重拍锁定、追逐禁用和奖励规则继续按原计划实施。

**验收**　相册中的图片、CC98 缩略图和详情页来自同一配方；两处与三处补拍奖励各结算一次。

### Task F｜教学楼接入微信

**修改**　第四章 Scene、controller、微信 model、`P14_Wechat`、相册投影和内容 JSON。

按一楼运行记录、二楼通道记录、三楼导视记录和最终签到回执四段实施。先完成当前运行时已有的 A1、A2、A3；B2 回执随最终签到终端接入。可选清楼片段复用 NPC 实际位置和动画帧，不能单独伪造人物状态。

**验收**　一楼三份材料齐全后才能校准；二楼截图和现场照片对应当前 cycle；三楼缺一张时不能发送；两张齐全后可以发送；对照完成后任务回到三楼；最终签到只生成一次回执；旧已归档存档可以继续。

### Task G｜入口、通知、DEV 和文案

**修改**　`FeatureAccess`、`NavIntent`、手机主页、`DeveloperChannel`、`QuestModel` 和章节内容 JSON。

新增以下定向节点。

- `c2-photo-capture`
- `c2-photo-album-detail`
- `c3-qizhen-journal-main-capture`
- `c3-qizhen-journal-album`
- `c4-elevator-media-set`
- `c4-corridor-photo-cycle-1`
- `c4-corridor-photo-cycle-2`
- `c4-wayfinding-photo-current`
- `c4-wayfinding-photo-pair`
- `c4-wayfinding-photo-wechat`
- `c4-attendance-receipt`

界面文案和章节对话使用 `human-writing` 审校。相机提示只写当前动作；相册卡片不解释整段任务；微信和 CC98 保持各自说话方式。

**验收**　每个 DEV 节点可以完成下一步；主页通知对应真实最新照片；任务栏不显示未来照片名。

### Task H｜浏览器、存档和单文件验收

```bash
npm run story-media:verify
npm run qizhen:validate-journal
npm run typecheck
npm run build:single
npm run verify:single
git diff --check
```

浏览器验证覆盖 Blink、Gecko、WebKit，视口覆盖 `1280×720`、一个非 16:9 桌面视口和 `390×844`。逐段完成图书馆拍摄与报告、启真湖主图与补拍、第四章一楼运行记录、二楼通道记录、三楼导视对照和最终签到回执。还要检查返回路径、页面隐藏、连续点击、存档刷新、旧档迁移、直接打开单文件和 HTTP 运行。

通过条件包括零页面错误、零 console error、无文档溢出、相机和相册可用键盘与触控操作、媒体记录幂等、无 Base64 图片、单文件不请求外部媒体、临时截图检查后删除。

## 十、排期调整

共享相机与相册会替换启真湖专用相机，因此工作量不能把两份计划直接相加。调整后的整体预估如下。

| 阶段 | 预估 |
|---|---:|
| 共享媒体状态、渲染和 v22 迁移 | 0.75 天 |
| 相册首页、详情和图书馆迁移 | 1.25 天 |
| 共享相机、Host 生命周期和启真湖适配 | 1.5 天 |
| 第四章三组证据、微信接入和最终回执 | 1.75 天 |
| DEV、文案、跨浏览器和单文件验收 | 0.75 天 |

这些工作与上一份启真湖计划重叠约 3.5 个开发日。两份计划合并后的总预估从 `7.5` 个开发日调整为约 `10` 个开发日。验证次数为 `0`，该排期仍是实施假说；完成 Task A 和图书馆迁移后再用实际耗时校准。

首轮优先完成共享媒体合同、相册首页、图书馆迁移、启真湖相机和第四章双照片。相册编辑、筛选和分享都只实现剧情当前需要的操作。自由滤镜、批量删除、云端同步、真实系统相册读写、视频拍摄和通用社交分享不进入首轮。

实施完成后仍按仓库规则执行 read-only fetch，并分别展示工作区改动、本地独有提交和远端独有提交。用户确认精确范围以后，才进行任何 stage、commit、merge 或 push。

---

# Chapter 4 “把时间拨回 7:55” Asset Integration Implementation Plan

> **For Codex:** REQUIRED SKILL — use `executing-plans` to implement this plan task-by-task. Any image correction step must also load and follow the `imagegen` skill before changing raster assets.

**Goal:** Replace the active Chapter 4 story path with the approved `22:45 → 12:25 → 18:50 → 22:45 → 07:54 → 07:55` teaching-building sequence, promote the approved generated art into tracked runtime assets, and deliver the complete A1/A2/A3 exploration, room restoration, maintenance patrol, light-grid puzzle, final pursuit, check-in, and approved exterior closing handoff.

**Architecture:** `GameState`, `ChapterFourTemporalMazeController`, `ChapterFourMazeProjection`, and `SaveStore` remain the only progression authority. Phaser owns the three-floor `1672×941` source-pixel maps, dynamic props, NPCs, collisions, occlusion, patrol, and chase. React owns the shared task/inventory overlays and the accessible five-zone power-panel surface. Opaque time-state plates replace the current floor texture atomically. The existing Three.js stair implementation remains isolated and is unreachable from this story path.

**Tech Stack:** React, TypeScript, Phaser 3, JSON runtime contracts, existing `RpgInteractionContract`, existing NPC atlases, pure Node validators, Vite, the generated offline single file, Blink/Gecko/WebKit browser QA.

## 1. Source order and scope lock

Use the following sources in this order when they disagree.

1. Approved story source: `/Users/zhuhangcheng/.codex/attachments/bae6a4ba-a493-402c-ae83-7d77a6e3d016/pasted-text.txt`.
2. Runtime and delivery constraints: `AGENTS.md`.
3. Art intent and naming: `docs/plans/2026-08-20-chapter4-topdown-pixel-map-generation-prompts.md`.
4. Per-image collision and occlusion pre-annotations:
   - `docs/plans/2026-08-20-chapter4-airwall-occlusion-base-prompts.md`
   - `docs/plans/2026-08-20-chapter4-airwall-occlusion-state-prompts.md`
   - `docs/plans/2026-08-20-chapter4-airwall-occlusion-sprite-prompts.md`

This plan supersedes the story and puzzle sequence in the earlier “Chapter 4 Three-Floor Temporal Campus Maze Implementation Plan”. The following technical work remains reusable:

- one stitched A1/A2/A3 Phaser world;
- source-pixel collision and foreground occlusion;
- one shared elevator and adjacent stair core;
- controller-owned movement, checkpoints, domain events, and save recovery;
- `RpgGameHost`, `RpgInteractionContract`, `FinaleNpcTextures`, task UI, inventory feedback, and developer checkpoints.

The following old paths must become unreachable from normal Chapter 4 progression:

- the `22:43:31` elevator-history replay and six-second boarding gate;
- the old NPC schedule, partition, guide-fragment, wayfinding-board, and `23:30` cycle route;
- the B-building branch and old `B2-04 / 08:00` ending;
- the phone clock’s four-stage `08:00` calibration as the Chapter 4 terminal path;
- the Three.js misaligned-stair puzzle as a required main-story step.

Keep the old source files until a separate cleanup is authorized. Disable their route and feature gates first so an old phase cannot reopen them.

## 2. Current baseline and verified gaps

Read-only verification count is `1` on 2026-08-20.

```text
npm run chapter4:validate-topology  PASS, but reports the old 6-floor / 13-puzzle contract
npm run typecheck                   PASS
npm run verify:single               PASS, demo/index.html = 192116388 bytes
```

`npm run build:single` was not run during planning because it rewrites a generated deliverable.

The art candidates cannot be copied directly into the current runtime for four reasons.

1. The project and art specification require one transport core at `elevatorCenterX=836` and stair bounds `{x:932,y:145,width:138,height:107}`. The visible candidate elevator centers are approximately A1 `775`, A2 v02 `794`, and A3 v01 `790`; their stairs are also misaligned.
2. A1 has a continuous visible wall at approximately `x=486..530` between the bakery and lobby. The story requires a walkable, visible bakery entrance.
3. Nine time-state images are opaque complete scenes. Three are `1671×941`; they require a copied final column on the right, with no stretch.
4. All collision and occlusion coordinates are pre-annotations with `approximate=true`. Runtime use requires source-pixel calibration against the corrected active plates.

These are integration gates. Runtime work may begin in parallel on state and controller contracts, but the active floor textures cannot be switched until Tasks 1–3 pass.

## 3. Final asset roles

### 3.1 Active full-scene assets

| Candidate | Runtime role | Tracked destination |
|---|---|---|
| `base/chapter4_a1_base_v01.png` | A1 geometry and collision authority after transport-core and bakery-door correction | `src/assets/rpg/interiors/finale/chapter4-755/base/a1.png` |
| `base/chapter4_a2_base_v02.png` | A2 geometry and collision authority after transport-core correction | `src/assets/rpg/interiors/finale/chapter4-755/base/a2.png` |
| `base/chapter4_a3_base_v01.png` | A3 geometry and collision authority after transport-core correction | `src/assets/rpg/interiors/finale/chapter4-755/base/a3.png` |
| `overlays/chapter4_a1_2245_opening_v01.png` | opening A1 night plate | `.../states/a1_2245_opening.png` |
| `overlays/chapter4_a1_1225_bakery_v01.png` | midday bakery plate; queue rails add the only baked physical delta | `.../states/a1_1225_bakery.png` |
| `overlays/chapter4_a2_1850_evening_v01.png` | A2 room-restoration plate | `.../states/a2_1850_evening.png` |
| `overlays/chapter4_a3_1850_reference_v01.png` | A3 standard-layout observation plate | `.../states/a3_1850_reference.png` |
| `overlays/chapter4_a1_2245_maintenance_v01.png` | maintenance and ordinary-patrol A1 night plate | `.../states/a1_2245_maintenance.png` |
| `overlays/chapter4_a1_0754_blackout_v01.png` | A1 minute-theft and power-panel plate | `.../states/a1_0754_blackout.png` |
| `overlays/chapter4_a2_0754_chase_v01.png` | A2 final-pursuit plate | `.../states/a2_0754_chase.png` |
| `overlays/chapter4_a2_lecture_final_minute_v01.png` | 202 interior and projected-paper recovery plate | `.../states/a2_202_final_minute.png` |
| `overlays/chapter4_a1_0755_morning_v01.png` | A1 final check-in plate | `.../states/a1_0755_morning.png` |

All state plates use `renderMode: "opaque_base_replacement"`. No state plate is loaded as a transparent overlay.

### 3.2 Active dynamic sheets

| Candidate | Runtime role | Collision rule |
|---|---|---|
| `chapter4_a2_room204_furniture_v02.png` | 12 desk/chair seat units, four discussion tables, one podium | authored foot boxes only; y-sort by bottom pivot |
| `chapter4_a2_room204_dark_residual_v02.png` | one grouped dark-mode observation and 12 target decals | `visual_only`, never colliding |
| `chapter4_clock_states_v01.png` | old clock face, missing/restored hand, 07:54 and 07:55, gear states | wall interaction only |
| `chapter4_power_panel_states_v01.png` | closed, powered, partial, restored panel frames | wall interaction only |
| `chapter4_story_items_v01.png` | attendance paper, hour hand, positioning plate, short pry bar, oil, final minute, campus card | inventory or pickup triggers only |

Place these under `src/assets/rpg/interiors/finale/chapter4-755/sprites/`. Use explicit `sourceTrim`, `measuredAlphaBounds`, `pivot`, `footCollision`, and `interactionBounds`; do not use an Alpha-to-collision conversion.

### 3.3 Reference-only candidates

| Candidate | Reason |
|---|---|
| `chapter4_a2_base_v01.png` | width mismatch and disconnected room/lobby geometry |
| `chapter4_a3_base_v02.png` | width mismatch and inaccessible archive/media/honor areas |
| `chapter4_a2_dynamic_structures_v01.png` | partitions, guide fragments, and the labelled 203-door sequence belong to the superseded story path |

Keep these only under the ignored `artifacts/` package. They must not enter the active environment manifest or single-file bundle.

### 3.4 Existing art retained

- `finale_arrival_arcade.png` remains the last replay shot before the live A1 handoff.
- Existing player, student, cleaner, cart, guard, and paper textures remain the dynamic actor sources.
- `teaching_building_elevator_doors.png` remains usable after the corrected plates satisfy the shared `x=836` door aperture.
- The official “灿若星辰” material must be referenced by its existing approved asset ID and consumer. No generated replacement may be added. If its concrete source path is still absent when Task 13 starts, stop that task and request the path; do not substitute another image.

## 4. Runtime state sequence

| Phase | Floor plate | Time authority | Persisted outcome | Guard mode |
|---|---|---|---|---|
| `opening_handoff` | A1 `2245_opening` | `external_evidence` | control handed from replay to live scene | absent |
| `opening_paper_caught` | A1 `2245_opening` | `external_evidence` | paper secured; external submission rejected | absent |
| `hall_clock_inspection` | A1 `2245_opening` | `external_evidence` | old clock inspected | absent |
| `bakery_hour_hand` | A1 `1225_bakery` | `hall_clock` | hour hand collected | absent |
| `room204_restore` | A2/A3 `1850` | `hall_clock` | reference and residual observed; room restored; positioning plate collected | absent |
| `maintenance_repair` | A1 `2245_maintenance` | `hall_clock` | pry bar, cart repair, oil, clock gear repair | `patrol` |
| `blackout_light_grid` | A1 `0754_blackout` | `hall_clock` | minute stolen; five-zone light solution locked | absent until lock |
| `final_chase` | A1/A2 `0754` | `hall_clock` | chase attempt and chase-only checkpoint | `chase` |
| `final_minute_recovery` | A2 `202_final_minute` | `hall_clock` | last minute obtained | absent |
| `return_to_clock` | A1 `0754_blackout` | `hall_clock` | safe guard-free return | absent |
| `morning_checkin` | A1 `0755_morning` | `hall_clock` | card and paper accepted | absent |
| `exterior_closure` | approved existing exterior material | `hall_clock` | closing acknowledged | absent |
| `complete` | final morning state | `hall_clock` | `28500 / 07:55:00 / trusted=true` | absent |

Time-state changes must be atomic. One controller transition changes the phase, `timeState`, world seconds, phone seconds, trust marker, active plate ID, available targets, and checkpoint before publishing the presentation event.

## 5. Planned state and intent contracts

Update the existing Chapter 4 state rather than creating a second progression store.

```ts
export type ChapterFourTimeAuthority = "external_evidence" | "hall_clock";

export type ChapterFourTimeState =
  | "2245_opening"
  | "1225_bakery"
  | "1850_evening"
  | "2245_maintenance"
  | "0754_blackout"
  | "0755_morning";

export type ChapterFourGuardMode = "absent" | "patrol" | "chase";

export interface ChapterFourLightGridState {
  mask: number;
  locked: boolean;
}

export interface ChapterFourRoom204Placement {
  pieceId: string;
  slotId: string;
  orientation: "up" | "right" | "down" | "left";
}

export interface ChapterFourState {
  // Existing shared chapter fields remain where still applicable.
  phase: ChapterFourPhase;
  timeAuthority: ChapterFourTimeAuthority;
  timeState: ChapterFourTimeState;
  worldTimeSeconds: number;
  phoneStatusTimeSeconds: number;
  phoneStatusTimeTrusted: boolean;
  room204Placements: ChapterFourRoom204Placement[];
  lightGrid: ChapterFourLightGridState;
  guardMode: ChapterFourGuardMode;
  chaseAttempt: number;
  chaseRestartCheckpoint: RpgCheckpointId | null;
  completed: boolean;
}
```

Use one engine-neutral request at the React/Phaser boundary.

```ts
export type ChapterFour755Intent =
  | { type: "catch_opening_paper" }
  | { type: "inspect_hall_clock" }
  | { type: "pull_hall_clock" }
  | { type: "collect_hour_hand" }
  | { type: "use_item"; itemId: ItemId; targetId: string }
  | { type: "observe_room204_residual" }
  | { type: "observe_a3_reference" }
  | { type: "place_room204_piece"; pieceId: string; slotId: string; orientation: string }
  | { type: "toggle_light_zone"; zoneId: string }
  | { type: "enter_final_chase" }
  | { type: "final_chase_failed" }
  | { type: "enter_lecture_room_202" }
  | { type: "collect_final_minute" }
  | { type: "submit_checkin_part"; itemId: ItemId; targetId: string }
  | { type: "acknowledge_exterior_closure" };
```

`ChapterFourTemporalMazeController.resolve755Intent()` validates phase, floor, distance result, mode, item, target, and prior facts. The Phaser scene supplies target IDs and world context but never writes progression.

## 6. Execution tasks

### Task 0: Freeze the implementation baseline and file ownership

**Files:**

- Read: `AGENTS.md`
- Read: `project-development-report.md`
- Read: `progress.md`
- Read: all current Chapter 4 source files before editing

**Steps:**

1. Run `git branch --show-current`, `git status --short`, and `git log -1 --oneline`.
2. Save a path ownership list for the execution lanes:
   - asset lane: `src/assets/rpg/interiors/finale/chapter4-755/**`, environment manifest, asset scripts;
   - state lane: `src/core/**`, `src/modules/ChapterFour*`, content JSON, save migration;
   - scene lane: `ChapterFourTemporalMazeScene.ts`, `RpgGameHost.tsx`, Chapter 4 components/styles;
   - integration lane: Quest, DEV, debug, CI, documentation, and generated demo.
3. Run `npm run chapter4:validate-topology`, `npm run typecheck`, and `npm run verify:single`.
4. Record current outputs in `progress.md` without claiming that the new story is validated.
5. Do not stage, commit, clean, restore, or delete any current dirty-tree file.

**Expected:** the old validator may still report `13 puzzles`; TypeScript and the current single file should remain usable. Any changed baseline is recorded before edits.

### Task 1: Correct and promote the three structural masters

> 2026-08-21 superseding decision: the user approved the generated A1/A2/A3 plates as the geometry authority and selected floor-specific elevator anchors. The visible centers are A1 `772.5`, A2 `791`, and A3 `787.5`. Task 1 must promote the approved plates without moving their elevators to `x=836`; scene code, layout data, door visuals, stand points, travel zones, validators, and time-state registration must read the active floor's anchor. A1 walkable regions 25/26 are hidden passages behind the portrait wall and require foreground occlusion rather than collision.

**Files:**

- Create: `src/assets/rpg/interiors/finale/chapter4-755/base/a1.png`
- Create: `src/assets/rpg/interiors/finale/chapter4-755/base/a2.png`
- Create: `src/assets/rpg/interiors/finale/chapter4-755/base/a3.png`
- Create: `src/assets/rpg/interiors/finale/chapter4-755/README.md`
- Create: `scripts/normalize-chapter4-755-assets.mjs`

**Steps:**

1. Use a temporary working directory created by `mktemp -d`; preserve the ignored artifact originals.
2. Select A1 v01, A2 v02, and A3 v01 only.
3. Correct all three transport cores so the visible elevator center is exactly `x=836`, the usable door aperture matches the existing `72×96` door sheet, and the stair bounds are exactly `{x:932,y:145,width:138,height:107}`.
4. Add one visible lobby-to-bakery doorway through the A1 divider, wide enough for the existing player foot box plus at least `16px` horizontal clearance on both sides.
5. Preserve each room identity, floor projection, source-pixel density, and `1672×941` dimensions.
6. Save the three corrected masters to the tracked destinations.
7. Have `normalize-chapter4-755-assets.mjs` verify dimensions and copy only approved source IDs; it must fail when the shared transport-core metadata or bakery-door approval flag is missing.
8. Open all three PNGs at `1:1` and at the real `960×540` viewport. Delete temporary review captures after recording the conclusion.

**Expected:** three tracked `1672×941` masters with a shared transport core and a visible A1 bakery route. No Godot file is created or updated.

### Task 2: Correct, normalize, and register the nine time-state plates

**Files:**

- Create: `src/assets/rpg/interiors/finale/chapter4-755/states/*.png`
- Modify: `scripts/normalize-chapter4-755-assets.mjs`
- Modify: `src/assets/rpg/interiors/finale/chapter4-755/README.md`

**Steps:**

1. Apply the same transport-core correction to every state plate on its floor.
2. Apply the exact A1 bakery doorway correction to all six A1 images: base, opening, midday, maintenance, blackout, and morning.
3. For the three `1671×941` plates, copy the final source column to the right. Do not resize or interpolate:

```bash
magick input.png \( +clone -crop 1x941+1670+0 +repage \) +append output.png
```

4. Register at least five visual anchors per state plate: elevator center, stair bounds, main entrance or central hall, and two room-door corners.
5. Align each state plate to its corrected floor master. Geometry drift outside declared dynamic regions is a failure.
6. Record `normalizedFrom`, `renderMode`, `registrationAnchors`, and `calibrationStatus` in the source README.
7. Use image comparison only for structural regions; lighting and intended state differences are excluded through declared masks.

**Expected:** all nine plates are `1672×941`, share their floor master geometry, and pass manual anchor review. The three formerly narrow plates contain one copied edge column and no non-uniform scaling.

### Task 3: Build the authoritative asset, atlas, collision, and occlusion contracts

**Files:**

- Modify: `src/assets/rpg/interiors/finale/finale_environment_manifest.json`
- Modify: `scripts/build-finale-environment-manifest.mjs`
- Create: `scripts/verify-chapter4-755-assets.mjs`
- Modify: `package.json`
- Modify: `src/data/chapter4-three-floor-maze.layout.json`
- Modify: `scripts/verify-chapter4-temporal-maze.mjs`
- Modify: `src/assets/rpg/interiors/README.md`

**Steps:**

1. Upgrade `finale_environment_manifest.json` to schema 3 with `layoutContract`, `basePlates`, `statePlates`, and `spritesheets`.
2. Record every active asset’s size, Alpha role, SHA-256, source ID, browser consumer, and calibration status.
3. For every state plate record `floor`, `storyTime`, `renderMode`, `geometryAuthority`, `collisionProfileId`, and `physicalDeltaIds`.
4. Add explicit source trims from the sprite prompt document. Keep the 204 residual as 12 visual trims plus one group interaction bounds.
5. Upgrade `chapter4-three-floor-maze.layout.json` to schema 2 and convert gameplay rectangles to `{x,y,width,height}`.
6. Recalibrate static collisions, visible doorways, room portals, safe spawns, item targets, foot boxes, and foreground masks from the corrected masters.
7. Define state deltas. A1 midday adds queue rails; closed doors and moving furniture use conditional collisions; light, shadow, residuals, projection, and blackout remain non-colliding.
8. Remove active references to old A2 partitions, guide fragments, and old A3 wayfinding targets.
9. Extend topology validation to prove:
   - A1 lobby connects visibly to the bakery;
   - A2 rooms 201–204, transport core, and corridor share one walkable network;
   - A3 reference classroom is reachable;
   - the A1-to-A2-to-202 chase route is continuous;
   - all spawns and interaction stands are clear;
   - every active collision and occluder has a unique ID.
10. Add `chapter4:validate-assets` to `package.json`.

**Commands:**

```bash
npm run art:finale-environments
npm run chapter4:validate-assets
npm run chapter4:validate-topology
```

**Expected:** all commands pass; the manifest contains no reference-only candidate and no generated “灿若星辰” replacement.

### Task 4: Replace the old story contract and migrate saves

**Files:**

- Create: `src/data/chapter4-755.content.json`
- Create: `scripts/verify-chapter4-755-story.mjs`
- Modify: `package.json`
- Modify: `src/core/types.ts`
- Modify: `src/core/GameState.ts`
- Modify: `src/core/SaveStore.ts`
- Modify: `src/data/items.config.json`

**Steps:**

1. Author the ordered phases, time-state table, item transforms, five light zones, accepted check-in targets, task text, dialogue IDs, and completion invariants in `chapter4-755.content.json`.
2. Replace the active `ChapterFourPhase` and puzzle union with the 7:55 path. Keep legacy values only inside migration parsing.
3. Add `timeAuthority`, `timeState`, `worldTimeSeconds`, `phoneStatusTimeSeconds`, `phoneStatusTimeTrusted`, room placements, light-grid state, guard mode, and chase restart state.
4. Add inventory IDs:
   - `attendanceRecordPaper`
   - `oldClockHourHand`
   - `clockPositioningPlate`
   - `shortPryBar`
   - `universalLubricatingOil`
   - `finalMinute`
5. Keep `campusCard`; it is read at check-in and is not consumed.
6. Upgrade the save version from `24` to `25`.
7. Apply the default migration policy:
   - v24 before Chapter 4: preserve all prior facts and enter the new opening normally;
   - old Chapter 4 in progress: preserve Chapters 1–3.5 and global inventory, clear incompatible Chapter 4-only facts, restore the new A1 opening checkpoint;
   - old Chapter 4 complete: migrate to the new complete `07:55` state so completion never regresses; DEV and explicit story reset remain available for replay.
8. Preserve the existing previous-snapshot recovery and transient-UI sanitization.
9. Add `chapter4:validate-story`. It must reject the old `08:00/B2-04` terminal path and verify the exact time and item sequence.

**Commands:**

```bash
npm run chapter4:validate-story
npm run typecheck
```

**Expected:** both pass; fresh state begins at external `22:45` with frozen untrusted `07:55:23`, and completed state is `28500 / 28500 / trusted=true`.

### Task 5: Rebuild the controller projection and one host boundary

**Files:**

- Modify: `src/modules/ChapterFourTemporalMazeController.ts`
- Modify: `src/modules/ChapterFourMazeProjection.ts`
- Modify: `src/scenes/rpg/RpgGameHost.tsx`
- Modify: `src/scenes/rpg/RpgInteractionContract.ts`
- Modify: `src/core/FeatureAccess.ts`
- Modify: `src/components/StatusBar.tsx`

**Steps:**

1. Add `resolve755Intent()` and one `rpg_chapter4_755_intent_requested` event path in `RpgGameHost`.
2. Move every phase transition, item grant/consume, time change, checkpoint write, and chase recovery into the controller.
3. Rewrite the active maze projection to derive plate ID, targets, dynamic collisions, occlusions, NPCs, guard mode, doors, and safe checkpoint from current state.
4. Use one controller helper for atomic time transitions; do not set the phone clock independently in a component or scene.
5. Add exact `RpgInteractionContract` entries for the notice paper, old clock, conveyor lamp, hour hand, A3 reference, 204 residual group, furniture pieces, cart wheel, pry-bar pickup, clock gear, power panel, 202 threshold, final-minute projection, card reader, and paper slot.
6. Make the old phone calibration page and old Chapter 4 Settings/CC98/WeChat gates non-blocking and unreachable from the new mainline.
7. Before the first hall-clock pull, show the frozen untrusted time; after the pull, show the time derived from the same `timeState` as Phaser.

**Commands:**

```bash
npm run chapter4:validate-story
npm run chapter4:validate-topology
npm run typecheck
```

**Expected:** all pass; no accepted intent can advance out of order, and no component writes Chapter 4 progression directly.

### Task 6: Add atomic plate switching and dynamic depth layers

**Files:**

- Modify: `src/scenes/rpg/FinaleEnvironmentTextures.ts`
- Modify: `src/scenes/rpg/ChapterFourTemporalMazeScene.ts`
- Modify: `src/scenes/rpg/RpgAssetLoader.ts`
- Modify: `src/scenes/rpg/RpgRuntimeDebug.ts`

**Steps:**

1. Register the three masters, nine state plates, and five active sprite sheets in the shared texture registry.
2. Remove direct scene-local imports of the three old teaching-building floor PNGs.
3. Keep a background object reference for every floor and call `setTexture()` on a time-state transition.
4. Rebuild the matching foreground crops after a plate change. A foreground mask may only crop the currently active plate.
5. Remove the old hard-coded A2 desk occlusion crop; use dynamic furniture sprites, foot collisions, and bottom-pivot y-sort.
6. Load explicit atlas trims. Never use the source sheet’s coarse grid when a full object crosses a cell.
7. Keep source coordinates unchanged across the `960×540` viewport and stitched floor offsets.
8. Expose `plateId`, `activeCollisionIds`, `activeOcclusionIds`, `lightingZones`, and `contractFailures` through runtime debug.
9. Limit `?debugColliders=1` to `import.meta.env.DEV`; it must not render in the release single file.

**Expected:** changing time swaps one opaque plate without flicker, stale foreground crops, stale dynamic collision, or camera movement.

### Task 7: Implement the replay handoff, first paper catch, and hall-clock takeover

**Files:**

- Modify: `src/scenes/rpg/Chapter4PrologueOverlay.tsx`
- Modify: `src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts`
- Modify: `src/scenes/rpg/ChapterFourTemporalMazeScene.ts`
- Modify: `src/modules/ChapterFourTemporalMazeController.ts`
- Modify: `src/data/chapter4-755.content.json`

**Steps:**

1. End the recovered replay on the A1 glass-door composition and transfer control directly to the live `a1_2245_opening` plate.
2. Remove any second route decision or pursuit between replay completion and the noticeboard paper.
3. Spawn the paper `4–6m` ahead, move it to the noticeboard, and enable one catch target.
4. On catch, grant `attendanceRecordPaper` once, run the controller-owned external-time check, and reject submission at `22:45` while the phone close-up still reports `07:55:23 / untrusted`.
5. Enable the old-clock inspection target only after the rejection sequence resolves.
6. First pull sets `timeAuthority=hall_clock` and `timeState=1225_bakery` in one transition, then emits the light/sound/plate cue.
7. Use the clock atlas for missing-hand and gear-stutter visuals; no clock-state sprite owns progression.

**Expected:** the route contains no second chase, no repeated evidence selection, and no black frame. The phone, map, clock, and task objective change together on the first pull.

### Task 8: Implement the 12:25 bakery hour-hand sequence

**Files:**

- Modify: `src/scenes/rpg/ChapterFourTemporalMazeScene.ts`
- Modify: `src/modules/ChapterFourTemporalMazeController.ts`
- Modify: `src/data/chapter4-755.content.json`
- Modify: `src/core/QuestModel.ts`

**Steps:**

1. Activate the midday plate, queue-rail collision delta, student crowd routes, bakery sound direction, baker NPC, inspection lamp, conveyor, and hour-hand target.
2. Keep at least one visible walkable gap through the queue rails and a second route around the crowd.
3. Reject the conveyor pickup before the inspection lamp is used; show one corrective line.
4. Stop the conveyor for the authored short beat and expose the hour-hand pickup.
5. Grant `oldClockHourHand` once and update the objective to the hall clock.
6. Accept an inventory drop only at the visible clock bounds and only in light operation mode.
7. Install the hour hand, consume it, animate the clock atlas, and transition atomically to `1850_evening`.

**Expected:** the chocolate decoration never becomes an item; the metal hour hand is acquired once; crowd and queue geometry never block the only bakery exit.

### Task 9: Implement A3 reference observation and A2 room 204 restoration

**Files:**

- Create: `src/scenes/rpg/ChapterFourRoom204Model.ts`
- Modify: `src/scenes/rpg/ChapterFourTemporalMazeScene.ts`
- Modify: `src/modules/ChapterFourTemporalMazeController.ts`
- Modify: `src/data/chapter4-three-floor-maze.layout.json`
- Modify: `src/data/chapter4-755.content.json`

**Steps:**

1. Enable normal elevator and stair travel between A2 and A3 at 18:50; the old historical-elevator minigame stays inactive.
2. At A3, let one observation of the standard room record the reference layout.
3. At A2 room 204, show the 12 residual targets only in dark observation mode. One group interaction records every simultaneously visible target.
4. Return to light operation for physical movement.
5. Build 12 paired desk/chair units from explicit trims. Use the four group tables as the displaced discussion layout and the podium as the fixed axis reference.
6. Persist only `pieceId`, `slotId`, and orientation after a valid snap; pixel tween positions remain runtime-only.
7. Keep the door, central aisle, and both side aisles open for every partial arrangement.
8. Require both the A3 reference fact and the A2 residual fact before accepting the final layout.
9. On the symmetric 12-slot solution, show the short `07:55` projection, open the podium drawer, and grant `clockPositioningPlate` once.
10. Install the plate at the hall clock and transition atomically to `2245_maintenance`.

**Expected:** residual pixels never collide; the player can leave and return without losing saved placements; the completed room matches the A3 reference and retains three walkable aisles.

### Task 10: Implement the 22:45 maintenance loop and ordinary patrol

**Files:**

- Create: `src/scenes/rpg/ChapterFourGuardModel.ts`
- Modify: `src/scenes/rpg/ChapterFourTemporalMazeScene.ts`
- Modify: `src/modules/ChapterFourTemporalMazeController.ts`
- Modify: `src/data/chapter4-three-floor-maze.layout.json`
- Modify: `src/data/chapter4-755.content.json`

**Steps:**

1. Activate the maintenance plate, cleaner, cleaning cart, guard, bakery-back-corner pry bar, and clock-gear target.
2. Define patrol waypoints through east/west corridors and the stair mouth. Patrol pauses last `1–2s` and never enter closed classrooms.
3. Implement a forward cone, close radius, `0.4s` confirmation, last-visible target, and short pursuit.
4. End ordinary pursuit after a continuous line-of-sight loss window; restore a valid new patrol waypoint.
5. On patrol contact, restore the latest maintenance safe checkpoint while preserving every acquired story item and accepted cart action.
6. Require `shortPryBar` at the visible cart wheel cover. Consume or mark its final use only after the cover opens.
7. Reveal and grant `universalLubricatingOil` after the wheel cover opens. Require its first accepted use on the cart wheel; keep the same inventory item available as the remaining half bottle.
8. Apply the remaining oil to the old-clock gear, consume it, set gear-running visual state, and enable the final clock drag.

**Expected:** ordinary patrol can be escaped by breaking sight; it has no countdown and cannot erase acquired items. The oil cannot be taken before the cart is repaired.

### Task 11: Implement minute theft, blackout, and the five-zone light grid

**Files:**

- Create: `src/components/temporal-maze/ChapterFourPowerPanelGame.tsx`
- Create: `src/modules/ChapterFourLightGridModel.ts`
- Create: `src/styles/chapter4-755.css`
- Modify: `src/scenes/rpg/RpgGameHost.tsx`
- Modify: `src/scenes/rpg/ChapterFourTemporalMazeScene.ts`
- Modify: `src/modules/ChapterFourTemporalMazeController.ts`
- Modify: `src/data/chapter4-755.content.json`

**Steps:**

1. Let the repaired clock approach 07:55; trigger the paper animation before the minute hand settles.
2. Move the paper out of inventory, set `timeState=0754_blackout`, swap to the blackout plate, and disable ordinary patrol.
3. Open the power-panel surface only from its visible A1 wall bounds.
4. Render five labelled buttons: hall, west corridor, east corridor, classroom zone, bakery back area.
5. Each button flips its declared node and adjacent nodes from content JSON.
6. The pure model evaluates required-on and required-off zones. It must have at least one solution, and the all-on mask must fail.
7. Phaser applies light-zone visuals only. Light edges do not change collision.
8. On success, persist the mask, set `locked=true`, close the panel, and reject all later toggle requests.
9. Do not show an arrow, waypoint, or distance; leave only the objective “前往阶梯教室”.

**Expected:** the route to the stair and 202 remains visibly readable; off-route regions remain dark; the solution survives refresh and every later chase failure.

### Task 12: Implement the continuous final pursuit and final-minute recovery

**Files:**

- Modify: `src/scenes/rpg/ChapterFourGuardModel.ts`
- Modify: `src/scenes/rpg/ChapterFourTemporalMazeScene.ts`
- Modify: `src/modules/ChapterFourTemporalMazeController.ts`
- Modify: `src/data/chapter4-three-floor-maze.layout.json`
- Modify: `src/data/chapter4-755.content.json`

**Steps:**

1. Start the final guard behind the player only after the light grid locks.
2. Switch to `guardMode=chase`; remove random patrol, confirmation delay, and line-of-sight disengagement.
3. Use an authored waypoint graph from A1 hall through the stair transition to the A2 202 threshold. Do not add a pathfinding dependency.
4. Preserve pursuit across the floor transition by moving the guard to the paired stair portal with retained pursuit state.
5. Use foot-box contact only. Resolve the 202 threshold before guard contact on the same frame.
6. On contact, increment `chaseAttempt`, show the short failure text, and restore the chase start checkpoint. Preserve light mask, locked state, open doors, and all prior story facts.
7. On success, close the 202 door, set `guardMode=absent`, switch to `a2_202_final_minute`, and stop pursuit input.
8. Provide one projected-paper target. No puzzle panel, combination, or timing gate follows.
9. Grant `finalMinute` once, restore the attendance paper, and open a guard-free route back to A1.

**Expected:** ordinary patrol and final chase are distinct model states; the final chase never disengages; failure restarts only the chase; the return trip contains no guard.

### Task 13: Implement 07:55 restoration, check-in, and approved exterior closure

**Files:**

- Modify: `src/scenes/rpg/ChapterFourTemporalMazeScene.ts`
- Modify: `src/modules/ChapterFourTemporalMazeController.ts`
- Modify: `src/modules/PresentationDirector.ts`
- Modify: `src/data/chapter4-755.content.json`
- Modify: approved existing “灿若星辰” consumer only after its path is confirmed

**Steps:**

1. Accept `finalMinute` only at the visible minute-hand endpoint on the old clock.
2. Consume it and transition atomically to `0755_morning`, world time `28500`, phone time `28500`, and trusted time.
3. Open the authored morning doors and enable two visible check-in subtargets: campus-card reader and attendance-paper slot.
4. Accept the two parts in either order. The campus card remains; the attendance paper becomes the final signed record.
5. Complete check-in only after both facts are present and Chapter 3.5 remains complete.
6. Publish the check-in result and `外面亮了一下` through controller-owned events.
7. Locate and register the existing approved “灿若星辰” asset/sequence. If its source path is missing, stop here and request the path.
8. Route the player to the existing exterior sequence, accept one lamp interaction, and return `acknowledge_exterior_closure` to the controller.
9. Mark Chapter 4 complete only after the closure event. Refresh must keep `28500 / 28500 / trusted=true` and must not restore `22:45` or frozen `07:55:23`.

**Expected:** the ending uses the approved existing material, contains no new generated star-lamp asset, and produces one stable completed save.

### Task 14: Align quest text, audio events, DEV checkpoints, and runtime debug

**Files:**

- Modify: `src/core/QuestModel.ts`
- Modify: `src/modules/AudioDirector.ts`
- Modify: `src/modules/PresentationDirector.ts`
- Modify: `src/modules/DeveloperChannel.ts`
- Modify: `src/components/DeveloperChannel.tsx`
- Modify: `src/scenes/rpg/RpgRuntimeDebug.ts`
- Modify: `src/main.tsx`
- Modify: `docs/gameplay-debug-walkthrough.md`

**Steps:**

1. Replace the old 13-step Chapter 4 task projection with one current objective from the approved task table.
2. Keep only the three authored hints for room restoration, maintenance repair, and light grid. Do not reveal future items or the chase route.
3. Map domain events for time swaps, conveyor stop, drawer open, cart scrape/repair, clock gear, power toggles, patrol warning, chase start/failure/success, minute restoration, check-in, and closure.
4. Keep audio failure non-blocking.
5. Add DEV checkpoints:
   - `c4-755-opening`
   - `c4-755-hall-clock`
   - `c4-755-bakery-1225`
   - `c4-755-room204-1850`
   - `c4-755-maintenance-2245`
   - `c4-755-blackout-0754`
   - `c4-755-light-grid`
   - `c4-755-chase`
   - `c4-755-final-minute`
   - `c4-755-checkin`
   - `c4-755-complete`
6. Seed real phase, floor, time, item, room placement, light mask, guard, checkpoint, mode, and closed transient UI for every checkpoint.
7. Extend `render_game_to_text()` with plate, time authority, world/phone seconds, trust, occlusion, lighting, guard state, chase attempt, restart checkpoint, and contract failures.
8. Confirm DEV state remains session-only and can restore the pre-jump state.

**Expected:** every checkpoint can perform the next intended action; no checkpoint opens an old `08:00`, B-building, old wayfinding, or Three.js story route.

### Task 15: Add CI gates and execute the complete acceptance matrix

**Files:**

- Modify: `.github/workflows/web-ci.yml`
- Modify: `docs/client-compatibility.md` only if the support contract changes
- Modify: `progress.md`
- Modify: `project-development-report.md`
- Generate: `demo/index.html` through the canonical build command

**Static commands:**

```bash
npm run chapter4:validate-assets
npm run chapter4:validate-story
npm run chapter4:validate-topology
npm run typecheck
npm run build
npm run build:single
npm run verify:single
git diff --check
```

Add the three Chapter 4 validators to CI before typecheck.

**Browser commands:**

```bash
npm run dev -- --host 127.0.0.1 --port 5173
python3 -m http.server 4173 --directory demo
```

**Browser matrix:**

1. Open all 11 DEV checkpoints in Blink at `1280×720`.
2. Run one complete keyboard playthrough from A1 handoff through exterior closure.
3. Repeat room restoration, power panel, chase, inventory drops, and check-in with pointer/touch at `390×844`.
4. Check Blink at `1280×800` for letterboxing and UI boundaries.
5. Repeat the complete critical path in Gecko and WebKit at `1280×720`.
6. Verify every active plate at its source-pixel collision samples: solid pixels block, clear floor passes, spawn is open, and the real player foot box stops at the expected edge.
7. Walk before and behind walls, counters, furniture, plants, doors, and the 202 threshold to inspect occlusion.
8. Test refresh at each safe story phase.
9. Test one v24 pre-Chapter-4 save, one v24 in-progress save, one v24 completed save, and one corrupted-primary/valid-backup save.
10. Fail the final chase twice, then succeed; confirm the locked light state and open doors survive.
11. Open the rebuilt single file through HTTP and `file://`; repeat opening, room 204, chase, and completed refresh.
12. Confirm one Phaser canvas, `16:9`, no document overflow, no external media, and zero console/page errors.
13. Inspect all temporary screenshots, record conclusions, and delete the screenshots before completion.
14. Record final demo size, SHA-256, inline script/style counts, browser matrix, migration count, and remaining limitations in both project reports.

**Expected:** every command passes and all browser scenarios meet the project compatibility contract. `demo/index.html` is generated, never edited by hand.

**Task 15 status on 2026-08-22:**

- CI now runs the five Chapter 4 gates before `typecheck`. Fresh assets, story, topology (`2497` assertions), runtime (`1171` assertions), Task14 (`215` assertions), typecheck, production build, single-file build, single-file verification, and diff checks all passed. Asset verification also passed both full-local-provenance and clean-checkout tracked-contract modes; the partial-provenance negative probe failed as required.
- Blink passed all 11 DEV checkpoints at `1280×720`, the `1280×800` letterbox/UI inspection, and the `390×844` coarse-pointer layout. Genuine interactions covered Room204 keyboard movement, solving and locking the power panel from mask `6` to `13`, both check-in item drops, two chase failures followed by a main-stair success, and phone-home task re-entry to the same RPG scene/checkpoint.
- Formal persistence passed after a genuine campus-card drop with the DEV session marker removed: reload restored `morning_checkin`, the accepted card fact, the unaccepted paper fact, and the same RPG scene/checkpoint with no developer checkpoint. The permanent runtime validator also passed four migration cases: v24 pre-Chapter-4, v24 in-progress, v24 completed downgraded to exterior waiting when official closure proof is absent, and corrupt-primary recovery from a valid v24 backup.
- Firefox and WebKit each passed the 11-checkpoint `1280×720` smoke matrix with committed/applied agreement, one visible `16:9` canvas, no overflow, empty contract failures, and finite positive chase guard bounds. Recorded `pageerror`, `console.error`, and `requestfailed` counts were all zero.
- The rebuilt ignored `demo/index.html` passed HTTP and direct `file://` smoke for opening, Room204, chase, and completed-state refresh. Final artifact: `236019677` bytes, SHA-256 `7a011c99f78a22c54e7a2b0e9888f93bfef02967cdf8aec28215d1d765479478`, two inline scripts, one inline style. It remains a local generated verification artifact and is not automatically part of the Git scope.
- The user waived the three-floor browser collision and occlusion专项 only. The approved exterior closure asset/consumer proof is still absent, so the natural full run correctly stops at `exterior_closure` waiting; no substitute `灿若星辰` asset or completion proof was fabricated. All Task 15 screenshots, temporary QA directories, and browser sessions were removed after inspection.

### Task 16: Prepare the Git delivery without mutating it

**Files:** none until the user approves the exact delivery scope.

**Steps:**

1. Fetch the relevant GitHub remote read-only.
2. Present three separate views:
   - working-tree changes including untracked files;
   - local commits absent from the tracked remote branch;
   - remote commits absent locally.
3. Identify generated files, ignored artifact sources, reference-only candidates, existing unrelated changes, and the exact normalized runtime assets.
4. Ask the user to approve the path-scoped upload set and whether delivery goes directly to `main` under the repository’s current policy.
5. Only after approval, stage exact paths, commit, push, merge, and verify the remote `main` paths.
6. Apply the actual Asia/Shanghai completion date to delivery names after remote verification.

**Task 16 read-only status on 2026-08-22:**

- `git fetch --prune origin` completed. The current checkout is `codex/bike-rush-visual-redesign` at `c667bab`, tracking `origin/codex/bike-rush-visual-redesign`; it is `ahead 2 / behind 0` relative to that stale topic ref.
- Relative to current `origin/main` (`2a540e7`), local-only commits are `0` and remote-only commits are `17`. `merge-base(HEAD, origin/main)` equals current `HEAD`, so this checkout is an ancestor of remote `main` and must first integrate those 17 commits before a direct `main` delivery can be validated.
- After H3 temporary-snapshot cleanup, the working tree contains `104` modified tracked files and `586` untracked files (`131` collapsed `??` status entries). It mixes Chapter 4 Tasks 3–16, Chapter 3/Qizhen/theater work, archived Godot artifacts, H3/PV/canteen packages, older Playwright MCP metadata, and generated/debug outputs. The ignored `demo/index.html` is a local verification artifact.
- The H3 integration itself spans the normalized MP4 and compact music, manifest/audio metadata, App-level gate, overlay/timeline, recovery controller, RPG host/scene handshake, styles, single-file MSE loader, validators, and reports. Several of these depend on the broader untracked Chapter 4 implementation, so an isolated two-file media commit would not produce a runnable feature.
- No staging, commit, merge, rebase, push, branch switch, reset, or repository-wide cleanup was performed. Only the explicitly identified H3 browser snapshots were moved to the macOS Trash after inspection. Delivery remains at the mandatory scope-selection gate.

## 7. Execution dependency graph

```text
Task 0 baseline
  ├─ Task 1 structural masters ─ Task 2 state plates ─ Task 3 asset/layout contracts
  └─ Task 4 state/save ─ Task 5 controller boundary
                                      │
Task 3 + Task 5 ─ Task 6 renderer ─ Tasks 7–13 gameplay slices
                                      │
                               Task 14 integration
                                      │
                               Task 15 acceptance
                                      │
                               Task 16 Git decision
```

Safe parallel execution after Task 0:

- asset worker owns Tasks 1–3;
- state/controller worker owns Tasks 4–5;
- no scene worker begins Task 6 until both lanes pass their validators;
- gameplay slices run in order because each consumes the previous phase contract;
- one integration owner handles Tasks 14–16.

All workers share the dirty worktree. Each worker must preserve other edits, avoid broad formatting, and never revert files outside its ownership.

## 8. Estimated delivery slices

| Slice | Scope | Estimate |
|---|---|---:|
| A | structural correction of 3 masters and 9 state plates | 1.5–2.0 days |
| B | manifests, calibrated collision/occlusion, validators | 1.0–1.5 days |
| C | state, save v25, controller, projection, renderer | 1.5–2.0 days |
| D | opening, bakery, room 204, maintenance | 2.0–2.5 days |
| E | blackout, light grid, final chase, check-in, closure | 1.5–2.0 days |
| F | DEV, cross-browser, migration, single-file acceptance | 1.0–1.5 days |

Total estimate: `8.5–11.5` developer days. Implementation validation count is `0`, so this estimate is a hypothesis. Re-estimate after Tasks 1–5 pass with the corrected asset dimensions, calibrated topology, and migrated state contract.

## 9. 2026-08-22 H3 chapter 3.5 to chapter 4 runtime integration

### Delivered asset

- Joined the three user-supplied MP4 files in the approved narrative order: lake departure, arcade and entrance, then lobby and lights-out corridor.
- Normalized the checked-in runtime asset to `960×540`, `24 FPS`, H.264 High, `yuv420p`, `1052` frames, and `43.833333s` without changing playback speed, then remuxed it as fragmented MP4 for incremental single-file playback.
- Removed all generated audio. The output contains one video stream and remains subordinate to `src/data/chapter4-prologue.audio.json`.
- Final video size is `8282814` bytes. Output SHA-256: `d5cb9e9a91ef778337f5eeef74fad59643ca1f393607f993d7e5fc8196678aff`; full-frame SSIM against the pre-compression normalized splice is `0.988282`.
- Added a compact `44.000000s`, `353687`-byte, `64306 bit/s`, `44.1kHz` stereo MP3 for this runtime. Its SHA-256 is `0b8e5a0eb47f431af5d96f13b9bbff07580419b1641de9e6637fa59d7c4685c6`; the larger source music remains unchanged.
- Locked the output, all three source hashes, fragmented-container contract, scene cuts, and runtime music fingerprint in `src/data/chapter4-prologue-h3.asset.json`.

### Runtime contract

- `Chapter4PrologueOverlay` plays the H3 file as the primary visual, keeps it muted and synchronized to the TypeScript elapsed-time authority, and pauses it when the task card appears. Normal Vite builds use the emitted asset URL; the single file decodes `256 KiB` Base64 chunks in a Worker and serially appends them through `MediaSource / SourceBuffer`, avoiding one giant main-thread data URL or Blob allocation.
- The existing Canvas 2D renderer remains active until H3 is ready and resumes as the failure or reduced-motion fallback. Canvas frame rendering stops while the H3 layer is healthy.
- The active timeline now uses `snap / lake_exit / arcade / entrance / lobby / closing`, ending at `43834ms`. Local wet-floor, broadcast-static, and lights-out cues align with the actual third clip.
- `Chapter4PrologueRuntimeGate` is the sole task-card confirmation and A1 handoff owner. It keeps the lower runtime mounted under `inert`, `aria-hidden`, pointer and keyboard blocks; submits `complete_prologue_handoff` once; correlates the A1 live-ready response by `requestId`; retries the correlation pulse internally; and releases the overlay `80ms` after `a1_2245_opening + contractReady` succeeds.
- `RpgGameHost` consumes only the gate block state and explicitly rejects `complete_prologue_handoff` on its generic intent path. A 20-second readiness timeout changes the retry UI while retaining the mounted Phaser instance and committed controller state.

### Verification evidence

- MP4 probe: one H.264 High video stream, `960×540`, `24/1`, `1052` decoded frames, `43.833333s`, `8282814` bytes, `yuv420p`, and zero audio streams. The container starts with `ftyp + moov` and carries `mvex/moof/mdat` fragmentation for MSE.
- Fresh commands passed: assets, story, topology (`2497` assertions), runtime (`1171` assertions), Task14 (`215` assertions), typecheck, production build, `build:single`, `verify:single`, and targeted `git diff --check`.
- HTTP single-file H3 playback passed in Chromium, Firefox, and WebKit with `data-h3-source="blob"`, `data-h3-video="ready"`, actual `currentTime` advance, decoded `960×540`, `paused=false` during playback, `error=null`, and zero console errors. Firefox emitted one non-fatal `WebGL context was lost` warning after the media proof.
- Chromium and WebKit exercised the task card and automatic A1 handoff. Both ended at `duan_yongping_temporal_maze / c4_a1_lobby / opening_handoff`, `a1_2245_opening`, one Phaser canvas, restored input, `contractFailures=[]`, and zero console errors. WebKit event evidence contained the same request ID across retry, live-ready, and handoff-release events; no user-facing retry was clicked.
- Vite playback passed with `data-h3-source="url"`, `data-h3-video="ready"`, `currentTime 8.7146 → 20.7970`, `960×540`, `error=null`, and zero console errors. Reduced-motion Chromium used `data-h3-video="fallback"`, paused and hid the video, retained the Canvas role `img`, and logged zero errors.
- Reloading through the legacy DEV ID `c4-prologue-task-card` safely migrated it to the canonical `c4-755-opening` checkpoint and completed the correlated A1 recovery without a manual retry. That legacy ID serves only as a compatibility alias and does not persist a task-card scene; formal committed `opening_handoff` recovery still initializes the overlay at `43834ms` while the lower A1 runtime applies.
- The generated ignored `demo/index.html` is `246712370` bytes with SHA-256 `3c8ecf5963200ba6da727199e1fc71d391ea2de5536542d516e229ffc4a8609a`, two inline scripts, one inline style, and zero external script or stylesheet tags.
- A fresh direct `file://` browser pass was not run because the Playwright CLI blocks that protocol. The structural single-file verifier and HTTP embedded-data playback passed. The previously approved three-floor browser collision and occlusion waiver remains in force.
- User source videos were preserved with their original hashes. All H3 browser sessions and the temporary Vite `4187` service were closed; inspected temporary screenshots were deleted or moved to the macOS Trash. The shared `4173` single-file service was stopped during final cleanup. No Git staging, commit, push, merge, rebase, or reset was executed.

## 10. 2026-08-22 Chapter 4 H3 MiniMax scene-voice repair

### Gap analysis and prompt contract

- Inspected the complete `43.833333s` H3 sequence against the existing four-character voice catalog, subtitle beats, scene cuts, and single-file runtime. The player (`English_Diligent_Man`) and narrator (`English_expressive_narrator`) already fit their visual windows and remain byte-identical. The former cleaner take was `6211ms`, which exceeded the lobby window, while the former guard take was `4805ms` and had no active timeline beat.
- Added `docs/plans/2026-08-22-chapter4-h3-scene-voice-prompts.md` as the six-phase scene and delivery contract. It fixes the voice IDs, English synthesis copy, Chinese subtitles, speed, emotion, normalization profile, cue time, duration ceiling, and acceptance margin. The `lake_exit` and `entrance` phases intentionally retain only their local sound design.

### MiniMax generation and runtime integration

- Verified the locally authenticated `mmx 1.0.15` client and invoked `speech synthesize` for the two missing NPC lines, including one short-line pacing refinement. The cleaner retained `Chinese (Mandarin)_Kind-hearted_Antie`; the guard retained `English_Trustworthy_Man`.
- Cleaner final: `Careful, I just mopped. That paper went inside.` with Chinese subtitle `小心，刚拖过。那张纸往里去了。`; `2841ms`, `47796` bytes, `32kHz` mono MP3, SHA-256 `3a7d8182c146d98e326e3fef26ff05873b5a95b305bec17c20b27e374439c465`, integrated loudness `-17.2 LUFS`, true peak `-1.9 dBFS`.
- Guard final: `The North Teaching Building is closing. Please pack up.` with Chinese subtitle `同学，北教要清楼了，请收好东西。`; `2413ms`, `41460` bytes, `32kHz` mono MP3, SHA-256 `b49d31593914e24bf459b4f36670afffbe6abf7efd1d96e5da33e53dd4c408b4`, integrated loudness `-17.8 LUFS`, true peak `-1.9 dBFS`.
- The generation script now validates scene identity, cue timing, duration ceilings, delivery prompts, emotion, and normalization profile before replacing formal assets. `short_dialogue_consistent_v2` applies light compression followed by the existing dual-pass loudness normalization. Existing player and narrator measurements are `-16.4` and `-16.7 LUFS`, keeping the four-line automatic loudness spread within approximately `1.4 LU`.
- `PrologueTimeline.ts` now schedules the cleaner at `29450ms` and the guard at `36000ms`. Their measured ends are `32291ms` and `38413ms`, leaving `1126ms` before the lobby cut and `2629ms` before broadcast static. The audio manifest, authored content catalog, generated provenance catalog, and story validator carry the same contract.

### Verification and current boundary

- Fresh verification passed for generation `--verify-only`, Chapter 4 story validation, TypeScript, single-file build, single-file structure, and targeted whitespace/diff checks.
- A formal saved-state Chromium run of the final single file displayed the cleaner subtitle at H3 time `29.543299s` and the guard subtitle at `36.126699s`; both loaded the final embedded MP3 data, with zero console errors and zero warnings. Final `demo/index.html`: `246590721` bytes, SHA-256 `a1ac086d94ad0de439a903fd3f8b8a72521ff8ae6c9a3401e078b13843c3dd70`.
- Automated timing, encoding, loudness, manifest, build, and runtime checks passed. Human acceptance of voice timbre, acting, pronunciation, and mix balance remains pending the user's audition; this report does not promote structural validation into subjective approval.
- No `灿若星辰` material was generated. The waived three-floor browser collision and occlusion suite was not run. No Git staging, commit, push, merge, rebase, reset, or broad cleanup occurred. Temporary frames, loudness files, browser snapshots, and browser sessions from this task were moved to the macOS Trash or closed after inspection.

## 11. 2026-08-22 Final single-file demo packaging

- Re-ran the canonical `npm run build:single` entry after the H3 scene-voice integration. TypeScript and Vite completed successfully, transforming `606` modules and inlining the application into `demo/index.html`.
- `npm run verify:single` passed with `2` inline scripts, `1` inline style, and a final size of `246590721` bytes. The artifact modification time is `2026-08-22 13:32:09 CST`; SHA-256 is `a1ac086d94ad0de439a903fd3f8b8a72521ff8ae6c9a3401e078b13843c3dd70`.
- Full Base64 payload matching against the packaged HTML confirmed that the cleaner MP3 is embedded (`63728` Base64 characters) and the guard MP3 is embedded (`55280` Base64 characters). The four-voice provenance manifest passed `--verify-only` without regeneration.
- The distributable is the canonical single file `demo/index.html`. No duplicate ZIP was created, and no Git staging, commit, push, merge, rebase, or reset was performed.

## 12. 2026-08-22 All-chapter facing-agnostic interactions and Chapter 4 active-floor bounds

### Global interaction contract

- Character facing and kayak heading are locomotion and non-gating presentation state only. They continue to drive movement animation, sprite selection, kayak steering, pursuit, roll, wakes, and captured-image composition.
- Story interactions across every chapter do not read facing. Observation, pickup, dialogue, doors, devices, item drag and drop, stairs, elevators, fishing, lockers, and entity use are resolved from the active target, reality mode, accepted item, visible-edge distance, and drop bounds where relevant.
- `RpgInteractionContract.ts` no longer defines `requiredFacing`, `facingToleranceDegrees`, `wrong_facing`, cardinal-facing vectors, target-facing tests, or player-ready-facing helpers. Chapter 4 spatial attestations no longer transport `cardinalFacing`.
- Library, canteen, theater, Qizhen Lake, and Chapter 4 scene/model targets were migrated to the same contract. Prompts and rejection feedback no longer ask the player to turn toward a target.

### Chapter 4 physical boundary contract

- Every floor transition applies four-sided Phaser physics bounds before input resumes, then applies the same camera bounds. The player body keeps `collideWorldBounds` enabled.
- The active source-pixel rectangles are A1 `[0,1672] × [0,941]`, A2 `[1864,3536] × [0,941]`, and A3 `[3728,5400] × [0,941]` in world coordinates. The `192px` gaps between floor plates are outside the active physics world and cannot be entered.
- Runtime debug state exposes `chapterFour.activeFloorBounds`, allowing validation to compare the current floor manifest, camera, and physics world without inferring coordinates from a screenshot.

### Regression protection and verification

- Added `scripts/verify-rpg-facing-agnostic.mjs` and the `verify:rpg-facing-agnostic` package command. The CI workflow runs it on every push and pull request and rejects reintroduced facing-gate fields, outcomes, helpers, or interaction prompts in active source files.
- Static validation passed: facing guard `256` files and `0` forbidden matches; Chapter 4 topology `2495` assertions; runtime `1125` assertions; Task 14 `220` assertions; TypeScript; and the regular Vite production build. The build emitted only the existing large-chunk advisory.
- Chromium `1280×720` exercised all four outward directions on each of A1, A2, and A3. All `12/12` attempts stopped on the exact active-floor edge, including both sides adjacent to inter-floor gaps, with zero console/page errors.
- Facing-agnostic real-scene checks passed in three chapters: the Chapter 2 library record opened while facing down; the Chapter 3 theater kiosk responded while the player faced left with the target to the right; the Chapter 4 A3 classroom reference recorded `a3_reference_observed` while the player faced away. The visual facing value remained unchanged after each interaction.
- This task intentionally did not run `build:single`, did not rewrite `demo/index.html`, and did not perform Git staging, commit, merge, push, rebase, or reset.

## 13. 2026-08-22 Single-file packaging after the global interaction and floor-boundary update

- The user subsequently authorized packaging. `npm run build:single` ran the full `tsc --noEmit` plus Vite Demo build, transformed `606` modules, inlined the generated JavaScript and CSS, and replaced the canonical `demo/index.html`.
- The new artifact is `246582539` bytes with modification time `2026-08-22 16:28:03 CST` and SHA-256 `259583dcb1d4142d590426c12b0667d8ce313e6389b5d54bbda5cae079d27f9f`.
- `npm run verify:single` passed with `2` inline scripts, `1` inline style, and validated internal entries `campus-map-demo.html`, `chapter4-monument-stair-demo.html`, and `index.html`.
- Fresh related checks passed: facing-agnostic guard `256` active files and `0` forbidden matches; Chapter 4 topology `2495` assertions; Chapter 4 runtime `1125` assertions; Task 14 `220` assertions.
- Chromium opened the rebuilt single file over local HTTP at `c4-755-room204-1850`. It mounted one React root and one Phaser canvas, entered `duan_yongping_temporal_maze`, exposed A3 active bounds `{x:3728,y:0,width:1672,height:941}`, and reported `contractFailures=[]`, zero console errors, and zero warnings. The request log contained only one `200 OK` request for `index.html`, confirming that the runtime did not fetch external assets in this session.
- Playwright CLI blocked navigation to the `file:` protocol before page load, so this run does not claim a fresh automated direct-file execution. The structural single-file verifier and HTTP zero-external-request runtime both passed; direct-file visual acceptance remains available through the desktop browser.
- No ZIP, Git staging, commit, push, merge, rebase, or reset was performed.

## 14. 2026-08-23 Chapter 3.5 voice-memo selection, MiniMax synthesis, and runtime QA

### Puzzle and state contract

- The voice-memo page now presents seven recovered files, requires the player to audition and retain four, then moves to a separate ordering stage. The three decoys use canteen, theater, and library sound fields. The four authoritative evidence IDs and their stored order remain `lake → stone → lobby → broadcast`.
- Candidate-only decoy IDs stay outside `ChapterThreeInterludeState` and `SaveStore v25`. `submitVoiceSequence()` validates the complete seven-ID candidate domain and writes the canonical four-ID order only after an exact match. A decoy can no longer disappear during normalization and permit a false success.
- Quest, scene registry, and DEV checkpoint copy now describe seven-to-four selection without revealing the answer order. Wrong selection, wrong order, and accepted results use separate page feedback.

### Prompt and audio production

- Added `docs/plans/2026-08-23-chapter35-voice-memo-prompts.md` and `src/data/chapter3-interlude-voice-memos.audio.content.json`. The prompt contract preserves `English_Diligent_Man` for the player, `English_Graceful_Lady` for campus system announcements, and reuses the existing cleaner and guard takes where those characters appear.
- The authenticated `mmx 1.0.22` client generated four `speech-2.8-hd` dry voices. Final measured durations are `1997ms`, `4138ms`, `4310ms`, and `4485ms`. The first execution stopped safely on two narrow duration-budget misses; the checkpoint retained validated work, and only missing assets were requested after each budget correction.
- `scripts/generate-chapter3-interlude-voice-memos-audio.mjs` performs incremental synthesis, local FFmpeg mixing, MP3 decoding checks, configuration and component hashing, atomic replacement, checkpoint recovery, and a zero-network `--verify-only` path. It produced seven unique final recordings at `5200ms / 32000Hz / mono / 128kbps`.
- Final integrated loudness spans `-21.3` to `-19.0 LUFS`; true peak spans `-4.9` to `-2.4 dBFS`. Automatic encoding and level checks passed. Voice acting, pronunciation, and mix preference still require user audition before subjective approval.

### Runtime and verification

- `AudioDirector` accepts explicit asset-backed voice previews without story subtitles. A dedicated stop cue cancels scheduled Chapter 3.5 previews and pauses the current recording. Starting another clip, clicking the active clip, hiding the page, leaving the scene, or unmounting now stops the previous preview. P21 reads each real duration from the generated manifest.
- The first validator execution failed at the expected missing-manifest boundary. After generation, `audio:chapter3-interlude-voice-memos:verify` passed for `7` recordings, `4` correct clips, `3` decoys, `4` MiniMax dry voices, and `11` generated assets. A second generator verification reported `networkUsed=false`.
- `npm run typecheck`, `npm run build:single`, and `npm run verify:single` passed. The seven final MP3 byte streams are present as Base64 payloads in the single file. `demo/index.html` is `248256518` bytes with SHA-256 `b00c9d4454e6c20c5793e70099a1e2a7b1f96f9df5c9caebe0c455c6084c28b6`, two inline scripts, and one inline style.
- Chromium at `1280×720` confirmed mutually exclusive playback, exit-time pause, decoy-set rejection, correct-set wrong-order rejection, correct-order acceptance, and the resulting quest transition. At `390×844`, document dimensions matched the viewport and horizontal overflow was false. Console errors and warnings were zero; the only network entries were the three deliberate reloads of the self-contained `index.html`.
- The full `chapter4:validate-story` command currently fails on two unrelated existing Chapter 4 checks: Task 7 real player-foot/target geometry derivation and Task 10 `Space` interaction scope. This task did not modify those behaviors and does not claim that full gate as passing.
- Browser and HTTP sessions were closed. Five newly created Playwright artifacts were moved to `/Users/zhuhangcheng/.Trash/codex-ch35-qa-20260823-1949/`; older shared logs were preserved. No Git staging, commit, push, merge, rebase, reset, or upload was performed.

# Chapter 3.5 Evidence Recovery And Chapter 4 7:55 Unified Modification Plan

**Status:** The base repair path and optional details `A1 + A2 + A3 + B1 + B3 + C2` are approved for implementation.

**Goal:** Turn Chapter 3.5 and Chapter 4 into one coherent deduction and execution chain: evidence is gathered without early answer leakage, audio comparison is deterministic and accessible, Chapter 4 always explains its current time source and phase difference, and recurring instructions move from subtitles into the task system.

**Architecture:** React pages collect evidence and render presentation state. TypeScript controllers remain the only progression authority. New read-only selectors derive view models from existing state. MiniMax and audio-analysis scripts operate only in the asset pipeline. Phaser renders Chapter 4 and submits engine-neutral intents. The existing H3 gate remains the Chapter 3.5-to-4 handoff owner.

## Scope locks

- Preserve the existing Chapter 3.5 formal save fields, including `voiceClipOrder`, `timelineOrder`, `destinationId`, and the Chapter 4 entry contract.
- Keep unfinished recording selections in a versioned session draft store; do not add them to `GameState` or `SaveStore`.
- Keep every interaction facing-agnostic across all chapters.
- Do not add a new engine, runtime AI inference, or a second progression model.
- Do not generate a replacement for “灿若星辰”. Task 12 may only integrate the already-approved asset after its unique path or consumer ID is confirmed.
- Do not restore A1/A2/A3 collision, air-wall, walkability, or foreground-occlusion browser validation. Existing structural validators may continue to protect authored contracts.
- Generate `demo/index.html` only through `npm run build:single`; never edit it by hand.
- Optional detail scope is fixed to `A1 + A2 + A3 + B1 + B3 + C2`; unselected ideas remain out of scope.

## Acceptance baseline

- Chapter 3.5 starts with an unresolved time window and never displays the destination before the player earns the final choice.
- The final page auto-assembles recovered evidence and asks for one real location judgment; it does not repeat the A-D ordering exercise.
- Seven voice memos remain four true plus three decoys. Runtime grading uses exact authored IDs and order; waveform and event descriptions reflect the actual final MP3 files.
- Leaving and reopening the voice page in the same browser session restores audition, shortlist, and ordering work without changing the formal save schema.
- Chapter 4 derives one presentation object for all 13 phases and all 6 time states. The two `22:45` states always show different sources and trust states.
- Room 204 reports `n/12`, uses fixed slot occupancy, and exposes no direction or rotation rule.
- Repeated guidance appears in the task drawer. Local actions, item rejection, and authored dialogue keep separate output channels.
- The existing H3 playback and `requestId` handoff contract continue to work in the single-file build.

## Task 0: Freeze the live contracts before implementation

**Read:**

- `src/core/types.ts`
- `src/core/GameState.ts`
- `src/core/SaveStore.ts`
- `src/modules/ChapterThreePhoneInterludeController.ts`
- `src/modules/ChapterFourPrologueController.ts`
- `src/components/Chapter4PrologueRuntimeGate.tsx`
- `src/modules/ChapterFourTemporalMazeController.ts`
- `src/modules/ChapterFourClosureContract.ts`
- `src/modules/DeveloperChannel.ts`

**Actions:**

- Record the current Chapter 3.5 field contract, H3 event sequence, 13 phases, 6 time states, and closure gate.
- Resolve the unique repository path or official consumer ID for the existing “灿若星辰” asset. If it cannot be uniquely identified, Tasks 1-11 may proceed and Task 12 remains blocked.
- Preserve the currently validated `chapter35_recovered_replay_gate_requested -> requestId -> live_ready -> handoff_released` sequence.

## Task 1: Create one Chapter 3.5 content entry and one read-only selector

**Files:**

- Create: `src/data/chapter3InterludeContent.ts`
- Create: `src/modules/ChapterThreeInterludeModel.ts`
- Modify: `src/core/QuestModel.ts`
- Modify: `src/scenes/phone/P13_PhoneHome/index.tsx`

**Actions:**

- Import the existing voice content JSON and unify public evidence copy, validation IDs, destination candidates, decoy reasons, task copy, and hint levels behind one entry.
- Separate `publicContent`, `validationContract`, and `presentationCopy` so UI code cannot accidentally display solution-only fields.
- Add `selectChapterThreeInterludeViewModel(state)` with unresolved/resolved time window, evidence progress, network `n/3`, source summaries, auto timeline rows, destination eligibility, current objective, and hints.
- Derive the time window progressively: no start evidence shows `待恢复 — 待恢复`; CC98 restores the left boundary; the broadcast evidence restores the right boundary.
- Keep selectors read-only and leave all progression writes in `ChapterThreePhoneInterludeController`.

**Verification:**

- The phone home notification, quest drawer, and recovery page read the same derived time state.
- No public view model contains canonical destination or answer-order fields before eligibility.

## Task 2: Replace decorative recording data with an authored audio evidence model

**Files:**

- Modify: `src/data/chapter3-interlude-voice-memos.audio.content.json`
- Modify: `scripts/generate-chapter3-interlude-voice-memos-audio.mjs`
- Modify: `scripts/verify-chapter3-interlude-voice-memos.mjs`
- Modify: `docs/plans/2026-08-23-chapter35-voice-memo-prompts.md`

**Actions:**

- Keep seven clips, four canonical clips, three decoys, and the existing exact-order answer.
- Give every clip two to four authored `soundEvents` with start/end milliseconds, category, short Chinese label, and near/mid/far distance.
- Describe audible facts only. Do not expose `correct`, `decoy`, canonical rank, or the intended destination.
- Extract 32 RMS waveform bins from each final MP3 during generation and write them into the generated manifest. Remove the hard-coded eight-bar waveform from the page.
- Extend prompt data with event emphasis, distance, speech density, and decoy overlap while keeping MiniMax generation asset-side only.
- Treat a clip as heard after natural completion or at least 80% playback; clicking play alone does not unlock its event list.

**Verification:**

- `npm run audio:chapter3-interlude-voice-memos:verify`
- The validator checks seven unique final MP3 files, duration, waveform-bin count/range, event time bounds, four canonical IDs, and three decoy IDs.
- Human audition remains required to confirm that each authored event is actually audible.

## Task 3: Add session-level voice memo draft recovery

**Files:**

- Create: `src/modules/ChapterThreeInterludeDraftStore.ts`
- Modify: `src/scenes/phone/P21_VoiceMemos/index.tsx`
- Modify: `src/modules/ChapterThreePhoneInterludeController.ts`
- Modify: `src/styles/chapter-three-interlude.css`

**Actions:**

- Store only `stage`, `heardIds`, `selectedIds`, and `orderedIds` in versioned `sessionStorage`.
- Validate every restored ID against the current seven-candidate manifest, remove duplicates, and discard drafts when the manifest version changes.
- Keep playback time, currently playing clip, and feedback text runtime-only.
- Preserve the draft after wrong-set and wrong-order submissions. Clear it after a correct submission, story reset, or completed interlude.
- Keep formal `voiceClipOrder` unchanged and commit its four IDs only after successful controller validation.
- After a clip is heard, show event chips and allow short replay around an event marker without replaying the full 5.2-second clip.

**Verification:**

- Hear three clips, shortlist two, leave the page, and return: all three draft dimensions restore.
- Reload the same tab during ordering: order restores and no audio starts automatically.
- An old or malformed draft cannot inject unknown IDs or bypass validation.

## Task 4: Reduce answer leakage in photos, WeChat, and network evidence

**Files:**

- Modify: `src/scenes/phone/P18_Photos/index.tsx`
- Modify: `src/scenes/phone/P14_Wechat/index.tsx`
- Modify: `src/scenes/phone/P15_Zjuding/index.tsx`
- Modify: `src/core/QuestModel.ts`
- Modify: `src/styles/chapter-three-interlude.css`

**Actions:**

- Replace the photo task's explicit left/middle/right answer with three optional levels: discontinuity, fixed-reference comparison, then continuous horizontal movement.
- Make WeChat list previews neutral; reveal entrance direction and timing only after the player opens and saves the relevant messages.
- Build network filtering from an actual record collection. Each valid dimension narrows the current result set and updates `0/3`, `1/3`, `2/3`, or `3/3`.
- Derive network progress from the existing `officialNoticeSaved`, `routeScreenshotSaved`, and `networkRecordRead` facts.
- Hide the human-readable building resolution until final destination eligibility. AP identifiers may remain technical evidence only if they do not spell out the answer in visible copy.

**Verification:**

- A first-time player can state the next action but cannot quote the destination from a task hint, list preview, or initial record result.
- Every network filter has an observable effect before all three are correct.

## Task 5: Rebuild the Chapter 3.5 recovery and final deduction page

**Files:**

- Modify: `src/scenes/phone/P20_TimelineRecovery/index.tsx`
- Modify: `src/modules/ChapterThreePhoneInterludeController.ts`
- Modify: `src/styles/chapter-three-interlude.css`
- Modify: `src/modules/DeveloperChannel.ts`

**Actions:**

- Remove `timelineDraft`, A-D slots, and player-entered repetition of the evidence order.
- After all required facts and old-time exclusions are complete, have the controller write the canonical order into the existing `timelineOrder` and render a read-only four-row timeline.
- Keep the three old-time exclusions as the active reasoning task; they are not replaced by the auto timeline.
- Present four real candidates: Qizhen Lake dock, theater lobby, Basic Library south area, and Duan Yongping Building A1. Wrong candidates stay UI-local and never overwrite `destinationId`.
- Return one evidence conflict for each wrong location. Only the correct candidate writes the existing `destinationId: "duan_yongping_a1"`.
- Default completed evidence sections to a one-line summary with an explicit reopen control.
- Add one derived reasoning line that changes only when evidence meaning changes, such as unresolved time range, excessive candidate count, or one remaining conflict. Do not implement it as a subtitle.
- Update DEV checkpoints so intermediate evidence and final-choice states still seed real facts rather than a route-only page.

**Verification:**

- The destination does not appear in the heading before selection.
- The player performs one final location judgment and receives specific conflict feedback for all three wrong candidates.
- The current actionable block remains visible in the `430 x 860` phone viewport after completed sections collapse.

## Task 6: Delay RPG preload and preserve the H3 handoff

**Files:**

- Modify: `src/scenes/phone/P20_TimelineRecovery/index.tsx`
- Modify: `src/components/Chapter4PrologueRuntimeGate.tsx`
- Modify: `src/modules/DeveloperChannel.ts`
- Modify: `scripts/verify-chapter4-755-story.mjs`

**Actions:**

- Remove page-mount `preloadRpgGameHost()` from P20.
- Start preload only after the correct destination is confirmed and the player requests the recovered replay; keep the gate as the owner of loading, timeout, retry, and release.
- Preserve the current H3 source selection, task-card timing, request ID correlation, and A1 live-ready handshake.
- Give `c4-prologue-task-card` real reload semantics: an unconfirmed task card reloads to the task card; a confirmed task card resumes the A1 handoff. Do not silently normalize the unconfirmed checkpoint to `c4-755-opening`.

**Verification:**

- Opening P20 before final confirmation does not evaluate the RPG host.
- Chromium, Firefox, and WebKit keep H3 playback and automatic A1 handoff.
- Reload at the task card preserves the pending confirmation state; reload after confirmation safely restores A1.

## Task 7: Add one Chapter 4 stage-presentation selector

**Files:**

- Create: `src/modules/ChapterFourStagePresentation.ts`
- Modify: `src/data/chapter4-755.content.json`
- Modify: `src/data/chapter4-temporal-maze.content.json`
- Modify: `src/modules/ChapterFourTemporalMazeController.ts`
- Modify: `src/core/QuestModel.ts`

**Actions:**

- Derive stage label, time-state label, phone time, time source, trust state, floor, current difference, local progress, and confirmed facts from existing state.
- Cover all 13 phases and all 6 time states without adding a second phase graph.
- Distinguish the two `22:45` states in every consumer:
  - `现场 22:45 · 手机 07:55:23 未同步`;
  - `旧钟 22:45 · 维修时段 · 手机已同步`.
- Derive Room 204 progress from normalized placement count, light-grid progress from required zones only, and double-check-in progress from the two existing acceptance facts.
- Fix the controller event value `1850_room204` to the canonical `1850_evening`.

**Verification:**

- A selector-level validator proves unique presentation for 13 phases and 6 time states.
- The two `22:45` states differ by source, trust, and stage copy.

## Task 8: Move Chapter 4 guidance into the existing task drawer

**Files:**

- Modify: `src/data/chapter4-755.content.json`
- Modify: `src/core/types.ts`
- Modify: `src/core/QuestModel.ts`
- Modify: `src/components/QuestClueStrip.tsx`
- Modify: `src/styles/shell.css`

**Actions:**

- Replace each task's nullable single `hint` with `hints[]`; give each of the 28 active tasks three levels and leave the completed task without an action hint.
- Extend `QuestViewModel` with optional Chapter 4 presentation context only; do not add a persisted field.
- Keep the top bar compact: chapter, time state, floor, current objective, and local progress.
- Put current difference, confirmed facts, trust/source context, and the three reveal-on-request hints in the drawer.
- Reuse `QuestClueStrip`'s current progressive hint interaction and existing `.quest-task-overview` layout.
- Level 1 identifies the observation area, level 2 explains the rule, and level 3 states the exact accepted action. Future puzzle steps stay absent.

**Verification:**

- The drawer remains scrollable within the `960 x 540` RPG bounds at desktop and mobile scale.
- No locked future task label appears.
- Reopening the drawer does not repeat the hint as a subtitle.

## Task 9: Fix Room 204 progress and add specific failure details

**Files:**

- Modify: `src/scenes/rpg/ChapterFourRoom204Model.ts`
- Modify: `src/modules/ChapterFourTemporalMazeController.ts`
- Modify: `src/scenes/rpg/RpgInteractionContract.ts`
- Modify: `src/scenes/rpg/RpgGameHost.tsx`
- Modify: `src/data/chapter4-755.content.json`

**Actions:**

- Keep the existing 12 unique pieces, 12 unique slots, and fixed `up` compatibility metadata. Remove all player-facing direction and rotation wording.
- Display `复原 204：n/12` and derive it from the normalized placement collection. No new Room 204 save field is required.
- Preserve the existing coarse `reason` contract and add optional `detailCode` for locked prerequisites, occupied slots, already placed pieces, invalid routes, missing repairs, check-in requirements, and closure failures.
- Require every `locked` result to carry a detail code. Map details to one corrective action in content data; Host performs lookup only.
- Keep `wrong_mode`, `wrong_item`, `too_far`, `missed_target`, and `accepted` semantics unchanged.

**Verification:**

- Placement counts 0, 1, 6, 11, and 12 render correctly.
- Room 204 can be solved without reading or changing orientation.
- Every rejected item or interaction attempt produces one visible reason and one next action.

## Task 10: Assign each information channel one responsibility

**Files:**

- Modify: `src/scenes/rpg/ChapterFourTemporalMazeScene.ts`
- Modify: `src/scenes/rpg/RpgGameHost.tsx`
- Modify: `src/modules/PresentationDirector.ts`
- Modify: `src/data/chapter4-755.content.json`
- Modify: `src/data/chapter4-temporal-maze.content.json`

**Actions:**

- Top bar: stage, time, floor, objective, progress.
- Task drawer: difference, confirmed facts, optional hints.
- Phaser interaction hint: one nearby action accepted now.
- Inventory feedback: accepted or rejected item use and correction.
- Subtitle layer: dialogue, one-time transition, and major story result only.
- Remove repeated task titles, control tutorials, and route reminders from subtitles.
- Change A3 reference copy from direction language to `303 的 12 组参照位置已经记录`.
- Keep guard chase dialogue, time-transition results, final-minute recovery, and official exterior-closure result.

**Verification:**

- No instruction is simultaneously visible in task bar, subtitle, and item feedback.
- A critical failure never ends without a correction path.

## Task 11: Normalize Chapter 4 DEV checkpoints

**Files:**

- Modify: `src/modules/DeveloperChannel.ts`
- Modify: `scripts/verify-chapter4-755-story.mjs`
- Modify: `scripts/verify-chapter4-755-runtime.mjs`

**Actions:**

- Merge the duplicate blackout and light-grid seeds under canonical `c4-755-blackout-0754`; retain `c4-755-light-grid` as a compatibility alias.
- Add canonical `c4-755-return-clock` for `return_to_clock` with the final minute, attendance paper, and campus card.
- Rename the pre-consumer ending checkpoint to `c4-755-closure` and reserve `c4-755-result` for a verified completed state.
- Keep DEV seeds session-only and prevent them from writing the formal save.

**Verification:**

- Every canonical node seeds a real gameplay checkpoint with matching phase, floor, room, items, and facts.
- Legacy URLs resolve without changing their former gameplay meaning.

## Task 12: Integrate the existing “灿若星辰” consumer and persist verified completion

**Files:**

- Modify: `src/modules/ChapterFourClosureContract.ts`
- Create: `src/modules/ChapterFourClosureSessionRegistry.ts`
- Modify: `src/modules/ChapterFourTemporalMazeController.ts`
- Modify: `src/scenes/rpg/RpgGameHost.tsx`
- Modify: the confirmed official “灿若星辰” consumer
- Modify: `src/core/SaveStore.ts`

**Actions:**

- Use only the confirmed official asset reference and consumer. Do not accept an old Godot asset, placeholder, or generated substitute.
- Start a runtime closure session, accept one completion event from the official consumer, validate the proof once, and then write the existing `complete`, `completed`, `exteriorClosureAcknowledged`, and closure fact fields atomically.
- Keep session IDs and proof runtime-only. Add no new `GameState` field.
- If the current save sanitizer still downgrades every completed Chapter 4 state, bump the save envelope version while preserving v25 in-progress phases. Only a complete state with all existing closure facts may survive reload.
- Treat missing reference, wrong reference, incomplete session, and reused proof as zero-write failures with specific detail codes.

**Verification:**

- The official consumer completes once, refreshes to the result state, and cannot be replayed to duplicate completion.
- v24 legacy completion remains safely downgraded; v25 in-progress Chapter 4 saves remain intact; the new verified completion survives reload.

## Task 13: Apply the approved optional interaction details

**Files:**

- Modify: `src/scenes/phone/P20_TimelineRecovery/index.tsx`
- Modify: `src/scenes/phone/P21_VoiceMemos/index.tsx`
- Modify: `src/data/chapter3-interlude-voice-memos.audio.content.json`
- Modify: `src/data/chapter4-755.content.json`
- Modify: `src/data/chapter4-temporal-maze.content.json`
- Modify: `src/scenes/rpg/ChapterFourTemporalMazeScene.ts`
- Modify: `src/scenes/rpg/FinaleNpcTextures.ts` only if the existing cleaner atlas needs an additional fixed-frame animation mapping.

**Actions:**

- `A1`: unlock short replay around authored voice-event markers after a clip reaches the heard threshold.
- `A2`: return one specific contradiction for an incorrect voice set or destination candidate.
- `A3`: restore the time-window digits independently as the start and end evidence becomes valid.
- `B1`: on each authored Chapter 4 return visit, change at least one already-known door, notice, NPC placement, or evidence state through the phase presentation data.
- `B3`: change the cleaner cart from a blocked-wheel sound to a short free-roll sound after repair, and change the hall clock from an unstable tick to a stable tick after gear repair.
- `C2`: show the cleaner attempting and failing to move the cart before repair, then moving it a short authored distance after repair.
- Keep each detail independent of base progression, formal save migration, and required collision geometry.
- Do not create generic feature flags for unselected ideas.

**Verification:**

- Disabling or removing one optional detail leaves the base puzzle solvable and state-compatible.

## Task 14: Update deterministic validators

**Files:**

- Modify: `scripts/verify-chapter3-interlude-voice-memos.mjs`
- Modify: `scripts/verify-chapter4-755-story.mjs`
- Modify: `scripts/verify-chapter4-755-runtime.mjs`
- Modify: `scripts/verify-chapter4-755-task14.mjs`
- Modify: `src/scenes/rpg/RpgRuntimeDebug.ts`

**Actions:**

- Validate Chapter 3.5 public/solution separation, waveform/event metadata, draft sanitization, automatic timeline, and location write rules.
- Validate 13 Chapter 4 phase presentations, 6 time-state labels, two distinct `22:45` contexts, 28 three-level hint arrays, 204 progress, locked detail codes, DEV aliases, and closure proof behavior.
- Add negative checks for direction gates, duplicate subtitle ownership, early destination copy, and page-mount RPG preload.
- Keep A1/A2/A3 collision and foreground-occlusion browser checks outside this task.

**Verification:**

- `npm run typecheck`
- `npm run audio:chapter3-interlude-voice-memos:verify`
- `npm run chapter4:validate-topology`
- `npm run chapter4:validate-runtime`
- `npm run chapter4:validate-story`
- `npm run chapter4:validate-task14`

## Task 15: Run the integrated browser path

**Checks:**

- Chapter 3.5: photo, seven recordings, WeChat, progressive network filtering, old-time exclusions, automatic timeline, four location candidates, and draft reload.
- Transition: recovered replay, H3 natural end, H3 skip, pending task-card reload, confirmed task-card reload, and automatic A1 release.
- Chapter 4: six time-state presentations, both `22:45` labels, 204 `n/12`, progressive hints, representative prerequisite failures, final-minute return, double check-in, official closure, and result reload.
- Viewports: `1280 x 720`, one non-16:9 desktop viewport, and `390 x 844`.
- Engines: Blink, Gecko, and WebKit according to the project compatibility baseline.
- Pass criteria: no document overflow, stable phone/RPG ratios, no page or console errors, no duplicate guidance channels, and no route blocked by removal of a subtitle.

**Explicit exclusion:**

- Do not run three-floor collision, air-wall, walkability, source-coordinate, or foreground-occlusion browser validation.

## Task 16: Build and record the demo only after the path passes

**Files:**

- Modify: `progress.md`
- Generated: `demo/index.html`

**Actions:**

- Record implemented scope, selected optional detail IDs, validators, browser paths, exclusions, and any remaining visual-approval boundary in `progress.md`.
- Run `npm run build:single` and `npm run verify:single` only after Tasks 14 and 15 pass.
- Report final file size and SHA-256.
- Do not stage, commit, merge, or push in this task; Git delivery requires the separate fetch-and-scope procedure in the project rules.

## Optional detail decision

- Approved: `A1 + A2 + A3 + B1 + B3 + C2`.
- Excluded from this implementation: `A4`, `A5`, `B2`, `B4`, `C1`, `C3`, and `C4`.

# 全通关后“7:55 挑战”无尽小游戏中心实施计划

> 计划日期：2026-08-24
>
> 当前状态：Task 0–13 已实施；自动合同、三模式等效 30 分钟长测、Blink/Gecko/WebKit 真实浏览器验收、生产构建、离线单文件构建及 HTTP/`file://` 单文件复验均已完成。Git 上传仍受 fetch 后精确范围确认门约束。
>
> 用户目标：主线正式通关后，保留手机桌面现有 `7:55` 图标，以一个统一入口提供节奏钓鱼、灯光追逐、755 米自行车三种无尽挑战。

## 1. 结论与产品边界

采用以下产品形态：

- 手机桌面继续使用现有 `bike_arcade` 槽位、`7:55` 图标、`游戏` 名称和原网格位置。
- 打开后进入 `7:55 挑战` 中心，不再直接进入旧版固定 755 米骑行。
- 三个模式均采用“持续提高难度，失败后结算”的单局结构。
- “无尽”表示关卡层级和分数可以持续增长，单局仍然具有明确失败、结算、重试和退出。
- 生产环境仅在经过第四章正式收束验证并写入持久通关回执后开放。
- 开发环境通过 session-only 检查点验证玩法，不写正式存档，也不代替生产解锁。
- 第一版仅保存本地个人最佳成绩，不增加账号、联网排行榜、每日任务、货币、奖励和剧情分支。
- 第一版复用现有美术、音频、交互规则和 Phaser；不增加新引擎，不生成新角色或视频。
- 旧 `bikeArcade` 第三章存档保留兼容用途，不能继续充当通关权限或新模式成绩权威。

推荐的用户可见结构：

```text
手机桌面
└── 7:55 图标（名称继续显示“游戏”）
    └── 7:55 挑战
        ├── 节奏钓鱼
        ├── 灯光追逐
        └── 755 米骑行
```

## 2. 当前代码证据与复用决定

### 2.1 现有入口可以直接升级

- `src/core/types.ts` 已包含 `SceneId = "bike_arcade"` 和 `PhoneHomeAppId = "bike_arcade"`。
- `src/core/PhoneHomeApps.ts` 已把 `bike_arcade` 放入默认桌面顺序。
- `src/scenes/phone/P13_PhoneHome/index.tsx` 已显示 `7:55` 图标，并在开放时进入 `bike_arcade`。
- `src/core/SceneRouter.ts` 和 `src/core/FeatureAccess.ts` 已对该场景执行二次权限检查。
- `src/scenes/phone/registry.tsx` 已登记 P16 场景。
- `src/scenes/phone/P16_BikeArcade/index.tsx` 已具备竖屏 Phaser 加载、启动失败提示和销毁路径。

因此，第一版不新增应用 ID、场景 ID、桌面排序项和单文件加载入口。内部名称 `bike_arcade` 作为兼容标识保留，用户界面统一使用 `7:55 挑战`。

### 2.2 三种玩法已有可靠基础

节奏钓鱼：

- `src/scenes/rpg/QizhenFishingRhythmModel.ts` 已提供单调时钟、判定窗、长按、连击、张力和失败持续时间。
- `src/data/chapter3-qizhen-fishing.charts.json` 已有四组可用节奏母题。
- `src/scenes/rpg/QizhenLakeScene.ts` 已处理 AudioContext 时钟、节拍预调度、输入释放、页面隐藏和场景清理。
- 原 960×540 世界坐标视觉不可直接塞入手机页，需要建立 390×650 竖屏视觉层。

灯光追逐：

- `src/scenes/rpg/TheaterSpotlightModel.ts` 已提供目标路径、预览时间、光束半径、锁定时间、干扰目标和辅助参数。
- `src/scenes/rpg/TheaterInteriorScene.ts` 已实现路径预览、目标和干扰目标移动、光束覆盖、连续锁定以及提前、延后、中断反馈。
- `src/modules/ChapterThreeTheaterController.ts` 中的判定需要提取为可复用纯函数，并保留原剧情关卡回归结果。
- 第四章灯阵和楼梯追逐不属于本模式来源，不能混入此模式规则。

755 米骑行：

- `src/scenes/phone/P16_BikeArcade/BikeArcadeRules.ts` 已提供三车道、可解波次、速度和难度计算。
- `src/scenes/phone/P16_BikeArcade/BikeArcadeRuntime.ts` 已提供暂停原因、恢复首帧丢弃和 delta 上限。
- `src/scenes/phone/P16_BikeArcade/BikeRushScene.ts` 已适配 390×650、键盘、触屏、碰撞、无敌时间和 Phaser 生命周期。
- 原控制器以 755 米作为剧情终点；无尽模式需要把每 755 米改为一圈，并继续下一圈。

### 2.3 现有通关状态无法直接持久开放入口

当前第四章正式结束事务会在验证成功后写入：

```text
chapter4.phase = complete
chapter4.completed = true
chapter4.exteriorClosureAcknowledged = true
factIds += exterior_closure_acknowledged
```

但 `SaveStore` 为防止伪造 consumer proof，会在重新加载时把裸 `complete` 状态降回 `exterior_closure`。如果权限直接读取 `chapter4.completed`，当前会话中图标开放，刷新后会再次锁定。

同时，现有 `bikeArcade.unlocked` 曾用于第三章旧小游戏和 022 座位迁移。使用它会让部分旧存档提前开放通关内容。

本计划新增“正式结局回执”。它只在第四章 controller 已完成素材引用和 consumer session 双重验证后写入，可独立持久恢复。

## 3. 范围锁定

### 3.1 第一版必须完成

- 正式通关回执与持久解锁。
- 桌面固定 7:55 图标和统一挑战中心。
- 三种可完整游玩的无尽模式。
- 键盘与触屏输入。
- 暂停、显式恢复、失败结算、立即重试、返回中心、返回手机主页。
- 三模式独立个人最佳记录。
- 旧存档迁移与原剧情玩法回归保护。
- 开发检查点、文本快照、确定性种子和浏览器验证。
- Vite、直接打开的单文件、桌面和移动视口行为一致。

### 3.2 第一版明确排除

- 在线排行榜、好友排行和账号系统。
- 每日挑战、赛季、体力、货币、奖励商店和成就系统。
- 新剧情、通关奖励物品和主线状态回写。
- 新联网请求、遥测和云存档。
- 新美术批量生成、新语音和新视频。
- Three.js、Godot 或其他新运行时。
- 把一局进行中的障碍、音符、目标位置和按键状态写入存档。
- 为三个模式各自建立一套手机外框或全局导航。

### 3.3 前置依赖

生产解锁依赖第四章正式收束合同真实接通：

- `CHAPTER_FOUR_APPROVED_CLOSURE_REFERENCE` 必须登记已制作的“灿若星辰”正式素材与 consumer。
- 实际播放 consumer 必须生成一次性完成证明。
- 处理最终 intent 的 controller 必须持有真实 verifier。
- 只有 verifier 成功的事务可写 `chapter4_closure_v1` 回执。

无尽挑战主体可以先通过开发检查点实现和验证。正式入口在上述依赖完成前维持静态锁定槽位。

## 4. 目标架构

### 4.1 数据流

```text
第四章正式 consumer 播放完成
  │
  ├─ 素材引用匹配
  └─ session verifier 通过
       │
       ▼
ChapterFourTemporalMazeController
  ├─ 写 chapter4 完成事实
  ├─ 写 postgame.completionReceipt
  └─ 返回 phone_home
       │
       ▼
selectMainStoryCompleted
       │
       ▼
FeatureAccess.endlessChallenge
       │
       ▼
手机桌面 7:55 固定槽位
       │
       ▼
P16 “7:55 挑战”中心
       │
       ▼
EndlessArcadeGameHost（一次只挂载一个 Phaser 实例）
  ├─ EndlessFishingScene
  ├─ EndlessSpotlightScene
  └─ BikeRushScene(mode = endless)
       │
       ▼
EndlessArcadeController.settleAttempt(runId, summary)
       │
       ▼
GameState.endlessArcade.records
       │
       ▼
SaveStore
```

### 4.2 页面状态机

```text
locked
  └─ 通关回执生效 → hub

hub
  └─ 选择模式 → loading → intro → running

running
  ├─ 页面隐藏 / 失焦 / 控制中心打开 → paused
  ├─ 主动退出 → confirm_exit → cancelled → hub
  └─ 失败 → game_over

paused
  ├─ 玩家点击继续 → running
  └─ 退出 → cancelled → hub

game_over
  ├─ 再来一局 → intro → running
  ├─ 返回挑战中心 → hub
  └─ 返回手机主页 → phone_home
```

### 4.3 分层职责

`FeatureAccess`：

- 只回答正式通关内容是否可进入。
- 不读取旧 `bikeArcade.unlocked`。
- `SceneRouter`、首页卡片和 P16 内部防护使用同一 selector。

`P16_BikeArcade`：

- 管理挑战中心、模式说明、最佳记录、加载态、错误态和结算面板。
- 使用共享 Phone UI 组件，不改变 430×860 外框。
- 不直接修改全局剧情字段。

`EndlessArcadeGameHost`：

- 在一个 390×650 逻辑区域挂载一个 Phaser canvas。
- 懒加载 Phaser 和当前模式 scene。
- 统一 pause、resume、blur、visibilitychange、Pointer Events、启动超时、错误恢复和 teardown。
- 切换模式前销毁旧实例，不保留第二个活动 canvas。

三种 scene：

- 只维护当前局运行态。
- 通过结构化 summary 报告结算。
- 不访问 `GameStore`，不写存档，不发送剧情完成事件。

`EndlessArcadeController`：

- 生成 run ID 和确定性种子。
- 每次开局只增加一次 attempt count。
- 每个 run ID 只接受一次结算。
- 校验 mode、分数、进度、连击、层级和时长。
- 只更新对应模式最佳记录。

## 5. 状态、存档与迁移合同

### 5.1 新状态

在 `src/core/types.ts` 增加：

```ts
export type MainStoryCompletionReceipt = "chapter4_closure_v1" | null;

export type EndlessChallengeModeId =
  | "fishing"
  | "spotlight"
  | "bike";

export interface EndlessChallengeRecord {
  attemptCount: number;
  bestScore: number;
  bestProgress: number;
  bestTier: number;
  bestCombo: number;
  bestDurationMs: number;
}

export interface PostgameState {
  completionReceipt: MainStoryCompletionReceipt;
}

export interface EndlessArcadeState {
  records: Record<EndlessChallengeModeId, EndlessChallengeRecord>;
}
```

`bestProgress` 的单位由模式注册表解释：

- `fishing`：成功收线次数。
- `spotlight`：完成轮数。
- `bike`：累计米数。

`bestTier` 用于三个模式统一显示难度层级。所有数值归一化为安全、非负、有限整数，并设置实现常量上限，防止异常存档或超长运行溢出。

### 5.2 正式解锁 selector

建议新增：

```ts
export function selectMainStoryCompleted(state: GameState): boolean {
  return state.postgame.completionReceipt === "chapter4_closure_v1";
}
```

`selectFeatureAccess()` 增加：

```ts
endlessChallenge: selectMainStoryCompleted(state)
```

`canEnterScene("bike_arcade")`、P13 可用状态和 P16 内部防护统一读取 `endlessChallenge`。

禁止从以下字段推导正式回执：

- `chapter4.phase`
- `chapter4.completed`
- `chapter4.exteriorClosureAcknowledged`
- `chapter4.factIds`
- `bikeArcade.unlocked`
- `bikeArcade.completed`
- `flags.checkinDone`
- `currentScene === "ending"`

### 5.3 回执写入事务

`ChapterFourTemporalMazeController` 只有在以下两项均通过后写回执：

```text
closureProofMatchesReference(...)
closureSessionVerifier.verifyCompletedSession(...)
```

同一个 store transaction 写入：

```text
chapter4.phase = complete
chapter4.completed = true
chapter4.exteriorClosureAcknowledged = true
chapter4.factIds += exterior_closure_acknowledged
postgame.completionReceipt = chapter4_closure_v1
runtimeMode = phone
currentScene = phone_home
ui.controlCenterOpen = false
ui.inventoryOpen = false
ui.selectedItem = null
```

该事务发生在最终 consumer 播放完成并提交 acknowledgement 之后，避免提前返回手机主页。

### 5.4 SaveStore 版本与迁移

实施时建议把整体 `SAVE_VERSION` 从 25 提升到 26，同时固定已有第四章迁移阈值：

```ts
const CHAPTER_FOUR_755_SAVE_VERSION = 25;
const POSTGAME_ENDLESS_SAVE_VERSION = 26;
```

必须先把 `normalizeChapterFour()` 中跟随当前 `SAVE_VERSION` 的旧架构判断改为固定阈值，再提升整体版本。否则全部 v25 第四章进行中存档会被再次判旧并重置。

`isLegacyChapterThreeState()` 当前仅凭 `currentScene === "bike_arcade"` 就会触发旧第三章修复。该判断需要受旧版本阈值约束，或改为检查旧结构特征。否则新 postgame 页面刷新时可能改写第三章图书馆状态。

迁移规则：

- v25 及更早存档默认 `postgame.completionReceipt = null`。
- 旧字段不能自动生成正式回执。
- 新回执存在时，恢复 canonical Chapter 4 complete 状态和手机主页或 `bike_arcade`。
- 非法回执值归一化为 `null`。
- 新 `endlessArcade` 缺失时生成三个零值记录。
- 仅当新 `endlessArcade` 整体缺失时，可把旧自行车数据作为“历史成绩种子”：
  - `bike.attemptCount = legacy attemptCount`
  - `bike.bestProgress = legacy bestDistance`
  - `bike.bestScore = legacy bestDistance`
  - 其他值为 0
- 上述成绩迁移不产生正式解锁。
- 正式入口改为不可从桌面删除；归一化时从 `hiddenHomeAppIds` 移除 `bike_arcade`。

### 5.5 当前局保持运行时状态

以下内容不写存档：

- run ID、随机种子、当前分数、当前层级和当前生命。
- 音符、障碍、目标、干扰目标、粒子和计时器。
- 当前按键、触点、拖动、光束和暂停原因。
- 结局 consumer 的 session ID 与 completion event ID。

刷新活动局时返回挑战中心。未结算的局不更新最佳记录；attempt count 保留已经开始这一事实。

## 6. 统一挑战中心与交互合同

### 6.1 挑战中心

使用 `PhoneAppScaffold`、`PhoneAppHeader`、`PhoneStateView` 和现有手机 token，提供：

- 标题：`7:55 挑战`。
- 一行说明：`选择一个玩法，坚持到失误为止。`。
- 三张模式卡：名称、短规则、控制方式、最佳成绩和开始按钮。
- 本地成绩说明：`成绩仅保存在本机。`。
- 返回手机主页按钮。

视觉统一延续现有图标：

- 页头保留分段数字形式的 `07:55`，它只作为品牌标识，不伪装成系统当前时间。
- 三张卡使用同一排版和状态结构，通过节奏轨道、圆形光束、三车道线三种简化底纹区分玩法。
- 分数、层级和个人最佳统一采用数字表盘字形；正文、按钮和错误反馈继续使用全局 Phone UI 字体与 token。
- 新纪录只在本次结算面板显示一次短动画；降低动态效果时改成静态高亮。
- 挑战中心不加入装饰性横幅、自动轮播和第二套底部导航。

模式卡保持相同层级：

```text
节奏钓鱼
跟准节拍，控制张力
最佳：12 次收线 · 38,420 分

灯光追逐
预判路线，持续锁定目标
最佳：18 轮 · 46,700 分

755 米骑行
每 755 米进入下一圈
最佳：3,284 米 · 52,100 分
```

### 6.2 游戏内固定结构

每个模式都提供：

- 顶部：模式名、分数、进度或层级。
- 中部：Phaser 游戏区。
- 底部：触屏控制区；细指针桌面不显示虚拟按键。
- 首次进入：一屏内完成的简短玩法说明和开始按钮。
- 暂停：清楚显示暂停原因和“继续”。
- 结算：分数、进度、最高连击、新纪录状态、重试、返回中心、返回主页。

进入活动局后隐藏全局剧情任务抽屉和物品栏，保留共享状态栏。挑战中心可使用控制中心；活动局打开控制中心时先暂停，关闭后等待玩家显式恢复。

### 6.3 退出与恢复

- 活动局点击返回时显示行内确认：`退出本局？本局成绩不会结算。`
- `visibilitychange`、窗口失焦、控制中心打开和系统中断均暂停。
- 所有活动输入在暂停时清空。
- 页面重新可见后不自动继续，避免后台时间造成误判。
- pointer capture 丢失、`pointercancel` 和键盘 `keyup` 都必须释放对应输入。

## 7. 模式一：节奏钓鱼

### 7.1 核心循环

```text
4 小节倒计时
  → 音符进入判定线
  → 玩家按 J / K / L 或三个触屏按钮
  → 判定 Perfect / Good / Miss
  → 更新连击、分数和张力
  → 完成一个段落并成功收线
  → 难度提高并生成下一段
  → 张力越界持续达到失败阈值后结算
```

### 7.2 规则复用

- 把 `QizhenFishingRhythmModel.ts` 中与故事 chart ID 解耦的判定、长按、张力和评分提取到 `src/modules/RhythmFishingEngine.ts`。
- 原剧情 model 保持现有公开 API，通过适配层调用共享 engine。
- 新 `EndlessFishingRules.ts` 负责确定性段落生成、难度层级和计分。
- 原四张剧情谱面的相同输入必须产生完全相同的判定结果，作为回归门槛。

### 7.3 难度曲线

- 起始 BPM：96。
- BPM 逐层提高，第一版上限建议 144。
- 初期使用较少音符和短 hold；后续增加密度、交替型、连续同轨和长按组合。
- 判定窗沿用 70/130/190ms 基线，可在高层级有限收紧；最小窗保留可操作下限。
- 前两层使用宽松张力变化，先让玩家理解按键与判定线。
- 每完成一个完整段落记一次“收线成功”，作为 `bestProgress`。
- 张力达到边界后保留短暂修正时间，持续超限才失败。

### 7.4 计分

```text
基础判定分
× 连击系数
× 当前层级系数
+ 完整段落奖励
+ 无 Miss 段落奖励
```

分数、连击和层级均采用饱和安全整数。分数计算只使用单调游戏时钟，不读取 `Date.now()`。

### 7.5 输入与视觉

- 桌面：`A`、`S`、`D` 三轨。
- 触屏：底部三个大按钮，按下、保持、释放均可见。
- 竖屏画面使用固定判定线，音符向判定线移动，张力条始终可见。
- `prefers-reduced-motion` 降低镜头、粒子和缩放动画，不改变音符时间和判定。
- 音频不可用时继续使用可见节拍闪烁和倒计时，玩法仍可完成。

### 7.6 长局资源限制

- 仅保留当前段、下一段和短历史窗口。
- 已结束音符及时删除，不积累整局 chart。
- 同时活动音符数量设置上限。
- 粒子池建议不超过 64。

## 8. 模式二：灯光追逐

### 8.1 核心循环

```text
显示目标路线预览
  → 预览消失
  → 目标与干扰目标移动
  → 玩家左右瞄准
  → 按住照射键持续覆盖真实目标
  → 达到锁定时间后完成一轮
  → 提高难度并开始下一轮
  → 提前照射、照错目标或锁定中断消耗电量
  → 电量耗尽后结算
```

### 8.2 规则复用

- 从 `TheaterSpotlightModel.ts` 和 `ChapterThreeTheaterController.ts` 提取纯判定器。
- 原剧院关卡继续调用该判定器，并通过固定用例证明结果未变。
- `EndlessSpotlightRules.ts` 负责基于 seed 生成目标路径、干扰路径、预览时长、光束半径和锁定时间。
- 事件名使用 `endless_spotlight_*`，避免触发第三章剧情监听器。

### 8.3 难度曲线

- 初始 3 格电量。
- 前两轮只有一个真实目标，不生成干扰目标。
- 随层级缩短预览和操作时间、减小光束半径、增加锁定时间、提高目标速度。
- 中层级开始加入一个干扰目标；高层级可提高到两个，但保持路径可读。
- 所有参数设置可解上限，不允许预览时间、光束半径或锁定窗口降到输入基线以下。
- 每完成一轮增加 `bestProgress`；连续无损完成形成 combo。

### 8.4 输入与视觉

- 桌面：`A/D` 或左右方向键移动光束，`Space` 按住照射。
- 触屏：底部横向滑轨控制光束位置，一个大按钮控制照射。
- 路线预览、行动阶段、已锁定比例和剩余电量分区显示。
- 真实目标和干扰目标使用现有剧院资产与颜色规则，不能依靠文字直接标答案。
- 照错目标时给出短反馈并消耗电量，不把完整路线重新展示。

### 8.5 长局资源限制

- 每轮只保留本轮路径点、目标和最多两个干扰目标。
- 轮次结束立即销毁 tween、timer、pointer listener 和显示对象。
- 路径点数量与 spline 采样数设置上限。

## 9. 模式三：755 米骑行

### 9.1 核心循环

```text
三车道骑行
  → 左右换道避开障碍
  → 近距离避让获得加分
  → 每前进 755 米完成一圈
  → 提高速度和波次难度
  → 继续下一圈
  → 生命耗尽后结算
```

### 9.2 规则复用

- `BikeArcadeRules.ts` 增加配置对象和确定性 seed，默认配置继续保持原剧情 755 米结果。
- `BikeRushScene.ts` 接受 `mode: "story" | "endless"`。
- `story` 模式仍在 755 米结束，并继续使用旧 controller 合同。
- `endless` 模式每 755 米只增加圈数和难度，不发出剧情胜利事件。
- `BikeArcadeRuntime.ts` 的暂停、delta 限制和恢复首帧处理继续复用。

### 9.3 难度曲线

- 第 1 圈接近原剧情关卡中段难度。
- 每圈提高基础速度、障碍密度和组合复杂度。
- 波次生成器始终保留至少一条可通过车道。
- 速度、生成间隔和并行障碍数设置安全上限。
- 难度达到上限后通过波次组合和分数倍率继续增长，不再压缩到不可解输入窗口。

### 9.4 计分与进度

- `bestProgress` 记录全局累计米数，不在 755 截断。
- 圈数显示为 `floor(distance / 755)`，当前圈进度显示余数。
- 计分包含距离、圈数、近距离避让、连续无碰撞和层级倍率。
- 碰撞扣生命并进入短暂无敌；生命耗尽结算。

### 9.5 输入与资源限制

- 桌面：`A/D` 或左右方向键。
- 触屏：左、右两个按钮；细指针桌面不渲染虚拟按钮。
- 同时活动障碍建议不超过 18。
- 离屏障碍立即回收；粒子、提示和近失记录使用固定上限。
- scene 在 `shutdown` 与 `destroy` 两条路径都清理 bridge、键盘和 pointer 订阅。

## 10. 确定性、结算与调试合同

### 10.1 开局

`EndlessArcadeController.startAttempt(mode)`：

- 校验正式权限或 session-only 开发权限。
- 增加该模式 `attemptCount`。
- 生成 runtime-only `runId`。
- 用 `mode + attemptCount + 固定版本盐` 派生 seed。
- 返回 `{runId, mode, seed}`。

### 10.2 结算

`settleAttempt(runId, summary)`：

- 只接受仍活动且未结算的 run ID。
- 校验 summary 的 mode 与开局 mode 一致。
- 拒绝 NaN、Infinity、负数、越界数值和未知字段。
- 对数值取整并执行模式上限检查。
- 更新最佳分数、进度、层级、连击和时长。
- 同一个 run ID 的重复回调无副作用。

`cancelAttempt(runId)`：

- 清除活动 run。
- 不更新最佳成绩。
- 不回滚已经增加的 attempt count。

### 10.3 文本调试快照

`render_game_to_text()` 在挑战中心和活动局至少暴露：

```json
{
  "scene": "bike_arcade",
  "endlessArcade": {
    "access": true,
    "completionReceipt": "chapter4_closure_v1",
    "view": "running",
    "mode": "fishing",
    "runId": "runtime-only",
    "seed": 123456,
    "score": 7200,
    "progress": 4,
    "tier": 3,
    "combo": 18,
    "paused": false,
    "failureReason": null
  }
}
```

生产保存数据不包含 `runId` 和 `seed`。文本快照只供验证使用。

### 10.4 开发检查点

新增 session-only 检查点：

- `postgame-arcade-locked`：第四章外景等待，图标保持锁定。
- `postgame-arcade-hub`：正式回执已注入，打开挑战中心。
- `postgame-arcade-fishing`：节奏钓鱼第 1 层。
- `postgame-arcade-fishing-high`：高层级、张力接近边界。
- `postgame-arcade-spotlight`：灯光追逐第 1 轮。
- `postgame-arcade-spotlight-high`：高层级、剩余 1 格电量。
- `postgame-arcade-bike`：骑行第 1 圈。
- `postgame-arcade-bike-lap3`：骑行第 3 圈中段。

`verify-chapter4-755-task14.mjs` 当前把第四章 gameplay checkpoint 统一要求为 RPG。postgame 检查点需要独立 `POSTGAME_IDS` 分组，避免套用 temporal maze 的 stage presentation 条件。

## 11. 详细执行任务

### Task 0：冻结基线并建立验证入口

**读取：**

- `project-development-report.md`
- `progress.md`
- `package.json`
- `.github/workflows/web-ci.yml`
- 当前相关 validator

**新增：**

- `scripts/verify-endless-arcade.mjs`

**修改：**

- `package.json`

**动作：**

- 登记 `npm run endless:validate`。
- 先写失败断言，覆盖状态默认值、通关回执、旧存档不误解锁、三模式注册、确定性 seed、重复结算和资源上限常量。
- 记录当前原剧情 validator 的通过基线。

**通过条件：**

- 新 validator 在实现前按预期失败。
- 现有相关 validator 的基线结果已记录。

### Task 1：正式通关回执与 SaveStore 迁移

**修改：**

- `src/core/types.ts`
- `src/core/GameState.ts`
- `src/core/SaveStore.ts`
- `src/core/FeatureAccess.ts`
- `src/modules/ChapterFourTemporalMazeController.ts`

**动作：**

- 增加 `PostgameState`、`EndlessArcadeState` 和默认值。
- 增加 `selectMainStoryCompleted()` 与 `FeatureAccess.endlessChallenge`。
- 固定 Chapter 4 迁移阈值，再提升存档版本。
- 限定 `bike_arcade` 的旧第三章 scene 推断版本。
- verifier 成功事务中原子写正式回执。
- 新回执恢复 canonical complete；旧字段不生成回执。

**验证：**

- 默认新游戏锁定。
- v25 第四章进行中存档不重置。
- 伪造的裸 complete 仍不能解锁。
- 合法回执刷新后继续解锁。
- 旧 `bikeArcade.unlocked` 不解锁 postgame。

### Task 2：固定桌面入口和三层权限防护

**修改：**

- `src/core/PhoneHomeApps.ts`
- `src/scenes/phone/P13_PhoneHome/index.tsx`
- `src/scenes/phone/P16_BikeArcade/index.tsx`
- `src/core/SceneRouter.ts`（仅在现有映射无法复用时修改）

**动作：**

- 让 `bike_arcade` 槽位不可删除。
- 归一化旧 `hiddenHomeAppIds` 时移除该 ID。
- 首页、router 和 P16 使用同一 `endlessChallenge` 权限。
- 保留 `7:55` 图标、`游戏` 名称、网格位置和锁定时的静态语义。
- 删除 P16 中“022 座位后开放”“第三章完成”“继续下一章”等旧文案和路由。

**验证：**

- 锁定时无 button、焦点、click 和 toast。
- 解锁时原槽位转为可操作入口。
- URL 或直接 scene 写入无法绕过权限。
- 旧隐藏状态不会让正式通关入口消失。

### Task 3：挑战中心、统一宿主和模式注册表

**新增：**

- `src/scenes/phone/P16_BikeArcade/EndlessArcadeGameHost.tsx`
- `src/scenes/phone/P16_BikeArcade/EndlessChallengeRegistry.ts`
- `src/scenes/phone/P16_BikeArcade/EndlessArcadeRuntime.ts`
- `src/data/endless-arcade.content.json`

**修改：**

- `src/scenes/phone/P16_BikeArcade/index.tsx`
- `src/styles/scenes/p16-bike-arcade.css`
- `src/components/PhoneShell.tsx`
- `scripts/verify-endless-arcade.mjs`（仅同步显式懒加载合同）

**动作：**

- 建立 hub/loading/intro/running/paused/game_over 状态。
- 建立一个 Phaser 实例、一个 canvas、一个活动模式的宿主。
- 模式注册表提供 ID、标题、规则、输入说明、progress 单位、scene loader 和成绩格式器。
- 注册表使用一个显式 `import.meta.glob` 模块表保持真正的按需加载；Task 6/8 的 Scene 文件尚未创建时，对应 loader 返回结构化 `runtime_unavailable`，不得留下无法解析的静态 import、类型忽略或临时替代玩法。
- 活动局隐藏剧情任务和物品栏。
- 统一退出确认、错误恢复和返回主页。

**验证：**

- 手机外框在 430×860 和 390×844 缩放视口不改变。
- 三模式懒加载；进入一个模式时不加载另两个 scene。
- 模式切换后只有一个 canvas 和一组输入 listener。
- boot error 有重试和返回中心。

### Task 4：控制器与持久成绩

**新增：**

- `src/modules/EndlessArcadeController.ts`

**修改：**

- `src/modules/GameKit.ts`
- `src/core/SaveStore.ts`
- `src/scenes/phone/P16_BikeArcade/index.tsx`
- `src/scenes/phone/P16_BikeArcade/EndlessArcadeGameHost.tsx`
- `src/scenes/phone/P16_BikeArcade/EndlessArcadeRuntime.ts`
- `scripts/verify-endless-arcade.mjs`

**动作：**

- 实现 `startAttempt`、`settleAttempt`、`cancelAttempt`。
- 增加确定性 seed、run ID 一次结算和数值 sanitize。
- 保存三模式最佳记录。
- 仅在新成绩结构缺失时迁移旧自行车历史成绩。
- P16 只把 controller 返回的 run ticket 交给宿主；宿主将 ticket 的 `runId` 与 seed 交给场景，并把结算请求回传给 controller。

**验证：**

- 重复 settle 只写一次。
- cancel 不更新最佳记录。
- 非法、跨模式和过期 run summary 被拒绝。
- 三模式成绩互不覆盖。
- 开发模式不写正式存档。

### Task 5：提取钓鱼纯规则并保护剧情关卡

**新增：**

- `src/modules/RhythmFishingEngine.ts`
- `src/scenes/phone/P16_BikeArcade/EndlessFishingRules.ts`

**修改：**

- `src/scenes/rpg/QizhenFishingRhythmModel.ts`
- `scripts/verify-endless-arcade.mjs`
- `scripts/verify-qizhen-fishing-rhythm.mjs`

**动作：**

- 提取单调时钟判定、hold、combo、张力和 rating。
- 原剧情 model 通过适配层继续接受固定 chart ID。
- 新规则基于 seed 生成滚动段落。
- 加入有限难度曲线和资源窗口常量。

**验证：**

- 原四张 chart 的固定输入输出逐项一致。
- 同 seed 生成相同段落。
- 不同 seed 产生有效差异。
- 长局模拟中活动音符和历史数组均不增长过界。

### Task 6：实现竖屏节奏钓鱼

**新增：**

- `src/scenes/phone/P16_BikeArcade/EndlessFishingScene.ts`

**修改：**

- `EndlessChallengeRegistry.ts`
- `EndlessArcadeGameHost.tsx`
- `src/styles/scenes/p16-bike-arcade.css`

**动作：**

- 实现 390×650 三轨判定线、张力条、层级、连击和触屏按钮。
- 复用音频时钟与节拍调度策略。
- 实现视觉节拍 fallback、页面隐藏暂停和输入清空。
- 失败后生成结构化 summary。

**浏览器验收：**

- 键盘和触屏各完成至少两次成功收线。
- hold 按下与释放正确。
- 后台停留后不会产生集中 Miss。
- 失败、重试、返回中心完整。

### Task 7：提取灯光判定并保护剧院关卡

**新增：**

- `src/scenes/phone/P16_BikeArcade/EndlessSpotlightRules.ts`

**修改：**

- `src/scenes/rpg/TheaterSpotlightModel.ts`
- `src/modules/ChapterThreeTheaterController.ts`
- 现有剧院 validator
- `scripts/verify-endless-arcade.mjs`

**动作：**

- 导出纯判定器。
- 原剧院 controller 改为调用共享判定器。
- 建立 seeded 路径、干扰目标和有限难度生成。
- 使用 `endless_spotlight_*` 事件命名。

**验证：**

- 原剧情三组配置结果一致。
- 每个生成轮次可在输入基线内完成。
- 高层级仍满足最小预览、最大锁定和最小光束半径限制。

### Task 8：实现竖屏灯光追逐

**新增：**

- `src/scenes/phone/P16_BikeArcade/EndlessSpotlightScene.ts`

**修改：**

- `EndlessChallengeRegistry.ts`
- `EndlessArcadeGameHost.tsx`

**动作：**

- 实现预览、行动、锁定、失误、电量和轮次切换。
- 实现键盘瞄准与触屏滑轨。
- 每轮销毁路径、timer、tween 和对象。
- 电量归零后提交 summary。

**浏览器验收：**

- 真实目标可完成连续锁定。
- 照错干扰目标、提前照射和锁定中断反馈各自清楚。
- 指针滑出、取消和重新进入不会留下持续照射。
- 高层级检查点仍可操作。

**实施结果（2026-08-24）：**

- 已实现 `preview → action → transition`、动态 `previewMs`、跨轮三格电量、四类离散扣电、连续锁定和结构化 summary；路径、Graphics、监听器与检查 hook 均按场景生命周期回收。
- 触屏采用真实横向滑轨和独立照射键，显式 pointer capture 覆盖外部松手、取消、丢失捕获与离开；普通三键同步采用同一释放合同。
- 原第三章剧院三轮 parity、seeded wave 边界、TypeScript 和 diff 检查通过。Chromium `390×844` 已验证单 canvas、0.6 比例、滑轨移动、提前扣电、行动路线隐藏、外部松手释放、暂停恢复与零 console/page error。
- 真实截图发现并修复 `PresentationDirector` 对 postgame P16 误发旧 `bike_arcade_opened` 旁白的问题。当前静态规格与代码质量审查均为 PASS；高层级 DEV 检查点留在 Task 10。

### Task 9：把骑行扩展为可配置剧情与无尽模式

**修改：**

- `src/scenes/phone/P16_BikeArcade/BikeArcadeRules.ts`
- `src/scenes/phone/P16_BikeArcade/BikeArcadeRuntime.ts`
- `src/scenes/phone/P16_BikeArcade/BikeRushScene.ts`
- `EndlessChallengeRegistry.ts`
- 原自行车 validator
- `scripts/verify-endless-arcade.mjs`

**动作：**

- 增加 seed 和 `story/endless` 配置。
- 剧情模式保留固定 755 米终点。
- 无尽模式每 755 米进入下一圈。
- 增加圈数、近失连击、有限难度和对象池上限。
- 无尽事件使用独立命名，不写第三章完成状态。

**浏览器验收：**

- 剧情模式仍在 755 米按原合同完成。
- 无尽模式经过 755 米后继续运行并显示第 2 圈。
- 每个波次保留可通过车道。
- 暂停恢复不产生大 delta 碰撞。

### Task 10：开发通道、音频方向与诊断

**新增：**

- `src/data/endless-arcade.audio.json`（仅登记现有可复用音频）

**修改：**

- `src/modules/DeveloperChannel.ts`
- `src/main.tsx`
- `src/modules/AudioDirector.ts`
- `src/modules/PresentationDirector.ts`（仅在事件路由需要时修改）
- `scripts/verify-chapter4-755-task14.mjs`
- `scripts/verify-endless-arcade.mjs`

**动作：**

- 增加八个 postgame 检查点。
- 文本快照暴露挑战访问权、模式和活动局关键数值。
- 页面隐藏、scene close 和模式切换时停止该局音频。
- 未解锁检查点验证生产 gate 保持关闭。

**验证：**

- `?devCheckpoint=<id>` 在 Vite 和单文件中工作。
- postgame 检查点不触发 RPG-only 断言。
- 音频关闭、AudioContext 拒绝和页面隐藏都有可玩 fallback。

**2026-08-24 实施结果：**

- 已新增八个 `寻人篇 → 7:55 挑战` session-only 检查点，并通过 `DeveloperChannel` 写入无尽模式 runtime seed。
- `render_game_to_text` 现暴露 `endlessArcadeRuntime` 调试快照，包含 access、phase、selectedMode、activeRunId、attempt、snapshot 和 summary。
- Chromium Vite 定向验证已通过：hub seed 正常进入挑战中心；`postgame-bike-lap2` 修复后实际进入第 2 圈；`postgame-fishing-fail` 修复后能显示完整结算卡片。
- 实测中发现并修复两项真实问题：自行车跨圈 seed 未被 Host 注入、synthetic `game_over` seed 的结果页被 `runTicket` 条件挡住。

### Task 11：自动验证、CI 与性能长测

**修改：**

- `.github/workflows/web-ci.yml`
- `package.json`
- `scripts/verify-endless-arcade.mjs`

**动作：**

- 把 `npm run endless:validate` 加入 CI。
- 覆盖通关回执、旧存档、状态 sanitize、确定性、原剧情 parity、资源上限和重复结算。
- 为三个模式分别执行 30 分钟确定性模拟。
- 记录最大活动对象、listener 数、timer 数和内存趋势。

**通过条件：**

- 数组、对象池、timer 和 listener 没有随总运行时间持续增长。
- 分数和进度保持有限安全整数。
- 单次失败或退出后活动 Phaser 实例为 0。
- 新代码不引入网络请求和新外部依赖。

**2026-08-24 实施结果：**

- `.github/workflows/web-ci.yml` 已在 `typecheck` 前加入 `npm run endless:validate`。
- `scripts/verify-endless-arcade-long-run.mjs` 已接入 `scripts/verify-endless-arcade.mjs`；fresh `npm run endless:validate` 为 `172/172 PASS`。
- 三模式分别完成等效 `1,800,000ms` 离线确定性模拟：节奏钓鱼完成 `146` 段、灯光追逐完成 `648` 轮、自行车达到 `107,353m`；同 seed 全量结果一致，异 seed 指纹不同。
- controller 长测覆盖非法 summary 拒绝、一次取消、一次结算、三模式记录隔离和统一 score ceiling；失败与退出后的 active runtime、对象、timer 均归零。
- 资源趋势字段属于纯规则计数模型，明确记录 `scope=pure_rules_resource_counts_only` 与 `browserHeapMeasured=false`，不将其表述为浏览器堆内存实测。
- `npm run typecheck`、`npm run bike:validate`（`21/21`）、`npm run qizhen:validate-fishing`、`npm run theater:validate-spotlight` 与 `npm run chapter4:validate-task14`（`337` 项）均 fresh 通过。
- Firefox/WebKit 和多视口真实交互验收已在 Task 12 完成；Task 13 单文件构建与 `demo/index.html` 验收按用户要求暂缓。

### Task 12：真实浏览器验收

使用现有 Web 游戏浏览器客户端：

```bash
node /Users/zhuhangcheng/.codex/skills/develop-web-game/scripts/web_game_playwright_client.js --help
```

按项目实际启动命令运行 Vite，然后验证：

**浏览器：**

- Chromium/Blink
- Firefox/Gecko
- WebKit

**视口：**

- `1280×720`
- 一个非 16:9 桌面视口
- `390×844`

**路径：**

```text
锁定手机桌面
  → 7:55 静态槽位

postgame 开发检查点
  → 手机桌面
  → 7:55 挑战中心
  → 节奏钓鱼开始 / 暂停 / 失败 / 重试 / 返回
  → 灯光追逐开始 / 暂停 / 失败 / 重试 / 返回
  → 755 米骑行跨圈 / 失败 / 重试 / 返回
  → 刷新
  → 回执与最佳成绩保持
  → 返回手机主页
```

**输入：**

- 桌面真实键盘事件。
- 移动端 Pointer Events。
- `pointercancel`、失焦、页面隐藏和控制中心打开。

**通过条件：**

- 430×860 手机框稳定，无 document overflow。
- 桌面不显示虚拟按键；粗指针显示触屏控制。
- 页面和控制台无错误。
- 只有一个 Phaser canvas。
- 任务抽屉和物品栏不覆盖活动局。
- 所有截图在结论记录后删除。

**2026-08-24 实施结果：**

- React StrictMode 生命周期改用 epoch 判定；探测式 cleanup 不再提前取消首局 ticket，真实卸载仍以原 `runId` 执行一次取消。
- Host 在暂停、失焦、页面隐藏、控制中心打开、退出确认和销毁前统一执行中性输入释放；scene cleanup 同时覆盖 `SHUTDOWN` 与 `DESTROY`。
- 灯光追逐已修复 `ArrowLeft + Space → blur → paused → resume` 后持续移动或持续照射的问题；恢复后光束位置保持，`beam.on=false`、`lockMs=0`。
- 节奏钓鱼使用无惩罚的 held-input 生命周期释放；正常提前松手仍只结算一次，不会出现 soft lock。
- 自行车粗指针控制精简为“左车道 / 右车道”；三模式触控区仅在 `phase === running` 时渲染，暂停、确认退出和结算态均为零。
- pointer capture 具备能力检测与异常 fallback；window `pointerup`、`pointercancel`、`blur`、`pagehide` 和 document `visibilitychange` 均能清理活动指针。
- 灯光追逐使用独立 `window.render_endless_spotlight_to_text`；主应用 `window.render_game_to_text` 保持原调试所有权，退出后专用 hook 与 `advanceTime` 均清理。
- 真实浏览器基础矩阵为 `45/45 PASS`：Blink、Gecko、WebKit × `1280×720`、`1280×800`、`390×844` × 锁定入口、挑战中心和三个运行态。
- 状态与生命周期工作流为 `19/19 PASS`：三个模式的失焦暂停、恢复、控制中心暂停、退出确认、失败、重试、返回中心，以及三引擎移动端无 pointer capture fallback 全部通过；Blink 额外验证自然结算后最佳成绩在刷新后保持。
- 全矩阵 `documentOverflowX/Y=0`，手机框比例保持 `0.5`，运行态 canvas 固定 `390×650` 且数量为 `1`；hub、game over 和确认退出后的最终 hub canvas 数量为 `0`，任务栏与物品栏未覆盖活动画布，浏览器 diagnostics 为 `0`。
- 视觉抽查覆盖 Blink 的桌面挑战中心、非 16:9 灯光运行态和 `390×844` 自行车触控态；临时截图在记录结论后删除。Task 13 单文件构建本轮未执行。

### Task 13：构建、单文件与记录

**修改：**

- `progress.md`
- `project-development-report.md`

**生成：**

- `demo/index.html`

**命令：**

```bash
npm run endless:validate
npm run typecheck
npm run build:single
npm run verify:single
git diff --check
```

并运行受影响的现有剧情 validator：

- 启真湖节奏和音频合同。
- 第三章剧院灯光合同。
- 原固定 755 米自行车合同。
- 第四章 7:55 runtime、story 和 developer checkpoint 合同。

**记录：**

- 修改范围。
- 三模式规则版本。
- validator 与浏览器结果。
- 单文件字节数与 SHA-256。
- 未解决问题和正式结局素材接线状态。

**Git 边界：**

- 本任务不自动 stage、commit、merge 或 push。
- 用户提出上传后，先 fetch，并分别列出工作区改动、本地领先提交、远端领先提交和未跟踪文件，再由用户确认精确提交范围。

**2026-08-25 实施结果：**

- Fresh 自动门全部通过：`chapter4:validate-assets`、`chapter4:validate-story`、`chapter4:validate-topology`、`chapter4:validate-runtime`、`chapter4:validate-task14`、`endless:validate`（`172/172`）、`bike:validate`（`21/21`）、`qizhen:validate-fishing`、`theater:validate-spotlight` 与 `typecheck`。
- Chapter 3 音频总门首次报告缺少 `music_qizhen_fishing.mp3`；从已验证交付快照恢复同一二进制，并按原 manifest 哈希补回生成记录。复验结果为 `expected=77 / ready=77`，文件 SHA-256 为 `9cdbd42eef10c39d3b393b335a8458f29226aa1d74c0388adb026c31124de352`。本次没有发起模型生成请求。
- 初始工作区的 `npm run build`、`npm run build:single` 和 `npm run verify:single` 全部退出码 `0`。随后按方案 A 在 fresh `origin/main` 隔离工作区移入活动源码、删除 Godot/Playwright 退役内容并重新构建；最终 `demo/index.html` 为 `249850310` bytes，SHA-256 为 `1a68b0a6a9460959904d132ec5c28c1b7c90d7f4de304d6cbe6ed2c322bbf7ff`，包含 `2` 个内联脚本、`1` 个内联样式，验证器确认最终允许入口为 `index.html`。
- 标准网页游戏客户端对新单文件分别从 HTTP 与直接 `file://` 进入 `postgame-endless-hub`，两条路径画面一致、挑战中心三模式完整、无 console/page error。HTTP 单文件继续验证节奏钓鱼、灯光追逐与 755 米骑行运行态均只有 `1` 个 Phaser canvas；钓鱼正常进入失败结算，灯光保持运行态，骑行从第二圈检查点运行到 `progress=984 / lap=2 / tier=2`。
- Task 11–12 的跨引擎与多视口证据继续作为同一源码的浏览器兼容基线：`45/45` 基础矩阵与 `19/19` 生命周期工作流已覆盖 Blink、Gecko、WebKit 及 `1280×720`、`1280×800`、`390×844`。本次 Task 13 只新增生成物结构、HTTP 和直接文件打开复验，没有重复运行三层碰撞与遮挡专项。
- 单文件仍受 `.gitignore` 的 `demo/` 规则约束，不会因普通 `git add` 自动进入提交。上传前必须在 fetch 后明确选择源码交付、强制纳入单文件，或采用日期化发布目录；不得把这一选择隐式处理。
- 用户已选择日期化 GitHub Release：源码直接进入 `main`，HTML 与 SHA-256 以 `demo-20260825` Release 附件发布。实现、上传目录、资产文件、README 与 `ASSETS.md` 均使用 `20260825`。

## 12. 自审结果

### 12.1 范围挑战

已找到现成入口、宿主、三套规则基础、手机 UI、存档、开发通道和单文件管线。无需新增第二个应用入口、第二个手机框、新引擎、新服务或新媒体管线。

该功能必然超过 8 个文件，原因来自三种完整模式、持久状态、存档迁移、剧情回归保护和跨浏览器验收。删减任一玩法会偏离用户明确范围。执行时按 Task 1–13 分段，每段保持单一责任和独立验证，避免一次性横跨全部模块。

最低新增长期抽象只有两项：

- `EndlessArcadeController`：开局与结算权威。
- `EndlessArcadeGameHost`：竖屏 Phaser 生命周期权威。

模式注册表和纯规则模块属于静态数据与计算层，不建立额外服务。

### 12.2 架构审查

通过项：

- 继续由 React/TypeScript 管理状态、路由、保存和 UI。
- Phaser 只管理当前局呈现和输入。
- 一个页面只存在一个 Phaser 实例。
- 通关权限、挑战成绩和旧剧情自行车状态分离。
- 生产 gate 使用 controller 验证后的回执，不依赖可伪造旧字段。
- 复用稳定 scene ID，降低桌面排序和旧存档迁移范围。

需要在实现阶段重点复核：

- `SAVE_VERSION` 提升前必须固定 Chapter 4 迁移阈值。
- `currentScene === "bike_arcade"` 的旧第三章推断必须加版本边界。
- 合法回执恢复 complete 状态与当前防伪降级逻辑需要明确优先级。
- `PhoneShell` 的任务/物品栏抑制只作用于活动局，不影响挑战中心和其他章节。

### 12.3 代码质量审查

必须坚持：

- 共享判定器先以原剧情固定用例证明 parity，再接无尽模式。
- scene 不直接读写 `GameStore`。
- 所有随机内容来自显式 seed。
- 所有 event 使用 `endless_*` 命名空间。
- 所有分数、进度、层级和时长经过有限整数校验。
- 每个 scene 同时监听 `shutdown` 与 `destroy`，统一清理。
- 活动对象和历史集合均有明确上限。

拒绝的捷径：

- 直接把原三个完整剧情 scene 嵌入手机页面。
- 把 `bikeArcade.unlocked` 改成通关标志。
- 把 `chapter4.completed` 直接持久化后跳过 consumer proof。
- 在每个模式各写一套暂停、错误、退出和存档逻辑。
- 使用 `Math.random()` 生成无法复现的难度波次。
- 在 755 米后继续累积旧剧情 `bestDistance` 字段。

### 12.4 验证审查

验证层级：

```text
纯规则 validator
  ├─ 原剧情 parity
  ├─ endless 难度与确定性
  └─ 长局资源上限
       │
       ▼
controller / SaveStore validator
  ├─ receipt
  ├─ migration
  ├─ exactly-once settlement
  └─ malformed data
       │
       ▼
React 路由与挑战中心浏览器检查
       │
       ▼
三模式真实键盘与触屏操作
       │
       ▼
Blink / Gecko / WebKit 与多视口
       │
       ▼
offline single-file
```

没有新增测试框架。项目当前明确排除测试依赖，第一版使用确定性 Node validator、现有回归脚本和真实浏览器 QA。

### 12.5 性能审查

- Phaser 和 mode scene 懒加载。
- 挑战中心不预加载 RPG 地图、Three.js 或另外两个模式。
- 单次只挂载一个 canvas。
- 音符、障碍、路径点、粒子、timer 和 listener 使用上限或池。
- 长局以滚动窗口生成内容，不构建完整无限谱面或波次数组。
- 第一版不增加新媒体，单文件体积增长目标控制在约 1 MiB 以内；超过后需要定位 bundle 组成并重新评估。

### 12.6 安全与数据审查

- 本地功能不新增网络、账号和用户输入发布。
- 存档值全部 sanitize。
- 开发检查点继续使用 session-only 标记，不能覆盖正式存档。
- URL 检查点 ID 必须在白名单内解析。
- `render_game_to_text()` 不输出本地路径、完整存档或个人信息。

### 12.7 故障处理矩阵

| 故障 | 预期处理 | 禁止结果 |
|---|---|---|
| 第四章收束未验证 | 7:55 槽位静态锁定 | 使用旧骑行状态提前开放 |
| 旧存档含 `bikeArcade.unlocked` | 迁移历史成绩，可用权仍关闭 | 生成正式回执 |
| 合法回执后刷新 | 回执、complete 和入口保持 | 降回外景等待 |
| 非法回执 | 清为 null 并锁定 | 容错成任意真值 |
| Phaser 动态导入失败 | 显示重试和返回中心 | 空白页或无限 loading |
| 页面隐藏或失焦 | 暂停、清输入、显式恢复 | 后台继续判定或碰撞 |
| pointer capture 丢失 | 释放输入 | 按键永久按住 |
| 活动局刷新 | 取消当前局并返回中心 | 保存半局障碍和计时器 |
| 重复结算回调 | 忽略第二次 | 重复增加记录 |
| summary 含 NaN/Infinity | 拒绝并记录开发错误 | 污染存档 |
| 音频不可用 | 使用视觉节拍和倒计时 | 禁止进入钓鱼 |
| 30 分钟长局 | 集合与对象数量有界 | 内存随总时间持续增长 |
| 单文件直接打开 | 三模式正常启动 | 依赖 HTTP 媒体或外链脚本 |

### 12.8 TODO 审查

- 当前仓库无 `TODOS.md`。
- 未发现需要为第一版额外绑定的既有 TODO。
- 第四章正式收束素材与 verifier 接线属于生产解锁前置依赖，在现有第四章 Task 12 范围内完成；无尽挑战不得自行伪造该完成事实。

## 13. 验收清单

### 权限与存档

- [x] 新游戏和未正式通关存档中，7:55 图标保留原位置且无交互语义。
- [x] 旧 `bikeArcade.unlocked`、P12 ending 和裸 Chapter 4 complete 均不开放入口。
- [x] 正式 verifier 成功后，同一事务写回执并返回手机主页。
- [x] 合法回执与最佳成绩在 Vite/HTTP 刷新后保持。
- [ ] Task 13：合法回执和最佳成绩在生成的离线单文件中保持。
- [x] v25 第四章进行中存档不被 v26 迁移重置。
- [x] 旧隐藏桌面配置不会移除 7:55 入口。

### 挑战中心

- [x] 现有 7:55 图标和 `游戏` 名称保持。
- [x] Hub 显示三个模式、规则、控制和各自最佳成绩。
- [x] hub、loading、intro、paused、game over 和 boot error 均有明确下一步。
- [x] 活动局退出需要行内确认。

### 节奏钓鱼

- [x] J/K/L 和触屏三轨工作。
- [x] Perfect/Good/Miss、hold、combo 和 tension 可见且一致。
- [x] 随层级持续生成有界段落。
- [x] 张力持续越界才失败。
- [x] 原启真湖四张剧情 chart 回归通过。

### 灯光追逐

- [x] 预览、瞄准、持续锁定、干扰目标和电量完整。
- [x] 键盘和触屏滑轨均进入同一动作合同并正确释放。
- [x] 高层级参数保持可操作下限。
- [x] 原第三章剧院灯光判定回归通过。

### 755 米骑行

- [x] 每 755 米进入下一圈，不触发剧情胜利。
- [x] 距离、圈数、近失、生命和难度显示正确。
- [x] 波次始终保留可通过车道。
- [x] 原剧情模式仍在 755 米按现有合同结束。

### 运行时与交付

- [x] 一次只有一个 Phaser canvas。
- [x] 退出后无残留 timer、listener、AudioContext 调度和 bridge 订阅。
- [x] 30 分钟确定性长测集合数量有界。
- [x] Blink、Gecko、WebKit 和三个目标视口通过。
- [x] `npm run endless:validate`、受影响的剧情 validator 与 `npm run typecheck` 全部通过。
- [ ] Task 13：`npm run build:single` 与 `npm run verify:single` 全部通过。
- [ ] Task 13：`demo/index.html` 可直接打开并进入三个模式。
- [x] QA 临时截图已删除。

## 14. 执行准备结论

计划已通过范围、架构、状态迁移、代码复用、性能、故障和交付自审。执行顺序固定为：

```text
Task 0 基线验证
  → Task 1–2 通关回执与入口
  → Task 3–4 统一宿主与控制器
  → Task 5–6 节奏钓鱼
  → Task 7–8 灯光追逐
  → Task 9 755 米骑行
  → Task 10 调试与音频
  → Task 11 自动验证和长测
  → Task 12 真实浏览器
  → Task 13 单文件交付
```

开始执行时先完成 Task 0，不直接改 `demo/index.html`，不把第四章未验证完成状态写入正式存档，不进行 Git 提交或上传。

# 2026-08-27｜第三章半并行取证、全局现实模式解序与第四章阶段加载修订计划

> 本节是 2026-08-27 的现行执行依据。上文已经完成后又被产品决定删除的三种无尽挑战仅保留历史记录，不得恢复入口、运行时、存档字段或验收项。本轮不编辑生成文件 `demo/index.html`，不执行 Git 暂存、提交、合并或推送。

## 1. 本轮结论与用户影响

本轮同时解决四组直接影响实际游玩的矛盾：

1. 第四章当前把整章图像一次性预热，入口后的局部切换较顺，但移动端和 Safari 可能承担集中解码与内存峰值。改为按剧情阶段加载，并以“切换期间角色控制没有明显停顿”作为验收目标。
2. 第三章半控制器已经允许照片、录音、消息和网络记录任意顺序完成，任务栏仍用固定顺序呈现。改为一个 `0/4` 并行调查目标，四类证据分别显示完成状态。
3. 浅色操作和深色观察保留各自语义，但全游戏禁止用“必须先完成另一模式的交互”作为当前交互的隐藏门槛。玩家可先观察，也可先执行已满足物品、距离、目标和剧情阶段条件的实体操作。
4. 第四章新增内容按实际作用设计：可进入教室有状态相关交互，每层有能解释当前异常的 NPC，保安增加稳定的感知与搜寻表现状态。角色数量不能成为内容量的替代指标。

## 2. 全局现实模式合同

### 2.1 保留规则

- `深色观察`：读取残影、路线、节拍、异常状态和环境证据。
- `浅色操作`：拾取、拖放、清洁、支付、推动、开关设备、使用物品和其他实体行为。
- `requiredMode`、`wrong_mode`、物品 ID、距离、目标区域、剧情阶段和一次性事务继续有效。
- 玩家在错误模式尝试时，反馈只说明该动作所属模式以及当前可执行动作。

### 2.2 删除的固定先后门槛

- 浅色实体操作不得仅因某个深色观察事实尚未写入而被拒绝。
- 深色观察不得仅因某个浅色操作尚未完成而失去交互入口。
- 允许两种模式的事实分别记录，并在最终结算点检查完整条件；中间步骤不得强制排列为 `深色 → 浅色` 或 `浅色 → 深色`。
- 直接尝试正确目标不会提前显示答案。目标仍需可见、可到达，物品、距离和剧情阶段仍需正确。

### 2.3 首批覆盖范围

- 食堂：读取线索与清洁、支付、拾取等实体动作解除模式先后依赖。
- 剧院：观察光路与操作道具可任意先后，最终灯光结算仍检查必要事实。
- 启真湖：深色观察仍能标记倒影和钓点；浅色模式在正确坐标、正确物品和有效距离下可直接执行，不再要求先写入观察事实。
- 第四章：教室残影、参考信息、家具复位、配电与电梯交互解除模式先后依赖；房间最终复原仍要求状态完整。
- 错位楼梯：观察回声和调整结构均可先做；完成判定继续由 TypeScript 第四章控制器统一提交。

### 2.4 自动防回归

新增确定性 validator，覆盖：

- 同一谜题的两种合法顺序均能到达相同终态。
- 未观察时，正确浅色动作不会返回只由观察事实触发的 `locked`。
- 错误模式仍返回 `wrong_mode`，错误物品、距离和剧情阶段不放宽。
- 观察事实在实体操作完成后仍可记录，不被已完成状态吞掉。
- 存档重载后两种顺序产生相同的控制器事实。

## 3. Task 0｜基线、脏工作区与合同锁定

目标：在不覆盖当前人物侧面帧、空气墙、文本导出、雨天表现、教室和保安改动的前提下建立本轮基线。

执行：

- 记录 `git status --short`、当前分支和 `HEAD` 到 `progress.md`。
- 只修改本轮明确列出的源文件；遇到已修改文件先按局部差异合并。
- 运行受影响模块的现有 validator 和 `npm run typecheck`，把既有失败与本轮回归分开记录。
- 保持 `demo/index.html` 只由构建脚本生成；首个三任务批次不生成单文件。

## 4. Task 1｜第四章分阶段静默加载

### 4.1 阶段定义

| 阶段 | 触发时机 | 必备资源 | 下一阶段静默加载 |
|---|---|---|---|
| `entry` | 3.5 任务卡确认、进入第四章前 | A1 开场、主角、基础 HUD、前台、电梯门基础帧、当前可见道具 | `transport` |
| `transport` | A1 可控后；玩家接近电梯时提高优先级 | A2/A3 基础板、18:50 状态、电梯、错位楼梯、Room 204 基础物件 | `maintenance` |
| `maintenance` | 进入 22:45 维修链前 | 保安、保洁、配电、停电、追逐和维修状态板 | `closure` |
| `closure` | 安装最后一分钟、进入 07:54 前 | 校友墙画像、晨间状态、最后一分钟和正式收束素材 | 无 |

当前场景只等待“进入该阶段必需资源”。下一阶段资源通过空闲回调、逐张解码和可取消任务加载；受限网络或低内存设备缩小提前加载批次，不跳过当前阶段必备资源。

### 4.2 运行时数据结构

在 `src/scenes/rpg/RpgRuntimePreload.ts` 增加阶段键和可观测快照：

```ts
type RpgWarmupPhase = "entry" | "transport" | "maintenance" | "closure";

interface RpgWarmupPhaseSnapshot {
  sceneId: RpgSceneId;
  phase: RpgWarmupPhase;
  status: "idle" | "scheduled" | "loading" | "ready" | "degraded" | "failed";
  assetCount: number;
  loadedCount: number;
  reusedCount: number;
  failedUrls: string[];
  estimatedTransferBytes: number;
  measuredTransferBytes: number;
  estimatedDecodedBytes: number;
  elapsedMs: number;
  degradationReason: "constrained_network" | "low_memory" | "decode_failure" | null;
}
```

说明：`estimatedDecodedBytes` 使用 `naturalWidth × naturalHeight × 4`，只表示估算的 RGBA 解码量，不宣称等于浏览器实际堆内存。HTTP 资源优先从响应或资源计时读取传输字节；`file://` 与无法测量的 data URL 保留估算值和明确的未知状态。

### 4.3 真实加载边界

仅拆分浏览器预热不能降低 Phaser 首次 `preload()` 的集中解码，因此需要同时调整：

- `ChapterFourTemporalMazeScene.ts`：把资源表拆为四个阶段；创建阶段只注册当前必需纹理和动画。
- `RpgGameHost.tsx`：提供阶段请求、取消、失败恢复和调试快照；同一场景同一阶段去重。
- `Chapter4PrologueRuntimeGate.tsx`：只等待 `entry`，不得等待整章素材。
- `App.tsx`：手机态只计划 `entry`；后续阶段由第四章进度或运行时事件触发。
- Phaser 场景与 React 宿主通过引擎中立事件请求下一阶段，场景不得直接修改共享存档或创建第二套进度状态。
- 进入原子状态板切换前先确认目标阶段资源已就绪；失败时保持当前可控画面，显示可重试状态，不切到空白纹理。

### 4.4 性能验收

- 调试快照可读取每阶段耗时、成功数、失败资源、传输字节和估算解码字节。
- 同一资源跨阶段只解码一次；页面隐藏或场景退出取消未开始批次。
- 入口等待只覆盖 `entry`。
- 在正常桌面、受限网络模拟和移动端视口中记录阶段切换期间最长主线程任务与控制响应。
- 通过条件：切换时角色移动输入持续响应，无空白贴图、无重复场景、无未处理 Promise rejection。

## 5. Task 2｜第三章半并行调查与时间线兼容

### 5.1 并行任务投影

保留 `journal_start` 作为共同起点。完成后任务栏显示：

```text
恢复剩余证据（n/4）

照片线索    已恢复 / 待恢复
录音线索    已恢复 / 待恢复
消息线索    已恢复 / 待恢复
网络记录    已恢复 / 待恢复
```

四项完成条件：

- 照片：`photoSequenceSolved`。
- 录音：`voiceSequenceSolved`。
- 消息：`officialNoticeSaved && routeScreenshotSaved`。
- 网络：`networkRecordRead`。

现有 `evidenceProgress` 继续服务自动时间线来源；新增独立 `branchProgress`，避免把日志起点计入 `0/4`，也避免把消息与网络合并成一项。

### 5.2 任务栏 UI

- `ChapterThreeInterludeModel.ts` 提供 `parallelBranches` 和聚合目标。
- `QuestModel.ts` 把并行分支映射到任务视图。
- `QuestClueStrip.tsx` 在当前任务下常显四行状态，每行可进入对应应用；不要求先展开提示。
- 聚合目标的默认推荐场景是 `phone_home`，避免用第一项未完成应用继续暗示顺序。
- 只显示类别、状态和应用入口；禁止显示正确照片排序、录音 ID、消息内容、AP 编号和最终楼宇。

### 5.3 删除正式流程中的时间线死任务

- 正式 selector 不再返回独立 `timeline` 任务。
- “证据齐全 + 三条旧时间已排除 + 状态栏时钟不可信”直接解锁自动时间线和地点判断。
- `assembleTimeline()` 保留为旧调用和 DEV 节点兼容入口。
- `verifyDestination()` 在接受正确地点时同步规范化 `timelineOrder`。
- `c3-interlude-timeline` 开发节点保留，不能破坏现有 Task 14 validator。

### 5.4 旧存档迁移

`normalizeChapterThreeInterlude()` 双向对齐汇总 evidence ID 与细分事实：

- 已有 `photo_direction` / `broadcast_end` 时补齐相应 solved 布尔值。
- 已有 `network_destination` 时补齐通知、截图和网络记录三个布尔值。
- 细分事实已齐时补齐汇总 evidence ID。
- 所有时间线前置事实已齐时把 `timelineOrder` 规范为四个标准来源。
- 已进入第四章的存档不得回退到调查任务。

### 5.5 验收

- 运行四分支 `4!` 顺序，并覆盖消息内部两种顺序，共 48 条成功路径。
- 日志前正确操作保持锁定；日志后任何未完成分支均可直接完成。
- 错误答案不写入完成事实。
- 三类旧存档：时间线为空、顺序错误、只有汇总 evidence ID，水合后均一致。
- 聚合任务静态检查禁止泄露答案文本。
- 430×860 与 390×844 下任务抽屉四行可见、可滚动、可点击。

## 6. Task 3｜全游戏现实模式解序

### 6.1 实现方法

- 在 `RpgInteractionContract.ts` 记录全局“模式语义独立、模式顺序不构成门槛”合同。
- 逐一删除食堂、剧院、启真湖和第四章控制器中仅用于强制观察先行的布尔锁。
- 将最终完整性检查集中到各自控制器终态方法；中间实体动作只验证当前模式、物品、距离、目标与剧情阶段。
- 已完成实体操作后，观察交互仍可运行并记录事实；重复操作保持幂等。
- 更新任务文案，删除“先切到深色”“观察后才能操作”等固定顺序提示，保留错误模式纠正。

### 6.2 验收矩阵

| 场景 | 顺序 A | 顺序 B | 共同终态 |
|---|---|---|---|
| 食堂 | 深色读取后浅色处理 | 浅色处理后深色读取 | 当前食堂事实一致 |
| 剧院 | 深色观察后操作道具 | 操作道具后深色观察 | 灯光结算前置一致 |
| 启真湖 | 观察钓点后使用物品 | 正确坐标直接使用后再观察 | 物品链与存档一致 |
| Room 204 | 观察残影后复位 | 先复位可见家具后观察 | 房间最终复原一致 |
| 错位楼梯 | 观察回声后调整 | 调整后观察回声 | 控制器完成事实一致 |

## 7. Task 4｜第四章有效交互设计

### 7.1 数据模型

建立由时间状态驱动的交互目录，不把 NPC 对白散落在 Phaser 场景条件中：

```ts
type ChapterFourClockState = "12:25" | "18:50" | "22:45" | "07:54" | "07:55";

interface ChapterFourContextInteraction {
  id: string;
  floor: 1 | 2 | 3;
  roomId: string;
  actorId?: string;
  clockState: ChapterFourClockState;
  purpose: "environment" | "state_feedback" | "side_info" | "theme";
  mode: "dark" | "light" | "either";
  repeatPolicy: "once" | "per_clock_state" | "repeatable";
  textId: string;
  optionalFactId?: string;
}
```

### 7.2 内容配额

- 每间可进入教室至少一个与当前时间状态相关的有效交互。
- 每层至少一个 NPC 能说明本层当前异常，但不直接给出完整解法。
- 前台、教师、助教、值班人员、保洁、面包坊营业员和自习学生按所在时段改变对白。
- 每个 NPC 至少承担环境说明、状态反馈、支线信息、主题表达中的一项。
- 校友生平使用一张短卡；少数校友与“竺老两问”和后续灯光主题产生弱关联，其余保持自愿阅读。
- 校友和普通 NPC 都不作为批量通关条件。

### 7.3 时间状态示例

| 位置/角色 | 12:25 | 18:50 | 22:45 | 07:54 | 07:55 |
|---|---|---|---|---|---|
| 204 教室助教 | 说明课间设备状态 | 指出终端回放和座椅异样 | 提醒维修许可范围 | 确认复原差一项 | 记录正式恢复 |
| 一层前台 | 午间访客登记 | 晚间房间使用情况 | 说明值班与维修人员 | 核对最后一分钟 | 开放正式签到 |
| 二层保洁 | 说明地面与推车位置 | 反馈晚课散场 | 指出异常断电后的可见变化 | 确认清洁复位 | 恢复日常路线 |
| 电梯口值班员 | 电梯正常楼层信息 | 说明楼层显示异常 | 反馈维修模式 | 确认层号同步 | 解除临时管制 |
| 面包坊营业员 | 午间出炉信息 | 晚间余量 | 维修夜间关闭 | 早班备货 | 正式营业 |

具体文案在实现任务中进入统一文本目录，并由文本导出脚本按章节收集。

## 8. Task 5｜保安感知与追逐表现设计

### 8.1 状态机

```text
patrol
  → notice
  → turn_confirm
  → pursue
  → lost_sight
  → move_to_last_seen
  → search
  → reacquire → pursue
  → return_patrol → patrol
```

### 8.2 状态职责

- `patrol`：沿固定路径移动，转向只发生在路径节点并保持最短朝向时间。
- `notice`：玩家进入视野后累计确认时间，短暂擦边不会立即追逐。
- `turn_confirm`：保安只转向一次并播放确认帧，禁止连续左右摆头。
- `pursue`：使用最后稳定目标点和短时预测点；目标点有最短保持时间与位置变化阈值。
- `lost_sight`：视线丢失后保留短暂容错，防止遮挡边缘频繁切换状态。
- `move_to_last_seen`：前往最后目击点，不直接读取不可见玩家实时坐标。
- `search`：按有限的两个或三个检查点搜索，转头有停留时间和次数上限。
- `reacquire`：重新确认后回到追逐。
- `return_patrol`：以最近路径节点恢复巡查，不瞬移、不反复转向。

### 8.3 与现有公平性模型的边界

- `ChapterFourFinalChaseModel.ts` 继续负责最终追逐的速度带、路线距离、终点同帧优先和接触确认。
- 新状态机负责普通巡查和追逐表现、目标选择、朝向和动画提示，不改控制器胜负事实。
- 使用滞回阈值、目标保持时间和转向冷却处理现有突然转向与左右摆头。
- 调试快照输出状态、最后目击点、视线确认时间、丢失时间、目标保持时间和当前搜索点。

## 9. Task 6｜验证、浏览器 QA 与报告

### 9.1 自动验证

- 新增第三章半并行顺序 validator。
- 新增现实模式双顺序 validator。
- 新增第四章阶段加载 manifest、阶段边界和指标 validator。
- 新增保安状态转换、滞回和目标保持纯模型 validator。
- 运行现有受影响的音频、Task 14、启真湖、第四章、文本导出和 TypeScript 检查。

### 9.2 真实浏览器

- 第三章半：验证四分支逆序完成、任务栏四行状态、旧时间排除后直接地点判断。
- 现实模式：各选一个食堂、剧院、启真湖和第四章路径，分别以两种顺序完成。
- 第四章加载：记录 `entry` 与后三阶段切换，确认角色控制持续响应；模拟受限网络和移动端视口。
- 保安：验证发现、失去视线、最后目击点、搜索、重新发现和返回巡逻，不出现连续左右摆头。
- 按用户既有要求，不执行三层浏览器碰撞与遮挡专项校验；自动碰撞数据检查仍保留。
- 所有临时截图在结论记录后删除。

### 9.3 交付边界

- 首批执行 Task 1、Task 2、Task 3，完成后先汇报变更与验证结果。
- Task 4、Task 5 在设计确认后进入实现；本轮已给出可直接编码的数据合同和状态机。
- 行为修改完成后按项目合同运行 `npm run typecheck`；只有用户再次要求交付时才构建单文件。
- 不执行 Git 暂存、提交、合并或推送；需要上传时先 fetch 并展示本地工作树、本地相对远端提交、远端新增提交三份视图。

# 2026-08-27｜并行取证、阶段预热、现实模式解序与第四章交互执行结果

## 1. 已落地结果

### 1.1 第三章半取证

- 照片、录音、消息与网络四条证据线由固定顺序改为并行完成，任务栏统一显示 `恢复剩余证据 n/4` 和四行独立状态。
- 四类证据收齐以后才进入旧时间排除和地点判断；正常流程不再显示独立“核对自动恢复的时间线”任务。
- `SaveStore` 在摘要 evidence ID、细分事实、规范时间线和已进入第四章的旧存档之间执行双向归一化，避免旧存档倒退。

### 1.2 第四章阶段预热

- 资源阶段固定为 `entry / transport / maintenance / closure`。首次入口只解码当前 A1 开场所需资源，A2/A3 和后续人物、状态图按剧情接近点加载。
- 空闲预热和必需加载使用同一阶段注册表；受限网络或低内存环境缩小推测批次，必需阶段仍可完整补齐。
- 调试状态记录阶段、预计字节、已解码字节、总耗时、失败资源和降级原因。失败时保留上一张已提交投影，并从最早缺失前置阶段重试。

### 1.3 现实模式顺序

- 全局规则为：深色观察读取信息，浅色操作执行物理动作；模式语义继续存在，模式先后不构成隐藏门槛。
- 食堂菜单、取餐窗与餐盘车，剧院节目单与道具箱，启真湖钓点与物品链，第四章电梯、Room 204 与错位楼梯均覆盖两种执行顺序。
- 实体操作不会自动写入观察事实；玩家随后仍可完成真实观察。最终阶段只检查真实领域事实是否完整。
- 第四章电梯的历史读取和轨道校准可在教室检查前独立进行，高层路线继续由 104/105 教室检查控制。这样保留剧情门控，同时删除现实模式门控。

### 1.4 教室与保安

- A2 201/202/203 和 A3 301/302/304 接入统一只读上下文 intent。生产场景和验证器共用 intent 构造与字幕解析函数，拒绝、变更型或 intent 不匹配的 controller 响应不能输出内容。
- 当前正式 `room204_restore` 阶段使用 18:50 文案；其余五种时间状态标记为回访预留，不伪装为当前可达内容。
- 保安表现增加发现、确认、追逐、失视、最后目击点搜索、返回巡查与重新发现状态，并使用移动阈值与主轴滞回稳定朝向。位置、速度、视线、碰撞和抓捕仍由原权威模型结算。

## 2. 验证结果

| 范围 | Fresh 结果 |
|---|---|
| 第三章半并行证据 | `1944` 项，`48` 种完成顺序 |
| 全局现实模式解序 | `180` 项 |
| 第四章阶段预热 | `70` 项；`12` 张 plate、`5` 张 spritesheet、`21` 组 NPC 动画 |
| 六间教室只读交互 | `435` 项 |
| 保安表现状态 | `40` 项；独立审查无 Critical/Important |
| 第四章完整回归 | runtime `1252`、Task 14 `365`、topology `2769`，story 与 assets 通过 |
| 第三章受影响玩法 | 食堂 `40/40`、剧院三轮、启真湖钓鱼/雨天 `47` 项/日志均通过 |
| 工程门禁 | `typecheck`、普通 `build`、任务提示所有权、文本导出校验、`git diff --check` 全部通过 |

## 3. 证据边界与后续验证

- 六教室的生产共用纯流程、控制器只读结果、字幕解析、锚点内部样本与静态碰撞分离已验证；真实浏览器的人物靠近、`Space` 输入、字幕可见性尚未执行。
- 阶段资源注册、失败重试、受限环境降级和指标字段已验证；Safari 与移动端的实际内存峰值、阶段切换帧时长和角色控制停顿仍需要性能 profile。
- 按用户既有决定，不执行第四章三层碰撞与遮挡浏览器专项校验。
- 本轮只运行普通 `npm run build`，未运行 `build:single`，未编辑 `demo/index.html`，未执行 Git 上传或任何 Git 写操作。

## 4. 复用规则

- 新的双模式交互应分别声明当前动作所属模式，禁止把另一模式的历史事实作为入口条件。
- 可重复只读交互优先使用“纯 intent 构造 → controller 权限与只读结果 → 纯展示解析”结构，生产场景和 validator 共用同一流程。
- 大型章节资源按玩家即将到达的阶段加载；缓存命中、失败、重试与受限环境降级必须进入同一可观察状态。
