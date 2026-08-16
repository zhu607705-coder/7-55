#!/usr/bin/env python3
"""Build the crisp 755 m camera-motion atlas from generated key plates.

The checked-in high-resolution plates remain the authored image sources. This
script downsamples them to the renderer's 320 x 180 pixel buffer, applies the
pre-calibrated affine camera motion, and packs 273 opaque frames into one PNG.
It intentionally avoids optical-flow synthesis and alpha dissolves because
both introduce doubled edges in the generated architecture.
"""

from __future__ import annotations

from math import ceil
from pathlib import Path

from PIL import Image


FRAME_WIDTH = 320
FRAME_HEIGHT = 180
FRAMES_PER_INTERVAL = 16
ATLAS_COLUMNS = 16

REPO_ROOT = Path(__file__).resolve().parents[1]
ASSET_ROOT = REPO_ROOT / "src" / "assets" / "rpg" / "canteen_chase"
OUTPUT_PATH = ASSET_ROOT / "campus_avenue_distance_atlas_273f.png"

SOURCE_FRAMES = (
    (0, "campus_avenue_plate.png"),
    (47, "campus_avenue_distance_047.png"),
    (95, "campus_avenue_distance_095.png"),
    (143, "campus_avenue_distance_143.png"),
    (190, "campus_avenue_distance_190.png"),
    (238, "campus_avenue_distance_238.png"),
    (285, "campus_avenue_distance_285.png"),
    (331, "campus_avenue_distance_331.png"),
    (377, "campus_avenue_distance_377.png"),
    (424, "campus_avenue_distance_424.png"),
    (470, "campus_avenue_distance_470.png"),
    (518, "campus_avenue_distance_518.png"),
    (566, "campus_avenue_distance_566.png"),
    (600, "campus_avenue_distance_600.png"),
    (635, "campus_avenue_distance_635.png"),
    (668, "campus_avenue_distance_668.png"),
    (700, "campus_avenue_distance_700.png"),
    (755, "campus_avenue_distance_755.png"),
)

# Each matrix maps points in one key plate into the following key plate. They
# were calibrated on the 320 x 180 runtime projection with ECC registration.
PAIR_TRANSFORMS = (
    ((1.010, 0.002, -1.420), (0.001, 1.033, -4.042), (0.0, 0.0, 1.0)),
    ((1.006, -0.004, -0.667), (0.000, 1.013, -1.220), (0.0, 0.0, 1.0)),
    ((1.001, 0.001, -0.253), (0.000, 1.004, -0.388), (0.0, 0.0, 1.0)),
    ((1.079, -0.019, -9.674), (0.004, 1.060, -2.706), (0.0, 0.0, 1.0)),
    ((1.127, 0.005, -20.319), (-0.001, 1.148, -11.951), (0.0, 0.0, 1.0)),
    ((0.953, -0.002, 7.370), (0.002, 0.967, 1.210), (0.0, 0.0, 1.0)),
    ((1.004, -0.001, -0.393), (0.001, 1.017, -2.421), (0.0, 0.0, 1.0)),
    ((0.974, 0.022, 2.425), (0.006, 0.967, -5.307), (0.0, 0.0, 1.0)),
    ((1.047, -0.002, -7.210), (-0.001, 1.047, -1.983), (0.0, 0.0, 1.0)),
    ((1.009, -0.005, -0.557), (0.001, 1.016, -1.235), (0.0, 0.0, 1.0)),
    ((1.000, 0.003, -0.233), (-0.001, 0.990, 1.182), (0.0, 0.0, 1.0)),
    ((1.106, 0.006, -17.624), (0.006, 1.084, -6.665), (0.0, 0.0, 1.0)),
    ((0.989, 0.000, 1.829), (0.000, 0.988, 4.655), (0.0, 0.0, 1.0)),
    ((1.374, -0.018, -53.711), (0.002, 1.386, -16.105), (0.0, 0.0, 1.0)),
    ((0.889, 0.002, 16.094), (0.001, 0.885, 8.717), (0.0, 0.0, 1.0)),
    ((1.383, 0.016, -66.330), (0.000, 1.362, -46.638), (0.0, 0.0, 1.0)),
    ((1.055745, 0.003810, -8.445062), (0.000229, 1.072467, -8.638083), (0.0, 0.0, 1.0)),
)


def multiply(left: tuple[tuple[float, ...], ...], right: tuple[tuple[float, ...], ...]):
    return tuple(
        tuple(sum(left[row][index] * right[index][column] for index in range(3)) for column in range(3))
        for row in range(3)
    )


def invert_affine(matrix: tuple[tuple[float, ...], ...]):
    a, b, c = matrix[0]
    d, e, f = matrix[1]
    determinant = a * e - b * d
    if abs(determinant) < 1e-9:
        raise ValueError("Camera transform is singular")
    inverse_a = e / determinant
    inverse_b = -b / determinant
    inverse_d = -d / determinant
    inverse_e = a / determinant
    return (
        (inverse_a, inverse_b, -(inverse_a * c + inverse_b * f)),
        (inverse_d, inverse_e, -(inverse_d * c + inverse_e * f)),
        (0.0, 0.0, 1.0),
    )


def interpolate_affine(matrix: tuple[tuple[float, ...], ...], amount: float):
    identity = ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0))
    return tuple(
        tuple(identity[row][column] + (matrix[row][column] - identity[row][column]) * amount for column in range(3))
        for row in range(3)
    )


def transform_point(matrix, x: float, y: float):
    return (
        matrix[0][0] * x + matrix[0][1] * y + matrix[0][2],
        matrix[1][0] * x + matrix[1][1] * y + matrix[1][2],
    )


def cover_transform(source_to_output):
    corners = (
        transform_point(source_to_output, 0.0, 0.0),
        transform_point(source_to_output, FRAME_WIDTH, 0.0),
        transform_point(source_to_output, 0.0, FRAME_HEIGHT),
        transform_point(source_to_output, FRAME_WIDTH, FRAME_HEIGHT),
    )
    minimum_x = min(point[0] for point in corners)
    maximum_x = max(point[0] for point in corners)
    minimum_y = min(point[1] for point in corners)
    maximum_y = max(point[1] for point in corners)
    span_x = max(1.0, maximum_x - minimum_x)
    span_y = max(1.0, maximum_y - minimum_y)
    # Four per cent overscan prevents rotated or sheared corners from exposing
    # synthetic borders while keeping the same crop at every key-frame seam.
    cover_scale = max(1.0, FRAME_WIDTH / span_x, FRAME_HEIGHT / span_y) * 1.04
    center_x = (minimum_x + maximum_x) / 2
    center_y = (minimum_y + maximum_y) / 2
    cover = (
        (cover_scale, 0.0, FRAME_WIDTH / 2 - center_x * cover_scale),
        (0.0, cover_scale, FRAME_HEIGHT / 2 - center_y * cover_scale),
        (0.0, 0.0, 1.0),
    )
    return multiply(cover, source_to_output)


def warp_frame(source: Image.Image, source_to_output):
    output_to_source = invert_affine(cover_transform(source_to_output))
    return source.transform(
        (FRAME_WIDTH, FRAME_HEIGHT),
        Image.Transform.AFFINE,
        (
            output_to_source[0][0],
            output_to_source[0][1],
            output_to_source[0][2],
            output_to_source[1][0],
            output_to_source[1][1],
            output_to_source[1][2],
        ),
        resample=Image.Resampling.NEAREST,
        fillcolor=(40, 45, 49),
    )


def main() -> None:
    if len(PAIR_TRANSFORMS) != len(SOURCE_FRAMES) - 1:
        raise ValueError("Every source interval requires one camera transform")

    source_images: list[Image.Image] = []
    for _, filename in SOURCE_FRAMES:
        source_path = ASSET_ROOT / filename
        with Image.open(source_path) as source:
            if source.size != (1672, 941):
                raise ValueError(f"Unexpected source size for {filename}: {source.size}")
            runtime_frame = source.convert("RGB").resize(
                (FRAME_WIDTH, FRAME_HEIGHT),
                resample=Image.Resampling.NEAREST,
            )
        source_images.append(runtime_frame)

    total_frames = (len(SOURCE_FRAMES) - 1) * FRAMES_PER_INTERVAL + 1
    atlas_rows = ceil(total_frames / ATLAS_COLUMNS)
    atlas = Image.new("RGB", (ATLAS_COLUMNS * FRAME_WIDTH, atlas_rows * FRAME_HEIGHT))

    frame_index = 0
    for interval_index, transform in enumerate(PAIR_TRANSFORMS):
        transform_inverse = invert_affine(transform)
        for step in range(FRAMES_PER_INTERVAL):
            amount = step / FRAMES_PER_INTERVAL
            intermediate = interpolate_affine(transform, amount)
            if amount <= 0.5:
                source_to_output = intermediate
                frame = warp_frame(source_images[interval_index], source_to_output)
            else:
                source_to_output = multiply(intermediate, transform_inverse)
                frame = warp_frame(source_images[interval_index + 1], source_to_output)
            atlas.paste(
                frame,
                (
                    (frame_index % ATLAS_COLUMNS) * FRAME_WIDTH,
                    (frame_index // ATLAS_COLUMNS) * FRAME_HEIGHT,
                ),
            )
            frame_index += 1

    atlas.paste(
        warp_frame(
            source_images[-1],
            ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0)),
        ),
        (
            (frame_index % ATLAS_COLUMNS) * FRAME_WIDTH,
            (frame_index // ATLAS_COLUMNS) * FRAME_HEIGHT,
        ),
    )
    atlas.save(OUTPUT_PATH, format="PNG", compress_level=9)
    print(
        f"Built {OUTPUT_PATH.relative_to(REPO_ROOT)}: "
        f"{total_frames} frames, {atlas.width}x{atlas.height}"
    )


if __name__ == "__main__":
    main()
