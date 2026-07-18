import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";

const EXPECTED = {
  width: 5016,
  height: 5016,
  sha256: "63ff841fce9e29fd73775b6f42cf3ef65ae303993a55f3a555c90ec0a5ff98c2"
};

const plateUrl = new URL("../src/assets/rpg/campus/zijingang_campus_plate.png", import.meta.url);
const runtimeUrl = new URL("../src/data/maps/zijingang-campus-runtime.json", import.meta.url);
const plate = await readFile(plateUrl);
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
if (!Array.isArray(runtime.collisions?.buildings) || !Array.isArray(runtime.collisions?.water)) {
  throw new Error("Campus runtime collision arrays are missing");
}

console.log(`verified repository panorama ${width}x${height} sha256=${sha256}`);
