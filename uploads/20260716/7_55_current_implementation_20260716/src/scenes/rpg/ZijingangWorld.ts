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

const campusRuntime = campusRuntimeData as {
  collisions: {
    buildings: CollisionRect[];
    water: CollisionRect[];
  };
};

const LANDMARK_TONES: Record<keyof typeof ZIJINGANG_CAMPUS_LANDMARKS, LabelTone> = {
  main_library: "cyan",
  qiushi_auditorium: "red",
  crescent_building: "silver",
  foundation_library: "blue",
  information_tower: "cyan",
  asia_games_hall: "gold",
  indoor_stadium: "silver",
  west_track: "green",
  east_track: "green",
  nanhuayuan: "green",
  south_gate: "blue"
};

export function drawZijingangWorld(scene: Phaser.Scene, { addObstacle }: ZijingangWorldOptions): void {
  const texture = scene.textures.get(ZIJINGANG_CAMPUS_PLATE_KEY);
  const source = texture.getSourceImage() as HTMLImageElement;
  if (source.naturalWidth !== ZIJINGANG_WORLD.width || source.naturalHeight !== ZIJINGANG_WORLD.height) {
    throw new Error(
      `Campus plate must match the top-down world: expected ${ZIJINGANG_WORLD.width}x${ZIJINGANG_WORLD.height}, received ${source.naturalWidth}x${source.naturalHeight}`
    );
  }
  texture.setFilter(Phaser.Textures.FilterMode.NEAREST);
  scene.add.image(0, 0, ZIJINGANG_CAMPUS_PLATE_KEY)
    .setOrigin(0)
    .setDepth(0)
    .setData("campusProjection", "top-down-90deg");

  [...campusRuntime.collisions.buildings, ...campusRuntime.collisions.water].forEach((rect) => {
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

  createLandmarkLabel(scene, 1032, 1057, "启真湖", "cyan")
    .setData("anchorX", 1032)
    .setData("anchorY", 1057)
    .setData("revealRadius", 190);
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
