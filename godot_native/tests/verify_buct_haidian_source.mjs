// Read-only source contracts. Does not import assets, launch Godot, or write reports.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';

const project=path.resolve(import.meta.dirname,'..');
const prefix='campuses/buct_haidian/';
const campus=path.join(project,prefix);
const read=relative=>fs.readFileSync(path.join(project,relative),'utf8');
const json=relative=>JSON.parse(read(prefix+relative));
let checks=0;
function check(ok,message){assert.ok(ok,message);checks++;}
function same(actual,expected,message){assert.deepEqual(actual,expected,message);checks++;}
function resource(relative){
 check(typeof relative==='string'&&relative.length>0&&!path.isAbsolute(relative)&&!relative.split(/[\\/]/).includes('..'),`Unsafe campus resource: ${relative}`);
 const file=path.join(campus,relative);
 check(fs.existsSync(file)&&fs.statSync(file).isFile(),`Missing campus dependency: ${relative}`);
 return file;
}
function png(relative,expectedHash){
 const bytes=fs.readFileSync(resource(relative));
 check(bytes.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10])),`PNG signature: ${relative}`);
 if(expectedHash)same(createHash('sha256').update(bytes).digest('hex'),expectedHash,`Original PNG hash: ${relative}`);
 return {width:bytes.readUInt32BE(16),height:bytes.readUInt32BE(20),colorType:bytes[25]};
}
function walk(folder){return fs.readdirSync(folder,{withFileTypes:true}).flatMap(item=>item.isDirectory()?walk(path.join(folder,item.name)):[path.join(folder,item.name)]);}
function uniform(transform,info,rect,label){
 check(transform&&Number.isFinite(transform.scale)&&transform.scale>0,`${label}: one positive uniform image scale`);
 check(Array.isArray(transform.origin)&&transform.origin.length===2&&transform.origin.every(Number.isFinite),`${label}: explicit image origin`);
 same(transform.raw_size,[info.width,info.height],`${label}: raw PNG dimensions`);
 check(Array.isArray(rect)&&rect.length===4&&rect.every(Number.isFinite)&&rect[2]>0&&rect[3]>0,`${label}: valid world rectangle`);
}

const chooser=read('scripts/entry.gd');
check(chooser.includes('const STORY_SCENE := "res://scenes/main.tscn"'),'Original story scene identity retained');
check(chooser.includes('const BUCT_SCENE := "res://campuses/buct/scenes/playable.tscn"'),'Original Chaoyang scene identity retained');
check(chooser.includes('const HAIDIAN_SCENE := "res://campuses/buct_haidian/scenes/playable.tscn"'),'Haidian uses separate resource root');
for(const name of ['ContinueStory','OpenBuctCampus','OpenBuctHaidian'])check(chooser.includes(`name="${name}"`),`Chooser button identity ${name}`);
check(/func open_campus\(\) -> void:\s*_open\(BUCT_SCENE\)/.test(chooser),'Original open_campus semantic retained');
check(/func open_haidian\(\) -> void:\s*_open\(HAIDIAN_SCENE\)/.test(chooser),'New Haidian callback routes independently');
check(chooser.includes('if opening:return')&&chooser.includes('_change_scene.call_deferred(path)'),'Chooser retains transition guard/deferred lifecycle');
const qaArguments=chooser.match(/var qa_argument\s*:=([^\n]+)/)?.[1]||'';
check(chooser.includes('entry_arguments_consumed')
 &&['--fresh','--screenshot','--preview=','--checkpoint=','--page='].every(arg=>qaArguments.includes(`"${arg}"`))
 &&/if\s+argument\s*==\s*"--story"\s+or\s+\(DeveloperTools\.available\(\)\s+and\s+qa_argument\):\s*open_story\.call_deferred\(\)/.test(chooser),
 'Normal --story entry retained; every QA direct-entry argument requires developer permission');
check(read('project.godot').includes('run/main_scene="res://scenes/entry.tscn"'),'Default native entry remains the shared chooser');

const manifest=json('data/buildings/scene-manifest.json');
same(manifest.profiles,['data/buildings/teaching-profile.json'],'Teaching inspector retains its own single profile');
const profile=json(manifest.profiles[0]);
same(profile.legacy_id,'main_building','Teaching profile retains original identity');
same(profile.render_backend,'sprite_regions','Default accepted Sprite-region renderer');
same(profile.body_filter,'rgb_mipmap_alpha0','RGB mipmaps with alpha LOD0');
const source=json('data/layers.json');
const route=json('data/playable_route.json');
same(source.canvas_size,[1448,1086],'Original full-campus source dimensions');
same(route.canvas_size,[1448,1086],'Route shares the original source coordinate frame');
same(route.spawn,[963,297],'Original north entrance coordinate');
same(route.landmarks.map(x=>x.id),['north_gate','main_building','library'],'Original three landmark identities');
check(source.objects.some(x=>x.id==='library'),'Original library source geometry retained for retirement accounting');
same(route.qa.manual_action,'buct_haidian_walk_down','QA action uses isolated Haidian namespace');
same(source.source,route.source,'Route and legacy layers use the same original map');
png(source.source,'b5a95f81d89819cc54a346c5ec8e22abd7cd2bc7814b7daf5b65d0145bf72c63');
for(const occluder of route.occluders??[])if(occluder.alpha_mask)png(occluder.alpha_mask);
const body=png(profile.body_texture,profile.body_png_sha256);
same(profile.body_png_sha256,'52bbdabc29b1dcc085eb5edb9dca31a663803745c7c8d4502095bcf9cdd0543b','Accepted body source bytes remain unchanged');
same(body.colorType,6,'Teaching body is an RGBA PNG');
const shadow=png(profile.shadow_texture,profile.shadow_png_sha256);
png(profile.shadow_clip_texture,profile.shadow_clip_sha256);
png(manifest.repair_mask,manifest.repair_mask_sha256);
png(manifest.preserved_foliage_mask,manifest.preserved_foliage_mask_sha256);
uniform(profile.body_image_to_world,body,profile.body_world_rect,'body');
uniform(profile.shadow_image_to_world,shadow,profile.shadow_world_rect,'shadow');
for(const [label,t,info,rect] of [['body',profile.body_image_to_world,body,profile.body_world_rect],['shadow',profile.shadow_image_to_world,shadow,profile.shadow_world_rect]]){
 check(Math.abs(info.width*t.scale-rect[2])<1e-6&&Math.abs(info.height*t.scale-rect[3])<1e-6,`${label}: world size follows the same scalar on both axes`);
 check(Math.abs(t.origin[0]-rect[0])<1e-6&&Math.abs(t.origin[1]-rect[1])<1e-6,`${label}: world origin agrees with registration`);
}
same(manifest.ground_layers.map(x=>x.id),['WestCompleteCleanGround','EastCompleteCleanGround','LongFacadeCleanGround'],'Only the accepted three-section ground is active');
const acceptedGroundFiles=['assets/buildings/haidian-west-expanded-ground-quality-v1.png','assets/buildings/haidian-east-ground-quality-v1.png','assets/buildings/haidian-long-ground-quality-v1.png'];
same(manifest.ground_layers.map(x=>x.texture),acceptedGroundFiles,'No old five-layer or failed ground candidate');
const acceptedRects={WestCompleteCleanGround:[424,160,226,180],EastCompleteCleanGround:[754,250,106,162],LongFacadeCleanGround:[588,247,185,141]};
for(const layer of manifest.ground_layers){
 same(layer.world_rect,acceptedRects[layer.id],`${layer.id}: exact independently accepted ROI, never shared-frame fallback`);
 const info=png(layer.texture,layer.png_sha256);
 uniform(layer.image_to_world,info,layer.world_rect,layer.id);
 same(layer.image_to_world.clip_world_rect,layer.world_rect,`${layer.id}: clipping and registered world frame agree`);
 const t=layer.image_to_world,r=layer.world_rect;
 check(t.origin[0]<=r[0]+1e-6&&t.origin[1]<=r[1]+1e-6&&t.origin[0]+info.width*t.scale>=r[0]+r[2]-1e-6&&t.origin[1]+info.height*t.scale>=r[1]+r[3]-1e-6,`${layer.id}: uniform source covers only its declared clip frame`);
 check(Array.isArray(layer.overlap_feather)&&layer.overlap_feather.length===4&&layer.overlap_feather.every(x=>Number.isFinite(x)&&x>=0),`${layer.id}: explicit nonnegative overlap feather`);
}
// Exact accepted ROI contracts prevent the prior accidental whole-frame fallback.
const importSettings=fs.readFileSync(resource(profile.body_texture+'.import'),'utf8');
check(/^mipmaps\/generate=true$/m.test(importSettings),'Shipping body PNG importer generates mipmaps');
check(importSettings.includes(`source_file="res://${prefix}${profile.body_texture}"`),'Body importer points at the integrated source');
check(/^process\/size_limit=0$/m.test(importSettings),'Body importer preserves original source dimensions');
for(const shader of ['registered_alpha.gdshader','registered_body.gdshader'])check(/textureLod\(TEXTURE,\s*UV,\s*0\.0\)/.test(read(prefix+'shaders/'+shader)),`${shader}: alpha samples source LOD0`);
const runtime=read(prefix+'scripts/playable_campus.gd');
const visitor=read(prefix+'scripts/campus_visitor.gd');
check(runtime.includes('overlap_feather')&&read(prefix+'shaders/registered_ground_patch.gdshader').includes('overlap_feather'),'Three-part ground registration includes overlap-only blending');
for(const action of ['left','right','up','down','fast'])check(runtime.includes(`buct_haidian_walk_${action}`)&&visitor.includes(`buct_haidian_walk_${action}`),`Haidian input namespace: ${action}`);
check(!/["']walk_(?:left|right|up|down|fast)["']/.test(runtime+visitor),'No global standalone walk actions leak into integrated game');
check(!/content_scale_(?:size|mode|factor|aspect)\s*=/.test(runtime),'Haidian never overwrites global window scaling');
check(!/get_tree\(\)\.quit\s*\(|save_(?:png|jpg)\s*\(|BUCT_WALK_CAPTURE/.test(runtime),'Runtime does not retain capture/export/quit branches');
check(!/\bState\s*\.|\bsave_game\s*\(|\bSAVE_PATH\b|\bBACKUP_PATH\b/.test(runtime),'Campus runtime does not write story state or saves');
for(const method of ['return_to_entry','_exit_tree','_notification'])check(runtime.includes(`func ${method}(`),`Haidian lifecycle owns ${method}`);
check(runtime.includes('owned_actions')&&runtime.includes('InputMap.erase_action'),'Haidian records and removes only owned actions');
check(runtime.includes('res://scenes/entry.tscn'),'Haidian returns to the same existing chooser');

const allowedResourceRoots=[prefix,'campuses/buct_shared/student/scripts/landmark_pin_layout.gd','scripts/developer_tools_policy.gd','scenes/entry.tscn','assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf'];
for(const file of walk(campus)){
 const relative=path.relative(campus,file).replaceAll(path.sep,'/');
 check(!/(^|\/)(?:delivery|evidence|exports|\.godot|cache)(\/|$)|\.zip$/.test(relative),`No old delivery/evidence/cache in campus: ${relative}`);
 if(/\.(?:gd|gdshader|tscn)$/.test(relative)){
  const text=fs.readFileSync(file,'utf8');
  check(!/assert\s*\([^\n]*(?:configure|add_child|queue_free|save_game|InputMap\.)/.test(text),`No release-stripped assert side effects: ${relative}`);
  check(!/res:\/\/evidence\//.test(text),`No evidence runtime resource: ${relative}`);
  check(!/\bclass_name\s+LayeredBuilding\b/.test(text),`No global prototype class registration: ${relative}`);
  for(const match of text.matchAll(/res:\/\/([^"'\s)]+)/g)){
   const target=match[1];if(target.endsWith('/'))continue;
   check(allowedResourceRoots.some(root=>target===root||target.startsWith(prefix)),`Unexpected cross-campus resource ${target} in ${relative}`);
   check(fs.existsSync(path.join(project,target)),`Unresolved static resource ${target} in ${relative}`);
  }
 }
}
const allowedBuildingAssets=new Set([profile.body_texture,profile.body_texture+'.import',profile.shadow_texture,profile.shadow_clip_texture,manifest.repair_mask,manifest.preserved_foliage_mask,...acceptedGroundFiles].map(x=>path.basename(x)));
for(const file of fs.readdirSync(path.join(campus,'assets/buildings'))){
 if(file.endsWith('.import')&&allowedBuildingAssets.has(file.slice(0,-7)))continue;
 check(allowedBuildingAssets.has(file),`Unused or unaccepted building asset copied into integration: ${file}`);
}
for(const license of ['assets/FONT-LICENSE.txt','assets/NOTO-OFL-LICENSE.txt'])resource(license);
console.log(`BUCT_HAIDIAN_SOURCE: ${checks} checks passed (read-only; no Godot, GPU, or art-acceptance claim)`);

const rongmao=json('rongmao/data/library-profile.json');
const lib=png('rongmao/'+rongmao.body_texture,rongmao.body_png_sha256);
same([lib.width,lib.height,lib.colorType],[1115,1411,6],'Rongmao original true-RGBA body dimensions');
same(rongmao.body_image_to_world.origin,[399,246],'Rongmao corrected original full-PNG origin');
same(rongmao.body_image_to_world.scale,196/1115,'One Rongmao registration scalar');
same(rongmao.interaction_policy,{alpha_select:true,information:true,hide:false,move:false},'Minimal ground does not expose unsupported hide/move UI');
same(rongmao.static_overlap_foot_y,[462],'Only actually relevant nearby tree threshold retained');
for(const [asset,hash] of Object.entries(rongmao.asset_sha256))png('rongmao/'+asset,hash);
check(runtime.includes('_install_rongmao_library')&&runtime.includes('landmark_hit_polys.erase("library")'),'Real body installed and legacy click proxy retired');
check(runtime.includes('CleanShadowUnderlay_library')&&runtime.includes('library_GroundShadow_'),'Old broad shadow and underlay retired together');
check(!/assert\s*\([^\n]*configure/.test(read(prefix+'rongmao/scripts/rongmao_library.gd')),'Rongmao release configure call executes outside assert');
console.log(`BUCT_HAIDIAN_RONGMAO_SOURCE: ${checks} cumulative read-only checks passed`);

const textureGuard=read(prefix+'scripts/imported_texture_validator.gd');
check(textureGuard.includes('ResourceLoader.exists')&&textureGuard.includes('ResourceLoader.load')&&textureGuard.includes('resource is Texture2D'),'Export-safe validator requires an actual imported Texture2D');
check(textureGuard.includes('Vector2i(texture.get_size())!=expected_size'),'Imported texture dimensions checked against registration');
check(textureGuard.includes('FileAccess.file_exists(path) and FileAccess.get_sha256(path)!=expected_sha256'),'Available raw source still requires unchanged SHA');
check(!/FileAccess\.get_sha256/.test(runtime),'Both runtime loaders delegate source-or-import validation centrally');
check((runtime.match(/TEXTURE_VALIDATOR\.validate/g)||[]).length===5,'Ground, masks, bodies, shadow clip and Rongmao assets use central validator');
same(rongmao.asset_imported_size['assets/south-ground.png'],[238,256],'Limited-size imported ground is validated without changing raw registration');
console.log(`BUCT_HAIDIAN_EXPORT_SOURCE: ${checks} cumulative read-only checks passed`);
