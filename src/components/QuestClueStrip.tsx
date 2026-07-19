import { useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { createPortal } from "react-dom";
import type { EventBus } from "../core/EventBus";
import type { SceneRouter } from "../core/SceneRouter";
import { selectQuestViewModel } from "../core/QuestModel";
import type { GameState, QuestViewModel } from "../core/types";

export type QuestTaskBarVariant = "phone" | "rpg" | "desktop";

export interface QuestTaskBarProps {
  state: GameState;
  events: EventBus;
  router?: SceneRouter;
  variant?: QuestTaskBarVariant;
  portalRoot?: Element | null;
  onNavigate?: (quest: QuestViewModel) => void;
}

function QuestDrawerLayer({
  children,
  portalRoot,
  variant
}: {
  children: ReactNode;
  portalRoot?: Element | null;
  variant: QuestTaskBarVariant;
}) {
  if (variant === "rpg" && portalRoot) {
    return createPortal(children, portalRoot);
  }
  return children;
}

const HIDDEN_CHAPTER_TWO_PHASES = new Set([
  "friend_message_required",
  "system_required",
  "inventory_required",
  "system_return_required"
]);

export function isQuestCluePhase(state: GameState): boolean {
  return !HIDDEN_CHAPTER_TWO_PHASES.has(state.actOne.phase);
}

export function QuestTaskBar({
  state,
  variant = "phone",
  portalRoot
}: QuestTaskBarProps) {
  const quest = useMemo(() => selectQuestViewModel(state), [state]);
  const taskBarVisible = isQuestCluePhase(state);
  const [open, setOpen] = useState(false);
  const [revealedHintCount, setRevealedHintCount] = useState(0);
  const [updateCue, setUpdateCue] = useState(false);
  const previousQuestRef = useRef({
    id: quest.id,
    objective: quest.objective
  });

  useEffect(() => {
    const previous = previousQuestRef.current;
    previousQuestRef.current = {
      id: quest.id,
      objective: quest.objective
    };
    if (quest.id === previous.id && quest.objective === previous.objective) {
      return undefined;
    }
    setOpen(false);
    setRevealedHintCount(0);
    setUpdateCue(true);
    const timer = window.setTimeout(() => setUpdateCue(false), 1050);
    return () => window.clearTimeout(timer);
  }, [quest.id, quest.objective]);

  if (!taskBarVisible) {
    return null;
  }

  return (
    <aside
      className={`quest-task-bar quest-task-bar--${variant} ${open ? "is-open" : ""} ${updateCue ? "has-objective-update" : ""}`.trim()}
      role="region"
      aria-label="当前任务"
      data-quest-id={quest.id}
    >
      <button
        type="button"
        className="quest-task-trigger"
        aria-label={`当前任务：${quest.objective}。点击查看任务提示`}
        aria-expanded={open}
        aria-controls={`quest-drawer-${variant}`}
        title="点击展开任务提示"
        onPointerDown={(event) => event.stopPropagation()}
        onPointerUp={(event) => event.stopPropagation()}
        onClick={(event) => {
          event.stopPropagation();
          setOpen((value) => !value);
        }}
      >
        <span>当前任务</span>
        <strong className="quest-task-trigger-copy">
          <span>{quest.objective}</span>
        </strong>
        <b aria-hidden="true">{open ? "−" : "+"}</b>
      </button>

      {open ? (
        <QuestDrawerLayer variant={variant} portalRoot={portalRoot}>
        <section
          id={`quest-drawer-${variant}`}
          className={`quest-task-drawer quest-task-drawer--${variant}`}
          aria-label="任务详情"
        >
          <header>
            <div>
              <small>当前任务</small>
              <h2>{quest.objective}</h2>
            </div>
            <button type="button" aria-label="关闭任务详情" onClick={() => setOpen(false)}>×</button>
          </header>

          <section className="quest-task-hints" aria-label="任务提示">
            <header>
              <strong>任务提示</strong>
              <span>{revealedHintCount}/3</span>
            </header>
            {quest.hints.slice(0, revealedHintCount).map((hint, index) => (
              <p key={hint}><b>{index + 1}</b>{hint}</p>
            ))}
            {revealedHintCount < quest.hints.length ? (
              <button
                type="button"
                onClick={(event) => {
                  event.stopPropagation();
                  setRevealedHintCount((count) => Math.min(count + 1, quest.hints.length));
                }}
              >
                {revealedHintCount === 0 ? "查看第一条提示" : "继续查看下一条提示"}
              </button>
            ) : null}
          </section>
        </section>
        </QuestDrawerLayer>
      ) : null}
    </aside>
  );
}

/** 兼容旧组件名；所有调用共享同一个交互式任务栏实现。 */
export const QuestClueStrip = QuestTaskBar;
