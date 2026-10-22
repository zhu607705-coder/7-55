extends Node2D
## One true-alpha building. Ground is owned by the map and never by this node.
## Two mutually exclusive whole-texture passes give local facade depth for ONE actor.
## Body PNG remains unchanged; shader removes low-alpha extraction noise.
var profile: Dictionary = {}
var source_anchor := Vector2.ZERO
var body_rect := Rect2()
var body_image: Image
var body_image_scale: float=0.0
var rgb_mipmaps_alpha0: bool=false
var body_texture_filter: int=CanvasItem.TEXTURE_FILTER_LINEAR
var back_sprite: Sprite2D
var front_sprite: Sprite2D
var shadow_sprite: Sprite2D
var physics_body: StaticBody2D
var collision_shapes: Array[CollisionPolygon2D] = []
var depth_texture: ImageTexture
var rest_transform := Transform2D.IDENTITY
var geometry_overlay: Node2D
var configured := false
var body_enabled := true
var selected := false
var debug_geometry := false
var actor_foot_local := Vector2.ZERO

func configure(data: Dictionary, body_texture: Texture2D, shadow_texture: Texture2D = null) -> bool:
	if configured or body_texture == null: return false
	var rect: Array = data.get("body_world_rect", [])
	var anchor: Array = data.get("source_anchor", [])
	var baseline: Array = data.get("depth_baseline_crop_y", [])
	if rect.size() != 4 or anchor.size() != 2 or baseline.size() != int(rect[2]): return false
	if float(rect[2]) <= 0.0 or float(rect[3]) <= 0.0: return false
	profile = data.duplicate(true)
	source_anchor = Vector2(anchor[0], anchor[1])
	position = source_anchor
	var image_transform: Dictionary=data.get("body_image_to_world",{})
	body_image_scale=float(image_transform.get("scale",0.0))
	var image_origin: Array=image_transform.get("origin",[])
	if body_image_scale<=0 or image_origin.size()!=2:return false
	body_rect = Rect2(Vector2(image_origin[0],image_origin[1])-source_anchor,body_texture.get_size()*body_image_scale)
	if not body_rect.position.is_equal_approx(Vector2(rect[0],rect[1])-source_anchor) or not body_rect.size.is_equal_approx(Vector2(rect[2],rect[3])):return false
	body_image = body_texture.get_image()
	if body_image == null or body_image.is_empty(): return false
	if body_image.is_compressed(): body_image.decompress()
	if body_image.detect_alpha()==Image.ALPHA_NONE:return false
	rgb_mipmaps_alpha0=str(data.get("body_filter","linear"))=="rgb_mipmap_alpha0"
	if rgb_mipmaps_alpha0 and not body_image.has_mipmaps():
		push_error("RGB mipmap profile requires mipmapped original PNG import");return false
	body_texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS if rgb_mipmaps_alpha0 else CanvasItem.TEXTURE_FILTER_LINEAR
	var depth_image := Image.create(baseline.size(), 1, false, Image.FORMAT_RGBA8)
	for x in range(baseline.size()):
		var encoded := clampi(roundi(float(baseline[x]) / body_rect.size.y * 65535.0), 0, 65535)
		depth_image.set_pixel(x, 0, Color(float(encoded >> 8) / 255.0, float(encoded & 255) / 255.0, 0.0, 1.0))
	depth_texture = ImageTexture.create_from_image(depth_image)
	back_sprite = _make_body_sprite("BodyBehindActor", body_texture, false, 0)
	front_sprite = _make_body_sprite("BodyInFrontOfActor", body_texture, true, 20)
	if shadow_texture != null:
		var sr: Array = data.get("shadow_world_rect", rect)
		var shadow_transform: Dictionary=data.get("shadow_image_to_world",{})
		var shadow_scale: float=float(shadow_transform.get("scale",0.0))
		var shadow_origin: Array=shadow_transform.get("origin",[])
		if shadow_scale<=0 or shadow_origin.size()!=2:return false
		if not (shadow_texture.get_size()*shadow_scale).is_equal_approx(Vector2(sr[2],sr[3])):return false
		shadow_sprite = Sprite2D.new()
		shadow_sprite.name = str(data.id) + "_IndependentGroundShadow"
		shadow_sprite.texture = shadow_texture
		shadow_sprite.centered = false
		shadow_sprite.position = Vector2(shadow_origin[0],shadow_origin[1]) - source_anchor
		shadow_sprite.scale = Vector2.ONE*shadow_scale
		shadow_sprite.z_index = -10
		if data.has("shadow_clip_texture"):
			var shadow_material:=ShaderMaterial.new();shadow_material.shader=preload("res://campuses/buct_haidian/shaders/registered_contact_shadow.gdshader")
			shadow_material.set_shader_parameter("contact_clip",load("res://campuses/buct_haidian/"+str(data.shadow_clip_texture)))
			shadow_material.set_shader_parameter("shadow_opacity",float(data.get("shadow_opacity",1.0)));shadow_sprite.material=shadow_material
		else:shadow_sprite.modulate.a=float(data.get("shadow_opacity",1.0))
		add_child(shadow_sprite)
	physics_body = StaticBody2D.new()
	physics_body.name = "SourceGroundFootprint"
	physics_body.collision_layer = 1
	physics_body.collision_mask = 0
	add_child(physics_body)
	for poly: Array in data.get("collision_polygons_source_xy", []):
		if poly.size() < 3: continue
		var points := PackedVector2Array()
		for p: Array in poly: points.append(Vector2(p[0], p[1]) - source_anchor)
		if Geometry2D.decompose_polygon_in_convex(points).is_empty():
			push_error("Invalid source-foot polygon for "+str(data.id));return false
		var shape := CollisionPolygon2D.new()
		shape.polygon = points
		physics_body.add_child(shape)
		collision_shapes.append(shape)
	geometry_overlay = Node2D.new()
	geometry_overlay.name = "FootprintDepthOverlay"
	geometry_overlay.z_index = 30
	geometry_overlay.draw.connect(_draw_overlay)
	add_child(geometry_overlay)
	rest_transform = transform
	configured = true
	set_actor_foot(source_anchor)
	return true

func _make_body_sprite(node_name: String, texture: Texture2D, front: bool, depth: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.centered = false
	sprite.position = body_rect.position
	sprite.scale = Vector2.ONE*body_image_scale
	sprite.texture_filter = body_texture_filter
	sprite.z_index = depth
	var material := ShaderMaterial.new()
	material.shader = preload("res://campuses/buct_haidian/shaders/registered_body.gdshader")
	material.set_shader_parameter("depth_profile", depth_texture)
	material.set_shader_parameter("body_height", body_rect.size.y)
	material.set_shader_parameter("foreground_pass", front)
	material.set_shader_parameter("alpha_cutoff", profile.get("alpha_cutoff", 0.04))
	material.set_shader_parameter("solid_threshold", profile.get("solid_alpha_threshold", 0.95))
	material.set_shader_parameter("alpha_lod0",rgb_mipmaps_alpha0)
	sprite.material = material
	add_child(sprite)
	return sprite

func hit_test_alpha(world_point: Vector2) -> bool:
	if not configured or not body_enabled: return false
	var pixel := to_local(world_point) - body_rect.position
	if not Rect2(Vector2.ZERO, body_rect.size).has_point(pixel): return false
	pixel /= body_image_scale
	return body_image.get_pixel(clampi(int(pixel.x), 0, body_image.get_width()-1), clampi(int(pixel.y), 0, body_image.get_height()-1)).a >= float(profile.get("alpha_cutoff", 0.04))

func set_actor_foot(world_point: Vector2) -> void:
	if not configured: return
	actor_foot_local = to_local(world_point) - body_rect.position
	for sprite in [back_sprite, front_sprite]:
		sprite.material.set_shader_parameter("actor_foot_y", actor_foot_local.y)

func depth_y_at_world_x(world_x: float) -> float:
	# Translation and positive scale are supported; no rotated 2.5D campus building.
	var local_x := to_local(Vector2(world_x, global_position.y)).x - body_rect.position.x
	var values: Array = profile.depth_baseline_crop_y
	var ix := clampi(int(floor(local_x)), 0, values.size()-1)
	return to_global(body_rect.position + Vector2(local_x, float(values[ix]))).y

func set_selected(value: bool) -> void:
	selected = value
	for sprite in [back_sprite, front_sprite]: sprite.material.set_shader_parameter("selected", value)
	if is_instance_valid(geometry_overlay): geometry_overlay.queue_redraw()

func set_body_visible(value: bool) -> void:
	body_enabled = value
	back_sprite.visible = value
	front_sprite.visible = value
	if is_instance_valid(shadow_sprite): shadow_sprite.visible = value
	physics_body.collision_layer = 1 if value else 0
	if not value: set_selected(false)
	if is_instance_valid(geometry_overlay): geometry_overlay.queue_redraw()

func reset_building() -> void:
	transform = rest_transform
	set_body_visible(true)
	set_selected(false)
	debug_geometry = false
	if is_instance_valid(geometry_overlay): geometry_overlay.queue_redraw()

func set_debug_geometry(value: bool) -> void:
	debug_geometry = value
	if is_instance_valid(geometry_overlay): geometry_overlay.queue_redraw()

func _draw_overlay() -> void:
	if not configured or not debug_geometry: return
	for poly in collision_shapes:
		geometry_overlay.draw_colored_polygon(poly.polygon, Color(0.8, 0.2, 0.18, 0.12))
		var closed := poly.polygon.duplicate(); closed.append(closed[0])
		geometry_overlay.draw_polyline(closed, Color(0.8, 0.2, 0.18, 0.85), 0.5, true)
	var line := PackedVector2Array()
	var baseline: Array = profile.depth_baseline_crop_y
	for x in range(baseline.size()):
		if baseline[x] > 0: line.append(body_rect.position + Vector2(x+0.5, baseline[x]))
	if line.size() > 1: geometry_overlay.draw_polyline(line, Color(0.1, 0.8, 0.95, 0.9), 0.5, true)
