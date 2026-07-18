import { act, fireEvent, render, screen } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { eventBus } from "../../../core/EventBus";
import { createInitialGameState, gameStore } from "../../../core/GameState";
import { SceneRouter } from "../../../core/SceneRouter";
import { WechatScene } from ".";

describe("WechatScene second chapter handoff", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    eventBus.clearHistory();
    gameStore.setState(() => {
      const state = createInitialGameState();
      return {
        ...state,
        currentScene: "wechat",
        flags: { ...state.flags, codeScattered: true, checkinDone: true, slashTaken: true },
        actOne: { ...state.actOne, phase: "friend_message_required", dormHubUnlocked: true }
      };
    });
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("fills the player reply, receives the question mark, and updates the task", () => {
    const router = new SceneRouter(gameStore, eventBus);
    render(<WechatScene state={gameStore.getState()} router={router} events={eventBus} />);
    fireEvent.click(screen.getByRole("button", { name: "打开朋友聊天" }));

    expect(screen.getByText("成功了吗")).toBeInTheDocument();
    act(() => vi.advanceTimersByTime(700));
    expect(screen.getByText("没有，但我正试着威胁系统")).toBeInTheDocument();
    act(() => vi.advanceTimersByTime(850));
    expect(screen.getByText("？")).toBeInTheDocument();
    act(() => vi.advanceTimersByTime(600));

    expect(gameStore.getState().actOne.phase).toBe("system_required");
    expect(eventBus.getHistory()).toEqual(expect.arrayContaining([
      { name: "act2_friend_reply_filled" },
      { name: "act2_friend_exchange_completed" }
    ]));
  });

  it("uses exit semantics on the chat list and returns to the phone home", () => {
    const router = new SceneRouter(gameStore, eventBus);
    render(<WechatScene state={gameStore.getState()} router={router} events={eventBus} />);

    const exit = screen.getByRole("button", { name: "退出微信，返回手机主页" });
    expect(exit).toHaveAttribute("data-phone-nav", "exit");
    fireEvent.click(exit);
    expect(gameStore.getState().currentScene).toBe("phone_home");
  });

  it("uses back semantics inside a conversation without leaving WeChat", () => {
    const router = new SceneRouter(gameStore, eventBus);
    render(<WechatScene state={gameStore.getState()} router={router} events={eventBus} />);
    fireEvent.click(screen.getByRole("button", { name: "打开朋友聊天" }));

    const back = screen.getByRole("button", { name: "返回聊天列表" });
    expect(back).toHaveAttribute("data-phone-nav", "back");
    fireEvent.click(back);
    expect(screen.getByRole("button", { name: "退出微信，返回手机主页" })).toBeInTheDocument();
    expect(gameStore.getState().currentScene).toBe("wechat");
  });

  it("waits two seconds before allowing the first-chapter attack voice to be skipped", () => {
    gameStore.setState(() => {
      const state = createInitialGameState();
      return { ...state, currentScene: "wechat" };
    });
    const router = new SceneRouter(gameStore, eventBus);
    render(<WechatScene state={gameStore.getState()} router={router} events={eventBus} />);
    fireEvent.click(screen.getByRole("button", { name: "打开朋友聊天" }));

    act(() => vi.advanceTimersByTime(2000));
    expect(screen.getByText("等等等等，你想翘课？没门！")).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: "跳过小影语音" })).not.toBeInTheDocument();

    act(() => vi.advanceTimersByTime(1999));
    expect(screen.queryByRole("button", { name: "跳过小影语音" })).not.toBeInTheDocument();

    act(() => vi.advanceTimersByTime(1));
    fireEvent.click(screen.getByRole("button", { name: "跳过小影语音" }));

    expect(screen.getByText("找你的数字去吧哈哈哈")).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: "跳过小影语音" })).not.toBeInTheDocument();
  });

  it("reveals the stuck mentor-line clue across three inspections", () => {
    gameStore.setState((state) => ({
      ...state,
      actOne: {
        ...state.actOne,
        phase: "movement_required",
        inventoryRecovered: true,
        dormHubUnlocked: true
      }
    }));
    const router = new SceneRouter(gameStore, eventBus);
    render(<WechatScene state={gameStore.getState()} router={router} events={eventBus} />);

    const mentorAvatar = screen.getByRole("button", { name: "导师头像上的竖线" });
    expect(mentorAvatar).toHaveClass("is-stuck-target");
    fireEvent.click(mentorAvatar);
    expect(screen.getByText("两枚卡扣在发亮，中间的竖线还是拔不动。")).toBeInTheDocument();
    fireEvent.click(mentorAvatar);
    expect(screen.getByText("头像胶缝里似乎缺一点能流动的东西。")).toBeInTheDocument();
    fireEvent.click(mentorAvatar);

    expect(eventBus.getHistory()).toEqual(expect.arrayContaining([
      { name: "act2_mentor_hint_advanced", payload: { step: 1 } },
      { name: "act2_mentor_hint_advanced", payload: { step: 2 } },
      { name: "act2_mentor_hint_advanced", payload: { step: 3 } }
    ]));
  });

  it("releases the decorated mentor line only when weather water is dropped", () => {
    gameStore.setState((state) => ({
      ...state,
      items: { ...state.items, weatherWater: true },
      actOne: {
        ...state.actOne,
        phase: "movement_required",
        inventoryRecovered: true,
        dormHubUnlocked: true,
        weatherWaterTaken: true
      }
    }));
    const router = new SceneRouter(gameStore, eventBus);
    render(<WechatScene state={gameStore.getState()} router={router} events={eventBus} />);

    act(() => {
      eventBus.emit("item_dropped", { item: "weatherWater", target: "mentor_avatar" });
    });

    expect(gameStore.getState().items.weatherWater).toBe(false);
    expect(gameStore.getState().items.mentorLine).toBe(true);
    expect(gameStore.getState().actOne.mentorLineReleased).toBe(true);
    expect(screen.getByRole("button", { name: "导师头像上的竖线" })).toHaveClass("is-line-falling");
  });
});
