import { createGameStore, createInitialGameState } from "../src/core/GameState.ts";
import { SaveStore } from "../src/core/SaveStore.ts";
import { EventBus } from "../src/core/EventBus.ts";
import { selectQuestViewModel } from "../src/core/QuestModel.ts";
import { selectChapterThreeInterludeViewModel } from "../src/modules/ChapterThreeInterludeModel.ts";
import { ChapterThreePhoneInterludeController } from "../src/modules/ChapterThreePhoneInterludeController.ts";
import { ChapterThreeCanteenController } from "../src/modules/ChapterThreeCanteenController.ts";
import { ChapterFourTemporalMazeController } from "../src/modules/ChapterFourTemporalMazeController.ts";
import {
  createCanonicalCompleteRoom204Placements,
  ROOM204_PIECE_ORDER,
  ROOM204_SLOT_ORDER
} from "../src/scenes/rpg/ChapterFourRoom204Model.ts";

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

class MemoryStorage {
  #map = new Map();

  getItem(key) {
    return this.#map.has(key) ? this.#map.get(key) : null;
  }

  setItem(key, value) {
    this.#map.set(key, String(value));
  }

  removeItem(key) {
    this.#map.delete(key);
  }

  clear() {
    this.#map.clear();
  }
}

function roundtrip(state) {
  const storage = new MemoryStorage();
  const store = new SaveStore(storage);
  assert(store.save(state), "save roundtrip must persist state");
  const loaded = store.load(createInitialGameState());
  assert(loaded, "save roundtrip must load state");
  return loaded;
}

function testInterludeParallelEvidence() {
  const store = createGameStore(createInitialGameState());
  const events = new EventBus();
  const controller = new ChapterThreePhoneInterludeController(store, events);

  store.setState((current) => ({
    ...current,
    qizhenLake: {
      ...current.qizhenLake,
      phase: "complete"
    }
  }));

  assert(controller.beginRecovery() === "accepted", "recovery must open after qizhen completion");
  assert(controller.completeJournalCloseout("safe_return") === "accepted", "journal closeout must unlock evidence collection");

  const openedView = selectChapterThreeInterludeViewModel(store.getState());
  assert(openedView.currentObjective.id === "chapter_three_interlude_evidence_collection", "interlude task must aggregate the four evidence branches");
  assert(openedView.currentObjective.label === "恢复剩余证据 0/4", "interlude aggregate label must start at 0/4");

  assert(controller.saveOfficialNotice() === "accepted", "official notice may be collected before photos and voice");
  assert(controller.saveRouteScreenshot(["east_closed", "west_cleaner"]) === "accepted", "route screenshot may be collected before photos and voice");
  assert(controller.readNetworkRecord("record_0755") === "accepted", "network record may be collected before photos and voice");

  const networkFirstView = selectChapterThreeInterludeViewModel(store.getState());
  assert(networkFirstView.currentObjective.id === "chapter_three_interlude_evidence_collection", "network-first run must remain in aggregate evidence task");
  assert(networkFirstView.currentObjective.label === "恢复剩余证据 1/4", "network-first run must increment aggregate evidence progress");

  assert(controller.submitVoiceSequence(["lake", "stone", "lobby", "broadcast"]) === "accepted", "voice branch must complete independently");
  assert(controller.submitPhotoSequence(["paper_left", "paper_middle", "paper_right"]) === "accepted", "photo branch must complete independently");

  assert(controller.rejectDecoy("canteen_0755", "number_not_time") === "accepted", "canteen decoy must be rejectable");
  assert(controller.rejectDecoy("theater_0832", "earlier_independent_event") === "accepted", "theater decoy must be rejectable");
  assert(controller.rejectDecoy("status_clock_075523", "frozen_local_clock") === "accepted", "status clock decoy must be rejectable");

  const destinationView = selectChapterThreeInterludeViewModel(store.getState());
  assert(destinationView.currentObjective.id === "chapter_three_interlude_destination", "automatic timeline must skip the dead manual timeline task");

  const reloaded = roundtrip({
    ...createInitialGameState(),
    qizhenLake: {
      ...createInitialGameState().qizhenLake,
      phase: "complete"
    },
    chapterThreeInterlude: {
      ...createInitialGameState().chapterThreeInterlude,
      recoveryOpened: true,
      phase: "journal_closeout"
    }
  });
  assert(!reloaded.chapterThreeInterlude.evidenceIds.includes("journal_start"), "recoveryOpened alone must not fabricate journal_start evidence");
}

function testCanteenModeOrderFreedom() {
  const store = createGameStore(createInitialGameState());
  const events = new EventBus();
  const controller = new ChapterThreeCanteenController(store, events);

  store.setState((current) => ({
    ...current,
    canteenHunt: {
      ...current.canteenHunt,
      active: true,
      phase: "menu_order",
      mode: "light"
    }
  }));

  assert(controller.selectMenuOption("D") === "correct", "light-mode ordering must still work first");
  assert(controller.setMode("dark"), "canteen mode must switch to dark");
  assert(controller.inspectMenuClue(), "menu clue must remain readable after ordering advances to pickup_search");

  store.setState((current) => ({
    ...current,
    items: {
      ...current.items,
      pickupTicket0755: true
    },
    canteenHunt: {
      ...current.canteenHunt,
      active: true,
      phase: "pickup_search",
      orderedMenuOption: "D",
      pickupDarkClueRead: false,
      mode: "light"
    }
  }));

  assert(controller.selectPickupWindow("3") === "locked", "light-mode pickup must still reject before dark clue");
  assert(controller.setMode("dark"), "pickup stage must switch to dark");
  assert(controller.inspectPickupWindow("3"), "pickup clue must remain readable after a failed light-mode attempt");
  assert(controller.selectPickupWindow("3") === "correct", "dark pickup must still complete after the clue is read later");

  assert(store.getState().canteenHunt.phase === "exit_blocking", "late dark clue completion must still advance canteen flow to exit_blocking");
  void selectQuestViewModel(store.getState());
}

function testChapterFourModeOrderFreedom() {
  const store = createGameStore(createInitialGameState());
  const events = new EventBus();
  const controller = new ChapterFourTemporalMazeController(store, events);

  store.setState((current) => ({
    ...current,
    runtimeMode: "rpg",
    rpgScene: "duan_yongping_temporal_maze",
    rpgCheckpoint: "c4_a1_lobby",
    currentScene: "phone_home",
    chapter4: {
      ...current.chapter4,
      prologueSeen: true,
      phase: "room204_restore",
      floor: "A1",
      roomId: "a1_lobby",
      mode: "light",
      factIds: [
        "classroom_104_chalk_residual_observed",
        "classroom_105_terminal_replay_checked"
      ]
    }
  }));

  const calibrateFirst = controller.resolve755Intent({
    type: "calibrate_elevator_history",
    startSeconds: 81811
  });
  assert(calibrateFirst.accepted, "elevator calibration must accept before dark observation");
  store.setState((current) => ({
    ...current,
    chapter4: {
      ...current.chapter4,
      mode: "dark"
    }
  }));
  const observeLater = controller.resolve755Intent({ type: "observe_elevator_history" });
  assert(observeLater.accepted, "elevator history observation must still accept after calibration");
  assert(store.getState().chapter4.factIds.includes("elevator_history_calibrated"), "elevator calibration fact must persist");
  assert(store.getState().chapter4.factIds.includes("elevator_history_observed"), "elevator observation fact must persist");

  store.setState((current) => ({
    ...current,
    rpgCheckpoint: "c4_a3_wayfinding",
    chapter4: {
      ...current.chapter4,
      floor: "A3",
      roomId: "a3_wayfinding",
      mode: "light",
      factIds: [
        "classroom_104_chalk_residual_observed",
        "classroom_105_terminal_replay_checked",
        "elevator_history_calibrated"
      ],
      zhuQuestionAnswers: {
        purpose: null,
        person: null
      }
    }
  }));

  const a3ZhuAttemptBeforeClosure = controller.resolve755Intent({
    type: "complete_zhu_two_questions",
    purposeAnswer: "seek_truth",
    personAnswer: "responsible"
  });
  assert(
    !a3ZhuAttemptBeforeClosure.accepted
      && a3ZhuAttemptBeforeClosure.detailCode === "zhu_two_questions_required",
    "Zhu questions must remain unavailable during the A3 room204 route"
  );
  const stairBeforeReference = controller.resolve755Intent({ type: "complete_misaligned_stair" });
  assert(
    !stairBeforeReference.accepted
      && stairBeforeReference.detailCode === "a3_reference_required",
    "misaligned stair must reject until the A3 classroom reference is recorded"
  );
  store.setState((current) => ({
    ...current,
    chapter4: {
      ...current.chapter4,
      roomId: "a3_reference_classroom",
      mode: "dark"
    }
  }));
  const a3Reference = controller.resolve755Intent({
    type: "observe_a3_reference",
    targetId: "a3_reference_classroom_layout",
    spatial: { distance: "within_range" }
  });
  assert(a3Reference.accepted, "A3 reference observation must accept in dark mode");
  const stairAfterReference = controller.resolve755Intent({ type: "complete_misaligned_stair" });
  assert(stairAfterReference.accepted, "misaligned stair must accept after the A3 reference without Zhu answers");
  assert(store.getState().chapter4.floor === "A2", "misaligned stair completion must still relocate to A2");
  assert(
    !store.getState().chapter4.factIds.includes("zhu_two_questions_answered"),
    "the A3-to-A2 route must not fabricate the final Zhu answer fact"
  );

  const roomReloadPrerequisites = [
    "bakery_conveyor_lamp_inspected",
    "bakery_conveyor_direction_observed",
    "bakery_tool_location_observed",
    "bakery_hour_hand_exposed",
    "bakery_hour_hand_collected",
    "hour_hand_installed",
    "classroom_104_chalk_residual_observed",
    "classroom_105_terminal_replay_checked",
    "elevator_history_observed",
    "elevator_history_calibrated",
    "a1_time_route_compared",
    "a3_reference_observed",
    "a3_identity_context_observed",
    "misaligned_stair_solved"
  ];

  const partialRoomReload = roundtrip({
    ...store.getState(),
    chapter4: {
      ...store.getState().chapter4,
      phase: "room204_restore",
      floor: "A2",
      roomId: "a2_room204",
      factIds: roomReloadPrerequisites,
      room204Placements: [{
        pieceId: ROOM204_PIECE_ORDER[0],
        slotId: ROOM204_SLOT_ORDER[0],
        orientation: "up"
      }]
    }
  });
  assert(!partialRoomReload.chapter4.factIds.includes("room204_restored"), "partial room placements must not auto-complete without both observations");

  const restoredRoomReload = roundtrip({
    ...store.getState(),
    chapter4: {
      ...store.getState().chapter4,
      phase: "room204_restore",
      floor: "A2",
      roomId: "a2_room204",
      factIds: [...roomReloadPrerequisites, "room204_residual_observed"],
      room204Placements: createCanonicalCompleteRoom204Placements()
    }
  });
  assert(restoredRoomReload.chapter4.factIds.includes("room204_restored"), "complete room placements plus both observations must still synthesize room204_restored");
}

function main() {
  testInterludeParallelEvidence();
  testCanteenModeOrderFreedom();
  testChapterFourModeOrderFreedom();
  console.log("mode-order flexibility PASS");
}

main();
