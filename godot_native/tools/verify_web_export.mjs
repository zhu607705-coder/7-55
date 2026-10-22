#!/usr/bin/env node
// Accepts the independent Godot Web export. No React APIs, writable game bridge,
// virtual game clock, chapter URL, or injected progression state is used.
import { spawn } from 'node:child_process';
import { createHash } from 'node:crypto';
import { createReadStream, existsSync } from 'node:fs';
import { mkdir, mkdtemp, readFile, readdir, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { phoneRecoveryCase } from './web_phone_recovery.mjs';

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
if (!['all', 'bike', 'media', 'durability', 'durability-switch', 'streaming', 'mobile-world', 'phone-recovery'].includes(scenarios)) throw new Error(`Unknown scenario: ${scenarios}`);
const importSettleMs = Number(option('import-settle-ms', 1600));
const bootTimeout = Number(option('boot-timeout', 360000));
const chromeArgs = args.flatMap((arg, i) => arg.startsWith('--chrome-arg=') ? [arg.slice('--chrome-arg='.length)] : arg === '--chrome-arg' && args[i + 1] ? [args[i + 1]] : []);
function artifactLocation(assetUrl, pageUrl = url, rootDirectory = exportDir) {
  const base = new URL('.', pageUrl);
  const asset = new URL(assetUrl);
  if (asset.origin !== base.origin || !asset.pathname.startsWith(base.pathname) || asset.search || asset.hash) throw new Error(`Resource is outside the accepted page origin/base: ${assetUrl}`);
  const relativePath = decodeURIComponent(asset.pathname.slice(base.pathname.length));
  if (!relativePath || relativePath.startsWith('/') || relativePath.includes('\\') || /[\x00-\x1f\x7f]/.test(relativePath) || relativePath.split('/').some(part => ['', '.', '..'].includes(part))) throw new Error(`Invalid resource path: ${assetUrl}`);
  const root = rootDirectory ? path.resolve(rootDirectory) : null;
  const local = root ? path.resolve(root, relativePath) : null;
  if (local && !local.startsWith(root + path.sep)) throw new Error(`Resource escapes export directory: ${assetUrl}`);
  return { relativePath, local };
}
if (args.includes('--self-test-paths')) {
  const base = 'http://127.0.0.1:5211/7-55/';
  const root = '/tmp/755-artifact-path-unit';
  const examples = [['index.wasm', 'index.wasm'], ['content/chapter2_001-abcd.pck', 'content/chapter2_001-abcd.pck'], ['boot/index-wasm-0001-abcd.bin', 'boot/index-wasm-0001-abcd.bin']];
  for (const [resource, expected] of examples) {
    const actual = artifactLocation(new URL(resource, base).href, base, root);
    if (actual.relativePath !== expected || actual.local !== path.join(root, expected)) throw new Error('Artifact path self-test failed');
  }
  for (const resource of ['http://127.0.0.1:5212/7-55/index.pck', 'http://127.0.0.1:5211/other/index.pck', 'http://127.0.0.1:5211/7-55/%2e%2e/index.pck', 'http://127.0.0.1:5211/7-55/content/%2f..%2f..%2fescape.pck', 'http://127.0.0.1:5211/7-55/content/%5cescape.pck', 'http://127.0.0.1:5211/7-55/index.pck?seed=1']) {
    let rejected = false; try { artifactLocation(resource, base, root); } catch { rejected = true; }
    if (!rejected) throw new Error(`Artifact path self-test did not reject ${resource}`);
  }
  console.log('Artifact path self-test PASS: root and nested content paths, origin/base, encoded traversal, backslash and query controls');
  process.exit(0);
}
const interval = ms => new Promise(resolve => setTimeout(resolve, ms));
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const report = { schema: '755-godot-web-acceptance-v1', startedAt: new Date().toISOString(), url, scenarios,
  passed: false, checks: [], cases: [], network: [], errors: [], limitations: [
    'Automated browser input and actual Godot clocks; this does not prove human audio audibility or a fresh manual four-chapter campaign.',
    'Chapter saves must be ordinary validated portable saves earned by a recorded controller campaign. Import is performed through the shipped file picker.',
    'This runner uses an isolated Chromium profile. Other browser engines and physical phones require separate acceptance.'
  ] };
if (scenarios === 'mobile-world') report.limitations.push('This focused scenario imports one controller-earned C2 fixture and tests actual world input; C3/C4, deeper campaign routes and full media lifecycle are not run here.');
if (scenarios === 'phone-recovery') report.limitations.push('Zero/one-percent legacy files are explicitly constructed compatibility variants of an earned plant boundary. Their construction is not browser evidence; actual charging and two-stage Tiyi input are tested separately.');
const runnerBytes = await readFile(new URL(import.meta.url));
report.runnerSha256 = hash(runnerBytes);
if (exportDir && existsSync(path.join(exportDir, 'build-manifest.json'))) report.exportManifest = JSON.parse(await readFile(path.join(exportDir, 'build-manifest.json'), 'utf8'));
await mkdir(output, { recursive: true });
await writeFile(path.join(output, 'runner-source.mjs'), runnerBytes);
if (scenarios === 'phone-recovery') {
  const dependency = await readFile(new URL('./web_phone_recovery.mjs', import.meta.url));
  report.phoneRecoveryRunnerSha256 = hash(dependency);
  await writeFile(path.join(output, 'phone-recovery-runner.mjs'), dependency);
}
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
let delivery;
async function prepareDeliveryEvidence() {
  const base = new URL('.', url);
  async function manifest(name) {
    const response = await fetch(new URL(name, base), { cache: 'no-cache' });
    check(response.status === 200, `actual HTTP ${name} is available`);
    const bytes = Buffer.from(await response.arrayBuffer());
    if (exportDir) check(await shaFile(path.join(exportDir, name)) === hash(bytes), `HTTP ${name} matches the accepted export`);
    return { value: JSON.parse(bytes), sha256: hash(bytes) };
  }
  const build = await manifest('build-manifest.json');
  const content = await manifest('content-manifest.json');
  const value = build.value, chunks = value.bootChunks;
  check(value.runtime === 'godot-web' && value.storyOnly === true && Array.isArray(value.files), 'actual build manifest declares the independent story-only release');
  check(value.engine === '4.7.1.stable.official' && value.pack?.engine === '4.7.1' && value.fullPack?.engine === '4.7.1', 'actual HTTP build manifest declares the pinned Godot 4.7.1 engine and both PCK identities');
  check(content.value.schema === '755-web-content-v1' && content.value.engine === '4.7.1' && Array.isArray(content.value.packs) && content.value.packs.every(pack => !pack.family.startsWith('campus_')), 'actual delivery includes story content without research campus families');
  check(chunks?.schema === '755-boot-chunks-v1' && chunks.chunkBytes === 1048576 && JSON.stringify(Object.keys(chunks.resources || {}).sort()) === '["index.pck","index.wasm"]', 'actual delivery declares both statically chunked boot resources');
  const files = new Map(value.files.map(file => [file.path, file]));
  check(files.size === value.files.length, 'actual build file identities are unique');
  const transport = [];
  const bootByUrl = new Map();
  const originalUrls = new Set();
  for (const name of ['index.pck', 'index.wasm']) {
    const resource = chunks.resources[name], full = files.get(name);
    check(full && resource.file === name && Number.isSafeInteger(resource.bytes) && resource.bytes > 0 && /^[a-f0-9]{64}$/.test(resource.sha256) && resource.bytes === full.bytes && resource.sha256 === full.sha256 && Array.isArray(resource.chunks) && resource.chunks.length === Math.ceil(resource.bytes / chunks.chunkBytes), `boot resource matches its original full artifact identity: ${name}`);
    if (name === 'index.pck') check(resource.file === content.value.core.file && resource.bytes === content.value.core.bytes && resource.sha256 === content.value.core.sha256, 'chunked boot core matches the content coordinator manifest');
    originalUrls.add(new URL(name, base).href);
    let offset = 0;
    for (const chunk of resource.chunks) {
      const assetUrl = new URL(chunk.file, base).href;
      const { relativePath } = artifactLocation(assetUrl);
      const listed = files.get(relativePath);
      if (!relativePath.startsWith('boot/') || !relativePath.endsWith('.bin') || chunk.offset !== offset || chunk.bytes !== Math.min(chunks.chunkBytes, resource.bytes - offset) || !/^[a-f0-9]{64}$/.test(chunk.sha256) || !listed || listed.bytes !== chunk.bytes || listed.sha256 !== chunk.sha256 || bootByUrl.has(assetUrl)) throw new Error(`Invalid boot chunk coverage or identity: ${name}:${offset}`);
      const record = { ...chunk, resource: name, role: 'boot-chunk', url: assetUrl };
      bootByUrl.set(assetUrl, record); transport.push(record); offset += chunk.bytes;
    }
    check(offset === resource.bytes, `boot chunk map exactly covers ${name}`);
  }
  for (const pack of content.value.packs) {
    const assetUrl = new URL(pack.file, base).href;
    const { relativePath } = artifactLocation(assetUrl);
    const listed = files.get(relativePath);
    if (!relativePath.startsWith('content/') || !relativePath.endsWith('.pck') || !listed || listed.bytes !== pack.bytes || listed.sha256 !== pack.sha256) throw new Error(`Deferred PCK identity differs from build: ${pack.file}`);
    transport.push({ ...pack, role: 'deferred-pck', url: assetUrl });
  }
  check(new Set(transport.map(asset => asset.url)).size === transport.length, 'actual boot and deferred transport paths have no duplicates');
  const evidence = { buildManifestSha256: build.sha256, contentManifestSha256: content.sha256, bootResources: chunks.resources, transportFiles: transport.map(({ role, resource, file, url, bytes, sha256 }) => ({ role, resource, file, url, bytes, sha256 })), originalArtifactsRetained: [...originalUrls], originalArtifactsClaimedAsBrowserDownloads: false };
  report.delivery = evidence;
  return { build: value, content: content.value, bootByUrl, originalUrls, transport, evidence };
}
async function verifyColdBoot(start) {
  await poll(() => [...delivery.bootByUrl.keys()].every(url => active.bootResponses.some(record => record.url === url && record.requestAt >= start && !record.pending)), 'every actual cold boot chunk has an independently inspected browser response', bootTimeout);
  for (const name of ['index.pck', 'index.wasm']) {
    const expected = [...delivery.bootByUrl.values()].filter(chunk => chunk.resource === name);
    const rows = expected.map(chunk => ({ ...active.bootResponses.find(record => record.url === chunk.url && record.requestAt >= start), expectedBytes: chunk.bytes, expectedSha256: chunk.sha256 }));
    check(rows.every(record => record.status === 200 && !record.fromDiskCache && !record.fromServiceWorker && !record.range && !record.error && record.bytes === record.expectedBytes && record.sha256 === record.expectedSha256), `${active.id}: cold ${name} loads entirely from real HTTP 200 static chunks with verified response bytes`, rows);
  }
  const originals = active.requests.filter(request => request.at >= start && delivery.originalUrls.has(request.url));
  check(originals.length === 0, `${active.id}: cold chunk transport does not fetch the original PCK or WASM`, originals);
  active.coldBoot = { startedAt: start, verifiedAt: Date.now(), responses: active.bootResponses.filter(record => record.requestAt >= start).map(record => ({ ...record })), originalHttpRequests: originals, engineProof: 'Boot readiness is followed by the real Enter entry action and ordinary fresh-game pointer/touch input in this case.' };
}
async function evaluate(expression) { const result = await active.cdp.send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true }); if (result.exceptionDetails) throw new Error(result.exceptionDetails.exception?.description || result.exceptionDetails.text); return result.result.value; }
async function snapshot() { return evaluate('window.__GODOT_755__?.snapshot?.() ?? null'); }
const state = value => value?.state;
async function key(key, code, down) { if (active.mobileWorld) active.mobileWorld.inputs.push({ at: Date.now(), method: 'Input.dispatchKeyEvent', key, code, down }); await active.cdp.send('Input.dispatchKeyEvent', { type: down ? 'keyDown' : 'keyUp', key, code, windowsVirtualKeyCode: ({ Enter: 13, Escape: 27, F10: 121, ArrowLeft: 37, ArrowRight: 39, ArrowUp: 38, ArrowDown: 40, Space: 32 })[code] || 0 }); }
async function press(keyName, code = keyName) { await key(keyName, code, true); await interval(65); await key(keyName, code, false); }
async function clickPoint(point, touch = active.touch) { if (active.mobileWorld) active.mobileWorld.inputs.push({ at: Date.now(), method: touch ? 'ordinaryTouchTap' : 'ordinaryMouseClick', point, touch }); if (touch) { await active.cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ ...point, id: 1 }] }); await interval(65); await active.cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] }); } else { await active.cdp.send('Input.dispatchMouseEvent', { type: 'mouseMoved', ...point }); await active.cdp.send('Input.dispatchMouseEvent', { type: 'mousePressed', button: 'left', clickCount: 1, ...point }); await interval(65); await active.cdp.send('Input.dispatchMouseEvent', { type: 'mouseReleased', button: 'left', clickCount: 1, ...point }); } }
async function canvasGeometry() { return evaluate(`(()=>{const c=document.getElementById('canvas')||document.querySelector('canvas');if(!c)return null;const r=c.getBoundingClientRect();return{x:r.x,y:r.y,width:r.width,height:r.height,pixelWidth:c.width,pixelHeight:c.height};})()`); }
async function renderPoint(point, value) { value ||= await snapshot(); const canvas = await canvasGeometry(); const viewport = value.viewport || {}; const width = viewport.width || viewport.size?.x || canvas.pixelWidth; const height = viewport.height || viewport.size?.y || canvas.pixelHeight; return { x: canvas.x + point.x / width * canvas.width, y: canvas.y + point.y / height * canvas.height }; }
function controls(value) { return value?.visibleControls || []; }
async function clickControl(nameOrText, match = 'either') {
  const found = await poll(async () => { const s = await snapshot(); const c = controls(s).find(c => !c.disabled && (match !== 'text' && c.name === nameOrText || match !== 'name' && c.text === nameOrText)); return c ? { s, c } : null; }, `control ${nameOrText}`);
  const r = found.c.rect; const point = await renderPoint({ x: r.x + r.width / 2, y: r.y + r.height / 2 }, found.s);
  if (active.fresh?.recording) active.fresh.inputs.push({ at: Date.now(), text: found.c.text, name: found.c.name, rect: r, point, touch: active.touch, observedMode: state(found.s)?.native?.mode, observedSaveDigest: found.s.saveDigest });
  await clickPoint(point); await interval(350);
}
async function screenshot(name) { const data = (await active.cdp.send('Page.captureScreenshot', { format: 'png' }, 10000)).data; const bytes = Buffer.from(data, 'base64'); await writeFile(path.join(output, `${name}.png`), bytes); return { path: `${name}.png`, bytes: bytes.length, sha256: hash(bytes) }; }
async function waitForPersistedSave(label, previousToken = -1, visibleSuccess = false) {
  const began = Date.now();
  const attempt = { label, beganAt: began, previousToken, visibleSuccess, observations: [] };
  (active.saveAttempts ||= []).push(attempt);
  let observed = '';
  let saved;
  try { saved = await poll(async () => {
    const value = await snapshot(); const receipt = value?.savePersistence;
    const identity = JSON.stringify([receipt, value?.saveDigest]);
    if (identity !== observed && attempt.observations.length < 160) {
      observed = identity;
      attempt.observations.push({ elapsedMs: Date.now() - began, receipt, currentDigest: value?.saveDigest });
    }
    if (!receipt || receipt.token <= previousToken) return null;
    if (receipt.error) throw new Error(`Browser save receipt failed: ${receipt.error}`);
    const visible = !visibleSuccess || controls(value).some(c => c.name === 'SaveNativeProgress' && c.text === '已保存' && !c.disabled);
    return visible && !receipt.pending && receipt.digest && receipt.acknowledgedDigest === receipt.digest && receipt.digest === value.saveDigest ? value : null;
  }, `${label}: current native save has an exact durable receipt`, 30000);
  } catch (error) {
    attempt.failedAt = Date.now();
    // A readonly backing-store sample diagnoses a failed receipt without
    // accepting it, retrying a game save, or extending the original watchdog.
    try { attempt.failureDisk = await readPersistentSaveEntries(); }
    catch (readError) { attempt.failureDisk = { error: readError.message }; }
    throw error;
  }
  const disk = await readPersistentSaveEntries(); const primary = disk.entries.find(e => e.key.endsWith('/save.json'));
  attempt.completedAt = Date.now(); attempt.disk = disk;
  check(primary?.sha256 === saved.saveDigest, `${label}: independent readonly IndexedDB primary matches the current native save`, { elapsedMs: Date.now() - began, receipt: saved.savePersistence, primary, diskReadMs: disk.readDurationMs });
  return saved;
}
async function saveProgressAndWait(label) {
  const before = await snapshot();
  await clickControl('SaveNativeProgress', 'name');
  return waitForPersistedSave(label, before.savePersistence?.token ?? -1, true);
}
async function startStory(reload = false) {
  if (reload) await waitForPersistedSave(`${active.id} before actual reload`);
  const start = Date.now(); await active.cdp.send(reload ? 'Page.reload' : 'Page.navigate', reload ? { ignoreCache: true } : { url: active.url || url });
  await poll(() => evaluate("document.documentElement.dataset.bootState === 'ready'"), 'Godot engine initialized and PCK preloaded', bootTimeout);
  const bootReadyMs = Date.now() - start;
  if (!reload && !active.coldBoot) await verifyColdBoot(start);
  if (active.streaming) {
    const deferred = active.requests.filter(request => request.at >= start && active.deferredUrls.has(request.url));
    check(deferred.length === 0, `${active.id}: initial engine/first-chapter stage never requests deferred packs`, deferred);
    active.streaming.boots.push({ at: start, reload, bootReadyMs, deferredRequestsBeforeStart: deferred.length, initialRequests: active.requests.filter(request => request.at >= start).map(request => ({ url: request.url, at: request.at })) });
  }
  const startRect = await evaluate("(()=>{const r=document.getElementById('start-game').getBoundingClientRect();return{x:r.x+r.width/2,y:r.y+r.height/2};})()"); await clickPoint(startRect);
  await poll(() => evaluate("document.documentElement.dataset.bootState === 'running'"), 'Godot engine running', 60000);
  await interval(500); await evaluate("(document.getElementById('canvas')||document.querySelector('canvas')).focus()");
  // One real Enter activates the focused entry button. Repeating it while Main
  // loads could accidentally press the next story action on a slower machine.
  await press('Enter');
  const s = await poll(async () => { const s = await snapshot(); return state(s)?.native ? s : null; }, 'real Main snapshot', 60000);
  console.log(`${active.id}: Godot ${s.version} ready=${bootReadyMs}ms Main=${Date.now() - start}ms${reload ? ' reload' : ''}`);
  check(s.web === true, `${active.id}: actual Godot Web feature`);
  check(s.engine === 'Godot' && s.version === '4.7.1-stable (official)', `${active.id}: actual pinned Godot 4.7.1 official runtime`, { engine: s.engine, version: s.version });
  check(s.developerAvailable === false || s.developerToolsAvailable === false || s.developerMode === false, `${active.id}: production developer tools unavailable`);
  check(!controls(s).some(c => /DEV|独立场景检查|动画与原型预览|章节跳转/.test(c.text)), `${active.id}: no chapter or QA controls`);
  return { snapshot: s, bootReadyMs, mainReadyMs: Date.now() - start };
}
async function assertLayout(label) {
  const geometry = await evaluate(`(()=>{const c=document.getElementById('canvas')||document.querySelector('canvas'),r=c.getBoundingClientRect();return{width:innerWidth,height:innerHeight,dpr:devicePixelRatio,canvas:{x:r.x,y:r.y,width:r.width,height:r.height,pixelWidth:c.width,pixelHeight:c.height},overflowX:document.documentElement.scrollWidth>innerWidth,overflowY:document.documentElement.scrollHeight>innerHeight};})()`);
  check(!geometry.overflowX && !geometry.overflowY, `${label}: no document overflow`, geometry);
  check(geometry.canvas.width > 0 && geometry.canvas.height > 0 && geometry.canvas.x >= -1 && geometry.canvas.y >= -1 && geometry.canvas.x + geometry.canvas.width <= geometry.width + 1 && geometry.canvas.y + geometry.canvas.height <= geometry.height + 1, `${label}: canvas fits viewport`);
  const s = await snapshot(); const phone = s.phoneRect || s.viewport?.phoneRect;
  check(Math.abs(geometry.dpr - active.dpr) < .01, `${label}: actual browser pixel ratio matches the test`, geometry);
  check(Math.abs(s.viewport.width - geometry.canvas.width) <= 2 && Math.abs(s.viewport.height - geometry.canvas.height) <= 2, `${label}: logical Godot layout uses CSS dimensions on high-density screens`, { viewport: s.viewport, geometry });
  check(Math.abs(geometry.canvas.pixelWidth - geometry.canvas.width * geometry.dpr) <= 2 && Math.abs(geometry.canvas.pixelHeight - geometry.canvas.height * geometry.dpr) <= 2, `${label}: high-density rendering keeps the full backing resolution`, geometry);
  if (phone) {
    check(Math.abs(phone.width / phone.height - .5) < .01, `${label}: phone has uniform 1:2 aspect`, phone);
    check(phone.x >= 0 && phone.y >= 0 && phone.x + phone.width <= s.viewport.width + 1 && phone.y + phone.height <= s.viewport.height + 1, `${label}: phone and its hit areas stay inside the logical viewport`, phone);
    check(phone.height >= geometry.height * .85 || phone.width >= geometry.width * .9, `${label}: phone uses the available height or portrait width instead of shrinking to physical pixels`, { phone, geometry });
  }
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
async function freshCase(entryOnly = false) {
  // Focused input scenarios still cold-boot and enter through ordinary controls.
  // The separate default gate retains the complete generic persistence baseline.
  if (entryOnly) active.fresh = { scope: 'cold-boot-to-phone-only', persistenceBaselineRepeated: false, recording: true, inputs: [], startedAt: Date.now() };
  const start = await startStory(); check(state(start.snapshot).native.page === 'alarm', `${active.id}: fresh story starts at alarm`);
  await clickControl('开始游戏'); await poll(async () => state(await snapshot())?.native.alarm_ringing, 'real alarm start');
  active.mediaObservations.push({ phase: 'alarm-ringing', audio: (await snapshot()).audio, video: (await snapshot()).video });
  await clickControl('关闭'); await poll(async () => state(await snapshot())?.native.page === 'desktop', 'real alarm dismiss');
  await clickControl('……再睡5分钟……'); await poll(async () => state(await snapshot())?.native.wake_warned, 'real wake warning');
  await clickControl('进入手机主界面'); await poll(async () => state(await snapshot())?.native.page === 'phone_home', 'real phone home');
  const geometry = await assertLayout(active.id);
  if (entryOnly) {
    active.fresh.recording = false; active.fresh.completedAt = Date.now();
    return { bootReadyMs: start.bootReadyMs, mainReadyMs: start.mainReadyMs, geometry };
  }
  await settings();
  const evidence = value => ({ page: state(value)?.native?.page, chapter: state(value)?.native?.chapter, mode: state(value)?.native?.mode, flags: state(value)?.flags, saveDigest: value?.saveDigest });
  const s = await snapshot(); const beforeMode = state(s).native.mode; const toggle = controls(s).find(c => c.text.startsWith('当前：')); check(!!toggle, 'mode toggle states current and destination');
  active.fresh = { recording: true, inputs: [], before: evidence(s) };
  await clickControl(toggle.text);
  const toggled = await poll(async () => { const value = await snapshot(); return state(value)?.native.mode !== beforeMode ? value : null; }, 'real mode toggle');
  active.fresh.toggled = evidence(toggled);
  const saved = await saveProgressAndWait(`${active.id} explicit save`);
  active.fresh.saved = evidence(saved); active.fresh.savedObservedAt = Date.now();
  check(saved.persistentStorageAvailable === true, `${active.id}: IndexedDB persistent storage available`);
  const desired = { page: state(saved).native.page, chapter: state(saved).native.chapter, mode: state(saved).native.mode, flags: state(saved).flags };
  active.screenshots.push(await screenshot(`${active.id}-phone`));
  // The visible saved acknowledgement now proves this generation reached IDB.
  // Retain the additional original settle interval and independent diagnostics;
  // never substitute an arbitrary delay for the actual completion receipt.
  await interval(1600); active.fresh.beforeReload = evidence(await snapshot());
  active.fresh.persistentReadStartedAt = Date.now();
  try { active.fresh.beforeReloadIDB = await readPersistentSaveEntries(); } catch (error) { active.fresh.beforeReloadIDB = { error: error.message }; }
  active.fresh.reloadRequestedAt = Date.now(); active.fresh.recording = false;
  const after = await startStory(true);
  const actual = { page: state(after.snapshot).native.page, chapter: state(after.snapshot).native.chapter, mode: state(after.snapshot).native.mode, flags: state(after.snapshot).flags };
  active.fresh.desired = desired; active.fresh.afterReload = evidence(after.snapshot);
  active.fresh.differences = Object.keys(desired).filter(key => JSON.stringify(desired[key]) !== JSON.stringify(actual[key]));
  check(JSON.stringify(actual) === JSON.stringify(desired), `${active.id}: actual page reload retains native save and selected mode`, active.fresh);
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
  const screenshotCanvas = await canvasGeometry();
  check(png.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])) && png.readUInt32BE(16) === screenshotCanvas.pixelWidth && png.readUInt32BE(20) === screenshotCanvas.pixelHeight, 'downloaded Godot screenshot preserves the actual high-density backing dimensions', screenshotCanvas);
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
  await settings(); await saveProgressAndWait('bike explicit save'); await interval(1500); await startStory(true);
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
          entries.push({database:meta.name,key:String(row.key),bytes:bytes.length,sha256:digest,timestampMs:row.value.timestamp instanceof Date?row.value.timestamp.getTime():null,chapter:envelope.state?.native?.chapter,page:envelope.state?.native?.page,scene:envelope.state?.native?.scene,mode:envelope.state?.native?.mode,flags:envelope.state?.flags,canteenPhase:envelope.state?.canteenHunt?.phase});
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
async function prepareStreamingFault() {
  if (!fixtureDir || !existsSync(path.join(fixtureDir, 'after_c2_dorm_exit.json'))) throw new Error('Streaming acceptance requires an earned after_c2_dorm_exit.json fixture directory');
  const manifestUrl = new URL('content-manifest.json', new URL('.', url)).href;
  const response = await fetch(manifestUrl, { cache: 'no-cache' });
  check(response.ok, 'streaming content manifest is independently available');
  const bytes = Buffer.from(await response.arrayBuffer());
  const manifest = JSON.parse(bytes);
  check(manifest.schema === '755-web-content-v1' && manifest.core && Array.isArray(manifest.packs) && manifest.packs.length > 0, 'delivery declares separate core and deferred content packs');
  const base = new URL('.', url);
  const coreUrl = new URL(manifest.core.file, base).href;
  const deferredUrls = manifest.packs.map(pack => new URL(pack.file, base).href);
  for (const deferred of deferredUrls) {
    const location = artifactLocation(deferred);
    check(location.relativePath.startsWith('content/') && deferred !== coreUrl, 'controlled failure targets only a declared deferred content path', { relativePath: location.relativePath });
  }
  check(new Set(deferredUrls).size === manifest.packs.length, 'deferred content URLs are unique');
  if (exportDir) check(await shaFile(path.join(exportDir, 'content-manifest.json')) === hash(bytes), 'HTTP content manifest matches the actual split export');
  active.deferredUrls = new Set(deferredUrls);
  active.controlledBlockedUrls = new Set(deferredUrls);
  active.faultPhase = 'fresh-c1-deferred-blocked';
  active.streamingManifest = manifest;
  active.streaming = { manifestUrl, manifestSha256: hash(bytes), core: manifest.core, deferredPacks: manifest.packs.map(({ id, family, file, bytes, sha256 }) => ({ id, family, file, bytes, sha256 })), boots: [], controlledFailures: [], reloadContentRequests: [] };
  await active.cdp.send('Network.setBlockedURLs', { urls: deferredUrls });
}

async function cachedContentKeys() {
  return evaluate(`(async()=>{
    if(typeof caches==='undefined')return {available:false,names:[],keys:[]};
    const names=await caches.keys();
    if(!names.includes('755-godot-content-v1'))return {available:true,names,keys:[]};
    const cache=await caches.open('755-godot-content-v1');
    return {available:true,names,keys:(await cache.keys()).map(request=>request.url)};
  })()`);
}

function storyEvidence(value) {
  return { chapter: state(value)?.native.chapter, page: state(value)?.native.page, scene: state(value)?.native.scene, stateSha256: hash(JSON.stringify(state(value))), saveDigest: value.saveDigest, itemsSha256: hash(JSON.stringify(state(value)?.items)), walletSha256: hash(JSON.stringify(state(value)?.wallet)), actOnePhase: state(value)?.actOne.phase };
}

async function streamingCase() {
  const fresh = await snapshot();
  check(state(fresh)?.native.chapter === 1 && !fresh.content?.blocking, 'fresh C1 ordinary phone interaction and save/reload remain usable with every deferred HTTP URL blocked');
  await poll(() => active.streaming.controlledFailures.length > 0, 'background transport actually encounters the controlled deferred-content block', 30000);
  const backgroundFailed = await snapshot();
  check(!backgroundFailed.content.blocking && backgroundFailed.content.packs.some(pack => pack.status === 'error'), 'a real optional background failure does not show the required-content overlay');
  check(backgroundFailed.content.enabled && !backgroundFailed.content.monolithic && !backgroundFailed.content.manifestError, 'the running engine uses the content coordinator and a valid split manifest');
  active.streaming.freshWithBlockedBackground = { evidence: storyEvidence(backgroundFailed), content: backgroundFailed.content };
  console.log('desktop-1280: first-chapter input/save/reload survives deferred-content HTTP failure');

  active.faultPhase = 'c2-required-failure';
  await press('Escape'); await interval(250);
  await importSave(path.join(fixtureDir, 'after_c2_dorm_exit.json'));
  const blocked = await poll(async () => { const value = await snapshot(); return value?.content?.blocking && value.content.retryVisible && controls(value).some(control => control.name === 'RetryRequiredContent') ? value : null; }, 'ordinary later save shows the real required-content retry control', 60000);
  check(state(blocked).native.chapter === 2 && state(blocked).native.scene === 'campus_bootstrap' && blocked.content.requiredIds.length > 0, 'validated earned C2 import is retained while required assets are unavailable');
  const frozen = storyEvidence(blocked);
  await interval(1200);
  const whileBlocked = await snapshot();
  check(whileBlocked.content.blocking && whileBlocked.saveDigest === frozen.saveDigest && hash(JSON.stringify(state(whileBlocked))) === frozen.stateSha256, 'required-content network failure preserves actual imported State and committed save bytes while waiting');
  active.streaming.requiredFailure = { at: Date.now(), evidence: frozen, content: whileBlocked.content, retryControl: controls(whileBlocked).find(control => control.name === 'RetryRequiredContent') };
  active.screenshots.push(await screenshot('desktop-streaming-required-retry'));

  active.faultPhase = 'c2-user-retry-recovery';
  active.controlledBlockedUrls.clear();
  await active.cdp.send('Network.setBlockedURLs', { urls: [] });
  await clickControl('RetryRequiredContent', 'name');
  const ready = await poll(async () => {
    const value = await snapshot();
    return value?.content?.readyFamilies?.includes('chapter2') && !value.content.blocking && value.world?.visible && value.world.scene_id === 'campus_bootstrap' && value.world.player ? value : null;
  }, 'user Retry downloads every C2 block and reveals the real Godot campus map', bootTimeout);
  check(hash(JSON.stringify(state(ready).items)) === frozen.itemsSha256 && hash(JSON.stringify(state(ready).wallet)) === frozen.walletSha256 && state(ready).actOne.phase === frozen.actOnePhase, 'asset recovery preserves earned inventory, wallet and story phase');
  const chapter2Packs = active.streamingManifest.packs.filter(pack => pack.family === 'chapter2');
  check(chapter2Packs.length > 1 && chapter2Packs.every(pack => ready.content.packs.some(loaded => loaded.id === pack.id && loaded.status === 'ready')), 'family readiness requires every independently verified C2 content block');
  const position = ready.world.player;
  await evaluate("document.getElementById('canvas').focus()");
  let moved = false;
  for (const direction of ['ArrowRight', 'ArrowDown', 'ArrowLeft', 'ArrowUp']) {
    await key(direction, direction, true); await interval(500); await key(direction, direction, false); await interval(350);
    const now = (await snapshot()).world?.player;
    if (now && Math.hypot(now.x - position.x, now.y - position.y) > 3) { moved = true; break; }
  }
  check(moved, 'recovered native campus renders and accepts real keyboard movement');
  await assertLayout('streaming-recovered-campus');
  active.screenshots.push(await screenshot('desktop-streaming-campus-recovered'));
  active.streaming.recovery = { at: Date.now(), evidence: storyEvidence(await snapshot()), content: ready.content, realKeyboardMovement: moved };

  const expectedCacheKeys = chapter2Packs.map(pack => new URL('/.755-content-cache/' + pack.sha256 + '.pck', new URL(url).origin).href);
  const cached = await poll(async () => { const value = await cachedContentKeys(); return value.available && expectedCacheKeys.every(key => value.keys.includes(key)) ? value : null; }, 'only natively accepted C2 chunks are committed to actual CacheStorage', 60000);
  check(cached.available && expectedCacheKeys.every(key => cached.keys.includes(key)), 'CacheStorage contains every verified C2 chunk under its full SHA-256 identity', cached);
  active.streaming.cacheBeforeReload = cached;
  await settings(); await saveProgressAndWait('streaming explicit save'); await interval(1600);
  const saved = await snapshot();
  active.faultPhase = 'reload-from-verified-cache';
  active.controlledBlockedUrls = new Set(active.deferredUrls);
  await active.cdp.send('Network.setBlockedURLs', { urls: [...active.deferredUrls] });
  const requestStart = active.requests.length;
  const oldDocument = await evaluate('performance.timeOrigin');
  const reloaded = await startStory(true);
  const resumed = await poll(async () => { const value = await snapshot(); return !value?.content?.blocking && value?.content?.readyFamilies?.includes('chapter2') && value.world?.visible && value.world.scene_id === 'campus_bootstrap' ? value : null; }, 'real document reload restores C2 entirely from verified content cache', 60000);
  const chapter2Urls = new Set(chapter2Packs.map(pack => new URL(pack.file, new URL('.', url)).href));
  const requests = active.requests.slice(requestStart).filter(request => chapter2Urls.has(request.url));
  check(requests.length === 0, 'ordinary reload makes no C2 HTTP requests while all deferred URLs remain explicitly blocked', requests);
  check(await evaluate('performance.timeOrigin') !== oldDocument && state(resumed).native.chapter === 2 && state(resumed).native.scene === 'campus_bootstrap', 'cache recovery occurs in a new real document and retains the saved C2 route');
  check(hash(JSON.stringify(state(resumed).items)) === hash(JSON.stringify(state(saved).items)) && hash(JSON.stringify(state(resumed).wallet)) === hash(JSON.stringify(state(saved).wallet)), 'cache-only reload preserves earned items and wallet');
  active.streaming.reload = { beforeEvidence: storyEvidence(saved), afterEvidence: storyEvidence(resumed), mainReadyMs: reloaded.mainReadyMs, oldDocumentTimeOrigin: oldDocument, newDocumentTimeOrigin: await evaluate('performance.timeOrigin'), chapter2HttpRequests: requests, cache: await cachedContentKeys() };
  active.screenshots.push(await screenshot('desktop-streaming-campus-cache-reload'));
  check(active.streaming.controlledFailures.length > 0 && active.streaming.controlledFailures.every(failure => active.deferredUrls.has(failure.url) && ['', 'net::ERR_BLOCKED_BY_CLIENT'].includes(failure.errorText) && failure.blockedReason === 'inspector'), 'only explicitly injected deferred inspector blocks are recorded as controlled failures', active.streaming.controlledFailures);
  console.log('desktop-1280: earned C2 file import, visible failure/retry, full-family map recovery and cache-only real reload passed');
}

// No game writes: every operation below is a real CDP input or a fresh read of
// the detached engine snapshot. Fixture construction is separate evidence.
const mobileDistance = (a, b) => Math.hypot(a.x - b.x, a.y - b.y);
const inRect = (point, rect, inset = 0) => point.x >= rect.x + inset && point.y >= rect.y + inset && point.x <= rect.x + rect.width - inset && point.y <= rect.y + rect.height - inset;
const mobileFacts = value => JSON.stringify({ scene: state(value).native.scene, phase: state(value).actOne.phase, props: state(value).native.dorm_props, items: state(value).items, wallet: state(value).wallet, dormPropActions: value.world?.input?.dormPropActions });
// Production creates dorm_props on the first real prop action; absent lamps are off.
const lampOn = value => !!state(value).native.dorm_props?.lamp_03_on;
const worldTarget = (value, id = 'desk_03') => value.world.input.targets.find(target => target.id === id);
async function mobileSample(previous, delay = 300) {
  await interval(delay);
  const value = await poll(async () => { const next = await snapshot(); return next?.sampleFrame > (previous?.sampleFrame ?? -1) ? next : null; }, 'fresh engine mobile-input observation', 5000);
  active.mobileWorld.samples.push({ at: Date.now(), sampleFrame: value.sampleFrame, world: value.world, facts: mobileFacts(value) });
  return value;
}
async function worldTouches(type, points = []) {
  if ((type === 'touchEnd' || type === 'touchCancel') && points.length) throw new Error('CDP end/cancel requires an empty active point set');
  active.mobileWorld.inputs.push({ at: Date.now(), method: 'Input.dispatchTouchEvent', type, touchPoints: points });
  await active.cdp.send('Input.dispatchTouchEvent', { type, touchPoints: points });
}
async function worldTap(value, point) {
  const css = await renderPoint(point, value);
  await worldTouches('touchStart', [{ ...css, id: 1 }]); await interval(65); await worldTouches('touchEnd');
  return mobileSample(value);
}
async function stickStart(value, vector = { x: 0, y: -1 }) {
  const origin = await renderPoint(value.world.input.stick, value);
  const length = Math.hypot(vector.x, vector.y) || 1;
  const displaced = await renderPoint({ x: value.world.input.stick.x + 38 * vector.x / length, y: value.world.input.stick.y + 38 * vector.y / length }, value);
  await worldTouches('touchStart', [{ ...origin, id: 1 }]);
  await worldTouches('touchMove', [{ ...displaced, id: 1 }]);
  return displaced;
}
async function stickStep(value, vector, ms = 150) {
  await stickStart(value, vector); await interval(ms); await worldTouches('touchEnd');
  return mobileSample(value);
}
async function assertStickHeld(value, label) {
  const held = await mobileSample(value);
  check(held.world.input.owners.filter(owner => owner.role === 'stick').length === 1 && mobileDistance(held.world.touch_axis, { x: 0, y: 0 }) > .1, `${active.id}: ${label} begins with an actually owned, nonzero joystick`, held.world);
  return held;
}
async function assertWorldStopped(value, label) {
  value = await mobileSample(value);
  check(mobileDistance(value.world.touch_axis, { x: 0, y: 0 }) < .001 && value.world.input.owners.length === 0 && !value.world.input.mouseOwned && !value.world.input.inventoryOwned, `${active.id}: ${label} clears pointer owners and axis`, value.world.input);
  const after = await mobileSample(value, 500);
  check(mobileDistance(value.world.player, after.world.player) < .5, `${active.id}: ${label} does not leave stuck movement`, { before: value.world.player, after: after.world.player });
  return after;
}
async function assertBottomPlaque(value, label) {
  value = await poll(async () => { const next = await snapshot(); return next?.world?.input?.plaque?.visible && !next.world.subtitle ? next : null; }, 'actual confirmed plaque with no transient feedback', 15000);
  const rect = value.world.rect, plaque = value.world.input.plaque.rect, stick = value.world.input.stickRect;
  check(inRect({ x: plaque.x, y: plaque.y }, value.viewport) && inRect({ x: plaque.x + plaque.width, y: plaque.y + plaque.height }, value.viewport), `${active.id}: ${label} plaque stays inside the actual root viewport`);
  check(plaque.x + plaque.width <= stick.x || stick.x + stick.width <= plaque.x || plaque.y + plaque.height <= stick.y || stick.y + stick.height <= plaque.y, `${active.id}: ${label} plaque does not overlap the actual joystick rectangle`, { plaque, stick });
  check(inRect({ x: plaque.x, y: plaque.y }, rect) && inRect({ x: plaque.x + plaque.width, y: plaque.y + plaque.height }, rect), `${active.id}: ${label} confirmed plaque stays inside the actual world`, { rect, plaque });
  check(Math.abs(plaque.x + plaque.width / 2 - rect.x - rect.width / 2) <= 1 && Math.abs(rect.y + rect.height - plaque.y - plaque.height - 4) <= 1, `${active.id}: ${label} confirmed plaque is bottom-centred at four logical display pixels`, { rect, plaque });
  const later = await mobileSample(value, 500);
  check(JSON.stringify(later.world.input.plaque.rect) === JSON.stringify(plaque), `${active.id}: ${label} deferred layout keeps the plaque anchored`);
  active.screenshots.push(await screenshot(`${active.id}-${label}-confirmed-bottom`));
  return later;
}
async function mobileWorldCase() {
  check(!!fixtureDir, 'mobile-world requires an explicit earned fixture directory (never a fabricated save)');
  active.mobileWorld = { fixtureConstructionIsNotTouchEvidence: true, inputs: [], samples: [], coverage: [], limitations: ['Chromium emulation, not physical phones or a manual campaign.', 'No notch/safe-area emulation is claimed by DeviceMetricsOverride; native safe-area regression is separate.'] };
  await importSave(path.join(fixtureDir, 'before_c2_dorm_exit.json'));
  let value = await poll(async () => { const s = await snapshot(); return s?.world?.visible && s.world.scene_id === 'dorm_hub' && s.world.input && (!active.touch || s.world.input.geometryAvailable) && !s.world.input.modalVisible && !s.content.blocking ? s : null; }, 'ordinary earned import reaches the real dorm world', 60000);
  value = await mobileSample(value, importSettleMs);
  value = await poll(async () => { const next = await snapshot(); return next?.sampleFrame > value.sampleFrame && !next.world.subtitle && (!active.touch || next.world.input.geometryAvailable) ? next : null; }, 'import feedback finishes before any world gesture', 15000);
  check(state(value).actOne.manualControlTested && state(value).actOne.phase === 'movement_ready', 'earned C2 fixture contains the original unlocked movement and exit gates');
  if (!active.touch) {
    const before = value.world.player;
    // A short wall-clock pulse can begin and end between loaded WASM frames.
    // Keep real input held only until a fresh engine sample proves movement.
    // The earned actor stands beside the right door jamb: move toward its centre.
    const direction = { at: Date.now(), method: 'observedKeyHold', code: 'ArrowLeft', startSampleFrame: value.sampleFrame, endSampleFrame: value.sampleFrame, maxMs: 3000, released: false };
    active.mobileWorld.inputs.push(direction);
    try {
      await key('ArrowLeft', 'ArrowLeft', true);
      value = await poll(async () => {
        const next = await snapshot();
        if (!next || next.sampleFrame <= direction.endSampleFrame) return null;
        direction.endSampleFrame = next.sampleFrame;
        active.mobileWorld.samples.push({ at: Date.now(), sampleFrame: next.sampleFrame, world: next.world, facts: mobileFacts(next) });
        return mobileDistance(before, next.world.player) > 1 ? next : null;
      }, 'real desktop direction produces movement in a fresh engine sample', direction.maxMs);
    } finally {
      await key('ArrowLeft', 'ArrowLeft', false);
      direction.finishedAt = Date.now(); direction.released = true;
    }
    value = await mobileSample(value);
    check(mobileDistance(before, value.world.player) > 1 && worldTarget(value, 'exit_door').distance <= worldTarget(value, 'exit_door').radius, 'desktop direction input moves the actual actor while the earned door remains nearby');
    await press(' ', 'Space');
    value = await poll(async () => { const s = await snapshot(); return s?.world?.scene_id === 'campus_bootstrap' ? s : null; }, 'PC Space retains the existing proximity-gated dorm exit', 60000);
    active.mobileWorld.coverage.push('PC direction + Space');
    active.mobileWorld.completed = true;
    active.screenshots.push(await screenshot(`${active.id}-pc-space-campus`));
    return;
  }
  check(value.world.mobile_exploration && inRect({ x: value.world.input.stickRect.x, y: value.world.input.stickRect.y }, value.world.rect) && inRect({ x: value.world.input.stickRect.x + value.world.input.stickRect.width, y: value.world.input.stickRect.y + value.world.input.stickRect.height }, value.world.rect) && value.world.input.confirmRect.width === 0 && value.world.input.confirmRect.height === 0, `${active.id}: mobile movement pad overlays the actual world without a confirm button`);
  const original = mobileFacts(value), target = worldTarget(value), beforeFarTap = value.world.player;
  check(target.distance > target.radius && inRect(target.point, value.world.rect, 8), `${active.id}: far lamp is visibly on-screen and outside the original proximity radius`, target);
  value = await worldTap(value, target.point);
  value = await poll(async () => { const next = await snapshot(); return next?.world?.subtitle === `太远了，请靠近${target.label}。` ? next : null; }, 'the actual lamp proximity refusal reaches the feedback FIFO', 15000);
  check(value.world.subtitle === `太远了，请靠近${target.label}。`, `${active.id}: far tap actually reaches the visible lamp picker and receives its proximity refusal`, { subtitle: value.world.subtitle, target });
  check(mobileFacts(value) === original && !value.world.mobile_confirmed_target_id, `${active.id}: far object tap does not interact, confirm or start remote progress`);
  check(mobileDistance(value.world.player, beforeFarTap) < .5, `${active.id}: the rejected far tap never moved or teleported the actor before its refusal`, { before: beforeFarTap, after: value.world.player });
  const farPosition = value.world.player;
  value = await mobileSample(value, 650);
  check(mobileDistance(value.world.player, farPosition) < .5, `${active.id}: rejected distant object tap does not auto-walk`);
  const movementStart = value.world.player;
  for (let step = 0; step < 55 && worldTarget(value).distance > worldTarget(value).radius - 18; step++) {
    const destination = worldTarget(value).worldPoint;
    value = await stickStep(value, { x: destination.x - value.world.player.x, y: destination.y - value.world.player.y });
  }
  check(mobileDistance(value.world.player, movementStart) > 20 && worldTarget(value).distance <= worldTarget(value).radius - 10, `${active.id}: real joystick movement reaches the ordinary lamp proximity`, value.world);
  value = await mobileSample(value, 650);
  check(mobileFacts(value) === original && !value.world.mobile_confirmed_target_id && !value.world.input.plaque.visible, `${active.id}: joystick only moves; arriving beside an object never opens it or reveals a confirmed label`);
  // Briefly face away while remaining nearby: direct tapping has no facing gate.
  value = await stickStep(value, { x: 0, y: 1 }, 55);
  check(value.world.facing === 'down' && worldTarget(value).worldPoint.y < value.world.player.y && worldTarget(value).distance <= worldTarget(value).radius, `${active.id}: actor faces away from the nearby lamp before direct tap`);
  const beforeLamp = lampOn(value), beforeActions = value.world.input.dormPropActions;
  value = await worldTap(value, worldTarget(value).point);
  check(lampOn(value) !== beforeLamp && value.world.mobile_confirmed_target_id === 'desk_03' && value.world.input.dormPropActions === beforeActions + 1, `${active.id}: one direct object touch confirms exactly one nearby lamp toggle without facing/joystick confirmation`);
  const once = lampOn(value);
  value = await mobileSample(value, 650);
  check(lampOn(value) === once && value.world.input.dormPropActions === beforeActions + 1, `${active.id}: generated mouse events do not toggle the lamp a second time`);
  value = await assertBottomPlaque(value, 'portrait');
  const facts = mobileFacts(value), point = await renderPoint(worldTarget(value).point, value);
  await worldTouches('touchStart', [{ ...point, id: 1 }]);
  await worldTouches('touchMove', [{ x: point.x - 40, y: point.y, id: 1 }]);
  await worldTouches('touchMove', [{ ...point, id: 1 }]); await worldTouches('touchEnd');
  value = await mobileSample(value);
  check(mobileFacts(value) === facts, `${active.id}: object drag returning to its start never ends as a tap`);
  await stickStart(value); value = await assertStickHeld(value, 'touchcancel interruption'); await worldTouches('touchCancel');
  value = await assertWorldStopped(value, 'touchcancel');
  const first = await stickStart(value, { x: 0, y: 0 });
  let held = await mobileSample(value);
  const owner = held.world.input.owners.find(owner => owner.role === 'stick');
  check(!!owner, `${active.id}: the first finger actually owns the stick`);
  const second = await renderPoint({ x: held.world.input.stick.x + 24, y: held.world.input.stick.y }, held);
  await worldTouches('touchStart', [{ ...first, id: 1 }, { ...second, id: 2 }]);
  held = await mobileSample(held);
  check(held.world.input.owners.filter(row => row.role === 'stick').length === 1 && held.world.input.owners.find(row => row.role === 'stick').index === owner.index && mobileDistance(held.world.touch_axis, { x: 0, y: 0 }) < .001, `${active.id}: second finger cannot steal the joystick or inject its direction`, held.world.input);
  await worldTouches('touchEnd'); value = await assertWorldStopped(held, 'multitouch release');
  // The reverse ownership order is important: inventory handles some pointer
  // releases before Main, so movement must stop as soon as its gesture owns input.
  await clickControl('WorldInventoryHandle', 'name'); value = await mobileSample(value);
  const item = controls(value).find(control => control.itemId === 'campusCard' && !control.disabled);
  check(!!item, `${active.id}: the existing earned inventory item is available through the real bag UI`);
  const heldStick = await stickStart(value, { x: -1, y: 0 });
  value = await assertStickHeld(value, 'inventory acquisition interruption');
  const itemPoint = await renderPoint({ x: item.rect.x + item.rect.width / 2, y: item.rect.y + item.rect.height / 2 }, value);
  await worldTouches('touchStart', [{ ...heldStick, id: 1 }, { ...itemPoint, id: 2 }]);
  value = await mobileSample(value);
  check(value.world.input.inventoryOwned && mobileDistance(value.world.touch_axis, { x: 0, y: 0 }) < .001, `${active.id}: acquiring an inventory touch cancels already-held world movement`);
  await worldTouches('touchCancel'); value = await assertWorldStopped(value, 'inventory cancellation');
  check(mobileFacts(value) === facts, `${active.id}: inventory ownership does not consume an item or trigger the world`);
  await clickControl('WorldInventoryHandle', 'name'); value = await mobileSample(value);
  await stickStart(value); value = await assertStickHeld(value, 'settings interruption'); await press('F10');
  value = await poll(async () => { const s = await snapshot(); return s?.world?.input?.modalVisible ? s : null; }, 'settings modal opens over a held joystick');
  value = await assertWorldStopped(value, 'settings modal before finger release'); await worldTouches('touchEnd');
  await press('Escape'); value = await mobileSample(value);
  await stickStart(value, { x: -1, y: 0 }); value = await assertStickHeld(value, 'journal interruption');
  const tasks = controls(value).find(control => control.name === 'WorldTasks');
  check(!!tasks, `${active.id}: the existing task journal launcher is visible`);
  const tasksPoint = await renderPoint({ x: tasks.rect.x + tasks.rect.width / 2, y: tasks.rect.y + tasks.rect.height / 2 }, value);
  // A real independent mouse click opens the native button without releasing
  // the held touch; testing touchEnd first would mask missing modal cleanup.
  await clickPoint(tasksPoint, false);
  value = await poll(async () => { const s = await snapshot(); return s?.world?.input?.modalVisible ? s : null; }, 'actual task journal opens while the touch remains held');
  value = await assertWorldStopped(value, 'journal modal before finger release'); await worldTouches('touchEnd');
  check(mobileFacts(value) === facts, `${active.id}: modal and journal input cannot bleed into world interaction`);
  await press('Escape'); value = await mobileSample(value);
  await stickStart(value); value = await assertStickHeld(value, 'browser blur interruption');
  check(await evaluate('document.hasFocus()'), `${active.id}: game document is focused immediately before the real tab switch`);
  const other = await active.cdp.send('Target.createTarget', { url: 'about:blank' });
  await active.cdp.send('Target.activateTarget', { targetId: other.targetId }); await interval(350);
  const lostFocus = await evaluate('!document.hasFocus()');
  await active.cdp.send('Target.activateTarget', { targetId: active.targetId });
  await active.cdp.send('Target.closeTarget', { targetId: other.targetId });
  check(await evaluate('document.hasFocus()'), `${active.id}: returning to the game tab restores actual document focus`);
  check(lostFocus, `${active.id}: browser tab switch really removes document focus (not a synthetic blur event)`);
  value = await assertWorldStopped(value, 'real browser blur/return before finger release'); await worldTouches('touchEnd');
  check(mobileFacts(value) === facts, `${active.id}: browser blur cannot trigger an object or consume inventory`);
  const beforeNew = value.world.player; value = await stickStep(value, { x: -1, y: 0 });
  check(mobileDistance(beforeNew, value.world.player) > 1, `${active.id}: a fresh joystick gesture still works after cancellation and blur`);
  if (active.id === 'touch-390') {
    await stickStart(value); value = await assertStickHeld(value, 'orientation interruption');
    await active.cdp.send('Emulation.setDeviceMetricsOverride', { width: 844, height: 390, deviceScaleFactor: active.dpr, mobile: true });
    value = await poll(async () => { const s = await snapshot(); return s?.viewport?.width === 844 && s.viewport.height === 390 ? s : null; }, 'actual landscape canvas resize');
    value = await assertWorldStopped(value, 'orientation resize before finger release'); await worldTouches('touchEnd');
    // Re-import through the shipped file picker rather than moving the actor
    // or camera through a privileged bridge to obtain a convenient screenshot.
    await importSave(path.join(fixtureDir, 'before_c2_dorm_exit.json')); value = await mobileSample(value, importSettleMs);
    value = await poll(async () => { const next = await snapshot(); return next?.sampleFrame > value.sampleFrame && !next.world.subtitle && next.world.input.geometryAvailable ? next : null; }, 'landscape import feedback finishes before joystick movement', 15000);
    for (let step = 0; step < 55 && worldTarget(value).distance > worldTarget(value).radius - 18; step++) {
      const destination = worldTarget(value).worldPoint;
      value = await stickStep(value, { x: destination.x - value.world.player.x, y: destination.y - value.world.player.y });
    }
    check(worldTarget(value).distance <= worldTarget(value).radius, 'landscape real joystick reaches lamp proximity');
    value = await worldTap(value, worldTarget(value).point);
    check(value.world.mobile_confirmed_target_id === 'desk_03', 'landscape direct touch confirms the actual lamp');
    await assertBottomPlaque(value, 'landscape');
  }
  active.mobileWorld.completed = true;
  active.mobileWorld.coverage.push('real joystick movement only', 'far tap and arrival never interact', 'near direct tap without facing', 'single reversible lamp toggle', 'bottom plaque', 'drag is not tap', 'cancel and new gesture', 'single-owner multitouch', 'stick then inventory', 'settings and journal gates', 'real browser blur', ...(active.id === 'touch-390' ? ['landscape resize'] : []));
}

async function browserCase(id, width, height, touch, dpr = 1) {
  const temp = await mkdtemp(path.join(tmpdir(), '755-godot-web-browser-')); const profile = path.join(temp, 'profile'); const errors = []; const network = new Map(); const responses = new Map();
  const child = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-dev-shm-usage', '--disable-background-networking', '--disable-extensions', '--disable-sync', '--disable-default-apps', ...chromeArgs, `--window-size=${width},${height}`, '--force-device-scale-factor=1', `--user-data-dir=${profile}`, '--remote-debugging-port=0', 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] }); let stderr = ''; child.stderr.on('data', chunk => { stderr = (stderr + chunk).slice(-10000); });
  active = { id, width, height, touch, dpr, child, imports: [], screenshots: [], mediaObservations: [], requests: [], requestsById: new Map(), bootResponses: [], bootBodyJobs: [], controlledBlockedUrls: new Set(), downloadDir: path.join(temp, 'downloads') }; await mkdir(active.downloadDir);
  if (id === 'desktop-1440') { const negativeUrl = new URL(url); negativeUrl.searchParams.set('dev', '1'); negativeUrl.searchParams.set('devCheckpoint', 'c4-755-opening'); active.url = negativeUrl.href; }
  let result;
  try {
    const portFile = await poll(() => readFile(path.join(profile, 'DevToolsActivePort'), 'utf8'), 'isolated Chromium starts'); const port = portFile.split('\n')[0]; const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
    active.targetId = targets.find(t => t.type === 'page').id;
    active.cdp = await connect(targets.find(t => t.type === 'page').webSocketDebuggerUrl, ({ method, params }) => {
      if (method === 'Runtime.exceptionThrown') errors.push({ type: 'pageerror', ...params.exceptionDetails });
      if (method === 'Runtime.consoleAPICalled' && ['error', 'warning'].includes(params.type)) { const text = params.args.map(a => a.value ?? a.description ?? '').join(' '); if (params.type === 'error' || /SCRIPT ERROR|Parse Error|Failed to load|ERROR:/.test(text)) errors.push({ type: params.type, text }); }
      if (method === 'Network.requestWillBeSent') {
        const request = { requestId: params.requestId, url: params.request.url, at: Date.now(), range: params.request.headers.Range || params.request.headers.range || '', phase: active.faultPhase || '', controlled: active.controlledBlockedUrls.has(params.request.url) };
        active.requests.push(request); active.requestsById.set(params.requestId, request);
      }
      if (method === 'Network.responseReceived') responses.set(params.requestId, { url: params.response.url, status: params.response.status, mimeType: params.response.mimeType, fromDiskCache: params.response.fromDiskCache || false, fromServiceWorker: params.response.fromServiceWorker || false });
      if (method === 'Network.loadingFinished' && responses.has(params.requestId)) {
        const response = responses.get(params.requestId);
        network.set(response.url, { ...response, encodedDataLength: params.encodedDataLength });
        if (delivery.bootByUrl.has(response.url)) {
          const request = active.requestsById.get(params.requestId);
          const row = { ...response, requestId: params.requestId, requestAt: request?.at ?? 0, range: request?.range ?? '', encodedDataLength: params.encodedDataLength, pending: true };
          active.bootResponses.push(row);
          active.bootBodyJobs.push(active.cdp.send('Network.getResponseBody', { requestId: params.requestId }).then(result => {
            const bytes = Buffer.from(result.body, result.base64Encoded ? 'base64' : 'utf8');
            row.bytes = bytes.length; row.sha256 = hash(bytes); row.pending = false;
          }).catch(error => { row.error = error.message; row.pending = false; }));
        }
      }
      if (method === 'Network.loadingFailed' && !params.canceled) {
        const request = active.requestsById.get(params.requestId);
        const failure = { type: 'network', requestId: params.requestId, url: request?.url || '', phase: request?.phase || '', errorText: params.errorText, blockedReason: params.blockedReason || '' };
        // Chromium 155 reports an empty errorText for Network.setBlockedURLs;
        // blockedReason=inspector and the exact active injected URL remain the
        // authoritative, narrowly scoped fault identity. Keep the raw event.
        if (active.streaming && request?.controlled && active.deferredUrls.has(request.url) && ['', 'net::ERR_BLOCKED_BY_CLIENT'].includes(params.errorText || '') && params.blockedReason === 'inspector') active.streaming.controlledFailures.push(failure);
        else errors.push(failure);
      }
    });
    // Retain the complete ~94 MB cold boot response set while the inspector
    // hashes real response bodies, even when local export I/O delays CDP.
    // This changes observation capacity only; HTTP/hash/cache checks stay strict.
    await active.cdp.send('Page.enable'); await active.cdp.send('Runtime.enable'); await active.cdp.send('Network.enable', { maxTotalBufferSize: 128 * 1024 * 1024, maxResourceBufferSize: 2 * 1024 * 1024 }); await active.cdp.send('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: dpr, mobile: touch }); await active.cdp.send('Emulation.setTouchEmulationEnabled', { enabled: touch, maxTouchPoints: 5 });
    await active.cdp.send('Browser.setDownloadBehavior', { behavior: 'allow', downloadPath: active.downloadDir, eventsEnabled: true });
    if (scenarios === 'streaming') await prepareStreamingFault();
    result = await freshCase(['mobile-world', 'phone-recovery'].includes(scenarios));
    if (scenarios === 'mobile-world') await mobileWorldCase();
    else if (scenarios === 'phone-recovery') active.phoneRecovery = await phoneRecoveryCase({ id, touch, fixtureDir,
      snapshot, clickControl, clickPoint, renderPoint, poll, check, interval, screenshot, importSave,
      assertLayout, settings, saveProgressAndWait, startStory, record: value => { active.phoneRecovery = value; }, capture: value => active.screenshots.push(value) });
    else await portableSaveCase();
    if (id === 'desktop-1280') {
      if (scenarios === 'all') { await legacyCase(); await c1Case(true); await fixtureCases(); }
      if (scenarios === 'all' || scenarios === 'bike') await bikeCase();
      if (scenarios === 'all' || scenarios === 'media') await mediaCase();
      if (scenarios === 'durability') await durabilityCase();
      if (scenarios === 'durability-switch') await durabilitySwitchCase();
      if (scenarios === 'streaming') await streamingCase();
    } else if (touch && scenarios === 'all') await c1Case(false);
    if (scenarios === 'mobile-world') check(active.mobileWorld?.completed === true && active.mobileWorld.coverage.length > 0 && active.imports.some(item => item.filename === 'before_c2_dorm_exit.json'), `${id}: requested mobile-world scenario completed with actual inputs and earned file import`);
    if (scenarios === 'phone-recovery') check(active.phoneRecovery?.completed === true && active.phoneRecovery.coverage.length === 9 && active.phoneRecovery.inputs.length > 0, `${id}: requested phone recovery flows completed with ordinary input`);
    const transportUrls = new Set(delivery.transport.map(asset => asset.url));
    const resources = [...network.values()].filter(record => transportUrls.has(record.url));
    check(active.coldBoot?.responses.length === delivery.bootByUrl.size, `${id}: actual Godot engine boot and ordinary input used the verified complete static boot chunk set`, { chunks: active.coldBoot?.responses.length, expected: delivery.bootByUrl.size, freshInput: active.fresh?.inputs });
    check(![...network.values()].some(n => n.status >= 400), `${id}: no failed HTTP resources`, [...network.values()].filter(n => n.status >= 400));
    check(errors.length === 0, `${id}: no page, runtime, script or uncancelled network errors`, errors);
    const renderer = await evaluate(`(()=>{const c=document.getElementById('canvas')||document.querySelector('canvas');const gl=c.getContext('webgl2');if(!gl)return{webgl2:false};const e=gl.getExtension('WEBGL_debug_renderer_info');return{webgl2:true,vendor:e?gl.getParameter(e.UNMASKED_VENDOR_WEBGL):gl.getParameter(gl.VENDOR),renderer:e?gl.getParameter(e.UNMASKED_RENDERER_WEBGL):gl.getParameter(gl.RENDERER)};})()`);
    check(renderer.webgl2, `${id}: actual WebGL2 context available`, renderer);
    check(await evaluate("JSON.stringify(Object.keys(window.__GODOT_755__))") === '["snapshot"]', 'production browser bridge exposes only a read operation');
    check(await evaluate("(()=>{const s=window.__GODOT_755__.snapshot(),old=s.state.native.chapter;s.state.native.chapter=999;return window.__GODOT_755__.snapshot().state.native.chapter===old})()"), 'returned browser snapshot is a detached copy');
    report.cases.push({ id, width, height, touch, dpr, passed: true, ...result, coldBoot: active.coldBoot, fresh: active.fresh, portable: active.portable, imports: active.imports, legacy: active.legacy, bike: active.bike, durability: active.durability, streaming: active.streaming, mobileWorld: active.mobileWorld, phoneRecovery: active.phoneRecovery, chapterResults: active.chapterResults, screenshots: active.screenshots, mediaObservations: active.mediaObservations, renderer, network: resources, errors });
    report.network.push(...network.values());
  } catch (e) { report.cases.push({ id, width, height, touch, dpr, passed: false, result, error: e.stack || String(e), coldBoot: active.coldBoot, bootResponses: active.bootResponses, fresh: active.fresh, imports: active.imports, durability: active.durability, streaming: active.streaming, mobileWorld: active.mobileWorld, phoneRecovery: active.phoneRecovery, screenshots: active.screenshots, errors, stderr }); try { report.cases.at(-1).lastSnapshot = await snapshot(); report.cases.at(-1).failureScreenshot = await screenshot(`${id}-failure`); } catch {} throw e; }
  finally { if (report.cases.at(-1)?.id === id) report.cases.at(-1).saveAttempts = active.saveAttempts || []; await Promise.allSettled(active.bootBodyJobs); active.cdp?.close(); child.kill('SIGTERM'); await interval(200); if (child.exitCode === null) child.kill('SIGKILL'); await rm(temp, { recursive: true, force: true }); await persist(); }
}
try {
  const selected = [['desktop-1280', 1280, 720, false, 1], ['desktop-1440', 1440, 900, false, 1], ['touch-390', 390, 844, true, 1], ['retina-1440', 1440, 900, false, 2], ['retina-touch-390', 390, 844, true, 3], ['desktop-1920', 1920, 1080, false, 1]].filter(([id]) => (only === 'all' || id === only) && (scenarios !== 'streaming' || id === 'desktop-1280') && (!['mobile-world', 'phone-recovery'].includes(scenarios) || ['desktop-1280', 'touch-390', 'retina-touch-390'].includes(id)));
  check(selected.length > 0, 'at least one requested viewport selected');
  delivery = await prepareDeliveryEvidence();
  for (const selectedCase of selected) await browserCase(...selectedCase);
  report.assets = [];
  for (const resource of delivery.transport) {
    const { relativePath, local } = artifactLocation(resource.url);
    const response = await fetch(resource.url, { cache: 'no-cache' }); check(response.status === 200, `transport asset independently fetched in full: ${relativePath}`); const h = createHash('sha256'); let bytes = 0; for await (const chunk of response.body) { h.update(chunk); bytes += chunk.length; } const sha256 = h.digest('hex');
    check(bytes === resource.bytes && sha256 === resource.sha256, `independent HTTP transport bytes match the actual manifest: ${relativePath}`, { bytes, sha256, expectedBytes: resource.bytes, expectedSha256: resource.sha256 });
    if (local) { check(existsSync(local), `export artifact exists: ${relativePath}`); check(await shaFile(local) === sha256, `HTTP bytes match actual Godot export: ${relativePath}`); }
    report.assets.push({ url: resource.url, relativePath, role: resource.role, resource: resource.resource, bytes, sha256, local, observedInBrowser: report.network.some(record => record.url === resource.url) });
  }
  report.passed = report.cases.every(c => c.passed) && report.checks.every(c => c.ok);
} catch (e) { report.errors.push(e.stack || String(e)); process.exitCode = 1; }
report.completedAt = new Date().toISOString(); await persist();
console.log(`Godot Web acceptance ${report.passed ? 'PASS' : 'FAIL'}: ${report.checks.length} checks; ${report.cases.length} browser cases; ${output}`);
if (!report.passed) console.error(report.errors.join('\n'));
