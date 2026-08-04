import { readFile } from "node:fs/promises";

const mapUrl = new URL("../src/data/maps/zijingang-campus.json", import.meta.url);
const map = JSON.parse(await readFile(mapUrl, "utf8"));

if (
  map.type !== "map"
  || map.orientation !== "orthogonal"
  || map.width !== 75
  || map.height !== 50
  || map.tilewidth !== 32
  || map.tileheight !== 32
) {
  throw new Error("Zijingang Tiled runtime must remain a 75x50 orthogonal map with 32px tiles");
}

const layers = new Map(map.layers.map((layer) => [layer.name, layer]));
for (const name of [
  "Ground",
  "Roads",
  "Water",
  "Decor",
  "RoadPaths",
  "Landmarks",
  "Environment",
  "WaterCollisions",
  "StructureCollisions"
]) {
  if (!layers.has(name)) throw new Error(`Zijingang Tiled runtime is missing ${name}`);
}

for (const name of ["Ground", "Roads", "Water", "Decor"]) {
  const layer = layers.get(name);
  if (layer.type !== "tilelayer" || layer.data.length !== map.width * map.height) {
    throw new Error(`${name} must cover the complete 2400x1600 tile world`);
  }
}

const objectNames = (layerName) => new Set((layers.get(layerName)?.objects ?? []).map((object) => object.name));
const roadNames = objectNames("RoadPaths");
for (const name of [
  "south_gate_approach",
  "foundation_walk",
  "east_mid_link",
  "auditorium_walk"
]) {
  if (!roadNames.has(name)) throw new Error(`Campus route is missing ${name}`);
}

const landmarkNames = objectNames("Landmarks");
for (const name of ["foundation_library", "qiushi_auditorium", "south_gate"]) {
  if (!landmarkNames.has(name)) throw new Error(`Campus landmark is missing ${name}`);
}

if ((layers.get("WaterCollisions")?.objects?.length ?? 0) < 1) {
  throw new Error("Tile campus must retain source-pixel water collision objects");
}
if ((layers.get("StructureCollisions")?.objects?.length ?? 0) < 1) {
  throw new Error("Tile campus must retain source-pixel structure collision objects");
}

console.log("verified Zijingang Tiled campus 2400x1600 with dorm, library, canteen route and theater approach");
