#!/usr/bin/env node
// Pure Node workflow/receipt contracts. This does not launch a browser or prove gameplay.
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { test } from 'node:test';
import {phoneCoverage} from '../tools/web_phone_shards.mjs';

const workflow = readFileSync(new URL('../../.github/workflows/deploy-pages.yml', import.meta.url), 'utf8');
// Only split at job-level YAML keys, never let a newly inserted job become part
// of its predecessor and accidentally satisfy that predecessor's assertions.
const jobsSource = workflow.split('\njobs:\n')[1];
const headings = [...jobsSource.matchAll(/^  ([a-z][a-z0-9_]*):\n/gm)];
const jobs = Object.fromEntries(headings.map((match, index) => [match[1], jobsSource.slice(match.index + match[0].length, headings[index + 1]?.index)]));
const { build, browser_baseline: baselineJob, browser_streaming: streamingJob, browser_profiles: profilesJob, phone_profiles: phoneJob, library_profiles: libraryJob, browser_coverage: coverageJob, deploy } = jobs;
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
const phoneCode = receiptCode('Accept actual early charging and two-stage Tiyi phone input', phoneJob);
const phoneContract = readFileSync(new URL('../tools/web_phone_shards.mjs', import.meta.url), 'utf8');
const fixtureHelper = readFileSync(new URL('../tools/prepare_web_controller_fixtures.mjs', import.meta.url), 'utf8');
const consumerNames = ['browser_baseline', 'browser_streaming', 'browser_profiles', 'phone_profiles', 'library_profiles'];
const gateNames = ['build', 'browser_contracts', ...consumerNames, 'browser_coverage'];

await test('one immutable producer fans out to nine bounded jobs and thirteen logical consumers', () => {
  assert.deepEqual(Object.keys(jobs), [...gateNames, 'deploy']);
  assert.doesNotMatch(build, /^    needs:/m);
  for (const name of consumerNames) {
    const job = jobs[name];
    assert.equal(job.match(/^    needs: (.+)$/m)?.[1], '[build, browser_contracts]');
    assert.equal(job.match(/^    if: \$\{\{ (.*?) \}\}$/m)?.[1], "!cancelled() && needs.build.outputs.bundle_ready == 'true'");
    assert.match(job, /runs-on: ubuntu-latest/);
    assert.match(job, /permissions:\n      contents: read/);
    assert.match(job, /ref: \$\{\{ github.sha \}\}/);
    const checkout = step('Check out exact producer source', job);
    assert.match(checkout, /filter: blob:none/);
    assert.match(checkout, /sparse-checkout: godot_native\/tools\n/);
    assert.match(job, /node-version: 22\.23\.3/);
    assert.match(job, /EXPECTED_RECEIPT_SHA: \$\{\{ needs.build.outputs.receipt_sha \}\}/);
    assert.match(job, /EXPECTED_PRODUCER_ATTEMPT: \$\{\{ needs.build.outputs.producer_attempt \}\}/);
    assert.doesNotMatch(job, /npm ci|build_web\.mjs|sync_source\.mjs|convert_media|continue-on-error|pages: write|id-token: write|deploy-pages@|upload-pages-artifact@/);
    const download = step("Download this run's sealed producer inputs", job);
    assert.match(download, /name: \$\{\{ needs.build.outputs.bundle_name \}\}/);
    assert.doesNotMatch(download, /run-id:|repository:|github-token:/);
    const verify = step('Verify exact source and every input byte', job);
    for (const option of ['--bundle-dir "$RUNNER_TEMP/godot-web-inputs"', '--receipt-sha "$EXPECTED_RECEIPT_SHA"', '--producer-attempt "$EXPECTED_PRODUCER_ATTEMPT"']) assert.ok(verify.includes(option));
    for (const match of job.matchAll(/^      - name: (.+)$/gm)) {
      if (['browser_streaming','browser_profiles','library_profiles'].includes(name) && ['Verify exact source and every phone input byte', 'Accept actual early charging and two-stage Tiyi phone input', "Preserve this phone group's browser evidence"].includes(match[1])) continue; // Exact independent gates and artifact conditions are exercised below.
      if (match[1].startsWith('Preserve')) assert.match(step(match[1], job), /if: always\(\)/);
      else assert.doesNotMatch(step(match[1], job), /^        if:/m, `${name}/${match[1]} cannot skip a gate`);
    }
  }
  assert.match(baselineJob, /max-parallel: 2/);
  assert.match(profilesJob, /max-parallel: 3/);
  assert.match(phoneJob, /max-parallel: 1/);
  assert.match(libraryJob, /max-parallel: 2/);
  assert.equal(2 + 1 + 3 + 1 + 2, 9, 'bounded physical job count');
  assert.deepEqual(phoneRows(), [['retina-touch-390','c2-tiyi']]);
  assert.deepEqual(pairedRows(profilesJob), [['desktop-1280','desktop-1280','all'],['touch-390','retina-touch-390','charging'],['retina-touch-390','','']]);
  assert.deepEqual(pairedRows(libraryJob), [['desktop-1280','',''],['touch-390','retina-touch-390','c1-tiyi']]);
  assert.equal((workflow.match(/node godot_native\/tools\/build_web\.mjs/g) || []).length, 1);
  assert.match(step('Accept actual world input for this profile'), /--scenarios mobile-world --only "\$ACCEPTANCE_PROFILE"/);
  const phone = step('Accept actual early charging and two-stage Tiyi phone input', phoneJob);
  assert.match(phoneJob, /^    timeout-minutes: 18$/m);
  assert.match(profilesJob, /^    timeout-minutes: 12$/m);
  assert.match(phone, /timeout-minutes: 12/);
  assert.match(phone, /--scenarios phone-recovery --only "\$ACCEPTANCE_PROFILE"/);
  assert.match(phone, /--phone-group "\$ACCEPTANCE_PHONE_GROUP"/);
  for (const job of [baselineJob, streamingJob, profilesJob, phoneJob, libraryJob]) {
    assert.match(job, /--boot-timeout 180000/);
    assert.match(job, /--chrome-arg --use-angle=swiftshader/);
    assert.match(job, /--chrome-arg --enable-unsafe-swiftshader/);
  }
});

function pairedRows(job) {
  return [...job.matchAll(/          - profile: (.+)\n            phone_profile: (.+)\n            phone_group: (.+)/g)].map(m => m.slice(1).map(value => value === "''" ? '' : value));
}
function phoneRows() { return [...phoneJob.matchAll(/          - profile: (.+)\n            group: (.+)/g)].map(m => m.slice(1)); }
function assertPhoneKeys(pairs) {
  const keys = pairs.map(pair => pair.join('/')).sort();
  assert.deepEqual(keys, ['desktop-1280/all','touch-390/all','retina-touch-390/charging','retina-touch-390/c1-tiyi','retina-touch-390/c2-tiyi'].sort());
  assert.equal(new Set(keys).size, 5, 'No phone group is omitted or duplicated across physical jobs');
}
await test('duration-balanced pairs preserve five exact phone keys and thirteen logical artifacts', () => {
  const phonePairs = [...pairedRows(profilesJob), ...pairedRows(libraryJob)].filter(row => row[1]).map(row => row.slice(1));
  phonePairs.push(['touch-390','all'], ...phoneRows());
  assertPhoneKeys(phonePairs);
  assert.throws(() => assertPhoneKeys(phonePairs.slice(1)), /Assertion/);
  assert.throws(() => assertPhoneKeys([...phonePairs, phonePairs[0]]), /Assertion/);
  assert.throws(() => assertPhoneKeys(phonePairs.map((row, i) => i === 0 ? ['unknown','all'] : row)), /Assertion/);
  const artifactKeys = ['baseline-standard','baseline-wide','streaming',
    ...pairedRows(profilesJob).map(row => `world-${row[0]}`),
    ...phonePairs.map(row => `phone-${row.join('-')}`), ...pairedRows(libraryJob).map(row => `library-${row[0]}`)];
  assert.equal(artifactKeys.length, 13);
  assert.equal(new Set(artifactKeys).size, 13);
  assert.equal(6 + 1 + 3 + phonePairs.length + 2, 17, 'All original independent browser reports remain mandatory');
});
await test('all balanced phone invocations retain identical commands, validators and isolated evidence', () => {
  const title = 'Accept actual early charging and two-stage Tiyi phone input';
  const separate = step(title, phoneJob);
  for (const [name, job, first] of [['world',profilesJob,'Preserve this profile\'s independent browser evidence'], ['streaming',streamingJob,'Preserve streaming evidence'], ['library',libraryJob,'Preserve this profile\'s library evidence']]) {
    const combined = step(title, job), paired = name !== 'streaming';
    assert.equal(combined.split('        run: |\n')[1].trim(), separate.split('        run: |\n')[1].trim());
    assert.equal(receiptCode(title, job), phoneCode);
    assert.equal((job.match(/node godot_native\/tools\/verify_web_export\.mjs/g) || []).length, 2);
    assert.match(combined, /timeout-minutes: 8/);
    assert.match(combined, /--output godot_native\/exports\/verification\/web_phone_recovery/);
    assert.ok(job.indexOf(first) < job.indexOf(title));
    if (paired) {
      assert.match(combined, /ACCEPTANCE_PROFILE: \$\{\{ matrix.phone_profile \}\}/);
      assert.match(combined, /ACCEPTANCE_PHONE_GROUP: \$\{\{ matrix.phone_group \}\}/);
    } else {
      assert.match(combined, /ACCEPTANCE_PROFILE: touch-390\n/);
      assert.match(combined, /ACCEPTANCE_PHONE_GROUP: all\n/);
    }
    const artifact = step("Preserve this phone group's browser evidence", job);
    if (paired) assert.match(artifact, /name: godot-web-phone-\$\{\{ matrix.phone_profile \}\}-\$\{\{ matrix.phone_group \}\}-\$\{\{ github.run_id \}\}-\$\{\{ github.run_attempt \}\}/);
    else assert.match(artifact, /name: godot-web-phone-touch-390-all-\$\{\{ github.run_id \}\}-\$\{\{ github.run_attempt \}\}/);
    assert.match(artifact, /verified-inputs\.json/);
    assert.match(artifact, /web_phone_recovery\//);
    assert.doesNotMatch(artifact, /web_mobile_world\/|web_streaming\/|web_library\//);
    if (!paired) assert.match(artifact, /if: always\(\)/);
    else {
      const expression = artifact.match(/^        if: \$\{\{ (.*?) \}\}$/m)?.[1];
      assert.equal(expression, "always() && matrix.phone_profile != ''");
      const preserve = new Function('always','matrix',`return (${expression});`);
      for (const profile of ['',...profiles]) assert.equal(preserve(() => true,{phone_profile:profile}), profile !== '');
    }
  }
});
await test('paired cases continue after the first browser fails but never after input verification fails', () => {
  const title = 'Accept actual early charging and two-stage Tiyi phone input';
  for (const [name,job] of [['world',profilesJob],['streaming',streamingJob],['library',libraryJob]]) {
    assert.match(step('Verify exact source and every input byte',job), /id: verify_inputs/);
    const checked = [[step(title,job),name === 'world' ? 'verify_inputs' : 'verify_phone_inputs']];
    if (name !== 'world') {
      const verify = step('Verify exact source and every phone input byte',job);
      assert.match(verify, /id: verify_phone_inputs/);
      assert.equal(verify.split('        run: |\n')[1].trim(),step('Verify exact source and every input byte',phoneJob).split('        run: |\n')[1].trim());
      checked.push([verify,'verify_inputs']);
    }
    for (const [body,prerequisite] of checked) {
      const expression = body.match(/^        if: \$\{\{ (.*?) \}\}$/m)?.[1];
      const profileGate = name === 'streaming' ? '' : "matrix.phone_profile != '' && ";
      assert.equal(expression, `!cancelled() && ${profileGate}steps.${prerequisite}.outcome == 'success'`);
      const allowed = new Function('cancelled','steps','matrix',`return (${expression});`);
      for (const outcome of ['success','failure','skipped','cancelled',undefined]) for (const cancelled of [true,false]) for (const phone_profile of ['',...profiles]) for (const firstOutcome of ['success','failure','skipped']) {
        assert.equal(allowed(() => cancelled,{[prerequisite]:{outcome},first_browser:{outcome:firstOutcome}},{phone_profile}), !cancelled && outcome === 'success' && (name === 'streaming' || phone_profile !== ''));
      }
    }
  }
});

await test('balanced baseline batches retain all six original default cases and separate streaming', () => {
  assert.deepEqual([...baselineJob.matchAll(/          - batch: (.+)\n            profiles: (.+)/g)].map(m => m.slice(1)), [['standard','desktop-1280 touch-390 retina-1440'],['wide','desktop-1440 retina-touch-390 desktop-1920']]);
  const baseline = step('Accept actual Godot Web input and persisted reload at Pages subpath', baselineJob);
  assert.match(baseline, /timeout-minutes: 12/);
  assert.match(baseline, /for profile in \$ACCEPTANCE_BASELINE_PROFILES; do/);
  assert.match(baseline, /--only "\$profile"/);
  assert.doesNotMatch(baseline, /--scenarios|--fixtures/);
  assert.match(baseline, /report.scenarios !== 'all'/);
  assert.match(baseline, /report.cases\?\.length !== 1/);
  assert.match(streamingJob, /--scenarios streaming/);
  assert.doesNotMatch(step('Accept actual streaming failure retry and persisted reload', streamingJob), /--only /);
  assert.match(streamingJob, /timeout-minutes: 12/);
  assert.match(streamingJob, /--fixtures "\$RUNNER_TEMP\/godot-web-inputs\/controller-earned"/);
});

await test('moved streaming validator still rejects every missing original fault/retry/reload requirement', () => {
  // Synthetic contract receipts execute the actual inline validator. They do
  // not replace running the real browser or prove the controlled network fault.
  const code = receiptCode('Accept actual streaming failure retry and persisted reload', streamingJob);
  const root = mkdtempSync(path.join(tmpdir(), '755-streaming-workflow-receipt-'));
  try {
    const verification = path.join(root, 'godot_native/exports/verification');
    const directory = path.join(verification, 'web_streaming');
    const earned = path.join(root, 'inputs/godot-web-inputs/controller-earned');
    for (const folder of [directory, earned]) mkdirSync(folder, { recursive: true });
    const fixture = { fixture: 'after_c2_dorm_exit.json', sha256: fixtureHash };
    const bundle = { verified: true, source: { checkedOutCommit: sha }, receiptSha: 'e'.repeat(64), producerAttempt: '1' };
    writeFileSync(path.join(earned, 'fixture-provenance.json'), JSON.stringify({ streamingFixture: fixture }));
    writeFileSync(path.join(verification, 'verified-streaming-inputs.json'), JSON.stringify(bundle));
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

await test('PRs cannot upload Pages and publication requires every consumer plus aggregate', () => {
  const expression = step('Upload Pages artifact', build).match(/^        if: \$\{\{ (.*?) \}\}$/m)?.[1];
  const upload = new Function('success', 'github', `return (${expression});`);
  const publishExpression = deploy.match(/^    if: \$\{\{ (.*?) \}\}$/m)?.[1];
  const publish = new Function('needs', 'github', `return (${publishExpression});`);
  assert.deepEqual(deploy.match(/^    needs: \[([^\]]+)\]$/m)[1].split(',').map(x=>x.trim()), gateNames);
  assert.deepEqual(coverageJob.match(/^    needs: \[([^\]]+)\]$/m)[1].split(',').map(x=>x.trim()), gateNames.slice(0,-1));
  const ready = Object.fromEntries(gateNames.map(name => [name,{result:'success'}]));
  for (const event_name of ['pull_request','push','workflow_dispatch']) for (const ref of ['refs/heads/main','refs/heads/codex/godot-complete-20261019','refs/heads/unapproved']) {
    const github = {event_name,ref}, allowed = event_name !== 'pull_request' && ref !== 'refs/heads/unapproved';
    for (const success of [true,false]) assert.equal(upload(()=>success,github),allowed && success);
    assert.equal(publish(ready,github),allowed);
    for (const name of gateNames) for (const result of ['failure','skipped','cancelled']) {
      const failed = structuredClone(ready); failed[name].result=result; assert.equal(publish(failed,github),false);
    }
  }
  assert.match(coverageJob, /timeout-minutes: 5/);
  assert.match(coverageJob, /filter: blob:none/);
  assert.match(coverageJob, /sparse-checkout: godot_native\/tools/);
  assert.doesNotMatch(coverageJob, /godot-web-inputs|merge-multiple: true|run-id:|repository:|github-token:/);
  assert.equal((coverageJob.match(/merge-multiple: false/g)||[]).length,5);
  assert.match(deploy, /permissions:\n      pages: write\n      id-token: write/);
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
    phoneRecovery: { group: 'all', completed: true, coverage: phoneCoverage(), inputs: [{}] } };
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
    mkdirSync(path.join(root, 'godot_native/tools'), { recursive: true });
    writeFileSync(path.join(root, 'godot_native/tools/web_phone_shards.mjs'), phoneContract);
    writeFileSync(path.join(directory, 'web-acceptance.json'), JSON.stringify(input.report));
    writeFileSync(path.join(verification, 'verified-inputs.json'), JSON.stringify({ sourceCommit: sha, totalBytes: 12345, producerAttempt: '1' }));
    writeFileSync(path.join(earned, 'fixture-provenance.json'), JSON.stringify(input.fixture));
    writeFileSync(path.join(earned, 'phone-recovery-inputs.json'), JSON.stringify(input.fixtures));
    const result = spawnSync(process.execPath, ['--input-type=module'], { input: scenario === 'mobile-world' ? worldCode : phoneCode, cwd: root,
      env: { ...process.env, GITHUB_SHA: sha, ACCEPTANCE_PROFILE: profile, ACCEPTANCE_PHONE_GROUP: 'all', RUNNER_TEMP: path.join(root, 'inputs') }, encoding: 'utf8' });
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
await test('both library profiles retain bounded fresh runners and original separate evidence', () => {
  assert.match(libraryJob, /needs: \[build, browser_contracts\]/);
  assert.match(libraryJob, /timeout-minutes: 12/);
  assert.match(libraryJob, /permissions:\n      contents: read/);
  assert.match(libraryJob, /fail-fast: false/);
  assert.deepEqual(pairedRows(libraryJob).map(row => row[0]), ['desktop-1280','touch-390']);
  assert.match(libraryJob, /ref: \$\{\{ github.sha \}\}/);
  assert.match(libraryJob, /node-version: 22\.23\.3/);
  assert.match(libraryJob, /name: \$\{\{ needs.build.outputs.bundle_name \}\}/);
  assert.match(libraryJob, /EXPECTED_RECEIPT_SHA: \$\{\{ needs.build.outputs.receipt_sha \}\}/);
  assert.match(libraryJob, /EXPECTED_PRODUCER_ATTEMPT: \$\{\{ needs.build.outputs.producer_attempt \}\}/);
  const verify = step('Verify exact source and every input byte', libraryJob);
  assert.match(verify, /--receipt-sha "\$EXPECTED_RECEIPT_SHA"/);
  assert.match(verify, /--producer-attempt "\$EXPECTED_PRODUCER_ATTEMPT"/);
  assert.match(verify, /--output-receipt godot_native\/exports\/verification\/verified-library-inputs.json/);
  assert.equal((libraryJob.match(/node godot_native\/tools\/verify_web_export\.mjs/g) || []).length, 2);
  assert.match(libraryJob, /--scenarios library --only "\$ACCEPTANCE_PROFILE"/);
  assert.match(libraryJob, /--export-dir "\$RUNNER_TEMP\/godot-web-inputs\/web-release"/);
  assert.match(libraryJob, /--fixtures "\$RUNNER_TEMP\/godot-web-inputs\/controller-earned"/);
  assert.match(libraryJob, /--boot-timeout 180000/);
  assert.match(libraryJob, /--chrome-arg --use-angle=swiftshader/);
  assert.doesNotMatch(libraryJob, /npm ci|build_web\.mjs|sync_source\.mjs|continue-on-error|pages: write|id-token: write|deploy-pages@|upload-pages-artifact@/);
  assert.match(step("Preserve this profile's library evidence", libraryJob), /if: always\(\)/);
  assert.match(libraryJob, /name: godot-web-library-\$\{\{ matrix.profile \}\}-\$\{\{ github.run_id \}\}-\$\{\{ github.run_attempt \}\}/);
});
await test('library diagnostics require a sealed producer, while deployment requires every job', () => {
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
  const ready = Object.fromEntries(gateNames.map(name => [name, {result: 'success'}]));
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
await test('producer joins two isolated existing recorders after completed export and before sealing', () => {
  const preparation = step('Install media converter', build);
  assert.ok(preparation.indexOf('node godot_native/tools/sync_source.mjs') < preparation.indexOf('node godot_native/tools/prepare_import_media.mjs --install-media'));
  assert.match(preparation, /node godot_native\/tools\/prepare_import_media.mjs --install-media/);
  const production = step('Build actual production Godot HTML, WebAssembly and PCK',build);
  assert.match(production, /run: node godot_native\/tools\/build_web.mjs --skip-prepare --prepare-controller-fixtures/);
  assert.doesNotMatch(production, /--skip-import/);
  const fixtureStep = step('Check controller-earned fixture for mobile browser input', build);
  assert.match(fixtureStep, /id: phone_recovery_inputs/);
  assert.match(fixtureStep, /run: node godot_native\/tests\/test_phone_recovery_inputs.mjs --fixtures godot_native\/exports\/verification\/controller-earned/);
  assert.doesNotMatch(workflow, /node godot_native\/tools\/prepare_web_controller_fixtures.mjs/);
  assert.ok(build.indexOf('Install media converter') < build.indexOf('Build actual production Godot HTML'));
  assert.ok(build.indexOf('Build actual production Godot HTML') < build.indexOf('Check controller-earned fixture'));
  assert.ok(build.indexOf('Check controller-earned fixture') < build.indexOf('Seal exact-source browser acceptance inputs'));
  assert.match(fixtureHelper, /campaign_continuity_recorder\.gd/);
  assert.match(fixtureHelper, /library_continuity_recorder\.gd/);
  assert.match(fixtureHelper, /Promise.allSettled/);
  assert.match(fixtureHelper, /createNativeTestSandbox/);
  const evidence = step('Preserve build evidence', build);
  for (const filename of ['library-controller.log', 'library-controller-report.json', ...libraryFiles]) assert.ok(evidence.includes(`godot_native/exports/verification/controller-earned/${filename}`));
  assert.match(evidence, /controller-earned-diagnostics\//);
  assert.match(evidence, /verification\/import-media\//);
  assert.match(evidence, /controller-fixture-process\.log/);
  assert.match(evidence, /controller-fixture-process\.json/);
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

await test('source-only contracts remain required but never delay or mutate production export', () => {
  const contracts = jobs.browser_contracts;
  assert.doesNotMatch(contracts, /^    needs:|build_web\.mjs|--export|verify_web_export\.mjs|sync_source\.mjs|convert_media\.sh/m);
  assert.match(contracts, /ref: \$\{\{ github.sha \}\}/);
  assert.match(contracts, /test "\$\(git rev-parse HEAD\)" = "\$GITHUB_SHA"/);
  for (const file of ['test_web_acceptance_workflow.mjs','test_web_consumer_source_closure.mjs','test_preparation_pipeline.mjs','test_web_phone_shards.mjs','test_web_controller_fixtures.mjs','test_web_browser_lifecycle.mjs','test_web_network_observation.mjs','test_web_streaming_fault_lifecycle.mjs','test_web_save_diagnostics.mjs','test_web_input_completion.mjs']) {
    assert.equal((workflow.match(new RegExp(`node godot_native/tests/${file.replaceAll('.', '\\.')}`, 'g')) || []).length,1);
    assert.ok(contracts.includes(file));assert.ok(!build.includes(file));
  }
  for (const file of ['test_web_audio_compat.mjs --export=','verify_web_content_boot_assets.mjs --export=','verify_web_story_only_export.mjs --export=']) assert.ok(build.includes(file));
});

await test('aggregate job-success gate rejects every omitted, failed, skipped or unknown job family', () => {
  const code=receiptCode('Require every producer and consumer job',coverageJob);
  const execute=needs=>spawnSync(process.execPath,['--input-type=module'],{input:code,env:{...process.env,ACCEPTANCE_JOB_RESULTS:JSON.stringify(needs)},encoding:'utf8'});
  const ready=()=>Object.fromEntries(gateNames.slice(0,-1).map(name=>[name,{result:'success'}]));
  assert.equal(execute(ready()).status,0);
  for (const name of gateNames.slice(0,-1)) {
    const missing=ready();delete missing[name];assert.notEqual(execute(missing).status,0);
    for (const result of ['failure','cancelled','skipped']) {const bad=ready();bad[name].result=result;assert.notEqual(execute(bad).status,0);}
  }
  assert.notEqual(execute({...ready(),unknown:{result:'success'}}).status,0);
});

await test('actual aggregate validator fails closed on incomplete coverage, altered provenance and phone partitions', () => {
  const code=receiptCode('Verify exhaustive browser coverage and shared provenance',coverageJob);
  const root=mkdtempSync(path.join(tmpdir(),'755-web-full-coverage-'));
  const run='1234',attempt='1', receiptSha='e'.repeat(64);
  try {
    const directory=path.join(root,'godot_native/tools');mkdirSync(directory,{recursive:true});
    for (const file of ['web_phone_shards.mjs','web_phone_recovery.mjs','verify_web_export.mjs']) writeFileSync(path.join(directory,file),readFileSync(new URL(`../tools/${file}`,import.meta.url)));
    const git=(...args)=>{const result=spawnSync('git',args,{cwd:root,encoding:'utf8'});assert.equal(result.status,0,result.stderr);return result.stdout.trim();};
    git('init','-q');git('add','godot_native/tools');git('-c','user.name=Contract Fixture','-c','user.email=fixture@example.invalid','commit','-qm','Synthetic validator fixture');
    const commit=git('rev-parse','HEAD'),tree=git('rev-parse','HEAD^{tree}');
    const source={event:'pull_request',head:commit,base:'f'.repeat(40),checkedOutCommit:commit,tree,run,attempt,dirty:false};
    const inputBundle={verified:true,source,receiptSha,producerAttempt:attempt,consumerAttempt:attempt};
    const sizes={'desktop-1280':[1280,720,false,1],'desktop-1440':[1440,900,false,1],'touch-390':[390,844,true,1],'retina-1440':[1440,900,false,2],'retina-touch-390':[390,844,true,3],'desktop-1920':[1920,1080,false,1]};
    const runnerSha=digest(readFileSync(path.join(directory,'verify_web_export.mjs'))),phoneSha=digest(readFileSync(path.join(directory,'web_phone_recovery.mjs'))),shardSha=digest(readFileSync(path.join(directory,'web_phone_shards.mjs')));
    const plan=[];
    const add=(key,bundle,receipt,cases)=>plan.push({key,bundle,receipt,cases});
    add('baseline-standard','verified-baseline-inputs.json','web_ci/ci-baseline-receipt.json',['desktop-1280','touch-390','retina-1440'].map(id=>[`web_ci/${id}/web-acceptance.json`,id,'all']));
    add('baseline-wide','verified-baseline-inputs.json','web_ci/ci-baseline-receipt.json',['desktop-1440','retina-touch-390','desktop-1920'].map(id=>[`web_ci/${id}/web-acceptance.json`,id,'all']));
    add('streaming','verified-streaming-inputs.json','web_streaming/ci-streaming-receipt.json',[['web_streaming/web-acceptance.json','desktop-1280','streaming']]);
    for(const id of profiles)add(`world-${id}`,'verified-inputs.json','web_mobile_world/ci-mobile-world-receipt.json',[['web_mobile_world/web-acceptance.json',id,'mobile-world']]);
    for(const [id,group] of [['desktop-1280','all'],['touch-390','all'],['retina-touch-390','charging'],['retina-touch-390','c1-tiyi'],['retina-touch-390','c2-tiyi']])add(`phone-${id}-${group}`,'verified-inputs.json','web_phone_recovery/ci-phone-recovery-receipt.json',[['web_phone_recovery/web-acceptance.json',id,'phone-recovery',group]]);
    for(const id of ['desktop-1280','touch-390'])add(`library-${id}`,'verified-library-inputs.json','web_library/ci-library-receipt.json',[['web_library/web-acceptance.json',id,'library']]);
    const files=()=>Object.fromEntries(plan.map(item=>{
      const docs={[item.bundle]:structuredClone(inputBundle)};
      const receipt={sourceCommit:commit,inputBundle:structuredClone(inputBundle),cases:item.cases.map(([,id])=>({id}))};
      if(item.key==='streaming'){receipt.case='desktop-1280';receipt.verified=['a','b','c','d'];}
      for(const [file,id,scenarios,group] of item.cases){
        const [width,height,touch,dpr]=sizes[id];const c={id,width,height,touch,dpr,passed:true,renderer:{webgl2:true}};
        const report={passed:true,scenarios,runnerSha256:runnerSha,exportManifest:{sourceCommit:commit,engine:'4.7.1.stable.official'},cases:[c],checks:[{ok:true}],errors:[]};
        if(group){c.phoneRecovery={completed:true,group,coverage:phoneCoverage(group),inputs:[{}]};report.phoneRecoveryRunnerSha256=phoneSha;report.phoneShardRunnerSha256=shardSha;receipt.group=group;receipt.cases[0]={id,group,coverage:phoneCoverage(group)};}
        docs[file]=report;
      }
      docs[item.receipt]=receipt;return [`godot-web-${item.key}-${run}-${attempt}`,docs];
    }));
    const evidenceRoot=path.join(root,'inputs/godot-web-evidence');
    const execute=(mutate=()=>{}, currentAttempt=attempt)=>{
      const data=files();mutate(data);
      rmSync(evidenceRoot,{recursive:true,force:true});mkdirSync(evidenceRoot,{recursive:true});
      for(const [name,docs] of Object.entries(data))for(const [file,value]of Object.entries(docs)){
        const target=path.join(evidenceRoot,name,file);mkdirSync(path.dirname(target),{recursive:true});writeFileSync(target,JSON.stringify(value));
      }
      return spawnSync(process.execPath,['--input-type=module'],{input:code,cwd:root,encoding:'utf8',env:{...process.env,GITHUB_SHA:commit,GITHUB_EVENT_NAME:'pull_request',GITHUB_RUN_ID:run,GITHUB_RUN_ATTEMPT:currentAttempt,ACCEPTANCE_HEAD_SHA:commit,ACCEPTANCE_BASE_SHA:source.base,EXPECTED_RECEIPT_SHA:receiptSha,EXPECTED_PRODUCER_ATTEMPT:attempt,RUNNER_TEMP:path.join(root,'inputs')}});
    };
    const valid=execute();assert.equal(valid.status,0,valid.stderr);
    const result=JSON.parse(readFileSync(path.join(root,'godot_native/exports/verification/web-coverage.json'),'utf8'));assert.equal(result.artifacts.length,13);assert.equal(result.covered.length,17);
    const world=`godot-web-world-touch-390-${run}-${attempt}`,phone=`godot-web-phone-retina-touch-390-c2-tiyi-${run}-${attempt}`,baseline=`godot-web-baseline-standard-${run}-${attempt}`,streaming=`godot-web-streaming-${run}-${attempt}`;
    const report=d=>d[world]['web_mobile_world/web-acceptance.json'];
    const retried=`godot-web-world-touch-390-${run}-2`;
    const retryMutation=d=>{
      d[retried]=structuredClone(d[world]);
      d[retried]['verified-inputs.json'].consumerAttempt='2';
      d[retried]['web_mobile_world/ci-mobile-world-receipt.json'].inputBundle.consumerAttempt='2';
    };
    const retry=execute(retryMutation,'2');assert.equal(retry.status,0,retry.stderr);
    assert.notEqual(execute(d=>{retryMutation(d);d[retried]['web_mobile_world/web-acceptance.json'].passed=false;},'2').status,0,'must not fall back to old success behind a new failed report');
    assert.notEqual(execute(retryMutation,'1').status,0,'future attempt must not be accepted');

    for(const [reason,mutate]of[
      ['missing artifact',d=>delete d[world]],['unknown artifact',d=>d.extra=d[world]],['duplicate attempt alias',d=>d[`godot-web-world-touch-390-${run}-01`]=d[world]],['missing receipt',d=>delete d[world]['web_mobile_world/ci-mobile-world-receipt.json']],
      ['wrong bundle digest',d=>d[world]['verified-inputs.json'].receiptSha='f'.repeat(64)],['stale consumer attempt',d=>d[world]['verified-inputs.json'].consumerAttempt='2'],['wrong producer attempt',d=>d[world]['verified-inputs.json'].producerAttempt='2'],['different base',d=>d[world]['verified-inputs.json'].source.base='a'.repeat(40)],['unverified bundle',d=>d[world]['verified-inputs.json'].verified=false],
      ['failed report',d=>report(d).passed=false],['unknown source',d=>report(d).exportManifest.sourceCommit='a'.repeat(40)],['unknown runner',d=>report(d).runnerSha256='b'.repeat(64)],['wrong scenario',d=>report(d).scenarios='all'],['missing case',d=>report(d).cases=[]],['duplicate case',d=>report(d).cases.push(report(d).cases[0])],['failed case',d=>report(d).cases[0].passed=false],['wrong DPR',d=>report(d).cases[0].dpr=3],['no renderer',d=>report(d).cases[0].renderer.webgl2=false],['failed assertion',d=>report(d).checks[0].ok=false],['missing assertions',d=>report(d).checks=[]],['runtime error',d=>report(d).errors.push('failure')],
      ['phone wrong runner',d=>d[phone]['web_phone_recovery/web-acceptance.json'].phoneRecoveryRunnerSha256='a'.repeat(64)],['phone wrong shard contract',d=>d[phone]['web_phone_recovery/web-acceptance.json'].phoneShardRunnerSha256='a'.repeat(64)],['phone missing gate',d=>d[phone]['web_phone_recovery/web-acceptance.json'].cases[0].phoneRecovery.coverage.pop()],['phone duplicate group',d=>d[phone]['web_phone_recovery/web-acceptance.json'].cases[0].phoneRecovery.group='charging'],['phone false completion',d=>d[phone]['web_phone_recovery/web-acceptance.json'].cases[0].phoneRecovery.completed=false],['phone missing inputs',d=>d[phone]['web_phone_recovery/web-acceptance.json'].cases[0].phoneRecovery.inputs=[]],
      ['baseline missing case receipt',d=>d[baseline]['web_ci/ci-baseline-receipt.json'].cases.pop()],['streaming missing gate receipt',d=>d[streaming]['web_streaming/ci-streaming-receipt.json'].verified.pop()]
    ]){const result=execute(mutate);assert.notEqual(result.status,0,`${reason} unexpectedly accepted`);}
  }finally{rmSync(root,{recursive:true,force:true});}
});
