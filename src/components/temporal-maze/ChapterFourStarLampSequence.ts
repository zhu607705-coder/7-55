export const CHAPTER_FOUR_STAR_LAMP_SEQUENCE = Object.freeze({
  durationMs: 5_800,
  revealEndMs: 260,
  riseStartMs: 120,
  riseEndMs: 2_200,
  lightStartMs: 2_350,
  coreStartMs: 2_750,
  fullyLitMs: 4_050,
  captionStartMs: 4_150
});

export const CHAPTER_FOUR_STAR_LAMP_REDUCED_SEQUENCE = Object.freeze({
  durationMs: 3_600,
  revealEndMs: 200,
  lightStartMs: 850,
  coreStartMs: 1_300,
  fullyLitMs: 2_500,
  captionStartMs: 2_650
});

export const CHAPTER_FOUR_STAR_LAMP_MAX_LIGHT_LEVELS = Object.freeze({
  leds: 0.7,
  core: 0.62,
  glow: 0.26
});

const CAMERA_START = Object.freeze({
  radius: 12.4,
  height: -5.8,
  lookAtHeight: -4.1,
  artworkOffsetY: -22,
  artworkScale: 1.16
});

const CAMERA_END = Object.freeze({
  radius: 15.8,
  height: 0.35,
  lookAtHeight: 0.25,
  artworkOffsetY: 0,
  artworkScale: 0.92
});

export type ChapterFourStarLampSequencePhase =
  | "reveal_dark"
  | "rise_dark"
  | "front_dark_hold"
  | "ignite_leds"
  | "ignite_core"
  | "radiant_hold"
  | "complete";

export interface ChapterFourStarLampSequenceFrame {
  elapsedMs: number;
  durationMs: number;
  progress: number;
  phase: ChapterFourStarLampSequencePhase;
  sceneReveal: number;
  cameraRiseProgress: number;
  cameraRadius: number;
  cameraHeight: number;
  cameraLookAtHeight: number;
  artworkOffsetY: number;
  artworkScale: number;
  ledLevel: number;
  coreLevel: number;
  glowLevel: number;
  starfieldLevel: number;
  captionLevel: number;
  reducedMotion: boolean;
}

export interface ChapterFourStarLampCameraPose {
  x: number;
  y: number;
  z: number;
}

export function resolveChapterFourStarLampSequenceFrame(
  elapsedMs: number,
  reducedMotion = false
): ChapterFourStarLampSequenceFrame {
  const durationMs = reducedMotion
    ? CHAPTER_FOUR_STAR_LAMP_REDUCED_SEQUENCE.durationMs
    : CHAPTER_FOUR_STAR_LAMP_SEQUENCE.durationMs;
  const time = clamp(elapsedMs, 0, durationMs);
  const progress = time / durationMs;
  const revealEndMs = reducedMotion
    ? CHAPTER_FOUR_STAR_LAMP_REDUCED_SEQUENCE.revealEndMs
    : CHAPTER_FOUR_STAR_LAMP_SEQUENCE.revealEndMs;
  const sceneReveal = smootherStep(time / revealEndMs);

  if (reducedMotion) {
    const sequence = CHAPTER_FOUR_STAR_LAMP_REDUCED_SEQUENCE;
    const ledLevel = smootherStep((time - sequence.lightStartMs) / 620)
      * CHAPTER_FOUR_STAR_LAMP_MAX_LIGHT_LEVELS.leds;
    const coreLevel = smootherStep((time - sequence.coreStartMs) / 650)
      * CHAPTER_FOUR_STAR_LAMP_MAX_LIGHT_LEVELS.core;
    const glowLevel = smootherStep((time - sequence.coreStartMs - 160) / 760)
      * CHAPTER_FOUR_STAR_LAMP_MAX_LIGHT_LEVELS.glow;
    const captionLevel = smootherStep((time - sequence.captionStartMs) / 280);
    return {
      elapsedMs: time,
      durationMs,
      progress,
      phase: selectPhase(time, {
        durationMs,
        riseStartMs: sequence.revealEndMs,
        riseEndMs: sequence.lightStartMs - 120,
        lightStartMs: sequence.lightStartMs,
        coreStartMs: sequence.coreStartMs,
        fullyLitMs: sequence.fullyLitMs
      }),
      sceneReveal,
      cameraRiseProgress: 1,
      cameraRadius: CAMERA_END.radius,
      cameraHeight: CAMERA_END.height,
      cameraLookAtHeight: CAMERA_END.lookAtHeight,
      artworkOffsetY: CAMERA_END.artworkOffsetY,
      artworkScale: CAMERA_END.artworkScale,
      ledLevel,
      coreLevel,
      glowLevel,
      starfieldLevel: 0.68 + glowLevel * 0.12,
      captionLevel,
      reducedMotion: true
    };
  }

  const sequence = CHAPTER_FOUR_STAR_LAMP_SEQUENCE;
  const cameraRiseProgress = smootherStep(
    (time - sequence.riseStartMs) / (sequence.riseEndMs - sequence.riseStartMs)
  );
  const ledLevel = smootherStep((time - sequence.lightStartMs) / 780)
    * CHAPTER_FOUR_STAR_LAMP_MAX_LIGHT_LEVELS.leds;
  const coreLevel = smootherStep((time - sequence.coreStartMs) / 800)
    * CHAPTER_FOUR_STAR_LAMP_MAX_LIGHT_LEVELS.core;
  const glowLevel = smootherStep((time - sequence.coreStartMs - 180) / 960)
    * CHAPTER_FOUR_STAR_LAMP_MAX_LIGHT_LEVELS.glow;
  const captionLevel = smootherStep((time - sequence.captionStartMs) / 300);
  return {
    elapsedMs: time,
    durationMs,
    progress,
    phase: selectPhase(time, sequence),
    sceneReveal,
    cameraRiseProgress,
    cameraRadius: lerp(CAMERA_START.radius, CAMERA_END.radius, cameraRiseProgress),
    cameraHeight: lerp(CAMERA_START.height, CAMERA_END.height, cameraRiseProgress),
    cameraLookAtHeight: lerp(
      CAMERA_START.lookAtHeight,
      CAMERA_END.lookAtHeight,
      cameraRiseProgress
    ),
    artworkOffsetY: lerp(
      CAMERA_START.artworkOffsetY,
      CAMERA_END.artworkOffsetY,
      cameraRiseProgress
    ),
    artworkScale: lerp(
      CAMERA_START.artworkScale,
      CAMERA_END.artworkScale,
      cameraRiseProgress
    ),
    ledLevel,
    coreLevel,
    glowLevel,
    starfieldLevel: 0.68 + glowLevel * 0.12,
    captionLevel,
    reducedMotion: false
  };
}

export function resolveChapterFourStarLampCameraPose(
  frame: Pick<ChapterFourStarLampSequenceFrame, "cameraRadius" | "cameraHeight">
): ChapterFourStarLampCameraPose {
  return {
    x: 0,
    y: frame.cameraHeight,
    z: -frame.cameraRadius
  };
}

function selectPhase(
  time: number,
  sequence: Readonly<{
    durationMs: number;
    riseStartMs: number;
    riseEndMs: number;
    lightStartMs: number;
    coreStartMs: number;
    fullyLitMs: number;
  }>
): ChapterFourStarLampSequencePhase {
  if (time >= sequence.durationMs) return "complete";
  if (time >= sequence.fullyLitMs) return "radiant_hold";
  if (time >= sequence.coreStartMs) return "ignite_core";
  if (time >= sequence.lightStartMs) return "ignite_leds";
  if (time >= sequence.riseEndMs) return "front_dark_hold";
  if (time >= sequence.riseStartMs) return "rise_dark";
  return "reveal_dark";
}

function lerp(start: number, end: number, progress: number): number {
  return start + (end - start) * progress;
}

function smootherStep(value: number): number {
  const t = clamp(value, 0, 1);
  return t * t * t * (t * (t * 6 - 15) + 10);
}

function clamp(value: number, minimum: number, maximum: number): number {
  return Math.min(maximum, Math.max(minimum, value));
}
