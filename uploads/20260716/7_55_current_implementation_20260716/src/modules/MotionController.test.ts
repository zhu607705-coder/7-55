import { describe, expect, it } from "vitest";
import { MotionController } from "./MotionController";

describe("MotionController", () => {
  it("tracks clockwise rotation and fallback mode", () => {
    const motion = new MotionController();

    motion.startListen("settings_gear");
    motion.enableFallback("long_press_3s");
    motion.addClockwiseAngle(180);
    motion.addClockwiseAngle(180);

    expect(motion.getTargetId()).toBe("settings_gear");
    expect(motion.getFallbackMode()).toBe("long_press_3s");
    expect(motion.isThresholdReached()).toBe(true);
  });
});
