import { describe, expect, it } from "vitest";
import { createGameStore, createPersistentGameStore } from "../core/GameState";
import {
  applyDeveloperCheckpoint,
  applyDeveloperCheckpointFromUrl,
  createDeveloperCheckpointState,
  getDeveloperCc98Mode,
  restoreDeveloperBackup
} from "./DeveloperChannel";

describe("DeveloperChannel", () => {
  it("creates consistent granular chapter checkpoints", () => {
    const pass = createDeveloperCheckpointState("c2-pass");
    expect(pass.ui.libraryFinalsPhase).toBe("pass_ready");
    expect(pass.items.seatReleasePass).toBe(true);
    expect(pass.rpgCheckpoint).toBe("library_seat_022");

    const sprint = createDeveloperCheckpointState("c3-sprint");
    expect(sprint.currentScene).toBe("bike_arcade");
    expect(sprint.bikeArcade.unlocked).toBe(true);
    expect(sprint.ui.libraryFinalsPhase).toBe("friend_contacted");

    const gate = createDeveloperCheckpointState("c2-library-gate");
    expect(gate.runtimeMode).toBe("rpg");
    expect(gate.rpgScene).toBe("campus_bootstrap");
    expect(gate.rpgCheckpoint).toBe("campus_library_gate");

    const dormCard = createDeveloperCheckpointState("c1-dorm-card");
    expect(dormCard.runtimeMode).toBe("rpg");
    expect(dormCard.rpgScene).toBe("dorm_hub");
    expect(dormCard.items.campusCard).toBe(false);
    expect(dormCard.actOne.inventoryRecovered).toBe(false);

    const chapterTwo = createDeveloperCheckpointState("c2-friend");
    expect(chapterTwo.items.campusCard).toBe(true);
    expect(chapterTwo.actOne.inventoryRecovered).toBe(true);

    const arrival = createDeveloperCheckpointState("c2-seat-arrival");
    expect(arrival.ui.libraryFinalsPuzzle.entranceRecordRead).toBe(true);
    expect(arrival.ui.libraryFinalsPuzzle.backpackInspected).toBe(false);

    const note = createDeveloperCheckpointState("c2-occupancy-note");
    expect(note.ui.libraryFinalsPuzzle.backpackInspected).toBe(true);
    expect(note.ui.libraryFinalsPuzzle.occupancyNoteCollected).toBe(false);

    const chapterExit = createDeveloperCheckpointState("c2-chapter-exit");
    expect(chapterExit.ui.libraryFinalsPhase).toBe("friend_contacted");
    expect(chapterExit.ui.libraryFinalsPuzzle.nextQuestId).toBe("chapter_three_book_hunt");
    expect(chapterExit.bikeArcade.unlocked).toBe(true);
  });

  it("keeps legacy checkpoint URLs on the canonical state generator", () => {
    const store = createGameStore();
    window.sessionStorage.clear();
    const location = { search: "?devCheckpoint=c2-seat-022" } as Location;

    expect(applyDeveloperCheckpointFromUrl(store, location, window.sessionStorage)).toBe("c2-seat-arrival");
    expect(store.getState().rpgCheckpoint).toBe("library_seat_022");
    expect(store.getState().ui.libraryFinalsPuzzle.backpackInspected).toBe(false);
  });

  it("maps the retired chapter-two chest checkpoint to chapter one", () => {
    const store = createGameStore();
    window.sessionStorage.clear();
    const location = { search: "?devCheckpoint=c2-inventory" } as Location;

    expect(applyDeveloperCheckpointFromUrl(store, location, window.sessionStorage)).toBe("c1-dorm-card");
    expect(store.getState()).toMatchObject({
      runtimeMode: "rpg",
      rpgScene: "dorm_hub",
      items: { campusCard: false },
      actOne: { phase: "prologue", inventoryRecovered: false }
    });
  });

  it("opens the matching CC98 quest thread for granular checkpoints", () => {
    const store = createGameStore();
    window.sessionStorage.clear();

    applyDeveloperCheckpoint(store, "c2-gamepad-market", window.sessionStorage);
    expect(getDeveloperCc98Mode(window.sessionStorage)).toBe("exchange");

    applyDeveloperCheckpoint(store, "c2-cc98-upload", window.sessionStorage);
    expect(getDeveloperCc98Mode(window.sessionStorage)).toBe("investigation");
  });

  it("backs up and restores the real save around a jump", () => {
    const store = createGameStore();
    store.setState((state) => ({ ...state, currentScene: "photos" }));
    const storage = window.sessionStorage;
    storage.clear();
    applyDeveloperCheckpoint(store, "c2-top-ten", storage);
    expect(store.getState().currentScene).toBe("cc98");
    expect(restoreDeveloperBackup(store, storage)).toBe(true);
    expect(store.getState().currentScene).toBe("photos");
  });

  it("does not overwrite the formal local save while a developer checkpoint is active", () => {
    window.localStorage.clear();
    window.sessionStorage.clear();
    const store = createPersistentGameStore(window.localStorage);
    store.setState((state) => ({ ...state, currentScene: "campus_card" }));
    applyDeveloperCheckpoint(store, "c2-top-ten", window.sessionStorage);

    expect(store.getState().currentScene).toBe("cc98");
    expect(createPersistentGameStore(window.localStorage).getState().currentScene).toBe("campus_card");
  });
});
