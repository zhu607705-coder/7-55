import type { EventBus } from "../core/EventBus";
import type { GameStore } from "../core/types";

/**
 * 第四章序幕「纸条进入段永平教学楼」控制器。
 * 过场本身是纯表现层；这里只负责在过场结束（播完或跳过后收下任务卡）时
 * 记录已看事实、发领域事件，并以已验证的 GameState 进入教学楼时间迷宫。
 */
export class ChapterFourPrologueController {
  constructor(private readonly store: GameStore, private readonly events: EventBus) {}

  /** 序幕是否应在启真湖 RPG 画布上播放。 */
  shouldPlayPrologue(): boolean {
    const state = this.store.getState();
    return state.qizhenLake.phase === "complete" && !state.chapter4.prologueSeen;
  }

  /**
   * 过场结束：标记已看并进入 A1 门厅（第四章任务已随任务卡发布）。
   * 保留完整 GameState，绝不通过 createInitialGameState() 进入下一章。
   */
  completePrologue(): boolean {
    const state = this.store.getState();
    if (state.qizhenLake.phase !== "complete" || state.chapter4.prologueSeen) return false;
    this.store.setState((current) => ({
      ...current,
      runtimeMode: "rpg",
      rpgScene: "duan_yongping_temporal_maze",
      rpgCheckpoint: "c4_a1_lobby",
      ui: { ...current.ui, inventoryOpen: false, selectedItem: null },
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
