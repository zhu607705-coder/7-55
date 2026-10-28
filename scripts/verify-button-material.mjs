import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import ts from 'typescript';
import { inlineButtonMaterial, verifyButtonMaterial } from '../godot_native/tools/web_button_material.mjs';
const root=process.cwd(), project=path.join(root,'godot_native');
const css=fs.readFileSync(path.join(project,'web/button.css'),'utf8');
assert(!/::(?:before|after)/.test(css),'No inset overlay');
for(const variant of ['primary','tertiary','ghost','text']) assert(css.includes(`[data-variant="${variant}"]`));
assert(css.includes('--button-u: calc(var(--button-label-size) / 14)'));
assert(css.includes('transform 120ms')&&css.includes('box-shadow 140ms')&&css.includes('color 160ms'));
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'button-material-'));
try {
 fs.writeFileSync(path.join(temp,'index.html'),'<link rel="stylesheet" href="button.css">');
 inlineButtonMaterial(project,temp);
 const output=fs.readFileSync(path.join(temp,'index.html'),'utf8');
 assert.equal(verifyButtonMaterial(project,output).source,'web/button.css');
 assert.throws(()=>verifyButtonMaterial(project,output.replace('#404859','#404858')));
 assert.throws(()=>verifyButtonMaterial(project,output+output));
 assert.throws(()=>inlineButtonMaterial(project,temp));
} finally {fs.rmSync(temp,{recursive:true,force:true});}
const coverage=JSON.parse(fs.readFileSync('docs/ui/button-coverage.json','utf8'));
let nativeSites=0, wrappedSites=0;
function walk(dir){for(const entry of fs.readdirSync(dir,{withFileTypes:true})){const file=path.join(dir,entry.name);if(entry.isDirectory())walk(file);else if(file.endsWith('.tsx')){const source=ts.createSourceFile(file,fs.readFileSync(file,'utf8'),ts.ScriptTarget.Latest,true,ts.ScriptKind.TSX);function visit(node){if(ts.isJsxOpeningElement(node)||ts.isJsxSelfClosingElement(node)){const tag=node.tagName.getText(source);if(tag==='button')nativeSites++;if(tag==='Button')wrappedSites++;}ts.forEachChild(node,visit)}visit(source);}}}
walk('src');
assert.equal(nativeSites,coverage.filter(x=>x.decision==='scene-object').length,'Every unstyled native button is explicitly inventoried (including implementation)');
assert.equal(wrappedSites,353,'352 migrated sites and the chapter introduction');
const shell=fs.readFileSync('godot_native/web/index.html','utf8');
for(const id of ['start-game','retry-game','boot-motion-toggle'])assert.match(shell,new RegExp(`<button class="tactile-button"[^>]*id="${id}"[^>]*type="button"`));
console.log(`Button material PASS: source inline/hash/tamper, ${wrappedSites} shared controls, ${nativeSites} inventoried objects/implementation, three production shell controls`);
