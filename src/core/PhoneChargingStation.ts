import type { GameState } from "./types";

// Source-pixel position of the small cabinet left of the theater entrance.
// The scene, proximity prompt and battery controller share this one target.
export const THEATER_CHARGING_STATION = {
  id: "theater_charging_station",
  label: "手机充电服务站",
  x: 595,
  y: 773,
  width: 77,
  height: 93,
  stand: { x: 665, y: 790 },
  proximity: 46,
  requiredMode: "light"
} as const;

export const PHONE_CHARGING_DURATION_MS = 2200;
export const PHONE_BATTERY_RECHARGE_PERCENT = 45;

export type ChargingRejection = "no_power_source" | "too_far" | "wrong_mode";

export function checkPhoneChargingStation(
  state: GameState,
  stationId: string,
  position: { x: number; y: number }
): ChargingRejection | null {
  if (stationId !== THEATER_CHARGING_STATION.id
    || state.runtimeMode !== "rpg"
    || state.rpgScene !== "theater_interior"
    || !state.theaterHunt.active
    || state.ui.controlCenterOpen) return "no_power_source";
  const station = THEATER_CHARGING_STATION;
  const dx = Math.max(0, Math.abs(position.x - station.x) - station.width / 2);
  const dy = Math.max(0, Math.abs(position.y - station.y) - station.height / 2);
  if (!Number.isFinite(position.x) || !Number.isFinite(position.y)
    || Math.hypot(dx, dy) > station.proximity) return "too_far";
  return state.theaterHunt.mode === "light" ? null : "wrong_mode";
}
