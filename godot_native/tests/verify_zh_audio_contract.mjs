import assert from 'node:assert/strict';
import fs from 'node:fs';
import crypto from 'node:crypto';
import path from 'node:path';
import {applyNativeAudioTextRevisions, normalizeSubtitle, originalTheaterDuration} from '../tools/audio-text-revisions.mjs';

const root = path.resolve(import.meta.dirname, '..');
const read = relative => JSON.parse(fs.readFileSync(path.join(root, relative), 'utf8'));
const source = read('data/native/audio-director-source.json');
const fixture = read('tests/fixtures/zh_audio_contract.json');
const revisions = fs.existsSync(path.join(root, 'data/zh_text_revisions.json')) ? read('data/zh_text_revisions.json') : {version:1,revisions:[]};
const canonical = value => Array.isArray(value) ? value.map(canonical) : value && typeof value === 'object' ? Object.fromEntries(Object.keys(value).sort().map(key => [key, canonical(value[key])])) : value;
const protectedFields = structuredClone(source);
delete protectedFields.chapter3KeysBySubtitle;
delete protectedFields.chapter3TheaterDurationMsBySubtitle;
delete protectedFields.chapter3OpeningDurationMsByKey;
for (const line of Object.values(protectedFields.storyLines)) delete line.subtitleZh;
for (const group of Object.values(protectedFields.theaterDialogue)) for (const line of group) delete line.text;
assert.equal(crypto.createHash('sha256').update(JSON.stringify(canonical(protectedFields))).digest('hex'), fixture.protectedSha256,
  'Audio files, assets, English voice, role, event order, durations, offsets and all non-display fields are unchanged');
for (const [text, key] of Object.entries(fixture.chapter3KeysBySubtitle)) assert.equal(source.chapter3KeysBySubtitle[text], key, `Legacy subtitle keeps ${key}`);

// Reconstruct the immutable pre-edit catalog from its protected payload and
// original display strings. This check is independent of a local Git checkout.
const baseline = structuredClone(source);
baseline.chapter3KeysBySubtitle = structuredClone(fixture.chapter3KeysBySubtitle);
baseline.theaterDialogue = structuredClone(fixture.theaterDialogue);
delete baseline.chapter3TheaterDurationMsBySubtitle;
delete baseline.chapter3OpeningDurationMsByKey;
for (const [key, subtitle] of Object.entries(fixture.storyLineSubtitles)) baseline.storyLines[key].subtitleZh = subtitle;
assert.deepEqual(source, applyNativeAudioTextRevisions(baseline, revisions), 'Native export is exactly the authorized display overlay');
let aliases = 0;
for (const revision of [...revisions.revisions, ...(revisions.nativeRevisions ?? [])]) {
  const key = fixture.chapter3KeysBySubtitle[normalizeSubtitle(revision.oldText)];
  if (key) {
    aliases++;
    assert.equal(source.chapter3KeysBySubtitle[normalizeSubtitle(revision.newText)], key, 'New Chinese resolves the same existing voice key');
    assert.equal(source.storyLines[key].voiceAsset, baseline.storyLines[key].voiceAsset, 'New Chinese keeps the existing clip');
  }
  if (revision.sourceFile === 'library-finals.content.json' && revision.path[0] === 'library' && revision.path[1] === 'dialogue022' && revision.path.at(-1) === 'text') {
    const openingKey = `library_story_library_friend_contacted_${String(revision.path[2] + 1).padStart(2, '0')}`;
    assert.equal(source.chapter3OpeningDurationMsByKey[openingKey], Math.max(1200, Math.min(1900, 760 + revision.oldText.length * 48)), 'Opening retains its distinct original UTF-16 beat duration');
  }
  if (revision.sourceFile === 'chapter3-theater.content.json' && revision.oldText !== revision.newText) {
    assert.equal(source.chapter3TheaterDurationMsBySubtitle[normalizeSubtitle(revision.newText)], originalTheaterDuration(revision.oldText), 'Theater runtime receives original text timing');
  }
}

// Deliberately change a line enough to cross timing buckets. The display edit
// must not change any source timer or voice field, even in future revisions.
const first = fixture.theaterDialogue.wrong_order[1];
const second = fixture.theaterDialogue.reversal_before[1];
const edited = `${first.text} 原有录音照常播放，这里只测试更长的中文字幕。`;
const example = {sourceFile:'chapter3-theater.content.json',path:['program','wrongDialogue',1],oldText:first.text,newText:edited,key:first.subtitleKey};
const before = JSON.stringify(baseline);
const result = applyNativeAudioTextRevisions(baseline, {version:1,revisions:[example]});
assert.equal(JSON.stringify(baseline), before, 'Overlay leaves its baseline input untouched');
assert.equal(result.chapter3KeysBySubtitle[normalizeSubtitle(edited)], first.subtitleKey);
assert.equal(result.chapter3KeysBySubtitle[normalizeSubtitle(first.text)], first.subtitleKey);
assert.equal(result.storyLines[first.subtitleKey].voiceTextEn, baseline.storyLines[first.subtitleKey].voiceTextEn);
assert.equal(result.storyLines[first.subtitleKey].voiceAsset, baseline.storyLines[first.subtitleKey].voiceAsset);
assert.equal(result.storyLines[first.subtitleKey].speaker, baseline.storyLines[first.subtitleKey].speaker);
assert.equal(result.storyLines[first.subtitleKey].voiceRole, baseline.storyLines[first.subtitleKey].voiceRole);
assert.deepEqual(result.textDurationMsByKey, baseline.textDurationMsByKey);
assert.deepEqual(result.events, baseline.events);
assert.deepEqual(result.assets, baseline.assets);
assert.deepEqual(result.theaterDialogue.wrong_order[1], {...first,text:edited});
assert.notEqual(originalTheaterDuration(edited), originalTheaterDuration(first.text));
assert.equal(result.chapter3TheaterDurationMsBySubtitle[edited], originalTheaterDuration(first.text));
const silent = fixture.theaterDialogue.reversal_before[0];
const silentResult = applyNativeAudioTextRevisions(baseline, {version:1,revisions:[{...example,key:undefined,oldText:silent.text,newText:'玩家：只是文字。'}]});
assert.equal(silentResult.chapter3KeysBySubtitle['玩家：只是文字。'], undefined, 'A revised silent line stays silent');
assert.equal(silentResult.theaterDialogue.reversal_before[0].subtitleKey, null);
assert.throws(() => applyNativeAudioTextRevisions(baseline, {version:1,revisions:[{...example,newText:second.text}]}), /Conflicting C3 subtitle voice key/, 'Ambiguous aliases fail closed');
assert.throws(() => applyNativeAudioTextRevisions(baseline, {version:1,revisions:[{...example,key:'missing_key'}]}), /Stale native story-line revision/);
assert.throws(() => applyNativeAudioTextRevisions(baseline, {version:1,revisions:[{...example,newText:'旁白：说话人不能改变。'}]}), /cannot change the speaker/);
assert.throws(() => applyNativeAudioTextRevisions(baseline, {version:1,revisions:[example,{...example,newText:'系统：同一行发生冲突。'}]}), /Conflicting catalog subtitle/);
const duplicateBaseline = structuredClone(baseline);
duplicateBaseline.storyLines.duplicate_test = structuredClone(duplicateBaseline.storyLines[first.subtitleKey]);
assert.throws(() => applyNativeAudioTextRevisions(duplicateBaseline, {version:1,revisions:[{...example,key:undefined}]}), /needs a stable key/, 'Ambiguous short text is not broadcast to multiple catalog lines');
const nativeResult = applyNativeAudioTextRevisions(baseline, {version:1,revisions:[],nativeRevisions:[{...example,sourceFile:'chapter4-native-source.json'}]});
assert.equal(nativeResult.storyLines[first.subtitleKey].subtitleZh, edited, 'Native cinematic sources share display-only catalog handling');
console.log(`Native Chinese/audio contract: protected source hash unchanged; ${Object.keys(fixture.chapter3KeysBySubtitle).length} legacy mappings; ${aliases} revised voice references; display-only, silence, collision and frozen-timing checks passed.`);
