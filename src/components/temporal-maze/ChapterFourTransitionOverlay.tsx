import { useCallback, useEffect, useRef } from "react";
import type { ChapterFourTransitionPresentationPlan } from "../../modules/ChapterFourTransitionPresentation";

interface ChapterFourTransitionOverlayProps {
  sessionId: string;
  plan: ChapterFourTransitionPresentationPlan;
  onComplete: (sessionId: string) => void;
}

export function ChapterFourTransitionOverlay({
  sessionId,
  plan,
  onComplete
}: ChapterFourTransitionOverlayProps) {
  const rootRef = useRef<HTMLDivElement | null>(null);
  const completionRef = useRef(false);

  const finish = useCallback(() => {
    if (completionRef.current) return;
    completionRef.current = true;
    onComplete(sessionId);
  }, [onComplete, sessionId]);

  useEffect(() => {
    completionRef.current = false;
    rootRef.current?.focus({ preventScroll: true });
  }, [sessionId]);

  return (
    <div
      ref={rootRef}
      className="chapter4-transition-overlay is-time-shift"
      role="dialog"
      aria-modal="true"
      aria-labelledby="chapter4-transition-title"
      tabIndex={-1}
      data-transition-session={sessionId}
      data-transition-id={plan.id}
      data-transition-step="time_shift"
      data-transition-surface="rpg-shell"
      data-transition-from-phase={plan.fromPhase}
      data-transition-to-phase={plan.toPhase}
      onKeyDown={(event) => {
        if (event.key !== " " && event.key !== "Enter") return;
        if (event.target instanceof HTMLButtonElement) return;
        event.preventDefault();
        finish();
      }}
    >
      <section className="chapter4-transition-overlay__panel is-change-card kind-time">
        <small>{plan.change.eyebrow}</small>
        <h2 id="chapter4-transition-title">{plan.change.title}</h2>
        <p>{plan.change.detail}</p>
      </section>

      <nav className="chapter4-transition-overlay__actions" aria-label="时间切换操作">
        <button type="button" className="is-primary" onClick={finish}>
          继续行动
        </button>
      </nav>
    </div>
  );
}
