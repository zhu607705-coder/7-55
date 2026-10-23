#!/usr/bin/env node
// Offline preview only. The temporary project has NO autoload or Main scene.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const args = process.argv.slice(2), option = name => args.find(value => value.startsWith(`--${name}=`))?.slice(name.length + 3);
if (!option('output')) throw new Error('Usage: capture_liangzhu_performance.mjs --output=<new absolute directory> [--full] [--presentation-frame] [--sample-times=<comma-separated-ms>]; default is seven cue samples');
const output = path.resolve(option('output')), source = fileURLToPath(new URL('..', import.meta.url));
const cache = path.join(source, '.godot'), engine = process.env.GODOT_BIN || '/Applications/Godot.app/Contents/MacOS/Godot';
if (!fs.existsSync(cache)) throw new Error('Lead must complete the shared native asset import before capture');
for (const asset of ['stage.png', 'actors.png']) if (!fs.existsSync(path.join(source, 'assets/native/liangzhu_performance_20261021', asset))) throw new Error(`Actual generated asset missing:${asset}`);
if (fs.existsSync(output) && fs.readdirSync(output).some(file => file.endsWith('.png') || ['capture.json', 'runner.json'].includes(file))) throw new Error('Use a new directory; stale capture frames cannot be mixed');
fs.mkdirSync(output, { recursive: true });
const temporaryProject = fs.mkdtempSync(path.join(os.tmpdir(), '755-liangzhu-capture-'));
for (const folder of ['scripts', 'assets', 'tools', 'data']) fs.symlinkSync(path.join(source, folder), path.join(temporaryProject, folder));
fs.symlinkSync(cache, path.join(temporaryProject, '.godot'));
const config = `config_version=5

[application]
config/name="755 Liangzhu offline capture"
config/use_custom_user_dir=true
config/custom_user_dir_name="${path.basename(temporaryProject)}"
config/features=PackedStringArray("4.6", "GL Compatibility")

[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="disabled"

[rendering]
textures/canvas_textures/default_texture_filter=0
renderer/rendering_method="gl_compatibility"
`;
fs.writeFileSync(path.join(temporaryProject, 'project.godot'), config);
if (args.includes('--full') && option('sample-times')) throw new Error('Custom sample times cannot be mixed with full capture');
const command = ['--path', temporaryProject, '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', '--fixed-fps', '30', '--log-file', path.join(output, 'godot.log'), '--script', 'res://tools/capture_liangzhu_performance.gd', '--', `--output=${output}`, ...(args.includes('--full') ? [] : ['--samples']), ...(args.includes('--presentation-frame') ? ['--presentation-frame'] : []), ...(option('sample-times') ? [`--sample-times=${option('sample-times')}`] : [])];
const hashFile = filename => crypto.createHash('sha256').update(fs.readFileSync(filename)).digest('hex');
const receipt = { schema: '755-liangzhu-capture-runner-v1', temporaryProject, autoloads: [], mainScene: null, gameSaveAccess: false, mode: args.includes('--full') ? 'full frozen model duration at30fps' : option('sample-times') ? 'custom cue samples' : 'seven cue samples', presentationFrame: args.includes('--presentation-frame'), outputDimensions: args.includes('--presentation-frame') ? [1280, 720] : [1200, 675], playbackMode: 'passive', engine, command, projectConfigSha256: crypto.createHash('sha256').update(config).digest('hex'), runnerSha256: hashFile(fileURLToPath(import.meta.url)), captureScriptSha256: hashFile(path.join(source, 'tools/capture_liangzhu_performance.gd')), sharedImportedCache: cache, scope: 'Reuse completed imports only; no editor import, export, Main scene or game State is launched.' };
fs.writeFileSync(path.join(output, 'runner.json'), JSON.stringify(receipt, null, 2) + '\n');
try {
  const status = await new Promise((resolve, reject) => {
    const child = spawn(engine, command, { stdio: 'inherit', env: { ...process.env, GODOT_SILENCE_ROOT_WARNING: '1' } });
    child.once('error', reject); child.once('close', (code, signal) => resolve(signal ? 2 : code ?? 2));
  });
  process.exitCode = status;
} finally {
  // rm unlinks the shared cache symlink; it never removes the original cache.
  fs.rmSync(temporaryProject, { recursive: true, force: true });
}
