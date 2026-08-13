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
      seatReleasePass: false,
      cafeteriaWages: false,
      greaseTissue: false,
      sparklingWater: false,
      lemonTea: false,
      blackCoffee: false,
      badDrink: false,
      dailySpecialSparklingWater: false,
      pickupTicket0755: false,
      canteenRealBun: false,
      canteenCluelessSoyMilk: false,
      canteenEdgeEgg: false,
      canteenUselessCongee: false,
      theaterTicketHalfA: false,
      theaterTicketHalfB: false,
      temporaryTheaterTicket: false,
      theaterProgramOpening: false,
      theaterProgramSpotlight: false,
      theaterProgramFinale: false,
      spotlightRemote: false,
      fluorescentBrush: false,
      decoyPaper: false,
      wetProgram: false,
      bridgeKeyword: false,
      reflectionKeyword: false,
      lakeKeyword: false,
      reflectionCoordinate: false,
      fishingRod: false,
      rustedLockerKey: false,
      nylonCord: false,
      brokenNetFrame: false,
      improvisedDipNet: false,
      sealedFeedTin: false,
      fishFeedPellets: false,
      smallCarp: false,
      swanMagnet: false,
      magneticFishingRod: false
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
      pushTriangleTapCount: 0,
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
    wallet: {
      campusCardCents: 6,
      cashCents: 0
    },
    bikeArcade: {
      unlocked: false,
      completed: false,
      attemptCount: 0,
      bestDistance: 0,
      bestLives: 0
    },
    canteenHunt: {
      active: false,
      phase: "tracking",
      mode: "light",
      entryPaperEscaped: false,
      trayTaskStarted: false,
      carriedTrayIds: [],
      identifiedTrayIds: [],
      returnedTrayIds: [],
      drinkShelfRead: false,
      drinkMixSequence: [],
      drinkMixAttemptCount: 0,
      queueChallengeSeen: false,
      promoDrinkPlaced: false,
      queueGapOpened: false,
      menuDarkClueRead: false,
      pickupTimeErrorSeen: false,
      pickupDarkClueRead: false,
      defenseDrinkUsed: false,
      orderedMenuOption: null,
      identifiedExitIds: [],
      orderAttemptCount: 0,
      pickupAttemptCount: 0,
      blockHits: 0,
      bikeCodeRead: false,
      bikeLockCleaned: false,
      bikePaid: false,
      chaseCompleted: false,
      chaseAttemptCount: 0,
      chaseBestDistance: 0,
      chaseBestLives: 0,
      chaseCollisions: 0
    },
    theaterHunt: {
      active: false,
      phase: "entry_ticket",
      mode: "light",
      cc98TicketCommissionPhase: "locked",
      cc98TicketClaimedWave: null,
      posterCleaned: false,
      ticketCodeRead: false,
      ticketCodeAttempts: 0,
      admitted: false,
      collectedProgramIds: [],
      programOrder: [],
      programWrongAttempts: 0,
      propGhostRead: false,
      managerHintRead: false,
      propBoxOpened: false,
      paperDusted: false,
      spotlightRound: 0,
      spotlightMistakes: 0,
      decoyRevealed: false
    },
    qizhenLake: {
      active: false,
      phase: "inactive",
      mode: "light",
      zone: "dock",
      vehicle: "on_foot",
      safeSpawnId: "dock_entry",
      locationBriefingSeen: false,
      bridgeClueFound: false,
      reflectionClueFound: false,
      lakeClueFound: false,
      mapClueIds: [],
      introSeen: false,
      kayakEquipped: false,
      leftPaddleEquipped: false,
      rightPaddleEquipped: false,
      boardingStrokeCount: 0,
      boardingLastSide: null,
      boardingTutorialCompleted: false,
      capsizeCount: 0,
      rodFound: false,
      decoyBaitAttached: false,
      reflectionLocationObserved: false,
      observedFishingSpotIds: [],
      directPaperCastFailures: 0,
      lockerOpened: false,
      netCombined: false,
      feedTinRetrieved: false,
      feedTinOpened: false,
      fishCaught: false,
      swanFed: false,
      magneticRodCombined: false,
      paperCaptured: false,
      swanReleased: false,
      chaseDistance: 0,
      chaseBestDistance: 0,
      chaseAttempts: 0,
      magneticAttachmentBroken: false,
      transitionReady: false,
      reflectionRound: 0,
      reflectionMistakes: 0,
      signRotations: [0, 0, 0],
      signsSolved: false,
      decoyPlacedAt: null,
      decoyAttempts: 0,
      mistRhythmRead: false,
      mistAttempts: 0,
      paperReleased: false
    },
    // 第四章「校时」：07:55:23 被篡改冻结，目标 08:00:00。
    clockCalibration: {
      phase: "tampered",
      step: "target_selection",
      displayedSeconds: 28523,
      targetSeconds: 28800,
      selectedTargetSeconds: null,
      archiveClueIds: [],
      coarseLockIds: [],
      driftCorrectedChannelIds: [],
      driftAttempts: 0,
      phaseLockHits: 0,
      phaseLockAttempts: 0,
      adjustCount: 0
    },
    // 第四章：序幕完成后进入段永平教学楼 A1，22:45 起始。
    chapter4: {
      prologueSeen: false,
      phase: "inactive",
      cycle: 1,
      mode: "light",
      building: "A",
      floor: "A1",
      roomId: "a1_lobby",
      buildingTimeSeconds: 81900,
      airflowObserved: false,
      paperGuidedToElevator: false,
      elevatorHistoryObserved: false,
      elevatorSelectedStartSeconds: null,
      elevatorTrackAligned: false,
      elevatorReplayAttempts: 0,
      elevatorPlayerBoarded: false,
      stairEchoObserved: false,
      stairRotationQuarterTurns: 0,
      stairAlignmentSolved: false,
      solvedPuzzleIds: [],
      clueIds: [],
      anchor: null,
      echoRecorded: false,
      resetCount: 0,
      finalCode: null,
      completed: false
    },
    ui: {
      controlCenterOpen: false,
      autoRotate: false,
      musicPlaying: false,
      musicMuted: false,
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
        catalogUnlocked: false,
        callNumberCollected: false,
        archivedRuleCollected: false,
        archivedRuleRead: false,
        archivedRuleBriefingSeen: false,
        frontDeskProofRequestSeen: false,
        photoCaptured: false,
        photoDimmed: false,
        itemReportGenerated: false,
        lostFoundStage: "missing_report",
        nonPersonProofStamped: false,
        seatReceiptCollected: false,
        auditAttemptCount: 0,
        auditArrivalMinutes: 0,
        auditPublicNoticeFloor: 0,
        auditProofCount: 0,
        presenceProofCollected: false,
        cc98UploadedEvidenceIds: [],
        preBdBriefingSeen: false,
        bdCount: 0,
        appliedBdReplyIds: [],
        bdSelectedPostIds: [],
        bdPasswordAttemptCount: 0,
        recoverySubmittedEvidenceIds: [],
        evictionPassGenerated: false,
        passBriefingSeen: false,
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
