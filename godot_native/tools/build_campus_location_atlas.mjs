import { spawnSync } from 'node:child_process';
import { mkdtempSync, readFileSync, renameSync, rmSync } from 'node:fs';
import path from 'node:path';

const project = path.resolve(import.meta.dirname, '..');
const source = path.resolve(project, '../src/assets/rpg/campus/zijingang_campus_plate.png');
const atlas = path.join(project, 'assets/native/library_geometry/campus_location_atlas.webp');
const ffmpeg = process.env.FFMPEG_BIN || 'ffmpeg';
const [argument, ...extra] = process.argv.slice(2);
if (extra.length || ![undefined, '--check'].includes(argument)) throw Error('Usage: node godot_native/tools/build_campus_location_atlas.mjs [--check]');

// The source-aligned map window is 1850×1500 at (2240, 360). The tower
// window is inside it. The one-pixel border preserves edge filter samples.
const width = 1852;
const height = 1502;
const crop = `format=rgba,crop=${width}:${height}:2239:359:exact=1`;

function run(input, args) {
  const result = spawnSync(ffmpeg, ['-nostdin', '-v', 'error', '-i', input, '-frames:v', '1', ...args], { maxBuffer: 16 * 1024 * 1024 });
  if (result.error || result.status !== 0) throw Error(`Could not process ${input}: ${result.error || result.stderr.toString().trim()}`);
  return result.stdout;
}

function pixelBytes(input, filter = []) {
  return run(input, [...filter, '-pix_fmt', 'rgba', '-f', 'rawvideo', '-']);
}

function verify(filename) {
  const sourcePixels = pixelBytes(source, ['-vf', crop]);
  const actualPixels = pixelBytes(filename);
  const header = readFileSync(filename);
  // FFmpeg's rawvideo stream carries no dimensions. Require the same source
  // geometry via its lossless VP8L header before comparing decoded pixels.
  const size = header.length >= 25 ? header.readUInt32LE(21) : 0;
  if (header.toString('ascii', 8, 16) !== 'WEBPVP8L' || header[20] !== 0x2f || (size & 0x3fff) + 1 !== width || ((size >>> 14) & 0x3fff) + 1 !== height || !actualPixels.equals(sourcePixels)) {
    throw Error('Library campus atlas must reproduce the exact RGBA pixels and dimensions of its source crop');
  }
  console.log(`Library campus atlas matches ${width}×${height} source pixels exactly (${header.length} bytes)`);
}

if (argument === '--check') {
  verify(atlas);
} else {
  const scratch = mkdtempSync(path.join(path.dirname(atlas), '.campus-atlas-'));
  try {
    const candidate = path.join(scratch, 'atlas.webp');
    run(source, ['-vf', crop, '-c:v', 'libwebp', '-pix_fmt', 'bgra', '-lossless', '1', '-compression_level', '6', candidate]);
    verify(candidate);
    renameSync(candidate, atlas);
  } finally {
    rmSync(scratch, { recursive: true, force: true });
  }
}
