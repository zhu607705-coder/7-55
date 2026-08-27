import type { ChapterFourMaintenanceGuardMode } from "./ChapterFourGuardModel";

export type ChapterFourGuardPresentationPhase =
  | "patrol_walk"
  | "notice"
  | "turn_confirm"
  | "pursue"
  | "short_sight_loss"
  | "last_seen_search"
  | "return_to_patrol"
  | "reacquire";

export type ChapterFourGuardPresentationDirection = "side" | "up" | "down";

export type ChapterFourGuardPresentationAnimationId =
  | "guard_walk"
  | "guard_walk_down"
  | "guard_walk_up"
  | "guard_check_list"
  | "guard_check_watch"
  | "guard_flashlight_down"
  | "guard_radio";

export interface ChapterFourGuardPresentationState {
  phase: ChapterFourGuardPresentationPhase;
  phaseElapsedMs: number;
  direction: ChapterFourGuardPresentationDirection;
  flipX: boolean;
  visualHeading: { x: number; y: number };
  previousAuthorityMode: ChapterFourMaintenanceGuardMode;
  playerWasVisible: boolean;
}

export interface ChapterFourGuardPresentationInput {
  deltaMs: number;
  authorityMode: ChapterFourMaintenanceGuardMode;
  playerVisible: boolean;
  enteredPursuit: boolean;
  disengaged: boolean;
  desiredMotion: { x: number; y: number };
  authorityHeading: { x: number; y: number };
  patrolIdleVariant: "list" | "watch";
}

export interface ChapterFourGuardPresentationResult {
  state: ChapterFourGuardPresentationState;
  animationId: ChapterFourGuardPresentationAnimationId;
  alertText: "" | "!" | "?";
  alertVisible: boolean;
  visionColor: number;
  visionConeAlpha: number;
  visionCloseAlpha: number;
  visionRangeScale: number;
}

export const CHAPTER_FOUR_GUARD_PRESENTATION_RULES = Object.freeze({
  noticeMs: 150,
  reacquireMs: 180,
  lastSeenSearchMs: 420,
  radioMs: 440,
  movementThreshold: 8,
  directionSwitchRatio: 1.28
});

export function createChapterFourGuardPresentationState(): ChapterFourGuardPresentationState {
  return {
    phase: "patrol_walk",
    phaseElapsedMs: 0,
    direction: "side",
    flipX: true,
    visualHeading: { x: -1, y: 0 },
    previousAuthorityMode: "patrol",
    playerWasVisible: false
  };
}

export function stepChapterFourGuardPresentation(
  source: ChapterFourGuardPresentationState,
  input: ChapterFourGuardPresentationInput
): ChapterFourGuardPresentationResult {
  const deltaMs = Math.max(0, Number.isFinite(input.deltaMs) ? input.deltaMs : 0);
  const phase = selectPresentationPhase(source, input, deltaMs);
  const phaseElapsedMs = phase === source.phase ? source.phaseElapsedMs + deltaMs : 0;
  const facing = selectStableFacing(source, input, phase);
  const state: ChapterFourGuardPresentationState = {
    phase,
    phaseElapsedMs,
    direction: facing.direction,
    flipX: facing.flipX,
    visualHeading: facing.visualHeading,
    previousAuthorityMode: input.authorityMode,
    playerWasVisible: input.playerVisible
  };
  const animationId = selectAnimation(state, input);
  const vision = selectVisionPresentation(phase);
  const alertText = phase === "short_sight_loss" || phase === "last_seen_search"
    ? "?"
    : phase === "notice" || phase === "turn_confirm" || phase === "reacquire"
      ? "!"
      : "";
  return {
    state,
    animationId,
    alertText,
    alertVisible: alertText.length > 0,
    ...vision
  };
}

function selectPresentationPhase(
  source: ChapterFourGuardPresentationState,
  input: ChapterFourGuardPresentationInput,
  deltaMs: number
): ChapterFourGuardPresentationPhase {
  if (input.authorityMode === "confirming") {
    if (source.previousAuthorityMode !== "confirming") return "notice";
    if (source.phase === "notice"
      && source.phaseElapsedMs + deltaMs < CHAPTER_FOUR_GUARD_PRESENTATION_RULES.noticeMs) {
      return "notice";
    }
    return "turn_confirm";
  }
  if (input.authorityMode === "pursuit") {
    if (!input.playerVisible) return "short_sight_loss";
    if (source.phase === "short_sight_loss" || source.playerWasVisible === false) {
      return input.enteredPursuit ? "pursue" : "reacquire";
    }
    if (source.phase === "reacquire"
      && source.phaseElapsedMs + deltaMs < CHAPTER_FOUR_GUARD_PRESENTATION_RULES.reacquireMs) {
      return "reacquire";
    }
    return "pursue";
  }
  if (input.authorityMode === "returning") {
    if (input.disengaged || source.previousAuthorityMode !== "returning") {
      return "last_seen_search";
    }
    if (source.phase === "last_seen_search"
      && source.phaseElapsedMs + deltaMs < CHAPTER_FOUR_GUARD_PRESENTATION_RULES.lastSeenSearchMs) {
      return "last_seen_search";
    }
    return "return_to_patrol";
  }
  return "patrol_walk";
}

function selectStableFacing(
  source: ChapterFourGuardPresentationState,
  input: ChapterFourGuardPresentationInput,
  phase: ChapterFourGuardPresentationPhase
): Pick<ChapterFourGuardPresentationState, "direction" | "flipX" | "visualHeading"> {
  const phaseJustChanged = phase !== source.phase;
  if ((phase === "notice" || phase === "reacquire") && phaseJustChanged) {
    return facingFromVector(input.authorityHeading, source, false);
  }
  if (phase === "turn_confirm" || phase === "short_sight_loss" || phase === "last_seen_search") {
    return copyFacing(source);
  }
  return facingFromVector(input.desiredMotion, source, true);
}

function facingFromVector(
  vector: { x: number; y: number },
  source: ChapterFourGuardPresentationState,
  useHysteresis: boolean
): Pick<ChapterFourGuardPresentationState, "direction" | "flipX" | "visualHeading"> {
  const absX = Math.abs(vector.x);
  const absY = Math.abs(vector.y);
  const speed = Math.hypot(vector.x, vector.y);
  const threshold = useHysteresis
    ? CHAPTER_FOUR_GUARD_PRESENTATION_RULES.movementThreshold
    : 0.001;
  if (!Number.isFinite(speed) || speed < threshold) {
    return copyFacing(source);
  }
  const ratio = useHysteresis ? CHAPTER_FOUR_GUARD_PRESENTATION_RULES.directionSwitchRatio : 1;
  let direction = source.direction;
  if (source.direction === "side") {
    if (absY > absX * ratio) direction = vector.y < 0 ? "up" : "down";
  } else if (absX > absY * ratio) {
    direction = "side";
  } else if (absY >= threshold) {
    direction = vector.y < 0 ? "up" : "down";
  }
  const flipX = direction === "side" ? vector.x < 0 : false;
  return {
    direction,
    flipX,
    visualHeading: direction === "side"
      ? { x: flipX ? -1 : 1, y: 0 }
      : { x: 0, y: direction === "up" ? -1 : 1 }
  };
}

function copyFacing(
  source: ChapterFourGuardPresentationState
): Pick<ChapterFourGuardPresentationState, "direction" | "flipX" | "visualHeading"> {
  return {
    direction: source.direction,
    flipX: source.flipX,
    visualHeading: { ...source.visualHeading }
  };
}

function selectAnimation(
  state: ChapterFourGuardPresentationState,
  input: ChapterFourGuardPresentationInput
): ChapterFourGuardPresentationAnimationId {
  if (state.phase === "notice") return "guard_check_list";
  if (state.phase === "turn_confirm"
    || state.phase === "short_sight_loss"
    || state.phase === "last_seen_search") {
    return "guard_flashlight_down";
  }
  if (state.phase === "reacquire"
    || (state.phase === "pursue"
      && state.phaseElapsedMs < CHAPTER_FOUR_GUARD_PRESENTATION_RULES.radioMs)) {
    return "guard_radio";
  }
  if (Math.hypot(input.desiredMotion.x, input.desiredMotion.y)
    < CHAPTER_FOUR_GUARD_PRESENTATION_RULES.movementThreshold) {
    return input.patrolIdleVariant === "watch" ? "guard_check_watch" : "guard_check_list";
  }
  if (state.direction === "up") return "guard_walk_up";
  if (state.direction === "down") return "guard_walk_down";
  return "guard_walk";
}

function selectVisionPresentation(
  phase: ChapterFourGuardPresentationPhase
): Pick<
  ChapterFourGuardPresentationResult,
  "visionColor" | "visionConeAlpha" | "visionCloseAlpha" | "visionRangeScale"
> {
  if (phase === "pursue" || phase === "reacquire") {
    return {
      visionColor: 0xff3e4d,
      visionConeAlpha: phase === "reacquire" ? 0.28 : 0.24,
      visionCloseAlpha: 0.28,
      visionRangeScale: 1
    };
  }
  if (phase === "notice" || phase === "turn_confirm") {
    return {
      visionColor: 0xff8d52,
      visionConeAlpha: phase === "turn_confirm" ? 0.22 : 0.19,
      visionCloseAlpha: 0.24,
      visionRangeScale: 1
    };
  }
  if (phase === "short_sight_loss" || phase === "last_seen_search") {
    return {
      visionColor: 0xff8d52,
      visionConeAlpha: 0.17,
      visionCloseAlpha: 0.18,
      visionRangeScale: phase === "last_seen_search" ? 0.78 : 0.9
    };
  }
  return {
    visionColor: 0xffc857,
    visionConeAlpha: phase === "return_to_patrol" ? 0.12 : 0.16,
    visionCloseAlpha: 0.14,
    visionRangeScale: 1
  };
}
