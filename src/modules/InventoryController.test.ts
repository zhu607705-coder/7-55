import { describe, expect, it } from "vitest";
import { EventBus } from "../core/EventBus";
import { createGameStore } from "../core/GameState";
import { InventoryController } from "./InventoryController";

describe("InventoryController", () => {
  it("adds and uses items through the shared state", () => {
    const store = createGameStore();
    const events = new EventBus();
    const inventory = new InventoryController(store, events);

    inventory.addItem("reverseGear", "phone_home");

    expect(inventory.hasItem("reverseGear")).toBe(true);
    expect(inventory.useItem("reverseGear", "dark_mode_slot")).toBe(true);
    expect(events.getHistory()).toContainEqual({
      name: "use_item",
      payload: { itemId: "reverseGear", targetId: "dark_mode_slot" }
    });
  });

  it("combines slashLine + reverseGear into towerKey either direction", () => {
    const store = createGameStore();
    const events = new EventBus();
    const inventory = new InventoryController(store, events);

    inventory.addItem("slashLine", "wechat");
    inventory.addItem("reverseGear", "phone_home");

    expect(inventory.combine("slashLine", "reverseGear")).toBe("towerKey");
    expect(inventory.hasItem("towerKey")).toBe(true);
    expect(inventory.hasItem("slashLine")).toBe(false);
    expect(inventory.hasItem("reverseGear")).toBe(false);
    expect(events.getHistory()).toContainEqual({
      name: "combine_item",
      payload: { a: "slashLine", b: "reverseGear", result: "towerKey" }
    });
  });

  it("combines waterDrop + headphone into the watered headphone", () => {
    const store = createGameStore();
    const events = new EventBus();
    const inventory = new InventoryController(store, events);

    inventory.addItem("waterDrop", "phone_home");
    inventory.addItem("headphone", "phone_home");

    expect(inventory.combine("headphone", "waterDrop")).toBe("wateredHeadphone");
    expect(inventory.hasItem("wateredHeadphone")).toBe(true);
    expect(inventory.hasItem("waterDrop")).toBe(false);
    expect(inventory.hasItem("headphone")).toBe(false);
  });

  it("rejects combine when items are missing or not a recipe", () => {
    const store = createGameStore();
    const events = new EventBus();
    const inventory = new InventoryController(store, events);

    expect(inventory.combine("slashLine", "reverseGear")).toBeNull();

    inventory.addItem("waterDrop", "phone_home");
    inventory.addItem("fertilizer", "phone_home");
    expect(inventory.combine("waterDrop", "fertilizer")).toBeNull();
    expect(inventory.hasItem("waterDrop")).toBe(true);
    expect(inventory.hasItem("fertilizer")).toBe(true);
  });

  it("consumes items after single-use targets", () => {
    const store = createGameStore();
    const events = new EventBus();
    const inventory = new InventoryController(store, events);

    inventory.addItem("towerKey", "phone_home");
    expect(inventory.consumeItem("towerKey", "tower_slot")).toBe(true);
    expect(inventory.hasItem("towerKey")).toBe(false);
  });
});
