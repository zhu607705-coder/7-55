import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';

const source = fs.readFileSync(new URL('../web/boot_intro.js', import.meta.url), 'utf8');
const shell = fs.readFileSync(new URL('../web/index.html', import.meta.url), 'utf8');
let checks = 0;
const check = (condition, label) => { assert.ok(condition, label); checks++; };
function fixture({ reduced = false, legacyMedia = false, animated = true, shellMode = false } = {}) {
  const events = new Map(), mediaEvents = new Set();
  function node(id) {
    return { id, dataset: {}, attributes: {}, hidden: true, disabled: false, textContent: '', listeners: new Map(),
      style: { values: {}, setProperty(key, value) { this.values[key] = value; } },
      setAttribute(key, value) { this.attributes[key] = value; },
      removeAttribute(key) { delete this.attributes[key]; },
      addEventListener(type, listener) { this.listeners.set(type, listener); },
      removeEventListener(type, listener) { if (this.listeners.get(type) === listener) this.listeners.delete(type); }
    };
  }
  const layer = node('loading'), toggle = node('boot-motion-toggle');
  layer.hidden = false; layer.dataset.bootAnimation = String(animated);
  const nodes = new Map([['loading', layer], ['boot-motion-toggle', toggle]]);
  if (shellMode) for (const id of ['canvas', 'loading-message', 'loading-detail', 'loading-progress', 'start-game', 'retry-game']) nodes.set(id, node(id));
  // Attempting to control verified progress, readiness buttons or the engine
  // fails immediately: this presenter only owns its motion toggle and data.
  const doc = { hidden: false, getElementById(id) { assert.ok(nodes.has(id), 'No transport/readiness control access'); return nodes.get(id); },
    addEventListener(type, listener) { events.set(type, listener); },
    removeEventListener(type, listener) { if (events.get(type) === listener) events.delete(type); }
  };
  doc.documentElement = { dataset: { bootState: 'loading' } };
  for (const n of nodes.values()) n.focus = () => { doc.activeElement = n; };
  const media = { matches: reduced };
  if (legacyMedia) { media.addListener = fn => mediaEvents.add(fn); media.removeListener = fn => mediaEvents.delete(fn); }
  else { media.addEventListener = (type, fn) => { assert.equal(type, 'change'); mediaEvents.add(fn); }; media.removeEventListener = (_type, fn) => mediaEvents.delete(fn); }
  const window = { document: doc, matchMedia(query) { assert.equal(query, '(prefers-reduced-motion: reduce)'); return media; } };
  vm.runInNewContext(source, { window });
  const api = window.install755BootIntro();
  return { window, doc, layer, toggle, api, events, mediaEvents, nodes,
    visibility(hidden) { doc.hidden = hidden; events.get('visibilitychange')?.(); },
    preference(value) { media.matches = value; for (const fn of mediaEvents) fn({ matches: value }); },
    click() { toggle.listeners.get('click')?.(); }
  };
}

let f = fixture();
check(f.api.snapshot().stage === 'loading' && f.api.snapshot().ratio === null, 'Initial loading is indeterminate');
check(f.layer.attributes['aria-busy'] === 'true' && f.api.snapshot().motion === 'running', 'Presentation is busy with independently controllable animation');
f.api.progress(20, 100);
check(f.api.snapshot().ratio === .2 && f.layer.style.values['--boot-real-progress'] === '0.2', 'Only supplied real bytes determine visual progress');
f.api.progress(100, 100);
check(f.api.snapshot().ratio === 1 && f.api.snapshot().stage === 'loading', '100 percent does not mark verification or engine readiness complete');
f.api.update({ phase: 'verifying' });
check(f.api.snapshot().phase === 'verifying' && f.api.snapshot().stage === 'loading', 'Verification remains a loading phase');
f.visibility(true);
check(f.api.snapshot().motion === 'paused', 'Background visibility pauses decoration without changing progress');
f.visibility(false);
check(f.api.snapshot().motion === 'running' && f.api.snapshot().ratio === 1, 'Foreground resumes decoration while retaining actual bytes');
f.click();
check(f.api.snapshot().manuallyPaused && f.toggle.attributes['aria-pressed'] === 'true', 'Keyboard-compatible native button pauses animation');
f.visibility(true); f.visibility(false);
check(f.api.snapshot().motion === 'paused', 'Foreground does not override explicit pause');
f.preference(true);
check(f.api.snapshot().motion === 'reduced' && f.toggle.hidden, 'Reduced-motion preference wins without a redundant toggle');
f.preference(false);
check(f.api.snapshot().motion === 'paused', 'Changing system preference preserves user pause');
f.api.update({ stage: 'ready' });
check(f.api.snapshot().stage === 'ready' && f.layer.attributes['aria-busy'] === 'false' && f.api.snapshot().manuallyPaused, 'Ready is immediate even while animation is paused');
check(f.api.snapshot().motion === 'stopped' && f.toggle.hidden, 'Ready immediately settles decoration and hides its unused pause button');
f.api.progress(0, 100); f.api.update({ stage: 'loading' });
check(f.api.snapshot().stage === 'ready' && f.api.snapshot().ratio === 1, 'Late progress and a backward state cannot regress ready');
f.api.update({ stage: 'starting' });
check(f.layer.attributes['aria-busy'] === 'true', 'Explicit engine start may report its own busy stage');
f.api.update({ stage: 'running' });
check(f.api.disposed && f.api.snapshot().stage === 'running' && f.api.snapshot().motion === 'stopped', 'Engine handoff retires animation immediately');
check(!f.events.size && !f.mediaEvents.size && !f.toggle.listeners.size, 'Handoff releases all motion and preference listeners');
f.api.update({ stage: 'error' });
check(f.api.snapshot().stage === 'error' && f.layer.dataset.introState === 'error' && f.api.snapshot().motion === 'stopped', 'Post-handoff engine failure replaces running with a static error');
check(!f.events.size && !f.mediaEvents.size && !f.toggle.listeners.size, 'Post-handoff error cannot recreate motion subscriptions');

f = fixture(); f.api.progress(5, 0);
check(f.api.snapshot().ratio === null && f.layer.dataset.bootProgress === 'unknown', 'Unknown totals never create a fake percentage');
f.api.progress(11, 10);
check(f.api.snapshot().ratio === null, 'Invalid denominator does not fabricate 100 percent');
f.api.progress(-1, 5); f.api.progress(NaN, 5);
check(f.api.snapshot().current === 11, 'Invalid progress numbers are ignored');
f.api.update({ stage: 'error' }); f.api.progress(100, 100); f.api.update({ stage: 'ready' });
check(f.api.snapshot().stage === 'error' && f.api.disposed && f.api.snapshot().current === 11, 'Error is terminal against stale progress or completion callbacks');
check(f.toggle.hidden && !f.events.size && !f.mediaEvents.size, 'Error removes decorative controls and listeners, leaving the original retry authority');
f = fixture({ reduced: true, legacyMedia: true });
check(f.api.snapshot().motion === 'reduced', 'Legacy media-query API respects initial reduced motion');
check(f.window.install755BootIntro() === f.api && f.mediaEvents.size === 1, 'Repeated installation keeps one active owner');
f.api.dispose();
check(f.api.disposed && !f.mediaEvents.size && !f.events.size, 'Explicit disposal releases legacy media subscriptions');
check(f.toggle.hidden, 'Explicit disposal cannot leave an inert motion control visible');
check(f.window.install755BootIntro() !== f.api, 'An explicitly retired owner permits fresh presentation installation');
f = fixture({ animated: false });
check(f.api.snapshot().motion === 'off' && f.toggle.hidden, 'Interface skeleton does not pretend unfinished visual animation exists');

check(shell.indexOf('src="boot-intro.js"') < shell.indexOf('src="$GODOT_URL"'), 'Presentation script loads before the engine download');
check(shell.includes("bootIntro.progress(current, total)") && shell.includes("bootIntro.update({ phase: 'verifying' })"), 'The unchanged boot transport supplies real progress and verification phase');
check(!/\b(?:fetch|Engine|Audio|localStorage|indexedDB|setTimeout|setInterval|requestAnimationFrame)\s*\(/.test(source), 'Presenter does not download, play audio, access saves, run a clock or start the engine');

async function bootShell({ fetchManifest, bootResources } = {}) {
  const f = fixture({ shellMode: true });
  Object.defineProperty(f.doc, 'fonts', { get() { throw new Error('Font readiness must not gate engine readiness or ordinary Start'); } });
  const calls = { engine: 0, start: 0, reload: 0, errors: [], requests: [] };
  const timers = new Map();
  let timerId = 0;
  const manifest = { core: { file: 'index.pck', bytes: 5 } };
  let config;
  class FakeEngine {
    static isWebGLAvailable(version) { return version === 2; }
    constructor(value) { config = value; calls.engine++; }
    preloadFile() { return Promise.resolve(); }
    start() { calls.start++; return Promise.resolve(); }
  }
  const transport = {
    validate: () => manifest,
    bootResources: bootResources || (() => ({ wasm: { bytes: 5 }, core: { bytes: 5 } })),
    createResourceCache: () => ({
      load(resource, options) { options.onProgress(resource.bytes); return Promise.resolve({ buffer: new ArrayBuffer(5), response: {} }); },
      snapshot: () => ({ reusedBytes: 0, storage: 'indexeddb' })
    }),
    create: () => ({}), initEngine: () => Promise.resolve()
  };
  f.window.location = { reload() { calls.reload++; } };
  f.window.Godot755Content = transport;
  const inline = shell.match(/<script>\s*('use strict';[\s\S]*?)<\/script>/)[1]
    .replace('$GODOT_CONFIG', '{ executable: "index" }');
  vm.runInNewContext(inline, { window: f.window, document: f.doc, Engine: FakeEngine, WebAssembly: {}, Godot755Content: transport,
    AbortController,
    setTimeout(callback, delay) { timers.set(++timerId, { callback, delay }); return timerId; },
    clearTimeout(id) { timers.delete(id); },
    fetch: (file, options) => {
      calls.requests.push({ file, options });
      return fetchManifest ? fetchManifest(file, options) : Promise.resolve({ ok: true, json: () => Promise.resolve({}) });
    },
    console: { error: (...args) => calls.errors.push(args) }
  });
  await new Promise(setImmediate);
  return { ...f, config, calls, timers, timerStarts: () => timerId,
    expireManifest() { for (const { callback } of [...timers.values()]) callback(); }
  };
}
async function runningShell() {
  const f = await bootShell();
  const { calls } = f;
  check(f.doc.documentElement.dataset.bootState === 'ready' && f.api.snapshot().stage === 'ready' && calls.start === 0, 'Original HTML promise chain alone sets ready, without automatic engine start');
  check(f.timers.size === 0, 'Successful metadata loading clears its deadline');
  f.nodes.get('start-game').listeners.get('click')();
  await new Promise(setImmediate);
  check(calls.start === 1 && f.layer.hidden && f.api.snapshot().stage === 'running', 'Original HTML Start gesture alone hands off to the stub engine');
  return f;
}
let running = await runningShell();
let prevented = false;
running.nodes.get('canvas').listeners.get('webglcontextlost')({ preventDefault() { prevented = true; } });
check(prevented && running.doc.documentElement.dataset.bootState === 'error' && running.api.snapshot().stage === 'error', 'Production context-loss listener after running invokes the original fail path and static presenter error');
check(!running.layer.hidden && !running.nodes.get('retry-game').hidden && running.nodes.get('start-game').hidden && running.nodes.get('loading-progress').hidden, 'Actual fail-handler execution exposes Retry and original error text without stale progress or Start');
check(running.nodes.get('loading-message').textContent === '加载遇到了一点问题。' && !running.events.size && !running.mediaEvents.size, 'Adopted failure copy stays visible with no resurrected motion listeners');
running.nodes.get('retry-game').listeners.get('click')();
check(running.calls.reload === 1, 'Original Retry listener retains ordinary page reload');
running = await runningShell();
running.config.onExit(2);
check(running.doc.documentElement.dataset.bootState === 'error' && running.api.snapshot().stage === 'error' && !running.nodes.get('retry-game').hidden, 'Nonzero engine exit after running follows the same original Retry path');

for (const phase of ['headers', 'body']) {
  const pending = [];
  const blocked = await bootShell({ fetchManifest: () => {
    const response = { ok: true, json: () => new Promise(resolve => pending.push(resolve)) };
    return phase === 'headers' ? new Promise(resolve => pending.push(() => resolve({ ok: true, json: () => Promise.resolve({}) }))) : Promise.resolve(response);
  } });
  check(blocked.calls.requests.length === 2 && blocked.doc.documentElement.dataset.bootState === 'loading' && blocked.calls.engine === 0,
    `A stalled manifest ${phase} cannot construct or start the engine`);
  check(blocked.timers.size === 1 && [...blocked.timers.values()][0].delay === 30000,
    `Both manifests share one bounded 30-second deadline while waiting for ${phase}`);
  blocked.expireManifest();
  await new Promise(setImmediate);
  check(blocked.doc.documentElement.dataset.bootState === 'error' && !blocked.nodes.get('retry-game').hidden && blocked.nodes.get('start-game').hidden,
    `A stalled manifest ${phase} reaches the ordinary visible Retry path`);
  check(blocked.timers.size === 0 && blocked.calls.requests.every(request => request.options.signal.aborted),
    `A manifest ${phase} timeout releases its timer and aborts both transfers`);
  for (const resolve of pending) resolve({});
  await new Promise(setImmediate);
  check(blocked.calls.engine === 0 && blocked.calls.start === 0 && blocked.calls.requests.length === 2 && blocked.doc.documentElement.dataset.bootState === 'error',
    `Late manifest ${phase} completions cannot create a stale engine or restart metadata reads`);
  blocked.nodes.get('retry-game').listeners.get('click')();
  check(blocked.calls.reload === 1, `Manifest ${phase} timeout keeps ordinary reload recovery`);
}

for (const failure of ['http', 'json']) {
  let sibling;
  const rejected = await bootShell({ fetchManifest: file => file === 'content-manifest.json'
    ? Promise.resolve({ ok: failure !== 'http', status: 503, json: () => Promise.reject(new SyntaxError('Invalid manifest JSON')) })
    : new Promise(resolve => { sibling = resolve; }) });
  check(rejected.doc.documentElement.dataset.bootState === 'error' && rejected.timers.size === 0
    && rejected.calls.requests.every(request => request.options.signal.aborted),
  `Manifest ${failure} rejection clears the deadline and cancels its sibling immediately`);
  sibling({ ok: true, json: () => Promise.resolve({}) });
  await new Promise(setImmediate);
  check(rejected.calls.engine === 0 && rejected.calls.errors.length === 1 && !rejected.nodes.get('retry-game').hidden,
    `A late sibling after ${failure} rejection cannot revive boot or hide Retry`);
}

let metadataReads = 0;
const mismatch = await bootShell({
  bootResources: () => { throw new Error('Release manifests differ'); },
  fetchManifest: () => ++metadataReads <= 2
    ? Promise.resolve({ ok: true, json: () => Promise.resolve({}) }) : new Promise(() => {})
});
check(mismatch.calls.requests.length === 4 && mismatch.timerStarts() === 1 && mismatch.timers.size === 1,
  'The existing manifest mismatch reread stays inside the original deadline');
mismatch.expireManifest();
await new Promise(setImmediate);
check(mismatch.doc.documentElement.dataset.bootState === 'error' && mismatch.calls.engine === 0 && mismatch.timers.size === 0
  && mismatch.calls.requests.every(request => request.options.signal.aborted),
  'A stalled manifest mismatch reread is cancelled without extending boot indefinitely');

const settleAfterContextLoss = [];
const interrupted = await bootShell({ fetchManifest: () => new Promise(resolve => { settleAfterContextLoss.push(resolve); }) });
interrupted.nodes.get('canvas').listeners.get('webglcontextlost')({ preventDefault() {} });
await new Promise(setImmediate);
check(interrupted.timers.size === 0 && interrupted.calls.requests.every(request => request.options.signal.aborted),
  'An independent boot failure immediately cancels pending manifest reads');
for (const resolve of settleAfterContextLoss) resolve({ ok: true, json: () => Promise.resolve({}) });
await new Promise(setImmediate);
check(interrupted.calls.engine === 0 && interrupted.doc.documentElement.dataset.bootState === 'error',
  'Context loss while reading metadata remains terminal against a late response');
check(!/\bLoaderUI\b|loader-enter|loader-retry/.test(shell), 'Reference prototype state machine is absent from production');
check(!/transition\s*:\s*width/.test(shell) && shell.includes('100vh') && /env\(safe-area-inset-top, 0px\)/.test(shell), 'Real progress has no animated width and viewport/safe-area fallbacks remain');
console.log(JSON.stringify({ success: true, checks, scope: 'Fake-DOM presentation ownership, progress, accessibility and actual shell manifest failure/deadline lifecycle. Visual design, real browser timing and actual Godot boot acceptance remain separate.' }));
