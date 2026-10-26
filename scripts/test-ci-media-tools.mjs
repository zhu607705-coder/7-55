import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { chmodSync, existsSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { ensureCiMediaTools, prepareFallback } from './ensure-ci-media-tools.mjs';

// Pure local fixtures + injected process results. Never invoke the production CLI,
// actual apt/sudo/timeout, network, dpkg or a browser from this test.
const SOURCE = `# Public Ubuntu source; preserve comments and every other byte.\nTypes: deb\nURIs: mirror+file:/etc/apt/apt-mirrors.txt\nSuites: noble noble-updates noble-backports\nComponents: main universe restricted multiverse\nSigned-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg\n\nTypes: deb\nURIs: mirror+file:/etc/apt/apt-mirrors.txt\nSuites: noble-security\nComponents: main universe restricted multiverse\nSigned-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg\n`;
const MIRRORS = 'http://azure.archive.ubuntu.com/ubuntu/\tpriority:1\nhttps://archive.ubuntu.com/ubuntu/\tpriority:2\nhttps://security.ubuntu.com/ubuntu/\tpriority:3\n';
const TEMP_MIRROR = '/tmp/755-ci-media-fixture/mirrors.txt';
const hash = value => createHash('sha256').update(value).digest('hex');
const sourceOptions = call => call.args.filter(arg => arg.startsWith('Dir::Etc::'));
let passed = 0;
function test(name, body) { body(); passed += 1; console.log(`PASS ${name}`); }

function scenario({ initial = [1, 1], source = SOURCE, mirrors = MIRRORS, responses = {}, final = [0, 0], inspect } = {}) {
  const directory = mkdtempSync(join(tmpdir(), '755-ci-media-test-'));
  chmodSync(directory, 0o755);
  const sourcePath = join(directory, 'source.original');
  const mirrorPath = join(directory, 'mirrors.original');
  writeFileSync(sourcePath, source, { mode: 0o600 });
  writeFileSync(mirrorPath, mirrors, { mode: 0o600 });
  const originals = [sourcePath, mirrorPath].map(path => ({ bytes: readFileSync(path), mode: statSync(path).mode }));
  const calls = [], logs = [], counts = {};
  let result, error;
  const execute = (command, args) => {
    const phase = command === 'ffmpeg' || command === 'ffprobe' ? command : args.includes('--no-download') ? 'install' : args.includes('--download-only') ? 'download' : args.includes('update') ? 'index' : 'unexpected';
    const occurrence = counts[phase] = (counts[phase] ?? 0) + 1;
    const call = { command, args: [...args], phase, occurrence };
    calls.push(call);
    if (inspect) inspect(call, directory);
    const requested = responses[`${phase}${occurrence}`];
    if (requested instanceof Error) throw requested;
    if (Object.hasOwn(responses, `${phase}${occurrence}`) && typeof requested !== 'number') return requested;
    const toolIndex = ['ffmpeg', 'ffprobe'].indexOf(phase);
    const status = requested ?? (toolIndex < 0 ? 0 : (occurrence === 1 ? initial : final)[toolIndex]);
    return { status };
  };
  try {
    try { result = ensureCiMediaTools({ execute, sourcePath, mirrorPath, temporaryParent: directory, log: line => logs.push(line) }); }
    catch (failure) { error = failure; }
    for (let i = 0; i < originals.length; i += 1) {
      const path = [sourcePath, mirrorPath][i];
      assert.deepEqual(readFileSync(path), originals[i].bytes, 'original source bytes changed');
      assert.equal(statSync(path).mode, originals[i].mode, 'original permissions changed');
    }
    assert.deepEqual(readdirSync(directory).sort(), ['mirrors.original', 'source.original'], 'temporary files leaked');
    return { calls, logs, result, error };
  } finally { rmSync(directory, { recursive: true, force: true }); }
}

test('already available: both actual version commands, no APT or source reads', () => {
  const r = scenario({ initial: [0, 0], source: 'invalid', mirrors: 'invalid' });
  assert.deepEqual(r.result, { installed: false, fallback: false });
  assert.deepEqual(r.calls.map(c => [c.command, c.args]), [['ffmpeg', ['-version']], ['ffprobe', ['-version']]]);
});
test('available versions do not require any readable APT source paths', () => {
  const calls = [];
  const result = ensureCiMediaTools({
    execute: (command, args) => { calls.push([command, args]); return { status: 0 }; },
    sourcePath: '/nonexistent-755-media-source', mirrorPath: '/nonexistent-755-media-mirrors',
    temporaryParent: '/nonexistent-755-media-parent', log: () => {},
  });
  assert.deepEqual(result, { installed: false, fallback: false });
  assert.deepEqual(calls, [['ffmpeg', ['-version']], ['ffprobe', ['-version']]]);
});
for (const initial of [[0, 1], [1, 0], [1, 1]]) test(`missing tools ${initial}: HTTPS first, no original acquisition, both final versions`, () => {
  const r = scenario({ initial });
  assert.ifError(r.error);
  assert.deepEqual(r.result, { installed: true, fallback: false });
  assert.deepEqual(r.calls.map(c => c.phase), ['ffmpeg', 'ffprobe', 'index', 'download', 'install', 'ffmpeg', 'ffprobe']);
  const apt = r.calls.filter(c => c.command === 'sudo');
  assert.equal(sourceOptions(apt[0]).length, 2);
  for (const call of apt) assert.deepEqual(sourceOptions(call), sourceOptions(apt[0]));
  assert(apt[0].args.includes('60s'));
  assert(apt[1].args.includes('180s'));
  assert(!r.logs.some(line => line.includes('original APT configuration')));
});
for (const command of ['ffmpeg', 'ffprobe']) test(`${command} ENOENT allows normal tool installation`, () => {
  const r = scenario({ responses: { [`${command}1`]: { status: null, error: { code: 'ENOENT' } } } });
  assert.ifError(r.error);
  assert.equal(r.result.installed, true);
});
for (const failure of [
  { status: null, error: { code: 'EACCES' } },
  { status: null, error: { code: 'EPERM' } },
  { status: null, error: { code: 'EIO' } },
  { status: null, signal: 'SIGTERM' },
  { status: null, error: { code: 'ENOENT' }, signal: 'SIGTERM' },
  { status: null }, {}, null, undefined, 'invalid',
]) for (const command of ['ffmpeg', 'ffprobe']) test(`${command} executor failure ${JSON.stringify(failure)} never invokes APT`, () => {
  const r = scenario({ responses: { [`${command}1`]: failure } });
  assert.match(r.error?.message ?? '', /version process failed; installation not permitted/);
  assert.equal(r.calls.filter(c => c.command === 'sudo').length, 0);
});
test('HTTPS timeout causes exactly one original-route fallback with unchanged route wall clocks', () => {
  const r = scenario({ responses: { download1: 124 } });
  assert.ifError(r.error);
  assert.equal(r.result.fallback, true);
  assert.deepEqual(r.calls.filter(c => ['index', 'download'].includes(c.phase)).map(c => c.args.slice(0, 7)), [
    ['-n', 'timeout', '--signal=TERM', '--kill-after=10s', '60s', 'apt-get', '-o'],
    ['-n', 'timeout', '--signal=TERM', '--kill-after=10s', '180s', 'apt-get', '-o'],
    ['-n', 'timeout', '--signal=TERM', '--kill-after=10s', '60s', 'apt-get', '-o'],
    ['-n', 'timeout', '--signal=TERM', '--kill-after=10s', '120s', 'apt-get', '-o'],
  ]);
  const apt = r.calls.filter(c => c.command === 'sudo');
  assert.equal(sourceOptions(apt[0]).length, 2);
  assert.deepEqual(sourceOptions(apt[1]), sourceOptions(apt[0]));
  for (const call of apt.slice(2)) assert.deepEqual(sourceOptions(call), []);
  const routes = r.logs.filter(line => line.includes(' index (60s)'));
  assert.match(routes[0], /existing official HTTPS mirrors only/);
  assert.match(routes[1], /original APT configuration/);
});
test('HTTPS index failure skips its download, then acquires once from original configuration', () => {
  const r = scenario({ responses: { index1: 100 } });
  assert.ifError(r.error);
  assert.deepEqual(r.calls.filter(c => c.command === 'sudo').map(c => c.phase), ['index', 'index', 'download', 'install']);
});
for (const failure of [100, 124, 137]) for (const phase of ['index', 'download']) test(`${phase} acquisition failure ${failure} has one original-route fallback`, () => {
  const r = scenario({ responses: { [`${phase}1`]: failure } });
  assert.ifError(r.error);
  assert.equal(r.calls.filter(c => c.phase === 'index').length, 2);
  assert.equal(r.calls.filter(c => c.phase === 'install').length, 1);
});
for (const failure of [
  1, 2, 125, 126, 127,
  { status: null },
  { status: null, signal: 'SIGTERM' },
  { status: 137, signal: 'SIGKILL' },
  { status: null, error: new Error('spawn failed') },
  { status: null, error: Object.assign(new Error('permission denied'), { code: 'EACCES' }) },
  { status: null, error: Object.assign(new Error('operation not permitted'), { code: 'EPERM' }) },
  { status: null, error: Object.assign(new Error('executor missing'), { code: 'ENOENT' }) },
  { status: 100, error: Object.assign(new Error('permission denied'), { code: 'EACCES' }) },
  { status: 124, signal: 'SIGTERM' },
  { status: 137, error: { code: 'EPERM' } },
  {}, null, undefined, 'invalid', { status: '100' },
]) for (const phase of ['index', 'download']) for (const route of [1, 2]) test(`route ${route} ${phase} executor/cancellation failure ${JSON.stringify(failure)} is fatal without another sudo`, () => {
  const responses = route === 1 ? {} : { index1: 100 };
  responses[`${phase}${route === 2 && phase === 'download' ? 1 : route}`] = failure;
  const r = scenario({ responses });
  assert.match(r.error?.message ?? '', /acquisition process failed.*no route retry/);
  assert.equal(r.calls.filter(c => c.command === 'sudo').length, route + (phase === 'download' ? 1 : 0));
  assert.equal(r.calls.at(-1).phase, phase);
  assert.equal(r.calls.filter(c => c.phase === 'install').length, 0);
});
for (const failure of [100, 124, 137]) for (const responses of [{ index1: 124, index2: failure }, { download1: 124, download2: failure }]) test(`original fallback failure never installs: ${JSON.stringify(responses)}`, () => {
  const r = scenario({ responses });
  assert.match(r.error?.message ?? '', /both bounded acquisition attempts failed/);
  assert.equal(r.calls.filter(c => c.phase === 'index').length, 2);
  assert.equal(r.calls.filter(c => c.phase === 'install').length, 0);
});
for (const failure of [100, 124, 137, { status: null, signal: 'SIGTERM' }, { status: 0, error: { code: 'EPERM' } }, null])
for (const responses of [{ install1: failure }, { download1: 124, install1: failure }]) test(`install failure never retries or starts another fallback: ${JSON.stringify(responses)}`, () => {
  const r = scenario({ responses });
  assert.match(r.error?.message ?? '', /installation failed; not retried/);
  assert.equal(r.calls.at(-1).phase, 'install');
  assert.equal(r.calls.filter(c => c.phase === 'install').length, 1);
});
for (const final of [[1, 0], [0, 1]]) test(`post-install version failure ${final} is fatal`, () => {
  const r = scenario({ final });
  assert.match(r.error?.message ?? '', /version check failed/);
  assert.equal(r.calls.filter(c => c.phase === 'install').length, 1);
});
for (const command of ['ffmpeg', 'ffprobe']) for (const failure of [{ status: null, signal: 'SIGTERM' }, { status: null, error: { code: 'EACCES' } }]) test(`post-install ${command} executor failure never re-enters acquisition`, () => {
  const r = scenario({ responses: { [`${command}2`]: failure } });
  assert.match(r.error?.message ?? '', /version process failed; installation not permitted/);
  assert.deepEqual(r.calls.filter(c => c.command === 'sudo').map(c => c.phase), ['index', 'download', 'install']);
});
for (const responses of [{}, { download1: 124 }]) test(`each route installs only with its acquired source options, never wraps dpkg in timeout: ${JSON.stringify(responses)}`, () => {
  const r = scenario({ responses, inspect(call) {
    const sourceArg = call.args.find(arg => arg.startsWith('Dir::Etc::sourcelist='));
    if (!sourceArg) return;
    const path = sourceArg.split('=')[1];
    const parts = call.args.find(arg => arg.startsWith('Dir::Etc::sourceparts=')).split('=')[1];
    assert.deepEqual(readdirSync(parts), []);
    assert.equal(statSync(path).mode & 0o777, 0o644);
    assert.equal(statSync(parts).mode & 0o777, 0o755);
    const text = readFileSync(path, 'utf8');
    const mirror = /^URIs: mirror\+file:(.+)$/m.exec(text)[1];
    assert.equal(statSync(mirror).mode & 0o777, 0o644);
    assert.equal(statSync(join(path, '..')).mode & 0o777, 0o755);
    assert.equal(text.replaceAll(`mirror+file:${mirror}`, 'mirror+file:/etc/apt/apt-mirrors.txt'), SOURCE);
    assert.equal(readFileSync(mirror, 'utf8'), MIRRORS.split('\n').slice(1).join('\n'));
  } });
  assert.ifError(r.error);
  const apt = r.calls.filter(c => c.command === 'sudo');
  assert.equal(sourceOptions(apt[0]).length, 2);
  assert.deepEqual(sourceOptions(apt.at(-1)), sourceOptions(apt.at(-2)));
  assert.equal(sourceOptions(apt.at(-1)).length, Object.hasOwn(responses, 'download1') ? 0 : 2);
  const install = apt.at(-1);
  assert.deepEqual(install.args.slice(0, 2), ['-n', 'apt-get']);
  assert(!install.args.includes('timeout'));
  assert(install.args.includes('--no-download'));
});
test('public temporary permissions remain correct under restrictive umask', () => {
  const previous = process.umask(0o077);
  try {
    const r = scenario({ responses: { index1: 100 }, inspect(call) {
      const arg = call.args.find(arg => arg.startsWith('Dir::Etc::sourcelist='));
      if (arg) assert.equal(statSync(arg.split('=')[1]).mode & 0o777, 0o644);
    } });
    assert.ifError(r.error);
  } finally { process.umask(previous); }
});
test('all APT invocations preserve authentication; update fails on any index error', () => {
  const r = scenario({ responses: { download1: 124 } });
  assert.ifError(r.error);
  for (const c of r.calls.filter(c => c.command === 'sudo')) {
    for (const value of ['APT::Get::AllowUnauthenticated=false', 'Acquire::AllowInsecureRepositories=false', 'Acquire::AllowDowngradeToInsecureRepositories=false', 'Acquire::https::Verify-Peer=true', 'Acquire::https::Verify-Host=true', 'Acquire::Check-Valid-Until=true', 'Acquire::Check-Date=true']) {
      assert.deepEqual(c.args.filter(arg => arg.startsWith(`${value.split('=')[0]}=`)), [value]);
      assert.equal(c.args[c.args.indexOf(value) - 1], '-o');
    }
    if (c.phase === 'index') assert(c.args.includes('APT::Update::Error-Mode=any'));
    else assert(c.args.includes('--no-install-recommends'));
    for (const flag of ['--ignore-missing', '--allow-unauthenticated', '--allow-insecure-repositories']) assert(!c.args.includes(flag));
  }
});
test('source hash and approved HTTPS only are logged, not source comments or vendor config', () => {
  const r = scenario();
  assert(r.logs.some(line => line.includes(hash(SOURCE)) && line.includes(hash(MIRRORS))));
  assert(!r.logs.join('\n').includes('Public Ubuntu source'));
});
for (const [name, source] of Object.entries({
  'new source URI': SOURCE.replaceAll('mirror+file:/etc/apt/apt-mirrors.txt', 'https://example.com/ubuntu/'),
  'unsigned': SOURCE.replaceAll('Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg\n', ''),
  'different signing key': SOURCE.replaceAll('ubuntu-archive-keyring.gpg', 'other-keyring.gpg'),
  'trusted yes': SOURCE + 'Trusted: yes\n',
  'allow insecure': SOURCE + 'Allow-Insecure: yes\n',
  'disable expiry': SOURCE + 'Check-Valid-Until: no\n',
  'embedded key': SOURCE.replaceAll('/usr/share/keyrings/ubuntu-archive-keyring.gpg', '\n -----BEGIN PGP PUBLIC KEY BLOCK-----'),
  'duplicate field': SOURCE + 'Types: deb\n',
  'unknown field': SOURCE + 'Unknown: value\n',
  'mixed releases': SOURCE.replace('noble-security', 'jammy-security'),
  'unknown pocket': SOURCE.replace('noble-security', 'noble-proposed'),
  'partly unreplaceable URI': SOURCE.replace('URIs: mirror+file:/etc/apt/apt-mirrors.txt\n', 'URIs: mirror+file:/etc/apt/apt-mirrors.txt\u00a0\n'),
  'missing security pocket': SOURCE.replace('Suites: noble-security', 'Suites: noble'),
  'foreign component': SOURCE.replaceAll('multiverse', 'foreign'),
  'wrong architecture': SOURCE + 'Architectures: arm64\n',
  'continuation field': SOURCE.replace('Suites: noble noble-updates', 'Suites: noble\n noble-updates'),
  'control character': SOURCE + '\0',
  'invalid UTF-8': Buffer.from([0xff, 0xfe]),
  'legacy sources.list shape': 'deb http://archive.ubuntu.com/ubuntu/ noble main universe\n',
})) test(`reject ${name} before any APT command`, () => {
  const r = scenario({ source });
  assert(r.error);
  assert.equal(r.calls.filter(c => c.command === 'sudo').length, 0);
});
for (const [name, mirrors] of Object.entries({
  'new host': MIRRORS + 'https://example.com/ubuntu/\tpriority:2\n',
  'new protocol': MIRRORS.replace('https://archive.', 'http://archive.'),
  'credentials': MIRRORS.replace('https://archive.', 'https://user:password@archive.'),
  'missing existing official route': MIRRORS.split('\n').slice(0, 2).join('\n'),
  'duplicate mirror': MIRRORS + MIRRORS.split('\n')[1] + '\n',
  'invalid UTF-8': Buffer.from([0xff, 0xfe]),
  'unknown priority': MIRRORS.replace('priority:2', 'priority:0'),
  'extra mirror metadata': MIRRORS.replace('priority:2', 'priority:2 trusted=yes'),
})) test(`reject mirror ${name}, never invent a fallback host`, () => {
  const r = scenario({ mirrors });
  assert(r.error);
  assert.equal(r.calls.filter(c => c.command === 'sudo').length, 0);
});
test('inverse replacement preserves CRLF, comments, tabs and final newline bytes', () => {
  const source = SOURCE.replace('Public Ubuntu source;', '注释 mirror+file:/etc/apt/apt-mirrors.txt;').replaceAll('URIs: ', 'URIs:\t').replaceAll('\n', '\r\n');
  const p = prepareFallback(source, MIRRORS, TEMP_MIRROR);
  assert.equal(p.stanzas, 2);
  assert.equal(p.source.replaceAll(`mirror+file:${TEMP_MIRROR}`, 'mirror+file:/etc/apt/apt-mirrors.txt'), source);
  assert(p.source.includes('# 注释 mirror+file:/etc/apt/apt-mirrors.txt;'));
});
test('existing release suites are preserved, not pinned or rewritten to Noble', () => {
  for (const codename of ['jammy', 'noble', 'resolute']) {
    const source = SOURCE.replaceAll('noble', codename);
    const p = prepareFallback(source, MIRRORS, TEMP_MIRROR);
    assert.equal(p.source.replaceAll(`mirror+file:${TEMP_MIRROR}`, 'mirror+file:/etc/apt/apt-mirrors.txt'), source);
  }
});
test('unsafe temporary URI or original mirror path is rejected', () => {
  for (const path of ['/tmp/has space', '/etc/apt/apt-mirrors.txt', 'relative', '/tmp/x\nTrusted: yes']) assert.throws(() => prepareFallback(SOURCE, MIRRORS, path));
});
for (const [phase, responses, aptCount] of [
  ['index', {}, 1], ['download', {}, 2], ['install', {}, 3],
  ['index', { download1: 124 }, 3], ['download', { download1: 124 }, 4], ['install', { download1: 124 }, 5],
]) test(`executor exception during ${phase} is fatal and cleans temporary files without retry (${aptCount} APT calls)`, () => {
  const occurrence = Object.hasOwn(responses, 'download1') && phase !== 'install' ? 2 : 1;
  const r = scenario({ responses: { ...responses, [`${phase}${occurrence}`]: new Error('executor fixture fault') } });
  assert.match(r.error?.message ?? '', /executor fixture fault/);
  assert.equal(r.calls.filter(c => c.command === 'sudo').length, aptCount);
  assert.equal(r.calls.at(-1).phase, phase);
});
test('module import did not invoke the real CLI', () => {
  assert.equal(typeof ensureCiMediaTools, 'function');
  assert.equal(typeof prepareFallback, 'function');
  assert.equal(existsSync('/tmp/755-ci-media-fixture'), false);
});
const WORKFLOWS = [
  ['web-ci.yml', /run: npm run validate:release/, /timeout-minutes: 20/],
  ['godot-native-ci.yml', /node godot_native\/tools\/validate_native\.mjs/],
  ['native-pr-integration.yml', /run: node scripts\/verify-native-pr-integration\.mjs --runtime/, /timeout-minutes: 25/],
  ['deploy-pages.yml', /run: node godot_native\/tools\/build_web\.mjs/, /timeout-minutes: 25/],
];
for (const [file, acceptance, budget] of WORKFLOWS) test(`${file}: helper fixture test precedes install; original gate remains`, () => {
  const text = readFileSync(new URL(`../.github/workflows/${file}`, import.meta.url), 'utf8');
  const commands = text.match(/^\s+node scripts\/(?:test|ensure)-ci-media-tools\.mjs\s*$/gm)?.map(line => line.trim());
  const parallelPreparation = ['godot-native-ci.yml', 'deploy-pages.yml'].includes(file);
  if (parallelPreparation) {
    assert.deepEqual(commands, ['node scripts/test-ci-media-tools.mjs']);
    const helper = readFileSync(new URL('../godot_native/tools/prepare_import_media.mjs', import.meta.url), 'utf8');
    assert.match(text, /node godot_native\/tools\/prepare_import_media\.mjs --install-media/);
    assert(helper.includes("path.join(root,'scripts/ensure-ci-media-tools.mjs')"));
    assert(helper.includes('"$1" "$2" && NODE_BIN="$1" bash "$3"'), 'original checked installer finishes before isolated conversion');
    assert(text.indexOf('prepare_import_media.mjs --install-media') < text.search(acceptance));
  } else {
    assert.deepEqual(commands, ['node scripts/test-ci-media-tools.mjs', 'node scripts/ensure-ci-media-tools.mjs']);
    assert(text.indexOf('node scripts/ensure-ci-media-tools.mjs') < text.search(acceptance));
  }
  assert.match(text, acceptance);
  if (budget) assert.match(text, budget);
  if (file !== 'web-ci.yml') {
    assert(text.includes("'scripts/ensure-ci-media-tools.mjs'"));
    assert(text.includes("'scripts/test-ci-media-tools.mjs'"));
  }
});
test('Godot Web baseline, streaming, profile and library commands retain bounded read-only consumers', () => {
  const text = readFileSync(new URL('../.github/workflows/deploy-pages.yml', import.meta.url), 'utf8');
  const build = text.split('  build:\n')[1].split('  browser_profiles:\n')[0];
  const profiles = text.split('  browser_profiles:\n')[1].split('  library_profiles:\n')[0];
  const library = text.split('  library_profiles:\n')[1].split('  deploy:\n')[0];
  const commandCount = value => (value.match(/node godot_native\/tools\/verify_web_export\.mjs/g) ?? []).length;
  assert.equal(commandCount(text), 8);
  assert.equal(commandCount(build), 3, 'original baseline, streaming and combined touch-phone gates remain');
  assert.equal(commandCount(profiles), 3, 'original world, combined phone and separate retina phone gates remain');
  assert.equal(commandCount(library), 2, 'both library profiles plus paired retina C1 retain separate invocations');
  assert(build.includes('--scenarios streaming'));
  for (const scenario of ['--scenarios mobile-world', '--scenarios phone-recovery']) assert(profiles.includes(scenario));
  assert(library.includes('--scenarios library --only "$ACCEPTANCE_PROFILE"'));
  for (const consumer of [profiles, library]) {
    assert.match(consumer, /needs: \[build, browser_contracts\]/);
    assert.match(consumer, /needs\.build\.outputs\.bundle_ready == 'true'/);
    assert.match(consumer, /timeout-minutes: 12/);
    assert.match(consumer, /permissions:\n      contents: read/);
    assert.match(consumer, /fail-fast: false/);
    assert.match(consumer, /node godot_native\/tools\/web_acceptance_bundle\.mjs verify/);
    assert.doesNotMatch(consumer, /ensure-ci-media-tools|sudo |build_web\.mjs|continue-on-error|pages: write|id-token: write/);
  }
});
console.log(`CI media tools: ${passed} fixture tests passed; no real APT/network/browser execution.`);
