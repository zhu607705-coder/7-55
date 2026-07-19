import type { StoryLine } from "../core/types";
import actOneContent from "./act-one-bootstrap.content.json";
import bikeContent from "./bike-arcade.content.json";
import legacyDialogue from "./dialogue.lines.json";
import { LIBRARY_STORY_SEQUENCES, libraryStoryLineKey } from "./libraryFinalsStory";

const MALE_DIALOGUE_KEYS = new Set([
  "wake_narration",
  "prologue_narrator_intro",
  "prologue_narrator_caught",
  "prologue_narrator_bargain"
]);

const FEMALE_DIALOGUE_KEYS = new Set([
  "wake_flash",
  "xy_attack",
  "xy_laugh",
  "act2_system_found_intro",
  "act2_system_inventory_demand",
  "act2_system_inventory_missing",
  "act2_system_just_find_it",
  "act2_system_departure",
  "act2_system_confession",
  "act2_system_friend",
  "act2_system_library",
  "act2_system_move_now"
]);

const LEGACY_TAUNT_KEYS = new Set([
  "sys_balance",
  "sys_net_try",
  "sys_no_money",
  "tiyi_47",
  "gear_pickup"
]);

function dialogueLine(
  key: string,
  voiceTextEn: string | undefined,
  subtitleZh: string
): StoryLine {
  const male = MALE_DIALOGUE_KEYS.has(key);
  return {
    kind: "dialogue",
    speaker: male ? "narrator" : "system",
    voiceRole: male ? "male_narrator" : "female_system",
    voiceTextEn,
    subtitleZh
  };
}

function textLine(kind: "taunt" | "task", subtitleZh: string): StoryLine {
  return { kind, speaker: "system", subtitleZh };
}

function libraryDialogueLine(speakerLabel: string, subtitleZh: string): StoryLine {
  const speaker = speakerLabel === "旁白"
    ? "narrator"
    : speakerLabel === "玩家"
      ? "player"
      : speakerLabel === "022"
        ? "seat022"
        : "system";
  return {
    kind: "dialogue",
    speaker,
    voiceRole: speaker === "narrator" || speaker === "player" ? "male_narrator" : "female_system",
    subtitleZh
  };
}

const lines: Record<string, StoryLine> = {};

for (const line of legacyDialogue) {
  lines[line.voice_key] = MALE_DIALOGUE_KEYS.has(line.voice_key) || FEMALE_DIALOGUE_KEYS.has(line.voice_key)
    ? dialogueLine(line.voice_key, line.voice_text_en, line.subtitle_zh)
    : textLine(LEGACY_TAUNT_KEYS.has(line.voice_key) ? "taunt" : "task", line.subtitle_zh);
}

for (const [key, line] of Object.entries(actOneContent.audioNarration)) {
  const subtitleZh = line.subtitleZh ?? line.text;
  lines[key] = MALE_DIALOGUE_KEYS.has(key) || FEMALE_DIALOGUE_KEYS.has(key)
    ? dialogueLine(key, line.text, subtitleZh)
    : textLine(line.tone === "task" ? "task" : "taunt", subtitleZh);
}

for (const [sequenceId, sequence] of Object.entries(LIBRARY_STORY_SEQUENCES)) {
  sequence.forEach((line, index) => {
    lines[libraryStoryLineKey(sequenceId, index)] = libraryDialogueLine(line.speaker, line.text);
  });
}

for (const [key, subtitleZh] of Object.entries(bikeContent.subtitles)) {
  lines[key] = textLine("taunt", subtitleZh);
}

export const STORY_LINE_CATALOG: Readonly<Record<string, StoryLine>> = Object.freeze(lines);

export function storyLineForKey(key: string | undefined): StoryLine | null {
  return key ? STORY_LINE_CATALOG[key] ?? null : null;
}

export function isVoicedDialogue(line: StoryLine | null): line is StoryLine & Required<Pick<StoryLine, "voiceRole">> {
  return line?.kind === "dialogue" && line.voiceRole !== undefined;
}
