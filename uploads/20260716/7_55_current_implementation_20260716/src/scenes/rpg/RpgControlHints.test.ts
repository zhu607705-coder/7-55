import { describe, expect, it } from "vitest";
import { formatRpgInteractionHint, RPG_CONTROL_HINTS } from "./RpgControlHints";

describe("RPG control hints", () => {
  it("matches the actual WASD movement and Space interaction bindings", () => {
    expect(RPG_CONTROL_HINTS.libraryGate).toBe("WASD 移动 · 空格键进入");
    expect(RPG_CONTROL_HINTS.continueDialogue).toBe("空格键继续");
    expect(RPG_CONTROL_HINTS.touchInteraction).toBe("空格");
  });

  it("formats contextual interactions with the Space key", () => {
    expect(formatRpgInteractionHint("检查占座书包")).toBe("空格键  检查占座书包");
  });

  it("does not advertise A as an interaction key", () => {
    expect(Object.values(RPG_CONTROL_HINTS).join(" ")).not.toMatch(/A\s*(进入|继续|交互)/);
  });
});
