import { describe, expect, it } from "vitest";
import { EventBus } from "../core/EventBus";
import { createGameStore, createInitialGameState } from "../core/GameState";
import type { BikeArcadeChapterState, LibraryFinalsPhase } from "../core/types";
import { BikeArcadeChapterController } from "./BikeArcadeChapterController";

function createSubject(
  phase: LibraryFinalsPhase = "friend_contacted",
  bikeArcadePatch: Partial<BikeArcadeChapterState> = { unlocked: true }
) {
  const initial = createInitialGameState();
  const store = createGameStore({
    ...initial,
    bikeArcade: { ...initial.bikeArcade, ...bikeArcadePatch },
    ui: { ...initial.ui, libraryFinalsPhase: phase }
  });
  const events = new EventBus();
  return {
    store,
    events,
    controller: new BikeArcadeChapterController(store, events)
  };
}

describe("BikeArcadeChapterController", () => {
  it("does not unlock the bike chapter from seat recovery or the 022 dialogue alone", () => {
    for (const phase of ["seat_recovered", "friend_contacted"] as LibraryFinalsPhase[]) {
      const { store, events, controller } = createSubject(phase, { unlocked: false });
      expect(controller.syncUnlock()).toBe(false);
      expect(controller.startAttempt()).toBe(false);
      expect(store.getState().bikeArcade.unlocked).toBe(false);
      expect(events.getHistory()).toEqual([]);
    }
  });

  it("starts only after an explicit later-chapter unlock", () => {
    const { events, controller } = createSubject("idle", { unlocked: true });
    expect(controller.syncUnlock()).toBe(true);
    expect(controller.startAttempt()).toBe(true);
    expect(events.getHistory()).toEqual([
      { name: "bike_arcade_run_started", payload: { attempt: 1 } }
    ]);
  });

  it("settles failed attempts and preserves the best failed distance", () => {
    const { store, events, controller } = createSubject();

    expect(controller.startAttempt()).toBe(true);
    expect(controller.recordProgress(420, 0)).toBe(true);
    expect(controller.failAttempt()).toBe(true);
    expect(store.getState().bikeArcade).toEqual({
      unlocked: true,
      completed: false,
      attemptCount: 1,
      bestDistance: 420,
      bestLives: 0
    });

    expect(controller.startAttempt()).toBe(true);
    expect(controller.recordProgress(200, 0)).toBe(true);
    expect(controller.failAttempt()).toBe(true);
    expect(store.getState().bikeArcade).toMatchObject({
      attemptCount: 2,
      bestDistance: 420,
      completed: false
    });
    expect(events.getHistory()).toEqual([
      { name: "bike_arcade_run_started", payload: { attempt: 1 } },
      { name: "bike_arcade_progress_recorded", payload: { attempt: 1, distance: 420, lives: 0 } },
      { name: "bike_arcade_lost", payload: { attempt: 1, distance: 420 } },
      { name: "bike_arcade_run_started", payload: { attempt: 2 } },
      { name: "bike_arcade_progress_recorded", payload: { attempt: 2, distance: 200, lives: 0 } },
      { name: "bike_arcade_lost", payload: { attempt: 2, distance: 200 } }
    ]);
  });

  it("cancels an active attempt without settling it and allows a fresh start", () => {
    const { store, events, controller } = createSubject();

    expect(controller.cancelAttempt()).toBe(false);
    expect(controller.startAttempt()).toBe(true);
    expect(controller.recordProgress(321, 2)).toBe(true);
    const chapterBeforeCancel = store.getState().bikeArcade;

    expect(controller.cancelAttempt()).toBe(true);
    expect(store.getState().bikeArcade).toBe(chapterBeforeCancel);
    expect(events.getHistory().at(-1)).toEqual({
      name: "bike_arcade_attempt_cancelled",
      payload: { attempt: 1, distance: 321, lives: 2 }
    });

    expect(controller.startAttempt()).toBe(true);
    expect(events.getHistory().at(-1)).toEqual({
      name: "bike_arcade_run_started",
      payload: { attempt: 1 }
    });
  });

  it("records a 755m win and lets a replay improve best lives", () => {
    const { store, events, controller } = createSubject();

    expect(controller.startAttempt()).toBe(true);
    expect(controller.recordProgress(755, 1)).toBe(true);
    expect(controller.completeAttempt()).toBe(true);
    expect(controller.completeAttempt()).toBe(false);

    expect(controller.startAttempt()).toBe(true);
    expect(controller.recordProgress(755, 3)).toBe(true);
    expect(controller.completeAttempt()).toBe(true);
    expect(store.getState().bikeArcade).toEqual({
      unlocked: true,
      completed: true,
      attemptCount: 2,
      bestDistance: 755,
      bestLives: 3
    });
    expect(events.getHistory().filter((event) => event.name === "bike_arcade_completed")).toHaveLength(1);
  });

  it("settles only a 755m success or a zero-life failure", () => {
    const { controller } = createSubject();

    expect(controller.startAttempt()).toBe(true);
    expect(controller.recordProgress(754, 3)).toBe(true);
    expect(controller.completeAttempt()).toBe(false);
    expect(controller.failAttempt()).toBe(false);
    expect(controller.recordProgress(754, 0)).toBe(true);
    expect(controller.failAttempt()).toBe(true);
  });
});
