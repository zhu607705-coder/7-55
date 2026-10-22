"""Measure existing RGBA leaf pixels. Does not synthesize or warp artwork.

Usage: python measure_aperture.py path/to/registered-leaves.png
The centered clear corridor is the intersection of alpha-free row spans.
The full leaf-height scan includes lowered open tips and handle projections.
"""
from __future__ import annotations
import json
import sys
from PIL import Image

CELL = 512
SOURCE_SCALE = 88 / 766
CELL_TO_SOURCE = 2
LEFT_HINGE = 98
RIGHT_HINGE = 412
CENTER = 255.5
CENTER_PIXEL = 256
BAND = (82, 487)
PLAYER_FOOT_WIDTH = 19.5


def measure(cell: Image.Image) -> dict:
    alpha = cell.getchannel('A')
    corridor_left = LEFT_HINGE
    corridor_right = RIGHT_HINGE
    blocked_rows = 0
    for y in range(*BAND):
        if alpha.getpixel((CENTER_PIXEL, y)) >= 8:
            blocked_rows += 1
            corridor_left = corridor_right = CENTER_PIXEL
            continue
        left = CENTER_PIXEL
        right = CENTER_PIXEL
        while left > LEFT_HINGE and alpha.getpixel((left - 1, y)) < 8:
            left -= 1
        while right < RIGHT_HINGE and alpha.getpixel((right, y)) < 8:
            right += 1
        corridor_left = max(corridor_left, left)
        corridor_right = min(corridor_right, right)
    width = max(0, corridor_right - corridor_left)
    return {
        'cell_corridor': [corridor_left, corridor_right],
        'clear_width_cell_px': width,
        'clear_width_world_px': width * CELL_TO_SOURCE * SOURCE_SCALE,
        'centered_clear_width_world_px': 2 * max(0, min(CENTER - corridor_left, corridor_right - CENTER)) * CELL_TO_SOURCE * SOURCE_SCALE,
        'foot_passable': 2 * max(0, min(CENTER - corridor_left, corridor_right - CENTER)) * CELL_TO_SOURCE * SOURCE_SCALE >= PLAYER_FOOT_WIDTH,
        'center_blocked_rows': blocked_rows,
    }


def main() -> None:
    atlas = Image.open(sys.argv[1])
    if atlas.mode != 'RGBA' or atlas.size != (CELL * 4, CELL * 2):
        raise SystemExit('Expected a 2048x1024 RGBA registered leaves atlas')
    result = []
    for frame in range(8):
        x, y = frame % 4 * CELL, frame // 4 * CELL
        result.append({'frame': frame, **measure(atlas.crop((x, y, x + CELL, y + CELL)))})
    print(json.dumps({'scan_band': BAND, 'alpha_threshold': 8, 'player_foot_width_world': PLAYER_FOOT_WIDTH, 'frames': result}, indent=2))


if __name__ == '__main__':
    main()
