#!/usr/bin/env python3
"""Calibrate collision and runtime metadata for the approved wide campus plate."""

from __future__ import annotations

import base64
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
PLATE_PATH = ROOT / "src/assets/rpg/campus/zijingang_campus_plate.png"
MASK_PATH = ROOT / "src/assets/rpg/campus/zijingang_road_walkability_mask.png"
RUNTIME_PATH = ROOT / "src/data/maps/zijingang-campus-runtime.json"

WORLD_WIDTH = 11744
WORLD_HEIGHT = 1084
CELL_SIZE = 4

# Walkable pixels describe ground beneath the shared player foot box.  The old
# texture classifier fragmented the asphalt and paving whenever it encountered a
# drain, lane marking, shadow, or a slightly different paving colour.  The wide
# panorama has a stable foreground promenade, so source-pixel geometry is both
# more accurate and reproducible than classifying the rendered colours.
# The visible roadside pavement begins at y=864 across the complete panorama.
# Keeping the former y=880 cutoff left the canonical player foot box partly
# inside the blocked band at the y=842 story checkpoint, so stepping sideways
# away from an entrance immediately hit an invisible wall.
PROMENADE_SURFACE_TOP = 864

# Each entry is a visible paved route from the continuous foreground promenade
# to a building entrance.  These are intentionally narrow enough to leave the
# adjacent flower beds, fences, water, and facades solid.
ENTRANCE_APPROACHES = (
    {"id": "dining_hall", "left": 560, "right": 930, "top": 700},
    {"id": "west_round_hall", "left": 5440, "right": 5750, "top": 744},
    {"id": "museum", "left": 7580, "right": 7770, "top": 720},
)

# Several visible campus walks are angled instead of rectangular. Keeping their
# source-pixel outlines opens the paved route without opening the flower bed or
# fence beside it.
PUBLIC_PATH_POLYGONS = (
    {
        "id": "museum_central_gate",
        "points": ((6130, 880), (6270, 880), (6260, 720), (6150, 720)),
    },
    {
        "id": "east_riverside_walk",
        "points": ((9940, 900), (10060, 900), (9955, 600), (9870, 600)),
    },
    {
        "id": "east_main_hall_walk",
        "points": ((11030, 900), (11190, 900), (10965, 690), (10880, 690)),
    },
    {
        # The library flower bed blocks the straight line below the door.  This
        # L-shaped route follows the real right-side gap and then the paved
        # forecourt, so the player can reach the entrance without crossing soil.
        "id": "foundation_library_entry",
        "points": (
            (9120, 864),
            (9180, 864),
            (9180, 812),
            (9300, 812),
            (9300, 760),
            (8750, 760),
            (8750, 812),
            (9120, 812),
        ),
    },
)

# The canteen forecourt is wider than its doorway.  This polygon follows the
# visible stone paving while keeping the billboard, bins, utility cabinet, and
# surrounding lawn outside the playable ground.
CANTEEN_FORECOURT = (
    (100, 744),
    (1260, 744),
    (1430, PROMENADE_SURFACE_TOP),
    (0, PROMENADE_SURFACE_TOP),
)

# Foreground props inside otherwise walkable paving retain a compact collision
# footprint.  Coordinates are measured from the final panorama, not inferred
# from colour or browser viewport size.
FOREGROUND_OBSTACLES = (
    {"id": "canteen_billboard", "left": 88, "right": 330, "top": 760, "bottom": 887},
    {"id": "canteen_vending_machine", "left": 350, "right": 456, "top": 736, "bottom": 874},
    {"id": "canteen_bins", "left": 322, "right": 474, "top": 850, "bottom": 904},
    {"id": "canteen_utility_box", "left": 1284, "right": 1396, "top": 776, "bottom": 900},
)

# The regenerated east plate places the library door at x=9000. Interaction and
# collision use the same source coordinate, leaving both flower beds blocked.
LIBRARY_GATE = {"x": 9000, "y": 770, "radius": 100}
LIBRARY_APPROACH = {"x": 9070, "y": 770}
FOUNDATION_LIBRARY = {"x": 9000, "y": 690}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def aligned_cell(value: int, *, edge: str) -> int:
    if edge == "start":
        return value // CELL_SIZE
    return (value + CELL_SIZE - 1) // CELL_SIZE


def grid_rect(
    grid: np.ndarray,
    *,
    left: int,
    right: int,
    top: int,
    bottom: int,
    walkable: bool,
) -> None:
    grid[
        aligned_cell(top, edge="start"):aligned_cell(bottom, edge="end"),
        aligned_cell(left, edge="start"):aligned_cell(right, edge="end"),
    ] = walkable


def build_walkability_grid() -> np.ndarray:
    grid_width = WORLD_WIDTH // CELL_SIZE
    grid_height = WORLD_HEIGHT // CELL_SIZE
    grid = np.zeros((grid_height, grid_width), dtype=bool)

    # One connected road-and-sidewalk surface removes false walls at every lane
    # marking, drain, curb shadow, and stitched scene boundary.
    grid_rect(
        grid,
        left=0,
        right=WORLD_WIDTH,
        top=PROMENADE_SURFACE_TOP,
        bottom=WORLD_HEIGHT,
        walkable=True,
    )

    polygon = [
        (int(round(x / CELL_SIZE)), int(round(y / CELL_SIZE)))
        for x, y in CANTEEN_FORECOURT
    ]
    polygon_mask = Image.new("1", (grid_width, grid_height), 0)
    ImageDraw.Draw(polygon_mask).polygon(polygon, fill=1)
    grid |= np.asarray(polygon_mask, dtype=bool)

    for approach in ENTRANCE_APPROACHES:
        grid_rect(
            grid,
            left=approach["left"],
            right=approach["right"],
            top=approach["top"],
            bottom=WORLD_HEIGHT,
            walkable=True,
        )

    for path in PUBLIC_PATH_POLYGONS:
        polygon = [
            (int(round(x / CELL_SIZE)), int(round(y / CELL_SIZE)))
            for x, y in path["points"]
        ]
        path_mask = Image.new("1", (grid_width, grid_height), 0)
        ImageDraw.Draw(path_mask).polygon(polygon, fill=1)
        grid |= np.asarray(path_mask, dtype=bool)

    for obstacle in FOREGROUND_OBSTACLES:
        grid_rect(
            grid,
            left=obstacle["left"],
            right=obstacle["right"],
            top=obstacle["top"],
            bottom=obstacle["bottom"],
            walkable=False,
        )

    return grid


def main() -> None:
    plate = Image.open(PLATE_PATH).convert("RGB")
    if plate.size != (WORLD_WIDTH, WORLD_HEIGHT):
        raise RuntimeError(
            f"Wide campus plate must be {WORLD_WIDTH}x{WORLD_HEIGHT}; received "
            f"{plate.width}x{plate.height}"
        )

    grid_width = WORLD_WIDTH // CELL_SIZE
    grid_height = WORLD_HEIGHT // CELL_SIZE
    grid = build_walkability_grid()

    mask_image = Image.fromarray((grid * 255).astype(np.uint8), mode="L").resize(
        (WORLD_WIDTH, WORLD_HEIGHT),
        Image.Resampling.NEAREST,
    )
    mask_image.save(MASK_PATH, format="PNG", optimize=True)

    packed = np.packbits(grid.reshape(-1), bitorder="little").tobytes()
    plate_digest = sha256(PLATE_PATH)
    mask_digest = sha256(MASK_PATH)
    bitset_digest = hashlib.sha256(packed).hexdigest()

    runtime = json.loads(RUNTIME_PATH.read_text(encoding="utf-8"))
    runtime["source"]["plateSha256"] = plate_digest
    runtime["source"]["worldScale"] = (
        "single 11744px x 1084px side-view panorama stitched from 9 generated campus scenes; "
        "west and middle joins use source-aligned local transitions, the former x=8939 and "
        "x=10133 east joins are replaced by one continuous regenerated campus strip, and a "
        "coherent sky treatment removes the former placeholder bands"
    )
    runtime["world"] = {"width": WORLD_WIDTH, "height": WORLD_HEIGHT}
    runtime["libraryGate"] = LIBRARY_GATE
    for landmark in runtime.get("landmarks", []):
        if landmark.get("id") == "foundation_library":
            landmark.update(FOUNDATION_LIBRARY)
            break

    runtime["walkability"] = {
        "cellSize": CELL_SIZE,
        "gridWidth": grid_width,
        "gridHeight": grid_height,
        "bitOrder": "little",
        "bitsBase64": base64.b64encode(packed).decode("ascii"),
        "walkableCells": int(grid.sum()),
        "totalCells": int(grid.size),
        "maskSha256": mask_digest,
        "bitsetSha256": bitset_digest,
        "sourcePlateSha256": plate_digest,
        "gateApproach": LIBRARY_APPROACH,
        "promenadeSurfaceTop": PROMENADE_SURFACE_TOP,
        "entranceApproaches": list(ENTRANCE_APPROACHES),
        "publicPathPolygons": [
            {"id": path["id"], "points": [list(point) for point in path["points"]]}
            for path in PUBLIC_PATH_POLYGONS
        ],
        "foregroundObstacles": list(FOREGROUND_OBSTACLES),
    }
    RUNTIME_PATH.write_text(
        json.dumps(runtime, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print(
        f"calibrated wide campus {WORLD_WIDTH}x{WORLD_HEIGHT} "
        f"walkable={int(grid.sum())}/{grid.size} "
        f"libraryGate={LIBRARY_GATE['x']},{LIBRARY_GATE['y']} "
        f"approach={LIBRARY_APPROACH['x']},{LIBRARY_APPROACH['y']} "
        f"plateSha256={plate_digest} maskSha256={mask_digest} "
        f"bitsetSha256={bitset_digest}"
    )


if __name__ == "__main__":
    main()
