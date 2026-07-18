# Library CC98 Tiyi Puzzle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Build an 8–12 minute cross-app puzzle where a lost library seat is recovered through CC98 filtering and ranking, a ZJU Sports route puzzle, local photo evidence, and a final audited pass.

**Architecture:** Extend the existing `LibraryFinalsController` as the sole progression owner and keep puzzle interaction details in a typed `LibraryFinalsPuzzleState`. React scene components emit controller commands; controller commands emit domain events; `AudioDirector` consumes those events through JSON timelines without influencing game state.

**Tech Stack:** React 18, TypeScript, Zustand vanilla store, Vitest, CSS animations, Pointer Events, MiniMax CLI, FFmpeg, Vite single-file build.

---

## File Map

**Create**

- `src/modules/library-finals/puzzleRules.ts`: pure route, citation, `bd`, and audit validation.
- `src/modules/library-finals/puzzleRules.test.ts`: deterministic rules tests.
- `src/components/QuestClueStrip.tsx`: shared clue display and final drag source.
- `src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx`: floor filtering UI.
- `src/scenes/phone/P02_CC98/CitationChainPuzzle.tsx`: quoted-floor traversal.
- `src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx`: `bd` ranking and follow-up unlock.
- `src/scenes/phone/P06_Tiyi/RoutePuzzle.tsx`: pointer route and bicycle collision.
- `src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx`: discrete audit controls.
- `src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx`: local screenshot evidence.
- `src/data/library-finals.puzzle.json`: checkpoints, floors, thresholds, audit values, animation timing.

**Modify**

- `src/core/types.ts`: phases and puzzle state types.
- `src/core/GameState.ts`: initial puzzle state.
- `src/modules/LibraryFinalsController.ts`: guarded progression methods.
- `src/modules/LibraryFinalsController.test.ts`: end-to-end state/event assertions.
- `src/components/PhoneShell.tsx`: mount `QuestClueStrip` for active phases.
- `src/scenes/phone/P02_CC98/index.tsx`: select investigation, ranking, and follow-up views.
- `src/scenes/phone/P02_CC98/ThreadPage.tsx`: accept interactive floor content.
- `src/scenes/phone/P06_Tiyi/index.tsx`: select route or audit subview.
- `src/scenes/phone/P13_PhoneHome/index.tsx`: open photo evidence overlay.
- `src/scenes/phone/P15_Zjuding/index.tsx`: lost-seat and evidence drop target.
- `src/data/library-finals.content.json`: fictional floors, clues, labels, narration.
- `src/data/library-finals.audio.json`: event timelines.
- `src/data/library-finals.audio.generated.json`: generated durations.
- `scripts/generate-library-finals-audio.mjs`: new asset prompts and validation.
- `src/main.tsx`: debug phases and `render_game_to_text()` details.
- `src/styles/scenes.css`: all puzzle visuals and reduced-motion rules.
- `progress.md`: implementation and verification record.

## Task 1: Typed Puzzle State and Pure Rules

**Files:**
- Create: `src/modules/library-finals/puzzleRules.ts`
- Create: `src/modules/library-finals/puzzleRules.test.ts`
- Modify: `src/core/types.ts`
- Modify: `src/core/GameState.ts`

- [x] **Step 1: Add failing pure-rule tests**

```ts
import { describe, expect, it } from "vitest";
import { advanceCitation, validateAudit, validateRoute } from "./puzzleRules";

describe("library finals puzzle rules", () => {
  it("accepts only the ordered route", () => {
    expect(validateRoute(["north_gate", "bridge", "south_second_floor"])).toBe(true);
    expect(validateRoute(["bridge", "north_gate", "south_second_floor"])).toBe(false);
  });

  it("caps citation traversal at two links", () => {
    expect(advanceCitation(0)).toBe(1);
    expect(advanceCitation(1)).toBe(2);
    expect(advanceCitation(2)).toBe(2);
  });

  it("requires the 7-47-3 audit values", () => {
    expect(validateAudit({ pace: 7, count: 47, radius: 3 })).toBe(true);
    expect(validateAudit({ pace: 7, count: 46, radius: 3 })).toBe(false);
  });
});
```

- [x] **Step 2: Run the focused test and confirm failure**

Run: `npx vitest run src/modules/library-finals/puzzleRules.test.ts`  
Expected: FAIL because `puzzleRules.ts` does not exist.

- [x] **Step 3: Add route and puzzle types**

Add `RoutePointId`, the expanded `LibraryFinalsPhase`, and `LibraryFinalsPuzzleState` exactly as defined in the design spec. Add `libraryFinalsPuzzle` to `UiState`.

- [x] **Step 4: Implement pure rules**

```ts
import type { RoutePointId } from "../../core/types";

const EXPECTED_ROUTE: RoutePointId[] = ["north_gate", "bridge", "south_second_floor"];

export function validateRoute(route: RoutePointId[]): boolean {
  return route.length === EXPECTED_ROUTE.length && route.every((point, index) => point === EXPECTED_ROUTE[index]);
}

export function advanceCitation(depth: 0 | 1 | 2): 0 | 1 | 2 {
  return Math.min(2, depth + 1) as 0 | 1 | 2;
}

export function validateAudit(values: { pace: number; count: number; radius: number }): boolean {
  return values.pace === 7 && values.count === 47 && values.radius === 3;
}
```

- [x] **Step 5: Initialize puzzle state**

Set filter false, counts zero, route empty, evidence false, code null, audit values `0`, and clues empty in `createInitialGameState()`.

- [x] **Step 6: Run the focused test**

Run: `npx vitest run src/modules/library-finals/puzzleRules.test.ts`  
Expected: 3 tests PASS.

## Task 2: Controller Progression and Domain Events

**Files:**
- Modify: `src/modules/LibraryFinalsController.ts`
- Modify: `src/modules/LibraryFinalsController.test.ts`

- [x] **Step 1: Replace the old happy-path test with the confirmed C flow**

```ts
expect(controller.reserveSeat("022")).toBe(true);
expect(controller.loseSeat()).toBe(true);
expect(controller.setAc01Filter(true, 18)).toBe(true);
expect(controller.followCitation()).toBe(true);
expect(controller.followCitation()).toBe(true);
expect(controller.startRoute()).toBe(true);
expect(controller.completeRoute(["north_gate", "bridge", "south_second_floor"])).toBe(true);
expect(controller.applyBd("reply-route")).toBe(true);
expect(controller.applyBd("reply-photo")).toBe(true);
expect(controller.applyBd("reply-rule")).toBe(true);
expect(controller.revealRecoveryCode()).toBe(true);
expect(controller.submitAudit({ pace: 7, count: 47, radius: 3 })).toBe(true);
expect(controller.recoverSeat()).toBe(true);
expect(store.getState().ui.libraryFinalsPhase).toBe("seat_recovered");
```

- [x] **Step 2: Run the controller test and confirm failure**

Run: `npx vitest run src/modules/LibraryFinalsController.test.ts`  
Expected: FAIL because new methods and phases do not exist.

- [x] **Step 3: Implement guarded commands**

Add methods `setAc01Filter`, `followCitation`, `startRoute`, `completeRoute`, `applyBd`, `revealRecoveryCode`, and `submitAudit`. Each method must validate the current phase, patch puzzle state, emit one domain event, and return a boolean.

- [x] **Step 4: Preserve compatibility**

Keep `validatePass`, `reportBikeJam`, `openTopTen`, and `findMaterial` as compatibility wrappers that route old UI calls into the nearest new phase without skipping required puzzle state when the C flow is active.

- [x] **Step 5: Assert exact event order**

Expected event names:

```ts
[
  "library_finals_started",
  "library_seat_lost",
  "cc98_ac01_filtered",
  "cc98_citation_followed",
  "cc98_route_order_found",
  "tiyi_route_started",
  "tiyi_route_evidence_ready",
  "cc98_bd_applied",
  "cc98_bd_applied",
  "cc98_top_ten_reached",
  "cc98_recovery_code_found",
  "tiyi_audit_passed",
  "library_seat_recovered"
]
```

- [x] **Step 6: Run controller and rule tests**

Run: `npx vitest run src/modules/LibraryFinalsController.test.ts src/modules/library-finals/puzzleRules.test.ts`  
Expected: all tests PASS.

## Task 3: Puzzle Configuration and Clue Strip

**Files:**
- Create: `src/data/library-finals.puzzle.json`
- Create: `src/components/QuestClueStrip.tsx`
- Modify: `src/components/PhoneShell.tsx`
- Modify: `src/styles/scenes.css`

- [x] **Step 1: Add deterministic puzzle data**

```json
{
  "ac01FloorCount": 18,
  "targetFloor": 47,
  "citationFloors": [47, 12, 1],
  "routeOrder": ["north_gate", "bridge", "south_second_floor"],
  "bdRequired": 3,
  "recoveryCode": "7-47-3",
  "audit": { "pace": 7, "count": 47, "radius": 3 },
  "timing": { "floorFoldMs": 45, "rankMoveMs": 560, "auditRollbackMs": 800 }
}
```

- [x] **Step 2: Implement `QuestClueStrip`**

Render at most three 28px clue slots. Show labels only on focus/hover. When `route_audit_passed`, make the pass slot draggable with Pointer Events and emit `library_pass_drag_started`/`library_pass_drag_ended`.

- [x] **Step 3: Mount only during active phases**

In `PhoneShell`, render the strip when the phase is neither `idle`, `seat_reserved`, nor `seat_recovered`.

- [x] **Step 4: Add fixed dimensions and reduced motion**

Use `top: 44px`, `left: 8px`, `max-width: 164px`, and stable 28px slots. Under `prefers-reduced-motion`, remove slot translation and retain opacity changes.

- [x] **Step 5: Run typecheck**

Run: `npm run typecheck`  
Expected: PASS.

## Task 4: CC98 ac01 Filter and Citation Chain

**Files:**
- Create: `src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx`
- Create: `src/scenes/phone/P02_CC98/CitationChainPuzzle.tsx`
- Modify: `src/scenes/phone/P02_CC98/ThreadPage.tsx`
- Modify: `src/scenes/phone/P02_CC98/index.tsx`
- Modify: `src/data/library-finals.content.json`
- Modify: `src/styles/scenes.css`

- [x] **Step 1: Add 63 fictional floor descriptors**

Store 18 `ac01` floor IDs, three route floors, and compact filler floor descriptors in JSON. Generate repeated neutral floors in the component from descriptors; do not write 63 large text blocks.

- [x] **Step 2: Implement the filter control**

`Ac01FilterPuzzle` receives `enabled`, `hiddenCount`, and `onToggle`. It renders a segmented switch and uses `--fold-index` to stagger 18 fold animations at 45ms.

- [x] **Step 3: Reveal floor 47**

After the final fold transition, call `controller.setAc01Filter(true, 18)`, scroll floor 47 into view, and focus its quote button.

- [x] **Step 4: Implement citation traversal**

Render quoted cards `47 → 12 → 1`. Each valid click calls `followCitation()`. A non-quote click adds `.is-invalid` for 220ms without changing global progress.

- [x] **Step 5: Add accessible labels**

Use `aria-label="隐藏18条纯ac01回复"`, `aria-live="polite"` for hidden count, and unique quote labels such as `查看第12楼引用`.

- [x] **Step 6: Verify focused behavior**

Run: `npm run typecheck`  
Expected: PASS.  
Manual: filter reveals floor 47; two quote clicks produce route-order clues.

## Task 5: ZJU Sports Route Puzzle

**Files:**
- Create: `src/scenes/phone/P06_Tiyi/RoutePuzzle.tsx`
- Modify: `src/scenes/phone/P06_Tiyi/index.tsx`
- Modify: `src/styles/scenes.css`

- [x] **Step 1: Define stable route geometry**

Use a `360×520` internal board with percentage-positioned checkpoints. Keep board aspect ratio fixed so hit testing uses `getBoundingClientRect()` and remains correct at scaled phone sizes.

- [x] **Step 2: Implement global Pointer Events**

On `pointerdown`, call `setPointerCapture`; listen for `pointermove`, `pointerup`, and `pointercancel`. Convert client coordinates into board coordinates on every move. Do not reuse inventory snapping logic.

- [x] **Step 3: Sample route and validate checkpoints**

Append a route point after 8px movement. Mark a checkpoint visited within a 22px radius. Only accept the configured order.

- [x] **Step 4: Add three bicycle lanes**

Animate bicycle rectangles with CSS custom durations `1800ms`, `2200ms`, and `2600ms`. During drag, collision uses current element rectangles; on collision, reset to the last checkpoint.

- [x] **Step 5: Complete and capture evidence**

On the third checkpoint, call `completeRoute`, freeze the route, apply blue completion styling, emit a 120ms screenshot-flash overlay, and add `route_screenshot` to clue IDs.

- [x] **Step 6: Preserve original digit interaction**

Keep the existing clickable `47` digit when the finals route puzzle is inactive. During `route_active`, hide that hit target behind the route layer.

- [x] **Step 7: Verify mouse and touch release**

Manual: complete once with mouse and once using touch emulation; releasing outside the green marker must end dragging.

## Task 6: Local Photo Evidence Bridge

**Files:**
- Create: `src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx`
- Modify: `src/scenes/phone/P13_PhoneHome/index.tsx`
- Modify: `src/styles/scenes.css`

- [x] **Step 1: Replace the photo toast during the quest**

When `routeEvidenceReady` is true, the Photos button opens a bounded overlay containing one generated route card plus the existing “37 takeout screenshots and 1 plant” joke as non-interactive thumbnails.

- [x] **Step 2: Render evidence from state**

Use an SVG-free DOM/CSS miniature route based on visited checkpoints. The overlay must not serialize a real bitmap or upload data.

- [x] **Step 3: Attach evidence locally**

The “用于帖子” button calls a controller command that adds `route_screenshot_attached` and routes to CC98. It does not invoke any network API.

- [x] **Step 4: Add focus and escape behavior**

Focus the close button on open, close with `Escape`, and restore focus to the Photos app icon.

- [x] **Step 5: Run typecheck**

Run: `npm run typecheck`  
Expected: PASS.

## Task 7: bd Ranking and Top-Ten Follow-Up

**Files:**
- Create: `src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx`
- Modify: `src/scenes/phone/P02_CC98/index.tsx`
- Modify: `src/scenes/phone/P02_CC98/ThreadPage.tsx`
- Modify: `src/data/library-finals.content.json`
- Modify: `src/styles/scenes.css`

- [x] **Step 1: Render quest post at rank 04**

When screenshot evidence is attached, insert the quest post at index 3 with rank `04`. Keep all other default posts editable and unchanged.

- [x] **Step 2: Add three valid bd sources**

Use reply IDs `reply-route`, `reply-photo`, and `reply-rule`. Clicking each once calls `applyBd(id)`. Repeated clicks and pure image replies produce an invalid sound and no state change.

- [x] **Step 3: Animate one rank per valid bd**

Move the card using FLIP-style transform for 560ms, update rank only after the transform begins, and preserve list height.

- [x] **Step 4: Unlock the follow-up**

At three valid `bd` actions, stamp `01`, set `top_ten_reached`, and add a follow-up row. Opening it reveals the owner-only filter.

- [x] **Step 5: Reveal `7-47-3`**

The owner-only filter hides 18 filler replies. Three owner edit records expose the code parts. Calling `revealRecoveryCode()` adds the code clue and routes the next objective to ZJU Sports.

- [x] **Step 6: Verify keyboard access**

All `bd`, filter, quote, and follow-up controls must work with Enter and Space and have visible focus states.

## Task 8: Audit Rollback and Final Seat Drop

**Files:**
- Create: `src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx`
- Modify: `src/scenes/phone/P06_Tiyi/index.tsx`
- Modify: `src/scenes/phone/P15_Zjuding/index.tsx`
- Modify: `src/styles/scenes.css`

- [x] **Step 1: Show completion then rollback**

On entry with `recovery_code_found`, show green “完成”; after 800ms switch to yellow “待审核” and phase `route_audit_pending`.

- [x] **Step 2: Implement three discrete steppers**

Pace range `5–9`, count range `45–49`, radius range `1–4`. Initialize to `5`, `45`, `1`. Each step emits `tiyi_audit_value_changed` without narration.

- [x] **Step 3: Submit audit**

Call `submitAudit`. Wrong values show only the number of incorrect fields. Correct `7/47/3` adds `temporary_pass` and changes phase to `route_audit_passed`.

- [x] **Step 4: Add the seat drop target**

On the library seat map, accept the pass only over seat `022`. Use pointer coordinates against the rendered seat button rectangle. On miss, return the pass to the clue strip.

- [x] **Step 5: Complete the chapter**

On hit, call `recoverSeat`, restore blue highlight, update reservation text, and disable further drops.

- [x] **Step 6: Verify no layout shift**

Check that steppers, clue strip, and drop state keep fixed heights throughout animations.

## Task 9: Choreography and Reduced Motion

**Files:**
- Modify: `src/styles/scenes.css`
- Modify: `src/components/PhoneShell.tsx`
- Modify: `src/data/library-finals.puzzle.json`

- [x] **Step 1: Add named classes for every event state**

Add `.is-seat-lost`, `.is-folding`, `.is-floor-found`, `.is-route-complete`, `.is-rank-rising`, `.is-top-ten`, `.is-audit-rollback`, and `.is-seat-restored`.

- [x] **Step 2: Apply the confirmed timing values**

Seat loss `1600ms`, floor fold `45ms` stagger, citation `420ms`, rank rise `560ms`, audit rollback `800ms`, final restore `1800ms`.

- [x] **Step 3: Add screen shake only through EventBus**

Emit `screen_shake` with `strong: false` for seat rejection and collisions. Do not set PhoneShell shake classes from scene components.

- [x] **Step 4: Add reduced-motion equivalents**

Under `@media (prefers-reduced-motion: reduce)`, set translations to zero, durations to `1ms`, keep color changes, and stop bicycle lanes while preserving their collision rectangles outside the valid path.

- [x] **Step 5: Inspect at logical size**

Manual: inspect all eight phases at `430×930`; no text or controls may overlap the status bar or clue strip.

## Task 10: Narration, Music, and Sound Effects

**Files:**
- Modify: `src/data/library-finals.content.json`
- Modify: `src/data/library-finals.audio.json`
- Modify: `scripts/generate-library-finals-audio.mjs`
- Modify: `src/data/library-finals.audio.generated.json`
- Create assets under: `src/assets/audio/library-finals/{vo,music,sfx}/`

- [x] **Step 1: Add nine narration entries**

Use the nine approved draft lines from the design spec with one narrator identity. Assign stage-specific speed and pitch in the generator configuration.

- [x] **Step 2: Define six music prompts**

Generate distinct loops for library lost, CC98 investigation, route dragging, top-ten rise, audit, and recovery. Target 20–24 seconds each; no loop may share the same prompt.

- [x] **Step 3: Define custom sound prompts**

Generate seat reject, floor fold, floor reveal, route checkpoint, bicycle pass, collision brake, screenshot shutter, attachment drop, `bd` rise, rank flip, top-ten stamp, audit reverse, audit success, pass drop, and seat restore.

- [x] **Step 4: Extend audio events**

Add JSON timelines for controller events. Use `offsetMs`, `duckMusicTo`, and music replacement only; no gameplay callback may depend on `Audio` events.

- [x] **Step 5: Generate and normalize assets**

Run: `npm run audio:library-finals -- --timeout 180`  
Expected: all configured assets generated; FFmpeg normalization succeeds; durations are written to `library-finals.audio.generated.json`.

- [x] **Step 6: Validate asset inventory**

Run: `find src/assets/audio/library-finals -type f -name '*.mp3' | sort`  
Expected: every asset referenced by `library-finals.audio.json` has one MP3 file.

- [x] **Step 7: Check audio failure independence**

Temporarily block `Audio.play()` in the browser console and complete one transition. Expected: state advances and subtitles still appear.

## Task 11: Debug Observability and Verification

**Files:**
- Modify: `src/main.tsx`
- Modify: `progress.md`

- [x] **Step 1: Extend `render_game_to_text()`**

Include phase, filter state, hidden count, citation depth, route visited, evidence status, `bd` count, recovery code presence, audit values, and clue IDs.

- [x] **Step 2: Extend development query parameters**

Allow every new phase through `?scene=cc98&libraryFinalsPhase=...` and `?scene=tiyi&libraryFinalsPhase=...`. Reject unknown values.

- [x] **Step 3: Run focused logic tests**

Run: `npx vitest run src/modules/LibraryFinalsController.test.ts src/modules/library-finals/puzzleRules.test.ts`  
Expected: PASS.

- [x] **Step 4: Run typecheck**

Run: `npm run typecheck`  
Expected: PASS.

- [x] **Step 5: Perform manual browser verification**

Complete the full chain with mouse, then recheck route release with touch emulation. Inspect `430×930` and one scaled mobile viewport. Confirm subtitles do not cover active controls.

- [x] **Step 6: Build the standalone file**

Run: `npm run build:single`  
Expected: `demo/index.html` is regenerated with no external asset requirement.

- [ ] **Step 7: Open the final file directly**

Open `demo/index.html` through `file://`. Complete at least filter → citation → route and verify audio asset URLs work inside the single file.

Residual: the automated browser rejected direct `file://` navigation by policy. The build, inlining audit, source preview, and complete HTTP browser chain passed; keep this one item for the user's local hand-feel pass.

- [x] **Step 8: Record completion**

Add exact test counts, build size, visual viewports, known residual risks, and generated audio inventory to `progress.md`.

## Delivery Order

1. Tasks 1–2 produce a testable state machine.
2. Tasks 3–4 produce the first playable CC98 puzzle.
3. Tasks 5–6 complete the first app round trip.
4. Tasks 7–8 complete the second round trip and ending.
5. Tasks 9–10 add final choreography and audio.
6. Task 11 verifies and regenerates the single-file deliverable.
