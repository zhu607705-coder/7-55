import test from 'node:test';
import assert from 'node:assert/strict';
import {randomUUID,createHash} from 'node:crypto';
import {readFile} from 'node:fs/promises';
import {fixture,request,expectStatus} from '../helpers/fixture.mjs';

const base='/api/v1/me/game-save';
const bundle=(chapter=1,assets=[])=>({bundleVersion:1,
  stateText:JSON.stringify({format:'7-55-godot-native',version:1,sourceVersion:36,state:{native:{chapter},
    qizhenLake:{journal:assets.length?{mainPhoto:{nativeImagePath:'user://qizhen_journal/photo.png',nativeImageSha256:assets[0]}}:{}}}}),
  stores:{posts:'[]',questPostOverrides:'{}'},assets,summary:{chapter,task:'当前任务 '+chapter}});
const write=(actor,revision,data=bundle())=>({expectedMemberId:actor.user.id,expectedRevision:revision,operationId:randomUUID(),bundle:data});
const head=async(app,actor)=>(expectStatus(await request(app,'GET',base,undefined,actor.cookie),200)).json();

test('current and legacy native envelopes round-trip without rewriting game-owned fields',async t=>{
  const {app,login}=await fixture(t),actor=await login('save-native-versions');
  for (const [revision,sourceVersion] of [35,36].entries()) {
    const data=bundle(),envelope=JSON.parse(data.stateText);
    envelope.sourceVersion=sourceVersion;
    envelope.state.native.flc_rooms={version:1,rooms:{example:{earned:true}},location:{room:'example'}};
    data.stateText=JSON.stringify(envelope);
    const saved=expectStatus(await request(app,'PUT',base,write(actor,revision,data),actor.cookie),200).json();
    assert.equal(saved.current.sourceVersion,sourceVersion);
    const restored=expectStatus(await request(app,'GET',base+'/snapshots/'+saved.current.id,undefined,actor.cookie),200).json();
    assert.deepEqual(restored.bundle,data);
  }
});

test('cloud save ownership, operator isolation, source protection and guest rejection',async t=>{
  const {app,login}=await fixture(t),a=await login('save-a'),b=await login('save-b'),operator=await login('operator');
  expectStatus(await request(app,'GET',base),401);
  const first=expectStatus(await request(app,'PUT',base,write(a,0),a.cookie),200).json();
  assert.equal(first.memberId,a.user.id); assert.equal(first.revision,1);
  for(const other of [b,operator]) {
    assert.equal((await head(app,other)).current,null);
    expectStatus(await request(app,'GET',base+'/snapshots/'+first.current.id,undefined,other.cookie),404);
    expectStatus(await request(app,'PUT',base,write(a,0),other.cookie),409);
    expectStatus(await request(app,'POST',base+'/restore',{expectedMemberId:other.user.id,expectedRevision:0,operationId:randomUUID(),snapshotId:first.current.id},other.cookie),404);
  }
  expectStatus(await request(app,'PUT',base,write(a,1),a.cookie,{headers:{origin:'https://evil.test'}}),403);
  expectStatus(await request(app,'GET',base,undefined,b.cookie,{headers:{'x-755-member':a.user.id}}),409);
  const huge={...write(a,1),extra:'x'.repeat(70*1024)};
  expectStatus(await request(app,'POST','/api/v1/ideas',huge,a.cookie),413);
});

test('revision races, exact retries, restart backup and restore are atomic and bounded',async t=>{
  const {app,pool,login}=await fixture(t),a=await login('save-revisions');
  const one=write(a,0),first=expectStatus(await request(app,'PUT',base,one,a.cookie),200).json();
  assert.deepEqual(expectStatus(await request(app,'PUT',base,one,a.cookie),200).json(),first);
  expectStatus(await request(app,'PUT',base,{...one,bundle:bundle(2)},a.cookie),409);
  const raced=await Promise.all([2,3].map(chapter=>request(app,'PUT',base,write(a,1,bundle(chapter)),a.cookie)));
  assert.deepEqual(raced.map(r=>r.statusCode).sort(),[200,409]);
  const second=await head(app,a);
  expectStatus(await request(app,'PUT',base,one,a.cookie),409);
  assert.equal((await head(app,a)).revision,second.revision);
  assert.equal(second.previous.id,first.current.id);
  const restarted=expectStatus(await request(app,'POST',base+'/restart',write(a,2,bundle(1)),a.cookie),200).json();
  assert.equal(restarted.beforeRestart.id,second.current.id); assert.equal(restarted.revision,3);
  const after=expectStatus(await request(app,'PUT',base,write(a,3,bundle(4)),a.cookie),200).json();
  assert.equal(after.beforeRestart.id,second.current.id);
  const restored=expectStatus(await request(app,'POST',base+'/restore',{expectedMemberId:a.user.id,expectedRevision:4,operationId:randomUUID(),snapshotId:after.beforeRestart.id},a.cookie),200).json();
  assert.equal(restored.current.id,second.current.id); assert.equal(restored.previous.id,after.current.id);
  const count=(await pool.query('SELECT count(*)::int n FROM game_save_snapshots')).rows[0].n;
  assert.ok(count<=3);
  expectStatus(await request(app,'PUT',base,write(a,4),a.cookie),409);
});

test('private PNG attachments are deduplicated, complete and fingerprint checked',async t=>{
  const {app,pool,login}=await fixture(t),a=await login('save-pictures'),b=await login('save-picture-other');
  const png=await readFile(new URL('../../apps/web/public/art/campus-night.png',import.meta.url));
  const sha=createHash('sha256').update(png).digest('hex');
  const data=bundle(3,[sha]);
  expectStatus(await request(app,'PUT',base,write(a,0,data),a.cookie),400);
  const upload=()=>request(app,'PUT',base+'/assets/'+sha,png,a.cookie,{headers:{'content-type':'application/octet-stream','x-755-member':a.user.id}});
  expectStatus(await upload(),200); expectStatus(await upload(),200);
  assert.equal((await pool.query('SELECT count(*)::int n FROM game_save_assets')).rows[0].n,1);
  expectStatus(await request(app,'PUT',base+'/assets/'+'0'.repeat(64),png,a.cookie,{headers:{'content-type':'application/octet-stream'}}),400);
  assert.equal(expectStatus(await request(app,'HEAD',base+'/assets/'+sha,undefined,a.cookie),200).body,'');
  expectStatus(await request(app,'HEAD',base+'/assets/'+sha,undefined,b.cookie),404);
  const saved=expectStatus(await request(app,'PUT',base,write(a,0,data),a.cookie),200).json();
  const download=expectStatus(await request(app,'GET',base+'/assets/'+sha,undefined,a.cookie),200);
  assert.ok(download.rawPayload.equals(png));
  expectStatus(await request(app,'GET',base+'/assets/'+sha,undefined,b.cookie),404);
  expectStatus(await request(app,'PUT',base+'/assets/'+sha,png,b.cookie,{headers:{'content-type':'application/octet-stream','x-755-member':a.user.id}}),409);
  const snapshot=expectStatus(await request(app,'GET',base+'/snapshots/'+saved.current.id,undefined,a.cookie),200).json();
  assert.deepEqual(snapshot.bundle,data);
  expectStatus(await request(app,'PUT',base,write(a,1,{...bundle(),assets:[sha]}),a.cookie),400);
});

test('expired sessions, invalid documents, future formats and failed quota writes preserve old save',async t=>{
  const {app,pool,login}=await fixture(t),a=await login('save-errors');
  const original=expectStatus(await request(app,'PUT',base,write(a,0),a.cookie),200).json();
  for(const changed of [{bundleVersion:2},{stateText:'bad json'},{stores:{posts:'{}',questPostOverrides:'{}'}},
    {stateText:JSON.stringify({format:'7-55-godot-native',version:1,sourceVersion:999,state:{native:{chapter:1}}})}])
    expectStatus(await request(app,'PUT',base,write(a,1,{...bundle(),...changed}),a.cookie),400);
  await pool.query('UPDATE game_save_snapshots SET bytes=268435456 WHERE id=$1',[original.current.id]);
  expectStatus(await request(app,'PUT',base,write(a,1,bundle(2)),a.cookie),409);
  assert.equal((await head(app,a)).current.id,original.current.id);
  await pool.query("UPDATE sessions SET expires_at=now()-interval '1 second'");
  expectStatus(await request(app,'PUT',base,write(a,1),a.cookie),401);
});

test('database faults roll back; old referenced photos survive and abandoned assets wait 24h',async t=>{
  const {app,pool,login}=await fixture(t),a=await login('save-transaction-fault');
  const original=expectStatus(await request(app,'PUT',base,write(a,0),a.cookie),200).json();
  await pool.query("CREATE FUNCTION reject_test_save() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN RAISE EXCEPTION 'isolated database fault'; END $$");
  await pool.query('CREATE TRIGGER reject_test_save BEFORE UPDATE ON game_save_heads FOR EACH ROW EXECUTE FUNCTION reject_test_save()');
  const retry=write(a,1,bundle(2));
  expectStatus(await request(app,'PUT',base,retry,a.cookie),500);
  assert.equal((await head(app,a)).current.id,original.current.id);
  assert.equal((await pool.query('SELECT count(*)::int n FROM game_save_snapshots')).rows[0].n,1);
  await pool.query('DROP TRIGGER reject_test_save ON game_save_heads');
  expectStatus(await request(app,'PUT',base,retry,a.cookie),200);
  const png=await readFile(new URL('../../apps/web/public/art/campus-night.png',import.meta.url));
  const sha=createHash('sha256').update(png).digest('hex');
  expectStatus(await request(app,'PUT',base+'/assets/'+sha,png,a.cookie,{headers:{'content-type':'application/octet-stream'}}),200);
  expectStatus(await request(app,'PUT',base,write(a,2,bundle(3,[sha])),a.cookie),200);
  await pool.query("UPDATE game_save_assets SET created_at=now()-interval '25 hours'");
  expectStatus(await request(app,'PUT',base,write(a,3,bundle(4)),a.cookie),200);
  expectStatus(await request(app,'GET',base+'/assets/'+sha,undefined,a.cookie),200);
  await pool.query('UPDATE game_save_assets SET created_at=now()');
  expectStatus(await request(app,'PUT',base,write(a,4,bundle(5)),a.cookie),200);
  expectStatus(await request(app,'GET',base+'/assets/'+sha,undefined,a.cookie),200);
  await pool.query("UPDATE game_save_assets SET created_at=now()-interval '25 hours'");
  expectStatus(await request(app,'PUT',base,write(a,5,bundle(6)),a.cookie),200);
  expectStatus(await request(app,'GET',base+'/assets/'+sha,undefined,a.cookie),404);
});
