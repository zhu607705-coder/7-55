/** Native display-only edits. The source exporter computes audio and timing first. */
const segmenter = new Intl.Segmenter('zh', {granularity: 'grapheme'});
export const normalizeSubtitle = text => text.trim().replace(/\s+/g, ' ');

export function originalTheaterDuration(text) {
  const spoken = text.replace(/^[^：]+：/, '');
  const visible = [...segmenter.segment(spoken)].filter(part => part.segment.trim().length > 0).length;
  return Math.max(2400, Math.min(6500, 1600 + 120 * visible));
}

function setExact(target, name, value, label) {
  if (Object.hasOwn(target, name) && target[name] !== value) {
    throw new Error(`Conflicting ${label}: ${name}`);
  }
  target[name] = value;
}

function preserveSpeaker(oldText, newText) {
  const speaker = oldText.match(/^([^：]+)：/);
  if (speaker && !newText.startsWith(speaker[0])) {
    throw new Error(`A Chinese text revision cannot change the speaker: ${oldText}`);
  }
}

function catalogKeyForPath(sourceFile, path) {
  if (sourceFile === 'library-finals.content.json' && path.at(-1) === 'text') {
    if (path[0] === 'storyDialogues' && path.length === 4 && Number.isInteger(path[2])) {
      return `library_story_${path[1]}_${String(path[2] + 1).padStart(2, '0')}`;
    }
    if (path[0] === 'library' && path[1] === 'dialogue022' && path.length === 4 && Number.isInteger(path[2])) {
      return `library_story_library_friend_contacted_${String(path[2] + 1).padStart(2, '0')}`;
    }
  }
  if (sourceFile === 'act-one-bootstrap.content.json' && path[0] === 'audioNarration' && path.length === 3) return path[1];
  return null;
}

export function applyNativeAudioTextRevisions(original, document) {
  if (document.version !== 1 || !Array.isArray(document.revisions) ||
      (document.nativeRevisions !== undefined && !Array.isArray(document.nativeRevisions))) {
    throw new Error('Unsupported native Chinese text revision document');
  }
  const output = structuredClone(original);
  const catalogChanges = {};
  const theaterChanges = {};
  const theaterDurations = {};
  const openingDurations = {};
  for (const revision of [...document.revisions, ...(document.nativeRevisions ?? [])]) {
    const {sourceFile, path, oldText, newText} = revision;
    if (typeof sourceFile !== 'string' || !Array.isArray(path) ||
        typeof oldText !== 'string' || typeof newText !== 'string' || !newText.trim()) {
      throw new Error('Invalid native Chinese text revision');
    }
    if (oldText === newText) continue;
    const oldNormalized = normalizeSubtitle(oldText);
    const newNormalized = normalizeSubtitle(newText);
    // Both old and new Chinese resolve to the existing stable voice key. Never
    // infer a voice from the speaker prefix or give a silent line a new asset.
    const oldKey = original.chapter3KeysBySubtitle[oldNormalized];
    if (oldKey) {
      preserveSpeaker(oldText, newText);
      setExact(output.chapter3KeysBySubtitle, newNormalized, oldKey, 'C3 subtitle voice key');
    }
    const key = revision.key ?? catalogKeyForPath(sourceFile, path);
    let keys;
    if (key) {
      if (!Object.hasOwn(original.storyLines, key) || original.storyLines[key].subtitleZh !== oldText) {
        throw new Error(`Stale native story-line revision: ${key}`);
      }
      keys = [key];
    } else {
      keys = Object.keys(original.storyLines).filter(id => original.storyLines[id].subtitleZh === oldText);
      if (keys.length > 1) throw new Error(`Ambiguous native story-line revision needs a stable key: ${sourceFile} ${JSON.stringify(path)}`);
    }
    for (const id of keys) setExact(catalogChanges, id, newText, 'catalog subtitle');
    if (sourceFile === 'library-finals.content.json' && path[0] === 'library' && path[1] === 'dialogue022' && path.at(-1) === 'text') {
      setExact(openingDurations, key, Math.max(1200, Math.min(1900, 760 + oldText.length * 48)), '022 opening duration');
    }
    // These queues use the speaker-stripped text length at runtime. Freeze the
    // original duration for revised theater text, including unvoiced lines.
    if (sourceFile === 'chapter3-theater.content.json') {
      preserveSpeaker(oldText, newText);
      setExact(theaterChanges, oldText, newText, 'theater subtitle');
      setExact(theaterDurations, newNormalized, originalTheaterDuration(oldText), 'theater duration');
    }
  }
  for (const [key, text] of Object.entries(catalogChanges)) output.storyLines[key].subtitleZh = text;
  for (const lines of Object.values(output.theaterDialogue)) {
    for (const line of lines) {
      if (Object.hasOwn(theaterChanges, line.text)) line.text = theaterChanges[line.text];
    }
  }
  if (Object.keys(theaterDurations).length) output.chapter3TheaterDurationMsBySubtitle = theaterDurations;
  if (Object.keys(openingDurations).length) output.chapter3OpeningDurationMsByKey = openingDurations;
  return output;
}
