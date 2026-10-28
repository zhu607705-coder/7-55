import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import { build } from 'esbuild';
import { execFileSync, spawn } from 'node:child_process';
(async()=>{const dir=path.resolve(process.env.BUTTON_EVIDENCE_DIR || 'artifacts/button-material');fs.mkdirSync(dir,{recursive:true});await build({stdin:{contents:`import React from 'react';import{createRoot}from'react-dom/client';import{Button}from'./src/components/Button';window.clicks=0;createRoot(document.getElementById('root')).render(<main><h1>Button material acceptance board</h1><p>Not a game screenshot · shared production CSS / React component</p>{['md','lg'].map(size=><section><h2>{size}</h2>{['primary','secondary','tertiary','ghost','text'].map(variant=><article><Button id={size+'-'+variant} variant={variant} size={size} onClick={()=>window.clicks++}>{variant}</Button><Button variant={variant} size={size} disabled>Disabled</Button></article>)}</section>)}</main>);`,resolveDir:process.cwd(),loader:'tsx'},bundle:true,outfile:dir+'/gallery.js',jsx:'automatic'});const css=fs.readFileSync(dir+'/gallery.css','utf8');const js=fs.readFileSync(dir+'/gallery.js','utf8');const browser=await chromium.launch({...(process.env.CHROMIUM_BIN ? {executablePath:process.env.CHROMIUM_BIN} : {}),headless:true,args:['--no-sandbox']});const page=await browser.newPage({viewport:{width:1000,height:850}});await page.setContent(`<style>body{font:14px system-ui;background:#f5f5f4;color:#30343a;margin:32px}section{display:inline-block;vertical-align:top;width:45%}article{display:flex;gap:24px;margin:25px 0}h1{font-size:24px}h2{font-size:18px}p{color:#666}@media(max-width:500px){body{margin:16px}section{width:100%}article{gap:12px}}</style><style>${css}</style><div id=root></div><script>${js}</script>`);await page.waitForSelector('#md-primary');const results=[];for(const size of['md','lg'])for(const variant of['primary','secondary','tertiary','ghost','text']){const el=page.locator('#'+size+'-'+variant);const read=()=>el.evaluate(el=>{const s=getComputedStyle(el);return{height:el.getBoundingClientRect().height,font:s.fontSize,radius:s.borderRadius,border:s.borderTopWidth,shadow:s.boxShadow,bg:s.backgroundImage,transform:s.transform}});await page.mouse.move(0,0);await page.waitForTimeout(180);const rest=await read();if(Math.abs(rest.height-(size==='md'?40:40*16/14))>.1)throw Error('height '+JSON.stringify(rest));if((rest.shadow.match(/inset/g)||[]).length!==2)throw Error('inset count');await el.hover();await page.waitForTimeout(180);const hover=await read();await page.mouse.down();await page.waitForTimeout(180);const active=await read();if((active.shadow.match(/inset/g)||[]).length!==2)throw Error('pressed inset count');if(!active.transform.startsWith('matrix'))throw Error('press transform');await page.mouse.up();results.push({size,variant,rest,hover,active});}await page.mouse.move(0,0);await page.locator('#md-primary').focus();await page.keyboard.press('Tab');if(!await page.locator('#md-secondary').evaluate(e=>e.matches(':focus-visible')))throw Error('keyboard focus');const before=await page.evaluate(()=>clicks);await page.keyboard.press('Enter');if(await page.evaluate(()=>clicks)!==before+1)throw Error('keyboard click');const disabled=page.locator('button:disabled').first();await disabled.evaluate(e=>e.click());if(await page.evaluate(()=>clicks)!==before+1)throw Error('disabled activation');await page.screenshot({path:dir+'/board-desktop.png',fullPage:true});await page.setViewportSize({width:390,height:844});await page.screenshot({path:dir+'/board-mobile.png',fullPage:true});if(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth))throw Error('mobile overflow');fs.writeFileSync(dir+'/results.json',JSON.stringify(results,null,2));await verifySurfaces(browser,dir);await browser.close();console.log('PASS 10 variant/size combinations, rest/hover/pressed, keyboard focus/Enter, native disabled, mobile overflow');})();

async function verifySurfaces(browser, dir) {
  const commit=execFileSync('git',['rev-parse','HEAD'],{encoding:'utf8'}).trim();
  const tree=execFileSync('git',['rev-parse','HEAD^{tree}'],{encoding:'utf8'}).trim();
  // Shell presentation fixture uses the actual HTML/CSS; engine lifecycle belongs to native Web acceptance.
  const shell=fs.readFileSync('godot_native/web/index.html','utf8')
    .replace(/<script\b[^>]*>[\s\S]*?<\/script>/g,'')
    .replace('<link rel="stylesheet" href="button.css">',`<style>${fs.readFileSync('godot_native/web/button.css','utf8')}</style>`)
    .replace(/\$GODOT_HEAD_INCLUDE/g,'')
    .replace('__755_BOOT_ART_MORNING_ROOM__','data:image/webp;base64,'+fs.readFileSync('godot_native/web/boot_art/morning_room.webp').toString('base64'))
    .replace('__755_BOOT_FONT_REGULAR__','data:font/woff2;base64,'+fs.readFileSync('godot_native/art_source/fonts/morning_note_v1/web/MorningNote-Regular.woff2').toString('base64'))
    .replace('__755_BOOT_FONT_MEDIUM__','data:font/woff2;base64,'+fs.readFileSync('godot_native/art_source/fonts/morning_note_v1/web/MorningNote-Medium.woff2').toString('base64'));
  const shellPage=await browser.newPage({viewport:{width:1280,height:800}});
  await shellPage.setContent(shell);
  await shellPage.locator('#start-game, #retry-game, #boot-motion-toggle').evaluateAll(nodes=>nodes.forEach(node=>node.hidden=false));
  for(const id of ['start-game','retry-game','boot-motion-toggle']) {
    const button=shellPage.locator('#'+id);
    if(!await button.isVisible())throw Error('Shell button hidden: '+id);
    if(await button.getAttribute('type')!=='button')throw Error('Shell native semantics lost');
  }
  await shellPage.screenshot({path:path.join(dir,'production-shell-presentation.png'),fullPage:true});
  await shellPage.setViewportSize({width:390,height:844});
  await shellPage.screenshot({path:path.join(dir,'production-shell-presentation-mobile.png'),fullPage:true});
  await shellPage.close();
  // Mount real retained phone and settings pages, not just the material board.
  const server=spawn(process.execPath,['node_modules/vite/bin/vite.js','--host','127.0.0.1','--port','4188'],{stdio:'ignore'});
  try {
    let ready=false;
    for(let attempt=0;attempt<60;attempt++){try{if((await fetch('http://127.0.0.1:4188')).ok){ready=true;break;}}catch{}await new Promise(resolve=>setTimeout(resolve,500));}
    if(!ready)throw Error('Retained runtime did not start');
    const page=await browser.newPage({viewport:{width:390,height:844}});
    await page.goto('http://127.0.0.1:4188/?dev=1&devCheckpoint=c2-cc98-upload');
    await page.locator('.tactile-button').first().waitFor({timeout:60000});
    await page.waitForTimeout(3000);
    await page.screenshot({path:path.join(dir,'retained-phone-mobile.png'),fullPage:true});
    // Control center is a real menu with native toggle and destructive-confirmation flows.
    const open=page.locator('[aria-label^="打开控制中心"]');
    if(await open.count()) {
      await open.click();
      await page.locator('.cc-close').waitFor();
      await page.screenshot({path:path.join(dir,'retained-control-center-mobile.png'),fullPage:true});
      const toggle=page.locator('.cc-toggle[aria-pressed]').first();
      const before=await toggle.getAttribute('aria-pressed');
      await toggle.click();
      if(await toggle.getAttribute('aria-pressed')===before)throw Error('Actual control-center toggle no longer activates');
      await page.locator('.cc-close').click();
    } else throw Error('Real phone menu entry not found');
    await page.close();
    fs.writeFileSync(path.join(dir,'provenance.json'),JSON.stringify({commit,tree,shell:'actual production template presentation; engine not mocked as gameplay acceptance',react:'actual retained Vite runtime, mobile phone and control center',board:'shared source component/CSS, not game screenshot'},null,2));
  } finally {server.kill();}
}
