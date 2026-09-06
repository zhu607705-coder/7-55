import { useCallback, useEffect, useRef, useState } from "react";
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
  const [assetState, setAssetState] = useState<"loading" | "ready" | "error">("loading");
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
    let lastTick = performance.now();
    let visibleElapsedMs = 0;

    const render = (now: number) => {
      const elapsed = Math.min(250, Math.max(0, now - lastTick));
      lastTick = now;
      const readiness = renderer.getAssetState();
      setAssetState(readiness);
      if (readiness !== "ready") {
        renderer.renderFrame(0);
        frameRequest = window.requestAnimationFrame(render);
        return;
      }
      if (document.visibilityState === "hidden") {
        frameRequest = window.requestAnimationFrame(render);
        return;
      }
      visibleElapsedMs += elapsed;
      const frame = prefersReducedMotion
        ? lastFrame
        : Math.min(lastFrame, Math.floor(visibleElapsedMs / FRAME_DURATION_MS));
      renderer.renderFrame(frame);
      if (frame >= lastFrame) {
        finishOnce();
        return;
      }
      frameRequest = window.requestAnimationFrame(render);
    };

    const handleVisibility = () => {
      lastTick = performance.now();
    };
    const handleResize = () => renderer.resizeViewport();

    document.addEventListener("visibilitychange", handleVisibility);
    window.addEventListener("resize", handleResize);
    renderer.renderFrame(prefersReducedMotion ? lastFrame : 0);
    frameRequest = window.requestAnimationFrame(render);

    return () => {
      window.cancelAnimationFrame(frameRequest);
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
      {assetState !== "ready" && (
        <div className="canteen-bike-asset-status" role="status">
          <p>{assetState === "error" ? "人物资源加载失败，转场已暂停。" : "正在准备人物…"}</p>
          {assetState === "error" && <button type="button" onClick={() => window.location.reload()}>重新载入</button>}
        </div>
      )}
    </section>
  );
}
