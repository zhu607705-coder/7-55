import path from 'node:path';

// Ordinary browser input only. The harness exposes a detached read-only Godot
// snapshot, real CDP pointer input, and the shipped portable-save file picker.
export async function phoneRecoveryCase(h) {
  const evidence = { completed: false, inputs: [], samples: [], coverage: [],
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
    if ((await read()).world.visible) await click('WorldPhoneButton');
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
        return value.state.native.page === 'phone_home' || value.visibleControls.some(c => ['PhoneNav_exit', 'PhoneNav_back'].includes(c.name)) ? value : null;
      }, 'ordinary return navigation');
      if (current.state.native.page === 'phone_home') return;
      const nav = current.visibleControls.find(c => c.name === 'PhoneNav_exit') || current.visibleControls.find(c => c.name === 'PhoneNav_back');
      await click(nav.name);
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

  // Battery values are explicit legacy compatibility variants. Water/fertilizer
  // and every other story fact come from the uninterrupted controller campaign.
  for (const percent of [0, 1]) {
    const filename = `compat-c1-battery-${percent}-v35.json`;
    await h.importSave(path.join(h.fixtureDir, filename));
    await closeInventory();
    let value = await read(`legacy ${percent}% accepted`);
    h.check(value.state.phoneBattery.percent === percent && value.state.phoneBattery.lowPowerMode && value.state.ui.brightness === 40,
      `${h.id}: ordinary legacy ${percent}% import preserves the low-battery input`);
    await click('HomeBonsaiOpen'); await page('bonsai');
    await click('PutPhoneOnDesk'); await page('desktop');
    await click('DeskDockContact');
    await h.poll(async () => (await read()).visibleControls.some(c => c.name === 'DeskChargingStatus' && /^连接 [1-9][0-9]*%/.test(c.text)), 'actual incomplete charging session is visible');
    value = await read('real partial charge before cancellation');
    h.check(value.state.phoneBattery.percent === percent, `${h.id}: visible charging progress does not grant energy early`);
    await click('DeskPhonePickup'); await page('bonsai');
    await h.interval(2400);
    value = await read(`cancelled ${percent}% charge`);
    h.check(value.state.phoneBattery.percent === percent && !value.state.flags.plantLit,
      `${h.id}: early pickup cancels actual charging without granting energy or light`);
    await click('PutPhoneOnDesk'); await page('desktop');
    await shot(`dock-${percent}-before`);
    const began = Date.now(), rechargeCount = value.state.phoneBattery.rechargeCount;
    await click('DeskDockContact'); await click('DeskDockContact');
    await h.poll(async () => (await read()).state.phoneBattery.percent >= 45, 'real desktop charge completes', 12000);
    value = await read(`charged ${percent}% through actual dock`);
    h.check(Date.now() - began >= 2200 && value.state.phoneBattery.rechargeCount === rechargeCount + 1 && !value.state.phoneBattery.lowPowerMode,
      `${h.id}: duplicate start grants exactly one real 2200ms charge and exits low-power mode`);
    h.check(value.state.ui.brightness === 40 && !value.state.flags.plantLit && !value.state.flags.flowerBloomed,
      `${h.id}: charging does not change brightness or award plant progression`);
    await shot(`dock-${percent}-charged`);
    await click('DeskPhonePickup'); await page('bonsai');
    await click('ControlCenterTrigger');
    const before = await read();
    const slider = before.visibleControls.find(c => c.name === 'ControlBrightness');
    h.check(slider?.rect?.height > 0, `${h.id}: real brightness control geometry is observable`);
    evidence.inputs.push({ name: 'ControlBrightness', method: h.touch ? 'ordinaryTouchTap' : 'ordinaryMouseClick', at: Date.now() });
    await h.clickPoint(await h.renderPoint({ x: slider.rect.x + slider.rect.width / 2, y: slider.rect.y + slider.rect.height * .05 }, before));
    await h.poll(async () => (await read()).state.ui.brightness >= 80, 'manual brightness reaches original plant threshold');
    await shot(`control-center-${percent}`);
    await click('PhoneNav_close');
    await h.poll(async () => (await read()).state.flags.flowerBloomed, 'original watered/fertilized/light conditions bloom');
    value = await read(`recovered original plant path from ${percent}%`);
    h.check(value.state.flags.plantWatered && value.state.flags.plantFertilized && value.state.flags.plantLit && !value.state.flags.flowerEightTaken,
      `${h.id}: original three plant conditions still apply; charging never collects the digit`);
    await shot(`plant-${percent}-recovered`); await h.assertLayout(`charging recovery ${percent}%`);
  }
  evidence.coverage.push('legacy 0% and 1% ordinary imports', 'real dock cancel and duplicate-safe 2200ms recharge', 'manual brightness and original plant gates');

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

  await h.importSave(path.join(h.fixtureDir, 'before_c2_tiyi_update.json'));
  await ensurePhoneSurface();
  await closeInventory();
  await home(); await network('campus_wifi'); await network('cellular');
  await click('HomeApp_tiyi'); await page('tiyi'); await shot('tiyi-old-client'); await page('phone_home');
  value = await read('C2 repeated network trick refused');
  h.check(value.state.actOne.tiyiUpdateStage === 'not_started' && !value.state.actOne.exerciseStarted && !value.state.actOne.weatherWaterTaken,
    `${h.id}: switching cellular again cannot update the second-stage client or earn rain`);
  await click('HomeApp_wechat'); await click('TiyiOfficialAccount'); await shot('tiyi-official-account');
  await click('TiyiContact');
  h.check((await read()).state.actOne.tiyiUpdateStage === 'official_entry_found', `${h.id}: real Contact menu discovers the official download card`);
  await click('TiyiAcquireUpdate');
  h.check((await read()).state.actOne.tiyiUpdateStage === 'package_ready', `${h.id}: ordinary simulated acquisition does not install automatically`);
  await shot('tiyi-package-ready'); await click('TiyiInstallUpdate');
  value = await read('C2 installed through ordinary official-account buttons');
  h.check(value.state.actOne.tiyiUpdateStage === 'installed' && !value.state.actOne.exerciseStarted && !value.state.actOne.weatherWaterTaken,
    `${h.id}: explicit installation grants neither exercise nor rain`);
  await click('TiyiUpdateReturnHome'); await page('phone_home');
  await h.settings(); await h.saveProgressAndWait('installed Tiyi before reload'); await h.startStory(true);
  h.check((await read()).state.actOne.tiyiUpdateStage === 'installed', `${h.id}: real browser reload retains installation`);
  await click('HomeApp_tiyi'); await click('TiyiExercise');
  for (let point = 1; point <= 10; point++) await click(`Fix${point}`);
  await h.poll(async () => (await read()).state.actOne.exerciseStarted, 'ten actual exercise point presses accepted');
  await shot('tiyi-real-exercise'); await click('ReturnToTiyi'); await home();
  await click('HomeWeatherOpen'); await click('WeatherWaterCard');
  value = await read('C2 original weather rain earned after exercise');
  h.check(value.state.actOne.weatherWaterTaken && value.state.items.weatherWater, `${h.id}: original weather drop remains gated behind actual exercise`);
  await shot('tiyi-weather-rain'); await h.assertLayout('Tiyi two-stage recovery');
  evidence.coverage.push('C2 repeated cellular trick refused', 'official account Contact acquisition and explicit installation', 'ordinary installation save/reload', 'ten actual exercise points then weather rain');
  evidence.completed = true;
  return evidence;
}
