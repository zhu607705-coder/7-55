import { readFile, writeFile, mkdir, rm, rename, mkdtemp } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { readStaticConstants, validateSpatialManifest } from './lib/static-ts-data.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
const read = relative => readFile(path.join(root, relative), 'utf8');
const modelPath = 'src/scenes/rpg/TheaterInteriorModel.ts';
const playerPath = 'src/scenes/rpg/RpgPlayerTextures.ts';
const portPath = 'src/scenes/rpg/TheaterRuntimeContract.ts';
const sources = await Promise.all([modelPath, playerPath, portPath].map(read));
const m = readStaticConstants(sources[0], ['THEATER_INTERIOR_WORLD', 'THEATER_STATIC_COLLISION_RECTS', 'THEATER_OCCLUSION_RECTS', 'THEATER_LOBBY_SPAWN', 'THEATER_AUDITORIUM_SPAWN', 'THEATER_STAGE_SPAWN', 'THEATER_GATE_BLOCKER'], modelPath);
const p = readStaticConstants(sources[1], ['RPG_PLAYER_FRAME_WIDTH', 'RPG_PLAYER_FRAME_HEIGHT', 'RPG_PLAYER_DISPLAY_SCALE', 'RPG_PLAYER_WALK_FRAME_MS', 'RPG_PLAYER_WALK_FRAME_COUNT', 'RPG_PLAYER_FOOT_COLLISION'], playerPath);
const c = readStaticConstants(sources[2], ['THEATER_RUNTIME_LOGICAL_VIEWPORT', 'THEATER_RUNTIME_CONTRACT_VERSION'], portPath);
const data = validateSpatialManifest({
  schemaVersion: 1,
  scope: 'spatial-parity-slice-no-story-authority',
  sourceContract: c.THEATER_RUNTIME_CONTRACT_VERSION,
  viewport: c.THEATER_RUNTIME_LOGICAL_VIEWPORT,
  world: m.THEATER_INTERIOR_WORLD,
  collisions: [...m.THEATER_STATIC_COLLISION_RECTS, {id: 'admission_gate', ...m.THEATER_GATE_BLOCKER}],
  occlusion: m.THEATER_OCCLUSION_RECTS,
  spawns: {lobby: m.THEATER_LOBBY_SPAWN, auditorium: m.THEATER_AUDITORIUM_SPAWN, stage: m.THEATER_STAGE_SPAWN},
  player: {width: p.RPG_PLAYER_FRAME_WIDTH, height: p.RPG_PLAYER_FRAME_HEIGHT, scale: p.RPG_PLAYER_DISPLAY_SCALE,
    frameMs: p.RPG_PLAYER_WALK_FRAME_MS, frameCount: p.RPG_PLAYER_WALK_FRAME_COUNT, foot: p.RPG_PLAYER_FOOT_COLLISION},
  sourceHashes: Object.fromEntries([modelPath, playerPath, portPath].map((name, i) => [name, createHash('sha256').update(sources[i]).digest('hex')])),
  assets: []
});
const dest = path.join(root, 'godot-port/generated');
await mkdir(path.dirname(dest), {recursive: true});
const temp = await mkdtemp(path.join(root, 'godot-port/.generated-'));
const assets = [['src/assets/rpg/interiors/theater_interior.png', 'theater.png', data.world.width, data.world.height]];
for (const direction of ['down', 'up', 'side']) {
  for (let i = 0; i < data.player.frameCount; i++) assets.push([`src/assets/rpg/player/player_${direction}_${i}.png`, `player_${direction}_${i}.png`, data.player.width, data.player.height]);
}
assets.push(['src/assets/rpg/player/player_side_idle.png', 'player_side_idle.png', data.player.width, data.player.height]);
try {
  for (const [source, target, width, height] of assets) {
    const bytes = await readFile(path.join(root, source));
    if (bytes.length < 24 || bytes.subarray(0, 8).toString('hex') !== '89504e470d0a1a0a'
      || bytes.toString('ascii', 12, 16) !== 'IHDR' || bytes.readUInt32BE(16) !== width || bytes.readUInt32BE(20) !== height) throw new Error(`Asset missing/incorrect dimensions (or LFS pointer): ${source}`);
    await writeFile(path.join(temp, target), bytes);
    data.assets.push({source, target, width, height, bytes: bytes.length, decodedBytes: width * height * 4, sha256: createHash('sha256').update(bytes).digest('hex')});
  }
  await writeFile(path.join(temp, 'theater.json'), JSON.stringify(data, null, 2) + '\n');
  // Only this generated, gitignored directory is replaced. Source assets are untouched.
  await rm(dest, {recursive: true, force: true});
  await rename(temp, dest);
  console.log(`Exported ${assets.length} checked assets, ${data.collisions.length} colliders, ${data.occlusion.length} source-pixel occlusion regions.`);
} finally { await rm(temp, {recursive: true, force: true}); }
