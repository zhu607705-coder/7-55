#!/usr/bin/env node
// Scoped, repeatable retirement of stale phone-charger entries. Never rerun the
// full worlds exporter over curated campus geometry or replace decorative art.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
const root = path.resolve(import.meta.dirname, '../..');
const charger = 'theater_charging_station';
const modelPath = 'src/scenes/rpg/TheaterInteriorModel.ts';
const model = fs.readFileSync(path.join(root, modelPath), 'utf8');
assert(!model.includes('THEATER_CHARGING_STATION'), 'Remove the source charging model before retiring generated entries.');
const worldPath = path.join(root, 'godot_native/data/worlds.json');
const before = JSON.parse(fs.readFileSync(worldPath, 'utf8'));
const worlds = structuredClone(before);
const theater = worlds.worlds.theater_interior;
theater.interactionTargets = theater.interactionTargets.filter(entry => entry.id !== charger);
theater.constants.THEATER_INTERACTION_TARGETS = theater.constants.THEATER_INTERACTION_TARGETS.filter(entry => entry.id !== charger);
if (worlds.chargingConstants) {
  assert.deepEqual(Object.keys(worlds.chargingConstants).sort(), ['PHONE_BATTERY_RECHARGE_PERCENT', 'PHONE_CHARGING_DURATION_MS', 'THEATER_CHARGING_STATION']);
  delete worlds.chargingConstants;
}
delete worlds.sourceHashes['src/core/PhoneChargingStation.ts'];
worlds.sourceHashes[modelPath] = crypto.createHash('sha256').update(model).digest('hex');
for (const scene of Object.keys(before.worlds)) {
  if (scene !== 'theater_interior') assert.deepEqual(worlds.worlds[scene], before.worlds[scene]);
}
const layoutPath = path.join(root, 'godot_native/data/native/theater-object-layout.json');
const layoutBefore = JSON.parse(fs.readFileSync(layoutPath, 'utf8'));
const layout = structuredClone(layoutBefore);
for (const object of layout.objects) {
  if (object.targetIds?.includes(charger)) object.targetIds = object.targetIds.filter(id => id !== charger);
}
for (let i = 0; i < layout.objects.length; i++) {
  const {targetIds: _old, ...oldObject} = layoutBefore.objects[i];
  const {targetIds: _new, ...newObject} = layout.objects[i];
  assert.deepEqual(newObject, oldObject, 'Preserve poster art, source coordinates and collisions.');
}
for (const [file, data, previous] of [[worldPath, worlds, before], [layoutPath, layout, layoutBefore]]) {
  if (process.argv.includes('--check')) assert.deepEqual(previous, data, `Stale charging entries: ${file}`);
  else if (JSON.stringify(previous) !== JSON.stringify(data)) fs.writeFileSync(file, JSON.stringify(data, null, 2) + '\n');
}
console.log('Phone charging data retired; all other worlds, theater art and collisions unchanged.');
