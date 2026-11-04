import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import {readFileSync} from 'node:fs';
import {webcrypto} from 'node:crypto';
const source=readFileSync(new URL('../../godot_native/web/cloud-saves.js',import.meta.url),'utf8');
const member='11111111-1111-4111-8111-111111111111';
function transport(fetch) {
  const window={crypto:webcrypto,addEventListener(){}},document={addEventListener(){}};
  vm.runInNewContext(source,{window,document,fetch,AbortController,setTimeout,clearTimeout,URL,Uint8Array,ArrayBuffer,JSON,Date,
    btoa:value=>Buffer.from(value,'binary').toString('base64'),atob:value=>Buffer.from(value,'base64').toString('binary')});
  return {api:window.__GODOT_755_CLOUD__,call:(op,args)=>new Promise(resolve=>window.__GODOT_755_CLOUD__.request(op,JSON.stringify(args),raw=>resolve(JSON.parse(raw))))};
}
test('cloud transport pins every data request to the current member and same-origin cookie',async()=>{
  const calls=[];
  const client=transport(async(url,options)=>{calls.push({url,options});return {ok:true,status:200,json:async()=>({revision:1})};});
  const result=await client.call('save',{owner:member,input:{expectedMemberId:member,expectedRevision:0,operationId:member,bundle:{}}});
  assert.equal(result.ok,true);assert.equal(calls[0].url,'/api/v1/me/game-save');
  assert.equal(calls[0].options.credentials,'same-origin');
  assert.equal(calls[0].options.headers['X-755-Member'],member);
  assert.equal(calls[0].options.headers['X-Requested-With'],'755-platform');
  assert.equal(calls[0].options.cache,'no-store');
  await client.call('assetExists',{owner:member,sha:'a'.repeat(64)});
  assert.equal(calls[1].options.method,'HEAD');
  assert.equal(calls[1].options.body,undefined);
});
test('fixed transport rejects injected paths and never accepts an arbitrary destination or owner',async()=>{
  let calls=0;const client=transport(async()=>{calls++;throw Error('must not fetch');});
  for(const [op,args] of [['snapshot',{owner:member,id:'../../other'}],['asset',{owner:member,sha:'https://evil.test'}],['head',{owner:'../../other'}],['https://evil.test',{owner:member}]])
    assert.equal((await client.call(op,args)).ok,false);
  assert.equal(calls,0);
});
test('failed upload and authorization stay explicit; non-JSON response keeps its HTTP status',async()=>{
  const client=transport(async()=>({ok:false,status:401,json:async()=>({error:{message:'请重新登录'}})}));
  const result=await client.call('head',{owner:member});
  assert.equal(result.status,401);assert.equal(result.error,'请重新登录');
  const missing=transport(async()=>({ok:false,status:404,json:async()=>{throw Error('HTML');}}));
  assert.equal((await missing.call('session',{})).status,404);
  const offline=transport(async()=>{throw Error('offline');});
  assert.equal((await offline.call('head',{owner:member})).ok,false);
});
test('local persistence cannot report success without an actual backing database and matching file bytes',async()=>{
  const client=transport(async()=>{throw Error('not an HTTP operation');});
  const result=await client.call('persist',{profile:member,files:[{path:'/userfs/profiles/'+member+'/save.json',digest:'0'.repeat(64)}]});
  assert.equal(result.ok,false);
});
