#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const config = fs.readFileSync(path.join(root, 'project.godot'), 'utf8');
assert(!/^\[autoload\]/m.test(config), 'Standalone sample must not load formal game autoloads');
assert.match(config, /config\/features=PackedStringArray\("4\.7", "GL Compatibility"\)/);
assert.match(config, /pointing\/emulate_mouse_from_touch=false/);
assert.match(config, /run\/main_scene="res:\/\/scenes\/library_time\.tscn"/);
const files = [];
function walk(directory) {
  for (const entry of fs.readdirSync(directory, {withFileTypes: true})) {
    const full = path.join(directory, entry.name);
    if (entry.isDirectory()) walk(full);
    else if (/\.(gd|tscn|tres)$/.test(entry.name)) files.push(full);
  }
}
for (const directory of ['scripts', 'kit', 'scenes']) walk(path.join(root, directory));
assert(files.length >= 8, 'Expected model, world, view and standalone helpers');
for (const file of files) {
  const code = fs.readFileSync(file, 'utf8');
  const relative = path.relative(root, file);
  assert(!/\b(?:FileAccess|DirAccess|HTTPRequest|HTTPClient|OS\.execute|ProjectSettings\.save)\b/.test(code), `${relative}: runtime must not write state or access network`);
  assert(!/(?:user:\/\/|save\.json|res:\/\/\.\.|\.\.\/)/.test(code), `${relative}: isolated namespace only`);
  for (const match of code.matchAll(/(?:preload|load)\("(res:\/\/[^"\n]+)"\)|path="(res:\/\/[^"\n]+)"/g)) {
    const reference = match[1] || match[2];
    assert(fs.existsSync(path.join(root, reference.slice(6))), `${relative}: missing local resource ${reference}`);
  }
}
const model = fs.readFileSync(path.join(root, 'scripts/library_model.gd'), 'utf8');
assert(!/\b(?:World|SceneTree|Node3D|Camera3D|SubViewport)\b/.test(model), 'Local inference model must not own historical or present worlds');
console.log(`LIBRARY_ISOLATION runtime_files=${files.length} no_formal_state_io=true self_contained=true`);
