import { describe, expect, it } from "vitest";
import { EventBus } from "../core/EventBus";
import { createGameStore, createInitialGameState } from "../core/GameState";
import type {
  GameStore,
  LibraryEvidenceId,
  LibraryFinalsBdReplyId,
  LibraryRecoveryEvidenceId
} from "../core/types";
import { LibraryFinalsController } from "./LibraryFinalsController";

const REQUIRED_EVIDENCE: LibraryEvidenceId[] = [
  "archived_leave_rule",
  "bag_non_person_proof",
  "seat_022_receipt",
  "library_presence_proof"
];

const VALID_BD_REPLIES: LibraryFinalsBdReplyId[] = [
  "reply-seat-ticket",
  "reply-visit-proof",
  "reply-bag-nonperson"
];

const RECOVERY_EVIDENCE: LibraryRecoveryEvidenceId[] = [
  "bag_non_person_proof",
  "seat_022_receipt",
  "library_presence_proof"
];

function createSubject({ movementReady = true }: { movementReady?: boolean } = {}) {
  const initial = createInitialGameState();
  const store = createGameStore({
    ...initial,
    items: { ...initial.items, rightArrow: movementReady },
    actOne: {
      ...initial.actOne,
      phase: movementReady ? "complete" : initial.actOne.phase,
      inventoryRecovered: movementReady,
      rightArrowAssembled: movementReady,
      balanceShifted: movementReady,
      gamepadPurchased: movementReady,
      manualControlTested: movementReady,
      canLeaveDorm: movementReady
    }
  });
  const events = new EventBus();
  return {
    store,
    events,
    controller: new LibraryFinalsController(store, events)
  };
}

function advanceToEvidence(controller: LibraryFinalsController) {
  expect(controller.unlockLibraryRoute()).toBe(true);
  expect(controller.enterLibrary()).toBe(true);
  expect(controller.readEntranceRecord()).toBe(true);
  expect(controller.inspectBackpack()).toBe(true);
  expect(controller.collectOccupancyNote()).toBe(true);
  expect(controller.openInvestigation()).toBe(true);
}

function collectAllEvidence(controller: LibraryFinalsController) {
  expect(controller.searchCatalog(" 三分钟 离座法 ")).toBe(true);
  expect(controller.selectCatalogResult("three-minute-leave-method")).toBe(true);
  expect(controller.useCallNumberOnShelf()).toBe(true);

  expect(controller.dimPhoto(20)).toBe(true);
  expect(controller.generateItemReport()).toBe(true);
  expect(controller.stampNonPersonProof()).toBe(true);

  expect(controller.useRightArrowOnReceipt()).toBe(true);

  expect(controller.setAuditValue("arrivalMinutes", 7)).toBe(true);
  expect(controller.setAuditValue("publicNoticeFloor", 47)).toBe(true);
  expect(controller.setAuditValue("proofCount", 3)).toBe(true);
  expect(controller.submitAudit()).toBe(true);
}

function advanceToTopTen(controller: LibraryFinalsController) {
  advanceToEvidence(controller);
  collectAllEvidence(controller);
  REQUIRED_EVIDENCE.forEach((evidenceId) => {
    expect(controller.uploadEvidence(evidenceId)).toBe(true);
  });
  VALID_BD_REPLIES.forEach((replyId) => {
    expect(controller.applyBd(replyId)).toBe(true);
  });
}

function expectStable(store: GameStore, events: EventBus, action: () => boolean) {
  const state = store.getState();
  const eventCount = events.getHistory().length;
  expect(action()).toBe(false);
  expect(store.getState()).toBe(state);
  expect(events.getHistory()).toHaveLength(eventCount);
}

describe("LibraryFinalsController V2", () => {
  it("completes the authored 16-step 022 backpack flow and unlocks the book hunt", () => {
    const { store, events, controller } = createSubject();

    // 1-6: movement gate, library entry, arrival record, occupied seat, note, investigation.
    advanceToEvidence(controller);
    // 7-10: catalog/shelf, photo/machine, receipt, presence form.
    collectAllEvidence(controller);
    // 11: four independent evidence uploads.
    REQUIRED_EVIDENCE.forEach((evidenceId) => expect(controller.uploadEvidence(evidenceId)).toBe(true));
    // 12: A/C/E bd replies move rank 04 -> 01.
    VALID_BD_REPLIES.forEach((replyId) => expect(controller.applyBd(replyId)).toBe(true));
    // 13-14: recovery application, three materials, PASS generation.
    expect(controller.openRecoveryApplication()).toBe(true);
    RECOVERY_EVIDENCE.forEach((evidenceId) => expect(controller.uploadRecoveryEvidence(evidenceId)).toBe(true));
    expect(controller.generateEvictionPass()).toBe(true);
    // 15: use PASS in the RPG and sit at 022.
    expect(controller.applyPassToBackpack()).toBe(true);
    expect(controller.sitAt022()).toBe(true);
    // 16: finish the abnormal 022 dialogue.
    expect(controller.complete022Dialogue()).toBe(true);

    expect(store.getState()).toMatchObject({
      rpgScene: "library_interior",
      rpgCheckpoint: "library_seat_022",
      items: {
        rightArrow: false,
        archivedLeaveRule: false,
        bagNonPersonProof: false,
        seat022Receipt: false,
        libraryPresenceProof: false,
        seatReleasePass: false
      },
      bikeArcade: { unlocked: true },
      ui: {
        librarySelectedSeat: "022",
        librarySeatReserved: true,
        libraryFinalsPhase: "friend_contacted",
        libraryFinalsPuzzle: {
          cc98UploadedEvidenceIds: REQUIRED_EVIDENCE,
          bdCount: 3,
          appliedBdReplyIds: VALID_BD_REPLIES,
          recoverySubmittedEvidenceIds: RECOVERY_EVIDENCE,
          evictionPassGenerated: true,
          backpackEvicted: true,
          playerSeated: true,
          nextQuestId: "chapter_three_book_hunt"
        }
      }
    });
    expect(events.getHistory()).toContainEqual({
      name: "chapter_three_book_hunt_unlocked",
      payload: { objective: "找到那本借走签到记录的书" }
    });
  });

  it("rejects commands in the wrong order without mutating state or emitting presentation triggers", () => {
    const { store, events, controller } = createSubject({ movementReady: false });

    expectStable(store, events, () => controller.unlockLibraryRoute());
    expectStable(store, events, () => controller.enterLibrary());
    expectStable(store, events, () => controller.inspectBackpack());
    expectStable(store, events, () => controller.collectOccupancyNote());
    expectStable(store, events, () => controller.searchCatalog("三分钟离座法"));
    expectStable(store, events, () => controller.selectCatalogResult("three-minute-leave-method"));
    expectStable(store, events, () => controller.useCallNumberOnShelf());
    expectStable(store, events, () => controller.generateItemReport());
    expectStable(store, events, () => controller.stampNonPersonProof());
    expectStable(store, events, () => controller.useRightArrowOnReceipt());
    expectStable(store, events, () => controller.submitAudit({ arrivalMinutes: 7, publicNoticeFloor: 47, proofCount: 3 }));
    expectStable(store, events, () => controller.uploadEvidence("archived_leave_rule"));
    expectStable(store, events, () => controller.applyBd("reply-seat-ticket"));
    expectStable(store, events, () => controller.openRecoveryApplication());
    expectStable(store, events, () => controller.generateEvictionPass());
    expectStable(store, events, () => controller.applyPassToBackpack());
    expectStable(store, events, () => controller.sitAt022());
    expectStable(store, events, () => controller.complete022Dialogue());
  });

  it("shows four decoy books beside the correct result and only accepts the authored catalog match", () => {
    const { store, events, controller } = createSubject();
    advanceToEvidence(controller);
    expect(controller.searchCatalog("三分钟离座法")).toBe(true);

    const decoys = [
      "three-minute-leave-and-exceptions",
      "three-minute-temporary-leave",
      "three-minute-standing-boundaries",
      "three-minute-empty-seat"
    ];
    decoys.forEach((resultId) => {
      const puzzleBefore = store.getState().ui.libraryFinalsPuzzle;
      expect(controller.selectCatalogResult(resultId)).toBe(false);
      expect(store.getState().ui.libraryFinalsPuzzle).toBe(puzzleBefore);
    });
    expect(store.getState().items.callNumber755).toBe(false);
    expect(events.getHistory().filter((event) => event.name === "library_catalog_distractor_selected"))
      .toEqual(decoys.map((resultId) => ({ name: "library_catalog_distractor_selected", payload: { resultId } })));

    expect(controller.selectCatalogResult("three-minute-leave-method")).toBe(true);
    expect(store.getState().items.callNumber755).toBe(true);
    expect(events.getHistory()).toContainEqual({
      name: "library_catalog_match_found",
      payload: { callNumber: "I247.55 / 755" }
    });
  });

  it("accepts the full punctuated title but keeps a short catalog search outside progression", () => {
    const short = createSubject();
    advanceToEvidence(short.controller);
    expectStable(short.store, short.events, () => short.controller.searchCatalog("三分钟"));

    const full = createSubject();
    advanceToEvidence(full.controller);
    expect(full.controller.searchCatalog("《 三分钟离座法及其例外 》")).toBe(true);
    expect(full.store.getState().ui.libraryFinalsPuzzle.catalogSearchCompleted).toBe(true);
  });

  it("caps optional ac01 reading at five floors and never makes it a progression gate", () => {
    const { store, controller } = createSubject();
    advanceToEvidence(controller);

    [2, 6, 11, 17, 23].forEach((floor) => expect(controller.inspectOptionalAc01(floor)).toBe(true));
    expect(controller.inspectOptionalAc01(23)).toBe(false);
    expect(controller.inspectOptionalAc01(1)).toBe(false);
    expect(controller.inspectOptionalAc01(24)).toBe(false);
    expect(store.getState().ui.libraryFinalsPuzzle.optionalAc01Floors).toEqual([2, 6, 11, 17, 23]);
    expect(controller.searchCatalog("三分钟离座法")).toBe(true);

    const fresh = createSubject();
    advanceToEvidence(fresh.controller);
    expect(fresh.controller.searchCatalog("三分钟离座法")).toBe(true);
    expect(fresh.store.getState().ui.libraryFinalsPuzzle.optionalAc01Floors).toEqual([]);
  });

  it("requires four owned evidence items before the thread enters top-ten rising", () => {
    const { store, controller } = createSubject();
    advanceToEvidence(controller);
    expect(controller.uploadEvidence("archived_leave_rule")).toBe(false);
    collectAllEvidence(controller);

    REQUIRED_EVIDENCE.slice(0, 3).forEach((evidenceId) => {
      expect(controller.uploadEvidence(evidenceId)).toBe(true);
      expect(store.getState().ui.libraryFinalsPhase).toBe("evidence_gathering");
    });
    expect(controller.uploadEvidence(REQUIRED_EVIDENCE[3])).toBe(true);
    expect(store.getState().ui.libraryFinalsPhase).toBe("top_ten_rising");
    expect(controller.uploadEvidence(REQUIRED_EVIDENCE[3])).toBe(false);
  });

  it("accepts only distinct A/C/E replies and advances rank 04 -> 03 -> 02 -> 01", () => {
    const { store, events, controller } = createSubject();
    advanceToEvidence(controller);
    collectAllEvidence(controller);
    REQUIRED_EVIDENCE.forEach((evidenceId) => expect(controller.uploadEvidence(evidenceId)).toBe(true));

    expect(controller.applyBd("reply-seat-ticket")).toBe(true);
    expect(controller.applyBd("reply-seat-ticket")).toBe(false);
    expect(controller.applyBd("reply-no-source" as LibraryFinalsBdReplyId)).toBe(false);
    expect(controller.applyBd("reply-visit-proof")).toBe(true);
    expect(controller.applyBd("reply-bag-nonperson")).toBe(true);

    expect(store.getState().ui.libraryFinalsPhase).toBe("top_ten_reached");
    expect(events.getHistory().filter((event) => ["cc98_bd_applied", "cc98_top_ten_reached"].includes(event.name)))
      .toEqual([
        { name: "cc98_bd_applied", payload: { replyId: "reply-seat-ticket", bdCount: 1, rank: "03" } },
        { name: "cc98_bd_applied", payload: { replyId: "reply-visit-proof", bdCount: 2, rank: "02" } },
        { name: "cc98_top_ten_reached", payload: { replyId: "reply-bag-nonperson", bdCount: 3, rank: "01" } }
      ]);
  });

  it("records failed presence forms, then issues proof only for 7 / 47 / 3", () => {
    const { store, events, controller } = createSubject();
    advanceToEvidence(controller);

    expect(controller.submitAudit({ arrivalMinutes: 7, publicNoticeFloor: 23, proofCount: 3 })).toBe(false);
    expect(store.getState().ui.libraryFinalsPuzzle.auditAttemptCount).toBe(1);
    expect(events.getHistory()).toContainEqual({
      name: "tiyi_presence_audit_rejected",
      payload: { attempt: 1, arrivalMinutes: 7, publicNoticeFloor: 23, proofCount: 3 }
    });

    expect(controller.submitAudit({ arrivalMinutes: 7, publicNoticeFloor: 47, proofCount: 3 })).toBe(true);
    expect(store.getState().items.libraryPresenceProof).toBe(true);
    expect(store.getState().ui.libraryFinalsPuzzle.auditAttemptCount).toBe(2);
  });

  it("requires three recovery materials, consumes PASS on the backpack, and owns seat/dialogue transitions", () => {
    const { store, events, controller } = createSubject();
    advanceToTopTen(controller);
    expect(controller.openRecoveryApplication()).toBe(true);

    expect(controller.uploadRecoveryEvidence("archived_leave_rule" as LibraryRecoveryEvidenceId)).toBe(false);
    RECOVERY_EVIDENCE.slice(0, 2).forEach((evidenceId) => {
      expect(controller.uploadRecoveryEvidence(evidenceId)).toBe(true);
    });
    expect(controller.generateEvictionPass()).toBe(false);
    expect(controller.uploadRecoveryEvidence(RECOVERY_EVIDENCE[2])).toBe(true);
    expect(controller.generateEvictionPass()).toBe(true);
    expect(store.getState().items.seatReleasePass).toBe(true);

    expect(controller.sitAt022()).toBe(false);
    expect(controller.applyPassToBackpack()).toBe(true);
    expect(store.getState().items.seatReleasePass).toBe(false);
    expect(controller.applyPassToBackpack()).toBe(false);
    expect(controller.sitAt022()).toBe(true);
    expect(controller.complete022Dialogue()).toBe(true);
    expect(controller.complete022Dialogue()).toBe(false);
    expect(events.getHistory().filter((event) => event.name === "library_seat_recovered")).toHaveLength(1);
  });

  it("consumes one-use paper clues while retaining recovery proofs until their second submission", () => {
    const { store, controller } = createSubject();
    advanceToEvidence(controller);
    expect(store.getState().items.occupancyNote).toBe(false);

    collectAllEvidence(controller);
    expect(store.getState().items.callNumber755).toBe(false);
    expect(store.getState().items.rightArrow).toBe(false);

    REQUIRED_EVIDENCE.forEach((evidenceId) => expect(controller.uploadEvidence(evidenceId)).toBe(true));
    expect(store.getState().items.archivedLeaveRule).toBe(false);
    expect(store.getState().items.bagNonPersonProof).toBe(true);
    expect(store.getState().items.seat022Receipt).toBe(true);
    expect(store.getState().items.libraryPresenceProof).toBe(true);

    VALID_BD_REPLIES.forEach((replyId) => expect(controller.applyBd(replyId)).toBe(true));
    expect(controller.openRecoveryApplication()).toBe(true);
    RECOVERY_EVIDENCE.forEach((evidenceId) => expect(controller.uploadRecoveryEvidence(evidenceId)).toBe(true));
    expect(store.getState().items.bagNonPersonProof).toBe(false);
    expect(store.getState().items.seat022Receipt).toBe(false);
    expect(store.getState().items.libraryPresenceProof).toBe(false);
  });
});
