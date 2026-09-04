import type { EventBus } from "../core/EventBus";
import type { GameState, GameStore, RpgSceneId, SceneId } from "../core/types";

export const PHONE_BATTERY_MIN_PERCENT = 1;
export const PHONE_BATTERY_RECHARGE_PERCENT = 45;

const BATTERY_FREE_SCENES = new Set<SceneId>([
  "alarm",
  "desktop",
  "phone_home",
  "ending"
]);

const CHAPTER_FOUR_POWER_OUT_PHASES = new Set<GameState["chapter4"]["phase"]>([
  "blackout_light_grid",
  "final_chase",
  "final_minute_recovery"
]);

const CHARGING_SOURCE_BY_RPG_SCENE: Readonly<Partial<Record<RpgSceneId, string>>> = {
  dorm_hub: "宿舍桌边插座",
  library_interior: "基础图书馆公共插座",
  canteen_interior: "食堂服务台电源",
  theater_interior: "剧场服务台电源"
};

export function getPhoneSceneBatteryCost(sceneId: SceneId, lowPowerMode: boolean): number {
  if (BATTERY_FREE_SCENES.has(sceneId)) return 0;
  return lowPowerMode ? 1 : 2;
}

export function getNearbyChargingSource(state: GameState): string | null {
  if (state.rpgScene === "duan_yongping_temporal_maze") {
    return CHAPTER_FOUR_POWER_OUT_PHASES.has(state.chapter4.phase)
      ? null
      : "教学楼服务台插座";
  }
  return CHARGING_SOURCE_BY_RPG_SCENE[state.rpgScene] ?? null;
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

  getNearbyChargingSource(): string | null {
    return getNearbyChargingSource(this.store.getState());
  }

  rechargeFromNearbyPower(): "charged" | "already_sufficient" | "no_power_source" {
    const current = this.store.getState();
    const source = getNearbyChargingSource(current);
    if (!source) {
      this.events.emit("toast", {
        text: "附近没有可用电源。回到室内服务区后再打开控制中心。",
        tone: "task"
      });
      return "no_power_source";
    }
    if (current.phoneBattery.percent >= PHONE_BATTERY_RECHARGE_PERCENT) {
      this.events.emit("toast", {
        text: `当前电量足够，${source}暂不需要接入。`,
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
        text: "已进入 1% 任务保底电量。主线功能继续可用，回到室内服务区可充电。",
        tone: "task"
      });
    }
    return to;
  }
}
