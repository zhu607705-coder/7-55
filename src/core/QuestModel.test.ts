import { describe, expect, it } from "vitest";
import { createInitialGameState } from "./GameState";
import { selectQuestViewModel } from "./QuestModel";

describe("shared quest view model", () => {
  it("starts chapter one with one current objective and seven saved progress units", () => {
    const quest = selectQuestViewModel(createInitialGameState());
    expect(quest).toMatchObject({
      id: "chapter_one_checkin",
      chapter: "chapter_one",
      title: "找回签到码",
      objective: "查看朋友发来的新消息",
      completed: 0,
      total: 7,
      targetSurface: "phone",
      recommendedScene: "wechat"
    });
    expect(quest.steps.filter((step) => step.status === "active")).toHaveLength(1);
    expect(quest.hints).toHaveLength(3);
  });

  it("derives movement progress from controller-owned facts", () => {
    const initial = createInitialGameState();
    const state = {
      ...initial,
      actOne: {
        ...initial.actOne,
        phase: "movement_required" as const,
        inventoryRecovered: true,
        characterNamed: true,
        identityVerified: true,
        exerciseStarted: true
      }
    };
    const quest = selectQuestViewModel(state);
    expect(quest).toMatchObject({
      id: "chapter_two_movement",
      completed: 3,
      total: 8,
      objective: "拼出一个能移动对象的方向"
    });
  });

  it("uses the same library progress for phone and RPG surfaces", () => {
    const initial = createInitialGameState();
    const state = {
      ...initial,
      actOne: { ...initial.actOne, phase: "complete" as const },
      ui: {
        ...initial.ui,
        libraryFinalsPhase: "evidence_gathering" as const,
        libraryFinalsPuzzle: {
          ...initial.ui.libraryFinalsPuzzle,
          entranceRecordRead: true,
          backpackInspected: true,
          occupancyNoteCollected: true,
          investigationOpened: true,
          catalogSearchCompleted: true,
          callNumberCollected: true,
          archivedRuleCollected: true
        }
      }
    };
    const quest = selectQuestViewModel(state);
    expect(quest).toMatchObject({
      id: "chapter_two_library",
      title: "恢复 022 座位",
      completed: 5,
      total: 16,
      objective: "生成并盖章物品识别报告",
      targetSurface: "phone",
      recommendedScene: "photos"
    });
    expect(quest.steps.find((step) => step.id === "rule")?.itemId).toBe("archivedLeaveRule");
  });

  it("changes to the chapter-three book hunt after the 022 dialogue", () => {
    const initial = createInitialGameState();
    const state = {
      ...initial,
      actOne: { ...initial.actOne, phase: "complete" as const },
      ui: {
        ...initial.ui,
        libraryFinalsPhase: "friend_contacted" as const,
        libraryFinalsPuzzle: {
          ...initial.ui.libraryFinalsPuzzle,
          nextQuestId: "chapter_three_book_hunt" as const
        }
      },
      bikeArcade: { ...initial.bikeArcade, unlocked: true }
    };
    expect(selectQuestViewModel(state)).toMatchObject({
      id: "chapter_three_book_hunt",
      chapter: "chapter_three",
      recommendedScene: "bike_arcade"
    });
  });
});
