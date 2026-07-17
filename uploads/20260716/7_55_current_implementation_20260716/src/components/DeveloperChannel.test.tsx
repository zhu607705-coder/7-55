import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { createGameStore } from "../core/GameState";
import { DeveloperChannel, isDeveloperChannelAvailable } from "./DeveloperChannel";

describe("DeveloperChannel component", () => {
  beforeEach(() => {
    window.history.replaceState({}, "", "/");
    window.sessionStorage.clear();
  });

  it("keeps the offline review entry visible unless presentation mode hides it", () => {
    expect(isDeveloperChannelAvailable("", false)).toBe(true);
    expect(isDeveloperChannelAvailable("?dev=1", false)).toBe(true);
    expect(isDeveloperChannelAvailable("?devCheckpoint=c2-dorm-exit", false)).toBe(true);
    expect(isDeveloperChannelAvailable("?dev=0", true)).toBe(false);
  });

  it("keeps its controls clickable while containing pointer events", async () => {
    const user = userEvent.setup();
    const store = createGameStore();
    const onVisibilityChange = vi.fn();
    const parentClick = vi.fn();
    const parentPointerDown = vi.fn();
    render(
      <div onClick={parentClick} onPointerDown={parentPointerDown}>
        <DeveloperChannel store={store} onVisibilityChange={onVisibilityChange} />
      </div>
    );

    await user.click(screen.getByRole("button", { name: "打开开发者通道" }));
    expect(screen.getByRole("complementary", { name: "开发者通道" })).toBeInTheDocument();
    await waitFor(() => expect(onVisibilityChange).toHaveBeenLastCalledWith(true));

    await user.click(screen.getByRole("button", { name: "关闭开发者通道" }));
    expect(screen.queryByRole("complementary", { name: "开发者通道" })).toBeNull();
    await waitFor(() => expect(onVisibilityChange).toHaveBeenLastCalledWith(false));
    expect(parentPointerDown).not.toHaveBeenCalled();
    expect(parentClick).not.toHaveBeenCalled();
  });
});
