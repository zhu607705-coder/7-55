import path from 'node:path';
import {spawn} from 'node:child_process';
import {createNativeTestSandbox} from '../../tools/native_test_sandbox.mjs';

const fixture = createNativeTestSandbox(path.resolve(import.meta.dirname, '../..'));
console.log(`Actual NPC preview; disposable DEV save: ${fixture.userData}`);
const child = spawn(process.env.GODOT_BIN || 'godot', [
  '--path', fixture.project, '--script', 'res://samples/north_npc_interaction/play.gd',
  ...process.argv.slice(2),
], {env: fixture.env, stdio: 'inherit'});
child.on('error', error => { console.error(error.message); process.exitCode = 2; });
child.on('close', code => { process.exitCode = code ?? 2; });
