import { fireEvent, render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { createInitialGameState, gameStore } from "../core/GameState";
import { InventoryBar } from "./InventoryBar";

function inventoryState() {
  const initial = createInitialGameState();
  const state = {
    ...initial,
    items: { ...initial.items, campusCard: true, gamepad: true },
    ui: { ...initial.ui, inventoryOpen: true }
  };
  gameStore.setState(() => state);
  return state;
}

function pointerEvent(
  element: HTMLElement,
  type: "pointerdown" | "pointermove" | "pointerup",
  { pointerId, clientX, clientY }: { pointerId: number; clientX: number; clientY: number }
) {
  const event = new MouseEvent(type, { bubbles: true, cancelable: true, button: 0, clientX, clientY });
  Object.defineProperties(event, {
    pointerId: { value: pointerId },
    pointerType: { value: "mouse" }
  });
  fireEvent(element, event);
}

function tap(element: HTMLElement, pointerId: number) {
  pointerEvent(element, "pointerdown", { pointerId, clientX: 24, clientY: 180 });
  pointerEvent(element, "pointerup", { pointerId, clientX: 24, clientY: 180 });
}

describe("InventoryBar item inspection", () => {
  it("opens the shared detail view after a mouse or touch double tap", () => {
    const state = inventoryState();
    render(<InventoryBar state={state} />);
    const card = screen.getByRole("button", { name: "道具：电子校园卡，双击查看详情" });

    tap(card, 1);
    tap(card, 2);

    expect(screen.getByRole("dialog")).toHaveTextContent("电子校园卡");
    expect(screen.getByRole("dialog")).toHaveTextContent("身份凭证");
  });

  it("opens details from the keyboard without starting a drag", () => {
    const state = inventoryState();
    render(<InventoryBar state={state} />);

    fireEvent.keyDown(screen.getByRole("button", { name: "道具：游戏手柄，双击查看详情" }), {
      key: "Enter"
    });

    expect(screen.getByRole("dialog")).toHaveTextContent("游戏手柄");
  });

  it("keeps a moved pointer in drag mode and does not open details", () => {
    const state = inventoryState();
    render(<InventoryBar state={state} />);
    const card = screen.getByRole("button", { name: "道具：电子校园卡，双击查看详情" });

    pointerEvent(card, "pointerdown", { pointerId: 3, clientX: 24, clientY: 180 });
    pointerEvent(card, "pointermove", { pointerId: 3, clientX: 90, clientY: 240 });
    pointerEvent(card, "pointerup", { pointerId: 3, clientX: 90, clientY: 240 });

    expect(screen.queryByRole("dialog")).toBeNull();
  });

  it("shows acquired digits in their original four positions", () => {
    const state = inventoryState();
    state.digits = { d1: "0", d2: null, d3: "9", d4: null };
    render(<InventoryBar state={state} />);

    const digits = screen.getAllByLabelText(/已获取签到数字/);
    expect(digits).toHaveLength(2);
    expect(digits[0]).toHaveTextContent("0·9·");
    expect(within(digits[1]).getAllByRole("listitem").map((slot) => slot.textContent)).toEqual([
      "10", "2?", "39", "4?"
    ]);
  });

  it("hides the check-in digits after chapter one", () => {
    const state = inventoryState();
    state.actOne = { ...state.actOne, phase: "movement_required" };
    state.digits = { d1: "0", d2: "7", d3: "9", d4: "8" };

    render(<InventoryBar state={state} />);

    expect(screen.queryByLabelText(/已获取签到数字/)).not.toBeInTheDocument();
    expect(screen.queryByText("签到数字")).not.toBeInTheDocument();
  });
});
