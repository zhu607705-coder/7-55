#!/usr/bin/env node
/** Plan lossless, original-path Godot resource packs from an actual export.
 * This does not export, remove, or rewrite resources. The matching partition
 * tool copies the selected PCK entries byte for byte. Unresolved ownership is
 * deliberately retained in core and reported, rather than guessed away.
 */
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const project = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const argv = process.argv.slice(2);
function argument(name, fallback) {
  const index = argv.indexOf(name);
  const inline = argv.find(value => value.startsWith(`${name}=`));
  return inline ? inline.slice(name.length + 1) : index >= 0 ? argv[index + 1] : fallback;
}
if (argv.includes('--help')) {
  console.log('node godot_native/tools/plan_web_content.mjs --input complete.pck --inventory pack-inventory.json --output groups.json [--startup=conservative|lazy-world]');
  process.exit(0);
}
const input = argument('--input');
const inventoryFile = argument('--inventory');
const output = argument('--output');
const startup = argument('--startup', 'conservative');
if (!input || !inventoryFile || !output || !['conservative', 'lazy-world'].includes(startup)) throw new Error('Required --input, --inventory, --output; --startup must be conservative or lazy-world');
const inventory = JSON.parse(fs.readFileSync(inventoryFile, 'utf8'));
const entries = inventory.entries;
if (!Array.isArray(entries) || !entries.length) throw new Error('Missing exported PCK inventory.entries');
const packBytes = fs.statSync(input).size;
const byPath = new Map();
for (const entry of entries) {
  if (!entry || typeof entry.path !== 'string' || entry.path.startsWith('/') || entry.path.includes('..') || byPath.has(entry.path) || !Number.isSafeInteger(entry.offset) || !Number.isSafeInteger(entry.bytes) || entry.offset < 0 || entry.bytes < 0 || entry.offset + entry.bytes > packBytes) throw new Error(`Invalid PCK inventory entry ${entry?.path}`);
  byPath.set(entry.path, entry);
}
const fd = fs.openSync(input, 'r');
function readEntry(entry) {
  if (entry.bytes > 8 * 1024 * 1024) throw new Error(`Unexpectedly large import/remap metadata ${entry.path}`);
  const bytes = Buffer.alloc(entry.bytes);
  if (fs.readSync(fd, bytes, 0, bytes.length, entry.offset) !== bytes.length) throw new Error(`Truncated PCK entry ${entry.path}`);
  if (entry.md5 && crypto.createHash('md5').update(bytes).digest('hex') !== entry.md5) throw new Error(`PCK import metadata differs from inventory: ${entry.path}`);
  return bytes.toString('utf8');
}
const normalize = value => value.replace(/^res:\/\//, '');
const ownership = new Map();
const aliases = new Map();
const links = [];
const unresolved = [];
function assign(name, group, reason) { ownership.set(name, { group, reason }); }
function classify(name) {
  if (name.startsWith('campuses/buct_shared/')) return 'campus_shared';
  if (name.startsWith('campuses/buct_changping/')) return 'campus_changping';
  if (name.startsWith('campuses/buct_haidian/')) return 'campus_haidian';
  if (name.startsWith('campuses/buct_pilots/')) return 'campus_chaoyang';
  if (name.startsWith('campuses/buct/')) return 'campus_chaoyang';
  if (/^(scripts|scenes|data)\//.test(name) || name === 'project.binary' || /assets\/rpg\/fonts\//.test(name)) return 'core';
  if (!name.startsWith('assets/')) return null;
  if (/^assets\/audio\/(library-finals)\//.test(name)) return 'chapter2';
  if (/^assets\/audio\/(chapter4)\//.test(name)) return 'chapter4';
  if (/^assets\/audio\/(chapter3-qizhen|chapter3-interlude)\//.test(name)) return 'chapter35';
  if (/^assets\/audio\/(chapter3|chapter3-theater|chapter3-canteen|pursuit)\//.test(name)) return /(?:ch35|qizhen|night_wind|interlude)/.test(name) ? 'chapter35' : 'chapter3';
  if (/^assets\/audio\/(act-one|sfx|vo)\//.test(name)) return 'core';
  if (/^assets\/phone\/library-search\//.test(name)) return 'chapter2';
  if (/^assets\/native_755\/ride\//.test(name) || /^assets\/derived\/chase_transition_3d\//.test(name)) return 'chapter3';
  if (/^assets\/(objectized\/chapter4|native\/(stair_b|endless_stair_b3|canruo))\//.test(name)) return 'chapter4';
  if (/^assets\/native\/(qizhen_rain_rescue|lake_assembly|kayak)\//.test(name)) return 'chapter35';
  if (/^assets\/native\/(canteen_objects|mixer|chapter3|canteen_animation|canteen_door)\//.test(name)) return 'chapter3';
  if (/^assets\/native\/(bonsai|dorm_cabinet)\//.test(name)) return 'core';
  if (/^assets\/rpg\/(campus|landmarks)\//.test(name)) return /loop_panorama/.test(name) ? 'chapter35' : 'chapter2';
  if (/^assets\/rpg\/(portraits|chapter4-stair)\//.test(name)) return 'chapter4';
  if (/^assets\/rpg\/(qizhen_fishing|qizhen)\//.test(name)) return 'chapter35';
  if (/^assets\/rpg\/(theater|canteen|canteen_chase|canteen-characters)\//.test(name)) return 'chapter3';
  if (/^assets\/rpg\/interiors\//.test(name)) {
    if (/(?:finale|chapter4)/.test(name)) return 'chapter4';
    if (/(?:qizhen|lake|swan)/.test(name)) return 'chapter35';
    if (/(?:canteen|theater)/.test(name)) return 'chapter3';
    if (/library/.test(name)) return 'chapter2';
    if (/dorm/.test(name)) return 'core';
  }
  if (/^assets\/rpg\/npcs\//.test(name)) {
    if (/(?:finale|chapter4)/.test(name)) return 'chapter4';
    if (/(?:qizhen|lake|swan)/.test(name)) return 'chapter35';
    if (/(?:canteen|theater)/.test(name)) return 'chapter3';
    if (/library/.test(name)) return 'chapter2';
  }
  if (/^assets\/rpg\/cinematics\//.test(name)) return /(?:chapter4-prologue|chapter4-755)/.test(name) ? 'chapter4' : /qizhen/.test(name) ? 'chapter35' : null;
  // Retain unused source sheets in later content too. Only the actual shared
  // 32 animation frames and idle images are needed by World._ready.
  if (/^assets\/rpg\/player\//.test(name)) return /^assets\/rpg\/player\/player_(?:down_[0-7]|up_[0-7]|side_[0-7]|left_[0-7]|side_idle|left_idle)\.png$/.test(name) ? 'core' : 'chapter2';
  if (/^assets\/rpg\/props\//.test(name)) {
    if (/\/(?:front-source|side-source|landscape-source)\//.test(name) || /\/zijingang_environment(?:_source)?\.png$/.test(name)) return 'chapter2';
    if (/(?:chapter4|finale)/.test(name)) return 'chapter4';
    if (/(?:qizhen|lake|swan|fish|kayak)/.test(name)) return 'chapter35';
    if (/(?:canteen|theater)/.test(name)) return 'chapter3';
    if (/library/.test(name)) return 'chapter2';
  }
  if (/^assets\/rpg\/tiles\//.test(name)) return 'chapter2';
  if (/^assets\/ui\//.test(name)) return /library/.test(name) ? 'chapter2' : 'core';
  return null;
}
try {
  for (const entry of entries) {
    const logical = entry.path.replace(/\.(?:import|remap)$/, '');
    const group = classify(logical);
    if (group) assign(entry.path, group, `authored-path:${logical}`);
    if (/\.(?:import|remap)$/.test(entry.path)) {
      const linked = [...new Set([...readEntry(entry).matchAll(/"(res:\/\/[^"\r\n]+)"/g)].map(match => normalize(match[1])))];
      aliases.set(logical, [entry.path, ...linked.filter(name => byPath.has(name))]);
      for (const target of linked) {
        if (byPath.has(target)) links.push([entry.path, target]);
        // source_file points at the intentionally absent original image/audio.
        else if (target.startsWith('.godot/')) unresolved.push({ path: entry.path, missingImportTarget: target });
      }
    }
  }
} finally { fs.closeSync(fd); }

// Work through preloads of the scripts genuinely parsed at boot. Literal load()
// calls inside later puzzle methods are intentionally not treated as boot work.
const parsed = new Set();
const promoted = new Map();
function promote(logical, why) {
  logical = normalize(logical);
  const candidates = aliases.get(logical) || (byPath.has(logical) ? [logical] : []);
  for (const candidate of candidates) {
    const prior = ownership.get(candidate);
    if (prior?.group !== 'core') promoted.set(candidate, { from: prior?.group || 'unresolved', because: why, logicalPath: logical });
    assign(candidate, 'core', `startup:${why}`);
  }
}
function scanParsed(logical, why) {
  logical = normalize(logical);
  if (parsed.has(logical)) return;
  parsed.add(logical);
  const file = path.join(project, logical);
  if (!fs.existsSync(file)) { unresolved.push({ source: logical, reason: 'startup dependency absent in source checkout' }); return; }
  const source = fs.readFileSync(file, 'utf8');
  const dependencies = [];
  if (/\.(?:tscn|tres)$/.test(logical)) {
    dependencies.push(...[...source.matchAll(/^\[ext_resource[^\n]*path="(res:\/\/[^"\n]+)"/gm)].map(match => match[1]));
  } else {
    dependencies.push(...[...source.matchAll(/\bpreload\(\s*["'](res:\/\/[^"'\n]+)["']\s*\)/g)].map(match => match[1]));
    // Godot resolves named constant preloads while compiling the entire script,
    // even if the node that uses the texture is currently invisible. The actual
    // canteen button/fountain rigs use this form rather than literal preload().
    const pathConstants = new Map([...source.matchAll(/^const\s+([A-Za-z_]\w*)\s*(?::\s*String\s*)?(?::=|=)\s*["'](res:\/\/[^"'\n]+)["']/gm)].map(match => [match[1], match[2]]));
    for (const match of source.matchAll(/\bpreload\(\s*([A-Za-z_]\w*)\s*\)/g)) {
      if (!pathConstants.has(match[1])) throw new Error(`Unresolved startup constant preload ${logical}: ${match[1]}`);
      dependencies.push(pathConstants.get(match[1]));
    }
    dependencies.push(...[...source.matchAll(/^extends\s+["'](res:\/\/[^"'\n]+)["']/gm)].map(match => match[1]));
    // Top-level resource initializers execute when the script instance is made.
    dependencies.push(...[...source.matchAll(/^(?:@[^\n]+\s+)?(?:static\s+)?(?:var|const)\s+[^\n]*\bload\(\s*["'](res:\/\/[^"'\n]+)["']/gm)].map(match => match[1]));
    // Conservative startup constructors instantiate helper scripts with load()
    // inside setup/_build methods (e.g. the canteen mixer performances). Parsing
    // those helpers also compiles their inherited/transitive preloads. Follow
    // literal code-resource loads; do not promote arbitrary later image/audio
    // load() calls, which would erase chapter streaming.
    dependencies.push(...[...source.matchAll(/\bload\(\s*["'](res:\/\/[^"'\n]+\.(?:gd|tscn|tres))["']\s*\)/g)].map(match => match[1]).filter(name => aliases.has(normalize(name)) || byPath.has(normalize(name))));
    // An instantiated script's top-level JSON initializer is just as eager as
    // its preloads. Asset descriptors may themselves own texture paths. Shared
    // data/worlds.json is already core and deliberately does not recursively
    // promote every later chapter's background map.
    for (const match of source.matchAll(/^(?:@[^\n]+\s+)?(?:static\s+)?(?:var|const)\s+[^\n]*FileAccess\.get_file_as_string\(\s*["'](res:\/\/assets\/[^"'\n]+\.json)["']/gm)) {
      const descriptor = normalize(match[1]);
      promote(descriptor, `${logical}:eager asset descriptor`);
      const value = JSON.parse(fs.readFileSync(path.join(project, descriptor), 'utf8'));
      const visit = node => {
        if (typeof node === 'string' && node.startsWith('res://')) dependencies.push(node);
        else if (Array.isArray(node)) for (const child of node) visit(child);
        else if (node && typeof node === 'object') for (const child of Object.values(node)) visit(child);
      };
      visit(value);
    }
    // Script.new() executes _init before later scene visibility checks. World
    // eagerly constructs chapter4_world_layers -> PhaseLayers, whose _init reads
    // the NPC metadata even in Chapter 1. This metadata read does not load those
    // future NPC textures, so retain only the JSON rather than the whole family.
    for (const block of source.matchAll(/^func _init\([^]*?(?=^func |$(?![\s\S]))/gm)) {
      for (const match of block[0].matchAll(/FileAccess\.get_file_as_string\(\s*["'](res:\/\/assets\/[^"'\n]+\.json)["']/g)) promote(match[1], `${logical}:_init asset metadata`);
    }
  }
  for (const dependency of dependencies) {
    promote(dependency, `${logical} (${why})`);
    if (/\.(?:gd|tscn|tres)$/.test(dependency)) scanParsed(dependency, logical);
  }
}
const bootRoots = [
  'scripts/entry.gd', 'scripts/state.gd', 'scripts/main.gd',
  'scripts/chapters/chapter1_2.gd', 'scripts/chapters/chapter3.gd', 'scripts/chapters/chapter4.gd',
  'scripts/ui/phone_chrome.gd', 'scripts/ui/phone_object_pickup.gd', 'scripts/ui/phone_pages.gd', 'scripts/ui/chapter3_phone_pages.gd',
  'scripts/world.gd', 'scripts/ui/world_viewport_container.gd',
  'scripts/presentation/c3_narrative_host.gd', 'scripts/presentation/library_story_host.gd', 'scripts/presentation/c3_scene_host.gd',
  'scripts/media/audio_director.gd', 'scripts/media/c3_media_host.gd', 'scripts/media/c3_battery_prank.gd',
];
const eagerWorldRoots = [
  'scripts/ui/chapter4_world_layers.gd', 'scripts/ui/chapter3_world_layers.gd', 'scripts/ui/library_world_layers.gd',
  'scripts/objects/room204_table_adapter.gd', 'scripts/objects/canteen_object_scene.gd', 'scripts/objects/dorm_scene_adapter.gd',
];
if (startup === 'conservative') bootRoots.push(...eagerWorldRoots);
for (const logical of bootRoots) scanParsed(logical, 'ordinary fresh-main startup');
function scanReady(logical) {
  const source = fs.readFileSync(path.join(project, logical), 'utf8');
  const block = source.match(/^func _ready\([^]*?(?=^func |$(?![\s\S]))/m)?.[0] || '';
  for (const match of block.matchAll(/\bload\(\s*["'](res:\/\/[^"'\n]+)["']/g)) promote(match[1], `${logical}:_ready`);
}
for (const logical of ['scripts/entry.gd', 'scripts/main.gd', 'scripts/presentation/c3_opening_view.gd']) scanReady(logical);
if (startup === 'conservative') {
  scanReady('scripts/world.gd');
  const layout = JSON.parse(fs.readFileSync(path.join(project, 'data/native/canteen-object-layout.json'), 'utf8'));
  for (const asset of Object.values(layout.assets)) promote(asset.texture, 'canteen_object_scene.gd:setup loads every layout.assets texture');
  for (const logical of ['assets/rpg/interiors/dorm_hub.png', 'assets/native/dorm_cabinet/cabinet_opening_frames.png']) promote(logical, 'dorm_scene_adapter.gd:setup');
}

// An import pointer and its actual payload are indivisible. A shared payload
// gets the safer core owner if two logical paths claim different groups.
let changed = true;
while (changed) {
  changed = false;
  for (const [left, right] of links) {
    const a = ownership.get(left), b = ownership.get(right);
    let group;
    if (!a && !b) continue;
    if (!a) group = b.group;
    else if (!b || a.group === b.group) group = a.group;
    else group = 'core';
    for (const name of [left, right]) if (ownership.get(name)?.group !== group) { assign(name, group, `import/remap-unit:${left}`); changed = true; }
  }
}
for (const entry of entries) if (!ownership.has(entry.path)) {
  assign(entry.path, 'core', 'unresolved retained in core');
  unresolved.push({ path: entry.path, bytes: entry.bytes, reason: 'unclassified export entry retained in core' });
}
const groupOrder = ['core', 'chapter2', 'chapter3', 'chapter35', 'chapter4', 'campus_shared', 'campus_chaoyang', 'campus_haidian', 'campus_changping'];
const summaries = groupOrder.map(id => {
  const files = entries.filter(entry => ownership.get(entry.path).group === id).sort((a, b) => a.path.localeCompare(b.path, 'en'));
  return { id, count: files.length, payloadBytes: files.reduce((sum, entry) => sum + entry.bytes, 0), paths: files.map(entry => entry.path) };
});
const chunkLimitBytes = 24_000_000;
const chunks = [];
for (const family of summaries.filter(group => group.id !== 'core' && group.count)) {
  let current = null;
  let sequence = 0;
  // Stable first-fit decreasing avoids large, poorly cacheable chapter packs.
  // Pack membership remains deterministic for a fixed complete export.
  const bins = [];
  const sorted = family.paths.map(name => byPath.get(name)).sort((a, b) => b.bytes - a.bytes || a.path.localeCompare(b.path, 'en'));
  for (const entry of sorted) {
    // PCKPacker also writes file alignment and a path/hash directory. Reserve
    // 128 bytes per entry plus its UTF-8 path and a 256-byte pack header, which
    // is greater than the 4.7.2 format's 32-byte alignment/directory overhead.
    const budgetBytes = entry.bytes + Buffer.byteLength(entry.path, 'utf8') + 128;
    if (budgetBytes + 256 > chunkLimitBytes) throw new Error(`Resource exceeds ${chunkLimitBytes}-byte content chunk budget: ${entry.path} (${entry.bytes}); split/convert the authored resource explicitly`);
    current = bins.find(bin => bin.estimatedPackBytes + budgetBytes <= chunkLimitBytes);
    if (!current) { current = { family: family.id, id: `${family.id}_${String(++sequence).padStart(3, '0')}`, paths: [], payloadBytes: 0, estimatedPackBytes: 256 }; bins.push(current); }
    current.paths.push(entry.path);
    current.payloadBytes += entry.bytes;
    current.estimatedPackBytes += budgetBytes;
  }
  for (const bin of bins) { bin.paths.sort((a, b) => a.localeCompare(b, 'en')); chunks.push(bin); }
}
const plan = { schemaVersion: 1, coreId: 'core', groups: chunks.map(({ id, paths }) => ({ id, paths })) };
const report = {
  schemaVersion: 1, mode: startup,
  inventorySha256: crypto.createHash('sha256').update(fs.readFileSync(inventoryFile)).digest('hex'),
  input: path.resolve(input), packBytes, entryCount: entries.length,
  totalPayloadBytes: entries.reduce((sum, entry) => sum + entry.bytes, 0),
  groups: summaries.map(({ paths, ...group }) => group),
  chunkLimitBytes,
  chunks: chunks.map(({ paths, ...chunk }) => ({ ...chunk, count: paths.length })),
  startupParsedScripts: [...parsed].sort(),
  startupPromotions: [...promoted].map(([path, value]) => ({ path, ...value })), unresolved,
  acceptance: startup === 'lazy-world' ? 'Planning estimate only; requires the eager world constructors to be deferred before this grouping is usable.' : 'Conservative source review, not browser acceptance. Verify fresh start, ordinary later-save Continue/import, every transition, missing-pack recovery and background caching using the split export.',
};
fs.mkdirSync(path.dirname(path.resolve(output)), { recursive: true });
fs.writeFileSync(output, JSON.stringify(plan, null, 2) + '\n');
fs.writeFileSync(output.replace(/\.json$/, '') + '.report.json', JSON.stringify(report, null, 2) + '\n');
console.log(JSON.stringify({ output: path.resolve(output), mode: startup, groups: report.groups, promoted: promoted.size, unresolved: unresolved.length }, null, 2));
