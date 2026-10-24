#!/usr/bin/env node
// Read-only, dependency-light raster acceptance. Grid tests validate declared
// integer enlargement; they do not infer authorship, perspective or collisions.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';

const args = process.argv.slice(2);
const option = (key, fallback) => args.find(arg => arg.startsWith(`--${key}=`))?.slice(key.length + 3) ?? fallback;
const files = args.filter(arg => !arg.startsWith('--'));
if (!files.length) throw new Error('Usage: audit_pixel_art.mjs <PNG>... --profile=<policy profile> --scale=1|4 [--strict] [--output=report.json]');
const policyPath = path.resolve(option('policy', new URL('../docs/art/art_direction_v1.json', import.meta.url).pathname));
const policyBytes = fs.readFileSync(policyPath), policy = JSON.parse(policyBytes);
const profileName = option('profile', 'environment'), profile = policy.profiles[profileName];
const scale = Number(option('scale', '1'));
if (!profile || !Number.isSafeInteger(scale) || scale < 1 || scale > 16) throw new Error('Unknown profile or invalid integer source scale');
const expectedLayout = profile.logicalFrame || profile.logicalCanvas;
const nativeRaster = profile.nativeRaster;
if (nativeRaster !== undefined && (!Array.isArray(nativeRaster) || nativeRaster.length !== 2 || nativeRaster.some(value => !Number.isSafeInteger(value) || value < 1))) throw new Error('Profile nativeRaster must contain two positive integer dimensions');
const expectedSource = nativeRaster || expectedLayout?.map(value => value * scale);
const colorBudget = profile.colorBudget ?? profile.colorsPerEffectMax ?? (['character','itemIcon','uiIcon'].includes(profileName) ? policy.palette.spriteColorBudget : policy.palette.worldColorBudget);
if (!Number.isSafeInteger(colorBudget) || colorBudget < 1 || colorBudget > 32) throw new Error('Profile color budget must be an integer from1 to32');
const palette = new Set(policy.palette.colors.map(color => color.toUpperCase()));
if (palette.size !== 32 || [...palette].some(color => !/^[0-9A-F]{6}$/.test(color))) throw new Error('Art policy must contain32 distinct six-digit colors');
for (const ramp of Object.values(policy.palette.ramps)) if (ramp.some(color => !palette.has(color))) throw new Error('Material ramp references an unlocked color');
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const ffmpeg = process.env.FFMPEG_BIN || 'ffmpeg';
const report = { schema: '755-pixel-art-audit-v1', policySha256: sha(policyBytes), policyVersion: policy.version, profile: profileName, declaredSourceScale: scale, dimensionBasis: nativeRaster ? 'nativeRaster' : 'logical-times-declared-scale', expectedSourceDimensions: expectedSource || null, colorBudget, files: [], limitations: ['A one-pixel raster grid is not evidence of coherent authored pixel clusters.', 'Palette/grid checks cannot approve perspective, proportions, camera, source placement, alpha silhouette quality or collision.', 'Legacy inputs are diagnostic; they are never overwritten.'] };
for (const input of files) {
  const filename = path.resolve(input), bytes = fs.readFileSync(filename);
  if (!bytes.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10])) || bytes.toString('ascii',12,16) !== 'IHDR') throw new Error(`PNG input required: ${input}`);
  const width = bytes.readUInt32BE(16), height = bytes.readUInt32BE(20);
  if (!width || !height || width * height > 4194304) throw new Error(`Raster exceeds4M-pixel inspection budget: ${input}`);
  const decoded = spawnSync(ffmpeg, ['-hide_banner', '-loglevel', 'error', '-i', filename, '-f', 'rawvideo', '-pix_fmt', 'rgba', '-frames:v', '1', 'pipe:1'], { maxBuffer: width * height * 4 + 1048576 });
  if (decoded.error || decoded.status !== 0 || decoded.stdout?.length !== width * height * 4) throw new Error(`Cannot decode ${input}: ${decoded.error || decoded.stderr}`);
  const raw = decoded.stdout, colors = new Map(), alpha = new Map(), outside = new Map();
  let nonuniformBlocks = 0, blocks = 0;
  const alphaAllowed = profile.alpha || policy.palette.sourceAlpha;
  for (let i = 0; i < raw.length; i += 4) {
    const a = raw[i+3]; alpha.set(a, (alpha.get(a) || 0) + 1);
    if (!a) continue;
    const rgb = raw.subarray(i, i+3).toString('hex').toUpperCase();
    colors.set(rgb, (colors.get(rgb) || 0) + 1);
    if (!palette.has(rgb)) outside.set(rgb, (outside.get(rgb) || 0) + 1);
  }
  for (let y = 0; y < height; y += scale) for (let x = 0; x < width; x += scale) {
    blocks++; const first = (y * width + x) * 4; let same = true;
    for (let dy = 0; same && dy < Math.min(scale, height-y); dy++) for (let dx = 0; dx < Math.min(scale,width-x); dx++) {
      const i = ((y+dy)*width+x+dx)*4;
      // Hidden RGB beneath fully transparent pixels has no visual meaning.
      if (raw[i+3] !== raw[first+3] || (raw[i+3] && (raw[i] !== raw[first] || raw[i+1] !== raw[first+1] || raw[i+2] !== raw[first+2]))) { same = false; break; }
    }
    if (!same) nonuniformBlocks++;
  }
  const checks = {
    dimensions: !expectedSource || (width === expectedSource[0] && height === expectedSource[1]),
    colorBudget: colors.size <= colorBudget,
    integerSourceDimensions: width % scale === 0 && height % scale === 0,
    declaredGridBlocksUniform: nonuniformBlocks === 0,
    lockedPaletteOnly: outside.size === 0,
    alphaPolicy: [...alpha.keys()].every(value => alphaAllowed.includes(value))
  };
  report.files.push({ path: filename, bytes: bytes.length, sha256: sha(bytes), dimensions: [width,height], logicalDimensions: nativeRaster ? null : [width/scale,height/scale], expectedLogicalDimensions: expectedLayout || null, expectedSourceDimensions: expectedSource || null, visibleColors: colors.size, nonuniformBlocks, inspectedBlocks: blocks, alphaHistogram: Object.fromEntries([...alpha].sort((a,b)=>a[0]-b[0])), outsidePaletteColorCount: outside.size, outsidePaletteTop: [...outside].sort((a,b)=>b[1]-a[1]).slice(0,8), checks, passed: Object.values(checks).every(Boolean) });
}
report.passed = report.files.every(file => file.passed);
if (option('output')) { const target=path.resolve(option('output')); fs.mkdirSync(path.dirname(target),{recursive:true}); fs.writeFileSync(target,JSON.stringify(report,null,2)+'\n'); }
console.log(JSON.stringify(args.includes('--verbose') ? report : {schema:report.schema,profile:profileName,policySha256:report.policySha256,passed:report.passed,files:report.files.map(({path,dimensions,visibleColors,nonuniformBlocks,inspectedBlocks,outsidePaletteColorCount,checks,passed})=>({path,dimensions,visibleColors,nonuniformBlocks,inspectedBlocks,outsidePaletteColorCount,checks,passed}))},null,2));
if (args.includes('--strict') && !report.passed) process.exitCode = 1;
