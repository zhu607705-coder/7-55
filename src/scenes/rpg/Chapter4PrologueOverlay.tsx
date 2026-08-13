import { useCallback, useEffect, useRef, useState } from "react";
import { useMediaQuery } from "../../components/useMediaQuery";
import { GameSubtitleFrame } from "../../components/GameSubtitleFrame";
import type { EventBus } from "../../core/EventBus";
import { PrologueRenderer } from "./chapter4-prologue/PrologueRenderer";
import {
  getProloguePortrait,
  PROLOGUE_DEPARTING_STUDENT_PORTRAIT,
  type ProloguePortraitPair
} from "./chapter4-prologue/ProloguePortraitAssets";
import {
  PROLOGUE_BEATS,
  PROLOGUE_TASK_CARD_AT,
  prologueSubtitleAt,
  type PrologueSubtitle
} from "./chapter4-prologue/PrologueTimeline";

interface Chapter4PrologueOverlayProps {
  events: EventBus;
  onComplete: () => void;
  initialElapsedMs?: number;
}

interface PrologueRuntime {
  elapsedMs: number;
  paused: boolean;
  cardShown: boolean;
}

interface ProloguePortraitState {
  key: "cleaner" | "guard" | "departing_student";
  pair: ProloguePortraitPair;
  frame: 0 | 1;
  sceneCutIn: boolean;
}

function portraitAt(elapsedMs: number, subtitle: PrologueSubtitle | null): ProloguePortraitState | null {
  const frame = (Math.floor(elapsedMs / 680) % 2) as 0 | 1;
  const dialoguePortrait = getProloguePortrait(subtitle);
  if (dialoguePortrait && subtitle?.id === "cleaner") {
    return { key: "cleaner", pair: dialoguePortrait, frame, sceneCutIn: false };
  }
  if (dialoguePortrait && subtitle?.id === "guard") {
    return { key: "guard", pair: dialoguePortrait, frame, sceneCutIn: false };
  }
  if (elapsedMs >= 25200 && elapsedMs < 28600) {
    return {
      key: "departing_student",
      pair: PROLOGUE_DEPARTING_STUDENT_PORTRAIT,
      frame,
      sceneCutIn: true
    };
  }
  return null;
}

function normalizeInitialElapsedMs(value: number | undefined): number {
  const elapsedMs = Number(value) || 0;
  return Math.max(0, Math.min(PROLOGUE_TASK_CARD_AT, elapsedMs));
}

function createInitialRuntime(initialElapsedMs: number): PrologueRuntime {
  return {
    elapsedMs: initialElapsedMs,
    paused: false,
    cardShown: initialElapsedMs >= PROLOGUE_TASK_CARD_AT
  };
}

function createInitialFiredBeats(initialElapsedMs: number): Set<string> {
  return new Set(
    PROLOGUE_BEATS
      .filter((beat) => initialElapsedMs >= PROLOGUE_TASK_CARD_AT
        ? beat.at <= initialElapsedMs
        : beat.at < initialElapsedMs)
      .map((beat) => beat.cueEvent)
  );
}

/**
 * 第四章序幕「纸条进入段永平教学楼」过场。
 * 纯表现层：按共享时间线播放像素演出、发领域事件驱动音频 cue 与中文字幕；
 * 剧情事实只通过 onComplete 交给 ChapterFourPrologueController 写入。
 */
export function Chapter4PrologueOverlay({ events, onComplete, initialElapsedMs }: Chapter4PrologueOverlayProps) {
  const prefersReducedMotion = useMediaQuery("(prefers-reduced-motion: reduce)");
  const initialElapsedRef = useRef(normalizeInitialElapsedMs(initialElapsedMs));
  const runtimeRef = useRef<PrologueRuntime>(createInitialRuntime(initialElapsedRef.current));
  const firedBeatsRef = useRef(createInitialFiredBeats(initialElapsedRef.current));
  const completedRef = useRef(false);
  const eventsRef = useRef(events);
  const onCompleteRef = useRef(onComplete);
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const rendererRef = useRef<PrologueRenderer | null>(null);
  const initialSubtitle = initialElapsedRef.current >= PROLOGUE_TASK_CARD_AT
    ? null
    : prologueSubtitleAt(initialElapsedRef.current);
  const [subtitle, setSubtitle] = useState<PrologueSubtitle | null>(initialSubtitle);
  const [portrait, setPortrait] = useState<ProloguePortraitState | null>(
    portraitAt(initialElapsedRef.current, initialSubtitle)
  );
  const [cardShown, setCardShown] = useState(initialElapsedRef.current >= PROLOGUE_TASK_CARD_AT);
  eventsRef.current = events;
  onCompleteRef.current = onComplete;

  const advance = useCallback((milliseconds: number) => {
    const runtime = runtimeRef.current;
    if (runtime.paused || runtime.cardShown || milliseconds <= 0) return;
    runtime.elapsedMs = Math.min(PROLOGUE_TASK_CARD_AT, runtime.elapsedMs + Math.min(5000, milliseconds));
    for (const beat of PROLOGUE_BEATS) {
      if (runtime.elapsedMs >= beat.at && !firedBeatsRef.current.has(beat.cueEvent)) {
        firedBeatsRef.current.add(beat.cueEvent);
        eventsRef.current.emit(beat.cueEvent);
      }
    }
    if (runtime.elapsedMs >= PROLOGUE_TASK_CARD_AT) {
      runtime.cardShown = true;
      setCardShown(true);
    }
  }, []);

  const restart = useCallback(() => {
    runtimeRef.current = { elapsedMs: 0, paused: false, cardShown: false };
    firedBeatsRef.current = new Set<string>();
    setSubtitle(null);
    setPortrait(null);
    setCardShown(false);
  }, []);

  const skipToCard = useCallback(() => {
    const runtime = runtimeRef.current;
    if (runtime.cardShown) return;
    // 跳过时静默略过剩余节拍，只停掉在播人声与排队音效，再弹出任务卡。
    for (const beat of PROLOGUE_BEATS) {
      if (beat.cueEvent !== "chapter4_prologue_task_card") firedBeatsRef.current.add(beat.cueEvent);
    }
    eventsRef.current.emit("chapter4_prologue_skip");
    runtime.elapsedMs = PROLOGUE_TASK_CARD_AT;
    runtime.cardShown = true;
    firedBeatsRef.current.add("chapter4_prologue_task_card");
    eventsRef.current.emit("chapter4_prologue_task_card");
    setSubtitle(null);
    setPortrait(null);
    setCardShown(true);
  }, []);

  const confirm = useCallback(() => {
    if (completedRef.current) return;
    completedRef.current = true;
    eventsRef.current.emit("chapter4_prologue_finished");
    onCompleteRef.current();
  }, []);

  // 中途卸载（例如切回手机）：取消排队 cue、停止人声与音乐。
  useEffect(() => () => {
    if (!completedRef.current) {
      eventsRef.current.emit("chapter4_prologue_closed");
    }
  }, []);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const renderer = new PrologueRenderer(canvas);
    rendererRef.current = renderer;
    renderer.setReducedMotion(prefersReducedMotion);
    renderer.render(runtimeRef.current.elapsedMs);
    return () => {
      renderer.destroy();
      rendererRef.current = null;
    };
  }, [prefersReducedMotion]);

  useEffect(() => {
    const handleVisibility = () => {
      runtimeRef.current.paused = document.visibilityState === "hidden";
    };
    document.addEventListener("visibilitychange", handleVisibility);
    return () => document.removeEventListener("visibilitychange", handleVisibility);
  }, []);

  useEffect(() => {
    let frame = 0;
    let previous = performance.now();
    let lastSubtitleId: string | null = null;
    let lastPortraitId: string | null = null;
    const tick = (now: number) => {
      const delta = Math.min(48, Math.max(0, now - previous));
      previous = now;
      advance(delta);
      const runtime = runtimeRef.current;
      rendererRef.current?.render(runtime.elapsedMs);
      const active = runtime.cardShown ? null : prologueSubtitleAt(runtime.elapsedMs);
      const activeId = active ? `${active.id}:${active.at}` : null;
      if (activeId !== lastSubtitleId) {
        lastSubtitleId = activeId;
        setSubtitle(active);
      }
      const activePortrait = portraitAt(runtime.elapsedMs, active);
      const portraitId = activePortrait ? `${activePortrait.key}:${activePortrait.frame}` : null;
      if (portraitId !== lastPortraitId) {
        lastPortraitId = portraitId;
        setPortrait(activePortrait);
      }
      frame = window.requestAnimationFrame(tick);
    };
    frame = window.requestAnimationFrame(tick);
    return () => window.cancelAnimationFrame(frame);
  }, [advance]);

  useEffect(() => {
    const previousAdvance = window.advanceTime;
    const advanceTime = (milliseconds: number) => {
      let remaining = Math.max(0, Number(milliseconds) || 0);
      while (remaining > 0) {
        const step = Math.min(1000 / 60, remaining);
        advance(step);
        remaining -= step;
      }
      rendererRef.current?.render(runtimeRef.current.elapsedMs);
      const active = runtimeRef.current.cardShown ? null : prologueSubtitleAt(runtimeRef.current.elapsedMs);
      setSubtitle(active);
      setPortrait(runtimeRef.current.cardShown ? null : portraitAt(runtimeRef.current.elapsedMs, active));
    };
    window.advanceTime = advanceTime;
    return () => {
      if (window.advanceTime !== advanceTime) return;
      if (previousAdvance) window.advanceTime = previousAdvance;
      else delete window.advanceTime;
    };
  }, [advance]);

  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.metaKey || event.ctrlKey || event.altKey) return;
      if (event.key === "Escape" && !runtimeRef.current.cardShown) {
        event.preventDefault();
        skipToCard();
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [skipToCard]);

  return (
    <section
      className="chapter4-prologue-overlay"
      aria-label="第四章序幕：纸条进入段永平教学楼"
      data-card={cardShown ? "shown" : "hidden"}
      data-initial-elapsed-ms={initialElapsedRef.current}
    >
      <canvas
        ref={canvasRef}
        className="chapter4-prologue-canvas"
        role="img"
        aria-label="夜色中，湿纸条从启真湖升到高处，越过拱廊并被追入仍亮着灯的段永平教学楼"
      />

      {!cardShown ? (
        <button type="button" className="chapter4-prologue-skip" onClick={skipToCard}>
          跳过过场
        </button>
      ) : null}

      {subtitle ? (
        <GameSubtitleFrame
          key={`${subtitle.id}:${subtitle.at}`}
          text={subtitle.text}
          tone={subtitle.tone}
          speaker={subtitle.speaker}
          durationMs={subtitle.durationMs}
          className={`chapter4-prologue-subtitle${portrait && !portrait.sceneCutIn ? " has-portrait" : ""}`}
        />
      ) : null}

      {portrait ? (
        <figure
          key={portrait.key}
          className={`chapter4-prologue-portrait is-${portrait.key}${portrait.sceneCutIn ? " is-scene-cut-in" : ""}`}
          aria-hidden="true"
        >
          <img src={portrait.frame === 0 ? portrait.pair.a : portrait.pair.b} alt={portrait.pair.alt} />
        </figure>
      ) : null}

      {cardShown ? (
        <aside className="chapter4-prologue-task-card" role="dialog" aria-modal="true" aria-labelledby="chapter4-prologue-task-title">
          <small>新任务</small>
          <h2 id="chapter4-prologue-task-title">第四章：时间迷宫</h2>
          <dl>
            <div>
              <dt>建筑清楼时间</dt>
              <dd>22:45 → 23:30</dd>
            </div>
            <div>
              <dt>当前目标</dt>
              <dd>追踪进入教学楼的异常签到纸</dd>
            </div>
          </dl>
          <div className="chapter4-prologue-task-actions">
            <button type="button" className="primary" onClick={confirm}>收下任务，进入第四章</button>
            <button type="button" className="secondary" onClick={restart}>重播过场</button>
          </div>
        </aside>
      ) : null}
    </section>
  );
}
