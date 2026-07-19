import { useEffect, useRef, useState, type CSSProperties, type ReactNode } from "react";
import type { EventBus } from "../core/EventBus";
import type { SceneRouter } from "../core/SceneRouter";
import type { GameState, QuestViewModel, SceneId } from "../core/types";
import { ControlCenter } from "./ControlCenter";
import { InventoryBar } from "./InventoryBar";
import { PresentationLayer } from "./PresentationLayer";
import { QuestTaskBar } from "./QuestClueStrip";
import { StatusBar } from "./StatusBar";
import { ToastLayer } from "./ToastLayer";
import { useChiptune } from "./useChiptune";
import { PHONE_VIEWPORT_HEIGHT, PHONE_VIEWPORT_WIDTH } from "./PhoneViewport";

interface PhoneShellProps {
  state: GameState;
  router: SceneRouter;
  events: EventBus;
  children: ReactNode;
  embedded?: boolean;
  showTaskBar?: boolean;
  showGlobalLayers?: boolean;
  onTaskNavigate?: (quest: QuestViewModel) => void;
}

/** 这些场景不显示全局状态栏 / 物品栏（闹钟、起床、纯黑结局自带全屏演出） */
const BARE_SCENES: SceneId[] = ["alarm", "desktop", "ending"];
const STAGE_EDGE_PADDING = 18;
const MIN_PHONE_SCALE = 0.35;

interface SafeAreaInsets {
  top: number;
  right: number;
  bottom: number;
  left: number;
}

function getSafeAreaInsets(): SafeAreaInsets {
  if (typeof document === "undefined" || !document.body) {
    return { top: 0, right: 0, bottom: 0, left: 0 };
  }
  const probe = document.createElement("div");
  probe.style.cssText = [
    "position:fixed",
    "visibility:hidden",
    "pointer-events:none",
    "padding-top:env(safe-area-inset-top)",
    "padding-right:env(safe-area-inset-right)",
    "padding-bottom:env(safe-area-inset-bottom)",
    "padding-left:env(safe-area-inset-left)"
  ].join(";");
  document.body.appendChild(probe);
  const style = window.getComputedStyle(probe);
  const insets = {
    top: Number.parseFloat(style.paddingTop) || 0,
    right: Number.parseFloat(style.paddingRight) || 0,
    bottom: Number.parseFloat(style.paddingBottom) || 0,
    left: Number.parseFloat(style.paddingLeft) || 0
  };
  probe.remove();
  return insets;
}

function getPhoneScale(container?: HTMLElement | null, embedded = false) {
  if (typeof window === "undefined") {
    return 1;
  }
  const viewport = window.visualViewport;
  const width = embedded && container ? container.clientWidth : viewport?.width ?? window.innerWidth;
  const height = embedded && container ? container.clientHeight : viewport?.height ?? window.innerHeight;
  const safeArea = embedded ? { top: 0, right: 0, bottom: 0, left: 0 } : getSafeAreaInsets();
  const edgePadding = embedded ? 10 : STAGE_EDGE_PADDING;
  const horizontalPadding = Math.max(edgePadding, safeArea.left) + Math.max(edgePadding, safeArea.right);
  const verticalPadding = Math.max(edgePadding, safeArea.top) + Math.max(edgePadding, safeArea.bottom);
  const fitWidth = (width - horizontalPadding) / PHONE_VIEWPORT_WIDTH;
  const fitHeight = (height - verticalPadding) / PHONE_VIEWPORT_HEIGHT;
  return Math.max(MIN_PHONE_SCALE, Math.min(1, fitWidth, fitHeight));
}

export function PhoneShell({
  state,
  router,
  events,
  children,
  embedded = false,
  showTaskBar = true,
  showGlobalLayers = true,
  onTaskNavigate
}: PhoneShellProps) {
  const [shake, setShake] = useState<"" | "shake" | "shake-strong">("");
  const [phoneScale, setPhoneScale] = useState(() => getPhoneScale(null, embedded));
  const stageRef = useRef<HTMLElement>(null);
  const frameRef = useRef<HTMLElement>(null);
  const bare = BARE_SCENES.includes(state.currentScene);
  const inventorySuppressed = ["friend_message_required", "system_required", "inventory_required"].includes(
    state.actOne.phase
  );
  const hasInventoryItem = Object.values(state.items).some(Boolean) && !inventorySuppressed;
  // 音乐全局播放（不局限于控制中心打开时）
  useChiptune(state.ui.musicPlaying);

  useEffect(() => {
    return events.subscribe((event) => {
      if (event.name !== "screen_shake") {
        return;
      }
      setShake(event.payload?.strong ? "shake-strong" : "shake");
      window.setTimeout(() => setShake(""), 700);
    });
  }, [events]);

  useEffect(() => {
    const updateScale = () => setPhoneScale(getPhoneScale(stageRef.current, embedded));
    updateScale();
    const observer = typeof ResizeObserver === "undefined" ? null : new ResizeObserver(updateScale);
    if (stageRef.current) observer?.observe(stageRef.current);
    window.addEventListener("resize", updateScale);
    window.addEventListener("orientationchange", updateScale);
    window.visualViewport?.addEventListener("resize", updateScale);
    window.visualViewport?.addEventListener("scroll", updateScale);
    return () => {
      observer?.disconnect();
      window.removeEventListener("resize", updateScale);
      window.removeEventListener("orientationchange", updateScale);
      window.visualViewport?.removeEventListener("resize", updateScale);
      window.visualViewport?.removeEventListener("scroll", updateScale);
    };
  }, [embedded]);

  // 亮度遮罩：亮度越低越暗（最多 0.3），拉满则完全通透
  const veilOpacity = Math.max(0, (70 - state.ui.brightness) / 70) * 0.3;
  const scaleStyle = {
    "--phone-scale": phoneScale,
    "--phone-stage-width": `${PHONE_VIEWPORT_WIDTH * phoneScale}px`,
    "--phone-stage-height": `${PHONE_VIEWPORT_HEIGHT * phoneScale}px`
  } as CSSProperties;

  return (
    <main ref={stageRef} className={`app-stage ${embedded ? "is-embedded" : ""}`.trim()} style={scaleStyle}>
      <section className="phone-scale-box" aria-label="7:55 scaled phone viewport">
        <div className="phone-scale-shell">
          <section ref={frameRef} className={`phone-frame ${shake}`} role="application" aria-label="7:55 phone runtime">
            <section className="scene-surface">{children}</section>
            {!bare ? <StatusBar state={state} /> : null}
            {!bare && showTaskBar ? (
              <QuestTaskBar
                state={state}
                router={router}
                events={events}
                variant="phone"
                portalRoot={frameRef.current}
                onNavigate={onTaskNavigate}
              />
            ) : null}
            {!bare && hasInventoryItem ? <InventoryBar state={state} /> : null}
            <div className="brightness-veil" style={{ opacity: veilOpacity }} aria-hidden="true" />
            <ControlCenter state={state} />
            {showGlobalLayers ? <PresentationLayer events={events} /> : null}
            {showGlobalLayers ? <ToastLayer events={events} state={state} /> : null}
          </section>
        </div>
      </section>
    </main>
  );
}
