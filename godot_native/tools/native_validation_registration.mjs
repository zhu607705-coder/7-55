import path from 'node:path';

const safePath = value => typeof value === 'string' && value.length > 0 && !/[\\\\\x00-\x1f\x7f:*?\[\]]/.test(value)
 && !value.startsWith('/') && value.split('/').every(part => part && part !== '.' && part !== '..' && part !== '.git');
const requireValue = (condition, message) => {if (!condition) throw Error(message);};
const exactKeys = (value, allowed) => value && typeof value === 'object' && !Array.isArray(value) && Object.keys(value).every(key => allowed.includes(key));
const ids = value => Array.isArray(value) && value.every(id => typeof id === 'string' && id.length > 0 && !/[\x00-\x1f\x7f]/.test(id)) && new Set(value).size === value.length;

/** Explicit reader contract. It cannot add shared writers to the sealed producer manifest. */
export function registerStage(spec) {
 requireValue(exactKeys(spec, ['id','execution','entry','args','inputs','outputs','dependencies','exclusive','resources','durationHintMs']), 'Unknown or malformed native stage registration field');
 requireValue(ids([spec.id]) && ['godot','node','python','bash'].includes(spec.execution), 'Registration needs an exact ID and execution type: godot, node, python, or bash');
 const extension = {godot:/\.gd$/,node:/\.(?:mjs|js|cjs)$/,python:/\.py$/,bash:/\.sh$/}[spec.execution];
 requireValue(safePath(spec.entry) && extension.test(spec.entry) && (spec.execution !== 'godot' || spec.entry.startsWith('godot_native/')), 'Stage entry must be a safe repository-relative file matching its execution type');
 requireValue(Array.isArray(spec.inputs) && spec.inputs.length > 0 && spec.inputs.every(safePath) && new Set(spec.inputs).size === spec.inputs.length && spec.inputs.includes(spec.entry), 'Stage inputs must be unique repository-relative paths and include its entry');
 requireValue(Array.isArray(spec.outputs), 'Stage outputs must be explicit; use [] for no declared outputs');
 const outputs = spec.outputs.map(output => {
  requireValue(exactKeys(output, ['scope','path']) && output.scope === 'sandbox' && safePath(output.path), 'Shared outputs/writers are unsupported: separately audit PREPARATION_IDS, PRODUCER_OUTPUTS, transport, and consumers; only sandbox outputs may be registered');
  return Object.freeze({scope: 'sandbox', path: output.path});
 });
 requireValue(new Set(outputs.map(output => output.path)).size === outputs.length, 'Duplicate sandbox output path');
 const dependencies = spec.dependencies ?? [], args = spec.args ?? [], exclusive = spec.exclusive ?? false, resources = spec.resources ?? {slots:1};
 requireValue(ids(dependencies) && !dependencies.includes(spec.id), 'Stage dependencies must be unique exact IDs without self-dependency');
 requireValue(!dependencies.includes('test_buct_rongmao.gd'), 'Use test_buct_haidian.gd canonical owner; test_buct_rongmao.gd deduplication is finalized after dispatch');
 requireValue(Array.isArray(args) && args.every(arg => typeof arg === 'string' && !arg.includes('\0')), 'Stage arguments must be strings without NUL');
 requireValue(typeof exclusive === 'boolean', 'Stage exclusive must be boolean');
 requireValue(exactKeys(resources, ['slots']) && resources.slots === 1, 'Only resources.slots=1 is supported; use an explicit exclusive barrier or separately review weighted scheduling. Global workers remain capped at 1..4');
 requireValue(spec.durationHintMs === undefined || (Number.isSafeInteger(spec.durationHintMs) && spec.durationHintMs > 0), 'durationHintMs must be a positive safe integer');
 return Object.freeze({id:spec.id,execution:spec.execution,entry:spec.entry,args:Object.freeze([...args]),inputs:Object.freeze([...spec.inputs]),outputs:Object.freeze(outputs),
  dependencies:Object.freeze([...dependencies]),exclusive,resources:Object.freeze({slots:1}),...(spec.durationHintMs === undefined ? {} : {durationHintMs:spec.durationHintMs})});
}

// Each FLC reader uses one existing scheduler slot; no nested CI worker pool.
const flc='godot_native/campuses/future_learning_center';
export const NATIVE_STAGE_REGISTRATIONS = Object.freeze([
 ...['koala','machinery','solid_projection','platform','robotics','signal_sync','formula','flex','collab','focus','storage','assembly','rail','rules','projection','projection_placement','2f_placement','fold','logic','balance','schedule','recording','access','sync','perspective','coupled','puzzles_integration','floor'].map(name=>({
  id:`flc_${name}`,execution:'godot',entry:`${flc}/tests/test_${name}.gd`,args:['--with-view'],
  inputs:[`${flc}/tests/test_${name}.gd`,...(['floor','puzzles_integration','projection_placement','2f_placement'].includes(name)
   ? [`${flc}/scripts/floor_view.gd`,`${flc}/scripts/floor_space.gd`,`${flc}/data/floor_2.json`,`${flc}/data/floor_3.json`,`${flc}/data/floor_4.json`]
   : [`${flc}/scripts/puzzles/${name}_model.gd`,`${flc}/scripts/puzzles/${name}_view.gd`])],
  outputs:[],dependencies:[],durationHintMs:['floor','puzzles_integration','projection_placement','2f_placement'].includes(name)?15000:1000,
 })),
 {id:"flc_projection_table_builder",execution:"node",entry:`${flc}/tests/test_projection_table_builder.mjs`,
  inputs:[`${flc}/tests/test_projection_table_builder.mjs`,`${flc}/tools/place_projection_table.mjs`,`${flc}/data/floor_3.json`,`${flc}/data/object_assets.json`],outputs:[],dependencies:[],durationHintMs:1000}
]);

export function appendRegisteredStages(legacy, {project, executable, registrations = NATIVE_STAGE_REGISTRATIONS}) {
 requireValue(Array.isArray(registrations), 'Native stage registrations must be an array');
 const specs = registrations.map(registerStage), allIds = new Set(legacy.map(stage => stage.id)), byId = new Map();
 for (const spec of specs) {
  requireValue(!allIds.has(spec.id), `Duplicate native stage ID: ${spec.id}`);
  allIds.add(spec.id); byId.set(spec.id,spec);
 }
 for (const spec of specs) for (const dependency of spec.dependencies) requireValue(allIds.has(dependency), `Unknown dependency ${dependency} for registered stage ${spec.id}`);
 const ordered = [], active = new Set(), done = new Set();
 function visit(spec) {
  if (done.has(spec.id)) return;
  requireValue(!active.has(spec.id), `Registered stage dependency cycle: ${spec.id}`);
  active.add(spec.id);
  for (const dependency of spec.dependencies) if (byId.has(dependency)) visit(byId.get(dependency));
  active.delete(spec.id); done.add(spec.id); ordered.push(spec);
 }
 specs.forEach(visit);
 const root = path.dirname(project);
 return [...legacy, ...ordered.map(registration => {
  const {id,entry,execution,args,exclusive,dependencies} = registration;
  const command = {godot:executable,node:process.execPath,python:'python3',bash:'bash'}[execution];
  const commandArgs = execution === 'godot'
   ? ['--headless','--path',project,'--script',`res://${entry.slice('godot_native/'.length)}`,...(args.length ? ['--',...args] : [])]
   : [path.join(root,entry),...args];
  return {id,label:id,command,args:commandArgs,exclusive,dependencies:[...dependencies],registration};
 })];
}

export const registrationFields = stage => stage.registration ? {registration:stage.registration} : {};
