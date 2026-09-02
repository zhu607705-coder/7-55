import Phaser from "phaser";

export type RpgInteriorDoorMotion = "closed" | "opening" | "open" | "closing";
export type RpgInteriorDoorLeafMotion =
  | "single-swing"
  | "single-slide"
  | "double-swing"
  | "double-fold"
  | "double-slide";

export interface RpgInteriorDoorForegroundSpec {
  left: number;
  top: number;
  right: number;
  bottom: number;
  sortY: number;
  sourceCrop?: {
    left: number;
    top: number;
    right: number;
    bottom: number;
  };
  displayScale?: number;
}

export interface RpgInteriorDoorPalette {
  portal: number;
  spill: number;
  leaf: number;
  inset: number;
  trim: number;
  handle: number;
}

export interface RpgInteriorDoorLeafTextureSpec {
  key: string;
  frame?: string | number;
}

export interface RpgInteriorDoorSpec {
  id: string;
  centerX: number;
  centerY: number;
  openingWidth: number;
  openingHeight: number;
  passableProgress?: number;
  durationMs?: number;
  motion: RpgInteriorDoorLeafMotion;
  openOffset?: number;
  openAngle?: number;
  motionEase?: string;
  depth: number;
  palette: RpgInteriorDoorPalette;
  portalAlpha?: number;
  spillAlphaClosed?: number;
  spillAlphaOpen?: number;
  leafTextures?: {
    single?: RpgInteriorDoorLeafTextureSpec;
    left?: RpgInteriorDoorLeafTextureSpec;
    right?: RpgInteriorDoorLeafTextureSpec;
  };
  hideLeavesWhenOpen?: boolean;
  foreground?: RpgInteriorDoorForegroundSpec & { textureKey: string };
}

export interface RpgInteriorDoorDebugSnapshot {
  id: string;
  state: RpgInteriorDoorMotion;
  progress: number;
  passable: boolean;
  actorOccluded: boolean;
}

const DEFAULT_PASSABLE_PROGRESS = 0.38;

function createLeafPanel(
  scene: Phaser.Scene,
  width: number,
  height: number,
  palette: RpgInteriorDoorPalette,
  handleX: number,
  texture?: RpgInteriorDoorLeafTextureSpec
): Phaser.GameObjects.Container {
  if (texture) {
    const image = scene.add.image(0, 0, texture.key, texture.frame)
      .setDisplaySize(width, height);
    return scene.add.container(0, 0, [image]);
  }
  const shadow = scene.add.rectangle(2, 3, width, height, 0x000000, 0.28);
  const panel = scene.add.rectangle(0, 0, width, height, palette.leaf, 1)
    .setStrokeStyle(3, palette.trim, 1);
  const upperInset = scene.add.rectangle(0, -height * 0.23, width * 0.72, height * 0.31, palette.inset, 0.92)
    .setStrokeStyle(2, palette.trim, 0.88);
  const lowerInset = scene.add.rectangle(0, height * 0.23, width * 0.72, height * 0.31, palette.inset, 0.92)
    .setStrokeStyle(2, palette.trim, 0.88);
  const handle = scene.add.circle(handleX, 0, Math.max(2, Math.min(4, width * 0.08)), palette.handle, 1)
    .setStrokeStyle(1, palette.trim, 0.9);
  return scene.add.container(0, 0, [shadow, panel, upperInset, lowerInset, handle]);
}

export function createRpgDoorForeground(
  scene: Phaser.Scene,
  textureKey: string,
  spec: RpgInteriorDoorForegroundSpec
): Phaser.GameObjects.Image {
  const crop = spec.sourceCrop ?? spec;
  return scene.add.image(spec.left, spec.top, textureKey, "__BASE")
    .setOrigin(0)
    .setCrop(crop.left, crop.top, crop.right - crop.left, crop.bottom - crop.top)
    .setScale(spec.displayScale ?? 1)
    .setDepth(-900)
    .setVisible(false);
}

export function updateRpgDoorForeground(
  foreground: Phaser.GameObjects.Image,
  actor: Phaser.Physics.Arcade.Sprite,
  spec: RpgInteriorDoorForegroundSpec,
  depthOffset = 4
): boolean {
  const body = actor.body as Phaser.Physics.Arcade.Body | null;
  const footY = body?.bottom ?? actor.y;
  const actorBounds = actor.getBounds();
  const cropBounds = new Phaser.Geom.Rectangle(
    spec.left,
    spec.top,
    spec.right - spec.left,
    spec.bottom - spec.top
  );
  const overlaps = Phaser.Geom.Intersects.RectangleToRectangle(actorBounds, cropBounds);
  const actorBehind = overlaps && footY < spec.sortY;
  foreground
    .setDepth(actorBehind ? actor.depth + depthOffset : -900)
    .setVisible(actorBehind);
  return actorBehind;
}

export class RpgInteriorDoorRuntime {
  readonly passableDelayMs: number;

  private readonly scene: Phaser.Scene;
  private readonly spec: RpgInteriorDoorSpec;
  private readonly portal: Phaser.GameObjects.Rectangle;
  private readonly spill: Phaser.GameObjects.Rectangle;
  private readonly leaves: Phaser.GameObjects.Container[];
  private readonly foreground: Phaser.GameObjects.Image | null;
  private readonly durationMs: number;
  private motion: RpgInteriorDoorMotion = "closed";
  private progress = 0;
  private actorOccluded = false;
  private destroyed = false;
  private transitionStartedAt = 0;
  private transitionFrom = 0;
  private transitionTo = 0;

  constructor(
    scene: Phaser.Scene,
    spec: RpgInteriorDoorSpec,
    reducedMotion = false
  ) {
    this.scene = scene;
    this.spec = spec;
    const durationMs = reducedMotion ? Math.min(120, spec.durationMs ?? 360) : spec.durationMs ?? 360;
    this.durationMs = durationMs;
    const passableProgress = spec.passableProgress ?? DEFAULT_PASSABLE_PROGRESS;
    this.passableDelayMs = Math.round(durationMs * passableProgress);

    this.portal = scene.add.rectangle(
      spec.centerX,
      spec.centerY,
      spec.openingWidth,
      spec.openingHeight,
      spec.palette.portal,
      spec.portalAlpha ?? 1
    ).setDepth(spec.depth - 3);
    this.spill = scene.add.rectangle(
      spec.centerX,
      spec.centerY + spec.openingHeight * 0.18,
      spec.openingWidth * 0.8,
      spec.openingHeight * 0.66,
      spec.palette.spill,
      0.2
    ).setDepth(spec.depth - 2);

    this.leaves = this.createLeaves();
    this.leaves.forEach((leaf) => leaf.setDepth(spec.depth));

    this.foreground = spec.foreground
      ? createRpgDoorForeground(scene, spec.foreground.textureKey, spec.foreground)
      : null;
    this.setInstant(false);
  }

  open(): void {
    if (this.motion === "open" || this.motion === "opening") return;
    this.stopTweens();
    this.motion = "opening";
    this.beginProgressTransition(1);
    this.animateLeaves(true);
    this.scene.tweens.add({
      targets: this.spill,
      alpha: this.spec.spillAlphaOpen ?? 0.7,
      duration: this.durationMs,
      ease: this.spec.motionEase ?? "Stepped"
    });
  }

  close(): void {
    if (this.motion === "closed" || this.motion === "closing") return;
    this.stopTweens();
    this.motion = "closing";
    this.beginProgressTransition(0);
    this.animateLeaves(false);
    this.scene.tweens.add({
      targets: this.spill,
      alpha: this.spec.spillAlphaClosed ?? 0.2,
      duration: this.durationMs,
      ease: this.spec.motionEase ?? "Stepped"
    });
  }

  setInstant(open: boolean): void {
    this.stopTweens();
    this.progress = open ? 1 : 0;
    this.motion = open ? "open" : "closed";
    this.applyLeafTransform(open ? 1 : 0);
    if (this.spec.hideLeavesWhenOpen) {
      this.leaves.forEach((leaf) => leaf.setAlpha(open ? 0 : 1));
    }
    this.spill.setAlpha(open
      ? this.spec.spillAlphaOpen ?? 0.7
      : this.spec.spillAlphaClosed ?? 0.2);
  }

  updateActorOcclusion(actor: Phaser.Physics.Arcade.Sprite): void {
    this.updateProgress();
    this.actorOccluded = this.foreground && this.spec.foreground
      ? updateRpgDoorForeground(this.foreground, actor, this.spec.foreground)
      : false;
    const actorBounds = actor.getBounds();
    const doorBounds = new Phaser.Geom.Rectangle(
      this.spec.centerX - this.spec.openingWidth / 2,
      this.spec.centerY - this.spec.openingHeight / 2,
      this.spec.openingWidth,
      this.spec.openingHeight
    );
    if (Phaser.Geom.Intersects.RectangleToRectangle(actorBounds, doorBounds)) {
      this.leaves.forEach((leaf) => leaf.setDepth(actor.depth + 2));
    } else {
      this.leaves.forEach((leaf) => leaf.setDepth(this.spec.depth));
    }
  }

  getDebugSnapshot(): RpgInteriorDoorDebugSnapshot {
    this.updateProgress();
    return {
      id: this.spec.id,
      state: this.motion,
      progress: Number(this.progress.toFixed(3)),
      passable: this.progress >= (this.spec.passableProgress ?? DEFAULT_PASSABLE_PROGRESS),
      actorOccluded: this.actorOccluded
    };
  }

  reject(): void {
    if (this.motion !== "closed") return;
    this.stopTweens();
    this.leaves.forEach((leaf) => {
      this.scene.tweens.add({
        targets: leaf,
        x: leaf.x + 5,
        duration: 55,
        yoyo: true,
        repeat: 3,
        ease: this.spec.motionEase ?? "Stepped",
        onComplete: () => this.applyLeafTransform(0)
      });
    });
  }

  destroy(): void {
    if (this.destroyed) return;
    this.destroyed = true;
    this.stopTweens();
    if (this.foreground?.active) this.foreground.destroy();
    this.leaves.forEach((leaf) => {
      if (leaf.active) leaf.destroy(true);
    });
    if (this.spill.active) this.spill.destroy();
    if (this.portal.active) this.portal.destroy();
  }

  private createLeaves(): Phaser.GameObjects.Container[] {
    const { openingWidth, openingHeight, centerX, centerY, motion, palette, leafTextures } = this.spec;
    if (motion === "single-swing" || motion === "single-slide") {
      const leaf = createLeafPanel(
        this.scene,
        openingWidth,
        openingHeight,
        palette,
        openingWidth * 0.32,
        leafTextures?.single
      );
      leaf.setPosition(centerX - openingWidth / 2, centerY);
      leaf.getAll().forEach((child) => {
        if ("x" in child && typeof child.x === "number") child.x += openingWidth / 2;
      });
      return [leaf];
    }
    const leafWidth = openingWidth / 2;
    const left = createLeafPanel(
      this.scene,
      leafWidth,
      openingHeight,
      palette,
      leafWidth * 0.32,
      leafTextures?.left
    );
    const right = createLeafPanel(
      this.scene,
      leafWidth,
      openingHeight,
      palette,
      -leafWidth * 0.32,
      leafTextures?.right
    );
    if (motion === "double-swing" || motion === "double-fold") {
      left.setPosition(centerX - openingWidth / 2, centerY);
      right.setPosition(centerX + openingWidth / 2, centerY);
      left.getAll().forEach((child) => {
        if ("x" in child && typeof child.x === "number") child.x += leafWidth / 2;
      });
      right.getAll().forEach((child) => {
        if ("x" in child && typeof child.x === "number") child.x -= leafWidth / 2;
      });
    } else {
      left.setPosition(centerX - leafWidth / 2, centerY);
      right.setPosition(centerX + leafWidth / 2, centerY);
    }
    return [left, right];
  }

  private animateLeaves(open: boolean): void {
    const duration = this.durationMs;
    const targets = this.targetLeafTransforms(open ? 1 : 0);
    this.leaves.forEach((leaf, index) => {
      this.scene.tweens.add({
        targets: leaf,
        ...targets[index],
        ...(this.spec.hideLeavesWhenOpen ? { alpha: open ? 0 : 1 } : {}),
        duration,
        ease: this.spec.motionEase ?? "Stepped",
        onComplete: index === this.leaves.length - 1 ? () => {
          this.progress = open ? 1 : 0;
          this.motion = open ? "open" : "closed";
        } : undefined
      });
    });
  }

  private targetLeafTransforms(progress: number): Array<{ x: number; angle: number; scaleX: number }> {
    const { centerX, openingWidth, motion } = this.spec;
    if (motion === "single-slide") {
      return [{
        x: centerX - openingWidth / 2 - (this.spec.openOffset ?? openingWidth * 0.82) * progress,
        angle: 0,
        scaleX: 1
      }];
    }
    if (motion === "single-swing") {
      return [{
        x: centerX - openingWidth / 2,
        angle: 0,
        scaleX: Phaser.Math.Linear(1, 0.2, progress)
      }];
    }
    if (motion === "double-swing") {
      return [
        { x: centerX - openingWidth / 2, angle: -(this.spec.openAngle ?? 78) * progress, scaleX: 1 },
        { x: centerX + openingWidth / 2, angle: (this.spec.openAngle ?? 78) * progress, scaleX: 1 }
      ];
    }
    if (motion === "double-fold") {
      const foldedScale = Phaser.Math.Linear(1, 0.18, progress);
      return [
        { x: centerX - openingWidth / 2, angle: 0, scaleX: foldedScale },
        { x: centerX + openingWidth / 2, angle: 0, scaleX: foldedScale }
      ];
    }
    const leafWidth = openingWidth / 2;
    const offset = (this.spec.openOffset ?? leafWidth * 0.92) * progress;
    return [
      { x: centerX - leafWidth / 2 - offset, angle: 0, scaleX: 1 },
      { x: centerX + leafWidth / 2 + offset, angle: 0, scaleX: 1 }
    ];
  }

  private applyLeafTransform(progress: number): void {
    const transforms = this.targetLeafTransforms(progress);
    this.leaves.forEach((leaf, index) => leaf
      .setPosition(transforms[index].x, this.spec.centerY)
      .setAngle(transforms[index].angle)
      .setScale(transforms[index].scaleX, 1));
  }

  private beginProgressTransition(target: number): void {
    this.transitionStartedAt = this.scene.time.now;
    this.transitionFrom = this.progress;
    this.transitionTo = target;
  }

  private updateProgress(): void {
    if (this.motion !== "opening" && this.motion !== "closing") return;
    const duration = Math.max(1, this.durationMs);
    const elapsed = Phaser.Math.Clamp((this.scene.time.now - this.transitionStartedAt) / duration, 0, 1);
    this.progress = Phaser.Math.Linear(this.transitionFrom, this.transitionTo, elapsed);
  }

  private stopTweens(): void {
    this.scene.tweens.killTweensOf([...this.leaves, this.spill]);
  }
}
