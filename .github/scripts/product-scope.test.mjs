import test from 'node:test';
import assert from 'node:assert/strict';
import { changedProducts, compareRange } from './product-scope.mjs';

test('platform-only paths do not schedule game builds or deployments', () => {
  assert.deepEqual(changedProducts(['platform/apps/web/src/app/App.tsx', 'platform/package-lock.json', '.github/workflows/platform-ci.yml']), { game: false, platform: true });
});
test('game, mixed, shared, renamed and deleted paths are conservative', () => {
  assert.deepEqual(changedProducts(['godot_native/scripts/main.gd']), { game: true, platform: false });
  assert.deepEqual(changedProducts(['src/App.tsx', 'platform/apps/web/src/main.tsx']), { game: true, platform: true });
  assert.deepEqual(changedProducts(['.github/scripts/product-scope.mjs']), { game: true, platform: true });
  assert.deepEqual(changedProducts(['README.md']), { game: true, platform: true });
  assert.deepEqual(changedProducts(['platform/deleted-file.ts']), { game: false, platform: true });
});
test('PRs compare explicit base/head; manual and new branches run both', () => {
  assert.deepEqual(compareRange('pull_request', { pull_request: { base: { sha: 'base' }, head: { sha: 'head' } } }), { base: 'base', head: 'head' });
  assert.deepEqual(compareRange('push', { before: 'base', after: 'head' }), { base: 'base', head: 'head' });
  assert.equal(compareRange('push', { before: '0000', after: 'head' }), null);
  assert.equal(compareRange('workflow_dispatch', {}), null);
});
