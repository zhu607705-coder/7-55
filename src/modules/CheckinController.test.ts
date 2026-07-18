import { describe, expect, it } from "vitest";
import { EventBus } from "../core/EventBus";
import { createGameStore } from "../core/GameState";
import { CheckinController } from "./CheckinController";

describe("CheckinController", () => {
  it("rejects submission on cellular with need_campus_wifi", () => {
    const store = createGameStore();
    const events = new EventBus();
    const checkin = new CheckinController(store, events);

    store.setState((s) => ({ ...s, networkMode: "cellular" }));

    expect(checkin.submit("0798")).toBe("need_campus_wifi");
    expect(store.getState().flags.checkinDone).toBe(false);
  });

  it("rejects a wrong code on campus wifi", () => {
    const store = createGameStore();
    const events = new EventBus();
    const checkin = new CheckinController(store, events);

    expect(checkin.submit("1234")).toBe("wrong_code");
    expect(store.getState().flags.checkinDone).toBe(false);
    expect(events.getHistory()).toContainEqual({
      name: "checkin_rejected",
      payload: { reason: "wrong_code", code: "1234" }
    });
  });

  it("accepts 0798 on campus wifi and marks checkinDone", () => {
    const store = createGameStore();
    const events = new EventBus();
    const checkin = new CheckinController(store, events);

    expect(checkin.submit("0798")).toBe("success");
    expect(store.getState().flags.checkinDone).toBe(true);
    expect(events.getHistory()).toContainEqual({
      name: "checkin_success",
      payload: { code: "0798" }
    });
  });
});
