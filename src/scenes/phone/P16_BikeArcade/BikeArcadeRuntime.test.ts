import { describe, expect, it } from "vitest";
import {
  BikeArcadeLifecycle,
  resolveBikeArcadeReducedMotion
} from "./BikeArcadeRuntime";

describe("BikeArcadeLifecycle", () => {
  it("freezes hidden frames and discards the first frame after resuming", () => {
    const lifecycle = new BikeArcadeLifecycle();

    expect(lifecycle.consumeFrame(16)).toEqual({ deltaMs: 16, paused: false, resumed: false });
    expect(lifecycle.setPauseReason("document-hidden", true)).toBe("paused");
    expect(lifecycle.consumeFrame(5_000)).toEqual({ deltaMs: 0, paused: true, resumed: false });
    expect(lifecycle.setPauseReason("document-hidden", false)).toBe("resume-pending");
    expect(lifecycle.consumeFrame(5_000)).toEqual({ deltaMs: 0, paused: false, resumed: true });
    expect(lifecycle.consumeFrame(16)).toEqual({ deltaMs: 16, paused: false, resumed: false });
  });

  it("waits for hidden and blur reasons to clear before resuming", () => {
    const lifecycle = new BikeArcadeLifecycle();

    expect(lifecycle.setPauseReason("document-hidden", true)).toBe("paused");
    expect(lifecycle.setPauseReason("window-blur", true)).toBe("unchanged");
    expect(lifecycle.setPauseReason("document-hidden", false)).toBe("unchanged");
    expect(lifecycle.consumeFrame(16)).toEqual({ deltaMs: 0, paused: true, resumed: false });
    expect(lifecycle.setPauseReason("window-blur", false)).toBe("resume-pending");
    expect(lifecycle.consumeFrame(2_000)).toEqual({ deltaMs: 0, paused: false, resumed: true });
  });

  it("clamps an active long frame without changing ordinary frame timing", () => {
    const lifecycle = new BikeArcadeLifecycle(100);

    expect(lifecycle.consumeFrame(5_000).deltaMs).toBe(100);
    expect(lifecycle.consumeFrame(-10).deltaMs).toBe(0);
    expect(lifecycle.consumeFrame(24).deltaMs).toBe(24);
  });
});

describe("resolveBikeArcadeReducedMotion", () => {
  it("lets an explicit bridge flag override the media preference", () => {
    expect(resolveBikeArcadeReducedMotion(true, false)).toBe(true);
    expect(resolveBikeArcadeReducedMotion(false, true)).toBe(false);
    expect(resolveBikeArcadeReducedMotion(undefined, true)).toBe(true);
    expect(resolveBikeArcadeReducedMotion(undefined, false)).toBe(false);
  });
});
