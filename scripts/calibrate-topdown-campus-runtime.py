#!/usr/bin/env python3
"""Build the runtime contract for the approved top-down Zijin'gang campus plate."""

from __future__ import annotations

import base64
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
CAMPUS_ASSET_DIR = ROOT / "src/assets/rpg/campus"
SOURCE_DIR = CAMPUS_ASSET_DIR / "source/topdown"
PLATE_PATH = CAMPUS_ASSET_DIR / "zijingang_campus_plate.png"
ROAD_SOURCE_PATH = SOURCE_DIR / "campus_roads_source.png"
WATER_SOURCE_PATH = SOURCE_DIR / "campus_water_source.png"
BUILDING_SOURCE_PATH = SOURCE_DIR / "campus_buildings_source.png"
MASK_PATH = CAMPUS_ASSET_DIR / "zijingang_road_walkability_mask.png"
RUNTIME_PATH = ROOT / "src/data/maps/zijingang-campus-runtime.json"

WORLD_WIDTH = 4516
WORLD_HEIGHT = 3420
CELL_SIZE = 4

SPAWN = {"x": 2550, "y": 650}
LIBRARY_LANDMARK = {"x": 3718, "y": 1568}
LIBRARY_GATE = {"x": 3706, "y": 1696, "radius": 112}
LIBRARY_APPROACH = {"x": 3805, "y": 1680}
CANTEEN = {
    "huntSpawn": {"x": 4200, "y": 2868},
    "gate": {"x": 3120, "y": 620, "radius": 88},
    "approach": {"x": 3120, "y": 650},
    "bike": {"x": 3220, "y": 650},
}

# Manual collision authority. Only the verified Basic Library forecourt remains
# special-cased; Zijun Bifeng and East Canteen use the road alpha layer alone.
WALKABLE_POLYGONS = [
    # Basic Library east/south forecourt and its short connection to the east road.
    [(3732, 1516), (3876, 1516), (3876, 1740), (3652, 1740), (3652, 1692), (3732, 1692)],
]

# The Basic Library body is subtracted from its manually opened forecourt.
# Dense landscaping elsewhere stays blocked because it is absent from both the
# road mask and the single verified polygon above.
SOLID_POLYGONS = [
    # Basic Library tower, east wing, and south base. Separate polygons keep
    # the surrounding grass and forecourt open instead of blocking one AABB.
    [
        (3642, 1470),
        (3720, 1470),
        (3738, 1645),
        (3610, 1645),
        (3610, 1570),
        (3642, 1570),
    ],
    [(3690, 1510), (3825, 1510), (3825, 1665), (3690, 1665)],
    [(3610, 1600), (3740, 1600), (3740, 1665), (3610, 1665)],
]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def require_matching_rgba(path: Path, label: str) -> Image.Image:
    image = Image.open(path).convert("RGBA")
    if image.size != (WORLD_WIDTH, WORLD_HEIGHT):
        raise RuntimeError(
            f"{label} must be {WORLD_WIDTH}x{WORLD_HEIGHT}; "
            f"received {image.width}x{image.height}"
        )
    return image


def threshold_channel(image: Image.Image, threshold: int) -> bytearray:
    return bytearray(value >= threshold for value in image.tobytes())


def rasterize_polygons(polygons: list[list[tuple[int, int]]]) -> bytearray:
    image = Image.new("L", (WORLD_WIDTH, WORLD_HEIGHT), 0)
    draw = ImageDraw.Draw(image)
    for polygon in polygons:
        draw.polygon(polygon, fill=255)
    grid_image = image.resize(
        (WORLD_WIDTH // CELL_SIZE, WORLD_HEIGHT // CELL_SIZE),
        Image.Resampling.BOX,
    )
    return threshold_channel(grid_image, 128)


def point_is_walkable(
    grid: bytearray,
    grid_width: int,
    grid_height: int,
    x: int,
    y: int,
) -> bool:
    grid_x = x // CELL_SIZE
    grid_y = y // CELL_SIZE
    return (
        0 <= grid_x < grid_width
        and 0 <= grid_y < grid_height
        and bool(grid[grid_y * grid_width + grid_x])
    )


def require_walkable(
    grid: bytearray,
    grid_width: int,
    grid_height: int,
    label: str,
    point: dict[str, int],
) -> None:
    if not point_is_walkable(
        grid,
        grid_width,
        grid_height,
        point["x"],
        point["y"],
    ):
        raise RuntimeError(
            f"{label} must be walkable at {point['x']},{point['y']}"
        )


def pack_little_endian_bits(grid: bytearray) -> bytes:
    packed = bytearray((len(grid) + 7) // 8)
    for index, value in enumerate(grid):
        if value:
            packed[index >> 3] |= 1 << (index & 7)
    return bytes(packed)


def main() -> None:
    plate = Image.open(PLATE_PATH).convert("RGB")
    if plate.size != (WORLD_WIDTH, WORLD_HEIGHT):
        raise RuntimeError(
            f"Top-down campus plate must be {WORLD_WIDTH}x{WORLD_HEIGHT}; "
            f"received {plate.width}x{plate.height}"
        )

    roads = require_matching_rgba(ROAD_SOURCE_PATH, "Campus road source")
    water = require_matching_rgba(WATER_SOURCE_PATH, "Campus water source")
    require_matching_rgba(BUILDING_SOURCE_PATH, "Campus building source")

    grid_size = (WORLD_WIDTH // CELL_SIZE, WORLD_HEIGHT // CELL_SIZE)
    road_alpha = roads.getchannel("A").resize(grid_size, Image.Resampling.BOX)
    water_alpha = water.getchannel("A").resize(grid_size, Image.Resampling.BOX)
    road_grid = threshold_channel(road_alpha, 192)
    water_grid = threshold_channel(water_alpha, 64)

    manual_walkable = rasterize_polygons(WALKABLE_POLYGONS)
    manual_solids = rasterize_polygons(SOLID_POLYGONS)

    # Roads remain authoritative at bridges. Water only removes manually-added
    # surfaces, so a river painted beneath a road cannot sever the network.
    grid = bytearray(len(road_grid))
    for index, road_cell in enumerate(road_grid):
        grid[index] = (
            (road_cell or (manual_walkable[index] and not water_grid[index]))
            and not manual_solids[index]
        )

    grid_width, grid_height = grid_size
    require_walkable(grid, grid_width, grid_height, "Campus spawn", SPAWN)
    require_walkable(grid, grid_width, grid_height, "Library gate", LIBRARY_GATE)
    require_walkable(
        grid,
        grid_width,
        grid_height,
        "Library approach",
        LIBRARY_APPROACH,
    )
    require_walkable(
        grid,
        grid_width,
        grid_height,
        "Canteen hunt spawn",
        CANTEEN["huntSpawn"],
    )
    require_walkable(
        grid,
        grid_width,
        grid_height,
        "Canteen gate",
        CANTEEN["gate"],
    )
    require_walkable(
        grid,
        grid_width,
        grid_height,
        "Canteen approach",
        CANTEEN["approach"],
    )
    require_walkable(
        grid,
        grid_width,
        grid_height,
        "Canteen bike",
        CANTEEN["bike"],
    )

    grid_pixels = bytearray(255 if value else 0 for value in grid)
    mask_image = Image.frombytes("L", grid_size, bytes(grid_pixels)).resize(
        (WORLD_WIDTH, WORLD_HEIGHT),
        Image.Resampling.NEAREST,
    )
    mask_image.save(MASK_PATH, format="PNG", optimize=True)

    packed = pack_little_endian_bits(grid)
    plate_digest = sha256(PLATE_PATH)
    mask_digest = sha256(MASK_PATH)
    bitset_digest = hashlib.sha256(packed).hexdigest()
    walkable_cells = sum(grid)
    road_cells = sum(road_grid)
    manual_open_cells = sum(
        cell and not road_grid[index] for index, cell in enumerate(grid)
    )

    runtime = json.loads(RUNTIME_PATH.read_text(encoding="utf-8"))
    runtime["source"] = {
        "map": "user-selected repository top-down campus artwork",
        "worldScale": (
            "single 4516px x 3420px north-up top-down campus plate; separated "
            "road and water alpha layers seed the conservative walkability mask"
        ),
        "plateSha256": plate_digest,
        "layerSha256": {
            "roads": sha256(ROAD_SOURCE_PATH),
            "water": sha256(WATER_SOURCE_PATH),
            "buildings": sha256(BUILDING_SOURCE_PATH),
        },
    }
    runtime["world"] = {"width": WORLD_WIDTH, "height": WORLD_HEIGHT}
    runtime["spawn"] = SPAWN
    runtime["libraryGate"] = LIBRARY_GATE
    runtime["canteen"] = CANTEEN
    runtime["bridges"] = []
    runtime["landmarks"] = [
        {
            "id": "foundation_library",
            "x": LIBRARY_LANDMARK["x"],
            "y": LIBRARY_LANDMARK["y"],
        }
    ]
    runtime["walkability"] = {
        "cellSize": CELL_SIZE,
        "gridWidth": grid_width,
        "gridHeight": grid_height,
        "bitOrder": "little",
        "bitsBase64": base64.b64encode(packed).decode("ascii"),
        "walkableCells": walkable_cells,
        "roadCells": road_cells,
        "manualOpenCells": manual_open_cells,
        "totalCells": len(grid),
        "maskSha256": mask_digest,
        "bitsetSha256": bitset_digest,
        "sourcePlateSha256": plate_digest,
        "gateApproach": LIBRARY_APPROACH,
    }
    RUNTIME_PATH.write_text(
        json.dumps(runtime, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print(
        f"calibrated top-down campus {WORLD_WIDTH}x{WORLD_HEIGHT} "
        f"walkable={walkable_cells}/{len(grid)} "
        f"road={road_cells} manual={manual_open_cells} "
        f"libraryGate={LIBRARY_GATE['x']},{LIBRARY_GATE['y']} "
        f"approach={LIBRARY_APPROACH['x']},{LIBRARY_APPROACH['y']} "
        f"plateSha256={plate_digest} maskSha256={mask_digest} "
        f"bitsetSha256={bitset_digest}"
    )


if __name__ == "__main__":
    main()
