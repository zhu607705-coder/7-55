import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';

const source = fs.readFileSync(new URL('../web/scene_orientation.js',import.meta.url),'utf8');
let checks = 0;
function check(value, label) { assert.ok(value,label); checks++; }
const settle = () => new Promise(setImmediate);
function fixture({coarse=true,active=true}={}) {
  const calls={request:0,exit:0,lock:0,unlock:0};
  const doc={documentElement:{},fullscreenElement:null};
  doc.documentElement.requestFullscreen=async()=>{calls.request++;doc.fullscreenElement=doc.documentElement;};
  doc.exitFullscreen=async()=>{calls.exit++;doc.fullscreenElement=null;};
  const orientation={lock:async value=>{calls.lock++;check(value==='landscape','Only maps request a landscape system lock');},
    unlock:()=>{calls.unlock++;}};
  const window={document:doc,navigator:{userActivation:{isActive:active}},screen:{orientation},matchMedia:()=>({matches:coarse})};
  vm.runInNewContext(source,{window});
  return {doc,calls,orientation,window,api:window.install755SceneOrientation()};
}

let f=fixture();
f.api.update({portraitRequired:true});
check(f.api.snapshot().portraitRequired&&!f.api.snapshot().visible&&f.calls.request===0,'Phone pages have no prompt or fullscreen request');
f.api.update({landscapePreferred:true});
await settle();
check(f.calls.request===1&&f.calls.lock===1&&!f.api.snapshot().visible,'An already activated map requests fullscreen without a prompt');
f.api.update({landscapePreferred:true});
check(f.calls.request===1,'A repeated snapshot does not request fullscreen again');
f.api.update({portraitRequired:true});
check(f.calls.exit===1&&f.calls.unlock===1,'Phone return releases the fullscreen and orientation owned by the scene');

for (const options of [{coarse:false},{active:false}]) {
  f=fixture(options); f.api.update({landscapePreferred:true});
  check(f.calls.request===0&&!f.api.snapshot().visible,'No prompt or forced fullscreen without touch activation');
}

f=fixture();
f.doc.documentElement.requestFullscreen=async()=>{throw Error('Unavailable');};
f.api.update({landscapePreferred:true});
await settle();
check(!f.api.snapshot().visible&&!f.api.snapshot().busy&&f.calls.lock===0,'Rejected fullscreen leaves the scene usable');

f=fixture();
let finish;
f.doc.documentElement.requestFullscreen=()=>new Promise(resolve=>{finish=()=>{f.doc.fullscreenElement=f.doc.documentElement;resolve();};});
f.api.update({landscapePreferred:true});
f.api.update({portraitRequired:true});
finish();
await settle();
check(!f.doc.fullscreenElement&&f.calls.lock===0,'A late fullscreen result is released on the phone page');

f=fixture();
let finishLock;
f.orientation.lock=()=>new Promise(resolve=>{finishLock=resolve;});
f.api.update({landscapePreferred:true});
await settle();
f.api.dispose();
finishLock();
await settle();
check(f.calls.unlock===1&&f.calls.exit===1,'A late orientation lock is released when the scene exits');
check(f.window.install755SceneOrientation()!==f.api,'An exited host can be replaced cleanly');
console.log(JSON.stringify({success:true,checks,scope:'Browser fullscreen lifecycle only. Actual canvas rotation and touch input run in browser acceptance.'}));
