import type { EventBus } from "../core/EventBus";
import type { GameFlags, GameStore, UiState } from "../core/types";

/**
 * 小工具集合：flags / ui 的浅更新 + 事件广播 + toast。
 * 所有场景只通过这里改共享状态，避免每个组件手写 setState 样板。
 */
export class FlagController {
  constructor(
    private readonly store: GameStore,
    private readonly events: EventBus
  ) {}

  setFlag<K extends keyof GameFlags>(key: K, value: GameFlags[K]): void {
    this.store.setState((state) => ({
      ...state,
      flags: { ...state.flags, [key]: value }
    }));
    this.events.emit("flag_changed", { key, value });
  }

  getFlag<K extends keyof GameFlags>(key: K): GameFlags[K] {
    return this.store.getState().flags[key];
  }

  bumpTiyiCrash(): number {
    const next = this.store.getState().flags.tiyiCrashCount + 1;
    this.setFlag("tiyiCrashCount", next);
    return next;
  }

  setUi<K extends keyof UiState>(key: K, value: UiState[K]): void {
    this.store.setState((state) => ({
      ...state,
      ui: { ...state.ui, [key]: value }
    }));
    this.events.emit("ui_changed", { key, value });
  }

  getUi<K extends keyof UiState>(key: K): UiState[K] {
    return this.store.getState().ui[key];
  }

  /** 像素气泡吐槽（系统嘲讽 / 小影台词共用通道） */
  toast(text: string, tone: "system" | "xiaoying" | "task" = "system"): void {
    this.events.emit("toast", { text, tone });
  }

  /** 全屏震动特效 */
  shake(strong = false): void {
    this.events.emit("screen_shake", { strong });
    if (typeof window !== "undefined") {
      window.navigator.vibrate?.(strong ? [120, 60, 120, 60, 200] : [80, 40, 80]);
    }
  }
}
