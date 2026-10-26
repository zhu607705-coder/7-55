import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
export const digest = value => createHash('sha256').update(typeof value === 'string' ? value : JSON.stringify(value)).digest('hex');
export function fileDigest(file) {
 const hash = createHash('sha256'), buffer = Buffer.alloc(1024 * 1024), fd = fs.openSync(file, 'r');
 try {let size; while ((size = fs.readSync(fd, buffer, 0, buffer.length, null))) hash.update(buffer.subarray(0, size));}
 finally {fs.closeSync(fd);}
 return hash.digest('hex');
}
export const PRODUCER_OUTPUTS = {
 'test_canteen_defense.gd': ['canteen_defense.json', 'canteen_defense_snapshots.json'].map(f => `godot_native/tests/fixtures/${f}`),
 'test_minigame_models.gd': ['chase', 'rhythm_locker_key', 'rhythm_net_frame', 'rhythm_fish', 'rhythm_paper', 'kayak_boarding', 'kayak_rain', 'kayak_travel', 'kayak_chase'].map(f => `godot_native/tests/fixtures/${f}.json`),
 'Source catalog tests/export_lake_live_source_fixtures.mjs': ['godot_native/tests/fixtures/lake_live_source.json']
};
const outputs = new Set(Object.values(PRODUCER_OUTPUTS).flat());
export function snapshotPaths(root, paths, {exclude = () => false} = {}) {
 const records = new Map();
 function visit(relative, ancestors = new Set()) {
  if (exclude(relative) || records.has(relative)) return;
  const file = path.join(root, relative);
  if (!fs.existsSync(file)) {records.set(relative, ['missing']); return;}
  const real = fs.realpathSync(file), stat = fs.statSync(file), link = fs.lstatSync(file).isSymbolicLink() ? fs.readlinkSync(file) : null;
  if (stat.isDirectory()) {
   if (ancestors.has(real)) throw Error(`Cannot fingerprint symlink cycle: ${relative}`);
   records.set(relative, ['directory', link]);
   for (const entry of fs.readdirSync(file).sort()) visit(path.posix.join(relative, entry), new Set([...ancestors, real]));
  } else if (stat.isFile()) records.set(relative, ['file', stat.mode & 0o777, link, fileDigest(file)]);
  else throw Error(`Cannot fingerprint non-regular input: ${relative}`);
 }
 for (const relative of paths) visit(relative);
 const entries = [...records].sort(([a], [b]) => a.localeCompare(b));
 return {sha256: digest(entries), count: entries.length};
}
export function fixtureIdentity(root, id = null) {
 return snapshotPaths(root, id && PRODUCER_OUTPUTS[id] ? PRODUCER_OUTPUTS[id] : [...outputs]).sha256;
}
export function resolveExecutable(command, env = process.env) {
 const candidates = command.includes('/') ? [path.resolve(command)] : (env.PATH || '').split(path.delimiter).map(p => path.join(p, command));
 for (const file of candidates) try {fs.accessSync(file, fs.constants.X_OK); if (fs.statSync(file).isFile()) return fs.realpathSync(file);} catch {}
 throw Error(`Cannot identify executable: ${command}`);
}
export function validationIdentity(root, {executable, jobs, env = process.env, extraExcludes = []}) {
 const git = spawnSync('git', ['ls-files', '-z', '--cached', '--others', '--exclude-standard'], {cwd: root, encoding: 'utf8', maxBuffer: 32 * 1024 * 1024});
 if (git.status !== 0) throw Error('Cannot establish complete tracked/untracked input list; resume is unsafe');
 const exclude = file => outputs.has(file) || extraExcludes.includes(file)
   || /(?:^|\/)(?:\.validation|\.vite|\.vite-temp|\.cache)(?:\/|$)/.test(file);
 const input = snapshotPaths(root, [...new Set([...git.stdout.split('\0').filter(Boolean),
  'src', 'public', 'scripts', 'godot_native/scripts', 'godot_native/tests', 'godot_native/tools', 'godot_native/data', 'godot_native/scenes', 'godot_native/shaders', 'godot_native/campuses',
  'godot_native/assets', 'godot_native/data/source', 'godot_native/.godot/imported',
  'godot_native/.godot/global_script_class_cache.cfg', 'godot_native/.godot/uid_cache.bin', 'node_modules'])], {exclude});
 const executablePath = resolveExecutable(executable, env);
 const version = spawnSync(executablePath, ['--version'], {encoding: 'utf8', env, timeout: 30000});
 if (version.error || version.status !== 0 || !version.stdout.trim()) throw Error('Cannot establish Godot identity; resume is unsafe');
 const environment = Object.fromEntries(Object.entries(env).filter(([key]) => !['PWD', 'OLDPWD', 'SHLVL', '_', 'GODOT_TEST_REPORT', 'GODOT_TEST_PAUSE_FILE'].includes(key)).sort(([a], [b]) => a.localeCompare(b)));
 const tools = [...new Set([executablePath, process.execPath, resolveExecutable('python3', env), resolveExecutable('bash', env)])].map(file => ({path: file, sha256: fileDigest(file)}));
 const details = {schema: 2, root: fs.realpathSync(root), input, jobs, tools, godotVersion: version.stdout.trim(), nodeVersion: process.version,
  platform: process.platform, arch: process.arch, release: os.release(), environmentSha256: digest(environment)};
 return {...details, sha256: digest(details)}; // Never serialize secret environment values.
}
export function stageIdentity(identity, stage, fixtureSha256) {
 return digest({identity: identity.sha256, command: stage.command, args: stage.args, fixtureSha256});
}
export function canReuse(row, key) {return row?.result === 'pass' && row.failed === false && row.identity === key;}

// Discover explicit fixture/test controls from the checked-in harness, instead
// of mistaking unrelated cloud-agent *_PATH variables for shared test outputs.
// Unknown controls are deliberately conservative: no reuse, serial execution.
export function inheritedTestOverrides(root, env = process.env) {
 const names = new Set();
 function visit(file) {
  if (!fs.existsSync(file)) return;
  if (fs.statSync(file).isDirectory()) {for (const entry of fs.readdirSync(file)) visit(path.join(file, entry)); return;}
  if (!/\.(?:gd|mjs|js|py)$/.test(file)) return;
  const source = fs.readFileSync(file, 'utf8');
  for (const match of source.matchAll(/(?:get_environment\(|process\.env\[|os\.environ\.get\()\s*['"]([A-Z][A-Z0-9_]*)['"]|process\.env\.([A-Z][A-Z0-9_]*)/g)) names.add(match[1] || match[2]);
 }
 for (const directory of ['godot_native/tests', 'godot_native/tools', 'godot_native/scripts', 'scripts']) visit(path.join(root, directory));
 // Hosted runners also set CHROME_BIN and USER. Their only scanned consumers
 // are separate Web browser tools and deploy_web_server's host metadata, not
 // native catalog stages. Keep their values in the environment identity, but
 // do not mistake them for native fixture/output overrides.
 const isolated = new Set(['CI','GITHUB_OUTPUT','GITHUB_EVENT_NAME','GITHUB_RUN_ATTEMPT','GITHUB_RUN_ID','GITHUB_SHA','CHROME_BIN','USER','GODOT_BIN','NATIVE_TEST_JOBS','GODOT_TEST_REPORT','GODOT_TEST_PAUSE_FILE','BUCT_V4_QA_DIR','HOME','TMPDIR','TMP','TEMP','PATH','XDG_DATA_HOME','XDG_CONFIG_HOME','XDG_CACHE_HOME','XDG_STATE_HOME','XDG_RUNTIME_DIR','GODOT_TEST_USER_DATA_DIR','GODOT_NATIVE_TEST_NONCE']);
 return [...names].filter(key => env[key] && !isolated.has(key)).sort();
}
export function completedStageIdentity(identity, stage, before, after) {
 const producer = Object.hasOwn(PRODUCER_OUTPUTS, stage.id);
 if (!producer && before !== after) throw Error(`Fixture inputs changed while reader was running: ${stage.id}`);
 return identity ? stageIdentity(identity, stage, producer ? after : before) : null;
}
