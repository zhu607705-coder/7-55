// Read-only full-map entry and provenance contracts. No Godot or image mutation.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
const project=path.resolve(import.meta.dirname,'..');
const prefix='campuses/buct_changping/';
const campus=path.join(project,prefix);
const read=p=>fs.readFileSync(path.join(project,p),'utf8');
const manifest=JSON.parse(read(prefix+'provenance.json'));
const route=JSON.parse(read(prefix+'data/playable_route.json'));
const layers=JSON.parse(read(prefix+'data/layers.json'));
let checks=0;
const check=(ok,label)=>{assert.ok(ok,label);checks++;};
for(const item of manifest.preserved_sources)check(createHash('sha256').update(fs.readFileSync(path.join(campus,item.file))).digest('hex')===item.sha256,'Original registered source bytes: '+item.file);
check(route.canvas_size.join(',')==='950,1656'&&layers.canvas_size.join(',')==='950,1656','Portrait full map coordinate system');
check(route.spawn.join(',')==='515,1510'&&route.route_waypoints.length===41,'Original entrance and bounded route');
check(route.landmarks.map(x=>x.id).join(',')==='south_gate,main_building,library','Original three POIs');
check(layers.objects.length===53&&manifest.genuine_buildings_added===0,'Honest legacy UV-group count, no invented true building completion');
const chooser=read('scripts/entry.gd');
for(const id of ['ContinueStory','OpenBuctCampus','OpenBuctHaidian','OpenBuctChangping'])check(chooser.includes(`name="${id}"`),'Distinct actual entry: '+id);
check(chooser.includes('_open(CHANGPING_SCENE)')&&chooser.includes('if opening:return'),'Independent guarded Changping scene transition');
const runtime=read(prefix+'scripts/playable_campus.gd');
check(!runtime.includes('content_scale_size='),'Campus does not mutate global viewport scaling');
check(runtime.includes('res://scenes/entry.tscn')&&runtime.includes('if leaving:return'),'Idempotent return to existing chooser');
check(runtime.includes('owned_actions.append(action)')&&runtime.includes('InputMap.erase_action(action)'),'Owned-only action lifecycle');
check(runtime.includes('if InputMap.has_action(action):continue'),'Borrowed action events/deadzone remain untouched');
check(runtime.includes('Input.action_release(action)')&&runtime.includes('NOTIFICATION_APPLICATION_FOCUS_OUT'),'Held input released on focus loss and exit');
check(runtime.includes('InputEventScreenTouch')&&runtime.includes('not map_area.has_point(screen_position)'),'Touch input shares bounded navigation');
check(runtime.includes('ScrollContainer.new()')&&runtime.includes('STUDENT_PIN_LAYOUT.place'),'Mobile information and student-safe screen pins');
check(runtime.includes('SubViewport.UPDATE_ONCE'),'Static paving viewport is cached after initial draw');
check(!/State\.|save_game\(|user:\/\//.test(runtime),'Campus owns no story or save mutation');
check(!runtime.includes('room')&&!runtime.includes('interior'),'No indoor dependency');
function walk(dir){return fs.readdirSync(dir,{withFileTypes:true}).flatMap(f=>f.isDirectory()?walk(path.join(dir,f.name)):[path.join(dir,f.name)]);}
for(const file of walk(campus)){
 if(/\.(gd|tscn|gdshader)$/.test(file))for(const match of fs.readFileSync(file,'utf8').matchAll(/res:\/\/([^"'\s)]+)/g)){
  if(match[1].endsWith('/'))continue;
  check(fs.existsSync(path.join(project,match[1])),'Resolved resource '+match[1]);
 }
 check(!/\/\.godot\/|\.zip$|\.b64$|\/evidence\//.test(file),'No runtime delivery/cache transport files');
}
console.log(`BUCT_CHANGPING_SOURCE: ${checks} checks passed (source only)`);
