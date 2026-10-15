extends Node2D
## Source-traced pavement only. Replaces the old guard with the joined union;
## it does not create physics, unlock interiors or change legacy route data.
const PROFILE := "res://campuses/buct_changping/data/north_road_extension.json"
var profile: Dictionary
var campus: Node2D
var extension: Node2D
var prior_edges: Array[PackedVector2Array] = []
var prior_rect := Rect2()
var added_polygon := PackedVector2Array()
var prior_boundary_owner: Variant
var _committed := false
var _resume_on_enter := false

static func install(map: Node2D, profile_path := PROFILE) -> Node2D:
	if not FileAccess.file_exists(profile_path): return null
	return _install_profile(map, JSON.parse_string(FileAccess.get_file_as_string(profile_path)))

static func _finite_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func _points(value: Variant, minimum: int, maximum: int) -> PackedVector2Array:
	var result := PackedVector2Array()
	if not value is Array or value.size() < minimum or value.size() > maximum: return result
	for pair in value:
		if not pair is Array or pair.size() != 2 or not _finite_number(pair[0]) or not _finite_number(pair[1]): return PackedVector2Array()
		var point := Vector2(float(pair[0]), float(pair[1]))
		if point.x < 0 or point.y < 0 or point.x > 950 or point.y > 1656: return PackedVector2Array()
		result.append(point)
	return result

static func _validated_geometry(decoded: Variant) -> Dictionary:
	if not decoded is Dictionary or decoded.get("schema", "") != "buct_bounded_original_art_road_v2": return {}
	var polygon := _points(decoded.get("polygon_source_xy"), 3, 128)
	if polygon.is_empty() or Geometry2D.triangulate_polygon(polygon).is_empty(): return {}
	var raw_edges: Variant = decoded.get("exposed_joined_union_boundary_segments")
	if not raw_edges is Array or raw_edges.is_empty() or raw_edges.size() > 256: return {}
	var edges: Array[PackedVector2Array] = []
	for raw_edge in raw_edges:
		var edge := _points(raw_edge, 2, 2)
		if edge.is_empty() or edge[0].distance_squared_to(edge[1]) < .000001: return {}
		edges.append(edge)
	var raw_rect: Variant = decoded.get("new_feet_guard_rect")
	if not raw_rect is Array or raw_rect.size() != 4: return {}
	for number in raw_rect:
		if not _finite_number(number): return {}
	var rect := Rect2(float(raw_rect[0]),float(raw_rect[1]),float(raw_rect[2]),float(raw_rect[3]))
	if rect.size.x <= 0 or rect.size.y <= 0 or not Rect2(0,0,950,1656).encloses(rect): return {}
	for point in polygon:
		if not rect.grow(.001).has_point(point): return {}
	# Joined edges include the old road tail beyond this local guard rectangle.
	# Their map bounds are validated above; only the new polygon must fit the guard.
	return {"polygon":polygon,"edges":edges,"rect":rect}

static func _install_profile(map: Node2D, decoded: Variant) -> Node2D:
	if not is_instance_valid(map.east_road_extension): return null
	var old: Node = map.objects.get_node_or_null("NorthOriginalRoadExtension")
	if old != null: return old
	# All untrusted values are checked and converted before any scene/navigation write.
	var geometry := _validated_geometry(decoded)
	if geometry.is_empty(): return null
	var node: Node2D = load("res://campuses/buct_changping/scripts/north_road_extension.gd").new()
	node.name = "NorthOriginalRoadExtension"
	node.profile = decoded
	node.campus = map
	node.extension = map.east_road_extension
	node.prior_edges = node.extension.exposed_edges.duplicate()
	node.prior_rect = node.extension.guard_rect
	node.prior_boundary_owner = node.extension.get_meta("joined_boundary_owner") if node.extension.has_meta("joined_boundary_owner") else null
	node.added_polygon = geometry.polygon
	map.objects.add_child(node)
	map.walk_polys.append(node.added_polygon)
	node.extension.exposed_edges = geometry.edges
	node.extension.guard_rect = geometry.rect
	node.extension.set_meta("joined_boundary_owner",node)
	node._committed = true
	return node

func uninstall(rebuild_grid := true) -> void:
	_restore()
	if rebuild_grid and is_instance_valid(campus) and campus.initialized:
		campus.walk_cells.clear()
		campus._build_grid()
	if get_parent() != null: get_parent().remove_child(self)
	queue_free()

func _restore() -> void:
	if not _committed: return
	_committed = false
	if is_instance_valid(extension) and extension.has_meta("joined_boundary_owner") and extension.get_meta("joined_boundary_owner")==self:
		extension.set_meta("joined_boundary_owner",prior_boundary_owner)
		extension.exposed_edges = prior_edges
		extension.guard_rect = prior_rect
	if is_instance_valid(campus): campus.walk_polys.erase(added_polygon)

func _enter_tree() -> void:
	# A cached whole-campus detach retires the guard, but reentry must restore
	# the same authored road rights. An explicit uninstall must stay retired.
	if not _resume_on_enter: return
	_resume_on_enter = false
	if _committed or not is_instance_valid(campus) or not is_instance_valid(extension): return
	var current_owner: Variant = extension.get_meta("joined_boundary_owner") if extension.has_meta("joined_boundary_owner") else null
	if current_owner != prior_boundary_owner: return
	var geometry := _validated_geometry(profile)
	if geometry.is_empty() or geometry.polygon != added_polygon or campus.walk_polys.has(added_polygon): return
	campus.walk_polys.append(added_polygon)
	extension.exposed_edges = geometry.edges
	extension.guard_rect = geometry.rect
	extension.set_meta("joined_boundary_owner",self)
	_committed = true

func _exit_tree() -> void:
	_resume_on_enter = _committed
	_restore()
