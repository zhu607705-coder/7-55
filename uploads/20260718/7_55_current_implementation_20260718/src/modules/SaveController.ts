import type { EventBus } from "../core/EventBus";
import { createInitialGameState } from "../core/GameState";
import { SaveStore } from "../core/SaveStore";
import { DEVELOPER_ACTIVE_KEY, DEVELOPER_BACKUP_KEY, DEVELOPER_BIKE_START_KEY } from "../core/StorageKeys";
import type { GameStore } from "../core/types";

export class SaveController {
  constructor(
    private readonly store: GameStore,
    private readonly events: EventBus,
    private readonly storage: Storage = window.localStorage,
    private readonly sessionStorage: Storage = window.sessionStorage
  ) {}

  saveNow(): boolean {
    const saveStore = new SaveStore(this.storage);
    const state = this.store.getState();
    const saved = saveStore.save(state) && saveStore.saveBikeArcade(state);
    this.events.emit(saved ? "game_saved" : "game_save_failed");
    return saved;
  }

  resetProgress(): void {
    new SaveStore(this.storage).clear();
    this.sessionStorage.removeItem(DEVELOPER_ACTIVE_KEY);
    this.sessionStorage.removeItem(DEVELOPER_BACKUP_KEY);
    this.sessionStorage.removeItem(DEVELOPER_BIKE_START_KEY);
    this.store.setState(() => createInitialGameState());
    this.events.emit("game_progress_reset");
  }
}
