import React from "react";
import ReactDOM from "react-dom/client";
import { App } from "./App";
import { ErrorBoundary } from "./ErrorBoundary";
import { eventBus } from "./core/EventBus";
import { selectFeatureAccess } from "./core/FeatureAccess";
import { gameStore } from "./core/GameState";
import { selectQuestViewModel } from "./core/QuestModel";
import type { GameState } from "./core/types";
import { applyDeveloperCheckpointFromUrl } from "./modules/DeveloperChannel";
import { getPresentationRuntimeSnapshot } from "./modules/PresentationRuntime";
import { getBikeArcadeSnapshot } from "./scenes/phone/P16_BikeArcade/BikeArcadeRuntime";
import { getRpgRuntimeDebugState } from "./scenes/rpg/RpgRuntimeDebug";
import "@fontsource/fusion-pixel-12px-proportional-sc";
import "./styles.css";

function summarizeGameState(state: GameState) {
  const puzzle = state.ui.libraryFinalsPuzzle;
  const featureAccess = selectFeatureAccess(state);
  const quest = selectQuestViewModel(state);
  const desktopShell = document.querySelector<HTMLElement>(".desktop-gameplay-shell");
  return {
    coordinateSystem: "DOM viewport coordinates, origin at top-left, x right, y down",
    runtimeMode: state.runtimeMode,
    rpgScene: state.rpgScene,
    rpgCheckpoint: state.rpgCheckpoint,
    currentScene: state.currentScene,
    chapter: featureAccess.chapter,
    quest: {
      id: quest.id,
      title: quest.title,
      objective: quest.objective,
      completed: quest.completed,
      total: quest.total,
      targetSurface: quest.targetSurface,
      recommendedScene: quest.recommendedScene
    },
    featureAccess,
    desktopGameplay: {
      enabled: desktopShell !== null,
      activeSurface: desktopShell?.dataset.activeSurface ?? (state.runtimeMode === "rpg" ? "rpg" : "phone"),
      phoneShellCount: document.querySelectorAll(".phone-frame").length,
      phaserCanvasCount: document.querySelectorAll("canvas").length
    },
    networkMode: state.networkMode,
    digits: state.digits,
    ownedItems: Object.entries(state.items)
      .filter(([, owned]) => owned)
      .map(([item]) => item),
    itemStates: state.items,
    flags: {
      codeScattered: state.flags.codeScattered,
      towerOpened: state.flags.towerOpened,
      flowerBloomed: state.flags.flowerBloomed,
      checkinDone: state.flags.checkinDone
    },
    actOne: state.actOne,
    bikeArcadeChapter: state.bikeArcade,
    presentation: getPresentationRuntimeSnapshot(),
    rpgRuntime: getRpgRuntimeDebugState(),
    bikeArcade: getBikeArcadeSnapshot(),
    ui: {
      inventoryOpen: state.ui.inventoryOpen,
      selectedItem: state.ui.selectedItem,
      controlCenterOpen: state.ui.controlCenterOpen,
      brightness: state.ui.brightness,
      zjudingPage: state.ui.zjudingPage,
      librarySelectedSeat: state.ui.librarySelectedSeat,
      librarySeatReserved: state.ui.librarySeatReserved,
      libraryFinalsPhase: state.ui.libraryFinalsPhase,
      libraryFinalsPuzzle: {
        libraryVisitedPoints: puzzle.libraryVisitedPoints,
        entranceRecordRead: puzzle.entranceRecordRead,
        backpackInspected: puzzle.backpackInspected,
        occupancyNoteCollected: puzzle.occupancyNoteCollected,
        investigationOpened: puzzle.investigationOpened,
        optionalAc01Floors: puzzle.optionalAc01Floors,
        catalogSearchCompleted: puzzle.catalogSearchCompleted,
        callNumberCollected: puzzle.callNumberCollected,
        archivedRuleCollected: puzzle.archivedRuleCollected,
        photoDimmed: puzzle.photoDimmed,
        itemReportGenerated: puzzle.itemReportGenerated,
        nonPersonProofStamped: puzzle.nonPersonProofStamped,
        seatReceiptCollected: puzzle.seatReceiptCollected,
        audit: {
          attemptCount: puzzle.auditAttemptCount,
          arrivalMinutes: puzzle.auditArrivalMinutes,
          publicNoticeFloor: puzzle.auditPublicNoticeFloor,
          proofCount: puzzle.auditProofCount
        },
        presenceProofCollected: puzzle.presenceProofCollected,
        cc98UploadedEvidenceIds: puzzle.cc98UploadedEvidenceIds,
        bdCount: puzzle.bdCount,
        appliedBdReplyIds: puzzle.appliedBdReplyIds,
        recoverySubmittedEvidenceIds: puzzle.recoverySubmittedEvidenceIds,
        evictionPassGenerated: puzzle.evictionPassGenerated,
        backpackEvicted: puzzle.backpackEvicted,
        playerSeated: puzzle.playerSeated,
        nextQuestId: puzzle.nextQuestId,
        clueIds: puzzle.clueIds
      }
    }
  };
}

window.render_game_to_text = () => JSON.stringify(summarizeGameState(gameStore.getState()));
applyDeveloperCheckpointFromUrl(gameStore, window.location);

if (import.meta.env.DEV) {
  (window as unknown as Record<string, unknown>).__game = { store: gameStore, bus: eventBus };
}

ReactDOM.createRoot(document.getElementById("root") as HTMLElement).render(
  <React.StrictMode>
    <ErrorBoundary>
      <App />
    </ErrorBoundary>
  </React.StrictMode>
);
