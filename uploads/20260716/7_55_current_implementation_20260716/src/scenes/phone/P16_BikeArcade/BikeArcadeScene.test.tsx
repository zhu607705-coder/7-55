import { act, render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { StrictMode } from "react";
import { eventBus } from "../../../core/EventBus";
import { createInitialGameState, gameStore } from "../../../core/GameState";
import { SceneRouter } from "../../../core/SceneRouter";
import { DEVELOPER_BIKE_START_KEY } from "../../../core/StorageKeys";
import { kit } from "../../../modules/GameKit";
import type { BikeArcadeBridge } from "./BikeRushScene";
import { BikeArcadeScene } from ".";

const phaserMock = vi.hoisted(() => ({
  bridge: null as BikeArcadeBridge | null,
  destroyed: vi.fn(),
  scene: { moveLane: vi.fn() }
}));

vi.mock("phaser", () => ({
  default: {
    CANVAS: 1,
    Scale: { FIT: 1, CENTER_BOTH: 2 },
    Game: class MockPhaserGame {
      scene = { getScene: () => phaserMock.scene };

      constructor(config: {
        callbacks?: {
          preBoot?: (game: { registry: { set: (key: string, value: unknown) => void } }) => void;
          postBoot?: (game: MockPhaserGame) => void;
        };
      }) {
        config.callbacks?.preBoot?.({
          registry: {
            set: (key, value) => {
              if (key === "bikeArcadeBridge") {
                phaserMock.bridge = value as BikeArcadeBridge;
              }
            }
          }
        });
        config.callbacks?.postBoot?.(this);
      }

      destroy() {
        phaserMock.destroyed();
      }
    }
  }
}));

vi.mock("./BikeRushScene", () => ({ BikeRushScene: class MockBikeRushScene {} }));

function renderScene() {
  const router = new SceneRouter(gameStore, eventBus);
  return render(
    <StrictMode>
      <BikeArcadeScene state={gameStore.getState()} router={router} events={eventBus} />
    </StrictMode>
  );
}

describe("BikeArcadeScene", () => {
  beforeEach(() => {
    window.sessionStorage.clear();
    kit.bikeArcade.cancelAttempt();
    eventBus.clearHistory();
    phaserMock.bridge = null;
    phaserMock.destroyed.mockClear();
    phaserMock.scene.moveLane.mockClear();
    const initial = createInitialGameState();
    gameStore.setState(() => ({
      ...initial,
      currentScene: "bike_arcade",
      actOne: { ...initial.actOne, phase: "complete" },
      bikeArcade: { ...initial.bikeArcade, unlocked: true },
      ui: {
        ...initial.ui,
        libraryFinalsPhase: "friend_contacted",
        libraryFinalsPuzzle: {
          ...initial.ui.libraryFinalsPuzzle,
          nextQuestId: "chapter_three_book_hunt"
        }
      }
    }));
  });

  it("shows the 755m target, three chances and saved chapter record", () => {
    renderScene();

    expect(screen.getByRole("heading", { name: "求是潮 755" })).toBeInTheDocument();
    expect(screen.getByText("000 / 755m")).toBeInTheDocument();
    expect(screen.getByText("■■■")).toBeInTheDocument();
    expect(screen.getByText(/最佳 000m/)).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "开始骑行" })).toBeInTheDocument();
  });

  it.each([
    ["377", "377 / 755m"],
    ["566", "566 / 755m"]
  ])("shows developer start distance %s before and after starting", async (storedDistance, label) => {
    const user = userEvent.setup();
    window.sessionStorage.setItem(DEVELOPER_BIKE_START_KEY, storedDistance);
    renderScene();

    expect(screen.getByText(label)).toBeInTheDocument();
    await user.click(screen.getByRole("button", { name: "开始骑行" }));
    expect(screen.getByText(label)).toBeInTheDocument();
  });

  it("connects Phaser callbacks to domain events and persistent victory", async () => {
    const user = userEvent.setup();
    renderScene();

    await user.click(screen.getByRole("button", { name: "开始骑行" }));
    await waitFor(() => expect(phaserMock.bridge).not.toBeNull());

    act(() => {
      phaserMock.bridge?.onLaneChanged?.({ from: 1, to: 2 });
      phaserMock.bridge?.onDistance(377);
      phaserMock.bridge?.onMilestone?.(377);
      phaserMock.bridge?.onLives(1);
      phaserMock.bridge?.onCollision({ obstacleType: "crowd", lives: 1, invulnerableMs: 900 });
      phaserMock.bridge?.onDistance(755);
      phaserMock.bridge?.onFinish("won", { distance: 755, lives: 1, lastMilestone: 755 });
    });

    expect(await screen.findByRole("heading", { name: "已通过" })).toBeInTheDocument();
    expect(gameStore.getState().bikeArcade).toMatchObject({
      completed: true,
      attemptCount: 1,
      bestDistance: 755,
      bestLives: 1
    });
    expect(eventBus.getHistory().map((event) => event.name)).toEqual(
      expect.arrayContaining([
        "bike_arcade_run_started",
        "bike_arcade_lane_changed",
        "bike_arcade_congestion_started",
        "bike_arcade_collision",
        "bike_arcade_last_life",
        "bike_arcade_milestone",
        "bike_arcade_won",
        "bike_arcade_completed"
      ])
    );

    await user.click(screen.getByRole("button", { name: "继续下一章" }));
    expect(gameStore.getState().currentScene).toBe("chapter_transition");
    expect(eventBus.getHistory().at(-1)?.name).toBe("enter_scene");
    expect(eventBus.getHistory().some((event) => event.name === "bike_arcade_next_chapter_requested")).toBe(true);
  });

  it("cancels an active run when returning home and can start again", async () => {
    const user = userEvent.setup();
    renderScene();

    await user.click(screen.getByRole("button", { name: "开始骑行" }));
    await waitFor(() => expect(phaserMock.bridge).not.toBeNull());
    await user.click(screen.getByRole("button", { name: "退出求是潮 755，返回手机桌面" }));

    expect(eventBus.getHistory().some((event) => event.name === "bike_arcade_attempt_cancelled")).toBe(true);
    expect(gameStore.getState().bikeArcade.attemptCount).toBe(0);
    expect(gameStore.getState().currentScene).toBe("phone_home");
  });
});
