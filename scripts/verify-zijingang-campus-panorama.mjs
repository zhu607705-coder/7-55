import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";

const EXPECTED = {
  width: 5016,
  height: 5016,
  sha256: "600e3010c7b1ccb4e4c697850e9ee37b6670d84aaec3ba5ce8fc0c1274a718bd",
  foundationLibrary: { x: 3000, y: 280 },
  libraryGate: { x: 3000, y: 538, radius: 112 }
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
assertStandable("Campus library gate approach", gateApproach);
assertStandable("Campus library checkpoint", {
  x: runtime.libraryGate.x,
  y: runtime.libraryGate.y + 72
});
if (Math.hypot(gateApproach.x - runtime.libraryGate.x, gateApproach.y - runtime.libraryGate.y) > runtime.libraryGate.radius) {
  throw new Error("Campus library approach is outside the interaction radius");
}

console.log(
  `verified repository panorama ${width}x${height} sha256=${sha256} walkable=${walkability.walkableCells} libraryGate=${runtime.libraryGate.x},${runtime.libraryGate.y} approach=${gateApproach.x},${gateApproach.y}`
);
