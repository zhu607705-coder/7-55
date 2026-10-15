// Dependency-free, read-only source checks; no engine or external process is launched.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import zlib from 'node:zlib';

const root = path.resolve(import.meta.dirname, '..');
const campus = path.join(root, 'campuses/buct');
const baseline = process.env.BUCT_CAMPUS_BASE || campus;
const profile = JSON.parse(fs.readFileSync(path.join(campus, 'data/ambient-squirrel-profile.json')));
const script = fs.readFileSync(path.join(campus, 'scripts/ambient_squirrel.gd'), 'utf8');
const installer = fs.readFileSync(path.join(campus, 'scripts/ambient_squirrel_patch.gd'), 'utf8');
const nav = JSON.parse(fs.readFileSync(path.join(baseline, 'data/playable_route.json')));
const layers = JSON.parse(fs.readFileSync(path.join(baseline, 'data/layers.json')));
let checks = 0;
function check(value, label) { assert.ok(value, label); checks++; console.log(`PASS ${label}`); }
function inside([x, y], poly) {
 let result = false;
 for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
  const [ax, ay] = poly[i], [bx, by] = poly[j];
  if ((ay > y) !== (by > y) && x < (bx - ax) * (y - ay) / (by - ay) + ax) result = !result;
 }
 return result;
}
function edgeDistance(p, a, b) {
 const dx = b[0] - a[0], dy = b[1] - a[1];
 const t = Math.max(0, Math.min(1, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / (dx * dx + dy * dy || 1)));
 return Math.hypot(p[0] - a[0] - dx * t, p[1] - a[1] - dy * t);
}
function polygonDistance(p, poly) {
 return inside(p, poly) ? 0 : Math.min(...poly.map((a, i) => edgeDistance(p, a, poly[(i + 1) % poly.length])));
}
check(profile.version === 1 && profile.frames.length === 8, 'Eight measured poses in one versioned profile');
check(profile.display_height_source_px === 8 && profile.reference_height_pixels === 313, 'One common 8/313 scale, below the 18px student');
check(JSON.stringify(profile.route_source_xy) === '[[722,690],[746,690]]', 'Bounded 24px horizontal tree-adjacent route');
for (let i = 0; i <= 48; i++) {
 const point = [722 + i / 2, 690];
 for (const [dx, dy] of [[0, 0], [3, 0], [-3, 0], [0, 3], [0, -3]])
  assert.ok(nav.walkable_polygons.some(poly => inside([point[0] + dx, point[1] + dy], poly)), `Paving sample ${i}`);
 for (const object of layers.objects) for (const poly of object.footprints)
  assert.ok(polygonDistance(point, poly) > 3.2, `Footprint clearance ${object.id} sample ${i}`);
 for (const tree of nav.occluders)
  assert.ok(Math.hypot(point[0] - tree.anchor[0], point[1] - tree.anchor[1]) > (tree.trunk_radius || 2) + 3.2, `Tree clearance ${tree.id} sample ${i}`);
}
check(true, '49 half-pixel samples pass five-point paving, original footprint and tree clearance');
check(nav.occluders.some(tree => tree.id === profile.tree_id && JSON.stringify(tree.anchor) === '[712,689]'), 'Existing tree reference is unchanged');
check(script.startsWith('extends Node2D') && !/Collision(Object|Shape|Polygon)|CharacterBody|StaticBody|Area2D|InputMap|Input\.|SaveStore|FileAccess\.WRITE|set_point_solid/.test(script), 'Visual-only component has no collision, input, save or navigation authority');
check(/distance_phase \+ actual \/ float\(profile\.stride_source_px\)/.test(script), 'Run cycle follows actual moved distance');
check(/set_process\(configured and on_screen and app_focused and not blocked\)/.test(script) && /minf\(delta, MAX_DELTA\)/.test(script), 'Off-screen/focus pause and bounded delta are explicit');
check(/objects\.has_node\("AmbientSquirrel"\)/.test(installer) && /Callable\(host, "is_walkable"\)/.test(installer), 'Installer is idempotent and reads existing walkability');
check(/Vector3\(1\.0, 0\.25, 0\.035\)/.test(script) && /Vector3\(0\.7, 0\.175, 0\.045\)/.test(script) && /Vector3\(0\.4, 0\.10, 0\.055\)/.test(script) && !script.split('func advance(')[1].split('func _segment_is_legal')[0].includes('queue_redraw'), 'Tiny cached warm contact shadow uses AA-calibrated radii and no per-tick geometry');
check(new Set(profile.poses.run).size === 4, 'Four distinct run frame references, no duplicate-index imitation');
const pngPath = path.join(root, profile.atlas.replace('res://', ''));
const png = fs.readFileSync(pngPath);
check(crypto.createHash('sha256').update(png).digest('hex') === profile.source_sha256, 'Original generated RGBA bytes preserved');
check(png.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10])), 'PNG signature');
const width = png.readUInt32BE(16), height = png.readUInt32BE(20);
check(width === 1536 && height === 1024 && png[24] === 8 && png[25] === 6 && png[28] === 0, 'Real 1536x1024 eight-bit RGBA, non-interlaced');
const idat = [];
for (let cursor = 8; cursor < png.length;) {
 const size = png.readUInt32BE(cursor), type = png.toString('ascii', cursor + 4, cursor + 8);
 if (type === 'IDAT') idat.push(png.subarray(cursor + 8, cursor + 8 + size));
 cursor += size + 12;
}
const raw = zlib.inflateSync(Buffer.concat(idat)), stride = width * 4;
assert.equal(raw.length, (stride + 1) * height);
const rgba = Buffer.alloc(stride * height);
const paeth = (a, b, c) => { const p = a + b - c, pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c); return pa <= pb && pa <= pc ? a : pb <= pc ? b : c; };
for (let y = 0; y < height; y++) {
 const filter = raw[y * (stride + 1)];
 assert.ok(filter >= 0 && filter <= 4);
 for (let x = 0; x < stride; x++) {
  const target = y * stride + x, value = raw[y * (stride + 1) + x + 1];
  const a = x >= 4 ? rgba[target - 4] : 0, b = y ? rgba[target - stride] : 0, c = x >= 4 && y ? rgba[target - stride - 4] : 0;
  const addition = [0, a, b, Math.floor((a + b) / 2), paeth(a, b, c)][filter];
  rgba[target] = (value + addition) & 255;
 }
}
let zero = 0, solid = 0;
for (let i = 3; i < rgba.length; i += 4) { zero += rgba[i] === 0; solid += rgba[i] >= 243; }
check(zero === 1198011 && solid === 278550, 'Measured real alpha, no opaque rectangular background');
const digests = [];
for (const [index, frame] of profile.frames.entries()) {
 const [x, y, w, h] = frame.region, [fx, fy] = frame.foot;
 assert.ok(x >= 0 && y >= 0 && x + w <= width && y + h <= height && fx >= 0 && fx <= w && fy >= 0 && fy <= h, `Frame ${index} region and ground anchor`);
 let content = 0, border = 0;
 const bytes = Buffer.alloc(w * h);
 for (let py = 0; py < h; py++) for (let px = 0; px < w; px++) {
  const alpha = rgba[((y + py) * width + x + px) * 4 + 3];
  bytes[py * w + px] = alpha;
  if (alpha > 10) { content++; if (!px || !py || px === w - 1 || py === h - 1) border++; }
 }
 assert.ok(content > 30000 && border === 0, `Frame ${index} retains a complete clear-border silhouette`);
 digests.push(crypto.createHash('sha256').update(bytes).digest('hex'));
}
check(new Set(digests).size === 8, 'All eight crops contain distinct source alpha patterns; visual gait review remains required');
check(profile.frames.slice(4).every(frame => frame.body_ground_pivot_sheet_xy[1] === 866), 'Airborne and contact poses share the measured ground line');
const importConfig = fs.readFileSync(pngPath + '.import', 'utf8');
check(/mipmaps\/generate=true/.test(importConfig) && /TEXTURE_FILTER_LINEAR_WITH_MIPMAPS/.test(script), 'Single mipmapped atlas for stable miniature sampling');
console.log(`BUCT_SQUIRREL_SOURCE: ${checks} checks passed`);
