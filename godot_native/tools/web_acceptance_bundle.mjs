// Immutable CI transport only. This does not replace build or browser assertions.
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {execFileSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';

const SCHEMA = '755-godot-web-acceptance-bundle-v1';
const ENGINE = '4.7.1.stable.official';
const RECEIPT = 'bundle-receipt.json';
const digest = bytes => createHash('sha256').update(bytes).digest('hex');
const equal = (a, b) => JSON.stringify(a) === JSON.stringify(b);
function requireValue(condition, message) { if (!condition) throw Error(message); }
function sha(value) { return typeof value === 'string' && /^[a-f0-9]{64}$/.test(value); }
function commit(value) { return typeof value === 'string' && /^[a-f0-9]{40}$/.test(value); }
function positive(value) { return typeof value === 'string' && /^[1-9][0-9]*$/.test(value) && Number.isSafeInteger(Number(value)); }
function safeName(name) {
  return typeof name === 'string' && name.length > 0 && !/[\\\x00-\x1f\x7f]/.test(name)
    && !name.startsWith('/') && name.split('/').every(part => part !== '' && part !== '.' && part !== '..');
}
function fileHash(file) {
  const hash = createHash('sha256'), buffer = Buffer.alloc(1024 * 1024), fd = fs.openSync(file, 'r');
  try { let bytes; while ((bytes = fs.readSync(fd, buffer, 0, buffer.length, null))) hash.update(buffer.subarray(0, bytes)); }
  finally { fs.closeSync(fd); }
  return hash.digest('hex');
}
function inventory(directory, skipReceipt = false) {
  requireValue(fs.lstatSync(directory).isDirectory(), 'Bundle input must be a real directory');
  const files = [], directories = [];
  function walk(current, prefix = '') {
    for (const name of fs.readdirSync(current).sort((a, b) => a.localeCompare(b, 'en'))) {
      const relative = prefix ? `${prefix}/${name}` : name;
      requireValue(safeName(relative), `Unsafe bundle path: ${relative}`);
      const file = path.join(current, name), stat = fs.lstatSync(file);
      requireValue(!stat.isSymbolicLink(), `Symlink is not a bundle input: ${relative}`);
      if (stat.isDirectory()) { directories.push(relative); walk(file, relative); }
      else {
        requireValue(stat.isFile(), `Nonregular bundle input: ${relative}`);
        if (!(skipReceipt && relative === RECEIPT)) files.push({path: relative, bytes: stat.size, sha256: fileHash(file)});
      }
    }
  }
  walk(directory);
  return {files: files.sort((a, b) => a.path.localeCompare(b.path, 'en')), directories: directories.sort((a, b) => a.localeCompare(b, 'en'))};
}
function readJson(file) { return JSON.parse(fs.readFileSync(file, 'utf8')); }
function validateExpected(expected) {
  requireValue(expected && commit(expected.commit) && commit(expected.head) && commit(expected.tree), 'Invalid expected source SHA/tree');
  requireValue(expected.base === null || commit(expected.base), 'Invalid expected base SHA');
  requireValue(positive(expected.run) && positive(expected.attempt), 'Invalid expected run/attempt');
  requireValue(typeof expected.event === 'string' && expected.event.length > 0 && expected.dirty === false, 'Acceptance checkout must be clean');
}
function validateProvenance(directory, expected, producerAttempt) {
  validateExpected(expected);
  requireValue(positive(producerAttempt) && Number(producerAttempt) <= Number(expected.attempt), 'Invalid or future producer attempt');
  const source = readJson(path.join(directory, 'ci-source.json'));
  const expectedSource = {event: expected.event, head: expected.head, base: expected.base, checkedOutCommit: expected.commit,
    tree: expected.tree, run: expected.run, attempt: producerAttempt, dirty: false};
  requireValue(Object.keys(source).length === Object.keys(expectedSource).length && Object.entries(expectedSource).every(([key, value]) => source[key] === value), 'CI source provenance differs from expected checkout/run/producer attempt');
  const manifest = readJson(path.join(directory, 'web-release/build-manifest.json'));
  requireValue(manifest.schema === '7-55-godot-web-release/v1' && manifest.sourceCommit === expected.commit && manifest.sourceTree === expected.tree && manifest.sourceDirty === false && equal(manifest.sourceChanges, []), 'Build source provenance differs from clean checkout');
  requireValue(manifest.engine === ENGINE && manifest.runtime === 'godot-web' && manifest.production === true && manifest.storyOnly === true && manifest.threads === false && manifest.chapterShortcuts === false, 'Unverified production Godot 4.7.1 bundle');
  requireValue(manifest.bootChunks?.schema === '755-boot-chunks-v1' && manifest.delivery === 'chapter-content-packs' && manifest.content?.exactCoverage === true && Number.isInteger(manifest.content.packs) && manifest.content.packs > 0, 'Missing staged content provenance');
  requireValue(Number.isSafeInteger(manifest.initialPayloadBytes) && manifest.initialPayloadBytes > 0 && manifest.initialPayloadBytes <= 100_000_000, 'Initial payload budget exceeded');
  const inputs = readJson(path.join(directory, 'web-release/source-inputs.json'));
  requireValue(Array.isArray(inputs.files) && inputs.files.length > 0 && inputs.files.every(file => safeName(file.path) && Number.isSafeInteger(file.bytes) && file.bytes >= 0 && sha(file.sha256)), 'Invalid source-input inventory');
  const names = inputs.files.map(file => file.path);
  requireValue(new Set(names).size === names.length && equal(names, [...names].sort((a, b) => a.localeCompare(b, 'en'))), 'Source-input inventory must be unique and sorted');
  // Exact build_web.mjs sourceInventory digest, not a different canonicalization.
  const sourceInputSha256 = digest(JSON.stringify(inputs.files));
  requireValue(inputs.digest === sourceInputSha256 && manifest.sourceInputSha256 === sourceInputSha256 && manifest.sourceInputCount === inputs.files.length, 'Source-input SHA does not match build inventory');
  const site = inventory(path.join(directory, 'web-release')).files.filter(file => !['build-manifest.json', 'source-inputs.json', 'pack-inventory.json', '.nojekyll'].includes(path.posix.basename(file.path)));
  requireValue(Array.isArray(manifest.files) && equal([...manifest.files].sort((a, b) => a.path.localeCompare(b.path, 'en')), site), 'Site bytes differ from original build manifest');
  requireValue(manifest.totalPayloadBytes === site.reduce((sum, file) => sum + file.bytes, 0) && site.filter(file => file.path.startsWith('content/') && file.path.endsWith('.pck')).every(file => file.bytes <= 24_000_000), 'Payload total or deferred pack budget differs');
  const fixture = readJson(path.join(directory, 'controller-earned/fixture-provenance.json'));
  requireValue(equal(fixture.source, source), 'Earned fixture provenance differs from producer source');
  return {source, manifest, sourceInputSha256};
}
function validateRoot(directory) {
  const names = fs.readdirSync(directory).sort();
  requireValue(equal(names, ['ci-source.json', 'controller-earned', 'web-release', ...(names.includes(RECEIPT) ? [RECEIPT] : [])].sort()), 'Unexpected or missing bundle root entry');
}
function totals(files) {
  return {fileCount: files.length, totalBytes: files.reduce((sum, file) => sum + file.bytes, 0),
    siteBytes: files.filter(file => file.path.startsWith('web-release/')).reduce((sum, file) => sum + file.bytes, 0),
    fixtureBytes: files.filter(file => file.path.startsWith('controller-earned/')).reduce((sum, file) => sum + file.bytes, 0)};
}
function copyInputs(from, to) {
  const original = inventory(from);
  fs.mkdirSync(to);
  for (const directory of original.directories) fs.mkdirSync(path.join(to, directory), {recursive: true});
  for (const file of original.files) fs.copyFileSync(path.join(from, file.path), path.join(to, file.path));
  requireValue(equal(original, inventory(to)), 'Bundle inputs changed during copy');
}
export function createBundle({bundleDir, exportDir, fixturesDir, sourceFile, expected}) {
  validateExpected(expected);
  requireValue(!fs.existsSync(bundleDir), 'Bundle destination must not exist');
  requireValue(fs.lstatSync(sourceFile).isFile() && !fs.lstatSync(sourceFile).isSymbolicLink(), 'CI source must be a regular file');
  fs.mkdirSync(bundleDir, {recursive: true});
  copyInputs(exportDir, path.join(bundleDir, 'web-release'));
  copyInputs(fixturesDir, path.join(bundleDir, 'controller-earned'));
  fs.copyFileSync(sourceFile, path.join(bundleDir, 'ci-source.json'));
  validateRoot(bundleDir);
  const provenance = validateProvenance(bundleDir, expected, expected.attempt);
  const all = inventory(bundleDir), stats = totals(all.files);
  const bundleName = `godot-web-inputs-${expected.run}-${expected.attempt}`;
  const receipt = {schema: SCHEMA, bundleName, source: provenance.source, producerAttempt: expected.attempt,
    engine: ENGINE, sourceInputSha256: provenance.sourceInputSha256, ...stats, ...all};
  const bytes = JSON.stringify(receipt, null, 2) + '\n';
  fs.writeFileSync(path.join(bundleDir, RECEIPT), bytes);
  return {bundleName, receiptSha: digest(bytes), producerAttempt: expected.attempt, sourceInputSha256: provenance.sourceInputSha256,
    ...stats, receiptBytes: Buffer.byteLength(bytes), transportBytes: stats.totalBytes + Buffer.byteLength(bytes)};
}
export function verifyBundle({bundleDir, receiptSha, producerAttempt, expected, outputReceipt}) {
  validateExpected(expected);
  requireValue(sha(receiptSha), 'Expected receipt SHA is required');
  validateRoot(bundleDir);
  const receiptFile = path.join(bundleDir, RECEIPT), stat = fs.lstatSync(receiptFile);
  requireValue(stat.isFile() && !stat.isSymbolicLink(), 'Bundle receipt must be a regular file');
  const bytes = fs.readFileSync(receiptFile);
  requireValue(digest(bytes) === receiptSha, 'Bundle receipt SHA differs from trusted producer output');
  const receipt = JSON.parse(bytes);
  const provenance = validateProvenance(bundleDir, expected, producerAttempt);
  requireValue(receipt.schema === SCHEMA && receipt.bundleName === `godot-web-inputs-${expected.run}-${producerAttempt}` && receipt.producerAttempt === producerAttempt && equal(receipt.source, provenance.source) && receipt.engine === ENGINE && receipt.sourceInputSha256 === provenance.sourceInputSha256, 'Bundle receipt provenance differs from expected producer');
  const all = inventory(bundleDir, true), stats = totals(all.files);
  requireValue(equal(receipt.files, all.files) && equal(receipt.directories, all.directories), 'Bundle file set, size, or SHA differs (extra, missing, or modified input)');
  requireValue(Object.entries(stats).every(([key, value]) => receipt[key] === value), 'Bundle byte totals differ');
  const result = {schema: '755-godot-web-consumer-inputs-v1', verified: true, bundleName: receipt.bundleName, receiptSha,
    source: provenance.source, producerAttempt, consumerAttempt: expected.attempt, engine: ENGINE,
    sourceInputSha256: provenance.sourceInputSha256, ...stats, receiptBytes: bytes.length, transportBytes: stats.totalBytes + bytes.length,
    scope: 'Exact input-byte and provenance verification only; not browser gameplay acceptance.'};
  if (outputReceipt) {
    const relative = path.relative(path.resolve(bundleDir), path.resolve(outputReceipt));
    requireValue(relative.startsWith(`..${path.sep}`) || path.isAbsolute(relative), 'Consumer receipt must be outside immutable bundle');
    fs.mkdirSync(path.dirname(outputReceipt), {recursive: true});
    fs.writeFileSync(outputReceipt, JSON.stringify(result, null, 2) + '\n');
  }
  return result;
}
function cliExpected() {
  const git = (...args) => execFileSync('git', args, {encoding: 'utf8'}).trim();
  const checkedOut = git('rev-parse', 'HEAD');
  requireValue(checkedOut === process.env.GITHUB_SHA, 'Checkout differs from triggering merge SHA');
  return {commit: checkedOut, head: process.env.ACCEPTANCE_HEAD_SHA, base: process.env.ACCEPTANCE_BASE_SHA || null,
    tree: git('rev-parse', 'HEAD^{tree}'), run: process.env.GITHUB_RUN_ID, attempt: process.env.GITHUB_RUN_ATTEMPT,
    event: process.env.GITHUB_EVENT_NAME, dirty: git('status', '--porcelain', '--untracked-files=all') !== ''};
}
function main() {
  const [command, ...args] = process.argv.slice(2), options = {};
  const allowed = command === 'create' ? ['bundle-dir', 'export-dir', 'fixtures-dir', 'source'] : command === 'verify' ? ['bundle-dir', 'receipt-sha', 'producer-attempt', 'output-receipt'] : [];
  requireValue(allowed.length > 0 && args.length % 2 === 0, 'Usage: web_acceptance_bundle.mjs create|verify --option value');
  for (let index = 0; index < args.length; index += 2) {
    const key = args[index].replace(/^--/, '');
    requireValue(args[index].startsWith('--') && allowed.includes(key) && !Object.hasOwn(options, key) && args[index + 1], `Unknown, duplicate or incomplete option: ${args[index]}`);
    options[key] = args[index + 1];
  }
  requireValue(allowed.every(key => options[key]), 'Missing required bundle argument');
  const expected = cliExpected();
  const result = command === 'create'
    ? createBundle({bundleDir: options['bundle-dir'], exportDir: options['export-dir'], fixturesDir: options['fixtures-dir'], sourceFile: options.source, expected})
    : verifyBundle({bundleDir: options['bundle-dir'], receiptSha: options['receipt-sha'], producerAttempt: options['producer-attempt'], outputReceipt: options['output-receipt'], expected});
  if (command === 'create' && process.env.GITHUB_OUTPUT) fs.appendFileSync(process.env.GITHUB_OUTPUT,
    `bundle_name=${result.bundleName}\nreceipt_sha=${result.receiptSha}\nproducer_attempt=${result.producerAttempt}\nsource_input_sha=${result.sourceInputSha256}\n`);
  console.log(JSON.stringify(result, null, 2));
}
if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) main();
