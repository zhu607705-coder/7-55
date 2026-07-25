import { useCallback, useEffect, useRef, useState, useSyncExternalStore } from "react";
import type { EventBus } from "../../core/EventBus";
import { createGodotBridge, type GodotBridgeController, type GodotRuntimeSnapshot } from "../../core/GodotBridge";
import type { SceneRouter } from "../../core/SceneRouter";
import type { GameStore, QuestViewModel } from "../../core/types";
import { QuestTaskBar } from "../../components/QuestClueStrip";
import { useMediaQuery } from "../../components/useMediaQuery";

interface GodotRpgGameHostProps {
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

type LoadStatus = "loading" | "ready" | "error";

const RPG_TOUCH_CONTROLS_QUERY = "(any-pointer: coarse)";
const READY_TIMEOUT_MS = 15_000;

export function GodotRpgGameHost({
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
}: GodotRpgGameHostProps) {
  const iframeRef = useRef<HTMLIFrameElement | null>(null);
  const shellRef = useRef<HTMLElement | null>(null);
  const bridgeRef = useRef<GodotBridgeController | null>(null);
  const activePointerRef = useRef<number | null>(null);
  const inputBlockedRef = useRef(inputBlocked);
  const keyboardBlockedRef = useRef(keyboardBlocked);
  inputBlockedRef.current = inputBlocked;
  keyboardBlockedRef.current = keyboardBlocked;
  const [shellRoot, setShellRoot] = useState<HTMLElement | null>(null);
  const [status, setStatus] = useState<LoadStatus>("loading");
  const [engineLabel, setEngineLabel] = useState("Godot 4.7.1");
  const [errorMessage, setErrorMessage] = useState("");
  const [snapshot, setSnapshot] = useState<GodotRuntimeSnapshot | null>(null);
  const state = useSyncExternalStore(store.subscribe, store.getState, store.getState);
  const touchControls = useMediaQuery(RPG_TOUCH_CONTROLS_QUERY)
    || (typeof navigator !== "undefined" && navigator.maxTouchPoints > 0);
  const interactionBlocked = inputBlocked || keyboardBlocked;
  const bindShellRef = useCallback((node: HTMLElement | null) => {
    shellRef.current = node;
    setShellRoot((current) => current === node ? current : node);
  }, []);

  function syncInputState(controller = bridgeRef.current) {
    controller?.sendCommand("set_input_enabled", {
      enabled: !(inputBlockedRef.current || keyboardBlockedRef.current)
    });
    controller?.sendCommand("set_paused", {
      paused: inputBlockedRef.current
    });
  }

  useEffect(() => {
    const iframe = iframeRef.current;
    if (!iframe) return undefined;
    setStatus("loading");
    const timeout = window.setTimeout(() => {
      setStatus((current) => {
        if (current === "ready") return current;
        setErrorMessage("Godot Web 运行时启动超时。请重新执行 npm run godot:export:web。");
        return "error";
      });
    }, READY_TIMEOUT_MS);

    const bridge = createGodotBridge({
      iframe,
      store,
      events,
      onReady: (engine) => {
        window.clearTimeout(timeout);
        setStatus("ready");
        setErrorMessage("");
        const major = typeof engine.major === "number" ? engine.major : 4;
        const minor = typeof engine.minor === "number" ? engine.minor : 7;
        const patch = typeof engine.patch === "number" ? engine.patch : 1;
        setEngineLabel(`Godot ${major}.${minor}.${patch}`);
        syncInputState(bridgeRef.current);
        events.emit("godot_runtime_ready", { major, minor, patch });
      },
      onSnapshot: (nextSnapshot) => setSnapshot(nextSnapshot),
      onError: (message) => {
        window.clearTimeout(timeout);
        setStatus("error");
        setErrorMessage(message);
      }
    });
    bridgeRef.current = bridge;
    return () => {
      window.clearTimeout(timeout);
      bridge.destroy();
      if (bridgeRef.current === bridge) bridgeRef.current = null;
    };
  }, [events, store]);

  useEffect(() => {
    syncInputState();
  }, [inputBlocked, keyboardBlocked]);

  useEffect(() => {
    const stopDirection = () => {
      if (activePointerRef.current === null) return;
      activePointerRef.current = null;
      bridgeRef.current?.sendCommand("input", { x: 0, y: 0 });
    };
    window.addEventListener("pointerup", stopDirection, true);
    window.addEventListener("pointercancel", stopDirection, true);
    window.addEventListener("blur", stopDirection);
    window.addEventListener("pagehide", stopDirection);
    return () => {
      window.removeEventListener("pointerup", stopDirection, true);
      window.removeEventListener("pointercancel", stopDirection, true);
      window.removeEventListener("blur", stopDirection);
      window.removeEventListener("pagehide", stopDirection);
      stopDirection();
    };
  }, []);

  function startDirection(event: React.PointerEvent<HTMLButtonElement>, x: number, y: number) {
    activePointerRef.current = event.pointerId;
    try {
      event.currentTarget.setPointerCapture?.(event.pointerId);
    } catch {
      // Old WebKit may reject pointer capture; global pointerup still clears input.
    }
    bridgeRef.current?.sendCommand("input", { x, y });
    event.preventDefault();
  }

  function returnToPhone() {
    if (desktopSplit) {
      onFocusPhone?.();
      return;
    }
    store.setState((current) => ({
      ...current,
      runtimeMode: "phone",
      currentScene: "phone_home"
    }));
  }

  const playerPosition = snapshot ? `${snapshot.player.x}, ${snapshot.player.y}` : "等待状态";
  const iframeSrc = `${import.meta.env.BASE_URL}godot/index.html?embed=1`;

  return (
    <main
      className={`rpg-stage godot-rpg-stage is-campus-map ${embedded ? "is-embedded" : ""}`.trim()}
      aria-label="7:55 Godot RPG runtime"
      data-godot-status={status}
      data-godot-player-x={snapshot?.player.x ?? ""}
      data-godot-player-y={snapshot?.player.y ?? ""}
      data-godot-camera-zoom={snapshot?.camera.zoom ?? ""}
      data-input-blocked={inputBlocked ? "true" : "false"}
      data-keyboard-blocked={keyboardBlocked ? "true" : "false"}
    >
      <section ref={bindShellRef} className="rpg-shell godot-rpg-shell" aria-label="7:55 Godot 横屏游戏">
        <iframe
          ref={iframeRef}
          className="godot-rpg-frame"
          src={iframeSrc}
          title="7:55 Godot 校园运行时"
          allow="autoplay; fullscreen"
          allowFullScreen
          tabIndex={0}
          onPointerDown={() => iframeRef.current?.focus()}
        />

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
          <button type="button" onClick={() => bridgeRef.current?.sendCommand("recenter")}>定位人物</button>
        </div>

        <nav className="rpg-camera-actions" aria-label="Godot 地图视角">
          <button type="button" aria-label="放大地图" onClick={() => bridgeRef.current?.sendCommand("zoom", { delta: 0.1 })}>+</button>
          <button type="button" aria-label="缩小地图" onClick={() => bridgeRef.current?.sendCommand("zoom", { delta: -0.1 })}>−</button>
        </nav>

        <aside className={`godot-runtime-status is-${status}`} role="status" aria-live="polite">
          <span>{status === "ready" ? "MIGRATION ACTIVE" : status.toUpperCase()}</span>
          <strong>{engineLabel}</strong>
          <small>角色 {playerPosition} · {snapshot?.checkpoint ?? state.rpgCheckpoint}</small>
        </aside>

        {status === "error" ? (
          <section className="godot-runtime-error" role="alert">
            <strong>Godot 运行时未就绪</strong>
            <p>{errorMessage}</p>
            <code>npm run godot:export:web</code>
          </section>
        ) : null}

        {state.actOne.controlsInstalled && touchControls ? (
          <nav className="rpg-touch-controls godot-touch-controls" aria-label="Godot RPG 操作键">
            <button type="button" aria-label="向上" disabled={interactionBlocked} onPointerDown={(event) => startDirection(event, 0, -1)}>↑</button>
            <button type="button" aria-label="向左" disabled={interactionBlocked} onPointerDown={(event) => startDirection(event, -1, 0)}>←</button>
            <button type="button" aria-label="向下" disabled={interactionBlocked} onPointerDown={(event) => startDirection(event, 0, 1)}>↓</button>
            <button type="button" aria-label="向右" disabled={interactionBlocked} onPointerDown={(event) => startDirection(event, 1, 0)}>→</button>
            <button type="button" className="interact" disabled>迁移中</button>
          </nav>
        ) : null}

        <div className="rpg-rotate-hint" role="status">请将设备横过来继续 Godot RPG</div>
      </section>
    </main>
  );
}
