#!/usr/bin/env python3
"""Calibrate collision and runtime metadata for the approved wide campus plate."""

from __future__ import annotations

import base64
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
PLATE_PATH = ROOT / "src/assets/rpg/campus/zijingang_campus_plate.png"
MASK_PATH = ROOT / "src/assets/rpg/campus/zijingang_road_walkability_mask.png"
RUNTIME_PATH = ROOT / "src/data/maps/zijingang-campus-runtime.json"

WORLD_WIDTH = 11744
WORLD_HEIGHT = 1084
CELL_SIZE = 4

# The visible south approach is the clear stone path between the two flower beds.
# Keep the corridor narrower than the artwork so the fixed player foot box cannot
# touch the trees, shrubs, or lamp on either side.
LIBRARY_CORRIDOR = {
    "left": 9072,
    "right": 9172,
    "top": 760,
    "bottom": WORLD_HEIGHT,
}
LIBRARY_GATE = {"x": 9120, "y": 780, "radius": 80}
LIBRARY_APPROACH = {"x": 9120, "y": 824}
FOUNDATION_LIBRARY = {"x": 9120, "y": 700}

# The theater door is visible in the round building at x≈7730. Its front path
# runs through a flower-bed gap to the road. Carve only that measured path so
# the marker stays physically reachable without opening the surrounding facade.
THEATER_CORRIDOR = {
    "left": 7672,
    "right": 7788,
    "top": 700,
    "bottom": WORLD_HEIGHT,
}
THEATER_GATE = {"x": 7730, "y": 735, "radius": 86}
THEATER_APPROACH = {"x": 7730, "y": 840}

# The Qizhen Lake story branches from the open sidewalk west of the theater.
# This gate already sits on the approved road mask and therefore needs no
# additional carving; it remains a real campus-walk destination.
QIZHEN_GATE = {"x": 7080, "y": 900, "radius": 92}
QIZHEN_APPROACH = {"x": 7160, "y": 930}


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


def main() -> None:
    plate = Image.open(PLATE_PATH).convert("RGB")
    if plate.size != (WORLD_WIDTH, WORLD_HEIGHT):
        raise RuntimeError(
            f"Wide campus plate must be {WORLD_WIDTH}x{WORLD_HEIGHT}; received "
            f"{plate.width}x{plate.height}"
        )

    mask = Image.open(MASK_PATH).convert("L")
    if mask.size != plate.size:
        raise RuntimeError("Campus walkability mask dimensions do not match the wide plate")

    grid_width = WORLD_WIDTH // CELL_SIZE
    grid_height = WORLD_HEIGHT // CELL_SIZE
    grid = np.asarray(
        mask.resize((grid_width, grid_height), Image.Resampling.NEAREST),
        dtype=np.uint8,
    ) >= 128

    left = aligned_cell(LIBRARY_CORRIDOR["left"], edge="start")
    right = aligned_cell(LIBRARY_CORRIDOR["right"], edge="end")
    top = aligned_cell(LIBRARY_CORRIDOR["top"], edge="start")
    bottom = aligned_cell(LIBRARY_CORRIDOR["bottom"], edge="end")
    grid[top:bottom, left:right] = True

    theater_left = aligned_cell(THEATER_CORRIDOR["left"], edge="start")
    theater_right = aligned_cell(THEATER_CORRIDOR["right"], edge="end")
    theater_top = aligned_cell(THEATER_CORRIDOR["top"], edge="start")
    theater_bottom = aligned_cell(THEATER_CORRIDOR["bottom"], edge="end")
    grid[theater_top:theater_bottom, theater_left:theater_right] = True

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
        "the scene-2/3 road seam is vertically aligned by 32px, the duplicated scene-5/6 "
        "overlap at source x=5700..7000 is removed, and the museum join at x=7079 uses a "
        "locally blended transition"
    )
    runtime["world"] = {"width": WORLD_WIDTH, "height": WORLD_HEIGHT}
    runtime["libraryGate"] = LIBRARY_GATE
    runtime["theaterGate"] = THEATER_GATE
    runtime["qizhenGate"] = QIZHEN_GATE
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
        "theaterApproach": THEATER_APPROACH,
        "qizhenApproach": QIZHEN_APPROACH,
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
        f"theaterGate={THEATER_GATE['x']},{THEATER_GATE['y']} "
        f"theaterApproach={THEATER_APPROACH['x']},{THEATER_APPROACH['y']} "
        f"qizhenGate={QIZHEN_GATE['x']},{QIZHEN_GATE['y']} "
        f"plateSha256={plate_digest} maskSha256={mask_digest} "
        f"bitsetSha256={bitset_digest}"
    )


if __name__ == "__main__":
    main()
