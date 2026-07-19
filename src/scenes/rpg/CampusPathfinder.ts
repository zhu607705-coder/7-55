export interface WalkabilityMaskData {
  cellSize: number;
  gridWidth: number;
  gridHeight: number;
  bitsBase64: string;
}

export interface CampusPathPoint {
  x: number;
  y: number;
}

const DEFAULT_SAMPLE_CELL_SIZE = 16;
const DEFAULT_SNAP_RADIUS_PX = 96;
const DEFAULT_MAX_ITERATIONS = 60000;
const SQRT2 = Math.SQRT2;
const OCTILE_DIAGONAL_BIAS = Math.SQRT2 - 1;

function decodeMaskBits(bitsBase64: string): Uint8Array {
  const binary = globalThis.atob(bitsBase64);
  const bytes = new Uint8Array(binary.length);
  for (let index = 0; index < binary.length; index += 1) {
    bytes[index] = binary.charCodeAt(index);
  }
  return bytes;
}

class BinaryMinHeap {
  private readonly items: number[] = [];

  constructor(private readonly scores: Float64Array) {}

  get size(): number {
    return this.items.length;
  }

  clear(): void {
    this.items.length = 0;
  }

  push(item: number): void {
    const items = this.items;
    items.push(item);
    let index = items.length - 1;
    while (index > 0) {
      const parent = (index - 1) >> 1;
      if (this.scores[items[parent]] <= this.scores[items[index]]) {
        break;
      }
      const swap = items[parent];
      items[parent] = items[index];
      items[index] = swap;
      index = parent;
    }
  }

  pop(): number {
    const items = this.items;
    const top = items[0];
    const last = items.pop();
    if (last !== undefined && items.length > 0) {
      items[0] = last;
      let index = 0;
      for (;;) {
        const left = index * 2 + 1;
        const right = left + 1;
        let smallest = index;
        if (left < items.length && this.scores[items[left]] < this.scores[items[smallest]]) {
          smallest = left;
        }
        if (right < items.length && this.scores[items[right]] < this.scores[items[smallest]]) {
          smallest = right;
        }
        if (smallest === index) {
          break;
        }
        const swap = items[smallest];
        items[smallest] = items[index];
        items[index] = swap;
        index = smallest;
      }
    }
    return top;
  }
}

export class CampusPathGrid {
  readonly navCellSize: number;
  readonly navWidth: number;
  readonly navHeight: number;

  private readonly worldWidth: number;
  private readonly worldHeight: number;
  private readonly cells: Uint8Array;
  private readonly gScores: Float64Array;
  private readonly fScores: Float64Array;
  private readonly cameFrom: Int32Array;
  private readonly cellState: Uint8Array;
  private readonly openHeap: BinaryMinHeap;

  constructor(mask: WalkabilityMaskData, sampleCellSize = DEFAULT_SAMPLE_CELL_SIZE) {
    if (
      !mask
      || !Number.isFinite(mask.cellSize)
      || mask.cellSize <= 0
      || !Number.isInteger(mask.gridWidth)
      || mask.gridWidth <= 0
      || !Number.isInteger(mask.gridHeight)
      || mask.gridHeight <= 0
    ) {
      throw new Error("CampusPathGrid requires a valid walkability mask");
    }
    const mergeRatio = Math.max(1, Math.round(sampleCellSize / mask.cellSize));
    this.navCellSize = mask.cellSize * mergeRatio;
    this.navWidth = Math.ceil(mask.gridWidth / mergeRatio);
    this.navHeight = Math.ceil(mask.gridHeight / mergeRatio);
    this.worldWidth = mask.gridWidth * mask.cellSize;
    this.worldHeight = mask.gridHeight * mask.cellSize;

    const bytes = decodeMaskBits(mask.bitsBase64);
    const cells = new Uint8Array(this.navWidth * this.navHeight);
    for (let navY = 0; navY < this.navHeight; navY += 1) {
      const sourceY0 = navY * mergeRatio;
      const sourceY1 = Math.min(sourceY0 + mergeRatio, mask.gridHeight);
      for (let navX = 0; navX < this.navWidth; navX += 1) {
        const sourceX0 = navX * mergeRatio;
        const sourceX1 = Math.min(sourceX0 + mergeRatio, mask.gridWidth);
        // conservative merge: a nav cell is walkable only if every source cell inside it is
        let walkable = 1;
        for (let sourceY = sourceY0; sourceY < sourceY1 && walkable === 1; sourceY += 1) {
          const rowOffset = sourceY * mask.gridWidth;
          for (let sourceX = sourceX0; sourceX < sourceX1; sourceX += 1) {
            const bitIndex = rowOffset + sourceX;
            if ((bytes[bitIndex >> 3] & (1 << (bitIndex & 7))) === 0) {
              walkable = 0;
              break;
            }
          }
        }
        cells[navY * this.navWidth + navX] = walkable;
      }
    }
    this.cells = cells;

    const cellCount = this.navWidth * this.navHeight;
    this.gScores = new Float64Array(cellCount);
    this.fScores = new Float64Array(cellCount);
    this.cameFrom = new Int32Array(cellCount);
    this.cellState = new Uint8Array(cellCount);
    this.openHeap = new BinaryMinHeap(this.fScores);
  }

  isWalkablePoint(x: number, y: number): boolean {
    if (!Number.isFinite(x) || !Number.isFinite(y)) {
      return false;
    }
    if (x < 0 || y < 0 || x >= this.worldWidth || y >= this.worldHeight) {
      return false;
    }
    const navX = Math.floor(x / this.navCellSize);
    const navY = Math.floor(y / this.navCellSize);
    return this.cells[navY * this.navWidth + navX] === 1;
  }

  nearestWalkable(x: number, y: number, maxRadiusPx = DEFAULT_SNAP_RADIUS_PX): CampusPathPoint | null {
    if (!Number.isFinite(x) || !Number.isFinite(y) || !(maxRadiusPx >= 0)) {
      return null;
    }
    const centerX = Math.min(Math.max(Math.floor(x / this.navCellSize), 0), this.navWidth - 1);
    const centerY = Math.min(Math.max(Math.floor(y / this.navCellSize), 0), this.navHeight - 1);
    const maxRing = Math.ceil(maxRadiusPx / this.navCellSize);
    const maxDistSq = maxRadiusPx * maxRadiusPx;
    for (let ring = 0; ring <= maxRing; ring += 1) {
      let bestIndex = -1;
      let bestDistSq = Infinity;
      for (let offsetY = -ring; offsetY <= ring; offsetY += 1) {
        for (let offsetX = -ring; offsetX <= ring; offsetX += 1) {
          if (Math.max(Math.abs(offsetX), Math.abs(offsetY)) !== ring) {
            continue;
          }
          const navX = centerX + offsetX;
          const navY = centerY + offsetY;
          if (navX < 0 || navY < 0 || navX >= this.navWidth || navY >= this.navHeight) {
            continue;
          }
          const cellIndex = navY * this.navWidth + navX;
          if (this.cells[cellIndex] !== 1) {
            continue;
          }
          const pointX = (navX + 0.5) * this.navCellSize;
          const pointY = (navY + 0.5) * this.navCellSize;
          const distSq = (pointX - x) * (pointX - x) + (pointY - y) * (pointY - y);
          if (distSq <= maxDistSq && distSq < bestDistSq) {
            bestDistSq = distSq;
            bestIndex = cellIndex;
          }
        }
      }
      if (bestIndex >= 0) {
        return this.cellCenter(bestIndex);
      }
    }
    return null;
  }

  findPath(
    from: CampusPathPoint,
    to: CampusPathPoint,
    maxIterations = DEFAULT_MAX_ITERATIONS
  ): CampusPathPoint[] | null {
    if (
      !from
      || !to
      || !Number.isFinite(from.x)
      || !Number.isFinite(from.y)
      || !Number.isFinite(to.x)
      || !Number.isFinite(to.y)
    ) {
      return null;
    }
    const start = this.isWalkablePoint(from.x, from.y)
      ? { x: from.x, y: from.y }
      : this.nearestWalkable(from.x, from.y);
    const goal = this.isWalkablePoint(to.x, to.y)
      ? { x: to.x, y: to.y }
      : this.nearestWalkable(to.x, to.y);
    if (!start || !goal) {
      return null;
    }
    const startCell = this.cellIndexAt(start.x, start.y);
    const goalCell = this.cellIndexAt(goal.x, goal.y);
    if (startCell === goalCell) {
      return [{ x: goal.x, y: goal.y }];
    }

    const pathCells = this.searchCells(startCell, goalCell, maxIterations);
    if (!pathCells) {
      return null;
    }
    const smoothed = this.smoothCells(pathCells);
    return smoothed.map((cellIndex, index) => {
      if (index === 0) {
        return { x: start.x, y: start.y };
      }
      if (index === smoothed.length - 1) {
        return { x: goal.x, y: goal.y };
      }
      return this.cellCenter(cellIndex);
    });
  }

  private cellIndexAt(x: number, y: number): number {
    const navX = Math.min(Math.max(Math.floor(x / this.navCellSize), 0), this.navWidth - 1);
    const navY = Math.min(Math.max(Math.floor(y / this.navCellSize), 0), this.navHeight - 1);
    return navY * this.navWidth + navX;
  }

  private cellCenter(cellIndex: number): CampusPathPoint {
    const navX = cellIndex % this.navWidth;
    const navY = Math.floor(cellIndex / this.navWidth);
    return {
      x: (navX + 0.5) * this.navCellSize,
      y: (navY + 0.5) * this.navCellSize
    };
  }

  private searchCells(startCell: number, goalCell: number, maxIterations: number): number[] | null {
    const width = this.navWidth;
    const height = this.navHeight;
    const gScores = this.gScores;
    const fScores = this.fScores;
    const cameFrom = this.cameFrom;
    const cellState = this.cellState;
    gScores.fill(Infinity);
    cameFrom.fill(-1);
    cellState.fill(0);
    this.openHeap.clear();

    const goalX = goalCell % width;
    const goalY = Math.floor(goalCell / width);
    gScores[startCell] = 0;
    fScores[startCell] = this.octile(startCell % width, Math.floor(startCell / width), goalX, goalY);
    cellState[startCell] = 1;
    this.openHeap.push(startCell);

    let iterations = 0;
    while (this.openHeap.size > 0) {
      if (iterations >= maxIterations) {
        return null;
      }
      iterations += 1;
      const current = this.openHeap.pop();
      if (cellState[current] === 2) {
        continue;
      }
      cellState[current] = 2;
      if (current === goalCell) {
        return this.reconstructCells(startCell, goalCell);
      }
      const currentX = current % width;
      const currentY = Math.floor(current / width);
      for (let stepY = -1; stepY <= 1; stepY += 1) {
        for (let stepX = -1; stepX <= 1; stepX += 1) {
          if (stepX === 0 && stepY === 0) {
            continue;
          }
          const nextX = currentX + stepX;
          const nextY = currentY + stepY;
          if (nextX < 0 || nextY < 0 || nextX >= width || nextY >= height) {
            continue;
          }
          const next = nextY * width + nextX;
          if (this.cells[next] !== 1 || cellState[next] === 2) {
            continue;
          }
          const diagonal = stepX !== 0 && stepY !== 0;
          if (
            diagonal
            && this.cells[currentY * width + nextX] !== 1
            && this.cells[nextY * width + currentX] !== 1
          ) {
            // no corner cutting: a diagonal is blocked when both orthogonal neighbors are blocked
            continue;
          }
          const tentativeG = gScores[current] + (diagonal ? SQRT2 : 1);
          if (tentativeG < gScores[next]) {
            gScores[next] = tentativeG;
            fScores[next] = tentativeG + this.octile(nextX, nextY, goalX, goalY);
            cameFrom[next] = current;
            cellState[next] = 1;
            this.openHeap.push(next);
          }
        }
      }
    }
    return null;
  }

  private reconstructCells(startCell: number, goalCell: number): number[] {
    const reversed: number[] = [];
    let cursor = goalCell;
    for (;;) {
      reversed.push(cursor);
      if (cursor === startCell) {
        break;
      }
      cursor = this.cameFrom[cursor];
    }
    return reversed.reverse();
  }

  private smoothCells(pathCells: number[]): number[] {
    if (pathCells.length <= 2) {
      return pathCells;
    }
    const smoothed: number[] = [pathCells[0]];
    let anchor = 0;
    while (anchor < pathCells.length - 1) {
      let next = anchor + 1;
      for (let candidate = pathCells.length - 1; candidate > anchor + 1; candidate -= 1) {
        if (this.hasLineOfSight(pathCells[anchor], pathCells[candidate])) {
          next = candidate;
          break;
        }
      }
      smoothed.push(pathCells[next]);
      anchor = next;
    }
    return smoothed;
  }

  private hasLineOfSight(fromCell: number, toCell: number): boolean {
    const width = this.navWidth;
    let x = fromCell % width;
    let y = Math.floor(fromCell / width);
    const targetX = toCell % width;
    const targetY = Math.floor(toCell / width);
    const deltaX = Math.abs(targetX - x);
    const deltaY = Math.abs(targetY - y);
    const stepX = x < targetX ? 1 : -1;
    const stepY = y < targetY ? 1 : -1;
    let error = deltaX - deltaY;
    for (;;) {
      if (this.cells[y * width + x] !== 1) {
        return false;
      }
      if (x === targetX && y === targetY) {
        return true;
      }
      const doubledError = error * 2;
      if (doubledError > -deltaY) {
        error -= deltaY;
        x += stepX;
      }
      if (doubledError < deltaX) {
        error += deltaX;
        y += stepY;
      }
    }
  }

  private octile(fromX: number, fromY: number, toX: number, toY: number): number {
    const deltaX = Math.abs(toX - fromX);
    const deltaY = Math.abs(toY - fromY);
    return Math.max(deltaX, deltaY) + OCTILE_DIAGONAL_BIAS * Math.min(deltaX, deltaY);
  }
}
