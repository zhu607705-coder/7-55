import { useCallback, useEffect, useRef, useState, type CSSProperties } from "react";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import actOneContent from "../../../data/act-one-bootstrap.content.json";
import { kit } from "../../../modules/GameKit";
import {
  clearEndingRuntimeSnapshot,
  setEndingRuntimeSnapshot,
  type EndingRuntimePhase,
  type EndingRuntimeSnapshot
} from "./EndingRuntime";

const BLACKOUT_MS = 7000;
const ERROR_DEPLOY_MS = 1500;
const ATTEMPT_DURATION_MS = [2700, 2500, 2300] as const;
const IMPACT_PAUSE_MS = 350;
const MISS_PAUSE_MS = 650;
const HOLD_TO_CATCH_MS = 1400;
const REQUIRED_BLOCKS = 3;
const MAX_MISSES = 3;
const PADDLE_WIDTH_PERCENT = 38;
const PADDLE_MIN_X = PADDLE_WIDTH_PERCENT / 2 + 2;
const PADDLE_MAX_X = 100 - PADDLE_MIN_X;
const KEYBOARD_SPEED_PERCENT_PER_SECOND = 54;

type EndingFeedback = "blocked" | "missed" | "round_failed" | null;

interface EndingViewState {
  phase: EndingRuntimePhase;
  phaseElapsedMs: number;
  introElapsedMs: number;
  blockedCount: number;
  misses: number;
  paddleX: number;
  orbX: number;
  orbY: number;
  orbRotation: number;
  lockHeldMs: number;
  lockActive: boolean;
  dialogueStep: number;
  feedback: EndingFeedback;
  paused: boolean;
  completionRequested: boolean;
}

const DIALOGUE = [
  { speaker: "narrator", text: actOneContent.audioNarration.prologue_narrator_caught.subtitleZh },
  { speaker: "player", text: "不，除非你帮助我" },
  { speaker: "player", text: "不然你就和我的绩点同归于尽吧" },
  { speaker: "narrator", text: actOneContent.audioNarration.prologue_narrator_bargain.subtitleZh }
] as const;

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

function createEndingViewState(): EndingViewState {
  return {
    phase: "blackout",
    phaseElapsedMs: 0,
    introElapsedMs: 0,
    blockedCount: 0,
    misses: 0,
    paddleX: 50,
    orbX: 82,
    orbY: 12,
    orbRotation: -8,
    lockHeldMs: 0,
    lockActive: false,
    dialogueStep: 0,
    feedback: null,
    paused: false,
    completionRequested: false
  };
}

function narratorPath(round: number, progress: number): { x: number; y: number; rotation: number } {
  const p = clamp(progress, 0, 1);
  if (round === 0) {
    return {
      x: 82 - 58 * p + Math.sin(p * Math.PI) * 5,
      y: 12 + 69 * p,
      rotation: -12 + 24 * p
    };
  }
  if (round === 1) {
    return {
      x: 16 + 60 * p - Math.sin(p * Math.PI) * 6,
      y: 12 + 69 * p,
      rotation: 14 - 28 * p
    };
  }
  return {
    x: 50 + 29 * Math.sin(p * Math.PI * 2),
    y: 12 + 69 * p,
    rotation: -10 + 360 * p
  };
}

function toRuntimeSnapshot(state: EndingViewState): EndingRuntimeSnapshot {
  const orbVisible = !["blackout", "failed", "burst", "whiteout"].includes(state.phase);
  return {
    coordinateSystem: "430x820 scene coordinates, origin at top-left, x right, y down",
    phase: state.phase,
    blockedCount: state.blockedCount,
    requiredBlocks: 3,
    misses: state.misses,
    maxMisses: 3,
    attempt: Math.min(REQUIRED_BLOCKS, state.blockedCount + 1),
    paddle: { xPercent: state.paddleX, widthPercent: PADDLE_WIDTH_PERCENT },
    narratorOrb: orbVisible ? { xPercent: state.orbX, yPercent: state.orbY } : null,
    lockProgress: clamp(state.lockHeldMs / HOLD_TO_CATCH_MS, 0, 1),
    lockRequiredMs: 1400,
    paused: state.paused,
    feedback: state.feedback
  };
}

/**
 * P12 序章结算：7 秒黑屏后用经纬度错误框挡住三次离场路径，再按住旁白圆圈完成锁定。
 */
export function EndingScene({ state, events }: SceneComponentProps) {
  const runtimeRef = useRef<EndingViewState>(createEndingViewState());
  const [view, setView] = useState<EndingViewState>(() => ({ ...runtimeRef.current }));
  const fieldRef = useRef<HTMLDivElement>(null);
  const paddleRef = useRef<HTMLButtonElement>(null);
  const lockButtonRef = useRef<HTMLButtonElement>(null);
  const retryButtonRef = useRef<HTMLButtonElement>(null);
  const dragPointerRef = useRef<number | null>(null);
  const heldDirectionsRef = useRef({ left: false, right: false });

  const publishRuntime = useCallback(() => {
    const next = { ...runtimeRef.current };
    setView(next);
    setEndingRuntimeSnapshot(toRuntimeSnapshot(next));
  }, []);

  const advanceSimulation = useCallback((requestedMs: number) => {
    let remainingMs = clamp(Number.isFinite(requestedMs) ? requestedMs : 0, 0, 10000);
    while (remainingMs > 0) {
      const deltaMs = Math.min(remainingMs, 34);
      remainingMs -= deltaMs;
      const runtime = runtimeRef.current;
      if (runtime.paused || runtime.phase === "failed") {
        continue;
      }

      if (["deploy", "intercept", "impact", "miss", "lock"].includes(runtime.phase)) {
        runtime.introElapsedMs += deltaMs;
      }

      if (["deploy", "intercept", "impact", "miss"].includes(runtime.phase)) {
        const direction = Number(heldDirectionsRef.current.right) - Number(heldDirectionsRef.current.left);
        runtime.paddleX = clamp(
          runtime.paddleX + direction * KEYBOARD_SPEED_PERCENT_PER_SECOND * deltaMs / 1000,
          PADDLE_MIN_X,
          PADDLE_MAX_X
        );
      }

      runtime.phaseElapsedMs += deltaMs;

      if (runtime.phase === "blackout" && runtime.phaseElapsedMs >= BLACKOUT_MS) {
        runtime.phase = "deploy";
        runtime.phaseElapsedMs = 0;
        runtime.introElapsedMs = 0;
        runtime.feedback = null;
        events.emit("prologue_narrator_intro");
        queueMicrotask(() => paddleRef.current?.focus());
        continue;
      }

      if (runtime.phase === "deploy" && runtime.phaseElapsedMs >= ERROR_DEPLOY_MS) {
        runtime.phase = "intercept";
        runtime.phaseElapsedMs = 0;
        const path = narratorPath(runtime.blockedCount, 0);
        runtime.orbX = path.x;
        runtime.orbY = path.y;
        runtime.orbRotation = path.rotation;
        continue;
      }

      if (runtime.phase === "intercept") {
        const round = Math.min(runtime.blockedCount, REQUIRED_BLOCKS - 1);
        const durationMs = ATTEMPT_DURATION_MS[round];
        const progress = clamp(runtime.phaseElapsedMs / durationMs, 0, 1);
        const path = narratorPath(round, progress);
        runtime.orbX = path.x;
        runtime.orbY = path.y;
        runtime.orbRotation = path.rotation;
        if (progress >= 1) {
          const hitRange = PADDLE_WIDTH_PERCENT / 2;
          if (Math.abs(runtime.paddleX - runtime.orbX) <= hitRange) {
            runtime.blockedCount += 1;
            runtime.phase = "impact";
            runtime.phaseElapsedMs = 0;
            runtime.feedback = "blocked";
            events.emit("prologue_error_intercepted", {
              blockedCount: runtime.blockedCount,
              requiredBlocks: REQUIRED_BLOCKS
            });
          } else {
            runtime.misses += 1;
            runtime.phase = "miss";
            runtime.phaseElapsedMs = 0;
            runtime.orbY = 92;
            runtime.feedback = "missed";
            events.emit("prologue_error_intercept_missed", {
              misses: runtime.misses,
              maxMisses: MAX_MISSES
            });
          }
        }
        continue;
      }

      if (runtime.phase === "impact" && runtime.phaseElapsedMs >= IMPACT_PAUSE_MS) {
        runtime.phaseElapsedMs = 0;
        runtime.feedback = null;
        if (runtime.blockedCount >= REQUIRED_BLOCKS) {
          runtime.phase = "lock";
          runtime.orbX = 50;
          runtime.orbY = 42;
          runtime.orbRotation = 0;
          events.emit("prologue_error_lock_ready", { requiredHoldMs: HOLD_TO_CATCH_MS });
          queueMicrotask(() => lockButtonRef.current?.focus());
        } else {
          runtime.phase = "intercept";
          const path = narratorPath(runtime.blockedCount, 0);
          runtime.orbX = path.x;
          runtime.orbY = path.y;
          runtime.orbRotation = path.rotation;
        }
        continue;
      }

      if (runtime.phase === "miss" && runtime.phaseElapsedMs >= MISS_PAUSE_MS) {
        runtime.phaseElapsedMs = 0;
        if (runtime.misses >= MAX_MISSES) {
          runtime.phase = "failed";
          runtime.feedback = "round_failed";
          events.emit("prologue_error_round_failed", { misses: runtime.misses });
          queueMicrotask(() => retryButtonRef.current?.focus());
        } else {
          runtime.phase = "intercept";
          runtime.feedback = null;
          const path = narratorPath(runtime.blockedCount, 0);
          runtime.orbX = path.x;
          runtime.orbY = path.y;
          runtime.orbRotation = path.rotation;
        }
        continue;
      }

      if (runtime.phase === "lock" && runtime.lockActive) {
        runtime.lockHeldMs = Math.min(HOLD_TO_CATCH_MS, runtime.lockHeldMs + deltaMs);
        if (runtime.lockHeldMs >= HOLD_TO_CATCH_MS) {
          runtime.lockActive = false;
          runtime.phase = "caught";
          runtime.phaseElapsedMs = 0;
          runtime.dialogueStep = 0;
          runtime.feedback = "blocked";
          events.emit("prologue_narrator_caught", {
            blockedCount: runtime.blockedCount,
            lockHeldMs: runtime.lockHeldMs
          });
        }
        continue;
      }

      if (runtime.phase === "caught") {
        const nextDialogueStep = runtime.phaseElapsedMs >= 5200
          ? 3
          : runtime.phaseElapsedMs >= 4100
            ? 2
            : runtime.phaseElapsedMs >= 3000
              ? 1
              : 0;
        if (nextDialogueStep !== runtime.dialogueStep) {
          runtime.dialogueStep = nextDialogueStep;
          if (nextDialogueStep === 3) {
            events.emit("prologue_narrator_bargain");
          }
        }
        if (runtime.phaseElapsedMs >= 8900) {
          runtime.phase = "burst";
          runtime.phaseElapsedMs = 0;
          events.emit("prologue_white_burst");
        }
        continue;
      }

      if (runtime.phase === "burst" && runtime.phaseElapsedMs >= 950) {
        runtime.phase = "whiteout";
        runtime.phaseElapsedMs = 0;
        continue;
      }

      if (runtime.phase === "whiteout" && runtime.phaseElapsedMs >= 700 && !runtime.completionRequested) {
        runtime.completionRequested = true;
        kit.actOne.completeNarratorIntervention({
          interceptedCount: runtime.blockedCount,
          lockHeldMs: runtime.lockHeldMs,
          failed: false
        });
      }
    }
    publishRuntime();
  }, [events, publishRuntime]);

  useEffect(() => {
    events.emit("ending_started");
    events.emit("prologue_blackout_started", { durationMs: BLACKOUT_MS });
    setEndingRuntimeSnapshot(toRuntimeSnapshot(runtimeRef.current));
    return () => clearEndingRuntimeSnapshot();
  }, [events]);

  useEffect(() => {
    const previousAdvanceTime = window.advanceTime;
    const controlledByClient = window.__vt_pending instanceof Set;
    let frame = 0;
    let lastTime = performance.now();

    const advanceForTests = async (ms: number) => {
      advanceSimulation(ms);
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
      heldDirectionsRef.current.left = false;
      heldDirectionsRef.current.right = false;
      if (document.hidden && runtimeRef.current.phase === "lock") {
        runtimeRef.current.lockActive = false;
        runtimeRef.current.lockHeldMs = 0;
      }
      publishRuntime();
    };
    document.addEventListener("visibilitychange", onVisibilityChange);
    return () => document.removeEventListener("visibilitychange", onVisibilityChange);
  }, [publishRuntime]);

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (setHeldDirection(event.key, true)) {
        event.preventDefault();
        return;
      }
      if ((event.key === " " || event.key === "Enter") && !event.repeat && runtimeRef.current.phase === "lock") {
        event.preventDefault();
        beginLock();
      }
    };
    const onKeyUp = (event: KeyboardEvent) => {
      if (setHeldDirection(event.key, false)) {
        event.preventDefault();
        return;
      }
      if ((event.key === " " || event.key === "Enter") && runtimeRef.current.phase === "lock") {
        event.preventDefault();
        cancelLock();
      }
    };
    const onWindowBlur = () => {
      heldDirectionsRef.current.left = false;
      heldDirectionsRef.current.right = false;
      cancelLock();
    };
    window.addEventListener("keydown", onKeyDown);
    window.addEventListener("keyup", onKeyUp);
    window.addEventListener("blur", onWindowBlur);
    return () => {
      window.removeEventListener("keydown", onKeyDown);
      window.removeEventListener("keyup", onKeyUp);
      window.removeEventListener("blur", onWindowBlur);
    };
  });

  function updatePaddleFromClientX(clientX: number) {
    const rect = fieldRef.current?.getBoundingClientRect();
    if (!rect?.width) return;
    runtimeRef.current.paddleX = clamp(
      (clientX - rect.left) / rect.width * 100,
      PADDLE_MIN_X,
      PADDLE_MAX_X
    );
    publishRuntime();
  }

  function beginPaddleDrag(event: React.PointerEvent<HTMLButtonElement>) {
    if (!["deploy", "intercept", "impact", "miss"].includes(runtimeRef.current.phase)) return;
    dragPointerRef.current = event.pointerId;
    try {
      event.currentTarget.setPointerCapture?.(event.pointerId);
    } catch {
      // Older engines and synthetic pointers may not provide pointer capture.
    }
    updatePaddleFromClientX(event.clientX);
  }

  function movePaddle(event: React.PointerEvent<HTMLButtonElement>) {
    if (dragPointerRef.current !== event.pointerId) return;
    event.preventDefault();
    updatePaddleFromClientX(event.clientX);
  }

  function endPaddleDrag(event: React.PointerEvent<HTMLButtonElement>) {
    if (dragPointerRef.current !== event.pointerId) return;
    dragPointerRef.current = null;
    try {
      event.currentTarget.releasePointerCapture?.(event.pointerId);
    } catch {
      // The pointer may already have been released by the browser.
    }
  }

  function setHeldDirection(key: string, held: boolean) {
    if (key === "ArrowLeft" || key.toLowerCase() === "a") {
      heldDirectionsRef.current.left = held;
      return true;
    }
    if (key === "ArrowRight" || key.toLowerCase() === "d") {
      heldDirectionsRef.current.right = held;
      return true;
    }
    return false;
  }

  function beginLock() {
    const runtime = runtimeRef.current;
    if (runtime.phase !== "lock" || runtime.lockActive) return;
    runtime.lockActive = true;
    events.emit("prologue_error_lock_started", { requiredHoldMs: HOLD_TO_CATCH_MS });
    publishRuntime();
  }

  function cancelLock() {
    const runtime = runtimeRef.current;
    if (runtime.phase !== "lock" || !runtime.lockActive) return;
    const heldMs = runtime.lockHeldMs;
    runtime.lockActive = false;
    runtime.lockHeldMs = 0;
    events.emit("prologue_error_lock_cancelled", { heldMs });
    publishRuntime();
  }

  function beginPointerLock(event: React.PointerEvent<HTMLButtonElement>) {
    try {
      event.currentTarget.setPointerCapture?.(event.pointerId);
    } catch {
      // Pointer capture is optional for older browsers.
    }
    beginLock();
  }

  function retryInterception() {
    const next = createEndingViewState();
    next.phase = "deploy";
    next.phaseElapsedMs = 0;
    next.introElapsedMs = 0;
    runtimeRef.current = next;
    heldDirectionsRef.current.left = false;
    heldDirectionsRef.current.right = false;
    events.emit("prologue_narrator_intro");
    publishRuntime();
    queueMicrotask(() => paddleRef.current?.focus());
  }

  const showGame = ["deploy", "intercept", "impact", "miss", "failed", "lock"].includes(view.phase);
  const showPaddle = ["deploy", "intercept", "impact", "miss", "lock"].includes(view.phase);
  const introSegments = actOneContent.audioNarration.prologue_narrator_intro.subtitleSegmentsZh;
  const introSegmentIndex = view.introElapsedMs >= 6800 ? 2 : view.introElapsedMs >= 3400 ? 1 : 0;
  const dialogue = view.phase === "caught" ? DIALOGUE[view.dialogueStep] : null;
  const lockProgress = clamp(view.lockHeldMs / HOLD_TO_CATCH_MS, 0, 1);
  const orbStyle = {
    left: `${view.orbX}%`,
    top: `${view.orbY}%`,
    transform: `translate(-50%, -50%) rotate(${view.orbRotation}deg)`
  } satisfies CSSProperties;
  const paddleStyle = { left: `${view.paddleX}%` } satisfies CSSProperties;
  const lockStyle = { "--lock-progress": `${lockProgress * 360}deg` } as CSSProperties;

  return (
    <section
      className={`ending-scene ending-${view.phase}`}
      aria-label="序章结算"
      data-ending-phase={view.phase}
      data-blocked-count={view.blockedCount}
      data-misses={view.misses}
    >
      {view.phase === "blackout" ? <div className="ending-seven-second-blackout" aria-label="黑屏" /> : null}

      {showGame ? (
        <>
          <header className="ending-intercept-hud">
            <div>
              <small>GEO ERROR // INTERCEPT</small>
              <strong>错误框拦截</strong>
            </div>
            <ol aria-label={`已挡住 ${view.blockedCount} 次，共 ${REQUIRED_BLOCKS} 次`}>
              {Array.from({ length: REQUIRED_BLOCKS }, (_, index) => (
                <li key={index} className={index < view.blockedCount ? "is-complete" : ""}>{index + 1}</li>
              ))}
            </ol>
            <span>失误 {view.misses}/{MAX_MISSES}</span>
          </header>

          <p className="ending-game-subtitle" aria-live="polite">
            <small>旁白</small>
            {introSegments[introSegmentIndex]}
          </p>

          <div ref={fieldRef} className={`ending-intercept-field is-${view.phase}`}>
            <i className="ending-field-grid" aria-hidden="true" />
            <i className="ending-exit-slot" aria-hidden="true"><span>EXIT</span></i>

            {view.phase !== "failed" ? (
              view.phase === "lock" ? (
                <button
                  ref={lockButtonRef}
                  type="button"
                  className={`narrator-orb is-lock-target ${view.lockActive ? "is-held" : ""}`}
                  style={{ ...orbStyle, ...lockStyle }}
                  aria-label={`按住旁白圆圈完成锁定，当前 ${Math.round(lockProgress * 100)}%`}
                  onPointerDown={beginPointerLock}
                  onPointerUp={cancelLock}
                  onPointerCancel={cancelLock}
                  onLostPointerCapture={cancelLock}
                  onKeyDown={(event) => {
                    if ((event.key === " " || event.key === "Enter") && !event.repeat) {
                      event.preventDefault();
                      beginLock();
                    }
                  }}
                  onKeyUp={(event) => {
                    if (event.key === " " || event.key === "Enter") {
                      event.preventDefault();
                      cancelLock();
                    }
                  }}
                >
                  <span aria-hidden="true" />
                  <strong>{Math.round(lockProgress * 100)}%</strong>
                </button>
              ) : (
                <div
                  className={`narrator-orb is-moving ${view.phase === "impact" ? "is-impact" : ""} ${view.phase === "miss" ? "is-missed" : ""}`}
                  style={orbStyle}
                  role="img"
                  aria-label="正在移动的旁白圆圈"
                >
                  <span aria-hidden="true" />
                  <strong>旁白</strong>
                </div>
              )
            ) : null}

            {view.phase === "lock" ? <div className="ending-capture-frame" aria-hidden="true"><i /><i /><i /><i /></div> : null}

            {showPaddle ? (
              <button
                ref={paddleRef}
                type="button"
                className={`ending-geo-error-board ${view.phase === "deploy" ? "is-deploying" : ""} ${view.phase === "impact" ? "is-impact" : ""}`}
                style={paddleStyle}
                aria-label="拖动经纬度错误框挡住下方出口，键盘可用 A D 或左右方向键"
                onPointerDown={beginPaddleDrag}
                onPointerMove={movePaddle}
                onPointerUp={endPaddleDrag}
                onPointerCancel={endPaddleDrag}
                onLostPointerCapture={(event) => {
                  if (dragPointerRef.current === event.pointerId) dragPointerRef.current = null;
                }}
                onKeyDown={(event) => {
                  if (setHeldDirection(event.key, true)) event.preventDefault();
                }}
                onKeyUp={(event) => {
                  if (setHeldDirection(event.key, false)) event.preventDefault();
                }}
                onBlur={() => {
                  heldDirectionsRef.current.left = false;
                  heldDirectionsRef.current.right = false;
                }}
              >
                <span className="ending-error-title"><small>LOCATION ERROR</small><i aria-hidden="true">×</i></span>
                <strong>经度与纬度不存在</strong>
                <span className="ending-error-coordinates">null / null</span>
              </button>
            ) : null}

            {view.feedback === "blocked" && view.phase === "impact" ? (
              <p className="ending-intercept-feedback is-success" role="status">已挡住 {view.blockedCount}/{REQUIRED_BLOCKS}</p>
            ) : null}
            {view.feedback === "missed" ? (
              <p className="ending-intercept-feedback is-failure" role="status">未命中出口位置</p>
            ) : null}

            {view.phase === "failed" ? (
              <section className="ending-intercept-failed" role="dialog" aria-labelledby="ending-retry-title">
                <small>SIGNAL LOST</small>
                <h2 id="ending-retry-title">拦截失败</h2>
                <p>错误框连续三次没有对齐出口。</p>
                <button ref={retryButtonRef} type="button" onClick={retryInterception}>重新部署错误框</button>
              </section>
            ) : null}
          </div>

          <p className="ending-control-hint">
            {view.phase === "lock" ? "按住圆圈 1.4 秒完成锁定" : "拖动错误框 · 键盘 A / D 或 ← / →"}
          </p>
        </>
      ) : null}

      {view.phase === "caught" ? (
        <>
          <div className="ending-capture-frame is-complete" aria-hidden="true"><i /><i /><i /><i /></div>
          <div className="narrator-orb is-caught" role="img" aria-label="已被锁定的旁白圆圈">
            <span aria-hidden="true" />
            <strong>已锁定</strong>
          </div>
          {dialogue ? (
            <p className={`ending-dialogue is-${dialogue.speaker}`} aria-live="polite">
              <small>{dialogue.speaker === "narrator" ? "旁白" : "我"}</small>
              {dialogue.text}
            </p>
          ) : null}
        </>
      ) : null}

      {view.paused && showGame ? <p className="ending-paused" role="status">已暂停</p> : null}
      {view.phase === "burst" ? <div className="ending-white-burst" aria-hidden="true"><i /><i /><i /></div> : null}
      {view.phase === "whiteout" ? <div className="ending-whiteout" aria-label="白屏闪退" /> : null}
    </section>
  );
}
