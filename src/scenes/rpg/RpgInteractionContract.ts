import type { ItemId } from "../../core/types";

export type RpgRealityMode = "light" | "dark";

export const RPG_REALITY_MODE_CONTRACT = {
  dark: {
    label: "深色观察",
    shortHint: "深色模式只读取线索和异常，不执行实体操作。"
  },
  light: {
    label: "浅色操作",
    shortHint: "浅色模式执行移动、拖放、清洁、付款和设备操作。"
  }
} as const satisfies Record<RpgRealityMode, {
  label: string;
  shortHint: string;
}>;

export interface RpgWorldPoint {
  x: number;
  y: number;
}

export type RpgCardinalFacing = "up" | "down" | "left" | "right";

export type RpgFacingRequirement = RpgCardinalFacing | "toward_target";

export const RPG_LOOSE_FACING = {
  requiredFacing: "toward_target",
  // A diagonal approach accepts either adjacent cardinal direction while a
  // direction pointing away from the visible target remains invalid.
  facingToleranceDegrees: 90
} as const;

export const RPG_ANY_FACING = ["up", "down", "left", "right"] as const;

export interface RpgSpatialInteractionTarget {
  id: string;
  label: string;
  /** Visible entity or control center in world coordinates. */
  x: number;
  y: number;
  /**
   * Legacy checkpoint/spawn hint. It is never used as an interaction gate.
   * Runtime interaction is measured from the player's foot point to the
   * visible object bounds, so scenes do not require one exact floor spot.
   */
  stand?: RpgWorldPoint;
  proximity: number;
  /** Visible entity bounds, always used for proximity and facing checks. */
  width?: number;
  height?: number;
  /** Exact item drop bounds centered on x/y. */
  dropWidth?: number;
  dropHeight?: number;
  acceptedItem?: ItemId;
  requiredMode?: RpgRealityMode;
  /**
   * Fixed direction for wall/counter fixtures, or toward_target for objects
   * that can be approached from several sides. Omitted targets also default
   * to toward_target, keeping facing part of the global interaction contract.
  */
  requiredFacing?: RpgFacingRequirement | readonly RpgCardinalFacing[];
  /** Item drops may opt out of facing while Space/pointer interaction keeps it. */
  dropRequiresFacing?: boolean;
  /** Forward cone used by toward_target checks. Defaults to 60 degrees. */
  facingToleranceDegrees?: number;
}

export interface RpgDropBounds {
  left: number;
  top: number;
  right: number;
  bottom: number;
  width: number;
  height: number;
}

export type RpgItemDropResultKind =
  | "accepted"
  | "missed_target"
  | "wrong_item"
  | "too_far"
  | "wrong_facing"
  | "wrong_mode";

export interface RpgItemDropResult<TTarget extends RpgSpatialInteractionTarget> {
  kind: RpgItemDropResultKind;
  target: TTarget | null;
  expectedMode?: RpgRealityMode;
}

export function getRpgDropBounds(target: RpgSpatialInteractionTarget): RpgDropBounds {
  const width = target.dropWidth ?? target.width ?? target.proximity * 2;
  const height = target.dropHeight ?? target.height ?? target.proximity * 2;
  return {
    left: target.x - width / 2,
    top: target.y - height / 2,
    right: target.x + width / 2,
    bottom: target.y + height / 2,
    width,
    height
  };
}

export function isRpgDropPointWithin(
  target: RpgSpatialInteractionTarget,
  x: number,
  y: number
): boolean {
  const bounds = getRpgDropBounds(target);
  return x >= bounds.left
    && x <= bounds.right
    && y >= bounds.top
    && y <= bounds.bottom;
}

export function distanceFromPlayerToRpgTarget(
  target: RpgSpatialInteractionTarget,
  playerX: number,
  playerY: number
): number {
  const nearest = nearestRpgTargetPoint(target, playerX, playerY);
  return Math.hypot(playerX - nearest.x, playerY - nearest.y);
}

export function nearestRpgTargetPoint(
  target: RpgSpatialInteractionTarget,
  playerX: number,
  playerY: number
): RpgWorldPoint {
  if (target.width && target.height) {
    const halfWidth = target.width / 2;
    const halfHeight = target.height / 2;
    return {
      x: Math.max(target.x - halfWidth, Math.min(playerX, target.x + halfWidth)),
      y: Math.max(target.y - halfHeight, Math.min(playerY, target.y + halfHeight))
    };
  }
  return { x: target.x, y: target.y };
}

const RPG_FACING_VECTORS: Readonly<Record<RpgCardinalFacing, RpgWorldPoint>> = {
  up: { x: 0, y: -1 },
  down: { x: 0, y: 1 },
  left: { x: -1, y: 0 },
  right: { x: 1, y: 0 }
};

export function isFacingVectorTowardRpgTarget(
  target: RpgSpatialInteractionTarget,
  playerX: number,
  playerY: number,
  facingVector: RpgWorldPoint,
  minimumForwardDot?: number
): boolean {
  const vectorLength = Math.hypot(facingVector.x, facingVector.y);
  if (vectorLength < 0.001) return false;
  const normalizedFacing = {
    x: facingVector.x / vectorLength,
    y: facingVector.y / vectorLength
  };
  const forwardThreshold = minimumForwardDot
    ?? Math.cos((target.facingToleranceDegrees ?? 60) * Math.PI / 180);
  const requirement = target.requiredFacing ?? "toward_target";
  if (typeof requirement !== "string") {
    return requirement.some((direction) => {
      const requiredVector = RPG_FACING_VECTORS[direction];
      return normalizedFacing.x * requiredVector.x + normalizedFacing.y * requiredVector.y >= 0.8;
    });
  }
  if (requirement !== "toward_target") {
    const requiredVector = RPG_FACING_VECTORS[requirement];
    return normalizedFacing.x * requiredVector.x + normalizedFacing.y * requiredVector.y >= 0.8;
  }

  const nearest = nearestRpgTargetPoint(target, playerX, playerY);
  let dx = nearest.x - playerX;
  let dy = nearest.y - playerY;
  if (dx === 0 && dy === 0) {
    dx = target.x - playerX;
    dy = target.y - playerY;
  }
  const targetDistance = Math.hypot(dx, dy);
  if (targetDistance < 0.001) return true;
  const forwardDot = (
    dx * normalizedFacing.x + dy * normalizedFacing.y
  ) / targetDistance;
  if (forwardDot >= forwardThreshold) return true;

  // A 90-degree scene tolerance treats the adjacent cardinal direction as a
  // deliberate loose-facing choice. When the nearest-edge vector is exactly
  // perpendicular, use the target center only to choose the correct quadrant:
  // lower-right accepts up/left, but still rejects down/right.
  if ((target.facingToleranceDegrees ?? 60) < 90 || Math.abs(forwardDot) > 0.0001) {
    return false;
  }
  const centerDx = target.x - playerX;
  const centerDy = target.y - playerY;
  const centerDistance = Math.hypot(centerDx, centerDy);
  if (centerDistance < 0.001) return true;
  return (
    centerDx * normalizedFacing.x + centerDy * normalizedFacing.y
  ) / centerDistance > 0.0001;
}

/**
 * Facing uses a broad forward cone so diagonal approaches accept either
 * adjacent cardinal pose. Fixed wall/counter fixtures can request one exact
 * direction through requiredFacing.
 */
export function isPlayerFacingRpgTarget(
  target: RpgSpatialInteractionTarget,
  playerX: number,
  playerY: number,
  playerFacing: RpgCardinalFacing
): boolean {
  return isFacingVectorTowardRpgTarget(
    target,
    playerX,
    playerY,
    RPG_FACING_VECTORS[playerFacing]
  );
}

export function isPlayerWithinRpgTarget(
  target: RpgSpatialInteractionTarget,
  playerX: number,
  playerY: number
): boolean {
  return distanceFromPlayerToRpgTarget(target, playerX, playerY) <= target.proximity;
}

/**
 * Assign an overlapping set of broad interaction ranges to exactly one target.
 * Visible-edge distance is authoritative; center distance and id only make an
 * exact seam deterministic, so adjacent fixtures never alternate by array order.
 */
export function findNearestRpgInteractionTarget<TTarget extends RpgSpatialInteractionTarget>(
  playerX: number,
  playerY: number,
  targets: readonly TTarget[]
): TTarget | null {
  return targets
    .map((target) => ({
      target,
      edgeDistance: distanceFromPlayerToRpgTarget(target, playerX, playerY),
      centerDistance: Math.hypot(target.x - playerX, target.y - playerY)
    }))
    .filter((candidate) => candidate.edgeDistance <= candidate.target.proximity)
    .sort((a, b) => (
      a.edgeDistance - b.edgeDistance
      || a.centerDistance - b.centerDistance
      || a.target.id.localeCompare(b.target.id)
    ))[0]?.target ?? null;
}

export function isPlayerReadyForRpgTarget(
  target: RpgSpatialInteractionTarget,
  playerX: number,
  playerY: number,
  playerFacing: RpgCardinalFacing
): boolean {
  return isPlayerWithinRpgTarget(target, playerX, playerY)
    && isPlayerFacingRpgTarget(target, playerX, playerY, playerFacing);
}

export function isPlayerReadyForRpgItemDrop(
  target: RpgSpatialInteractionTarget,
  playerX: number,
  playerY: number,
  playerFacing: RpgCardinalFacing
): boolean {
  return isPlayerWithinRpgTarget(target, playerX, playerY)
    && (target.dropRequiresFacing === false
      || isPlayerFacingRpgTarget(target, playerX, playerY, playerFacing));
}

function targetPriority<TTarget extends RpgSpatialInteractionTarget>(
  target: TTarget,
  itemId: ItemId
): readonly [number, number, number] {
  const bounds = getRpgDropBounds(target);
  return [
    target.acceptedItem === itemId ? 0 : 1,
    target.acceptedItem ? 0 : 1,
    bounds.width * bounds.height
  ];
}

export function resolveRpgItemDrop<TTarget extends RpgSpatialInteractionTarget>(options: {
  targets: readonly TTarget[];
  itemId: ItemId;
  dropX: number;
  dropY: number;
  playerX: number;
  playerY: number;
  playerFacing: RpgCardinalFacing;
  mode?: RpgRealityMode;
}): RpgItemDropResult<TTarget> {
  const target = options.targets
    .filter((candidate) => isRpgDropPointWithin(candidate, options.dropX, options.dropY))
    .sort((a, b) => {
      const aPriority = targetPriority(a, options.itemId);
      const bPriority = targetPriority(b, options.itemId);
      return aPriority[0] - bPriority[0]
        || aPriority[1] - bPriority[1]
        || aPriority[2] - bPriority[2]
        || Math.hypot(a.x - options.dropX, a.y - options.dropY)
          - Math.hypot(b.x - options.dropX, b.y - options.dropY)
        || a.id.localeCompare(b.id);
    })[0] ?? null;

  if (!target) return { kind: "missed_target", target: null };
  if (target.acceptedItem !== options.itemId) return { kind: "wrong_item", target };
  if (target.requiredMode && target.requiredMode !== options.mode) {
    return {
      kind: "wrong_mode",
      target,
      expectedMode: target.requiredMode
    };
  }
  if (!isPlayerWithinRpgTarget(target, options.playerX, options.playerY)) {
    return { kind: "too_far", target };
  }
  if (target.dropRequiresFacing !== false && !isPlayerFacingRpgTarget(
    target,
    options.playerX,
    options.playerY,
    options.playerFacing
  )) {
    return { kind: "wrong_facing", target };
  }
  return { kind: "accepted", target };
}

export function formatRpgModeRequirement(mode: RpgRealityMode): string {
  const contract = RPG_REALITY_MODE_CONTRACT[mode];
  return `需要${contract.label}：${contract.shortHint}`;
}
