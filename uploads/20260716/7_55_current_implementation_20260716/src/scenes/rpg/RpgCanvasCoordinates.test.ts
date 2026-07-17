import { describe, expect, it } from "vitest";
import { clientToRpgCanvasPoint } from "./RpgCanvasCoordinates";

describe("clientToRpgCanvasPoint", () => {
  it("maps a scaled canvas center to the 960x540 logical center", () => {
    expect(clientToRpgCanvasPoint(340, 185, {
      left: 100,
      top: 50,
      width: 480,
      height: 270
    })).toEqual({ x: 480, y: 270 });
  });

  it("rejects pointer releases outside the rendered canvas", () => {
    expect(clientToRpgCanvasPoint(90, 185, {
      left: 100,
      top: 50,
      width: 480,
      height: 270
    })).toBeNull();
  });
});
