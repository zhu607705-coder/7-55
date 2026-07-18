#!/usr/bin/env python3
"""Build the canonical top-down campus mosaic and its road walkability grid."""

from __future__ import annotations

import argparse
import base64
import hashlib
import json
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "src/assets/rpg/campus/source/mosaic"
PLATE_PATH = ROOT / "src/assets/rpg/campus/zijingang_campus_plate.png"
MASK_PATH = SOURCE_DIR / "zijingang_road_walkability_mask.png"
RUNTIME_PATH = ROOT / "src/data/maps/zijingang-campus-runtime.json"

GRID_SIZE = 4
TILE_SIZE = 960
WORLD_SIZE = GRID_SIZE * TILE_SIZE
SEAM_ROAD_WIDTH = 80
SEAM_ASPHALT_WIDTH = 62
WALK_GRID_CELL = 8
PLAYER_FOOT_CLEARANCE = 9

LAYOUT = (
    (1, 2, 3, 4),
    (5, 6, 7, 8),
    (9, 10, 11, 12),
    (13, 14, 15, 16),
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def normalize_tile(path: Path) -> tuple[Image.Image, dict[str, object]]:
    source = Image.open(path).convert("RGB")
    side = min(source.width, source.height)
    left = (source.width - side) // 2
    top = (source.height - side) // 2
    crop = (left, top, left + side, top + side)
    normalized = source.crop(crop).resize((TILE_SIZE, TILE_SIZE), Image.Resampling.LANCZOS)
    return normalized, {
        "source": path.name,
        "sourceWidth": source.width,
        "sourceHeight": source.height,
        "crop": {"x": left, "y": top, "width": side, "height": side},
        "sha256": sha256(path),
    }


def extract_boundary_roads(tile: Image.Image) -> np.ndarray:
    pixels = np.asarray(tile, dtype=np.float32)
    smooth = np.stack(
        [ndimage.gaussian_filter(pixels[:, :, channel], sigma=3.0) for channel in range(3)],
        axis=2,
    )
    maximum = smooth.max(axis=2)
    minimum = smooth.min(axis=2)
    mean = smooth.mean(axis=2)
    chroma = maximum - minimum
    green_excess = smooth[:, :, 1] - (smooth[:, :, 0] + smooth[:, :, 2]) * 0.5
    grayscale = pixels.mean(axis=2)
    local_mean = ndimage.uniform_filter(grayscale, size=11)
    local_variance = ndimage.uniform_filter(grayscale * grayscale, size=11) - local_mean * local_mean
    local_std = np.sqrt(np.maximum(0, local_variance))

    candidates = (
        (mean >= 28)
        & (mean <= 92)
        & (chroma <= 10)
        & (green_excess <= 5)
        & (local_std <= 23)
    )
    candidates = ndimage.binary_closing(candidates, structure=np.ones((17, 17), dtype=bool))
    candidates = ndimage.binary_opening(candidates, structure=np.ones((5, 5), dtype=bool))

    labels, count = ndimage.label(candidates)
    component_sizes = np.bincount(labels.ravel())
    border_labels = np.unique(
        np.concatenate(
            (
                labels[:32, :].ravel(),
                labels[-32:, :].ravel(),
                labels[:, :32].ravel(),
                labels[:, -32:].ravel(),
            )
        )
    )
    keep = np.zeros(count + 1, dtype=bool)
    for label in border_labels:
        if label and component_sizes[label] >= 700:
            keep[label] = True

    roads = keep[labels]
    roads = ndimage.binary_closing(roads, structure=np.ones((21, 21), dtype=bool))
    return roads


def block_noise(height: int, width: int, seed: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    small_height = math.ceil(height / 4)
    small_width = math.ceil(width / 4)
    noise = rng.integers(-5, 6, size=(small_height, small_width), dtype=np.int16)
    return np.repeat(np.repeat(noise, 4, axis=0), 4, axis=1)[:height, :width]


def make_vertical_road(height: int, seed: int) -> Image.Image:
    width = SEAM_ROAD_WIDTH
    noise = block_noise(height, width, seed)
    strip = np.empty((height, width, 3), dtype=np.int16)
    strip[:, :, :] = np.array((51, 55, 56), dtype=np.int16)
    strip += noise[:, :, None]
    strip = np.clip(strip, 0, 255).astype(np.uint8)
    road = Image.fromarray(strip, mode="RGB")
    draw = ImageDraw.Draw(road)
    curb = (145, 142, 129)
    curb_light = (196, 191, 171)
    for x in (0, width - 9):
        draw.rectangle((x, 0, x + 8, height), fill=curb)
    draw.line((9, 0, 9, height), fill=curb_light, width=2)
    draw.line((width - 11, 0, width - 11, height), fill=curb_light, width=2)
    for y in range(14, height, 42):
        draw.rectangle((width // 2 - 1, y, width // 2 + 1, min(height, y + 20)), fill=(198, 188, 139))
    return road


def make_horizontal_road(width: int, seed: int) -> Image.Image:
    height = SEAM_ROAD_WIDTH
    noise = block_noise(height, width, seed)
    strip = np.empty((height, width, 3), dtype=np.int16)
    strip[:, :, :] = np.array((51, 55, 56), dtype=np.int16)
    strip += noise[:, :, None]
    strip = np.clip(strip, 0, 255).astype(np.uint8)
    road = Image.fromarray(strip, mode="RGB")
    draw = ImageDraw.Draw(road)
    curb = (145, 142, 129)
    curb_light = (196, 191, 171)
    for y in (0, height - 9):
        draw.rectangle((0, y, width, y + 8), fill=curb)
    draw.line((0, 9, width, 9), fill=curb_light, width=2)
    draw.line((0, height - 11, width, height - 11), fill=curb_light, width=2)
    for x in range(14, width, 42):
        draw.rectangle((x, height // 2 - 1, min(width, x + 20), height // 2 + 1), fill=(198, 188, 139))
    return road


def paint_seam_roads(mosaic: Image.Image, walkable: np.ndarray) -> None:
    half_road = SEAM_ROAD_WIDTH // 2
    half_asphalt = SEAM_ASPHALT_WIDTH // 2
    for index in range(1, GRID_SIZE):
        center = index * TILE_SIZE
        mosaic.paste(make_vertical_road(WORLD_SIZE, 7550 + index), (center - half_road, 0))
        walkable[:, center - half_asphalt : center + half_asphalt] = True
        mosaic.paste(make_horizontal_road(WORLD_SIZE, 7555 + index), (0, center - half_road))
        walkable[center - half_asphalt : center + half_asphalt, :] = True


def nearest_walkable(mask: np.ndarray, target_x: int, target_y: int) -> tuple[int, int]:
    if mask[target_y, target_x]:
        return target_x, target_y
    ys, xs = np.nonzero(mask)
    distances = (xs - target_x) ** 2 + (ys - target_y) ** 2
    nearest = int(np.argmin(distances))
    return int(xs[nearest]), int(ys[nearest])


def encode_walkability(mask: np.ndarray) -> dict[str, object]:
    height, width = mask.shape
    if width % WALK_GRID_CELL or height % WALK_GRID_CELL:
        raise ValueError("World dimensions must be divisible by the walkability cell size")
    grid = mask.reshape(
        height // WALK_GRID_CELL,
        WALK_GRID_CELL,
        width // WALK_GRID_CELL,
        WALK_GRID_CELL,
    ).mean(axis=(1, 3)) >= 0.72
    grid = ndimage.binary_closing(grid, structure=np.ones((3, 3), dtype=bool))
    packed = np.packbits(grid.reshape(-1), bitorder="little")
    return {
        "cellSize": WALK_GRID_CELL,
        "gridWidth": int(grid.shape[1]),
        "gridHeight": int(grid.shape[0]),
        "bitsBase64": base64.b64encode(packed.tobytes()).decode("ascii"),
        "walkableCells": int(grid.sum()),
        "totalCells": int(grid.size),
    }


def build(qa_output: Path | None) -> None:
    mosaic = Image.new("RGB", (WORLD_SIZE, WORLD_SIZE), (29, 35, 31))
    walkable = np.zeros((WORLD_SIZE, WORLD_SIZE), dtype=bool)
    tile_manifest: list[dict[str, object]] = []

    for row, layout_row in enumerate(LAYOUT):
        for column, tile_number in enumerate(layout_row):
            path = SOURCE_DIR / f"tile_{tile_number:02}.png"
            if not path.exists():
                raise FileNotFoundError(path)
            tile, metadata = normalize_tile(path)
            x = column * TILE_SIZE
            y = row * TILE_SIZE
            mosaic.paste(tile, (x, y))
            walkable[y : y + TILE_SIZE, x : x + TILE_SIZE] |= extract_boundary_roads(tile)
            tile_manifest.append(
                {
                    "id": f"tile_{tile_number:02}",
                    "row": row,
                    "column": column,
                    "worldRect": {"x": x, "y": y, "width": TILE_SIZE, "height": TILE_SIZE},
                    **metadata,
                }
            )

    paint_seam_roads(mosaic, walkable)
    walkable = ndimage.binary_closing(walkable, structure=np.ones((9, 9), dtype=bool))
    walkable = ndimage.binary_erosion(walkable, iterations=PLAYER_FOOT_CLEARANCE)

    spawn_x, spawn_y = nearest_walkable(walkable, WORLD_SIZE // 2, WORLD_SIZE - 64)
    labels, _ = ndimage.label(walkable)
    spawn_component = labels[spawn_y, spawn_x]
    if spawn_component == 0:
        raise RuntimeError("Spawn is not connected to a walkable road")
    walkable = labels == spawn_component

    library_x, library_y = nearest_walkable(walkable, TILE_SIZE // 2, 120)
    if not walkable[library_y, library_x]:
        raise RuntimeError("Library entrance is not on the generated road mask")

    PLATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    mosaic.save(PLATE_PATH, optimize=True, compress_level=9)
    Image.fromarray((walkable * 255).astype(np.uint8), mode="L").save(MASK_PATH, optimize=True)

    runtime = {
        "source": {
            "kind": "user-selected-top-down-mosaic",
            "projection": "top-down-90deg",
            "northUp": True,
            "layout": [list(row) for row in LAYOUT],
            "tileSize": TILE_SIZE,
            "seamRoadWidth": SEAM_ROAD_WIDTH,
            "plateSha256": sha256(PLATE_PATH),
        },
        "world": {"width": WORLD_SIZE, "height": WORLD_SIZE},
        "spawn": {"x": spawn_x, "y": spawn_y},
        "libraryGate": {"x": library_x, "y": library_y, "radius": 88},
        "walkability": encode_walkability(walkable),
        "tiles": tile_manifest,
    }
    RUNTIME_PATH.write_text(json.dumps(runtime, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")

    if qa_output:
        qa_output.parent.mkdir(parents=True, exist_ok=True)
        preview = mosaic.resize((1280, 1280), Image.Resampling.LANCZOS)
        preview_mask = Image.fromarray((walkable * 150).astype(np.uint8), mode="L").resize(
            preview.size, Image.Resampling.NEAREST
        )
        overlay = Image.new("RGB", preview.size, (25, 220, 105))
        preview = Image.composite(overlay, preview, preview_mask)
        draw = ImageDraw.Draw(preview)
        scale = preview.width / WORLD_SIZE
        draw.ellipse(
            (
                spawn_x * scale - 8,
                spawn_y * scale - 8,
                spawn_x * scale + 8,
                spawn_y * scale + 8,
            ),
            fill=(255, 220, 55),
            outline=(255, 255, 255),
            width=3,
        )
        draw.ellipse(
            (
                library_x * scale - 8,
                library_y * scale - 8,
                library_x * scale + 8,
                library_y * scale + 8,
            ),
            fill=(70, 160, 255),
            outline=(255, 255, 255),
            width=3,
        )
        preview.save(qa_output, optimize=True)

    coverage = 100 * float(walkable.mean())
    print(f"plate={PLATE_PATH.relative_to(ROOT)} {WORLD_SIZE}x{WORLD_SIZE}")
    print(f"runtime={RUNTIME_PATH.relative_to(ROOT)}")
    print(f"spawn=({spawn_x},{spawn_y}) library=({library_x},{library_y})")
    print(f"walkable={coverage:.2f}% sha256={runtime['source']['plateSha256']}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--qa-output", type=Path, default=None)
    args = parser.parse_args()
    build(args.qa_output)


if __name__ == "__main__":
    main()
