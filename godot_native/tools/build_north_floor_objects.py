"""Register source-pixel cutouts; never infer collision from generated art.

Rectangles describe visual ownership only. Later rows own overlaps. The native
adapter subtracts those overlaps, retaining one copy of every original pixel.
"""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
floors = {key: [] for key in ('A1', 'A2', 'A3')}


def add(floor, name, bounds, kind='prop', baseline=None):
    x, y, w, h = bounds
    assert 0 <= x < x+w <= 1672 and 0 <= y < y+h <= 941, name
    floors[floor].append(dict(id=f'{floor.lower()}_{name}', rect=bounds,
                              kind=kind, baselineY=y+h if baseline is None else baseline,
                              pixelPriority=len(floors[floor]), movable=False,
                              depthPolicy='original_source_occlusion'))


for f in floors:
    for name, box in [('north_coping', [0, 0, 1672, 24]),
                      ('west_exterior', [0, 24, 50, 917]),
                      ('east_exterior', [1628, 24, 44, 917]),
                      ('south_windows', [50, 840, 1578, 101]),
                      ('north_hall_wall', [508, 24, 646, 122] if f == 'A3' else [50, 24, 1578, 122])]:
        add(f, name, box, 'wall')
    # The stair and each elevator door/call plate retain their measured source
    # locations. Their controller-owned transport remains in the existing host.
    if f == 'A1':
        lift, stairs = [724, 44, 99, 111], [925, 111, 125, 119]
    elif f == 'A2':
        lift, stairs = [741, 42, 99, 112], [921, 16, 129, 172]
    else:
        lift, stairs = [739, 43, 98, 103], [892, 43, 130, 180]
    add(f, 'elevator_door', lift, 'wall')
    add(f, 'stair_flight', stairs, 'wall')

# A1: the 53 generated table/chair/classroom objects stay in their dedicated
# family. This registry covers the rest of the floor, without a second owner.
for name, box in [
    ('bakery_west_wall', [43, 145, 36, 655]),
    ('bakery_east_wall', [494, 145, 38, 655]),
    ('bakery_south_wall', [50, 783, 484, 57]),
    ('class104_west_wall', [1177, 134, 49, 339]),
    ('class104_north_wall', [1226, 134, 382, 114]),
    ('classrooms_east_wall', [1608, 134, 20, 666]),
    ('class105_west_wall', [1185, 473, 41, 326]),
    ('class105_south_wall', [1226, 795, 382, 45]),
    ('entrance_west_jamb', [642, 733, 39, 156]),
    ('entrance_east_jamb', [977, 733, 46, 156]),
]: add('A1', name, box, 'wall')
for i, (x, y, w, h) in enumerate([
    (108, 171, 77, 90), (201, 171, 72, 90), (300, 171, 130, 90),
    (83, 298, 394, 84), (79, 297, 66, 93),
    (626, 239, 138, 268), (914, 240, 122, 273),
    (752, 571, 189, 112), (595, 797, 59, 91), (1023, 797, 72, 91),
]): add('A1', f'fixture_{i+1:02}', [x, y, w, h])
for row, y in enumerate([428, 556]):
    for col, x in enumerate([122, 236, 348]):
        add('A1', f'cafe_table_{row}_{col}', [x, y, 87, 100])
for i, x in enumerate([99, 177, 259, 338, 421, 501, 589, 1161, 1241, 1321, 1403, 1484, 1564]):
    add('A1', f'north_portrait_{i+1:02}', [x, 61, 45, 60], 'mounted')
for name, box in [('class104_blackboard', [1328, 166, 158, 60]),
                  ('class104_notice', [1240, 184, 47, 26]),
                  ('class104_lectern', [1381, 226, 55, 54]),
                  ('class104_bookcase', [1533, 186, 45, 77]),
                  ('class104_plant', [1578, 220, 29, 57])]:
    add('A1', name, box, 'mounted' if 'blackboard' in name or 'notice' in name else 'prop')

# A2: workshop, lecture hall, computer room, lounge and the 204 architecture.
# The 204 movable furniture/residuals already have their own original runtime.
for name, box in [
    ('workshop_west', [44, 42, 23, 326]), ('workshop_east', [519, 42, 26, 326]),
    ('workshop_south_left', [44, 344, 225, 32]), ('workshop_south_right', [389, 344, 156, 32]),
    ('room202_west', [1158, 42, 18, 327]), ('room202_east', [1598, 42, 30, 327]),
    ('room202_south_left', [1160, 340, 139, 35]), ('room202_south_right', [1408, 340, 220, 35]),
    ('room204_north_left', [44, 505, 223, 29]), ('room204_north_right', [388, 505, 157, 29]),
    ('room204_west', [44, 534, 30, 306]), ('room204_east', [518, 534, 27, 306]),
    ('room205_north_left', [1157, 503, 134, 28]), ('room205_north_right', [1418, 503, 210, 28]),
    ('room205_west', [1157, 531, 22, 309]), ('room205_east', [1614, 531, 14, 309]),
]: add('A2', name, box, 'wall')
for name, box in [
    ('workbench', [180, 177, 254, 91]), ('tool_wall', [181, 55, 228, 84]),
    ('workshop_locker', [451, 63, 70, 94]), ('workshop_left_unit', [54, 66, 127, 98]),
    ('workshop_south_bench', [112, 310, 148, 38]), ('workshop_right_bench', [444, 310, 77, 38]),
    ('workshop_side_cabinet', [49, 186, 44, 115]), ('workshop_right_terminal', [488, 201, 34, 79]),
    ('west_planter', [635, 246, 112, 219]), ('east_planter', [921, 246, 112, 219]),
    ('hall_bookcase', [661, 549, 354, 60]), ('hall_left_flower', [632, 549, 34, 72]),
    ('hall_right_flower', [1017, 549, 34, 72]),
    ('lounge_left_sofa', [652, 666, 151, 133]), ('lounge_right_sofa', [886, 666, 151, 133]),
    ('lounge_left_plant', [620, 679, 36, 120]), ('lounge_right_plant', [1038, 679, 36, 120]),
    ('lecture_lectern', [1316, 141, 59, 51]), ('lecture_blackboard', [1211, 63, 347, 63]),
    ('lecture_screen', [1369, 53, 148, 70]), ('lecture_bookcase', [1165, 67, 29, 86]),
    ('lecture_plant', [1575, 91, 39, 67]), ('room204_screen', [245, 526, 108, 45]),
    ('room204_teacher_desk', [184, 563, 38, 36]),
    ('room204_left_shelf', [63, 525, 34, 68]), ('room204_right_shelf', [481, 525, 34, 68]),
]: add('A2', name, box, 'mounted' if 'blackboard' in name or 'screen' in name or 'tool_wall' in name else 'prop')
for row, y in enumerate([220, 266, 312]):
    add('A2', f'lecture_bench_{row}', [1230, y+23, 315, 15])
    for col in range(9):add('A2', f'lecture_seat_{row}_{col}', [1234+34*col, y, 29, 27])
for row, y in enumerate([592, 681, 769]):
    for col, x in enumerate([1224, 1294, 1364, 1434, 1504]):
        add('A2', f'computer_desk_{row}_{col}', [x, y, 66, 42])
        add('A2', f'computer_monitor_{row}_{col}', [x+16, y-14, 31, 27])
        add('A2', f'computer_chair_{row}_{col}', [x+23, y+39, 28, 31])

# A3: room301's existing 33-node exhibit remains the only owner of that room.
# Honor portraits and their biographies remain in the original phase host.
for name, box in [
    ('media_north_left', [44, 472, 193, 30]), ('media_north_right', [335, 472, 192, 30]),
    ('media_west', [44, 502, 15, 338]), ('media_east', [498, 502, 29, 338]),
    ('honor_north_left', [604, 550, 108, 25]), ('honor_north_right', [961, 550, 106, 25]),
    ('honor_west', [604, 575, 23, 241]), ('honor_east', [1062, 575, 15, 241]),
    ('honor_south', [619, 804, 451, 36]),
    ('report_north', [1157, 42, 471, 16]), ('report_west', [1154, 58, 20, 332]),
    ('report_east', [1616, 58, 12, 332]), ('report_south_left', [1160, 372, 179, 28]),
    ('report_south_right', [1432, 372, 196, 28]),
    ('class303_north_left', [1159, 473, 159, 29]), ('class303_north_right', [1473, 473, 155, 29]),
    ('class303_west', [1156, 502, 18, 338]), ('class303_east', [1616, 502, 12, 338]),
]: add('A3', name, box, 'wall')
for name, box in [
    ('west_planter', [624, 243, 81, 225]), ('east_planter', [899, 246, 79, 222]),
    ('report_stage', [1259, 147, 316, 57]), ('report_lectern', [1365, 141, 33, 42]),
    ('report_screen', [1286, 58, 195, 73]), ('report_left_plant', [1178, 96, 53, 82]),
    ('report_right_plant', [1554, 96, 53, 82]), ('report_speaker', [1243, 82, 24, 42]),
    ('honor_left_case', [635, 602, 60, 94]), ('honor_right_case', [976, 602, 47, 88]),
    ('honor_south_left_case', [654, 773, 127, 58]), ('honor_south_center_case', [787, 773, 127, 58]),
    ('honor_south_right_case', [920, 773, 127, 58]),
    ('media_green_screen', [174, 510, 188, 89]), ('media_left_camera', [75, 604, 65, 151]),
    ('media_right_camera', [413, 604, 65, 151]), ('media_left_lamp', [117, 512, 50, 91]),
    ('media_right_lamp', [365, 512, 50, 91]), ('media_control_desk', [142, 747, 234, 77]),
    ('media_right_rack', [440, 533, 44, 215]), ('media_left_rack', [65, 504, 38, 113]),
    ('class303_blackboard', [1284, 512, 214, 42]), ('class303_lectern', [1360, 557, 65, 45]),
    ('class303_left_shelf', [1185, 519, 52, 78]), ('class303_right_shelf', [1553, 519, 52, 78]),
    ('class303_left_plant', [1237, 552, 34, 45]), ('class303_right_plant', [1519, 552, 34, 45]),
]: add('A3', name, box, 'mounted' if 'screen' in name or 'blackboard' in name or 'speaker' in name else 'prop')
for row, y in enumerate([217, 254, 291, 328]):
    for group, xs in enumerate([[1194, 1226, 1258, 1290, 1322], [1416, 1448, 1480, 1512, 1544, 1576]]):
        for col, x in enumerate(xs):add('A3', f'report_seat_{row}_{group}_{col}', [x, y, 30, 34])
for row, y in enumerate([606, 656, 706, 756]):
    for col, x in enumerate([1214, 1274, 1334, 1420, 1480, 1540]):
        add('A3', f'class303_desk_{row}_{col}', [x, y, 39, 28])
        add('A3', f'class303_chair_{row}_{col}', [x+7, y+27, 27, 26])

manifest = dict(schema='north-floor-source-objects-v1', sceneId='duan_yongping_temporal_maze',
                worldSize=[1672, 941], authority='presentation_only; existing source collisions and controller targets',
                source='res://data/source/chapter4-three-floor-maze.layout.json',
                excludedOwners=['A1: generated 53-object classroom family', 'A3: room301 33-object exhibit',
                                'A2: original movable room204 furniture and residuals'], floors=floors)
target = ROOT/'data/native/north-floor-source-objects.json'
target.write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+'\n')
print(json.dumps({f: len(rows) for f, rows in floors.items()}))
