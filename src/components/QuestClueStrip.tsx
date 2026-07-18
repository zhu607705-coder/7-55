import { useEffect, useMemo, useState } from "react";
import type { EventBus } from "../core/EventBus";
import type { SceneRouter } from "../core/SceneRouter";
import { selectQuestViewModel } from "../core/QuestModel";
import type { GameState, ItemId, QuestViewModel } from "../core/types";
import { ITEM_CATALOG } from "../data/itemCatalog";
import { ItemInspectDialog } from "./ItemInspectDialog";

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

export function isQuestCluePhase(): boolean {
  return true;
}

export function QuestTaskBar({
  state,
  events,
  router,
  variant = "phone",
  portalRoot,
  onNavigate
}: QuestTaskBarProps) {
  const quest = useMemo(() => selectQuestViewModel(state), [state]);
  const [open, setOpen] = useState(false);
  const [hintCount, setHintCount] = useState(0);
  const [documentItem, setDocumentItem] = useState<ItemId | null>(null);
  const digitSlots = [state.digits.d1, state.digits.d2, state.digits.d3, state.digits.d4];
  const acquiredDigitCount = digitSlots.filter(Boolean).length;
  const showDigitHint = quest.chapter === "chapter_one"
    && (state.flags.codeScattered || acquiredDigitCount > 0);
  const digitHintText = digitSlots.map((digit) => digit ?? "?").join(" ");
  const digitHintAria = `已找到的签到数字：${digitSlots
    .map((digit, index) => `第${index + 1}位${digit ?? "未找到"}`)
    .join("，")}`;

  useEffect(() => {
    setHintCount(0);
  }, [quest.id, quest.objective]);

  function navigate() {
    events.emit("quest_navigation_requested", {
      questId: quest.id,
      targetSurface: quest.targetSurface,
      recommendedScene: quest.recommendedScene
    });
    if (onNavigate) {
      onNavigate(quest);
    } else if (quest.recommendedScene) {
      router?.goTo(quest.recommendedScene);
    }
    setOpen(false);
  }

  return (
    <aside
      className={`quest-task-bar quest-task-bar--${variant} ${open ? "is-open" : ""}`.trim()}
      role="region"
      aria-label="当前任务"
      data-quest-id={quest.id}
    >
      <button
        type="button"
        className="quest-task-trigger"
        aria-label={`${CHAPTER_LABEL[quest.chapter]}任务：${quest.title}。当前目标：${quest.objective}。当前进度：${quest.completed}/${quest.total}${showDigitHint ? `。签到数字提示：${digitHintText}` : ""}。点击查看详情`}
        aria-expanded={open}
        aria-controls={`quest-drawer-${variant}`}
        title="点击查看当前任务和进度"
        onPointerDown={(event) => event.stopPropagation()}
        onPointerUp={(event) => event.stopPropagation()}
        onClick={(event) => {
          event.stopPropagation();
          setOpen((value) => !value);
        }}
      >
        <span>{CHAPTER_LABEL[quest.chapter]}</span>
        <strong className="quest-task-trigger-copy">
          <span>{quest.objective}</span>
          {showDigitHint ? (
            <em className="quest-task-digit-hint" aria-label={digitHintAria}>
              签到码 {digitHintText}
            </em>
          ) : null}
        </strong>
        <b>{quest.completed}/{quest.total}</b>
      </button>

      {open ? (
        <section id={`quest-drawer-${variant}`} className="quest-task-drawer" aria-label="任务详情">
          <header>
            <div>
              <small>{CHAPTER_LABEL[quest.chapter]}</small>
              <h2>{quest.title}</h2>
            </div>
            <button type="button" aria-label="关闭任务详情" onClick={() => setOpen(false)}>×</button>
          </header>

          <div className="quest-task-overview">
            <section>
              <span>当前任务</span>
              <strong>{quest.title}</strong>
            </section>
            <section>
              <span>当前进度</span>
              <strong>{quest.completed} / {quest.total}</strong>
            </section>
          </div>

          {showDigitHint ? (
            <section className="quest-task-digits" aria-label={digitHintAria}>
              <header>
                <span>签到数字提示</span>
                <strong>{acquiredDigitCount} / 4</strong>
              </header>
              <div>
                {digitSlots.map((digit, index) => (
                  <span key={index} className={digit ? "is-acquired" : ""}>
                    <small>第 {index + 1} 位</small>
                    <b>{digit ?? "?"}</b>
                  </span>
                ))}
              </div>
            </section>
          ) : null}

          <div className="quest-task-objective">
            <span>下一步目标</span>
            <strong>{quest.objective}</strong>
            <b>{quest.completed} / {quest.total}</b>
          </div>

          <ol className="quest-task-steps" aria-label="任务步骤">
            {quest.steps.map((step) => {
              const document = step.itemId ? ITEM_CATALOG[step.itemId].document : undefined;
              return (
                <li key={step.id} className={`is-${step.status}`}>
                  <i aria-hidden="true">{step.status === "completed" ? "✓" : step.status === "active" ? "→" : "·"}</i>
                  <span>{step.label}</span>
                  {step.status === "completed" && step.itemId && document ? (
                    <button type="button" onClick={() => setDocumentItem(step.itemId ?? null)}>查看材料</button>
                  ) : null}
                </li>
              );
            })}
          </ol>

          <section className="quest-task-hints" aria-label="渐进提示">
            <header>
              <strong>提示</strong>
              <span>{hintCount}/3</span>
            </header>
            {hintCount === 0 ? <p>需要时逐条展开，提示不会公布答案。</p> : null}
            {quest.hints.slice(0, hintCount).map((hint, index) => (
              <p key={hint}><b>{index + 1}</b>{hint}</p>
            ))}
            <button
              type="button"
              disabled={hintCount >= 3}
              onClick={() => setHintCount((count) => Math.min(3, count + 1))}
            >
              {hintCount >= 3 ? "提示已全部展开" : "显示下一条提示"}
            </button>
          </section>

          <button type="button" className="quest-task-navigate" onClick={navigate}>
            {quest.targetSurface === "rpg" ? "前往地图" : "前往相关界面"}
          </button>
        </section>
      ) : null}

      <ItemInspectDialog
        open={documentItem !== null}
        itemId={documentItem}
        variant={variant === "phone" ? "phone" : "rpg"}
        portalRoot={portalRoot}
        onClose={() => setDocumentItem(null)}
      />
    </aside>
  );
}

/** 兼容旧组件名；所有调用共享同一个交互式任务栏实现。 */
export const QuestClueStrip = QuestTaskBar;
