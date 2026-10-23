#!/usr/bin/env node
// Self-authored raster fixtures only. These checks exercise the audit contract,
// not artistic quality, source placement or actual generated performance art.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import zlib from 'node:zlib';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const audit = fileURLToPath(new URL('./audit_pixel_art.mjs', import.meta.url));
const policyPath = fileURLToPath(new URL('../docs/art/art_direction_v1.json', import.meta.url));
const policyBytes = fs.readFileSync(policyPath), policy = JSON.parse(policyBytes);
const work = fs.mkdtempSync(path.join(os.tmpdir(), '755-pixel-audit-'));
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const files = [], cases = [];
const colors = policy.palette.colors.map(value => [...Buffer.from(value, 'hex'), 255]);

function crc32(bytes) {
  let crc = 0xffffffff;
  for (const value of bytes) {
    crc ^= value;
    for (let bit = 0; bit < 8; bit++) crc = (crc >>> 1) ^ (crc & 1 ? 0xedb88320 : 0);
  }
  return (crc ^ 0xffffffff) >>> 0;
}
function chunk(type, data) {
  const name = Buffer.from(type), size = Buffer.alloc(4), crc = Buffer.alloc(4);
  size.writeUInt32BE(data.length); crc.writeUInt32BE(crc32(Buffer.concat([name, data])));
  return Buffer.concat([size, name, data, crc]);
}
function png(name, width, height, pixel) {
  const header = Buffer.alloc(13); header.writeUInt32BE(width); header.writeUInt32BE(height, 4); header[8] = 8; header[9] = 6;
  const raw = Buffer.alloc(height * (1 + width * 4));
  for (let y = 0; y < height; y++) for (let x = 0; x < width; x++) raw.set(pixel(x, y), y * (1 + width * 4) + 1 + x * 4);
  const filename = path.join(work, name), bytes = Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]), chunk('IHDR', header), chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]);
  fs.writeFileSync(filename, bytes); files.push({ filename, sha256: sha(bytes) }); return filename;
}
function run(label, input, profile, scale = 1, expectedStatus = 0, extra = []) {
  const result = spawnSync(process.execPath, [audit, input, `--profile=${profile}`, `--scale=${scale}`, '--strict', '--verbose', ...extra], { encoding: 'utf8', timeout: 30000, maxBuffer: 1024 * 1024 });
  assert.ifError(result.error); assert.equal(result.status, expectedStatus, `${label}: ${result.stderr || result.stdout}`);
  const report = JSON.parse(result.stdout); assert.equal(report.files.length, 1); cases.push({ label, passed: true }); return report;
}

try {
  assert.deepEqual(policy.profiles.fineCharacter.nativeRaster, [120, 160]);
  assert.deepEqual(policy.profiles.fineStage.nativeRaster, [1200, 675]);
  assert.equal(policy.profiles.fineCharacter.colorBudget, 24);
  assert.equal(policy.profiles.fineStage.colorBudget, 32);

  const fine = png('fine-character-24.png', 120, 160, (x, y) => colors[(x + y) % 24]);
  const accepted = run('Native fine character accepts24 palette colors without uniform5px blocks', fine, 'fineCharacter');
  assert.equal(accepted.colorBudget, 24); assert.equal(accepted.dimensionBasis, 'nativeRaster');
  assert.deepEqual(accepted.expectedSourceDimensions, [120, 160]);
  assert.equal(accepted.files[0].logicalDimensions, null);
  assert.deepEqual(accepted.files[0].expectedLogicalDimensions, [24, 32]);
  assert.equal(accepted.files[0].visibleColors, 24);
  assert.equal(accepted.files[0].nonuniformBlocks, 0);
  assert.ok(accepted.limitations.some(text => text.includes('not evidence of coherent authored pixel clusters')));

  const excess = run('A25th locked color violates the fine-character budget', png('fine-character-25.png', 120, 160, (x, y) => colors[(x + y) % 25]), 'fineCharacter', 1, 1);
  assert.equal(excess.files[0].checks.colorBudget, false); assert.equal(excess.files[0].checks.lockedPaletteOnly, true);

  const outside = run('One off-palette native pixel fails independently of dimensions and budget', png('off-palette.png', 120, 160, (x, y) => x === 0 && y === 0 ? [1,2,3,255] : colors[0]), 'fineCharacter', 1, 1);
  assert.equal(outside.files[0].outsidePaletteColorCount, 1);
  assert.equal(outside.files[0].checks.lockedPaletteOnly, false); assert.equal(outside.files[0].checks.dimensions, true); assert.equal(outside.files[0].checks.colorBudget, true);

  const wrong = run('One missing source column fails exact native dimensions', png('wrong-dimension.png', 119, 160, () => colors[0]), 'fineCharacter', 1, 1);
  assert.equal(wrong.files[0].checks.dimensions, false); assert.equal(wrong.files[0].checks.lockedPaletteOnly, true);

  const scaled = run('nativeRaster size is not multiplied by a declared block-inspection scale', fine, 'fineCharacter', 2, 1);
  assert.equal(scaled.files[0].checks.dimensions, true); assert.equal(scaled.files[0].checks.declaredGridBlocksUniform, false);

  const stage = run('Fine stage accepts1200×675 native source and32 colors', png('fine-stage.png', 1200, 675, (x, y) => colors[(x + y) % 32]), 'fineStage');
  assert.equal(stage.files[0].visibleColors, 32); assert.deepEqual(stage.files[0].expectedSourceDimensions, [1200, 675]);

  const legacy = png('legacy-character.png', 96, 128, (x, y) => colors[(Math.floor(x / 4) + Math.floor(y / 4)) % 12]);
  const legacyAccepted = run('Legacy character scale4 retains96×128/12-color uniform-block contract', legacy, 'character', 4);
  assert.equal(legacyAccepted.colorBudget, 12); assert.equal(legacyAccepted.dimensionBasis, 'logical-times-declared-scale');
  assert.deepEqual(legacyAccepted.files[0].logicalDimensions, [24, 32]);
  const brokenLegacy = run('One changed legacy pixel still fails the declared4px block test', png('legacy-broken-block.png', 96, 128, (x, y) => x === 0 && y === 0 ? colors[1] : colors[0]), 'character', 4, 1);
  assert.equal(brokenLegacy.files[0].checks.dimensions, true); assert.equal(brokenLegacy.files[0].checks.declaredGridBlocksUniform, false);

  const effect = run('Legacy effect retains its four-color budget fallback', png('effect-five-colors.png', 16, 16, (x, y) => colors[(x + y) % 5]), 'effect', 1, 1);
  assert.equal(effect.colorBudget, 4); assert.equal(effect.files[0].checks.colorBudget, false);

  for (const file of files) assert.equal(sha(fs.readFileSync(file.filename)), file.sha256, 'Read-only audit must preserve every input fixture');
  assert.deepEqual(fs.readFileSync(policyPath), policyBytes, 'Test must not mutate the active policy');
  console.log(JSON.stringify({ schema: '755-pixel-art-audit-tests-v1', passed: true, cases, checks: { fixtureBytesUnchanged: files.length, activePolicyUnchanged: true }, scope: 'Synthetic dimensions, palette budgets and declared grid contract; no generated artwork or visual acceptance.' }, null, 2));
} finally {
  fs.rmSync(work, { recursive: true, force: true });
}
