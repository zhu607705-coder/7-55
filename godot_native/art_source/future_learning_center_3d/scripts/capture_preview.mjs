import {chromium} from '/private/tmp/flc-viewer-qa/node_modules/playwright-core/index.mjs';
const browser=await chromium.launch({executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true});
const page=await browser.newPage({viewport:{width:1280,height:800}});const errors=[];page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
await page.goto('http://127.0.0.1:8142/?floor=3&room=studio_1');
await page.waitForFunction(()=>window.flcReview?.snapshot().ready,null,{timeout:30000});await page.waitForTimeout(800);
await page.screenshot({path:'review/office_overview.png'});console.log({errors,state:await page.evaluate(()=>window.flcReview.snapshot())});
await page.locator('#walk').click();await page.waitForTimeout(800);await page.screenshot({path:'review/office_walk.png'});console.log(await page.evaluate(()=>window.flcReview.snapshot()));
await page.goto('http://127.0.0.1:8142/?floor=4');await page.waitForFunction(()=>window.flcReview?.snapshot().ready);await page.waitForTimeout(800);await page.screenshot({path:'review/floor_4.png'});
await browser.close();
