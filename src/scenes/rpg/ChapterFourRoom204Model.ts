import type {
  ChapterFourPhase,
  ChapterFourRoom204GroupId,
  ChapterFourRoom204Orientation,
  ChapterFourRoom204PieceId,
  ChapterFourRoom204Placement,
  ChapterFourRoom204SlotId
} from "../../core/types";
import storyContent from "../../data/chapter4-755.content.json";
import mazeLayout from "../../data/chapter4-three-floor-maze.layout.json";

export interface Room204Point {
  x: number;
  y: number;
}

export interface Room204Rect extends Room204Point {
  width: number;
  height: number;
}

export interface Room204FrameBinding {
  /** Compatibility alias for the desk frame while the Scene adopts paired furniture. */
  furnitureFrame: string;
  deskFrame: string;
  chairFrame: string;
  residualFrame: string;
}

export interface Room204InitialPieceLayout {
  pieceId: ChapterFourRoom204PieceId;
  deskFrame: string;
  chairFrame: string;
  residualFrame: string;
  position: Room204Point;
  angle: number;
  discussionTableId: string;
  approximate: true;
}

export interface Room204DiscussionTableLayout {
  id: string;
  frame: string;
  position: Room204Point;
  angle: number;
  pieceIds: ChapterFourRoom204PieceId[];
  approximate: true;
}

export interface Room204SlotLayout {
  slotId: ChapterFourRoom204SlotId;
  center: Room204Point;
  bounds: Room204Rect;
  orientation: ChapterFourRoom204Orientation;
  approximate: true;
}

export interface Room204GroupMapping {
  pieceId: ChapterFourRoom204PieceId;
  slotId: ChapterFourRoom204SlotId;
}

export interface Room204GroupContract {
  id: ChapterFourRoom204GroupId;
  label: string;
  rawDetailId: string;
  rationale: string;
  targetBounds: Room204Rect;
  mappings: readonly Readonly<Room204GroupMapping>[];
}

export type Room204PlacementIssue =
  | "unknown_piece"
  | "unknown_slot"
  | "invalid_orientation"
  | "duplicate_piece"
  | "occupied_slot";

export type Room204PlacementResolution =
  | {
      accepted: true;
      placement: ChapterFourRoom204Placement;
      placements: ChapterFourRoom204Placement[];
      complete: boolean;
    }
  | {
      accepted: false;
      issue: Room204PlacementIssue | "already_placed";
      placements: ChapterFourRoom204Placement[];
    };

export type Room204GroupPlacementIssue =
  | "unknown_group"
  | "wrong_group"
  | "group_conflict"
  | "already_placed";

export type Room204GroupPlacementResolution =
  | {
      accepted: true;
      groupId: ChapterFourRoom204GroupId;
      addedPlacements: ChapterFourRoom204Placement[];
      placements: ChapterFourRoom204Placement[];
      complete: boolean;
    }
  | {
      accepted: false;
      issue: Room204GroupPlacementIssue;
      placements: ChapterFourRoom204Placement[];
    };

interface Room204RuntimeLayoutJson {
  roomBounds: Room204Rect;
  residualGroupBounds: Room204Rect;
  uniformScale: number;
  pairOffsets: { desk: Room204Point; chair: Room204Point };
  slotTargets: Room204SlotLayout[];
  initialPiecePairs: Room204InitialPieceLayout[];
  discussionTables: Room204DiscussionTableLayout[];
  podium: {
    frame: string;
    position: Room204Point;
    drawerBounds: Room204Rect;
    fixedAxisReference: true;
    approximate: true;
  };
  walkability: {
    sampleSteps: number[];
    verticalAisleCenters: number[];
    verticalRange: { fromY: number; toY: number };
    horizontalConnector: { y: number; fromX: number; toX: number };
    playerFootBox: { width: number; height: number };
  };
  projectionHandshake: {
    screenBounds: Room204Rect;
    misalignedAtMs: number;
    stableAtMs: number;
    commitAtMs: number;
    stableText: string;
  };
}

interface Room204GroupContentJson {
  groups: Array<{
    id: ChapterFourRoom204GroupId;
    label: string;
    rawDetailId: string;
    rationale: string;
    targetBounds: Room204Rect;
    mappings: Room204GroupMapping[];
  }>;
}

const ROOM204_LAYOUT = mazeLayout.room204Runtime as Room204RuntimeLayoutJson;
const ROOM204_CONTENT = storyContent.room204 as Room204GroupContentJson;

export const ROOM204_ALLOWED_ORIENTATION: ChapterFourRoom204Orientation = "up";
export const ROOM204_FURNITURE_SCALE = ROOM204_LAYOUT.uniformScale;
export const ROOM204_PAIR_OFFSETS = Object.freeze({
  desk: Object.freeze({ ...ROOM204_LAYOUT.pairOffsets.desk }),
  chair: Object.freeze({ ...ROOM204_LAYOUT.pairOffsets.chair })
});
export const ROOM204_ROOM_BOUNDS = Object.freeze({ ...ROOM204_LAYOUT.roomBounds });
export const ROOM204_RESIDUAL_GROUP_BOUNDS = Object.freeze({
  ...ROOM204_LAYOUT.residualGroupBounds
});
export const ROOM204_PODIUM_LAYOUT = Object.freeze({ ...ROOM204_LAYOUT.podium });
export const ROOM204_WALKABILITY = Object.freeze({ ...ROOM204_LAYOUT.walkability });
export const ROOM204_PROJECTION_HANDSHAKE = Object.freeze({
  ...ROOM204_LAYOUT.projectionHandshake
});

export const ROOM204_RESTORED_DISPLAY_PHASES: ReadonlySet<ChapterFourPhase> = new Set([
  "maintenance_repair",
  "blackout_light_grid",
  "final_chase",
  "final_minute_recovery",
  "return_to_clock",
  "morning_checkin",
  "exterior_closure",
  "complete"
]);

export type Room204RuntimePresentation = "interactive" | "restored" | "hidden";

export function selectRoom204RuntimePresentation(
  phase: string,
  restored: boolean,
  placements: readonly ChapterFourRoom204Placement[]
): Room204RuntimePresentation {
  if (phase === "room204_restore") return "interactive";
  return restored
    && ROOM204_RESTORED_DISPLAY_PHASES.has(phase as ChapterFourPhase)
    && isRoom204PlacementSetComplete(placements)
    ? "restored"
    : "hidden";
}

export const ROOM204_PIECE_ORDER = Object.freeze(
  ROOM204_LAYOUT.initialPiecePairs.map((entry) => entry.pieceId)
) as readonly ChapterFourRoom204PieceId[];

export const ROOM204_SLOT_ORDER = Object.freeze(
  ROOM204_LAYOUT.slotTargets.map((entry) => entry.slotId)
) as readonly ChapterFourRoom204SlotId[];

export const ROOM204_INITIAL_PIECE_LAYOUTS = Object.freeze(
  Object.fromEntries(ROOM204_LAYOUT.initialPiecePairs.map((entry) => [entry.pieceId, Object.freeze({
    ...entry,
    position: Object.freeze({ ...entry.position })
  })]))
) as Readonly<Record<ChapterFourRoom204PieceId, Readonly<Room204InitialPieceLayout>>>;

export const ROOM204_DISCUSSION_TABLES = Object.freeze(
  ROOM204_LAYOUT.discussionTables.map((entry) => Object.freeze({
    ...entry,
    position: Object.freeze({ ...entry.position }),
    pieceIds: Object.freeze([...entry.pieceIds])
  }))
) as readonly Readonly<Room204DiscussionTableLayout>[];

export const ROOM204_PIECE_FRAME_BINDINGS = Object.freeze(
  Object.fromEntries(ROOM204_LAYOUT.initialPiecePairs.map((entry) => [entry.pieceId, Object.freeze({
    furnitureFrame: entry.deskFrame,
    deskFrame: entry.deskFrame,
    chairFrame: entry.chairFrame,
    residualFrame: entry.residualFrame
  })]))
) as Readonly<Record<ChapterFourRoom204PieceId, Readonly<Room204FrameBinding>>>;

export const ROOM204_SLOT_LAYOUTS = Object.freeze(
  Object.fromEntries(ROOM204_LAYOUT.slotTargets.map((entry) => [entry.slotId, Object.freeze({
    ...entry,
    center: Object.freeze({ ...entry.center }),
    bounds: Object.freeze({ ...entry.bounds })
  })]))
) as Readonly<Record<ChapterFourRoom204SlotId, Readonly<Room204SlotLayout>>>;

export const ROOM204_GROUPS = Object.freeze(
  Object.fromEntries(ROOM204_CONTENT.groups.map((group) => [group.id, Object.freeze({
    ...group,
    targetBounds: Object.freeze({ ...group.targetBounds }),
    mappings: Object.freeze(group.mappings.map((mapping) => Object.freeze({ ...mapping })))
  })]))
) as Readonly<Record<ChapterFourRoom204GroupId, Readonly<Room204GroupContract>>>;

export const ROOM204_GROUP_ORDER = Object.freeze(
  ROOM204_CONTENT.groups.map((group) => group.id)
) as readonly ChapterFourRoom204GroupId[];

export const ROOM204_SLOT_CENTERS = Object.freeze(
  Object.fromEntries(ROOM204_LAYOUT.slotTargets.map((entry) => [
    entry.slotId,
    Object.freeze({ ...entry.center })
  ]))
) as Readonly<Record<ChapterFourRoom204SlotId, Readonly<Room204Point>>>;

export const ROOM204_INITIAL_PIECE_POSITIONS = Object.freeze(
  Object.fromEntries(ROOM204_LAYOUT.initialPiecePairs.map((entry) => [
    entry.pieceId,
    Object.freeze({ ...entry.position })
  ]))
) as Readonly<Record<ChapterFourRoom204PieceId, Readonly<Room204Point>>>;

const ROOM204_PIECE_IDS = new Set<ChapterFourRoom204PieceId>(ROOM204_PIECE_ORDER);
const ROOM204_SLOT_IDS = new Set<ChapterFourRoom204SlotId>(ROOM204_SLOT_ORDER);
const ROOM204_GROUP_IDS = new Set<ChapterFourRoom204GroupId>(ROOM204_GROUP_ORDER);

export function room204SlotTargetId(slotId: ChapterFourRoom204SlotId): string {
  return `a2_room204_slot_${slotId}`;
}

export function room204SlotRuntimeEntityId(slotId: ChapterFourRoom204SlotId): string {
  return `chapter4-room204-slot-${slotId}`;
}

export function room204GroupTargetId(groupId: ChapterFourRoom204GroupId): string {
  return `a2_room204_group_${groupId}`;
}

export function room204GroupRuntimeEntityId(groupId: ChapterFourRoom204GroupId): string {
  return `chapter4-room204-group-${groupId}`;
}

export function room204GroupIdFromTargetId(targetId: string): ChapterFourRoom204GroupId | null {
  const prefix = "a2_room204_group_";
  if (!targetId.startsWith(prefix)) return null;
  const groupId = targetId.slice(prefix.length) as ChapterFourRoom204GroupId;
  return ROOM204_GROUP_IDS.has(groupId) ? groupId : null;
}

export const ROOM204_RESIDUAL_GROUP_RUNTIME_ENTITY_ID = "chapter4-room204-residual-group";
export const ROOM204_PODIUM_DRAWER_RUNTIME_ENTITY_ID = "chapter4-room204-podium-drawer";

export function findRoom204PlacementForPiece(
  placements: readonly ChapterFourRoom204Placement[],
  pieceId: ChapterFourRoom204PieceId
): ChapterFourRoom204Placement | null {
  return placements.find((placement) => placement.pieceId === pieceId) ?? null;
}

export function isRoom204OrientationAccepted(
  orientation: ChapterFourRoom204Orientation
): boolean {
  return orientation === ROOM204_ALLOWED_ORIENTATION;
}

export function normalizeRoom204Placements(value: unknown): ChapterFourRoom204Placement[] {
  if (!Array.isArray(value)) return [];
  const placements: ChapterFourRoom204Placement[] = [];
  const seenPieces = new Set<ChapterFourRoom204PieceId>();
  const seenSlots = new Set<ChapterFourRoom204SlotId>();
  for (const entry of value) {
    if (!isRecord(entry)) continue;
    const pieceId = typeof entry.pieceId === "string"
      && ROOM204_PIECE_IDS.has(entry.pieceId as ChapterFourRoom204PieceId)
      ? entry.pieceId as ChapterFourRoom204PieceId
      : null;
    const slotId = typeof entry.slotId === "string"
      && ROOM204_SLOT_IDS.has(entry.slotId as ChapterFourRoom204SlotId)
      ? entry.slotId as ChapterFourRoom204SlotId
      : null;
    const orientation = entry.orientation === ROOM204_ALLOWED_ORIENTATION
      ? ROOM204_ALLOWED_ORIENTATION
      : null;
    if (!pieceId
      || !slotId
      || !orientation
      || seenPieces.has(pieceId)
      || seenSlots.has(slotId)) continue;
    seenPieces.add(pieceId);
    seenSlots.add(slotId);
    placements.push({ pieceId, slotId, orientation });
  }
  return placements;
}

/**
 * Every desk/chair pair is visually equivalent. Gameplay accepts any unique
 * piece in any unique empty slot; only the upward orientation is authored.
 */
export function resolveRoom204Placement(
  current: readonly ChapterFourRoom204Placement[],
  candidate: {
    pieceId: unknown;
    slotId: unknown;
    orientation: unknown;
  }
): Room204PlacementResolution {
  const placements = normalizeRoom204Placements(current);
  if (typeof candidate.pieceId !== "string"
    || !ROOM204_PIECE_IDS.has(candidate.pieceId as ChapterFourRoom204PieceId)) {
    return { accepted: false, issue: "unknown_piece", placements };
  }
  if (typeof candidate.slotId !== "string"
    || !ROOM204_SLOT_IDS.has(candidate.slotId as ChapterFourRoom204SlotId)) {
    return { accepted: false, issue: "unknown_slot", placements };
  }
  if (candidate.orientation !== ROOM204_ALLOWED_ORIENTATION) {
    return { accepted: false, issue: "invalid_orientation", placements };
  }
  const pieceId = candidate.pieceId as ChapterFourRoom204PieceId;
  const slotId = candidate.slotId as ChapterFourRoom204SlotId;
  const existing = placements.find((placement) => placement.pieceId === pieceId);
  if (existing) {
    return {
      accepted: false,
      issue: existing.slotId === slotId ? "already_placed" : "duplicate_piece",
      placements
    };
  }
  if (placements.some((placement) => placement.slotId === slotId)) {
    return { accepted: false, issue: "occupied_slot", placements };
  }
  const placement = { pieceId, slotId, orientation: ROOM204_ALLOWED_ORIENTATION };
  const next = [...placements, placement];
  return {
    accepted: true,
    placement,
    placements: next,
    complete: isRoom204PlacementSetComplete(next)
  };
}

export function resolveRoom204GroupPlacement(
  current: readonly ChapterFourRoom204Placement[],
  candidate: { groupId: unknown; targetGroupId?: unknown }
): Room204GroupPlacementResolution {
  const placements = normalizeRoom204Placements(current);
  if (typeof candidate.groupId !== "string"
    || !ROOM204_GROUP_IDS.has(candidate.groupId as ChapterFourRoom204GroupId)) {
    return { accepted: false, issue: "unknown_group", placements };
  }
  const groupId = candidate.groupId as ChapterFourRoom204GroupId;
  if (candidate.targetGroupId !== undefined && candidate.targetGroupId !== groupId) {
    return { accepted: false, issue: "wrong_group", placements };
  }
  const group = ROOM204_GROUPS[groupId];
  const placedPieceIds = new Set(placements.map((placement) => placement.pieceId));
  if (group.mappings.every((mapping) => placedPieceIds.has(mapping.pieceId))) {
    return { accepted: false, issue: "already_placed", placements };
  }

  const occupiedSlotIds = new Set(placements.map((placement) => placement.slotId));
  const missingMappings = group.mappings.filter((mapping) => !placedPieceIds.has(mapping.pieceId));
  const availableGroupSlots = group.mappings
    .map((mapping) => mapping.slotId)
    .filter((slotId) => !occupiedSlotIds.has(slotId));
  if (availableGroupSlots.length < missingMappings.length) {
    return { accepted: false, issue: "group_conflict", placements };
  }

  const remainingSlots = [...availableGroupSlots];
  const addedPlacements = missingMappings.map((mapping) => {
    const preferredIndex = remainingSlots.indexOf(mapping.slotId);
    const slotIndex = preferredIndex >= 0 ? preferredIndex : 0;
    const [slotId] = remainingSlots.splice(slotIndex, 1);
    return { pieceId: mapping.pieceId, slotId, orientation: ROOM204_ALLOWED_ORIENTATION };
  });
  const next = [...placements, ...addedPlacements];
  return {
    accepted: true,
    groupId,
    addedPlacements,
    placements: next,
    complete: isRoom204PlacementSetComplete(next)
  };
}

export function isRoom204GroupComplete(
  placements: readonly ChapterFourRoom204Placement[],
  groupId: ChapterFourRoom204GroupId
): boolean {
  const placedPieceIds = new Set(
    normalizeRoom204Placements(placements).map((placement) => placement.pieceId)
  );
  return ROOM204_GROUPS[groupId].mappings.every((mapping) => placedPieceIds.has(mapping.pieceId));
}

export function countCompletedRoom204Groups(
  placements: readonly ChapterFourRoom204Placement[]
): number {
  return ROOM204_GROUP_ORDER.filter((groupId) => isRoom204GroupComplete(placements, groupId)).length;
}

export function isRoom204PlacementSetComplete(
  placements: readonly ChapterFourRoom204Placement[]
): boolean {
  const normalized = normalizeRoom204Placements(placements);
  return normalized.length === ROOM204_PIECE_ORDER.length
    && new Set(normalized.map((placement) => placement.pieceId)).size === ROOM204_PIECE_ORDER.length
    && new Set(normalized.map((placement) => placement.slotId)).size === ROOM204_SLOT_ORDER.length;
}

/** Used only to repair later-phase saves whose completed layout payload is missing. */
export function createCanonicalCompleteRoom204Placements(): ChapterFourRoom204Placement[] {
  return ROOM204_PIECE_ORDER.map((pieceId, index) => ({
    pieceId,
    slotId: ROOM204_SLOT_ORDER[index],
    orientation: ROOM204_ALLOWED_ORIENTATION
  }));
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
