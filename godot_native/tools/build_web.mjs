import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { readPack } from './partition_web_pack.mjs';
import { createContentDelivery, verifyContentDelivery, fileSha256, CONTENT_PACK_LIMIT } from './web_content_delivery.mjs';
import { campusPayloadIdentity, assertStoryOnlyPackEntries } from './web_story_content_policy.mjs';
import { createBootChunks, verifyBootChunks } from './web_boot_chunks.mjs';
import { applyWebAudioCompatibility, verifyWebAudioCompatibility } from './web_audio_compat.mjs';

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
const monolithic = args.includes('--monolithic');
const sha256 = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const relative = file => path.relative(project, file).split(path.sep).join('/');
const limits = { siteBytes: 950_000_000, packBytes: 800_000_000, wasmBytes: 70_000_000, deferredPackBytes: CONTENT_PACK_LIMIT };
const deliveryTools = ['tools/build_web.mjs', 'tools/convert_media.sh', 'tools/plan_web_content.mjs', 'tools/partition_web_pack.mjs', 'tools/partition_web_pack.gd', 'tools/web_content_delivery.mjs', 'tools/web_story_content_policy.mjs', 'tools/web_boot_chunks.mjs', 'tools/web_audio_compat.mjs'];
const browserSources = ['web/index.html', 'web/content_loader.js'];
const excludedPrefixes = ['docs/', 'tests/', 'tools/', 'verification/', 'exports/', 'web/', '.screenshots/', 'examples/', 'samples/', 'campuses/', 'assets/rpg/campus/source/', 'assets/rpg/interiors/source/', 'assets/rpg/optimized/'];
const excludedSuffixes = ['.mp4', '.md', '.log', '.blend', '.blend1', '.py', '.ts', '.mjs'];
function excluded(name) {
  name = name.replace(/^res:\/\//, '');
  return excludedPrefixes.some(prefix => name.startsWith(prefix)) || excludedSuffixes.some(suffix => name.endsWith(suffix)) || name === 'scenes/library_stamp_review.tscn';
}
function run(command, commandArgs, capture = false, environment = process.env) {
  const result = spawnSync(command, commandArgs, { cwd: root, env: environment, encoding: 'utf8', stdio: capture ? 'pipe' : 'inherit', maxBuffer: 16 * 1024 * 1024 });
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
function bindScript(name) {
  const filename = path.join(output, 'index.html');
  const html = fs.readFileSync(filename, 'utf8');
  let references = 0;
  const pattern = new RegExp(`(<script\\b[^>]*\\bsrc=["'])${name.replaceAll('.', '\\.')}(?:\\?v=[a-f0-9]+)?(["'])`, 'g');
  const bound = html.replace(pattern, (_, prefix, quote) => {
    references++;
    return `${prefix}${name}?v=${fileSha256(path.join(output, name))}${quote}`;
  });
  if (references !== 1) throw new Error(`Expected exactly one local ${name} script in exported HTML`);
  fs.writeFileSync(filename, bound);
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
    .concat(['project.godot', 'export_presets.cfg', ...browserSources, ...deliveryTools].map(file => path.join(project, file)))
    // Import sidecars and newly generated UIDs can differ between a clean CI
    // checkout and an editor workspace; the exported PCK has its own byte hash.
    .filter(file => !file.endsWith('.import') && !file.endsWith('.uid') && !file.includes('/.DS_Store'));
  const inventory = files.filter(file => !excluded(relative(file)) || [...browserSources, ...deliveryTools].includes(relative(file)))
    .map(file => ({ path: relative(file), bytes: fs.statSync(file).size, sha256: sha256(fs.readFileSync(file)) }))
    .sort((a, b) => a.path.localeCompare(b.path, 'en'));
  const excludedFiles = files.filter(file => excluded(relative(file)) && ![...browserSources, ...deliveryTools].includes(relative(file)))
    .map(file => ({ path: relative(file), bytes: fs.statSync(file).size }));
  return { inventory, excludedFiles, digest: sha256(JSON.stringify(inventory)) };
}
function validatePreset() {
  const text = fs.readFileSync(path.join(project, 'export_presets.cfg'), 'utf8');
  const web = text.split('[preset.2]')[1];
  for (const expected of ['name="Web production"', 'custom_features="755_production,755_web,755_story_only"', 'variant/thread_support=false', 'variant/extensions_support=false', 'html/custom_html_shell="res://web/index.html"', 'progressive_web_app/enabled=false']) {
    if (!web?.includes(expected)) throw new Error(`Web preset contract missing: ${expected}`);
  }
  if (!web.match(/^exclude_filter="[^"]*\bcampuses\/\*/m)) throw new Error('Story-only Web preset must exclude campuses/*');
  const projectSettings = fs.readFileSync(path.join(project, 'project.godot'), 'utf8');
  if (!projectSettings.includes('renderer/rendering_method="gl_compatibility"')) throw new Error('Web requires the Compatibility renderer');
  if (!/^general\/default_playback_type\.web=0\s*$/m.test(projectSettings)) throw new Error('The pinned HTTP audio compatibility path requires Stream playback');
  for (const file of walk(path.join(project, 'scripts')).concat(walk(path.join(project, 'scenes')), walk(path.join(project, 'campuses')))) {
    if (excluded(relative(file)) || !/\.(gd|tscn|tres)$/.test(file)) continue;
    const text = fs.readFileSync(file, 'utf8');
    for (const prefix of ['assets/rpg/campus/source/', 'assets/rpg/interiors/source/', 'assets/rpg/optimized/']) {
      if (text.includes(prefix)) throw new Error(`Excluded source art acquired a runtime consumer: ${relative(file)} → ${prefix}`);
    }
  }
}
function validatePackEntries(entries, full = false) {
  assertStoryOnlyPackEntries(entries, campusPayloadIdentity(project));
  for (const entry of entries) if (excluded(entry.path)) throw new Error(`Non-production resource leaked into PCK: ${entry.path}`);
  const required = ['project.binary', 'scripts/entry.gd', 'scripts/main.gd', 'scripts/state.gd', 'scripts/developer_tools_policy.gd', 'scripts/release_content_policy.gd', 'scenes/entry.tscn', 'scenes/main.tscn', 'data/initial_state.json', 'data/native/prologue-interception.content.json', 'assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf.import', 'ui_assets/fonts/CampusUISans-Regular.otf.import', 'ui_assets/fonts/OFL.txt'];
  for (const name of required) if (!entries.some(entry => entry.path === name || entry.path === `${name}.remap`)) throw new Error(`Formal ${full ? 'full-export' : 'boot-core'} dependency absent from PCK: ${name}`);
}
function readPck(filename, full = false) {
  const pack = readPack(filename);
  validatePackEntries(pack.entries, full);
  const config = pack.entries.find(entry => entry.path === 'project.binary');
  const fd = fs.openSync(filename, 'r');
  try {
    const configBytes = Buffer.alloc(config.bytes);
    if (fs.readSync(fd, configBytes, 0, config.bytes, config.offset) !== config.bytes) throw new Error('Truncated project.binary');
    for (const feature of ['755_production', '755_web', '755_story_only', 'gl_compatibility']) if (!configBytes.includes(Buffer.from(feature))) throw new Error(`PCK lost production feature: ${feature}`);
  } finally { fs.closeSync(fd); }
  return pack;
}

validatePreset();
let sourceBeforeExport;
let bootChunks;
let audioCompatibility;
if (!verifyOnly) {
  const actual = run(godot, ['--version'], true);
  if (!actual.startsWith(version)) throw new Error(`Godot must be ${version}, found ${actual}`);
  if (!args.includes('--skip-prepare')) {
    run(process.execPath, ['godot_native/tools/sync_source.mjs']);
    run('bash', ['godot_native/tools/convert_media.sh'], false, { ...process.env, NODE_BIN: process.execPath });
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
  sourceBeforeExport = sourceInventory().digest;
  runGodot('export', ['--headless', '--path', project, '--export-release', preset, path.join(output, 'index.html')]);
  audioCompatibility = applyWebAudioCompatibility(output, version);
  fs.copyFileSync(path.join(project, 'web/content_loader.js'), path.join(output, 'content-loader.js'));
  bindScript('content-loader.js');
  bindScript('index.js');
  // Validate the complete Godot export before assigning any resources to packs.
  readPck(path.join(output, 'index.pck'), true);
  if (!monolithic) createContentDelivery({ exportDirectory: output, intermediateDirectory: path.join(project, 'exports/verification/godot-web-build', `${path.basename(output)}-${new Date().toISOString().replace(/[:.]/g, '-')}-${process.pid}`) });
  // Chunk the final boot-core, never the full intermediate PCK. Original PCK
  // and WASM stay intact for independent engine validation and rollback.
  if (!monolithic) bootChunks = createBootChunks(output);
}

const html = fs.readFileSync(path.join(output, 'index.html'), 'utf8');
if (!html.includes('name="seven55-runtime" content="godot-web"') || !html.includes('new Engine(') || !html.includes('index.js')) throw new Error('HTML is not the dedicated Godot shell');
if (/<iframe\b|react-dom|phaser|@vite|\/src\/main/.test(html) || /\$GODOT_[A-Z_]+/.test(html)) throw new Error('Invalid hybrid/unexpanded Web shell');
const contentLoaderSha256 = fileSha256(path.join(output, 'content-loader.js'));
const contentLoaderUrl = `content-loader.js?v=${contentLoaderSha256}`;
const loaderReferences = [...html.matchAll(/<script\b[^>]*\bsrc=["']([^"']+)["']/g)].map(match => match[1]).filter(value => /(?:^|\/)content-loader\.js(?:[?#]|$)/.test(value));
if (loaderReferences.length !== 1 || loaderReferences[0] !== contentLoaderUrl) throw new Error('Exported HTML content-loader URL is not bound to its actual SHA-256');
const engineLoaderSha256 = fileSha256(path.join(output, 'index.js'));
const engineLoaderUrl = `index.js?v=${engineLoaderSha256}`;
const engineReferences = [...html.matchAll(/<script\b[^>]*\bsrc=["']([^"']+)["']/g)].map(match => match[1]).filter(value => /(?:^|\/)index\.js(?:[?#]|$)/.test(value));
if (engineReferences.length !== 1 || engineReferences[0] !== engineLoaderUrl) throw new Error('Exported HTML engine-loader URL is not bound to its actual SHA-256');
const wasm = fs.openSync(path.join(output, 'index.wasm'), 'r');
try {
  const magic = Buffer.alloc(8);
  fs.readSync(wasm, magic, 0, 8, 0);
  if (!magic.equals(Buffer.from([0, 97, 115, 109, 1, 0, 0, 0]))) throw new Error('Missing or invalid WebAssembly module');
} finally { fs.closeSync(wasm); }
const streaming = fs.existsSync(path.join(output, 'content-manifest.json'));
if (monolithic && streaming) throw new Error('--monolithic cannot verify a split delivery');
if (!streaming && !monolithic) throw new Error('Production delivery requires content-manifest.json; use --monolithic only for an internal full-export intermediate');
const content = streaming ? verifyContentDelivery(output) : null;
if (content && (content.manifest.packs.some(pack => pack.family.startsWith('campus_')) || content.manifest.backgroundOrder.some(family => family.startsWith('campus_')))) throw new Error('Story-only manifest includes research campus families');
if (content) validatePackEntries(content.fullEntries, true);
const pack = readPck(path.join(output, 'index.pck'), !streaming);
const previous = verifyOnly ? JSON.parse(fs.readFileSync(path.join(output, 'build-manifest.json'), 'utf8')) : null;
audioCompatibility = verifyWebAudioCompatibility(output, verifyOnly ? previous.engineAudioCompatibility : audioCompatibility, version);
if (verifyOnly) bootChunks = previous.bootChunks;
const boot = streaming ? verifyBootChunks(output, bootChunks) : null;
const files = walk(output).filter(file => !['build-manifest.json', 'source-inputs.json', 'pack-inventory.json', '.nojekyll'].includes(path.basename(file)))
  .map(file => ({ path: path.relative(output, file).split(path.sep).join('/'), bytes: fs.statSync(file).size, sha256: fileSha256(file) }));
if (files.some(file => /service\.worker|\.worker\.js$|\.side\.wasm$/.test(file.path))) throw new Error('Unexpected threaded/PWA dependency');
const siteBytes = files.reduce((total, file) => total + file.bytes, 0);
// Hosted originals duplicate their static transport chunks. Count both in the
// hosting budget, and count only chunks in the player's initial transfer.
const initialPayloadBytes = files.filter(file => !file.path.startsWith('content/') && file.path !== 'content-inventory.json' && (!boot || !['index.pck', 'index.wasm'].includes(file.path))).reduce((sum, file) => sum + file.bytes, 0);
const logicalPayloadBytes = siteBytes - (boot?.bytes ?? 0);
if (boot) for (const resource of Object.values(bootChunks.resources)) {
  const original = files.find(file => file.path === resource.file);
  if (!original || original.bytes !== resource.bytes || original.sha256 !== resource.sha256) throw new Error(`Static boot map differs from original build artifact: ${resource.file}`);
  for (const chunk of resource.chunks) {
    const actual = files.find(file => file.path === chunk.file);
    if (!actual || actual.bytes !== chunk.bytes || actual.sha256 !== chunk.sha256) throw new Error(`Static boot map differs from build file receipt: ${chunk.file}`);
  }
}
if (siteBytes > limits.siteBytes || files.find(file => file.path === 'index.pck').bytes > limits.packBytes || files.find(file => file.path === 'index.wasm').bytes > limits.wasmBytes) throw new Error(`Web build exceeds declared delivery budget: ${siteBytes} bytes`);
const source = sourceInventory();
if (sourceBeforeExport && sourceBeforeExport !== source.digest) throw new Error('Source inputs changed during export/partition; freeze inputs and rebuild');
if (verifyOnly) {
  if (previous.engine !== version) throw new Error('Engine version differs from the pinned compatibility transform');
  const recordedPack = JSON.parse(fs.readFileSync(path.join(output, 'pack-inventory.json'), 'utf8'));
  const recordedSource = JSON.parse(fs.readFileSync(path.join(output, 'source-inputs.json'), 'utf8'));
  if (JSON.stringify(recordedPack) !== JSON.stringify(pack) || recordedSource.digest !== source.digest || JSON.stringify(recordedSource.files) !== JSON.stringify(source.inventory)) throw new Error('Published core/source inventories differ from their actual verified inputs');
  for (const file of files) {
    const recorded = previous.files.find(item => item.path === file.path);
    if (!recorded || recorded.bytes !== file.bytes || recorded.sha256 !== file.sha256) throw new Error(`Artifact no longer matches its build manifest: ${file.path}`);
  }
  if (previous.files.length !== files.length || previous.sourceInputSha256 !== source.digest || previous.pack.inventorySha256 !== sha256(JSON.stringify(pack.entries))) throw new Error('Build provenance differs from current inputs/PCK; rebuild instead of rewriting provenance');
  if (previous.delivery !== (streaming ? 'chapter-content-packs' : 'internal-monolithic') || previous.initialPayloadBytes !== initialPayloadBytes || previous.totalPayloadBytes !== siteBytes) throw new Error('Delivery layout or byte budget differs from its build manifest');
  if (previous.logicalPayloadBytes !== logicalPayloadBytes || (streaming && previous.storyOnly !== true)) throw new Error('Logical payload or story-only release policy differs from its build manifest');
  if (previous.contentLoader?.sha256 !== contentLoaderSha256 || previous.contentLoader?.url !== contentLoaderUrl) throw new Error('Content-loader version differs from its build provenance');
  if (previous.engineLoader?.file !== 'index.js' || previous.engineLoader?.sha256 !== engineLoaderSha256 || previous.engineLoader?.url !== engineLoaderUrl) throw new Error('Engine-loader version differs from its build provenance');
  if (content && (JSON.stringify(previous.fullPack) !== JSON.stringify(content.inventory.full) || previous.content?.inventorySha256 !== fileSha256(path.join(output, 'content-inventory.json')) || previous.content?.entryCount !== content.fullEntries.length)) throw new Error('Complete-export provenance differs from the verified content inventory');
  console.log(JSON.stringify({ verified: true, output, originalSourceCommit: previous.sourceCommit, sourceInputSha256: source.digest, payloadBytes: siteBytes, logicalPayloadBytes, initialPayloadBytes, bootChunkFiles: boot?.files ?? 0, coreFiles: pack.count, fullFiles: content?.inventory.full.count ?? pack.count, deferredPacks: content?.manifest.packs.length ?? 0 }, null, 2));
  process.exit(0);
}
const commit = run('git', ['rev-parse', 'HEAD'], true);
const tree = run('git', ['rev-parse', 'HEAD^{tree}'], true);
const dirty = run('git', ['status', '--porcelain=v1', '--untracked-files=all', '--', 'godot_native', '.github/workflows/deploy-pages.yml'], true).split('\n').filter(Boolean);
const manifest = {
  schema: '7-55-godot-web-release/v1', runtime: 'godot-web', engine: '4.7.2.stable.official', preset,
  renderer: 'gl_compatibility', threads: false, pwa: false, production: true, storyOnly: true, chapterShortcuts: false,
  builtAt: new Date().toISOString(), sourceCommit: commit, sourceTree: tree, sourceDirty: dirty.length !== 0,
  sourceChanges: dirty, sourceInputSha256: source.digest, sourceInputCount: source.inventory.length,
  excludedSourceFiles: source.excludedFiles.length, excludedSourceBytes: source.excludedFiles.reduce((sum, file) => sum + file.bytes, 0),
  delivery: streaming ? 'chapter-content-packs' : 'internal-monolithic', totalPayloadBytes: siteBytes, logicalPayloadBytes, initialPayloadBytes, limits, files,
  contentLoader: { file: 'content-loader.js', sha256: contentLoaderSha256, url: contentLoaderUrl },
  engineLoader: { file: 'index.js', sha256: engineLoaderSha256, url: engineLoaderUrl },
  engineAudioCompatibility: audioCompatibility,
  ...(boot ? { bootChunks } : {}),
  pack: { role: streaming ? 'boot-core' : 'internal-full-export', format: pack.format, engine: pack.engine, flags: pack.flags, files: pack.count, inventorySha256: sha256(JSON.stringify(pack.entries)) },
  ...(content ? { fullPack: content.inventory.full, content: { schema: content.manifest.schema, packs: content.manifest.packs.length, deferredBytes: content.manifest.packs.reduce((sum, item) => sum + item.bytes, 0), coreBytes: content.manifest.core.bytes, exactCoverage: true, entryCount: content.inventory.full.count, inventorySha256: fileSha256(path.join(output, 'content-inventory.json')) } } : {}),
  acceptance: 'Artifact verification only. Actual browser input, rendering, persistence and chapter continuity are separate required gates.',
};
fs.writeFileSync(path.join(output, 'source-inputs.json'), JSON.stringify({ digest: source.digest, files: source.inventory, excluded: source.excludedFiles }, null, 2) + '\n');
fs.writeFileSync(path.join(output, 'pack-inventory.json'), JSON.stringify(pack, null, 2) + '\n');
fs.writeFileSync(path.join(output, 'build-manifest.json'), JSON.stringify(manifest, null, 2) + '\n');
fs.writeFileSync(path.join(output, '.nojekyll'), '');
console.log(JSON.stringify({ output, sourceCommit: commit, sourceInputSha256: source.digest, payloadBytes: siteBytes, logicalPayloadBytes, initialPayloadBytes, bootChunkFiles: boot?.files ?? 0, coreFiles: pack.count, fullFiles: content?.inventory.full.count ?? pack.count, deferredPacks: content?.manifest.packs.length ?? 0, excludedSourceBytes: manifest.excludedSourceBytes }, null, 2));
