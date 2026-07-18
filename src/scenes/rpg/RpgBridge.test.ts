import { describe, expect, it } from "vitest";
import { EventBus } from "../../core/EventBus";
import { createGameStore } from "../../core/GameState";
import { SceneRouter } from "../../core/SceneRouter";
import { createRpgBridge } from "./RpgBridge";

describe("createRpgBridge", () => {
  it("exposes state, checkpoint persistence, phone routing, and event emission to Phaser scenes", () => {
    const store = createGameStore();
    const events = new EventBus();
    const router = new SceneRouter(store, events);
    const bridge = createRpgBridge(store, router, events);

    store.setState((state) => ({ ...state, runtimeMode: "rpg" }));

    bridge.emit("rpg_trigger_enter", { triggerId: "bed_exit" });
    bridge.setRpgLocation("library_interior", "library_seat_022");
    bridge.goToPhoneScene("desktop");

    expect(bridge.getState().currentScene).toBe("desktop");
    expect(bridge.getState().runtimeMode).toBe("phone");
    expect(bridge.getState().rpgScene).toBe("library_interior");
    expect(bridge.getState().rpgCheckpoint).toBe("library_seat_022");
    expect(events.getHistory()).toContainEqual({
      name: "rpg_trigger_enter",
      payload: { triggerId: "bed_exit" }
    });
    expect(events.getHistory()).toContainEqual({
      name: "rpg_location_changed",
      payload: { scene: "library_interior", checkpoint: "library_seat_022" }
    });
  });
});
