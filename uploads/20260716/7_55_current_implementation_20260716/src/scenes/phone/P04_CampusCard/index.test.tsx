import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { EventBus } from "../../../core/EventBus";
import { createGameStore, createInitialGameState } from "../../../core/GameState";
import { SceneRouter } from "../../../core/SceneRouter";
import type { GameState, LibraryFinalsPhase } from "../../../core/types";
import { CampusCardScene } from ".";

function stateAt(phase: LibraryFinalsPhase): GameState {
  const state = createInitialGameState();
  return {
    ...state,
    currentScene: "campus_card",
    items: { ...state.items, campusCard: true },
    actOne: { ...state.actOne, inventoryRecovered: true },
    ui: {
      ...state.ui,
      libraryFinalsPhase: phase
    }
  };
}

function renderScene(state: GameState) {
  const events = new EventBus();
  const router = new SceneRouter(createGameStore(state), events);
  return render(<CampusCardScene state={state} router={router} events={events} />);
}

describe("CampusCardScene", () => {
  it("keeps the first-chapter balance puzzle during the V2 evidence flow", () => {
    const { container } = renderScene(stateAt("evidence_gathering"));

    expect(screen.getByRole("button", { name: "黄色的零" })).toBeInTheDocument();
    expect(screen.getByText("¥0.06")).toBeInTheDocument();
    expect(container.querySelector(".campus-card-quest")).not.toBeInTheDocument();
  });
});
