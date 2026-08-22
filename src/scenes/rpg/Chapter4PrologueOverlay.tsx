import { useCallback, useEffect, useRef, useState } from "react";
import { useMediaQuery } from "../../components/useMediaQuery";
import { GameSubtitleFrame } from "../../components/GameSubtitleFrame";
import type { EventBus } from "../../core/EventBus";
import h3TransitionSource from "../../assets/rpg/cinematics/chapter4-prologue/chapter35_to_chapter4_h3_transition.mp4?chapter4-h3-embedded";
import {
  PROLOGUE_DEPARTING_STUDENT_PORTRAIT,
  type ProloguePortraitPair
} from "./chapter4-prologue/ProloguePortraitAssets";
import {
  PROLOGUE_BEATS,
  PROLOGUE_TASK_CARD_AT,
  prologueSubtitleAt,
  type PrologueSubtitle
} from "./chapter4-prologue/PrologueTimeline";

const H3_TRANSITION_IS_EMBEDDED = typeof h3TransitionSource !== "string";
const H3_TRANSITION_URL = typeof h3TransitionSource === "string" ? h3TransitionSource : "";
const H3_TRANSITION_CHUNKS = typeof h3TransitionSource === "string" ? null : h3TransitionSource.chunks;
const H3_TRANSITION_MIME_TYPE = typeof h3TransitionSource === "string"
  ? "video/mp4; codecs=\"avc1.640028\""
  : h3TransitionSource.mimeType;
const EMBEDDED_VIDEO_CHUNK_SIZE = 256 * 1024;
const EMBEDDED_VIDEO_CONVERSION_TIMEOUT_MS = 20000;

type EmbeddedVideoWorkerReply =
  | { ok: true; buffer: ArrayBuffer; final: boolean }
  | { ok: false; error: string };

interface EmbeddedVideoMediaSource {
  url: string;
  ready: Promise<void>;
  dispose: () => void;
}

const EMBEDDED_VIDEO_WORKER_SOURCE = `
self.onmessage = (event) => {
  try {
    const chunk = event.data && event.data.chunk;
    if (typeof chunk !== "string") throw new Error("embedded_video_chunk_missing");
    const binary = atob(chunk);
    const buffer = new ArrayBuffer(binary.length);
    const bytes = new Uint8Array(buffer);
    for (let index = 0; index < binary.length; index += 1) {
      bytes[index] = binary.charCodeAt(index);
    }
    self.postMessage({ ok: true, buffer, final: Boolean(event.data.final) }, [buffer]);
  } catch (error) {
    self.postMessage({ ok: false, error: error instanceof Error ? error.message : String(error) });
  }
};`;

function createEmbeddedVideoMediaSource(
  chunks: readonly string[],
  mimeType: string,
  signal: AbortSignal
): EmbeddedVideoMediaSource {
  if (signal.aborted) throw new DOMException("H3 transition conversion aborted", "AbortError");
  if (typeof MediaSource === "undefined" || !MediaSource.isTypeSupported(mimeType)) {
    throw new Error("h3_transition_media_source_unsupported");
  }
  if (chunks.length === 0) throw new Error("h3_transition_chunks_empty");
  if (chunks.some((chunk, index) => (
    typeof chunk !== "string"
    || chunk.length === 0
    || chunk.length % 4 !== 0
    || (index < chunks.length - 1 && chunk.length !== EMBEDDED_VIDEO_CHUNK_SIZE)
  ))) {
    throw new Error("h3_transition_chunk_contract_invalid");
  }

  const mediaSource = new MediaSource();
  const videoObjectUrl = URL.createObjectURL(mediaSource);
  const workerScriptUrl = URL.createObjectURL(new Blob(
    [EMBEDDED_VIDEO_WORKER_SOURCE],
    { type: "text/javascript" }
  ));
  let worker: Worker;
  try {
    worker = new Worker(workerScriptUrl);
  } catch (error) {
    URL.revokeObjectURL(workerScriptUrl);
    URL.revokeObjectURL(videoObjectUrl);
    throw error;
  }

  let sourceBuffer: SourceBuffer | null = null;
  let nextChunkIndex = 0;
  let inFlightFinal = false;
  let appendedFinal = false;
  let settled = false;
  let detached = false;
  let disposed = false;
  let resolveReady!: () => void;
  let rejectReady!: (error: unknown) => void;
  const ready = new Promise<void>((resolve, reject) => {
    resolveReady = resolve;
    rejectReady = reject;
  });

  const detachPipeline = () => {
    if (detached) return;
    detached = true;
    worker.onmessage = null;
    worker.onerror = null;
    worker.onmessageerror = null;
    worker.terminate();
    URL.revokeObjectURL(workerScriptUrl);
    mediaSource.removeEventListener("sourceopen", handleSourceOpen);
    mediaSource.removeEventListener("sourceclose", handleSourceClose);
    sourceBuffer?.removeEventListener("updateend", handleUpdateEnd);
    sourceBuffer?.removeEventListener("error", handleSourceBufferError);
    signal.removeEventListener("abort", handleAbort);
  };

  const rejectOnce = (error: unknown) => {
    if (settled) return;
    settled = true;
    detachPipeline();
    rejectReady(error);
  };

  const finish = () => {
    if (settled) return;
    try {
      if (mediaSource.readyState !== "open") {
        throw new Error("h3_transition_media_source_not_open");
      }
      mediaSource.endOfStream();
      settled = true;
      detachPipeline();
      resolveReady();
    } catch (error) {
      rejectOnce(error);
    }
  };

  const sendNextChunk = () => {
    if (settled) return;
    if (!sourceBuffer || sourceBuffer.updating || nextChunkIndex >= chunks.length) {
      rejectOnce(new Error("h3_transition_source_buffer_protocol_error"));
      return;
    }
    const chunk = chunks[nextChunkIndex];
    inFlightFinal = nextChunkIndex === chunks.length - 1;
    nextChunkIndex += 1;
    try {
      worker.postMessage({ chunk, final: inFlightFinal });
    } catch (error) {
      rejectOnce(error);
    }
  };

  const handleUpdateEnd = () => {
    if (settled) return;
    if (appendedFinal) {
      if (nextChunkIndex !== chunks.length) {
        rejectOnce(new Error("h3_transition_final_chunk_order_invalid"));
        return;
      }
      finish();
      return;
    }
    sendNextChunk();
  };

  const handleSourceBufferError = () => {
    rejectOnce(new Error("h3_transition_source_buffer_error"));
  };

  const handleSourceOpen = () => {
    if (settled) return;
    try {
      sourceBuffer = mediaSource.addSourceBuffer(mimeType);
      sourceBuffer.addEventListener("updateend", handleUpdateEnd);
      sourceBuffer.addEventListener("error", handleSourceBufferError);
      sendNextChunk();
    } catch (error) {
      rejectOnce(error);
    }
  };

  const handleSourceClose = () => {
    if (!settled && !disposed) {
      rejectOnce(new Error("h3_transition_media_source_closed"));
    }
  };

  const handleAbort = () => {
    rejectOnce(new DOMException("H3 transition conversion aborted", "AbortError"));
  };

  worker.onmessage = (event: MessageEvent<EmbeddedVideoWorkerReply>) => {
    if (!event.data.ok) {
      rejectOnce(new Error(event.data.error || "h3_transition_worker_failed"));
      return;
    }
    if (!(event.data.buffer instanceof ArrayBuffer) || event.data.final !== inFlightFinal) {
      rejectOnce(new Error("h3_transition_worker_buffer_invalid"));
      return;
    }
    if (!sourceBuffer || sourceBuffer.updating) {
      rejectOnce(new Error("h3_transition_source_buffer_busy"));
      return;
    }
    appendedFinal = event.data.final;
    try {
      sourceBuffer.appendBuffer(event.data.buffer);
    } catch (error) {
      rejectOnce(error);
    }
  };
  worker.onerror = (event) => {
    event.preventDefault();
    rejectOnce(new Error(event.message || "h3_transition_worker_error"));
  };
  worker.onmessageerror = () => {
    rejectOnce(new Error("h3_transition_worker_message_error"));
  };
  mediaSource.addEventListener("sourceopen", handleSourceOpen, { once: true });
  mediaSource.addEventListener("sourceclose", handleSourceClose);
  signal.addEventListener("abort", handleAbort, { once: true });

  const dispose = () => {
    if (disposed) return;
    disposed = true;
    if (!settled) {
      rejectOnce(new DOMException("H3 transition conversion disposed", "AbortError"));
    } else {
      detachPipeline();
    }
    try {
      if (sourceBuffer?.updating) sourceBuffer.abort();
    } catch {
      // SourceBuffer may already be detached after a media error.
    }
    URL.revokeObjectURL(videoObjectUrl);
  };

  if (signal.aborted) handleAbort();
  return { url: videoObjectUrl, ready, dispose };
}

interface Chapter4PrologueOverlayProps {
  events: EventBus;
  onComplete: () => void;
  initialElapsedMs?: number;
  handoffStatus?: "idle" | "pending" | "waiting_ready" | "failed" | "ready";
  handoffFeedback?: string | null;
}

interface PrologueRuntime {
  elapsedMs: number;
  paused: boolean;
  cardShown: boolean;
}

interface ProloguePortraitState {
  key: "departing_student";
  pair: ProloguePortraitPair;
  frame: 0 | 1;
  sceneCutIn: boolean;
}

function portraitAt(elapsedMs: number): ProloguePortraitState | null {
  const frame = (Math.floor(elapsedMs / 680) % 2) as 0 | 1;
  if (elapsedMs >= 24600 && elapsedMs < 28300) {
    return {
      key: "departing_student",
      pair: PROLOGUE_DEPARTING_STUDENT_PORTRAIT,
      frame,
      sceneCutIn: true
    };
  }
  return null;
}

function normalizeInitialElapsedMs(value: number | undefined): number {
  const elapsedMs = Number(value) || 0;
  return Math.max(0, Math.min(PROLOGUE_TASK_CARD_AT, elapsedMs));
}

function createInitialRuntime(initialElapsedMs: number): PrologueRuntime {
  return {
    elapsedMs: initialElapsedMs,
    paused: false,
    cardShown: initialElapsedMs >= PROLOGUE_TASK_CARD_AT
  };
}

function drawStaticPrologueFallback(canvas: HTMLCanvasElement): void {
  const width = 960;
  const height = 540;
  if (canvas.width !== width) canvas.width = width;
  if (canvas.height !== height) canvas.height = height;
  const context = canvas.getContext("2d");
  if (!context) return;
  context.clearRect(0, 0, width, height);
  const sky = context.createLinearGradient(0, 0, 0, height);
  sky.addColorStop(0, "#102d50");
  sky.addColorStop(0.58, "#245f7d");
  sky.addColorStop(1, "#152130");
  context.fillStyle = sky;
  context.fillRect(0, 0, width, height);
  context.fillStyle = "#0b111a";
  context.fillRect(0, 352, width, 188);
  context.fillStyle = "#263b50";
  context.fillRect(0, 352, width, 6);
  context.fillStyle = "#111a26";
  context.fillRect(640, 92, 250, 260);
  context.fillStyle = "#e7c56b";
  for (let row = 0; row < 3; row += 1) {
    for (let column = 0; column < 4; column += 1) {
      context.fillRect(670 + column * 48, 126 + row * 58, 22, 18);
    }
  }
  context.save();
  context.translate(480, 306);
  context.rotate(-0.08);
  context.fillStyle = "#554d39";
  context.fillRect(-39, -27, 78, 54);
  context.fillStyle = "#e8dfc4";
  context.fillRect(-36, -24, 72, 48);
  context.fillStyle = "#7b8799";
  context.fillRect(-24, -8, 38, 3);
  context.fillRect(-24, 1, 48, 3);
  context.fillRect(-24, 10, 31, 3);
  context.restore();
}

function createInitialFiredBeats(initialElapsedMs: number): Set<string> {
  return new Set(
    PROLOGUE_BEATS
      .filter((beat) => initialElapsedMs >= PROLOGUE_TASK_CARD_AT
        ? beat.at <= initialElapsedMs
        : beat.at < initialElapsedMs)
      .map((beat) => beat.cueEvent)
  );
}

/**
 * 第三章半恢复出的现场回放。
 * 纯表现层：H3 成片负责主画面，像素演出负责加载失败与减少动态效果时的回退；
 * 共享时间线发领域事件驱动音频 cue 与中文字幕；
 * 剧情事实只通过 onComplete 交给 ChapterFourPrologueController 写入。
 */
export function Chapter4PrologueOverlay({
  events,
  onComplete,
  initialElapsedMs,
  handoffStatus = "idle",
  handoffFeedback = null
}: Chapter4PrologueOverlayProps) {
  const prefersReducedMotion = useMediaQuery("(prefers-reduced-motion: reduce)");
  const initialElapsedRef = useRef(normalizeInitialElapsedMs(initialElapsedMs));
  const runtimeRef = useRef<PrologueRuntime>(createInitialRuntime(initialElapsedRef.current));
  const firedBeatsRef = useRef(createInitialFiredBeats(initialElapsedRef.current));
  const completedRef = useRef(false);
  const eventsRef = useRef(events);
  const onCompleteRef = useRef(onComplete);
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const videoReadyRef = useRef(false);
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const initialSubtitle = initialElapsedRef.current >= PROLOGUE_TASK_CARD_AT
    ? null
    : prologueSubtitleAt(initialElapsedRef.current);
  const [subtitle, setSubtitle] = useState<PrologueSubtitle | null>(initialSubtitle);
  const [portrait, setPortrait] = useState<ProloguePortraitState | null>(
    portraitAt(initialElapsedRef.current)
  );
  const [cardShown, setCardShown] = useState(initialElapsedRef.current >= PROLOGUE_TASK_CARD_AT);
  const [videoReady, setVideoReady] = useState(false);
  const [videoFailed, setVideoFailed] = useState(false);
  const [videoSource, setVideoSource] = useState(
    H3_TRANSITION_IS_EMBEDDED ? "" : H3_TRANSITION_URL
  );
  eventsRef.current = events;
  onCompleteRef.current = onComplete;

  const useH3Video = !prefersReducedMotion && !videoFailed;

  const markVideoFailed = useCallback(() => {
    videoRef.current?.pause();
    videoReadyRef.current = false;
    setVideoReady(false);
    setVideoFailed(true);
  }, []);

  const playVideo = useCallback(() => {
    const video = videoRef.current;
    const runtime = runtimeRef.current;
    if (!video || prefersReducedMotion || runtime.paused || runtime.cardShown) return;
    void video.play().catch(markVideoFailed);
  }, [markVideoFailed, prefersReducedMotion]);

  const syncVideoToRuntime = useCallback((force = false) => {
    const video = videoRef.current;
    if (!video || !Number.isFinite(video.duration)) return;
    const runtimeSeconds = Math.min(
      runtimeRef.current.elapsedMs / 1000,
      Math.max(0, video.duration - (1 / 24))
    );
    if (force || Math.abs(video.currentTime - runtimeSeconds) > 0.25) {
      video.currentTime = runtimeSeconds;
    }
  }, []);

  const handleVideoReady = useCallback(() => {
    if (prefersReducedMotion) return;
    videoReadyRef.current = true;
    setVideoReady(true);
    setVideoFailed(false);
    syncVideoToRuntime(true);
    playVideo();
  }, [playVideo, prefersReducedMotion, syncVideoToRuntime]);

  useEffect(() => {
    if (!H3_TRANSITION_IS_EMBEDDED
      || prefersReducedMotion
      || runtimeRef.current.cardShown) return;
    const chunks = H3_TRANSITION_CHUNKS;
    if (!chunks) {
      markVideoFailed();
      return;
    }
    const abortController = new AbortController();
    let embeddedMedia: EmbeddedVideoMediaSource;
    try {
      embeddedMedia = createEmbeddedVideoMediaSource(
        chunks,
        H3_TRANSITION_MIME_TYPE,
        abortController.signal
      );
    } catch {
      markVideoFailed();
      return;
    }
    setVideoSource(embeddedMedia.url);
    let conversionFinished = false;
    const conversionTimeout = window.setTimeout(() => {
      if (conversionFinished) return;
      abortController.abort();
      embeddedMedia.dispose();
      setVideoSource("");
      markVideoFailed();
    }, EMBEDDED_VIDEO_CONVERSION_TIMEOUT_MS);
    void embeddedMedia.ready
      .then(() => {
        conversionFinished = true;
        window.clearTimeout(conversionTimeout);
      })
      .catch((error: unknown) => {
        conversionFinished = true;
        window.clearTimeout(conversionTimeout);
        if (error instanceof DOMException && error.name === "AbortError") return;
        embeddedMedia.dispose();
        setVideoSource("");
        markVideoFailed();
      });
    return () => {
      conversionFinished = true;
      window.clearTimeout(conversionTimeout);
      abortController.abort();
      embeddedMedia.dispose();
    };
  }, [markVideoFailed, prefersReducedMotion]);

  const advance = useCallback((milliseconds: number) => {
    const runtime = runtimeRef.current;
    if (runtime.paused || runtime.cardShown || milliseconds <= 0) return;
    runtime.elapsedMs = Math.min(PROLOGUE_TASK_CARD_AT, runtime.elapsedMs + Math.min(5000, milliseconds));
    for (const beat of PROLOGUE_BEATS) {
      if (runtime.elapsedMs >= beat.at && !firedBeatsRef.current.has(beat.cueEvent)) {
        firedBeatsRef.current.add(beat.cueEvent);
        eventsRef.current.emit(beat.cueEvent);
      }
    }
    if (runtime.elapsedMs >= PROLOGUE_TASK_CARD_AT) {
      runtime.cardShown = true;
      setCardShown(true);
    }
  }, []);

  const restart = useCallback(() => {
    runtimeRef.current = { elapsedMs: 0, paused: false, cardShown: false };
    firedBeatsRef.current = new Set<string>();
    setSubtitle(null);
    setPortrait(null);
    setCardShown(false);
    const video = videoRef.current;
    if (video) video.currentTime = 0;
    playVideo();
  }, [playVideo]);

  const skipToCard = useCallback(() => {
    const runtime = runtimeRef.current;
    if (runtime.cardShown) return;
    // 跳过时静默略过剩余节拍，只停掉在播人声与排队音效，再弹出任务卡。
    for (const beat of PROLOGUE_BEATS) {
      if (beat.cueEvent !== "chapter4_prologue_task_card") firedBeatsRef.current.add(beat.cueEvent);
    }
    eventsRef.current.emit("chapter4_prologue_skip");
    runtime.elapsedMs = PROLOGUE_TASK_CARD_AT;
    runtime.cardShown = true;
    videoRef.current?.pause();
    firedBeatsRef.current.add("chapter4_prologue_task_card");
    eventsRef.current.emit("chapter4_prologue_task_card");
    setSubtitle(null);
    setPortrait(null);
    setCardShown(true);
  }, []);

  const confirm = useCallback(() => {
    if (completedRef.current
      || handoffStatus === "pending"
      || handoffStatus === "waiting_ready"
      || handoffStatus === "ready") return;
    onCompleteRef.current();
  }, [handoffStatus]);

  useEffect(() => {
    if (handoffStatus !== "ready" || completedRef.current) return;
    completedRef.current = true;
    eventsRef.current.emit("chapter4_prologue_finished");
  }, [handoffStatus]);

  // 中途卸载（例如切回手机）：取消排队 cue、停止人声与音乐。
  useEffect(() => () => {
    if (!completedRef.current) {
      eventsRef.current.emit("chapter4_prologue_closed");
    }
  }, []);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    if (useH3Video) {
      const context = canvas.getContext("2d");
      context?.clearRect(0, 0, canvas.width, canvas.height);
      return;
    }
    drawStaticPrologueFallback(canvas);
  }, [prefersReducedMotion, useH3Video]);

  useEffect(() => {
    const video = videoRef.current;
    if (!video) return;
    if (prefersReducedMotion) {
      video.pause();
      videoReadyRef.current = false;
      setVideoReady(false);
      return;
    }
    if (!videoFailed && video.readyState >= HTMLMediaElement.HAVE_METADATA) {
      handleVideoReady();
    }
  }, [handleVideoReady, prefersReducedMotion, videoFailed]);

  useEffect(() => {
    const handleVisibility = () => {
      const hidden = document.visibilityState === "hidden";
      runtimeRef.current.paused = hidden;
      if (hidden) videoRef.current?.pause();
      else if (videoReadyRef.current) {
        syncVideoToRuntime(true);
        playVideo();
      }
    };
    document.addEventListener("visibilitychange", handleVisibility);
    return () => document.removeEventListener("visibilitychange", handleVisibility);
  }, [playVideo, syncVideoToRuntime]);

  useEffect(() => {
    let frame = 0;
    let previous = performance.now();
    let lastSubtitleId: string | null = null;
    let lastPortraitId: string | null = null;
    const tick = (now: number) => {
      const delta = Math.min(48, Math.max(0, now - previous));
      previous = now;
      advance(delta);
      const runtime = runtimeRef.current;
      if (videoReadyRef.current && !runtime.cardShown) syncVideoToRuntime();
      if (runtime.cardShown) videoRef.current?.pause();
      const active = runtime.cardShown ? null : prologueSubtitleAt(runtime.elapsedMs);
      const activeId = active ? `${active.id}:${active.at}` : null;
      if (activeId !== lastSubtitleId) {
        lastSubtitleId = activeId;
        setSubtitle(active);
      }
      const activePortrait = portraitAt(runtime.elapsedMs);
      const portraitId = activePortrait ? `${activePortrait.key}:${activePortrait.frame}` : null;
      if (portraitId !== lastPortraitId) {
        lastPortraitId = portraitId;
        setPortrait(activePortrait);
      }
      frame = window.requestAnimationFrame(tick);
    };
    frame = window.requestAnimationFrame(tick);
    return () => window.cancelAnimationFrame(frame);
  }, [advance, syncVideoToRuntime]);

  useEffect(() => {
    const previousAdvance = window.advanceTime;
    const advanceTime = (milliseconds: number) => {
      let remaining = Math.max(0, Number(milliseconds) || 0);
      while (remaining > 0) {
        const step = Math.min(1000 / 60, remaining);
        advance(step);
        remaining -= step;
      }
      if (videoReadyRef.current) syncVideoToRuntime(true);
      if (runtimeRef.current.cardShown) videoRef.current?.pause();
      const active = runtimeRef.current.cardShown ? null : prologueSubtitleAt(runtimeRef.current.elapsedMs);
      setSubtitle(active);
      setPortrait(runtimeRef.current.cardShown ? null : portraitAt(runtimeRef.current.elapsedMs));
    };
    window.advanceTime = advanceTime;
    return () => {
      if (window.advanceTime !== advanceTime) return;
      if (previousAdvance) window.advanceTime = previousAdvance;
      else delete window.advanceTime;
    };
  }, [advance, syncVideoToRuntime]);

  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.metaKey || event.ctrlKey || event.altKey) return;
      if (event.key === "Escape" && !runtimeRef.current.cardShown) {
        event.preventDefault();
        skipToCard();
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [skipToCard]);

  return (
    <section
      className="chapter4-prologue-overlay"
      aria-label="第四章序幕：纸条进入段永平教学楼"
      data-card={cardShown ? "shown" : "hidden"}
      data-initial-elapsed-ms={initialElapsedRef.current}
      data-h3-video={useH3Video ? videoReady ? "ready" : "loading" : "fallback"}
      data-h3-source={videoSource.startsWith("blob:") ? "blob" : videoSource ? "url" : "pending"}
    >
      <video
        ref={videoRef}
        className={`chapter4-prologue-video${useH3Video && videoReady ? " is-ready" : ""}`}
        src={videoSource || undefined}
        aria-hidden="true"
        autoPlay={!prefersReducedMotion && !cardShown}
        disablePictureInPicture
        muted
        playsInline
        preload="auto"
        onCanPlay={handleVideoReady}
        onError={markVideoFailed}
      />
      <canvas
        ref={canvasRef}
        className="chapter4-prologue-canvas"
        role="img"
        aria-label="夜色中，湿纸条离开启真湖，经过街机厅进入段永平教学楼，沿大厅进入熄灯后的走廊"
      />

      <div className="chapter4-prologue-recovery-mark" aria-label="由四项手机证据恢复的现场回放">
        <strong>RECOVERED TIMELINE</strong>
        <span>SOURCE 4 / 4</span>
      </div>

      {!cardShown ? (
        <button type="button" className="chapter4-prologue-skip" onClick={skipToCard}>
          跳过恢复回放
        </button>
      ) : null}

      {subtitle ? (
        <GameSubtitleFrame
          key={`${subtitle.id}:${subtitle.at}`}
          text={subtitle.text}
          tone={subtitle.tone}
          speaker={subtitle.speaker}
          durationMs={subtitle.durationMs}
          className={`chapter4-prologue-subtitle${portrait && !portrait.sceneCutIn && (!useH3Video || !videoReady) ? " has-portrait" : ""}`}
        />
      ) : null}

      {portrait && (!useH3Video || !videoReady) ? (
        <figure
          key={portrait.key}
          className={`chapter4-prologue-portrait is-${portrait.key}${portrait.sceneCutIn ? " is-scene-cut-in" : ""}`}
          aria-hidden="true"
        >
          <img src={portrait.frame === 0 ? portrait.pair.a : portrait.pair.b} alt={portrait.pair.alt} />
        </figure>
      ) : null}

      {cardShown ? (
        <aside className="chapter4-prologue-task-card" role="dialog" aria-modal="true" aria-labelledby="chapter4-prologue-task-title">
          <small>CHAPTER 03.5 · COMPLETE</small>
          <h2 id="chapter4-prologue-task-title">第四章：时间迷宫</h2>
          <dl>
            <div>
              <dt>现场定位</dt>
              <dd>段永平教学楼玻璃门</dd>
            </div>
            <div>
              <dt>当前目标</dt>
              <dd>追踪进入教学楼的异常签到纸</dd>
            </div>
          </dl>
          {handoffFeedback ? (
            <p role="status" aria-live="polite">{handoffFeedback}</p>
          ) : null}
          <div className="chapter4-prologue-task-actions">
            <button
              type="button"
              className="primary"
              onClick={confirm}
              disabled={handoffStatus === "pending" || handoffStatus === "waiting_ready" || handoffStatus === "ready"}
            >
              {handoffStatus === "pending"
                ? "正在提交任务……"
                : handoffStatus === "waiting_ready"
                  ? "正在同步教学楼现场……"
                  : handoffStatus === "failed"
                    ? "重试进入第四章"
                    : "收下任务，进入第四章"}
            </button>
            <button
              type="button"
              className="secondary"
              onClick={restart}
              disabled={handoffStatus === "pending" || handoffStatus === "waiting_ready" || handoffStatus === "ready"}
            >重播过场</button>
          </div>
        </aside>
      ) : null}
    </section>
  );
}
