#!/usr/bin/env python3

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
PLATE = ROOT / "src/assets/rpg/campus/zijingang_campus_plate.png"
SECTOR_DIR = ROOT / "src/assets/rpg/campus/sectors"
MANIFEST = SECTOR_DIR / "manifest.json"


def main() -> None:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    world_size = (manifest["world"]["width"], manifest["world"]["height"])
    sector_size = (manifest["sectorSize"]["width"], manifest["sectorSize"]["height"])
    plate = Image.open(PLATE).convert("RGB")
    if plate.size != world_size:
        raise SystemExit(f"Campus plate must be {world_size[0]}x{world_size[1]}, got {plate.width}x{plate.height}")

    for sector in manifest["sectors"]:
        left = int(sector["x"])
        top = int(sector["y"])
        crop = plate.crop((left, top, left + sector_size[0], top + sector_size[1]))
        destination = SECTOR_DIR / sector["file"]
        crop.save(destination, optimize=True)
        print(f"wrote {destination.relative_to(ROOT)} at ({left},{top})")


if __name__ == "__main__":
    main()
