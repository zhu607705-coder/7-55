import { describe, expect, it } from "vitest";
import {
  acceptsLibraryItem,
  findLibraryTargetAt,
  findNearestLibraryTarget,
  getLibraryTarget,
  getVisibleLibraryMarkerIds,
  isPointInsideLibraryCollision,
  LIBRARY_CHECKPOINT_SPAWNS,
  LIBRARY_ENTRANCE_DOOR,
  LIBRARY_INTERACTION_TARGETS,
  LIBRARY_INTERIOR_WORLD,
  LIBRARY_STATIC_COLLISION_RECTS,
  shouldOpenLibraryEntranceDoor
} from "./LibraryInteriorModel";

describe("LibraryInteriorModel", () => {
  it("resolves the shelf drop zone independently from render scale", () => {
    const target = findLibraryTargetAt(548, 230, LIBRARY_INTERACTION_TARGETS);
    expect(target?.id).toBe("library_shelf_755");
    expect(target && acceptsLibraryItem(target, "callNumber755")).toBe(true);
    expect(target && acceptsLibraryItem(target, "rightArrow")).toBe(false);
  });

  it("keeps the reusable arrow and one-use PASS on separate target zones", () => {
    const gap = findLibraryTargetAt(1368, 445, LIBRARY_INTERACTION_TARGETS);
    const backpack = findLibraryTargetAt(1330, 410, LIBRARY_INTERACTION_TARGETS);
    expect(gap?.id).toBe("seat_022_gap");
    expect(gap && acceptsLibraryItem(gap, "rightArrow")).toBe(true);
    expect(backpack?.id).toBe("seat_022_backpack");
    expect(backpack && acceptsLibraryItem(backpack, "seatReleasePass")).toBe(true);
  });

  it("uses target-specific proximity for contextual interaction", () => {
    const seat = getLibraryTarget("seat_022_chair");
    expect(findNearestLibraryTarget(seat.x + 50, seat.y, [seat])?.id).toBe("seat_022_chair");
    expect(findNearestLibraryTarget(seat.x + 140, seat.y, [seat])).toBeNull();
  });

  it("provides stable named spawns for phone round trips", () => {
    expect(LIBRARY_CHECKPOINT_SPAWNS.library_entrance).toEqual({ x: 715, y: 842 });
    expect(LIBRARY_CHECKPOINT_SPAWNS.library_seat_022).toEqual({ x: 1180, y: 505 });
  });

  it("keeps the entrance closed until the record grants access", () => {
    const spawn = LIBRARY_CHECKPOINT_SPAWNS.library_entrance;
    expect(shouldOpenLibraryEntranceDoor(false, spawn.x, spawn.y)).toBe(false);
    expect(shouldOpenLibraryEntranceDoor(true, spawn.x, spawn.y)).toBe(true);
    expect(shouldOpenLibraryEntranceDoor(true, LIBRARY_ENTRANCE_DOOR.x + 220, LIBRARY_ENTRANCE_DOOR.y)).toBe(false);
    expect(shouldOpenLibraryEntranceDoor(true, LIBRARY_ENTRANCE_DOOR.x, LIBRARY_ENTRANCE_DOOR.y - 180)).toBe(false);
  });

  it("shows only the nearest marker during ordinary exploration", () => {
    const nearest = getLibraryTarget("front_desk");
    expect(getVisibleLibraryMarkerIds(LIBRARY_INTERACTION_TARGETS, nearest, null)).toEqual(["front_desk"]);
    expect(getVisibleLibraryMarkerIds(LIBRARY_INTERACTION_TARGETS, null, null)).toEqual([]);
  });

  it("switches marker focus to the matching drop target while an item is selected", () => {
    const nearest = getLibraryTarget("front_desk");
    expect(getVisibleLibraryMarkerIds(LIBRARY_INTERACTION_TARGETS, nearest, "callNumber755"))
      .toEqual(["library_shelf_755"]);
    expect(getVisibleLibraryMarkerIds(LIBRARY_INTERACTION_TARGETS, nearest, "rightArrow"))
      .toEqual(["seat_022_gap"]);
  });

  it("falls back to the nearest marker when the selected item has no active target", () => {
    const nearest = getLibraryTarget("catalog_terminal");
    expect(getVisibleLibraryMarkerIds(LIBRARY_INTERACTION_TARGETS, nearest, "campusCard"))
      .toEqual(["catalog_terminal"]);
  });

  it("keeps every source-pixel collision inside the 1500 by 900 interior", () => {
    const ids = new Set<string>();
    LIBRARY_STATIC_COLLISION_RECTS.forEach((rect) => {
      expect(ids.has(rect.id)).toBe(false);
      ids.add(rect.id);
      expect(rect.left).toBeGreaterThanOrEqual(0);
      expect(rect.top).toBeGreaterThanOrEqual(0);
      expect(rect.right).toBeLessThanOrEqual(LIBRARY_INTERIOR_WORLD.width);
      expect(rect.bottom).toBeLessThanOrEqual(LIBRARY_INTERIOR_WORLD.height);
      expect(rect.right).toBeGreaterThan(rect.left);
      expect(rect.bottom).toBeGreaterThan(rect.top);
    });
  });

  it("blocks the visible north wall and the centers of authored shelf pixels", () => {
    expect(isPointInsideLibraryCollision(544, 50)).toBe(true);
    expect(isPointInsideLibraryCollision(544, 100)).toBe(true);
    expect(isPointInsideLibraryCollision(500, 110)).toBe(false);
    expect(isPointInsideLibraryCollision(145, 200)).toBe(true);
    expect(isPointInsideLibraryCollision(224, 200)).toBe(true);
    expect(isPointInsideLibraryCollision(548, 180)).toBe(true);
    expect(isPointInsideLibraryCollision(808, 200)).toBe(true);
  });

  it("leaves the visible upper aisles and cross aisle traversable", () => {
    expect(isPointInsideLibraryCollision(185, 220)).toBe(false);
    expect(isPointInsideLibraryCollision(265, 220)).toBe(false);
    expect(isPointInsideLibraryCollision(425, 220)).toBe(false);
    expect(isPointInsideLibraryCollision(620, 350)).toBe(false);
    expect(isPointInsideLibraryCollision(870, 350)).toBe(false);
  });

  it("follows the visible diagonal railing without blocking its clear triangles", () => {
    expect(isPointInsideLibraryCollision(935, 490)).toBe(true);
    expect(isPointInsideLibraryCollision(954, 509)).toBe(true);
    expect(isPointInsideLibraryCollision(978, 535)).toBe(true);
    expect(isPointInsideLibraryCollision(1005, 490)).toBe(false);
    expect(isPointInsideLibraryCollision(935, 530)).toBe(false);
  });

  it("keeps the source-pixel opening between the reading-room posts traversable", () => {
    expect(isPointInsideLibraryCollision(990, 545)).toBe(true);
    expect(isPointInsideLibraryCollision(1080, 545)).toBe(true);
    expect(isPointInsideLibraryCollision(1038, 520)).toBe(false);
    expect(isPointInsideLibraryCollision(1038, 550)).toBe(false);
    expect(isPointInsideLibraryCollision(1038, 580)).toBe(false);
    expect(isPointInsideLibraryCollision(1026, 550)).toBe(false);
    expect(isPointInsideLibraryCollision(1050, 550)).toBe(false);
  });

  it("blocks the visible south railing and planters while leaving adjacent floor clear", () => {
    expect(isPointInsideLibraryCollision(1180, 545)).toBe(true);
    expect(isPointInsideLibraryCollision(1360, 548)).toBe(true);
    expect(isPointInsideLibraryCollision(1120, 570)).toBe(true);
    expect(isPointInsideLibraryCollision(1255, 570)).toBe(true);
    expect(isPointInsideLibraryCollision(1180, 510)).toBe(false);
    expect(isPointInsideLibraryCollision(1180, 590)).toBe(false);
  });

  it("blocks the visible reading-room edge planters", () => {
    expect(isPointInsideLibraryCollision(950, 455)).toBe(true);
    expect(isPointInsideLibraryCollision(1400, 470)).toBe(true);
  });

  it("uses separate furniture footprints instead of blocking the full catalog carpet", () => {
    expect(isPointInsideLibraryCollision(600, 550)).toBe(false);
    expect(isPointInsideLibraryCollision(750, 630)).toBe(false);
    expect(isPointInsideLibraryCollision(765, 550)).toBe(false);
    expect(isPointInsideLibraryCollision(700, 550)).toBe(true);
    expect(isPointInsideLibraryCollision(825, 555)).toBe(true);
  });

  it("keeps both entrance walking lanes clear between the fixed turnstiles", () => {
    expect(isPointInsideLibraryCollision(715, 842)).toBe(false);
    expect(isPointInsideLibraryCollision(785, 842)).toBe(false);
    expect(isPointInsideLibraryCollision(681, 842)).toBe(true);
    expect(isPointInsideLibraryCollision(820, 842)).toBe(true);
  });

  it("keeps every interior checkpoint spawn on visible walkable floor", () => {
    const interiorSpawns = Object.entries(LIBRARY_CHECKPOINT_SPAWNS)
      .filter(([checkpoint]) => checkpoint !== "campus_library_gate")
      .map(([, spawn]) => spawn);
    interiorSpawns.forEach((spawn) => {
      expect(isPointInsideLibraryCollision(spawn.x, spawn.y)).toBe(false);
    });
  });
});
