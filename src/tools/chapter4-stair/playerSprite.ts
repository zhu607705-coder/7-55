import * as THREE from "three";
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
import playerUp0Url from "../../assets/rpg/player/player_up_0.png";
import playerUp1Url from "../../assets/rpg/player/player_up_1.png";
import playerUp2Url from "../../assets/rpg/player/player_up_2.png";
import playerUp3Url from "../../assets/rpg/player/player_up_3.png";
import playerUp4Url from "../../assets/rpg/player/player_up_4.png";
import playerUp5Url from "../../assets/rpg/player/player_up_5.png";
import playerUp6Url from "../../assets/rpg/player/player_up_6.png";
import playerUp7Url from "../../assets/rpg/player/player_up_7.png";

/**
 * 第四章楼梯间像素人物 Sprite（设计文档 §8.4）。
 * 始终面向当前相机的 THREE.Sprite，复用 src/assets/rpg/player/ 的 96×128
 * 三方向八帧人物图；独立 vite 入口经 viteSingleFile 构建时上述静态导入会被内联。
 * 本模块只依赖 three；纹理加载失败时自动退回程序化硬边备用人物，不影响通关（§11）。
 */

/**
 * 行走帧间隔。与 src/scenes/rpg/RpgPlayerTextures.ts 的 RPG_PLAYER_WALK_FRAME_MS = 110
 * 保持一致；该文件依赖 Phaser，本模块不能引用，故复制常量于此（两处修改需同步）。
 */
export const STAIR_PLAYER_WALK_FRAME_MS = 110;
export const STAIR_PLAYER_WALK_FRAME_COUNT = 8;

export const STAIR_PLAYER_FRAME_WIDTH = 96;
export const STAIR_PLAYER_FRAME_HEIGHT = 128;

/**
 * 人物世界身高（与现有原型一致的换算）：
 * ChapterFourMonumentStairDemo.createPlayer 的胶囊身体（顶约 1.44）+ 头部球体
 * （中心 1.45、半径 0.3）总高约 1.75 世界单位，脚底在 y=0。
 * 原型正交相机竖直可视范围 ±5.5 共 11 世界单位，对应内部 270px（约 24.5px/世界单位），
 * 因此本 Sprite 在内部 480×270 画面上约高 43px。
 */
export const STAIR_PLAYER_HEIGHT_WORLD = 1.75;
/** 宽高比 96:128 换算出的世界宽度（约 1.31）。 */
export const STAIR_PLAYER_WIDTH_WORLD =
  STAIR_PLAYER_HEIGHT_WORLD * (STAIR_PLAYER_FRAME_WIDTH / STAIR_PLAYER_FRAME_HEIGHT);

export type StairPlayerFacing = "down" | "up" | "side";

const PLAYER_FRAME_URLS: Record<StairPlayerFacing, readonly string[]> = {
  down: [
    playerDown0Url, playerDown1Url, playerDown2Url, playerDown3Url,
    playerDown4Url, playerDown5Url, playerDown6Url, playerDown7Url
  ],
  up: [
    playerUp0Url, playerUp1Url, playerUp2Url, playerUp3Url,
    playerUp4Url, playerUp5Url, playerUp6Url, playerUp7Url
  ],
  side: [
    playerSide0Url, playerSide1Url, playerSide2Url, playerSide3Url,
    playerSide4Url, playerSide5Url, playerSide6Url, playerSide7Url
  ]
};

/* ---------------- 程序化备用人物（纹理加载失败时兜底，§11） ---------------- */

const FALLBACK_FRAME_WIDTH = 48;
const FALLBACK_FRAME_HEIGHT = 64;

const FALLBACK_COLORS = Object.freeze({
  outline: "#17212A",
  coat: "#315F9F",
  coatDark: "#244B7D",
  leg: "#26313B",
  shoe: "#17212A",
  skin: "#E0B36F",
  hair: "#2A2220",
  accent: "#F0D54E"
});

/** 用 fillRect 画 48×64 硬边小人（与真实帧同宽高比，世界缩放不变）。 */
function createFallbackFrame(facing: StairPlayerFacing, frame: number): THREE.Texture {
  const canvas = document.createElement("canvas");
  canvas.width = FALLBACK_FRAME_WIDTH;
  canvas.height = FALLBACK_FRAME_HEIGHT;
  const g = canvas.getContext("2d");
  if (g) {
    g.imageSmoothingEnabled = false;
    const rect = (x: number, y: number, w: number, h: number, color: string): void => {
      g.fillStyle = color;
      g.fillRect(x, y, w, h);
    };
    const fallbackPhase = frame % 4;
    const stepping = fallbackPhase === 1 || fallbackPhase === 3;
    const alternate = fallbackPhase === 3;
    const leftShift = stepping ? (alternate ? 3 : -3) : 0;
    const rightShift = stepping ? (alternate ? -3 : 3) : 0;
    // 腿与鞋：帧 1/3 交替迈步，帧 0/2 并立。
    rect(13 + leftShift, 44, 8, 10, FALLBACK_COLORS.leg);
    rect(27 + rightShift, 44, 8, 10, FALLBACK_COLORS.leg);
    rect(12 + leftShift, 52, 10, 5, FALLBACK_COLORS.shoe);
    rect(26 + rightShift, 52, 10, 5, FALLBACK_COLORS.shoe);
    // 上衣（2px 深轮廓）。
    rect(8, 20, 32, 26, FALLBACK_COLORS.outline);
    rect(10, 22, 28, 22, facing === "up" ? FALLBACK_COLORS.coatDark : FALLBACK_COLORS.coat);
    if (facing === "up") {
      rect(12, 40, 24, 3, FALLBACK_COLORS.accent);
    } else if (facing === "side") {
      rect(16, 26, 16, 3, FALLBACK_COLORS.accent);
    } else {
      rect(14, 25, 20, 4, FALLBACK_COLORS.accent);
    }
    // 头与发。
    rect(12, 2, 24, 22, FALLBACK_COLORS.outline);
    rect(14, 4, 20, 18, FALLBACK_COLORS.skin);
    rect(14, 4, 20, 6, FALLBACK_COLORS.hair);
    if (facing === "up") {
      rect(16, 10, 16, 8, FALLBACK_COLORS.hair);
    } else if (facing === "side") {
      rect(14, 6, 6, 12, FALLBACK_COLORS.hair);
      rect(28, 13, 3, 3, FALLBACK_COLORS.outline);
    } else {
      rect(18, 13, 3, 3, FALLBACK_COLORS.outline);
      rect(27, 13, 3, 3, FALLBACK_COLORS.outline);
    }
  }
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  applyNearest(texture);
  return texture;
}

/** 与 pixelStyle.nearestTexture 相同的最近邻设置（本模块不依赖 pixelStyle，保持单文件依赖边界）。 */
function applyNearest(texture: THREE.Texture): void {
  texture.magFilter = THREE.NearestFilter;
  texture.minFilter = THREE.NearestFilter;
  texture.generateMipmaps = false;
  texture.anisotropy = 1;
}

const FACING_ORDER: readonly StairPlayerFacing[] = ["down", "up", "side"];

const cameraRight = new THREE.Vector3();
const cameraUp = new THREE.Vector3();

export interface StairPlayerSpriteOptions {
  /** 世界单位身高，默认 STAIR_PLAYER_HEIGHT_WORLD（与原型人物一致）。 */
  heightWorld?: number;
}

/**
 * 用法：
 * ```ts
 * const player = new StairPlayerSprite();
 * scene.add(player.object3d);
 * player.object3d.position.copy(footPosition); // position 即脚底坐标
 * player.setDirectionFromVelocity(segmentVelocity, camera); // 每段路径换向时调用
 * player.setWalking(true);
 * // 每帧：player.update(nowMs);
 * // 销毁：player.dispose();
 * ```
 */
export class StairPlayerSprite {
  /** THREE.Sprite：始终面向相机。 */
  readonly object3d: THREE.Sprite;

  private readonly material: THREE.SpriteMaterial;
  private readonly baseScaleX: number;
  /** 当前各朝向各帧的贴图：初始为备用帧，真实 PNG 加载成功后原位替换。 */
  private readonly frames: Record<StairPlayerFacing, THREE.Texture[]>;
  private readonly ownedTextures: THREE.Texture[] = [];
  private facing: StairPlayerFacing = "down";
  private flipX = false;
  private walking = false;
  private frame = 0;
  private occlusionOverride = false;
  private disposed = false;

  constructor(options: StairPlayerSpriteOptions = {}) {
    const height = options.heightWorld ?? STAIR_PLAYER_HEIGHT_WORLD;
    this.baseScaleX = height * (STAIR_PLAYER_FRAME_WIDTH / STAIR_PLAYER_FRAME_HEIGHT);

    this.frames = {
      down: [],
      up: [],
      side: []
    };
    FACING_ORDER.forEach((facing) => {
      for (let frame = 0; frame < STAIR_PLAYER_WALK_FRAME_COUNT; frame += 1) {
        const fallback = createFallbackFrame(facing, frame);
        this.frames[facing].push(fallback);
        this.ownedTextures.push(fallback);
      }
    });

    this.material = new THREE.SpriteMaterial({
      map: this.frames.down[0],
      // 正交相机下 Sprite 缩放本来就是世界单位、无近大远小；
      // sizeAttenuation:false 额外保证即使换透视相机也不随深度缩放（§8.4）。
      sizeAttenuation: false,
      // 硬边 alpha 裁剪：保留正确深度遮挡，避免半透明排序问题。
      alphaTest: 0.5,
      fog: false,
      toneMapped: false
    });
    this.object3d = new THREE.Sprite(this.material);
    this.object3d.name = "stair-player";
    // 脚底锚点：center.y=0 使 position 即脚底坐标，站在走面上不再偏移（§8.4）。
    this.object3d.center.set(0.5, 0);
    this.object3d.scale.set(this.baseScaleX, height, 1);

    this.loadRealFrames();
  }

  /** 按移动方向选 down/up/side 帧组：世界速度投影到当前相机屏幕轴后比较分量。 */
  setDirectionFromVelocity(velocity: THREE.Vector3, camera: THREE.Camera): void {
    if (velocity.lengthSq() < 1e-8) {
      return;
    }
    cameraRight.set(1, 0, 0).applyQuaternion(camera.quaternion);
    cameraUp.set(0, 1, 0).applyQuaternion(camera.quaternion);
    const dx = velocity.dot(cameraRight);
    const dy = velocity.dot(cameraUp);
    if (Math.abs(dx) > Math.abs(dy)) {
      this.facing = "side";
      // side 帧默认面向屏幕右方；与共享 RPG 契约 flipX = x < 0 一致，镜像表示向左。
      this.flipX = dx < 0;
    } else {
      this.facing = dy > 0 ? "up" : "down";
      this.flipX = false;
    }
    this.applyPose();
  }

  /** 站定切回第 0 帧（§8.4）。 */
  setWalking(walking: boolean): void {
    if (this.walking === walking) {
      return;
    }
    this.walking = walking;
    if (!walking) {
      this.frame = 0;
    }
    this.applyPose();
  }

  /**
   * 投影接缝端点可能与较近平台或门体共用同一屏幕坐标。只在端点站定或跨缝时
   * 临时关闭深度测试，确保玩家仍能看见自己的位置；离开接缝后恢复正常遮挡。
   */
  setOcclusionOverride(enabled: boolean): void {
    if (this.occlusionOverride === enabled) {
      return;
    }
    this.occlusionOverride = enabled;
    this.material.depthTest = !enabled;
    this.material.needsUpdate = true;
    this.object3d.renderOrder = enabled ? 100 : 0;
  }

  /** 行走循环：110ms 一帧，八帧循环。每帧调用；静止时为空操作。 */
  update(nowMs: number): void {
    if (!this.walking) {
      return;
    }
    const nextFrame = Math.floor(nowMs / STAIR_PLAYER_WALK_FRAME_MS)
      % STAIR_PLAYER_WALK_FRAME_COUNT;
    if (nextFrame !== this.frame) {
      this.frame = nextFrame;
      this.applyPose();
    }
  }

  dispose(): void {
    if (this.disposed) {
      return;
    }
    this.disposed = true;
    this.material.dispose();
    this.ownedTextures.forEach((texture) => texture.dispose());
    this.ownedTextures.length = 0;
  }

  /** 异步加载真实 96×128 PNG；失败时静默保留备用帧，不影响通关。 */
  private loadRealFrames(): void {
    const loader = new THREE.TextureLoader();
    FACING_ORDER.forEach((facing) => {
      PLAYER_FRAME_URLS[facing].forEach((url, frame) => {
        loader.load(url, (texture) => {
          if (this.disposed) {
            texture.dispose();
            return;
          }
          texture.colorSpace = THREE.SRGBColorSpace;
          applyNearest(texture);
          this.frames[facing][frame] = texture;
          this.ownedTextures.push(texture);
          // 若当前姿势正显示该槽位的备用帧，立即换成真实贴图。
          if (this.facing === facing && this.frame === frame) {
            this.applyPose();
          }
        });
      });
    });
  }

  private applyPose(): void {
    if (this.disposed) {
      return;
    }
    const texture = this.frames[this.facing][this.frame];
    if (this.material.map !== texture) {
      // 两张 2D 纹理间互换不需要重编译着色器，无需 material.needsUpdate。
      this.material.map = texture;
    }
    const scaleX = this.flipX ? -this.baseScaleX : this.baseScaleX;
    if (this.object3d.scale.x !== scaleX) {
      this.object3d.scale.x = scaleX;
    }
  }
}
