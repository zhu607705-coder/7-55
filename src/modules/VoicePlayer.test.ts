import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { eventBus } from "../core/EventBus";
import voMap from "../data/vo.map.json";
import { textFeedbackDuration } from "./AudioDirector";
import { playVo, voiceRoleForVoKey } from "./VoicePlayer";

describe("VoicePlayer subtitle contract", () => {
  beforeEach(() => {
    eventBus.clearHistory();
    vi.stubGlobal("Audio", undefined);
  });

  afterEach(() => {
    vi.useRealTimers();
    eventBus.clearHistory();
    vi.unstubAllGlobals();
  });

  it("shows the mapped Chinese subtitle by default", () => {
    playVo("wake_narration");

    expect(eventBus.getHistory()).toContainEqual({
      name: "toast",
      payload: {
        text: voMap.lines.wake_narration,
        tone: "system",
        durationMs: 3200
      }
    });
    expect(voMap.lines.wake_narration).toMatch(/[\u3400-\u9fff]/u);
  });

  it("assigns the legacy story dialogue to the correct voice roles", () => {
    expect(voiceRoleForVoKey("wake_narration")).toBe("male_narrator");
    expect(voiceRoleForVoKey("wake_flash")).toBe("female_system");
    expect(voiceRoleForVoKey("xy_attack")).toBe("female_system");
    expect(voiceRoleForVoKey("xy_laugh")).toBe("female_system");
  });

  it("renders operation taunts as text without assigning a voice role", () => {
    playVo("sys_balance");

    expect(voiceRoleForVoKey("sys_balance")).toBeNull();
    expect(eventBus.getHistory()).toContainEqual({
      name: "toast",
      payload: {
        text: voMap.lines.sys_balance,
        tone: "xiaoying",
        durationMs: textFeedbackDuration(voMap.lines.sys_balance)
      }
    });
  });

  it("lets a voiced line be skipped once without firing its completion twice", () => {
    vi.useFakeTimers();
    const onEnded = vi.fn();
    const playback = playVo("xy_attack", { subtitle: false, onEnded });

    vi.advanceTimersByTime(2000);
    expect(onEnded).not.toHaveBeenCalled();

    playback.skip();
    expect(onEnded).toHaveBeenCalledTimes(1);
    vi.runAllTimers();
    expect(onEnded).toHaveBeenCalledTimes(1);
  });
});
