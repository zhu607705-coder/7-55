// Source-path identities also cover anonymous Godot import/export payloads.
// Excluding only a logical campuses/ path would miss leaked .ctex/.scn files.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

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
  return {
    sourceResources: hashes.size,
    owner(name) {
      name = name.replace(/^res:\/\//, '');
      if (name.startsWith('campuses/')) return name;
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
    if (owner) throw new Error(`Research campus resource leaked into story-only PCK: ${entry.path} ← ${owner}`);
  }
}
