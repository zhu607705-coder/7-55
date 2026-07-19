import { useEffect, useRef, useState } from "react";
import type { EventBus } from "../core/EventBus";
import type { GameState } from "../core/types";
import { GameSubtitleFrame, type GameSubtitleTone } from "./GameSubtitleFrame";

interface Toast {
  id: number;
  text: string;
  tone: "system" | "xiaoying" | "task";
  durationMs: number;
}

interface ToastLayerProps {
  events: EventBus;
  state: GameState;
  surface?: "phone" | "rpg";
}

const SUBTITLE_TONE_BY_TOAST: Readonly<Record<Toast["tone"], GameSubtitleTone>> = {
  system: "system",
  xiaoying: "narrator",
  task: "task"
};

/** 全局像素气泡：系统吐槽 / 小影台词 / 任务更新共用。订阅 eventBus 的 toast 事件。 */
export function ToastLayer({ events, state, surface = "phone" }: ToastLayerProps) {
  const [toasts, setToasts] = useState<Toast[]>([]);
  const nextId = useRef(1);

  useEffect(() => {
    return events.subscribe((event) => {
      if (event.name !== "toast") {
        return;
      }
      const text = String(event.payload?.text ?? "");
      const tone = (event.payload?.tone as Toast["tone"]) ?? "system";
      if (!text) {
        return;
      }

      const id = nextId.current++;
      const durationMs = Number(event.payload?.durationMs) || (tone === "task" ? 4200 : 3000);
      setToasts((prev) => [...prev.slice(-2), { id, text, tone, durationMs }]);
      window.setTimeout(() => {
        setToasts((prev) => prev.filter((t) => t.id !== id));
      }, durationMs);
    });
  }, [events]);

  if (toasts.length === 0) {
    return null;
  }

  return (
    <div className={`toast-layer subtitle-layer--${surface}`} role="status" aria-live="polite" aria-atomic="true">
      {toasts.map((toast) => (
        <GameSubtitleFrame
          key={toast.id}
          text={toast.text}
          tone={SUBTITLE_TONE_BY_TOAST[toast.tone]}
          state={state}
          durationMs={toast.durationMs}
          className={`px-toast tone-${toast.tone}`}
        />
      ))}
    </div>
  );
}
