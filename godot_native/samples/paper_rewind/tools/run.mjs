#!/usr/bin/env node
// Independent source/test/export harness. Never opens the formal project's save.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';

const project = path.resolve(import.meta.dirname, '..');
const engine = process.env.GODOT_BIN || 'godot';
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const provenance = JSON.parse(fs.readFileSync(path.join(project, 'assets/provenance.json'), 'utf8'));
for (const asset of provenance.assets) {
  if (hash(fs.readFileSync(path.join(project, asset.path))) !== asset.sha256) throw Error(`Asset hash mismatch: ${asset.path}`);
}
const version = spawnSync(engine, ['--version'], {encoding: 'utf8'});
if (version.status !== 0 || !version.stdout.trim().startsWith('4.7.1.')) throw Error(`Godot 4.7.1 is required: ${version.stdout || version.stderr}`);
const command = process.argv[2] || '--test';
if (!['--test', '--web'].includes(command)) throw Error('Usage: node tools/run.mjs [--test | --web OUTPUT_DIRECTORY]');
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), '755-paper-rewind-'));
const copy = path.join(temporary, 'project');
fs.cpSync(project, copy, {recursive: true, filter: source => !['.godot', 'build', '.git'].includes(path.basename(source)) && !['.import','.uid'].includes(path.extname(source))});
const env = {...process.env};
for (const [key, folder] of Object.entries({XDG_DATA_HOME:'data',XDG_CONFIG_HOME:'config',XDG_CACHE_HOME:'cache',XDG_STATE_HOME:'state'})) {
  env[key] = path.join(temporary, folder); fs.mkdirSync(env[key], {recursive:true});
}
const sentinelDir = path.join(env.XDG_DATA_HOME, 'SevenFiftyFiveNative');
fs.mkdirSync(sentinelDir, {recursive:true});
const sentinels = ['save.json','save.previous.json','save.json.tmp'].map(name => {
  const file = path.join(sentinelDir, name), bytes = Buffer.from(`formal-save-sentinel:${name}`);
  fs.writeFileSync(file, bytes); return {file, bytes};
});
const report = {engine:version.stdout.trim(),headless:true,visualAcceptance:false,physicalMobile:false,stages:[],assets:provenance.assets};
function run(label, args) {
  const r = spawnSync(engine, ['--headless','--audio-driver','Dummy','--path',copy,...args], {env,encoding:'utf8',timeout:180000,maxBuffer:8*1024*1024});
  const output = (r.stdout||'')+(r.stderr||'');
  const passed = !r.error && r.status===0 && !/(?:^|\n)ERROR:|SCRIPT ERROR:|Parse Error:|TEST FAILED|ASSERTION FAILED/.test(output);
  report.stages.push({label,passed,status:r.status,output});
  console.log(`${passed?'PASS':'FAIL'} ${label}`);
  if (!passed) { console.error(output); throw Error(`${label} failed`); }
}
try {
  run('Fresh standalone import', ['--editor','--import','--quit']);
  for (const test of ['test_paper_rewind.gd','test_paper_rewind_input.gd','test_paper_rewind_two_hands.gd']) run(test, ['--script',`res://tests/${test}`]);
  run('Ordinary standalone startup', ['--quit-after','10']);
  for (const {file,bytes} of sentinels) if (!fs.readFileSync(file).equals(bytes)) throw Error(`Formal save sentinel changed: ${path.basename(file)}`);
  report.formalSaveSentinelsUnchanged = true;
  if (command === '--web') {
    const output = path.resolve(process.argv[3] || path.join(project,'build/web'));
    const template = process.env.GODOT_WEB_TEMPLATE;
    if (!template || !fs.existsSync(template)) throw Error('Set GODOT_WEB_TEMPLATE to the matching 4.7.1 web_nothreads_release.zip');
    fs.mkdirSync(output,{recursive:true});
    const preset = path.join(copy,'export_presets.cfg');
    fs.writeFileSync(preset,fs.readFileSync(preset,'utf8').replace('custom_template/release=""',`custom_template/release=${JSON.stringify(path.resolve(template))}`));
    run('Standalone Godot Web export (not browser acceptance)', ['--export-release','Web sample',path.join(output,'index.html')]);
    for (const name of ['index.html','index.js','index.wasm','index.pck']) if (!fs.existsSync(path.join(output,name))) throw Error(`Missing exported file: ${name}`);
    report.webExport = output;
  }
  fs.mkdirSync(path.join(project,'build'),{recursive:true});
  fs.writeFileSync(path.join(project,'build/test-report.json'),JSON.stringify(report,null,2)+'\n');
  console.log(`Standalone test PASS; visual/browser/physical-device acceptance remains unverified.`);
} finally {
  fs.rmSync(temporary,{recursive:true,force:true});
}
