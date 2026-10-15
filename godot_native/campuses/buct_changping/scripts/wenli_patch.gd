extends RefCounted
## One exterior object. Physics and true courtyard pixels retain original ownership.
const BUILDING = preload("res://campuses/buct_changping/scripts/wenli_building.gd")
const GROUND_SHADER = preload("res://campuses/buct_changping/shaders/wenli_ground.gdshader")
const PROFILE = "res://campuses/buct_changping/data/wenli_registration.json"
const VISUAL_NAMES = ["SourcePixelSilhouette", "wenli_building_SourceShadowOrAnnex_0", "wenli_building_SourceShadowOrAnnex_1", "wenli_building_SourceShadowOrAnnex_2"]

static func install(world: Node2D, objects: Node2D, building_data: Dictionary) -> Node2D:
	var old: Node2D = objects.get_node_or_null("wenli_building")
	if old == null or not FileAccess.file_exists(PROFILE):
		push_error("Wenli replacement lacks its source group or registration")
		return null
	var reference: Dictionary = {}
	for item in building_data.objects:
		if str(item.id) == "wenli_building": reference = item
	if reference.is_empty() or reference.footprints.size() != 3:
		push_error("Wenli requires the original three collision bodies")
		return null
	var retired: Array[Node] = []
	var physical_count := 0
	for child in old.get_children():
		if child is StaticBody2D:
			physical_count += 1
			continue
		if str(child.name) not in VISUAL_NAMES:
			push_error("Wenli found an unverified legacy child: " + str(child.name))
			return null
		retired.append(child)
	if physical_count != 3 or retired.size() != VISUAL_NAMES.size():
		push_error("Wenli legacy ownership changed")
		return null
	var polygons: Array = [reference.silhouette]
	polygons.append_array(reference.visual_polygons)
	var underlays: Array[Polygon2D] = []
	for child in world.get_children():
		if not child is Polygon2D: continue
		for polygon in polygons:
			if _same_polygon(child.polygon, polygon):
				underlays.append(child)
				break
	if underlays.size() != 4:
		push_error("Wenli cannot identify all four old approximate covers")
		return null
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PROFILE))
	if data.get("id", "") != "wenli_building": return null
	var texture: Texture2D = load(str(data.body_asset))
	if texture == null or not texture.get_image().has_mipmaps():
		push_error("Wenli requires its imported immutable RGBA with mipmaps")
		return null
	var body := Node2D.new()
	body.set_script(BUILDING)
	body.name = "WenliRGBA"
	if not body.configure(data, texture):
		body.free()
		return null
	var ground := _prepare_ground(data)
	if ground == null:
		body.free()
		return null
	# Commit only after all inputs, owners and explicit masks validate.
	# Never change the original three bodies, player feet or navigation polygons.
	for child in retired:
		old.remove_child(child)
		child.queue_free()
	for underlay in underlays: underlay.hide()
	world.add_child(ground)
	world.move_child(ground, objects.get_index())
	objects.add_child(body)
	body.set_meta("retired_legacy_visual_children", retired.size())
	body.set_meta("disabled_approximate_underlays", underlays.size())
	body.set_meta("original_physics_count", physical_count)
	body.set_meta("ground_is_inferred", true)
	return body

static func _prepare_ground(data: Dictionary) -> Sprite2D:
	var spec: Dictionary = data.source_removal
	var rect: Array = spec.rect
	var bytes := FileAccess.get_file_as_bytes(str(spec.path))
	if bytes.size() != int(rect[2]) * int(rect[3]):
		push_error("Wenli original-source ownership mask length changed")
		return null
	var mask := Image.create_from_data(int(rect[2]), int(rect[3]), false, Image.FORMAT_R8, bytes)
	var sprite := Sprite2D.new()
	sprite.name = "WenliInferredGroundWithinOriginalBodyOnly"
	sprite.centered = false
	sprite.texture = load(str(data.ground.asset))
	if sprite.texture == null:
		sprite.free()
		return null
	sprite.position = Vector2(data.ground.origin[0], data.ground.origin[1])
	sprite.scale = Vector2.ONE * float(data.ground.scale)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var material := ShaderMaterial.new()
	material.shader = GROUND_SHADER
	material.set_shader_parameter("source_ownership", ImageTexture.create_from_image(mask))
	material.set_shader_parameter("source_rect", Vector4(rect[0],rect[1],rect[2],rect[3]))
	material.set_shader_parameter("image_origin", sprite.position)
	material.set_shader_parameter("raw_size", sprite.texture.get_size())
	material.set_shader_parameter("world_scale", float(data.ground.scale))
	material.set_shader_parameter("inferred_shade", float(data.ground.inferred_shade_multiplier))
	sprite.material = material
	return sprite

static func _same_polygon(polygon: PackedVector2Array, points: Array) -> bool:
	if polygon.size() != points.size(): return false
	for i in range(points.size()):
		if not polygon[i].is_equal_approx(Vector2(points[i][0], points[i][1])): return false
	return true
