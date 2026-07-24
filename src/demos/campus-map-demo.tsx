import { useCallback, useEffect, useMemo, useRef, useState, type PointerEvent as ReactPointerEvent } from "react";
import { createRoot } from "react-dom/client";
import Phaser from "phaser";
import "@fontsource/fusion-pixel-12px-proportional-sc";
import { getClientCompatibilitySnapshot, installClientCompatibility } from "../core/ClientCompatibility";
import { EventBus } from "../core/EventBus";
import { createGameStore, createInitialGameState } from "../core/GameState";
import { SceneRouter } from "../core/SceneRouter";
import type { GameState, RpgCheckpointId } from "../core/types";
import { useMediaQuery } from "../components/useMediaQuery";
import { BootScene } from "../scenes/rpg/BootScene";
import { createRpgBridge } from "../scenes/rpg/RpgBridge";
import { getRpgRuntimeDebugState } from "../scenes/rpg/RpgRuntimeDebug";
import "./campus-map-demo.css";

type DemoSpawn = "library" | "canteen";

const DEMO_SPAWNS = {
  library: { checkpoint: "campus_library_gate", label: "基础图书馆门前" },
  canteen: { checkpoint: "campus_canteen_gate", label: "大食堂门前" }
} as const satisfies Record<DemoSpawn, { checkpoint: RpgCheckpointId; label: string }>;

function createCampusMapDemoState(checkpoint: RpgCheckpointId = DEMO_SPAWNS.library.checkpoint): GameState {
  const initial = createInitialGameState();
  return {
    ...initial,
    runtimeMode: "rpg",
    rpgScene: "campus_bootstrap",
    rpgCheckpoint: checkpoint,
    currentScene: "phone_home",
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
    ui: {
      ...initial.ui,
      libraryFinalsPhase: "library_route_unlocked"
    }
  };
}

function createDemoTextState(state: GameState) {
  return {
    coordinateSystem: "Phaser world coordinates, origin at top-left, x right, y down",
    demo: "campus-map",
    currentScene: state.rpgScene,
    checkpoint: state.rpgCheckpoint,
    clientCompatibility: getClientCompatibilitySnapshot(),
    rpgRuntime: getRpgRuntimeDebugState()
  };
}

function isEditableTarget(target: EventTarget | null): boolean {
  return target instanceof HTMLInputElement || target instanceof HTMLTextAreaElement || target instanceof HTMLSelectElement;
}

function CampusMapDemo() {
  const events = useMemo(() => new EventBus(), []);
  const store = useMemo(() => createGameStore(createCampusMapDemoState()), []);
  const router = useMemo(() => new SceneRouter(store, events), [events, store]);
  const bridge = useMemo(() => createRpgBridge(store, router, events), [events, router, store]);
  const stageRef = useRef<HTMLElement | null>(null);
  const hostRef = useRef<HTMLDivElement | null>(null);
  const gameRef = useRef<Phaser.Game | null>(null);
  const manualTimeRef = useRef(0);
  const [notice, setNotice] = useState("地图加载中…");
  const [runtime, setRuntime] = useState(getRpgRuntimeDebugState());
  const touchControls = useMediaQuery("(any-pointer: coarse)");

  const refreshRuntime = useCallback(() => setRuntime(getRpgRuntimeDebugState()), []);

  useEffect(() => {
    const detachCompatibility = installClientCompatibility();
    return detachCompatibility;
  }, []);

  useEffect(() => {
    const detach = events.subscribe((event) => {
      if (event.name === "rpg_booted") {
        setNotice("大地图已就绪：道路可走，建筑与绿地保持阻挡。");
      } else if (event.name === "rpg_library_gate_requested") {
        setNotice("已到达基础图书馆入口。此独立 Demo 保持在大地图，不进入正式剧情。");
      } else if (event.name === "rpg_canteen_entry_requested") {
        setNotice("已到达大食堂入口。此独立 Demo 保持在大地图，不进入正式剧情。");
      }
      window.requestAnimationFrame(refreshRuntime);
    });
    return detach;
  }, [events, refreshRuntime]);

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
      scene: [BootScene],
      callbacks: {
        preBoot: (phaserGame) => {
          phaserGame.registry.set("rpgBridge", bridge);
        },
        postBoot: () => {
          bridge.emit("rpg_runtime_ready");
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
  }, [bridge, refreshRuntime]);

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
    store.setState(() => createCampusMapDemoState(target.checkpoint));
    const game = gameRef.current;
    if (game?.isBooted && game.scene.isActive("campus-bootstrap")) {
      game.scene.getScene("campus-bootstrap").scene.restart();
    }
    setNotice(`已回到${target.label}。`);
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

  return (
    <main ref={stageRef} className="campus-map-demo" aria-label="紫金港校园大地图独立演示">
      <section className="campus-map-demo__shell">
        <div ref={hostRef} className="campus-map-demo__canvas-host" aria-label="校园大地图交互区" />

        <header className="campus-map-demo__hud">
          <div className="campus-map-demo__title">
            <span>7:55</span>
            <strong>紫金港校园大地图</strong>
          </div>
          <p>{notice}</p>
        </header>

        <div className="campus-map-demo__actions" aria-label="演示操作">
          <button type="button" onClick={() => resetAt("library")}>图书馆门前</button>
          <button type="button" onClick={() => resetAt("canteen")}>食堂门前</button>
          <button type="button" onClick={() => events.emit("rpg_camera_recenter")}>回到角色</button>
          <button type="button" onClick={() => events.emit("rpg_camera_zoom", { delta: -1 })} aria-label="缩小地图">−</button>
          <button type="button" onClick={() => events.emit("rpg_camera_zoom", { delta: 1 })} aria-label="放大地图">+</button>
          <button type="button" onClick={toggleFullscreen}>全屏</button>
        </div>

        <div className="campus-map-demo__status" aria-live="polite">
          <span>坐标 {playerPosition}</span>
          <span>缩放 {cameraZoom}</span>
          <span>WASD / 方向键移动 · Shift 冲刺 · 单击路面寻路</span>
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
