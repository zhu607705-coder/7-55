import fs from 'node:fs';
import path from 'node:path';
import {execFileSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
import {createValidationCatalog, PREPARATION_IDS} from './native_validation_plan.mjs';
import {createShardPlan, stageDescriptor} from './native_validation_shards.mjs';
import {digest, fileDigest, stageIdentity} from './native_validation_identity.mjs';
const equal = (a,b) => JSON.stringify(a) === JSON.stringify(b);
const requireValue = (condition,message) => {if (!condition) throw Error(message);};
const sha = value => typeof value === 'string' && /^[a-f0-9]{64}$/.test(value);
const positive = value => /^[1-9]\d*$/.test(String(value)) && Number.isSafeInteger(Number(value));
const hashBytes = bytes => createHash('sha256').update(bytes).digest('hex');
const errors = /(?:^|\n)ERROR:|SCRIPT ERROR:|Parse Error:|Failed to load script|TEST FAILED|ASSERTION FAILED/;
function successful(row) {
 return row.result === 'pass' && row.failed === false && row.status === 0 && row.error === null && row.signal === null
  && row.reused === false && typeof row.output === 'string' && !errors.test(row.output)
  && Number.isFinite(Date.parse(row.startedAt)) && Date.parse(row.finishedAt) >= Date.parse(row.startedAt)
  && Number.isFinite(row.durationMs) && row.durationMs >= 0;
}
function checkIdentity(identity) {
 requireValue(identity && sha(identity.sha256) && sha(identity.input?.sha256), 'Missing exact input identity');
 const {sha256,...body} = identity;
 requireValue(digest(body) === sha256, 'Input identity digest mismatch');
}
function checkRows(rows,catalog) {requireValue(Array.isArray(rows) && equal(rows.map(r=>r.id),catalog.map(s=>s.id)), 'Report catalog order/coverage differs');}
function summary(rows) {return Object.fromEntries(['not-run','pass','prepared','failed','blocked','deduplicated'].map(status=>[status,rows.filter(r=>r.result===status).length]));}
/** No individual job or partial report can declare the full suite passed. */
export function aggregateNative({root,catalog,preparationRows,preparationMeta,receipt,receiptSha,fragments,expected,statuses}) {
 requireValue(equal(Object.keys(statuses).sort(),['contracts','graphics','prepare','shards']) && Object.values(statuses).every(s=>s==='success'), 'All native jobs must succeed, including contracts and graphics/export');
 const plan = createShardPlan(catalog,root);
 requireValue(sha(receiptSha) && receipt.schema === '755-native-prepared-bundle-v2', 'Missing trusted preparation receipt');
 requireValue(receipt.source.checkedOutCommit === expected.commit && receipt.source.tree === expected.tree && receipt.source.run === expected.run
  && receipt.producerAttempt === expected.producerAttempt && positive(expected.attempt) && Number(expected.producerAttempt)<=Number(expected.attempt), 'Preparation source/run/attempt mismatch');
 checkRows(preparationRows,catalog); checkIdentity(preparationMeta.identity);
 requireValue(preparationMeta.gitHead === expected.commit && preparationMeta.gitTree === expected.tree && preparationMeta.completed === true
  && preparationMeta.inputChangedDuringRun === false && preparationMeta.resumable === true && preparationMeta.partial === true
  && preparationMeta.fullSuitePassed === false && preparationMeta.profile === 'prepare' && preparationMeta.effectiveProfile === 'prepare'
  && preparationMeta.identity.sha256 === receipt.preparation.identitySha256 && preparationMeta.identity.input.sha256 === receipt.preparation.inputSha256, 'Preparation did not complete exact fresh coverage');
 requireValue(equal(preparationRows.filter(r=>r.selected).map(r=>r.id),PREPARATION_IDS), 'Preparation selection differs');
 for (const row of preparationRows) requireValue(row.selected ? successful(row) : row.result === 'not-run', `Invalid preparation result: ${row.id}`);
 requireValue(equal(preparationMeta.summary,summary(preparationRows)), 'Preparation summary differs');
 const candidates = new Map();
 for (const fragment of fragments) {
  const m = fragment.meta, s = m.shard;
  requireValue(s && Number.isInteger(s.index) && s.index >= 0 && s.index < plan.count && s.count === plan.count && s.planSha256 === plan.sha256, 'Unknown shard or partition');
  requireValue(s.run === expected.run && s.producerAttempt === expected.producerAttempt && s.receiptSha === receiptSha
   && positive(s.attempt) && Number(s.attempt)<=Number(expected.attempt), 'Shard source receipt/run/attempt mismatch');
  const key = `${s.index}/${s.attempt}`;
  requireValue(!candidates.has(key), 'Duplicate shard attempt report'); candidates.set(key,fragment);
 }
 const selected = plan.shards.map(s => [...candidates.values()].filter(f=>f.meta.shard.index===s.index).sort((a,b)=>Number(b.meta.shard.attempt)-Number(a.meta.shard.attempt))[0]);
 requireValue(selected.every(Boolean), 'Missing native shard report');
 const merged = new Map(preparationRows.filter(r=>r.selected).map(r=>[r.id,{...r,evidenceOwner:'prepare'}]));
 for (const fragment of selected) {
  const {rows,meta:m} = fragment, s = m.shard, owned = plan.shards[s.index].ids;
  checkRows(rows,catalog); checkIdentity(m.identity);
  requireValue(m.gitHead===expected.commit && m.gitTree===expected.tree && m.completed===true && m.inputChangedDuringRun===false
   && m.resumable===true && m.partial===true && m.fullSuitePassed===false && m.profile==='shard' && m.effectiveProfile==='shard'
   && m.jobs===2 && m.selected===owned.length && m.total===catalog.length, `Incomplete/failed shard ${s.index}`);
  requireValue(m.identity.input.sha256===receipt.preparation.inputSha256 && s.preparationInputSha256===receipt.preparation.inputSha256
   && sha(m.preparedFixtureSha256) && m.preparedFixtureSha256===receipt.preparation.fixtureSha256
   && equal(s.ownedIds,owned) && equal(rows.filter(r=>r.selected).map(r=>r.id),owned), 'Shard input identity or exact ownership differs');
  requireValue(equal(m.summary,summary(rows)), 'Shard summary differs');
  for (const row of rows) {
   if (!row.selected) {
    requireValue(PREPARATION_IDS.includes(row.id)
     ? (row.id==='Native save isolation' ? successful(row) : row.result==='prepared' && row.preparedReceiptSha===receiptSha)
     : row.result==='not-run', `Unexpected unowned execution/result: ${row.id}`);
    continue;
   }
   const stage = catalog.find(x=>x.id===row.id);
   if (row.result==='deduplicated') {
    const owner = rows.find(r=>r.id==='test_buct_haidian.gd');
    requireValue(row.id==='test_buct_rongmao.gd' && row.equivalentTo===owner?.id && successful(owner)
     && ['test_buct_haidian.gd','test_buct_rongmao.gd'].every(id=>fileDigest(path.join(root,'godot_native/tests',id))==='7755f05f3ff527e4072523a90b70452ada0aa64b69b652be09d7df83f03a6510'), 'Unproven evidence deduplication');
   } else {
    requireValue(successful(row), `Native stage failed or was not freshly run: ${row.id}`);
    requireValue(equal(stageDescriptor(row,path.dirname(m.project)),stageDescriptor(stage,root)), `Stage command/input contract differs: ${row.id}`);
    requireValue(row.identity===stageIdentity(m.identity,row,m.preparedFixtureSha256), `Stage fixture/input identity differs: ${row.id}`);
   }
   requireValue(!merged.has(row.id), 'Duplicate executed stage owner');
   merged.set(row.id,{...row,evidenceOwner:`shard-${s.index}`,consumerAttempt:s.attempt});
  }
 }
 requireValue(merged.size===catalog.length, 'Aggregate coverage is incomplete');
 const rows = catalog.map(s=>merged.get(s.id));
 return {rows,meta:{schema:3,mode:'sharded-full',completed:true,fullSuitePassed:true,partial:false,inputChangedDuringRun:false,
  gitHead:expected.commit,gitTree:expected.tree,run:expected.run,attempt:expected.attempt,producerAttempt:expected.producerAttempt,
  preparationReceiptSha:receiptSha,planSha256:plan.sha256,summary:summary(rows),total:rows.length,
  startedAt:preparationMeta.startedAt,finishedAt:new Date().toISOString(),
  fragments:selected.map(f=>({index:f.meta.shard.index,attempt:f.meta.shard.attempt,identity:f.meta.identity,startedAt:f.meta.startedAt,finishedAt:f.meta.finishedAt})),
  scope:'Complete exact-source native coverage plus required graphics/export job; not an individual shard or browser acceptance.'}};
}
function main() {
 const options = {}, args = process.argv.slice(2), allowed=['preparation-dir','reports-dir','receipt-sha','producer-attempt','output','prepare-status','shards-status','graphics-status','contracts-status'];
 requireValue(args.length===allowed.length*2,'All aggregate arguments required');
 for(let i=0;i<args.length;i+=2){const key=args[i].replace(/^--/,'');requireValue(allowed.includes(key)&&!options[key]&&args[i+1],`Invalid aggregate argument ${args[i]}`);options[key]=args[i+1];}
 const root=process.cwd(), project=path.join(root,'godot_native'), read=file=>fs.readFileSync(file), json=file=>JSON.parse(read(file));
 const receiptBytes=read(path.join(options['preparation-dir'],'bundle-receipt.json'));
 requireValue(hashBytes(receiptBytes)===options['receipt-sha'],'Untrusted aggregate preparation receipt');
 const receipt=JSON.parse(receiptBytes), reportBytes=read(path.join(options['preparation-dir'],'native-prepare.json')), metaBytes=read(path.join(options['preparation-dir'],'native-prepare.json.meta.json'));
 requireValue(hashBytes(reportBytes)===receipt.preparation.reportSha256&&hashBytes(metaBytes)===receipt.preparation.metaSha256,'Preparation reports differ from sealed receipt');
 const fragments=[];
 for(const entry of fs.readdirSync(options['reports-dir'],{withFileTypes:true})){
  requireValue(entry.isDirectory()&&!entry.isSymbolicLink(),'Unexpected shard report entry');
  const dir=path.join(options['reports-dir'],entry.name);
  fragments.push({rows:json(path.join(dir,'native-test-report.json')),meta:json(path.join(dir,'native-test-report.json.meta.json'))});
 }
 const expected={commit:process.env.GITHUB_SHA,tree:execFileSync('git',['rev-parse','HEAD^{tree}'],{encoding:'utf8'}).trim(),run:process.env.GITHUB_RUN_ID,attempt:process.env.GITHUB_RUN_ATTEMPT,producerAttempt:options['producer-attempt']};
 requireValue(execFileSync('git',['rev-parse','HEAD'],{encoding:'utf8'}).trim()===expected.commit,'Aggregate checkout changed');
 const result=aggregateNative({root,catalog:createValidationCatalog(project),preparationRows:JSON.parse(reportBytes),preparationMeta:JSON.parse(metaBytes),receipt,receiptSha:options['receipt-sha'],fragments,expected,
  statuses:{prepare:options['prepare-status'],shards:options['shards-status'],graphics:options['graphics-status'],contracts:options['contracts-status']}});
 fs.mkdirSync(path.dirname(path.resolve(options.output)),{recursive:true});
 fs.writeFileSync(options.output,JSON.stringify(result.rows,null,2)+'\n');fs.writeFileSync(`${options.output}.meta.json`,JSON.stringify(result.meta,null,2)+'\n');
 console.log(`FULL sharded validation: ${JSON.stringify(result.meta.summary)}`);
}
if(process.argv[1]&&import.meta.url===pathToFileURL(path.resolve(process.argv[1])).href)main();
