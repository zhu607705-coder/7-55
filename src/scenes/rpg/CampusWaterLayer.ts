import Phaser from "phaser";
import waterOverlayData from "../../data/maps/zijingang-campus-water-overlay.json";
import {
  ZIJINGANG_CAMPUS_WATER_KEY,
  ZIJINGANG_CAMPUS_WATER_MASK_KEY
} from "./ZijingangLandmarkAssets";

interface CampusWaterTileData {
  x: number;
  y: number;
  width: number;
  height: number;
  maskIndex: number;
}

interface CampusWaterOverlayData {
  version: number;
  world: { width: number; height: number };
  tileSize: number;
  animation: {
    frameCount: number;
    frameWidth: number;
    frameHeight: number;
    frameDurationMs: number;
    sampling: "nearest";
  };
  rendering: {
    edgeFeatherRadius: number;
    naturalEdge: "feathered";
    roadEdge: "hard";
    maskAtlas: {
      columns: number;
      rows: number;
      cellSize: number;
      width: number;
      height: number;
    };
    embeddedWaterRegions: Array<{ id: string; bounds: number[] }>;
  };
  mask: {
    encoding: "rgba-alpha-atlas";
  };
  tiles: CampusWaterTileData[];
}

interface CampusWaterTileRuntime {
  key: string;
  texture: Phaser.Textures.CanvasTexture;
  image: Phaser.GameObjects.Image;
  data: CampusWaterTileData;
}

const overlay = waterOverlayData as CampusWaterOverlayData;
const WATER_DEPTH = 1;
const WATER_TILE_TEXTURE_PREFIX = "zijingang-campus-water-tile";

export interface CampusWaterMaskWorldRect {
  x: number;
  y: number;
  width: number;
  height: number;
}

/**
 * Remove final-mask water pixels from a source-aligned foreground canvas.
 *
 * Campus building occlusion crops sit above the animated water. Without this
 * pass, their same-source plate pixels paint irregular pieces of the retired
 * water texture back over the new surface around Crescent Building and the
 * Qizhen right bank.
 */
export function eraseCampusAnimatedWaterFromContext(
  context: CanvasRenderingContext2D,
  maskSource: CanvasImageSource,
  bounds: CampusWaterMaskWorldRect
): void {
  const { columns, cellSize } = overlay.rendering.maskAtlas;
  const boundsRight = bounds.x + bounds.width;
  const boundsBottom = bounds.y + bounds.height;

  context.save();
  context.globalCompositeOperation = "destination-out";
  context.imageSmoothingEnabled = false;
  overlay.tiles.forEach((tile) => {
    const left = Math.max(bounds.x, tile.x);
    const top = Math.max(bounds.y, tile.y);
    const right = Math.min(boundsRight, tile.x + tile.width);
    const bottom = Math.min(boundsBottom, tile.y + tile.height);
    if (left >= right || top >= bottom) return;

    const sourceX = (tile.maskIndex % columns) * cellSize + left - tile.x;
    const sourceY = Math.floor(tile.maskIndex / columns) * cellSize + top - tile.y;
    context.drawImage(
      maskSource,
      sourceX,
      sourceY,
      right - left,
      bottom - top,
      left - bounds.x,
      top - bounds.y,
      right - left,
      bottom - top
    );
  });
  context.restore();
}

/**
 * Canvas-native animated water for the source-sized Zijin'gang campus plate.
 *
 * The authored grayscale alpha atlas preserves antialiased shore coverage and
 * manual gray transitions without allocating one 4516x3420 runtime surface.
 */
export class CampusWaterLayer {
  private readonly tiles: CampusWaterTileRuntime[] = [];
  private waterSource!: CanvasImageSource;
  private maskSource!: CanvasImageSource;
  private animationStartedAt = 0;
  private currentFrame = -1;
  private built = false;
  private destroyed = false;

  constructor(private readonly scene: Phaser.Scene) {}

  build(): Phaser.GameObjects.Image[] {
    if (this.built) {
      return this.tiles.map((tile) => tile.image);
    }
    this.validateContract();

    const waterTexture = this.scene.textures.get(ZIJINGANG_CAMPUS_WATER_KEY);
    waterTexture.setFilter(Phaser.Textures.FilterMode.NEAREST);
    this.waterSource = waterTexture.getSourceImage() as CanvasImageSource;
    this.maskSource = this.scene.textures
      .get(ZIJINGANG_CAMPUS_WATER_MASK_KEY)
      .getSourceImage() as CanvasImageSource;

    overlay.tiles.forEach((data, index) => {
      const key = `${WATER_TILE_TEXTURE_PREFIX}-${index}`;
      if (this.scene.textures.exists(key)) {
        this.scene.textures.remove(key);
      }
      const texture = this.scene.textures.createCanvas(key, data.width, data.height);
      if (!texture) {
        throw new Error(`CampusWaterLayer: failed to create tile texture "${key}"`);
      }
      texture.setFilter(Phaser.Textures.FilterMode.NEAREST);
      const image = this.scene.add.image(data.x, data.y, key)
        .setOrigin(0)
        .setDepth(WATER_DEPTH)
        .setData("campusAnimatedWater", true)
        .setData("campusWaterTileIndex", index);
      this.tiles.push({ key, texture, image, data });
    });

    this.animationStartedAt = this.scene.time.now;
    this.renderFrame(0);
    this.scene.events.on(Phaser.Scenes.Events.UPDATE, this.handleUpdate, this);
    this.scene.events.once(Phaser.Scenes.Events.SHUTDOWN, this.destroy, this);
    this.scene.events.once(Phaser.Scenes.Events.DESTROY, this.destroy, this);
    this.built = true;
    return this.tiles.map((tile) => tile.image);
  }

  destroy(): void {
    if (this.destroyed) return;
    this.destroyed = true;
    this.scene.events.off(Phaser.Scenes.Events.UPDATE, this.handleUpdate, this);
    this.scene.events.off(Phaser.Scenes.Events.SHUTDOWN, this.destroy, this);
    this.scene.events.off(Phaser.Scenes.Events.DESTROY, this.destroy, this);
    this.tiles.forEach(({ image }) => image.destroy());
    this.tiles.forEach(({ key }) => {
      if (this.scene.textures.exists(key)) {
        this.scene.textures.remove(key);
      }
    });
    this.tiles.length = 0;
    this.currentFrame = -1;
    this.built = false;
  }

  private handleUpdate(): void {
    const elapsed = Math.max(0, this.scene.time.now - this.animationStartedAt);
    const nextFrame = Math.floor(elapsed / overlay.animation.frameDurationMs)
      % overlay.animation.frameCount;
    if (nextFrame !== this.currentFrame) {
      this.renderFrame(nextFrame);
    }
  }

  private renderFrame(frameIndex: number): void {
    const { frameWidth, frameHeight } = overlay.animation;
    const { columns, cellSize } = overlay.rendering.maskAtlas;
    const waterSourceX = frameIndex * frameWidth;
    this.tiles.forEach(({ texture, data }) => {
      const context = texture.getContext();
      const maskSourceX = (data.maskIndex % columns) * cellSize;
      const maskSourceY = Math.floor(data.maskIndex / columns) * cellSize;
      context.save();
      context.clearRect(0, 0, data.width, data.height);
      context.imageSmoothingEnabled = false;
      context.drawImage(
        this.waterSource,
        waterSourceX,
        0,
        frameWidth,
        frameHeight,
        0,
        0,
        frameWidth,
        frameHeight
      );
      context.globalCompositeOperation = "destination-in";
      context.drawImage(
        this.maskSource,
        maskSourceX,
        maskSourceY,
        data.width,
        data.height,
        0,
        0,
        data.width,
        data.height
      );
      context.restore();
      texture.refresh();
    });
    this.currentFrame = frameIndex;
  }

  private validateContract(): void {
    const { maskAtlas, embeddedWaterRegions } = overlay.rendering;
    if (overlay.version !== 1) {
      throw new Error(`CampusWaterLayer: unsupported mask version ${overlay.version}`);
    }
    if (
      overlay.tileSize !== 128
      || overlay.animation.frameCount !== 3
      || overlay.animation.frameWidth !== 128
      || overlay.animation.frameHeight !== 128
      || overlay.animation.frameDurationMs !== 500
      || overlay.animation.sampling !== "nearest"
      || overlay.mask.encoding !== "rgba-alpha-atlas"
      || overlay.rendering.edgeFeatherRadius !== 3
      || overlay.rendering.naturalEdge !== "feathered"
      || overlay.rendering.roadEdge !== "hard"
      || maskAtlas.cellSize !== overlay.tileSize
      || maskAtlas.width !== maskAtlas.columns * maskAtlas.cellSize
      || maskAtlas.height !== maskAtlas.rows * maskAtlas.cellSize
      || embeddedWaterRegions.length !== 1
      || embeddedWaterRegions[0]?.id !== "north_mid_river"
    ) {
      throw new Error("CampusWaterLayer: animated water contract no longer matches the approved alpha atlas");
    }

    const usedMaskIndices = new Set<number>();
    overlay.tiles.forEach((tile, index) => {
      if (
        tile.x < 0
        || tile.y < 0
        || tile.width <= 0
        || tile.height <= 0
        || tile.width > overlay.tileSize
        || tile.height > overlay.tileSize
        || tile.x + tile.width > overlay.world.width
        || tile.y + tile.height > overlay.world.height
        || tile.x % overlay.tileSize !== 0
        || tile.y % overlay.tileSize !== 0
        || !Number.isInteger(tile.maskIndex)
        || tile.maskIndex < 0
        || tile.maskIndex >= maskAtlas.columns * maskAtlas.rows
        || usedMaskIndices.has(tile.maskIndex)
      ) {
        throw new Error(`CampusWaterLayer: tile ${index} has an invalid world or mask-atlas placement`);
      }
      usedMaskIndices.add(tile.maskIndex);
    });
  }
}
