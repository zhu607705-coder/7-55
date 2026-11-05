// Real loopback HTTP + disposable PostgreSQL schema. No production data or Authing accounts.
import test from 'node:test';
import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import {writeFile} from 'node:fs/promises';
import {fixture,publish,origin} from '../helpers/fixture.mjs';
test('100 concurrent players: HTTP sessions, hot-post reactions, cloud saves and conflicting writes',async t=>{
 const {app,pool,login}=await fixture(t);
 const actors=[];
 for(let batch=0;batch<10;batch++) actors.push(...await Promise.all(Array.from({length:10},(_,n)=>login('load-'+(batch*10+n)))));
 const idea=await publish(app,actors[0]);
 await app.listen({host:'127.0.0.1',port:0});
 const host='http://127.0.0.1:'+app.server.address().port;
 const report={users:100,transport:'loopback HTTP',identity:'signed test provider',database:'isolated PostgreSQL schema',phases:[]};
 async function wave(name,work,allowed=[200]){
  const started=performance.now(),rows=await Promise.all(actors.map(async(actor,index)=>{
   const begin=performance.now(),response=await work(actor,index);const data=await response.json();
   assert.ok(allowed.includes(response.status),name+' '+response.status+' '+JSON.stringify(data));
   return {ms:performance.now()-begin,status:response.status};
  }));
  const times=rows.map(r=>r.ms).sort((a,b)=>a-b),elapsed=performance.now()-started;
  report.phases.push({name,requests:100,elapsedMs:Math.round(elapsed),p50Ms:Math.round(times[49]),p95Ms:Math.round(times[94]),maxMs:Math.round(times[99]),statuses:rows.reduce((m,r)=>(m[r.status]=(m[r.status]||0)+1,m),{})});
 }
 const http=(actor,path,method='GET',data)=>fetch(host+'/api/v1'+path,{method,headers:{cookie:actor.cookie,origin,'x-requested-with':'755-platform',...(data?{'content-type':'application/json'}:{})},body:data?JSON.stringify(data):undefined});
 for(let round=0;round<5;round++) await wave('browse-'+round,(a,i)=>http(a,i%2?'/session':'/ideas'));
 await wave('same-post-like',a=>http(a,'/ideas/'+idea.id+'/like','PUT',{liked:true}));
 await wave('same-post-rating',a=>http(a,'/ideas/'+idea.id+'/rating','PUT',{score:5}));
 const bundle={bundleVersion:1,stateText:JSON.stringify({format:'7-55-godot-native',version:1,sourceVersion:36,state:{native:{chapter:1}}}),stores:{posts:'[]',questPostOverrides:'{}'},assets:[],summary:{chapter:1,task:'load test'}};
 await wave('account-save',a=>http(a,'/me/game-save','PUT',{expectedMemberId:a.user.id,expectedRevision:0,operationId:randomUUID(),bundle}));
 await wave('account-read',a=>http(a,'/me/game-save'));
 const actor=actors[0];
 await wave('same-account-conflict',()=>http(actor,'/me/game-save','PUT',{expectedMemberId:actor.user.id,expectedRevision:1,operationId:randomUUID(),bundle:{...bundle,summary:{chapter:1,task:randomUUID()}}}),[200,409,429]);
 const races=report.phases.at(-1).statuses;
 assert.equal(races[200],1);
 assert.equal((await pool.query('SELECT count(*)::int n FROM idea_likes WHERE idea_id=$1',[idea.id])).rows[0].n,100);
 assert.equal((await pool.query('SELECT count(*)::int n FROM idea_ratings WHERE idea_id=$1',[idea.id])).rows[0].n,100);
 assert.equal((await pool.query('SELECT count(*)::int n FROM game_save_heads WHERE current_id IS NOT NULL')).rows[0].n,100);
 assert.equal(Number((await pool.query('SELECT revision FROM game_save_heads WHERE member_id=$1',[actor.user.id])).rows[0].revision),2);
 if(process.env.LOAD_REPORT) await writeFile(process.env.LOAD_REPORT,JSON.stringify(report,null,2)+'\n');
 console.log(JSON.stringify(report));
});
