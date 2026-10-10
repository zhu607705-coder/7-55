import assert from 'node:assert/strict';
import { copyFileSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const here = dirname(fileURLToPath(import.meta.url));
const sourceRoot = resolve(process.env.SOURCE_REPO_ROOT || resolve(here, '../..'));
const original = readFileSync(join(here, 'tiyi_audit_oracle.json'));

// Every child gets its own exporter/fixture and working directory. Never edit
// the checked-in fixture or rely on the caller's cwd for --check resolution.
function sandbox(body, withFixture = true) {
  const directory = mkdtempSync(join(tmpdir(), '755-tiyi-oracle-cli-'));
  const exporter = join(directory, 'export_tiyi_presence_source.mjs');
  const fixture = join(directory, 'tiyi_audit_oracle.json');
  const cwd = join(directory, 'working');
  copyFileSync(join(here, 'export_tiyi_presence_source.mjs'), exporter);
  if (withFixture) writeFileSync(fixture, original);
  mkdirSync(cwd);
  const run = (args, extraEnv = {}) => {
    const result = spawnSync(process.execPath, [exporter, ...args], {
      cwd,
      env: { ...process.env, SOURCE_REPO_ROOT: sourceRoot, ...extraEnv },
      encoding: 'utf8',
      timeout: 30000,
      maxBuffer: 1024 * 1024,
    });
    assert.equal(result.error, undefined, result.error?.message);
    return result;
  };
  try { body({ directory, fixture, cwd, run }); }
  finally { rmSync(directory, { recursive: true, force: true }); }
}

test('--check executes source, resolves its adjacent fixture, and writes nothing', () => sandbox(({ directory, fixture, cwd, run }) => {
  const modified = statSync(fixture, { bigint: true }).mtimeNs;
  const result = run(['--check']);
  assert.equal(result.status, 0, result.stderr);
  const output = JSON.parse(result.stdout);
  assert.equal(output.mode, 'check');
  assert.equal(output.output, fixture);
  assert.equal(output.drafts, 468);
  assert.equal(output.submissions, 36);
  assert.deepEqual(readFileSync(fixture), original);
  assert.equal(statSync(fixture, { bigint: true }).mtimeNs, modified);
  assert.equal(existsSync(join(cwd, '--check')), false);
  assert.equal(existsSync(join(directory, '--check')), false);
}));

test('--check rejects a changed oracle without overwriting it', () => sandbox(({ fixture, cwd, run }) => {
  const stale = JSON.parse(original);
  stale.drafts[0].accepted = !stale.drafts[0].accepted;
  const bytes = JSON.stringify(stale, null, 2) + '\n';
  writeFileSync(fixture, bytes);
  const modified = statSync(fixture, { bigint: true }).mtimeNs;
  const result = run(['--check']);
  assert.equal(result.status, 1, result.stderr);
  assert.match(result.stderr, /source oracle is stale/);
  assert.equal(readFileSync(fixture, 'utf8'), bytes);
  assert.equal(statSync(fixture, { bigint: true }).mtimeNs, modified);
  assert.equal(existsSync(join(cwd, '--check')), false);
}));

test('--check rejects a missing fixture without generating one', () => sandbox(({ fixture, run }) => {
  const result = run(['--check']);
  assert.equal(result.status, 1, result.stderr);
  assert.match(result.stderr, /Cannot read Tiyi presence source oracle/);
  assert.equal(existsSync(fixture), false);
}, false));

test('an explicit output path generates the executed source oracle', () => sandbox(({ fixture, cwd, run }) => {
  const modified = statSync(fixture, { bigint: true }).mtimeNs;
  const result = run(['generated oracle.json']);
  assert.equal(result.status, 0, result.stderr);
  assert.equal(JSON.parse(result.stdout).mode, 'generate');
  assert.deepEqual(readFileSync(join(cwd, 'generated oracle.json')), original);
  assert.deepEqual(readFileSync(fixture), original);
  assert.equal(statSync(fixture, { bigint: true }).mtimeNs, modified);
}));

test('no arguments preserves generation to the adjacent default fixture', () => sandbox(({ fixture, run }) => {
  const result = run([]);
  assert.equal(result.status, 0, result.stderr);
  assert.equal(JSON.parse(result.stdout).mode, 'generate');
  assert.deepEqual(readFileSync(fixture), original);
}, false));

for (const args of [['--unknown'], ['first.json', 'second.json'], ['--check', 'output.json'], ['']]) {
  test(`unsupported arguments fail before source reads or writes: ${JSON.stringify(args)}`, () => sandbox(({ fixture, cwd, run }) => {
    const result = run(args, { SOURCE_REPO_ROOT: join(cwd, 'nonexistent-source') });
    assert.equal(result.status, 2, result.stderr);
    assert.match(result.stderr, /^Usage:/);
    assert.deepEqual(readFileSync(fixture), original);
    for (const filename of ['--unknown', '--check', 'first.json', 'second.json', 'output.json']) {
      assert.equal(existsSync(join(cwd, filename)), false);
    }
  }));
}
