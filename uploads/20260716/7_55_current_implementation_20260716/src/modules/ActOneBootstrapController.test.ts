import { describe, expect, it } from "vitest";
import { EventBus } from "../core/EventBus";
import { createGameStore } from "../core/GameState";
import content from "../data/act-one-bootstrap.content.json";
import { ActOneBootstrapController } from "./ActOneBootstrapController";
import { InventoryController } from "./InventoryController";

describe("ActOneBootstrapController", () => {
  it("returns to the phone after the narrator is restrained without resetting prologue progress", () => {
    const store = createGameStore();
    const events = new EventBus();
    const controller = new ActOneBootstrapController(store, events);
    store.setState((state) => ({
      ...state,
      currentScene: "ending",
      digits: { d1: "0", d2: "7", d3: "9", d4: "8" },
      flags: { ...state.flags, checkinDone: true }
    }));

    expect(controller.beginAfterCheckin()).toBe(true);
    expect(store.getState()).toMatchObject({
      runtimeMode: "phone",
      currentScene: "phone_home",
      digits: { d1: "0", d2: "7", d3: "9", d4: "8" },
      flags: { checkinDone: true },
      actOne: { phase: "friend_message_required", dormHubUnlocked: true }
    });
    expect(events.getHistory()).toEqual(expect.arrayContaining([
      { name: "prologue_narrator_released" },
      { name: "act2_entry_unlocked", payload: { entry: "phone_home" } }
    ]));
  });

  it("rejects the next chapter entry before check-in succeeds", () => {
    const store = createGameStore();
    const events = new EventBus();
    const controller = new ActOneBootstrapController(store, events);

    expect(controller.beginAfterCheckin()).toBe(false);
    expect(store.getState().runtimeMode).toBe("phone");
    expect(events.getHistory()).toContainEqual({
      name: "act2_entry_rejected",
      payload: { reason: "checkin_incomplete" }
    });
  });

  it("unlocks the first-chapter dorm only after the sign-in code scatters", () => {
    const store = createGameStore();
    const events = new EventBus();
    const controller = new ActOneBootstrapController(store, events);

    expect(controller.enterRpg("dorm_hub")).toBe(false);
    store.setState((state) => ({
      ...state,
      flags: { ...state.flags, codeScattered: true }
    }));
    expect(controller.enterRpg("dorm_hub")).toBe(true);
    expect(store.getState()).toMatchObject({
      runtimeMode: "rpg",
      rpgScene: "dorm_hub",
      actOne: { phase: "prologue", dormHubUnlocked: true }
    });
  });

  it("advances through the assembled movement puzzle in order", () => {
    const store = createGameStore();
    const events = new EventBus();
    const controller = new ActOneBootstrapController(store, events);
    const inventory = new InventoryController(store, events);
    store.setState((state) => ({
      ...state,
      items: { ...state.items, campusCard: true },
      actOne: {
        ...state.actOne,
        phase: "movement_required",
        inventoryRecovered: true,
        dormHubUnlocked: true
      }
    }));

    expect(controller.inspectCharacter()).toBe(true);
    expect(controller.identifyCharacter(content.studentName, content.studentId)).toBe(true);
    expect(controller.startExercise()).toBe(true);
    expect(controller.collectPushTriangle()).toBe(true);
    expect(controller.collectWeatherWater()).toBe(true);
    expect(controller.releaseMentorLine()).toBe(true);
    expect(inventory.combine("pushTriangle", "mentorLine")).toBe("rightArrow");
    expect(controller.shiftBalance()).toBe(true);
    expect(controller.purchaseGamepad()).toBe("purchased");
    expect(controller.confirmManualControl()).toBe(true);
    expect(controller.leaveDorm()).toBe(true);

    expect(store.getState().actOne).toMatchObject({
      phase: "complete",
      identityVerified: true,
      characterNamed: true,
      exerciseStarted: true,
      rightArrowAssembled: true,
      balanceShifted: true,
      gamepadPurchased: true,
      controlsInstalled: true,
      movementEnabled: true,
      manualControlTested: true,
      canLeaveDorm: true
    });
    expect(store.getState().items).toMatchObject({
      campusCard: true,
      pushTriangle: false,
      weatherWater: false,
      mentorLine: false,
      rightArrow: true,
      gamepad: true
    });
  });

  it("rejects movement steps whose evidence or prerequisite is missing", () => {
    const store = createGameStore();
    const events = new EventBus();
    const controller = new ActOneBootstrapController(store, events);
    store.setState((state) => ({
      ...state,
      actOne: { ...state.actOne, phase: "movement_required", inventoryRecovered: true }
    }));

    expect(controller.startExercise()).toBe(false);
    expect(controller.releaseMentorLine()).toBe(false);
    expect(controller.shiftBalance()).toBe(false);
    expect(controller.purchaseGamepad()).toBe("insufficient_balance");
    expect(controller.identifyCharacter("路人", "87950000")).toBe(false);
    expect(controller.confirmManualControl()).toBe(false);
    expect(controller.leaveDorm()).toBe(false);
    expect(store.getState().actOne.phase).toBe("movement_required");
  });

  it("accepts campus-card identity with full-width digits and harmless spacing", () => {
    const store = createGameStore();
    const events = new EventBus();
    const controller = new ActOneBootstrapController(store, events);
    store.setState((state) => ({
      ...state,
      items: { ...state.items, campusCard: true },
      actOne: { ...state.actOne, phase: "movement_required", inventoryRecovered: true }
    }));

    expect(controller.identifyCharacter(" 林　星宇 ", "３２５０１００７５５")).toBe(true);
    expect(store.getState().actOne).toMatchObject({ characterNamed: true, identityVerified: true });
  });

  it("reports which campus-card identity field failed without accepting a partial match", () => {
    const store = createGameStore();
    const events = new EventBus();
    const controller = new ActOneBootstrapController(store, events);
    store.setState((state) => ({
      ...state,
      items: { ...state.items, campusCard: true },
      actOne: { ...state.actOne, phase: "movement_required", inventoryRecovered: true }
    }));

    expect(controller.identifyCharacter(content.studentName, "3250100000")).toBe(false);
    expect(events.getHistory()).toContainEqual({
      name: "act2_character_identity_rejected",
      payload: {
        hasName: true,
        hasStudentId: true,
        nameMatches: true,
        studentIdMatches: false
      }
    });
  });

  it("repairs an owned gamepad whose purchase and control flags were missing", () => {
    const store = createGameStore();
    const events = new EventBus();
    const controller = new ActOneBootstrapController(store, events);
    store.setState((state) => ({
      ...state,
      items: { ...state.items, campusCard: true, gamepad: true },
      actOne: {
        ...state.actOne,
        phase: "movement_required",
        inventoryRecovered: true,
        characterNamed: true,
        identityVerified: true,
        exerciseStarted: true,
        gamepadPurchased: false,
        controlsInstalled: false,
        movementEnabled: false
      }
    }));

    expect(controller.useGamepad()).toBe("active");
    expect(store.getState()).toMatchObject({
      items: { gamepad: true },
      actOne: { gamepadPurchased: true, controlsInstalled: true, movementEnabled: true }
    });
    expect(events.getHistory()).toContainEqual({
      name: "act2_gamepad_connected",
      payload: { movementEnabled: true }
    });
  });

  it("repairs owned gamepad controls when the dorm map is reopened before using the return button", () => {
    const store = createGameStore();
    const events = new EventBus();
    const controller = new ActOneBootstrapController(store, events);
    store.setState((state) => ({
      ...state,
      runtimeMode: "phone",
      currentScene: "cc98",
      items: { ...state.items, campusCard: true, gamepad: true },
      actOne: {
        ...state.actOne,
        phase: "movement_required",
        dormHubUnlocked: true,
        inventoryRecovered: true,
        characterNamed: true,
        identityVerified: true,
        exerciseStarted: true,
        gamepadPurchased: true,
        controlsInstalled: false,
        movementEnabled: false
      }
    }));

    expect(controller.enterRpg("dorm_hub")).toBe(true);
    expect(store.getState()).toMatchObject({
      runtimeMode: "rpg",
      rpgScene: "dorm_hub",
      items: { gamepad: true },
      actOne: {
        gamepadPurchased: true,
        controlsInstalled: true,
        movementEnabled: true
      }
    });

    controller.returnToPhone();
    expect(controller.enterRpg("dorm_hub")).toBe(true);
    expect(store.getState().actOne).toMatchObject({
      controlsInstalled: true,
      movementEnabled: true
    });
  });

  it("keeps the gamepad visible while naming and exercise prerequisites are incomplete", () => {
    const store = createGameStore();
    const events = new EventBus();
    const controller = new ActOneBootstrapController(store, events);
    store.setState((state) => ({
      ...state,
      items: { ...state.items, gamepad: true },
      actOne: { ...state.actOne, phase: "movement_required" }
    }));

    expect(controller.useGamepad()).toBe("identity_required");
    expect(store.getState()).toMatchObject({
      items: { gamepad: true },
      actOne: { gamepadPurchased: true, controlsInstalled: true, movementEnabled: false }
    });

    store.setState((state) => ({
      ...state,
      actOne: { ...state.actOne, characterNamed: true, identityVerified: true }
    }));
    expect(controller.useGamepad()).toBe("exercise_required");
  });

  it("returns from the campus map to the ZJU Ding hub", () => {
    const store = createGameStore();
    const events = new EventBus();
    const controller = new ActOneBootstrapController(store, events);
    store.setState((state) => ({
      ...state,
      runtimeMode: "rpg",
      currentScene: "phone_home",
      ui: { ...state.ui, zjudingPage: "library" }
    }));

    controller.returnToPhone();

    expect(store.getState()).toMatchObject({
      runtimeMode: "phone",
      currentScene: "zjuding",
      ui: { zjudingPage: "hub" }
    });
    expect(events.getHistory()).toContainEqual({
      name: "act2_phone_opened",
      payload: { sceneId: "zjuding" }
    });
  });

  it("recovers the campus card in chapter one and reuses it after the system is found", () => {
    const store = createGameStore();
    const events = new EventBus();
    const controller = new ActOneBootstrapController(store, events);

    store.setState((state) => ({
      ...state,
      flags: { ...state.flags, codeScattered: true }
    }));
    expect(controller.enterRpg("dorm_hub")).toBe(true);
    expect(controller.recoverInventory()).toBe(true);
    expect(store.getState()).toMatchObject({
      items: { campusCard: true },
      actOne: {
        phase: "prologue",
        inventoryRecovered: true,
        dormHubUnlocked: true
      },
      ui: { inventoryOpen: true }
    });

    store.setState((state) => ({
      ...state,
      currentScene: "ending",
      flags: { ...state.flags, checkinDone: true }
    }));

    expect(controller.completeNarratorIntervention()).toBe(true);
    expect(controller.completeFriendExchange()).toBe(true);
    expect(store.getState().actOne.phase).toBe("system_required");
    expect(controller.confrontSystem()).toBe(true);
    expect(store.getState().actOne.phase).toBe("system_return_required");
    expect(controller.startMovementQuest()).toBe(true);
    expect(store.getState().actOne.phase).toBe("movement_required");
    expect(events.getHistory()).toEqual(expect.arrayContaining([
      { name: "act2_friend_exchange_completed" },
      { name: "act1_campus_card_recovered", payload: { itemId: "campusCard" } },
      { name: "act2_system_inventory_confirmed", payload: { itemId: "campusCard" } },
      { name: "act2_movement_quest_started", payload: { destination: "library" } }
    ]));
  });

  it("keeps the second-chapter chest path only for an old save without a campus card", () => {
    const store = createGameStore();
    const events = new EventBus();
    const controller = new ActOneBootstrapController(store, events);
    store.setState((state) => ({
      ...state,
      actOne: { ...state.actOne, phase: "system_required" }
    }));

    expect(controller.confrontSystem()).toBe(true);
    expect(store.getState().actOne.phase).toBe("inventory_required");
    expect(controller.recoverInventory()).toBe(true);
    expect(store.getState()).toMatchObject({
      items: { campusCard: true },
      actOne: { phase: "system_return_required", inventoryRecovered: true }
    });
  });
});
