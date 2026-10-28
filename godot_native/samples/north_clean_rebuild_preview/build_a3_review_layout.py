#!/usr/bin/env python3
"""Build a visual-review placement list from the checked-in source bounds.

This never generates a production collision map, saves, or story facts. Source
rectangles are used as placement guides; original bitmap crops are not assets.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SAMPLE = Path(__file__).resolve().parent
source = json.loads((ROOT / "godot_native/data/native/north-floor-source-objects.json").read_text())
exhibit = json.loads((ROOT / "godot_native/data/native/room301-exhibit.json").read_text())
assets = json.loads((SAMPLE / "asset_manifest.json").read_text())["objects"]
result = []
unmapped = []

def add(name, texture, bounds, source_id=None, anchor=(0.5, 1.0)):
    result.append({"id": name, "texture": texture, "bounds": bounds,
                   "sourceId": source_id, "anchor": list(anchor)})

# This transparent inlay is below the honor-room cabinets and trophy cases.
add("honor_floor_trim", "a3_honor_floor_border", [698, 657, 271, 133])

mapping = {
    "a3_west_planter": "a3_hall_planter", "a3_east_planter": "a3_hall_planter",
    "a3_report_stage": "a3_stage_wide", "a3_report_lectern": "a3_report_lectern",
    "a3_report_screen": "a3_projection_screen", "a3_report_speaker": "a3_wall_speaker",
    "a3_report_left_plant": "a3_plant", "a3_report_right_plant": "a3_plant",
    "a3_honor_left_case": "a3_trophy_cabinet", "a3_honor_right_case": "a3_trophy_cabinet",
    "a3_honor_south_left_case": "a3_case_exact", "a3_honor_south_center_case": "a3_case_exact",
    "a3_honor_south_right_case": "a3_case_exact", "a3_media_green_screen": "a3_green_screen",
    "a3_media_left_lamp": "a3_studio_light", "a3_media_right_lamp": "a3_studio_light",
    "a3_media_control_desk": "a3_console_desk_v3",
    "a3_media_left_rack": "a3_empty_rack", "a3_class303_blackboard": "a3_blackboard_wide",
    "a3_class303_lectern": "class_lectern", "a3_class303_left_shelf": "a3_class_shelf",
    "a3_class303_right_shelf": "a3_class_shelf", "a3_class303_left_plant": "a3_plant",
    "a3_class303_right_plant": "a3_plant",
}
for row in source["floors"]["A3"]:
    if row["kind"] == "wall":
        continue
    name = row["id"]
    if name in {"a3_media_left_camera", "a3_media_right_camera", "a3_media_right_rack"}:
        # These source groups contain several physical pieces with different proportions.
        # Place their cameras, cabinets, displays and control units individually below.
        continue
    if name.startswith("a3_report_seat_"):
        texture = "a3_report_seat"
    elif name.startswith("a3_class303_desk_"):
        texture = "a3_class_desk"
    elif name.startswith("a3_class303_chair_"):
        texture = "a3_class_chair"
    else:
        texture = mapping.get(name)
    if texture:
        add(name, texture, row["rect"], name)
    else:
        unmapped.append(name)

# Two cameras are on the left; a third compact camera stands on the right.
add("studio_camera_upper", "media_camera", [67, 617, 68, 74], "a3_media_left_camera")
add("studio_camera_lower", "media_camera", [67, 688, 68, 77], "a3_media_left_camera")
add("studio_camera_right", "a3_studio_right_camera", [431, 710, 53, 67], "a3_media_right_camera")
add("report_right_speaker", "a3_wall_speaker", [1504, 82, 24, 42])

# The original planters each have four separate long bench pieces.
for planter, left_x, right_x in (("west", 621, 690), ("east", 895, 964)):
    for side, x in (("left", left_x), ("right", right_x)):
        for row in range(2):
            add(f"a3_bench_{planter}_{side}_{row}", "hall_bench", [x, 265 + row * 92, 18, 90])

# 301 source objects are managed by a separate adapter in the game.
for row in exhibit["objects"]:
    name = row["id"]
    if name in {"north_wall", "west_wall", "east_wall", "south_wall_left", "south_wall_right", "entrance"}:
        continue
    if name == "archive_case":
        texture = "a3_archive_case"
    elif name.startswith("north_case_") or name.startswith("south_case_"):
        texture = "a3_case_exact"
    elif name.startswith("west_case_"):
        texture = "a3_exhibit_tall_case"
    elif name in {"west_plant", "east_plant"}:
        texture = "a3_plant"
    elif name.startswith("exhibit_document_"):
        texture = "a3_archive_document"
    elif name == "globe":
        texture = "a3_exhibit_globe"
    elif name.startswith("wall_archive_"):
        texture = "a3_exhibit_wide_frame" if name == "wall_archive_03" else "a3_frame"
    else:
        unmapped.append("301:" + name)
        continue
    if name.startswith("wall_archive_") and name != "wall_archive_03":
        x, y, w, h = row["rect"]
        add("301_wall_content_" + name, "a3_archive_document", [x + 5, y + 5, w - 10, h - 10], "301:" + name)
    add("301_" + name, texture, row["rect"], "301:" + name)
    if name.startswith("north_case_") or name.startswith("south_case_"):
        x, y, w, h = row["rect"]
        for part in range(2):
            add(f"301_card_{name}_{part}", "a3_archive_blue_card", [x + 5 + part * (w - 10) / 2, y + 7, (w - 12) / 2, h - 23], "301:" + name)

# Mount pictures on the visible wall face, rather than using a floor foot pivot.
# Derive each picture's interior from the same frame aperture so it cannot slip below it.
add("a3_hall_notice_backboard", "a3_notice_backboard", [590, 76, 97, 49], anchor=(0.5, 0.5))
portraits = [
    ("su_buqing", [748,570,43,53]),
    ("zhu_kezhen", [812,570,43,53]),
    ("lu_yongxiang", [877,570,43,53]),
    ("chen_jiangong", [593,81,28,35]),
    ("tan_jiazhen", [624,81,28,35]),
    ("cheng_kaijia", [655,81,28,35]),
]
for name, frame in portraits:
    sx, sy, sw, sh = assets["a3_frame"]["sourceRect"]
    cx, cy, cw, ch = assets["a3_frame"]["contentRect"]
    x, y, w, h = frame
    scale = min(w / sw, h / sh)
    fx, fy = x + (w - sw * scale) / 2, y + (h - sh * scale) / 2
    image = [fx + (cx - sx) * scale, fy + (cy - sy) * scale, cw * scale, ch * scale]
    add("portrait_" + name, "portrait_" + name, image, "ChapterFourAlumniHonorWall:" + name, (0.5, 0.5))
    add("frame_" + name, "a3_frame", frame, "ChapterFourAlumniHonorWall:" + name, (0.5, 0.5))

for x, y, name in [(696,577,"honor_west"), (955,577,"honor_east"), (1266,510,"class_west"), (1542,510,"class_east")]:
    add("wall_lamp_" + name, "a3_wall_lamp", [x,y,20,28])
for x, name in [(568, "hall_west"), (688, "hall_middle"), (1078, "hall_east")]:
    add("wall_lamp_" + name, "a3_wall_lamp", [x, 70, 20, 28])
for name, x, y in [("exhibit", 260, 375), ("report", 1366, 375),
                   ("studio", 260, 477), ("classroom", 1366, 477)]:
    add("door_threshold_" + name, "a3_entrance_threshold", [x, y, 40, 25])
add("elevator_door", "a3_elevator_door", [758, 57, 59, 78])
for name, bounds in [("honor_west", [635,738,43,58]), ("honor_east", [987,738,43,58]),
                     ("studio_west", [60,782,42,44]), ("studio_east", [449,782,42,44])]:
    add("plant_" + name, "a3_plant", bounds)
for x in (646, 987):
    for y in (621, 647):
        for dx in (0, 22):
            add(f"cabinet_trophy_{x}_{y}_{dx}", "a3_trophy", [x+dx,y,15,19])
for x in (676, 808, 941):
    for dx in (0, 25, 50):
        add(f"case_trophy_{x}_{dx}", "a3_trophy", [x+dx,785,14,19])
# Studio equipment follows the original footprint instead of shrinking a whole column
# into one slender rack. The editing desk, displays, cabinets and controls stay separate.
for index, texture, bounds in [
    (0, "a3_studio_monitor", [176, 733, 48, 32]),
    (1, "a3_studio_monitor_v2", [228, 733, 65, 34]),
    (2, "a3_studio_monitor", [298, 733, 49, 33]),
    (3, "a3_studio_monitor", [346, 746, 27, 25]),
]:
    add(f"studio_monitor_{index}", texture, bounds)
for index, bounds in enumerate(([174, 774, 51, 22], [230, 774, 64, 22], [299, 774, 47, 22])):
    add(f"studio_mixer_{index}", "a3_studio_mixer", bounds)
for index, x in enumerate((192, 307)):
    add(f"studio_chair_{index}", "a3_studio_chair", [x, 796, 32, 30])

add("studio_right_upper_rack", "a3_av_rack_wide", [416, 537, 61, 82], "a3_media_right_rack")
add("studio_right_lower_rack", "a3_av_rack_wide", [421, 619, 59, 91], "a3_media_right_rack")
add("studio_desk_sidecar", "a3_av_rack_wide", [380, 748, 53, 77], "a3_media_control_desk")
add("studio_rack_top_monitor", "a3_studio_monitor_v2", [415, 502, 60, 36], "a3_media_right_rack")
add("studio_rack_vertical_monitor", "a3_studio_vertical_display", [428, 621, 44, 66], "a3_media_right_rack")
add("studio_left_rack_display", "a3_studio_monitor", [68, 508, 31, 24], "a3_media_left_rack")
for index, y in enumerate((539, 564, 589)):
    add(f"studio_left_rack_unit_{index}", "a3_studio_mixer", [68, y, 31, 15], "a3_media_left_rack")
for index, y in enumerate((554, 576, 598)):
    add(f"studio_right_rack_unit_{index}", "a3_studio_mixer", [422, y, 45, 17], "a3_media_right_rack")
add("studio_lower_rack_unit", "a3_studio_mixer", [429, 690, 42, 14], "a3_media_right_rack")
for index, y in enumerate((760, 785, 804)):
    add(f"studio_sidecar_unit_{index}", "a3_studio_mixer", [386, y, 41, 14], "a3_media_control_desk")

out = {"source": "north-floor-source-objects.json + room301-exhibit.json + ChapterFourAlumniHonorWall.ts",
       "worldSize": [1672, 941], "status": "review_only_approximate_visual_placements",
       "unmappedSourceIds": unmapped, "placements": result}
(SAMPLE / "a3_review_layout.json").write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n")
print(f"A3 review: {len(result)} separate instances; unresolved source groups: {unmapped}")

# Keep the inspector's prose a generated copy of the existing authored biographies.
canonical = json.loads((ROOT / "godot_native/data/native/chapter4-native-source.json").read_text())
figure_ids = {name for name, _frame in portraits}
fields = ("id", "name", "years", "role", "biography", "sourceLabel", "sourceUrl")
figures = [{key: row[key] for key in fields} for row in canonical["alumni"] if row["id"] in figure_ids]
assert len(figures) == 6
(SAMPLE / "portrait_interaction_data.json").write_text(json.dumps({
    "source": "godot_native/data/native/chapter4-native-source.json:alumni",
    "scope": "read_only_review_no_story_progress",
    "figures": figures,
}, ensure_ascii=False, indent=2) + "\n")
