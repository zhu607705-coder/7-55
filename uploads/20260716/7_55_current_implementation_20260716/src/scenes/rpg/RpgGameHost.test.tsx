import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { StrictMode } from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { EventBus } from "../../core/EventBus";
import { createInitialGameState, createGameStore } from "../../core/GameState";
import { SceneRouter } from "../../core/SceneRouter";

const phaserGames = vi.hoisted(() => [] as Array<{
  canvas: HTMLCanvasElement;
  destroy: ReturnType<typeof vi.fn>;
  scene: {
    stop: ReturnType<typeof vi.fn>;
    getScenes: ReturnType<typeof vi.fn>;
  };
  input: { enabled: boolean; activePointer: { isDown: boolean } };
}>);

vi.mock("phaser", () => {
  class MockGame {
    canvas: HTMLCanvasElement;
    destroy = vi.fn();
    isBooted = true;
    registry = { set: vi.fn() };
    activeScene = {
      input: {
        enabled: true,
        keyboard: { enabled: true, resetKeys: vi.fn() }
      }
    };
    input = { enabled: true, activePointer: { isDown: false } };
    scene = {
      isActive: vi.fn(() => true),
      start: vi.fn(),
      stop: vi.fn(),
      getScenes: vi.fn(() => [this.activeScene])
    };

    constructor(config: { parent: HTMLElement; callbacks?: { preBoot?: (game: MockGame) => void; postBoot?: (game: MockGame) => void } }) {
      this.canvas = document.createElement("canvas");
      this.canvas.width = 960;
      this.canvas.height = 540;
      config.parent.appendChild(this.canvas);
      config.callbacks?.preBoot?.(this);
      config.callbacks?.postBoot?.(this);
      phaserGames.push(this);
    }
  }

  return {
    default: {
      CANVAS: "CANVAS",
      Game: MockGame,
      Scale: { FIT: "FIT", CENTER_BOTH: "CENTER_BOTH" }
    }
  };
});

vi.mock("./BootScene", () => ({ BootScene: class BootScene {} }));
vi.mock("./DormHubScene", () => ({ DormHubScene: class DormHubScene {} }));
vi.mock("./LibraryInteriorScene", () => ({ LibraryInteriorScene: class LibraryInteriorScene {} }));

import { RpgGameHost } from "./RpgGameHost";

describe("RpgGameHost canvas lifecycle", () => {
  beforeEach(() => {
    phaserGames.length = 0;
  });

  it("keeps exactly one Phaser canvas through StrictMode remounts", async () => {
    const initial = createInitialGameState();
    const store = createGameStore({
      ...initial,
      runtimeMode: "rpg",
      rpgScene: "library_interior",
      rpgCheckpoint: "library_entrance",
      actOne: {
        ...initial.actOne,
        phase: "complete",
        inventoryRecovered: true,
        controlsInstalled: true,
        movementEnabled: true
      },
      ui: {
        ...initial.ui,
        libraryFinalsPhase: "library_entered"
      }
    });
    const events = new EventBus();
    const router = new SceneRouter(store, events);

    const { container, unmount } = render(
      <StrictMode>
        <RpgGameHost store={store} router={router} events={events} />
      </StrictMode>
    );

    await waitFor(() => expect(container.querySelectorAll(".rpg-canvas-host canvas")).toHaveLength(1));
    expect(phaserGames).toHaveLength(2);
    expect(phaserGames[0].destroy).toHaveBeenCalledWith(true);
    expect(phaserGames[1].scene.stop).toHaveBeenCalledWith("campus-bootstrap");
    expect(phaserGames[1].scene.stop).toHaveBeenCalledWith("dorm-hub");

    unmount();
    expect(container.querySelectorAll(".rpg-canvas-host canvas")).toHaveLength(0);
    expect(phaserGames[1].destroy).toHaveBeenCalledWith(true);
  });

  it("blocks Phaser while the developer channel is open and restores it after the closing pointer frame", async () => {
    const initial = createInitialGameState();
    const store = createGameStore({ ...initial, runtimeMode: "rpg" });
    const events = new EventBus();
    const router = new SceneRouter(store, events);
    const { rerender } = render(
      <RpgGameHost store={store} router={router} events={events} inputBlocked />
    );

    await waitFor(() => expect(phaserGames.at(-1)?.input.enabled).toBe(false));
    expect(phaserGames.at(-1)?.scene.getScenes()[0].input.keyboard.enabled).toBe(false);
    rerender(<RpgGameHost store={store} router={router} events={events} inputBlocked={false} />);
    await waitFor(() => expect(phaserGames.at(-1)?.input.enabled).toBe(true));
    expect(phaserGames.at(-1)?.scene.getScenes()[0].input.keyboard.enabled).toBe(true);
    expect(phaserGames.at(-1)?.scene.getScenes()[0].input.keyboard.resetKeys.mock.calls.length).toBeGreaterThanOrEqual(3);
  });

  it("restores Phaser input even when Phaser retained a stale pressed pointer", async () => {
    const initial = createInitialGameState();
    const store = createGameStore({ ...initial, runtimeMode: "rpg" });
    const events = new EventBus();
    const router = new SceneRouter(store, events);
    const { rerender } = render(
      <RpgGameHost store={store} router={router} events={events} inputBlocked />
    );

    await waitFor(() => expect(phaserGames.at(-1)?.input.enabled).toBe(false));
    phaserGames.at(-1)!.input.activePointer.isDown = true;
    rerender(<RpgGameHost store={store} router={router} events={events} inputBlocked={false} />);
    await waitFor(() => expect(phaserGames.at(-1)?.input.enabled).toBe(true));
  });

  it("labels the touch interaction control with the actual Space keyboard binding", async () => {
    const initial = createInitialGameState();
    const store = createGameStore({
      ...initial,
      runtimeMode: "rpg",
      actOne: {
        ...initial.actOne,
        controlsInstalled: true,
        movementEnabled: true
      }
    });
    const events = new EventBus();
    const router = new SceneRouter(store, events);

    render(<RpgGameHost store={store} router={router} events={events} />);

    expect(await screen.findByRole("navigation", { name: /WASD 移动和空格键交互/ })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "交互（键盘为空格键）" })).toHaveTextContent("空格");
  });

  it("shows owned map items as real controls and repairs a stale gamepad state", async () => {
    const initial = createInitialGameState();
    const store = createGameStore({
      ...initial,
      runtimeMode: "rpg",
      rpgScene: "dorm_hub",
      items: { ...initial.items, campusCard: true, gamepad: false },
      actOne: {
        ...initial.actOne,
        phase: "movement_required",
        inventoryRecovered: true,
        characterNamed: true,
        identityVerified: true,
        exerciseStarted: true,
        gamepadPurchased: true,
        controlsInstalled: false,
        movementEnabled: false
      }
    });
    const events = new EventBus();
    const router = new SceneRouter(store, events);

    render(<RpgGameHost store={store} router={router} events={events} />);

    expect(await screen.findByRole("complementary", { name: "地图物品栏" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "查看电子校园卡" })).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "使用游戏手柄" }));

    expect(store.getState()).toMatchObject({
      items: { gamepad: true },
      actOne: { controlsInstalled: true, movementEnabled: true }
    });
    expect(await screen.findByText("已连接")).toBeInTheDocument();
    expect(screen.getByRole("navigation", { name: /WASD 移动和空格键交互/ })).toBeInTheDocument();
  });

  it("keeps the gamepad usable in the map and explains a missing identity prerequisite", async () => {
    const initial = createInitialGameState();
    const store = createGameStore({
      ...initial,
      runtimeMode: "rpg",
      rpgScene: "dorm_hub",
      items: { ...initial.items, campusCard: true, gamepad: true },
      actOne: {
        ...initial.actOne,
        phase: "movement_required",
        inventoryRecovered: true,
        gamepadPurchased: true,
        controlsInstalled: true,
        exerciseStarted: true
      }
    });
    const events = new EventBus();
    const router = new SceneRouter(store, events);

    render(<RpgGameHost store={store} router={router} events={events} />);
    fireEvent.click(await screen.findByRole("button", { name: "使用游戏手柄" }));

    expect(screen.getByText("待登记姓名")).toBeInTheDocument();
    expect(events.getHistory()).toContainEqual({
      name: "act2_gamepad_use_rejected",
      payload: { reason: "identity_required" }
    });
    expect(events.getHistory()).toContainEqual(expect.objectContaining({
      name: "toast",
      payload: expect.objectContaining({ text: expect.stringContaining("部门黄页") })
    }));
  });

  it("opens the same item detail view from the map inventory after a double tap", async () => {
    const initial = createInitialGameState();
    const store = createGameStore({
      ...initial,
      runtimeMode: "rpg",
      rpgScene: "dorm_hub",
      items: { ...initial.items, campusCard: true, gamepad: true },
      actOne: {
        ...initial.actOne,
        phase: "movement_required",
        inventoryRecovered: true,
        characterNamed: true,
        exerciseStarted: true,
        gamepadPurchased: true,
        controlsInstalled: true,
        movementEnabled: true
      }
    });
    const events = new EventBus();
    const router = new SceneRouter(store, events);

    render(<RpgGameHost store={store} router={router} events={events} />);
    const gamepad = await screen.findByRole("button", { name: "使用游戏手柄" });
    fireEvent.pointerUp(gamepad, { pointerId: 1 });
    fireEvent.pointerUp(gamepad, { pointerId: 2 });

    expect(screen.getByRole("dialog")).toHaveTextContent("游戏手柄");
    expect(screen.getByRole("dialog")).toHaveTextContent("控制设备");
    expect(store.getState().actOne.movementEnabled).toBe(true);
    expect(events.getHistory()).toContainEqual({
      name: "inventory_item_inspected",
      payload: { itemId: "gamepad", surface: "rpg" }
    });
  });
});
