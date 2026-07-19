import { useCallback, useEffect, useMemo, useRef, useState, useSyncExternalStore } from "react";
import Phaser from "phaser";
import type { EventBus } from "../../core/EventBus";
import type { SceneRouter } from "../../core/SceneRouter";
import type {
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
import { exitRpgFullscreen, toggleRpgFullscreen } from "../../modules/RpgFullscreen";
import { BootScene } from "./BootScene";
import { DormHubScene } from "./DormHubScene";
import { LibraryInteriorScene } from "./LibraryInteriorScene";
import { createRpgBridge } from "./RpgBridge";
import { RPG_CONTROL_HINTS } from "./RpgControlHints";
import { RpgInventoryDock } from "./RpgInventoryDock";
import { QuestTaskBar } from "../../components/QuestClueStrip";

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
  library_interior: "library-interior"
} as const;

const SCENE_CLASSES = {
  campus_bootstrap: BootScene,
  dorm_hub: DormHubScene,
  library_interior: LibraryInteriorScene
} as const;

const DOUBLE_TAP_WINDOW_MS = 380;
const RPG_TOUCH_CONTROLS_QUERY = "(pointer: coarse)";

function useTouchControls(): boolean {
  const [enabled, setEnabled] = useState(() => (
    typeof window !== "undefined" && typeof window.matchMedia === "function"
      ? window.matchMedia(RPG_TOUCH_CONTROLS_QUERY).matches
      : false
  ));

  useEffect(() => {
    if (typeof window.matchMedia !== "function") return undefined;
    const query = window.matchMedia(RPG_TOUCH_CONTROLS_QUERY);
    const update = () => setEnabled(query.matches);
    update();
    query.addEventListener?.("change", update);
    return () => query.removeEventListener?.("change", update);
  }, []);

  return enabled;
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
  const shellRef = useRef<HTMLElement | null>(null);
  const hostRef = useRef<HTMLDivElement | null>(null);
  const gameRef = useRef<Phaser.Game | null>(null);
  const inputBlockedRef = useRef(inputBlocked);
  const keyboardBlockedRef = useRef(keyboardBlocked);
  const pendingInspectStoryRef = useRef<string | null>(null);
  const lastMapItemTap = useRef<{ itemId: ItemId; at: number } | null>(null);
  const itemInspectOpen = inspectedMapItem !== null;
  inputBlockedRef.current = inputBlocked || itemInspectOpen;
  keyboardBlockedRef.current = keyboardBlocked;
  const state = useSyncExternalStore(store.subscribe, store.getState, store.getState);
  const controller = useMemo(() => new ActOneBootstrapController(store, events), [events, store]);
  const libraryController = useMemo(() => new LibraryFinalsController(store, events), [events, store]);
  const bridge = useMemo(() => createRpgBridge(store, router, events), [events, router, store]);
  const runtimeScene = resolveRuntimeScene(state);
  const touchControls = useTouchControls();
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
    return events.subscribe((event) => {
      if (event.name === "rpg_campus_card_collected" || event.name === "rpg_inventory_chest_opened") {
        controller.recoverInventory();
      } else if (event.name === "rpg_character_inspected") {
        controller.inspectCharacter();
      } else if (event.name === "rpg_manual_movement_started") {
        controller.confirmManualControl();
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
        let accepted = false;
        if (action === "visitLibraryPoint") {
          accepted = libraryController.visitLibraryPoint(
            String(event.payload?.point ?? "") as LibraryLocationId,
            event.payload?.checkpoint
              ? String(event.payload.checkpoint) as RpgCheckpointId
              : undefined
          );
        } else if (action === "readEntranceRecord") {
          accepted = libraryController.readEntranceRecord();
        } else if (action === "inspectBackpack") {
          accepted = libraryController.inspectBackpack();
        } else if (action === "collectOccupancyNote") {
          accepted = libraryController.collectOccupancyNote();
        } else if (action === "useCallNumberOnShelf") {
          accepted = libraryController.useCallNumberOnShelf();
        } else if (action === "stampNonPersonProof") {
          accepted = libraryController.stampNonPersonProof();
        } else if (action === "useRightArrowOnReceipt") {
          accepted = libraryController.useRightArrowOnReceipt();
        } else if (action === "applyPassToBackpack") {
          accepted = libraryController.applyPassToBackpack();
        } else if (action === "sitAt022") {
          accepted = libraryController.sitAt022();
        } else if (action === "complete022Dialogue") {
          accepted = libraryController.complete022Dialogue();
        }
        if (accepted) {
          events.emit("rpg_library_action_accepted", { action, targetId });
        } else if (action !== "visitLibraryPoint") {
          events.emit("library_rpg_interaction_failed", { action, targetId, reason: "unavailable" });
        }
      } else if (event.name === "library_archived_rule_recovered") {
        pendingInspectStoryRef.current = "library_archived_rule_recovered";
        setInspectedMapItem("archivedLeaveRule");
      } else if (
        event.name === "library_story_finished"
        && event.payload?.sequenceId === "library_friend_contacted"
      ) {
        libraryController.complete022Dialogue();
      } else if (
        event.name === "library_story_finished"
        && event.payload?.sequenceId === "library_archived_rule_recovered"
      ) {
        events.emit("toast", {
          text: "任务更新：完成三项证明",
          tone: "task",
          durationMs: 4200
        });
      }
    });
  }, [controller, events, libraryController]);

  useEffect(() => {
    const stopDirection = () => {
      events.emit("rpg_direction_changed", { x: 0, y: 0 });
    };
    window.addEventListener("pointerup", stopDirection, true);
    window.addEventListener("pointercancel", stopDirection, true);
    return () => {
      window.removeEventListener("pointerup", stopDirection, true);
      window.removeEventListener("pointercancel", stopDirection, true);
    };
  }, [events]);

  useEffect(() => {
    const handleFullscreenKey = (event: KeyboardEvent) => {
      if (!keyboardBlocked && event.key.toLowerCase() === "f" && !event.metaKey && !event.ctrlKey && !event.altKey) {
        toggleRpgFullscreen();
      }
    };
    window.addEventListener("keydown", handleFullscreenKey);
    return () => window.removeEventListener("keydown", handleFullscreenKey);
  }, [keyboardBlocked]);

  function direction(x: number, y: number) {
    events.emit("rpg_direction_changed", { x, y });
  }

  function returnToPhone() {
    if (desktopSplit) {
      onFocusPhone?.();
      return;
    }
    exitRpgFullscreen();
    controller.returnToPhone();
  }

  function inspectMapItem(item: "campusCard" | "gamepad") {
    if (item === "campusCard") {
      events.emit("toast", {
        text: `电子校园卡：${actOneContent.studentName} · ${actOneContent.studentId}`,
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

  function closeMapItemDetails() {
    const pendingStory = pendingInspectStoryRef.current;
    pendingInspectStoryRef.current = null;
    setInspectedMapItem(null);
    if (pendingStory) {
      events.emit("library_story_request", { sequenceId: pendingStory });
    }
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

  return (
    <main
      className={`rpg-stage ${runtimeScene === "library_interior" ? "is-library-interior" : ""} ${embedded ? "is-embedded" : ""}`.trim()}
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
          <>
            <nav className="rpg-camera-actions" aria-label="地图视角">
              <button type="button" aria-label="定位人物" title="定位人物" onClick={() => events.emit("rpg_camera_recenter")}>⌖</button>
              <button type="button" aria-label="放大地图" title="放大地图" onClick={() => events.emit("rpg_camera_zoom", { delta: 0.1 })}>+</button>
              <button type="button" aria-label="缩小地图" title="缩小地图" onClick={() => events.emit("rpg_camera_zoom", { delta: -0.1 })}>−</button>
            </nav>
            <aside className="rpg-minimap-frame" aria-hidden="true"><span>紫金港全图</span></aside>
          </>
        ) : null}

        {(state.items.campusCard || state.items.gamepad || state.actOne.gamepadPurchased) && runtimeScene !== "library_interior" ? (
          <aside className="rpg-temp-inventory" aria-label="地图物品栏">
            <strong>物品栏</strong>
            <div className="rpg-temp-items">
              {state.items.campusCard ? (
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
              {state.items.gamepad || state.actOne.gamepadPurchased ? (
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
            {state.items.gamepad || state.actOne.gamepadPurchased ? (
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

        {runtimeScene === "library_interior" ? (
          <RpgInventoryDock
            state={state}
            events={events}
            shellRef={shellRef}
            canvasHostRef={hostRef}
            onInspect={openMapItemDetails}
          />
        ) : null}

        {state.actOne.controlsInstalled && touchControls ? (
          <nav
            className={`rpg-touch-controls ${state.actOne.movementEnabled ? "" : "is-disabled"}`.trim()}
            aria-label="RPG操作键，键盘使用 WASD 移动和空格键交互"
          >
            <button type="button" aria-label="向上" disabled={!state.actOne.movementEnabled} onPointerDown={() => direction(0, -1)}>↑</button>
            <button type="button" aria-label="向左" disabled={!state.actOne.movementEnabled} onPointerDown={() => direction(-1, 0)}>←</button>
            <button type="button" aria-label="向下" disabled={!state.actOne.movementEnabled} onPointerDown={() => direction(0, 1)}>↓</button>
            <button type="button" aria-label="向右" disabled={!state.actOne.movementEnabled} onPointerDown={() => direction(1, 0)}>→</button>
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
  if (phase === "library_route_unlocked") return "进入图书馆，找到 022";
  if (phase === "library_entered") return puzzle.entranceRecordRead ? "前往二层南区寻找 022" : "读取入馆记录，确认 022 的位置";
  if (phase === "occupied_seat_found") return puzzle.occupancyNoteCollected ? "调查 022 的占座规则" : "检查书包旁边的占座纸条";
  if (phase === "evidence_gathering") {
    if (!puzzle.investigationOpened) return "调查 022 的占座规则";
    if (!puzzle.catalogSearchCompleted || !puzzle.callNumberCollected) return "找到旧版离座规则";
    if (!puzzle.archivedRuleCollected) return "按索书号核对馆内旧规则";
    if (!puzzle.nonPersonProofStamped) return "证明书包不是本人";
    if (!puzzle.seatReceiptCollected) return "取得 022 座位小票";
    if (!puzzle.presenceProofCollected) return "证明本人来过 022";
    return "把四项公开证据整理进 CC98";
  }
  if (phase === "top_ten_reached") return "前往图书馆 App 提交恢复申请";
  if (phase === "bd_briefing") return "听系统说明为什么还需要 bd";
  if (phase === "top_ten_rising") return "让证据公示进入 CC98 十大";
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
  if (["bd_briefing", "top_ten_rising", "top_ten_reached"].includes(state.ui.libraryFinalsPhase)) {
    return `R${String(4 - puzzle.bdCount).padStart(2, "0")}`;
  }
  if (!puzzle.archivedRuleCollected) {
    return puzzle.callNumberCollected ? "755" : "规则";
  }
  const proofCount = [puzzle.nonPersonProofStamped, puzzle.seatReceiptCollected, puzzle.presenceProofCollected].filter(Boolean).length;
  return `${proofCount}/3`;
}

function resolveRuntimeScene(state: GameState): RpgSceneId {
  const hasLibraryCheckpoint = state.rpgCheckpoint !== "campus_library_gate";
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
