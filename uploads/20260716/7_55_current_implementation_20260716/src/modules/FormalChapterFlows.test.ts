import { describe, expect, it } from "vitest";
import { EventBus } from "../core/EventBus";
import { createGameStore } from "../core/GameState";
import type {
  LibraryEvidenceId,
  LibraryFinalsBdReplyId,
  LibraryRecoveryEvidenceId
} from "../core/types";
import actOneContent from "../data/act-one-bootstrap.content.json";
import { ActOneBootstrapController } from "./ActOneBootstrapController";
import { BikeArcadeChapterController } from "./BikeArcadeChapterController";
import { CheckinController } from "./CheckinController";
import { DigitCollector } from "./DigitCollector";
import { InventoryController } from "./InventoryController";
import { LibraryFinalsController } from "./LibraryFinalsController";

const evidence: LibraryEvidenceId[] = [
  "archived_leave_rule",
  "bag_non_person_proof",
  "seat_022_receipt",
  "library_presence_proof"
];
const bdReplies: LibraryFinalsBdReplyId[] = [
  "reply-seat-ticket",
  "reply-visit-proof",
  "reply-bag-nonperson"
];
const recoveryEvidence: LibraryRecoveryEvidenceId[] = [
  "bag_non_person_proof",
  "seat_022_receipt",
  "library_presence_proof"
];

function completeChapterOne() {
  const store = createGameStore();
  const events = new EventBus();
  const digits = new DigitCollector(store, events);
  const checkin = new CheckinController(store, events);
  const actTwo = new ActOneBootstrapController(store, events);

  store.setState((state) => ({
    ...state,
    flags: { ...state.flags, codeScattered: true }
  }));
  expect(actTwo.enterRpg("dorm_hub")).toBe(true);
  expect(actTwo.recoverInventory()).toBe(true);
  expect(store.getState()).toMatchObject({
    items: { campusCard: true },
    actOne: { phase: "prologue", inventoryRecovered: true }
  });
  digits.collectDigit(1, "0", "campus_card");
  digits.collectDigit(2, "7", "tiyi");
  digits.collectDigit(3, "9", "phone_home");
  digits.collectDigit(4, "8", "bonsai");
  expect(checkin.submit(digits.getCode())).toBe("success");
  expect(actTwo.completeNarratorIntervention()).toBe(true);

  return { store, events, actTwo };
}

function completeMovementPrelude() {
  const subject = completeChapterOne();
  const inventory = new InventoryController(subject.store, subject.events);
  const actTwo = subject.actTwo;

  expect(actTwo.completeFriendExchange()).toBe(true);
  expect(actTwo.confrontSystem()).toBe(true);
  expect(subject.store.getState().actOne.phase).toBe("system_return_required");
  expect(actTwo.startMovementQuest()).toBe(true);
  expect(actTwo.inspectCharacter()).toBe(true);
  expect(actTwo.identifyCharacter(actOneContent.studentName, actOneContent.studentId)).toBe(true);
  expect(actTwo.startExercise()).toBe(true);
  expect(actTwo.collectPushTriangle()).toBe(true);
  expect(actTwo.collectWeatherWater()).toBe(true);
  expect(actTwo.releaseMentorLine()).toBe(true);
  expect(inventory.combine("pushTriangle", "mentorLine")).toBe("rightArrow");
  expect(actTwo.shiftBalance()).toBe(true);
  expect(actTwo.purchaseGamepad()).toBe("purchased");
  expect(actTwo.confirmManualControl()).toBe(true);
  expect(actTwo.leaveDorm()).toBe(true);

  return subject;
}

function completeLibraryChapter(controller: LibraryFinalsController) {
  expect(controller.unlockLibraryRoute()).toBe(true);
  expect(controller.enterLibrary()).toBe(true);
  expect(controller.readEntranceRecord()).toBe(true);
  expect(controller.inspectBackpack()).toBe(true);
  expect(controller.collectOccupancyNote()).toBe(true);
  expect(controller.openInvestigation()).toBe(true);
  expect(controller.searchCatalog("三分钟离座法")).toBe(true);
  expect(controller.selectCatalogResult("three-minute-leave-method")).toBe(true);
  expect(controller.useCallNumberOnShelf()).toBe(true);
  expect(controller.dimPhoto(20)).toBe(true);
  expect(controller.generateItemReport()).toBe(true);
  expect(controller.stampNonPersonProof()).toBe(true);
  expect(controller.useRightArrowOnReceipt()).toBe(true);
  expect(controller.submitAudit({ arrivalMinutes: 7, publicNoticeFloor: 47, proofCount: 3 })).toBe(true);
  evidence.forEach((id) => expect(controller.uploadEvidence(id)).toBe(true));
  bdReplies.forEach((id) => expect(controller.applyBd(id)).toBe(true));
  expect(controller.openRecoveryApplication()).toBe(true);
  recoveryEvidence.forEach((id) => expect(controller.uploadRecoveryEvidence(id)).toBe(true));
  expect(controller.generateEvictionPass()).toBe(true);
  expect(controller.applyPassToBackpack()).toBe(true);
  expect(controller.sitAt022()).toBe(true);
  expect(controller.complete022Dialogue()).toBe(true);
}

describe("formal chapter flows", () => {
  it("completes chapter one check-in and enters the chapter two phone state", () => {
    const { store } = completeChapterOne();

    expect(store.getState()).toMatchObject({
      currentScene: "phone_home",
      digits: { d1: "0", d2: "7", d3: "9", d4: "8" },
      items: { campusCard: true },
      flags: { checkinDone: true },
      actOne: { phase: "friend_message_required", inventoryRecovered: true }
    });
  });

  it("completes movement setup and reaches the library entrance", () => {
    const { store, events } = completeMovementPrelude();
    const library = new LibraryFinalsController(store, events);

    expect(library.unlockLibraryRoute()).toBe(true);
    expect(library.enterLibrary()).toBe(true);
    expect(store.getState()).toMatchObject({
      runtimeMode: "rpg",
      rpgScene: "library_interior",
      rpgCheckpoint: "library_entrance",
      actOne: { phase: "complete", movementEnabled: true },
      ui: { libraryFinalsPhase: "library_entered" }
    });
  });

  it("completes the library chapter and starts the explicitly unlocked third chapter", () => {
    const { store, events } = completeMovementPrelude();
    completeLibraryChapter(new LibraryFinalsController(store, events));
    const bike = new BikeArcadeChapterController(store, events);

    expect(store.getState().ui.libraryFinalsPhase).toBe("friend_contacted");
    expect(store.getState().bikeArcade.unlocked).toBe(true);
    expect(bike.startAttempt()).toBe(true);
  });

  it("retries after a failed bike run and persists the later victory", () => {
    const store = createGameStore();
    store.setState((state) => ({
      ...state,
      bikeArcade: { ...state.bikeArcade, unlocked: true }
    }));
    const events = new EventBus();
    const bike = new BikeArcadeChapterController(store, events);

    expect(bike.startAttempt()).toBe(true);
    expect(bike.recordProgress(420, 0)).toBe(true);
    expect(bike.failAttempt()).toBe(true);
    expect(bike.startAttempt()).toBe(true);
    expect(bike.recordProgress(755, 2)).toBe(true);
    expect(bike.completeAttempt()).toBe(true);

    expect(store.getState().bikeArcade).toEqual({
      unlocked: true,
      completed: true,
      attemptCount: 2,
      bestDistance: 755,
      bestLives: 2
    });
    expect(events.getHistory().filter((event) => event.name === "bike_arcade_lost")).toHaveLength(1);
    expect(events.getHistory().filter((event) => event.name === "bike_arcade_completed")).toHaveLength(1);
  });
});
