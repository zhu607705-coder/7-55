import { useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { createPortal } from "react-dom";
import type { EventBus } from "../core/EventBus";
import type { SceneRouter } from "../core/SceneRouter";
import { isQuestTaskBarVisible, selectQuestViewModel } from "../core/QuestModel";
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

const CHAPTER_LABEL: Record<QuestViewModel["chapter"], string> = {
  chapter_one: "第 1 章",
  chapter_two: "第 2 章",
  chapter_three: "第 3 章"
};

function QuestDrawerLayer({
  children,
  portalRoot,
  variant
}: {
  children: ReactNode;
  portalRoot?: Element | null;
  variant: QuestTaskBarVariant;
}) {
  if ((variant === "phone" || variant === "rpg") && portalRoot) {
    return createPortal(children, portalRoot);
  }
  return children;
}

export function isQuestCluePhase(): boolean {
  return true;
}

export function QuestTaskBar({
  state,
  variant = "phone",
  portalRoot
}: QuestTaskBarProps) {
  const quest = useMemo(() => selectQuestViewModel(state), [state]);
  const visible = isQuestTaskBarVisible(state);
  const [open, setOpen] = useState(false);
  const [hintCount, setHintCount] = useState(0);
  const [updated, setUpdated] = useState(false);
  const previousQuestRef = useRef({ id: quest.id, objective: quest.objective });

  useEffect(() => {
    setHintCount(0);
  }, [quest.id]);

  useEffect(() => {
    const previous = previousQuestRef.current;
    previousQuestRef.current = { id: quest.id, objective: quest.objective };
    if (quest.id === previous.id && quest.objective === previous.objective) {
      return undefined;
    }
    setUpdated(true);
    const timer = window.setTimeout(() => setUpdated(false), 1050);
    return () => window.clearTimeout(timer);
  }, [quest.id, quest.objective]);

  useEffect(() => {
    if (!visible) setOpen(false);
  }, [visible]);

  if (!visible) return null;

  const hintTotal = quest.hints.length;
  return (
    <aside
      className={`quest-task-bar quest-task-bar--${variant} ${open ? "is-open" : ""} ${updated ? "has-objective-update" : ""}`.trim()}
      role="region"
      aria-label="当前任务"
      data-quest-id={quest.id}
      data-layout-zone={variant === "phone" ? "phone-quest" : undefined}
    >
      <button
        type="button"
        className="quest-task-trigger"
        aria-label={`${CHAPTER_LABEL[quest.chapter]}当前任务：${quest.objective}。点击查看任务提示`}
        aria-expanded={open}
        aria-controls={`quest-drawer-${variant}`}
        title="点击查看当前任务和提示"
        onPointerDown={(event) => event.stopPropagation()}
        onPointerUp={(event) => event.stopPropagation()}
        onClick={(event) => {
          event.stopPropagation();
          setOpen((value) => !value);
        }}
      >
        {variant === "phone" ? null : <span>{CHAPTER_LABEL[quest.chapter]}</span>}
        <strong className="quest-task-trigger-copy">
          <span>{variant === "phone" ? (open ? "收起任务" : "任务") : quest.objective}</span>
        </strong>
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
                <small>{CHAPTER_LABEL[quest.chapter]} · {quest.title}</small>
                <h2>任务栏</h2>
              </div>
              <button type="button" aria-label="关闭任务详情" onClick={() => setOpen(false)}>×</button>
            </header>

            <section className="quest-task-objective">
              <span>当前任务</span>
              <strong>{quest.objective}</strong>
            </section>

            <section className="quest-task-hints" aria-label="任务提示">
              <header>
                <strong>任务提示</strong>
                <span>{hintCount}/{hintTotal}</span>
              </header>
              {hintTotal === 0 ? <p>当前任务没有提示。</p> : null}
              {hintTotal > 0 && hintCount === 0 ? <p>需要时点击下方按钮，逐条查看提示。</p> : null}
              {quest.hints.slice(0, hintCount).map((hint, index) => (
                <p key={`${index}-${hint}`}><b>{index + 1}</b>{hint}</p>
              ))}
              {hintTotal > 0 ? (
                <button
                  type="button"
                  disabled={hintCount >= hintTotal}
                  onClick={() => setHintCount((count) => Math.min(hintTotal, count + 1))}
                >
                  {hintCount >= hintTotal ? "提示已全部展开" : "显示下一条提示"}
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
