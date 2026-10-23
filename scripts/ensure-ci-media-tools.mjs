import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { chmodSync, mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const SOURCE = '/etc/apt/sources.list.d/ubuntu.sources';
const MIRRORS = '/etc/apt/apt-mirrors.txt';
const MIRROR_URI = `mirror+file:${MIRRORS}`;
const KEYRING = '/usr/share/keyrings/ubuntu-archive-keyring.gpg';
const HTTPS_MIRRORS = ['https://archive.ubuntu.com/ubuntu/', 'https://security.ubuntu.com/ubuntu/'];
const KNOWN_MIRRORS = ['http://azure.archive.ubuntu.com/ubuntu/', ...HTTPS_MIRRORS];
const SECURITY = [
  '-o', 'APT::Get::AllowUnauthenticated=false',
  '-o', 'Acquire::AllowInsecureRepositories=false',
  '-o', 'Acquire::AllowDowngradeToInsecureRepositories=false',
  '-o', 'Acquire::https::Verify-Peer=true', '-o', 'Acquire::https::Verify-Host=true',
  '-o', 'Acquire::Check-Valid-Until=true', '-o', 'Acquire::Check-Date=true',
];

function requireCondition(condition, message) {
  if (!condition) throw new Error(`CI media tools: ${message}`);
}

// Only the public Ubuntu deb822 shape is accepted. No vendor sources,
// embedded keys, authentication, trust overrides or newly introduced mirrors.
export function prepareFallback(source, mirrors, temporaryMirrorPath) {
  requireCondition(typeof source === 'string' && !/[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/.test(source), 'invalid source text');
  requireCondition(/^\/[A-Za-z0-9_./-]+$/.test(temporaryMirrorPath) && temporaryMirrorPath !== MIRRORS, 'invalid temporary mirror path');
  const allowed = new Set(['Types', 'URIs', 'Suites', 'Components', 'Signed-By', 'Architectures']);
  const components = new Set(['main', 'restricted', 'universe', 'multiverse']);
  const seenSuites = new Set();
  let codename;
  let fields = new Map();
  let stanzas = 0;
  function finish() {
    if (fields.size === 0) return;
    for (const key of ['Types', 'URIs', 'Suites', 'Components', 'Signed-By']) requireCondition(fields.has(key), `source missing ${key}`);
    requireCondition(fields.get('Types') === 'deb', 'unsupported source Types');
    requireCondition(fields.get('URIs') === MIRROR_URI, 'unsupported source URI');
    requireCondition(fields.get('Signed-By') === KEYRING, 'unsupported signing keyring');
    requireCondition(!fields.has('Architectures') || fields.get('Architectures') === 'amd64', 'unsupported source architecture');
    for (const suite of fields.get('Suites').split(/\s+/)) {
      const match = /^([a-z][a-z0-9]*)(?:-(updates|backports|security))?$/.exec(suite);
      requireCondition(match, 'unsupported source suite');
      codename ??= match[1];
      requireCondition(match[1] === codename, 'mixed source releases');
      seenSuites.add(suite);
    }
    const entries = fields.get('Components').split(/\s+/);
    requireCondition(entries.includes('main') && entries.includes('universe') && entries.every(item => components.has(item)), 'unsupported source components');
    fields = new Map();
    stanzas += 1;
  }
  for (const line of source.split(/\r?\n/)) {
    if (line.trim() === '') { finish(); continue; }
    if (line.startsWith('#')) continue;
    const match = /^([A-Za-z-]+):[ \t]+([^\r\n]+)$/.exec(line);
    requireCondition(match && allowed.has(match[1]) && !fields.has(match[1]), 'unknown, duplicate or continued source field');
    fields.set(match[1], match[2].trim());
  }
  finish();
  requireCondition(stanzas > 0 && ['', '-updates', '-backports', '-security'].every(suffix => seenSuites.has(`${codename}${suffix}`)), 'incomplete Ubuntu source pockets');
  requireCondition(typeof mirrors === 'string', 'invalid mirror list');
  const selected = [];
  const seen = new Set();
  for (const raw of mirrors.split(/(?<=\n)/)) {
    const line = raw.replace(/\r?\n$/, '');
    if (line.trim() === '' || line.startsWith('#')) continue;
    const match = /^(\S+)[ \t]+priority:([1-3])$/.exec(line);
    requireCondition(match && KNOWN_MIRRORS.includes(match[1]) && !seen.has(match[1]), 'unknown or duplicate mirror');
    seen.add(match[1]);
    if (HTTPS_MIRRORS.includes(match[1])) selected.push(raw.endsWith('\n') ? raw : `${raw}\n`);
  }
  requireCondition(HTTPS_MIRRORS.every(uri => seen.has(uri)), 'official HTTPS fallback mirrors are not already present');
  const temporaryUri = `mirror+file:${temporaryMirrorPath}`;
  requireCondition(!source.includes(temporaryUri), 'temporary URI already present');
  // Replace only exact URIs field values, not comments or any other source bytes.
  let replacements = 0;
  const sourceCopy = source.replace(/^(URIs:[ \t]+)mirror\+file:\/etc\/apt\/apt-mirrors\.txt([ \t]*\r?)$/gm, (_, prefix, suffix) => { replacements += 1; return `${prefix}${temporaryUri}${suffix}`; });
  const inverse = sourceCopy.replaceAll(temporaryUri, MIRROR_URI);
  requireCondition(replacements === stanzas && inverse === source, 'source inverse replacement mismatch');
  return { source: sourceCopy, mirrors: selected.join(''), stanzas };
}

function readUtf8(path) {
  const bytes = readFileSync(path);
  const text = bytes.toString('utf8');
  requireCondition(Buffer.from(text, 'utf8').equals(bytes), 'source is not valid UTF-8');
  return text;
}

export function runCommand(command, args) {
  return spawnSync(command, args, { stdio: 'inherit' });
}

// Injectable executor keeps fault tests entirely local: importing this module never
// invokes sudo, apt, timeout or a browser. Only the direct CLI uses real commands.
export function ensureCiMediaTools({ execute = runCommand, sourcePath = SOURCE, mirrorPath = MIRRORS, temporaryParent = '/tmp', log = console.log } = {}) {
  const processResult = result => result !== null && typeof result === 'object' && !Array.isArray(result);
  const success = result => processResult(result) && result.status === 0 && result.error == null && result.signal == null;
  const version = command => {
    const result = execute(command, ['-version']);
    // ENOENT means missing, not denied. Never turn a permission/cancellation error
    // into an opportunity to invoke sudo and install a replacement executable.
    const missing = processResult(result) && result.error?.code === 'ENOENT' && result.status === null;
    const exited = processResult(result) && result.error == null && Number.isInteger(result.status) && result.status >= 0 && result.status <= 255;
    requireCondition(result?.signal == null && (missing || exited), `${command} version process failed; installation not permitted after executor error or signal`);
    return result;
  };
  const versions = () => {
    const ffmpeg = version('ffmpeg');
    const ffprobe = version('ffprobe');
    return success(ffmpeg) && success(ffprobe);
  };
  if (versions()) { log('CI media tools: ffmpeg and ffprobe versions verified (already available).'); return { installed: false, fallback: false }; }
  requireCondition(process.platform === 'linux' && process.arch === 'x64', 'APT bootstrap supports the current Linux x64 runner only');
  const source = readUtf8(sourcePath);
  const mirrors = readUtf8(mirrorPath);
  let directory;
  try {
    directory = mkdtempSync(join(temporaryParent, '755-ci-media-'));
    chmodSync(directory, 0o755);
    const temporaryMirrors = join(directory, 'mirrors.txt');
    const prepared = prepareFallback(source, mirrors, temporaryMirrors);
    log(`CI media tools: ${JSON.stringify({ sourceSha256: createHash('sha256').update(source).digest('hex'), mirrorListSha256: createHash('sha256').update(mirrors).digest('hex'), httpsMirrors: HTTPS_MIRRORS, imageVersion: process.env.ImageVersion ?? 'unknown', architecture: process.arch })}`);
    const temporarySource = join(directory, 'ubuntu.sources');
    const emptySources = join(directory, 'empty-sources');
    mkdirSync(emptySources, { mode: 0o755 });
    writeFileSync(temporarySource, prepared.source, { mode: 0o644 });
    writeFileSync(temporaryMirrors, prepared.mirrors, { mode: 0o644 });
    chmodSync(emptySources, 0o755);
    chmodSync(temporarySource, 0o644);
    chmodSync(temporaryMirrors, 0o644);
    const fallbackOptions = ['-o', `Dir::Etc::sourcelist=${temporarySource}`, '-o', `Dir::Etc::sourceparts=${emptySources}`];
    const network = (seconds, options, operation) => {
      const result = execute('sudo', ['-n', 'timeout', '--signal=TERM', '--kill-after=10s', `${seconds}s`, 'apt-get', ...SECURITY, ...options, ...operation]);
      log(`CI media tools: ${operation.includes('update') ? 'index' : 'download-only'} returned ${JSON.stringify({ status: result?.status ?? null, signal: result?.signal ?? null })}`);
      if (success(result)) return true;
      // A mirror cannot fix a cancelled process, sudo denial or broken executor.
      // Only APT acquisition failure and GNU timeout exits permit route failover.
      requireCondition(processResult(result) && result.error == null && result.signal == null && [100, 124, 137].includes(result.status), `acquisition process failed (status ${result?.status ?? 'none'}, signal ${result?.signal ?? 'none'}, error ${result?.error?.code ?? 'none'}); no route retry`);
      return false;
    };
    const acquire = (label, options, seconds) => {
      log(`CI media tools: ${label} index (60s) then download-only (${seconds}s); no dpkg timeout.`);
      return network(60, options, ['-o', 'APT::Update::Error-Mode=any', 'update'])
        && network(seconds, options, ['--yes', '--no-install-recommends', '--download-only', 'install', 'ffmpeg']);
    };
    let options = [];
    let fallback = false;
    if (!acquire('original APT configuration', options, 120)) {
      fallback = true;
      options = fallbackOptions;
      requireCondition(acquire('existing official HTTPS mirrors only', options, 180), 'both bounded acquisition attempts failed; installation not attempted');
    }
    // No retry/fallback after dpkg starts, and no network or wall-clock kill here.
    requireCondition(success(execute('sudo', ['-n', 'apt-get', ...SECURITY, ...options, '--yes', '--no-install-recommends', '--no-download', 'install', 'ffmpeg'])), 'no-download installation failed; not retried');
    requireCondition(versions(), 'installed ffmpeg/ffprobe version check failed');
    log('CI media tools: both versions verified after signed APT installation.');
    return { installed: true, fallback };
  } finally {
    if (directory) rmSync(directory, { recursive: true, force: true });
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    requireCondition(process.argv.length === 2, 'no CLI arguments are accepted');
    ensureCiMediaTools();
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
