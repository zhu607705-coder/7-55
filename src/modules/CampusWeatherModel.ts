import type { GameState } from "../core/types";

export interface CampusWeatherProjection {
  condition: "light_rain" | "overcast";
  label: "小雨" | "多云";
  boatingAllowed: boolean;
}

export function selectCampusWeather(state: GameState): CampusWeatherProjection {
  if (!state.qizhenLake.rainSafetyCleared) {
    return { condition: "light_rain", label: "小雨", boatingAllowed: false };
  }
  return { condition: "overcast", label: "多云", boatingAllowed: true };
}
