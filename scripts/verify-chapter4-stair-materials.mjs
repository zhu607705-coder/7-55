#!/usr/bin/env node

import { createHash } from "node:crypto";
import { readFile, stat } from "node:fs/promises";
import { fileURLToPath } from "node:url";

const materialDir = fileURLToPath(new URL("../src/assets/rpg/chapter4-stair/materials/", import.meta.url));
const manifestPath = new URL("../src/assets/rpg/chapter4-stair/materials/manifest.json", import.meta.url);
const manifest = JSON.parse(await readFile(manifestPath, "utf8"));

const failures = [];
let passed = 0;

function check(condition, message) {
  if (condition) {
    passed += 1;
  } else {
    failures.push(message);
  }
}

check(manifest.schemaVersion === 1, "manifest schemaVersion must be 1");
check(manifest.license?.spdx === "CC0-1.0", "material license must be CC0-1.0");
check(
  manifest.license?.url === "https://docs.ambientcg.com/license/",
  "license URL must point to the official ambientCG license page"
);
check(manifest.runtimePolicy?.networkDependency === false, "runtime must not depend on ambientCG network access");
check(Array.isArray(manifest.materials) && manifest.materials.length === 3, "manifest must contain three material families");

const expectedIds = ["Plaster001", "Concrete010", "Metal012"];
check(
  expectedIds.every((id) => manifest.materials.some((material) => material.id === id)),
  "manifest must include Plaster001, Concrete010, and Metal012"
);

const seenFiles = new Set();
for (const material of manifest.materials) {
  check(
    material.sourcePage === `https://ambientcg.com/a/${material.id}`,
    `${material.id} must use its official ambientCG asset page`
  );
  check(
    material.download === `https://ambientcg.com/get?file=${material.id}_1K-JPG.zip`,
    `${material.id} must record its official 1K-JPG package`
  );
  for (const map of material.maps ?? []) {
    check(!seenFiles.has(map.file), `${map.file} must appear only once`);
    seenFiles.add(map.file);
    const filePath = new URL(`../src/assets/rpg/chapter4-stair/materials/${map.file}`, import.meta.url);
    try {
      const fileStat = await stat(filePath);
      const bytes = await readFile(filePath);
      const digest = createHash("sha256").update(bytes).digest("hex");
      check(fileStat.size === map.bytes, `${map.file} byte size must match manifest`);
      check(digest === map.sha256, `${map.file} SHA-256 must match manifest`);
      check(fileStat.size > 0, `${map.file} must not be empty`);
    } catch (error) {
      failures.push(`${map.file} is missing: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
}

check(seenFiles.size === 3, "runtime material set must contain exactly three color maps");
check(materialDir.endsWith("/materials/"), "material directory resolution must remain scoped");

if (failures.length > 0) {
  for (const failure of failures) {
    console.error(`FAIL  ${failure}`);
  }
  console.error(`\nChapter 4 stair materials: ${passed} passed, ${failures.length} failed.`);
  process.exit(1);
}

console.log(`Chapter 4 stair materials: ${passed} checks passed.`);
