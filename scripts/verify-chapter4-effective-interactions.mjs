import fs from "node:fs";
import { createServer } from "vite";

const errors = [];
let assertionCount = 0;

function assert(condition, message) {
  assertionCount += 1;
  if (!condition) errors.push(message);
}

function snapshot(value) {
  return JSON.stringify(value);
}

const expectedEntries = Object.freeze([
  ["a1_front_desk_duty_board_context", "A1", "a1_front_desk_duty_board", "duty_board"],
  ["a2_maker_workshop_201_context", "A2", "a2_201_calibration_bench", "positioning_calibration"],
  ["a2_lecture_room_202_context", "A2", "lecture_room_202", null],
  ["a2_computer_room_203_context", "A2", "a2_203_circuit_terminal", "power_topology"],
  ["a2_open_study_evacuation_context", "A2", "a2_open_study_evacuation", "evacuation_route"],
  ["a3_archive_exhibition_301_context", "A3", "a3_301_archive_index", "archive_index"],
  ["a3_media_studio_302_context", "A3", "a3_302_alignment_scanner", "media_alignment"],
  ["a3_report_hall_304_context", "A3", "report_hall_304", null]
]);
const timeStates = Object.freeze([
  "2245_opening",
  "1225_bakery",
  "1850_evening",
  "2245_maintenance",
  "0754_blackout",
  "0755_morning"
]);
const modes = Object.freeze(["light", "dark"]);

const layout = JSON.parse(fs.readFileSync(
  new URL("../src/data/chapter4-three-floor-maze.layout.json", import.meta.url),
  "utf8"
));
const controllerSource = fs.readFileSync(
  new URL("../src/modules/ChapterFourTemporalMazeController.ts", import.meta.url),
  "utf8"
);
const sceneSource = fs.readFileSync(
  new URL("../src/scenes/rpg/ChapterFourTemporalMazeScene.ts", import.meta.url),
  "utf8"
);
const contentSource = fs.readFileSync(
  new URL("../src/data/ChapterFourInteractionContent.ts", import.meta.url),
  "utf8"
);

const server = await createServer({
  configFile: false,
  appType: "custom",
  logLevel: "error",
  optimizeDeps: { noDiscovery: true, include: [] },
  server: { middlewareMode: true, ws: false }
});

try {
  const [
    gameStateModule,
    eventBusModule,
    contentModule,
    interactionModule,
    flowModule,
    controllerModule,
    projectionModule,
    insertedPuzzleModule
  ] = await Promise.all([
    server.ssrLoadModule("/src/core/GameState.ts"),
    server.ssrLoadModule("/src/core/EventBus.ts"),
    server.ssrLoadModule("/src/data/ChapterFourInteractionContent.ts"),
    server.ssrLoadModule("/src/scenes/rpg/RpgInteractionContract.ts"),
    server.ssrLoadModule("/src/scenes/rpg/ChapterFourContextInteractionFlow.ts"),
    server.ssrLoadModule("/src/modules/ChapterFourTemporalMazeController.ts"),
    server.ssrLoadModule("/src/modules/ChapterFourMazeProjection.ts"),
    server.ssrLoadModule("/src/modules/ChapterFourInsertedPuzzleModel.ts")
  ]);

  const { createGameStore, createInitialGameState } = gameStateModule;
  const { EventBus } = eventBusModule;
  const {
    CHAPTER_FOUR_CONTEXT_INTERACTIONS,
    CHAPTER_FOUR_CONTEXT_INTERACTION_TARGET_IDS,
    selectChapterFourContextInteractionText
  } = contentModule;
  const {
    CHAPTER_FOUR_755_INTERACTION_TARGETS,
    isPointInsideChapterFour755Bounds
  } = interactionModule;
  const {
    createChapterFourContextInteractionIntent,
    resolveChapterFourContextInteractionSubtitle
  } = flowModule;
  const { ChapterFourTemporalMazeController } = controllerModule;
  const { selectChapterFourMazeProjection } = projectionModule;
  const {
    CHAPTER_FOUR_INSERTED_PUZZLES,
    chapterFourInsertedPuzzleForTarget
  } = insertedPuzzleModule;

  assert(
    CHAPTER_FOUR_CONTEXT_INTERACTIONS.length === expectedEntries.length,
    "content catalog must contain the six inserted puzzles and two read-only room interactions"
  );
  assert(
    snapshot(CHAPTER_FOUR_CONTEXT_INTERACTION_TARGET_IDS) === snapshot(expectedEntries.map(([id]) => id)),
    "exported context target ids must preserve the approved eight-target order"
  );

  const floorById = new Map(layout.floors.map((floor) => [floor.storyFloor, floor]));
  for (const [targetId, floorId, anchorId, puzzleId] of expectedEntries) {
    const entry = CHAPTER_FOUR_CONTEXT_INTERACTIONS.find((candidate) => candidate.targetId === targetId);
    const target = CHAPTER_FOUR_755_INTERACTION_TARGETS[targetId];
    const floor = floorById.get(floorId);
    const anchor = floor?.anchors.find((candidate) => candidate.id === anchorId);

    assert(Boolean(entry), `${targetId} must exist in the content catalog`);
    assert(Boolean(target), `${targetId} must exist in the RPG interaction contract`);
    assert(Boolean(anchor), `${floorId}/${anchorId} must exist in the source-pixel layout`);
    if (!entry || !target || !floor || !anchor) continue;

    assert(entry.floor === floorId && entry.anchorId === anchorId, `${targetId} must retain its authored floor and anchor`);
    assert(entry.activePhases.length === 1 && entry.activePhases[0] === "room204_restore", `${targetId} must avoid chase and final-minute phases`);
    assert(entry.repeatPolicy === "repeatable", `${targetId} must stay repeatable and optional`);
    assert(entry.roomAliases.length > 0, `${targetId} must declare reachable runtime room aliases`);
    assert(
      chapterFourInsertedPuzzleForTarget(targetId) === puzzleId,
      `${targetId} must retain its inserted-puzzle classification`
    );
    if (puzzleId) {
      assert(
        CHAPTER_FOUR_INSERTED_PUZZLES[puzzleId]?.targetId === targetId,
        `${targetId} must resolve to the matching inserted-puzzle definition`
      );
    }

    for (const timeState of timeStates) {
      const lightText = selectChapterFourContextInteractionText({
        targetId,
        phase: "room204_restore",
        timeState,
        mode: "light"
      });
      const darkText = selectChapterFourContextInteractionText({
        targetId,
        phase: "room204_restore",
        timeState,
        mode: "dark"
      });
      assert(typeof lightText === "string" && lightText.trim().length > 0, `${targetId}/${timeState}/light must have readable text`);
      assert(typeof darkText === "string" && darkText.trim().length > 0, `${targetId}/${timeState}/dark must have readable text`);
      assert(lightText !== darkText, `${targetId}/${timeState} must provide a real light/dark context difference`);
    }
    assert(
      selectChapterFourContextInteractionText({
        targetId,
        phase: "maintenance_repair",
        timeState: "2245_maintenance",
        mode: "light"
      }) === null,
      `${targetId} content must be withheld outside its conflict-free phase`
    );

    assert(target.activation === "phase_exclusive", `${targetId} must be a state-projected interaction`);
    assert(target.activationCondition.id === "context_interaction_available", `${targetId} must use the shared context selector condition`);
    assert(target.requiredMode === undefined && target.requiredModeByPhase === undefined, `${targetId} must work in either reality mode without order gating`);
    assert(target.acceptedItem === undefined && target.acceptedItemByPhase === undefined, `${targetId} must not consume an item`);
    assert(target.collision === false && target.approximate === false && target.contractPending === false, `${targetId} must be a precise interaction-only rectangle`);
    assert(
      target.boundsSource.kind === "layout_anchor"
        && target.boundsSource.floor === floorId
        && target.boundsSource.anchorId === anchorId,
      `${targetId} must resolve from the exact source-pixel anchor`
    );
    assert(snapshot(target.bounds) === snapshot(anchor.bounds), `${targetId} bounds must equal the authored anchor bounds`);

    const center = {
      x: anchor.bounds.x + anchor.bounds.width / 2,
      y: anchor.bounds.y + anchor.bounds.height / 2
    };
    assert(
      isPointInsideChapterFour755Bounds(anchor.bounds, center.x, center.y),
      `${targetId} authored anchor center must stay inside its half-open bounds`
    );
    const centerBlocked = floor.staticCollisions.some((collision) => (
      isPointInsideChapterFour755Bounds(collision, center.x, center.y)
    ));
    if (puzzleId) {
      const standSamples = [
        { x: center.x, y: anchor.bounds.y - 8 },
        { x: center.x, y: anchor.bounds.y + anchor.bounds.height + 8 },
        { x: anchor.bounds.x - 8, y: center.y },
        { x: anchor.bounds.x + anchor.bounds.width + 8, y: center.y }
      ].filter((point) => (
        point.x >= 0
          && point.y >= 0
          && point.x < layout.worldSize.width
          && point.y < layout.worldSize.height
          && !floor.staticCollisions.some((collision) => (
            isPointInsideChapterFour755Bounds(collision, point.x, point.y)
          ))
      ));
      assert(
        standSamples.length > 0,
        `${targetId} tabletop prop must retain a collision-free stand point within interaction range`
      );
    } else {
      assert(!centerBlocked, `${targetId} read-only room anchor center must stay on walkable floor`);
    }
    const clearInteriorSamples = [
      [0.25, 0.25],
      [0.75, 0.25],
      [0.25, 0.75],
      [0.75, 0.75]
    ].map(([xRatio, yRatio]) => ({
      x: anchor.bounds.x + anchor.bounds.width * xRatio,
      y: anchor.bounds.y + anchor.bounds.height * yRatio
    })).filter((point) => !floor.staticCollisions.some((collision) => (
      isPointInsideChapterFour755Bounds(collision, point.x, point.y)
    )));
    assert(
      clearInteriorSamples.length > 0,
      `${targetId} must retain at least one additional interior sample outside static collisions`
    );
  }

  function makeState(entry, mode = "light", phase = "room204_restore") {
    const initial = createInitialGameState();
    const checkpointByFloor = {
      A1: "c4_a1_lobby",
      A2: "c4_a2_corridor",
      A3: "c4_a3_wayfinding"
    };
    const roomByFloor = {
      A1: "a1_lobby",
      A2: "a2_corridor",
      A3: "a3_wayfinding"
    };
    return {
      ...initial,
      runtimeMode: "rpg",
      rpgScene: "duan_yongping_temporal_maze",
      rpgCheckpoint: checkpointByFloor[entry.floor],
      qizhenLake: { ...initial.qizhenLake, phase: "complete", active: false },
      chapterThreeInterlude: {
        ...initial.chapterThreeInterlude,
        phase: "complete",
        replayUnlocked: true,
        completed: true
      },
      chapter4: {
        ...initial.chapter4,
        prologueSeen: true,
        phase,
        mode,
        building: "A",
        floor: entry.floor,
        roomId: roomByFloor[entry.floor],
        timeAuthority: "hall_clock",
        timeState: phase === "room204_restore" ? "1850_evening" : "2245_maintenance",
        worldTimeSeconds: phase === "room204_restore" ? 67800 : 81900,
        phoneStatusTimeSeconds: phase === "room204_restore" ? 67800 : 81900,
        phoneStatusTimeTrusted: true,
        factIds: ["hour_hand_installed"]
      }
    };
  }

  for (const floorId of ["A1", "A2", "A3"]) {
    const floorEntries = CHAPTER_FOUR_CONTEXT_INTERACTIONS.filter((entry) => entry.floor === floorId);
    const projection = selectChapterFourMazeProjection(makeState(floorEntries[0]));
    for (const entry of CHAPTER_FOUR_CONTEXT_INTERACTIONS) {
      assert(
        projection.availableTargetIds.includes(entry.targetId) === (entry.floor === floorId),
        `${floorId} projection must expose only its floor-local context targets (${entry.targetId})`
      );
    }
  }

  const modeOrders = Object.freeze([
    ["light", "dark"],
    ["dark", "light"]
  ]);

  for (const entry of CHAPTER_FOUR_CONTEXT_INTERACTIONS) {
    const puzzleId = chapterFourInsertedPuzzleForTarget(entry.targetId);
    for (const modeOrder of modeOrders) {
      const store = createGameStore(makeState(entry, modeOrder[0]));
      const events = new EventBus();
      const controller = new ChapterFourTemporalMazeController(store, events);
      const subtitles = [];
      for (let index = 0; index < modeOrder.length; index += 1) {
        const mode = modeOrder[index];
        if (index > 0) {
          const modeResult = controller.resolve755Intent({ type: "set_mode", mode });
          assert(
            modeResult.accepted === true && store.getState().chapter4.mode === mode,
            `${entry.targetId}/${modeOrder.join("->")} must allow switching to ${mode} without a context-order gate`
          );
        }
        const before = snapshot(store.getState());
        const intent = createChapterFourContextInteractionIntent({
          targetId: entry.targetId,
          spatial: { distance: "within_range" }
        });
        assert(Boolean(intent), `${entry.targetId}/${modeOrder.join("->")}/${mode} pure flow must construct an intent`);
        if (!intent) continue;
        const result = controller.resolve755Intent(intent);
        const current = store.getState();
        const subtitle = resolveChapterFourContextInteractionSubtitle({
          targetId: intent.targetId,
          phase: current.chapter4.phase,
          timeState: current.chapter4.timeState,
          mode: current.chapter4.mode,
          result
        });
        assert(
          result.accepted === true && result.changed === false,
          `${entry.targetId}/${modeOrder.join("->")}/${mode} pure flow must reach an accepted read-only controller result`
        );
        assert(
          snapshot(store.getState()) === before,
          `${entry.targetId}/${modeOrder.join("->")}/${mode} context resolution must write zero controller state`
        );
        const expectedText = selectChapterFourContextInteractionText({
          targetId: entry.targetId,
          phase: current.chapter4.phase,
          timeState: current.chapter4.timeState,
          mode: current.chapter4.mode
        });
        if (puzzleId) {
          const requestEvent = events.getHistory().find((event) => (
            event.name === "chapter4_inserted_puzzle_requested"
              && event.payload?.targetId === entry.targetId
              && event.payload?.mode === mode
          ));
          assert(subtitle === null, `${entry.targetId}/${mode} puzzle request must not emit a read-only subtitle`);
          assert(
            requestEvent?.payload?.puzzleId === puzzleId,
            `${entry.targetId}/${mode} must emit its controller-owned puzzle request`
          );
        } else {
          assert(
            subtitle?.text === expectedText
              && subtitle?.tone === "system"
              && subtitle?.durationMs === 4400,
            `${entry.targetId}/${modeOrder.join("->")}/${mode} pure flow must close on its time/mode subtitle`
          );
          if (subtitle) subtitles.push(subtitle.text);
        }
      }
      assert(
        puzzleId
          ? subtitles.length === 0
          : subtitles.length === 2 && subtitles[0] !== subtitles[1],
        puzzleId
          ? `${entry.targetId}/${modeOrder.join("->")} must open the puzzle without a duplicate subtitle`
          : `${entry.targetId}/${modeOrder.join("->")} must preserve two distinct read-only subtitles in either order`
      );
    }

    for (const mode of modes) {
      const state = makeState(entry, mode);
      const distantStore = createGameStore(state);
      const distantController = new ChapterFourTemporalMazeController(distantStore, new EventBus());
      const distantBefore = snapshot(distantStore.getState());
      const distantIntent = createChapterFourContextInteractionIntent({
        targetId: entry.targetId,
        spatial: { distance: "too_far" }
      });
      assert(Boolean(distantIntent), `${entry.targetId}/${mode} pure flow must construct the distant intent`);
      if (!distantIntent) continue;
      const distant = distantController.resolve755Intent(distantIntent);
      const distantSubtitle = resolveChapterFourContextInteractionSubtitle({
        targetId: distantIntent.targetId,
        phase: state.chapter4.phase,
        timeState: state.chapter4.timeState,
        mode: state.chapter4.mode,
        result: distant
      });
      assert(distant.accepted === false && distant.changed === false && distant.reason === "too_far", `${entry.targetId}/${mode} must enforce actual proximity`);
      assert(distantSubtitle === null, `${entry.targetId}/${mode} rejected proximity must not emit a context subtitle`);
      assert(snapshot(distantStore.getState()) === distantBefore, `${entry.targetId}/${mode} distant rejection must write zero state`);
    }

    const conflictState = makeState(entry, "light", "maintenance_repair");
    const conflictStore = createGameStore(conflictState);
    const conflictController = new ChapterFourTemporalMazeController(conflictStore, new EventBus());
    const conflictBefore = snapshot(conflictStore.getState());
    const conflictIntent = createChapterFourContextInteractionIntent({
      targetId: entry.targetId,
      spatial: { distance: "within_range" }
    });
    assert(Boolean(conflictIntent), `${entry.targetId} pure flow must construct the inactive-phase intent`);
    if (!conflictIntent) continue;
    const conflict = conflictController.resolve755Intent(conflictIntent);
    const conflictSubtitle = resolveChapterFourContextInteractionSubtitle({
      targetId: conflictIntent.targetId,
      phase: conflictState.chapter4.phase,
      timeState: conflictState.chapter4.timeState,
      mode: conflictState.chapter4.mode,
      result: conflict
    });
    assert(conflict.accepted === false && conflict.changed === false && conflict.reason === "locked", `${entry.targetId} must stay inactive during maintenance conflict phases`);
    assert(conflictSubtitle === null, `${entry.targetId} inactive phase must not emit a context subtitle`);
    assert(snapshot(conflictStore.getState()) === conflictBefore, `${entry.targetId} conflict rejection must write zero state`);
  }

  const readOnlyCaseStart = controllerSource.indexOf('case "inspect_chapter_four_context":');
  const readOnlyCaseEnd = controllerSource.indexOf('case "complete_inserted_puzzle":', readOnlyCaseStart);
  const readOnlyCase = controllerSource.slice(readOnlyCaseStart, readOnlyCaseEnd);
  assert(readOnlyCase.includes("return acceptReadOnly();"), "controller must route context inspection through its unified read-only result");
  assert(
    readOnlyCase.includes('this.emitChapterFourCue("chapter4_inserted_puzzle_requested"'),
    "controller must route inserted targets to the host-owned puzzle overlay"
  );
  assert(!/(patchChapter|transition|appendFact|withItem)\s*\(/.test(readOnlyCase), "context intent must not mutate facts, phase, or inventory");
  for (const [targetId] of expectedEntries) {
    assert(!controllerSource.includes(`"${targetId}"`), `${targetId} must not be hard-coded into progression gates`);
  }
  assert(!/(factIds|optionalFactId|transition|inventory|items)\s*:/.test(contentSource), "content catalog must remain free of progression writes and item rewards");
  assert(sceneSource.includes("...CHAPTER_FOUR_CONTEXT_INTERACTION_TARGET_IDS"), "scene actionable sets must include all context targets");
  assert(
    sceneSource.includes("Phaser.Input.Keyboard.JustDown(this.interactKey)")
      && sceneSource.includes("this.handleStoryOrTravelInteraction();"),
    "keyboard-binding-only check: Space must still enter the shared story/travel handler"
  );
  assert(
    sceneSource.includes("createChapterFourContextInteractionIntent({"),
    "production scene must use the executable pure flow to construct context intents"
  );
  assert(
    sceneSource.includes("resolveChapterFourContextInteractionSubtitle({"),
    "production scene must use the executable pure flow to resolve time/mode subtitles"
  );
} finally {
  await server.close();
}

if (errors.length > 0) {
  console.error(`Chapter 4 effective-interaction validation failed (${errors.length}/${assertionCount})`);
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}

console.log(`Chapter 4 effective-interaction validation passed (${assertionCount} assertions).`);
