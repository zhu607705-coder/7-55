/** DOM interaction acceptance only. This fixture does not replace actual building/GPU QA. */
import {chromium} from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../',import.meta.url)),web=path.join(root,'web'),out=path.join(root,'review/project_displays_browser');
fs.mkdirSync(out,{recursive:true});
const mime={'.html':'text/html','.js':'text/javascript','.json':'application/json','.css':'text/css'};
const fixture=path.join(root,'browser_tests/fixtures/project_display.html');
const server=http.createServer((req,res)=>{
 try{const pathname=new URL(req.url,'http://local').pathname;
 let file=pathname==='/__fixture'?fixture:path.resolve(web,'.'+decodeURIComponent(pathname));
 if(file!==fixture&&!file.startsWith(web+path.sep))throw Error('Outside web');
 res.setHeader('Content-Type',mime[path.extname(file)]||'application/octet-stream');res.end(fs.readFileSync(file));
 }catch{res.writeHead(404);res.end('Not found');}
});
let browser;const evidence={head:process.env.TEST_HEAD_SHA||null,scope:'Real Chromium DOM fixture, not building raycast/GPU acceptance',runs:[]};
try{
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 browser=await chromium.launch({headless:true,...(process.env.CHROME_PATH?{executablePath:process.env.CHROME_PATH}:{})});
 for(const [name,viewport,touch] of [['desktop',{width:1280,height:800},false],['mobile',{width:390,height:844},true]]){
  const context=await browser.newContext({viewport,hasTouch:touch,isMobile:touch});
  const page=await context.newPage(),errors=[];page.on('pageerror',e=>errors.push(e.message));
  try{
   await page.goto('http://127.0.0.1:'+server.address().port+'/__fixture');
   await page.locator('#poster').click();
   await page.locator('#project-display-dialog').waitFor({state:'visible'});
   assert.match(await page.locator('#project-display-title').innerText(),/走廊海报/);
   assert.equal(await page.locator('#project-display-content a').count(),0);
   assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),true);
   await page.screenshot({path:path.join(out,name+'-poster.png')});
   await page.getByRole('button',{name:'关闭项目展示'}).click();
   await page.locator('#project-display-dialog').waitFor({state:'hidden'});
   assert.match(await page.locator('#result').innerText(),/已关闭/);
   await page.locator('#monitor').click();
   await page.locator('#project-display-dialog').waitFor({state:'visible'});
   assert.match(await page.locator('#project-display-content').innerText(),/尚未配置项目内容/);
   await page.screenshot({path:path.join(out,name+'-monitor.png')});
   await page.keyboard.press('Escape');
   await page.locator('#project-display-dialog').waitFor({state:'hidden'});
   await page.locator('#poster').click();
   await page.locator('#project-display-dialog').waitFor({state:'visible'});
   await page.getByRole('button',{name:'关闭项目展示'}).click();
   assert.deepEqual(errors,[]);
   evidence.runs.push({name,passed:true,errors});
  }catch(error){evidence.runs.push({name,passed:false,error:String(error),errors});}
  finally{await context.close();}
 }
 assert.ok(evidence.runs.every(r=>r.passed),'All viewport interaction fixtures pass');
}finally{
 fs.writeFileSync(path.join(out,'result.json'),JSON.stringify(evidence,null,2));
 await browser?.close();server.close();
}

