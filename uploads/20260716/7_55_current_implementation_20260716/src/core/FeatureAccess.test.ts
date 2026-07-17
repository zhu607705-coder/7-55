import { describe, expect, it } from "vitest";
import { createInitialGameState } from "./GameState";
import { canEnterScene, sanitizeZjudingPage, selectFeatureAccess } from "./FeatureAccess";

describe("feature access matrix", () => {
  it("locks later apps throughout chapter one", () => {
    const state = createInitialGameState();
    expect(selectFeatureAccess(state)).toMatchObject({
      chapter: "chapter_one",
      cc98: false,
      photos: false,
      departmentDirectory: false,
      library: false,
      bikeArcade: false
    });
    expect(canEnterScene(state, "cc98")).toBe(false);
    expect(sanitizeZjudingPage(state, "directory")).toBe("hub");
    expect(sanitizeZjudingPage(state, "library_catalog")).toBe("hub");
  });

  it("opens chapter-two services before the library route", () => {
    const initial = createInitialGameState();
    const state = { ...initial, actOne: { ...initial.actOne, phase: "movement_required" as const } };
    expect(selectFeatureAccess(state)).toMatchObject({
      chapter: "chapter_two",
      cc98: true,
      departmentDirectory: true,
      weather: true,
      fullCampusMap: true,
      library: false
    });
    expect(canEnterScene(state, "cc98")).toBe(true);
    expect(sanitizeZjudingPage(state, "directory")).toBe("directory");
  });

  it("opens the library, photos, owner upload, bd and recovery in order", () => {
    const initial = createInitialGameState();
    const state = {
      ...initial,
      actOne: { ...initial.actOne, phase: "complete" as const },
      ui: {
        ...initial.ui,
        libraryFinalsPhase: "evidence_gathering" as const,
        libraryFinalsPuzzle: {
          ...initial.ui.libraryFinalsPuzzle,
          backpackInspected: true,
          archivedRuleCollected: true,
          nonPersonProofStamped: true,
          seatReceiptCollected: true,
          presenceProofCollected: true
        }
      }
    };
    expect(selectFeatureAccess(state)).toMatchObject({
      library: true,
      photos: true,
      cc98OwnerUpload: true,
      cc98Bd: false,
      libraryRecovery: false
    });

    const uploaded = {
      ...state,
      ui: {
        ...state.ui,
        libraryFinalsPhase: "top_ten_rising" as const,
        libraryFinalsPuzzle: {
          ...state.ui.libraryFinalsPuzzle,
          cc98UploadedEvidenceIds: [
            "archived_leave_rule" as const,
            "bag_non_person_proof" as const,
            "seat_022_receipt" as const,
            "library_presence_proof" as const
          ]
        }
      }
    };
    expect(selectFeatureAccess(uploaded).cc98Bd).toBe(true);
    expect(selectFeatureAccess(uploaded).libraryRecovery).toBe(false);

    const ranked = { ...uploaded, ui: { ...uploaded.ui, libraryFinalsPhase: "top_ten_reached" as const } };
    expect(selectFeatureAccess(ranked).libraryRecovery).toBe(true);
  });

  it("switches to chapter three only after the 022 dialogue", () => {
    const initial = createInitialGameState();
    const state = {
      ...initial,
      actOne: { ...initial.actOne, phase: "complete" as const },
      ui: {
        ...initial.ui,
        libraryFinalsPhase: "friend_contacted" as const,
        libraryFinalsPuzzle: {
          ...initial.ui.libraryFinalsPuzzle,
          nextQuestId: "chapter_three_book_hunt" as const
        }
      }
    };
    expect(selectFeatureAccess(state)).toMatchObject({ chapter: "chapter_three", bikeArcade: true });
    expect(canEnterScene(state, "bike_arcade")).toBe(true);
  });
});
