import { readFileSync, writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { stripTypeScriptTypes } from 'node:module';

// Execute the authored methods, not a hand-copied model of their behavior.
const here = dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
if (args.length > 1 || (args.length === 1 && (!args[0] || (args[0].startsWith('-') && args[0] !== '--check')))) {
  console.error('Usage: node export_tiyi_presence_source.mjs [--check | output-path]');
  process.exit(2);
}
const checkOnly = args[0] === '--check';
const out = checkOnly || args.length === 0 ? resolve(here, 'tiyi_audit_oracle.json') : resolve(args[0]);
const root = resolve(process.env.SOURCE_REPO_ROOT || resolve(here, '../..'));
const controllerPath = 'src/modules/LibraryFinalsController.ts';
const rulesPath = 'src/modules/library-finals/puzzleRules.ts';
const controller = readFileSync(resolve(root, controllerPath), 'utf8');
const rules = readFileSync(resolve(root, rulesPath), 'utf8');
function balancedBody(text, start, marker) {
  const index = text.indexOf(marker, start);
  if (index < 0) throw new Error(`Missing source marker: ${marker}`);
  const open = text.indexOf('{', index);
  let depth = 1, end = open + 1;
  for (; depth && end < text.length; end++) {
    if (text[end] === '{') depth++;
    if (text[end] === '}') depth--;
  }
  if (depth) throw new Error(`Unclosed source block: ${marker}`);
  return text.slice(index, end);
}
const rangeBlock = controller.slice(controller.indexOf('const AUDIT_RANGES:'), controller.indexOf('\n};', controller.indexOf('const AUDIT_RANGES:')) + 3);
const methods = ['setAuditValue(', 'submitAudit('].map(marker => balancedBody(controller, 0, marker));
const functions = ['function isAuditValueInRange(', 'function auditPuzzleField('].map(marker => balancedBody(controller, 0, marker));
const validate = balancedBody(rules, 0, 'function validateAudit(');
const config = JSON.parse(readFileSync(resolve(root, 'src/data/library-finals.puzzle.json'), 'utf8'));
const js = stripTypeScriptTypes(`${rangeBlock}\n${functions.join('\n')}\n${validate}\nclass SourceAudit { ${methods.join('\n')} }`, { mode: 'strip' });
const SourceAudit = new Function('LIBRARY_FINALS_PUZZLE_CONFIG', `${js}; return SourceAudit;`)(config);
const fields = { arrival: 'arrivalMinutes', notice: 'publicNoticeFloor', proofs: 'proofCount' };
const initialPuzzle = { investigationOpened: true, entranceRecordRead: true, archivedRuleRead: true, presenceProofCollected: false, auditArrivalMinutes: 0, auditPublicNoticeFloor: 0, auditProofCount: 0, auditAttemptCount: 0 };
function model(phase, opened, passed) {
  const subject = new SourceAudit();
  subject.phase = phase;
  subject.puzzle = { ...initialPuzzle, investigationOpened: opened, presenceProofCollected: passed };
  subject.items = {};
  subject.recorded = [];
  subject.getPhase = () => subject.phase;
  subject.getPuzzle = () => subject.puzzle;
  subject.patchFinals = (next, patch, _game, items) => { subject.phase = next; Object.assign(subject.puzzle, patch); Object.assign(subject.items, items); };
  subject.events = { emit: (event, payload = {}) => subject.recorded.push({ event, payload }) };
  return subject;
}
const drafts = [];
for (const phase of ['evidence_gathering', 'library_entered', 'top_ten_reached'])
  for (const opened of [false, true]) for (const passed of [false, true])
    for (const [native, source] of Object.entries(fields))
      for (const value of [-1, 0, 1, 5, 7, 12, 13, 47, 63, 64, 1.5, '7', null]) {
        const subject = model(phase, opened, passed);
        const accepted = subject.setAuditValue(source, value);
        drafts.push({ phase, opened, passed, field: native, sourceField: source, value, accepted, puzzle: subject.puzzle, events: subject.recorded });
      }
const submissions = [];
for (const phase of ['evidence_gathering', 'library_entered', 'top_ten_reached'])
  for (const opened of [false, true]) for (const passed of [false, true])
    for (const values of [{ arrivalMinutes: 5, publicNoticeFloor: 45, proofCount: 1 }, config.audit, { arrivalMinutes: 0, publicNoticeFloor: 47, proofCount: 3 }]) {
      const subject = model(phase, opened, passed);
      const accepted = subject.submitAudit(values);
      submissions.push({ phase, opened, passed, values, accepted, puzzle: subject.puzzle, items: subject.items, events: subject.recorded });
    }
const hashes = Object.fromEntries([controllerPath, rulesPath, 'src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx', 'src/data/library-finals.audio.json'].map(path => [path, createHash('sha256').update(readFileSync(resolve(root, path))).digest('hex')]));
const output = { provenance: 'Reconstructed source oracle; methods executed from active TypeScript source', hashes, drafts, submissions };
const serialized = JSON.stringify(output, null, 2) + '\n';
if (checkOnly) {
  let checkedIn;
  try {
    checkedIn = readFileSync(out, 'utf8');
  } catch (error) {
    console.error(`Cannot read Tiyi presence source oracle: ${out} (${error.code})`);
    process.exit(1);
  }
  if (checkedIn !== serialized) {
    console.error(`Tiyi presence source oracle is stale: ${out}`);
    process.exit(1);
  }
} else {
  writeFileSync(out, serialized);
}
console.log(JSON.stringify({ mode: checkOnly ? 'check' : 'generate', output: out, drafts: drafts.length, submissions: submissions.length, hashes }));
