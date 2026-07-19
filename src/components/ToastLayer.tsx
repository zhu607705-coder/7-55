import { useEffect, useRef, useState } from "react";
import type { EventBus } from "../core/EventBus";
import { selectIdentityReadable } from "../core/IdentityAccess";
import type { GameState } from "../core/types";
import actOneContent from "../data/act-one-bootstrap.content.json";

interface Toast {
  id: number;
  text: string;
  tone: "system" | "xiaoying" | "task";
}

interface ToastLayerProps {
  events: EventBus;
  state: GameState;
}

function visibleToastText(text: string, identityReadable: boolean): string {
  if (identityReadable) return text;
  return text
    .replaceAll(actOneContent.studentName, "身份信息")
    .replaceAll(actOneContent.studentId, "身份编号");
}

/** 全局像素气泡：系统吐槽 / 小影台词 / 任务更新共用。订阅 eventBus 的 toast 事件。 */
export function ToastLayer({ events, state }: ToastLayerProps) {
  const [toasts, setToasts] = useState<Toast[]>([]);
  const nextId = useRef(1);
  const identityReadable = selectIdentityReadable(state);

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
          {visibleToastText(toast.text, identityReadable)}
        </p>
      ))}
    </div>
  );
}
