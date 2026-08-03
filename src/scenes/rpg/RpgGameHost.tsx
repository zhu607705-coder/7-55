import { useCallback, useEffect, useMemo, useRef, useState, useSyncExternalStore } from "react";
import Phaser from "phaser";
import type { EventBus } from "../../core/EventBus";
import type { SceneRouter } from "../../core/SceneRouter";
import { selectIdentityReadable } from "../../core/IdentityAccess";
import type {
  GameState,
  GameStore,
  ItemId,
  LibraryLocationId,
  QuestViewModel,
  QizhenDecoyTargetId,
  QizhenLakeMode,
  RpgCheckpointId,
  RpgSceneId,
  TheaterMode,
  TheaterProgramId
} from "../../core/types";
import actOneContent from "../../data/act-one-bootstrap.content.json";
import theaterContent from "../../data/chapter3-theater.content.json";
import { chapterThreeStoryLineKeyForSubtitle } from "../../data/chapterThreeStory";
import { ItemInspectDialog } from "../../components/ItemInspectDialog";
import { PixelIcon } from "../../components/PixelIcon";
import { ActOneBootstrapController } from "../../modules/ActOneBootstrapController";
import { LibraryFinalsController } from "../../modules/LibraryFinalsController";
import {
  bindChapterThreeCanteenEvents,
  ChapterThreeCanteenController
} from "../../modules/ChapterThreeCanteenController";
import { ChapterThreeTheaterController } from "../../modules/ChapterThreeTheaterController";
import { ChapterThreeQizhenLakeController } from "../../modules/ChapterThreeQizhenLakeController";
import { exitRpgFullscreen, toggleRpgFullscreen } from "../../modules/RpgFullscreen";
import { BootScene } from "./BootScene";
import { DormHubScene } from "./DormHubScene";
import { LibraryInteriorScene } from "./LibraryInteriorScene";
import { CanteenInteriorScene } from "./CanteenInteriorScene";
import { TheaterInteriorScene } from "./TheaterInteriorScene";
import { createTheaterRuntimePort } from "./TheaterRuntimeContract";
import type { TheaterSpotlightAttempt, TheaterSpotlightLane } from "./TheaterSpotlightModel";
import { QizhenLakeScene } from "./QizhenLakeScene";
import { CanteenChaseOverlay } from "./CanteenChaseOverlay";
import { RpgRealityModeToggle } from "./RpgRealityModeToggle";
import { createRpgBridge } from "./RpgBridge";
import { RPG_CONTROL_HINTS } from "./RpgControlHints";
import { RpgInventoryDock } from "./RpgInventoryDock";
import { QuestTaskBar } from "../../components/QuestClueStrip";
import { RpgSubtitleLayer } from "../../components/RpgSubtitleLayer";
import { useMediaQuery } from "../../components/useMediaQuery";
import { GodotRpgFrame } from "../../integrations/godot/GodotRpgFrame";
import {
  getRpgRuntimeSelection,
  isGodotTheaterPreviewPhase
} from "../../integrations/godot/GodotRuntimePolicy";
import {
  GodotTheaterPanel,
  type GodotTheaterPanelKind
} from "../../integrations/godot/GodotTheaterPanel";

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
  dorm_hub: "dorm-hub",
  library_interior: "library-interior",
  canteen_interior: "canteen-interior",
  theater_interior: "theater-interior",
  qizhen_lake: "qizhen-lake"
} as const;

const SCENE_CLASSES = {
  campus_bootstrap: BootScene,
  dorm_hub: DormHubScene,
  library_interior: LibraryInteriorScene,
  canteen_interior: CanteenInteriorScene,
  theater_interior: TheaterInteriorScene,
  qizhen_lake: QizhenLakeScene
} as const;

const DOUBLE_TAP_WINDOW_MS = 380;
const MIN_TOUCH_DIRECTION_PULSE_MS = 96;
const RPG_TOUCH_CONTROLS_QUERY = "(any-pointer: coarse)";
const LIBRARY_ACTION_CONTRACTS: Record<string, Readonly<{ targetId: string; itemId: ItemId | "" }>> = {
  readEntranceRecord: { targetId: "entrance_record", itemId: "" },
  inspectBackpack: { targetId: "seat_022_backpack", itemId: "" },
  collectOccupancyNote: { targetId: "occupancy_note", itemId: "" },
  unlockCatalogAtTerminal: { targetId: "catalog_terminal", itemId: "" },
  useCallNumberOnShelf: { targetId: "library_shelf_755", itemId: "callNumber755" },
  stampNonPersonProof: { targetId: "lost_found_machine", itemId: "itemRecognitionReport" },
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
  const shellRef = useRef<HTMLElement | null>(null);
  const hostRef = useRef<HTMLDivElement | null>(null);
  const phaserHostRef = useRef<HTMLDivElement | null>(null);
  const gameRef = useRef<Phaser.Game | null>(null);
  const inputBlockedRef = useRef(inputBlocked);
  const keyboardBlockedRef = useRef(keyboardBlocked);
  const lastMapItemTap = useRef<{ itemId: ItemId; at: number } | null>(null);
  const activeDirectionPointerRef = useRef<{ pointerId: number; startedAt: number } | null>(null);
  const directionStopTimerRef = useRef<number | null>(null);
  const archivedRuleRevealPendingRef = useRef(false);
  const itemInspectOpen = inspectedMapItem !== null;
  const state = useSyncExternalStore(store.subscribe, store.getState, store.getState);
  const chaseActive = state.canteenHunt.phase === "chasing";
  inputBlockedRef.current = inputBlocked || itemInspectOpen || chaseActive;
  keyboardBlockedRef.current = keyboardBlocked || chaseActive;
  const controller = useMemo(() => new ActOneBootstrapController(store, events), [events, store]);
  const libraryController = useMemo(() => new LibraryFinalsController(store, events), [events, store]);
  const canteenController = useMemo(() => new ChapterThreeCanteenController(store, events), [events, store]);
  const theaterController = useMemo(() => new ChapterThreeTheaterController(store, events), [events, store]);
  const qizhenController = useMemo(() => new ChapterThreeQizhenLakeController(store, events), [events, store]);
  const bridge = useMemo(() => createRpgBridge(store, router, events), [events, router, store]);
  const theaterRuntimePort = useMemo(() => createTheaterRuntimePort(bridge), [bridge]);
  const runtimeScene = resolveRuntimeScene(state);
  const runtimeSelection = useMemo(() => getRpgRuntimeSelection(runtimeScene), [runtimeScene]);
  const [failedGodotScene, setFailedGodotScene] = useState<RpgSceneId | null>(null);
  const [godotTheaterPanel, setGodotTheaterPanel] = useState<GodotTheaterPanelKind | null>(null);
  const godotPhaseSupported = runtimeScene !== "theater_interior"
    || isGodotTheaterPreviewPhase(state.theaterHunt.phase);
  const useGodotRuntime = runtimeSelection.engine === "godot"
    && failedGodotScene !== runtimeScene
    && godotPhaseSupported;
  const touchControls = useMediaQuery(RPG_TOUCH_CONTROLS_QUERY)
    || (typeof navigator !== "undefined" && navigator.maxTouchPoints > 0);
  const bindShellRef = useCallback((node: HTMLElement | null) => {
    shellRef.current = node;
    setShellRoot((current) => current === node ? current : node);
  }, []);
  const closeGodotTheaterPanel = useCallback(() => setGodotTheaterPanel(null), []);
  const handleGodotRuntimeFailure = useCallback((reason: string) => {
    console.warn(`[Godot RPG] ${reason}`);
    setFailedGodotScene(runtimeScene);
    events.emit("toast", {
      text: "Godot 场景载入失败，已切回兼容场景。",
      tone: "system",
      durationMs: 4200
    });
  }, [events, runtimeScene]);
  const selectDraggedRpgItem = useCallback((itemId: ItemId | null) => {
    store.setState((current) => current.ui.selectedItem === itemId
      ? current
      : { ...current, ui: { ...current.ui, selectedItem: itemId } });
  }, [store]);

  useEffect(() => {
    setFailedGodotScene(null);
  }, [runtimeScene]);

  useEffect(() => {
    if (!useGodotRuntime) setGodotTheaterPanel(null);
  }, [useGodotRuntime]);

  useEffect(() => {
    const host = phaserHostRef.current;
    if (!host || useGodotRuntime) {
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
          const target = SCENE_KEYS[resolveRuntimeScene(store.getState())];
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
  }, [bridge, store, theaterRuntimePort, useGodotRuntime]);

  useEffect(() => {
    const game = gameRef.current;
    if (!game) {
      return undefined;
    }
    if (inputBlocked || itemInspectOpen || chaseActive) {
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
  }, [chaseActive, events, inputBlocked, itemInspectOpen, keyboardBlocked]);

  useEffect(() => {
    const game = gameRef.current;
    const sceneKey = SCENE_KEYS[runtimeScene];
    if (game?.isBooted) {
      activateRpgScene(game, sceneKey);
    }
  }, [runtimeScene]);

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
      if (event.name === "rpg_canteen_bike_inspect_requested") {
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
        if (
          useGodotRuntime
          && store.getState().theaterHunt.phase === "program_search"
          && store.getState().theaterHunt.mode === "light"
          && store.getState().theaterHunt.collectedProgramIds.length === 3
        ) {
          setGodotTheaterPanel("program");
        }
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
            ? "票据扫描完成，道具箱已经解锁；临时观演票会保留。"
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
      } else if (event.name === "rpg_qizhen_reflection_requested") {
        qizhenController.interceptReflection(String(event.payload?.positionId ?? ""));
      } else if (event.name === "rpg_qizhen_sign_rotate_requested") {
        qizhenController.rotateSign(Number(event.payload?.signIndex));
      } else if (event.name === "rpg_qizhen_decoy_requested") {
        const result = qizhenController.placeDecoy(String(event.payload?.targetId ?? "notice") as QizhenDecoyTargetId);
        events.emit("rpg_item_use_feedback", {
          itemId: "decoyPaper",
          reason: result === "correct" ? "accepted" : result === "wrong" ? "wrong_item" : "locked",
          targetLabel: "候选布置点",
          detail: result === "wrong"
            ? "目标范围已经命中，但该位置与倒影坐标不一致。"
            : undefined
        });
      } else if (event.name === "rpg_qizhen_mist_observe_requested") {
        qizhenController.observeMistRhythm();
      } else if (event.name === "rpg_qizhen_mist_trigger_requested") {
        qizhenController.triggerMist(event.payload?.success === true);
      }
    });
  }, [canteenController, events, qizhenController, store, theaterController, useGodotRuntime]);

  useEffect(() => {
    if (!useGodotRuntime) return undefined;
    return events.subscribe((event) => {
      const showGodotSubtitle = (text: string, durationMs = 4200) => {
        events.emit("rpg_subtitle", {
          text,
          tone: "system",
          durationMs
        });
      };
      if (event.name === "theater_ticket_code_panel_opened") {
        setGodotTheaterPanel("code");
      } else if (event.name === "theater_ticket_halves_ready") {
        theaterController.combineTicketHalves();
      } else if (event.name === "theater_ticket_admitted" || event.name === "theater_program_order_solved") {
        setGodotTheaterPanel(null);
        showGodotSubtitle(
          event.name === "theater_ticket_admitted"
            ? "临时观演票通过，闸机已经开放。"
            : theaterContent.program.unlocked
        );
      } else if (event.name === "theater_ticket_code_read") {
        showGodotSubtitle(`深色模式：${theaterContent.ticket.codeVisible} 切回浅色模式输入。`, 4800);
      } else if (event.name === "theater_program_order_read") {
        showGodotSubtitle(theaterContent.program.darkOrder, 5200);
      } else if (event.name === "theater_prop_ghost_read") {
        showGodotSubtitle(`${theaterContent.prop.ghost} ${theaterContent.prop.managerHint}`, 5600);
      } else if (event.name === "theater_prop_box_locked") {
        showGodotSubtitle(theaterContent.prop.locked);
      } else if (event.name === "theater_prop_box_opened") {
        showGodotSubtitle(theaterContent.prop.scannerAccepted);
      } else if (event.name === "theater_paper_dusted") {
        showGodotSubtitle(theaterContent.prop.ventComplete);
      }
    });
  }, [events, theaterController, useGodotRuntime]);

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
      if (activePointer && activePointer.pointerId !== event.pointerId) return;
      activeDirectionPointerRef.current = null;
      clearStopTimer();
      const elapsed = activePointer ? performance.now() - activePointer.startedAt : MIN_TOUCH_DIRECTION_PULSE_MS;
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
    const handleFullscreenKey = (event: KeyboardEvent) => {
      if (!inputBlocked && !itemInspectOpen && !keyboardBlocked && event.key.toLowerCase() === "f" && !event.metaKey && !event.ctrlKey && !event.altKey) {
        toggleRpgFullscreen();
      }
    };
    window.addEventListener("keydown", handleFullscreenKey);
    return () => window.removeEventListener("keydown", handleFullscreenKey);
  }, [inputBlocked, itemInspectOpen, keyboardBlocked]);

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
      className={`rpg-stage ${runtimeScene === "campus_bootstrap" ? "is-campus-map" : ""} ${runtimeScene === "library_interior" ? "is-library-interior" : ""} ${runtimeScene === "canteen_interior" ? "is-canteen-interior" : ""} ${runtimeScene === "theater_interior" ? "is-theater-interior" : ""} ${runtimeScene === "qizhen_lake" ? "is-qizhen-lake" : ""} ${runtimeScene === "campus_bootstrap" && state.canteenHunt.phase === "chase_ready" ? "is-canteen-bike" : ""} ${chaseActive ? "is-canteen-chase" : ""} ${embedded ? "is-embedded" : ""}`.trim()}
      aria-label="7:55 RPG runtime"
      data-input-blocked={inputBlocked || itemInspectOpen || godotTheaterPanel !== null ? "true" : "false"}
      data-keyboard-blocked={keyboardBlocked ? "true" : "false"}
      data-rpg-engine={useGodotRuntime ? "godot" : "phaser"}
      data-rpg-engine-reason={
        failedGodotScene === runtimeScene
          ? "godot_runtime_failed"
          : !godotPhaseSupported
            ? "godot_phase_not_migrated"
            : runtimeSelection.reason
      }
    >
      <section ref={bindShellRef} className="rpg-shell" aria-label="7:55 横屏游戏">
        <div ref={hostRef} className="rpg-canvas-host">
          <div ref={phaserHostRef} className="rpg-phaser-host" aria-hidden={useGodotRuntime ? "true" : "false"} />
          {useGodotRuntime && runtimeScene === "theater_interior" ? (
            <GodotRpgFrame
              store={store}
              events={events}
              inputBlocked={inputBlocked || itemInspectOpen || chaseActive || keyboardBlocked || godotTheaterPanel !== null}
              onRuntimeFailure={handleGodotRuntimeFailure}
            />
          ) : null}
        </div>

        {chaseActive ? (
          <CanteenChaseOverlay
            events={events}
            completed={state.canteenHunt.chaseCompleted}
            attemptCount={state.canteenHunt.chaseAttemptCount}
            bestDistance={state.canteenHunt.chaseBestDistance}
            bestLives={state.canteenHunt.chaseBestLives}
            onAttempt={(attempt) => { canteenController.resolveChaseAttempt(attempt); }}
            onContinue={() => { canteenController.completeChase(); }}
          />
        ) : null}

        {useGodotRuntime && godotTheaterPanel ? (
          <GodotTheaterPanel
            kind={godotTheaterPanel}
            state={state}
            events={events}
            onClose={closeGodotTheaterPanel}
          />
        ) : null}

        {showTaskBar && !chaseActive ? (
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

        {runtimeScene === "qizhen_lake" && ["reflection_hunt", "sign_alignment", "decoy_setup", "mist_timing"].includes(state.qizhenLake.phase) ? (
          <RpgRealityModeToggle
            className="rpg-qizhen-mode-toggle"
            mode={state.qizhenLake.mode}
            onToggle={() => events.emit("rpg_qizhen_mode_requested", {
              mode: state.qizhenLake.mode === "dark" ? "light" : "dark"
            })}
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

        {runtimeScene === "library_interior"
          || runtimeScene === "dorm_hub"
          || runtimeScene === "canteen_interior"
          || (runtimeScene === "theater_interior" && !["spotlight_hunt", "reversal"].includes(state.theaterHunt.phase))
          || runtimeScene === "qizhen_lake"
          || (runtimeScene === "campus_bootstrap" && state.canteenHunt.phase === "chase_ready") ? (
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
          blocked={inputBlocked || itemInspectOpen || chaseActive || godotTheaterPanel !== null}
        />

        {state.actOne.controlsInstalled && touchControls && !chaseActive ? (
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
