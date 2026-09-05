import { useEffect, useRef, useState, type PointerEvent as ReactPointerEvent, type RefObject } from "react";
import { InventoryAcquisitionFlight, useRecentInventoryItem } from "../../components/InventoryAcquisitionFeedback";
import { ITEM_META, PixelIcon } from "../../components/PixelIcon";
import type { EventBus } from "../../core/EventBus";
import type { GameState, ItemId, RpgSceneId } from "../../core/types";
import { isPaperItem } from "../../data/itemCatalog";
import { clientToRpgCanvasPoint } from "./RpgCanvasCoordinates";
import { selectRpgItemUseGuidance } from "./RpgItemUseGuidance";

interface RpgInventoryDockProps {
  state: GameState;
  events: EventBus;
  blocked?: boolean;
  shellRef: RefObject<HTMLElement | null>;
  canvasHostRef: RefObject<HTMLDivElement | null>;
  runtimeScene: RpgSceneId;
  onInspect: (itemId: ItemId) => void;
  onDragSelectionChange: (itemId: ItemId | null) => void;
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
  "gamepad",
  "occupancyNote",
  "callNumber755",
  "archivedLeaveRule",
  "itemRecognitionReport",
  "bagNonPersonProof",
  "rightArrow",
  "seat022Receipt",
  "libraryPresenceProof",
  "seatReleasePass",
  "cafeteriaWages",
  "greaseTissue",
  "sparklingWater",
  "lemonTea",
  "blackCoffee",
  "badDrink",
  "dailySpecialSparklingWater",
  "pickupTicket0755",
  "canteenRealBun",
  "canteenCluelessSoyMilk",
  "canteenEdgeEgg",
  "canteenUselessCongee",
  "theaterTicketHalfA",
  "theaterTicketHalfB",
  "temporaryTheaterTicket",
  "theaterProgramOpening",
  "theaterProgramSpotlight",
  "theaterProgramFinale",
  "spotlightRemote",
  "fluorescentBrush",
  "decoyPaper",
  "wetProgram",
  "bridgeKeyword",
  "reflectionKeyword",
  "lakeKeyword",
  "reflectionCoordinate",
  "hairDryer",
  "fishingRod",
  "rustedLockerKey",
  "nylonCord",
  "brokenNetFrame",
  "improvisedDipNet",
  "sealedFeedTin",
  "fishFeedPellets",
  "smallCarp",
  "swanMagnet",
  "magneticFishingRod",
  "attendanceRecordPaper",
  "oldClockHourHand",
  "clockPositioningPlate",
  "shortPryBar",
  "universalLubricatingOil",
  "finalMinute"
];

export function isRpgInventoryFeedbackItemId(
  items: GameState["items"],
  value: unknown
): value is ItemId {
  return typeof value === "string"
    && Object.prototype.hasOwnProperty.call(items, value)
    && Object.prototype.hasOwnProperty.call(ITEM_META, value);
}

function itemUseResultText(payload: Record<string, unknown>, itemId: ItemId): string {
  switch (payload.reason) {
    case "accepted": return `${ITEM_META[itemId].name}已使用。`;
    case "too_far": return "距离太远，未能使用。";
    case "wrong_item": return "道具不匹配。";
    case "missed_target": return "道具未放到目标上。";
    case "wrong_mode": return "当前模式无法进行这项操作。";
    case "unobserved": return "尚未记录目标位置。";
    case "direct_paper_failure": return "钓钩无法固定纸张。";
    case "already_complete": return "这项操作已经完成。";
    default: return "这次使用没有生效。";
  }
}

export function RpgInventoryDock({
  state,
  events,
  blocked = false,
  shellRef,
  canvasHostRef,
  runtimeScene,
  onInspect,
  onDragSelectionChange
}: RpgInventoryDockProps) {
  const [drag, setDrag] = useState<DragState | null>(null);
  const lastItemTap = useRef<{ itemId: ItemId; at: number } | null>(null);
  const visibleItems = RPG_DOCK_ORDER.filter((itemId) => state.items[itemId]);
  const recentItem = useRecentInventoryItem(visibleItems);

  useEffect(() => {
    if (!drag || state.items[drag.itemId]) return;
    if (drag.moved) {
      events.emit("rpg_inventory_drag_ended", {
        itemId: drag.itemId,
        surface: "rpg",
        cancelled: true,
        reason: "consumed"
      });
    }
    setDrag(null);
    onDragSelectionChange(null);
  }, [drag, events, onDragSelectionChange, state.items]);

  useEffect(() => {
    if (!blocked || !drag) return;
    if (drag.moved) {
      events.emit("rpg_inventory_drag_ended", {
        itemId: drag.itemId,
        surface: "rpg",
        cancelled: true,
        reason: "input_blocked"
      });
    }
    setDrag(null);
    onDragSelectionChange(null);
  }, [blocked, drag, events, onDragSelectionChange]);

  useEffect(() => {
    return events.subscribe((event) => {
      if (event.name !== "rpg_item_use_feedback"
        || !isRpgInventoryFeedbackItemId(state.items, event.payload?.itemId)) return;
      events.emit("rpg_subtitle", {
        text: itemUseResultText(event.payload, event.payload.itemId),
        tone: "task",
        durationMs: 2400
      });
    });
  }, [events, state.items]);

  useEffect(() => () => {
    onDragSelectionChange(null);
  }, [onDragSelectionChange]);

  if (!state.actOne.inventoryRecovered || visibleItems.length === 0) {
    return null;
  }

  function relativePointer(clientX: number, clientY: number) {
    const shellRect = shellRef.current?.getBoundingClientRect();
    return shellRect
      ? { x: clientX - shellRect.left, y: clientY - shellRect.top }
      : { x: clientX, y: clientY };
  }

  function beginDrag(event: ReactPointerEvent<HTMLButtonElement>, itemId: ItemId) {
    if (blocked) return;
    const point = relativePointer(event.clientX, event.clientY);
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
      ...point
    });
    onDragSelectionChange(itemId);
    event.preventDefault();
  }

  function moveDrag(event: ReactPointerEvent<HTMLButtonElement>) {
    if (!drag || drag.pointerId !== event.pointerId) {
      return;
    }
    const point = relativePointer(event.clientX, event.clientY);
    const moved = drag.moved || Math.hypot(
      event.clientX - drag.startClientX,
      event.clientY - drag.startClientY
    ) > DRAG_START_DISTANCE;
    if (moved && !drag.moved) {
      events.emit("rpg_inventory_drag_started", { itemId: drag.itemId, surface: "rpg" });
    }
    setDrag({ ...drag, moved, ...point });
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
        onDragSelectionChange(null);
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
      onDragSelectionChange(null);
      event.preventDefault();
      return;
    }
    const currentGuidance = selectRpgItemUseGuidance(state, runtimeScene, drag.itemId);
    if (currentGuidance.status !== "ready") {
      events.emit("rpg_item_use_feedback", {
        itemId: drag.itemId,
        reason: currentGuidance.status,
        targetLabel: currentGuidance.targetLabel,
        detail: currentGuidance.detail
      });
      events.emit("rpg_inventory_drag_ended", { itemId: drag.itemId, surface: "rpg" });
      setDrag(null);
      onDragSelectionChange(null);
      event.preventDefault();
      return;
    }
    const surface = canvasHostRef.current?.querySelector<HTMLElement>("canvas, iframe[data-rpg-canvas]");
    const canvasPoint = surface
      ? surface instanceof HTMLCanvasElement
        ? clientToRpgCanvasPoint(
          event.clientX,
          event.clientY,
          surface.getBoundingClientRect(),
          surface.width,
          surface.height
        )
        : clientToRpgCanvasPoint(
          event.clientX,
          event.clientY,
          surface.getBoundingClientRect()
        )
      : null;
    if (canvasPoint) {
      events.emit("rpg_inventory_drop_requested", {
        itemId: drag.itemId,
        canvasX: canvasPoint.x,
        canvasY: canvasPoint.y,
        pointerType: event.pointerType
      });
    } else {
      events.emit("rpg_item_use_feedback", {
        itemId: drag.itemId,
        reason: "missed_target",
        detail: "道具没有进入游戏画布，请拖到场景中的对应物体。"
      });
    }
    events.emit("rpg_inventory_drag_ended", { itemId: drag.itemId, surface: "rpg" });
    setDrag(null);
    onDragSelectionChange(null);
    event.preventDefault();
  }

  function cancelDrag() {
    if (drag?.moved) {
      events.emit("rpg_inventory_drag_ended", { itemId: drag.itemId, surface: "rpg", cancelled: true });
    }
    setDrag(null);
    onDragSelectionChange(null);
  }

  return (
    <aside
      className={`rpg-inventory-dock ${recentItem ? "is-receiving-item" : ""} ${blocked ? "is-blocked" : ""}`.trim()}
      aria-label="RPG 道具栏"
      aria-disabled={blocked}
    >
      <InventoryAcquisitionFlight item={recentItem} className="rpg-inventory-acquisition-flight" />
      <header>
        <strong>道具</strong>
      </header>
      <div className="rpg-inventory-items">
        {visibleItems.map((itemId) => (
          <button
            key={itemId}
            type="button"
            className={`${drag?.itemId === itemId ? "is-dragging" : ""} ${recentItem === itemId ? "is-new-item" : ""}`.trim()}
            aria-label={`拖动${ITEM_META[itemId].name}，${isPaperItem(itemId) ? "单击" : "双击"}查看详情`}
            aria-grabbed={drag?.itemId === itemId}
            disabled={blocked}
            onPointerDown={(event) => beginDrag(event, itemId)}
            onPointerMove={moveDrag}
            onPointerUp={finishDrag}
            onPointerCancel={cancelDrag}
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
      {drag ? (
        <div className="rpg-inventory-drag-ghost" style={{ left: drag.x, top: drag.y }} aria-hidden="true">
          <PixelIcon name={drag.itemId} size={42} />
        </div>
      ) : null}
    </aside>
  );
}
