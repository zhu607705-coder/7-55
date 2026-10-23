#!/usr/bin/env node
// Whole connected silhouettes -> fixed cells, one scale across all8 poses.
// Alpha segmentation is authoritative; no clothing color is used as a key.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import zlib from 'node:zlib';
import { spawnSync } from 'node:child_process';

const args = process.argv.slice(2), inputs = args.filter(value => !value.startsWith('--'));
const option = (name, fallback) => args.find(value => value.startsWith(`--${name}=`))?.slice(name.length + 3) ?? fallback;
if (inputs.length !== 2 || !option('receipt') || !option('preview')) throw new Error('Usage: prepare_liangzhu_actors.mjs <master.png> <actors.png> --receipt=<json> --preview=<png> [--source-sha=<sha256>]');
const sourcePath = path.resolve(inputs[0]), output = path.resolve(inputs[1]), reportPath = path.resolve(option('receipt')), previewPath = path.resolve(option('preview'));
const policyPath = path.resolve(option('policy', new URL('../docs/art/art_direction_v1.json', import.meta.url).pathname));
if (new Set([sourcePath, output, reportPath, previewPath, policyPath]).size !== 5) throw new Error('All input/output paths must be separate');
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const sourceBytes = fs.readFileSync(sourcePath), sourceSha = sha(sourceBytes), policyBytes = fs.readFileSync(policyPath), policy = JSON.parse(policyBytes);
if (option('source-sha') && option('source-sha') !== sourceSha) throw new Error('Source SHA differs from approved master');
if (!sourceBytes.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10]))) throw new Error('PNG source required');
const width = sourceBytes.readUInt32BE(16), height = sourceBytes.readUInt32BE(20);
if (width !== 1536 || height !== 1024) throw new Error('Expected the approved1536×1024 actor master');
if (JSON.stringify(policy.profiles.fineCharacter.nativeRaster) !== '[120,160]' || policy.profiles.fineCharacter.colorBudget !== 24) throw new Error('Expected120×160 native fine actor profile with24-color budget');
const ffmpeg = process.env.FFMPEG_BIN || 'ffmpeg';
const decoded = spawnSync(ffmpeg, ['-v', 'error', '-i', sourcePath, '-f', 'rawvideo', '-pix_fmt', 'rgba', '-frames:v', '1', 'pipe:1'], { maxBuffer: width * height * 4 + 1048576 });
if (decoded.error || decoded.status !== 0 || decoded.stdout?.length !== width * height * 4) throw new Error(`Cannot decode actors: ${decoded.error || decoded.stderr}`);
const raw = decoded.stdout, threshold = 128, visited = new Uint8Array(width * height), queue = new Uint32Array(width * height), components = [];
for (let start = 0; start < visited.length; start++) {
  if (visited[start] || raw[start * 4 + 3] < threshold) continue;
  let head = 0, tail = 1, left = width, top = height, right = -1, bottom = -1;
  queue[0] = start; visited[start] = 1;
  while (head < tail) {
    const at = queue[head++], x = at % width, y = Math.floor(at / width);
    left = Math.min(left, x); right = Math.max(right, x); top = Math.min(top, y); bottom = Math.max(bottom, y);
    const near = []; if (x) near.push(at - 1); if (x < width - 1) near.push(at + 1); if (y) near.push(at - width); if (y < height - 1) near.push(at + width);
    for (const index of near) if (!visited[index] && raw[index * 4 + 3] >= threshold) { visited[index] = 1; queue[tail++] = index; }
  }
  components.push({ pixels: Uint32Array.from(queue.subarray(0, tail)), bbox: [left, top, right - left + 1, bottom - top + 1] });
}
const major = components.filter(value => value.pixels.length >= 50000);
if (major.length !== 8) throw new Error(`Expected8 whole major silhouettes, found${major.length}; artwork must be reviewed`);
const rows = [[], []];
for (const component of major) {
  const [x, y, w, h] = component.bbox, row = Math.floor((y + h / 2) / 512);
  if (row < 0 || row > 1) throw new Error('Actor lies outside the intended two rows'); rows[row].push(component);
}
if (rows.some(row => row.length !== 4)) throw new Error('Expected four distinct complete poses per row');
const poses = rows.flatMap((row, y) => row.sort((a, b) => a.bbox[0] - b.bbox[0]).map((component, x) => ({ ...component, row: y, col: x, extraPixels: 0 })));
const owner = new Int8Array(width * height); owner.fill(-1);
poses.forEach((pose, index) => { for (const at of pose.pixels) owner[at] = index; });
let discardedSmallPixels = 0, attachedSmallPixels = 0;
for (const component of components.filter(value => value.pixels.length < 50000)) {
  const [x, y, w, h] = component.bbox; let closest = -1, best = Infinity;
  for (let index = 0; index < poses.length; index++) {
    const [px, py, pw, ph] = poses[index].bbox;
    const dx = Math.max(px - (x + w), x - (px + pw), 0), dy = Math.max(py - (y + h), y - (py + ph), 0), distance = dx * dx + dy * dy;
    if (distance < best) { best = distance; closest = index; }
  }
  // Preserve tiny detached embroidery/ornaments within3source pixels, but do
  // not silently turn distant high-alpha background fragments into costumes.
  if (closest >= 0 && best <= 9) { for (const at of component.pixels) owner[at] = closest; poses[closest].extraPixels += component.pixels.length; attachedSmallPixels += component.pixels.length; }
  else discardedSmallPixels += component.pixels.length;
}
if (discardedSmallPixels > 64) throw new Error(`Unexpected distant opaque fragments:${discardedSmallPixels}; review master before deriving`);
for (let index = 0; index < poses.length; index++) {
  const pose = poses[index]; let left = width, top = height, right = -1, bottom = -1;
  for (let at = 0; at < owner.length; at++) if (owner[at] === index) { const x = at % width, y = Math.floor(at / width); left = Math.min(left, x); right = Math.max(right, x); top = Math.min(top, y); bottom = Math.max(bottom, y); }
  let sumX = 0, footPixels = 0;
  for (let y = bottom - 7; y <= bottom; y++) for (let x = left; x <= right; x++) if (owner[y * width + x] === index) { sumX += x + 0.5; footPixels++; }
  pose.bbox = [left, top, right - left + 1, bottom - top + 1];
  pose.sourceFoot = [sumX / footPixels, bottom + 1]; pose.footMeasurementPixels = footPixels;
}
const maxHeight = Math.max(...poses.map(pose => pose.bbox[3])), maxWidth = Math.max(...poses.map(pose => pose.bbox[2]));
const maxLeft = Math.max(...poses.map(pose => pose.sourceFoot[0] - pose.bbox[0]));
const maxRight = Math.max(...poses.map(pose => pose.bbox[0] + pose.bbox[2] - pose.sourceFoot[0]));
const scale = Math.min(140 / maxHeight, 116 / maxWidth, 58 / maxLeft, 58 / maxRight);
const cellWidth = 120, cellHeight = 160, atlasWidth = 480, atlasHeight = 320, targetFoot = [60, 150];
const sampled = Buffer.alloc(atlasWidth * atlasHeight * 4), final = Buffer.alloc(sampled.length);
for (let index = 0; index < poses.length; index++) {
  const pose = poses[index]; let count = 0;
  for (let y = 0; y < cellHeight; y++) for (let x = 0; x < cellWidth; x++) {
    const sx = Math.floor(pose.sourceFoot[0] + (x + 0.5 - targetFoot[0]) / scale), sy = Math.floor(pose.sourceFoot[1] + (y + 0.5 - targetFoot[1]) / scale);
    if (sx < 0 || sx >= width || sy < 0 || sy >= height || owner[sy * width + sx] !== index) continue;
    const from = (sy * width + sx) * 4, to = ((pose.row * cellHeight + y) * atlasWidth + pose.col * cellWidth + x) * 4;
    sampled.set([...raw.subarray(from, from + 3), 255], to); count++;
  }
  pose.outputVisiblePixels = count;
}
const paletteHex = policy.palette.colors, palette = paletteHex.map(color => [...Buffer.from(color, 'hex')]);
const nearest = (r, g, b, choices) => {
  let best = Infinity, chosen = -1;
  for (const index of choices) { const rgb = palette[index], error = (rgb[0] - r) ** 2 + (rgb[1] - g) ** 2 + (rgb[2] - b) ** 2; if (error < best) { best = error; chosen = index; } } return chosen;
};
const all = [...palette.keys()], rowPalettes = [];
for (let row = 0; row < 2; row++) {
  const histogram = new Map();
  for (let y = row * cellHeight; y < (row + 1) * cellHeight; y++) for (let x = 0; x < atlasWidth; x++) {
    const i = (y * atlasWidth + x) * 4; if (!sampled[i + 3]) continue;
    const choice = nearest(sampled[i], sampled[i + 1], sampled[i + 2], all); histogram.set(choice, (histogram.get(choice) || 0) + 1);
  }
  const selected = [...histogram].sort((a, b) => b[1] - a[1] || a[0] - b[0]).slice(0, 24).map(([index]) => index).sort((a, b) => a - b);
  rowPalettes.push(selected);
  for (let y = row * cellHeight; y < (row + 1) * cellHeight; y++) for (let x = 0; x < atlasWidth; x++) {
    const i = (y * atlasWidth + x) * 4; if (!sampled[i + 3]) continue;
    const choice = nearest(sampled[i], sampled[i + 1], sampled[i + 2], selected); final.set([...palette[choice], 255], i);
  }
}
function crc32(bytes) { let crc = 0xffffffff; for (const byte of bytes) { crc ^= byte; for (let bit = 0; bit < 8; bit++) crc = (crc >>> 1) ^ (crc & 1 ? 0xedb88320 : 0); } return (crc ^ 0xffffffff) >>> 0; }
function chunk(type, data) { const name = Buffer.from(type), size = Buffer.alloc(4), crc = Buffer.alloc(4); size.writeUInt32BE(data.length); crc.writeUInt32BE(crc32(Buffer.concat([name, data]))); return Buffer.concat([size, name, data, crc]); }
function writePNG(filename, w, h, rgba) {
  const header = Buffer.alloc(13); header.writeUInt32BE(w); header.writeUInt32BE(h, 4); header[8] = 8; header[9] = 6;
  const rows = Buffer.alloc(h * (w * 4 + 1)); for (let y = 0; y < h; y++) rgba.copy(rows, y * (w * 4 + 1) + 1, y * w * 4, (y + 1) * w * 4);
  const png = Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]), chunk('IHDR', header), chunk('IDAT', zlib.deflateSync(rows, { level: 9 })), chunk('IEND', Buffer.alloc(0))]);
  fs.mkdirSync(path.dirname(filename), { recursive: true }); fs.writeFileSync(filename, png); return { file: filename, sha256: sha(png), bytes: png.length, dimensions: [w, h] };
}
const outputRecord = writePNG(output, atlasWidth, atlasHeight, final);
// True2× pixel preview with a checker background, not another game asset.
const preview = Buffer.alloc(atlasWidth * 2 * atlasHeight * 2 * 4);
for (let y = 0; y < atlasHeight * 2; y++) for (let x = 0; x < atlasWidth * 2; x++) {
  const from = (Math.floor(y / 2) * atlasWidth + Math.floor(x / 2)) * 4, to = (y * atlasWidth * 2 + x) * 4;
  const gray = ((x >> 4) + (y >> 4)) % 2 ? 210 : 240; preview.set(final[from + 3] ? final.subarray(from, from + 4) : [gray, gray, gray, 255], to);
}
const previewRecord = writePNG(previewPath, atlasWidth * 2, atlasHeight * 2, preview);
const report = {
  schema: '755-liangzhu-actor-derivation-v1', source: { file: sourcePath, sha256: sourceSha, dimensions: [width, height], unchanged: fs.readFileSync(sourcePath).equals(sourceBytes) }, tool: { file: new URL(import.meta.url).pathname, sha256: sha(fs.readFileSync(new URL(import.meta.url))), node: process.version, decoder: ffmpeg },
  policy: { file: policyPath, sha256: sha(policyBytes), version: policy.version, profile: 'fineCharacter', nativeRaster: [120, 160], colorBudgetPerActorAcrossAllPoses: 24 },
  segmentation: { alphaThreshold: threshold, method: '8 complete major4-connected silhouettes, sorted left-to-right per source row; tiny nearby ornaments retained by alpha ownership', majorCount: 8, attachedSmallPixels, discardedSmallPixels, noColorKey: true, originalGridCrossing: 'Generated raised sleeves and misstep hems cross384px cells; full connected ownership preserves them instead of cropping on those boundaries.' },
  geometry: { atlas: [480, 320], cell: [120, 160], columns: 4, rows: 2, commonUniformScale: scale, sameScaleForAll8Poses: true, targetFoot, footDefinition: 'Mean source pixel-center X of each complete alpha silhouette bottom8rows, Y at bottom-pixel lower edge', maxSourceHeight: maxHeight, maxSourceWidth: maxWidth, maxLeftExtent: maxLeft, maxRightExtent: maxRight, limitingRule: 'min(140/maxHeight,116/maxWidth,58/maxLeftExtent,58/maxRightExtent), preserving2px side margin and all asymmetric sleeves', maxOutputHeight: maxHeight * scale, nonuniformStretch: false, elasticSnap: false, coarseUpscale: false },
  quantization: { method: 'Nearest locked RGB/no dither; each actor selects its top24 initial nearest-palette colors across all4poses, then all pose pixels are remapped to that fixed row palette', rowPalettes: rowPalettes.map(row => row.map(index => paletteHex[index])), alpha: [0, 255] },
  poses: poses.map(({ pixels, ...pose }) => pose), output: outputRecord, preview: { ...previewRecord, purpose: 'Actual2× nearest checker preview of final alpha; not a source/collision texture' },
  acceptance: { sourceViewed: true, alpha128PreviewViewed: true, noVisibleOpaqueBackgroundHaloAtThreshold: true, newAtlasActualViewPending: true, anonymity: 'Source is a newly generated two-performer sheet per art owner. Reference real photographs were not viewed or traced by this conversion task. Final generic illustrated faces still require visual review; no biometric likeness guarantee.', runtimeAndVideo: 'No engine import, active performance, source-photo comparison or movie acceptance from this derivation alone.' }
};
fs.mkdirSync(path.dirname(reportPath), { recursive: true }); fs.writeFileSync(reportPath, JSON.stringify(report, null, 2) + '\n');
console.log(JSON.stringify({ output: outputRecord, preview: previewRecord, commonScale: scale, maxOutputHeight: maxHeight * scale, rowColors: rowPalettes.map(row => row.length), attachedSmallPixels, discardedSmallPixels, receipt: reportPath }, null, 2));
