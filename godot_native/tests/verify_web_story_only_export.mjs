#!/usr/bin/env node
// Inspect real exported PCK directories, including payloads whose original
// resource path has become an anonymous .godot/imported or exported name.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { readPack } from '../tools/partition_web_pack.mjs';
import { campusPayloadIdentity, assertStoryOnlyPackEntries } from '../tools/web_story_content_policy.mjs';

const argument = name => process.argv.find(value => value.startsWith(name + '='))?.slice(name.length + 1);
const directory = argument('--export');
const negative = argument('--negative-export');
if (!directory) throw new Error('Required --export=actual-export-directory');
const project = path.resolve(import.meta.dirname, '..');
const identity = campusPayloadIdentity(project);
const manifest = JSON.parse(fs.readFileSync(path.join(directory, 'content-manifest.json'), 'utf8'));
assert.ok(manifest.packs.every(pack => !pack.family.startsWith('campus_')), 'Published manifest must not advertise campus packs');
assert.ok(manifest.backgroundOrder.every(family => !family.startsWith('campus_')), 'Published background order must contain only story chapters');
const files = [manifest.core, ...manifest.packs];
let checkedEntries = 0;
for (const record of files) {
  const pack = readPack(path.join(directory, record.file));
  assertStoryOnlyPackEntries(pack.entries, identity);
  checkedEntries += pack.count;
}
let priorCampusEntriesRejected = 0;
let anonymousPayloadsRejected = 0;
if (negative) {
  const prior = JSON.parse(fs.readFileSync(path.join(negative, 'content-manifest.json'), 'utf8'));
  const campus = prior.packs.filter(pack => pack.family.startsWith('campus_'));
  assert.ok(campus.length, 'Negative export must contain actual campus PCKs');
  for (const record of campus) {
    const entries = readPack(path.join(negative, record.file)).entries;
    for (const entry of entries) {
      assert.ok(identity.owner(entry.path), `Actual historical campus payload has a known source identity: ${entry.path}`);
      assert.throws(() => assertStoryOnlyPackEntries([entry], identity), /Research campus resource leaked/);
      priorCampusEntriesRejected++;
      if (entry.path.startsWith('.godot/')) anonymousPayloadsRejected++;
    }
  }
  assert.ok(anonymousPayloadsRejected > 0, 'Negative includes real anonymous imported/compiled payloads');
}
console.log(JSON.stringify({ success: true, scope: 'Actual PCK resource exclusion; engine input and scene lifecycle are covered separately.', packs: files.length, checkedEntries, campusSourceResources: identity.sourceResources, priorCampusEntriesRejected, anonymousPayloadsRejected }, null, 2));
