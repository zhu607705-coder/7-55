import type { StoryLine } from "../core/types";
import chapterFourPrologueVoiceData from "./chapter4-prologue-voice.audio.content.json";

interface ChapterFourPrologueStoryDefinition {
  key: string;
  speaker: "player" | "narrator" | "cleaner" | "guard";
  voiceRole: "male_narrator" | "male_player" | "female_cleaner" | "male_guard";
  subtitleZh: string;
  voiceTextEn: string;
}

const definitions = chapterFourPrologueVoiceData.lines as ChapterFourPrologueStoryDefinition[];

const storyLinesByKey = new Map<string, StoryLine>();
const keysBySubtitle = new Map<string, string>();

for (const definition of definitions) {
  storyLinesByKey.set(definition.key, {
    kind: "dialogue",
    speaker: definition.speaker,
    voiceRole: definition.voiceRole,
    voiceTextEn: definition.voiceTextEn,
    voiceAsset: `vo_${definition.key}`,
    subtitleZh: definition.subtitleZh
  });
  keysBySubtitle.set(normalizeSubtitle(definition.subtitleZh), definition.key);
}

export const CHAPTER_FOUR_PROLOGUE_STORY_LINES: ReadonlyMap<string, StoryLine> = storyLinesByKey;

export function chapterFourPrologueStoryLineKeyForSubtitle(text: string): string | null {
  return keysBySubtitle.get(normalizeSubtitle(text)) ?? null;
}

function normalizeSubtitle(text: string): string {
  return text.trim().replace(/\s+/g, " ");
}
