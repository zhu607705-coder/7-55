extends RefCounted
const BUILDING = preload("res://campuses/buct_changping/scripts/first_teaching_building.gd")
const REPAIR_SHADER = preload("res://campuses/buct_changping/shaders/first_teaching_repair.gdshader")
const PROFILE = "res://campuses/buct_changping/data/first_teaching_registration.json"

static func install(world: Node2D, objects: Node2D, building_data: Dictionary) -> Node2D:
	var old: Node2D = objects.get_node_or_null("main_building")
	if old == null or not FileAccess.file_exists(PROFILE):
		push_error("First teaching patch lacks frozen legacy object or profile")
		return null
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PROFILE))
	var texture: Texture2D = load(str(data.body_asset))
	if texture == null:
		push_error("First teaching original RGBA is missing")
		return null
	# An imported compressed image may not carry mipmaps in a minimal stage.
	# Create one shared body texture only when needed; never a texture per pass.
	if not texture.get_image().has_mipmaps():
		var image: Image = texture.get_image()
		if image.is_compressed() and image.decompress() != OK:
			push_error("First teaching RGBA cannot be decompressed")
			return null
		image.generate_mipmaps()
		texture = ImageTexture.create_from_image(image)
	var body := Node2D.new()
	body.set_script(BUILDING)
	body.name = "FirstTeachingRGBA"
	if not body.configure(data, texture):
		body.free()
		return null
	var reference: Dictionary = {}
	for item in building_data.objects:
		if str(item.id) == "main_building": reference = item
	if reference.is_empty():
		body.free()
		return null
	# Commit replacement only after valid configuration. Keep BOTH old physical
	# children and their transforms/collision bits unchanged. No new collider.
	var retired := 0
	for child in old.get_children():
		if child is StaticBody2D: continue
		# _prepare_depth_layers already reparented only the actual _0 shadow.
		old.remove_child(child)
		child.queue_free()
		retired += 1
	# Exact polygon equality, not brittle anonymous serialized node names.
	var old_polygons: Array = [reference.silhouette]
	old_polygons.append_array(reference.get("visual_polygons", []))
	var underlays := 0
	for child in world.get_children():
		if not child is Polygon2D: continue
		for points in old_polygons:
			if _same_polygon(child.polygon, points):
				child.hide()
				underlays += 1
				break
	_install_repairs(world, objects)
	objects.add_child(body)
	body.set_meta("retired_legacy_visual_children", retired)
	body.set_meta("disabled_approximate_underlays", underlays)
	body.set_meta("original_physics_count", 2)
	return body

static func _same_polygon(polygon: PackedVector2Array, points: Array) -> bool:
	if polygon.size() != points.size(): return false
	for i in range(points.size()):
		if not polygon[i].is_equal_approx(Vector2(points[i][0],points[i][1])): return false
	return true

static func _install_repairs(world: Node2D, objects: Node2D) -> void:
	const PATH = "res://campuses/buct_changping/data/first_teaching_repairs.json"
	if not FileAccess.file_exists(PATH): return
	var profile: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	var root := Node2D.new()
	root.name = "FirstTeachingApprovedGroundFragments"
	world.add_child(root)
	world.move_child(root,objects.get_index())
	for item in profile.patches:
		var raw_path := "res://campuses/buct_changping/assets/" + str(item.raw_asset)
		var mask_path := "res://campuses/buct_changping/assets/" + str(item.permission_mask_asset)
		if not ResourceLoader.exists(raw_path) or not ResourceLoader.exists(mask_path):
			push_error("Missing first teaching approved repair candidate: " + str(item.id))
			continue
		var texture: Texture2D = load(raw_path)
		if texture.get_size() != Vector2(item.raw_size[0],item.raw_size[1]):
			push_error("First teaching repair dimensions changed")
			continue
		if not texture.get_image().has_mipmaps():
			var image: Image = texture.get_image()
			if image.is_compressed() and image.decompress() != OK:
				push_error("Cannot prepare first teaching repair mipmaps")
				continue
			image.generate_mipmaps()
			texture = ImageTexture.create_from_image(image)
		var sprite := Sprite2D.new()
		sprite.name = str(item.id)
		sprite.texture = texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite.centered = false
		sprite.position = Vector2(item.image_to_world.origin[0],item.image_to_world.origin[1])
		sprite.scale = Vector2.ONE * float(item.image_to_world.scale)
		var material := ShaderMaterial.new()
		material.shader = REPAIR_SHADER
		material.set_shader_parameter("permission_mask",load(mask_path))
		material.set_shader_parameter("image_world_origin",sprite.position)
		material.set_shader_parameter("raw_image_size",texture.get_size())
		material.set_shader_parameter("image_world_scale",float(item.image_to_world.scale))
		var rect: Array = item.source_context_rect
		material.set_shader_parameter("permission_world_rect",Vector4(rect[0],rect[1],rect[2],rect[3]))
		sprite.material = material
		root.add_child(sprite)
