import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";

const EXPECTED = {
  width: 13668,
  height: 1084,
  sha256: "c2f3c887bb6c1d5f58e09a89883a28bd0050d0ccc8b1c85e10b5236ec3a4136d",
  legacySha256: "c049150bf9b5408756b8baf479b9a7ef38cc98d9ebb3d829e2080d73b5d8c021",
  qizhenSha256: "21a83373372458b2c0f80886eb667b78c02986da10d3033d07bd6e88db3b89a8",
  insertion: { splitX: 8400, width: 1924 },
  spawn: { x: 800, y: 968 },
  foundationLibrary: { x: 10924, y: 690 },
  libraryGate: { x: 10924, y: 770, radius: 100 },
  libraryApproach: { x: 10994, y: 770 },
  canteen: {
    huntSpawn: { x: 12424, y: 1004 },
    gate: { x: 756, y: 756, radius: 88 },
    approach: { x: 756, y: 756 },
    bike: { x: 980, y: 973 }
  },
  theater: {
    gate: { x: 7730, y: 735, radius: 86 },
    approach: { x: 7730, y: 840 }
  },
  qizhen: {
    gate: { x: 9362, y: 900, radius: 110 },
    approach: { x: 9362, y: 930 },
    segment: { left: 8400, right: 10324, center: 9362 }
  },
  loop: {
    leftTriggerX: 120,
    rightTriggerX: 13548,
    leftArrival: { x: 360, y: 960 },
    rightArrival: { x: 13308, y: 960 }
  },
  perspective: {
    farY: 840,
    nearY: 1040,
    farMultiplier: 1,
    nearMultiplier: 1.5,
    baseMultiplier: 1.5
  }
};

const plateUrl = new URL("../src/assets/rpg/campus/zijingang_campus_loop_panorama.png", import.meta.url);
const legacyUrl = new URL("../src/assets/rpg/campus/source/panorama/zijingang_legacy_panorama.png", import.meta.url);
const qizhenUrl = new URL("../src/assets/rpg/interiors/qizhen_lake_reflection.png", import.meta.url);
const maskUrl = new URL("../src/assets/rpg/campus/zijingang_road_walkability_mask.png", import.meta.url);
const runtimeUrl = new URL("../src/data/maps/zijingang-campus-runtime.json", import.meta.url);
const [plate, legacy, qizhen, mask, runtimeText] = await Promise.all([
  readFile(plateUrl),
  readFile(legacyUrl),
  readFile(qizhenUrl),
  readFile(maskUrl),
  readFile(runtimeUrl, "utf8")
]);
const runtime = JSON.parse(runtimeText);

const pngSignature = "89504e470d0a1a0a";
for (const [name, bytes] of [["loop panorama", plate], ["legacy panorama", legacy], ["Qizhen plate", qizhen], ["walkability mask", mask]]) {
  if (bytes.subarray(0, 8).toString("hex") !== pngSignature) {
    throw new Error(`${name} is not a valid PNG file`);
  }
}
const sha256 = (bytes) => createHash("sha256").update(bytes).digest("hex");
const plateSha256 = sha256(plate);
if (plate.readUInt32BE(16) !== EXPECTED.width || plate.readUInt32BE(20) !== EXPECTED.height) {
  throw new Error(`Campus loop panorama must be ${EXPECTED.width}x${EXPECTED.height}`);
}
if (plateSha256 !== EXPECTED.sha256) {
  throw new Error(`Campus loop panorama SHA-256 mismatch: ${plateSha256}`);
}
if (sha256(legacy) !== EXPECTED.legacySha256 || sha256(qizhen) !== EXPECTED.qizhenSha256) {
  throw new Error("Campus loop source assets changed without rebuilding and reviewing the insertion");
}
if (runtime.world?.width !== EXPECTED.width || runtime.world?.height !== EXPECTED.height) {
  throw new Error("Campus runtime world dimensions do not match the loop panorama");
}
if (
  runtime.source?.plateSha256 !== plateSha256
  || runtime.source?.sourceSha256?.legacyPanorama !== EXPECTED.legacySha256
  || runtime.source?.sourceSha256?.qizhenReflection !== EXPECTED.qizhenSha256
) {
  throw new Error("Campus runtime source hashes do not match the reviewed images");
}
if (
  runtime.source?.insertion?.splitX !== EXPECTED.insertion.splitX
  || runtime.source?.insertion?.width !== EXPECTED.insertion.width
) {
  throw new Error("Qizhen insertion metadata changed");
}
for (const [name, actual, expected] of [
  ["spawn", runtime.spawn, EXPECTED.spawn],
  ["libraryGate", runtime.libraryGate, EXPECTED.libraryGate],
  ["canteen", runtime.canteen, EXPECTED.canteen],
  ["theater", runtime.theater, EXPECTED.theater],
  ["Qizhen gate", runtime.qizhen?.gate, EXPECTED.qizhen.gate],
  ["Qizhen approach", runtime.qizhen?.approach, EXPECTED.qizhen.approach],
  ["Qizhen segment", runtime.qizhen?.segment, EXPECTED.qizhen.segment],
  ["perspective", runtime.perspective, EXPECTED.perspective]
]) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(`${name} does not match the accepted loop coordinate contract`);
  }
}
const foundationLibrary = runtime.landmarks?.find((landmark) => landmark.id === "foundation_library");
if (JSON.stringify(foundationLibrary) !== JSON.stringify({ id: "foundation_library", ...EXPECTED.foundationLibrary })) {
  throw new Error("Foundation Library was not shifted with the post-Qizhen east panorama");
}

const walkability = runtime.walkability;
if (
  !walkability
  || walkability.cellSize !== 4
  || walkability.gridWidth * walkability.cellSize !== EXPECTED.width
  || walkability.gridHeight * walkability.cellSize !== EXPECTED.height
) {
  throw new Error("Campus walkability grid does not match the loop panorama");
}
const walkabilityBytes = Buffer.from(walkability.bitsBase64, "base64");
const expectedBytes = Math.ceil((walkability.gridWidth * walkability.gridHeight) / 8);
if (walkabilityBytes.length !== expectedBytes) {
  throw new Error(`Campus walkability bitset must contain ${expectedBytes} bytes`);
}
if (
  walkability.sourcePlateSha256 !== plateSha256
  || sha256(mask) !== walkability.maskSha256
  || mask.readUInt32BE(16) !== EXPECTED.width
  || mask.readUInt32BE(20) !== EXPECTED.height
) {
  throw new Error("Campus walkability mask is stale or has incorrect dimensions");
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
  if (!point || !playerFootSamples.every(([offsetX, offsetY]) => isWalkable(point.x + offsetX, point.y + offsetY))) {
    throw new Error(`${name} does not fit the canonical player foot box`);
  }
};

for (const [name, point] of [
  ["Campus spawn", runtime.spawn],
  ["Library approach", walkability.gateApproach],
  ["Canteen gate", runtime.canteen.gate],
  ["Canteen approach", runtime.canteen.approach],
  ["Canteen hunt spawn", runtime.canteen.huntSpawn],
  ["Canteen bicycle", runtime.canteen.bike],
  ["Theater gate", runtime.theater.gate],
  ["Theater approach", runtime.theater.approach],
  ["Qizhen gate", runtime.qizhen.gate],
  ["Qizhen approach", runtime.qizhen.approach],
  ["Loop left arrival", runtime.loop?.leftArrival],
  ["Loop right arrival", runtime.loop?.rightArrival],
  ["Qizhen cinematic stop", runtime.qizhen?.approachTransition?.stop]
]) {
  assertStandable(name, point);
}
runtime.qizhen.approachTransition.waypoints.forEach((point, index) => {
  assertStandable(`Qizhen cinematic waypoint ${index + 1}`, point);
});

if (
  runtime.loop?.enabled !== true
  || runtime.loop?.leftTriggerX !== EXPECTED.loop.leftTriggerX
  || runtime.loop?.rightTriggerX !== EXPECTED.loop.rightTriggerX
  || JSON.stringify(runtime.loop?.leftArrival) !== JSON.stringify(EXPECTED.loop.leftArrival)
  || JSON.stringify(runtime.loop?.rightArrival) !== JSON.stringify(EXPECTED.loop.rightArrival)
) {
  throw new Error("Campus bidirectional loop points changed");
}
if (walkability.promenadeSurfaceTop !== 864) {
  throw new Error("Campus foreground road must retain the source-pixel y=864 contract");
}
for (let x = 40; x < EXPECTED.width - 40; x += 160) {
  const overlapsProp = walkability.foregroundObstacles?.some((obstacle) => (
    x + 8.75 >= obstacle.left
    && x - 8.75 < obstacle.right
    && 842 + 38 >= obstacle.top
    && 842 + 25.375 < obstacle.bottom
  ));
  if (!overlapsProp) assertStandable(`Continuous road at x=${x}`, { x, y: 842 });
}
for (const x of [420, 2643, 5700, 7079, 8400, 9362, 10324, 11864, 12954, 13500]) {
  assertStandable(`Road seam at x=${x}`, { x, y: 940 });
}
for (const [name, point] of [
  ["Qizhen lake water", { x: 9362, y: 420 }],
  ["Qizhen foreground lawn", { x: 9362, y: 800 }],
  ["Foundation Library flower bed", { x: 10924, y: 840 }],
  ["Canteen billboard", { x: 200, y: 810 }],
  ["Canteen vending machine", { x: 400, y: 760 }],
  ["Canteen utility cabinet", { x: 1340, y: 800 }]
]) {
  if (isWalkable(point.x, point.y)) {
    throw new Error(`${name} must remain blocked`);
  }
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
    ) continue;
    const next = nextY * walkability.gridWidth + nextX;
    if (reachable[next] || !isWalkable(nextX * walkability.cellSize, nextY * walkability.cellSize)) continue;
    reachable[next] = 1;
    queue[tail++] = next;
  }
}
for (const [name, point] of [
  ["Library", walkability.gateApproach],
  ["Canteen", runtime.canteen.approach],
  ["Theater", runtime.theater.approach],
  ["Qizhen", runtime.qizhen.approach],
  ["Loop left arrival", runtime.loop.leftArrival],
  ["Loop right arrival", runtime.loop.rightArrival],
  ["Qizhen transition stop", runtime.qizhen.approachTransition.stop]
]) {
  if (!reachable[cellIndexAt(point)]) {
    throw new Error(`${name} must share the connected campus road component`);
  }
}

console.log(
  `verified campus loop ${EXPECTED.width}x${EXPECTED.height} sha256=${plateSha256} `
  + `walkable=${walkability.walkableCells} theater=${runtime.theater.gate.x},${runtime.theater.gate.y} `
  + `qizhen=${runtime.qizhen.gate.x},${runtime.qizhen.gate.y} wrap=${runtime.loop.leftTriggerX}<->${runtime.loop.rightTriggerX}`
);
