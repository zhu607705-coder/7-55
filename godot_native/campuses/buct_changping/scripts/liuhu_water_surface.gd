extends Node2D
## Fixed-location original-art water surface. No movement or navigation authority.
const PROFILE_PATH := "res://campuses/buct_changping/data/liuhu_water_registration.json"
const WATER_SHADER = preload("res://campuses/buct_changping/shaders/liuhu_water.gdshader")
const CUTOUT_SHADER = preload("res://campuses/buct_changping/shaders/liuhu_static_cutout.gdshader")
var profile: Dictionary
var water_sprite: Sprite2D
var water_material: ShaderMaterial
var cutout_material: ShaderMaterial
var static_ground: Sprite2D
var alpha_image: Image
var distance_image: Image
var source_origin := Vector2.ZERO
var animation_enabled := true
var selected := false
var wave_time := 0.0
var _hd_rgb_owner: CanvasItem
var _hd_rgb_texture: Texture2D
var _hd_rgb_material: ShaderMaterial
var _hd_rgb_rect := Rect2()
var _hd_rgb_sha := ""
var _hd_rgb_previous: Dictionary = {}
var _hd_rgb_active := false
var _hd_rgb_validation_full_mip_image_bytes := 0
var _hd_rgb_validation_base_rgba_bytes := 0

static func install(world: Node2D) -> Node2D:
	var ground := world.get_node_or_null("StaticUnseparatedCampus") as Sprite2D
	if ground == null or ground.texture == null or ground.material != null or ground.texture.get_size() != Vector2(950, 1656):
		push_error("Liu Lake needs its exact unmodified source-ground sprite")
		return null
	if world.get_node_or_null("LiuLakeMainSurface") != null:
		push_error("Liu Lake surface must have one owner")
		return null
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PROFILE_PATH))
	var texture: Texture2D = load(str(data.water_texture))
	var distance_texture: Texture2D = load(str(data.distance_texture))
	if texture == null or distance_texture == null:
		push_error("Liu Lake imported textures are unavailable")
		return null
	var lake := Node2D.new()
	lake.set_script(load("res://campuses/buct_changping/scripts/liuhu_water_surface.gd"))
	lake.name = "LiuLakeMainSurface"
	if not lake.configure(data, texture, distance_texture, ground):
		push_error("Liu Lake registration or imported pixel checksum is invalid; original ground preserved")
		lake.free()
		return null
	world.add_child(lake)
	world.move_child(lake, ground.get_index() + 1)
	# Apply complementary removal only after the new object is fully configured.
	ground.material = lake.cutout_material
	return lake

func configure(data: Dictionary, texture: Texture2D, distance_texture: Texture2D, ground: Sprite2D) -> bool:
	if texture == null or distance_texture == null or ground == null:return false
	if data.get("schema", "") != "buct_original_pixel_water_v1" or data.get("id", "") != "liuhu_main_surface":return false
	var crop: Array = data.get("crop_source_xywh", [])
	if crop.size() != 4:return false
	# JSON numbers are floats in Godot; Array[int] equality rejects valid JSON.
	if Vector4(crop[0],crop[1],crop[2],crop[3]) != Vector4(317,750,163,108):return false
	if texture.get_size() != Vector2(crop[2], crop[3]) or distance_texture.get_size() != texture.get_size():return false
	var imported_water := texture.get_image()
	var imported_distance := distance_texture.get_image()
	if imported_water == null or imported_distance == null or imported_water.is_empty() or imported_distance.is_empty():return false
	if imported_water.has_mipmaps() or imported_distance.has_mipmaps():return false
	imported_water.convert(Image.FORMAT_RGBA8)
	var distance_bytes := PackedByteArray()
	distance_bytes.resize(163 * 108)
	for y in range(108):
		for x in range(163):distance_bytes[y * 163 + x] = imported_distance.get_pixel(x,y).r8
	var water_bytes := imported_water.get_data()
	# Lossless texture codecs may canonicalize invisible RGB. Such pixels can
	# never pass the four-sample water guard; hash their alpha and zero RGB only.
	for i in range(0, water_bytes.size(), 4):
		if water_bytes[i+3] == 0:
			water_bytes[i] = 0; water_bytes[i+1] = 0; water_bytes[i+2] = 0
	if _sha256(water_bytes) != str(data.get("water_visible_rgba_sha256", "")):return false
	if _sha256(distance_bytes) != str(data.get("distance_r8_raw_sha256", "")):return false
	profile = data
	static_ground = ground
	source_origin = Vector2(crop[0], crop[1])
	position = source_origin
	alpha_image = imported_water
	distance_image = imported_distance
	water_material = ShaderMaterial.new()
	water_material.shader = WATER_SHADER
	water_material.set_shader_parameter("shore_distance", distance_texture)
	water_material.set_shader_parameter("water_size", texture.get_size())
	water_material.set_shader_parameter("amplitude_source_px", float(data.wave_amplitude_source_pixels_max))
	water_material.set_shader_parameter("angular_speed", float(data.wave_speed_radians_per_second))
	water_material.set_shader_parameter("static_border_source_px", float(data.frozen_animation_border_source_pixels))
	water_material.set_shader_parameter("fade_width_source_px", float(data.animation_feather_source_pixels))
	water_sprite = Sprite2D.new()
	water_sprite.name = "OriginalPixelWaterRGBA"
	water_sprite.texture = texture
	water_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	water_sprite.centered = false
	water_sprite.material = water_material
	add_child(water_sprite)
	cutout_material = ShaderMaterial.new()
	cutout_material.shader = CUTOUT_SHADER
	cutout_material.set_shader_parameter("water_rgba", texture)
	cutout_material.set_shader_parameter("source_size", ground.texture.get_size())
	cutout_material.set_shader_parameter("source_crop", Vector4(crop[0], crop[1], crop[2], crop[3]))
	return true

func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()

func _process(delta: float) -> void:
	if _hd_rgb_active and (not is_instance_valid(_hd_rgb_owner) or not _hd_rgb_owner.is_visible_in_tree()):_clear_hd_rgb()
	if animation_enabled:
		set_wave_time(wave_time + delta)

func set_wave_time(seconds: float) -> void:
	wave_time = maxf(0.0, seconds)
	water_material.set_shader_parameter("wave_time", wave_time)

func set_animation_enabled(enabled: bool) -> void:
	animation_enabled = enabled
	water_material.set_shader_parameter("animation_enabled", enabled)

func set_selected(value: bool) -> void:
	selected = value
	# The existing neutral status line provides selection feedback. Keep the
	# artwork free of a default frame, debug label, invented POI or glow.

func hit_test_alpha(source_point: Vector2) -> bool:
	if not visible or alpha_image == null:return false
	var local := source_point - source_origin
	if local.x < 0 or local.y < 0 or local.x >= alpha_image.get_width() or local.y >= alpha_image.get_height():return false
	return alpha_image.get_pixel(floori(local.x), floori(local.y)).a > 0.5

func _exit_tree() -> void:
	_clear_hd_rgb()
	# If this component is removed, restore the original ground owner cleanly.
	if is_instance_valid(static_ground) and static_ground.material == cutout_material:
		static_ground.material = null

## An optional RGB-only view of the already allocated SW region ground. Original
## water alpha, distance, registration, wave time and enabled state remain owners.
func install_hd_rgb(owner: CanvasItem, texture: Texture2D, source_rect: Rect2, rgba_sha256: String) -> bool:
	if not is_instance_valid(owner) or not owner.is_visible_in_tree() or texture==null:return false
	if not is_instance_valid(water_sprite) or water_material==null or water_sprite.material!=water_material or water_material.shader!=WATER_SHADER:return false
	if source_rect!=Rect2(398,615,256,240) or texture.get_size()!=Vector2(1280,1200):return false
	if _hd_rgb_active:
		return owner==_hd_rgb_owner and texture==_hd_rgb_texture and source_rect==_hd_rgb_rect and rgba_sha256==_hd_rgb_sha and _hd_rgb_material==water_material and water_material.get_shader_parameter("hd_rgb_enabled")==true and water_material.get_shader_parameter("hd_rgb")==texture
	# Do not take over an input owned outside this optional interface.
	if water_material.get_shader_parameter("hd_rgb_enabled")==true:return false
	var image: Image = texture.get_image()
	if image==null or image.is_empty():return false
	image=image.duplicate()
	if image.is_compressed() and image.decompress()!=OK:return false
	_hd_rgb_validation_full_mip_image_bytes=image.get_data_size()
	image.clear_mipmaps();image.convert(Image.FORMAT_RGBA8)
	_hd_rgb_validation_base_rgba_bytes=image.get_data_size()
	var bytes := image.get_data()
	if _sha256(bytes)!=rgba_sha256:return false
	for i in range(3,bytes.size(),4):
		if bytes[i]!=255:return false
	# Validation buffers are temporary. This interface adds no RGB allocation.
	image=null;bytes.clear()
	_hd_rgb_previous={}
	for key in ["hd_rgb_enabled","hd_rgb","hd_original_water","hd_source_rect"]:
		_hd_rgb_previous[key]=water_material.get_shader_parameter(key)
	_hd_rgb_owner=owner;_hd_rgb_texture=texture;_hd_rgb_material=water_material
	_hd_rgb_rect=source_rect;_hd_rgb_sha=rgba_sha256
	water_material.set_shader_parameter("hd_rgb",texture)
	# Named sampler avoids passing the built-in TEXTURE sampler through a shader
	# function, which the Compatibility compiler cannot lower on this engine.
	water_material.set_shader_parameter("hd_original_water",water_sprite.texture)
	water_material.set_shader_parameter("hd_source_rect",Vector4(source_rect.position.x,source_rect.position.y,source_rect.size.x,source_rect.size.y))
	water_material.set_shader_parameter("hd_rgb_enabled",true)
	_hd_rgb_active=true
	owner.tree_exiting.connect(_on_hd_rgb_owner_exiting)
	owner.visibility_changed.connect(_on_hd_rgb_owner_visibility_changed)
	return true

func remove_hd_rgb(owner: CanvasItem) -> bool:
	if not _hd_rgb_active:return true
	if not is_instance_valid(owner) or owner!=_hd_rgb_owner:return false
	_clear_hd_rgb()
	return true

func _on_hd_rgb_owner_exiting() -> void:
	_clear_hd_rgb()

func _on_hd_rgb_owner_visibility_changed() -> void:
	if _hd_rgb_active and (not is_instance_valid(_hd_rgb_owner) or not _hd_rgb_owner.is_visible_in_tree()):_clear_hd_rgb()

func _clear_hd_rgb() -> void:
	if not _hd_rgb_active:return
	_hd_rgb_active=false
	if is_instance_valid(_hd_rgb_owner):
		if _hd_rgb_owner.tree_exiting.is_connected(_on_hd_rgb_owner_exiting):_hd_rgb_owner.tree_exiting.disconnect(_on_hd_rgb_owner_exiting)
		if _hd_rgb_owner.visibility_changed.is_connected(_on_hd_rgb_owner_visibility_changed):_hd_rgb_owner.visibility_changed.disconnect(_on_hd_rgb_owner_visibility_changed)
	# Restore only the material whose inputs this interface actually installed.
	# A separately replaced material is never overwritten during group teardown.
	if is_instance_valid(_hd_rgb_material):
		for key in _hd_rgb_previous:_hd_rgb_material.set_shader_parameter(key,_hd_rgb_previous[key])
	_hd_rgb_owner=null;_hd_rgb_texture=null;_hd_rgb_material=null
	_hd_rgb_previous.clear();_hd_rgb_rect=Rect2();_hd_rgb_sha=""

func get_hd_rgb_diagnostics() -> Dictionary:
	return {"active":_hd_rgb_active,"source_rect":_hd_rgb_rect,"additional_gpu_texture_bytes":0,
		"shared_region_texture":_hd_rgb_active,"alpha_distance_unchanged":true,
		"independent_wave_clock":false,"hd_rgb_filter":"continuous_alpha_guarded_base_bilinear",
		"validation_full_mip_image_bytes":_hd_rgb_validation_full_mip_image_bytes,
		"validation_base_rgba_bytes":_hd_rgb_validation_base_rgba_bytes,"stable_retained_cpu_rgba_bytes":0,
		"hd_guard_fallback":"same_coordinate_static_hd_rgb","outer_fallback_source_collar_px":2,"outer_transition_source_px":10}
