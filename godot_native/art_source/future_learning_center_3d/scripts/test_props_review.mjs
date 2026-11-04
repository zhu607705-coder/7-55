/** Node resource/loader tests; not browser rendering acceptance. */
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import * as THREE from '../web/vendor/three/three.module.js';
import {REVIEW_ASSETS,reviewLevel} from '../web/props_review_catalog.js';
import {createReviewStore} from '../web/props_review_store.js';
const root=fileURLToPath(new URL('..',import.meta.url)),web=path.join(root,'web');let checks=0;
function check(value,message){assert.ok(value,message);checks++;}
const assets=REVIEW_ASSETS.slice(0,2),manifest={source:{size:[1,1,1]},levels:[0,1,2]};
function mesh(){return new THREE.Mesh(new THREE.BoxGeometry(),new THREE.MeshStandardMaterial());}
let calls=[],releases=0;
const store=createReviewStore({assets,loadManifest:async()=>manifest,loadScene:async url=>{calls.push(url);if(url.endsWith('lod1.draco.glb'))throw Error('decoder failure');const m=mesh();m.geometry.addEventListener('dispose',()=>releases++);m.material.addEventListener('dispose',()=>releases++);return m;}});
const [a,b]=await Promise.all([store.load(assets[0].id),store.load(assets[0].id)]);
check(a===b,'concurrent requests deduplicate');check(calls.length===4,'three levels with one plain fallback');check(a.formats[1]==='plain 回退','fallback visible');
const one=a.create(),two=a.create();
check(one[0]!==two[0],'independent transforms');check(one[0].geometry===two[0].geometry,'real Three.js geometry shared');check(one[0].material===two[0].material,'real Three.js material shared');one[0].position.x=7;check(two[0].position.x===0,'transform isolation');
store.dispose();store.dispose();check(releases===6,'resources disposed exactly once');assert.throws(()=>a.create(),/disposed/);checks++;await assert.rejects(store.load(assets[0].id),/disposed/);checks++;
let fail=true,partialDisposed=0;
const retryStore=createReviewStore({assets,loadManifest:async()=>manifest,loadScene:async url=>{if(fail&&url.includes(assets[0].id)&&/lod1\./.test(url))throw Error('broken asset');const m=mesh();m.geometry.addEventListener('dispose',()=>partialDisposed++);return m;}});
await assert.rejects(retryStore.load(assets[0].id),/broken asset/);checks++;check(partialDisposed===1,'partial failed asset cleaned');check((await retryStore.load(assets[1].id)).create().length===3,'other asset unaffected');fail=false;check((await retryStore.load(assets[0].id)).create().length===3,'failed cache evicted for retry');retryStore.dispose();
let resolvePending,pendingDisposed=0;
const pending=createReviewStore({assets,loadManifest:async()=>manifest,loadScene:()=>new Promise(resolve=>{resolvePending=resolve;})});const request=pending.load(assets[0].id);await Promise.resolve();pending.dispose();const late=mesh();late.geometry.addEventListener('dispose',()=>pendingDisposed++);resolvePending(late);await assert.rejects(request,/disposed/);checks++;check(pendingDisposed===1,'late load disposed after shutdown');
let manifestAttempts=0;
const badManifest=createReviewStore({assets,loadManifest:async()=>{manifestAttempts++;return {};},loadScene:async()=>{throw Error('must not load geometry');}});
await assert.rejects(badManifest.load(assets[0].id),/Invalid review manifest/);checks++;
await assert.rejects(badManifest.load(assets[0].id),/Invalid review manifest/);checks++;check(manifestAttempts===2,'invalid manifest retry');
await assert.rejects(badManifest.load('unknown'),/Unknown review asset/);checks++;badManifest.dispose();
check(reviewLevel(150)===0&&reviewLevel(149)===1&&reviewLevel(55)===1&&reviewLevel(54)===2,'LOD thresholds');check(REVIEW_ASSETS.length===6,'six existing samples');
for(const asset of REVIEW_ASSETS){check(fs.existsSync(path.resolve(web,asset.doc)),asset.id+' provenance exists');const base=path.resolve(web,asset.base),m=JSON.parse(fs.readFileSync(path.join(base,'manifest.json')));check(m.levels.length===3,asset.id+' three LOD manifest');for(let i=0;i<3;i++){for(const suffix of ['.glb','.draco.glb'])check(fs.existsSync(path.join(base,`lod${i}${suffix}`)),asset.id+' fallback file');}check(asset.source.length>10&&asset.note.length>10,asset.id+' explicit limitations');}
const visited=new Set();function visit(file){file=path.resolve(file);if(visited.has(file))return;visited.add(file);check(fs.existsSync(file),'module '+path.relative(web,file));const source=fs.readFileSync(file,'utf8').replace(/\/\*[\s\S]*?\*\//g,'').replace(/^\s*\/\/.*$/gm,'');for(const match of source.matchAll(/^\s*(?:import|export)\s+(?:[^;]*?\s+from\s*)?['"]([^'"]+)['"]/gm)){const spec=match[1];let target;if(spec==='three')target=path.join(web,'vendor/three/three.module.js');else if(spec.startsWith('three/addons/'))target=path.join(web,'vendor/three/addons',spec.slice(13));else if(spec.startsWith('.'))target=path.resolve(path.dirname(file),spec);else throw Error('Unbundled import '+spec);visit(target);}}
visit(path.join(web,'props_review.js'));
for(const name of ['draco_decoder.js','draco_decoder.wasm','draco_wasm_wrapper.js'])check(fs.existsSync(path.join(web,'vendor/three/draco',name)),'local decoder '+name);
const html=fs.readFileSync(path.join(web,'props_review.html'),'utf8'),js=fs.readFileSync(path.join(web,'props_review.js'),'utf8');
for(const match of html.matchAll(/(?:src|href)="([^"#]+)"/g)){if(match[1].startsWith('data:'))continue;check(fs.existsSync(path.resolve(web,match[1])),'HTML resource '+match[1]);}
check(!/https?:\/\//.test(html+js),'no CDN or external environment request');check(html.includes('尚未通过真实浏览器'),'browser boundary explicit');
console.log(JSON.stringify({passed:checks,scope:'Node loader lifetime/fallback/retry, actual Three clone sharing, all six source paths and local ES dependency graph. Not browser/GPU acceptance.',modules:visited.size},null,2));
