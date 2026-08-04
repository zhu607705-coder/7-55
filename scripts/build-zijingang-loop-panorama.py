#!/usr/bin/env python3
"""Insert the Qizhen lakeside scene into the accepted side-view campus panorama."""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
CAMPUS_ASSET_DIR = ROOT / "src/assets/rpg/campus"
LEGACY_PANORAMA_PATH = (
    CAMPUS_ASSET_DIR / "source/panorama/zijingang_legacy_panorama.png"
)
QIZHEN_PLATE_PATH = ROOT / "src/assets/rpg/interiors/qizhen_lake_reflection.png"
OUTPUT_PATH = CAMPUS_ASSET_DIR / "zijingang_campus_loop_panorama.png"

LEGACY_SIZE = (11744, 1084)
QIZHEN_SIZE = (1672, 941)
SPLIT_X = 8400
INSERT_WIDTH = 1924
WORLD_HEIGHT = 1084
ROAD_TOP = 864
EDGE_FEATHER = 260


def smoothstep(value: float) -> int:
    value = max(0.0, min(1.0, value))
    eased = value * value * (3 - 2 * value)
    return round(eased * 255)


def interpolate_profile(y: int, anchors: tuple[tuple[int, float], ...]) -> float:
    if y <= anchors[0][0]:
        return anchors[0][1]
    for (start_y, start_value), (end_y, end_value) in zip(anchors, anchors[1:]):
        if y <= end_y:
            progress = (y - start_y) / max(1, end_y - start_y)
            eased = smoothstep(progress) / 255
            return start_value + (end_value - start_value) * eased
    return anchors[-1][1]


def horizontal_mask(width: int, height: int) -> Image.Image:
    column = Image.new("L", (width, 1))
    column.putdata([
        smoothstep(index / max(1, width - 1))
        for index in range(width)
    ])
    return column.resize((width, height), Image.Resampling.NEAREST)


def layered_edge_mask(width: int, height: int, side: str) -> Image.Image:
    """Blend uniform sky broadly while cutting foreground objects at the edge."""

    if side not in {"left", "right"}:
        raise ValueError(f"Unsupported seam side: {side}")

    mask = Image.new("L", (width, height))
    pixels: list[int] = []
    for y in range(height):
        if y >= ROAD_TOP:
            pixels.extend([
                smoothstep(x / max(1, width - 1))
                for x in range(width)
            ])
            continue

        # The sky can tolerate a broad colour blend. Below the skyline the
        # cut follows tree, hedge and lawn boundaries so the willow, lamp post
        # and building edge resolve to one image rather than a vertical band.
        center_anchors = (
            ((0, width / 2), (180, width / 2), (360, 42), (520, 48), (680, 82), (820, 142), (863, 150))
            if side == "left"
            else ((0, width / 2), (180, width / 2), (360, width - 42), (520, width - 36), (650, 190), (780, 118), (863, 110))
        )
        feather_anchors = (
            (0, 220),
            (180, 220),
            (360, 40),
            (650, 44),
            (863, 52),
        )
        wave = math.sin(y * 0.041) * 3 + math.sin(y * 0.017) * 2
        center = interpolate_profile(y, center_anchors) + wave
        feather = interpolate_profile(y, feather_anchors)
        start = center - feather / 2
        pixels.extend([
            smoothstep((x - start) / max(1, feather))
            for x in range(width)
        ])

    mask.putdata(pixels)
    return mask


def multiband_composite(
    first: Image.Image,
    second: Image.Image,
    detail_mask: Image.Image,
    color_mask: Image.Image,
) -> Image.Image:
    """Blend broad colour differences without double-exposing scene details."""

    first_pixels = np.asarray(first, dtype=np.float32)
    second_pixels = np.asarray(second, dtype=np.float32)
    first_low = np.asarray(
        first.filter(ImageFilter.GaussianBlur(radius=52)),
        dtype=np.float32,
    )
    second_low = np.asarray(
        second.filter(ImageFilter.GaussianBlur(radius=52)),
        dtype=np.float32,
    )
    color_alpha = np.asarray(color_mask, dtype=np.float32)[..., None] / 255
    detail_alpha = np.asarray(detail_mask, dtype=np.float32)[..., None] / 255
    result = (
        first_low * color_alpha
        + second_low * (1 - color_alpha)
        + (first_pixels - first_low) * detail_alpha
        + (second_pixels - second_low) * (1 - detail_alpha)
    )
    blended = Image.fromarray(np.clip(result, 0, 255).astype(np.uint8), "RGB")

    # The foreground road is already sourced from the accepted legacy
    # panorama. Preserve its exact linear blend and lane continuity.
    linear = Image.composite(first, second, color_mask)
    blended.paste(
        linear.crop((0, ROAD_TOP, first.width, first.height)),
        (0, ROAD_TOP),
    )
    return blended


def require_rgb(path: Path, expected_size: tuple[int, int], label: str) -> Image.Image:
    image = Image.open(path).convert("RGB")
    if image.size != expected_size:
        raise RuntimeError(
            f"{label} must be {expected_size[0]}x{expected_size[1]}; "
            f"received {image.width}x{image.height}"
        )
    return image


def main() -> None:
    legacy = require_rgb(LEGACY_PANORAMA_PATH, LEGACY_SIZE, "Legacy panorama")
    qizhen = require_rgb(QIZHEN_PLATE_PATH, QIZHEN_SIZE, "Qizhen plate")
    qizhen = qizhen.resize((INSERT_WIDTH, WORLD_HEIGHT), Image.Resampling.LANCZOS)

    # Keep one visible foreground road across the inserted lake segment. The
    # central band comes from the same accepted panorama, then the exact pixels
    # immediately on either side of SPLIT_X are restored by the edge blends.
    road = legacy.crop(
        (SPLIT_X - INSERT_WIDTH, ROAD_TOP, SPLIT_X, WORLD_HEIGHT)
    ).resize((INSERT_WIDTH, WORLD_HEIGHT - ROAD_TOP), Image.Resampling.LANCZOS)
    qizhen.paste(road, (0, ROAD_TOP))

    color_mask = horizontal_mask(EDGE_FEATHER, WORLD_HEIGHT)
    left_mask = layered_edge_mask(EDGE_FEATHER, WORLD_HEIGHT, "left")
    left_context = legacy.crop(
        (SPLIT_X, 0, SPLIT_X + EDGE_FEATHER, WORLD_HEIGHT)
    )
    left_lake = qizhen.crop((0, 0, EDGE_FEATHER, WORLD_HEIGHT))
    qizhen.paste(
        multiband_composite(left_lake, left_context, left_mask, color_mask),
        (0, 0),
    )

    right_context = legacy.crop(
        (SPLIT_X - EDGE_FEATHER, 0, SPLIT_X, WORLD_HEIGHT)
    )
    right_lake = qizhen.crop(
        (INSERT_WIDTH - EDGE_FEATHER, 0, INSERT_WIDTH, WORLD_HEIGHT)
    )
    right_mask = layered_edge_mask(EDGE_FEATHER, WORLD_HEIGHT, "right")
    qizhen.paste(
        multiband_composite(right_context, right_lake, right_mask, color_mask),
        (INSERT_WIDTH - EDGE_FEATHER, 0),
    )

    world = Image.new(
        "RGB",
        (LEGACY_SIZE[0] + INSERT_WIDTH, WORLD_HEIGHT),
    )
    world.paste(legacy.crop((0, 0, SPLIT_X, WORLD_HEIGHT)), (0, 0))
    world.paste(qizhen, (SPLIT_X, 0))
    world.paste(
        legacy.crop((SPLIT_X, 0, LEGACY_SIZE[0], WORLD_HEIGHT)),
        (SPLIT_X + INSERT_WIDTH, 0),
    )

    temporary_path = OUTPUT_PATH.with_suffix(".tmp.png")
    world.save(temporary_path, format="PNG", optimize=True)
    temporary_path.replace(OUTPUT_PATH)
    print(
        f"built loop panorama {world.width}x{world.height} "
        f"split={SPLIT_X} insert={INSERT_WIDTH} output={OUTPUT_PATH}"
    )


if __name__ == "__main__":
    main()
