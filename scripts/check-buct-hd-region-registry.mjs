#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
const repo=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const native=path.join(repo,'godot_native');
const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const read=p=>fs.readFileSync(p),json=p=>JSON.parse(read(p));
const res=p=>{assert.ok(typeof p==='string'&&p.startsWith('res://'),'Canonical resource path required');const result=path.resolve(native,p.slice(6));assert.ok(result.startsWith(native+path.sep));return result;};
const artifact=p=>{assert.ok(typeof p==='string');const result=path.resolve(repo,p);assert.ok(result.startsWith(repo+path.sep));return result;};
const mip=([w,h],channels)=>{let total=0;while(true){total+=w*h*channels;if(w===1&&h===1)return total;w=Math.max(1,Math.floor(w/2));h=Math.max(1,Math.floor(h/2));}};
const intersect=(a,b)=>{const x=Math.max(a[0],b[0]),y=Math.max(a[1],b[1]),w=Math.min(a[0]+a[2],b[0]+b[2])-x,h=Math.min(a[1]+a[3],b[1]+b[3])-y;return w>0&&h>0?[x,y,w,h]:null;};
const catalog=json(path.join(native,'campuses/buct_changping/data/hd_region_registry.json'));
const runtime=read(path.join(native,'campuses/buct_changping/scripts/playable_campus.gd')).toString();
let checks=0;
const check=(ok,label)=>{assert.ok(ok,label);checks++;};
const same=(a,b,label)=>{assert.deepEqual(a,b,label);checks++;};
function validate(value){
 check(value.schema==='buct_hd_region_registry_v1'&&value.campus==='buct_changping','Versioned campus registry');
 same(value.canvas_size,[950,1656],'Original source dimensions');
 check(sha(read(path.join(native,'campuses/buct_changping/assets/approved-changping.png')))===value.source_sha256,'Source bytes unchanged');
 same(value.grid,{core_source_pixels:216,overlap_source_pixels:24,runtime_texels_per_source_pixel:5,source_collar_pixels:2,transition_source_pixels:10},'Registered grid');
 check(value.residency.max_regions===6&&value.residency.maximum_region_layer_bytes===57597600&&value.residency.maximum_single_region_layer_bytes===12000000,'Explicit layer-only caps');
 check(value.residency.runtime_admission_enforced===true&&value.residency.runtime_streaming_implemented===false&&value.residency.body_bytes_separate===true,'Admission distinguished from streaming and body accounting');
 const ids=new Set(),assets=new Set();let knownBytes=0;
 for(const region of value.regions){
  check(typeof region.id==='string'&&!ids.has(region.id),'Stable unique region ID');ids.add(region.id);
  check(['accepted','awaiting_assets'].includes(region.status),'Explicit acceptance state');
  if(region.default_enabled){check(region.status==='accepted','Default enabled requires accepted status');check(typeof region.profile==='string','Default enabled requires actual profile');}
  for(const field of ['roi_xywh','core_xywh']){const rect=region[field];check(Array.isArray(rect)&&rect.length===4&&rect.every(Number.isInteger),'Integer source rectangle');check(rect[0]>=0&&rect[1]>=0&&rect[2]>0&&rect[3]>0&&rect[0]+rect[2]<=950&&rect[1]+rect[3]<=1656,'Region inside source');}
  const [x,y,w,h]=region.roi_xywh;const west=region.adapter==='registered_hd_region_v3',large=region.adapter==='registered_hd_region_v4',upper=region.adapter==='registered_hd_region_v5';same(region.core_xywh,west?[x+w-228,y+12,216,216]:[x+12,y+12,w-24,h-24],'Core inset, including bounded wider west context collar');same(region.runtime_size,[w*((large||upper)?4:5),h*((large||upper)?4:5)],'Explicit uniform native scale, without five-texel upscaling of v4 originals');
  if(region.runtime_default_flag){const match=runtime.match(new RegExp('var '+region.runtime_default_flag+'\\s*:=\\s*(true|false)'));check(match&&((match[1]==='true')===region.default_enabled),'Registry agrees with actual default runtime flag');}
  if(region.status!=='accepted'){check(region.default_enabled===false&&region.profile===null&&region.ground_asset===null,'Pending region retains source fallback');continue;}
  const profile=json(res(region.profile));check(profile.quality_approved===true,'Approved production profile');same(profile.roi_xywh,region.roi_xywh,'Profile region');same(profile.core_xywh,region.core_xywh,'Profile core');
  check(profile.ground_asset===region.ground_asset&&fs.existsSync(res(region.ground_asset)),'Actual ground asset');check(!assets.has(region.ground_asset),'Unique ground artwork');assets.add(region.ground_asset);
  let layerBytes;
  if(region.adapter==='legacy_wenli'){
   check(profile.shadow_asset===region.shadow_asset&&fs.existsSync(res(region.shadow_asset)),'Legacy owned shadow remains exact');layerBytes=mip(region.runtime_size,5);
  }else{
   check(['registered_hd_region_v2','registered_hd_region_v3','registered_hd_region_v4','registered_hd_region_v5'].includes(region.adapter)&&profile.shadow===null&&region.shadow_asset===null,'Only explicit schematic world shadows, no invented texture shadow');
   if(large){
    check(profile.schema==='buct_registered_hd_region_v4'&&profile.texels_per_source_pixel===4,'V4 real native original density is explicit');
    same(region.roi_xywh,[350,167,384,256],'Bounded northern large ROI');same(profile.source_body_ownership.size,[384,256],'Source-sized indexed fallback mask');
    same(profile.source_body_ownership.owner_ids,['hill_south_block','north_sports_west_shelter'],'Unaccepted old visual owners remain explicit');
    check(sha(read(res(profile.source_body_ownership.asset)))===profile.source_body_ownership.sha256,'Exact v4 source fallback mask');
    const mask=read(res(profile.source_body_ownership.asset));let fallback=0;
    for(let yy=12;yy<244;yy++)for(let xx=12;xx<372;xx++)if(mask[yy*384+xx])fallback++;
    check(fallback===5016&&region.source_fallback_core_pixels===fallback&&region.hd_terrain_core_source_pixels===360*232-fallback,'Coverage excludes every unaccepted original body cell');
    same(profile.shared_lower_edges.map(e=>e.sample_size),[[1280,122],[520,122]],'Two charged native lower strips');
    layerBytes=mip(region.runtime_size,4)+mip(profile.source_body_ownership.size,1)+profile.shared_lower_edges.reduce((n,e)=>n+mip(e.sample_size,4),0);
    same(profile.independent_buildings,[],'No rejected building is promoted to RGBA');same(profile.foreground,[],'No new foreground claim in terrain-only v4');
   }else if(upper){
    check(profile.schema==='buct_registered_hd_region_v5'&&profile.texels_per_source_pixel===4,'V5 explicit native registration grid');
    same(region.roi_xywh,[118,167,256,256],'Bounded left northern region');same(profile.source_body_ownership.size,[256,256],'Original building fallback owner mask');
    const mask=read(res(profile.source_body_ownership.asset));check(sha(mask)===profile.source_body_ownership.sha256,'Exact V5 source fallback mask');
    const acceptedIds=profile.independent_buildings.map(x=>x.id);
    check(acceptedIds.length<=1&&acceptedIds.every(x=>x==='dorm_nw_02'),'Only explicitly accepted original dorm may retire its indexed fallback');
    let fallback=0;for(let yy=12;yy<244;yy++)for(let xx=12;xx<244;xx++){const owner=mask[yy*256+xx];if(owner&&!acceptedIds.includes(profile.source_body_ownership.owner_ids[owner-1]))fallback++;}
    check(fallback===(acceptedIds.length?8268:11224)&&region.source_fallback_core_pixels===fallback&&region.hd_terrain_core_source_pixels===232*232-fallback,'New coverage excludes every remaining original body cell');
    if(acceptedIds.length){const body=json(res(profile.independent_buildings[0].registration));check(body.id==='dorm_nw_02'&&body.registration_audit.acceptance_status==='accepted_local_scope_actual_normal_render'&&sha(read(res(body.body_asset)))===body.body_sha256,'Accepted original RGBA and full-body local evidence are exact');same(body.source_anchor,[181,304],'Original dorm anchor unchanged');check(region.independent_body_gpu_bytes===mip(body.body_image_to_world.raw_size,4)+body.body_image_to_world.raw_size[0]*body.body_image_to_world.raw_size[1]+body.body_image_to_world.raw_size[0]*4,'New body mip/surface/depth allocation is separate');}
    same(profile.foreground,[],'No new left foreground owner');
    layerBytes=mip(region.runtime_size,4)+mip(profile.source_body_ownership.size,1)+mip(profile.shared_east.sample_size,4);
   }else{
    const seam=profile.shared_overlap??profile.shared_edges.find(edge=>edge.edge==='east');
    layerBytes=mip(region.runtime_size,4)+mip(seam.sample_size,4)+mip(profile.source_body_ownership.size,1);
   }
   if(profile.water_complement)layerBytes+=mip(profile.water_complement.size,1);
   if(west){check(profile.atomic_group_id===region.atomic_group_id&&region.atomic_group_id==='west_adjacent_pair','Explicit atomic west group');same(profile.atomic_region_ids,['west_north','west_south'],'Atomic pair IDs');}
   for(const leaf of profile.foreground)layerBytes+=mip([leaf.rect[2]*5,leaf.rect[3]*5],1);
   same(region.independent_building_owner_ids,profile.independent_buildings.map(x=>x.id),'Exact independent owner IDs');same(region.foreground_owner_ids,profile.foreground.map(x=>x.id),'Exact foreground owner IDs');
   const report=json(artifact(region.acceptance_report));check(report.status==='accepted_local_scope'&&report.remaining_gates.length===0,'Accepted default has completed local evidence gates');
  }
  check(region.region_layer_gpu_bytes===layerBytes,'Exact per-region mip byte calculation');check(Number.isInteger(region.independent_body_gpu_bytes)&&region.independent_body_gpu_bytes>=0,'Independent body bytes are explicit');check((region.independent_building_owner_ids.length===0)===(region.independent_body_gpu_bytes===0),'Empty SW body owner has exactly zero new body bytes; reused library never double counts');knownBytes+=layerBytes+region.independent_body_gpu_bytes;
 }
 check(ids.has('wenli_east')&&ids.has('north_adjacent'),'Contiguous first pair retained');
 for(const adjacency of value.adjacencies){
  const a=value.regions.find(r=>r.id===adjacency.a),b=value.regions.find(r=>r.id===adjacency.b);check(a&&b&&a!==b,'Valid distinct neighbors');same(intersect(a.roi_xywh,b.roi_xywh),adjacency.shared_source_xywh,'Exact shared region');check(intersect(a.core_xywh,b.core_xywh)===null,'Core coverage does not double count');
  if(a.default_enabled&&b.default_enabled){
   const upperSeam=a.adapter==='registered_hd_region_v5'||b.adapter==='registered_hd_region_v5';
   check(adjacency.seam_status===(upperSeam?'accepted_normal_render':'accepted_gpu')&&adjacency.seam_validation,'Two enabled neighbors require scoped actual seam evidence');
   const proof=adjacency.seam_validation,bytes=read(artifact(proof.file));check(sha(bytes)===proof.sha256,'Seam evidence file hash');const report=JSON.parse(bytes);
   if(upperSeam){
    check(report.status==='accepted_local_scope'&&report.tests.default_smoke.status==='passed'&&report.tests.default_smoke.display_server==='X11','New left seam has real default startup/render evidence');
    check(report.visual_review.seam_passed===true&&report.visual_review.manual_gameplay===false&&proof.scope==='normal_default_render_only','Minimal normal seam review is not a source-poison or gameplay claim');
    continue;
   }
   const fixture=report.gpu_records.find(x=>x.fixture===proof.fixture);check(fixture&&fixture.comparison.changed_pixels===0&&fixture.comparison.max_channel_delta===0,'Actual source-poisoning GPU record has exact zero delta');
   if(a.adapter==='registered_hd_region_v4'||b.adapter==='registered_hd_region_v4')check(fixture.comparison.tested_pixels===1256064&&report.tests.gpu.checks>=29&&report.tests.gpu.actual_display_server==='X11','V4 proof covers the complete nonempty terrain core on the actual display');
   check(proof.changed_pixels===0&&proof.max_channel_delta===0&&report.tests.gpu.failures.length===0,'Seam summary agrees with passed GPU proof');
  }
 }
 check(knownBytes===(value.residency.known_registered_region_body_and_layer_bytes??value.residency.known_two_region_body_and_layer_bytes),'Known layers plus independent bodies accounted separately');
}
validate(catalog);
const positiveChecks=checks;
const negativeCases=[
 ['enabled_pending',c=>{c.regions.find(r=>r.id==='north_adjacent').status='awaiting_assets';}],
 ['enabled_null_profile',c=>{c.regions.find(r=>r.id==='north_adjacent').profile=null;}],
 ['runtime_flag_disagrees',c=>{c.regions.find(r=>r.id==='north_adjacent').default_enabled=false;}],
 ['missing_seam_evidence',c=>{delete c.adjacencies[0].seam_validation;}],
 ['pending_seam',c=>{c.adjacencies[0].seam_status='pending_asset_validation';}],
 ['false_seam_hash',c=>{c.adjacencies[0].seam_validation.sha256='wrong';}],
 ['false_layer_budget',c=>{c.regions.find(r=>r.id==='north_adjacent').region_layer_gpu_bytes=1;}]
];
if(catalog.regions.some(r=>r.id==='west_north'))negativeCases.push(
 ['false_west_core',c=>{c.regions.find(r=>r.id==='west_north').core_xywh[0]=410;}],
 ['false_west_group',c=>{c.regions.find(r=>r.id==='west_north').atomic_group_id='wrong';}],
 ['double_count_reused_library',c=>{c.regions.find(r=>r.id==='west_south').independent_building_owner_ids=['library'];}]
);
for(const [name,mutate] of negativeCases){const copy=structuredClone(catalog);mutate(copy);assert.throws(()=>validate(copy),undefined,`Malformed registry must reject: ${name}`);}
console.log(`BUCT_HD_REGION_REGISTRY ${positiveChecks} positive assertions and ${negativeCases.length} required rejection cases passed; ${catalog.regions.filter(x=>x.status==='accepted').length} accepted regions, automatic streaming false`);
