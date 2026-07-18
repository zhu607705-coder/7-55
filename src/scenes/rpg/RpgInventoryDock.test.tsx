import { createRef } from "react";
import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { EventBus } from "../../core/EventBus";
import { createInitialGameState } from "../../core/GameState";
import { RpgInventoryDock } from "./RpgInventoryDock";

function renderDock(onInspect = vi.fn()) {
  const initial = createInitialGameState();
  const state = {
    ...initial,
    items: { ...initial.items, occupancyNote: true, rightArrow: true },
    actOne: { ...initial.actOne, inventoryRecovered: true }
  };
  const shell = document.createElement("section");
  const host = document.createElement("div");
  const canvas = document.createElement("canvas");
  canvas.width = 960;
  canvas.height = 540;
  Object.defineProperty(canvas, "getBoundingClientRect", {
    value: () => ({ left: 0, top: 0, right: 960, bottom: 540, width: 960, height: 540, x: 0, y: 0, toJSON: () => ({}) })
  });
  host.appendChild(canvas);
  const shellRef = createRef<HTMLElement>();
  const canvasHostRef = createRef<HTMLDivElement>();
  Object.defineProperty(shellRef, "current", { value: shell });
  Object.defineProperty(canvasHostRef, "current", { value: host });
  const events = new EventBus();

  render(
    <RpgInventoryDock
      state={state}
      events={events}
      shellRef={shellRef}
      canvasHostRef={canvasHostRef}
      onInspect={onInspect}
    />
  );
  return { events, onInspect };
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
  pointerEvent(element, "pointerdown", { pointerId, clientX: 40, clientY: 480 });
  pointerEvent(element, "pointerup", { pointerId, clientX: 40, clientY: 480 });
}

describe("RpgInventoryDock inspection and drag separation", () => {
  it("opens paper item details on a single tap without reporting a missed drop", () => {
    const { events, onInspect } = renderDock();
    const note = screen.getByRole("button", { name: "拖动占座纸条，单击查看详情" });

    tap(note, 1);

    expect(onInspect).toHaveBeenCalledWith("occupancyNote");
    expect(events.getHistory().some((event) => event.name === "library_rpg_interaction_failed")).toBe(false);
  });

  it("still emits a scene drop after the pointer crosses the drag threshold", () => {
    const { events, onInspect } = renderDock();
    const arrow = screen.getByRole("button", { name: "拖动右移箭头，双击查看详情" });

    pointerEvent(arrow, "pointerdown", { pointerId: 3, clientX: 40, clientY: 480 });
    pointerEvent(arrow, "pointermove", { pointerId: 3, clientX: 620, clientY: 360 });

    const ghost = document.body.querySelector<HTMLElement>(".rpg-inventory-drag-ghost");
    expect(ghost).toHaveStyle({ left: "620px", top: "360px" });
    expect(ghost?.parentElement).toBe(document.body);

    pointerEvent(arrow, "pointerup", { pointerId: 3, clientX: 620, clientY: 360 });

    expect(onInspect).not.toHaveBeenCalled();
    expect(events.getHistory()).toContainEqual({
      name: "rpg_inventory_drop_requested",
      payload: {
        itemId: "rightArrow",
        canvasX: 620,
        canvasY: 360,
        pointerType: "mouse"
      }
    });
  });

  it("supports keyboard inspection for every visible dock item", () => {
    const { onInspect } = renderDock();
    fireEvent.keyDown(screen.getByRole("button", { name: "拖动占座纸条，单击查看详情" }), {
      key: "Enter"
    });
    expect(onInspect).toHaveBeenCalledWith("occupancyNote");
  });
});
