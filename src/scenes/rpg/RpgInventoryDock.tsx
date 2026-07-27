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

interface DropFeedback {
  itemId: ItemId;
  tone: "success" | "warning" | "error";
  title: string;
  detail: string;
}

const DOUBLE_TAP_WINDOW_MS = 380;
const DRAG_START_DISTANCE = 4;
const DROP_FEEDBACK_MS = 3600;

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
  "pickupTicket0755",
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
  "reflectionCoordinate"
];

function feedbackFromPayload(payload: Record<string, unknown>): DropFeedback {
  const itemId = String(payload.itemId ?? "campusCard") as ItemId;
  const reason = String(payload.reason ?? "locked");
  const targetLabel = String(payload.targetLabel ?? "目标");
  const customDetail = String(payload.detail ?? "");
  if (reason === "accepted") {
    return {
      itemId,
      tone: "success",
      title: "目标命中，使用成功",
      detail: customDetail || `${targetLabel}已接收该道具。`
    };
  }
  if (reason === "too_far") {
    return {
      itemId,
      tone: "warning",
      title: "目标命中，人物距离不足",
      detail: customDetail || `先让人物走到「${targetLabel}」旁边，再拖入道具。`
    };
  }
  if (reason === "wrong_item") {
    return {
      itemId,
      tone: "warning",
      title: "目标命中，道具不匹配",
      detail: customDetail || `「${targetLabel}」需要另一类道具。`
    };
  }
  if (reason === "missed_target") {
    return {
      itemId,
      tone: "error",
      title: "没有放进目标范围",
      detail: customDetail || "拖动位置有效，但松手点落在高亮框外。"
    };
  }
  if (reason === "passive") {
    return {
      itemId,
      tone: "warning",
      title: "此处无需拖动",
      detail: customDetail || "靠近对应位置或完成页面操作时会自动核验。"
    };
  }
  if (reason === "elsewhere") {
    return {
      itemId,
      tone: "warning",
      title: "本场景没有使用点",
      detail: customDetail || "保留该道具，跟随当前任务前往对应页面或场景。"
    };
  }
  return {
    itemId,
    tone: "warning",
    title: "当前使用条件未满足",
    detail: customDetail || `「${targetLabel}」当前还不能接收该道具。`
  };
}

export function RpgInventoryDock({
  state,
  events,
  shellRef,
  canvasHostRef,
  runtimeScene,
  onInspect,
  onDragSelectionChange
}: RpgInventoryDockProps) {
  const [drag, setDrag] = useState<DragState | null>(null);
  const [dropFeedback, setDropFeedback] = useState<DropFeedback | null>(null);
  const lastItemTap = useRef<{ itemId: ItemId; at: number } | null>(null);
  const feedbackTimer = useRef<number | null>(null);
  const visibleItems = RPG_DOCK_ORDER.filter((itemId) => state.items[itemId]);
  const recentItem = useRecentInventoryItem(visibleItems);
  const guidance = drag ? selectRpgItemUseGuidance(state, runtimeScene, drag.itemId) : null;

  useEffect(() => {
    return events.subscribe((event) => {
      if (event.name !== "rpg_item_use_feedback" || !event.payload?.itemId) return;
      if (feedbackTimer.current !== null) window.clearTimeout(feedbackTimer.current);
      setDropFeedback(feedbackFromPayload(event.payload));
      feedbackTimer.current = window.setTimeout(() => {
        setDropFeedback(null);
        feedbackTimer.current = null;
      }, DROP_FEEDBACK_MS);
    });
  }, [events]);

  useEffect(() => () => {
    if (feedbackTimer.current !== null) window.clearTimeout(feedbackTimer.current);
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
    setDropFeedback(null);
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
        detail: "道具没有进入游戏画布，请拖到场景内的高亮目标。"
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
    <aside className={`rpg-inventory-dock ${recentItem ? "is-receiving-item" : ""}`} aria-label="RPG 道具栏">
      <InventoryAcquisitionFlight item={recentItem} className="rpg-inventory-acquisition-flight" />
      <header>
        <strong>道具</strong>
        <span>按住查看可用时机 · 拖到高亮目标</span>
      </header>
      {guidance ? (
        <div className={`rpg-item-use-guidance is-${guidance.status}`} role="status">
          <strong>{ITEM_META[drag!.itemId].name} · {guidance.title}</strong>
          <span>{guidance.targetLabel ? `目标：${guidance.targetLabel}。` : ""}{guidance.detail}</span>
        </div>
      ) : dropFeedback ? (
        <div className={`rpg-item-use-guidance is-${dropFeedback.tone}`} role="status" aria-live="polite">
          <strong>{ITEM_META[dropFeedback.itemId].name} · {dropFeedback.title}</strong>
          <span>{dropFeedback.detail}</span>
        </div>
      ) : null}
      <div className="rpg-inventory-items">
        {visibleItems.map((itemId) => (
          <button
            key={itemId}
            type="button"
            className={`${drag?.itemId === itemId ? "is-dragging" : ""} ${recentItem === itemId ? "is-new-item" : ""}`.trim()}
            aria-label={`拖动${ITEM_META[itemId].name}，${isPaperItem(itemId) ? "单击" : "双击"}查看详情`}
            aria-grabbed={drag?.itemId === itemId}
            title={`${ITEM_META[itemId].name}：${ITEM_META[itemId].desc}`}
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
