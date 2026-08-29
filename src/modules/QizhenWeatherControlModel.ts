export type QizhenWeatherBandIndex = 0 | 1 | 2;
export type QizhenWeatherControlDirection = -1 | 0 | 1;
export type QizhenWeatherCloudPositions = readonly [number, number, number];
export type QizhenWeatherControlDirections = readonly [
  QizhenWeatherControlDirection,
  QizhenWeatherControlDirection,
  QizhenWeatherControlDirection
];

export interface QizhenWeatherBandControl {
  readonly bandIndex: QizhenWeatherBandIndex;
  readonly label: "低层" | "中层" | "高层";
  readonly backwardCode: "KeyZ" | "KeyA" | "KeyQ";
  readonly backwardKey: "Z" | "A" | "Q";
  readonly forwardCode: "KeyC" | "KeyD" | "KeyE";
  readonly forwardKey: "C" | "D" | "E";
}

export interface QizhenWeatherControlFrame {
  readonly positions: QizhenWeatherCloudPositions;
  readonly stableMs: number;
  readonly elapsedMs: number;
}

export interface QizhenWeatherControlSummary {
  moves: number;
  cloudOffsets: QizhenWeatherCloudPositions;
  controlledBands: readonly [boolean, boolean, boolean];
  stableMs: number;
  elapsedMs: number;
}

export const QIZHEN_WEATHER_POSITION_MIN = 2;
export const QIZHEN_WEATHER_POSITION_MAX = 98;
export const QIZHEN_WEATHER_TARGET_TOLERANCE = 8;
export const QIZHEN_WEATHER_STABLE_REQUIRED_MS = 1000;
export const QIZHEN_WEATHER_CONTROL_SPEED = 30;

/** Low, middle, and high cloud-band positions on a shared 0–100 track. */
export const QIZHEN_WEATHER_CLOUD_INITIAL = [78, 22, 38] as const;
export const QIZHEN_WEATHER_CLOUD_TARGET = [34, 52, 70] as const;
export const QIZHEN_WEATHER_WIND_SPEED = [5.5, 6.5, 7.5] as const;

/** Displayed from high to low so the key rows match the keyboard's Q/A/Z columns. */
export const QIZHEN_WEATHER_BAND_CONTROLS: readonly QizhenWeatherBandControl[] = Object.freeze([
  {
    bandIndex: 2,
    label: "高层",
    backwardCode: "KeyQ",
    backwardKey: "Q",
    forwardCode: "KeyE",
    forwardKey: "E"
  },
  {
    bandIndex: 1,
    label: "中层",
    backwardCode: "KeyA",
    backwardKey: "A",
    forwardCode: "KeyD",
    forwardKey: "D"
  },
  {
    bandIndex: 0,
    label: "低层",
    backwardCode: "KeyZ",
    backwardKey: "Z",
    forwardCode: "KeyC",
    forwardKey: "C"
  }
]);

export function createQizhenWeatherControlFrame(): QizhenWeatherControlFrame {
  return {
    positions: [...QIZHEN_WEATHER_CLOUD_INITIAL],
    stableMs: 0,
    elapsedMs: 0
  };
}

function clampPosition(value: number): number {
  return Math.min(QIZHEN_WEATHER_POSITION_MAX, Math.max(QIZHEN_WEATHER_POSITION_MIN, value));
}

export function isQizhenWeatherBandAligned(position: number, bandIndex: number): boolean {
  if (!Number.isFinite(position) || !Number.isInteger(bandIndex) || bandIndex < 0 || bandIndex > 2) return false;
  return Math.abs(position - QIZHEN_WEATHER_CLOUD_TARGET[bandIndex]) <= QIZHEN_WEATHER_TARGET_TOLERANCE;
}

export function isQizhenWeatherCloudAligned(positions: QizhenWeatherCloudPositions): boolean {
  return positions.every((position, index) => isQizhenWeatherBandAligned(position, index));
}

export function getQizhenWeatherAlignedBandCount(positions: QizhenWeatherCloudPositions): number {
  return positions.reduce(
    (count, position, index) => count + Number(isQizhenWeatherBandAligned(position, index)),
    0
  );
}

export function stepQizhenWeatherControl(
  frame: QizhenWeatherControlFrame,
  directions: QizhenWeatherControlDirections,
  deltaMs: number
): QizhenWeatherControlFrame {
  const boundedDeltaMs = Math.min(50, Math.max(0, Number.isFinite(deltaMs) ? deltaMs : 0));
  const deltaSeconds = boundedDeltaMs / 1000;
  const positions = frame.positions.map((position, index) => {
    const direction = directions[index] === -1 || directions[index] === 1 ? directions[index] : 0;
    const velocity = -QIZHEN_WEATHER_WIND_SPEED[index] + direction * QIZHEN_WEATHER_CONTROL_SPEED;
    return clampPosition(position + velocity * deltaSeconds);
  }) as [number, number, number];
  const aligned = isQizhenWeatherCloudAligned(positions);
  return {
    positions,
    stableMs: aligned
      ? Math.min(QIZHEN_WEATHER_STABLE_REQUIRED_MS, frame.stableMs + boundedDeltaMs)
      : 0,
    elapsedMs: frame.elapsedMs + boundedDeltaMs
  };
}

/** At least one deliberate correction is required on each of the three cloud bands. */
export function getQizhenWeatherMinimumMoves(): number {
  return 3;
}

export function isValidQizhenWeatherControlSummary(summary: QizhenWeatherControlSummary): boolean {
  return Number.isInteger(summary.moves)
    && summary.moves >= getQizhenWeatherMinimumMoves()
    && summary.cloudOffsets.length === QIZHEN_WEATHER_CLOUD_TARGET.length
    && summary.cloudOffsets.every((position) => Number.isFinite(position)
      && position >= QIZHEN_WEATHER_POSITION_MIN
      && position <= QIZHEN_WEATHER_POSITION_MAX)
    && summary.controlledBands.length === QIZHEN_WEATHER_CLOUD_TARGET.length
    && summary.controlledBands.every(Boolean)
    && Number.isFinite(summary.stableMs)
    && summary.stableMs >= QIZHEN_WEATHER_STABLE_REQUIRED_MS
    && Number.isFinite(summary.elapsedMs)
    && summary.elapsedMs >= summary.stableMs
    && isQizhenWeatherCloudAligned(summary.cloudOffsets);
}
