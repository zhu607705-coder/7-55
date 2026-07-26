import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import type { EventBus } from "../../core/EventBus";
import type { GameStore } from "../../core/types";
import {
  clearRpgRuntimeDebugState,
  setRpgRuntimeDebugState,
  type RpgRuntimeDebugState
} from "../../scenes/rpg/RpgRuntimeDebug";
import {
  createGodotRequestId,
  GODOT_REACT_MESSAGE_SOURCE,
  GODOT_RPG_PROTOCOL_VERSION,
  inspectGodotRuntimeProtocolVersion,
  parseGodotRuntimeMessage,
  selectGodotTheaterSnapshot,
  type GodotHostCommandName,
  type GodotHostMessage
} from "./GodotRpgProtocol";

interface GodotRpgFrameProps {
  store: GameStore;
  events: EventBus;
  inputBlocked: boolean;
  onRuntimeFailure: (reason: string) => void;
}

type RuntimeStatus = "loading" | "ready";

const STARTUP_TIMEOUT_MS = 20_000;
const THEATER_INTERACTION_HINTS: Readonly<Record<string, string>> = {
  theater_poster: "拖动油渍纸巾至入口海报",
  theater_ticket_kiosk: "空格键　操作取票机",
  theater_ticket_gate: "拖动临时观演票至闸机右侧读票器",
  theater_program_opening: "空格键　拾取开场节目单",
  theater_program_spotlight: "空格键　拾取追光节目单",
  theater_program_finale: "空格键　拾取终场节目单",
  theater_prop_box: "空格键　检查后台道具箱",
  theater_prop_scanner: "拖动临时观演票至票据扫描器",
  theater_backstage_vent: "拖动荧光粉刷至后台通风口",
  theater_exit: "空格键　离开剧院"
};
const FORWARDED_COMMANDS = new Set<GodotHostCommandName>([
  "rpg_direction_changed",
  "rpg_interact",
  "rpg_inventory_drag_started",
  "rpg_inventory_drag_ended",
  "rpg_inventory_drop_requested"
]);

function exportUrl(): string {
  const base = import.meta.env.BASE_URL || "/";
  return new URL(`${base}godot/theater/index.html?embed=1`, window.location.origin).toString();
}

function normalizeGodotDebug(value: Record<string, unknown>): RpgRuntimeDebugState | null {
  if (
    value.engine !== "godot"
    || typeof value.coordinateSystem !== "string"
    || typeof value.world !== "object"
    || typeof value.player !== "object"
    || typeof value.camera !== "object"
  ) {
    return null;
  }
  return value as unknown as RpgRuntimeDebugState;
}

export function GodotRpgFrame({
  store,
  events,
  inputBlocked,
  onRuntimeFailure
}: GodotRpgFrameProps) {
  const iframeRef = useRef<HTMLIFrameElement | null>(null);
  const readyRef = useRef(false);
  const sequenceRef = useRef(0);
  const revisionRef = useRef(0);
  const [status, setStatus] = useState<RuntimeStatus>("loading");
  const [interactionHint, setInteractionHint] = useState("");
  const src = useMemo(exportUrl, []);

  const post = useCallback((message: GodotHostMessage) => {
    iframeRef.current?.contentWindow?.postMessage(
      JSON.stringify(message),
      window.location.origin
    );
  }, []);

  const nextRequestId = useCallback((prefix: string) => {
    sequenceRef.current += 1;
    return createGodotRequestId(prefix, sequenceRef.current);
  }, []);

  const sendSnapshot = useCallback(() => {
    if (!readyRef.current) return;
    revisionRef.current += 1;
    post({
      source: GODOT_REACT_MESSAGE_SOURCE,
      version: GODOT_RPG_PROTOCOL_VERSION,
      type: "state_snapshot",
      sceneId: "theater_interior",
      requestId: nextRequestId("snapshot"),
      revision: revisionRef.current,
      snapshot: selectGodotTheaterSnapshot(store.getState(), inputBlocked)
    });
  }, [inputBlocked, nextRequestId, post, store]);

  useEffect(() => {
    const onMessage = (event: MessageEvent<unknown>) => {
      if (event.origin !== window.location.origin || event.source !== iframeRef.current?.contentWindow) {
        return;
      }
      const runtimeVersion = inspectGodotRuntimeProtocolVersion(event.data);
      if (runtimeVersion !== null && runtimeVersion !== GODOT_RPG_PROTOCOL_VERSION) {
        onRuntimeFailure(
          `Godot runtime contract ${runtimeVersion} does not match host ${GODOT_RPG_PROTOCOL_VERSION}.`
        );
        return;
      }
      const message = parseGodotRuntimeMessage(event.data);
      if (!message || message.sceneId !== "theater_interior") return;
      if (message.type === "runtime_ready") {
        readyRef.current = true;
        setStatus("ready");
        sendSnapshot();
        return;
      }
      if (message.type === "intent") {
        events.emit(message.name, message.payload);
        return;
      }
      if (message.type === "debug_snapshot") {
        const debug = normalizeGodotDebug(message.debug);
        if (debug) {
          setRpgRuntimeDebugState(debug);
          const activeTarget = debug.theater?.activeTarget ?? "";
          const phase = debug.theater?.phase ?? "";
          setInteractionHint(
            activeTarget === "theater_light_console"
              ? phase === "program_search"
                ? "空格键　查看灯光控制台"
                : "拖动聚光灯遥控器至灯光控制台"
              : THEATER_INTERACTION_HINTS[activeTarget] ?? ""
          );
        }
        return;
      }
      onRuntimeFailure(`${message.code}: ${message.detail}`);
    };
    window.addEventListener("message", onMessage);
    return () => window.removeEventListener("message", onMessage);
  }, [events, onRuntimeFailure, sendSnapshot]);

  useEffect(() => store.subscribe(sendSnapshot), [sendSnapshot, store]);

  useEffect(() => {
    return events.subscribe((event) => {
      if (!FORWARDED_COMMANDS.has(event.name as GodotHostCommandName) || !readyRef.current) return;
      post({
        source: GODOT_REACT_MESSAGE_SOURCE,
        version: GODOT_RPG_PROTOCOL_VERSION,
        type: "host_command",
        sceneId: "theater_interior",
        requestId: nextRequestId("command"),
        command: {
          name: event.name as GodotHostCommandName,
          payload: event.payload ?? {}
        }
      });
    });
  }, [events, nextRequestId, post]);

  useEffect(() => {
    const sendLifecycle = () => {
      if (!readyRef.current) return;
      post({
        source: GODOT_REACT_MESSAGE_SOURCE,
        version: GODOT_RPG_PROTOCOL_VERSION,
        type: "lifecycle",
        sceneId: "theater_interior",
        requestId: nextRequestId("lifecycle"),
        paused: document.visibilityState !== "visible",
        inputBlocked
      });
    };
    document.addEventListener("visibilitychange", sendLifecycle);
    sendLifecycle();
    return () => document.removeEventListener("visibilitychange", sendLifecycle);
  }, [inputBlocked, nextRequestId, post]);

  useEffect(() => {
    const timer = window.setTimeout(() => {
      if (!readyRef.current) onRuntimeFailure("Godot Web runtime startup timed out.");
    }, STARTUP_TIMEOUT_MS);
    return () => window.clearTimeout(timer);
  }, [onRuntimeFailure]);

  useEffect(() => {
    return () => {
      readyRef.current = false;
      clearRpgRuntimeDebugState();
    };
  }, []);

  return (
    <>
      <iframe
        ref={iframeRef}
        className="godot-rpg-frame"
        data-rpg-canvas
        title="7:55 Godot 剧院场景"
        src={src}
        allow="autoplay; fullscreen; gamepad"
        onLoad={() => {
          post({
            source: GODOT_REACT_MESSAGE_SOURCE,
            version: GODOT_RPG_PROTOCOL_VERSION,
            type: "host_hello",
            sceneId: "theater_interior",
            requestId: nextRequestId("hello")
          });
        }}
        onError={() => onRuntimeFailure("Godot Web export could not be loaded.")}
      />
      {status === "loading" ? (
        <div className="godot-rpg-loading" role="status">
          <strong>正在载入 Godot 剧院</strong>
          <span>若 WebGL 2 或 WebAssembly 不可用，将自动回到 Phaser 场景。</span>
        </div>
      ) : null}
      {status === "ready" && interactionHint ? (
        <div className="godot-rpg-interaction-hint" role="status">
          {interactionHint}
        </div>
      ) : null}
    </>
  );
}
