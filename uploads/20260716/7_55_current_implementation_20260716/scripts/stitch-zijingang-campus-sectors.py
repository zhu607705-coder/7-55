#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SECTOR_DIR = ROOT / "src/assets/rpg/campus/sectors"
MANIFEST = SECTOR_DIR / "manifest.json"
OUTPUT = ROOT / "src/assets/rpg/campus/zijingang_campus_plate.png"


def horizontal_mask(width: int, height: int, overlap: int) -> Image.Image:
    mask = Image.new("L", (width, height), 255)
    pixels = mask.load()
    for x in range(overlap):
        value = round(255 * x / max(1, overlap - 1))
        for y in range(height):
            pixels[x, y] = value
    return mask


def vertical_mask(width: int, height: int, overlap: int) -> Image.Image:
    mask = Image.new("L", (width, height), 255)
    pixels = mask.load()
    for y in range(overlap):
        value = round(255 * y / max(1, overlap - 1))
        for x in range(width):
            pixels[x, y] = value
    return mask


def compose_row(left: Image.Image, right: Image.Image, world_width: int, overlap: int) -> Image.Image:
    row = Image.new("RGB", (world_width, left.height))
    row.paste(left, (0, 0))
    row.paste(right, (left.width - overlap, 0), horizontal_mask(right.width, right.height, overlap))
    return row


def main() -> None:
    parser = argparse.ArgumentParser(description="Stitch four overlapping Zijingang campus sectors")
    parser.add_argument("--normalize-palette", action="store_true", help="Reduce the result to one 192-color palette")
    args = parser.parse_args()

    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    world_width = int(manifest["world"]["width"])
    world_height = int(manifest["world"]["height"])
    sector_width = int(manifest["sectorSize"]["width"])
    sector_height = int(manifest["sectorSize"]["height"])
    overlap_x = int(manifest["overlap"]["x"])
    overlap_y = int(manifest["overlap"]["y"])

    images: dict[str, Image.Image] = {}
    for sector in manifest["sectors"]:
        image = Image.open(SECTOR_DIR / sector["file"]).convert("RGB")
        if image.size != (sector_width, sector_height):
            raise SystemExit(
                f"{sector['file']} must be {sector_width}x{sector_height}; got {image.width}x{image.height}. "
                "Resize from the shared coordinate template before stitching."
            )
        images[sector["id"]] = image

    north = compose_row(images["nw"], images["ne"], world_width, overlap_x)
    south = compose_row(images["sw"], images["se"], world_width, overlap_x)
    plate = Image.new("RGB", (world_width, world_height))
    plate.paste(north, (0, 0))
    plate.paste(south, (0, sector_height - overlap_y), vertical_mask(world_width, sector_height, overlap_y))

    if args.normalize_palette:
        plate = plate.quantize(colors=192, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
    plate.save(OUTPUT, optimize=True)
    print(f"stitched {OUTPUT.relative_to(ROOT)} from 4 sectors with {overlap_x}x{overlap_y}px overlap")


if __name__ == "__main__":
    main()
