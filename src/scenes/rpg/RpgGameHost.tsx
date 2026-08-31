import { useCallback, useEffect, useMemo, useRef, useState, useSyncExternalStore } from "react";
import Phaser from "phaser";
import type { EventBus } from "../../core/EventBus";
import type { SceneRouter } from "../../core/SceneRouter";
import { selectIdentityReadable } from "../../core/IdentityAccess";
import type {
  GameState,
  GameStore,
  ChapterFourLightZoneId,
  ItemId,
  LibraryLocationId,
  QuestViewModel,
  QizhenFishingSpotId,
  QizhenJournalDraft,
  QizhenLakeMode,
  QizhenLakeZone,
  QizhenPaddleDirection,
  QizhenPaddleSide,
  QizhenPhotoRecipe,
  QizhenPhotoRecord,
  QizhenPhotoSpotId,
  RpgCheckpointId,
  RpgSceneId,
  TheaterMode,
  TheaterProgramId
} from "../../core/types";
import actOneContent from "../../data/act-one-bootstrap.content.json";
import { chapterThreeStoryLineKeyForSubtitle } from "../../data/chapterThreeStory";
import qizhenLakeContent from "../../data/chapter3-qizhen-lake.content.json";
import chapterFour755Content from "../../data/chapter4-755.content.json";
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
  type QizhenActionResult,
  type QizhenJournalDraftRejection,
  type QizhenPhotoCaptureRejection
} from "../../modules/ChapterThreeQizhenLakeController";
import {
  CHAPTER_FOUR_755_INTENT_DETAIL_CODES,
  ChapterFourTemporalMazeController,
  resolveChapterFour755SessionRequest,
  validateChapterFour755IntentRequest,
  type ChapterFour755Intent,
  type ChapterFour755IntentDetailCode,
  type ChapterFour755IntentResult,
  type ChapterFourMaintenanceDiagnosisAnswers
} from "../../modules/ChapterFourTemporalMazeController";
import {
  CHAPTER_FOUR_INSERTED_PUZZLES,
  isChapterFourInsertedPuzzleId,
  type ChapterFourInsertedPuzzleAnswer,
  type ChapterFourInsertedPuzzleId,
  type ChapterFourInsertedPuzzleTargetId
} from "../../modules/ChapterFourInsertedPuzzleModel";
import { ChapterFourInsertedPuzzleGame } from "../../components/temporal-maze/ChapterFourInsertedPuzzleGame";
import { ChapterFourMaintenanceDiagnosisGame } from "../../components/temporal-maze/ChapterFourMaintenanceDiagnosisGame";
import { ChapterFourPowerPanelGame } from "../../components/temporal-maze/ChapterFourPowerPanelGame";
import { ChapterFourStarLampClosure } from "../../components/temporal-maze/ChapterFourStarLampClosure";
import { ChapterFourStairPuzzleOverlay } from "../../components/temporal-maze/ChapterFourStairPuzzleOverlay";
import { ChapterFourClosureSessionRegistry } from "../../modules/ChapterFourClosureSessionRegistry";
import { useChapter4PrologueGateBlocked } from "../../components/Chapter4PrologueRuntimeGate";
import { selectChapterFourMazeProjection } from "../../modules/ChapterFourMazeProjection";
import { exitRpgFullscreen, toggleRpgFullscreen } from "../../modules/RpgFullscreen";
import { BootScene } from "./BootScene";
import { QizhenLoopScene } from "./QizhenLoopScene";
import { DORM_HUB_WARM_ASSET_URLS, DormHubScene } from "./DormHubScene";
import { LIBRARY_INTERIOR_WARM_ASSET_URLS, LibraryInteriorScene } from "./LibraryInteriorScene";
import { CANTEEN_INTERIOR_WARM_ASSET_URLS, CanteenInteriorScene } from "./CanteenInteriorScene";
import { THEATER_INTERIOR_WARM_ASSET_URLS, TheaterInteriorScene } from "./TheaterInteriorScene";
import { createTheaterRuntimePort } from "./TheaterRuntimeContract";
import type { TheaterSpotlightAttempt, TheaterSpotlightLane } from "./TheaterSpotlightModel";
import { QIZHEN_LAKE_WARM_ASSET_URLS, QizhenLakeScene } from "./QizhenLakeScene";
import {
  QizhenRainRescueCinematic,
  type QizhenRainRescueCinematicResult
} from "./QizhenRainRescueCinematic";
import type { QizhenFishingAction, QizhenFishingResult } from "./QizhenFishingRhythmModel";
import { CanteenBikeTransitionOverlay } from "./CanteenBikeTransitionOverlay";
import { CanteenChaseOverlay } from "./CanteenChaseOverlay";
import { ChapterFourTemporalMazeScene } from "./ChapterFourTemporalMazeScene";
import {
  getChapterFourWarmupPhaseAssets,
  isChapterFourWarmupPhase,
  type ChapterFourWarmupPhase
} from "./ChapterFourWarmupAssets";
import { warmRpgRuntime } from "./RpgRuntimePreload";
import { RPG_PLAYER_TEXTURE_ASSETS } from "./RpgPlayerTextures";
import { ZIJINGANG_CAMPUS_PLATE_URL } from "./ZijingangLandmarkAssets";
import { QIZHEN_LOOP_PANORAMA_URL } from "./QizhenLoopWorld";
import { RpgRealityModeToggle } from "./RpgRealityModeToggle";
import { createRpgBridge } from "./RpgBridge";
import { RPG_CONTROL_HINTS } from "./RpgControlHints";
import { RpgInventoryDock } from "./RpgInventoryDock";
import {
  installRpgAdaptiveResolution,
  RPG_LOGICAL_HEIGHT,
  RPG_LOGICAL_WIDTH
} from "./RpgRenderResolution";
import { QuestTaskBar } from "../../components/QuestClueStrip";
import { RpgSubtitleLayer } from "../../components/RpgSubtitleLayer";
import { QizhenJournalCamera, type QizhenJournalCameraSession } from "../../components/QizhenJournalCamera";
import { useMediaQuery } from "../../components/useMediaQuery";
import {
  CHAPTER_FOUR_755_SCENE_KEY,
  revalidateChapterFour755SpatialAttestation,
  resolveChapterFour755SpatialAttestationTarget,
  type ChapterFour755RuntimeTargetContext,
  type ChapterFour755SpatialAttestationFailure,
  type ChapterFour755SpatialAttestationRequest
} from "./RpgInteractionContract";

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

const RPG_SCENE_WARM_ASSET_URLS: Readonly<Record<RpgSceneId, readonly string[]>> = {
  campus_bootstrap: [ZIJINGANG_CAMPUS_PLATE_URL],
  campus_qizhen_loop: [QIZHEN_LOOP_PANORAMA_URL],
  dorm_hub: DORM_HUB_WARM_ASSET_URLS,
  library_interior: LIBRARY_INTERIOR_WARM_ASSET_URLS,
  canteen_interior: CANTEEN_INTERIOR_WARM_ASSET_URLS,
  theater_interior: THEATER_INTERIOR_WARM_ASSET_URLS,
  qizhen_lake: QIZHEN_LAKE_WARM_ASSET_URLS,
  duan_yongping_temporal_maze: []
};

export interface RpgSceneWarmAsset {
  key: string;
  url: string;
  sourceSize?: Readonly<{ width: number; height: number }>;
}

/** 与各 Phaser Scene 的阶段资源表使用同一批 URL，不扫描素材源目录。 */
export function getRpgSceneWarmAssets(
  sceneId: RpgSceneId,
  phase?: ChapterFourWarmupPhase
): readonly RpgSceneWarmAsset[] {
  const includePlayerAssets = sceneId !== "duan_yongping_temporal_maze" || (phase ?? "entry") === "entry";
  const playerAssets = includePlayerAssets
    ? Object.entries(RPG_PLAYER_TEXTURE_ASSETS).map(([key, url]) => ({ key, url }))
    : [];
  const sceneAssets: readonly RpgSceneWarmAsset[] = sceneId === "duan_yongping_temporal_maze"
    ? getChapterFourWarmupPhaseAssets(phase ?? "entry")
    : RPG_SCENE_WARM_ASSET_URLS[sceneId].map((url, index) => ({
        key: `${sceneId}-${index}`,
        url
      }));
  return [...new Map(
    [...playerAssets, ...sceneAssets].map((asset) => [asset.url, asset])
  ).values()];
}

export function getRpgSceneWarmAssetUrls(
  sceneId: RpgSceneId,
  phase?: ChapterFourWarmupPhase
): readonly string[] {
  return getRpgSceneWarmAssets(sceneId, phase).map((asset) => asset.url);
}

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
const QIZHEN_PHOTO_SESSION_FEEDBACK: Record<QizhenPhotoCaptureRejection | QizhenJournalDraftRejection, string> = {
  inactive: "启真湖的行程还没开始,现在拍不了。",
  swan_chase: "黑天鹅正追着船尾,顾不上拍照。",
  journal_locked: "先完成上船教学,稳住船之后再打开相机。",
  journal_archived: "启真湖的帖子已经归档,不能再补拍了。",
  unknown_spot: "这里构不成画面,换个位置再试。",
  orphan_photo: "这张照片已经不在记录里了,重新拍一张。",
  draft_mismatch: "草稿和照片对不上,请重新拍摄。",
  incomplete_draft: "先把该选的都选好,再存草稿。"
};
const QIZHEN_CAMERA_TITLE = qizhenLakeContent.journal.camera.title;

/** 相机会话的宿主局部态:会话输入来自场景冻结帧,照片与草稿由 controller 回灌。 */
interface QizhenPhotoSessionState {
  session: QizhenJournalCameraSession;
  capturedAtSeconds?: number;
  photo: QizhenPhotoRecord | null;
  draft: QizhenJournalDraft | null;
}
interface ChapterFourPowerPanelSession {
  openRequestId: string;
  targetId: "a1_power_panel";
  spatial: { distance: "within_range" };
  runtimeTarget: ChapterFour755RuntimeTargetContext;
}
interface ChapterFourInsertedPuzzleSession {
  puzzleId: ChapterFourInsertedPuzzleId;
  targetId: ChapterFourInsertedPuzzleTargetId;
  mode: "light" | "dark";
  completed: boolean;
  prerequisiteReady: boolean;
}
const CHAPTER_FOUR_755_ACTIVE_PHASES = new Set<GameState["chapter4"]["phase"]>([
  "opening_handoff",
  "opening_paper_caught",
  "hall_clock_inspection",
  "bakery_hour_hand",
  "room204_restore",
  "maintenance_repair",
  "blackout_light_grid",
  "final_chase",
  "final_minute_recovery",
  "return_to_clock",
  "morning_checkin",
  "exterior_closure"
]);
// These intents already own their visual or subtitle presentation inside the
// Phaser scene or React overlay. The Host keeps the ownership list as contract
// metadata and never opens a second player-facing subtitle surface for them.
const CHAPTER_FOUR_755_PRESENTATION_HANDSHAKE_INTENTS = new Set([
  "complete_opening_paper_flight",
  "catch_attendance_paper",
  "resolve_external_time_rejection",
  "inspect_hall_clock",
  "resolve_hall_clock_inspection",
  "pull_hall_clock",
  "inspect_bakery_conveyor_lamp",
  "complete_bakery_conveyor_stop",
  "talk_to_a1_front_desk_attendant",
  "talk_to_chapter_four_support_npc",
  "inspect_alumni_figure",
  "complete_zhu_two_questions",
  "observe_classroom_104_chalk_residual",
  "check_classroom_105_terminal_replay",
  "observe_elevator_history",
  "calibrate_elevator_history",
  "observe_a3_reference",
  "inspect_chapter_four_context",
  "complete_inserted_puzzle",
  "complete_misaligned_stair",
  "observe_room204_residual",
  "place_room204_piece",
  "complete_room204_projection",
  "collect_positioning_plate",
  "install_positioning_plate",
  "begin_final_clock_drag",
  "complete_minute_theft",
  "open_power_panel",
  "toggle_light_zone",
  "lock_light_grid",
  "acknowledge_exterior_closure"
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
    unobserved: "当前目标还没有观察记录；深色观察可补充坐标。",
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

function chapterFour755Feedback(
  result: ChapterFour755IntentResult,
  _intentType?: string
): string {
  if (result.detailCode) {
    const detail = CHAPTER_FOUR_755_INTENT_DETAILS[result.detailCode];
    if (detail) return `${detail.reason} ${detail.nextAction}`;
  }
  if (result.reason === "accepted") return "当前操作已记录。";
  if (result.reason === "already_complete") return "当前操作已经完成。";
  if (result.reason === "wrong_mode") return "切换到目标要求的现实模式后重试。";
  if (result.reason === "wrong_item") return "当前目标需要另一件道具。";
  if (result.reason === "too_far") return "距离目标太远，请靠近可见交互区域。";
  if (result.reason === "incorrect") return "当前组合与已记录的线索不一致。";
  if (result.reason === "inactive") return "第四章教学楼流程尚未开始。";
  return "当前剧情条件尚未满足。";
}

const CHAPTER_FOUR_755_INTENT_DETAILS = chapterFour755Content.intentFeedback.details as Readonly<
  Record<ChapterFour755IntentDetailCode, { reason: string; nextAction: string }>
>;
const chapterFour755DetailKeys = Object.keys(CHAPTER_FOUR_755_INTENT_DETAILS);
if (chapterFour755DetailKeys.length !== CHAPTER_FOUR_755_INTENT_DETAIL_CODES.length
  || CHAPTER_FOUR_755_INTENT_DETAIL_CODES.some((code) => {
    const copy = CHAPTER_FOUR_755_INTENT_DETAILS[code];
    return !copy || copy.reason.trim().length === 0 || copy.nextAction.trim().length === 0;
  })) {
  throw new Error("chapter4_755_intent_detail_copy_contract_invalid");
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

function focusRpgCanvas(game: Phaser.Game): void {
  const canvas = game.canvas;
  canvas.tabIndex = -1;
  try {
    canvas.focus({ preventScroll: true });
  } catch {
    canvas.focus();
  }
}

export function RpgGameHost({
  store,
  router,
  events,
  inputBlocked: inputBlockedProp = false,
  keyboardBlocked: keyboardBlockedProp = false,
  embedded = false,
  showTaskBar = true,
  desktopSplit = false,
  onFocusPhone,
  onTaskNavigate
}: RpgGameHostProps) {
  const prologueGateBlocked = useChapter4PrologueGateBlocked();
  const inputBlocked = inputBlockedProp || prologueGateBlocked;
  const keyboardBlocked = keyboardBlockedProp || prologueGateBlocked;
  const [inspectedMapItem, setInspectedMapItem] = useState<ItemId | null>(null);
  const [shellRoot, setShellRoot] = useState<HTMLElement | null>(null);
  const [fishingSession, setFishingSession] = useState<QizhenFishingSessionSnapshot | null>(null);
  const [photoSession, setPhotoSession] = useState<QizhenPhotoSessionState | null>(null);
  const [qizhenRainRescueCinematicOpen, setQizhenRainRescueCinematicOpen] = useState(false);
  const photoSessionRef = useRef<QizhenPhotoSessionState | null>(null);
  const photoSessionOpen = photoSession !== null;
  const shellRef = useRef<HTMLElement | null>(null);
  const hostRef = useRef<HTMLDivElement | null>(null);
  const phaserHostRef = useRef<HTMLDivElement | null>(null);
  const gameRef = useRef<Phaser.Game | null>(null);
  const inputBlockedRef = useRef(inputBlocked);
  const keyboardBlockedRef = useRef(keyboardBlocked);
  const lastMapItemTap = useRef<{ itemId: ItemId; at: number } | null>(null);
  const activeDirectionPointerRef = useRef<{ pointerId: number; startedAt: number } | null>(null);
  const directionStopTimerRef = useRef<number | null>(null);
  const developerCheckpointInputRestoreSerialRef = useRef(0);
  const chapter4IntentRequestSerialRef = useRef(0);
  const chapter4ResolvedRequestIdsRef = useRef<Set<string>>(new Set());
  const chapter4PowerPanelPendingRequestRef = useRef<string | null>(null);
  const chapter4InsertedPuzzlePendingRequestRef = useRef<string | null>(null);
  const chapter4MaintenanceDiagnosisPendingRequestRef = useRef<string | null>(null);
  const chapter4StairPendingRequestRef = useRef<string | null>(null);
  const chapter4ClosurePendingRequestRef = useRef<string | null>(null);
  const chapter4ClosureSessionIdRef = useRef<string | null>(null);
  const chapter4StairPausedSceneKeysRef = useRef<Set<string>>(new Set());
  const [chapter4InteractionBlocked, setChapter4InteractionBlocked] = useState(false);
  const [chapter4ScenePointerAllowed, setChapter4ScenePointerAllowed] = useState(false);
  const [chapter4SceneKeyboardAllowed, setChapter4SceneKeyboardAllowed] = useState(false);
  const [chapter4PowerPanelSession, setChapter4PowerPanelSession] =
    useState<ChapterFourPowerPanelSession | null>(null);
  const [chapter4PowerPanelPending, setChapter4PowerPanelPending] = useState(false);
  const [chapter4PowerPanelFeedback, setChapter4PowerPanelFeedback] = useState<string | null>(null);
  const [chapter4InsertedPuzzleSession, setChapter4InsertedPuzzleSession] =
    useState<ChapterFourInsertedPuzzleSession | null>(null);
  const [chapter4InsertedPuzzlePending, setChapter4InsertedPuzzlePending] = useState(false);
  const [chapter4InsertedPuzzleFeedback, setChapter4InsertedPuzzleFeedback] = useState<string | null>(null);
  const [chapter4MaintenanceDiagnosisOpen, setChapter4MaintenanceDiagnosisOpen] = useState(false);
  const [chapter4MaintenanceDiagnosisPending, setChapter4MaintenanceDiagnosisPending] = useState(false);
  const [chapter4MaintenanceDiagnosisFeedback, setChapter4MaintenanceDiagnosisFeedback] = useState<string | null>(null);
  const [chapter4StairActive, setChapter4StairActive] = useState(false);
  const [chapter4StairFeedback, setChapter4StairFeedback] = useState<string | null>(null);
  const [chapter4ClosureSessionId, setChapter4ClosureSessionId] = useState<string | null>(null);
  const [chapter4ClosureFeedback, setChapter4ClosureFeedback] = useState<string | null>(null);
  const archivedRuleRevealPendingRef = useRef(false);
  const pendingFishingRef = useRef<{ sessionId: string; spotId: QizhenFishingSpotId } | null>(null);
  const itemInspectOpen = inspectedMapItem !== null;
  const state = useSyncExternalStore(store.subscribe, store.getState, store.getState);
  const canteenStartTransitionActive = state.canteenHunt.phase === "chase_ready"
    && state.canteenHunt.bikePaid
    && !state.canteenHunt.chaseCompleted;
  const canteenChaseRunActive = state.canteenHunt.phase === "chasing"
    && !state.canteenHunt.chaseCompleted;
  const canteenFinishTransitionActive = state.canteenHunt.phase === "chasing"
    && state.canteenHunt.chaseCompleted
    && state.canteenHunt.chaseBestDistance >= 755;
  const canteenExclusiveActive = canteenStartTransitionActive
    || canteenChaseRunActive
    || canteenFinishTransitionActive;
  const chaseActive = canteenChaseRunActive;
  const controller = useMemo(() => new ActOneBootstrapController(store, events), [events, store]);
  const libraryController = useMemo(() => new LibraryFinalsController(store, events), [events, store]);
  const canteenController = useMemo(() => new ChapterThreeCanteenController(store, events), [events, store]);
  const theaterController = useMemo(() => new ChapterThreeTheaterController(store, events), [events, store]);
  const qizhenController = useMemo(() => new ChapterThreeQizhenLakeController(store, events), [events, store]);
  const chapter4ClosureRegistry = useMemo(() => new ChapterFourClosureSessionRegistry(), []);
  const chapter4Controller = useMemo(
    () => new ChapterFourTemporalMazeController(store, events, chapter4ClosureRegistry),
    [chapter4ClosureRegistry, events, store]
  );
  const bridge = useMemo(() => createRpgBridge(store, router, events), [events, router, store]);
  const theaterRuntimePort = useMemo(() => createTheaterRuntimePort(bridge), [bridge]);
  const runtimeScene = resolveRuntimeScene(state);
  const kayakPaddleGesturesRef = useRef<Map<number, KayakPaddleGesture>>(new Map());
  const [kayakPaddleSwipeState, setKayakPaddleSwipeState] = useState<Partial<Record<QizhenPaddleSide, KayakPaddleSwipePhase>>>({});
  const chapter4MazeActive = runtimeScene === "duan_yongping_temporal_maze";
  const chapter4MazeUiActive = chapter4MazeActive
    && state.chapter4.prologueSeen
    && (state.chapter4.floor === "A1" || state.chapter4.floor === "A2" || state.chapter4.floor === "A3")
    && CHAPTER_FOUR_755_ACTIVE_PHASES.has(state.chapter4.phase);
  const chapter4PowerPanelOpen = chapter4PowerPanelSession !== null;
  const chapter4ClosureOpen = chapter4ClosureSessionId !== null;
  const chapter4OverlayBlocked = chapter4InteractionBlocked || chapter4PowerPanelOpen
    || chapter4InsertedPuzzleSession !== null || chapter4MaintenanceDiagnosisOpen || chapter4StairActive
    || chapter4ClosureOpen;
  const chapter4PhaserInputBlocked = chapter4PowerPanelOpen || chapter4InsertedPuzzleSession !== null
    || chapter4MaintenanceDiagnosisOpen || chapter4StairActive || chapter4ClosureOpen
    || (chapter4InteractionBlocked && !chapter4ScenePointerAllowed);
  const chapter4PhaserKeyboardBlocked = chapter4PowerPanelOpen || chapter4InsertedPuzzleSession !== null
    || chapter4MaintenanceDiagnosisOpen || chapter4StairActive || chapter4ClosureOpen
    || (chapter4InteractionBlocked && !chapter4SceneKeyboardAllowed);
  inputBlockedRef.current = inputBlocked || itemInspectOpen || canteenExclusiveActive || chapter4PhaserInputBlocked
    || photoSessionOpen || qizhenRainRescueCinematicOpen;
  keyboardBlockedRef.current = keyboardBlocked || canteenExclusiveActive || chapter4PhaserKeyboardBlocked
    || photoSessionOpen || qizhenRainRescueCinematicOpen;

  useEffect(() => {
    if (!chapter4MazeActive) {
      chapter4ResolvedRequestIdsRef.current.clear();
      setChapter4InteractionBlocked(false);
      setChapter4ScenePointerAllowed(false);
      setChapter4SceneKeyboardAllowed(false);
      chapter4PowerPanelPendingRequestRef.current = null;
      setChapter4PowerPanelSession(null);
      setChapter4PowerPanelPending(false);
      setChapter4PowerPanelFeedback(null);
      chapter4InsertedPuzzlePendingRequestRef.current = null;
      setChapter4InsertedPuzzleSession(null);
      setChapter4InsertedPuzzlePending(false);
      setChapter4InsertedPuzzleFeedback(null);
      chapter4MaintenanceDiagnosisPendingRequestRef.current = null;
      setChapter4MaintenanceDiagnosisOpen(false);
      setChapter4MaintenanceDiagnosisPending(false);
      setChapter4MaintenanceDiagnosisFeedback(null);
      chapter4StairPendingRequestRef.current = null;
      setChapter4StairActive(false);
      setChapter4StairFeedback(null);
    }
  }, [chapter4MazeActive]);

  useEffect(() => events.subscribe((event) => {
    if (event.name !== "rpg_chapter4_warmup_phase_requested") return;
    const phase = event.payload?.phase;
    if (!isChapterFourWarmupPhase(phase)) return;
    const priority = event.payload?.priority === "required" ? "immediate" : "idle";
    void warmRpgRuntime("duan_yongping_temporal_maze", priority, phase);
  }), [events]);

  useEffect(() => {
    return events.subscribe((event) => {
      if (event.name !== "rpg_chapter4_stair_alignment_requested") return;
      const current = store.getState().chapter4;
      const allowed = runtimeScene === "duan_yongping_temporal_maze"
        && current.phase === "room204_restore"
        && current.floor === "A3"
        && current.factIds.includes("zhu_two_questions_answered")
        && current.factIds.includes("a3_media_alignment_completed")
        && !current.factIds.includes("misaligned_stair_solved");
      if (!allowed) {
        events.emit("rpg_subtitle", {
          text: "先完成荣誉墙问答，并在 301 找到旧胶片、到 302 对齐新旧入口影像，再进入空间校准。",
          tone: "system",
          durationMs: 2800
        });
        return;
      }
      setChapter4StairFeedback(null);
      setChapter4StairActive(true);
    });
  }, [events, runtimeScene, store]);

  useEffect(() => {
    return events.subscribe((event) => {
      if (event.name !== "chapter4_inserted_puzzle_requested") return;
      const puzzleId = event.payload?.puzzleId;
      if (!isChapterFourInsertedPuzzleId(puzzleId)) return;
      const definition = CHAPTER_FOUR_INSERTED_PUZZLES[puzzleId];
      if (event.payload?.targetId !== definition.targetId) return;
      const mode = event.payload?.mode;
      if (mode !== "light" && mode !== "dark") return;
      chapter4InsertedPuzzlePendingRequestRef.current = null;
      setChapter4InsertedPuzzlePending(false);
      setChapter4InsertedPuzzleFeedback(null);
      setChapter4InsertedPuzzleSession({
        puzzleId,
        targetId: definition.targetId,
        mode,
        completed: event.payload?.completed === true,
        prerequisiteReady: event.payload?.prerequisiteReady === true
      });
    });
  }, [events]);

  useEffect(() => {
    return events.subscribe((event) => {
      if (event.name !== "rpg_chapter4_755_intent_resolved") return;
      const requestId = String(event.payload?.requestId ?? "");
      if (!requestId || requestId !== chapter4InsertedPuzzlePendingRequestRef.current) return;
      chapter4InsertedPuzzlePendingRequestRef.current = null;
      setChapter4InsertedPuzzlePending(false);
      const result = event.payload?.result;
      const accepted = typeof result === "object"
        && result !== null
        && (result as { accepted?: unknown }).accepted === true;
      if (!accepted) {
        setChapter4InsertedPuzzleFeedback(String(
          event.payload?.feedback ?? "当前组合与现场痕迹不一致，可以继续调整。"
        ));
        return;
      }
      setChapter4InsertedPuzzleSession((current) => current
        ? { ...current, completed: true }
        : current);
      setChapter4InsertedPuzzleFeedback(null);
    });
  }, [events]);

  const submitChapterFourInsertedPuzzle = useCallback((answer: ChapterFourInsertedPuzzleAnswer) => {
    const session = chapter4InsertedPuzzleSession;
    if (!session
      || answer.puzzleId !== session.puzzleId
      || chapter4InsertedPuzzlePendingRequestRef.current) return;
    const requestId = `host-inserted-puzzle-${++chapter4IntentRequestSerialRef.current}`;
    chapter4InsertedPuzzlePendingRequestRef.current = requestId;
    setChapter4InsertedPuzzlePending(true);
    setChapter4InsertedPuzzleFeedback(null);
    events.emit("rpg_chapter4_755_intent_requested", {
      requestId,
      intent: { type: "complete_inserted_puzzle", answer }
    });
  }, [chapter4InsertedPuzzleSession, events]);

  const closeChapterFourInsertedPuzzle = useCallback(() => {
    if (chapter4InsertedPuzzlePendingRequestRef.current) return;
    setChapter4InsertedPuzzleFeedback(null);
    setChapter4InsertedPuzzleSession(null);
  }, []);

  useEffect(() => {
    const game = gameRef.current;
    if (!game?.isBooted) return;
    if (chapter4StairActive) {
      const pausedKeys = chapter4StairPausedSceneKeysRef.current;
      pausedKeys.clear();
      for (const scene of game.scene.getScenes(true)) {
        const sceneKey = scene.sys.settings.key;
        if (!game.scene.isPaused(sceneKey)) {
          pausedKeys.add(sceneKey);
          game.scene.pause(sceneKey);
        }
      }
      setRpgInputEnabled(game, false);
      events.emit("rpg_direction_changed", { x: 0, y: 0 });
      return;
    }
    for (const sceneKey of chapter4StairPausedSceneKeysRef.current) {
      if (game.scene.isPaused(sceneKey)) game.scene.resume(sceneKey);
    }
    chapter4StairPausedSceneKeysRef.current.clear();
  }, [chapter4StairActive, events]);

  const completeChapterFourStair = useCallback(() => {
    if (chapter4StairPendingRequestRef.current) return;
    const requestId = `host-stair-${++chapter4IntentRequestSerialRef.current}`;
    chapter4StairPendingRequestRef.current = requestId;
    setChapter4StairFeedback("正在写入二楼到达记录…");
    events.emit("rpg_chapter4_755_intent_requested", {
      requestId,
      intent: { type: "complete_misaligned_stair" }
    });
  }, [events]);

  useEffect(() => {
    return events.subscribe((event) => {
      if (event.name !== "rpg_chapter4_755_intent_resolved") return;
      const requestId = String(event.payload?.requestId ?? "");
      if (!requestId || requestId !== chapter4StairPendingRequestRef.current) return;
      chapter4StairPendingRequestRef.current = null;
      const result = event.payload?.result;
      const accepted = typeof result === "object"
        && result !== null
        && (result as { accepted?: unknown }).accepted === true;
      if (!accepted) {
        setChapter4StairFeedback(String(event.payload?.feedback ?? "楼梯校准结果未能写入，请重试。"));
        return;
      }
      setChapter4StairFeedback(null);
      setChapter4StairActive(false);
      events.emit("rpg_subtitle", {
        text: "两层错位楼梯已连通。已从三楼抵达二楼，204 教室恢复流程开放。",
        tone: "system",
        durationMs: 3600
      });
    });
  }, [events]);

  useEffect(() => {
    if (state.chapter4.phase === "blackout_light_grid"
      && !state.chapter4.lightGrid.locked) return;
    chapter4PowerPanelPendingRequestRef.current = null;
    setChapter4PowerPanelSession(null);
    setChapter4PowerPanelPending(false);
    setChapter4PowerPanelFeedback(null);
  }, [state.chapter4.lightGrid.locked, state.chapter4.phase]);

  useEffect(() => {
    return events.subscribe((event) => {
      if (event.name !== "chapter4_maintenance_diagnosis_requested") return;
      const chapter = store.getState().chapter4;
      if (runtimeScene !== "duan_yongping_temporal_maze"
        || chapter.phase !== "maintenance_repair"
        || chapter.factIds.includes("cart_wheel_inspected")) return;
      chapter4MaintenanceDiagnosisPendingRequestRef.current = null;
      setChapter4MaintenanceDiagnosisPending(false);
      setChapter4MaintenanceDiagnosisFeedback(null);
      setChapter4MaintenanceDiagnosisOpen(true);
    });
  }, [events, runtimeScene, store]);

  useEffect(() => {
    const active = state.chapter4.phase === "maintenance_repair"
      && !state.chapter4.factIds.includes("cart_wheel_inspected");
    if (active) return;
    chapter4MaintenanceDiagnosisPendingRequestRef.current = null;
    setChapter4MaintenanceDiagnosisOpen(false);
    setChapter4MaintenanceDiagnosisPending(false);
    setChapter4MaintenanceDiagnosisFeedback(null);
  }, [state.chapter4.factIds, state.chapter4.phase]);

  useEffect(() => {
    events.emit("rpg_chapter4_power_panel_open_state_changed", {
      open: chapter4PowerPanelOpen,
      openRequestId: chapter4PowerPanelSession?.openRequestId ?? null,
      targetId: chapter4PowerPanelSession?.targetId ?? null
    });
    return () => {
      if (chapter4PowerPanelOpen) {
        events.emit("rpg_chapter4_power_panel_open_state_changed", { open: false });
      }
    };
  }, [chapter4PowerPanelOpen, chapter4PowerPanelSession, events]);

  useEffect(() => {
    const active = runtimeScene === "duan_yongping_temporal_maze"
      && state.chapter4.phase === "exterior_closure"
      && !state.chapter4.completed;
    if (active && chapter4ClosureSessionIdRef.current === null) {
      const sessionId = chapter4ClosureRegistry.beginSession();
      chapter4ClosureSessionIdRef.current = sessionId;
      setChapter4ClosureSessionId(sessionId);
      setChapter4ClosureFeedback(null);
      return;
    }
    if (!active && chapter4ClosureSessionIdRef.current !== null) {
      chapter4ClosureRegistry.cancelSession(chapter4ClosureSessionIdRef.current);
      chapter4ClosureSessionIdRef.current = null;
      chapter4ClosurePendingRequestRef.current = null;
      setChapter4ClosureSessionId(null);
      setChapter4ClosureFeedback(null);
    }
  }, [chapter4ClosureRegistry, runtimeScene, state.chapter4.completed, state.chapter4.phase]);

  const completeChapterFourClosure = useCallback((sessionId: string) => {
    if (chapter4ClosureSessionIdRef.current !== sessionId
      || chapter4ClosurePendingRequestRef.current !== null) return;
    const proof = chapter4ClosureRegistry.completeSession(sessionId);
    if (!proof) {
      setChapter4ClosureFeedback("灯光收束未完成，正在重新播放。");
      return;
    }
    const requestId = `host-closure-${++chapter4IntentRequestSerialRef.current}`;
    chapter4ClosurePendingRequestRef.current = requestId;
    events.emit("rpg_chapter4_755_intent_requested", {
      requestId,
      intent: { type: "acknowledge_exterior_closure", proof }
    });
  }, [chapter4ClosureRegistry, events]);

  useEffect(() => {
    return events.subscribe((event) => {
      if (event.name !== "rpg_chapter4_755_intent_resolved") return;
      const requestId = String(event.payload?.requestId ?? "");
      if (!requestId || requestId !== chapter4ClosurePendingRequestRef.current) return;
      chapter4ClosurePendingRequestRef.current = null;
      const result = event.payload?.result;
      const accepted = typeof result === "object"
        && result !== null
        && (result as { accepted?: unknown }).accepted === true;
      if (accepted) {
        setChapter4ClosureFeedback(null);
        return;
      }
      const currentSessionId = chapter4ClosureSessionIdRef.current;
      if (currentSessionId) chapter4ClosureRegistry.cancelSession(currentSessionId);
      const retrySessionId = chapter4ClosureRegistry.beginSession();
      chapter4ClosureSessionIdRef.current = retrySessionId;
      setChapter4ClosureSessionId(retrySessionId);
      setChapter4ClosureFeedback(String(
        event.payload?.feedback ?? "灯光收束确认未写入，已重新播放。"
      ));
    });
  }, [chapter4ClosureRegistry, events]);

  useEffect(() => {
    return () => {
      const sessionId = chapter4ClosureSessionIdRef.current;
      if (sessionId) chapter4ClosureRegistry.cancelSession(sessionId);
      chapter4ClosureSessionIdRef.current = null;
      chapter4ClosurePendingRequestRef.current = null;
    };
  }, [chapter4ClosureRegistry]);

  useEffect(() => {
    return events.subscribe((event) => {
      if (event.name !== "rpg_chapter4_story_input_lock_changed") return;
      const locked = event.payload?.locked === true;
      setChapter4InteractionBlocked(locked);
      setChapter4ScenePointerAllowed(locked && event.payload?.allowScenePointer === true);
      setChapter4SceneKeyboardAllowed(locked && event.payload?.allowSceneKeyboard === true);
    });
  }, [events]);

  useEffect(() => {
    if (inspectedMapItem && !state.items[inspectedMapItem]) {
      setInspectedMapItem(null);
    }
  }, [inspectedMapItem, state.items]);
  const coarsePointer = useMediaQuery(RPG_TOUCH_CONTROLS_QUERY);
  const touchControls = coarsePointer
    || (typeof navigator !== "undefined" && navigator.maxTouchPoints > 0);
  const bindShellRef = useCallback((node: HTMLElement | null) => {
    shellRef.current = node;
    setShellRoot((current) => current === node ? current : node);
  }, []);
  const selectDraggedRpgItem = useCallback((itemId: ItemId | null) => {
    store.setState((current) => current.ui.selectedItem === itemId
      ? current
      : { ...current, ui: { ...current.ui, selectedItem: itemId } });
  }, [store]);

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
        .map(([, SceneClass]) => SceneClass)
    ];
    let stopAdaptiveResolution: () => void = () => undefined;
    const game = new Phaser.Game({
      type: Phaser.CANVAS,
      parent: host,
      width: RPG_LOGICAL_WIDTH,
      height: RPG_LOGICAL_HEIGHT,
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
          stopAdaptiveResolution = installRpgAdaptiveResolution(phaserGame, host);
          setRpgInputEnabled(phaserGame, !inputBlockedRef.current);
          if (!inputBlockedRef.current) setRpgKeyboardEnabled(phaserGame, !keyboardBlockedRef.current);
          bridge.emit("rpg_runtime_ready");
          const target = resolveRuntimeSceneKey(store.getState());
          activateRpgScene(phaserGame, target);
          if (!inputBlockedRef.current && !keyboardBlockedRef.current) {
            window.requestAnimationFrame(() => focusRpgCanvas(phaserGame));
          }
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
      stopAdaptiveResolution();
      game.destroy(true);
      clearRpgCanvasHost(host);
    };
  }, [bridge, store, theaterRuntimePort]);

  useEffect(() => {
    const game = gameRef.current;
    if (!game) {
      return undefined;
    }
    if (inputBlocked || itemInspectOpen || canteenExclusiveActive || chapter4PhaserInputBlocked
      || photoSessionOpen || qizhenRainRescueCinematicOpen) {
      setRpgInputEnabled(game, false);
      events.emit("rpg_direction_changed", { x: 0, y: 0 });
      return undefined;
    }

    setRpgInputEnabled(game, true);
    setRpgKeyboardEnabled(game, !keyboardBlocked && !chapter4PhaserKeyboardBlocked);
    if (keyboardBlocked || chapter4PhaserKeyboardBlocked) {
      events.emit("rpg_direction_changed", { x: 0, y: 0 });
    }
    const frame = window.requestAnimationFrame(() => {
      if (gameRef.current) {
        setRpgInputEnabled(gameRef.current, true);
        setRpgKeyboardEnabled(gameRef.current, !keyboardBlocked && !chapter4PhaserKeyboardBlocked);
        if (!keyboardBlocked && !chapter4PhaserKeyboardBlocked) {
          focusRpgCanvas(gameRef.current);
        }
      }
    });
    return () => {
      window.cancelAnimationFrame(frame);
    };
  }, [canteenExclusiveActive, chapter4PhaserInputBlocked, chapter4PhaserKeyboardBlocked, events, inputBlocked,
    itemInspectOpen, keyboardBlocked, photoSessionOpen, qizhenRainRescueCinematicOpen]);

  useEffect(() => {
    const game = gameRef.current;
    const sceneKey = resolveRuntimeSceneKey(state);
    if (!game?.isBooted) return undefined;

    activateRpgScene(game, sceneKey);
    const syncActivatedSceneInput = () => {
      if (gameRef.current !== game) return;
      const blocked = inputBlockedRef.current;
      setRpgInputEnabled(game, !blocked);
      if (!blocked) {
        setRpgKeyboardEnabled(game, !keyboardBlockedRef.current);
        if (!keyboardBlockedRef.current) focusRpgCanvas(game);
      }
    };
    // A stopped Phaser Scene retains its KeyboardPlugin.enabled value. If it
    // was stopped while DEV or another host overlay held input, starting it
    // later does not retrigger the React blocker effect. Apply the current host
    // contract both now and after Phaser has completed the activation frame.
    syncActivatedSceneInput();
    const frame = window.requestAnimationFrame(syncActivatedSceneInput);
    return () => window.cancelAnimationFrame(frame);
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
      if (event.name !== "rpg_chapter4_755_intent_requested") return;
      const validation = validateChapterFour755IntentRequest(event.payload);
      const rejectRequest = (
        reason: "invalid_request" | "duplicate_request" | "invalid_intent" | "system_failure",
        feedback: string
      ) => {
        console.debug(`[chapter4-755] ${reason}: ${feedback}`);
        const requestId = validation.valid ? validation.request.requestId : validation.requestId;
        const playerFeedback = "交互失败，请重新靠近目标后重试。";
        const result = {
          accepted: false,
          changed: false,
          reason,
          intentType: "invalid",
          previousPhase: null,
          phase: null
        };
        events.emit("rpg_chapter4_755_intent_resolved", {
          requestId,
          result,
          projection: selectChapterFourMazeProjection(store.getState()),
          feedback: playerFeedback
        });
        events.emit("rpg_chapter4_755_intent_feedback", {
          requestId,
          reason,
          feedback: playerFeedback
        });
      };
      if (!validation.valid) {
        rejectRequest(
          validation.reason,
          validation.reason === "invalid_request"
            ? "教学楼交互请求缺少有效编号或包含多余字段。请重试。"
            : "当前教学楼交互请求无效。"
        );
        return;
      }
      const { requestId, intent, runtimeTarget } = validation.request;
      if (chapter4ResolvedRequestIdsRef.current.has(requestId)) {
        rejectRequest("duplicate_request", "这次教学楼交互已经处理，未重复写入。");
        return;
      }
      if (intent.type === "complete_prologue_handoff") {
        chapter4ResolvedRequestIdsRef.current.add(requestId);
        rejectRequest(
          "invalid_intent",
          "第四章序幕交接仅由 App gate 提交。"
        );
        return;
      }
      let trustedIntent: ChapterFour755Intent = intent;
      if ("targetId" in intent) {
        const prepared = resolveChapterFour755SpatialAttestationTarget(
          intent.targetId,
          runtimeTarget
        );
        const attestationId = `host-spatial-${++chapter4IntentRequestSerialRef.current}`;
        const emitAttestationFailure = (
          reason: ChapterFour755SpatialAttestationFailure | "target_context_invalid"
        ) => {
          try {
            events.emit("rpg_chapter4_755_spatial_attestation_failed", {
              requestId,
              attestationId,
              targetId: intent.targetId,
              reason
            });
          } catch {
            // Debug reporting cannot change the zero-write rejection.
          }
          chapter4ResolvedRequestIdsRef.current.add(requestId);
          rejectRequest(
            "invalid_request",
            "当前交互位置无法由活动场景重新确认，请靠近可见目标后重试。"
          );
        };
        if (!prepared) {
          emitAttestationFailure("target_context_invalid");
          return;
        }
        const request: ChapterFour755SpatialAttestationRequest = {
          requestId,
          attestationId,
          sceneKey: CHAPTER_FOUR_755_SCENE_KEY,
          committedPhase: store.getState().chapter4.phase as ChapterFour755SpatialAttestationRequest["committedPhase"],
          targetId: prepared.context.targetId,
          entityId: prepared.context.entityId,
          bounds: { ...prepared.context.bounds }
        };
        const responses: unknown[] = [];
        const unsubscribeAttestation = events.subscribe((attestationEvent) => {
          if (attestationEvent.name === "rpg_chapter4_755_spatial_attestation_response") {
            responses.push(attestationEvent.payload);
          }
        });
        try {
          events.emit("rpg_chapter4_755_spatial_attestation_requested", { ...request });
        } catch {
          // The result below becomes no_response. The listener is still
          // removed in finally, so a failed producer cannot leak responders.
        } finally {
          unsubscribeAttestation();
        }
        const revalidation = revalidateChapterFour755SpatialAttestation({
          request,
          responses,
          target: prepared.contract,
          claimedSpatial: intent.spatial
        });
        if (!revalidation.accepted) {
          emitAttestationFailure(revalidation.reason);
          return;
        }
        trustedIntent = { ...intent, spatial: revalidation.spatial } as ChapterFour755Intent;
      } else if (runtimeTarget !== undefined) {
        chapter4ResolvedRequestIdsRef.current.add(requestId);
        rejectRequest("invalid_request", "无目标交互不得携带运行时几何。");
        return;
      }
      const sessionResolution = resolveChapterFour755SessionRequest(
        chapter4ResolvedRequestIdsRef.current,
        requestId,
        () => chapter4Controller.resolve755Intent(trustedIntent, runtimeTarget)
      );
      if (sessionResolution.status === "duplicate") {
        rejectRequest("duplicate_request", "这次教学楼交互已经处理，未重复写入。");
        return;
      }
      if (sessionResolution.status === "failed") {
        rejectRequest("system_failure", "教学楼交互处理失败，请重试。");
        return;
      }
      const result = sessionResolution.result;
      const feedback = chapterFour755Feedback(result, trustedIntent.type);
      const presentationOwner = CHAPTER_FOUR_755_PRESENTATION_HANDSHAKE_INTENTS.has(trustedIntent.type)
        ? "scene_or_overlay"
        : "controller_feedback";
      const projection = selectChapterFourMazeProjection(store.getState());
      if (trustedIntent.type === "open_power_panel"
        && result.accepted
        && runtimeTarget
        && runtimeTarget.targetId === "a1_power_panel"
        && trustedIntent.spatial.distance === "within_range") {
        setChapter4PowerPanelFeedback(null);
        setChapter4PowerPanelSession({
          openRequestId: requestId,
          targetId: "a1_power_panel",
          spatial: { distance: "within_range" },
          runtimeTarget
        });
        try {
          events.emit("power_panel_opened", {
            requestId,
            targetId: "a1_power_panel",
            bounds: runtimeTarget.bounds
          });
        } catch {
          // Presentation/audio listeners cannot block the accepted panel session.
        }
      }
      events.emit("rpg_chapter4_755_intent_resolved", {
        requestId,
        intentType: trustedIntent.type,
        result,
        projection,
        feedback,
        presentationOwner
      });
      events.emit("rpg_chapter4_755_intent_feedback", {
        requestId,
        intentType: trustedIntent.type,
        reason: result.reason,
        ...(result.detailCode ? { detailCode: result.detailCode } : {}),
        feedback,
        presentationOwner
      });
    });
  }, [chapter4Controller, events, store]);

  useEffect(() => {
    return events.subscribe((event) => {
      if (event.name !== "rpg_chapter4_755_intent_resolved") return;
      const requestId = String(event.payload?.requestId ?? "");
      if (!requestId || requestId !== chapter4PowerPanelPendingRequestRef.current) return;
      chapter4PowerPanelPendingRequestRef.current = null;
      setChapter4PowerPanelPending(false);
      const result = event.payload?.result;
      const accepted = typeof result === "object"
        && result !== null
        && (result as { accepted?: unknown }).accepted === true;
      const intentType = String(event.payload?.intentType ?? "");
      if (!accepted) {
        setChapter4PowerPanelFeedback(
          String(event.payload?.feedback ?? "配电请求未被接受，请重试。")
        );
        return;
      }
      if (intentType === "lock_light_grid") {
        setChapter4PowerPanelFeedback("配电结果已锁定。");
        setChapter4PowerPanelSession(null);
        return;
      }
      setChapter4PowerPanelFeedback("区域供电状态已同步。");
    });
  }, [events]);

  const submitChapterFourPowerPanelIntent = useCallback((
    intent: { type: "toggle_light_zone"; zoneId: ChapterFourLightZoneId }
      | { type: "lock_light_grid" }
  ) => {
    const session = chapter4PowerPanelSession;
    if (!session || chapter4PowerPanelPendingRequestRef.current !== null) return;
    const requestId = `host-power-panel-${++chapter4IntentRequestSerialRef.current}`;
    chapter4PowerPanelPendingRequestRef.current = requestId;
    setChapter4PowerPanelPending(true);
    setChapter4PowerPanelFeedback(null);
    events.emit("rpg_chapter4_755_intent_requested", {
      requestId,
      intent: {
        ...intent,
        targetId: session.targetId,
        spatial: session.spatial
      },
      runtimeTarget: session.runtimeTarget
    });
  }, [chapter4PowerPanelSession, events]);

  const closeChapterFourPowerPanel = useCallback(() => {
    if (chapter4PowerPanelPendingRequestRef.current !== null
      || store.getState().chapter4.lightGrid.locked) return;
    setChapter4PowerPanelSession(null);
    setChapter4PowerPanelFeedback(null);
  }, [store]);

  useEffect(() => {
    return events.subscribe((event) => {
      if (event.name !== "rpg_chapter4_755_intent_resolved") return;
      const requestId = String(event.payload?.requestId ?? "");
      if (!requestId || requestId !== chapter4MaintenanceDiagnosisPendingRequestRef.current) return;
      chapter4MaintenanceDiagnosisPendingRequestRef.current = null;
      setChapter4MaintenanceDiagnosisPending(false);
      const result = event.payload?.result;
      const accepted = typeof result === "object"
        && result !== null
        && (result as { accepted?: unknown }).accepted === true;
      if (!accepted) {
        setChapter4MaintenanceDiagnosisFeedback("三项判断中仍有矛盾，请重新核对现场现象。");
        return;
      }
      setChapter4MaintenanceDiagnosisFeedback(null);
      setChapter4MaintenanceDiagnosisOpen(false);
    });
  }, [events]);

  const submitChapterFourMaintenanceDiagnosis = useCallback((answers: ChapterFourMaintenanceDiagnosisAnswers) => {
    if (chapter4MaintenanceDiagnosisPendingRequestRef.current) return;
    const requestId = `host-maintenance-diagnosis-${++chapter4IntentRequestSerialRef.current}`;
    chapter4MaintenanceDiagnosisPendingRequestRef.current = requestId;
    setChapter4MaintenanceDiagnosisPending(true);
    setChapter4MaintenanceDiagnosisFeedback(null);
    events.emit("rpg_chapter4_755_intent_requested", {
      requestId,
      intent: { type: "complete_maintenance_diagnosis", answers }
    });
  }, [events]);

  const closeChapterFourMaintenanceDiagnosis = useCallback(() => {
    if (chapter4MaintenanceDiagnosisPendingRequestRef.current) return;
    setChapter4MaintenanceDiagnosisFeedback(null);
    setChapter4MaintenanceDiagnosisOpen(false);
  }, []);

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
          detail: result === "rule" ? "清洁车锁需要浅色操作。" : undefined
        });
      } else if (event.name === "rpg_canteen_bike_requested") {
        const result = canteenController.payForBike();
        events.emit("rpg_item_use_feedback", {
          itemId: "cafeteriaWages",
          reason: result === "paid" ? "accepted" : "locked",
          targetLabel: "共享单车",
          detail: result === "rule" ? "付款需要浅色操作，且车锁表面已经清洁。" : undefined
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
            : "扫描票据需要浅色操作、临时观演票和当前道具布置阶段。"
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
        const beforeEntry = store.getState();
        const entered = qizhenController.enterLake();
        if (!entered && beforeEntry.qizhenLake.phase === "rain_recovery" && !beforeEntry.qizhenLake.rainSafetyCleared) {
          events.emit("rpg_subtitle", {
            text: qizhenLakeContent.dock.rainReturnBlocked,
            tone: "dialogue",
            durationMs: 4800
          });
        }
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
      } else if (event.name === "rpg_qizhen_safety_officer_requested") {
        qizhenController.requestDockSafetyClearance();
      } else if (event.name === "rpg_qizhen_rain_rescue_cinematic_requested") {
        setQizhenRainRescueCinematicOpen(true);
      } else if (event.name === "rpg_qizhen_rain_rescue_completed_requested") {
        const result = qizhenController.completeRainRescue();
        if (result === "accepted") {
          events.emit("toast", {
            text: "你被救起并送回寝室。先找到吹风机。",
            tone: "task",
            durationMs: 4200
          });
        }
      } else if (event.name === "rpg_qizhen_hair_dryer_requested") {
        qizhenController.collectHairDryer();
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
      } else if (event.name === "rpg_qizhen_swan_branch_requested") {
        const result = qizhenController.completeSwanBranch();
        emitQizhenItemFeedback(events, "fishingRod", result, "黑天鹅围栏");
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
            events.emit(
              spotId === "paper" ? "qizhen_fishing_paper_completed" : "qizhen_fishing_catch_completed",
              {
                sessionId,
                spotId,
                grade: fishingResult?.grade ?? "C",
                accuracy: fishingResult?.accuracy ?? 0
              }
            );
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

  const completeQizhenRainRescueCinematic = useCallback((result: QizhenRainRescueCinematicResult) => {
    setQizhenRainRescueCinematicOpen(false);
    events.emit("rpg_qizhen_rain_rescue_cinematic_completed", { result });
    window.requestAnimationFrame(() => gameRef.current?.canvas.focus());
  }, [events]);

  const updatePhotoSession = useCallback((next: QizhenPhotoSessionState | null) => {
    photoSessionRef.current = next;
    setPhotoSession(next);
  }, []);

  const emitPhotoSessionFeedback = useCallback((reason: QizhenPhotoCaptureRejection | QizhenJournalDraftRejection) => {
    // 用 toast 而不是 rpg_subtitle:会话打开期间字幕层被遮蔽,toast 在两种布局下都可见。
    events.emit("toast", { text: QIZHEN_PHOTO_SESSION_FEEDBACK[reason], tone: "system", durationMs: 3200 });
  }, [events]);

  // 相机桥:场景冻结帧请求 → controller 只读预检 → 挂载覆盖层并回发 opened。
  // 拒绝时经既有 toast 反馈原因;会话期间场景自锁,host 侧再闸住 Phaser 输入。
  useEffect(() => {
    return events.subscribe((event) => {
      if (event.name !== "qizhen_photo_session_requested") return;
      const payload = event.payload;
      const spotId = String(payload?.spotId ?? "") as QizhenPhotoSpotId;
      const recipe = payload?.recipe;
      if (!recipe || typeof recipe !== "object") return;
      const precheck = qizhenController.precheckPhotoCapture(spotId);
      if (!precheck.accepted) {
        emitPhotoSessionFeedback(precheck.reason);
        return;
      }
      kayakPaddleGesturesRef.current.clear();
      setKayakPaddleSwipeState({});
      const capturedAtSeconds = Number(payload?.capturedAtSeconds);
      updatePhotoSession({
        session: {
          spotId: precheck.spotId,
          recipe: recipe as QizhenPhotoRecipe,
          speed: Number(payload?.speed ?? 0),
          roll: Number(payload?.roll ?? 0),
          kind: String(payload?.kind ?? "spot") === "main" ? "main" : "spot"
        },
        capturedAtSeconds: Number.isInteger(capturedAtSeconds) && capturedAtSeconds >= 0
          ? capturedAtSeconds
          : undefined,
        photo: null,
        draft: null
      });
      events.emit("qizhen_photo_session_opened", { spotId: precheck.spotId });
    });
  }, [emitPhotoSessionFeedback, events, qizhenController, updatePhotoSession]);

  const handlePhotoShutter = useCallback(() => {
    const current = photoSessionRef.current;
    if (!current) return;
    const result = qizhenController.capturePhoto({
      ...current.session,
      capturedAtSeconds: current.capturedAtSeconds
    });
    if (!result.accepted) {
      emitPhotoSessionFeedback(result.reason);
      return;
    }
    updatePhotoSession({ ...current, photo: result.photo, draft: result.draft });
  }, [emitPhotoSessionFeedback, qizhenController, updatePhotoSession]);

  const handlePhotoDraftUpdate = useCallback((
    patch: Partial<Pick<QizhenJournalDraft, "titleId" | "statusId" | "captionId">>
  ) => {
    const current = photoSessionRef.current;
    if (!current?.draft) return;
    updatePhotoSession({ ...current, draft: { ...current.draft, ...patch } });
  }, [updatePhotoSession]);

  const handlePhotoDraftSave = useCallback(() => {
    const current = photoSessionRef.current;
    if (!current?.draft) return;
    const result = qizhenController.saveJournalDraft(current.draft);
    if (!result.accepted) {
      emitPhotoSessionFeedback(result.reason);
      return;
    }
    updatePhotoSession({ ...current, draft: result.draft });
  }, [emitPhotoSessionFeedback, qizhenController, updatePhotoSession]);

  const handlePhotoRetake = useCallback(() => {
    const current = photoSessionRef.current;
    if (!current) return;
    // 重拍丢弃当前未提交的照片与草稿,回到取景;存档不保留孤儿照片。
    qizhenController.discardJournalDraft("retake");
    updatePhotoSession({ ...current, photo: null, draft: null });
  }, [qizhenController, updatePhotoSession]);

  const closePhotoSession = useCallback(() => {
    const current = photoSessionRef.current;
    if (!current) return;
    // 关闭会话:丢弃未存草稿(已存草稿保留,供 CC98 发布),通知场景恢复输入。
    qizhenController.discardJournalDraft("close");
    updatePhotoSession(null);
    events.emit("qizhen_photo_session_closed", { spotId: current.session.spotId });
    window.requestAnimationFrame(() => gameRef.current?.canvas.focus());
  }, [events, qizhenController, updatePhotoSession]);

  useEffect(() => events.subscribe((event) => {
    if (event.name !== "developer_checkpoint_applied") return;

    const inputRestoreSerial = ++developerCheckpointInputRestoreSerialRef.current;
    const game = gameRef.current;
    if (game?.isBooted) setRpgInputEnabled(game, false);
    events.emit("rpg_direction_changed", { x: 0, y: 0 });

    activeDirectionPointerRef.current = null;
    if (directionStopTimerRef.current !== null) {
      window.clearTimeout(directionStopTimerRef.current);
      directionStopTimerRef.current = null;
    }
    kayakPaddleGesturesRef.current.clear();
    setKayakPaddleSwipeState({});
    pendingFishingRef.current = null;
    setFishingSession(null);

    const currentPhotoSession = photoSessionRef.current;
    if (currentPhotoSession) {
      qizhenController.discardJournalDraft("close");
      photoSessionRef.current = null;
      setPhotoSession(null);
      events.emit("qizhen_photo_session_closed", { spotId: currentPhotoSession.session.spotId });
    }
    setQizhenRainRescueCinematicOpen(false);
    setInspectedMapItem(null);
    archivedRuleRevealPendingRef.current = false;

    chapter4ResolvedRequestIdsRef.current.clear();
    chapter4PowerPanelPendingRequestRef.current = null;
    chapter4InsertedPuzzlePendingRequestRef.current = null;
    chapter4MaintenanceDiagnosisPendingRequestRef.current = null;
    chapter4StairPendingRequestRef.current = null;
    chapter4ClosurePendingRequestRef.current = null;
    const closureSessionId = chapter4ClosureSessionIdRef.current;
    if (closureSessionId) chapter4ClosureRegistry.cancelSession(closureSessionId);
    chapter4ClosureSessionIdRef.current = null;
    chapter4StairPausedSceneKeysRef.current.clear();
    setChapter4InteractionBlocked(false);
    setChapter4ScenePointerAllowed(false);
    setChapter4SceneKeyboardAllowed(false);
    setChapter4PowerPanelSession(null);
    setChapter4PowerPanelPending(false);
    setChapter4PowerPanelFeedback(null);
    setChapter4InsertedPuzzleSession(null);
    setChapter4InsertedPuzzlePending(false);
    setChapter4InsertedPuzzleFeedback(null);
    setChapter4MaintenanceDiagnosisOpen(false);
    setChapter4MaintenanceDiagnosisPending(false);
    setChapter4MaintenanceDiagnosisFeedback(null);
    setChapter4StairActive(false);
    setChapter4StairFeedback(null);
    setChapter4ClosureSessionId(null);
    setChapter4ClosureFeedback(null);

    store.setState((current) => current.ui.selectedItem === null
      ? current
      : { ...current, ui: { ...current.ui, selectedItem: null } });

    if (!game?.isBooted || event.payload?.runtimeMode !== "rpg") return;
    const target = resolveRuntimeSceneKey(store.getState());
    restartRpgScene(game, target);
    const restoreDeveloperCheckpointInput = (attemptsRemaining: number) => {
      window.requestAnimationFrame(() => {
        if (
          gameRef.current !== game
          || developerCheckpointInputRestoreSerialRef.current !== inputRestoreSerial
        ) return;
        // The DEV click closes its React overlay and restarts Phaser in one
        // browser event. The overlay state can commit one or more frames after
        // this handler, so a single-frame check can permanently leave
        // game.input disabled. Wait only while a real host blocker remains.
        if (inputBlockedRef.current) {
          if (attemptsRemaining > 0) restoreDeveloperCheckpointInput(attemptsRemaining - 1);
          return;
        }
        setRpgInputEnabled(game, true);
        setRpgKeyboardEnabled(game, !keyboardBlockedRef.current);
        if (!keyboardBlockedRef.current) focusRpgCanvas(game);
      });
    };
    restoreDeveloperCheckpointInput(12);
  }), [chapter4ClosureRegistry, events, qizhenController, store]);

  // 方案三.2/四 Task 4:页面隐藏视同关闭会话;离开湖区场景同理。
  useEffect(() => {
    if (!photoSessionOpen) return undefined;
    const handleVisibility = () => {
      if (document.hidden) closePhotoSession();
    };
    document.addEventListener("visibilitychange", handleVisibility);
    return () => document.removeEventListener("visibilitychange", handleVisibility);
  }, [closePhotoSession, photoSessionOpen]);

  useEffect(() => {
    if (photoSessionOpen && runtimeScene !== "qizhen_lake") closePhotoSession();
  }, [closePhotoSession, photoSessionOpen, runtimeScene]);

  // 宿主卸载(如切回手机模式)视同关闭:未存草稿不残留,已存草稿保留。
  useEffect(() => {
    return () => {
      if (photoSessionRef.current) {
        qizhenController.discardJournalDraft("close");
        events.emit("qizhen_photo_session_closed", { spotId: photoSessionRef.current.session.spotId });
        photoSessionRef.current = null;
      }
    };
  }, [events, qizhenController]);

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
      if (!inputBlocked && !itemInspectOpen && !keyboardBlocked && !chapter4OverlayBlocked
        && !photoSessionOpen && !qizhenRainRescueCinematicOpen
        && event.key.toLowerCase() === "f" && !event.metaKey && !event.ctrlKey && !event.altKey) {
        toggleRpgFullscreen();
      }
    };
    window.addEventListener("keydown", handleFullscreenKey);
    return () => window.removeEventListener("keydown", handleFullscreenKey);
  }, [chapter4OverlayBlocked, inputBlocked, itemInspectOpen, keyboardBlocked, photoSessionOpen,
    qizhenRainRescueCinematicOpen]);

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
      className={`rpg-stage ${runtimeScene === "campus_bootstrap" || runtimeScene === "campus_qizhen_loop" ? "is-campus-map" : ""} ${runtimeScene === "campus_qizhen_loop" ? "is-qizhen-approach" : ""} ${runtimeScene === "library_interior" ? "is-library-interior" : ""} ${runtimeScene === "canteen_interior" ? "is-canteen-interior" : ""} ${runtimeScene === "theater_interior" ? "is-theater-interior" : ""} ${runtimeScene === "qizhen_lake" ? "is-qizhen-lake" : ""} ${runtimeScene === "duan_yongping_temporal_maze" ? `is-chapter-four-temporal-maze is-chapter-four-mode-${state.chapter4.mode}` : ""} ${runtimeScene === "campus_bootstrap" && state.canteenHunt.phase === "chase_ready" ? "is-canteen-bike" : ""} ${chaseActive ? "is-canteen-chase" : ""} ${embedded ? "is-embedded" : ""}`.trim()}
      aria-label="7:55 RPG runtime"
      data-input-blocked={inputBlocked || itemInspectOpen || chapter4OverlayBlocked || photoSessionOpen
        || qizhenRainRescueCinematicOpen ? "true" : "false"}
      data-keyboard-blocked={keyboardBlocked || chapter4OverlayBlocked || photoSessionOpen
        || qizhenRainRescueCinematicOpen ? "true" : "false"}
      data-rpg-engine={chapter4StairActive ? "three" : "phaser"}
      data-rpg-engine-reason={chapter4StairActive ? "chapter4_misaligned_stair" : "web_runtime_only"}
      data-reality-mode={runtimeScene === "duan_yongping_temporal_maze"
        ? state.chapter4.mode
        : undefined}
      data-canteen-handoff={canteenStartTransitionActive
        ? "start"
        : canteenChaseRunActive
          ? "ride"
          : canteenFinishTransitionActive
            ? "finish"
            : "none"}
    >
      <section ref={bindShellRef} className="rpg-shell" aria-label="7:55 横屏游戏">
        <div ref={hostRef} className="rpg-canvas-host">
          <div ref={phaserHostRef} className={`rpg-phaser-host${chapter4StairActive ? " is-suspended" : ""}`} />
          {chapter4StairActive ? (
            <ChapterFourStairPuzzleOverlay
              events={events}
              feedback={chapter4StairFeedback}
              onComplete={completeChapterFourStair}
              onExit={() => {
                if (chapter4StairPendingRequestRef.current) return;
                setChapter4StairFeedback(null);
                setChapter4StairActive(false);
              }}
            />
          ) : null}
        </div>

        {canteenStartTransitionActive ? (
          <CanteenBikeTransitionOverlay
            stage="start"
            onComplete={() => { canteenController.startChase(); }}
          />
        ) : canteenChaseRunActive ? (
          <CanteenChaseOverlay
            events={events}
            onAttempt={(attempt) => { canteenController.resolveChaseAttempt(attempt); }}
          />
        ) : canteenFinishTransitionActive ? (
          <CanteenBikeTransitionOverlay
            stage="finish"
            onComplete={() => { canteenController.completeChase(); }}
          />
        ) : null}

        {qizhenRainRescueCinematicOpen ? (
          <QizhenRainRescueCinematic onComplete={completeQizhenRainRescueCinematic} />
        ) : null}

        {chapter4ClosureSessionId ? (
          <ChapterFourStarLampClosure
            key={chapter4ClosureSessionId}
            sessionId={chapter4ClosureSessionId}
            feedback={chapter4ClosureFeedback}
            onComplete={completeChapterFourClosure}
          />
        ) : null}

        {chapter4InsertedPuzzleSession ? (
          <ChapterFourInsertedPuzzleGame
            puzzleId={chapter4InsertedPuzzleSession.puzzleId}
            mode={chapter4InsertedPuzzleSession.mode}
            completed={chapter4InsertedPuzzleSession.completed}
            prerequisiteReady={chapter4InsertedPuzzleSession.prerequisiteReady}
            pending={chapter4InsertedPuzzlePending}
            feedback={chapter4InsertedPuzzleFeedback}
            onSubmit={submitChapterFourInsertedPuzzle}
            onClose={closeChapterFourInsertedPuzzle}
          />
        ) : null}

        {chapter4PowerPanelSession ? (
          <ChapterFourPowerPanelGame
            mask={state.chapter4.lightGrid.mask}
            locked={state.chapter4.lightGrid.locked}
            pending={chapter4PowerPanelPending}
            feedback={chapter4PowerPanelFeedback}
            onToggle={(zoneId) => submitChapterFourPowerPanelIntent({
              type: "toggle_light_zone",
              zoneId
            })}
            onLock={() => submitChapterFourPowerPanelIntent({ type: "lock_light_grid" })}
            onClose={closeChapterFourPowerPanel}
          />
        ) : null}

        {chapter4MaintenanceDiagnosisOpen ? (
          <ChapterFourMaintenanceDiagnosisGame
            pending={chapter4MaintenanceDiagnosisPending}
            feedback={chapter4MaintenanceDiagnosisFeedback}
            onSubmit={submitChapterFourMaintenanceDiagnosis}
            onClose={closeChapterFourMaintenanceDiagnosis}
          />
        ) : null}


        {photoSession ? (
          <div className="rpg-overlay-layer qizhen-journal-camera-overlay" role="dialog" aria-modal="true" aria-label={QIZHEN_CAMERA_TITLE}>
            <QizhenJournalCamera
              session={photoSession.session}
              photo={photoSession.photo}
              draft={photoSession.draft}
              onShutter={handlePhotoShutter}
              onUpdateDraft={handlePhotoDraftUpdate}
              onSaveDraft={handlePhotoDraftSave}
              onRetake={handlePhotoRetake}
              onClose={closePhotoSession}
            />
          </div>
        ) : null}

        {showTaskBar && !canteenExclusiveActive && !chapter4OverlayBlocked && !photoSessionOpen
          && !qizhenRainRescueCinematicOpen && (!chapter4MazeActive || chapter4MazeUiActive) ? (
          <QuestTaskBar
            state={state}
            events={events}
            router={router}
            variant="rpg"
            portalRoot={shellRoot}
            onNavigate={onTaskNavigate}
          />
        ) : null}

        {qizhenRainRescueCinematicOpen || photoSessionOpen || chapter4OverlayBlocked ? null : (
          <div className="rpg-system-actions">
            <button type="button" onClick={returnToPhone}>{desktopSplit ? "聚焦手机" : "返回手机主页"}</button>
            <button type="button" onClick={() => toggleRpgFullscreen()}>全屏</button>
          </div>
        )}

        {runtimeScene === "campus_bootstrap" && !canteenExclusiveActive ? (
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
            onToggle={() => events.emit("rpg_canteen_mode_requested", {
              mode: state.canteenHunt.mode === "dark" ? "light" : "dark"
            })}
          />
        ) : null}

        {runtimeScene === "theater_interior" && ["entry_ticket", "program_search", "prop_setup", "spotlight_ready", "spotlight_hunt"].includes(state.theaterHunt.phase) ? (
          <RpgRealityModeToggle
            className="rpg-theater-mode-toggle"
            mode={state.theaterHunt.mode}
            onToggle={() => events.emit("rpg_theater_mode_requested", {
              mode: state.theaterHunt.mode === "dark" ? "light" : "dark"
            })}
          />
        ) : null}

        {runtimeScene === "qizhen_lake" && !fishingSession && !photoSessionOpen
          && !qizhenRainRescueCinematicOpen
          && ["dock_outfitting", "boarding_tutorial", "lake_exploration", "tool_chain", "swan_exchange", "paper_capture"].includes(state.qizhenLake.phase) ? (
          <RpgRealityModeToggle
            className="rpg-qizhen-mode-toggle"
            mode={state.qizhenLake.mode}
            onToggle={() => events.emit("rpg_qizhen_mode_requested", {
              mode: state.qizhenLake.mode === "dark" ? "light" : "dark"
            })}
          />
        ) : null}

        {chapter4MazeUiActive && !chapter4OverlayBlocked ? (
          <RpgRealityModeToggle
            mode={state.chapter4.mode}
            onToggle={() => events.emit("rpg_chapter4_755_intent_requested", {
              requestId: `host-mode-${++chapter4IntentRequestSerialRef.current}`,
              intent: {
                type: "set_mode",
                mode: state.chapter4.mode === "dark" ? "light" : "dark"
              }
            })}
          />
        ) : null}

        {!inputBlocked && ((state.actOne.inventoryRecovered && state.items.campusCard) || state.items.gamepad) && runtimeScene === "campus_bootstrap" && !canteenExclusiveActive ? (
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

        {!chapter4OverlayBlocked && !fishingSession && !photoSessionOpen && !qizhenRainRescueCinematicOpen && (runtimeScene === "library_interior"
          || runtimeScene === "dorm_hub"
          || runtimeScene === "canteen_interior"
          || (runtimeScene === "theater_interior" && !["spotlight_hunt", "reversal"].includes(state.theaterHunt.phase))
          || runtimeScene === "qizhen_lake"
          || (runtimeScene === "duan_yongping_temporal_maze" && chapter4MazeUiActive)
          || (runtimeScene === "campus_bootstrap" && state.canteenHunt.phase === "chase_ready")) ? (
          <RpgInventoryDock
            state={state}
            events={events}
            blocked={inputBlocked}
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
          blocked={inputBlocked || itemInspectOpen || canteenExclusiveActive || chapter4OverlayBlocked
            || Boolean(fishingSession) || photoSessionOpen || qizhenRainRescueCinematicOpen}
        />

        {!inputBlocked && state.actOne.controlsInstalled && touchControls && !canteenExclusiveActive && !chapter4OverlayBlocked
          && !photoSessionOpen && !qizhenRainRescueCinematicOpen
          && runtimeScene === "qizhen_lake" && state.qizhenLake.vehicle === "kayak" ? (
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
        ) : !inputBlocked && state.actOne.controlsInstalled && touchControls && !canteenExclusiveActive && !chapter4OverlayBlocked
          && !qizhenRainRescueCinematicOpen ? (
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
  const targetIsRunning = game.scene.isActive(target)
    || game.scene.isPaused(target)
    || game.scene.isSleeping(target);
  if (!targetIsRunning) {
    game.scene.start(target);
  }
}

function restartRpgScene(game: Phaser.Game, target: string): void {
  Object.values(SCENE_KEYS).forEach((sceneKey) => {
    if (game.scene.isActive(sceneKey)
      || game.scene.isPaused(sceneKey)
      || game.scene.isSleeping(sceneKey)) {
      game.scene.stop(sceneKey);
    }
  });
  game.scene.start(target);
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
  return SCENE_KEYS[resolveRuntimeScene(state)];
}
