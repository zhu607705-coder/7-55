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

export interface RpgSpatialInteractionTarget {
  id: string;
  label: string;
  /** Visible entity or control center in world coordinates. */
  x: number;
  y: number;
  /** Reachable floor position used for proximity validation. */
  stand?: RpgWorldPoint;
  proximity: number;
  /** Visible entity bounds, used when no explicit stand point exists. */
  width?: number;
  height?: number;
  /** Exact item drop bounds centered on x/y. */
  dropWidth?: number;
  dropHeight?: number;
  acceptedItem?: ItemId;
  requiredMode?: RpgRealityMode;
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
  if (target.stand) {
    return Math.hypot(playerX - target.stand.x, playerY - target.stand.y);
  }
  if (target.width && target.height) {
    const halfWidth = target.width / 2;
    const halfHeight = target.height / 2;
    const nearestX = Math.max(target.x - halfWidth, Math.min(playerX, target.x + halfWidth));
    const nearestY = Math.max(target.y - halfHeight, Math.min(playerY, target.y + halfHeight));
    return Math.hypot(playerX - nearestX, playerY - nearestY);
  }
  return Math.hypot(playerX - target.x, playerY - target.y);
}

export function isPlayerWithinRpgTarget(
  target: RpgSpatialInteractionTarget,
  playerX: number,
  playerY: number
): boolean {
  return distanceFromPlayerToRpgTarget(target, playerX, playerY) <= target.proximity;
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
  mode?: RpgRealityMode;
}): RpgItemDropResult<TTarget> {
  const target = options.targets
    .filter((candidate) => isRpgDropPointWithin(candidate, options.dropX, options.dropY))
    .sort((a, b) => {
      const aPriority = targetPriority(a, options.itemId);
      const bPriority = targetPriority(b, options.itemId);
      return aPriority[0] - bPriority[0]
        || aPriority[1] - bPriority[1]
        || aPriority[2] - bPriority[2];
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
  return { kind: "accepted", target };
}

export function formatRpgModeRequirement(mode: RpgRealityMode): string {
  const contract = RPG_REALITY_MODE_CONTRACT[mode];
  return `需要${contract.label}：${contract.shortHint}`;
}
