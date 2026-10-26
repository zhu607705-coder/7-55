#!/usr/bin/env node
// Pure Node workflow/receipt contracts. This does not launch a browser or prove gameplay.
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { test } from 'node:test';

const workflow = readFileSync(new URL('../../.github/workflows/deploy-pages.yml', import.meta.url), 'utf8');
// Only split at job-level YAML keys, never let a newly inserted job become part
// of its predecessor and accidentally satisfy that predecessor's assertions.
const jobsSource = workflow.split('\njobs:\n')[1];
const headings = [...jobsSource.matchAll(/^  ([a-z][a-z0-9_]*):\n/gm)];
const jobs = Object.fromEntries(headings.map((match, index) => [match[1], jobsSource.slice(match.index + match[0].length, headings[index + 1]?.index)]));
const { build, browser_baseline: baselineJob, browser_profiles: profilesJob, library_profiles: libraryJob, deploy } = jobs;
const profiles = ['desktop-1280', 'touch-390', 'retina-touch-390'];
const sha = 'a'.repeat(40), fixtureHash = 'b'.repeat(64);
const dimensions = { 'desktop-1280': [1280, 720, false, 1], 'touch-390': [390, 844, true, 1], 'retina-touch-390': [390, 844, true, 3] };
function step(name, job = profilesJob) {
  const start = job.indexOf(`      - name: ${name}\n`);
  assert.ok(start >= 0, `Missing step ${name}`);
  const next = job.indexOf('\n      - name: ', start + 1);
  return job.slice(start, next < 0 ? undefined : next);
}
function receiptCode(name, job = profilesJob) {
  const match = step(name, job).match(/node --input-type=module <<'NODE'\n([\s\S]*?)\n          NODE/);
  assert.ok(match, `Missing inline receipt validator in ${name}`);
  return match[1].split('\n').map(line => line.replace(/^          /, '')).join('\n');
}
const worldCode = receiptCode('Accept actual world input for this profile');
const phoneCode = receiptCode('Accept actual early charging and two-stage Tiyi phone input');

await test('one producer fans out to all acceptance jobs; publishing waits for every branch', () => {
  assert.deepEqual(Object.keys(jobs), ['build', 'browser_baseline', 'browser_profiles', 'library_profiles', 'deploy']);
  assert.doesNotMatch(build, /^    needs:/m);
  for (const name of ['browser_baseline', 'browser_profiles', 'library_profiles']) {
    assert.equal(jobs[name].match(/^    needs: (.+)$/m)?.[1], 'build', `${name} must not wait for another acceptance job`);
    assert.equal(jobs[name].match(/^    if: \$\{\{ (.*?) \}\}$/m)?.[1], "!cancelled() && needs.build.outputs.bundle_ready == 'true'");
  }
  assert.deepEqual(deploy.match(/^    needs: \[([^\]]+)\]$/m)?.[1].split(',').map(name => name.trim()),
    ['build', 'browser_baseline', 'browser_profiles', 'library_profiles']);
  assert.equal((workflow.match(/node godot_native\/tools\/build_web\.mjs/g) || []).length, 1, 'only one heavy export across all jobs');
});

await test('baseline consumes verified producer bytes without skipping either original browser invocation', () => {
  assert.match(baselineJob, /runs-on: ubuntu-latest/);
  assert.match(baselineJob, /^    timeout-minutes: 15$/m);
  assert.match(baselineJob, /permissions:\n      contents: read/);
  assert.match(baselineJob, /ref: \$\{\{ github.sha \}\}/);
  assert.match(baselineJob, /node-version: 22\.23\.3/);
  assert.match(baselineJob, /ACCEPTANCE_HEAD_SHA: \$\{\{ github.event.pull_request.head.sha \|\| github.sha \}\}/);
  assert.match(baselineJob, /ACCEPTANCE_BASE_SHA: \$\{\{ github.event.pull_request.base.sha \|\| '' \}\}/);
  assert.match(baselineJob, /EXPECTED_RECEIPT_SHA: \$\{\{ needs.build.outputs.receipt_sha \}\}/);
  assert.match(baselineJob, /EXPECTED_PRODUCER_ATTEMPT: \$\{\{ needs.build.outputs.producer_attempt \}\}/);
  assert.doesNotMatch(baselineJob, /npm ci|build_web\.mjs|sync_source\.mjs|convert_media|continue-on-error|pages: write|id-token: write|deploy-pages@|upload-pages-artifact@/);
  const names = [...baselineJob.matchAll(/^      - name: (.+)$/gm)].map(match => match[1]);
  assert.deepEqual(names, ['Check out exact producer source', 'Set up Node.js 22', "Download this run's sealed producer inputs",
    'Verify exact source and every input byte', 'Accept actual Godot Web input and persisted reload at Pages subpath',
    'Preserve baseline and streaming evidence']);
  for (const name of names.slice(0, -1)) assert.doesNotMatch(step(name, baselineJob), /^        if:/m, `${name} must require prior success and cannot skip itself`);
  const download = step("Download this run's sealed producer inputs", baselineJob);
  assert.match(download, /uses: actions\/download-artifact@v4/);
  assert.match(download, /name: \$\{\{ needs.build.outputs.bundle_name \}\}/);
  assert.match(download, /path: \$\{\{ runner.temp \}\}\/godot-web-inputs/);
  assert.doesNotMatch(download, /run-id:|repository:|github-token:/, 'only this workflow run may supply the artifact');
  const verify = step('Verify exact source and every input byte', baselineJob);
  assert.match(verify, /node godot_native\/tools\/web_acceptance_bundle.mjs verify/);
  for (const option of ['--bundle-dir "$RUNNER_TEMP/godot-web-inputs"', '--receipt-sha "$EXPECTED_RECEIPT_SHA"',
    '--producer-attempt "$EXPECTED_PRODUCER_ATTEMPT"', '--output-receipt godot_native/exports/verification/verified-baseline-inputs.json']) assert.ok(verify.includes(option));
  const acceptance = step('Accept actual Godot Web input and persisted reload at Pages subpath', baselineJob);
  assert.match(acceptance, /timeout-minutes: 12/);
  assert.match(acceptance, /shell: bash\n        run: \|\n          set -euo pipefail/);
  assert.match(acceptance, /ln -s "\$RUNNER_TEMP\/godot-web-inputs\/web-release" "\$RUNNER_TEMP\/godot-qa-site\/7-55"/);
  const invocations = [...acceptance.matchAll(/          node godot_native\/tools\/verify_web_export\.mjs \\\n(?:            .*\n)+/g)]
    .map(match => match[0].replace(/[ \t]*\\\n\s*/g, ' ').trim());
  const command = 'node godot_native/tools/verify_web_export.mjs --url http://127.0.0.1:5207/7-55/ --export-dir "$RUNNER_TEMP/godot-web-inputs/web-release"';
  const browser = '--chrome "$godot_web_chrome" --chrome-arg --use-angle=swiftshader --chrome-arg --enable-unsafe-swiftshader --boot-timeout 180000';
  assert.deepEqual(invocations, [
    `${command} --output godot_native/exports/verification/web_ci ${browser} 2>&1 | tee godot_native/exports/verification/web_ci/acceptance.log`,
    `${command} --output godot_native/exports/verification/web_streaming --scenarios streaming --fixtures "$RUNNER_TEMP/godot-web-inputs/controller-earned" ${browser} 2>&1 | tee godot_native/exports/verification/web_streaming/acceptance.log`
  ]);
  assert.match(acceptance, /inputBundle: JSON.parse\(fs.readFileSync\('godot_native\/exports\/verification\/verified-baseline-inputs.json'/);
  const evidence = step('Preserve baseline and streaming evidence', baselineJob);
  assert.match(evidence, /if: always\(\)/);
  assert.match(evidence, /uses: actions\/upload-artifact@v4/);
  assert.match(evidence, /name: godot-web-baseline-\$\{\{ github.run_id \}\}-\$\{\{ github.run_attempt \}\}/);
  for (const file of ['verified-baseline-inputs.json', 'web_ci/', 'web_streaming/']) assert.ok(evidence.includes(`godot_native/exports/verification/${file}`));
});

await test('moved streaming validator still rejects every missing original fault/retry/reload requirement', () => {
  // Synthetic contract receipts execute the actual inline validator. They do
  // not replace running the real browser or prove the controlled network fault.
  const code = receiptCode('Accept actual Godot Web input and persisted reload at Pages subpath', baselineJob);
  const root = mkdtempSync(path.join(tmpdir(), '755-streaming-workflow-receipt-'));
  try {
    const verification = path.join(root, 'godot_native/exports/verification');
    const directory = path.join(verification, 'web_streaming');
    const earned = path.join(root, 'inputs/godot-web-inputs/controller-earned');
    for (const folder of [directory, earned]) mkdirSync(folder, { recursive: true });
    const fixture = { fixture: 'after_c2_dorm_exit.json', sha256: fixtureHash };
    const bundle = { verified: true, source: { checkedOutCommit: sha }, receiptSha: 'e'.repeat(64), producerAttempt: '1' };
    writeFileSync(path.join(earned, 'fixture-provenance.json'), JSON.stringify({ streamingFixture: fixture }));
    writeFileSync(path.join(verification, 'verified-baseline-inputs.json'), JSON.stringify(bundle));
    const run = (mutate = () => {}) => {
      const report = { passed: true, exportManifest: { sourceCommit: sha, engine: '4.7.1.stable.official' },
        cases: [{ id: 'desktop-1280', passed: true, imports: [{ filename: fixture.fixture, sha256: fixture.sha256 }],
          streaming: { controlledFailures: [{ url: 'synthetic.pck' }],
            freshWithBlockedBackground: { evidence: { chapter: 1 }, content: { blocking: false } },
            requiredFailure: { content: { blocking: true, retryVisible: true } },
            recovery: { realKeyboardMovement: true, content: { blocking: false } },
            reload: { oldDocumentTimeOrigin: 1, newDocumentTimeOrigin: 2, afterEvidence: { chapter: 2 }, chapter2HttpRequests: [], cache: { keys: ['synthetic'] } } } }] };
      mutate(report);
      writeFileSync(path.join(directory, 'web-acceptance.json'), JSON.stringify(report));
      return spawnSync(process.execPath, ['--input-type=module'], { input: code, cwd: root,
        env: { ...process.env, GITHUB_SHA: sha, RUNNER_TEMP: path.join(root, 'inputs') }, encoding: 'utf8' });
    };
    const valid = run();
    assert.equal(valid.status, 0, valid.stderr);
    const receipt = JSON.parse(readFileSync(path.join(directory, 'ci-streaming-receipt.json'), 'utf8'));
    assert.deepEqual(receipt.inputBundle, bundle);
    assert.equal(receipt.verified.length, 4);
    for (const [label, mutate] of [
      ['failed report', r => { r.passed = false; }],
      ['wrong source', r => { r.exportManifest.sourceCommit = 'c'.repeat(40); }],
      ['wrong engine', r => { r.exportManifest.engine = '4.6.3.stable.official'; }],
      ['missing case', r => { r.cases = []; }],
      ['extra case', r => { r.cases.push(structuredClone(r.cases[0])); }],
      ['wrong case', r => { r.cases[0].id = 'touch-390'; }],
      ['failed case', r => { r.cases[0].passed = false; }],
      ['missing import', r => { r.cases[0].imports = []; }],
      ['wrong fixture hash', r => { r.cases[0].imports[0].sha256 = 'c'.repeat(64); }],
      ['missing controlled failure', r => { r.cases[0].streaming.controlledFailures = []; }],
      ['wrong fresh chapter', r => { r.cases[0].streaming.freshWithBlockedBackground.evidence.chapter = 2; }],
      ['background blocks C1', r => { r.cases[0].streaming.freshWithBlockedBackground.content.blocking = true; }],
      ['required fault not blocking', r => { r.cases[0].streaming.requiredFailure.content.blocking = false; }],
      ['missing retry', r => { r.cases[0].streaming.requiredFailure.content.retryVisible = false; }],
      ['missing real keyboard', r => { r.cases[0].streaming.recovery.realKeyboardMovement = false; }],
      ['recovery still blocking', r => { r.cases[0].streaming.recovery.content.blocking = true; }],
      ['missing reload', r => { delete r.cases[0].streaming.reload; }],
      ['same document', r => { r.cases[0].streaming.reload.newDocumentTimeOrigin = 1; }],
      ['wrong reloaded chapter', r => { r.cases[0].streaming.reload.afterEvidence.chapter = 1; }],
      ['missing reload network record', r => { delete r.cases[0].streaming.reload.chapter2HttpRequests; }],
      ['network instead of cache', r => { r.cases[0].streaming.reload.chapter2HttpRequests.push({}); }],
      ['missing cache keys', r => { r.cases[0].streaming.reload.cache.keys = []; }]
    ]) assert.notEqual(run(mutate).status, 0, `${label} must not pass the moved validator`);
  } finally { rmSync(root, { recursive: true, force: true }); }
});

await test('PRs never upload deployable Pages assets, and neither upload nor publication ignores failed gates', () => {
  const expression = step('Upload Pages artifact', build).match(/^        if: \$\{\{ (.*?) \}\}$/m)?.[1];
  assert.ok(expression);
  const upload = new Function('success', 'github', `return (${expression});`);
  const publishExpression = deploy.match(/^    if: \$\{\{ (.*?) \}\}$/m)?.[1];
  const publish = new Function('needs', 'github', `return (${publishExpression});`);
  const names = ['build', 'browser_baseline', 'browser_profiles', 'library_profiles'];
  const results = ['success', 'failure', 'cancelled', 'skipped'];
  for (const event_name of ['pull_request', 'push', 'workflow_dispatch']) {
    for (const ref of ['refs/heads/main', 'refs/heads/codex/godot-complete-20261019', 'refs/heads/unapproved']) {
      const github = { event_name, ref };
      const authorized = event_name !== 'pull_request' && ref !== 'refs/heads/unapproved';
      for (const succeeded of [true, false]) assert.equal(upload(() => succeeded, github), authorized && succeeded);
      for (const a of results) for (const b of results) for (const c of results) for (const d of results) {
        const values = [a, b, c, d];
        const needs = Object.fromEntries(names.map((name, index) => [name, { result: values[index] }]));
        assert.equal(publish(needs, github), authorized && values.every(result => result === 'success'), `${event_name}/${ref}/${values.join(',')}`);
      }
    }
  }
});

await test('bounded three-profile isolation retains the original gates and deployment protection', () => {
  assert.match(build, /timeout-minutes: 25/);
  assert.match(baselineJob, /Accept actual Godot Web input[\s\S]*?timeout-minutes: 12/);
  assert.equal((build.match(/node godot_native\/tools\/build_web\.mjs/g) || []).length, 1);
  assert.doesNotMatch(build, /verify_web_export\.mjs/);
  assert.equal((baselineJob.match(/node godot_native\/tools\/verify_web_export\.mjs/g) || []).length, 2);
  assert.match(baselineJob, /--scenarios streaming/);
  assert.doesNotMatch(baselineJob, /--only |--scenarios (?:mobile-world|phone-recovery)/);
  assert.match(profilesJob, /needs: build/);
  assert.match(profilesJob, /timeout-minutes: 18/);
  assert.match(profilesJob, /fail-fast: false/);
  const actualProfiles = profilesJob.match(/profile: \[([^\]]+)\]/)[1].split(',').map(v => v.trim());
  assert.deepEqual(actualProfiles, profiles);
  assert.equal((profilesJob.match(/node godot_native\/tools\/verify_web_export\.mjs/g) || []).length, 2);
  assert.match(profilesJob, /--scenarios mobile-world --only "\$ACCEPTANCE_PROFILE"/);
  assert.match(profilesJob, /--scenarios phone-recovery --only "\$ACCEPTANCE_PROFILE"/);
  assert.ok(profilesJob.indexOf('--scenarios mobile-world') < profilesJob.indexOf('--scenarios phone-recovery'));
  assert.match(step('Accept actual early charging and two-stage Tiyi phone input'), /if: \$\{\{ !cancelled\(\) && steps\.verify_inputs\.outcome == 'success' \}\}/);
  assert.match(step('Accept actual early charging and two-stage Tiyi phone input'), /timeout-minutes: 12/);
  assert.doesNotMatch(profilesJob, /npm ci|continue-on-error|build_web\.mjs/);
  assert.equal((profilesJob.match(/--boot-timeout 180000/g) || []).length, 2);
  assert.equal((profilesJob.match(/--chrome-arg --use-angle=swiftshader/g) || []).length, 2);
  assert.match(step("Preserve this profile's independent browser evidence"), /if: always\(\)/);
  assert.match(profilesJob, /name: godot-web-profile-\$\{\{ matrix.profile \}\}-\$\{\{ github.run_id \}\}-\$\{\{ github.run_attempt \}\}/);
  assert.match(deploy, /needs: \[build, browser_baseline, browser_profiles, library_profiles\]/);
  assert.match(deploy, /needs\.build\.result == 'success' && needs\.browser_baseline\.result == 'success' && needs\.browser_profiles\.result == 'success'/);
  assert.match(deploy, /&& needs\.library_profiles\.result == 'success'/);
  assert.match(deploy, /github\.event_name == 'push' \|\| github\.event_name == 'workflow_dispatch'/);
  assert.match(deploy, /github\.ref == 'refs\/heads\/main' \|\| github\.ref == 'refs\/heads\/codex\/godot-complete-20261019'/);
  assert.match(deploy, /permissions:\n      pages: write\n      id-token: write/);
  assert.match(deploy, /environment:\n      name: github-pages/);
  assert.doesNotMatch(workflow, /continue-on-error|pull_request_target/);
});

await test('sealed inputs allow independent profile diagnostics after producer post-transfer failure only', () => {
  assert.ok(build.indexOf('Seal exact-source browser acceptance inputs') < build.indexOf('Transfer immutable acceptance inputs to profile runners'));
  assert.doesNotMatch(build, /Accept actual Godot Web input/);
  assert.match(build, /bundle_ready: \$\{\{ steps.transfer_inputs.outcome == 'success' \}\}/);
  assert.match(build, /Transfer immutable acceptance inputs to profile runners\n        id: transfer_inputs/);
  const expression = profilesJob.match(/^    if: \$\{\{ (.*?) \}\}$/m)?.[1];
  assert.equal(expression, "!cancelled() && needs.build.outputs.bundle_ready == 'true'");
  // Execute the actual workflow expression, not a separately maintained predicate.
  const allowed = new Function('cancelled', 'needs', `return (${expression});`);
  const evaluate = (result, ready, cancelled = false) => allowed(() => cancelled, { build: { result, outputs: { bundle_ready: ready } } });
  assert.equal(evaluate('success', 'true'), true);
  assert.equal(evaluate('failure', 'true'), true, 'post-transfer producer failure must retain independent diagnostics');
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
for (const profile of ['touch-390', 'retina-touch-390']) {
  await test(`current direct-world ${profile} labels retain exact touch and layout evidence`, () => {
    // Match the current directWorldCase emitter; the original loop above keeps
    // accepting the legacy branch's exact labels. These are synthetic receipts,
    // not a substitute for the runner's actual input and geometry assertions.
    const coverage = ['real physical target approach', 'original proximity and single action', 'bottom plaque above inline controls',
      'drag is not tap', 'cancel and fresh gesture', 'two-finger camera ownership', 'scene then inventory ownership', 'settings modal cancellation',
      ...(profile === 'touch-390' ? ['landscape resize and direct tap'] : [])];
    const run = (mutate = () => {}) => runReceipt(profile, 'mobile-world', input => {
      input.report.cases[0].mobileWorld.coverage = [...coverage];
      mutate(input.report.cases[0].mobileWorld);
    });
    const ok = run();
    assert.equal(ok.status, 0, ok.stderr);
    assert.equal(ok.receipt.cases[0].id, profile);
    assert.deepEqual(ok.receipt.cases[0].coverage, coverage);
    const invalid = [
      ['missing plaque', world => { world.coverage = world.coverage.filter(label => label !== 'bottom plaque above inline controls'); }],
      ['unknown plaque label', world => { world.coverage = world.coverage.map(label => label === 'bottom plaque above inline controls' ? `${label} (unchecked)` : label); }],
      ['missing touch input', world => { world.inputs = []; }],
      ['mouse is not touch', world => { world.inputs = [{ method: 'Input.dispatchMouseEvent' }]; }],
      ['unknown touch method', world => { world.inputs = [{ method: 'Input.dispatchTouchEventUnchecked' }]; }],
      ['missing all coverage', world => { world.coverage = []; }]
    ];
    if (profile === 'touch-390') invalid.push(
      ['missing landscape', world => { world.coverage = world.coverage.filter(label => label !== 'landscape resize and direct tap'); }],
      ['unknown landscape label', world => { world.coverage = world.coverage.map(label => label === 'landscape resize and direct tap' ? `${label} (unchecked)` : label); }]
    );
    for (const [reason, mutate] of invalid) assert.notEqual(run(mutate).status, 0, `${profile}: ${reason} unexpectedly accepted`);
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

// Library fixtures below are synthetic byte identities for executing the exact
// workflow validator. They are not earned gameplay or real browser screenshots.
assert.ok(libraryJob, 'Missing separate bounded library profile job');
const libraryCode = receiptCode('Accept actual library boundary input for this profile', libraryJob);
const libraryProfiles = ['desktop-1280', 'touch-390'];
const libraryFiles = ['before_library_rule_read.json', 'before_library_022_opening.json'];
const receiptHash = 'e'.repeat(64);
const digest = bytes => createHash('sha256').update(bytes).digest('hex');
await test('library profiles reuse the same sealed source in two read-only bounded runners', () => {
  assert.match(libraryJob, /needs: build/);
  assert.match(libraryJob, /timeout-minutes: 12/);
  assert.match(libraryJob, /permissions:\n      contents: read/);
  assert.match(libraryJob, /fail-fast: false/);
  assert.deepEqual(libraryJob.match(/profile: \[([^\]]+)\]/)[1].split(',').map(v => v.trim()), libraryProfiles);
  assert.match(libraryJob, /ref: \$\{\{ github.sha \}\}/);
  assert.match(libraryJob, /node-version: 22\.23\.3/);
  assert.match(libraryJob, /name: \$\{\{ needs.build.outputs.bundle_name \}\}/);
  assert.match(libraryJob, /EXPECTED_RECEIPT_SHA: \$\{\{ needs.build.outputs.receipt_sha \}\}/);
  assert.match(libraryJob, /EXPECTED_PRODUCER_ATTEMPT: \$\{\{ needs.build.outputs.producer_attempt \}\}/);
  const verify = step('Verify exact source and every input byte', libraryJob);
  assert.match(verify, /--receipt-sha "\$EXPECTED_RECEIPT_SHA"/);
  assert.match(verify, /--producer-attempt "\$EXPECTED_PRODUCER_ATTEMPT"/);
  assert.match(verify, /--output-receipt godot_native\/exports\/verification\/verified-library-inputs.json/);
  assert.equal((libraryJob.match(/node godot_native\/tools\/verify_web_export\.mjs/g) || []).length, 1);
  assert.match(libraryJob, /--scenarios library --only "\$ACCEPTANCE_PROFILE"/);
  assert.match(libraryJob, /--export-dir "\$RUNNER_TEMP\/godot-web-inputs\/web-release"/);
  assert.match(libraryJob, /--fixtures "\$RUNNER_TEMP\/godot-web-inputs\/controller-earned"/);
  assert.match(libraryJob, /--boot-timeout 180000/);
  assert.match(libraryJob, /--chrome-arg --use-angle=swiftshader/);
  assert.doesNotMatch(libraryJob, /npm ci|build_web\.mjs|sync_source\.mjs|continue-on-error|pages: write|id-token: write|deploy-pages@|upload-pages-artifact@/);
  assert.match(step("Preserve this profile's library evidence", libraryJob), /if: always\(\)/);
  assert.match(libraryJob, /name: godot-web-library-\$\{\{ matrix.profile \}\}-\$\{\{ github.run_id \}\}-\$\{\{ github.run_attempt \}\}/);
});
await test('library diagnostics require a sealed producer, while deployment requires all four jobs', () => {
  const expression = libraryJob.match(/^    if: \$\{\{ (.*?) \}\}$/m)?.[1];
  assert.equal(expression, "!cancelled() && needs.build.outputs.bundle_ready == 'true'");
  const allowed = new Function('cancelled', 'needs', `return (${expression});`);
  for (const result of ['success', 'failure']) {
    assert.equal(allowed(() => false, { build: { result, outputs: { bundle_ready: 'true' } } }), true);
    assert.equal(allowed(() => false, { build: { result, outputs: { bundle_ready: 'false' } } }), false);
  }
  assert.equal(allowed(() => true, { build: { outputs: { bundle_ready: 'true' } } }), false);
  const deployExpression = deploy.match(/^    if: \$\{\{ (.*?) \}\}$/m)?.[1];
  const publish = new Function('needs', 'github', `return (${deployExpression});`);
  const ready = { build: { result: 'success' }, browser_baseline: { result: 'success' }, browser_profiles: { result: 'success' }, library_profiles: { result: 'success' } };
  for (const event_name of ['push', 'workflow_dispatch']) for (const ref of ['refs/heads/main', 'refs/heads/codex/godot-complete-20261019']) {
    assert.equal(publish(ready, { event_name, ref }), true);
    for (const job of Object.keys(ready)) for (const result of ['failure', 'cancelled', 'skipped']) {
      const needs = structuredClone(ready); needs[job].result = result;
      assert.equal(publish(needs, { event_name, ref }), false, `${job}/${result} cannot publish`);
    }
  }
  assert.equal(publish(ready, { event_name: 'pull_request', ref: 'refs/heads/main' }), false);
  assert.equal(publish(ready, { event_name: 'workflow_dispatch', ref: 'refs/heads/unapproved' }), false);
});
await test('producer earns library boundaries through the existing isolated recorder before sealing', () => {
  const fixtureStep = step('Generate controller-earned fixture for mobile browser input', build);
  assert.match(fixtureStep, /createNativeTestSandbox\(path.resolve\('godot_native'\), '755-web-library-fixture-'\)/);
  assert.match(fixtureStep, /libraryCommand = \['--headless', '--path', librarySandbox.project, '--script', 'res:\/\/tests\/library_continuity_recorder.gd'\]/);
  assert.match(fixtureStep, /LIBRARY_CAPTURE_DIR: output, CAMPAIGN_REPORT: libraryReport/);
  assert.match(fixtureStep, /libraryCampaign.failures !== 0/);
  assert.match(fixtureStep, /!libraryCampaign.notManualPlaythrough \|\| !libraryCampaign.spatialSetupExplicit/);
  assert.match(fixtureStep, /\[1, 2\]\.every\(chapter => libraryCampaign.completedChapters\?\.includes\(chapter\)\)/);
  assert.match(fixtureStep, /fixtures: \['before_library_rule_read.json', 'before_library_022_opening.json'\]\.map\(portableFixture\)/);
  assert.ok(build.indexOf('library_continuity_recorder.gd') < build.indexOf('Seal exact-source browser acceptance inputs'));
  assert.match(fixtureStep, /not complete natural-navigation proof/);
  const evidence = step('Preserve build evidence', build);
  for (const filename of ['library-controller.log', 'library-controller-report.json', ...libraryFiles]) assert.ok(evidence.includes(`godot_native/exports/verification/controller-earned/${filename}`), `producer evidence retains ${filename}`);
});
function librarySample(profile) {
  const [width, height, touch, dpr] = dimensions[profile];
  const runnerBytes = Buffer.from('// Synthetic immutable runner bytes for workflow validator tests.\n');
  const fixtureBytes = Object.fromEntries(libraryFiles.map((file, i) => [file, Buffer.from(JSON.stringify({ format: '7-55-godot-native', version: 1, state: { testBoundary: i } }))]));
  const inputs = libraryFiles.map(fixture => ({ fixture, bytes: fixtureBytes[fixture].length, sha256: digest(fixtureBytes[fixture]) }));
  const source = { checkedOutCommit: sha, head: sha, base: 'f'.repeat(40), event: 'pull_request', run: '1234', attempt: '1', dirty: false };
  const screenshots = ['library-rule-entry', 'library-rule-reviewed', 'library-handoff'].map(stage => ({ path: `${profile}-${stage}.png`, bytes: 1, sha256: digest(Buffer.from('x')) }));
  const screenshotBytes = Object.fromEntries(screenshots.map(file => [file.path, Buffer.from('x')]));
  const labels = [`${profile} unread library rule`, `${profile} library handoff`];
  const item = { id: profile, width, height, touch, dpr, passed: true, renderer: { webgl2: true }, screenshots,
    imports: inputs.map(input => ({ filename: input.fixture, sha256: input.sha256, bytes: input.bytes })),
    library: { completed: true, unreadReopen: true, explicitRead: true, reload: true, handoff: 'original skip-to-arrival button then ordinary return-to-campus', fixtureBoundary: 'controller-earned; not manual spatial navigation', dialogueSamples: [{ frame: 1, text: ['synthetic contract fixture'] }] },
    saveInputs: labels.map(label => ({ label, dispatchCompleted: true, touch, events: [{ method: touch ? 'Input.dispatchTouchEvent' : 'Input.dispatchMouseEvent' }] })),
    saveAttempts: labels.map(label => ({ label, completedAt: 123, disk: { entries: [{ key: '/userfs/SevenFiftyFiveNative/save.json', sha256: fixtureHash }] } })) };
  return { runnerBytes, fixtureBytes, screenshotBytes,
    provenance: { source: structuredClone(source), libraryInputs: { recorder: 'res://tests/library_continuity_recorder.gd', checks: 10, fixtures: inputs } },
    bundle: { verified: true, source, receiptSha: receiptHash, producerAttempt: '1' },
    report: { passed: true, scenarios: 'library', exportManifest: { sourceCommit: sha, engine: '4.7.1.stable.official' }, runnerSha256: digest(runnerBytes), cases: [item] } };
}
function runLibraryReceipt(profile, mutate = () => {}) {
  const root = mkdtempSync(path.join(tmpdir(), '755-library-receipt-'));
  try {
    const input = librarySample(profile); mutate(input);
    const verification = path.join(root, 'godot_native/exports/verification');
    const directory = path.join(verification, 'web_library');
    const earned = path.join(root, 'inputs/godot-web-inputs/controller-earned');
    const toolDirectory = path.join(root, 'godot_native/tools');
    for (const folder of [directory, earned, toolDirectory]) mkdirSync(folder, { recursive: true });
    writeFileSync(path.join(directory, 'web-acceptance.json'), JSON.stringify(input.report));
    writeFileSync(path.join(verification, 'verified-library-inputs.json'), JSON.stringify(input.bundle));
    writeFileSync(path.join(earned, 'fixture-provenance.json'), JSON.stringify(input.provenance));
    writeFileSync(path.join(toolDirectory, 'verify_web_export.mjs'), input.runnerBytes);
    for (const [file, bytes] of Object.entries(input.fixtureBytes)) writeFileSync(path.join(earned, file), bytes);
    for (const [file, bytes] of Object.entries(input.screenshotBytes)) writeFileSync(path.join(directory, file), bytes);
    const result = spawnSync(process.execPath, ['--input-type=module'], { input: libraryCode, cwd: root,
      env: { ...process.env, GITHUB_SHA: sha, ACCEPTANCE_PROFILE: profile, RUNNER_TEMP: path.join(root, 'inputs'), EXPECTED_RECEIPT_SHA: receiptHash, EXPECTED_PRODUCER_ATTEMPT: '1' }, encoding: 'utf8' });
    return { ...result, receipt: result.status === 0 ? JSON.parse(readFileSync(path.join(directory, 'ci-library-receipt.json'), 'utf8')) : null };
  } finally { rmSync(root, { recursive: true, force: true }); }
}
for (const profile of libraryProfiles) {
  await test(`library exact ${profile} receipt binds the runner, two imported files and actual screenshot records`, () => {
    const result = runLibraryReceipt(profile); assert.equal(result.status, 0, result.stderr);
    assert.equal(result.receipt.cases.length, 1); assert.equal(result.receipt.cases[0].id, profile);
    assert.deepEqual(result.receipt.inputs.map(input => input.fixture), libraryFiles);
    assert.equal(result.receipt.inputBundle.receiptSha, receiptHash);
    assert.equal(result.receipt.inputBundle.producerAttempt, '1');
    assert.equal(result.receipt.cases[0].screenshots.length, 3);
    assert.match(result.receipt.scope, /Not complete natural navigation through the bag, paper, librarian stamp or PASS chain/);
    assert.match(result.receipt.scope, /not physical-device proof/);
  });
}
function rejectLibrary(mutations) {
  for (const profile of libraryProfiles) for (const [name, mutate] of mutations) {
    const result = runLibraryReceipt(profile, mutate);
    assert.notEqual(result.status, 0, `${profile}: ${name} unexpectedly accepted`);
    assert.equal(result.receipt, null);
  }
}
await test('library rejects wrong source, runner, engine, scenario and profile evidence', () => rejectLibrary([
  ['wrong source', x => { x.report.exportManifest.sourceCommit = 'c'.repeat(40); }],
  ['wrong engine', x => { x.report.exportManifest.engine = '4.6.3.stable.official'; }],
  ['wrong runner hash', x => { x.report.runnerSha256 = 'c'.repeat(64); }],
  ['changed runner bytes', x => { x.runnerBytes = Buffer.from('different runner'); }],
  ['wrong scenario', x => { x.report.scenarios = 'all'; }],
  ['failed report', x => { x.report.passed = false; }],
  ['failed case', x => { x.report.cases[0].passed = false; }],
  ['no cases', x => { x.report.cases = []; }],
  ['extra case', x => { x.report.cases.push(structuredClone(x.report.cases[0])); }],
  ['wrong profile', x => { x.report.cases[0].id = 'retina-touch-390'; }],
  ['wrong dimensions', x => { x.report.cases[0].width += 1; }],
  ['wrong DPR', x => { x.report.cases[0].dpr += 1; }],
  ['wrong pointer mode', x => { x.report.cases[0].touch = !x.report.cases[0].touch; }],
  ['no actual WebGL2', x => { x.report.cases[0].renderer.webgl2 = false; }]
]));
await test('library rejects a different or incomplete sealed producer receipt', () => rejectLibrary([
  ['not verified', x => { x.bundle.verified = false; }],
  ['different checked-out source', x => { x.bundle.source.checkedOutCommit = 'c'.repeat(40); }],
  ['different receipt hash', x => { x.bundle.receiptSha = 'd'.repeat(64); }],
  ['different producer attempt', x => { x.bundle.producerAttempt = '2'; }],
  ['missing attempt', x => { delete x.bundle.producerAttempt; }],
  ['different fixture provenance source', x => { x.provenance.source.head = 'c'.repeat(40); }]
]));
await test('library rejects wrong or missing recorder, exact boundary files, hashes and byte sizes', () => rejectLibrary([
  ['wrong recorder', x => { x.provenance.libraryInputs.recorder = 'res://tests/invented.gd'; }],
  ['no recorder checks', x => { x.provenance.libraryInputs.checks = 0; }],
  ['noninteger checks', x => { x.provenance.libraryInputs.checks = 1.5; }],
  ['missing boundary', x => { x.provenance.libraryInputs.fixtures.pop(); }],
  ['duplicate boundary', x => { x.provenance.libraryInputs.fixtures[1] = structuredClone(x.provenance.libraryInputs.fixtures[0]); }],
  ['missing fixture file', x => { delete x.fixtureBytes[libraryFiles[0]]; }],
  ['changed fixture bytes', x => { x.fixtureBytes[libraryFiles[0]] = Buffer.from('changed'); }],
  ['wrong fixture hash', x => { x.provenance.libraryInputs.fixtures[0].sha256 = 'd'.repeat(64); }],
  ['wrong fixture size', x => { x.provenance.libraryInputs.fixtures[0].bytes++; }],
  ['missing actual import', x => { x.report.cases[0].imports.pop(); }],
  ['wrong imported file', x => { x.report.cases[0].imports[0].filename = 'other.json'; }],
  ['wrong imported hash', x => { x.report.cases[0].imports[0].sha256 = 'd'.repeat(64); }],
  ['wrong imported size', x => { x.report.cases[0].imports[0].bytes++; }]
]));
await test('library rejects missing continuity facts, altered handoff and overclaimed fixture boundaries', () => rejectLibrary([
  ...['completed', 'unreadReopen', 'explicitRead', 'reload'].map(key => [`missing ${key}`, x => { delete x.report.cases[0].library[key]; }]),
  ['truthy is not true', x => { x.report.cases[0].library.explicitRead = 'true'; }],
  ['wrong handoff', x => { x.report.cases[0].library.handoff = 'injected chapter change'; }],
  ['overclaimed manual route', x => { x.report.cases[0].library.fixtureBoundary = 'complete manual spatial navigation'; }],
  ['no dialogue evidence', x => { x.report.cases[0].library.dialogueSamples = []; }]
]));
await test('library rejects missing screenshot stages and another profile screenshot', () => rejectLibrary([
  ...[0, 1, 2].map(index => [`missing screenshot stage ${index}`, x => { x.report.cases[0].screenshots.splice(index, 1); }]),
  ['wrong screenshot profile', x => { x.report.cases[0].screenshots[0].path = 'other-library-rule-entry.png'; }],
  ['unstructured screenshots', x => { x.report.cases[0].screenshots = x.report.cases[0].screenshots.map(file => file.path); }]
]));
await test('library checks actual screenshot files against their recorded size and digest', () => rejectLibrary([
  ['missing screenshot file', x => { delete x.screenshotBytes[x.report.cases[0].screenshots[0].path]; }],
  ['changed screenshot bytes', x => { x.screenshotBytes[x.report.cases[0].screenshots[0].path] = Buffer.from('changed'); }],
  ['wrong screenshot size', x => { x.report.cases[0].screenshots[0].bytes++; }],
  ['zero screenshot size', x => { x.report.cases[0].screenshots[0].bytes = 0; }],
  ['noninteger screenshot size', x => { x.report.cases[0].screenshots[0].bytes = 1.5; }],
  ['wrong screenshot digest', x => { x.report.cases[0].screenshots[0].sha256 = 'd'.repeat(64); }],
  ['malformed screenshot digest', x => { x.report.cases[0].screenshots[0].sha256 = 'not-a-hash'; }],
  ['traversing screenshot path', x => { x.report.cases[0].screenshots[0].path = `../${x.report.cases[0].screenshots[0].path}`; }]
]));
await test('library rejects missing explicit input or saved/reloaded boundary receipts', () => rejectLibrary([
  ['missing first save input', x => { x.report.cases[0].saveInputs.shift(); }],
  ['missing second save input', x => { x.report.cases[0].saveInputs.pop(); }],
  ['unfinished input dispatch', x => { x.report.cases[0].saveInputs[0].dispatchCompleted = false; }],
  ['wrong save pointer mode', x => { x.report.cases[0].saveInputs[0].touch = !x.report.cases[0].touch; }],
  ['no dispatch event evidence', x => { x.report.cases[0].saveInputs[0].events = []; }],
  ['wrong input label', x => { x.report.cases[0].saveInputs[0].label = 'other save'; }],
  ['missing first save receipt', x => { x.report.cases[0].saveAttempts.shift(); }],
  ['missing second save receipt', x => { x.report.cases[0].saveAttempts.pop(); }],
  ['failed receipt', x => { x.report.cases[0].saveAttempts[0].failedAt = 456; }],
  ['unfinished receipt', x => { delete x.report.cases[0].saveAttempts[0].completedAt; }],
  ['no independent disk evidence', x => { x.report.cases[0].saveAttempts[0].disk.entries = []; }]
]));
