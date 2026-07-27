import type { StoryLine } from "../core/types";
import chapterThreeStoryData from "./chapter3-story-lines.json";

interface ChapterThreeStoryDefinition {
  key: string;
  speaker: "narrator" | "system";
  voiceRole: "male_narrator" | "female_system";
  subtitleZh: string;
  voiceTextEn: string;
  speed: number;
  pitch: number;
}

export const CHAPTER_THREE_STORY_DEFINITIONS = Object.freeze(
  chapterThreeStoryData.lines as ChapterThreeStoryDefinition[]
);

const storyLinesByKey = new Map<string, StoryLine>();
const keysBySubtitle = new Map<string, string>();

for (const definition of CHAPTER_THREE_STORY_DEFINITIONS) {
  const voiceAsset = `vo_${definition.key}`;
  storyLinesByKey.set(definition.key, {
    kind: "dialogue",
    speaker: definition.speaker,
    voiceRole: definition.voiceRole,
    voiceTextEn: definition.voiceTextEn,
    voiceAsset,
    subtitleZh: definition.subtitleZh
  });
  keysBySubtitle.set(normalizeChapterThreeSubtitle(definition.subtitleZh), definition.key);
}

export const CHAPTER_THREE_STORY_LINES: ReadonlyMap<string, StoryLine> = storyLinesByKey;

export function chapterThreeStoryLineKeyForSubtitle(text: string): string | null {
  return keysBySubtitle.get(normalizeChapterThreeSubtitle(text)) ?? null;
}

function normalizeChapterThreeSubtitle(text: string): string {
  return text.trim().replace(/\s+/g, " ");
}
