import type { EventBus } from "../core/EventBus";
import { createInitialGameState } from "../core/GameState";
import { SaveStore } from "../core/SaveStore";
import {
  DEVELOPER_ACTIVE_KEY,
  DEVELOPER_BACKUP_KEY,
  DEVELOPER_CHAPTER4_PROLOGUE_OFFSET_KEY,
  DEVELOPER_CHAPTER4_TASK_CARD_CONFIRMED_KEY,
  DEVELOPER_QIZHEN_RHYTHM_SPAWN_KEY,
  DEVELOPER_SOURCE_KEY
} from "../core/StorageKeys";
import type { GameStore } from "../core/types";
import { clearChapterThreeInterludeVoiceDraft } from "./ChapterThreeInterludeDraftStore";

export class SaveController {
  constructor(
    private readonly store: GameStore,
    private readonly events: EventBus,
    private readonly storage: Storage = window.localStorage,
    private readonly sessionStorage: Storage = window.sessionStorage
  ) {}

  saveNow(): boolean {
    if (this.sessionStorage.getItem(DEVELOPER_ACTIVE_KEY)) {
      this.events.emit("game_save_failed", { reason: "developer_checkpoint_session" });
      return false;
    }
    const saveStore = new SaveStore(this.storage);
    const state = this.store.getState();
    const saved = saveStore.save(state);
    this.events.emit(saved ? "game_saved" : "game_save_failed");
    return saved;
  }

  resetProgress(): void {
    new SaveStore(this.storage).clear();
    this.sessionStorage.removeItem(DEVELOPER_ACTIVE_KEY);
    this.sessionStorage.removeItem(DEVELOPER_SOURCE_KEY);
    this.sessionStorage.removeItem(DEVELOPER_BACKUP_KEY);
    this.sessionStorage.removeItem(DEVELOPER_CHAPTER4_PROLOGUE_OFFSET_KEY);
    this.sessionStorage.removeItem(DEVELOPER_CHAPTER4_TASK_CARD_CONFIRMED_KEY);
    this.sessionStorage.removeItem(DEVELOPER_QIZHEN_RHYTHM_SPAWN_KEY);
    clearChapterThreeInterludeVoiceDraft(this.sessionStorage);
    this.store.setState(() => createInitialGameState());
    this.events.emit("game_progress_reset");
  }
}
