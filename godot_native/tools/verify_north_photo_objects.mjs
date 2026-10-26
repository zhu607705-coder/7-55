#!/usr/bin/env node
// Read-only candidate QA. Importing the existing PNG decoder does not run its normalizer.
import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { existsSync, lstatSync, readFileSync, readdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { decodePng } from "../../scripts/normalize-chapter4-755-assets.mjs";

const HERE = dirname(fileURLToPath(import.meta.url));
export const CATALOG = resolve(HERE, "../art_source/north_photo_objects_20261026");
const IDS = ["north1_104_microwave", "north1_104_loveseat", "north1_104_pendant",
  "north3_109_doorplate", "north3_building_display", "north_complex_locker",
  "north_complex_speaker", "north_complex_clock", "north_complex_double_door",
  "north_complex_power_module", "north_complex_study_divider"].sort();
const SOURCE_HOSTS = new Set(["zulg.zju.edu.cn", "m.thepaper.cn", "mse.zju.edu.cn"]);
const PHOTO_HOSTS = new Set(["zulg.zju.edu.cn", "imagepphcloud.thepaper.cn", "mse.zju.edu.cn"]);
const nonempty = value => typeof value === "string" && value.trim().length > 0;
const dateOrUnknown = value => value === null || /^\d{4}-\d{2}-\d{2}$/.test(value);
function publicUrl(value, hosts) {
  const url = new URL(value);
  assert(url.protocol === "https:" && hosts.has(url.hostname) && !url.username && !url.password, "public source URL");
}

export function verifyMetadata(catalog) {
  assert.equal(catalog.schema_version, 1);
  assert.equal(catalog.catalog_id, "north_photo_objects_20261026");
  assert.equal(catalog.status, "photo_grounded_art_candidates_not_integrated");
  assert.equal(catalog.asset_count, 11);
  assert.equal(catalog.generation.existing_generated_scene_uploaded, false);
  assert.equal(catalog.generation.local_pixel_edits, false);
  assert.equal(catalog.rights.source_photos_redistributed, false);
  assert.deepEqual(catalog.objects.map(o => o.id).sort(), IDS, "exactly 11 unique stable IDs");
  const sources = new Map(catalog.sources.map(s => [s.id, s]));
  assert.equal(sources.size, catalog.sources.length, "unique source IDs");
  for (const source of sources.values()) {
    publicUrl(source.page_url, SOURCE_HOSTS);
    for (const field of ["published_date", "event_date", "capture_date"]) assert(dateOrUnknown(source[field]), field);
    assert(nonempty(source.date_note) && nonempty(source.location_context));
  }
  const paths = new Set();
  for (const o of catalog.objects) {
    assert.equal(o.status, "candidate_not_integrated");
    assert(nonempty(o.label));
    const i = o.image;
    assert(/^png\/[a-z0-9_]+\.png$/.test(i.path), "bounded relative PNG path");
    assert(!paths.has(i.path), "unique PNG paths"); paths.add(i.path);
    assert(/^[a-f0-9]{64}$/.test(i.sha256), "SHA256");
    assert(Number.isInteger(i.bytes) && i.bytes > 0);
    assert([i.width, i.height].every(v => Number.isInteger(v) && v > 0 && v <= 4096));
    assert.equal(i.mode, "RGBA"); assert.equal(i.native_png_unchanged, true);
    const evidence = o.photo_evidence;
    assert(sources.has(evidence.source_id), "known photo source");
    publicUrl(evidence.image_url, PHOTO_HOSTS);
    assert(nonempty(evidence.observed_features) && nonempty(evidence.interpretive_or_unseen_parts));
    assert(nonempty(evidence.location.basis));
    if (evidence.location.scope === "complex_only") {
      assert.deepEqual([evidence.location.building, evidence.location.floor, evidence.location.room], [null, null, null], "unknown location stays unknown");
    }
    const p = o.preview;
    assert.equal(p.is_measured, false);
    assert(Array.isArray(p.pivot_canvas_px) && p.pivot_canvas_px.length === 2);
    assert(p.pivot_canvas_px.every((v, axis) => Number.isFinite(v) && v >= 0 && v < [i.width, i.height][axis]), "canvas pivot bounds");
    assert(nonempty(p.anchor_role));
    assert(Number.isFinite(p.uniform_scale) && p.uniform_scale > 0);
    assert(Number.isFinite(p.target_visible_width_px) && p.target_visible_width_px > 0);
    for (const key of ["world_coordinates", "measured_dimensions", "collision_geometry", "navigation_geometry"]) assert.equal(o.placement[key], null, "no measured placement/geometry");
    assert.deepEqual(o.placement.instances, []);
    const q = o.alpha_qa;
    assert.equal(q.min, 0); assert.equal(q.max, 255);
    assert([q.transparent_pixels, q.opaque255_pixels, q.partial_alpha_pixels].every(v => Number.isInteger(v) && v >= 0));
    assert.equal(q.transparent_pixels + q.opaque255_pixels + q.partial_alpha_pixels, i.width * i.height);
    assert(q.transparent_pixels > 0 && q.opaque255_pixels > 0, "real transparent and solid pixels");
    const b = q.visible_bbox_alpha128;
    assert(Array.isArray(b) && b.length === 4 && b.every(Number.isInteger));
    assert(b[0] >= 0 && b[1] >= 0 && b[0] < b[2] && b[1] < b[3] && b[2] <= i.width && b[3] <= i.height);
    assert(Math.abs(p.uniform_scale * (b[2] - b[0]) - p.target_visible_width_px) < 0.002, "uniform preview width");
  }
  return catalog.objects.length;
}

export function verifyImage(object, bytes) {
  const expected = object.image;
  assert.equal(bytes.length, expected.bytes, `${object.id}: byte count`);
  assert.equal(createHash("sha256").update(bytes).digest("hex"), expected.sha256, `${object.id}: unchanged SHA256`);
  const png = decodePng(bytes, expected.path);
  assert.deepEqual([png.width, png.height, png.channels], [expected.width, expected.height, 4], `${object.id}: native RGBA`);
  const hist = new Array(256).fill(0);
  const bbox = [png.width, png.height, 0, 0];
  for (let y = 0; y < png.height; y++) for (let x = 0; x < png.width; x++) {
    const alpha = png.pixels[(y * png.width + x) * 4 + 3]; hist[alpha]++;
    if (alpha >= 128) {
      bbox[0] = Math.min(bbox[0], x); bbox[1] = Math.min(bbox[1], y);
      bbox[2] = Math.max(bbox[2], x + 1); bbox[3] = Math.max(bbox[3], y + 1);
    }
  }
  const q = object.alpha_qa;
  assert.equal(hist[0], q.transparent_pixels, `${object.id}: transparent pixels`);
  assert.equal(hist[255], q.opaque255_pixels, `${object.id}: opaque pixels`);
  assert.equal(png.width * png.height - hist[0] - hist[255], q.partial_alpha_pixels, `${object.id}: soft alpha`);
  assert.deepEqual(bbox, q.visible_bbox_alpha128, `${object.id}: visible bbox is QA, not collision`);
}

export function verifyCatalog(root = CATALOG) {
  const catalog = JSON.parse(readFileSync(resolve(root, "objects.json"), "utf8"));
  verifyMetadata(catalog);
  assert(existsSync(resolve(root, "../.gdignore")), "authoring sources excluded from Godot import");
  assert.deepEqual(readdirSync(root).sort(), ["README.md", "objects.json", "png"], "only intended deliverables");
  assert.deepEqual(readdirSync(resolve(root, "png")).sort(), catalog.objects.map(o => o.image.path.slice(4)).sort(), "no missing or extra PNGs");
  for (const object of catalog.objects) {
    const path = resolve(root, object.image.path);
    assert(lstatSync(path).isFile() && !lstatSync(path).isSymbolicLink(), "regular local PNG only");
    verifyImage(object, readFileSync(path));
  }
  return catalog;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const catalog = verifyCatalog();
  console.log(`North photo object catalog PASS: ${catalog.objects.length} unchanged RGBA PNGs; ${catalog.objects.reduce((n, o) => n + o.image.bytes, 0)} bytes; provenance, IDs, paths, alpha, pivots and no-placement contract.`);
}
