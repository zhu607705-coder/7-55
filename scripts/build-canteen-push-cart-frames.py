#!/usr/bin/env python3
"""Package the reviewed 8x4 canteen push-cart art into runtime cells.

The checked-in source is the reviewed image-generation result on a magenta
key background. This step removes the key, snaps the art to nearest-neighbour
pixels and normalizes every direction row to one stable 314px frame grid.
"""

from __future__ import annotations

import hashlib
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "src/assets/rpg/player/source/player_push_cart_sheet_8f_chroma.png"
OUTPUT = ROOT / "src/assets/rpg/player/player_push_cart_sheet_8f.png"
EXPECTED_SOURCE_SHA256 = "77801be4dc3686d0e8bd317924e03e5f3fe67ecbaafba7fdc9ea255ba0347638"
SOURCE_WIDTH = 1536
SOURCE_HEIGHT = 1024
SOURCE_COLUMNS = 8
OUTPUT_COLUMNS = 8
ROWS = 4
FRAME_SIZE = 314
ROW_BANDS = ((0, 286), (286, 520), (520, 735), (735, 1024))
MAX_CONTENT_SIZE = 282
BOTTOM_MARGIN = 16


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def remove_chroma_key(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    output = Image.new("RGBA", rgba.size, (0, 0, 0, 0))
    source_pixels = rgba.load()
    output_pixels = output.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            red, green, blue, _ = source_pixels[x, y]
            chroma_strength = min(red, blue) - green
            is_key = red > 100 and blue > 100 and chroma_strength > 30
            output_pixels[x, y] = (red, green, blue, 0 if is_key else 255)
    return output


def remove_detached_key_edges(image: Image.Image) -> Image.Image:
    """Drop narrow chroma-edge fragments without touching the main silhouette."""
    alpha = image.getchannel("A")
    pixels = alpha.load()
    visited: set[tuple[int, int]] = set()
    for start_y in range(image.height):
        for start_x in range(image.width):
            if pixels[start_x, start_y] == 0 or (start_x, start_y) in visited:
                continue
            stack = [(start_x, start_y)]
            visited.add((start_x, start_y))
            component: list[tuple[int, int]] = []
            min_x = max_x = start_x
            min_y = max_y = start_y
            while stack:
                x, y = stack.pop()
                component.append((x, y))
                min_x = min(min_x, x)
                max_x = max(max_x, x)
                min_y = min(min_y, y)
                max_y = max(max_y, y)
                for next_x, next_y in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                    if (
                        0 <= next_x < image.width
                        and 0 <= next_y < image.height
                        and pixels[next_x, next_y] > 0
                        and (next_x, next_y) not in visited
                    ):
                        visited.add((next_x, next_y))
                        stack.append((next_x, next_y))
            component_width = max_x - min_x + 1
            component_height = max_y - min_y + 1
            if len(component) < 200 and (component_width <= 3 or component_height <= 3):
                for x, y in component:
                    image.putpixel((x, y), (0, 0, 0, 0))
    return image


def main() -> None:
    actual_hash = sha256(SOURCE)
    if actual_hash != EXPECTED_SOURCE_SHA256:
        raise SystemExit(
            "push-cart chroma source changed; review it and update the source hash "
            f"before rebuilding (received {actual_hash})"
        )

    source = Image.open(SOURCE).convert("RGBA")
    if source.size != (SOURCE_WIDTH, SOURCE_HEIGHT):
        raise SystemExit(
            f"expected source size {(SOURCE_WIDTH, SOURCE_HEIGHT)}, received {source.size}"
        )

    keyed = remove_chroma_key(source)
    source_cell_width = SOURCE_WIDTH // SOURCE_COLUMNS
    extracted_rows: list[list[Image.Image]] = []
    for top, bottom in ROW_BANDS:
        row_frames: list[Image.Image] = []
        for column in range(SOURCE_COLUMNS):
            frame = remove_detached_key_edges(keyed.crop(
                (column * source_cell_width, top, (column + 1) * source_cell_width, bottom)
            ))
            bounds = frame.getbbox()
            if bounds is None:
                raise SystemExit(f"empty push-cart frame at row {len(extracted_rows)}, column {column}")
            row_frames.append(frame.crop(bounds))
        extracted_rows.append(row_frames)

    output = Image.new(
        "RGBA",
        (FRAME_SIZE * OUTPUT_COLUMNS, FRAME_SIZE * ROWS),
        (0, 0, 0, 0),
    )
    for row_index, row_frames in enumerate(extracted_rows):
        max_width = max(frame.width for frame in row_frames)
        max_height = max(frame.height for frame in row_frames)
        scale = min(MAX_CONTENT_SIZE / max_width, MAX_CONTENT_SIZE / max_height)
        for column, frame in enumerate(row_frames):
            target_size = (
                max(1, round(frame.width * scale)),
                max(1, round(frame.height * scale)),
            )
            resized = frame.resize(target_size, Image.Resampling.NEAREST)
            target_x = column * FRAME_SIZE + (FRAME_SIZE - resized.width) // 2
            target_y = row_index * FRAME_SIZE + FRAME_SIZE - BOTTOM_MARGIN - resized.height
            output.alpha_composite(resized, (target_x, target_y))

    output.save(OUTPUT, optimize=True)
    print(
        f"generated {OUTPUT.relative_to(ROOT)} {output.width}x{output.height} "
        f"sha256={sha256(OUTPUT)}"
    )


if __name__ == "__main__":
    main()
