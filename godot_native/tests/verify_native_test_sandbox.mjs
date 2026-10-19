import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {createNativeTestSandbox} from '../tools/native_test_sandbox.mjs';

// Use an asset-free project: no production autoload can write before the guard.
const source=fs.mkdtempSync(path.join(os.tmpdir(),'755-isolation-oracle-'));
const project=path.join(source,'godot_native');
fs.mkdirSync(project);fs.mkdirSync(path.join(project,'tests'));fs.mkdirSync(path.join(source,'src'));
fs.writeFileSync(path.join(source,'src','sibling-proof.txt'),'original source sibling');
const config='config_version=5\n[application]\nconfig/name="Native test isolation oracle"\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="SevenFiftyFiveNative"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n';
fs.writeFileSync(path.join(project,'project.godot'),config);
fs.copyFileSync(path.join(import.meta.dirname,'native_test_isolation.gd'),path.join(project,'tests','native_test_isolation.gd'));
fs.writeFileSync(path.join(project,'probe.gd'),`extends SceneTree
const Guard=preload("res://tests/native_test_isolation.gd")
func _initialize() -> void:
 var expected:=OS.get_environment("EXPECTED_ISOLATION")=="true"
 if Guard.is_isolated_save()!=expected: printerr("Isolation guard mismatch");quit(2);return
 if expected:
  if OS.get_user_data_dir()!=OS.get_environment("GODOT_TEST_USER_DATA_DIR"):quit(3);return
  if FileAccess.get_file_as_string("res://../src/sibling-proof.txt")!="original source sibling":quit(4);return
  var file:=FileAccess.open("user://save.json",FileAccess.WRITE)
  file.store_string("isolated fixture bytes")
  file.close()
 print("NATIVE_TEST_ISOLATION_OK")
 quit()
`);
function probe(mutate,expected=true) {
 const fixture=createNativeTestSandbox(project);
 try {
  mutate?.(fixture);
  const result=spawnSync(process.env.GODOT_BIN||'godot',['--headless','--path',fixture.project,'--script','res://probe.gd'],{
   env:{...fixture.env,EXPECTED_ISOLATION:String(expected)},encoding:'utf8',timeout:30000,maxBuffer:1024*1024
  });
  const output=(result.stdout||'')+(result.stderr||'');
  assert.ifError(result.error);assert.equal(result.status,0,output);assert.match(output,/NATIVE_TEST_ISOLATION_OK/);
  const save=path.join(fixture.userData,'save.json');
  if(expected)assert.equal(fs.readFileSync(save,'utf8'),'isolated fixture bytes');
  else assert.equal(fs.existsSync(save),false,'rejected fixture must not create a save');
  assert.equal(fs.readFileSync(path.join(project,'project.godot'),'utf8'),config,'source project settings stay unchanged');
  return fixture.userData;
 } finally {fs.rmSync(fixture.root,{recursive:true,force:true});}
}
try {
 assert.notEqual(probe(),probe(),'fresh runs receive separate save directories');
 if(process.platform==='darwin') {
  probe(f=>delete f.env.GODOT_TEST_USER_DATA_DIR,false);
  probe(f=>f.env.GODOT_TEST_USER_DATA_DIR+='-mismatch',false);
  probe(f=>f.env.GODOT_NATIVE_TEST_NONCE='wrong-nonce',false);
  probe(f=>fs.rmSync(path.join(f.root,'.native-test-fixture.json')),false);
  probe(f=>{
   const file=path.join(f.root,'.native-test-fixture.json');
   const receipt=JSON.parse(fs.readFileSync(file,'utf8'));receipt.mirror_project+='/wrong';fs.writeFileSync(file,JSON.stringify(receipt));
  },false);
 }
 console.log('PASS native save isolation: fresh profiles, source siblings, original config, and macOS receipt rejection');
} finally {fs.rmSync(source,{recursive:true,force:true});}
