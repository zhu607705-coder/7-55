import {
  CanteenBikeTransitionRenderer,
  type CanteenBikeTransitionInspectionView
} from "./CanteenBikeTransitionRenderer";
import {
  TRANSITION_FPS,
  getCanteenBikeTransitionLastFrame,
  type CanteenBikeTransitionStage
} from "./CanteenBikeTransitionTimeline";

declare global {
  interface Window {
    __canteenBikeTransitionDebug?: {
      setStage: (stage: CanteenBikeTransitionStage) => void;
      setFrame: (frame: number) => void;
      play: () => void;
      pause: () => void;
      captureCanvas: () => string;
    };
  }
}

const FRAME_DURATION_MS = 1000 / TRANSITION_FPS;
const CAPTURE_RENDER_WIDTH = 1920;
const CAPTURE_RENDER_HEIGHT = 1080;

const START_KEYS = Object.freeze([
  { frame: 0, label: "O1 食堂外" },
  { frame: 10, label: "O2 上车开始" },
  { frame: 23, label: "双手握把" },
  { frame: 33, label: "右腿跨座" },
  { frame: 40, label: "A8 近景锚点" },
  { frame: 41, label: "O3 手脚近景" },
  { frame: 70, label: "脚踏压下" },
  { frame: 71, label: "O4 蹬地起步" },
  { frame: 90, label: "A9 0m 接管" }
]);

const FINISH_KEYS = Object.freeze([
  { frame: 0, label: "A10 755m 宽景" },
  { frame: 9, label: "A11 刹车锚点" },
  { frame: 10, label: "E2 刹车近景" },
  { frame: 39, label: "前轮降速" },
  { frame: 40, label: "A12 下车宽景" },
  { frame: 66, label: "左脚落地" },
  { frame: 82, label: "右腿跨回" },
  { frame: 90, label: "双脚站稳" },
  { frame: 91, label: "E4 推车" },
  { frame: 107, label: "自行车停放" },
  { frame: 120, label: "朝入口行走" },
  { frame: 121, label: "E5 门柱遮挡" },
  { frame: 132, label: "终帧" }
]);

function requiredElement<T extends HTMLElement>(id: string): T {
  const element = document.getElementById(id);
  if (!element) throw new Error(`Missing transition debug element #${id}`);
  return element as T;
}

function numberParam(params: URLSearchParams, name: string, fallback: number): number {
  const raw = params.get(name);
  if (raw === null) return fallback;
  const value = Number(raw);
  return Number.isFinite(value) ? value : fallback;
}

function positiveIntegerParam(params: URLSearchParams, name: string): number | undefined {
  const raw = params.get(name);
  if (raw === null) return undefined;
  const value = Number(raw);
  if (!Number.isFinite(value) || value <= 0) return undefined;
  return Math.round(value);
}

const params = new URLSearchParams(window.location.search);
const quality = params.get("quality") === "capture" ? "capture" : "preview";
const requestedRenderWidth = positiveIntegerParam(params, "renderWidth");
const requestedRenderHeight = positiveIntegerParam(params, "renderHeight");
const requestedInspection = params.get("inspection");
const inspectionView: CanteenBikeTransitionInspectionView | undefined =
  requestedInspection === "hero"
  || requestedInspection === "hero_front"
  || requestedInspection === "hero_close"
  || requestedInspection === "hero_side"
  || requestedInspection === "hero_back"
  || requestedInspection === "bicycle"
    ? requestedInspection
    : undefined;
const renderWidth = requestedRenderWidth ?? (quality === "capture" ? CAPTURE_RENDER_WIDTH : undefined);
const renderHeight = requestedRenderHeight ?? (quality === "capture" ? CAPTURE_RENDER_HEIGHT : undefined);
let stage: CanteenBikeTransitionStage = params.get("stage") === "finish" ? "finish" : "start";
let currentFrame = Math.max(0, Math.round(numberParam(params, "frame", 0)));
let fractionalFrame = currentFrame;
let playing = false;
let lastAnimationTime = performance.now();

const canvas = requiredElement<HTMLCanvasElement>("transition-canvas");
const frameSlider = requiredElement<HTMLInputElement>("frame-slider");
const frameReadout = requiredElement<HTMLElement>("frame-readout");
const segmentReadout = requiredElement<HTMLElement>("segment-readout");
const poseReadout = requiredElement<HTMLElement>("pose-readout");
const playButton = requiredElement<HTMLButtonElement>("play-toggle");
const keysHost = requiredElement<HTMLElement>("keyframes");
const startButton = requiredElement<HTMLButtonElement>("stage-start");
const finishButton = requiredElement<HTMLButtonElement>("stage-finish");
const statusBadge = requiredElement<HTMLElement>("playback-status");

const renderer = new CanteenBikeTransitionRenderer(canvas, stage, {
  preserveDrawingBuffer: true,
  renderWidth,
  renderHeight,
  enableCaptureShadows: quality === "capture",
  inspectionView
});

canvas.dataset.quality = quality;
canvas.dataset.renderWidth = String(renderWidth ?? 960);
canvas.dataset.renderHeight = String(renderHeight ?? 540);

function lastFrame(): number {
  return getCanteenBikeTransitionLastFrame(stage);
}

function replaceQuery(): void {
  const query = new URLSearchParams(window.location.search);
  query.set("stage", stage);
  query.set("frame", String(currentFrame));
  query.delete("autoplay");
  if (quality === "capture") query.set("quality", "capture");
  else query.delete("quality");
  if (renderWidth) query.set("renderWidth", String(renderWidth));
  else query.delete("renderWidth");
  if (renderHeight) query.set("renderHeight", String(renderHeight));
  else query.delete("renderHeight");
  history.replaceState(null, "", `${window.location.pathname}?${query.toString()}`);
}

function updateUi(updateQuery = false): void {
  const snapshot = renderer.getSnapshot();
  frameSlider.max = String(snapshot.lastFrame);
  frameSlider.value = String(snapshot.frame);
  frameReadout.textContent = `F${String(snapshot.frame).padStart(3, "0")} / F${String(snapshot.lastFrame).padStart(3, "0")}`;
  segmentReadout.textContent = `${snapshot.segment} · ${snapshot.camera}`;
  poseReadout.textContent = `${snapshot.pose} · speed ${snapshot.wheelSpeedRatio.toFixed(2)}`;
  playButton.textContent = playing ? "暂停" : snapshot.frame >= snapshot.lastFrame ? "从头播放" : "播放";
  const qualityText = quality === "capture"
    ? `Capture ${snapshot.canvas.width}×${snapshot.canvas.height}`
    : `Preview ${snapshot.canvas.width}×${snapshot.canvas.height}`;
  statusBadge.textContent = playing ? `24 FPS 播放中 · ${qualityText}` : `已暂停 · ${qualityText}`;
  statusBadge.dataset.playing = playing ? "true" : "false";
  startButton.dataset.active = stage === "start" ? "true" : "false";
  finishButton.dataset.active = stage === "finish" ? "true" : "false";
  if (updateQuery) replaceQuery();
}

function setFrame(frame: number, updateQuery = true): void {
  currentFrame = Math.max(0, Math.min(lastFrame(), Math.round(frame)));
  fractionalFrame = currentFrame;
  renderer.renderFrame(currentFrame);
  updateUi(updateQuery);
}

function renderKeyframeButtons(): void {
  keysHost.replaceChildren();
  const entries = stage === "start" ? START_KEYS : FINISH_KEYS;
  entries.forEach((entry) => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "keyframe-button";
    button.textContent = `${entry.label} · F${String(entry.frame).padStart(3, "0")}`;
    button.addEventListener("click", () => {
      playing = false;
      setFrame(entry.frame);
    });
    keysHost.appendChild(button);
  });
}

function setStage(nextStage: CanteenBikeTransitionStage): void {
  stage = nextStage;
  playing = false;
  currentFrame = 0;
  fractionalFrame = 0;
  renderer.setStage(stage);
  renderKeyframeButtons();
  updateUi(true);
}

function pause(): void {
  playing = false;
  updateUi();
}

function play(): void {
  if (currentFrame >= lastFrame()) setFrame(0, false);
  lastAnimationTime = performance.now();
  playing = true;
  updateUi();
}

function advanceByMilliseconds(milliseconds: number, updateQuery = false): void {
  if (!Number.isFinite(milliseconds) || milliseconds <= 0) return;
  fractionalFrame = Math.min(lastFrame(), fractionalFrame + milliseconds / FRAME_DURATION_MS);
  const nextFrame = Math.min(lastFrame(), Math.floor(fractionalFrame + 0.000001));
  if (nextFrame !== currentFrame) {
    currentFrame = nextFrame;
    renderer.renderFrame(currentFrame);
    updateUi(updateQuery);
  }
  if (currentFrame >= lastFrame()) pause();
}

function animationLoop(now: number): void {
  if (playing) {
    const delta = Math.min(100, Math.max(0, now - lastAnimationTime));
    lastAnimationTime = now;
    advanceByMilliseconds(delta);
  } else {
    lastAnimationTime = now;
  }
  window.requestAnimationFrame(animationLoop);
}

startButton.addEventListener("click", () => setStage("start"));
finishButton.addEventListener("click", () => setStage("finish"));
playButton.addEventListener("click", () => {
  if (playing) pause();
  else play();
});
frameSlider.addEventListener("input", () => {
  playing = false;
  setFrame(Number(frameSlider.value), false);
});
frameSlider.addEventListener("change", () => replaceQuery());
requiredElement<HTMLButtonElement>("frame-back").addEventListener("click", () => {
  playing = false;
  setFrame(currentFrame - 1);
});
requiredElement<HTMLButtonElement>("frame-forward").addEventListener("click", () => {
  playing = false;
  setFrame(currentFrame + 1);
});
requiredElement<HTMLButtonElement>("download-frame").addEventListener("click", () => {
  renderer.renderFrame(currentFrame);
  const link = document.createElement("a");
  link.download = `canteen-bike-${stage}-F${String(currentFrame).padStart(3, "0")}.png`;
  link.href = canvas.toDataURL("image/png");
  link.click();
});

window.render_game_to_text = () => JSON.stringify({
  coordinateSystem: `960x540 logical framing; render canvas ${renderer.getSnapshot().canvas.width}x${renderer.getSnapshot().canvas.height}; +x right, +y up, -z north/theater direction`,
  playback: playing ? "playing" : "paused",
  ...renderer.getSnapshot()
});
window.advanceTime = (milliseconds: number) => advanceByMilliseconds(milliseconds);
window.__canteenBikeTransitionDebug = {
  setStage,
  setFrame,
  play,
  pause,
  captureCanvas: () => {
    renderer.renderFrame(currentFrame);
    return canvas.toDataURL("image/png");
  }
};

const handleResize = () => renderer.resizeViewport();
window.addEventListener("resize", handleResize);
window.addEventListener("beforeunload", () => {
  window.removeEventListener("resize", handleResize);
  renderer.destroy();
}, { once: true });

currentFrame = Math.min(currentFrame, lastFrame());
fractionalFrame = currentFrame;
renderer.renderFrame(currentFrame);
renderKeyframeButtons();
updateUi();
window.requestAnimationFrame(animationLoop);
if (params.get("autoplay") === "1") play();
