import { useCallback, useEffect, useRef } from "react";
import lampCoreUrl from "../../assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_core.png";
import lampDarkUrl from "../../assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_dark.png";
import lampGlowUrl from "../../assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_glow.png";
import lampLedsUrl from "../../assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_leds.png";
import lampOutlineUrl from "../../assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_outline.png";

export const CHAPTER_FOUR_STAR_LAMP_SEQUENCE_DURATION_MS = 6200;

interface ChapterFourStarLampClosureProps {
  sessionId: string;
  feedback?: string | null;
  onComplete: (sessionId: string) => void;
}

export function ChapterFourStarLampClosure({
  sessionId,
  feedback = null,
  onComplete
}: ChapterFourStarLampClosureProps) {
  const completedRef = useRef(false);
  const completeOnce = useCallback(() => {
    if (completedRef.current) return;
    completedRef.current = true;
    onComplete(sessionId);
  }, [onComplete, sessionId]);

  useEffect(() => {
    const fallback = window.setTimeout(
      completeOnce,
      CHAPTER_FOUR_STAR_LAMP_SEQUENCE_DURATION_MS + 900
    );
    return () => window.clearTimeout(fallback);
  }, [completeOnce]);

  return (
    <section
      className="chapter4-star-lamp-closure"
      role="dialog"
      aria-modal="true"
      aria-label="灿若星辰灯点亮"
      data-session-id={sessionId}
    >
      <div
        className="chapter4-star-lamp-closure__camera"
        onAnimationEnd={(event) => {
          if (event.currentTarget === event.target
            && event.animationName === "chapter4-star-lamp-camera") {
            completeOnce();
          }
        }}
      >
        <img className="chapter4-star-lamp-closure__layer is-dark" src={lampDarkUrl} alt="" />
        <img className="chapter4-star-lamp-closure__layer is-outline" src={lampOutlineUrl} alt="" />
        <img className="chapter4-star-lamp-closure__layer is-glow" src={lampGlowUrl} alt="" />
        <img className="chapter4-star-lamp-closure__layer is-core" src={lampCoreUrl} alt="" />
        <img className="chapter4-star-lamp-closure__layer is-leds" src={lampLedsUrl} alt="" />
        <div className="chapter4-star-lamp-closure__flare" aria-hidden="true" />
      </div>
      <div className="chapter4-star-lamp-closure__vignette" aria-hidden="true" />
      <div className="chapter4-star-lamp-closure__blackout" aria-hidden="true" />
      <footer className="chapter4-star-lamp-closure__caption">
        <strong>07:55</strong>
        <span>灿若星辰</span>
        {feedback ? <small role="status">{feedback}</small> : null}
      </footer>
    </section>
  );
}
