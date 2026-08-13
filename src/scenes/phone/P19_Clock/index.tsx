import { useCallback, useEffect, useRef, useState, type CSSProperties } from "react";
import { GameSubtitleFrame, type GameSubtitleTone } from "../../../components/GameSubtitleFrame";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import { formatClockSeconds, selectClockTint } from "../../../core/ClockTime";
import type {
  ClockArchiveClueId,
  ClockCalibrationStep,
  ClockCoarseLockId,
  ClockDriftChannelId
} from "../../../core/types";
import type { ClockCalibrationResult } from "../../../modules/ClockCalibrationController";
import clockContent from "../../../data/chapter4-clock.content.json";
import { kit } from "../../../modules/GameKit";

const PLAYABLE_STEPS: readonly ClockCalibrationStep[] = ["target_selection", "coarse_time", "seconds_trim", "phase_lock"];

type FeedbackTone = "neutral" | "error" | "success";
interface ClockFeedback { tone: FeedbackTone; text: string; }
interface ClockCandidate { seconds: number; time: string; period: string; title: string; note: string; visual: string; }
interface ArchiveClue { id: ClockArchiveClueId | string; stamp: string; title: string; body: string; valid: boolean; }
interface DriftChannel { id: ClockDriftChannelId; label: string; drift: number; display: string; expectedCorrection: number; }
interface PhaseRound { label: string; protocol: string; targetMin: number; targetMax: number; cycleMs: number; reverse: boolean; }

function lineDurationMs(text: string) { return Math.max(2400, Math.min(6500, 1600 + 120 * Array.from(text).length)); }
function parseDialogueLine(line: string): { speaker: string; tone: GameSubtitleTone; text: string } {
  const match = /^(系统|旁白|任务|玩家|我)[:：](.*)$/.exec(line.trim());
  if (!match) return { speaker: "系统", tone: "system", text: line };
  const tones: Record<string, GameSubtitleTone> = { 系统: "system", 旁白: "narrator", 任务: "task", 玩家: "player", 我: "player" };
  return { speaker: match[1] === "玩家" ? "我" : match[1], tone: tones[match[1]] ?? "system", text: match[2].trim() };
}
function wrap(value: number, size: number) { return ((value % size) + size) % size; }
function pad(value: number) { return String(value).padStart(2, "0"); }
function resultFeedback(result: ClockCalibrationResult, successText: string): ClockFeedback {
  if (result === "accepted") return { tone: "success", text: successText };
  if (result === "wrong_target") return { tone: "error", text: clockContent.feedback.wrongTarget };
  if (result === "wrong_time") return { tone: "error", text: clockContent.feedback.wrongTime };
  if (result === "missed_lock") return { tone: "error", text: clockContent.feedback.missedLock };
  if (result === "already_complete") return { tone: "success", text: clockContent.feedback.alreadyComplete };
  return { tone: "error", text: clockContent.feedback.locked };
}

/** 四个连续内容关卡。DEV 检查点只构造各关入口，关内进度由正式控制器保存。 */
export function ClockScene({ state, router }: SceneComponentProps) {
  const clock = state.clockCalibration;
  const { hh, mm, ss } = formatClockSeconds(clock.displayedSeconds);
  const tint = selectClockTint(clock.displayedSeconds, clock.phase);
  const [candidate, setCandidate] = useState<number | null>(clock.selectedTargetSeconds);
  const [corrections, setCorrections] = useState<Partial<Record<ClockDriftChannelId, number>>>({});
  const [feedback, setFeedback] = useState<ClockFeedback | null>(null);
  const [dialogueStep, setDialogueStep] = useState(0);
  const [lockPosition, setLockPosition] = useState(0);
  const lockPositionRef = useRef(0);
  const lockOriginRef = useRef(0);
  const frameRef = useRef<number | null>(null);

  const aligned = clock.step === "complete" || clock.phase === "aligned";
  const playable = state.chapter4.phase === "clock_phase_lock" || aligned;
  const stepIndex = aligned ? PLAYABLE_STEPS.length : Math.max(0, PLAYABLE_STEPS.indexOf(clock.step));
  const candidates = clockContent.targetSelection.options as ClockCandidate[];
  const archiveClues = clockContent.targetSelection.clues as ArchiveClue[];
  const driftChannels = clockContent.secondsTrim.channels as DriftChannel[];
  const phaseRounds = clockContent.phaseLock.rounds as PhaseRound[];
  const currentRound = phaseRounds[Math.min(clock.phaseLockHits, phaseRounds.length - 1)];
  const archiveReady = clock.archiveClueIds.length === 3 && candidate !== null;
  const coarseReady = clock.coarseLockIds.length === 2;
  const driftReady = clock.driftCorrectedChannelIds.length === 3;

  useEffect(() => {
    setCandidate(clock.selectedTargetSeconds);
    setCorrections({});
    setFeedback(null);
  }, [clock.step, clock.selectedTargetSeconds]);

  useEffect(() => {
    if (clock.step !== "phase_lock") {
      if (frameRef.current !== null) window.cancelAnimationFrame(frameRef.current);
      frameRef.current = null;
      lockPositionRef.current = 0;
      setLockPosition(0);
      return undefined;
    }
    lockOriginRef.current = performance.now();
    const animate = (now: number) => {
      const raw = ((now - lockOriginRef.current) % currentRound.cycleMs) / currentRound.cycleMs;
      const position = currentRound.reverse ? 1 - raw : raw;
      lockPositionRef.current = position;
      setLockPosition(position);
      frameRef.current = window.requestAnimationFrame(animate);
    };
    frameRef.current = window.requestAnimationFrame(animate);
    return () => {
      if (frameRef.current !== null) window.cancelAnimationFrame(frameRef.current);
      frameRef.current = null;
    };
  }, [clock.phaseLockHits, clock.step, currentRound.cycleMs, currentRound.reverse]);

  const submitLock = useCallback(() => {
    if (clock.step !== "phase_lock") return;
    const position = lockPositionRef.current;
    const hit = position >= currentRound.targetMin && position <= currentRound.targetMax;
    const result = kit.clock.submitPhaseLock(hit);
    const nextHits = hit ? Math.min(3, clock.phaseLockHits + 1) : 0;
    setFeedback(resultFeedback(result, nextHits >= 3 ? clockContent.feedback.complete : `${currentRound.label}协议通过，进入下一轮。`));
    lockOriginRef.current = performance.now();
    lockPositionRef.current = currentRound.reverse ? 1 : 0;
  }, [clock.phaseLockHits, clock.step, currentRound]);

  useEffect(() => {
    if (clock.step !== "phase_lock") return undefined;
    const onKeyDown = (event: KeyboardEvent) => {
      const element = event.target as HTMLElement | null;
      if (element?.tagName === "BUTTON" || element?.tagName === "INPUT" || element?.isContentEditable || event.code !== "Space") return;
      event.preventDefault();
      submitLock();
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [clock.step, submitLock]);

  useEffect(() => {
    if (!aligned) { setDialogueStep(0); return undefined; }
    const timers: number[] = [];
    let elapsed = 0;
    for (let index = 1; index < clockContent.alignedDialogue.length; index += 1) {
      elapsed += lineDurationMs(clockContent.alignedDialogue[index - 1]);
      timers.push(window.setTimeout(() => setDialogueStep(index), elapsed));
    }
    return () => timers.forEach((timer) => window.clearTimeout(timer));
  }, [aligned]);

  const toggleClue = (clueId: string) => {
    if (!["room_b2_04", "schedule_0800", "attendance_open"].includes(clueId)) {
      setFeedback({ tone: "error", text: "这条记录属于其他场景，无法写入 B2-04 档案。" });
      return;
    }
    kit.clock.toggleArchiveClue(clueId as ClockArchiveClueId);
  };
  const selectTarget = () => {
    if (candidate === null) return;
    setFeedback(resultFeedback(kit.clock.selectTarget(candidate), clockContent.feedback.targetAccepted));
  };
  const adjustCoarse = (unit: ClockCoarseLockId, delta: number) => {
    const result = kit.clock.adjustCoarseBy(unit, delta);
    if (result !== "accepted") setFeedback(resultFeedback(result, ""));
  };
  const lockCoarse = (unit: ClockCoarseLockId) => {
    const result = kit.clock.lockCoarseUnit(unit);
    setFeedback(resultFeedback(result, result === "accepted" ? `${unit === "hour" ? "小时" : "分钟"}机芯已锁定。` : ""));
  };
  const confirmCoarse = () => setFeedback(resultFeedback(kit.clock.confirmCoarseTime(), clockContent.feedback.coarseAccepted));
  const correctChannel = (channel: DriftChannel) => {
    const correction = corrections[channel.id];
    if (correction === undefined) return;
    const result = kit.clock.correctDriftChannel(channel.id, correction);
    setFeedback(resultFeedback(result, result === "accepted" ? `${channel.label}漂移已归零。` : ""));
  };
  const confirmPrecision = () => setFeedback(resultFeedback(kit.clock.confirmPrecision(), clockContent.feedback.precisionAccepted));
  const dialogueLine = aligned ? parseDialogueLine(clockContent.alignedDialogue[Math.min(dialogueStep, clockContent.alignedDialogue.length - 1)]) : null;
  const tintStyle = { background: tint.color, opacity: Math.min(tint.alpha, 0.18) } satisfies CSSProperties;
  const targetStyle = { "--clock-target-left": `${currentRound.targetMin * 100}%`, "--clock-target-width": `${(currentRound.targetMax - currentRound.targetMin) * 100}%` } as CSSProperties;

  return (
    <section className={`app-screen clock-page-v3 ${aligned ? "is-complete" : ""}`.trim()} aria-label={clockContent.pageTitle} data-clock-phase={clock.phase} data-clock-step={clock.step} data-clock-lock-hits={clock.phaseLockHits}>
      <div className="clock-calibration-tint" aria-hidden="true" style={tintStyle} />
      <header className="clock-terminal-header">
        <PhoneNavButton kind="back" label="返回手机主页" onClick={() => router.goTo("phone_home")} />
        <div><small>B2-04 / TIME REPAIR</small><h1>{clockContent.pageTitle}</h1></div>
        <strong>{hh}:{mm}</strong>
      </header>
      <main>
        <section className="clock-status-ribbon" aria-label="校时状态">
          <div><small>LOCAL</small><strong>{hh}:{mm}:{ss}</strong></div><span>→</span>
          <div><small>TARGET</small><strong>08:00:00</strong></div><em>{aligned ? "SYNC" : `${Math.min(stepIndex + 1, 4)}/4`}</em>
        </section>
        <nav className="clock-step-rail" aria-label="四关校时流程">
          {clockContent.stages.map((stage, index) => <div key={stage.id} className={`${!aligned && index === stepIndex ? "is-active" : ""} ${aligned || index < stepIndex ? "is-complete" : ""}`.trim()}><b>{String(index + 1).padStart(2, "0")}</b><span>{stage.label}</span></div>)}
        </nav>

        {!playable ? <section className="clock-play-panel clock-locked-panel"><p className="clock-panel-code">ACCESS DENIED</p><div className="clock-lock-glyph">×</div><h2>{clockContent.locked.title}</h2><p>{clockContent.locked.body}</p><button type="button" onClick={() => router.goTo("phone_home")}>返回当前任务</button></section> : null}

        {playable && clock.step === "target_selection" ? <section className="clock-play-panel clock-archive-panel">
          <header className="clock-panel-heading"><div><p className="clock-panel-code">01 / ARCHIVE REBUILD</p><h2>{clockContent.targetSelection.title}</h2></div><span>{clock.archiveClueIds.length}/3 证据</span></header>
          <p className="clock-panel-copy">{clockContent.targetSelection.body}</p>
          <div className="clock-clue-board">{archiveClues.map((clue) => {
            const selected = clock.archiveClueIds.includes(clue.id as ClockArchiveClueId);
            return <button key={clue.id} type="button" className={selected ? "is-selected" : ""} aria-pressed={selected} onClick={() => toggleClue(clue.id)}><time>{clue.stamp}</time><strong>{clue.title}</strong><span>{clue.body}</span></button>;
          })}</div>
          <div className="clock-anchor-strip">{candidates.map((option) => <button key={option.seconds} type="button" className={candidate === option.seconds ? "is-selected" : ""} onClick={() => { setCandidate(option.seconds); setFeedback(null); }}><small>{option.period}</small><strong>{option.time}</strong><span>{option.title}</span></button>)}</div>
          <button className="clock-main-action" type="button" disabled={!archiveReady} onClick={selectTarget}>提交档案与时刻</button>
        </section> : null}

        {playable && clock.step === "coarse_time" ? <section className="clock-play-panel clock-coarse-panel">
          <header className="clock-panel-heading"><div><p className="clock-panel-code">02 / DUAL MOVEMENT</p><h2>{clockContent.coarseTime.title}</h2></div><span>{clock.coarseLockIds.length}/2 LOCKED</span></header>
          <p className="clock-panel-copy">{clockContent.coarseTime.body}</p>
          <div className="clock-reel-pair"><ClockReel label="HOUR" value={Number(hh)} size={24} locked={clock.coarseLockIds.includes("hour")} onDecrease={() => adjustCoarse("hour", -1)} onIncrease={() => adjustCoarse("hour", 1)} onLock={() => lockCoarse("hour")} /><i className="clock-reel-colon">:</i><ClockReel label="MINUTE" value={Number(mm)} size={60} locked={clock.coarseLockIds.includes("minute")} onDecrease={() => adjustCoarse("minute", -1)} onIncrease={() => adjustCoarse("minute", 1)} onLock={() => lockCoarse("minute")} /></div>
          <div className="clock-lock-ledger"><span className={clock.coarseLockIds.includes("hour") ? "is-done" : ""}>08 时机芯</span><span className={clock.coarseLockIds.includes("minute") ? "is-done" : ""}>00 分机芯</span><span>23 秒暂存</span></div>
          <button className="clock-main-action" type="button" disabled={!coarseReady} onClick={confirmCoarse}>进入漂移核对</button>
        </section> : null}

        {playable && clock.step === "seconds_trim" ? <section className="clock-play-panel clock-drift-panel">
          <header className="clock-panel-heading"><div><p className="clock-panel-code">03 / DRIFT MATRIX</p><h2>{clockContent.secondsTrim.title}</h2></div><span>{clock.driftCorrectedChannelIds.length}/3 ONLINE</span></header>
          <p className="clock-panel-copy">{clockContent.secondsTrim.body}</p>
          <div className="clock-drift-matrix">{driftChannels.map((channel) => {
            const corrected = clock.driftCorrectedChannelIds.includes(channel.id);
            return <article key={channel.id} className={corrected ? "is-corrected" : ""}><header><span>{channel.label}</span><strong>{corrected ? "00" : channel.display}</strong></header><div>{clockContent.secondsTrim.corrections.map((value) => <button key={value} type="button" disabled={corrected} className={corrections[channel.id] === value ? "is-selected" : ""} onClick={() => setCorrections((current) => ({ ...current, [channel.id]: value }))}>{value > 0 ? `+${value}` : value}</button>)}</div><button className="clock-channel-apply" type="button" disabled={corrected || corrections[channel.id] === undefined} onClick={() => correctChannel(channel)}>{corrected ? "已归零" : "应用反向修正"}</button></article>;
          })}</div>
          <button className="clock-main-action" type="button" disabled={!driftReady} onClick={confirmPrecision}>生成 08:00:00</button>
        </section> : null}

        {playable && clock.step === "phase_lock" ? <section className="clock-play-panel clock-phase-panel">
          <header className="clock-panel-heading"><div><p className="clock-panel-code">04 / THREE PROTOCOLS</p><h2>{clockContent.phaseLock.title}</h2></div><span>{clock.phaseLockAttempts} ATTEMPTS</span></header>
          <p className="clock-panel-copy">{clockContent.phaseLock.body}</p>
          <div className="clock-protocol-tabs">{phaseRounds.map((round, index) => <div key={round.label} className={`${index === clock.phaseLockHits ? "is-active" : ""} ${index < clock.phaseLockHits ? "is-done" : ""}`.trim()}><b>0{index + 1}</b><span>{round.label}</span><small>{round.protocol}</small></div>)}</div>
          <div className="clock-phase-lane" style={{ ...targetStyle, "--clock-lock-position": `${lockPosition * 100}%` } as CSSProperties}><span className="clock-phase-target" /><i className="clock-phase-sweep" /><b>{currentRound.reverse ? "REVERSE" : "FORWARD"}</b></div>
          <div className="clock-pulse-readout"><small>{currentRound.label}</small><strong>{String(Math.round(lockPosition * 999)).padStart(3, "0")}</strong><em>{currentRound.protocol}</em></div>
          <button className="clock-main-action is-release" type="button" onClick={submitLock}>执行本轮放行 <kbd>SPACE</kbd></button>
        </section> : null}

        {playable && aligned ? <section className="clock-play-panel clock-complete-panel"><p className="clock-panel-code">TIME AXIS / RELEASED</p><div className="clock-complete-mark">08:00</div><h2>{clockContent.complete.title}</h2><p>{clockContent.complete.body}</p><div className="clock-complete-ledger"><span>四关校时</span><strong>COMPLETE</strong><span>放行尝试</span><strong>{clock.phaseLockAttempts}</strong><span>漂移尝试</span><strong>{clock.driftAttempts}</strong></div>{dialogueLine ? <GameSubtitleFrame key={dialogueStep} text={dialogueLine.text} tone={dialogueLine.tone} speaker={dialogueLine.speaker} /> : null}<button className="clock-main-action" type="button" onClick={() => router.goTo("phone_home")}>返回手机主页</button></section> : null}
        {feedback && !aligned ? <p className={`clock-feedback is-${feedback.tone}`} role="status">{feedback.text}</p> : null}
      </main>
    </section>
  );
}

function ClockReel({ label, value, size, locked, onDecrease, onIncrease, onLock }: { label: string; value: number; size: number; locked: boolean; onDecrease: () => void; onIncrease: () => void; onLock: () => void; }) {
  return <div className={`clock-number-reel ${locked ? "is-locked" : ""}`}><small>{label}</small><button type="button" disabled={locked} onClick={onIncrease}>▲</button><span>{pad(wrap(value + 1, size))}</span><strong role="spinbutton" aria-valuemin={0} aria-valuemax={size - 1} aria-valuenow={value}>{pad(value)}</strong><span>{pad(wrap(value - 1, size))}</span><button type="button" disabled={locked} onClick={onDecrease}>▼</button><button className="clock-reel-lock" type="button" onClick={onLock}>{locked ? "LOCKED" : "锁定"}</button></div>;
}
