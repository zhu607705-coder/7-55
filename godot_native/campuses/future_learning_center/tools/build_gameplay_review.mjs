import fs from 'node:fs';import path from 'node:path';
const root=path.resolve(import.meta.dirname,'..'),out=path.resolve(process.argv[2]||'');
if(!process.argv[2])throw Error('Pass a review output directory');fs.mkdirSync(out,{recursive:true});fs.mkdirSync(path.join(out,'sprites'),{recursive:true});
for(const name of ['gameplay.html','gameplay.css','gameplay.mjs'])fs.copyFileSync(path.join(root,'review',name),path.join(out,name==='gameplay.html'?'index.html':name));
const props=JSON.parse(fs.readFileSync(path.join(root,'data/object_assets.json'),'utf8')),rooms=JSON.parse(fs.readFileSync(path.join(root,'data/room_assets.json'),'utf8')),manifest={};
const used=['desk','printer_3d','camera_tripod','whiteboard','cabinet','chair_back','tool_cart','parts_rack','potted_plant','desk_divider','monitor_front','soldering_station'];
for(const [id,a] of Object.entries({...Object.fromEntries(used.map(id=>[id,props[id]])),floor:rooms.f2_platform})){
 const b=a.opaqueBounds,file='sprites/'+id+'.png';fs.copyFileSync(path.resolve(root,'../..',a.path.replace('res://','')),path.join(out,file));manifest[id]={file,crop:[b[0],b[1],b[2]-b[0],b[3]-b[1]]};
}
const npc=path.resolve(root,'../../assets/rpg/npcs/canteen/canteen_queue_student_01_front.png');fs.copyFileSync(npc,path.join(out,'sprites/student.png'));manifest.student={file:'sprites/student.png',crop:[0,0,96,128]};
fs.writeFileSync(path.join(out,'sprites.json'),JSON.stringify(manifest));console.log(out);
const captures=process.argv[3],before=process.argv[4],pantryBefore=process.argv[5]||before;
if(captures){
 for(const name of ['floor_2_assembled_preview.png','floor_3_assembled_preview.png','floor_4_assembled_preview.png','f4_light_08.png','f3_light_16.png','f4_light_21.png','f2_electrical.png','f3_pantry.png','f4_focus_a.png','f3_atrium_corridor.png','f2_hall.png','f2_hall_under.png','f2_hall_behind.png'])fs.copyFileSync(path.join(captures,name),path.join(out,name));
 fs.copyFileSync(path.join(captures,'f3_studio_1.png'),path.join(out,'density_after.png'));
 for(const name of ['workshop_room.png','workshop_setup.png','workshop_running.png','workshop_success.png','workshop_gap.png'])fs.copyFileSync(path.join(captures,name),path.join(out,name));
}
if(before){
 fs.copyFileSync(path.join(before,'f3_studio_1.png'),path.join(out,'density_before.png'));
}
if(pantryBefore)fs.copyFileSync(path.join(pantryBefore,'f3_pantry.png'),path.join(out,'pantry_before.png'));
