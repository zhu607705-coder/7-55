import type { EventBus } from "../core/EventBus";
import type { GameStore } from "../core/types";

/**
 * 第四章恢复回放控制器。画面只会在第三章半完成四项手机证据、确认目的地
 * 并主动播放后出现；启真湖结算不能直接越过取证流程。
 */
export class ChapterFourPrologueController {
  constructor(private readonly store: GameStore, private readonly events: EventBus) {}

  /** 恢复回放是否已由第三章半正式解锁。 */
  shouldPlayPrologue(): boolean {
    const state = this.store.getState();
    return state.qizhenLake.phase === "complete"
      && state.chapterThreeInterlude.phase === "replay_ready"
      && state.chapterThreeInterlude.replayUnlocked
      && !state.chapter4.prologueSeen;
  }

  /**
   * 过场结束：标记已看并进入 A1 门厅（第四章任务已随任务卡发布）。
   * 保留完整 GameState，绝不通过 createInitialGameState() 进入下一章。
   */
  completePrologue(): boolean {
    const state = this.store.getState();
    if (
      state.qizhenLake.phase !== "complete"
      || state.chapterThreeInterlude.phase !== "replay_ready"
      || !state.chapterThreeInterlude.replayUnlocked
      || state.chapter4.prologueSeen
    ) return false;
    this.store.setState((current) => ({
      ...current,
      runtimeMode: "rpg",
      rpgScene: "duan_yongping_temporal_maze",
      rpgCheckpoint: "c4_a1_lobby",
      ui: { ...current.ui, inventoryOpen: false, selectedItem: null },
      chapterThreeInterlude: {
        ...current.chapterThreeInterlude,
        phase: "complete",
        completed: true
      },
      chapter4: {
        ...current.chapter4,
        prologueSeen: true,
        phase: "arrival",
        cycle: 1,
        mode: "light",
        building: "A",
        floor: "A1",
        roomId: "a1_lobby",
        buildingTimeSeconds: 81900
      }
    }));
    this.events.emit("chapter4_prologue_completed", {
      scene: "duan_yongping_temporal_maze",
      checkpoint: "c4_a1_lobby"
    });
    return true;
  }
}
