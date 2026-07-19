import Phaser from "phaser";

export interface RpgMovementOptions {
  walkSpeed?: number;
  runSpeed?: number;
  acceleration?: number;
  deceleration?: number;
  pathArriveRadius?: number;
}

interface PathPoint {
  x: number;
  y: number;
}

const SPEED_EPSILON = 1;
const STUCK_WINDOW_MS = 500;
const STUCK_DISTANCE_RATIO = 0.2;

/**
 * Smooths arcade-body velocity for the campus map: split accel/decel,
 * brake-before-reverse turns, and optional waypoint following with
 * displacement-based stuck detection. Scene feeds input via setManualInput
 * and calls update once per frame; the returned vector drives RpgPlayerAnimator.
 */
export class RpgMovementController {
  onPathFinished?: (reason: "arrived" | "cancelled") => void;

  private readonly walkSpeed: number;
  private readonly runSpeed: number;
  private readonly acceleration: number;
  private readonly deceleration: number;
  private readonly pathArriveRadius: number;

  private readonly velocity = new Phaser.Math.Vector2(0, 0);
  private readonly desired = new Phaser.Math.Vector2(0, 0);
  private readonly manualInput = new Phaser.Math.Vector2(0, 0);
  private manualRunning = false;

  private path: PathPoint[] = [];
  private pathIndex = 0;
  private finishingPath = false;

  private stuckElapsedMs = 0;
  private stuckExpected = 0;
  private stuckDistance = 0;
  private lastBodyX = 0;
  private lastBodyY = 0;

  constructor(
    private readonly player: Phaser.Physics.Arcade.Sprite,
    options: RpgMovementOptions = {}
  ) {
    this.walkSpeed = options.walkSpeed ?? 220;
    this.runSpeed = options.runSpeed ?? 320;
    this.acceleration = options.acceleration ?? 1500;
    this.deceleration = options.deceleration ?? 2000;
    this.pathArriveRadius = options.pathArriveRadius ?? 12;
    this.lastBodyX = player.body?.position.x ?? player.x;
    this.lastBodyY = player.body?.position.y ?? player.y;
  }

  get followingPath(): boolean {
    return this.path.length > 0;
  }

  setManualInput(x: number, y: number, running: boolean): void {
    this.manualInput.set(x, y);
    this.manualRunning = running;
    if ((x !== 0 || y !== 0) && this.followingPath) {
      this.cancelPath();
    }
  }

  setPath(points: { x: number; y: number }[] | null): void {
    if (!points || points.length === 0) {
      this.clearPath();
      return;
    }
    this.path = points.map((point) => ({ x: point.x, y: point.y }));
    this.pathIndex = 0;
    this.finishingPath = false;
    this.resetStuckTracking();
  }

  clearPath(): void {
    this.path = [];
    this.pathIndex = 0;
    this.finishingPath = false;
    this.resetStuckTracking();
  }

  update(deltaMs: number): Phaser.Math.Vector2 {
    const dt = Math.max(0, deltaMs) / 1000;
    if (dt === 0) {
      return this.velocity;
    }

    this.computeDesired();
    this.applySmoothing(dt);
    this.player.setVelocity(this.velocity.x, this.velocity.y);
    this.trackStuck(dt);
    return this.velocity;
  }

  private computeDesired(): void {
    this.desired.set(0, 0);

    if (this.manualInput.x !== 0 || this.manualInput.y !== 0) {
      const speed = this.manualRunning ? this.runSpeed : this.walkSpeed;
      this.desired.copy(this.manualInput).normalize().scale(speed);
      return;
    }

    if (!this.followingPath) {
      return;
    }

    const target = this.path[this.pathIndex];
    const dx = target.x - this.player.x;
    const dy = target.y - this.player.y;
    const distance = Math.hypot(dx, dy);

    if (distance <= this.pathArriveRadius) {
      if (this.pathIndex < this.path.length - 1) {
        this.pathIndex += 1;
        this.computeDesired();
        return;
      }
      this.finishingPath = true;
      return;
    }

    this.desired.set(dx / distance, dy / distance).scale(this.walkSpeed);
  }

  private applySmoothing(dt: number): void {
    const vel = this.velocity;
    const desiredSpeed = this.desired.length();
    let remaining = dt;

    if (desiredSpeed > 0) {
      const speed = vel.length();
      const reversing = speed > SPEED_EPSILON
        && vel.x * this.desired.x + vel.y * this.desired.y < 0;
      if (reversing) {
        const brakeTime = Math.min(speed / this.deceleration, remaining);
        vel.setLength(Math.max(0, speed - this.deceleration * brakeTime));
        remaining -= brakeTime;
      }
    }

    if (remaining <= 0) {
      return;
    }

    const currentSpeed = vel.length();
    const rate = desiredSpeed === 0 || currentSpeed > desiredSpeed
      ? this.deceleration
      : this.acceleration;
    const maxDelta = rate * remaining;
    const deltaX = this.desired.x - vel.x;
    const deltaY = this.desired.y - vel.y;
    const deltaLength = Math.hypot(deltaX, deltaY);
    if (deltaLength <= maxDelta) {
      vel.copy(this.desired);
    } else {
      vel.x += (deltaX / deltaLength) * maxDelta;
      vel.y += (deltaY / deltaLength) * maxDelta;
    }

    if (this.finishingPath && vel.length() <= SPEED_EPSILON) {
      vel.set(0, 0);
      this.clearPath();
      this.onPathFinished?.("arrived");
    }
  }

  private trackStuck(dt: number): void {
    const bodyX = this.player.body?.position.x ?? this.player.x;
    const bodyY = this.player.body?.position.y ?? this.player.y;
    const moved = Math.hypot(bodyX - this.lastBodyX, bodyY - this.lastBodyY);
    this.lastBodyX = bodyX;
    this.lastBodyY = bodyY;

    if (!this.followingPath || this.finishingPath) {
      this.resetStuckTracking();
      return;
    }

    this.stuckElapsedMs += dt * 1000;
    this.stuckDistance += moved;
    this.stuckExpected += this.desired.length() * dt;

    if (this.stuckElapsedMs < STUCK_WINDOW_MS) {
      return;
    }
    if (this.stuckExpected > 1 && this.stuckDistance < this.stuckExpected * STUCK_DISTANCE_RATIO) {
      this.cancelPath();
      return;
    }
    this.resetStuckTracking();
  }

  private cancelPath(): void {
    this.clearPath();
    this.onPathFinished?.("cancelled");
  }

  private resetStuckTracking(): void {
    this.stuckElapsedMs = 0;
    this.stuckExpected = 0;
    this.stuckDistance = 0;
  }
}
