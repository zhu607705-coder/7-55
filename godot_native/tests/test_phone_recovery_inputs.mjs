// Input-construction/provenance tests only. No browser, game, or renderer is run.
// Usage: node godot_native/tests/test_phone_recovery_inputs.mjs --fixtures <earned-directory>
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {test} from 'node:test';
import {preparePhoneRecoveryInputs} from '../tools/prepare_phone_recovery_inputs.mjs';

const args=process.argv.slice(2);
if(args.length && (args.length!==2 || args[0]!=='--fixtures')) throw Error('Usage: test_phone_recovery_inputs.mjs --fixtures <earned-directory>');
const fixtureDirectory=path.resolve(args[1] || process.env.GODOT_WEB_FIXTURES_DIR || path.join(import.meta.dirname,'../exports/verification/controller-earned'));
const files={plant:'before_c1_plant_light.json',firstTiyi:'before_c1_tiyi_digit.json',secondTiyi:'before_c2_tiyi_update.json'};
// Capture real campaign output, never manufacture an "earned" positive fixture.
const original=Object.fromEntries(Object.values(files).map(name=>[name,fs.readFileSync(path.join(fixtureDirectory,name))]));
const temporary=fs.mkdtempSync(path.join(os.tmpdir(),'755-phone-recovery-input-test-'));
let sequence=0;
const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
function copyInputs(change=()=>{}) {
  const directory=path.join(temporary,String(++sequence)); fs.mkdirSync(directory);
  for(const [name,bytes] of Object.entries(original)) fs.writeFileSync(path.join(directory,name),bytes);
  const values=Object.fromEntries(Object.entries(files).map(([key,name])=>[key,JSON.parse(original[name])]));
  change(values,directory);
  return directory;
}
function unchanged(directory) {
  for(const [name,bytes] of Object.entries(original)) assert.deepEqual(fs.readFileSync(path.join(directory,name)),bytes,`${name}: original source bytes unchanged`);
}
function pathsChanged(a,b,prefix='') {
  if(JSON.stringify(a)===JSON.stringify(b)) return [];
  if(a && b && typeof a==='object' && typeof b==='object' && !Array.isArray(a) && !Array.isArray(b))
    return [...new Set([...Object.keys(a),...Object.keys(b)])].flatMap(key=>pathsChanged(a[key],b[key],prefix?`${prefix}.${key}`:key));
  return [prefix];
}
await test('phone recovery input construction (not browser acceptance)',async t=>{
  t.after(()=>{
    try { unchanged(fixtureDirectory); }
    finally { fs.rmSync(temporary,{recursive:true,force:true}); }
  });

  await t.test('actual earned inputs produce only the documented legacy compatibility variants',()=>{
    const directory=copyInputs();
    const result=preparePhoneRecoveryInputs(directory);
    assert.equal(result.schema,'755-phone-recovery-inputs-v1');
    assert.deepEqual(JSON.parse(fs.readFileSync(path.join(directory,'phone-recovery-inputs.json'))),result);
    assert.match(result.scope,/not browser, rendering, charging, or navigation acceptance/);
    assert.deepEqual(result.variants.map(item=>item.percent),[0,1]);
    const allowed=new Set(['sourceVersion','state.actOne.tiyiUpdateStage','state.ui.homeDeskReturnScene','state.phoneBattery.percent','state.phoneBattery.lowPowerMode','state.ui.brightness']);
    for(const [key,name] of Object.entries(files)) {
      assert.deepEqual(result.earned[key],{filename:name,bytes:original[name].length,sha256:sha(original[name])});
    }
    for(const item of result.variants) {
      const bytes=fs.readFileSync(path.join(directory,item.filename));
      const value=JSON.parse(bytes), plant=JSON.parse(original[files.plant]);
      assert.equal(item.filename,`compat-c1-battery-${item.percent}-v35.json`);
      assert.equal(item.sourceVersion,35); assert.equal(value.sourceVersion,35);
      assert.equal(value.format,plant.format); assert.equal(value.version,plant.version);
      assert.equal(item.bytes,bytes.length); assert.equal(item.sha256,sha(bytes));
      assert.equal(value.state.phoneBattery.percent,item.percent);
      assert.equal(value.state.phoneBattery.lowPowerMode,true); assert.equal(value.state.ui.brightness,40);
      assert.equal(Object.hasOwn(value.state.actOne,'tiyiUpdateStage'),false);
      assert.equal(Object.hasOwn(value.state.ui,'homeDeskReturnScene'),false);
      assert.match(item.construction,/legacy version\/new-field omissions/);
      assert.ok(pathsChanged(plant,value).every(key=>allowed.has(key)),'no progression, item, page, or other field changes');
      const expected=structuredClone(plant);
      expected.sourceVersion=35; expected.state.phoneBattery.percent=item.percent;
      expected.state.phoneBattery.lowPowerMode=true; expected.state.ui.brightness=40;
      delete expected.state.actOne.tiyiUpdateStage; delete expected.state.ui.homeDeskReturnScene;
      assert.deepEqual(value,expected,'full structural equality outside the explicitly allowed compatibility construction');
    }
    unchanged(directory);
    const outputs=[...result.variants.map(item=>item.filename),'phone-recovery-inputs.json'];
    const before=Object.fromEntries(outputs.map(name=>[name,fs.readFileSync(path.join(directory,name))]));
    assert.deepEqual(preparePhoneRecoveryInputs(directory),result,'rerun produces the same provenance');
    for(const name of outputs) assert.deepEqual(fs.readFileSync(path.join(directory,name)),before[name],`${name}: deterministic bytes`);
    unchanged(directory);
  });

  const negative=[
    ['plant already illuminated','plant',v=>{v.state.flags.plantLit=true;}],
    ['plant already bloomed','plant',v=>{v.state.flags.flowerBloomed=true;}],
    ['plant not watered','plant',v=>{v.state.flags.plantWatered=false;}],
    ['plant not fertilized','plant',v=>{v.state.flags.plantFertilized=false;}],
    ['C1 already checked in','plant',v=>{v.state.flags.checkinDone=true;}],
    ['wrong plant chapter','plant',v=>{v.state.native.chapter=2;}],
    ['wrong plant page','plant',v=>{v.state.native.page='bonsai';}],
    ['plant is not current source version','plant',v=>{v.sourceVersion=35;}],
    ['first digit already awarded','firstTiyi',v=>{v.state.flags.tiyiCountTaken=true;v.state.digits.d2='7';}],
    ['digit seven present despite stale flag','firstTiyi',v=>{v.state.digits.d2='7';}],
    ['wrong first-visit chapter','firstTiyi',v=>{v.state.native.chapter=2;}],
    ['first visit is not current source version','firstTiyi',v=>{v.sourceVersion=35;}],
    ['C2 update already installed','secondTiyi',v=>{v.state.actOne.tiyiUpdateStage='installed';}],
    ['C2 package already acquired','secondTiyi',v=>{v.state.actOne.tiyiUpdateStage='package_ready';}],
    ['C2 exercise already earned','secondTiyi',v=>{v.state.actOne.exerciseStarted=true;}],
    ['C2 weather water already earned','secondTiyi',v=>{v.state.actOne.weatherWaterTaken=true;}],
    ['wrong second-visit chapter','secondTiyi',v=>{v.state.native.chapter=1;}],
    ['wrong second-visit phase','secondTiyi',v=>{v.state.actOne.phase='prologue';}],
    ['second visit is not current source version','secondTiyi',v=>{v.sourceVersion=35;}],
  ];
  for(const key of Object.keys(files)) {
    negative.push([`${key}: wrong portable format`,key,v=>{v.format='not-a-native-save';}]);
    negative.push([`${key}: unsupported portable version`,key,v=>{v.version=2;}]);
    negative.push([`${key}: missing state`,key,v=>{delete v.state;}]);
  }
  for(const [label,key,change] of negative) await t.test(`rejects ${label} before writing variants`,()=>{
    const directory=copyInputs((values,dir)=>{
      change(values[key]); fs.writeFileSync(path.join(dir,files[key]),JSON.stringify(values[key]));
    });
    const inputs=Object.fromEntries(Object.values(files).map(name=>[name,fs.readFileSync(path.join(directory,name))]));
    assert.throws(()=>preparePhoneRecoveryInputs(directory),undefined,label);
    assert.deepEqual(fs.readdirSync(directory).sort(),Object.values(files).sort(),'rejection writes no variants or success receipt');
    for(const [name,bytes] of Object.entries(inputs)) assert.deepEqual(fs.readFileSync(path.join(directory,name)),bytes,'reject does not repair or rewrite its input');
  });
  await t.test('missing or malformed input cannot produce a receipt',()=>{
    for(const mode of ['missing','malformed']) {
      const directory=copyInputs(); const filename=path.join(directory,files.secondTiyi);
      if(mode==='missing') fs.unlinkSync(filename); else fs.writeFileSync(filename,'{invalid json');
      assert.throws(()=>preparePhoneRecoveryInputs(directory));
      assert.equal(fs.existsSync(path.join(directory,'phone-recovery-inputs.json')),false);
      assert.ok(!fs.readdirSync(directory).some(name=>name.startsWith('compat-')));
    }
  });
  console.log('Scope: input construction and SHA provenance only; no browser, rendering, charging, or gameplay acceptance.');
});
