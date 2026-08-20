import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";

const EXPECTED = {
  width: 4516,
  height: 3420,
  plateSha256: "57e27997d0c24a77dd758869bcc1bab8665b10496a77ec0f802986461ceb116d",
  spawn: { x: 2550, y: 650 },
  foundationLibrary: { x: 3718, y: 1568 },
  libraryGate: { x: 3706, y: 1696, radius: 112 },
  libraryApproach: { x: 3805, y: 1680 },
  canteen: {
    huntSpawn: { x: 4200, y: 2868 },
    gate: { x: 3120, y: 620, radius: 88 },
    approach: { x: 3120, y: 650 },
    bike: { x: 3220, y: 650 }
  },
  theater: {
    gate: { x: 3300, y: 1445, radius: 105 },
    approach: { x: 3300, y: 1360 }
  }
};

const plateUrl = new URL("../src/assets/rpg/campus/zijingang_campus_plate.png", import.meta.url);
const maskUrl = new URL("../src/assets/rpg/campus/zijingang_road_walkability_mask.png", import.meta.url);
const runtimeUrl = new URL("../src/data/maps/zijingang-campus-runtime.json", import.meta.url);
const [plate, mask, runtimeText] = await Promise.all([
  readFile(plateUrl),
  readFile(maskUrl),
  readFile(runtimeUrl, "utf8")
]);
const runtime = JSON.parse(runtimeText);
const pngSignature = "89504e470d0a1a0a";
const sha256 = (bytes) => createHash("sha256").update(bytes).digest("hex");

for (const [name, bytes] of [["campus plate", plate], ["walkability mask", mask]]) {
  if (bytes.subarray(0, 8).toString("hex") !== pngSignature) {
    throw new Error(`${name} is not a valid PNG file`);
  }
}

const width = plate.readUInt32BE(16);
const height = plate.readUInt32BE(20);
const plateSha256 = sha256(plate);
if (width !== EXPECTED.width || height !== EXPECTED.height) {
  throw new Error(`IonicJian campus plate must remain ${EXPECTED.width}x${EXPECTED.height}`);
}
if (plateSha256 !== EXPECTED.plateSha256) {
  throw new Error(`IonicJian campus plate SHA-256 mismatch: ${plateSha256}`);
}
if (
  runtime.world?.width !== width
  || runtime.world?.height !== height
  || runtime.source?.plateSha256 !== plateSha256
) {
  throw new Error("Top-down campus runtime no longer matches the reviewed plate");
}

for (const [name, actual, expected] of [
  ["spawn", runtime.spawn, EXPECTED.spawn],
  ["library gate", runtime.libraryGate, EXPECTED.libraryGate],
  ["canteen", runtime.canteen, EXPECTED.canteen],
  ["theater", runtime.theater, EXPECTED.theater]
]) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(`${name} changed outside the accepted top-down coordinate contract`);
  }
}
const foundationLibrary = runtime.landmarks?.find((landmark) => landmark.id === "foundation_library");
if (JSON.stringify(foundationLibrary) !== JSON.stringify({ id: "foundation_library", ...EXPECTED.foundationLibrary })) {
  throw new Error("Foundation Library landmark is no longer anchored to the IonicJian plate");
}

const walkability = runtime.walkability;
if (
  !walkability
  || walkability.cellSize !== 4
  || walkability.gridWidth * walkability.cellSize !== width
  || walkability.gridHeight * walkability.cellSize !== height
  || JSON.stringify(walkability.gateApproach) !== JSON.stringify(EXPECTED.libraryApproach)
) {
  throw new Error("Top-down campus walkability dimensions or library approach changed");
}
const bits = Buffer.from(walkability.bitsBase64, "base64");
const expectedBytes = Math.ceil((walkability.gridWidth * walkability.gridHeight) / 8);
if (bits.length !== expectedBytes) {
  throw new Error(`Top-down walkability bitset must contain ${expectedBytes} bytes`);
}
if (
  walkability.sourcePlateSha256 !== plateSha256
  || sha256(mask) !== walkability.maskSha256
  || mask.readUInt32BE(16) !== width
  || mask.readUInt32BE(20) !== height
) {
  throw new Error("Top-down campus walkability mask is stale");
}

const isWalkable = (x, y) => {
  const gridX = Math.floor(x / walkability.cellSize);
  const gridY = Math.floor(y / walkability.cellSize);
  if (gridX < 0 || gridX >= walkability.gridWidth || gridY < 0 || gridY >= walkability.gridHeight) return false;
  const cellIndex = gridY * walkability.gridWidth + gridX;
  return ((bits[cellIndex >> 3] >> (cellIndex & 7)) & 1) === 1;
};
const playerFootSamples = [
  [-8.75, 25.375], [0, 25.375], [8.75, 25.375],
  [-8.75, 38], [0, 38], [8.75, 38]
];
const assertStandable = (name, point) => {
  if (!point || !playerFootSamples.every(([offsetX, offsetY]) => isWalkable(point.x + offsetX, point.y + offsetY))) {
    throw new Error(`${name} does not fit the canonical player foot box`);
  }
};
for (const [name, point] of [
  ["Campus spawn", runtime.spawn],
  ["Library approach", walkability.gateApproach],
  ["Canteen approach", runtime.canteen.approach],
  ["Canteen hunt spawn", runtime.canteen.huntSpawn],
  ["Canteen bicycle", runtime.canteen.bike],
  ["Theater approach", runtime.theater.approach]
]) {
  assertStandable(name, point);
}
for (const [name, point] of [
  ["Basic Library body", { x: 3706, y: 1600 }],
  ["Basic Library river bank", { x: 3500, y: 1700 }],
  ["East Canteen body", { x: 3120, y: 520 }],
  ["Ziyun/Bifeng building body", { x: 2572, y: 525 }]
]) {
  if (isWalkable(point.x, point.y)) throw new Error(`${name} must remain blocked`);
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
    if (nextX < 0 || nextY < 0 || nextX >= walkability.gridWidth || nextY >= walkability.gridHeight) continue;
    const next = nextY * walkability.gridWidth + nextX;
    if (reachable[next] || !isWalkable(nextX * walkability.cellSize, nextY * walkability.cellSize)) continue;
    reachable[next] = 1;
    queue[tail++] = next;
  }
}
for (const [name, point] of [
  ["Basic Library", walkability.gateApproach],
  ["East Canteen", runtime.canteen.approach],
  ["Canteen hunt spawn", runtime.canteen.huntSpawn],
  ["Theater", runtime.theater.approach]
]) {
  if (!reachable[cellIndexAt(point)]) {
    throw new Error(`${name} must remain connected to the campus spawn`);
  }
}

console.log(
  `verified IonicJian top-down campus ${width}x${height} sha256=${plateSha256} walkable=${walkability.walkableCells}`
);
