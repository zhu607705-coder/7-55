#!/usr/bin/env node
// Local QA only; never writes the formal game's user:// or modifies source saves.
import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {createNativeTestSandbox} from './native_test_sandbox.mjs';
const project=path.resolve(import.meta.dirname,'..');
const binary=process.env.GODOT_BIN||'godot';
const version=spawnSync(binary,['--version'],{encoding:'utf8'});
if(version.status!==0||!/^4\.7\.1\./m.test(version.stdout||''))throw new Error('Use the repository-pinned official Godot 4.7.1 via GODOT_BIN.');
if(!fs.existsSync(path.join(project,'data/source/chapter4-755.content.json')))throw new Error('Run node godot_native/tools/sync_source.mjs first.');
const fixture=createNativeTestSandbox(project,'755-c4-feedback-');
const env={...fixture.env,XDG_RUNTIME_DIR:path.join(fixture.root,'runtime')};
fs.chmodSync(env.XDG_RUNTIME_DIR,0o700);
let exitCode=0;
try{
 const run=args=>{const result=spawnSync(binary,['--path',fixture.project,...args],{env,stdio:'inherit'});if(result.error)throw result.error;return result.status??1;};
 exitCode=run(['--headless','--editor','--import','--quit']);
 if(!exitCode){
  if(process.argv.includes('--test'))exitCode=run(['--headless','--script','res://tests/test_pr_integration_chapter4_time_feedback.gd']);
  else{
   const index=process.argv.indexOf('--capture');
   if(index>=0){if(!process.argv[index+1])throw new Error('--capture needs an output directory');env.C4_FEEDBACK_CAPTURE_DIR=path.resolve(process.argv[index+1]);}
   const movie=process.argv.indexOf('--movie');let extra=[];
   if(movie>=0){if(!process.argv[movie+1])throw new Error('--movie needs an .avi output path');env.C4_FEEDBACK_AUTOPLAY='1';env.C4_FEEDBACK_REQUIRE_GRAPHICAL='1';extra=['--write-movie',path.resolve(process.argv[movie+1]),'--fixed-fps','60'];}
   exitCode=run([...extra,'res://tests/chapter4_time_feedback_preview.tscn']);
  }
 }
}finally{fs.rmSync(fixture.root,{recursive:true,force:true});}
process.exitCode=exitCode;
