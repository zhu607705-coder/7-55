import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const output = join(root, "src/data/maps/zijingang-campus.json");
const width = 75;
const height = 50;
const tile = 32;

const GID = {
  grassA: 1,
  grassB: 2,
  lawn: 3,
  stone: 4,
  pathH: 9,
  pathV: 10,
  roadH: 11,
  roadV: 12,
  roadCross: 13,
  waterA: 16,
  waterB: 17,
  bankN: 18,
  bankS: 19,
  bankW: 20,
  bankE: 21,
  bridgeH: 25,
  bridgeV: 26,
  track: 27,
  court: 28,
  dirt: 29,
  flowers: 30,
  reeds: 31,
  lawnStripe: 32
};

const environmentFrameBounds = {
  0: { x: 16, y: 353, width: 480, height: 159 },
  1: { x: 16, y: 197, width: 480, height: 315 },
  2: { x: 16, y: 266, width: 480, height: 246 },
  3: { x: 16, y: 342, width: 480, height: 170 },
  6: { x: 16, y: 180, width: 480, height: 332 },
  7: { x: 16, y: 331, width: 480, height: 181 },
  10: { x: 79, y: 270, width: 354, height: 242 },
  11: { x: 16, y: 367, width: 480, height: 145 },
  14: { x: 16, y: 357, width: 480, height: 155 },
  15: { x: 16, y: 236, width: 480, height: 276 },
  16: { x: 25, y: 32, width: 461, height: 480 },
  17: { x: 16, y: 39, width: 480, height: 473 },
  18: { x: 33, y: 32, width: 445, height: 480 },
  19: { x: 16, y: 43, width: 480, height: 469 }
};

const scaleClassRules = {
  landmark: { min: 320, max: 490 },
  campus_block: { min: 230, max: 270 },
  service_building: { min: 155, max: 190 },
  athletics_site: { min: 390, max: 430 },
  utility_structure: { min: 90, max: 150 }
};

// Reusable structures own one visible-world scale. Atlas display size is
// derived later from measured alpha bounds, so repeated instances cannot drift.
const environmentModels = {
  dorm_cluster: { frame: 1, projection: "front", scaleClass: "campus_block", visualWidth: 260, placementWidth: 260, placementHeight: 188.953, collisionWidth: 220, collisionHeight: 145 },
  dorm_cluster_side: { frame: 16, projection: "side", scaleClass: "campus_block", visualWidth: 230, placementWidth: 188.953, placementHeight: 230, collisionWidth: 145, collisionHeight: 200 },
  teaching_courtyard: { frame: 0, projection: "front", scaleClass: "campus_block", visualWidth: 240, placementWidth: 240, placementHeight: 179.478, collisionWidth: 205, collisionHeight: 90 },
  teaching_courtyard_side: { frame: 17, projection: "side", scaleClass: "campus_block", visualWidth: 230, placementWidth: 179.478, placementHeight: 240, collisionWidth: 90, collisionHeight: 205 },
  research_cluster: { frame: 2, projection: "front", scaleClass: "campus_block", visualWidth: 245, placementWidth: 245, placementHeight: 180.377, collisionWidth: 205, collisionHeight: 92 },
  service_block: { frame: 3, projection: "front", scaleClass: "service_building", visualWidth: 175, placementWidth: 175, placementHeight: 104.5, collisionWidth: 158, collisionHeight: 72 },
  service_block_side: { frame: 18, projection: "side", scaleClass: "service_building", visualWidth: 155, placementWidth: 104.5, placementHeight: 175, collisionWidth: 72, collisionHeight: 158 },
  sports_courts: { frame: 10, projection: "top", scaleClass: "athletics_site", visualWidth: 410, placementWidth: 410, placementHeight: 410 * 271 / 362, collisionWidth: 0, collisionHeight: 0 },
  greenhouse_garden: { frame: 11, projection: "front", scaleClass: "utility_structure", visualWidth: 135, placementWidth: 135, placementHeight: 92.837, collisionWidth: 115, collisionHeight: 56 },
  greenhouse_garden_side: { frame: 19, projection: "side", scaleClass: "utility_structure", visualWidth: 120, placementWidth: 115, placementHeight: 135, collisionWidth: 68, collisionHeight: 115 },
  bike_shelter: { frame: 14, projection: "front", scaleClass: "utility_structure", visualWidth: 135, placementWidth: 135, placementHeight: 95.99, collisionWidth: 112, collisionHeight: 46 },
  campus_kiosk: { frame: 15, projection: "front", scaleClass: "utility_structure", visualWidth: 100, placementWidth: 100, placementHeight: 78.832, collisionWidth: 86, collisionHeight: 54 }
};

const bridgeSpecs = [
  { id: "north_bridge", x: 1185, y: 592, spanStartX: 970, spanEndX: 1400, corridorHalfWidth: 48, modelWidth: 430 },
  { id: "middle_bridge", x: 1185, y: 1104, spanStartX: 970, spanEndX: 1400, corridorHalfWidth: 48, modelWidth: 430 },
  { id: "south_bridge", x: 1185, y: 1360, spanStartX: 970, spanEndX: 1400, corridorHalfWidth: 48, modelWidth: 430 },
  { id: "east_pond_bridge", x: 2000, y: 1120, spanStartX: 1920, spanEndX: 2080, corridorHalfWidth: 28, modelWidth: 160, landingRadiusTiles: 0 }
];

const [northBridge, middleBridge, southBridge] = bridgeSpecs;

const index = (x, y) => y * width + x;
const makeLayer = (fill = 0) => Array.from({ length: width * height }, () => fill);
const ground = makeLayer();
const roads = makeLayer();
const water = makeLayer();
const decor = makeLayer();

for (let y = 0; y < height; y += 1) {
  for (let x = 0; x < width; x += 1) {
    ground[index(x, y)] = (x * 7 + y * 11) % 9 === 0 ? GID.grassB : GID.grassA;
  }
}

// Great Lawn and sports lawns are authored as real ground cells, not overlays.
for (let y = 35; y <= 44; y += 1) {
  for (let x = 44; x <= 56; x += 1) {
    ground[index(x, y)] = (x + y) % 3 === 0 ? GID.lawnStripe : GID.lawn;
  }
}
for (let y = 5; y <= 15; y += 1) {
  for (let x = 58; x <= 70; x += 1) {
    ground[index(x, y)] = GID.lawn;
  }
}

const roadPathSpecs = [
  ["north_perimeter", "road", [[50, 70], [2380, 70]]],
  ["west_perimeter", "road", [[50, 70], [50, 1550]]],
  ["east_perimeter", "road", [[2380, 70], [2380, 1550]]],
  ["south_perimeter", "road", [[50, 1550], [2380, 1550]]],
  ["west_north_link", "road", [[50, 500], [1050, 500]]],
  ["west_mid_link", "road", [[50, 1000], [1050, 1000]]],
  ["east_north_link", "road", [[1350, 500], [2380, 500]]],
  ["east_mid_link", "road", [[1350, 1120], [2380, 1120]]],
  ["east_south_link", "road", [[1350, 1470], [2380, 1470]]],
  ["south_gate_approach", "road", [[700, 1500], [700, 1550]]],
  ["qizhen_west_bank", "path", [[1020, 100], [1010, 300], [980, 480], [northBridge.spanStartX, northBridge.y], [940, 780], [980, 960], [middleBridge.spanStartX, middleBridge.y], [950, 1240], [southBridge.spanStartX, southBridge.y], [930, 1500]]],
  ["qizhen_east_bank", "path", [[1320, 100], [1330, 300], [1370, 480], [northBridge.spanEndX, northBridge.y], [1420, 780], [1380, 960], [middleBridge.spanEndX, middleBridge.y], [1430, 1240], [southBridge.spanEndX, southBridge.y], [1480, 1500]]],
  ["north_bridge_link", "path", [[northBridge.spanStartX, northBridge.y], [northBridge.x, northBridge.y], [northBridge.spanEndX, northBridge.y]]],
  ["middle_bridge_link", "path", [[middleBridge.spanStartX, middleBridge.y], [middleBridge.x, middleBridge.y], [middleBridge.spanEndX, middleBridge.y]]],
  ["south_bridge_link", "path", [[southBridge.spanStartX, southBridge.y], [southBridge.x, southBridge.y], [southBridge.spanEndX, southBridge.y]]],
  ["main_library_walk", "path", [[620, 400], [650, 450], [580, 500]]],
  ["crescent_walk", "path", [[860, 500], [860, 455]]],
  ["auditorium_walk", "path", [[850, 820], [900, 900], [900, 1000]]],
  ["management_walk", "path", [[1580, 500], [1580, 455]]],
  ["foundation_walk", "path", [[1630, 1120], [1630, 980]]],
  ["stadium_walk", "path", [[2050, 500], [2050, 455]]]
];

const roadPathObjects = roadPathSpecs.map(([name, kind, points], pathIndex) => {
  const [originX, originY] = points[0];
  return {
    id: 400 + pathIndex,
    name,
    type: "road_path",
    x: originX,
    y: originY,
    rotation: 0,
    visible: true,
    polyline: points.map(([pointX, pointY]) => ({ x: pointX - originX, y: pointY - originY })),
    properties: [{ name: "kind", type: "string", value: kind }]
  };
});

// Qizhen Lake: a longitudinal water system with west/east branches and a southern pond.
const waterCells = new Set();
const addWater = (x, y) => {
  if (x > 0 && y > 0 && x < width - 1 && y < height - 1) waterCells.add(`${x},${y}`);
};
for (let y = 4; y <= 45; y += 1) {
  const center = 37 + Math.round(Math.sin(y / 4) * 2);
  const radius = y >= 20 && y <= 33 ? 5 : 3;
  for (let x = center - radius; x <= center + radius; x += 1) addWater(x, y);
}
for (let y = 22; y <= 30; y += 1) {
  const westEdge = 37 - Math.round((y - 22) * 1.35);
  for (let x = westEdge; x <= 38; x += 1) addWater(x, y);
}
for (let y = 23; y <= 30; y += 1) {
  const eastEdge = Math.min(45, 39 + Math.round((y - 23) * 1.75));
  for (let x = 38; x <= eastEdge; x += 1) addWater(x, y);
}
for (let y = 28; y <= 43; y += 1) {
  const center = 63 + Math.round(Math.sin(y / 3));
  const radius = y > 35 ? 3 : 1;
  for (let x = center - radius; x <= center + radius; x += 1) addWater(x, y);
}

// Lake-heart island removes water visually. Bridge water stays visible and is
// removed only from the collision model so the river continues under the deck.
for (let y = 30; y <= 33; y += 1) {
  for (let x = 35; x <= 38; x += 1) waterCells.delete(`${x},${y}`);
}

const waterCollisionCells = new Set(waterCells);
for (const key of waterCollisionCells) {
  const [cellX, cellY] = key.split(",").map(Number);
  const centerX = cellX * tile + tile / 2;
  const centerY = cellY * tile + tile / 2;
  const isBridgeDeck = bridgeSpecs.some((bridge) => (
    centerX >= bridge.spanStartX
    && centerX <= bridge.spanEndX
    && Math.abs(centerY - bridge.y) <= bridge.corridorHalfWidth
  ));
  if (isBridgeDeck) waterCollisionCells.delete(key);
}

for (const key of waterCells) {
  const [x, y] = key.split(",").map(Number);
  const north = waterCells.has(`${x},${y - 1}`);
  const south = waterCells.has(`${x},${y + 1}`);
  const west = waterCells.has(`${x - 1},${y}`);
  const east = waterCells.has(`${x + 1},${y}`);
  let gid = (x + y) % 2 === 0 ? GID.waterA : GID.waterB;
  if (!north) gid = GID.bankN;
  else if (!south) gid = GID.bankS;
  else if (!west) gid = GID.bankW;
  else if (!east) gid = GID.bankE;
  water[index(x, y)] = gid;
}

// Great Lawn paths, sports markings and planting beds.
for (let x = 45; x <= 55; x += 1) {
  decor[index(x, 37)] = GID.pathH;
  decor[index(x, 43)] = GID.pathH;
}
for (let y = 35; y <= 44; y += 1) decor[index(50, y)] = GID.pathV;
for (let x = 4; x <= 8; x += 1) decor[index(x, 24)] = GID.flowers;
for (let y = 25; y <= 29; y += 1) decor[index(9, y)] = GID.reeds;

// Stone landings use the same bridge spans as the visual and collision model.
for (const bridge of bridgeSpecs) {
  const landingRadius = bridge.landingRadiusTiles ?? 1;
  for (const endpointX of [bridge.spanStartX, bridge.spanEndX]) {
    const centerTileX = Math.floor(endpointX / tile);
    const centerTileY = Math.floor(bridge.y / tile);
    for (let y = centerTileY - landingRadius; y <= centerTileY + landingRadius; y += 1) {
      for (let x = centerTileX - landingRadius; x <= centerTileX + landingRadius; x += 1) {
        if (x >= 0 && y >= 0 && x < width && y < height && !waterCells.has(`${x},${y}`)) {
          decor[index(x, y)] = GID.stone;
        }
      }
    }
  }
}

const waterCollisionObjects = [];
let nextObjectId = 100;
for (let y = 0; y < height; y += 1) {
  let runStart = null;
  for (let x = 0; x <= width; x += 1) {
    const blocked = x < width && waterCollisionCells.has(`${x},${y}`);
    if (blocked && runStart === null) runStart = x;
    if (!blocked && runStart !== null) {
      waterCollisionObjects.push({
        id: nextObjectId++,
        name: "water",
        type: "collision",
        x: runStart * tile,
        y: y * tile,
        width: (x - runStart) * tile,
        height: tile,
        rotation: 0,
        visible: true
      });
      runStart = null;
    }
  }
}

const landmarkSpecs = [
  { id: 1, name: "main_library", x: 420, y: 250, displayWidth: 405, baseWidth: 405, centerOffsetX: 0, groundOffsetY: 145, renderAspect: 627 / 1429, placementHeight: 405 * 816 / 1212 },
  { id: 2, name: "crescent_building", x: 860, y: 280, displayWidth: 430, baseWidth: 430, centerOffsetX: 0, groundOffsetY: 155, renderAspect: 640 / 1454, placementHeight: 430 * 823 / 1221 },
  { id: 3, name: "qiushi_auditorium", x: 650, y: 700, displayWidth: 330, baseWidth: 330, centerOffsetX: 12, groundOffsetY: 112, renderAspect: 632 / 1367, placementHeight: 330 * 833 / 1169 },
  { id: 4, name: "management_school", x: 1580, y: 260, displayWidth: 370, baseWidth: 370, centerOffsetX: 0, groundOffsetY: 188, renderAspect: 765 / 1336, placementHeight: 370 * 868 / 1039 },
  {
    id: 5,
    name: "foundation_library",
    x: 1630,
    y: 770,
    displayWidth: 340,
    baseWidth: 390,
    centerOffsetX: 20,
    groundOffsetY: 222,
    renderAspect: 827 / 1052,
    placementHeight: 340 * 827 / 889,
    placementPolygon: [
      [-147, -160], [-37, -160], [-37, -21], [205, -21],
      [205, 24], [238, 24], [238, 156], [202.5, 156],
      [202.5, 185], [-42.5, 185], [-42.5, 90], [-147, 90]
    ],
    collisionRectangles: [
      { x: 55, y: 34, width: 300, height: 110 },
      { x: 80, y: 137, width: 245, height: 96 },
      { x: 188, y: 90, width: 100, height: 132 },
      { x: -92, y: -35, width: 110, height: 250 }
    ]
  },
  { id: 6, name: "zijingang_stadium", x: 2050, y: 300, displayWidth: 430, baseWidth: 430, centerOffsetX: 0, groundOffsetY: 145, renderAspect: 346 / 1447, placementHeight: 430 * 655 / 1170 },
  { id: 7, name: "south_gate", x: 700, y: 1390, displayWidth: 480, baseWidth: 480, centerOffsetX: 28, groundOffsetY: 100, renderAspect: 251 / 1660, placementHeight: 480 * 251 / 1660 }
];

const landmarks = landmarkSpecs.map((spec) => {
  const scale = spec.displayWidth / spec.baseWidth;
  return {
    id: spec.id,
    name: spec.name,
    type: "landmark",
    x: spec.x,
    y: spec.y,
    point: true,
    rotation: 0,
    visible: true,
    properties: [
      { name: "displayWidth", type: "int", value: spec.displayWidth },
      { name: "visualWidth", type: "int", value: spec.displayWidth },
      { name: "scaleClass", type: "string", value: "landmark" },
      { name: "projection", type: "string", value: "front" },
      { name: "renderAspect", type: "float", value: spec.renderAspect },
      { name: "placementOffsetX", type: "float", value: spec.centerOffsetX * scale },
      { name: "placementBottomOffsetY", type: "float", value: spec.groundOffsetY * scale },
      { name: "placementWidth", type: "float", value: spec.displayWidth },
      { name: "placementHeight", type: "float", value: spec.placementHeight },
      { name: "placementShape", type: "string", value: spec.placementPolygon ? "polygon" : "rectangle" }
    ]
  };
});

const structureFootprintObjects = landmarkSpecs.flatMap((spec, footprintIndex) => {
  if (!spec.placementPolygon) return [];
  const scale = spec.displayWidth / spec.baseWidth;
  return [{
    id: 600 + footprintIndex,
    name: `${spec.name}_footprint`,
    type: "structure_footprint",
    x: spec.x,
    y: spec.y,
    rotation: 0,
    visible: true,
    polygon: spec.placementPolygon.map(([pointX, pointY]) => ({ x: pointX * scale, y: pointY * scale })),
    properties: [
      { name: "owner", type: "string", value: spec.name },
      { name: "scaleClass", type: "string", value: "landmark" }
    ]
  }];
});

const structureCollisionObjects = landmarkSpecs.flatMap((spec, landmarkIndex) => {
  if (!spec.collisionRectangles) return [];
  const scale = spec.displayWidth / spec.baseWidth;
  return spec.collisionRectangles.map((rectangle, rectangleIndex) => ({
    id: 650 + landmarkIndex * 10 + rectangleIndex,
    name: `${spec.name}_collision_${rectangleIndex + 1}`,
    type: "structure_collision",
    x: spec.x + (rectangle.x - rectangle.width / 2) * scale,
    y: spec.y + (rectangle.y - rectangle.height / 2) * scale,
    width: rectangle.width * scale,
    height: rectangle.height * scale,
    rotation: 0,
    visible: true,
    properties: [{ name: "owner", type: "string", value: spec.name }]
  }));
});

const vegetationSpecs = [
  // North campus canopy: placed behind the landmark baselines.
  { name: "avenue_tree_row", frame: 20, x: 250, y: 165, displayWidth: 330 },
  { name: "avenue_tree_row", frame: 20, x: 760, y: 165, displayWidth: 330 },
  { name: "avenue_tree_row", frame: 20, x: 1510, y: 165, displayWidth: 340 },
  { name: "avenue_tree_row", frame: 20, x: 2090, y: 165, displayWidth: 340 },

  // West teaching and residential courts.
  { name: "tree_grove", frame: 4, x: 125, y: 430, displayWidth: 245 },
  { name: "tree_grove", frame: 4, x: 500, y: 560, displayWidth: 250 },
  { name: "avenue_tree_row", frame: 20, x: 710, y: 575, displayWidth: 280 },
  { name: "avenue_tree_row", frame: 20, x: 320, y: 820, displayWidth: 255 },
  { name: "tree_grove", frame: 4, x: 780, y: 805, displayWidth: 220 },
  { name: "tree_grove", frame: 4, x: 120, y: 1180, displayWidth: 255 },
  { name: "avenue_tree_row", frame: 20, x: 490, y: 1170, displayWidth: 300 },
  { name: "tree_grove", frame: 4, x: 890, y: 1320, displayWidth: 205 },

  // East campus courts and the Great Lawn edge.
  { name: "tree_grove", frame: 4, x: 1435, y: 455, displayWidth: 215 },
  { name: "avenue_tree_row", frame: 20, x: 1670, y: 585, displayWidth: 290 },
  { name: "avenue_tree_row", frame: 20, x: 2090, y: 600, displayWidth: 310 },
  { name: "tree_grove", frame: 4, x: 2310, y: 675, displayWidth: 200 },
  { name: "tree_grove", frame: 4, x: 1510, y: 930, displayWidth: 205 },
  { name: "avenue_tree_row", frame: 20, x: 1970, y: 930, displayWidth: 280 },
  { name: "avenue_tree_row", frame: 20, x: 1770, y: 1240, displayWidth: 320 },
  { name: "tree_grove", frame: 4, x: 2180, y: 1450, displayWidth: 210 },

  // Qizhen Lake bank planting, kept clear of the three bridge decks.
  { name: "willow_bank", frame: 5, x: 925, y: 380, displayWidth: 150 },
  { name: "willow_bank", frame: 5, x: 1470, y: 390, displayWidth: 150 },
  { name: "willow_bank", frame: 5, x: 920, y: 785, displayWidth: 160 },
  { name: "willow_bank", frame: 5, x: 1480, y: 790, displayWidth: 155 },
  { name: "willow_bank", frame: 5, x: 920, y: 1230, displayWidth: 155 },
  { name: "willow_bank", frame: 5, x: 1500, y: 1235, displayWidth: 155 }
];

const environmentSpecs = [
  { name: "dorm_cluster", x: 215, y: 720 },
  { name: "dorm_cluster_side", x: 2260, y: 1095 },
  { name: "teaching_courtyard_side", x: 350, y: 970 },
  { name: "research_cluster", x: 650, y: 1350 },
  { name: "service_block", x: 800, y: 940 },
  { name: "service_block_side", x: 850, y: 1200 },
  ...vegetationSpecs,
  {
    name: "lake_heart_island",
    frame: 6,
    x: 1190,
    y: 1040,
    visualWidth: 270,
    collisionWidth: 180,
    collisionHeight: 100,
    extraProperties: [{ name: "projection", type: "string", value: "front" }]
  },
  {
    name: "nanhuayuan",
    frame: 7,
    x: 370,
    y: 1330,
    visualWidth: 280,
    collisionWidth: 185,
    collisionHeight: 90,
    extraProperties: [{ name: "projection", type: "string", value: "front" }]
  },
  { name: "great_lawn", frame: 8, x: 1600, y: 1430, displayWidth: 560 },
  { name: "ceremonial_plaza", frame: 9, x: 1460, y: 1100, displayWidth: 300 },
  { name: "sports_courts", x: 2040, y: 855 },
  { name: "greenhouse_garden_side", x: 2240, y: 1280 },
  ...bridgeSpecs.map((bridge) => ({
    name: "qizhen_bridge",
    frame: 13,
    x: bridge.x,
    y: bridge.y,
    displayWidth: bridge.modelWidth,
    extraProperties: [
      { name: "bridgeId", type: "string", value: bridge.id },
      { name: "spanStartX", type: "int", value: bridge.spanStartX },
      { name: "spanEndX", type: "int", value: bridge.spanEndX },
      { name: "corridorHalfWidth", type: "int", value: bridge.corridorHalfWidth }
    ]
  })),
  { name: "bike_shelter", x: 1770, y: 1080 },
  { name: "campus_kiosk", x: 2250, y: 1380 }
];

function environmentPlacementProperties(model, bounds) {
  if (!model || !bounds) return [];
  const { placementHeight, placementWidth, projection, scaleClass, visualWidth } = model;
  return [
    { name: "scaleClass", type: "string", value: scaleClass },
    { name: "visualWidth", type: "float", value: visualWidth },
    { name: "projection", type: "string", value: projection },
    {
      name: "placementOffsetX",
      type: "float",
      value: ((bounds.x + bounds.width / 2) - 256) / bounds.width * visualWidth
    },
    { name: "placementBottomOffsetY", type: "float", value: 0 },
    { name: "placementWidth", type: "float", value: placementWidth },
    { name: "placementHeight", type: "float", value: placementHeight }
  ];
}

const environmentObjects = environmentSpecs.map((spec, indexValue) => {
  const model = environmentModels[spec.name];
  const frame = model?.frame ?? spec.frame;
  const bounds = environmentFrameBounds[frame];
  const visualWidth = model?.visualWidth ?? spec.visualWidth;
  const displayWidth = visualWidth && bounds
    ? visualWidth * 512 / bounds.width
    : spec.displayWidth;
  const collisionWidth = model?.collisionWidth ?? spec.collisionWidth ?? 0;
  const collisionHeight = model?.collisionHeight ?? spec.collisionHeight ?? 0;
  return {
    id: 20 + indexValue,
    name: spec.name,
    type: "environment",
    x: spec.x,
    y: spec.y,
    point: true,
    rotation: 0,
    visible: true,
    properties: [
      { name: "frame", type: "int", value: frame },
      { name: "displayWidth", type: "float", value: displayWidth },
      ...(spec.visualWidth ? [{ name: "visualWidth", type: "float", value: spec.visualWidth }] : []),
      { name: "collisionWidth", type: "float", value: collisionWidth },
      { name: "collisionHeight", type: "float", value: collisionHeight },
      ...environmentPlacementProperties(model, bounds),
      ...(spec.extraProperties ?? [])
    ]
  };
});

function objectProperty(object, propertyName) {
  return object.properties?.find((property) => property.name === propertyName)?.value;
}

function validateScaleContract(objects) {
  const reusableModels = new Map();
  for (const object of objects) {
    const scaleClass = objectProperty(object, "scaleClass");
    if (!scaleClass) continue;
    const visualWidth = Number(objectProperty(object, "visualWidth"));
    const placementWidth = Number(objectProperty(object, "placementWidth"));
    const projection = objectProperty(object, "projection");
    const rule = scaleClassRules[scaleClass];
    if (!rule || !Number.isFinite(visualWidth) || visualWidth < rule.min || visualWidth > rule.max) {
      throw new Error(`Invalid visual scale: ${object.name} (${scaleClass}) at ${visualWidth}`);
    }
    if (!Number.isFinite(placementWidth) || placementWidth <= 0) {
      throw new Error(`Invalid placement width: ${object.name}`);
    }
    if (projection === "front" && Math.abs(placementWidth - visualWidth) > 0.001) {
      throw new Error(`Visible width and placement width diverge: ${object.name}`);
    }
    if (object.type !== "environment") continue;
    const signature = [
      visualWidth,
      Number(objectProperty(object, "displayWidth")),
      placementWidth,
      Number(objectProperty(object, "placementHeight")),
      projection,
      Number(objectProperty(object, "collisionWidth")),
      Number(objectProperty(object, "collisionHeight"))
    ].join(":");
    const existing = reusableModels.get(object.name);
    if (existing && existing !== signature) {
      throw new Error(`Reusable environment scale drift: ${object.name}`);
    }
    reusableModels.set(object.name, signature);
  }
}

function placementRectangle(object) {
  const placementWidth = Number(objectProperty(object, "placementWidth"));
  const placementHeight = Number(objectProperty(object, "placementHeight"));
  if (!placementWidth || !placementHeight) return null;
  const centerX = object.x + Number(objectProperty(object, "placementOffsetX") ?? 0);
  const bottomY = object.y + Number(objectProperty(object, "placementBottomOffsetY") ?? 0);
  return {
    id: object.name,
    left: centerX - placementWidth / 2,
    right: centerX + placementWidth / 2,
    top: bottomY - placementHeight,
    bottom: bottomY
  };
}

function rectanglesOverlap(first, second, clearance = 0) {
  return first.left < second.right + clearance
    && first.right > second.left - clearance
    && first.top < second.bottom + clearance
    && first.bottom > second.top - clearance;
}

function validateRoadClearance(objects) {
  const roadHalfWidth = 17;
  const structureClearance = 4;
  const accessExemptions = new Set(["south_gate:south_gate_approach"]);
  const placements = objects
    .map((object) => ({ object, rectangle: placementRectangle(object) }))
    .filter((entry) => entry.rectangle);

  for (const { object, rectangle } of placements) {
    for (const road of roadPathObjects) {
      if (objectProperty(road, "kind") !== "road") continue;
      if (accessExemptions.has(`${object.name}:${road.name}`)) continue;
      const points = road.polyline.map((point) => ({ x: road.x + point.x, y: road.y + point.y }));
      for (let pointIndex = 1; pointIndex < points.length; pointIndex += 1) {
        const start = points[pointIndex - 1];
        const end = points[pointIndex];
        const roadRectangle = {
          left: Math.min(start.x, end.x) - roadHalfWidth,
          right: Math.max(start.x, end.x) + roadHalfWidth,
          top: Math.min(start.y, end.y) - roadHalfWidth,
          bottom: Math.max(start.y, end.y) + roadHalfWidth
        };
        if (rectanglesOverlap(rectangle, roadRectangle, structureClearance)) {
          throw new Error(`Structure overlaps vehicle road: ${object.name} and ${road.name}`);
        }
      }
    }
  }
}

function absolutePlacementPolygon(object, rectangle) {
  const footprint = structureFootprintObjects.find(
    (candidate) => objectProperty(candidate, "owner") === object.name
  );
  if (footprint) {
    return footprint.polygon.map((point) => ({ x: footprint.x + point.x, y: footprint.y + point.y }));
  }
  return [
    { x: rectangle.left, y: rectangle.top },
    { x: rectangle.right, y: rectangle.top },
    { x: rectangle.right, y: rectangle.bottom },
    { x: rectangle.left, y: rectangle.bottom }
  ];
}

function pointInPolygon(point, polygon) {
  let inside = false;
  for (let current = 0, previous = polygon.length - 1; current < polygon.length; previous = current, current += 1) {
    const currentPoint = polygon[current];
    const previousPoint = polygon[previous];
    const crosses = (currentPoint.y > point.y) !== (previousPoint.y > point.y)
      && point.x < (previousPoint.x - currentPoint.x) * (point.y - currentPoint.y)
        / (previousPoint.y - currentPoint.y) + currentPoint.x;
    if (crosses) inside = !inside;
  }
  return inside;
}

function orientation(first, second, third) {
  return (second.x - first.x) * (third.y - first.y) - (second.y - first.y) * (third.x - first.x);
}

function segmentsIntersect(firstStart, firstEnd, secondStart, secondEnd) {
  const firstSideA = orientation(firstStart, firstEnd, secondStart);
  const firstSideB = orientation(firstStart, firstEnd, secondEnd);
  const secondSideA = orientation(secondStart, secondEnd, firstStart);
  const secondSideB = orientation(secondStart, secondEnd, firstEnd);
  return ((firstSideA > 0 && firstSideB < 0) || (firstSideA < 0 && firstSideB > 0))
    && ((secondSideA > 0 && secondSideB < 0) || (secondSideA < 0 && secondSideB > 0));
}

function polygonsIntersect(first, second) {
  for (let firstIndex = 0; firstIndex < first.length; firstIndex += 1) {
    const firstStart = first[firstIndex];
    const firstEnd = first[(firstIndex + 1) % first.length];
    for (let secondIndex = 0; secondIndex < second.length; secondIndex += 1) {
      const secondStart = second[secondIndex];
      const secondEnd = second[(secondIndex + 1) % second.length];
      if (segmentsIntersect(firstStart, firstEnd, secondStart, secondEnd)) return true;
    }
  }
  return pointInPolygon(first[0], second) || pointInPolygon(second[0], first);
}

function validateStructurePlacements(objects) {
  const placements = objects
    .map((object) => {
      const rectangle = placementRectangle(object);
      return rectangle ? {
        ...rectangle,
        polygon: absolutePlacementPolygon(object, rectangle),
        isPolygon: objectProperty(object, "placementShape") === "polygon"
      } : null;
    })
    .filter(Boolean);

  for (const placement of placements) {
    for (const key of waterCells) {
      const [cellX, cellY] = key.split(",").map(Number);
      const waterRectangle = {
        left: cellX * tile,
        right: (cellX + 1) * tile,
        top: cellY * tile,
        bottom: (cellY + 1) * tile
      };
      const waterPolygon = [
        { x: waterRectangle.left, y: waterRectangle.top },
        { x: waterRectangle.right, y: waterRectangle.top },
        { x: waterRectangle.right, y: waterRectangle.bottom },
        { x: waterRectangle.left, y: waterRectangle.bottom }
      ];
      if (rectanglesOverlap(placement, waterRectangle) && polygonsIntersect(placement.polygon, waterPolygon)) {
        throw new Error(`Structure overlaps water: ${placement.id} at ${placement.left},${placement.top}`);
      }
    }
  }

  for (let firstIndex = 0; firstIndex < placements.length; firstIndex += 1) {
    for (let secondIndex = firstIndex + 1; secondIndex < placements.length; secondIndex += 1) {
      const first = placements[firstIndex];
      const second = placements[secondIndex];
      const broadPhaseOverlap = rectanglesOverlap(first, second, 4);
      const exactOverlap = !first.isPolygon && !second.isPolygon
        ? broadPhaseOverlap
        : polygonsIntersect(first.polygon, second.polygon);
      if (broadPhaseOverlap && exactOverlap) {
        throw new Error(`Structures overlap: ${first.id} and ${second.id}`);
      }
    }
  }
}

const structuralObjects = [...landmarks, ...environmentObjects];
validateScaleContract(structuralObjects);
validateStructurePlacements(structuralObjects);
validateRoadClearance(structuralObjects);

const layers = [
  { id: 1, name: "Ground", type: "tilelayer", x: 0, y: 0, width, height, opacity: 1, visible: true, data: ground },
  { id: 2, name: "Roads", type: "tilelayer", x: 0, y: 0, width, height, opacity: 1, visible: true, data: roads },
  { id: 3, name: "Water", type: "tilelayer", x: 0, y: 0, width, height, opacity: 1, visible: true, data: water },
  { id: 4, name: "Decor", type: "tilelayer", x: 0, y: 0, width, height, opacity: 1, visible: true, data: decor },
  { id: 5, name: "RoadPaths", type: "objectgroup", draworder: "topdown", opacity: 1, visible: true, objects: roadPathObjects },
  { id: 6, name: "Landmarks", type: "objectgroup", draworder: "topdown", opacity: 1, visible: true, objects: landmarks },
  { id: 7, name: "Environment", type: "objectgroup", draworder: "topdown", opacity: 1, visible: true, objects: environmentObjects },
  { id: 8, name: "WaterCollisions", type: "objectgroup", draworder: "topdown", opacity: 1, visible: true, objects: waterCollisionObjects },
  { id: 9, name: "StructureFootprints", type: "objectgroup", draworder: "topdown", opacity: 1, visible: true, objects: structureFootprintObjects },
  { id: 10, name: "StructureCollisions", type: "objectgroup", draworder: "topdown", opacity: 1, visible: true, objects: structureCollisionObjects }
];

const map = {
  compressionlevel: -1,
  height,
  width,
  infinite: false,
  layers,
  nextlayerid: 11,
  nextobjectid: Math.max(nextObjectId, 700),
  orientation: "orthogonal",
  renderorder: "right-down",
  tiledversion: "1.12.2",
  tileheight: tile,
  tilewidth: tile,
  type: "map",
  version: "1.10",
  tilesets: [{
    firstgid: 1,
    columns: 8,
    image: "zijingang_terrain.png",
    imageheight: 128,
    imagewidth: 256,
    margin: 0,
    name: "zijingang_terrain",
    spacing: 0,
    tilecount: 32,
    tileheight: tile,
    tilewidth: tile
  }]
};

mkdirSync(dirname(output), { recursive: true });
writeFileSync(output, `${JSON.stringify(map)}\n`);
process.stdout.write(`${output}\n`);
