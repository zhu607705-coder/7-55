/** Native-only display copy. Original English voice sources and browser content stay immutable. */
import fs from 'node:fs';
import path from 'node:path';
const prohibited = /^(?:speaker|voiceRole|voiceTextEn|voice_text_en|delivery|tone|id|key|voice_key|durationMs|offsetMs|startMs|endMs|condition|event|asset|path)$/;
export function readTextRevisions(root) {
  const spec = JSON.parse(fs.readFileSync(path.join(root, 'godot_native/data/zh_text_revisions.json'), 'utf8'));
  if (spec.version !== 1 || !Array.isArray(spec.revisions) || !Array.isArray(spec.nativeRevisions)) throw Error('Unsupported native Chinese revision schema');
  return spec;
}
export function applyTextRevisions(data, entries, label = '') {
  const seen = new Set();
  for (const revision of entries) {
    const {path: keys, oldText, newText} = revision;
    if (!Array.isArray(keys) || keys.length === 0 || keys.some(k => typeof k !== 'string' && !Number.isInteger(k)) || typeof oldText !== 'string' || typeof newText !== 'string' || !newText.trim()) throw Error(`Invalid Chinese revision: ${label}`);
    if (keys.some(k => ['__proto__', 'prototype', 'constructor'].includes(k)) || prohibited.test(String(keys.at(-1)))) throw Error(`Non-display field in Chinese revision: ${label} ${JSON.stringify(keys)}`);
    const address = JSON.stringify(keys);
    if (seen.has(address)) throw Error(`Duplicate Chinese revision: ${label} ${address}`);
    seen.add(address);
    let parent = data;
    for (const key of keys.slice(0, -1)) {
      if (parent == null || !Object.hasOwn(parent, key)) throw Error(`Missing Chinese revision path: ${label} ${address}`);
      parent = parent[key];
    }
    const leaf = keys.at(-1);
    if (!Object.hasOwn(parent, leaf) || parent[leaf] !== oldText) throw Error(`Original Chinese text changed: ${label} ${address}`);
    parent[leaf] = newText;
  }
  return data;
}
export function applySourceTextRevisions(root, file, data) {
  return applyTextRevisions(data, readTextRevisions(root).revisions.filter(x => x.sourceFile === file), file);
}
export function applyNativeTextRevisions(root, file, data) {
  return applyTextRevisions(data, readTextRevisions(root).nativeRevisions.filter(x => x.sourceFile === file), file);
}
export function synchronizeSourceTextRevisions(root, {check = false} = {}) {
  const {revisions} = readTextRevisions(root);
  let count = 0;
  for (const file of new Set(revisions.map(x => x.sourceFile))) {
    if (file !== path.basename(file) || !file.endsWith('.json')) throw Error(`Invalid source content filename: ${file}`);
    const original = JSON.parse(fs.readFileSync(path.join(root, 'src/data', file), 'utf8'));
    const revised = applySourceTextRevisions(root, file, original);
    const target = path.join(root, 'godot_native/data/source', file);
    if (check) {
      if (JSON.stringify(JSON.parse(fs.readFileSync(target, 'utf8'))) !== JSON.stringify(revised)) throw Error(`Native Chinese copy is stale: ${file}`);
    } else fs.writeFileSync(target, JSON.stringify(revised, null, 2) + '\n');
    count++;
  }
  return {files: count, replacements: revisions.length};
}
