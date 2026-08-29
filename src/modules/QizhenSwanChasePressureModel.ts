export type QizhenSwanChasePressurePhase =
  | "release_warning"
  | "tracking"
  | "charge_warning"
  | "charge"
  | "recovery";

export type QizhenSwanChaseSegment = "opening" | "mid_channel" | "final_bank";

export type QizhenSwanChaseDangerBand = "safe" | "pressured" | "critical";

export type QizhenSwanChaseCue = "none" | "release" | "telegraph" | "surge" | "final_bank";

export interface QizhenSwanChasePressureState {
  phase: QizhenSwanChasePressurePhase;
  phaseElapsedMs: number;
  cycleIndex: number;
  aimY: number;
  segment: QizhenSwanChaseSegment;
}

export interface QizhenSwanChasePressureInput {
  deltaMs: number;
  elapsedSeconds: number;
  actualGap: number;
  catchDistance: number;
  nearDistance: number;
  farDistance: number;
  catchReady: boolean;
  progressRatio: number;
  playerY: number;
}

export interface QizhenSwanChaseSpeedProfile {
  near: number;
  far: number;
}

export interface QizhenSwanChasePressureResult {
  state: QizhenSwanChasePressureState;
  phaseChanged: boolean;
  segmentChanged: boolean;
  dangerBand: QizhenSwanChaseDangerBand;
  riskRatio: number;
  targetSpeed: number;
  speedProfile: QizhenSwanChaseSpeedProfile;
  lateralSwayScale: number;
  visualIntensityBoost: number;
  wingBeatPeriodMs: number;
  cue: QizhenSwanChaseCue;
}

export const QIZHEN_SWAN_CHASE_PRESSURE_RULES = Object.freeze({
  releaseWarningMs: 1100,
  firstTelegraphAtMs: 2700,
  openingTrackingMs: 1900,
  midTrackingMs: 1580,
  finalTrackingMs: 980,
  chargeWarningMs: 620,
  chargeMs: 560,
  recoveryMs: 760,
  chargeGapPadding: 18,
  chargeMaxGapPadding: 24,
  finalSegmentRatio: 0.78,
  openingSegmentRatio: 0.24,
  pressuredGapRatio: 0.57,
  criticalGapPadding: 22
});

const SPEED_PROFILES: Readonly<Record<QizhenSwanChasePressurePhase, QizhenSwanChaseSpeedProfile>> =
  Object.freeze({
    release_warning: Object.freeze({ near: 90, far: 348 }),
    tracking: Object.freeze({ near: 168, far: 440 }),
    charge_warning: Object.freeze({ near: 142, far: 348 }),
    charge: Object.freeze({ near: 268, far: 500 }),
    recovery: Object.freeze({ near: 132, far: 352 })
  });

export function createQizhenSwanChasePressureState(playerY: number): QizhenSwanChasePressureState {
  return {
    phase: "release_warning",
    phaseElapsedMs: 0,
    cycleIndex: 0,
    aimY: finiteOr(playerY, 0),
    segment: "opening"
  };
}

export function stepQizhenSwanChasePressure(
  source: QizhenSwanChasePressureState,
  input: QizhenSwanChasePressureInput
): QizhenSwanChasePressureResult {
  const deltaMs = clamp(finiteOr(input.deltaMs, 0), 0, 100);
  const progressRatio = clamp(finiteOr(input.progressRatio, 0), 0, 1);
  const segment = resolveQizhenSwanChaseSegment(progressRatio);
  const phase = selectPressurePhase(source, input, deltaMs, segment);
  const phaseChanged = phase !== source.phase;
  const segmentChanged = segment !== source.segment;
  const phaseElapsedMs = phaseChanged ? 0 : source.phaseElapsedMs + deltaMs;
  const cycleIndex = source.cycleIndex + Number(source.phase === "recovery" && phase === "tracking");
  const playerY = finiteOr(input.playerY, source.aimY);
  const aimY = phase === "charge_warning" && phaseChanged
    ? playerY
    : phase === "charge_warning" || phase === "charge"
      ? source.aimY
      : approach(source.aimY, playerY, 1 - Math.exp(-5.4 * deltaMs / 1000));
  const state: QizhenSwanChasePressureState = {
    phase,
    phaseElapsedMs,
    cycleIndex,
    aimY,
    segment
  };
  const danger = resolveQizhenSwanChaseDanger(
    input.actualGap,
    input.catchDistance,
    input.nearDistance,
    input.farDistance
  );
  const speedProfile = resolveQizhenSwanChaseSpeedProfile(phase, segment);
  const distanceFactor = smoothstep(clamp(
    (finiteOr(input.actualGap, input.farDistance) - input.nearDistance)
      / Math.max(1, input.farDistance - input.nearDistance),
    0,
    1
  ));
  const targetSpeed = approach(speedProfile.near, speedProfile.far, distanceFactor);
  return {
    state,
    phaseChanged,
    segmentChanged,
    ...danger,
    targetSpeed,
    speedProfile,
    lateralSwayScale: resolveLateralSwayScale(phase),
    visualIntensityBoost: resolveVisualIntensityBoost(phase, segment),
    wingBeatPeriodMs: resolveWingBeatPeriodMs(phase, segment),
    cue: resolveCue(source, state, phaseChanged, segmentChanged)
  };
}

export function resolveQizhenSwanChaseSpeedProfile(
  phase: QizhenSwanChasePressurePhase,
  segment: QizhenSwanChaseSegment
): QizhenSwanChaseSpeedProfile {
  const base = SPEED_PROFILES[phase];
  if (segment !== "final_bank" || phase === "release_warning" || phase === "charge_warning") {
    return { ...base };
  }
  const nearBoost = phase === "charge" ? 18 : 12;
  const farBoost = phase === "charge" ? 20 : 14;
  return {
    near: base.near + nearBoost,
    far: base.far + farBoost
  };
}

export function resolveQizhenSwanChaseDanger(
  actualGap: number,
  catchDistance: number,
  nearDistance: number,
  farDistance: number
): Pick<QizhenSwanChasePressureResult, "dangerBand" | "riskRatio"> {
  const safeCatchDistance = finiteOr(catchDistance, 0);
  const safeNearDistance = Math.max(safeCatchDistance + 1, finiteOr(nearDistance, safeCatchDistance + 1));
  const safeFarDistance = Math.max(safeNearDistance + 1, finiteOr(farDistance, safeNearDistance + 1));
  const gap = finiteOr(actualGap, safeFarDistance);
  const riskRatio = 1 - clamp(
    (gap - safeCatchDistance) / Math.max(1, safeFarDistance - safeCatchDistance),
    0,
    1
  );
  if (gap <= safeNearDistance + QIZHEN_SWAN_CHASE_PRESSURE_RULES.criticalGapPadding) {
    return { dangerBand: "critical", riskRatio };
  }
  const pressuredGap = safeCatchDistance
    + (safeFarDistance - safeCatchDistance) * QIZHEN_SWAN_CHASE_PRESSURE_RULES.pressuredGapRatio;
  if (gap <= pressuredGap) return { dangerBand: "pressured", riskRatio };
  return { dangerBand: "safe", riskRatio };
}

export function resolveQizhenSwanChaseSegment(progressRatio: number): QizhenSwanChaseSegment {
  const progress = clamp(finiteOr(progressRatio, 0), 0, 1);
  if (progress >= QIZHEN_SWAN_CHASE_PRESSURE_RULES.finalSegmentRatio) return "final_bank";
  if (progress >= QIZHEN_SWAN_CHASE_PRESSURE_RULES.openingSegmentRatio) return "mid_channel";
  return "opening";
}

function selectPressurePhase(
  source: QizhenSwanChasePressureState,
  input: QizhenSwanChasePressureInput,
  deltaMs: number,
  segment: QizhenSwanChaseSegment
): QizhenSwanChasePressurePhase {
  const elapsedMs = Math.max(0, finiteOr(input.elapsedSeconds, 0) * 1000);
  if (elapsedMs < QIZHEN_SWAN_CHASE_PRESSURE_RULES.releaseWarningMs) return "release_warning";
  const phaseElapsedAfterStep = source.phaseElapsedMs + deltaMs;
  if (source.phase === "release_warning") return "tracking";
  if (source.phase === "charge_warning") {
    if (!input.catchReady) return "charge_warning";
    return phaseElapsedAfterStep >= QIZHEN_SWAN_CHASE_PRESSURE_RULES.chargeWarningMs
      ? "charge"
      : "charge_warning";
  }
  const minChargeGap = finiteOr(input.catchDistance, 0)
    + QIZHEN_SWAN_CHASE_PRESSURE_RULES.chargeGapPadding;
  const maxChargeGap = finiteOr(input.farDistance, 360)
    + QIZHEN_SWAN_CHASE_PRESSURE_RULES.chargeMaxGapPadding;
  const actualGap = finiteOr(input.actualGap, maxChargeGap + 1);
  const chargeGapIsReadable = actualGap >= minChargeGap && actualGap <= maxChargeGap;
  if (!input.catchReady) {
    const firstTelegraphIsDue = source.phase === "tracking"
      && source.cycleIndex === 0
      && elapsedMs >= QIZHEN_SWAN_CHASE_PRESSURE_RULES.firstTelegraphAtMs
      && chargeGapIsReadable;
    return firstTelegraphIsDue ? "charge_warning" : "tracking";
  }
  if (source.phase === "charge") {
    return phaseElapsedAfterStep >= QIZHEN_SWAN_CHASE_PRESSURE_RULES.chargeMs
      ? "recovery"
      : "charge";
  }
  if (source.phase === "recovery") {
    return phaseElapsedAfterStep >= QIZHEN_SWAN_CHASE_PRESSURE_RULES.recoveryMs
      ? "tracking"
      : "recovery";
  }
  const trackingMs = segment === "final_bank"
    ? QIZHEN_SWAN_CHASE_PRESSURE_RULES.finalTrackingMs
    : segment === "mid_channel"
      ? QIZHEN_SWAN_CHASE_PRESSURE_RULES.midTrackingMs
      : QIZHEN_SWAN_CHASE_PRESSURE_RULES.openingTrackingMs;
  if (phaseElapsedAfterStep >= trackingMs && chargeGapIsReadable) {
    return "charge_warning";
  }
  return "tracking";
}

function resolveCue(
  source: QizhenSwanChasePressureState,
  state: QizhenSwanChasePressureState,
  phaseChanged: boolean,
  segmentChanged: boolean
): QizhenSwanChaseCue {
  if (segmentChanged && state.segment === "final_bank") return "final_bank";
  if (!phaseChanged) return "none";
  if (state.phase === "release_warning" && source.phase !== "release_warning") return "release";
  if (state.phase === "charge_warning") return "telegraph";
  if (state.phase === "charge") return "surge";
  return "none";
}

function resolveLateralSwayScale(phase: QizhenSwanChasePressurePhase): number {
  if (phase === "release_warning") return 0.3;
  if (phase === "charge_warning") return 0.08;
  if (phase === "charge") return 0.02;
  if (phase === "recovery") return 0.5;
  return 1;
}

function resolveVisualIntensityBoost(
  phase: QizhenSwanChasePressurePhase,
  segment: QizhenSwanChaseSegment
): number {
  const phaseBoost = phase === "charge"
    ? 0.2
    : phase === "charge_warning"
      ? 0.1
      : phase === "recovery"
        ? -0.08
        : 0;
  return phaseBoost + (segment === "final_bank" ? 0.08 : 0);
}

function resolveWingBeatPeriodMs(
  phase: QizhenSwanChasePressurePhase,
  segment: QizhenSwanChaseSegment
): number {
  const base = phase === "charge"
    ? 54
    : phase === "charge_warning"
      ? 76
      : phase === "recovery"
        ? 126
        : phase === "release_warning"
          ? 138
          : 102;
  return Math.max(46, base - (segment === "final_bank" ? 10 : 0));
}

function smoothstep(value: number): number {
  return value * value * (3 - 2 * value);
}

function approach(from: number, to: number, ratio: number): number {
  return from + (to - from) * clamp(ratio, 0, 1);
}

function finiteOr(value: number, fallback: number): number {
  return Number.isFinite(value) ? value : fallback;
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}
