import path from 'node:path';
import {appendFileSync, writeFileSync} from 'node:fs';
import {phoneGroups, runPhoneRecoveryGroups} from './web_phone_shards.mjs';

// Diagnostic-only, bounded Node-side records. Never feed these into acceptance.
// Synchronous small writes survive a killed Node process without a buffered queue.
// No timer, browser read, input, retry or full event array is added here.
export function createPhoneProgress({filename, id, group, touch, dpr, cdpProgress = () => null}) {
  const maxRecords = 128, maxRecordBytes = 4096;
  let sequence = 0, failed;
  const fail = error => {
    failed ||= new Error(`Phone progress diagnostic write failed: ${error.message}`, {cause: error});
    console.error(failed.message);
    throw failed;
  };
  try {writeFileSync(filename, '');} catch (error) {fail(error);}
  return (event, timing) => {
    if (failed) throw failed;
    try {
      if (sequence >= maxRecords) throw Error(`record limit ${maxRecords} exceeded`);
      const row = {schema: '755-phone-progress-v1', diagnosticOnly: true, complete: false,
        sequence: sequence + 1, at: Date.now(), id, group, touch, dpr, event,
        cdp: cdpProgress()};
      if (timing) row.exercise = {
        segment: timing.segment, startedAt: timing.startedAt, finishedAt: timing.finishedAt ?? null,
        elapsedMs: timing.elapsedMs ?? Date.now() - timing.startedAt,
        geometryCalls: timing.geometryCalls, geometryMs: timing.geometryMs,
        pointerMoves: timing.pointerMoves, inputWaitMs: timing.inputWaitMs,
        pointerAck: Object.fromEntries(['start', 'move', 'end'].map(phase => {
          const stats = timing.pointerAck[phase];
          return [phase, {calls: stats.calls, acknowledged: stats.acknowledged, failed: stats.failed,
            totalMs: stats.totalMs, maxMs: stats.maxMs}];
        })),
        snapshots: {calls: timing.snapshots.calls, failed: timing.snapshots.failed,
          totalMs: timing.snapshots.totalMs, maxMs: timing.snapshots.maxMs},
        sentCount: timing.sent.length, observedCount: timing.observed?.events?.length ?? null,
        maxInFlight: timing.maxInFlight,
        releaseError: timing.releaseError?.slice(0, 256) ?? null,
        observationError: timing.observationError?.slice(0, 256) ?? null
      };
      const line = JSON.stringify(row) + '\n';
      if (Buffer.byteLength(line) > maxRecordBytes) throw Error(`record byte limit ${maxRecordBytes} exceeded`);
      appendFileSync(filename, line);
      sequence++;
    } catch (error) {fail(error);}
  };
}

// Save acceptance is not content readiness. In the cold C2-only shard, the
// required chapter packs can still occlude the world after the save is accepted.
// Observe their real completion before sending the one ordinary phone tap.
export async function waitForC2PhoneWorld(h, afterFrame) {
  const result = await h.poll(async () => {
    const value = await h.snapshot(), content = value?.content;
    const required = content?.requiredIds;
    const packs = Array.isArray(content?.packs) ? content.packs : [];
    const chapterPacks = packs.filter(pack => pack.family === 'chapter2');
    const failed = packs.find(pack => (pack.family === 'chapter2' || required?.includes(pack.id)) && (pack.error || pack.status === 'error'));
    if (content?.manifestError || failed) return {error: content.manifestError || `${failed.id}: ${failed.error || failed.status}`};
    if (!Number.isSafeInteger(afterFrame) || !Number.isSafeInteger(value?.sampleFrame) || value.sampleFrame <= afterFrame || value.documentHidden === true) return null;
    // requiredIds lists active waiters and is normally empty after success.
    // The manifest-backed family, not that transient list, proves all C2 packs.
    if (value.state?.native?.chapter !== 2 || value.state.native.scene !== 'dorm_hub' || content?.enabled !== true || content.blocking !== false || !content.readyFamilies?.includes('chapter2') || chapterPacks.length === 0 || !chapterPacks.every(pack => pack.status === 'ready') || !Array.isArray(required) || !required.every(id => packs.some(pack => pack.id === id && pack.status === 'ready'))) return null;
    if (value.world?.visible !== true || value.world.scene_id !== 'dorm_hub' || value.world.backgroundPlate?.ready !== true || value.world.input?.modalVisible !== false || (h.touch && value.world.input.geometryAvailable !== true)) return null;
    const controls = (value.visibleControls || []).filter(control => control.name === 'WorldPhoneButton');
    if (controls.length !== 1 || controls[0].disabled !== false) return null;
    const r = controls[0].rect, v = value.viewport;
    if (!r || !v || ![r.x, r.y, r.width, r.height, v.width, v.height].every(Number.isFinite) || r.width <= 0 || r.height <= 0 || v.width <= 0 || v.height <= 0) return null;
    // The snapshot and click harness use pre-rotation root coordinates. Bounds
    // must be tested after the same canvas quarter turn used for actual input.
    const rotation = value.presentation?.rotation || 0;
    const screen = rotation === 1 ? {x:v.width-r.y-r.height,y:r.x,width:r.height,height:r.width}
      : rotation === -1 ? {x:r.y,y:v.height-r.x-r.width,width:r.height,height:r.width} : r;
    if (screen.x < 0 || screen.y < 0 || screen.x + screen.width > v.width || screen.y + screen.height > v.height) return null;
    return {value};
  }, 'cold C2 required content and restored dorm world are ready before phone input', h.bootTimeout);
  if (result.error) throw Error(`C2 phone content failed: ${result.error}`);
  return result.value;
}

// Opening the control center and publishing its native layout are separate
// frames on slow renderers. Observe readiness without dispatching more input.
export async function waitForBrightnessControl(h, afterFrame) {
  return h.poll(async () => {
    const value = await h.snapshot();
    if (!Number.isSafeInteger(afterFrame) || !Number.isSafeInteger(value?.sampleFrame) || value.sampleFrame <= afterFrame || value.documentHidden === true) return null;
    const matches = (value.visibleControls || []).filter(c => c.name === 'ControlBrightness');
    if (matches.length !== 1 || matches[0].disabled !== false) return null;
    const slider = matches[0], r = slider.rect, v = value.viewport;
    if (!r || !v || ![r.x, r.y, r.width, r.height, v.width, v.height].every(Number.isFinite) || r.width <= 0 || r.height <= 0 || v.width <= 0 || v.height <= 0 || r.x < 0 || r.y < 0 || r.x + r.width > v.width || r.y + r.height > v.height) return null;
    return { value, slider };
  }, 'fresh native brightness control is visible and usable', 20000);
}

// Only the harness trace is writable. Listeners never cancel, synthesize or
// modify an event or game state. This function is serialized into the browser.
export function exerciseInputObserver(action, touch) {
  const key = '__755ExerciseInputObservation';
  if (action === 'begin') {
    if (window[key]) throw Error('Exercise observer already active');
    const state = {events: [], overflow: false, cancelled: false};
    const types = touch ? ['touchstart', 'touchmove', 'touchend', 'touchcancel'] : ['mousedown', 'mousemove', 'mouseup'];
    state.listen = event => {
      if (event.type === 'touchcancel') state.cancelled = true;
      const phase = ({touchstart: 'start', touchmove: 'move', touchend: 'end', mousedown: 'start', mousemove: 'move', mouseup: 'end'})[event.type];
      if (!phase) return;
      const points = touch ? Array.from(event.changedTouches) : [event];
      for (const point of points) {
        if (state.events.length >= 1024) {state.overflow = true; break;}
        state.events.push({phase, x: point.clientX, y: point.clientY, trusted: event.isTrusted,
          identifier: touch ? point.identifier : null, buttons: touch ? null : event.buttons, at: performance.now()});
      }
    };
    state.types = types;
    for (const type of types) window.addEventListener(type, state.listen, {capture: true, passive: true});
    window[key] = state;
    return true;
  }
  const state = window[key];
  if (!state) throw Error('Exercise observer is not active');
  const result = {events: state.events.slice(), overflow: state.overflow, cancelled: state.cancelled};
  if (action === 'end') {
    for (const type of state.types) window.removeEventListener(type, state.listen, {capture: true});
    delete window[key];
  } else if (action !== 'read') throw Error('Unknown exercise observer operation');
  return result;
}

export function verifyExerciseObservation(observed, sent, touch) {
  if (!observed || observed.overflow || observed.cancelled || !Array.isArray(observed.events) || observed.events.length !== sent.length)
    throw Error('Exercise browser event observation lost, added or cancelled input');
  for (let i = 0; i < sent.length; i++) {
    const actual = observed.events[i], expected = sent[i];
    if (actual.phase !== expected.phase || actual.trusted !== true || !Number.isFinite(actual.x) || !Number.isFinite(actual.y)
      || Math.hypot(actual.x - expected.x, actual.y - expected.y) > .05
      || (touch && actual.identifier !== 4) || (!touch && actual.buttons !== (expected.phase === 'end' ? 0 : 1)))
      throw Error(`Exercise browser event order/coordinate differs at input ${i + 1}`);
  }
}

// Keep every move serialized: real browsers coalesced concurrent commands even
// when all ACKs succeeded. Observe the ACK first, then retain the original 80ms
// interval. Trusted DOM event verification below remains mandatory.
export function createExerciseMoveQueue(dispatch, interval, timing, now = () => performance.now()) {
  const pending = new Set(); let firstError;
  const fail = error => {firstError ||= error;};
  return {
    async move(point) {
      while (pending.size >= 1) {await Promise.race(pending); if (firstError) throw firstError;}
      if (firstError) throw firstError;
      let job;
      try { job = Promise.resolve(dispatch(point)); } catch (error) { fail(error); throw error; }
      const tracked = job.then(() => {}, fail).finally(() => pending.delete(tracked));
      pending.add(tracked); timing.maxInFlight = Math.max(timing.maxInFlight || 0, pending.size);
      await tracked;
      if (firstError) throw firstError;
      const acknowledgedAt = now();
      await interval(80); timing.inputWaitMs += 80;
      // Timers can wake slightly early; do not allow a sub-80ms send interval.
      while (now() - acknowledgedAt < 80) {const remaining = 80 - (now() - acknowledgedAt); await interval(remaining); timing.inputWaitMs += remaining;}
      if (firstError) throw firstError;
    },
    async drain() {await Promise.all(pending); if (firstError) throw firstError;},
    async settle() {await Promise.all(pending);}
  };
}

export async function continuousExercise(h, evidence) {
  const initial = await h.poll(async () => {
    const s = await h.snapshot();
    return s.activeGame?.script === 'res://scripts/games/virtual_run.gd' && s.visibleControls.some(c => c.name === 'RunProgress') ? s : null;
  }, 'ordinary exercise opens the continuous running track');
  // Authored 430x820 exercise layout and stadium centreline. These coordinates
  // generate only ordinary pointer input, never game properties or progress.
  const radius = 83, straight = 130, quarter = Math.PI * radius / 2, length = Math.PI * radius * 2 + straight * 2;
  const fractions = [0, .075, .175, .275, .375, .475, .575, .675, .775, .875, 1];
  function pointAt(distance) {
    let d = Math.min(length, Math.max(0, distance));
    if (d <= quarter) return { x: 180 + Math.cos(Math.PI / 2 + d / radius) * radius, y: 245 + Math.sin(Math.PI / 2 + d / radius) * radius };
    d -= quarter;
    if (d <= straight) return { x: 97, y: 245 - d };
    d -= straight;
    if (d <= Math.PI * radius) return { x: 180 + Math.cos(Math.PI + d / radius) * radius, y: 115 + Math.sin(Math.PI + d / radius) * radius };
    d -= Math.PI * radius;
    if (d <= straight) return { x: 263, y: 115 + d };
    d -= straight;
    return { x: 180 + Math.cos(d / radius) * radius, y: 245 + Math.sin(d / radius) * radius };
  }
  function screenPoint(p, s) {
    const r = s.activeGame.rect, scale = r.width / 430;
    // track=(14,186,402,394), fit=1, centred source origin=(21,23).
    return { x: r.x + (35 + p.x) * scale, y: r.y + (209 + p.y) * scale };
  }
  const count = s => Number(s.visibleControls.find(c => c.name === 'RunProgress')?.text.match(/(\d+)\s*\/\s*10/)?.[1]);
  h.check(count(initial) === 0, `${h.id}: exercise starts with zero controller-earned fixes`);
  for (let segment = 0; segment < 10; segment++) {
    const timing = {segment: segment + 1, startedAt: Date.now(), geometryCalls: 0, geometryMs: 0, pointerMoves: 0, inputWaitMs: 0,
      pointerAck: Object.fromEntries(['start', 'move', 'end'].map(phase => [phase, {calls: 0, acknowledged: 0, failed: 0, totalMs: 0, maxMs: 0}])),
      snapshots: {calls: 0, failed: 0, totalMs: 0, maxMs: 0}, sent: [], observed: null, maxInFlight: 0};
    (evidence.exerciseTransport ||= []).push(timing);
    // Start/move/end stay serial. Keep attempted input, ACK and DOM receipt distinct.
    // Attempted input, browser observation and ACKs remain separate evidence.
    const sendPointer = async (phase, point) => {
      const stats = timing.pointerAck[phase], began = Date.now(); stats.calls++;
      // This CI Chromium path exposed integral MouseEvent client coordinates.
      // Send explicit integers for exact cross-implementation comparison; touch
      // retains its fractional path. Do not loosen the observation tolerance.
      // The original float point stays intact for canvas registration checks.
      const dispatchedPoint = h.touch ? point : {x: Math.trunc(point.x), y: Math.trunc(point.y)};
      const input = {phase, x: dispatchedPoint.x, y: dispatchedPoint.y, at: began}; timing.sent.push(input);
      try { const result = await h.pointer(phase, dispatchedPoint); stats.acknowledged++; input.acknowledgedAt = Date.now(); if (phase === 'move') timing.pointerMoves++; return result; }
      catch (error) { stats.failed++; input.error = error.message; input.failedAt = Date.now(); throw error; }
      finally { const elapsed = Date.now() - began; stats.totalMs += elapsed; stats.maxMs = Math.max(stats.maxMs, elapsed); }
    };
    const readSnapshot = async () => {
      const stats = timing.snapshots, began = Date.now(); stats.calls++;
      try { return await h.snapshot(); }
      catch (error) { stats.failed++; throw error; }
      finally { const elapsed = Date.now() - began; stats.totalMs += elapsed; stats.maxMs = Math.max(stats.maxMs, elapsed); }
    };
    let segmentFailure;
    try {
      h.progress?.('exercise-segment-start', timing);
      let s = await readSnapshot();
      // renderPoint is an axis-aligned canvas/viewport mapping. Measure it once
      // per segment instead of making a browser Runtime.evaluate round trip for
      // every two source pixels. The trajectory, 80ms cadence and authority reads
      // below stay unchanged. Revalidate at every existing eight-input boundary;
      // a resized/reframed canvas fails closed and finally releases the pointer.
      const measure = async (point, value) => {
        const began = Date.now();
        try { return await h.renderPoint(point, value); }
        finally { timing.geometryCalls++; timing.geometryMs += Date.now() - began; }
      };
      const origin = await measure({x: 0, y: 0}, s);
      const corner = await measure({x: 100, y: 100}, s);
      const transform = point => ({x: origin.x + point.x * (corner.x - origin.x) / 100,
        y: origin.y + point.y * (corner.y - origin.y) / 100});
      h.check([origin.x, origin.y, corner.x, corner.y].every(Number.isFinite) && corner.x > origin.x && corner.y > origin.y,
        `${h.id}: segment ${segment + 1} uses a measured positive canvas transform`);
      const geometry = JSON.stringify({rect: s.activeGame.rect, viewport: s.viewport});
      let last = transform(screenPoint(pointAt(fractions[segment] * length), s));
      h.check(count(s) === segment, `${h.id}: segment ${segment + 1} starts at the previous genuine checkpoint`);
      evidence.inputs.push({ method: h.touch ? 'ordinaryTouchDrag' : 'ordinaryMouseDrag', name: 'VirtualRunTrack', segment: segment + 1, at: Date.now() });
      const queue = createExerciseMoveQueue(point => sendPointer('move', point), h.interval, timing, h.monotonicNow);
      let failure, startAttempted = false;
      const observe = async action => {
        timing.observed = await h.observeExercise(action);
        verifyExerciseObservation(timing.observed, timing.sent, h.touch);
      };
      try {
        await h.observeExercise('begin');
        startAttempted = true;
        await sendPointer('start', last);
        const start = fractions[segment] * length, finish = fractions[segment + 1] * length;
        const steps = Math.ceil((finish - start) / 2);
        for (let step = 1; step <= steps; step++) {
          const sourcePoint = pointAt(start + (finish - start) * step / steps);
          last = transform(screenPoint(sourcePoint, s));
          await queue.move(last);
          if (step % 8 === 0) {
            h.progress?.('exercise-input-boundary', timing);
            await queue.drain(); await observe('read');
            s = await readSnapshot();
            if (count(s) === segment + 1) break;
            const actual = await measure(screenPoint(sourcePoint, s), s);
            h.check(JSON.stringify({rect: s.activeGame.rect, viewport: s.viewport}) === geometry &&
              Math.hypot(actual.x - last.x, actual.y - last.y) < .01,
              `${h.id}: continuous exercise canvas remains registered after input ${step} of segment ${segment + 1}`);
          }
        }
        await queue.drain(); await observe('read');
        s = await h.poll(async () => {
          const current = await readSnapshot();
          return count(current) === segment + 1 ? current : null;
        }, `continuous pointer traversal completes running segment ${segment + 1}`, 8000);
        evidence.samples.push({ label: `continuous exercise segment ${segment + 1}`, at: Date.now(), progress: s.visibleControls.find(c => c.name === 'RunProgress').text });
      } catch (error) {failure = error; throw error;}
      finally {
        // Stop issuing moves, observe every outstanding ACK, then release once.
        // Never let a release/observation failure mask the first transport error.
        await queue.settle();
        try {if (startAttempted) await sendPointer('end', last);} catch (error) {if (!failure) failure = error; timing.releaseError = error.message;}
        try {await observe('end');} catch (error) {if (!failure) failure = error; timing.observationError = error.message;}
        if (failure) throw failure;
      }
    } catch (error) {segmentFailure = error; throw error;}
    finally {
      timing.finishedAt = Date.now(); timing.elapsedMs = timing.finishedAt - timing.startedAt;
      try {h.progress?.(segmentFailure ? 'exercise-segment-failed' : 'exercise-segment-finished', timing);}
      catch (error) {
        if (!segmentFailure) throw error;
        // Retain the original transport/assertion failure, but never hide a
        // secondary diagnostic failure. The original run still fails closed.
        console.error(`Phone progress also failed: ${error.message}`);
      }
    }
  }
  const accepted = await h.poll(async () => {
    const s = await h.snapshot();
    return s.state.actOne.exerciseStarted && s.visibleControls.some(c => c.name === 'ReturnToTiyi') ? s : null;
  }, 'ten continuous exercise traces accepted by the original authority');
  h.check(count(accepted) === 10, `${h.id}: accepted exercise retains all ten genuine fixes`);
}

// Ordinary browser input only. The harness exposes a detached read-only Godot
// snapshot, real CDP pointer input, and the shipped portable-save file picker.
export async function phoneRecoveryCase(h) {
  const group = h.group === undefined ? 'all' : h.group;
  phoneGroups(group); // Reject an unknown selection before any browser input.
  const evidence = { group, completed: false, inputs: [], samples: [], coverage: [],
    fixtureConstructionIsNotBrowserEvidence: true };
  h.record(evidence);
  const read = async label => {
    const value = await h.snapshot();
    if (label) evidence.samples.push({ label, at: Date.now(), page: value.state.native.page,
      battery: value.state.phoneBattery, brightness: value.state.ui.brightness,
      flags: value.state.flags, digits: value.state.digits, actOne: value.state.actOne });
    return value;
  };
  const click = async name => {
    evidence.inputs.push({ name, at: Date.now(), method: h.touch ? 'ordinaryTouchTap' : 'ordinaryMouseClick' });
    await h.clickControl(name, 'name');
  };
  const page = name => h.poll(async () => (await read()).state.native.page === name, `phone page ${name}`);
  async function ensurePhoneSurface() {
    // An earned C2 save restores the world even while native.page remembers an
    // app. Open the actual phone through its shipped world button, not that field.
    const imported = await read();
    if (imported.world.visible) {
      evidence.contentWait = {beganAt: Date.now(), timeoutMs: h.bootTimeout};
      const ready = await waitForC2PhoneWorld(h, imported.sampleFrame);
      Object.assign(evidence.contentWait, {finishedAt: Date.now(), sampleFrame: ready.sampleFrame, requiredIds: ready.content.requiredIds, readyFamilies: ready.content.readyFamilies, chapter2Ids: ready.content.packs.filter(pack => pack.family === 'chapter2').map(pack => pack.id)});
      await click('WorldPhoneButton');
    }
    const value = await h.poll(async () => {
      const current = await read();
      return !current.world.visible && current.visibleControls.some(c => c.name === 'ControlCenterTrigger') ? current : null;
    }, 'ordinary world-to-phone navigation exposes the phone surface');
    h.check(!value.world.visible, `${h.id}: actual phone surface is visible before phone inventory and launcher input`);
  }
  async function closeInventory() {
    if (!(await read()).state.ui.inventoryOpen) return;
    // Earned saves can legitimately leave the existing inventory open. Close it
    // through its own handle, never click launcher buttons underneath its panel.
    await h.poll(async () => {
      const value = await read();
      return !value.world.visible && value.visibleControls.some(c => c.name === 'InventoryHandle');
    }, 'open phone inventory exposes its visible handle');
    await click('InventoryHandle');
    await h.poll(async () => {
      const value = await read();
      return !value.world.visible && !value.state.ui.inventoryOpen;
    }, 'ordinary inventory close clears launcher occlusion');
  }
  async function home() {
    for (let i = 0; i < 3; i++) {
      const current = await h.poll(async () => {
        const value = await read();
        if (value.content?.blocking) return null;
        const currentPage = value.state.native.page;
        if (currentPage === 'phone_home') return value;
        if (currentPage === 'bonsai' && !value.visibleControls.some(c => c.name === 'BonsaiPlant')) return null;
        return value.visibleControls.some(c => !c.disabled && ['PhoneNav_exit', 'PhoneNav_back'].includes(c.name)) ? value : null;
      }, 'ordinary return navigation');
      if (current.state.native.page === 'phone_home') return;
      const nav = current.visibleControls.find(c => c.name === 'PhoneNav_exit' && !c.disabled) || current.visibleControls.find(c => c.name === 'PhoneNav_back' && !c.disabled);
      await click(nav.name);
      if (nav.name === 'PhoneNav_exit') {
        // A CDP ACK and fixed delay do not acknowledge the cached native snapshot.
        // Exit targets home; observe that transition without sending another tap.
        await h.poll(async () => {
          const next = await read();
          return Number.isSafeInteger(current.sampleFrame) && Number.isSafeInteger(next.sampleFrame)
            && next.sampleFrame > current.sampleFrame && next.documentHidden !== true
            && !next.content?.blocking && next.state.native.page === 'phone_home';
        }, 'ordinary exit reaches phone home');
        await page('phone_home');
        return;
      }
    }
    await page('phone_home');
  }
  async function network(mode) {
    await click('ControlCenterTrigger');
    await click(mode === 'cellular' ? 'ControlNetwork_cellular' : 'ControlNetwork_wifi');
    await h.poll(async () => (await read()).state.networkMode === mode, `real network selection ${mode}`);
    await click('PhoneNav_close');
  }
  const shot = async name => h.capture(await h.screenshot(`${h.id}-${name}`));

  await runPhoneRecoveryGroups(group, {
    'charging': async () => {
      // Battery values are explicit legacy compatibility variants. Water/fertilizer
      // and every other story fact come from the uninterrupted controller campaign.
      for (const percent of [0, 1]) {
        const filename = `compat-c1-battery-${percent}-v35.json`;
        await h.importSave(path.join(h.fixtureDir, filename));
        await closeInventory();
        let value = await read(`legacy ${percent}% accepted`);
        const consumptionOnly = state => Object.keys(state.phoneBattery).length === 1 && Object.hasOwn(state.phoneBattery, 'percent') && !Object.hasOwn(state.ui, 'homeDeskReturnScene');
        const noRetiredControls = value => !(value.visibleControls || []).some(c => ['PutPhoneOnDesk', 'HomeChargingDock', 'DeskDockContact', 'DeskUnplug', 'LowPowerToggle'].includes(c.name));
        h.check(value.state.phoneBattery.percent === percent && consumptionOnly(value.state) && value.state.ui.brightness === 40,
          `${h.id}: ordinary legacy ${percent}% import preserves charge and brightness while removing retired power fields`);
        h.check(noRetiredControls(value), `${h.id}: imported home exposes no charging return control`);
        await click('HomeBonsaiOpen'); await page('bonsai');
        // The route is set before the first deferred artwork mounts. Wait
        // on the real object and exit control before exercising navigation.
        await h.poll(async () => {
          const current = await read();
          return !current.content?.blocking && current.state.native.page === 'bonsai'
            && current.visibleControls.some(c => c.name === 'BonsaiPlant')
            && current.visibleControls.some(c => c.name === 'PhoneNav_exit' && !c.disabled);
        }, 'first bonsai view and its ordinary exit are ready', h.bootTimeout);
        value = await read(`ordinary bonsai entry at ${percent}%`);
        h.check(noRetiredControls(value) && !value.state.flags.plantLit,
          `${h.id}: bonsai remains reachable without charging and dim light cannot satisfy the plant`);
        await home(); await click('HomeBonsaiOpen'); await page('bonsai');
        await h.interval(2400);
        value = await read(`navigation and elapsed time at ${percent}%`);
        h.check(value.state.phoneBattery.percent === percent && !value.state.flags.plantLit && consumptionOnly(value.state),
          `${h.id}: repeated return and elapsed time neither recharge nor award plant light`);
        await shot(`battery-${percent}-unchanged`);
        await h.importSave(path.join(h.fixtureDir, `compat-c1-desk-${percent}-v35.json`), { expectedPage: 'bonsai' });
        await closeInventory(); await page('bonsai');
        value = await read(`legacy desk ${percent}% restored to bonsai`);
        h.check(value.state.currentScene === 'bonsai' && value.state.phoneBattery.percent === percent && consumptionOnly(value.state) && noRetiredControls(value),
          `${h.id}: ordinary legacy desktop import returns to its original app without an unavailable pickup control`);
        await h.settings(); await h.saveProgressAndWait(`consumption-only ${percent}% before reload`); await h.startStory(true);
        await page('bonsai');
        value = await read(`legacy ${percent}% migration survives reload`);
        h.check(value.state.phoneBattery.percent === percent && consumptionOnly(value.state) && value.state.ui.brightness === 40 && !value.state.flags.plantLit,
          `${h.id}: normal save and reload preserve zero/one battery and unfinished plant without retired charging state`);
        const brightnessOpening = await read();
        await click('ControlCenterTrigger');
        const { value: before, slider } = await waitForBrightnessControl(h, brightnessOpening.sampleFrame);
        h.check(slider?.rect?.height > 0, `${h.id}: real brightness control geometry is observable`);
        evidence.inputs.push({ name: 'ControlBrightness', method: h.touch ? 'ordinaryTouchTap' : 'ordinaryMouseClick', at: Date.now(), sampleFrame: before.sampleFrame, rect: slider.rect });
        await h.clickPoint(await h.renderPoint({ x: slider.rect.x + slider.rect.width / 2, y: slider.rect.y + slider.rect.height * .05 }, before));
        await h.poll(async () => (await read()).state.ui.brightness >= 80, 'manual brightness reaches original plant threshold');
        value = await read(`manual brightness at ${percent}%`);
        h.check(value.state.phoneBattery.percent === percent && value.state.ui.brightnessUserAdjusted && noRetiredControls(value),
          `${h.id}: manual brightness remains uncapped and recorded at zero/one battery`);
        const wasPlaying = value.state.ui.musicPlaying;
        await click('ControlMusicPlay');
        await h.poll(async () => (await read()).state.ui.musicPlaying !== wasPlaying, 'music remains usable at zero/one battery');
        await shot(`control-center-${percent}`);
        await click('PhoneNav_close');
        await h.poll(async () => (await read()).state.flags.flowerBloomed, 'original watered/fertilized/light conditions bloom');
        value = await read(`recovered original plant path from ${percent}%`);
        h.check(value.state.flags.plantWatered && value.state.flags.plantFertilized && value.state.flags.plantLit && !value.state.flags.flowerEightTaken,
          `${h.id}: original three plant conditions still apply; migration and manual brightness never collect the digit`);
        await shot(`plant-${percent}-recovered`); await h.assertLayout(`battery migration recovery ${percent}%`);
      }
      evidence.coverage.push('legacy 0% and 1% ordinary imports', 'retired desk returns to original app', 'consumption-only save/reload and repeated app navigation', 'uncapped manual brightness and music at zero/one battery', 'original plant gates');
    },
    'c1-tiyi': async () => {
      await h.importSave(path.join(h.fixtureDir, 'before_c1_tiyi_digit.json'));
      await closeInventory();
      await home(); await network('campus_wifi'); await click('HomeApp_tiyi'); await page('tiyi');
      await page('phone_home');
      h.check(!(await read()).state.flags.tiyiCountTaken, `${h.id}: C1 WiFi failure does not award the first digit`);
      await network('cellular');
      const battery = (await read()).state.phoneBattery.percent;
      await click('HomeApp_tiyi'); await click('TiyiCount47');
      await h.poll(async () => (await read()).state.flags.tiyiCountTaken, 'C1 cellular still earns original number seven');
      let value = await read('C1 first network puzzle preserved');
      h.check(value.state.digits.d2 === '7' && value.state.phoneBattery.percent === battery,
        `${h.id}: first cellular trick remains valid and opening an app costs no fixed percent`);
      await shot('tiyi-first-cellular');
      evidence.coverage.push('C1 WiFi refusal then cellular earns 7', 'app navigation has no fixed battery cost');
    },
    'c2-tiyi': async () => {
      h.progress?.('c2-import-start');
      await h.importSave(path.join(h.fixtureDir, 'before_c2_tiyi_update.json'));
      h.progress?.('c2-imported');
      await ensurePhoneSurface();
      h.progress?.('c2-phone-ready');
      await closeInventory();
      await home(); await network('campus_wifi'); await network('cellular');
      await click('HomeApp_tiyi'); await page('tiyi'); await shot('tiyi-old-client'); await page('phone_home');
      let value = await read('C2 repeated network trick refused');
      h.check(value.state.actOne.tiyiUpdateStage === 'not_started' && !value.state.actOne.exerciseStarted && !value.state.actOne.weatherWaterTaken,
        `${h.id}: switching cellular again cannot update the second-stage client or earn rain`);
      h.progress?.('c2-old-client-refused');
      await click('HomeApp_wechat'); await click('TiyiOfficialAccount'); await shot('tiyi-official-account');
      await click('TiyiContact');
      await h.poll(async () => (await read()).state.actOne.tiyiUpdateStage === 'official_entry_found', 'ordinary Contact action reveals the official update entry');
      h.check((await read()).state.actOne.tiyiUpdateStage === 'official_entry_found', `${h.id}: real Contact menu discovers the official download card`);
      h.progress?.('c2-official-entry-found');
      await click('TiyiAcquireUpdate');
      await h.poll(async () => (await read()).state.actOne.tiyiUpdateStage === 'package_ready', 'ordinary update acquisition produces the package');
      h.check((await read()).state.actOne.tiyiUpdateStage === 'package_ready', `${h.id}: ordinary simulated acquisition does not install automatically`);
      h.progress?.('c2-package-ready');
      await shot('tiyi-package-ready'); await click('TiyiInstallUpdate');
      await h.poll(async () => (await read()).state.actOne.tiyiUpdateStage === 'installed', 'ordinary explicit installation completes');
      value = await read('C2 installed through ordinary official-account buttons');
      h.check(value.state.actOne.tiyiUpdateStage === 'installed' && !value.state.actOne.exerciseStarted && !value.state.actOne.weatherWaterTaken,
        `${h.id}: explicit installation grants neither exercise nor rain`);
      h.progress?.('c2-installed');
      await click('TiyiUpdateReturnHome'); await page('phone_home');
      h.progress?.('c2-save-start');
      await h.settings(); await h.saveProgressAndWait('installed Tiyi before reload');
      h.progress?.('c2-reload-start');
      await h.startStory(true);
      h.check((await read()).state.actOne.tiyiUpdateStage === 'installed', `${h.id}: real browser reload retains installation`);
      h.progress?.('c2-reloaded');
      await click('HomeApp_tiyi'); await click('TiyiExercise');
      h.progress?.('c2-exercise-start');
      await continuousExercise(h, evidence);
      h.progress?.('c2-exercise-accepted');
      await shot('tiyi-real-exercise'); await click('ReturnToTiyi'); await home();
      await click('HomeWeatherOpen');
      h.progress?.('c2-weather-claim-start');
      await click('WeatherWaterCard');
      // CDP delivery plus a fixed delay does not acknowledge the engine's cached
      // snapshot. Observe this one real claim completing; never repeat the input.
      await h.poll(async () => {
        const current = await read();
        return current?.state?.native?.chapter === 2 && current.state.native.page === 'weather' && current.state.actOne.exerciseStarted && current.state.actOne.weatherWaterTaken && current.state.items.weatherWater;
      }, 'actual weather card claim after exercise completes');
      value = await read('C2 original weather rain earned after exercise');
      h.check(value.state.actOne.weatherWaterTaken && value.state.items.weatherWater, `${h.id}: original weather drop remains gated behind actual exercise`);
      h.progress?.('c2-weather-claimed');
      await shot('tiyi-weather-rain'); await h.assertLayout('Tiyi two-stage recovery');
      evidence.coverage.push('C2 repeated cellular trick refused', 'official account Contact acquisition and explicit installation', 'ordinary installation save/reload', 'ten continuous exercise traces then weather rain');
      h.progress?.('c2-finished');
    }
  });
  evidence.completed = true;
  return evidence;
}
