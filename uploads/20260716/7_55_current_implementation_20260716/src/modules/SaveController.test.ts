import { describe, expect, it } from "vitest";
import { EventBus } from "../core/EventBus";
import { createGameStore } from "../core/GameState";
import { SaveStore } from "../core/SaveStore";
import { SaveController } from "./SaveController";

describe("SaveController", () => {
  it("saves immediately and resets all story progress after confirmation", () => {
    const storage = window.localStorage;
    const session = window.sessionStorage;
    storage.clear();
    session.clear();
    const store = createGameStore();
    const events = new EventBus();
    const controller = new SaveController(store, events, storage, session);
    store.setState((state) => ({ ...state, currentScene: "cc98", items: { ...state.items, reverseGear: true } }));

    expect(controller.saveNow()).toBe(true);
    expect(new SaveStore(storage).load(store.getState())?.currentScene).toBe("phone_home");
    controller.resetProgress();

    expect(store.getState().currentScene).toBe("alarm");
    expect(Object.values(store.getState().items).some(Boolean)).toBe(false);
    expect(storage.getItem("seven_fifty_five_state")).toBeNull();
    expect(events.getHistory().at(-1)?.name).toBe("game_progress_reset");
  });
});
