import { useCallback, useEffect, useRef, useState, type CSSProperties } from "react";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import actOneContent from "../../../data/act-one-bootstrap.content.json";
import { kit } from "../../../modules/GameKit";
import { clearEndingRuntimeSnapshot, setEndingRuntimeSnapshot, type EndingRuntimePhase, type EndingRuntimeSnapshot } from "./EndingRuntime";
import { INTERCEPTION_STAGES, WINDOW_BODY, clamp, createInterceptionState, stepInterception, continueInterception,
  toggleClueReview, missingTargets, failureHint, type InterceptionState } from "./InterceptionModel";

const BLACKOUT_MS = 7000;
const ERROR_DEPLOY_MS = 1500;
const HOLD_TO_CATCH_MS = 1400;
const REQUIRED_BLOCKS = 3;
interface EndingViewState {
  phase: EndingRuntimePhase; phaseElapsedMs: number; introElapsedMs: number; blockedCount: number;
  game: InterceptionState; lockHeldMs: number; lockActive: boolean; dialogueStep: number;
  paused: boolean; completionRequested: boolean;
}
const DIALOGUE = [
  { speaker: "narrator", text: actOneContent.audioNarration.prologue_narrator_caught.subtitleZh },
  { speaker: "player", text: "不，除非你帮助我" },
  { speaker: "player", text: "不然你就和我的绩点同归于尽吧" },
  { speaker: "narrator", text: actOneContent.audioNarration.prologue_narrator_bargain.subtitleZh }
] as const;
function createEndingViewState(): EndingViewState {
  return { phase: "blackout", phaseElapsedMs: 0, introElapsedMs: 0, blockedCount: 0,
    game: createInterceptionState(), lockHeldMs: 0, lockActive: false, dialogueStep: 0, paused: false, completionRequested: false };
}
function toRuntimeSnapshot(s: EndingViewState): EndingRuntimeSnapshot {
  return { coordinateSystem: "430x820 scene coordinates, origin at top-left, x right, y down",
    phase: s.phase, blockedCount: s.blockedCount, requiredBlocks: 3, misses: s.game.failures, maxMisses: null,
    attempt: Math.min(3, s.game.stage + 1), paddle: { xPercent: s.game.boardX / 430 * 100, widthPercent: WINDOW_BODY.width / 430 * 100 },
    narratorOrb: s.phase === "lock" ? { xPercent: 50, yPercent: 42 } : null,
    lockProgress: clamp(s.lockHeldMs / HOLD_TO_CATCH_MS, 0, 1), lockRequiredMs: 1400,
    paused: s.paused || ["hint", "review"].includes(s.game.phase),
    feedback: s.game.phase === "hint" ? "round_failed" : s.game.phase === "stage_complete" ? "blocked" : null,
    interception: { stage: s.game.stage + 1, phase: s.game.phase, collected: [...s.game.collected],
      missing: missingTargets(s.game), clueIndex: s.game.clueIndex, failures: s.game.stageFailures,
      failureReason: s.game.failure, boardX: s.game.boardX, boardY: WINDOW_BODY.y, boardAngle: s.game.boardAngle,
      words: s.game.words.map((w) => ({ ...w })) } };
}

/** Text discovery is presentation-local; only all three stages plus the original hold submit the existing controller proof. */
export function EndingScene({ state, events }: SceneComponentProps) {
  const runtimeRef = useRef(createEndingViewState());
  const [view, setView] = useState(() => ({ ...runtimeRef.current }));
  const sceneRef = useRef<HTMLElement>(null);
  const [stageScale, setStageScale] = useState(1);
  const fieldRef = useRef<HTMLDivElement>(null);
  const paddleRef = useRef<HTMLButtonElement>(null);
  const lockButtonRef = useRef<HTMLButtonElement>(null);
  const retryButtonRef = useRef<HTMLButtonElement>(null);
  const dragPointerRef = useRef<{ id: number; offset: number } | null>(null);
  const pointerTargetRef = useRef<number | null>(null);
  const heldDirectionsRef = useRef({ left: false, right: false });
  useEffect(() => {
    const element = sceneRef.current;
    if (!element) return;
    const measure = () => setStageScale(Math.min(element.clientWidth / 430, (element.clientHeight - 40) / 820));
    measure();
    const observer = typeof ResizeObserver === "function" ? new ResizeObserver(measure) : null;
    observer?.observe(element);
    window.addEventListener("resize", measure);
    return () => { observer?.disconnect(); window.removeEventListener("resize", measure); };
  }, []);
  const clearMotion = useCallback(() => {
    dragPointerRef.current = null; pointerTargetRef.current = null;
    heldDirectionsRef.current.left = false; heldDirectionsRef.current.right = false;
  }, []);
  const publishRuntime = useCallback(() => {
    const r = runtimeRef.current;
    setView({ ...r, game: { ...r.game, collected: [...r.game.collected], words: r.game.words.map((w) => ({ ...w })), ring: r.game.ring ? { ...r.game.ring } : null } });
    setEndingRuntimeSnapshot(toRuntimeSnapshot(r));
  }, []);
  const advanceSimulation = useCallback((requestedMs: number) => {
    let remaining = clamp(Number.isFinite(requestedMs) ? requestedMs : 0, 0, 10000);
    while (remaining > 0) {
      const delta = Math.min(remaining, 1000 / 120); remaining -= delta;
      const r = runtimeRef.current;
      if (r.paused) continue;
      r.phaseElapsedMs += delta;
      if (["deploy", "intercept", "impact", "failed", "lock"].includes(r.phase)) r.introElapsedMs += delta;
      if (r.phase === "blackout" && r.phaseElapsedMs >= BLACKOUT_MS) {
        r.phase = "deploy"; r.phaseElapsedMs = 0; r.introElapsedMs = 0;
        events.emit("prologue_narrator_intro"); queueMicrotask(() => paddleRef.current?.focus()); continue;
      }
      if (r.phase === "deploy" && r.phaseElapsedMs >= ERROR_DEPLOY_MS) {
        r.phase = "intercept"; r.phaseElapsedMs = 0; continue;
      }
      if (["intercept", "impact", "failed"].includes(r.phase)) {
        const oldStages = r.game.completedStages, oldFailures = r.game.failures;
        stepInterception(r.game, delta, { direction: Number(heldDirectionsRef.current.right) - Number(heldDirectionsRef.current.left), targetX: pointerTargetRef.current });
        r.blockedCount = r.game.completedStages;
        if (r.blockedCount > oldStages) events.emit("prologue_error_intercepted", { blockedCount: r.blockedCount, requiredBlocks: REQUIRED_BLOCKS });
        if (r.game.failures > oldFailures) {
          clearMotion(); events.emit("prologue_error_intercept_missed", { misses: r.game.failures, reason: r.game.failure });
          queueMicrotask(() => retryButtonRef.current?.focus());
        }
        r.phase = r.game.phase === "hint" ? "failed" : r.game.phase === "stage_complete" ? "impact" : "intercept";
        if (r.game.phase === "complete") {
          r.phase = "lock"; r.phaseElapsedMs = 0; clearMotion();
          events.emit("prologue_error_lock_ready", { requiredHoldMs: HOLD_TO_CATCH_MS });
          queueMicrotask(() => lockButtonRef.current?.focus());
        }
        continue;
      }
      if (r.phase === "lock" && r.lockActive) {
        r.lockHeldMs = Math.min(HOLD_TO_CATCH_MS, r.lockHeldMs + delta);
        if (r.lockHeldMs >= HOLD_TO_CATCH_MS) {
          r.lockActive = false; r.phase = "caught"; r.phaseElapsedMs = 0; r.dialogueStep = 0;
          events.emit("prologue_narrator_caught", { blockedCount: r.blockedCount, lockHeldMs: r.lockHeldMs });
        }
        continue;
      }
      if (r.phase === "caught") {
        const next = r.phaseElapsedMs >= 5200 ? 3 : r.phaseElapsedMs >= 4100 ? 2 : r.phaseElapsedMs >= 3000 ? 1 : 0;
        if (next !== r.dialogueStep) { r.dialogueStep = next; if (next === 3) events.emit("prologue_narrator_bargain"); }
        if (r.phaseElapsedMs >= 8900) { r.phase = "burst"; r.phaseElapsedMs = 0; events.emit("prologue_white_burst"); }
        continue;
      }
      if (r.phase === "burst" && r.phaseElapsedMs >= 950) { r.phase = "whiteout"; r.phaseElapsedMs = 0; continue; }
      if (r.phase === "whiteout" && r.phaseElapsedMs >= 700 && !r.completionRequested) {
        r.completionRequested = true;
        kit.actOne.completeNarratorIntervention({ interceptedCount: r.blockedCount, lockHeldMs: r.lockHeldMs, failed: false });
      }
    }
    publishRuntime();
  }, [events, publishRuntime, clearMotion]);
  useEffect(() => {
    events.emit("ending_started"); events.emit("prologue_blackout_started", { durationMs: BLACKOUT_MS });
    setEndingRuntimeSnapshot(toRuntimeSnapshot(runtimeRef.current));
    return () => clearEndingRuntimeSnapshot();
  }, [events]);
  useEffect(() => {
    const previous = window.advanceTime, controlled = window.__vt_pending instanceof Set;
    let frame = 0, last = performance.now();
    const advance = async (ms: number) => { advanceSimulation(ms); await Promise.resolve(); };
    window.advanceTime = advance;
    if (!controlled) {
      const loop = (now: number) => { advanceSimulation(Math.min(100, now - last)); last = now; frame = requestAnimationFrame(loop); };
      frame = requestAnimationFrame(loop);
    }
    return () => { cancelAnimationFrame(frame); if (window.advanceTime === advance) { if (previous) window.advanceTime = previous; else delete window.advanceTime; } };
  }, [advanceSimulation]);
  function cancelLock() {
    const r = runtimeRef.current;
    if (r.phase !== "lock" || !r.lockActive) return;
    const heldMs = r.lockHeldMs; r.lockActive = false; r.lockHeldMs = 0;
    events.emit("prologue_error_lock_cancelled", { heldMs }); publishRuntime();
  }
  function beginLock() {
    const r = runtimeRef.current;
    if (r.paused || r.phase !== "lock" || r.lockActive) return;
    r.lockActive = true; events.emit("prologue_error_lock_started", { requiredHoldMs: HOLD_TO_CATCH_MS }); publishRuntime();
  }
  function setDirection(key: string, held: boolean) {
    if (key === "ArrowLeft" || key.toLowerCase() === "a") { heldDirectionsRef.current.left = held; return true; }
    if (key === "ArrowRight" || key.toLowerCase() === "d") { heldDirectionsRef.current.right = held; return true; }
    return false;
  }
  useEffect(() => {
    const visibility = () => { runtimeRef.current.paused = document.hidden; clearMotion(); if (document.hidden) cancelLock(); publishRuntime(); };
    const down = (e: KeyboardEvent) => {
      if (setDirection(e.key, true)) { e.preventDefault(); return; }
      if ((e.key === " " || e.key === "Enter") && !e.repeat && runtimeRef.current.phase === "lock") { e.preventDefault(); beginLock(); }
    };
    const up = (e: KeyboardEvent) => {
      if (setDirection(e.key, false)) { e.preventDefault(); return; }
      if ((e.key === " " || e.key === "Enter") && runtimeRef.current.phase === "lock") { e.preventDefault(); cancelLock(); }
    };
    const blur = () => { clearMotion(); cancelLock(); };
    document.addEventListener("visibilitychange", visibility); window.addEventListener("keydown", down);
    window.addEventListener("keyup", up); window.addEventListener("blur", blur);
    return () => { document.removeEventListener("visibilitychange", visibility); window.removeEventListener("keydown", down); window.removeEventListener("keyup", up); window.removeEventListener("blur", blur); };
  });
  function logicalX(clientX: number): number | null {
    const rect = fieldRef.current?.getBoundingClientRect(); return rect?.width ? (clientX - rect.left) / rect.width * 430 : null;
  }
  function beginDrag(e: React.PointerEvent<HTMLButtonElement>) {
    if (!["clue", "playing"].includes(runtimeRef.current.game.phase) || runtimeRef.current.paused) return;
    const x = logicalX(e.clientX); if (x === null) return;
    dragPointerRef.current = { id: e.pointerId, offset: x - runtimeRef.current.game.boardX };
    pointerTargetRef.current = runtimeRef.current.game.boardX;
    try { e.currentTarget.setPointerCapture(e.pointerId); } catch { /* Pointer capture may be unavailable. */ }
  }
  function moveDrag(e: React.PointerEvent<HTMLButtonElement>) {
    const drag = dragPointerRef.current;
    if (!drag || drag.id !== e.pointerId) return;
    e.preventDefault(); const x = logicalX(e.clientX); if (x !== null) pointerTargetRef.current = x - drag.offset;
  }
  function endDrag(e: React.PointerEvent<HTMLButtonElement>) {
    if (dragPointerRef.current?.id !== e.pointerId) return;
    dragPointerRef.current = null; pointerTargetRef.current = null;
    try { e.currentTarget.releasePointerCapture(e.pointerId); } catch { /* The browser may already have released it. */ }
  }
  function reviewClues() { clearMotion(); toggleClueReview(runtimeRef.current.game); publishRuntime(); }
  function retryInterception() {
    clearMotion(); continueInterception(runtimeRef.current.game); runtimeRef.current.phase = "intercept"; publishRuntime();
    queueMicrotask(() => paddleRef.current?.focus());
  }
  const game = view.game, stage = INTERCEPTION_STAGES[game.stage];
  const showGame = ["deploy", "intercept", "impact", "failed", "lock"].includes(view.phase);
  const intro = actOneContent.audioNarration.prologue_narrator_intro.subtitleSegmentsZh;
  const introIndex = view.introElapsedMs >= 6800 ? 2 : view.introElapsedMs >= 3400 ? 1 : 0;
  const dialogue = view.phase === "caught" ? DIALOGUE[view.dialogueStep] : null;
  const lockProgress = clamp(view.lockHeldMs / HOLD_TO_CATCH_MS, 0, 1);
  const lockStyle = { left: "50%", top: "42%", transform: "translate(-50%, -50%)", "--lock-progress": `${lockProgress * 360}deg` } as CSSProperties;
  const boardStyle = { left: `${game.boardX / 430 * 100}%`, top: `${WINDOW_BODY.y / 820 * 100}%`, transform: `translate(-50%, -50%) rotate(${game.boardAngle}deg)` } as CSSProperties;
  return (
    <section ref={sceneRef} className={`ending-scene ending-text-discovery ending-${view.phase}`} aria-label="序章结算"
      data-ending-phase={view.phase} data-blocked-count={view.blockedCount} data-misses={game.failures} data-semantic-stage={game.stage + 1}>
      {view.phase === "blackout" ? <div className="ending-seven-second-blackout" aria-label="黑屏" /> : null}
      {showGame ? <>
        <header className="ending-intercept-hud"><div><small>LOCATION ERROR</small><strong>未结束的字句</strong></div>
          <ol aria-label={`已接回 ${view.blockedCount} 段，共三段`}>{[0,1,2].map((i) => <li key={i} className={i < view.blockedCount ? "is-complete" : ""}>{i + 1}</li>)}</ol>
          <span>{game.collected.length ? `留下 ${game.collected.length}/${stage.targets.length}` : `第 ${game.stage + 1} 段`}</span>
        </header>
        <p key={`intro-${introIndex}`} className="ending-game-subtitle game-subtitle-frame subtitle-tone-narrator is-line-entering" aria-live="polite">
          <small className="game-subtitle-speaker">旁白</small><span>{intro[introIndex]}</span>
        </p>
        {view.phase !== "lock" ? <section className="ending-clue-lane" aria-label="字句线索">
          <div className="ending-clue-trail" aria-hidden="true">{stage.fragments.slice(Math.max(0, game.clueIndex - 2), game.clueIndex).join(" ")}</div>
          <p aria-live="polite">{stage.fragments[game.clueIndex]}</p>
          <button type="button" onClick={reviewClues} disabled={view.phase === "deploy" || game.phase === "hint" || game.phase === "stage_complete"}>回看完整字句</button>
        </section> : null}
        <div ref={fieldRef} className={`ending-intercept-field is-${view.phase}`} style={{ transform: `translateX(-50%) scale(${stageScale})` }}>
          <i className="ending-field-grid" aria-hidden="true" />
          {game.assist && game.phase === "playing" ? game.words.filter((w) => !w.contacted && w.target).map((w) =>
            <i key={`assist-${w.id}`} className="ending-word-assist" style={{ left: `${w.x / 430 * 100}%`, top: `${WINDOW_BODY.y / 820 * 100}%` }} aria-hidden="true" />) : null}
          {view.phase !== "lock" ? game.words.map((w) => <div key={w.id} className={`ending-word-body ${w.contacted ? "is-retained" : ""}`} data-word-id={w.id}
            style={{ left: `${w.x / 430 * 100}%`, top: `${w.y / 820 * 100}%`, width: `${w.width}px`, height: `${w.height}px`, transform: `translate(-50%, -50%) rotate(${w.angle}deg)` }}>{w.text}</div>) : null}
          {game.ring ? <i className="ending-word-contact" style={{ left: `${game.ring.x / 430 * 100}%`, top: `${game.ring.y / 820 * 100}%` }} aria-hidden="true" /> : null}
          {view.phase === "lock" ? <>
            <button ref={lockButtonRef} type="button" className={`narrator-orb is-lock-target ${view.lockActive ? "is-held" : ""}`} style={lockStyle}
              aria-label={`按住旁白圆圈完成锁定，当前 ${Math.round(lockProgress * 100)}%`}
              onPointerDown={(e) => { try { e.currentTarget.setPointerCapture(e.pointerId); } catch { /* Optional. */ } beginLock(); }}
              onPointerUp={cancelLock} onPointerCancel={cancelLock} onLostPointerCapture={cancelLock}>
              <span aria-hidden="true" /><strong>{Math.round(lockProgress * 100)}%</strong>
            </button><div className="ending-capture-frame" aria-hidden="true"><i/><i/><i/><i/></div>
          </> : null}
          <button ref={paddleRef} type="button" className={`ending-geo-error-board ${view.phase === "deploy" ? "is-deploying" : ""}`} style={boardStyle}
            aria-label="经纬度错误窗口，可拖动或用 A D 和左右方向键移动"
            disabled={["hint", "review", "stage_complete", "complete"].includes(game.phase)}
            onPointerDown={beginDrag} onPointerMove={moveDrag} onPointerUp={endDrag} onPointerCancel={endDrag}
            onLostPointerCapture={(e) => { if (dragPointerRef.current?.id === e.pointerId) { dragPointerRef.current = null; pointerTargetRef.current = null; } }}
            onBlur={() => { clearMotion(); }}>
            <span className="ending-error-title"><small>LOCATION ERROR</small><i aria-hidden="true">×</i></span>
            <strong>经度与纬度不存在</strong><span className="ending-error-coordinates">null / null</span>
          </button>
          {game.phase === "hint" ? <section className="ending-intercept-failed" role="dialog" aria-modal="true" aria-labelledby="ending-retry-title">
            <small>这一瞬间已暂停</small><h2 id="ending-retry-title">字句还在等你</h2><p>{failureHint(game)}</p>
            <p className="ending-retained-words">{game.collected.length ? `已留下：${game.collected.join("、")}。` : ""}这一段的进度会保留。</p>
            {game.stageFailures >= 3 ? <label><input type="checkbox" checked={game.assist} onChange={(e) => { runtimeRef.current.game.assist = e.target.checked; publishRuntime(); }}/> 落点助视</label> : null}
            <button ref={retryButtonRef} type="button" onClick={retryInterception}>继续这一段</button>
          </section> : null}
          {game.phase === "review" ? <section className="ending-clue-review" role="dialog" aria-modal="true" aria-labelledby="ending-clue-title">
            <h2 id="ending-clue-title">第 {game.stage + 1} 段 · 完整字句</h2>{stage.fragments.map((t) => <p key={t}>{t}</p>)}
            <small>阅读时文字暂停，不会漏掉目标。</small><button type="button" onClick={reviewClues}>回到这一瞬间</button>
          </section> : null}
        </div>
        <p className="ending-control-hint">{view.phase === "lock" ? "按住圆圈 1.4 秒完成锁定" : game.collected.length ? `已留下：${game.collected.join("、")}` : game.stageFailures >= 2 ? "拖动窗口标题栏 · A / D 或 ← / →" : "字句会重来，完整线索可随时回看。"}</p>
      </> : null}
      {view.phase === "caught" ? (
        <>
          <div className="ending-capture-frame is-complete" aria-hidden="true"><i /><i /><i /><i /></div>
          <div className="narrator-orb is-caught" role="img" aria-label="已被锁定的旁白圆圈">
            <span aria-hidden="true" />
            <strong>已锁定</strong>
          </div>
          {dialogue ? (
            <p
              key={`caught-${view.dialogueStep}`}
              className={`ending-dialogue game-subtitle-frame subtitle-tone-${dialogue.speaker === "narrator" ? "narrator" : "player"} is-${dialogue.speaker} is-line-entering`}
              aria-live="polite"
            >
              <small className="game-subtitle-speaker">{dialogue.speaker === "narrator" ? "旁白" : "我"}</small>
              <span>{dialogue.text}</span>
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
