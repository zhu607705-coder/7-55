import { useEffect, useRef, useState } from "react";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import actOneContent from "../../../data/act-one-bootstrap.content.json";
import { kit } from "../../../modules/GameKit";

type EndingPhase = "blackout" | "chase" | "caught" | "burst" | "whiteout";

const HOLD_TO_CATCH_MS = 900;

const DIALOGUE = [
  { speaker: "narrator", text: actOneContent.audioNarration.prologue_narrator_caught.subtitleZh },
  { speaker: "player", text: "不，除非你帮助我" },
  { speaker: "player", text: "不然你就和我的绩点同归于尽吧" },
  { speaker: "narrator", text: actOneContent.audioNarration.prologue_narrator_bargain.subtitleZh }
] as const;

/** P12 序章结算：7 秒黑屏后抓住试图离场的旁白，强制开启第二章入口。 */
export function EndingScene({ events }: SceneComponentProps) {
  const [phase, setPhase] = useState<EndingPhase>("blackout");
  const [held, setHeld] = useState(false);
  const [dialogueStep, setDialogueStep] = useState(0);
  const holdTimerRef = useRef<number | null>(null);
  const capturedRef = useRef(false);

  useEffect(() => {
    events.emit("ending_started");
    events.emit("prologue_blackout_started", { durationMs: 7000 });
    const timer = window.setTimeout(() => {
      setPhase("chase");
      events.emit("prologue_narrator_intro");
    }, 7000);
    return () => window.clearTimeout(timer);
  }, [events]);

  useEffect(() => {
    if (phase !== "caught") {
      return undefined;
    }
    const timers = [
      window.setTimeout(() => setDialogueStep(1), 2500),
      window.setTimeout(() => setDialogueStep(2), 4300),
      window.setTimeout(() => {
        setDialogueStep(3);
        events.emit("prologue_narrator_bargain");
      }, 6100),
      window.setTimeout(() => {
        setPhase("burst");
        events.emit("prologue_white_burst");
      }, 14000)
    ];
    return () => timers.forEach((timer) => window.clearTimeout(timer));
  }, [events, phase]);

  useEffect(() => {
    if (phase === "burst") {
      const timer = window.setTimeout(() => setPhase("whiteout"), 950);
      return () => window.clearTimeout(timer);
    }
    if (phase === "whiteout") {
      const timer = window.setTimeout(() => kit.actOne.completeNarratorIntervention(), 700);
      return () => window.clearTimeout(timer);
    }
    return undefined;
  }, [phase]);

  useEffect(() => {
    return () => {
      if (holdTimerRef.current !== null) {
        window.clearTimeout(holdTimerRef.current);
      }
    };
  }, []);

  function beginHold(event: React.PointerEvent<HTMLButtonElement>) {
    if (phase !== "chase" || capturedRef.current) {
      return;
    }
    try {
      event.currentTarget.setPointerCapture?.(event.pointerId);
    } catch {
      // Synthetic pointers and older browsers may not expose capture.
    }
    setHeld(true);
    holdTimerRef.current = window.setTimeout(() => {
      capturedRef.current = true;
      holdTimerRef.current = null;
      setHeld(true);
      setDialogueStep(0);
      setPhase("caught");
      events.emit("prologue_narrator_caught");
    }, HOLD_TO_CATCH_MS);
  }

  function releaseHold() {
    if (capturedRef.current) {
      return;
    }
    if (holdTimerRef.current !== null) {
      window.clearTimeout(holdTimerRef.current);
      holdTimerRef.current = null;
    }
    setHeld(false);
  }

  const dialogue = phase === "caught" ? DIALOGUE[dialogueStep] : null;

  return (
    <section className={`ending-scene ending-${phase}`} aria-label="序章结算">
      {phase === "blackout" ? <div className="ending-seven-second-blackout" aria-label="黑屏" /> : null}

      {phase === "chase" || phase === "caught" ? (
        <>
          <button
            type="button"
            className={`narrator-orb ${held ? "is-held" : ""} ${phase === "caught" ? "is-caught" : ""}`}
            aria-label="按住旁白圆圈"
            onPointerDown={beginHold}
            onPointerUp={releaseHold}
            onPointerCancel={releaseHold}
            onLostPointerCapture={releaseHold}
          >
            <span aria-hidden="true" />
            <strong>旁白</strong>
          </button>

          {phase === "chase" ? (
            <>
              <p className="narrator-intro-line">
                {actOneContent.audioNarration.prologue_narrator_intro.subtitleZh}
              </p>
              <p className="stop-narrator-prompt" role="status">制止它</p>
            </>
          ) : null}

          {dialogue ? (
            <p className={`ending-dialogue is-${dialogue.speaker}`} aria-live="polite">
              <small>{dialogue.speaker === "narrator" ? "旁白" : "我"}</small>
              {dialogue.text}
            </p>
          ) : null}
        </>
      ) : null}

      {phase === "burst" ? <div className="ending-white-burst" aria-hidden="true"><i /><i /><i /></div> : null}
      {phase === "whiteout" ? <div className="ending-whiteout" aria-label="白屏闪退" /> : null}
    </section>
  );
}
