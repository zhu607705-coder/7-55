"""Blender offline preparation for the original Rodin campus asset batch.

Run with Blender --background --factory-startup --python this_file -- <downloads> <output>.
No network, credentials, animation clock, game collision or progression writes.
Blender Armature automatic heat weights: https://docs.blender.org/manual/en/latest/animation/armatures/skinning/parenting.html
Skeleton3D rest/pose contract: https://docs.godotengine.org/en/stable/classes/class_skeleton3d.html
"""
import bpy
import bmesh
from mathutils import Vector
from mathutils.kdtree import KDTree
import hashlib
import json
import math
from pathlib import Path
import sys

arguments = sys.argv[sys.argv.index("--") + 1:]
downloads, output = (Path(p) for p in arguments[:2])
student_id = arguments[2] if len(arguments) > 2 else "campus_student"
output.mkdir(parents=True, exist_ok=True)


def clean():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def load_asset(name):
    clean()
    source = downloads / name / "base_basic_pbr.glb"
    bpy.ops.import_scene.gltf(filepath=str(source))
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    assert meshes
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return source, obj


def bounds(obj):
    points = [v.co for v in obj.data.vertices]
    return Vector([min(p[i] for p in points) for i in range(3)]), Vector([max(p[i] for p in points) for i in range(3)])


def gltf_export(path):
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", export_yup=True, export_animations=False, export_extras=True)


def scenery(name, width):
    source, obj = load_asset(name)
    obj.name = name
    lo, hi = bounds(obj)
    factor = width / (hi.x - lo.x)
    center = (lo + hi) * .5
    for vertex in obj.data.vertices:
        p = vertex.co
        vertex.co = Vector(((p.x - center.x) * factor, (p.y - center.y) * factor, (p.z - lo.z) * factor))
    after_lo, after_hi = bounds(obj)
    obj["role"] = "Original generated campus scenery; no gameplay collision or route authority"
    report = {"sourceSha256": hashlib.sha256(source.read_bytes()).hexdigest(), "uniformScale": factor,
              "boundsGodot": {"min": [after_lo.x, after_lo.z, -after_hi.y], "max": [after_hi.x, after_hi.z, -after_lo.y]},
              "vertices": len(obj.data.vertices), "triangles": sum(len(p.vertices) - 2 for p in obj.data.polygons),
              "groundPivot": [0, 0, 0], "status": "import candidate; scene placement acceptance required"}
    gltf_export(output / (name + ".glb"))
    (output / (name + ".json")).write_text(json.dumps(report, indent=2) + "\n")
    print("RODIN_SCENERY_PREPARED " + json.dumps({"asset": name, **report}), flush=True)


def human(asset_id):
    source, obj = load_asset(asset_id)
    obj.name = "CampusStudentSkin"
    lo, hi = bounds(obj)
    factor = 2.82 / (hi.z - lo.z)
    # Rodin's front is +Z in glTF (-Y in Blender); the authored bike faces -Z.
    for vertex in obj.data.vertices:
        p = vertex.co
        vertex.co = Vector((-p.x * factor, -p.y * factor, (p.z - lo.z) * factor))
    # glTF splits coincident vertices at UV seams; reconnect geometric neighbors
    # for heat diffusion while retaining the per-loop UV coordinates.
    source_vertices = len(obj.data.vertices)
    editable = bmesh.new();editable.from_mesh(obj.data)
    bmesh.ops.remove_doubles(editable, verts=list(editable.verts), dist=.00001)
    editable.to_mesh(obj.data);editable.free();obj.data.update()
    # Calibrated A-pose positions in the existing bicycle's native unit scale.
    points = {"Hips": (0, 1.51, 0), "Torso": (0, 1.96, 0), "Head": (0, 2.46, 0)}
    parents = {"Hips": None, "Torso": "Hips", "Head": "Torso"}
    for side in (-1, 1):
        suffix = "L" if side < 0 else "R"
        for name, point, parent in [
            ("Shoulder", (side * .31, 2.18, 0), "Torso"),
            ("Elbow", (side * .65, 1.82, 0), "Shoulder" + suffix),
            ("Wrist", (side * .96, 1.40, 0), "Elbow" + suffix),
            ("Hip", (side * .16, 1.51, 0), "Hips"),
            ("Knee", (side * .16, .82, 0), "Hip" + suffix),
            ("Foot", (side * .16, .15, 0), "Knee" + suffix),
        ]:
            points[name + suffix] = point
            parents[name + suffix] = parent

    if asset_id == "campus_student_v2":
        # The reference-conditioned revision has a narrower relaxed A-pose.
        # Recalibrate this source; never reuse the wider first-generation arms.
        for side in (-1, 1):
            suffix = "L" if side < 0 else "R"
            points["Shoulder" + suffix] = (side * .30, 2.18, -.04)
            points["Elbow" + suffix] = (side * .49, 1.82, -.03)
            points["Wrist" + suffix] = (side * .62, 1.40, 0)

    if asset_id == "campus_student_v3":
        # Body subset of Godot's open-source SkeletonProfileHumanoid hierarchy:
        # hips -> spine -> chest -> neck/head, chest -> clavicle -> upper arm.
        # A shoulder blade must not be heat-weighted as a neck or an upper arm.
        points["Spine"] = (0, 1.73, 0)
        points["Neck"] = (0, 2.35, -.025)
        parents["Spine"] = "Hips"
        parents["Torso"] = "Spine"
        parents["Neck"] = "Torso"
        parents["Head"] = "Neck"
        for side in (-1, 1):
            suffix = "L" if side < 0 else "R"
            points["Clavicle" + suffix] = (side * .055, 2.22, -.025)
            parents["Clavicle" + suffix] = "Torso"
            parents["Shoulder" + suffix] = "Clavicle" + suffix
            points["Shoulder" + suffix] = (side * .32, 2.20, -.025)
            points["Elbow" + suffix] = (side * .49, 1.85, -.025)
            points["Wrist" + suffix] = (side * .62, 1.42, 0)
        obj["rig_profile_reference"] = "https://docs.godotengine.org/en/stable/classes/class_skeletonprofilehumanoid.html"
        # Preserve a normalized, completely unrigged mesh for silhouette review.
        gltf_export(output / "campus_student_unrigged.glb")

    def xyz(p):
        return Vector((p[0], -p[2], p[1]))

    armature_data = bpy.data.armatures.new("CampusContactSkeleton")
    armature = bpy.data.objects.new("CampusContactSkeleton", armature_data)
    bpy.context.collection.objects.link(armature)
    bpy.ops.object.select_all(action="DESELECT")
    armature.select_set(True)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.object.mode_set(mode="EDIT")
    for name, point in points.items():
        bone = armature_data.edit_bones.new(name)
        bone.head = xyz(point)
        children = [n for n, parent in parents.items() if parent == name]
        if name == "Hips":
            bone.tail = xyz(points["Spine"] if "Spine" in points else points["Torso"])
        elif name == "Torso":
            bone.tail = xyz(points["Neck"] if "Neck" in points else points["Head"])
        elif children:
            bone.tail = xyz(points[children[0]])
        else:
            bone.tail = bone.head + (Vector((0, 0, .30)) if name == "Head" else Vector((0, .17, 0)) if name.startswith("Foot") else Vector((-.11 if name.endswith("L") else .11, 0, -.15)))
    for name, parent in parents.items():
        if parent:
            armature_data.edit_bones[name].parent = armature_data.edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    obj.select_set(True)
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    unweighted = []
    # Keep the strongest four heat-weight influences, normalized for Web skinning.
    for vertex in obj.data.vertices:
        entries = sorted(((g.group, g.weight) for g in vertex.groups if g.weight > 1e-5), key=lambda g: g[1], reverse=True)[:4]
        if not entries:
            unweighted.append(vertex.index)
            continue
        total = sum(weight for _, weight in entries)
        for group in obj.vertex_groups:
            group.remove([vertex.index])
        for group, weight in entries:
            obj.vertex_groups[group].add([vertex.index], weight / total, "REPLACE")
    repaired = []
    if unweighted:
        # Tiny detached surface islands (eyes/cuffs etc.) may get no heat weight.
        # Transfer only from a nearby successfully weighted surface, never stretch
        # a distant unbound part toward an arbitrary nearest bone.
        missing = set(unweighted)
        tree = KDTree(len(obj.data.vertices) - len(missing))
        for vertex in obj.data.vertices:
            if vertex.index not in missing:
                tree.insert(vertex.co, vertex.index)
        tree.balance()
        for index in unweighted:
            vertex = obj.data.vertices[index]
            point, neighbor, distance = tree.find(vertex.co)
            if distance > .05:
                raise RuntimeError(f"Unweighted island {index} is {distance:.4f} native units from a weighted surface")
            for group in obj.data.vertices[neighbor].groups:
                obj.vertex_groups[group.group].add([index], group.weight, "REPLACE")
            repaired.append({"vertex": index, "neighbor": neighbor, "distance": distance})
    obj["source_task"] = json.loads((downloads / "receipt.json").read_text())["jobs"][asset_id]["uuid"]
    obj["role"] = "Original generated mesh with native contact skeleton; animation driven by Godot"
    report = {
        "sourceSha256": hashlib.sha256(source.read_bytes()).hexdigest(),
        "bonePoints": points, "boneParents": parents,
        "vertices": len(obj.data.vertices), "sourceVertices": source_vertices,
        "coincidentVerticesWelded": source_vertices - len(obj.data.vertices),
        "triangles": sum(len(p.vertices) - 2 for p in obj.data.polygons),
        "heatUnweightedVertices": len(unweighted), "unweightedVertices": 0, "maxWeights": 4,
        "surfaceWeightRepairs": repaired,
        "normalizationScale": factor, "groundPivot": [0, 0, 0],
        "front": "-Z in Godot", "skeleton": "Blender heat weights -> glTF Skin -> Godot Skeleton3D",
        "status": "import candidate; visual deformation and contact acceptance still required"
    }
    gltf_export(output / "campus_student_rigged.glb")
    bpy.ops.wm.save_as_mainfile(filepath=str(output / "campus_student_rigged.blend"))
    (output / "campus_student_rig.json").write_text(json.dumps(report, indent=2) + "\n")
    print("RODIN_HUMAN_PREPARED " + json.dumps(report), flush=True)


human(student_id)
for module, width in [("campus_glass_canopy", 16), ("campus_willow_verge", 10), ("campus_theater_foyer", 28)]:
    if (downloads / module).exists():scenery(module, width)
