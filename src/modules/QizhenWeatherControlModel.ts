export const QIZHEN_WEATHER_CLOUD_SLOT_COUNT = 5;

export const QIZHEN_WEATHER_CLOUD_INITIAL = [4, 0, 1] as const;
export const QIZHEN_WEATHER_CLOUD_TARGET = [1, 2, 3] as const;

export type QizhenWeatherCloudOffsets = readonly [number, number, number];

export interface QizhenWeatherControlSummary {
  moves: number;
  cloudOffsets: QizhenWeatherCloudOffsets;
}

export function moveQizhenWeatherCloud(
  offsets: QizhenWeatherCloudOffsets,
  bandIndex: number,
  direction: -1 | 1
): QizhenWeatherCloudOffsets {
  if (!Number.isInteger(bandIndex) || bandIndex < 0 || bandIndex >= offsets.length) return offsets;
  const next = [...offsets] as [number, number, number];
  next[bandIndex] = (next[bandIndex] + direction + QIZHEN_WEATHER_CLOUD_SLOT_COUNT)
    % QIZHEN_WEATHER_CLOUD_SLOT_COUNT;
  return next;
}

export function isQizhenWeatherCloudAligned(offsets: QizhenWeatherCloudOffsets): boolean {
  return offsets.every((offset, index) => offset === QIZHEN_WEATHER_CLOUD_TARGET[index]);
}

export function getQizhenWeatherAlignedBandCount(offsets: QizhenWeatherCloudOffsets): number {
  return offsets.reduce(
    (count, offset, index) => count + Number(offset === QIZHEN_WEATHER_CLOUD_TARGET[index]),
    0
  );
}

export function getQizhenWeatherMinimumMoves(): number {
  return QIZHEN_WEATHER_CLOUD_INITIAL.reduce<number>((total, offset, index) => {
    const target = QIZHEN_WEATHER_CLOUD_TARGET[index];
    const clockwise = (target - offset + QIZHEN_WEATHER_CLOUD_SLOT_COUNT) % QIZHEN_WEATHER_CLOUD_SLOT_COUNT;
    const counterClockwise = (offset - target + QIZHEN_WEATHER_CLOUD_SLOT_COUNT) % QIZHEN_WEATHER_CLOUD_SLOT_COUNT;
    return total + Math.min(clockwise, counterClockwise);
  }, 0);
}

export function isValidQizhenWeatherControlSummary(summary: QizhenWeatherControlSummary): boolean {
  return Number.isInteger(summary.moves)
    && summary.moves >= getQizhenWeatherMinimumMoves()
    && summary.cloudOffsets.length === QIZHEN_WEATHER_CLOUD_TARGET.length
    && summary.cloudOffsets.every((offset) => Number.isInteger(offset)
      && offset >= 0
      && offset < QIZHEN_WEATHER_CLOUD_SLOT_COUNT)
    && isQizhenWeatherCloudAligned(summary.cloudOffsets);
}
