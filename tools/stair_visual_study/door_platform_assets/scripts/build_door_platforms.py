"""Source-sized fixed platforms and a genuinely hinged school door.

Asset-only authoring. World metres and original navigation remain untouched.
Run under flock /tmp/755-blender-render.lock, Blender -b -t 1 --python ... --.
"""
import argparse
import hashlib
import json
import math
import pathlib
import random
import shutil
import sys

import bpy
from mathutils import Matrix, Vector

P = argparse.ArgumentParser()
P.add_argument('--output', required=True)
P.add_argument('--render', action='store_true')
P.add_argument('--render-assets', default='all')
P.add_argument('--export-assets', default='all', help='Comma-separated selected exports; default all. Used for bounded door-only fixes.')
P.add_argument('--samples', type=int, default=32)
P.add_argument('--resolution', type=int, default=1024)
A = P.parse_args(sys.argv[sys.argv.index('--') + 1:])
ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = pathlib.Path(A.output).resolve()
OUT.mkdir(parents=True, exist_ok=True)
D = json.loads((ROOT / 'stair_b_snapshot.json').read_text())
sys.path.insert(0, str(ROOT))
from pixel_materials import metric_uv

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
S = bpy.context.scene
S.render.engine = 'CYCLES'
S.cycles.device = 'CPU'
S.cycles.samples = A.samples
S.cycles.max_bounces = 1
S.cycles.use_denoising = False
S.render.threads_mode = 'FIXED'
S.render.threads = 1
S.render.resolution_x = A.resolution
S.render.resolution_y = A.resolution
S.render.resolution_percentage = 100
S.render.image_settings.file_format = 'PNG'
S.render.image_settings.color_mode = 'RGBA'
S.render.film_transparent = True
S.view_settings.view_transform = 'Standard'
S.view_settings.look = 'Medium High Contrast'
S.world.use_nodes = True
S.world.node_tree.nodes['Background'].inputs['Color'].default_value = (.12, .14, .16, 1)
S.world.node_tree.nodes['Background'].inputs['Strength'].default_value = .7


def v(p):
    return Vector((p[0], -p[2], p[1]))


def inv_v(p):
    return [float(p.x), float(p.z), float(-p.y)]


def rgba(h):
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)) + (1,)


def plain(name, h, metal=0, rough=.9):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    linear = tuple(c / 12.92 if c <= .04045 else ((c + .055) / 1.055) ** 2.4 for c in rgba(h)[:3]) + (1,)
    mat.diffuse_color = linear
    node = mat.node_tree.nodes.get('Principled BSDF')
    node.inputs['Base Color'].default_value = linear
    node.inputs['Metallic'].default_value = metal
    node.inputs['Roughness'].default_value = rough
    return mat


def image_mat(name, h, path, rough):
    mat = plain(name, h, rough=rough)
    image = bpy.data.images.load(str(path), check_existing=True)
    image.colorspace_settings.name = 'sRGB'
    image.pack()
    tex = mat.node_tree.nodes.new('ShaderNodeTexImage')
    tex.image = image
    tex.interpolation = 'Closest'
    tex.extension = 'REPEAT'
    mat.node_tree.links.new(tex.outputs['Color'], mat.node_tree.nodes['Principled BSDF'].inputs['Base Color'])
    return mat


# Byte-identical approved terrazzo; no independent palette or density drift.
shutil.copyfile(ROOT / 'sample_asset/terrazzo_pixel_albedo.png', OUT / 'terrazzo_pixel_albedo.png')
stone = image_mat('Campus grey terrazzo', 'b8b7aa', OUT / 'terrazzo_pixel_albedo.png', .92)
iron = plain('Blue grey painted iron', '233a44', .48, .48)
cuff = plain('Iron joint collars', '314b56', .58, .46)
edge = plain('Stone worn edges', 'ccc8b7', rough=.86)
groove = plain('Recessed edge reveals', '637776', rough=.94)
bolt = plain('Recessed steel fixings', '6d7f83', .65, .48)
wood_edge = plain('Worn end grain and door joinery', '604a35', rough=.88)
wood_light = plain('Fine exposed wood edge', '9b7952', rough=.9)
dark = plain('Joinery shadow', '302d28', rough=.95)

# Authored pixel wood grain: 1 metre repeat, no AI photograph or flat billboard.
rng = random.Random(755042)
n = 128
palette = [rgba(c) for c in ['79593d', '725236', '816044', '684b34', '8a6849', '604931']]
columns = [rng.choice([0, 0, 0, 1, 2, 3]) for _ in range(n)]
pixels = []
for y in range(n):
    for x in range(n):
        shade = columns[x]
        if rng.random() < .06:
            shade = rng.choice([0, 1, 2, 4])
        if (x + int(math.sin(y / 21) * 1.5)) % 23 == 0 and y % 29 < 21:
            shade = 5
        pixels.extend(palette[shade])
im = bpy.data.images.new('Authored school wood pixel albedo', width=n, height=n, alpha=True)
im.colorspace_settings.name = 'sRGB'
im.pixels = pixels
im.filepath_raw = str(OUT / 'school_wood_pixel_albedo.png')
im.file_format = 'PNG'
im.save()
im.pack()
wood = image_mat('School oak veneer', '79593d', OUT / 'school_wood_pixel_albedo.png', .88)


def empty(name, parent=None):
    ob = bpy.data.objects.new(name, None)
    S.collection.objects.link(ob)
    ob.parent = parent
    ob['render_only'] = True
    ob['source_owner_id'] = 'level'
    return ob


def setmat(ob, mat):
    ob.data.materials.append(mat)
    metric_uv(ob)
    ob['render_only'] = True
    ob['source_owner_id'] = 'level'
    return ob


def box(name, c, size, mat, parent):
    bpy.ops.mesh.primitive_cube_add(size=1, location=v(c))
    ob = bpy.context.object
    ob.name = name
    ob.dimensions = (size[0], size[2], size[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    ob.parent = parent
    return setmat(ob, mat)


def cylinder(name, a, b, radius, mat, parent, vertices=12):
    a, b = v(a), v(b)
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=(b - a).length, location=(a + b) / 2)
    ob = bpy.context.object
    ob.name = name
    ob.rotation_mode = 'QUATERNION'
    ob.rotation_quaternion = (b - a).to_track_quat('Z', 'Y')
    ob.parent = parent
    return setmat(ob, mat)


def children(root):
    result = [root]
    for child in root.children:
        result.extend(children(child))
    return result


def export(root, filename):
    bpy.ops.object.select_all(action='DESELECT')
    for ob in children(root):
        ob.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(OUT / filename), export_format='GLB', use_selection=True,
                              export_animations=False, export_extras=True)


all_fixed = empty('fixed_platforms')
platforms = [p for p in D['level']['geometry']['platforms'] if p['ownerId'] == 'level' and p['walkable']]
assert [p['id'] for p in platforms] == ['b_platform_start', 'b_platform_lower_base', 'b_platform_landing', 'b_platform_island', 'b_platform_exit']
assets = {}
report = {
    'source_sha256': D['source_sha256'], 'coordinate_map': 'Godot (x,y,z) -> Blender (x,-z,y)',
    'world_metres': True, 'root_transforms': 'identity, source world coordinates retained',
    'navigation_modified': False, 'colliders_generated': False, 'gameplay_open_rule_added': False,
    'platforms': [], 'render_views': {}, 'geometry_checks': 0,
    'rail_ownership': 'fixed rails are independent children of the fixed platform, never a mechanism child',
    'guard_placement': 'short peripheral segments, no rail on lower pivot base or across source navigation endpoints',
}


def guard(parent, label, a, b):
    """Two-ended closed tubular segment; source coordinates and material family."""
    a, b = Vector(a), Vector(b)
    length = (b - a).length
    cylinder(label + '_top', a + Vector((0, .72, 0)), b + Vector((0, .72, 0)), .031, iron, parent)
    cylinder(label + '_low', a + Vector((0, .30, 0)), b + Vector((0, .30, 0)), .018, iron, parent)
    intervals = max(1, math.ceil(length / .8))
    for i in range(intervals + 1):
        foot = a.lerp(b, i / intervals)
        box(label + '_foot_%d' % i, foot + Vector((0, .015, 0)), (.08, .03, .08), cuff, parent)
        cylinder(label + '_post_%d' % i, foot + Vector((0, .03, 0)), foot + Vector((0, .76, 0)), .025, iron, parent)
        cylinder(label + '_cap_%d' % i, foot + Vector((0, .742, 0)), foot + Vector((0, .77, 0)), .028, cuff, parent)
        for j, (sx, sz) in enumerate([(-1, -1), (-1, 1), (1, -1), (1, 1)]):
            q = foot + Vector((sx * .025, .03, sz * .025))
            cylinder(label + '_bolt_%d_%d' % (i, j), q, q + Vector((0, .004, 0)), .006, bolt, parent, 8)


for p in platforms:
    ident = p['id']
    owner = empty(ident + '_fixed', all_fixed)
    body = box(ident, p['center'], p['size'], stone, owner)
    body['role'] = 'unchanged source walking slab'
    assets[ident] = owner
    center = Vector(p['center'])
    size = Vector(p['size'])
    top = center.y + size.y / 2
    # Subtle side edge reveals. Top remains exactly the original source slab.
    trim = empty(ident + '_side_details', owner)
    for sign in [-1, 1]:
        box(ident + '_front_reveal_%d' % sign,
            center + Vector((0, -.085, sign * (size.z / 2 + .001))),
            (size.x - .10, .009, .002), groove, trim)
        box(ident + '_side_reveal_%d' % sign,
            center + Vector((sign * (size.x / 2 + .001), -.085, 0)),
            (.002, .009, size.z - .10), groove, trim)
    rail = empty(ident + '_fixed_rails', owner)
    rail['never_parent_to_mechanism'] = True
    segments = []
    if ident == 'b_platform_start':
        segments = [((-7.10, top, .51), (-7.10, top, 2.69)), ((-7.10, top, .51), (-3.10, top, .51))]
    elif ident == 'b_platform_landing':
        segments = [((.35, top, 3.24), (2.43, top, 3.24)), ((2.43, top, 2.40), (2.43, top, 3.24))]
    elif ident == 'b_platform_island':
        segments = [((3.72, top, 5.48), (3.72, top, 6.65))]
    elif ident == 'b_platform_exit':
        segments = [((3.83, top, 7.74), (3.83, top, 8.42)), ((5.60, top, 7.74), (5.60, top, 8.42))]
    for j, (a, b) in enumerate(segments):
        guard(rail, ident + '_guard_%d' % j, a, b)
    record = {k: p[k] for k in ['id', 'center', 'size', 'ownerId', 'walkable']}
    record.update({'walk_top_y': top, 'file': ident + '.glb', 'node': ident,
                   'fixed_root': owner.name, 'rails_node': rail.name,
                   'rail_segments_godot': segments, 'side_detail_expansion_m': .002})
    report['platforms'].append(record)

# Actual native door dimensions are the production authority, not the older
# build_stair_sample placeholder. The base transform is applied exactly once.
deco = next(d for d in D['level']['geometry']['decorations'] if d['kind'] == 'fire_door')
door = empty('school_door_assembly')
assets['school_door'] = door
door_base = empty('b_deco_fire_door_base', door)
door_base.location = v(deco['position'])
door_base.rotation_euler[2] = deco['rotationY']
frame = empty('b_deco_fire_door_frame_fixed', door_base)
frame['source_decoration_id'] = deco['id']
for sign in [-1, 1]:
    box('Door fixed jamb %d' % sign, (sign * .74, 1.15, 0), (.22, 2.30, .34), iron, frame)
    for y in [.20, 1.15, 2.10]:
        cylinder('Jamb anchor %d %.2f' % (sign, y), (sign * .74, y, -.174), (sign * .74, y, -.179), .014, bolt, frame, 8)
box('Door fixed lintel', (0, 2.3, 0), (1.70, .24, .36), iron, frame)
# Stops stay inside original jamb/header envelopes and never narrow the 1.26 m opening.
for sign in [-1, 1]:
    box('Door jamb fine edge %d' % sign, (sign * .650, 1.11, .172), (.024, 2.22, .004), cuff, frame)
box('Door lintel fine edge', (0, 2.192, .182), (1.24, .018, .004), cuff, frame)

hinge_local = Vector((-.62, 0, -.072))
angle = deco['rotationY']
base = Vector(deco['position'])
hinge_world = base + Vector((hinge_local.x * math.cos(angle) + hinge_local.z * math.sin(angle),
                             hinge_local.y, -hinge_local.x * math.sin(angle) + hinge_local.z * math.cos(angle)))
hinge = empty('b_deco_fire_door_hinge', door_base)
hinge.location = v(hinge_local)
hinge['hinge_axis_godot'] = 'Y'
hinge['source_hinge_godot'] = list(hinge_world)
hinge['open_angle_reference_degrees'] = 65
hinge['role'] = 'presentation-only door leaf motion; no game rule'
leaf = box('b_deco_fire_door_leaf', (.62, 1.03, 0), (1.24, 2.06, .14), wood, hinge)
leaf['role'] = 'unchanged native six-sided door slab, independent of fixed frame'
# Nonoverlapping joinery faces avoid black coplanar seams at stile/cross-rail joins.
for side in [-1, 1]:
    z = side * .075
    for x in [.10, 1.14]:
        box('Leaf stile %s %.2f' % (side, x), (x, 1.03, z), (.12, 2.00, .010), wood_edge, hinge)
    for y in [.10, .75, 1.98]:
        box('Leaf cross rail %s %.2f' % (side, y), (.62, y, z), (.92, .10, .010), wood_edge, hinge)
    for y, h in [(.424, .49), (1.363, 1.09)]:
        for x in [.186, 1.054]:
            box('Fine panel edge %s %.2f %.2f' % (side, y, x), (x, y, side * .074), (.010, h, .006), wood_light, hinge)
        for yy in [y - h / 2, y + h / 2]:
            box('Fine panel rail %s %.3f' % (side, yy), (.62, yy, side * .074), (.858, .010, .006), wood_light, hinge)
    box('Door lower kick plate %s' % side, (.62, .20, side * .088), (.98, .19, .012), cuff, hinge)
    for x in [.18, 1.06]:
        for y in [.145, .255]:
            cylinder('Kick plate fixing', (x, y, side * .095), (x, y, side * .099), .008, bolt, hinge, 8)
    box('Door handle backplate %s' % side, (1.06, .97, side * .092), (.09, .22, .018), bolt, hinge)
    cylinder('Door handle spindle %s' % side, (1.06, 1.01, side * .09), (1.06, 1.01, side * .155), .02, bolt, hinge)
    cylinder('Door handle lever %s' % side, (1.06, 1.01, side * .155), (.89, 1.01, side * .155), .022, bolt, hinge)
    cylinder('Door keyhole %s' % side, (1.06, .914, side * .102), (1.06, .914, side * .105), .012, dark, hinge)
    for y in [.888, 1.055]:
        cylinder('Handle screw', (1.06, y, side * .102), (1.06, y, side * .106), .006, iron, hinge, 8)

for j, y in enumerate([.33, 1.03, 1.73]):
    # Solid straps and bent returns meet the real Y-axis knuckles; no floating plates.
    box('Hinge door strap %d' % j, (.052, y, -.074), (.10, .12, .010), bolt, hinge)
    box('Hinge door bent return %d' % j, (.008, y, -.072), (.016, .12, .010), bolt, hinge)
    box('Hinge fixed strap %d' % j, (-.690, y, -.182), (.10, .12, .014), bolt, frame)
    box('Hinge fixed return %d' % j, (-.644, y, -.126), (.030, .12, .130), bolt, frame)
    cylinder('Hinge fixed barrel %d' % j, (-.62, y - .061, -.072), (-.62, y - .005, -.072), .009, bolt, frame)
    cylinder('Hinge moving barrel %d' % j, (0, y + .005, 0), (0, y + .061, 0), .009, bolt, hinge)
    cylinder('Hinge fixed pin %d' % j, (-.62, y - .068, -.072), (-.62, y + .068, -.072), .006, iron, frame)

# Preserve the exact source closed pose while moving only the mechanical axis.
# Knuckles stay centred on the new hinge axis; all other moving parts compensate.
for child in hinge.children:
    if not child.name.startswith('Hinge moving barrel'):
        child.location += v((0, 0, .072))

bpy.context.view_layer.update()
report['door'] = {
    'file': 'school_door.glb', 'assembly_node': door.name, 'base_node': door_base.name, 'frame_node': frame.name,
    'hinge_node': hinge.name, 'leaf_node': leaf.name,
    'source_base_godot': deco['position'], 'source_rotation_y': deco['rotationY'],
    'hinge_local_godot': list(hinge_local), 'hinge_world_godot': list(hinge_world),
    'hinge_axis_godot': [0, 1, 0], 'clear_opening_width_m': 1.26,
    'clear_opening_height_m': 2.18, 'leaf_size_m': [1.24, 2.06, .14],
    'leaf_closed_center_godot': inv_v(leaf.matrix_world.translation),
    'frame_remains_fixed': True, 'handles_both_faces': True,
    'dimension_authority': 'native chapter4_stairs.gd _decoration fire_door; older study placeholder superseded',
    'jamb_centres_local_x': [-.74, .74], 'jamb_size_m': [.22, 2.3, .34], 'lintel_size_m': [1.7, .24, .36],
    'closed_body_edge_incidence': 2, 'native_closed_y_rotation': 0,
    'open_pose': 'hinge.rotation.y = desired_angle in [0, PI/2]; never rotate the assembly/base/frame',
    'hinge_clearance_revision': 2, 'source_closed_leaf_pose_preserved': True,
}

# Structural tests against the exact exported objects, before render.
for p in platforms:
    body = bpy.data.objects[p['id']]
    assert (body.matrix_world.translation - v(p['center'])).length < 2e-6
    assert (body.dimensions - Vector((p['size'][0], p['size'][2], p['size'][1]))).length < 2e-6
    assert body.parent.parent == all_fixed
    report['geometry_checks'] += 3
assert (hinge.matrix_world.translation - v(hinge_world)).length < 2e-6
report['geometry_checks'] += 1
for ob in [o for o in S.objects if o.type == 'MESH']:
    counts = {}
    for polygon in ob.data.polygons:
        for a, b in polygon.edge_keys:
            key = tuple(sorted((a, b)))
            counts[key] = counts.get(key, 0) + 1
    assert counts and all(c == 2 for c in counts.values()), ('Open mesh', ob.name)
    report['geometry_checks'] += 1
report['all_meshes_closed'] = True
saved_frame = frame.matrix_world.copy()
saved_hinge = hinge.matrix_world.copy()
saved_leaf = leaf.matrix_world.copy()
hinge.rotation_euler[2] += math.radians(65)
bpy.context.view_layer.update()
assert (frame.matrix_world.translation - saved_frame.translation).length < 1e-7
assert (hinge.matrix_world.translation - saved_hinge.translation).length < 1e-7
expected = Matrix.Translation(saved_hinge.translation) @ Matrix.Rotation(math.radians(65), 4, 'Z') @ Matrix.Translation(-saved_hinge.translation) @ saved_leaf
assert max(abs(leaf.matrix_world[i][j] - expected[i][j]) for i in range(4) for j in range(4)) < 3e-6
hinge.rotation_euler[2] = 0
bpy.context.view_layer.update()
report['geometry_checks'] += 3

wanted_exports = set(assets) if A.export_assets == 'all' else set(A.export_assets.split(','))
assert wanted_exports <= set(assets), wanted_exports
for ident, owner in assets.items():
    if ident in wanted_exports:
        export(owner, ident + '.glb')
if A.export_assets == 'all':
    export(all_fixed, 'fixed_platforms.glb')
report['exported_assets'] = sorted(wanted_exports)

camdata = bpy.data.cameras.new('Asset orthographic inspection')
cam = bpy.data.objects.new('Inspection camera', camdata)
S.collection.objects.link(cam)
S.camera = cam
camdata.type = 'ORTHO'
lights = []
for name, offset, energy, color in [('Soft key', (-3, -5, 7), 1000, (1, .97, .90)), ('Cool fill', (6, 3, 5), 600, (.80, .90, 1))]:
    data = bpy.data.lights.new(name, 'AREA')
    ob = bpy.data.objects.new(name, data)
    S.collection.objects.link(ob)
    data.energy = energy
    data.size = 5
    data.color = color
    lights.append((ob, Vector(offset)))

wanted = set(assets) if A.render_assets == 'all' else set(A.render_assets.split(','))
assert wanted <= set(assets), wanted
meshes = [o for o in S.objects if o.type == 'MESH']
if A.render:
    for ident in assets:
        if ident not in wanted:
            continue
        visible = [o for o in children(assets[ident]) if o.type == 'MESH']
        for ob in meshes:
            ob.hide_render = ob not in visible
        points = [ob.matrix_world @ Vector(p) for ob in visible for p in ob.bound_box]
        lo = Vector(tuple(min(p[i] for p in points) for i in range(3)))
        hi = Vector(tuple(max(p[i] for p in points) for i in range(3)))
        center = (hi + lo) / 2
        for light, offset in lights:
            light.location = center + offset
            light.rotation_euler = (center - light.location).to_track_quat('-Z', 'Y').to_euler()
        views = [('threequarter', Vector((-7, -9, 7))), ('reverse', Vector((7, 9, 7))), ('bottom', Vector((0, 0, -15)))]
        if ident == 'school_door':
            views.append(('open65', Vector((-7, -9, 7))))
        for view, direction in views:
            if view == 'open65':
                hinge.rotation_euler[2] = math.radians(65)
                bpy.context.view_layer.update()
            cam.location = center + direction
            cam.rotation_euler = ((0, math.pi, 0) if view == 'bottom' else (center - cam.location).to_track_quat('-Z', 'Y').to_euler())
            bpy.context.view_layer.update()
            # Exact camera-space projected bounds prevent clipping any orientation.
            points = [ob.matrix_world @ Vector(p) for ob in visible for p in ob.bound_box]
            viewpoints = [cam.matrix_world.inverted() @ p for p in points]
            extent = max(max(p.x for p in viewpoints) - min(p.x for p in viewpoints), max(p.y for p in viewpoints) - min(p.y for p in viewpoints))
            camdata.ortho_scale = extent * 1.20
            report['render_views'][ident + '/' + view] = {'camera_blender': [list(r) for r in cam.matrix_world], 'ortho_scale': camdata.ortho_scale}
            S.render.filepath = str(OUT / (ident + '_' + view + '_rgba.png'))
            bpy.ops.render.render(write_still=True)
            if view == 'open65':
                hinge.rotation_euler[2] = 0
                bpy.context.view_layer.update()

for ob in meshes:
    ob.hide_render = False
report['mesh_count'] = len(meshes)
report['texture_sha256'] = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in OUT.glob('*albedo.png')}
(OUT / 'door_platform_manifest.json').write_text(json.dumps(report, indent=2) + '\n')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / 'door_platforms.blend'))
print('DOOR_PLATFORM_ASSETS_OK', report['geometry_checks'], report['mesh_count'])
