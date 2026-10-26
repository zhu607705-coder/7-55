#!/usr/bin/env node
// Dependency-free namespace and save boundary check for the isolated prototype.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';

const project = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const scripts = fs.readdirSync(path.join(project, 'scripts')).filter(name => name.endsWith('.gd'));
assert(scripts.length >= 1, 'Expected executable standalone GDScript');
const config = fs.readFileSync(path.join(project, 'project.godot'), 'utf8');
assert(!/^\[autoload\]/m.test(config), 'No formal game autoloads in the standalone sample');
assert.match(config, /config\/features=PackedStringArray\("4\.7", "GL Compatibility"\)/);
assert.match(config, /pointing\/emulate_mouse_from_touch=false/);
for (const name of scripts) {
  const code = fs.readFileSync(path.join(project, 'scripts', name), 'utf8');
  assert(!/\b(?:FileAccess|DirAccess|HTTPRequest|HTTPClient|OS\.execute|ProjectSettings\.save)\b/.test(code), `${name} must not write saves, launch tools, or access the network`);
  assert(!/(?:user:\/\/|minute-card-paper|save\.json|res:\/\/\.\.|\.\.\/)/.test(code), `${name} must remain within the isolated prototype namespace`);
  for (const [, dependency] of code.matchAll(/(?:preload|load)\("(res:\/\/[^"\n]+)"\)/g)) {
    const relative = dependency.slice('res://'.length);
    assert(fs.existsSync(path.join(project, relative)), `${name}: missing self-contained dependency ${relative}`);
  }
}
console.log(`RAKING_ISOLATION scripts=${scripts.length} no_formal_state_io=true`);
