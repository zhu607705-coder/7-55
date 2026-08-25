import { useCallback, useEffect, useRef, useState } from "react";
import type { KeyboardEvent as ReactKeyboardEvent, PointerEvent as ReactPointerEvent } from "react";
import {
  PhoneActionSheet,
  PhoneAppHeader,
  PhoneAppScaffold,
  PhoneStateView
} from "../../../components/PhoneAppUi";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import { selectFeatureAccess } from "../../../core/FeatureAccess";
import type { EndlessChallengeModeId } from "../../../core/types";
import content from "../../../data/endless-arcade.content.json";
import { readEndlessArcadeDeveloperSeed } from "../../../modules/DeveloperChannel";
import { kit } from "../../../modules/GameKit";
import type { EndlessArcadeRunTicket } from "../../../modules/EndlessArcadeController";
import { EndlessArcadeGameHost, type EndlessArcadeGameHostHandle } from "./EndlessArcadeGameHost";
import {
  ENDLESS_CHALLENGE_MODE_IDS,
  getEndlessChallengeDefinition
} from "./EndlessChallengeRegistry";
import {
  createEndlessArcadeClosedEmitter,
  consumePendingEndlessArcadeResume,
  emitEndlessArcadeConfirmExitPause,
  emitEndlessArcadePauseEvent,
  emitEndlessArcadeRuntimeErrorPause
} from "./EndlessArcadeSceneEvents";
import {
  beginEndlessArcadeLifecycleEpoch,
  EndlessArcadeRuntimeError,
  clearEndlessArcadeDebugSnapshot,
  isCurrentEndlessArcadeLifecycleEpoch,
  setEndlessArcadeDebugSnapshot
} from "./EndlessArcadeRuntime";
import type {
  EndlessArcadeHostStatus,
  EndlessArcadeRunSnapshot,
  EndlessArcadeRunSummary,
  EndlessArcadeControlAction,
  EndlessArcadeViewPhase
} from "./EndlessArcadeRuntime";

function initialSnapshot(mode: EndlessChallengeModeId): EndlessArcadeRunSnapshot {
  return { mode, score: 0, progress: 0, tier: 1, combo: 0 };
}

function createInitialViewState() {
  const developerSeed = readEndlessArcadeDeveloperSeed();
  if (!developerSeed) {
    return {
      developerSeed,
      phase: "hub" as EndlessArcadeViewPhase,
      selectedMode: null as EndlessChallengeModeId | null,
      snapshot: null as EndlessArcadeRunSnapshot | null,
      summary: null as EndlessArcadeRunSummary | null
    };
  }
  if (developerSeed.mode === null || developerSeed.boot === "hub") {
    return {
      developerSeed,
      phase: "hub" as EndlessArcadeViewPhase,
      selectedMode: null as EndlessChallengeModeId | null,
      snapshot: null as EndlessArcadeRunSnapshot | null,
      summary: null as EndlessArcadeRunSummary | null
    };
  }
  if (developerSeed.boot === "game_over" && developerSeed.summary) {
    return {
      developerSeed,
      phase: "game_over" as EndlessArcadeViewPhase,
      selectedMode: developerSeed.mode,
      snapshot: developerSeed.summary,
      summary: developerSeed.summary
    };
  }
  return {
    developerSeed,
    phase: "intro" as EndlessArcadeViewPhase,
    selectedMode: developerSeed.mode,
    snapshot: initialSnapshot(developerSeed.mode),
    summary: null as EndlessArcadeRunSummary | null
  };
}

function formatRuntimeError(error: EndlessArcadeRuntimeError | null): string {
  if (!error) return content.states.errorDescription;
  if (error.code === "runtime_unavailable") return content.states.unavailableDescription;
  if (error.code === "boot_timeout") return "玩法启动超时，请重新加载当前模式。";
  return content.states.errorDescription;
}

export function BikeArcadeScene({ state, router, events }: SceneComponentProps) {
  const initialViewStateRef = useRef(createInitialViewState());
  const developerSeedRef = useRef(initialViewStateRef.current.developerSeed);
  const autoStartedDeveloperSeedRef = useRef(false);
  const access = selectFeatureAccess(state);
  const hostRef = useRef<EndlessArcadeGameHostHandle>(null);
  const activeTouchControlsRef = useRef(new Map<number, "left" | "primary" | "right">());
  const activeSpotlightAimPointerRef = useRef<number | null>(null);
  const phaseBeforeConfirmRef = useRef<EndlessArcadeViewPhase>("running");
  const confirmingExitRef = useRef(false);
  const resumeAfterConfirmRef = useRef(false);
  const pausedReasonRef = useRef<string | null>(null);
  const emitClosedOnceRef = useRef(createEndlessArcadeClosedEmitter(events));
  const lifecycleEpochRef = useRef(0);
  const [phase, setPhase] = useState<EndlessArcadeViewPhase>(initialViewStateRef.current.phase);
  const [selectedMode, setSelectedMode] = useState<EndlessChallengeModeId | null>(initialViewStateRef.current.selectedMode);
  const [spotlightAim, setSpotlightAim] = useState(0.5);
  const [runKey, setRunKey] = useState(0);
  const activeRunRef = useRef<EndlessArcadeRunTicket | null>(null);
  const [runTicket, setRunTicket] = useState<EndlessArcadeRunTicket | null>(null);
  const [snapshot, setSnapshot] = useState<EndlessArcadeRunSnapshot | null>(initialViewStateRef.current.snapshot);
  const [summary, setSummary] = useState<EndlessArcadeRunSummary | null>(initialViewStateRef.current.summary);
  const [runtimeError, setRuntimeError] = useState<EndlessArcadeRuntimeError | null>(null);
  const unlocked = access.endlessChallenge;
  const suppressSharedBars = ["loading", "running", "paused", "confirm_exit"].includes(phase);

  useEffect(() => {
    events.emit("endless_arcade_shell_suppression_changed", { active: suppressSharedBars });
    return () => {
      events.emit("endless_arcade_shell_suppression_changed", { active: false });
    };
  }, [events, suppressSharedBars]);

  useEffect(() => {
    const epoch = beginEndlessArcadeLifecycleEpoch(lifecycleEpochRef);
    return () => {
      queueMicrotask(() => {
        if (!isCurrentEndlessArcadeLifecycleEpoch(lifecycleEpochRef, epoch)) return;
        emitClosedOnceRef.current();
        const activeRun = activeRunRef.current;
        if (activeRun) kit.endlessArcade.cancelAttempt(activeRun.runId);
      });
    };
  }, []);

  useEffect(() => {
    const handlePointerUp = (event: PointerEvent) => {
      releaseTouchPointer(event.pointerId);
      if (activeSpotlightAimPointerRef.current === event.pointerId) {
        activeSpotlightAimPointerRef.current = null;
      }
    };
    const handlePointerCancel = () => releaseAllTouchInputsNeutral();
    const handleLifecycleRelease = () => releaseAllTouchInputsNeutral();
    const handleVisibilityChange = () => {
      if (document.hidden) releaseAllTouchInputsNeutral();
    };
    window.addEventListener("pointerup", handlePointerUp);
    window.addEventListener("pointercancel", handlePointerCancel);
    window.addEventListener("blur", handleLifecycleRelease);
    window.addEventListener("pagehide", handleLifecycleRelease);
    document.addEventListener("visibilitychange", handleVisibilityChange);
    return () => {
      window.removeEventListener("pointerup", handlePointerUp);
      window.removeEventListener("pointercancel", handlePointerCancel);
      window.removeEventListener("blur", handleLifecycleRelease);
      window.removeEventListener("pagehide", handleLifecycleRelease);
      document.removeEventListener("visibilitychange", handleVisibilityChange);
      releaseAllTouchInputsNeutral();
    };
  }, []);

  useEffect(() => {
    if (!unlocked) return;
    const developerSeed = developerSeedRef.current;
    if (
      !developerSeed
      || developerSeed.boot !== "running"
      || developerSeed.mode === null
      || autoStartedDeveloperSeedRef.current
      || selectedMode !== developerSeed.mode
      || phase !== "intro"
    ) {
      return;
    }
    autoStartedDeveloperSeedRef.current = true;
    startSelectedMode();
  }, [phase, selectedMode, unlocked]);

  useEffect(() => {
    if (!selectedMode) return;
    if (phase === "paused") {
      emitEndlessArcadePauseEvent(events, selectedMode, pausedReasonRef.current ?? "runtime_paused");
    }
  }, [events, phase, selectedMode]);

  useEffect(() => {
    setEndlessArcadeDebugSnapshot({
      unlocked,
      phase,
      selectedMode,
      activeRunId: activeRunRef.current?.runId ?? null,
      activeAttempt: activeRunRef.current?.attempt ?? null,
      snapshot,
      summary
    });
    return () => {
      clearEndlessArcadeDebugSnapshot();
    };
  }, [phase, selectedMode, snapshot, summary, unlocked]);

  const returnPhoneHome = useCallback(() => {
    emitClosedOnceRef.current();
    router.goTo("phone_home");
  }, [router]);

  function returnHub(): void {
    releaseAllTouchInputsNeutral();
    const activeRun = activeRunRef.current;
    if (activeRun) kit.endlessArcade.cancelAttempt(activeRun.runId);
    activeRunRef.current = null;
    hostRef.current?.destroy();
    confirmingExitRef.current = false;
    resumeAfterConfirmRef.current = false;
    setSelectedMode(null);
    setRunTicket(null);
    setSnapshot(null);
    setSummary(null);
    setRuntimeError(null);
    setPhase("hub");
    events.emit("endless_arcade_hub_returned");
  }

  function chooseMode(mode: EndlessChallengeModeId): void {
    setSelectedMode(mode);
    setSpotlightAim(0.5);
    setSnapshot(initialSnapshot(mode));
    setSummary(null);
    setRuntimeError(null);
    setPhase("intro");
    events.emit("endless_arcade_mode_selected", { mode });
  }

  function startSelectedMode(): void {
    if (!selectedMode || !unlocked) return;
    releaseAllTouchInputsNeutral();
    const priorRun = activeRunRef.current;
    if (priorRun) kit.endlessArcade.cancelAttempt(priorRun.runId);
    const ticket = kit.endlessArcade.startAttempt(selectedMode);
    if (!ticket) {
      enterRuntimeError(
        selectedMode,
        new EndlessArcadeRuntimeError("boot_failed", selectedMode, "无法启动当前挑战记录")
      );
      return;
    }
    activeRunRef.current = ticket;
    if (selectedMode === "spotlight") setSpotlightAim(0.5);
    setRunTicket(ticket);
    confirmingExitRef.current = false;
    resumeAfterConfirmRef.current = false;
    setSnapshot(initialSnapshot(selectedMode));
    setSummary(null);
    setRuntimeError(null);
    setPhase("loading");
    setRunKey((current) => current + 1);
    events.emit("endless_arcade_runtime_requested", { mode: selectedMode });
  }

  function requestActiveExit(): void {
    if (phase === "loading") {
      returnHub();
      return;
    }
    if (["running", "paused"].includes(phase)) {
      releaseAllTouchInputsNeutral();
      phaseBeforeConfirmRef.current = phase;
      confirmingExitRef.current = true;
      if (emitEndlessArcadeConfirmExitPause(events, phase, selectedMode)) {
        pausedReasonRef.current = "player";
      }
      hostRef.current?.pause("player");
      setPhase("confirm_exit");
      return;
    }
    returnHub();
  }

  function keepPlaying(): void {
    const previous = phaseBeforeConfirmRef.current;
    confirmingExitRef.current = false;
    if (previous === "running" || previous === "paused") {
      resumeAfterConfirmRef.current = true;
      hostRef.current?.resume();
      return;
    }
    setPhase(previous);
  }

  function confirmExit(): void {
    confirmingExitRef.current = false;
    resumeAfterConfirmRef.current = false;
    returnHub();
  }

  const enterRuntimeError = useCallback((mode: EndlessChallengeModeId, error: EndlessArcadeRuntimeError) => {
    resumeAfterConfirmRef.current = false;
    emitEndlessArcadeRuntimeErrorPause(events, mode);
    setRuntimeError(error);
    setPhase("error");
  }, [events]);

  const handleHostStatus = useCallback((status: EndlessArcadeHostStatus) => {
    if (confirmingExitRef.current) return;
    if (status.kind === "loading") {
      setPhase("loading");
      return;
    }
    if (status.kind === "running") {
      const pendingResume = resumeAfterConfirmRef.current;
      const resumeTransition = consumePendingEndlessArcadeResume(pendingResume, status.kind);
      resumeAfterConfirmRef.current = resumeTransition.pending;
      pausedReasonRef.current = null;
      if (selectedMode && (phase === "paused" || resumeTransition.shouldEmit)) {
        events.emit("endless_arcade_runtime_resumed", { mode: selectedMode });
      }
      setPhase("running");
      return;
    }
    if (status.kind === "paused") {
      releaseAllTouchInputsNeutral();
      const resumeTransition = consumePendingEndlessArcadeResume(resumeAfterConfirmRef.current, status.kind);
      resumeAfterConfirmRef.current = resumeTransition.pending;
      pausedReasonRef.current = status.reason;
      setPhase("paused");
      return;
    }
    if (status.kind === "game_over") {
      releaseAllTouchInputsNeutral();
      const ticket = activeRunRef.current;
      if (!ticket) {
        enterRuntimeError(
          status.summary.mode,
          new EndlessArcadeRuntimeError("boot_failed", status.summary.mode, "挑战结算票据已失效")
        );
        return;
      }
      const settled = kit.endlessArcade.settleAttempt({
        runId: ticket.runId,
        mode: status.summary.mode,
        score: status.summary.score,
        progress: status.summary.progress,
        tier: status.summary.tier,
        combo: status.summary.combo,
        durationMs: status.summary.durationMs
      });
      if (!settled) {
        enterRuntimeError(
          status.summary.mode,
          new EndlessArcadeRuntimeError("boot_failed", status.summary.mode, "挑战结算数据无效")
        );
        return;
      }
      resumeAfterConfirmRef.current = false;
      activeRunRef.current = null;
      setSummary(status.summary);
      setSnapshot(status.summary);
      setPhase("game_over");
      events.emit("endless_arcade_runtime_finished", {
        mode: status.summary.mode,
        score: status.summary.score,
        progress: status.summary.progress,
        tier: status.summary.tier,
        combo: status.summary.combo,
        durationMs: status.summary.durationMs
      });
      return;
    }
    enterRuntimeError(selectedMode ?? status.error.mode, status.error);
  }, [enterRuntimeError, events, phase, selectedMode]);

  function resumeRun(): void {
    hostRef.current?.resume();
  }

  function sendTouchControl(action: EndlessArcadeControlAction): void {
    hostRef.current?.sendControl(action);
  }

  function releaseTouchControl(action: "left" | "primary" | "right"): void {
    const releaseAction: Record<typeof action, EndlessArcadeControlAction> = {
      left: "release_left",
      primary: "release_primary",
      right: "release_right",
    };
    hostRef.current?.sendControl(releaseAction[action]);
  }

  function trySetPointerCapture(target: HTMLElement, pointerId: number): void {
    try {
      if (typeof target.setPointerCapture === "function") target.setPointerCapture(pointerId);
    } catch {
      // Pointer capture is an enhancement; global pointer listeners retain the release contract.
    }
  }

  function tryReleasePointerCapture(target: HTMLElement, pointerId: number): void {
    try {
      if (
        typeof target.hasPointerCapture === "function"
        && typeof target.releasePointerCapture === "function"
        && target.hasPointerCapture(pointerId)
      ) {
        target.releasePointerCapture(pointerId);
      }
    } catch {
      // A detached or cancelled pointer may already have released capture.
    }
  }

  function releaseTouchPointer(pointerId: number): void {
    const action = activeTouchControlsRef.current.get(pointerId);
    if (!action) return;
    activeTouchControlsRef.current.delete(pointerId);
    const actionStillHeld = [...activeTouchControlsRef.current.values()].includes(action);
    if (!actionStillHeld) releaseTouchControl(action);
  }

  function releaseAllTouchInputsNeutral(): void {
    activeTouchControlsRef.current.clear();
    activeSpotlightAimPointerRef.current = null;
    hostRef.current?.releaseControls();
  }

  function beginTouchControl(
    action: "left" | "primary" | "right",
    event: ReactPointerEvent<HTMLButtonElement>,
  ): void {
    const alreadyHeld = [...activeTouchControlsRef.current.values()].includes(action);
    activeTouchControlsRef.current.set(event.pointerId, action);
    trySetPointerCapture(event.currentTarget, event.pointerId);
    if (!alreadyHeld) sendTouchControl(action);
  }

  function endTouchControl(
    action: "left" | "primary" | "right",
    event: ReactPointerEvent<HTMLButtonElement>,
  ): void {
    if (activeTouchControlsRef.current.get(event.pointerId) === action) {
      releaseTouchPointer(event.pointerId);
    }
    tryReleasePointerCapture(event.currentTarget, event.pointerId);
  }

  function cancelTouchControl(event: ReactPointerEvent<HTMLButtonElement>): void {
    activeTouchControlsRef.current.delete(event.pointerId);
    tryReleasePointerCapture(event.currentTarget, event.pointerId);
    releaseAllTouchInputsNeutral();
  }

  function getFishingTouchControlLabel(action: "left" | "primary" | "right"): string {
    return action === "left" ? "左收 J" : action === "primary" ? "起钩 K" : "右收 L";
  }

  function applySpotlightAim(nextAim: number): void {
    const clampedAim = Math.min(1, Math.max(0, nextAim));
    setSpotlightAim(clampedAim);
    hostRef.current?.setAim(clampedAim);
  }

  function updateSpotlightAimFromPointer(event: ReactPointerEvent<HTMLDivElement>): void {
    const bounds = event.currentTarget.getBoundingClientRect();
    if (bounds.width <= 0) return;
    applySpotlightAim((event.clientX - bounds.left) / bounds.width);
  }

  function beginSpotlightAim(event: ReactPointerEvent<HTMLDivElement>): void {
    activeSpotlightAimPointerRef.current = event.pointerId;
    trySetPointerCapture(event.currentTarget, event.pointerId);
    updateSpotlightAimFromPointer(event);
  }

  function moveSpotlightAim(event: ReactPointerEvent<HTMLDivElement>): void {
    if (activeSpotlightAimPointerRef.current !== event.pointerId) return;
    updateSpotlightAimFromPointer(event);
  }

  function endSpotlightAim(event: ReactPointerEvent<HTMLDivElement>): void {
    if (activeSpotlightAimPointerRef.current === event.pointerId) {
      activeSpotlightAimPointerRef.current = null;
    }
    tryReleasePointerCapture(event.currentTarget, event.pointerId);
  }

  function handleSpotlightAimKey(event: ReactKeyboardEvent<HTMLDivElement>): void {
    if (!["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) return;
    event.preventDefault();
    if (event.key === "Home") applySpotlightAim(0);
    else if (event.key === "End") applySpotlightAim(1);
    else applySpotlightAim(spotlightAim + (event.key === "ArrowLeft" ? -0.05 : 0.05));
  }

  if (!unlocked) {
    return (
      <PhoneAppScaffold
        className="endless-arcade-app is-locked"
        contentMode="fixed"
        label={content.lockedTitle}
        header={(
          <PhoneAppHeader
            eyebrow={content.brand}
            title={content.title}
            navigation={{ kind: "exit", label: content.actions.backHome, onClick: returnPhoneHome }}
          />
        )}
      >
        <PhoneStateView
          kind="empty"
          icon={<span className="endless-arcade-lock-icon">7:55</span>}
          title={content.lockedTitle}
          description={content.lockedDescription}
          primaryAction={<button type="button" onClick={returnPhoneHome}>{content.actions.backHome}</button>}
        />
      </PhoneAppScaffold>
    );
  }

  const definition = selectedMode ? getEndlessChallengeDefinition(selectedMode) : null;
  const runtimeShellVisible = selectedMode !== null && [
    "loading",
    "running",
    "paused",
    "confirm_exit",
    "game_over",
    "error"
  ].includes(phase);
  const hostMounted = runtimeShellVisible && runTicket !== null;
  const headerBack = phase === "hub" ? returnPhoneHome : requestActiveExit;
  const headerBackLabel = phase === "hub" ? content.actions.backHome : content.actions.backHub;

  return (
    <PhoneAppScaffold
      className={`endless-arcade-app phase-${phase}`}
      contentClassName="endless-arcade-content"
      contentMode={phase === "hub" ? "scroll" : "fixed"}
      label={content.title}
      header={(
        <PhoneAppHeader
          eyebrow={content.brand}
          title={phase === "hub" ? content.title : definition?.title ?? content.title}
          navigation={{ kind: phase === "hub" ? "exit" : "back", label: headerBackLabel, onClick: headerBack }}
          end={<span className="endless-arcade-phase-label">{phase.replace("_", " ").toUpperCase()}</span>}
        />
      )}
    >
      {phase === "hub" ? (
        <section className="endless-arcade-hub" data-endless-view="hub">
          <header className="endless-arcade-hub-intro">
            <span aria-hidden="true">07:55</span>
            <p>{content.tagline}</p>
          </header>
          <div className="endless-arcade-mode-list">
            {ENDLESS_CHALLENGE_MODE_IDS.map((mode) => {
              const modeDefinition = getEndlessChallengeDefinition(mode);
              const record = state.endlessArcade.records[mode];
              return (
                <article key={mode} className={`endless-arcade-mode-card is-${modeDefinition.accent}`}>
                  <span className="endless-arcade-mode-mark" aria-hidden="true"><i /><i /><i /></span>
                  <div>
                    <h2>{modeDefinition.title}</h2>
                    <p>{modeDefinition.shortRule}</p>
                    <small>{modeDefinition.input}</small>
                  </div>
                  <strong>{modeDefinition.formatRecord(record)}</strong>
                  <button type="button" onClick={() => chooseMode(mode)}>查看玩法</button>
                </article>
              );
            })}
          </div>
          <p className="endless-arcade-local-note">{content.localRecordNotice}</p>
        </section>
      ) : null}

      {phase === "intro" && definition && selectedMode ? (
        <section className={`endless-arcade-intro is-${definition.accent}`} data-endless-view="intro">
          <span className="endless-arcade-intro-clock">07:55</span>
          <div className="endless-arcade-intro-pattern" aria-hidden="true"><i /><i /><i /><i /></div>
          <h2>{definition.title}</h2>
          <p>{definition.shortRule}</p>
          <small>{definition.input}</small>
          <strong>最佳：{definition.formatRecord(state.endlessArcade.records[selectedMode])}</strong>
          <button type="button" onClick={startSelectedMode}>{content.actions.start}</button>
          <button type="button" className="is-secondary" onClick={returnHub}>{content.actions.backHub}</button>
        </section>
      ) : null}

      {runtimeShellVisible && selectedMode && definition ? (
        <section className="endless-arcade-runtime" data-endless-view={phase}>
          <header className="endless-arcade-runtime-hud">
            <span><small>分数</small><strong>{snapshot?.score.toLocaleString("zh-CN") ?? "0"}</strong></span>
            <span><small>{definition.progressUnit}</small><strong>{snapshot?.progress.toLocaleString("zh-CN") ?? "0"}</strong></span>
            <span><small>层级</small><strong>{snapshot?.tier ?? 1}</strong></span>
            <span><small>连击</small><strong>{snapshot?.combo ?? 0}</strong></span>
          </header>
          <div className="endless-arcade-runtime-stage" aria-busy={phase === "loading"}>
            {hostMounted ? (
              <EndlessArcadeGameHost
                ref={hostRef}
                mode={selectedMode}
                run={runTicket}
                runKey={runKey}
                externalPause={state.ui.controlCenterOpen}
                onStatusChange={handleHostStatus}
                onSnapshot={setSnapshot}
              />
            ) : null}
            {phase === "loading" ? (
              <PhoneStateView
                kind="loading"
                className="endless-arcade-overlay"
                title={content.states.loadingTitle}
                description={content.states.loadingDescription}
              />
            ) : null}
            {phase === "paused" ? (
              <PhoneStateView
                kind="empty"
                className="endless-arcade-overlay"
                title={content.states.pausedTitle}
                description={content.states.pausedDescription}
                primaryAction={<button type="button" onClick={resumeRun}>{content.actions.resume}</button>}
                secondaryAction={<button type="button" onClick={requestActiveExit}>{content.actions.exitRun}</button>}
              />
            ) : null}
            {phase === "error" ? (
              <PhoneStateView
                kind="error"
                className="endless-arcade-overlay"
                title={content.states.errorTitle}
                description={formatRuntimeError(runtimeError)}
                primaryAction={<button type="button" onClick={startSelectedMode}>{content.actions.retryLoad}</button>}
                secondaryAction={<button type="button" onClick={returnHub}>{content.actions.backHub}</button>}
              />
            ) : null}
            {phase === "game_over" && summary ? (
              <section className="endless-arcade-result" role="dialog" aria-modal="true" aria-label={content.states.gameOverTitle}>
                <span>{content.states.gameOverTitle}</span>
                <h2>{summary.score.toLocaleString("zh-CN")} 分</h2>
                <p>{summary.progress.toLocaleString("zh-CN")} {definition.progressUnit} · 层级 {summary.tier} · 连击 {summary.combo}</p>
                <small>{content.states.gameOverDescription}</small>
                <button type="button" onClick={startSelectedMode}>{content.actions.retry}</button>
                <button type="button" className="is-secondary" onClick={returnHub}>{content.actions.backHub}</button>
                <button type="button" className="is-secondary" onClick={returnPhoneHome}>{content.actions.backHome}</button>
              </section>
            ) : null}
          </div>
          {phase === "running" && selectedMode === "spotlight" ? (
            <nav className="endless-arcade-touch-controls endless-arcade-spotlight-controls" aria-label="灯光追逐触屏操作">
              <div className="endless-arcade-aim-control">
                <span>光束位置</span>
                <div
                  className="endless-arcade-aim-track"
                  role="slider"
                  tabIndex={0}
                  aria-label="光束横向位置"
                  aria-valuemin={0}
                  aria-valuemax={100}
                  aria-valuenow={Math.round(spotlightAim * 100)}
                  onKeyDown={handleSpotlightAimKey}
                  onPointerDown={beginSpotlightAim}
                  onPointerMove={moveSpotlightAim}
                  onPointerUp={endSpotlightAim}
                  onPointerCancel={endSpotlightAim}
                  onLostPointerCapture={endSpotlightAim}
                >
                  <i style={{ left: `${spotlightAim * 100}%` }} />
                </div>
              </div>
              <button
                type="button"
                className="endless-arcade-beam-button"
                onPointerDown={(event) => beginTouchControl("primary", event)}
                onPointerUp={(event) => endTouchControl("primary", event)}
                onPointerCancel={cancelTouchControl}
                onLostPointerCapture={cancelTouchControl}
                onPointerLeave={(event) => endTouchControl("primary", event)}
              >按住照射</button>
            </nav>
          ) : phase === "running" && selectedMode === "bike" ? (
          <nav className="endless-arcade-touch-controls is-bike" aria-label="755 米骑行触屏操作">
            <button
              type="button"
              onPointerDown={(event) => beginTouchControl("left", event)}
              onPointerUp={(event) => endTouchControl("left", event)}
              onPointerCancel={cancelTouchControl}
              onLostPointerCapture={cancelTouchControl}
              onPointerLeave={(event) => endTouchControl("left", event)}
            >左车道</button>
            <button
              type="button"
              onPointerDown={(event) => beginTouchControl("right", event)}
              onPointerUp={(event) => endTouchControl("right", event)}
              onPointerCancel={cancelTouchControl}
              onLostPointerCapture={cancelTouchControl}
              onPointerLeave={(event) => endTouchControl("right", event)}
            >右车道</button>
          </nav>
          ) : phase === "running" && selectedMode === "fishing" ? (
            <nav className="endless-arcade-touch-controls" aria-label={`${definition.title}触屏操作`}>
              {(["left", "primary", "right"] as const).map((action) => (
                <button
                  key={action}
                  type="button"
                  onPointerDown={(event) => beginTouchControl(action, event)}
                  onPointerUp={(event) => endTouchControl(action, event)}
                  onPointerCancel={cancelTouchControl}
                  onLostPointerCapture={cancelTouchControl}
                  onPointerLeave={(event) => endTouchControl(action, event)}
                >{getFishingTouchControlLabel(action)}</button>
              ))}
            </nav>
          ) : null}
        </section>
      ) : null}

      {phase === "confirm_exit" ? (
        <PhoneActionSheet
          title={content.states.exitTitle}
          description={content.states.exitDescription}
          onClose={keepPlaying}
        >
          <div className="endless-arcade-exit-actions">
            <button type="button" data-phone-autofocus onClick={keepPlaying}>{content.actions.keepPlaying}</button>
            <button type="button" className="is-danger" onClick={confirmExit}>{content.actions.confirmExit}</button>
          </div>
        </PhoneActionSheet>
      ) : null}
    </PhoneAppScaffold>
  );
}
