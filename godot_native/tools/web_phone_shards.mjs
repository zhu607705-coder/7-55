// Static, exhaustive partitions of the existing independent portable-import flows.
// This module never changes a game state or substitutes for browser assertions.
export const PHONE_GROUPS = Object.freeze(['charging', 'c1-tiyi', 'c2-tiyi']);
export const PHONE_COVERAGE = Object.freeze({
  charging: Object.freeze(['legacy 0% and 1% ordinary imports', 'real dock cancel and duplicate-safe 2200ms recharge', 'manual brightness and original plant gates']),
  'c1-tiyi': Object.freeze(['C1 WiFi refusal then cellular earns 7', 'app navigation has no fixed battery cost']),
  'c2-tiyi': Object.freeze(['C2 repeated cellular trick refused', 'official account Contact acquisition and explicit installation', 'ordinary installation save/reload', 'ten actual exercise points then weather rain'])
});
export function phoneGroups(group = 'all') {
  if (group !== 'all' && !PHONE_GROUPS.includes(group)) throw Error(`Unknown phone recovery group: ${group}`);
  return group === 'all' ? [...PHONE_GROUPS] : [group];
}
export function phoneCoverage(group = 'all') { return phoneGroups(group).flatMap(name => PHONE_COVERAGE[name]); }
export function phoneInputs(fixtures, group = 'all') {
  const inputs = { charging: fixtures.variants, 'c1-tiyi': [fixtures.earned?.firstTiyi], 'c2-tiyi': [fixtures.earned?.secondTiyi] };
  const selected = phoneGroups(group).flatMap(name => {
    const values = inputs[name];
    if (!Array.isArray(values) || values.length !== (name === 'charging' ? 2 : 1) || values.some(value => !value || typeof value.filename !== 'string' || !/^[a-f0-9]{64}$/.test(value.sha256))) throw Error(`Incomplete ${name} phone fixture identities`);
    return values;
  });
  if (new Set(selected.map(value => value.filename)).size !== selected.length) throw Error('Duplicate phone input identities');
  return selected;
}
export async function runPhoneRecoveryGroups(group, callbacks) {
  const selected = phoneGroups(group);
  if (Object.keys(callbacks).sort().join() !== [...PHONE_GROUPS].sort().join() || PHONE_GROUPS.some(name => typeof callbacks[name] !== 'function')) throw Error('Phone runner must define every original flow exactly once');
  for (const name of selected) await callbacks[name]();
}
export function assertPhoneCoverage(evidence, group = 'all') {
  const expected = phoneCoverage(group);
  if (evidence?.completed !== true || evidence.group !== group || JSON.stringify(evidence.coverage) !== JSON.stringify(expected) || !Array.isArray(evidence.inputs) || !evidence.inputs.length) throw Error(`Incomplete exact phone coverage: ${group}`);
}
export function assertPhoneShardUnion(rows) {
  if (!Array.isArray(rows) || rows.length !== PHONE_GROUPS.length || new Set(rows.map(row => row.group)).size !== rows.length || rows.some(row => !PHONE_GROUPS.includes(row.group))) throw Error('Missing, duplicate or unknown phone groups');
  for (const row of rows) assertPhoneCoverage(row, row.group);
  const union = PHONE_GROUPS.flatMap(group => rows.find(row => row.group === group).coverage);
  if (JSON.stringify(union) !== JSON.stringify(phoneCoverage('all')) || new Set(union).size !== 9) throw Error('Phone shard union differs from the original nine gates');
}
