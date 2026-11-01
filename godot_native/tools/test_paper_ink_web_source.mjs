// Source/packaging contract only. Full Godot Web load/input is a separate CI gate.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { inlineButtonMaterial, verifyButtonMaterial } from './web_button_material.mjs';
const project=path.resolve(import.meta.dirname,'..');
const css=fs.readFileSync(path.join(project,'web/button.css'),'utf8');
const html=fs.readFileSync(path.join(project,'web/index.html'),'utf8');
const native=fs.readFileSync(path.join(project,'scripts/ui/paper_ink_material.gd'),'utf8');
let checks=0;const check=(v,label)=>{assert.ok(v,label);checks++;};
check((html.match(/data-skin="paper-ink"/g)||[]).length===3,'All three real boot buttons opt in');
for(const id of ['start-game','retry-game','boot-motion-toggle'])check(new RegExp(`<button[^>]+data-skin="paper-ink"[^>]+id="${id}"`).test(html),'Original action identity retained: '+id);
for(const color of ['f6efe2','1d1a1e','4a4038','6f655a','a43b32'])check(native.includes(color)&&css.includes('#'+color),'Native/Web paper role shares exact value: '+color);
for(const state of [':hover',':active',':focus-visible',':disabled'])check(css.includes(`[data-skin="paper-ink"]${state}`)||css.includes(`[data-skin="paper-ink"]:not(:disabled)${state}`),'Explicit paper state: '+state);
check(css.includes('translate: none'),'Pressed paper paint cannot shift the DOM hit rectangle');
check(css.includes('@media (prefers-reduced-motion: reduce)')&&css.includes('@media (forced-colors: active)'),'Existing accessibility fallbacks retained');
const scope=css.slice(css.indexOf('/* Godot Web entry skin.'));
const transition=scope.match(/\btransition:\s*([^;]+);/)?.[1]||'';
check(transition&&!/(?:^|,)\s*(?:background-color|color)\s/.test(transition),'Paper ink polarity changes never interpolate through unreadable colors');
check(transition.includes('box-shadow 140ms ease')&&transition.includes('border-color 160ms ease'),'Existing paper hover/press shadow and edge feedback remains animated');
check(!/(?:^|[;{])\s*(?:width|height|min-height|padding|gap|font-size|font-weight|font-family)\s*:/m.test(scope),'Opt-in skin cannot change authored geometry or type size');
check(!/url\s*\(/i.test(scope),'No external font, texture or hidden request added');
const temporary=fs.mkdtempSync(path.join(os.tmpdir(),'755-paper-source-'));
try{
 fs.writeFileSync(path.join(temporary,'index.html'),html);inlineButtonMaterial(project,temporary);
 const packed=fs.readFileSync(path.join(temporary,'index.html'),'utf8');
 check(verifyButtonMaterial(project,packed).mode==='inline','Exact source stylesheet is verified in generated HTML');
 assert.throws(()=>verifyButtonMaterial(project,packed.replace('#927c52','#927c53')),/differs from source/);checks++;
}finally{fs.rmSync(temporary,{recursive:true,force:true});}
console.log(JSON.stringify({passed:true,checks,scope:'source packaging, skin scope and contrast tokens; not full Web engine acceptance'}));
