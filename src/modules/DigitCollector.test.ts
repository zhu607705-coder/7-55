import { describe, expect, it } from "vitest";
import { EventBus } from "../core/EventBus";
import { createGameStore } from "../core/GameState";
import { DigitCollector } from "./DigitCollector";

describe("DigitCollector", () => {
  it("collects the four code digits in the fixed 0798 order", () => {
    const store = createGameStore();
    const events = new EventBus();
    const collector = new DigitCollector(store, events);

    collector.collectDigit(1, "0", "campus_card");
    collector.collectDigit(2, "7", "tiyi");
    collector.collectDigit(3, "9", "phone_home");
    collector.collectDigit(4, "8", "bonsai");

    expect(collector.hasAllDigits()).toBe(true);
    expect(collector.getCode()).toBe("0798");
    expect(events.getHistory().filter((event) => event.name === "collect_digit")).toHaveLength(4);
  });
});
