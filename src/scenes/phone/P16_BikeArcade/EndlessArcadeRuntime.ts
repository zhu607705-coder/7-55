import type Phaser from "phaser";
import type { EndlessChallengeModeId } from "../../../core/types";
import { ENDLESS_ARCADE_SCORE_LIMIT } from "../../../core/EndlessArcadeLimits";

export type EndlessArcadeViewPhase =
  | "hub"
  | "intro"
  | "loading"
  | "running"
  | "paused"
  | "confirm_exit"
  | "game_over"
  | "error";

export type EndlessArcadePauseReason =
  | "document_hidden"
  | "window_blur"
  | "control_center"
  | "player";

export type EndlessArcadeControlAction =
  | "primary"
  | "secondary"
  | "left"
  | "right"
  | "release_left"
  | "release_right"
  | "release_primary"
  | "release_secondary";

export interface EndlessArcadeRunSnapshot {
  mode: EndlessChallengeModeId;
  score: number;
  progress: number;
  tier: number;
  combo: number;
  lives?: number;
  status?: string;
}

export interface EndlessArcadeRunSummary extends EndlessArcadeRunSnapshot {
  durationMs: number;
}

export interface EndlessArcadeDebugSnapshot {
  unlocked: boolean;
  phase: EndlessArcadeViewPhase;
  selectedMode: EndlessChallengeModeId | null;
  activeRunId: string | null;
  activeAttempt: number | null;
  snapshot: EndlessArcadeRunSnapshot | null;
  summary: EndlessArcadeRunSummary | null;
}

export interface EndlessArcadeSceneBridge {
  readonly mode: EndlessChallengeModeId;
  readonly runId: string;
  readonly seed: number;
  readonly reducedMotion: boolean;
  publishSnapshot: (snapshot: EndlessArcadeRunSnapshot) => void;
  finish: (summary: EndlessArcadeRunSummary) => void;
  requestPause: (reason: EndlessArcadePauseReason) => void;
}

export interface EndlessArcadeControllableScene extends Phaser.Scene {
  handleEndlessControl?: (action: EndlessArcadeControlAction) => void;
  /**
   * Clears held keyboard, pointer and rhythm inputs without judging or
   * penalising them. The host calls this before pausing or destroying a scene
   * because keyup/pointerup events are not guaranteed while Phaser is paused.
   */
  releaseEndlessControls?: () => void;
  /** Runs scene-owned idempotent teardown before Phaser.Game destruction. */
  cleanupEndlessScene?: () => void;
  setEndlessAim?: (normalizedX: number) => void;
  moveLane?: (direction: -1 | 1) => void;
}

export function releaseEndlessArcadeSceneControls(
  scene: Pick<EndlessArcadeControllableScene, "releaseEndlessControls"> | null
): boolean {
  if (!scene?.releaseEndlessControls) return false;
  scene.releaseEndlessControls();
  return true;
}

export function cleanupEndlessArcadeScene(
  scene: Pick<EndlessArcadeControllableScene, "cleanupEndlessScene"> | null
): boolean {
  if (!scene?.cleanupEndlessScene) return false;
  scene.cleanupEndlessScene();
  return true;
}

export type EndlessArcadeSceneConstructor = new () => EndlessArcadeControllableScene;

export interface EndlessArcadeSceneModule {
  Scene: EndlessArcadeSceneConstructor;
  sceneKey: string;
}

export type EndlessArcadeHostStatus =
  | { kind: "loading" }
  | { kind: "running" }
  | { kind: "paused"; reason: EndlessArcadePauseReason }
  | { kind: "game_over"; summary: EndlessArcadeRunSummary }
  | { kind: "error"; error: EndlessArcadeRuntimeError };

export type EndlessArcadeRuntimeErrorCode =
  | "runtime_unavailable"
  | "invalid_scene_module"
  | "boot_timeout"
  | "boot_failed";

export class EndlessArcadeRuntimeError extends Error {
  readonly code: EndlessArcadeRuntimeErrorCode;
  readonly mode: EndlessChallengeModeId;

  constructor(
    code: EndlessArcadeRuntimeErrorCode,
    mode: EndlessChallengeModeId,
    message: string
  ) {
    super(message);
    this.name = "EndlessArcadeRuntimeError";
    this.code = code;
    this.mode = mode;
  }
}

export function normalizeEndlessRuntimeInteger(
  value: unknown,
  maximum = ENDLESS_ARCADE_SCORE_LIMIT
): number {
  if (!Number.isFinite(value) || !Number.isSafeInteger(value)) return 0;
  return Math.min(maximum, Math.max(0, value as number));
}

export function normalizeEndlessRunSnapshot(
  mode: EndlessChallengeModeId,
  snapshot: Partial<EndlessArcadeRunSnapshot>
): EndlessArcadeRunSnapshot {
  return {
    mode,
    score: normalizeEndlessRuntimeInteger(snapshot.score),
    progress: normalizeEndlessRuntimeInteger(snapshot.progress),
    tier: normalizeEndlessRuntimeInteger(snapshot.tier, 1_000_000),
    combo: normalizeEndlessRuntimeInteger(snapshot.combo, 1_000_000),
    lives: snapshot.lives === undefined
      ? undefined
      : normalizeEndlessRuntimeInteger(snapshot.lives, 99),
    status: typeof snapshot.status === "string" ? snapshot.status.slice(0, 48) : undefined
  };
}

export function normalizeEndlessRunSummary(
  mode: EndlessChallengeModeId,
  summary: Partial<EndlessArcadeRunSummary>
): EndlessArcadeRunSummary {
  return {
    ...normalizeEndlessRunSnapshot(mode, summary),
    durationMs: normalizeEndlessRuntimeInteger(summary.durationMs, 86_400_000)
  };
}

let currentEndlessArcadeDebugSnapshot: EndlessArcadeDebugSnapshot | null = null;

export function setEndlessArcadeDebugSnapshot(snapshot: EndlessArcadeDebugSnapshot): void {
  currentEndlessArcadeDebugSnapshot = {
    ...snapshot,
    snapshot: snapshot.snapshot ? { ...snapshot.snapshot } : null,
    summary: snapshot.summary ? { ...snapshot.summary } : null
  };
}

export function getEndlessArcadeDebugSnapshot(): EndlessArcadeDebugSnapshot | null {
  if (!currentEndlessArcadeDebugSnapshot) return null;
  return {
    ...currentEndlessArcadeDebugSnapshot,
    snapshot: currentEndlessArcadeDebugSnapshot.snapshot
      ? { ...currentEndlessArcadeDebugSnapshot.snapshot }
      : null,
    summary: currentEndlessArcadeDebugSnapshot.summary
      ? { ...currentEndlessArcadeDebugSnapshot.summary }
      : null
  };
}

export function clearEndlessArcadeDebugSnapshot(): void {
  currentEndlessArcadeDebugSnapshot = null;
}

export interface EndlessArcadeDestroyableRuntime {
  destroy: (removeCanvas: boolean) => void;
}

export interface EndlessArcadeRuntimeSlot<Runtime extends EndlessArcadeDestroyableRuntime> {
  current: Runtime | null;
}

/**
 * Installs the one active Phaser runtime after disposing any stale instance.
 * The slot is deliberately framework-neutral so the lifecycle contract can be
 * executed in Node without constructing React or Phaser.
 */
export function mountEndlessArcadeRuntime<Runtime extends EndlessArcadeDestroyableRuntime>(
  slot: EndlessArcadeRuntimeSlot<Runtime>,
  runtime: Runtime
): void {
  destroyEndlessArcadeRuntime(slot);
  slot.current = runtime;
}

/** Clears the slot before destroying so re-entrant and repeated cleanup is safe. */
export function destroyEndlessArcadeRuntime<Runtime extends EndlessArcadeDestroyableRuntime>(
  slot: EndlessArcadeRuntimeSlot<Runtime>
): boolean {
  const runtime = slot.current;
  slot.current = null;
  if (!runtime) return false;
  runtime.destroy(true);
  return true;
}

export function countActiveEndlessArcadeRuntimes<Runtime extends EndlessArcadeDestroyableRuntime>(
  slot: EndlessArcadeRuntimeSlot<Runtime>
): 0 | 1 {
  return slot.current === null ? 0 : 1;
}

export interface EndlessArcadeLifecycleEpochSlot {
  current: number;
}

/** Starts one mounted lifecycle generation, including React StrictMode probes. */
export function beginEndlessArcadeLifecycleEpoch(
  slot: EndlessArcadeLifecycleEpochSlot
): number {
  const epoch = slot.current + 1;
  slot.current = epoch;
  return epoch;
}

/**
 * A queued cleanup may cancel a controller ticket only if no newer lifecycle
 * setup has superseded it. This keeps the first real run alive in StrictMode.
 */
export function isCurrentEndlessArcadeLifecycleEpoch(
  slot: EndlessArcadeLifecycleEpochSlot,
  epoch: number
): boolean {
  return slot.current === epoch;
}
