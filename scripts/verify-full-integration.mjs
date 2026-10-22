import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
const root=path.resolve(import.meta.dirname,'..');
const manifest=JSON.parse(fs.readFileSync(path.join(root,'godot_native/docs/FULL_INTEGRATION_SOURCES_20261019.json'),'utf8'));
const expected=[53,54,86,87,88,99,104,105,106,107,108,109,110,111,112,113,114,115,117,118,120,121,123,141,143,144,145,146,147,148,149,150,151,152];
assert.deepEqual(manifest.open_prs.map(r=>r.pr),expected,'every reviewed open PR has exactly one disposition');
let paths=0;
for(const entry of manifest.open_prs){
 assert(/^[a-f0-9]{40}$/.test(entry.source_head));
 assert(entry.disposition&&entry.required_paths.length);
 for(const relative of new Set([entry.evidence_path,...entry.required_paths])){
  const absolute=path.resolve(root,relative);
  assert(absolute.startsWith(root+path.sep),'source evidence remains in repository');
  assert(fs.statSync(absolute).isFile(),`PR #${entry.pr}: missing ${relative}`);paths++;
 }
}
const config=fs.readFileSync(path.join(root,'godot_native/project.godot'),'utf8');
assert(config.includes('run/main_scene="res://scenes/entry.tscn"'));
console.log(`Full integration inventory PASS: ${expected.length} PR dispositions, ${paths} path checks. Presence is source coverage; runtime, saves and visual parity require separate validation.`);
