import { useCallback, useEffect, useRef, useState, type CSSProperties } from "react";
import lampCoreUrl from "../../assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_core.png";
import lampDarkUrl from "../../assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_dark.png";
import lampGlowUrl from "../../assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_glow.png";
import lampLedsUrl from "../../assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_leds.png";
import lampOutlineUrl from "../../assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_outline.png";
import { useMediaQuery } from "../useMediaQuery";
import {
  CHAPTER_FOUR_STAR_LAMP_REDUCED_SEQUENCE,
  CHAPTER_FOUR_STAR_LAMP_SEQUENCE,
  resolveChapterFourStarLampCameraPose,
  resolveChapterFourStarLampSequenceFrame,
  type ChapterFourStarLampSequenceFrame
} from "./ChapterFourStarLampSequence";
import { ChapterFourStarLampThreeRenderer } from "./ChapterFourStarLampThreeRenderer";

export const CHAPTER_FOUR_STAR_LAMP_SEQUENCE_DURATION_MS =
  CHAPTER_FOUR_STAR_LAMP_SEQUENCE.durationMs;

interface ChapterFourStarLampClosureProps {
  sessionId: string;
  feedback?: string | null;
  onComplete: (sessionId: string) => void;
}

type StarLampRendererMode = "initializing" | "three" | "fallback";

interface StarLampCssProperties extends CSSProperties {
  "--chapter4-star-lamp-led-level": string;
  "--chapter4-star-lamp-core-level": string;
  "--chapter4-star-lamp-glow-level": string;
  "--chapter4-star-lamp-caption-level": string;
  "--chapter4-star-lamp-blackout-level": string;
  "--chapter4-star-lamp-camera-offset-y": string;
  "--chapter4-star-lamp-camera-scale": string;
}

export function ChapterFourStarLampClosure({
  sessionId,
  feedback = null,
  onComplete
}: ChapterFourStarLampClosureProps) {
  const reducedMotion = useMediaQuery("(prefers-reduced-motion: reduce)");
  const rootRef = useRef<HTMLElement | null>(null);
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const completedRef = useRef(false);
  const onCompleteRef = useRef(onComplete);
  const [rendererMode, setRendererMode] = useState<StarLampRendererMode>("initializing");
  onCompleteRef.current = onComplete;

  const completeOnce = useCallback(() => {
    if (completedRef.current) return;
    completedRef.current = true;
    onCompleteRef.current(sessionId);
  }, [sessionId]);

  useEffect(() => {
    const root = rootRef.current;
    const canvas = canvasRef.current;
    if (!root || !canvas) return undefined;

    completedRef.current = false;
    let renderer: ChapterFourStarLampThreeRenderer | null = null;
    let resizeObserver: ResizeObserver | null = null;
    let fallbackAnimationFrame = 0;
    let fallbackElapsedMs = 0;
    let fallbackLastTimestamp: number | null = null;
    let fallbackStarted = false;
    let disposed = false;

    const reflectFrame = (frame: ChapterFourStarLampSequenceFrame) => {
      const cameraPosition = resolveChapterFourStarLampCameraPose(frame);
      root.dataset.sequencePhase = frame.phase;
      root.dataset.sequenceProgress = frame.progress.toFixed(4);
      root.dataset.cameraRise = frame.cameraRiseProgress.toFixed(4);
      root.dataset.cameraX = cameraPosition.x.toFixed(4);
      root.dataset.cameraY = cameraPosition.y.toFixed(4);
      root.dataset.cameraZ = cameraPosition.z.toFixed(4);
      root.dataset.lampRotationY = "0.0000";
      root.dataset.lampArtwork = "layered-original-v1";
      root.dataset.lightLevel = Math.max(
        frame.ledLevel,
        frame.coreLevel,
        frame.glowLevel
      ).toFixed(4);
      root.style.setProperty("--chapter4-star-lamp-led-level", frame.ledLevel.toFixed(4));
      root.style.setProperty("--chapter4-star-lamp-core-level", frame.coreLevel.toFixed(4));
      root.style.setProperty("--chapter4-star-lamp-glow-level", frame.glowLevel.toFixed(4));
      root.style.setProperty("--chapter4-star-lamp-caption-level", frame.captionLevel.toFixed(4));
      root.style.setProperty(
        "--chapter4-star-lamp-camera-offset-y",
        `${frame.artworkOffsetY.toFixed(3)}%`
      );
      root.style.setProperty(
        "--chapter4-star-lamp-camera-scale",
        frame.artworkScale.toFixed(4)
      );
      root.style.setProperty(
        "--chapter4-star-lamp-blackout-level",
        (1 - frame.sceneReveal).toFixed(4)
      );
    };

    const tickFallback = (timestamp: number) => {
      if (disposed || completedRef.current) return;
      if (document.visibilityState === "hidden") {
        fallbackLastTimestamp = null;
        fallbackAnimationFrame = window.requestAnimationFrame(tickFallback);
        return;
      }
      if (fallbackLastTimestamp === null) fallbackLastTimestamp = timestamp;
      const frameDelta = Math.min(100, Math.max(0, timestamp - fallbackLastTimestamp));
      fallbackLastTimestamp = timestamp;
      fallbackElapsedMs += frameDelta;
      const frame = resolveChapterFourStarLampSequenceFrame(fallbackElapsedMs, reducedMotion);
      reflectFrame(frame);
      if (frame.phase === "complete") {
        completeOnce();
        return;
      }
      fallbackAnimationFrame = window.requestAnimationFrame(tickFallback);
    };

    const startFallback = (reason: string) => {
      if (disposed || fallbackStarted || completedRef.current) return;
      fallbackStarted = true;
      renderer?.destroy();
      renderer = null;
      fallbackElapsedMs = 0;
      fallbackLastTimestamp = null;
      root.dataset.renderer = "layered-camera-fallback";
      root.dataset.fallbackReason = reason;
      reflectFrame(resolveChapterFourStarLampSequenceFrame(0, reducedMotion));
      setRendererMode("fallback");
      fallbackAnimationFrame = window.requestAnimationFrame(tickFallback);
    };

    const resizeRenderer = () => {
      if (!renderer) return;
      const bounds = root.getBoundingClientRect();
      renderer.resize(bounds.width || 960, bounds.height || 540);
    };

    if (!canCreateWebGlContext()) {
      startFallback("star_lamp_webgl_unavailable");
    } else {
      try {
        renderer = new ChapterFourStarLampThreeRenderer(canvas, reducedMotion);
        root.dataset.renderer = "three-camera-stage";
        delete root.dataset.fallbackReason;
        setRendererMode("three");
        resizeRenderer();
        renderer.start({
          onComplete: completeOnce,
          onFailure: startFallback,
          onFrame: reflectFrame
        });
      } catch (error) {
        startFallback(error instanceof Error ? error.message : "star_lamp_webgl_unavailable");
      }
    }

    if (typeof ResizeObserver === "function") {
      resizeObserver = new ResizeObserver(resizeRenderer);
      resizeObserver.observe(root);
    }
    window.addEventListener("resize", resizeRenderer);

    return () => {
      disposed = true;
      window.cancelAnimationFrame(fallbackAnimationFrame);
      window.removeEventListener("resize", resizeRenderer);
      resizeObserver?.disconnect();
      renderer?.destroy();
    };
  }, [completeOnce, reducedMotion]);

  const style: StarLampCssProperties = {
    "--chapter4-star-lamp-led-level": "0",
    "--chapter4-star-lamp-core-level": "0",
    "--chapter4-star-lamp-glow-level": "0",
    "--chapter4-star-lamp-caption-level": "0",
    "--chapter4-star-lamp-blackout-level": "1",
    "--chapter4-star-lamp-camera-offset-y": "-22%",
    "--chapter4-star-lamp-camera-scale": "1.16"
  };

  return (
    <section
      ref={rootRef}
      className={`chapter4-star-lamp-closure is-${rendererMode}`}
      role="dialog"
      aria-modal="true"
      aria-label="灿若星辰灯由底部向上观察与点亮演出"
      data-session-id={sessionId}
      data-motion={reducedMotion ? "reduced" : "full"}
      style={style}
    >
      <div className="chapter4-star-lamp-closure__fallback" aria-hidden="true">
        <div className="chapter4-star-lamp-closure__fallback-stars is-far" />
        <div className="chapter4-star-lamp-closure__fallback-stars is-middle" />
        <div className="chapter4-star-lamp-closure__fallback-stars is-near" />
      </div>
      <canvas
        ref={canvasRef}
        className="chapter4-star-lamp-closure__canvas"
        role="img"
        aria-hidden={rendererMode !== "three"}
        aria-label={reducedMotion
          ? "原版灿若星辰灯依次点亮灯珠与中央灯芯"
          : "相机从固定的原版灿若星辰灯底部向上移动，随后灯珠与中央灯芯依次点亮"}
      />
      <div className="chapter4-star-lamp-closure__artwork" aria-hidden="true">
        <img className="chapter4-star-lamp-closure__layer is-dark" src={lampDarkUrl} alt="" />
        <img className="chapter4-star-lamp-closure__layer is-outline" src={lampOutlineUrl} alt="" />
        <img className="chapter4-star-lamp-closure__layer is-leds" src={lampLedsUrl} alt="" />
        <img className="chapter4-star-lamp-closure__layer is-core" src={lampCoreUrl} alt="" />
        <img className="chapter4-star-lamp-closure__layer is-glow" src={lampGlowUrl} alt="" />
        <div className="chapter4-star-lamp-closure__flare" />
      </div>
      <div className="chapter4-star-lamp-closure__vignette" aria-hidden="true" />
      <div className="chapter4-star-lamp-closure__blackout" aria-hidden="true" />
      <footer className="chapter4-star-lamp-closure__caption">
        <strong>07:55</strong>
        <span>灿若星辰</span>
        {feedback ? <small role="status">{feedback}</small> : null}
      </footer>
      <span className="chapter4-star-lamp-closure__sr-status" aria-live="polite">
        {rendererMode === "fallback"
          ? "正在以兼容模式完整播放灯光演出"
          : reducedMotion
            ? "正在按减弱动态模式播放完整点灯演出"
            : "摄像机正在从固定灯体底部向上移动，到达正面机位后点亮"}
      </span>
    </section>
  );
}

export const CHAPTER_FOUR_STAR_LAMP_REDUCED_SEQUENCE_DURATION_MS =
  CHAPTER_FOUR_STAR_LAMP_REDUCED_SEQUENCE.durationMs;

function canCreateWebGlContext(): boolean {
  const probe = document.createElement("canvas");
  const attributes: WebGLContextAttributes = {
    alpha: false,
    antialias: false,
    depth: false,
    failIfMajorPerformanceCaveat: false,
    powerPreference: "low-power",
    preserveDrawingBuffer: false,
    stencil: false
  };
  try {
    const context = probe.getContext("webgl2", attributes)
      ?? probe.getContext("webgl", attributes);
    if (!context) return false;
    context.getExtension("WEBGL_lose_context")?.loseContext();
    return true;
  } catch {
    return false;
  }
}
