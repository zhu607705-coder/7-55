import { describe, expect, it } from "vitest";
import { EventBus } from "../core/EventBus";
import { createGameStore } from "../core/GameState";
import { NetworkController } from "./NetworkController";

describe("NetworkController", () => {
  it("enforces tiyi and check-in network rules", () => {
    const store = createGameStore();
    const events = new EventBus();
    const network = new NetworkController(store, events);

    expect(network.canOpenTiyi()).toBe(false);
    expect(network.canSubmitCheckin()).toBe(true);

    network.setMode("cellular");

    expect(network.canOpenTiyi()).toBe(true);
    expect(network.canSubmitCheckin()).toBe(false);
    expect(events.getHistory()).toContainEqual({
      name: "network_changed",
      payload: { oldMode: "campus_wifi", newMode: "cellular" }
    });
  });
});
