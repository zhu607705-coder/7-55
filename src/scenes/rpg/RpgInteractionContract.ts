import type {
  ChapterFour755FloorId,
  ChapterFourFactId,
  ChapterFourPhase,
  ChapterFourRoom204GroupId,
  ChapterFourRoom204PieceId,
  ChapterFourRoom204SlotId,
  GameState,
  InventoryItemId,
  ItemId
} from "../../core/types";
import chapterFourLayout from "../../data/chapter4-three-floor-maze.layout.json";
import {
  CHAPTER_FOUR_CONTEXT_INTERACTIONS,
  type ChapterFourContextInteractionTargetId
} from "../../data/ChapterFourInteractionContent";
import {
  ROOM204_GROUPS,
  ROOM204_GROUP_ORDER,
  ROOM204_PODIUM_DRAWER_RUNTIME_ENTITY_ID,
  ROOM204_PODIUM_LAYOUT,
  ROOM204_RESIDUAL_GROUP_BOUNDS,
  ROOM204_RESIDUAL_GROUP_RUNTIME_ENTITY_ID,
  ROOM204_SLOT_LAYOUTS,
  isRoom204GroupComplete,
  room204GroupRuntimeEntityId,
  room204GroupTargetId,
  room204SlotRuntimeEntityId
} from "./ChapterFourRoom204Model";
import {
  isChapterFourClockControlAvailable,
  isChapterFourPhaseTimeAligned
} from "../../modules/ChapterFourTimeControlModel";

export type RpgRealityMode = "light" | "dark";

/**
 * `requiredMode` 只校验当前动作的现实模式，不表示另一模式的事实必须先写入。
 * 实体操作完成后，仍可在可到达的观察点补录真实观察事实；模式切换本身不得补写事实或推进阶段。
 */
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

export const RPG_REALITY_MODE_ORDER_CONTRACT = Object.freeze({
  sequence: "independent",
  operationMayPrecedeObservation: true,
  observationMayFollowOperation: true,
  inferObservationFromOperation: false
} as const);

export interface RpgWorldPoint {
  x: number;
  y: number;
}

export type RpgCardinalFacing = "up" | "down" | "left" | "right";

export interface RpgHalfOpenWorldRect {
  x: number;
  y: number;
  width: number;
  height: number;
}

export type ChapterFour755BoundsSource =
  | {
      kind: "layout_anchor";
      floor: ChapterFour755FloorId;
      anchorId: string;
    }
  | {
      kind: "runtime_entity";
      floor: ChapterFour755FloorId;
      entityId: string;
    };

type ChapterFour755Room204SlotTargetId = `a2_room204_slot_${ChapterFourRoom204SlotId}`;
type ChapterFour755Room204GroupTargetId = `a2_room204_group_${ChapterFourRoom204GroupId}`;

export type ChapterFour755InteractionTargetId =
  | "a1_noticeboard_paper"
  | "a1_hall_clock"
  | "a1_bakery_inspection_lamp"
  | "a1_bakery_conveyor_edge"
  | "a1_bakery_hour_hand_pickup"
  | "a1_hall_clock_hour_hand_socket"
  | "a1_front_desk_attendant"
  | "a2_elevator_attendant"
  | "a3_reference_teacher"
  | ChapterFourContextInteractionTargetId
  | "a3_alumni_su_buqing"
  | "a3_alumni_zhu_kezhen"
  | "a3_alumni_lu_yongxiang"
  | "a3_alumni_chen_jiangong"
  | "a3_alumni_tan_jiazhen"
  | "a3_alumni_cheng_kaijia"
  | "a1_classroom_104_blackboard_residual"
  | "a1_classroom_105_lectern_terminal"
  | "a3_reference_classroom_layout"
  | "a2_room204_residual_group"
  | ChapterFour755Room204GroupTargetId
  | ChapterFour755Room204SlotTargetId
  | "a2_room204_podium_drawer"
  | "a1_hall_clock_positioning_plate_slot"
  | "a1_cleaning_cart_wheel_inspection"
  | "a1_bakery_back_pry_bar"
  | "a1_cleaning_cart_wheel_cover"
  | "a1_cleaning_cart_oil_bottle"
  | "a1_cleaning_cart_wheel"
  | "a1_hall_clock_gear"
  | "a1_hall_clock_minute_endpoint"
  | "a1_power_panel"
  | "a2_202_threshold"
  | "a2_202_projection"
  | "a1_campus_card_reader"
  | "a1_attendance_paper_slot";

export type ChapterFour755TargetConditionId =
  | "opening_paper_available"
  | "hall_clock_action_available"
  | "bakery_lamp_available"
  | "bakery_conveyor_available"
  | "hour_hand_pickup_available"
  | "hour_hand_install_available"
  | "front_desk_attendant_available"
  | "support_npc_available"
  | "context_interaction_available"
  | "alumni_honor_wall_available"
  | "classroom_104_content_available"
  | "classroom_105_content_available"
  | "a3_reference_available"
  | "room204_residual_available"
  | "room204_group_available"
  | "room204_slot_available"
  | "positioning_plate_pickup_available"
  | "positioning_plate_install_available"
  | "cart_wheel_inspection_available"
  | "pry_bar_pickup_available"
  | "pry_bar_granted_by_diagnosis"
  | "cart_cover_available"
  | "oil_pickup_available"
  | "oil_granted_by_diagnosis"
  | "cart_wheel_available"
  | "clock_gear_available"
  | "clock_gear_repaired_with_linkage"
  | "minute_endpoint_available"
  | "power_panel_available"
  | "lecture202_threshold_available"
  | "final_minute_available"
  | "campus_card_checkin_available"
  | "attendance_paper_checkin_available";

export interface ChapterFour755TargetActivationCondition {
  id: ChapterFour755TargetConditionId;
  /** Pure story-state predicate owned by this registry entry. */
  test: (state: GameState) => boolean;
}

export interface ChapterFour755TargetSpatialResult {
  distance: "within_range" | "too_far";
}

export interface ChapterFour755RuntimeTargetContext {
  targetId: ChapterFour755InteractionTargetId;
  entityId: string;
  bounds: Readonly<RpgHalfOpenWorldRect>;
}

export const CHAPTER_FOUR_755_SCENE_KEY = "chapter-four-temporal-maze" as const;

export interface ChapterFour755SpatialAttestationRequest {
  requestId: string;
  attestationId: string;
  sceneKey: typeof CHAPTER_FOUR_755_SCENE_KEY;
  committedPhase: ChapterFourPhase;
  targetId: ChapterFour755InteractionTargetId;
  entityId: string;
  bounds: Readonly<RpgHalfOpenWorldRect>;
}

export interface ChapterFour755SpatialAttestationResponse
  extends ChapterFour755SpatialAttestationRequest {
  appliedPhase: ChapterFourPhase;
  appliedPlateSignature: string;
  playerFootPoint: Readonly<RpgWorldPoint>;
}

export type ChapterFour755SpatialAttestationFailure =
  | "no_response"
  | "multiple_responses"
  | "invalid_response"
  | "mismatched_nonce"
  | "wrong_scene"
  | "wrong_target"
  | "wrong_bounds"
  | "stale_projection"
  | "invalid_player"
  | "spatial_claim_mismatch";

export type ChapterFour755SpatialAttestationResult =
  | {
      accepted: true;
      spatial: ChapterFour755TargetSpatialResult;
      distancePx: number;
      response: ChapterFour755SpatialAttestationResponse;
    }
  | {
      accepted: false;
      reason: ChapterFour755SpatialAttestationFailure;
    };

export const CHAPTER_FOUR_755_WORLD_BOUNDS = Object.freeze({
  width: 1672,
  height: 941
});

export type ChapterFour755TargetContractRejection =
  | "locked"
  | "wrong_mode"
  | "wrong_item"
  | "too_far";

export interface ChapterFour755TargetIntentContractInput {
  targetId: string;
  itemId?: InventoryItemId;
  pieceId?: ChapterFourRoom204PieceId;
  spatial: ChapterFour755TargetSpatialResult;
}

export interface ChapterFour755InteractionTargetContract {
  id: ChapterFour755InteractionTargetId;
  label: string;
  /** Half-open [x, x + width) × [y, y + height) bounds in the 1672 × 941 plate. */
  bounds: Readonly<RpgHalfOpenWorldRect> | null;
  /** Runtime-entity targets stay out of the state-only projection until their visible entity resolves bounds. */
  activation: "phase_exclusive" | "runtime_entity";
  activePhases: readonly ChapterFourPhase[];
  roomIds: readonly string[];
  activationCondition: Readonly<ChapterFour755TargetActivationCondition>;
  proximity: number;
  acceptedItem?: InventoryItemId;
  /** Overrides acceptedItem for a phase; null explicitly means an item-free action. */
  acceptedItemByPhase?: Readonly<Partial<Record<ChapterFourPhase, InventoryItemId | null>>>;
  requiredMode?: RpgRealityMode;
  requiredModeByPhase?: Readonly<Partial<Record<ChapterFourPhase, RpgRealityMode>>>;
  approximate: boolean;
  contractPending: boolean;
  /** These rectangles are interaction-only and never become collision masks. */
  collision: false;
  boundsSource: Readonly<ChapterFour755BoundsSource>;
}

interface ChapterFourLayoutAnchor {
  id: string;
  bounds: RpgHalfOpenWorldRect;
}

interface ChapterFourLayoutFloor {
  storyFloor: ChapterFour755FloorId;
  anchors: ChapterFourLayoutAnchor[];
}

interface ChapterFourLayoutBakeryRuntimeTarget {
  targetId:
    | "a1_bakery_inspection_lamp"
    | "a1_bakery_conveyor_edge"
    | "a1_bakery_hour_hand_pickup";
  entityId: string;
  installationBounds: RpgHalfOpenWorldRect;
}

interface ChapterFourLayoutMaintenanceRuntimeTarget {
  targetId:
    | "a1_cleaning_cart_wheel_inspection"
    | "a1_bakery_back_pry_bar"
    | "a1_cleaning_cart_wheel_cover"
    | "a1_cleaning_cart_oil_bottle"
    | "a1_cleaning_cart_wheel"
    | "a1_hall_clock_gear";
  entityId: string;
  installationBounds: RpgHalfOpenWorldRect;
}

interface ChapterFourLayoutFinalClockRuntime {
  endpoint: {
    targetId: "a1_hall_clock_minute_endpoint";
    entityId: string;
    visualHandleBounds: RpgHalfOpenWorldRect;
    installationBounds: RpgHalfOpenWorldRect;
    approximate: boolean;
  };
}

interface ChapterFourLayoutLightGridRuntime {
  panel: {
    targetId: "a1_power_panel";
    entityId: string;
    installationBounds: RpgHalfOpenWorldRect;
  };
}

interface ChapterFourLayoutFinalMinuteRuntime {
  storyFloor: "A2";
  targetId: "a2_202_projection";
  entityId: string;
  installationBounds: RpgHalfOpenWorldRect;
  proximity: number;
  requiredMode: "light";
}

interface ChapterFourLayoutMorningCheckinRuntimeTarget {
  targetId: "a1_campus_card_reader" | "a1_attendance_paper_slot";
  entityId: string;
  installationBounds: RpgHalfOpenWorldRect;
  proximity: number;
  approximate: boolean;
}

interface ChapterFourLayoutMorningCheckinRuntime {
  storyFloor: "A1";
  statePlateId: "a1_0755_morning";
  targetEntities: ChapterFourLayoutMorningCheckinRuntimeTarget[];
}

interface ChapterFourLayoutRuntimeTargetInstallation {
  targetId: ChapterFour755InteractionTargetId;
  entityId: string;
  bounds: Readonly<RpgHalfOpenWorldRect>;
}

const CHAPTER_FOUR_755_MORNING_CHECKIN_RUNTIME =
  chapterFourLayout.morningCheckinRuntime as ChapterFourLayoutMorningCheckinRuntime;
const CHAPTER_FOUR_755_MORNING_CHECKIN_TARGETS = new Map(
  CHAPTER_FOUR_755_MORNING_CHECKIN_RUNTIME.targetEntities.map((entry) => [entry.targetId, entry])
);

const CHAPTER_FOUR_LAYOUT_FLOORS = chapterFourLayout.floors as ChapterFourLayoutFloor[];
const CHAPTER_FOUR_755_RUNTIME_TARGET_INSTALLATIONS = new Map<
  ChapterFour755InteractionTargetId,
  ChapterFourLayoutRuntimeTargetInstallation
>([
  ...(chapterFourLayout.bakeryRuntime.targetEntities as ChapterFourLayoutBakeryRuntimeTarget[])
    .map((entry) => [entry.targetId, {
      targetId: entry.targetId,
      entityId: entry.entityId,
      bounds: entry.installationBounds
    }] as const),
  ...(chapterFourLayout.maintenanceRuntime.targetEntities as ChapterFourLayoutMaintenanceRuntimeTarget[])
    .map((entry) => [entry.targetId, {
      targetId: entry.targetId,
      entityId: entry.entityId,
      bounds: entry.installationBounds
    }] as const),
  ["a1_hall_clock_minute_endpoint", {
    targetId: "a1_hall_clock_minute_endpoint",
    entityId: (chapterFourLayout.finalClockRuntime as ChapterFourLayoutFinalClockRuntime).endpoint.entityId,
    bounds: (chapterFourLayout.finalClockRuntime as ChapterFourLayoutFinalClockRuntime).endpoint.installationBounds
  }],
  ["a1_power_panel", {
    targetId: "a1_power_panel",
    entityId: (chapterFourLayout.lightGridRuntime as ChapterFourLayoutLightGridRuntime).panel.entityId,
    bounds: (chapterFourLayout.lightGridRuntime as ChapterFourLayoutLightGridRuntime).panel.installationBounds
  }],
  ["a2_202_projection", {
    targetId: "a2_202_projection",
    entityId: (chapterFourLayout.finalMinuteRuntime as ChapterFourLayoutFinalMinuteRuntime).entityId,
    bounds: (chapterFourLayout.finalMinuteRuntime as ChapterFourLayoutFinalMinuteRuntime).installationBounds
  }],
  ["a2_room204_residual_group", {
    targetId: "a2_room204_residual_group",
    entityId: ROOM204_RESIDUAL_GROUP_RUNTIME_ENTITY_ID,
    bounds: ROOM204_RESIDUAL_GROUP_BOUNDS
  }],
  ["a2_room204_podium_drawer", {
    targetId: "a2_room204_podium_drawer",
    entityId: ROOM204_PODIUM_DRAWER_RUNTIME_ENTITY_ID,
    bounds: ROOM204_PODIUM_LAYOUT.drawerBounds
  }],
  ...ROOM204_GROUP_ORDER.map((groupId) => {
    const targetId = room204GroupTargetId(groupId) as ChapterFour755Room204GroupTargetId;
    const group = ROOM204_GROUPS[groupId];
    return [targetId, {
      targetId,
      entityId: room204GroupRuntimeEntityId(groupId),
      bounds: group.targetBounds
    }] as const;
  }),
  ...Object.entries(ROOM204_SLOT_LAYOUTS).map(([slotId, slot]) => {
    const typedSlotId = slotId as ChapterFourRoom204SlotId;
    const targetId = `a2_room204_slot_${typedSlotId}` as ChapterFour755Room204SlotTargetId;
    return [targetId, {
      targetId,
      entityId: room204SlotRuntimeEntityId(typedSlotId),
      bounds: slot.bounds
    }] as const;
  }),
  ...CHAPTER_FOUR_755_MORNING_CHECKIN_RUNTIME.targetEntities.map((entry) => (
    [entry.targetId, {
      targetId: entry.targetId,
      entityId: entry.entityId,
      bounds: entry.installationBounds
    }] as const
  ))
]);
const CHAPTER_FOUR_755_CALIBRATED_RUNTIME_TARGET_IDS: ReadonlySet<ChapterFour755InteractionTargetId> =
  new Set(CHAPTER_FOUR_755_RUNTIME_TARGET_INSTALLATIONS.keys());

export interface ChapterFour755BakeryCommittedRuntimeState {
  lampLit: boolean;
  conveyorStopped: boolean;
  crowdPaused: boolean;
  hourHandVisible: boolean;
  glintVisible: boolean;
  retryStopHandshake: boolean;
}

function targetCondition(
  id: ChapterFour755TargetConditionId,
  test: (state: GameState) => boolean
): Readonly<ChapterFour755TargetActivationCondition> {
  return Object.freeze({ id, test });
}

function hasChapterFourFact(state: GameState, factId: ChapterFourFactId): boolean {
  return state.chapter4.factIds.includes(factId);
}

function ownsChapterFourItem(state: GameState, itemId: InventoryItemId): boolean {
  return state.items[itemId];
}

const ROOM204_INTERACTION_TARGETS = Object.fromEntries(
  Object.keys(ROOM204_SLOT_LAYOUTS).map((rawSlotId) => {
    const slotId = rawSlotId as ChapterFourRoom204SlotId;
    const id = `a2_room204_slot_${slotId}` as ChapterFour755Room204SlotTargetId;
    return [id, defineChapterFourTarget({
      id,
      label: "204 教室空槽位",
      bounds: null,
      activation: "runtime_entity",
      activePhases: ["room204_restore"],
      roomIds: ["a2_corridor", "a2_room204", "a2_room_204"],
      activationCondition: targetCondition("room204_slot_available", () => false),
      proximity: 56,
      requiredMode: "light",
      approximate: false,
      contractPending: true,
      boundsSource: Object.freeze({
        kind: "runtime_entity",
        floor: "A2",
        entityId: room204SlotRuntimeEntityId(slotId)
      })
    })];
  })
) as Readonly<Record<ChapterFour755Room204SlotTargetId, ChapterFour755InteractionTargetContract>>;

const ROOM204_GROUP_INTERACTION_TARGETS = Object.fromEntries(
  ROOM204_GROUP_ORDER.map((groupId) => {
    const id = room204GroupTargetId(groupId) as ChapterFour755Room204GroupTargetId;
    return [id, defineChapterFourTarget({
      id,
      label: ROOM204_GROUPS[groupId].label,
      bounds: null,
      activation: "runtime_entity",
      activePhases: ["room204_restore"],
      roomIds: ["a2_corridor", "a2_room204", "a2_room_204"],
      activationCondition: targetCondition("room204_group_available", (state) => (
        hasChapterFourFact(state, "a3_reference_observed")
        && hasChapterFourFact(state, "room204_residual_observed")
        && !isRoom204GroupComplete(state.chapter4.room204Placements, groupId)
      )),
      proximity: 64,
      requiredMode: "light",
      approximate: false,
      contractPending: true,
      boundsSource: Object.freeze({
        kind: "runtime_entity",
        floor: "A2",
        entityId: room204GroupRuntimeEntityId(groupId)
      })
    })];
  })
) as Readonly<Record<ChapterFour755Room204GroupTargetId, ChapterFour755InteractionTargetContract>>;

const CHAPTER_FOUR_CONTEXT_INTERACTION_TARGETS = Object.fromEntries(
  CHAPTER_FOUR_CONTEXT_INTERACTIONS.map((entry) => [entry.targetId, defineChapterFourTarget({
    id: entry.targetId,
    label: entry.label,
    ...layoutAnchorTarget(entry.floor, entry.anchorId),
    activation: "phase_exclusive",
    activePhases: entry.activePhases,
    roomIds: entry.roomAliases,
    activationCondition: targetCondition("context_interaction_available", () => true),
    proximity: entry.proximity ?? 52
  })])
) as Readonly<Record<ChapterFourContextInteractionTargetId, ChapterFour755InteractionTargetContract>>;

/**
 * Chapter 4's single interaction geometry contract. Layout-backed rectangles
 * are read directly from the Task 3 source-pixel anchors. Room 204 slots read
 * their exact layout rectangles and require a measured runtime entity. Targets whose art is a dynamic
 * entity declare that entity as their source and remain inactive until the
 * scene resolves a visible runtime rectangle.
 */
export const CHAPTER_FOUR_755_INTERACTION_TARGETS = Object.freeze({
  ...CHAPTER_FOUR_CONTEXT_INTERACTION_TARGETS,
  a1_noticeboard_paper: defineChapterFourTarget({
    id: "a1_noticeboard_paper",
    label: "公告栏前的签到记录纸条",
    ...layoutAnchorTarget("A1", "a1_noticeboard_paper"),
    activation: "phase_exclusive",
    activePhases: ["opening_handoff"],
    // The authoritative opening location is a1_lobby. Keep the prior broad
    // clock-room alias readable long enough for an already-running save to
    // project the same physical noticeboard instead of deadlocking.
    roomIds: ["a1_lobby", "a1_hall_clock"],
    activationCondition: targetCondition("opening_paper_available", (state) => (
      hasChapterFourFact(state, "opening_paper_at_noticeboard")
      && !hasChapterFourFact(state, "opening_paper_caught")
      && !ownsChapterFourItem(state, "attendanceRecordPaper")
    )),
    proximity: 72,
    requiredMode: "light"
  }),
  a1_hall_clock: defineChapterFourTarget({
    id: "a1_hall_clock",
    label: "一楼旧钟",
    ...layoutAnchorTarget("A1", "a1_hall_clock"),
    activation: "phase_exclusive",
    activePhases: [
      "opening_paper_caught",
      "hall_clock_inspection",
      "room204_restore",
      "maintenance_repair"
    ],
    // The A1 map keeps one broad lobby room state. The exact clock geometry
    // and distance check remain authoritative for this wall fixture.
    roomIds: ["a1_lobby", "a1_hall_clock"],
    activationCondition: targetCondition("hall_clock_action_available", (state) => (
      (state.chapter4.phase === "opening_paper_caught"
        && hasChapterFourFact(state, "opening_paper_caught")
        && hasChapterFourFact(state, "external_time_rejected")
        && !hasChapterFourFact(state, "hall_clock_inspected"))
      || (state.chapter4.phase === "hall_clock_inspection"
        && hasChapterFourFact(state, "hall_clock_inspected"))
      || isChapterFourClockControlAvailable(state.chapter4)
    )),
    proximity: 86,
    requiredModeByPhase: {
      opening_paper_caught: "light",
      hall_clock_inspection: "light",
      room204_restore: "light",
      maintenance_repair: "light"
    }
  }),
  a1_bakery_inspection_lamp: runtimeEntityTarget(
    "a1_bakery_inspection_lamp",
    "烤箱旁的检修灯",
    "light",
    ["bakery_hour_hand"],
    "chapter4-bakery-inspection-lamp",
    ["a1_lobby", "a1_bakery"],
    targetCondition("bakery_lamp_available", (state) => (
      !hasChapterFourFact(state, "bakery_hour_hand_exposed")
      && !hasChapterFourFact(state, "bakery_hour_hand_collected")
      && !hasChapterFourFact(state, "hour_hand_installed")
      && !ownsChapterFourItem(state, "oldClockHourHand")
    )),
    undefined,
    56
  ),
  a1_bakery_conveyor_edge: runtimeEntityTarget(
    "a1_bakery_conveyor_edge",
    "面包坊传送带边缘",
    "light",
    ["bakery_hour_hand"],
    "chapter4-bakery-conveyor-edge",
    ["a1_lobby", "a1_bakery"],
    targetCondition("bakery_conveyor_available", (state) => (
      !hasChapterFourFact(state, "bakery_hour_hand_exposed")
      && !hasChapterFourFact(state, "bakery_hour_hand_collected")
      && !hasChapterFourFact(state, "hour_hand_installed")
      && !ownsChapterFourItem(state, "oldClockHourHand")
    )),
    undefined,
    48
  ),
  a1_bakery_hour_hand_pickup: runtimeEntityTarget(
    "a1_bakery_hour_hand_pickup",
    "传送带旁的金属时针",
    "light",
    ["bakery_hour_hand"],
    "chapter4-bakery-hour-hand-pickup",
    ["a1_lobby", "a1_bakery"],
    targetCondition("hour_hand_pickup_available", (state) => (
      hasChapterFourFact(state, "bakery_conveyor_lamp_inspected")
      && hasChapterFourFact(state, "bakery_hour_hand_exposed")
      && !hasChapterFourFact(state, "bakery_hour_hand_collected")
      && !hasChapterFourFact(state, "hour_hand_installed")
      && !ownsChapterFourItem(state, "oldClockHourHand")
    )),
    undefined,
    48
  ),
  a1_hall_clock_hour_hand_socket: clockSocketTarget(
    "a1_hall_clock_hour_hand_socket",
    "旧钟时针插槽",
    "oldClockHourHand",
    ["bakery_hour_hand"],
    targetCondition("hour_hand_install_available", (state) => (
      ownsChapterFourItem(state, "oldClockHourHand")
      && !hasChapterFourFact(state, "hour_hand_installed")
    ))
  ),
  a1_front_desk_attendant: defineChapterFourTarget({
    id: "a1_front_desk_attendant",
    label: "与一楼前台值班助理交谈",
    ...layoutAnchorTarget("A1", "a1_front_desk_attendant"),
    activation: "phase_exclusive",
    activePhases: [
      "bakery_hour_hand",
      "room204_restore",
      "morning_checkin",
      "exterior_closure"
    ],
    roomIds: ["a1_lobby", "a1_hall_clock", "a1_bakery", "a1_checkin"],
    activationCondition: targetCondition("front_desk_attendant_available", () => true),
    proximity: 104
  }),
  a2_elevator_attendant: defineChapterFourTarget({
    id: "a2_elevator_attendant",
    label: "与二楼电梯口值班安全员交谈",
    ...layoutAnchorTarget("A2", "a2_elevator_attendant"),
    activation: "phase_exclusive",
    activePhases: ["room204_restore"],
    roomIds: ["a2_corridor", "a2_room204"],
    activationCondition: targetCondition("support_npc_available", () => true),
    proximity: 92
  }),
  a3_reference_teacher: defineChapterFourTarget({
    id: "a3_reference_teacher",
    label: "与三楼参照教室教师交谈",
    ...layoutAnchorTarget("A3", "a3_reference_teacher"),
    activation: "phase_exclusive",
    activePhases: ["room204_restore"],
    roomIds: ["a3_reference_classroom", "a3_wayfinding"],
    activationCondition: targetCondition("support_npc_available", () => true),
    proximity: 92
  }),
  a3_alumni_su_buqing: defineChapterFourTarget({
    id: "a3_alumni_su_buqing",
    label: "查看苏步青生平",
    ...layoutAnchorTarget("A3", "a3_alumni_su_buqing"),
    activation: "phase_exclusive",
    activePhases: ["room204_restore"],
    roomIds: ["a3_wayfinding", "a3_reference_classroom"],
    activationCondition: targetCondition("alumni_honor_wall_available", () => true),
    proximity: 72
  }),
  a3_alumni_zhu_kezhen: defineChapterFourTarget({
    id: "a3_alumni_zhu_kezhen",
    label: "查看竺可桢生平",
    ...layoutAnchorTarget("A3", "a3_alumni_zhu_kezhen"),
    activation: "phase_exclusive",
    activePhases: ["room204_restore"],
    roomIds: ["a3_wayfinding", "a3_reference_classroom"],
    activationCondition: targetCondition("alumni_honor_wall_available", () => true),
    proximity: 72
  }),
  a3_alumni_lu_yongxiang: defineChapterFourTarget({
    id: "a3_alumni_lu_yongxiang",
    label: "查看路甬祥生平",
    ...layoutAnchorTarget("A3", "a3_alumni_lu_yongxiang"),
    activation: "phase_exclusive",
    activePhases: ["room204_restore"],
    roomIds: ["a3_wayfinding", "a3_reference_classroom"],
    activationCondition: targetCondition("alumni_honor_wall_available", () => true),
    proximity: 72
  }),
  a3_alumni_chen_jiangong: defineChapterFourTarget({
    id: "a3_alumni_chen_jiangong",
    label: "查看陈建功生平",
    ...layoutAnchorTarget("A3", "a3_alumni_chen_jiangong"),
    activation: "phase_exclusive",
    activePhases: ["room204_restore"],
    roomIds: ["a3_wayfinding", "a3_reference_classroom"],
    activationCondition: targetCondition("alumni_honor_wall_available", () => true),
    proximity: 72
  }),
  a3_alumni_tan_jiazhen: defineChapterFourTarget({
    id: "a3_alumni_tan_jiazhen",
    label: "查看谈家桢生平",
    ...layoutAnchorTarget("A3", "a3_alumni_tan_jiazhen"),
    activation: "phase_exclusive",
    activePhases: ["room204_restore"],
    roomIds: ["a3_wayfinding", "a3_reference_classroom"],
    activationCondition: targetCondition("alumni_honor_wall_available", () => true),
    proximity: 72
  }),
  a3_alumni_cheng_kaijia: defineChapterFourTarget({
    id: "a3_alumni_cheng_kaijia",
    label: "查看程开甲生平",
    ...layoutAnchorTarget("A3", "a3_alumni_cheng_kaijia"),
    activation: "phase_exclusive",
    activePhases: ["room204_restore"],
    roomIds: ["a3_wayfinding", "a3_reference_classroom"],
    activationCondition: targetCondition("alumni_honor_wall_available", () => true),
    proximity: 72
  }),
  a1_classroom_104_blackboard_residual: defineChapterFourTarget({
    id: "a1_classroom_104_blackboard_residual",
    label: "观察 104 黑板擦痕",
    ...layoutAnchorTarget("A1", "a1_classroom_104_blackboard_residual"),
    activation: "phase_exclusive",
    activePhases: [
      "room204_restore",
      "maintenance_repair",
      "blackout_light_grid",
      "return_to_clock"
    ],
    roomIds: ["a1_lobby", "a1_hall_clock", "a1_bakery", "a1_cleaning_cart"],
    activationCondition: targetCondition("classroom_104_content_available", () => true),
    proximity: 96,
    requiredMode: "dark"
  }),
  a1_classroom_105_lectern_terminal: defineChapterFourTarget({
    id: "a1_classroom_105_lectern_terminal",
    label: "检查 105 讲台回放",
    ...layoutAnchorTarget("A1", "a1_classroom_105_lectern_terminal"),
    activation: "phase_exclusive",
    activePhases: [
      "room204_restore",
      "maintenance_repair",
      "blackout_light_grid",
      "return_to_clock"
    ],
    roomIds: ["a1_lobby", "a1_hall_clock", "a1_bakery", "a1_cleaning_cart"],
    activationCondition: targetCondition("classroom_105_content_available", () => true),
    proximity: 76,
    requiredMode: "light"
  }),
  a3_reference_classroom_layout: defineChapterFourTarget({
    id: "a3_reference_classroom_layout",
    label: "三楼晨间教室布置参照",
    ...layoutAnchorTarget("A3", "a3_reference_classroom_layout"),
    activation: "phase_exclusive",
    activePhases: ["room204_restore"],
    roomIds: ["a3_reference_classroom", "a3_wayfinding"],
    activationCondition: targetCondition("a3_reference_available", (state) => (
      !hasChapterFourFact(state, "a3_reference_observed")
    )),
    proximity: 84,
    requiredMode: "dark"
  }),
  a2_room204_residual_group: defineChapterFourTarget({
    id: "a2_room204_residual_group",
    label: "204 教室残影组",
    bounds: null,
    activation: "runtime_entity",
    activePhases: ["room204_restore"],
    roomIds: ["a2_corridor", "a2_room204", "a2_room_204"],
    activationCondition: targetCondition("room204_residual_available", (state) => (
      !hasChapterFourFact(state, "room204_residual_observed")
    )),
    proximity: 76,
    requiredMode: "dark",
    approximate: false,
    contractPending: true,
    boundsSource: Object.freeze({
      kind: "runtime_entity",
      floor: "A2",
      entityId: ROOM204_RESIDUAL_GROUP_RUNTIME_ENTITY_ID
    })
  }),
  ...ROOM204_INTERACTION_TARGETS,
  ...ROOM204_GROUP_INTERACTION_TARGETS,
  a2_room204_podium_drawer: defineChapterFourTarget({
    id: "a2_room204_podium_drawer",
    label: "204 讲台抽屉里的定位盘",
    bounds: null,
    activation: "runtime_entity",
    activePhases: ["room204_restore"],
    roomIds: ["a2_corridor", "a2_room204", "a2_room_204"],
    activationCondition: targetCondition("positioning_plate_pickup_available", (state) => (
      hasChapterFourFact(state, "room204_projection_completed")
      && !hasChapterFourFact(state, "positioning_plate_collected")
      && !hasChapterFourFact(state, "positioning_plate_installed")
      && !ownsChapterFourItem(state, "clockPositioningPlate")
    )),
    proximity: 60,
    requiredMode: "light",
    approximate: false,
    contractPending: true,
    boundsSource: Object.freeze({
      kind: "runtime_entity",
      floor: "A2",
      entityId: ROOM204_PODIUM_DRAWER_RUNTIME_ENTITY_ID
    })
  }),
  a1_hall_clock_positioning_plate_slot: clockSocketTarget(
    "a1_hall_clock_positioning_plate_slot",
    "旧钟定位盘插槽",
    "clockPositioningPlate",
    ["room204_restore"],
    targetCondition("positioning_plate_install_available", (state) => (
      hasChapterFourFact(state, "room204_projection_completed")
      && hasChapterFourFact(state, "positioning_plate_collected")
      && ownsChapterFourItem(state, "clockPositioningPlate")
      && !hasChapterFourFact(state, "positioning_plate_installed")
    ))
  ),
  a1_cleaning_cart_wheel_inspection: runtimeEntityTarget(
    "a1_cleaning_cart_wheel_inspection",
    "清洁车卡住的轮罩",
    "light",
    ["maintenance_repair"],
    "chapter4_cleaning_cart_wheel_inspection",
    ["a1_lobby", "a1_hall_clock", "a1_bakery", "a1_cleaning_cart"],
    targetCondition("cart_wheel_inspection_available", (state) => (
      !hasChapterFourFact(state, "cart_wheel_inspected")
      && !hasChapterFourFact(state, "cart_wheel_cover_opened")
      && !hasChapterFourFact(state, "cart_wheel_repaired")
      && !hasChapterFourFact(state, "clock_gear_repaired")
    )),
    undefined,
    72
  ),
  a1_bakery_back_pry_bar: runtimeEntityTarget(
    "a1_bakery_back_pry_bar",
    "面包店后场短撬棍",
    "light",
    ["maintenance_repair"],
    "chapter4_pry_bar_pickup",
    ["a1_lobby", "a1_hall_clock", "a1_bakery", "a1_cleaning_cart"],
    targetCondition("pry_bar_granted_by_diagnosis", () => false),
    undefined,
    52
  ),
  a1_cleaning_cart_wheel_cover: runtimeEntityTarget(
    "a1_cleaning_cart_wheel_cover",
    "清洁车轮罩",
    "light",
    ["maintenance_repair"],
    "chapter4_cleaning_cart_wheel_cover",
    ["a1_lobby", "a1_hall_clock", "a1_bakery", "a1_cleaning_cart"],
    targetCondition("cart_cover_available", (state) => (
      hasChapterFourFact(state, "cart_wheel_inspected")
      && !hasChapterFourFact(state, "cart_wheel_cover_opened")
    )),
    "shortPryBar",
    72
  ),
  a1_cleaning_cart_oil_bottle: runtimeEntityTarget(
    "a1_cleaning_cart_oil_bottle",
    "清洁车里的通用润滑油",
    "light",
    ["maintenance_repair"],
    "chapter4_cleaning_cart_oil_bottle",
    ["a1_lobby", "a1_hall_clock", "a1_bakery", "a1_cleaning_cart"],
    targetCondition("oil_granted_by_diagnosis", () => false),
    undefined,
    72
  ),
  a1_cleaning_cart_wheel: runtimeEntityTarget(
    "a1_cleaning_cart_wheel",
    "清洁车车轮",
    "light",
    ["maintenance_repair"],
    "chapter4_cleaning_cart_wheel",
    ["a1_lobby", "a1_hall_clock", "a1_bakery", "a1_cleaning_cart"],
    targetCondition("cart_wheel_available", (state) => (
      hasChapterFourFact(state, "cart_wheel_cover_opened")
      && !hasChapterFourFact(state, "cart_wheel_repaired")
    )),
    "universalLubricatingOil",
    72
  ),
  a1_hall_clock_gear: runtimeEntityTarget(
    "a1_hall_clock_gear",
    "旧钟齿轮",
    "light",
    ["maintenance_repair"],
    "chapter4_hall_clock_gear",
    ["a1_lobby", "a1_hall_clock", "a1_bakery", "a1_cleaning_cart"],
    targetCondition("clock_gear_repaired_with_linkage", () => false),
    "universalLubricatingOil",
    86
  ),
  a1_hall_clock_minute_endpoint: runtimeEntityTarget(
    "a1_hall_clock_minute_endpoint",
    "大厅旧钟表盘",
    "light",
    ["maintenance_repair", "return_to_clock"],
    (chapterFourLayout.finalClockRuntime as ChapterFourLayoutFinalClockRuntime).endpoint.entityId,
    ["a1_lobby", "a1_hall_clock"],
    targetCondition("minute_endpoint_available", (state) => (
      (state.chapter4.phase === "maintenance_repair"
        && hasChapterFourFact(state, "clock_gear_repaired")
        && ownsChapterFourItem(state, "attendanceRecordPaper")
        && !hasChapterFourFact(state, "paper_temporarily_out_of_inventory"))
      || (state.chapter4.phase === "return_to_clock"
        && state.chapter4.floor === "A1"
        && hasChapterFourFact(state, "final_minute_recovered")
        && !hasChapterFourFact(state, "final_minute_installed")
        && ownsChapterFourItem(state, "finalMinute")
        && ownsChapterFourItem(state, "attendanceRecordPaper"))
    )),
    undefined,
    148,
    { maintenance_repair: null, return_to_clock: "finalMinute" },
    false
  ),
  a1_power_panel: runtimeEntityTarget(
    "a1_power_panel",
    "一楼配电面板",
    "light",
    ["blackout_light_grid"],
    (chapterFourLayout.lightGridRuntime as ChapterFourLayoutLightGridRuntime).panel.entityId,
    ["a1_lobby", "a1_hall_clock", "a1_power_panel"],
    targetCondition("power_panel_available", (state) => (
      hasChapterFourFact(state, "paper_temporarily_out_of_inventory")
      && !hasChapterFourFact(state, "light_grid_locked")
      && !state.chapter4.lightGrid.locked
    )),
    undefined,
    72
  ),
  a2_202_threshold: defineChapterFourTarget({
    id: "a2_202_threshold",
    label: "202 阶梯教室门槛",
    ...layoutAnchorTarget("A2", "a2_202_threshold"),
    activation: "phase_exclusive",
    activePhases: ["final_chase"],
    roomIds: ["a2_corridor", "a2_room_202"],
    activationCondition: targetCondition("lecture202_threshold_available", (state) => (
      hasChapterFourFact(state, "light_grid_locked")
    )),
    proximity: 48
  }),
  a2_202_projection: runtimeEntityTarget(
    "a2_202_projection",
    "202 阶梯座椅间的黄铜分针组件",
    "light",
    ["final_minute_recovery"],
    (chapterFourLayout.finalMinuteRuntime as ChapterFourLayoutFinalMinuteRuntime).entityId,
    ["a2_room_202"],
    targetCondition("final_minute_available", (state) => (
      !hasChapterFourFact(state, "final_minute_recovered")
      && !ownsChapterFourItem(state, "finalMinute")
    )),
    undefined,
    (chapterFourLayout.finalMinuteRuntime as ChapterFourLayoutFinalMinuteRuntime).proximity,
    undefined,
    false,
    "A2"
  ),
  a1_campus_card_reader: runtimeEntityTarget(
    "a1_campus_card_reader",
    "签到校园卡读卡器",
    "light",
    ["morning_checkin"],
    CHAPTER_FOUR_755_MORNING_CHECKIN_TARGETS.get("a1_campus_card_reader")!.entityId,
    ["a1_checkin"],
    targetCondition("campus_card_checkin_available", (state) => (
      !state.chapter4.checkinCardAccepted
      && !hasChapterFourFact(state, "checkin_card_accepted")
    )),
    "campusCard",
    CHAPTER_FOUR_755_MORNING_CHECKIN_TARGETS.get("a1_campus_card_reader")!.proximity,
    undefined,
    false
  ),
  a1_attendance_paper_slot: runtimeEntityTarget(
    "a1_attendance_paper_slot",
    "签到记录纸槽",
    "light",
    ["morning_checkin"],
    CHAPTER_FOUR_755_MORNING_CHECKIN_TARGETS.get("a1_attendance_paper_slot")!.entityId,
    ["a1_checkin"],
    targetCondition("attendance_paper_checkin_available", (state) => (
      !state.chapter4.checkinPaperAccepted
      && !hasChapterFourFact(state, "checkin_paper_accepted")
    )),
    "attendanceRecordPaper",
    CHAPTER_FOUR_755_MORNING_CHECKIN_TARGETS.get("a1_attendance_paper_slot")!.proximity,
    undefined,
    false
  )
} satisfies Readonly<Record<ChapterFour755InteractionTargetId, ChapterFour755InteractionTargetContract>>);

function halfOpenRect(
  x: number,
  y: number,
  width: number,
  height: number
): Readonly<RpgHalfOpenWorldRect> {
  return Object.freeze({ x, y, width, height });
}

function defineChapterFourTarget(
  target: Omit<ChapterFour755InteractionTargetContract, "collision">
): ChapterFour755InteractionTargetContract {
  return Object.freeze({
    ...target,
    collision: false as const
  });
}

function clockSocketTarget(
  id:
    | "a1_hall_clock_hour_hand_socket"
    | "a1_hall_clock_positioning_plate_slot"
    | "a1_hall_clock_gear"
    | "a1_hall_clock_minute_endpoint",
  label: string,
  acceptedItem: InventoryItemId,
  activePhases: readonly ChapterFourPhase[],
  activationCondition: Readonly<ChapterFour755TargetActivationCondition>,
  acceptedItemByPhase?: Readonly<Partial<Record<ChapterFourPhase, InventoryItemId | null>>>
): ChapterFour755InteractionTargetContract {
  return defineChapterFourTarget({
    id,
    label,
    ...layoutAnchorTarget("A1", id),
    activation: "phase_exclusive",
    activePhases,
    roomIds: ["a1_lobby", "a1_hall_clock"],
    activationCondition,
    proximity: 86,
    acceptedItem,
    ...(acceptedItemByPhase ? { acceptedItemByPhase } : {}),
    requiredMode: "light",
    approximate: false,
    contractPending: false
  });
}

function runtimeEntityTarget(
  id:
    | "a1_bakery_inspection_lamp"
    | "a1_bakery_conveyor_edge"
    | "a1_bakery_hour_hand_pickup"
    | "a1_cleaning_cart_wheel_inspection"
    | "a1_bakery_back_pry_bar"
    | "a1_cleaning_cart_wheel_cover"
    | "a1_cleaning_cart_oil_bottle"
    | "a1_cleaning_cart_wheel"
    | "a1_hall_clock_gear"
    | "a1_hall_clock_minute_endpoint"
    | "a1_power_panel"
    | "a2_202_projection"
    | "a1_campus_card_reader"
    | "a1_attendance_paper_slot",
  label: string,
  requiredMode: RpgRealityMode,
  activePhases: readonly ChapterFourPhase[],
  entityId: string,
  roomIds: readonly string[],
  activationCondition: Readonly<ChapterFour755TargetActivationCondition>,
  acceptedItem?: InventoryItemId,
  proximity = 72,
  acceptedItemByPhase?: Readonly<Partial<Record<ChapterFourPhase, InventoryItemId | null>>>,
  approximate = false,
  floor: ChapterFour755FloorId = "A1"
): ChapterFour755InteractionTargetContract {
  return defineChapterFourTarget({
    id,
    label,
    bounds: null,
    activation: "runtime_entity",
    activePhases,
    roomIds,
    activationCondition,
    proximity,
    ...(acceptedItem ? { acceptedItem } : {}),
    ...(acceptedItemByPhase ? { acceptedItemByPhase } : {}),
    requiredMode,
    approximate,
    contractPending: true,
    boundsSource: Object.freeze({ kind: "runtime_entity", floor, entityId })
  });
}

function layoutAnchorTarget(
  floor: ChapterFour755FloorId,
  anchorId: string
): Pick<ChapterFour755InteractionTargetContract, "bounds" | "boundsSource" | "approximate" | "contractPending"> {
  const layoutFloor = CHAPTER_FOUR_LAYOUT_FLOORS.find((candidate) => candidate.storyFloor === floor);
  const anchor = layoutFloor?.anchors.find((candidate) => candidate.id === anchorId);
  if (!anchor) throw new Error(`Missing Chapter 4 layout anchor: ${floor}/${anchorId}`);
  return {
    bounds: halfOpenRect(anchor.bounds.x, anchor.bounds.y, anchor.bounds.width, anchor.bounds.height),
    boundsSource: Object.freeze({ kind: "layout_anchor", floor, anchorId }),
    approximate: false,
    contractPending: false
  };
}

export function getChapterFour755TargetContract(
  targetId: string
): ChapterFour755InteractionTargetContract | null {
  return Object.prototype.hasOwnProperty.call(CHAPTER_FOUR_755_INTERACTION_TARGETS, targetId)
    ? CHAPTER_FOUR_755_INTERACTION_TARGETS[targetId as ChapterFour755InteractionTargetId]
    : null;
}

export function selectChapterFour755RequiredMode(
  target: ChapterFour755InteractionTargetContract,
  phase: ChapterFourPhase
): RpgRealityMode | undefined {
  return target.requiredModeByPhase?.[phase] ?? target.requiredMode;
}

export function selectChapterFour755AcceptedItem(
  target: ChapterFour755InteractionTargetContract,
  phase: ChapterFourPhase
): InventoryItemId | null | undefined {
  if (target.acceptedItemByPhase
    && Object.prototype.hasOwnProperty.call(target.acceptedItemByPhase, phase)) {
    return target.acceptedItemByPhase[phase];
  }
  return target.acceptedItem;
}

/**
 * Pure registry selector shared by the state projection and the controller.
 * Geometry readiness remains a separate check because runtime-entity bounds
 * are resolved by the active scene without mutating GameState.
 */
export function isChapterFour755TargetStateActive(
  state: GameState,
  target: ChapterFour755InteractionTargetContract
): boolean {
  const chapter = state.chapter4;
  const phase = chapter.phase as ChapterFourPhase;
  if (!isChapterFourPhaseTimeAligned(chapter) && target.id !== "a1_hall_clock") {
    return false;
  }
  return target.activePhases.includes(phase)
    && target.boundsSource.floor === chapter.floor
    && target.roomIds.includes(chapter.roomId)
    && target.activationCondition.test(state);
}

/**
 * Validates every target intent against the same registry entry used by the
 * projection. A null result means the shared floor/room/mode/item/story/spatial
 * contract accepted the request; the controller still owns the resulting
 * story transaction.
 */
export function validateChapterFour755TargetIntentContract(
  state: GameState,
  input: ChapterFour755TargetIntentContractInput,
  resolvedTarget?: ChapterFour755InteractionTargetContract
): ChapterFour755TargetContractRejection | null {
  const target = resolvedTarget ?? getChapterFour755TargetContract(input.targetId);
  if (!target) return "locked";
  if (target.id !== input.targetId) return "locked";
  // Registry entries for runtime entities remain closed. The controller may
  // pass a temporary resolver-produced contract with validated world bounds.
  if (target.contractPending
    || target.bounds === null
    || target.activation === "runtime_entity") {
    return "locked";
  }

  const phase = state.chapter4.phase as ChapterFourPhase;
  if (!isChapterFourPhaseTimeAligned(state.chapter4) && target.id !== "a1_hall_clock") {
    return "locked";
  }
  if (!target.activePhases.includes(phase)
    || target.boundsSource.floor !== state.chapter4.floor
    || !target.roomIds.includes(state.chapter4.roomId)) {
    return "locked";
  }

  const requiredMode = selectChapterFour755RequiredMode(target, phase);
  if (requiredMode !== undefined && requiredMode !== state.chapter4.mode) {
    return "wrong_mode";
  }

  const acceptedItem = selectChapterFour755AcceptedItem(target, phase);
  if (acceptedItem !== undefined && acceptedItem !== null) {
    if (input.itemId !== acceptedItem || !state.items[acceptedItem]) return "wrong_item";
  } else if (input.itemId !== undefined) {
    return "wrong_item";
  }
  if (!target.activationCondition.test(state)) return "locked";
  if (input.spatial.distance === "too_far") return "too_far";
  return null;
}

export function isChapterFour755TargetProjectable(
  target: ChapterFour755InteractionTargetContract,
  phase: ChapterFourPhase
): boolean {
  if (!target.activePhases.includes(phase)) return false;
  if (target.activation === "runtime_entity") {
    return CHAPTER_FOUR_755_CALIBRATED_RUNTIME_TARGET_IDS.has(target.id);
  }
  return target.bounds !== null && !target.contractPending;
}

/**
 * Projects only committed controller state into the recoverable bakery visual
 * state. Scene timeouts and rejected or incomplete completion responses use
 * this selector before scheduling another stop handshake.
 */
export function selectChapterFour755BakeryCommittedRuntimeState(
  state: GameState
): Readonly<ChapterFour755BakeryCommittedRuntimeState> {
  const active = state.chapter4.phase === "bakery_hour_hand"
    && state.chapter4.timeState === "1225_bakery";
  const lampLit = hasChapterFourFact(state, "bakery_conveyor_lamp_inspected");
  const exposed = hasChapterFourFact(state, "bakery_hour_hand_exposed");
  const installed = hasChapterFourFact(state, "hour_hand_installed");
  const collected = installed
    || hasChapterFourFact(state, "bakery_hour_hand_collected")
    || ownsChapterFourItem(state, "oldClockHourHand");
  const conveyorStopped = active && exposed && !installed;
  const hourHandVisible = conveyorStopped && !collected;
  return Object.freeze({
    lampLit,
    conveyorStopped,
    crowdPaused: conveyorStopped,
    hourHandVisible,
    glintVisible: hourHandVisible,
    retryStopHandshake: active && lampLit && !exposed && !collected && !installed
  });
}

export function resolveChapterFour755RuntimeEntityTarget(
  targetId: ChapterFour755InteractionTargetId,
  entityId: string,
  bounds: Readonly<RpgHalfOpenWorldRect>
): ChapterFour755InteractionTargetContract | null {
  const target = CHAPTER_FOUR_755_INTERACTION_TARGETS[targetId];
  const installation = CHAPTER_FOUR_755_RUNTIME_TARGET_INSTALLATIONS.get(targetId);
  if (!target
    || !installation
    || target.boundsSource.kind !== "runtime_entity"
    || target.boundsSource.entityId !== entityId
    || !isChapterFour755RuntimeBounds(bounds)
    || installation.entityId !== entityId
    || !sameHalfOpenWorldRect(bounds, installation.bounds)) {
    return null;
  }
  const resolvedBounds = installation.bounds;
  return Object.freeze({
    ...target,
    bounds: halfOpenRect(
      resolvedBounds.x,
      resolvedBounds.y,
      resolvedBounds.width,
      resolvedBounds.height
    ),
    activation: "phase_exclusive",
    contractPending: false
  });
}

export function getChapterFour755RuntimeTargetInstallation(
  targetId: ChapterFour755InteractionTargetId
): Readonly<ChapterFourLayoutRuntimeTargetInstallation> | null {
  return CHAPTER_FOUR_755_RUNTIME_TARGET_INSTALLATIONS.get(targetId) ?? null;
}

export function isChapterFour755RuntimeBounds(
  bounds: Readonly<RpgHalfOpenWorldRect>
): boolean {
  return isValidHalfOpenRect(bounds)
    && bounds.x >= 0
    && bounds.y >= 0
    && bounds.x + bounds.width <= CHAPTER_FOUR_755_WORLD_BOUNDS.width
    && bounds.y + bounds.height <= CHAPTER_FOUR_755_WORLD_BOUNDS.height;
}

export function isPointInsideChapterFour755Bounds(
  bounds: Readonly<RpgHalfOpenWorldRect>,
  x: number,
  y: number
): boolean {
  return x >= bounds.x
    && x < bounds.x + bounds.width
    && y >= bounds.y
    && y < bounds.y + bounds.height;
}

export function resolveChapterFour755SpatialAttestationTarget(
  targetId: string,
  runtimeTarget?: ChapterFour755RuntimeTargetContext
): {
  contract: ChapterFour755InteractionTargetContract;
  context: ChapterFour755RuntimeTargetContext;
} | null {
  const target = getChapterFour755TargetContract(targetId);
  if (!target) return null;
  if (target.boundsSource.kind === "runtime_entity") {
    if (!runtimeTarget
      || runtimeTarget.targetId !== target.id
      || runtimeTarget.entityId !== target.boundsSource.entityId) return null;
    const resolved = resolveChapterFour755RuntimeEntityTarget(
      target.id,
      runtimeTarget.entityId,
      runtimeTarget.bounds
    );
    return resolved ? { contract: resolved, context: runtimeTarget } : null;
  }
  if (runtimeTarget || !target.bounds || target.contractPending) return null;
  return {
    contract: target,
    context: {
      targetId: target.id,
      entityId: target.boundsSource.anchorId,
      bounds: target.bounds
    }
  };
}

export function revalidateChapterFour755SpatialAttestation(options: {
  request: ChapterFour755SpatialAttestationRequest;
  responses: readonly unknown[];
  target: ChapterFour755InteractionTargetContract;
  claimedSpatial: ChapterFour755TargetSpatialResult;
}): ChapterFour755SpatialAttestationResult {
  const { request, responses, target, claimedSpatial } = options;
  if (responses.length === 0) return { accepted: false, reason: "no_response" };
  if (responses.length !== 1) return { accepted: false, reason: "multiple_responses" };
  const raw = responses[0];
  if (!isChapterFour755SpatialAttestationResponse(raw)) {
    return { accepted: false, reason: "invalid_response" };
  }
  if (raw.requestId !== request.requestId || raw.attestationId !== request.attestationId) {
    return { accepted: false, reason: "mismatched_nonce" };
  }
  if (raw.sceneKey !== request.sceneKey) {
    return { accepted: false, reason: "wrong_scene" };
  }
  if (raw.targetId !== request.targetId || raw.entityId !== request.entityId) {
    return { accepted: false, reason: "wrong_target" };
  }
  if (!sameHalfOpenWorldRect(raw.bounds, request.bounds)) {
    return { accepted: false, reason: "wrong_bounds" };
  }
  if (raw.committedPhase !== request.committedPhase
    || raw.appliedPhase !== request.committedPhase
    || raw.appliedPlateSignature.length === 0) {
    return { accepted: false, reason: "stale_projection" };
  }
  const { x, y } = raw.playerFootPoint;
  if (!Number.isFinite(x)
    || !Number.isFinite(y)
    || x < 0
    || y < 0
    || x > CHAPTER_FOUR_755_WORLD_BOUNDS.width
    || y > CHAPTER_FOUR_755_WORLD_BOUNDS.height) {
    return { accepted: false, reason: "invalid_player" };
  }
  const spatialTarget: RpgSpatialInteractionTarget = {
    id: target.id,
    label: target.label,
    x: request.bounds.x + request.bounds.width / 2,
    y: request.bounds.y + request.bounds.height / 2,
    width: request.bounds.width,
    height: request.bounds.height,
    proximity: target.proximity
  };
  const distancePx = distanceFromPlayerToRpgTarget(spatialTarget, x, y);
  const spatial: ChapterFour755TargetSpatialResult = {
    distance: distancePx <= target.proximity ? "within_range" : "too_far"
  };
  if (spatial.distance !== claimedSpatial.distance) {
    return { accepted: false, reason: "spatial_claim_mismatch" };
  }
  return { accepted: true, spatial, distancePx, response: raw };
}

export function isChapterFour755SpatialAttestationResponse(
  value: unknown
): value is ChapterFour755SpatialAttestationResponse {
  if (!isRecordValue(value)
    || !hasExactRecordKeys(value, [
      "requestId", "attestationId", "sceneKey", "committedPhase", "targetId",
      "entityId", "bounds", "appliedPhase", "appliedPlateSignature",
      "playerFootPoint"
    ])) return false;
  if (typeof value.requestId !== "string"
    || typeof value.attestationId !== "string"
    || value.sceneKey !== CHAPTER_FOUR_755_SCENE_KEY
    || typeof value.committedPhase !== "string"
    || typeof value.targetId !== "string"
    || typeof value.entityId !== "string"
    || typeof value.appliedPhase !== "string"
    || typeof value.appliedPlateSignature !== "string"
    || !isRecordValue(value.bounds)
    || !hasExactRecordKeys(value.bounds, ["x", "y", "width", "height"])
    || !isChapterFour755RuntimeBounds(value.bounds as unknown as RpgHalfOpenWorldRect)
    || !isRecordValue(value.playerFootPoint)
    || !hasExactRecordKeys(value.playerFootPoint, ["x", "y"])
    || typeof value.playerFootPoint.x !== "number"
    || typeof value.playerFootPoint.y !== "number") return false;
  const target = getChapterFour755TargetContract(value.targetId);
  return Boolean(target)
    && target!.activePhases.includes(value.committedPhase as ChapterFourPhase)
    && target!.activePhases.includes(value.appliedPhase as ChapterFourPhase);
}

export function isChapterFour755SpatialAttestationRequest(
  value: unknown
): value is ChapterFour755SpatialAttestationRequest {
  if (!isRecordValue(value)
    || !hasExactRecordKeys(value, [
      "requestId", "attestationId", "sceneKey", "committedPhase",
      "targetId", "entityId", "bounds"
    ])
    || typeof value.requestId !== "string"
    || value.requestId.length === 0
    || typeof value.attestationId !== "string"
    || value.attestationId.length === 0
    || value.sceneKey !== CHAPTER_FOUR_755_SCENE_KEY
    || typeof value.committedPhase !== "string"
    || typeof value.targetId !== "string"
    || typeof value.entityId !== "string"
    || !isRecordValue(value.bounds)
    || !hasExactRecordKeys(value.bounds, ["x", "y", "width", "height"])
    || !isChapterFour755RuntimeBounds(value.bounds as unknown as RpgHalfOpenWorldRect)) {
    return false;
  }
  const target = getChapterFour755TargetContract(value.targetId);
  return Boolean(target)
    && target!.activePhases.includes(value.committedPhase as ChapterFourPhase);
}

function isRecordValue(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function hasExactRecordKeys(value: Record<string, unknown>, keys: readonly string[]): boolean {
  const actual = Object.keys(value).sort();
  const expected = [...keys].sort();
  return actual.length === expected.length
    && actual.every((key, index) => key === expected[index]);
}

function isValidHalfOpenRect(bounds: Readonly<RpgHalfOpenWorldRect>): boolean {
  return Number.isFinite(bounds.x)
    && Number.isFinite(bounds.y)
    && Number.isFinite(bounds.width)
    && Number.isFinite(bounds.height)
    && bounds.width > 0
    && bounds.height > 0;
}

function sameHalfOpenWorldRect(
  actual: Readonly<RpgHalfOpenWorldRect>,
  expected: Readonly<RpgHalfOpenWorldRect>
): boolean {
  return actual.x === expected.x
    && actual.y === expected.y
    && actual.width === expected.width
    && actual.height === expected.height;
}

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
  /** Visible entity bounds, always used for proximity checks. */
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
    && x < bounds.right
    && y >= bounds.top
    && y < bounds.bottom;
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
