#!/usr/bin/env python3
"""Reproduce the geometric ground-replacement coverage, without touching any PNG."""
import argparse
import hashlib
import json
import math
from pathlib import Path


def build(meta):
    width, height = meta['canvas']
    origin_x, origin_y, _, _ = meta['world_rect']
    guard = meta['opaque_guard_source_pixels']
    feather = meta['feather_limit_source_pixels']
    raw = bytearray()
    protected = unprotected = 0
    for row in range(height):
        for column in range(width):
            x, y = origin_x + column + 0.5, origin_y + row + 0.5
            distance_squared, inside = math.inf, False
            for polygon in meta['protected_source_polygons']:
                own = False
                for a, b in zip(polygon, polygon[1:] + polygon[:1]):
                    dx, dy = b[0] - a[0], b[1] - a[1]
                    projection = ((x-a[0])*dx + (y-a[1])*dy) / (dx*dx + dy*dy)
                    t = max(0.0, min(1.0, projection))
                    distance_squared = min(distance_squared, (x-a[0]-t*dx)**2 + (y-a[1]-t*dy)**2)
                    if (a[1] > y) != (b[1] > y) and x < dx * (y-a[1]) / dy + a[0]:
                        own = not own
                inside = inside or own
            u = max(0.0, min(1.0, (math.sqrt(distance_squared)-guard)/(feather-guard)))
            alpha = 255 if inside else round(255*(1-u*u*(3-2*u)))
            raw.append(alpha)
            if inside:
                protected += 1
                unprotected += alpha != 255
    return bytes(raw), {
        'protected_source_pixel_centers': protected,
        'protected_pixels_with_alpha_below_255': unprotected,
        'fully_opaque_pixels': raw.count(255),
        'fully_source_preserved_pixels': raw.count(0),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='Verify existing bytes and metadata without writing')
    args = parser.parse_args()
    data = Path(__file__).resolve().parents[1] / 'data'
    metadata_path = data / 'library-ground-coverage.json'
    output = data / 'library-ground-coverage.bin'
    meta = json.loads(metadata_path.read_text())
    raw, validation = build(meta)
    digest = hashlib.sha256(raw).hexdigest()
    if args.check:
        assert output.read_bytes() == raw, 'Coverage bytes differ from authored geometry'
        assert meta['mask_sha256'] == digest and meta['validation'] == validation, 'Coverage metadata mismatch'
        print('Ground geometry coverage verified:', digest, validation)
    else:
        output.write_bytes(raw)
        meta.update(mask_sha256=digest, validation=validation)
        metadata_path.write_text(json.dumps(meta, ensure_ascii=False, indent=2)+'\n')
        print('Wrote geometric coverage:', output.name, digest)


if __name__ == '__main__':
    main()
