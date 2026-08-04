import type { EventBus } from "../core/EventBus";
import type {
  GameStore,
  ItemId,
  QizhenFishingSpotId,
  QizhenLakeMode,
  QizhenLakeZone,
  QizhenMapClueId,
  QizhenPaddleSide,
  RpgCheckpointId
} from "../core/types";

export type QizhenMapClueResult = "added" | "already_added" | "location_solved" | "wrong_item" | "inactive";
export type QizhenActionResult =
  | "accepted"
  | "inactive"
  | "locked"
  | "wrong_mode"
  | "wrong_item"
  | "unobserved"
  | "direct_paper_failure"
  | "already_complete";

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
    const solved = mapClueIds.length === 3;
    this.store.setState((current) => ({
      ...current,
      items: { ...current.items, [itemId]: false },
      ui: current.ui.selectedItem === itemId ? { ...current.ui, selectedItem: null } : current.ui,
      qizhenLake: {
        ...current.qizhenLake,
        mapClueIds,
        phase: solved ? "lake_unlocked" : current.qizhenLake.phase
      }
    }));
    this.events.emit("use_item", { itemId, targetId: "qizhen_map_search", result: "consume" });
    this.events.emit(solved ? "qizhen_location_solved" : "qizhen_map_clue_added", {
      clueId,
      count: mapClueIds.length
    });
    return solved ? "location_solved" : "added";
  }

  getMapClueCount(): number {
    return this.store.getState().qizhenLake.mapClueIds.length;
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

  collectOutfit(): QizhenActionResult {
    const state = this.store.getState();
    if (state.qizhenLake.phase !== "dock_outfitting" || state.qizhenLake.zone !== "dock") return "inactive";
    if (state.qizhenLake.mode !== "light") return "wrong_mode";
    this.store.setState((current) => ({
      ...current,
      rpgCheckpoint: "qizhen_dock",
      qizhenLake: {
        ...current.qizhenLake,
        phase: "boarding_tutorial",
        kayakEquipped: true,
        leftPaddleEquipped: true,
        rightPaddleEquipped: true,
        safeSpawnId: "dock_kayak"
      }
    }));
    this.events.emit("qizhen_outfit_collected", {
      leftPaddle: "willow_branch",
      rightPaddle: "no_swimming_sign"
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

  recordPaddleStroke(side: QizhenPaddleSide): QizhenActionResult {
    const state = this.store.getState();
    if (state.qizhenLake.vehicle !== "kayak") return "inactive";
    if (state.qizhenLake.phase !== "boarding_tutorial") {
      this.events.emit("qizhen_paddle_stroke_recorded", { side, tutorial: false });
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
      alternating,
      count: boardingStrokeCount
    });
    return "accepted";
  }

  recordCapsize(reason: string): QizhenActionResult {
    const state = this.store.getState();
    if (state.qizhenLake.vehicle !== "kayak") return "inactive";
    const inTutorial = state.qizhenLake.phase === "boarding_tutorial";
    this.store.setState((current) => ({
      ...current,
      rpgCheckpoint: inTutorial ? "qizhen_dock" : checkpointForCurrentLakeState(current),
      qizhenLake: {
        ...current.qizhenLake,
        capsizeCount: current.qizhenLake.capsizeCount + 1,
        chaseAttempts: current.qizhenLake.phase === "swan_chase"
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
      count: state.qizhenLake.capsizeCount + 1
    });
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

  castAt(spotId: QizhenFishingSpotId): QizhenActionResult {
    const state = this.store.getState();
    if (state.qizhenLake.vehicle !== "kayak" || !["tool_chain", "swan_exchange", "paper_capture"].includes(state.qizhenLake.phase)) {
      return "inactive";
    }
    if (state.qizhenLake.mode !== "light") return "wrong_mode";
    if (!state.qizhenLake.observedFishingSpotIds.includes(spotId)) return "unobserved";
    if (spotId === "paper" && !state.items.magneticFishingRod) {
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
      return "direct_paper_failure";
    }
    if (spotId === "locker_key") {
      if (!state.items.fishingRod || !state.qizhenLake.decoyBaitAttached) return "wrong_item";
      if (state.items.rustedLockerKey || state.qizhenLake.lockerOpened) return "already_complete";
      return this.grantCaughtItem(spotId, "rustedLockerKey");
    }
    if (spotId === "net_frame") {
      if (!state.items.fishingRod || !state.qizhenLake.lockerOpened) return "locked";
      if (state.items.brokenNetFrame || state.qizhenLake.netCombined) return "already_complete";
      return this.grantCaughtItem(spotId, "brokenNetFrame");
    }
    if (spotId === "fish") {
      if (!state.items.fishingRod || !state.items.fishFeedPellets) return "wrong_item";
      if (state.qizhenLake.fishCaught || state.items.smallCarp) return "already_complete";
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
    if (!state.items.magneticFishingRod || !state.qizhenLake.swanFed) return "wrong_item";
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

  completeEscape(): QizhenActionResult {
    const state = this.store.getState();
    if (state.qizhenLake.phase !== "swan_chase") return "inactive";
    this.store.setState((current) => ({
      ...current,
      items: { ...current.items, magneticFishingRod: false },
      ui: current.ui.selectedItem === "magneticFishingRod" ? { ...current.ui, selectedItem: null } : current.ui,
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
      }
    }));
    this.events.emit("use_item", { itemId: "magneticFishingRod", targetId: "qizhen_paper", result: "consume" });
    this.events.emit("qizhen_escape_completed");
    this.events.emit("qizhen_chapter_transition_requested", {
      reason: "paper_escaped_after_swan_chase"
    });
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

function checkpointForCurrentLakeState(state: ReturnType<GameStore["getState"]>): RpgCheckpointId {
  if (state.qizhenLake.phase === "complete") return "qizhen_complete";
  if (state.qizhenLake.phase === "swan_chase") return "qizhen_chase";
  return ZONE_CHECKPOINTS[state.qizhenLake.zone];
}

export function qizhenSpotItem(spotId: QizhenFishingSpotId): ItemId | null {
  return SPOT_ITEM[spotId] ?? null;
}
