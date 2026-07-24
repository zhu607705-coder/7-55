import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";

const EXPECTED = {
  width: 11744,
  height: 1084,
  sha256: "c049150bf9b5408756b8baf479b9a7ef38cc98d9ebb3d829e2080d73b5d8c021",
  foundationLibrary: { x: 9000, y: 690 },
  libraryGate: { x: 9000, y: 770, radius: 100 }
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
  [-9.5, 24.5],
  [0, 24.5],
  [9.5, 24.5],
  [-9.5, 38.75],
  [0, 38.75],
  [9.5, 38.75]
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
assertStandable("Campus library gate approach", gateApproach);
assertStandable("Campus library checkpoint", {
  x: gateApproach.x,
  y: gateApproach.y
});
if (walkability.promenadeSurfaceTop !== 864) {
  throw new Error("Campus promenade surface must retain the source-pixel y=864 contract");
}
for (const x of [420, 1300, 2643, 3944, 5700, 7079, 8939, 10133, 11600]) {
  assertStandable(`Campus seam-crossing road at x=${x}`, { x, y: 940 });
}
for (let x = 40; x < width - 40; x += 160) {
  const overlapsForegroundObstacle = walkability.foregroundObstacles?.some((obstacle) => (
    x + 9.5 >= obstacle.left
    && x - 9.5 < obstacle.right
    && 842 + 38.75 >= obstacle.top
    && 842 + 24.5 < obstacle.bottom
  ));
  if (overlapsForegroundObstacle) continue;
  assertStandable(`Campus continuous sidewalk at x=${x}`, { x, y: 842 });
}
const expectedApproaches = [
  ["dining_hall", 745, 708],
  ["west_round_hall", 5595, 752],
  ["museum", 7675, 728]
];
if (walkability.entranceApproaches?.length !== expectedApproaches.length) {
  throw new Error("Campus runtime must retain all three rectangular source-pixel entrance approaches");
}
for (const [name, x, y] of expectedApproaches) {
  assertStandable(`Campus ${name} entrance approach`, { x, y });
}
const expectedPublicPaths = [
  ["museum_central_gate", 6200, 760],
  ["east_riverside_walk", 9970, 760],
  ["east_main_hall_walk", 11030, 760],
  ["foundation_library_entry", 9070, 770]
];
if (walkability.publicPathPolygons?.length !== expectedPublicPaths.length) {
  throw new Error("Campus runtime must retain all four measured public path polygons");
}
for (const [name, x, y] of expectedPublicPaths) {
  assertStandable(`Campus ${name}`, { x, y });
}
for (const [name, point] of [
  ["Campus library central flower bed", { x: 9000, y: 840 }],
  ["Campus library east flower bed", { x: 9250, y: 840 }],
  ["Campus central garden", { x: 2500, y: 800 }],
  ["Campus lake", { x: 7000, y: 400 }],
  ["Campus museum facade", { x: 7600, y: 650 }],
  ["Campus east annex fence", { x: 10200, y: 820 }],
  ["Campus east study-hall fence", { x: 11400, y: 820 }],
  ["Campus canteen billboard", { x: 200, y: 810 }],
  ["Campus canteen vending machine", { x: 400, y: 760 }],
  ["Campus canteen utility cabinet", { x: 1340, y: 800 }]
]) {
  if (isWalkable(point.x, point.y)) {
    throw new Error(`${name} must remain blocked outside the measured entrance corridor`);
  }
}
if (Math.hypot(gateApproach.x - runtime.libraryGate.x, gateApproach.y - runtime.libraryGate.y) > runtime.libraryGate.radius) {
  throw new Error("Campus library approach is outside the interaction radius");
}

console.log(
  `verified repository panorama ${width}x${height} sha256=${sha256} walkable=${walkability.walkableCells} libraryGate=${runtime.libraryGate.x},${runtime.libraryGate.y} approach=${gateApproach.x},${gateApproach.y}`
);
