import Phaser from "phaser";
import campusRuntimeData from "../../data/maps/zijingang-campus-loop-runtime.json";
import playerDown0Url from "../../assets/rpg/player/player_down_0.png";
import playerDown1Url from "../../assets/rpg/player/player_down_1.png";
import playerDown2Url from "../../assets/rpg/player/player_down_2.png";
import playerDown3Url from "../../assets/rpg/player/player_down_3.png";
import playerDown4Url from "../../assets/rpg/player/player_down_4.png";
import playerDown5Url from "../../assets/rpg/player/player_down_5.png";
import playerDown6Url from "../../assets/rpg/player/player_down_6.png";
import playerDown7Url from "../../assets/rpg/player/player_down_7.png";
import playerSide0Url from "../../assets/rpg/player/player_side_0.png";
import playerSide1Url from "../../assets/rpg/player/player_side_1.png";
import playerSide2Url from "../../assets/rpg/player/player_side_2.png";
import playerSide3Url from "../../assets/rpg/player/player_side_3.png";
import playerSide4Url from "../../assets/rpg/player/player_side_4.png";
import playerSide5Url from "../../assets/rpg/player/player_side_5.png";
import playerSide6Url from "../../assets/rpg/player/player_side_6.png";
import playerSide7Url from "../../assets/rpg/player/player_side_7.png";
import playerSide8Url from "../../assets/rpg/player/player_side_8.png";
import playerSide9Url from "../../assets/rpg/player/player_side_9.png";
import playerSide10Url from "../../assets/rpg/player/player_side_10.png";
import playerSide11Url from "../../assets/rpg/player/player_side_11.png";
import playerUp0Url from "../../assets/rpg/player/player_up_0.png";
import playerUp1Url from "../../assets/rpg/player/player_up_1.png";
import playerUp2Url from "../../assets/rpg/player/player_up_2.png";
import playerUp3Url from "../../assets/rpg/player/player_up_3.png";
import playerUp4Url from "../../assets/rpg/player/player_up_4.png";
import playerUp5Url from "../../assets/rpg/player/player_up_5.png";
import playerUp6Url from "../../assets/rpg/player/player_up_6.png";
import playerUp7Url from "../../assets/rpg/player/player_up_7.png";
import { preloadRpgImages } from "./RpgAssetLoader";
import type { RpgCardinalFacing } from "./RpgInteractionContract";

export type RpgPlayerFacing = "down" | "up" | "side";
export type RpgPlayerWalkFrame = 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11;

export const RPG_PLAYER_FRAME_WIDTH = 96;
export const RPG_PLAYER_FRAME_HEIGHT = 128;
export const RPG_PLAYER_DISPLAY_SCALE = 0.65;
export const RPG_NORTH_UP_CAMPUS_PLAYER_SCALE_MULTIPLIER = 0.5;
export const RPG_NORTH_UP_CAMPUS_PLAYER_DISPLAY_SCALE = (
  RPG_PLAYER_DISPLAY_SCALE * RPG_NORTH_UP_CAMPUS_PLAYER_SCALE_MULTIPLIER
);
export const RPG_PLAYER_NAME_OFFSET_Y = 54;
export const RPG_CAMPUS_PLAYER_BASE_MULTIPLIER = campusRuntimeData.perspective.baseMultiplier;
export const RPG_PLAYER_WALK_FRAME_MS = 110;
export const RPG_PLAYER_WALK_FPS = 1000 / RPG_PLAYER_WALK_FRAME_MS;
export const RPG_PLAYER_WALK_FRAME_COUNT = 8;
export const RPG_PLAYER_SIDE_WALK_FRAME_COUNT = 12;
export const RPG_PLAYER_WALK_CYCLE_MS = RPG_PLAYER_WALK_FRAME_MS * RPG_PLAYER_WALK_FRAME_COUNT;
export const RPG_PLAYER_SIDE_WALK_FRAME_MS = (
  RPG_PLAYER_WALK_CYCLE_MS / RPG_PLAYER_SIDE_WALK_FRAME_COUNT
);
export const RPG_PLAYER_SIDE_WALK_FPS = 1000 / RPG_PLAYER_SIDE_WALK_FRAME_MS;
export const RPG_PLAYER_FOOT_COLLISION = Object.freeze({
  width: 30,
  height: 22.5,
  offsetX: 33,
  offsetY: 101.5
});

export const RPG_CAMPUS_PLAYER_PERSPECTIVE = Object.freeze({
  farY: campusRuntimeData.perspective.farY,
  nearY: campusRuntimeData.perspective.nearY,
  farMultiplier: campusRuntimeData.perspective.farMultiplier,
  nearMultiplier: campusRuntimeData.perspective.nearMultiplier
});

const RPG_PLAYER_GROUND_OFFSET_Y = RPG_PLAYER_FRAME_HEIGHT * RPG_PLAYER_DISPLAY_SCALE / 2;
const RPG_PLAYER_NAME_GAP_Y = RPG_PLAYER_NAME_OFFSET_Y - RPG_PLAYER_GROUND_OFFSET_Y;
const RPG_PLAYER_FOOT_WORLD_WIDTH = RPG_PLAYER_FOOT_COLLISION.width * RPG_PLAYER_DISPLAY_SCALE;
const RPG_PLAYER_FOOT_WORLD_HEIGHT = RPG_PLAYER_FOOT_COLLISION.height * RPG_PLAYER_DISPLAY_SCALE;
const RPG_PLAYER_FOOT_BOTTOM_INSET = (
  RPG_PLAYER_FRAME_HEIGHT
  - RPG_PLAYER_FOOT_COLLISION.offsetY
  - RPG_PLAYER_FOOT_COLLISION.height
) * RPG_PLAYER_DISPLAY_SCALE;

export interface RpgPlayerPerspectiveMetrics {
  normalizedDepth: number;
  perspectiveMultiplier: number;
  displayScale: number;
  displayWidth: number;
  displayHeight: number;
  nameOffsetY: number;
}

export const RPG_PLAYER_TEXTURE_ASSETS = {
  "act1-player-down-0": playerDown0Url,
  "act1-player-down-1": playerDown1Url,
  "act1-player-down-2": playerDown2Url,
  "act1-player-down-3": playerDown3Url,
  "act1-player-down-4": playerDown4Url,
  "act1-player-down-5": playerDown5Url,
  "act1-player-down-6": playerDown6Url,
  "act1-player-down-7": playerDown7Url,
  "act1-player-up-0": playerUp0Url,
  "act1-player-up-1": playerUp1Url,
  "act1-player-up-2": playerUp2Url,
  "act1-player-up-3": playerUp3Url,
  "act1-player-up-4": playerUp4Url,
  "act1-player-up-5": playerUp5Url,
  "act1-player-up-6": playerUp6Url,
  "act1-player-up-7": playerUp7Url,
  "act1-player-side-0": playerSide0Url,
  "act1-player-side-1": playerSide1Url,
  "act1-player-side-2": playerSide2Url,
  "act1-player-side-3": playerSide3Url,
  "act1-player-side-4": playerSide4Url,
  "act1-player-side-5": playerSide5Url,
  "act1-player-side-6": playerSide6Url,
  "act1-player-side-7": playerSide7Url,
  "act1-player-side-8": playerSide8Url,
  "act1-player-side-9": playerSide9Url,
  "act1-player-side-10": playerSide10Url,
  "act1-player-side-11": playerSide11Url
} as const;

export function preloadRpgPlayerTextures(scene: Phaser.Scene): void {
  preloadRpgImages(scene, Object.entries(RPG_PLAYER_TEXTURE_ASSETS));
}

export function ensureRpgPlayerTextures(scene: Phaser.Scene): void {
  const drawPlayer = (texture: string, facing: RpgPlayerFacing, frame: RpgPlayerWalkFrame) => {
    if (scene.textures.exists(texture)) {
      return;
    }
    const graphics = scene.make.graphics({ x: 0, y: 0 });
    graphics.scaleCanvas(RPG_PLAYER_FRAME_WIDTH / 28, RPG_PLAYER_FRAME_HEIGHT / 43);
    graphics.fillStyle(0x172028, 0.42).fillEllipse(14, 39, 24, 7);
    const fallbackPhase = frame % 4;
    const stepping = fallbackPhase === 1 || fallbackPhase === 3;
    const alternateStep = fallbackPhase === 3;
    const leftStep = stepping ? (alternateStep ? 17 : 2) : 5;
    const rightStep = stepping ? (alternateStep ? 2 : 17) : 15;
    graphics.fillStyle(0x26313b).fillRect(leftStep, 32, 8, 7).fillRect(rightStep, stepping ? 30 : 32, 8, 7);
    graphics.fillStyle(0x17212a).fillRect(leftStep - 1, 37, 10, 4).fillRect(rightStep - 1, stepping ? 35 : 37, 10, 4);

    if (facing === "up") {
      graphics.fillStyle(0x244b7d).fillRect(4, 17, 20, 17);
      graphics.lineStyle(2, 0x17212a).strokeRect(4, 17, 20, 17);
      graphics.fillStyle(0x59432f).fillRect(8, 19, 12, 11);
      graphics.fillStyle(0xf0d54e).fillRect(7, 31, 14, 3);
    } else if (facing === "side") {
      graphics.fillStyle(0x315f9f).fillRect(5, 17, 17, 17);
      graphics.lineStyle(2, 0x17212a).strokeRect(5, 17, 17, 17);
      graphics.fillStyle(0x59432f).fillRect(3, 20, 6, 12);
      graphics.fillStyle(0xf0d54e).fillRect(8, 22, 13, 3);
    } else {
      graphics.fillStyle(0x315f9f).fillRect(4, 17, 20, 17);
      graphics.lineStyle(2, 0x17212a).strokeRect(4, 17, 20, 17);
      graphics.fillStyle(0xf0d54e).fillRect(7, 21, 14, 4);
      graphics.fillStyle(0xe8eced).fillRect(12, 25, 4, 6);
    }

    graphics.fillStyle(0xe0b36f).fillCircle(14, 10, 9);
    graphics.lineStyle(2, 0x17212a).strokeCircle(14, 10, 9);
    graphics.fillStyle(0x2a2220).fillRect(6, 4, 16, 6).fillRect(5, 7, 4, 8);
    if (facing === "up") {
      graphics.fillStyle(0x2a2220).fillRect(9, 11, 12, 6);
    } else if (facing === "side") {
      graphics.fillStyle(0x17212a).fillRect(19, 10, 3, 3);
    } else {
      graphics.fillStyle(0x17212a).fillRect(9, 10, 3, 3).fillRect(17, 10, 3, 3);
    }
    graphics.generateTexture(texture, RPG_PLAYER_FRAME_WIDTH, RPG_PLAYER_FRAME_HEIGHT);
    graphics.destroy();
  };

  (["down", "up", "side"] as const).forEach((direction) => {
    const frameCount = direction === "side"
      ? RPG_PLAYER_SIDE_WALK_FRAME_COUNT
      : RPG_PLAYER_WALK_FRAME_COUNT;
    Array.from({ length: frameCount }, (_unused, frame) => frame).forEach((frame) => {
      drawPlayer(
        `act1-player-${direction}-${frame}`,
        direction,
        frame as RpgPlayerWalkFrame
      );
    });
  });
}

function applyRpgPlayerVisualScale(player: Phaser.Physics.Arcade.Sprite, displayScale: number): void {
  const safeScale = Math.max(0.01, displayScale);
  const originY = 1 - RPG_PLAYER_GROUND_OFFSET_Y / (RPG_PLAYER_FRAME_HEIGHT * safeScale);

  player.setScale(safeScale).setOrigin(0.5, originY);
  player.body
    ?.setSize(
      RPG_PLAYER_FOOT_WORLD_WIDTH / safeScale,
      RPG_PLAYER_FOOT_WORLD_HEIGHT / safeScale
    )
    .setOffset(
      RPG_PLAYER_FRAME_WIDTH / 2 - RPG_PLAYER_FOOT_WORLD_WIDTH / (2 * safeScale),
      RPG_PLAYER_FRAME_HEIGHT
        - (RPG_PLAYER_FOOT_BOTTOM_INSET + RPG_PLAYER_FOOT_WORLD_HEIGHT) / safeScale
    );
}

export function getRpgPlayerNameOffsetY(displayScale = RPG_PLAYER_DISPLAY_SCALE): number {
  return RPG_PLAYER_FRAME_HEIGHT * displayScale - RPG_PLAYER_GROUND_OFFSET_Y + RPG_PLAYER_NAME_GAP_Y;
}

export function configureRpgPlayerSprite(player: Phaser.Physics.Arcade.Sprite): void {
  applyRpgPlayerVisualScale(player, RPG_PLAYER_DISPLAY_SCALE);
}

export function configureNorthUpCampusRpgPlayerSprite(
  player: Phaser.Physics.Arcade.Sprite
): void {
  applyRpgPlayerVisualScale(player, RPG_NORTH_UP_CAMPUS_PLAYER_DISPLAY_SCALE);
}

/**
 * Convert elapsed movement time into the shared directional walk sequence.
 * The elapsed value is local to one continuous walk, so a fresh walk cannot
 * enter halfway through a stride because of a scene's absolute game clock.
 * Down/up retain eight frames. Side walking uses twelve actually drawn frames
 * over the same 880ms cycle, so extra artwork improves continuity without
 * changing movement cadence.
 */
export function getRpgPlayerWalkFrameAt(
  elapsedMs: number,
  facing: RpgPlayerFacing = "down"
): RpgPlayerWalkFrame {
  const frameCount = facing === "side"
    ? RPG_PLAYER_SIDE_WALK_FRAME_COUNT
    : RPG_PLAYER_WALK_FRAME_COUNT;
  const frameMs = RPG_PLAYER_WALK_CYCLE_MS / frameCount;
  return (
    Math.floor(Math.max(0, elapsedMs) / frameMs)
    % frameCount
  ) as RpgPlayerWalkFrame;
}

export function applyCampusRpgPlayerPerspectiveScale(
  player: Phaser.Physics.Arcade.Sprite,
  worldY: number
): RpgPlayerPerspectiveMetrics {
  const perspective = RPG_CAMPUS_PLAYER_PERSPECTIVE;
  const normalizedDepth = Phaser.Math.Clamp(
    (worldY - perspective.farY) / (perspective.nearY - perspective.farY),
    0,
    1
  );
  const perspectiveMultiplier = Phaser.Math.Linear(
    perspective.farMultiplier,
    perspective.nearMultiplier,
    normalizedDepth
  );
  const displayScale = RPG_PLAYER_DISPLAY_SCALE
    * RPG_CAMPUS_PLAYER_BASE_MULTIPLIER
    * perspectiveMultiplier;

  applyRpgPlayerVisualScale(player, displayScale);
  return {
    normalizedDepth,
    perspectiveMultiplier,
    displayScale,
    displayWidth: RPG_PLAYER_FRAME_WIDTH * displayScale,
    displayHeight: RPG_PLAYER_FRAME_HEIGHT * displayScale,
    nameOffsetY: getRpgPlayerNameOffsetY(displayScale)
  };
}

interface TurnState {
  fromFacing: RpgPlayerFacing;
  fromFlipX: boolean;
  toFacing: RpgPlayerFacing;
  toFlipX: boolean;
  startedAt: number;
  durationMs: number;
}

function directionFromVector(vector: Phaser.Math.Vector2): { facing: RpgPlayerFacing; flipX: boolean } {
  if (Math.abs(vector.x) > Math.abs(vector.y)) {
    return { facing: "side", flipX: vector.x < 0 };
  }
  return { facing: vector.y < 0 ? "up" : "down", flipX: false };
}

function turnDuration(
  fromFacing: RpgPlayerFacing,
  fromFlipX: boolean,
  toFacing: RpgPlayerFacing,
  toFlipX: boolean
): number {
  if (fromFacing === "side" && toFacing === "side" && fromFlipX !== toFlipX) {
    return 150;
  }
  if (fromFacing !== "side" && toFacing !== "side" && fromFacing !== toFacing) {
    return 170;
  }
  return 132;
}

/**
 * 共享人物动画器：方向改变时依次显示原朝向、侧身过渡和新朝向；
 * 行走帧率统一由本模块控制，三个 RPG 场景不再各自维护帧计时。
 */
export class RpgPlayerAnimator {
  private targetFacing: RpgPlayerFacing;
  private targetFlipX: boolean;
  private walkingFrame: RpgPlayerWalkFrame = 0;
  private walkCycleStartedAt: number | null = null;
  private turn: TurnState | null = null;

  constructor(
    private readonly player: Phaser.Physics.Arcade.Sprite,
    initialFacing: RpgPlayerFacing,
    initialFlipX = false
  ) {
    this.targetFacing = initialFacing;
    this.targetFlipX = initialFlipX;
    this.applyPose(initialFacing, 0, initialFlipX);
  }

  get facing(): RpgPlayerFacing {
    return this.targetFacing;
  }

  get cardinalFacing(): RpgCardinalFacing {
    if (this.targetFacing === "side") {
      return this.targetFlipX ? "left" : "right";
    }
    return this.targetFacing;
  }

  get isTurning(): boolean {
    return this.turn !== null;
  }

  get textureKey(): string {
    return this.player.texture.key;
  }

  setFacing(facing: RpgPlayerFacing, flipX = false): void {
    this.targetFacing = facing;
    this.targetFlipX = flipX;
    this.walkingFrame = 0;
    this.walkCycleStartedAt = null;
    this.turn = null;
    this.applyPose(facing, 0, flipX);
  }

  update(vector: Phaser.Math.Vector2, now: number): void {
    const moving = vector.lengthSq() > 0;
    if (moving) {
      const desired = directionFromVector(vector);
      if (desired.facing !== this.targetFacing || desired.flipX !== this.targetFlipX) {
        this.turn = {
          fromFacing: this.targetFacing,
          fromFlipX: this.targetFlipX,
          toFacing: desired.facing,
          toFlipX: desired.flipX,
          startedAt: now,
          durationMs: turnDuration(this.targetFacing, this.targetFlipX, desired.facing, desired.flipX)
        };
        this.targetFacing = desired.facing;
        this.targetFlipX = desired.flipX;
        this.walkingFrame = 0;
        this.walkCycleStartedAt = null;
      }
    }

    if (this.turn) {
      const progress = Math.min(1, (now - this.turn.startedAt) / this.turn.durationMs);
      if (progress < 0.3) {
        this.applyPose(this.turn.fromFacing, 0, this.turn.fromFlipX);
        return;
      }
      if (progress < 0.68) {
        const reversingSide = this.turn.fromFacing === "side"
          && this.turn.toFacing === "side"
          && this.turn.fromFlipX !== this.turn.toFlipX;
        if (reversingSide) {
          this.applyPose("down", 0, false);
        } else {
        const transitionFlip = this.turn.toFacing === "side"
            ? this.turn.toFlipX
            : this.turn.fromFacing === "side"
              ? this.turn.fromFlipX
              : false;
          const turnAngle = transitionFlip ? -6 : 6;
          this.applyPose("side", 0, transitionFlip, turnAngle);
        }
        return;
      }
      this.applyPose(this.turn.toFacing, 0, this.turn.toFlipX);
      if (progress < 1) {
        return;
      }
      this.turn = null;
      this.walkingFrame = 0;
      this.walkCycleStartedAt = now;
      // Keep the target's neutral pose visible for one render before the
      // walk loop advances. This preserves the missing support beat
      // when the player changes direction while holding movement input.
      return;
    }

    if (!moving) {
      this.walkingFrame = 0;
      this.walkCycleStartedAt = null;
      this.applyPose(this.targetFacing, 0, this.targetFlipX);
      return;
    }

    if (this.walkCycleStartedAt === null || now < this.walkCycleStartedAt) {
      this.walkCycleStartedAt = now;
    }
    const nextFrame = getRpgPlayerWalkFrameAt(
      now - this.walkCycleStartedAt,
      this.targetFacing
    );
    if (
      nextFrame !== this.walkingFrame
      || this.player.texture.key !== `act1-player-${this.targetFacing}-${nextFrame}`
      || this.player.flipX !== this.targetFlipX
    ) {
      this.walkingFrame = nextFrame;
      this.applyPose(this.targetFacing, nextFrame, this.targetFlipX);
    }
  }

  private applyPose(
    facing: RpgPlayerFacing,
    frame: RpgPlayerWalkFrame,
    flipX: boolean,
    angle = 0
  ): void {
    const texture = `act1-player-${facing}-${frame}`;
    if (this.player.texture.key !== texture) {
      this.player.setTexture(texture);
    }
    if (this.player.flipX !== flipX) {
      this.player.setFlipX(flipX);
    }
    if (this.player.angle !== angle) {
      this.player.setAngle(angle);
    }
  }
}
