extends Node2D
## One static, source-pixel visible water segment. No navigation authority.
const PROFILE_PATH := "res://campuses/buct_changping/data/south_bridge_water_registration.json"
const CUTOUT_SHADER = preload("res://campuses/buct_changping/shaders/south_bridge_water_cutout.gdshader")
var profile: Dictionary
var water_sprite: Sprite2D
var cutout_material: ShaderMaterial
var static_ground: Sprite2D
var main_surface: Node2D
var main_cutout: Material
var alpha_image: Image
var source_origin := Vector2(395,867)
var selected := false

static func install(world: Node2D, main: Node2D) -> Node2D:
	var ground := world.get_node_or_null("StaticUnseparatedCampus") as Sprite2D
	if world.get_node_or_null("LiuLakeSouthBridgeWater") != null:return null
	if ground == null or ground.texture == null or ground.texture.get_size() != Vector2(950,1656):return null
	if not is_instance_valid(main) or main.get_parent() != world or ground.material != main.cutout_material:return null
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PROFILE_PATH))
	var texture: Texture2D = load(str(data.get("water_texture", "")))
	var segment := Node2D.new()
	segment.set_script(load("res://campuses/buct_changping/scripts/south_bridge_water_surface.gd"))
	segment.name = "LiuLakeSouthBridgeWater"
	if not segment.configure(data, texture, ground, main):
		segment.free()
		return null
	world.add_child(segment)
	world.move_child(segment, main.get_index() + 1)
	main.tree_exiting.connect(segment._on_main_exiting)
	# Atomic: the existing main cutout is replaced only after validation succeeds.
	ground.material = segment.cutout_material
	return segment

func configure(data: Dictionary, texture: Texture2D, ground: Sprite2D, main: Node2D) -> bool:
	if texture == null or ground == null or not is_instance_valid(main):return false
	if data.get("schema", "") != "buct_original_pixel_static_water_v1" or data.get("id", "") != "liuhu_south_bridge_visible_water":return false
	var crop: Array = data.get("crop_source_xywh", [])
	if crop.size() != 4 or Vector4(crop[0],crop[1],crop[2],crop[3]) != Vector4(395,867,24,21):return false
	if texture.get_size() != Vector2(24,21):return false
	var pixels := texture.get_image()
	if pixels == null or pixels.is_empty() or pixels.has_mipmaps():return false
	pixels.convert(Image.FORMAT_RGBA8)
	var bytes := pixels.get_data()
	for i in range(0,bytes.size(),4):
		if bytes[i+3] == 0:
			bytes[i] = 0; bytes[i+1] = 0; bytes[i+2] = 0
	var hash_context := HashingContext.new()
	hash_context.start(HashingContext.HASH_SHA256)
	hash_context.update(bytes)
	if hash_context.finish().hex_encode() != str(data.get("water_visible_rgba_sha256", "")):return false
	profile = data
	static_ground = ground
	main_surface = main
	main_cutout = main.cutout_material
	alpha_image = pixels
	position = source_origin
	water_sprite = Sprite2D.new()
	water_sprite.name = "OriginalPixelStaticWaterRGBA"
	water_sprite.texture = texture
	water_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	water_sprite.centered = false
	add_child(water_sprite)
	cutout_material = ShaderMaterial.new()
	cutout_material.shader = CUTOUT_SHADER
	cutout_material.set_shader_parameter("main_rgba", main.water_sprite.texture)
	cutout_material.set_shader_parameter("south_rgba", texture)
	return true

func set_selected(value: bool) -> void:
	selected = value

func hit_test_alpha(source_point: Vector2) -> bool:
	if not visible or alpha_image == null:return false
	var local := source_point - source_origin
	if local.x < 0 or local.y < 0 or local.x >= 24 or local.y >= 21:return false
	return alpha_image.get_pixel(floori(local.x),floori(local.y)).a > 0.5

func _on_main_exiting() -> void:
	# The old main component must restore only its own pixels. Keep this segment
	# separated if the main owner leaves first; never strand a main-pool hole.
	cutout_material.set_shader_parameter("main_installed", false)
	main_surface = null

func _exit_tree() -> void:
	if is_instance_valid(main_surface) and main_surface.tree_exiting.is_connected(_on_main_exiting):
		main_surface.tree_exiting.disconnect(_on_main_exiting)
	if is_instance_valid(static_ground) and static_ground.material == cutout_material:
		static_ground.material = main_cutout if is_instance_valid(main_surface) and main_surface.is_inside_tree() else null
