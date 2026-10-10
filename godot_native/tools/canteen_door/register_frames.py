"""Mechanical registration of web-authored hinge poses; no generated geometry.

Uses only source crop, alpha masks, independent uniform scale and translation.
The original frame and runtime closed endpoint are never rescaled or redrawn.
"""
from __future__ import annotations
import hashlib
import json
import math
from pathlib import Path
from PIL import Image, ImageDraw
from measure_aperture import measure

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/native/canteen_door'
ORIGINAL = ROOT / 'assets/native/canteen_objects/canteen_double_door.png'
RAW = OUT / 'web_atlas_source.png'
SOURCE_HASH = 'd2f5df50b71e106a84335807b703ae6b3385cc2fb5f96c805c9a09dc799cf36d'
CROP = (244, 232, 1010, 1023)
CELL = 512
CELL_SOURCE_ORIGIN = (64, 40)
APERTURE = (72, 85, 695, 770)
HINGE_PLATES = [(59, 178, 91, 280), (59, 551, 91, 653), (677, 178, 709, 280), (677, 551, 709, 653)]
# Read from the generated sheet's fixed outside hinge edges, not requested angles.
# Each record is left x, right x, top y, and bottom y in its unscaled source cell.
RAW_HINGES = [(79, 366, 82, 378), (79, 367, 82, 378), (79, 368, 82, 378), (80, 367, 82, 378),
              (80, 367, 83, 379), (79, 367, 83, 379), (80, 367, 82, 379), (80, 367, 83, 379)]
TARGET_HINGES = (100.0, 411.5, 82.5, 425.0)
# Actual inner silhouette extents below the static lintel, including handles.
RAW_INNER_EXTENTS = [(224, 224), (208, 235), (193, 251), (171, 272), (149, 296), (133, 310), (124, 319), (120, 324)]


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    if sha(ORIGINAL) != SOURCE_HASH:
        raise SystemExit('Unexpected original canteen door source')
    source = Image.open(ORIGINAL).convert('RGBA').crop(CROP)
    raw = Image.open(RAW).convert('RGBA')
    if raw.size != (1774, 887):
        raise SystemExit('Unexpected generated atlas size; re-audit registration')
    mask = Image.new('L', source.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rectangle((APERTURE[0], APERTURE[1], APERTURE[2] - 1, APERTURE[3] - 1), fill=255)
    for box in HINGE_PLATES:
        draw.rectangle((box[0], box[1], box[2] - 1, box[3] - 1), fill=0)
    frame = source.copy()
    frame.putalpha(Image.composite(Image.new('L', source.size, 0), source.getchannel('A'), mask))
    frame.save(OUT / 'southeast_frame.png')
    closed = source.copy()
    closed.putalpha(Image.composite(source.getchannel('A'), Image.new('L', source.size, 0), mask))
    closed_cell = Image.new('RGBA', (1024, 1024))
    closed_cell.paste(closed, (128, 80))
    cells = [closed_cell.resize((CELL, CELL), Image.Resampling.NEAREST)]
    registrations = [{'frame': 0, 'method': 'uniform half-size original aperture reference; runtime uses full original source'}]
    for i in range(1, 8):
        col, row = i % 4, i // 4
        x, xe = round(col * raw.width / 4), round((col + 1) * raw.width / 4)
        y, ye = round(row * raw.height / 2), round((row + 1) * raw.height / 2)
        cell = raw.crop((x, y, xe, ye))
        lx, rx, ty, by = RAW_HINGES[i]
        scale = (TARGET_HINGES[3] - TARGET_HINGES[2]) / (by - ty)
        result = Image.new('RGBA', (CELL, CELL))
        for side in range(2):
            clip = (lx, ty, RAW_INNER_EXTENTS[i][0], 425) if side == 0 else (RAW_INNER_EXTENTS[i][1], ty, rx, 425)
            isolated = Image.new('RGBA', cell.size)
            isolated.paste(cell.crop(clip), clip[:2])
            isolated.putalpha(isolated.getchannel('A').point(lambda a: 0 if a < 16 else a))
            anchor_x = lx if side == 0 else rx
            target_x = TARGET_HINGES[side]
            # Equal diagonal coefficients: only uniform scale and translation.
            coeff = (1 / scale, 0, anchor_x - target_x / scale, 0, 1 / scale, ty - TARGET_HINGES[2] / scale)
            registered = isolated.transform((CELL, CELL), Image.Transform.AFFINE, coeff, Image.Resampling.NEAREST)
            result.alpha_composite(registered)
        cells.append(result)
        registrations.append({'frame': i, 'raw_cell': [x, y, xe-x, ye-y], 'raw_hinges': [lx, rx, ty, by], 'inner_silhouette_extents': RAW_INNER_EXTENTS[i],
                              'uniform_scale': scale, 'target_hinges': TARGET_HINGES})
    atlas = Image.new('RGBA', (CELL * 4, CELL * 2))
    for i, cell in enumerate(cells):
        atlas.paste(cell, (i % 4 * CELL, i // 4 * CELL))
    atlas.save(OUT / 'southeast_leaves_8f.png')
    measures = [{'frame': i, **measure(cell)} for i, cell in enumerate(cells)]
    first_passable = next(i for i, row in enumerate(measures) if row['foot_passable'])
    gate_visual = (1 - math.cos(math.pi * .38)) / 2
    clearances = [row['centered_clear_width_world_px'] for row in measures]
    gate_clearance = clearances[first_passable]
    cues = [gate_visual * v / gate_clearance if i <= first_passable else
            gate_visual + (1 - gate_visual) * (v - gate_clearance) / (clearances[-1] - gate_clearance)
            for i, v in enumerate(clearances)]
    manifest = {
        'version': 1, 'generation_method': 'ChatGPT web image generation', 'generation_date': '2026-10-09',
        'source_asset': 'assets/native/canteen_objects/canteen_double_door.png', 'source_sha256': SOURCE_HASH,
        'generated_source_sha256': sha(RAW), 'generated_source_size': raw.size, 'source_crop': CROP,
        'stationary_aperture': APERTURE, 'stationary_hinge_plates': HINGE_PLATES,
        'atlas_size': atlas.size, 'cell_size': [CELL, CELL], 'cell_source_origin': CELL_SOURCE_ORIGIN,
        'cell_to_source_scale': 2, 'world_scale': 88 / 766, 'registrations': registrations,
        'angles': 'Requested angles are a drawing brief; passage clearance is measured from actual alpha silhouettes.',
        'clearance_measurements': measures, 'first_passable_frame': first_passable,
        'gate_visual_full_travel': gate_visual, 'measured_visual_cues': cues,
        'frame_sha256': sha(OUT / 'southeast_frame.png'), 'leaves_sha256': sha(OUT / 'southeast_leaves_8f.png'),
        'closed_endpoint': 'Runtime paints the unchanged full-resolution original source directly.',
    }
    (OUT / 'provenance.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(json.dumps(measures, indent=2))


if __name__ == '__main__':
    main()
