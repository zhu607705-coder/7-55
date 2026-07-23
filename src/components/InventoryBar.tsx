import { useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { eventBus } from "../core/EventBus";
import type { GameState, ItemId } from "../core/types";
import { kit } from "../modules/GameKit";
import { ItemInspectDialog } from "./ItemInspectDialog";
import { ITEM_META, PixelIcon } from "./PixelIcon";
import { InventoryAcquisitionFlight, useRecentInventoryItem } from "./InventoryAcquisitionFeedback";
import { isPaperItem } from "../data/itemCatalog";
import { PHONE_VIEWPORT_HEIGHT } from "./PhoneViewport";

interface InventoryBarProps {
  state: GameState;
}

interface DragGhost {
  item: ItemId;
  x: number;
  y: number;
  moved: boolean;
}

interface ScrollDrag {
  pointerId: number;
  startY: number;
  scrollTop: number;
}

interface BarDrag {
  pointerId: number;
  startY: number;
  startTop: number;
  moved: boolean;
  fromHandle: boolean;
}

interface ItemDrag {
  item: ItemId;
  pointerId: number;
  startX: number;
  startY: number;
  moved: boolean;
}

interface PointerLike {
  pointerId: number;
  clientX: number;
  clientY: number;
  preventDefault: () => void;
}

const ITEM_ORDER: ItemId[] = [
  "headphone",
  "waterDrop",
  "wateredHeadphone",
  "reverseGear",
  "slashLine",
  "towerKey",
  "fertilizer",
  "campusCard",
  "pushTriangle",
  "weatherWater",
  "mentorLine",
  "rightArrow",
  "gamepad",
  "occupancyNote",
  "callNumber755",
  "archivedLeaveRule",
  "itemRecognitionReport",
  "bagNonPersonProof",
  "seat022Receipt",
  "libraryPresenceProof",
  "seatReleasePass",
  "cafeteriaWages",
  "greaseTissue",
  "pickupTicket0755"
];
const INVENTORY_TOP_DEFAULT = 240;
const INVENTORY_TOP_MIN = 108;
const INVENTORY_BOTTOM_GAP = 16;
const DRAG_START_DISTANCE = 3;
const DOUBLE_TAP_WINDOW_MS = 380;
const DROP_HIT_OFFSETS = [
  [0, 0],
  [0, -18],
  [0, 18],
  [-18, 0],
  [18, 0],
  [-18, -18],
  [18, -18],
  [-18, 18],
  [18, 18]
] as const;

function getPhoneScale() {
  const stage = document.querySelector<HTMLElement>(".app-stage");
  const value = stage ? window.getComputedStyle(stage).getPropertyValue("--phone-scale") : "";
  return Number.parseFloat(value) || 1;
}

function safeSetPointerCapture(el: HTMLElement, pointerId: number) {
  try {
    el.setPointerCapture?.(pointerId);
  } catch {
    // Synthetic pointer events in tests may not have an active pointer capture target.
  }
}

function safeReleasePointerCapture(el: HTMLElement | null, pointerId: number) {
  try {
    el?.releasePointerCapture?.(pointerId);
  } catch {
    // See safeSetPointerCapture.
  }
}

function closestFromPoint(selector: string, x: number, y: number) {
  if (typeof document.elementFromPoint !== "function") {
    return null;
  }
  for (const [dx, dy] of DROP_HIT_OFFSETS) {
    const element = document.elementFromPoint(x + dx, y + dy);
    const closest = element?.closest<HTMLElement>(selector);
    if (closest) {
      return closest;
    }
  }
  return null;
}

function closestByRect(selector: string, x: number, y: number) {
  const candidates = Array.from(document.querySelectorAll<HTMLElement>(selector));
  return (
    candidates.find((element) => {
      const rect = element.getBoundingClientRect();
      return x >= rect.left && x <= rect.right && y >= rect.top && y <= rect.bottom;
    }) ?? null
  );
}

function closestDropTarget(selector: string, x: number, y: number) {
  return closestFromPoint(selector, x, y) ?? closestByRect(selector, x, y);
}

/**
 * 可收起的左侧物品栏（参照 pageexample/物品栏.png）。
 * - 点击槽位：查看道具说明
 * - 道具拖到另一道具上：合成（斜线+齿轮→钥匙；三角形+竖线→右移箭头）
 * - 道具拖到场景目标（带 data-drop-target 的元素）上：使用（钥匙→塔楼锁孔、浇水/施肥→盆栽）
 */
export function InventoryBar({ state }: InventoryBarProps) {
  const [ghost, setGhost] = useState<DragGhost | null>(null);
  const [inspectedItem, setInspectedItem] = useState<ItemId | null>(null);
  const [barTop, setBarTop] = useState(INVENTORY_TOP_DEFAULT);
  const [barDragging, setBarDragging] = useState(false);
  const [scrollDragging, setScrollDragging] = useState(false);
  const dragFrom = useRef<ItemDrag | null>(null);
  const barDrag = useRef<BarDrag | null>(null);
  const suppressHandleClick = useRef(false);
  const lastItemTap = useRef<{ item: ItemId; at: number } | null>(null);
  const scrollDrag = useRef<ScrollDrag | null>(null);
  const barRef = useRef<HTMLElement>(null);
  const slotsRef = useRef<HTMLDivElement>(null);
  const ghostRef = useRef<HTMLDivElement>(null);
  const open = state.ui.inventoryOpen;
  const owned = ITEM_ORDER.filter((id) => state.items[id]);
  const recentItem = useRecentInventoryItem(owned);

  function clampBarTop(nextTop: number) {
    const height = barRef.current?.offsetHeight ?? (open ? 328 : 42);
    const maxTop = Math.max(INVENTORY_TOP_MIN, PHONE_VIEWPORT_HEIGHT - height - INVENTORY_BOTTOM_GAP);
    return Math.min(maxTop, Math.max(INVENTORY_TOP_MIN, nextTop));
  }

  useEffect(() => {
    setBarTop((top) => clampBarTop(top));
  }, [open, owned.length]);

  function toggleOpen() {
    kit.flags.setUi("inventoryOpen", !open);
    if (open) {
      kit.flags.setUi("selectedItem", null);
    }
    eventBus.emit("inventory_panel_toggled", { open: !open });
  }

  function openItemDetails(item: ItemId) {
    lastItemTap.current = null;
    kit.flags.setUi("selectedItem", null);
    setInspectedItem(item);
    eventBus.emit("inventory_item_inspected", { itemId: item, surface: "phone" });
  }

  function onSlotPointerDown(item: ItemId, e: React.PointerEvent) {
    safeSetPointerCapture(e.currentTarget as HTMLElement, e.pointerId);
    dragFrom.current = { item, pointerId: e.pointerId, startX: e.clientX, startY: e.clientY, moved: false };
    setGhost({ item, x: e.clientX, y: e.clientY, moved: false });
    e.preventDefault();
  }

  function moveGhost(x: number, y: number) {
    const element = ghostRef.current;
    if (!element) {
      return;
    }
    element.style.transform = `translate(${x}px, ${y}px) translate(-50%, -50%) scale(1.15)`;
  }

  function onBarPointerDown(e: React.PointerEvent<HTMLElement>) {
    if (e.button !== 0) {
      return;
    }
    const target = e.target as HTMLElement;
    if (target.closest("[data-inv-item]") || target.closest(".inv-slots")) {
      return;
    }
    safeSetPointerCapture(e.currentTarget, e.pointerId);
    barDrag.current = {
      pointerId: e.pointerId,
      startY: e.clientY,
      startTop: barTop,
      moved: false,
      fromHandle: Boolean(target.closest(".inv-handle"))
    };
    setBarDragging(true);
  }

  function onSlotsPointerDown(e: React.PointerEvent<HTMLDivElement>) {
    if (e.button !== 0 || (e.target as HTMLElement).closest("[data-inv-item]")) {
      return;
    }
    const slots = slotsRef.current;
    if (!slots || slots.scrollHeight <= slots.clientHeight) {
      return;
    }
    safeSetPointerCapture(slots, e.pointerId);
    scrollDrag.current = { pointerId: e.pointerId, startY: e.clientY, scrollTop: slots.scrollTop };
    setScrollDragging(true);
    e.preventDefault();
  }

  function onSlotsPointerMove(e: React.PointerEvent<HTMLDivElement>) {
    const drag = scrollDrag.current;
    const slots = slotsRef.current;
    if (!drag || !slots || drag.pointerId !== e.pointerId) {
      return;
    }
    slots.scrollTop = drag.scrollTop - (e.clientY - drag.startY);
  }

  function finishSlotsScroll(e: React.PointerEvent<HTMLDivElement>) {
    const drag = scrollDrag.current;
    if (!drag || drag.pointerId !== e.pointerId) {
      return;
    }
    safeReleasePointerCapture(slotsRef.current, e.pointerId);
    scrollDrag.current = null;
    setScrollDragging(false);
  }

  function moveActivePointer(e: PointerLike) {
    const currentBarDrag = barDrag.current;
    if (currentBarDrag && currentBarDrag.pointerId === e.pointerId) {
      const distance = e.clientY - currentBarDrag.startY;
      const moved = currentBarDrag.moved || Math.abs(distance) > 4;
      barDrag.current = { ...currentBarDrag, moved };
      setBarTop(clampBarTop(currentBarDrag.startTop + distance / getPhoneScale()));
      if (moved) {
        e.preventDefault();
      }
      return;
    }

    if (!dragFrom.current) {
      return;
    }
    const { startX, startY, item } = dragFrom.current;
    if (dragFrom.current.pointerId !== e.pointerId) {
      return;
    }
    const wasMoved = dragFrom.current.moved;
    const moved = Math.hypot(e.clientX - startX, e.clientY - startY) > DRAG_START_DISTANCE;
    dragFrom.current.moved = dragFrom.current.moved || moved;
    if (!wasMoved && dragFrom.current.moved) {
      eventBus.emit("inventory_drag_started", { itemId: item, surface: "phone" });
    }
    if (moved) {
      moveGhost(e.clientX, e.clientY);
      e.preventDefault();
    }
    if (!ghost || ghost.item !== item || ghost.moved !== dragFrom.current.moved) {
      setGhost({ item, x: e.clientX, y: e.clientY, moved: dragFrom.current.moved });
    }
  }

  function finishActivePointer(e: PointerLike, applyDrop = true) {
    const currentBarDrag = barDrag.current;
    if (currentBarDrag && currentBarDrag.pointerId === e.pointerId) {
      barDrag.current = null;
      setBarDragging(false);
      safeReleasePointerCapture(barRef.current, e.pointerId);
      if (currentBarDrag.moved) {
        suppressHandleClick.current = true;
        e.preventDefault();
      } else if (currentBarDrag.fromHandle) {
        suppressHandleClick.current = true;
        toggleOpen();
        e.preventDefault();
      }
      return;
    }

    const from = dragFrom.current;
    if (from && from.pointerId !== e.pointerId) {
      return;
    }
    dragFrom.current = null;
    setGhost(null);
    if (!from) {
      return;
    }
    if (from.moved) eventBus.emit("inventory_drag_ended", { itemId: from.item, surface: "phone" });

    if (!applyDrop) {
      return;
    }

    if (!from.moved) {
      if (isPaperItem(from.item)) {
        openItemDetails(from.item);
        return;
      }
      const now = Date.now();
      const previousTap = lastItemTap.current;
      if (previousTap?.item === from.item && now - previousTap.at <= DOUBLE_TAP_WINDOW_MS) {
        openItemDetails(from.item);
        return;
      }
      lastItemTap.current = { item: from.item, at: now };

      // 单击保留原有快速说明；双击或双触打开完整详情。
      const next = state.ui.selectedItem === from.item ? null : from.item;
      kit.flags.setUi("selectedItem", next);
      eventBus.emit("inventory_item_selection_changed", {
        itemId: from.item,
        selected: next !== null
      });
      if (next) {
        kit.flags.toast(`${ITEM_META[next].name}：${ITEM_META[next].desc}`);
      }
      return;
    }

    // 1) 拖到另一个道具上 → 合成
    const slot = closestDropTarget("[data-inv-item]", e.clientX, e.clientY);
    const target = slot?.dataset.invItem as ItemId | undefined;
    if (target && target !== from.item) {
      const result = kit.inventory.combine(from.item, target);
      if (result) {
        kit.flags.setUi("selectedItem", null);
        kit.flags.toast(`合成成功：${ITEM_META[result].name}！`, "task");
      } else {
        eventBus.emit("inventory_combine_rejected", { itemId: from.item, targetItemId: target });
        kit.flags.toast("它们拒绝合作。");
      }
      return;
    }

    // 2) 拖到场景目标上 → 使用
    const dropZone = closestDropTarget("[data-drop-target]", e.clientX, e.clientY);
    if (dropZone?.dataset.dropTarget) {
      eventBus.emit("item_dropped", { item: from.item, target: dropZone.dataset.dropTarget });
      return;
    }

    eventBus.emit("inventory_drop_missed", { itemId: from.item });
  }

  function onPointerMove(e: React.PointerEvent) {
    moveActivePointer(e);
  }

  function onPointerUp(e: React.PointerEvent) {
    finishActivePointer(e);
  }

  function onPointerCancel(e: React.PointerEvent) {
    finishActivePointer(e, false);
  }

  useEffect(() => {
    const move = (event: PointerEvent) => moveActivePointer(event);
    const up = (event: PointerEvent) => finishActivePointer(event);
    const cancel = (event: PointerEvent) => finishActivePointer(event, false);

    window.addEventListener("pointermove", move, { passive: false });
    window.addEventListener("pointerup", up, { passive: false });
    window.addEventListener("pointercancel", cancel, { passive: false });
    return () => {
      window.removeEventListener("pointermove", move);
      window.removeEventListener("pointerup", up);
      window.removeEventListener("pointercancel", cancel);
    };
  });

  if (owned.length === 0) {
    return null;
  }

  const ghostElement = ghost?.moved ? (
    <div
      ref={ghostRef}
      className="inv-ghost"
      style={{ transform: `translate(${ghost.x}px, ${ghost.y}px) translate(-50%, -50%) scale(1.15)` }}
      aria-hidden="true"
    >
      <PixelIcon name={ghost.item} size={34} />
    </div>
  ) : null;

  return (
    <>
      <aside
        ref={barRef}
        className={`inventory-bar ${open ? "is-open" : "is-closed"} ${barDragging ? "is-position-dragging" : ""} ${recentItem ? "is-receiving-item" : ""}`}
        style={{ top: `${barTop}px` }}
        aria-label="物品栏"
        onPointerDown={onBarPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerCancel={onPointerCancel}
      >
        <InventoryAcquisitionFlight item={recentItem} className="inv-acquisition-flight" />
        <button
          type="button"
          className="inv-handle"
          onClick={(e) => {
            if (suppressHandleClick.current) {
              suppressHandleClick.current = false;
              e.preventDefault();
              return;
            }
            toggleOpen();
          }}
          aria-expanded={open}
          aria-label={open ? "收起物品栏" : "展开物品栏"}
        >
          <PixelIcon name="backpack" size={26} />
          <span className="inv-arrow">{open ? "‹" : "›"}</span>
          {!open && owned.length > 0 ? <i className="inv-count">{owned.length}</i> : null}
        </button>

        {open ? (
          <div className="inv-body">
            <div
              ref={slotsRef}
              className={`inv-slots ${scrollDragging ? "is-scroll-dragging" : ""}`}
              onPointerDown={onSlotsPointerDown}
              onPointerMove={onSlotsPointerMove}
              onPointerUp={finishSlotsScroll}
              onPointerCancel={finishSlotsScroll}
            >
              {owned.length === 0 ? <p className="inv-empty">空空如也</p> : null}
              {owned.map((item) => (
                <button
                  key={item}
                  type="button"
                  data-inv-item={item}
                  className={`inv-slot ${state.ui.selectedItem === item ? "is-selected" : ""} ${recentItem === item ? "is-new-item" : ""} ${
                    ghost?.moved && ghost.item === item ? "is-dragging" : ""
                  }`}
                  aria-label={`道具：${ITEM_META[item].name}，${isPaperItem(item) ? "点击展开内容" : "双击查看详情"}`}
                  onPointerDown={(e) => onSlotPointerDown(item, e)}
                  onKeyDown={(event) => {
                    if (event.key === "Enter") {
                      event.preventDefault();
                      openItemDetails(item);
                    }
                  }}
                >
                  <PixelIcon name={item} size={34} />
                </button>
              ))}
            </div>
            <p className="inv-tip">{state.ui.selectedItem ? `${ITEM_META[state.ui.selectedItem].name} · 双击查看` : "可拖动 · 双击查看"}</p>
          </div>
        ) : null}
      </aside>

      {ghostElement ? createPortal(ghostElement, document.body) : null}
      <ItemInspectDialog
        open={inspectedItem !== null}
        itemId={inspectedItem}
        variant="phone"
        portalRoot={barRef.current?.closest(".phone-frame")}
        onClose={() => setInspectedItem(null)}
      />
    </>
  );
}
