#!/usr/bin/env python3
"""Insert the Qizhen lakeside scene into the accepted side-view campus panorama."""

from __future__ import annotations

from pathlib import Path

from PIL import Image


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
    eased = value * value * (3 - 2 * value)
    return round(eased * 255)


def horizontal_mask(width: int, height: int) -> Image.Image:
    column = Image.new("L", (width, 1))
    column.putdata([
        smoothstep(index / max(1, width - 1))
        for index in range(width)
    ])
    return column.resize((width, height), Image.Resampling.NEAREST)


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

    mask = horizontal_mask(EDGE_FEATHER, WORLD_HEIGHT)
    left_context = legacy.crop(
        (SPLIT_X, 0, SPLIT_X + EDGE_FEATHER, WORLD_HEIGHT)
    )
    left_lake = qizhen.crop((0, 0, EDGE_FEATHER, WORLD_HEIGHT))
    qizhen.paste(Image.composite(left_lake, left_context, mask), (0, 0))

    right_context = legacy.crop(
        (SPLIT_X - EDGE_FEATHER, 0, SPLIT_X, WORLD_HEIGHT)
    )
    right_lake = qizhen.crop(
        (INSERT_WIDTH - EDGE_FEATHER, 0, INSERT_WIDTH, WORLD_HEIGHT)
    )
    qizhen.paste(
        Image.composite(right_context, right_lake, mask),
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
