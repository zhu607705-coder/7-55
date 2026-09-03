#!/usr/bin/env python3
"""Build the compact runtime mask for the animated Zijin'gang campus water.

The approved campus is a single source-sized plate at runtime, while its
authoring water, road, and building layers remain available as aligned RGBA
images. This generator turns those authoring layers into a feathered visual
mask without treating one shade of blue as the water boundary:

* strong blue/cyan pixels seed the connected water surface;
* nearby neutral, dark, and white pixels are admitted so foam and highlights
  do not punch holes through the mask;
* green/brown banks stop the growth;
* road alpha is applied after feathering, so every road-water join remains a
  clean hard edge without exposing a strip of the original painted water;
* one explicitly approved building-layer river is added, while roofs, courts,
  and unrelated decorative ponds remain untouched;
* a transparent grayscale correction layer can author exact coverage and soft
  transitions after the automatic edge feather.

The result is packed into a compact 128px-cell alpha atlas. The browser consumes
only that atlas, a small placement manifest, and the three-frame water texture;
it never loads the 4516x3420 authoring layers.
"""

from __future__ import annotations

import argparse
import hashlib
import io
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
CAMPUS_DIR = ROOT / "src/assets/rpg/campus"
SOURCE_DIR = CAMPUS_DIR / "source/topdown"
PLATE_PATH = CAMPUS_DIR / "zijingang_campus_plate.png"
WATER_SOURCE_PATH = SOURCE_DIR / "campus_water_source.png"
ROAD_SOURCE_PATH = SOURCE_DIR / "campus_roads_source.png"
BUILDING_SOURCE_PATH = SOURCE_DIR / "campus_buildings_source.png"
WATER_ATLAS_PATH = CAMPUS_DIR / "water/zijingang_water_frames.png"
MASK_ATLAS_PATH = CAMPUS_DIR / "water/zijingang_water_mask_atlas.png"
WATER_OVERRIDE_PATH = SOURCE_DIR / "campus_water_mask_override.png"
OUTPUT_PATH = ROOT / "src/data/maps/zijingang-campus-water-overlay.json"

WORLD_WIDTH = 4516
WORLD_HEIGHT = 3420
TILE_SIZE = 128
FRAME_COUNT = 3
FRAME_DURATION_MS = 500
MASK_ATLAS_COLUMNS = 16
ALPHA_THRESHOLD = 64
OCCLUDER_ALPHA_THRESHOLD = 48
STRONG_BLUE_OVER_GREEN = 5
STRONG_BLUE_OVER_RED = 15
NEUTRAL_BLUE_UNDER_GREEN = 8
NEUTRAL_BLUE_UNDER_RED = 12
GROWTH_PASSES = 8
BUILDING_EDGE_GROWTH_PASSES = 3
GROWTH_FILTER_SIZE = 5
CLOSE_FILTER_SIZE = 9
EDGE_FEATHER_RADIUS = 3

# The user-approved embedded-water exception. Other water-like pixels in the
# building source (blue roofs, courts, and decorative ponds) stay untouched.
EMBEDDED_WATER_REGIONS = (
    {
        "id": "north_mid_river",
        "bounds": (1940, 650, 2110, 1250),
    },
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def require_rgba(path: Path, label: str) -> Image.Image:
    image = Image.open(path).convert("RGBA")
    if image.size != (WORLD_WIDTH, WORLD_HEIGHT):
        raise RuntimeError(
            f"{label} must be {WORLD_WIDTH}x{WORLD_HEIGHT}; "
            f"received {image.width}x{image.height}"
        )
    return image


def threshold_at_least(image: Image.Image, value: int) -> Image.Image:
    return image.point(lambda channel: 255 if channel >= value else 0, mode="1").convert("L")


def difference_at_least(
    left: Image.Image,
    right: Image.Image,
    minimum: int,
) -> Image.Image:
    shifted = ImageChops.subtract(left, right, scale=1.0, offset=128)
    return threshold_at_least(shifted, 128 + minimum)


def and_masks(*images: Image.Image) -> Image.Image:
    result = images[0]
    for image in images[1:]:
        result = ImageChops.multiply(result, image)
    return result


def or_masks(*images: Image.Image) -> Image.Image:
    result = images[0]
    for image in images[1:]:
        result = ImageChops.lighter(result, image)
    return result


def connected_water_mask(
    source: Image.Image,
    allowed_region: Image.Image | None = None,
    growth_passes: int = GROWTH_PASSES,
) -> tuple[Image.Image, Image.Image]:
    red, green, blue, alpha = source.split()
    visible = threshold_at_least(alpha, ALPHA_THRESHOLD)
    if allowed_region is not None:
        visible = and_masks(visible, allowed_region)

    strong_water_seed = and_masks(
        visible,
        difference_at_least(blue, green, STRONG_BLUE_OVER_GREEN),
        difference_at_least(blue, red, STRONG_BLUE_OVER_RED),
    )

    # White foam and very dark ripples may have little saturation.  They are
    # candidates only when locally connected to a strong water seed; green or
    # warm shoreline pixels fail these relaxed blue-balance constraints.
    connected_candidate = and_masks(
        visible,
        difference_at_least(blue, green, -NEUTRAL_BLUE_UNDER_GREEN),
        difference_at_least(blue, red, -NEUTRAL_BLUE_UNDER_RED),
    )

    water = strong_water_seed
    for _ in range(growth_passes):
        grown = water.filter(ImageFilter.MaxFilter(GROWTH_FILTER_SIZE))
        water = or_masks(water, and_masks(grown, connected_candidate))

    # Close narrow white ripple gaps. Do not re-apply the color candidate here:
    # doing so would punch every white crest back out of the completed surface.
    # The close operation preserves the outer topology, while source alpha and
    # foreground masks retain the authored banks, islands, and bridges.
    water = water.filter(ImageFilter.MaxFilter(CLOSE_FILTER_SIZE))
    water = water.filter(ImageFilter.MinFilter(CLOSE_FILTER_SIZE))
    return and_masks(water, visible), connected_candidate


def build_visual_water_mask(
    water_source: Image.Image,
    building_source: Image.Image,
) -> Image.Image:
    water, _ = connected_water_mask(water_source)
    building_water_like, _ = connected_water_mask(
        building_source,
        growth_passes=BUILDING_EDGE_GROWTH_PASSES,
    )

    building_alpha = threshold_at_least(
        building_source.getchannel("A"),
        OCCLUDER_ALPHA_THRESHOLD,
    )
    # Large building-source blocks overlap some valid bank water. Preserve only
    # their locally connected blue/white water pixels; all remaining building
    # alpha still cuts structures and islands out of the animated surface.
    building_occluder = and_masks(
        building_alpha,
        ImageChops.invert(building_water_like),
    )
    # Cut structures at their authored boundary before feathering. Expanding
    # this keep-out used to leave a visible ring of the old painted water by
    # Crescent Building and along Qizhen Lake's right bank.
    water = and_masks(water, ImageChops.invert(building_occluder))

    embedded_region = Image.new("L", (WORLD_WIDTH, WORLD_HEIGHT), 0)
    embedded_draw = ImageDraw.Draw(embedded_region)
    for region in EMBEDDED_WATER_REGIONS:
        left, top, right, bottom = region["bounds"]
        embedded_draw.rectangle((left, top, right - 1, bottom - 1), fill=255)
    embedded_water, _ = connected_water_mask(building_source, embedded_region)
    return threshold_at_least(or_masks(water, embedded_water), 128)


def build_alpha_mask(
    binary_mask: Image.Image,
    water_override: Image.Image,
    road_source: Image.Image,
) -> Image.Image:
    automatic_alpha = binary_mask.filter(ImageFilter.BoxBlur(EDGE_FEATHER_RADIUS))

    # Transparent pixels retain the automatic result. On painted pixels the
    # grayscale value is the requested final coverage: black=0, white=255, and
    # intermediate gray values author an exact feathered transition. The PNG's
    # own alpha supports soft-brush blending with the automatic mask as well.
    override_gray = ImageOps.grayscale(water_override)
    override_alpha = water_override.getchannel("A")
    corrected_alpha = Image.composite(override_gray, automatic_alpha, override_alpha)

    # Roads and bridge decks are the intentional exception to soft shorelines.
    # Clip them after both automatic feathering and manual correction so their
    # source-pixel boundary stays hard and no translucent old-water seam shows.
    road_alpha = threshold_at_least(
        road_source.getchannel("A"),
        OCCLUDER_ALPHA_THRESHOLD,
    )
    return and_masks(corrected_alpha, ImageChops.invert(road_alpha))


def build_mask_atlas(mask: Image.Image) -> tuple[list[dict[str, int]], bytes, dict[str, int]]:
    tiles: list[dict[str, int]] = []
    tile_masks: list[Image.Image] = []
    for origin_y in range(0, WORLD_HEIGHT, TILE_SIZE):
        for origin_x in range(0, WORLD_WIDTH, TILE_SIZE):
            width = min(TILE_SIZE, WORLD_WIDTH - origin_x)
            height = min(TILE_SIZE, WORLD_HEIGHT - origin_y)
            tile = mask.crop((origin_x, origin_y, origin_x + width, origin_y + height))
            _, maximum = tile.getextrema()
            if maximum == 0:
                continue
            entry = {
                "x": origin_x,
                "y": origin_y,
                "width": width,
                "height": height,
                "maskIndex": len(tile_masks),
            }
            tiles.append(entry)
            tile_masks.append(tile)

    rows = (len(tile_masks) + MASK_ATLAS_COLUMNS - 1) // MASK_ATLAS_COLUMNS
    atlas_width = MASK_ATLAS_COLUMNS * TILE_SIZE
    atlas_height = rows * TILE_SIZE
    atlas = Image.new("RGBA", (atlas_width, atlas_height), (255, 255, 255, 0))
    for index, tile in enumerate(tile_masks):
        frame = Image.new("RGBA", tile.size, (255, 255, 255, 0))
        frame.putalpha(tile)
        atlas.paste(
            frame,
            (
                (index % MASK_ATLAS_COLUMNS) * TILE_SIZE,
                (index // MASK_ATLAS_COLUMNS) * TILE_SIZE,
            ),
        )

    output = io.BytesIO()
    atlas.save(output, format="PNG", optimize=True)
    return tiles, output.getvalue(), {
        "columns": MASK_ATLAS_COLUMNS,
        "rows": rows,
        "cellSize": TILE_SIZE,
        "width": atlas_width,
        "height": atlas_height,
    }


def build_manifest() -> tuple[dict[str, object], Image.Image, bytes]:
    plate = Image.open(PLATE_PATH)
    if plate.size != (WORLD_WIDTH, WORLD_HEIGHT):
        raise RuntimeError(
            f"Campus plate must be {WORLD_WIDTH}x{WORLD_HEIGHT}; "
            f"received {plate.width}x{plate.height}"
        )
    atlas = Image.open(WATER_ATLAS_PATH)
    expected_atlas_size = (TILE_SIZE * FRAME_COUNT, TILE_SIZE)
    if atlas.size != expected_atlas_size:
        raise RuntimeError(
            f"Water atlas must be {expected_atlas_size[0]}x{expected_atlas_size[1]}; "
            f"received {atlas.width}x{atlas.height}"
        )

    water_source = require_rgba(WATER_SOURCE_PATH, "Campus water source")
    road_source = require_rgba(ROAD_SOURCE_PATH, "Campus road source")
    building_source = require_rgba(BUILDING_SOURCE_PATH, "Campus building source")
    water_override = require_rgba(WATER_OVERRIDE_PATH, "Campus water override")
    binary_mask = build_visual_water_mask(
        water_source,
        building_source,
    )
    alpha_mask = build_alpha_mask(binary_mask, water_override, road_source)
    tiles, mask_atlas_bytes, mask_atlas_layout = build_mask_atlas(alpha_mask)
    raw_alpha = alpha_mask.tobytes()
    bounds = alpha_mask.getbbox()
    histogram = alpha_mask.histogram()
    pixel_count = sum(histogram[1:])
    opaque_pixel_count = histogram[255]
    coverage_sum = sum(alpha * count for alpha, count in enumerate(histogram))
    alpha_level_count = sum(1 for alpha, count in enumerate(histogram) if alpha and count)

    manifest: dict[str, object] = {
        "version": 1,
        "world": {"width": WORLD_WIDTH, "height": WORLD_HEIGHT},
        "tileSize": TILE_SIZE,
        "animation": {
            "frameCount": FRAME_COUNT,
            "frameWidth": TILE_SIZE,
            "frameHeight": TILE_SIZE,
            "frameDurationMs": FRAME_DURATION_MS,
            "sampling": "nearest",
        },
        "source": {
            "waterAtlas": "src/assets/rpg/campus/water/zijingang_water_frames.png",
            "waterAtlasSha256": sha256(WATER_ATLAS_PATH),
            "waterLayerSha256": sha256(WATER_SOURCE_PATH),
            "roadLayerSha256": sha256(ROAD_SOURCE_PATH),
            "buildingLayerSha256": sha256(BUILDING_SOURCE_PATH),
            "manualOverride": "src/assets/rpg/campus/source/topdown/campus_water_mask_override.png",
            "manualOverrideSha256": sha256(WATER_OVERRIDE_PATH),
            "maskAtlas": "src/assets/rpg/campus/water/zijingang_water_mask_atlas.png",
            "maskAtlasSha256": sha256_bytes(mask_atlas_bytes),
        },
        "rendering": {
            "edgeFeatherRadius": EDGE_FEATHER_RADIUS,
            "naturalEdge": "feathered",
            "roadEdge": "hard",
            "maskAtlas": mask_atlas_layout,
            "embeddedWaterRegions": [
                {"id": region["id"], "bounds": list(region["bounds"])}
                for region in EMBEDDED_WATER_REGIONS
            ],
        },
        "mask": {
            "encoding": "rgba-alpha-atlas",
            "sha256": hashlib.sha256(raw_alpha).hexdigest(),
            "pixelCount": pixel_count,
            "opaquePixelCount": opaque_pixel_count,
            "coverageSum": coverage_sum,
            "alphaLevelCount": alpha_level_count,
            "bounds": list(bounds) if bounds is not None else None,
            "tileCount": len(tiles),
            "algorithm": {
                "alphaThreshold": ALPHA_THRESHOLD,
                "occluderAlphaThreshold": OCCLUDER_ALPHA_THRESHOLD,
                "strongBlueOverGreen": STRONG_BLUE_OVER_GREEN,
                "strongBlueOverRed": STRONG_BLUE_OVER_RED,
                "neutralBlueUnderGreen": NEUTRAL_BLUE_UNDER_GREEN,
                "neutralBlueUnderRed": NEUTRAL_BLUE_UNDER_RED,
                "growthPasses": GROWTH_PASSES,
                "buildingEdgeGrowthPasses": BUILDING_EDGE_GROWTH_PASSES,
                "growthFilterSize": GROWTH_FILTER_SIZE,
                "closeFilterSize": CLOSE_FILTER_SIZE,
            },
        },
        "tiles": tiles,
    }
    return manifest, alpha_mask, mask_atlas_bytes


def write_preview(mask: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    plate = Image.open(PLATE_PATH).convert("RGBA")
    overlay = Image.new("RGBA", plate.size, (255, 48, 96, 0))
    overlay.putalpha(mask.point(lambda value: round(value * 0.62)))
    Image.alpha_composite(plate, overlay).save(path, format="PNG", optimize=True)


def initialize_override() -> None:
    if WATER_OVERRIDE_PATH.exists():
        return
    WATER_OVERRIDE_PATH.parent.mkdir(parents=True, exist_ok=True)
    Image.new(
        "RGBA",
        (WORLD_WIDTH, WORLD_HEIGHT),
        (0, 0, 0, 0),
    ).save(WATER_OVERRIDE_PATH, format="PNG", optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check",
        action="store_true",
        help="Fail when the checked-in manifest differs from a fresh build.",
    )
    parser.add_argument(
        "--preview",
        type=Path,
        help="Optionally write a red mask overlay for visual authoring QA.",
    )
    parser.add_argument(
        "--init-override",
        action="store_true",
        help="Create the blank transparent manual correction layer when absent.",
    )
    args = parser.parse_args()

    if args.init_override:
        initialize_override()
    if not WATER_OVERRIDE_PATH.exists():
        raise RuntimeError(
            "Campus water override is missing; run this script once with "
            "--init-override"
        )

    manifest, mask, mask_atlas_bytes = build_manifest()
    serialized = json.dumps(manifest, ensure_ascii=False, separators=(",", ":")) + "\n"
    if args.check:
        if (
            not OUTPUT_PATH.exists()
            or OUTPUT_PATH.read_text(encoding="utf-8") != serialized
            or not MASK_ATLAS_PATH.exists()
            or MASK_ATLAS_PATH.read_bytes() != mask_atlas_bytes
        ):
            raise RuntimeError(
                "Campus water overlay manifest or alpha atlas is stale; run "
                "python scripts/build-zijingang-water-overlay.py"
            )
    else:
        OUTPUT_PATH.write_text(serialized, encoding="utf-8")
        MASK_ATLAS_PATH.write_bytes(mask_atlas_bytes)

    if args.preview is not None:
        write_preview(mask, args.preview.resolve())

    mask_info = manifest["mask"]
    print(
        "built Zijin'gang water overlay "
        f"pixels={mask_info['pixelCount']} "
        f"tiles={mask_info['tileCount']} "
        f"alphaLevels={mask_info['alphaLevelCount']} "
        f"sha256={mask_info['sha256']}"
    )


if __name__ == "__main__":
    main()
