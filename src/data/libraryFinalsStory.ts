import libraryFinalsContent from "./library-finals.content.json";

export interface LibraryStoryLine {
  speaker: string;
  text: string;
}

const final022Dialogue: LibraryStoryLine[] = libraryFinalsContent.library.dialogue022.map((line) => ({
  speaker: line.speaker,
  text: line.text
}));

const authoredStoryDialogues: Record<string, LibraryStoryLine[]> = Object.fromEntries(
  Object.entries(libraryFinalsContent.storyDialogues).map(([sequenceId, sequence]) => [
    sequenceId,
    sequence.map((line) => ({
      speaker: line.speaker,
      text: line.text
    }))
  ])
);

export const LIBRARY_STORY_SEQUENCES: Readonly<Record<string, readonly LibraryStoryLine[]>> = Object.freeze({
  ...authoredStoryDialogues,
  library_friend_contacted: final022Dialogue
});

export function libraryStoryLineKey(sequenceId: string, index: number): string {
  return `library_story_${sequenceId}_${String(index + 1).padStart(2, "0")}`;
}
