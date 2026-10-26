import fs from 'node:fs';
import path from 'node:path';
import {spawn, spawnSync} from 'node:child_process';
import {createNativeTestSandbox} from './native_test_sandbox.mjs';
import {createValidationCatalog, planValidation, PREFLIGHT} from './native_validation_plan.mjs';
import {acquireNativeWorkspaceLock} from './native_validation_lock.mjs';
import {scheduleValidation} from './native_validation_scheduler.mjs';
import {validationIdentity, stageIdentity, fixtureIdentity, canReuse, fileDigest, inheritedTestOverrides, completedStageIdentity} from './native_validation_identity.mjs';

const project = path.resolve(import.meta.dirname, '..'), root = path.dirname(project);
const executable = process.env.GODOT_BIN || 'godot';
const options = {profile: 'full', tests: [], changedFiles: []};
let resume = false, inspect = false, filter = null, changedSince = null;
const argv = process.argv.slice(2);
for (let i = 0; i < argv.length; i++) {
 const flag = argv[i];
 if (['--plan', '--list'].includes(flag)) {inspect = true; continue;}
 if (flag === '--resume') {resume = true; continue;}
 if (!['--profile', '--test', '--changed-file', '--changed-since', '--filter'].includes(flag)) throw Error(`Unknown argument ${flag}`);
 const value = argv[++i];
 if (!value || value.startsWith('--')) throw Error(`${flag} requires a value`);
 if (flag === '--profile') options.profile = value;
 if (flag === '--test') options.tests.push(value);
 if (flag === '--changed-file') options.changedFiles.push(value.replaceAll('\\', '/'));
 if (flag === '--changed-since') changedSince = value;
 if (flag === '--filter') filter = new RegExp(value);
}
if (changedSince) {
 const git = args => {const r = spawnSync('git', args, {cwd: root, encoding: 'utf8'}); if (r.status !== 0) throw Error(r.stderr); return r.stdout.split('\0').filter(Boolean);};
 const revision = git(['rev-parse', '--verify', `${changedSince}^{commit}`])[0].trim();
 options.changedFiles.push(...git(['diff', '--name-only', '-z', revision, '--']), ...git(['ls-files', '--others', '--exclude-standard', '-z']));
}
const catalog = createValidationCatalog(project, executable);
const plan = planValidation(catalog, {...options, filter});
if (inspect) {
 const output = JSON.stringify({...plan, stages: plan.stages.map(s => ({...s, status: 'not-run'}))}, null, 2) + '\n';
 // Pipes flush asynchronously. Do not truncate a large plan by exiting while
 // stdout still owns buffered JSON; inspecting must remain nonexecuting.
 await new Promise((resolve, reject) => process.stdout.write(output, error => error ? reject(error) : resolve()));
 process.exit(0);
}
const report = process.env.GODOT_TEST_REPORT && path.resolve(process.env.GODOT_TEST_REPORT);
if (resume && !report) throw Error('--resume requires GODOT_TEST_REPORT');
let jobs = Number(process.env.NATIVE_TEST_JOBS || 2);
if (!Number.isInteger(jobs) || jobs < 1 || jobs > 4) throw Error('NATIVE_TEST_JOBS must be 1, 2, 3, or 4');
// A custom test output/fixture environment may bypass user:// isolation. Do not
// parallelize unreviewed overrides (or resume externally mutable fixture paths).
const inheritedOverrides = inheritedTestOverrides(root);
const externalLoaders = ['NODE_PATH', 'NODE_OPTIONS', 'PYTHONPATH', 'PYTHONHOME', 'LD_PRELOAD', 'LD_LIBRARY_PATH'].filter(key => process.env[key]);
if (resume && [...inheritedOverrides, ...externalLoaders].length) throw Error(`Resume refused with external fixture/output/module overrides: ${[...inheritedOverrides, ...externalLoaders].join(', ')}`);
if (inheritedOverrides.length && jobs > 1) {
 console.warn(`Using jobs=1 for unreviewed test fixture/output overrides: ${inheritedOverrides.join(', ')}`);
 jobs = 1;
}
const pauseFile = process.env.GODOT_TEST_PAUSE_FILE || '/tmp/codex-755-test-pause';
let announcedPause = false;
const oldRows = resume ? JSON.parse(fs.readFileSync(report, 'utf8')) : [];
const previous = resume ? JSON.parse(fs.readFileSync(`${report}.meta.json`, 'utf8')) : null;
if (resume && (previous.schema !== 2 || !previous.identity || previous.resumable === false || !Array.isArray(oldRows))) throw Error('Resume refused: missing/stale/legacy exact-content identity; start a new report');
const rows = plan.rows.map(row => ({...row, label: row.id, result: 'not-run', status: null, failed: null}));
const byId = new Map(rows.map(row => [row.id, row]));
let identity = null;
let reportEnabled = !resume; // Refused resumes must not overwrite prior evidence.
const meta = {schema: 2, startedAt: new Date().toISOString(), project, executable, jobs,
 profile: plan.profile, effectiveProfile: plan.effectiveProfile, partial: plan.partial, reasons: plan.reasons,
 identity: null, resumable: false, finalAcceptance: plan.finalAcceptance,
 gitHead: spawnSync('git', ['rev-parse', 'HEAD'], {cwd: root, encoding: 'utf8'}).stdout?.trim(),
 gitTree: spawnSync('git', ['rev-parse', 'HEAD^{tree}'], {cwd: root, encoding: 'utf8'}).stdout?.trim()};
function atomicWrite(file, value) {
 fs.mkdirSync(path.dirname(file), {recursive: true});
 const temporary = `${file}.${process.pid}.tmp`;
 fs.writeFileSync(temporary, JSON.stringify(value, null, 2) + '\n'); fs.renameSync(temporary, file);
}
function writeReport() {
 if (!report || !reportEnabled) return;
 meta.summary = Object.fromEntries(['not-run', 'pass', 'failed', 'blocked', 'deduplicated'].map(status => [status, rows.filter(r => r.result === status).length]));
 meta.selected = plan.stages.length; meta.total = rows.length;
 // Metadata first: a crash cannot associate new rows with a stale identity.
 atomicWrite(`${report}.meta.json`, meta); atomicWrite(report, rows);
}
function blocked(stage, reason) {Object.assign(byId.get(stage.id), {result: 'blocked', failed: null, reason}); writeReport();}
const releaseLock = acquireNativeWorkspaceLock(project, 'native validation');

async function run(stage) {
 const row = byId.get(stage.id);
 for (const dependency of filter ? [] : stage.dependencies) {
  if (byId.get(dependency)?.result !== 'pass') {blocked(stage, `Dependency did not pass: ${dependency}`); return false;}
 }
 const isPreflight = PREFLIGHT.includes(stage.id);
 const fixtureBefore = fixtureIdentity(root, stage.id);
 const key = identity && stageIdentity(identity, stage, fixtureBefore);
 const cached = oldRows.find(r => r.id === stage.id);
 if (!isPreflight && resume && canReuse(cached, key)) {
  Object.assign(row, cached, {selected: true, reused: true, reusedAt: new Date().toISOString()});
  console.log(`REUSED ${stage.label}`); writeReport(); return true;
 }
 while (fs.existsSync(pauseFile)) {
  if (!announcedPause) {console.log(`PAUSED native validation while ${pauseFile} exists`); announcedPause = true;}
  await new Promise(resolve => setTimeout(resolve, 1000));
 }
 const fixture = createNativeTestSandbox(project);
 const args = stage.command === executable ? stage.args.map((value, index) => index > 0 && stage.args[index - 1] === '--path' ? fixture.project : value) : stage.args;
 const timeout = (stage.id === 'Godot asset import and editor parse' ? 20 : ['test_full_campaign.gd', 'Formal campaign entry persistence', 'Chapter 4 late Continue persistence'].includes(stage.id) ? 12 : 5) * 60 * 1000;
 const start = Date.now();
 Object.assign(row, {startedAt: new Date().toISOString(), reason: null});
 const result = await new Promise(resolve => {
  const child = spawn(stage.command, args, {cwd: root, timeout, env: fixture.env});
  let stdout = '', stderr = '', error = null, bytes = 0;
  const capture = channel => chunk => {
   bytes += Buffer.byteLength(chunk);
   if (bytes > 32 * 1024 * 1024) {error = new Error('Native stage output exceeded 32 MiB'); child.kill(); return;}
   if (channel === 'stdout') stdout += chunk; else stderr += chunk;
  };
  child.stdout.setEncoding('utf8').on('data', capture('stdout'));
  child.stderr.setEncoding('utf8').on('data', capture('stderr'));
  child.on('error', value => {error = value;});
  child.on('close', (status, signal) => resolve({status, signal, error, stdout, stderr}));
 });
 let output = result.stdout + result.stderr;
 let completedIdentity = null;
 try {completedIdentity = completedStageIdentity(identity, stage, fixtureBefore, fixtureIdentity(root, stage.id));}
 catch (error) {result.error = error; output += `\n${error.message}\n`;}
 const failed = !!(result.error || result.status !== 0 || /(?:^|\n)ERROR:|SCRIPT ERROR:|Parse Error:|Failed to load script|TEST FAILED|ASSERTION FAILED/.test(output));
 Object.assign(row, {result: failed ? 'failed' : 'pass', status: result.status, failed, signal: result.signal,
  error: result.error?.message || null, finishedAt: new Date().toISOString(), durationMs: Date.now() - start,
  command: stage.command, args: stage.args, output, reused: false,
  identity: completedIdentity});
 writeReport(); console.log(`${failed ? 'FAIL' : 'PASS'} ${stage.label}`);
 if (failed) {console.error(output.slice(-24000)); process.exitCode = 1;}
 return !failed;
}
try {
 writeReport();
 const preflight = plan.stages.filter(s => PREFLIGHT.includes(s.id));
 let ready = true;
 for (const stage of preflight) {
  if (!ready) {blocked(stage, 'Mandatory preflight failed'); continue;}
  if (!await run(stage)) ready = false;
 }
 if (!ready) {
  for (const stage of plan.stages.filter(s => !PREFLIGHT.includes(s.id))) blocked(stage, 'Mandatory preflight failed');
 } else {
  // Hash exact content only after import. Every formal attempt reruns preflight;
  // old imports, stale files and legacy label-only receipts cannot bypass it.
  const extraExcludes = report && !path.relative(root, report).startsWith('..') ? [path.relative(root, report), path.relative(root, `${report}.meta.json`)] : [];
  if (report || resume) {
   identity = validationIdentity(root, {executable, jobs, extraExcludes});
   if (resume && previous.identity.sha256 !== identity.sha256) throw Error('Resume refused: exact source/dependency/import/tool/environment identity changed; start a new report');
   reportEnabled = true; meta.identity = identity; meta.resumable = !inheritedOverrides.length && !externalLoaders.length; writeReport();
  }
  let rest = plan.stages.filter(s => !PREFLIGHT.includes(s.id));
  // Audited same body/input/environment, not generic identical-file guessing.
  // If either file changes, both independent regression entries execute again.
  const canonical = 'test_buct_haidian.gd', alias = 'test_buct_rongmao.gd';
  const duplicate = [canonical, alias].every(id => rest.some(s => s.id === id) && fileDigest(path.join(project, 'tests', id)) === '7755f05f3ff527e4072523a90b70452ada0aa64b69b652be09d7df83f03a6510');
  if (duplicate) rest = rest.filter(s => s.id !== alias);
  await scheduleValidation(rest, {jobs, run});
  if (duplicate) {
   const source = byId.get(canonical), target = byId.get(alias);
   Object.assign(target, {result: source.result === 'pass' ? 'deduplicated' : 'blocked', failed: null, equivalentTo: canonical,
    reason: 'Audited identical script bytes, scene, environment and inputs; no self-path introspection. No regression file removed.'});
  }
  if (identity) {
   const after = validationIdentity(root, {executable, jobs, extraExcludes});
   if (after.sha256 !== identity.sha256) {meta.resumable = false; meta.inputChangedDuringRun = true; process.exitCode = 1; console.error('Validation inputs changed during execution; evidence is not an exact-content completion and cannot resume.');}
  }
 }
 if (rows.some(row => row.selected && ['failed', 'blocked', 'not-run'].includes(row.result))) process.exitCode = 1;
 meta.completed = !process.exitCode; meta.fullSuitePassed = !plan.partial && meta.completed;
 meta.finishedAt = new Date().toISOString(); writeReport();
 console.log(`${meta.fullSuitePassed ? 'FULL' : 'PARTIAL'} validation: ${JSON.stringify(meta.summary || {})}`);
} catch (error) {
 meta.resumable = false; meta.error = error.message; writeReport(); throw error;
} finally {releaseLock();}
