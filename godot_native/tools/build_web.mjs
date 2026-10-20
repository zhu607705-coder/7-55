import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';

// This builds the independent Godot project. The retained Vite/React build is
// deliberately not an input, fallback, or output of this command.
const root = path.resolve(import.meta.dirname, '../..');
const project = path.join(root, 'godot_native');
const args = process.argv.slice(2);
const godot = process.env.GODOT_BIN || 'godot';
const version = '4.7.2.stable.official';
const preset = 'Web production';
const output = path.resolve(args.find(value => value.startsWith('--output='))?.slice(9) || path.join(project, 'exports/web-release'));
const verifyOnly = args.includes('--verify-only');
const sha256 = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const relative = file => path.relative(project, file).split(path.sep).join('/');
const limits = { siteBytes: 950_000_000, packBytes: 800_000_000, wasmBytes: 70_000_000 };
const excludedPrefixes = ['docs/', 'tests/', 'tools/', 'verification/', 'exports/', 'web/', '.screenshots/', 'examples/', 'samples/', 'assets/rpg/campus/source/', 'assets/rpg/interiors/source/', 'assets/rpg/optimized/'];
const excludedSuffixes = ['.mp4', '.md', '.log', '.blend', '.blend1', '.py', '.ts', '.mjs'];
function excluded(name) {
  name = name.replace(/^res:\/\//, '');
  return excludedPrefixes.some(prefix => name.startsWith(prefix)) || excludedSuffixes.some(suffix => name.endsWith(suffix)) || name === 'scenes/library_stamp_review.tscn';
}
function run(command, commandArgs, capture = false) {
  const result = spawnSync(command, commandArgs, { cwd: root, encoding: 'utf8', stdio: capture ? 'pipe' : 'inherit', maxBuffer: 16 * 1024 * 1024 });
  if (result.error || result.status !== 0) throw new Error(`${command} failed (${result.status}): ${result.error || result.stderr || ''}`);
  return capture ? result.stdout.trim() : '';
}
function runGodot(stage, commandArgs) {
  const logs = path.join(project, 'exports/verification/godot-web-build');
  fs.mkdirSync(logs, { recursive: true });
  const filename = path.join(logs, `${new Date().toISOString().replace(/[:.]/g, '-')}-${stage}.log`);
  const result = spawnSync(godot, ['--quiet', ...commandArgs], { cwd: root, encoding: 'utf8', stdio: 'pipe', maxBuffer: 64 * 1024 * 1024 });
  const log = `${result.stdout || ''}\n${result.stderr || ''}`;
  fs.writeFileSync(filename, log);
  const errors = log.split('\n').filter(line => /^\s*(?:SCRIPT ERROR|ERROR):/.test(line));
  console.log(`Godot ${stage}: ${result.status === 0 && !errors.length ? 'PASS' : 'FAIL'}; full log ${filename}`);
  if (result.error || result.status !== 0 || errors.length) throw new Error(`Godot ${stage} failed (${result.status}): ${result.error || errors.slice(0, 12).join('\n') || log.slice(-4000)}`);
}
function walk(directory) {
  if (!fs.existsSync(directory)) return [];
  return fs.readdirSync(directory, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name, 'en')).flatMap(entry => {
    const file = path.join(directory, entry.name);
    if (entry.isSymbolicLink()) throw new Error(`Symlink is not a reproducible build input: ${relative(file)}`);
    return entry.isDirectory() ? walk(file) : [file];
  });
}
function sourceInventory() {
  const files = ['scripts', 'scenes', 'data', 'assets', 'campuses'].flatMap(directory => walk(path.join(project, directory)))
    .concat(['project.godot', 'export_presets.cfg', 'web/index.html', 'tools/build_web.mjs'].map(file => path.join(project, file)))
    // Import sidecars and newly generated UIDs can differ between a clean CI
    // checkout and an editor workspace; the exported PCK has its own byte hash.
    .filter(file => !file.endsWith('.import') && !file.endsWith('.uid') && !file.includes('/.DS_Store'));
  const inventory = files.filter(file => !excluded(relative(file)) || ['web/index.html', 'tools/build_web.mjs'].includes(relative(file)))
    .map(file => ({ path: relative(file), bytes: fs.statSync(file).size, sha256: sha256(fs.readFileSync(file)) }))
    .sort((a, b) => a.path.localeCompare(b.path, 'en'));
  const excludedFiles = files.filter(file => excluded(relative(file)) && !['web/index.html', 'tools/build_web.mjs'].includes(relative(file)))
    .map(file => ({ path: relative(file), bytes: fs.statSync(file).size }));
  return { inventory, excludedFiles, digest: sha256(JSON.stringify(inventory)) };
}
function validatePreset() {
  const text = fs.readFileSync(path.join(project, 'export_presets.cfg'), 'utf8');
  const web = text.split('[preset.2]')[1];
  for (const expected of ['name="Web production"', 'custom_features="755_production,755_web"', 'variant/thread_support=false', 'variant/extensions_support=false', 'html/custom_html_shell="res://web/index.html"', 'progressive_web_app/enabled=false']) {
    if (!web?.includes(expected)) throw new Error(`Web preset contract missing: ${expected}`);
  }
  if (!fs.readFileSync(path.join(project, 'project.godot'), 'utf8').includes('renderer/rendering_method="gl_compatibility"')) throw new Error('Web requires the Compatibility renderer');
  for (const file of walk(path.join(project, 'scripts')).concat(walk(path.join(project, 'scenes')), walk(path.join(project, 'campuses')))) {
    if (excluded(relative(file)) || !/\.(gd|tscn|tres)$/.test(file)) continue;
    const text = fs.readFileSync(file, 'utf8');
    for (const prefix of ['assets/rpg/campus/source/', 'assets/rpg/interiors/source/', 'assets/rpg/optimized/']) {
      if (text.includes(prefix)) throw new Error(`Excluded source art acquired a runtime consumer: ${relative(file)} → ${prefix}`);
    }
  }
}
function readPck(filename) {
  const fd = fs.openSync(filename, 'r');
  let cursor = 0;
  function read(size) {
    const buffer = Buffer.alloc(size);
    if (fs.readSync(fd, buffer, 0, size, cursor) !== size) throw new Error('Truncated PCK directory');
    cursor += size;
    return buffer;
  }
  function u32() { return read(4).readUInt32LE(); }
  function u64() { return Number(read(8).readBigUInt64LE()); }
  try {
    if (read(4).toString('ascii') !== 'GDPC') throw new Error('Not a Godot PCK');
    const format = u32();
    const engine = [u32(), u32(), u32()].join('.');
    if (![2, 3, 4].includes(format) || engine !== '4.7.2') throw new Error(`Unexpected PCK format/engine: ${format}/${engine}`);
    const flags = u32();
    const fileBase = u64();
    if (flags & 1 || flags & 4) throw new Error('Encrypted/sparse PCK is not supported by this delivery contract');
    if (format >= 3) cursor = u64(); else cursor += 64;
    const count = u32();
    if (count < 100 || count > 50_000) throw new Error(`Unexpected PCK entry count: ${count}`);
    const entries = [];
    for (let index = 0; index < count; index++) {
      const length = u32();
      if (length < 1 || length > 16_384) throw new Error('Invalid PCK path length');
      const name = read(length).toString('utf8').replace(/\0+$/, '').replace(/^res:\/\//, '');
      const offset = fileBase + u64();
      const bytes = u64();
      const md5 = read(16).toString('hex');
      const entryFlags = u32();
      if (!Number.isSafeInteger(offset) || offset < 0 || offset + bytes > fs.statSync(filename).size || entryFlags !== 0) throw new Error(`Invalid PCK range/flags: ${name}`);
      entries.push({ path: name, offset, bytes, md5 });
    }
    if (new Set(entries.map(entry => entry.path)).size !== count) throw new Error('Duplicate PCK paths');
    for (const entry of entries) {
      if (excluded(entry.path)) throw new Error(`Non-production resource leaked into PCK: ${entry.path}`);
    }
    for (const required of ['project.binary', 'scripts/entry.gd', 'scripts/main.gd', 'scripts/state.gd', 'scripts/developer_tools_policy.gd', 'scenes/entry.tscn', 'scenes/main.tscn', 'data/initial_state.json', 'data/native/prologue-interception.content.json', 'campuses/buct/scenes/playable.tscn', 'campuses/buct_haidian/scenes/playable.tscn', 'campuses/buct_changping/scenes/playable.tscn']) {
      if (!entries.some(entry => entry.path === required || entry.path === `${required}.remap`)) throw new Error(`Formal runtime dependency absent from PCK: ${required}`);
    }
    const config = entries.find(entry => entry.path === 'project.binary');
    cursor = config.offset;
    const configBytes = read(config.bytes);
    for (const feature of ['755_production', '755_web', 'gl_compatibility']) if (!configBytes.includes(Buffer.from(feature))) throw new Error(`PCK lost production feature: ${feature}`);
    return { format, engine, flags, count, entries };
  } finally { fs.closeSync(fd); }
}

validatePreset();
if (!verifyOnly) {
  const actual = run(godot, ['--version'], true);
  if (!actual.startsWith(version)) throw new Error(`Godot must be ${version}, found ${actual}`);
  if (!args.includes('--skip-prepare')) {
    run(process.execPath, ['godot_native/tools/sync_source.mjs']);
    run('bash', ['godot_native/tools/convert_media.sh']);
  }
  for (const required of ['assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf', 'data/source/items.config.json', 'assets/rpg/cinematics/chapter4-prologue/chapter35_to_chapter4_h3_transition.ogv', 'assets/rpg/cinematics/qizhen-rain-rescue/qizhen_rain_rescue_hailuo23_v01.ogv']) {
    if (!fs.existsSync(path.join(project, required))) throw new Error(`Build input missing: ${required}; run without --skip-prepare`);
  }
  if (output === root || output === project || !output.startsWith(path.join(project, 'exports') + path.sep)) throw new Error('Build output must be a dedicated directory inside godot_native/exports/');
  if (fs.existsSync(output) && fs.readdirSync(output).length) {
    if (!args.includes('--replace')) throw new Error('Output exists; use --replace to preserve it as a timestamped backup');
    const backup = `${output}.previous-${new Date().toISOString().replace(/[:.]/g, '-')}`;
    fs.renameSync(output, backup);
    console.log(`Preserved previous build: ${backup}`);
  }
  fs.mkdirSync(output, { recursive: true });
  if (!args.includes('--skip-import')) runGodot('import', ['--headless', '--path', project, '--editor', '--import']);
  runGodot('export', ['--headless', '--path', project, '--export-release', preset, path.join(output, 'index.html')]);
}

const html = fs.readFileSync(path.join(output, 'index.html'), 'utf8');
if (!html.includes('name="seven55-runtime" content="godot-web"') || !html.includes('new Engine(') || !html.includes('index.js')) throw new Error('HTML is not the dedicated Godot shell');
if (/<iframe\b|react-dom|phaser|@vite|\/src\/main/.test(html) || /\$GODOT_[A-Z_]+/.test(html)) throw new Error('Invalid hybrid/unexpanded Web shell');
const wasm = fs.openSync(path.join(output, 'index.wasm'), 'r');
try {
  const magic = Buffer.alloc(8);
  fs.readSync(wasm, magic, 0, 8, 0);
  if (!magic.equals(Buffer.from([0, 97, 115, 109, 1, 0, 0, 0]))) throw new Error('Missing or invalid WebAssembly module');
} finally { fs.closeSync(wasm); }
const pack = readPck(path.join(output, 'index.pck'));
const files = walk(output).filter(file => !['build-manifest.json', 'source-inputs.json', 'pack-inventory.json', '.nojekyll'].includes(path.basename(file)))
  .map(file => ({ path: path.relative(output, file).split(path.sep).join('/'), bytes: fs.statSync(file).size, sha256: sha256(fs.readFileSync(file)) }));
if (files.some(file => /service\.worker|\.worker\.js$|\.side\.wasm$/.test(file.path))) throw new Error('Unexpected threaded/PWA dependency');
const siteBytes = files.reduce((total, file) => total + file.bytes, 0);
if (siteBytes > limits.siteBytes || files.find(file => file.path === 'index.pck').bytes > limits.packBytes || files.find(file => file.path === 'index.wasm').bytes > limits.wasmBytes) throw new Error(`Web build exceeds declared delivery budget: ${siteBytes} bytes`);
const source = sourceInventory();
if (verifyOnly) {
  const previous = JSON.parse(fs.readFileSync(path.join(output, 'build-manifest.json'), 'utf8'));
  for (const file of files) {
    const recorded = previous.files.find(item => item.path === file.path);
    if (!recorded || recorded.bytes !== file.bytes || recorded.sha256 !== file.sha256) throw new Error(`Artifact no longer matches its build manifest: ${file.path}`);
  }
  if (previous.files.length !== files.length || previous.sourceInputSha256 !== source.digest || previous.pack.inventorySha256 !== sha256(JSON.stringify(pack.entries))) throw new Error('Build provenance differs from current inputs/PCK; rebuild instead of rewriting provenance');
  console.log(JSON.stringify({ verified: true, output, originalSourceCommit: previous.sourceCommit, sourceInputSha256: source.digest, payloadBytes: siteBytes, packFiles: pack.count }, null, 2));
  process.exit(0);
}
const commit = run('git', ['rev-parse', 'HEAD'], true);
const tree = run('git', ['rev-parse', 'HEAD^{tree}'], true);
const dirty = run('git', ['status', '--porcelain=v1', '--untracked-files=all', '--', 'godot_native', '.github/workflows/deploy-pages.yml'], true).split('\n').filter(Boolean);
const manifest = {
  schema: '7-55-godot-web-release/v1', runtime: 'godot-web', engine: '4.7.2.stable.official', preset,
  renderer: 'gl_compatibility', threads: false, pwa: false, production: true, chapterShortcuts: false,
  builtAt: new Date().toISOString(), sourceCommit: commit, sourceTree: tree, sourceDirty: dirty.length !== 0,
  sourceChanges: dirty, sourceInputSha256: source.digest, sourceInputCount: source.inventory.length,
  excludedSourceFiles: source.excludedFiles.length, excludedSourceBytes: source.excludedFiles.reduce((sum, file) => sum + file.bytes, 0),
  totalPayloadBytes: siteBytes, limits, files,
  pack: { format: pack.format, engine: pack.engine, flags: pack.flags, files: pack.count, inventorySha256: sha256(JSON.stringify(pack.entries)) },
  acceptance: 'Artifact verification only. Actual browser input, rendering, persistence and chapter continuity are separate required gates.',
};
fs.writeFileSync(path.join(output, 'source-inputs.json'), JSON.stringify({ digest: source.digest, files: source.inventory, excluded: source.excludedFiles }, null, 2) + '\n');
fs.writeFileSync(path.join(output, 'pack-inventory.json'), JSON.stringify(pack, null, 2) + '\n');
fs.writeFileSync(path.join(output, 'build-manifest.json'), JSON.stringify(manifest, null, 2) + '\n');
fs.writeFileSync(path.join(output, '.nojekyll'), '');
console.log(JSON.stringify({ output, sourceCommit: commit, sourceInputSha256: source.digest, payloadBytes: siteBytes, packFiles: pack.count, excludedSourceBytes: manifest.excludedSourceBytes }, null, 2));
