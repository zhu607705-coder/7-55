// Immutable same-run transport, not a generic cache or completed native acceptance.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import {createHash} from 'node:crypto';
import {execFileSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
import {createValidationCatalog, PREFLIGHT, PREPARATION_IDS} from './native_validation_plan.mjs';
import {fileDigest, resolveExecutable, validationIdentity, fixtureIdentity, stageIdentity, PRODUCER_OUTPUTS} from './native_validation_identity.mjs';

const SCHEMA = '755-native-prepared-bundle-v2';
const ASSET_MANIFEST = 'godot_native/data/asset_manifest.json';
const RECEIPT = 'bundle-receipt.json';
const ENGINE = '4.7.1.stable.official';
export {PREPARATION_IDS};
const digest = bytes => createHash('sha256').update(bytes).digest('hex');
const equal = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const sorted = values => [...values].sort((a, b) => a.localeCompare(b, 'en'));
const failUnless = (condition, message) => {if (!condition) throw Error(message);};
const sha = value => typeof value === 'string' && /^[a-f0-9]{64}$/.test(value);
const commit = value => typeof value === 'string' && /^[a-f0-9]{40}$/.test(value);
const positive = value => typeof value === 'string' && /^[1-9][0-9]*$/.test(value) && Number.isSafeInteger(Number(value));
const safeName = value => typeof value === 'string' && value.length > 0 && !/[\\\x00-\x1f\x7f]/.test(value)
  && !value.startsWith('/') && value.split('/').every(part => part && part !== '.' && part !== '..');
const inside = (parent, child) => {const relative = path.relative(parent, child); return relative === '' || (!relative.startsWith(`..${path.sep}`) && relative !== '..' && !path.isAbsolute(relative));};
const readJson = file => JSON.parse(fs.readFileSync(file, 'utf8'));
function safeAbsolute(file) {
  const absolute = path.resolve(file), parsed = path.parse(absolute);
  let current = parsed.root;
  for (const part of absolute.slice(parsed.root.length).split(path.sep)) {
    current = path.join(current, part);
    if (!fs.existsSync(current)) {failUnless(!fs.lstatSync(current, {throwIfNoEntry: false}), `Broken symlink path: ${current}`); continue;}
    failUnless(!fs.lstatSync(current).isSymbolicLink(), `Symlink path is not allowed: ${current}`);
  }
  return absolute;
}
function directory(file) {failUnless(fs.lstatSync(file).isDirectory() && !fs.lstatSync(file).isSymbolicLink(), `Expected real directory: ${file}`);}
function regular(file) {const stat = fs.lstatSync(file); failUnless(stat.isFile() && !stat.isSymbolicLink(), `Expected regular file: ${file}`); return stat;}
function excluded(relative) {
  return relative === '.validation/runner.lock' || relative === 'exports' || relative.startsWith('exports/')
    || relative === '.screenshots' || relative.startsWith('.screenshots/') || relative.endsWith('.log')
    || relative === '.godot/editor' || relative.startsWith('.godot/editor/')
    || relative.split('/').some(part => part === 'node_modules' || part === '.git');
}
function inventory(base, {project = false, skipReceipt = false} = {}) {
  directory(base);
  const files = [], directories = [];
  function walk(current, prefix = '') {
    for (const name of sorted(fs.readdirSync(current))) {
      const relative = prefix ? `${prefix}/${name}` : name;
      failUnless(safeName(relative), `Unsafe bundle path: ${relative}`);
      const file = path.join(current, name), stat = fs.lstatSync(file);
      failUnless(!stat.isSymbolicLink(), `Symlink is not a bundle input: ${relative}`);
      failUnless(stat.isDirectory() || stat.isFile(), `Nonregular bundle input: ${relative}`);
      if ((project && excluded(relative)) || (skipReceipt && relative === RECEIPT)) continue;
      if (stat.isDirectory()) {directories.push({path: relative, mode: stat.mode & 0o777}); walk(file, relative);}
      else files.push({path: relative, bytes: stat.size, sha256: fileDigest(file), mode: stat.mode & 0o777});
    }
  }
  walk(base);
  return {files: files.sort((a, b) => a.path.localeCompare(b.path, 'en')), directories: directories.sort((a, b) => a.path.localeCompare(b.path, 'en'))};
}
const plain = all => ({files: all.files.map(({path, bytes, sha256, mode}) => ({path, bytes, sha256, mode})), directories: all.directories});
const withoutModes = all => ({files: plain(all).files.map(({mode, ...file}) => file), directories: all.directories.map(({path: name}) => name)});
function validateExpected(expected) {
  failUnless(expected && commit(expected.commit) && commit(expected.head) && commit(expected.tree), 'Invalid expected source SHA/tree');
  failUnless(expected.base === null || commit(expected.base), 'Invalid expected base SHA');
  failUnless(positive(expected.run) && positive(expected.attempt), 'Invalid expected run/attempt');
  failUnless(typeof expected.event === 'string' && expected.event.length > 0 && expected.dirty !== true, 'Expected clean checkout and event');
}
function checkout(root, expected) {
  validateExpected(expected); root = safeAbsolute(root); directory(root);
  const git = (...args) => execFileSync('git', args, {cwd: root, encoding: 'utf8', maxBuffer: 32 * 1024 * 1024}).trim();
  failUnless(fs.realpathSync(git('rev-parse', '--show-toplevel')) === fs.realpathSync(root), 'Root must be the Git checkout root');
  failUnless(git('rev-parse', 'HEAD') === expected.commit && git('rev-parse', 'HEAD^{tree}') === expected.tree, 'Git checkout commit/tree differs from expected source');
  failUnless(git('status', '--porcelain', '--untracked-files=no') === '', 'Tracked checkout must be clean');
  return root;
}
function locations(root, bundleDir) {
  bundleDir = safeAbsolute(bundleDir);
  failUnless(!inside(root, bundleDir) && !inside(bundleDir, root), 'Bundle directory must be outside the checkout and cannot contain it');
  return bundleDir;
}
function sourceFor(expected, attempt = expected.attempt) {
  return {event: expected.event, head: expected.head, base: expected.base, checkedOutCommit: expected.commit, tree: expected.tree,
    run: expected.run, attempt, dirty: false};
}
function engineIdentity(meta) {
  const version = meta.identity?.godotVersion;
  failUnless(typeof version === 'string' && (version === ENGINE || version.startsWith(`${ENGINE}.`)), 'Preparation requires pinned Godot 4.7.1 official engine');
  const executable = resolveExecutable(process.env.GODOT_BIN || 'godot');
  const installedVersion = execFileSync(executable, ['--version'], {encoding: 'utf8', timeout: 30000}).trim();
  const binarySha256 = fileDigest(executable);
  const producerTool = meta.identity.tools[0]; // validationIdentity records Godot first, then Node/Python/Bash.
  failUnless(producerTool && producerTool.sha256 === binarySha256 && installedVersion === version, 'Installed Godot engine version/binary differs from preparation identity');
  return {version, binarySha256};
}
function validatePreparation({rows, meta, project, expected, fixtureRoot = path.dirname(project)}) {
  failUnless(meta?.schema === 2 && meta.profile === 'prepare' && meta.effectiveProfile === 'prepare', 'Expected explicit preparation profile report');
  failUnless(meta.gitHead === expected.commit && meta.gitTree === expected.tree, 'Preparation source commit/tree differs');
  failUnless(meta.completed === true && meta.partial === true && meta.fullSuitePassed === false && meta.inputChangedDuringRun === false && meta.resumable === true && !meta.error, 'Preparation was incomplete, changed inputs, or has errors');
  const identity = meta.identity;
  failUnless(identity?.schema === 2 && sha(identity.sha256) && sha(identity.input?.sha256) && Number.isSafeInteger(identity.input?.count) && identity.input.count > 0
    && sha(identity.environmentSha256) && Array.isArray(identity.tools) && identity.tools.length === 4
    && identity.tools.every(tool => typeof tool.path === 'string' && path.isAbsolute(tool.path) && sha(tool.sha256))
    && Number.isInteger(identity.jobs) && identity.jobs >= 1 && identity.jobs <= 4 && identity.jobs === meta.jobs
    && ['godotVersion', 'nodeVersion', 'platform', 'arch', 'release'].every(key => typeof identity[key] === 'string' && identity[key].length > 0)
    && typeof meta.executable === 'string' && meta.executable.length > 0
    && typeof identity.root === 'string' && path.isAbsolute(identity.root) && meta.project === path.join(identity.root, 'godot_native'), 'Incomplete exact input/environment/tool identity');
  const {sha256, ...details} = identity;
  failUnless(digest(JSON.stringify(details)) === sha256, 'Preparation identity SHA differs');
  failUnless(Array.isArray(rows), 'Preparation report must be rows');
  const catalog = createValidationCatalog(project, meta.executable);
  failUnless(equal(rows.map(row => row.id), catalog.map(stage => stage.id)), 'Preparation result catalog has extra, missing or reordered rows');
  failUnless(meta.selected === PREPARATION_IDS.length && meta.total === rows.length, 'Preparation selected/total count differs');
  const selected = rows.filter(row => row.selected).map(row => row.id);
  failUnless(equal(selected, PREPARATION_IDS), 'Preparation must select exactly mandatory preflight and fixed fixture producers');
  for (const row of rows) {
    if (row.selected) {
      failUnless(row.result === 'pass' && row.failed === false && row.status === 0 && row.reused === false && row.error === null && row.signal === null
        && !row.imported && typeof row.output === 'string' && !/(?:^|\n)ERROR:|SCRIPT ERROR:|Parse Error:|Failed to load script|TEST FAILED|ASSERTION FAILED/.test(row.output), `Preparation stage did not freshly pass: ${row.id}`);
      const stage = catalog.find(stage => stage.id === row.id);
      const expectedArgs = stage.args.map(value => typeof value === 'string' && inside(project, value) ? path.join(meta.project, path.relative(project, value)) : value);
      failUnless(equal(row.args, expectedArgs), `Preparation command arguments differ: ${row.id}`);
      failUnless(stage.command === meta.executable ? row.command === meta.executable : row.command === identity.tools[1].path, `Preparation command differs: ${row.id}`);
      if (PREFLIGHT.includes(row.id)) failUnless(row.identity === null, `Unexpected reused preflight identity: ${row.id}`);
      else failUnless(row.identity === stageIdentity(identity, {...stage, command: row.command, args: row.args}, fixtureIdentity(fixtureRoot, row.id)), `Fixture producer identity differs: ${row.id}`);
    } else failUnless(row.selected === false && row.result === 'not-run' && row.failed === null && row.status === null, `Unexpected non-preparation result: ${row.id}`);
  }
  const summary = Object.fromEntries(['not-run', 'pass', 'prepared', 'failed', 'blocked', 'deduplicated'].map(status => [status, rows.filter(row => row.result === status).length]));
  failUnless(equal(meta.summary, summary), 'Preparation summary differs from exact results');
  for (const relative of ['project.godot', '.validation/media-prepared.json', '.godot/global_script_class_cache.cfg', '.godot/uid_cache.bin']) regular(path.join(project, relative));
  directory(path.join(project, '.godot/imported'));
  return engineIdentity(meta);
}
function trackedTree(root) {
  const output = execFileSync('git', ['ls-tree', '-rz', '--full-tree', 'HEAD'], {cwd: root, encoding: 'utf8', maxBuffer: 32 * 1024 * 1024});
  return new Map(output.split('\0').filter(Boolean).map(line => {
    const split = line.indexOf('\t'), [mode, type, blob] = line.slice(0, split).split(' ');
    return [line.slice(split + 1), {mode, type, blob}];
  }));
}
function referencePlan(root, files) {
  const tracked = trackedTree(root), cache = new Map();
  const logicalNames = new Set(files.map(file => file.path));
  for (const name of tracked.keys()) if (name.startsWith('godot_native/') && !excluded(name.slice('godot_native/'.length))) failUnless(logicalNames.has(name), `Logical inventory omits tracked native file: ${name}`);
  function sourceInfo(relative) {
    if (cache.has(relative)) return cache.get(relative);
    failUnless(safeName(relative), 'Unsafe reference source path');
    const tree = tracked.get(relative);
    failUnless(tree?.type === 'blob' && ['100644', '100755'].includes(tree.mode), `Reference source is not a checked-in regular file: ${relative}`);
    const file = safeAbsolute(path.join(root, relative)), stat = regular(file);
    const sha256 = createHash('sha256'), gitHash = createHash('sha1').update(`blob ${stat.size}\0`);
    const fd = fs.openSync(file, 'r'), buffer = Buffer.alloc(1024 * 1024);
    try {let size; while ((size = fs.readSync(fd, buffer, 0, buffer.length, null))) {sha256.update(buffer.subarray(0, size)); gitHash.update(buffer.subarray(0, size));}}
    finally {fs.closeSync(fd);}
    failUnless(gitHash.digest('hex') === tree.blob && ((stat.mode & 0o111) ? '100755' : '100644') === tree.mode, `Reference source bytes/mode differ from committed Git blob: ${relative}`);
    const result = {path: relative, bytes: stat.size, sha256: sha256.digest('hex'), mode: stat.mode & 0o777, gitBlob: tree.blob};
    cache.set(relative, result); return result;
  }
  const manifest = sourceInfo(ASSET_MANIFEST), data = readJson(path.join(root, ASSET_MANIFEST));
  failUnless(Array.isArray(data.assets) && data.assetCount === data.assets.length && data.totalBytes === data.assets.reduce((sum, row) => sum + row.bytes, 0), 'Invalid checked-in source asset manifest');
  const aliases = new Map();
  for (const row of data.assets) {
    failUnless(safeName(row.path) && row.path.startsWith('assets/') && Number.isSafeInteger(row.bytes) && row.bytes >= 0 && sha(row.sha256)
      && !aliases.has(`godot_native/${row.path}`), 'Invalid or duplicate source asset manifest entry');
    aliases.set(`godot_native/${row.path}`, row);
    failUnless(logicalNames.has(`godot_native/${row.path}`), `Logical inventory omits synced source asset: ${row.path}`);
  }
  const planned = files.map(file => {
    if (!file.path.startsWith('godot_native/')) return {...file, reference: undefined};
    let reference;
    if (tracked.has(file.path)) {
      reference = {kind: 'checkout', ...sourceInfo(file.path)};
      failUnless(reference.bytes === file.bytes && reference.sha256 === file.sha256 && reference.mode === file.mode, `Tracked native input differs from exact checkout: ${file.path}`);
    } else if (aliases.has(file.path)) {
      const alias = aliases.get(file.path);
      failUnless(alias.bytes === file.bytes && alias.sha256 === file.sha256, `Synced asset differs from checked-in manifest: ${file.path}`);
      reference = {kind: 'synced-asset', ...sourceInfo(`src/${alias.path}`)};
      failUnless(reference.bytes === file.bytes && reference.sha256 === file.sha256, `Synced asset reference bytes differ: ${file.path}`);
    }
    return {...file, reference};
  });
  return {files: planned, referenceManifest: manifest};
}
function copyInventory(from, to, all, referenceRoot = null, payloadPrefix = '') {
  fs.mkdirSync(to);
  for (const entry of all.directories) fs.mkdirSync(path.join(to, entry.path), {recursive: true});
  for (const entry of all.files) {
    const source = entry.reference ? path.join(referenceRoot, entry.reference.path) : path.join(from, payloadPrefix + entry.path);
    fs.copyFileSync(source, path.join(to, entry.path)); fs.chmodSync(path.join(to, entry.path), entry.mode);
  }
  for (const entry of [...all.directories].reverse()) fs.chmodSync(path.join(to, entry.path), entry.mode);
}
function stats(files) {
  const logicalBytes = files.reduce((sum, file) => sum + file.bytes, 0), payloadBytes = files.filter(file => !file.reference).reduce((sum, file) => sum + file.bytes, 0);
  return {fileCount: files.length, totalBytes: logicalBytes, logicalBytes, payloadBytes, referenceBytes: logicalBytes - payloadBytes, referenceCount: files.filter(file => file.reference).length};
}
export function createBundle({root, bundleDir, preparationReport, expected}) {
  const started = Date.now();
  root = checkout(root, expected); bundleDir = locations(root, bundleDir);
  failUnless(!fs.existsSync(bundleDir), 'Bundle destination must not exist');
  preparationReport = safeAbsolute(preparationReport); regular(preparationReport); regular(safeAbsolute(`${preparationReport}.meta.json`));
  const reportBytes = fs.readFileSync(preparationReport), metaBytes = fs.readFileSync(`${preparationReport}.meta.json`);
  const rows = JSON.parse(reportBytes), meta = JSON.parse(metaBytes), project = path.join(root, 'godot_native');
  failUnless(meta.identity?.root === fs.realpathSync(root), 'Preparation ran in a different checkout');
  const engine = validatePreparation({rows, meta, project, expected});
  const extraExcludes = inside(root, preparationReport) ? [path.relative(root, preparationReport), path.relative(root, `${preparationReport}.meta.json`)] : [];
  const currentIdentity = validationIdentity(root, {executable: process.env.GODOT_BIN || 'godot', jobs: meta.jobs, extraExcludes});
  failUnless(equal(meta.identity.input, currentIdentity.input), 'Preparation input files changed after validation');
  const original = inventory(project, {project: true});
  const planned = referencePlan(root, original.files.map(file => ({...file, path: `godot_native/${file.path}`})));
  fs.mkdirSync(bundleDir, {recursive: true});
  try {
    const payloadFiles = planned.files.filter(file => !file.reference).map(file => ({...file, path: file.path.slice('godot_native/'.length)}));
    const payload = {files: payloadFiles, directories: original.directories.filter(dir => payloadFiles.some(file => file.path.startsWith(`${dir.path}/`)))};
    copyInventory(project, path.join(bundleDir, 'godot_native'), payload);
    failUnless(equal(original, inventory(project, {project: true})) && equal(plain(payload), inventory(path.join(bundleDir, 'godot_native'))), 'Prepared inputs changed during freeze');
    failUnless(equal(meta.identity.input, validationIdentity(root, {executable: process.env.GODOT_BIN || 'godot', jobs: meta.jobs, extraExcludes}).input), 'Preparation input files changed during freeze');
    fs.writeFileSync(path.join(bundleDir, 'preparation-report.json'), reportBytes);
    fs.writeFileSync(path.join(bundleDir, 'preparation-meta.json'), metaBytes);
    const source = sourceFor(expected);
    fs.writeFileSync(path.join(bundleDir, 'ci-source.json'), JSON.stringify(source, null, 2) + '\n');
    const physical = inventory(bundleDir);
    const all = {files: [...planned.files, ...physical.files.filter(file => !file.path.startsWith('godot_native/'))].sort((a, b) => a.path.localeCompare(b.path, 'en')),
      directories: [{path: 'godot_native', mode: fs.statSync(project).mode & 0o777}, ...original.directories.map(dir => ({...dir, path: `godot_native/${dir.path}`}))].sort((a, b) => a.path.localeCompare(b.path, 'en'))};
    const totals = stats(all.files), bundleName = `godot-native-inputs-${expected.run}-${expected.attempt}`;
    const receipt = {schema: SCHEMA, bundleName, source, producerAttempt: expected.attempt, engine, referenceManifest: planned.referenceManifest,
      preparation: {ids: PREPARATION_IDS, reportSha256: digest(reportBytes), metaSha256: digest(metaBytes), identitySha256: meta.identity.sha256, inputSha256: meta.identity.input.sha256,
        fixtureSha256: fixtureIdentity(root)}, ...totals, ...all};
    // Same verification view as consumers; never trust unchecked omitted files.
    validateReferences(root, receipt);
    withValidationView(root, bundleDir, receipt, view => {
      failUnless(fixtureIdentity(view) === receipt.preparation.fixtureSha256, 'Producer fixtures changed during freeze');
    });
    const bytes = JSON.stringify(receipt, null, 2) + '\n';
    fs.writeFileSync(path.join(bundleDir, RECEIPT), bytes); checkout(root, expected);
    return {bundleName, receiptSha: digest(bytes), producerAttempt: expected.attempt, engine, ...totals, receiptBytes: Buffer.byteLength(bytes),
      transportBytes: totals.payloadBytes + Buffer.byteLength(bytes), durationMs: Date.now() - started};
  } catch (error) {fs.rmSync(bundleDir, {recursive: true, force: true}); throw error;}
}
function validateInventory(receipt, observed) {
  failUnless(Array.isArray(receipt.files) && Array.isArray(receipt.directories), 'Missing payload inventory');
  for (const entry of [...receipt.files, ...receipt.directories]) failUnless(safeName(entry.path) && Number.isInteger(entry.mode) && entry.mode >= 0 && entry.mode <= 0o777, 'Unsafe receipt path/mode');
  const fileNames = receipt.files.map(file => file.path), directoryNames = receipt.directories.map(entry => entry.path);
  failUnless(equal(fileNames, sorted(new Set(fileNames))) && equal(directoryNames, sorted(new Set(directoryNames))) && fileNames.every(name => !directoryNames.includes(name)), 'Logical inventory must be unique, sorted, and unambiguous');
  for (const file of receipt.files) failUnless(Number.isSafeInteger(file.bytes) && file.bytes >= 0 && sha(file.sha256)
    && (file.path.startsWith('godot_native/') || ['ci-source.json', 'preparation-report.json', 'preparation-meta.json'].includes(file.path)), 'Invalid logical file path/size/SHA');
  for (const file of receipt.files) if (Object.hasOwn(file, 'reference')) {
    const ref = file.reference;
    failUnless(ref && ['checkout', 'synced-asset'].includes(ref.kind) && safeName(ref.path) && ref.bytes === file.bytes && ref.sha256 === file.sha256
      && Number.isInteger(ref.mode) && ref.mode >= 0 && ref.mode <= 0o777 && commit(ref.gitBlob), 'Invalid source reference path/bytes/hash/mode');
  }
  for (const dir of receipt.directories) failUnless(dir.path === 'godot_native' || dir.path.startsWith('godot_native/'), 'Invalid logical directory path');
  for (const entry of [...receipt.files, ...receipt.directories]) {
    if (entry.path.startsWith('godot_native/')) failUnless(!excluded(entry.path.slice('godot_native/'.length)), 'Excluded path in prepared payload');
    const parent = path.posix.dirname(entry.path); failUnless(parent === '.' || directoryNames.includes(parent), 'Missing logical parent directory');
  }
  const physicalFiles = receipt.files.filter(file => !file.reference);
  const physicalDirectories = receipt.directories.filter(dir => physicalFiles.some(file => file.path.startsWith(`${dir.path}/`)));
  failUnless(equal(withoutModes({files: physicalFiles, directories: physicalDirectories}), withoutModes(observed)), 'Bundle file set, size, or SHA differs (extra, missing, or modified input)');
  const totals = stats(receipt.files);
  failUnless(Object.entries(totals).every(([key, value]) => receipt[key] === value), 'Bundle totals differ');
  return totals;
}
function validateReferences(root, receipt) {
  const planned = referencePlan(root, plain(receipt).files);
  failUnless(equal(planned.referenceManifest, receipt.referenceManifest), 'Checked-in reference manifest bytes/mode differ');
  failUnless(equal(planned.files.map(file => file.reference || null), receipt.files.map(file => file.reference || null)), 'Missing, mutated, or wrong-path source reference');
}
function restoreProject(root, bundleDir, receipt) {
  const project = path.join(root, 'godot_native');
  inventory(project, {project: true}); // Reject existing links; leave no stale generated files.
  const prefix = 'godot_native/';
  const payload = Object.fromEntries(['files', 'directories'].map(key => [key, receipt[key].filter(entry => entry.path.startsWith(prefix)).map(entry => ({...entry, path: entry.path.slice(prefix.length)}))]));
  const temporary = fs.mkdtempSync(path.join(path.dirname(root), '.755-native-restore-'));
  const staged = path.join(temporary, 'prepared'), backup = path.join(temporary, 'previous');
  let moved = false, installed = false;
  try {
    copyInventory(bundleDir, staged, payload, root, prefix);
    failUnless(equal(plain(payload), inventory(staged)), 'Restored project differs from verified bytes/modes');
    fs.renameSync(project, backup); moved = true;
    fs.renameSync(staged, project); installed = true;
  } catch (error) {
    if (installed) fs.rmSync(project, {recursive: true, force: true});
    if (moved) fs.renameSync(backup, project);
    throw error;
  } finally {fs.rmSync(temporary, {recursive: true, force: true});}
}
function withValidationView(root, bundleDir, receipt, run) {
  // Verification needs the real catalog/test bytes and fixed fixtures, not a
  // second multi-GB import tree. Every omitted source was already hash-verified.
  const mandatory = new Set(['godot_native/project.godot', 'godot_native/.validation/media-prepared.json', 'godot_native/.godot/global_script_class_cache.cfg', 'godot_native/.godot/uid_cache.bin', ...Object.values(PRODUCER_OUTPUTS).flat()]);
  const files = receipt.files.filter(file => file.path.startsWith('godot_native/tests/') || mandatory.has(file.path));
  const directories = receipt.directories.filter(dir => dir.path === 'godot_native/.godot/imported' || files.some(file => file.path.startsWith(`${dir.path}/`)));
  const temporary = fs.mkdtempSync(path.join(os.tmpdir(), '755-native-input-verification-')), view = path.join(temporary, 'view');
  try {
    copyInventory(bundleDir, view, {files, directories}, root);
    failUnless(equal(plain({files, directories}), inventory(view)), 'Verification view differs from sealed logical inputs');
    return run(view);
  } finally {fs.rmSync(temporary, {recursive: true, force: true});}
}
export function verifyBundle({root, bundleDir, receiptSha, producerAttempt, expected, restore = false, outputReceipt}) {
  const started = Date.now();
  root = checkout(root, expected); bundleDir = locations(root, bundleDir); directory(bundleDir);
  failUnless(sha(receiptSha), 'Expected receipt SHA is required');
  failUnless(positive(producerAttempt) && Number(producerAttempt) <= Number(expected.attempt), 'Invalid or future producer attempt');
  failUnless(typeof restore === 'boolean', 'Restore must be boolean');
  if (outputReceipt) {outputReceipt = safeAbsolute(outputReceipt); failUnless(!inside(bundleDir, outputReceipt), 'Consumer receipt must be outside immutable bundle');}
  regular(path.join(bundleDir, RECEIPT));
  const bytes = fs.readFileSync(path.join(bundleDir, RECEIPT));
  failUnless(digest(bytes) === receiptSha, 'Bundle receipt SHA differs from trusted producer output');
  const receipt = JSON.parse(bytes);
  failUnless(equal(sorted(fs.readdirSync(bundleDir)), sorted([RECEIPT, 'godot_native', 'ci-source.json', 'preparation-report.json', 'preparation-meta.json'])), 'Unexpected or missing bundle root entry');
  const all = inventory(bundleDir, {skipReceipt: true}), totals = validateInventory(receipt, all);
  const source = sourceFor(expected, producerAttempt);
  failUnless(receipt.schema === SCHEMA && receipt.bundleName === `godot-native-inputs-${expected.run}-${producerAttempt}`
    && receipt.producerAttempt === producerAttempt && equal(receipt.source, source) && equal(readJson(path.join(bundleDir, 'ci-source.json')), source), 'Bundle source/run/producer attempt differs');
  validateReferences(root, receipt);
  const preparationRows = readJson(path.join(bundleDir, 'preparation-report.json'));
  const preparationMeta = readJson(path.join(bundleDir, 'preparation-meta.json'));
  const engine = withValidationView(root, bundleDir, receipt, fixtureRoot => {
    const value = validatePreparation({rows: preparationRows, meta: preparationMeta, project: path.join(fixtureRoot, 'godot_native'), expected, fixtureRoot});
    failUnless(equal(receipt.engine, value) && equal(receipt.preparation, {ids: PREPARATION_IDS,
      reportSha256: fileDigest(path.join(bundleDir, 'preparation-report.json')), metaSha256: fileDigest(path.join(bundleDir, 'preparation-meta.json')),
      identitySha256: preparationMeta.identity.sha256, inputSha256: preparationMeta.identity.input.sha256,
      fixtureSha256: fixtureIdentity(fixtureRoot)}), 'Preparation receipts/engine differ from frozen provenance');
    return value;
  });
  if (restore) {restoreProject(root, bundleDir, receipt); checkout(root, expected);}
  const result = {schema: '755-native-prepared-consumer-v2', verified: true, restored: restore, bundleName: receipt.bundleName, receiptSha,
    source, producerAttempt, consumerAttempt: expected.attempt, engine, ...totals, receiptBytes: bytes.length, transportBytes: totals.payloadBytes + bytes.length, durationMs: Date.now() - started,
    preparationRows, preparationMeta, preparedFixtureSha256: receipt.preparation.fixtureSha256,
    scope: 'Verified same-run prepared inputs; imported preparation results are not fresh consumer passes or full native acceptance.'};
  if (outputReceipt) {fs.mkdirSync(path.dirname(outputReceipt), {recursive: true}); fs.writeFileSync(outputReceipt, JSON.stringify(result, null, 2) + '\n');}
  return result;
}
function main() {
  const [command, ...args] = process.argv.slice(2), options = {};
  const shared = ['root', 'bundle-dir', 'head', 'base'];
  const required = command === 'create' ? ['preparation-report'] : command === 'restore' ? ['receipt-sha', 'producer-attempt', 'output-receipt'] : [];
  failUnless(required.length && args.length % 2 === 0, 'Usage: native_validation_bundle.mjs create|restore --root path --bundle-dir path --head SHA [--base SHA] ...');
  for (let index = 0; index < args.length; index += 2) {
    const key = args[index].replace(/^--/, '');
    failUnless(args[index].startsWith('--') && [...shared, ...required].includes(key) && !Object.hasOwn(options, key) && args[index + 1], `Unknown, duplicate, or incomplete option: ${args[index]}`);
    options[key] = args[index + 1];
  }
  failUnless(['root', 'bundle-dir', 'head', ...required].every(key => options[key]), 'Missing required bundle argument');
  const git = (...parameters) => execFileSync('git', parameters, {cwd: options.root, encoding: 'utf8'}).trim();
  const expected = {commit: process.env.GITHUB_SHA, tree: git('rev-parse', 'HEAD^{tree}'), head: options.head, base: options.base || null,
    event: process.env.GITHUB_EVENT_NAME, run: process.env.GITHUB_RUN_ID, attempt: process.env.GITHUB_RUN_ATTEMPT};
  const result = command === 'create' ? createBundle({root: options.root, bundleDir: options['bundle-dir'], preparationReport: options['preparation-report'], expected})
    : verifyBundle({root: options.root, bundleDir: options['bundle-dir'], receiptSha: options['receipt-sha'], producerAttempt: options['producer-attempt'], outputReceipt: options['output-receipt'], expected, restore: true});
  if (command === 'create' && process.env.GITHUB_OUTPUT) fs.appendFileSync(process.env.GITHUB_OUTPUT,
    `bundle_name=${result.bundleName}\nreceipt_sha=${result.receiptSha}\nproducer_attempt=${result.producerAttempt}\n`);
  const {preparationRows, preparationMeta, ...summary} = result;
  console.log(JSON.stringify(summary, null, 2));
}
if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) main();
