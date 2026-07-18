import { createStore } from "zustand/vanilla";
import { SaveStore } from "./SaveStore";
import type { GameState, GameStore } from "./types";
import { DEVELOPER_ACTIVE_KEY } from "./StorageKeys";

export function createInitialGameState(): GameState {
  return {
    runtimeMode: "phone",
    rpgScene: "campus_bootstrap",
    rpgCheckpoint: "campus_library_gate",
    currentScene: "alarm",
    networkMode: "campus_wifi",
    themeMode: "normal",
    digits: {
      d1: null,
      d2: null,
      d3: null,
      d4: null
    },
    items: {
      waterDrop: false,
      headphone: false,
      wateredHeadphone: false,
      reverseGear: false,
      slashLine: false,
      towerKey: false,
      fertilizer: false,
      campusCard: false,
      pushTriangle: false,
      weatherWater: false,
      mentorLine: false,
      rightArrow: false,
      gamepad: false,
      occupancyNote: false,
      callNumber755: false,
      archivedLeaveRule: false,
      itemRecognitionReport: false,
      bagNonPersonProof: false,
      seat022Receipt: false,
      libraryPresenceProof: false,
      seatReleasePass: false
    },
    flags: {
      codeScattered: false,
      cardZeroTaken: false,
      tiyiCrashCount: 0,
      tiyiCountTaken: false,
      gearFallen: false,
      gearNineTaken: false,
      headphoneFallen: false,
      waterDropTaken: false,
      slashHalfDropped: false,
      slashTapCount: 0,
      slashTaken: false,
      bonsaiHintShown: false,
      towerOpened: false,
      plantWatered: false,
      plantLit: false,
      plantFertilized: false,
      flowerBloomed: false,
      flowerEightTaken: false,
      checkinDone: false
    },
    actOne: {
      phase: "prologue",
      identityVerified: false,
      phoneLinked: false,
      controlsInstalled: false,
      movementEnabled: false,
      inventoryRecovered: false,
      characterPromptSeen: false,
      characterNamed: false,
      exerciseStarted: false,
      pushTriangleTaken: false,
      weatherWaterTaken: false,
      mentorLineReleased: false,
      rightArrowAssembled: false,
      balanceShifted: false,
      gamepadPurchased: false,
      manualControlTested: false,
      canLeaveDorm: false,
      requiredItemCollected: false,
      visitedAreaIds: [],
      gameMenuUnlocked: false,
      dormHubUnlocked: false
    },
    bikeArcade: {
      unlocked: false,
      completed: false,
      attemptCount: 0,
      bestDistance: 0,
      bestLives: 0
    },
    ui: {
      controlCenterOpen: false,
      autoRotate: false,
      musicPlaying: false,
      brightness: 33,
      inventoryOpen: false,
      selectedItem: null,
      zjudingPage: "hub",
      librarySelectedSeat: null,
      librarySeatReserved: false,
      libraryFinalsPhase: "idle",
      libraryFinalsPuzzle: {
        libraryVisitedPoints: [],
        entranceRecordRead: false,
        backpackInspected: false,
        occupancyNoteCollected: false,
        investigationOpened: false,
        optionalAc01Floors: [],
        catalogSearchCompleted: false,
        callNumberCollected: false,
        archivedRuleCollected: false,
        photoDimmed: false,
        itemReportGenerated: false,
        nonPersonProofStamped: false,
        seatReceiptCollected: false,
        auditAttemptCount: 0,
        auditArrivalMinutes: 0,
        auditPublicNoticeFloor: 0,
        auditProofCount: 0,
        presenceProofCollected: false,
        cc98UploadedEvidenceIds: [],
        bdCount: 0,
        appliedBdReplyIds: [],
        recoverySubmittedEvidenceIds: [],
        evictionPassGenerated: false,
        backpackEvicted: false,
        playerSeated: false,
        nextQuestId: null,
        clueIds: []
      },
      seenChapterIntros: []
    }
  };
}

export function createGameStore(initialState = createInitialGameState()): GameStore {
  const store = createStore<GameState>(() => initialState);

  return {
    getState: store.getState,
    subscribe: (listener) => store.subscribe(listener),
    setState: (updater) => store.setState((state) => updater(state), true)
  };
}

export function createPersistentGameStore(storage?: Storage): GameStore {
  const initial = createInitialGameState();
  const resolvedStorage = storage ?? (typeof window === "undefined" ? null : window.localStorage);
  if (!resolvedStorage) {
    return createGameStore(initial);
  }

  const saveStore = new SaveStore(resolvedStorage);
  const persistedGame = saveStore.load(initial);
  const persistedBike = persistedGame ? null : saveStore.loadBikeArcade(initial);
  const hydrated: GameState = persistedGame ?? (persistedBike
    ? {
        ...initial,
        bikeArcade: persistedBike.bikeArcade
      }
    : initial);
  const store = createGameStore(hydrated);
  let lastSnapshot = JSON.stringify(hydrated);

  if (persistedGame || persistedBike) {
    saveStore.save(hydrated);
    saveStore.saveBikeArcade(hydrated);
  }
  store.subscribe(() => {
    const state = store.getState();
    const snapshot = JSON.stringify(state);
    if (snapshot === lastSnapshot) {
      return;
    }
    lastSnapshot = snapshot;
    if (typeof window !== "undefined" && window.sessionStorage.getItem(DEVELOPER_ACTIVE_KEY)) {
      return;
    }
    saveStore.save(state);
    saveStore.saveBikeArcade(state);
  });

  return store;
}

export const gameStore = createPersistentGameStore();
