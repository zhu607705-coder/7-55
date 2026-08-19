import type { GameState, PhoneHomeAppId } from "./types";

export type PhoneHomeRemovalContext = Pick<GameState, "actOne"> & {
  ui: Pick<GameState["ui"], "libraryFinalsPuzzle">;
};

export const PHONE_HOME_APP_IDS = Object.freeze([
  "wechat",
  "tiyi",
  "zjuding",
  "settings",
  "photos",
  "timeline_recovery",
  "voice_memos",
  "cc98",
  "bike_arcade",
  "control_center",
  "clock"
] as const satisfies readonly PhoneHomeAppId[]);

export const DEFAULT_PHONE_HOME_APP_ORDER: readonly PhoneHomeAppId[] = PHONE_HOME_APP_IDS;

const PHONE_HOME_APP_ID_SET = new Set<PhoneHomeAppId>(PHONE_HOME_APP_IDS);

export function normalizePhoneHomeAppOrder(value: unknown): PhoneHomeAppId[] {
  const incoming = Array.isArray(value)
    ? value.filter((id): id is PhoneHomeAppId => typeof id === "string" && PHONE_HOME_APP_ID_SET.has(id as PhoneHomeAppId))
    : [];
  const unique = [...new Set(incoming)];
  return [...unique, ...PHONE_HOME_APP_IDS.filter((id) => !unique.includes(id))];
}

export function canRemovePhoneHomeApp(state: PhoneHomeRemovalContext, appId: PhoneHomeAppId): boolean {
  if (appId === "bike_arcade") return true;
  if (appId === "tiyi") {
    return state.actOne.exerciseStarted && state.ui.libraryFinalsPuzzle.presenceProofCollected;
  }
  return false;
}

export function normalizeHiddenPhoneHomeAppIds(
  value: unknown,
  state: PhoneHomeRemovalContext
): PhoneHomeAppId[] {
  if (!Array.isArray(value)) return [];
  return [...new Set(value)].filter(
    (id): id is PhoneHomeAppId => typeof id === "string"
      && PHONE_HOME_APP_ID_SET.has(id as PhoneHomeAppId)
      && canRemovePhoneHomeApp(state, id as PhoneHomeAppId)
  );
}
