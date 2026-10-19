#!/usr/bin/env node
// Earned campaign snapshots -> independent entry/Continue processes. No DEV seeds.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';

if (process.platform !== 'linux') throw new Error('Linux XDG isolation is required');
const project = path.resolve(import.meta.dirname, '..');
const output = path.resolve(process.env.CONTINUITY_OUTPUT || fs.mkdtempSync(path.join(os.tmpdir(), '755-continuity-report-')));
fs.mkdirSync(output, {recursive: true});
const earned = path.join(output, 'earned');
const records = [];
function sandbox() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), '755-continuity-entry-'));
  return Object.fromEntries(['DATA', 'CONFIG', 'CACHE', 'STATE'].map(key => {
    const folder = path.join(root, key.toLowerCase());
    fs.mkdirSync(folder);
    return [`XDG_${key}_HOME`, folder];
  }));
}
function run(label, script, isolated, extra = {}) {
  const result = spawnSync(process.env.GODOT_BIN || 'godot', ['--headless', '--audio-driver', 'Dummy', '--path', project, '--script', `res://tests/${script}`], {
    env: {...process.env, ...isolated, ...extra}, encoding: 'utf8', timeout: 12 * 60 * 1000, maxBuffer: 32 * 1024 * 1024
  });
  const text = (result.stdout || '') + (result.stderr || '');
  fs.writeFileSync(path.join(output, `${label}.log`), text);
  const ok = !result.error && result.status === 0 && !/(?:^|\n)ERROR:|SCRIPT ERROR:|Parse Error:|Failed to load script/.test(text);
  records.push({label, ok, status: result.status, error: result.error?.message || null});
  fs.writeFileSync(path.join(output, 'summary.json'), JSON.stringify(records, null, 2));
  console.log(`${ok ? 'PASS' : 'FAIL'} ${label}`);
  if (!ok) {
    console.error(text.slice(-12000));
    throw new Error(`Continuity check failed: ${label}; raw output retained at ${output}`);
  }
}
run('campaign', 'campaign_continuity_recorder.gd', sandbox(), {
  CONTINUITY_CAPTURE_DIR: earned, CAMPAIGN_REPORT: path.join(output, 'campaign.json')
});
for (const [scenario, filename] of [
  ['escape', 'after_c3_defense_result.json'],
  ['admission', 'after_c3_target_theater_ticket_gate.json'],
  ['theater_intro', 'after_c3_enter_theater.json']
]) {
  const isolated = sandbox();
  const saveDir = path.join(isolated.XDG_DATA_HOME, 'SevenFiftyFiveNative');
  fs.mkdirSync(saveDir);
  fs.copyFileSync(path.join(earned, filename), path.join(saveDir, 'save.json'));
  for (const stage of ['interrupt', 'complete', 'reload']) {
    run(`${scenario}-${stage}`, 'probe_whole_game_entry.gd', isolated, {
      CONTINUITY_SCENARIO: scenario, CONTINUITY_STAGE: stage,
      CONTINUITY_REPORT: path.join(output, `${scenario}-${stage}.json`)
    });
  }
}
console.log(`Formal continuity checks passed; evidence: ${output}`);
