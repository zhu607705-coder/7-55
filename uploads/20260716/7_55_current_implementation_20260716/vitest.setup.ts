import "@testing-library/jest-dom/vitest";
import { vi } from "vitest";

if (typeof HTMLMediaElement !== "undefined") {
  Object.defineProperties(HTMLMediaElement.prototype, {
    play: {
      configurable: true,
      value: vi.fn().mockResolvedValue(undefined)
    },
    pause: {
      configurable: true,
      value: vi.fn()
    },
    load: {
      configurable: true,
      value: vi.fn()
    }
  });
}
