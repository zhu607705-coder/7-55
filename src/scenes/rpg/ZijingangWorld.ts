import Phaser from "phaser";
import {
  ZIJINGANG_LANDMARK_ASSETS,
  ZIJINGANG_BRIDGE_KEY,
  ZIJINGANG_ENVIRONMENT_KEY,
  ZIJINGANG_MAP_KEY,
  ZIJINGANG_TILESET_KEY
} from "./ZijingangLandmarkAssets";
import { ZIJINGANG_WORLD } from "./ZijingangWorldModel";

export { ZIJINGANG_WORLD } from "./ZijingangWorldModel";

type LabelTone = "blue" | "cyan" | "gold" | "green" | "red" | "silver";
type LandmarkAssetId = keyof typeof ZIJINGANG_LANDMARK_ASSETS;

interface ZijingangWorldOptions {
  addObstacle: (x: number, y: number, width: number, height: number) => void;
}

const LANDMARK_RENDERERS: Record<LandmarkAssetId, (
  scene: Phaser.Scene,
  x: number,
  y: number,
  addObstacle: ZijingangWorldOptions["addObstacle"],
  displayWidth: number
) => void> = {
  main_library: createMainLibrary,
  crescent_building: createCrescentBuilding,
  qiushi_auditorium: createAuditorium,
  management_school: createManagementSchool,
  foundation_library: createFoundationLibrary,
  zijingang_stadium: createStadium,
  south_gate: createSouthGate
};

export function drawZijingangWorld(scene: Phaser.Scene, { addObstacle }: ZijingangWorldOptions): void {
  const map = scene.make.tilemap({ key: ZIJINGANG_MAP_KEY });
  const tileset = map.addTilesetImage("zijingang_terrain", ZIJINGANG_TILESET_KEY);
  if (!tileset) {
    throw new Error("Zijingang terrain tileset failed to load");
  }

  ["Ground", "Roads", "Water", "Decor"].forEach((name, index) => {
    const layer = map.createLayer(name, tileset, 0, 0);
    if (!layer) {
      throw new Error(`Zijingang tile layer missing: ${name}`);
    }
    layer.setDepth(index);
  });

  drawRoadNetwork(scene, map);

  ["WaterCollisions", "StructureCollisions"].forEach((layerName) => {
    const collisionLayer = map.getObjectLayer(layerName);
    collisionLayer?.objects.forEach((object) => {
      const width = object.width ?? 0;
      const height = object.height ?? 0;
      addObstacle((object.x ?? 0) + width / 2, (object.y ?? 0) + height / 2, width, height);
    });
  });

  const environmentTexture = scene.textures.get(ZIJINGANG_ENVIRONMENT_KEY);
  environmentTexture.setFilter(Phaser.Textures.FilterMode.NEAREST);
  const environment = map.getObjectLayer("Environment");
  environment?.objects.forEach((object) => {
    const frame = readObjectNumber(object, "frame");
    const frameDisplayWidth = readObjectNumber(object, "displayWidth");
    const visualWidth = readObjectNumber(object, "visualWidth");
    const scaleClass = readObjectString(object, "scaleClass");
    const collisionWidth = readObjectNumber(object, "collisionWidth");
    const collisionHeight = readObjectNumber(object, "collisionHeight");
    const x = object.x ?? 0;
    const y = object.y ?? 0;
    if (object.name === "qizhen_bridge") {
      createQizhenBridge(scene, object, y, frameDisplayWidth);
      return;
    }
    const sprite = scene.add.image(x, y, ZIJINGANG_ENVIRONMENT_KEY, frame)
      .setOrigin(0.5, 1)
      .setDisplaySize(frameDisplayWidth, frameDisplayWidth)
      .setDepth(y)
      .setData("environmentAsset", object.name)
      .setData("visualWidth", visualWidth)
      .setData("scaleClass", scaleClass);

    if (collisionWidth > 0 && collisionHeight > 0) {
      addObstacle(x, y - collisionHeight / 2, collisionWidth, collisionHeight);
    }
    if (object.name === "great_lawn") {
      createLandmarkLabel(scene, x, y + 18, "大草坪", "green");
    } else if (object.name === "lake_heart_island") {
      createLandmarkLabel(scene, x, y + 14, "启真湖·湖心岛", "cyan");
    } else if (object.name === "nanhuayuan") {
      createLandmarkLabel(scene, x, y + 10, "南华园", "green");
    }
  });

  const landmarks = map.getObjectLayer("Landmarks");
  landmarks?.objects.forEach((object) => {
    const id = object.name as LandmarkAssetId;
    const render = LANDMARK_RENDERERS[id];
    if (render) {
      render(scene, object.x ?? 0, object.y ?? 0, addObstacle, readObjectNumber(object, "displayWidth"));
    }
  });

  createLandmarkLabel(scene, 1210, 790, "启真湖", "cyan");
}

function createQizhenBridge(
  scene: Phaser.Scene,
  object: Phaser.Types.Tilemaps.TiledObject,
  y: number,
  segmentWidth: number
): void {
  const texture = scene.textures.get(ZIJINGANG_BRIDGE_KEY);
  texture.setFilter(Phaser.Textures.FilterMode.NEAREST);
  const source = texture.getSourceImage() as { width: number; height: number };
  const segmentHeight = segmentWidth * (source.height / source.width);
  const spanStartX = readObjectNumber(object, "spanStartX");
  const spanEndX = readObjectNumber(object, "spanEndX");

  scene.add.image((spanStartX + spanEndX) / 2, y, ZIJINGANG_BRIDGE_KEY)
    .setOrigin(0.5)
    .setDisplaySize(segmentWidth, segmentHeight)
    .setDepth(y + 2)
    .setData("environmentAsset", object.name)
    .setData("bridgeSegment", 0);
}

function readObjectNumber(object: Phaser.Types.Tilemaps.TiledObject, propertyName: string): number {
  const properties = object.properties as Array<{ name: string; value: unknown }> | undefined;
  const property = properties?.find((candidate) => candidate.name === propertyName);
  return Number(property?.value) || 0;
}

function readObjectString(object: Phaser.Types.Tilemaps.TiledObject, propertyName: string): string {
  const properties = object.properties as Array<{ name: string; value: unknown }> | undefined;
  const property = properties?.find((candidate) => candidate.name === propertyName);
  return String(property?.value ?? "");
}

function drawRoadNetwork(scene: Phaser.Scene, map: Phaser.Tilemaps.Tilemap): void {
  const roadLayer = map.getObjectLayer("RoadPaths");
  if (!roadLayer) {
    return;
  }

  const routes = roadLayer.objects.flatMap((object) => {
    const polyline = object.polyline as Array<{ x: number; y: number }> | undefined;
    if (!polyline?.length) {
      return [];
    }
    const originX = object.x ?? 0;
    const originY = object.y ?? 0;
    const controlPoints = polyline.map((point) => new Phaser.Math.Vector2(originX + point.x, originY + point.y));
    const kind = readObjectString(object, "kind");
    if (kind === "road") {
      return [{ kind, points: controlPoints }];
    }
    const curve = new Phaser.Curves.Spline(controlPoints);
    const divisions = Math.max(12, Math.ceil(curve.getLength() / 12));
    return [{ kind, points: curve.getSpacedPoints(divisions) }];
  });

  const paths = routes.filter((route) => route.kind === "path");
  const roads = routes.filter((route) => route.kind === "road");
  const graphics = scene.add.graphics().setDepth(1);

  strokeRoutes(graphics, paths, 18, 0x334638, 0.62);
  strokeRoutes(graphics, paths, 15, 0xc9c2aa, 1);
  strokeRoutes(graphics, paths, 10, 0xa9a692, 1);
  strokeRoutes(graphics, paths, 2, 0xe1dccb, 0.8);

  strokeRoutes(graphics, roads, 34, 0x2b3a32, 0.62);
  strokeRoutes(graphics, roads, 30, 0xc9c5b6, 1);
  strokeRoutes(graphics, roads, 24, 0x4c5456, 1);
  strokeRoutes(graphics, roads, 2, 0x6a7476, 0.7);

  graphics.lineStyle(2, 0xe7d86e, 0.92);
  roads.forEach((route) => {
    graphics.beginPath();
    for (let index = 1; index < route.points.length; index += 5) {
      const from = route.points[index - 1];
      const to = route.points[Math.min(index + 1, route.points.length - 1)];
      graphics.moveTo(from.x, from.y);
      graphics.lineTo(to.x, to.y);
    }
    graphics.strokePath();
  });
}

function strokeRoutes(
  graphics: Phaser.GameObjects.Graphics,
  routes: Array<{ points: Phaser.Math.Vector2[] }>,
  width: number,
  color: number,
  alpha: number
): void {
  graphics.lineStyle(width, color, alpha);
  routes.forEach((route) => graphics.strokePoints(route.points, false, false));
}

function createLandmarkSprite(
  scene: Phaser.Scene,
  assetId: LandmarkAssetId,
  x: number,
  groundY: number,
  displayWidth: number
): Phaser.GameObjects.Image {
  const { key } = ZIJINGANG_LANDMARK_ASSETS[assetId];
  const texture = scene.textures.get(key);
  texture.setFilter(Phaser.Textures.FilterMode.NEAREST);
  const source = texture.getSourceImage() as { width: number; height: number };
  const displayHeight = displayWidth * (source.height / source.width);
  return scene.add.image(x, groundY, key)
    .setOrigin(0.5, 1)
    .setDisplaySize(displayWidth, displayHeight)
    .setDepth(groundY)
    .setData("landmarkAsset", assetId);
}

function createMainLibrary(
  scene: Phaser.Scene,
  x: number,
  y: number,
  addObstacle: ZijingangWorldOptions["addObstacle"],
  displayWidth: number
): void {
  const scale = displayWidth / 405;
  const sprite = createLandmarkSprite(scene, "main_library", x, y + 145 * scale, displayWidth);
  addObstacle(x - 8 * scale, y - 28 * scale, 330 * scale, 94 * scale);
  addObstacle(x + 8 * scale, y + 92 * scale, 290 * scale, 92 * scale);
  createLandmarkLabel(scene, x + 26 * scale, sprite.y - sprite.displayHeight - 15, "主图书馆", "cyan")
    .setData("anchorY", sprite.y);
}

function createCrescentBuilding(
  scene: Phaser.Scene,
  x: number,
  y: number,
  addObstacle: ZijingangWorldOptions["addObstacle"],
  displayWidth: number
): void {
  const scale = displayWidth / 430;
  const sprite = createLandmarkSprite(scene, "crescent_building", x, y + 155 * scale, displayWidth);
  addObstacle(x, y + 36 * scale, 410 * scale, 188 * scale);
  createLandmarkLabel(scene, x, sprite.y - sprite.displayHeight - 15, "月牙楼", "silver")
    .setData("anchorY", sprite.y);
}

function createAuditorium(
  scene: Phaser.Scene,
  x: number,
  y: number,
  addObstacle: ZijingangWorldOptions["addObstacle"],
  displayWidth: number
): void {
  const scale = displayWidth / 330;
  const sprite = createLandmarkSprite(scene, "qiushi_auditorium", x + 12 * scale, y + 112 * scale, displayWidth);
  addObstacle(x + 15 * scale, y + 2 * scale, 325 * scale, 132 * scale);
  createLandmarkLabel(scene, x + 18 * scale, sprite.y - sprite.displayHeight - 15, "求是大讲堂", "red")
    .setData("anchorY", sprite.y);
}

function createManagementSchool(
  scene: Phaser.Scene,
  x: number,
  y: number,
  addObstacle: ZijingangWorldOptions["addObstacle"],
  displayWidth: number
): void {
  const scale = displayWidth / 370;
  const sprite = createLandmarkSprite(scene, "management_school", x, y + 188 * scale, displayWidth);
  addObstacle(x - 92 * scale, y - 28 * scale, 104 * scale, 178 * scale);
  addObstacle(x + 98 * scale, y + 2 * scale, 104 * scale, 178 * scale);
  addObstacle(x + 2 * scale, y + 103 * scale, 116 * scale, 142 * scale);
  createLandmarkLabel(scene, x + 154 * scale, sprite.y - sprite.displayHeight - 15, "管理学院", "gold")
    .setData("anchorY", sprite.y);
}

function createFoundationLibrary(
  scene: Phaser.Scene,
  x: number,
  y: number,
  _addObstacle: ZijingangWorldOptions["addObstacle"],
  displayWidth: number
): void {
  const scale = displayWidth / 390;
  const sprite = createLandmarkSprite(scene, "foundation_library", x + 20 * scale, y + 222 * scale, displayWidth);
  createLandmarkLabel(scene, x + 26 * scale, sprite.y - sprite.displayHeight - 15, "基础图书馆", "blue")
    .setData("anchorY", sprite.y);
}

function createStadium(
  scene: Phaser.Scene,
  x: number,
  y: number,
  addObstacle: ZijingangWorldOptions["addObstacle"],
  displayWidth: number
): void {
  const scale = displayWidth / 430;
  const sprite = createLandmarkSprite(scene, "zijingang_stadium", x, y + 145 * scale, displayWidth);
  addObstacle(x, y + 20 * scale, 392 * scale, 258 * scale);
  createLandmarkLabel(scene, x, sprite.y - sprite.displayHeight - 15, "紫金港体育馆", "silver")
    .setData("anchorY", sprite.y);
}

function createSouthGate(
  scene: Phaser.Scene,
  x: number,
  y: number,
  addObstacle: ZijingangWorldOptions["addObstacle"],
  displayWidth: number
): void {
  const scale = displayWidth / 480;
  createLandmarkSprite(scene, "south_gate", x + 28 * scale, y + 100 * scale, displayWidth);
  addObstacle(x, y + 72 * scale, 450 * scale, 56 * scale);
  createLandmarkLabel(scene, x + 38 * scale, y + 12 * scale, "南大门", "blue");
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
    .setData("revealRadius", 235);
}
