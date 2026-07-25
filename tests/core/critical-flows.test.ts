import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import { test } from "node:test";
import assert from "node:assert/strict";
import { EventBus } from "../../src/core/EventBus";
import { selectFeatureAccess } from "../../src/core/FeatureAccess";
import { createInitialGameState } from "../../src/core/GameState";
import { SaveStore } from "../../src/core/SaveStore";
import { GAME_SAVE_KEY } from "../../src/core/StorageKeys";
import type { GameState, GameStore } from "../../src/core/types";
import { BikeArcadeChapterController } from "../../src/modules/BikeArcadeChapterController";
import {
  CANTEEN_EXIT_SEQUENCE,
  CANTEEN_TARGET_TRAYS,
  ChapterThreeCanteenController
} from "../../src/modules/ChapterThreeCanteenController";
import {
  BIKE_ARCADE_GOAL,
  getCrossedBikeMilestones,
  isBikeObstacleWaveSolvable,
  moveBikeLane,
  planBikeObstacleWave,
  type BikeArcadeLane
} from "../../src/scenes/phone/P16_BikeArcade/BikeArcadeRules";

test("食堂控制器完成餐盘、点餐、取餐、封堵和自行车状态链", () => {
  const initial = createInitialGameState();
  initial.canteenHunt = {
    ...initial.canteenHunt,
    active: true,
    phase: "tray_search",
    mode: "light"
  };
  const store = createTestStore(initial);
  const events = new EventBus();
  const controller = new ChapterThreeCanteenController(store, events);

  assert.equal(controller.useTray(CANTEEN_TARGET_TRAYS[0]), "wrong_mode");
  assert.equal(store.getState().canteenHunt.returnedTrayIds.length, 0);

  assert.equal(controller.setMode("dark"), true);
  for (const trayId of CANTEEN_TARGET_TRAYS) {
    assert.equal(controller.useTray(trayId), "identified");
  }
  assert.deepEqual(store.getState().canteenHunt.identifiedTrayIds, [...CANTEEN_TARGET_TRAYS]);

  assert.equal(controller.setMode("light"), true);
  for (const trayId of CANTEEN_TARGET_TRAYS) {
    assert.equal(controller.useTray(trayId), "returned");
  }
  assert.equal(store.getState().canteenHunt.phase, "menu_order");
  assert.equal(store.getState().items.cafeteriaWages, true);
  assert.equal(store.getState().items.greaseTissue, true);

  assert.equal(controller.selectMenuOption("A"), "wrong");
  assert.equal(store.getState().canteenHunt.phase, "menu_order");
  assert.equal(controller.selectMenuOption("D"), "correct");
  assert.equal(store.getState().canteenHunt.phase, "pickup_search");
  assert.equal(store.getState().items.pickupTicket0755, true);

  assert.equal(controller.selectPickupWindow("1"), "wrong");
  assert.equal(store.getState().items.pickupTicket0755, true);
  assert.equal(controller.selectPickupWindow("3"), "correct");
  assert.equal(store.getState().canteenHunt.phase, "exit_blocking");
  assert.equal(store.getState().items.pickupTicket0755, false);

  assert.equal(controller.blockExit("west"), "wrong");
  assert.equal(store.getState().canteenHunt.blockHits, 0);
  CANTEEN_EXIT_SEQUENCE.forEach((exitId, index) => {
    const result = controller.blockExit(exitId);
    assert.equal(result, index === CANTEEN_EXIT_SEQUENCE.length - 1 ? "complete" : "correct");
  });
  assert.equal(store.getState().canteenHunt.phase, "chase_ready");

  assert.equal(controller.leaveCanteen(), true);
  assert.equal(store.getState().rpgScene, "campus_bootstrap");
  assert.equal(controller.inspectBikeLock(), "glare");

  assert.equal(controller.setMode("dark"), true);
  assert.equal(controller.inspectBikeLock(), "code_read");
  assert.equal(store.getState().canteenHunt.bikeCodeRead, true);
  assert.equal(controller.inspectBikeLock(), "dark_rejected");

  assert.equal(controller.setMode("light"), true);
  assert.equal(controller.cleanBikeLock(), "cleaned");
  assert.equal(store.getState().canteenHunt.bikeLockCleaned, true);
  assert.equal(controller.payForBike(), "paid");
  assert.equal(store.getState().canteenHunt.phase, "chasing");
  assert.equal(store.getState().items.cafeteriaWages, false);

  assert.equal(controller.completeChase(-3.2), true);
  assert.equal(store.getState().canteenHunt.active, false);
  assert.equal(store.getState().canteenHunt.phase, "tracking");
  assert.equal(store.getState().canteenHunt.chaseCollisions, 0);
  assert.equal(events.getHistory().some((event) => event.name === "canteen_chase_completed"), true);
});

test("Bike Arcade 规则保持换道边界、里程事件和障碍波可解", () => {
  assert.equal(moveBikeLane(0, -1), 0);
  assert.equal(moveBikeLane(2, 1), 2);
  assert.equal(moveBikeLane(1, -1), 0);
  assert.deepEqual(getCrossedBikeMilestones(180, 570), [188, 377, 566]);
  assert.deepEqual(getCrossedBikeMilestones(600, 500), []);

  const lanes: readonly BikeArcadeLane[] = [0, 1, 2];
  for (const previousSafeLane of lanes) {
    for (let index = 0; index < 80; index += 1) {
      const plan = planBikeObstacleWave({
        distance: (index * 37) % (BIKE_ARCADE_GOAL + 1),
        previousSafeLane,
        entropy: {
          safeLane: ((index * 17) % 97) / 97,
          density: ((index * 29) % 89) / 89,
          blockedLane: ((index * 43) % 83) / 83,
          interval: ((index * 53) % 79) / 79,
          obstacleTypes: [((index * 61) % 73) / 73, ((index * 67) % 71) / 71]
        }
      });
      assert.equal(isBikeObstacleWaveSolvable(plan, previousSafeLane), true);
    }
  }
});

test("Bike Arcade 控制器只在合法终态结算成功或失败", () => {
  const winningState = createInitialGameState();
  winningState.bikeArcade.unlocked = true;
  const winningStore = createTestStore(winningState);
  const winningController = new BikeArcadeChapterController(winningStore, new EventBus());

  assert.equal(winningController.startAttempt(), true);
  assert.equal(winningController.recordProgress(BIKE_ARCADE_GOAL - 1, 3), true);
  assert.equal(winningController.completeAttempt(3), false);
  assert.equal(winningController.recordProgress(BIKE_ARCADE_GOAL, 2), true);
  assert.equal(winningController.completeAttempt(2), true);
  assert.equal(winningStore.getState().bikeArcade.completed, true);
  assert.equal(winningStore.getState().bikeArcade.attemptCount, 1);
  assert.equal(winningStore.getState().bikeArcade.bestDistance, BIKE_ARCADE_GOAL);
  assert.equal(winningStore.getState().bikeArcade.bestLives, 2);

  const failedState = createInitialGameState();
  failedState.bikeArcade.unlocked = true;
  const failedStore = createTestStore(failedState);
  const failedController = new BikeArcadeChapterController(failedStore, new EventBus());

  assert.equal(failedController.startAttempt(), true);
  assert.equal(failedController.recordProgress(123, 0), true);
  assert.equal(failedController.failAttempt(123), true);
  assert.equal(failedStore.getState().bikeArcade.completed, false);
  assert.equal(failedStore.getState().bikeArcade.attemptCount, 1);
  assert.equal(failedStore.getState().bikeArcade.bestDistance, 123);
});

test("章节功能门控按剧情事实开放和关闭", () => {
  const chapterOne = createInitialGameState();
  const chapterOneAccess = selectFeatureAccess(chapterOne);
  assert.equal(chapterOneAccess.chapter, "chapter_one");
  assert.equal(chapterOneAccess.checkin, true);
  assert.equal(chapterOneAccess.cc98, false);

  const chapterTwo = createInitialGameState();
  chapterTwo.actOne.phase = "movement_required";
  chapterTwo.actOne.dormHubUnlocked = true;
  const chapterTwoAccess = selectFeatureAccess(chapterTwo);
  assert.equal(chapterTwoAccess.chapter, "chapter_two");
  assert.equal(chapterTwoAccess.checkin, false);
  assert.equal(chapterTwoAccess.cc98, true);
  assert.equal(chapterTwoAccess.fullCampusMap, true);

  const chapterThree = createInitialGameState();
  chapterThree.actOne.phase = "complete";
  chapterThree.ui.libraryFinalsPhase = "friend_contacted";
  chapterThree.ui.libraryFinalsPuzzle.nextQuestId = "chapter_three_book_hunt";
  chapterThree.bikeArcade.unlocked = true;
  const chapterThreeAccess = selectFeatureAccess(chapterThree);
  assert.equal(chapterThreeAccess.chapter, "chapter_three");
  assert.equal(chapterThreeAccess.checkin, false);
  assert.equal(chapterThreeAccess.bikeArcade, true);
});

test("SaveStore 清理临时 UI，并在主存档损坏时恢复上一份快照", () => {
  const storage = new MemoryStorage();
  const saveStore = new SaveStore(storage);
  const initial = createInitialGameState();

  const first = createInitialGameState();
  first.currentScene = "phone_home";
  first.items.waterDrop = true;
  first.ui.controlCenterOpen = true;
  first.ui.inventoryOpen = true;
  first.ui.selectedItem = "waterDrop";
  assert.equal(saveStore.save(first), true);

  const firstLoaded = saveStore.load(initial);
  assert.ok(firstLoaded);
  assert.equal(firstLoaded.currentScene, "phone_home");
  assert.equal(firstLoaded.ui.controlCenterOpen, false);
  assert.equal(firstLoaded.ui.inventoryOpen, false);
  assert.equal(firstLoaded.ui.selectedItem, null);

  const second = createInitialGameState();
  second.actOne.phase = "movement_required";
  second.currentScene = "cc98";
  assert.equal(saveStore.save(second), true);
  storage.setItem(GAME_SAVE_KEY, "{broken json");

  const recovered = saveStore.load(initial);
  assert.ok(recovered);
  assert.equal(recovered.currentScene, "phone_home");
  assert.equal(JSON.parse(storage.getItem(GAME_SAVE_KEY) ?? "null").version, 8);
});

test("SaveStore 在浏览器拒绝存储时返回失败状态", () => {
  const denied = new DeniedStorage();
  const saveStore = new SaveStore(denied);
  assert.equal(saveStore.save(createInitialGameState()), false);
  assert.equal(saveStore.load(createInitialGameState()), null);
});

test("仓库质量契约包含 PR 模板、单元测试和两个离线产物", async () => {
  const root = process.cwd();
  const [workflow, template, developerChannel] = await Promise.all([
    readFile(resolve(root, ".github/workflows/web-ci.yml"), "utf8"),
    readFile(resolve(root, ".github/pull_request_template.md"), "utf8"),
    readFile(resolve(root, "src/components/DeveloperChannel.tsx"), "utf8")
  ]);

  for (const command of [
    "npm test",
    "npm run build:campus-map-demo",
    "npm run verify:campus-map-demo"
  ]) {
    assert.equal(workflow.includes(command), true, `Web CI 缺少命令：${command}`);
  }
  for (const heading of ["## 改动", "## 原因", "## 验证", "## 风险与回滚", "## 未覆盖"]) {
    assert.equal(template.includes(heading), true, `PR 模板缺少章节：${heading}`);
  }
  assert.equal(developerChannel.includes('"寻人篇"'), true, "DEV 面板需要显示寻人篇检查点");
});

test.todo("E2E：chase_ready 自行车热点完成编号读取、纸巾清理、付款、骑行和章节回写");

function createTestStore(initial: GameState): GameStore {
  let state = structuredClone(initial);
  const listeners = new Set<() => void>();
  return {
    getState: () => state,
    subscribe: (listener) => {
      listeners.add(listener);
      return () => listeners.delete(listener);
    },
    setState: (updater) => {
      state = updater(state);
      listeners.forEach((listener) => listener());
    }
  };
}

class MemoryStorage implements Storage {
  private readonly values = new Map<string, string>();

  get length(): number {
    return this.values.size;
  }

  clear(): void {
    this.values.clear();
  }

  getItem(key: string): string | null {
    return this.values.get(key) ?? null;
  }

  key(index: number): string | null {
    return Array.from(this.values.keys())[index] ?? null;
  }

  removeItem(key: string): void {
    this.values.delete(key);
  }

  setItem(key: string, value: string): void {
    this.values.set(key, String(value));
  }
}

class DeniedStorage implements Storage {
  get length(): number {
    throw new DOMException("Storage denied", "SecurityError");
  }

  clear(): void {
    throw new DOMException("Storage denied", "SecurityError");
  }

  getItem(_key: string): string | null {
    throw new DOMException("Storage denied", "SecurityError");
  }

  key(_index: number): string | null {
    throw new DOMException("Storage denied", "SecurityError");
  }

  removeItem(_key: string): void {
    throw new DOMException("Storage denied", "SecurityError");
  }

  setItem(_key: string, _value: string): void {
    throw new DOMException("Storage denied", "SecurityError");
  }
}
