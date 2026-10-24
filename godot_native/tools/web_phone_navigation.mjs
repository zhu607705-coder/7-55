import path from 'node:path';

// Shipped controls, real mouse/touch/keyboard input and earned portable saves.
// Snapshot reads locate controls; they never mutate the running game.
export async function phoneNavigationCase(h) {
  const evidence = { completed: false, inputs: [], samples: [], coverage: [] };
  h.record(evidence);
  const read = h.snapshot;
  const find = (s, name) => s.visibleControls.find(c => c.name === name);
  const page = name => h.poll(async () => (await read()).state.native.page === name, `phone route ${name}`);
  const click = async name => { evidence.inputs.push({ name, touch: h.touch, at: Date.now() }); await h.clickControl(name, 'name'); };
  const shot = async label => h.capture(await h.screenshot(`${h.id}-${label}`));
  async function escape() { evidence.inputs.push({ key: 'Escape', at: Date.now() }); await h.press('Escape'); await h.interval(400); }
  async function home() {
    for (let n = 0; n < 6; n++) {
      const s = await read();
      if (s.world.visible) { await click('WorldPhoneButton'); continue; }
      if (s.state.ui.inventoryOpen) { await click('InventoryHandle'); continue; }
      if (s.state.native.page === 'phone_home') return;
      const nav = s.visibleControls.find(c => ['PhoneNav_exit', 'PhoneNav_back', 'TiyiOfficialBack', 'Cc98LoginExit'].includes(c.name));
      if (!nav) throw new Error('No visible return control on ' + s.state.native.page);
      await click(nav.name);
    }
    await page('phone_home');
  }
  async function network(mode) {
    await click('ControlCenterTrigger');
    await click(mode === 'cellular' ? 'ControlNetwork_cellular' : 'ControlNetwork_wifi');
    await click('PhoneNav_close');
    h.check((await read()).state.networkMode === mode, `${h.id}: network selected through ordinary controls`);
  }
  async function scrollTo(name) {
    for (let n = 0; n < 12; n++) {
      const s = await read(), c = find(s, name), p = s.phoneRect;
      if (!c) throw new Error(`Missing control ${name}`);
      if (c.rect.y >= p.y + p.height * .18 && c.rect.y + c.rect.height <= p.y + p.height * .95) return;
      const down = c.rect.y + c.rect.height > p.y + p.height * .95;
      const a = await h.renderPoint({ x: p.x + p.width * .84, y: p.y + p.height * (down ? .75 : .35) }, s);
      const b = await h.renderPoint({ x: p.x + p.width * .84, y: p.y + p.height * (down ? .35 : .75) }, s);
      await h.scroll(a, b, down); await h.interval(350);
    }
    throw new Error(`Cannot scroll control into view: ${name}`);
  }
  async function type(name, text) { await scrollTo(name); await click(name); await h.type(text); await h.interval(250); }

  await network('campus_wifi');
  await click('HomeApp_tiyi'); await page('tiyi');
  let s = await read();
  const loading = find(s, 'TiyiLoadingExit');
  h.check(loading && loading.rect.y < s.phoneRect.y + s.phoneRect.height * .22, `${h.id}: Tiyi loading return is at the top`);
  await click('TiyiLoadingExit'); await page('phone_home');
  await click('HomeApp_tiyi'); await page('tiyi'); await page('phone_home');
  h.check(!(await read()).state.flags.tiyiCountTaken, `${h.id}: original WiFi refusal does not award a digit`);
  await network('cellular');
  await click('HomeApp_tiyi'); await h.poll(async () => find(await read(), 'TiyiCount47'), 'Tiyi ready');
  await shot('tiyi-original-return'); await click('PhoneNav_exit'); await page('phone_home');
  evidence.coverage.push('original network refusal and ordinary ready exit');

  await h.importSave(path.join(h.fixtureDir, 'after_c2_tiyi_install.json')); await home(); await network('campus_wifi');
  await click('HomeApp_zjuding'); await h.poll(async () => find(await read(), 'ZjudingTab_contacts'), 'Zjuding ready');
  await click('ZjudingTab_contacts');
  if (!h.touch) {
    await escape();
    s = await read();
    h.check(s.state.native.page === 'zjuding' && !s.world.visible && !find(s, 'ZjudingOpenDirectory'), `${h.id}: detail Escape returns to parent app`);
    await escape(); await page('phone_home');
  } else { await click('PhoneNav_back'); await click('PhoneNav_exit'); await page('phone_home'); }
  await click('ControlCenterTrigger');
  if (!h.touch) await escape(); else await click('PhoneNav_close');
  h.check(!(await read()).state.ui.controlCenterOpen && !(await read()).world.visible, `${h.id}: control center closes without leaving phone`);
  evidence.coverage.push('detail-parent-home and control-center return');

  await click('HomeApp_cc98'); await page('cc98');
  await h.poll(async () => find(await read(), 'Cc98LoginExit'), 'unified authentication form');
  s = await read();
  h.check(!s.visibleControls.some(c => /^Cc98HintFragment_/.test(c.name)), `${h.id}: no explicit password answer cards`);
  await shot('auth-initial');
  await scrollTo('Cc98ReadCampusCard'); await click('Cc98ReadCampusCard');
  await h.poll(async () => (await read()).state.actOne.cc98Login.studentIdDiscovered, 'campus card read by original controller');
  for (let index = 0; index < 3; index++) {
    await scrollTo('Cc98RevealHint'); await click('Cc98RevealHint');
    s = await h.poll(async () => { const v = await read(); return v.state.actOne.cc98Login.revealedHintCount === index + 1 ? v : null; }, `auth dialogue ${index + 1}`);
    h.check(find(s, 'Cc98AttendantRemark').text.includes(['ZheJiang University', '1897', '气势来!'][index]), `${h.id}: clue is embedded in spoken line ${index + 1}`);
    evidence.samples.push({ label: `dialogue-${index + 1}`, text: find(s, 'Cc98AttendantRemark').text });
  }
  await shot('auth-taunt');
  await scrollTo('Cc98PreviousRemark'); await click('Cc98PreviousRemark');
  h.check(find(await read(), 'Cc98AttendantRemark').text.includes('1897'), `${h.id}: already-spoken clues can be reread`);
  h.check((await read()).state.actOne.cc98Login.revealedHintCount === 3, `${h.id}: rereading does not change hint authority`);
  await scrollTo('Cc98ReturnToForm'); await click('Cc98ReturnToForm');
  for (let i = 1; i <= 2; i++) {
    await type('Cc98LoginPassword', 'wrong'); await click('Cc98LoginSubmit');
    await h.poll(async () => (await read()).state.actOne.cc98Login.failureCount === i, `original failed attempt ${i}`);
  }
  await scrollTo('Cc98AskClearly'); await click('Cc98AskClearly');
  h.check(find(await read(), 'Cc98AttendantRemark').text.includes('大写字母在前'), `${h.id}: optional extraction help appears after two real failures`);
  await shot('auth-optional-help');
  await scrollTo('Cc98ReturnToForm'); await click('Cc98ReturnToForm');
  await type('Cc98LoginPassword', 'ZJU1897!'); await click('Cc98LoginSubmit');
  await h.poll(async () => (await read()).state.actOne.cc98Login.authenticated, 'original password authenticates');
  evidence.coverage.push('hidden dialogue clues, reread, failed attempts, optional help and original authentication');
  await home();

  await h.importSave(path.join(h.fixtureDir, 'before_c2_dorm_exit.json')); await home(); await network('cellular');
  const original = (await read()).state.actOne.exerciseStarted;
  await click('HomeApp_tiyi'); await h.poll(async () => find(await read(), 'PhoneNav_exit'), 'installed Tiyi ready');
  if (!h.touch) await escape(); else await click('PhoneNav_exit');
  await page('phone_home');
  s = await read();
  h.check(s.state.actOne.exerciseStarted === original && !s.world.visible, `${h.id}: exiting Tiyi preserves earned exercise state and returns home`);
  if (!h.touch) await escape(); else await click('PhoneWorldReturn');
  await h.poll(async () => (await read()).world.visible, 'home return reaches retained world');
  evidence.coverage.push('only phone home returns to retained world; no exercise-dependent exit');
  await h.assertLayout(`${h.id}: completed phone navigation`);
  evidence.completed = true;
  return evidence;
}
