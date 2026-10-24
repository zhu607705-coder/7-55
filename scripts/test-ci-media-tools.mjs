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
for (const initial of [[0, 1], [1, 0], [1, 1]]) test(`missing tools ${initial}: primary acquisition and both final versions`, () => {
  const r = scenario({ initial });
  assert.ifError(r.error);
  assert.deepEqual(r.result, { installed: true, fallback: false });
  assert.deepEqual(r.calls.map(c => c.phase), ['ffmpeg', 'ffprobe', 'index', 'download', 'install', 'ffmpeg', 'ffprobe']);
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
test('primary timeout causes exactly one fallback with the stated wall clocks', () => {
  const r = scenario({ responses: { download1: 124 } });
  assert.ifError(r.error);
  assert.equal(r.result.fallback, true);
  assert.deepEqual(r.calls.filter(c => ['index', 'download'].includes(c.phase)).map(c => c.args.slice(0, 7)), [
    ['-n', 'timeout', '--signal=TERM', '--kill-after=10s', '60s', 'apt-get', '-o'],
    ['-n', 'timeout', '--signal=TERM', '--kill-after=10s', '120s', 'apt-get', '-o'],
    ['-n', 'timeout', '--signal=TERM', '--kill-after=10s', '60s', 'apt-get', '-o'],
    ['-n', 'timeout', '--signal=TERM', '--kill-after=10s', '180s', 'apt-get', '-o'],
  ]);
});
test('primary index failure skips its download, then acquires once from fallback', () => {
  const r = scenario({ responses: { index1: 100 } });
  assert.ifError(r.error);
  assert.deepEqual(r.calls.filter(c => c.command === 'sudo').map(c => c.phase), ['index', 'index', 'download', 'install']);
});
for (const failure of [100, 137]) test(`acquisition failure ${JSON.stringify(failure)} has one fallback`, () => {
  const r = scenario({ responses: { download1: failure } });
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
]) test(`executor/cancellation failure ${JSON.stringify(failure)} is fatal without another sudo`, () => {
  const r = scenario({ responses: { index1: failure } });
  assert.match(r.error?.message ?? '', /acquisition process failed.*no route retry/);
  assert.equal(r.calls.filter(c => c.command === 'sudo').length, 1);
  assert.equal(r.calls.filter(c => c.phase === 'install').length, 0);
});
for (const responses of [{ index1: 124, index2: 124 }, { download1: 124, download2: 100 }]) test(`fallback failure never installs: ${JSON.stringify(responses)}`, () => {
  const r = scenario({ responses });
  assert.match(r.error?.message ?? '', /both bounded acquisition attempts failed/);
  assert.equal(r.calls.filter(c => c.phase === 'index').length, 2);
  assert.equal(r.calls.filter(c => c.phase === 'install').length, 0);
});
for (const responses of [{ install1: 100 }, { download1: 124, install1: 100 }]) test(`install failure never retries or starts another fallback: ${JSON.stringify(responses)}`, () => {
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
test('fallback installation retains exact source options, never wraps dpkg in timeout', () => {
  const r = scenario({ responses: { download1: 124 }, inspect(call) {
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
  const optionPairs = c => c.args.filter(arg => arg.startsWith('Dir::Etc::'));
  assert.deepEqual(optionPairs(apt[0]), []);
  assert.deepEqual(optionPairs(apt.at(-1)), optionPairs(apt.at(-2)));
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
  for (const c of r.calls.filter(c => c.command === 'sudo')) {
    for (const value of ['APT::Get::AllowUnauthenticated=false', 'Acquire::AllowInsecureRepositories=false', 'Acquire::AllowDowngradeToInsecureRepositories=false', 'Acquire::https::Verify-Peer=true', 'Acquire::https::Verify-Host=true', 'Acquire::Check-Valid-Until=true']) assert(c.args.includes(value));
    if (c.phase === 'index') assert(c.args.includes('APT::Update::Error-Mode=any'));
    else assert(c.args.includes('--no-install-recommends'));
    assert(!c.args.includes('--ignore-missing'));
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
test('executor exception is fatal and cleans temporary files without retry', () => {
  const r = scenario({ responses: { index1: new Error('executor fixture fault') } });
  assert.match(r.error?.message ?? '', /executor fixture fault/);
  assert.equal(r.calls.filter(c => c.command === 'sudo').length, 1);
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
  assert.deepEqual(commands, ['node scripts/test-ci-media-tools.mjs', 'node scripts/ensure-ci-media-tools.mjs']);
  assert.match(text, acceptance);
  assert(text.indexOf('node scripts/ensure-ci-media-tools.mjs') < text.search(acceptance));
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
  assert.equal(commandCount(text), 5);
  assert.equal(commandCount(build), 2, 'original baseline and streaming gates remain');
  assert.equal(commandCount(profiles), 2, 'original world and phone gates remain');
  assert.equal(commandCount(library), 1, 'library is one additional consumer, not a replacement');
  assert(build.includes('--scenarios streaming'));
  for (const scenario of ['--scenarios mobile-world', '--scenarios phone-recovery']) assert(profiles.includes(scenario));
  assert(library.includes('--scenarios library --only "$ACCEPTANCE_PROFILE"'));
  for (const consumer of [profiles, library]) {
    assert.match(consumer, /needs: build/);
    assert.match(consumer, /needs\.build\.outputs\.bundle_ready == 'true'/);
    assert.match(consumer, /timeout-minutes: 12/);
    assert.match(consumer, /permissions:\n      contents: read/);
    assert.match(consumer, /fail-fast: false/);
    assert.match(consumer, /node godot_native\/tools\/web_acceptance_bundle\.mjs verify/);
    assert.doesNotMatch(consumer, /ensure-ci-media-tools|sudo |build_web\.mjs|continue-on-error|pages: write|id-token: write/);
  }
});
console.log(`CI media tools: ${passed} fixture tests passed; no real APT/network/browser execution.`);
