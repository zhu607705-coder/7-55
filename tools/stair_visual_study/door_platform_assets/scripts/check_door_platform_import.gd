extends SceneTree
## Isolated asset roundtrip check only. This is not a game scene or new runtime.
var checks: int = 0
var failures: int = 0
var meshes: int = 0
var textured: int = 0
var colliders: int = 0
var seen_materials: Dictionary = {}
var result: Dictionary = {}

func check(ok: bool, label: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(label)

func vector(data: Array) -> Vector3:
 return Vector3(data[0], data[1], data[2])

func inspect(root_node: Node, expected_images: Array[Image]) -> void:
 var queue: Array[Node] = [root_node]
 while not queue.is_empty():
  var node: Node = queue.pop_front()
  for child in node.get_children():
   queue.append(child)
  if node is CollisionObject3D:
   colliders += 1
  if not node is MeshInstance3D:
   continue
  meshes += 1
  var mi: MeshInstance3D = node
  check(mi.mesh != null, "mesh resource present: " + str(node.name))
  if mi.mesh == null:
   continue
  for i in range(mi.mesh.get_surface_count()):
   var mat: Material = mi.get_active_material(i)
   check(mat is StandardMaterial3D, "standard portable PBR material")
   if not mat is StandardMaterial3D or mat.albedo_texture == null:
    continue
   textured += 1
   check(mat.texture_filter in [BaseMaterial3D.TEXTURE_FILTER_NEAREST, BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS], "nearest pixel filter retained")
   var imported: Image = mat.albedo_texture.get_image()
   if imported.is_compressed():
    imported.decompress()
   imported.convert(Image.FORMAT_RGBA8)
   imported.clear_mipmaps()
   var match_index: int = -1
   for j in range(expected_images.size()):
    if imported.get_size() == expected_images[j].get_size() and imported.get_data() == expected_images[j].get_data():
     match_index = j
   check(match_index >= 0, "embedded authored texture base pixels exact")
   if match_index >= 0:
    check(absf(mat.roughness - ([.92, .88][match_index])) < .00001 and mat.metallic == 0, "authored PBR roughness retained")
    seen_materials[str(match_index)] = true

func _initialize() -> void:
 var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://door_platform_manifest.json"))
 var expected_images: Array[Image] = []
 for file: String in ["terrazzo_pixel_albedo.png", "school_wood_pixel_albedo.png"]:
  var img: Image = Image.load_from_file("res://" + file)
  check(img != null, "authored PNG present: " + file)
  if img == null:
   quit(1)
   return
  img.convert(Image.FORMAT_RGBA8)
  expected_images.append(img)
 for p: Dictionary in data.platforms:
  var packed: PackedScene = load("res://" + p.file)
  check(packed != null, "platform GLB imports: " + p.id)
  if packed == null:
   continue
  var instance: Node3D = packed.instantiate()
  root.add_child(instance)
  await process_frame
  var body: MeshInstance3D = instance.find_child(p.id, true, false)
  check(body != null, "source body name retained: " + p.id)
  if body != null:
   check(body.global_position.distance_to(vector(p.center)) < .00001, "exact source world centre: " + p.id)
   check(body.global_basis.is_equal_approx(Basis.IDENTITY), "slab axes retained: " + p.id)
   check(body.mesh.get_aabb().size.distance_to(vector(p.size)) < .00001, "exact source dimensions: " + p.id)
   check(absf(body.global_position.y + body.mesh.get_aabb().end.y - float(p.walk_top_y)) < .00001, "source walking top unchanged: " + p.id)
  var rails: Node3D = instance.find_child(p.rails_node, true, false)
  check(rails != null, "independent fixed rail node retained: " + p.id)
  if rails != null and body != null:
   check(rails.get_parent() == body.get_parent(), "fixed rails are siblings of source body: " + p.id)
  inspect(instance, expected_images)
  instance.queue_free()
  await process_frame
 var d: Dictionary = data.door
 var packed: PackedScene = load("res://" + d.file)
 check(packed != null, "door GLB imports")
 if packed != null:
  var instance: Node3D = packed.instantiate()
  root.add_child(instance)
  await process_frame
  var base: Node3D = instance.find_child(d.base_node, true, false)
  var frame: Node3D = instance.find_child(d.frame_node, true, false)
  var hinge: Node3D = instance.find_child(d.hinge_node, true, false)
  var leaf: MeshInstance3D = instance.find_child(d.leaf_node, true, false)
  check(base != null and frame != null and hinge != null and leaf != null, "four named door nodes retained")
  if base != null and frame != null and hinge != null and leaf != null:
   check(base.global_position.distance_to(vector(d.source_base_godot)) < .00001, "source door base retained")
   check(base.global_basis.is_equal_approx(Basis(Vector3.UP, float(d.source_rotation_y))), "source door 180 degree orientation retained")
   check(hinge.get_parent() == base and frame.get_parent() == base, "moving leaf and fixed frame independently parented")
   check(leaf.get_parent() == hinge, "door leaf attached to real hinge")
   check(hinge.position.distance_to(vector(d.hinge_local_godot)) < .00001, "source-local hinge point retained")
   check(hinge.global_position.distance_to(vector(d.hinge_world_godot)) < .00001, "world hinge coordinate roundtrip")
   check(leaf.mesh.get_aabb().size.distance_to(vector(d.leaf_size_m)) < .00001, "wood leaf dimensions preserved")
   check(leaf.global_position.distance_to(vector(d.leaf_closed_center_godot)) < .00001, "closed leaf centre preserved")
   check(leaf.mesh.get_aabb().size.distance_to(Vector3(1.24, 2.06, .14)) < .00001, "native production leaf dimensions, not historical study placeholder")
   check(base.to_local(leaf.global_position).distance_to(Vector3(0, 1.03, 0)) < .00001, "native closed panel centre exactly reproduced")
   var frame_transform: Transform3D = frame.global_transform
   var leaf_transform: Transform3D = leaf.global_transform
   var pivot: Vector3 = hinge.global_position
   for degrees: float in [65.0, 0.0, -65.0, 0.0, 90.0, 0.0, 65.0, 0.0]:
    hinge.rotation.y = deg_to_rad(degrees)
    await process_frame
    var turn := Transform3D(Basis(Vector3.UP, deg_to_rad(degrees)), Vector3.ZERO)
    var to_pivot := Transform3D(Basis.IDENTITY, pivot)
    var expected: Transform3D = to_pivot * turn * to_pivot.affine_inverse() * leaf_transform
    check(frame.global_transform.is_equal_approx(frame_transform), "door frame stays fixed at %s degrees" % degrees)
    check(hinge.global_position.distance_to(pivot) < .00001, "hinge axis stationary at %s degrees" % degrees)
    check(leaf.global_transform.is_equal_approx(expected), "correct pivot-relative leaf rotation at %s degrees" % degrees)
    if degrees == 90.0:
     var corridor := AABB(base.global_position + Vector3(-.25, .01, -.40), Vector3(.50, 1.75, .80))
     var queue: Array[Node] = [instance]
     while not queue.is_empty():
      var child: Node = queue.pop_front()
      for descendant in child.get_children():
       queue.append(descendant)
      if child is MeshInstance3D:
       var bound: AABB = child.global_transform * child.mesh.get_aabb()
       check(not bound.intersects(corridor), "90 degree open door preserves 0.5 m central passage: " + str(child.name))
   inspect(instance, expected_images)
  instance.queue_free()
  await process_frame
 check(colliders == 0, "zero collision authority introduced")
 check(meshes == int(data.mesh_count), "all exported asset meshes counted exactly")
 check(seen_materials.has("0") and seen_materials.has("1"), "both approved stone and authored wood preserved")
 result = {"checks": checks, "failures": failures, "meshes": meshes, "textured_surfaces": textured, "colliders": colliders,
           "platforms": data.platforms.size(), "hinge_repeated_angles": [65, 0, -65, 0, 90, 0, 65, 0], "source_rules_modified": false}
 var output := FileAccess.open("res://door_platform_import_evidence.json", FileAccess.WRITE)
 if output != null:
  output.store_string(JSON.stringify(result, "  ") + "\n")
 print("DOOR_PLATFORM_IMPORT ", JSON.stringify(result))
 quit(1 if failures else 0)
