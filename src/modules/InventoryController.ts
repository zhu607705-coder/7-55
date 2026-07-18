import type { EventBus } from "../core/EventBus";
import type { GameStore, ItemId, SceneId } from "../core/types";

export interface CombineRecipe {
  a: ItemId;
  b: ItemId;
  result: ItemId;
  resultName: string;
}

/** 物品栏内拖拽合成表。具体关卡事实仍由控制器状态持久化。 */
export const COMBINE_RECIPES: CombineRecipe[] = [
  { a: "slashLine", b: "reverseGear", result: "towerKey", resultName: "钥匙" },
  { a: "waterDrop", b: "headphone", result: "wateredHeadphone", resultName: "盛水的耳机" },
  { a: "pushTriangle", b: "mentorLine", result: "rightArrow", resultName: "右移箭头" }
];

export class InventoryController {
  constructor(
    private readonly store: GameStore,
    private readonly events: EventBus
  ) {}

  addItem(itemId: ItemId, sourceScene: SceneId): void {
    this.store.setState((state) => ({
      ...state,
      items: {
        ...state.items,
        [itemId]: true
      }
    }));
    this.events.emit("get_item", { itemId, sourceScene });
  }

  removeItem(itemId: ItemId): void {
    this.store.setState((state) => ({
      ...state,
      items: {
        ...state.items,
        [itemId]: false
      }
    }));
  }

  hasItem(itemId: ItemId): boolean {
    return this.store.getState().items[itemId];
  }

  useItem(itemId: ItemId, targetId: string): boolean {
    if (!this.hasItem(itemId)) {
      return false;
    }

    this.events.emit("use_item", { itemId, targetId });
    return true;
  }

  /** 消耗道具（使用后从物品栏消失） */
  consumeItem(itemId: ItemId, targetId: string): boolean {
    if (!this.useItem(itemId, targetId)) {
      return false;
    }
    this.removeItem(itemId);
    return true;
  }

  /**
   * 物品栏拖拽合成。把 dragged 拖到 target 上；命中配方则移除两者、
   * 加入结果道具并广播 combine_item。返回结果 ItemId 或 null。
   */
  combine(dragged: ItemId, target: ItemId): ItemId | null {
    if (!this.hasItem(dragged) || !this.hasItem(target) || dragged === target) {
      return null;
    }

    const recipe = COMBINE_RECIPES.find(
      (r) => (r.a === dragged && r.b === target) || (r.a === target && r.b === dragged)
    );
    if (!recipe) {
      return null;
    }

    this.removeItem(dragged);
    this.removeItem(target);
    this.addItem(recipe.result, this.store.getState().currentScene);
    if (recipe.result === "rightArrow") {
      this.store.setState((state) => ({
        ...state,
        actOne: { ...state.actOne, rightArrowAssembled: true }
      }));
      this.events.emit("act2_right_arrow_assembled", { result: recipe.result });
    }
    this.events.emit("combine_item", { a: dragged, b: target, result: recipe.result });
    return recipe.result;
  }
}
