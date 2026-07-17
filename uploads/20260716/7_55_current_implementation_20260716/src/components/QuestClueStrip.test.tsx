import { fireEvent, render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, describe, expect, it, vi } from "vitest";
import { EventBus } from "../core/EventBus";
import { createGameStore, createInitialGameState } from "../core/GameState";
import { SceneRouter } from "../core/SceneRouter";
import type { GameState, LibraryFinalsPhase, LibraryFinalsPuzzleState, SceneId } from "../core/types";
import { PhoneShell } from "./PhoneShell";
import { QuestTaskBar } from "./QuestClueStrip";

function createLibraryState({
  phase = "evidence_gathering",
  scene = "phone_home",
  puzzle = {}
}: {
  phase?: LibraryFinalsPhase;
  scene?: SceneId;
  puzzle?: Partial<LibraryFinalsPuzzleState>;
} = {}): GameState {
  const state = createInitialGameState();
  return {
    ...state,
    currentScene: scene,
    actOne: {
      ...state.actOne,
      phase: "complete",
      inventoryRecovered: true,
      manualControlTested: true,
      canLeaveDorm: true
    },
    ui: {
      ...state.ui,
      libraryFinalsPhase: phase,
      libraryFinalsPuzzle: { ...state.ui.libraryFinalsPuzzle, ...puzzle }
    }
  };
}

function renderShell(state: GameState) {
  const events = new EventBus();
  const store = createGameStore(state);
  const router = new SceneRouter(store, events);
  return {
    ...render(
      <PhoneShell state={state} router={router} events={events}>
        <div>scene</div>
      </PhoneShell>
    ),
    events,
    store,
    router
  };
}

describe("QuestTaskBar", () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("shows one first-chapter objective and numeric progress before later features unlock", () => {
    renderShell({ ...createInitialGameState(), currentScene: "phone_home" });

    const task = screen.getByRole("region", { name: "当前任务" });
    expect(task).toHaveAttribute("data-quest-id", "chapter_one_checkin");
    expect(within(task).getByRole("button", { name: /第 1 章.*查看朋友发来的新消息.*0\/7/ })).toBeInTheDocument();
  });

  it("shows found digits in their original positions on the task trigger and drawer", async () => {
    const user = userEvent.setup();
    const state = createInitialGameState();
    state.currentScene = "phone_home";
    state.flags.codeScattered = true;
    state.digits = { d1: "0", d2: null, d3: "9", d4: null };
    renderShell(state);

    const triggerHint = screen.getByLabelText(/已找到的签到数字/);
    expect(triggerHint).toHaveTextContent("签到码 0 ? 9 ?");

    await user.click(screen.getByRole("button", { name: /签到数字提示：0 \? 9 \?/ }));

    const hints = screen.getAllByLabelText(/已找到的签到数字/);
    expect(hints).toHaveLength(2);
    const slots = within(hints[1]).getAllByText(/^[0798?]$/);
    expect(slots.map((slot) => slot.textContent)).toEqual(["0", "?", "9", "?"]);
    expect(within(hints[1]).getByText("2 / 4")).toBeInTheDocument();
  });

  it("opens a complete task drawer from the task button", async () => {
    const user = userEvent.setup();
    renderShell(createLibraryState({
      puzzle: { entranceRecordRead: true, backpackInspected: true, occupancyNoteCollected: true }
    }));

    await user.click(screen.getByRole("button", { name: /第 2 章.*用纸条查找公开记录/ }));

    const drawer = screen.getByRole("region", { name: "当前任务" });
    expect(within(drawer).getByRole("heading", { name: "恢复 022 座位" })).toBeInTheDocument();
    expect(within(drawer).getByText("当前任务")).toBeInTheDocument();
    expect(within(drawer).getByText("当前进度")).toBeInTheDocument();
    expect(within(drawer.querySelector(".quest-task-overview") as HTMLElement).getByText("3 / 16")).toBeInTheDocument();
    expect(within(drawer).getByLabelText("任务步骤")).toBeInTheDocument();
    expect(within(drawer).getByLabelText("渐进提示")).toBeInTheDocument();
    expect(within(drawer).getByRole("button", { name: "前往相关界面" })).toBeInTheDocument();
  });

  it("supports Enter and Space through the native task control", async () => {
    const user = userEvent.setup();
    renderShell(createLibraryState());
    const trigger = screen.getByRole("button", { name: /第 2 章/ });

    trigger.focus();
    await user.keyboard("{Enter}");
    expect(screen.getByLabelText("任务详情")).toBeInTheDocument();
    await user.keyboard(" ");
    expect(screen.queryByLabelText("任务详情")).not.toBeInTheDocument();
  });

  it("keeps pointer activation inside the task control", async () => {
    const user = userEvent.setup();
    const parentClick = vi.fn();
    const state = createLibraryState();
    const events = new EventBus();
    render(
      <div onClick={parentClick}>
        <QuestTaskBar state={state} events={events} />
      </div>
    );

    await user.click(screen.getByRole("button", { name: /第 2 章任务/ }));

    expect(screen.getByLabelText("任务详情")).toBeInTheDocument();
    expect(parentClick).not.toHaveBeenCalled();
  });

  it("reveals exactly three non-answer hints one at a time", async () => {
    const user = userEvent.setup();
    renderShell(createLibraryState());
    await user.click(screen.getByRole("button", { name: /第 2 章/ }));

    const hints = screen.getByLabelText("渐进提示");
    const next = within(hints).getByRole("button", { name: "显示下一条提示" });
    await user.click(next);
    await user.click(next);
    await user.click(next);

    expect(within(hints).getByText("3/3")).toBeInTheDocument();
    expect(within(hints).getAllByText(/^[123]$/)).toHaveLength(3);
    expect(next).toBeDisabled();
    expect(hints).not.toHaveTextContent("7 / 47 / 3");
  });

  it("navigates to the recommended surface without advancing puzzle facts", async () => {
    const user = userEvent.setup();
    const state = createLibraryState({
      puzzle: { entranceRecordRead: true, backpackInspected: true, occupancyNoteCollected: true }
    });
    const { store, events } = renderShell(state);
    await user.click(screen.getByRole("button", { name: /第 2 章/ }));
    await user.click(screen.getByRole("button", { name: "前往相关界面" }));

    expect(store.getState().currentScene).toBe("cc98");
    expect(store.getState().ui.libraryFinalsPuzzle).toEqual(state.ui.libraryFinalsPuzzle);
    expect(events.getHistory()).toContainEqual({
      name: "quest_navigation_requested",
      payload: {
        questId: "chapter_two_library",
        targetSurface: "phone",
        recommendedScene: "cc98"
      }
    });
  });

  it("keeps completed paper materials readable after their inventory item is consumed", async () => {
    const user = userEvent.setup();
    const state = createLibraryState({
      puzzle: {
        entranceRecordRead: true,
        backpackInspected: true,
        occupancyNoteCollected: true,
        callNumberCollected: true,
        archivedRuleCollected: true
      }
    });
    state.items.archivedLeaveRule = false;
    renderShell(state);

    await user.click(screen.getByRole("button", { name: /第 2 章/ }));
    const ruleStep = screen.getByText("取得旧版规则").closest("li");
    await user.click(within(ruleStep as HTMLElement).getByRole("button", { name: "查看材料" }));

    expect(screen.getByRole("dialog", { name: "旧离座规定" })).toHaveTextContent("同时具备三类证明");
  });

  it("renders the same quest id and progress on phone and RPG surfaces", () => {
    const state = createLibraryState({ puzzle: { entranceRecordRead: true, backpackInspected: true } });
    const events = new EventBus();
    const { container } = render(
      <>
        <QuestTaskBar state={state} events={events} variant="phone" />
        <QuestTaskBar state={state} events={events} variant="rpg" />
      </>
    );

    const bars = container.querySelectorAll<HTMLElement>("[data-quest-id='chapter_two_library']");
    expect(bars).toHaveLength(2);
    expect(bars[0].textContent).toBe(bars[1].textContent);
  });

  it("switches to the third chapter after the 022 dialogue", () => {
    renderShell(createLibraryState({
      phase: "friend_contacted",
      puzzle: { nextQuestId: "chapter_three_book_hunt" }
    }));

    const task = screen.getByRole("region", { name: "当前任务" });
    expect(task).toHaveAttribute("data-quest-id", "chapter_three_book_hunt");
    expect(task).toHaveTextContent("打开求是潮，追上那本书");
  });

  it("stays hidden in bare opening and ending scenes", () => {
    const { rerender } = renderShell(createInitialGameState());
    expect(screen.queryByRole("region", { name: "当前任务" })).not.toBeInTheDocument();

    for (const scene of ["desktop", "ending"] as SceneId[]) {
      const state = { ...createInitialGameState(), currentScene: scene };
      const events = new EventBus();
      const store = createGameStore(state);
      rerender(
        <PhoneShell state={state} router={new SceneRouter(store, events)} events={events}>
          <div>scene</div>
        </PhoneShell>
      );
      expect(screen.queryByRole("region", { name: "当前任务" })).not.toBeInTheDocument();
    }
  });

  it("does not install legacy global PASS drag listeners", () => {
    const addEventListener = vi.spyOn(window, "addEventListener");
    renderShell(createLibraryState({ phase: "pass_ready" }));

    const pointerRegistrations = addEventListener.mock.calls.filter(([eventName]) =>
      ["pointermove", "pointerup", "pointercancel"].includes(String(eventName))
    );
    expect(pointerRegistrations).toEqual([]);
  });

  it("closes the drawer without changing the current quest", () => {
    renderShell(createLibraryState());
    const trigger = screen.getByRole("button", { name: /第 2 章/ });
    fireEvent.click(trigger);
    fireEvent.click(screen.getByRole("button", { name: "关闭任务详情" }));
    expect(screen.queryByLabelText("任务详情")).not.toBeInTheDocument();
    expect(screen.getByRole("region", { name: "当前任务" })).toHaveAttribute("data-quest-id", "chapter_two_library");
  });
});
