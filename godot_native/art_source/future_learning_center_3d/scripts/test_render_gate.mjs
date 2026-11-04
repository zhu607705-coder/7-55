import assert from 'node:assert/strict';
import {createRenderGate} from '../web/render_gate.js';
let passed=0;const check=(value,label)=>{assert.ok(value,label);passed++;};const gate=createRenderGate();
check(gate.consume(),'initial load draws');check(!gate.consume(),'idle stops submissions');
for(const cause of ['camera damping','resize','model load','material change','selection highlight','walking','desk lift','return','visibility restore']){gate.invalidate();check(gate.pending,cause+' requests draw');check(gate.consume(),cause+' draws');check(!gate.consume(),cause+' settles to idle');}
for(let i=0;i<10;i++)check(gate.consume(true),'ongoing visible animation draws');check(!gate.consume(),'completed animation returns to idle');gate.invalidate();gate.invalidate();check(gate.consume(),'multiple changes coalesce');check(!gate.consume(),'coalesced changes draw only once');
console.log(JSON.stringify({passed,scope:'Render-request lifecycle only; not GPU timing or browser input acceptance'},null,2));
