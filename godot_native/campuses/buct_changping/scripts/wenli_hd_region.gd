extends Node2D
## One bounded default ground region; no physics, routes or new foliage masks.
const PROFILE := "res://campuses/buct_changping/data/wenli_hd_region.json"
const SELF_SCRIPT := "res://campuses/buct_changping/scripts/wenli_hd_region.gd"
const SOURCE_SHA := "f92a8de6ef703bab4b2e471a49acc082dd4d128d264d99d3ed1818fdb0c93707"
const BODY_SHA := "29acba79fa0ba17512350d3db377a6b8e2f675ef683f59754d305e2dc04f6afc"
const REGION := Rect2(630,615,240,240)
const TEXTURE_SIZE := Vector2i(1200,1200)
const WORLD_SCALE := 0.2
const MAX_NEW_GPU_BYTES := 12000000
const LEAF_IDS := ["east_road_east_leaf_edge_01","east_road_east_leaf_edge_02","east_road_east_leaf_edge_03","east_road_east_leaf_edge_04","east_road_east_leaf_edge_05","east_road_east_leaf_edge_06","east_road_east_leaf_edge_07","east_road_west_leaf_edge_01","east_road_west_leaf_edge_02"]
var profile: Dictionary = {}
var ground_texture: Texture2D
var shadow_texture: ImageTexture
var ground_sprite: Sprite2D
var shadow_sprite: Sprite2D
var building: Node2D
var legacy_ground: Sprite2D
var original_ground_visible := true
var leaf_restore: Array[Dictionary] = []
var _committed := false
var _transient_rgba_bytes := 0
var _gpu_bytes := 0

static func install(campus: Node2D, paths: Dictionary = {}) -> Node2D:
	if not is_instance_valid(campus.world) or not is_instance_valid(campus.wenli_layer):
		return null
	var existing: Node = campus.world.get_node_or_null("WenliHighDetailRegion")
	if existing != null:
		if existing.get("_committed") == true: return existing
		# A detached and re-added cached scene is safely in legacy fallback.
		# An explicit reinstall replaces the retired hidden component.
		existing.get_parent().remove_child(existing)
		existing.queue_free()
	var script_path: String = str(paths.get("script_path", SELF_SCRIPT))
	var script: Script = load(script_path)
	if script == null:
		return null
	var component := Node2D.new()
	component.set_script(script)
	component.name = "WenliHighDetailRegion"
	if not component._prepare(campus, paths):
		component.free()
		return null
	# Only after all assets, owners, masks and hashes validate do visuals change.
	campus.world.add_child(component)
	campus.world.move_child(component, campus.objects.get_index())
	component._commit()
	return component

func _prepare(campus: Node2D, paths: Dictionary) -> bool:
	if not paths.get("profile_path",PROFILE) is String: return false
	var path: String = paths.get("profile_path", PROFILE)
	if not FileAccess.file_exists(path): return false
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return false
	var decoded: Variant = parser.data
	if not decoded is Dictionary: return false
	profile = decoded
	if profile.get("schema", "") != "buct_wenli_hd_region_v1": return false
	if profile.get("source_sha256", "") != SOURCE_SHA or profile.get("body_sha256", "") != BODY_SHA: return false
	if not _numbers_equal(profile.get("runtime_size", []), [1200,1200]) or not _numbers_equal(profile.get("roi_xywh", []), [630,615,240,240]): return false
	if not profile.get("quality_approved", false) is bool or profile.get("quality_approved", false) != true: return false
	if not _number(profile.get("shadow_opacity",0.28)): return false
	var opacity: float = float(profile.get("shadow_opacity",0.28))
	if opacity < 0.0 or opacity > 1.0: return false
	building = campus.wenli_layer
	if building.profile.get("body_sha256", "") != BODY_SHA: return false
	if building.profile.body_image_to_world != profile.get("immutable_body_transform", {}): return false
	legacy_ground = campus.world.get_node_or_null("WenliInferredGroundWithinOriginalBodyOnly")
	if legacy_ground == null: return false
	original_ground_visible = legacy_ground.visible
	var texture_value: Variant = paths.get("ground_path", profile.get("ground_asset", ""))
	if not texture_value is String or texture_value.is_empty(): return false
	var texture_path: String = texture_value
	if not paths.get("external_png_preview",false) is bool: return false
	if paths.get("external_png_preview", false):
		# External proof loads the same final pixels before an editor import.
		# Production never sets this test-only path option.
		var image := Image.load_from_file(texture_path)
		if image == null or image.get_size() != TEXTURE_SIZE: return false
		image.convert(Image.FORMAT_RGBA8)
		if _sha(image.get_data()) != profile.get("ground_rgba_sha256", ""): return false
		_transient_rgba_bytes = image.get_data_size()
		image.generate_mipmaps()
		ground_texture = ImageTexture.create_from_image(image)
		image = null
	else:
		if not ResourceLoader.exists(texture_path): return false
		var texture_resource: Resource = load(texture_path)
		if not texture_resource is Texture2D: return false
		ground_texture = texture_resource
	if ground_texture == null or ground_texture.get_size() != Vector2(TEXTURE_SIZE): return false
	var verify_image: Image = ground_texture.get_image()
	if verify_image == null or not verify_image.has_mipmaps(): return false
	# get_image may expose a cached Image; never clear its imported mip chain.
	verify_image = verify_image.duplicate()
	if verify_image.is_compressed() and verify_image.decompress() != OK: return false
	verify_image.clear_mipmaps()
	verify_image.convert(Image.FORMAT_RGBA8)
	var verify_bytes := verify_image.get_data()
	_transient_rgba_bytes = maxi(_transient_rgba_bytes, verify_bytes.size())
	if _sha(verify_bytes) != profile.get("ground_rgba_sha256", ""): return false
	verify_bytes.clear()
	verify_image = null
	var shadow_value: Variant = paths.get("shadow_path", profile.get("shadow_asset", ""))
	if not shadow_value is String or shadow_value.is_empty(): return false
	var shadow_path: String = shadow_value
	if not FileAccess.file_exists(shadow_path): return false
	var shadow_bytes := FileAccess.get_file_as_bytes(shadow_path)
	if shadow_bytes.size() != TEXTURE_SIZE.x * TEXTURE_SIZE.y: return false
	if _sha(shadow_bytes) != profile.get("shadow_r8_sha256", ""): return false
	var shadow_image := Image.create_from_data(TEXTURE_SIZE.x,TEXTURE_SIZE.y,false,Image.FORMAT_R8,shadow_bytes)
	shadow_bytes.clear()
	shadow_image.generate_mipmaps()
	shadow_texture = ImageTexture.create_from_image(shadow_image)
	shadow_image = null
	_gpu_bytes = _mip_bytes(TEXTURE_SIZE,4) + _mip_bytes(TEXTURE_SIZE,1)
	if _gpu_bytes > MAX_NEW_GPU_BYTES: return false
	if not paths.get("shader_root", "res://campuses/buct_changping/shaders") is String: return false
	var shader_root: String = paths.get("shader_root", "res://campuses/buct_changping/shaders")
	var ground_shader: Resource = load(shader_root.path_join("wenli_hd_region.gdshader"))
	var shadow_shader: Resource = load(shader_root.path_join("wenli_hd_shadow.gdshader"))
	var leaf_shader: Resource = load(shader_root.path_join("wenli_hd_foliage.gdshader"))
	if not ground_shader is Shader or not shadow_shader is Shader or not leaf_shader is Shader: return false
	if not _prepare_leaves(campus, leaf_shader): return false
	ground_sprite = _sprite(ground_texture,"CoherentGroundAndCanopy")
	var ground_material := ShaderMaterial.new();ground_material.shader = ground_shader
	ground_material.set_shader_parameter("source_rect",Vector4(630,615,240,240))
	ground_sprite.material = ground_material
	add_child(ground_sprite)
	shadow_sprite = _sprite(shadow_texture,"IndependentWenliCastShadow")
	var shadow_material := ShaderMaterial.new();shadow_material.shader = shadow_shader
	shadow_material.set_shader_parameter("shadow_opacity",opacity)
	shadow_sprite.material = shadow_material
	add_child(shadow_sprite)
	return true

func _prepare_leaves(campus: Node2D, shader: Shader) -> bool:
	if not is_instance_valid(campus.east_road_extension): return false
	var expected: Variant = profile.get("foreground", [])
	if not expected is Array or expected.size() != 9: return false
	var pixels := 0
	var outside := 0
	var seen: Array[String] = []
	for spec in expected:
		if not spec is Dictionary: return false
		var id: Variant = spec.get("id","")
		if not id is String or id not in LEAF_IDS or id in seen: return false
		seen.append(id)
		if not _number(spec.get("baseline_y",null)): return false
		var leaf: Node2D = campus.east_road_extension.get_node_or_null(id)
		if leaf == null or not is_equal_approx(leaf.position.y,float(spec.baseline_y)): return false
		var sprite: Sprite2D = leaf.get_node_or_null("ExactOriginalLeafPixels")
		if sprite == null or sprite.texture == null: return false
		var box_value: Variant = spec.get("bbox_xywh",[])
		if not box_value is Array or box_value.size() != 4: return false
		var bbox: Array = box_value
		for value in bbox:
			if not _number(value): return false
		if bbox[2] <= 0 or bbox[3] <= 0: return false
		if not sprite.global_position.is_equal_approx(Vector2(bbox[0],bbox[1])): return false
		if sprite.texture.get_size() != Vector2(bbox[2],bbox[3]): return false
		var source_spec: Dictionary = {}
		for candidate in campus.east_road_extension.profile.foliage:
			if candidate.id == spec.id: source_spec = candidate;break
		if source_spec.is_empty(): return false
		var canonical := ""
		for span in source_spec.source_spans_y_x0_x1_exclusive:
			canonical += "%d,%d,%d;" % [int(span[0]),int(span[1]),int(span[2])]
			for x in range(int(span[1]),int(span[2])):
				pixels += 1
				if not REGION.has_point(Vector2(x,span[0])): outside += 1
		if _sha(canonical.to_utf8_buffer()) != spec.get("spans_sha256", ""): return false
		var material := ShaderMaterial.new();material.shader = shader
		material.set_shader_parameter("region_rgb",ground_texture)
		material.set_shader_parameter("source_rect",Vector4(630,615,240,240))
		leaf_restore.append({"sprite":sprite,"old_material":sprite.material,"new_material":material,
			"old_filter":sprite.texture_filter,"original_texture":sprite.texture})
	return seen.size() == LEAF_IDS.size() and pixels == 798 and outside == 17

func _commit() -> void:
	legacy_ground.hide()
	for entry in leaf_restore:
		entry.sprite.material = entry.new_material
		entry.sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_committed = true
	_process(0)

func _process(_delta: float) -> void:
	if _committed and is_instance_valid(shadow_sprite):
		shadow_sprite.visible = is_instance_valid(building) and building.is_visible_in_tree()

func uninstall() -> void:
	_restore()
	if get_parent() != null: get_parent().remove_child(self)
	queue_free()

func _restore() -> void:
	if not _committed: return
	_committed = false
	for entry in leaf_restore:
		if is_instance_valid(entry.sprite):
			entry.sprite.material = entry.old_material
			entry.sprite.texture_filter = entry.old_filter
	if is_instance_valid(legacy_ground): legacy_ground.visible = original_ground_visible
	hide()
	set_process(false)
	for sprite in [ground_sprite,shadow_sprite]:
		if is_instance_valid(sprite):
			sprite.hide()
			sprite.texture = null
			sprite.material = null
	leaf_restore.clear()
	ground_texture = null
	shadow_texture = null
	_gpu_bytes = 0

func _exit_tree() -> void:
	_restore()

func get_diagnostics() -> Dictionary:
	return {"active":_committed,"runtime_size":TEXTURE_SIZE,"world_rect":REGION,
		"world_scale":WORLD_SCALE,"new_gpu_texture_bytes":_gpu_bytes,
		"stable_retained_new_cpu_rgba_bytes":0,"validation_rgba_buffer_bytes":_transient_rgba_bytes,
		"leaf_materials":leaf_restore.size(),"leaf_derived_rgb_textures":0,
		"source_leaf_alpha_pixels":798,"outside_roi_leaf_alpha_pixels":17,
		"new_collision_bodies":0,"new_navigation_polygons":0}

static func _sprite(texture: Texture2D, label: String) -> Sprite2D:
	var sprite := Sprite2D.new();sprite.name = label
	sprite.centered = false;sprite.texture = texture
	sprite.position = REGION.position;sprite.scale = Vector2.ONE * WORLD_SCALE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return sprite

static func _sha(bytes: PackedByteArray) -> String:
	var context := HashingContext.new();context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()

static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func _mip_bytes(size: Vector2i, channels: int) -> int:
	var result := 0
	while true:
		result += size.x * size.y * channels
		if size == Vector2i.ONE: return result
		size = Vector2i(maxi(1,size.x/2),maxi(1,size.y/2))
	return result

static func _numbers_equal(value: Variant, expected: Array) -> bool:
	if not value is Array or value.size() != expected.size(): return false
	for i in range(expected.size()):
		if not _number(value[i]) or float(value[i]) != float(expected[i]): return false
	return true
