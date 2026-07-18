import { describe, expect, it } from "vitest";
import type { ItemId } from "../core/types";
import { isPaperItem, ITEM_CATALOG } from "./itemCatalog";

const PAPER_ITEMS: ItemId[] = [
  "occupancyNote",
  "callNumber755",
  "archivedLeaveRule",
  "itemRecognitionReport",
  "bagNonPersonProof",
  "seat022Receipt",
  "libraryPresenceProof",
  "seatReleasePass"
];

describe("ITEM_CATALOG paper and lifecycle contract", () => {
  it("provides complete readable content for all eight paper items", () => {
    expect(PAPER_ITEMS).toHaveLength(8);
    for (const item of PAPER_ITEMS) {
      const entry = ITEM_CATALOG[item];
      expect(isPaperItem(item), item).toBe(true);
      expect(entry.inspectKind, item).toBe("paper");
      expect(entry.document?.heading.trim(), item).toBeTruthy();
      expect(entry.document?.fields.length, item).toBeGreaterThan(0);
      expect(entry.document?.body.length, item).toBeGreaterThan(0);
    }
  });

  it("keeps the two-stage evidence lifecycle and consumes one-use papers", () => {
    expect(ITEM_CATALOG.bagNonPersonProof.uses.map(({ result }) => result)).toEqual(["retain", "consume"]);
    expect(ITEM_CATALOG.seat022Receipt.uses.map(({ result }) => result)).toEqual(["retain", "consume"]);
    expect(ITEM_CATALOG.libraryPresenceProof.uses.map(({ result }) => result)).toEqual(["retain", "consume"]);
    expect(ITEM_CATALOG.occupancyNote.uses).toEqual([{ target: "cc98-search", result: "consume" }]);
    expect(ITEM_CATALOG.callNumber755.uses).toEqual([{ target: "library-shelf-755", result: "consume" }]);
    expect(ITEM_CATALOG.seatReleasePass.uses).toEqual([{ target: "seat-022-backpack", result: "consume" }]);
  });

  it("retains the arrow for balance movement and consumes it for the 022 receipt", () => {
    expect(ITEM_CATALOG.rightArrow.uses).toEqual([
      { target: "campus-card-balance", result: "retain" },
      { target: "seat-022-gap", result: "consume" }
    ]);
  });
});
