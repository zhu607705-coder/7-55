// Read-only provenance and wiring guards for the approved full-map student.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
const project=path.resolve(import.meta.dirname,'..');
const student=path.join(project,'campuses/buct_shared/student');
const read=p=>fs.readFileSync(p,'utf8');
const profile=JSON.parse(read(path.join(student,'data/student-movement-profile.json')));
const provenance=JSON.parse(read(path.join(student,'data/provenance.json')));
let checks=0;
function check(value,message){assert.ok(value,message);checks++;}
for(const output of provenance.outputs){
 const bytes=fs.readFileSync(path.join(student,output.file));
 check(createHash('sha256').update(bytes).digest('hex')===output.sha256,`Approved source bytes: ${output.file}`);
}
for(const [direction,count] of Object.entries({right:8,left:8,down:8,up:6})){
 check(profile.directions[direction].idle.length===1,`Directional idle: ${direction}`);
 check(profile.directions[direction].walk.length===count,`Approved effective frame count: ${direction}`);
}
check(profile.cycle_stride_body_heights===0.65,'Original small-pilot profile is immutable');
for(const campus of ['buct','buct_haidian']){
 const code=read(path.join(project,`campuses/${campus}/scripts/campus_visitor.gd`));
 check(code.includes('character_visual.name="StudentVisual"'),'Actual visitor owns registered visual: '+campus);
 check(code.includes('character_visual.advance_motion(last_motion,delta)'),'Post-collision actual displacement drives visual: '+campus);
 check(code.indexOf('move_and_slide()')<code.indexOf('character_visual.advance_motion(last_motion,delta)'),'Visual follows physical movement: '+campus);
 check(code.includes('profile["cycle_stride_body_heights"]=2.6'),'Map-only stride calibration: '+campus);
 check(code.includes('circle.radius = 3.0')&&code.includes('var speed := 88.0'),'Original feet and speed: '+campus);
 check(!code.includes('draw_style_box(_coat()')&&!code.includes('draw_arc(Vector2(0,1)'),'Old body and default ring removed: '+campus);
}
console.log(`BUCT_STUDENT_SOURCE: ${checks} checks passed (source/wiring only; actual scene assertions are separate)`);
