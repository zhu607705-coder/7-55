#!/usr/bin/env python3
"""Calibrate collision, story gates, depth, and wrap metadata for the loop panorama."""

from __future__ import annotations

import base64
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
CAMPUS_ASSET_DIR = ROOT / "src/assets/rpg/campus"
PLATE_PATH = CAMPUS_ASSET_DIR / "zijingang_campus_loop_panorama.png"
MASK_PATH = CAMPUS_ASSET_DIR / "zijingang_loop_walkability_mask.png"
LEGACY_PANORAMA_PATH = (
    CAMPUS_ASSET_DIR / "source/panorama/zijingang_legacy_panorama.png"
)
QIZHEN_PLATE_PATH = ROOT / "src/assets/rpg/interiors/qizhen_lake_reflection.png"
RUNTIME_PATH = ROOT / "src/data/maps/zijingang-campus-loop-runtime.json"

WORLD_WIDTH = 13668
WORLD_HEIGHT = 1084
CELL_SIZE = 4
PROMENADE_SURFACE_TOP = 864
INSERT_SPLIT_X = 8400
INSERT_WIDTH = 1924
INSERT_EDGE_FEATHER = 260
INSERT_BLEND_MODE = "layered-multiband-v1"

SPAWN = {"x": 800, "y": 968}
LIBRARY_GATE = {"x": 10924, "y": 770, "radius": 100}
LIBRARY_APPROACH = {"x": 10994, "y": 770}
FOUNDATION_LIBRARY = {"x": 10924, "y": 690}

CANTEEN = {
    "huntSpawn": {"x": 12424, "y": 1004},
    "gate": {"x": 756, "y": 756, "radius": 88},
    "approach": {"x": 756, "y": 756},
    "bike": {"x": 980, "y": 973},
}
THEATER = {
    "gate": {"x": 7730, "y": 735, "radius": 86},
    "approach": {"x": 7730, "y": 840},
}
QIZHEN = {
    "gate": {"x": 9362, "y": 900, "radius": 110},
    "approach": {"x": 9362, "y": 930},
    "segment": {
        "left": INSERT_SPLIT_X,
        "right": INSERT_SPLIT_X + INSERT_WIDTH,
        "center": INSERT_SPLIT_X + INSERT_WIDTH // 2,
    },
    "approachTransition": {
        "start": {"x": 7730, "y": 840},
        "stop": {"x": 9040, "y": 930},
        "waypoints": [
            {"x": 7820, "y": 900, "durationMs": 650},
            {"x": 8150, "y": 930, "durationMs": 1250},
            {"x": 8460, "y": 930, "durationMs": 1200},
            {"x": 8780, "y": 930, "durationMs": 1400},
            {"x": 9040, "y": 930, "durationMs": 1100},
        ],
        "paperStart": {"x": 7770, "y": 910},
        "paperStop": {"x": 9060, "y": 914},
        "trailSpacing": 74,
    },
}
LOOP = {
    "enabled": True,
    "roadTop": PROMENADE_SURFACE_TOP,
    "roadBottom": WORLD_HEIGHT,
    "leftTriggerX": 120,
    "rightTriggerX": WORLD_WIDTH - 120,
    "leftArrival": {"x": 360, "y": 960},
    "rightArrival": {"x": WORLD_WIDTH - 360, "y": 960},
    "fadeMs": 180,
    "cooldownMs": 900,
}
PERSPECTIVE = {
    "farY": 840,
    "nearY": 1040,
    "farMultiplier": 1.0,
    "nearMultiplier": 1.5,
    "baseMultiplier": 1.5,
}

ENTRANCE_APPROACHES = (
    {"id": "dining_hall", "left": 560, "right": 930, "top": 700},
    {"id": "west_round_hall", "left": 5440, "right": 5750, "top": 744},
    {"id": "theater", "left": 7672, "right": 7788, "top": 700},
)

PUBLIC_PATH_POLYGONS = (
    {
        "id": "museum_central_gate",
        "points": ((6130, 880), (6270, 880), (6260, 720), (6150, 720)),
    },
    {
        "id": "foundation_library_entry",
        "points": (
            (11044, 864),
            (11104, 864),
            (11104, 812),
            (11224, 812),
            (11224, 760),
            (10674, 760),
            (10674, 812),
            (11044, 812),
        ),
    },
    {
        "id": "east_riverside_walk",
        "points": ((11864, 900), (11984, 900), (11879, 600), (11794, 600)),
    },
    {
        "id": "east_main_hall_walk",
        "points": ((12954, 900), (13114, 900), (12889, 690), (12804, 690)),
    },
)

CANTEEN_FORECOURT = (
    (100, 744),
    (1260, 744),
    (1430, PROMENADE_SURFACE_TOP),
    (0, PROMENADE_SURFACE_TOP),
)

FOREGROUND_OBSTACLES = (
    {"id": "canteen_billboard", "left": 88, "right": 330, "top": 760, "bottom": 887},
    {"id": "canteen_vending_machine", "left": 350, "right": 456, "top": 736, "bottom": 874},
    {"id": "canteen_bins", "left": 322, "right": 474, "top": 850, "bottom": 904},
    {"id": "canteen_utility_box", "left": 1284, "right": 1396, "top": 776, "bottom": 900},
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def to_cell(value: int, *, end: bool = False) -> int:
    return (value + CELL_SIZE - 1) // CELL_SIZE if end else value // CELL_SIZE


def draw_grid_rect(
    draw: ImageDraw.ImageDraw,
    *,
    left: int,
    right: int,
    top: int,
    bottom: int,
    fill: int,
) -> None:
    draw.rectangle(
        (
            to_cell(left),
            to_cell(top),
            max(to_cell(left), to_cell(right, end=True) - 1),
            max(to_cell(top), to_cell(bottom, end=True) - 1),
        ),
        fill=fill,
    )


def draw_grid_polygon(
    draw: ImageDraw.ImageDraw,
    points: tuple[tuple[int, int], ...],
    *,
    fill: int,
) -> None:
    draw.polygon(
        [(round(x / CELL_SIZE), round(y / CELL_SIZE)) for x, y in points],
        fill=fill,
    )


def is_walkable(grid: bytearray, width: int, x: int, y: int) -> bool:
    grid_x = x // CELL_SIZE
    grid_y = y // CELL_SIZE
    return (
        0 <= grid_x < width
        and 0 <= grid_y < WORLD_HEIGHT // CELL_SIZE
        and bool(grid[grid_y * width + grid_x])
    )


def require_walkable(grid: bytearray, width: int, label: str, point: dict[str, int]) -> None:
    if not is_walkable(grid, width, point["x"], point["y"]):
        raise RuntimeError(f"{label} must be walkable at {point['x']},{point['y']}")


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
            f"Loop panorama must be {WORLD_WIDTH}x{WORLD_HEIGHT}; "
            f"received {plate.width}x{plate.height}"
        )

    grid_width = WORLD_WIDTH // CELL_SIZE
    grid_height = WORLD_HEIGHT // CELL_SIZE
    grid_image = Image.new("L", (grid_width, grid_height), 0)
    draw = ImageDraw.Draw(grid_image)

    draw_grid_rect(
        draw,
        left=0,
        right=WORLD_WIDTH,
        top=PROMENADE_SURFACE_TOP,
        bottom=WORLD_HEIGHT,
        fill=255,
    )
    draw_grid_polygon(draw, CANTEEN_FORECOURT, fill=255)
    for approach in ENTRANCE_APPROACHES:
        draw_grid_rect(
            draw,
            left=approach["left"],
            right=approach["right"],
            top=approach["top"],
            bottom=WORLD_HEIGHT,
            fill=255,
        )
    for path in PUBLIC_PATH_POLYGONS:
        draw_grid_polygon(draw, path["points"], fill=255)
    for obstacle in FOREGROUND_OBSTACLES:
        draw_grid_rect(draw, **{key: value for key, value in obstacle.items() if key != "id"}, fill=0)

    grid = bytearray(1 if value else 0 for value in grid_image.tobytes())
    for label, point in (
        ("Campus spawn", SPAWN),
        ("Library gate", LIBRARY_GATE),
        ("Library approach", LIBRARY_APPROACH),
        ("Canteen hunt spawn", CANTEEN["huntSpawn"]),
        ("Canteen gate", CANTEEN["gate"]),
        ("Canteen approach", CANTEEN["approach"]),
        ("Canteen bike", CANTEEN["bike"]),
        ("Theater gate", THEATER["gate"]),
        ("Theater approach", THEATER["approach"]),
        ("Qizhen gate", QIZHEN["gate"]),
        ("Qizhen approach", QIZHEN["approach"]),
        ("Loop left arrival", LOOP["leftArrival"]),
        ("Loop right arrival", LOOP["rightArrival"]),
        ("Qizhen transition stop", QIZHEN["approachTransition"]["stop"]),
    ):
        require_walkable(grid, grid_width, label, point)
    for index, point in enumerate(QIZHEN["approachTransition"]["waypoints"]):
        require_walkable(grid, grid_width, f"Qizhen transition waypoint {index + 1}", point)

    mask_image = grid_image.resize(
        (WORLD_WIDTH, WORLD_HEIGHT),
        Image.Resampling.NEAREST,
    )
    mask_image.save(MASK_PATH, format="PNG", optimize=True)

    packed = pack_little_endian_bits(grid)
    plate_digest = sha256(PLATE_PATH)
    mask_digest = sha256(MASK_PATH)
    runtime = {
        "source": {
            "map": "user-approved side-view campus loop panorama",
            "projection": "side-view-pseudo-2.5d",
            "worldScale": (
                "legacy 11744x1084 campus panorama plus one 1924px Qizhen Lake "
                "segment inserted east of the first theater; one continuous foreground "
                "road and bidirectional boundary wrap form the loop"
            ),
            "plateSha256": plate_digest,
            "sourceSha256": {
                "legacyPanorama": sha256(LEGACY_PANORAMA_PATH),
                "qizhenReflection": sha256(QIZHEN_PLATE_PATH),
            },
            "insertion": {
                "splitX": INSERT_SPLIT_X,
                "width": INSERT_WIDTH,
                "leftFeather": INSERT_EDGE_FEATHER,
                "rightFeather": INSERT_EDGE_FEATHER,
                "blendMode": INSERT_BLEND_MODE,
                "detailFeatherRange": [40, 52],
                "roadTop": PROMENADE_SURFACE_TOP,
            },
        },
        "world": {"width": WORLD_WIDTH, "height": WORLD_HEIGHT},
        "spawn": SPAWN,
        "libraryGate": LIBRARY_GATE,
        "bridges": [],
        "landmarks": [
            {"id": "foundation_library", **FOUNDATION_LIBRARY},
        ],
        "walkability": {
            "cellSize": CELL_SIZE,
            "gridWidth": grid_width,
            "gridHeight": grid_height,
            "bitOrder": "little",
            "bitsBase64": base64.b64encode(packed).decode("ascii"),
            "walkableCells": int(sum(grid)),
            "totalCells": len(grid),
            "maskSha256": mask_digest,
            "bitsetSha256": hashlib.sha256(packed).hexdigest(),
            "sourcePlateSha256": plate_digest,
            "gateApproach": LIBRARY_APPROACH,
            "promenadeSurfaceTop": PROMENADE_SURFACE_TOP,
            "entranceApproaches": list(ENTRANCE_APPROACHES),
            "publicPathPolygons": [
                {"id": path["id"], "points": [list(point) for point in path["points"]]}
                for path in PUBLIC_PATH_POLYGONS
            ],
            "foregroundObstacles": list(FOREGROUND_OBSTACLES),
        },
        "canteen": CANTEEN,
        "theater": THEATER,
        "qizhen": QIZHEN,
        "loop": LOOP,
        "perspective": PERSPECTIVE,
    }
    RUNTIME_PATH.write_text(
        json.dumps(runtime, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(
        f"calibrated loop campus {WORLD_WIDTH}x{WORLD_HEIGHT} "
        f"walkable={sum(grid)}/{len(grid)} theater={THEATER['gate']['x']},{THEATER['gate']['y']} "
        f"qizhen={QIZHEN['gate']['x']},{QIZHEN['gate']['y']} "
        f"plateSha256={plate_digest}"
    )


if __name__ == "__main__":
    main()
