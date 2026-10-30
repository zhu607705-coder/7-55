// Source-path identities also cover anonymous Godot import/export payloads.
// Excluding only a logical campuses/ path would miss leaked .ctex/.scn files.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

// Only authored runtime inputs of the approved optional activity are shipped.
// Unknown/new campus roots still fail closed in the actual PCK audit.
export const FLC_FONT_DEPENDENCIES = Object.freeze([
  "campuses/future_learning_center/assets/fonts/flc_coverage_regular.otf",
  "ui_assets/fonts/SelectedSans-Regular.otf",
  "ui_assets/fonts/SelectedCoverage-Regular.otf",
]);

export function isFlcRuntimePath(name) {
  name = name.replace(/^res:\/\//, '').replace(/\.(?:import|remap)$/, '');
  if (FLC_FONT_DEPENDENCIES.includes(name)) return true;
  return /^campuses\/future_learning_center\/(?:scripts\/.+\.(?:gd|gdc)|scenes\/.+\.(?:tscn|scn|tres|res)|data\/.+\.json|assets\/.+\.(?:png|webp|jpg|jpeg|svg|json|ogg|wav|mp3|ttf|tres|res))$/.test(name)
    && !name.split('/').some(part => part === '..' || part === '.');
}

export function campusPayloadIdentity(project) {
  const hashes = new Map();
  const imported = new Map();
  function visit(directory) {
    if (!fs.existsSync(directory)) return;
    for (const item of fs.readdirSync(directory, { withFileTypes: true })) {
      const file = path.join(directory, item.name);
      if (item.isSymbolicLink()) throw new Error(`Unexpected campus source symlink: ${file}`);
      if (item.isDirectory()) { visit(file); continue; }
      const logical = path.relative(project, file).split(path.sep).join('/');
      if (logical.endsWith('.import')) {
        for (const match of fs.readFileSync(file, 'utf8').matchAll(/"res:\/\/(\.godot\/[^"\r\n]+)"/g)) imported.set(match[1], logical.slice(0, -7));
      } else if (!logical.endsWith('.uid')) {
        hashes.set(crypto.createHash('md5').update(`res://${logical}`).digest('hex'), logical);
      }
    }
  }
  visit(path.join(project, 'campuses'));
  // These two physical-bench typefaces are explicit optional-activity inputs,
  // not shared first-paint UI fonts. Track their anonymous payloads as well.
  for (const logical of FLC_FONT_DEPENDENCIES) {
    if (!fs.existsSync(path.join(project, logical))) continue;
    hashes.set(crypto.createHash('md5').update(`res://${logical}`).digest('hex'), logical);
    const metadata = path.join(project, logical + '.import');
    if (fs.existsSync(metadata))
      for (const match of fs.readFileSync(metadata, 'utf8').matchAll(/"res:\/\/(\.godot\/[^"\r\n]+)"/g)) imported.set(match[1], logical);
  }
  return {
    sourceResources: hashes.size,
    owner(name) {
      name = name.replace(/^res:\/\//, '');
      if (name.startsWith('campuses/') || FLC_FONT_DEPENDENCIES.includes(name.replace(/\.(?:import|remap)$/, ''))) return name.replace(/\.(?:import|remap)$/, '');
      if (imported.has(name)) return imported.get(name);
      // Godot identifies imported variants and compiled text resources by the
      // MD5 of their complete original res:// path, independent of export ID.
      const key = name.match(/^\.godot\/imported\/[^/]+-([a-f0-9]{32})(?:\.|$)/)?.[1]
        || name.match(/^\.godot\/exported\/[^/]+\/export-([a-f0-9]{32})-/)?.[1];
      return key ? hashes.get(key) ?? null : null;
    },
  };
}

export function assertStoryOnlyPackEntries(entries, identity) {
  for (const entry of entries) {
    const owner = identity.owner(entry.path);
    if (owner && !isFlcRuntimePath(owner)) throw new Error(`Research campus resource leaked into story-only PCK: ${entry.path} ← ${owner}`);
  }
}
