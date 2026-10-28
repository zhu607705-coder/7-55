import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const sample = path.dirname(fileURLToPath(import.meta.url));
const project = path.join(sample, 'preview');
const native = path.resolve(sample, '../..');
const godot = process.env.GODOT_BIN || 'godot';
const source = path.join(native, 'ui_assets/fonts/MorningNote-Regular.ttf');
const expectedFont = '7a90f1a996c6e5b124644fc12bac9f8c41f13976f767d3ac5a75f0e796a6e2ae';
const font = fs.readFileSync(source);
if (crypto.createHash('sha256').update(font).digest('hex') !== expectedFont) {
  throw new Error('Existing Morning Note font changed. Review its provenance before updating this preview.');
}
fs.mkdirSync(path.join(project, 'generated'), { recursive: true });
fs.writeFileSync(path.join(project, 'generated/MorningNote-Regular.ttf'), font);
fs.copyFileSync(path.join(native, 'ui_assets/fonts/MORNING_NOTE_OFL.txt'), path.join(project, 'generated/MORNING_NOTE_OFL.txt'));
if (process.argv.includes('--prepare-only')) {
  console.log('PHONE_CAMPUS_PREPARE font SHA-256 verified; existing font and OFL copied');
  process.exit(0);
}
const env = { ...process.env };
// Keep editor caches and this presentation's user:// isolated from formal saves.
for (const [name, folder] of [['XDG_DATA_HOME', 'data'], ['XDG_CONFIG_HOME', 'config'], ['XDG_CACHE_HOME', 'cache']]) {
  env[name] = path.join(project, 'generated/runtime', folder);
  fs.mkdirSync(env[name], { recursive: true });
}
function run(args, timeout = 120000) {
  const result = spawnSync(godot, args, { cwd: project, env, encoding: 'utf8', timeout });
  process.stdout.write(result.stdout || '');
  process.stderr.write(result.stderr || '');
  if (result.error || result.status !== 0 || /SCRIPT ERROR:|ERROR:/.test((result.stdout || '') + (result.stderr || ''))) {
    throw new Error(`Godot check failed: ${args.join(' ')} (${result.error || result.status})`);
  }
  return result.stdout;
}
const version = run(['--headless', '--version']);
if (!version.includes('4.7.1.stable.official')) throw new Error(`Use the project's pinned Godot 4.7.1, not ${version.trim()}`);
run(['--headless', '--path', project, '--editor', '--import']);
const args = process.argv.slice(2);
if (args.includes('--test')) {
  run(['--headless', '--path', project, '--script', 'res://test_transition.gd']);
  run(['--headless', '--path', project, '--script', 'res://test_input.gd']);
} else if (args.includes('--capture')) {
  // Capture requires a real graphical renderer. The capture script rejects headless/dummy.
  const directory = path.resolve(args[args.indexOf('--capture') + 1] || path.join(sample, 'evidence'));
  run(['--path', project, '--audio-driver', 'Dummy', '--script', 'res://capture.gd', '--', `--output=${directory}`]);
} else {
  const result = spawnSync(godot, ['--path', project, ...args], { cwd: project, env, stdio: 'inherit' });
  if (result.error || result.status !== 0) process.exitCode = 1;
}
