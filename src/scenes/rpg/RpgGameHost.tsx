import { useCallback, useEffect, useMemo, useRef, useState, useSyncExternalStore } from "react";
import Phaser from "phaser";
import type { EventBus } from "../../core/EventBus";
import type { SceneRouter } from "../../core/SceneRouter";
import { selectIdentityReadable } from "../../core/IdentityAccess";
import type {
  CanteenExitId,
  CanteenMode,
  GameState,
  GameStore,
  ItemId,
  LibraryLocationId,
  QuestViewModel,
  RpgCheckpointId,
  RpgSceneId
} from "../../core/types";
import actOneContent from "../../data/act-one-bootstrap.content.json";
import { ItemInspectDialog } from "../../components/ItemInspectDialog";
import { PixelIcon } from "../../components/PixelIcon";
import { ActOneBootstrapController } from "../../modules/ActOneBootstrapController";
import { LibraryFinalsController } from "../../modules/LibraryFinalsController";
import { ChapterThreeCanteenController } from "../../modules/ChapterThreeCanteenController";
import { exitRpgFullscreen, toggleRpgFullscreen } from "../../modules/RpgFullscreen";
import { BootScene } from "./BootScene";
import { DormHubScene } from "./DormHubScene";
import { LibraryInteriorScene } from "./LibraryInteriorScene";
import { CanteenInteriorScene } from "./CanteenInteriorScene";
import { createRpgBridge } from "./RpgBridge";
import { RPG_CONTROL_HINTS } from "./RpgControlHints";
import { RpgInventoryDock } from "./RpgInventoryDock";
import { QuestTaskBar } from "../../components/QuestClueStrip";
import { RpgSubtitleLayer } from "../../components/RpgSubtitleLayer";
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
  dorm_hub: "dorm-hub",
  library_interior: "library-interior",
  canteen_interior: "canteen-interior"
} as const;

const SCENE_CLASSES = {
  campus_bootstrap: BootScene,
  dorm_hub: DormHubScene,
  library_interior: LibraryInteriorScene,
  canteen_interior: CanteenInteriorScene
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
  const gameRef = useRef<Phaser.Game | null>(null);
  const inputBlockedRef = useRef(inputBlocked);
  const keyboardBlockedRef = useRef(keyboardBlocked);
  const lastMapItemTap = useRef<{ itemId: ItemId; at: number } | null>(null);
  const activeDirectionPointerRef = useRef<{ pointerId: number; startedAt: number } | null>(null);
  const directionStopTimerRef = useRef<number | null>(null);
  const archivedRuleRevealPendingRef = useRef(false);
  const itemInspectOpen = inspectedMapItem !== null;
  inputBlockedRef.current = inputBlocked || itemInspectOpen;
  keyboardBlockedRef.current = keyboardBlocked;
  const state = useSyncExternalStore(store.subscribe, store.getState, store.getState);
  const controller = useMemo(() => new ActOneBootstrapController(store, events), [events, store]);
  const libraryController = useMemo(() => new LibraryFinalsController(store, events), [events, store]);
  const canteenController = useMemo(() => new ChapterThreeCanteenController(store, events), [events, store]);
  const bridge = useMemo(() => createRpgBridge(store, router, events), [events, router, store]);
  const runtimeScene = resolveRuntimeScene(state);
  const touchControls = useMediaQuery(RPG_TOUCH_CONTROLS_QUERY)
    || (typeof navigator !== "undefined" && navigator.maxTouchPoints > 0);
  const bindShellRef = useCallback((node: HTMLElement | null) => {
    shellRef.current = node;
    setShellRoot((current) => current === node ? current : node);
  }, []);

  useEffect(() => {
    const host = hostRef.current;
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
  }, [bridge, store]);

  useEffect(() => {
    const game = gameRef.current;
    if (!game) {
      return undefined;
    }
    if (inputBlocked || itemInspectOpen) {
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
  }, [events, inputBlocked, itemInspectOpen, keyboardBlocked]);

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
        } else if (action !== "visitLibraryPoint") {
          events.emit("library_rpg_interaction_failed", { action, targetId, reason: "unavailable" });
        }
      } else if (event.name === "rpg_canteen_entry_requested") {
        canteenController.enterCanteen();
      } else if (event.name === "rpg_canteen_mode_requested") {
        canteenController.setMode(String(event.payload?.mode ?? "light") as CanteenMode);
      } else if (event.name === "rpg_canteen_tray_requested") {
        canteenController.useTray(
          String(event.payload?.trayId ?? ""),
          event.payload?.queueCollision === true
        );
      } else if (event.name === "rpg_canteen_menu_selected") {
        canteenController.selectMenuOption(String(event.payload?.optionId ?? ""));
      } else if (event.name === "rpg_canteen_pickup_selected") {
        canteenController.selectPickupWindow(String(event.payload?.windowId ?? ""));
      } else if (event.name === "rpg_canteen_exit_block_requested") {
        canteenController.blockExit(String(event.payload?.exitId ?? "west") as CanteenExitId);
      } else if (event.name === "rpg_canteen_leave_requested") {
        canteenController.leaveCanteen();
      }
    });
  }, [canteenController, controller, events, libraryController]);

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
  }

  return (
    <main
      className={`rpg-stage ${runtimeScene === "library_interior" ? "is-library-interior" : ""} ${runtimeScene === "canteen_interior" ? "is-canteen-interior" : ""} ${embedded ? "is-embedded" : ""}`.trim()}
      aria-label="7:55 RPG runtime"
      data-input-blocked={inputBlocked || itemInspectOpen ? "true" : "false"}
      data-keyboard-blocked={keyboardBlocked ? "true" : "false"}
    >
      <section ref={bindShellRef} className="rpg-shell" aria-label="7:55 横屏游戏">
        <div ref={hostRef} className="rpg-canvas-host" aria-hidden="true" />

        {showTaskBar ? (
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

        {runtimeScene === "campus_bootstrap" ? (
          <nav className="rpg-camera-actions" aria-label="地图视角">
            <button type="button" aria-label="定位人物" title="定位人物" onClick={(event) => { events.emit("rpg_camera_recenter"); event.currentTarget.blur(); }}>⌖</button>
            <button type="button" aria-label="放大地图" title="放大地图" onClick={(event) => { events.emit("rpg_camera_zoom", { delta: 0.1 }); event.currentTarget.blur(); }}>+</button>
            <button type="button" aria-label="缩小地图" title="缩小地图" onClick={(event) => { events.emit("rpg_camera_zoom", { delta: -0.1 }); event.currentTarget.blur(); }}>−</button>
          </nav>
        ) : null}

        {runtimeScene === "canteen_interior" && state.canteenHunt.active
          && ["tray_search", "menu_order", "pickup_search", "exit_blocking"].includes(state.canteenHunt.phase) ? (
          <button
            type="button"
            className={`rpg-canteen-mode-toggle is-${state.canteenHunt.mode}`}
            aria-pressed={state.canteenHunt.mode === "dark"}
            onClick={() => events.emit("rpg_canteen_mode_requested", {
              mode: state.canteenHunt.mode === "dark" ? "light" : "dark"
            })}
          >
            {state.canteenHunt.mode === "dark" ? "浅色模式" : "深色模式"}
          </button>
        ) : null}

        {((state.actOne.inventoryRecovered && state.items.campusCard) || state.items.gamepad) && runtimeScene === "campus_bootstrap" ? (
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

        {runtimeScene === "library_interior" || runtimeScene === "dorm_hub" || runtimeScene === "canteen_interior" ? (
          <RpgInventoryDock
            state={state}
            events={events}
            shellRef={shellRef}
            canvasHostRef={hostRef}
            onInspect={openMapItemDetails}
          />
        ) : null}

        <RpgSubtitleLayer
          key={runtimeScene}
          events={events}
          state={state}
          blocked={inputBlocked || itemInspectOpen}
        />

        {state.actOne.controlsInstalled && touchControls ? (
          <nav
            className={`rpg-touch-controls ${state.actOne.movementEnabled ? "" : "is-disabled"}`.trim()}
            aria-label="RPG操作键，键盘使用 WASD 移动和空格键交互"
          >
            <button type="button" aria-label="向上" disabled={!state.actOne.movementEnabled} onPointerDown={(event) => direction(event, 0, -1)}>↑</button>
            <button type="button" aria-label="向左" disabled={!state.actOne.movementEnabled} onPointerDown={(event) => direction(event, -1, 0)}>←</button>
            <button type="button" aria-label="向下" disabled={!state.actOne.movementEnabled} onPointerDown={(event) => direction(event, 0, 1)}>↓</button>
            <button type="button" aria-label="向右" disabled={!state.actOne.movementEnabled} onPointerDown={(event) => direction(event, 1, 0)}>→</button>
            {runtimeScene !== "dorm_hub" ? (
              <button
                type="button"
                className="interact"
                aria-label="交互（键盘为空格键）"
                disabled={!state.actOne.movementEnabled}
                onClick={() => events.emit("rpg_interact")}
              >
                {RPG_CONTROL_HINTS.touchInteraction}
              </button>
            ) : null}
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
  if (phase === "friend_contacted") return "找到那本借走签到记录的书";
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
