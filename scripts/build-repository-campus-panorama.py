#!/usr/bin/env python3
"""Rebuild the selected 4 x 4 campus panorama as one seam-stable PNG."""

from __future__ import annotations

import argparse
import base64
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE = Path.home() / "Downloads" / "大地图"
DEFAULT_OUTPUT = ROOT / "src/assets/rpg/campus/zijingang_campus_plate.png"
DEFAULT_MASK_OUTPUT = ROOT / "src/assets/rpg/campus/zijingang_road_walkability_mask.png"
DEFAULT_RUNTIME = ROOT / "src/data/maps/zijingang-campus-runtime.json"
TILE_SIZE = 1254
GRID_SIZE = 4
WORLD_SIZE = TILE_SIZE * GRID_SIZE
SEAMS = tuple(TILE_SIZE * index for index in range(1, GRID_SIZE))

WALKABILITY_CELL_SIZE = 4
WALKABILITY_GRID_SIZE = WORLD_SIZE // WALKABILITY_CELL_SIZE
FOUNDATION_LIBRARY_CENTER = (3000, 280)
LIBRARY_GATE = (3000, 538)
LIBRARY_GATE_RADIUS = 112
LIBRARY_APPROACH_ROAD_Y = 610
LIBRARY_APPROACH_START_X = 2476
LIBRARY_APPROACH_END_X = 3048
LIBRARY_APPROACH_HALF_WIDTH = 40
KNOWN_OVERLAP_CORRECTION = (2, 4)
KNOWN_OVERLAP_WIDTH = 430
KNOWN_OVERLAP_VERTICAL_SHIFT = 60

ROAD_HALF_WIDTH = 38
CURB_WIDTH = 6
ROAD_COLOR = np.array([58, 60, 57], dtype=np.int16)
CURB_COLOR = (158, 153, 132)
EDGE_COLOR = (184, 174, 126)
MARK_COLOR = (208, 196, 128)
CROSSWALK_COLOR = (211, 211, 191)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--mask-output", type=Path, default=DEFAULT_MASK_OUTPUT)
    parser.add_argument("--runtime", type=Path, default=DEFAULT_RUNTIME)
    parser.add_argument(
        "--walkability-only",
        action="store_true",
        help="Rebuild the road mask and runtime data from the existing selected panorama without rewriting it.",
    )
    return parser.parse_args()


def tile_path(source: Path, row: int, column: int) -> Path:
    return source / f"（{row},{column}）.png"


def load_normalized_tile(path: Path) -> tuple[Image.Image, tuple[int, int]]:
    if not path.is_file():
        raise FileNotFoundError(f"Missing panorama tile: {path}")
    image = Image.open(path).convert("RGB")
    source_size = image.size
    if image.size != (TILE_SIZE, TILE_SIZE):
        image = image.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.LANCZOS)
    return image, source_size


def correct_known_overlap(tile: Image.Image, row: int, column: int) -> Image.Image:
    """Remove the duplicated 430px overlap baked into source tile (2,4)."""
    if (row, column) != KNOWN_OVERLAP_CORRECTION:
        return tile

    overlap = KNOWN_OVERLAP_WIDTH
    vertical_shift = KNOWN_OVERLAP_VERTICAL_SHIFT
    retained_width = TILE_SIZE - overlap
    retained_height = TILE_SIZE - vertical_shift
    main = tile.crop((overlap, 0, TILE_SIZE, retained_height))
    extension_source = tile.crop((TILE_SIZE - 220, 0, TILE_SIZE, retained_height))
    extension = extension_source.resize((overlap, retained_height), Image.Resampling.LANCZOS)

    corrected = Image.new("RGB", (TILE_SIZE, TILE_SIZE))
    top_main = tile.crop((overlap, 0, TILE_SIZE, vertical_shift))
    top_extension = tile.crop((TILE_SIZE - 220, 0, TILE_SIZE, vertical_shift)).resize(
        (overlap, vertical_shift), Image.Resampling.LANCZOS
    )
    corrected.paste(top_main, (0, 0))
    corrected.paste(top_extension, (retained_width, 0))
    corrected.paste(main, (0, vertical_shift))
    corrected.paste(extension, (retained_width, vertical_shift))
    return corrected


def draw_connector_roads(image: Image.Image) -> Image.Image:
    draw = ImageDraw.Draw(image)
    extent = WORLD_SIZE - 1

    for seam in SEAMS:
        draw.rectangle(
            (seam - ROAD_HALF_WIDTH - CURB_WIDTH, 0, seam + ROAD_HALF_WIDTH + CURB_WIDTH, extent),
            fill=CURB_COLOR,
        )
    for seam in SEAMS:
        draw.rectangle(
            (0, seam - ROAD_HALF_WIDTH - CURB_WIDTH, extent, seam + ROAD_HALF_WIDTH + CURB_WIDTH),
            fill=CURB_COLOR,
        )

    pixels = np.asarray(image).copy().astype(np.int16)
    rng = np.random.default_rng(755)
    noise = rng.integers(-6, 7, size=(WORLD_SIZE, WORLD_SIZE), dtype=np.int16)
    road_mask = np.zeros((WORLD_SIZE, WORLD_SIZE), dtype=bool)
    for seam in SEAMS:
        road_mask[:, seam - ROAD_HALF_WIDTH : seam + ROAD_HALF_WIDTH + 1] = True
        road_mask[seam - ROAD_HALF_WIDTH : seam + ROAD_HALF_WIDTH + 1, :] = True
    pixels[road_mask] = np.clip(ROAD_COLOR + noise[road_mask, None], 0, 255)
    image = Image.fromarray(pixels.astype(np.uint8), "RGB")
    draw = ImageDraw.Draw(image)

    for seam in SEAMS:
        draw.line(
            (seam - ROAD_HALF_WIDTH + 7, 0, seam - ROAD_HALF_WIDTH + 7, extent),
            fill=EDGE_COLOR,
            width=2,
        )
        draw.line(
            (seam + ROAD_HALF_WIDTH - 7, 0, seam + ROAD_HALF_WIDTH - 7, extent),
            fill=EDGE_COLOR,
            width=2,
        )
    for seam in SEAMS:
        draw.line(
            (0, seam - ROAD_HALF_WIDTH + 7, extent, seam - ROAD_HALF_WIDTH + 7),
            fill=EDGE_COLOR,
            width=2,
        )
        draw.line(
            (0, seam + ROAD_HALF_WIDTH - 7, extent, seam + ROAD_HALF_WIDTH - 7),
            fill=EDGE_COLOR,
            width=2,
        )

    intersection_clearance = 100
    for seam in SEAMS:
        for y in range(12, WORLD_SIZE, 48):
            if any(abs(y - crossing) < intersection_clearance for crossing in SEAMS):
                continue
            draw.rectangle((seam - 2, y, seam + 2, min(y + 22, extent)), fill=MARK_COLOR)
    for seam in SEAMS:
        for x in range(12, WORLD_SIZE, 48):
            if any(abs(x - crossing) < intersection_clearance for crossing in SEAMS):
                continue
            draw.rectangle((x, seam - 2, min(x + 22, extent), seam + 2), fill=MARK_COLOR)

    for x in SEAMS:
        for y in SEAMS:
            draw.rectangle(
                (x - ROAD_HALF_WIDTH, y - ROAD_HALF_WIDTH, x + ROAD_HALF_WIDTH, y + ROAD_HALF_WIDTH),
                fill=tuple(int(value) for value in ROAD_COLOR),
            )
            for offset in range(-24, 25, 12):
                draw.rectangle(
                    (x + offset - 3, y - ROAD_HALF_WIDTH - 16, x + offset + 3, y - ROAD_HALF_WIDTH - 5),
                    fill=CROSSWALK_COLOR,
                )
                draw.rectangle(
                    (x + offset - 3, y + ROAD_HALF_WIDTH + 5, x + offset + 3, y + ROAD_HALF_WIDTH + 16),
                    fill=CROSSWALK_COLOR,
                )
                draw.rectangle(
                    (x - ROAD_HALF_WIDTH - 16, y + offset - 3, x - ROAD_HALF_WIDTH - 5, y + offset + 3),
                    fill=CROSSWALK_COLOR,
                )
                draw.rectangle(
                    (x + ROAD_HALF_WIDTH + 5, y + offset - 3, x + ROAD_HALF_WIDTH + 16, y + offset + 3),
                    fill=CROSSWALK_COLOR,
                )

    return image


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def build_standable_centers(walkable: np.ndarray) -> np.ndarray:
    """Apply the six runtime foot-box samples to every 4px player-center cell."""
    samples = (
        (-8.75, 25.375),
        (0.0, 25.375),
        (8.75, 25.375),
        (-8.75, 38.0),
        (0.0, 38.0),
        (8.75, 38.0),
    )
    standable = np.ones_like(walkable, dtype=bool)
    height, width = walkable.shape
    for offset_x, offset_y in samples:
        delta_x = int(np.floor(offset_x / WALKABILITY_CELL_SIZE))
        delta_y = int(np.floor(offset_y / WALKABILITY_CELL_SIZE))
        sampled = np.zeros_like(walkable, dtype=bool)
        center_x_start = max(0, -delta_x)
        center_x_end = min(width, width - delta_x)
        center_y_start = max(0, -delta_y)
        center_y_end = min(height, height - delta_y)
        sampled[center_y_start:center_y_end, center_x_start:center_x_end] = walkable[
            center_y_start + delta_y:center_y_end + delta_y,
            center_x_start + delta_x:center_x_end + delta_x,
        ]
        standable &= sampled
    return standable


def build_walkability(image: Image.Image) -> tuple[np.ndarray, dict[str, object]]:
    """Extract conservative internal roads plus the generated connector-road grid."""
    analysis = image.resize(
        (WALKABILITY_GRID_SIZE, WALKABILITY_GRID_SIZE),
        Image.Resampling.BOX,
    )
    pixels = np.asarray(analysis, dtype=np.float32)
    smooth = np.stack(
        [ndimage.gaussian_filter(pixels[:, :, channel], sigma=1) for channel in range(3)],
        axis=2,
    )
    maximum = smooth.max(axis=2)
    minimum = smooth.min(axis=2)
    mean = smooth.mean(axis=2)
    chroma = maximum - minimum
    green_excess = smooth[:, :, 1] - (smooth[:, :, 0] + smooth[:, :, 2]) * 0.5
    grayscale = pixels.mean(axis=2)
    local_mean = ndimage.uniform_filter(grayscale, size=5)
    local_variance = ndimage.uniform_filter(grayscale * grayscale, size=5) - local_mean * local_mean
    local_std = np.sqrt(np.maximum(0, local_variance))

    strict_road = (
        (mean >= 28)
        & (mean <= 108)
        & (chroma <= 22)
        & (green_excess < 12)
        & (local_std <= 22)
    )
    road_seed = ndimage.binary_opening(strict_road, structure=np.ones((3, 35), dtype=bool))
    road_seed |= ndimage.binary_opening(strict_road, structure=np.ones((35, 3), dtype=bool))

    loose_road = (
        (mean >= 20)
        & (mean <= 135)
        & (chroma <= 32)
        & (green_excess < 15)
        & (local_std <= 30)
    )
    water = (
        (smooth[:, :, 2] > smooth[:, :, 0] + 12)
        & (smooth[:, :, 2] > smooth[:, :, 1] + 5)
        & (smooth[:, :, 2] > 55)
        & (chroma > 18)
    )
    vegetation = (green_excess > 22) & (smooth[:, :, 1] > 58)
    negative = ndimage.binary_dilation(water, iterations=3)
    negative |= ndimage.binary_dilation(vegetation, iterations=1)
    support = ndimage.binary_closing(
        loose_road & ~negative,
        structure=np.ones((5, 5), dtype=bool),
    )

    connector = np.zeros((WALKABILITY_GRID_SIZE, WALKABILITY_GRID_SIZE), dtype=bool)
    for seam in SEAMS:
        center = int(round(seam / WALKABILITY_CELL_SIZE))
        connector[:, center - 7:center + 8] = True
        connector[center - 7:center + 8, :] = True

    # The selected panorama contains a visible eastbound road and stone approach
    # from the x=2508 connector to the south entrance of the foundation library.
    # The generic texture classifier misses this shaded road, so preserve that
    # source-pixel-aligned corridor explicitly.
    library_approach = np.zeros((WALKABILITY_GRID_SIZE, WALKABILITY_GRID_SIZE), dtype=bool)
    approach_y = int(round(LIBRARY_APPROACH_ROAD_Y / WALKABILITY_CELL_SIZE))
    approach_half_height = int(np.ceil(LIBRARY_APPROACH_HALF_WIDTH / WALKABILITY_CELL_SIZE))
    approach_start_x = int(np.floor(LIBRARY_APPROACH_START_X / WALKABILITY_CELL_SIZE))
    approach_end_x = int(np.ceil(LIBRARY_APPROACH_END_X / WALKABILITY_CELL_SIZE))
    library_approach[
        approach_y - approach_half_height:approach_y + approach_half_height + 1,
        approach_start_x:approach_end_x + 1,
    ] = True

    walkable = (
        ndimage.binary_dilation(road_seed | connector, structure=np.ones((11, 11), dtype=bool))
        & support
    ) | connector
    walkable = ndimage.binary_closing(walkable, structure=np.ones((5, 5), dtype=bool))
    walkable &= ~negative
    labels, _ = ndimage.label(walkable)
    spawn_grid = (2508 // WALKABILITY_CELL_SIZE, 4800 // WALKABILITY_CELL_SIZE)
    spawn_label = labels[spawn_grid[1], spawn_grid[0]]
    if spawn_label == 0:
        raise RuntimeError("Campus spawn is not on the extracted road network")
    walkable = labels == spawn_label
    walkable = ndimage.binary_erosion(walkable, iterations=3)
    labels, _ = ndimage.label(walkable)
    spawn_label = labels[spawn_grid[1], spawn_grid[0]]
    if spawn_label == 0:
        raise RuntimeError("Campus spawn lost road access after foot-clearance erosion")
    walkable = labels == spawn_label

    # Restore the measured library road after generic erosion, then keep only
    # the component that remains connected to the campus spawn.
    walkable |= library_approach
    labels, _ = ndimage.label(walkable)
    spawn_label = labels[spawn_grid[1], spawn_grid[0]]
    walkable = labels == spawn_label

    standable = build_standable_centers(walkable)
    standable_labels, _ = ndimage.label(standable)
    standable_label = standable_labels[spawn_grid[1], spawn_grid[0]]
    if standable_label == 0:
        raise RuntimeError("Campus spawn does not fit the six-point player foot box")
    reachable = standable_labels == standable_label
    reachable_y, reachable_x = np.nonzero(reachable)
    gate_x, gate_y = LIBRARY_GATE
    gate_radius = LIBRARY_GATE_RADIUS
    distance_squared = (
        reachable_x * WALKABILITY_CELL_SIZE - gate_x
    ) ** 2 + (
        reachable_y * WALKABILITY_CELL_SIZE - gate_y
    ) ** 2
    within_gate = distance_squared <= gate_radius * gate_radius
    if not np.any(within_gate):
        raise RuntimeError("Spawn road component cannot reach the library interaction radius")
    gate_candidates = np.flatnonzero(within_gate)
    nearest_gate_index = gate_candidates[int(np.argmin(distance_squared[gate_candidates]))]
    gate_approach = {
        "x": int(reachable_x[nearest_gate_index] * WALKABILITY_CELL_SIZE),
        "y": int(reachable_y[nearest_gate_index] * WALKABILITY_CELL_SIZE),
    }

    tile_coverage: list[dict[str, object]] = []
    interior_margin = 64
    for row in range(GRID_SIZE):
        for column in range(GRID_SIZE):
            left = int(np.ceil((column * TILE_SIZE + interior_margin) / WALKABILITY_CELL_SIZE))
            right = int(np.floor(((column + 1) * TILE_SIZE - interior_margin) / WALKABILITY_CELL_SIZE))
            top = int(np.ceil((row * TILE_SIZE + interior_margin) / WALKABILITY_CELL_SIZE))
            bottom = int(np.floor(((row + 1) * TILE_SIZE - interior_margin) / WALKABILITY_CELL_SIZE))
            interior = walkable[top:bottom, left:right]
            tile_coverage.append({
                "tile": f"({row + 1},{column + 1})",
                "walkableCells": int(interior.sum()),
                "totalCells": int(interior.size),
            })

    coverage = float(walkable.mean())
    if not 0.06 <= coverage <= 0.18:
        raise RuntimeError(f"Extracted road coverage is outside the calibrated range: {coverage:.4f}")
    return walkable, {
        "gateApproach": gate_approach,
        "tileInteriorCoverage": tile_coverage,
    }


def write_runtime(
    runtime_path: Path,
    output_path: Path,
    mask_output: Path,
    walkable: np.ndarray,
    metadata: dict[str, object],
) -> tuple[str, str, str]:
    output_digest = sha256(output_path)
    mask_digest = sha256(mask_output)
    packed = np.packbits(walkable.reshape(-1), bitorder="little").tobytes()
    packed_digest = hashlib.sha256(packed).hexdigest()
    runtime = json.loads(runtime_path.read_text(encoding="utf-8"))
    runtime["source"]["plateSha256"] = output_digest
    runtime["source"]["tileOrder"] = [
        f"({row},{column})"
        for row in range(1, GRID_SIZE + 1)
        for column in range(1, GRID_SIZE + 1)
    ]
    runtime["source"]["overlapCorrections"] = [{
        "left": "(2,3)",
        "right": "(2,4)",
        "overlapWidth": KNOWN_OVERLAP_WIDTH,
        "verticalShift": KNOWN_OVERLAP_VERTICAL_SHIFT,
    }]
    runtime.pop("collisions", None)
    runtime["libraryGate"] = {
        "x": LIBRARY_GATE[0],
        "y": LIBRARY_GATE[1],
        "radius": LIBRARY_GATE_RADIUS,
    }
    for landmark in runtime.get("landmarks", []):
        if landmark.get("id") == "foundation_library":
            landmark["x"], landmark["y"] = FOUNDATION_LIBRARY_CENTER
            break
    runtime["walkability"] = {
        "cellSize": WALKABILITY_CELL_SIZE,
        "gridWidth": int(walkable.shape[1]),
        "gridHeight": int(walkable.shape[0]),
        "bitOrder": "little",
        "bitsBase64": base64.b64encode(packed).decode("ascii"),
        "walkableCells": int(walkable.sum()),
        "totalCells": int(walkable.size),
        "maskSha256": mask_digest,
        "bitsetSha256": packed_digest,
        "sourcePlateSha256": output_digest,
        **metadata,
    }
    runtime_path.write_text(
        json.dumps(runtime, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return output_digest, mask_digest, packed_digest


def main() -> None:
    args = parse_args()
    normalized: list[str] = []
    if args.walkability_only:
        panorama = Image.open(args.output).convert("RGB")
        if panorama.size != (WORLD_SIZE, WORLD_SIZE):
            raise RuntimeError(
                f"Selected panorama must be {WORLD_SIZE}x{WORLD_SIZE}; received "
                f"{panorama.width}x{panorama.height}"
            )
    else:
        panorama = Image.new("RGB", (WORLD_SIZE, WORLD_SIZE))
        for row in range(1, GRID_SIZE + 1):
            for column in range(1, GRID_SIZE + 1):
                path = tile_path(args.source, row, column)
                tile, source_size = load_normalized_tile(path)
                tile = correct_known_overlap(tile, row, column)
                panorama.paste(tile, ((column - 1) * TILE_SIZE, (row - 1) * TILE_SIZE))
                if source_size != (TILE_SIZE, TILE_SIZE):
                    normalized.append(f"({row},{column}) {source_size[0]}x{source_size[1]}")

        panorama = draw_connector_roads(panorama)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        panorama.save(args.output, format="PNG", optimize=True)
    walkable, metadata = build_walkability(panorama)
    args.mask_output.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray((walkable * 255).astype(np.uint8), mode="L").resize(
        (WORLD_SIZE, WORLD_SIZE),
        Image.Resampling.NEAREST,
    ).save(args.mask_output, format="PNG", optimize=True)
    digest, mask_digest, packed_digest = write_runtime(
        args.runtime,
        args.output,
        args.mask_output,
        walkable,
        metadata,
    )
    if args.walkability_only:
        print(f"rebuilt walkability from existing panorama {args.output}")
    else:
        print(f"rebuilt {args.output} from row-major 4x4 tiles")
        print(f"normalized tiles: {', '.join(normalized) if normalized else 'none'}")
        print(
            f"corrected overlap: (2,3)/(2,4) width={KNOWN_OVERLAP_WIDTH}px "
            f"verticalShift={KNOWN_OVERLAP_VERTICAL_SHIFT}px"
        )
    print(
        f"walkability={int(walkable.sum())}/{walkable.size} "
        f"gateApproach={metadata['gateApproach']} maskSha256={mask_digest} bitsetSha256={packed_digest}"
    )
    print(f"size={WORLD_SIZE}x{WORLD_SIZE} sha256={digest}")


if __name__ == "__main__":
    main()
