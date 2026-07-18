import { describe, expect, it } from "vitest";
import { EventBus } from "./EventBus";
import { createGameStore } from "./GameState";
import { SceneRouter } from "./SceneRouter";

describe("SceneRouter", () => {
  it("updates current scene and emits enter_scene", () => {
    const store = createGameStore();
    const events = new EventBus();
    const router = new SceneRouter(store, events);

    router.goTo("desktop");

    expect(store.getState().currentScene).toBe("desktop");
    expect(events.getHistory()).toContainEqual({
      name: "enter_scene",
      payload: { sceneId: "desktop" }
    });
  });

  it("rejects a direct route into a chapter-locked feature", () => {
    const store = createGameStore();
    const events = new EventBus();
    const router = new SceneRouter(store, events);

    expect(router.goTo("cc98")).toBe(false);
    expect(store.getState().currentScene).toBe("alarm");
    expect(events.getHistory().at(-1)).toEqual({
      name: "feature_access_denied",
      payload: { sceneId: "cc98" }
    });
  });
});
