import type { WalkabilityMaskData } from "./CampusPathfinder";

export interface TileCampusCollisionRect {
  x: number;
  y: number;
  width: number;
  height: number;
}

export const ZIJINGANG_TILE_CAMPUS = Object.freeze({
  world: { width: 2400, height: 1600 },
  spawns: {
    dormExit: { x: 700, y: 1530 },
    libraryExit: { x: 1630, y: 1008 },
    canteenApproach: { x: 2200, y: 1168 },
    theaterJunction: { x: 900, y: 940 }
  },
  gates: {
    library: { x: 1630, y: 990, radius: 104 },
    canteen: { x: 2200, y: 1120, radius: 116 },
    theater: { x: 850, y: 820, radius: 150 }
  },
  canteen: {
    building: { x: 2200, groundY: 1085, width: 330, height: 238 },
    bike: { x: 2088, y: 1138 },
    huntSpawn: { x: 1630, y: 1048 }
  }
} as const);

/**
 * Build a conservative browser-side navigation mask from the same rectangles
 * used by Arcade Physics. This keeps click-to-move and keyboard collision on
 * one Tiled coordinate system without introducing another authored map.
 */
export function createTileCampusWalkabilityMask(
  obstacles: readonly TileCampusCollisionRect[],
  cellSize = 8,
  paddingX = 12,
  paddingY = 10
): WalkabilityMaskData {
  const { width, height } = ZIJINGANG_TILE_CAMPUS.world;
  const gridWidth = Math.ceil(width / cellSize);
  const gridHeight = Math.ceil(height / cellSize);
  const bitCount = gridWidth * gridHeight;
  const bytes = new Uint8Array(Math.ceil(bitCount / 8));
  bytes.fill(0xff);

  const setBlocked = (cellX: number, cellY: number) => {
    if (cellX < 0 || cellY < 0 || cellX >= gridWidth || cellY >= gridHeight) return;
    const bitIndex = cellY * gridWidth + cellX;
    bytes[bitIndex >> 3] &= ~(1 << (bitIndex & 7));
  };

  obstacles.forEach((rect) => {
    const left = Math.max(0, rect.x - rect.width / 2 - paddingX);
    const right = Math.min(width, rect.x + rect.width / 2 + paddingX);
    const top = Math.max(0, rect.y - rect.height / 2 - paddingY);
    const bottom = Math.min(height, rect.y + rect.height / 2 + paddingY);
    const startX = Math.floor(left / cellSize);
    const endX = Math.ceil(right / cellSize);
    const startY = Math.floor(top / cellSize);
    const endY = Math.ceil(bottom / cellSize);
    for (let cellY = startY; cellY < endY; cellY += 1) {
      for (let cellX = startX; cellX < endX; cellX += 1) {
        setBlocked(cellX, cellY);
      }
    }
  });

  // Clear unused trailing bits so malformed dimensions cannot expose cells.
  for (let bitIndex = bitCount; bitIndex < bytes.length * 8; bitIndex += 1) {
    bytes[bitIndex >> 3] &= ~(1 << (bitIndex & 7));
  }

  let binary = "";
  for (let index = 0; index < bytes.length; index += 0x8000) {
    binary += String.fromCharCode(...bytes.subarray(index, index + 0x8000));
  }
  return {
    cellSize,
    gridWidth,
    gridHeight,
    bitsBase64: globalThis.btoa(binary)
  };
}
