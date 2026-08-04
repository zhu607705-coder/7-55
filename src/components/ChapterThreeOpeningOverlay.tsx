import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
  type CSSProperties
} from "react";
import libraryMapUrl from "../assets/rpg/interiors/library_interior.png";
import type { EventBus } from "../core/EventBus";
import {
  LIBRARY_STORY_SEQUENCES,
  libraryStoryLineKey,
  type LibraryStoryLine
} from "../data/libraryFinalsStory";
import { PRESENTATION_CUE_EVENT } from "../modules/PresentationDirector";
import {
  clearChapterThreeOpeningRuntimeSnapshot,
  setChapterThreeOpeningRuntimeSnapshot,
  type ChapterThreeOpeningPhase,
  type ChapterThreeOpeningRuntimeSnapshot
} from "./ChapterThreeOpeningRuntime";

interface ChapterThreeOpeningOverlayProps {
  events: EventBus;
  onFinished: () => void;
}

interface CutsceneBeat {
  phase: ChapterThreeOpeningPhase;
  durationMs: number;
  lineIndex: number | null;
  caption?: string;
}

interface OpeningRuntimeState {
  beatIndex: number;
  beatElapsedMs: number;
  paused: boolean;
  skipped: boolean;
  completionRequested: boolean;
}

const MAX_SIMULATION_STEP_MS = 34;
const MAX_ADVANCE_MS = 60_000;
const TRANSITION_CAPTIONS = {
  record_scan: "短暂加载后：",
  mode_unlock: "获得功能：外观模式切换",
  paper_burst: "纸条突然从 022 座位详情页弹出，贴着图书馆窗缝飞走。",
  exit_observation: "切到深色模式，看到纸条脚印通向出口。",
  cart_clear: "切回浅色模式，发现出口被书车挡住。",
  route_confirm: "再次切到深色模式，确认脚印通向食堂。",
  route: "当前任务：追上逃跑的记录纸条",
  arrival: "离开图书馆，在校园里继续追踪纸条。"
} as const;

function lineDuration(line: LibraryStoryLine): number {
  return Math.min(1900, Math.max(1200, 760 + line.text.length * 48));
}

function createOpeningBeats(
  lines: readonly LibraryStoryLine[],
  reducedMotion: boolean
): CutsceneBeat[] {
  const motionDuration = (durationMs: number, reducedDurationMs: number) =>
    reducedMotion ? reducedDurationMs : durationMs;
  const beats: CutsceneBeat[] = [];
  lines.slice(0, 8).forEach((line, lineIndex) => {
    beats.push({ phase: "conversation", durationMs: lineDuration(line), lineIndex });
  });
  beats.push({
    phase: "record_scan",
    durationMs: motionDuration(1350, 850),
    lineIndex: null,
    caption: TRANSITION_CAPTIONS.record_scan
  });
  lines.slice(8, 18).forEach((line, offset) => {
    beats.push({
      phase: "record_escape",
      durationMs: lineDuration(line),
      lineIndex: 8 + offset
    });
  });
  beats.push({
    phase: "mode_unlock",
    durationMs: motionDuration(1700, 1050),
    lineIndex: null,
    caption: TRANSITION_CAPTIONS.mode_unlock
  });
  lines.slice(18, 22).forEach((line, offset) => {
    beats.push({
      phase: "mode_explanation",
      durationMs: lineDuration(line),
      lineIndex: 18 + offset
    });
  });
  beats.push({
    phase: "paper_burst",
    durationMs: motionDuration(1000, 850),
    lineIndex: null,
    caption: TRANSITION_CAPTIONS.paper_burst
  });
  lines.slice(22, 26).forEach((line, offset) => {
    beats.push({
      phase: "paper_dialogue",
      durationMs: lineDuration(line),
      lineIndex: 22 + offset
    });
  });
  beats.push({
    phase: "exit_observation",
    durationMs: motionDuration(900, 850),
    lineIndex: null,
    caption: TRANSITION_CAPTIONS.exit_observation
  });
  beats.push({
    phase: "cart_clear",
    durationMs: motionDuration(900, 850),
    lineIndex: null,
    caption: TRANSITION_CAPTIONS.cart_clear
  });
  beats.push({
    phase: "route_confirm",
    durationMs: motionDuration(600, 500),
    lineIndex: null,
    caption: TRANSITION_CAPTIONS.route_confirm
  });
  beats.push({
    phase: "arrival",
    durationMs: motionDuration(1300, 900),
    lineIndex: null,
    caption: TRANSITION_CAPTIONS.arrival
  });
  return beats;
}

function clamp(value: number, minimum: number, maximum: number): number {
  return Math.min(maximum, Math.max(minimum, value));
}

function speakerTone(speaker: string): "seat" | "player" | "system" | "paper" {
  if (speaker === "玩家") return "player";
  if (speaker === "系统") return "system";
  if (speaker === "纸条") return "paper";
  return "seat";
}

function toRuntimeSnapshot(
  runtime: OpeningRuntimeState,
  beats: readonly CutsceneBeat[]
): ChapterThreeOpeningRuntimeSnapshot {
  const beat = beats[Math.min(runtime.beatIndex, beats.length - 1)];
  const beatProgress = beat
    ? clamp(runtime.beatElapsedMs / Math.max(1, beat.durationMs), 0, 1)
    : 1;
  return {
    coordinateSystem: "960x540 cutscene coordinates, origin at top-left, x right, y down",
    phase: beat?.phase ?? "arrival",
    beatIndex: Math.min(runtime.beatIndex, beats.length - 1),
    beatCount: beats.length,
    beatProgress,
    overallProgress: clamp((runtime.beatIndex + beatProgress) / beats.length, 0, 1),
    lineIndex: beat?.lineIndex ?? null,
    paused: runtime.paused,
    skipped: runtime.skipped,
    completionRequested: runtime.completionRequested
  };
}

export function ChapterThreeOpeningOverlay({
  events,
  onFinished
}: ChapterThreeOpeningOverlayProps) {
  const lines = LIBRARY_STORY_SEQUENCES.library_friend_contacted ?? [];
  const reducedMotion = typeof window !== "undefined"
    && window.matchMedia?.("(prefers-reduced-motion: reduce)").matches === true;
  const beats = useMemo(
    () => createOpeningBeats(lines, reducedMotion),
    [lines, reducedMotion]
  );
  const runtimeRef = useRef<OpeningRuntimeState>({
    beatIndex: 0,
    beatElapsedMs: 0,
    paused: false,
    skipped: false,
    completionRequested: false
  });
  const [view, setView] = useState(() => toRuntimeSnapshot(runtimeRef.current, beats));
  const stageRef = useRef<HTMLElement>(null);
  const advanceButtonRef = useRef<HTMLButtonElement>(null);
  const skipButtonRef = useRef<HTMLButtonElement>(null);
  const previousBeatRef = useRef(-1);

  const publishRuntime = useCallback(() => {
    const snapshot = toRuntimeSnapshot(runtimeRef.current, beats);
    setView(snapshot);
    setChapterThreeOpeningRuntimeSnapshot(snapshot);
  }, [beats]);

  const requestCompletion = useCallback(() => {
    const runtime = runtimeRef.current;
    if (runtime.completionRequested) return;
    runtime.completionRequested = true;
    publishRuntime();
    queueMicrotask(onFinished);
  }, [onFinished, publishRuntime]);

  const advanceSimulation = useCallback((requestedMs: number) => {
    let remainingMs = clamp(Number.isFinite(requestedMs) ? requestedMs : 0, 0, MAX_ADVANCE_MS);
    const runtime = runtimeRef.current;
    while (remainingMs > 0 && !runtime.paused && !runtime.completionRequested) {
      const beat = beats[runtime.beatIndex];
      if (!beat) {
        requestCompletion();
        break;
      }
      const deltaMs = Math.min(
        remainingMs,
        MAX_SIMULATION_STEP_MS,
        Math.max(0, beat.durationMs - runtime.beatElapsedMs)
      );
      remainingMs -= deltaMs;
      runtime.beatElapsedMs += deltaMs;
      if (runtime.beatElapsedMs + 0.01 < beat.durationMs) continue;
      runtime.beatIndex += 1;
      runtime.beatElapsedMs = 0;
      if (runtime.beatIndex >= beats.length) {
        requestCompletion();
        break;
      }
    }
    publishRuntime();
  }, [beats, publishRuntime, requestCompletion]);

  const advanceCurrentBeat = useCallback(() => {
    const runtime = runtimeRef.current;
    const beat = beats[runtime.beatIndex];
    if (!beat || runtime.completionRequested) return;
    runtime.beatElapsedMs = beat.durationMs;
    advanceSimulation(1);
  }, [advanceSimulation, beats]);

  const skipToArrival = useCallback(() => {
    const runtime = runtimeRef.current;
    if (runtime.completionRequested) return;
    runtime.skipped = true;
    runtime.beatIndex = Math.max(0, beats.length - 1);
    runtime.beatElapsedMs = 0;
    publishRuntime();
    queueMicrotask(() => advanceButtonRef.current?.focus());
  }, [beats.length, publishRuntime]);

  useEffect(() => {
    events.emit("chapter_three_opening_started");
    setChapterThreeOpeningRuntimeSnapshot(toRuntimeSnapshot(runtimeRef.current, beats));
    advanceButtonRef.current?.focus();
    return () => clearChapterThreeOpeningRuntimeSnapshot();
  }, [beats, events]);

  useEffect(() => {
    if (previousBeatRef.current === view.beatIndex) return;
    previousBeatRef.current = view.beatIndex;
    const beat = beats[view.beatIndex];
    if (!beat) return;
    if (beat.lineIndex !== null) {
      events.emit(PRESENTATION_CUE_EVENT, {
        cueId: "library_story_line",
        subtitleKey: libraryStoryLineKey("library_friend_contacted", beat.lineIndex)
      });
      return;
    }
    events.emit(`chapter_three_opening_${beat.phase}`, {
      beatIndex: view.beatIndex,
      beatCount: beats.length
    });
  }, [beats, events, view.beatIndex]);

  useEffect(() => {
    const previousAdvanceTime = window.advanceTime;
    const controlledByClient = window.__vt_pending instanceof Set;
    let frame = 0;
    let lastTime = performance.now();
    const advanceForTests = async (milliseconds: number) => {
      advanceSimulation(milliseconds);
      await Promise.resolve();
    };
    window.advanceTime = advanceForTests;
    if (!controlledByClient) {
      const loop = (now: number) => {
        advanceSimulation(Math.min(100, now - lastTime));
        lastTime = now;
        frame = window.requestAnimationFrame(loop);
      };
      frame = window.requestAnimationFrame(loop);
    }
    return () => {
      if (frame) window.cancelAnimationFrame(frame);
      if (window.advanceTime === advanceForTests) {
        if (previousAdvanceTime) window.advanceTime = previousAdvanceTime;
        else delete window.advanceTime;
      }
    };
  }, [advanceSimulation]);

  useEffect(() => {
    const onVisibilityChange = () => {
      runtimeRef.current.paused = document.hidden;
      publishRuntime();
    };
    document.addEventListener("visibilitychange", onVisibilityChange);
    return () => document.removeEventListener("visibilitychange", onVisibilityChange);
  }, [publishRuntime]);

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Tab") {
        event.preventDefault();
        event.stopPropagation();
        event.stopImmediatePropagation();
        const skipButton = skipButtonRef.current;
        const advanceButton = advanceButtonRef.current;
        if (!advanceButton) return;
        if (!skipButton || skipButton.disabled) {
          advanceButton.focus();
          return;
        }
        const activeElement = document.activeElement;
        if (event.shiftKey) {
          (activeElement === advanceButton ? skipButton : advanceButton).focus();
          return;
        }
        (activeElement === skipButton ? advanceButton : skipButton).focus();
        return;
      }
      if (event.key !== "Enter" && event.key !== " ") return;
      if (event.target instanceof HTMLButtonElement) {
        event.preventDefault();
        event.stopPropagation();
        event.stopImmediatePropagation();
        event.target.click();
        return;
      }
      event.preventDefault();
      event.stopPropagation();
      event.stopImmediatePropagation();
      advanceCurrentBeat();
    };
    window.addEventListener("keydown", onKeyDown, true);
    return () => window.removeEventListener("keydown", onKeyDown, true);
  }, [advanceCurrentBeat]);

  const beat = beats[view.beatIndex] ?? beats[beats.length - 1];
  const line = beat?.lineIndex === null || beat?.lineIndex === undefined
    ? null
    : lines[beat.lineIndex];
  const progressStyle = {
    "--chapter-three-opening-progress": `${Math.round(view.overallProgress * 10000) / 100}%`
  } as CSSProperties;
  return (
    <section
      ref={stageRef}
      className={`chapter-three-opening phase-${view.phase}${view.paused ? " is-paused" : ""}`}
      data-phase={view.phase}
      data-beat-index={view.beatIndex}
      role="dialog"
      aria-modal="true"
      aria-label="第二章到第三章转场演出"
      tabIndex={-1}
      style={progressStyle}
    >
      <div className="chapter-three-opening__letterbox">
        <div className="chapter-three-opening__stage">
          <img
            className="chapter-three-opening__backdrop is-library"
            src={libraryMapUrl}
            alt=""
            aria-hidden="true"
          />
          <div className="chapter-three-opening__grade" aria-hidden="true" />
          <div className="chapter-three-opening__scanlines" aria-hidden="true" />

          <header className="chapter-three-opening__chapter-card" aria-hidden="true">
            <small>CHAPTER 03</small>
            <strong>07:55 的残影</strong>
          </header>

          <div className="chapter-three-opening__seat" aria-hidden="true">
            <span>022</span>
            <i />
            <b>RECORD QUERY</b>
            <em>07:55</em>
          </div>

          <div className="chapter-three-opening__mode-card" aria-hidden="true">
            <small>外观模式切换</small>
            <div><span>浅色模式</span><i /><span>深色模式</span></div>
            <p>当前校园 / 07:55 的校园残影</p>
          </div>

          <div className="chapter-three-opening__paper" aria-hidden="true">
            <i /><i />
            <span>本人马上回来</span>
          </div>

          <div className="chapter-three-opening__exit-sequence" aria-hidden="true">
            <div className="chapter-three-opening__exit-footprints">
              <i /><i /><i /><i /><i /><i />
            </div>
            <div className="chapter-three-opening__exit-words">
              <span>食堂</span><span>热气</span><span>退款</span>
            </div>
            <div className="chapter-three-opening__book-cart">
              <i /><i />
              <span /><span /><span />
            </div>
          </div>

          <div className="chapter-three-opening__scraps" aria-hidden="true">
            <i /><i /><i /><i /><i /><i />
          </div>

          <div className="chapter-three-opening__arrival" aria-hidden="true">
            <small>MISSION</small>
            <strong>追到东区大食堂</strong>
          </div>

          <div className={`chapter-three-opening__subtitle tone-${line ? speakerTone(line.speaker) : "system"}`}>
            <div className="chapter-three-opening__subtitle-meta">
              <span>{line?.speaker ?? (view.phase === "arrival" ? "地点" : "剧情")}</span>
              <small>{view.beatIndex + 1}/{beats.length}</small>
            </div>
            <p aria-live="polite">{line?.text ?? beat?.caption ?? ""}</p>
            <button ref={advanceButtonRef} type="button" onClick={advanceCurrentBeat}>
              {line ? "快进此句" : view.phase === "arrival" ? "回到校园" : "继续演出"}
            </button>
          </div>

          <button
            ref={skipButtonRef}
            className="chapter-three-opening__skip"
            type="button"
            onClick={skipToArrival}
            disabled={view.phase === "arrival"}
          >
            跳过演出
          </button>

          <div className="chapter-three-opening__progress" aria-hidden="true"><i /></div>
          {view.paused ? <div className="chapter-three-opening__paused" role="status">演出已暂停</div> : null}
        </div>
      </div>
    </section>
  );
}
