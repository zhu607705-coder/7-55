import { useCallback, useEffect, useMemo, useRef, useState, useSyncExternalStore } from "react";
import Phaser from "phaser";
import type { EventBus } from "../../core/EventBus";
import type { SceneRouter } from "../../core/SceneRouter";
import { selectIdentityReadable } from "../../core/IdentityAccess";
import { selectFeatureAccess } from "../../core/FeatureAccess";
import { selectClockTint } from "../../core/ClockTime";
import type {
  GameState,
  GameStore,
  ItemId,
  ChapterFourRealityMode,
  LibraryLocationId,
  QuestViewModel,
  QizhenFishingSpotId,
  QizhenLakeMode,
  QizhenLakeZone,
  QizhenPaddleDirection,
  QizhenPaddleSide,
  RpgCheckpointId,
  RpgSceneId,
  TheaterMode,
  TheaterProgramId
} from "../../core/types";
import actOneContent from "../../data/act-one-bootstrap.content.json";
import { chapterThreeStoryLineKeyForSubtitle } from "../../data/chapterThreeStory";
import chapterFourContent from "../../data/chapter4-temporal-maze.content.json";
import { ItemInspectDialog } from "../../components/ItemInspectDialog";
import { PixelIcon } from "../../components/PixelIcon";
import { ActOneBootstrapController } from "../../modules/ActOneBootstrapController";
import { LibraryFinalsController } from "../../modules/LibraryFinalsController";
import {
  bindChapterThreeCanteenEvents,
  ChapterThreeCanteenController
} from "../../modules/ChapterThreeCanteenController";
import { ChapterThreeTheaterController } from "../../modules/ChapterThreeTheaterController";
import {
  ChapterThreeQizhenLakeController,
  type QizhenActionResult
} from "../../modules/ChapterThreeQizhenLakeController";
import { ChapterFourPrologueController } from "../../modules/ChapterFourPrologueController";
import {
  ChapterFourTemporalMazeController,
  type ChapterFourActionResult,
  type ChapterFourCorridorPartitionId,
  type ChapterFourMazeMoveIntent,
  type ChapterFourWayfindingFragmentId
} from "../../modules/ChapterFourTemporalMazeController";
import {
  CHAPTER_FOUR_MAZE_CLUES,
  CHAPTER_FOUR_MAZE_IDS,
  selectChapterFourMazeProjection
} from "../../modules/ChapterFourMazeProjection";
import { CHAPTER_FOUR_WECHAT_CLUES } from "../../modules/ChapterFourWechatModel";
import { getDeveloperChapter4PrologueOffset } from "../../modules/DeveloperChannel";
import { exitRpgFullscreen, toggleRpgFullscreen } from "../../modules/RpgFullscreen";
import { BootScene } from "./BootScene";
import { QizhenLoopScene } from "./QizhenLoopScene";
import { DormHubScene } from "./DormHubScene";
import { LibraryInteriorScene } from "./LibraryInteriorScene";
import { CanteenInteriorScene } from "./CanteenInteriorScene";
import { TheaterInteriorScene } from "./TheaterInteriorScene";
import { createTheaterRuntimePort } from "./TheaterRuntimeContract";
import type { TheaterSpotlightAttempt, TheaterSpotlightLane } from "./TheaterSpotlightModel";
import { QizhenLakeScene } from "./QizhenLakeScene";
import type { QizhenFishingAction, QizhenFishingResult } from "./QizhenFishingRhythmModel";
import { CanteenChaseOverlay } from "./CanteenChaseOverlay";
import { Chapter4PrologueOverlay } from "./Chapter4PrologueOverlay";
import { ChapterFourStairAlignmentScene } from "./ChapterFourStairAlignmentScene";
import { ChapterFourTemporalMazeScene } from "./ChapterFourTemporalMazeScene";
import { RpgRealityModeToggle } from "./RpgRealityModeToggle";
import { createRpgBridge } from "./RpgBridge";
import { RPG_CONTROL_HINTS } from "./RpgControlHints";
import { RpgInventoryDock } from "./RpgInventoryDock";
import { QuestTaskBar } from "../../components/QuestClueStrip";
import { RpgSubtitleLayer } from "../../components/RpgSubtitleLayer";
import { RpgClockCrownOverlay } from "../../components/RpgClockCrownOverlay";
import { ElevatorTrackSyncGame } from "../../components/temporal-maze/ElevatorTrackSyncGame";
import { WayfindingBoardGame } from "../../components/temporal-maze/WayfindingBoardGame";
import { useMediaQuery } from "../../components/useMediaQuery";

interface RpgGameHostProps {
  store: GameStore;
  router: SceneRouter;
  events: EventBus;
  inputBlocked?: boolean;
  keyboardBlocked?: boolean;
  embedded?: boolean;
  showTaskBar?: boolean;
  desktopSplit?: boolean;
  onFocusPhone?: () => void;
  onTaskNavigate?: (quest: QuestViewModel) => void;
}

const SCENE_KEYS = {
  campus_bootstrap: "campus-bootstrap",
  campus_qizhen_loop: "campus-qizhen-loop",
  dorm_hub: "dorm-hub",
  library_interior: "library-interior",
  canteen_interior: "canteen-interior",
  theater_interior: "theater-interior",
  qizhen_lake: "qizhen-lake",
  duan_yongping_temporal_maze: "chapter-four-temporal-maze"
} as const;

const SCENE_CLASSES = {
  campus_bootstrap: BootScene,
  campus_qizhen_loop: QizhenLoopScene,
  dorm_hub: DormHubScene,
  library_interior: LibraryInteriorScene,
  canteen_interior: CanteenInteriorScene,
  theater_interior: TheaterInteriorScene,
  qizhen_lake: QizhenLakeScene,
  duan_yongping_temporal_maze: ChapterFourTemporalMazeScene
} as const;

const DOUBLE_TAP_WINDOW_MS = 380;
const MIN_TOUCH_DIRECTION_PULSE_MS = 96;
const KAYAK_PADDLE_SWIPE_THRESHOLD_PX = 18;
const RPG_TOUCH_CONTROLS_QUERY = "(any-pointer: coarse)";
type KayakPaddleSwipePhase = "pending" | QizhenPaddleDirection;
interface KayakPaddleGesture {
  side: QizhenPaddleSide;
  startY: number;
  lastY: number;
  pointerType: string;
}
interface QizhenFishingSessionSnapshot {
  sessionId: string;
  spotId: string;
  chartId: string;
  targetLabel: string;
  totalNotes: number;
  assist: boolean;
}
const QIZHEN_FISHING_SPOT_FEEDBACK: Record<QizhenFishingSpotId, { itemId: ItemId; targetLabel: string }> = {
  locker_key: { itemId: "fishingRod", targetLabel: "倒影对应点一" },
  net_frame: { itemId: "fishingRod", targetLabel: "旧木桩倒影" },
  fish: { itemId: "fishFeedPellets", targetLabel: "鱼群水纹" },
  paper: { itemId: "magneticFishingRod", targetLabel: "纸条本体水纹" }
};
const CHAPTER_FOUR_MAZE_UI_PHASES = new Set<GameState["chapter4"]["phase"]>([
  "arrival",
  "airflow_overlay",
  "elevator_track_sync",
  "npc_schedule_route",
  "corridor_bay_reconstruction",
  "wayfinding_fragment_board",
  "bridge_floor_discrimination"
]);
type ChapterFourMazeActionName =
  | "observe_npc_schedule"
  | "reconfigure_corridor_bay"
  | "collect_wayfinding_fragment"
  | "observe_old_signage"
  | "observe_bridge_history"
  | "align_wayfinding_board"
  | "open_second_floor_return_window";

interface ChapterFourMazeActionRequest {
  requestId: string;
  action: ChapterFourMazeActionName;
  targetId?: string;
  partitionId?: string;
  fragmentId?: string;
  order?: string[];
}

const CHAPTER_FOUR_MAZE_ACTIONS = new Set<ChapterFourMazeActionName>([
  "observe_npc_schedule",
  "reconfigure_corridor_bay",
  "collect_wayfinding_fragment",
  "observe_old_signage",
  "observe_bridge_history",
  "align_wayfinding_board",
  "open_second_floor_return_window"
]);
const LIBRARY_ACTION_CONTRACTS: Record<string, Readonly<{ targetId: string; itemId: ItemId | "" }>> = {
  readEntranceRecord: { targetId: "entrance_record", itemId: "" },
  inspectBackpack: { targetId: "seat_022_backpack", itemId: "" },
  collectOccupancyNote: { targetId: "occupancy_note", itemId: "" },
  unlockCatalogAtTerminal: { targetId: "catalog_terminal", itemId: "" },
  useCallNumberOnShelf: { targetId: "library_shelf_755", itemId: "callNumber755" },
  stampNonPersonProof: { targetId: "front_desk", itemId: "itemRecognitionReport" },
  useRightArrowOnReceipt: { targetId: "seat_022_gap", itemId: "rightArrow" },
  applyPassToBackpack: { targetId: "seat_022_backpack", itemId: "seatReleasePass" },
  sitAt022: { targetId: "seat_022_chair", itemId: "" }
};
const LIBRARY_VISIT_CHECKPOINTS: Record<LibraryLocationId, RpgCheckpointId | ""> = {
  entrance: "library_entrance",
  seat_022: "library_seat_022",
  front_desk: "library_front_desk",
  lost_found: "library_front_desk",
  catalog_terminal: "",
  printer: "",
  shelf_755: "library_shelf_755"
};

function normalizeQizhenFishingSpot(value: unknown): QizhenFishingSpotId {
  const target = String(value ?? "");
  if (target === "locker_key" || target.includes("item_1") || target.includes("locker")) return "locker_key";
  if (target === "net_frame" || target.includes("item_3") || target.includes("net")) return "net_frame";
  if (target === "fish" || target.includes("fish")) return "fish";
  return "paper";
}

function emitQizhenItemFeedback(
  events: EventBus,
  itemId: ItemId,
  result: QizhenActionResult,
  targetLabel: string
): void {
  const detail: Partial<Record<QizhenActionResult, string>> = {
    accepted: `${targetLabel}已完成当前操作。`,
    wrong_mode: "切到浅色操作后再使用道具。",
    wrong_item: `${targetLabel}当前需要其他道具。`,
    unobserved: "先切到深色观察，记录该目标的倒影坐标。",
    direct_paper_failure: "普通鱼钩无法固定纸条。需要完成湖区道具链。",
    already_complete: "这个目标已经完成，请查看当前任务。",
    locked: "当前剧情条件尚未满足。",
    inactive: "该交互点当前未开放。"
  };
  events.emit("rpg_item_use_feedback", {
    itemId,
    reason: result,
    targetLabel,
    detail: detail[result]
  });
}

function isChapterFourMazeAction(value: string): value is ChapterFourMazeActionName {
  return CHAPTER_FOUR_MAZE_ACTIONS.has(value as ChapterFourMazeActionName);
}

function chapterFourMazeActionFeedback(
  action: ChapterFourMazeActionName,
  result: ChapterFourActionResult,
  chapter: GameState["chapter4"]
): string {
  if (result === "inactive") return "第四章教学楼流程尚未开始。";
  if (result === "wrong_mode") {
    return action === "observe_npc_schedule"
      || action === "observe_old_signage"
      || action === "observe_bridge_history"
      ? "切到深色观察后再读取当前历史痕迹。"
      : "切回浅色操作后再执行当前动作。";
  }
  if (result === "misaligned") return chapterFourContent.threeFloorMaze.wayfinding.misaligned;
  if (result === "locked") {
    if (
      action === "observe_npc_schedule"
      && !chapter.clueIds.includes(CHAPTER_FOUR_WECHAT_CLUES.studentRouteSaved)
    ) {
      return "先打开微信，保存麦斯威夜间自习群的路线讨论，再核对二楼人员行程。";
    }
    if (
      action === "align_wayfinding_board"
      && !chapter.clueIds.includes(CHAPTER_FOUR_WECHAT_CLUES.wayfindingCompared)
    ) {
      return "先在微信中归档新旧导视板照片，并请朋友完成对照。";
    }
    if (action === "reconfigure_corridor_bay") return chapterFourContent.threeFloorMaze.corridor.locked;
    if (action === "open_second_floor_return_window") return chapterFourContent.threeFloorMaze.returnWindow.locked;
    return chapterFourContent.threeFloorMaze.movementFeedback.missingEvidence;
  }
  if (result === "already_complete") return "当前证据或操作已经记录。";

  if (action === "observe_npc_schedule") return chapterFourContent.threeFloorMaze.schedule.observed;
  if (action === "reconfigure_corridor_bay") {
    return chapter.solvedPuzzleIds.includes("corridor_bay_reconstruction")
      ? chapterFourContent.threeFloorMaze.corridor.completed
      : "一组可见隔断已经移开，主环路保持开放。";
  }
  if (action === "collect_wayfinding_fragment") {
    const bothCollected = chapter.clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.fragmentWestCollected)
      && chapter.clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.fragmentEastCollected);
    return bothCollected ? "两块导视碎片均已取得。" : "已取得一块导视碎片。";
  }
  if (action === "observe_old_signage") return chapterFourContent.threeFloorMaze.wayfinding.oldSignageObserved;
  if (action === "observe_bridge_history") return chapterFourContent.threeFloorMaze.bridge.observed;
  if (action === "align_wayfinding_board") return chapterFourContent.threeFloorMaze.wayfinding.aligned;
  return chapterFourContent.threeFloorMaze.returnWindow.opened;
}

function setRpgInputEnabled(game: Phaser.Game, enabled: boolean): void {
  game.input.enabled = enabled;
  const scenes = game.scene.getScenes?.(true) ?? [];
  scenes.forEach((scene) => {
    scene.input.enabled = enabled;
    if (scene.input.keyboard) {
      scene.input.keyboard.enabled = enabled;
      scene.input.keyboard.resetKeys();
    }
  });
}

function setRpgKeyboardEnabled(game: Phaser.Game, enabled: boolean): void {
  const scenes = game.scene.getScenes?.(true) ?? [];
  scenes.forEach((scene) => {
    if (scene.input.keyboard) {
      scene.input.keyboard.enabled = enabled;
      scene.input.keyboard.resetKeys();
    }
  });
}

export function RpgGameHost({
  store,
  router,
  events,
  inputBlocked = false,
  keyboardBlocked = false,
  embedded = false,
  showTaskBar = true,
  desktopSplit = false,
  onFocusPhone,
  onTaskNavigate
}: RpgGameHostProps) {
  const [inspectedMapItem, setInspectedMapItem] = useState<ItemId | null>(null);
  const [shellRoot, setShellRoot] = useState<HTMLElement | null>(null);
  const [chapter4ElevatorPanelOpen, setChapter4ElevatorPanelOpen] = useState(false);
  const [chapter4WayfindingPanelOpen, setChapter4WayfindingPanelOpen] = useState(false);
  const [fishingSession, setFishingSession] = useState<QizhenFishingSessionSnapshot | null>(null);
  const shellRef = useRef<HTMLElement | null>(null);
  const hostRef = useRef<HTMLDivElement | null>(null);
  const phaserHostRef = useRef<HTMLDivElement | null>(null);
  const stair3dHostRef = useRef<HTMLDivElement | null>(null);
  const gameRef = useRef<Phaser.Game | null>(null);
  const inputBlockedRef = useRef(inputBlocked);
  const keyboardBlockedRef = useRef(keyboardBlocked);
  const lastMapItemTap = useRef<{ itemId: ItemId; at: number } | null>(null);
  const activeDirectionPointerRef = useRef<{ pointerId: number; startedAt: number } | null>(null);
  const directionStopTimerRef = useRef<number | null>(null);
  const chapter4WayfindingRequestSerialRef = useRef(0);
  const archivedRuleRevealPendingRef = useRef(false);
  const pendingFishingRef = useRef<{ sessionId: string; spotId: QizhenFishingSpotId } | null>(null);
  const itemInspectOpen = inspectedMapItem !== null;
  const state = useSyncExternalStore(store.subscribe, store.getState, store.getState);
  const chaseActive = state.canteenHunt.phase === "chasing";
  // 第四章序幕：启真湖逃脱完成且过场未看时，首次停留在湖区即播放过场。
  const prologueActive = state.rpgScene === "qizhen_lake"
    && state.qizhenLake.phase === "complete"
    && !state.chapter4.prologueSeen;
  const prologueInitialElapsedMs = prologueActive ? getDeveloperChapter4PrologueOffset() : 0;
  const controller = useMemo(() => new ActOneBootstrapController(store, events), [events, store]);
  const libraryController = useMemo(() => new LibraryFinalsController(store, events), [events, store]);
  const canteenController = useMemo(() => new ChapterThreeCanteenController(store, events), [events, store]);
  const theaterController = useMemo(() => new ChapterThreeTheaterController(store, events), [events, store]);
  const qizhenController = useMemo(() => new ChapterThreeQizhenLakeController(store, events), [events, store]);
  const chapter4PrologueController = useMemo(() => new ChapterFourPrologueController(store, events), [events, store]);
  const chapter4Controller = useMemo(() => new ChapterFourTemporalMazeController(store, events), [events, store]);
  const bridge = useMemo(() => createRpgBridge(store, router, events), [events, router, store]);
  const theaterRuntimePort = useMemo(() => createTheaterRuntimePort(bridge), [bridge]);
  const runtimeScene = resolveRuntimeScene(state);
  const kayakPaddleGesturesRef = useRef<Map<number, KayakPaddleGesture>>(new Map());
  const [kayakPaddleSwipeState, setKayakPaddleSwipeState] = useState<Partial<Record<QizhenPaddleSide, KayakPaddleSwipePhase>>>({});
  const chapter4MazeActive = runtimeScene === "duan_yongping_temporal_maze";
  const chapter4Stair3dActive = resolveRuntimeSceneKey(state) === "chapter-four-stair-alignment";
  const chapter4MazeUiActive = chapter4MazeActive
    && state.chapter4.prologueSeen
    && (state.chapter4.floor === "A1" || state.chapter4.floor === "A2" || state.chapter4.floor === "A3")
    && CHAPTER_FOUR_MAZE_UI_PHASES.has(state.chapter4.phase);
  const chapter4InteractionBlocked = chapter4ElevatorPanelOpen || chapter4WayfindingPanelOpen;
  inputBlockedRef.current = inputBlocked || itemInspectOpen || chaseActive || prologueActive || chapter4InteractionBlocked;
  keyboardBlockedRef.current = keyboardBlocked || chaseActive || prologueActive || chapter4InteractionBlocked;

  useEffect(() => {
    if (inspectedMapItem && !state.items[inspectedMapItem]) {
      setInspectedMapItem(null);
    }
  }, [inspectedMapItem, state.items]);
  const coarsePointer = useMediaQuery(RPG_TOUCH_CONTROLS_QUERY);
  const touchControls = coarsePointer
    || (typeof navigator !== "undefined" && navigator.maxTouchPoints > 0);
  // 第四章校时：时间染色层与移动端表冠都由共享 state 直接驱动
  const clockCalibrationAccess = selectFeatureAccess(state).clockCalibration;
  const clockPhaseActive = state.chapter4.phase === "clock_phase_lock";
  const clockTint = clockCalibrationAccess && clockPhaseActive
    ? selectClockTint(state.clockCalibration.displayedSeconds, state.clockCalibration.phase)
    : null;
  const clockCrownVisible = clockCalibrationAccess
    && clockPhaseActive
    && state.clockCalibration.step === "seconds_trim"
    && coarsePointer;
  const bindShellRef = useCallback((node: HTMLElement | null) => {
    shellRef.current = node;
    setShellRoot((current) => current === node ? current : node);
  }, []);
  const selectDraggedRpgItem = useCallback((itemId: ItemId | null) => {
    store.setState((current) => current.ui.selectedItem === itemId
      ? current
      : { ...current, ui: { ...current.ui, selectedItem: itemId } });
  }, [store]);

  const closeChapter4WayfindingPanel = useCallback((reason: "cancelled" | "accepted" | "state_changed") => {
    setChapter4WayfindingPanelOpen(false);
    events.emit("chapter4_wayfinding_panel_closed", { reason });
    window.requestAnimationFrame(() => gameRef.current?.canvas.focus());
  }, [events]);

  const resolveChapterFourMazeAction = useCallback((request: ChapterFourMazeActionRequest): ChapterFourActionResult => {
    const targetId = request.targetId ?? "";
    const partitionId = request.partitionId ?? "";
    const fragmentId = request.fragmentId ?? "";
    let result: ChapterFourActionResult = "locked";

    if (request.action === "observe_npc_schedule" && targetId === CHAPTER_FOUR_MAZE_IDS.scheduleTarget) {
      result = chapter4Controller.observeNpcSchedule();
    } else if (
      request.action === "reconfigure_corridor_bay"
      && (CHAPTER_FOUR_MAZE_IDS.partitions as readonly string[]).includes(partitionId)
      && (!targetId || targetId === partitionId)
    ) {
      result = chapter4Controller.reconfigureCorridorBay(partitionId as ChapterFourCorridorPartitionId);
    } else if (
      request.action === "collect_wayfinding_fragment"
      && (CHAPTER_FOUR_MAZE_IDS.fragments as readonly string[]).includes(fragmentId)
      && (!targetId || targetId === fragmentId)
    ) {
      result = chapter4Controller.collectWayfindingFragment(fragmentId as ChapterFourWayfindingFragmentId);
    } else if (
      request.action === "observe_old_signage"
      && targetId === CHAPTER_FOUR_MAZE_IDS.oldSignageTarget
    ) {
      result = chapter4Controller.observeOldSignage();
    } else if (
      request.action === "observe_bridge_history"
      && targetId === CHAPTER_FOUR_MAZE_IDS.bridgeHistoryTarget
    ) {
      result = chapter4Controller.observeBridgeHistory();
    } else if (
      request.action === "align_wayfinding_board"
      && targetId === CHAPTER_FOUR_MAZE_IDS.wayfindingBoardTarget
      && Array.isArray(request.order)
    ) {
      result = chapter4Controller.alignWayfindingBoard(request.order);
    } else if (
      request.action === "open_second_floor_return_window"
      && targetId === CHAPTER_FOUR_MAZE_IDS.returnWindowTarget
    ) {
      result = chapter4Controller.openSecondFloorReturnWindow();
    }

    const updatedChapter = store.getState().chapter4;
    const projection = selectChapterFourMazeProjection(updatedChapter);
    const feedback = chapterFourMazeActionFeedback(request.action, result, updatedChapter);
    const response: Record<string, unknown> = {
      requestId: request.requestId,
      action: request.action,
      result,
      projection,
      feedback
    };
    if (request.targetId !== undefined) response.targetId = request.targetId;
    if (request.partitionId !== undefined) response.partitionId = request.partitionId;
    if (request.fragmentId !== undefined) response.fragmentId = request.fragmentId;
    if (request.order !== undefined) response.order = [...request.order];
    events.emit("chapter4_maze_action_resolved", response);
    events.emit("rpg_subtitle", {
      text: feedback,
      tone: result === "accepted" ? "success" : "system",
      durationMs: result === "accepted" ? 3600 : 3000
    });
    return result;
  }, [chapter4Controller, events, store]);

  const requestChapter4WayfindingPanel = useCallback((requestId: string, targetId: string) => {
    const chapter = store.getState().chapter4;
    const hasBothFragments = chapter.clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.fragmentWestCollected)
      && chapter.clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.fragmentEastCollected);
    const alreadySolved = chapter.solvedPuzzleIds.includes("wayfinding_fragment_board");
    let result: ChapterFourActionResult = "locked";
    let open = false;

    if (targetId !== CHAPTER_FOUR_MAZE_IDS.wayfindingBoardTarget) {
      result = "locked";
    } else if (alreadySolved) {
      result = "already_complete";
    } else if (chapter.mode !== "light") {
      result = "wrong_mode";
    } else if (
      chapter.floor !== "A3"
      || chapter.phase !== "wayfinding_fragment_board"
      || !hasBothFragments
      || !chapter.clueIds.includes(CHAPTER_FOUR_MAZE_CLUES.oldSignageObserved)
      || !chapter.clueIds.includes(CHAPTER_FOUR_WECHAT_CLUES.wayfindingCompared)
    ) {
      result = "locked";
    } else {
      result = chapter4WayfindingPanelOpen ? "already_complete" : "accepted";
      open = true;
      events.emit("rpg_subtitle_clear");
      setChapter4WayfindingPanelOpen(true);
    }

    const feedback = result === "wrong_mode"
      ? "切回浅色操作后再调整导视板。"
      : result === "locked"
        ? !chapter.clueIds.includes(CHAPTER_FOUR_WECHAT_CLUES.wayfindingCompared)
          ? "先在微信中归档新旧导视板照片，并请朋友完成对照。"
          : chapterFourContent.threeFloorMaze.movementFeedback.missingEvidence
        : result === "already_complete" && !open
          ? "这一段导视记录已经恢复。"
          : chapterFourContent.threeFloorMaze.wayfinding.alignPrompt;
    events.emit("chapter4_wayfinding_panel_resolved", {
      requestId,
      targetId,
      result,
      open,
      projection: selectChapterFourMazeProjection(store.getState().chapter4),
      feedback
    });
    if (!open) {
      events.emit("rpg_subtitle", { text: feedback, tone: "system", durationMs: 3000 });
    }
  }, [chapter4WayfindingPanelOpen, events, store]);

  useEffect(() => {
    if (!chapter4MazeUiActive || state.chapter4.phase !== "elevator_track_sync") {
      setChapter4ElevatorPanelOpen(false);
    }
  }, [chapter4MazeUiActive, state.chapter4.phase]);

  useEffect(() => {
    if (
      chapter4WayfindingPanelOpen
      && (!chapter4MazeUiActive || state.chapter4.floor !== "A3" || state.chapter4.phase !== "wayfinding_fragment_board")
    ) {
      closeChapter4WayfindingPanel("state_changed");
    }
  }, [
    chapter4MazeUiActive,
    chapter4WayfindingPanelOpen,
    closeChapter4WayfindingPanel,
    state.chapter4.floor,
    state.chapter4.phase
  ]);

  useEffect(() => {
    const host = phaserHostRef.current;
    if (!host) {
      return undefined;
    }
    clearRpgCanvasHost(host);
    const initialScene = resolveRuntimeScene(store.getState());
    const sceneClasses = [
      SCENE_CLASSES[initialScene],
      ...Object.entries(SCENE_CLASSES)
        .filter(([sceneId]) => sceneId !== initialScene)
        .map(([, SceneClass]) => SceneClass),
      ChapterFourStairAlignmentScene
    ];
    const game = new Phaser.Game({
      type: Phaser.CANVAS,
      parent: host,
      width: 960,
      height: 540,
      backgroundColor: "#080a0c",
      pixelArt: true,
      roundPixels: true,
      physics: {
        default: "arcade",
        arcade: { debug: false }
      },
      scale: {
        mode: Phaser.Scale.FIT,
        autoCenter: Phaser.Scale.CENTER_BOTH
      },
      scene: sceneClasses,
      callbacks: {
        preBoot: (phaserGame) => {
          phaserGame.registry.set("rpgBridge", bridge);
          phaserGame.registry.set("theaterRuntimePort", theaterRuntimePort);
        },
        postBoot: (phaserGame) => {
          setRpgInputEnabled(phaserGame, !inputBlockedRef.current);
          if (!inputBlockedRef.current) setRpgKeyboardEnabled(phaserGame, !keyboardBlockedRef.current);
          bridge.emit("rpg_runtime_ready");
          const target = resolveRuntimeSceneKey(store.getState());
          activateRpgScene(phaserGame, target);
        }
      }
    });
    gameRef.current = game;
    if (import.meta.env.DEV) {
      const debugRoot = (window as unknown as { __game?: Record<string, unknown> }).__game;
      if (debugRoot) {
        debugRoot.rpg = game;
      }
    }
    return () => {
      if (import.meta.env.DEV) {
        const debugRoot = (window as unknown as { __game?: Record<string, unknown> }).__game;
        if (debugRoot?.rpg === game) {
          delete debugRoot.rpg;
        }
      }
      if (gameRef.current === game) {
        gameRef.current = null;
      }
      game.destroy(true);
      clearRpgCanvasHost(host);
    };
  }, [bridge, store, theaterRuntimePort]);

  useEffect(() => {
    if (!chapter4Stair3dActive) return undefined;
    const host = stair3dHostRef.current;
    if (!host) return undefined;
    const game = gameRef.current;
    if (game) setRpgInputEnabled(game, false);
    let cancelled = false;
    let dispose: (() => void) | undefined;
    void import("../../tools/ChapterFourMonumentStairDemo").then(({ mountChapterFourMonumentStairDemo }) => {
      if (cancelled) return;
      dispose = mountChapterFourMonumentStairDemo(host, {
        subscribeDirection: (listener) => events.subscribe((event) => {
          if (event.name !== "rpg_direction_changed") return;
          const x = event.payload?.x;
          const y = event.payload?.y;
          if (typeof x !== "number" || typeof y !== "number") return;
          if (Math.abs(x) + Math.abs(y) !== 1) return;
          listener({ x, y });
        }),
        onComplete: () => {
          let chapter = store.getState().chapter4;
          if (!chapter.stairEchoObserved) {
            if (chapter.mode !== "dark") chapter4Controller.setMode("dark");
            chapter4Controller.observeStairEcho();
          }
          chapter = store.getState().chapter4;
          if (chapter.mode !== "light") chapter4Controller.setMode("light");
          for (
            let turn = 0;
            turn < 4 && store.getState().chapter4.stairRotationQuarterTurns !== 1;
            turn += 1
          ) {
            chapter4Controller.rotateStair("right");
          }
          const result = chapter4Controller.traverseAlignedStair();
          const completed = result === "accepted" || result === "already_complete";
          events.emit("rpg_subtitle", {
            text: completed
              ? "两处错位楼梯已连通，B2 通路开放。"
              : "楼梯通关状态未能写入，请重新完成当前关卡。",
            tone: completed ? "success" : "system",
            durationMs: 4200
          });
        }
      });
    }).catch((error: unknown) => {
      if (cancelled) return;
      host.textContent = `三维楼梯加载失败：${error instanceof Error ? error.message : String(error)}`;
    });
    return () => {
      cancelled = true;
      dispose?.();
    };
  }, [chapter4Controller, chapter4Stair3dActive, events, store]);

  useEffect(() => {
    const game = gameRef.current;
    if (!game) {
      return undefined;
    }
    if (inputBlocked || itemInspectOpen || chaseActive || chapter4InteractionBlocked || chapter4Stair3dActive) {
      setRpgInputEnabled(game, false);
      events.emit("rpg_direction_changed", { x: 0, y: 0 });
      return undefined;
    }

    setRpgInputEnabled(game, true);
    setRpgKeyboardEnabled(game, !keyboardBlocked);
    if (keyboardBlocked) events.emit("rpg_direction_changed", { x: 0, y: 0 });
    const frame = window.requestAnimationFrame(() => {
      if (gameRef.current) {
        setRpgInputEnabled(gameRef.current, true);
        setRpgKeyboardEnabled(gameRef.current, !keyboardBlocked);
      }
    });
    return () => {
      window.cancelAnimationFrame(frame);
    };
  }, [chapter4InteractionBlocked, chapter4Stair3dActive, chaseActive, events, inputBlocked, itemInspectOpen, keyboardBlocked]);

  useEffect(() => {
    const game = gameRef.current;
    const sceneKey = resolveRuntimeSceneKey(state);
    if (game?.isBooted) {
      activateRpgScene(game, sceneKey);
    }
  }, [runtimeScene, state.rpgCheckpoint]);

  useEffect(() => {
    if (runtimeScene === "library_interior" && state.rpgScene !== runtimeScene) {
      bridge.setRpgLocation(runtimeScene, state.rpgCheckpoint);
    }
  }, [bridge, runtimeScene, state.rpgCheckpoint, state.rpgScene]);

  useEffect(() => {
    if (state.actOne.phase === "system_return_required" && state.items.campusCard) {
      setInspectedMapItem((current) => current ?? "campusCard");
    }
  }, [state.actOne.phase, state.items.campusCard]);

  useEffect(() => {
    if (runtimeScene !== "library_interior") {
      archivedRuleRevealPendingRef.current = false;
      return undefined;
    }
    const puzzle = state.ui.libraryFinalsPuzzle;
    if (
      !puzzle.archivedRuleCollected
      || puzzle.archivedRuleRead
      || !state.items.archivedLeaveRule
      || inspectedMapItem !== null
      || archivedRuleRevealPendingRef.current
    ) {
      return undefined;
    }
    const timer = window.setTimeout(() => {
      const current = store.getState();
      const currentPuzzle = current.ui.libraryFinalsPuzzle;
      if (
        archivedRuleRevealPendingRef.current
        || !currentPuzzle.archivedRuleCollected
        || currentPuzzle.archivedRuleRead
        || !current.items.archivedLeaveRule
      ) {
        return;
      }
      setInspectedMapItem("archivedLeaveRule");
      events.emit("inventory_item_inspected", { itemId: "archivedLeaveRule", surface: "rpg", automatic: true });
    }, 180);
    return () => window.clearTimeout(timer);
  }, [events, inspectedMapItem, runtimeScene, state.items.archivedLeaveRule, state.ui.libraryFinalsPuzzle, store]);

  useEffect(() => {
    return bindChapterThreeCanteenEvents(canteenController, events);
  }, [canteenController, events]);

  useEffect(() => {
    return events.subscribe((event) => {
      if (event.name !== "rpg_subtitle") return;
      const subtitleKey = chapterThreeStoryLineKeyForSubtitle(String(event.payload?.text ?? ""));
      if (!subtitleKey) return;
      events.emit("chapter3_story_line", { subtitleKey });
    });
  }, [events]);

  useEffect(() => {
    return events.subscribe((event) => {
      if (event.name === "chapter4_maze_action_requested") {
        const requestId = String(event.payload?.requestId ?? "");
        const rawAction = String(event.payload?.action ?? "");
        if (!isChapterFourMazeAction(rawAction)) {
          const feedback = "当前教学楼交互请求无效。";
          events.emit("chapter4_maze_action_resolved", {
            requestId,
            action: rawAction,
            targetId: String(event.payload?.targetId ?? ""),
            result: "locked",
            projection: selectChapterFourMazeProjection(store.getState().chapter4),
            feedback
          });
          events.emit("rpg_subtitle", { text: feedback, tone: "system", durationMs: 3000 });
          return;
        }
        const request: ChapterFourMazeActionRequest = { requestId, action: rawAction };
        if (event.payload?.targetId !== undefined) request.targetId = String(event.payload.targetId);
        if (event.payload?.partitionId !== undefined) request.partitionId = String(event.payload.partitionId);
        if (event.payload?.fragmentId !== undefined) request.fragmentId = String(event.payload.fragmentId);
        if (Array.isArray(event.payload?.order)) request.order = event.payload.order.map((entry) => String(entry));
        resolveChapterFourMazeAction(request);
        return;
      }
      if (event.name === "chapter4_wayfinding_panel_requested") {
        requestChapter4WayfindingPanel(
          String(event.payload?.requestId ?? ""),
          String(event.payload?.targetId ?? "")
        );
        return;
      }
      if (event.name === "chapter4_maze_move_requested") {
        const requestId = String(event.payload?.requestId ?? "");
        const requestedFloor = String(event.payload?.floor ?? "");
        const roomId = String(event.payload?.roomId ?? "");
        const checkpoint = String(event.payload?.checkpoint ?? "");
        const requestedRoute = String(event.payload?.route ?? "");
        const intent = (
          (requestedFloor === "A1" || requestedFloor === "A2" || requestedFloor === "A3")
          && (requestedRoute === "walk" || requestedRoute === "elevator" || requestedRoute === "stair")
        )
          ? {
              floor: requestedFloor,
              roomId,
              checkpoint: checkpoint as ChapterFourMazeMoveIntent["checkpoint"],
              route: requestedRoute
            } satisfies ChapterFourMazeMoveIntent
          : null;
        const result = intent ? chapter4Controller.moveWithinMaze(intent) : "locked";
        events.emit("chapter4_maze_move_resolved", {
          requestId,
          result,
          floor: requestedFloor,
          roomId,
          checkpoint,
          route: requestedRoute
        });
        return;
      }
      if (event.name === "rpg_chapter4_mode_requested") {
        chapter4Controller.setMode(String(event.payload?.mode ?? "light") as ChapterFourRealityMode);
        return;
      }
      if (event.name !== "rpg_chapter4_action_requested") return;
      const action = String(event.payload?.action ?? "");
      if (action === "inspect_elevator") {
        const chapter = store.getState().chapter4;
        const result = chapter.elevatorHistoryObserved
          ? "accepted"
          : chapter4Controller.observeElevatorHistory();
        if (result === "accepted" || result === "already_complete") {
          const updatedChapter = store.getState().chapter4;
          if (!updatedChapter.clueIds.includes(CHAPTER_FOUR_WECHAT_CLUES.elevatorAudioArchived)) {
            events.emit("rpg_subtitle", {
              text: "已记录主电梯历史提示音。打开微信的文件传输助手完成归档。",
              tone: "task",
              durationMs: 4200
            });
          } else {
            events.emit("rpg_subtitle_clear");
            setChapter4ElevatorPanelOpen(true);
          }
        } else {
          const text = result === "wrong_mode"
            ? "切到深色观察后再读取轿厢、门体和进入窗口三条历史轨道。"
            : !chapter.clueIds.includes(CHAPTER_FOUR_WECHAT_CLUES.officialNoticeRead)
              ? "先打开微信，查看紫金港楼宇服务公众号发布的夜间运行通知。"
              : "先完成一楼气流路径，再检查主电梯。";
          events.emit("rpg_subtitle", { text, tone: "system", durationMs: 3000 });
        }
        return;
      }
      if (action === "board_elevator") {
        const result = chapter4Controller.boardHistoricalElevator();
        events.emit("rpg_subtitle", {
          text: result === "accepted"
            ? "已进入轿厢。门体开始关闭。"
            : result === "already_complete"
              ? "已经站在轿厢内。"
              : "等待门体完全打开后再进入。",
          tone: result === "accepted" ? "success" : "system",
          durationMs: 2400
        });
        return;
      }
      if (action === "elevator_replay_missed") {
        chapter4Controller.markElevatorReplayMissed();
        events.emit("rpg_subtitle", {
          text: "六秒进入窗口已经结束。到主电梯前再次启动历史重放。",
          tone: "system",
          durationMs: 3000
        });
        return;
      }
      if (action === "complete_elevator_ride") {
        const result = chapter4Controller.completeElevatorRide();
        if (result !== "accepted") {
          events.emit("rpg_subtitle", {
            text: "轿厢历史尚未完整执行。",
            tone: "system",
            durationMs: 2400
          });
        }
        return;
      }
      const result = action === "observe_airflow"
        ? chapter4Controller.observeAirflow()
        : action === "guide_paper"
          ? chapter4Controller.guidePaperToElevator()
          : action === "observe_stair_echo"
            ? chapter4Controller.observeStairEcho()
            : action === "rotate_stair"
              ? chapter4Controller.rotateStair(String(event.payload?.direction) === "left" ? "left" : "right")
              : action === "traverse_stair"
                ? chapter4Controller.traverseAlignedStair()
          : "locked";
      const feedback = action === "observe_airflow"
        ? {
            accepted: "已记录气流轨迹。切回浅色操作，前往麦斯威卷帘门。",
            already_complete: "这条气流轨迹已经记录。",
            wrong_mode: "切到深色观察后再读取断续水迹。",
            misaligned: "当前轨道没有对齐。",
            locked: "当前阶段还不能记录这条轨迹。",
            inactive: "第四章教学楼流程尚未开始。"
          }[result]
        : action === "guide_paper"
          ? {
              accepted: "暖风重新接上水迹，湿纸进入主电梯厅。",
              already_complete: "纸条已经进入主电梯厅。",
              wrong_mode: "切回浅色操作后再调整麦斯威暖风。",
              misaligned: "当前轨道没有对齐。",
              locked: "先在深色观察中记录门厅的完整气流轨迹。",
              inactive: "第四章教学楼流程尚未开始。"
          }[result]
          : action === "observe_stair_echo"
            ? {
                accepted: "已记录下层空调低频。切回浅色操作，旋转折返楼梯。",
                already_complete: "下层回声已经记录。",
                wrong_mode: "切到深色观察后再分辨三处回声。",
                misaligned: "当前轨道没有对齐。",
                locked: "当前阶段还不能记录楼梯回声。",
                inactive: "第四章教学楼流程尚未开始。"
              }[result]
            : action === "rotate_stair"
              ? {
                  accepted: "楼梯转动了九十度。",
                  already_complete: "B2 通路已经接通。",
                  wrong_mode: "切回浅色操作后再转动楼梯。",
                  misaligned: "当前轨道没有对齐。",
                  locked: "先在深色观察中记录下层回声。",
                  inactive: "第四章教学楼流程尚未开始。"
                }[result]
              : action === "traverse_stair"
                ? {
                    accepted: "端点接通，已沿折返楼梯到达 B2。",
                    already_complete: "B2 通路已经接通。",
                    wrong_mode: "切回浅色操作后再通过楼梯。",
                    misaligned: "当前轨道没有对齐。",
                    locked: "两端仍未对齐。继续旋转中央楼梯段。",
                    inactive: "第四章教学楼流程尚未开始。"
                  }[result]
                : "当前交互尚未开放。";
      events.emit("rpg_subtitle", {
        text: feedback,
        tone: result === "accepted" ? "success" : "system",
        durationMs: result === "accepted" ? 4200 : 3000
      });
    });
  }, [
    chapter4Controller,
    events,
    requestChapter4WayfindingPanel,
    resolveChapterFourMazeAction,
    store
  ]);

  // 第四章校时：对齐成功后在 RPG 侧发成功字幕（文案取事件 payload.text）；
  // clock_time_adjusted 无需订阅，染色层由 state.clockCalibration 直接驱动。
  useEffect(() => {
    return events.subscribe((event) => {
      if (event.name !== "clock_calibration_aligned") return;
      const text = String(event.payload?.text ?? "").trim();
      if (!text) return;
      events.emit("rpg_subtitle", { text, tone: "success", durationMs: 4200 });
    });
  }, [events]);

  useEffect(() => {
    return events.subscribe((event) => {
      if (event.name === "library_archived_rule_opened") {
        archivedRuleRevealPendingRef.current = true;
      } else if (event.name === "library_archived_rule_reveal_completed") {
        archivedRuleRevealPendingRef.current = false;
        setInspectedMapItem("archivedLeaveRule");
        events.emit("inventory_item_inspected", { itemId: "archivedLeaveRule", surface: "rpg", automatic: true });
      } else if (event.name === "rpg_campus_card_collected") {
        if (controller.recoverInventory()) {
          setInspectedMapItem("campusCard");
          events.emit("inventory_item_inspected", { itemId: "campusCard", surface: "rpg", automatic: true });
        }
      } else if (event.name === "rpg_character_inspected") {
        controller.inspectCharacter();
      } else if (event.name === "rpg_gamepad_install_requested") {
        const result = controller.useGamepad();
        const feedback = {
          active: "手柄已安装，自动走动已停止。请输入一次方向。",
          identity_required: "他还不知道自己是谁。先用部门黄页完成命名。",
          exercise_required: "他还没有开始课外锻炼。",
          not_owned: "道具栏里没有手柄。",
          inactive: "当前流程还不能安装手柄。"
        }[result];
        events.emit("toast", { text: feedback, tone: result === "active" ? "task" : "system", durationMs: 4200 });
        events.emit("rpg_item_use_feedback", {
          itemId: "gamepad",
          reason: result === "active" ? "accepted" : "locked",
          targetLabel: "角色",
          detail: feedback
        });
      } else if (event.name === "rpg_manual_movement_started") {
        if (!store.getState().actOne.manualControlTested && controller.confirmManualControl()) {
          events.emit("toast", { text: "可以出门了", tone: "task", durationMs: 2800 });
          controller.returnToPhone();
          router.goTo("zjuding");
        }
      } else if (event.name === "rpg_dorm_exit") {
        if (controller.leaveDorm()) {
          controller.enterRpg("campus_bootstrap");
        }
      } else if (event.name === "rpg_library_gate_requested") {
        const phase = libraryController.getPhase();
        if (phase === "idle") {
          libraryController.unlockLibraryRoute();
        }
        if (!libraryController.enterLibrary()) {
          events.emit("library_rpg_interaction_failed", {
            action: "enterLibrary",
            targetId: "foundation_library_gate",
            reason: "unavailable"
          });
        }
      } else if (event.name === "rpg_library_leave_requested") {
        if (!libraryController.leaveLibrary()) {
          events.emit("library_rpg_interaction_failed", {
            action: "leaveLibrary",
            targetId: "library_exit",
            reason: "unavailable"
          });
        }
      } else if (event.name === "rpg_library_action_requested") {
        const action = String(event.payload?.action ?? "");
        const targetId = String(event.payload?.targetId ?? "");
        const itemId = String(event.payload?.itemId ?? "");
        const actionContract = LIBRARY_ACTION_CONTRACTS[action];
        let accepted = false;
        if (action === "visitLibraryPoint") {
          const point = String(event.payload?.point ?? "") as LibraryLocationId;
          const checkpoint = String(event.payload?.checkpoint ?? "");
          const expectedCheckpoint = LIBRARY_VISIT_CHECKPOINTS[point];
          if (targetId || itemId || expectedCheckpoint === undefined || checkpoint !== expectedCheckpoint) {
            events.emit("library_rpg_interaction_failed", {
              action,
              targetId,
              reason: "wrong_target"
            });
            return;
          }
          accepted = libraryController.visitLibraryPoint(point, expectedCheckpoint || undefined);
        } else if (!actionContract || targetId !== actionContract.targetId || itemId !== actionContract.itemId) {
          events.emit("library_rpg_interaction_failed", {
            action,
            targetId,
            reason: actionContract && targetId === actionContract.targetId ? "wrong_item" : "wrong_target"
          });
          return;
        } else if (action === "readEntranceRecord") {
          accepted = libraryController.readEntranceRecord();
        } else if (action === "inspectBackpack") {
          accepted = libraryController.inspectBackpack();
        } else if (action === "collectOccupancyNote") {
          accepted = libraryController.collectOccupancyNote();
        } else if (action === "unlockCatalogAtTerminal") {
          accepted = libraryController.unlockCatalogAtTerminal();
        } else if (action === "useCallNumberOnShelf") {
          accepted = libraryController.useCallNumberOnShelf();
        } else if (action === "stampNonPersonProof") {
          accepted = libraryController.beginNonPersonScan();
        } else if (action === "useRightArrowOnReceipt") {
          accepted = libraryController.useRightArrowOnReceipt();
        } else if (action === "applyPassToBackpack") {
          accepted = libraryController.applyPassToBackpack();
        } else if (action === "sitAt022") {
          accepted = libraryController.sitAt022();
        }
        if (accepted) {
          events.emit("rpg_library_action_accepted", { action, targetId });
          if (itemId) {
            events.emit("rpg_item_use_feedback", {
              itemId,
              reason: "accepted",
              targetLabel: LIBRARY_ACTION_CONTRACTS[action]?.targetId ?? targetId
            });
          }
        } else if (action !== "visitLibraryPoint") {
          events.emit("library_rpg_interaction_failed", { action, targetId, reason: "unavailable" });
          if (itemId) {
            events.emit("rpg_item_use_feedback", {
              itemId,
              reason: "locked",
              targetLabel: targetId
            });
          }
        }
      }
    });
  }, [controller, events, libraryController]);

  useEffect(() => {
    return events.subscribe((event) => {
      if (event.name === "theater_interior_opened") {
        theaterController.recoverTicketCombination();
      } else if (event.name === "rpg_canteen_bike_inspect_requested") {
        canteenController.inspectBikeLock();
      } else if (event.name === "rpg_canteen_bike_tissue_requested") {
        const result = canteenController.cleanBikeLock();
        events.emit("rpg_item_use_feedback", {
          itemId: "greaseTissue",
          reason: result === "cleaned" ? "accepted" : "locked",
          targetLabel: "共享单车车锁",
          detail: result === "rule" ? "先在深色模式读取二维码，再切回浅色模式清洁车锁。" : undefined
        });
      } else if (event.name === "rpg_canteen_bike_requested") {
        const result = canteenController.payForBike();
        events.emit("rpg_item_use_feedback", {
          itemId: "cafeteriaWages",
          reason: result === "paid" ? "accepted" : "locked",
          targetLabel: "共享单车",
          detail: result === "rule" ? "先读取二维码并清洁车锁，再在浅色模式付款。" : undefined
        });
      } else if (event.name === "rpg_theater_entry_requested") {
        theaterController.enterTheater();
      } else if (event.name === "rpg_theater_mode_requested") {
        theaterController.setMode(String(event.payload?.mode ?? "light") as TheaterMode);
      } else if (event.name === "rpg_theater_poster_tissue_requested") {
        const accepted = theaterController.cleanPoster();
        events.emit("rpg_item_use_feedback", {
          itemId: "greaseTissue",
          reason: accepted ? "accepted" : "locked",
          targetLabel: "入口海报"
        });
      } else if (event.name === "rpg_theater_ticket_kiosk_requested") {
        theaterController.inspectTicketKiosk();
      } else if (event.name === "rpg_theater_ticket_code_submitted") {
        theaterController.submitTicketCode(String(event.payload?.code ?? ""));
      } else if (event.name === "rpg_theater_ticket_combine_requested") {
        theaterController.combineTicketHalves();
      } else if (event.name === "rpg_theater_admission_requested") {
        const accepted = theaterController.admitWithTicket();
        events.emit("rpg_item_use_feedback", {
          itemId: "temporaryTheaterTicket",
          reason: accepted ? "accepted" : "locked",
          targetLabel: "检票闸机右侧读票器",
          detail: accepted
            ? "验票完成，闸机已经放行；临时观演票会保留。"
            : "当前剧情条件不允许验票，请先完成入口取票流程。"
        });
      } else if (event.name === "rpg_theater_program_collect_requested") {
        theaterController.collectProgram(String(event.payload?.programId ?? "") as TheaterProgramId);
      } else if (event.name === "rpg_theater_program_order_read_requested") {
        theaterController.readProgramOrder();
      } else if (event.name === "rpg_theater_program_panel_requested") {
        // Phaser owns its in-canvas program panel.
      } else if (event.name === "rpg_theater_program_order_set_requested") {
        const order = Array.isArray(event.payload?.order)
          ? event.payload.order.filter((value): value is TheaterProgramId => ["opening", "spotlight", "finale"].includes(String(value)))
          : [];
        theaterController.setProgramOrder(order);
      } else if (event.name === "rpg_theater_program_order_submit_requested") {
        theaterController.submitProgramOrder();
      } else if (event.name === "rpg_theater_prop_inspect_requested") {
        theaterController.inspectPropBox();
      } else if (event.name === "rpg_theater_prop_ticket_requested") {
        const accepted = theaterController.openPropBoxWithTicket();
        events.emit("rpg_item_use_feedback", {
          itemId: "temporaryTheaterTicket",
          reason: accepted ? "accepted" : "locked",
          targetLabel: "道具箱旁票据扫描器",
          detail: accepted
            ? "票据扫描完成，道具箱已经解锁；临时观演票已完成用途并从道具栏移除。"
            : "先在深色模式读取管理员提示，再切回浅色模式扫描票据。"
        });
      } else if (event.name === "rpg_theater_vent_brush_requested") {
        const accepted = theaterController.dustPaperAtVent();
        events.emit("rpg_item_use_feedback", {
          itemId: "fluorescentBrush",
          reason: accepted ? "accepted" : "locked",
          targetLabel: "后台通风口"
        });
      } else if (event.name === "rpg_theater_spotlight_start_requested") {
        const accepted = theaterController.startSpotlightHunt();
        events.emit("rpg_item_use_feedback", {
          itemId: "spotlightRemote",
          reason: accepted ? "accepted" : "locked",
          targetLabel: "灯光控制台"
        });
      } else if (event.name === "rpg_theater_spotlight_attempt") {
        const firstBeamAt = event.payload?.firstBeamAtMs;
        const attempt: TheaterSpotlightAttempt = {
          round: Number(event.payload?.round),
          lane: String(event.payload?.lane ?? "center") as TheaterSpotlightLane,
          maxContinuousLockMs: Number(event.payload?.maxContinuousLockMs),
          beamActivated: event.payload?.beamActivated === true,
          firstBeamAtMs: firstBeamAt === null || firstBeamAt === undefined
            ? null
            : Number(firstBeamAt),
          actionMs: Number(event.payload?.actionMs),
          submittedAtMs: Number(event.payload?.submittedAtMs)
        };
        theaterController.resolveSpotlightAttempt(attempt);
      } else if (event.name === "rpg_theater_spotlight_choice") {
        theaterController.resolveSpotlightChoice(String(event.payload?.lane ?? "center") as TheaterSpotlightLane);
      } else if (event.name === "rpg_theater_spotlight_timeout") {
        theaterController.missSpotlightRound();
      } else if (event.name === "rpg_theater_reversal_complete_requested") {
        theaterController.completeReversal();
      } else if (event.name === "rpg_theater_exit_requested") {
        theaterController.leaveTheater();
      } else if (event.name === "theater_decoy_inspect_requested") {
        setInspectedMapItem("decoyPaper");
        events.emit("inventory_item_inspected", { itemId: "decoyPaper", surface: "rpg", automatic: true });
      } else if (event.name === "rpg_qizhen_location_briefing_seen_requested") {
        qizhenController.acknowledgeLocationBriefing();
      } else if (event.name === "rpg_qizhen_entry_requested") {
        qizhenController.enterLake();
      } else if (event.name === "rpg_qizhen_leave_requested") {
        qizhenController.leaveLake();
      } else if (event.name === "rpg_qizhen_intro_seen_requested") {
        qizhenController.markIntroSeen();
      } else if (event.name === "rpg_qizhen_mode_requested") {
        qizhenController.setMode(String(event.payload?.mode ?? "light") as QizhenLakeMode);
      } else if (event.name === "rpg_qizhen_outfit_requested") {
        const part = String(event.payload?.part ?? "");
        if (part === "kayak" || part === "left_paddle" || part === "right_paddle") {
          qizhenController.collectOutfit(part);
        }
      } else if (event.name === "rpg_qizhen_board_requested") {
        qizhenController.boardKayak();
      } else if (event.name === "rpg_qizhen_paddle_requested") {
        qizhenController.recordPaddleStroke(
          String(event.payload?.side ?? "left") as QizhenPaddleSide,
          (String(event.payload?.direction ?? "forward") === "reverse" ? "reverse" : "forward") as QizhenPaddleDirection
        );
      } else if (event.name === "rpg_qizhen_capsized") {
        qizhenController.recordCapsize(String(event.payload?.reason ?? "balance_limit"));
      } else if (event.name === "rpg_qizhen_zone_requested") {
        qizhenController.enterZone(String(event.payload?.zone ?? "dock") as QizhenLakeZone);
      } else if (event.name === "rpg_qizhen_reflection_observe_requested") {
        qizhenController.observeReflection(String(event.payload?.targetId ?? "qizhen_reflection_probe"));
      } else if (event.name === "rpg_qizhen_rod_requested") {
        const result = qizhenController.findFishingRod();
        emitQizhenItemFeedback(events, "fishingRod", result, "浮排边钓鱼竿");
      } else if (event.name === "rpg_qizhen_bait_requested") {
        const result = qizhenController.attachDecoyBait();
        emitQizhenItemFeedback(events, "decoyPaper", result, "钓鱼竿装饵框");
      } else if (event.name === "rpg_qizhen_fish_requested") {
        const spotId = normalizeQizhenFishingSpot(event.payload?.targetId);
        const fallbackItem: ItemId = spotId === "fish" ? "fishFeedPellets" : spotId === "paper" ? "fishingRod" : "fishingRod";
        const itemId = String(event.payload?.itemId ?? fallbackItem) as ItemId;
        const result = qizhenController.castAt(spotId);
        emitQizhenItemFeedback(events, itemId, result, String(event.payload?.targetLabel ?? "已观察抛竿点"));
      } else if (event.name === "rpg_qizhen_item_use_requested") {
        const itemId = String(event.payload?.itemId ?? "campusCard") as ItemId;
        const targetId = String(event.payload?.targetId ?? "");
        const result = qizhenController.useItemAt(targetId, itemId);
        emitQizhenItemFeedback(events, itemId, result, String(event.payload?.targetLabel ?? "湖区道具点"));
      } else if (event.name === "rpg_qizhen_combine_requested") {
        const rawItems = Array.isArray(event.payload?.itemIds) ? event.payload.itemIds : [];
        const itemIds = rawItems.map((itemId) => String(itemId) as ItemId);
        const result = qizhenController.combineItems(itemIds);
        emitQizhenItemFeedback(events, itemIds[0] ?? "fishingRod", result, "工具装配框");
      } else if (event.name === "combine_item") {
        qizhenController.recordInventoryCombination(String(event.payload?.result ?? "campusCard") as ItemId);
      } else if (event.name === "rpg_qizhen_swan_feed_requested") {
        const itemId = String(event.payload?.itemId ?? "smallCarp") as ItemId;
        const result = qizhenController.feedSwan(itemId);
        emitQizhenItemFeedback(events, itemId, result, "黑天鹅投喂区");
      } else if (event.name === "rpg_qizhen_paper_caught_requested") {
        const itemId = String(event.payload?.rigItemId ?? "magneticFishingRod") as ItemId;
        const result = qizhenController.castAt("paper");
        emitQizhenItemFeedback(events, itemId, result, "纸条本体水纹");
      } else if (event.name === "rpg_qizhen_fishing_attempt_requested") {
        const sessionId = String(event.payload?.sessionId ?? "");
        const spotId = normalizeQizhenFishingSpot(event.payload?.spotId ?? event.payload?.targetId);
        const feedback = QIZHEN_FISHING_SPOT_FEEDBACK[spotId];
        const itemId = String(event.payload?.itemId ?? feedback.itemId) as ItemId;
        const result = qizhenController.precheckCast(spotId);
        if (result === "accepted") {
          pendingFishingRef.current = { sessionId, spotId };
          events.emit("qizhen_fishing_prechecked", { sessionId, spotId, chartId: spotId });
        } else {
          events.emit("qizhen_fishing_precheck_failed", { sessionId, spotId, reason: result });
          emitQizhenItemFeedback(events, itemId, result, feedback.targetLabel);
        }
      } else if (event.name === "rpg_qizhen_fishing_resolve_requested") {
        const sessionId = String(event.payload?.sessionId ?? "");
        const pending = pendingFishingRef.current;
        if (pending && pending.sessionId === sessionId) {
          pendingFishingRef.current = null;
          const spotId = pending.spotId;
          const result = qizhenController.castAt(spotId);
          if (result === "accepted") {
            const fishingResult = event.payload?.result as QizhenFishingResult | undefined;
            events.emit("qizhen_fishing_completed", {
              sessionId,
              spotId,
              grade: fishingResult?.grade ?? "C",
              accuracy: fishingResult?.accuracy ?? 0
            });
          } else {
            events.emit("qizhen_fishing_failed", { sessionId, spotId, reason: result });
            const feedback = QIZHEN_FISHING_SPOT_FEEDBACK[spotId];
            emitQizhenItemFeedback(events, feedback.itemId, result, feedback.targetLabel);
          }
        }
      } else if (event.name === "qizhen_fishing_started") {
        kayakPaddleGesturesRef.current.clear();
        setKayakPaddleSwipeState({});
        setFishingSession({
          sessionId: String(event.payload?.sessionId ?? ""),
          spotId: String(event.payload?.spotId ?? ""),
          chartId: String(event.payload?.chartId ?? ""),
          targetLabel: String(event.payload?.targetLabel ?? ""),
          totalNotes: Number(event.payload?.totalNotes ?? 0),
          assist: event.payload?.assist === true
        });
      } else if (event.name === "qizhen_fishing_completed"
        || event.name === "qizhen_fishing_failed"
        || event.name === "qizhen_fishing_cancelled") {
        const sessionId = String(event.payload?.sessionId ?? "");
        if (pendingFishingRef.current?.sessionId === sessionId) {
          pendingFishingRef.current = null;
        }
        setFishingSession(null);
      } else if (event.name === "rpg_qizhen_chase_progress") {
        qizhenController.recordChaseProgress(Number(event.payload?.distance ?? 0));
      } else if (event.name === "rpg_qizhen_chase_failed") {
        qizhenController.recordChaseFailure(String(event.payload?.reason ?? "swan_caught"));
      } else if (event.name === "rpg_qizhen_escape_completed_requested") {
        qizhenController.completeEscape();
      }
    });
  }, [canteenController, events, qizhenController, store, theaterController]);

  useEffect(() => {
    if (state.ui.libraryFinalsPuzzle.lostFoundStage !== "scanning") {
      return undefined;
    }
    const timer = window.setTimeout(() => libraryController.completeNonPersonScan(), 920);
    return () => window.clearTimeout(timer);
  }, [libraryController, state.ui.libraryFinalsPuzzle.lostFoundStage]);

  useEffect(() => {
    const emitStop = () => {
      events.emit("rpg_direction_changed", { x: 0, y: 0 });
    };

    const clearStopTimer = () => {
      if (directionStopTimerRef.current === null) return;
      window.clearTimeout(directionStopTimerRef.current);
      directionStopTimerRef.current = null;
    };

    const stopDirection = (event: PointerEvent, preserveShortTap: boolean) => {
      const activePointer = activeDirectionPointerRef.current;
      if (!activePointer || activePointer.pointerId !== event.pointerId) return;
      activeDirectionPointerRef.current = null;
      clearStopTimer();
      const elapsed = performance.now() - activePointer.startedAt;
      const remaining = preserveShortTap ? Math.max(0, MIN_TOUCH_DIRECTION_PULSE_MS - elapsed) : 0;
      if (remaining <= 0) {
        emitStop();
        return;
      }
      directionStopTimerRef.current = window.setTimeout(() => {
        directionStopTimerRef.current = null;
        emitStop();
      }, remaining);
    };

    const onPointerUp = (event: PointerEvent) => stopDirection(event, true);
    const onPointerCancel = (event: PointerEvent) => stopDirection(event, false);
    const stopImmediately = () => {
      activeDirectionPointerRef.current = null;
      clearStopTimer();
      emitStop();
    };

    window.addEventListener("pointerup", onPointerUp, true);
    window.addEventListener("pointercancel", onPointerCancel, true);
    window.addEventListener("blur", stopImmediately);
    window.addEventListener("pagehide", stopImmediately);
    return () => {
      window.removeEventListener("pointerup", onPointerUp, true);
      window.removeEventListener("pointercancel", onPointerCancel, true);
      window.removeEventListener("blur", stopImmediately);
      window.removeEventListener("pagehide", stopImmediately);
      stopImmediately();
    };
  }, [events]);

  useEffect(() => {
    const finishGesture = (event: PointerEvent) => completeKayakPaddleGesture(event.pointerId, event.clientY, event.pointerType);
    const cancelGesture = (event: PointerEvent) => cancelKayakPaddleGesture(event.pointerId);
    const cancelAllGestures = () => {
      if (kayakPaddleGesturesRef.current.size === 0) return;
      kayakPaddleGesturesRef.current.clear();
      setKayakPaddleSwipeState({});
    };
    window.addEventListener("pointerup", finishGesture, true);
    window.addEventListener("pointercancel", cancelGesture, true);
    window.addEventListener("blur", cancelAllGestures);
    window.addEventListener("pagehide", cancelAllGestures);
    return () => {
      window.removeEventListener("pointerup", finishGesture, true);
      window.removeEventListener("pointercancel", cancelGesture, true);
      window.removeEventListener("blur", cancelAllGestures);
      window.removeEventListener("pagehide", cancelAllGestures);
      cancelAllGestures();
    };
  }, [events]);

  useEffect(() => {
    if (runtimeScene === "qizhen_lake" && state.qizhenLake.vehicle === "kayak") return;
    kayakPaddleGesturesRef.current.clear();
    setKayakPaddleSwipeState({});
  }, [runtimeScene, state.qizhenLake.vehicle]);

  useEffect(() => {
    const handleFullscreenKey = (event: KeyboardEvent) => {
      if (!inputBlocked && !itemInspectOpen && !keyboardBlocked && !chapter4InteractionBlocked && event.key.toLowerCase() === "f" && !event.metaKey && !event.ctrlKey && !event.altKey) {
        toggleRpgFullscreen();
      }
    };
    window.addEventListener("keydown", handleFullscreenKey);
    return () => window.removeEventListener("keydown", handleFullscreenKey);
  }, [chapter4InteractionBlocked, inputBlocked, itemInspectOpen, keyboardBlocked]);

  function direction(event: React.PointerEvent<HTMLButtonElement>, x: number, y: number) {
    if (directionStopTimerRef.current !== null) {
      window.clearTimeout(directionStopTimerRef.current);
      directionStopTimerRef.current = null;
    }
    activeDirectionPointerRef.current = { pointerId: event.pointerId, startedAt: performance.now() };
    try {
      event.currentTarget.setPointerCapture?.(event.pointerId);
    } catch {
      // Pointer capture is optional in older WebKit and some embedded browsers.
    }
    events.emit("rpg_direction_changed", { x, y });
    event.preventDefault();
  }

  function setKayakPaddlePhase(side: QizhenPaddleSide, phase: KayakPaddleSwipePhase | null) {
    setKayakPaddleSwipeState((current) => {
      if (phase !== null && current[side] === phase) return current;
      if (phase === null && current[side] === undefined) return current;
      const next = { ...current };
      if (phase === null) delete next[side];
      else next[side] = phase;
      return next;
    });
  }

  function resolveKayakPaddleDirection(startY: number, endY: number): QizhenPaddleDirection {
    const deltaY = endY - startY;
    if (Math.abs(deltaY) < KAYAK_PADDLE_SWIPE_THRESHOLD_PX) return "forward";
    return deltaY > 0 ? "reverse" : "forward";
  }

  function startKayakPaddleGesture(side: QizhenPaddleSide, event: React.PointerEvent<HTMLButtonElement>) {
    const sideAlreadyActive = [...kayakPaddleGesturesRef.current.values()].some((gesture) => gesture.side === side);
    if (sideAlreadyActive) {
      event.preventDefault();
      return;
    }
    kayakPaddleGesturesRef.current.set(event.pointerId, {
      side,
      startY: event.clientY,
      lastY: event.clientY,
      pointerType: event.pointerType
    });
    setKayakPaddlePhase(side, "pending");
    try {
      event.currentTarget.setPointerCapture?.(event.pointerId);
    } catch {
      // Pointer capture is optional in older WebKit and some embedded browsers.
    }
    event.preventDefault();
  }

  function updateKayakPaddleGesture(event: React.PointerEvent<HTMLButtonElement>) {
    const gesture = kayakPaddleGesturesRef.current.get(event.pointerId);
    if (!gesture) return;
    gesture.lastY = event.clientY;
    const deltaY = gesture.lastY - gesture.startY;
    setKayakPaddlePhase(
      gesture.side,
      Math.abs(deltaY) < KAYAK_PADDLE_SWIPE_THRESHOLD_PX
        ? "pending"
        : resolveKayakPaddleDirection(gesture.startY, gesture.lastY)
    );
    event.preventDefault();
  }

  function completeKayakPaddleGesture(pointerId: number, clientY: number, pointerType: string) {
    const gesture = kayakPaddleGesturesRef.current.get(pointerId);
    if (!gesture) return;
    kayakPaddleGesturesRef.current.delete(pointerId);
    const direction = resolveKayakPaddleDirection(gesture.startY, clientY || gesture.lastY);
    setKayakPaddlePhase(gesture.side, null);
    events.emit("rpg_qizhen_paddle_input", {
      side: gesture.side,
      direction,
      pointerType: pointerType || gesture.pointerType
    });
  }

  function cancelKayakPaddleGesture(pointerId: number) {
    const gesture = kayakPaddleGesturesRef.current.get(pointerId);
    if (!gesture) return;
    kayakPaddleGesturesRef.current.delete(pointerId);
    setKayakPaddlePhase(gesture.side, null);
  }

  function emitFishingTouchInput(action: QizhenFishingAction, type: "press" | "release", event: React.PointerEvent<HTMLButtonElement>) {
    if (type === "press") {
      try {
        event.currentTarget.setPointerCapture?.(event.pointerId);
      } catch {
        // Pointer capture is optional in older WebKit and some embedded browsers.
      }
    }
    events.emit("rpg_qizhen_fishing_input", { action, type, pointerType: event.pointerType });
    event.preventDefault();
  }

  function returnToPhone() {
    setInspectedMapItem(null);
    if (desktopSplit) {
      onFocusPhone?.();
      return;
    }
    exitRpgFullscreen();
    controller.returnToPhone();
  }

  function inspectMapItem(item: "campusCard" | "gamepad") {
    if (item === "campusCard") {
      const identityReadable = selectIdentityReadable(store.getState());
      events.emit("toast", {
        text: identityReadable
          ? `电子校园卡：${actOneContent.studentName} · ${actOneContent.studentId}`
          : "电子校园卡：身份信息尚未读取",
        tone: "task",
        durationMs: 3200
      });
      return;
    }

    const result = controller.useGamepad();
    const feedback = {
      active: "手柄已连接：WASD 或方向键移动，空格键交互。",
      identity_required: "手柄有电，角色还没有姓名。去部门黄页读取校园卡。",
      exercise_required: "手柄已连接，浙大体艺还没有开始课外锻炼。",
      not_owned: "道具栏里没有手柄。",
      inactive: "当前任务还没有开放手柄控制。"
    }[result];
    events.emit("toast", {
      text: feedback,
      tone: result === "active" ? "task" : "system",
      durationMs: 4200
    });
  }

  function openMapItemDetails(itemId: ItemId) {
    lastMapItemTap.current = null;
    setInspectedMapItem(itemId);
    events.emit("inventory_item_inspected", { itemId, surface: "rpg" });
  }

  function handleMapItemPointerUp(itemId: ItemId) {
    const now = Date.now();
    const previousTap = lastMapItemTap.current;
    if (previousTap?.itemId === itemId && now - previousTap.at <= DOUBLE_TAP_WINDOW_MS) {
      openMapItemDetails(itemId);
      return;
    }
    lastMapItemTap.current = { itemId, at: now };
  }

  function closeMapItemDetails() {
    const closingItem = inspectedMapItem;
    setInspectedMapItem(null);
    if (closingItem === "archivedLeaveRule") {
      libraryController.confirmArchivedRuleRead();
    }
    if (closingItem === "decoyPaper" && store.getState().theaterHunt.phase === "complete") {
      events.emit("theater_decoy_inspect_closed");
    }
  }

  return (
    <main
      className={`rpg-stage ${runtimeScene === "campus_bootstrap" || runtimeScene === "campus_qizhen_loop" ? "is-campus-map" : ""} ${runtimeScene === "campus_qizhen_loop" ? "is-qizhen-approach" : ""} ${runtimeScene === "library_interior" ? "is-library-interior" : ""} ${runtimeScene === "canteen_interior" ? "is-canteen-interior" : ""} ${runtimeScene === "theater_interior" ? "is-theater-interior" : ""} ${runtimeScene === "qizhen_lake" ? "is-qizhen-lake" : ""} ${runtimeScene === "duan_yongping_temporal_maze" ? "is-chapter-four-temporal-maze" : ""} ${runtimeScene === "campus_bootstrap" && state.canteenHunt.phase === "chase_ready" ? "is-canteen-bike" : ""} ${chaseActive ? "is-canteen-chase" : ""} ${embedded ? "is-embedded" : ""}`.trim()}
      aria-label="7:55 RPG runtime"
      data-input-blocked={inputBlocked || itemInspectOpen || chapter4InteractionBlocked ? "true" : "false"}
      data-keyboard-blocked={keyboardBlocked || chapter4InteractionBlocked ? "true" : "false"}
      data-rpg-engine={chapter4Stair3dActive ? "three" : "phaser"}
      data-rpg-engine-reason={chapter4Stair3dActive ? "chapter4_spatial_stair" : "web_runtime_only"}
    >
      <section ref={bindShellRef} className="rpg-shell" aria-label="7:55 横屏游戏">
        <div ref={hostRef} className="rpg-canvas-host">
          <div ref={phaserHostRef} className="rpg-phaser-host" hidden={chapter4Stair3dActive} />
          <div
            id="stair-demo"
            ref={stair3dHostRef}
            className="rpg-stair3d-host"
            hidden={!chapter4Stair3dActive}
            aria-label="第四章错位楼梯三维空间解谜"
          />
        </div>

        {clockTint ? (
          <div
            className="rpg-time-tint"
            aria-hidden="true"
            style={{ background: clockTint.color, opacity: clockTint.alpha }}
          />
        ) : null}

        {clockCrownVisible && !prologueActive ? <RpgClockCrownOverlay /> : null}

        {chaseActive ? (
          <CanteenChaseOverlay
            events={events}
            onAttempt={(attempt) => { canteenController.resolveChaseAttempt(attempt); }}
            onContinue={() => {
              canteenController.completeChase();
            }}
          />
        ) : null}

        {prologueActive ? (
          <Chapter4PrologueOverlay
            key={`chapter4-prologue-${prologueInitialElapsedMs}`}
            events={events}
            initialElapsedMs={prologueInitialElapsedMs}
            onComplete={() => { chapter4PrologueController.completePrologue(); }}
          />
        ) : null}

        {chapter4ElevatorPanelOpen && chapter4MazeUiActive ? (
          <ElevatorTrackSyncGame
            mode={state.chapter4.mode}
            observed={state.chapter4.elevatorHistoryObserved}
            initialStartSeconds={state.chapter4.elevatorSelectedStartSeconds}
            attempts={state.chapter4.elevatorReplayAttempts}
            onSwitchToLight={() => { chapter4Controller.setMode("light"); }}
            onConfirm={(startSeconds) => {
              const result = chapter4Controller.startElevatorReplay(startSeconds);
              if (result === "accepted") setChapter4ElevatorPanelOpen(false);
              return result;
            }}
            onClose={() => setChapter4ElevatorPanelOpen(false)}
          />
        ) : null}

        {chapter4WayfindingPanelOpen && chapter4MazeUiActive ? (
          <WayfindingBoardGame
            onConfirm={(order) => {
              const result = resolveChapterFourMazeAction({
                requestId: `wayfinding-ui-${++chapter4WayfindingRequestSerialRef.current}`,
                action: "align_wayfinding_board",
                targetId: CHAPTER_FOUR_MAZE_IDS.wayfindingBoardTarget,
                order: [...order]
              });
              if (result === "accepted" || result === "already_complete") {
                closeChapter4WayfindingPanel("accepted");
              }
              return result;
            }}
            onCancel={() => closeChapter4WayfindingPanel("cancelled")}
          />
        ) : null}

        {showTaskBar && !chaseActive && !prologueActive && !chapter4InteractionBlocked && (!chapter4MazeActive || chapter4MazeUiActive) ? (
          <QuestTaskBar
            state={state}
            events={events}
            router={router}
            variant="rpg"
            portalRoot={shellRoot}
            onNavigate={onTaskNavigate}
          />
        ) : null}

        <div className="rpg-system-actions">
          <button type="button" onClick={returnToPhone}>{desktopSplit ? "聚焦手机" : "返回手机主页"}</button>
          <button type="button" onClick={() => toggleRpgFullscreen()}>全屏</button>
        </div>

        {runtimeScene === "campus_bootstrap" && !chaseActive ? (
          <nav className="rpg-camera-actions" aria-label="地图视角">
            <button type="button" aria-label="定位人物" title="定位人物" onClick={(event) => { events.emit("rpg_camera_recenter"); event.currentTarget.blur(); }}>⌖</button>
            <button type="button" aria-label="放大地图" title="放大地图" onClick={(event) => { events.emit("rpg_camera_zoom", { delta: 0.1 }); event.currentTarget.blur(); }}>+</button>
            <button type="button" aria-label="缩小地图" title="缩小地图" onClick={(event) => { events.emit("rpg_camera_zoom", { delta: -0.1 }); event.currentTarget.blur(); }}>−</button>
          </nav>
        ) : null}

        {((runtimeScene === "canteen_interior" && state.canteenHunt.active && ["tray_search", "drink_mix", "menu_order", "pickup_search", "exit_blocking", "chase_ready"].includes(state.canteenHunt.phase))
          || (runtimeScene === "campus_bootstrap" && state.canteenHunt.phase === "chase_ready")) ? (
          <RpgRealityModeToggle
            mode={state.canteenHunt.mode}
            onToggle={() => {
              if (runtimeScene === "canteen_interior") {
                events.emit("rpg_canteen_toggle_mode");
                return;
              }
              events.emit("rpg_canteen_mode_requested", {
                mode: state.canteenHunt.mode === "dark" ? "light" : "dark"
              });
            }}
          />
        ) : null}

        {runtimeScene === "theater_interior" && ["entry_ticket", "program_search", "prop_setup", "spotlight_ready"].includes(state.theaterHunt.phase) ? (
          <RpgRealityModeToggle
            className="rpg-theater-mode-toggle"
            mode={state.theaterHunt.mode}
            onToggle={() => events.emit("rpg_theater_mode_requested", {
              mode: state.theaterHunt.mode === "dark" ? "light" : "dark"
            })}
          />
        ) : null}

        {runtimeScene === "qizhen_lake" && !fishingSession && ["lake_exploration", "tool_chain", "swan_exchange", "paper_capture"].includes(state.qizhenLake.phase) ? (
          <RpgRealityModeToggle
            className="rpg-qizhen-mode-toggle"
            mode={state.qizhenLake.mode}
            onToggle={() => events.emit("rpg_qizhen_mode_requested", {
              mode: state.qizhenLake.mode === "dark" ? "light" : "dark"
            })}
          />
        ) : null}

        {chapter4MazeUiActive && !chapter4InteractionBlocked ? (
          <RpgRealityModeToggle
            mode={state.chapter4.mode}
            onToggle={() => chapter4Controller.setMode(state.chapter4.mode === "dark" ? "light" : "dark")}
          />
        ) : null}

        {((state.actOne.inventoryRecovered && state.items.campusCard) || state.items.gamepad) && runtimeScene === "campus_bootstrap" && !chaseActive ? (
          <aside className="rpg-temp-inventory" aria-label="地图物品栏">
            <strong>物品栏</strong>
            <div className="rpg-temp-items">
              {state.actOne.inventoryRecovered && state.items.campusCard ? (
                <button
                  type="button"
                  aria-label="查看电子校园卡"
                  title="单击查看校园卡信息，双击查看完整详情"
                  onClick={() => inspectMapItem("campusCard")}
                  onPointerUp={() => handleMapItemPointerUp("campusCard")}
                >
                  <PixelIcon name="campusCard" size={30} />
                  <span>校园卡</span>
                </button>
              ) : null}
              {state.items.gamepad ? (
                <button
                  type="button"
                  className={state.actOne.movementEnabled ? "is-active" : "is-waiting"}
                  aria-label="使用游戏手柄"
                  title="单击连接手柄，双击查看完整详情"
                  onClick={() => inspectMapItem("gamepad")}
                  onPointerUp={() => handleMapItemPointerUp("gamepad")}
                >
                  <PixelIcon name="gamepad" size={30} />
                  <span>手柄</span>
                </button>
              ) : null}
            </div>
            {state.items.gamepad ? (
              <small>
                {state.actOne.movementEnabled
                  ? "已连接"
                  : !state.actOne.characterNamed
                    ? "待登记姓名"
                    : "待开始锻炼"}
              </small>
            ) : null}
          </aside>
        ) : null}

        {!prologueActive && !chapter4InteractionBlocked && !fishingSession && (runtimeScene === "library_interior"
          || runtimeScene === "dorm_hub"
          || runtimeScene === "canteen_interior"
          || (runtimeScene === "theater_interior" && !["spotlight_hunt", "reversal"].includes(state.theaterHunt.phase))
          || runtimeScene === "qizhen_lake"
          || (runtimeScene === "campus_bootstrap" && state.canteenHunt.phase === "chase_ready")) ? (
          <RpgInventoryDock
            state={state}
            events={events}
            shellRef={shellRef}
            canvasHostRef={hostRef}
            runtimeScene={runtimeScene}
            onInspect={openMapItemDetails}
            onDragSelectionChange={selectDraggedRpgItem}
          />
        ) : null}

        <RpgSubtitleLayer
          key={runtimeScene}
          events={events}
          state={state}
          blocked={inputBlocked || itemInspectOpen || chaseActive || prologueActive || chapter4InteractionBlocked || Boolean(fishingSession)}
        />

        {state.actOne.controlsInstalled && touchControls && !chaseActive && !prologueActive && !chapter4InteractionBlocked && runtimeScene === "qizhen_lake" && state.qizhenLake.vehicle === "kayak" ? (
          fishingSession ? (
            <nav className="rpg-kayak-controls is-fishing" aria-label="节奏钓鱼 A 左收线、S 提竿、D 右收线按钮">
              <button
                type="button"
                className="left-paddle"
                aria-label="A 左收线"
                onPointerDown={(event) => emitFishingTouchInput("left", "press", event)}
                onPointerUp={(event) => emitFishingTouchInput("left", "release", event)}
                onPointerCancel={(event) => emitFishingTouchInput("left", "release", event)}
                onLostPointerCapture={(event) => emitFishingTouchInput("left", "release", event)}
              >
                <PixelIcon name="willowBranchPaddle" size={34} />
                <span>左收线</span>
                <small>A</small>
              </button>
              <button
                type="button"
                className="interact"
                aria-label="S 提竿"
                onPointerDown={(event) => emitFishingTouchInput("hook", "press", event)}
                onPointerUp={(event) => emitFishingTouchInput("hook", "release", event)}
                onPointerCancel={(event) => emitFishingTouchInput("hook", "release", event)}
                onLostPointerCapture={(event) => emitFishingTouchInput("hook", "release", event)}
              >
                <PixelIcon name="fishingRod" size={34} />
                <span>提竿</span>
                <small>S</small>
              </button>
              <button
                type="button"
                className="right-paddle"
                aria-label="D 右收线"
                onPointerDown={(event) => emitFishingTouchInput("right", "press", event)}
                onPointerUp={(event) => emitFishingTouchInput("right", "release", event)}
                onPointerCancel={(event) => emitFishingTouchInput("right", "release", event)}
                onLostPointerCapture={(event) => emitFishingTouchInput("right", "release", event)}
              >
                <PixelIcon name="warningSignPaddle" size={34} />
                <span>右收线</span>
                <small>D</small>
              </button>
            </nav>
          ) : (
            <nav className="rpg-kayak-controls" aria-label="皮划艇划桨手势和交互按钮">
              <button
                type="button"
                className={`left-paddle is-swipe-${kayakPaddleSwipeState.left ?? "idle"}`}
                aria-label="左桨，上划前进，下划后退，轻触默认前进"
                onPointerDown={(event) => startKayakPaddleGesture("left", event)}
                onPointerMove={updateKayakPaddleGesture}
                onPointerUp={(event) => completeKayakPaddleGesture(event.pointerId, event.clientY, event.pointerType)}
                onPointerCancel={(event) => cancelKayakPaddleGesture(event.pointerId)}
                onLostPointerCapture={(event) => cancelKayakPaddleGesture(event.pointerId)}
              >
                <PixelIcon name="willowBranchPaddle" size={34} />
                <span>左桨</span>
                <small>{kayakPaddleSwipeState.left === "reverse" ? "↓ 后退" : kayakPaddleSwipeState.left === "forward" ? "↑ 前进" : "↑前进 · ↓后退"}</small>
              </button>
              <button
                type="button"
                className={`right-paddle is-swipe-${kayakPaddleSwipeState.right ?? "idle"}`}
                aria-label="右桨，上划前进，下划后退，轻触默认前进"
                onPointerDown={(event) => startKayakPaddleGesture("right", event)}
                onPointerMove={updateKayakPaddleGesture}
                onPointerUp={(event) => completeKayakPaddleGesture(event.pointerId, event.clientY, event.pointerType)}
                onPointerCancel={(event) => cancelKayakPaddleGesture(event.pointerId)}
                onLostPointerCapture={(event) => cancelKayakPaddleGesture(event.pointerId)}
              >
                <PixelIcon name="warningSignPaddle" size={34} />
                <span>右桨</span>
                <small>{kayakPaddleSwipeState.right === "reverse" ? "↓ 后退" : kayakPaddleSwipeState.right === "forward" ? "↑ 前进" : "↑前进 · ↓后退"}</small>
              </button>
              <button type="button" className="interact" aria-label="与当前湖区目标交互" onClick={() => events.emit("rpg_interact")}>交互</button>
            </nav>
          )
        ) : state.actOne.controlsInstalled && touchControls && !chaseActive && !prologueActive && !chapter4InteractionBlocked ? (
          <nav
            className={`rpg-touch-controls ${state.actOne.movementEnabled ? "" : "is-disabled"}`.trim()}
            aria-label="RPG操作键，键盘使用 WASD 移动和空格键交互"
          >
            <button type="button" aria-label="向上" disabled={!state.actOne.movementEnabled} onPointerDown={(event) => direction(event, 0, -1)}>↑</button>
            <button type="button" aria-label="向左" disabled={!state.actOne.movementEnabled} onPointerDown={(event) => direction(event, -1, 0)}>←</button>
            <button type="button" aria-label="向下" disabled={!state.actOne.movementEnabled} onPointerDown={(event) => direction(event, 0, 1)}>↓</button>
            <button type="button" aria-label="向右" disabled={!state.actOne.movementEnabled} onPointerDown={(event) => direction(event, 1, 0)}>→</button>
            <button
              type="button"
              className="interact"
              aria-label="交互（键盘为空格键）"
              disabled={!state.actOne.movementEnabled}
              onClick={() => events.emit("rpg_interact")}
            >
              {RPG_CONTROL_HINTS.touchInteraction}
            </button>
          </nav>
        ) : null}

        <div className="rpg-rotate-hint" role="status">请将设备横过来继续 RPG</div>
      </section>
      <ItemInspectDialog
        open={inspectedMapItem !== null}
        itemId={inspectedMapItem}
        variant="rpg"
        portalRoot={shellRoot}
        onClose={closeMapItemDetails}
      />
    </main>
  );
}

export function clearRpgCanvasHost(host: HTMLElement): void {
  host.replaceChildren();
}

export function activateRpgScene(game: Phaser.Game, target: string): void {
  Object.values(SCENE_KEYS).forEach((sceneKey) => {
    if (sceneKey !== target && game.scene.isActive(sceneKey)) {
      game.scene.stop(sceneKey);
    }
  });
  if (!game.scene.isActive(target)) {
    game.scene.start(target);
  }
}

function getLibraryObjective(state: GameState): string {
  const phase = state.ui.libraryFinalsPhase;
  const puzzle = state.ui.libraryFinalsPuzzle;
  if (phase === "library_entered") return puzzle.entranceRecordRead ? "前往二层南区寻找 022" : "点击闸机小屏，核对入馆与到达时间";
  if (phase === "occupied_seat_found") return puzzle.occupancyNoteCollected ? "调查纸条提到的公开记录" : "检查书包旁边的占座纸条";
  if (phase === "evidence_gathering") {
    if (!puzzle.investigationOpened) return "用占座纸条查找公开记录";
    const evidenceReadyCount = [
      puzzle.archivedRuleRead,
      puzzle.nonPersonProofStamped,
      puzzle.seatReceiptCollected,
      puzzle.presenceProofCollected
    ].filter(Boolean).length;
    return evidenceReadyCount < 4
      ? `并行收集四项公示材料（${evidenceReadyCount}/4）`
      : "把已取得材料上传到 CC98";
  }
  if (phase === "bd_briefing") return "确认系统说明，开始筛选有效回复";
  if (phase === "top_ten_rising" || phase === "top_ten_reached") return "让证据公示进入 CC98 十大";
  if (phase === "recovery_application") return "完成图书馆座位恢复申请";
  if (phase === "pass_ready") return "对 022 书包使用离座清退 PASS";
  if (phase === "backpack_removed") return "坐到已经恢复的 022";
  if (phase === "seat_recovered") return "与 022 继续对话";
  if (phase === "friend_contacted") return "追上逃跑的记录纸条";
  return "前往基础图书馆，寻找系统的朋友";
}

function getLibraryProgress(state: GameState): string {
  const puzzle = state.ui.libraryFinalsPuzzle;
  if (state.ui.libraryFinalsPhase === "friend_contacted") {
    return "完成";
  }
  if (state.ui.libraryFinalsPhase === "bd_briefing") {
    return "说明";
  }
  if (state.ui.libraryFinalsPhase === "top_ten_rising" || state.ui.libraryFinalsPhase === "top_ten_reached") {
    return `R${String(4 - puzzle.bdCount).padStart(2, "0")}`;
  }
  if (puzzle.investigationOpened) {
    const evidenceReadyCount = [
      puzzle.archivedRuleRead,
      puzzle.nonPersonProofStamped,
      puzzle.seatReceiptCollected,
      puzzle.presenceProofCollected
    ].filter(Boolean).length;
    return `${evidenceReadyCount}/4`;
  }
  return puzzle.callNumberCollected ? "755" : "调查";
}

function resolveRuntimeScene(state: GameState): RpgSceneId {
  const hasLibraryCheckpoint = [
    "library_entrance",
    "library_front_desk",
    "library_shelf_755",
    "library_seat_022"
  ].includes(state.rpgCheckpoint);
  const activeLibraryPhase = [
    "library_entered",
    "occupied_seat_found",
    "evidence_gathering",
    "bd_briefing",
    "top_ten_rising",
    "top_ten_reached",
    "recovery_application",
    "pass_ready",
    "backpack_removed",
    "seat_recovered"
  ].includes(state.ui.libraryFinalsPhase);
  if (state.rpgScene === "campus_bootstrap" && hasLibraryCheckpoint && activeLibraryPhase) {
    return "library_interior";
  }
  return state.rpgScene;
}

function resolveRuntimeSceneKey(state: GameState): string {
  const scene = resolveRuntimeScene(state);
  if (
    scene === "duan_yongping_temporal_maze"
    && (state.rpgCheckpoint === "c4_b3_landing" || state.rpgCheckpoint === "c4_b2_activity")
  ) {
    return "chapter-four-stair-alignment";
  }
  return SCENE_KEYS[scene];
}
