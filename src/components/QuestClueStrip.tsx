import { useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { createPortal } from "react-dom";
import { InvestigationRing } from "./InvestigationRing";
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
  chapter_three: "第 3 章",
  chapter_four: "第 4 章"
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
  events,
  router,
  variant = "phone",
  portalRoot,
  onNavigate
}: QuestTaskBarProps) {
  const quest = useMemo(() => selectQuestViewModel(state), [state]);
  const visible = isQuestTaskBarVisible(state);
  const chapterFourPresentation = quest.chapterFourPresentation;
  const [open, setOpen] = useState(false);
  const [hintCount, setHintCount] = useState(0);
  const [updated, setUpdated] = useState(false);
  const [progressUpdated, setProgressUpdated] = useState(false);
  const previousQuestRef = useRef({ id: quest.id, objective: quest.objective });
  const previousProgressRef = useRef(chapterFourPresentation?.localProgress ?? "");

  useEffect(() => {
    setHintCount(0);
    setOpen(false);
  }, [quest.id, quest.objective]);

  useEffect(() => {
    const progress = chapterFourPresentation?.localProgress ?? "";
    const previous = previousProgressRef.current;
    previousProgressRef.current = progress;
    if (!progress || progress === previous) return undefined;
    setProgressUpdated(true);
    const timer = window.setTimeout(() => setProgressUpdated(false), 1050);
    return () => window.clearTimeout(timer);
  }, [chapterFourPresentation?.localProgress]);

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
  const parallelProgress = quest.parallelProgress;
  const parallelBranchesAreRpgStatusNodes = Boolean(
    quest.parallelBranches?.length
    && quest.parallelBranches.every((branch) => (
      (branch.targetSurface ?? quest.targetSurface) === "rpg"
      && !branch.recommendedScene
    ))
  );
  const parallelObjective = parallelProgress
    ? `${quest.objective}（${parallelProgress.completed}/${parallelProgress.total}）`
    : quest.objective;
  const digitSlots = [state.digits.d1, state.digits.d2, state.digits.d3, state.digits.d4];
  const acquiredDigitCount = digitSlots.filter(Boolean).length;
  const showDigitHint = quest.chapter === "chapter_one"
    && (state.flags.codeScattered || acquiredDigitCount > 0);
  const digitHintText = digitSlots.map((digit) => digit ?? "?").join(" ");
  const digitHintAria = `已找到的签到数字：${digitSlots
    .map((digit, index) => `第${index + 1}位${digit ?? "未找到"}`)
    .join("，")}`;
  const questIncomplete = quest.completed < quest.total;
  const hasNavigationHandler = Boolean(onNavigate || (router && quest.recommendedScene));
  const redundantRpgNavigation = variant !== "phone" && quest.targetSurface === "rpg";
  const showNavigation = questIncomplete && hasNavigationHandler && !redundantRpgNavigation;
  const navigationLabel = quest.targetSurface === "rpg" ? "返回任务现场" : "前往相关界面";
  const chapterFourAria = chapterFourPresentation
    ? `。${chapterFourPresentation.stageLabel}。${chapterFourPresentation.timeStateLabel}。${chapterFourPresentation.floor}。${chapterFourPresentation.localProgress}`
    : "";

  function navigateToQuest() {
    events.emit("quest_navigation_requested", {
      questId: quest.id,
      targetSurface: quest.targetSurface,
      recommendedScene: quest.recommendedScene
    });
    if (onNavigate) {
      onNavigate(quest);
    } else if (router && quest.recommendedScene) {
      router.goTo(quest.recommendedScene);
    }
    setOpen(false);
  }

  function navigateToParallelBranch(branch: NonNullable<QuestViewModel["parallelBranches"]>[number]) {
    const branchQuest: QuestViewModel = {
      ...quest,
      id: `${quest.id}:${branch.id}`,
      objective: branch.label,
      targetSurface: branch.targetSurface ?? quest.targetSurface,
      recommendedScene: branch.recommendedScene
    };
    events.emit("quest_navigation_requested", {
      questId: branchQuest.id,
      targetSurface: branchQuest.targetSurface,
      recommendedScene: branch.recommendedScene
    });
    if (onNavigate) {
      onNavigate(branchQuest);
    } else if (router && branch.recommendedScene) {
      router.goTo(branch.recommendedScene);
    }
    setOpen(false);
  }

  return (
    <aside
      className={`quest-task-bar quest-task-bar--${variant} ${open ? "is-open" : ""} ${updated ? "has-objective-update" : ""} ${progressUpdated ? "has-progress-update" : ""} ${showDigitHint ? "has-digits" : ""}`.trim()}
      role="region"
      aria-label="当前任务"
      data-quest-id={quest.id}
      data-layout-zone={variant === "phone" ? "phone-quest" : undefined}
    >
      <button
        type="button"
        className="quest-task-trigger"
        aria-label={`${CHAPTER_LABEL[quest.chapter]}当前任务：${parallelObjective}${chapterFourAria}${showDigitHint ? `。${digitHintAria}` : ""}。点击查看任务提示`}
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
          {showDigitHint ? <em className="quest-task-digit-hint" aria-hidden="true">签到码 {digitHintText}</em> : null}
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
                <small>{CHAPTER_LABEL[quest.chapter]} · {chapterFourPresentation?.stageLabel ?? quest.title}</small>
                <h2>任务栏</h2>
              </div>
              <button type="button" aria-label="关闭任务详情" onClick={() => setOpen(false)}>×</button>
            </header>

            <section className="quest-task-objective">
              <span>当前任务</span>
              <strong>{parallelObjective}</strong>
            </section>

            {quest.parallelBranches && parallelProgress ? (
              <InvestigationRing
                compact
                ariaLabel={`并行调查 ${parallelProgress.completed}/${parallelProgress.total}`}
                eyebrow="PARALLEL"
                title="并行调查环"
                completed={parallelProgress.completed}
                total={parallelProgress.total}
                centerLabel="调查分支"
                hint={parallelBranchesAreRpgStatusNodes
                  ? "环上节点没有提交先后；选择节点后返回现场，就近调查"
                  : "环上节点没有提交先后；方向键切换节点，回车或空格打开"}
                nodes={quest.parallelBranches.map((branch) => ({
                  id: branch.id,
                  label: branch.label,
                  detail: branch.detail ?? (
                    branch.status === "completed"
                      ? "可重新查看"
                      : branch.recommendedScene
                        ? "可直接开始"
                        : "就近调查"
                  ),
                  statusLabel: branch.status === "completed" ? "已完成" : "待处理",
                  state: branch.status === "completed" ? "complete" : "ready"
                }))}
                onActivate={(branchId) => {
                  const branch = quest.parallelBranches?.find((candidate) => candidate.id === branchId);
                  if (branch) navigateToParallelBranch(branch);
                }}
              />
            ) : null}

            {chapterFourPresentation ? (
              <>
                <section className="quest-task-overview is-chapter-four" aria-label="第四章当前阶段概览">
                  <section>
                    <span>当前阶段</span>
                    <strong>{chapterFourPresentation.stageLabel}</strong>
                  </section>
                  <section>
                    <span>时间状态</span>
                    <strong>{chapterFourPresentation.timeStateLabel}</strong>
                  </section>
                  <section>
                    <span>所在楼层</span>
                    <strong>{chapterFourPresentation.floor}</strong>
                  </section>
                  <section>
                    <span>当前进度</span>
                    <strong>{chapterFourPresentation.localProgress}</strong>
                  </section>
                </section>

                <section className="quest-chapter-four-context" aria-label="第四章阶段差分">
                  <div className="quest-chapter-four-difference">
                    <span>当前差分</span>
                    <p>{chapterFourPresentation.currentDifference}</p>
                  </div>
                  <dl>
                    <div>
                      <dt>时间来源</dt>
                      <dd>{chapterFourPresentation.timeSource}</dd>
                    </div>
                    <div>
                      <dt>手机状态</dt>
                      <dd>{chapterFourPresentation.phoneTime} · {chapterFourPresentation.trustState}</dd>
                    </div>
                  </dl>
                  <div className="quest-chapter-four-facts">
                    <strong>已确认事实</strong>
                    {chapterFourPresentation.confirmedFacts.length > 0 ? (
                      <ul>
                        {chapterFourPresentation.confirmedFacts.map((fact) => <li key={fact}>{fact}</li>)}
                      </ul>
                    ) : <p>当前阶段尚无已确认事实。</p>}
                  </div>
                </section>
              </>
            ) : null}

            {showDigitHint && !quest.parallelBranches ? (
              <section className="quest-task-digits" aria-label={digitHintAria}>
                <header>
                  <span>签到数字</span>
                  <strong>{acquiredDigitCount}/4</strong>
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

            {showNavigation ? (
              <button type="button" className="quest-task-navigate" onClick={navigateToQuest}>
                {navigationLabel}
              </button>
            ) : null}
          </section>
        </QuestDrawerLayer>
      ) : null}
    </aside>
  );
}

/** 兼容旧组件名；所有调用共享同一个交互式任务栏实现。 */
export const QuestClueStrip = QuestTaskBar;
