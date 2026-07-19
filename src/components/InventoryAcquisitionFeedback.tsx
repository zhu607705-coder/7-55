import { useEffect, useRef, useState } from "react";
import type { ItemId } from "../core/types";
import { PixelIcon } from "./PixelIcon";

const ITEM_ACQUISITION_FEEDBACK_MS = 1150;

/** Keeps phone and RPG inventory acquisition feedback on the same state-diff contract. */
export function useRecentInventoryItem(ownedItems: readonly ItemId[]): ItemId | null {
  const [recentItem, setRecentItem] = useState<ItemId | null>(null);
  const previousOwnedRef = useRef<Set<ItemId>>(new Set(ownedItems));
  const ownedSignature = ownedItems.join("|");

  useEffect(() => {
    const previousOwned = previousOwnedRef.current;
    const addedItem = ownedItems.find((item) => !previousOwned.has(item)) ?? null;
    previousOwnedRef.current = new Set(ownedItems);
    if (!addedItem) {
      return undefined;
    }

    setRecentItem(addedItem);
    const timer = window.setTimeout(() => setRecentItem(null), ITEM_ACQUISITION_FEEDBACK_MS);
    return () => window.clearTimeout(timer);
  }, [ownedSignature]);

  return recentItem;
}

interface InventoryAcquisitionFlightProps {
  item: ItemId | null;
  className: string;
}

export function InventoryAcquisitionFlight({ item, className }: InventoryAcquisitionFlightProps) {
  if (!item) {
    return null;
  }

  return (
    <span className={className} aria-hidden="true">
      <PixelIcon name={item} size={28} />
      <i /><i /><i />
    </span>
  );
}
