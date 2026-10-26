import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {spawnSync} from 'node:child_process';
import {NATIVE_SHARD_COUNT} from '../tools/native_validation_shards.mjs';
const source=fs.readFileSync(new URL('../../.github/workflows/godot-native-ci.yml',import.meta.url),'utf8');
const matches=[...source.matchAll(/^  ([a-z][a-z0-9-]*):\n/gm)];
const jobs=Object.fromEntries(matches.filter(m=>source.indexOf('jobs:\n')<m.index).map((m,i,a)=>[m[1],source.slice(m.index,a[i+1]?.index??source.length)]));
test('bounded eight-shard architecture retains original final required-check identity',()=>{
 assert.deepEqual(Object.keys(jobs),['contracts','prepare','runtime','graphics','native-parse-and-tests']);
 assert.match(jobs.runtime,/fail-fast: false/);assert.equal(Number(jobs.runtime.match(/max-parallel: (\d+)/)[1]),NATIVE_SHARD_COUNT);assert.deepEqual(JSON.parse(jobs.runtime.match(/shard: (\[[^\n]+\])/)[1]),Array.from({length:NATIVE_SHARD_COUNT},(_,i)=>i));
 assert.match(jobs.runtime,/NATIVE_TEST_JOBS: '2'/);assert.doesNotMatch(source,/continue-on-error|runs-on:.*(?:large|gpu-|self-hosted)/);
 assert.match(jobs['native-parse-and-tests'],/name: native-parse-and-tests/);
});
test('producer retains exact preflight, complete media and all prepared source gates',()=>{
 for(const command of ['sync_source.mjs','build-save-normalizer.mjs','export-audio-director.mjs','prepare_import_media.mjs --install-media','validate_native.mjs --profile prepare','native_validation_bundle.mjs create'])assert.ok(jobs.prepare.includes(command),command);
 assert.match(jobs.prepare,/git diff --exit-code -- godot_native\/data\/native\/save_normalizer.json godot_native\/data\/native\/audio-director-source.json/);
 assert.doesNotMatch(jobs.prepare,/--filter|--skip-import|--resume/);
});
test('all native input consumers use isolated checkouts and verified producer receipts',()=>{
 for(const name of ['runtime','graphics']){
  const body=jobs[name];assert.match(body,/needs: \[prepare, contracts\]/);assert.match(body,/ref: \$\{\{ github.sha \}\}/);
  assert.match(body,/native_validation_bundle.mjs restore/);assert.match(body,/--receipt-sha '\$\{\{ needs.prepare.outputs.receipt_sha \}\}'/);
  assert.match(body,/--producer-attempt '\$\{\{ needs.prepare.outputs.producer_attempt \}\}'/);
  assert.match(body,/name: \$\{\{ needs.prepare.outputs.bundle_name \}\}/);
 }
 assert.ok(jobs.runtime.includes(`validate_native.mjs --shard '\${{ matrix.shard }}/${NATIVE_SHARD_COUNT}'`));
 assert.doesNotMatch(jobs.runtime,/--editor|--import|sync_source.mjs|convert_media.sh|--resume/);
});
test('unchanged GPU, north route and complete exported-package contracts remain mandatory',()=>{
 for(const text of ['test-buct-changping-wenli.sh godot_native proof','test-buct-changping-hd-region.sh godot_native headless','test-buct-changping-hd-region.sh godot_native proof','check-buct-changping-north-region.mjs','check-buct-hd-region-registry.mjs','test-buct-changping-north-region.sh headless','test-buct-changping-north-region.sh walk','test-buct-changping-north-region.sh proof','north_package_validation.py','--export-pack','verify_exported_campuses.gd','BUCT_EXPECT_SOURCELESS=1','test_buct_changping_source_texture.gd'])assert.ok(jobs.graphics.includes(text),text);
});
test('full aggregate rejects every unsuccessful, skipped, cancelled or pending dependency combination',()=>{
 const body=jobs['native-parse-and-tests'];assert.match(body,/if: \$\{\{ always\(\) \}\}/);assert.match(body,/needs: \[contracts, prepare, runtime, graphics\]/);
 const gate=[...body.matchAll(/test '\$\{\{ needs\.([a-z]+)\.result \}\}' = success/g)].map(x=>x[1]);assert.deepEqual(gate,['contracts','prepare','runtime','graphics']);
 const statuses=['success','failure','cancelled','skipped','pending'];let accepted=0;
 for(const a of statuses)for(const b of statuses)for(const c of statuses)for(const d of statuses){const results={contracts:a,prepare:b,runtime:c,graphics:d};if(gate.every(n=>results[n]==='success'))accepted++;}
 assert.equal(accepted,1);assert.match(body,/native_validation_aggregate.mjs/);
 for(const name of ['prepare','shards','graphics','contracts'])assert.ok(body.includes(`--${name}-status`));
});
test('attempt-addressed evidence supports retries without overwriting or silently merging fragments',()=>{
 assert.match(jobs.runtime,/if: always\(\)/);assert.match(jobs.runtime,/native-shard-\$\{\{ github.run_id \}\}-\$\{\{ needs.prepare.outputs.producer_attempt \}\}-\$\{\{ matrix.shard \}\}-\$\{\{ github.run_attempt \}\}/);
 assert.match(jobs.runtime,/if-no-files-found: error/);assert.match(jobs['native-parse-and-tests'],/merge-multiple: false/);
 assert.match(jobs.prepare,/include-hidden-files: true/);assert.match(jobs.prepare,/retention-days: 1/);assert.match(jobs.prepare,/compression-level: 0/);
 assert.doesNotMatch(source,/overwrite: true/);
});
test('source contracts are parallel but required and all three new protocol layers are tested',()=>{
 assert.doesNotMatch(jobs.contracts,/needs:/);assert.match(jobs.contracts,/test_native_validation_bundle.mjs/);assert.match(jobs.contracts,/test_native_validation_shards.mjs/);assert.match(jobs.contracts,/test_native_validation_workflow.mjs/);
 assert.match(source,/permissions:\n  contents: read/);assert.doesNotMatch(source,/pull_request_target|contents: write|id-token: write/);
});
test('every workflow multiline shell block parses without executing any commands',()=>{
 const blocks=[...source.matchAll(/        run: \|\n((?:          .*\n|\n)+)/g)];assert.ok(blocks.length>=10);
 for(const block of blocks){const script=block[1].split('\n').map(l=>l.startsWith('          ')?l.slice(10):l).join('\n');const r=spawnSync('bash',['-n'],{input:script,encoding:'utf8'});assert.equal(r.status,0,r.stderr);}
});

test('package artifacts retain proofs without copying runtime inputs or intermediate PCKs',()=>{
 const paths=jobs.graphics.split('      - name: Preserve GPU and package evidence')[1];
 for(const value of ['.buct-north-ci/gpu/','.buct-north-ci/*.json','.buct-north-ci/north-package-*/summary.json','.buct-north-ci/north-package-*/*/validation.log'])assert.ok(paths.includes(value));
 assert.doesNotMatch(paths,/^            \.buct-north-ci\/\s*$/m);
 assert.doesNotMatch(paths,/\*\*|\.pck/);
});
