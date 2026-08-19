import type { EventBus } from "../core/EventBus";
import type {
  ChapterThreeInterludeDecoyId,
  ChapterThreeInterludeDestinationId,
  ChapterThreeInterludeEvidenceId,
  ChapterThreeInterludePhotoFrameId,
  ChapterThreeInterludeVoiceClipId,
  GameState,
  GameStore
} from "../core/types";

export type ChapterThreeInterludeResult =
  | "accepted"
  | "inactive"
  | "locked"
  | "incorrect"
  | "already_complete";

export type ChapterThreeInterludeDecoyReasonId =
  | "number_not_time"
  | "earlier_independent_event"
  | "frozen_local_clock";

export type ChapterThreeInterludeRouteMessageId =
  | "computer_left_on"
  | "guard_east"
  | "east_closed"
  | "west_cleaner"
  | "withdrawn";

export type ChapterThreeInterludeNetworkRecordId =
  | "record_qizhen_dock"
  | "record_theater_hall"
  | "record_library_south"
  | "record_0755";

const PHOTO_ORDER: readonly ChapterThreeInterludePhotoFrameId[] = [
  "paper_left",
  "paper_middle",
  "paper_right"
];
const VOICE_ORDER: readonly ChapterThreeInterludeVoiceClipId[] = [
  "lake",
  "stone",
  "lobby",
  "broadcast"
];
const EVIDENCE_ORDER: readonly ChapterThreeInterludeEvidenceId[] = [
  "journal_start",
  "photo_direction",
  "network_destination",
  "broadcast_end"
];
const ROUTE_MESSAGE_ORDER: readonly ChapterThreeInterludeRouteMessageId[] = [
  "east_closed",
  "west_cleaner"
];
const DECOY_REASON_BY_ID: Readonly<Record<
  ChapterThreeInterludeDecoyId,
  ChapterThreeInterludeDecoyReasonId
>> = {
  canteen_0755: "number_not_time",
  theater_0832: "earlier_independent_event",
  status_clock_075523: "frozen_local_clock"
};

function sameOrder<T extends string>(actual: readonly T[], expected: readonly T[]): boolean {
  return actual.length === expected.length && actual.every((value, index) => value === expected[index]);
}

function addUnique<T extends string>(values: readonly T[], value: T): T[] {
  return values.includes(value) ? [...values] : [...values, value];
}

function withCollectedEvidence(
  state: GameState,
  evidenceId?: ChapterThreeInterludeEvidenceId
): GameState["chapterThreeInterlude"] {
  const current = state.chapterThreeInterlude;
  const evidenceIds = evidenceId ? addUnique(current.evidenceIds, evidenceId) : [...current.evidenceIds];
  const allEvidenceReady = EVIDENCE_ORDER.every((id) => evidenceIds.includes(id));
  return {
    ...current,
    evidenceIds,
    phase: allEvidenceReady && current.phase !== "destination_verified" && current.phase !== "replay_ready"
      ? "timeline_assembly"
      : current.phase
  };
}

/**
 * 第三章半手机取证控制器。所有页面只提交领域动作，证据、排序和第四章门槛
 * 统一写回 GameState，避免通过页面访问顺序绕过验证。
 */
export class ChapterThreePhoneInterludeController {
  constructor(private readonly store: GameStore, private readonly events: EventBus) {}

  beginRecovery(): ChapterThreeInterludeResult {
    const state = this.store.getState();
    if (state.qizhenLake.phase !== "complete") return "inactive";
    if (state.chapterThreeInterlude.completed) return "already_complete";
    this.store.setState((current) => ({
      ...current,
      runtimeMode: "phone",
      currentScene: "timeline_recovery",
      chapterThreeInterlude: {
        ...current.chapterThreeInterlude,
        phase: current.chapterThreeInterlude.phase === "reboot" || current.chapterThreeInterlude.phase === "inactive"
          ? "journal_closeout"
          : current.chapterThreeInterlude.phase,
        rebootSeen: true,
        recoveryOpened: true
      },
      ui: { ...current.ui, controlCenterOpen: false, inventoryOpen: false, selectedItem: null }
    }));
    this.events.emit("chapter35_recovery_opened");
    return "accepted";
  }

  completeJournalCloseout(
    summaryChoice: NonNullable<GameState["qizhenLake"]["journal"]["summaryChoice"]>
  ): ChapterThreeInterludeResult {
    const state = this.store.getState();
    if (!state.chapterThreeInterlude.recoveryOpened) return "locked";
    if (state.chapterThreeInterlude.evidenceIds.includes("journal_start")) return "already_complete";
    this.store.setState((current) => ({
      ...current,
      qizhenLake: {
        ...current.qizhenLake,
        journal: {
          ...current.qizhenLake.journal,
          status: "archived",
          summaryChoice,
          summaryPublished: true,
          memoryCardUnlocked: true
        }
      },
      chapterThreeInterlude: {
        ...withCollectedEvidence(current, "journal_start"),
        phase: "evidence_collection"
      }
    }));
    this.events.emit("chapter35_evidence_collected", { evidenceId: "journal_start", timeSeconds: 81425 });
    return "accepted";
  }

  submitPhotoSequence(order: readonly ChapterThreeInterludePhotoFrameId[]): ChapterThreeInterludeResult {
    const state = this.store.getState();
    if (!state.chapterThreeInterlude.evidenceIds.includes("journal_start")) return "locked";
    const normalized = [...new Set(order)].filter((id): id is ChapterThreeInterludePhotoFrameId => PHOTO_ORDER.includes(id));
    const solved = sameOrder(normalized, PHOTO_ORDER);
    this.store.setState((current) => ({
      ...current,
      chapterThreeInterlude: {
        ...withCollectedEvidence(current, solved ? "photo_direction" : undefined),
        photoFrameIds: normalized,
        photoSequenceSolved: solved
      }
    }));
    this.events.emit(solved ? "chapter35_evidence_collected" : "chapter35_sequence_rejected", {
      evidenceId: "photo_direction",
      order: normalized
    });
    return solved ? "accepted" : "incorrect";
  }

  submitVoiceSequence(order: readonly ChapterThreeInterludeVoiceClipId[]): ChapterThreeInterludeResult {
    const state = this.store.getState();
    if (!state.chapterThreeInterlude.evidenceIds.includes("journal_start")) return "locked";
    const normalized = [...new Set(order)].filter((id): id is ChapterThreeInterludeVoiceClipId => VOICE_ORDER.includes(id));
    const solved = sameOrder(normalized, VOICE_ORDER);
    this.store.setState((current) => ({
      ...current,
      chapterThreeInterlude: {
        ...withCollectedEvidence(current, solved ? "broadcast_end" : undefined),
        voiceClipOrder: normalized,
        voiceSequenceSolved: solved
      }
    }));
    this.events.emit(solved ? "chapter35_evidence_collected" : "chapter35_sequence_rejected", {
      evidenceId: "broadcast_end",
      order: normalized
    });
    return solved ? "accepted" : "incorrect";
  }

  saveOfficialNotice(): ChapterThreeInterludeResult {
    return this.recordNetworkFact("officialNoticeSaved", "chapter35_official_notice_saved");
  }

  saveRouteScreenshot(
    messageIds: readonly ChapterThreeInterludeRouteMessageId[]
  ): ChapterThreeInterludeResult {
    const normalized = [...new Set(messageIds)].filter((id): id is ChapterThreeInterludeRouteMessageId =>
      ["computer_left_on", "guard_east", "east_closed", "west_cleaner", "withdrawn"].includes(id)
    );
    const correctPair = normalized.length === ROUTE_MESSAGE_ORDER.length
      && ROUTE_MESSAGE_ORDER.every((id) => normalized.includes(id));
    if (!correctPair) {
      this.events.emit("chapter35_route_selection_rejected", { messageIds: normalized });
      return "incorrect";
    }
    return this.recordNetworkFact("routeScreenshotSaved", "chapter35_route_screenshot_saved");
  }

  readNetworkRecord(recordId: ChapterThreeInterludeNetworkRecordId): ChapterThreeInterludeResult {
    if (recordId !== "record_0755") {
      this.events.emit("chapter35_network_record_rejected", { recordId });
      return "incorrect";
    }
    return this.recordNetworkFact("networkRecordRead", "chapter35_network_record_read");
  }

  rejectDecoy(
    decoyId: ChapterThreeInterludeDecoyId,
    reasonId: ChapterThreeInterludeDecoyReasonId
  ): ChapterThreeInterludeResult {
    const state = this.store.getState();
    if (state.chapterThreeInterlude.evidenceIds.length < EVIDENCE_ORDER.length) return "locked";
    if (DECOY_REASON_BY_ID[decoyId] !== reasonId) {
      this.events.emit("chapter35_decoy_reason_rejected", { decoyId, reasonId });
      return "incorrect";
    }
    this.store.setState((current) => ({
      ...current,
      chapterThreeInterlude: {
        ...current.chapterThreeInterlude,
        rejectedDecoyIds: addUnique(current.chapterThreeInterlude.rejectedDecoyIds, decoyId),
        statusClockMarkedUntrusted: current.chapterThreeInterlude.statusClockMarkedUntrusted
          || decoyId === "status_clock_075523"
      }
    }));
    this.events.emit("chapter35_decoy_rejected", { decoyId });
    return "accepted";
  }

  assembleTimeline(order: readonly ChapterThreeInterludeEvidenceId[]): ChapterThreeInterludeResult {
    const state = this.store.getState();
    const interlude = state.chapterThreeInterlude;
    if (!EVIDENCE_ORDER.every((id) => interlude.evidenceIds.includes(id))) return "locked";
    const normalized = [...new Set(order)].filter((id): id is ChapterThreeInterludeEvidenceId => EVIDENCE_ORDER.includes(id));
    const allDecoysRejected = (["canteen_0755", "theater_0832", "status_clock_075523"] as const)
      .every((id) => interlude.rejectedDecoyIds.includes(id));
    const solved = sameOrder(normalized, EVIDENCE_ORDER) && allDecoysRejected && interlude.statusClockMarkedUntrusted;
    this.store.setState((current) => ({
      ...current,
      chapterThreeInterlude: {
        ...current.chapterThreeInterlude,
        timelineOrder: normalized
      }
    }));
    this.events.emit(solved ? "chapter35_timeline_assembled" : "chapter35_sequence_rejected", {
      evidenceId: "timeline",
      order: normalized,
      decoysReady: allDecoysRejected
    });
    return solved ? "accepted" : "incorrect";
  }

  verifyDestination(
    destinationId: ChapterThreeInterludeDestinationId,
    explanationId: "a" | "b" | "c"
  ): ChapterThreeInterludeResult {
    const state = this.store.getState();
    const interlude = state.chapterThreeInterlude;
    const allEvidenceReady = EVIDENCE_ORDER.every((id) => interlude.evidenceIds.includes(id));
    const allDecoysRejected = (Object.keys(DECOY_REASON_BY_ID) as ChapterThreeInterludeDecoyId[])
      .every((id) => interlude.rejectedDecoyIds.includes(id));
    if (
      !allEvidenceReady
      || !allDecoysRejected
      || !interlude.statusClockMarkedUntrusted
      || !sameOrder(interlude.timelineOrder, EVIDENCE_ORDER)
    ) return "locked";
    if (destinationId !== "duan_yongping_a1" || explanationId !== "c") {
      this.events.emit("chapter35_destination_rejected", { destinationId, explanationId });
      return "incorrect";
    }
    this.store.setState((current) => ({
      ...current,
      chapterThreeInterlude: {
        ...current.chapterThreeInterlude,
        phase: "destination_verified",
        destinationId
      }
    }));
    this.events.emit("chapter35_destination_verified", { destinationId });
    return "accepted";
  }

  startRecoveredReplay(): ChapterThreeInterludeResult {
    const state = this.store.getState();
    if (state.chapterThreeInterlude.destinationId !== "duan_yongping_a1") return "locked";
    if (state.chapterThreeInterlude.completed) return "already_complete";
    this.store.setState((current) => ({
      ...current,
      runtimeMode: "rpg",
      rpgScene: "qizhen_lake",
      rpgCheckpoint: "qizhen_complete",
      currentScene: "phone_home",
      chapterThreeInterlude: {
        ...current.chapterThreeInterlude,
        phase: "replay_ready",
        replayUnlocked: true
      },
      ui: { ...current.ui, controlCenterOpen: false, inventoryOpen: false, selectedItem: null }
    }));
    this.events.emit("chapter35_recovered_replay_requested", {
      destinationId: "duan_yongping_a1"
    });
    return "accepted";
  }

  private recordNetworkFact(
    key: "officialNoticeSaved" | "routeScreenshotSaved" | "networkRecordRead",
    eventName: string
  ): ChapterThreeInterludeResult {
    const state = this.store.getState();
    if (!state.chapterThreeInterlude.evidenceIds.includes("journal_start")) return "locked";
    if (state.chapterThreeInterlude[key]) return "already_complete";
    this.store.setState((current) => {
      const next = { ...current.chapterThreeInterlude, [key]: true };
      const networkReady = next.officialNoticeSaved && next.routeScreenshotSaved && next.networkRecordRead;
      const staged: GameState = { ...current, chapterThreeInterlude: next };
      return {
        ...current,
        chapterThreeInterlude: networkReady
          ? withCollectedEvidence(staged, "network_destination")
          : next
      };
    });
    this.events.emit(eventName);
    if (this.store.getState().chapterThreeInterlude.evidenceIds.includes("network_destination")) {
      this.events.emit("chapter35_evidence_collected", { evidenceId: "network_destination" });
    }
    return "accepted";
  }
}
