// Source-derived icon checks. A renderer agreeing with its own registry is not
// evidence that it preserved the Web artwork. No browser/visual claim here.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
const root=path.resolve(import.meta.dirname,'../..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
let checks=0;
const equal=(a,b,label)=>{checks++;assert.deepEqual(a,b,label);};
const has=(text,part,label)=>{checks++;assert.ok(text.includes(part),label);};
const hash=p=>createHash('sha256').update(fs.readFileSync(path.join(root,p))).digest('hex');
const web=read('src/components/PixelIcon.tsx');
const native=read('godot_native/scripts/ui/phone_chrome.gd');
// This source registry is literal strings/arrays/objects, never evaluated code.
const literal=web.match(/const ICONS[^=]*=\s*(\{[\s\S]*?\n\});/)[1]
  .replace(/\/\/[^\n]*/g,'').replace(/([{,]\s*)(\w+)\s*:/g,'$1"$2":').replace(/,(\s*[}\]])/g,'$1');
const sourceMaps=JSON.parse(literal);
const nativeMaps=JSON.parse(native.match(/^const PIXEL_ICONS\s*:?=\s*(\{.*\})$/m)[1]);
equal(Object.keys(sourceMaps).sort(),Object.keys(nativeMaps).sort(),'every source pixel icon, and no substitute');
equal(Object.keys(sourceMaps).length,68,'all68 authored pixel maps covered');
for(const [id,map] of Object.entries(sourceMaps)){
  equal(nativeMaps[id].rows,map.rows,`${id}: exact source pixels`);
  equal(nativeMaps[id].palette,map.palette,`${id}: exact source palette`);
}
const imports=Object.fromEntries([...web.matchAll(/import (\w+) from "(\.\.\/assets\/[^"\n]+)";/g)].map(m=>[m[1],path.posix.normalize('src/components/'+m[2])]));
const rasterBody=web.match(/const THEATER_RASTER_ICONS[^=]*=\s*\{([\s\S]*?)\n\};/)[1];
const nativeRasters=JSON.parse(native.match(/const RASTER_ICONS\s*:?=\s*(\{[\s\S]*?\n\})/)[1].replace(/,(\s*})/g,'$1'));
const rasters=[...rasterBody.matchAll(/(\w+):\s*(\w+)/g)];
equal(rasters.length,11,'all11 raster source assets covered');
for(const [,id,variable] of rasters)equal(hash('godot_native/'+nativeRasters[id].replace('res://','')),hash(imports[variable]),`${id}: byte-identical source PNG`);
equal(hash('src/assets/ui/zjuding.png'),hash('godot_native/assets/ui/zjuding.png'),'launcher uses untouched original Zjuding image');
const home=read('src/styles/scenes/p13-phone-home.css');
const interlude=read('src/styles/chapter-three-interlude.css');
const clock=read('src/styles/scenes/p19-clock.css');
const shell=read('src/styles/shell.css');
const pages=read('godot_native/scripts/ui/phone_pages.gd');
const helper=read('godot_native/scripts/ui/phone_launcher_icons.gd');
const symbols=read('godot_native/scripts/ui/native_symbol_icon.gd');
const cssRule=(css,selector)=>{
  const escaped=selector.replace(/[.*+?^${}()|[\]\\]/g,'\\$&');
  const found=css.match(new RegExp('(?:^|\\n)'+escaped+'\\s*\\{([^}]+)\\}'));
  assert.ok(found,`source CSS exists: ${selector}`);
  return Object.fromEntries([...found[1].matchAll(/([\w-]+)\s*:\s*([^;]+);/g)].map(m=>[m[1],m[2].trim()]));
};
const svg=name=>read(`godot_native/ui_assets/phone_icons/${name}.svg`);
const attrs=(name,id)=>{
  const tag=svg(name).match(new RegExp('<[^>]*\\bid="'+id+'"[^>]*>'));
  assert.ok(tag,`source part exists: ${name}/${id}`);
  return Object.fromEntries([...tag[0].matchAll(/([\w-]+)="([^"]*)"/g)].map(m=>[m[1],m[2]]));
};
const number=(value)=>Number.parseFloat(value);
const dimensions=(name,id,css,selector)=>{
  const rule=cssRule(css,selector),part=attrs(name,id);
  for(const field of ['width','height'])equal(number(part[field]),number(rule[field]),`${name}/${id}: source ${field}`);
};
dimensions('messages','bubble-one',home,'.phone .bubble.one');
dimensions('messages','bubble-two',home,'.phone .bubble.two');
for(let n=1;n<=4;n++)equal([attrs('messages',`eye-${n}`).width,attrs('messages',`eye-${n}`).height],['4','4'],'original4px green chat eyes');
for(const [id,selector] of [['body','body'],['arm-1','arm1'],['arm-2','arm2'],['leg-1','leg1'],['leg-2','leg2']])dimensions('sports',id,home,`.phone .runner .${selector}`);
for(const color of ['#e88a9f','#7fb0e8','#8fce7c','#e8a05f','#f5c542']){
  has(cssRule(home,'.phone .photo-flower').background,color,'flower source color');
  has(svg('album'),`stop-color="${color}"`,'same source flower color in SVG');
}
dimensions('recovery','document',interlude,'.recovery-document');
dimensions('recovery','clock',interlude,'.recovery-clock');
dimensions('voice','microphone',interlude,'.voice-microphone');
for(let n=1;n<=3;n++)equal(number(attrs('voice',`wave-${n}`).height),number(cssRule(interlude,`.voice-icon-wave i:nth-child(${n})`).height),'original microphone wave height');
equal(attrs('clock','hour').transform,'rotate(330 17 17)','source330deg hour hand, not generic3oclock');
equal(attrs('clock','minute').transform,'rotate(237 17 17)','source237deg minute hand');
has(clock,'rotate(330deg)','source clock hour evidence');has(clock,'rotate(237deg)','source clock minute evidence');
for(const color of ['#f0d54e','#101820'])has(svg('clock'),color,'source yellow/dark clock colors');
for(const [id,color] of Object.entries({wechat:'61b58c',tiyi:'e8893f',zjuding:'ece9df',settings:'777989',photos:'ece9df',timeline_recovery:'173948',voice_memos:'0a0a0c',cc98:'4d7ed9',control_center:'756aa9',clock:'20272f'}))
  has(helper,`"${id}":Color("${color}")`,`${id}: source tile color, not uniform dark replacement`);
equal(cssRule(shell,'.cc-wifi-icon i:nth-child(1)').width,'22px','source WiFi outer arc');
equal(cssRule(shell,'.cc-wifi-icon i:nth-child(2)').width,'13px','source WiFi inner arc');
equal(cssRule(shell,'.cc-wifi-icon i:nth-child(3)')['border-radius'],'0','source WiFi dot is square');
has(symbols,'Rect2(8,9,22,18),Rect2(12.5,15,13,11)','WiFi port accounts for2px CSS containing border');
has(symbols,'DOT_RECT := Rect2(16.5,23,5,5)','WiFi source square dot bounds');
has(pages,'Symbols.add_wifi(button,Rect2(9,10,34,34))','network uses specific role renderer');
has(pages,'["≋","振动"','vibration keeps its own source symbol');
assert.ok(!pages.includes('_label(button,"≋",Rect2(11,8,30,25)'),'old WiFi alias must not return');checks++;
has(pages,'wordmark.autowrap_mode=TextServer.AUTOWRAP_OFF','CC98 wordmark stays unbroken');
console.log(`PHONE_ICON_SOURCE: ${checks} checks;0 failures (source/geometry/assets only; not rendered visual proof)`);
