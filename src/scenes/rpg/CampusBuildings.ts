import Phaser from "phaser";
import {
  CAMPUS_LANDMARK_LABEL_TOP_INSET,
  ZIJINGANG_CAMPUS_LANDMARKS,
  ZIJINGANG_PLATE,
  type CampusScaleClass
} from "./ZijingangCampusLayout";

// 分层约定：校园底图 depth 0；建筑遮挡层是同源裁剪 overlay，depth = 该建筑 footprint 南缘 y；
// 玩家 depth = player.y + 30，于是玩家在南缘以北（建筑后方）被 overlay 盖住，以南（前方）盖住建筑。
export interface CampusBuildingTransform {
  offsetX?: number;
  offsetY?: number;
  scaleX?: number;
  scaleY?: number;
  rotation?: number;
}

export interface CampusBuildingState {
  id: string;
  label: string;
  /** 经 transform 后的有效中心（base + offset） */
  center: { x: number; y: number };
  /** 经 scale 后的有效尺寸（旋转前的本地尺寸） */
  footprint: { width: number; height: number };
  /** 有效几何（含 rotation 包围盒）的南缘 y，即 overlay 的 depth */
  occlusionDepth: number;
  transform: Required<CampusBuildingTransform>;
}

// athletics / landscape 是平地与园林，不参与前后遮挡
const OCCLUDING_SCALE_CLASSES: ReadonlySet<CampusScaleClass> = new Set(["landmark", "major", "campus_block"]);
const OVERLAY_TEXTURE_PREFIX = "campus-building-overlay-";

const IDENTITY_TRANSFORM: Required<CampusBuildingTransform> = {
  offsetX: 0,
  offsetY: 0,
  scaleX: 1,
  scaleY: 1,
  rotation: 0
};

interface CampusBuildingEntry {
  id: string;
  label: string;
  baseCenter: { x: number; y: number };
  baseFootprint: { width: number; height: number };
  occlusionPolygons: readonly (readonly Readonly<{ x: number; y: number }>[])[];
  transform: Required<CampusBuildingTransform>;
  textureKey: string;
  // overlay 图像中心与 footprint 中心的固定差值（源矩形取整 / clamp 产生），变换时保持像素对齐
  imageOffsetX: number;
  imageOffsetY: number;
  overlay?: Phaser.GameObjects.Image;
}

interface EffectiveGeometry {
  centerX: number;
  centerY: number;
  width: number;
  height: number;
  aabbWidth: number;
  aabbHeight: number;
}

function resolveEffectiveGeometry(entry: CampusBuildingEntry): EffectiveGeometry {
  const { transform } = entry;
  const width = entry.baseFootprint.width * Math.abs(transform.scaleX);
  const height = entry.baseFootprint.height * Math.abs(transform.scaleY);
  const cos = Math.abs(Math.cos(transform.rotation));
  const sin = Math.abs(Math.sin(transform.rotation));
  return {
    centerX: entry.baseCenter.x + transform.offsetX,
    centerY: entry.baseCenter.y + transform.offsetY,
    width,
    height,
    aabbWidth: width * cos + height * sin,
    aabbHeight: width * sin + height * cos
  };
}

export class CampusBuildingLayer {
  onBuildingChanged?: (id: string, state: CampusBuildingState) => void;

  private readonly entries = new Map<string, CampusBuildingEntry>();
  private overlays: Phaser.GameObjects.Image[] = [];
  private built = false;

  constructor(private readonly scene: Phaser.Scene, private readonly plateTextureKey: string) {
    Object.values(ZIJINGANG_CAMPUS_LANDMARKS).forEach((landmark) => {
      if (!landmark.occlusionEnabled || !OCCLUDING_SCALE_CLASSES.has(landmark.scaleClass)) {
        return;
      }
      this.entries.set(landmark.id, {
        id: landmark.id,
        label: landmark.label,
        baseCenter: { x: landmark.worldCenter.x, y: landmark.worldCenter.y },
        baseFootprint: { width: landmark.visualFootprint.width, height: landmark.visualFootprint.height },
        occlusionPolygons: landmark.occlusionPolygons,
        transform: { ...IDENTITY_TRANSFORM },
        textureKey: `${OVERLAY_TEXTURE_PREFIX}${landmark.id}`,
        imageOffsetX: 0,
        imageOffsetY: 0
      });
    });
    // 场景重启时 display list 由场景销毁，这里只重置簿记以便再次 build()
    scene.events.once(Phaser.Scenes.Events.SHUTDOWN, this.handleSceneShutdown, this);
  }

  /** 创建全部遮挡 overlay，返回创建的对象（供小地图 camera ignore） */
  build(): Phaser.GameObjects.Image[] {
    if (this.built) {
      return [...this.overlays];
    }
    if (!this.scene.textures.exists(this.plateTextureKey)) {
      throw new Error(`CampusBuildingLayer: plate texture "${this.plateTextureKey}" must be loaded before build()`);
    }
    const texture = this.scene.textures.get(this.plateTextureKey);
    const source = texture.getSourceImage() as CanvasImageSource;
    this.entries.forEach((entry) => {
      const halfWidth = entry.baseFootprint.width / 2;
      const halfHeight = entry.baseFootprint.height / 2;
      // 源矩形对齐到整像素并 clamp 在 plate 内：overlay 像素与底图逐像素一致，静止时视觉零变化
      const left = Phaser.Math.Clamp(Math.floor(entry.baseCenter.x - halfWidth), 0, ZIJINGANG_PLATE.width);
      const top = Phaser.Math.Clamp(Math.floor(entry.baseCenter.y - halfHeight), 0, ZIJINGANG_PLATE.height);
      const right = Phaser.Math.Clamp(Math.ceil(entry.baseCenter.x + halfWidth), 0, ZIJINGANG_PLATE.width);
      const bottom = Phaser.Math.Clamp(Math.ceil(entry.baseCenter.y + halfHeight), 0, ZIJINGANG_PLATE.height);
      const width = right - left;
      const height = bottom - top;
      if (width <= 0 || height <= 0) {
        return;
      }
      if (this.scene.textures.exists(entry.textureKey)) {
        this.scene.textures.remove(entry.textureKey);
      }
      const overlayTexture = this.scene.textures.createCanvas(entry.textureKey, width, height);
      if (!overlayTexture) {
        throw new Error(`CampusBuildingLayer: failed to create overlay texture "${entry.textureKey}"`);
      }
      const context = overlayTexture.getContext();
      context.save();
      context.beginPath();
      entry.occlusionPolygons.forEach((polygon) => {
        polygon.forEach((point, index) => {
          const x = point.x - left;
          const y = point.y - top;
          if (index === 0) {
            context.moveTo(x, y);
          } else {
            context.lineTo(x, y);
          }
        });
        context.closePath();
      });
      context.clip();
      context.drawImage(source, left, top, width, height, 0, 0, width, height);
      context.restore();
      overlayTexture.refresh();
      overlayTexture.setFilter(Phaser.Textures.FilterMode.LINEAR);
      entry.imageOffsetX = left + width / 2 - entry.baseCenter.x;
      entry.imageOffsetY = top + height / 2 - entry.baseCenter.y;
      const overlay = this.scene.add.image(
        entry.baseCenter.x + entry.imageOffsetX,
        entry.baseCenter.y + entry.imageOffsetY,
        entry.textureKey
      );
      overlay.setData("campusBuildingOverlay", true).setData("buildingId", entry.id);
      entry.overlay = overlay;
      this.syncOverlay(entry);
      this.overlays.push(overlay);
    });
    this.built = true;
    return [...this.overlays];
  }

  getBuilding(id: string): CampusBuildingState | undefined {
    const entry = this.entries.get(id);
    return entry ? this.toState(entry) : undefined;
  }

  listBuildings(): CampusBuildingState[] {
    return [...this.entries.values()].map((entry) => this.toState(entry));
  }

  /**
   * 玩家只有在建筑实际横向轮廓内且位于南缘之后时才会被遮挡。
   * 脚底在建筑侧面时将 overlay 放到玩家下方，避免矩形裁片切掉半个角色。
   */
  updateOcclusionForPlayer(playerX: number, playerY: number, playerDepth: number): void {
    this.entries.forEach((entry) => {
      const overlay = entry.overlay;
      if (!overlay) {
        return;
      }
      const geometry = resolveEffectiveGeometry(entry);
      const left = geometry.centerX - geometry.aabbWidth / 2;
      const right = geometry.centerX + geometry.aabbWidth / 2;
      const south = geometry.centerY + geometry.aabbHeight / 2;
      const behind = playerY < south;
      const horizontallyBehind = playerX >= left && playerX <= right;
      overlay.setDepth(behind && !horizontallyBehind ? playerDepth - 1 : south);
    });
  }

  /**
   * 移动/变形建筑：更新 overlay 位置/缩放/旋转、重算 occlusion depth（南缘随 transform 变化），并触发 onBuildingChanged。
   * 只更新传入的字段，未指定的字段保持当前值；rotation 为弧度。
   */
  applyTransform(id: string, transform: CampusBuildingTransform): boolean {
    const entry = this.entries.get(id);
    if (!entry) {
      return false;
    }
    (Object.keys(transform) as (keyof CampusBuildingTransform)[]).forEach((key) => {
      const value = transform[key];
      if (value !== undefined) {
        entry.transform[key] = value;
      }
    });
    this.syncOverlay(entry);
    this.onBuildingChanged?.(id, this.toState(entry));
    return true;
  }

  resetTransform(id: string): boolean {
    const entry = this.entries.get(id);
    if (!entry) {
      return false;
    }
    entry.transform = { ...IDENTITY_TRANSFORM };
    this.syncOverlay(entry);
    this.onBuildingChanged?.(id, this.toState(entry));
    return true;
  }

  /** 地标标签锚点（建筑顶部内侧），随 transform 移动。 */
  getLabelAnchor(id: string): { x: number; y: number } | undefined {
    const entry = this.entries.get(id);
    if (!entry) {
      return undefined;
    }
    const geometry = resolveEffectiveGeometry(entry);
    return {
      x: geometry.centerX,
      y: geometry.centerY - geometry.aabbHeight / 2 + CAMPUS_LANDMARK_LABEL_TOP_INSET
    };
  }

  destroy(): void {
    this.scene.events.off(Phaser.Scenes.Events.SHUTDOWN, this.handleSceneShutdown, this);
    this.overlays.forEach((overlay) => overlay.destroy());
    this.overlays = [];
    this.entries.forEach((entry) => {
      if (this.scene.textures.exists(entry.textureKey)) {
        this.scene.textures.remove(entry.textureKey);
      }
    });
    this.entries.forEach((entry) => {
      entry.overlay = undefined;
    });
    this.built = false;
    this.onBuildingChanged = undefined;
  }

  private syncOverlay(entry: CampusBuildingEntry): void {
    const overlay = entry.overlay;
    if (!overlay) {
      return;
    }
    const geometry = resolveEffectiveGeometry(entry);
    overlay.setPosition(geometry.centerX + entry.imageOffsetX, geometry.centerY + entry.imageOffsetY);
    overlay.setScale(entry.transform.scaleX, entry.transform.scaleY);
    overlay.setRotation(entry.transform.rotation);
    overlay.setDepth(geometry.centerY + geometry.aabbHeight / 2);
  }

  private toState(entry: CampusBuildingEntry): CampusBuildingState {
    const geometry = resolveEffectiveGeometry(entry);
    return {
      id: entry.id,
      label: entry.label,
      center: { x: geometry.centerX, y: geometry.centerY },
      footprint: { width: geometry.width, height: geometry.height },
      occlusionDepth: geometry.centerY + geometry.aabbHeight / 2,
      transform: { ...entry.transform }
    };
  }

  private handleSceneShutdown(): void {
    this.overlays = [];
    this.entries.forEach((entry) => {
      entry.overlay = undefined;
      if (this.scene.textures.exists(entry.textureKey)) {
        this.scene.textures.remove(entry.textureKey);
      }
    });
    this.built = false;
    this.onBuildingChanged = undefined;
  }
}
