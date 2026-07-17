import { act, fireEvent, render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { App } from "./App";
import { createInitialGameState, gameStore } from "./core/GameState";

const rpgHostMock = vi.hoisted(() => ({ props: null as null | { keyboardBlocked?: boolean } }));

vi.mock("./scenes/rpg/RpgGameHost", () => ({
  RpgGameHost: (props: { keyboardBlocked?: boolean }) => {
    rpgHostMock.props = props;
    return <main role="application" aria-label="mock RPG runtime"><canvas /></main>;
  }
}));

function installMatchMedia(matches: boolean) {
  Object.defineProperty(window, "matchMedia", {
    configurable: true,
    writable: true,
    value: vi.fn().mockImplementation((query: string) => ({
      matches,
      media: query,
      onchange: null,
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      addListener: vi.fn(),
      removeListener: vi.fn(),
      dispatchEvent: vi.fn()
    }))
  });
}

describe("App", () => {
  beforeEach(() => {
    installMatchMedia(false);
    rpgHostMock.props = null;
    gameStore.setState(() => createInitialGameState());
  });

  it("renders the phone scene shell by default", () => {
    render(<App />);

    expect(screen.getByRole("application", { name: "7:55 phone runtime" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "开始游戏" })).toBeInTheDocument();
  });

  it("keeps one phone, one RPG canvas and one shared task bar in desktop split mode", async () => {
    installMatchMedia(true);
    gameStore.setState((state) => ({
      ...state,
      runtimeMode: "rpg",
      currentScene: "phone_home",
      actOne: { ...state.actOne, phase: "complete", inventoryRecovered: true },
      ui: { ...state.ui, seenChapterIntros: ["chapter_two"] }
    }));

    const { container } = render(<App />);

    expect(await screen.findByLabelText("手机交互区")).toBeInTheDocument();
    expect(screen.getByLabelText("地图交互区")).toBeInTheDocument();
    expect(screen.getAllByRole("region", { name: "当前任务" })).toHaveLength(1);
    expect(container.querySelectorAll(".phone-frame")).toHaveLength(1);
    await waitFor(() => expect(container.querySelectorAll("canvas")).toHaveLength(1));
    expect(rpgHostMock.props?.keyboardBlocked).toBe(false);

    fireEvent.pointerDown(screen.getByLabelText("手机交互区"));
    await waitFor(() => expect(rpgHostMock.props?.keyboardBlocked).toBe(true));
    fireEvent.pointerDown(screen.getByLabelText("地图交互区"));
    await waitFor(() => expect(rpgHostMock.props?.keyboardBlocked).toBe(false));
  });

  it("plays through the opening: alarm → wake → home → wechat scatter", async () => {
    const user = userEvent.setup();
    render(<App />);

    await user.click(screen.getByRole("button", { name: "开始游戏" }));
    await user.click(screen.getByRole("button", { name: "关闭" }));

    expect(screen.getByText("……再睡5分钟……")).toBeInTheDocument();
    expect(screen.getByText("旁白：你没有5分钟了，但你很有勇气")).toBeInTheDocument();

    await user.click(screen.getByRole("button", { name: "……再睡5分钟……" }));
    expect(screen.getByRole("heading", { name: /起床蠢货/ })).toBeInTheDocument();

    await user.click(screen.getByRole("button", { name: "进入手机主界面" }));
    expect(screen.getByRole("button", { name: "微信" })).toBeInTheDocument();

    await user.click(screen.getByRole("button", { name: "微信" }));
    expect(screen.getByRole("button", { name: "打开朋友聊天" })).toBeInTheDocument();

    await user.click(screen.getByRole("button", { name: "打开朋友聊天" }));

    // 第一章获得首个道具后显示；旧存档缺失物品栏时仍会暂时隐藏。
    await waitFor(() => expect(gameStore.getState().flags.codeScattered).toBe(true), { timeout: 14000 });
    act(() => gameStore.setState((s) => ({ ...s, items: { ...s.items, slashLine: true } })));
    expect(screen.getByRole("complementary", { name: "物品栏" })).toBeInTheDocument();
    act(() => gameStore.setState((s) => ({
      ...s,
      actOne: { ...s.actOne, phase: "inventory_required", inventoryRecovered: false }
    })));
    await waitFor(() => expect(screen.queryByRole("complementary", { name: "物品栏" })).not.toBeInTheDocument());
    act(() => gameStore.setState((s) => ({
      ...s,
      actOne: { ...s.actOne, phase: "movement_required", inventoryRecovered: true }
    })));
    await waitFor(() => expect(screen.getByRole("complementary", { name: "物品栏" })).toBeInTheDocument());
  }, 18000);

  it("opens the friend chat from the delayed home notification", async () => {
    const user = userEvent.setup();
    render(<App />);

    await user.click(screen.getByRole("button", { name: "开始游戏" }));
    await user.click(screen.getByRole("button", { name: "关闭" }));
    await user.click(screen.getByRole("button", { name: "……再睡5分钟……" }));
    await user.click(screen.getByRole("button", { name: "进入手机主界面" }));

    const notice = await screen.findByRole("button", { name: "朋友发来的微信消息" }, { timeout: 1800 });
    await user.click(notice);

    expect(screen.getByRole("heading", { name: "朋友" })).toBeInTheDocument();
  });

  it("collects d1 from the campus card yellow zero", async () => {
    const user = userEvent.setup();
    gameStore.setState((s) => ({
      ...s,
      currentScene: "campus_card",
      items: { ...s.items, campusCard: true },
      flags: { ...s.flags, codeScattered: true },
      actOne: { ...s.actOne, inventoryRecovered: true }
    }));
    render(<App />);

    await user.click(screen.getByRole("button", { name: "黄色的零" }));

    expect(gameStore.getState().digits.d1).toBe("0");
    expect(gameStore.getState().flags.cardZeroTaken).toBe(true);
    expect(await screen.findByText("余额暂时不足以购买尊严")).toBeInTheDocument();
  });

  it("does not collect the yellow zero before the dorm table grants the campus card", async () => {
    const user = userEvent.setup();
    gameStore.setState((state) => ({
      ...state,
      currentScene: "campus_card",
      flags: { ...state.flags, codeScattered: true }
    }));
    render(<App />);

    await user.click(screen.getByRole("button", { name: "黄色的零" }));

    expect(gameStore.getState().digits.d1).toBeNull();
    expect(gameStore.getState().flags.cardZeroTaken).toBe(false);
    expect(await screen.findByText(/先去浙大钉的校园地图，拿到寝室右侧书桌上的校园卡。/)).toBeInTheDocument();
  });

  it("shows the backpack for an older save that owns items even when inventoryRecovered is missing", () => {
    gameStore.setState((state) => ({
      ...state,
      currentScene: "phone_home",
      items: { ...state.items, reverseGear: true },
      actOne: { ...state.actOne, phase: "complete", inventoryRecovered: false }
    }));

    render(<App />);

    expect(screen.getByRole("button", { name: "展开物品栏" })).toBeInTheDocument();
  });

  it("switches network from the control center and gates zjuding", async () => {
    const user = userEvent.setup();
    gameStore.setState((s) => ({
      ...s,
      currentScene: "phone_home",
      flags: { ...s.flags, codeScattered: true }
    }));
    render(<App />);

    await user.click(screen.getByRole("button", { name: "打开控制中心" }));
    await user.click(screen.getByRole("button", { name: /移动数据/ }));
    expect(gameStore.getState().networkMode).toBe("cellular");

    await user.click(screen.getByRole("button", { name: "关闭控制中心" }));
    await user.click(screen.getByRole("button", { name: "浙大钉" }));

    // 流量下卡在加载页
    expect(await screen.findByLabelText("浙大钉加载中")).toBeInTheDocument();
  });

  it("keeps the bike arcade hidden when seat recovery has not explicitly unlocked it", () => {
    gameStore.setState((state) => ({
      ...state,
      currentScene: "phone_home",
      bikeArcade: { ...state.bikeArcade, unlocked: false },
      ui: { ...state.ui, libraryFinalsPhase: "seat_recovered" }
    }));
    render(<App />);

    expect(screen.queryByRole("button", { name: "游戏" })).not.toBeInTheDocument();
    expect(gameStore.getState().currentScene).toBe("phone_home");
  });

  it("opens the standalone bike arcade only after an explicit later-chapter unlock", async () => {
    const user = userEvent.setup();
    gameStore.setState((state) => ({
      ...state,
      currentScene: "phone_home",
      bikeArcade: { ...state.bikeArcade, unlocked: true },
      ui: { ...state.ui, libraryFinalsPhase: "seat_recovered" }
    }));
    render(<App />);

    await user.click(await screen.findByRole("button", { name: "游戏" }));

    expect(gameStore.getState().currentScene).toBe("bike_arcade");
    expect(screen.getByRole("heading", { name: "求是潮 755" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "开始骑行" })).toBeInTheDocument();

    await user.click(screen.getByRole("button", { name: "退出求是潮 755，返回手机桌面" }));
    expect(gameStore.getState().currentScene).toBe("phone_home");
  });

  it("renders a stable next-chapter exit after the bike chapter", async () => {
    gameStore.setState((state) => ({
      ...state,
      currentScene: "chapter_transition",
      bikeArcade: {
        unlocked: true,
        completed: true,
        attemptCount: 2,
        bestDistance: 755,
        bestLives: 2
      },
      ui: { ...state.ui, libraryFinalsPhase: "friend_contacted" }
    }));

    render(<App />);

    expect(screen.getByRole("heading", { name: "下一章" })).toBeInTheDocument();
    expect(screen.getByText("755m")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "返回手机桌面" })).toBeInTheDocument();
    expect(screen.queryByRole("status")).toBeNull();
  });

  it("offers manual save and a two-step story reset in control center", async () => {
    const user = userEvent.setup();
    gameStore.setState((state) => ({
      ...state,
      currentScene: "phone_home",
      items: { ...state.items, reverseGear: true }
    }));
    render(<App />);

    await user.click(screen.getByRole("button", { name: "打开控制中心" }));
    expect(screen.getByLabelText("存档管理")).toBeInTheDocument();
    await user.click(screen.getByRole("button", { name: "立即保存" }));
    await user.click(screen.getByRole("button", { name: "重置剧情进度" }));
    expect(screen.getByRole("alert")).toHaveTextContent("将清除章节、道具和谜题进度");
    await user.click(screen.getByRole("button", { name: "确认重置" }));

    expect(gameStore.getState().currentScene).toBe("alarm");
    expect(Object.values(gameStore.getState().items).some(Boolean)).toBe(false);
    expect(screen.getByRole("button", { name: "开始游戏" })).toBeInTheDocument();
  });

  it("opens only the useful library controls after chapter-two movement completes", async () => {
    const user = userEvent.setup();
    gameStore.setState((state) => ({
      ...state,
      currentScene: "zjuding",
      networkMode: "campus_wifi",
      actOne: { ...state.actOne, phase: "complete", inventoryRecovered: true },
      ui: { ...state.ui, seenChapterIntros: ["chapter_two"] }
    }));
    render(<App />);

    expect(screen.getByLabelText("浙大钉加载中")).toBeInTheDocument();
    expect(await screen.findByLabelText("浙大钉首页", {}, { timeout: 2500 })).toBeInTheDocument();

    await user.click(screen.getByRole("button", { name: "学在浙大" }));
    expect(screen.getByLabelText("学在浙大")).toBeInTheDocument();
    await user.click(screen.getByRole("button", { name: "返回浙大钉" }));

    await user.click(screen.getByRole("button", { name: "图书馆" }));
    expect(screen.getByLabelText("浙大移动图书馆")).toBeInTheDocument();

    expect(screen.getByRole("button", { name: "馆藏检索" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "返回现场" })).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: "座位预约" })).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: "立即预约" })).not.toBeInTheDocument();

    await user.click(screen.getByRole("button", { name: "馆藏检索" }));
    expect(screen.getByLabelText("图书馆馆藏检索")).toBeInTheDocument();
  }, 7000);
});
