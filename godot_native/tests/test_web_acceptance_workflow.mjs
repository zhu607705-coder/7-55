#!/usr/bin/env node
// Pure Node workflow/receipt contracts. This does not launch a browser or prove gameplay.
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { test } from 'node:test';

const workflow = readFileSync(new URL('../../.github/workflows/deploy-pages.yml', import.meta.url), 'utf8');
const build = workflow.split('  build:\n')[1].split('  browser_profiles:\n')[0];
const profilesJob = workflow.split('  browser_profiles:\n')[1].split('  deploy:\n')[0];
const deploy = workflow.split('  deploy:\n')[1];
const profiles = ['desktop-1280', 'touch-390', 'retina-touch-390'];
const sha = 'a'.repeat(40), fixtureHash = 'b'.repeat(64);
const dimensions = { 'desktop-1280': [1280, 720, false, 1], 'touch-390': [390, 844, true, 1], 'retina-touch-390': [390, 844, true, 3] };
function step(name) {
  const start = profilesJob.indexOf(`      - name: ${name}\n`);
  assert.ok(start >= 0, `Missing step ${name}`);
  const next = profilesJob.indexOf('\n      - name: ', start + 1);
  return profilesJob.slice(start, next < 0 ? undefined : next);
}
function receiptCode(name) {
  const match = step(name).match(/node --input-type=module <<'NODE'\n([\s\S]*?)\n          NODE/);
  assert.ok(match, `Missing inline receipt validator in ${name}`);
  return match[1].split('\n').map(line => line.replace(/^          /, '')).join('\n');
}
const worldCode = receiptCode('Accept actual world input for this profile');
const phoneCode = receiptCode('Accept actual early charging and two-stage Tiyi phone input');

await test('bounded three-profile isolation retains the original gates and deployment protection', () => {
  assert.match(build, /timeout-minutes: 25/);
  assert.match(build, /Accept actual Godot Web input[\s\S]*?timeout-minutes: 12/);
  assert.equal((build.match(/node godot_native\/tools\/build_web\.mjs/g) || []).length, 1);
  assert.equal((build.match(/node godot_native\/tools\/verify_web_export\.mjs/g) || []).length, 2);
  assert.match(build, /--scenarios streaming/);
  assert.doesNotMatch(build, /--only |--scenarios (?:mobile-world|phone-recovery)/);
  assert.match(profilesJob, /needs: build/);
  assert.match(profilesJob, /timeout-minutes: 12/);
  assert.match(profilesJob, /fail-fast: false/);
  const actualProfiles = profilesJob.match(/profile: \[([^\]]+)\]/)[1].split(',').map(v => v.trim());
  assert.deepEqual(actualProfiles, profiles);
  assert.equal((profilesJob.match(/node godot_native\/tools\/verify_web_export\.mjs/g) || []).length, 2);
  assert.match(profilesJob, /--scenarios mobile-world --only "\$ACCEPTANCE_PROFILE"/);
  assert.match(profilesJob, /--scenarios phone-recovery --only "\$ACCEPTANCE_PROFILE"/);
  assert.ok(profilesJob.indexOf('--scenarios mobile-world') < profilesJob.indexOf('--scenarios phone-recovery'));
  assert.match(step('Accept actual early charging and two-stage Tiyi phone input'), /if: \$\{\{ !cancelled\(\) && steps\.verify_inputs\.outcome == 'success' \}\}/);
  assert.match(step('Accept actual early charging and two-stage Tiyi phone input'), /timeout-minutes: 8/);
  assert.doesNotMatch(profilesJob, /npm ci|continue-on-error|build_web\.mjs/);
  assert.equal((profilesJob.match(/--boot-timeout 180000/g) || []).length, 2);
  assert.equal((profilesJob.match(/--chrome-arg --use-angle=swiftshader/g) || []).length, 2);
  assert.match(step("Preserve this profile's independent browser evidence"), /if: always\(\)/);
  assert.match(profilesJob, /name: godot-web-profile-\$\{\{ matrix.profile \}\}-\$\{\{ github.run_id \}\}-\$\{\{ github.run_attempt \}\}/);
  assert.match(deploy, /needs: \[build, browser_profiles\]/);
  assert.match(deploy, /needs\.build\.result == 'success' && needs\.browser_profiles\.result == 'success'/);
  assert.match(deploy, /github\.event_name == 'push' \|\| github\.event_name == 'workflow_dispatch'/);
  assert.match(deploy, /github\.ref == 'refs\/heads\/main' \|\| github\.ref == 'refs\/heads\/codex\/godot-complete-20261019'/);
  assert.match(deploy, /permissions:\n      pages: write\n      id-token: write/);
  assert.match(deploy, /environment:\n      name: github-pages/);
  assert.doesNotMatch(workflow, /continue-on-error|pull_request_target/);
});

await test('sealed inputs allow independent profile diagnostics after a baseline failure only', () => {
  assert.ok(build.indexOf('Seal exact-source browser acceptance inputs') < build.indexOf('Accept actual Godot Web input and persisted reload'));
  assert.ok(build.indexOf('Transfer immutable acceptance inputs to profile runners') < build.indexOf('Accept actual Godot Web input and persisted reload'));
  assert.match(build, /bundle_ready: \$\{\{ steps.transfer_inputs.outcome == 'success' \}\}/);
  assert.match(build, /Transfer immutable acceptance inputs to profile runners\n        id: transfer_inputs/);
  const expression = profilesJob.match(/^    if: \$\{\{ (.*?) \}\}$/m)?.[1];
  assert.equal(expression, "!cancelled() && needs.build.outputs.bundle_ready == 'true'");
  // Execute the actual workflow expression, not a separately maintained predicate.
  const allowed = new Function('cancelled', 'needs', `return (${expression});`);
  const evaluate = (result, ready, cancelled = false) => allowed(() => cancelled, { build: { result, outputs: { bundle_ready: ready } } });
  assert.equal(evaluate('success', 'true'), true);
  assert.equal(evaluate('failure', 'true'), true, 'baseline failure must retain independent diagnostics');
  assert.equal(evaluate('failure', 'false'), false, 'producer failure must not run consumers');
  assert.equal(evaluate('failure', undefined), false, 'missing bundle must not run consumers');
  assert.equal(evaluate('success', 'false'), false, 'an incomplete bundle must not run consumers');
  assert.equal(evaluate('cancelled', 'true', true), false, 'cancellation must stop diagnostics');
});

await test('producer artifact and consumer checkout bind one run and explicit producer attempt', () => {
  assert.match(build, /bundle_name: \$\{\{ steps.acceptance_bundle.outputs.bundle_name \}\}/);
  assert.match(build, /receipt_sha: \$\{\{ steps.acceptance_bundle.outputs.receipt_sha \}\}/);
  assert.match(build, /producer_attempt: \$\{\{ steps.acceptance_bundle.outputs.producer_attempt \}\}/);
  assert.match(build, /include-hidden-files: true\n          retention-days: 1/);
  assert.match(build, /compression-level: 0/);
  assert.match(profilesJob, /name: \$\{\{ needs.build.outputs.bundle_name \}\}/);
  assert.match(profilesJob, /ref: \$\{\{ github.sha \}\}/);
  assert.match(profilesJob, /EXPECTED_RECEIPT_SHA: \$\{\{ needs.build.outputs.receipt_sha \}\}/);
  assert.match(profilesJob, /EXPECTED_PRODUCER_ATTEMPT: \$\{\{ needs.build.outputs.producer_attempt \}\}/);
  assert.match(step('Verify exact source and every input byte'), /--receipt-sha "\$EXPECTED_RECEIPT_SHA"/);
  assert.match(step('Verify exact source and every input byte'), /--producer-attempt "\$EXPECTED_PRODUCER_ATTEMPT"/);
  assert.match(worldCode, /inputBundle: JSON.parse/);
  assert.match(phoneCode, /inputBundle: JSON.parse/);
});

function sample(profile, scenario) {
  const [width, height, touch, dpr] = dimensions[profile];
  const fixture = { fixture: 'before_c2_dorm_exit.json', sha256: fixtureHash };
  const inputs = ['low0', 'low1', 'first', 'second'].map(filename => ({ filename, sha256: fixtureHash }));
  const fixtures = { variants: inputs.slice(0, 2), earned: { firstTiyi: inputs[2], secondTiyi: inputs[3] } };
  const coverage = touch ? ['bottom plaque', ...(profile === 'touch-390' ? ['landscape resize'] : [])] : ['PC direction + Space'];
  const item = { id: profile, width, height, touch, dpr, passed: true, screenshots: ['actual.png'],
    imports: [{ filename: fixture.fixture, sha256: fixtureHash }, ...structuredClone(inputs)],
    mobileWorld: { completed: true, fixtureConstructionIsNotTouchEvidence: true, samples: [{}], coverage, inputs: [{ method: 'Input.dispatchTouchEvent' }] },
    phoneRecovery: { completed: true, coverage: Array.from({ length: 9 }, (_, i) => `coverage-${i}`), inputs: [{}] } };
  return { report: { passed: true, scenarios: scenario, exportManifest: { sourceCommit: sha, engine: '4.7.1.stable.official' }, cases: [item] }, fixture, fixtures };
}
function runReceipt(profile, scenario, mutate = () => {}) {
  const root = mkdtempSync(path.join(tmpdir(), '755-profile-receipt-'));
  try {
    const input = sample(profile, scenario); mutate(input);
    const verification = path.join(root, 'godot_native/exports/verification');
    const directory = path.join(verification, scenario === 'mobile-world' ? 'web_mobile_world' : 'web_phone_recovery');
    const earned = path.join(root, 'inputs/godot-web-inputs/controller-earned');
    mkdirSync(directory, { recursive: true }); mkdirSync(earned, { recursive: true });
    writeFileSync(path.join(directory, 'web-acceptance.json'), JSON.stringify(input.report));
    writeFileSync(path.join(verification, 'verified-inputs.json'), JSON.stringify({ sourceCommit: sha, totalBytes: 12345, producerAttempt: '1' }));
    writeFileSync(path.join(earned, 'fixture-provenance.json'), JSON.stringify(input.fixture));
    writeFileSync(path.join(earned, 'phone-recovery-inputs.json'), JSON.stringify(input.fixtures));
    const result = spawnSync(process.execPath, ['--input-type=module'], { input: scenario === 'mobile-world' ? worldCode : phoneCode, cwd: root,
      env: { ...process.env, GITHUB_SHA: sha, ACCEPTANCE_PROFILE: profile, RUNNER_TEMP: path.join(root, 'inputs') }, encoding: 'utf8' });
    return { ...result, receipt: result.status === 0 ? JSON.parse(readFileSync(path.join(directory, `ci-${scenario}-receipt.json`), 'utf8')) : null };
  } finally { rmSync(root, { recursive: true, force: true }); }
}
for (const profile of profiles) for (const scenario of ['mobile-world', 'phone-recovery']) {
  await test(`${scenario} exact ${profile} receipt accepts only that actual profile`, () => {
    const ok = runReceipt(profile, scenario);
    assert.equal(ok.status, 0, ok.stderr);
    assert.equal(ok.receipt.cases.length, 1);
    assert.equal(ok.receipt.cases[0].id, profile);
    assert.equal(ok.receipt.inputBundle.totalBytes, 12345);
    for (const mutate of [
      x => { x.report.exportManifest.sourceCommit = 'c'.repeat(40); },
      x => { x.report.exportManifest.engine = '4.6.3.stable.official'; },
      x => { x.report.scenarios = 'all'; },
      x => { x.report.passed = false; },
      x => { x.report.cases[0].passed = false; },
      x => { x.report.cases.push(structuredClone(x.report.cases[0])); },
      x => { x.report.cases[0].id = 'unknown'; },
      x => { x.report.cases[0].dpr += 1; },
      x => { x.report.cases[0].imports = []; }
    ]) assert.notEqual(runReceipt(profile, scenario, mutate).status, 0, 'invalid source/profile/import unexpectedly accepted');
  });
}
await test('all original mobile receipt requirements still reject missing evidence', () => {
  for (const [profile, mutate] of [
    ['desktop-1280', x => { x.report.cases[0].mobileWorld.completed = false; }],
    ['desktop-1280', x => { x.report.cases[0].mobileWorld.fixtureConstructionIsNotTouchEvidence = false; }],
    ['desktop-1280', x => { x.report.cases[0].mobileWorld.samples = []; }],
    ['desktop-1280', x => { x.report.cases[0].mobileWorld.coverage = ['wrong']; }],
    ['touch-390', x => { x.report.cases[0].mobileWorld.coverage = ['bottom plaque']; }],
    ['retina-touch-390', x => { x.report.cases[0].mobileWorld.coverage = ['wrong']; }],
    ['touch-390', x => { x.report.cases[0].mobileWorld.inputs = []; }]
  ]) assert.notEqual(runReceipt(profile, 'mobile-world', mutate).status, 0);
});
await test('all original phone receipt requirements still reject missing evidence', () => {
  for (const mutate of [
    x => { x.report.cases[0].phoneRecovery.completed = false; },
    x => { x.report.cases[0].phoneRecovery.coverage.pop(); },
    x => { x.report.cases[0].phoneRecovery.inputs = []; },
    x => { x.report.cases[0].screenshots = []; },
    x => { x.report.cases[0].imports.pop(); },
    x => { x.report.cases[0].imports.at(-1).sha256 = 'd'.repeat(64); }
  ]) assert.notEqual(runReceipt('touch-390', 'phone-recovery', mutate).status, 0);
});
