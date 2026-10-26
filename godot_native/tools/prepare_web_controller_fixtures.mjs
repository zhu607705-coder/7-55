import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {spawn} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {createNativeTestSandbox} from './native_test_sandbox.mjs';
import {acquireNativeWorkspaceLock} from './native_validation_lock.mjs';
import {preparePhoneRecoveryInputs} from './prepare_phone_recovery_inputs.mjs';

// Invoke only after source preparation, import AND export have finished. These
// two unchanged recorders share read-only res:///.godot, but never user:// or
// capture files. No fixture is certified until both processes have closed.
const RECORDERS = [
  {id: 'campaign', prefix: '755-web-controller-fixture-', script: 'res://tests/campaign_continuity_recorder.gd',
    captureVariable: 'CONTINUITY_CAPTURE_DIR', report: 'controller-campaign-report.json', log: 'controller-campaign.log'},
  {id: 'library', prefix: '755-web-library-fixture-', script: 'res://tests/library_continuity_recorder.gd',
    captureVariable: 'LIBRARY_CAPTURE_DIR', report: 'library-controller-report.json', log: 'library-controller.log'}
];
const requireValue = (value, message) => {if (!value) throw Error(message);};
const readJson = filename => JSON.parse(fs.readFileSync(filename, 'utf8'));

export function validateControllerReport(report, library = false) {
  requireValue(report && report.failures === 0 && Number.isInteger(report.checks) && report.checks > 0 &&
    report.kind === 'continuous-native-controller-campaign' && report.notManualPlaythrough === true &&
    report.spatialSetupExplicit === true && (!library || [1, 2].every(chapter => report.completedChapters?.includes(chapter))),
  `Missing successful controller-only ${library ? 'library ' : ''}fixture provenance`);
  return report;
}

// Flat filenames are intentional: the two existing recorders only emit JSON
// files. Refuse directories/symlinks and colliding names even when bytes agree.
export function mergeControllerFiles(directories, destination) {
  const entries = [], names = new Set();
  for (const directory of directories) for (const name of fs.readdirSync(directory).sort()) {
    requireValue(/^[a-zA-Z0-9][a-zA-Z0-9_.-]*\.(?:json|log)$/.test(name) &&
      !['fixture-provenance.json', 'phone-recovery-inputs.json'].includes(name) && !name.startsWith('compat-'), `Unexpected controller output: ${name}`);
    requireValue(fs.lstatSync(path.join(directory, name)).isFile(), `Controller output is not a regular file: ${name}`);
    requireValue(!names.has(name), `Controller output collision: ${name}`);
    names.add(name); entries.push([directory, name]);
  }
  // Complete inventory validation before creating any success-candidate files.
  requireValue(!fs.existsSync(destination), 'Controller merge destination must not exist');
  fs.mkdirSync(destination);
  for (const [directory, name] of entries) fs.copyFileSync(path.join(directory, name), path.join(destination, name), fs.constants.COPYFILE_EXCL);
}

function launchRecorder(spec, {spawnProcess, executable, log, cancellationGraceMs}) {
  const child = spawnProcess(executable, spec.command, {env: spec.env, stdio: ['ignore', 'pipe', 'pipe']});
  let closed = false, terminated = false, timer, processError, bytes = 0;
  const stdout = [], stderr = [];
  const terminate = () => {
    if (closed || terminated) return;
    terminated = true;
    child.kill('SIGTERM');
    timer = setTimeout(() => {if (!closed) child.kill('SIGKILL');}, cancellationGraceMs);
    timer.unref?.();
  };
  const completion = new Promise((resolve, reject) => {
    const collect = target => chunk => {
      const data = Buffer.from(chunk); bytes += data.length;
      if (bytes <= 32 * 1024 * 1024) target.push(data);
      else {processError ||= Error('Controller output exceeds the original 32 MiB process buffer'); terminate();}
    };
    child.stdout.on('data', collect(stdout)); child.stderr.on('data', collect(stderr));
    child.once('error', error => {processError = error;});
    child.once('close', (status, signal) => {
      closed = true; clearTimeout(timer);
      const output = `${Buffer.concat(stdout).toString('utf8')}\n${Buffer.concat(stderr).toString('utf8')}`;
      try {
        fs.writeFileSync(path.join(spec.capture, spec.log), output);
        log(output);
        requireValue(!processError && status === 0 && signal == null && !/(?:^|\n)\s*(?:SCRIPT ERROR|ERROR):/.test(output),
          `${spec.id} fixture generation failed: ${processError?.message || signal || status}`);
        const report = validateControllerReport(readJson(path.join(spec.capture, spec.report)), spec.id === 'library');
        resolve({spec, report});
      } catch (error) {reject(error);}
    });
  });
  return {completion, terminate};
}

export async function prepareWebControllerFixtures({
  project = path.resolve('godot_native'), output = path.resolve('godot_native/exports/verification/controller-earned'),
  sourceFile = path.resolve('godot_native/exports/verification/ci-source.json'),
  executable = process.env.GODOT_BIN || 'godot', spawnProcess = spawn,
  createSandbox = createNativeTestSandbox, preparePhoneInputs = preparePhoneRecoveryInputs,
  acquireLock = acquireNativeWorkspaceLock, log = console.log, cancellationGraceMs = 3000
} = {}) {
  project = path.resolve(project); output = path.resolve(output);
  requireValue(!fs.existsSync(output), 'Controller-earned output already exists; refusing stale or overwritten fixtures');
  const source = readJson(sourceFile);
  requireValue(source && typeof source === 'object' && !Array.isArray(source), 'Missing exact-source acceptance receipt');
  fs.mkdirSync(path.dirname(output), {recursive: true});
  const diagnostics = `${output}-diagnostics`;
  requireValue(!fs.existsSync(diagnostics), 'Controller diagnostics already exist; refusing stale diagnostics');
  const release = acquireLock(project, 'parallel read-only Web controller recorders');
  const sandboxes = [], specifications = [], handles = [];
  let aborted, merged;
  const cancel = signal => {aborted ||= Error(`Controller fixture generation cancelled: ${signal}`); for (const handle of handles) handle.terminate();};
  const onInt = () => cancel('SIGINT'), onTerm = () => cancel('SIGTERM');
  process.once('SIGINT', onInt); process.once('SIGTERM', onTerm);
  try {
    fs.mkdirSync(diagnostics);
    for (const recorder of RECORDERS) {
      const sandbox = createSandbox(project, recorder.prefix); sandboxes.push(sandbox);
      const capture = path.join(sandbox.root, 'controller-capture'); fs.mkdirSync(capture);
      const command = ['--headless', '--path', sandbox.project, '--script', recorder.script];
      const spec = {...recorder, capture, command,
        env: {...sandbox.env, [recorder.captureVariable]: capture, CAMPAIGN_REPORT: path.join(capture, recorder.report)}};
      specifications.push(spec);
      // Synchronous launch failures must cancel and join any already-live peer.
      handles.push(launchRecorder(spec, {spawnProcess, executable, log, cancellationGraceMs}));
    }
    const results = await Promise.allSettled(handles.map(handle => handle.completion.catch(error => {
      for (const peer of handles) if (peer !== handle) peer.terminate();
      throw error;
    })));
    if (aborted) throw aborted;
    const rejected = results.find(result => result.status === 'rejected');
    if (rejected) throw rejected.reason;
    const [campaign, library] = results.map(result => result.value);
    merged = path.join(diagnostics, 'validated-merge');
    mergeControllerFiles(specifications.map(spec => spec.capture), merged);
    function portableFixture(fixture) {
      const bytes = fs.readFileSync(path.join(merged, fixture)), save = JSON.parse(bytes);
      requireValue(save.format === '7-55-godot-native' && save.version === 1 && save.state,
        `Missing ordinary portable C2 fixture: ${fixture}`);
      return {fixture, bytes: bytes.length, sha256: createHash('sha256').update(bytes).digest('hex')};
    }
    const phoneRecoveryInputs = preparePhoneInputs(merged);
    const libraryInputs = {recorder: library.spec.script, command: library.spec.command, checks: library.report.checks,
      fixtures: ['before_library_rule_read.json', 'before_library_022_opening.json'].map(portableFixture),
      scope: 'Controller-earned library boundaries with explicit spatial setup; not complete natural-navigation proof.'};
    const provenance = {source, recorder: campaign.spec.script, command: campaign.spec.command, checks: campaign.report.checks,
      ...portableFixture('before_c2_dorm_exit.json'), streamingFixture: portableFixture('after_c2_dorm_exit.json'), phoneRecoveryInputs, libraryInputs,
      scope: 'Controller-earned snapshots with explicit spatial test setup, plus explicitly constructed legacy low-battery variants; not browser interaction or manual-navigation proof. Browser coverage is the separately executed mobile-world, streaming, phone-recovery and library-boundary scenarios.'};
    fs.writeFileSync(path.join(merged, 'fixture-provenance.json'), JSON.stringify(provenance, null, 2) + '\n');
    log(JSON.stringify(provenance, null, 2));
    fs.renameSync(merged, output); merged = null;
    return provenance;
  } catch (error) {
    for (const handle of handles) handle.terminate();
    await Promise.allSettled(handles.map(handle => handle.completion));
    throw error;
  } finally {
    // Preserve only diagnostics here, never a partial success manifest. Both
    // children have closed before their capture/save sandboxes are removed.
    try {
      for (const spec of specifications) {
        const directory = path.join(diagnostics, spec.id); fs.mkdirSync(directory, {recursive: true});
        for (const name of [spec.log, spec.report]) {
          const filename = path.join(spec.capture, name);
          if (fs.existsSync(filename) && fs.lstatSync(filename).isFile()) fs.copyFileSync(filename, path.join(directory, name));
        }
      }
    } finally {
      try {
        if (merged) fs.rmSync(merged, {recursive: true, force: true});
        for (const sandbox of sandboxes) fs.rmSync(sandbox.root, {recursive: true, force: true});
      } finally {
        process.removeListener('SIGINT', onInt); process.removeListener('SIGTERM', onTerm); release();
      }
    }
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  if (process.argv.length !== 2) throw Error('Usage: node prepare_web_controller_fixtures.mjs');
  await prepareWebControllerFixtures();
}
