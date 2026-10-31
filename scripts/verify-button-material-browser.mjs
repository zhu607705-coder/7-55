import { chromium } from "playwright";
import fs from "node:fs";
import path from "node:path";
import { build } from "esbuild";
import { execFileSync, spawn } from "node:child_process";
(async () => {
  const dir = path.resolve(process.env.BUTTON_EVIDENCE_DIR || "artifacts/button-material");
  fs.mkdirSync(dir, { recursive: true });
  await build({ stdin: { contents: `import React from 'react';import{createRoot}from'react-dom/client';import{Button}from'./src/components/Button';window.clicks=0;createRoot(document.getElementById('root')).render(<main><h1>Button material acceptance board</h1><p>Not a game screenshot · shared production CSS / React component</p>{['md','lg'].map(size=><section><h2>{size}</h2>{['primary','secondary','tertiary','ghost','text'].map(variant=><article><Button id={size+'-'+variant} variant={variant} size={size} onClick={()=>window.clicks++}>{variant}</Button><Button variant={variant} size={size} disabled>Disabled</Button></article>)}</section>)}</main>);`, resolveDir: process.cwd(), loader: "tsx" }, bundle: true, outfile: dir + "/gallery.js", jsx: "automatic" });
  const css = fs.readFileSync(dir + "/gallery.css", "utf8");
  const js = fs.readFileSync(dir + "/gallery.js", "utf8");
  const browser = await chromium.launch({ ...process.env.CHROMIUM_BIN ? { executablePath: process.env.CHROMIUM_BIN } : {}, headless: true, args: ["--no-sandbox"] });
  const page = await browser.newPage({ viewport: { width: 1e3, height: 850 } });
  await page.setContent(`<style>body{font:14px system-ui;background:#f5f5f4;color:#30343a;margin:32px}section{display:inline-block;vertical-align:top;width:45%}article{display:flex;gap:24px;margin:25px 0}h1{font-size:24px}h2{font-size:18px}p{color:#666}@media(max-width:500px){body{margin:16px}section{width:100%}article{gap:12px}}</style><style>${css}</style><div id=root></div><script>${js}<\/script>`);
  await page.waitForSelector("#md-primary");
  const results = [];
  for (const size of ["md", "lg"]) for (const variant of ["primary", "secondary", "tertiary", "ghost", "text"]) {
    const el = page.locator("#" + size + "-" + variant);
    const read = () => el.evaluate((el2) => {
      const s = getComputedStyle(el2);
      const r = el2.getBoundingClientRect();
      return { x:r.x, y:r.y, height:r.height, font: s.fontSize, radius: s.borderRadius, border: s.borderTopWidth, shadow: s.boxShadow, bg: s.backgroundImage, transform: s.transform };
    });
    await page.mouse.move(0, 0);
    await page.waitForTimeout(180);
    const rest = await read();
    if (Math.abs(rest.height - (size === "md" ? 40 : 40 * 16 / 14)) > 0.1) throw Error("height " + JSON.stringify(rest));
    if (Math.abs(parseFloat(rest.radius) - (size === "md" ? 10 : 10 * 16 / 14)) > 0.01) throw Error("radius scale");
    if (parseFloat(rest.font) !== (size === "md" ? 14 : 16)) throw Error("label scale");
    if ((rest.shadow.match(/inset/g) || []).length !== 2) throw Error("inset count");
    await el.hover();
    await page.waitForTimeout(180);
    const hover = await read();
    await page.mouse.down();
    await page.waitForTimeout(180);
    const active = await read();
    if ((active.shadow.match(/inset/g) || []).length !== 2) throw Error("pressed inset count");
    const pressY = active.y-hover.y;
    const expectedPress = await page.evaluate(()=>CSS.supports('translate','0 1px')) ? (size === "md" ? 1 : 16 / 14) : 0;
    if (Math.abs(active.x-hover.x) > .01 || Math.abs(pressY-expectedPress) > .02) throw Error("press scale/placement");
    await page.mouse.up();
    results.push({ size, variant, rest, hover, active });
  }
  await page.mouse.move(0, 0);
  await page.locator("#md-primary").focus();
  await page.keyboard.press("Tab");
  if (!await page.locator("#md-secondary").evaluate((e) => e.matches(":focus-visible"))) throw Error("keyboard focus");
  const before = await page.evaluate(() => clicks);
  await page.keyboard.press("Enter");
  if (await page.evaluate(() => clicks) !== before + 1) throw Error("keyboard click");
  const disabled = page.locator("button:disabled").first();
  await disabled.evaluate((e) => e.click());
  if (await page.evaluate(() => clicks) !== before + 1) throw Error("disabled activation");
  await page.screenshot({ path: dir + "/board-desktop.png", fullPage: true });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.screenshot({ path: dir + "/board-mobile.png", fullPage: true });
  if (await page.evaluate(() => document.documentElement.scrollWidth > innerWidth)) throw Error("mobile overflow");
  fs.writeFileSync(dir + "/results.json", JSON.stringify(results, null, 2));
  await verifyRingPressedLayout(browser, dir);
  await verifyPhoneFocus(browser, dir);
  await verifySurfaces(browser, dir);
  await browser.close();
  console.log("PASS 10 variant/size combinations, rest/hover/pressed, keyboard focus/Enter, native disabled, mobile overflow");
})();
async function verifyRingPressedLayout(browser, dir) {
  await build({stdin:{contents:`import React from 'react';import{createRoot}from'react-dom/client';import{InvestigationRing}from'./src/components/InvestigationRing';import'./src/styles/investigation-ring.css';window.ringActivations=[];createRoot(document.getElementById('root')).render(<InvestigationRing ariaLabel="Investigation input fixture" title="Evidence" completed={0} total={3} nodes={['a','b','c'].map(id=>({id,label:id,statusLabel:'Ready',state:'ready'}))} onActivate={id=>window.ringActivations.push(id)}/>);`,resolveDir:process.cwd(),loader:'tsx'},bundle:true,outfile:dir+'/ring-input.js',jsx:'automatic'});
  const page=await browser.newPage();
  const records=[];
  for(const width of [390,1280]) {
    await page.setViewportSize({width,height:844});
    await page.setContent(`<style>body{margin:20px}#root{width:350px}</style><style>${fs.readFileSync(dir+'/ring-input.css','utf8')}</style><div id="root"></div><script>${fs.readFileSync(dir+'/ring-input.js','utf8')}<\/script>`);
    const node=page.locator('.investigation-ring__node').first();await node.waitFor();
    const rest=await node.boundingBox();
    // Releasing in the original left half used to miss after a 60px jump.
    await page.mouse.move(rest.x+5,rest.y+rest.height/2);await page.mouse.down();await page.waitForTimeout(180);
    const pressed=await node.boundingBox();
    if(Math.abs(pressed.x-rest.x)>.1||Math.abs(pressed.y-rest.y)>1.2)throw Error('Investigation ring jumps during press: '+JSON.stringify({rest,pressed}));
    await page.mouse.up();
    if(await page.evaluate(()=>window.ringActivations.join(','))!=='a')throw Error('Original left-half press/release lost evidence activation');
    records.push({width,rest,pressed,activated:'a'});
  }
  fs.writeFileSync(dir+'/ring-input-results.json',JSON.stringify(records,null,2));
  await page.close();
}
async function verifySurfaces(browser, dir) {
  const commit = execFileSync("git", ["rev-parse", "HEAD"], { encoding: "utf8" }).trim();
  const tree = execFileSync("git", ["rev-parse", "HEAD^{tree}"], { encoding: "utf8" }).trim();
  const shell = fs.readFileSync("godot_native/web/index.html", "utf8").replace(/<script\b[^>]*>[\s\S]*?<\/script>/g, "").replace('<link rel="stylesheet" href="button.css">', `<style>${fs.readFileSync("godot_native/web/button.css", "utf8")}</style>`).replace(/\$GODOT_HEAD_INCLUDE/g, "").replace("__755_BOOT_ART_MORNING_ROOM__", "data:image/webp;base64," + fs.readFileSync("godot_native/web/boot_art/morning_room.webp").toString("base64")).replace("__755_BOOT_FONT_REGULAR__", "data:font/woff2;base64," + fs.readFileSync("godot_native/art_source/fonts/morning_note_v1/web/MorningNote-Regular.woff2").toString("base64")).replace("__755_BOOT_FONT_MEDIUM__", "data:font/woff2;base64," + fs.readFileSync("godot_native/art_source/fonts/morning_note_v1/web/MorningNote-Medium.woff2").toString("base64"));
  const shellPage = await browser.newPage({ viewport: { width: 1280, height: 800 } });
  await shellPage.setContent(shell);
  await shellPage.locator("#start-game, #retry-game, #boot-motion-toggle").evaluateAll((nodes) => nodes.forEach((node) => node.hidden = false));
  for (const id of ["start-game", "retry-game", "boot-motion-toggle"]) {
    const button = shellPage.locator("#" + id);
    if (!await button.isVisible()) throw Error("Shell button hidden: " + id);
    if (await button.getAttribute("type") !== "button") throw Error("Shell native semantics lost");
  }
  await shellPage.screenshot({ path: path.join(dir, "production-shell-presentation.png"), fullPage: true });
  await shellPage.setViewportSize({ width: 390, height: 844 });
  await shellPage.screenshot({ path: path.join(dir, "production-shell-presentation-mobile.png"), fullPage: true });
  await shellPage.close();
  const server = spawn(process.execPath, ["node_modules/vite/bin/vite.js", "--host", "127.0.0.1", "--port", "4188"], { stdio: "ignore" });
  try {
    let ready = false;
    for (let attempt = 0; attempt < 60; attempt++) {
      try {
        if ((await fetch("http://127.0.0.1:4188")).ok) {
          ready = true;
          break;
        }
      } catch {
      }
      await new Promise((resolve) => setTimeout(resolve, 500));
    }
    if (!ready) throw Error("Retained runtime did not start");
    const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
    await page.goto("http://127.0.0.1:4188/?dev=1&devCheckpoint=c2-cc98-upload");
    await page.locator(".tactile-button").first().waitFor({ timeout: 6e4 });
    await page.waitForTimeout(3e3);
    await page.screenshot({ path: path.join(dir, "retained-developer-menu-mobile.png"), fullPage: true });
    const developerClose = page.getByRole("button", { name: "关闭开发者通道", exact: true });
    if (await developerClose.isVisible()) await developerClose.click();
    await page.locator("[data-developer-channel-root]").waitFor({ state: "hidden" });
    await page.screenshot({ path: path.join(dir, "retained-phone-mobile.png"), fullPage: true });
    const open = page.locator('[aria-label^="打开控制中心"]');
    if (await open.count()) {
      await open.click();
      await page.locator(".cc-close").waitFor();
      await page.locator(".cc-panel").evaluate(async (panel) => {
        await Promise.all(panel.getAnimations().map((animation) => animation.finished));
      });
      await page.screenshot({ path: path.join(dir, "retained-control-center-mobile.png"), fullPage: true });
      const toggle = page.locator(".cc-toggle[aria-pressed]").first();
      const before = await toggle.getAttribute("aria-pressed");
      await toggle.click();
      if (await toggle.getAttribute("aria-pressed") === before) throw Error("Actual control-center toggle no longer activates");
      const after = await toggle.getAttribute("aria-pressed");
      await page.locator(".cc-close").click();
      await page.locator(".cc-close").waitFor({ state: "hidden" });
      await open.click();
      if (await toggle.getAttribute("aria-pressed") !== after) throw Error("Toggle state lost after dismiss/reopen");
      await page.locator(".cc-close").click();
    } else throw Error("Real phone menu entry not found");
    await page.close();
    fs.writeFileSync(path.join(dir, "provenance.json"), JSON.stringify({ commit, tree, shell: "actual production template presentation; engine not mocked as gameplay acceptance", react: "actual retained Vite runtime, mobile phone and control center", board: "shared source component/CSS, not game screenshot" }, null, 2));
  } finally {
    server.kill();
  }
}

// Exercise actual shared phone components with their authored high-specificity CSS.
async function verifyPhoneFocus(browser, dir) {
  await build({stdin:{contents:`import React from 'react';import{createRoot}from'react-dom/client';import{PhoneAppBottomNav,PhoneActionSheet}from'./src/components/PhoneAppUi';import{Button}from'./src/components/Button';import'./src/styles/phone-app-ui.css';function Probe(){const[open,setOpen]=React.useState(false);return <main><PhoneAppBottomNav items={[{id:'home',label:'首页',icon:'H'},{id:'records',label:'记录',icon:'R'}]} activeId="home" onSelect={()=>{}}/><Button id="open-sheet" onClick={()=>setOpen(true)}>打开操作</Button>{open&&<PhoneActionSheet title="操作" onClose={()=>setOpen(false)}><p>焦点测试</p></PhoneActionSheet>}</main>}createRoot(document.getElementById('root')).render(<Probe/>);`,resolveDir:process.cwd(),loader:'tsx'},bundle:true,outfile:dir+'/phone-focus.js',jsx:'automatic'});
  const page=await browser.newPage({viewport:{width:390,height:844}});
  await page.setContent(`<style>body{background:#eeeae0} :root{--phone-app-line:#333;--phone-app-action:#333;--phone-app-accent:#ddd}</style><style>${fs.readFileSync(dir+'/phone-focus.css','utf8')}</style><div id="root"></div><script>${fs.readFileSync(dir+'/phone-focus.js','utf8')}<\/script>`);
  await page.locator('.phone-app-bottom-nav button').first().waitFor();
  async function assertRing(selector) {
    if(!await page.locator(selector).evaluate(e=>{const s=getComputedStyle(e);return e.matches(':focus-visible')&&s.outlineStyle!=='none'&&parseFloat(s.outlineWidth)>=3;}))throw Error('Phone keyboard focus ring lost: '+selector);
  }
  await page.keyboard.press('Tab'); await assertRing('.phone-app-bottom-nav button:first-child');
  await page.keyboard.press('Tab'); await assertRing('.phone-app-bottom-nav button:nth-child(2)');
  await page.keyboard.press('Tab'); await page.keyboard.press('Enter');
  await page.locator('.phone-app-sheet').waitFor(); await assertRing('.phone-app-sheet__header button');
  await page.screenshot({path:dir+'/retained-phone-sheet-keyboard-focus.png'});
  await page.keyboard.press('Escape'); await page.locator('.phone-app-sheet').waitFor({state:'hidden'});
  await assertRing('#open-sheet');
  await page.emulateMedia({forcedColors:'active'}); await assertRing('#open-sheet');
  await page.close();
}
