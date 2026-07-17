import { describe, expect, it } from "vitest";
import { EventBus } from "../core/EventBus";
import { createGameStore } from "../core/GameState";
import { PlantController } from "./PlantController";

function setup() {
  const store = createGameStore();
  const events = new EventBus();
  const plant = new PlantController(store, events);
  return { store, events, plant };
}

describe("PlantController", () => {
  it("requires the watered headphone for watering", () => {
    const { store, plant } = setup();

    expect(plant.apply("water")).toBe("missing_requirement");

    store.setState((s) => ({
      ...s,
      items: { ...s.items, wateredHeadphone: true }
    }));

    expect(plant.apply("water")).toBe("done");
    expect(plant.apply("water")).toBe("already");
    expect(plant.growthStage()).toBe(1);
  });

  it("requires brightness >= 80 for light", () => {
    const { store, plant } = setup();

    expect(plant.apply("light")).toBe("missing_requirement");

    store.setState((s) => ({ ...s, ui: { ...s.ui, brightness: 85 } }));

    expect(plant.apply("light")).toBe("done");
    expect(plant.growthStage()).toBe(1);
  });

  it("blooms after all three parallel steps", () => {
    const { store, events, plant } = setup();

    store.setState((s) => ({
      ...s,
      items: { ...s.items, wateredHeadphone: true, fertilizer: true },
      ui: { ...s.ui, brightness: 100 }
    }));

    expect(plant.apply("water")).toBe("done");
    expect(plant.apply("light")).toBe("done");
    expect(plant.isBloomed()).toBe(false);
    expect(plant.apply("fertilize")).toBe("done");

    expect(plant.growthStage()).toBe(3);
    expect(plant.isBloomed()).toBe(true);
    expect(events.getHistory()).toContainEqual({ name: "flower_bloomed" });
  });
});
