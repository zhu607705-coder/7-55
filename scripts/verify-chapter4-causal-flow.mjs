#!/usr/bin/env node

import { readFile } from "node:fs/promises";
import { createServer } from "vite";

function assert(condition, message) {
  if (!condition) throw new Error(`[chapter4:validate-causal-flow] ${message}`);
}

const [layout, content, audio, hostSource, sceneSource, subtitleSource, powerPanelSource] = await Promise.all([
  readFile(new URL("../src/data/chapter4-three-floor-maze.layout.json", import.meta.url), "utf8").then(JSON.parse),
  readFile(new URL("../src/data/chapter4-755.content.json", import.meta.url), "utf8").then(JSON.parse),
  readFile(new URL("../src/data/chapter4-755.audio.json", import.meta.url), "utf8").then(JSON.parse),
  readFile(new URL("../src/scenes/rpg/RpgGameHost.tsx", import.meta.url), "utf8"),
  readFile(new URL("../src/scenes/rpg/ChapterFourTemporalMazeScene.ts", import.meta.url), "utf8"),
  readFile(new URL("../src/components/RpgSubtitleLayer.tsx", import.meta.url), "utf8"),
  readFile(new URL("../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx", import.meta.url), "utf8")
]);

assert(layout.evidenceDetails.length === 30, "exactly 30 source-pixel raw details are required");
assert(content.evidenceContracts.length === 11, "exactly 11 causal evidence contracts are required");
assert(content.room204.groups.length === 4, "Room204 must expose four grouped operations");
assert(content.room204.groups.every((group) => group.mappings.length === 3), "each Room204 group must atomically place three legacy pieces");
assert(content.transitionContracts.length === 8, "the Chapter 4 sequence must declare eight transitions");
assert(content.transitionContracts.filter((entry) => entry.owner === "transition_overlay").length === 4, "only four genuine time changes may own overlays");
assert(content.transitionContracts.filter((entry) => entry.owner === "scene_interaction").length === 4, "four world handoffs must stay inside the scene");
assert(Boolean(audio.events.chapter4_environment_hint_pulse?.cues?.some((cue) => cue.panFromEvent === true)), "adaptive environment sound must consume scene position");
assert(Boolean(audio.events.power_grid_locked?.cues?.some((cue) => cue.channel === "sfx")), "power-grid success must have an audible confirmation cue");
assert(/selectChapterFourTransitionPresentation\(result\)/.test(hostSource) && /<ChapterFourTransitionOverlay/.test(hostSource), "Host must mount the selected time transition overlay");
assert(/rpg_chapter4_power_panel_attempt_abandoned/.test(hostSource) && /recordVisualHintFailure\("power_route_comparison"\)/.test(sceneSource), "closing an unfinished power panel must count as one help attempt");
assert(/allZonesPowered[\s\S]*?总负载过高。核对已记录的必要路线，关闭旁路回路。/.test(powerPanelSource), "all-on power state must explain that the necessary route is still unresolved");
assert(/CHAPTER_FOUR_LIGHT_GRID\.zones\.map[\s\S]*?data-fixture-zone=\{zone\.id\}[\s\S]*?className=\{on \? "is-on" : "is-off"\}/.test(powerPanelSource), "physical breaker indicators must mirror all five diagram zone states");
assert(/beginPowerGridSuccessPresentation[\s\S]*?chapter4_power_grid_success_presentation_completed/.test(sceneSource), "solved power grid must run a scene-owned success presentation before the chase handoff");
assert(/storyPresentation === "power_grid_success"[\s\S]*?guard\.setVelocity\(0, 0\)\.setVisible\(false\)/.test(sceneSource), "final-chase guard must remain paused while the power-grid success presentation owns input");
assert(/if \(blocked\) return;/.test(subtitleSource), "subtitle surface must stay suppressed while an overlay owns presentation");
assert(!/字幕.*(?:房间|路线|答案)/.test(JSON.stringify(content.evidenceContracts)), "evidence contracts must remain raw-detail contracts");

const server = await createServer({
  root: new URL("../", import.meta.url).pathname,
  configFile: false,
  appType: "custom",
  logLevel: "error",
  optimizeDeps: { noDiscovery: true, include: [] },
  server: { middlewareMode: true, ws: false }
});

try {
  const [evidenceModule, hintModule, transitionModule, room204Module] = await Promise.all([
    server.ssrLoadModule("/src/modules/ChapterFourEvidenceCausality.ts"),
    server.ssrLoadModule("/src/modules/ChapterFourVisualHintModel.ts"),
    server.ssrLoadModule("/src/modules/ChapterFourTransitionPresentation.ts"),
    server.ssrLoadModule("/src/scenes/rpg/ChapterFourRoom204Model.ts")
  ]);

  assert(evidenceModule.CHAPTER_FOUR_EVIDENCE_VALIDATION.contractCount === 11, "evidence validation count mismatch");
  assert(evidenceModule.CHAPTER_FOUR_EVIDENCE_VALIDATION.rawDetailCount === 30, "raw detail validation count mismatch");
  assert(evidenceModule.CHAPTER_FOUR_EVIDENCE_VALIDATION.multiPhaseReuseCount > 0, "at least one clue must be reused after multiple phases");
  assert(transitionModule.CHAPTER_FOUR_TRANSITION_PRESENTATION_VALIDATION.overlayCount === 4, "time overlay ownership mismatch");
  assert(transitionModule.CHAPTER_FOUR_TRANSITION_PRESENTATION_VALIDATION.worldHandoffCount === 4, "world handoff ownership mismatch");

  const knownDetailIds = new Set(layout.evidenceDetails.map((detail) => detail.id));
  const hintValidation = hintModule.validateChapterFourVisualHintContracts(knownDetailIds);
  assert(hintValidation.puzzleCount === 9 && hintValidation.maximumFailureCount === 4, "adaptive hint contract mismatch");
  let hintModel = hintModule.createChapterFourVisualHintModel();
  const levels = [];
  const counts = [];
  for (let attempt = 0; attempt < 5; attempt += 1) {
    hintModel = hintModule.recordChapterFourVisualHintFailure(hintModel, "bakery_trace_comparison");
    const session = hintModule.selectChapterFourVisualHintSession(hintModel, "bakery_trace_comparison");
    levels.push(session.level);
    counts.push(session.failureCount);
  }
  assert(levels.join(",") === "0,1,2,3,3", "help levels must ease only after repeated failure");
  assert(counts.join(",") === "1,2,3,4,4", "failure count must clamp after four attempts");
  assert(hintModule.selectChapterFourVisualHintSession(hintModel, "bakery_trace_comparison").pairedDetailIds.length === 2, "fourth failure must compare exactly two raw facts");

  let placements = [];
  for (const groupId of room204Module.ROOM204_GROUP_ORDER) {
    const result = room204Module.resolveRoom204GroupPlacement(placements, { groupId, targetGroupId: groupId });
    assert(result.accepted, `Room204 group ${groupId} must be accepted`);
    placements = result.placements;
  }
  assert(room204Module.countCompletedRoom204Groups(placements) === 4, "Room204 must complete in four grouped operations");
  assert(placements.length === 12, "grouped operations must preserve the twelve-piece save format");

  console.log(`chapter4 causal flow PASS evidence=${content.evidenceContracts.length} details=${layout.evidenceDetails.length} reused=${evidenceModule.CHAPTER_FOUR_EVIDENCE_VALIDATION.multiPhaseReuseCount} room204Groups=4 hintLevels=${levels.join("/")} transitions=4+4`);
} finally {
  await server.close();
}
