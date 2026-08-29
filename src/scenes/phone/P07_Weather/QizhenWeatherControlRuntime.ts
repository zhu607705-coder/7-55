import type {
  QizhenWeatherCloudPositions,
  QizhenWeatherControlDirections
} from "../../../modules/QizhenWeatherControlModel";

export interface QizhenWeatherControlRuntimeSnapshot {
  readonly active: true;
  readonly positions: QizhenWeatherCloudPositions;
  readonly alignedBandCount: number;
  readonly controlledBands: readonly [boolean, boolean, boolean];
  readonly activeDirections: QizhenWeatherControlDirections;
  readonly stableMs: number;
  readonly requiredStableMs: number;
  readonly elapsedMs: number;
  readonly moves: number;
  readonly windDirection: "left";
}

let snapshot: QizhenWeatherControlRuntimeSnapshot | null = null;

export function setQizhenWeatherControlRuntimeSnapshot(
  next: QizhenWeatherControlRuntimeSnapshot | null
): void {
  snapshot = next;
}

export function getQizhenWeatherControlRuntimeSnapshot(): QizhenWeatherControlRuntimeSnapshot | null {
  return snapshot;
}
