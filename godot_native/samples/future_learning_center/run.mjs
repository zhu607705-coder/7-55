import path from 'node:path';
import fs from 'node:fs';
import {spawn} from 'node:child_process';
import {createNativeTestSandbox} from '../../tools/native_test_sandbox.mjs';
const fixture=createNativeTestSandbox(path.resolve(import.meta.dirname,'../..'));
const args=process.argv.slice(2);
const test=args.includes('--test');
const signalTest=args.includes('--signal-test');
const motionTest=args.includes('--motion-test');
const presentationTest=args.includes('--presentation-test');
if(presentationTest&&args.includes('--write-movie')){
 fixture.env.FLC_RECORDING='1';
 // MovieWriter takes its backing resolution from the private project config,
 // not --resolution. Keep this optional recording at the native 960x540 canvas.
 if(fixture.project!==path.resolve(import.meta.dirname,'../..')){
  const config=path.join(fixture.project,'project.godot');
  let source=fs.readFileSync(config,'utf8');
  for(const [key,value] of Object.entries({'viewport_width':960,'viewport_height':540,'window_width_override':960,'window_height_override':540}))
   source=source.replace(new RegExp(`^window/size/${key}=.*$`,'m'),`window/size/${key}=${value}`);
  fs.writeFileSync(config,source);
 }
}
const objectInput=args.includes('--object-input-test')||['FLC_OBJECT_CHECK','FLC_MOTION_CHECK','FLC_SIGNAL_CHECK','FLC_WORKSHOP_CHECK'].some(key=>process.env[key]==='1');
const script=args.includes("--robotics-room-test")?"res://campuses/future_learning_center/tests/test_robotics_room_input.gd":args.includes("--feedback-test")?"res://campuses/future_learning_center/tests/test_feedback_subtitle.gd":args.includes("--locker-test")?"res://campuses/future_learning_center/tests/test_locker_cipher.gd":args.includes("--locker-input-test")?"res://campuses/future_learning_center/tests/test_locker_input.gd":args.includes("--coupling-test")?"res://campuses/future_learning_center/tests/test_coupling_tray.gd":args.includes("--coupling-input-test")?"res://campuses/future_learning_center/tests/test_coupling_input.gd":args.includes("--pantry-test")?"res://campuses/future_learning_center/tests/test_pantry_tray.gd":args.includes("--pantry-input-test")?"res://campuses/future_learning_center/tests/test_pantry_input.gd":presentationTest?'res://campuses/future_learning_center/tests/test_bench_presentation.gd':objectInput?'res://campuses/future_learning_center/tests/test_object_input.gd':motionTest?'res://campuses/future_learning_center/tests/test_motion_puzzles.gd':signalTest?'res://campuses/future_learning_center/tests/test_signal_sync.gd':test?'res://campuses/future_learning_center/tests/test_floor.gd':'res://samples/future_learning_center/play.gd';
console.log(`Future Learning Center room assembly; isolated profile: ${fixture.userData}`);
const child=spawn(process.env.GODOT_BIN||'godot',['--path',fixture.project,'--script',script,...args.filter(x=>!['--robotics-room-test','--feedback-test','--locker-test','--locker-input-test','--coupling-test','--coupling-input-test','--pantry-test','--pantry-input-test','--test','--signal-test','--motion-test','--object-input-test','--presentation-test'].includes(x))],{env:fixture.env,stdio:['inherit','pipe','pipe']});
let diagnostics='';
for(const [stream,dest] of [[child.stdout,process.stdout],[child.stderr,process.stderr]])stream.on('data',chunk=>{diagnostics+=chunk;dest.write(chunk);});
child.on('error',error=>{console.error(error);process.exitCode=2;});
child.on('close',code=>{process.exitCode=code||(/SCRIPT ERROR:|Parse Error:|ERROR:/.test(diagnostics)?1:0);});
