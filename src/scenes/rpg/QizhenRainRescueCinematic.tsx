import { useCallback, useEffect, useRef, useState } from "react";
import { useMediaQuery } from "../../components/useMediaQuery";
import rescueVideoUrl from "../../assets/rpg/cinematics/qizhen-rain-rescue/qizhen_rain_rescue_hailuo23_v01.mp4?url";

export type QizhenRainRescueCinematicResult = "video" | "fallback" | "skipped";

interface QizhenRainRescueCinematicProps {
  onComplete: (result: QizhenRainRescueCinematicResult) => void;
}

const PLAYBACK_WATCHDOG_MS = 9000;

/**
 * 雨天救援视频只负责落水后的表现。视频失败、页面隐藏或减少动态效果时，
 * 立即交回 Phaser 的确定性救援收尾，章节状态仍由控制器统一结算。
 */
export function QizhenRainRescueCinematic({ onComplete }: QizhenRainRescueCinematicProps) {
  const reducedMotion = useMediaQuery("(prefers-reduced-motion: reduce)");
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const completedRef = useRef(false);
  const [playbackState, setPlaybackState] = useState<"loading" | "playing">("loading");

  const completeOnce = useCallback((result: QizhenRainRescueCinematicResult) => {
    if (completedRef.current) return;
    completedRef.current = true;
    onComplete(result);
  }, [onComplete]);

  useEffect(() => {
    if (reducedMotion) {
      const frame = window.requestAnimationFrame(() => completeOnce("fallback"));
      return () => window.cancelAnimationFrame(frame);
    }
    const watchdog = window.setTimeout(() => completeOnce("fallback"), PLAYBACK_WATCHDOG_MS);
    return () => window.clearTimeout(watchdog);
  }, [completeOnce, reducedMotion]);

  useEffect(() => {
    if (reducedMotion) return undefined;
    const handleVisibility = () => {
      const video = videoRef.current;
      if (!video) return;
      if (document.hidden) {
        video.pause();
        return;
      }
      void video.play().catch(() => completeOnce("fallback"));
    };
    document.addEventListener("visibilitychange", handleVisibility);
    return () => document.removeEventListener("visibilitychange", handleVisibility);
  }, [completeOnce, reducedMotion]);

  if (reducedMotion) return null;

  return (
    <section
      className="qizhen-rain-rescue-cinematic"
      role="dialog"
      aria-modal="true"
      aria-label="启真湖雨天落水救援回放"
      data-qizhen-rain-rescue-cinematic="true"
      data-playback-state={playbackState}
    >
      <video
        ref={videoRef}
        src={rescueVideoUrl}
        muted
        autoPlay
        playsInline
        preload="auto"
        aria-label="值班老师和安全员把落水学生拉回码头"
        onCanPlay={(event) => {
          setPlaybackState("playing");
          void event.currentTarget.play().catch(() => completeOnce("fallback"));
        }}
        onPlay={() => setPlaybackState("playing")}
        onEnded={() => completeOnce("video")}
        onError={() => completeOnce("fallback")}
      />
      <header aria-live="polite">
        <strong>启真湖 · 雨天救援</strong>
        <span>{playbackState === "loading" ? "正在载入救援回放" : "正在将落水者拉回码头"}</span>
      </header>
      <button
        type="button"
        data-qizhen-rain-rescue-skip="true"
        onClick={() => completeOnce("skipped")}
      >跳过回放</button>
    </section>
  );
}
