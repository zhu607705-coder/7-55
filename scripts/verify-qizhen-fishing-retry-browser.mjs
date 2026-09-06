// Run against the development server. Point PLAYWRIGHT_MODULE at an external QA runtime if needed.
import assert from 'node:assert/strict';
const { chromium } = await import(process.env.PLAYWRIGHT_MODULE || 'playwright');
const touch = process.argv.includes('--touch');
const browser = await chromium.launch({headless:true});
const page = await browser.newPage({viewport:touch?{width:390,height:844}:{width:1280,height:720},isMobile:touch,hasTouch:touch});
const read=()=>page.evaluate(()=>JSON.parse(render_game_to_text()));
const key=async(code,ms=140)=>{await page.keyboard.down(code);await page.waitForTimeout(ms);await page.keyboard.up(code);};
try{
 await page.goto(`${process.env.BASE_URL||'http://127.0.0.1:4182'}/?devCheckpoint=c3-qizhen-rhythm-key`);
 if(await page.getByRole('button',{name:'关闭开发者通道',exact:true}).isVisible()) await page.getByRole('button',{name:'关闭开发者通道',exact:true}).click();
 await page.waitForFunction(()=>JSON.parse(render_game_to_text()).rpgRuntime?.qizhenLake?.vehicle==='kayak');
 await page.locator('.rpg-shell canvas').click();await key('Space');
 await page.waitForFunction(()=>JSON.parse(render_game_to_text()).rpgRuntime.qizhenLake.fishing.totalNotes===8);
 await key('d',700);await key('Space',600);
 await page.waitForFunction(()=>JSON.parse(render_game_to_text()).rpgRuntime.qizhenLake.fishing.stage==='fighting');
 await page.keyboard.down('Space');await page.waitForFunction(()=>JSON.parse(render_game_to_text()).rpgRuntime.qizhenLake.fishing.tension>=100);await page.keyboard.up('Space');
 const failed=await read();assert(!failed.ownedItems.includes('rustedLockerKey'));
 const bounds=await page.locator('.rpg-shell canvas').boundingBox();const x=bounds.x+bounds.width*.5,y=bounds.y+bounds.height*(.66+22/540);
 if(touch)await page.touchscreen.tap(x,y);else await page.mouse.click(x,y);
 await page.waitForFunction(previous=>{const f=JSON.parse(render_game_to_text()).rpgRuntime.qizhenLake.fishing;return f.totalNotes===8&&f.sessionId!==previous;},failed.rpgRuntime.qizhenLake.fishing.sessionId);
 const retried=await read();assert.equal(retried.rpgRuntime.qizhenLake.fishing.judged,0);assert(retried.ownedItems.includes('fishingRod'));
 await key('Escape');const cancelled=await read();assert.equal(cancelled.rpgRuntime.qizhenLake.fishing.state,'idle');assert(!cancelled.ownedItems.includes('rustedLockerKey'));
 console.log(`${touch?'Native touch':'Mouse'} retry -> fresh session -> cancel preserves items PASS`);
}finally{await browser.close();}
