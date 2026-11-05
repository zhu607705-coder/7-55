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
document.activeElement={id:'other-control'};canvas.fire('blur');check([false,false],'canvas-only blur');
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
