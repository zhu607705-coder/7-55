import { act, fireEvent, render, screen } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { EventBus } from "../../../core/EventBus";
import { createGameStore, createInitialGameState } from "../../../core/GameState";
import { SceneRouter } from "../../../core/SceneRouter";
import type { GameState, LibraryFinalsPhase } from "../../../core/types";
import { kit } from "../../../modules/GameKit";
import { TiyiScene } from ".";

function stateAt(
  phase: LibraryFinalsPhase,
  puzzlePatch: Partial<GameState["ui"]["libraryFinalsPuzzle"]> = {}
): GameState {
  const state = createInitialGameState();
  return {
    ...state,
    currentScene: "tiyi",
    ui: {
      ...state.ui,
      libraryFinalsPhase: phase,
      libraryFinalsPuzzle: { ...state.ui.libraryFinalsPuzzle, ...puzzlePatch }
    }
  };
}

function renderMain(state: GameState) {
  const events = new EventBus();
  const router = new SceneRouter(createGameStore(state), events);
  const view = render(<TiyiScene state={state} router={router} events={events} />);
  act(() => {
    vi.advanceTimersByTime(1400);
  });
  return view;
}

describe("TiyiScene", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.spyOn(kit.network, "canOpenTiyi").mockReturnValue(true);
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.restoreAllMocks();
  });

  it("does not render the retired route prompt", () => {
    const retiredPhase = ["pass", "validated"].join("_") as LibraryFinalsPhase;
    const { container } = renderMain(stateAt(retiredPhase));

    expect(screen.getByRole("button", { name: "运动打卡次数 47" })).toBeInTheDocument();
    expect(container.querySelector(".tiyi-finals-route")).not.toBeInTheDocument();
  });

  it("keeps the first-chapter digit and exercise entry", () => {
    const initial = stateAt("idle");
    const state: GameState = {
      ...initial,
      actOne: {
        ...initial.actOne,
        phase: "movement_required"
      }
    };

    renderMain(state);

    expect(screen.getByRole("button", { name: "运动打卡次数 47" })).toBeInTheDocument();
    expect(screen.getByRole("status", { name: "课外锻炼状态" })).toHaveTextContent("等待开始锻炼");
    expect(screen.getByRole("button", { name: "开始课外锻炼" })).toBeInTheDocument();
  });

  it("starts exercise only from the authored blue-button hotspot", () => {
    const initial = stateAt("idle");
    const state: GameState = {
      ...initial,
      actOne: {
        ...initial.actOne,
        phase: "movement_required",
        characterNamed: true
      }
    };
    const startExercise = vi.spyOn(kit.actOne, "startExercise").mockReturnValue(true);

    renderMain(state);

    expect(screen.getByRole("status", { name: "课外锻炼状态" })).toHaveTextContent(
      "参加者已确认，可以开始课外锻炼"
    );
    fireEvent.click(screen.getByRole("status", { name: "课外锻炼状态" }));
    expect(startExercise).not.toHaveBeenCalled();

    fireEvent.click(screen.getByRole("button", { name: "开始课外锻炼" }));
    expect(startExercise).toHaveBeenCalledTimes(1);
  });

  it("keeps the running message as display-only status after exercise starts", () => {
    const initial = stateAt("idle");
    const state: GameState = {
      ...initial,
      actOne: {
        ...initial.actOne,
        phase: "movement_required",
        characterNamed: true,
        exerciseStarted: true
      }
    };

    renderMain(state);

    const status = screen.getByRole("status", { name: "课外锻炼状态" });
    expect(status).toHaveTextContent("锻炼进行中");
    expect(status).toHaveTextContent("小人正在寝室里来回走动");
    expect(status.tagName).toBe("SECTION");
    expect(screen.getByRole("button", { name: "开始课外锻炼" })).toBeInTheDocument();
  });

  it("opens the V2 presence form after the CC98 investigation is established", () => {
    renderMain(stateAt("evidence_gathering", { investigationOpened: true }));

    expect(screen.getByRole("region", { name: "本人来过证明补录单" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "提交补录" })).toBeInTheDocument();
    expect(screen.queryByLabelText("求是潮路线验证")).not.toBeInTheDocument();
  });
});
