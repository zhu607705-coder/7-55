import { describe, expect, it } from "vitest";
import { DialogueManager, type DialogueLine } from "./DialogueManager";

const lines: DialogueLine[] = [
  {
    line_id: "XY_P14_HIDE_CODE_001",
    speaker: "xiaoying",
    subtitle_zh: "小影：签到码已为你安全隐藏。",
    trigger_scene: "wechat",
    trigger_event: "code_scattered"
  }
];

describe("DialogueManager", () => {
  it("finds lines by scene and event and prevents replay by default", () => {
    const manager = new DialogueManager(lines);
    const [line] = manager.findLines("wechat", "code_scattered");

    expect(line.line_id).toBe("XY_P14_HIDE_CODE_001");
    expect(manager.canPlay(line)).toBe(true);

    manager.markPlayed(line.line_id);

    expect(manager.canPlay(line)).toBe(false);
  });
});
