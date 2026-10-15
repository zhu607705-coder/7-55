#!/usr/bin/env node
// STATIC/CPU ONLY. This does not parse GDScript or execute shaders/Godot/GPU.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import crypto from 'node:crypto';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const base=path.join(root,'godot_native/campuses/buct_changping');
const smooth=(a,b,x)=>{const t=Math.max(0,Math.min(1,(x-a)/(b-a)));return t*t*(3-2*t);};
const inside=(x,y,r)=>x>=r[0]&&y>=r[1]&&x<r[0]+r[2]&&y<r[1]+r[3];
const mip=(w,h,c)=>{let n=0;while(true){n+=w*h*c;if(w===1&&h===1)return n;w=Math.max(1,w>>1);h=Math.max(1,h>>1);}};
const sourceCoverage=(x,y,wActive=true,eActive=true)=>{
 const px=x-350,py=y-167;
 const west=wActive&&inside(x,y,[398,399,256,24]);
 const east=eActive&&inside(x,y,[630,399,104,24]);
 const shared=west||east,right=east&&px>=372;
 const outer=px<2||py<2||(!right&&px>=382)||(!shared&&py>=254);
 if(outer)return 0;
 let d=Math.min(px,py);if(!right)d=Math.min(d,384-px);if(!shared)d=Math.min(d,256-py);
 let c=smooth(2,12,d),lower=1;
 if(west){lower=smooth(400,410,x);if(!eActive)lower=Math.min(lower,smooth(2,12,654-x));}
 if(east){lower=west?1:smooth(632,642,x);}
 if(shared){c=Math.min(c,1-smooth(411,423,y)*(1-lower));if(right)c=Math.min(c,1-smooth(722,734,x)*(1-Math.min(lower,smooth(401,411,y))));}
 return c;
};
let checks=0;const check=(ok,label)=>{assert.ok(ok,label);checks++;};
check(mip(1536,1024,4)===8388604,'Native 4x ground mip budget');
check(mip(384,256,1)===131071,'One owner-index R8 mip budget');
check(mip(1280,122,4)+mip(520,122,4)===1169520,'Owned native 5x strip mip budget');
const baseBytes=mip(1536,1024,4)+mip(384,256,1)+mip(1280,122,4)+mip(520,122,4);
check(baseBytes===9689195&&baseBytes<12000000,'Bounded single-region layers');
check(36390042+baseBytes===46079237&&46079237<57597600,'Five-region resident layers');
const ownerMask=fs.readFileSync(path.join(base,"data/north_large_body_ownership.r8.bin"));
check(ownerMask.length===384*256&&ownerMask.every(v=>v<=2),"Actual owner-index mask size and values");
check(crypto.createHash("sha256").update(ownerMask).digest("hex")==="8586ca0dee5d621c3b73d22640237aff47b128be38e295712f6ca04ea465f75b","Exact accepted original-body fallback mask");
let coreTexels=0,excludedFallbackTexels=0;
for(const [w,e] of [[false,false],[true,false],[false,true],[true,true]]){
 for(let iy=179*4;iy<411*4;iy++)for(let ix=362*4;ix<722*4;ix++){
  const x=(ix+.5)/4,y=(iy+.5)/4;
  if(ownerMask[(Math.floor(y)-167)*384+Math.floor(x)-350]>0){excludedFallbackTexels++;continue;}
  assert.equal(sourceCoverage(x,y,w,e),1,'Every owner-zero native core texel avoids original-source coverage');coreTexels++;
 }
 checks++;
}
for(const x of [398.125,399.875,400.125,405,409.875,410,426,630,642,653.875,654,721.875,722,733.875]){
 for(const [w,e] of [[true,true],[true,false],[false,true]]){
  const c=sourceCoverage(x,410.875,w,e);
  check(x>=722 ? (c>=0&&c<=1) : c===1,'Core remains source-free; exterior right shoulder stays bounded');
 }
}
const mix=(a,b,t)=>a.map((v,i)=>v*(1-t)+b[i]*t);
const N=[.13,.47,.82],W=[.73,.11,.28],E=[.19,.87,.41],S=[.02,.04,.07];
const lowerRaw=x=>mix(W,E,smooth(630,654,x));
for(const x of [630,636,642,648,654])for(const y of [399,405,411,417,423]){
 const u=smooth(630,654,x),v=smooth(399,423,y);
 const nested=mix(N,lowerRaw(x),v);
 const weighted=N.map((n,i)=>(1-v)*n+v*(1-u)*W[i]+v*u*E[i]);
 check(nested.every((c,i)=>Math.abs(c-weighted[i])<1e-12),'One convex three-source composite at triple overlap');
}
for(const x of [398.125,399.875,400.125,405,409.875,410]){
 const target=smooth(400,410,x);
 const c=sourceCoverage(x,423-1e-6,true,true);
 check(Math.abs(c-target)<1e-12,'Bottom shoulder meets unchanged old west left collar');
 const before=mix(S,mix(N,W,smooth(399,423,423-1e-6)),c),after=mix(S,W,target);
 check(before.every((v,i)=>Math.abs(v-after[i])<1e-12),'Bottom final-color limit matches lower source/HD collar');
}
for(const y of [399.125,400.875,405,410.875,411,417,422.875]){
 const c=sourceCoverage(734-1e-6,y,true,true),target=smooth(401,411,y);
 check(Math.abs(c-target)<1e-12,'Right outer shoulder meets unchanged lower top collar');
}
check(sourceCoverage(375,422.875,true,true)===0,'Unshared x<398 bottom retains ordinary fallback');
check(coreTexels===5024256&&excludedFallbackTexels===321024,"Original body fallback is explicitly excluded from added HD claims");
const script=fs.readFileSync(path.join(base,'scripts/registered_hd_north_large.gd'),'utf8');
const shader=fs.readFileSync(path.join(base,'shaders/registered_hd_north_large.gdshader'),'utf8');
check(script.includes('_sprite(ground_texture,"RegisteredNative4xNorthernGround",region_rect.position,.25)'),'Actual native 4x sprite scale');
check(script.includes('_gpu_bytes!=estimate')&&script.includes('_precommit_safe()'),'Exact allocation and retirement precommit gates');
check(!script.includes('south.ground_texture')&&!script.includes('node.ground_texture,'),'No retained lower ground sampler borrow');
check(shader.includes('smoothstep(411.0,423.0,world_pixel.y)'),'Source shoulder starts outside core');
check(shader.includes('owner>0 && !independent')&&shader.includes('discard;'),'Unaccepted original bodies retain exact display owners');
check(shader.includes('if (coverage>=1.0) { COLOR=vec4(detail,1.0); }'),'Full coverage has no original source fetch');
for(const file of ['registered_hd_ground.gdshader','registered_hd_west_ground.gdshader']){
 const s=fs.readFileSync(path.join(base,'shaders',file),'utf8');
 check(s.includes('external_top_owner_active = false')&&s.includes('external_top_owner_rect'),'Old shaders gain only an inert-by-default external guard');
}
const template=JSON.parse(fs.readFileSync(path.join(base,'data/north_large_hd_region.template.json')));
check(template.quality_approved===false&&template.independent_buildings.length===0,'Unregistered artwork and old bodies cannot be falsely enabled');
console.log(JSON.stringify({status:'static_cpu_only_passed',checks,core_owner_zero_texels_verified_across_four_states:coreTexels,excluded_original_body_texels_across_four_states:excludedFallbackTexels,v4_layer_bytes:baseBytes,five_region_layer_bytes:36390042+baseBytes,independent_body_bytes_excluded:true,source_fallback_body_mask_excluded_from_hd_claim:true,godot_parse_run:false,godot_lifecycle_run:false,gpu_run:false,artwork_accepted:false},null,2));
