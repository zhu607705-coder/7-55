import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
const path=new URL('../scripts/platform/web_platform.gd',import.meta.url);
const gd=fs.readFileSync(path,'utf8');
const match=gd.match(/JavaScriptBridge\.eval\("""([\s\S]*?)""", true\)/);
assert(match,'actual production bridge inline script');
// Decode GDScript's escaped backslashes. This source has no other escaped
// string sequences in its triple-quoted JavaScript program.
const script=match[1].replaceAll('\\\\','\\');
class Target {
 constructor(){this.listeners=new Map();}
 addEventListener(name,fn){if(!this.listeners.has(name))this.listeners.set(name,new Set());this.listeners.get(name).add(fn);}
 removeEventListener(name,fn){this.listeners.get(name)?.delete(fn);}
 fire(name){for(const fn of this.listeners.get(name)||[])fn({target:this});}
}
const window=new Target();const canvas=new Target();const document=new Target();
canvas.parentElement={};
let focused=true;document.hidden=false;document.activeElement=canvas;document.hasFocus=()=>focused;
document.getElementById=id=>id==='canvas'?canvas:null;canvas.focus=()=>{document.activeElement=canvas;};
const context={window,document,setTimeout,clearTimeout,console,Object,JSON,Uint8Array,ArrayBuffer};
vm.runInNewContext(script,context,{filename:'actual-web-platform-bridge.js'});
const host=window.__GODOT_755_HOST__;const observations=[];
host.observeVisibility((hidden,focus)=>observations.push([hidden,focus]));
let checks=0;
const check=(expected,label)=>{checks++;assert.deepEqual(observations.at(-1),expected,label);};
check([false,true],'initial canvas focus');
window.fire('blur');check([false,false],'window blur while document stays visible');
for(let i=0;i<3;i++){window.fire('blur');check([false,false],'duplicate window blur');}
document.hidden=true;document.fire('visibilitychange');check([true,false],'hidden and blurred');
focused=true;window.fire('focus');check([true,true],'window focus cannot clear hidden');
document.hidden=false;document.fire('visibilitychange');check([false,true],'visible after window focus');
document.activeElement={id:'other-control'};canvas.fire('blur');await Promise.resolve();check([false,false],'settled canvas-only blur');
window.fire('focus');check([false,false],'window focus cannot override another DOM control');
document.activeElement=canvas;focused=true;canvas.fire('focus');check([false,true],'canvas re-entry');
for(let i=0;i<5;i++){
 focused=false;window.fire('blur');document.hidden=true;document.fire('visibilitychange');check([true,false],'repeat hide');
 document.hidden=false;document.fire('visibilitychange');check([false,false],'visible but still unfocused');
 focused=true;window.fire('focus');check([false,true],'repeat foreground');
}
focused=false;window.fire('blur');check([false,false],'mobile app blur');
focused=true;document.hidden=false;canvas.fire('pointerdown');check([false,true],'canvas gesture recovers omitted window focus');
focused=false;window.fire('blur');focused=true;canvas.fire('touchstart');check([false,true],'touch recovery uses original input route');
focused=false;window.fire('blur');focused=true;canvas.fire('keydown');check([false,true],'keyboard recovery uses original input route');
document.hidden=true;canvas.fire('pointerdown');check([false,true],'hidden canvas gesture does not publish a false foreground');
document.fire('visibilitychange');check([true,true],'hidden remains explicit');
const length=observations.length;host.dispose();host.dispose();window.fire('blur');canvas.fire('blur');document.fire('visibilitychange');canvas.fire('pointerdown');canvas.fire('touchstart');canvas.fire('keydown');
checks++;assert.equal(observations.length,length,'dispose removes every lifecycle listener');
checks++;assert.equal(window.__GODOT_755__,undefined,'disposed snapshot access removed');
for(const target of [window,document,canvas]){
 checks++;assert.equal([...target.listeners.values()].reduce((total,listeners)=>total+listeners.size,0),0,'repeated dispose leaves no lifecycle listeners');
}
const output={checks,failures:0,kind:'Actual production JS bridge run in isolated DOM event fixture, not a WebGL gameplay test',observations};
if (process.env.PAUSE_BRIDGE_REPORT) fs.writeFileSync(process.env.PAUSE_BRIDGE_REPORT,JSON.stringify(output,null,2));
console.log(`BROWSER_FOCUS_BRIDGE: ${checks} checks; 0 failures`);

// Engine IME and virtual-keyboard focus ownership regressions.
{
// Execute the shipped JS bridge with browser-like focus ordering. No game save writes.

const source = fs.readFileSync(new URL('../scripts/platform/web_platform.gd', import.meta.url), 'utf8');
const literal = source.split('JavaScriptBridge.eval("""')[1].split('""", true)')[0];
const script = literal.replace(/\\(u[0-9a-fA-F]{4}|U[0-9a-fA-F]{6}|[\\"'nrtbfv0])/g, (_, escape) => {
  if (escape[0] === 'u' || escape[0] === 'U') return String.fromCodePoint(parseInt(escape.slice(1), 16));
  return ({ '\\': '\\', '"': '"', "'": "'", n: '\n', r: '\r', t: '\t', b: '\b', f: '\f', v: '\v', 0: '\0' })[escape];
});
class Target {
  listeners = new Map();
  addEventListener(name, fn) { if (!this.listeners.has(name)) this.listeners.set(name, new Set()); this.listeners.get(name).add(fn); }
  removeEventListener(name, fn) { this.listeners.get(name)?.delete(fn); }
  emit(name, event = {}) { for (const fn of this.listeners.get(name) || []) fn(event); }
  get listenerCount() { return [...this.listeners.values()].reduce((sum, set) => sum + set.size, 0); }
}
const window = new Target(), document = new Target(), canvas = new Target();
const parent = {}, body = {}, outside = new Target();
let focused = true, focusCalls = 0;
canvas.parentElement = parent;
canvas.focus = () => { focusCalls++; document.activeElement = canvas; canvas.emit('focus'); document.emit('focusin'); };
document.activeElement = canvas; document.hidden = false; document.hasFocus = () => focused;
document.body = { appendChild() {} };
document.getElementById = id => id === 'canvas' ? canvas : null;
document.createElement = () => Object.assign(new Target(), { remove() {} });
const states = [];
vm.runInNewContext(script, { window, document, Promise, setTimeout, clearTimeout });
const bridge = window.__GODOT_755_HOST__;
bridge.observeVisibility((hidden, active) => states.push({ hidden, active }));
const latest = () => states.at(-1);
const settle = async () => { await Promise.resolve(); await Promise.resolve(); };
const ime = Object.assign(new Target(), { parentElement: parent, style: {}, disabled: false,
  matches: selector => selector === 'div.ime[contenteditable="true"]' });
const vk = Object.assign(new Target(), { parentElement: parent, style: { position: 'absolute', zIndex: '-1' }, disabled: false,
  matches: selector => selector === 'input:not([type="file"]), textarea' });
async function transfer(target) {
  document.activeElement = body;
  canvas.emit('blur'); document.emit('focusout');
  document.activeElement = target;
  document.emit('focusin');
  await settle();
}
assert.deepEqual(latest(), { hidden: false, active: true });
for (const target of [ime, vk, canvas, ime]) {
  const start = states.length;
  await transfer(target);
  assert(states.slice(start).every(state => state.active && !state.hidden), 'engine text handoff never suspends, even transiently');
}
const beforeInput = focusCalls;
canvas.emit('pointerdown'); canvas.emit('keydown'); canvas.emit('touchstart');
assert.equal(document.activeElement, ime, 'canvas recovery must not steal active IME focus');
assert.equal(focusCalls, beforeInput);
// Repeated IME timer focus and ordinary key/wheel events must remain admitted.
for (let i = 0; i < 20; i++) { document.emit('focusin'); assert.equal(latest().active, true); }
await transfer(outside);
assert.equal(latest().active, false, 'unrelated DOM control still suspends');
canvas.emit('pointerdown');
assert.equal(latest().active, true, 'ordinary canvas input recovers');
await transfer(Object.assign({}, vk, { parentElement: {} }));
assert.equal(latest().active, false, 'foreign keyboard element is not an engine input');
await transfer(Object.assign({}, vk, { disabled: true }));
assert.equal(latest().active, false, 'disabled virtual keyboard cannot own focus');
await transfer(ime);
focused = false; window.emit('blur');
assert.equal(latest().active, false, 'leaving the window pauses even with IME active');
focused = true; window.emit('focus');
assert.equal(latest().active, true, 'returning to IME recovers');
document.hidden = true; document.emit('visibilitychange');
assert.equal(latest().hidden, true, 'hidden tab pauses');
document.hidden = false; document.emit('visibilitychange');
assert.equal(latest().active, true);
// Browser may focus body temporarily with no successor element.
await transfer(body);
assert.equal(latest().active, false, 'unowned focus does not stay incorrectly admitted');
canvas.emit('pointerdown');
canvas.emit('blur');
const beforeDispose = states.length;
bridge.dispose(); await settle();
assert.equal(states.length, beforeDispose, 'queued callbacks cannot run after disposal');
assert.equal(document.listenerCount + window.listenerCount + canvas.listenerCount, 0, 'all installed focus listeners are disposed');
console.log('Web text focus: internal IME/VK handoffs, recovery, window/tab exit and disposal passed');

}
