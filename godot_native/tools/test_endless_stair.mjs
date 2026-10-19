import fs from 'node:fs';
import {createNativeTestSandbox} from './native_test_sandbox.mjs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';

// Keep prototype tests away from the user's real SevenFiftyFiveNative saves.
const project = path.resolve(import.meta.dirname, '..');
const godot = process.env.GODOT_BIN || 'godot';
const names = ['route', 'pursuit', 'feedback', 'presentation', 'beam', 'integration', 'step_pose', 'gait', 'camera_input'];
const results = [];
for (const name of names) {
  const fixture = createNativeTestSandbox(project);
  const env = fixture.env;
  const script = `test_endless_stair_${name}.gd`;
  const run = spawnSync(godot, ['--headless', '--audio-driver', 'Dummy', '--path', fixture.project, '--script', `res://tests/${script}`, '--', '--fresh'], {
    env, encoding:'utf8', timeout:300000, maxBuffer:16 * 1024 * 1024
  });
  const output = (run.stdout || '') + (run.stderr || '');
  const passed = !run.error && run.status === 0 && !/(?:^|\n)ERROR:|SCRIPT ERROR:|Parse Error:|Failed to load script|TEST FAILED|ASSERTION FAILED/.test(output);
  results.push({script, passed, status:run.status, output});
  console.log(`${passed ? 'PASS' : 'FAIL'} ${script}`);
  if (!passed) { console.error(output); process.exitCode = 1; }
}
if (process.env.ENDLESS_STAIR_TEST_REPORT) fs.writeFileSync(process.env.ENDLESS_STAIR_TEST_REPORT, JSON.stringify(results, null, 2) + '\n');
