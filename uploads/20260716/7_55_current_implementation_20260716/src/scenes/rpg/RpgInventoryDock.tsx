import { useRef, useState, type PointerEvent as ReactPointerEvent, type RefObject } from "react";
import { createPortal } from "react-dom";
import { ITEM_META, PixelIcon } from "../../components/PixelIcon";
import type { EventBus } from "../../core/EventBus";
import type { GameState, ItemId } from "../../core/types";
import { isPaperItem } from "../../data/itemCatalog";
import { clientToRpgCanvasPoint } from "./RpgCanvasCoordinates";

interface RpgInventoryDockProps {
  state: GameState;
  events: EventBus;
  shellRef: RefObject<HTMLElement | null>;
  canvasHostRef: RefObject<HTMLDivElement | null>;
  onInspect: (itemId: ItemId) => void;
}

interface DragState {
  itemId: ItemId;
  pointerId: number;
  x: number;
  y: number;
  startClientX: number;
  startClientY: number;
  moved: boolean;
}

const DOUBLE_TAP_WINDOW_MS = 380;
const DRAG_START_DISTANCE = 4;

const RPG_DOCK_ORDER: readonly ItemId[] = [
  "campusCard",
  "occupancyNote",
  "callNumber755",
  "archivedLeaveRule",
  "itemRecognitionReport",
  "bagNonPersonProof",
  "rightArrow",
  "seat022Receipt",
  "libraryPresenceProof",
  "seatReleasePass"
];

export function RpgInventoryDock({ state, events, shellRef, canvasHostRef, onInspect }: RpgInventoryDockProps) {
  const [drag, setDrag] = useState<DragState | null>(null);
  const lastItemTap = useRef<{ itemId: ItemId; at: number } | null>(null);
  const visibleItems = RPG_DOCK_ORDER.filter((itemId) => state.items[itemId]);

  if (!state.actOne.inventoryRecovered || visibleItems.length === 0) {
    return null;
  }

  function beginDrag(event: ReactPointerEvent<HTMLButtonElement>, itemId: ItemId) {
    try {
      event.currentTarget.setPointerCapture(event.pointerId);
    } catch {
      // Synthetic pointer events may not provide capture support.
    }
    setDrag({
      itemId,
      pointerId: event.pointerId,
      startClientX: event.clientX,
      startClientY: event.clientY,
      moved: false,
      x: event.clientX,
      y: event.clientY
    });
    event.preventDefault();
  }

  function moveDrag(event: ReactPointerEvent<HTMLButtonElement>) {
    if (!drag || drag.pointerId !== event.pointerId) {
      return;
    }
    const moved = drag.moved || Math.hypot(
      event.clientX - drag.startClientX,
      event.clientY - drag.startClientY
    ) > DRAG_START_DISTANCE;
    setDrag({ ...drag, moved, x: event.clientX, y: event.clientY });
    if (moved) {
      event.preventDefault();
    }
  }

  function finishDrag(event: ReactPointerEvent<HTMLButtonElement>) {
    if (!drag || drag.pointerId !== event.pointerId) {
      return;
    }
    try {
      event.currentTarget.releasePointerCapture(event.pointerId);
    } catch {
      // Synthetic pointer events may not own a capture target.
    }
    if (!drag.moved) {
      if (isPaperItem(drag.itemId)) {
        lastItemTap.current = null;
        onInspect(drag.itemId);
        setDrag(null);
        event.preventDefault();
        return;
      }
      const now = Date.now();
      const previousTap = lastItemTap.current;
      if (previousTap?.itemId === drag.itemId && now - previousTap.at <= DOUBLE_TAP_WINDOW_MS) {
        lastItemTap.current = null;
        onInspect(drag.itemId);
      } else {
        lastItemTap.current = { itemId: drag.itemId, at: now };
      }
      setDrag(null);
      event.preventDefault();
      return;
    }
    const canvas = canvasHostRef.current?.querySelector("canvas");
    const canvasPoint = canvas
      ? clientToRpgCanvasPoint(event.clientX, event.clientY, canvas.getBoundingClientRect())
      : null;
    if (canvasPoint) {
      events.emit("rpg_inventory_drop_requested", {
        itemId: drag.itemId,
        canvasX: canvasPoint.x,
        canvasY: canvasPoint.y,
        pointerType: event.pointerType
      });
    } else {
      events.emit("library_rpg_interaction_failed", { itemId: drag.itemId, reason: "no_target" });
    }
    setDrag(null);
    event.preventDefault();
  }

  return (
    <aside className="rpg-inventory-dock" aria-label="RPG 道具栏">
      <header>
        <strong>道具</strong>
        <span>拖到场景目标</span>
      </header>
      <div className="rpg-inventory-items">
        {visibleItems.map((itemId) => (
          <button
            key={itemId}
            type="button"
            className={drag?.itemId === itemId ? "is-dragging" : ""}
            aria-label={`拖动${ITEM_META[itemId].name}，${isPaperItem(itemId) ? "单击" : "双击"}查看详情`}
            aria-grabbed={drag?.itemId === itemId}
            title={`${ITEM_META[itemId].name}：${ITEM_META[itemId].desc}`}
            onPointerDown={(event) => beginDrag(event, itemId)}
            onPointerMove={moveDrag}
            onPointerUp={finishDrag}
            onPointerCancel={() => setDrag(null)}
            onKeyDown={(event) => {
              if (event.key === "Enter") {
                event.preventDefault();
                onInspect(itemId);
              }
            }}
          >
            <PixelIcon name={itemId} size={34} />
            <span>{ITEM_META[itemId].name}</span>
          </button>
        ))}
      </div>
      {drag ? createPortal((
        <div className="rpg-inventory-drag-ghost" style={{ left: drag.x, top: drag.y }} aria-hidden="true">
          <PixelIcon name={drag.itemId} size={42} />
        </div>
      ), document.body) : null}
    </aside>
  );
}
