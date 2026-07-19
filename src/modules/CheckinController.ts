import type { EventBus } from "../core/EventBus";
import type { GameStore } from "../core/types";

export type CheckinResult = "need_campus_wifi" | "wrong_code" | "success";

export const CHECKIN_CODE = "0798";

export class CheckinController {
  constructor(
    private readonly store: GameStore,
    private readonly events: EventBus
  ) {}

  /** 校务签到提交规则：必须校园网；签到码必须为 0798。 */
  submit(code: string): CheckinResult {
    const state = this.store.getState();

    if (state.networkMode !== "campus_wifi") {
      this.events.emit("checkin_rejected", { reason: "network", code });
      return "need_campus_wifi";
    }

    if (code !== CHECKIN_CODE) {
      this.events.emit("checkin_rejected", { reason: "wrong_code", code });
      return "wrong_code";
    }

    this.store.setState((s) => ({
      ...s,
      flags: { ...s.flags, checkinDone: true }
    }));
    this.events.emit("checkin_success", { code });
    return "success";
  }
}
