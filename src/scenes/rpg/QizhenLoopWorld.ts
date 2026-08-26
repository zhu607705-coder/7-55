import Phaser from "phaser";
import loopPanoramaUrl from "../../assets/rpg/campus/zijingang_campus_loop_panorama.png";
import loopRuntime from "../../data/maps/zijingang-campus-loop-runtime.json";

export const QIZHEN_LOOP_PANORAMA_KEY = "qizhen-loop-panorama";
export const QIZHEN_LOOP_PANORAMA_URL = loopPanoramaUrl;
export const QIZHEN_LOOP_RUNTIME = loopRuntime;

interface CollisionRect {
  x: number;
  y: number;
  width: number;
  height: number;
}

interface QizhenLoopWorldOptions {
  addObstacle: (x: number, y: number, width: number, height: number) => void;
}

export function preloadQizhenLoopWorld(scene: Phaser.Scene): void {
  if (!scene.textures.exists(QIZHEN_LOOP_PANORAMA_KEY)) {
    scene.load.image(QIZHEN_LOOP_PANORAMA_KEY, QIZHEN_LOOP_PANORAMA_URL);
  }
}

function decodeMaskBits(bitsBase64: string): Uint8Array {
  const binary = globalThis.atob(bitsBase64);
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
}

function collisionRectsFromWalkability(): CollisionRect[] {
  const walkability = loopRuntime.walkability;
  const bytes = decodeMaskBits(walkability.bitsBase64);
  const active = new Map<string, { x: number; y: number; width: number; height: number }>();
  const completed: Array<{ x: number; y: number; width: number; height: number }> = [];

  for (let y = 0; y < walkability.gridHeight; y += 1) {
    const next = new Map<string, { x: number; y: number; width: number; height: number }>();
    let runStart = -1;
    for (let x = 0; x <= walkability.gridWidth; x += 1) {
      const cellIndex = y * walkability.gridWidth + x;
      const walkable = x < walkability.gridWidth
        && ((bytes[cellIndex >> 3] >> (cellIndex & 7)) & 1) === 1;
      if (!walkable && runStart < 0 && x < walkability.gridWidth) runStart = x;
      if ((walkable || x === walkability.gridWidth) && runStart >= 0) {
        const width = x - runStart;
        const key = `${runStart}:${width}`;
        const existing = active.get(key);
        if (existing) {
          existing.height += 1;
          next.set(key, existing);
        } else {
          next.set(key, { x: runStart, y, width, height: 1 });
        }
        runStart = -1;
      }
    }
    active.forEach((run, key) => {
      if (!next.has(key)) completed.push(run);
    });
    active.clear();
    next.forEach((run, key) => active.set(key, run));
  }
  active.forEach((run) => completed.push(run));

  return completed.map((run) => ({
    x: (run.x + run.width / 2) * walkability.cellSize,
    y: (run.y + run.height / 2) * walkability.cellSize,
    width: run.width * walkability.cellSize,
    height: run.height * walkability.cellSize
  }));
}

const COLLISION_RECTS = collisionRectsFromWalkability();

export function drawQizhenLoopWorld(
  scene: Phaser.Scene,
  { addObstacle }: QizhenLoopWorldOptions
): void {
  const texture = scene.textures.get(QIZHEN_LOOP_PANORAMA_KEY);
  const source = texture.getSourceImage() as HTMLImageElement;
  if (source.naturalWidth !== loopRuntime.world.width || source.naturalHeight !== loopRuntime.world.height) {
    throw new Error(
      `Qizhen loop panorama mismatch: expected ${loopRuntime.world.width}x${loopRuntime.world.height}, received ${source.naturalWidth}x${source.naturalHeight}`
    );
  }
  texture.setFilter(Phaser.Textures.FilterMode.LINEAR);
  scene.add.image(0, 0, QIZHEN_LOOP_PANORAMA_KEY)
    .setOrigin(0)
    .setDepth(0)
    .setData("campusProjection", "side-view-pseudo-2.5d-qizhen-corridor");
  COLLISION_RECTS.forEach((rect) => addObstacle(rect.x, rect.y, rect.width, rect.height));
}
