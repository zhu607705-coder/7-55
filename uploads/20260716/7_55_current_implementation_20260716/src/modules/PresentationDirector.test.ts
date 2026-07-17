import { describe, expect, it } from "vitest";
import { EventBus } from "../core/EventBus";
import { createGameStore, createInitialGameState } from "../core/GameState";
import { LibraryFinalsController } from "./LibraryFinalsController";
import { PRESENTATION_CUE_EVENT, PresentationDirector } from "./PresentationDirector";

describe("PresentationDirector", () => {
  it("emits one stable cue when duplicate V2 domain events describe the same result", () => {
    const events = new EventBus();
    const initial = createInitialGameState();
    const store = createGameStore({
      ...initial,
      actOne: {
        ...initial.actOne,
        canLeaveDorm: true
      }
    });
    const director = new PresentationDirector();
    const detach = director.attach(store, events);
    const controller = new LibraryFinalsController(store, events);

    expect(controller.unlockLibraryRoute()).toBe(true);
    events.emit("library_route_unlocked", { destination: "foundation_library" });

    const cues = events.getHistory().filter((event) => event.name === PRESENTATION_CUE_EVENT);
    expect(cues).toEqual([
      {
        name: PRESENTATION_CUE_EVENT,
        payload: {
          cueId: "library_route_unlocked",
          source: "event",
          destination: "foundation_library"
        }
      }
    ]);
    detach();
  });

  it("derives the later-chapter cue only from an explicit bike unlock", () => {
    const events = new EventBus();
    const initial = createInitialGameState();
    const store = createGameStore({
      ...initial,
      ui: {
        ...initial.ui,
        libraryFinalsPhase: "seat_recovered"
      }
    });
    const director = new PresentationDirector();
    const detach = director.attach(store, events);

    store.setState((state) => ({
      ...state,
      bikeArcade: {
        ...state.bikeArcade,
        unlocked: true
      }
    }));

    expect(events.getHistory()).toContainEqual({
      name: PRESENTATION_CUE_EVENT,
      payload: {
        cueId: "bike_arcade_unlocked",
        source: "state"
      }
    });
    detach();
  });

  it("forwards low-level domain feedback without coupling it to a component", () => {
    const events = new EventBus();
    const store = createGameStore();
    const director = new PresentationDirector();
    const detach = director.attach(store, events);

    events.emit("bike_arcade_collision", { obstacleType: "barrier", lives: 2 });

    expect(events.getHistory()).toContainEqual({
      name: PRESENTATION_CUE_EVENT,
      payload: {
        cueId: "bike_arcade_collision",
        source: "event",
        obstacleType: "barrier",
        lives: 2
      }
    });
    detach();
  });

  it("publishes the chapter transition cue for audio and event consumers", async () => {
    const events = new EventBus();
    const store = createGameStore();
    const director = new PresentationDirector();
    const detach = director.attach(store, events);

    store.setState((state) => ({ ...state, currentScene: "chapter_transition" }));
    await Promise.resolve();

    expect(events.getHistory()).toContainEqual({
      name: PRESENTATION_CUE_EVENT,
      payload: {
        cueId: "chapter_transition_opened",
        source: "state"
      }
    });
    detach();
  });
});
