#!/usr/bin/env python3

from __future__ import annotations

import colorsys
import json
import math
import random
import re
from pathlib import Path
from typing import Any, Iterable

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "src/assets/rpg/campus/source"
SOURCE_MAP = SOURCE_DIR / "zijingang_official_map_reference.png"
SOURCE_FEATURES = SOURCE_DIR / "zijingang_official_hotspots_reference.json"
OUTPUT_PLATE = ROOT / "src/assets/rpg/campus/zijingang_campus_plate.png"
OUTPUT_RUNTIME = ROOT / "src/data/maps/zijingang-campus-runtime.json"

WORLD_WIDTH = 2400
WORLD_HEIGHT = 1920
PIXEL_SCALE = 2
BASE_WIDTH = WORLD_WIDTH // PIXEL_SCALE
BASE_HEIGHT = WORLD_HEIGHT // PIXEL_SCALE
CONTENT_BOUNDS = tuple(value // PIXEL_SCALE for value in (176, 80, 2224, 1840))

OFFICIAL_BOUNDS = {
    "min_x": 1_867_295.0663178791,
    "min_y": 1_976_904.1468487254,
    "max_x": 1_869_188.5869699426,
    "max_y": 1_978_532.0626899807,
}

BUILDING_PATTERN = re.compile(
    r"(楼|幢|馆|厅|堂|中心|餐厅|食堂|医院|剧场|宿舍|公寓|教学楼|门卫房|牌坊|大楼|阁|亭)$"
)
SPORT_PATTERN = re.compile(r"(田径场|足球场|篮球场|网球场|羽毛球场|匹克球场|游泳馆|操场)$")
BRIDGE_PATTERN = re.compile(r"桥$")
ROAD_PATTERN = re.compile(r"(路|大道|街)$")
LANDSCAPE_PATTERN = re.compile(r"(花苑|果园|苗圃|树林|林|园)$")

KEY_LANDMARKS = {
    "主图书馆（浙江大学校史校情馆）": "main_library",
    "求是大讲堂": "qiushi_auditorium",
    "月牙楼": "crescent_building",
    "图书信息A楼（基础图书馆）": "foundation_library",
    "图书信息C楼": "information_tower",
    "亚运比赛馆": "asia_games_hall",
    "风雨操场": "indoor_stadium",
    "南华园": "nanhuayuan",
}

LANDMARK_LAYOUT = {
    "main_library": {"center": (462, 730), "size": (130, 105)},
    "qiushi_auditorium": {"center": (368, 792), "size": (216, 105)},
    "crescent_building": {"center": (1141, 799), "size": (230, 140)},
    "foundation_library": {"center": (1252, 985), "size": (118, 118)},
    "information_tower": {"center": (1197, 964), "size": (52, 122)},
    "asia_games_hall": {"center": (1452, 845), "size": (158, 112)},
    "indoor_stadium": {"center": (1616, 895), "size": (200, 105)},
    "nanhuayuan": {"center": (664, 1314), "size": (150, 120)},
    "south_gate": {"center": (1133, 1774), "size": (284, 46)},
}

SAFE_WALK_CORRIDORS = (
    (1080, 1680, 1188, 1900),
    (1190, 1030, 1315, 1195),
)

GROUND_COLORS = {
    "grass": ((112, 139, 78), (101, 128, 69), (124, 148, 86)),
    "deep_grass": ((74, 111, 65), (82, 120, 69), (65, 100, 59)),
    "water": ((50, 120, 139), (59, 137, 151), (45, 108, 131)),
    "road": ((72, 78, 77), (81, 86, 84), (63, 70, 70)),
    "paving": ((170, 166, 147), (183, 178, 158), (157, 154, 139)),
    "outside": ((52, 75, 65), (58, 82, 69), (47, 69, 59)),
}


def project_point(x: float, y: float) -> tuple[float, float]:
    left, top, right, bottom = CONTENT_BOUNDS
    nx = (x - OFFICIAL_BOUNDS["min_x"]) / (OFFICIAL_BOUNDS["max_x"] - OFFICIAL_BOUNDS["min_x"])
    ny = (OFFICIAL_BOUNDS["max_y"] - y) / (OFFICIAL_BOUNDS["max_y"] - OFFICIAL_BOUNDS["min_y"])
    return left + nx * (right - left), top + ny * (bottom - top)


def world_point(x: float, y: float) -> tuple[int, int]:
    px, py = project_point(x, y)
    return round(px * PIXEL_SCALE), round(py * PIXEL_SCALE)


def iter_outer_rings(geometry: dict[str, Any]) -> Iterable[list[list[float]]]:
    coordinates = geometry.get("coordinates", [])
    if geometry.get("type") == "Polygon":
        if coordinates:
            yield coordinates[0]
        return
    for polygon in coordinates:
        if polygon:
            yield polygon[0]


def feature_base_polygons(feature: dict[str, Any]) -> list[list[tuple[int, int]]]:
    polygons: list[list[tuple[int, int]]] = []
    for ring in iter_outer_rings(feature["geometry"]):
        polygons.append([(round(project_point(point[0], point[1])[0]), round(project_point(point[0], point[1])[1])) for point in ring])
    return polygons


def classify_reference_pixel(rgb: tuple[int, int, int], x: int, y: int) -> str:
    r, g, b = rgb
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    if b > 92 and g > 88 and b - r > 15 and g - r > 8 and 0.42 <= h <= 0.61:
        return "water"
    if g > 45 and g > r * 1.08 and g >= b * 0.86 and 0.18 <= h <= 0.45:
        return "deep_grass" if v < 0.45 else "grass"
    if s < 0.16 and v < 0.64:
        return "road"
    if s < 0.2 and v >= 0.64:
        return "paving"
    if r > 142 and g > 125 and b < 135:
        return "paving"
    return "deep_grass" if (x + y) % 5 == 0 else "grass"


def textured_color(kind: str, x: int, y: int) -> tuple[int, int, int]:
    palette = GROUND_COLORS[kind]
    index = (x * 17 + y * 31 + (x // 7) * 5 + (y // 9) * 3) % len(palette)
    return palette[index]


def retain_large_mask_components(mask: Image.Image, minimum_area: int) -> Image.Image:
    source = mask.load()
    visited = bytearray(mask.width * mask.height)
    retained = Image.new("1", mask.size, 0)
    retained_pixels = retained.load()

    for start_y in range(mask.height):
        for start_x in range(mask.width):
            start_index = start_y * mask.width + start_x
            if visited[start_index] or not source[start_x, start_y]:
                continue
            stack = [start_index]
            visited[start_index] = 1
            component: list[int] = []
            while stack:
                index = stack.pop()
                component.append(index)
                x = index % mask.width
                y = index // mask.width
                for next_x, next_y in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                    if not (0 <= next_x < mask.width and 0 <= next_y < mask.height):
                        continue
                    next_index = next_y * mask.width + next_x
                    if visited[next_index] or not source[next_x, next_y]:
                        continue
                    visited[next_index] = 1
                    stack.append(next_index)
            if len(component) >= minimum_area:
                for index in component:
                    retained_pixels[index % mask.width, index // mask.width] = 1
    return retained


def build_ground_plate(reference: Image.Image) -> tuple[Image.Image, Image.Image, Image.Image]:
    canvas = Image.new("RGB", (BASE_WIDTH, BASE_HEIGHT), GROUND_COLORS["outside"][0])
    water_mask = Image.new("1", (BASE_WIDTH, BASE_HEIGHT), 0)
    road_mask = Image.new("1", (BASE_WIDTH, BASE_HEIGHT), 0)
    left, top, right, bottom = CONTENT_BOUNDS
    sampled = reference.convert("RGB").resize((right - left, bottom - top), Image.Resampling.LANCZOS)
    sampled = sampled.filter(ImageFilter.MedianFilter(5))
    pixels = canvas.load()
    water_pixels = water_mask.load()
    road_pixels = road_mask.load()
    source_pixels = sampled.load()

    for y in range(BASE_HEIGHT):
        for x in range(BASE_WIDTH):
            if not (left <= x < right and top <= y < bottom):
                pixels[x, y] = textured_color("outside", x, y)
                continue
            kind = classify_reference_pixel(source_pixels[x - left, y - top], x, y)
            pixels[x, y] = textured_color(kind, x, y)
            if kind == "water":
                water_pixels[x, y] = 1
            elif kind == "road":
                road_pixels[x, y] = 1

    filtered_water = retain_large_mask_components(water_mask, minimum_area=700)
    filtered_pixels = filtered_water.load()
    for y in range(top, bottom):
        for x in range(left, right):
            if water_pixels[x, y] and not filtered_pixels[x, y]:
                pixels[x, y] = textured_color("grass", x, y)

    return canvas, filtered_water, road_mask


def draw_water_features(canvas: Image.Image, water_mask: Image.Image, features: list[dict[str, Any]]) -> None:
    draw = ImageDraw.Draw(canvas)
    mask_draw = ImageDraw.Draw(water_mask)
    for feature in features:
        name = str(feature["properties"].get("name") or "")
        if name != "启真湖":
            continue
        for polygon in feature_base_polygons(feature):
            draw.polygon(polygon, fill=GROUND_COLORS["water"][1], outline=(31, 82, 105))
            mask_draw.polygon(polygon, fill=1)
            for offset in (4, 8):
                shifted = [(x, y + offset) for x, y in polygon]
                draw.line(shifted, fill=(78, 154, 158), width=1, joint="curve")


def clear_safe_walk_corridors(water_mask: Image.Image) -> None:
    draw = ImageDraw.Draw(water_mask)
    for left, top, right, bottom in SAFE_WALK_CORRIDORS:
        draw.rectangle(
            (left // PIXEL_SCALE, top // PIXEL_SCALE, right // PIXEL_SCALE, bottom // PIXEL_SCALE),
            fill=0,
        )


def draw_sports_surfaces(canvas: Image.Image, features: list[dict[str, Any]]) -> None:
    draw = ImageDraw.Draw(canvas)
    for feature in features:
        name = str(feature["properties"].get("name") or "")
        if not SPORT_PATTERN.search(name):
            continue
        for polygon in feature_base_polygons(feature):
            draw.polygon(polygon, fill=(87, 128, 77), outline=(41, 72, 57))
            bounds = polygon_bounds(polygon)
            if "田径场" in name:
                inset = 2
                draw.ellipse((bounds[0], bounds[1], bounds[2], bounds[3]), fill=(155, 82, 72), outline=(64, 57, 52), width=1)
                draw.ellipse((bounds[0] + inset, bounds[1] + inset, bounds[2] - inset, bounds[3] - inset), fill=(91, 135, 78), outline=(229, 205, 174), width=1)
                mid_x = (bounds[0] + bounds[2]) // 2
                draw.line((mid_x, bounds[1] + inset, mid_x, bounds[3] - inset), fill=(204, 224, 189), width=1)
            elif "足球场" in name:
                draw.rectangle(bounds, fill=(88, 133, 77), outline=(220, 231, 202), width=1)
            elif any(token in name for token in ("篮球", "网球", "羽毛", "匹克")):
                draw.rectangle(bounds, fill=(126, 77, 68), outline=(218, 207, 179), width=1)


def polygon_bounds(polygon: list[tuple[int, int]]) -> tuple[int, int, int, int]:
    xs = [point[0] for point in polygon]
    ys = [point[1] for point in polygon]
    return min(xs), min(ys), max(xs), max(ys)


def is_building(feature: dict[str, Any]) -> bool:
    props = feature["properties"]
    name = str(props.get("name") or "")
    if name in KEY_LANDMARKS:
        return False
    if SPORT_PATTERN.search(name) or BRIDGE_PATTERN.search(name) or name == "启真湖":
        return False
    area = float(props.get("build_area") or 0)
    floors = int(props.get("build_floor") or 0)
    return area > 0 or floors > 0 or bool(BUILDING_PATTERN.search(name))


def building_palette(name: str, center_x: float, center_y: float) -> tuple[tuple[int, int, int], ...]:
    if any(token in name for token in ("图书馆", "信息", "中心", "实验")):
        return (47, 75, 78), (202, 194, 168), (127, 168, 161), (31, 48, 49)
    if any(token in name for token in ("幢", "公寓", "宿舍")):
        return (121, 79, 63), (204, 180, 146), (89, 126, 124), (66, 49, 43)
    if any(token in name for token in ("堂", "阁", "亭", "剧场")):
        return (55, 58, 54), (167, 91, 62), (200, 187, 157), (37, 39, 37)
    if center_x > BASE_WIDTH * 0.55:
        return (113, 77, 65), (209, 191, 158), (78, 126, 132), (57, 49, 44)
    return (83, 82, 75), (201, 196, 174), (80, 125, 128), (48, 49, 47)


def draw_generic_buildings(canvas: Image.Image, features: list[dict[str, Any]]) -> list[dict[str, int]]:
    draw = ImageDraw.Draw(canvas)
    collisions: list[dict[str, int]] = []
    for feature in features:
        if not is_building(feature):
            continue
        props = feature["properties"]
        name = str(props.get("name") or "")
        for polygon in feature_base_polygons(feature):
            if len(polygon) < 3:
                continue
            bounds = polygon_bounds(polygon)
            if bounds[2] - bounds[0] < 2 or bounds[3] - bounds[1] < 2:
                continue
            center_x = (bounds[0] + bounds[2]) / 2
            center_y = (bounds[1] + bounds[3]) / 2
            roof, trim, glass, outline = building_palette(name, center_x, center_y)
            shadow = [(x + 2, y + 2) for x, y in polygon]
            draw.polygon(shadow, fill=(29, 43, 38))
            draw.polygon(polygon, fill=roof, outline=outline)
            draw.line(polygon + [polygon[0]], fill=trim, width=1, joint="curve")
            if bounds[2] - bounds[0] >= 8 and bounds[3] - bounds[1] >= 6:
                roof_mid_y = (bounds[1] + bounds[3]) // 2
                draw.line((bounds[0] + 2, roof_mid_y, bounds[2] - 2, roof_mid_y), fill=outline, width=1)
                for roof_x in range(bounds[0] + 3, bounds[2] - 2, 6):
                    draw.rectangle((roof_x, roof_mid_y - 1, roof_x + 1, roof_mid_y), fill=glass)
            collisions.append(world_rect_from_base_bounds(bounds, inset=1))
    return collisions


def world_rect_from_base_bounds(bounds: tuple[int, int, int, int], inset: int = 0) -> dict[str, int]:
    left, top, right, bottom = bounds
    left += inset
    top += inset
    right -= inset
    bottom -= inset
    return {
        "x": round(((left + right) / 2) * PIXEL_SCALE),
        "y": round(((top + bottom) / 2) * PIXEL_SCALE),
        "width": max(8, round((right - left) * PIXEL_SCALE)),
        "height": max(8, round((bottom - top) * PIXEL_SCALE)),
    }


def base_landmark_box(landmark_id: str) -> tuple[int, int, int, int]:
    layout = LANDMARK_LAYOUT[landmark_id]
    center_x, center_y = layout["center"]
    width, height = layout["size"]
    return (
        round((center_x - width / 2) / PIXEL_SCALE),
        round((center_y - height / 2) / PIXEL_SCALE),
        round((center_x + width / 2) / PIXEL_SCALE),
        round((center_y + height / 2) / PIXEL_SCALE),
    )


def draw_pixel_building(draw: ImageDraw.ImageDraw, bounds: tuple[int, int, int, int], roof: tuple[int, int, int], wall: tuple[int, int, int], glass: tuple[int, int, int]) -> None:
    left, top, right, bottom = bounds
    draw.rectangle((left + 2, top + 2, right + 2, bottom + 2), fill=(30, 44, 39))
    draw.rectangle(bounds, fill=roof, outline=(43, 43, 40))
    draw.rectangle((left + 2, top + 2, right - 2, bottom - 2), outline=wall, width=1)
    roof_mid_y = (top + bottom) // 2
    draw.line((left + 3, roof_mid_y, right - 3, roof_mid_y), fill=glass, width=1)


def draw_landmarks(canvas: Image.Image) -> list[dict[str, int]]:
    draw = ImageDraw.Draw(canvas)
    collisions: list[dict[str, int]] = []

    main = base_landmark_box("main_library")
    draw_pixel_building(draw, main, (57, 61, 58), (181, 102, 67), (77, 132, 136))
    courtyard_width = max(5, (main[2] - main[0]) // 5)
    draw.rectangle((main[0] + 7, main[1] + 7, main[0] + 7 + courtyard_width, main[3] - 7), fill=(91, 121, 76), outline=(31, 43, 37))
    draw.rectangle((main[2] - 7 - courtyard_width, main[1] + 7, main[2] - 7, main[3] - 7), fill=(91, 121, 76), outline=(31, 43, 37))
    draw.rectangle((main[0] + 3, main[1] + 3, main[2] - 3, main[1] + 6), fill=(78, 126, 132), outline=(38, 61, 64))
    collisions.append(world_rect_from_base_bounds(main, 2))

    auditorium = base_landmark_box("qiushi_auditorium")
    draw_pixel_building(draw, auditorium, (51, 54, 52), (174, 91, 58), (72, 116, 119))
    draw.polygon(
        [(auditorium[0] + 3, auditorium[1] + 5), ((auditorium[0] + auditorium[2]) // 2, auditorium[1] + 1), (auditorium[2] - 3, auditorium[1] + 5), ((auditorium[0] + auditorium[2]) // 2, auditorium[3] - 3)],
        fill=(65, 68, 64),
        outline=(27, 30, 29),
    )
    collisions.append(world_rect_from_base_bounds(auditorium, 2))

    crescent = base_landmark_box("crescent_building")
    arc_width = max(8, (crescent[3] - crescent[1]) // 5)
    draw.arc(crescent, 190, 350, fill=(43, 54, 53), width=arc_width + 4)
    draw.arc((crescent[0] + 2, crescent[1] + 2, crescent[2] - 2, crescent[3] - 2), 190, 350, fill=(205, 204, 188), width=arc_width)
    draw.arc((crescent[0] + 5, crescent[1] + 5, crescent[2] - 5, crescent[3] - 5), 190, 350, fill=(104, 150, 148), width=2)
    end_y = crescent[3] - arc_width // 2
    tower_radius = max(5, arc_width // 2 + 2)
    draw.ellipse((crescent[0] - tower_radius, end_y - tower_radius, crescent[0] + tower_radius, end_y + tower_radius), fill=(188, 190, 179), outline=(55, 67, 65), width=2)
    draw.ellipse((crescent[2] - tower_radius, end_y - tower_radius, crescent[2] + tower_radius, end_y + tower_radius), fill=(188, 190, 179), outline=(55, 67, 65), width=2)
    collisions.append(world_rect_from_base_bounds(crescent, 4))

    foundation = base_landmark_box("foundation_library")
    mid_x = foundation[0] + (foundation[2] - foundation[0]) // 3
    draw.ellipse((foundation[0], foundation[1], mid_x + 11, foundation[1] + 26), fill=(190, 187, 166), outline=(46, 56, 55), width=2)
    draw.ellipse((foundation[0] + 6, foundation[1] + 5, mid_x + 5, foundation[1] + 21), fill=(42, 79, 84), outline=(29, 47, 49))
    draw.rectangle((mid_x, foundation[1] + 10, foundation[2], foundation[1] + 24), fill=(201, 184, 154), outline=(50, 52, 48))
    draw.rectangle((mid_x + 12, foundation[1] + 24, foundation[2], foundation[3]), fill=(202, 185, 155), outline=(50, 52, 48))
    draw.rectangle((mid_x + 8, foundation[1] + 15, foundation[2] - 7, foundation[3] - 5), fill=(68, 120, 125), outline=(42, 69, 71))
    collisions.append(world_rect_from_base_bounds(foundation, 3))

    tower = base_landmark_box("information_tower")
    draw_pixel_building(draw, tower, (53, 82, 84), (181, 169, 145), (56, 108, 116))
    draw.rectangle((tower[0] + 4, tower[1] + 3, tower[2] - 4, tower[3] - 3), fill=(56, 108, 116), outline=(28, 52, 55))
    for y in range(tower[1] + 6, tower[3] - 3, 6):
        draw.line((tower[0] + 5, y, tower[2] - 5, y), fill=(110, 158, 158), width=1)
    collisions.append(world_rect_from_base_bounds(tower, 2))

    hall = base_landmark_box("asia_games_hall")
    draw.ellipse(hall, fill=(213, 211, 198), outline=(64, 73, 72), width=2)
    draw.ellipse((hall[0] + 5, hall[1] + 7, hall[2] - 5, hall[3] - 4), fill=(183, 190, 180), outline=(79, 110, 111))
    draw.line((hall[0] + 8, (hall[1] + hall[3]) // 2, hall[2] - 8, (hall[1] + hall[3]) // 2 - 4), fill=(113, 128, 127), width=2)
    collisions.append(world_rect_from_base_bounds(hall, 4))

    indoor = base_landmark_box("indoor_stadium")
    draw.rounded_rectangle(indoor, radius=8, fill=(190, 202, 196), outline=(58, 76, 76), width=2)
    draw.arc((indoor[0] + 5, indoor[1] + 5, indoor[2] - 5, indoor[3] - 5), 180, 360, fill=(100, 151, 154), width=2)
    collisions.append(world_rect_from_base_bounds(indoor, 3))

    garden = base_landmark_box("nanhuayuan")
    draw.ellipse(garden, fill=(77, 116, 67), outline=(216, 203, 161), width=2)
    pavilion = ((garden[0] + garden[2]) // 2 - 7, (garden[1] + garden[3]) // 2 - 5, (garden[0] + garden[2]) // 2 + 7, (garden[1] + garden[3]) // 2 + 7)
    draw.rectangle(pavilion, fill=(48, 55, 50), outline=(35, 39, 37))
    draw.line((pavilion[0], pavilion[1], pavilion[2], pavilion[3]), fill=(156, 81, 57), width=1)
    draw.line((pavilion[2], pavilion[1], pavilion[0], pavilion[3]), fill=(156, 81, 57), width=1)

    gate = base_landmark_box("south_gate")
    draw.rectangle((gate[0], gate[1] + 2, gate[2], gate[3] - 2), fill=(205, 199, 177), outline=(55, 57, 54))
    arch_width = max(3, (gate[2] - gate[0] - 10) // 9)
    for index in range(9):
        left = gate[0] + 5 + index * arch_width
        draw.rectangle((left, gate[1] + 5, left + arch_width - 2, gate[3] - 5), fill=(48, 95, 105), outline=(51, 57, 55))
    draw.rectangle((gate[0] - 2, gate[1], gate[2] + 2, gate[1] + 4), fill=(221, 215, 194), outline=(55, 57, 54))
    gate_center = (gate[0] + gate[2]) // 2
    collisions.extend([
        world_rect_from_base_bounds((gate[0], gate[1], gate_center - 12, gate[3]), 1),
        world_rect_from_base_bounds((gate_center + 12, gate[1], gate[2], gate[3]), 1),
    ])
    eagle_x = gate[2] + 10
    draw.polygon([(eagle_x, gate[1] + 6), (eagle_x - 5, gate[1] + 1), (eagle_x - 2, gate[1] + 8), (eagle_x - 6, gate[1] + 12), (eagle_x, gate[1] + 10), (eagle_x + 6, gate[1] + 12), (eagle_x + 2, gate[1] + 8), (eagle_x + 5, gate[1] + 1)], fill=(70, 138, 130), outline=(36, 70, 68))

    return collisions


def draw_bridges(canvas: Image.Image, water_mask: Image.Image, features: list[dict[str, Any]]) -> list[dict[str, Any]]:
    draw = ImageDraw.Draw(canvas)
    water_draw = ImageDraw.Draw(water_mask)
    bridges: list[dict[str, Any]] = []
    for feature in features:
        name = str(feature["properties"].get("name") or "")
        if not BRIDGE_PATTERN.search(name):
            continue
        for polygon in feature_base_polygons(feature):
            bounds = polygon_bounds(polygon)
            expanded = (bounds[0] - 2, bounds[1] - 2, bounds[2] + 2, bounds[3] + 2)
            water_draw.rectangle(expanded, fill=0)
            draw.rectangle(expanded, fill=(185, 183, 169), outline=(65, 69, 66))
            if expanded[2] - expanded[0] >= expanded[3] - expanded[1]:
                for x in range(expanded[0] + 2, expanded[2], 4):
                    draw.line((x, expanded[1] + 1, x, expanded[3] - 1), fill=(137, 139, 133), width=1)
            else:
                for y in range(expanded[1] + 2, expanded[3], 4):
                    draw.line((expanded[0] + 1, y, expanded[2] - 1, y), fill=(137, 139, 133), width=1)
            bridges.append({"id": name, "bounds": world_rect_from_base_bounds(expanded)})
    return bridges


def draw_tree(draw: ImageDraw.ImageDraw, x: int, y: int, variant: int) -> None:
    colors = [
        ((38, 72, 48), (63, 111, 59), (96, 143, 72)),
        ((40, 70, 51), (66, 105, 67), (119, 143, 76)),
        ((45, 76, 49), (74, 122, 61), (129, 157, 73)),
    ][variant % 3]
    draw.ellipse((x - 5, y - 4, x + 6, y + 7), fill=(31, 54, 42))
    draw.ellipse((x - 5, y - 6, x + 3, y + 3), fill=colors[0], outline=(32, 58, 42))
    draw.ellipse((x - 1, y - 4, x + 6, y + 4), fill=colors[1])
    draw.rectangle((x - 1, y - 4, x + 1, y - 2), fill=colors[2])


def draw_vegetation(canvas: Image.Image, water_mask: Image.Image, road_mask: Image.Image, building_features: list[dict[str, Any]]) -> None:
    occupied = Image.new("1", (BASE_WIDTH, BASE_HEIGHT), 0)
    occupied.paste(water_mask)
    occupied_pixels = occupied.load()
    road_pixels = road_mask.load()
    occupied_draw = ImageDraw.Draw(occupied)
    for feature in building_features:
        for polygon in feature_base_polygons(feature):
            occupied_draw.polygon(polygon, fill=1)
    for layout in LANDMARK_LAYOUT.values():
        center_x, center_y = layout["center"]
        width, height = layout["size"]
        occupied_draw.rectangle(
            (
                round((center_x - width / 2) / PIXEL_SCALE) - 2,
                round((center_y - height / 2) / PIXEL_SCALE) - 2,
                round((center_x + width / 2) / PIXEL_SCALE) + 2,
                round((center_y + height / 2) / PIXEL_SCALE) + 2,
            ),
            fill=1,
        )

    draw = ImageDraw.Draw(canvas)
    rng = random.Random(755)
    left, top, right, bottom = CONTENT_BOUNDS
    placed: list[tuple[int, int]] = []
    attempts = 0
    while len(placed) < 1150 and attempts < 24000:
        attempts += 1
        x = rng.randrange(left + 3, right - 3)
        y = rng.randrange(top + 8, bottom - 3)
        if occupied_pixels[x, y] or road_pixels[x, y]:
            continue
        if any((x - px) ** 2 + (y - py) ** 2 < 30 for px, py in placed[-90:]):
            continue
        placed.append((x, y))
        draw_tree(draw, x, y, rng.randrange(3))


def water_collision_runs(water_mask: Image.Image) -> list[dict[str, int]]:
    cell = 8
    runs: list[dict[str, int]] = []
    pixels = water_mask.load()
    for top in range(0, BASE_HEIGHT, cell):
        start: int | None = None
        for left in range(0, BASE_WIDTH + cell, cell):
            blocked = False
            if left < BASE_WIDTH:
                samples = 0
                water = 0
                for y in range(top, min(top + cell, BASE_HEIGHT), 2):
                    for x in range(left, min(left + cell, BASE_WIDTH), 2):
                        samples += 1
                        water += int(bool(pixels[x, y]))
                blocked = samples > 0 and water / samples >= 0.45
            if blocked and start is None:
                start = left
            if not blocked and start is not None:
                width = left - start
                runs.append({
                    "x": (start + width / 2) * PIXEL_SCALE,
                    "y": (top + cell / 2) * PIXEL_SCALE,
                    "width": width * PIXEL_SCALE,
                    "height": cell * PIXEL_SCALE,
                })
                start = None
    return [{key: round(value) for key, value in run.items()} for run in runs]


def main() -> None:
    if not SOURCE_MAP.exists() or not SOURCE_FEATURES.exists():
        raise SystemExit("Official Zijingang source references are missing")

    reference = Image.open(SOURCE_MAP)
    source = json.loads(SOURCE_FEATURES.read_text(encoding="utf-8"))
    features = source["features"]
    canvas, water_mask, road_mask = build_ground_plate(reference)
    draw_water_features(canvas, water_mask, features)
    clear_safe_walk_corridors(water_mask)
    draw_sports_surfaces(canvas, features)
    building_features = [feature for feature in features if is_building(feature)]
    draw_vegetation(canvas, water_mask, road_mask, building_features)
    building_collisions = draw_generic_buildings(canvas, features)
    landmark_collisions = draw_landmarks(canvas)
    bridges = draw_bridges(canvas, water_mask, features)

    output = canvas.resize((WORLD_WIDTH, WORLD_HEIGHT), Image.Resampling.NEAREST)
    OUTPUT_PLATE.parent.mkdir(parents=True, exist_ok=True)
    output.save(OUTPUT_PLATE, optimize=True)

    runtime = {
        "source": {
            "map": "https://map.zju.edu.cn/mobile/index.html",
            "officialFeatureCount": len(features),
            "worldScale": "official normalized coordinates with authored landmark exaggeration",
        },
        "world": {"width": WORLD_WIDTH, "height": WORLD_HEIGHT},
        "spawn": {"x": 1133, "y": 1840},
        "libraryGate": {"x": 1252, "y": 1128, "radius": 96},
        "collisions": {
            "buildings": building_collisions + landmark_collisions,
            "water": water_collision_runs(water_mask),
        },
        "bridges": bridges,
        "landmarks": [
            {"id": landmark_id, "x": layout["center"][0], "y": layout["center"][1]}
            for landmark_id, layout in LANDMARK_LAYOUT.items()
        ],
    }
    OUTPUT_RUNTIME.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_RUNTIME.write_text(json.dumps(runtime, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"generated {OUTPUT_PLATE.relative_to(ROOT)} ({WORLD_WIDTH}x{WORLD_HEIGHT})")
    print(f"generated {OUTPUT_RUNTIME.relative_to(ROOT)} ({len(building_collisions) + len(landmark_collisions)} building collisions, {len(runtime['collisions']['water'])} water runs)")


if __name__ == "__main__":
    main()
