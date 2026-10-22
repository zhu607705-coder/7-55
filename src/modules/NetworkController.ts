import type { EventBus } from "../core/EventBus";
import type { GameStore, NetworkMode } from "../core/types";
import { canAccessTiyi } from "./TiyiAccessModel";

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

  /** 首次保留流量谜题；外出锻炼阶段还须完成游戏内客户端更新。 */
  canOpenTiyi(): boolean {
    return canAccessTiyi(this.store.getState());
  }

  /** CC98 仅允许通过校园网访问。 */
  canOpenCc98(): boolean {
    return this.getMode() === "campus_wifi";
  }

  /** 浙大钉只认校园网：其他网络下停在加载页。 */
  canOpenZjuding(): boolean {
    return this.getMode() === "campus_wifi";
  }

  canSubmitCheckin(): boolean {
    return this.getMode() === "campus_wifi";
  }
}
