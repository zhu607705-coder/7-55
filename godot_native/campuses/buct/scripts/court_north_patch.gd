extends RefCounted
## Atomic ownership-checked replacement of this one outdoor natural building.
const BUILDING = preload("res://campuses/buct/scripts/court_north_building.gd")
const PROFILE := "res://campuses/buct/data/court-north-profile.json"
const ID := "west_courts_north_bar"

static func install(world: Node2D, objects: Node2D, building_data: Dictionary) -> Node2D:
	var old: Node2D = objects.get_node_or_null(ID)
	if old == null or not FileAccess.file_exists(PROFILE):
		push_error("Court-north replacement needs its exact old group and registration")
		return null
	var reference: Dictionary = {}
	for item in building_data.objects:
		if str(item.id) == ID: reference = item
	if reference.is_empty() or reference.footprints.size() != 1:
		push_error("Court-north original foot ownership changed")
		return null
	if old.get_child_count() != 2 or old.get_node_or_null("SourcePixelSilhouette") == null:
		push_error("Court-north unexpected old visual children")
		return null
	var original_body: StaticBody2D = old.get_node_or_null("GroundFootprint0")
	if original_body == null or original_body.get_child_count() != 1 or not original_body.get_child(0) is CollisionPolygon2D:
		push_error("Court-north unexpected original ground-foot collider")
		return null
	var original_shape: CollisionPolygon2D = original_body.get_child(0)
	var absolute_foot := PackedVector2Array()
	for point in original_shape.polygon: absolute_foot.append(point + old.position)
	if not _same_polygon(absolute_foot, reference.footprints[0]):
		push_error("Court-north original ground-foot vertices changed")
		return null
	var underlay: Polygon2D = world.get_node_or_null("CleanUnderlay_" + ID)
	if underlay == null or not _same_polygon(underlay.polygon, reference.silhouette):
		push_error("Court-north matching approximate underlay cannot be verified")
		return null
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PROFILE))
	if data.get("id", "") != ID or not ResourceLoader.exists(str(data.get("body_asset", ""))):
		push_error("Court-north registered imported body is unavailable")
		return null
	var texture: Texture2D = load(str(data.body_asset))
	if texture == null or not texture.get_image().has_mipmaps():
		push_error("Court-north requires production mipmaps and explicit alpha import settings")
		return null
	var body := Node2D.new()
	body.set_script(BUILDING)
	if not body.configure(data, texture):
		body.free()
		return null
	var repairs: Array[Sprite2D] = []
	for item in data.get("ground_repairs", []):
		var repair_texture: Texture2D = load(str(item.asset))
		var rect: Array = item.source_rect
		if repair_texture == null or repair_texture.get_size() != Vector2(rect[2], rect[3]):
			for pending in repairs: pending.free()
			body.free()
			push_error("Court-north exact masked repair dimensions differ from contract")
			return null
		var repair := Sprite2D.new()
		repair.name = "CourtNorthMinimalNorthEdgeRepair"
		repair.centered = false
		repair.texture = repair_texture
		repair.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		repair.position = Vector2(rect[0], rect[1])
		repair.z_index = -10
		repairs.append(repair)
	# All validation precedes retirement. Neither route data nor other groups change.
	objects.remove_child(old)
	old.free()
	underlay.hide()
	body.name = ID
	objects.add_child(body)
	for repair in repairs: world.add_child(repair)
	body.set_meta("retired_legacy_body_count", 1)
	body.set_meta("retired_legacy_foot_count", 1)
	body.set_meta("disabled_approximate_underlay_count", 1)
	return body

static func _same_polygon(polygon: PackedVector2Array, points: Array) -> bool:
	if polygon.size() != points.size(): return false
	for i in range(points.size()):
		if not polygon[i].is_equal_approx(Vector2(points[i][0], points[i][1])): return false
	return true
