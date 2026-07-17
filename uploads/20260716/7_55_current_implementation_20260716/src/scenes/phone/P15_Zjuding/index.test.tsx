import { act, fireEvent, render, screen } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { EventBus } from "../../../core/EventBus";
import { createGameStore, createInitialGameState, gameStore } from "../../../core/GameState";
import { SceneRouter } from "../../../core/SceneRouter";
import type { GameState, LibraryFinalsPhase } from "../../../core/types";
import actOneContent from "../../../data/act-one-bootstrap.content.json";
import { ZjudingScene } from ".";

function stateAt(phase: LibraryFinalsPhase): GameState {
  const state = createInitialGameState();
  return {
    ...state,
    currentScene: "zjuding",
    networkMode: "campus_wifi",
    actOne: { ...state.actOne, phase: "complete", inventoryRecovered: true },
    ui: {
      ...state.ui,
      zjudingPage: "library_seat",
      librarySelectedSeat: "022",
      libraryFinalsPhase: phase
    }
  };
}

function renderReady(state: GameState) {
  const events = new EventBus();
  const router = new SceneRouter(createGameStore(state), events);
  const view = render(<ZjudingScene state={state} router={router} events={events} />);
  act(() => {
    vi.advanceTimersByTime(1500);
  });
  return view;
}

describe("ZjudingScene library finals", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.restoreAllMocks();
  });

  it("does not render retired direct-recovery controls", () => {
    const retiredPhase = ["guide", "found"].join("_") as LibraryFinalsPhase;
    const { container } = renderReady(stateAt(retiredPhase));

    expect(container.querySelector(".library-finals-action.recover")).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: "立即预约" })).not.toBeInTheDocument();
    expect(screen.queryByLabelText("预约日期与时段")).not.toBeInTheDocument();
    expect(screen.getByRole("button", { name: "馆藏检索" })).toBeInTheDocument();
  });

  it("renders locked hub apps as framed icons without names, focus, or the blue banner", () => {
    const initial = createInitialGameState();
    const state: GameState = {
      ...initial,
      currentScene: "zjuding",
      ui: { ...initial.ui, zjudingPage: "hub" }
    };
    const { container } = renderReady(state);
    const grid = screen.getByLabelText("浙大钉应用");
    const lockedCloud = container.querySelector('[data-locked-app="智云课堂"]');

    expect(lockedCloud).toBeInTheDocument();
    expect(lockedCloud).toHaveAttribute("aria-hidden", "true");
    expect(lockedCloud).not.toHaveAttribute("tabindex");
    expect(lockedCloud?.querySelector(".zju-pixel-icon")).toBeInTheDocument();
    expect(lockedCloud?.querySelector(".zju-pixel-icon")).toHaveTextContent("云");
    expect(grid).not.toHaveTextContent("xxx");
    expect(screen.queryByText("智云课堂")).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: "部门黄页" })).not.toBeInTheDocument();
    expect(container.querySelector('[data-locked-app="部门黄页"] span')).toHaveTextContent("☎");
    expect(container.querySelector('[data-ui-part="assistant-banner"]')).not.toBeInTheDocument();
    expect(container.querySelectorAll('[data-locked-icon^="hub-nav-"]')).toHaveLength(5);
  });

  it("opens the three-item profile menu from the avatar and exits to the phone home", () => {
    const initial = createInitialGameState();
    const state: GameState = {
      ...initial,
      currentScene: "zjuding",
      networkMode: "campus_wifi",
      ui: { ...initial.ui, zjudingPage: "hub" }
    };
    const events = new EventBus();
    const store = createGameStore(state);
    const router = new SceneRouter(store, events);

    render(<ZjudingScene state={state} router={router} events={events} />);
    act(() => {
      vi.advanceTimersByTime(1500);
    });

    fireEvent.click(screen.getByRole("button", { name: "打开个人菜单" }));

    const menu = screen.getByRole("dialog", { name: "个人菜单" });
    const actions = Array.from(menu.querySelectorAll(".zju-sheet-actions button"))
      .map((button) => button.textContent?.trim())
      .filter(Boolean);
    expect(actions).toEqual(["个人资料", "账号与安全", "退出浙大钉"]);

    fireEvent.click(screen.getByRole("button", { name: "退出浙大钉" }));
    expect(router.getCurrentScene()).toBe("phone_home");
  });

  it("keeps locked library services as icon frames and reveals no service name", () => {
    const state = stateAt("idle");
    state.ui.zjudingPage = "library";
    const { container } = renderReady(state);
    const services = screen.getByLabelText("图书馆服务");
    const borrowing = container.querySelector('[data-locked-app="借阅信息"]');

    expect(borrowing).toBeInTheDocument();
    expect(borrowing).toHaveAttribute("aria-hidden", "true");
    expect(borrowing).not.toHaveAttribute("tabindex");
    expect(borrowing?.querySelector(".zju-library-service-icon")).toHaveTextContent("阅");
    expect(services).not.toHaveTextContent("xxx");
    expect(screen.queryByRole("button", { name: "借阅信息" })).not.toBeInTheDocument();
    expect(container.querySelector('[data-locked-app="022恢复申请"] .zju-library-service-icon')).toHaveTextContent("PASS");
  });

  it("shows an issued PASS in the recovery form without restoring 022 on the phone", () => {
    const state = stateAt("pass_ready");
    state.ui.zjudingPage = "library_recovery";
    state.ui.libraryFinalsPuzzle.evictionPassGenerated = true;
    renderReady(state);

    expect(screen.getByLabelText("022座位恢复申请")).toBeInTheDocument();
    expect(screen.getAllByText("PASS").length).toBeGreaterThan(0);
    expect(screen.queryByText("拖动左上角 PASS 到 022 座位")).not.toBeInTheDocument();
  });

  it("submits all three owned proofs and generates the seat 022 release PASS", () => {
    const state = stateAt("recovery_application");
    state.ui.zjudingPage = "library_recovery";
    state.items.bagNonPersonProof = true;
    state.items.seat022Receipt = true;
    state.items.libraryPresenceProof = true;
    gameStore.setState(() => state);

    const events = new EventBus();
    const router = new SceneRouter(gameStore, events);
    const view = render(<ZjudingScene state={state} router={router} events={events} />);
    act(() => {
      vi.advanceTimersByTime(1500);
    });

    for (const button of screen.getAllByRole("button", { name: "提交" })) {
      fireEvent.click(button);
    }

    expect(gameStore.getState().ui.libraryFinalsPuzzle.recoverySubmittedEvidenceIds).toEqual([
      "bag_non_person_proof",
      "seat_022_receipt",
      "library_presence_proof"
    ]);

    view.rerender(<ZjudingScene state={gameStore.getState()} router={router} events={events} />);
    fireEvent.click(screen.getByRole("button", { name: "生成 022 座位释放 PASS" }));

    expect(gameStore.getState().ui.libraryFinalsPuzzle.evictionPassGenerated).toBe(true);
    expect(gameStore.getState().items.seatReleasePass).toBe(true);
  });

  it("shows all five supplied catalog covers and advances only on the correct book", () => {
    const state = stateAt("evidence_gathering");
    state.ui.zjudingPage = "library_catalog";
    state.ui.libraryFinalsPuzzle.investigationOpened = true;
    gameStore.setState(() => state);
    renderReady(state);

    fireEvent.change(screen.getByRole("textbox", { name: "馆藏检索关键词" }), {
      target: { value: "三分钟离座法" }
    });
    fireEvent.click(screen.getByRole("button", { name: "搜索" }));

    expect(screen.getByLabelText("馆藏检索结果")).toBeInTheDocument();
    expect(screen.getAllByRole("button", { name: /选择馆藏/ })).toHaveLength(5);
    expect(screen.getByAltText("三分钟离座法及其例外封面")).toBeInTheDocument();
    expect(screen.getByAltText("三分钟离席法与若干例外封面")).toBeInTheDocument();
    expect(screen.getByAltText("三分钟暂离法及其应用封面")).toBeInTheDocument();
    expect(screen.getByAltText("三分钟起身法与边界情况封面")).toBeInTheDocument();
    expect(screen.getByAltText("三分钟空座法及其解释封面")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "选择馆藏三分钟暂离法及其应用" }));
    expect(gameStore.getState().items.callNumber755).toBe(false);
    expect(screen.getByText(/没有可核对的关系/)).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "选择馆藏三分钟离座法及其例外" }));
    expect(gameStore.getState().items.callNumber755).toBe(true);
    expect(screen.getByText("已获得线索：索书号 I247.55 / 755。")).toBeInTheDocument();
  });

  it("searches catalog titles before the story clue is synchronized without advancing the puzzle", () => {
    const state = stateAt("evidence_gathering");
    state.ui.zjudingPage = "library_catalog";
    state.ui.libraryFinalsPuzzle.investigationOpened = false;
    gameStore.setState(() => state);
    renderReady(state);

    fireEvent.change(screen.getByRole("textbox", { name: "馆藏检索关键词" }), {
      target: { value: "三分钟" }
    });
    fireEvent.click(screen.getByRole("button", { name: "搜索" }));

    expect(screen.getAllByRole("button", { name: /选择馆藏/ })).toHaveLength(5);
    expect(screen.getByText("检索到的书籍数：5")).toBeInTheDocument();
    expect(gameStore.getState().ui.libraryFinalsPuzzle.catalogSearchCompleted).toBe(false);

    fireEvent.click(screen.getByRole("button", { name: "选择馆藏三分钟离座法及其例外" }));
    expect(gameStore.getState().items.callNumber755).toBe(false);
    expect(screen.getByText(/题名提示还没有完成核对/)).toBeInTheDocument();
  });

  it("filters ordinary catalog terms and reports an empty search", () => {
    const state = stateAt("evidence_gathering");
    state.ui.zjudingPage = "library_catalog";
    renderReady(state);
    const input = screen.getByRole("textbox", { name: "馆藏检索关键词" });

    fireEvent.change(input, { target: { value: "离席" } });
    fireEvent.click(screen.getByRole("button", { name: "搜索" }));
    expect(screen.getAllByRole("button", { name: /选择馆藏/ })).toHaveLength(1);
    expect(screen.getByText("检索到的书籍数：1")).toBeInTheDocument();

    fireEvent.change(input, { target: { value: "不存在的馆藏" } });
    fireEvent.click(screen.getByRole("button", { name: "搜索" }));
    expect(screen.getByLabelText("无检索结果")).toBeInTheDocument();
    expect(screen.getByText("检索到的书籍数：0")).toBeInTheDocument();
    expect(screen.getByText(/没有找到与“不存在的馆藏”相符的馆藏/)).toBeInTheDocument();
  });

  it("keeps catalog search dominant and uses real advanced-search fields", () => {
    const state = stateAt("evidence_gathering");
    state.ui.zjudingPage = "library_catalog";
    renderReady(state);

    expect(screen.getByRole("textbox", { name: "馆藏检索关键词" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "搜索" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /检索字段\s+书名/ })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /馆藏范围\s+全部馆藏/ })).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "高级检索" }));
    expect(screen.getByLabelText("高级检索字段")).toHaveTextContent("题名匹配");
    expect(screen.getByLabelText("高级检索字段")).toHaveTextContent("索书号分类");
    expect(screen.getByLabelText("高级检索字段")).toHaveTextContent("馆藏地点");
    expect(screen.queryByText("书脊情绪")).not.toBeInTheDocument();
  });

  it("shows each recovery proof source, readiness, and next action", () => {
    const state = stateAt("recovery_application");
    state.ui.zjudingPage = "library_recovery";
    state.items.seat022Receipt = true;
    renderReady(state);

    const form = screen.getByLabelText("恢复证明槽位");
    expect(form).toHaveTextContent("失物招领 · 身份登记机");
    expect(form).toHaveTextContent("二层南区 · 022 桌面夹缝");
    expect(form).toHaveTextContent("浙大体艺 · 到馆记录补录");
    expect(form).toHaveTextContent("可提交");
    expect(form).toHaveTextContent("待取得");
    expect(screen.getByLabelText("恢复材料进度 0/3")).toBeInTheDocument();
  });

  it("sanitizes an old seat-reservation route to the simplified library home", () => {
    const state = stateAt("occupied_seat_found");
    state.ui.libraryFinalsPuzzle.backpackInspected = true;
    renderReady(state);

    expect(screen.getByLabelText("浙大移动图书馆")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "返回现场" })).toBeInTheDocument();
    expect(screen.queryByLabelText("预约日期与时段")).not.toBeInTheDocument();
    expect(screen.queryByLabelText("022调查状态")).not.toBeInTheDocument();
  });

  it("accepts the authored full title with book-title punctuation", () => {
    const state = stateAt("evidence_gathering");
    state.ui.zjudingPage = "library_catalog";
    state.ui.libraryFinalsPuzzle.investigationOpened = true;
    gameStore.setState(() => state);
    renderReady(state);

    fireEvent.change(screen.getByRole("textbox", { name: "馆藏检索关键词" }), {
      target: { value: "《 三分钟离座法及其例外 》" }
    });
    fireEvent.click(screen.getByRole("button", { name: "搜索" }));

    expect(gameStore.getState().ui.libraryFinalsPuzzle.catalogSearchCompleted).toBe(true);
    expect(screen.getAllByRole("button", { name: /选择馆藏/ })).toHaveLength(5);
  });

  it("moves the red system circle out for the inventory request", () => {
    const initial = createInitialGameState();
    gameStore.setState(() => ({
      ...initial,
      currentScene: "zjuding",
      flags: { ...initial.flags, checkinDone: true },
      actOne: { ...initial.actOne, phase: "system_required", dormHubUnlocked: true }
    }));
    const events = new EventBus();
    const router = new SceneRouter(gameStore, events);
    render(<ZjudingScene state={gameStore.getState()} router={router} events={events} />);
    act(() => vi.advanceTimersByTime(1500));

    fireEvent.click(screen.getByRole("button", { name: "系统红圈" }));
    expect(screen.getByRole("dialog", { name: "系统对话" })).toBeInTheDocument();
    expect(screen.getByText(actOneContent.audioNarration.act2_system_found_intro.subtitleZh)).toBeInTheDocument();
    for (let index = 0; index < 5; index += 1) {
      fireEvent.click(screen.getByRole("button", { name: "继续对话" }));
    }

    expect(gameStore.getState().actOne.phase).toBe("inventory_required");
  });

  it("opens the dorm RPG from the first-chapter campus-map task", () => {
    const initial = createInitialGameState();
    gameStore.setState(() => ({
      ...initial,
      currentScene: "zjuding",
      flags: { ...initial.flags, codeScattered: true }
    }));
    const events = new EventBus();
    const router = new SceneRouter(gameStore, events);
    render(<ZjudingScene state={gameStore.getState()} router={router} events={events} />);
    act(() => vi.advanceTimersByTime(1500));

    fireEvent.click(screen.getByRole("button", { name: "校园地图" }));

    expect(gameStore.getState()).toMatchObject({
      runtimeMode: "rpg",
      rpgScene: "dorm_hub",
      actOne: { phase: "prologue", inventoryRecovered: false }
    });
  });

  it("ends the returning system dialogue at the movement quest", () => {
    const initial = createInitialGameState();
    gameStore.setState(() => ({
      ...initial,
      currentScene: "zjuding",
      flags: { ...initial.flags, checkinDone: true },
      items: { ...initial.items, campusCard: true },
      actOne: {
        ...initial.actOne,
        phase: "system_return_required",
        inventoryRecovered: true,
        dormHubUnlocked: true
      }
    }));
    const events = new EventBus();
    const router = new SceneRouter(gameStore, events);
    render(<ZjudingScene state={gameStore.getState()} router={router} events={events} />);
    act(() => vi.advanceTimersByTime(1500));

    fireEvent.click(screen.getByRole("button", { name: "系统红圈" }));
    for (let index = 0; index < 6; index += 1) {
      fireEvent.click(screen.getByRole("button", { name: "继续对话" }));
    }

    expect(gameStore.getState().actOne.phase).toBe("movement_required");
  });

  it("uses the campus card acquired in chapter one and skips the repeated chest task", () => {
    const initial = createInitialGameState();
    gameStore.setState(() => ({
      ...initial,
      currentScene: "zjuding",
      flags: { ...initial.flags, checkinDone: true },
      items: { ...initial.items, campusCard: true },
      actOne: {
        ...initial.actOne,
        phase: "system_required",
        inventoryRecovered: true,
        dormHubUnlocked: true
      }
    }));
    const events = new EventBus();
    const router = new SceneRouter(gameStore, events);
    render(<ZjudingScene state={gameStore.getState()} router={router} events={events} />);
    act(() => vi.advanceTimersByTime(1500));

    fireEvent.click(screen.getByRole("button", { name: "系统红圈" }));
    fireEvent.click(screen.getByRole("button", { name: "继续对话" }));
    fireEvent.click(screen.getByRole("button", { name: "继续对话" }));
    expect(screen.getByText(actOneContent.audioNarration.act2_system_inventory_demand.subtitleZh)).toBeInTheDocument();
    expect(screen.queryByText(actOneContent.audioNarration.act2_system_inventory_missing.subtitleZh)).not.toBeInTheDocument();
    for (let index = 0; index < 7; index += 1) {
      fireEvent.click(screen.getByRole("button", { name: "继续对话" }));
    }

    expect(gameStore.getState().actOne.phase).toBe("movement_required");
    expect(gameStore.getState().items.campusCard).toBe(true);
    expect(gameStore.getState().actOne.inventoryRecovered).toBe(true);
  });

  it("reveals the directory identity clue in three steps without filling the answer", () => {
    const initial = createInitialGameState();
    const state: GameState = {
      ...initial,
      currentScene: "zjuding",
      networkMode: "campus_wifi",
      items: { ...initial.items, campusCard: true },
      actOne: {
        ...initial.actOne,
        phase: "movement_required",
        inventoryRecovered: true,
        dormHubUnlocked: true
      },
      ui: { ...initial.ui, zjudingPage: "directory" }
    };
    gameStore.setState(() => state);
    const events = new EventBus();
    const router = new SceneRouter(gameStore, events);
    render(<ZjudingScene state={state} router={router} events={events} />);
    act(() => vi.advanceTimersByTime(1500));

    const reader = screen.getByRole("button", { name: "校园卡读卡区" });
    fireEvent.click(reader);
    fireEvent.click(reader);
    fireEvent.click(reader);

    expect(events.getHistory()).toEqual(expect.arrayContaining([
      { name: "act2_directory_hint_advanced", payload: { step: 1 } },
      { name: "act2_directory_hint_advanced", payload: { step: 2 } },
      { name: "act2_directory_hint_advanced", payload: { step: 3 } }
    ]));
    expect(screen.getByRole("textbox", { name: "姓名" })).toHaveValue("");
    expect(screen.getByRole("textbox", { name: "学号" })).toHaveValue("");
  });

  it("reads the campus card into the directory and still requires the player to place the call", () => {
    const initial = createInitialGameState();
    const state: GameState = {
      ...initial,
      currentScene: "zjuding",
      networkMode: "campus_wifi",
      items: { ...initial.items, campusCard: true },
      actOne: {
        ...initial.actOne,
        phase: "movement_required",
        inventoryRecovered: true,
        dormHubUnlocked: true
      },
      ui: { ...initial.ui, zjudingPage: "directory" }
    };
    gameStore.setState(() => state);
    const events = new EventBus();
    const router = new SceneRouter(gameStore, events);
    render(<ZjudingScene state={state} router={router} events={events} />);
    act(() => vi.advanceTimersByTime(1500));

    act(() => {
      events.emit("item_dropped", { item: "campusCard", target: "directory_identity" });
      vi.advanceTimersByTime(650);
    });

    expect(screen.getByRole("textbox", { name: "姓名" })).toHaveValue(actOneContent.studentName);
    expect(screen.getByRole("textbox", { name: "学号" })).toHaveValue(actOneContent.studentId);
    expect(screen.getByText("电子校园卡已读取")).toBeInTheDocument();
    expect(gameStore.getState().actOne.characterNamed).toBe(false);

    fireEvent.click(screen.getByRole("button", { name: "☎ 呼叫" }));
    expect(gameStore.getState().actOne.characterNamed).toBe(true);
  });

  it("reads a selected campus card by tapping the reader without requiring drag support", () => {
    const initial = createInitialGameState();
    const state: GameState = {
      ...initial,
      currentScene: "zjuding",
      networkMode: "campus_wifi",
      items: { ...initial.items, campusCard: true },
      actOne: {
        ...initial.actOne,
        phase: "movement_required",
        inventoryRecovered: false,
        dormHubUnlocked: true
      },
      ui: { ...initial.ui, zjudingPage: "directory", selectedItem: "campusCard" }
    };
    gameStore.setState(() => state);
    const events = new EventBus();
    const router = new SceneRouter(gameStore, events);
    render(<ZjudingScene state={state} router={router} events={events} />);
    act(() => vi.advanceTimersByTime(1500));

    expect(screen.getByText("校园卡已对准，点击读取")).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "校园卡读卡区" }));
    act(() => vi.advanceTimersByTime(650));

    expect(screen.getByRole("textbox", { name: "姓名" })).toHaveValue(actOneContent.studentName);
    expect(screen.getByRole("textbox", { name: "学号" })).toHaveValue(actOneContent.studentId);
    expect(screen.getByText("电子校园卡已读取")).toBeInTheDocument();
  });

  it("restores the canonical directory identity when reopening the page after a successful call", () => {
    const initial = createInitialGameState();
    const state: GameState = {
      ...initial,
      currentScene: "zjuding",
      networkMode: "campus_wifi",
      items: { ...initial.items, campusCard: true },
      actOne: {
        ...initial.actOne,
        phase: "movement_required",
        inventoryRecovered: true,
        characterNamed: true,
        identityVerified: true
      },
      ui: { ...initial.ui, zjudingPage: "directory" }
    };
    gameStore.setState(() => state);
    const events = new EventBus();
    const router = new SceneRouter(gameStore, events);
    render(<ZjudingScene state={state} router={router} events={events} />);
    act(() => vi.advanceTimersByTime(1500));

    expect(screen.getByRole("textbox", { name: "姓名" })).toHaveValue(actOneContent.studentName);
    expect(screen.getByRole("textbox", { name: "学号" })).toHaveValue(actOneContent.studentId);
    expect(screen.getByRole("button", { name: `已联络：${actOneContent.studentName}` })).toBeInTheDocument();
  });

  it("uses the same canonical student number on the library profile", () => {
    const state = stateAt("idle");
    state.ui.zjudingPage = "library";
    renderReady(state);

    expect(screen.getByText(actOneContent.studentId, { exact: false })).toBeInTheDocument();
    expect(screen.queryByText("3250102741", { exact: false })).not.toBeInTheDocument();
  });
});
