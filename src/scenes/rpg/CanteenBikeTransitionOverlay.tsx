import { useCallback, useEffect, useRef } from "react";
import { useMediaQuery } from "../../components/useMediaQuery";
import { CanteenBikeTransitionRenderer } from "./canteen-chase/CanteenBikeTransitionRenderer";
import {
  TRANSITION_FPS,
  getCanteenBikeTransitionLastFrame,
  type CanteenBikeTransitionStage
} from "./canteen-chase/CanteenBikeTransitionTimeline";

interface CanteenBikeTransitionOverlayProps {
  stage: CanteenBikeTransitionStage;
  onComplete: () => void;
}

const FRAME_DURATION_MS = 1000 / TRANSITION_FPS;

export function CanteenBikeTransitionOverlay({
  stage,
  onComplete
}: CanteenBikeTransitionOverlayProps) {
  const prefersReducedMotion = useMediaQuery("(prefers-reduced-motion: reduce)");
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const onCompleteRef = useRef(onComplete);
  const completedRef = useRef(false);
  onCompleteRef.current = onComplete;

  const finishOnce = useCallback(() => {
    if (completedRef.current) return;
    completedRef.current = true;
    onCompleteRef.current();
  }, []);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return undefined;

    completedRef.current = false;
    const renderer = new CanteenBikeTransitionRenderer(canvas, stage);
    const lastFrame = getCanteenBikeTransitionLastFrame(stage);
    let frameRequest = 0;
    let timeout = 0;
    let startedAt = performance.now();
    let hiddenAt: number | null = document.visibilityState === "hidden" ? startedAt : null;

    const render = (now: number) => {
      if (hiddenAt !== null) {
        frameRequest = window.requestAnimationFrame(render);
        return;
      }
      const frame = prefersReducedMotion
        ? lastFrame
        : Math.min(lastFrame, Math.floor((now - startedAt) / FRAME_DURATION_MS));
      renderer.renderFrame(frame);
      if (frame >= lastFrame) {
        finishOnce();
        return;
      }
      frameRequest = window.requestAnimationFrame(render);
    };

    const handleVisibility = () => {
      const now = performance.now();
      if (document.visibilityState === "hidden") {
        hiddenAt = now;
      } else if (hiddenAt !== null) {
        startedAt += now - hiddenAt;
        hiddenAt = null;
      }
    };
    const handleResize = () => renderer.resizeViewport();

    document.addEventListener("visibilitychange", handleVisibility);
    window.addEventListener("resize", handleResize);
    renderer.renderFrame(prefersReducedMotion ? lastFrame : 0);
    frameRequest = window.requestAnimationFrame(render);
    timeout = window.setTimeout(
      finishOnce,
      prefersReducedMotion ? 160 : (lastFrame + 1) * FRAME_DURATION_MS + 1200
    );

    return () => {
      window.cancelAnimationFrame(frameRequest);
      window.clearTimeout(timeout);
      document.removeEventListener("visibilitychange", handleVisibility);
      window.removeEventListener("resize", handleResize);
      renderer.destroy();
    };
  }, [finishOnce, prefersReducedMotion, stage]);

  return (
    <section
      className={`canteen-bike-transition-overlay is-${stage}`}
      aria-label={stage === "start" ? "食堂外上车转场" : "剧院外到达转场"}
      data-transition-stage={stage}
    >
      <canvas
        ref={canvasRef}
        className="canteen-bike-transition-canvas"
        role="img"
        aria-label={stage === "start" ? "角色解锁共享单车并开始骑行" : "角色刹车下车并进入剧院外广场"}
      />
    </section>
  );
}
