extends RefCounted
## Atomic, ownership-checked replacement of this one exterior building.
const BUILDING = preload("res://campuses/buct_changping/scripts/library_building.gd")
const PROFILE = "res://campuses/buct_changping/data/library_registration.json"
const VISUAL_NAMES = ["SourcePixelSilhouette", "SourceRasterGuardDepth", "WestFacadeDepth", "EastFacadeDepth"]

static func install(world: Node2D, objects: Node2D, building_data: Dictionary) -> Node2D:
	var old: Node2D = objects.get_node_or_null("library")
	if old == null or not FileAccess.file_exists(PROFILE):
		push_error("Library replacement lacks its known legacy group or registration")
		return null
	var reference: Dictionary = {}
	for item in building_data.objects:
		if str(item.id) == "library": reference = item
	if reference.is_empty() or reference.footprints.size() != 2:
		push_error("Library replacement cannot verify the original two physical feet")
		return null
	# Fail before touching the old scene if ownership has changed.
	var retired: Array[Node] = []
	var physical_count := 0
	for child in old.get_children():
		if child is StaticBody2D:
			physical_count += 1
			continue
		if str(child.name) not in VISUAL_NAMES:
			push_error("Library replacement found an unverified old child: " + str(child.name))
			return null
		retired.append(child)
	if physical_count != 2 or retired.size() != VISUAL_NAMES.size():
		push_error("Library legacy visual or physical count differs from the source contract")
		return null
	var matching_underlays: Array[Polygon2D] = []
	for child in world.get_children():
		if child is Polygon2D and _same_polygon(child.polygon, reference.silhouette):
			matching_underlays.append(child)
	if matching_underlays.size() != 1:
		push_error("Library exact old body underlay cannot be uniquely identified")
		return null
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PROFILE))
	if data.get("id", "") != "library" or not ResourceLoader.exists(str(data.body_asset)):
		push_error("Library registered imported body Texture2D is unavailable")
		return null
	var east: StaticBody2D = old.get_node_or_null("GroundFootprint1")
	if east == null or east.get_child_count() != 1 or not east.get_child(0) is CollisionPolygon2D:
		push_error("Library east ground-foot shape ownership changed")
		return null
	var east_shape: CollisionPolygon2D = east.get_child(0)
	var east_polygon := PackedVector2Array()
	for p in data.replacement_east_footprint_source_xy:
		east_polygon.append(east_shape.to_local(world.to_global(Vector2(p[0], p[1]))))
	if Geometry2D.triangulate_polygon(east_polygon).is_empty():
		push_error("Library actual east contact band is not a valid simple polygon")
		return null
	var texture: Texture2D = load(str(data.body_asset))
	if texture == null or not texture.get_image().has_mipmaps():
		push_error("Library requires the committed production texture import with mipmaps")
		return null
	var body := Node2D.new()
	body.set_script(BUILDING)
	body.name = "LibraryRGBA"
	if not body.configure(data, texture):
		body.free()
		return null
	# Registration and exact ownership are valid. Preserve the original south foot.
	# Correct only the known east shape to the actual facade ground contact band.
	# Route polygons and nearby trees, lake, paths, and other groups stay unchanged.
	east_shape.polygon = east_polygon
	var debug_footprints: Array[PackedVector2Array] = old.footprint_polygons.duplicate()
	var east_debug := PackedVector2Array()
	for p in data.replacement_east_footprint_source_xy:
		east_debug.append(old.to_local(world.to_global(Vector2(p[0], p[1]))))
	debug_footprints[1] = east_debug
	old.footprint_polygons = debug_footprints
	for child in retired:
		old.remove_child(child)
		child.queue_free()
	for underlay in matching_underlays: underlay.hide()
	objects.add_child(body)
	body.set_meta("retired_legacy_visual_children", retired.size())
	body.set_meta("disabled_approximate_underlays", matching_underlays.size())
	body.set_meta("original_physics_count", physical_count)
	body.set_meta("corrected_library_east_ground_foot", true)
	return body

static func _same_polygon(polygon: PackedVector2Array, points: Array) -> bool:
	if polygon.size() != points.size(): return false
	for i in range(points.size()):
		if not polygon[i].is_equal_approx(Vector2(points[i][0], points[i][1])): return false
	return true
