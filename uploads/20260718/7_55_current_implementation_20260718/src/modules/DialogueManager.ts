import type { SceneId } from "../core/types";

export interface DialogueLine {
  line_id: string;
  speaker: "narrator" | "xiaoying" | "friend" | "system";
  voice_en?: string;
  subtitle_zh: string;
  audio_file?: string;
  trigger_scene: SceneId;
  trigger_event: string;
  replayable?: boolean;
}

export class DialogueManager {
  private readonly played = new Set<string>();

  constructor(private readonly lines: DialogueLine[]) {}

  findLines(sceneId: SceneId, eventName: string): DialogueLine[] {
    return this.lines.filter((line) => line.trigger_scene === sceneId && line.trigger_event === eventName);
  }

  markPlayed(lineId: string): void {
    this.played.add(lineId);
  }

  canPlay(line: DialogueLine): boolean {
    return Boolean(line.replayable) || !this.played.has(line.line_id);
  }
}
