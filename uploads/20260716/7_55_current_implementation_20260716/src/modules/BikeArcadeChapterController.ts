import type { EventBus } from "../core/EventBus";
import type { GameState, GameStore } from "../core/types";

const BIKE_ARCADE_GOAL = 755;
const BIKE_ARCADE_MAX_LIVES = 3;

interface ActiveAttempt {
  attempt: number;
  distance: number;
  lives: number;
}

/** Maintains chapter progress and emits domain events for presentation layers. */
export class BikeArcadeChapterController {
  private activeAttempt: ActiveAttempt | null = null;

  constructor(
    private readonly store: GameStore,
    private readonly events: EventBus
  ) {}

  syncUnlock(): boolean {
    const state = this.store.getState();
    return state.bikeArcade.unlocked;
  }

  startAttempt(): boolean {
    if (this.activeAttempt !== null || !this.syncUnlock()) {
      return false;
    }

    const attemptCount = this.store.getState().bikeArcade.attemptCount;
    if (!Number.isSafeInteger(attemptCount) || attemptCount < 0 || attemptCount >= Number.MAX_SAFE_INTEGER) {
      return false;
    }

    const attempt = attemptCount + 1;
    this.activeAttempt = {
      attempt,
      distance: 0,
      lives: BIKE_ARCADE_MAX_LIVES
    };
    this.events.emit("bike_arcade_run_started", { attempt });
    return true;
  }

  recordProgress(distance: number, lives: number): boolean {
    const active = this.activeAttempt;
    if (
      active === null ||
      !this.canContinue(active) ||
      !isDistance(distance) ||
      !isLives(lives) ||
      distance < active.distance ||
      lives > active.lives ||
      (distance === active.distance && lives === active.lives)
    ) {
      return false;
    }

    this.activeAttempt = { ...active, distance, lives };
    this.events.emit("bike_arcade_progress_recorded", {
      attempt: active.attempt,
      distance,
      lives
    });
    return true;
  }

  cancelAttempt(): boolean {
    const active = this.activeAttempt;
    if (active === null) {
      return false;
    }

    this.activeAttempt = null;
    this.events.emit("bike_arcade_attempt_cancelled", {
      attempt: active.attempt,
      distance: active.distance,
      lives: active.lives
    });
    return true;
  }

  completeAttempt(lives = this.activeAttempt?.lives): boolean {
    const active = this.activeAttempt;
    if (
      active === null ||
      !this.canContinue(active) ||
      active.distance < BIKE_ARCADE_GOAL ||
      !isWinningLives(lives) ||
      lives > active.lives
    ) {
      return false;
    }

    const chapter = this.store.getState().bikeArcade;
    this.patch({
      completed: true,
      attemptCount: active.attempt,
      bestDistance: BIKE_ARCADE_GOAL,
      bestLives: Math.max(chapter.bestLives, lives)
    });
    this.activeAttempt = null;
    this.events.emit("bike_arcade_won", { attempt: active.attempt, lives });
    if (!chapter.completed) {
      this.events.emit("bike_arcade_completed");
    }
    return true;
  }

  failAttempt(distance = this.activeAttempt?.distance): boolean {
    const active = this.activeAttempt;
    if (
      active === null ||
      !this.canContinue(active) ||
      active.lives !== 0 ||
      !isDistance(distance) ||
      distance >= BIKE_ARCADE_GOAL
    ) {
      return false;
    }

    const settledDistance = Math.max(active.distance, distance);
    const chapter = this.store.getState().bikeArcade;
    this.patch({
      attemptCount: active.attempt,
      bestDistance: Math.max(chapter.bestDistance, settledDistance)
    });
    this.activeAttempt = null;
    this.events.emit("bike_arcade_lost", {
      attempt: active.attempt,
      distance: settledDistance
    });
    return true;
  }

  private canContinue(active: ActiveAttempt): boolean {
    const state = this.store.getState();
    return isChapterUnlocked(state) && state.bikeArcade.attemptCount + 1 === active.attempt;
  }

  private patch(patch: Partial<GameState["bikeArcade"]>): void {
    this.store.setState((state) => ({
      ...state,
      bikeArcade: { ...state.bikeArcade, ...patch }
    }));
  }
}

function isChapterUnlocked(state: GameState): boolean {
  return state.bikeArcade.unlocked;
}

function isDistance(value: unknown): value is number {
  return typeof value === "number" && Number.isFinite(value) && value >= 0 && value <= BIKE_ARCADE_GOAL;
}

function isLives(value: unknown): value is number {
  return typeof value === "number" && Number.isInteger(value) && value >= 0 && value <= BIKE_ARCADE_MAX_LIVES;
}

function isWinningLives(value: unknown): value is number {
  return isLives(value) && value > 0;
}
