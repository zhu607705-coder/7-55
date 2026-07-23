import type { EventBus } from "../core/EventBus";
import type { CanteenExitId, CanteenMode, GameStore } from "../core/types";

export const CANTEEN_TARGET_TRAYS = ["tray_blue_01", "tray_blue_02", "tray_blue_03"] as const;
export const CANTEEN_EXIT_SEQUENCE: readonly CanteenExitId[] = ["southeast", "steam", "west"];

export type CanteenTrayResult = "identified" | "returned" | "ordinary" | "wrong_mode" | "already_done" | "inactive";
export type CanteenChoiceResult = "correct" | "wrong" | "inactive";
export type CanteenBlockResult = "correct" | "wrong" | "complete" | "inactive";
export type CanteenBikeResult = "code_read" | "glare" | "cleaned" | "payment_ready" | "dark_rejected" | "rule" | "paid" | "inactive";

export class ChapterThreeCanteenController {
  constructor(private readonly store: GameStore, private readonly events: EventBus) {}

  enterCanteen(): boolean {
    const state = this.store.getState();
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
      canteenHunt: { ...current.canteenHunt, mode }
    }));
    this.events.emit("canteen_mode_changed", { mode });
    return true;
  }

  useTray(trayId: string, isQueueCollision = false): CanteenTrayResult {
    const state = this.store.getState();
    if (!state.canteenHunt.active || state.canteenHunt.phase !== "tray_search") return "inactive";
    const isTarget = (CANTEEN_TARGET_TRAYS as readonly string[]).includes(trayId);
    if (!isTarget) {
      this.events.emit(isQueueCollision ? "canteen_tray_hit_student" : "canteen_tray_rejected", { trayId });
      return "ordinary";
    }
    if (state.canteenHunt.returnedTrayIds.includes(trayId)) return "already_done";
    if (state.canteenHunt.mode === "dark") {
      if (!state.canteenHunt.identifiedTrayIds.includes(trayId)) {
        this.store.setState((current) => ({
          ...current,
          canteenHunt: {
            ...current.canteenHunt,
            identifiedTrayIds: [...current.canteenHunt.identifiedTrayIds, trayId]
          }
        }));
      }
      this.events.emit("canteen_tray_identified", { trayId });
      return "identified";
    }
    if (!state.canteenHunt.identifiedTrayIds.includes(trayId)) {
      this.events.emit("canteen_tray_unidentified", { trayId });
      return "wrong_mode";
    }
    const returnedTrayIds = [...state.canteenHunt.returnedTrayIds, trayId];
    const completed = returnedTrayIds.length === CANTEEN_TARGET_TRAYS.length;
    this.store.setState((current) => ({
      ...current,
      items: completed
        ? { ...current.items, cafeteriaWages: true, greaseTissue: true }
        : current.items,
      canteenHunt: {
        ...current.canteenHunt,
        returnedTrayIds,
        phase: completed ? "menu_order" : current.canteenHunt.phase
      }
    }));
    this.events.emit("canteen_tray_returned", { trayId, count: returnedTrayIds.length });
    if (completed) {
      this.events.emit("get_item", { itemId: "cafeteriaWages", sourceScene: "canteen_interior" });
      this.events.emit("get_item", { itemId: "greaseTissue", sourceScene: "canteen_interior" });
      this.events.emit("canteen_trays_completed");
    }
    return "returned";
  }

  selectMenuOption(optionId: string): CanteenChoiceResult {
    const state = this.store.getState();
    if (!state.canteenHunt.active || state.canteenHunt.phase !== "menu_order") return "inactive";
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

  selectPickupWindow(windowId: string): CanteenChoiceResult {
    const state = this.store.getState();
    if (!state.canteenHunt.active || state.canteenHunt.phase !== "pickup_search") return "inactive";
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

  blockExit(exitId: CanteenExitId): CanteenBlockResult {
    const state = this.store.getState();
    if (!state.canteenHunt.active || state.canteenHunt.phase !== "exit_blocking") return "inactive";
    const expected = CANTEEN_EXIT_SEQUENCE[state.canteenHunt.blockHits];
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

  leaveCanteen(): boolean {
    const state = this.store.getState();
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
    if (state.canteenHunt.phase !== "chase_ready" || !state.items.cafeteriaWages) return "inactive";
    if (state.canteenHunt.mode !== "light" || !state.canteenHunt.bikeCodeRead || !state.canteenHunt.bikeLockCleaned) {
      this.events.emit("canteen_bike_scan_rule");
      return "rule";
    }
    this.store.setState((current) => ({
      ...current,
      items: { ...current.items, cafeteriaWages: false },
      canteenHunt: { ...current.canteenHunt, phase: "chasing", bikePaid: true }
    }));
    this.events.emit("use_item", { itemId: "cafeteriaWages", targetId: "canteen_bike" });
    this.events.emit("canteen_chase_started");
    return "paid";
  }

  completeChase(collisions: number): boolean {
    const state = this.store.getState();
    if (state.canteenHunt.phase !== "chasing") return false;
    this.store.setState((current) => ({
      ...current,
      rpgScene: "campus_bootstrap",
      rpgCheckpoint: "campus_canteen_gate",
      canteenHunt: {
        ...current.canteenHunt,
        active: false,
        phase: "tracking",
        chaseCollisions: Math.max(0, Math.floor(collisions))
      }
    }));
    this.events.emit("canteen_chase_completed", { collisions: Math.max(0, Math.floor(collisions)) });
    return true;
  }
}
