import fs from 'node:fs';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';

const sha = bytes => createHash('sha256').update(bytes).digest('hex');
export function preparePhoneRecoveryInputs(directory) {
  directory = path.resolve(directory);
  function input(filename) {
    const bytes = fs.readFileSync(path.join(directory, filename));
    const value = JSON.parse(bytes);
    if (value.format !== '7-55-godot-native' || value.version !== 1 || !value.state) throw Error(`Not an ordinary portable save: ${filename}`);
    return { value, receipt: { filename, bytes: bytes.length, sha256: sha(bytes) } };
  }
  const plant = input('before_c1_plant_light.json');
  const first = input('before_c1_tiyi_digit.json');
  const update = input('before_c2_tiyi_update.json');
  const s = plant.value.state;
  if (plant.value.sourceVersion !== 36 || s.native.chapter !== 1 || s.native.page !== 'phone_home' ||
      !s.flags.plantWatered || !s.flags.plantFertilized || s.flags.plantLit || s.flags.flowerBloomed || s.flags.checkinDone)
    throw Error('Charging variants require the earned, unfinished C1 plant boundary');
  if (first.value.sourceVersion !== 36 || first.value.state.flags.tiyiCountTaken || first.value.state.digits.d2 !== null || first.value.state.native.chapter !== 1)
    throw Error('First network puzzle must not already have awarded the digit');
  if (update.value.sourceVersion !== 36 || update.value.state.native.chapter !== 2 || update.value.state.actOne.phase !== 'movement_required' || update.value.state.actOne.tiyiUpdateStage !== 'not_started' || update.value.state.actOne.exerciseStarted || update.value.state.actOne.weatherWaterTaken)
    throw Error('Second-stage input must precede the official-entry/update/exercise actions');
  const variants = [0, 1].map(percent => {
    const value = structuredClone(plant.value);
    // These are explicitly constructed legacy compatibility inputs, NOT earned
    // battery levels or a claimed historic user save. Story facts stay intact.
    value.sourceVersion = 35;
    value.state.phoneBattery.percent = percent;
    value.state.phoneBattery.lowPowerMode = true;
    value.state.ui.brightness = 40;
    delete value.state.actOne.tiyiUpdateStage;
    delete value.state.ui.homeDeskReturnScene;
    const filename = `compat-c1-battery-${percent}-v35.json`;
    const bytes = Buffer.from(JSON.stringify(value, null, 2) + '\n');
    fs.writeFileSync(path.join(directory, filename), bytes);
    return { filename, percent, sourceVersion: 35, bytes: bytes.length, sha256: sha(bytes),
      construction: 'Only legacy version/new-field omissions, battery percent/low-power and brightness differ from the controller-earned plant boundary.' };
  });
  const receipt = { schema: '755-phone-recovery-inputs-v1',
    earned: { plant: plant.receipt, firstTiyi: first.receipt, secondTiyi: update.receipt }, variants,
    scope: 'Input provenance only. Generated files and controller fixtures are not browser, rendering, charging, or navigation acceptance.' };
  fs.writeFileSync(path.join(directory, 'phone-recovery-inputs.json'), JSON.stringify(receipt, null, 2) + '\n');
  return receipt;
}
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  if (process.argv.length !== 3) throw Error('Usage: node prepare_phone_recovery_inputs.mjs <earned-fixture-directory>');
  console.log(JSON.stringify(preparePhoneRecoveryInputs(process.argv[2]), null, 2));
}
