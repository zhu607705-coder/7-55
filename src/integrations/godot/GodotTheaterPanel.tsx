import { useEffect, useRef, useState } from "react";
import type { EventBus } from "../../core/EventBus";
import type { GameState, TheaterProgramId } from "../../core/types";

export type GodotTheaterPanelKind = "code" | "program";

interface GodotTheaterPanelProps {
  kind: GodotTheaterPanelKind;
  state: GameState;
  events: EventBus;
  onClose: () => void;
}

const PROGRAM_LABELS: Record<TheaterProgramId, string> = {
  opening: "开场",
  spotlight: "追光",
  finale: "谢幕"
};

export function GodotTheaterPanel({
  kind,
  state,
  events,
  onClose
}: GodotTheaterPanelProps) {
  const [code, setCode] = useState("");
  const [feedback, setFeedback] = useState("");
  const inputRef = useRef<HTMLInputElement | null>(null);
  const closeTimerRef = useRef<number | null>(null);

  useEffect(() => {
    if (kind === "code") inputRef.current?.focus();
  }, [kind]);

  useEffect(() => {
    const detach = events.subscribe((event) => {
      if (event.name === "theater_ticket_code_wrong") {
        setFeedback("取票码未通过。先在深色模式观察取票机，再切回浅色模式输入。");
      } else if (event.name === "theater_ticket_print_failed") {
        setFeedback("取票机吐出了另一半票根，系统正在拼合临时观演票。");
        if (closeTimerRef.current !== null) window.clearTimeout(closeTimerRef.current);
        closeTimerRef.current = window.setTimeout(onClose, 520);
      } else if (event.name === "theater_program_order_wrong") {
        setFeedback("节目顺序不匹配，最后一项已撤回。请根据深色模式残影重新判断。");
      } else if (event.name === "theater_program_order_solved") {
        onClose();
      }
    });
    return () => {
      detach();
      if (closeTimerRef.current !== null) window.clearTimeout(closeTimerRef.current);
      closeTimerRef.current = null;
    };
  }, [events, onClose]);

  const order = state.theaterHunt.programOrder;
  const collected = state.theaterHunt.collectedProgramIds;
  const codeReady = state.theaterHunt.ticketCodeRead;

  return (
    <div
      className="godot-theater-panel-scrim"
      role="presentation"
      onKeyDown={(event) => {
        if (event.key === "Escape") onClose();
      }}
    >
      <section
        className="godot-theater-panel"
        role="dialog"
        aria-modal="true"
        aria-labelledby="godot-theater-panel-title"
      >
        {kind === "code" ? (
          <>
            <header>
              <strong id="godot-theater-panel-title">剧院取票机</strong>
              <button type="button" aria-label="关闭取票机" onClick={onClose}>×</button>
            </header>
            <p>
              {codeReady
                ? "输入刚才在深色模式中读取到的四位取票码。"
                : "当前缺少取票码线索。关闭面板，切换深色模式，再站到取票机前查看。"}
            </p>
            <form
              onSubmit={(event) => {
                event.preventDefault();
                if (!codeReady || code.length !== 4) return;
                setFeedback("");
                events.emit("rpg_theater_ticket_code_submitted", { code });
              }}
            >
              <input
                ref={inputRef}
                aria-label="四位取票码"
                inputMode="numeric"
                pattern="[0-9]{4}"
                maxLength={4}
                placeholder="····"
                value={code}
                onChange={(event) => setCode(event.currentTarget.value.replace(/\D/g, "").slice(0, 4))}
              />
              <button type="submit" disabled={!codeReady || code.length !== 4}>提交取票码</button>
            </form>
          </>
        ) : (
          <>
            <header>
              <strong id="godot-theater-panel-title">灯光控制台 · 节目顺序</strong>
              <button type="button" aria-label="关闭节目顺序面板" onClick={onClose}>×</button>
            </header>
            <p>按你在深色模式中读到的残影顺序，依次选择三张节目单。</p>
            <div className="godot-theater-order" aria-label="当前节目顺序">
              {Array.from({ length: 3 }, (_, index) => (
                <span key={index}>{order[index] ? PROGRAM_LABELS[order[index]] : "待选"}</span>
              ))}
            </div>
            <div className="godot-theater-program-buttons">
              {collected.map((programId) => (
                <button
                  type="button"
                  key={programId}
                  disabled={order.includes(programId) || order.length >= 3}
                  onClick={() => events.emit("rpg_theater_program_order_set_requested", {
                    order: [...order, programId]
                  })}
                >
                  {PROGRAM_LABELS[programId]}
                </button>
              ))}
            </div>
            <div className="godot-theater-panel-actions">
              <button
                type="button"
                disabled={order.length === 0}
                onClick={() => events.emit("rpg_theater_program_order_set_requested", {
                  order: order.slice(0, -1)
                })}
              >
                撤回
              </button>
              <button
                type="button"
                disabled={order.length === 0}
                onClick={() => events.emit("rpg_theater_program_order_set_requested", { order: [] })}
              >
                清空
              </button>
              <button
                type="button"
                disabled={order.length !== 3}
                onClick={() => {
                  setFeedback("");
                  events.emit("rpg_theater_program_order_submit_requested");
                }}
              >
                提交顺序
              </button>
            </div>
          </>
        )}
        {feedback ? <p className="godot-theater-panel-feedback" role="status">{feedback}</p> : null}
      </section>
    </div>
  );
}
