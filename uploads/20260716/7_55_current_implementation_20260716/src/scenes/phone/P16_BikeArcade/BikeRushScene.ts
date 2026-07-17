import Phaser from "phaser";
import {
  advanceBikeDistance,
  BIKE_ARCADE_GOAL,
  BIKE_ARCADE_MAX_LIVES,
  bikeObstacleSpeed,
  emitCrossedBikeMilestones,
  loseBikeLife,
  moveBikeLane,
  planBikeObstacleWave,
  type BikeArcadeLane,
  type BikeArcadeMilestone,
  type BikeObstacleScheduleEntropy,
  type BikeObstacleWavePlan
} from "./BikeArcadeRules";
import {
  BikeArcadeLifecycle,
  clearBikeArcadeSnapshot,
  resolveBikeArcadeReducedMotion,
  setBikeArcadeSnapshot,
  type BikeArcadeCollisionEvent,
  type BikeArcadeLaneChangeEvent,
  type BikeArcadeNearMissEvent,
  type BikeArcadeObstacleType,
  type BikeArcadePauseReason,
  type BikeArcadePhase,
  type BikeArcadeRunSummary
} from "./BikeArcadeRuntime";

export interface BikeArcadeBridge {
  onDistance: (distance: number) => void;
  onLives: (lives: number) => void;
  onFinish: (result: "won" | "lost", summary: BikeArcadeRunSummary) => void;
  onCollision: (event: BikeArcadeCollisionEvent) => void;
  onMilestone?: (milestone: BikeArcadeMilestone) => void;
  onLaneChanged?: (event: BikeArcadeLaneChangeEvent) => void;
  onNearMiss?: (event: BikeArcadeNearMissEvent) => void;
  onPauseChange?: (paused: boolean) => void;
  reducedMotion?: boolean;
}

const LANE_X = [88, 195, 302] as const;
const BIKE_ARCADE_INVULNERABLE_MS = 900;
const BIKE_ARCADE_INITIAL_SPAWN_DELAY_MS = 720;

export class BikeRushScene extends Phaser.Scene {
  private bridge!: BikeArcadeBridge;
  private player!: Phaser.Physics.Arcade.Sprite;
  private obstacles!: Phaser.Physics.Arcade.Group;
  private roadMarks: Phaser.GameObjects.Rectangle[] = [];
  private lane: BikeArcadeLane = 1;
  private safeLane: BikeArcadeLane = 1;
  private distance = 0;
  private lives = BIKE_ARCADE_MAX_LIVES;
  private invulnerable = false;
  private finished = false;
  private spawnDelayRemainingMs = BIKE_ARCADE_INITIAL_SPAWN_DELAY_MS;
  private lastPublishedDistance = -1;
  private lastMilestone: BikeArcadeMilestone | null = null;
  private reducedMotion = false;
  private simulationPaused = false;
  private readonly lifecycle = new BikeArcadeLifecycle();
  private readonly handleVisibilityChange = () => {
    this.setPauseReason("document-hidden", document.hidden);
  };
  private readonly handleWindowBlur = () => {
    this.setPauseReason("window-blur", true);
  };
  private readonly handleWindowFocus = () => {
    this.setPauseReason("window-blur", false);
  };

  constructor() {
    super("bike-rush");
  }

  create(): void {
    this.bridge = this.registry.get("bikeArcadeBridge") as BikeArcadeBridge;
    const developerStartDistance = Number(this.registry.get("bikeArcadeStartDistance") ?? 0);
    this.distance = Number.isFinite(developerStartDistance) ? Math.min(BIKE_ARCADE_GOAL - 1, Math.max(0, developerStartDistance)) : 0;
    this.lastPublishedDistance = Math.floor(this.distance) - 1;
    const mediaPreference = typeof window !== "undefined" &&
      window.matchMedia?.("(prefers-reduced-motion: reduce)").matches === true;
    const registryFlag = this.registry.get("bikeArcadeReducedMotion");
    const explicitFlag = this.bridge.reducedMotion ??
      (typeof registryFlag === "boolean" ? registryFlag : undefined);
    this.reducedMotion = resolveBikeArcadeReducedMotion(explicitFlag, mediaPreference);
    this.physics.world.setBounds(0, 0, 390, 650);
    this.cameras.main.setBackgroundColor(0x73945f);
    this.drawRoad();
    this.ensureTextures();
    this.player = this.physics.add.sprite(LANE_X[this.lane], 560, "bike-player");
    this.player.setCollideWorldBounds(true).setDepth(40);
    this.player.body?.setSize(30, 48).setOffset(8, 10);
    if (!this.reducedMotion) {
      this.player.setAlpha(0);
      this.cameras.main.fadeIn(260, 32, 39, 47);
      this.tweens.add({
        targets: this.player,
        alpha: 1,
        y: 552,
        duration: 360,
        ease: "Back.easeOut",
        onComplete: () => this.player?.setY(560)
      });
    }
    this.obstacles = this.physics.add.group();
    this.physics.add.overlap(this.player, this.obstacles, (_player, obstacle) => {
      this.handleCollision(obstacle as Phaser.Physics.Arcade.Sprite);
    });

    this.input.keyboard?.on("keydown-LEFT", () => this.moveLane(-1));
    this.input.keyboard?.on("keydown-A", () => this.moveLane(-1));
    this.input.keyboard?.on("keydown-RIGHT", () => this.moveLane(1));
    this.input.keyboard?.on("keydown-D", () => this.moveLane(1));
    this.input.on("pointerdown", (pointer: Phaser.Input.Pointer) => this.moveLane(pointer.x < 195 ? -1 : 1));
    this.installLifecycleListeners();
    this.publishSnapshot("playing");
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, this.handleShutdown, this);
  }

  update(time: number, delta: number): void {
    if (this.finished) {
      return;
    }
    const frame = this.lifecycle.consumeFrame(delta);
    if (frame.paused) {
      return;
    }
    if (frame.resumed) {
      this.resumeSimulation();
      return;
    }

    const previousDistance = this.distance;
    this.distance = advanceBikeDistance(this.distance, frame.deltaMs);
    emitCrossedBikeMilestones(previousDistance, this.distance, (milestone) => {
      this.lastMilestone = milestone;
      this.spawnMilestoneBoard(milestone);
      this.bridge.onMilestone?.(milestone);
    });
    const speed = bikeObstacleSpeed(this.distance);
    this.scrollRoad(frame.deltaMs, speed);
    this.updateObstacles(speed);
    if (!this.reducedMotion && !this.invulnerable) {
      this.player.setY(560 + Math.sin(time / 92) * 2.2);
    }

    this.spawnDelayRemainingMs -= frame.deltaMs;
    if (this.spawnDelayRemainingMs <= 0) {
      const plan = planBikeObstacleWave({
        distance: this.distance,
        previousSafeLane: this.safeLane,
        entropy: this.createObstacleEntropy()
      });
      this.spawnObstacleWave(plan);
      this.safeLane = plan.safeLane;
      this.spawnDelayRemainingMs = plan.spawnDelayMs;
    }

    const roundedDistance = Math.floor(this.distance);
    if (roundedDistance !== this.lastPublishedDistance) {
      this.lastPublishedDistance = roundedDistance;
      this.bridge.onDistance(roundedDistance);
      this.publishSnapshot("playing");
    }

    if (this.distance >= BIKE_ARCADE_GOAL) {
      this.finish("won");
    }
  }

  moveLane(direction: -1 | 1): void {
    if (this.finished || this.simulationPaused) {
      return;
    }
    const previousLane = this.lane;
    const nextLane = moveBikeLane(this.lane, direction);
    if (nextLane === this.lane) {
      return;
    }
    this.lane = nextLane;
    this.tweens.killTweensOf(this.player);
    this.tweens.add({
      targets: this.player,
      x: LANE_X[this.lane],
      angle: direction * 8,
      duration: 105,
      ease: "Sine.easeOut",
      onComplete: () => {
        if (!this.player?.active) {
          return;
        }
        this.tweens.add({ targets: this.player, angle: 0, duration: 90, ease: "Sine.easeIn" });
      }
    });
    this.bridge.onLaneChanged?.({ from: previousLane, to: this.lane });
    this.publishSnapshot("playing");
  }

  private createObstacleEntropy(): BikeObstacleScheduleEntropy {
    return {
      safeLane: Phaser.Math.RND.frac(),
      density: Phaser.Math.RND.frac(),
      blockedLane: Phaser.Math.RND.frac(),
      interval: Phaser.Math.RND.frac(),
      obstacleTypes: [Phaser.Math.RND.frac(), Phaser.Math.RND.frac()]
    };
  }

  private drawRoad(): void {
    this.add.rectangle(195, 325, 390, 650, 0x6d8d57).setDepth(0);
    this.add.rectangle(195, 325, 314, 650, 0x474e52).setStrokeStyle(5, 0x252c30).setDepth(1);
    this.add.rectangle(25, 325, 46, 650, 0xbcb8a8).setDepth(2);
    this.add.rectangle(365, 325, 46, 650, 0xbcb8a8).setDepth(2);
    this.add.rectangle(49, 325, 8, 650, 0xf0d54e).setDepth(3);
    this.add.rectangle(341, 325, 8, 650, 0xf0d54e).setDepth(3);

    for (const x of [141, 249]) {
      for (let y = -30; y < 680; y += 86) {
        const mark = this.add.rectangle(x, y, 5, 42, 0xf3f0df, 0.74).setDepth(3);
        this.roadMarks.push(mark);
      }
    }

    for (let y = 40; y < 650; y += 105) {
      this.createRoadsideTree(18, y);
      this.createRoadsideTree(372, y + 48);
    }
    this.drawCampusLandmarks();
    this.add.text(195, 22, "求是大道", {
      color: "#f2e3a2",
      fontFamily: "monospace",
      fontSize: "14px",
      backgroundColor: "#20272fd9",
      padding: { x: 8, y: 4 }
    }).setOrigin(0.5).setDepth(10);
  }

  private createRoadsideTree(x: number, y: number): void {
    this.add.rectangle(x, y + 8, 5, 18, 0x6e4f34).setDepth(4);
    this.add.circle(x - 5, y - 2, 10, 0x397243).setStrokeStyle(2, 0x244d31).setDepth(5);
    this.add.circle(x + 6, y - 4, 11, 0x4a8247).setStrokeStyle(2, 0x244d31).setDepth(6);
  }

  private scrollRoad(delta: number, speed: number): void {
    const movement = speed * delta * 0.001;
    this.roadMarks.forEach((mark) => {
      mark.y += movement;
      if (mark.y > 690) {
        mark.y -= 774;
      }
    });
  }

  private updateObstacles(speed: number): void {
    this.obstacles.getChildren().forEach((child) => {
      const obstacle = child as Phaser.Physics.Arcade.Sprite;
      obstacle.setVelocityY(speed);
      if (!obstacle.getData("passed") && obstacle.y > this.player.y + 48) {
        obstacle.setData("passed", true);
        const lane = Number(obstacle.getData("lane")) as BikeArcadeLane;
        if (Math.abs(lane - this.lane) === 1) {
          this.showNearMiss();
          this.bridge.onNearMiss?.({
            obstacleType: obstacle.getData("type") as BikeArcadeObstacleType,
            lane
          });
        }
      }
      if (obstacle.y > 720) {
        obstacle.destroy();
      }
    });
  }

  private spawnObstacleWave(plan: BikeObstacleWavePlan): void {
    plan.obstacles.forEach((obstacle) => this.spawnObstacle(obstacle.lane, obstacle.type));
  }

  private spawnObstacle(lane: BikeArcadeLane, type: BikeArcadeObstacleType): void {
    const texture = `bike-obstacle-${type}`;
    const obstacle = this.physics.add.sprite(LANE_X[lane], -55, texture).setDepth(30);
    if (!this.reducedMotion) {
      obstacle.setAlpha(0.35).setScale(0.84);
      this.tweens.add({
        targets: obstacle,
        alpha: 1,
        scaleX: 1,
        scaleY: 1,
        duration: 180,
        ease: "Back.easeOut"
      });
      if (type === "bicycle") {
        this.tweens.add({
          targets: obstacle,
          angle: { from: -2, to: 2 },
          duration: 240,
          yoyo: true,
          repeat: -1,
          ease: "Sine.easeInOut"
        });
      }
    }
    obstacle.setData("lane", lane);
    obstacle.setData("type", type);
    obstacle.setData("passed", false);
    if (type === "barrier") {
      obstacle.body?.setSize(56, 28).setOffset(2, 9);
    } else if (type === "crowd") {
      obstacle.body?.setSize(44, 45).setOffset(6, 9);
    } else {
      obstacle.body?.setSize(34, 50).setOffset(10, 8);
    }
    this.obstacles.add(obstacle);
  }

  private handleCollision(obstacle: Phaser.Physics.Arcade.Sprite): void {
    if (this.finished || this.invulnerable) {
      return;
    }
    const obstacleType = obstacle.getData("type") as BikeArcadeObstacleType;
    obstacle.destroy();
    this.lives = loseBikeLife(this.lives);
    this.invulnerable = true;
    this.bridge.onLives(this.lives);
    this.bridge.onCollision({
      obstacleType,
      lives: this.lives,
      invulnerableMs: BIKE_ARCADE_INVULNERABLE_MS
    });
    if (!this.reducedMotion) {
      this.cameras.main.shake(170, 0.012);
      this.spawnImpactBurst(this.player.x, this.player.y - 12);
    }
    this.player.setTint(0xe97b70).setAlpha(this.reducedMotion ? 0.82 : 0.48);
    this.time.delayedCall(BIKE_ARCADE_INVULNERABLE_MS, () => {
      if (!this.player?.active || this.finished) {
        return;
      }
      this.invulnerable = false;
      this.player.clearTint().setAlpha(1);
      this.publishSnapshot("playing");
    });
    this.publishSnapshot(this.lives === 0 ? "lost" : "playing");
    if (this.lives === 0) {
      this.finish("lost");
    }
  }

  private finish(result: "won" | "lost"): void {
    if (this.finished) {
      return;
    }
    this.finished = true;
    this.physics.pause();
    this.tweens.killTweensOf(this.player);
    if (!this.reducedMotion) {
      if (result === "won") {
        this.cameras.main.flash(220, 240, 213, 78, false);
        this.tweens.add({
          targets: this.player,
          y: 480,
          scaleX: 1.08,
          scaleY: 1.08,
          duration: 420,
          ease: "Sine.easeOut"
        });
      } else {
        this.cameras.main.flash(180, 233, 123, 112, false);
        this.tweens.add({
          targets: this.player,
          angle: 12,
          alpha: 0.58,
          duration: 260,
          ease: "Sine.easeOut"
        });
      }
    }
    this.publishSnapshot(result);
    this.bridge.onFinish(result, {
      distance: Math.floor(this.distance),
      lives: this.lives,
      lastMilestone: this.lastMilestone
    });
  }

  private installLifecycleListeners(): void {
    if (typeof document !== "undefined") {
      document.addEventListener("visibilitychange", this.handleVisibilityChange);
      this.setPauseReason("document-hidden", document.hidden);
      if (typeof document.hasFocus === "function") {
        this.setPauseReason("window-blur", !document.hasFocus());
      }
    }
    if (typeof window !== "undefined") {
      window.addEventListener("blur", this.handleWindowBlur);
      window.addEventListener("focus", this.handleWindowFocus);
    }
  }

  private setPauseReason(reason: BikeArcadePauseReason, paused: boolean): void {
    if (this.finished) {
      return;
    }
    const transition = this.lifecycle.setPauseReason(reason, paused);
    if (transition !== "paused") {
      return;
    }
    this.simulationPaused = true;
    this.physics.pause();
    this.time.paused = true;
    this.tweens.pauseAll();
    this.bridge.onPauseChange?.(true);
    this.publishSnapshot("playing");
  }

  private resumeSimulation(): void {
    this.simulationPaused = false;
    this.time.paused = false;
    this.physics.resume();
    this.tweens.resumeAll();
    this.bridge.onPauseChange?.(false);
    this.publishSnapshot("playing");
  }

  private handleShutdown(): void {
    if (typeof document !== "undefined") {
      document.removeEventListener("visibilitychange", this.handleVisibilityChange);
    }
    if (typeof window !== "undefined") {
      window.removeEventListener("blur", this.handleWindowBlur);
      window.removeEventListener("focus", this.handleWindowFocus);
    }
    clearBikeArcadeSnapshot();
  }

  private spawnMilestoneBoard(milestone: BikeArcadeMilestone): void {
    if (milestone >= BIKE_ARCADE_GOAL) {
      return;
    }
    const sideX = milestone === 377 ? 365 : 25;
    const panel = this.add.rectangle(0, 0, 46, 24, 0xe7e2d4)
      .setStrokeStyle(3, 0x20272f);
    const label = this.add.text(0, 0, String(milestone), {
      color: "#20272f",
      fontFamily: "monospace",
      fontSize: "9px"
    }).setOrigin(0.5);
    const sign = this.add.container(sideX, -22, [panel, label]).setDepth(20);
    if (!this.reducedMotion) {
      sign.setScale(0.72).setAlpha(0.4);
      this.tweens.add({
        targets: sign,
        scaleX: 1,
        scaleY: 1,
        alpha: 1,
        duration: 220,
        ease: "Back.easeOut"
      });
    }
    const duration = Math.max(1800, (720 / bikeObstacleSpeed(this.distance)) * 1000);
    this.tweens.add({
      targets: sign,
      y: 690,
      duration,
      ease: "Linear",
      onComplete: () => sign.destroy(true)
    });
  }

  private showNearMiss(): void {
    if (this.reducedMotion || !this.player?.active) {
      return;
    }
    this.cameras.main.flash(65, 143, 199, 209, false);
    this.tweens.add({
      targets: this.player,
      scaleX: 1.12,
      scaleY: 1.12,
      duration: 70,
      yoyo: true,
      ease: "Sine.easeOut"
    });
  }

  private spawnImpactBurst(x: number, y: number): void {
    const colors = [0xf0d54e, 0xe97b70, 0xe7e2d4];
    for (let index = 0; index < 8; index += 1) {
      const shard = this.add.rectangle(x, y, 7, 7, colors[index % colors.length]).setDepth(60);
      const angle = (Math.PI * 2 * index) / 8;
      this.tweens.add({
        targets: shard,
        x: x + Math.cos(angle) * (28 + (index % 3) * 7),
        y: y + Math.sin(angle) * (28 + (index % 2) * 9),
        alpha: 0,
        scaleX: 0.35,
        scaleY: 0.35,
        duration: 360,
        ease: "Quad.easeOut",
        onComplete: () => shard.destroy()
      });
    }
  }

  private drawCampusLandmarks(): void {
    const eagle = this.add.graphics().setPosition(25, 142).setDepth(8);
    eagle.fillStyle(0x315f9f).fillTriangle(-12, 0, 0, -15, 12, 0);
    eagle.fillStyle(0xe7e2d4).fillRect(-3, 0, 6, 22);
    eagle.fillStyle(0x596168).fillRect(-13, 20, 26, 5);

    const library = this.add.graphics().setPosition(365, 430).setDepth(8);
    library.fillStyle(0xe7e2d4).fillRect(-15, -8, 30, 26);
    library.fillStyle(0x315f9f).fillRect(-4, -28, 8, 20);
    library.lineStyle(3, 0xf0d54e).strokeCircle(0, -31, 7);
    library.fillStyle(0x20272f).fillRect(-11, 0, 7, 10).fillRect(4, 0, 7, 10);
  }

  private publishSnapshot(phase: BikeArcadePhase): void {
    setBikeArcadeSnapshot({
      coordinateSystem: "390x650 canvas, origin at top-left, x right, y down",
      phase,
      distance: Math.floor(this.distance),
      goal: BIKE_ARCADE_GOAL,
      lives: this.lives,
      lane: this.lane,
      invulnerable: this.invulnerable,
      paused: this.simulationPaused,
      reducedMotion: this.reducedMotion,
      lastMilestone: this.lastMilestone,
      safeLane: this.safeLane,
      nextSpawnInMs: Math.max(0, Math.round(this.spawnDelayRemainingMs)),
      obstacles: this.obstacles
        ? this.obstacles.getChildren().slice(0, 8).map((child) => {
            const obstacle = child as Phaser.Physics.Arcade.Sprite;
            return {
              lane: Number(obstacle.getData("lane")),
              type: obstacle.getData("type") as BikeArcadeObstacleType,
              y: Math.round(obstacle.y)
            };
          })
        : []
    });
  }

  private ensureTextures(): void {
    if (!this.textures.exists("bike-player")) {
      const player = this.make.graphics({ x: 0, y: 0 });
      player.fillStyle(0x17212a, 0.38).fillEllipse(24, 63, 36, 8);
      player.lineStyle(4, 0x15222a).strokeCircle(15, 49, 9).strokeCircle(34, 49, 9);
      player.lineStyle(4, 0xf0d54e).lineBetween(15, 49, 23, 30).lineBetween(23, 30, 34, 49).lineBetween(15, 49, 34, 49);
      player.lineStyle(4, 0x315f9f).lineBetween(23, 30, 29, 18).lineBetween(29, 18, 35, 28);
      player.fillStyle(0xe0b36f).fillCircle(28, 11, 7);
      player.fillStyle(0x27211f).fillRect(22, 5, 13, 6);
      player.generateTexture("bike-player", 48, 68);
      player.destroy();
    }

    if (!this.textures.exists("bike-obstacle-bicycle")) {
      const bicycle = this.make.graphics({ x: 0, y: 0 });
      bicycle.lineStyle(4, 0x17212a).strokeCircle(16, 48, 10).strokeCircle(41, 48, 10);
      bicycle.lineStyle(5, 0xe97b70).lineBetween(16, 48, 27, 25).lineBetween(27, 25, 41, 48).lineBetween(16, 48, 41, 48);
      bicycle.fillStyle(0x20272f).fillRect(23, 18, 17, 5);
      bicycle.fillStyle(0xf0d54e).fillRect(8, 5, 42, 9);
      bicycle.generateTexture("bike-obstacle-bicycle", 58, 64);
      bicycle.destroy();
    }

    if (!this.textures.exists("bike-obstacle-barrier")) {
      const barrier = this.make.graphics({ x: 0, y: 0 });
      barrier.fillStyle(0xf0d54e).fillRect(2, 8, 56, 25);
      barrier.lineStyle(4, 0x2c3338).strokeRect(2, 8, 56, 25);
      for (let x = 6; x < 55; x += 15) {
        barrier.fillStyle(0x33383d).fillRect(x, 10, 8, 21);
      }
      barrier.fillStyle(0x4e5558).fillRect(8, 33, 8, 14).fillRect(44, 33, 8, 14);
      barrier.generateTexture("bike-obstacle-barrier", 60, 49);
      barrier.destroy();
    }

    if (!this.textures.exists("bike-obstacle-crowd")) {
      const crowd = this.make.graphics({ x: 0, y: 0 });
      [[14, 18, 0xe0b36f], [29, 13, 0xc89468], [44, 20, 0xe0b36f]].forEach(([x, y, color]) => {
        crowd.fillStyle(color).fillCircle(x, y, 7);
        crowd.fillStyle(x === 29 ? 0x756aa9 : 0x315f9f).fillRect(x - 7, y + 7, 14, 24);
        crowd.fillStyle(0x20272f).fillRect(x - 7, y + 31, 5, 15).fillRect(x + 2, y + 31, 5, 15);
      });
      crowd.generateTexture("bike-obstacle-crowd", 58, 62);
      crowd.destroy();
    }
  }
}
