import { beforeEach, describe, expect, it } from "vitest";
import { createInitialGameState, createPersistentGameStore } from "./GameState";
import { SaveStore } from "./SaveStore";

const SAVE_KEY = "seven_fifty_five_state";
const SAVE_BACKUP_KEY = "seven_fifty_five_state_backup";
const BIKE_SAVE_KEY = "seven_fifty_five_bike_arcade_state";

beforeEach(() => {
  window.localStorage.clear();
});

describe("createInitialGameState", () => {
  it("starts with the V2 library state, checkpoint and all evidence items unowned", () => {
    const state = createInitialGameState();

    expect(state).toMatchObject({
      runtimeMode: "phone",
      rpgScene: "campus_bootstrap",
      rpgCheckpoint: "campus_library_gate",
      currentScene: "alarm",
      networkMode: "campus_wifi",
      themeMode: "normal",
      digits: { d1: null, d2: null, d3: null, d4: null },
      bikeArcade: {
        unlocked: false,
        completed: false,
        attemptCount: 0,
        bestDistance: 0,
        bestLives: 0
      }
    });
    expect(state.items).toEqual({
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
    });
    expect(state.ui.libraryFinalsPhase).toBe("idle");
    expect(state.actOne.dormHubUnlocked).toBe(false);
    expect(state.ui.libraryFinalsPuzzle).toEqual({
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
    });
  });
});

describe("SaveStore V5", () => {
  it("writes a versioned envelope and restores an in-progress investigation", () => {
    const store = createPersistentGameStore(window.localStorage);
    store.setState((state) => ({
      ...state,
      runtimeMode: "rpg",
      rpgScene: "library_interior",
      rpgCheckpoint: "library_shelf_755",
      currentScene: "cc98",
      items: {
        ...state.items,
        rightArrow: true,
        occupancyNote: true,
        callNumber755: true,
        archivedLeaveRule: true
      },
      actOne: {
        ...state.actOne,
        phase: "complete",
        inventoryRecovered: true,
        rightArrowAssembled: true,
        balanceShifted: true,
        canLeaveDorm: true
      },
      ui: {
        ...state.ui,
        selectedItem: "callNumber755",
        libraryFinalsPhase: "evidence_gathering",
        libraryFinalsPuzzle: {
          ...state.ui.libraryFinalsPuzzle,
          libraryVisitedPoints: ["entrance", "seat_022", "catalog_terminal", "shelf_755"],
          entranceRecordRead: true,
          backpackInspected: true,
          occupancyNoteCollected: true,
          investigationOpened: true,
          optionalAc01Floors: [2, 6, 11, 17, 23],
          catalogSearchCompleted: true,
          callNumberCollected: true,
          archivedRuleCollected: true,
          clueIds: ["arrival_7_minutes", "occupancy_note", "call_number_755"]
        }
      }
    }));

    const raw = JSON.parse(window.localStorage.getItem(SAVE_KEY) ?? "null") as {
      version?: number;
      state?: unknown;
    };
    expect(raw.version).toBe(5);
    expect(raw.state).toBeTruthy();
    expect(window.localStorage.getItem(BIKE_SAVE_KEY)).not.toBeNull();

    const rebuilt = createPersistentGameStore(window.localStorage).getState();
    expect(rebuilt).toMatchObject({
      runtimeMode: "rpg",
      rpgScene: "library_interior",
      rpgCheckpoint: "library_shelf_755",
      currentScene: "cc98",
      items: { rightArrow: true, occupancyNote: false, callNumber755: false, archivedLeaveRule: true },
      ui: {
        selectedItem: null,
        libraryFinalsPhase: "evidence_gathering",
        libraryFinalsPuzzle: {
          optionalAc01Floors: [2, 6, 11, 17, 23],
          archivedRuleCollected: true
        }
      }
    });
  });

  it("keeps V2 phases with shared names out of the legacy reset path", () => {
    const initial = createInitialGameState();
    const v2State = {
      ...initial,
      ui: {
        ...initial.ui,
        libraryFinalsPhase: "top_ten_rising" as const,
        libraryFinalsPuzzle: {
          ...initial.ui.libraryFinalsPuzzle,
          cc98UploadedEvidenceIds: [
            "archived_leave_rule" as const,
            "bag_non_person_proof" as const,
            "seat_022_receipt" as const,
            "library_presence_proof" as const
          ]
        }
      }
    };
    expect(new SaveStore(window.localStorage).save(v2State)).toBe(true);

    const loaded = new SaveStore(window.localStorage).load(initial);
    expect(loaded?.ui.libraryFinalsPhase).toBe("top_ten_rising");
    expect(loaded?.ui.libraryFinalsPuzzle.cc98UploadedEvidenceIds).toHaveLength(4);
  });

  it("resets an old intermediate library route while preserving the completed movement gate", () => {
    window.localStorage.setItem(SAVE_KEY, JSON.stringify({
      currentScene: "cc98",
      items: { rightArrow: false, campusCard: true },
      actOne: {
        phase: "complete",
        inventoryRecovered: true,
        rightArrowAssembled: true,
        balanceShifted: true,
        canLeaveDorm: true
      },
      ui: {
        libraryFinalsPhase: "route_audit_pending",
        libraryFinalsPuzzle: {
          routeVisited: ["north_gate"],
          recoveryCode: "7-47-3"
        }
      }
    }));

    const initial = createInitialGameState();
    const loaded = new SaveStore(window.localStorage).load(initial);
    expect(loaded?.currentScene).toBe("cc98");
    expect(loaded?.actOne.canLeaveDorm).toBe(true);
    expect(loaded?.ui.libraryFinalsPhase).toBe("library_route_unlocked");
    expect(loaded?.ui.libraryFinalsPuzzle).toEqual(initial.ui.libraryFinalsPuzzle);
    expect(loaded?.bikeArcade.unlocked).toBe(false);
  });

  it("migrates an old seat_recovered save to the completed dialogue and unlocks the bike chapter", () => {
    window.localStorage.setItem(SAVE_KEY, JSON.stringify({
      currentScene: "phone_home",
      bikeArcade: { unlocked: false, completed: false, attemptCount: 0, bestDistance: 0, bestLives: 0 },
      ui: { libraryFinalsPhase: "seat_recovered" }
    }));

    const loaded = new SaveStore(window.localStorage).load(createInitialGameState());
    expect(loaded?.ui.libraryFinalsPhase).toBe("friend_contacted");
    expect(loaded?.ui.librarySeatReserved).toBe(true);
    expect(loaded?.ui.libraryFinalsPuzzle).toMatchObject({
      backpackEvicted: true,
      playerSeated: true,
      nextQuestId: "chapter_three_book_hunt",
      clueIds: ["borrowed_attendance_record"]
    });
    expect(loaded?.bikeArcade.unlocked).toBe(true);
  });

  it("repairs a V2 completed dialogue save whose bike chapter remained locked", () => {
    const initial = createInitialGameState();
    window.localStorage.setItem(SAVE_KEY, JSON.stringify({
      version: 2,
      state: {
        ...initial,
        bikeArcade: { ...initial.bikeArcade, unlocked: false },
        ui: {
          ...initial.ui,
          libraryFinalsPhase: "friend_contacted",
          libraryFinalsPuzzle: {
            ...initial.ui.libraryFinalsPuzzle,
            playerSeated: true,
            nextQuestId: "chapter_three_book_hunt"
          }
        }
      }
    }));

    const loaded = new SaveStore(window.localStorage).load(initial);
    expect(loaded?.ui.libraryFinalsPhase).toBe("friend_contacted");
    expect(loaded?.bikeArcade.unlocked).toBe(true);
  });

  it("repairs an old save that collected the first digit before owning the campus card", () => {
    const initial = createInitialGameState();
    window.localStorage.setItem(SAVE_KEY, JSON.stringify({
      version: 3,
      state: {
        ...initial,
        digits: { ...initial.digits, d1: "0" },
        items: { ...initial.items, campusCard: false },
        flags: { ...initial.flags, cardZeroTaken: true },
        actOne: {
          ...initial.actOne,
          phase: "inventory_required",
          inventoryRecovered: false,
          dormHubUnlocked: false
        }
      }
    }));

    const loaded = new SaveStore(window.localStorage).load(initial);
    expect(loaded).toMatchObject({
      digits: { d1: "0" },
      items: { campusCard: true },
      actOne: {
        phase: "system_return_required",
        inventoryRecovered: true,
        dormHubUnlocked: true
      }
    });
  });

  it("restores the reusable right arrow when an old save shifted the campus-card decimal", () => {
    window.localStorage.setItem(SAVE_KEY, JSON.stringify({
      items: { rightArrow: false },
      actOne: {
        rightArrowAssembled: true,
        balanceShifted: true
      }
    }));

    const loaded = new SaveStore(window.localStorage).load(createInitialGameState());
    expect(loaded?.actOne).toMatchObject({ rightArrowAssembled: true, balanceShifted: true });
    expect(loaded?.items.rightArrow).toBe(true);
  });

  it("repairs an old save that owns the gamepad without matching movement flags", () => {
    const initial = createInitialGameState();
    window.localStorage.setItem(SAVE_KEY, JSON.stringify({
      version: 3,
      state: {
        ...initial,
        items: { ...initial.items, campusCard: false, gamepad: true },
        actOne: {
          ...initial.actOne,
          phase: "movement_required",
          inventoryRecovered: false,
          characterNamed: true,
          identityVerified: false,
          exerciseStarted: true,
          gamepadPurchased: false,
          controlsInstalled: false,
          movementEnabled: false
        }
      }
    }));

    const loaded = new SaveStore(window.localStorage).load(initial);
    expect(loaded).toMatchObject({
      items: { campusCard: true, gamepad: true },
      actOne: {
        inventoryRecovered: true,
        identityVerified: true,
        gamepadPurchased: true,
        controlsInstalled: true,
        movementEnabled: true
      }
    });
  });

  it("normalizes damaged V2 arrays, ranges, item selection and chapter unlock independently", () => {
    const initial = createInitialGameState();
    window.localStorage.setItem(SAVE_KEY, JSON.stringify({
      version: 2,
      state: {
        ...initial,
        bikeArcade: {
          unlocked: false,
          completed: "yes",
          attemptCount: -1,
          bestDistance: 900,
          bestLives: 5
        },
        ui: {
          ...initial.ui,
          selectedItem: "seatReleasePass",
          libraryFinalsPhase: "seat_recovered",
          libraryFinalsPuzzle: {
            ...initial.ui.libraryFinalsPuzzle,
            optionalAc01Floors: [2, 2, 24],
            auditArrivalMinutes: 13,
            auditPublicNoticeFloor: 64,
            auditProofCount: 6,
            bdCount: 9,
            cc98UploadedEvidenceIds: ["route_screenshot"]
          }
        }
      }
    }));

    const loaded = new SaveStore(window.localStorage).load(initial);
    expect(loaded?.ui.selectedItem).toBeNull();
    expect(loaded?.ui.libraryFinalsPhase).toBe("seat_recovered");
    expect(loaded?.ui.libraryFinalsPuzzle).toMatchObject({
      optionalAc01Floors: [],
      auditArrivalMinutes: 0,
      auditPublicNoticeFloor: 0,
      auditProofCount: 0,
      bdCount: 0,
      cc98UploadedEvidenceIds: []
    });
    expect(loaded?.bikeArcade).toEqual(initial.bikeArcade);
  });

  it("returns null for malformed JSON", () => {
    window.localStorage.setItem(SAVE_KEY, "{broken-json");
    expect(new SaveStore(window.localStorage).load(createInitialGameState())).toBeNull();
  });

  it("restores the previous valid snapshot when the primary save is damaged", () => {
    const saveStore = new SaveStore(window.localStorage);
    const initial = createInitialGameState();
    const chapterTwo = {
      ...initial,
      actOne: { ...initial.actOne, phase: "movement_required" as const },
      ui: {
        ...initial.ui,
        libraryFinalsPuzzle: { ...initial.ui.libraryFinalsPuzzle, backpackInspected: true }
      }
    };
    expect(saveStore.save({ ...chapterTwo, currentScene: "phone_home" })).toBe(true);
    expect(saveStore.save({ ...chapterTwo, currentScene: "cc98" })).toBe(true);
    expect(window.localStorage.getItem(SAVE_BACKUP_KEY)).not.toBeNull();

    window.localStorage.setItem(SAVE_KEY, "{broken-json");
    expect(saveStore.load(initial)?.currentScene).toBe("phone_home");
    expect(JSON.parse(window.localStorage.getItem(SAVE_KEY) ?? "null").state.currentScene).toBe("phone_home");
  });

  it("repairs locked routes, chapter intro flags and consumed paper items", () => {
    const initial = createInitialGameState();
    window.localStorage.setItem(SAVE_KEY, JSON.stringify({
      version: 4,
      state: {
        ...initial,
        currentScene: "cc98",
        items: {
          ...initial.items,
          occupancyNote: true,
          callNumber755: true,
          archivedLeaveRule: true,
          rightArrow: true,
          bagNonPersonProof: true,
          seat022Receipt: true,
          libraryPresenceProof: true
        },
        ui: {
          ...initial.ui,
          selectedItem: "seat022Receipt",
          zjudingPage: "library_recovery",
          seenChapterIntros: ["chapter_two", "bad_chapter"],
          libraryFinalsPhase: "recovery_application",
          libraryFinalsPuzzle: {
            ...initial.ui.libraryFinalsPuzzle,
            investigationOpened: true,
            archivedRuleCollected: true,
            nonPersonProofStamped: true,
            seatReceiptCollected: true,
            cc98UploadedEvidenceIds: ["archived_leave_rule"],
            recoverySubmittedEvidenceIds: ["bag_non_person_proof", "seat_022_receipt", "library_presence_proof"]
          }
        }
      }
    }));

    const loaded = new SaveStore(window.localStorage).load(initial);
    expect(loaded?.currentScene).toBe("phone_home");
    expect(loaded?.ui.zjudingPage).toBe("library_recovery");
    expect(loaded?.ui.seenChapterIntros).toEqual(["chapter_two"]);
    expect(loaded?.ui.selectedItem).toBeNull();
    expect(loaded?.items).toMatchObject({
      occupancyNote: false,
      callNumber755: false,
      archivedLeaveRule: false,
      rightArrow: false,
      bagNonPersonProof: false,
      seat022Receipt: false,
      libraryPresenceProof: false
    });
  });

  it("does not persist temporary overlays or a selected drag item", () => {
    const initial = createInitialGameState();
    const saveStore = new SaveStore(window.localStorage);
    expect(saveStore.save({
      ...initial,
      ui: { ...initial.ui, controlCenterOpen: true, inventoryOpen: true, selectedItem: "reverseGear" }
    })).toBe(true);

    const raw = JSON.parse(window.localStorage.getItem(SAVE_KEY) ?? "null");
    expect(raw.savedAt).toEqual(expect.any(Number));
    expect(raw.state.ui).toMatchObject({ controlCenterOpen: false, inventoryOpen: false, selectedItem: null });
  });
});
