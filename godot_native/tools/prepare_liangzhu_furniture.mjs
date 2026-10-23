#!/usr/bin/env node
// Three whole alpha-owned props, one common uniform scale, no color key.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import zlib from 'node:zlib';
import { spawnSync } from 'node:child_process';

const args = process.argv.slice(2), inputs = args.filter(value => !value.startsWith('--'));
const option = (name, fallback) => args.find(value => value.startsWith(`--${name}=`))?.slice(name.length + 3) ?? fallback;
if (inputs.length !== 2 || !option('receipt') || !option('preview') || !option('source-sha')) throw new Error('Usage: prepare_liangzhu_furniture.mjs <approved-transparent-master.png> <asset-directory> --source-sha=<sha256> --receipt=<json> --preview=<png>');
const sourcePath = path.resolve(inputs[0]), outdir = path.resolve(inputs[1]), receiptPath = path.resolve(option('receipt')), previewPath = path.resolve(option('preview'));
const policyPath = path.resolve(option('policy', new URL('../docs/art/art_direction_v1.json', import.meta.url).pathname));
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const sourceBytes = fs.readFileSync(sourcePath), sourceSha = sha(sourceBytes), policyBytes = fs.readFileSync(policyPath), policy = JSON.parse(policyBytes);
if (sourceSha !== option('source-sha')) throw new Error('Source SHA differs from approved transparent master');
if (!sourceBytes.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10]))) throw new Error('PNG source required');
const width = sourceBytes.readUInt32BE(16), height = sourceBytes.readUInt32BE(20);
if (!width || !height || width * height > 4194304) throw new Error('Source exceeds4M-pixel conversion budget');
const paletteHex = policy.palette.colors, palette = paletteHex.map(color => [...Buffer.from(color, 'hex')]);
if (new Set(paletteHex).size !== 32 || palette.some(color => color.length !== 3)) throw new Error('Expected the locked32-color policy');
const ffmpeg = process.env.FFMPEG_BIN || 'ffmpeg';
const decoded = spawnSync(ffmpeg, ['-v', 'error', '-i', sourcePath, '-f', 'rawvideo', '-pix_fmt', 'rgba', '-frames:v', '1', 'pipe:1'], { maxBuffer: width * height * 4 + 1048576 });
if (decoded.error || decoded.status !== 0 || decoded.stdout?.length !== width * height * 4) throw new Error(`Cannot decode source:${decoded.error || decoded.stderr}`);
const raw = decoded.stdout, threshold = 128, visited = new Uint8Array(width * height), queue = new Uint32Array(width * height), components = [];
const sourceAlpha = new Map(); let pureRedDiscarded = 0, pureRedKept = 0;
for (let i = 0; i < raw.length; i += 4) {
  sourceAlpha.set(raw[i + 3], (sourceAlpha.get(raw[i + 3]) || 0) + 1);
  if (raw[i] > 220 && raw[i + 1] < 40 && raw[i + 2] < 40) { if (raw[i + 3] < threshold) pureRedDiscarded++; else pureRedKept++; }
}
for (let start = 0; start < visited.length; start++) {
  if (visited[start] || raw[start * 4 + 3] < threshold) continue;
  let head = 0, tail = 1, left = width, top = height, right = -1, bottom = -1; queue[0] = start; visited[start] = 1;
  while (head < tail) {
    const at = queue[head++], x = at % width, y = Math.floor(at / width);
    left = Math.min(left, x); right = Math.max(right, x); top = Math.min(top, y); bottom = Math.max(bottom, y);
    const near = []; if (x) near.push(at - 1); if (x < width - 1) near.push(at + 1); if (y) near.push(at - width); if (y < height - 1) near.push(at + width);
    for (const next of near) if (!visited[next] && raw[next * 4 + 3] >= threshold) { visited[next] = 1; queue[tail++] = next; }
  }
  components.push({ pixels: Uint32Array.from(queue.subarray(0, tail)), bbox: [left, top, right - left + 1, bottom - top + 1] });
}
const major = components.filter(value => value.pixels.length >= 10000).sort((a, b) => a.bbox[0] - b.bbox[0]);
if (major.length !== 3) throw new Error(`Expected3 independent complete table/chair silhouettes, found${major.length}; inspect alpha before processing`);
if (major[0].bbox[2] <= major[0].bbox[3] || major.slice(1).some(value => value.bbox[3] <= value.bbox[2])) throw new Error('Expected left landscape table and two upright chairs');
const roles = ['table', 'chair_left', 'chair_right'];
const specs = { table: { size: [160, 100], foot: [80, 100] }, chair_left: { size: [60, 120], foot: [30, 120] }, chair_right: { size: [60, 120], foot: [30, 120] } };
const owner = new Int8Array(width * height); owner.fill(-1);
major.forEach((object, index) => { for (const at of object.pixels) owner[at] = index; });
let attachedSmallPixels = 0, distantSmallPixels = 0;
for (const component of components.filter(value => value.pixels.length < 10000)) {
  const [x, y, w, h] = component.bbox; let best = Infinity, nearest = -1;
  for (let index = 0; index < major.length; index++) {
    const [px, py, pw, ph] = major[index].bbox, dx = Math.max(px - x - w, x - px - pw, 0), dy = Math.max(py - y - h, y - py - ph, 0), distance = dx * dx + dy * dy;
    if (distance < best) { best = distance; nearest = index; }
  }
  if (best <= 9) { for (const at of component.pixels) owner[at] = nearest; attachedSmallPixels += component.pixels.length; }
  else distantSmallPixels += component.pixels.length;
}
if (distantSmallPixels > 64) throw new Error(`Distant opaque fragments${distantSmallPixels} need source review, not silent color keying`);
for (let index = 0; index < major.length; index++) {
  let left = width, top = height, right = -1, bottom = -1;
  for (let at = 0; at < owner.length; at++) if (owner[at] === index) { const x = at % width, y = Math.floor(at / width); left = Math.min(left, x); right = Math.max(right, x); top = Math.min(top, y); bottom = Math.max(bottom, y); }
  let sum = 0, count = 0;
  for (let y = bottom - 7; y <= bottom; y++) for (let x = left; x <= right; x++) if (owner[y * width + x] === index) { sum += x + 0.5; count++; }
  major[index].bbox = [left, top, right - left + 1, bottom - top + 1]; major[index].sourceFoot = [sum / count, bottom + 1]; major[index].role = roles[index];
  if (left === 0 || top === 0 || right === width - 1 || bottom === height - 1) throw new Error('Whole object touches master boundary; review possible source cropping');
}
const scale = Math.min(...major.flatMap(object => {
  const { size, foot } = specs[object.role], [x, , w, h] = object.bbox, [fx] = object.sourceFoot;
  return [(foot[0] - 2) / (fx - x), (size[0] - foot[0] - 2) / (x + w - fx), (foot[1] - 2) / h];
}));
function crc32(bytes) { let crc = 0xffffffff; for (const byte of bytes) { crc ^= byte; for (let bit = 0; bit < 8; bit++) crc = (crc >>> 1) ^ (crc & 1 ? 0xedb88320 : 0); } return (crc ^ 0xffffffff) >>> 0; }
function chunk(type, data) { const name = Buffer.from(type), size = Buffer.alloc(4), crc = Buffer.alloc(4); size.writeUInt32BE(data.length); crc.writeUInt32BE(crc32(Buffer.concat([name, data]))); return Buffer.concat([size, name, data, crc]); }
function writePNG(filename, w, h, rgba) {
  const header = Buffer.alloc(13); header.writeUInt32BE(w); header.writeUInt32BE(h, 4); header[8] = 8; header[9] = 6;
  const rows = Buffer.alloc(h * (w * 4 + 1)); for (let y = 0; y < h; y++) rgba.copy(rows, y * (w * 4 + 1) + 1, y * w * 4, (y + 1) * w * 4);
  const png = Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]), chunk('IHDR', header), chunk('IDAT', zlib.deflateSync(rows, { level: 9 })), chunk('IEND', Buffer.alloc(0))]);
  fs.mkdirSync(path.dirname(filename), { recursive: true }); fs.writeFileSync(filename, png); return { file: filename, sha256: sha(png), bytes: png.length, dimensions: [w, h] };
}
const paletteCache = new Map();
function quantize(r, g, b) {
  const key = (r << 16) | (g << 8) | b; if (paletteCache.has(key)) return paletteCache.get(key);
  let best = Infinity, chosen = 0;
  for (let index = 0; index < palette.length; index++) { const c = palette[index], error = (r - c[0]) ** 2 + (g - c[1]) ** 2 + (b - c[2]) ** 2; if (error < best) { best = error; chosen = index; } }
  paletteCache.set(key, chosen); return chosen;
}
const propMetadata = {}, outputs = [], rasters = [];
for (let index = 0; index < major.length; index++) {
  const object = major[index], { size: [w, h], foot } = specs[object.role], rgba = Buffer.alloc(w * h * 4), used = new Set(); let left = w, top = h, right = -1, bottom = -1;
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    const sx = Math.floor(object.sourceFoot[0] + (x + 0.5 - foot[0]) / scale), sy = Math.floor(object.sourceFoot[1] + (y + 0.5 - foot[1]) / scale);
    if (sx < 0 || sx >= width || sy < 0 || sy >= height || owner[sy * width + sx] !== index) continue;
    const from = (sy * width + sx) * 4, to = (y * w + x) * 4, choice = quantize(raw[from], raw[from + 1], raw[from + 2]);
    rgba.set([...palette[choice], 255], to); used.add(choice); left = Math.min(left, x); right = Math.max(right, x); top = Math.min(top, y); bottom = Math.max(bottom, y);
  }
  if (bottom + 1 !== foot[1] || left < 2 || right >= w - 2) throw new Error(`Unsafe final complete bounds/foot alignment:${object.role}`);
  const file = path.join(outdir, object.role + '.png'), written = writePNG(file, w, h, rgba); outputs.push(written); rasters.push({ w, h, rgba });
  propMetadata[object.role] = { texture: `res://assets/native/liangzhu_performance_20261021/${object.role}.png`, nativeSize: [w, h], nativeFootAnchor: foot, visibleRect: [left, top, right - left + 1, bottom - top + 1], sha256: written.sha256, colors: used.size };
}
const metadata = { schema: '755-liangzhu-stage-furniture-v1', rasterPixelsPerCompositionUnit: 5, nativeGrid: 1, alpha: [0, 255], props: propMetadata,
  sets: {
    performance: { table: { compositionRect: [104, 76, 32, 20], foot: [120, 96] }, chair_left: { compositionRect: [102, 64, 12, 24], foot: [108, 88] }, chair_right: { compositionRect: [126, 64, 12, 24], foot: [132, 88] } },
    rehearsal: { table: { compositionRect: [8, 82, 32, 20], foot: [24, 102] }, chair_left: { compositionRect: [8, 68, 12, 24], foot: [14, 92] }, chair_right: { compositionRect: [28, 68, 12, 24], foot: [34, 92] } }
  }, semantics: 'Original decorative stage props only; no collision, picking target, gameplay fact or fake seated actor. Draw from full native frame with uniform density, sort by foot.y; rehearsal coordinates multiply composition units by4.'
};
fs.mkdirSync(outdir, { recursive: true }); const metadataPath = path.join(outdir, 'furniture.json'); fs.writeFileSync(metadataPath, JSON.stringify(metadata, null, 2) + '\n');
//4× nearest comparison, with fixed full frames and checker background.
const previewWidth = 1280, previewHeight = 480, preview = Buffer.alloc(previewWidth * previewHeight * 4);
for (let y = 0; y < previewHeight; y++) for (let x = 0; x < previewWidth; x++) { const gray = ((x >> 4) + (y >> 4)) % 2 ? 210 : 240; preview.set([gray, gray, gray, 255], (y * previewWidth + x) * 4); }
let cursor = 0;
for (const { w, h, rgba } of rasters) {
  for (let y = 0; y < h * 4; y++) for (let x = 0; x < w * 4; x++) { const from = (Math.floor(y / 4) * w + Math.floor(x / 4)) * 4; if (!rgba[from + 3]) continue; rgba.copy(preview, ((previewHeight - h * 4 + y) * previewWidth + cursor + x) * 4, from, from + 4); }
  cursor += w * 4 + 40;
}
const previewRecord = writePNG(previewPath, previewWidth, previewHeight, preview);
const report = { schema: '755-liangzhu-furniture-derivation-v1', source: { file: sourcePath, sha256: sourceSha, dimensions: [width, height], alphaHistogram: Object.fromEntries([...sourceAlpha].sort((a, b) => a[0] - b[0])), unchanged: fs.readFileSync(sourcePath).equals(sourceBytes), sourceProcessingBoundary: 'Web background-removal generation changed geometry/detail; this is not a claim of pure original-pixel alpha removal.' },
  tool: { file: new URL(import.meta.url).pathname, sha256: sha(fs.readFileSync(new URL(import.meta.url))), node: process.version, decoder: ffmpeg }, policy: { file: policyPath, sha256: sha(policyBytes), version: policy.version, palette: paletteHex },
  segmentation: { alphaThreshold: threshold, majorCount: 3, attachedSmallPixels, distantSmallPixels, noColorKey: true, pureRedSourcePixelsBelowThreshold: pureRedDiscarded, pureRedSourcePixelsKeptByAlpha: pureRedKept },
  geometry: { commonUniformScale: scale, sameScaleAcrossAll3Objects: true, completeShapesNotCropped: true, interpolation: 'nearest inverse-map pixel centers from measured lower-foot anchors', nonuniformStretch: false, elasticSnap: false, sourceObjects: major.map(({ pixels, ...object }) => object) },
  quantization: { colors: 'Nearest among32 locked RGB colors, integer squared Euclidean sRGB-byte distance, policy-index tie break', dithering: false, alpha: [0, 255], colorKeying: false }, outputs, metadata: { file: metadataPath, sha256: sha(fs.readFileSync(metadataPath)) }, preview: { ...previewRecord, nearestScale: 4, layout: 'table / chair_left / chair_right, complete fixed frames on checker, shared bottom edge' },
  acceptance: 'Pending actual output preview and independent decoded dimension/palette/alpha/foot checks. No engine import, stage integration, updated performance capture or movie acceptance.' };
fs.mkdirSync(path.dirname(receiptPath), { recursive: true }); fs.writeFileSync(receiptPath, JSON.stringify(report, null, 2) + '\n');
console.log(JSON.stringify({ outputs, metadata: report.metadata, preview: previewRecord, commonScale: scale, segmentation: report.segmentation, props: propMetadata, receipt: receiptPath }, null, 2));
