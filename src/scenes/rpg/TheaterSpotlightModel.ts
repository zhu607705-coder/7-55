export type TheaterSpotlightLane = "left" | "center" | "right";

export type TheaterSpotlightFailureReason =
  | "round_mismatch"
  | "wrong_lane"
  | "beam_not_activated"
  | "early"
  | "late"
  | "interrupted"
  | "timeout"
  | "invalid_attempt";

export interface TheaterSpotlightPoint {
  readonly x: number;
  readonly y: number;
}

export interface TheaterSpotlightAttempt {
  /** Zero-based round index. It must match theaterHunt.spotlightRound. */
  readonly round: number;
  readonly lane: TheaterSpotlightLane;
  readonly maxContinuousLockMs: number;
  readonly beamActivated: boolean;
  /** Milliseconds from the start of the action window; null when the beam never fired. */
  readonly firstBeamAtMs: number | null;
  /** The action-window duration used by the scene for this attempt. */
  readonly actionMs: number;
  /** Milliseconds elapsed in the action window when the scene submitted the attempt. */
  readonly submittedAtMs: number;
}

export interface TheaterSpotlightRoundConfig {
  readonly round: 0 | 1 | 2;
  readonly lane: TheaterSpotlightLane;
  readonly previewMs: number;
  readonly actionMs: number;
  readonly requiredLockMs: number;
  readonly beamRadius: number;
  readonly pathKind: "direct" | "broken_decoy" | "lamp_boundary";
  readonly pathPoints: readonly TheaterSpotlightPoint[];
  readonly decoyPathPoints?: readonly TheaterSpotlightPoint[];
}

export interface TheaterSpotlightAssist {
  readonly active: boolean;
  readonly enabled: boolean;
  readonly previewBonusMs: number;
  readonly radiusScale: number;
  readonly lockScale: number;
}

const point = (x: number, y: number): TheaterSpotlightPoint => Object.freeze({ x, y });

/**
 * Paths use the spotlight-panel local coordinate system:
 * the center of the panel is (0, 0), x grows rightward and y grows downward.
 */
export const THEATER_SPOTLIGHT_ROUNDS: readonly TheaterSpotlightRoundConfig[] = Object.freeze([
  Object.freeze({
    round: 0,
    lane: "left",
    previewMs: 1200,
    actionMs: 3000,
    requiredLockMs: 300,
    beamRadius: 60,
    pathKind: "direct",
    pathPoints: Object.freeze([
      point(-340, -55),
      point(-300, -10),
      point(-265, 35),
      point(-230, 90)
    ])
  }),
  Object.freeze({
    round: 1,
    lane: "right",
    previewMs: 1000,
    actionMs: 2700,
    requiredLockMs: 420,
    beamRadius: 54,
    pathKind: "broken_decoy",
    pathPoints: Object.freeze([
      point(340, -55),
      point(285, -4),
      point(250, 44),
      point(230, 90)
    ]),
    decoyPathPoints: Object.freeze([
      point(-340, 20),
      point(-205, 40),
      point(-90, 64),
      point(0, 90)
    ])
  }),
  Object.freeze({
    round: 2,
    lane: "center",
    previewMs: 900,
    actionMs: 2500,
    requiredLockMs: 550,
    beamRadius: 48,
    pathKind: "lamp_boundary",
    pathPoints: Object.freeze([
      point(-340, -55),
      point(-210, -5),
      point(-112, 25),
      point(18, 58),
      point(0, 90)
    ])
  })
]);

export const THEATER_SPOTLIGHT_SEQUENCE: readonly TheaterSpotlightLane[] = Object.freeze(
  THEATER_SPOTLIGHT_ROUNDS.map(({ lane }) => lane)
);

const BASE_ASSIST: TheaterSpotlightAssist = Object.freeze({
  active: false,
  enabled: false,
  previewBonusMs: 0,
  radiusScale: 1,
  lockScale: 1
});

const FAILURE_ASSIST: TheaterSpotlightAssist = Object.freeze({
  active: true,
  enabled: true,
  previewBonusMs: 800,
  radiusScale: 1.2,
  lockScale: 1
});

/**
 * Three failed attempts unlock the authored accessibility assist. The controller
 * remains authoritative for progression; scenes use this only for presentation.
 */
export function getTheaterSpotlightAssist(mistakes: number): TheaterSpotlightAssist {
  return Number.isFinite(mistakes) && mistakes >= 3 ? FAILURE_ASSIST : BASE_ASSIST;
}

export function getTheaterSpotlightRound(
  round: number
): TheaterSpotlightRoundConfig | undefined {
  if (!Number.isInteger(round)) return undefined;
  return THEATER_SPOTLIGHT_ROUNDS[round];
}

export function isTheaterSpotlightLane(value: unknown): value is TheaterSpotlightLane {
  return value === "left" || value === "center" || value === "right";
}

export function getRequiredTheaterSpotlightLockMs(
  round: TheaterSpotlightRoundConfig,
  mistakes: number
): number {
  const assist = getTheaterSpotlightAssist(mistakes);
  return round.requiredLockMs * assist.lockScale;
}

/**
 * Pure validation shared by the story controller and the endless extractor.
 * It has no store, scene or timer dependency, so story progression retains
 * controller ownership while matching the measured scene payload exactly.
 */
export function validateTheaterSpotlightAttempt(
  attempt: TheaterSpotlightAttempt,
  round: TheaterSpotlightRoundConfig,
  requiredLockMs: number
): TheaterSpotlightFailureReason | null {
  if (!Number.isInteger(attempt.round) || attempt.round !== round.round) {
    return "round_mismatch";
  }
  if (
    !Number.isFinite(attempt.maxContinuousLockMs)
    || attempt.maxContinuousLockMs < 0
    || !Number.isFinite(attempt.actionMs)
    || attempt.actionMs <= 0
    || attempt.actionMs !== round.actionMs
    || !Number.isFinite(attempt.submittedAtMs)
    || attempt.submittedAtMs < 0
  ) {
    return "invalid_attempt";
  }
  if (!attempt.beamActivated || attempt.firstBeamAtMs === null) {
    return "beam_not_activated";
  }
  if (attempt.lane !== round.lane) return "wrong_lane";
  if (!Number.isFinite(attempt.firstBeamAtMs)) return "invalid_attempt";
  if (attempt.firstBeamAtMs < 0) return "early";
  if (
    attempt.firstBeamAtMs > attempt.submittedAtMs
    || attempt.firstBeamAtMs >= round.actionMs
    || attempt.submittedAtMs > round.actionMs
  ) {
    return "late";
  }
  if (attempt.maxContinuousLockMs < requiredLockMs) {
    if (attempt.firstBeamAtMs <= round.actionMs * 0.1) return "early";
    if (attempt.firstBeamAtMs + requiredLockMs > round.actionMs) return "late";
    return "interrupted";
  }
  return null;
}
