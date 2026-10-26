import fs from 'node:fs';
import path from 'node:path';
import {digest} from './native_validation_identity.mjs';
import {PREPARATION_IDS} from './native_validation_plan.mjs';
import {registrationFields} from './native_validation_registration.mjs';

export const NATIVE_SHARD_COUNT = 6;
const observed = JSON.parse(fs.readFileSync(new URL('./native_validation_timings.json', import.meta.url), 'utf8')).durationMs;
export function stageDescriptor(stage, root) {
 const portable = value => value === root ? '$ROOT' : value.startsWith(`${root}${path.sep}`) ? `$ROOT/${path.relative(root, value).split(path.sep).join('/')}` : value;
 return {id: stage.id, command: stage.args.includes('--headless') ? 'godot' : path.basename(stage.command),
  args: stage.args.map(portable), exclusive: stage.exclusive, dependencies: stage.dependencies, ...registrationFields(stage)};
}
export function estimateShard(stages, durations = observed, jobs = 2) {
 if (!Number.isInteger(jobs) || jobs < 1 || jobs > 4) throw Error('Estimator jobs must be 1..4');
 const slots = Array(jobs).fill(0), finished = new Map();
 for (const stage of stages) {
  const duration = Number.isFinite(durations[stage.id]) && durations[stage.id] > 0 ? durations[stage.id] : (stage.registration?.durationHintMs ?? 20_000);
  const ready = Math.max(0,...stage.dependencies.map(id => finished.get(id) || 0));
  if (stage.exclusive) {const end = Math.max(ready,...slots) + duration; slots.fill(end); finished.set(stage.id,end);}
  else {const next = slots.indexOf(Math.min(...slots)); slots[next] = Math.max(slots[next],ready) + duration; finished.set(stage.id,slots[next]);}
 }
 return Math.max(...slots);
}
/** Timing only chooses owners. Every catalog entry remains mandatory. */
export function createShardPlan(catalog, root, {count = NATIVE_SHARD_COUNT, durations = observed} = {}) {
 if (!Number.isInteger(count) || count < 1 || count > NATIVE_SHARD_COUNT) throw Error('Native shard count must be 1..6');
 if (new Set(catalog.map(s => s.id)).size !== catalog.length) throw Error('Duplicate native catalog ID');
 const byId = new Map(catalog.map(s => [s.id, s]));
 for (const id of PREPARATION_IDS) if (!byId.has(id)) throw Error(`Missing preparation stage ${id}`);
 const rest = catalog.filter(s => !PREPARATION_IDS.includes(s.id));
 const parent = new Map(rest.map(stage => [stage.id,stage.id]));
 const find = id => parent.get(id) === id ? id : find(parent.get(id));
 const join = (a,b) => parent.set(find(b),find(a));
 for (const stage of rest) for (const dependency of stage.dependencies) if (!PREPARATION_IDS.includes(dependency)) {
  if (!stage.registration || !parent.has(dependency)) throw Error(`Unclassified cross-shard dependency: ${stage.id}`);
  join(stage.id,dependency);
 }
 const canonical = 'test_buct_haidian.gd', alias = 'test_buct_rongmao.gd';
 // Explicit reader dependency components and the audited alias share an owner.
 if (parent.has(canonical) && parent.has(alias)) join(canonical,alias);
 const components = new Map();
 for (const stage of rest) {const key = find(stage.id); if (!components.has(key)) components.set(key,[]); components.get(key).push(stage);}
 const groups = [...components.values()];
 groups.sort((a, b) => estimateShard(b, durations) - estimateShard(a, durations) || a[0].id.localeCompare(b[0].id));
 const shards = Array.from({length: count}, () => []), order = new Map(catalog.map((s, i) => [s.id, i]));
 const ordered = stages => [...stages].sort((a, b) => order.get(a.id) - order.get(b.id));
 for (const group of groups) {
  const choices = shards.map((stages, index) => ({index, duration: estimateShard(ordered([...stages, ...group]), durations)}));
  choices.sort((a, b) => a.duration - b.duration || a.index - b.index);
  shards[choices[0].index].push(...group);
 }
 const result = {schema: '755-native-shards-v1', count, jobs: 2, preparationIds: PREPARATION_IDS,
  catalog: catalog.map(s => stageDescriptor(s, root)),
  shards: shards.map((stages, index) => ({index, ids: ordered(stages).map(s => s.id), predictedMs: estimateShard(ordered(stages), durations)}))};
 const owners = result.shards.flatMap(s => s.ids);
 if (owners.length + PREPARATION_IDS.length !== catalog.length || new Set(owners).size !== owners.length) throw Error('Native partition lost or duplicated coverage');
 return {...result, sha256: digest(result)};
}
export function selectShard(catalog, root, index, count = NATIVE_SHARD_COUNT) {
 const shards = createShardPlan(catalog, root, {count});
 if (!Number.isInteger(index) || index < 0 || index >= count) throw Error('Invalid native shard index');
 const owned = new Set(shards.shards[index].ids), prepared = new Set(PREPARATION_IDS);
 return {shards, owned, prepared,
  plan: {profile: 'shard', effectiveProfile: 'shard', partial: true, reasons: [`Shard ${index + 1}/${count}: aggregate is the only full-suite acceptance.`],
   finalAcceptance: 'Only the complete exact-source shard aggregate may claim full acceptance.',
   stages: catalog.filter(s => owned.has(s.id)), rows: catalog.map(s => ({id:s.id, selected:owned.has(s.id), status:'not-run', dependencies:s.dependencies, exclusive:s.exclusive, ...registrationFields(s)}))}};
}
