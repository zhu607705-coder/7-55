import Phaser from "phaser";
import campusRuntimeData from "../../data/maps/zijingang-campus-runtime.json";
import { ZIJINGANG_CAMPUS_LANDMARKS } from "./ZijingangCampusLayout";
import { ZIJINGANG_CAMPUS_PLATE_KEY } from "./ZijingangLandmarkAssets";
import { ZIJINGANG_WORLD } from "./ZijingangWorldModel";

export { ZIJINGANG_WORLD } from "./ZijingangWorldModel";

type LabelTone = "blue" | "cyan" | "gold" | "green" | "red" | "silver";

interface CollisionRect {
  x: number;
  y: number;
  width: number;
  height: number;
}

interface ZijingangWorldOptions {
  addObstacle: (x: number, y: number, width: number, height: number) => void;
}

interface CampusRuntimeCollisionData {
  collisions?: {
    buildings: CollisionRect[];
    water: CollisionRect[];
  };
  walkability?: {
    cellSize: number;
    gridWidth: number;
    gridHeight: number;
    bitsBase64: string;
  };
}

interface GridCollisionRun {
  x: number;
  y: number;
  width: number;
  height: number;
}

const campusRuntime = campusRuntimeData as unknown as CampusRuntimeCollisionData;

function decodeBase64Bytes(value: string): Uint8Array {
  const decoded = window.atob(value);
  return Uint8Array.from(decoded, (character) => character.charCodeAt(0));
}

function collisionRectsFromWalkability(): CollisionRect[] {
  if (campusRuntime.collisions) {
    return [...campusRuntime.collisions.buildings, ...campusRuntime.collisions.water];
  }
  const walkability = campusRuntime.walkability;
  if (!walkability) {
    throw new Error("Campus runtime must provide collisions or a walkability mask");
  }

  const bytes = decodeBase64Bytes(walkability.bitsBase64);
  const active = new Map<string, GridCollisionRun>();
  const completed: GridCollisionRun[] = [];

  for (let y = 0; y < walkability.gridHeight; y += 1) {
    const next = new Map<string, GridCollisionRun>();
    let runStart = -1;
    for (let x = 0; x <= walkability.gridWidth; x += 1) {
      const cellIndex = y * walkability.gridWidth + x;
      const walkable = x < walkability.gridWidth
        && ((bytes[cellIndex >> 3] >> (cellIndex & 7)) & 1) === 1;
      if (!walkable && runStart < 0 && x < walkability.gridWidth) {
        runStart = x;
      }
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

const CAMPUS_COLLISION_RECTS = collisionRectsFromWalkability();

const LANDMARK_TONES: Record<keyof typeof ZIJINGANG_CAMPUS_LANDMARKS, LabelTone> = {};

export function drawZijingangWorld(scene: Phaser.Scene, { addObstacle }: ZijingangWorldOptions): void {
  const texture = scene.textures.get(ZIJINGANG_CAMPUS_PLATE_KEY);
  const source = texture.getSourceImage() as HTMLImageElement;
  if (source.naturalWidth !== ZIJINGANG_WORLD.width || source.naturalHeight !== ZIJINGANG_WORLD.height) {
    throw new Error(
      `Campus plate must match the top-down world: expected ${ZIJINGANG_WORLD.width}x${ZIJINGANG_WORLD.height}, received ${source.naturalWidth}x${source.naturalHeight}`
    );
  }
  texture.setFilter(Phaser.Textures.FilterMode.LINEAR);
  scene.add.image(0, 0, ZIJINGANG_CAMPUS_PLATE_KEY)
    .setOrigin(0)
    .setDepth(0)
    .setData("campusProjection", "wide-panorama-2.5d");

  CAMPUS_COLLISION_RECTS.forEach((rect) => {
    addObstacle(rect.x, rect.y, rect.width, rect.height);
  });

  Object.values(ZIJINGANG_CAMPUS_LANDMARKS).forEach((landmark) => {
    const label = createLandmarkLabel(
      scene,
      landmark.worldCenter.x,
      landmark.worldCenter.y - landmark.visualFootprint.height / 2 - 18,
      landmark.label,
      LANDMARK_TONES[landmark.id]
    );
    label
      .setData("anchorX", landmark.worldCenter.x)
      .setData("anchorY", landmark.worldCenter.y)
      .setData("revealRadius", Math.max(150, Math.min(225, landmark.visualFootprint.width + 72)));
  });
}

export function createLandmarkLabel(
  scene: Phaser.Scene,
  x: number,
  y: number,
  text: string,
  tone: LabelTone
): Phaser.GameObjects.Text {
  const accents = {
    blue: "#5ba2e6",
    cyan: "#74d4db",
    gold: "#f0d54e",
    green: "#83c77b",
    red: "#e97b70",
    silver: "#d6d8d8"
  } as const;
  return scene.add.text(x, y, text, {
    color: "#ffffff",
    fontFamily: "monospace",
    fontSize: "15px",
    backgroundColor: "#13202bea",
    padding: { x: 8, y: 5 },
    stroke: accents[tone],
    strokeThickness: 1
  })
    .setOrigin(0.5)
    .setDepth(10000)
    .setVisible(false)
    .setData("contextualLandmark", true)
    .setData("anchorX", x)
    .setData("anchorY", y)
    .setData("revealRadius", 190);
}
