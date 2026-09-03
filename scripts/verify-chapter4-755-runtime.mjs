import fs from "node:fs";
import { createServer } from "vite";

const errors = [];
let assertionCount = 0;

function assert(condition, message) {
  assertionCount += 1;
  if (!condition) errors.push(message);
}

function sameJson(actual, expected) {
  return JSON.stringify(actual) === JSON.stringify(expected);
}

function snapshot(value) {
  return JSON.stringify(value);
}

class MemoryStorage {
  #values = new Map();

  get length() { return this.#values.size; }
  clear() { this.#values.clear(); }
  getItem(key) { return this.#values.has(key) ? this.#values.get(key) : null; }
  key(index) { return [...this.#values.keys()][index] ?? null; }
  removeItem(key) { this.#values.delete(key); }
  setItem(key, value) { this.#values.set(String(key), String(value)); }
}

const server = await createServer({
  configFile: false,
  appType: "custom",
  logLevel: "error",
  optimizeDeps: { noDiscovery: true, include: [] },
  server: { middlewareMode: true, ws: false }
});

const chapterFourLayout = JSON.parse(fs.readFileSync(
  new URL("../src/data/chapter4-three-floor-maze.layout.json", import.meta.url),
  "utf8"
));

try {
  const [
    gameStateModule,
    eventBusModule,
    controllerModule,
    interactionModule,
    projectionModule,
    questModule,
    saveStoreModule,
    room204Module,
    guardModule,
    lightGridModule,
    finalChaseModule,
    itemUseGuidanceModule,
    elevatorDepthModule,
    storageKeysModule
  ] = await Promise.all([
    server.ssrLoadModule("/src/core/GameState.ts"),
    server.ssrLoadModule("/src/core/EventBus.ts"),
    server.ssrLoadModule("/src/modules/ChapterFourTemporalMazeController.ts"),
    server.ssrLoadModule("/src/scenes/rpg/RpgInteractionContract.ts"),
    server.ssrLoadModule("/src/modules/ChapterFourMazeProjection.ts"),
    server.ssrLoadModule("/src/core/QuestModel.ts"),
    server.ssrLoadModule("/src/core/SaveStore.ts"),
    server.ssrLoadModule("/src/scenes/rpg/ChapterFourRoom204Model.ts"),
    server.ssrLoadModule("/src/modules/ChapterFourGuardModel.ts"),
    server.ssrLoadModule("/src/modules/ChapterFourLightGridModel.ts"),
    server.ssrLoadModule("/src/modules/ChapterFourFinalChaseModel.ts"),
    server.ssrLoadModule("/src/scenes/rpg/RpgItemUseGuidance.ts"),
    server.ssrLoadModule("/src/modules/ChapterFourElevatorDepthModel.ts"),
    server.ssrLoadModule("/src/core/StorageKeys.ts")
  ]);

  const { createGameStore, createInitialGameState } = gameStateModule;
  const { EventBus } = eventBusModule;
  const {
    ChapterFourTemporalMazeController,
    resolveChapterFour755SessionRequest,
    validateChapterFour755IntentRequest
  } = controllerModule;
  const {
    CHAPTER_FOUR_755_INTERACTION_TARGETS,
    getChapterFour755TargetContract,
    resolveChapterFour755RuntimeEntityTarget,
    selectChapterFour755BakeryCommittedRuntimeState
  } = interactionModule;
  const { selectChapterFourMazeProjection } = projectionModule;
  const { selectQuestViewModel } = questModule;
  const { SaveStore } = saveStoreModule;
  const {
    ROOM204_GROUP_ORDER,
    ROOM204_GROUPS,
    ROOM204_PIECE_ORDER,
    ROOM204_PODIUM_DRAWER_RUNTIME_ENTITY_ID,
    ROOM204_RESIDUAL_GROUP_RUNTIME_ENTITY_ID,
    ROOM204_SLOT_ORDER,
    ROOM204_RESTORED_DISPLAY_PHASES,
    createCanonicalCompleteRoom204Placements,
    isRoom204PlacementSetComplete,
    room204GroupRuntimeEntityId,
    room204GroupTargetId,
    resolveRoom204Placement,
    room204SlotRuntimeEntityId,
    selectRoom204RuntimePresentation
  } = room204Module;
  const {
    CHAPTER_FOUR_MAINTENANCE_GUARD_RULES,
    CHAPTER_FOUR_MAINTENANCE_PATROL_WAYPOINTS,
    canChapterFourGuardSeePlayer,
    chapterFourGuardFootContact,
    createChapterFourMaintenanceGuardRecoveryState,
    createChapterFourMaintenanceGuardState,
    halfOpenRectsOverlap,
    hasChapterFourGuardLineOfSight,
    stepChapterFourMaintenanceGuard
  } = guardModule;
  const {
    CHAPTER_FOUR_LIGHT_GRID,
    applyChapterFourLightGridClickVector,
    enumerateChapterFourLightGridSolutions,
    evaluateChapterFourLightGrid,
    isChapterFourLightGridSolved,
    toggleChapterFourLightZone
  } = lightGridModule;
  const {
    CHAPTER_FOUR_FINAL_CHASE_POINTS,
    CHAPTER_FOUR_FINAL_CHASE_RULES,
    CHAPTER_FOUR_FINAL_CHASE_WAYPOINTS,
    chapterFourFinalChaseDeltaSlices,
    chapterFourFinalChaseFootContact,
    createChapterFourFinalChaseState,
    isChapterFourFinalChaseAttemptCurrent,
    resolveChapterFourFinalChaseFailure,
    resolveChapterFourFinalChaseFinish,
    resolveChapterFourFinalChasePortal,
    stepChapterFourFinalChase
  } = finalChaseModule;
  const { selectRpgItemUseGuidance } = itemUseGuidanceModule;
  const {
    CHAPTER_FOUR_ELEVATOR_VISUAL_DEPTH,
    CHAPTER_FOUR_PLAYER_TOP_DEPTH,
    chapterFourPlayerDepth,
    isChapterFourPlayerInFrontOfElevator
  } = elevatorDepthModule;
  const { GAME_SAVE_BACKUP_KEY, GAME_SAVE_KEY } = storageKeysModule;

  const openingFacts = [
    "opening_paper_at_noticeboard",
    "opening_paper_caught",
    "external_time_rejected",
    "hall_clock_inspected"
  ];
  const bakeryFactOrder = [
    "bakery_conveyor_lamp_inspected",
    "bakery_conveyor_direction_observed",
    "bakery_tool_location_observed",
    "bakery_hour_hand_exposed",
    "bakery_hour_hand_collected",
    "hour_hand_installed"
  ];
  const insertedA1Facts = [
    "a1_duty_board_reconstructed"
  ];
  const insertedA3Facts = [
    "a3_archive_film_retrieved",
    "a3_media_alignment_completed"
  ];
  const insertedA2Facts = [
    "a2_positioning_plate_calibrated",
    "a2_power_topology_recovered",
    "a2_evacuation_route_confirmed"
  ];
  const elevatorStopChainFacts = [
    "elevator_a2_call_record_observed",
    "elevator_a3_arrival_record_observed",
    "elevator_stop_chain_reconstructed"
  ];
  const layoutRuntimeTargetById = new Map([
    ...chapterFourLayout.bakeryRuntime.targetEntities,
    ...chapterFourLayout.maintenanceRuntime.targetEntities,
    chapterFourLayout.finalClockRuntime.endpoint,
    chapterFourLayout.lightGridRuntime.panel,
    chapterFourLayout.finalMinuteRuntime,
    ...chapterFourLayout.morningCheckinRuntime.targetEntities
  ].map((entry) => [entry.targetId, entry]));
  const runtimeTargetFromLayout = (targetId) => {
    const definition = layoutRuntimeTargetById.get(targetId);
    if (!definition) throw new Error(`Missing authoritative Chapter 4 runtime target ${targetId}`);
    return {
      targetId: definition.targetId,
      entityId: definition.entityId,
      bounds: { ...definition.installationBounds }
    };
  };
  const runtimeTargets = {
    lamp: runtimeTargetFromLayout("a1_bakery_inspection_lamp"),
    conveyor: runtimeTargetFromLayout("a1_bakery_conveyor_edge"),
    pickup: runtimeTargetFromLayout("a1_bakery_hour_hand_pickup")
  };
  const validSpatial = { distance: "within_range" };
  assert(
    Object.values(CHAPTER_FOUR_755_INTERACTION_TARGETS).every((target) => (
      !Object.prototype.hasOwnProperty.call(target, "requiredFacing")
    )),
    "all Chapter 4 target contracts must omit interaction-facing requirements"
  );
  assert(
    !JSON.stringify(chapterFourLayout).includes('"requiredFacing"'),
    "the Chapter 4 layout must omit interaction-facing requirements"
  );
  for (const floor of chapterFourLayout.floors) {
    const elevator = floor.elevator;
    for (const point of [elevator.doorCenter, elevator.arrivalPosition, elevator.standPosition]) {
      const playerDepth = chapterFourPlayerDepth(point.y);
      assert(
        playerDepth === CHAPTER_FOUR_PLAYER_TOP_DEPTH,
        `${floor.storyFloor} player depth must stay fixed at the Chapter 4 top gameplay layer`
      );
      assert(
        isChapterFourPlayerInFrontOfElevator(playerDepth, CHAPTER_FOUR_ELEVATOR_VISUAL_DEPTH.door)
          && isChapterFourPlayerInFrontOfElevator(playerDepth, CHAPTER_FOUR_ELEVATOR_VISUAL_DEPTH.indicator)
          && isChapterFourPlayerInFrontOfElevator(playerDepth, CHAPTER_FOUR_ELEVATOR_VISUAL_DEPTH.lamp),
        `${floor.storyFloor} player must render in front of every elevator visual at authored elevator anchors`
      );
    }
  }
  assert(
    chapterFourPlayerDepth(0) === chapterFourPlayerDepth(chapterFourLayout.worldSize.height),
    "Chapter 4 player depth must not change with world y"
  );
  for (const targetId of ["a2_elevator_attendant", "a3_reference_teacher"]) {
    const target = getChapterFour755TargetContract(targetId);
    assert(
      target?.collision === false
        && target.activation === "phase_exclusive"
        && target.activePhases.includes("room204_restore"),
      `${targetId} must be a non-colliding, layout-backed Room 204 support NPC target`
    );
  }

  function makeState({
    facts = [],
    oldClockHourHand = false,
    mode = "light",
    roomId = "a1_bakery",
    phase = "bakery_hour_hand"
  } = {}) {
    const initial = createInitialGameState();
    const isPostBakery = phase === "room204_restore";
    return {
      ...initial,
      runtimeMode: "rpg",
      rpgScene: "duan_yongping_temporal_maze",
      rpgCheckpoint: "c4_a1_lobby",
      items: { ...initial.items, attendanceRecordPaper: true, oldClockHourHand },
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
        floor: "A1",
        roomId,
        timeAuthority: "hall_clock",
        timeState: isPostBakery ? "1850_evening" : "1225_bakery",
        worldTimeSeconds: isPostBakery ? 67800 : 44700,
        phoneStatusTimeSeconds: isPostBakery ? 67800 : 44700,
        phoneStatusTimeTrusted: true,
        factIds: [...openingFacts, ...facts]
      }
    };
  }

  function assertZeroWriteRejection(state, intent, expectedReason, runtimeTarget, label) {
    const store = createGameStore(state);
    const controller = new ChapterFourTemporalMazeController(store, new EventBus());
    const before = snapshot(store.getState());
    const result = controller.resolve755Intent(intent, runtimeTarget);
    assert(result.accepted === false, `${label} must reject`);
    assert(result.changed === false, `${label} must report changed=false`);
    assert(result.reason === expectedReason, `${label} reason must be ${expectedReason}, got ${result.reason}`);
    assert(snapshot(store.getState()) === before, `${label} must be a zero-write rejection`);
  }

  const frontDeskTarget = CHAPTER_FOUR_755_INTERACTION_TARGETS.a1_front_desk_attendant;
  const classroom104Target = CHAPTER_FOUR_755_INTERACTION_TARGETS.a1_classroom_104_blackboard_residual;
  const classroom105Target = CHAPTER_FOUR_755_INTERACTION_TARGETS.a1_classroom_105_lectern_terminal;
  assert(
    frontDeskTarget.boundsSource.kind === "layout_anchor"
      && frontDeskTarget.boundsSource.anchorId === "a1_front_desk_attendant"
      && frontDeskTarget.requiredMode === undefined,
    "A1 front-desk attendant must use the measured visible NPC anchor without a reality-mode gate"
  );
  const frontDeskState = makeState({
    roomId: "a1_lobby",
    phase: "room204_restore",
    facts: ["hour_hand_installed"]
  });
  const frontDeskStore = createGameStore(frontDeskState);
  const frontDeskController = new ChapterFourTemporalMazeController(frontDeskStore, new EventBus());
  const frontDeskBefore = snapshot(frontDeskStore.getState());
  const frontDeskTalk = frontDeskController.resolve755Intent({
    type: "talk_to_a1_front_desk_attendant",
    targetId: frontDeskTarget.id,
    spatial: validSpatial
  });
  assert(frontDeskTalk.accepted && !frontDeskTalk.changed, "front-desk conversation must be accepted read-only");
  assert(snapshot(frontDeskStore.getState()) === frontDeskBefore, "front-desk conversation must not mutate progression");
  assertZeroWriteRejection(
    frontDeskState,
    {
      type: "talk_to_a1_front_desk_attendant",
      targetId: frontDeskTarget.id,
      spatial: { distance: "too_far" }
    },
    "too_far",
    undefined,
    "front-desk conversation outside proximity"
  );
  const frontDeskProjection = selectChapterFourMazeProjection(frontDeskState);
  assert(
    frontDeskProjection.availableTargetIds.includes(frontDeskTarget.id)
      && frontDeskProjection.npcIds.includes("a1_front_desk_attendant"),
    "front-desk target and visible NPC must project together on A1"
  );
  assert(
    classroom104Target.boundsSource.kind === "layout_anchor"
      && classroom104Target.boundsSource.anchorId === "a1_classroom_104_blackboard_residual"
      && classroom104Target.requiredMode === "dark",
    "104 classroom content must use the measured blackboard anchor and dark observation"
  );
  assert(
    classroom105Target.boundsSource.kind === "layout_anchor"
      && classroom105Target.boundsSource.anchorId === "a1_classroom_105_lectern_terminal"
      && classroom105Target.requiredMode === "light",
    "105 classroom content must use the measured lectern anchor and light operation"
  );
  assertZeroWriteRejection(
    makeState({ mode: "light", roomId: "a1_lobby", phase: "room204_restore", facts: ["hour_hand_installed"] }),
    {
      type: "observe_classroom_104_chalk_residual",
      targetId: classroom104Target.id,
      spatial: validSpatial
    },
    "wrong_mode",
    undefined,
    "104 classroom observation in light mode"
  );
  assertZeroWriteRejection(
    makeState({ mode: "dark", roomId: "a1_lobby", phase: "room204_restore", facts: ["hour_hand_installed"] }),
    {
      type: "check_classroom_105_terminal_replay",
      targetId: classroom105Target.id,
      spatial: validSpatial
    },
    "wrong_mode",
    undefined,
    "105 classroom terminal in dark mode"
  );
  const earlyElevatorStore = createGameStore(makeState({
    mode: "light",
    roomId: "a1_lobby",
    phase: "room204_restore",
    facts: ["hour_hand_installed"]
  }));
  const earlyElevatorController = new ChapterFourTemporalMazeController(
    earlyElevatorStore,
    new EventBus()
  );
  const earlyCalibration = earlyElevatorController.resolve755Intent({
    type: "calibrate_elevator_history",
    startSeconds: 81811
  });
  assert(
    earlyCalibration.accepted
      && !earlyElevatorStore.getState().chapter4.factIds.includes("elevator_history_observed"),
    "light elevator calibration must be available before classroom checks and must not synthesize dark observation"
  );
  earlyElevatorController.resolve755Intent({ type: "set_mode", mode: "dark" });
  const earlyObservation = earlyElevatorController.resolve755Intent({ type: "observe_elevator_history" });
  assert(
    earlyObservation.accepted
      && earlyElevatorStore.getState().chapter4.factIds.includes("elevator_history_calibrated")
      && earlyElevatorStore.getState().chapter4.factIds.includes("elevator_history_observed"),
    "dark elevator observation must remain available after light calibration and before classroom checks"
  );
  const earlyRoute = earlyElevatorController.resolve755Intent({
    type: "move_to_location",
    floor: "A3",
    roomId: "a3_wayfinding",
    checkpoint: "c4_a3_wayfinding"
  });
  assert(
    !earlyRoute.accepted && earlyRoute.detailCode === "classroom_checks_required",
    "mode-order freedom must not bypass the separate classroom route requirement"
  );
  const classroomStore = createGameStore(makeState({
    mode: "dark",
    roomId: "a1_lobby",
    phase: "room204_restore",
    facts: ["hour_hand_installed", ...insertedA1Facts]
  }));
  const classroomController = new ChapterFourTemporalMazeController(classroomStore, new EventBus());
  assert(
    selectQuestViewModel(classroomStore.getState()).objective === "汇总 A1 剩余调查点",
    "task drawer must group the remaining A1 investigations before exposing the A3 objective"
  );
  const blockedBeforeChecks = classroomController.resolve755Intent({
    type: "move_to_location",
    floor: "A3",
    roomId: "a3_wayfinding",
    checkpoint: "c4_a3_wayfinding"
  });
  assert(
    !blockedBeforeChecks.accepted
      && blockedBeforeChecks.reason === "locked"
      && blockedBeforeChecks.detailCode === "classroom_checks_required",
    "room204 route must stay on A1 before both classroom checks"
  );
  const classroom104First = classroomController.resolve755Intent({
    type: "observe_classroom_104_chalk_residual",
    targetId: classroom104Target.id,
    spatial: validSpatial
  });
  assert(classroom104First.accepted && classroom104First.changed, "104 classroom first observation must commit");
  assert(
    classroomStore.getState().chapter4.factIds.includes("classroom_104_chalk_residual_observed"),
    "104 classroom observation fact must persist in controller state"
  );
  const classroom104Repeat = classroomController.resolve755Intent({
    type: "observe_classroom_104_chalk_residual",
    targetId: classroom104Target.id,
    spatial: validSpatial
  });
  assert(classroom104Repeat.accepted && !classroom104Repeat.changed, "104 classroom repeat must be read-only");
  const blockedAfter104 = classroomController.resolve755Intent({
    type: "move_to_location",
    floor: "A3",
    roomId: "a3_wayfinding",
    checkpoint: "c4_a3_wayfinding"
  });
  assert(
    !blockedAfter104.accepted && blockedAfter104.detailCode === "classroom_checks_required",
    "one classroom check must not unlock the floor route"
  );
  classroomController.resolve755Intent({ type: "set_mode", mode: "light" });
  const classroom105First = classroomController.resolve755Intent({
    type: "check_classroom_105_terminal_replay",
    targetId: classroom105Target.id,
    spatial: validSpatial
  });
  assert(classroom105First.accepted && classroom105First.changed, "105 classroom first check must commit");
  assert(
    classroomStore.getState().chapter4.factIds.includes("classroom_105_terminal_replay_checked"),
    "105 classroom terminal fact must persist in controller state"
  );
  const classroomQuest = selectQuestViewModel(classroomStore.getState());
  assert(
    classroomQuest.objective === "汇总 A1 剩余调查点",
    "task drawer must keep elevator observation and calibration inside the order-free A1 group"
  );
  const classroomProjection = selectChapterFourMazeProjection(classroomStore.getState());
  assert(
    classroomProjection.availableTargetIds.includes(classroom104Target.id)
      && classroomProjection.availableTargetIds.includes(classroom105Target.id),
    "both classroom targets must remain available for repeat viewing"
  );
  const blockedBeforeElevatorCalibration = classroomController.resolve755Intent({
    type: "move_to_location",
    floor: "A3",
    roomId: "a3_wayfinding",
    checkpoint: "c4_a3_wayfinding"
  });
  assert(
    !blockedBeforeElevatorCalibration.accepted
      && blockedBeforeElevatorCalibration.detailCode === "elevator_calibration_required",
    "classroom checks alone must keep the A3 route behind elevator history calibration"
  );
  classroomController.resolve755Intent({ type: "set_mode", mode: "dark" });
  const elevatorObserved = classroomController.resolve755Intent({ type: "observe_elevator_history" });
  assert(elevatorObserved.accepted && elevatorObserved.changed, "dark observation must record elevator history once");
  assert(
    selectQuestViewModel(classroomStore.getState()).objective === "汇总 A1 剩余调查点",
    "one completed elevator branch must keep the grouped order-free A1 task visible"
  );
  classroomController.resolve755Intent({ type: "set_mode", mode: "light" });
  const wrongElevatorReplay = classroomController.resolve755Intent({
    type: "calibrate_elevator_history",
    startSeconds: 81807
  });
  assert(!wrongElevatorReplay.accepted && wrongElevatorReplay.reason === "incorrect", "misaligned elevator replay must be rejected");
  const elevatorCalibrated = classroomController.resolve755Intent({
    type: "calibrate_elevator_history",
    startSeconds: 81811
  });
  assert(elevatorCalibrated.accepted && elevatorCalibrated.changed, "aligned elevator replay must commit once");
  const unlockedAfterCalibration = classroomController.resolve755Intent({
    type: "move_to_location",
    floor: "A3",
    roomId: "a3_wayfinding",
    checkpoint: "c4_a3_wayfinding"
  });
  assert(unlockedAfterCalibration.accepted, "elevator calibration must unlock the authored A3 route");

  const deferredDutyBoardStore = createGameStore(makeState({
    mode: "light",
    roomId: "a1_main_elevator",
    phase: "room204_restore",
    facts: [
      "hour_hand_installed",
      "classroom_104_chalk_residual_observed",
      "classroom_105_terminal_replay_checked",
      "elevator_history_observed",
      "elevator_history_calibrated"
    ]
  }));
  const deferredDutyBoardController = new ChapterFourTemporalMazeController(
    deferredDutyBoardStore,
    new EventBus()
  );
  const routeBeforeDutyBoard = deferredDutyBoardController.resolve755Intent({
    type: "move_to_location",
    floor: "A3",
    roomId: "a3_wayfinding",
    checkpoint: "c4_a3_wayfinding"
  });
  assert(
    routeBeforeDutyBoard.accepted
      && deferredDutyBoardStore.getState().chapter4.floor === "A3",
    "A1 duty-board evidence must remain collectable after the authored A3 route opens"
  );
  assert(
    selectQuestViewModel(deferredDutyBoardStore.getState()).objective !== "汇总 A1 剩余调查点",
    "the task drawer must follow the player into the A3 investigation while the deferred A1 clue remains unconsumed"
  );

  const elevatorCalibrationFirstStore = createGameStore(makeState({
    mode: "light",
    roomId: "a1_lobby",
    phase: "room204_restore",
    facts: [
      "hour_hand_installed",
      ...insertedA1Facts,
      "classroom_104_chalk_residual_observed",
      "classroom_105_terminal_replay_checked"
    ]
  }));
  const elevatorCalibrationFirstController = new ChapterFourTemporalMazeController(
    elevatorCalibrationFirstStore,
    new EventBus()
  );
  const calibrationBeforeObservation = elevatorCalibrationFirstController.resolve755Intent({
    type: "calibrate_elevator_history",
    startSeconds: 81811
  });
  assert(
    calibrationBeforeObservation.accepted
      && !elevatorCalibrationFirstStore.getState().chapter4.factIds.includes("elevator_history_observed"),
    "light elevator calibration must be accepted before the independent dark observation"
  );
  elevatorCalibrationFirstController.resolve755Intent({ type: "set_mode", mode: "dark" });
  const observationAfterCalibration = elevatorCalibrationFirstController.resolve755Intent({
    type: "observe_elevator_history"
  });
  assert(observationAfterCalibration.accepted, "dark elevator observation must remain available after light calibration");
  assert(
    ["elevator_history_observed", "elevator_history_calibrated"].every((factId) => (
      elevatorCalibrationFirstStore.getState().chapter4.factIds.includes(factId)
    )),
    "both elevator facts must converge regardless of mode order"
  );

  function runtimeTargetIntentFixture(target) {
    if (target.targetId === runtimeTargets.lamp.targetId) {
      return {
        state: makeState(),
        intent: {
          type: "inspect_bakery_conveyor_lamp",
          targetId: target.targetId,
          spatial: validSpatial
        }
      };
    }
    if (target.targetId === runtimeTargets.conveyor.targetId) {
      return {
        state: makeState({ facts: ["bakery_conveyor_lamp_inspected"] }),
        intent: {
          type: "inspect_bakery_conveyor_edge",
          targetId: target.targetId,
          spatial: validSpatial
        }
      };
    }
    return {
      state: makeState({
        facts: ["bakery_conveyor_lamp_inspected", "bakery_hour_hand_exposed"]
      }),
      intent: {
        type: "collect_hour_hand",
        targetId: target.targetId,
        spatial: validSpatial
      }
    };
  }

  for (const target of Object.values(runtimeTargets)) {
    const contract = getChapterFour755TargetContract(target.targetId);
    const resolved = resolveChapterFour755RuntimeEntityTarget(
      target.targetId,
      target.entityId,
      target.bounds
    );
    assert(contract?.activation === "runtime_entity", `${target.targetId} registry contract must be runtime_entity`);
    assert(contract?.bounds === null && contract?.contractPending === true, `${target.targetId} static registry bounds must stay closed`);
    assert(resolved?.contractPending === false, `${target.targetId} runtime envelope must resolve`);
    assert(sameJson(resolved?.bounds, target.bounds), `${target.targetId} runtime envelope bounds mismatch`);
    assert(
      resolveChapterFour755RuntimeEntityTarget(
        target.targetId,
        "wrong-entity",
        target.bounds
      ) === null,
      `${target.targetId} resolver must reject a mismatched entityId`
    );
    const fixture = runtimeTargetIntentFixture(target);
    for (const [variant, wrongBounds] of [
      ["world-internal 1x1", { x: target.bounds.x, y: target.bounds.y, width: 1, height: 1 }],
      ["translated 1px", { ...target.bounds, x: target.bounds.x + 1 }]
    ]) {
      assert(
        resolveChapterFour755RuntimeEntityTarget(
          target.targetId,
          target.entityId,
          wrongBounds
        ) === null,
        `${target.targetId} resolver must reject ${variant} bounds with the correct entityId`
      );
      assertZeroWriteRejection(
        fixture.state,
        fixture.intent,
        "locked",
        { ...target, bounds: wrongBounds },
        `${target.targetId} controller ${variant} envelope`
      );
    }
  }

  for (const [label, state, expected] of [
    ["uninspected", makeState(), {
      lampLit: false,
      conveyorStopped: false,
      crowdPaused: false,
      hourHandVisible: false,
      glintVisible: false,
      retryStopHandshake: false
    }],
    ["lamp committed", makeState({ facts: ["bakery_conveyor_lamp_inspected"] }), {
      lampLit: true,
      conveyorStopped: false,
      crowdPaused: false,
      hourHandVisible: false,
      glintVisible: false,
      retryStopHandshake: true
    }],
    ["exposed committed", makeState({ facts: [
      "bakery_conveyor_lamp_inspected",
      "bakery_hour_hand_exposed"
    ] }), {
      lampLit: true,
      conveyorStopped: true,
      crowdPaused: true,
      hourHandVisible: true,
      glintVisible: true,
      retryStopHandshake: false
    }],
    ["collected committed", makeState({
      facts: [
        "bakery_conveyor_lamp_inspected",
        "bakery_hour_hand_exposed",
        "bakery_hour_hand_collected"
      ],
      oldClockHourHand: true
    }), {
      lampLit: true,
      conveyorStopped: true,
      crowdPaused: true,
      hourHandVisible: false,
      glintVisible: false,
      retryStopHandshake: false
    }],
    ["installed committed", makeState({
      facts: bakeryFactOrder,
      phase: "room204_restore",
      roomId: "a1_hall_clock"
    }), {
      lampLit: true,
      conveyorStopped: false,
      crowdPaused: false,
      hourHandVisible: false,
      glintVisible: false,
      retryStopHandshake: false
    }]
  ]) {
    assert(
      sameJson(selectChapterFour755BakeryCommittedRuntimeState(state), expected),
      `${label} bakery committed-runtime recovery state mismatch`
    );
  }

  const initialBakeryState = makeState();
  const initialProjection = selectChapterFourMazeProjection(initialBakeryState);
  assert(initialProjection.activePlateIds.includes("a1_1225_bakery"), "12:25 bakery plate must be active");
  assert(
    sameJson(initialProjection.npcIds, [
      "a1_bakery_clerk",
      "a1_bakery_lunch_crowd",
      "a1_front_desk_attendant"
    ]),
    "bakery baker, crowd, and front-desk attendant must project together"
  );
  assert(initialProjection.availableTargetIds.includes(runtimeTargets.lamp.targetId), "lamp must project before inspection");
  assert(initialProjection.availableTargetIds.includes(runtimeTargets.conveyor.targetId), "conveyor edge must project before inspection");
  assert(!initialProjection.availableTargetIds.includes(runtimeTargets.pickup.targetId), "hour-hand pickup must stay hidden before exposure");

  assertZeroWriteRejection(
    initialBakeryState,
    { type: "inspect_bakery_conveyor_edge", targetId: runtimeTargets.conveyor.targetId, spatial: validSpatial },
    "locked",
    runtimeTargets.conveyor,
    "pre-lamp conveyor attempt"
  );
  assertZeroWriteRejection(
    makeState({ mode: "dark" }),
    { type: "inspect_bakery_conveyor_lamp", targetId: runtimeTargets.lamp.targetId, spatial: validSpatial },
    "wrong_mode",
    runtimeTargets.lamp,
    "dark-mode lamp attempt"
  );
  assertZeroWriteRejection(
    initialBakeryState,
    {
      type: "inspect_bakery_conveyor_lamp",
      targetId: runtimeTargets.lamp.targetId,
      spatial: { distance: "too_far" }
    },
    "too_far",
    runtimeTargets.lamp,
    "too-far lamp attempt"
  );
  assertZeroWriteRejection(
    initialBakeryState,
    { type: "complete_bakery_conveyor_stop" },
    "locked",
    undefined,
    "completion before lamp"
  );
  assertZeroWriteRejection(
    initialBakeryState,
    { type: "inspect_bakery_conveyor_lamp", targetId: runtimeTargets.lamp.targetId, spatial: validSpatial },
    "locked",
    { ...runtimeTargets.lamp, entityId: "wrong-entity" },
    "lamp request with forged runtime envelope"
  );

  const sequenceStore = createGameStore(initialBakeryState);
  const sequenceEvents = new EventBus();
  const sequenceController = new ChapterFourTemporalMazeController(sequenceStore, sequenceEvents);
  const lampResult = sequenceController.resolve755Intent({
    type: "inspect_bakery_conveyor_lamp",
    targetId: runtimeTargets.lamp.targetId,
    spatial: validSpatial
  }, runtimeTargets.lamp);
  assert(lampResult.accepted && lampResult.changed, "lamp inspection must commit exactly once");
  assert(sequenceStore.getState().chapter4.factIds.includes("bakery_conveyor_lamp_inspected"), "lamp inspection fact must commit");
  const afterLampSnapshot = snapshot(sequenceStore.getState());
  const duplicateLamp = sequenceController.resolve755Intent({
    type: "inspect_bakery_conveyor_lamp",
    targetId: runtimeTargets.lamp.targetId,
    spatial: validSpatial
  }, runtimeTargets.lamp);
  assert(!duplicateLamp.accepted && !duplicateLamp.changed, "duplicate lamp inspection must reject");
  assert(snapshot(sequenceStore.getState()) === afterLampSnapshot, "duplicate lamp inspection must be zero-write");
  const pendingEdge = sequenceController.resolve755Intent({
    type: "inspect_bakery_conveyor_edge",
    targetId: runtimeTargets.conveyor.targetId,
    spatial: validSpatial
  }, runtimeTargets.conveyor);
  assert(!pendingEdge.accepted && !pendingEdge.changed, "conveyor edge must remain non-progressing during the stop handshake");
  assert(snapshot(sequenceStore.getState()) === afterLampSnapshot, "pending conveyor attempt must remain zero-write");

  const completeResult = sequenceController.resolve755Intent({ type: "complete_bakery_conveyor_stop" });
  assert(completeResult.accepted && completeResult.changed, "700ms completion intent must commit exposed");
  assert(sequenceStore.getState().chapter4.factIds.includes("bakery_hour_hand_exposed"), "exposed fact must commit at completion");
  const afterExposedSnapshot = snapshot(sequenceStore.getState());
  const duplicateCompletion = sequenceController.resolve755Intent({ type: "complete_bakery_conveyor_stop" });
  assert(!duplicateCompletion.accepted && !duplicateCompletion.changed, "duplicate stop completion must reject");
  assert(snapshot(sequenceStore.getState()) === afterExposedSnapshot, "duplicate stop completion must be zero-write");
  const exposedProjection = selectChapterFourMazeProjection(sequenceStore.getState());
  assert(exposedProjection.availableTargetIds.includes(runtimeTargets.pickup.targetId), "exposed save must project the pickup");
  assert(!exposedProjection.availableTargetIds.includes(runtimeTargets.lamp.targetId), "exposed save must close the lamp target");

  const pickupResult = sequenceController.resolve755Intent({
    type: "collect_hour_hand",
    targetId: runtimeTargets.pickup.targetId,
    spatial: validSpatial
  }, runtimeTargets.pickup);
  assert(pickupResult.accepted && pickupResult.changed, "hour-hand pickup must commit exactly once");
  assert(sequenceStore.getState().chapter4.factIds.includes("bakery_hour_hand_collected"), "pickup must commit collected fact");
  assert(sequenceStore.getState().items.oldClockHourHand === true, "pickup must grant oldClockHourHand in the same transaction");
  const afterPickupSnapshot = snapshot(sequenceStore.getState());
  const duplicatePickup = sequenceController.resolve755Intent({
    type: "collect_hour_hand",
    targetId: runtimeTargets.pickup.targetId,
    spatial: validSpatial
  }, runtimeTargets.pickup);
  assert(!duplicatePickup.accepted && !duplicatePickup.changed, "duplicate pickup must reject");
  assert(snapshot(sequenceStore.getState()) === afterPickupSnapshot, "duplicate pickup must be zero-write");

  const moveResult = sequenceController.resolve755Intent({
    type: "move_to_location",
    floor: "A1",
    roomId: "a1_hall_clock",
    checkpoint: "c4_a1_lobby"
  });
  assert(moveResult.accepted, "collected hour hand must allow return to the hall clock");
  const socketProjection = selectChapterFourMazeProjection(sequenceStore.getState());
  assert(socketProjection.availableTargetIds.includes("a1_hall_clock_hour_hand_socket"), "held hour hand must project the visible socket in the hall");
  const installResult = sequenceController.resolve755Intent({
    type: "install_hour_hand",
    itemId: "oldClockHourHand",
    targetId: "a1_hall_clock_hour_hand_socket",
    spatial: validSpatial
  });
  assert(installResult.accepted && installResult.changed, "valid socket drop must install the hour hand");
  const installedState = sequenceStore.getState();
  assert(installedState.chapter4.phase === "room204_restore", "install must enter room204_restore");
  assert(installedState.chapter4.timeState === "1225_bakery", "install must keep the committed 12:25 time until the player adjusts the clock");
  assert(installedState.chapter4.worldTimeSeconds === 44700, "install must keep world time at 12:25 before the next clock action");
  assert(installedState.chapter4.phoneStatusTimeSeconds === 44700, "install must keep phone time at 12:25 before the next clock action");
  assert(installedState.chapter4.phoneStatusTimeTrusted === true, "install must preserve trusted phone time");
  assert(installedState.chapter4.floor === "A1" && installedState.chapter4.roomId === "a1_hall_clock", "install must return the player to the A1 hall clock");
  assert(installedState.rpgCheckpoint === "c4_a1_lobby", "install must use the A1 safe checkpoint");
  assert(installedState.chapter4.factIds.includes("hour_hand_installed"), "install must commit hour_hand_installed");
  assert(installedState.items.oldClockHourHand === false, "install must consume oldClockHourHand");
  const installedProjection = selectChapterFourMazeProjection(installedState);
  assert(sameJson(installedProjection.activePlateIds, ["a1_1225_bakery"]), "install must retain the 12:25 plate until the next clock action");
  assert(installedProjection.availableTargetIds.includes("a1_hall_clock"), "the hall clock must remain actionable for the required 18:50 adjustment");
  assert(selectQuestViewModel(installedState).steps[0]?.id === "chapter_four_tune_clock_to_1850", "the next objective must ask the player to tune the clock to 18:50");
  const installedSnapshot = snapshot(installedState);
  const duplicateInstall = sequenceController.resolve755Intent({
    type: "install_hour_hand",
    itemId: "oldClockHourHand",
    targetId: "a1_hall_clock_hour_hand_socket",
    spatial: validSpatial
  });
  assert(!duplicateInstall.accepted && !duplicateInstall.changed, "duplicate install must reject");
  assert(snapshot(sequenceStore.getState()) === installedSnapshot, "duplicate install must be zero-write");
  const tune1850Result = sequenceController.resolve755Intent({
    type: "adjust_hall_clock_time",
    targetId: "a1_hall_clock",
    targetTimeState: "1850_evening",
    spatial: validSpatial
  });
  assert(tune1850Result.accepted && tune1850Result.changed, "the restored hour hand must unlock the explicit 18:50 adjustment");
  const eveningState = sequenceStore.getState();
  assert(eveningState.chapter4.phase === "room204_restore", "the 18:50 adjustment must stay in room204_restore");
  assert(eveningState.chapter4.timeState === "1850_evening", "the explicit clock action must enter the 18:50 time state");
  assert(eveningState.chapter4.worldTimeSeconds === 67800 && eveningState.chapter4.phoneStatusTimeSeconds === 67800, "the explicit 18:50 adjustment must synchronize world and phone time");
  assert(sameJson(selectChapterFourMazeProjection(eveningState).activePlateIds, ["a2_1850_evening", "a3_1850_reference"]), "the explicit 18:50 adjustment must activate the A2+A3 plate group");
  assert(
    sequenceEvents.getHistory().filter((event) => event.name === "chapter4_755_intent_committed").length === 6,
    "only lamp, completion, pickup, return, install and explicit clock adjustment may emit commit events in the accepted sequence"
  );

  for (const [label, state, expectedTaskId] of [
    ["uninspected", makeState(), "chapter_four_explore_bakery"],
    ["lamp-only", makeState({ facts: ["bakery_conveyor_lamp_inspected"] }), "chapter_four_explore_bakery"],
    ["exposed", makeState({ facts: ["bakery_conveyor_lamp_inspected", "bakery_hour_hand_exposed"] }), "chapter_four_collect_hour_hand"],
    ["collected", makeState({ facts: ["bakery_conveyor_lamp_inspected", "bakery_hour_hand_exposed", "bakery_hour_hand_collected"], oldClockHourHand: true }), "chapter_four_install_hour_hand"],
    ["held-item", makeState({ oldClockHourHand: true }), "chapter_four_install_hour_hand"]
  ]) {
    const quest = selectQuestViewModel(state);
    assert(quest.steps.length === 1, `${label} bakery quest must reveal exactly one step`);
    assert(quest.steps[0]?.id === expectedTaskId, `${label} bakery quest must select ${expectedTaskId}`);
  }

  function hydrate(state) {
    const storage = new MemoryStorage();
    const saveStore = new SaveStore(storage);
    assert(saveStore.save(state) === true, "SaveStore must persist the runtime-matrix fixture");
    const loaded = saveStore.load(createInitialGameState());
    assert(loaded !== null, "SaveStore must reload the runtime-matrix fixture");
    return loaded;
  }

  for (const [label, state, expectedFacts, expectedHeld, expectedPhase] of [
    ["uninspected", makeState(), [], false, "bakery_hour_hand"],
    ["lamp-only", makeState({ facts: ["bakery_conveyor_lamp_inspected"] }), ["bakery_conveyor_lamp_inspected"], false, "bakery_hour_hand"],
    ["exposed", makeState({ facts: ["bakery_hour_hand_exposed"] }), ["bakery_conveyor_lamp_inspected", "bakery_hour_hand_exposed"], false, "bakery_hour_hand"],
    ["collected", makeState({ facts: ["bakery_hour_hand_collected"] }), ["bakery_conveyor_lamp_inspected", "bakery_hour_hand_exposed", "bakery_hour_hand_collected"], true, "bakery_hour_hand"],
    ["stale-item", makeState({ oldClockHourHand: true }), [], false, "bakery_hour_hand"],
    ["installed", makeState({ facts: ["hour_hand_installed"], oldClockHourHand: true, phase: "room204_restore", roomId: "a1_hall_clock" }), bakeryFactOrder, false, "room204_restore"]
  ]) {
    const loaded = hydrate(state);
    const loadedBakeryFacts = loaded.chapter4.factIds.filter((factId) => bakeryFactOrder.includes(factId));
    assert(sameJson(loadedBakeryFacts, expectedFacts), `${label} save must restore bakery facts in causal order`);
    assert(loaded.items.oldClockHourHand === expectedHeld, `${label} save held-item state mismatch`);
    assert(loaded.chapter4.phase === expectedPhase, `${label} save phase mismatch`);
  }

  function legacyEnvelope(state) {
    return JSON.stringify({ version: 24, state, savedAt: 1_755_000 });
  }

  function loadRawSave(primaryRaw, backupRaw = null) {
    const storage = new MemoryStorage();
    storage.setItem(GAME_SAVE_KEY, primaryRaw);
    if (backupRaw !== null) storage.setItem(GAME_SAVE_BACKUP_KEY, backupRaw);
    const loaded = new SaveStore(storage).load(createInitialGameState());
    assert(loaded !== null, "legacy save fixture must hydrate");
    return { loaded, storage };
  }

  const legacyBase = createInitialGameState();
  const legacyNotStarted = {
    ...legacyBase,
    chapter4: {
      ...legacyBase.chapter4,
      prologueSeen: false,
      phase: "inactive",
      completed: false,
      solvedPuzzleIds: [],
      clueIds: []
    }
  };
  const notStartedMigration = loadRawSave(legacyEnvelope(legacyNotStarted)).loaded;
  assert(notStartedMigration.chapter4.phase === "opening_handoff", "v24 pre-Chapter-4 save must migrate to opening_handoff");
  assert(notStartedMigration.chapter4.prologueSeen === false, "v24 pre-Chapter-4 save must keep the prologue pending");
  assert(notStartedMigration.chapter4.floor === "A1" && notStartedMigration.chapter4.roomId === "a1_lobby", "v24 pre-Chapter-4 save must use the A1 lobby opening location");
  assert(notStartedMigration.chapter4.timeState === "2245_opening" && notStartedMigration.chapter4.phoneStatusTimeTrusted === false, "v24 pre-Chapter-4 save must restore the untrusted opening clock");
  assert(notStartedMigration.chapter4.factIds.length === 0, "v24 pre-Chapter-4 save must not invent Chapter 4 facts");

  const legacyInProgress = {
    ...legacyBase,
    runtimeMode: "phone",
    rpgScene: "campus_bootstrap",
    rpgCheckpoint: "campus_spawn",
    currentScene: "phone_home",
    items: {
      ...legacyBase.items,
      attendanceRecordPaper: true,
      oldClockHourHand: true,
      clockPositioningPlate: true,
      shortPryBar: true,
      universalLubricatingOil: true,
      finalMinute: true
    },
    chapter4: {
      ...legacyBase.chapter4,
      prologueSeen: true,
      phase: "route_schedule",
      completed: false,
      solvedPuzzleIds: ["route_schedule"],
      clueIds: ["legacy-route-clue"]
    }
  };
  const inProgressMigration = loadRawSave(legacyEnvelope(legacyInProgress)).loaded;
  assert(inProgressMigration.runtimeMode === "rpg" && inProgressMigration.rpgScene === "duan_yongping_temporal_maze", "v24 in-progress save must re-enter the Chapter 4 RPG");
  assert(inProgressMigration.rpgCheckpoint === "c4_a1_lobby", "v24 in-progress save must migrate to the safe A1 checkpoint");
  assert(inProgressMigration.chapter4.phase === "opening_handoff" && inProgressMigration.chapter4.prologueSeen === true, "v24 in-progress save must resume at the live opening handoff");
  assert(inProgressMigration.chapter4.factIds.length === 0, "v24 in-progress save must clear incompatible legacy facts");
  assert(
    ["attendanceRecordPaper", "oldClockHourHand", "clockPositioningPlate", "shortPryBar", "universalLubricatingOil", "finalMinute"]
      .every((itemId) => inProgressMigration.items[itemId] === false),
    "v24 in-progress save must clear incompatible Chapter 4 items"
  );

  const legacyCompleted = {
    ...legacyBase,
    runtimeMode: "rpg",
    rpgScene: "duan_yongping_temporal_maze",
    rpgCheckpoint: "c4_b2_final_room",
    currentScene: "phone_home",
    chapter4: {
      ...legacyBase.chapter4,
      prologueSeen: true,
      phase: "complete",
      completed: true,
      solvedPuzzleIds: ["clock_phase_lock"],
      clueIds: ["legacy-complete"]
    }
  };
  const completedMigration = loadRawSave(legacyEnvelope(legacyCompleted)).loaded;
  assert(completedMigration.chapter4.phase === "exterior_closure", "v24 completed save must migrate to the official exterior waiting phase");
  assert(completedMigration.chapter4.completed === false && completedMigration.chapter4.exteriorClosureAcknowledged === false, "v24 completed save must not forge closure completion without an approved asset proof");
  assert(completedMigration.chapter4.checkinCardAccepted === true && completedMigration.chapter4.checkinPaperAccepted === true, "v24 completed save must retain both completed check-in parts");
  assert(completedMigration.chapter4.floor === "A1" && completedMigration.chapter4.roomId === "a1_exterior", "v24 completed save must migrate to the A1 exterior waiting location");
  assert(completedMigration.chapter4.timeState === "0755_morning" && completedMigration.chapter4.phoneStatusTimeTrusted === true, "v24 completed save must restore trusted 07:55");
  assert(completedMigration.chapter4.lightGrid.mask === 13 && completedMigration.chapter4.lightGrid.locked === true, "v24 completed save must retain the solved light grid");
  assert(completedMigration.items.attendanceRecordPaper === true && completedMigration.items.campusCard === true, "v24 completed save must restore the two check-in items");

  const validBackupRaw = legacyEnvelope(legacyInProgress);
  const backupMigration = loadRawSave("{corrupted-primary", validBackupRaw);
  assert(backupMigration.loaded.chapter4.phase === "opening_handoff", "corrupted primary must recover the valid v24 backup");
  assert(backupMigration.loaded.rpgScene === "duan_yongping_temporal_maze" && backupMigration.loaded.rpgCheckpoint === "c4_a1_lobby", "backup recovery must preserve the migrated Chapter 4 safe entry");
  assert(backupMigration.storage.getItem(GAME_SAVE_KEY) === validBackupRaw, "valid backup recovery must repair the primary save slot");

  const room204Layout = chapterFourLayout.room204Runtime;
  const completeRoom204Placements = createCanonicalCompleteRoom204Placements();
  assert(
    selectRoom204RuntimePresentation("room204_restore", false, []) === "interactive",
    "Room 204 must mount its interactive furniture runtime while the restoration is in progress"
  );
  for (const phase of [
    "maintenance_repair",
    "blackout_light_grid",
    "final_chase",
    "final_minute_recovery",
    "return_to_clock",
    "morning_checkin",
    "exterior_closure",
    "complete"
  ]) {
    assert(ROOM204_RESTORED_DISPLAY_PHASES.has(phase), `${phase} must retain the restored Room 204 display`);
    assert(
      selectRoom204RuntimePresentation(phase, true, completeRoom204Placements) === "restored",
      `${phase} must keep all completed Room 204 furniture mounted`
    );
  }
  assert(
    selectRoom204RuntimePresentation("final_chase", false, completeRoom204Placements) === "hidden",
    "later phases must not fabricate a restored Room 204 without its persisted completion fact"
  );
  assert(
    selectRoom204RuntimePresentation("final_chase", true, completeRoom204Placements.slice(1)) === "hidden",
    "later phases must not render an incomplete Room 204 placement set as restored"
  );
  const room204RuntimeTargets = {
    residual: {
      targetId: "a2_room204_residual_group",
      entityId: ROOM204_RESIDUAL_GROUP_RUNTIME_ENTITY_ID,
      bounds: { ...room204Layout.residualGroupBounds }
    },
    drawer: {
      targetId: "a2_room204_podium_drawer",
      entityId: ROOM204_PODIUM_DRAWER_RUNTIME_ENTITY_ID,
      bounds: { ...room204Layout.podium.drawerBounds }
    },
    slots: Object.fromEntries(room204Layout.slotTargets.map((slot) => [slot.slotId, {
      targetId: `a2_room204_slot_${slot.slotId}`,
      entityId: room204SlotRuntimeEntityId(slot.slotId),
      bounds: { ...slot.bounds }
    }])),
    groups: Object.fromEntries(ROOM204_GROUP_ORDER.map((groupId) => [groupId, {
      targetId: room204GroupTargetId(groupId),
      entityId: room204GroupRuntimeEntityId(groupId),
      bounds: { ...ROOM204_GROUPS[groupId].targetBounds }
    }]))
  };
  const task9RuntimeTargets = [
    room204RuntimeTargets.residual,
    room204RuntimeTargets.drawer,
    ...Object.values(room204RuntimeTargets.slots),
    ...Object.values(room204RuntimeTargets.groups)
  ];
  const task9FactPrerequisites = [
    ...bakeryFactOrder,
    ...insertedA1Facts,
    "classroom_104_chalk_residual_observed",
    "classroom_105_terminal_replay_checked",
    "elevator_history_observed",
    "elevator_history_calibrated",
    "a1_time_route_compared",
    ...insertedA3Facts,
    ...insertedA2Facts
  ];

  function makeRoom204State({
    facts = [],
    placements = [],
    mode = "light",
    floor = "A2",
    roomId = floor === "A3" ? "a3_reference_classroom" : "a2_room204",
    clockPositioningPlate = false,
    phase = "room204_restore",
    stairSolved = true,
    a3ReferenceObserved = stairSolved
  } = {}) {
    const state = makeState({
      facts: [
        ...task9FactPrerequisites,
        ...(stairSolved
          ? ["misaligned_stair_solved"]
          : []),
        ...(a3ReferenceObserved ? ["a3_reference_observed", "a3_identity_context_observed"] : []),
        ...facts
      ],
      mode,
      roomId,
      phase
    });
    return {
      ...state,
      rpgCheckpoint: floor === "A3" ? "c4_a3_wayfinding" : floor === "A2" ? "c4_a2_corridor" : "c4_a1_lobby",
      items: { ...state.items, clockPositioningPlate },
      chapter4: {
        ...state.chapter4,
        floor,
        roomId,
        room204Placements: placements.map((placement) => ({ ...placement })),
        timeState: phase === "room204_restore" ? "1850_evening" : "2245_maintenance",
        worldTimeSeconds: phase === "room204_restore" ? 67800 : 81900,
        phoneStatusTimeSeconds: phase === "room204_restore" ? 67800 : 81900,
        guardMode: phase === "maintenance_repair" ? "patrol" : "absent"
      }
    };
  }

  for (const target of task9RuntimeTargets) {
    const contract = getChapterFour755TargetContract(target.targetId);
    const resolved = resolveChapterFour755RuntimeEntityTarget(
      target.targetId,
      target.entityId,
      target.bounds
    );
    assert(contract?.activation === "runtime_entity", `${target.targetId} must remain runtime-bound`);
    assert(contract?.bounds === null && contract?.contractPending === true, `${target.targetId} static bounds must remain closed`);
    assert(resolved?.contractPending === false, `${target.targetId} exact runtime bounds must resolve`);
    assert(sameJson(resolved?.bounds, target.bounds), `${target.targetId} must resolve to its layout rectangle`);
    assert(
      resolveChapterFour755RuntimeEntityTarget(target.targetId, `${target.entityId}-forged`, target.bounds) === null,
      `${target.targetId} must reject a forged entityId`
    );
    assert(
      resolveChapterFour755RuntimeEntityTarget(
        target.targetId,
        target.entityId,
        { ...target.bounds, x: target.bounds.x + 1 }
      ) === null,
      `${target.targetId} must reject a translated runtime rectangle`
    );
  }

  const a3Reference = getChapterFour755TargetContract("a3_reference_classroom_layout");
  const residualContract = getChapterFour755TargetContract("a2_room204_residual_group");
  assert(a3Reference?.requiredMode === "dark", "A3 reference observation must require dark mode");
  assert(residualContract?.requiredMode === "dark", "A2 residual observation must require dark mode");
  for (const slotId of ROOM204_SLOT_ORDER) {
    const slotContract = getChapterFour755TargetContract(`a2_room204_slot_${slotId}`);
    assert(slotContract?.boundsSource.kind === "runtime_entity", `${slotId} must use a runtime entity bounds source`);
    assert(!Object.prototype.hasOwnProperty.call(slotContract ?? {}, "acceptedPieceId"), `${slotId} must not bind a piece id`);
  }

  const arbitraryModelPlacements = [];
  for (const [index, pieceId] of ROOM204_PIECE_ORDER.entries()) {
    const slotId = ROOM204_SLOT_ORDER[ROOM204_SLOT_ORDER.length - 1 - index];
    const resolution = resolveRoom204Placement(arbitraryModelPlacements, {
      pieceId,
      slotId,
      orientation: "up"
    });
    assert(resolution.accepted, `${pieceId} must be accepted in arbitrary slot ${slotId}`);
    if (resolution.accepted) arbitraryModelPlacements.splice(0, arbitraryModelPlacements.length, ...resolution.placements);
  }
  assert(isRoom204PlacementSetComplete(arbitraryModelPlacements), "arbitrary piece-to-slot permutation must be a complete solution");
  assert(
    resolveRoom204Placement([], { pieceId: "unknown_piece", slotId: ROOM204_SLOT_ORDER[0], orientation: "up" }).issue === "unknown_piece",
    "pure model must classify unknown pieces"
  );
  assert(
    resolveRoom204Placement([], { pieceId: ROOM204_PIECE_ORDER[0], slotId: "unknown_slot", orientation: "up" }).issue === "unknown_slot",
    "pure model must classify unknown slots"
  );
  assert(
    resolveRoom204Placement([], { pieceId: ROOM204_PIECE_ORDER[0], slotId: ROOM204_SLOT_ORDER[0], orientation: "down" }).issue === "invalid_orientation",
    "pure model must classify non-up orientation"
  );
  const onePlacement = resolveRoom204Placement([], {
    pieceId: ROOM204_PIECE_ORDER[0],
    slotId: ROOM204_SLOT_ORDER[0],
    orientation: "up"
  });
  assert(onePlacement.accepted, "pure model first placement fixture must be accepted");
  const onePlacementList = onePlacement.accepted ? onePlacement.placements : [];
  assert(
    resolveRoom204Placement(onePlacementList, {
      pieceId: ROOM204_PIECE_ORDER[0],
      slotId: ROOM204_SLOT_ORDER[1],
      orientation: "up"
    }).issue === "duplicate_piece",
    "pure model must classify duplicate pieces"
  );
  assert(
    resolveRoom204Placement(onePlacementList, {
      pieceId: ROOM204_PIECE_ORDER[1],
      slotId: ROOM204_SLOT_ORDER[0],
      orientation: "up"
    }).issue === "occupied_slot",
    "pure model must classify occupied slots"
  );

  assertZeroWriteRejection(
    makeRoom204State({ floor: "A3", roomId: "a3_reference_classroom", mode: "light", stairSolved: false }),
    { type: "observe_a3_reference", targetId: "a3_reference_classroom_layout", spatial: validSpatial },
    "wrong_mode",
    undefined,
    "A3 reference in light mode"
  );
  assertZeroWriteRejection(
    makeRoom204State({ floor: "A2", roomId: "a2_room204", stairSolved: false }),
    { type: "observe_a3_reference", targetId: "a3_reference_classroom_layout", spatial: validSpatial },
    "locked",
    undefined,
    "A3 reference from wrong floor"
  );
  assertZeroWriteRejection(
    makeRoom204State({ facts: ["a3_reference_observed"], mode: "light" }),
    { type: "observe_room204_residual", targetId: room204RuntimeTargets.residual.targetId, spatial: validSpatial },
    "wrong_mode",
    room204RuntimeTargets.residual,
    "A2 residual in light mode"
  );
  assertZeroWriteRejection(
    makeRoom204State({ facts: ["a3_reference_observed"], mode: "dark", roomId: "a2_unknown" }),
    { type: "observe_room204_residual", targetId: room204RuntimeTargets.residual.targetId, spatial: validSpatial },
    "locked",
    room204RuntimeTargets.residual,
    "A2 residual from wrong room"
  );
  assertZeroWriteRejection(
    makeRoom204State({ facts: ["a3_reference_observed"], mode: "dark" }),
    { type: "observe_room204_residual", targetId: room204RuntimeTargets.residual.targetId, spatial: validSpatial },
    "locked",
    undefined,
    "A2 residual without measured runtime bounds"
  );
  assertZeroWriteRejection(
    makeRoom204State({ facts: ["a3_reference_observed", "room204_residual_observed"], mode: "light" }),
    {
      type: "place_room204_piece",
      pieceId: ROOM204_PIECE_ORDER[0],
      slotId: ROOM204_SLOT_ORDER[0],
      orientation: "down",
      targetId: `a2_room204_slot_${ROOM204_SLOT_ORDER[0]}`,
      spatial: validSpatial
    },
    "locked",
    room204RuntimeTargets.slots[ROOM204_SLOT_ORDER[0]],
    "non-up Room204 placement"
  );
  assertZeroWriteRejection(
    makeRoom204State({ placements: arbitraryModelPlacements }),
    { type: "complete_room204_projection" },
    "locked",
    undefined,
    "projection completion without both observations"
  );
  const missingDutyBoardState = makeRoom204State({
    facts: ["a3_reference_observed", "room204_residual_observed", "room204_restored"],
    placements: arbitraryModelPlacements
  });
  missingDutyBoardState.chapter4.factIds = missingDutyBoardState.chapter4.factIds.filter(
    (factId) => factId !== "a1_duty_board_reconstructed"
  );
  assertZeroWriteRejection(
    missingDutyBoardState,
    { type: "complete_room204_projection" },
    "locked",
    undefined,
    "projection completion before the deferred A1 duty-board evidence is consumed"
  );

  const preReferenceStore = createGameStore(makeRoom204State({
    floor: "A3",
    roomId: "a3_reference_classroom",
    stairSolved: false,
    a3ReferenceObserved: false,
    mode: "dark"
  }));
  const preReferenceController = new ChapterFourTemporalMazeController(preReferenceStore, new EventBus());
  const stairBeforeReference = preReferenceController.resolve755Intent({ type: "complete_misaligned_stair" });
  assert(!stairBeforeReference.accepted, "misaligned stair must remain locked until the A3 reference is recorded");
  const earlyQuestions = preReferenceController.resolve755Intent({
    type: "complete_zhu_two_questions",
    purposeAnswer: "seek_truth",
    personAnswer: "responsible"
  });
  assert(!earlyQuestions.accepted, "Zhu's two questions must remain reserved for the exterior closure");

  const roomSequenceStore = createGameStore(makeRoom204State({
    floor: "A3",
    roomId: "a3_reference_classroom",
    stairSolved: false,
    mode: "dark"
  }));
  const roomSequenceController = new ChapterFourTemporalMazeController(roomSequenceStore, new EventBus());
  const referenceResult = roomSequenceController.resolve755Intent({
    type: "observe_a3_reference",
    targetId: "a3_reference_classroom_layout",
    spatial: validSpatial
  });
  assert(referenceResult.accepted && referenceResult.changed, "A3 dark reference must commit once");
  assert(roomSequenceStore.getState().chapter4.factIds.includes("a3_reference_observed"), "A3 reference fact must commit");
  assert(roomSequenceStore.getState().chapter4.mode === "dark", "A3 floor record must remain in dark observation");
  const a3RecordResult = roomSequenceController.resolve755Intent({
    type: "observe_elevator_floor_record",
    floor: "A3"
  });
  assert(
    a3RecordResult.accepted
      && roomSequenceStore.getState().chapter4.factIds.includes("elevator_a3_arrival_record_observed"),
    "A3 arrival chime and door record must commit independently"
  );
  const a3RecordLightMode = roomSequenceController.resolve755Intent({ type: "set_mode", mode: "light" });
  assert(a3RecordLightMode.accepted, "A3 investigation must return to light operation without losing its record");
  const blockedDirectA2 = roomSequenceController.resolve755Intent({
    type: "move_to_location",
    floor: "A2",
    roomId: "a2_room204",
    checkpoint: "c4_a2_corridor"
  });
  assert(!blockedDirectA2.accepted && blockedDirectA2.detailCode === "misaligned_stair_required", "A3 reference alone must keep A2 behind the stair puzzle");
  const stairResult = roomSequenceController.resolve755Intent({ type: "complete_misaligned_stair" });
  assert(stairResult.accepted && stairResult.changed, "A3 reference must unlock the two-level stair completion");
  assert(roomSequenceStore.getState().chapter4.floor === "A2", "stair completion must relocate to A2");
  const moveToA2 = roomSequenceController.resolve755Intent({
    type: "move_to_location",
    floor: "A2",
    roomId: "a2_room204",
    checkpoint: "c4_a2_corridor"
  });
  assert(moveToA2.accepted, "room sequence must accept the A2 room alias after stair arrival");
  const a2RecordDarkMode = roomSequenceController.resolve755Intent({ type: "set_mode", mode: "dark" });
  assert(a2RecordDarkMode.accepted, "A2 floor record must be readable after entering dark observation");
  const a2RecordResult = roomSequenceController.resolve755Intent({
    type: "observe_elevator_floor_record",
    floor: "A2"
  });
  assert(
    a2RecordResult.accepted
      && roomSequenceStore.getState().chapter4.factIds.includes("elevator_a2_call_record_observed"),
    "A2 unserved call and door-machine record must commit independently"
  );
  const chainLightMode = roomSequenceController.resolve755Intent({ type: "set_mode", mode: "light" });
  assert(chainLightMode.accepted, "stop-chain reconstruction must run in light operation");
  const beforeWrongChain = snapshot(roomSequenceStore.getState());
  const wrongChain = roomSequenceController.resolve755Intent({
    type: "reconstruct_elevator_stop_chain",
    actualArrivalFloor: "A2",
    unservedCallFloor: "A3"
  });
  assert(!wrongChain.accepted && wrongChain.reason === "incorrect", "reversed elevator stop chain must be rejected");
  assert(snapshot(roomSequenceStore.getState()) === beforeWrongChain, "wrong elevator stop chain must remain zero-write");
  const correctChain = roomSequenceController.resolve755Intent({
    type: "reconstruct_elevator_stop_chain",
    actualArrivalFloor: "A3",
    unservedCallFloor: "A2"
  });
  assert(
    correctChain.accepted
      && roomSequenceStore.getState().chapter4.factIds.includes("elevator_stop_chain_reconstructed"),
    "A3 arrival and A2 unserved-call reconstruction must commit once"
  );
  const darkResult = roomSequenceController.resolve755Intent({ type: "set_mode", mode: "dark" });
  assert(darkResult.accepted, "room sequence must re-enter dark observation mode for the Room204 residual");
  const darkProjection = selectChapterFourMazeProjection(roomSequenceStore.getState());
  assert(darkProjection.npcIds.includes("a2_evening_residual_group"), "A2 residual visual must project in dark mode");
  const residualResult = roomSequenceController.resolve755Intent({
    type: "observe_room204_residual",
    targetId: room204RuntimeTargets.residual.targetId,
    spatial: validSpatial
  }, room204RuntimeTargets.residual);
  assert(residualResult.accepted && residualResult.changed, "A2 dark residual observation must commit once");
  const lightResult = roomSequenceController.resolve755Intent({ type: "set_mode", mode: "light" });
  assert(lightResult.accepted, "room sequence must return to light operation mode");
  const lightProjection = selectChapterFourMazeProjection(roomSequenceStore.getState());
  assert(!lightProjection.npcIds.includes("a2_evening_residual_group"), "A2 residual visual must not project in light mode");

  for (const [index, groupId] of ROOM204_GROUP_ORDER.entries()) {
    const runtimeTarget = room204RuntimeTargets.groups[groupId];
    const result = roomSequenceController.resolve755Intent({
      type: "place_room204_group",
      groupId,
      targetId: runtimeTarget.targetId,
      spatial: validSpatial
    }, runtimeTarget);
    assert(result.accepted && result.changed, `${groupId} must commit as one grouped Room204 operation`);
    assert(
      roomSequenceStore.getState().chapter4.factIds.includes("room204_restored") === (index === ROOM204_GROUP_ORDER.length - 1),
      `room204_restored must be written only by the fourth grouped operation (${index + 1})`
    );
  }
  const restoredState = roomSequenceStore.getState();
  assert(isRoom204PlacementSetComplete(restoredState.chapter4.room204Placements), "four grouped operations must preserve the complete twelve-piece save set");
  assert(!selectChapterFourMazeProjection(restoredState).availableTargetIds.includes("a2_room204_podium_drawer"), "drawer must remain closed before projection completion");
  const projectionResult = roomSequenceController.resolve755Intent({ type: "complete_room204_projection" });
  assert(projectionResult.accepted && projectionResult.changed, "projection handshake completion must commit once");
  assert(roomSequenceStore.getState().chapter4.factIds.includes("room204_projection_completed"), "projection completion fact must commit");
  const afterProjectionSnapshot = snapshot(roomSequenceStore.getState());
  const duplicateProjection = roomSequenceController.resolve755Intent({ type: "complete_room204_projection" });
  assert(!duplicateProjection.accepted && !duplicateProjection.changed, "projection handshake may resolve only once");
  assert(snapshot(roomSequenceStore.getState()) === afterProjectionSnapshot, "duplicate projection completion must be zero-write");
  assert(selectChapterFourMazeProjection(roomSequenceStore.getState()).availableTargetIds.includes("a2_room204_podium_drawer"), "drawer must project only after projection completion");
  const collectPlateResult = roomSequenceController.resolve755Intent({
    type: "collect_positioning_plate",
    targetId: room204RuntimeTargets.drawer.targetId,
    spatial: validSpatial
  }, room204RuntimeTargets.drawer);
  assert(collectPlateResult.accepted && collectPlateResult.changed, "positioning plate pickup must commit once");
  assert(roomSequenceStore.getState().chapter4.factIds.includes("positioning_plate_collected"), "positioning plate pickup fact must commit");
  assert(roomSequenceStore.getState().items.clockPositioningPlate === true, "positioning plate pickup must grant item atomically");
  const afterPlateSnapshot = snapshot(roomSequenceStore.getState());
  const duplicatePlate = roomSequenceController.resolve755Intent({
    type: "collect_positioning_plate",
    targetId: room204RuntimeTargets.drawer.targetId,
    spatial: validSpatial
  }, room204RuntimeTargets.drawer);
  assert(!duplicatePlate.accepted && !duplicatePlate.changed, "positioning plate pickup may resolve only once");
  assert(snapshot(roomSequenceStore.getState()) === afterPlateSnapshot, "duplicate positioning plate pickup must be zero-write");
  const returnToClock = roomSequenceController.resolve755Intent({
    type: "move_to_location",
    floor: "A1",
    roomId: "a1_hall_clock",
    checkpoint: "c4_a1_lobby"
  });
  assert(returnToClock.accepted, "held positioning plate must allow return to A1 clock");
  assert(selectChapterFourMazeProjection(roomSequenceStore.getState()).availableTargetIds.includes("a1_hall_clock_positioning_plate_slot"), "held positioning plate must project its A1 socket");
  const installPlateResult = roomSequenceController.resolve755Intent({
    type: "install_positioning_plate",
    itemId: "clockPositioningPlate",
    targetId: "a1_hall_clock_positioning_plate_slot",
    spatial: validSpatial
  });
  assert(installPlateResult.accepted && installPlateResult.changed, "positioning plate installation must commit once");
  const maintenanceState = roomSequenceStore.getState();
  assert(maintenanceState.chapter4.phase === "maintenance_repair", "positioning plate installation must enter maintenance_repair");
  assert(maintenanceState.chapter4.timeState === "1850_evening", "positioning plate installation must keep the committed 18:50 time until the player adjusts the clock");
  assert(maintenanceState.chapter4.worldTimeSeconds === 67800 && maintenanceState.chapter4.phoneStatusTimeSeconds === 67800, "positioning plate installation must keep world and phone time at 18:50");
  assert(maintenanceState.chapter4.floor === "A1" && maintenanceState.chapter4.roomId === "a1_hall_clock", "positioning plate installation must relocate atomically to A1 clock");
  assert(maintenanceState.rpgCheckpoint === "c4_a1_lobby", "positioning plate installation must use the A1 safe checkpoint");
  assert(maintenanceState.chapter4.factIds.includes("positioning_plate_installed"), "positioning plate installation fact must commit");
  assert(maintenanceState.items.clockPositioningPlate === false, "positioning plate installation must consume the item");
  assert(maintenanceState.chapter4.guardMode === "absent", "the maintenance guard must not appear before the 22:45 adjustment");
  assert(selectChapterFourMazeProjection(maintenanceState).availableTargetIds.includes("a1_hall_clock"), "the hall clock must remain actionable for the required 22:45 adjustment");
  assert(selectQuestViewModel(maintenanceState).steps[0]?.id === "chapter_four_tune_clock_to_2245", "the next objective must ask the player to tune the clock to 22:45");
  const maintenanceSnapshot = snapshot(maintenanceState);
  const duplicatePlateInstall = roomSequenceController.resolve755Intent({
    type: "install_positioning_plate",
    itemId: "clockPositioningPlate",
    targetId: "a1_hall_clock_positioning_plate_slot",
    spatial: validSpatial
  });
  assert(!duplicatePlateInstall.accepted && !duplicatePlateInstall.changed, "positioning plate installation may resolve only once");
  assert(snapshot(roomSequenceStore.getState()) === maintenanceSnapshot, "duplicate positioning plate installation must be zero-write");
  const tune2245Result = roomSequenceController.resolve755Intent({
    type: "adjust_hall_clock_time",
    targetId: "a1_hall_clock",
    targetTimeState: "2245_maintenance",
    spatial: validSpatial
  });
  assert(tune2245Result.accepted && tune2245Result.changed, "the positioning plate must unlock the explicit 22:45 adjustment");
  const tunedMaintenanceState = roomSequenceStore.getState();
  assert(tunedMaintenanceState.chapter4.phase === "maintenance_repair", "the 22:45 adjustment must stay in maintenance_repair");
  assert(tunedMaintenanceState.chapter4.timeState === "2245_maintenance", "the explicit clock action must restore 22:45 maintenance time");
  assert(tunedMaintenanceState.chapter4.worldTimeSeconds === 81900 && tunedMaintenanceState.chapter4.phoneStatusTimeSeconds === 81900, "the explicit 22:45 adjustment must synchronize world and phone time");
  assert(tunedMaintenanceState.chapter4.guardMode === "patrol", "the maintenance guard must begin patrol only after the 22:45 adjustment");
  assert(sameJson(selectChapterFourMazeProjection(tunedMaintenanceState).activePlateIds, ["a1_2245_maintenance"]), "the explicit 22:45 adjustment must activate the maintenance plate");

  const task10AndLaterTargets = [
    "a1_bakery_back_pry_bar",
    "a1_cleaning_cart_wheel_cover",
    "a1_cleaning_cart_oil_bottle",
    "a1_cleaning_cart_wheel",
    "a1_hall_clock_gear",
    "a1_hall_clock_minute_endpoint",
    "a1_power_panel",
    "a2_202_threshold",
    "a2_202_projection",
    "a1_campus_card_reader",
    "a1_attendance_paper_slot"
  ];
  const completePlacements = arbitraryModelPlacements.map((placement) => ({ ...placement }));
  const roomQuestCases = [
    ["reference", [], [], "chapter_four_resolve_a3_archive_chain", false],
    ["stair", ["a3_reference_observed"], [], "chapter_four_solve_misaligned_stair", false],
    ["elevator chain", ["elevator_a2_call_record_observed", "elevator_a3_arrival_record_observed"], [], "chapter_four_resolve_elevator_stop_chain", true],
    ["residual", [...elevatorStopChainFacts, "a3_reference_observed"], [], "chapter_four_restore_room204", true],
    ["restore", [...elevatorStopChainFacts, "a3_reference_observed", "room204_residual_observed"], [], "chapter_four_restore_room204", true],
    ["projection", [...elevatorStopChainFacts, "a3_reference_observed", "room204_residual_observed", "room204_restored"], completePlacements, "chapter_four_watch_room204_projection", true],
    ["collect", [...elevatorStopChainFacts, "a3_reference_observed", "room204_residual_observed", "room204_restored", "room204_projection_completed"], completePlacements, "chapter_four_collect_positioning_plate", true],
    ["install", [...elevatorStopChainFacts, "a3_reference_observed", "room204_residual_observed", "room204_restored", "room204_projection_completed", "positioning_plate_collected"], completePlacements, "chapter_four_install_positioning_plate", true]
  ];
  for (const [label, facts, placements, expectedTaskId, stairSolved] of roomQuestCases) {
    const state = makeRoom204State({ facts, placements, clockPositioningPlate: label === "install", stairSolved });
    const quest = selectQuestViewModel(state);
    assert(quest.steps.length === 1, `${label} Room204 quest must reveal exactly one step`);
    assert(quest.steps[0]?.id === expectedTaskId, `${label} Room204 quest must select ${expectedTaskId}`);
    const targetIds = selectChapterFourMazeProjection(state).availableTargetIds;
    assert(task10AndLaterTargets.every((targetId) => !targetIds.includes(targetId)), `${label} Room204 projection must keep Task10+ targets closed`);
  }

  const answeredZhuState = makeRoom204State({ facts: ["zhu_two_questions_answered"] });
  const preservedZhuAnswers = hydrate({
    ...answeredZhuState,
    chapter4: {
      ...answeredZhuState.chapter4,
      zhuQuestionAnswers: { purpose: "serve_public", person: "clear_minded" }
    }
  });
  assert(
    sameJson(preservedZhuAnswers.chapter4.zhuQuestionAnswers, {
      purpose: "serve_public",
      person: "clear_minded"
    }),
    "valid Zhu answers must survive save hydration"
  );
  const repairedZhuAnswers = hydrate({
    ...answeredZhuState,
    chapter4: {
      ...answeredZhuState.chapter4,
      zhuQuestionAnswers: { purpose: null, person: null }
    }
  });
  assert(
    sameJson(repairedZhuAnswers.chapter4.zhuQuestionAnswers, {
      purpose: "seek_truth",
      person: "responsible"
    }),
    "answered Zhu fact with missing answers must hydrate to safe defaults"
  );
  const clearedUncommittedZhuAnswers = hydrate({
    ...makeRoom204State({ stairSolved: false }),
    chapter4: {
      ...makeRoom204State({ stairSolved: false }).chapter4,
      zhuQuestionAnswers: { purpose: "serve_public", person: "clear_minded" }
    }
  });
  assert(
    sameJson(clearedUncommittedZhuAnswers.chapter4.zhuQuestionAnswers, { purpose: null, person: null }),
    "Zhu answers without the committed fact must be removed during hydration"
  );

  const maliciousLoaded = hydrate(makeRoom204State({
    facts: [
      "a3_reference_observed",
      "room204_residual_observed",
      "room204_restored",
      "room204_projection_completed",
      "positioning_plate_collected",
      "positioning_plate_installed"
    ],
    clockPositioningPlate: true,
    placements: [
      { pieceId: ROOM204_PIECE_ORDER[0], slotId: ROOM204_SLOT_ORDER[0], orientation: "up" },
      { pieceId: ROOM204_PIECE_ORDER[0], slotId: ROOM204_SLOT_ORDER[1], orientation: "up" },
      { pieceId: ROOM204_PIECE_ORDER[1], slotId: ROOM204_SLOT_ORDER[0], orientation: "up" },
      { pieceId: ROOM204_PIECE_ORDER[2], slotId: ROOM204_SLOT_ORDER[2], orientation: "down" },
      { pieceId: "unknown_piece", slotId: ROOM204_SLOT_ORDER[3], orientation: "up" }
    ]
  }));
  assert(maliciousLoaded.chapter4.room204Placements.length === 1, "malicious save must remove unknown, duplicate and non-up placements");
  assert(!maliciousLoaded.chapter4.factIds.includes("room204_restored"), "incomplete room save must clear restored fact");
  assert(!maliciousLoaded.chapter4.factIds.includes("room204_projection_completed"), "incomplete room save must clear projection fact");
  assert(!maliciousLoaded.chapter4.factIds.includes("positioning_plate_collected"), "incomplete room save must clear collection fact");
  assert(!maliciousLoaded.chapter4.factIds.includes("positioning_plate_installed"), "room phase save must clear impossible installed fact");
  assert(maliciousLoaded.items.clockPositioningPlate === false, "malicious room save must discard a stale positioning plate item");

  const partialLoaded = hydrate(makeRoom204State({
    facts: ["a3_reference_observed", "room204_residual_observed"],
    placements: completePlacements.slice(0, 5)
  }));
  assert(partialLoaded.chapter4.room204Placements.length === 5, "partial room save must preserve valid unique progress");
  assert(!partialLoaded.chapter4.factIds.includes("room204_restored"), "partial room save must remain resumable before restored");

  const completeLoaded = hydrate(makeRoom204State({
    facts: ["a3_reference_observed", "room204_residual_observed"],
    placements: completePlacements
  }));
  assert(completeLoaded.chapter4.factIds.includes("room204_restored"), "complete room save plus both observations must synthesize restored");
  assert(!completeLoaded.chapter4.factIds.includes("room204_projection_completed"), "complete room save must still require projection handshake");

  const collectedLoaded = hydrate(makeRoom204State({
    facts: [
      "a3_reference_observed",
      "room204_residual_observed",
      "room204_restored",
      "room204_projection_completed",
      "positioning_plate_collected"
    ],
    placements: completePlacements,
    clockPositioningPlate: false
  }));
  assert(collectedLoaded.items.clockPositioningPlate === true, "collection fact must restore a missing positioning plate item");
  assert(collectedLoaded.chapter4.factIds.includes("positioning_plate_collected"), "valid collected save must preserve causal collection fact");

  const laterLoaded = hydrate(makeRoom204State({
    facts: ["positioning_plate_installed"],
    placements: completePlacements.slice(0, 1),
    clockPositioningPlate: true,
    phase: "maintenance_repair",
    floor: "A1",
    roomId: "a1_hall_clock"
  }));
  assert(isRoom204PlacementSetComplete(laterLoaded.chapter4.room204Placements), "later phase save must repair missing Room204 placements canonically");
  assert(sameJson(laterLoaded.chapter4.room204Placements, createCanonicalCompleteRoom204Placements()), "later phase save must use canonical recovery placements only");
  assert([
    "a3_reference_observed",
    "room204_residual_observed",
    "room204_restored",
    "room204_projection_completed",
    "positioning_plate_collected",
    "positioning_plate_installed"
  ].every((factId) => laterLoaded.chapter4.factIds.includes(factId)), "later phase save must restore the strict Room204 causal closure");
  assert(laterLoaded.items.clockPositioningPlate === false, "later phase save must keep the installed positioning plate consumed");

  // Task 10: 22:45 maintenance chain, ordinary patrol recovery and pure guard behavior.
  const maintenanceLayout = chapterFourLayout.maintenanceRuntime;
  const maintenanceTargetIds = maintenanceLayout.targetEntities.map((entry) => entry.targetId);
  const maintenanceRuntimeTargets = Object.fromEntries(
    maintenanceLayout.targetEntities.map((entry) => [entry.targetId, runtimeTargetFromLayout(entry.targetId)])
  );
  const maintenanceFactOrder = [
    "cart_wheel_inspected",
    "cart_wheel_cover_opened",
    "cart_wheel_repaired",
    "clock_gear_repaired"
  ];
  const room204CompleteFacts = [
    "a3_reference_observed",
    "a3_identity_context_observed",
    "a1_time_route_compared",
    "room204_residual_observed",
    "room204_restored",
    "room204_projection_completed",
    "room204_projection_composite_completed",
    "room202_endpoint_inferred",
    "maintenance_incident_linked",
    "positioning_plate_collected",
    "positioning_plate_installed"
  ];
  const task11AndLaterTargets = [
    "a1_hall_clock_minute_endpoint",
    "a1_power_panel",
    "a2_202_threshold",
    "a2_202_projection",
    "a1_campus_card_reader",
    "a1_attendance_paper_slot"
  ];
  const finalClockRuntimeTarget = runtimeTargetFromLayout("a1_hall_clock_minute_endpoint");
  const powerPanelRuntimeTarget = runtimeTargetFromLayout("a1_power_panel");

  function makeMaintenanceState({
    facts = [],
    shortPryBar = false,
    universalLubricatingOil = false,
    mode = "light",
    floor = "A1",
    roomId = "a1_lobby",
    guardMode = "patrol",
    chaseAttempt = 0,
    inventoryOpen = false,
    selectedItem = null
  } = {}) {
    const state = makeRoom204State({
      facts: [...room204CompleteFacts, ...facts],
      placements: createCanonicalCompleteRoom204Placements(),
      mode,
      floor,
      roomId,
      phase: "maintenance_repair"
    });
    return {
      ...state,
      rpgCheckpoint: floor === "A1" ? "c4_a1_lobby" : "c4_a2_corridor",
      items: {
        ...state.items,
        shortPryBar,
        universalLubricatingOil
      },
      ui: {
        ...state.ui,
        inventoryOpen,
        selectedItem
      },
      chapter4: {
        ...state.chapter4,
        floor,
        roomId,
        timeAuthority: "hall_clock",
        timeState: "2245_maintenance",
        worldTimeSeconds: 81900,
        phoneStatusTimeSeconds: 81900,
        phoneStatusTimeTrusted: true,
        guardMode,
        chaseAttempt,
        lightGrid: { mask: 14, locked: false }
      }
    };
  }

  function maintenanceFixture(targetId) {
    const target = maintenanceRuntimeTargets[targetId];
    if (targetId === "a1_cleaning_cart_wheel_inspection") {
      return {
        state: makeMaintenanceState(),
        intent: { type: "inspect_cart_wheel", targetId, spatial: validSpatial },
        target
      };
    }
    if (targetId === "a1_bakery_back_pry_bar") {
      return {
        state: makeMaintenanceState(),
        intent: { type: "collect_short_pry_bar", targetId, spatial: validSpatial },
        target
      };
    }
    if (targetId === "a1_cleaning_cart_wheel_cover") {
      return {
        state: makeMaintenanceState({ facts: ["cart_wheel_inspected"], shortPryBar: true }),
        intent: {
          type: "open_cart_wheel_cover",
          itemId: "shortPryBar",
          targetId,
          spatial: validSpatial
        },
        target
      };
    }
    if (targetId === "a1_cleaning_cart_oil_bottle") {
      return {
        state: makeMaintenanceState({
          facts: ["cart_wheel_inspected", "cart_wheel_cover_opened"]
        }),
        intent: { type: "collect_lubricating_oil", targetId, spatial: validSpatial },
        target
      };
    }
    if (targetId === "a1_cleaning_cart_wheel") {
      return {
        state: makeMaintenanceState({
          facts: ["cart_wheel_inspected", "cart_wheel_cover_opened"],
          universalLubricatingOil: true
        }),
        intent: {
          type: "lubricate_cart_wheel",
          itemId: "universalLubricatingOil",
          targetId,
          spatial: validSpatial
        },
        target
      };
    }
    return {
      state: makeMaintenanceState({
        facts: ["cart_wheel_inspected", "cart_wheel_cover_opened", "cart_wheel_repaired"],
        universalLubricatingOil: true
      }),
      intent: {
        type: "lubricate_clock_gear",
        itemId: "universalLubricatingOil",
        targetId,
        spatial: validSpatial
      },
      target
    };
  }

  for (const targetId of maintenanceTargetIds) {
    const fixture = maintenanceFixture(targetId);
    const contract = getChapterFour755TargetContract(targetId);
    const resolved = resolveChapterFour755RuntimeEntityTarget(
      fixture.target.targetId,
      fixture.target.entityId,
      fixture.target.bounds
    );
    assert(contract?.activation === "runtime_entity", `${targetId} must be a runtime-entity target`);
    assert(contract?.bounds === null && contract?.contractPending === true, `${targetId} static contract must remain closed`);
    assert(resolved?.contractPending === false, `${targetId} exact runtime target must resolve`);
    assert(sameJson(resolved?.bounds, fixture.target.bounds), `${targetId} resolved bounds must equal the layout installation`);
    assert(
      resolveChapterFour755RuntimeEntityTarget(targetId, `${fixture.target.entityId}-forged`, fixture.target.bounds) === null,
      `${targetId} must reject a forged runtime entity id`
    );
    const translatedBounds = { ...fixture.target.bounds, x: fixture.target.bounds.x + 1 };
    assert(
      resolveChapterFour755RuntimeEntityTarget(targetId, fixture.target.entityId, translatedBounds) === null,
      `${targetId} must reject translated runtime bounds`
    );
  }

  for (const roomId of ["a1_lobby", "a1_hall_clock", "a1_bakery", "a1_cleaning_cart"]) {
    const state = makeMaintenanceState({ roomId });
    const projected = selectChapterFourMazeProjection(state).availableTargetIds;
    assert(projected.includes("a1_cleaning_cart_wheel_inspection"), `${roomId} must accept the wheel-inspection room alias`);
    assert(
      ["a1_bakery_back_pry_bar", "a1_cleaning_cart_oil_bottle", "a1_hall_clock_gear"]
        .every((targetId) => !projected.includes(targetId)),
      `${roomId} must keep legacy pickup and second lubrication targets closed`
    );
  }

  const maintenanceStore = createGameStore(makeMaintenanceState());
  const maintenanceEvents = new EventBus();
  const maintenanceController = new ChapterFourTemporalMazeController(maintenanceStore, maintenanceEvents);
  const expectedQuestIds = [
    "chapter_four_inspect_cart_wheel",
    "chapter_four_open_cart_wheel_cover",
    "chapter_four_lubricate_cart_wheel",
    "chapter_four_turn_clock_to_0755"
  ];
  assert(
    selectQuestViewModel(maintenanceStore.getState()).steps[0]?.id === expectedQuestIds[0],
    "maintenance must begin with wheel inspection as the one current objective"
  );
  const initialMaintenanceProjection = selectChapterFourMazeProjection(maintenanceStore.getState()).availableTargetIds;
  assert(initialMaintenanceProjection.includes("a1_cleaning_cart_wheel_inspection"), "initial maintenance must project wheel inspection");
  assert(
    ["a1_bakery_back_pry_bar", "a1_cleaning_cart_wheel_cover", "a1_cleaning_cart_oil_bottle", "a1_cleaning_cart_wheel", "a1_hall_clock_gear"]
      .every((targetId) => !initialMaintenanceProjection.includes(targetId)),
    "initial maintenance must keep later physical targets closed"
  );
  assert(task11AndLaterTargets.every((targetId) => !initialMaintenanceProjection.includes(targetId)), "initial maintenance must keep Task11+ targets closed");

  const inspectionIntent = maintenanceFixture("a1_cleaning_cart_wheel_inspection").intent;
  const inspectionTarget = maintenanceRuntimeTargets.a1_cleaning_cart_wheel_inspection;
  assertZeroWriteRejection(
    maintenanceStore.getState(),
    { ...inspectionIntent, spatial: { distance: "too_far" } },
    "too_far",
    inspectionTarget,
    "maintenance inspection too far"
  );
  const beforeInspection = snapshot(maintenanceStore.getState());
  const inspection = maintenanceController.resolve755Intent(inspectionIntent, inspectionTarget);
  assert(inspection.accepted && !inspection.changed, "maintenance inspection must open diagnosis as a read-only request");
  assert(snapshot(maintenanceStore.getState()) === beforeInspection, "maintenance inspection must not write before diagnosis completion");

  const wrongDiagnosisState = snapshot(maintenanceStore.getState());
  const wrongDiagnosis = maintenanceController.resolve755Intent({
    type: "complete_maintenance_diagnosis",
    answers: { wheel_sound: "oil_shortage", clock_jam: "gear_offset", oil_trace: "latch" }
  });
  assert(!wrongDiagnosis.accepted && !wrongDiagnosis.changed && wrongDiagnosis.reason === "incorrect", "wrong maintenance diagnosis must reject as incorrect");
  assert(snapshot(maintenanceStore.getState()) === wrongDiagnosisState, "wrong maintenance diagnosis must be zero-write");

  const diagnosisIntent = {
    type: "complete_maintenance_diagnosis",
    answers: { wheel_sound: "latch", clock_jam: "gear_offset", oil_trace: "oil_shortage" }
  };
  const diagnosis = maintenanceController.resolve755Intent(diagnosisIntent);
  assert(diagnosis.accepted && diagnosis.changed, "correct maintenance diagnosis must commit once");
  const diagnosedState = maintenanceStore.getState();
  assert(diagnosedState.chapter4.factIds.includes("cart_wheel_inspected"), "diagnosis must write cart_wheel_inspected");
  assert(diagnosedState.items.shortPryBar && diagnosedState.items.universalLubricatingOil, "diagnosis must prepare both required tools");
  assert(selectQuestViewModel(diagnosedState).steps[0]?.id === expectedQuestIds[1], "diagnosis must reveal the wheel-cover action");
  const diagnosisSnapshot = snapshot(diagnosedState);
  const duplicateDiagnosis = maintenanceController.resolve755Intent(diagnosisIntent);
  assert(!duplicateDiagnosis.accepted && !duplicateDiagnosis.changed, "completed maintenance diagnosis must reject a duplicate");
  assert(snapshot(maintenanceStore.getState()) === diagnosisSnapshot, "duplicate maintenance diagnosis must be zero-write");

  for (const legacyTargetId of ["a1_bakery_back_pry_bar", "a1_cleaning_cart_oil_bottle", "a1_hall_clock_gear"]) {
    const fixture = maintenanceFixture(legacyTargetId);
    assertZeroWriteRejection(
      maintenanceStore.getState(),
      fixture.intent,
      "locked",
      fixture.target,
      `${legacyTargetId} legacy action`
    );
  }

  const coverFixture = maintenanceFixture("a1_cleaning_cart_wheel_cover");
  const coverOpened = maintenanceController.resolve755Intent(coverFixture.intent, coverFixture.target);
  assert(coverOpened.accepted && coverOpened.changed, "opening the diagnosed wheel cover must commit once");
  const coverOpenState = maintenanceStore.getState();
  assert(coverOpenState.chapter4.factIds.includes("cart_wheel_cover_opened"), "cover use must write cart_wheel_cover_opened");
  assert(coverOpenState.items.shortPryBar === false, "opening the cover must consume shortPryBar");
  assert(coverOpenState.items.universalLubricatingOil === true, "opening the cover must preserve the diagnosed lubricant");
  assert(selectQuestViewModel(coverOpenState).steps[0]?.id === expectedQuestIds[2], "opening the cover must reveal linked lubrication");

  const wheelFixture = maintenanceFixture("a1_cleaning_cart_wheel");
  const repaired = maintenanceController.resolve755Intent(wheelFixture.intent, wheelFixture.target);
  assert(repaired.accepted && repaired.changed, "linked wheel and clock lubrication must commit once");
  const gearRepairedState = maintenanceStore.getState();
  assert(gearRepairedState.chapter4.factIds.includes("cart_wheel_repaired"), "linked lubrication must write cart_wheel_repaired");
  assert(gearRepairedState.chapter4.factIds.includes("clock_gear_repaired"), "gear oil use must write clock_gear_repaired");
  assert(gearRepairedState.items.universalLubricatingOil === false, "linked lubrication must consume the oil");
  assert(gearRepairedState.chapter4.phase === "maintenance_repair", "gear repair must remain in maintenance_repair");
  assert(gearRepairedState.chapter4.timeState === "2245_maintenance", "gear repair must remain at 22:45 maintenance time");
  assert(gearRepairedState.chapter4.worldTimeSeconds === 81900, "gear repair must preserve 81900 world seconds");
  assert(gearRepairedState.chapter4.guardMode === "patrol", "gear repair must preserve ordinary patrol mode");
  assert(!gearRepairedState.chapter4.factIds.includes("paper_temporarily_out_of_inventory"), "gear repair must not begin blackout theft");
  const afterGearProjection = selectChapterFourMazeProjection(gearRepairedState).availableTargetIds;
  assert(maintenanceTargetIds.every((targetId) => !afterGearProjection.includes(targetId)), "gear repair must close all completed maintenance targets");
  assert(afterGearProjection.includes("a1_hall_clock_minute_endpoint"), "gear repair must project the Task11 programmatic minute endpoint");
  assert(
    task11AndLaterTargets.filter((targetId) => targetId !== "a1_hall_clock_minute_endpoint")
      .every((targetId) => !afterGearProjection.includes(targetId)),
    "gear repair must keep the power panel and Task12+ targets closed"
  );
  assert(
    selectQuestViewModel(gearRepairedState).objective === "把旧钟拨向 07:55",
    "gear repair must hand off to the exact Task11 clock objective"
  );
  assert(
    maintenanceEvents.getHistory().filter((event) => event.name === "chapter4_755_intent_committed").length === 3,
    "diagnosis, wheel-cover and linked lubrication must emit exactly three commit events"
  );

  for (const [intent, target, label] of [
    [
      {
        type: "trigger_minute_theft",
        targetId: "a1_hall_clock_minute_endpoint",
        spatial: validSpatial
      },
      finalClockRuntimeTarget,
      "legacy minute theft after gear repair"
    ],
    [
      {
        type: "toggle_light_zone",
        zoneId: "west_corridor",
        targetId: "a1_power_panel",
        spatial: validSpatial
      },
      powerPanelRuntimeTarget,
      "Task11 power panel before blackout"
    ]
  ]) {
    assertZeroWriteRejection(gearRepairedState, intent, "locked", target, label);
  }

  const maintenanceSnapshots = [diagnosedState, coverOpenState, gearRepairedState];
  const expectedMaintenanceSaveStates = [
    { facts: ["cart_wheel_inspected"], pry: true, oil: true },
    { facts: ["cart_wheel_inspected", "cart_wheel_cover_opened"], pry: false, oil: true },
    { facts: maintenanceFactOrder, pry: false, oil: false }
  ];
  maintenanceSnapshots.forEach((state, index) => {
    const loaded = hydrate(state);
    const expected = expectedMaintenanceSaveStates[index];
    const loadedFacts = loaded.chapter4.factIds.filter((factId) => maintenanceFactOrder.includes(factId));
    assert(sameJson(loadedFacts, expected.facts), `maintenance save state ${index + 1} must restore causal facts`);
    assert(loaded.items.shortPryBar === expected.pry, `maintenance save state ${index + 1} pry state mismatch`);
    assert(loaded.items.universalLubricatingOil === expected.oil, `maintenance save state ${index + 1} oil state mismatch`);
    assert(loaded.chapter4.phase === "maintenance_repair", `maintenance save state ${index + 1} must remain maintenance_repair`);
    assert(loaded.chapter4.timeState === "2245_maintenance" && loaded.chapter4.guardMode === "patrol", `maintenance save state ${index + 1} must restore 22:45 patrol`);
  });

  const staleOilLoaded = hydrate(makeMaintenanceState({ universalLubricatingOil: true }));
  assert(staleOilLoaded.items.universalLubricatingOil === false, "pre-diagnosis save must clear a forged oil item");
  const diagnosedLoaded = hydrate(diagnosedState);
  assert(diagnosedLoaded.items.shortPryBar && diagnosedLoaded.items.universalLubricatingOil, "diagnosed save must restore both prepared tools");
  const wheelWithoutOilLoaded = hydrate(makeMaintenanceState({ facts: ["cart_wheel_repaired"] }));
  assert(
    sameJson(
      wheelWithoutOilLoaded.chapter4.factIds.filter((factId) => maintenanceFactOrder.includes(factId)),
      ["cart_wheel_inspected", "cart_wheel_cover_opened", "cart_wheel_repaired"]
    ),
    "wheel-repaired save must restore inspection and open-cover closure"
  );
  assert(wheelWithoutOilLoaded.items.universalLubricatingOil === true, "wheel-repaired save must restore the retained half bottle");
  const gearOnlyLoaded = hydrate(makeMaintenanceState({
    facts: ["clock_gear_repaired"],
    shortPryBar: true,
    universalLubricatingOil: true
  }));
  assert(
    sameJson(
      gearOnlyLoaded.chapter4.factIds.filter((factId) => maintenanceFactOrder.includes(factId)),
      maintenanceFactOrder
    ),
    "gear-repaired save must restore the complete maintenance causal closure"
  );
  assert(!gearOnlyLoaded.items.shortPryBar && !gearOnlyLoaded.items.universalLubricatingOil, "gear-repaired save must force both consumed maintenance items absent");
  assert(gearOnlyLoaded.chapter4.phase === "maintenance_repair" && gearOnlyLoaded.chapter4.timeState === "2245_maintenance", "gear-repaired save must not migrate into blackout");
  const invalidMaintenanceLocationLoaded = hydrate(makeMaintenanceState({
    floor: "A2",
    roomId: "a2_forged_maintenance_room"
  }));
  assert(
    invalidMaintenanceLocationLoaded.chapter4.floor === "A1"
      && invalidMaintenanceLocationLoaded.chapter4.roomId === "a1_lobby"
      && invalidMaintenanceLocationLoaded.rpgCheckpoint === "c4_a1_lobby",
    "invalid maintenance location must recover to the A1 lobby checkpoint"
  );

  const recoverySource = makeMaintenanceState({
    facts: ["cart_wheel_inspected", "cart_wheel_cover_opened", "cart_wheel_repaired"],
    universalLubricatingOil: true,
    mode: "dark",
    roomId: "a1_cleaning_cart",
    chaseAttempt: 7,
    inventoryOpen: true,
    selectedItem: "universalLubricatingOil"
  });
  recoverySource.chapter4.lightGrid = { mask: 19, locked: false };
  const recoveryStore = createGameStore(recoverySource);
  const recoveryController = new ChapterFourTemporalMazeController(recoveryStore, new EventBus());
  const recoveryResult = recoveryController.resolve755Intent({ type: "recover_from_maintenance_patrol" });
  assert(recoveryResult.accepted && recoveryResult.changed, "ordinary patrol capture must commit its independent recovery intent");
  const expectedRecoveryState = {
    ...recoverySource,
    rpgCheckpoint: "c4_a1_lobby",
    chapter4: {
      ...recoverySource.chapter4,
      building: "A",
      floor: "A1",
      roomId: "a1_lobby"
    },
    ui: {
      ...recoverySource.ui,
      inventoryOpen: false,
      selectedItem: null
    }
  };
  assert(sameJson(recoveryStore.getState(), expectedRecoveryState), "ordinary patrol recovery may change only location/checkpoint and transient inventory UI");
  assert(recoveryStore.getState().chapter4.chaseAttempt === 7, "ordinary patrol recovery must not increment chaseAttempt");
  assertZeroWriteRejection(
    { ...recoverySource, chapter4: { ...recoverySource.chapter4, phase: "blackout_light_grid" } },
    { type: "recover_from_maintenance_patrol" },
    "locked",
    undefined,
    "ordinary patrol recovery outside maintenance"
  );
  assertZeroWriteRejection(
    { ...recoverySource, chapter4: { ...recoverySource.chapter4, guardMode: "absent" } },
    { type: "recover_from_maintenance_patrol" },
    "locked",
    undefined,
    "ordinary patrol recovery without patrol mode"
  );

  // Task 11: strict final-clock handshake, atomic minute theft, pure five-zone
  // light grid, persisted panel writes and locked final-chase handoff.
  assert(sameJson({
    initialMask: CHAPTER_FOUR_LIGHT_GRID.initialMask,
    targetMask: CHAPTER_FOUR_LIGHT_GRID.targetMask,
    allOnMask: CHAPTER_FOUR_LIGHT_GRID.allOnMask,
    zoneIds: CHAPTER_FOUR_LIGHT_GRID.zones.map((zone) => zone.id),
    toggleMasks: CHAPTER_FOUR_LIGHT_GRID.zones.map((zone) => zone.toggleMask)
  }, {
    initialMask: 14,
    targetMask: 13,
    allOnMask: 31,
    zoneIds: ["hall", "west_corridor", "east_corridor", "classroom_zone", "bakery_back_area"],
    toggleMasks: [7, 19, 13, 28, 26]
  }), "Task11 pure light-grid contract must expose the exact five zones and masks");
  assert(!evaluateChapterFourLightGrid(14).solved, "Task11 initial mask 14 must remain unsolved");
  assert(isChapterFourLightGridSolved(13), "Task11 target mask 13 must solve the necessary route");
  assert(!isChapterFourLightGridSolved(31), "Task11 all-on mask must fail because off-route zones must stay dark");
  const lightGridSolutions = enumerateChapterFourLightGridSolutions();
  assert(lightGridSolutions.length === 1, "Task11 32-vector enumeration must have one unique solution");
  assert(sameJson(lightGridSolutions[0], {
    clickVector: 23,
    zoneIds: ["hall", "west_corridor", "east_corridor", "bakery_back_area"],
    resultMask: 13
  }), "Task11 unique solution must be click vector 23");
  assert(
    applyChapterFourLightGridClickVector(14, 23) === 13,
    "Task11 click vector 23 must transform initial mask 14 to target mask 13"
  );
  assert(
    toggleChapterFourLightZone(toggleChapterFourLightZone(14, "hall"), "hall") === 14,
    "Task11 XOR toggles must be self-inverse"
  );
  const finalClockContract = getChapterFour755TargetContract("a1_hall_clock_minute_endpoint");
  const resolvedFinalClockContract = resolveChapterFour755RuntimeEntityTarget(
    finalClockRuntimeTarget.targetId,
    finalClockRuntimeTarget.entityId,
    finalClockRuntimeTarget.bounds
  );
  assert(
    finalClockContract?.activation === "runtime_entity"
      && finalClockContract.bounds === null
      && finalClockContract.contractPending
      && resolvedFinalClockContract?.contractPending === false
      && resolvedFinalClockContract.approximate === false,
    "Task13 minute target must remain closed until its exact visible clock-face runtime envelope resolves"
  );
  assert(sameJson(powerPanelRuntimeTarget.bounds, { x: 493, y: 528, width: 67, height: 124 }), "Task11 power panel must use the exact A1 installation bounds");

  const beginFinalClockIntent = {
    type: "begin_final_clock_drag",
    targetId: "a1_hall_clock_minute_endpoint",
    spatial: validSpatial
  };
  for (const [label, state, intent, runtimeTarget, reason] of [
    [
      "wrong phase",
      { ...gearRepairedState, chapter4: { ...gearRepairedState.chapter4, phase: "blackout_light_grid" } },
      beginFinalClockIntent,
      finalClockRuntimeTarget,
      "locked"
    ],
    [
      "wrong mode",
      { ...gearRepairedState, chapter4: { ...gearRepairedState.chapter4, mode: "dark" } },
      beginFinalClockIntent,
      finalClockRuntimeTarget,
      "wrong_mode"
    ],
    [
      "missing attendance paper",
      { ...gearRepairedState, items: { ...gearRepairedState.items, attendanceRecordPaper: false } },
      beginFinalClockIntent,
      finalClockRuntimeTarget,
      "locked"
    ],
    [
      "too far",
      gearRepairedState,
      { ...beginFinalClockIntent, spatial: { ...validSpatial, distance: "too_far" } },
      finalClockRuntimeTarget,
      "too_far"
    ],
    [
      "missing runtime bounds",
      gearRepairedState,
      beginFinalClockIntent,
      undefined,
      "locked"
    ],
    [
      "translated endpoint bounds",
      gearRepairedState,
      beginFinalClockIntent,
      { ...finalClockRuntimeTarget, bounds: { ...finalClockRuntimeTarget.bounds, x: finalClockRuntimeTarget.bounds.x + 1 } },
      "locked"
    ],
    [
      "wrong room",
      { ...gearRepairedState, chapter4: { ...gearRepairedState.chapter4, roomId: "a1_bakery" } },
      beginFinalClockIntent,
      finalClockRuntimeTarget,
      "locked"
    ]
  ]) {
    assertZeroWriteRejection(state, intent, reason, runtimeTarget, `Task11 final clock ${label}`);
  }

  const beforeBeginFinalClock = snapshot(maintenanceStore.getState());
  const commitEventsBeforeBegin = maintenanceEvents.getHistory()
    .filter((event) => event.name === "chapter4_755_intent_committed").length;
  const beginFinalClock = maintenanceController.resolve755Intent(
    beginFinalClockIntent,
    finalClockRuntimeTarget
  );
  assert(beginFinalClock.accepted && !beginFinalClock.changed, "Task11 final-clock begin must accept with changed=false");
  assert(snapshot(maintenanceStore.getState()) === beforeBeginFinalClock, "Task11 final-clock begin must not write GameState");
  assert(
    maintenanceEvents.getHistory().filter((event) => event.name === "chapter4_755_intent_committed").length
      === commitEventsBeforeBegin,
    "Task11 read-only final-clock begin must not publish a commit event"
  );
  maintenanceStore.setState((current) => ({
    ...current,
    chapter4: { ...current.chapter4, mode: "dark" }
  }));
  const beforeDarkMinuteTheft = snapshot(maintenanceStore.getState());
  const darkMinuteTheft = maintenanceController.resolve755Intent({ type: "complete_minute_theft" });
  assert(
    !darkMinuteTheft.accepted && !darkMinuteTheft.changed && darkMinuteTheft.reason === "wrong_mode",
    "Task11 minute-theft completion must revalidate light mode after the read-only begin"
  );
  assert(
    snapshot(maintenanceStore.getState()) === beforeDarkMinuteTheft,
    "Task11 dark-mode minute-theft completion must remain zero-write"
  );
  maintenanceStore.setState((current) => ({
    ...current,
    chapter4: { ...current.chapter4, mode: "light" }
  }));
  const beforeUnarmedMinuteTheft = snapshot(maintenanceStore.getState());
  const unarmedMinuteTheft = maintenanceController.resolve755Intent({ type: "complete_minute_theft" });
  assert(
    !unarmedMinuteTheft.accepted && !unarmedMinuteTheft.changed && unarmedMinuteTheft.reason === "locked",
    "Task11 rejected dark-mode completion must disarm the runtime handshake"
  );
  assert(
    snapshot(maintenanceStore.getState()) === beforeUnarmedMinuteTheft,
    "Task11 unarmed minute-theft retry must remain zero-write"
  );
  const retryBeginFinalClock = maintenanceController.resolve755Intent(
    beginFinalClockIntent,
    finalClockRuntimeTarget
  );
  assert(
    retryBeginFinalClock.accepted && !retryBeginFinalClock.changed,
    "Task11 final-clock begin must be retryable after a rejected completion"
  );
  const completeMinuteTheft = maintenanceController.resolve755Intent({ type: "complete_minute_theft" });
  assert(completeMinuteTheft.accepted && completeMinuteTheft.changed, "Task11 minute-theft completion must commit once after begin");
  const blackoutState = maintenanceStore.getState();
  assert(sameJson({
    phase: blackoutState.chapter4.phase,
    timeState: blackoutState.chapter4.timeState,
    world: blackoutState.chapter4.worldTimeSeconds,
    phone: blackoutState.chapter4.phoneStatusTimeSeconds,
    trusted: blackoutState.chapter4.phoneStatusTimeTrusted,
    guard: blackoutState.chapter4.guardMode,
    paperHeld: blackoutState.items.attendanceRecordPaper,
    paperOut: blackoutState.chapter4.factIds.includes("paper_temporarily_out_of_inventory"),
    mask: blackoutState.chapter4.lightGrid.mask,
    locked: blackoutState.chapter4.lightGrid.locked,
    floor: blackoutState.chapter4.floor,
    roomId: blackoutState.chapter4.roomId,
    checkpoint: blackoutState.rpgCheckpoint
  }, {
    phase: "blackout_light_grid",
    timeState: "0754_blackout",
    world: 28440,
    phone: 28440,
    trusted: true,
    guard: "absent",
    paperHeld: false,
    paperOut: true,
    mask: 14,
    locked: false,
    floor: "A1",
    roomId: "a1_lobby",
    checkpoint: "c4_a1_lobby"
  }), "Task11 minute theft must write the complete blackout transaction atomically");
  assert(
    maintenanceEvents.getHistory().some((event) => event.name === "blackout_committed"
      && event.payload?.mask === 14
      && event.payload?.timeState === "0754_blackout"),
    "Task11 successful minute theft must emit blackout_committed data"
  );
  const afterMinuteTheft = snapshot(blackoutState);
  const repeatedMinuteTheft = maintenanceController.resolve755Intent({ type: "complete_minute_theft" });
  assert(!repeatedMinuteTheft.accepted && !repeatedMinuteTheft.changed, "Task11 repeated minute-theft completion must reject");
  assert(snapshot(maintenanceStore.getState()) === afterMinuteTheft, "Task11 repeated minute-theft completion must be zero-write");
  assert(
    selectQuestViewModel(blackoutState).objective === "让必要路线亮起",
    "Task11 blackout must reveal only the necessary-route objective"
  );
  const blackoutMazeProjection = selectChapterFourMazeProjection(blackoutState);
  const blackoutProjection = blackoutMazeProjection.availableTargetIds;
  assert(blackoutProjection.includes("a1_power_panel"), "Task11 blackout must project the A1 power panel");
  assert(
    !blackoutMazeProjection.dynamicCollisionIds.includes("a1_blackout_service_barrier"),
    "Task11 blackout must not project a service barrier without an authoritative runtime entity"
  );
  assert(
    ["a1_hall_clock_minute_endpoint", "a2_202_threshold", "a2_202_projection", "a1_campus_card_reader", "a1_attendance_paper_slot"]
      .every((targetId) => !blackoutProjection.includes(targetId)),
    "Task11 blackout projection must keep the clock endpoint and Task12+ targets closed"
  );

  const beforeOpenPanel = snapshot(maintenanceStore.getState());
  const openPanelIntent = {
    type: "open_power_panel",
    targetId: "a1_power_panel",
    spatial: validSpatial
  };
  for (const [label, state, intent, runtimeTarget, reason] of [
    ["wrong phase", gearRepairedState, openPanelIntent, powerPanelRuntimeTarget, "locked"],
    [
      "wrong mode",
      { ...blackoutState, chapter4: { ...blackoutState.chapter4, mode: "dark" } },
      openPanelIntent,
      powerPanelRuntimeTarget,
      "wrong_mode"
    ],
    [
      "missing theft fact",
      { ...blackoutState, chapter4: { ...blackoutState.chapter4, factIds: blackoutState.chapter4.factIds.filter((factId) => factId !== "paper_temporarily_out_of_inventory") } },
      openPanelIntent,
      powerPanelRuntimeTarget,
      "locked"
    ],
    [
      "too far",
      blackoutState,
      { ...openPanelIntent, spatial: { ...validSpatial, distance: "too_far" } },
      powerPanelRuntimeTarget,
      "too_far"
    ],
    [
      "translated bounds",
      blackoutState,
      openPanelIntent,
      { ...powerPanelRuntimeTarget, bounds: { ...powerPanelRuntimeTarget.bounds, y: powerPanelRuntimeTarget.bounds.y + 1 } },
      "locked"
    ]
  ]) {
    assertZeroWriteRejection(state, intent, reason, runtimeTarget, `Task11 power panel ${label}`);
  }
  const openPanelResult = maintenanceController.resolve755Intent(openPanelIntent, powerPanelRuntimeTarget);
  assert(openPanelResult.accepted && !openPanelResult.changed, "Task11 power-panel open must be an accepted read-only handshake");
  assert(snapshot(maintenanceStore.getState()) === beforeOpenPanel, "Task11 power-panel open must not write GameState");

  const allOnStore = createGameStore({
    ...blackoutState,
    chapter4: { ...blackoutState.chapter4, lightGrid: { mask: 31, locked: false } }
  });
  const allOnController = new ChapterFourTemporalMazeController(allOnStore, new EventBus());
  const allOnBefore = snapshot(allOnStore.getState());
  const allOnLock = allOnController.resolve755Intent({
    type: "lock_light_grid",
    targetId: "a1_power_panel",
    spatial: validSpatial
  }, powerPanelRuntimeTarget);
  assert(!allOnLock.accepted && !allOnLock.changed && allOnLock.reason === "incorrect", "Task11 all-on mask must reject lock");
  assert(snapshot(allOnStore.getState()) === allOnBefore, "Task11 failed all-on lock must be zero-write");

  const expectedToggleSequence = [
    ["hall", 9],
    ["west_corridor", 26],
    ["east_corridor", 23],
    ["bakery_back_area", 13]
  ];
  for (const [zoneId, expectedMask] of expectedToggleSequence) {
    const result = maintenanceController.resolve755Intent({
      type: "toggle_light_zone",
      zoneId,
      targetId: "a1_power_panel",
      spatial: validSpatial
    }, powerPanelRuntimeTarget);
    assert(result.accepted && result.changed, `Task11 ${zoneId} toggle must persist`);
    assert(maintenanceStore.getState().chapter4.lightGrid.mask === expectedMask, `Task11 ${zoneId} toggle must produce mask ${expectedMask}`);
  }
  const powerToggleEvents = maintenanceEvents.getHistory().filter((event) => event.name === "power_zone_toggled");
  assert(sameJson(powerToggleEvents.map((event) => ({
    zoneId: event.payload?.zoneId,
    previousMask: event.payload?.previousMask,
    mask: event.payload?.mask
  })), [
    { zoneId: "hall", previousMask: 14, mask: 9 },
    { zoneId: "west_corridor", previousMask: 9, mask: 26 },
    { zoneId: "east_corridor", previousMask: 26, mask: 23 },
    { zoneId: "bakery_back_area", previousMask: 23, mask: 13 }
  ]), "Task11 power-zone cues must report previous and committed masks");
  const lockGridResult = maintenanceController.resolve755Intent({
    type: "lock_light_grid",
    targetId: "a1_power_panel",
    spatial: validSpatial
  }, powerPanelRuntimeTarget);
  assert(lockGridResult.accepted && lockGridResult.changed, "Task11 solved mask must auto-lock through the canonical controller");
  const finalChaseState = maintenanceStore.getState();
  assert(sameJson({
    phase: finalChaseState.chapter4.phase,
    mask: finalChaseState.chapter4.lightGrid.mask,
    locked: finalChaseState.chapter4.lightGrid.locked,
    fact: finalChaseState.chapter4.factIds.includes("light_grid_locked"),
    guard: finalChaseState.chapter4.guardMode,
    world: finalChaseState.chapter4.worldTimeSeconds,
    phone: finalChaseState.chapter4.phoneStatusTimeSeconds,
    floor: finalChaseState.chapter4.floor,
    roomId: finalChaseState.chapter4.roomId,
    checkpoint: finalChaseState.rpgCheckpoint
  }, {
    phase: "final_chase",
    mask: 13,
    locked: true,
    fact: true,
    guard: "chase",
    world: 28440,
    phone: 28440,
    floor: "A1",
    roomId: "a1_lobby",
    checkpoint: "c4_a1_lobby"
  }), "Task11 solved grid must atomically enter the 07:54 final chase at A1 lobby");
  assert(selectQuestViewModel(finalChaseState).objective === "前往 202", "Task11 final chase must reveal only the 202 objective");
  const finalChaseProjection = selectChapterFourMazeProjection(finalChaseState);
  assert(
    finalChaseProjection.dynamicCollisionIds.includes("a1_guard_chase_body")
      && !finalChaseProjection.dynamicCollisionIds.includes("a1_blackout_service_barrier"),
    "Task11 final chase must project only the runtime-managed guard body on A1"
  );
  assert(
    maintenanceEvents.getHistory().some((event) => event.name === "power_grid_locked"
      && event.payload?.mask === 13
      && event.payload?.phase === "final_chase"),
    "Task11 successful lock must emit power_grid_locked data"
  );
  for (const [label, intent] of [
    ["toggle after lock", { type: "toggle_light_zone", zoneId: "hall", targetId: "a1_power_panel", spatial: validSpatial }],
    ["lock after lock", { type: "lock_light_grid", targetId: "a1_power_panel", spatial: validSpatial }]
  ]) {
    const before = snapshot(maintenanceStore.getState());
    const result = maintenanceController.resolve755Intent(intent, powerPanelRuntimeTarget);
    assert(!result.accepted && !result.changed, `Task11 ${label} must reject`);
    assert(snapshot(maintenanceStore.getState()) === before, `Task11 ${label} must be zero-write`);
  }

  const resolvedIds = new Set();
  let sessionWrites = 0;
  const firstSessionResolution = resolveChapterFour755SessionRequest(resolvedIds, "task11-panel-1", () => {
    sessionWrites += 1;
    return "accepted";
  });
  const duplicateSessionResolution = resolveChapterFour755SessionRequest(resolvedIds, "task11-panel-1", () => {
    sessionWrites += 1;
    return "duplicate-write";
  });
  assert(firstSessionResolution.status === "resolved" && duplicateSessionResolution.status === "duplicate", "Task11 panel request IDs must dedupe within one host session");
  assert(sessionWrites === 1, "Task11 duplicate panel request must not rerun the controller callback");

  const malformedBlackoutLoaded = hydrate({
    ...gearRepairedState,
    items: { ...gearRepairedState.items, attendanceRecordPaper: true },
    chapter4: {
      ...gearRepairedState.chapter4,
      phase: "blackout_light_grid",
      factIds: openingFacts,
      lightGrid: { mask: 19, locked: true }
    }
  });
  assert(
    maintenanceFactOrder.every((factId) => malformedBlackoutLoaded.chapter4.factIds.includes(factId))
      && malformedBlackoutLoaded.chapter4.factIds.includes("paper_temporarily_out_of_inventory"),
    "Task11 blackout save must restore maintenance and minute-theft fact closure"
  );
  assert(!malformedBlackoutLoaded.items.attendanceRecordPaper, "Task11 blackout save must remove the attendance paper");
  assert(sameJson(malformedBlackoutLoaded.chapter4.lightGrid, { mask: 19, locked: false }), "Task11 blackout save must retain a legal mask but keep it unlocked");
  for (const mask of [0, 14, 13, 31]) {
    const loaded = hydrate({
      ...blackoutState,
      chapter4: { ...blackoutState.chapter4, lightGrid: { mask, locked: false } }
    });
    assert(loaded.chapter4.lightGrid.mask === mask && !loaded.chapter4.lightGrid.locked, `Task11 blackout save must preserve legal mask ${mask}`);
  }
  const invalidMaskLoaded = hydrate({
    ...blackoutState,
    chapter4: { ...blackoutState.chapter4, lightGrid: { mask: 32, locked: false } }
  });
  assert(invalidMaskLoaded.chapter4.lightGrid.mask === 14, "Task11 invalid blackout mask must recover to initial mask 14");
  const v28PowerGridLoaded = loadRawSave(JSON.stringify({
    version: 28,
    state: {
      ...blackoutState,
      chapter4: {
        ...blackoutState.chapter4,
        lightGrid: { mask: 6, locked: false }
      }
    },
    savedAt: 1_755_029
  })).loaded;
  assert(
    sameJson(v28PowerGridLoaded.chapter4.lightGrid, { mask: 14, locked: false }),
    "v28 blackout save at the retired initial arrangement must migrate to initial mask 14"
  );
  const malformedFinalChaseLoaded = hydrate({
    ...blackoutState,
    items: { ...blackoutState.items, attendanceRecordPaper: true },
    chapter4: {
      ...blackoutState.chapter4,
      phase: "final_chase",
      factIds: openingFacts,
      lightGrid: { mask: 0, locked: false },
      guardMode: "absent"
    }
  });
  assert(sameJson(malformedFinalChaseLoaded.chapter4.lightGrid, { mask: 13, locked: true }), "Task11 final-chase save must force target mask 13 locked");
  assert(
    malformedFinalChaseLoaded.chapter4.factIds.includes("paper_temporarily_out_of_inventory")
      && malformedFinalChaseLoaded.chapter4.factIds.includes("light_grid_locked")
      && !malformedFinalChaseLoaded.items.attendanceRecordPaper
      && malformedFinalChaseLoaded.chapter4.guardMode === "chase",
    "Task11 final-chase save must restore theft, lock, absent paper and chase authority"
  );
  for (const phase of ["final_chase", "final_minute_recovery", "return_to_clock"]) {
    const floor = phase === "final_chase" ? "A1" : "A2";
    const loaded = hydrate({
      ...blackoutState,
      chapter4: {
        ...blackoutState.chapter4,
        phase,
        floor,
        roomId: phase === "final_minute_recovery" ? "a2_lecture_202" : blackoutState.chapter4.roomId
      }
    });
    assert(
      loaded.chapter4.timeState === "0754_blackout"
        && loaded.chapter4.worldTimeSeconds === 28440
        && loaded.chapter4.phoneStatusTimeSeconds === 28440
        && loaded.chapter4.phoneStatusTimeTrusted,
      `Task11 ${phase} save must preserve the 07:54 time contract`
    );
    if (phase === "final_minute_recovery") {
      assert(loaded.chapter4.roomId === "a2_room_202", "Task11 must migrate a2_lecture_202 to a2_room_202");
    }
  }

  // Task 12: pure six-state final chase, attempt-checked controller writes,
  // main-stair-only travel, 202 recovery and Task13 closure boundary.
  assert(sameJson(CHAPTER_FOUR_FINAL_CHASE_RULES, {
    stableFramesToArm: 4,
    playerSpeed: 208,
    guardSpeed: 196,
    catchUpSpeed: 224,
    closeSpeed: 178,
    catchDistance: 22,
    predictionMs: 320,
    targetHoldMs: 260,
    waypointReachDistance: 34,
    catchUpDistance: 420,
    closeDistance: 120,
    startContactGraceMs: 700,
    portalContactGraceMs: 420,
    contactConfirmMs: 180,
    maxStepMs: 50,
    finishBeforeContact: true,
    transportId: "main_stair",
    restartCheckpoint: "c4_a1_lobby"
  }), "Task12 pure chase rules must match the approved timing, speeds, contact, transport and restart contract");
  assert(sameJson(CHAPTER_FOUR_FINAL_CHASE_POINTS, {
    playerStart: { x: 590, y: 612 },
    guardSpawn: { x: 590, y: 724 },
    a1LowerHall: { x: 836, y: 540 },
    a1Central: { x: 836, y: 228 },
    a1Stair: { x: 1001, y: 214 },
    a2Arrival: { x: 966, y: 214 },
    a2CoreEast: { x: 1100, y: 232 },
    a2EastSouth: { x: 1100, y: 400 },
    room202Outer: { x: 1353, y: 400 },
    finishThreshold: { x: 1353, y: 356.5 },
    finalMinuteSpawn: { x: 1353, y: 320 },
    bakeryDeadEnd: { x: 318, y: 648 },
    room203DeadEnd: { x: 1353, y: 524 }
  }), "Task12 pure chase points must preserve the authored route, finish, collectible and two decoys");
  assert(CHAPTER_FOUR_FINAL_CHASE_WAYPOINTS.length === 12, "Task12 pure chase graph must contain 12 authored waypoints");
  assert(
    CHAPTER_FOUR_FINAL_CHASE_WAYPOINTS.filter((waypoint) => waypoint.role === "decoy")
      .map((waypoint) => waypoint.id).join(",") === "a1_bakery_dead_end,a2_room203_dead_end",
    "Task12 bakery and Room203 must remain non-progressing decoy branches"
  );
  const chaseInput = {
    deltaMs: 16,
    committedAndApplied: true,
    floor: "A1",
    playerPosition: CHAPTER_FOUR_FINAL_CHASE_POINTS.playerStart,
    guardPosition: CHAPTER_FOUR_FINAL_CHASE_POINTS.guardSpawn,
    playerInsideFinish: false,
    playerEnteredMainStair: false,
    guardContact: false
  };
  let chaseRuntimeState = createChapterFourFinalChaseState(7);
  assert(chaseRuntimeState.phase === "arming" && chaseRuntimeState.stableCommittedFrames === 0, "Task12 chase must begin unarmed");
  for (let frame = 1; frame <= 3; frame += 1) {
    const step = stepChapterFourFinalChase(chaseRuntimeState, chaseInput);
    chaseRuntimeState = step.state;
    assert(chaseRuntimeState.phase === "arming", `Task12 committed frame ${frame} must remain arming`);
    assert(chaseRuntimeState.stableCommittedFrames === frame, `Task12 committed frame ${frame} count mismatch`);
    assert(!step.guardVisible, `Task12 guard must remain hidden before committed frame 4 (frame ${frame})`);
  }
  const unstableArming = stepChapterFourFinalChase(chaseRuntimeState, {
    ...chaseInput,
    committedAndApplied: false
  });
  assert(
    unstableArming.state.phase === "arming" && unstableArming.state.stableCommittedFrames === 0,
    "Task12 one uncommitted frame must reset the consecutive arming count"
  );
  chaseRuntimeState = createChapterFourFinalChaseState(7);
  for (let frame = 1; frame <= 4; frame += 1) {
    chaseRuntimeState = stepChapterFourFinalChase(chaseRuntimeState, chaseInput).state;
  }
  assert(chaseRuntimeState.phase === "running", "Task12 exactly four consecutive committed/applied frames must arm the chase");
  assert(sameJson(chapterFourFinalChaseDeltaSlices(225), [50, 50, 50, 50, 25]), "Task12 225ms delta must split into 50ms maximum slices");
  assert(chapterFourFinalChaseDeltaSlices(0).length === 0, "Task12 zero delta must produce no chase slices");
  assert(
    chapterFourFinalChaseFootContact({ x: 10, y: 10 }, { x: 32, y: 10, width: 1, height: 1 }),
    "Task12 final guard contact must include the authored 22px catch boundary"
  );
  assert(
    !chapterFourFinalChaseFootContact({ x: 10, y: 10 }, { x: 32.001, y: 10, width: 1, height: 1 }),
    "Task12 final guard contact must reject points beyond the authored catch boundary"
  );
  const simultaneousFinish = stepChapterFourFinalChase({
    ...chaseRuntimeState,
    floor: "A2",
    guardFloor: "A2"
  }, {
    ...chaseInput,
    floor: "A2",
    playerPosition: CHAPTER_FOUR_FINAL_CHASE_POINTS.finishThreshold,
    guardPosition: CHAPTER_FOUR_FINAL_CHASE_POINTS.finishThreshold,
    playerInsideFinish: true,
    guardContact: true
  });
  assert(
    simultaneousFinish.state.phase === "finish_pending"
      && simultaneousFinish.finishRequested
      && !simultaneousFinish.failureRequested,
    "Task12 finish must win before contact on the same frame"
  );
  const completedFinish = resolveChapterFourFinalChaseFinish(simultaneousFinish.state, true);
  assert(completedFinish.phase === "complete", "Task12 accepted finish must resolve once to complete");
  assert(
    sameJson(resolveChapterFourFinalChaseFinish(completedFinish, true), completedFinish),
    "Task12 repeated finish resolution must be a no-op"
  );
  const grazingContact = stepChapterFourFinalChase({
    ...chaseRuntimeState,
    contactGraceRemainingMs: 0
  }, {
    ...chaseInput,
    deltaMs: 50,
    guardContact: true
  });
  assert(
    grazingContact.state.phase === "running"
      && grazingContact.state.contactHoldMs === 50
      && !grazingContact.failureRequested,
    "Task12 one-frame corner contact must not fail the chase"
  );
  const failureStep = stepChapterFourFinalChase({
    ...grazingContact.state,
    contactHoldMs: 160,
    contactGraceRemainingMs: 0
  }, {
    ...chaseInput,
    deltaMs: 20,
    guardContact: true
  });
  assert(
    failureStep.state.phase === "failure_pending"
      && failureStep.failureRequested
      && !failureStep.finishRequested,
    "Task12 non-finish contact must enter failure_pending"
  );
  assert(resolveChapterFourFinalChaseFailure(failureStep.state, true).phase === "complete", "Task12 accepted failure request must end only the runtime attempt");
  const portalStep = stepChapterFourFinalChase(chaseRuntimeState, {
    ...chaseInput,
    playerPosition: CHAPTER_FOUR_FINAL_CHASE_POINTS.a1Stair,
    playerEnteredMainStair: true
  });
  assert(
    portalStep.state.phase === "portal_transfer"
      && portalStep.portalRequested
      && portalStep.state.portalRemainingDistance > 0,
    "Task12 real A1 main-stair entry must request one portal transfer while retaining guard distance"
  );
  const acceptedPortal = resolveChapterFourFinalChasePortal(portalStep.state, true);
  assert(acceptedPortal.portalApplied && acceptedPortal.floor === "A2", "Task12 accepted portal must mark only the runtime transfer applied");
  const simultaneousPortalContact = stepChapterFourFinalChase({
    ...chaseRuntimeState,
    contactGraceRemainingMs: 0,
    contactHoldMs: 170
  }, {
    ...chaseInput,
    deltaMs: 20,
    playerPosition: CHAPTER_FOUR_FINAL_CHASE_POINTS.a1Stair,
    playerEnteredMainStair: true,
    guardContact: true
  });
  assert(
    simultaneousPortalContact.state.phase === "portal_transfer"
      && simultaneousPortalContact.portalRequested
      && !simultaneousPortalContact.failureRequested,
    "Task12 authored main-stair entry must win over contact on the same frame"
  );
  const farPursuit = stepChapterFourFinalChase({
    ...chaseRuntimeState,
    guardTargetHoldMs: 0,
    lastPlayerPosition: { x: 1100, y: 232 }
  }, {
    ...chaseInput,
    floor: "A2",
    guardPosition: CHAPTER_FOUR_FINAL_CHASE_POINTS.a2Arrival,
    playerPosition: CHAPTER_FOUR_FINAL_CHASE_POINTS.room203DeadEnd
  });
  assert(
    farPursuit.state.pursuitBand === "catch_up"
      && farPursuit.state.pursuitSpeed === CHAPTER_FOUR_FINAL_CHASE_RULES.catchUpSpeed,
    "Task12 a distant guard must enter bounded catch-up pressure"
  );
  const closePursuit = stepChapterFourFinalChase({
    ...chaseRuntimeState,
    floor: "A2",
    guardFloor: "A2",
    guardTargetWaypointId: "a2_room202_outer",
    guardTargetHoldMs: 0,
    lastPlayerPosition: { x: 1353, y: 400 }
  }, {
    ...chaseInput,
    floor: "A2",
    guardPosition: { x: 1340, y: 400 },
    playerPosition: { x: 1353, y: 400 }
  });
  assert(
    closePursuit.state.pursuitBand === "close"
      && closePursuit.state.pursuitSpeed === CHAPTER_FOUR_FINAL_CHASE_RULES.closeSpeed,
    "Task12 a close guard must slow below player speed to preserve a recovery window"
  );
  const heldTarget = stepChapterFourFinalChase({
    ...chaseRuntimeState,
    floor: "A2",
    guardFloor: "A2",
    guardTargetWaypointId: "a2_room202_outer",
    guardTargetHoldMs: 200,
    lastPlayerPosition: { x: 1100, y: 410 }
  }, {
    ...chaseInput,
    floor: "A2",
    guardPosition: { x: 1100, y: 400 },
    playerPosition: { x: 1100, y: 415 }
  });
  assert(
    heldTarget.state.guardTargetWaypointId === "a2_room202_outer",
    "Task12 target hysteresis must prevent one-frame branch oscillation"
  );
  assert(isChapterFourFinalChaseAttemptCurrent(chaseRuntimeState, 7), "Task12 runtime attempt token must accept its current attempt");
  assert(!isChapterFourFinalChaseAttemptCurrent(chaseRuntimeState, 6), "Task12 runtime attempt token must reject stale attempts");

  const directElevatorState = {
    ...finalChaseState,
    items: { ...finalChaseState.items, campusCard: true },
    chapter4: { ...finalChaseState.chapter4, chaseAttempt: 7 }
  };
  assertZeroWriteRejection(
    directElevatorState,
    { type: "move_to_location", floor: "A2", roomId: "a2_corridor", checkpoint: "c4_a2_corridor" },
    "locked",
    undefined,
    "Task12 final chase elevator/direct-floor travel"
  );
  assertZeroWriteRejection(
    directElevatorState,
    { type: "traverse_main_stair", fromFloor: "A1", toFloor: "A2", expectedAttempt: 6 },
    "locked",
    undefined,
    "Task12 stale stair transfer"
  );
  const chaseStore = createGameStore(directElevatorState);
  const chaseEvents = new EventBus();
  const chaseController = new ChapterFourTemporalMazeController(chaseStore, chaseEvents);
  const stairTransfer = chaseController.resolve755Intent({
    type: "traverse_main_stair",
    fromFloor: "A1",
    toFloor: "A2",
    expectedAttempt: 7
  });
  assert(stairTransfer.accepted && stairTransfer.changed, "Task12 current attempt must traverse A1->A2 through main_stair");
  assert(sameJson({
    floor: chaseStore.getState().chapter4.floor,
    roomId: chaseStore.getState().chapter4.roomId,
    checkpoint: chaseStore.getState().rpgCheckpoint
  }, { floor: "A2", roomId: "a2_corridor", checkpoint: "c4_a2_corridor" }), "Task12 stair transfer must arrive at the A2 corridor safe point");
  const thresholdContract = getChapterFour755TargetContract("a2_202_threshold");
  assert(
    thresholdContract && !Object.prototype.hasOwnProperty.call(thresholdContract, "requiredFacing"),
    "Task12 automatic 202 threshold must not expose a hidden facing direction"
  );
  assert(
    selectChapterFourMazeProjection(chaseStore.getState()).availableTargetIds.includes("a2_202_threshold"),
    "Task12 A2 chase projection must expose the automatic 202 threshold contract"
  );

  assertZeroWriteRejection(
    chaseStore.getState(),
    {
      type: "reach_202_threshold",
      targetId: "a2_202_threshold",
      expectedAttempt: 6,
      spatial: validSpatial
    },
    "locked",
    undefined,
    "Task12 stale finish callback"
  );
  const reach202 = chaseController.resolve755Intent({
    type: "reach_202_threshold",
    targetId: "a2_202_threshold",
    expectedAttempt: 7,
    spatial: validSpatial
  });
  assert(reach202.accepted && reach202.changed, "Task12 current attempt 202 threshold must finish the chase once");
  const recoveryState = chaseStore.getState();
  assert(sameJson({
    phase: recoveryState.chapter4.phase,
    floor: recoveryState.chapter4.floor,
    roomId: recoveryState.chapter4.roomId,
    checkpoint: recoveryState.rpgCheckpoint,
    guardMode: recoveryState.chapter4.guardMode,
    attempt: recoveryState.chapter4.chaseAttempt,
    time: [recoveryState.chapter4.timeState, recoveryState.chapter4.worldTimeSeconds, recoveryState.chapter4.phoneStatusTimeSeconds]
  }, {
    phase: "final_minute_recovery",
    floor: "A2",
    roomId: "a2_room_202",
    checkpoint: "c4_a2_room202",
    guardMode: "absent",
    attempt: 7,
    time: ["0754_blackout", 28440, 28440]
  }), "Task12 finish must atomically enter guard-free A2-202 recovery without advancing time");
  const recoveryProjection = selectChapterFourMazeProjection(recoveryState);
  assert(recoveryProjection.doorStates.a2_room202_door === "closed", "Task12 recovery must close the Room202 door");
  assert(recoveryProjection.dynamicCollisionIds.includes("a2_room202_recovery_barrier"), "Task12 recovery must enable the exact Room202 barrier collider");
  assert(!recoveryProjection.npcIds.includes("a2_security_guard"), "Task12 recovery must remove the final-chase guard");
  assert(recoveryProjection.availableTargetIds.includes("a2_202_projection"), "Task12 recovery must expose only the visible final-minute runtime target");
  assert(
    ["a1_hall_clock_minute_endpoint", "a1_campus_card_reader", "a1_attendance_paper_slot"]
      .every((targetId) => !recoveryProjection.availableTargetIds.includes(targetId)),
    "Task12 recovery projection must keep Task13 install/check-in targets closed"
  );

  const finalMinuteRuntimeTarget = runtimeTargetFromLayout("a2_202_projection");
  const resolvedFinalMinuteTarget = resolveChapterFour755RuntimeEntityTarget(
    finalMinuteRuntimeTarget.targetId,
    finalMinuteRuntimeTarget.entityId,
    finalMinuteRuntimeTarget.bounds
  );
  assert(
    resolvedFinalMinuteTarget?.activation === "phase_exclusive"
      && resolvedFinalMinuteTarget?.contractPending === false
      && sameJson(resolvedFinalMinuteTarget.bounds, finalMinuteRuntimeTarget.bounds),
    "Task12 exact sprite-derived final-minute envelope must resolve"
  );
  assert(
    resolveChapterFour755RuntimeEntityTarget(
      finalMinuteRuntimeTarget.targetId,
      finalMinuteRuntimeTarget.entityId,
      { ...finalMinuteRuntimeTarget.bounds, x: finalMinuteRuntimeTarget.bounds.x + 1 }
    ) === null,
    "Task12 translated final-minute runtime bounds must fail anti-forgery resolution"
  );
  const collectFinalMinuteIntent = {
    type: "collect_final_minute",
    targetId: "a2_202_projection",
    spatial: validSpatial
  };
  for (const [label, state, intent, runtimeTarget, reason] of [
    [
      "wrong mode",
      { ...recoveryState, chapter4: { ...recoveryState.chapter4, mode: "dark" } },
      collectFinalMinuteIntent,
      finalMinuteRuntimeTarget,
      "wrong_mode"
    ],
    [
      "too far",
      recoveryState,
      { ...collectFinalMinuteIntent, spatial: { ...validSpatial, distance: "too_far" } },
      finalMinuteRuntimeTarget,
      "too_far"
    ],
    [
      "missing runtime target",
      recoveryState,
      collectFinalMinuteIntent,
      undefined,
      "locked"
    ],
    [
      "translated runtime target",
      recoveryState,
      collectFinalMinuteIntent,
      { ...finalMinuteRuntimeTarget, bounds: { ...finalMinuteRuntimeTarget.bounds, y: finalMinuteRuntimeTarget.bounds.y + 1 } },
      "locked"
    ]
  ]) {
    assertZeroWriteRejection(state, intent, reason, runtimeTarget, `Task12 final minute ${label}`);
  }
  const collectFinalMinute = chaseController.resolve755Intent(
    collectFinalMinuteIntent,
    finalMinuteRuntimeTarget
  );
  assert(collectFinalMinute.accepted && collectFinalMinute.changed, "Task12 exact final-minute target must grant once");
  const returnA2State = chaseStore.getState();
  assert(sameJson({
    phase: returnA2State.chapter4.phase,
    floor: returnA2State.chapter4.floor,
    roomId: returnA2State.chapter4.roomId,
    checkpoint: returnA2State.rpgCheckpoint,
    recovered: returnA2State.chapter4.factIds.includes("final_minute_recovered"),
    finalMinute: returnA2State.items.finalMinute,
    paper: returnA2State.items.attendanceRecordPaper,
    guardMode: returnA2State.chapter4.guardMode
  }, {
    phase: "return_to_clock",
    floor: "A2",
    roomId: "a2_room_202",
    checkpoint: "c4_a2_room202",
    recovered: true,
    finalMinute: true,
    paper: true,
    guardMode: "absent"
  }), "Task12 final-minute pickup must atomically restore the minute, paper and return state inside A2-202");
  const afterFinalMinuteSnapshot = snapshot(returnA2State);
  const duplicateFinalMinute = chaseController.resolve755Intent(
    collectFinalMinuteIntent,
    finalMinuteRuntimeTarget
  );
  assert(!duplicateFinalMinute.accepted && !duplicateFinalMinute.changed, "Task12 repeated final-minute pickup must reject");
  assert(snapshot(chaseStore.getState()) === afterFinalMinuteSnapshot, "Task12 repeated final-minute pickup must be zero-write");
  const returnA2Projection = selectChapterFourMazeProjection(returnA2State);
  assert(returnA2Projection.doorStates.a2_room202_door === "open", "Task12 return phase must reopen Room202");
  assert(!returnA2Projection.dynamicCollisionIds.includes("a2_room202_recovery_barrier"), "Task12 return phase must remove the Room202 barrier");
  assert(returnA2Projection.guardMode === "absent", "Task12 return phase must remain guard-free");
  assert(selectQuestViewModel(returnA2State).steps.length === 1, "Task12 A2 return quest must reveal exactly one step");
  assert(selectQuestViewModel(returnA2State).steps[0]?.id === "chapter_four_return_via_main_stair", "Task12 A2 return quest must direct the player to main_stair");
  assertZeroWriteRejection(
    returnA2State,
    { type: "move_to_location", floor: "A1", roomId: "a1_lobby", checkpoint: "c4_a1_lobby" },
    "locked",
    undefined,
    "Task12 return direct floor travel"
  );
  const returnStair = chaseController.resolve755Intent({
    type: "traverse_main_stair",
    fromFloor: "A2",
    toFloor: "A1",
    expectedAttempt: 7
  });
  assert(returnStair.accepted && returnStair.changed, "Task12 return must traverse A2->A1 through main_stair");
  const returnA1State = chaseStore.getState();
  assert(sameJson({
    floor: returnA1State.chapter4.floor,
    roomId: returnA1State.chapter4.roomId,
    checkpoint: returnA1State.rpgCheckpoint,
    guardMode: returnA1State.chapter4.guardMode
  }, { floor: "A1", roomId: "a1_lobby", checkpoint: "c4_a1_lobby", guardMode: "absent" }), "Task12 main-stair return must arrive in the guard-free A1 lobby");
  assert(selectQuestViewModel(returnA1State).steps.length === 1, "Task12 A1 return quest must reveal exactly one step");
  assert(selectQuestViewModel(returnA1State).steps[0]?.id === "chapter_four_install_final_minute", "Task13 A1 return quest must direct the player to install the final minute");
  const returnA1Projection = selectChapterFourMazeProjection(returnA1State);
  assert(
    returnA1Projection.availableTargetIds.includes("a1_hall_clock_minute_endpoint")
      && ["a1_campus_card_reader", "a1_attendance_paper_slot"]
        .every((targetId) => !returnA1Projection.availableTargetIds.includes(targetId)),
    "Task13 A1 return projection must expose only the final-minute endpoint from the Task13 targets"
  );
  const installFinalMinuteIntent = {
    type: "install_final_minute",
    itemId: "finalMinute",
    targetId: "a1_hall_clock_minute_endpoint",
    spatial: validSpatial
  };
  for (const [label, state, intent, runtimeTarget, reason] of [
    ["wrong mode", { ...returnA1State, chapter4: { ...returnA1State.chapter4, mode: "dark" } }, installFinalMinuteIntent, finalClockRuntimeTarget, "wrong_mode"],
    ["wrong item", returnA1State, { ...installFinalMinuteIntent, itemId: "campusCard" }, finalClockRuntimeTarget, "wrong_item"],
    ["too far", returnA1State, { ...installFinalMinuteIntent, spatial: { ...validSpatial, distance: "too_far" } }, finalClockRuntimeTarget, "too_far"],
    ["missing runtime target", returnA1State, installFinalMinuteIntent, undefined, "locked"],
    ["wrong entity", returnA1State, installFinalMinuteIntent, { ...finalClockRuntimeTarget, entityId: "forged-minute-endpoint" }, "locked"],
    ["translated bounds", returnA1State, installFinalMinuteIntent, { ...finalClockRuntimeTarget, bounds: { ...finalClockRuntimeTarget.bounds, x: finalClockRuntimeTarget.bounds.x + 1 } }, "locked"]
  ]) {
    assertZeroWriteRejection(state, intent, reason, runtimeTarget, `Task13 final-minute install ${label}`);
  }
  const installFinalMinute = chaseController.resolve755Intent(
    installFinalMinuteIntent,
    finalClockRuntimeTarget
  );
  assert(installFinalMinute.accepted && installFinalMinute.changed, "Task13 exact visible clock-face target must install the final minute once");
  const morningState = chaseStore.getState();
  assert(sameJson({
    phase: morningState.chapter4.phase,
    floor: morningState.chapter4.floor,
    roomId: morningState.chapter4.roomId,
    checkpoint: morningState.rpgCheckpoint,
    timeState: morningState.chapter4.timeState,
    worldTimeSeconds: morningState.chapter4.worldTimeSeconds,
    phoneTimeSeconds: morningState.chapter4.phoneStatusTimeSeconds,
    trusted: morningState.chapter4.phoneStatusTimeTrusted,
    guardMode: morningState.chapter4.guardMode,
    finalMinuteInstalled: morningState.chapter4.factIds.includes("final_minute_installed"),
    finalMinute: morningState.items.finalMinute,
    paper: morningState.items.attendanceRecordPaper,
    card: morningState.items.campusCard,
    cardAccepted: morningState.chapter4.checkinCardAccepted,
    paperAccepted: morningState.chapter4.checkinPaperAccepted
  }, {
    phase: "morning_checkin",
    floor: "A1",
    roomId: "a1_checkin",
    checkpoint: "c4_a1_lobby",
    timeState: "0755_morning",
    worldTimeSeconds: 28500,
    phoneTimeSeconds: 28500,
    trusted: true,
    guardMode: "absent",
    finalMinuteInstalled: true,
    finalMinute: false,
    paper: true,
    card: true,
    cardAccepted: false,
    paperAccepted: false
  }), "Task13 final-minute install must atomically enter trusted guard-free 07:55 check-in while retaining paper/card");
  const afterInstallSnapshot = snapshot(morningState);
  const duplicateFinalMinuteInstall = chaseController.resolve755Intent(installFinalMinuteIntent, finalClockRuntimeTarget);
  assert(!duplicateFinalMinuteInstall.accepted && !duplicateFinalMinuteInstall.changed, "Task13 repeated final-minute install must reject");
  assert(snapshot(chaseStore.getState()) === afterInstallSnapshot, "Task13 repeated final-minute install must be zero-write");
  assert(selectQuestViewModel(morningState).steps[0]?.id === "chapter_four_complete_checkin", "Task13 initial morning quest must expose one combined check-in objective");
  const morningProjection = selectChapterFourMazeProjection(morningState);
  assert(
    ["a1_campus_card_reader", "a1_attendance_paper_slot"].every((targetId) => (
      morningProjection.availableTargetIds.includes(targetId)
    )) && !morningProjection.availableTargetIds.includes("a1_hall_clock_minute_endpoint"),
    "Task13 morning projection must expose both check-in targets and close the minute endpoint"
  );
  assert(sameJson(
    selectRpgItemUseGuidance(morningState, "duan_yongping_temporal_maze", "campusCard"),
    {
      status: "ready",
      title: "当前可以使用",
      detail: "靠近目标，把道具拖到物体本身后松手。",
      targetLabel: "签到校园卡读卡器"
    }
  ), "Task13 morning inventory guidance must allow dragging campusCard to the visible reader");
  assert(
    selectRpgItemUseGuidance(morningState, "duan_yongping_temporal_maze", "attendanceRecordPaper").status === "ready",
    "Task13 morning inventory guidance must allow dragging the attendance paper to its visible slot"
  );

  const task13CardTarget = runtimeTargetFromLayout("a1_campus_card_reader");
  const task13PaperTarget = runtimeTargetFromLayout("a1_attendance_paper_slot");
  assert(sameJson(task13CardTarget.bounds, { x: 784, y: 607, width: 30, height: 24 }), "Task13 card-reader bounds must match the visible authored fixture");
  assert(sameJson(task13PaperTarget.bounds, { x: 848, y: 606, width: 38, height: 25 }), "Task13 paper-slot bounds must match the visible authored fixture");
  for (const runtimeTarget of [task13CardTarget, task13PaperTarget]) {
    const resolved = resolveChapterFour755RuntimeEntityTarget(
      runtimeTarget.targetId,
      runtimeTarget.entityId,
      runtimeTarget.bounds
    );
    assert(resolved?.contractPending === false && sameJson(resolved.bounds, runtimeTarget.bounds), `Task13 ${runtimeTarget.targetId} exact runtime envelope must resolve`);
    assert(resolveChapterFour755RuntimeEntityTarget(
      runtimeTarget.targetId,
      runtimeTarget.entityId,
      { ...runtimeTarget.bounds, y: runtimeTarget.bounds.y + 1 }
    ) === null, `Task13 ${runtimeTarget.targetId} translated runtime envelope must reject`);
  }
  const cardIntent = {
    type: "read_campus_card",
    itemId: "campusCard",
    targetId: "a1_campus_card_reader",
    spatial: validSpatial
  };
  const paperIntent = {
    type: "submit_attendance_paper",
    itemId: "attendanceRecordPaper",
    targetId: "a1_attendance_paper_slot",
    spatial: validSpatial
  };
  for (const [label, state, intent, runtimeTarget, reason] of [
    ["card wrong item", morningState, { ...cardIntent, itemId: "attendanceRecordPaper" }, task13CardTarget, "wrong_item"],
    ["paper wrong item", morningState, { ...paperIntent, itemId: "campusCard" }, task13PaperTarget, "wrong_item"],
    ["card wrong mode", { ...morningState, chapter4: { ...morningState.chapter4, mode: "dark" } }, cardIntent, task13CardTarget, "wrong_mode"],
    ["paper too far", morningState, { ...paperIntent, spatial: { ...validSpatial, distance: "too_far" } }, task13PaperTarget, "too_far"],
    ["card missing envelope", morningState, cardIntent, undefined, "locked"],
    ["paper forged entity", morningState, paperIntent, { ...task13PaperTarget, entityId: "forged-paper-slot" }, "locked"],
    ["paper translated bounds", morningState, paperIntent, { ...task13PaperTarget, bounds: { ...task13PaperTarget.bounds, x: task13PaperTarget.bounds.x + 1 } }, "locked"]
  ]) {
    assertZeroWriteRejection(state, intent, reason, runtimeTarget, `Task13 check-in ${label}`);
  }

  function runTask13CheckinOrder(order, label) {
    const store = createGameStore(morningState);
    const events = new EventBus();
    const controller = new ChapterFourTemporalMazeController(store, events);
    const definitions = {
      card: { intent: cardIntent, runtimeTarget: task13CardTarget, fact: "checkin_card_accepted", quest: "chapter_four_submit_attendance_paper" },
      paper: { intent: paperIntent, runtimeTarget: task13PaperTarget, fact: "checkin_paper_accepted", quest: "chapter_four_read_campus_card" }
    };
    const first = definitions[order[0]];
    const second = definitions[order[1]];
    const firstResult = controller.resolve755Intent(first.intent, first.runtimeTarget);
    assert(firstResult.accepted && firstResult.changed, `Task13 ${label} first check-in part must commit once`);
    const afterFirst = store.getState();
    assert(afterFirst.chapter4.phase === "morning_checkin" && afterFirst.chapter4.factIds.includes(first.fact), `Task13 ${label} first part must remain in morning_checkin with its synced fact`);
    assert(afterFirst.items.campusCard && afterFirst.items.attendanceRecordPaper, `Task13 ${label} first part must retain both check-in items`);
    assert(selectQuestViewModel(afterFirst).steps.length === 1 && selectQuestViewModel(afterFirst).steps[0]?.id === first.quest, `Task13 ${label} quest must reveal only the remaining check-in item`);
    const firstSnapshot = snapshot(afterFirst);
    const repeatedFirst = controller.resolve755Intent(first.intent, first.runtimeTarget);
    assert(!repeatedFirst.accepted && !repeatedFirst.changed, `Task13 ${label} repeated first part must reject`);
    assert(snapshot(store.getState()) === firstSnapshot, `Task13 ${label} repeated first part must be zero-write`);
    const secondResult = controller.resolve755Intent(second.intent, second.runtimeTarget);
    assert(secondResult.accepted && secondResult.changed, `Task13 ${label} second check-in part must commit once`);
    const exterior = store.getState();
    assert(sameJson({
      phase: exterior.chapter4.phase,
      floor: exterior.chapter4.floor,
      roomId: exterior.chapter4.roomId,
      checkpoint: exterior.rpgCheckpoint,
      cardAccepted: exterior.chapter4.checkinCardAccepted,
      paperAccepted: exterior.chapter4.checkinPaperAccepted,
      cardFact: exterior.chapter4.factIds.includes("checkin_card_accepted"),
      paperFact: exterior.chapter4.factIds.includes("checkin_paper_accepted"),
      acknowledged: exterior.chapter4.exteriorClosureAcknowledged,
      completed: exterior.chapter4.completed,
      card: exterior.items.campusCard,
      paper: exterior.items.attendanceRecordPaper,
      time: [exterior.chapter4.timeState, exterior.chapter4.worldTimeSeconds, exterior.chapter4.phoneStatusTimeSeconds],
      trusted: exterior.chapter4.phoneStatusTimeTrusted,
      guardMode: exterior.chapter4.guardMode
    }, {
      phase: "exterior_closure",
      floor: "A1",
      roomId: "a1_exterior",
      checkpoint: "c4_a1_lobby",
      cardAccepted: true,
      paperAccepted: true,
      cardFact: true,
      paperFact: true,
      acknowledged: false,
      completed: false,
      card: true,
      paper: true,
      time: ["0755_morning", 28500, 28500],
      trusted: true,
      guardMode: "absent"
    }), `Task13 ${label} second part must enter the unacknowledged exterior wait atomically`);
    assert(selectQuestViewModel(exterior).steps[0]?.id === "chapter_four_answer_zhu_two_questions", `Task13 ${label} exterior quest must expose only the two-question objective before lamp playback`);
    const exteriorTransitions = events.getHistory().filter((event) => (
      event.name === "chapter4_755_intent_committed" && event.payload?.phase === "exterior_closure"
    ));
    assert(exteriorTransitions.length === 1, `Task13 ${label} must transition to exterior_closure exactly once`);
    return exterior;
  }

  const cardThenPaperExterior = runTask13CheckinOrder(["card", "paper"], "card-then-paper");
  runTask13CheckinOrder(["paper", "card"], "paper-then-card");

  const exteriorQuestionStore = createGameStore(cardThenPaperExterior);
  const exteriorQuestionController = new ChapterFourTemporalMazeController(
    exteriorQuestionStore,
    new EventBus()
  );
  const exteriorQuestionResult = exteriorQuestionController.resolve755Intent({
    type: "complete_zhu_two_questions",
    purposeAnswer: "serve_public",
    personAnswer: "clear_minded"
  });
  assert(exteriorQuestionResult.accepted && exteriorQuestionResult.changed, "Task13 exterior questions must commit both answers atomically");
  const answeredExterior = exteriorQuestionStore.getState();
  assert(
    answeredExterior.chapter4.factIds.includes("zhu_two_questions_answered")
      && sameJson(answeredExterior.chapter4.zhuQuestionAnswers, {
        purpose: "serve_public",
        person: "clear_minded"
      }),
    "Task13 exterior questions must persist the two selected answers with their committed fact"
  );
  assert(
    selectQuestViewModel(answeredExterior).steps[0]?.id === "chapter_four_acknowledge_exterior_closure",
    "Task13 exterior quest must expose the lamp closure only after both answers are saved"
  );

  const bareClosureRequest = validateChapterFour755IntentRequest({
    requestId: "task13-bare-closure",
    intent: { type: "acknowledge_exterior_closure" }
  });
  assert(!bareClosureRequest.valid && bareClosureRequest.reason === "invalid_intent", "Task13 bare exterior acknowledgement request must fail schema validation");
  assertZeroWriteRejection(
    cardThenPaperExterior,
    { type: "acknowledge_exterior_closure" },
    "locked",
    undefined,
    "Task13 bare exterior acknowledgement controller gate"
  );
  const fakeClosureProof = {
    assetId: "unregistered-star-asset",
    sequenceId: "unregistered-sequence",
    consumerModule: "unregistered-consumer",
    sessionId: "fake-session",
    completionEventId: "fake-completion"
  };
  assertZeroWriteRejection(
    cardThenPaperExterior,
    { type: "acknowledge_exterior_closure", proof: fakeClosureProof },
    "locked",
    undefined,
    "Task13 exterior acknowledgement without approved official reference"
  );

  const earlyMaliciousLoaded = hydrate({
    ...returnA1State,
    chapter4: {
      ...returnA1State.chapter4,
      phase: "maintenance_repair",
      factIds: [...returnA1State.chapter4.factIds, "final_minute_installed", "checkin_card_accepted", "checkin_paper_accepted", "exterior_closure_acknowledged"],
      checkinCardAccepted: true,
      checkinPaperAccepted: true,
      exteriorClosureAcknowledged: true,
      completed: false
    }
  });
  assert(
    ["final_minute_installed", "checkin_card_accepted", "checkin_paper_accepted", "exterior_closure_acknowledged"].every((factId) => !earlyMaliciousLoaded.chapter4.factIds.includes(factId))
      && !earlyMaliciousLoaded.chapter4.checkinCardAccepted
      && !earlyMaliciousLoaded.chapter4.checkinPaperAccepted
      && !earlyMaliciousLoaded.chapter4.exteriorClosureAcknowledged
      && !earlyMaliciousLoaded.chapter4.completed,
    "Task13 saves before return/morning must remove forged future check-in and closure fields"
  );
  const returnLoaded = hydrate({
    ...returnA1State,
    items: { ...returnA1State.items, finalMinute: false, attendanceRecordPaper: false, campusCard: false },
    chapter4: {
      ...returnA1State.chapter4,
      factIds: returnA1State.chapter4.factIds.filter((factId) => factId !== "final_minute_recovered")
        .concat("checkin_card_accepted", "exterior_closure_acknowledged"),
      checkinCardAccepted: true,
      exteriorClosureAcknowledged: true
    }
  });
  assert(
    returnLoaded.chapter4.phase === "return_to_clock"
      && returnLoaded.chapter4.factIds.includes("final_minute_recovered")
      && !returnLoaded.chapter4.factIds.includes("final_minute_installed")
      && !returnLoaded.chapter4.factIds.includes("checkin_card_accepted")
      && returnLoaded.items.finalMinute
      && returnLoaded.items.attendanceRecordPaper
      && returnLoaded.items.campusCard,
    "Task13 return save must restore minute/paper/card and clear future check-in closure"
  );
  const cardOnlyMorningLoaded = hydrate({
    ...morningState,
    items: { ...morningState.items, finalMinute: true, attendanceRecordPaper: false, campusCard: false },
    chapter4: {
      ...morningState.chapter4,
      factIds: [...morningState.chapter4.factIds, "checkin_card_accepted", "checkin_paper_accepted", "exterior_closure_acknowledged"],
      checkinCardAccepted: true,
      checkinPaperAccepted: false,
      exteriorClosureAcknowledged: true,
      completed: false
    }
  });
  assert(sameJson({
    phase: cardOnlyMorningLoaded.chapter4.phase,
    roomId: cardOnlyMorningLoaded.chapter4.roomId,
    cardAccepted: cardOnlyMorningLoaded.chapter4.checkinCardAccepted,
    paperAccepted: cardOnlyMorningLoaded.chapter4.checkinPaperAccepted,
    cardFact: cardOnlyMorningLoaded.chapter4.factIds.includes("checkin_card_accepted"),
    paperFact: cardOnlyMorningLoaded.chapter4.factIds.includes("checkin_paper_accepted"),
    closureFact: cardOnlyMorningLoaded.chapter4.factIds.includes("exterior_closure_acknowledged"),
    finalMinute: cardOnlyMorningLoaded.items.finalMinute,
    paper: cardOnlyMorningLoaded.items.attendanceRecordPaper,
    card: cardOnlyMorningLoaded.items.campusCard,
    acknowledged: cardOnlyMorningLoaded.chapter4.exteriorClosureAcknowledged,
    completed: cardOnlyMorningLoaded.chapter4.completed
  }, {
    phase: "morning_checkin",
    roomId: "a1_checkin",
    cardAccepted: true,
    paperAccepted: false,
    cardFact: true,
    paperFact: false,
    closureFact: false,
    finalMinute: false,
    paper: true,
    card: true,
    acknowledged: false,
    completed: false
  }), "Task13 morning save must preserve only valid boolean+fact pairs and repair items/location");
  const bothMorningLoaded = hydrate({
    ...morningState,
    chapter4: {
      ...morningState.chapter4,
      factIds: [...morningState.chapter4.factIds, "checkin_card_accepted", "checkin_paper_accepted"],
      checkinCardAccepted: true,
      checkinPaperAccepted: true
    }
  });
  assert(
    bothMorningLoaded.chapter4.phase === "exterior_closure"
      && bothMorningLoaded.chapter4.roomId === "a1_exterior"
      && bothMorningLoaded.chapter4.checkinCardAccepted
      && bothMorningLoaded.chapter4.checkinPaperAccepted
      && !bothMorningLoaded.chapter4.exteriorClosureAcknowledged
      && !bothMorningLoaded.chapter4.completed,
    "Task13 morning save with both valid check-ins must normalize once to the exterior wait"
  );
  const coherentCompleteLoaded = hydrate({
    ...answeredExterior,
    chapter4: {
      ...answeredExterior.chapter4,
      phase: "complete",
      factIds: [...answeredExterior.chapter4.factIds, "exterior_closure_acknowledged"],
      exteriorClosureAcknowledged: true,
      completed: true
    }
  });
  assert(
    coherentCompleteLoaded.chapter4.phase === "complete"
      && coherentCompleteLoaded.chapter4.factIds.includes("exterior_closure_acknowledged")
      && coherentCompleteLoaded.chapter4.exteriorClosureAcknowledged
      && coherentCompleteLoaded.chapter4.completed,
    "Task13 coherent completion must survive hydration after final answers and approved consumer proof have been persisted"
  );
  const bareAcknowledgedExteriorLoaded = hydrate({
    ...cardThenPaperExterior,
    chapter4: {
      ...cardThenPaperExterior.chapter4,
      phase: "exterior_closure",
      factIds: [...cardThenPaperExterior.chapter4.factIds, "exterior_closure_acknowledged"],
      exteriorClosureAcknowledged: true,
      completed: true
    }
  });
  assert(
    bareAcknowledgedExteriorLoaded.chapter4.phase === "exterior_closure"
      && bareAcknowledgedExteriorLoaded.chapter4.roomId === "a1_exterior"
      && !bareAcknowledgedExteriorLoaded.chapter4.factIds.includes("exterior_closure_acknowledged")
      && !bareAcknowledgedExteriorLoaded.chapter4.exteriorClosureAcknowledged
      && !bareAcknowledgedExteriorLoaded.chapter4.completed,
    "Task13 acknowledged exterior save must stay blocked at the official exterior consumer boundary"
  );

  const failureFixture = {
    ...directElevatorState,
    ui: { ...directElevatorState.ui, inventoryOpen: true, selectedItem: "campusCard" },
    chapter4: { ...directElevatorState.chapter4, mode: "dark" }
  };
  const failureStore = createGameStore(failureFixture);
  const failureController = new ChapterFourTemporalMazeController(failureStore, new EventBus());
  const beforeFailure = failureStore.getState();
  const acceptedFailure = failureController.resolve755Intent({ type: "fail_chase", expectedAttempt: 7 });
  const afterFailure = failureStore.getState();
  assert(acceptedFailure.accepted && acceptedFailure.changed, "Task12 current attempt failure must commit once");
  assert(sameJson({
    attempt: afterFailure.chapter4.chaseAttempt,
    floor: afterFailure.chapter4.floor,
    roomId: afterFailure.chapter4.roomId,
    checkpoint: afterFailure.rpgCheckpoint,
    facts: afterFailure.chapter4.factIds,
    items: afterFailure.items,
    mask: afterFailure.chapter4.lightGrid,
    mode: afterFailure.chapter4.mode,
    time: [afterFailure.chapter4.timeState, afterFailure.chapter4.worldTimeSeconds, afterFailure.chapter4.phoneStatusTimeSeconds],
    inventoryOpen: afterFailure.ui.inventoryOpen,
    selectedItem: afterFailure.ui.selectedItem
  }, {
    attempt: 8,
    floor: "A1",
    roomId: "a1_lobby",
    checkpoint: "c4_a1_lobby",
    facts: beforeFailure.chapter4.factIds,
    items: beforeFailure.items,
    mask: beforeFailure.chapter4.lightGrid,
    mode: "dark",
    time: ["0754_blackout", 28440, 28440],
    inventoryOpen: true,
    selectedItem: "campusCard"
  }), "Task12 failure may change only attempt and the authored A1 restart location");
  const afterFailureSnapshot = snapshot(afterFailure);
  const staleFailure = failureController.resolve755Intent({ type: "fail_chase", expectedAttempt: 7 });
  assert(!staleFailure.accepted && !staleFailure.changed, "Task12 stale failure callback must reject");
  assert(snapshot(failureStore.getState()) === afterFailureSnapshot, "Task12 stale failure callback must be zero-write");

  const maliciousChaseLoaded = hydrate({
    ...directElevatorState,
    rpgCheckpoint: "c4_a2_room202",
    items: {
      ...directElevatorState.items,
      attendanceRecordPaper: true,
      finalMinute: true
    },
    chapter4: {
      ...directElevatorState.chapter4,
      floor: "A2",
      roomId: "a2_room_202",
      guardMode: "absent",
      factIds: [...directElevatorState.chapter4.factIds, "final_minute_recovered"],
      finalChaseRuntime: { phase: "portal_transfer", guardVisible: false, doorOpen: false }
    }
  });
  assert(sameJson({
    phase: maliciousChaseLoaded.chapter4.phase,
    floor: maliciousChaseLoaded.chapter4.floor,
    roomId: maliciousChaseLoaded.chapter4.roomId,
    checkpoint: maliciousChaseLoaded.rpgCheckpoint,
    guardMode: maliciousChaseLoaded.chapter4.guardMode,
    attempt: maliciousChaseLoaded.chapter4.chaseAttempt,
    paper: maliciousChaseLoaded.items.attendanceRecordPaper,
    finalMinute: maliciousChaseLoaded.items.finalMinute,
    recovered: maliciousChaseLoaded.chapter4.factIds.includes("final_minute_recovered"),
    runtimePersisted: "finalChaseRuntime" in maliciousChaseLoaded.chapter4,
    time: [maliciousChaseLoaded.chapter4.timeState, maliciousChaseLoaded.chapter4.worldTimeSeconds, maliciousChaseLoaded.chapter4.phoneStatusTimeSeconds]
  }, {
    phase: "final_chase",
    floor: "A1",
    roomId: "a1_lobby",
    checkpoint: "c4_a1_lobby",
    guardMode: "chase",
    attempt: 7,
    paper: false,
    finalMinute: false,
    recovered: false,
    runtimePersisted: false,
    time: ["0754_blackout", 28440, 28440]
  }), "Task12 chase reload must discard malicious runtime/door/guard state and restart the same attempt at A1");

  const maliciousRecoveryLoaded = hydrate({
    ...recoveryState,
    rpgCheckpoint: "c4_a1_lobby",
    items: { ...recoveryState.items, attendanceRecordPaper: true, finalMinute: true },
    chapter4: {
      ...recoveryState.chapter4,
      floor: "A1",
      roomId: "a2_lecture_202",
      guardMode: "chase",
      finalChaseRuntime: { phase: "complete", doorOpen: true }
    }
  });
  assert(sameJson({
    phase: maliciousRecoveryLoaded.chapter4.phase,
    floor: maliciousRecoveryLoaded.chapter4.floor,
    roomId: maliciousRecoveryLoaded.chapter4.roomId,
    checkpoint: maliciousRecoveryLoaded.rpgCheckpoint,
    guardMode: maliciousRecoveryLoaded.chapter4.guardMode,
    paper: maliciousRecoveryLoaded.items.attendanceRecordPaper,
    finalMinute: maliciousRecoveryLoaded.items.finalMinute,
    runtimePersisted: "finalChaseRuntime" in maliciousRecoveryLoaded.chapter4
  }, {
    phase: "final_minute_recovery",
    floor: "A2",
    roomId: "a2_room_202",
    checkpoint: "c4_a2_room202",
    guardMode: "absent",
    paper: false,
    finalMinute: false,
    runtimePersisted: false
  }), "Task12 recovery reload must migrate inside A2-202, remove the guard and discard uncommitted grants/runtime state");

  for (const [label, source, expected] of [
    [
      "A2 room202",
      {
        ...returnA2State,
        rpgCheckpoint: "c4_a1_lobby",
        items: { ...returnA2State.items, attendanceRecordPaper: false, finalMinute: false },
        chapter4: {
          ...returnA2State.chapter4,
          guardMode: "chase",
          factIds: returnA2State.chapter4.factIds.filter((factId) => factId !== "final_minute_recovered")
        }
      },
      { floor: "A2", roomId: "a2_room_202", checkpoint: "c4_a2_room202" }
    ],
    [
      "A1 lobby",
      {
        ...returnA1State,
        rpgCheckpoint: "c4_a2_room202",
        items: { ...returnA1State.items, attendanceRecordPaper: false, finalMinute: false },
        chapter4: {
          ...returnA1State.chapter4,
          guardMode: "chase",
          factIds: returnA1State.chapter4.factIds.filter((factId) => factId !== "final_minute_recovered")
        }
      },
      { floor: "A1", roomId: "a1_lobby", checkpoint: "c4_a1_lobby" }
    ]
  ]) {
    const loaded = hydrate(source);
    assert(sameJson({
      floor: loaded.chapter4.floor,
      roomId: loaded.chapter4.roomId,
      checkpoint: loaded.rpgCheckpoint
    }, expected), `Task12 return reload must preserve the ${label} safe side of main_stair`);
    assert(
      loaded.chapter4.guardMode === "absent"
        && loaded.chapter4.factIds.includes("final_minute_recovered")
        && loaded.items.finalMinute
        && loaded.items.attendanceRecordPaper,
      `Task12 return reload must repair the committed grant closure without restoring the guard (${label})`
    );
    assert(
      loaded.chapter4.timeState === "0754_blackout"
        && loaded.chapter4.worldTimeSeconds === 28440
        && loaded.chapter4.phoneStatusTimeSeconds === 28440,
      `Task12 return reload must preserve 07:54 (${label})`
    );
  }

  const guardRules = CHAPTER_FOUR_MAINTENANCE_GUARD_RULES;
  assert(sameJson(guardRules, {
    confirmationMs: 400,
    sightLossMs: 900,
    coneRange: 220,
    coneHalfAngleDegrees: 36,
    closeRadius: 56,
    patrolSpeed: 84,
    pursuitSpeed: 140,
    returnSpeed: 96,
    pauseMinMs: 1000,
    pauseMaxMs: 2000,
    maxStepMs: 50,
    footBox: { width: 20, height: 16 }
  }), "pure ordinary-guard rules must match the Task10 timing and geometry contract");
  assert(
    sameJson(Object.values(CHAPTER_FOUR_MAINTENANCE_PATROL_WAYPOINTS), maintenanceLayout.guard.patrolWaypoints),
    "pure guard waypoint graph must match the authoritative layout"
  );

  const guardPlayer = { x: 1005, y: 560 };
  const guardInitial = createChapterFourMaintenanceGuardState(0x755);
  const confirming399 = stepChapterFourMaintenanceGuard(guardInitial, {
    deltaMs: 399,
    guardPosition: guardInitial.position,
    playerPosition: guardPlayer,
    walls: []
  });
  assert(confirming399.state.mode === "confirming", "399ms continuous visibility must remain confirming");
  assert(confirming399.state.visibleForMs === 399 && !confirming399.enteredPursuit, "399ms must not enter pursuit");
  const pursuit400 = stepChapterFourMaintenanceGuard(confirming399.state, {
    deltaMs: 1,
    guardPosition: confirming399.state.position,
    playerPosition: guardPlayer,
    walls: []
  });
  assert(pursuit400.state.mode === "pursuit" && pursuit400.enteredPursuit, "400ms continuous visibility must enter pursuit");
  assert(sameJson(pursuit400.state.lastVisiblePosition, guardPlayer), "pursuit must retain the last visible player position");

  const invisiblePlayer = { x: 1600, y: 900 };
  const lost899 = stepChapterFourMaintenanceGuard(pursuit400.state, {
    deltaMs: 899,
    guardPosition: pursuit400.state.position,
    playerPosition: invisiblePlayer,
    walls: []
  });
  assert(lost899.state.mode === "pursuit" && lost899.state.sightLostForMs === 899, "899ms sight loss must remain pursuit");
  const returning900 = stepChapterFourMaintenanceGuard(lost899.state, {
    deltaMs: 1,
    guardPosition: lost899.state.position,
    playerPosition: invisiblePlayer,
    walls: []
  });
  assert(returning900.state.mode === "returning" && returning900.disengaged, "900ms sight loss must enter returning");
  assert(returning900.state.lastVisiblePosition !== null, "disengage must retain the final last-visible position for diagnosis");

  const pursuitWithLoss = {
    ...pursuit400.state,
    sightLostForMs: 600,
    position: { x: 1105, y: 560 },
    heading: { x: -1, y: 0 }
  };
  const regainedPoint = { x: 1065, y: 560 };
  const regained = stepChapterFourMaintenanceGuard(pursuitWithLoss, {
    deltaMs: 50,
    guardPosition: pursuitWithLoss.position,
    playerPosition: regainedPoint,
    walls: []
  });
  assert(regained.state.mode === "pursuit" && regained.state.sightLostForMs === 0, "reacquiring the player must clear accumulated sight loss");
  assert(sameJson(regained.state.lastVisiblePosition, regainedPoint), "reacquiring the player must update last-visible position");

  const lastVisibleSource = {
    ...pursuit400.state,
    position: { x: 0, y: 0 },
    heading: { x: 1, y: 0 },
    lastVisiblePosition: { x: 100, y: 0 },
    sightLostForMs: 0
  };
  const trackingLastVisible = stepChapterFourMaintenanceGuard(lastVisibleSource, {
    deltaMs: 50,
    guardPosition: lastVisibleSource.position,
    playerPosition: { x: -500, y: 0 },
    walls: []
  });
  assert(Math.abs(trackingLastVisible.state.position.x - 7) < 1e-9, "lost pursuit must move at 140px/s toward last-visible position");
  assert(sameJson(trackingLastVisible.desiredVelocity, { x: 140, y: 0 }), "pursuit must expose its 140px/s desired Arcade velocity");
  assert(sameJson(trackingLastVisible.state.lastVisiblePosition, { x: 100, y: 0 }), "lost pursuit must not overwrite last-visible position");

  const returningSource = {
    ...createChapterFourMaintenanceGuardRecoveryState(0x755),
    mode: "returning",
    position: { x: 900, y: 240 },
    targetWaypointId: "stair_north",
    pauseRemainingMs: 0
  };
  const returningMove = stepChapterFourMaintenanceGuard(returningSource, {
    deltaMs: 100,
    guardPosition: returningSource.position,
    playerPosition: invisiblePlayer,
    walls: []
  });
  assert(returningMove.state.mode === "returning", "returning guard must stay returning before reaching its waypoint");
  assert(Math.abs(returningMove.state.position.x - 909.6) < 1e-6, "returning guard must move at 96px/s");
  assert(Math.abs(returningMove.desiredVelocity.x - 96) < 1e-6, "returning guard must expose its 96px/s desired Arcade velocity");
  const collisionRebasedMove = stepChapterFourMaintenanceGuard(returningMove.state, {
    deltaMs: 100,
    guardPosition: returningSource.position,
    playerPosition: invisiblePlayer,
    walls: []
  });
  assert(
    Math.abs(collisionRebasedMove.state.position.x - 909.6) < 1e-6,
    "runtime body feedback must rebase a blocked guard instead of preserving predicted penetration"
  );
  const recoveryGuard = createChapterFourMaintenanceGuardRecoveryState(0x755);
  assert(
    sameJson(recoveryGuard.position, { x: 588, y: 220 })
      && recoveryGuard.previousWaypointId === "west_north"
      && recoveryGuard.targetWaypointId === "stair_north",
    "capture recovery must reset the guard from west_north toward stair_north"
  );

  const directLargeStep = stepChapterFourMaintenanceGuard(createChapterFourMaintenanceGuardState(12345), {
    deltaMs: 1000,
    guardPosition: { x: 1105, y: 560 },
    playerPosition: guardPlayer,
    walls: []
  }).state;
  let slicedState = createChapterFourMaintenanceGuardState(12345);
  for (let index = 0; index < 20; index += 1) {
    slicedState = stepChapterFourMaintenanceGuard(slicedState, {
      deltaMs: 50,
      guardPosition: slicedState.position,
      playerPosition: guardPlayer,
      walls: []
    }).state;
  }
  assert(sameJson(directLargeStep, slicedState), "guard delta processing must be equivalent to 50ms maximum slices");
  const deterministicA = stepChapterFourMaintenanceGuard(createChapterFourMaintenanceGuardState(424242), {
    deltaMs: 20000,
    guardPosition: { x: 1105, y: 560 },
    playerPosition: invisiblePlayer,
    walls: []
  }).state;
  const deterministicB = stepChapterFourMaintenanceGuard(createChapterFourMaintenanceGuardState(424242), {
    deltaMs: 20000,
    guardPosition: { x: 1105, y: 560 },
    playerPosition: invisiblePlayer,
    walls: []
  }).state;
  const deterministicOtherSeed = stepChapterFourMaintenanceGuard(createChapterFourMaintenanceGuardState(424243), {
    deltaMs: 20000,
    guardPosition: { x: 1105, y: 560 },
    playerPosition: invisiblePlayer,
    walls: []
  }).state;
  assert(sameJson(deterministicA, deterministicB), "equal guard seeds and inputs must be reproducible");
  assert(!sameJson(deterministicA, deterministicOtherSeed), "different guard seeds must affect deterministic patrol pauses or position");
  assert(deterministicA.pauseRemainingMs >= 0 && deterministicA.pauseRemainingMs <= 2000, "patrol pause remainder must stay within the authored 1-2s range");

  const sightState = {
    ...createChapterFourMaintenanceGuardState(),
    position: { x: 0, y: 0 },
    heading: { x: 1, y: 0 }
  };
  assert(canChapterFourGuardSeePlayer(sightState, { x: 100, y: 0 }, []), "player inside the forward cone with clear LOS must be visible");
  assert(!canChapterFourGuardSeePlayer(sightState, { x: 0, y: 100 }, []), "player outside the 36-degree half-angle must be hidden");
  assert(!canChapterFourGuardSeePlayer(sightState, { x: 221, y: 0 }, []), "player beyond 220px cone range must be hidden");
  const blockingWall = [{ x: 40, y: -5, width: 10, height: 10 }];
  assert(!canChapterFourGuardSeePlayer(sightState, { x: 100, y: 0 }, blockingWall), "wall must block cone visibility");
  assert(!canChapterFourGuardSeePlayer(sightState, { x: 30, y: 0 }, [{ x: 10, y: -4, width: 5, height: 8 }]), "close-radius visibility must still be blocked by a wall");
  assert(hasChapterFourGuardLineOfSight(
    { x: 0, y: 5 },
    { x: 100, y: 5 },
    [{ x: 40, y: 0, width: 10, height: 5 }]
  ), "LOS along the excluded bottom edge of a half-open wall must remain clear");
  assert(!hasChapterFourGuardLineOfSight(
    { x: 0, y: 4.999 },
    { x: 100, y: 4.999 },
    [{ x: 40, y: 0, width: 10, height: 5 }]
  ), "LOS through the included interior of a half-open wall must be blocked");
  assert(chapterFourGuardFootContact(
    { x: 10, y: 8 },
    { x: 19.999, y: 0, width: 1, height: 1 }
  ), "guard foot contact must accept positive half-open overlap");
  assert(!chapterFourGuardFootContact(
    { x: 10, y: 8 },
    { x: 20, y: 0, width: 1, height: 1 }
  ), "guard foot contact must reject edge-only half-open contact");
  assert(!halfOpenRectsOverlap(
    { x: 0, y: 0, width: 20, height: 16 },
    { x: 20, y: 16, width: 1, height: 1 }
  ), "half-open rectangles must reject corner-only contact");
} catch (error) {
  errors.push(error instanceof Error ? error.stack ?? error.message : String(error));
} finally {
  await server.close();
}

if (errors.length > 0) {
  console.error(`Chapter 4 7:55 runtime validation failed (${errors.length} error${errors.length === 1 ? "" : "s"}):`);
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}

console.log(`Chapter 4 7:55 runtime PASS assertions=${assertionCount} controller=task7-13_zero-write+once+expectedAttempt save=task7-13_matrix quest=single-next-objective registry=runtime-bounds+task13-anti-forgery projection=task8+task9+task10+task11+task12+task13 lightGrid=32-vector-unique guard=ordinary+final-pure-behavior task12Route=main_stair-only task13=install+checkin-pass closure=blocked-without-official-reference`);
