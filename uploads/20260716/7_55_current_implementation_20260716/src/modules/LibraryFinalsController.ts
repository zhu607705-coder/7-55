import type { EventBus } from "../core/EventBus";
import type {
  GameStore,
  ItemId,
  LibraryEvidenceId,
  LibraryFinalsAuditValues,
  LibraryFinalsBdReplyId,
  LibraryFinalsPhase,
  LibraryFinalsPuzzleState,
  LibraryLocationId,
  LibraryRecoveryEvidenceId,
  RpgCheckpointId,
  UiState
} from "../core/types";
import {
  hasAllEvidence,
  hasRecoveryEvidence,
  isLibraryEvidenceId,
  isLibraryFinalsBdReplyId,
  isLibraryRecoveryEvidenceId,
  isCatalogClueQuery,
  isPhotoReadable,
  LIBRARY_FINALS_PUZZLE_CONFIG,
  validateAudit
} from "./library-finals/puzzleRules";

const AUDIT_RANGES: Record<keyof LibraryFinalsAuditValues, readonly [number, number]> = {
  arrivalMinutes: [0, 12],
  publicNoticeFloor: [1, 63],
  proofCount: [1, 5]
};

/**
 * 第二章只维护剧情事实与领域事件。动画、旁白、音效和延迟由演出层独立消费事件。
 */
export class LibraryFinalsController {
  constructor(
    private readonly store: GameStore,
    private readonly events: EventBus
  ) {}

  getPhase(): LibraryFinalsPhase {
    return this.store.getState().ui.libraryFinalsPhase;
  }

  getPuzzle(): LibraryFinalsPuzzleState {
    return this.store.getState().ui.libraryFinalsPuzzle;
  }

  unlockLibraryRoute(): boolean {
    const state = this.store.getState();
    if (state.ui.libraryFinalsPhase !== "idle" || !state.actOne.canLeaveDorm) {
      return false;
    }
    this.patchFinals("library_route_unlocked", {});
    this.events.emit("library_route_unlocked", { destination: "foundation_library" });
    return true;
  }

  enterLibrary(): boolean {
    const phase = this.getPhase();
    if (phase !== "library_route_unlocked" && phase !== "library_entered") {
      return false;
    }
    this.patchGame("library_entered", { libraryVisitedPoints: addUnique(this.getPuzzle().libraryVisitedPoints, "entrance") }, {
      runtimeMode: "rpg",
      rpgScene: "library_interior",
      rpgCheckpoint: "library_entrance"
    });
    if (phase !== "library_entered") {
      this.events.emit("library_entered", { seat: LIBRARY_FINALS_PUZZLE_CONFIG.targetSeat });
    }
    return true;
  }

  visitLibraryPoint(point: LibraryLocationId, checkpoint?: RpgCheckpointId): boolean {
    const phase = this.getPhase();
    if (phase === "idle" || phase === "library_route_unlocked" || phase === "friend_contacted") {
      return false;
    }
    const visited = this.getPuzzle().libraryVisitedPoints;
    if (visited.includes(point)) {
      return false;
    }
    this.patchGame(phase, { libraryVisitedPoints: [...visited, point] }, checkpoint ? { rpgCheckpoint: checkpoint } : {});
    this.events.emit("library_location_visited", { point });
    return true;
  }

  readEntranceRecord(): boolean {
    const puzzle = this.getPuzzle();
    if (this.getPhase() !== "library_entered" || puzzle.entranceRecordRead) {
      return false;
    }
    this.patchFinals("library_entered", {
      entranceRecordRead: true,
      clueIds: addUnique(puzzle.clueIds, "arrival_7_minutes")
    });
    this.events.emit("library_entrance_record_read", { arrivalMinutes: 7 });
    return true;
  }

  inspectBackpack(): boolean {
    const phase = this.getPhase();
    const puzzle = this.getPuzzle();
    if ((phase !== "library_entered" && phase !== "occupied_seat_found") || puzzle.backpackInspected) {
      return false;
    }
    this.patchGame("occupied_seat_found", {
      backpackInspected: true,
      libraryVisitedPoints: addUnique(puzzle.libraryVisitedPoints, "seat_022")
    }, { rpgCheckpoint: "library_seat_022" });
    this.events.emit("library_occupied_seat_found", { seat: "022" });
    return true;
  }

  collectOccupancyNote(): boolean {
    const puzzle = this.getPuzzle();
    if (this.getPhase() !== "occupied_seat_found" || !puzzle.backpackInspected || puzzle.occupancyNoteCollected) {
      return false;
    }
    this.patchFinals("evidence_gathering", {
      occupancyNoteCollected: true,
      clueIds: addUnique(puzzle.clueIds, "occupancy_note")
    });
    this.setItem("occupancyNote", false);
    this.setItem("occupancyNote", true);
    this.events.emit("get_item", { itemId: "occupancyNote", sourceScene: "phone_home" });
    this.events.emit("library_occupancy_note_collected", { seat: "022" });
    return true;
  }

  openInvestigation(): boolean {
    const puzzle = this.getPuzzle();
    if (this.getPhase() !== "evidence_gathering" || !puzzle.occupancyNoteCollected || puzzle.investigationOpened) {
      return false;
    }
    this.patchFinals("evidence_gathering", {
      investigationOpened: true,
      clueIds: addUnique(puzzle.clueIds, "public_notice_floor_47")
    });
    this.setItem("occupancyNote", false);
    this.events.emit("use_item", { itemId: "occupancyNote", targetId: "cc98_search" });
    this.events.emit("cc98_occupation_post_opened", { floors: 23, optionalAc01: 5 });
    return true;
  }

  inspectOptionalAc01(floor: number): boolean {
    const puzzle = this.getPuzzle();
    if (
      !puzzle.investigationOpened
      || !Number.isInteger(floor)
      || floor < 1
      || floor > LIBRARY_FINALS_PUZZLE_CONFIG.threadFloorCount
      || puzzle.optionalAc01Floors.includes(floor)
      || puzzle.optionalAc01Floors.length >= LIBRARY_FINALS_PUZZLE_CONFIG.optionalAc01Count
    ) {
      return false;
    }
    this.patchFinals(this.getPhase(), { optionalAc01Floors: [...puzzle.optionalAc01Floors, floor] });
    this.events.emit("cc98_optional_ac01_read", { floor, count: puzzle.optionalAc01Floors.length + 1 });
    return true;
  }

  searchCatalog(query: string): boolean {
    const puzzle = this.getPuzzle();
    if (
      this.getPhase() !== "evidence_gathering"
      || !puzzle.investigationOpened
      || puzzle.catalogSearchCompleted
      || !isCatalogClueQuery(query)
    ) {
      return false;
    }
    this.patchFinals("evidence_gathering", {
      catalogSearchCompleted: true
    });
    this.events.emit("library_catalog_results_shown", { resultCount: 5 });
    return true;
  }

  selectCatalogResult(resultId: string): boolean {
    const puzzle = this.getPuzzle();
    if (this.getPhase() !== "evidence_gathering" || !puzzle.catalogSearchCompleted || puzzle.callNumberCollected) {
      return false;
    }
    if (resultId !== "three-minute-leave-method") {
      this.events.emit("library_catalog_distractor_selected", { resultId });
      return false;
    }
    this.patchFinals("evidence_gathering", {
      callNumberCollected: true,
      clueIds: addUnique(puzzle.clueIds, "call_number_755")
    });
    this.setItem("callNumber755", true);
    this.events.emit("library_catalog_match_found", { callNumber: LIBRARY_FINALS_PUZZLE_CONFIG.callNumber });
    this.events.emit("get_item", { itemId: "callNumber755", sourceScene: "zjuding" });
    return true;
  }

  useCallNumberOnShelf(): boolean {
    const puzzle = this.getPuzzle();
    if (this.getPhase() !== "evidence_gathering" || !puzzle.callNumberCollected || puzzle.archivedRuleCollected) {
      return false;
    }
    this.patchGame("evidence_gathering", {
      archivedRuleCollected: true,
      libraryVisitedPoints: addUnique(puzzle.libraryVisitedPoints, "shelf_755"),
      clueIds: addUnique(puzzle.clueIds, "archived_leave_rule")
    }, { rpgCheckpoint: "library_shelf_755" });
    this.setItem("callNumber755", false);
    this.setItem("archivedLeaveRule", true);
    this.events.emit("use_item", { itemId: "callNumber755", targetId: "library_shelf_755" });
    this.events.emit("get_item", { itemId: "archivedLeaveRule", sourceScene: "phone_home" });
    this.events.emit("library_archived_rule_recovered", { proofCount: 3 });
    return true;
  }

  dimPhoto(brightness: number): boolean {
    const puzzle = this.getPuzzle();
    if (this.getPhase() !== "evidence_gathering" || !puzzle.backpackInspected || puzzle.photoDimmed || !isPhotoReadable(brightness)) {
      return false;
    }
    this.patchFinals("evidence_gathering", { photoDimmed: true });
    this.events.emit("photo_bag_label_revealed", { brightness });
    return true;
  }

  generateItemReport(): boolean {
    const puzzle = this.getPuzzle();
    if (this.getPhase() !== "evidence_gathering" || !puzzle.photoDimmed || puzzle.itemReportGenerated) {
      return false;
    }
    this.patchFinals("evidence_gathering", { itemReportGenerated: true });
    this.setItem("itemRecognitionReport", true);
    this.events.emit("photo_bag_report_generated", { file: "IMG_0755.JPG" });
    this.events.emit("get_item", { itemId: "itemRecognitionReport", sourceScene: "photos" });
    return true;
  }

  stampNonPersonProof(): boolean {
    const puzzle = this.getPuzzle();
    if (this.getPhase() !== "evidence_gathering" || !puzzle.itemReportGenerated || puzzle.nonPersonProofStamped) {
      return false;
    }
    this.patchGame("evidence_gathering", {
      nonPersonProofStamped: true,
      libraryVisitedPoints: addUnique(puzzle.libraryVisitedPoints, "lost_found")
    }, { rpgCheckpoint: "library_front_desk" });
    this.setItem("itemRecognitionReport", false);
    this.setItem("bagNonPersonProof", true);
    this.events.emit("use_item", { itemId: "itemRecognitionReport", targetId: "lost_found_machine" });
    this.events.emit("library_bag_nonperson_proof_issued");
    this.events.emit("get_item", { itemId: "bagNonPersonProof", sourceScene: "phone_home" });
    return true;
  }

  useRightArrowOnReceipt(): boolean {
    const state = this.store.getState();
    const puzzle = this.getPuzzle();
    if (this.getPhase() !== "evidence_gathering" || !state.items.rightArrow || puzzle.seatReceiptCollected) {
      return false;
    }
    this.patchGame("evidence_gathering", {
      seatReceiptCollected: true,
      libraryVisitedPoints: addUnique(puzzle.libraryVisitedPoints, "seat_022")
    }, { rpgCheckpoint: "library_seat_022" });
    this.setItem("rightArrow", false);
    this.setItem("seat022Receipt", true);
    this.events.emit("use_item", { itemId: "rightArrow", targetId: "seat_022_gap" });
    this.events.emit("library_seat_receipt_recovered", { seat: "022" });
    this.events.emit("get_item", { itemId: "seat022Receipt", sourceScene: "phone_home" });
    return true;
  }

  setAuditValue(field: keyof LibraryFinalsAuditValues, value: number): boolean {
    if (this.getPhase() !== "evidence_gathering" || !isAuditValueInRange(field, value)) {
      return false;
    }
    this.patchFinals("evidence_gathering", { [auditPuzzleField(field)]: value });
    this.events.emit("tiyi_audit_value_changed", { field, value });
    return true;
  }

  submitAudit(values?: Readonly<LibraryFinalsAuditValues>): boolean {
    const puzzle = this.getPuzzle();
    if (this.getPhase() !== "evidence_gathering" || puzzle.presenceProofCollected) {
      return false;
    }
    const submitted = values ?? {
      arrivalMinutes: puzzle.auditArrivalMinutes,
      publicNoticeFloor: puzzle.auditPublicNoticeFloor,
      proofCount: puzzle.auditProofCount
    };
    const attempt = puzzle.auditAttemptCount + 1;
    if (!validateAudit(submitted)) {
      this.patchFinals("evidence_gathering", { auditAttemptCount: attempt });
      this.events.emit("tiyi_presence_audit_rejected", { attempt, ...submitted });
      return false;
    }
    this.patchFinals("evidence_gathering", {
      auditAttemptCount: attempt,
      auditArrivalMinutes: submitted.arrivalMinutes,
      auditPublicNoticeFloor: submitted.publicNoticeFloor,
      auditProofCount: submitted.proofCount,
      presenceProofCollected: true
    });
    this.setItem("libraryPresenceProof", true);
    this.events.emit("tiyi_presence_proof_issued", { attempt, ...submitted });
    this.events.emit("get_item", { itemId: "libraryPresenceProof", sourceScene: "tiyi" });
    return true;
  }

  uploadEvidence(evidenceId: LibraryEvidenceId): boolean {
    const puzzle = this.getPuzzle();
    if (
      this.getPhase() !== "evidence_gathering"
      || !isLibraryEvidenceId(evidenceId)
      || !this.hasEvidenceItem(evidenceId)
      || puzzle.cc98UploadedEvidenceIds.includes(evidenceId)
    ) {
      return false;
    }
    const uploaded = [...puzzle.cc98UploadedEvidenceIds, evidenceId];
    this.patchFinals(hasAllEvidence(uploaded) ? "top_ten_rising" : "evidence_gathering", {
      cc98UploadedEvidenceIds: uploaded
    });
    if (evidenceId === "archived_leave_rule") this.setItem("archivedLeaveRule", false);
    this.events.emit("cc98_evidence_uploaded", { evidenceId, uploadedCount: uploaded.length });
    if (hasAllEvidence(uploaded)) {
      this.events.emit("cc98_evidence_set_completed");
    }
    return true;
  }

  applyBd(replyId: LibraryFinalsBdReplyId): boolean {
    const puzzle = this.getPuzzle();
    if (
      this.getPhase() !== "top_ten_rising"
      || !hasAllEvidence(puzzle.cc98UploadedEvidenceIds)
      || !isLibraryFinalsBdReplyId(replyId)
      || puzzle.appliedBdReplyIds.includes(replyId)
      || puzzle.bdCount >= LIBRARY_FINALS_PUZZLE_CONFIG.bdRequired
    ) {
      return false;
    }
    const bdCount = (puzzle.bdCount + 1) as LibraryFinalsPuzzleState["bdCount"];
    const complete = bdCount === LIBRARY_FINALS_PUZZLE_CONFIG.bdRequired;
    this.patchFinals(complete ? "top_ten_reached" : "top_ten_rising", {
      bdCount,
      appliedBdReplyIds: [...puzzle.appliedBdReplyIds, replyId]
    });
    this.events.emit(complete ? "cc98_top_ten_reached" : "cc98_bd_applied", {
      replyId,
      bdCount,
      rank: String(4 - bdCount).padStart(2, "0")
    });
    return true;
  }

  openRecoveryApplication(): boolean {
    if (this.getPhase() !== "top_ten_reached") {
      return false;
    }
    this.patchFinals("recovery_application", {});
    this.events.emit("library_recovery_application_opened", { seat: "022" });
    return true;
  }

  uploadRecoveryEvidence(evidenceId: LibraryRecoveryEvidenceId): boolean {
    const puzzle = this.getPuzzle();
    if (
      this.getPhase() !== "recovery_application"
      || !isLibraryRecoveryEvidenceId(evidenceId)
      || !this.hasEvidenceItem(evidenceId)
      || puzzle.recoverySubmittedEvidenceIds.includes(evidenceId)
    ) {
      return false;
    }
    const submitted = [...puzzle.recoverySubmittedEvidenceIds, evidenceId];
    this.patchFinals("recovery_application", { recoverySubmittedEvidenceIds: submitted });
    const itemByEvidence: Record<LibraryRecoveryEvidenceId, ItemId> = {
      bag_non_person_proof: "bagNonPersonProof",
      seat_022_receipt: "seat022Receipt",
      library_presence_proof: "libraryPresenceProof"
    };
    this.setItem(itemByEvidence[evidenceId], false);
    this.events.emit("library_recovery_evidence_uploaded", { evidenceId, submittedCount: submitted.length });
    return true;
  }

  generateEvictionPass(): boolean {
    const puzzle = this.getPuzzle();
    if (
      this.getPhase() !== "recovery_application"
      || !hasRecoveryEvidence(puzzle.recoverySubmittedEvidenceIds)
      || puzzle.evictionPassGenerated
    ) {
      return false;
    }
    this.patchFinals("pass_ready", { evictionPassGenerated: true });
    this.setItem("seatReleasePass", true);
    this.events.emit("library_seat_release_pass_issued", { seat: "022" });
    this.events.emit("get_item", { itemId: "seatReleasePass", sourceScene: "zjuding" });
    return true;
  }

  applyPassToBackpack(): boolean {
    const puzzle = this.getPuzzle();
    if (this.getPhase() !== "pass_ready" || !puzzle.evictionPassGenerated || !this.store.getState().items.seatReleasePass) {
      return false;
    }
    this.patchGame("backpack_removed", { backpackEvicted: true }, { rpgCheckpoint: "library_seat_022" });
    this.setItem("seatReleasePass", false);
    this.events.emit("use_item", { itemId: "seatReleasePass", targetId: "seat_022_backpack" });
    this.events.emit("library_seat_release_pass_applied", { seat: "022" });
    this.events.emit("library_backpack_evicted", { destination: "lost_found" });
    return true;
  }

  sitAt022(): boolean {
    const puzzle = this.getPuzzle();
    if (this.getPhase() !== "backpack_removed" || !puzzle.backpackEvicted || puzzle.playerSeated) {
      return false;
    }
    this.patchFinals("seat_recovered", { playerSeated: true }, {
      librarySelectedSeat: "022",
      librarySeatReserved: true
    });
    this.events.emit("library_seat_recovered", { seat: "022" });
    return true;
  }

  complete022Dialogue(): boolean {
    const puzzle = this.getPuzzle();
    if (this.getPhase() !== "seat_recovered" || !puzzle.playerSeated || puzzle.nextQuestId !== null) {
      return false;
    }
    this.store.setState((state) => ({
      ...state,
      bikeArcade: { ...state.bikeArcade, unlocked: true },
      ui: {
        ...state.ui,
        libraryFinalsPhase: "friend_contacted",
        libraryFinalsPuzzle: {
          ...state.ui.libraryFinalsPuzzle,
          nextQuestId: "chapter_three_book_hunt",
          clueIds: addUnique(state.ui.libraryFinalsPuzzle.clueIds, "borrowed_attendance_record")
        }
      }
    }));
    this.events.emit("library_friend_contacted", { seat: "022" });
    this.events.emit("chapter_three_book_hunt_unlocked", { objective: "找到那本借走签到记录的书" });
    return true;
  }

  private hasEvidenceItem(evidenceId: LibraryEvidenceId): boolean {
    const itemByEvidence: Record<LibraryEvidenceId, ItemId> = {
      archived_leave_rule: "archivedLeaveRule",
      bag_non_person_proof: "bagNonPersonProof",
      seat_022_receipt: "seat022Receipt",
      library_presence_proof: "libraryPresenceProof"
    };
    return this.store.getState().items[itemByEvidence[evidenceId]];
  }

  private setItem(itemId: ItemId, owned: boolean): void {
    this.store.setState((state) => ({
      ...state,
      items: { ...state.items, [itemId]: owned },
      ui: state.ui.selectedItem === itemId && !owned ? { ...state.ui, selectedItem: null } : state.ui
    }));
  }

  private patchFinals(
    libraryFinalsPhase: LibraryFinalsPhase,
    puzzlePatch: Partial<LibraryFinalsPuzzleState>,
    uiPatch: Partial<UiState> = {}
  ): void {
    this.store.setState((state) => ({
      ...state,
      ui: {
        ...state.ui,
        ...uiPatch,
        libraryFinalsPhase,
        libraryFinalsPuzzle: { ...state.ui.libraryFinalsPuzzle, ...puzzlePatch }
      }
    }));
  }

  private patchGame(
    libraryFinalsPhase: LibraryFinalsPhase,
    puzzlePatch: Partial<LibraryFinalsPuzzleState>,
    gamePatch: Partial<Pick<ReturnType<GameStore["getState"]>, "runtimeMode" | "rpgScene" | "rpgCheckpoint">>
  ): void {
    this.store.setState((state) => ({
      ...state,
      ...gamePatch,
      ui: {
        ...state.ui,
        libraryFinalsPhase,
        libraryFinalsPuzzle: { ...state.ui.libraryFinalsPuzzle, ...puzzlePatch }
      }
    }));
  }
}

function addUnique<T>(values: readonly T[], value: T): T[] {
  return values.includes(value) ? [...values] : [...values, value];
}

function isAuditValueInRange(field: keyof LibraryFinalsAuditValues, value: number): boolean {
  const [min, max] = AUDIT_RANGES[field];
  return Number.isInteger(value) && value >= min && value <= max;
}

function auditPuzzleField(
  field: keyof LibraryFinalsAuditValues
): "auditArrivalMinutes" | "auditPublicNoticeFloor" | "auditProofCount" {
  if (field === "arrivalMinutes") return "auditArrivalMinutes";
  if (field === "publicNoticeFloor") return "auditPublicNoticeFloor";
  return "auditProofCount";
}
