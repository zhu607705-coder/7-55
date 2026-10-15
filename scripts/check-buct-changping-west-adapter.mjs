#!/usr/bin/env node
// Dependency-free STATIC/CPU checks. This does not claim Godot, GPU or lifecycle execution.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import zlib from 'node:zlib';
import {fileURLToPath} from 'node:url';

const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const native = path.join(repo, 'godot_native');
const campus = path.join(native, 'campuses/buct_changping');
const read = p => fs.readFileSync(p);
const sha = b => crypto.createHash('sha256').update(b).digest('hex');
const adapter = read(path.join(campus, 'scripts/registered_hd_region.gd')).toString();
const shader = read(path.join(campus, 'shaders/registered_hd_west_ground.gdshader')).toString();
let checks = 0;
const check = (value, label) => { assert.ok(value, label); checks++; };
const same = (a, b, label) => { assert.deepEqual(a, b, label); checks++; };
const smooth = t => { t = Math.max(0, Math.min(1, t)); return t * t * (3 - 2 * t); };
const mix = (a, b, t) => a.map((v, i) => v * (1 - t) + b[i] * t);
const near = (a, b) => a.every((v, i) => Math.abs(v - b[i]) < 1e-12);
const inside = ([x, y], [rx, ry, w, h]) => x >= rx && x < rx + w && y >= ry && y < ry + h;
const mip = ([w, h], channels) => { let n = 0; while (true) { n += w * h * channels; if (w === 1 && h === 1) return n; w = Math.max(1, Math.floor(w / 2)); h = Math.max(1, Math.floor(h / 2)); } };
const methods = new Map([...adapter.matchAll(/^(?:static )?func (\w+)\(.*?(?=^(?:static )?func |$(?![\s\S]))/gms)].map(m => [m[1], m[0].split(/^##/m)[0].trim()]));

const v2WithIncomingOwner = read(path.join(campus, 'shaders/registered_hd_ground.gdshader')).toString();
check(sha(Buffer.from(v2WithIncomingOwner)) === '24462591b10f0b7fe637d383e988e610578851cde914b55f8dfea5c1b44dcef7', 'Exact reviewed v2 shader plus authenticated incoming-owner guard');
const incomingUniforms = 'uniform bool external_top_owner_active = false;\nuniform vec4 external_top_owner_rect;\n';
const incomingDiscard = '    if (external_top_owner_active && all(greaterThanEqual(world_pixel, external_top_owner_rect.xy)) && all(lessThan(world_pixel, external_top_owner_rect.xy + external_top_owner_rect.zw))) { discard; }\n';
check(v2WithIncomingOwner.split(incomingUniforms).length === 2 && v2WithIncomingOwner.split(incomingDiscard).length === 2, 'Only one bounded incoming-owner guard exists');
const unchangedV2 = v2WithIncomingOwner.replace(incomingUniforms, '').replace(incomingDiscard, '');
check(sha(Buffer.from(unchangedV2)) === 'af0b9895ce4f3fede2b2d1f0d1abf36ff4b08b5035a505dbb1801c6b6acdc0d5', 'Every original accepted v2 shading byte remains unchanged after stripping the isolated guard');
const frozenMethods = {
  _prepare_body: '45dffc6dea13f592b75b8cf77f77c43020be0996bf30127c6f8324b9f964c0ce',
  _commit: 'fa1ce1ed6f5e30fe2e0ef85a5de84531beeea0802b40271cf5408db95e620afd',
  update_actor_foot: 'f7ec7d76ea8f77926ce83e57d864bb22fcd497dc3eb14f5e49efc3ad2063bcbb',
  hit_test: '51f9c8a302908db8be5bca6f789bc9f100989f3793738912eeb1282ee4c9363f',
  select_body: 'f205c5095a9138450c4f17b36d7e24641b7bb71cff43815b1e3c65c70dbe7d7e',
  _texture: '50678348fec261ab35317432d3e9f7600db82f0951e49248fd8502979bd83fd7',
  _r8: '43def0e6a29a1bfa398cfe7f0e64ce22c0e019744467be9c8bc857917323755c',
  _sprite: 'd45568828e21fd9fdd33f4ec03f14df677190ee8f94c2c9c8700b93f94fed2a6',
  _valid_body_profile: 'f74ea85678fad038f4cee84346206cb628bbd32f270ba4e8ad940edceb146eb3'
};
const precisionGuard = '\tif actual != decoded.get("collision_footprints_source_xy",null):\n\t\t# JSON may round binary64 display tails; physics is original Vector2 float32.\n\t\t# Explicit new registrations must round back to the exact engine vectors.\n\t\tif decoded.get("footprint_coordinate_precision","")!="original_Vector2_float32" or not _same_footprint_vectors(actual,decoded.get("collision_footprints_source_xy",null)):return false';
check(methods.get('_prepare_body').includes(precisionGuard),'Only explicit Vector2-precision registrations admit JSON display-tail rounding');
check(sha(methods.get('_same_footprint_vectors')) === '00c56976e29a0be3e5657456b664a8fb91c251bb32518debaa8ac1d8c0cd063f','Exact zero-tolerance original-engine Vector2 comparison helper');
for (const [name, hash] of Object.entries(frozenMethods)) {
 const source=name==='_prepare_body'?methods.get(name).replace(precisionGuard,'\tif actual != decoded.get("collision_footprints_source_xy",null): return false'):methods.get(name);
 check(sha(source)===hash,`Accepted ${name} logic unchanged outside explicit precision guard`);
}
check(methods.get('install').includes('if parsed.get("schema","") == "buct_registered_hd_region_v3": return null'), 'A v3 member cannot install alone');
const install = methods.get('install_group');
check(install.indexOf('node._prepare(override)') < install.indexOf('for node in prepared:node._commit()'), 'All preparation precedes group commit');
check(install.indexOf('validator.call()') < install.indexOf('map.world.add_child(node)'), 'Caller identity validation precedes scene mutation');
check(install.includes('resident_count+2>MAX_REGIONS') && install.includes('resident_bytes>MAX_RESIDENT_REGION_LAYER_BYTES'), 'Combined count and layer admission before commit');
check(install.includes('item.node in owner_nodes') && install.includes('label in new_names'), 'Duplicate retired and created owners reject before commit');
check(!install.replace(/#.*$/gm,'').includes('await ') && !install.includes('hide()'), 'Synchronous group commit cannot render a half-prepared frame');
check(methods.get('_restore').includes('member._restore()') && methods.get('uninstall').includes('member.queue_free()'), 'Either member restores the atomic pair');
check(methods.get('_exit_tree').includes('_restore()'), 'Direct remove_child/queue_free enters group restoration through _exit_tree');
check(methods.get('_notification').includes('if not _group_members.is_empty():_restore()'), 'PREDELETE also restores a committed group that never entered the tree');
check(methods.get('_restore').indexOf('member._group_restoring=true') < methods.get('_restore').indexOf('member._restore()'), 'Every member is guarded before recursive group teardown');
check(methods.get('_restore').includes('world_shadow_nodes.clear();_world_shadow_owners.clear()') && methods.get('_restore').includes('visibility_changed.disconnect'), 'Teardown retires world shadows and disconnects reused body visibility');
check(methods.get('_prepare_west').includes('retire_world_visuals') && methods.get('_prepare_west').includes('not visual is Polygon2D'), 'Reused-body ground shadows retire without body replacement');
check(methods.get('_bind_south_region').includes('south.ground_texture') && methods.get('_bind_south_region').includes('south.seam_texture'), 'South/corner samples reuse prepared textures');
check(methods.get('_neighbor_active').includes('.encloses(') && methods.get('_neighbor_active').includes('SOURCE_SHA'), 'Only a registered active exact neighbor enables a strip');
check(shader.indexOf('float retirement =') < shader.indexOf('if (outer_collar'), 'Retirement evaluated before outer discard');
check(shader.includes('if (coverage >= 1.0) {\n        COLOR = vec4(detail, 1.0);\n    } else {\n        vec3 source = texture(original_source'), 'Full coverage has no source sampling dependency');
check(shader.includes('north_owner_active && inside_rect') && shader.includes('textureLod(water_complement, uv, 0.0)'), 'Half-open owner exclusion and original level-zero binary water alpha');
check(!/floor\s*\(|fract\s*\(/.test(shader), 'Continuous HD sampling, no pixel-cell discard');
const prepareShadows=methods.get('_prepare_world_shadows');
check(prepareShadows.includes('polygons!=authored.get("shadow_polygons",null)'), 'World shadows exactly equal their source owner polygons');
check(prepareShadows.includes('not profile.has("shared_corner") or not shared_edges.has("south")'), 'Only NW may prepare the whole-source shadows');
check(prepareShadows.includes('point[0]>950 or point[1]<0 or point[1]>1656'), 'All shadow vertices are bounded by the original source');
check(prepareShadows.includes('shadow.polygon=points;shadow.color=Color(0,0,0,float(spec.opacity))') && !prepareShadows.includes('region_rect.encloses'), 'One solid alpha polygon retains unclipped source coordinates');
check(!prepareShadows.includes('texture=') && !prepareShadows.includes('StaticBody2D'), 'No shadow texture or physics allocation');
check(install.includes('entry.legacy_node in owner_nodes'), 'Every restored shadow has an original source shadow in the atomic retirement list');
check(methods.get('_process_west').includes('visibility_changed.connect(callback)') && methods.get('_refresh_world_shadows').includes('entry.owner.is_visible_in_tree()'), 'Whole-body hide/show immediately controls its shadow');
check(methods.get('get_diagnostics').includes('world_shadow_polygon_count'), 'World polygon count reported separately from texture bytes');
const layers=JSON.parse(read(path.join(campus,'data/layers.json')));
const authoredShadows=new Map(layers.objects.filter(o=>['teaching_2','library'].includes(o.id)).map(o=>[o.id,o.shadow_polygons]));
function validWorldShadows(specs,north=true){
  if(!Array.isArray(specs)||specs.length>2||(!north&&specs.length))return false;
  const owners=new Set();
  return specs.every(s=>{
    if(owners.has(s.owner_id)||!authoredShadows.has(s.owner_id)||!Number.isFinite(s.opacity)||s.opacity<0||s.opacity>1)return false;
    owners.add(s.owner_id);
    return JSON.stringify(s.polygons_source_xy)===JSON.stringify(authoredShadows.get(s.owner_id)) && s.polygons_source_xy.every(poly=>poly.length>=3&&poly.every(p=>p.length===2&&p.every(Number.isFinite)&&p[0]>=0&&p[0]<=950&&p[1]>=0&&p[1]<=1656));
  });
}
const shadows=[...authoredShadows].map(([owner_id,polygons_source_xy])=>({owner_id,polygons_source_xy,opacity:.22}));
check(validWorldShadows(shadows),'Both exact source-owned world polygons validate (CPU model)');
check(!validWorldShadows(shadows,false),'SW duplication rejected (CPU model)');
for(const mutate of [s=>{s[0].polygons_source_xy[0][0][0]++;},s=>{s[0].owner_id='unrelated';},s=>{s[0].opacity=1.1;},s=>{s[1]=s[0];}]){
  const bad=structuredClone(shadows);mutate(bad);check(!validWorldShadows(bad),'Altered shadow geometry, owner, opacity or duplication rejected (CPU model)');
}
check(shadows[0].polygons_source_xy.flat().some(p=>p[1]>639),'Teaching cast shadow crosses NW ground boundary and must remain whole');

// CPU reference for the exact declared blend and availability/fallback contract.
const colors = [[0.08, 0.2, 0.9], [0.9, 0.13, 0.1], [0.7, 0.8, 0.12], [0.1, 0.6, 0.75]];
function cornerBlend(u, v, east = true, southeast = true) {
  const [nw, ne, sw, se] = colors;
  return nw.map((value, i) => (1-u)*(1-v)*value + u*(1-v)*(east ? ne : nw)[i] + (1-u)*v*sw[i] + u*v*(southeast ? se : sw)[i]);
}
let cornerTexels = 0;
for (let y = 0; y < 120; y++) for (let x = 0; x < 120; x++) {
  const u = smooth((x + .5) / 120), v = smooth((y + .5) / 120);
  check(near(cornerBlend(u, v), mix(mix(colors[0], colors[1], u), mix(colors[2], colors[3], u), v)), 'Four-source sum equals separable smoothstep');
  const weights = [(1-u)*(1-v), u*(1-v), (1-u)*v, u*v];
  check(weights.every(n => n >= 0 && n <= 1) && Math.abs(weights.reduce((a,b)=>a+b,0)-1) < 1e-12, 'Convex opaque corner weights');
  cornerTexels++;
}
for (let i = 0; i <= 120; i++) {
  const t = smooth(i / 120);
  check(near(cornerBlend(0,t), mix(colors[0],colors[2],t)), 'West corner boundary equals NW/SW');
  check(near(cornerBlend(1,t), mix(colors[1],colors[3],t)), 'East corner boundary equals unchanged NE/SE');
  check(near(cornerBlend(t,0), mix(colors[0],colors[1],t)), 'North corner boundary equals NW/NE');
  check(near(cornerBlend(t,1), mix(colors[2],colors[3],t)), 'South corner boundary equals SW/SE');
  for (const east of [false,true]) for (const southeast of [false,true]) {
    check(near(cornerBlend(t,0,east,southeast), mix(colors[0], east ? colors[1] : colors[0], t)), 'Missing east preserves north boundary');
    check(near(cornerBlend(t,1,east,southeast), mix(colors[2], southeast ? colors[3] : colors[2], t)), 'Missing diagonal preserves south boundary');
  }
}
function coverage(point, region, {east=true, south=false, southeast=true, retirement=0, north=false, water=false}={}) {
  if (water || (north && inside(point, [region[0],region[1],region[2],24]))) return null;
  const [x,y] = point, [rx,ry,w,h] = region, px=x-rx, py=y-ry;
  const sharedSouth=south && inside(point,[rx,ry+h-24,w,24]);
  const corner=sharedSouth && inside(point,[rx+w-24,ry+h-24,24,24]);
  const sharedEast=(east || (corner && southeast)) && px>=w-24;
  const collar=px<2 || py<2 || (!sharedEast&&px>=w-2) || (!sharedSouth&&py>=h-2);
  if (collar && retirement<1) return null;
  let d=Math.min(px,py); if(!sharedEast)d=Math.min(d,w-px); if(!sharedSouth)d=Math.min(d,h-py);
  let result=Math.max(smooth((d-2)/10),retirement);
  if(corner && (!east || !southeast)) {
    const fallback=smooth((w-px-2)/10), v=smooth((py-h+24)/24);
    result=Math.max(retirement,Math.min(result,(east?1:fallback)*(1-v)+(southeast?1:fallback)*v));
  }
  return result;
}
const nw=[398,399,256,240], sw=[398,615,256,240];
let sourceFreeCoreTexels=0;
for(let y=411*5;y<843*5;y++)for(let x=426*5;x<642*5;x++){
  const p=[(x+.5)/5,(y+.5)/5];
  const c=p[1]<639?coverage(p,nw,{south:true}):coverage(p,sw,{north:true});
  check(c===1,'Every west logical-core texel has full coverage under its sole owner');
  // Evaluating this branch must not read either normal or poisoned source RGB.
  const source=()=>{throw Error('Source accessed at full coverage');};
  const result=c>=1?colors[0]:mix(source(),colors[0],c);
  check(result===colors[0],'Source-poison-free CPU branch');sourceFreeCoreTexels++;
}
same(coverage([398.1,550.1],nw,{south:true,retirement:1}),1,'Teaching-shadow retirement overrides x398 collar');
same(coverage([398.1,550.1],nw,{south:true}),null,'Unowned x398 collar retains source');
same(coverage([650,400],nw,{south:true}),null,'East sharing does not suppress perpendicular exterior collar');
check(coverage([650,405],nw,{south:true})<1,'East sharing preserves perpendicular 10px transition');
same(coverage([640,620],sw,{north:true}),null,'SW excludes entire NW-owned horizontal/corner band');
same(coverage([420,800],sw,{water:true}),null,'Original water owner receives its exact alpha pixels');
same(coverage([652.1,620],nw,{south:true,east:false,southeast:false}),null,'Both eastern neighbors absent restores outer collar');
check(coverage([650,620],nw,{south:true,east:false,southeast:false})<1,'Missing east neighbors restore source transition');
for(const order of [['NW','SW','NE','SE'],['SE','NE','SW','NW'],['SW','NW','SE','NE']]){
  const sorted=[...order].sort((a,b)=>['SE','NE','SW','NW'].indexOf(a)-['SE','NE','SW','NW'].indexOf(b));
  same(sorted,['SE','NE','SW','NW'],'Stable owner DAG independent of insertion order (CPU model)');
}
const layer=mip([1280,1200],4)+mip([256,240],1)+mip([122,1200],4);
const swLayer=layer+mip([256,240],1);
const admitted=(count,bytes,regions)=>count+regions.length<=6 && regions.every(n=>n>=0&&n<=12000000) && bytes+regions.reduce((a,b)=>a+b,0)<=57597600;
check(admitted(2,18186840,[layer,swLayer]),'Accepted east pair plus west pair within combined budget');
check(!admitted(5,0,[layer,swLayer]),'Two-region transaction rejects seventh region');
check(!admitted(2,50000000,[layer,swLayer]),'Combined transaction rejects resident-byte overflow');
check(!admitted(0,0,[12000001,1]),'Oversized individual layer rejects');

// Optional actual generated profile/asset checks: pass north.json south.json.
const paths=process.argv.slice(2);
const res=p=>{check(typeof p==='string'&&p.startsWith('res://'),'Canonical resource path');const result=path.resolve(native,p.slice(6));check(result.startsWith(native+path.sep),'Resource stays inside project');return result;};
function decodePng(buffer){
  same([...buffer.subarray(0,8)],[137,80,78,71,13,10,26,10],'PNG signature');
  const w=buffer.readUInt32BE(16),h=buffer.readUInt32BE(20),channels=buffer[25]===6?4:3;
  check(buffer[24]===8&&[2,6].includes(buffer[25])&&buffer[28]===0,'8-bit non-interlaced RGB/RGBA');
  const chunks=[];for(let i=8;i<buffer.length;){const n=buffer.readUInt32BE(i);if(buffer.toString('ascii',i+4,i+8)==='IDAT')chunks.push(buffer.subarray(i+8,i+8+n));i+=n+12;}
  const raw=zlib.inflateSync(Buffer.concat(chunks)),stride=w*channels,data=Buffer.alloc(w*h*channels),rgba=Buffer.alloc(w*h*4);
  check(raw.length===h*(stride+1),'Exact decoded PNG scanline count');
  const paeth=(a,b,c)=>{const p=a+b-c,aa=Math.abs(p-a),bb=Math.abs(p-b),cc=Math.abs(p-c);return aa<=bb&&aa<=cc?a:bb<=cc?b:c;};
  for(let y=0;y<h;y++)for(let x=0;x<stride;x++){
    const i=y*stride+x,a=x>=channels?data[i-channels]:0,b=y?data[i-stride]:0,c=y&&x>=channels?data[i-stride-channels]:0;
    const predictor=[0,a,b,Math.floor((a+b)/2),paeth(a,b,c)][raw[y*(stride+1)]];if(predictor===undefined)throw Error('Unsupported PNG filter');data[i]=(raw[y*(stride+1)+1+x]+predictor)&255;
  }
  for(let i=0;i<w*h;i++){data.copy(rgba,i*4,i*channels,i*channels+3);rgba[i*4+3]=channels===4?data[i*channels+3]:255;}return {size:[w,h],rgba};
}
function verifyTexture(asset,size,hash){const decoded=decodePng(read(res(asset)));same(decoded.size,size,'Declared texture size');check(sha(decoded.rgba)===hash,'Exact decoded RGBA hash');return decoded;}
function verifyR8(spec,size,binary=false){same(spec.size??size,size,'Declared mask size');const b=read(res(spec.asset));check(b.length===size[0]*size[1]&&sha(b)===spec.sha256,'Exact mask byte count/hash');if(binary)check(b.every(v=>v===0||v===255),'Original-water complement remains binary');}
let actualProfiles=0;
if(paths.length){
  check(paths.length===2,'Pass both atomic profile paths');
  const profiles=paths.map(p=>JSON.parse(read(p))).sort((a,b)=>a.roi_xywh[1]-b.roi_xywh[1]);
  same(profiles.map(p=>p.id),['west_north','west_south'],'Correct canonical west pair');
  let total=0;
  for(const [i,p] of profiles.entries()){
    check(p.schema==='buct_registered_hd_region_v3'&&p.quality_approved===true&&p.texels_per_source_pixel===5,'Approved v3 profile');
    same(p.roi_xywh,i===0?nw:sw,'Authorized wider source ROI');same(p.runtime_size,[1280,1200],'Uniform 5x runtime');same(p.core_xywh,[426,i===0?411:627,216,216],'Unchanged logical core');
    same(p.atomic_region_ids,['west_north','west_south'],'Explicit atomic pair');check(p.atomic_group_id==='west_adjacent_pair','Expected group');
    const ground=verifyTexture(p.ground_asset,p.runtime_size,p.ground_rgba_sha256);check(ground.rgba.every((v,index)=>index%4!==3||v===255),'Ground remains opaque');
    verifyR8(p.source_body_ownership,[256,240]);
    const east=p.shared_edges.find(e=>e.edge==='east');same(east.rect,[630,i===0?399:615,24,240],'Exact east overlap');same(east.sample_size,[122,1200],'Two-texel sampling gutter');verifyTexture(east.unfeathered_strip_asset,east.sample_size,east.rgba_sha256);
    let bytes=layer;if(p.water_complement){verifyR8(p.water_complement,[256,240],true);bytes+=mip([256,240],1);}
    check(p.shadow===null,'No new texture-shadow renderer');
    check(validWorldShadows(p.world_shadows??[],i===0),'Actual world shadows retain exact authored polygons and owner');
    for(const leaf of p.foreground){const size=[leaf.rect[2]*5,leaf.rect[3]*5];verifyR8({asset:leaf.alpha_asset,sha256:leaf.alpha_sha256},size);bytes+=mip(size,1);}
    check(bytes<=12000000,'Actual region layer cap');total+=bytes;actualProfiles++;
  }
  same(profiles[0].independent_buildings.map(b=>b.id),['teaching_2'],'One whole teaching body owned by NW');same(profiles[1].independent_buildings,[],'SW never replaces library');
  same(profiles[0].shared_corner.rect,[630,615,24,24],'Exact four-way corner');check(total+18186840<=57597600,'Actual resident layer cap');
}
console.log(JSON.stringify({status:'static_cpu_checks_passed',checks,corner_texels:cornerTexels,source_free_core_texels:sourceFreeCoreTexels,base_nw_layer_bytes:layer,base_sw_layer_bytes_with_water_mask:swLayer,actual_profiles_checked:actualProfiles,godot_parse_run:false,gpu_run:false,engine_lifecycle_run:false,body_bytes_separate:true,automatic_streaming:false},null,2));
