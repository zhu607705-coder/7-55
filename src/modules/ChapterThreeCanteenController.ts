import type { EventBus } from "../core/EventBus";
import type { CanteenExitId, CanteenMode, GameStore } from "../core/types";

export const CANTEEN_TARGET_TRAYS = ["tray_blue_01", "tray_blue_02", "tray_blue_03"] as const;
export const CANTEEN_TRAY_IDS = [
  ...CANTEEN_TARGET_TRAYS,
  "tray_plain_01", "tray_plain_02", "tray_plain_03",
  "tray_plain_04", "tray_plain_05", "tray_plain_06",
  "tray_plain_07", "tray_plain_08", "tray_plain_09"
] as const;
export const CANTEEN_EXIT_SEQUENCE: readonly CanteenExitId[] = ["southeast", "steam", "west"];
const CANTEEN_TRAY_REWARD_CENTS = 200;
const CANTEEN_BIKE_FARE_CENTS = 200;
const CANTEEN_CHASE_GOAL = 755;
const CANTEEN_CHASE_MAX_LIVES = 3;

export interface CanteenChaseAttempt {
  mode: "story" | "endless";
  distance: number;
  lives: number;
  collisions: number;
}

export type CanteenChaseAttemptResult = "won" | "lost" | "invalid";

export type CanteenTrayResult =
  | "task_started"
  | "collected"
  | "delivered_target"
  | "delivered_ordinary"
  | "wrong_mode"
  | "already_done"
  | "hands_full"
  | "empty_handed"
  | "inactive";
export type CanteenChoiceResult = "correct" | "wrong" | "locked" | "inactive";
export type CanteenBlockResult = "correct" | "wrong" | "complete" | "inactive";
export type CanteenBikeResult = "code_read" | "glare" | "cleaned" | "payment_ready" | "dark_rejected" | "rule" | "paid" | "inactive";

export interface ChapterThreeCanteenEventBindingOptions {
  beforeEnter?: () => void;
  onEnterResult?: (entered: boolean) => void;
  onLeaveResult?: (left: boolean) => void;
}

export class ChapterThreeCanteenController {
  constructor(private readonly store: GameStore, private readonly events: EventBus) {}

  enterCanteen(): boolean {
    const state = this.store.getState();
    // The canteen is a normal campus destination outside the authored hunt. When the
    // hunt is active, keep its entry gate so an unrelated visit cannot skip a phase.
    if (state.canteenHunt.active && !["tracking", "canteen_reached", "entered"].includes(state.canteenHunt.phase)) {
      return false;
    }
    this.store.setState((current) => ({
      ...current,
      runtimeMode: "rpg",
      rpgScene: "canteen_interior",
      rpgCheckpoint: "canteen_entrance",
      canteenHunt: current.canteenHunt.active
        ? {
            ...current.canteenHunt,
            phase: "tray_search",
            mode: "light"
          }
        : current.canteenHunt
    }));
    this.events.emit("canteen_entered");
    return true;
  }

  setMode(mode: CanteenMode): boolean {
    const state = this.store.getState();
    if (!state.canteenHunt.active || !["tray_search", "menu_order", "pickup_search", "exit_blocking", "chase_ready"].includes(state.canteenHunt.phase)) {
      return false;
    }
    if (state.canteenHunt.mode === mode) return true;
    this.store.setState((current) => ({
      ...current,
      canteenHunt: {
        ...current.canteenHunt,
        mode,
        identifiedTrayIds: mode === "dark"
          && current.canteenHunt.phase === "tray_search"
          && current.canteenHunt.trayTaskStarted
            ? [...CANTEEN_TARGET_TRAYS]
            : current.canteenHunt.identifiedTrayIds
      }
    }));
    this.events.emit("canteen_mode_changed", { mode });
    return true;
  }

  startTrayTask(): CanteenTrayResult {
    const state = this.store.getState();
    if (!state.canteenHunt.active || state.canteenHunt.phase !== "tray_search") return "inactive";
    if (state.canteenHunt.trayTaskStarted) return "task_started";
    this.store.setState((current) => ({
      ...current,
      canteenHunt: { ...current.canteenHunt, trayTaskStarted: true }
    }));
    this.events.emit("canteen_tray_task_started");
    return "task_started";
  }

  collectTray(trayId: string): CanteenTrayResult {
    const state = this.store.getState();
    if (!state.canteenHunt.active || state.canteenHunt.phase !== "tray_search") return "inactive";
    if (!state.canteenHunt.trayTaskStarted || !(CANTEEN_TRAY_IDS as readonly string[]).includes(trayId)) {
      return "inactive";
    }
    if (state.canteenHunt.mode !== "light") {
      this.events.emit("canteen_tray_collect_wrong_mode", { trayId });
      return "wrong_mode";
    }
    if (
      state.canteenHunt.carriedTrayIds.includes(trayId)
      || state.canteenHunt.returnedTrayIds.includes(trayId)
    ) return "already_done";
    if (state.canteenHunt.carriedTrayIds.length > 0) {
      this.events.emit("canteen_tray_hands_full", { trayId });
      return "hands_full";
    }
    this.store.setState((current) => ({
      ...current,
      canteenHunt: {
        ...current.canteenHunt,
        carriedTrayIds: [trayId]
      }
    }));
    this.events.emit("canteen_tray_collected", {
      trayId,
      target: (CANTEEN_TARGET_TRAYS as readonly string[]).includes(trayId)
    });
    return "collected";
  }

  deliverCarriedTray(): CanteenTrayResult {
    const state = this.store.getState();
    if (!state.canteenHunt.active || state.canteenHunt.phase !== "tray_search") return "inactive";
    const trayId = state.canteenHunt.carriedTrayIds[0];
    if (!trayId) {
      this.events.emit("canteen_tray_empty_handed");
      return "empty_handed";
    }
    const target = (CANTEEN_TARGET_TRAYS as readonly string[]).includes(trayId);
    const returnedTrayIds = [...state.canteenHunt.returnedTrayIds, trayId];
    const correctCount = returnedTrayIds.filter((id) => (
      (CANTEEN_TARGET_TRAYS as readonly string[]).includes(id)
    )).length;
    const completed = correctCount === CANTEEN_TARGET_TRAYS.length;
    const rewardGranted = completed && !state.items.cafeteriaWages;
    this.store.setState((current) => ({
      ...current,
      items: rewardGranted
        ? { ...current.items, cafeteriaWages: true, greaseTissue: true }
        : current.items,
      wallet: rewardGranted
        ? { ...current.wallet, cashCents: current.wallet.cashCents + CANTEEN_TRAY_REWARD_CENTS }
        : current.wallet,
      canteenHunt: {
        ...current.canteenHunt,
        carriedTrayIds: [],
        returnedTrayIds,
        phase: completed ? "menu_order" : current.canteenHunt.phase
      }
    }));
    this.events.emit("canteen_tray_delivered", {
      trayId,
      target,
      correctCount,
      completed
    });
    if (completed) {
      this.events.emit("get_item", { itemId: "cafeteriaWages", sourceScene: "canteen_interior" });
      this.events.emit("get_item", { itemId: "greaseTissue", sourceScene: "canteen_interior" });
      this.events.emit("canteen_trays_completed");
    }
    return target ? "delivered_target" : "delivered_ordinary";
  }

  inspectMenuClue(): boolean {
    const state = this.store.getState();
    if (
      !state.canteenHunt.active
      || state.canteenHunt.phase !== "menu_order"
      || state.canteenHunt.mode !== "dark"
    ) return false;
    if (!state.canteenHunt.menuDarkClueRead) {
      this.store.setState((current) => ({
        ...current,
        canteenHunt: { ...current.canteenHunt, menuDarkClueRead: true }
      }));
    }
    this.events.emit("canteen_menu_dark_clue_read");
    return true;
  }

  selectMenuOption(optionId: string): CanteenChoiceResult {
    const state = this.store.getState();
    if (!state.canteenHunt.active || state.canteenHunt.phase !== "menu_order") return "inactive";
    if (state.canteenHunt.mode !== "light" || !state.canteenHunt.menuDarkClueRead) {
      this.events.emit("canteen_menu_order_locked", {
        mode: state.canteenHunt.mode,
        clueRead: state.canteenHunt.menuDarkClueRead
      });
      return "locked";
    }
    const correct = optionId === "D";
    this.store.setState((current) => ({
      ...current,
      items: correct ? { ...current.items, pickupTicket0755: true } : current.items,
      canteenHunt: {
        ...current.canteenHunt,
        orderAttemptCount: current.canteenHunt.orderAttemptCount + 1,
        phase: correct ? "pickup_search" : current.canteenHunt.phase
      }
    }));
    this.events.emit(correct ? "canteen_order_solved" : "canteen_order_wrong", { optionId });
    if (correct) this.events.emit("get_item", { itemId: "pickupTicket0755", sourceScene: "canteen_interior" });
    return correct ? "correct" : "wrong";
  }

  inspectPickupWindow(windowId: string): boolean {
    const state = this.store.getState();
    if (
      !state.canteenHunt.active
      || state.canteenHunt.phase !== "pickup_search"
      || state.canteenHunt.mode !== "dark"
    ) return false;
    const clueFound = windowId === "3";
    if (clueFound && !state.canteenHunt.pickupDarkClueRead) {
      this.store.setState((current) => ({
        ...current,
        canteenHunt: { ...current.canteenHunt, pickupDarkClueRead: true }
      }));
    }
    this.events.emit(clueFound ? "canteen_pickup_dark_clue_read" : "canteen_pickup_dark_clue_missed", { windowId });
    return clueFound;
  }

  selectPickupWindow(windowId: string): CanteenChoiceResult {
    const state = this.store.getState();
    if (!state.canteenHunt.active || state.canteenHunt.phase !== "pickup_search") return "inactive";
    if (state.canteenHunt.mode !== "light" || !state.canteenHunt.pickupDarkClueRead) {
      this.events.emit("canteen_pickup_order_locked", {
        mode: state.canteenHunt.mode,
        clueRead: state.canteenHunt.pickupDarkClueRead,
        windowId
      });
      return "locked";
    }
    if (!state.items.pickupTicket0755) {
      this.events.emit("canteen_pickup_missing_ticket", { windowId });
      return "wrong";
    }
    const correct = windowId === "3";
    this.store.setState((current) => ({
      ...current,
      items: correct ? { ...current.items, pickupTicket0755: false } : current.items,
      canteenHunt: {
        ...current.canteenHunt,
        pickupAttemptCount: current.canteenHunt.pickupAttemptCount + 1,
        phase: correct ? "exit_blocking" : current.canteenHunt.phase
      }
    }));
    this.events.emit(correct ? "canteen_pickup_solved" : "canteen_pickup_wrong", { windowId });
    if (correct) this.events.emit("use_item", { itemId: "pickupTicket0755", targetId: "canteen_pickup_3" });
    return correct ? "correct" : "wrong";
  }

  inspectExitCart(exitId: CanteenExitId): boolean {
    const state = this.store.getState();
    if (
      !state.canteenHunt.active
      || state.canteenHunt.phase !== "exit_blocking"
      || state.canteenHunt.mode !== "dark"
    ) return false;
    const expected = CANTEEN_EXIT_SEQUENCE[state.canteenHunt.blockHits];
    const matched = exitId === expected;
    if (matched && !state.canteenHunt.identifiedExitIds.includes(exitId)) {
      this.store.setState((current) => ({
        ...current,
        canteenHunt: {
          ...current.canteenHunt,
          identifiedExitIds: [...current.canteenHunt.identifiedExitIds, exitId]
        }
      }));
    }
    this.events.emit(matched ? "canteen_exit_dark_clue_read" : "canteen_exit_dark_clue_missed", {
      exitId,
      expected,
      step: state.canteenHunt.blockHits + 1
    });
    return matched;
  }

  blockExit(exitId: CanteenExitId): CanteenBlockResult {
    const state = this.store.getState();
    if (!state.canteenHunt.active || state.canteenHunt.phase !== "exit_blocking") {
      this.events.emit("canteen_exit_block_rejected", { exitId });
      return "inactive";
    }
    const expected = CANTEEN_EXIT_SEQUENCE[state.canteenHunt.blockHits];
    if (state.canteenHunt.mode !== "light" || !state.canteenHunt.identifiedExitIds.includes(expected)) {
      this.events.emit("canteen_exit_block_unidentified", {
        exitId,
        expected,
        mode: state.canteenHunt.mode
      });
      return "inactive";
    }
    if (exitId !== expected) {
      this.events.emit("canteen_exit_block_wrong", { exitId, expected });
      return "wrong";
    }
    const blockHits = state.canteenHunt.blockHits + 1;
    const complete = blockHits >= CANTEEN_EXIT_SEQUENCE.length;
    this.store.setState((current) => ({
      ...current,
      canteenHunt: {
        ...current.canteenHunt,
        blockHits,
        phase: complete ? "chase_ready" : current.canteenHunt.phase
      }
    }));
    this.events.emit(complete ? "canteen_exit_blocking_completed" : "canteen_exit_blocked", { exitId, blockHits });
    return complete ? "complete" : "correct";
  }

  completeDefense(): boolean {
    const state = this.store.getState();
    if (!state.canteenHunt.active || state.canteenHunt.phase !== "exit_blocking") {
      return false;
    }
    this.store.setState((current) => ({
      ...current,
      canteenHunt: {
        ...current.canteenHunt,
        mode: "light",
        phase: "chase_ready",
        // Keep the legacy fields complete so old saves and later chapter checks
        // continue to understand that the exit-defense beat has been cleared.
        blockHits: CANTEEN_EXIT_SEQUENCE.length,
        identifiedExitIds: [...CANTEEN_EXIT_SEQUENCE]
      }
    }));
    this.events.emit("canteen_defense_completed");
    return true;
  }

  leaveCanteen(): boolean {
    const state = this.store.getState();
    // The lower-right door is always a valid return route during ordinary
    // exploration. The chapter hunt still requires its cart-blocking phase.
    if (state.canteenHunt.active && state.canteenHunt.phase !== "chase_ready") return false;
    this.store.setState((current) => ({
      ...current,
      rpgScene: "campus_bootstrap",
      rpgCheckpoint: "campus_canteen_gate"
    }));
    this.events.emit("canteen_returned_to_campus");
    return true;
  }

  inspectBikeLock(): CanteenBikeResult {
    const state = this.store.getState();
    if (state.canteenHunt.phase !== "chase_ready") return "inactive";
    if (state.canteenHunt.mode === "dark") {
      if (!state.canteenHunt.bikeCodeRead) {
        this.store.setState((current) => ({
          ...current,
          canteenHunt: { ...current.canteenHunt, bikeCodeRead: true }
        }));
        this.events.emit("canteen_bike_code_read");
        return "code_read";
      }
      this.events.emit("canteen_bike_dark_payment_rejected");
      return "dark_rejected";
    }
    if (!state.canteenHunt.bikeLockCleaned) {
      this.events.emit("canteen_bike_glare_failed");
      return "glare";
    }
    this.events.emit("canteen_bike_payment_ready");
    return "payment_ready";
  }

  cleanBikeLock(): CanteenBikeResult {
    const state = this.store.getState();
    if (state.canteenHunt.phase !== "chase_ready" || !state.items.greaseTissue) return "inactive";
    if (state.canteenHunt.mode !== "light" || !state.canteenHunt.bikeCodeRead) {
      this.events.emit("canteen_bike_scan_rule");
      return "rule";
    }
    if (!state.canteenHunt.bikeLockCleaned) {
      this.store.setState((current) => ({
        ...current,
        canteenHunt: { ...current.canteenHunt, bikeLockCleaned: true }
      }));
      this.events.emit("use_item", { itemId: "greaseTissue", targetId: "canteen-bike-lock", result: "retain" });
    }
    this.events.emit("canteen_bike_lock_cleaned");
    return "cleaned";
  }

  payForBike(): CanteenBikeResult {
    const state = this.store.getState();
    if (
      state.canteenHunt.phase !== "chase_ready"
      || !state.items.cafeteriaWages
      || state.wallet.cashCents < CANTEEN_BIKE_FARE_CENTS
    ) return "inactive";
    if (state.canteenHunt.mode !== "light" || !state.canteenHunt.bikeCodeRead || !state.canteenHunt.bikeLockCleaned) {
      this.events.emit("canteen_bike_scan_rule");
      return "rule";
    }
    this.store.setState((current) => ({
      ...current,
      items: { ...current.items, cafeteriaWages: false },
      wallet: {
        ...current.wallet,
        cashCents: current.wallet.cashCents - CANTEEN_BIKE_FARE_CENTS
      },
      canteenHunt: {
        ...current.canteenHunt,
        phase: "chasing",
        bikePaid: true
      }
    }));
    this.events.emit("use_item", { itemId: "cafeteriaWages", targetId: "canteen_bike" });
    this.events.emit("canteen_chase_started");
    return "paid";
  }

  resolveChaseAttempt(attempt: CanteenChaseAttempt): CanteenChaseAttemptResult {
    const state = this.store.getState();
    if (state.canteenHunt.phase !== "chasing") return "invalid";
    const distance = Math.max(0, Math.floor(attempt.distance));
    const lives = Math.max(0, Math.min(CANTEEN_CHASE_MAX_LIVES, Math.floor(attempt.lives)));
    const collisions = Math.max(0, Math.floor(attempt.collisions));
    const won = attempt.mode === "story" && distance === CANTEEN_CHASE_GOAL && lives > 0;
    const lost = lives === 0;
    if (!won && !lost) return "invalid";

    this.store.setState((current) => ({
      ...current,
      canteenHunt: {
        ...current.canteenHunt,
        chaseCompleted: current.canteenHunt.chaseCompleted || won,
        chaseAttemptCount: current.canteenHunt.chaseAttemptCount + 1,
        chaseBestDistance: Math.max(current.canteenHunt.chaseBestDistance, distance),
        chaseBestLives: distance >= current.canteenHunt.chaseBestDistance
          ? Math.max(current.canteenHunt.chaseBestLives, lives)
          : current.canteenHunt.chaseBestLives,
        chaseCollisions: won ? collisions : current.canteenHunt.chaseCollisions
      }
    }));
    this.events.emit(won ? "canteen_chase_story_cleared" : "canteen_chase_attempt_failed", {
      mode: attempt.mode,
      distance,
      lives,
      collisions
    });
    return won ? "won" : "lost";
  }

  completeChase(): boolean {
    const state = this.store.getState();
    if (
      state.canteenHunt.phase !== "chasing"
      || !state.canteenHunt.chaseCompleted
      || state.canteenHunt.chaseBestDistance < CANTEEN_CHASE_GOAL
    ) return false;
    this.store.setState((current) => ({
      ...current,
      rpgScene: "campus_bootstrap",
      rpgCheckpoint: "campus_theater_junction",
      canteenHunt: {
        ...current.canteenHunt,
        phase: "theater_reached"
      }
    }));
    this.events.emit("canteen_chase_completed", {
      collisions: state.canteenHunt.chaseCollisions,
      distance: CANTEEN_CHASE_GOAL,
      lives: state.canteenHunt.chaseBestLives
    });
    return true;
  }
}

export function bindChapterThreeCanteenEvents(
  controller: ChapterThreeCanteenController,
  events: EventBus,
  options: ChapterThreeCanteenEventBindingOptions = {}
): () => void {
  return events.subscribe((event) => {
    if (event.name === "rpg_canteen_entry_requested") {
      options.beforeEnter?.();
      const entered = controller.enterCanteen();
      options.onEnterResult?.(entered);
    } else if (event.name === "rpg_canteen_mode_requested") {
      controller.setMode(String(event.payload?.mode ?? "light") as CanteenMode);
    } else if (event.name === "rpg_canteen_tray_task_start_requested") {
      controller.startTrayTask();
    } else if (event.name === "rpg_canteen_tray_requested") {
      controller.collectTray(String(event.payload?.trayId ?? ""));
    } else if (event.name === "rpg_canteen_tray_delivery_requested") {
      controller.deliverCarriedTray();
    } else if (event.name === "rpg_canteen_menu_clue_requested") {
      controller.inspectMenuClue();
    } else if (event.name === "rpg_canteen_menu_selected") {
      controller.selectMenuOption(String(event.payload?.optionId ?? ""));
    } else if (event.name === "rpg_canteen_pickup_clue_requested") {
      controller.inspectPickupWindow(String(event.payload?.windowId ?? ""));
    } else if (event.name === "rpg_canteen_pickup_selected") {
      controller.selectPickupWindow(String(event.payload?.windowId ?? ""));
    } else if (event.name === "rpg_canteen_cart_clue_requested") {
      controller.inspectExitCart(String(event.payload?.exitId ?? "west") as CanteenExitId);
    } else if (event.name === "rpg_canteen_exit_block_requested") {
      controller.blockExit(String(event.payload?.exitId ?? "west") as CanteenExitId);
    } else if (event.name === "rpg_canteen_defense_completed") {
      controller.completeDefense();
    } else if (event.name === "rpg_canteen_leave_requested") {
      const left = controller.leaveCanteen();
      options.onLeaveResult?.(left);
    }
  });
}
