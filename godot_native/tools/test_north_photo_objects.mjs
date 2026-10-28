#!/usr/bin/env node
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { CATALOG, verifyCatalog, verifyImage, verifyMetadata } from "./verify_north_photo_objects.mjs";

const original = verifyCatalog();
let checks = 1;
function rejected(label, mutate) {
  const copy = structuredClone(original); mutate(copy);
  assert.throws(() => verifyMetadata(copy), undefined, label); checks++;
}
rejected("missing object", c => c.objects.pop());
rejected("duplicate ID", c => c.objects[1].id = c.objects[0].id);
rejected("duplicate image path", c => c.objects[1].image.path = c.objects[0].image.path);
rejected("path traversal", c => c.objects[0].image.path = "png/../../outside.png");
rejected("absolute path", c => c.objects[0].image.path = "/tmp/object.png");
rejected("unknown source", c => c.objects[0].photo_evidence.source_id = "missing");
rejected("private source URL", c => c.sources[0].page_url = "https://chatgpt.com/c/private");
rejected("fake exact location", c => c.objects.find(o => o.photo_evidence.location.scope === "complex_only").photo_evidence.location.floor = 1);
rejected("out-of-canvas pivot", c => c.objects[0].preview.pivot_canvas_px = [-1, 20]);
rejected("nonuniform or wrong preview size", c => c.objects[0].preview.uniform_scale = 3);
rejected("measured scale claim", c => c.objects[0].preview.is_measured = true);
rejected("invented geometry", c => c.objects[0].placement.collision_geometry = [[0, 0], [1, 1]]);
rejected("invented instance", c => c.objects[0].placement.instances.push({ x: 1, y: 2 }));
rejected("alpha count mismatch", c => c.objects[0].alpha_qa.transparent_pixels++);
rejected("visual bbox outside canvas", c => c.objects[0].alpha_qa.visible_bbox_alpha128[2] = 10000);
const first = original.objects[0];
const bytes = readFileSync(resolve(CATALOG, first.image.path));
const altered = Buffer.from(bytes); altered[altered.length - 1] ^= 1;
assert.throws(() => verifyImage(first, altered), /unchanged SHA256/); checks++;
const wrongDimensions = structuredClone(first); wrongDimensions.image.width++;
assert.throws(() => verifyImage(wrongDimensions, bytes), /native RGBA/); checks++;
const wrongAlpha = structuredClone(first); wrongAlpha.alpha_qa.opaque255_pixels++;
assert.throws(() => verifyImage(wrongAlpha, bytes), /opaque pixels/); checks++;
const wrongBBox = structuredClone(first); wrongBBox.alpha_qa.visible_bbox_alpha128[0]++;
assert.throws(() => verifyImage(wrongBBox, bytes), /visible bbox/); checks++;
console.log(`North photo object validation regressions PASS: ${checks} positive/negative checks.`);
