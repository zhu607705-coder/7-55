import { act, fireEvent, render, screen } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { eventBus } from "../../../core/EventBus";
import { createInitialGameState, gameStore } from "../../../core/GameState";
import { SceneRouter } from "../../../core/SceneRouter";
import { PhoneHomeScene } from ".";

describe("PhoneHomeScene chapter two entry", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    eventBus.clearHistory();
    gameStore.setState(() => {
      const state = createInitialGameState();
      return {
        ...state,
        currentScene: "phone_home",
        flags: { ...state.flags, codeScattered: false, checkinDone: true },
        actOne: { ...state.actOne, phase: "friend_message_required", dormHubUnlocked: true }
      };
    });
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("shows the new friend notification and replaces the lower push copy", () => {
    const router = new SceneRouter(gameStore, eventBus);
    render(<PhoneHomeScene state={gameStore.getState()} router={router} events={eventBus} />);

    expect(screen.queryByRole("button", { name: "朋友：成功了吗" })).not.toBeInTheDocument();
    act(() => vi.advanceTimersByTime(900));

    expect(screen.getByRole("button", { name: "朋友：成功了吗" })).toBeInTheDocument();
    act(() => vi.advanceTimersByTime(1600));
    expect(screen.getByRole("button", { name: "朋友：成功了吗" })).toBeInTheDocument();
    expect(screen.getByText("签到记录未更新。你本人仍未抵达。")).toBeInTheDocument();
    expect(screen.getByText("校园地图、图书馆和 CC98 已恢复访问。")).toBeInTheDocument();
  });

  it("opens ZJU Ding from the first-chapter dorm-location notification", () => {
    const state = createInitialGameState();
    gameStore.setState(() => ({
      ...state,
      currentScene: "phone_home",
      flags: { ...state.flags, codeScattered: true }
    }));
    const router = new SceneRouter(gameStore, eventBus);
    render(<PhoneHomeScene state={gameStore.getState()} router={router} events={eventBus} />);

    fireEvent.click(screen.getByRole("button", { name: "浙大钉：查看寝室定位" }));

    expect(gameStore.getState()).toMatchObject({
      currentScene: "zjuding",
      ui: { zjudingPage: "hub" }
    });
  });

  it("opens the weather page from the lower weather notification after weather unlocks", () => {
    const router = new SceneRouter(gameStore, eventBus);
    render(<PhoneHomeScene state={gameStore.getState()} router={router} events={eventBus} />);

    fireEvent.click(screen.getByRole("button", { name: "天气：小雨，局部黏着物可能松动" }));

    expect(gameStore.getState().currentScene).toBe("weather");
  });

  it("keeps locked app frames and icons while hiding names and interaction", () => {
    const state = createInitialGameState();
    gameStore.setState(() => ({ ...state, currentScene: "phone_home" }));
    const router = new SceneRouter(gameStore, eventBus);
    const { container } = render(<PhoneHomeScene state={gameStore.getState()} router={router} events={eventBus} />);

    for (const label of ["照片", "CC98", "游戏"]) {
      const slot = container.querySelector(`[data-locked-app="${label}"]`);
      expect(slot).toBeInTheDocument();
      expect(slot).toHaveAttribute("aria-hidden", "true");
      expect(slot).not.toHaveAttribute("tabindex");
      expect(slot?.querySelector(".app-icon")).toBeInTheDocument();
      expect(slot?.querySelector(".label")).not.toBeInTheDocument();
      expect(slot?.tagName).toBe("DIV");
    }

    expect(container.querySelector(".app-placeholder")).not.toBeInTheDocument();
  });
});
