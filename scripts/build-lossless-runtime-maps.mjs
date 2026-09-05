import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readFileSync, writeFileSync, readdirSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const output = 'src/assets/rpg/optimized';
const chapter = 'src/assets/rpg/interiors/finale/chapter4-755';
const sources = [
  ...['zijingang_campus_plate', 'zijingang_campus_loop_panorama'].map(n => `src/assets/rpg/campus/${n}.png`),
  ...['dorm_hub', 'library_interior', 'canteen_interior', 'theater_interior',
    'qizhen_lake_dock', 'qizhen_lake_dock_no_sign', 'qizhen_lake_open_water',
    'qizhen_lake_channel', 'qizhen_lake_swan_cove'].map(n => `src/assets/rpg/interiors/${n}.png`),
  ...['base', 'states'].flatMap(dir => readdirSync(path.join(root, chapter, dir))
    .filter(n => n.endsWith('.png')).sort().map(n => `${chapter}/${dir}/${n}`))
];
const hash = data => createHash('sha256').update(data).digest('hex');
const assets = [];
for (const source of sources) {
  const file = `${output}/${source.slice('src/assets/rpg/'.length).replaceAll('/', '__').replace(/\.png$/, '.webp')}`;
  execFileSync('cwebp', ['-quiet', '-lossless', '-exact', '-m', '4', path.join(root, source), '-o', path.join(root, file)]);
  const before = readFileSync(path.join(root, source));
  const after = readFileSync(path.join(root, file));
  if (after.length >= before.length) throw new Error(`Derivative does not reduce size: ${source}`);
  assets.push({source, file, sourceSha256:hash(before), sha256:hash(after), sourceBytes:before.length, bytes:after.length});
  console.log(`${source}: ${before.length} -> ${after.length}`);
}
writeFileSync(path.join(root, output, 'manifest.json'), JSON.stringify({schema:1, encoding:'webp-lossless-exact', assets}, null, 2)+'\n');
console.log(JSON.stringify({count:assets.length, sourceBytes:assets.reduce((n,a)=>n+a.sourceBytes,0), bytes:assets.reduce((n,a)=>n+a.bytes,0)}));
