#!/usr/bin/env node
// Shared receipt validation only; browser input and sealed-byte checks run first.
import fs from 'node:fs';
import {phoneInputs, assertPhoneCoverage} from './web_phone_shards.mjs';
const directory = 'godot_native/exports/verification/web_phone_recovery';
const report = JSON.parse(fs.readFileSync(`${directory}/web-acceptance.json`, 'utf8'));
const fixtures = JSON.parse(fs.readFileSync(`${process.env.RUNNER_TEMP}/godot-web-inputs/controller-earned/phone-recovery-inputs.json`, 'utf8'));
const expected = [process.env.ACCEPTANCE_PROFILE];
const group = process.env.ACCEPTANCE_PHONE_GROUP;
const inputs = phoneInputs(fixtures, group);
if (report.scenarios !== 'phone-recovery' || !report.passed || report.exportManifest?.sourceCommit !== process.env.GITHUB_SHA || report.exportManifest?.engine !== '4.7.1.stable.official' || JSON.stringify(report.cases.map(item => item.id).sort()) !== JSON.stringify(expected)) throw Error('Missing exact-source 4.7.1 phone recovery browser cases');
const profile = { 'desktop-1280': [1280, 720, false, 1], 'touch-390': [390, 844, true, 1], 'retina-touch-390': [390, 844, true, 3] }[process.env.ACCEPTANCE_PROFILE];
for (const item of report.cases) {
  if (JSON.stringify([item.width, item.height, item.touch, item.dpr]) !== JSON.stringify(profile)) throw Error(`Wrong actual phone profile: ${item.id}`);
  assertPhoneCoverage(item.phoneRecovery, group);
  if (!item.passed || !item.screenshots.length) throw Error(`Incomplete ordinary phone recovery evidence: ${item.id}`);
  if (!inputs.every(input => item.imports.some(actual => actual.filename === input.filename && actual.sha256 === input.sha256))) throw Error(`Unverified phone recovery import bytes: ${item.id}`);
}
const receipt = {group, sourceCommit: report.exportManifest.sourceCommit, engine: report.exportManifest.engine,
  runnerSha256: report.runnerSha256, phoneRecoveryRunnerSha256: report.phoneRecoveryRunnerSha256,
  inputBundle: JSON.parse(fs.readFileSync('godot_native/exports/verification/verified-inputs.json', 'utf8')),
  inputs, cases: report.cases.map(item => ({id: item.id, group, coverage: item.phoneRecovery.coverage, screenshots: item.screenshots})),
  scope: 'Actual ordinary Chromium inputs, imports and reload against the Godot WASM export. Low-battery legacy inputs are explicit compatibility constructions; no physical-device or four-chapter manual playthrough claim.'};
fs.writeFileSync(`${directory}/ci-phone-recovery-receipt.json`, JSON.stringify(receipt, null, 2) + '\n');
console.log(JSON.stringify(receipt, null, 2));
