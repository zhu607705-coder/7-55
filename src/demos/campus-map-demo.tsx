import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
  useSyncExternalStore,
  type PointerEvent as ReactPointerEvent
} from "react";
import { createRoot } from "react-dom/client";
import Phaser from "phaser";
import "../styles/pixel-font.css";
import { getClientCompatibilitySnapshot, installClientCompatibility } from "../core/ClientCompatibility";
import { EventBus } from "../core/EventBus";
import { createGameStore, createInitialGameState } from "../core/GameState";
import { SceneRouter } from "../core/SceneRouter";
import type { GameState, RpgCheckpointId } from "../core/types";
import { useMediaQuery } from "../components/useMediaQuery";
import {
  bindChapterThreeCanteenEvents,
  ChapterThreeCanteenController
} from "../modules/ChapterThreeCanteenController";
import { BootScene } from "../scenes/rpg/BootScene";
import { CanteenInteriorScene } from "../scenes/rpg/CanteenInteriorScene";
import { createRpgBridge } from "../scenes/rpg/RpgBridge";
import { getRpgRuntimeDebugState } from "../scenes/rpg/RpgRuntimeDebug";
import "./campus-map-demo.css";

type DemoSpawn = "library" | "canteen";

const DEMO_SPAWNS = {
  library: { checkpoint: "campus_library_gate", label: "基础图书馆门前", canteenStory: false },
  canteen: { checkpoint: "campus_canteen_gate", label: "大食堂门前", canteenStory: true }
} as const satisfies Record<DemoSpawn, {
  checkpoint: RpgCheckpointId;
  label: string;
  canteenStory: boolean;
}>;

const DEMO_SCENE_KEYS = {
  campus_bootstrap: "campus-bootstrap",
  canteen_interior: "canteen-interior"
} as const;

const CANTEEN_PHASE_LABELS: Record<GameState["canteenHunt"]["phase"], string> = {
  tracking: "追踪脚印",
  canteen_reached: "抵达食堂",
  entered: "进入食堂",
  tray_search: "寻找异常餐盘",
  drink_mix: "调配今日新品",
  menu_order: "破解点餐机",
  pickup_search: "寻找 0755 窗口",
  exit_blocking: "封堵纸条出口",
  chase_ready: "准备继续追赶",
  chasing: "追逐中",
  theater_reached: "抵达体艺馆"
};

const CANTEEN_MODE_PHASES: readonly GameState["canteenHunt"]["phase"][] = [
  "tray_search",
  "drink_mix",
  "menu_order",
  "pickup_search",
  "exit_blocking",
  "chase_ready"
];

function createCampusMapDemoState(spawn: DemoSpawn = "library"): GameState {
  const initial = createInitialGameState();
  const target = DEMO_SPAWNS[spawn];
  return {
    ...initial,
    runtimeMode: "rpg",
    rpgScene: "campus_bootstrap",
    rpgCheckpoint: target.checkpoint,
    currentScene: "phone_home",
    themeMode: target.canteenStory ? "dark" : initial.themeMode,
    items: {
      ...initial.items,
      campusCard: true,
      gamepad: true
    },
    actOne: {
      ...initial.actOne,
      phase: "complete",
      identityVerified: true,
      phoneLinked: true,
      controlsInstalled: true,
      movementEnabled: true,
      inventoryRecovered: true,
      characterNamed: true,
      exerciseStarted: true,
      pushTriangleTaken: true,
      weatherWaterTaken: true,
      mentorLineReleased: true,
      rightArrowAssembled: true,
      balanceShifted: true,
      gamepadPurchased: true,
      manualControlTested: true,
      canLeaveDorm: true,
      requiredItemCollected: true,
      gameMenuUnlocked: true,
      dormHubUnlocked: true
    },
    canteenHunt: {
      ...initial.canteenHunt,
      active: target.canteenStory,
      phase: "tracking",
      mode: "light"
    },
    ui: {
      ...initial.ui,
      libraryFinalsPhase: target.canteenStory ? "friend_contacted" : "library_route_unlocked",
      seenChapterIntros: ["chapter_one", "chapter_two", "chapter_three"]
    }
  };
}

function createDemoTextState(state: GameState) {
  return {
    coordinateSystem: "Phaser world coordinates, origin at top-left, x right, y down",
    demo: "campus-map",
    currentScene: state.rpgScene,
    checkpoint: state.rpgCheckpoint,
    canteenStory: {
      active: state.canteenHunt.active,
      phase: state.canteenHunt.phase,
      mode: state.canteenHunt.mode,
      identifiedTrayIds: state.canteenHunt.identifiedTrayIds,
      returnedTrayIds: state.canteenHunt.returnedTrayIds,
      blockHits: state.canteenHunt.blockHits
    },
    clientCompatibility: getClientCompatibilitySnapshot(),
    rpgRuntime: getRpgRuntimeDebugState()
  };
}

function isEditableTarget(target: EventTarget | null): boolean {
  return target instanceof HTMLInputElement || target instanceof HTMLTextAreaElement || target instanceof HTMLSelectElement;
}

function activateDemoScene(game: Phaser.Game, target: string, restart = false): void {
  Object.values(DEMO_SCENE_KEYS).forEach((sceneKey) => {
    if (sceneKey !== target && game.scene.isActive(sceneKey)) {
      game.scene.stop(sceneKey);
    }
  });
  if (restart && game.scene.isActive(target)) {
    game.scene.getScene(target).scene.restart();
  } else if (!game.scene.isActive(target)) {
    game.scene.start(target);
  }
}

function CampusMapDemo() {
  const events = useMemo(() => new EventBus(), []);
  const store = useMemo(() => createGameStore(createCampusMapDemoState()), []);
  const router = useMemo(() => new SceneRouter(store, events), [events, store]);
  const bridge = useMemo(() => createRpgBridge(store, router, events), [events, router, store]);
  const canteenController = useMemo(
    () => new ChapterThreeCanteenController(store, events),
    [events, store]
  );
  const stageRef = useRef<HTMLElement | null>(null);
  const hostRef = useRef<HTMLDivElement | null>(null);
  const gameRef = useRef<Phaser.Game | null>(null);
  const manualTimeRef = useRef(0);
  const [notice, setNotice] = useState("地图加载中…");
  const [runtime, setRuntime] = useState(getRpgRuntimeDebugState());
  const state = useSyncExternalStore(store.subscribe, store.getState, store.getState);
  const touchControls = useMediaQuery("(any-pointer: coarse)");
  const runtimeScene = state.rpgScene === "canteen_interior" ? "canteen_interior" : "campus_bootstrap";

  const refreshRuntime = useCallback(() => setRuntime(getRpgRuntimeDebugState()), []);

  useEffect(() => {
    const detachCompatibility = installClientCompatibility();
    return detachCompatibility;
  }, []);

  useEffect(() => {
    return bindChapterThreeCanteenEvents(canteenController, events, {
      beforeEnter: () => {
        if (store.getState().canteenHunt.active) return;
        store.setState((current) => ({
          ...current,
          themeMode: "dark",
          canteenHunt: {
            ...createInitialGameState().canteenHunt,
            active: true,
            phase: "tracking",
            mode: "light"
          },
          ui: {
            ...current.ui,
            libraryFinalsPhase: "friend_contacted",
            seenChapterIntros: ["chapter_one", "chapter_two", "chapter_three"]
          }
        }));
      },
      onEnterResult: (entered) => {
        setNotice(entered ? "正在进入大食堂剧情…" : "当前剧情阶段不能重新进入大食堂。");
      },
      onLeaveResult: (left) => {
        if (!left) setNotice("先完成当前食堂剧情，纸条被截住后才能离开。");
      }
    });
  }, [canteenController, events, store]);

  useEffect(() => {
    const detach = events.subscribe((event) => {
      if (event.name === "rpg_booted") {
        const scene = String(event.payload?.scene ?? "");
        if (scene === "canteen_interior") {
          setNotice("已进入大食堂：跟随剧情提示，先找出纸条碰过的餐盘。");
        } else if (store.getState().canteenHunt.active) {
          setNotice("大食堂剧情已开始：沿脚印到入口，按空格进入。");
        } else {
          setNotice("大地图已就绪：道路可走，建筑与绿地保持阻挡。");
        }
      } else if (event.name === "rpg_library_gate_requested") {
        setNotice("已到达基础图书馆入口。当前大地图路线保持开放。");
      } else if (event.name === "canteen_returned_to_campus") {
        setNotice("食堂内的纸条已被逼出，已返回大食堂门前。");
      } else if (event.name === "rpg_subtitle") {
        const text = String(event.payload?.text ?? "").trim();
        if (text) setNotice(text);
      }
      window.requestAnimationFrame(refreshRuntime);
    });
    return detach;
  }, [events, refreshRuntime, store]);

  useEffect(() => {
    const host = hostRef.current;
    if (!host) return undefined;
    host.replaceChildren();
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
      scene: [BootScene, CanteenInteriorScene],
      callbacks: {
        preBoot: (phaserGame) => {
          phaserGame.registry.set("rpgBridge", bridge);
        },
        postBoot: (phaserGame) => {
          bridge.emit("rpg_runtime_ready");
          const initialScene = store.getState().rpgScene === "canteen_interior"
            ? DEMO_SCENE_KEYS.canteen_interior
            : DEMO_SCENE_KEYS.campus_bootstrap;
          activateDemoScene(phaserGame, initialScene);
          window.requestAnimationFrame(refreshRuntime);
        }
      }
    });
    gameRef.current = game;

    return () => {
      if (gameRef.current === game) gameRef.current = null;
      game.destroy(true);
      host.replaceChildren();
    };
  }, [bridge, refreshRuntime, store]);

  useEffect(() => {
    const game = gameRef.current;
    if (game?.isBooted) {
      activateDemoScene(game, DEMO_SCENE_KEYS[runtimeScene]);
    }
  }, [runtimeScene]);

  useEffect(() => {
    const timer = window.setInterval(refreshRuntime, 140);
    return () => window.clearInterval(timer);
  }, [refreshRuntime]);

  useEffect(() => {
    const previousRender = window.render_game_to_text;
    const previousAdvance = window.advanceTime;
    const renderGameToText = () => JSON.stringify(createDemoTextState(store.getState()));
    const advanceTime = (milliseconds: number) => {
      const game = gameRef.current;
      if (!game?.isBooted) return;
      const frameMs = 1000 / 60;
      const steps = Math.max(1, Math.ceil(Math.max(0, Number.isFinite(milliseconds) ? milliseconds : 0) / frameMs));
      for (let index = 0; index < steps; index += 1) {
        manualTimeRef.current += frameMs;
        game.step(manualTimeRef.current, frameMs);
      }
      refreshRuntime();
    };
    window.render_game_to_text = renderGameToText;
    window.advanceTime = advanceTime;

    return () => {
      if (window.render_game_to_text === renderGameToText) window.render_game_to_text = previousRender;
      if (window.advanceTime === advanceTime) window.advanceTime = previousAdvance;
    };
  }, [refreshRuntime, store]);

  useEffect(() => {
    const stopDirection = () => events.emit("rpg_direction_changed", { x: 0, y: 0 });
    window.addEventListener("pointerup", stopDirection, true);
    window.addEventListener("pointercancel", stopDirection, true);
    window.addEventListener("blur", stopDirection);
    return () => {
      window.removeEventListener("pointerup", stopDirection, true);
      window.removeEventListener("pointercancel", stopDirection, true);
      window.removeEventListener("blur", stopDirection);
    };
  }, [events]);

  const toggleFullscreen = useCallback(() => {
    const target = stageRef.current as (HTMLElement & { webkitRequestFullscreen?: () => Promise<void> | void }) | null;
    const documentWithWebkit = document as Document & { webkitExitFullscreen?: () => Promise<void> | void; webkitFullscreenElement?: Element | null };
    if (document.fullscreenElement || documentWithWebkit.webkitFullscreenElement) {
      (document.exitFullscreen ?? documentWithWebkit.webkitExitFullscreen)?.call(document);
      return;
    }
    (target?.requestFullscreen ?? target?.webkitRequestFullscreen)?.call(target);
  }, []);

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key.toLowerCase() !== "f" || event.metaKey || event.ctrlKey || event.altKey || isEditableTarget(event.target)) return;
      event.preventDefault();
      toggleFullscreen();
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [toggleFullscreen]);

  const resetAt = useCallback((spawn: DemoSpawn) => {
    const target = DEMO_SPAWNS[spawn];
    store.setState(() => createCampusMapDemoState(spawn));
    const game = gameRef.current;
    if (game?.isBooted) {
      window.requestAnimationFrame(() => {
        if (gameRef.current === game) {
          activateDemoScene(game, DEMO_SCENE_KEYS.campus_bootstrap, true);
        }
      });
    }
    setNotice(target.canteenStory
      ? `大食堂剧情已重开：已到${target.label}，按空格进入。`
      : `已回到${target.label}，当前为自由探索。`);
    window.requestAnimationFrame(refreshRuntime);
  }, [refreshRuntime, store]);

  const move = useCallback((event: ReactPointerEvent<HTMLButtonElement>, x: number, y: number) => {
    try {
      event.currentTarget.setPointerCapture?.(event.pointerId);
    } catch {
      // Some WebKit and synthetic-pointer paths reject capture; the window-level
      // pointerup/pointercancel listeners still stop movement safely.
    }
    events.emit("rpg_direction_changed", { x, y });
    event.preventDefault();
  }, [events]);

  const player = runtime?.player;
  const playerPosition = player ? `${Math.round(player.x)}, ${Math.round(player.y)}` : "--";
  const cameraZoom = runtime ? runtime.camera.zoom.toFixed(2) : "--";
  const canToggleCanteenMode = state.canteenHunt.active
    && runtimeScene === "canteen_interior"
    && CANTEEN_MODE_PHASES.includes(state.canteenHunt.phase);

  return (
    <main
      ref={stageRef}
      className={`campus-map-demo is-${runtimeScene.replace("_", "-")}`}
      aria-label="紫金港校园大地图与大食堂剧情演示"
    >
      <section className="campus-map-demo__shell">
        <div ref={hostRef} className="campus-map-demo__canvas-host" aria-label="校园与大食堂剧情交互区" />

        <header className="campus-map-demo__hud">
          <div className="campus-map-demo__title">
            <span>7:55</span>
            <strong>{runtimeScene === "canteen_interior" ? "大食堂剧情" : "紫金港校园大地图"}</strong>
          </div>
          <p aria-live="polite">{notice}</p>
        </header>

        <div className="campus-map-demo__actions" aria-label="演示操作">
          <button type="button" onClick={() => resetAt("library")}>自由探索</button>
          <button type="button" onClick={() => resetAt("canteen")}>大食堂剧情</button>
          {canToggleCanteenMode ? (
            <button
              type="button"
              aria-pressed={state.canteenHunt.mode === "dark"}
              onClick={() => events.emit("rpg_canteen_mode_requested", {
                mode: state.canteenHunt.mode === "dark" ? "light" : "dark"
              })}
            >
              {state.canteenHunt.mode === "dark" ? "切回浅色" : "切到深色"}
            </button>
          ) : null}
          {runtimeScene === "campus_bootstrap" ? (
            <>
              <button type="button" onClick={() => events.emit("rpg_camera_recenter")}>回到角色</button>
              <button type="button" onClick={() => events.emit("rpg_camera_zoom", { delta: -1 })} aria-label="缩小地图">−</button>
              <button type="button" onClick={() => events.emit("rpg_camera_zoom", { delta: 1 })} aria-label="放大地图">+</button>
            </>
          ) : null}
          <button type="button" onClick={toggleFullscreen}>全屏</button>
        </div>

        <div className="campus-map-demo__status" aria-live="polite">
          <span>坐标 {playerPosition}</span>
          <span>缩放 {cameraZoom}</span>
          {state.canteenHunt.active ? (
            <>
              <span>剧情 {CANTEEN_PHASE_LABELS[state.canteenHunt.phase]}</span>
              <span>{state.canteenHunt.mode === "dark" ? "深色模式" : "浅色模式"}</span>
            </>
          ) : null}
          <span>
            {runtimeScene === "canteen_interior"
              ? "WASD / 方向键移动 · 空格交互 · Tab 切换明暗"
              : "WASD / 方向键移动 · Shift 冲刺 · 空格进入 · 单击路面寻路"}
          </span>
        </div>

        {touchControls ? (
          <div className="campus-map-demo__touch-controls" aria-label="触控方向与交互">
            <button type="button" aria-label="向上移动" onPointerDown={(event) => move(event, 0, -1)}>▲</button>
            <button type="button" aria-label="向左移动" onPointerDown={(event) => move(event, -1, 0)}>◀</button>
            <button type="button" aria-label="向下移动" onPointerDown={(event) => move(event, 0, 1)}>▼</button>
            <button type="button" aria-label="向右移动" onPointerDown={(event) => move(event, 1, 0)}>▶</button>
            <button type="button" className="interact" onClick={() => events.emit("rpg_interact")}>空格</button>
          </div>
        ) : null}
      </section>
    </main>
  );
}

createRoot(document.getElementById("root") as HTMLElement).render(<CampusMapDemo />);
