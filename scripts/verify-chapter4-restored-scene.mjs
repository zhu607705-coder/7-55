import assert from 'node:assert/strict';
import fs from 'node:fs';
import ts from 'typescript';

const sourcePath = process.argv[2] ?? 'src/scenes/rpg/ChapterFourTemporalMazeScene.ts';
const source = fs.readFileSync(sourcePath, 'utf8');
const ast = ts.createSourceFile(sourcePath, source, ts.ScriptTarget.Latest, true);
const scene = ast.statements.find((node) => ts.isClassDeclaration(node)
  && node.name?.text === 'ChapterFourTemporalMazeScene');
assert.ok(scene, 'ChapterFourTemporalMazeScene exists');
const members = new Map(scene.members.map((node) => [node.name?.getText(ast), node.getText(ast)]));
const member = (name) => members.get(name) ?? '';
const checks = [
  ['raw evidence uses registered bindings and preserves authored clue shapes', () => {
    assert.match(member('syncEvidenceDetailRuntime'), /createEvidenceDetailRuntimeBinding/);
    assert.match(member('syncEvidenceDetailRuntime'), /evidenceDetailRuntime\.set\(placementId, binding\)/);
    assert.match(member('createEvidenceDetailRuntimeBinding'), /case "timeline"[\s\S]+detail.glyph/);
    assert.match(member('createEvidenceDetailRuntimeBinding'), /case "node"[\s\S]+detail.glyph/);
    assert.doesNotMatch(source, /createEvidenceDetailMark/);
  }],
  ['raw evidence and supporting chalkboard visuals share cleanup', () => {
    assert.match(member('syncEvidenceDetailRuntime'), /createClassroomChalkboardNotes/);
    assert.match(member('destroyEvidenceDetailRuntime'), /binding.container.destroy\(true\)/);
    assert.match(member('destroyEvidenceDetailRuntime'), /evidenceDetailObjects/);
  }],
  ['clock opens from the hall interaction', () => assert.match(member('handleStoryOrTravelInteraction'), /this\.openClockPanel\(spatial\)/)],
  ['clock submits controller-owned time adjustment', () => assert.match(member('submitClockPanelSelection'), /type: "adjust_hall_clock_time"/)],
  ['keyboard update runs while the clock panel is open', () => assert.match(member('update'), /this\.updateClockPanelKeyboard\(\)/)],
  ['clock request failure preserves its correction panel', () => assert.match(member('handleStoryIntentResolved'), /pending.intentType === "adjust_hall_clock_time" && this.clockPanel/)],
  ['installed parts no longer claim an automatic time jump', () => assert.doesNotMatch(member('handleStoryIntentResolved'), /时间已切换到 18:50|现在线索转入 22:45/)],
  ['context targets enter the actionable whitelist', () => assert.match(source, /TASK9_ACTIONABLE_TARGET_IDS[^;]+\.\.\.CHAPTER_FOUR_CONTEXT_INTERACTION_TARGET_IDS/)],
  ['context interaction uses the validated shared flow', () => assert.match(member('handleStoryOrTravelInteraction'), /createChapterFourContextInteractionIntent/)],
  ['context subtitles use committed result details', () => assert.match(member('handleStoryIntentResolved'), /resolveChapterFourContextInteractionSubtitle/)],
  ['inserted puzzle props reload after staged asset loading', () => assert.match(member('refreshLoadedChapterFourAssets'), /this\.createInsertedPuzzleProps\(\)/)],
  ['floor record is submitted from the elevator panel', () => assert.match(member('activateFloorPanelPrimary'), /observe_elevator_floor_record/)],
  ['stop chain submits both floor choices', () => assert.match(member('submitElevatorStopChain'), /reconstruct_elevator_stop_chain[\s\S]+actualArrivalFloor:[\s\S]+unservedCallFloor:/)],
  ['touch input operates clock and elevator deduction panels', () => assert.match(member('bindBridgeEvents'), /shiftClockPanelSelection[\s\S]+shiftElevatorDeductionArrival/)],
  ['conveyor fixture has belt, carriers and state light', () => assert.match(member('createBakeryConveyorFixture'), /tileSprite[\s\S]+carriers[\s\S]+bakeryConveyorStatusLight/)],
  ['conveyor slowdown is part of accepted stop presentation', () => assert.match(member('beginBakeryConveyorStopPresentation'), /slowBakeryConveyorMotion/)],
  ['bakery counter staff stays independent of transient pickup runtime', () => assert.match(member('syncPhaseRuntime'), /syncBakeryCounterStaff/)],
  ['conveyor cleanup removes every motion tween', () => assert.match(member('destroyBakeryConveyorFixture'), /for \(const tween of this.bakeryConveyorMotionTweens\) tween.remove\(\)/)],
  ['restored room remains presented according to shared selector', () => assert.match(member('syncRoom204Runtime'), /selectRoom204RuntimePresentation/)],
  ['room restoration retains four grouped placements', () => assert.match(member('handleStoryOrTravelInteraction'), /type: "place_room204_group"/)],
  ['stair entry requires A3 reference without inserted-puzzle completion gates', () => {
    assert.match(member('handleTravelInteraction'), /a3_reference_observed/);
    assert.doesNotMatch(member('handleTravelInteraction'), /insertedPuzzle|complete_inserted|classroom_104_chalk/);
  }],
  ['guard capture and scene epoch protections survive', () => {
    assert.match(member('update'), /if \(this.guardCaptureActive\) return/);
    assert.match(member('create'), /this.requestEpoch = \+\+chapterFourRequestEpoch/);
    assert.match(member('requestStoryIntent'), /this.requestEpoch/);
  }],
  ['source-pixel bounds and logical camera remain authoritative', () => {
    assert.match(member('configureCameraForCurrentFloor'), /this.physics.world.setBounds/);
    assert.match(member('configureCameraForCurrentFloor'), /setRpgLogicalCameraZoom/);
  }],
  ['capture and standalone chase-stair handoff remain wired', () => {
    assert.match(source, /presentGuardCapture/);
    assert.match(source, /CHASE_STAIR_HANDOFF_KEY/);
    assert.match(member('handleStoryIntentResolved'), /registry.remove\(CHASE_STAIR_HANDOFF_KEY\)/);
  }],
  ['wall-face and entrance occlusion stay tied to player foot depth', () => {
    assert.match(member('syncWallFaceOcclusion'), /visual\.playerRevealAlpha/);
    assert.match(member('syncWallFaceOcclusion'), /PLAYER_TOP_DEPTH \+ 1/);
    assert.match(member('syncMainEntranceForegroundDepth'), /MAIN_ENTRANCE_DOOR_RUNTIME\.sortY/);
    assert.match(member('syncMainEntranceDoorRuntime'), /ensureMainEntranceDoorFrame/);
    assert.match(member('destroyMainEntranceDoorRuntime'), /mainEntranceDoorBarrierCollider/);
    assert.match(member('create'), /syncMainEntranceDoorRuntime\(true\)[\s\S]*syncWallFaceOcclusion\(\)/);
    assert.match(member('update'), /syncMainEntranceDoorRuntime\(\)[\s\S]*syncWallFaceOcclusion\(\)/);
  }],
  ['alumni wall preserves authored floors, depth and nearby Space interaction', () => {
    assert.match(member('createAlumniHonorWallPortraits'), /getFloor\(figure\.floor\)/);
    assert.match(member('createAlumniHonorWallPortraits'), /wallDisplayDepth/);
    assert.doesNotMatch(member('createAlumniHonorWallPortraits'), /setInteractive|pointerdown/);
    assert.match(member('handleStoryOrTravelInteraction'), /if \(spacePressed\) this\.openAlumniPanel/);
    assert.match(member('openAlumniPanel'), /this\.currentFloor !== figure\.floor/);
    assert.match(member('openAlumniPanel'), /pointDistanceToRect[\s\S]*> 72/);
    assert.match(member('createAlumniHonorWallPortraits'), /this\.alumniWallObjects\.some/);
    assert.match(member('createAlumniHonorWallPortraits'), /figure\.drawRuntimeFrame/);
  }],
  ['scene does not submit final Zhu answers or lamp completion', () => assert.doesNotMatch(source, /type: "(?:submit_zhu_question_answers|complete_canruo_star_lamp)"/)],
  ['warmup keeps failure recovery and cancellation', () => {
    assert.match(member('retryRequiredWarmupPhase'), /phaseLoadRetryNotBeforeMs/);
    assert.match(member('bindBridgeEvents'), /phaseLoadCancelled = true/);
  }],
];
let failed = 0;
for (const [label, check] of checks) {
  try { check(); }
  catch (error) { failed++; console.error(`FAIL ${label}: ${error.message.split('\n')[0]}`); }
}
console.log(`Chapter 4 restored-scene regression: ${checks.length - failed}/${checks.length} passed`);
process.exitCode = failed ? 1 : 0;
