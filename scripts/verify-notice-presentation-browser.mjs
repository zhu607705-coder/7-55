import { createServer, transformWithEsbuild } from "vite";
import { spawn } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdtemp, readFile, writeFile, mkdir, rm, realpath } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";

// Isolated real-component harness. No route, fixture, clock override or controller hook ships.
const root = process.cwd();
const artifacts = process.env.NOTICE_BROWSER_ARTIFACT_DIR || "/tmp/codex-755-notice-presentation-browser";
const legacy = process.argv.includes("--legacy-negative");
const temp = await mkdtemp(path.join(tmpdir(), "755-notice-browser-"));
const harness = await mkdtemp(path.join(root, ".notice-qa-"));
const fixturePath = "scripts/fixtures/notice-presentation/toast-before-queue.tsx.source.txt";
const fixture = await readFile(path.join(root, fixturePath), "utf8");
const failures = [], evidence = {}, exceptions = [];
let checks = 0, browser, server, cdp, infrastructureError = null, legacyTransforms = 0;
const pause = ms => new Promise(resolve => setTimeout(resolve, ms));
const check = (ok, message) => { checks++; if (!ok) failures.push(message); };
async function poll(read, label) {
  for (let i = 0; i < 200; i++) { try { const value = await read(); if (value) return value; } catch {} await pause(50); }
  throw Error("Timed out: " + label);
}
async function connect(url) {
  const ws = new WebSocket(url);
  await new Promise((resolve, reject) => { ws.addEventListener("open", resolve, { once: true }); ws.addEventListener("error", reject, { once: true }); });
  let id = 0; const pending = new Map();
  ws.addEventListener("message", event => {
    const value = JSON.parse(String(event.data));
    if (value.method === "Runtime.exceptionThrown") exceptions.push(value.params.exceptionDetails.exception?.description || value.params.exceptionDetails.text);
    const item = pending.get(value.id); if (!item) return;
    pending.delete(value.id); clearTimeout(item.timer);
    value.error ? item.reject(Error(value.error.message)) : item.resolve(value.result);
  });
  return {
    send(method, params = {}) { return new Promise((resolve, reject) => {
      const next = ++id, timer = setTimeout(() => { pending.delete(next); reject(Error(method)); }, 15000);
      pending.set(next, { resolve, reject, timer }); ws.send(JSON.stringify({ id: next, method, params }));
    }); },
    close() { ws.close(); }
  };
}
async function evaluate(expression) {
  const value = await cdp.send("Runtime.evaluate", { expression, returnByValue: true, awaitPromise: true });
  if (value.exceptionDetails) throw Error(value.exceptionDetails.exception?.description || value.exceptionDetails.text);
  return value.result.value;
}
async function click(selector) {
  const point = await evaluate("(()=>{const e=document.querySelector(" + JSON.stringify(selector) + ");if(!e)return null;const r=e.getBoundingClientRect();return{x:r.x+r.width/2,y:r.y+r.height/2};})()");
  if (!point) throw Error("Missing harness control " + selector);
  await cdp.send("Input.dispatchMouseEvent", { type: "mousePressed", button: "left", clickCount: 1, ...point });
  await cdp.send("Input.dispatchMouseEvent", { type: "mouseReleased", button: "left", clickCount: 1, ...point });
  await pause(40);
}
async function snapshot() {
  return evaluate(`({now:performance.now(),hidden:document.hidden,
    notices:[...document.querySelectorAll('.toast-layer .px-toast')].map(e=>e.textContent),
    noticeDurations:[...document.querySelectorAll('.toast-layer .px-toast')].map(e=>parseFloat(e.style.getPropertyValue('--subtitle-duration'))),
    captions:[...document.querySelectorAll('.dialogue-caption-layer')].map(e=>e.textContent),
    speaker:document.querySelector('.dialogue-caption-layer .game-subtitle-speaker')?.textContent})`);
}
const screenshot = async name => writeFile(path.join(artifacts, `${legacy ? "legacy-" : ""}${name}.png`), Buffer.from((await cdp.send("Page.captureScreenshot", { format: "png" })).data, "base64"));
async function bounds() {
  return evaluate(`(()=>{const p=document.querySelector('.phone-frame').getBoundingClientRect(),box=e=>{const r=e.getBoundingClientRect();return{x:r.x,y:r.y,w:r.width,h:r.height}};
    const caption=document.querySelector('.dialogue-caption-layer'),notice=document.querySelector('.toast-layer .px-toast'),text=document.querySelector('.story-caption .game-subtitle-text');
    return{phone:{x:p.x,y:p.y,w:p.width,h:p.height},caption:caption?box(caption):null,notice:notice?box(notice):null,
      text:text?{...box(text),lineHeight:parseFloat(getComputedStyle(text).lineHeight),logicalWidth:text.clientWidth,logicalHeight:text.clientHeight}:null,
      captionBackground:caption?getComputedStyle(document.querySelector('.story-caption')).backgroundColor:null,
      documentOverflow:document.documentElement.scrollWidth>innerWidth,logicalPhone:{w:document.querySelector('.phone-frame').offsetWidth,h:document.querySelector('.phone-frame').offsetHeight}};})()`);
}
const inside = (outer, inner, margin = 0) => Boolean(inner && inner.x >= outer.x + margin - 1 && inner.y >= outer.y + margin - 1 && inner.x + inner.w <= outer.x + outer.w - margin + 1 && inner.y + inner.h <= outer.y + outer.h - margin + 1);

try {
  await mkdir(artifacts, { recursive: true });
  const appSource = await readFile(path.join(root, "src/App.tsx"), "utf8");
  const phoneSource = await readFile(path.join(root, "src/components/PhoneShell.tsx"), "utf8");
  const globalToastTags = [...appSource.matchAll(/<ToastLayer\b[^>]*\/>/g)].map(match => match[0]);
  check(globalToastTags.length === 2 && globalToastTags.every(tag => /blocked=\{libraryStoryVisible\s*\|\|\s*showChapterTwoIntro\}/.test(tag)), "Both real App RPG owners pause notifications for the full-screen chapter intro");
  check(/notificationsBlocked=\{showChapterTwoIntro\}/.test(appSource) && /blocked=\{Boolean\(dialogueOverlay\)\s*\|\|\s*notificationsBlocked\}/.test(phoneSource), "Normal phone owner forwards a dedicated intro notification block without changing gameplay input");
  check(/showGlobalLayers=\{false\}/.test(appSource) && /showGlobalLayers\s*\?\s*<ToastLayer/.test(phoneSource), "Embedded phone shell disables its second global notification owner");
  evidence.ownerAssertions = { method: "Exact current App/PhoneShell ownership clauses, combined with real component blocked-lifetime behavior below", appSha256: createHash("sha256").update(appSource).digest("hex"), phoneSha256: createHash("sha256").update(phoneSource).digest("hex") };
  await writeFile(path.join(harness, "index.html"), '<div id="root"></div><script type="module" src="./harness.tsx"></script>');
  await writeFile(path.join(harness, "harness.tsx"), [
    "import React,{useState} from 'react';import{createRoot}from'react-dom/client';",
    "import{ToastLayer}from'/src/components/ToastLayer';import{EventBus}from'/src/core/EventBus';import{createInitialGameState}from'/src/core/GameState';",
    "import'/src/styles/base.css';import'/src/styles/subtitles.css';",
    "const events=new EventBus();const state={...createInitialGameState(),currentScene:'phone_home'};",
    `function App(){const[blocked,setBlocked]=useState(false),[mounted,setMounted]=useState(true),[surface,setSurface]=useState('phone');
      const send=(text,durationMs=1800)=>events.emit('toast',{text,tone:'system',durationMs});return <>
      <div className='harness-actions'><button id='one' onClick={()=>send('通知甲：请保留阅读时间。')}>一条通知</button>
      <button id='burst' onClick={()=>['第一条','第二条','第三条','第四条','第五条'].forEach(text=>send(text,900))}>五条通知</button>
      <button id='sequence' onClick={()=>['保留甲','保留乙','保留丙'].forEach((text,i)=>send(text,i===0?2200:1100))}>重挂队列</button>
      <button id='story' onClick={()=>events.emit('toast',{text:'这句旁白按原时钟出现。',tone:'system',speaker:'narrator',presentationRole:'dialogue',durationMs:1200})}>剧情字幕</button>
      <button id='block' onClick={()=>setBlocked(true)}>进入场景</button><button id='unblock' onClick={()=>setBlocked(false)}>返回界面</button>
      <button id='unmount' onClick={()=>setMounted(false)}>卸载反馈</button><button id='remount' onClick={()=>setMounted(true)}>重挂反馈</button>
      <button id='rpg' onClick={()=>{setSurface('rpg');setMounted(true)}}>RPG表面</button></div>
      <div className='harness-phone-space'><div className='phone-frame'><div className='harness-app'>应用内容保持可见</div>
      {mounted?<ToastLayer key={surface} events={events} state={state} blocked={blocked} surface={surface}/>:null}</div></div></>;
    }createRoot(document.getElementById('root')).render(<App/>);`,
    `const style=document.createElement('style');style.textContent='body{margin:0;background:#18312e;display:grid;justify-items:center}.harness-phone-space{position:relative;width:430px;height:860px}.phone-frame{position:absolute;top:0;left:50%;width:430px;height:860px;transform:translateX(-50%) scale(var(--qa-scale,1));transform-origin:top center;background:#e6e5dc}.harness-app{padding:180px 20px;color:#28443b}.harness-actions{width:min(100%,760px);display:flex;flex-wrap:wrap;justify-content:center;gap:4px;padding:4px;box-sizing:border-box}.harness-actions button{font:12px sans-serif;min-height:32px;padding:3px 6px}@media(max-width:500px){.harness-phone-space{width:352.6px;height:705.2px}.phone-frame{--qa-scale:.82}}';document.head.append(style);`
  ].join("\n"));
  const plugins = legacy ? [{ name: "original-notice-negative", enforce: "pre", async transform(_code, id) {
    if (id.split("?")[0].endsWith("/src/components/ToastLayer.tsx")) { legacyTransforms++; return transformWithEsbuild(fixture, id, { loader: "tsx", jsx: "automatic" }); }
  } }] : [];
  server = await createServer({ plugins, server: { host: "127.0.0.1", port: 5190, strictPort: true, fs: { allow: [root, await realpath(path.join(root, "node_modules"))] } }, logLevel: "error" }); await server.listen();
  const profile = path.join(temp, "profile");
  browser = spawn(process.env.CHROME_BIN || "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome", ["--headless=new", "--no-sandbox", "--disable-background-networking", "--disable-extensions", "--mute-audio", "--remote-debugging-port=0", "--user-data-dir=" + profile, "about:blank"], { stdio: "ignore" });
  const port = (await poll(() => readFile(path.join(profile, "DevToolsActivePort"), "utf8"), "Chromium")).split("\n")[0];
  const target = (await (await fetch("http://127.0.0.1:" + port + "/json/list")).json()).find(item => item.type === "page");
  cdp = await connect(target.webSocketDebuggerUrl); await cdp.send("Page.enable"); await cdp.send("Runtime.enable");
  const url = "http://127.0.0.1:5190/" + path.basename(harness) + "/index.html";
  const boot = async () => {
    await evaluate("window.__noticeOldDocument=true");
    await cdp.send("Page.navigate", { url });
    await poll(() => evaluate("!window.__noticeOldDocument&&!!document.querySelector('#burst')"), "fresh component harness");
    await evaluate("document.fonts.ready.then(()=>true)"); await pause(80);
  };
  await cdp.send("Emulation.setDeviceMetricsOverride", { width: 1280, height: 1000, deviceScaleFactor: 1, mobile: false });
  await boot(); await click("#burst");
  check((await snapshot()).notices.length === 1, "Burst shows exactly one notification");
  check((await snapshot()).notices[0]?.includes("第一条"), "Fifth event cannot evict first unread notification");
  await pause(950); check((await snapshot()).notices[0]?.includes("第二条"), "Second notification gets its own turn");
  await boot(); await click("#one"); await pause(300); await click("#block");
  check((await snapshot()).notices.length === 0, "Scene-owned UI hides ordinary notifications");
  await pause(2000); await click("#unblock");
  check((await snapshot()).notices[0]?.includes("通知甲"), "Blocked time cannot expire the unread remainder");
  await boot(); await click("#one"); await pause(150); await click("#story");
  let state = await snapshot();
  check(state.captions.length === 1 && state.captions[0].includes("这句旁白"), "Authored speech appears immediately in its caption lane");
  check(state.notices.length === 0 && state.speaker === "旁白", "Notifications wait while the actual narrator is identified");
  await pause(1300); state = await snapshot();
  check(state.captions.length === 0 && state.notices[0]?.includes("通知甲"), "Original speech clock finishes before notification reading resumes");
  await click("#story");
  evidence.desktop = await bounds();
  check(inside(evidence.desktop.phone,evidence.desktop.caption) && evidence.desktop.caption.y > evidence.desktop.phone.y + 40 && evidence.desktop.caption.y + evidence.desktop.caption.h <= evidence.desktop.phone.y + evidence.desktop.phone.h - 70, "Story caption stays in the lower reading lane inside the phone");
  check(Boolean(evidence.desktop.captionBackground && !evidence.desktop.captionBackground.includes("rgba")), "Reading panel is opaque rather than black glass");
  check(Boolean(evidence.desktop.text && evidence.desktop.text.logicalWidth > 250 && evidence.desktop.text.logicalHeight <= evidence.desktop.text.lineHeight * 3), "Short story text uses the reading strip width rather than a hidden avatar column");
  await screenshot("caption");

  // Actual browser visibility event, not a mocked property or product pause API.
  await boot(); await click("#sequence"); await pause(300);
  const hiddenStart = await snapshot();
  const other = await cdp.send("Target.createTarget", { url: "about:blank" });
  await cdp.send("Target.activateTarget", { targetId: other.targetId });
  await poll(() => evaluate("document.hidden"), "real hidden page");
  const hiddenDuring = await snapshot(); await pause(2500);
  check((await snapshot()).notices.length === 0, "Real document.hidden hides the active notification");
  await cdp.send("Page.bringToFront"); await cdp.send("Target.closeTarget", { targetId: other.targetId });
  await poll(() => evaluate("!document.hidden"), "real foreground page"); await pause(30);
  const visibleAgain = await snapshot();
  check(visibleAgain.notices.length === 1 && visibleAgain.notices[0].includes("保留甲"), "Real hidden-tab interval longer than original deadline does not consume the first notice");
  check(visibleAgain.noticeDurations[0] > 1500 && visibleAgain.noticeDurations[0] < 2050, "Foreground resumes the unread remainder rather than restarting the full 2200ms");
  evidence.visibility = { before: hiddenStart, hidden: hiddenDuring, resumed: visibleAgain, hiddenWaitMs: 2500 };

  // Real React teardown/recreation; the event bus stays the same module object.
  await boot(); await click("#sequence"); await pause(420); await click("#unmount");
  check((await snapshot()).notices.length === 0, "Unmount actually removes the ToastLayer DOM");
  await pause(1900); await click("#remount");
  const remounted = await snapshot();
  check(remounted.notices.length === 1 && remounted.notices[0].includes("保留甲"), "Same-EventBus remount keeps the first unread notification");
  check(remounted.noticeDurations[0] > 1350 && remounted.noticeDurations[0] < 1900, "Unmounted time is paused and remount restores only the unread remainder");
  await click("#rpg"); const rpgRemount = await snapshot();
  check(rpgRemount.notices.length === 1 && rpgRemount.notices[0].includes("保留甲"), "Phone-to-RPG keyed component replacement retains the same FIFO owner");
  check(rpgRemount.noticeDurations[0] <= remounted.noticeDurations[0] && rpgRemount.noticeDurations[0] >= remounted.noticeDurations[0] - 200, "Surface remount does not restart or consume unseen notification time");
  await pause((rpgRemount.noticeDurations[0] || 100) + 90); const second = await snapshot();
  check(second.notices.length === 1 && second.notices[0].includes("保留乙"), "Second queued notice survives the actual unmount and surface remount");
  await pause(1130); const third = await snapshot();
  check(third.notices.length === 1 && third.notices[0].includes("保留丙"), "Third queued notice keeps FIFO order after remount");
  evidence.remount = { unmountedWaitMs: 1900, remounted, surfaceReplaced: rpgRemount, second, third };

  // Fixed logical 430×860 content, scaled as a whole at the supported mobile viewport.
  await cdp.send("Emulation.setDeviceMetricsOverride", { width: 390, height: 844, deviceScaleFactor: 1, mobile: false });
  await boot(); await click("#one"); evidence.mobileNotice = await bounds();
  check(evidence.mobileNotice.logicalPhone.w === 430 && evidence.mobileNotice.logicalPhone.h === 860 && Math.abs(evidence.mobileNotice.phone.w / evidence.mobileNotice.phone.h - .5) < .002, "390 viewport scales one logical 430×860 phone without changing its ratio");
  check(!evidence.mobileNotice.documentOverflow && inside({x:0,y:0,w:390,h:844},evidence.mobileNotice.phone), "Scaled mobile phone fits inside 390×844 with no document overflow");
  check(inside(evidence.mobileNotice.phone,evidence.mobileNotice.notice), "Mobile notification remains inside the scaled phone bounds");
  await screenshot("mobile-notice"); await click("#story"); evidence.mobileCaption = await bounds();
  const scale = evidence.mobileCaption.phone.w / 430;
  check(inside(evidence.mobileCaption.phone,evidence.mobileCaption.caption) && evidence.mobileCaption.caption.y >= evidence.mobileCaption.phone.y + 40 * scale && evidence.mobileCaption.caption.y + evidence.mobileCaption.caption.h <= evidence.mobileCaption.phone.y + evidence.mobileCaption.phone.h - 70 * scale, "Mobile story caption stays below status area and above lower phone controls");
  check(Boolean(evidence.mobileCaption.text && evidence.mobileCaption.text.logicalWidth > 250 && evidence.mobileCaption.text.logicalHeight <= evidence.mobileCaption.text.lineHeight * 3), "Scaled story text keeps its full logical reading width");
  await screenshot("mobile-caption");
  check(exceptions.length === 0, "Real component runs without uncaught browser exceptions");
  if (legacy) check(legacyTransforms > 0, "Negative control actually loaded the exact original Toast source");
} catch (error) { infrastructureError = error.stack || String(error); }
finally {
  cdp?.close(); browser?.kill("SIGTERM"); await server?.close();
  await rm(harness, { recursive: true, force: true }); await rm(temp, { recursive: true, force: true });
}
const negativeReproduced = legacy && !infrastructureError && exceptions.length === 0 && legacyTransforms > 0 && failures.length > 0;
const report = {
  kind: "isolated actual source component harness; not a production campaign or physical mobile device", legacy,
  checks, failures, infrastructureError, browserExceptions: exceptions, evidence,
  fixture: { path: fixturePath, sha256: createHash("sha256").update(fixture).digest("hex"), transformCount: legacyTransforms },
  passed: !infrastructureError && failures.length === 0, negativeReproduced,
  limits: ["App owner checks are source assertions plus real blocked component behavior, not a full chapter-transition campaign.", "Phone/RPG replacement uses the actual ToastLayer with the same EventBus in an isolated host, not the entire RpgGameHost.", "Audio event timing is checked; real audio-device playback and human reading acceptance remain separate."]
};
await mkdir(artifacts, { recursive: true });
await writeFile(path.join(artifacts, legacy ? "legacy-report.json" : "report.json"), JSON.stringify(report, null, 2) + "\n");
if (legacy ? !negativeReproduced : !report.passed) {
  console.error(infrastructureError || failures.join("\n")); process.exitCode = 1;
} else console.log(legacy ? `NOTICE_PRESENTATION_LEGACY negative reproduced checks=${checks} failures=${failures.length}` : `NOTICE_PRESENTATION_BROWSER PASS checks=${checks}`);
