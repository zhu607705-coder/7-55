#!/usr/bin/env node
// Deterministic stage derivation: one uniform affine nearest sample, then an
// exact locked-palette nearest-RGB lookup. No elastic cuts, dithering or blur.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import zlib from 'node:zlib';
import { spawnSync } from 'node:child_process';

const args = process.argv.slice(2), inputs = args.filter(value => !value.startsWith('--'));
const option = (key, fallback) => args.find(value => value.startsWith(`--${key}=`))?.slice(key.length + 3) ?? fallback;
if (inputs.length !== 2 || !option('receipt') || !option('comparison')) throw new Error('Usage: prepare_liangzhu_stage.mjs <source.png> <stage.png> --receipt=<json> --comparison=<png> [--source-sha=<sha256>]');
const input = path.resolve(inputs[0]), output = path.resolve(inputs[1]);
const receiptPath = path.resolve(option('receipt')), comparisonPath = path.resolve(option('comparison'));
const policyPath = path.resolve(option('policy', new URL('../docs/art/art_direction_v1.json', import.meta.url).pathname));
if (new Set([input, output, receiptPath, comparisonPath, policyPath]).size !== 5) throw new Error('Source, output, report, comparison and policy must be separate files');
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const sourceBytes = fs.readFileSync(input), sourceSha = sha(sourceBytes);
if (option('source-sha') && option('source-sha') !== sourceSha) throw new Error('Input source SHA differs from the approved master');
if (!sourceBytes.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10])) || sourceBytes.toString('ascii', 12, 16) !== 'IHDR') throw new Error('Source must be PNG');
const width = sourceBytes.readUInt32BE(16), height = sourceBytes.readUInt32BE(20);
if (!width || !height || width * height > 4194304) throw new Error('Source exceeds the4M-pixel conversion budget');
const policyBytes = fs.readFileSync(policyPath), policy = JSON.parse(policyBytes), profile = policy.profiles.fineStage;
const [destWidth, destHeight] = profile.nativeRaster;
if (destWidth !== 1200 || destHeight !== 675 || profile.colorBudget !== 32) throw new Error('Fine-stage contract must be1200×675 with a32-color budget');
const paletteHex = policy.palette.colors, palette = paletteHex.map(value => [...Buffer.from(value, 'hex')]);
if (new Set(paletteHex).size !== 32 || palette.some(rgb => rgb.length !== 3)) throw new Error('Expected32 distinct locked RGB colors');
const materialAware = args.includes('--material-aware');
const materialColors = {
  wood: [...policy.palette.ramps.wood, 'D8C7A0', 'F4EAD5', 'FFF0B2'],
  cool: [...policy.palette.ramps.inkMetal, ...policy.palette.ramps.blueFabricWater, ...policy.palette.ramps.plasterStone],
  curtain: ['44332D', '70503B', '6F483E', 'A76A4C', '9A514A', 'C77964', 'D89C6A', 'D3A451', 'F4CD77']
};
const materialIndexes = Object.fromEntries(Object.entries(materialColors).map(([role, values]) => [role, values.map(value => {
  const index = paletteHex.indexOf(value); if (index < 0) throw new Error('Material color is outside the locked policy'); return index;
})]));
const materialCounts = { wood: 0, cool: 0, curtain: 0, unrestricted: 0 };
const ffmpeg = process.env.FFMPEG_BIN || 'ffmpeg';
const decoded = spawnSync(ffmpeg, ['-hide_banner', '-loglevel', 'error', '-i', input, '-f', 'rawvideo', '-pix_fmt', 'rgba', '-frames:v', '1', 'pipe:1'], { maxBuffer: width * height * 4 + 1048576 });
if (decoded.error || decoded.status !== 0 || decoded.stdout?.length !== width * height * 4) throw new Error(`Cannot decode master: ${decoded.error || decoded.stderr}`);
const original = decoded.stdout;
for (let i = 3; i < original.length; i += 4) if (original[i] !== 255) throw new Error('Stage master must be fully opaque; alpha cannot be silently flattened');

// sourceX/Y are evaluated using the SAME exact rational scale. A centered
// source extent can end at a subpixel boundary; no separately rounded axis.
const widthLimited = destWidth * height >= destHeight * width;
const gcd = (a, b) => b ? gcd(b, a % b) : a;
const divisor = gcd(widthLimited ? destWidth : destHeight, widthLimited ? width : height);
const numerator = (widthLimited ? destWidth : destHeight) / divisor;
const denominator = (widthLimited ? width : height) / divisor;
const xMargin = width * numerator - destWidth * denominator;
const yMargin = height * numerator - destHeight * denominator;
const sampled = Buffer.alloc(destWidth * destHeight * 4), final = Buffer.alloc(sampled.length);
const colorCache = new Map(), sourceColors = new Set(), outputColors = new Set();
const squaredErrors = []; let sumSquaredError = 0;
for (let y = 0; y < destHeight; y++) for (let x = 0; x < destWidth; x++) {
  const sourceX = Math.floor((xMargin + (2 * x + 1) * denominator) / (2 * numerator));
  const sourceY = Math.floor((yMargin + (2 * y + 1) * denominator) / (2 * numerator));
  if (sourceX < 0 || sourceX >= width || sourceY < 0 || sourceY >= height) throw new Error('Uniform sample left the source');
  const from = (sourceY * width + sourceX) * 4, to = (y * destWidth + x) * 4;
  original.copy(sampled, to, from, from + 4);
  const key = original.readUIntBE(from, 3); sourceColors.add(key);
  const [r, g, b] = original.subarray(from, from + 3);
  // Regions classify the existing photographed material only. They do not
  // translate an object, alter the stage projection or affect any collision.
  const backdrop = x >= 215 && x < 985 && y < 252;
  const curtain = (x < 218 || x >= 982) && y < 422 && r - g >= 20 && r - g >= (g - b) * 1.6;
  const warmWood = r - g >= 6 && g - b >= 4;
  const role = !materialAware ? 'unrestricted' : backdrop ? 'cool' : curtain ? 'curtain' : warmWood ? 'wood' : 'cool';
  materialCounts[role]++;
  const cacheKey = `${role}:${key}`;
  let choice = colorCache.get(cacheKey);
  if (choice === undefined) {
    let best = Infinity;
    for (const index of materialAware ? materialIndexes[role] : palette.keys()) {
      const rgb = palette[index], distance = rgb.reduce((sum, value, channel) => sum + (value - original[from + channel]) ** 2, 0);
      if (distance < best) { best = distance; choice = index; }
    }
    colorCache.set(cacheKey, choice);
  }
  const rgb = palette[choice]; final.set([...rgb, 255], to); outputColors.add(choice);
  const error = rgb.reduce((sum, value, channel) => sum + (value - original[from + channel]) ** 2, 0);
  sumSquaredError += error; squaredErrors.push(error);
}
function crc32(bytes) {
  let crc = 0xffffffff;
  for (const byte of bytes) { crc ^= byte; for (let bit = 0; bit < 8; bit++) crc = (crc >>> 1) ^ (crc & 1 ? 0xedb88320 : 0); }
  return (crc ^ 0xffffffff) >>> 0;
}
function chunk(type, data) {
  const name = Buffer.from(type), size = Buffer.alloc(4), crc = Buffer.alloc(4);
  size.writeUInt32BE(data.length); crc.writeUInt32BE(crc32(Buffer.concat([name, data])));
  return Buffer.concat([size, name, data, crc]);
}
function writePNG(filename, w, h, rgba) {
  const header = Buffer.alloc(13); header.writeUInt32BE(w); header.writeUInt32BE(h, 4); header[8] = 8; header[9] = 6;
  const rows = Buffer.alloc(h * (1 + w * 4));
  for (let y = 0; y < h; y++) rgba.copy(rows, y * (1 + w * 4) + 1, y * w * 4, (y + 1) * w * 4);
  const png = Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]), chunk('IHDR', header), chunk('IDAT', zlib.deflateSync(rows, { level: 9 })), chunk('IEND', Buffer.alloc(0))]);
  fs.mkdirSync(path.dirname(filename), { recursive: true }); fs.writeFileSync(filename, png);
  return { file: filename, bytes: png.length, sha256: sha(png), dimensions: [w, h] };
}
const detailRegions = [
  { name: 'left-curtain-embroidery', rect: [70, 125, 160, 160] },
  { name: 'backdrop-branches', rect: [350, 55, 160, 160] },
  { name: 'wood-floor-grain', rect: [430, 390, 160, 160] }
];
const comparisonWidth = 640, comparisonHeight = 960, comparison = Buffer.alloc(comparisonWidth * comparisonHeight * 4);
for (let row = 0; row < detailRegions.length; row++) {
  const [left, top, w, h] = detailRegions[row].rect;
  for (let side = 0; side < 2; side++) for (let y = 0; y < h * 2; y++) for (let x = 0; x < w * 2; x++) {
    const source = side === 0 ? sampled : final, from = ((top + Math.floor(y / 2)) * destWidth + left + Math.floor(x / 2)) * 4;
    source.copy(comparison, ((row * h * 2 + y) * comparisonWidth + side * w * 2 + x) * 4, from, from + 4);
  }
}
let nonuniform5pxBlocks = 0;
for (let y = 0; y < destHeight; y += 5) for (let x = 0; x < destWidth; x += 5) {
  const first = (y * destWidth + x) * 4; let different = false;
  for (let dy = 0; !different && dy < 5; dy++) for (let dx = 0; dx < 5; dx++) {
    const offset = ((y + dy) * destWidth + x + dx) * 4;
    if (!final.subarray(first, first + 3).equals(final.subarray(offset, offset + 3))) { different = true; break; }
  }
  if (different) nonuniform5pxBlocks++;
}
const transitions = raw => {
  let horizontal = 0, vertical = 0;
  for (let y = 0; y < destHeight; y++) for (let x = 0; x < destWidth; x++) {
    const i = (y * destWidth + x) * 4;
    if (x && raw.readUIntBE(i, 3) !== raw.readUIntBE(i - 4, 3)) horizontal++;
    if (y && raw.readUIntBE(i, 3) !== raw.readUIntBE(i - destWidth * 4, 3)) vertical++;
  }
  return { horizontal, vertical };
};
const outputRecord = writePNG(output, destWidth, destHeight, final);
const comparisonRecord = writePNG(comparisonPath, comparisonWidth, comparisonHeight, comparison);
squaredErrors.sort((a, b) => a - b);
const receipt = {
  schema: '755-liangzhu-stage-derivation-v1', source: { file: input, bytes: sourceBytes.length, sha256: sourceSha, dimensions: [width, height] },
  tool: { file: new URL(import.meta.url).pathname, sha256: sha(fs.readFileSync(new URL(import.meta.url))), nodeVersion: process.version, decoder: ffmpeg },
  policy: { file: policyPath, sha256: sha(policyBytes), version: policy.version, profile: 'fineStage', palette: paletteHex },
  uniformTransform: { operation: 'centered uniform cover with direct nearest source-pixel sampling', scale: numerator / denominator, exactScaleFraction: [numerator, denominator], sourceExtent: [xMargin / (2 * numerator), yMargin / (2 * numerator), destWidth * denominator / numerator, destHeight * denominator / numerator], sampleFormula: 'floor((sourceDimension*numerator-destinationDimension*denominator+(2*destinationPixel+1)*denominator)/(2*numerator))', equalScaleOnBothAxes: true, nonuniformResize: false, intermediateLowResolutionRaster: false, elasticGridDetection: false },
  quantization: { method: materialAware ? 'nearest locked RGB within the declared material subset, integer squared Euclidean sRGB-byte distance; ties select first subset entry' : 'nearest locked RGB by integer squared Euclidean distance in stored sRGB bytes; ties select first policy entry', dither: false, alpha: 255, materialAware, materialCounts, materialColors: materialAware ? materialColors : null, materialClassification: materialAware ? { priority: ['centralBackdrop', 'sideCurtainRGB', 'warmWoodRGB', 'coolDefault'], centralBackdrop: 'x>=215 && x<985 && y<252 in1200×675 output coordinates', sideCurtainRGB: '(x<218 || x>=982) && y<422 && r-g>=20 && r-g>=(g-b)*1.6', warmWoodRGB: 'r-g>=6 && g-b>=4', coolDefault: 'All remaining pixels; plant palette forbidden throughout this stage', boundary: 'Classification changes color selection only; original uniform sampled source and object positions are unchanged.' } : null, sampledVisibleColors: sourceColors.size, outputVisibleColors: outputColors.size, rootMeanSquaredErrorPerRGBChannel: Math.sqrt(sumSquaredError / (destWidth * destHeight * 3)), p95EuclideanRGBDistance: Math.sqrt(squaredErrors[Math.floor(squaredErrors.length * 0.95)]) },
  fineDetailDiagnostics: { transitionsBeforePalette: transitions(sampled), transitionsAfterPalette: transitions(final), nonuniform5pxBlocks, total5pxBlocks: destWidth * destHeight / 25, meaning: 'Nonuniform5px blocks rule out a constant240×135 raster enlarged5× at origin0,0; transition counts show quantization merges. These statistics alone do not approve anatomy, authored pixel clusters, lighting or visual quality.' },
  output: outputRecord, comparison: { ...comparisonRecord, rows: detailRegions, columns: ['uniform sampled original colors', 'final fixed32-color output'], displayScale: 2, pixelResampling: 'nearest only' },
  sourceUnchanged: fs.readFileSync(input).equals(sourceBytes), artisticAcceptance: 'Pending actual final stage and detail comparison view; no actor, performance, engine import or video acceptance claimed.'
};
fs.mkdirSync(path.dirname(receiptPath), { recursive: true }); fs.writeFileSync(receiptPath, JSON.stringify(receipt, null, 2) + '\n');
console.log(JSON.stringify({ output: outputRecord, comparison: comparisonRecord, receipt: receiptPath, fineDetailDiagnostics: receipt.fineDetailDiagnostics, sourceUnchanged: receipt.sourceUnchanged }, null, 2));
