export type MotionFallbackMode = "mouse_drag_circle" | "long_press_3s";

export class MotionController {
  private angle = 0;
  private targetId: string | null = null;
  private fallbackMode: MotionFallbackMode = "mouse_drag_circle";

  startListen(targetId: string): void {
    this.targetId = targetId;
    this.angle = 0;
  }

  addClockwiseAngle(deltaDeg: number): void {
    this.angle += Math.max(0, deltaDeg);
  }

  getClockwiseAngle(): number {
    return this.angle;
  }

  isThresholdReached(thresholdDeg = 360): boolean {
    return this.angle >= thresholdDeg;
  }

  enableFallback(mode: MotionFallbackMode): void {
    this.fallbackMode = mode;
  }

  getFallbackMode(): MotionFallbackMode {
    return this.fallbackMode;
  }

  getTargetId(): string | null {
    return this.targetId;
  }
}
