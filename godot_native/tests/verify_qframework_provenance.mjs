import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
const vendor = path.resolve(import.meta.dirname, '../addons/qframework');
const manifest = JSON.parse(fs.readFileSync(path.join(vendor, 'UPSTREAM.json'), 'utf8'));
assert.equal(manifest.repository, 'https://github.com/liangxiegame/QFramework');
assert.match(manifest.commit, /^[a-f0-9]{40}$/);
assert.equal(manifest.license, 'MIT');
assert.deepEqual(manifest.local_modifications, []);
assert.equal(Object.keys(manifest.files).length, 7);
for (const [file, expected] of Object.entries(manifest.files)) {
  const actual = createHash('sha256').update(fs.readFileSync(path.join(vendor, file))).digest('hex');
  assert.equal(actual, expected, `Vendored QFramework changed: ${file}. Update provenance deliberately.`);
}
assert.match(fs.readFileSync(path.join(vendor, 'LICENSE'), 'utf8'), /Copyright \(c\) 2025 凉鞋/);
console.log('QFramework provenance: 6 unmodified official runtime scripts and MIT license verified.');
