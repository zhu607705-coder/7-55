import type { EventBus } from "../core/EventBus";
import type { GameStore, SceneId } from "../core/types";
import {
  checkPhoneChargingStation,
  PHONE_BATTERY_RECHARGE_PERCENT,
  THEATER_CHARGING_STATION,
  type ChargingRejection
} from "../core/PhoneChargingStation";

export const PHONE_BATTERY_MIN_PERCENT = 1;
export { PHONE_BATTERY_RECHARGE_PERCENT } from "../core/PhoneChargingStation";

const BATTERY_FREE_SCENES = new Set<SceneId>([
  "alarm",
  "desktop",
  "phone_home",
  "ending"
]);

export function getPhoneSceneBatteryCost(sceneId: SceneId, lowPowerMode: boolean): number {
  if (BATTERY_FREE_SCENES.has(sceneId)) return 0;
  return lowPowerMode ? 1 : 2;
}

export class PhoneBatteryController {
  constructor(
    private readonly store: GameStore,
    private readonly events: EventBus
  ) {}

  consumeForSceneOpen(previousScene: SceneId, nextScene: SceneId): number {
    if (previousScene === nextScene) return this.store.getState().phoneBattery.percent;
    const current = this.store.getState();
    const cost = getPhoneSceneBatteryCost(nextScene, current.phoneBattery.lowPowerMode);
    return this.consume(cost, "app_open", nextScene);
  }

  consumeForNetworkSwitch(): number {
    return this.consume(1, "network_switch");
  }

  setLowPowerMode(enabled: boolean): void {
    const current = this.store.getState();
    if (current.phoneBattery.lowPowerMode === enabled) return;
    this.store.setState((state) => ({
      ...state,
      phoneBattery: {
        ...state.phoneBattery,
        lowPowerMode: enabled
      },
      ui: enabled
        ? {
            ...state.ui,
            brightness: Math.min(state.ui.brightness, 45),
            musicPlaying: false
          }
        : state.ui
    }));
    this.events.emit("phone_low_power_mode_changed", { enabled });
    this.events.emit("toast", {
      text: enabled
        ? "低电量模式已开启：打开应用仅消耗 1%，亮度上限 45%，音乐已暂停。"
        : "低电量模式已关闭：打开应用恢复消耗 2%。",
      tone: "task"
    });
  }

  rechargeAtStation(
    stationId: string,
    position: { x: number; y: number }
  ): "charged" | "already_sufficient" | ChargingRejection {
    const current = this.store.getState();
    const rejection = checkPhoneChargingStation(current, stationId, position);
    if (rejection) {
      this.events.emit("toast", {
        text: rejection === "too_far"
          ? "接线够不到，请走到充电服务站旁。"
          : rejection === "wrong_mode"
            ? "深色观察只能查看设备。切到浅色操作后接入充电线。"
            : "需要在现场与充电服务站交互，手机中不能接入电源。",
        tone: "task"
      });
      return rejection;
    }
    const source = THEATER_CHARGING_STATION.label;
    if (current.phoneBattery.percent >= PHONE_BATTERY_RECHARGE_PERCENT) {
      this.events.emit("toast", {
        text: `当前电量 ${current.phoneBattery.percent}%，暂不需要补电。`,
        tone: "task"
      });
      return "already_sufficient";
    }
    const from = current.phoneBattery.percent;
    this.store.setState((state) => ({
      ...state,
      phoneBattery: {
        ...state.phoneBattery,
        percent: PHONE_BATTERY_RECHARGE_PERCENT,
        rechargeCount: state.phoneBattery.rechargeCount + 1
      }
    }));
    this.events.emit("phone_battery_recharged", {
      from,
      to: PHONE_BATTERY_RECHARGE_PERCENT,
      source
    });
    this.events.emit("toast", {
      text: `已接入${source}，电量恢复至 ${PHONE_BATTERY_RECHARGE_PERCENT}%。`,
      tone: "task"
    });
    return "charged";
  }

  private consume(amount: number, reason: string, sceneId?: SceneId): number {
    if (amount <= 0) return this.store.getState().phoneBattery.percent;
    const current = this.store.getState();
    const from = current.phoneBattery.percent;
    const to = Math.max(PHONE_BATTERY_MIN_PERCENT, from - amount);
    if (to === from) {
      this.events.emit("phone_battery_reserve_used", { percent: to, reason, sceneId });
      return to;
    }
    this.store.setState((state) => ({
      ...state,
      phoneBattery: {
        ...state.phoneBattery,
        percent: to
      }
    }));
    this.events.emit("phone_battery_changed", { from, to, amount: from - to, reason, sceneId });
    if (from > 10 && to <= 10) {
      this.events.emit("toast", {
        text: `电量降至 ${to}%。点状态栏，可开启低电量模式或寻找附近电源。`,
        tone: "task"
      });
    }
    if (to === PHONE_BATTERY_MIN_PERCENT) {
      this.events.emit("toast", {
        text: "已进入 1% 任务保底电量。主线功能继续可用，可在现场充电服务站补电。",
        tone: "task"
      });
    }
    return to;
  }
}
