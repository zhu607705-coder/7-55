import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(path.join(root,p))).digest('hex');
const prefix='godot_native/scripts/media/c3_rain_rescue_native/';
const uiFontDependency='res://scripts/ui/native_typography.gd';
const manifest=JSON.parse(read('godot_native/assets/native/qizhen_rain_rescue/integration_provenance.json'));
let checks=0;
function check(ok,label){assert.ok(ok,label);checks++;}
for(const item of manifest.records){
 check(hash(item.source)===(item.sha256??item.source_sha256),`review upstream change before updating production: ${item.source}`);
 check(hash(item.production)===(item.sha256??item.production_sha256),`review production change and update provenance: ${item.production}`);
}
const sourceTimeline=read('samples/qizhen-rain-rescue-native/scripts/rescue_timeline.gd');
const timeline=read(prefix+'timeline.gd');
check(timeline.slice(timeline.indexOf('static func phase_at')).trim()===sourceTimeline.slice(sourceTimeline.indexOf('static func phase_at'),sourceTimeline.indexOf('\nfunc pose()')).trim(),'all authored static pose and contact geometry retained');
const sourceRenderer=read('samples/qizhen-rain-rescue-native/scripts/rain_rescue_preview.gd');
const renderer=read(prefix+'renderer.gd');
check(renderer.slice(renderer.indexOf('func _screen('),renderer.indexOf('\t# Production owns')).trim()===sourceRenderer.slice(sourceRenderer.indexOf('func _screen('),sourceRenderer.indexOf('\t# Constant, opaque HUD bands')).replaceAll('timeline.elapsed','elapsed').trim(),'sample drawing and caption geometry retained without preview UI');
check(!/FileAccess\.file_exists\([^\n]*\.png/.test(renderer),'imported textures must use ResourceLoader so remapped PCK assets load');
for(const module of ['renderer.gd','timeline.gd','pose_geometry.gd']){
 const text=read(prefix+module);
 for(const forbidden of ['State.','preview_finished','func replay(','func skip(','func advance(','func finish(','func _process(','func _gui_input(','func _unhandled','Input.','Time.','get_process_delta_time','event.emit','VideoStreamPlayer']){
  check(!text.includes(forbidden),`${module} cannot own ${forbidden}`);
 }
 for(const match of text.matchAll(/(?:preload|load)\("(res:\/\/[^"\n]+)"\)/g)){
  const target=match[1];
  // The renderer alone may use the shared presentation-only font provider.
  // This exact exception does not admit other UI, state, input or clock modules.
  const sharedFont=module==='renderer.gd'&&target===uiFontDependency;
  if(sharedFont)check(text.split(uiFontDependency).length===2&&text.split(`font=preload("${uiFontDependency}").body_font()`).length===2,'shared dependency is exactly one common-font assignment');
  check(sharedFont||target.startsWith('res://scripts/media/c3_rain_rescue_native/')||target.startsWith('res://assets/native/qizhen_rain_rescue/'),`namespaced runtime dependency ${target}`);
  check(fs.existsSync(path.join(root,'godot_native',target.slice(6))),`portable runtime resource ${target}`);
 }
}
check(renderer.includes('func caption_text() -> String: return _caption(elapsed)')&&renderer.includes('if not external_caption:'),'compact wrapper exposes unchanged source caption and suppresses only duplicate renderer text');
const session=read('godot_native/scripts/media/c3_rain_rescue_session.gd');
const model=read('godot_native/scripts/media/c3_rain_rescue_model.gd');
check(model.includes('const WATCHDOG_MS: float=9000.0')&&model.includes('const VIDEO_DURATION_MS: float=5875.0'),'original video guards preserved');
check(model.includes(`const NATIVE_CINEMATIC_DURATION_MS: float=${manifest.nativeDurationMs}.0`),'native duration matches provenance');
check(timeline.includes(`const DURATION: float=${manifest.nativeSourceDurationMs/1000}.0`),'source duration matches renderer timeline');
check(model.includes(`const NATIVE_CINEMATIC_SOURCE_START_MS: float=${manifest.nativeSourceOffsetMs}.0`)&&manifest.nativeDurationMs+manifest.nativeSourceOffsetMs===manifest.nativeSourceDurationMs,'production continuation skips exactly the wind/fall introduction');
check(read('godot_native/scripts/media/c3_rain_rescue.gd').includes('native_renderer.present(Model.native_source_ms(float(snap.cinematicMs))'),'production renderer always receives the post-capsize source clock');
check(session.includes('_cinematic_mode=="video" and now-_cinematic_started_ms>=Model.WATCHDOG_MS'),'video watchdog applies only to legacy video');
check(session.includes('Time.get_ticks_msec()-_cinematic_started_ms<Model.NATIVE_CINEMATIC_DURATION_MS'),'native early callback cannot shorten duration');
console.log(`Rain rescue native source: ${checks} checks passed`);
