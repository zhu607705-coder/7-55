// Pure deterministic packing shared by planning and independent delivery checks.
// Ownership is decided by the startup planner; this module never moves a path
// between lifecycle families or adds anything to the boot core.
import { CONTENT_PACK_TARGET, CONTENT_PACK_LIMIT } from './web_content_chunks.mjs';

export const CONTENT_FAMILY_ORDER = ['core', 'phone_bonsai', 'phone_tiyi', 'phone_zjuding', 'chapter2', 'chapter2_campus', 'chapter2_library', 'chapter3', 'chapter35', 'chapter4', 'flc_activity', 'campus_shared', 'campus_chaoyang', 'campus_haidian', 'campus_changping'];
export function packContentFamilies(families, entries) {
  const byPath = new Map(entries.map(entry => [entry.path, entry]));
  const chunks = [];
  for (const family of families.filter(group => group.id !== 'core' && group.paths.length)) {
    let current = null;
    let sequence = 0;
    // Stable first-fit decreasing avoids large, poorly cacheable chapter packs.
    // Pack membership remains deterministic for a fixed complete export.
    const bins = [];
    const sorted = family.paths.map(name => byPath.get(name)).sort((a, b) => b.bytes - a.bytes || a.path.localeCompare(b.path, 'en'));
    for (const entry of sorted) {
      // PCKPacker also writes file alignment and a path/hash directory. Reserve
      // 128 bytes per entry plus its UTF-8 path and a 256-byte pack header, which
      // is greater than the supported PCK format's 32-byte alignment/directory overhead.
      const budgetBytes = entry.bytes + Buffer.byteLength(entry.path, 'utf8') + 128;
      if (budgetBytes + 256 > CONTENT_PACK_LIMIT) throw new Error(`Resource exceeds ${CONTENT_PACK_LIMIT}-byte content chunk budget: ${entry.path} (${entry.bytes}); split/convert the authored resource explicitly`);
      // A single immutable resource may exceed the ordinary target. Keep it
      // alone, record the exception, and retain the unchanged 24 MB hard limit.
      const oversized = budgetBytes + 256 > CONTENT_PACK_TARGET;
      current = oversized ? null : bins.find(bin => !bin.oversizedResource && bin.estimatedPackBytes + budgetBytes <= CONTENT_PACK_TARGET);
      if (!current) { current = { family: family.id, id: `${family.id}_${String(++sequence).padStart(3, '0')}`, paths: [], payloadBytes: 0, estimatedPackBytes: 256 }; bins.push(current); }
      if (oversized) current.oversizedResource = entry.path;
      current.paths.push(entry.path);
      current.payloadBytes += entry.bytes;
      current.estimatedPackBytes += budgetBytes;
    }
    for (const bin of bins) { bin.paths.sort((a, b) => a.localeCompare(b, 'en')); chunks.push(bin); }
}
const ordinaryPackCount = chunks.length;
const merges = [];
// Preserve the ordinary plan exactly unless the browser's existing limit is
// exceeded. Each merge removes exactly one pack, the minimum necessary change.
// Pick the smallest same-family pair, breaking ties by original bin order.
// Never absorb an immutable single-resource exception into another pack.
while (chunks.length > 100) {
  let selected = null;
  for (let left = 0; left < chunks.length; left++) {
    const a = chunks[left];
    if (a.oversizedResource) continue;
    for (let right = left + 1; right < chunks.length; right++) {
      const b = chunks[right];
      if (b.oversizedResource || a.family !== b.family) continue;
      const bytes = a.estimatedPackBytes + b.estimatedPackBytes - 256;
      if (bytes <= CONTENT_PACK_LIMIT && (!selected || bytes < selected.bytes)) selected = { left, right, bytes };
    }
  }
  if (!selected) throw new Error(`Content plan cannot meet the browser's 100-pack limit within same-family ${CONTENT_PACK_LIMIT}-byte budgets: ${chunks.length}`);
  const { left, right, bytes } = selected;
  const a = chunks[left], b = chunks[right];
  a.pressureSources = [...(a.pressureSources || [a.id]), ...(b.pressureSources || [b.id])];
  a.paths = [...a.paths, ...b.paths].sort((a, b) => a.localeCompare(b, 'en'));
  a.payloadBytes += b.payloadBytes;
  a.estimatedPackBytes = bytes;
  merges.push({ id: a.id, absorbed: b.id, estimatedPackBytes: bytes });
  chunks.splice(right, 1);
}
return { chunks, ordinaryPackCount, merges };
}

// Rebuild the required plan from the complete-export entries, not exception
// labels in the manifest. Reject unnecessary pressure and altered membership.
export function verifyContentPacking(entries, coreId = 'core') {
  const deferred = entries.filter(entry => entry.group !== coreId);
  const families = CONTENT_FAMILY_ORDER.filter(id => id !== 'core').map(id => ({
    id, paths: deferred.filter(entry => entry.group.replace(/_\d+$/, '') === id).map(entry => entry.path),
  }));
  if (families.reduce((sum, family) => sum + family.paths.length, 0) !== deferred.length) throw new Error('Unknown deferred packing family');
  const result = packContentFamilies(families, entries);
  const expected = new Map(result.chunks.flatMap(chunk => chunk.paths.map(name => [name, chunk.id])));
  if (deferred.some(entry => expected.get(entry.path) !== entry.group)) throw new Error('Deferred pack membership differs from deterministic count-budget plan');
  return result;
}
