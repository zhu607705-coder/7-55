import { useEffect, useRef, useState } from "react";
import type { EventBus } from "../core/EventBus";

interface Toast {
  id: number;
  text: string;
  tone: "system" | "xiaoying" | "task";
}

interface ToastLayerProps {
  events: EventBus;
}

/** 全局像素气泡：系统吐槽 / 小影台词 / 任务更新共用。订阅 eventBus 的 toast 事件。 */
export function ToastLayer({ events }: ToastLayerProps) {
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
      setToasts((prev) => [...prev.slice(-2), { id, text, tone }]);
      window.setTimeout(() => {
        setToasts((prev) => prev.filter((t) => t.id !== id));
      }, durationMs);
    });
  }, [events]);

  if (toasts.length === 0) {
    return null;
  }

  return (
    <div className="toast-layer" role="status" aria-live="polite">
      {toasts.map((toast) => (
        <p key={toast.id} className={`px-toast tone-${toast.tone}`}>
          {toast.tone === "task" ? "📌 " : null}
          {toast.text}
        </p>
      ))}
    </div>
  );
}
