#!/usr/bin/env node
// Load the actual, byte-identical Web boot PCK with a native engine in a
// source-less directory. Only an external user-directory override is permitted.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { createNativeTestSandbox } from '../tools/native_test_sandbox.mjs';

const argument = name => process.argv.find(value => value.startsWith(name + '='))?.slice(name.length + 1);
const directory = argument('--export');
if (!directory) throw new Error('Required --export=actual-export-directory');
const project = path.resolve(import.meta.dirname, '..');
const fixture = createNativeTestSandbox(project);
const evidence = fs.mkdtempSync(path.join(os.tmpdir(), '755-story-only-entry-'));
const empty = path.join(evidence, 'source-less');
fs.mkdirSync(empty);
const hash = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const original = path.resolve(directory, 'index.pck');
const copied = path.join(empty, 'index.pck');
fs.copyFileSync(original, copied);
const customName = /^config\/custom_user_dir_name="([^"]+)"/m.exec(fs.readFileSync(path.join(fixture.project, 'project.godot'), 'utf8'))?.[1];
if (process.platform === 'darwin' && (!customName || !customName.startsWith('755-native-check-'))) throw new Error('Missing isolated macOS fixture configuration');
if (process.platform === 'darwin') fs.writeFileSync(path.join(empty, 'override.cfg'), '[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name=' + JSON.stringify(customName) + '\n');
const script = path.join(evidence, 'test_developer_tools_access.gd');
fs.copyFileSync(path.join(project, 'tests/test_developer_tools_access.gd'), script);
const engine = process.env.GODOT_BIN || 'godot';
const args = ['--headless', '--audio-driver', 'Dummy', '--main-pack', copied, '--script', script, '--', '--require-production', '--require-story-only', '--fresh', '--checkpoint=c4-755-elevator-history', '--preview=duan_yongping_temporal_maze', '--page=phone_home'];
const startedAt = new Date().toISOString();
const result = spawnSync(engine, args, { cwd: empty, env: fixture.env, encoding: 'utf8', timeout: 120_000, maxBuffer: 16 * 1024 * 1024 });
const output = `${result.stdout || ''}${result.stderr || ''}`;
fs.writeFileSync(path.join(evidence, 'engine.log'), output);
const summary = /DEVELOPER_TOOLS_ACCESS (\d+) checks; (\d+) failures/.exec(output);
const passed = !result.error && result.status === 0 && summary && Number(summary[1]) >= 40 && Number(summary[2]) === 0
  && !/(?:^|\n)ERROR:|SCRIPT ERROR:|Parse Error:|Failed to load script/.test(output) && hash(original) === hash(copied);
const report = {
  schema: '755-story-only-entry-v1', passed: Boolean(passed), startedAt, finishedAt: new Date().toISOString(),
  scope: 'Actual source-less Web PCK, native engine feature/entry/input/content-admission regression. Browser rendering and network acceptance remain separate.',
  export: path.resolve(directory), packSha256: hash(original), externalScriptSha256: hash(script), evidence,
  isolation: { userData: fixture.userData, sourceLessDirectory: empty, override: 'External user directory only; original PCK bytes and release features retained.' },
  engine, args, status: result.status, error: result.error?.message || null, checks: summary ? Number(summary[1]) : null, output,
};
const reportFile = path.resolve(argument('--report') || path.join(evidence, 'report.json'));
fs.mkdirSync(path.dirname(reportFile), { recursive: true });
fs.writeFileSync(reportFile, JSON.stringify(report, null, 2) + '\n');
console.log(JSON.stringify({ passed: report.passed, checks: report.checks, report: reportFile, evidence, packSha256: report.packSha256 }, null, 2));
if (!passed) { console.error(output.slice(-12000)); process.exitCode = 1; }
