import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";

const EXPECTED = {
  width: 4516,
  height: 3420,
  sha256: "57e27997d0c24a77dd758869bcc1bab8665b10496a77ec0f802986461ceb116d",
  spawn: { x: 2550, y: 650 },
  foundationLibrary: { x: 3718, y: 1568 },
  libraryGate: { x: 3706, y: 1696, radius: 112 },
  libraryApproach: { x: 3805, y: 1680 },
  canteen: {
    huntSpawn: { x: 4200, y: 2868 },
    gate: { x: 3120, y: 620, radius: 88 },
    approach: { x: 3120, y: 650 },
    bike: { x: 3220, y: 650 }
  }
};

const plateUrl = new URL("../src/assets/rpg/campus/zijingang_campus_plate.png", import.meta.url);
const maskUrl = new URL("../src/assets/rpg/campus/zijingang_road_walkability_mask.png", import.meta.url);
const runtimeUrl = new URL("../src/data/maps/zijingang-campus-runtime.json", import.meta.url);
const plate = await readFile(plateUrl);
const mask = await readFile(maskUrl);
const runtime = JSON.parse(await readFile(runtimeUrl, "utf8"));

const pngSignature = "89504e470d0a1a0a";
if (plate.subarray(0, 8).toString("hex") !== pngSignature) {
  throw new Error("Campus panorama is not a valid PNG file");
}

const width = plate.readUInt32BE(16);
const height = plate.readUInt32BE(20);
const sha256 = createHash("sha256").update(plate).digest("hex");
if (width !== EXPECTED.width || height !== EXPECTED.height) {
  throw new Error(`Campus panorama must be ${EXPECTED.width}x${EXPECTED.height}; received ${width}x${height}`);
}
if (sha256 !== EXPECTED.sha256) {
  throw new Error(`Campus panorama SHA-256 mismatch: ${sha256}`);
}
if (runtime.world?.width !== width || runtime.world?.height !== height) {
  throw new Error("Campus runtime world dimensions do not match the panorama");
}
if (runtime.source?.plateSha256 !== sha256) {
  throw new Error("Campus runtime SHA-256 does not match the panorama");
}
if (runtime.spawn?.x !== EXPECTED.spawn.x || runtime.spawn?.y !== EXPECTED.spawn.y) {
  throw new Error("Campus spawn must stay on the road south of the Ziyun/Bifeng residential area");
}
for (const [name, point] of [["spawn", runtime.spawn], ["libraryGate", runtime.libraryGate]]) {
  if (!point || point.x < 0 || point.x > width || point.y < 0 || point.y > height) {
    throw new Error(`Campus runtime ${name} is outside the panorama`);
  }
}
if (
  runtime.libraryGate.x !== EXPECTED.libraryGate.x
  || runtime.libraryGate.y !== EXPECTED.libraryGate.y
  || runtime.libraryGate.radius !== EXPECTED.libraryGate.radius
) {
  throw new Error("Campus library gate is not calibrated to the visible foundation-library south entrance");
}
const foundationLibrary = runtime.landmarks?.find((landmark) => landmark.id === "foundation_library");
if (
  foundationLibrary?.x !== EXPECTED.foundationLibrary.x
  || foundationLibrary?.y !== EXPECTED.foundationLibrary.y
) {
  throw new Error("Foundation-library landmark is not anchored to the matching panorama building");
}
const walkability = runtime.walkability;
if (!walkability || walkability.cellSize <= 0) {
  throw new Error("Campus runtime walkability data is missing");
}
if (
  walkability.gridWidth * walkability.cellSize !== width ||
  walkability.gridHeight * walkability.cellSize !== height
) {
  throw new Error("Campus walkability grid does not match the panorama coordinate system");
}
const walkabilityBytes = Buffer.from(walkability.bitsBase64, "base64");
const expectedBytes = Math.ceil((walkability.gridWidth * walkability.gridHeight) / 8);
if (walkabilityBytes.length !== expectedBytes) {
  throw new Error(`Campus walkability bitset must contain ${expectedBytes} bytes; received ${walkabilityBytes.length}`);
}
if (walkability.sourcePlateSha256 !== sha256) {
  throw new Error("Campus walkability was not derived from the selected panorama");
}
const maskSha256 = createHash("sha256").update(mask).digest("hex");
if (maskSha256 !== walkability.maskSha256) {
  throw new Error(`Campus walkability mask SHA-256 mismatch: ${maskSha256}`);
}
if (
  mask.subarray(0, 8).toString("hex") !== pngSignature ||
  mask.readUInt32BE(16) !== width ||
  mask.readUInt32BE(20) !== height
) {
  throw new Error("Campus walkability mask dimensions do not match the panorama");
}

const isWalkable = (x, y) => {
  const gridX = Math.floor(x / walkability.cellSize);
  const gridY = Math.floor(y / walkability.cellSize);
  if (gridX < 0 || gridX >= walkability.gridWidth || gridY < 0 || gridY >= walkability.gridHeight) {
    return false;
  }
  const cellIndex = gridY * walkability.gridWidth + gridX;
  return ((walkabilityBytes[cellIndex >> 3] >> (cellIndex & 7)) & 1) === 1;
};
const playerFootSamples = [
  [-8.75, 25.375],
  [0, 25.375],
  [8.75, 25.375],
  [-8.75, 38],
  [0, 38],
  [8.75, 38]
];
const assertStandable = (name, point) => {
  if (!playerFootSamples.every(([offsetX, offsetY]) => isWalkable(point.x + offsetX, point.y + offsetY))) {
    throw new Error(`${name} does not fit the canonical player foot box on the walkability mask`);
  }
};
const gateApproach = walkability.gateApproach;
if (!gateApproach) {
  throw new Error("Campus walkability gate approach is missing");
}
if (
  gateApproach.x !== EXPECTED.libraryApproach.x
  || gateApproach.y !== EXPECTED.libraryApproach.y
) {
  throw new Error("Campus library approach is not calibrated to the Basic Library east forecourt");
}
assertStandable("Campus library gate approach", gateApproach);
assertStandable("Campus spawn", runtime.spawn);
assertStandable("East Canteen approach", runtime.canteen?.approach);
assertStandable("Canteen hunt spawn", runtime.canteen?.huntSpawn);
assertStandable("Canteen bicycle", runtime.canteen?.bike);
for (const [name, point] of [
  ["Basic Library building body", { x: 3706, y: 1600 }],
  ["Basic Library west river bank", { x: 3500, y: 1700 }],
  ["East Canteen building body", { x: 3120, y: 520 }],
  ["Ziyun/Bifeng building body", { x: 2572, y: 525 }]
]) {
  if (isWalkable(point.x, point.y)) {
    throw new Error(`${name} must remain blocked`);
  }
}
if (Math.hypot(gateApproach.x - runtime.libraryGate.x, gateApproach.y - runtime.libraryGate.y) > runtime.libraryGate.radius) {
  throw new Error("Campus library approach is outside the interaction radius");
}
if (JSON.stringify(runtime.canteen) !== JSON.stringify(EXPECTED.canteen)) {
  throw new Error("East Canteen story coordinates do not match the selected top-down plate");
}

const cellIndexAt = (point) => {
  const x = Math.floor(point.x / walkability.cellSize);
  const y = Math.floor(point.y / walkability.cellSize);
  return y * walkability.gridWidth + x;
};
const reachable = new Uint8Array(walkability.gridWidth * walkability.gridHeight);
const queue = new Int32Array(reachable.length);
let head = 0;
let tail = 0;
const start = cellIndexAt(runtime.spawn);
reachable[start] = 1;
queue[tail++] = start;
while (head < tail) {
  const current = queue[head++];
  const x = current % walkability.gridWidth;
  const y = Math.floor(current / walkability.gridWidth);
  for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
    const nextX = x + dx;
    const nextY = y + dy;
    if (
      nextX < 0
      || nextY < 0
      || nextX >= walkability.gridWidth
      || nextY >= walkability.gridHeight
    ) {
      continue;
    }
    const next = nextY * walkability.gridWidth + nextX;
    if (reachable[next] || !isWalkable(nextX * walkability.cellSize, nextY * walkability.cellSize)) {
      continue;
    }
    reachable[next] = 1;
    queue[tail++] = next;
  }
}
for (const [name, point] of [
  ["Basic Library", gateApproach],
  ["East Canteen", runtime.canteen.approach],
  ["night hunt spawn", runtime.canteen.huntSpawn]
]) {
  if (!reachable[cellIndexAt(point)]) {
    throw new Error(`${name} must be connected to the Ziyun/Bifeng campus spawn`);
  }
}

console.log(
  `verified repository top-down campus ${width}x${height} sha256=${sha256} walkable=${walkability.walkableCells} spawn=${runtime.spawn.x},${runtime.spawn.y} libraryGate=${runtime.libraryGate.x},${runtime.libraryGate.y} approach=${gateApproach.x},${gateApproach.y}`
);
