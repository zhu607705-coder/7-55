import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

// Keep these directories beside one another: entry.gd launches independent
// example projects relative to godot_native's parent directory.
export const sourceRoots = ['godot_native', 'examples', 'samples'];
// These are immutable PR #148/#151 source records, not local QA output.
// Preserve the authored names/bytes and keep every other .log excluded.
export const sourceOriginalLogs = Object.freeze([
  'examples/blender_stair_sample/verification/test-beam.log',
  'examples/blender_stair_sample/verification/test-camera-input.log',
  'examples/blender_stair_sample/verification/test-sample.log',
  'examples/qizhen_blender_nearshore/verification/capture-final.log',
  'examples/qizhen_blender_nearshore/verification/original-audit_large_world.log',
  'examples/qizhen_blender_nearshore/verification/original-test_input_camera.log',
  'examples/qizhen_blender_nearshore/verification/original-test_large_world.log',
  'examples/qizhen_blender_nearshore/verification/test-blender-sample.log',
  'examples/qizhen_blender_nearshore/verification/test-sample-route.log',
]);
const sourceOriginalLogSet = new Set(sourceOriginalLogs);
const excludedDirectories = new Set([
  '.git', '.godot', 'node_modules', 'exports', 'log', 'logs',
  '.screenshots', '.qa', '_qa', 'qa-artifacts', 'qa-tmp', 'tmp-qa',
  '__pycache__',
]);

export function exclusionReason(relativePath, isDirectory) {
  const name = path.posix.basename(relativePath);
  if (isDirectory && excludedDirectories.has(name)) return 'cache, export, log, or temporary QA directory';
  if (!isDirectory && sourceOriginalLogSet.has(relativePath)) return '';
  if (!isDirectory && (name === '.git' || name === '.DS_Store' || name.endsWith('.log') || name.endsWith('.pyc'))) return 'local metadata or log';
  return '';
}

export function collectSources(repository, omittedPaths = []) {
  const omitted = new Set(omittedPaths.map(value => path.resolve(value)));
  const entries = [];
  const excluded = [];
  const totals = {};
  function visit(relativePath, root) {
    const absolute = path.join(repository, relativePath);
    if (omitted.has(absolute)) return;
    const stat = fs.lstatSync(absolute);
    const reason = exclusionReason(relativePath, stat.isDirectory());
    if (reason) { excluded.push({ path: relativePath, reason }); return; }
    if (/[\r\n]/.test(relativePath)) throw Error('ZIP line-list cannot represent filename: ' + JSON.stringify(relativePath));
    // Reject links rather than silently produce an archive with external data
    // dependencies or traverse outside the requested source directories.
    if (stat.isSymbolicLink()) throw Error('Source archive requires regular files, not symlinks: ' + relativePath);
    if (stat.isDirectory()) {
      entries.push(relativePath + '/');
      for (const name of fs.readdirSync(absolute).sort()) visit(relativePath + '/' + name, root);
    } else if (stat.isFile()) {
      entries.push(relativePath);
      totals[root].files += 1;
      totals[root].bytes += stat.size;
    } else throw Error('Unsupported source entry: ' + relativePath);
  }
  for (const root of sourceRoots) {
    if (!fs.statSync(path.join(repository, root)).isDirectory()) throw Error('Missing source directory: ' + root);
    totals[root] = { files: 0, bytes: 0 };
    visit(root, root);
  }
  return { entries, excluded, totals };
}

export function verifyIntegrationCoverage(repository, included) {
  const manifest = JSON.parse(fs.readFileSync(path.join(repository, 'godot_native/docs/FULL_INTEGRATION_SOURCES_20261019.json'), 'utf8'));
  if (!Array.isArray(manifest.open_prs) || manifest.open_prs.length === 0) throw Error('Missing integration source dispositions');
  const required = new Set();
  const outsideSourceRoots = new Set();
  for (const entry of manifest.open_prs) {
    if (!Array.isArray(entry.required_paths)) throw Error('Invalid required source paths for PR ' + entry.pr);
    for (const relative of new Set([entry.evidence_path, ...entry.required_paths])) {
      if (typeof relative !== 'string' || path.posix.isAbsolute(relative) || path.posix.normalize(relative) !== relative || relative.split('/').includes('..')) throw Error('Invalid integration source path');
      if (sourceRoots.some(root => relative === root || relative.startsWith(root + '/'))) {
        required.add(relative);
        if (!included.has(relative)) throw Error('PR #' + entry.pr + ' source omitted from integration archive: ' + relative);
      } else outsideSourceRoots.add(relative);
    }
  }
  for (const relative of sourceOriginalLogs) if (!required.has(relative)) throw Error('Original log allowlist must be registered in source manifest: ' + relative);
  return { prs: manifest.open_prs.length, uniqueRequiredPaths: required.size, originalSourceLogs: sourceOriginalLogs.length, outsideSourceRoots: outsideSourceRoots.size };
}

function main() {
  const args = process.argv.slice(2);
  if (args.includes('--help')) {
    console.log('Usage: node godot_native/tools/package_integration.mjs [output.zip] [--dry-run] [--list]');
    console.log('Packages godot_native/, examples/, and samples/ as sibling source directories.');
    return;
  }
  const positional = args.filter(value => !value.startsWith('--'));
  const unknown = args.filter(value => value.startsWith('--') && !['--dry-run', '--list'].includes(value));
  if (positional.length > 1 || unknown.length) throw Error('Invalid arguments. Use --help for usage.');
  const repository = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
  const target = path.resolve(positional[0] || path.join(repository, 'godot_native/exports/7-55-integrated-source-20261019.zip'));
  if (!target.endsWith('.zip')) throw Error('Output filename must end with .zip');
  const temporary = path.join(path.dirname(target), '.' + path.basename(target, '.zip') + '-' + process.pid + '.tmp.zip');
  const inventory = collectSources(repository, [target, temporary]);
  const included = new Set(inventory.entries);
  const sourceCoverage = verifyIntegrationCoverage(repository, included);
  // Generated assets, native source data, authored verification evidence, and
  // Blender source files are deliberately included. Do not add broad rules for
  // generated/, source/, data/, tests/, or verification/ here.
  for (const required of [
    'godot_native/project.godot',
    'godot_native/scenes/entry.tscn',
    'godot_native/scenes/main.tscn',
    'godot_native/data/initial_state.json',
    'godot_native/data/worlds.json',
    'godot_native/data/asset_manifest.json',
    'godot_native/assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf',
    'godot_native/data/source/items.config.json',
    'godot_native/assets/rpg/cinematics/chapter4-prologue/chapter35_to_chapter4_h3_transition.ogv',
    'godot_native/assets/rpg/cinematics/qizhen-rain-rescue/qizhen_rain_rescue_hailuo23_v01.ogv',
    'examples/qizhen_playable_chase/project.godot',
    'examples/qizhen_large_world/project.godot',
    'examples/blender_stair_sample/preview/project.godot',
    'examples/qizhen_blender_nearshore/preview/project.godot',
    'examples/legacy_godot_theater/godot-port/project.godot',
    'examples/legacy_godot_theater/godot-port/generated/theater.json',
    'examples/blender_stair_sample/source/stairwell_sample.blend',
    'examples/qizhen_blender_nearshore/source/qizhen_north_bank.blend',
    'samples/qizhen-rain-rescue-native/project.godot',
  ]) if (!included.has(required)) throw Error('Missing integrated source: ' + required + '; prepare source assets first');
  // The synchronized Web asset inventory supplies a complete baseline for the
  // formal campaign, including dynamically constructed source asset paths.
  const manifest = JSON.parse(fs.readFileSync(path.join(repository, 'godot_native/data/asset_manifest.json'), 'utf8'));
  if (!Array.isArray(manifest.assets) || manifest.assetCount !== manifest.assets.length) throw Error('Invalid native source asset inventory');
  for (const asset of manifest.assets) {
    if (typeof asset.path !== 'string' || !asset.path.startsWith('assets/') || path.posix.normalize(asset.path) !== asset.path) throw Error('Invalid native source asset path');
    const relative = 'godot_native/' + asset.path;
    if (!included.has(relative)) throw Error('Missing campaign asset: ' + relative);
    if (fs.statSync(path.join(repository, relative)).size !== asset.bytes) throw Error('Incomplete campaign asset: ' + relative);
  }
  console.log(JSON.stringify({ target, totals: inventory.totals, sourceCoverage, excluded: inventory.excluded }, null, 2));
  if (args.includes('--list')) console.log(inventory.entries.join('\n'));
  if (args.includes('--dry-run')) { console.log('Dry run: no archive written.'); return; }
  fs.mkdirSync(path.dirname(target), { recursive: true });
  try {
    const result = spawnSync('zip', ['-q', '-X', temporary, '-@'], {
      cwd: repository, input: inventory.entries.join('\n') + '\n', stdio: ['pipe', 'inherit', 'inherit'],
    });
    if (result.error) throw result.error;
    if (result.status !== 0) throw Error('ZIP creation failed with exit code ' + result.status);
    const verification = spawnSync('unzip', ['-tq', temporary], { stdio: 'inherit' });
    if (verification.error) throw verification.error;
    if (verification.status !== 0) throw Error('ZIP integrity verification failed');
    fs.renameSync(temporary, target);
  } finally {
    if (fs.existsSync(temporary)) fs.unlinkSync(temporary);
  }
  console.log(target + ' ' + fs.statSync(target).size + ' bytes');
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main();
