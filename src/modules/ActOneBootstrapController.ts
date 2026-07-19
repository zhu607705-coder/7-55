import type { EventBus } from "../core/EventBus";
import type { ActOneBootstrapState, GameStore, RpgSceneId } from "../core/types";
import content from "../data/act-one-bootstrap.content.json";

export type GamepadPurchaseResult = "purchased" | "already_owned" | "insufficient_balance" | "inactive";
export type GamepadUseResult = "active" | "identity_required" | "exercise_required" | "not_owned" | "inactive";

export interface NarratorInterventionResult {
  interceptedCount: number;
  lockHeldMs: number;
  failed: boolean;
}

const REQUIRED_NARRATOR_INTERCEPTS = 3;
const REQUIRED_NARRATOR_LOCK_MS = 1400;

/**
 * Owns the prologue exit and chapter-two movement puzzle facts.
 * Scenes may animate these facts, while only this controller validates progress.
 */
export class ActOneBootstrapController {
  constructor(
    private readonly store: GameStore,
    private readonly events: EventBus
  ) {}

  enterRpg(scene: RpgSceneId = "campus_bootstrap"): boolean {
    const state = this.store.getState();
    if (scene === "dorm_hub" && !state.actOne.dormHubUnlocked) {
      return false;
    }
    if (state.actOne.gamepadPurchased || state.items.gamepad) {
      this.syncGamepadOwnership();
    }
    this.store.setState((current) => ({
      ...current,
      runtimeMode: "rpg",
      rpgScene: scene,
      actOne: scene === "dorm_hub"
        ? { ...current.actOne, dormHubUnlocked: true }
        : current.actOne
    }));
    this.events.emit("act2_rpg_entered", { scene });
    return true;
  }

  beginAfterCheckin(result: NarratorInterventionResult): boolean {
    return this.completeNarratorIntervention(result);
  }

  completeNarratorIntervention(result: NarratorInterventionResult): boolean {
    const state = this.store.getState();
    if (!state.flags.checkinDone) {
      this.events.emit("act2_entry_rejected", { reason: "checkin_incomplete" });
      return false;
    }
    if (state.actOne.phase !== "prologue") {
      return true;
    }
    const captureValidated = !result.failed
      && result.interceptedCount >= REQUIRED_NARRATOR_INTERCEPTS
      && result.lockHeldMs >= REQUIRED_NARRATOR_LOCK_MS;
    if (!captureValidated) {
      this.events.emit("prologue_narrator_capture_rejected", {
        reason: "capture_incomplete",
        interceptedCount: result.interceptedCount,
        requiredIntercepts: REQUIRED_NARRATOR_INTERCEPTS,
        lockHeldMs: result.lockHeldMs,
        requiredLockMs: REQUIRED_NARRATOR_LOCK_MS,
        failed: result.failed
      });
      return false;
    }
    this.store.setState((current) => ({
      ...current,
      runtimeMode: "phone",
      currentScene: "phone_home",
      actOne: {
        ...current.actOne,
        phase: "friend_message_required",
        inventoryRecovered: false,
        dormHubUnlocked: false
      },
      ui: {
        ...current.ui,
        controlCenterOpen: false,
        inventoryOpen: false,
        selectedItem: null,
        zjudingPage: "hub"
      }
    }));
    this.events.emit("prologue_narrator_released");
    this.events.emit("act2_entry_unlocked", { entry: "phone_home" });
    return true;
  }

  completeFriendExchange(): boolean {
    const actOne = this.getState();
    if (actOne.phase !== "friend_message_required") {
      return actOne.phase !== "prologue";
    }
    this.patch({ phase: "system_required" });
    this.events.emit("act2_friend_exchange_completed");
    return true;
  }

  confrontSystem(): boolean {
    const state = this.store.getState();
    const actOne = state.actOne;
    if (actOne.phase !== "system_required") {
      return actOne.phase === "inventory_required" || actOne.phase === "system_return_required";
    }
    if (actOne.inventoryRecovered && state.items.campusCard) {
      this.patch({ phase: "system_return_required" });
      this.events.emit("act2_system_inventory_confirmed", { itemId: "campusCard" });
      return true;
    }
    this.patch({ phase: "inventory_required", dormHubUnlocked: true });
    this.events.emit("act2_system_inventory_requested");
    return true;
  }

  recoverInventory(): boolean {
    const state = this.store.getState();
    if (state.actOne.inventoryRecovered && state.items.campusCard) {
      return true;
    }
    if (state.actOne.phase !== "inventory_required") {
      return false;
    }
    this.store.setState((current) => ({
      ...current,
      items: { ...current.items, campusCard: true },
      actOne: {
        ...current.actOne,
        phase: "system_return_required",
        inventoryRecovered: true,
        dormHubUnlocked: true
      },
      ui: { ...current.ui, inventoryOpen: true, selectedItem: null }
    }));
    this.events.emit("get_item", { itemId: "campusCard", sourceScene: "dorm_hub" });
    this.events.emit("act2_inventory_recovered", { itemId: "campusCard" });
    return true;
  }

  startMovementQuest(): boolean {
    const actOne = this.getState();
    if (actOne.phase !== "system_return_required" || !actOne.inventoryRecovered) {
      return this.isMovementPhase(actOne);
    }
    this.patch({ phase: "movement_required" });
    this.events.emit("act2_movement_quest_started", { destination: "library" });
    return true;
  }

  inspectCharacter(): boolean {
    const actOne = this.getState();
    if (!this.isMovementPhase(actOne)) {
      return false;
    }
    if (!actOne.characterPromptSeen) {
      this.patch({ characterPromptSeen: true });
      this.events.emit("act2_character_cannot_hear");
    }
    return true;
  }

  identifyCharacter(name: string, studentId: string): boolean {
    const actOne = this.getState();
    if (!this.isMovementPhase(actOne) || !actOne.inventoryRecovered) {
      return false;
    }
    const normalizedName = normalizeIdentityName(name);
    const normalizedStudentId = normalizeStudentId(studentId);
    if (
      normalizedName !== normalizeIdentityName(content.studentName)
      || normalizedStudentId !== normalizeStudentId(content.studentId)
    ) {
      this.events.emit("act2_character_identity_rejected", {
        hasName: Boolean(normalizedName),
        hasStudentId: Boolean(normalizedStudentId),
        nameMatches: normalizedName === normalizeIdentityName(content.studentName),
        studentIdMatches: normalizedStudentId === normalizeStudentId(content.studentId)
      });
      return false;
    }
    if (actOne.characterNamed) {
      return true;
    }
    this.updateMovementFacts({ characterNamed: true, identityVerified: true });
    this.events.emit("act2_character_named", { name: content.studentName, studentId: content.studentId });
    return true;
  }

  startExercise(): boolean {
    const actOne = this.getState();
    if (!this.isMovementPhase(actOne) || !actOne.characterNamed) {
      return false;
    }
    if (actOne.exerciseStarted) {
      return true;
    }
    this.updateMovementFacts({ exerciseStarted: true });
    this.events.emit("act2_exercise_started");
    return true;
  }

  collectPushTriangle(): boolean {
    const state = this.store.getState();
    if (!this.isMovementPhase(state.actOne)) {
      return false;
    }
    if (state.actOne.pushTriangleTaken) {
      return true;
    }
    this.store.setState((current) => ({
      ...current,
      items: { ...current.items, pushTriangle: true },
      actOne: { ...current.actOne, pushTriangleTaken: true }
    }));
    this.events.emit("get_item", { itemId: "pushTriangle", sourceScene: "phone_home" });
    this.events.emit("act2_push_triangle_collected");
    return true;
  }

  collectWeatherWater(): boolean {
    const state = this.store.getState();
    if (!this.isMovementPhase(state.actOne)) {
      return false;
    }
    if (state.actOne.weatherWaterTaken) {
      return true;
    }
    this.store.setState((current) => ({
      ...current,
      items: { ...current.items, weatherWater: true },
      actOne: { ...current.actOne, weatherWaterTaken: true }
    }));
    this.events.emit("get_item", { itemId: "weatherWater", sourceScene: "weather" });
    this.events.emit("act2_weather_water_collected");
    return true;
  }

  releaseMentorLine(): boolean {
    const state = this.store.getState();
    if (!this.isMovementPhase(state.actOne) || !state.items.weatherWater) {
      return false;
    }
    if (state.actOne.mentorLineReleased) {
      return true;
    }
    this.store.setState((current) => ({
      ...current,
      items: {
        ...current.items,
        weatherWater: false,
        mentorLine: true
      },
      actOne: { ...current.actOne, mentorLineReleased: true },
      ui: { ...current.ui, selectedItem: null }
    }));
    this.events.emit("use_item", { itemId: "weatherWater", targetId: "mentor_avatar" });
    this.events.emit("get_item", { itemId: "mentorLine", sourceScene: "wechat" });
    this.events.emit("act2_mentor_line_released");
    return true;
  }

  shiftBalance(): boolean {
    const state = this.store.getState();
    if (!this.isMovementPhase(state.actOne) || !state.items.rightArrow || !state.actOne.rightArrowAssembled) {
      return false;
    }
    if (state.actOne.balanceShifted) {
      return true;
    }
    this.store.setState((current) => ({
      ...current,
      actOne: { ...current.actOne, balanceShifted: true },
      ui: { ...current.ui, selectedItem: null }
    }));
    this.events.emit("use_item", { itemId: "rightArrow", targetId: "campus_card_balance" });
    this.events.emit("act2_balance_shifted", { from: "0.06", to: "6.00" });
    return true;
  }

  purchaseGamepad(): GamepadPurchaseResult {
    const state = this.store.getState();
    if (!this.isMovementPhase(state.actOne)) {
      return "inactive";
    }
    if (state.actOne.gamepadPurchased || state.items.gamepad) {
      this.syncGamepadOwnership();
      return "already_owned";
    }
    if (!state.actOne.balanceShifted) {
      this.events.emit("act2_gamepad_purchase_rejected", { balance: "0.06", price: "6.00" });
      return "insufficient_balance";
    }
    this.syncGamepadOwnership();
    this.events.emit("get_item", { itemId: "gamepad", sourceScene: "cc98" });
    this.events.emit("act2_gamepad_purchased", { price: "6.00" });
    return "purchased";
  }

  useGamepad(): GamepadUseResult {
    const state = this.store.getState();
    if (!state.items.gamepad && !state.actOne.gamepadPurchased) {
      this.events.emit("act2_gamepad_use_rejected", { reason: "not_owned" });
      return "not_owned";
    }
    if (!this.isMovementPhase(state.actOne) && state.actOne.phase !== "complete") {
      this.events.emit("act2_gamepad_use_rejected", { reason: "inactive" });
      return "inactive";
    }

    this.syncGamepadOwnership();
    const actOne = this.getState();
    if (!actOne.characterNamed) {
      this.events.emit("act2_gamepad_use_rejected", { reason: "identity_required" });
      return "identity_required";
    }
    if (!actOne.exerciseStarted) {
      this.events.emit("act2_gamepad_use_rejected", { reason: "exercise_required" });
      return "exercise_required";
    }

    this.events.emit("act2_gamepad_connected", { movementEnabled: actOne.movementEnabled });
    return "active";
  }

  confirmManualControl(): boolean {
    const actOne = this.getState();
    if (!this.isMovementPhase(actOne) || !actOne.movementEnabled || !actOne.gamepadPurchased) {
      return false;
    }
    if (actOne.manualControlTested) {
      return true;
    }
    this.patch({
      phase: "movement_ready",
      manualControlTested: true,
      canLeaveDorm: true
    });
    this.events.emit("act2_exit_ready");
    return true;
  }

  leaveDorm(): boolean {
    const actOne = this.getState();
    if (!actOne.canLeaveDorm || actOne.phase !== "movement_ready") {
      this.events.emit("act2_dorm_exit_rejected");
      return false;
    }
    this.patch({ phase: "complete" });
    this.events.emit("act2_movement_quest_completed", { destination: "library" });
    return true;
  }

  returnToPhone(): void {
    this.store.setState((state) => ({
      ...state,
      runtimeMode: "phone",
      currentScene: "phone_home",
      ui: { ...state.ui, zjudingPage: "hub" }
    }));
    this.events.emit("act2_phone_opened", { sceneId: "phone_home" });
  }

  private getState(): ActOneBootstrapState {
    return this.store.getState().actOne;
  }

  private patch(patch: Partial<ActOneBootstrapState>): void {
    this.store.setState((state) => ({ ...state, actOne: { ...state.actOne, ...patch } }));
  }

  private isMovementPhase(state: ActOneBootstrapState): boolean {
    return state.phase === "movement_required" || state.phase === "movement_ready";
  }

  private updateMovementFacts(patch: Partial<ActOneBootstrapState>): void {
    this.store.setState((state) => {
      const nextActOne = { ...state.actOne, ...patch };
      const movementEnabled = nextActOne.characterNamed && nextActOne.exerciseStarted && nextActOne.gamepadPurchased;
      return {
        ...state,
        actOne: {
          ...nextActOne,
          identityVerified: nextActOne.characterNamed,
          controlsInstalled: nextActOne.gamepadPurchased,
          movementEnabled
        }
      };
    });
  }

  private syncGamepadOwnership(): void {
    this.store.setState((state) => {
      const nextActOne = { ...state.actOne, gamepadPurchased: true };
      return {
        ...state,
        items: { ...state.items, gamepad: true },
        actOne: {
          ...nextActOne,
          identityVerified: nextActOne.characterNamed,
          controlsInstalled: true,
          movementEnabled: nextActOne.characterNamed && nextActOne.exerciseStarted
        }
      };
    });
  }

}

function normalizeIdentityName(value: string): string {
  return value.normalize("NFKC").replace(/\s+/g, "");
}

function normalizeStudentId(value: string): string {
  return value.normalize("NFKC").replace(/\D/g, "");
}
