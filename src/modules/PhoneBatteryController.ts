import type { EventBus } from "../core/EventBus";
import type { GameStore, SceneId } from "../core/types";

export const PHONE_BATTERY_MIN_PERCENT = 0;

// Navigation is free. Explicit network switching retains its separate cost.
export function getPhoneSceneBatteryCost(_sceneId: SceneId): number {
  return 0;
}

/** Battery is a decreasing display resource, never a navigation or puzzle gate. */
export class PhoneBatteryController {
  constructor(
    private readonly store: GameStore,
    private readonly events: EventBus
  ) {}

  consumeForSceneOpen(previousScene: SceneId, nextScene: SceneId): number {
    if (previousScene === nextScene) return this.store.getState().phoneBattery.percent;
    return this.consume(getPhoneSceneBatteryCost(nextScene), "app_open", nextScene);
  }

  consumeForNetworkSwitch(): number {
    return this.consume(1, "network_switch");
  }

  private consume(amount: number, reason: string, sceneId?: SceneId): number {
    if (amount <= 0) return this.store.getState().phoneBattery.percent;
    const from = this.store.getState().phoneBattery.percent;
    const to = Math.max(PHONE_BATTERY_MIN_PERCENT, from - amount);
    // The original prank starts on the action already at 1%, without retaining a reserve.
    if (from === 1) this.events.emit("phone_battery_reserve_used", { percent: from, reason, sceneId });
    if (to === from) return to;
    this.store.setState((state) => ({
      ...state,
      phoneBattery: { percent: to }
    }));
    this.events.emit("phone_battery_changed", { from, to, amount: from - to, reason, sceneId });
    return to;
  }
}
