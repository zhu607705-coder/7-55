import { act, fireEvent, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { EventBus } from "../../../core/EventBus";
import { createGameStore, createInitialGameState } from "../../../core/GameState";
import { SceneRouter } from "../../../core/SceneRouter";
import { DEVELOPER_ACTIVE_KEY } from "../../../core/StorageKeys";
import type { GameState } from "../../../core/types";
import defaultPostData from "../../../data/cc98.posts.json";
import libraryFinalsContent from "../../../data/library-finals.content.json";
import { kit } from "../../../modules/GameKit";
import { Cc98Scene } from ".";

const STORAGE_KEY = "seven-fifty-five.cc98-posts.v2";
const QUEST_STORAGE_KEY = "seven-fifty-five.cc98-quest-post-overrides.v1";
const INVESTIGATION_TITLE = libraryFinalsContent.cc98.post.title;
const INVESTIGATION_ID = libraryFinalsContent.cc98.post.id;
const ordinaryPost = defaultPostData[0];

function stateWithPuzzle(puzzle: Partial<GameState["ui"]["libraryFinalsPuzzle"]> = {}): GameState {
  const state = createInitialGameState();
  return {
    ...state,
    currentScene: "cc98",
    actOne: { ...state.actOne, phase: "complete", inventoryRecovered: true },
    ui: {
      ...state.ui,
      libraryFinalsPhase: "evidence_gathering",
      libraryFinalsPuzzle: { ...state.ui.libraryFinalsPuzzle, ...puzzle }
    }
  };
}

function renderScene(state: GameState) {
  const events = new EventBus();
  const store = createGameStore(state);
  const router = new SceneRouter(store, events);
  return render(<Cc98Scene state={state} router={router} events={events} />);
}

describe("Cc98Scene V2 library investigation", () => {
  beforeEach(() => {
    window.localStorage.clear();
    window.sessionStorage.clear();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("opens the 23-floor investigation from the collected occupancy note", () => {
    const openInvestigation = vi.spyOn(kit.libraryFinals, "openInvestigation").mockReturnValue(true);
    const state = stateWithPuzzle({ occupancyNoteCollected: true });
    state.items.occupancyNote = true;
    renderScene(state);

    fireEvent.click(screen.getByRole("button", { name: "搜索" }));
    expect(openInvestigation).toHaveBeenCalledTimes(1);
  });

  it("hides generic editing controls while retaining static icon-only chrome", () => {
    const { container } = renderScene(stateWithPuzzle());

    expect(screen.queryByRole("button", { name: "编辑帖子" })).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: "CC98更多菜单" })).not.toBeInTheDocument();
    expect(container.querySelector(".cc98-header-placeholder")).toHaveTextContent("•••");
    expect(container.querySelector(".cc98-header-placeholder")).toHaveAttribute("aria-hidden", "true");
    expect(container.querySelectorAll(".cc98-bottom-static [data-locked-icon]")).toHaveLength(5);
    expect(screen.getByLabelText("CC98主导航")).not.toHaveTextContent("xxx");
  });

  it("pins the investigation post without exposing uploads or bd before their gates", async () => {
    const user = userEvent.setup();
    renderScene(stateWithPuzzle({ occupancyNoteCollected: true, investigationOpened: true }));

    await user.click(screen.getByText(INVESTIGATION_TITLE));

    expect(screen.getByLabelText("022占座调查帖回复")).toBeInTheDocument();
    expect(screen.queryByLabelText("楼主证据上传区")).not.toBeInTheDocument();
    expect(screen.queryByLabelText("bd回复列表")).not.toBeInTheDocument();
    expect(screen.queryByAltText("CC98 bd 表情包")).not.toBeInTheDocument();
  });

  it("shows owner upload only after the rule and three proofs are ready", async () => {
    const user = userEvent.setup();
    const state = stateWithPuzzle({
      occupancyNoteCollected: true,
      investigationOpened: true,
      archivedRuleCollected: true,
      nonPersonProofStamped: true,
      seatReceiptCollected: true,
      presenceProofCollected: true
    });
    state.items.archivedLeaveRule = true;
    state.items.bagNonPersonProof = true;
    state.items.seat022Receipt = true;
    state.items.libraryPresenceProof = true;
    renderScene(state);

    await user.click(screen.getByText(INVESTIGATION_TITLE));
    expect(screen.getByLabelText("楼主证据上传区")).toBeInTheDocument();
    expect(screen.queryByLabelText("bd回复列表")).not.toBeInTheDocument();
    expect(screen.queryByAltText("CC98 bd 表情包")).not.toBeInTheDocument();
  });

  it("shows bd replies and the forum image only after all four uploads", async () => {
    const user = userEvent.setup();
    const state = stateWithPuzzle({
      occupancyNoteCollected: true,
      investigationOpened: true,
      archivedRuleCollected: true,
      nonPersonProofStamped: true,
      seatReceiptCollected: true,
      presenceProofCollected: true,
      cc98UploadedEvidenceIds: [
        "archived_leave_rule",
        "bag_non_person_proof",
        "seat_022_receipt",
        "library_presence_proof"
      ]
    });
    state.ui.libraryFinalsPhase = "top_ten_rising";
    renderScene(state);

    await user.click(screen.getByText(INVESTIGATION_TITLE));
    expect(screen.getByLabelText("bd回复列表")).toBeInTheDocument();
    expect(screen.getByAltText("CC98 bd 表情包")).toBeInTheDocument();
  });

  it("keeps editable ordinary posts on the existing forum-detail page", async () => {
    const user = userEvent.setup();
    renderScene(stateWithPuzzle());

    await user.click(screen.getByText(ordinaryPost.title));

    expect(screen.getByLabelText(`CC98帖子：${ordinaryPost.title}`)).toBeInTheDocument();
    expect(screen.getByText("晚八点打印机")).toBeInTheDocument();
    expect(screen.getByText("紫金港野生审核员")).toBeInTheDocument();
    expect(screen.queryByAltText("CC98 bd 表情包")).not.toBeInTheDocument();
  });

  it("keeps player-edited post copy while refreshing authored replies from defaults", async () => {
    const user = userEvent.setup();
    const savedPost = {
      ...ordinaryPost,
      title: "玩家保留的自定义标题",
      threadReplies: ordinaryPost.threadReplies.map((reply, index) => ({
        ...reply,
        text: `旧版本回复 ${index + 1}`
      }))
    };
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify([savedPost]));

    renderScene(stateWithPuzzle());
    await user.click(screen.getByText("玩家保留的自定义标题"));

    expect(screen.getByText(ordinaryPost.threadReplies[0].text)).toBeInTheDocument();
    expect(screen.queryByText("旧版本回复 1")).not.toBeInTheDocument();
  });

  it("prevents Space scrolling while opening a post from the keyboard", () => {
    renderScene(stateWithPuzzle());
    const post = screen.getByText(ordinaryPost.title).closest<HTMLElement>("[role='button']");
    const keydown = new KeyboardEvent("keydown", { key: " ", bubbles: true, cancelable: true });

    act(() => post?.dispatchEvent(keydown));

    expect(keydown.defaultPrevented).toBe(true);
    expect(screen.getByLabelText(`CC98帖子：${ordinaryPost.title}`)).toBeInTheDocument();
  });

  it("stores editable quest copy separately from ordinary post storage", async () => {
    const user = userEvent.setup();
    window.sessionStorage.setItem(DEVELOPER_ACTIVE_KEY, "c2-cc98-upload");
    renderScene(stateWithPuzzle({ occupancyNoteCollected: true, investigationOpened: true }));

    await user.click(screen.getByRole("button", { name: "编辑帖子" }));
    const questTitle = document.querySelector<HTMLElement>(".cc98-post.is-quest-post .cc98-title");
    expect(questTitle).not.toBeNull();
    if (!questTitle) return;
    questTitle.textContent = "待定的 022 调查帖";
    fireEvent.blur(questTitle);
    await user.click(screen.getByRole("button", { name: "保存帖子" }));

    const questSaved = JSON.parse(window.localStorage.getItem(QUEST_STORAGE_KEY) ?? "{}") as Record<string, { title?: string }>;
    const ordinarySaved = JSON.parse(window.localStorage.getItem(STORAGE_KEY) ?? "[]") as Array<{ id: string }>;
    expect(questSaved[INVESTIGATION_ID]?.title).toBe("待定的 022 调查帖");
    expect(ordinarySaved.some((post) => post.id === INVESTIGATION_ID)).toBe(false);
  });
});
