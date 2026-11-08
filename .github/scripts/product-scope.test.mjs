import test from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { changedProducts, changedScopes, compareRange } from './product-scope.mjs';

test('platform-only paths do not schedule game builds or deployments', () => {
  assert.deepEqual(changedProducts(['platform/apps/web/src/app/App.tsx', 'platform/package-lock.json', '.github/workflows/platform-ci.yml']), { game: false, platform: true });
});
test('game, mixed, shared, renamed and deleted paths are conservative', () => {
  assert.deepEqual(changedProducts(['godot_native/scripts/main.gd']), { game: true, platform: false });
  assert.deepEqual(changedProducts(['src/App.tsx', 'platform/apps/web/src/main.tsx']), { game: true, platform: true });
  assert.deepEqual(changedProducts(['.github/scripts/product-scope.mjs']), { game: true, platform: true });
  assert.deepEqual(changedProducts(['README.md']), { game: true, platform: true });
  assert.deepEqual(changedProducts(['godot_native/web/player-account.js']), { game: true, platform: true });
  assert.deepEqual(changedProducts(['godot_native/web/cloud-saves.js']), { game: true, platform: true });
  assert.deepEqual(changedProducts(['platform/deleted-file.ts']), { game: false, platform: true });
});
const baseSha = 'a'.repeat(40);
const headSha = 'b'.repeat(40);
const mergeSha = 'c'.repeat(40);

test('PRs compare base to tested merge; pushes retain before/after', () => {
  const event = { pull_request: { base: { sha: baseSha }, head: { sha: headSha } } };
  assert.deepEqual(compareRange('pull_request', event, mergeSha), { base: baseSha, head: mergeSha });
  assert.deepEqual(compareRange('push', { before: baseSha, after: headSha }, mergeSha), { base: baseSha, head: headSha });
  assert.equal(compareRange('push', { before: '0000', after: headSha }), null);
  assert.equal(compareRange('workflow_dispatch', {}, mergeSha), null);
  for (const trigger of [undefined, '', 'invalid']) assert.equal(compareRange('pull_request', event, trigger), null);
  assert.equal(compareRange('pull_request', {}, mergeSha), null);
});

test('native-only edits and progress notes do not schedule retained release', () => {
  for (const file of [
    'godot_native/scripts/main.gd', 'godot_native/assets/player.png',
    'godot_native/web/player-account.js', 'godot_native/web/cloud-saves.js',
    '.github/workflows/godot-native-ci.yml', '.github/workflows/deploy-pages.yml',
    '.github/workflows/native-pr-integration.yml', '.github/workflows/native-source-ab.yml',
    '.github/workflows/native-source-measure.yml',
  ]) {
    const scope = changedScopes([file, 'docs/progress.md', 'progress.md']);
    assert.equal(scope.game, true, file);
    assert.equal(scope.retained_web, false, file);
  }
  assert.deepEqual(changedScopes([]), { game: false, platform: false, retained_web: false });
  assert.deepEqual(changedScopes(['platform/package.json']), { game: false, platform: true, retained_web: false });
});

test('shared sources, build inputs, policies and unknown game paths keep retained release', () => {
  for (const file of [
    'src/assets/player.png', 'src/data/items.config.json', 'src/core/GameState.ts',
    'src/App.tsx', 'package.json', 'package-lock.json', 'vite.config.ts',
    'scripts/run-validation-suite.mjs', 'scripts/build-singlefile.mjs', 'public/icon.png',
    '.github/scripts/product-scope.mjs', '.github/scripts/product-scope.test.mjs',
    '.github/workflows/product-scope.yml', '.github/workflows/web-ci.yml',
    '.github/workflows/unknown.yml', 'future-game/unknown.bin',
    'AGENTS.md', 'README.md', 'CONTRIBUTING.md', '.gitignore',
  ]) {
    assert.equal(changedScopes(['godot_native/scripts/main.gd', file]).retained_web, true, file);
  }
});

// Exercise the production entry point, its Git fetch/diff behavior and GITHUB_OUTPUT.
// The local origin deliberately advances its base after the feature branch forks.
function gitFixture(t, { basePath = 'platform/base-only.ts', headPath = 'godot_native/scripts/feature.gd' } = {}) {
  const root = mkdtempSync(join(tmpdir(), 'product-scope-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const origin = join(root, 'origin');
  const checkout = join(root, 'checkout');
  mkdirSync(origin);
  const git = (...args) => execFileSync('git', args, { cwd: origin, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim();
  git('init', '-b', 'main');
  git('config', 'user.email', 'scope-test@example.invalid');
  git('config', 'user.name', 'Scope test');
  const commit = (file, text) => {
    mkdirSync(dirname(join(origin, file)), { recursive: true });
    writeFileSync(join(origin, file), text);
    git('add', '--all');
    git('commit', '-m', file);
    return git('rev-parse', 'HEAD');
  };
  commit('src/existing.ts', 'shared baseline');
  git('branch', 'feature');
  const base = commit(basePath, 'newer base-only change');
  git('checkout', 'feature');
  const head = commit(headPath, 'PR change');
  git('checkout', 'main');
  git('merge', '--no-ff', 'feature', '-m', 'synthetic PR merge');
  const merge = git('rev-parse', 'HEAD');
  git('clone', '--no-local', origin, checkout);
  const run = (eventName, event, trigger = '') => {
    const eventPath = join(root, 'event.json');
    const outputPath = join(root, 'output');
    writeFileSync(eventPath, JSON.stringify(event));
    writeFileSync(outputPath, '');
    execFileSync(process.execPath, [fileURLToPath(new URL('./product-scope.mjs', import.meta.url))], {
      cwd: checkout,
      env: { ...process.env, GITHUB_EVENT_NAME: eventName, GITHUB_EVENT_PATH: eventPath, GITHUB_OUTPUT: outputPath, GITHUB_SHA: trigger },
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    return Object.fromEntries(readFileSync(outputPath, 'utf8').trim().split('\n').map(line => {
      const [key, value] = line.split('=');
      assert.ok(['true', 'false'].includes(value));
      return [key, value === 'true'];
    }));
  };
  return { git, commit, base, head, merge, run };
}

test('CLI diverged PR ignores newer base-only product and compares tested merge', t => {
  const { git, base, head, merge, run } = gitFixture(t);
  const oldPaths = git('diff', '--name-only', base, head).split('\n');
  assert.equal(changedProducts(oldPaths).platform, true, 'fixture must expose the former two-tip bug');
  const event = { pull_request: { base: { sha: base }, head: { sha: head } } };
  assert.deepEqual(run('pull_request', event, merge), { game: true, platform: false, retained_web: false });
  assert.deepEqual(run('pull_request', event), { game: true, platform: true, retained_web: true });
  assert.deepEqual(run('pull_request', event, 'invalid'), { game: true, platform: true, retained_web: true });
  assert.deepEqual(run('workflow_dispatch', {}, merge), { game: true, platform: true, retained_web: true });
  assert.deepEqual(run('push', { before: '0'.repeat(40), after: merge }, merge), { game: true, platform: true, retained_web: true });
  assert.deepEqual(run('push', { before: base, after: merge }, head), { game: true, platform: false, retained_web: false });
});

test('CLI renames across runtime boundaries retain deleted source-side validation', t => {
  const { git, commit, merge, run } = gitFixture(t);
  git('mv', 'src/existing.ts', 'godot_native/existing.ts');
  const after = commit('godot_native/scripts/feature.gd', 'updated native change');
  assert.deepEqual(run('push', { before: merge, after }), { game: true, platform: false, retained_web: true });
});

test('CLI platform-only PR ignores retained-Web changes made only on newer base', t => {
  const { base, head, merge, run } = gitFixture(t, {
    basePath: 'src/base-only.ts', headPath: 'platform/feature.ts',
  });
  assert.deepEqual(run('pull_request', { pull_request: { base: { sha: base }, head: { sha: head } } }, merge),
    { game: false, platform: true, retained_web: false });
});

test('audited native-owned retained dependencies still schedule release validation', () => {
  for (const file of ['godot_native/web/button.css', 'godot_native/tools/theater-review-route.mjs']) {
    assert.deepEqual(changedScopes([file]), { game: true, platform: false, retained_web: true });
    assert.equal(changedScopes(['godot_native/scripts/main.gd', 'docs/progress.md', file]).retained_web, true);
  }
});

test('CLI shared native-owned CSS change schedules retained release', t => {
  const { base, head, merge, run } = gitFixture(t, { headPath: 'godot_native/web/button.css' });
  assert.deepEqual(run('pull_request', { pull_request: { base: { sha: base }, head: { sha: head } } }, merge),
    { game: true, platform: false, retained_web: true });
});
