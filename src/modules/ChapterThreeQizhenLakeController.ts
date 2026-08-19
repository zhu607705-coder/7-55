import type { EventBus } from "../core/EventBus";
import type {
  GameStore,
  ItemId,
  QizhenFishingSpotId,
  QizhenJournalDraft,
  QizhenJournalState,
  QizhenLakeMode,
  QizhenLakeZone,
  QizhenMapClueId,
  QizhenPaddleDirection,
  QizhenPaddleSide,
  QizhenPhotoRecipe,
  QizhenPhotoRecord,
  QizhenPhotoSpotId,
  RpgCheckpointId
} from "../core/types";
import {
  applyDraft,
  canCaptureSpot,
  clearPendingDraft,
  derivePhotoTags,
  draftIdFor,
  markSpotPublished,
  photoIdFor,
  upsertPhoto
} from "./QizhenJournalModel";

export type QizhenMapClueResult = "added" | "already_added" | "ready_to_confirm" | "wrong_item" | "inactive";
export type QizhenActionResult =
  | "accepted"
  | "inactive"
  | "locked"
  | "wrong_mode"
  | "wrong_item"
  | "unobserved"
  | "direct_paper_failure"
  | "already_complete";

export type QizhenDockOutfitPart = "kayak" | "left_paddle" | "right_paddle";

/** 拍照/草稿事务的拒绝原因码。host 按原因码选择用户可见反馈。 */
export type QizhenPhotoCaptureRejection =
  | "inactive"
  | "swan_chase"
  | "journal_locked"
  | "journal_archived"
  | "unknown_spot";

export type QizhenPhotoPrecheckResult =
  | { accepted: true; spotId: QizhenPhotoSpotId }
  | { accepted: false; reason: QizhenPhotoCaptureRejection };

/** 场景冻结帧透传给 capturePhoto 的输入。capturedAtSeconds 取湖区会话单调秒数。 */
export interface QizhenCapturePhotoInput {
  spotId: QizhenPhotoSpotId;
  recipe: QizhenPhotoRecipe;
  speed: number;
  roll: number;
  kind: "main" | "spot";
  capturedAtSeconds?: number;
}

export type QizhenCapturePhotoResult =
  | { accepted: true; photo: QizhenPhotoRecord; draft: QizhenJournalDraft; duplicate: boolean }
  | { accepted: false; reason: QizhenPhotoCaptureRejection };

export type QizhenJournalDraftRejection =
  | QizhenPhotoCaptureRejection
  | "orphan_photo"
  | "draft_mismatch"
  | "incomplete_draft";

export type QizhenJournalDraftSaveResult =
  | { accepted: true; draft: QizhenJournalDraft; duplicate: boolean }
  | { accepted: false; reason: QizhenJournalDraftRejection };

export interface QizhenJournalDraftDiscardResult {
  accepted: true;
  /** 是否真的丢弃了未提交内容(无存草稿或无 pendingDraft 时为 false)。 */
  discarded: boolean;
}

/**
 * 发布事务的拒绝原因码(主帖与补拍回复共用并集;各方法只产出自己的子集)。
 * 主帖发布:journal_locked / no_draft / incomplete_draft / offline / swan_chase /
 * already_published / archived。补拍回复另产出 not_open / no_photo。
 * 重复调用命中幂等键时返回 { accepted: true, duplicate: true },不走拒绝码。
 */
export type QizhenJournalPublishRejection =
  | "journal_locked"
  | "no_draft"
  | "incomplete_draft"
  | "offline"
  | "swan_chase"
  | "already_published"
  | "archived"
  | "not_open"
  | "no_photo";

export type QizhenJournalPublishResult =
  | { accepted: true; duplicate?: boolean }
  | { accepted: false; reason: QizhenJournalPublishRejection };

const MAP_CLUE_ITEMS: Readonly<Record<QizhenMapClueId, ItemId>> = {
  bridge: "bridgeKeyword",
  reflection: "reflectionKeyword",
  lake: "lakeKeyword"
};

const ITEM_TO_MAP_CLUE: Partial<Record<ItemId, QizhenMapClueId>> = {
  bridgeKeyword: "bridge",
  reflectionKeyword: "reflection",
  lakeKeyword: "lake"
};

const SPOT_ITEM: Partial<Record<QizhenFishingSpotId, ItemId>> = {
  locker_key: "rustedLockerKey",
  net_frame: "brokenNetFrame",
  fish: "smallCarp"
};

const ZONE_CHECKPOINTS: Readonly<Record<QizhenLakeZone, RpgCheckpointId>> = {
  dock: "qizhen_dock",
  open_water: "qizhen_open_water",
  channel: "qizhen_channel",
  swan_cove: "qizhen_swan_cove"
};

const ZONE_SAFE_SPAWNS = {
  dock: "dock_kayak",
  open_water: "open_water_entry",
  channel: "channel_entry",
  swan_cove: "swan_cove_entry"
} as const;

export class ChapterThreeQizhenLakeController {
  constructor(private readonly store: GameStore, private readonly events: EventBus) {}

  acknowledgeLocationBriefing(): boolean {
    const state = this.store.getState();
    if (!state.qizhenLake.active || state.qizhenLake.phase !== "location_search") return false;
    if (!state.qizhenLake.locationBriefingSeen) {
      this.store.setState((current) => ({
        ...current,
        qizhenLake: { ...current.qizhenLake, locationBriefingSeen: true }
      }));
    }
    this.events.emit("qizhen_location_briefing_seen");
    return true;
  }

  collectBridgeClue(): boolean {
    return this.collectClue("bridge", "qizhen_bridge_clue_found");
  }

  collectReflectionClue(): boolean {
    return this.collectClue("reflection", "qizhen_reflection_clue_found");
  }

  collectLakeClue(): boolean {
    return this.collectClue("lake", "qizhen_lake_clue_found");
  }

  addMapClue(itemId: ItemId): QizhenMapClueResult {
    const state = this.store.getState();
    if (!state.qizhenLake.active || state.qizhenLake.phase !== "location_search") return "inactive";
    const clueId = ITEM_TO_MAP_CLUE[itemId];
    if (!clueId || !state.items[itemId]) return "wrong_item";
    if (state.qizhenLake.mapClueIds.includes(clueId)) return "already_added";
    const mapClueIds = [...state.qizhenLake.mapClueIds, clueId];
    const readyToConfirm = mapClueIds.length === 3;
    this.store.setState((current) => ({
      ...current,
      items: { ...current.items, [itemId]: false },
      ui: current.ui.selectedItem === itemId ? { ...current.ui, selectedItem: null } : current.ui,
      qizhenLake: {
        ...current.qizhenLake,
        mapClueIds
      }
    }));
    this.events.emit("use_item", { itemId, targetId: "qizhen_map_search", result: "consume" });
    this.events.emit(readyToConfirm ? "qizhen_map_clues_ready" : "qizhen_map_clue_added", {
      clueId,
      count: mapClueIds.length
    });
    return readyToConfirm ? "ready_to_confirm" : "added";
  }

  getMapClueCount(): number {
    return this.store.getState().qizhenLake.mapClueIds.length;
  }

  confirmMapLocation(): boolean {
    const state = this.store.getState();
    if (!state.qizhenLake.active || state.qizhenLake.phase !== "location_search") return false;
    const clueIds = new Set(state.qizhenLake.mapClueIds);
    if (!(["bridge", "reflection", "lake"] as const).every((clueId) => clueIds.has(clueId))) return false;
    this.store.setState((current) => ({
      ...current,
      qizhenLake: {
        ...current.qizhenLake,
        phase: "lake_unlocked"
      }
    }));
    this.events.emit("qizhen_location_solved", {
      locationId: "qizhen_lake",
      clueIds: [...state.qizhenLake.mapClueIds]
    });
    return true;
  }

  enterLake(): boolean {
    const state = this.store.getState();
    if (!state.qizhenLake.active || ["inactive", "location_search"].includes(state.qizhenLake.phase)) return false;
    const firstEntry = state.qizhenLake.phase === "lake_unlocked";
    this.store.setState((current) => ({
      ...current,
      runtimeMode: "rpg",
      rpgScene: "qizhen_lake",
      rpgCheckpoint: firstEntry ? "qizhen_dock" : checkpointForCurrentLakeState(current),
      ui: { ...current.ui, inventoryOpen: false, selectedItem: null },
      qizhenLake: {
        ...current.qizhenLake,
        active: true,
        phase: firstEntry ? "dock_outfitting" : current.qizhenLake.phase,
        mode: firstEntry || current.qizhenLake.zone === "dock" ? "light" : current.qizhenLake.mode,
        zone: firstEntry ? "dock" : current.qizhenLake.zone,
        vehicle: firstEntry ? "on_foot" : current.qizhenLake.vehicle,
        safeSpawnId: firstEntry ? "dock_entry" : current.qizhenLake.safeSpawnId
      }
    }));
    this.events.emit("qizhen_lake_entered", { phase: firstEntry ? "dock_outfitting" : state.qizhenLake.phase });
    return true;
  }

  enterCampusApproach(): boolean {
    const state = this.store.getState();
    if (!state.qizhenLake.active || ["inactive", "location_search"].includes(state.qizhenLake.phase)) return false;
    this.store.setState((current) => ({
      ...current,
      runtimeMode: "rpg",
      rpgScene: "campus_qizhen_loop",
      rpgCheckpoint: "campus_qizhen_gate",
      ui: { ...current.ui, inventoryOpen: false, selectedItem: null, zjudingPage: "hub" }
    }));
    this.events.emit("qizhen_campus_approach_entered", { checkpoint: "campus_qizhen_gate" });
    return true;
  }

  leaveLake(): boolean {
    const state = this.store.getState();
    if (state.rpgScene !== "qizhen_lake") return false;
    if (state.qizhenLake.zone !== "dock" || state.qizhenLake.vehicle !== "on_foot") {
      this.events.emit("qizhen_lake_leave_rejected", { reason: "return_to_dock" });
      return false;
    }
    this.store.setState((current) => ({
      ...current,
      runtimeMode: "rpg",
      rpgScene: "campus_qizhen_loop",
      rpgCheckpoint: "campus_qizhen_gate",
      ui: { ...current.ui, inventoryOpen: false, selectedItem: null }
    }));
    this.events.emit("qizhen_lake_left");
    return true;
  }

  markIntroSeen(): boolean {
    const state = this.store.getState();
    if (!state.qizhenLake.active || state.qizhenLake.introSeen) return false;
    this.store.setState((current) => ({
      ...current,
      qizhenLake: { ...current.qizhenLake, introSeen: true }
    }));
    return true;
  }

  setMode(mode: QizhenLakeMode): boolean {
    const state = this.store.getState();
    if (!state.qizhenLake.active || ["inactive", "location_search", "lake_unlocked", "swan_chase", "complete"].includes(state.qizhenLake.phase)) {
      return false;
    }
    if (state.qizhenLake.mode === mode) return true;
    this.store.setState((current) => ({
      ...current,
      qizhenLake: { ...current.qizhenLake, mode }
    }));
    this.events.emit("qizhen_mode_changed", { mode });
    return true;
  }

  collectOutfit(part: QizhenDockOutfitPart): QizhenActionResult {
    const state = this.store.getState();
    if (state.qizhenLake.phase !== "dock_outfitting" || state.qizhenLake.zone !== "dock") return "inactive";
    if (state.qizhenLake.mode !== "light") return "wrong_mode";

    const alreadyCollected = part === "kayak"
      ? state.qizhenLake.kayakEquipped
      : part === "left_paddle"
        ? state.qizhenLake.leftPaddleEquipped
        : state.qizhenLake.rightPaddleEquipped;
    if (alreadyCollected) return "already_complete";

    const kayakEquipped = state.qizhenLake.kayakEquipped || part === "kayak";
    const leftPaddleEquipped = state.qizhenLake.leftPaddleEquipped || part === "left_paddle";
    const rightPaddleEquipped = state.qizhenLake.rightPaddleEquipped || part === "right_paddle";
    const complete = kayakEquipped && leftPaddleEquipped && rightPaddleEquipped;
    const collectedCount = Number(kayakEquipped) + Number(leftPaddleEquipped) + Number(rightPaddleEquipped);

    this.store.setState((current) => ({
      ...current,
      rpgCheckpoint: "qizhen_dock",
      qizhenLake: {
        ...current.qizhenLake,
        phase: complete ? "boarding_tutorial" : "dock_outfitting",
        kayakEquipped,
        leftPaddleEquipped,
        rightPaddleEquipped,
        safeSpawnId: complete ? "dock_kayak" : current.qizhenLake.safeSpawnId
      }
    }));
    this.events.emit("qizhen_outfit_part_collected", {
      part,
      collectedCount,
      complete,
      leftPaddle: leftPaddleEquipped ? "willow_branch" : null,
      rightPaddle: rightPaddleEquipped ? "no_swimming_sign" : null
    });
    return "accepted";
  }

  boardKayak(): QizhenActionResult {
    const state = this.store.getState();
    if (state.qizhenLake.zone !== "dock" || state.qizhenLake.vehicle !== "on_foot") return "inactive";
    if (!["boarding_tutorial", "lake_exploration", "tool_chain", "swan_exchange", "paper_capture"].includes(state.qizhenLake.phase)) {
      return "inactive";
    }
    if (state.qizhenLake.mode !== "light") return "wrong_mode";
    if (!state.qizhenLake.kayakEquipped || !state.qizhenLake.leftPaddleEquipped || !state.qizhenLake.rightPaddleEquipped) {
      return "locked";
    }
    this.store.setState((current) => ({
      ...current,
      qizhenLake: {
        ...current.qizhenLake,
        vehicle: "kayak",
        boardingStrokeCount: current.qizhenLake.boardingTutorialCompleted ? current.qizhenLake.boardingStrokeCount : 0,
        boardingLastSide: current.qizhenLake.boardingTutorialCompleted ? current.qizhenLake.boardingLastSide : null,
        safeSpawnId: "dock_kayak"
      }
    }));
    this.events.emit("qizhen_kayak_boarded");
    return "accepted";
  }

  recordPaddleStroke(
    side: QizhenPaddleSide,
    direction: QizhenPaddleDirection = "forward"
  ): QizhenActionResult {
    const state = this.store.getState();
    if (state.qizhenLake.vehicle !== "kayak") return "inactive";
    if (state.qizhenLake.phase !== "boarding_tutorial") {
      this.events.emit("qizhen_paddle_stroke_recorded", { side, direction, tutorial: false });
      return "accepted";
    }
    if (direction === "reverse") {
      this.events.emit("qizhen_boarding_stroke_recorded", {
        side,
        direction,
        alternating: false,
        count: state.qizhenLake.boardingStrokeCount
      });
      return "accepted";
    }
    const alternating = state.qizhenLake.boardingLastSide !== side;
    const boardingStrokeCount = alternating ? state.qizhenLake.boardingStrokeCount + 1 : 0;
    const completed = boardingStrokeCount >= 4;
    this.store.setState((current) => ({
      ...current,
      rpgCheckpoint: completed ? "qizhen_open_water" : current.rpgCheckpoint,
      qizhenLake: {
        ...current.qizhenLake,
        boardingStrokeCount,
        boardingLastSide: side,
        boardingTutorialCompleted: completed,
        phase: completed ? "lake_exploration" : current.qizhenLake.phase,
        zone: completed ? "open_water" : current.qizhenLake.zone,
        safeSpawnId: completed ? "open_water_entry" : current.qizhenLake.safeSpawnId
      }
    }));
    this.events.emit(completed ? "qizhen_boarding_completed" : "qizhen_boarding_stroke_recorded", {
      side,
      direction,
      alternating,
      count: boardingStrokeCount
    });
    return "accepted";
  }

  recordCapsize(reason: string): QizhenActionResult {
    const state = this.store.getState();
    if (state.qizhenLake.vehicle !== "kayak") return "inactive";
    const inTutorial = state.qizhenLake.phase === "boarding_tutorial";
    const inChase = state.qizhenLake.phase === "swan_chase";
    const nextCapsizeCount = state.qizhenLake.capsizeCount + 1;
    this.store.setState((current) => ({
      ...current,
      rpgCheckpoint: inTutorial ? "qizhen_dock" : checkpointForCurrentLakeState(current),
      qizhenLake: {
        ...current.qizhenLake,
        capsizeCount: nextCapsizeCount,
        chaseDistance: inChase ? 0 : current.qizhenLake.chaseDistance,
        chaseAttempts: inChase
          ? current.qizhenLake.chaseAttempts + 1
          : current.qizhenLake.chaseAttempts,
        boardingStrokeCount: inTutorial ? 0 : current.qizhenLake.boardingStrokeCount,
        boardingLastSide: inTutorial ? null : current.qizhenLake.boardingLastSide,
        safeSpawnId: inTutorial ? "dock_kayak" : current.qizhenLake.safeSpawnId
      }
    }));
    this.events.emit("qizhen_capsize_recovered", {
      reason,
      zone: state.qizhenLake.zone,
      count: nextCapsizeCount
    });
    if (nextCapsizeCount === 6) {
      this.events.emit("qizhen_capsize_loss_subtitle_unlocked", {
        count: nextCapsizeCount
      });
    }
    return "accepted";
  }

  enterZone(zone: QizhenLakeZone): QizhenActionResult {
    const state = this.store.getState();
    if (state.qizhenLake.vehicle !== "kayak" || !state.qizhenLake.boardingTutorialCompleted) return "locked";
    if (state.qizhenLake.phase === "swan_chase" && zone !== "channel" && zone !== "dock") return "locked";
    const arrivedAtDock = zone === "dock";
    const safeSpawnId = state.qizhenLake.phase === "swan_chase" && zone === "channel"
      ? "channel_chase"
      : arrivedAtDock ? "dock_entry" : ZONE_SAFE_SPAWNS[zone];
    this.store.setState((current) => ({
      ...current,
      rpgCheckpoint: current.qizhenLake.phase === "swan_chase" && zone === "channel"
        ? "qizhen_chase"
        : ZONE_CHECKPOINTS[zone],
      qizhenLake: {
        ...current.qizhenLake,
        zone,
        vehicle: arrivedAtDock ? "on_foot" : current.qizhenLake.vehicle,
        mode: arrivedAtDock ? "light" : current.qizhenLake.mode,
        safeSpawnId
      }
    }));
    if (arrivedAtDock && state.qizhenLake.mode !== "light") {
      this.events.emit("qizhen_mode_changed", { mode: "light", reason: "dock_return" });
    }
    this.events.emit("qizhen_zone_entered", { zone, vehicle: arrivedAtDock ? "on_foot" : "kayak" });
    return "accepted";
  }

  observeReflection(targetId: string): QizhenActionResult {
    const state = this.store.getState();
    if (!["lake_exploration", "tool_chain", "swan_exchange", "paper_capture"].includes(state.qizhenLake.phase)) return "inactive";
    if (state.qizhenLake.mode !== "dark") return "wrong_mode";
    const spotId = spotFromTarget(targetId);
    const observed = new Set(state.qizhenLake.observedFishingSpotIds);
    if (spotId) observed.add(spotId);
    this.store.setState((current) => ({
      ...current,
      qizhenLake: {
        ...current.qizhenLake,
        reflectionLocationObserved: current.qizhenLake.reflectionLocationObserved || spotId === "paper",
        observedFishingSpotIds: [...observed]
      }
    }));
    this.events.emit("qizhen_reflection_observed", { targetId, spotId });
    return "accepted";
  }

  findFishingRod(): QizhenActionResult {
    const state = this.store.getState();
    if (!["lake_exploration", "tool_chain"].includes(state.qizhenLake.phase)) return "inactive";
    if (state.qizhenLake.mode !== "light") return "wrong_mode";
    if (!state.qizhenLake.reflectionLocationObserved) return "unobserved";
    if (state.qizhenLake.rodFound || state.items.fishingRod || state.items.magneticFishingRod) return "already_complete";
    this.store.setState((current) => ({
      ...current,
      items: { ...current.items, fishingRod: true },
      qizhenLake: { ...current.qizhenLake, rodFound: true, phase: "tool_chain" }
    }));
    this.events.emit("get_item", { itemId: "fishingRod", sourceScene: "qizhen_lake" });
    this.events.emit("qizhen_fishing_rod_found");
    return "accepted";
  }

  attachDecoyBait(): QizhenActionResult {
    const state = this.store.getState();
    if (!["lake_exploration", "tool_chain"].includes(state.qizhenLake.phase)) return "inactive";
    if (state.qizhenLake.mode !== "light") return "wrong_mode";
    if (!state.items.fishingRod || !state.items.decoyPaper) return "wrong_item";
    if (state.qizhenLake.decoyBaitAttached) return "already_complete";
    this.store.setState((current) => ({
      ...current,
      items: { ...current.items, decoyPaper: false },
      ui: current.ui.selectedItem === "decoyPaper" ? { ...current.ui, selectedItem: null } : current.ui,
      qizhenLake: { ...current.qizhenLake, decoyBaitAttached: true, phase: "tool_chain" }
    }));
    this.events.emit("use_item", { itemId: "decoyPaper", targetId: "fishingRod", result: "consume" });
    this.events.emit("qizhen_decoy_bait_attached");
    return "accepted";
  }

  /** castAt 的只读镜像：相同验证、零副作用、零事件、零存档写入。 */
  precheckCast(spotId: QizhenFishingSpotId): QizhenActionResult {
    return this.validateCast(spotId);
  }

  castAt(spotId: QizhenFishingSpotId): QizhenActionResult {
    const validation = this.validateCast(spotId);
    if (validation === "direct_paper_failure") {
      const state = this.store.getState();
      this.store.setState((current) => ({
        ...current,
        qizhenLake: {
          ...current.qizhenLake,
          directPaperCastFailures: current.qizhenLake.directPaperCastFailures + 1
        }
      }));
      this.events.emit("qizhen_direct_paper_cast_failed", {
        attempts: state.qizhenLake.directPaperCastFailures + 1
      });
      return validation;
    }
    if (validation !== "accepted") return validation;
    if (spotId === "locker_key") return this.grantCaughtItem(spotId, "rustedLockerKey");
    if (spotId === "net_frame") return this.grantCaughtItem(spotId, "brokenNetFrame");
    if (spotId === "fish") {
      this.store.setState((current) => ({
        ...current,
        items: { ...current.items, fishFeedPellets: false, smallCarp: true },
        ui: current.ui.selectedItem === "fishFeedPellets" ? { ...current.ui, selectedItem: null } : current.ui,
        qizhenLake: { ...current.qizhenLake, fishCaught: true, phase: "swan_exchange" }
      }));
      this.events.emit("use_item", { itemId: "fishFeedPellets", targetId: "qizhen_fishing_fish", result: "consume" });
      this.events.emit("get_item", { itemId: "smallCarp", sourceScene: "qizhen_lake" });
      this.events.emit("qizhen_fish_caught");
      return "accepted";
    }
    return this.capturePaper();
  }

  useItemAt(targetId: string, itemId: ItemId): QizhenActionResult {
    const state = this.store.getState();
    if (state.qizhenLake.mode !== "light") return "wrong_mode";
    if (!state.items[itemId]) return "wrong_item";
    if (targetId === "qizhen_use_item_1") {
      if (itemId !== "rustedLockerKey") return "wrong_item";
      if (state.qizhenLake.lockerOpened) return "already_complete";
      this.atomicTransform("rustedLockerKey", "nylonCord", {
        lockerOpened: true,
        phase: "tool_chain"
      });
      this.events.emit("qizhen_locker_opened");
      return "accepted";
    }
    if (targetId === "qizhen_use_item_4") {
      if (itemId !== "improvisedDipNet" || !state.qizhenLake.netCombined) return "wrong_item";
      if (state.qizhenLake.feedTinRetrieved) return "already_complete";
      this.atomicTransform("improvisedDipNet", "sealedFeedTin", {
        feedTinRetrieved: true,
        phase: "tool_chain"
      });
      this.events.emit("qizhen_feed_tin_retrieved");
      return "accepted";
    }
    if (targetId === "qizhen_use_item_5") {
      if (itemId !== "sealedFeedTin" || !state.qizhenLake.feedTinRetrieved) return "wrong_item";
      if (state.qizhenLake.feedTinOpened) return "already_complete";
      this.atomicTransform("sealedFeedTin", "fishFeedPellets", {
        feedTinOpened: true,
        phase: "tool_chain"
      });
      this.events.emit("qizhen_feed_tin_opened");
      return "accepted";
    }
    return "locked";
  }

  combineItems(itemIds: readonly ItemId[]): QizhenActionResult {
    const state = this.store.getState();
    const items = new Set(itemIds);
    if (items.has("nylonCord") && items.has("brokenNetFrame")) {
      if (!state.items.nylonCord || !state.items.brokenNetFrame) return "wrong_item";
      this.atomicCombine("nylonCord", "brokenNetFrame", "improvisedDipNet", {
        netCombined: true,
        phase: "tool_chain"
      });
      this.events.emit("qizhen_dip_net_combined");
      return "accepted";
    }
    if (items.has("swanMagnet") && items.has("fishingRod")) {
      if (!state.items.swanMagnet || !state.items.fishingRod || !state.qizhenLake.swanFed) return "wrong_item";
      this.atomicCombine("swanMagnet", "fishingRod", "magneticFishingRod", {
        magneticRodCombined: true,
        phase: "paper_capture"
      });
      this.events.emit("qizhen_magnetic_rod_combined");
      return "accepted";
    }
    return "wrong_item";
  }

  recordInventoryCombination(result: ItemId): boolean {
    if (result !== "improvisedDipNet" && result !== "magneticFishingRod") return false;
    this.store.setState((current) => ({
      ...current,
      qizhenLake: {
        ...current.qizhenLake,
        netCombined: result === "improvisedDipNet" ? true : current.qizhenLake.netCombined,
        magneticRodCombined: result === "magneticFishingRod" ? true : current.qizhenLake.magneticRodCombined,
        phase: result === "magneticFishingRod" ? "paper_capture" : "tool_chain"
      }
    }));
    return true;
  }

  feedSwan(itemId: ItemId): QizhenActionResult {
    const state = this.store.getState();
    if (state.qizhenLake.phase !== "swan_exchange" || state.qizhenLake.zone !== "swan_cove") return "inactive";
    if (state.qizhenLake.mode !== "light") return "wrong_mode";
    if (itemId !== "smallCarp" || !state.items.smallCarp) return "wrong_item";
    this.atomicTransform("smallCarp", "swanMagnet", {
      swanFed: true,
      phase: "paper_capture"
    });
    this.events.emit("qizhen_swan_fed");
    return "accepted";
  }

  capturePaper(): QizhenActionResult {
    const state = this.store.getState();
    if (state.qizhenLake.phase !== "paper_capture") return "inactive";
    if (state.qizhenLake.mode !== "light") return "wrong_mode";
    if (!state.items.magneticFishingRod || !state.qizhenLake.magneticRodCombined) return "wrong_item";
    if (!state.qizhenLake.observedFishingSpotIds.includes("paper")) return "unobserved";
    this.store.setState((current) => ({
      ...current,
      rpgCheckpoint: "qizhen_chase",
      qizhenLake: {
        ...current.qizhenLake,
        phase: "swan_chase",
        zone: "channel",
        vehicle: "kayak",
        safeSpawnId: "channel_chase",
        paperCaptured: true,
        swanReleased: true,
        chaseDistance: 0,
        chaseAttempts: current.qizhenLake.chaseAttempts + 1
      }
    }));
    this.events.emit("qizhen_paper_captured");
    this.events.emit("qizhen_swan_released");
    this.events.emit("qizhen_chase_started");
    return "accepted";
  }

  recordChaseProgress(distance: number): QizhenActionResult {
    const state = this.store.getState();
    if (state.qizhenLake.phase !== "swan_chase") return "inactive";
    const chaseDistance = Math.max(0, Math.min(1000, Math.round(distance)));
    this.store.setState((current) => ({
      ...current,
      qizhenLake: {
        ...current.qizhenLake,
        chaseDistance,
        chaseBestDistance: Math.max(current.qizhenLake.chaseBestDistance, chaseDistance)
      }
    }));
    return "accepted";
  }

  recordChaseFailure(reason: string): QizhenActionResult {
    const state = this.store.getState();
    if (state.qizhenLake.phase !== "swan_chase") return "inactive";
    const nextAttempt = state.qizhenLake.chaseAttempts + 1;
    this.store.setState((current) => ({
      ...current,
      rpgCheckpoint: "qizhen_chase",
      qizhenLake: {
        ...current.qizhenLake,
        phase: "swan_chase",
        zone: "channel",
        vehicle: "kayak",
        mode: "light",
        safeSpawnId: "channel_chase",
        chaseDistance: 0,
        chaseAttempts: nextAttempt
      }
    }));
    this.events.emit("qizhen_chase_failed", {
      reason,
      attempt: nextAttempt,
      checkpoint: "qizhen_chase"
    });
    return "accepted";
  }

  completeEscape(): QizhenActionResult {
    const state = this.store.getState();
    if (state.qizhenLake.phase !== "swan_chase") return "inactive";
    this.store.setState((current) => ({
      ...current,
      runtimeMode: "phone",
      currentScene: "phone_home",
      items: { ...current.items, magneticFishingRod: false },
      ui: {
        ...current.ui,
        controlCenterOpen: false,
        inventoryOpen: false,
        selectedItem: null
      },
      rpgCheckpoint: "qizhen_complete",
      qizhenLake: {
        ...current.qizhenLake,
        phase: "complete",
        zone: "dock",
        vehicle: "on_foot",
        safeSpawnId: "dock_entry",
        chaseDistance: 1000,
        chaseBestDistance: Math.max(current.qizhenLake.chaseBestDistance, 1000),
        magneticAttachmentBroken: true,
        transitionReady: true
      },
      chapterThreeInterlude: {
        ...current.chapterThreeInterlude,
        phase: "reboot",
        rebootSeen: false,
        recoveryOpened: false,
        photoFrameIds: [],
        photoSequenceSolved: false,
        voiceClipOrder: [],
        voiceSequenceSolved: false,
        officialNoticeSaved: false,
        routeScreenshotSaved: false,
        networkRecordRead: false,
        evidenceIds: [],
        timelineOrder: [],
        rejectedDecoyIds: [],
        statusClockMarkedUntrusted: false,
        destinationId: null,
        replayUnlocked: false,
        completed: false
      }
    }));
    this.events.emit("use_item", { itemId: "magneticFishingRod", targetId: "qizhen_paper", result: "consume" });
    this.events.emit("qizhen_escape_completed");
    this.events.emit("chapter35_recovery_requested", {
      reason: "qizhen_escape_completed",
      scene: "phone_home"
    });
    return "accepted";
  }

  /**
   * 拍照会话的只读预检：与 precheckCast 同一合同(零 setState、零事件、零存档写入)。
   * 拒绝情形:追逐阶段、帖子已归档、journal locked 且上船教学未完成、未知拍摄点。
   * 上船教学完成后 locked 不再拦截;locked → capture_ready 的推进由 capturePhoto
   * 在首次通过的会话里随写事务完成(controller 拥有的事实)。
   */
  precheckPhotoCapture(spotId: QizhenPhotoSpotId): QizhenPhotoPrecheckResult {
    return this.validatePhotoCapture(spotId);
  }

  capturePhoto(input: QizhenCapturePhotoInput): QizhenCapturePhotoResult {
    const precheck = this.validatePhotoCapture(input.spotId);
    if (!precheck.accepted) {
      this.events.emit("qizhen_photo_capture_rejected", { spotId: input.spotId, reason: precheck.reason });
      return { accepted: false, reason: precheck.reason };
    }
    const state = this.store.getState();
    const journal = state.qizhenLake.journal;
    const tags = derivePhotoTags({ recipe: input.recipe, speed: input.speed, roll: input.roll });
    // kind 由 controller 按 journal 事实派生:lake_center 且主帖未发布 → "main",
    // 其余一律 "spot"。input.kind 只是场景透传的提示,不作为依据。
    const kind = journalCaptureKind(journal, input.spotId);
    const capturedAtSeconds = capturedAtSecondsFor(input.capturedAtSeconds, journal);
    const photoId = photoIdFor(input.spotId, capturedAtSeconds);
    const existing = photoForSpot(journal, input.spotId);
    if (existing && existing.id === photoId && journal.pendingDraft?.photo.id === photoId) {
      // 同一会话内的重复快门/重试得到同一幂等 id:直接返回既有结果,不重复写。
      return { accepted: true, photo: existing, draft: journal.pendingDraft, duplicate: true };
    }
    const photo: QizhenPhotoRecord = {
      id: photoId,
      spotId: input.spotId,
      capturedAtSeconds,
      tags,
      recipe: input.recipe
    };
    // 主帖草稿沿用上次保存的标题/状态选择,重拍不丢选择。
    const draft: QizhenJournalDraft = {
      id: draftIdFor(photoId),
      kind,
      photo,
      titleId: kind === "main" ? journal.mainTitleId : null,
      statusId: kind === "main" ? journal.mainStatusId : null,
      captionId: null
    };
    this.store.setState((current) => {
      const currentJournal = current.qizhenLake.journal;
      const unlocked: QizhenJournalState = currentJournal.status === "locked"
        ? { ...currentJournal, status: "capture_ready" }
        : currentJournal;
      return {
        ...current,
        qizhenLake: {
          ...current.qizhenLake,
          journal: applyDraft(upsertPhoto(unlocked, photo), draft)
        }
      };
    });
    this.emitJournalStatusChanged(journal.status);
    this.events.emit("qizhen_photo_captured", {
      photoId,
      spotId: input.spotId,
      kind,
      capturedAtSeconds,
      tags,
      duplicate: false
    });
    return { accepted: true, photo, draft, duplicate: false };
  }

  saveJournalDraft(draft: QizhenJournalDraft): QizhenJournalDraftSaveResult {
    const state = this.store.getState();
    const journal = state.qizhenLake.journal;
    if (!state.qizhenLake.active || state.qizhenLake.phase === "inactive") {
      return { accepted: false, reason: "inactive" };
    }
    if (state.qizhenLake.phase === "swan_chase") return { accepted: false, reason: "swan_chase" };
    if (journal.status === "archived") return { accepted: false, reason: "journal_archived" };
    if (journal.status === "locked" && !state.qizhenLake.boardingTutorialCompleted) {
      return { accepted: false, reason: "journal_locked" };
    }
    if (draft.id !== draftIdFor(draft.photo.id)) return { accepted: false, reason: "draft_mismatch" };
    const stored = photoForSpot(journal, draft.photo.spotId);
    if (!stored || stored.id !== draft.photo.id) return { accepted: false, reason: "orphan_photo" };
    if (draft.kind === "main" && (!draft.titleId || !draft.statusId)) {
      return { accepted: false, reason: "incomplete_draft" };
    }
    if (draft.kind === "spot" && !draft.captionId) return { accepted: false, reason: "incomplete_draft" };
    const pending = journal.pendingDraft;
    if (pending && journalDraftsEqual(pending, draft)) {
      // 重复保存同一草稿:返回既有结果,不重复写、不重复发事件。
      return { accepted: true, draft: pending, duplicate: true };
    }
    // 只落已知字段;照片引用以存档中的记录为准,防止宿主塞入不一致数据。
    const sanitized: QizhenJournalDraft = {
      id: draft.id,
      kind: draft.kind,
      photo: stored,
      titleId: draft.kind === "main" ? draft.titleId : null,
      statusId: draft.kind === "main" ? draft.statusId : null,
      captionId: draft.kind === "spot" ? draft.captionId : null
    };
    this.store.setState((current) => {
      const currentJournal = current.qizhenLake.journal;
      const unlocked: QizhenJournalState = currentJournal.status === "locked"
        ? { ...currentJournal, status: "capture_ready" }
        : currentJournal;
      return {
        ...current,
        qizhenLake: { ...current.qizhenLake, journal: applyDraft(unlocked, sanitized) }
      };
    });
    this.emitJournalStatusChanged(journal.status);
    this.events.emit("qizhen_journal_draft_saved", {
      draftId: sanitized.id,
      photoId: stored.id,
      kind: sanitized.kind,
      duplicate: false
    });
    return { accepted: true, draft: sanitized, duplicate: false };
  }

  /**
   * 丢弃挂起草稿。reason "close"(关闭会话)时已存草稿保留;未存草稿与显式
   * "retake"(重拍)回滚草稿及其未发布照片,避免存档留下无草稿的孤儿照片。
   * 已发布地点的照片属于帖子楼层事实,不回滚。
   */
  discardJournalDraft(reason: "retake" | "close" = "close"): QizhenJournalDraftDiscardResult {
    const state = this.store.getState();
    const draft = state.qizhenLake.journal.pendingDraft;
    if (!draft) return { accepted: true, discarded: false };
    const draftSaved = draft.kind === "main"
      ? Boolean(draft.titleId && draft.statusId)
      : Boolean(draft.captionId);
    if (reason === "close" && draftSaved) return { accepted: true, discarded: false };
    const published = state.qizhenLake.journal.publishedSpotIds.includes(draft.photo.spotId);
    this.store.setState((current) => {
      let next = clearPendingDraft(current.qizhenLake.journal);
      if (!published) {
        if (draft.kind === "main") {
          if (next.mainPhoto?.id === draft.photo.id) {
            next = {
              ...next,
              mainPhoto: null,
              status: next.status === "main_draft" ? "capture_ready" : next.status
            };
          }
        } else {
          const spotId = draft.photo.spotId as "dock" | "reflection" | "swan_cove";
          if (next.optionalPhotos[spotId]?.id === draft.photo.id) {
            const optionalPhotos = { ...next.optionalPhotos };
            delete optionalPhotos[spotId];
            next = { ...next, optionalPhotos };
          }
        }
      }
      return { ...current, qizhenLake: { ...current.qizhenLake, journal: next } };
    });
    this.emitJournalStatusChanged(state.qizhenLake.journal.status);
    this.events.emit("qizhen_journal_draft_discarded", {
      draftId: draft.id,
      photoId: draft.photo.id,
      spotId: draft.photo.spotId,
      reason
    });
    return { accepted: true, discarded: true };
  }

  /**
   * 主帖发布的只读预检:与 publishMainPost 共享 validateMainPublish,零 setState、
   * 零事件、零存档写入。返回 duplicate 表示主帖已发布、本次是幂等重试。
   */
  precheckJournalPublish(): QizhenJournalPublishResult {
    return this.validateMainPublish();
  }

  /**
   * 发布唯一主帖。幂等键为 threadId + draftId:threadId/threadSeed 在首次成功发布时
   * 生成并持久化;之后重复调用(同一 draftId、或无新 main 草稿的重试)直接返回
   * { accepted: true, duplicate: true },零写入零事件。duplicate 判定先于网络闸门,
   * 因为幂等命中不执行写操作,断网重试已成功的发布仍得到既有结果。
   * 成功时以草稿为准写入 mainTitleId/mainStatusId、status 推进为 "open"、把
   * "lake_center" 记入 publishedSpotIds(与 journalCaptureKind/场景侧判定一致),
   * 并清掉 pendingDraft(草稿选择已镜像入档)。
   */
  publishMainPost(): QizhenJournalPublishResult {
    const check = this.validateMainPublish();
    if (!check.accepted || check.duplicate) return check;
    const state = this.store.getState();
    const journal = state.qizhenLake.journal;
    const draft = journal.pendingDraft?.kind === "main" ? journal.pendingDraft : null;
    const titleId = draft?.titleId ?? null;
    const statusId = draft?.statusId ?? null;
    if (!draft || !titleId || !statusId) {
      // 防御分支:validateMainPublish 已保证 main_draft + 齐全草稿,正常不可达。
      return { accepted: false, reason: "incomplete_draft" };
    }
    const draftId = draft.id;
    // 一次性随机源生成 ≥1 的 32 位整数 seed;已有持久值(数据修复/异常补档)则复用。
    const seed = journal.threadSeed >= 1 ? journal.threadSeed : newThreadSeed();
    const threadId = journal.threadId.length > 0 ? journal.threadId : `qizhen-journal-${seed}`;
    this.store.setState((current) => {
      const journalWithSpot = markSpotPublished(current.qizhenLake.journal, "lake_center");
      return {
        ...current,
        qizhenLake: {
          ...current.qizhenLake,
          journal: {
            ...clearPendingDraft(journalWithSpot),
            status: "open",
            threadId,
            threadSeed: seed,
            mainTitleId: titleId,
            mainStatusId: statusId
          }
        }
      };
    });
    this.emitJournalStatusChanged(journal.status);
    this.events.emit("qizhen_journal_main_published", { threadId, draftId, titleId, statusId });
    return { accepted: true };
  }

  /**
   * 补拍回复发布的只读预检:与 publishPhotoReply 共享 validatePhotoReply,
   * 零 setState、零事件、零存档写入。
   */
  precheckJournalReply(spotId: QizhenPhotoSpotId): QizhenJournalPublishResult {
    return this.validatePhotoReply(spotId);
  }

  /**
   * 把某拍摄点的照片追加为同一帖内的楼主回复。每地点只追加一条:重复调用命中
   * publishedSpotIds 时返回 { accepted: true, duplicate: true },零写入零事件,
   * 网络重试/重复点击不会产生重复楼层。
   * captionId 固化:现有类型没有 per-spot caption 存储字段,回复投影
   * (projectJournalThread)直接读挂起的 pendingDraft,因此发布只标记楼层、
   * 不动 pendingDraft;发布事件顺带透出该地点挂起草稿的 captionId(无则 null)。
   */
  publishPhotoReply(spotId: QizhenPhotoSpotId): QizhenJournalPublishResult {
    const check = this.validatePhotoReply(spotId);
    if (!check.accepted || check.duplicate) return check;
    const pending = this.store.getState().qizhenLake.journal.pendingDraft;
    const captionId = pending?.kind === "spot" && pending.photo.spotId === spotId
      ? pending.captionId
      : null;
    this.store.setState((current) => ({
      ...current,
      qizhenLake: {
        ...current.qizhenLake,
        journal: markSpotPublished(current.qizhenLake.journal, spotId)
      }
    }));
    this.events.emit("qizhen_journal_reply_published", {
      spotId,
      publishedSpotIds: [...this.store.getState().qizhenLake.journal.publishedSpotIds],
      captionId
    });
    return { accepted: true };
  }

  /**
   * publishMainPost 的纯验证段:零 setState、零事件。追逐闸门最先(该阶段一律拒绝);
   * 已发布时同一 draftId(或无新 main 草稿)的重试命中幂等键返回 duplicate,
   * 出现另一份 main 草稿才拒绝 already_published;网络闸门最后,只拦真正的写发布。
   */
  private validateMainPublish(): QizhenJournalPublishResult {
    const state = this.store.getState();
    const journal = state.qizhenLake.journal;
    if (state.qizhenLake.phase === "swan_chase") return { accepted: false, reason: "swan_chase" };
    if (journal.status === "archived") return { accepted: false, reason: "archived" };
    if (journal.status === "open" || journal.status === "summary_ready") {
      const draft = journal.pendingDraft;
      const isRetryOfPublished = !draft
        || draft.kind !== "main"
        || (journal.mainPhoto !== null && draft.id === draftIdFor(journal.mainPhoto.id));
      return isRetryOfPublished
        ? { accepted: true, duplicate: true }
        : { accepted: false, reason: "already_published" };
    }
    if (journal.status === "locked") return { accepted: false, reason: "journal_locked" };
    if (journal.status === "capture_ready") return { accepted: false, reason: "no_draft" };
    // status === "main_draft":发布以挂起的 main 草稿为准。
    const draft = journal.pendingDraft;
    if (!draft || draft.kind !== "main") return { accepted: false, reason: "no_draft" };
    if (!draft.titleId || !draft.statusId) return { accepted: false, reason: "incomplete_draft" };
    if (state.networkMode !== "campus_wifi") return { accepted: false, reason: "offline" };
    return { accepted: true };
  }

  /**
   * publishPhotoReply 的纯验证段:零 setState、零事件。主帖未开(not_open)含
   * capture_ready/main_draft 两种草稿期;open 与 summary_ready(追逐后整理)都允许补发。
   */
  private validatePhotoReply(spotId: QizhenPhotoSpotId): QizhenJournalPublishResult {
    const state = this.store.getState();
    const journal = state.qizhenLake.journal;
    if (state.qizhenLake.phase === "swan_chase") return { accepted: false, reason: "swan_chase" };
    if (journal.status === "archived") return { accepted: false, reason: "archived" };
    if (journal.status === "locked") return { accepted: false, reason: "journal_locked" };
    if (journal.status === "capture_ready" || journal.status === "main_draft") {
      return { accepted: false, reason: "not_open" };
    }
    // status === "open" | "summary_ready":幂等命中先于照片与网络检查。
    if (journal.publishedSpotIds.includes(spotId)) return { accepted: true, duplicate: true };
    const photo = spotId === "lake_center" ? null : journal.optionalPhotos[spotId];
    if (!photo) return { accepted: false, reason: "no_photo" };
    if (state.networkMode !== "campus_wifi") return { accepted: false, reason: "offline" };
    return { accepted: true };
  }

  /** capturePhoto/saveJournalDraft/discardJournalDraft 的公共只读验证段。 */
  private validatePhotoCapture(spotId: QizhenPhotoSpotId): QizhenPhotoPrecheckResult {
    const state = this.store.getState();
    if (!state.qizhenLake.active || state.qizhenLake.phase === "inactive") {
      return { accepted: false, reason: "inactive" };
    }
    if (state.qizhenLake.phase === "swan_chase") return { accepted: false, reason: "swan_chase" };
    const spotCheck = canCaptureSpot(state.qizhenLake.journal, spotId);
    if (!spotCheck.ok) {
      if (spotCheck.reason === "journal_locked" && state.qizhenLake.boardingTutorialCompleted) {
        // 上船教学完成后 locked 视为可拍;状态推进由写事务完成。
        return { accepted: true, spotId };
      }
      const reason: QizhenPhotoCaptureRejection = spotCheck.reason === "journal_archived"
        ? "journal_archived"
        : spotCheck.reason === "unknown_spot"
          ? "unknown_spot"
          : "journal_locked";
      return { accepted: false, reason };
    }
    return { accepted: true, spotId };
  }

  /** 写事务后对比一次状态,有推进才发一次净变化事件。 */
  private emitJournalStatusChanged(previous: QizhenJournalState["status"]): void {
    const current = this.store.getState().qizhenLake.journal.status;
    if (current !== previous) {
      this.events.emit("qizhen_journal_status_changed", { from: previous, to: current });
    }
  }

  /**
   * castAt 的纯验证段：零 setState、零事件、零计数器。
   * 直抛纸条分支只返回 "direct_paper_failure"，其计数与事件副作用留在 castAt。
   */
  private validateCast(spotId: QizhenFishingSpotId): QizhenActionResult {
    const state = this.store.getState();
    if (state.qizhenLake.vehicle !== "kayak" || !["tool_chain", "swan_exchange", "paper_capture"].includes(state.qizhenLake.phase)) {
      return "inactive";
    }
    if (state.qizhenLake.mode !== "light") return "wrong_mode";
    if (!state.qizhenLake.observedFishingSpotIds.includes(spotId)) return "unobserved";
    if (spotId === "paper" && !state.items.magneticFishingRod) return "direct_paper_failure";
    if (spotId === "locker_key") {
      if (!state.items.fishingRod || !state.qizhenLake.decoyBaitAttached) return "wrong_item";
      if (state.items.rustedLockerKey || state.qizhenLake.lockerOpened) return "already_complete";
      return "accepted";
    }
    if (spotId === "net_frame") {
      if (!state.items.fishingRod || !state.qizhenLake.lockerOpened) return "locked";
      if (state.items.brokenNetFrame || state.qizhenLake.netCombined) return "already_complete";
      return "accepted";
    }
    if (spotId === "fish") {
      if (!state.items.fishingRod || !state.items.fishFeedPellets) return "wrong_item";
      if (state.qizhenLake.fishCaught || state.items.smallCarp) return "already_complete";
      return "accepted";
    }
    if (!state.items.magneticFishingRod || !state.qizhenLake.swanFed) return "wrong_item";
    return "accepted";
  }

  private grantCaughtItem(spotId: QizhenFishingSpotId, itemId: ItemId): QizhenActionResult {
    this.store.setState((current) => ({
      ...current,
      items: { ...current.items, [itemId]: true },
      qizhenLake: { ...current.qizhenLake, phase: "tool_chain" }
    }));
    this.events.emit("get_item", { itemId, sourceScene: "qizhen_lake" });
    this.events.emit("qizhen_item_caught", { spotId, itemId });
    return "accepted";
  }

  private atomicTransform(
    consumed: ItemId,
    granted: ItemId,
    qizhenPatch: Partial<GameStore["getState"] extends () => infer T ? T extends { qizhenLake: infer Q } ? Q : never : never>
  ): void {
    this.store.setState((current) => ({
      ...current,
      items: { ...current.items, [consumed]: false, [granted]: true },
      ui: current.ui.selectedItem === consumed ? { ...current.ui, selectedItem: null } : current.ui,
      qizhenLake: { ...current.qizhenLake, ...qizhenPatch }
    }));
    this.events.emit("use_item", { itemId: consumed, targetId: granted, result: "transform" });
    this.events.emit("get_item", { itemId: granted, sourceScene: "qizhen_lake" });
  }

  private atomicCombine(
    a: ItemId,
    b: ItemId,
    result: ItemId,
    qizhenPatch: Partial<GameStore["getState"] extends () => infer T ? T extends { qizhenLake: infer Q } ? Q : never : never>
  ): void {
    this.store.setState((current) => ({
      ...current,
      items: { ...current.items, [a]: false, [b]: false, [result]: true },
      ui: current.ui.selectedItem === a || current.ui.selectedItem === b
        ? { ...current.ui, selectedItem: null }
        : current.ui,
      qizhenLake: { ...current.qizhenLake, ...qizhenPatch }
    }));
    this.events.emit("combine_item", { a, b, result });
    this.events.emit("get_item", { itemId: result, sourceScene: "qizhen_lake" });
  }

  private collectClue(clueId: QizhenMapClueId, eventName: string): boolean {
    const state = this.store.getState();
    if (!state.qizhenLake.active || state.qizhenLake.phase !== "location_search" || !state.items.wetProgram) return false;
    const flagName = `${clueId}ClueFound` as "bridgeClueFound" | "reflectionClueFound" | "lakeClueFound";
    if (state.qizhenLake[flagName]) return true;
    const itemId = MAP_CLUE_ITEMS[clueId];
    const allCluesCollected = (
      (clueId === "bridge" || state.qizhenLake.bridgeClueFound)
      && (clueId === "reflection" || state.qizhenLake.reflectionClueFound)
      && (clueId === "lake" || state.qizhenLake.lakeClueFound)
    );
    const sourceTargetId = clueId === "bridge"
      ? "cc98_search"
      : clueId === "reflection" ? "library_catalog_search" : "wechat_location_chat";
    this.store.setState((current) => ({
      ...current,
      items: {
        ...current.items,
        wetProgram: allCluesCollected ? false : current.items.wetProgram,
        [itemId]: true
      },
      ui: allCluesCollected && current.ui.selectedItem === "wetProgram"
        ? { ...current.ui, selectedItem: null }
        : current.ui,
      qizhenLake: { ...current.qizhenLake, [flagName]: true }
    }));
    this.events.emit("use_item", {
      itemId: "wetProgram",
      targetId: sourceTargetId,
      result: allCluesCollected ? "consume" : "retain"
    });
    this.events.emit("get_item", {
      itemId,
      sourceScene: clueId === "bridge" ? "cc98" : clueId === "reflection" ? "zjuding" : "wechat"
    });
    this.events.emit(eventName, { clueId });
    return true;
  }
}

function spotFromTarget(targetId: string): QizhenFishingSpotId | null {
  if (targetId.includes("item_1") || targetId.includes("locker")) return "locker_key";
  if (targetId.includes("item_3") || targetId.includes("net")) return "net_frame";
  if (targetId.includes("fish")) return "fish";
  if (targetId.includes("paper") || targetId.includes("reflection")) return "paper";
  return null;
}

function photoForSpot(journal: QizhenJournalState, spotId: QizhenPhotoSpotId): QizhenPhotoRecord | null {
  return spotId === "lake_center" ? journal.mainPhoto : journal.optionalPhotos[spotId] ?? null;
}

/** lake_center 在主帖发布前一律是 "main";发布后(含归档)不再产生主帖草稿。 */
function journalCaptureKind(journal: QizhenJournalState, spotId: QizhenPhotoSpotId): "main" | "spot" {
  if (spotId !== "lake_center") return "spot";
  const mainPublished = journal.publishedSpotIds.includes("lake_center")
    || journal.status === "open"
    || journal.status === "summary_ready"
    || journal.status === "archived";
  return mainPublished ? "spot" : "main";
}

/**
 * 捕获时刻:优先用场景会话的单调秒数;缺失或非法时退化为存档内最大
 * capturedAtSeconds + 1,保证幂等 id 单调且确定。
 */
function capturedAtSecondsFor(input: number | undefined, journal: QizhenJournalState): number {
  if (typeof input === "number" && Number.isInteger(input) && input >= 0) return input;
  let max = 0;
  if (journal.mainPhoto) max = Math.max(max, journal.mainPhoto.capturedAtSeconds);
  for (const photo of Object.values(journal.optionalPhotos)) {
    if (photo) max = Math.max(max, photo.capturedAtSeconds);
  }
  return max + 1;
}

function journalDraftsEqual(a: QizhenJournalDraft, b: QizhenJournalDraft): boolean {
  return a.id === b.id
    && a.kind === b.kind
    && a.photo.id === b.photo.id
    && a.titleId === b.titleId
    && a.statusId === b.statusId
    && a.captionId === b.captionId;
}

/** 一次性随机源:返回 [1, 2^31-1] 的 32 位整数,作为主帖 threadSeed/threadId 的种子。 */
function newThreadSeed(): number {
  return 1 + Math.floor(Math.random() * 0x7fffffff);
}

function checkpointForCurrentLakeState(state: ReturnType<GameStore["getState"]>): RpgCheckpointId {
  if (state.qizhenLake.phase === "complete") return "qizhen_complete";
  if (state.qizhenLake.phase === "swan_chase") return "qizhen_chase";
  return ZONE_CHECKPOINTS[state.qizhenLake.zone];
}

export function qizhenSpotItem(spotId: QizhenFishingSpotId): ItemId | null {
  return SPOT_ITEM[spotId] ?? null;
}
