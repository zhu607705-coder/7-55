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
