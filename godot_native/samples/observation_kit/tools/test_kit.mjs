#!/usr/bin/env node
// A temporary standalone namespace; no project/cache files enter the source kit.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';

const source = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const engine = process.env.GODOT_BIN || 'godot';
const version = spawnSync(engine, ['--version'], {encoding: 'utf8'});
if (version.status !== 0 || !version.stdout.startsWith('4.7.1.')) throw Error('Pinned Godot 4.7.1 required');
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), '755-observation-kit-'));
try {
  const project = path.join(temporary, 'project');
  fs.mkdirSync(path.join(project, 'kit'), {recursive: true});
  for (const file of ['camera_rig.gd', 'pointer_owners.gd', 'history_surface.gd', 'capture_inputs.gd']) fs.copyFileSync(path.join(source, file), path.join(project, 'kit', file));
  fs.copyFileSync(path.join(source, 'tests/test_kit.gd'), path.join(project, 'test_kit.gd'));
  fs.writeFileSync(path.join(project, 'project.godot'), 'config_version=5\n[application]\nconfig/name="Observation kit isolated check"\nconfig/features=PackedStringArray("4.7", "GL Compatibility")\n[input_devices]\npointing/emulate_mouse_from_touch=false\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
  const env = {...process.env};
  for (const name of ['DATA', 'CONFIG', 'CACHE', 'STATE']) {
    env[`XDG_${name}_HOME`] = path.join(temporary, name.toLowerCase());
    fs.mkdirSync(env[`XDG_${name}_HOME`]);
  }
  const result = spawnSync(engine, ['--headless', '--audio-driver', 'Dummy', '--path', project, '--script', 'res://test_kit.gd'], {env, encoding: 'utf8', timeout: 30000});
  const output = (result.stdout || '') + (result.stderr || '');
  process.stdout.write(output);
  if (result.status !== 0 || /SCRIPT ERROR:|^ERROR:|Parse Error:|Assertion failed/m.test(output) || !output.includes('OBSERVATION_KIT camera=50/8')) throw Error('Observation kit regression failed');
} finally {
  fs.rmSync(temporary, {recursive: true, force: true});
}
