import type { EventBus } from "../core/EventBus";
import type { GameState, GameStore, SceneId } from "../core/types";
import {
  checkPhoneChargingStation,
  checkHomeDeskChargingStation,
  canReturnToHomeDesk,
  isHomeDeskContext,
  HOME_DESK_CHARGING_STATION,
  PHONE_CHARGING_DURATION_MS,
  PHONE_BATTERY_RECHARGE_PERCENT,
  THEATER_CHARGING_STATION,
  type ChargingRejection
} from "../core/PhoneChargingStation";

export const PHONE_BATTERY_MIN_PERCENT = 1;
export { PHONE_BATTERY_RECHARGE_PERCENT } from "../core/PhoneChargingStation";

// Navigation is not an energy-consuming action. Keep this source contract for
// router integrations; explicit network switching retains its separate cost.
export function getPhoneSceneBatteryCost(_sceneId: SceneId, _lowPowerMode: boolean): number {
  return 0;
}

export type HomeDeskChargingReceipt = Readonly<{ stationId: typeof HOME_DESK_CHARGING_STATION.id }>;
type DeskSession = {
  receipt: HomeDeskChargingReceipt;
  elapsedMs: number;
  lastClock: number;
  flags: GameState["flags"];
  battery: GameState["phoneBattery"];
  unsubscribe: () => void;
};

export class PhoneBatteryController {
  private deskSession: DeskSession | null = null;
  private deskHintShown = false;
  constructor(
    private readonly store: GameStore,
    private readonly events: EventBus,
    private readonly now: () => number = () => performance.now(),
    private readonly foreground: () => boolean = () => typeof document === "undefined" || (!document.hidden && document.hasFocus())
  ) {}

  prepareHomeDeskReturn(page: SceneId): boolean {
    const state = this.store.getState();
    if (!canReturnToHomeDesk(state) || state.currentScene !== page || !["phone_home", "bonsai"].includes(page)) return false;
    this.cancelHomeDeskCharging();
    this.store.setState(current => ({ ...current, ui: { ...current.ui, homeDeskReturnScene: page as "phone_home" | "bonsai" } }));
    if (!this.deskHintShown) {
      this.deskHintShown = true;
      this.events.emit("toast", { text: "手机放回桌面，点充电座接电；点手机拿起。", tone: "task" });
    }
    return true;
  }

  hasHomeDeskReturn(): boolean {
    const state = this.store.getState();
    // Presentation remembers the desk while a modal is open; only charging/input
    // uses the stricter no-modal predicate, so opening it cannot replay wake VO.
    return isHomeDeskContext(state) && ["phone_home", "bonsai"].includes(state.ui.homeDeskReturnScene ?? "");
  }

  takePhoneFromDesk(): "phone_home" | "bonsai" {
    const page = this.hasHomeDeskReturn() ? this.store.getState().ui.homeDeskReturnScene! : "phone_home";
    this.cancelHomeDeskCharging();
    this.store.setState(state => ({ ...state, ui: { ...state.ui, homeDeskReturnScene: null } }));
    return page;
  }

  beginHomeDeskCharging(): HomeDeskChargingReceipt | "already_sufficient" | ChargingRejection {
    const state = this.store.getState();
    if (checkHomeDeskChargingStation(state) || !this.foreground()) {
      this.cancelHomeDeskCharging();
      return "no_power_source";
    }
    if (this.deskSession && this.validDeskSession(this.deskSession.receipt)) return this.deskSession.receipt;
    if (state.phoneBattery.percent >= PHONE_BATTERY_RECHARGE_PERCENT && !state.phoneBattery.lowPowerMode) return "already_sufficient";
    const receipt: HomeDeskChargingReceipt = Object.freeze({ stationId: HOME_DESK_CHARGING_STATION.id });
    this.deskSession = { receipt, elapsedMs: 0, lastClock: this.now(), flags: state.flags, battery: state.phoneBattery, unsubscribe: () => {} };
    this.deskSession.unsubscribe = this.store.subscribe(() => {
      if (this.deskSession) this.validDeskSession(this.deskSession.receipt);
    });
    return receipt;
  }

  getHomeDeskChargingProgress(receipt: HomeDeskChargingReceipt): number | null {
    if (!this.validDeskSession(receipt)) return null;
    const session = this.deskSession!;
    const clock = this.now();
    // Match the existing theater timeline: a resumed/stalled frame cannot
    // backfill an unattended interval, and repeated reads at one clock add zero.
    session.elapsedMs += Math.min(100, Math.max(0, clock - session.lastClock));
    session.lastClock = clock;
    return Math.min(1, session.elapsedMs / PHONE_CHARGING_DURATION_MS);
  }

  completeHomeDeskCharging(receipt: HomeDeskChargingReceipt): "charged" | "already_sufficient" | "too_early" | "invalid_receipt" {
    const progress = this.getHomeDeskChargingProgress(receipt);
    if (progress === null) return "invalid_receipt";
    if (progress < 1) return "too_early";
    // Retire the receipt before mutating state or notifying subscribers.
    this.cancelHomeDeskCharging(receipt);
    return this.applyRecharge(HOME_DESK_CHARGING_STATION.label);
  }

  cancelHomeDeskCharging(receipt?: HomeDeskChargingReceipt): void {
    if (!this.deskSession || (receipt && receipt !== this.deskSession.receipt)) return;
    const session = this.deskSession;
    this.deskSession = null;
    session.unsubscribe();
  }

  private validDeskSession(receipt: HomeDeskChargingReceipt): boolean {
    const session = this.deskSession;
    if (!session || session.receipt !== receipt) return false;
    const state = this.store.getState();
    if (session.flags !== state.flags || session.battery !== state.phoneBattery
      || checkHomeDeskChargingStation(state) || !this.foreground()) {
      this.cancelHomeDeskCharging(receipt);
      return false;
    }
    return true;
  }

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
        ? "低电量模式已开启：亮度上限 45%，音乐已暂停。打开应用不扣电。"
        : "低电量模式已关闭：可手动调整亮度，打开应用不扣电。",
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
    return this.applyRecharge(THEATER_CHARGING_STATION.label);
  }

  private applyRecharge(source: string): "charged" | "already_sufficient" {
    const current = this.store.getState();
    if (current.phoneBattery.percent >= PHONE_BATTERY_RECHARGE_PERCENT && !current.phoneBattery.lowPowerMode) {
      this.events.emit("toast", {
        text: `当前电量 ${current.phoneBattery.percent}%，暂不需要补电。`,
        tone: "task"
      });
      return "already_sufficient";
    }
    const from = current.phoneBattery.percent;
    const to = Math.max(from, PHONE_BATTERY_RECHARGE_PERCENT);
    this.store.setState((state) => ({
      ...state,
      phoneBattery: {
        ...state.phoneBattery,
        percent: to,
        lowPowerMode: false,
        rechargeCount: state.phoneBattery.rechargeCount + 1
      }
    }));
    this.events.emit("phone_battery_recharged", {
      from,
      to,
      source
    });
    this.events.emit("toast", {
      text: `已接入${source}，电量 ${to}%，已退出低电量模式。`,
      tone: "task"
    });
    return "charged";
  }

  private consume(amount: number, reason: string, sceneId?: SceneId): number {
    if (amount <= 0) return this.store.getState().phoneBattery.percent;
    const current = this.store.getState();
    const from = current.phoneBattery.percent;
    const to = Math.min(from, Math.max(PHONE_BATTERY_MIN_PERCENT, from - amount));
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
        text: "电量仅剩 1%，请寻找现场充电服务站。",
        tone: "task"
      });
    }
    return to;
  }
}
