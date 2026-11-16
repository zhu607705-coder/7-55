import fs from 'node:fs';
import path from 'node:path';
import { fileSha256 } from './web_content_delivery.mjs';
import { verifyBootChunks } from './web_boot_chunks.mjs';
import { verifyContentChunks } from './web_content_chunks.mjs';
import { assertTokenizedWebScripts } from './web_story_content_policy.mjs';
import { prepareWebCompression, verifyWebCompression } from './web_precompress.mjs';

// Derive a second artifact instead of taking content away from campaign QA.
// Unknown content families require an explicit release decision.
const allowed = new Set(['phone_bonsai', 'phone_tiyi', 'phone_zjuding', 'chapter2', 'chapter2_campus', 'chapter2_library', 'flc_activity']);
const withheld = new Set(['chapter3', 'chapter35', 'chapter4']);
const manifestFile = 'content-manifest.json';
const internalFiles = new Set(['source-inputs.json', 'pack-inventory.json', 'content-inventory.json']);
const mobileStartupBudgetBytes = 30_000_000;
const sum = (items, key) => items.reduce((total, item) => total + item[key], 0);
const option = name => process.argv.slice(2).find(arg => arg.startsWith(`--${name}=`))?.slice(name.length + 3);
const input = fs.realpathSync(option('input') || 'godot_native/exports/web-release');
const destination = path.resolve(option('output') || 'godot_native/exports/web-pages');
const read = (directory, file) => JSON.parse(fs.readFileSync(path.join(directory, file), 'utf8'));
const write = (directory, file, value) => fs.writeFileSync(path.join(directory, file), JSON.stringify(value, null, 2) + '\n');

function assert(ok, message) {
  if (!ok) throw new Error(message);
}

function checkedFile(directory, file) {
  assert(typeof file === 'string' && /^(?:[a-zA-Z0-9_.-]+\/)*[a-zA-Z0-9_.-]+$/.test(file)
    && file.split('/').every(part => part !== '.' && part !== '..'), `Invalid Pages artifact path: ${file}`);
  const full = path.join(directory, file);
  assert(fs.realpathSync(full) === full && fs.lstatSync(full).isFile(), `Pages artifact includes a non-regular file: ${file}`);
  return full;
}

function identity(directory, file) {
  const full = checkedFile(directory, file);
  return { path: file, bytes: fs.statSync(full).size, sha256: fileSha256(full) };
}

function copy(file, directory, from = input) {
  const source = checkedFile(from, file);
  const target = path.join(directory, file);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.copyFileSync(source, target, fs.constants.COPYFILE_EXCL);
}

function verifyIdentity(files, file, record) {
  const actual = files.get(file);
  assert(actual?.bytes === record.bytes && actual?.sha256 === record.sha256, `Pages identity differs: ${file}`);
}

const build = read(input, 'build-manifest.json');
const content = read(input, 'content-manifest.json');
const inventory = read(input, 'content-inventory.json');
assert(build.schema === '7-55-godot-web-release/v1' && build.delivery === 'chapter-content-packs'
  && build.engine === '4.7.1.stable.official' && build.production && build.storyOnly && !build.chapterShortcuts
  && build.content?.exactCoverage === true && !build.releasePolicy, 'Expected a full verified Godot Web export');
assert(!process.env.GITHUB_SHA || (build.sourceCommit === process.env.GITHUB_SHA && !build.sourceDirty),
  'Pages source differs from the accepted CI commit');
assert(content.schema === '755-web-content-v1' && content.engine === '4.7.1'
  && content.packs.length === build.content.packs && !Object.hasOwn(content, 'publicChapterLimit'), 'Invalid full story manifest');
assert(inventory.schema === '755-web-content-inventory-v1'
  && fileSha256(checkedFile(input, 'content-inventory.json')) === build.content.inventorySha256, 'Full story inventory differs from its manifest');

const originals = new Map(build.files.map(item => [item.path, item]));
assert(originals.size === build.files.length, 'Duplicate source build file records');
for (const file of [manifestFile, 'content-inventory.json']) verifyIdentity(originals, file, identity(input, file));
const sourceContentPaths = new Set();
for (const pack of content.packs) {
  assert(allowed.has(pack.family) || withheld.has(pack.family), `Unclassified Pages content family: ${pack.family}`);
  for (const record of [pack, ...(pack.transportChunks ?? [])]) {
    assert(record.file.startsWith('content/') && !sourceContentPaths.has(record.file), `Invalid or shared story content path: ${record.file}`);
    sourceContentPaths.add(record.file);
    verifyIdentity(originals, record.file, record);
  }
}
const packs = content.packs.filter(pack => allowed.has(pack.family));
assert(packs.length < content.packs.length && packs.some(pack => pack.family === 'chapter2'), 'Pages projection must retain Chapter 2 and remove later chapters');
const backgroundOrder = content.backgroundOrder.filter(family => !withheld.has(family));
assert(backgroundOrder.every(family => packs.some(pack => pack.family === family)), 'Pages background order references missing content');
const publicContent = { ...content, packs, backgroundOrder, publicChapterLimit: 2 };
const publishedPaths = new Set(packs.flatMap(pack => [pack.file, ...(pack.transportChunks ?? []).map(chunk => chunk.file)]));
const groupIDs = new Set([inventory.coreId, ...packs.map(pack => pack.id)]);
const groups = inventory.groups.filter(group => groupIDs.has(group.id));
const entries = inventory.entries.filter(entry => groupIDs.has(entry.group));
assert(groups.length === groupIDs.size && sum(groups, 'entries') === entries.length, 'Pages story inventory does not account for every retained pack');

assertTokenizedWebScripts(entries);

function keep(file) {
  const original = file.endsWith('.gz') ? file.slice(0, -3) : file;
  if (original === manifestFile || internalFiles.has(original)) return false;
  assert(!/\.(?:gd|map|blend1?|psd|kra)$/i.test(original), `Authoring or diagnostic file in Pages artifact: ${original}`);
  if (!original.startsWith('content/')) return true;
  assert(sourceContentPaths.has(original), `Unclassified content artifact file: ${original}`);
  return publishedPaths.has(original);
}

const outputParent = path.dirname(destination);
fs.mkdirSync(outputParent, { recursive: true });
assert(fs.realpathSync(outputParent) === outputParent
  && destination !== input && !destination.startsWith(input + path.sep) && !input.startsWith(destination + path.sep),
  'Pages output must be separate from the full campaign artifact');
const previous = fs.lstatSync(destination, { throwIfNoEntry: false });
if (previous) {
  assert(process.argv.includes('--replace') && previous.isDirectory()
    && read(destination, 'build-manifest.json').releasePolicy?.publicChapterLimit === 2, 'Use --replace only to update a prior capped Pages artifact');
}
const temp = fs.mkdtempSync(path.join(outputParent, '.pages-build-'));
const site = path.join(temp, 'site');
const rollback = path.join(temp, 'previous');
fs.mkdirSync(site);
try {
  const copied = build.files.filter(file => keep(file.path));
  for (const file of copied) {
    copy(file.path, site);
    verifyIdentity(originals, file.path, identity(site, file.path));
  }
  copy('.nojekyll', site);
  write(site, manifestFile, publicContent);

  const json = path.join(temp, 'json');
  fs.mkdirSync(json);
  copy(manifestFile, json, site);
  const compressedJson = prepareWebCompression(json);
  for (const file of compressedJson.files) copy(file.file, site, json);
  const compressionFiles = [...(build.transportCompression?.files ?? []).filter(record => keep(record.file)), ...compressedJson.files]
    .sort((a, b) => a.source.localeCompare(b.source));
  const transportCompression = {
    ...compressedJson, files: compressionFiles,
    bytes: sum(compressionFiles, 'bytes'), sourceBytes: sum(compressionFiles, 'sourceBytes'),
    savedBytes: sum(compressionFiles, 'sourceBytes') - sum(compressionFiles, 'bytes'),
  };
  const compressedPaths = verifyWebCompression(site, transportCompression).files.map(record => record.file);
  const boot = verifyBootChunks(site, build.bootChunks, { verifiedCompressedFiles: compressedPaths });
  const transportChunks = verifyContentChunks(site, packs, { verifiedCompressedFiles: compressedPaths });
  const files = [...copied, ...[manifestFile, ...compressedJson.files.map(record => record.file)].map(file => identity(site, file))]
    .sort((a, b) => a.path.localeCompare(b.path));
  const actualFiles = new Map(files.map(file => [file.path, file]));
  for (const pack of [content.core, ...packs]) verifyIdentity(actualFiles, pack.file, pack);
  const initialFiles = files.filter(file => !file.path.startsWith('liangzhu-trailer/') && !file.path.endsWith('.gz')
    && !file.path.startsWith('content/') && !['index.pck', 'index.wasm'].includes(file.path));
  const gzipBySource = new Map(compressionFiles.map(record => [record.source, record]));
  const initialGzipPayloadBytes = initialFiles.reduce((bytes, file) => bytes + (gzipBySource.get(file.path)?.bytes ?? file.bytes), 0);
  // Count one transfer representation per game resource, including activities.
  // The standalone trailer pages and build-time audit files are separate.
  const gameGzipPayloadBytes = packs.reduce((bytes, pack) => bytes + (pack.transportChunks ?? [pack])
    .reduce((packed, resource) => packed + (gzipBySource.get(resource.file)?.bytes ?? resource.bytes), 0), initialGzipPayloadBytes);
  assert(initialGzipPayloadBytes <= mobileStartupBudgetBytes,
    `Pages startup payload ${initialGzipPayloadBytes} bytes exceeds the ${mobileStartupBudgetBytes}-byte mobile transfer budget`);
  const totalPayloadBytes = sum(files, 'bytes');
  const releasePolicy = {
    publicChapterLimit: 2,
    sourceBuildSha256: fileSha256(checkedFile(input, 'build-manifest.json')),
    withheldFamilies: [...withheld],
  };
  const { sourceChanges, content: { inventorySha256, ...contentBuild }, ...publicBuild } = build;
  const publishedBuild = {
    ...publicBuild, releasePolicy, files, totalPayloadBytes, transportCompression,
    logicalPayloadBytes: totalPayloadBytes - transportCompression.bytes - boot.bytes - transportChunks.bytes,
    initialPayloadBytes: sum(initialFiles, 'bytes'),
    initialGzipPayloadBytes,
    gameGzipPayloadBytes,
    fullPack: { ...build.fullPack, role: 'source-full-export' },
    content: { ...contentBuild, packs: packs.length, deferredBytes: sum(packs, 'bytes'),
      exactCoverage: false, exactPublishedCoverage: true, entryCount: entries.length, transportChunks,
    },
    acceptance: 'Verified Pages projection of the full campaign artifact. Later story families are omitted.',
  };
  write(site, 'build-manifest.json', publishedBuild);

  if (previous) fs.renameSync(destination, rollback);
  try { fs.renameSync(site, destination); }
  catch (error) {
    if (previous) fs.renameSync(rollback, destination);
    throw error;
  }
  if (previous) fs.rmSync(rollback, { recursive: true });
  console.log(JSON.stringify({ output: destination, sourceCommit: build.sourceCommit, ...releasePolicy,
    publishedPacks: packs.length, withdrawnPacks: content.packs.length - packs.length, initialGzipPayloadBytes, gameGzipPayloadBytes, totalPayloadBytes }, null, 2));
} finally {
  if (!fs.existsSync(rollback)) fs.rmSync(temp, { recursive: true, force: true });
}
