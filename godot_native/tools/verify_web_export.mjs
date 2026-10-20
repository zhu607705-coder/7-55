#!/usr/bin/env node
// Accepts the independent Godot Web export. No React APIs, writable game bridge,
// virtual game clock, chapter URL, or injected progression state is used.
import { spawn } from 'node:child_process';
import { createHash } from 'node:crypto';
import { createReadStream, existsSync } from 'node:fs';
import { mkdir, mkdtemp, readFile, readdir, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';

const args = process.argv.slice(2);
function option(name, fallback) { const inline = args.find(arg => arg.startsWith(`--${name}=`)); if (inline) return inline.slice(name.length + 3); const i = args.indexOf(`--${name}`); return i < 0 ? fallback : args[i + 1]; }
const url = option('url', process.env.GODOT_WEB_URL || 'http://127.0.0.1:5195/');
const output = path.resolve(option('output', process.env.GODOT_WEB_OUTPUT || `godot_native/exports/verification/web_${Date.now()}`));
const chrome = option('chrome', process.env.CHROME_BIN || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome');
const exportDir = option('export-dir', process.env.GODOT_WEB_EXPORT_DIR);
const fixtureDir = option('fixtures', process.env.GODOT_WEB_FIXTURES_DIR);
const c1Fixture = option('c1-fixture', process.env.GODOT_WEB_C1_FIXTURE || (fixtureDir ? path.join(fixtureDir, 'after_c1_checkin.json') : undefined));
const legacySave = option('legacy-save', process.env.GODOT_WEB_LEGACY_SAVE);
const only = option('only', 'all');
const scenarios = option('scenarios', 'all');
const importSettleMs = Number(option('import-settle-ms', 1600));
const bootTimeout = Number(option('boot-timeout', 360000));
const chromeArgs = args.flatMap((arg, i) => arg.startsWith('--chrome-arg=') ? [arg.slice('--chrome-arg='.length)] : arg === '--chrome-arg' && args[i + 1] ? [args[i + 1]] : []);
const interval = ms => new Promise(resolve => setTimeout(resolve, ms));
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const report = { schema: '755-godot-web-acceptance-v1', startedAt: new Date().toISOString(), url,
  passed: false, checks: [], cases: [], network: [], errors: [], limitations: [
    'Automated browser input and actual Godot clocks; this does not prove human audio audibility or a fresh manual four-chapter campaign.',
    'Chapter saves must be ordinary validated portable saves earned by a recorded controller campaign. Import is performed through the shipped file picker.',
    'This runner uses an isolated Chromium profile. Other browser engines and physical phones require separate acceptance.'
  ] };
const runnerBytes = await readFile(new URL(import.meta.url));
report.runnerSha256 = hash(runnerBytes);
if (exportDir && existsSync(path.join(exportDir, 'build-manifest.json'))) report.exportManifest = JSON.parse(await readFile(path.join(exportDir, 'build-manifest.json'), 'utf8'));
await mkdir(output, { recursive: true });
await writeFile(path.join(output, 'runner-source.mjs'), runnerBytes);
function check(ok, label, details) { const row = { ok: !!ok, label, ...(details === undefined ? {} : { details }) }; report.checks.push(row); if (!ok) throw new Error(label); }
async function persist() { await writeFile(path.join(output, 'web-acceptance.json'), JSON.stringify(report, null, 2) + '\n'); }
async function poll(fn, label, timeout = 20000) {
  const start = Date.now(); let error;
  while (Date.now() - start < timeout) { try { const value = await fn(); if (value) return value; } catch (e) { error = e; } await interval(100); }
  throw new Error(`Timeout: ${label}${error ? ` (${error.message})` : ''}`);
}
async function shaFile(filename) { const h = createHash('sha256'); for await (const chunk of createReadStream(filename)) h.update(chunk); return h.digest('hex'); }
async function connect(wsUrl, onEvent) {
  const ws = new WebSocket(wsUrl); await new Promise((resolve, reject) => { ws.addEventListener('open', resolve, { once: true }); ws.addEventListener('error', reject, { once: true }); });
  let sequence = 0; const pending = new Map();
  ws.addEventListener('message', event => { const message = JSON.parse(String(event.data)); if (message.method) { onEvent(message); return; } const item = pending.get(message.id); if (!item) return; pending.delete(message.id); clearTimeout(item.timer); message.error ? item.reject(new Error(message.error.message)) : item.resolve(message.result); });
  ws.addEventListener('close', () => { for (const item of pending.values()) { clearTimeout(item.timer); item.reject(new Error('CDP connection closed')); } pending.clear(); });
  return { send(method, params = {}, timeoutMs = 30000) { return new Promise((resolve, reject) => { const id = ++sequence; const timer = setTimeout(() => { pending.delete(id); reject(new Error(`CDP timeout ${method}`)); }, timeoutMs); pending.set(id, { resolve, reject, timer }); ws.send(JSON.stringify({ id, method, params })); }); }, close() { for (const item of pending.values()) { clearTimeout(item.timer); item.reject(new Error('CDP closed')); } pending.clear(); ws.close(); } };
}
let active;
async function evaluate(expression) { const result = await active.cdp.send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true }); if (result.exceptionDetails) throw new Error(result.exceptionDetails.exception?.description || result.exceptionDetails.text); return result.result.value; }
async function snapshot() { return evaluate('window.__GODOT_755__?.snapshot?.() ?? null'); }
const state = value => value?.state;
async function key(key, code, down) { await active.cdp.send('Input.dispatchKeyEvent', { type: down ? 'keyDown' : 'keyUp', key, code, windowsVirtualKeyCode: ({ Enter: 13, Escape: 27, F10: 121, ArrowLeft: 37, ArrowRight: 39, ArrowUp: 38, ArrowDown: 40, Space: 32 })[code] || 0 }); }
async function press(keyName, code = keyName) { await key(keyName, code, true); await interval(65); await key(keyName, code, false); }
async function clickPoint(point, touch = active.touch) { if (touch) { await active.cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ ...point, id: 1 }] }); await interval(65); await active.cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] }); } else { await active.cdp.send('Input.dispatchMouseEvent', { type: 'mouseMoved', ...point }); await active.cdp.send('Input.dispatchMouseEvent', { type: 'mousePressed', button: 'left', clickCount: 1, ...point }); await interval(65); await active.cdp.send('Input.dispatchMouseEvent', { type: 'mouseReleased', button: 'left', clickCount: 1, ...point }); } }
async function canvasGeometry() { return evaluate(`(()=>{const c=document.getElementById('canvas')||document.querySelector('canvas');if(!c)return null;const r=c.getBoundingClientRect();return{x:r.x,y:r.y,width:r.width,height:r.height,pixelWidth:c.width,pixelHeight:c.height};})()`); }
async function renderPoint(point, value) { value ||= await snapshot(); const canvas = await canvasGeometry(); const viewport = value.viewport || {}; const width = viewport.width || viewport.size?.x || canvas.pixelWidth; const height = viewport.height || viewport.size?.y || canvas.pixelHeight; return { x: canvas.x + point.x / width * canvas.width, y: canvas.y + point.y / height * canvas.height }; }
function controls(value) { return value?.visibleControls || []; }
async function clickControl(nameOrText, match = 'either') {
  const found = await poll(async () => { const s = await snapshot(); const c = controls(s).find(c => !c.disabled && (match !== 'text' && c.name === nameOrText || match !== 'name' && c.text === nameOrText)); return c ? { s, c } : null; }, `control ${nameOrText}`);
  const r = found.c.rect; await clickPoint(await renderPoint({ x: r.x + r.width / 2, y: r.y + r.height / 2 }, found.s)); await interval(350);
}
async function screenshot(name) { const data = (await active.cdp.send('Page.captureScreenshot', { format: 'png' }, 10000)).data; const bytes = Buffer.from(data, 'base64'); await writeFile(path.join(output, `${name}.png`), bytes); return { path: `${name}.png`, bytes: bytes.length, sha256: hash(bytes) }; }
async function startStory(reload = false) {
  const start = Date.now(); await active.cdp.send(reload ? 'Page.reload' : 'Page.navigate', reload ? { ignoreCache: true } : { url: active.url || url });
  await poll(() => evaluate("document.documentElement.dataset.bootState === 'ready'"), 'Godot engine initialized and PCK preloaded', bootTimeout);
  const bootReadyMs = Date.now() - start;
  const startRect = await evaluate("(()=>{const r=document.getElementById('start-game').getBoundingClientRect();return{x:r.x+r.width/2,y:r.y+r.height/2};})()"); await clickPoint(startRect);
  await poll(() => evaluate("document.documentElement.dataset.bootState === 'running'"), 'Godot engine running', 60000);
  await interval(500); await evaluate("(document.getElementById('canvas')||document.querySelector('canvas')).focus()");
  // One real Enter activates the focused entry button. Repeating it while Main
  // loads could accidentally press the next story action on a slower machine.
  await press('Enter');
  const s = await poll(async () => { const s = await snapshot(); return state(s)?.native ? s : null; }, 'real Main snapshot', 60000);
  console.log(`${active.id}: Godot ${s.version} ready=${bootReadyMs}ms Main=${Date.now() - start}ms${reload ? ' reload' : ''}`);
  check(s.web === true, `${active.id}: actual Godot Web feature`);
  check(s.engine && String(s.engine).toLowerCase().includes('godot') || s.version, `${active.id}: engine version exposed`, { engine: s.engine, version: s.version });
  check(s.developerAvailable === false || s.developerToolsAvailable === false || s.developerMode === false, `${active.id}: production developer tools unavailable`);
  check(!controls(s).some(c => /DEV|独立场景检查|动画与原型预览|章节跳转/.test(c.text)), `${active.id}: no chapter or QA controls`);
  return { snapshot: s, bootReadyMs, mainReadyMs: Date.now() - start };
}
async function assertLayout(label) {
  const geometry = await evaluate(`(()=>{const c=document.getElementById('canvas')||document.querySelector('canvas'),r=c.getBoundingClientRect();return{width:innerWidth,height:innerHeight,canvas:{x:r.x,y:r.y,width:r.width,height:r.height},overflowX:document.documentElement.scrollWidth>innerWidth,overflowY:document.documentElement.scrollHeight>innerHeight};})()`);
  check(!geometry.overflowX && !geometry.overflowY, `${label}: no document overflow`, geometry);
  check(geometry.canvas.width > 0 && geometry.canvas.height > 0 && geometry.canvas.x >= -1 && geometry.canvas.y >= -1 && geometry.canvas.x + geometry.canvas.width <= geometry.width + 1 && geometry.canvas.y + geometry.canvas.height <= geometry.height + 1, `${label}: canvas fits viewport`);
  const s = await snapshot(); const phone = s.phoneRect || s.viewport?.phoneRect;
  if (phone) check(Math.abs(phone.width / phone.height - .5) < .01, `${label}: phone has uniform 1:2 aspect`, phone);
  return geometry;
}
async function settings() { await press('F10'); await poll(async () => controls(await snapshot()).some(c => c.text === '导入存档'), 'settings opened'); }
async function importSave(filename) {
  const bytes = await readFile(filename); const envelope = JSON.parse(bytes); check(envelope.format === '7-55-godot-native' && envelope.version === 1 && envelope.state, `ordinary native portable envelope: ${path.basename(filename)}`);
  const beforeImport = await snapshot();
  await settings(); await clickControl('导入存档');
  const document = await active.cdp.send('DOM.getDocument', { depth: 0 }); const input = await active.cdp.send('DOM.querySelector', { nodeId: document.root.nodeId, selector: '#godot-save-import' }); check(input.nodeId > 0, 'shipped save file picker input exists');
  await active.cdp.send('DOM.setFileInputFiles', { nodeId: input.nodeId, files: [path.resolve(filename)] });
  const expected = envelope.state.native;
  const changedRoute = expected.chapter !== state(beforeImport).native.chapter || expected.page !== state(beforeImport).native.page || expected.scene !== state(beforeImport).native.scene;
  const s = await poll(async () => {
    const s = await snapshot(); const complete = changedRoute || s?.saveDigest !== beforeImport.saveDigest || controls(s).some(c => /存档已导入/.test(c.text)) || /存档已导入/.test(s?.world?.subtitle || '');
    return complete && state(s)?.native?.chapter === expected.chapter && state(s).native.page === expected.page && state(s).native.scene === expected.scene ? s : null;
  }, `validated native import completes ${path.basename(filename)}`, 60000);
  const firstAcceptedAt = Date.now();
  // Importing the just-downloaded save can retain the same route. Wait for the
  // next read-only bridge publication after its completion feedback rather than
  // mistaking a pre-import snapshot with equal route fields for completion.
  await interval(350);
  check(s.developerToolsAvailable === false, 'ordinary imported save remains formal progression');
  const completed = await snapshot();
  active.imports.push({ filename: path.basename(filename), sha256: hash(bytes), bytes: bytes.length, chapter: expected.chapter, page: expected.page, scene: expected.scene, firstAcceptedAt, observedAt: Date.now(), saveDigest: completed.saveDigest }); return completed;
}
async function freshCase() {
  const start = await startStory(); check(state(start.snapshot).native.page === 'alarm', `${active.id}: fresh story starts at alarm`);
  await clickControl('开始游戏'); await poll(async () => state(await snapshot())?.native.alarm_ringing, 'real alarm start');
  active.mediaObservations.push({ phase: 'alarm-ringing', audio: (await snapshot()).audio, video: (await snapshot()).video });
  await clickControl('关闭'); await poll(async () => state(await snapshot())?.native.page === 'desktop', 'real alarm dismiss');
  await clickControl('……再睡5分钟……'); await poll(async () => state(await snapshot())?.native.wake_warned, 'real wake warning');
  await clickControl('进入手机主界面'); await poll(async () => state(await snapshot())?.native.page === 'phone_home', 'real phone home');
  await assertLayout(active.id); await settings();
  const s = await snapshot(); const beforeMode = state(s).native.mode; const toggle = controls(s).find(c => c.text.startsWith('当前：')); check(!!toggle, 'mode toggle states current and destination'); await clickControl(toggle.text);
  await poll(async () => state(await snapshot())?.native.mode !== beforeMode, 'real mode toggle'); await clickControl('保存进度');
  const saved = await poll(async () => { const s = await snapshot(); return s.saveDigest ? s : null; }, 'native formal save exists');
  check(saved.persistentStorageAvailable === true, `${active.id}: IndexedDB persistent storage available`);
  const desired = { page: state(saved).native.page, chapter: state(saved).native.chapter, mode: state(saved).native.mode, flags: state(saved).flags };
  active.screenshots.push(await screenshot(`${active.id}-phone`));
  await interval(1600); const after = await startStory(true);
  check(JSON.stringify({ page: state(after.snapshot).native.page, chapter: state(after.snapshot).native.chapter, mode: state(after.snapshot).native.mode, flags: state(after.snapshot).flags }) === JSON.stringify(desired), `${active.id}: actual page reload retains native save and selected mode`);
  return { bootReadyMs: start.bootReadyMs, mainReadyMs: start.mainReadyMs, reloadedMainReadyMs: after.mainReadyMs, savedDigest: saved.saveDigest, geometry: await assertLayout(`${active.id}-reloaded`) };
}
async function portableSaveCase() {
  await settings(); await clickControl('导出存档');
  const filename = await poll(async () => (await readdir(active.downloadDir)).find(f => f.endsWith('.json')), 'real browser portable save download');
  const bytes = await readFile(path.join(active.downloadDir, filename)); const envelope = JSON.parse(bytes);
  check(envelope.format === '7-55-godot-native' && envelope.version === 1 && envelope.state?.native, 'downloaded file is an actual native portable save');
  const before = await snapshot(); check(envelope.state.native.chapter === state(before).native.chapter && envelope.state.native.page === state(before).native.page, 'portable download preserves current native story route');
  active.portable = { filename, bytes: bytes.length, sha256: hash(bytes), chapter: envelope.state.native.chapter, page: envelope.state.native.page };
  // Close the ordinary settings modal with the real key before the next case.
  await press('Escape'); await interval(350);
  await importSave(path.join(active.downloadDir, filename));
  check(state(await snapshot()).native.page === envelope.state.native.page, 'actual downloaded portable save can be re-imported through the ordinary file picker');
  const rejectedBefore = await snapshot(); const bad = path.join(active.downloadDir, 'invalid-save.json'); await writeFile(bad, '{"format":"7-55-godot-native","version":1,"state":');
  await settings(); await clickControl('导入存档'); const document = await active.cdp.send('DOM.getDocument', { depth: 0 }); const input = await active.cdp.send('DOM.querySelector', { nodeId: document.root.nodeId, selector: '#godot-save-import' }); await active.cdp.send('DOM.setFileInputFiles', { nodeId: input.nodeId, files: [bad] });
  await poll(async () => controls(await snapshot()).some(c => /JSON 格式无效/.test(c.text)), 'malformed ordinary file is visibly rejected');
  const rejectedAfter = await snapshot(); check(rejectedAfter.saveDigest === rejectedBefore.saveDigest && JSON.stringify(state(rejectedAfter)) === JSON.stringify(state(rejectedBefore)), 'malformed file preserves actual native state and saved bytes', { beforeSaveDigest: rejectedBefore.saveDigest, afterSaveDigest: rejectedAfter.saveDigest, beforeStateSha256: hash(JSON.stringify(state(rejectedBefore))), afterStateSha256: hash(JSON.stringify(state(rejectedAfter))) });
  await press('Escape'); await interval(350); await settings(); await clickControl('保存画面截图');
  const pngName = await poll(async () => (await readdir(active.downloadDir)).find(f => f.endsWith('.png')), 'ordinary screenshot PNG download'); const png = await readFile(path.join(active.downloadDir, pngName));
  check(png.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])) && png.readUInt32BE(16) === active.width && png.readUInt32BE(20) === active.height, 'downloaded Godot screenshot is PNG at the actual viewport dimensions');
  active.portable.roundTripImported = true; active.portable.invalidFileRejectedWithoutChanges = true; active.portable.screenshot = { filename: pngName, bytes: png.length, sha256: hash(png), width: png.readUInt32BE(16), height: png.readUInt32BE(20) };
}
async function legacyCase() {
  if (!legacySave) return;
  const raw = await readFile(legacySave, 'utf8'); const envelope = JSON.parse(raw); check(envelope.state && Number(envelope.version) >= 2 && Number(envelope.version) <= 35, 'legacy fixture is ordinary supported browser envelope');
  const keys = ['seven_fifty_five_state', 'seven_fifty_five_state_backup']; const original = state(await snapshot()).native;
  await evaluate(`(()=>{for(const key of ${JSON.stringify(keys)})localStorage.setItem(key,${JSON.stringify(raw)});})()`);
  const unchanged = await startStory(true); check(state(unchanged.snapshot).native.page === original.page && state(unchanged.snapshot).native.mode === original.mode, 'existing Web save never automatically overwrites current native progress');
  await settings(); await clickControl('导入原网页存档');
  const imported = await poll(async () => { const s = await snapshot(); return state(s)?.native?.save_import?.kind === 'browser' || state(s)?.native?.page !== original.page ? s : null; }, 'explicit legacy browser save migration', 30000);
  check(state(imported).flags.checkinDone === envelope.state.flags.checkinDone && state(imported).actOne.phase === envelope.state.actOne.phase, 'explicit migration preserves original browser story facts');
  const retained = await evaluate(`JSON.stringify(${JSON.stringify(keys)}.map(key=>localStorage.getItem(key)))`); check(retained === JSON.stringify([raw, raw]), 'explicit native import preserves both original Web localStorage keys byte for byte');
  await interval(1500); const reloaded = await startStory(true); check(state(reloaded.snapshot).native.page === state(imported).native.page && state(reloaded.snapshot).actOne.phase === state(imported).actOne.phase, 'migrated native save survives actual browser reload');
  check(await evaluate(`JSON.stringify(${JSON.stringify(keys)}.map(key=>localStorage.getItem(key)))`) === retained, 'native reload also preserves original Web localStorage bytes');
  active.legacy = { sourceSha256: hash(raw), sourceBytes: Buffer.byteLength(raw), explicitImport: true, originalKeysPreserved: true, nativeReload: true };
  console.log('desktop-1280: explicit legacy localStorage import and actual native reload passed');
  // Ordinary native settings remain reachable from the alarm and allow the next
  // portable save case. No story fact is inserted by this external harness.
}
async function fixtureCases() {
  if (!fixtureDir) return;
  const cases = [
    { file: 'after_c2_dorm_exit.json', name: 'c2-campus', predicate: s => s.native.scene === 'campus_bootstrap' },
    { file: 'after_c3_defense_result.json', name: 'c3-canteen-escape', predicate: s => s.native.scene === 'campus_bootstrap' && !s.native.c3_pending_handoff },
    { file: 'after_c3_enter_theater.json', name: 'c3-theater-entry', predicate: s => s.native.c3_theater_entry_seen === true },
    { file: 'after_c3_target_theater_exit.json', name: 'c3-lake-approach', predicate: s => s.qizhenLake.locationBriefingSeen === true },
    { file: 'action_c4_prologue_end.json', name: 'c4-real-map', predicate: s => s.native.scene === 'duan_yongping_temporal_maze' }
  ];
  active.chapterResults = [];
  for (const item of cases) {
    const filename = path.join(fixtureDir, item.file); if (!existsSync(filename)) throw new Error(`Missing earned chapter fixture ${filename}`);
    const initial = await importSave(filename); const beforeItems = JSON.stringify(state(initial).items);
    await poll(async () => { const s = state(await snapshot()); return s && item.predicate(s); }, `${item.name}: real presenter handoff completes`, 180000);
    const complete = await snapshot(); check(JSON.stringify(state(complete).items) === beforeItems, `${item.name}: presentation preserves inventory`);
    if (item.name === 'c4-real-map') check(complete.world.visible && !gameOf(complete)?.script, 'C4 early earned save exposes the actual A1 map without a closure activity');
    if (item.name === 'c2-campus') {
      const position = complete.world?.player; const rect = complete.world?.rect; check(position && rect && complete.world.visible, 'C2 real world surface and actor are visible');
      // Focus the actual canvas without issuing a mouse move-to destination;
      // otherwise a click route could be mistaken for keyboard movement.
      await evaluate("document.getElementById('canvas').focus()");
      let moved = false;
      for (const direction of ['ArrowRight', 'ArrowDown', 'ArrowLeft', 'ArrowUp']) {
        await key(direction, direction, true); await interval(500); await key(direction, direction, false); await interval(350);
        const now = (await snapshot()).world?.player; if (now && Math.hypot(now.x - position.x, now.y - position.y) > 3) { moved = true; break; }
      }
      check(moved, 'C2 real keyboard movement changes the Godot world actor');
    }
    active.screenshots.push(await screenshot(`${active.id}-${item.name}`)); await assertLayout(item.name);
    await interval(1500); const reloaded = await startStory(true); check(item.predicate(state(reloaded.snapshot)), `${item.name}: ordinary save and actual reload preserve completed handoff`);
    active.chapterResults.push({ name: item.name, chapter: state(reloaded.snapshot).native.chapter, scene: state(reloaded.snapshot).native.scene, page: state(reloaded.snapshot).native.page }); await persist();
    console.log(`desktop-1280: ${item.name} import, presenter and reload passed`);
  }
}
async function mediaCase() {
  if (!fixtureDir) return;
  await importSave(path.join(fixtureDir, 'after_c35_replay.json')); await startStory(true);
  const first = await poll(async () => { const s = await snapshot(); return s.video?.some(v => v.playing && !v.paused && v.position > .25 && v.stream.endsWith('.ogv')) ? s : null; }, 'real OGV VideoStreamPlayer advances', 30000);
  const video = first.video.find(v => v.playing && v.stream.endsWith('.ogv')); const audio = await poll(async () => (await snapshot()).audio?.find(a => a.playing && !a.paused && a.position > .25), 'actual prologue audio stream playback', 15000);
  await interval(2200); const second = await snapshot(); const video2 = second.video.find(v => v.stream === video.stream); const audio2 = second.audio.find(a => a.name === audio.name && a.stream === audio.stream);
  check(video2 && video2.position > video.position + 1.2, 'actual decoded OGV stream position grows while visible'); check(audio2 && audio2.position > audio.position + 1.2, 'actual Godot audio playback position grows while visible');
  active.mediaObservations.push({ phase: 'c4-prologue-playing', videoBefore: video, videoAfter: video2, audioBefore: audio, audioAfter: audio2 }); active.screenshots.push(await screenshot('desktop-c4-ogv-playing'));
  const beforeHide = await snapshot(); const pauseVideo = beforeHide.video.find(v => v.stream === video.stream); const pauseAudio = beforeHide.audio.find(a => a.name === audio.name && a.stream === audio.stream);
  const prologueMusic = beforeHide.audio.find(a => a.playing && a.channel === 'music' && a.cueId.startsWith('chapter4_prologue_'));
  const background = await active.cdp.send('Target.createTarget', { url: 'about:blank' }); await active.cdp.send('Target.activateTarget', { targetId: background.targetId }); await poll(() => evaluate('document.hidden'), 'real background tab visibility');
  const hiddenStarted = Date.now(); await interval(2000); const hiddenSnapshot = await snapshot();
  // Browsers may stop rAF while hidden, including the read-only bridge publisher.
  // Its cached .paused field is therefore not evidence about current playback.
  // Measure real playback positions immediately after foreground processing.
  await active.cdp.send('Page.bringToFront'); await active.cdp.send('Target.closeTarget', { targetId: background.targetId }); await poll(() => evaluate('!document.hidden'), 'foreground tab returns'); await interval(350);
  const afterShow = await snapshot(); const shownVideo = afterShow.video.find(v => v.stream === video.stream); const shownAudio = afterShow.audio.find(a => a.name === audio.name && a.stream === audio.stream);
  // The source procedural tune has a 12-note × 260ms loop. Account for its
  // wrap: a lower playhead after hiding must never masquerade as a pause.
  let audioAdvance = shownAudio && pauseAudio ? shownAudio.position - pauseAudio.position : Infinity;
  if (audioAdvance < 0 && pauseAudio?.name.startsWith('Chiptune_')) audioAdvance += pauseAudio.length || 3.12;
  const playbackPause = { hiddenMs: Date.now() - hiddenStarted, audioAdvanceSeconds: audioAdvance, beforeVideo: pauseVideo, hiddenCachedVideo: hiddenSnapshot.video.find(v => v.stream === video.stream), afterVideo: shownVideo, beforeAudio: pauseAudio, afterAudio: shownAudio };
  check(shownVideo && shownVideo.position - pauseVideo.position < 1.0, 'real hidden-tab interval does not advance the native OGV playhead', playbackPause);
  check(pauseAudio && shownAudio && audioAdvance >= -.05 && audioAdvance < 1.0, 'real hidden-tab interval does not advance the native audio playhead', playbackPause);
  const prologueMusicAfter = afterShow.audio.find(a => a.name === prologueMusic?.name && a.asset === prologueMusic?.asset);
  check(prologueMusic && prologueMusicAfter && prologueMusicAfter.position - prologueMusic.position >= -.05 && prologueMusicAfter.position - prologueMusic.position < 1.0, 'the exact C4 prologue music prefix preserves its playback timeline while hidden', { before: prologueMusic, after: prologueMusicAfter });
  check(Math.abs((prologueMusicAfter.position - prologueMusic.position) - (shownVideo.position - pauseVideo.position)) < .5, 'C4 prologue music and decoded OGV retain aligned visible-time advancement after backgrounding');
  await poll(async () => { const s = await snapshot(); return s.video?.some(v => v.stream === video.stream && !v.paused && v.position > shownVideo.position + .5); }, 'native OGV resumes from retained playhead');
  await clickControl('返回'); await poll(async () => !gameOf(await snapshot())?.script, 'ordinary media Return closes activity'); check(!state(await snapshot()).chapter4.prologueSeen, 'returning from media does not grant chapter completion');
  check(!(await snapshot()).audio.some(a => a.playing && a.cueId?.startsWith('chapter4_prologue_')), 'ordinary media Return retires its original C4 audio prefix');
  await clickControl('播放恢复回放'); await poll(async () => (await snapshot()).video?.some(v => v.playing && !v.paused && v.position > .25 && v.position < 4), 'ordinary media re-entry restarts its OGV stream');
  active.mediaObservations.push({ phase: 'c4-prologue-pause-return-reentry', playbackPause, resumedAndReentered: true });
  await clickControl('跳过恢复回放'); check(!state(await snapshot()).chapter4.prologueSeen, 'approved media skip still awaits explicit task acknowledgement'); await clickControl('收下任务，进入第四章');
  await poll(async () => state(await snapshot()).chapter4.prologueSeen && state(await snapshot()).native.scene === 'duan_yongping_temporal_maze', 'actual task acknowledgement hands off to native C4 A1', 30000);
  await interval(2000); const reloaded = await startStory(true); check(state(reloaded.snapshot).chapter4.prologueSeen && !gameOf(reloaded.snapshot)?.script, 'native media acknowledgement persists and does not replay after actual reload');
  console.log('desktop-1280: decoded OGV/audio, real hidden-tab pause/resume, Return/re-entry and acknowledged C4 handoff passed');
}
async function bikeCase() {
  if (!fixtureDir) return;
  const imported = await importSave(path.join(fixtureDir, 'before_c3_chase_result.json'));
  const earned = { items: state(imported).items, wallet: state(imported).wallet, canteen: state(imported).canteenHunt };
  check(earned.canteen.phase === 'chasing' && earned.canteen.bikePaid && !earned.canteen.chaseCompleted, 'earned bike save admits an unfinished paid ride without checkpoint seeding');
  // Native FileAccess has written the accepted import. The Web backend commits
  // that user filesystem asynchronously; use the same 1.6s settled-save window
  // as the ordinary save/reload case before destroying this document.
  await interval(importSettleMs); const reentry = await startStory(true);
  check(state(reentry.snapshot).native.chapter === 3 && state(reentry.snapshot).canteenHunt.phase === 'chasing' && !state(reentry.snapshot).canteenHunt.chaseCompleted, 'actual reload retains the imported paid unfinished bike save before rendering is assessed', { chapter: state(reentry.snapshot).native.chapter, page: state(reentry.snapshot).native.page, scene: state(reentry.snapshot).native.scene, phase: state(reentry.snapshot).canteenHunt.phase });
  const ready = await poll(async () => { const s = await snapshot(); const g = gameOf(s); return g?.mode === 'chase' && g.nativeChaseView?.ready3d && g.nativeChaseView?.presented ? s : null; }, 'real SourceChase3D geometry and first WebGL frame', 180000);
  check(!gameOf(ready).chase_presentation_error && !gameOf(ready).nativeChaseView.failure_reason, 'real source 3D bike view reports no presentation failure');
  check(gameOf(ready).nativeChaseView.meshInstances > 0, 'actual 3D bike SubViewport contains original source mesh instances');
  active.screenshots.push(await screenshot('desktop-source-chase3d-ready'));
  await clickControl('开始'); const before = await snapshot(); const lane = gameOf(before).model.lane;
  await key('ArrowRight', 'ArrowRight', true); await interval(650); await key('ArrowRight', 'ArrowRight', false);
  const right = await poll(async () => { const s = await snapshot(); return gameOf(s)?.model?.lane > lane + .15 ? s : null; }, 'real 3D bike right input changes lane');
  await key('ArrowLeft', 'ArrowLeft', true); await interval(650); await key('ArrowLeft', 'ArrowLeft', false);
  const left = await poll(async () => { const s = await snapshot(); return gameOf(s)?.model?.lane < gameOf(right).model.lane - .15 ? s : null; }, 'real 3D bike left input changes lane');
  await key(' ', 'Space', true); await interval(550); const charged = await snapshot(); check(gameOf(charged).model.charge > .25, 'real 3D bike held Space charges its jump'); await key(' ', 'Space', false);
  const jumped = await poll(async () => { const s = await snapshot(); return gameOf(s)?.model?.air_height > .1 ? s : null; }, 'real 3D bike released Space produces an airborne rider');
  check(gameOf(jumped).model.distance > gameOf(before).model.distance && gameOf(jumped).nativeChaseView.presented, 'native 3D road and rider render while the real model advances'); active.screenshots.push(await screenshot('desktop-source-chase3d-jump'));
  await clickControl('暂停'); const manualPause = await poll(async () => { const s = await snapshot(); return gameOf(s)?.paused ? s : null; }, 'ordinary bike pause');
  const background = await active.cdp.send('Target.createTarget', { url: 'about:blank' }); await active.cdp.send('Target.activateTarget', { targetId: background.targetId }); await poll(() => evaluate('document.hidden'), 'manual bike pause hidden tab'); await interval(1200); await active.cdp.send('Page.bringToFront'); await active.cdp.send('Target.closeTarget', { targetId: background.targetId }); await interval(400);
  const stillPaused = await snapshot(); check(gameOf(stillPaused).paused && gameOf(stillPaused).model.distance === gameOf(manualPause).model.distance, 'visibility restoration preserves a player-owned bike pause and model distance');
  await clickControl('退出'); await poll(async () => !gameOf(await snapshot())?.script, 'ordinary bike exit disposes the 3D activity');
  const after = state(await snapshot()); check(!after.canteenHunt.chaseCompleted && JSON.stringify(after.items) === JSON.stringify(earned.items) && JSON.stringify(after.wallet) === JSON.stringify(earned.wallet), 'exiting incomplete 3D ride preserves earned inventory, wallet and unfinished chase');
  await settings(); await clickControl('保存进度'); await interval(1500); await startStory(true);
  const resumed = await poll(async () => { const s = await snapshot(); return gameOf(s)?.mode === 'chase' && gameOf(s).nativeChaseView?.ready3d ? s : null; }, 'ordinary save reload re-enters the unfinished 3D bike ride', 180000);
  check(!state(resumed).canteenHunt.chaseCompleted && JSON.stringify(state(resumed).items) === JSON.stringify(earned.items) && JSON.stringify(state(resumed).wallet) === JSON.stringify(earned.wallet), 'actual native reload preserves the incomplete paid ride without granting 755m completion');
  await clickControl('退出'); await poll(async () => !gameOf(await snapshot())?.script, 'resumed bike exits through its ordinary control');
  active.bike = { realSource3d: true, firstFrame: gameOf(ready).nativeChaseView, rightLane: gameOf(right).model.lane, leftLane: gameOf(left).model.lane, jumpHeight: gameOf(jumped).model.air_height, charge: gameOf(charged).model.charge, distance: gameOf(jumped).model.distance, preservedPlayerPause: true, unfinishedSaveReload: true, completionClaimed: false };
  console.log('desktop-1280: real SourceChase3D WebGL rendering, steering/jump, manual pause ownership, exit and unfinished-save reload passed');
}
async function durabilityCase() {
  if (!fixtureDir) throw new Error('The durability diagnostic requires an earned fixture directory');
  const before = await snapshot(); const oldDocument = await evaluate('performance.timeOrigin');
  const imported = await importSave(path.join(fixtureDir, 'after_c2_dorm_exit.json')); const observed = active.imports.at(-1);
  check(state(imported).native.chapter === 2 && imported.saveDigest !== before.saveDigest, 'small ordinary import visibly changes native State and in-memory save bytes before reload', { beforeChapter: state(before).native.chapter, afterChapter: state(imported).native.chapter, beforeDigest: before.saveDigest, afterDigest: imported.saveDigest });
  await interval(importSettleMs); const beforeReload = await snapshot();
  active.durability = { settleMs: importSettleMs, importedObservedAt: observed.observedAt, reloadRequestedAt: Date.now(), beforeReloadChapter: state(beforeReload).native.chapter, beforeReloadPage: state(beforeReload).native.page, beforeReloadDigest: beforeReload.saveDigest };
  const reloaded = await startStory(true); const newDocument = await evaluate('performance.timeOrigin'); active.durability.afterReloadChapter = state(reloaded.snapshot).native.chapter; active.durability.afterReloadPage = state(reloaded.snapshot).native.page; active.durability.afterReloadDigest = reloaded.snapshot.saveDigest; active.durability.oldDocumentTimeOrigin = oldDocument; active.durability.newDocumentTimeOrigin = newDocument;
  check(newDocument !== oldDocument, 'durability check actually creates a fresh browser document and Godot engine');
  check(state(reloaded.snapshot).native.chapter === 2 && state(reloaded.snapshot).native.scene === 'campus_bootstrap', 'fresh browser reload preserves the small accepted ordinary import at the measured settle interval', active.durability);
  console.log(`desktop-1280: ordinary import durability passed with extra settle=${importSettleMs}ms`);
}
async function readPersistentSaveEntries() {
  return evaluate(`(async()=>{
    const started=performance.now(), databases=await indexedDB.databases(), entries=[];
    for(const meta of databases){
      if(!meta.name)continue;
      const db=await new Promise((resolve,reject)=>{const request=indexedDB.open(meta.name);request.onupgradeneeded=()=>request.transaction.abort();request.onsuccess=()=>resolve(request.result);request.onerror=()=>reject(request.error);});
      try{
        if(!db.objectStoreNames.contains('FILE_DATA'))continue;
        const rows=await new Promise((resolve,reject)=>{const tx=db.transaction('FILE_DATA','readonly'),store=tx.objectStore('FILE_DATA'),keys=store.getAllKeys(),values=store.getAll();tx.oncomplete=()=>resolve(keys.result.map((key,i)=>({key,value:values.result[i]})));tx.onerror=()=>reject(tx.error);});
        for(const row of rows){
          if(!/save.*\\.json$/i.test(String(row.key)))continue;
          const raw=row.value?.contents;
          if(!raw)continue;
          const bytes=raw instanceof Uint8Array?raw:new Uint8Array(raw),text=new TextDecoder().decode(bytes);
          let envelope;try{envelope=JSON.parse(text)}catch{continue}
          const digest=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',bytes))).map(v=>v.toString(16).padStart(2,'0')).join('');
          entries.push({database:meta.name,key:String(row.key),bytes:bytes.length,sha256:digest,chapter:envelope.state?.native?.chapter,page:envelope.state?.native?.page,scene:envelope.state?.native?.scene,canteenPhase:envelope.state?.canteenHunt?.phase});
        }
      }finally{db.close()}
    }
    return{readDurationMs:performance.now()-started,entries};
  })()`);
}
async function durabilitySwitchCase() {
  await importSave(path.join(fixtureDir, 'action_c4_prologue_end.json')); await interval(1600); const early = await startStory(true);
  check(state(early.snapshot).native.chapter === 4 && early.snapshot.world.visible && !gameOf(early.snapshot)?.script, 'durability switch uses an ordinary earlier C4 map without a chapter-ending input owner');
  const oldDisk = await readPersistentSaveEntries(); check(oldDisk.entries.some(e => e.key.endsWith('/save.json') && e.chapter === 4), 'read-only IDBFS observes the settled C4 primary save', oldDisk);
  const imported = await importSave(path.join(fixtureDir, 'before_c3_chase_result.json')); const observed = active.imports.at(-1);
  check(state(imported).native.chapter === 3 && state(imported).canteenHunt.phase === 'chasing', 'ordinary second import is visibly a paid unfinished C3 ride');
  await interval(importSettleMs); const inMemory = await snapshot(); const beforeReload = await readPersistentSaveEntries();
  active.durability = { mode: 'earlier-C4-map-to-earned-bike', extraSettleMs: importSettleMs, firstAcceptedAt: observed.firstAcceptedAt, observedAt: observed.observedAt, beforeReloadAt: Date.now(), memoryChapter: state(inMemory).native.chapter, memoryPage: state(inMemory).native.page, memorySaveDigest: inMemory.saveDigest, priorDisk: oldDisk, beforeReloadDisk: beforeReload, oldDocumentTimeOrigin: await evaluate('performance.timeOrigin') };
  const reloaded = await startStory(true); active.durability.newDocumentTimeOrigin = await evaluate('performance.timeOrigin'); active.durability.afterReloadChapter = state(reloaded.snapshot).native.chapter; active.durability.afterReloadPhase = state(reloaded.snapshot).canteenHunt.phase; active.durability.afterReloadSaveDigest = reloaded.snapshot.saveDigest;
  check(active.durability.oldDocumentTimeOrigin !== active.durability.newDocumentTimeOrigin, 'two-import durability reload creates a new document');
  check(state(reloaded.snapshot).native.chapter === 3 && state(reloaded.snapshot).canteenHunt.phase === 'chasing', 'rapid ordinary C4-map-to-bike import and reload preserve the new C3 save', active.durability);
  console.log('desktop-1280: rapid earlier-C4 to bike switch and read-only IDBFS primary/backup inspection passed');
}
function gameOf(s) { return s?.activeGame || s?.active_game; }
async function c1Case(full) {
  if (!c1Fixture) return;
  await importSave(c1Fixture); await clickControl('EndingResumeContinue');
  await poll(async () => gameOf(await snapshot())?.phase === 'deploy', 'C1 real seven-second blackout finishes', 60000);
  if (!full) {
    const s = await snapshot(), g = gameOf(s); const f = g.field; const scale = f.width / 430;
    const p = await renderPoint({ x: f.x + 215 * scale, y: f.y + 658 * scale }, s);
    await active.cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ ...p, id: 2 }] }); await active.cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ ...(await renderPoint({ x: f.x + 320 * scale, y: f.y + 658 * scale }, s)), id: 2 }] }); await interval(700);
    check(gameOf(await snapshot()).session.board_x > 250, 'C1 actual scaled touch drag moves the board');
    await active.cdp.send('Input.dispatchTouchEvent', { type: 'touchCancel', touchPoints: [] }); await interval(500); check(!gameOf(await snapshot()).dragging, 'C1 actual touch cancellation releases pointer ownership');
    active.screenshots.push(await screenshot('touch-c1-board')); return;
  }
  await poll(async () => gameOf(await snapshot())?.phase === 'failed', 'C1 stationary miss opens branch hint', 60000);
  const failure = gameOf(await snapshot()); await clickControl('继续当前阶段'); const retry = gameOf(await snapshot()); check(retry.session.stage === failure.session.stage && retry.misses === failure.misses, 'C1 failure continues current stage and preserves failure history');
  await clickControl('重看完整线索'); const review = gameOf(await snapshot()); await interval(1200); check(JSON.stringify(gameOf(await snapshot()).session.cards) === JSON.stringify(review.session.cards), 'C1 reread pauses actual moving word bodies'); await clickControl('继续寻找');
  let dragging = false; const until = Date.now() + 240000;
  while (Date.now() < until) {
    const s = await snapshot(), g = gameOf(s); if (!g || g.phase === 'lock') break;
    if (g.phase === 'failed') { if (dragging) { await active.cdp.send('Input.dispatchMouseEvent', { type: 'mouseReleased', button: 'left', clickCount: 1, x: 1, y: 1 }); dragging = false; } await clickControl('继续当前阶段'); continue; }
    if (!['deploy', 'intercept'].includes(g.phase)) { await interval(150); continue; }
    const model = g.session; const cards = model.cards || []; const wanted = model.missing || []; const next = wanted[0]; const ordered = model.current?.ordered; let desired = model.board_x; let found = false;
    for (const c of cards) if (!c.resolved && wanted.includes(c.text) && (!ordered || c.text === next)) { desired = c.position.x; found = true; break; }
    for (const c of cards) if (!c.resolved && (!wanted.includes(c.text) || ordered && c.text !== next) && (!found || c.position.y >= 500 && c.position.y <= 716) && Math.abs(Math.max(104, Math.min(326, desired)) - c.position.x) < 88 + c.size.x / 2) desired = c.position.x > 215 ? 104 : 326;
    const f = g.field, scale = f.width / 430;
    if (!dragging) { await active.cdp.send('Input.dispatchMouseEvent', { type: 'mousePressed', button: 'left', clickCount: 1, ...(await renderPoint({ x: f.x + model.board_x * scale, y: f.y + 658 * scale }, s)) }); dragging = true; }
    await active.cdp.send('Input.dispatchMouseEvent', { type: 'mouseMoved', button: 'left', buttons: 1, ...(await renderPoint({ x: f.x + desired * scale, y: f.y + 658 * scale }, s)) }); await interval(160);
  }
  if (dragging) await active.cdp.send('Input.dispatchMouseEvent', { type: 'mouseReleased', button: 'left', clickCount: 1, x: 1, y: 1 });
  const lock = gameOf(await snapshot()); check(lock?.phase === 'lock' && lock.blocks === 3, 'C1 real pointer contacts complete all three semantic stages');
  active.mediaObservations.push({ phase: 'c1-lock', audio: (await snapshot()).audio, video: (await snapshot()).video });
  active.screenshots.push(await screenshot('desktop-c1-lock')); await press(' ', 'Space'); await key(' ', 'Space', true); await interval(600); await key(' ', 'Space', false); await interval(400); check(gameOf(await snapshot()).phase === 'lock' && gameOf(await snapshot()).hold_ms === 0, 'C1 partial actual keyboard hold cannot complete');
  await key(' ', 'Space', true); await interval(600);
  const hiddenHold = await active.cdp.send('Target.createTarget', { url: 'about:blank' }); await active.cdp.send('Target.activateTarget', { targetId: hiddenHold.targetId }); await poll(() => evaluate('document.hidden'), 'C1 actual hidden tab during held lock'); await interval(1600); await active.cdp.send('Page.bringToFront'); await active.cdp.send('Target.closeTarget', { targetId: hiddenHold.targetId }); await interval(450);
  const returnedHold = gameOf(await snapshot()); check(returnedHold.phase === 'lock' && returnedHold.hold_ms === 0, 'C1 visibility loss releases a held lock without progression or stale input'); await key(' ', 'Space', false);
  if (returnedHold.paused) await clickControl('继续');
  await key(' ', 'Space', true); await interval(1650); await key(' ', 'Space', false); await poll(async () => gameOf(await snapshot())?.phase === 'caught', 'C1 actual hold reaches authored dialogue');
  await poll(async () => state(await snapshot())?.actOne.phase === 'friend_message_required', 'C1 authored dialogue and whiteout hand off to chapter two', 30000);
  await interval(1500); const reloaded = await startStory(true); check(state(reloaded.snapshot).actOne.phase === 'friend_message_required', 'C1 controller completion persists through actual page reload');
  console.log('desktop-1280: C1 six-word real pointer/keyboard run, authored C2 handoff and native reload passed');
}
async function browserCase(id, width, height, touch) {
  const temp = await mkdtemp(path.join(tmpdir(), '755-godot-web-browser-')); const profile = path.join(temp, 'profile'); const errors = []; const network = new Map(); const responses = new Map();
  const child = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-dev-shm-usage', '--disable-background-networking', '--disable-extensions', '--disable-sync', '--disable-default-apps', ...chromeArgs, `--window-size=${width},${height}`, '--force-device-scale-factor=1', `--user-data-dir=${profile}`, '--remote-debugging-port=0', 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] }); let stderr = ''; child.stderr.on('data', chunk => { stderr = (stderr + chunk).slice(-10000); });
  active = { id, width, height, touch, child, imports: [], screenshots: [], mediaObservations: [], downloadDir: path.join(temp, 'downloads') }; await mkdir(active.downloadDir);
  if (id === 'desktop-1440') { const negativeUrl = new URL(url); negativeUrl.searchParams.set('dev', '1'); negativeUrl.searchParams.set('devCheckpoint', 'c4-755-opening'); active.url = negativeUrl.href; }
  let result;
  try {
    const portFile = await poll(() => readFile(path.join(profile, 'DevToolsActivePort'), 'utf8'), 'isolated Chromium starts'); const port = portFile.split('\n')[0]; const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
    active.cdp = await connect(targets.find(t => t.type === 'page').webSocketDebuggerUrl, ({ method, params }) => {
      if (method === 'Runtime.exceptionThrown') errors.push({ type: 'pageerror', ...params.exceptionDetails });
      if (method === 'Runtime.consoleAPICalled' && ['error', 'warning'].includes(params.type)) { const text = params.args.map(a => a.value ?? a.description ?? '').join(' '); if (params.type === 'error' || /SCRIPT ERROR|Parse Error|Failed to load|ERROR:/.test(text)) errors.push({ type: params.type, text }); }
      if (method === 'Network.responseReceived') responses.set(params.requestId, { url: params.response.url, status: params.response.status, mimeType: params.response.mimeType, fromDiskCache: params.response.fromDiskCache || false });
      if (method === 'Network.loadingFinished' && responses.has(params.requestId)) network.set(responses.get(params.requestId).url, { ...responses.get(params.requestId), encodedDataLength: params.encodedDataLength });
      if (method === 'Network.loadingFailed' && !params.canceled) errors.push({ type: 'network', requestId: params.requestId, errorText: params.errorText });
    });
    await active.cdp.send('Page.enable'); await active.cdp.send('Runtime.enable'); await active.cdp.send('Network.enable'); await active.cdp.send('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: touch }); await active.cdp.send('Emulation.setTouchEmulationEnabled', { enabled: touch, maxTouchPoints: 1 });
    await active.cdp.send('Browser.setDownloadBehavior', { behavior: 'allow', downloadPath: active.downloadDir, eventsEnabled: true });
    result = await freshCase(); await portableSaveCase();
    if (id === 'desktop-1280') {
      if (scenarios === 'all') { await legacyCase(); await c1Case(true); await fixtureCases(); }
      if (scenarios === 'all' || scenarios === 'bike') await bikeCase();
      if (scenarios === 'all' || scenarios === 'media') await mediaCase();
      if (scenarios === 'durability') await durabilityCase();
      if (scenarios === 'durability-switch') await durabilitySwitchCase();
    } else if (touch && scenarios === 'all') await c1Case(false);
    const resources = [...network.values()].filter(n => /\.(wasm|pck)(?:$|\?)/.test(n.url)); check(resources.some(n => /\.wasm(?:$|\?)/.test(n.url) && n.status === 200), `${id}: actual engine WASM loaded over HTTP`); check(resources.some(n => /\.pck(?:$|\?)/.test(n.url) && n.status === 200), `${id}: actual Godot PCK loaded over HTTP`);
    check(![...network.values()].some(n => n.status >= 400), `${id}: no failed HTTP resources`, [...network.values()].filter(n => n.status >= 400));
    check(errors.length === 0, `${id}: no page, runtime, script or uncancelled network errors`, errors);
    const renderer = await evaluate(`(()=>{const c=document.getElementById('canvas')||document.querySelector('canvas');const gl=c.getContext('webgl2');if(!gl)return{webgl2:false};const e=gl.getExtension('WEBGL_debug_renderer_info');return{webgl2:true,vendor:e?gl.getParameter(e.UNMASKED_VENDOR_WEBGL):gl.getParameter(gl.VENDOR),renderer:e?gl.getParameter(e.UNMASKED_RENDERER_WEBGL):gl.getParameter(gl.RENDERER)};})()`);
    check(renderer.webgl2, `${id}: actual WebGL2 context available`, renderer);
    check(await evaluate("JSON.stringify(Object.keys(window.__GODOT_755__))") === '["snapshot"]', 'production browser bridge exposes only a read operation');
    check(await evaluate("(()=>{const s=window.__GODOT_755__.snapshot(),old=s.state.native.chapter;s.state.native.chapter=999;return window.__GODOT_755__.snapshot().state.native.chapter===old})()"), 'returned browser snapshot is a detached copy');
    report.cases.push({ id, width, height, touch, passed: true, ...result, portable: active.portable, imports: active.imports, legacy: active.legacy, bike: active.bike, durability: active.durability, chapterResults: active.chapterResults, screenshots: active.screenshots, mediaObservations: active.mediaObservations, renderer, network: resources, errors });
    report.network.push(...network.values());
  } catch (e) { report.cases.push({ id, width, height, touch, passed: false, result, error: e.stack || String(e), imports: active.imports, durability: active.durability, screenshots: active.screenshots, errors, stderr }); try { report.cases.at(-1).lastSnapshot = await snapshot(); report.cases.at(-1).failureScreenshot = await screenshot(`${id}-failure`); } catch {} throw e; }
  finally { active.cdp?.close(); child.kill('SIGTERM'); await interval(200); if (child.exitCode === null) child.kill('SIGKILL'); await rm(temp, { recursive: true, force: true }); await persist(); }
}
try {
  const selected = [['desktop-1280', 1280, 720, false], ['desktop-1440', 1440, 900, false], ['touch-390', 390, 844, true]].filter(([id]) => only === 'all' || id === only);
  check(selected.length > 0, 'at least one requested viewport selected');
  for (const selectedCase of selected) await browserCase(...selectedCase);
  const resources = new Map(report.network.filter(n => /\.(wasm|pck)(?:$|\?)/.test(n.url)).map(n => [n.url, n])); report.assets = [];
  for (const resource of resources.values()) {
    const response = await fetch(resource.url); check(response.ok, `asset independently fetched: ${resource.url}`); const h = createHash('sha256'); let bytes = 0; for await (const chunk of response.body) { h.update(chunk); bytes += chunk.length; } const sha256 = h.digest('hex');
    const filename = path.basename(new URL(resource.url).pathname); const local = exportDir ? path.join(exportDir, filename) : null; if (local) { check(existsSync(local), `export artifact exists: ${filename}`); check(await shaFile(local) === sha256, `HTTP bytes match actual Godot export: ${filename}`); }
    report.assets.push({ url: resource.url, bytes, sha256, local });
  }
  report.passed = report.cases.every(c => c.passed) && report.checks.every(c => c.ok);
} catch (e) { report.errors.push(e.stack || String(e)); process.exitCode = 1; }
report.completedAt = new Date().toISOString(); await persist();
console.log(`Godot Web acceptance ${report.passed ? 'PASS' : 'FAIL'}: ${report.checks.length} checks; ${report.cases.length} browser cases; ${output}`);
if (!report.passed) console.error(report.errors.join('\n'));
