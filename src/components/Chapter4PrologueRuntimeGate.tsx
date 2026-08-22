import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  useSyncExternalStore,
  type ReactNode
} from "react";
import type { EventBus } from "../core/EventBus";
import type { GameState, GameStore } from "../core/types";
import { ChapterFourTemporalMazeController } from "../modules/ChapterFourTemporalMazeController";
import { getDeveloperChapter4PrologueOffset } from "../modules/DeveloperChannel";
import { Chapter4PrologueOverlay } from "../scenes/rpg/Chapter4PrologueOverlay";
import { PROLOGUE_TASK_CARD_AT } from "../scenes/rpg/chapter4-prologue/PrologueTimeline";
import { preloadRpgGameHost } from "../scenes/rpg/RpgRuntimePreload";

type HandoffStatus = "idle" | "pending" | "waiting_ready" | "failed" | "ready";

interface Chapter4PrologueRuntimeGateProps {
  store: GameStore;
  events: EventBus;
  embedded?: boolean;
  children: ReactNode;
}

const HANDOFF_TIMEOUT_MS = 20_000;
const Chapter4PrologueGateBlockedContext = createContext(false);

function isOpeningHandoffCommitted(state: GameState): boolean {
  return state.chapter4.prologueSeen
    && state.chapter4.phase === "opening_handoff"
    && state.rpgScene === "duan_yongping_temporal_maze";
}

export function useChapter4PrologueGateBlocked(): boolean {
  return useContext(Chapter4PrologueGateBlockedContext);
}

export function Chapter4PrologueRuntimeGate({
  store,
  events,
  embedded = false,
  children
}: Chapter4PrologueRuntimeGateProps) {
  const state = useSyncExternalStore(store.subscribe, store.getState, store.getState);
  const eligible = state.rpgScene === "qizhen_lake"
    && state.qizhenLake.phase === "complete"
    && state.chapterThreeInterlude.phase === "replay_ready"
    && state.chapterThreeInterlude.replayUnlocked
    && !state.chapter4.prologueSeen;
  const resumeOpeningHandoff = isOpeningHandoffCommitted(state);
  const initialResumeRef = useRef(resumeOpeningHandoff);
  const initialElapsedRef = useRef(
    initialResumeRef.current ? PROLOGUE_TASK_CARD_AT : getDeveloperChapter4PrologueOffset()
  );
  const [held, setHeld] = useState(eligible || resumeOpeningHandoff);
  const [requested, setRequested] = useState(false);
  const [status, setStatus] = useState<HandoffStatus>(
    resumeOpeningHandoff ? "waiting_ready" : "idle"
  );
  const [feedback, setFeedback] = useState<string | null>(
    resumeOpeningHandoff ? "正在恢复 A1 现场……" : null
  );
  const contentRef = useRef<HTMLDivElement | null>(null);
  const timeoutRef = useRef<number | null>(null);
  const releaseRef = useRef<number | null>(null);
  const requestSerialRef = useRef(0);
  const requestIdRef = useRef<string | null>(null);
  const activeRef = useRef(eligible || resumeOpeningHandoff);
  const controller = useMemo(
    () => new ChapterFourTemporalMazeController(store, events),
    [events, store]
  );

  const createRequestId = useCallback(() => {
    requestSerialRef.current += 1;
    return `app-prologue-${Date.now()}-${requestSerialRef.current}`;
  }, []);

  const clearTimeoutGuard = useCallback(() => {
    if (timeoutRef.current === null) return;
    window.clearTimeout(timeoutRef.current);
    timeoutRef.current = null;
  }, []);

  const armTimeoutGuard = useCallback((requestId: string) => {
    clearTimeoutGuard();
    timeoutRef.current = window.setTimeout(() => {
      if (requestIdRef.current !== requestId) return;
      timeoutRef.current = null;
      setStatus("failed");
      setFeedback("A1 现场未在时限内完成应用。可用同一按钮重试同步。");
    }, HANDOFF_TIMEOUT_MS);
  }, [clearTimeoutGuard]);

  useEffect(() => {
    if (!eligible || resumeOpeningHandoff) return;
    if (!requestIdRef.current) requestIdRef.current = createRequestId();
    setHeld(true);
    setStatus("idle");
    setFeedback(null);
    void preloadRpgGameHost();
  }, [createRequestId, eligible, resumeOpeningHandoff]);

  useEffect(() => {
    if (!resumeOpeningHandoff || !initialResumeRef.current) return;
    const requestId = requestIdRef.current ?? createRequestId();
    requestIdRef.current = requestId;
    setHeld(true);
    setStatus("waiting_ready");
    setFeedback("正在恢复 A1 现场……");
    armTimeoutGuard(requestId);
    void preloadRpgGameHost();
  }, [armTimeoutGuard, createRequestId, resumeOpeningHandoff]);

  useEffect(() => events.subscribe((event) => {
    if (event.name !== "chapter35_recovered_replay_gate_requested"
      || event.payload?.destinationId !== "duan_yongping_a1") return;
    requestIdRef.current = createRequestId();
    setRequested(true);
    setHeld(true);
    setStatus("idle");
    setFeedback(null);
    void preloadRpgGameHost();
  }), [createRequestId, events]);

  useEffect(() => events.subscribe((event) => {
    if (event.name !== "rpg_chapter4_755_live_ready") return;
    const current = store.getState();
    if (!activeRef.current || !isOpeningHandoffCommitted(current)) return;
    const appliedPlateId = String(event.payload?.appliedPlateId ?? "");
    const phase = String(event.payload?.phase ?? "");
    if (phase !== "opening_handoff"
      || appliedPlateId !== "a1_2245_opening"
      || event.payload?.contractReady !== true) return;

    const expectedRequestId = requestIdRef.current;
    const receivedRequestId = typeof event.payload?.requestId === "string"
      ? event.payload.requestId
      : "";
    if (!expectedRequestId) return;
    if (receivedRequestId !== expectedRequestId) {
      if (!receivedRequestId) {
        events.emit("rpg_chapter4_755_live_ready_retry_requested", {
          requestId: expectedRequestId
        });
      }
      return;
    }

    clearTimeoutGuard();
    setStatus("ready");
    setFeedback("A1 现场已完成应用。");
    if (releaseRef.current !== null) window.clearTimeout(releaseRef.current);
    releaseRef.current = window.setTimeout(() => {
      releaseRef.current = null;
      requestIdRef.current = null;
      setRequested(false);
      setHeld(false);
      events.emit("rpg_chapter4_755_handoff_released", {
        requestId: expectedRequestId,
        appliedPlateId
      });
    }, 80);
  }), [clearTimeoutGuard, events, store]);

  useEffect(() => {
    if (!activeRef.current || status !== "waiting_ready") return;
    const requestId = requestIdRef.current;
    if (!requestId) return;
    const requestLiveReady = () => {
      if (requestIdRef.current !== requestId) return;
      events.emit("rpg_chapter4_755_live_ready_retry_requested", { requestId });
    };
    const initialPulse = window.setTimeout(requestLiveReady, 250);
    const retryPulse = window.setInterval(requestLiveReady, 1000);
    return () => {
      window.clearTimeout(initialPulse);
      window.clearInterval(retryPulse);
    };
  }, [events, status]);

  useEffect(() => () => {
    clearTimeoutGuard();
    if (releaseRef.current !== null) {
      window.clearTimeout(releaseRef.current);
      releaseRef.current = null;
    }
    requestIdRef.current = null;
  }, [clearTimeoutGuard]);

  const completePrologue = useCallback(() => {
    if (status === "pending" || status === "waiting_ready" || status === "ready") return;
    const current = store.getState();
    if (current.chapter4.prologueSeen) {
      const requestId = createRequestId();
      requestIdRef.current = requestId;
      setStatus("waiting_ready");
      setFeedback("正在重试同步 A1 现场……");
      armTimeoutGuard(requestId);
      events.emit("rpg_chapter4_755_live_ready_retry_requested", { requestId });
      return;
    }

    const requestId = createRequestId();
    requestIdRef.current = requestId;
    setStatus("pending");
    setFeedback("正在提交第四章入口……");
    try {
      const result = controller.resolve755Intent({ type: "complete_prologue_handoff" });
      if (!result.accepted) {
        requestIdRef.current = null;
        setStatus("failed");
        setFeedback("第四章入口被拒绝。可重试。");
        return;
      }
    } catch {
      requestIdRef.current = null;
      setStatus("failed");
      setFeedback("第四章入口提交失败。可重试。");
      return;
    }
    setStatus("waiting_ready");
    setFeedback("入口已写入，正在等待 A1 地图、前景、碰撞和交互点完成应用……");
    armTimeoutGuard(requestId);
  }, [armTimeoutGuard, controller, createRequestId, events, status, store]);

  const active = eligible || requested || held;
  activeRef.current = active;

  useEffect(() => {
    const content = contentRef.current;
    if (!content) return;
    if (active) content.setAttribute("inert", "");
    else content.removeAttribute("inert");
  }, [active]);

  return (
    <Chapter4PrologueGateBlockedContext.Provider value={active}>
      <div
        className={`chapter4-prologue-app-gate${embedded ? " is-embedded" : ""}`}
        data-prologue-gate={active ? status : "inactive"}
      >
        <div
          ref={contentRef}
          className={`chapter4-prologue-app-content${active ? " is-blocked" : ""}`}
          aria-hidden={active ? "true" : undefined}
        >
          {children}
        </div>
        {active ? (
          <main className={`rpg-stage chapter4-prologue-handoff-layer${embedded ? " is-embedded" : ""}`}>
            <section className="rpg-shell" aria-label="第三章半至第四章恢复回放">
              <Chapter4PrologueOverlay
                key={`chapter4-prologue-app-${initialElapsedRef.current}`}
                events={events}
                initialElapsedMs={initialElapsedRef.current}
                handoffStatus={status}
                handoffFeedback={feedback}
                onComplete={completePrologue}
              />
            </section>
          </main>
        ) : null}
      </div>
    </Chapter4PrologueGateBlockedContext.Provider>
  );
}
