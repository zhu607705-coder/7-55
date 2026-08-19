import type { EventBus } from "../core/EventBus";
import type {
  ChapterFourFloorId,
  ChapterFourRealityMode,
  ChapterFourStairRotation,
  GameStore,
  RpgCheckpointId
} from "../core/types";
import {
  CHAPTER_FOUR_ELEVATOR,
  isChapterFourElevatorStartSelectable,
  isChapterFourElevatorTrackAligned
} from "./ChapterFourElevatorModel";
import {
  CHAPTER_FOUR_MAZE_CLUES,
  CHAPTER_FOUR_MAZE_IDS,
  CHAPTER_FOUR_MAZE_TIMES,
  CHAPTER_FOUR_WAYFINDING_ORDER
} from "./ChapterFourMazeProjection";
import { CHAPTER_FOUR_WECHAT_CLUES } from "./ChapterFourWechatModel";
import {
  CHAPTER_FOUR_CC98_CLUES,
  REQUIRED_CHAPTER_FOUR_CC98_FACT_IDS
} from "./ChapterFourCc98Model";
import {
  CHAPTER_FOUR_SETTINGS_CLUES,
  REQUIRED_BACKGROUND_RECORD_IDS
} from "./ChapterFourSettingsModel";

export type ChapterFourActionResult =
  | "accepted"
  | "already_complete"
  | "incorrect"
  | "misaligned"
  | "wrong_mode"
  | "locked"
  | "inactive";

export type ChapterFourMazeRoute = "walk" | "elevator" | "stair";

export interface ChapterFourMazeMoveIntent {
  floor: ChapterFourFloorId;
  roomId: string;
  checkpoint: RpgCheckpointId;
  route: ChapterFourMazeRoute;
}

export type ChapterFourCorridorPartitionId = typeof CHAPTER_FOUR_MAZE_IDS.partitions[number];
export type ChapterFourWayfindingFragmentId = typeof CHAPTER_FOUR_MAZE_IDS.fragments[number];

const THREE_FLOOR_DESTINATIONS = {
  A1: [
    { roomId: "a1_lobby", checkpoint: "c4_a1_lobby" },
    { roomId: "a1_main_elevator", checkpoint: "c4_a1_main_elevator" }
  ],
  A2: [{ roomId: "a2_corridor", checkpoint: "c4_a2_corridor" }],
  A3: [{ roomId: "a3_wayfinding", checkpoint: "c4_a3_wayfinding" }]
} as const satisfies Readonly<Partial<Record<ChapterFourFloorId, readonly {
  roomId: string;
  checkpoint: RpgCheckpointId;
}[]>>>;

export class ChapterFourTemporalMazeController {
  constructor(private readonly store: GameStore, private readonly events: EventBus) {}

  verifyBackgroundActivity(recordIds: readonly string[]): ChapterFourActionResult {
    const chapter = this.store.getState().chapter4;
    if (!chapter.prologueSeen || chapter.phase === "inactive") return "inactive";
    if (chapter.clueIds.includes(CHAPTER_FOUR_SETTINGS_CLUES.backgroundActivityVerified)) {
      return "already_complete";
    }
    if (!sameStringSet(recordIds, REQUIRED_BACKGROUND_RECORD_IDS)) return "incorrect";
    this.appendWechatClue(
      CHAPTER_FOUR_SETTINGS_CLUES.backgroundActivityVerified,
      "chapter4_settings_background_activity_verified"
    );
    return "accepted";
  }

  restoreDesktopLayout(appOrder: readonly string[]): ChapterFourActionResult {
    const chapter = this.store.getState().chapter4;
    if (!chapter.prologueSeen || chapter.phase === "inactive") return "inactive";
    if (chapter.clueIds.includes(CHAPTER_FOUR_SETTINGS_CLUES.desktopLayoutRestored)) {
      return "already_complete";
    }
    const requiredPrefix = ["wechat", "zjuding", "photos", "cc98"];
    if (!requiredPrefix.every((id, index) => appOrder[index] === id)) return "incorrect";
    this.appendWechatClue(
      CHAPTER_FOUR_SETTINGS_CLUES.desktopLayoutRestored,
      "chapter4_settings_desktop_layout_restored"
    );
    return "accepted";
  }

  importCc98StudyIndex(factIds: readonly string[]): ChapterFourActionResult {
    const chapter = this.store.getState().chapter4;
    if (!chapter.prologueSeen || chapter.phase === "inactive") return "inactive";
    if (chapter.clueIds.includes(CHAPTER_FOUR_CC98_CLUES.studyIndexImported)) {
      return "already_complete";
    }
    if (chapter.floor !== "A2" || chapter.phase !== "npc_schedule_route") return "locked";
    if (!sameStringSet(factIds, REQUIRED_CHAPTER_FOUR_CC98_FACT_IDS)) return "incorrect";
    this.appendWechatClue(
      CHAPTER_FOUR_CC98_CLUES.studyIndexImported,
      "chapter4_cc98_study_index_imported"
    );
    return "accepted";
  }

  readWechatOfficialNotice(): ChapterFourActionResult {
    const chapter = this.store.getState().chapter4;
    if (!chapter.prologueSeen || chapter.phase === "inactive") return "inactive";
    if (chapter.clueIds.includes(CHAPTER_FOUR_WECHAT_CLUES.officialNoticeRead)) {
      return "already_complete";
    }
    this.appendWechatClue(
      CHAPTER_FOUR_WECHAT_CLUES.officialNoticeRead,
      "chapter4_wechat_official_notice_read"
    );
    return "accepted";
  }

  archiveWechatElevatorAudio(): ChapterFourActionResult {
    const chapter = this.store.getState().chapter4;
    if (!chapter.prologueSeen || chapter.phase === "inactive") return "inactive";
    if (chapter.clueIds.includes(CHAPTER_FOUR_WECHAT_CLUES.elevatorAudioArchived)) {
      return "already_complete";
    }
    if (!chapter.elevatorHistoryObserved && !chapter.solvedPuzzleIds.includes("elevator_track_sync")) {
      return "locked";
    }
    this.appendWechatClue(
      CHAPTER_FOUR_WECHAT_CLUES.elevatorAudioArchived,
      "chapter4_wechat_elevator_audio_archived"
    );
    return "accepted";
  }

  saveWechatStudentRoute(): ChapterFourActionResult {
    const chapter = this.store.getState().chapter4;
    if (!chapter.prologueSeen || chapter.phase === "inactive") return "inactive";
    if (chapter.clueIds.includes(CHAPTER_FOUR_WECHAT_CLUES.studentRouteSaved)) {
      return "already_complete";
    }
    if (
      !chapter.clueIds.includes(CHAPTER_FOUR_WECHAT_CLUES.officialNoticeRead)
      || !chapter.clueIds.includes(CHAPTER_FOUR_CC98_CLUES.studyIndexImported)
      || chapter.floor !== "A2"
      || chapter.phase !== "npc_schedule_route"
    ) {
      return "locked";
    }
    this.appendWechatClue(
      CHAPTER_FOUR_WECHAT_CLUES.studentRouteSaved,
      "chapter4_wechat_student_route_saved"
    );
    return "accepted";
  }

  archiveWechatWayfindingPhotos(): ChapterFourActionResult {
    const chapter = this.store.getState().chapter4;
    if (!chapter.prologueSeen || chapter.phase === "inactive") return "inactive";
    if (chapter.clueIds.includes(CHAPTER_FOUR_WECHAT_CLUES.wayfindingPhotosArchived)) {
      return "already_complete";
    }
    if (
      !chapter.clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.oldSignageObserved)
      && !chapter.solvedPuzzleIds.includes("wayfinding_fragment_board")
    ) {
      return "locked";
    }
    this.appendWechatClue(
      CHAPTER_FOUR_WECHAT_CLUES.wayfindingPhotosArchived,
      "chapter4_wechat_wayfinding_photos_archived"
    );
    return "accepted";
  }

  compareWechatWayfindingPhotos(): ChapterFourActionResult {
    const chapter = this.store.getState().chapter4;
    if (!chapter.prologueSeen || chapter.phase === "inactive") return "inactive";
    if (chapter.clueIds.includes(CHAPTER_FOUR_WECHAT_CLUES.wayfindingCompared)) {
      return "already_complete";
    }
    if (!chapter.clueIds.includes(CHAPTER_FOUR_WECHAT_CLUES.wayfindingPhotosArchived)) {
      return "locked";
    }
    this.appendWechatClue(
      CHAPTER_FOUR_WECHAT_CLUES.wayfindingCompared,
      "chapter4_wechat_wayfinding_compared"
    );
    return "accepted";
  }

  setMode(mode: ChapterFourRealityMode): ChapterFourActionResult {
    const state = this.store.getState();
    if (!state.chapter4.prologueSeen || state.chapter4.phase === "inactive") return "inactive";
    if (state.chapter4.mode === mode) return "already_complete";
    this.store.setState((current) => ({
      ...current,
      chapter4: { ...current.chapter4, mode }
    }));
    this.events.emit("chapter4_mode_changed", { mode });
    return "accepted";
  }

  observeAirflow(): ChapterFourActionResult {
    const state = this.store.getState();
    if (!state.chapter4.prologueSeen || state.chapter4.phase === "inactive") return "inactive";
    if (state.chapter4.airflowObserved) return "already_complete";
    if (state.chapter4.mode !== "dark") return "wrong_mode";
    if (state.chapter4.phase !== "arrival" && state.chapter4.phase !== "airflow_overlay") return "locked";
    this.store.setState((current) => ({
      ...current,
      chapter4: {
        ...current.chapter4,
        phase: "airflow_overlay",
        airflowObserved: true,
        clueIds: appendUnique(current.chapter4.clueIds, "a1_airflow_trace")
      }
    }));
    this.events.emit("chapter4_airflow_observed");
    return "accepted";
  }

  guidePaperToElevator(): ChapterFourActionResult {
    const state = this.store.getState();
    if (!state.chapter4.prologueSeen || state.chapter4.phase === "inactive") return "inactive";
    if (state.chapter4.paperGuidedToElevator) return "already_complete";
    if (state.chapter4.mode !== "light") return "wrong_mode";
    if (!state.chapter4.airflowObserved || state.chapter4.phase !== "airflow_overlay") return "locked";
    this.store.setState((current) => ({
      ...current,
      rpgCheckpoint: "c4_a1_main_elevator",
      chapter4: {
        ...current.chapter4,
        phase: "elevator_track_sync",
        roomId: "a1_main_elevator",
        paperGuidedToElevator: true,
        solvedPuzzleIds: appendUnique(current.chapter4.solvedPuzzleIds, "airflow_overlay")
      }
    }));
    this.events.emit("chapter4_airflow_completed", { checkpoint: "c4_a1_main_elevator" });
    return "accepted";
  }

  observeElevatorHistory(): ChapterFourActionResult {
    const state = this.store.getState();
    if (!state.chapter4.prologueSeen || state.chapter4.phase === "inactive") return "inactive";
    if (state.chapter4.elevatorHistoryObserved) return "already_complete";
    if (state.chapter4.mode !== "dark") return "wrong_mode";
    if (
      state.chapter4.phase !== "elevator_track_sync"
      || !state.chapter4.paperGuidedToElevator
      || !state.chapter4.clueIds.includes(CHAPTER_FOUR_WECHAT_CLUES.officialNoticeRead)
    ) return "locked";
    this.store.setState((current) => ({
      ...current,
      chapter4: {
        ...current.chapter4,
        elevatorHistoryObserved: true,
        clueIds: appendUnique(current.chapter4.clueIds, "a1_elevator_history_tracks")
      }
    }));
    this.events.emit("chapter4_elevator_history_observed");
    return "accepted";
  }

  startElevatorReplay(startSeconds: number): ChapterFourActionResult {
    const state = this.store.getState();
    if (!state.chapter4.prologueSeen || state.chapter4.phase === "inactive") return "inactive";
    if (state.chapter4.mode !== "light") return "wrong_mode";
    if (
      state.chapter4.phase !== "elevator_track_sync"
      || !state.chapter4.elevatorHistoryObserved
      || !state.chapter4.clueIds.includes(CHAPTER_FOUR_WECHAT_CLUES.elevatorAudioArchived)
    ) return "locked";
    if (!isChapterFourElevatorStartSelectable(startSeconds)) return "locked";
    const aligned = isChapterFourElevatorTrackAligned(startSeconds);
    this.store.setState((current) => ({
      ...current,
      chapter4: {
        ...current.chapter4,
        buildingTimeSeconds: startSeconds,
        elevatorSelectedStartSeconds: startSeconds,
        elevatorTrackAligned: aligned,
        elevatorReplayAttempts: current.chapter4.elevatorReplayAttempts + 1,
        elevatorPlayerBoarded: false
      }
    }));
    if (!aligned) {
      this.events.emit("chapter4_elevator_tracks_misaligned", { startSeconds });
      return "misaligned";
    }
    this.events.emit("chapter4_elevator_replay_started", { startSeconds, entryWindowSeconds: 6 });
    return "accepted";
  }

  boardHistoricalElevator(): ChapterFourActionResult {
    const state = this.store.getState();
    if (!state.chapter4.prologueSeen || state.chapter4.phase === "inactive") return "inactive";
    if (state.chapter4.elevatorPlayerBoarded) return "already_complete";
    if (state.chapter4.mode !== "light") return "wrong_mode";
    if (state.chapter4.phase !== "elevator_track_sync" || !state.chapter4.elevatorTrackAligned) return "locked";
    this.store.setState((current) => ({
      ...current,
      chapter4: { ...current.chapter4, elevatorPlayerBoarded: true }
    }));
    this.events.emit("chapter4_elevator_player_boarded");
    return "accepted";
  }

  markElevatorReplayMissed(): ChapterFourActionResult {
    const state = this.store.getState();
    if (state.chapter4.phase !== "elevator_track_sync" || state.chapter4.elevatorPlayerBoarded) return "locked";
    this.store.setState((current) => ({
      ...current,
      chapter4: { ...current.chapter4, elevatorPlayerBoarded: false }
    }));
    this.events.emit("chapter4_elevator_replay_missed");
    return "accepted";
  }

  completeElevatorRide(): ChapterFourActionResult {
    const state = this.store.getState();
    if (!state.chapter4.prologueSeen || state.chapter4.phase === "inactive") return "inactive";
    if (state.chapter4.phase === "npc_schedule_route" && state.chapter4.floor === "A2") return "already_complete";
    if (state.chapter4.phase !== "elevator_track_sync" || !state.chapter4.elevatorTrackAligned || !state.chapter4.elevatorPlayerBoarded) return "locked";
    this.store.setState((current) => ({
      ...current,
      rpgCheckpoint: "c4_a2_corridor",
      chapter4: {
        ...current.chapter4,
        phase: "npc_schedule_route",
        floor: "A2",
        roomId: "a2_corridor",
        buildingTimeSeconds: CHAPTER_FOUR_ELEVATOR.arrivedAtSeconds,
        solvedPuzzleIds: appendUnique(current.chapter4.solvedPuzzleIds, "elevator_track_sync"),
        clueIds: appendUnique(current.chapter4.clueIds, "A2_ELEVATOR")
      }
    }));
    this.events.emit("chapter4_elevator_ride_completed", { checkpoint: "c4_a2_corridor", floor: "A2" });
    return "accepted";
  }

  moveWithinMaze(intent: ChapterFourMazeMoveIntent): ChapterFourActionResult {
    const state = this.store.getState();
    const chapter = state.chapter4;
    if (!chapter.prologueSeen || chapter.phase === "inactive") return "inactive";
    if (!isThreeFloorDestination(intent)) return "locked";
    if (
      chapter.floor === intent.floor
      && chapter.roomId === intent.roomId
      && state.rpgCheckpoint === intent.checkpoint
    ) {
      return "already_complete";
    }
    if (!isMazeMoveAllowed(chapter, intent)) return "locked";

    const fromFloor = chapter.floor;
    const buildingTimeSeconds = intent.floor === "A3"
      ? Math.max(chapter.buildingTimeSeconds, CHAPTER_FOUR_MAZE_TIMES.thirdFloorHistorySeconds)
      : fromFloor === "A3" && intent.floor === "A2"
        ? Math.max(chapter.buildingTimeSeconds, CHAPTER_FOUR_MAZE_TIMES.secondFloorReturnSeconds)
        : chapter.buildingTimeSeconds;

    this.store.setState((current) => ({
      ...current,
      rpgCheckpoint: intent.checkpoint,
      chapter4: {
        ...current.chapter4,
        building: "A",
        floor: intent.floor,
        roomId: intent.roomId,
        buildingTimeSeconds
      }
    }));
    this.events.emit("chapter4_maze_moved", {
      fromFloor,
      floor: intent.floor,
      roomId: intent.roomId,
      checkpoint: intent.checkpoint,
      route: intent.route
    });
    return "accepted";
  }

  observeNpcSchedule(): ChapterFourActionResult {
    const state = this.store.getState();
    const chapter = state.chapter4;
    if (!chapter.prologueSeen || chapter.phase === "inactive") return "inactive";
    if (
      chapter.clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.scheduleObserved)
      || chapter.solvedPuzzleIds.includes("npc_schedule_route")
    ) {
      return "already_complete";
    }
    if (chapter.mode !== "dark") return "wrong_mode";
    if (
      chapter.floor !== "A2"
      || chapter.phase !== "npc_schedule_route"
      || !chapter.clueIds.includes(CHAPTER_FOUR_WECHAT_CLUES.studentRouteSaved)
    ) return "locked";

    this.store.setState((current) => ({
      ...current,
      chapter4: {
        ...current.chapter4,
        phase: "corridor_bay_reconstruction",
        clueIds: appendUnique(current.chapter4.clueIds, CHAPTER_FOUR_MAZE_CLUES.scheduleObserved),
        solvedPuzzleIds: appendUnique(current.chapter4.solvedPuzzleIds, "npc_schedule_route")
      }
    }));
    this.events.emit("chapter4_npc_schedule_observed", { floor: "A2" });
    return "accepted";
  }

  reconfigureCorridorBay(partitionId: ChapterFourCorridorPartitionId): ChapterFourActionResult {
    const state = this.store.getState();
    const chapter = state.chapter4;
    if (!chapter.prologueSeen || chapter.phase === "inactive") return "inactive";
    if (!(CHAPTER_FOUR_MAZE_IDS.partitions as readonly string[]).includes(partitionId)) return "locked";
    const clueId = partitionId === "a2_partition_west"
      ? CHAPTER_FOUR_MAZE_CLUES.partitionWestReconfigured
      : CHAPTER_FOUR_MAZE_CLUES.partitionEastReconfigured;
    if (chapter.clueIds.includes(clueId) || chapter.solvedPuzzleIds.includes("corridor_bay_reconstruction")) {
      return "already_complete";
    }
    if (chapter.mode !== "light") return "wrong_mode";
    if (
      chapter.floor !== "A2"
      || chapter.phase !== "corridor_bay_reconstruction"
      || !hasObservedNpcSchedule(chapter)
    ) {
      return "locked";
    }

    const clueIds = appendUnique(chapter.clueIds, clueId);
    const completed = hasBothReconfiguredPartitions(clueIds);
    this.store.setState((current) => ({
      ...current,
      chapter4: {
        ...current.chapter4,
        phase: completed ? "wayfinding_fragment_board" : current.chapter4.phase,
        clueIds,
        solvedPuzzleIds: completed
          ? appendUnique(current.chapter4.solvedPuzzleIds, "corridor_bay_reconstruction")
          : [...current.chapter4.solvedPuzzleIds]
      }
    }));
    this.events.emit("chapter4_corridor_partition_reconfigured", { partitionId, completed });
    return "accepted";
  }

  collectWayfindingFragment(fragmentId: ChapterFourWayfindingFragmentId): ChapterFourActionResult {
    const state = this.store.getState();
    const chapter = state.chapter4;
    if (!chapter.prologueSeen || chapter.phase === "inactive") return "inactive";
    if (!(CHAPTER_FOUR_MAZE_IDS.fragments as readonly string[]).includes(fragmentId)) return "locked";
    const clueId = fragmentId === "a2_fragment_west"
      ? CHAPTER_FOUR_MAZE_CLUES.fragmentWestCollected
      : CHAPTER_FOUR_MAZE_CLUES.fragmentEastCollected;
    if (chapter.clueIds.includes(clueId) || chapter.solvedPuzzleIds.includes("wayfinding_fragment_board")) {
      return "already_complete";
    }
    if (chapter.mode !== "light") return "wrong_mode";
    if (
      chapter.floor !== "A2"
      || chapter.phase !== "wayfinding_fragment_board"
      || !chapter.solvedPuzzleIds.includes("corridor_bay_reconstruction")
    ) {
      return "locked";
    }

    const clueIds = appendUnique(chapter.clueIds, clueId);
    this.store.setState((current) => ({
      ...current,
      chapter4: { ...current.chapter4, clueIds }
    }));
    this.events.emit("chapter4_wayfinding_fragment_collected", {
      fragmentId,
      completed: hasBothWayfindingFragments(clueIds)
    });
    return "accepted";
  }

  observeOldSignage(): ChapterFourActionResult {
    const state = this.store.getState();
    const chapter = state.chapter4;
    if (!chapter.prologueSeen || chapter.phase === "inactive") return "inactive";
    if (chapter.clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.oldSignageObserved)) {
      return "already_complete";
    }
    if (chapter.mode !== "dark") return "wrong_mode";
    if (
      chapter.floor !== "A3"
      || chapter.phase !== "wayfinding_fragment_board"
      || !hasBothWayfindingFragments(chapter.clueIds)
    ) {
      return "locked";
    }

    this.store.setState((current) => ({
      ...current,
      chapter4: {
        ...current.chapter4,
        clueIds: appendUnique(
          current.chapter4.clueIds,
          CHAPTER_FOUR_MAZE_CLUES.oldSignageObserved
        )
      }
    }));
    this.events.emit("chapter4_old_signage_observed", { floor: "A3" });
    return "accepted";
  }

  observeBridgeHistory(): ChapterFourActionResult {
    const state = this.store.getState();
    const chapter = state.chapter4;
    if (!chapter.prologueSeen || chapter.phase === "inactive") return "inactive";
    if (chapter.clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.bridgeHistoryObserved)) return "already_complete";
    if (chapter.mode !== "dark") return "wrong_mode";
    if (
      chapter.floor !== "A3"
      || chapter.phase !== "bridge_floor_discrimination"
      || !chapter.solvedPuzzleIds.includes("wayfinding_fragment_board")
    ) {
      return "locked";
    }

    this.store.setState((current) => ({
      ...current,
      chapter4: {
        ...current.chapter4,
        clueIds: appendUnique(current.chapter4.clueIds, CHAPTER_FOUR_MAZE_CLUES.bridgeHistoryObserved)
      }
    }));
    this.events.emit("chapter4_bridge_history_observed", { floor: "A3" });
    return "accepted";
  }

  alignWayfindingBoard(order: readonly string[]): ChapterFourActionResult {
    const state = this.store.getState();
    const chapter = state.chapter4;
    if (!chapter.prologueSeen || chapter.phase === "inactive") return "inactive";
    if (chapter.solvedPuzzleIds.includes("wayfinding_fragment_board")) return "already_complete";
    if (chapter.mode !== "light") return "wrong_mode";
    if (
      chapter.floor !== "A3"
      || chapter.phase !== "wayfinding_fragment_board"
      || !hasBothWayfindingFragments(chapter.clueIds)
      || !chapter.clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.oldSignageObserved)
      || !chapter.clueIds.includes(CHAPTER_FOUR_WECHAT_CLUES.wayfindingCompared)
    ) {
      return "locked";
    }
    if (!arraysEqual(order, CHAPTER_FOUR_WAYFINDING_ORDER)) return "misaligned";

    this.store.setState((current) => ({
      ...current,
      chapter4: {
        ...current.chapter4,
        phase: "bridge_floor_discrimination",
        clueIds: appendUnique(current.chapter4.clueIds, CHAPTER_FOUR_MAZE_CLUES.wayfindingAligned),
        solvedPuzzleIds: appendUnique(current.chapter4.solvedPuzzleIds, "wayfinding_fragment_board")
      }
    }));
    this.events.emit("chapter4_wayfinding_aligned", { floor: "A3" });
    return "accepted";
  }

  openSecondFloorReturnWindow(): ChapterFourActionResult {
    const state = this.store.getState();
    const chapter = state.chapter4;
    if (!chapter.prologueSeen || chapter.phase === "inactive") return "inactive";
    if (
      chapter.clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.secondFloorReturnWindowOpen)
      || chapter.solvedPuzzleIds.includes("bridge_floor_discrimination")
    ) {
      return "already_complete";
    }
    if (chapter.mode !== "light") return "wrong_mode";
    if (
      chapter.floor !== "A2"
      || chapter.phase !== "bridge_floor_discrimination"
      || !chapter.solvedPuzzleIds.includes("wayfinding_fragment_board")
      || !chapter.clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.bridgeHistoryObserved)
    ) {
      return "locked";
    }

    this.store.setState((current) => ({
      ...current,
      chapter4: {
        ...current.chapter4,
        buildingTimeSeconds: Math.max(
          current.chapter4.buildingTimeSeconds,
          CHAPTER_FOUR_MAZE_TIMES.secondFloorReturnSeconds
        ),
        clueIds: appendUnique(
          current.chapter4.clueIds,
          CHAPTER_FOUR_MAZE_CLUES.secondFloorReturnWindowOpen
        ),
        solvedPuzzleIds: appendUnique(current.chapter4.solvedPuzzleIds, "bridge_floor_discrimination")
      }
    }));
    this.events.emit("chapter4_second_floor_return_window_opened", {
      floor: "A2",
      targetId: CHAPTER_FOUR_MAZE_IDS.returnWindowTarget
    });
    return "accepted";
  }

  observeStairEcho(): ChapterFourActionResult {
    const state = this.store.getState();
    if (!state.chapter4.prologueSeen || state.chapter4.phase === "inactive") return "inactive";
    if (state.chapter4.stairEchoObserved) return "already_complete";
    if (state.chapter4.mode !== "dark") return "wrong_mode";
    if (state.chapter4.phase !== "stair_echo_direction") return "locked";
    this.store.setState((current) => ({
      ...current,
      chapter4: {
        ...current.chapter4,
        stairEchoObserved: true,
        clueIds: appendUnique(current.chapter4.clueIds, "b3_stair_lower_echo")
      }
    }));
    this.events.emit("chapter4_stair_echo_observed");
    return "accepted";
  }

  rotateStair(direction: "left" | "right"): ChapterFourActionResult {
    const state = this.store.getState();
    if (!state.chapter4.prologueSeen || state.chapter4.phase === "inactive") return "inactive";
    if (state.chapter4.stairAlignmentSolved) return "already_complete";
    if (state.chapter4.mode !== "light") return "wrong_mode";
    if (state.chapter4.phase !== "stair_echo_direction" || !state.chapter4.stairEchoObserved) return "locked";
    const delta = direction === "left" ? -1 : 1;
    const stairRotationQuarterTurns = ((state.chapter4.stairRotationQuarterTurns + delta + 4) % 4) as ChapterFourStairRotation;
    this.store.setState((current) => ({
      ...current,
      chapter4: { ...current.chapter4, stairRotationQuarterTurns }
    }));
    this.events.emit("chapter4_stair_rotated", { direction, stairRotationQuarterTurns });
    return "accepted";
  }

  traverseAlignedStair(): ChapterFourActionResult {
    const state = this.store.getState();
    if (!state.chapter4.prologueSeen || state.chapter4.phase === "inactive") return "inactive";
    if (state.chapter4.stairAlignmentSolved) return "already_complete";
    if (state.chapter4.mode !== "light") return "wrong_mode";
    if (state.chapter4.phase !== "stair_echo_direction" || !state.chapter4.stairEchoObserved) return "locked";
    if (state.chapter4.stairRotationQuarterTurns !== 1) return "locked";
    this.store.setState((current) => ({
      ...current,
      rpgCheckpoint: "c4_b2_activity",
      chapter4: {
        ...current.chapter4,
        phase: "multicam_video_edit",
        building: "B",
        floor: "B2",
        roomId: "b2_activity",
        stairAlignmentSolved: true,
        solvedPuzzleIds: appendUnique(current.chapter4.solvedPuzzleIds, "stair_echo_direction")
      }
    }));
    this.events.emit("chapter4_stair_alignment_completed", { checkpoint: "c4_b2_activity" });
    return "accepted";
  }

  private appendWechatClue(clueId: string, eventName: string): void {
    this.store.setState((current) => ({
      ...current,
      chapter4: {
        ...current.chapter4,
        clueIds: appendUnique(current.chapter4.clueIds, clueId)
      }
    }));
    this.events.emit(eventName, { clueId });
  }
}

function sameStringSet(actual: readonly string[], required: readonly string[]): boolean {
  if (actual.length !== required.length) return false;
  const actualSet = new Set(actual);
  return required.every((id) => actualSet.has(id));
}

function appendUnique<T>(values: readonly T[], value: T): T[] {
  return values.includes(value) ? [...values] : [...values, value];
}

function isThreeFloorDestination(intent: ChapterFourMazeMoveIntent): boolean {
  if (intent.floor !== "A1" && intent.floor !== "A2" && intent.floor !== "A3") return false;
  return THREE_FLOOR_DESTINATIONS[intent.floor].some((destination) => (
    destination.roomId === intent.roomId && destination.checkpoint === intent.checkpoint
  ));
}

function isMazeMoveAllowed(
  chapter: ReturnType<GameStore["getState"]>["chapter4"],
  intent: ChapterFourMazeMoveIntent
): boolean {
  if (chapter.floor !== "A1" && chapter.floor !== "A2" && chapter.floor !== "A3") return false;
  if (chapter.floor === intent.floor) return intent.route === "walk";
  if (intent.route === "walk") return false;
  if (!chapter.solvedPuzzleIds.includes("elevator_track_sync")) return false;

  const floorNumber = Number(intent.floor.slice(1));
  const currentFloorNumber = Number(chapter.floor.slice(1));
  if (intent.route === "stair" && Math.abs(floorNumber - currentFloorNumber) !== 1) return false;

  const crossesUpperPair = (
    (chapter.floor === "A2" && intent.floor === "A3")
    || (chapter.floor === "A3" && intent.floor === "A2")
  );
  const returnWindowOpen = chapter.clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.secondFloorReturnWindowOpen)
    || chapter.solvedPuzzleIds.includes("bridge_floor_discrimination");
  if (crossesUpperPair && !returnWindowOpen && intent.route !== "stair") return false;
  if (
    intent.floor === "A3"
    && !hasBothWayfindingFragments(chapter.clueIds)
    && !chapter.solvedPuzzleIds.includes("wayfinding_fragment_board")
  ) {
    return false;
  }
  if (
    chapter.floor === "A3"
    && intent.floor === "A2"
    && !chapter.clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.bridgeHistoryObserved)
  ) {
    return false;
  }
  if (
    (chapter.floor === "A1" && intent.floor === "A3")
    || (chapter.floor === "A3" && intent.floor === "A1")
  ) {
    return intent.route === "elevator" && returnWindowOpen;
  }
  return true;
}

function hasObservedNpcSchedule(chapter: ReturnType<GameStore["getState"]>["chapter4"]): boolean {
  return chapter.clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.scheduleObserved)
    || chapter.solvedPuzzleIds.includes("npc_schedule_route");
}

function hasBothReconfiguredPartitions(clueIds: readonly string[]): boolean {
  return clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.partitionWestReconfigured)
    && clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.partitionEastReconfigured);
}

function hasBothWayfindingFragments(clueIds: readonly string[]): boolean {
  return clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.fragmentWestCollected)
    && clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.fragmentEastCollected);
}

function arraysEqual<T>(left: readonly T[], right: readonly T[]): boolean {
  return left.length === right.length && left.every((value, index) => value === right[index]);
}
