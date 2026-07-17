import type { EventBus } from "../core/EventBus";
import type { GameStore, NetworkMode } from "../core/types";

export class NetworkController {
  constructor(
    private readonly store: GameStore,
    private readonly events: EventBus
  ) {}

  setMode(mode: NetworkMode): void {
    const oldMode = this.getMode();
    if (oldMode === mode) {
      return;
    }

    this.store.setState((state) => ({ ...state, networkMode: mode }));
    this.events.emit("network_changed", { oldMode, newMode: mode });
  }

  getMode(): NetworkMode {
    return this.store.getState().networkMode;
  }

  /** 浙大体艺只有流量能进：校园网下加载 3 秒后闪退 */
  canOpenTiyi(): boolean {
    return this.getMode() === "cellular";
  }

  /** 浙大钉只认校园网：流量下永远卡在加载页 */
  canOpenZjuding(): boolean {
    return this.getMode() === "campus_wifi";
  }

  canSubmitCheckin(): boolean {
    return this.getMode() === "campus_wifi";
  }
}
