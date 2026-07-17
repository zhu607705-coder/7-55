import { eventBus } from "../core/EventBus";
import { gameStore } from "../core/GameState";
import { CheckinController } from "./CheckinController";
import { ActOneBootstrapController } from "./ActOneBootstrapController";
import { BikeArcadeChapterController } from "./BikeArcadeChapterController";
import { DigitCollector } from "./DigitCollector";
import { FlagController } from "./FlagController";
import { InventoryController } from "./InventoryController";
import { LibraryFinalsController } from "./LibraryFinalsController";
import { NetworkController } from "./NetworkController";
import { PlantController } from "./PlantController";
import { SaveController } from "./SaveController";

/**
 * 绑定在全局单例 store / eventBus 上的控制器束。
 * 场景组件统一从这里调剧情逻辑；单元测试可自行 new 各控制器。
 */
export const kit = {
  actOne: new ActOneBootstrapController(gameStore, eventBus),
  bikeArcade: new BikeArcadeChapterController(gameStore, eventBus),
  flags: new FlagController(gameStore, eventBus),
  inventory: new InventoryController(gameStore, eventBus),
  libraryFinals: new LibraryFinalsController(gameStore, eventBus),
  digits: new DigitCollector(gameStore, eventBus),
  network: new NetworkController(gameStore, eventBus),
  checkin: new CheckinController(gameStore, eventBus),
  plant: new PlantController(gameStore, eventBus),
  save: new SaveController(gameStore, eventBus)
};

export type GameKit = typeof kit;
