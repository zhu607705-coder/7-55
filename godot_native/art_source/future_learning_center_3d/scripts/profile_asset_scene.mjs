import fs from 'node:fs';
import {chromium} from '/private/tmp/flc-viewer-qa/node_modules/playwright-core/index.mjs';
const label=process.argv[2]||'baseline',browser=await chromium.launch({executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true}),rows=[];
try{
 for(const route of ['?floor=4','?floor=3&room=studio_1&mode=walk']){
  const p=await browser.newPage({viewport:{width:1280,height:800},deviceScaleFactor:1});const cdp=await p.context().newCDPSession(p);await cdp.send('Performance.enable');const start=Date.now();await p.goto('http://127.0.0.1:8142/'+route);await p.waitForFunction(()=>flcReview.snapshot().ready&&flcReview.snapshot().drawCalls>0);const readyMs=Date.now()-start;await p.waitForTimeout(1500);const cpuBefore=await cdp.send('Performance.getMetrics');
  const frame=await p.evaluate(()=>new Promise(resolve=>{let prior=performance.now();const dt=[];function next(now){dt.push(now-prior);prior=now;if(dt.length>=90){dt.sort((a,b)=>a-b);const gl=document.querySelector('canvas').getContext('webgl2'),ext=gl.getExtension('WEBGL_debug_renderer_info');resolve({medianFrameMs:dt[45],p95FrameMs:dt[85],renderer:ext?gl.getParameter(ext.UNMASKED_RENDERER_WEBGL):'unavailable',scene:flcReview.snapshot(),resources:performance.getEntriesByType('resource').filter(r=>r.name.includes('.glb')).map(r=>({file:r.name.split('/').at(-1),encodedBytes:r.encodedBodySize,transferBytes:r.transferSize,duration:r.duration}))});}else requestAnimationFrame(next);}requestAnimationFrame(next);}));
  const cpuAfter=await cdp.send('Performance.getMetrics');const metric=(data,name)=>data.metrics.find(m=>m.name===name)?.value||0;
  rows.push({route,readyMs,...frame,cpuTaskSeconds:metric(cpuAfter,'TaskDuration')-metric(cpuBefore,'TaskDuration'),cpuScriptSeconds:metric(cpuAfter,'ScriptDuration')-metric(cpuBefore,'ScriptDuration')});await p.close();
 }
 fs.writeFileSync('review/asset_pipeline_'+label+'_profile.json',JSON.stringify({browser:browser.version(),viewport:[1280,800],scope:'Local headless Chrome90rAF-interval/CPU samples; not isolated GPU time or physical-phone acceptance',rows},null,2));console.log(JSON.stringify(rows.map(r=>({route:r.route,readyMs:r.readyMs,drawCalls:r.scene.drawCalls,triangles:r.scene.triangles,medianFrameMs:r.medianFrameMs,p95FrameMs:r.p95FrameMs,cpuTaskSeconds:r.cpuTaskSeconds}))))
}finally{await browser.close();}
