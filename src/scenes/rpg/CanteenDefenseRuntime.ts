import Phaser from "phaser";
import { CANTEEN_INTERIOR_WORLD } from "./CanteenInteriorModel";
import { getRpgLogicalCameraZoom } from "./RpgRenderResolution";

const PUSH_CART_SHEET_KEY = "chapter-3-canteen-player-push-cart";
const PAPER_IDLE_KEY = "chapter-3-canteen-paper";
const PAPER_RUN_KEYS = [
  "chapter-3-canteen-paper-run-0",
  "chapter-3-canteen-paper-run-1",
  "chapter-3-canteen-paper-run-2",
  "chapter-3-canteen-paper-run-3"
] as const;
const DEFENSE_DURATION_MS = 60_000;
const PLAYER_SPEED = 154;
const DASH_SPEED = 264;
const DASH_DURATION_MS = 430;
const DASH_COOLDOWN_MS = 1_650;
const PAPER_START_SPEED = 78;
const PAPER_MAX_SPEED = 118;
const PAPER_EXIT_RADIUS = 24;
const PAPER_HIT_COOLDOWN_MS = 720;
const PUSH_CART_DISPLAY_SCALE = 0.3;
const PLAYER_WORLD_DEPTH_OFFSET = 120;

export type CanteenDefenseExitId = "northwest" | "south_gap" | "southeast";

export interface CanteenDefenseCallbacks {
  onComplete: () => void;
  onFailure: (exitId: CanteenDefenseExitId) => void;
  onTurnaround: (
    exitId: CanteenDefenseExitId,
    route: readonly Phaser.Math.Vector2[]
  ) => void;
}

interface NavNode {
  id: string;
  point: Phaser.Math.Vector2;
  links: string[];
}

const GRID_X = [126, 301, 450, 600, 753, 908, 1064, 1225] as const;
const GRID_Y = [278, 414, 520, 628] as const;
const PLAYER_START = new Phaser.Math.Vector2(908, 628);
const PAPER_START = new Phaser.Math.Vector2(836, 520);
const EXIT_POINTS: Readonly<Record<CanteenDefenseExitId, Phaser.Math.Vector2>> = {
  northwest: new Phaser.Math.Vector2(82, 250),
  south_gap: new Phaser.Math.Vector2(500, 914),
  southeast: new Phaser.Math.Vector2(1380, 852)
};
const EXIT_GATEWAYS: Readonly<Record<CanteenDefenseExitId, readonly Phaser.Math.Vector2[]>> = {
  northwest: [
    new Phaser.Math.Vector2(126, 278),
    EXIT_POINTS.northwest
  ],
  south_gap: [
    new Phaser.Math.Vector2(450, 628),
    new Phaser.Math.Vector2(500, 650),
    EXIT_POINTS.south_gap
  ],
  southeast: [
    new Phaser.Math.Vector2(1225, 628),
    new Phaser.Math.Vector2(1225, 820),
    new Phaser.Math.Vector2(1380, 820),
    EXIT_POINTS.southeast
  ]
};

function buildNavigationGraph(): Map<string, NavNode> {
  const graph = new Map<string, NavNode>();
  GRID_Y.forEach((y, row) => {
    GRID_X.forEach((x, column) => {
      const id = `${column}:${row}`;
      graph.set(id, {
        id,
        point: new Phaser.Math.Vector2(x, y),
        links: []
      });
    });
  });
  GRID_Y.forEach((_y, row) => {
    GRID_X.forEach((_x, column) => {
      const node = graph.get(`${column}:${row}`)!;
      const candidates = [
        `${column - 1}:${row}`,
        `${column + 1}:${row}`,
        `${column}:${row - 1}`,
        `${column}:${row + 1}`
      ];
      node.links.push(...candidates.filter((id) => graph.has(id)));
    });
  });
  return graph;
}

export class CanteenDefenseRuntime {
  private readonly pushSprite: Phaser.GameObjects.Sprite;
  private readonly timerText: Phaser.GameObjects.Text;
  private readonly dashText: Phaser.GameObjects.Text;
  private readonly graph = buildNavigationGraph();
  private readonly route: Phaser.Math.Vector2[] = [];
  private facing = new Phaser.Math.Vector2(0, -1);
  private currentExit: CanteenDefenseExitId = "northwest";
  private elapsedMs = 0;
  private dashRemainingMs = 0;
  private dashCooldownMs = 0;
  private paperHitCooldownMs = 0;
  private paperFrameElapsedMs = 0;
  private paperFrameIndex = 0;
  private pushFrameElapsedMs = 0;
  private pushFrameIndex = 0;
  private routeIndex = 0;
  private paused = false;
  private completed = false;
  private destroyed = false;
  private readonly attemptStartElapsedMs: number;

  constructor(
    private readonly scene: Phaser.Scene,
    private readonly player: Phaser.Physics.Arcade.Sprite,
    private readonly paper: Phaser.GameObjects.Image,
    private readonly callbacks: CanteenDefenseCallbacks,
    startElapsedMs = 0
  ) {
    this.attemptStartElapsedMs = Phaser.Math.Clamp(startElapsedMs, 0, DEFENSE_DURATION_MS - 10_000);
    this.scene.textures.get(PUSH_CART_SHEET_KEY).setFilter(Phaser.Textures.FilterMode.NEAREST);
    this.player.setVisible(false);
    this.pushSprite = scene.add.sprite(PLAYER_START.x, PLAYER_START.y, PUSH_CART_SHEET_KEY, 8)
      .setScale(PUSH_CART_DISPLAY_SCALE)
      .setOrigin(0.5, 0.74)
      .setDepth(this.playerWorldDepth());
    this.timerText = scene.add.text(0, 0, "", {
      color: "#fff7df",
      backgroundColor: "#10171ddd",
      fontFamily: "monospace",
      fontSize: "20px",
      fontStyle: "bold",
      padding: { x: 10, y: 5 }
    }).setOrigin(0.5, 0).setDepth(6200);
    this.dashText = scene.add.text(0, 0, "", {
      color: "#d8e0e4",
      backgroundColor: "#10171dcc",
      fontFamily: "monospace",
      fontSize: "13px",
      padding: { x: 8, y: 4 }
    }).setOrigin(0.5, 1).setDepth(6200);
    this.layoutHud();
    this.restartAttempt();
  }

  get active(): boolean {
    return !this.paused && !this.completed;
  }

  update(
    deltaMs: number,
    inputDirection: Phaser.Math.Vector2,
    dashRequested: boolean
  ): Phaser.Math.Vector2 {
    if (this.paused || this.completed) {
      this.player.setVelocity(0, 0);
      return new Phaser.Math.Vector2();
    }

    this.elapsedMs = Math.min(DEFENSE_DURATION_MS, this.elapsedMs + deltaMs);
    this.dashRemainingMs = Math.max(0, this.dashRemainingMs - deltaMs);
    this.dashCooldownMs = Math.max(0, this.dashCooldownMs - deltaMs);
    this.paperHitCooldownMs = Math.max(0, this.paperHitCooldownMs - deltaMs);
    if (dashRequested && this.dashCooldownMs <= 0 && inputDirection.lengthSq() > 0) {
      this.dashRemainingMs = DASH_DURATION_MS;
      this.dashCooldownMs = DASH_COOLDOWN_MS;
    }

    const movement = inputDirection.clone();
    if (movement.lengthSq() > 0) {
      movement.normalize();
      this.facing.copy(movement);
      movement.scale(this.dashRemainingMs > 0 ? DASH_SPEED : PLAYER_SPEED);
    }
    this.player.setVelocity(movement.x, movement.y)
      .setDepth(this.playerWorldDepth());
    this.updatePushSprite(deltaMs, movement.lengthSq() > 0);
    this.updatePaper(deltaMs);
    this.updateHud();

    if (this.elapsedMs >= DEFENSE_DURATION_MS) {
      this.completed = true;
      this.player.setVelocity(0, 0);
      this.callbacks.onComplete();
    }
    return movement;
  }

  pauseAfterFailure(): void {
    this.paused = true;
    this.player.setVelocity(0, 0);
    this.timerText.setText("纸条已离开 · 重新拦截");
    this.dashText.setText("准备重新开始");
  }

  restartAttempt(): void {
    this.paused = false;
    this.completed = false;
    this.elapsedMs = this.attemptStartElapsedMs;
    this.dashRemainingMs = 0;
    this.dashCooldownMs = 0;
    this.paperHitCooldownMs = 500;
    this.paperFrameElapsedMs = 0;
    this.paperFrameIndex = 0;
    this.pushFrameElapsedMs = 0;
    this.pushFrameIndex = 0;
    this.facing.set(0, -1);
    this.player.setPosition(PLAYER_START.x, PLAYER_START.y).setVelocity(0, 0).setVisible(false);
    this.paper
      .setTexture(PAPER_RUN_KEYS[0])
      .setPosition(PAPER_START.x, PAPER_START.y)
      .setFlipX(false)
      .setAngle(0)
      .setScale(1.16)
      .setDepth(2100)
      .setAlpha(1)
      .setVisible(true);
    this.currentExit = this.pickNextExit();
    this.rebuildRoute(this.currentExit);
    this.updatePushSprite(0, false);
    this.updateHud();
  }

  destroy(): void {
    if (this.destroyed) return;
    this.destroyed = true;
    // Phaser releases Arcade bodies before all scene shutdown listeners have
    // necessarily run. Avoid Sprite.setVelocity(), which dereferences a body
    // that may already be gone during a DEV scene switch.
    const playerBody = this.player.body as Phaser.Physics.Arcade.Body | null | undefined;
    playerBody?.setVelocity(0, 0);
    if (this.player.active) this.player.setVisible(true);
    if (this.paper.active) this.paper.setTexture(PAPER_IDLE_KEY).setFlipX(false).setAngle(0).setScale(1);
    if (this.pushSprite.active) this.pushSprite.destroy();
    if (this.timerText.active) this.timerText.destroy();
    if (this.dashText.active) this.dashText.destroy();
  }

  getDebugSnapshot(): {
    startElapsedMs: number;
    elapsedMs: number;
    remainingMs: number;
    currentExit: CanteenDefenseExitId;
    paused: boolean;
  } {
    return {
      startElapsedMs: this.attemptStartElapsedMs,
      elapsedMs: Math.round(this.elapsedMs),
      remainingMs: Math.max(0, Math.round(DEFENSE_DURATION_MS - this.elapsedMs)),
      currentExit: this.currentExit,
      paused: this.paused
    };
  }

  private updatePushSprite(deltaMs: number, moving: boolean): void {
    if (moving) {
      this.pushFrameElapsedMs += deltaMs;
      const frameDuration = this.dashRemainingMs > 0 ? 72 : 104;
      if (this.pushFrameElapsedMs >= frameDuration) {
        this.pushFrameElapsedMs %= frameDuration;
        this.pushFrameIndex = (this.pushFrameIndex + 1) % 4;
      }
    } else {
      this.pushFrameElapsedMs = 0;
      this.pushFrameIndex = 0;
    }

    let row = 2;
    let originX = 0.5;
    let originY = 0.27;
    if (Math.abs(this.facing.x) > Math.abs(this.facing.y)) {
      if (this.facing.x < 0) {
        row = 1;
        originX = 0.63;
        originY = 0.32;
      } else {
        row = 3;
        originX = 0.39;
        originY = 0.32;
      }
    } else if (this.facing.y > 0) {
      row = 0;
      originY = 0.26;
    }
    this.pushSprite
      .setFrame(row * 4 + this.pushFrameIndex)
      .setOrigin(originX, originY)
      .setPosition(this.player.x, this.player.y)
      .setDepth(this.playerWorldDepth());
  }

  private playerWorldDepth(): number {
    const body = this.player.body as Phaser.Physics.Arcade.Body | null;
    return (body?.bottom ?? this.player.y) + PLAYER_WORLD_DEPTH_OFFSET;
  }

  private updatePaper(deltaMs: number): void {
    const target = this.route[this.routeIndex];
    if (!target) {
      this.failCurrentExit();
      return;
    }
    const toTarget = target.clone().subtract(new Phaser.Math.Vector2(this.paper.x, this.paper.y));
    const distance = toTarget.length();
    const progress = this.elapsedMs / DEFENSE_DURATION_MS;
    const speed = Phaser.Math.Linear(PAPER_START_SPEED, PAPER_MAX_SPEED, progress);
    this.paperFrameElapsedMs += deltaMs;
    const frameDurationMs = Phaser.Math.Linear(112, 82, progress);
    if (this.paperFrameElapsedMs >= frameDurationMs) {
      this.paperFrameElapsedMs %= frameDurationMs;
      this.paperFrameIndex = (this.paperFrameIndex + 1) % PAPER_RUN_KEYS.length;
      this.paper.setTexture(PAPER_RUN_KEYS[this.paperFrameIndex]);
    }
    const step = speed * deltaMs / 1000;
    if (distance <= step) {
      this.paper.setPosition(target.x, target.y);
      this.routeIndex += 1;
    } else if (distance > 0) {
      toTarget.scale(step / distance);
      this.paper.setPosition(this.paper.x + toTarget.x, this.paper.y + toTarget.y);
      this.paper
        .setFlipX(toTarget.x < 0)
        .setAngle(step > 0 ? Phaser.Math.Clamp(toTarget.y / step * 9, -9, 9) : 0);
    }
    // The table-front crops sort against the hidden physics actor, so a normal
    // Y-sorted paper can disappear beneath unrelated chairs. Keep the target
    // above scenery and the automatic dark-mode flash throughout this chase.
    this.paper.setDepth(2100);

    const playerBody = this.player.body as Phaser.Physics.Arcade.Body | null;
    const paperBounds = this.paper.getBounds();
    const playerBounds = playerBody
      ? {
          left: playerBody.x,
          top: playerBody.y,
          right: playerBody.x + playerBody.width,
          bottom: playerBody.y + playerBody.height
        }
      : {
          left: this.player.x - 7,
          top: this.player.y - 6,
          right: this.player.x + 7,
          bottom: this.player.y + 6
        };
    const paperTouchesPlayer = (
      paperBounds.right >= playerBounds.left
      && paperBounds.left <= playerBounds.right
      && paperBounds.bottom >= playerBounds.top
      && paperBounds.top <= playerBounds.bottom
    );
    if (paperTouchesPlayer && this.paperHitCooldownMs <= 0) {
      this.paperHitCooldownMs = PAPER_HIT_COOLDOWN_MS;
      const away = new Phaser.Math.Vector2(
        this.paper.x - (playerBounds.left + playerBounds.right) / 2,
        this.paper.y - (playerBounds.top + playerBounds.bottom) / 2
      );
      if (away.lengthSq() === 0) away.copy(this.facing).negate();
      away.normalize().scale(34);
      this.paper.setPosition(this.paper.x + away.x, this.paper.y + away.y);
      this.currentExit = this.pickNextExit(this.currentExit);
      this.rebuildRoute(this.currentExit);
      this.callbacks.onTurnaround(this.currentExit, this.route);
      return;
    }

    const exit = EXIT_POINTS[this.currentExit];
    if (
      this.routeIndex >= this.route.length
      || Phaser.Math.Distance.Between(this.paper.x, this.paper.y, exit.x, exit.y) <= PAPER_EXIT_RADIUS
    ) {
      this.failCurrentExit();
    }
  }

  private failCurrentExit(): void {
    if (this.paused || this.completed) return;
    this.pauseAfterFailure();
    this.callbacks.onFailure(this.currentExit);
  }

  private pickNextExit(exclude?: CanteenDefenseExitId): CanteenDefenseExitId {
    const exits = (Object.keys(EXIT_POINTS) as CanteenDefenseExitId[])
      .filter((exitId) => exitId !== exclude);
    return Phaser.Math.RND.pick(exits);
  }

  private rebuildRoute(exitId: CanteenDefenseExitId): void {
    this.route.length = 0;
    const startNode = this.findNearestNode(this.paper.x, this.paper.y);
    const gateway = EXIT_GATEWAYS[exitId][0];
    const endNode = this.findNearestNode(gateway.x, gateway.y);
    const nodeIds = this.findNodePath(startNode.id, endNode.id);
    nodeIds.forEach((id) => this.route.push(this.graph.get(id)!.point.clone()));
    EXIT_GATEWAYS[exitId].slice(1).forEach((point) => this.route.push(point.clone()));
    this.routeIndex = 0;
    while (
      this.routeIndex < this.route.length - 1
      && Phaser.Math.Distance.Between(
        this.paper.x,
        this.paper.y,
        this.route[this.routeIndex].x,
        this.route[this.routeIndex].y
      ) < 12
    ) {
      this.routeIndex += 1;
    }
  }

  private findNearestNode(x: number, y: number): NavNode {
    let nearest: NavNode | null = null;
    let nearestDistance = Number.POSITIVE_INFINITY;
    this.graph.forEach((node) => {
      const distance = Phaser.Math.Distance.Squared(x, y, node.point.x, node.point.y);
      if (distance < nearestDistance) {
        nearest = node;
        nearestDistance = distance;
      }
    });
    return nearest!;
  }

  private findNodePath(startId: string, endId: string): string[] {
    const queue = [startId];
    const previous = new Map<string, string | null>([[startId, null]]);
    while (queue.length > 0) {
      const id = queue.shift()!;
      if (id === endId) break;
      this.graph.get(id)!.links.forEach((nextId) => {
        if (previous.has(nextId)) return;
        previous.set(nextId, id);
        queue.push(nextId);
      });
    }
    const path: string[] = [];
    let cursor: string | null | undefined = endId;
    while (cursor) {
      path.unshift(cursor);
      cursor = previous.get(cursor);
    }
    return path.length > 0 ? path : [startId];
  }

  private layoutHud(): void {
    const camera = this.scene.cameras.main;
    const inverseZoom = 1 / getRpgLogicalCameraZoom(this.scene, camera);
    this.timerText
      .setPosition(CANTEEN_INTERIOR_WORLD.width / 2, 98 * inverseZoom)
      .setScale(inverseZoom);
    this.dashText
      .setPosition(
        CANTEEN_INTERIOR_WORLD.width / 2,
        CANTEEN_INTERIOR_WORLD.height - 12 * inverseZoom
      )
      .setScale(inverseZoom);
  }

  private updateHud(): void {
    const seconds = Math.max(0, Math.ceil((DEFENSE_DURATION_MS - this.elapsedMs) / 1000));
    this.timerText.setText(`守住出口  ${seconds.toString().padStart(2, "0")} 秒`);
    const dashReady = this.dashCooldownMs <= 0;
    this.dashText
      .setText(dashReady ? "空格：冲刺" : `冲刺冷却 ${(this.dashCooldownMs / 1000).toFixed(1)}s`)
      .setColor(dashReady ? "#e8f3f6" : "#89949a");
  }
}
