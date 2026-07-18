import { fireEvent, render, screen } from "@testing-library/react";
import { beforeEach, describe, expect, it } from "vitest";
import { eventBus } from "../../../core/EventBus";
import { createInitialGameState, gameStore } from "../../../core/GameState";
import { SceneRouter } from "../../../core/SceneRouter";
import { CheckinScene } from ".";

describe("CheckinScene navigation", () => {
  beforeEach(() => {
    eventBus.clearHistory();
    gameStore.setState(() => ({
      ...createInitialGameState(),
      currentScene: "checkin"
    }));
  });

  it("returns explicitly to the Learn at ZJU parent page", () => {
    const router = new SceneRouter(gameStore, eventBus);
    render(<CheckinScene state={gameStore.getState()} router={router} events={eventBus} />);

    const back = screen.getByRole("button", { name: "返回学在浙大" });
    expect(back).toHaveAttribute("data-phone-nav", "back");
    fireEvent.click(back);

    expect(gameStore.getState().currentScene).toBe("zjuding");
    expect(gameStore.getState().ui.zjudingPage).toBe("learn");
  });
});
