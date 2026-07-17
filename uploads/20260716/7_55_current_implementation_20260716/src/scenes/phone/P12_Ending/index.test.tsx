import { act, fireEvent, render, screen } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { eventBus } from "../../../core/EventBus";
import { createInitialGameState, gameStore } from "../../../core/GameState";
import { SceneRouter } from "../../../core/SceneRouter";
import actOneContent from "../../../data/act-one-bootstrap.content.json";
import { EndingScene } from ".";

describe("EndingScene", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    eventBus.clearHistory();
    gameStore.setState(() => ({
      ...createInitialGameState(),
      currentScene: "ending",
      digits: { d1: "0", d2: "7", d3: "9", d4: "8" },
      flags: { ...createInitialGameState().flags, checkinDone: true, flowerBloomed: true }
    }));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("holds seven seconds of black before the narrator tries to leave", () => {
    const router = new SceneRouter(gameStore, eventBus);
    render(<EndingScene state={gameStore.getState()} router={router} events={eventBus} />);

    expect(screen.getByLabelText("黑屏")).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: "按住旁白圆圈" })).not.toBeInTheDocument();
    act(() => vi.advanceTimersByTime(6999));
    expect(screen.queryByRole("button", { name: "按住旁白圆圈" })).not.toBeInTheDocument();
    act(() => vi.advanceTimersByTime(1));

    expect(screen.getByRole("button", { name: "按住旁白圆圈" })).toBeInTheDocument();
    expect(screen.getByText("制止它")).toBeInTheDocument();
    expect(screen.getByText(actOneContent.audioNarration.prologue_narrator_intro.subtitleZh)).toBeInTheDocument();
    expect(eventBus.getHistory()).toContainEqual({ name: "prologue_narrator_intro" });
  });

  it("requires a sustained hold, plays the exchange, and returns to the unlocked phone home", () => {
    const router = new SceneRouter(gameStore, eventBus);
    render(<EndingScene state={gameStore.getState()} router={router} events={eventBus} />);
    act(() => vi.advanceTimersByTime(7000));
    const orb = screen.getByRole("button", { name: "按住旁白圆圈" });

    fireEvent.pointerDown(orb, { pointerId: 1 });
    act(() => vi.advanceTimersByTime(899));
    fireEvent.pointerUp(orb, { pointerId: 1 });
    expect(screen.getByText("制止它")).toBeInTheDocument();

    fireEvent.pointerDown(orb, { pointerId: 2 });
    act(() => vi.advanceTimersByTime(900));
    expect(screen.getByText(actOneContent.audioNarration.prologue_narrator_caught.subtitleZh)).toBeInTheDocument();

    act(() => vi.advanceTimersByTime(2500));
    expect(screen.getByText("不，除非你帮助我")).toBeInTheDocument();
    act(() => vi.advanceTimersByTime(3600));
    expect(screen.getByText(actOneContent.audioNarration.prologue_narrator_bargain.subtitleZh)).toBeInTheDocument();
    act(() => vi.advanceTimersByTime(7900));
    expect(screen.getByLabelText("序章结算")).toHaveClass("ending-burst");
    act(() => vi.advanceTimersByTime(950));
    expect(screen.getByLabelText("白屏闪退")).toBeInTheDocument();
    act(() => vi.advanceTimersByTime(700));

    expect(gameStore.getState()).toMatchObject({
      runtimeMode: "phone",
      currentScene: "phone_home",
      digits: { d1: "0", d2: "7", d3: "9", d4: "8" },
      flags: { checkinDone: true, flowerBloomed: true },
      actOne: { phase: "friend_message_required", dormHubUnlocked: true }
    });
    expect(eventBus.getHistory()).toEqual(expect.arrayContaining([
      { name: "prologue_narrator_caught" },
      { name: "prologue_narrator_bargain" },
      { name: "prologue_white_burst" },
      { name: "prologue_narrator_released" },
      { name: "act2_entry_unlocked", payload: { entry: "phone_home" } }
    ]));
  });
});
