import {
  DEVELOPER_ACTIVE_KEY,
  DEVELOPER_BACKUP_KEY,
  DEVELOPER_CANTEEN_DEFENSE_START_KEY,
  DEVELOPER_CHAPTER4_PROLOGUE_OFFSET_KEY,
  DEVELOPER_CHAPTER4_TASK_CARD_CONFIRMED_KEY,
  DEVELOPER_PANEL_OPEN_KEY,
  DEVELOPER_QIZHEN_RHYTHM_SPAWN_KEY,
  DEVELOPER_SOURCE_KEY
} from "./StorageKeys";

// These are temporary QA-session records, never formal save envelopes. Clearing
// them does not restore the QA backup or read/write the player's localStorage.
export const DEVELOPER_SESSION_KEYS = Object.freeze([
  DEVELOPER_ACTIVE_KEY, DEVELOPER_BACKUP_KEY, DEVELOPER_SOURCE_KEY,
  DEVELOPER_CANTEEN_DEFENSE_START_KEY, DEVELOPER_CHAPTER4_PROLOGUE_OFFSET_KEY,
  DEVELOPER_CHAPTER4_TASK_CARD_CONFIRMED_KEY, DEVELOPER_QIZHEN_RHYTHM_SPAWN_KEY,
  DEVELOPER_PANEL_OPEN_KEY
]);

export function clearDeveloperSession(storage?: Pick<Storage, "removeItem">): void {
  let target: Pick<Storage, "removeItem">;
  try { target = storage ?? window.sessionStorage; } catch { return; }
  for (const key of DEVELOPER_SESSION_KEYS) {
    try { target.removeItem(key); } catch { /* Restricted storage remains optional. */ }
  }
}
