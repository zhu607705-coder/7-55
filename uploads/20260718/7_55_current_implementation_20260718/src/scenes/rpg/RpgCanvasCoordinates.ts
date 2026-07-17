export interface CanvasRectLike {
  left: number;
  top: number;
  width: number;
  height: number;
}

export interface RpgCanvasPoint {
  x: number;
  y: number;
}

export const RPG_CANVAS_WIDTH = 960;
export const RPG_CANVAS_HEIGHT = 540;

export function clientToRpgCanvasPoint(
  clientX: number,
  clientY: number,
  rect: CanvasRectLike,
  logicalWidth = RPG_CANVAS_WIDTH,
  logicalHeight = RPG_CANVAS_HEIGHT
): RpgCanvasPoint | null {
  if (
    !Number.isFinite(clientX)
    || !Number.isFinite(clientY)
    || rect.width <= 0
    || rect.height <= 0
    || logicalWidth <= 0
    || logicalHeight <= 0
  ) {
    return null;
  }

  const localX = clientX - rect.left;
  const localY = clientY - rect.top;
  if (localX < 0 || localY < 0 || localX > rect.width || localY > rect.height) {
    return null;
  }

  return {
    x: localX * (logicalWidth / rect.width),
    y: localY * (logicalHeight / rect.height)
  };
}
