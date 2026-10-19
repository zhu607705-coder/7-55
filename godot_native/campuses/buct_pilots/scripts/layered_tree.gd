extends Node2D
## A genuinely separated 2D tree: fixed trunk, independently animated crown,
## small feet collider, and an independent ground-shadow sibling.
## Every texture is a transparent asset. No campus overview/UV sampling here.

var canopy_pivot: Node2D
var canopy: Sprite2D
var trunk: Sprite2D
var ground_shadow: Sprite2D
var collision_body: StaticBody2D
var phase := 0.0
var wind_enabled := true
var maximum_sway_radians := 0.014
var phase_offset := 0.0
var canvas_world_size := Vector2(256,160)
var shadow_pixel_scale := Vector2.ONE
var source_anchor := Vector2.ZERO
var shadow_canvas_origin := Vector2.ZERO
var crown_joint := Vector2.ZERO
var selected := false
var manual_crown_angle := 0.0
var alpha_images: Dictionary = {}

func configure(item: Dictionary, parent_shadows: Node2D, asset_root: String) -> void:
	name = str(item.id)
	source_anchor = Vector2(item.anchor[0], item.anchor[1])
	var joint: Array = item.get("crown_joint",[source_anchor.x,source_anchor.y-10.0])
	crown_joint = Vector2(joint[0],joint[1])
	position = source_anchor
	var size: Array = item.get("world_canvas_size",[256,160])
	canvas_world_size = Vector2(size[0],size[1])
	phase_offset = float(item.get("phase", 0.0))
	maximum_sway_radians = float(item.get("sway_radians", 0.014))
	ground_shadow = _sprite("GroundShadow_" + name, asset_root + str(item.shadow),item.get("shadow_region",[]),item.get("shadow_world_rect",[]),true)
	shadow_pixel_scale = ground_shadow.scale
	shadow_canvas_origin = ground_shadow.get_meta("canvas_origin_world")
	ground_shadow.position = shadow_canvas_origin
	parent_shadows.add_child(ground_shadow)
	trunk = _sprite("FixedTrunk", asset_root + str(item.trunk),item.get("trunk_region",[]),item.get("trunk_world_rect",[]))
	trunk.position = trunk.get_meta("canvas_origin_world") - source_anchor
	add_child(trunk)
	canopy_pivot = Node2D.new()
	canopy_pivot.name = "FlexibleCrown"
	canopy_pivot.position = crown_joint-source_anchor
	add_child(canopy_pivot)
	canopy = _sprite("TransparentCrown", asset_root + str(item.canopy),item.get("canopy_region",[]),item.get("canopy_world_rect",[]))
	canopy.position = canopy.get_meta("canvas_origin_world") - crown_joint
	canopy_pivot.add_child(canopy)
	collision_body = StaticBody2D.new()
	collision_body.name = "TrunkOnlyCollision"
	collision_body.collision_layer = 1
	collision_body.collision_mask = 0
	var shape := CollisionShape2D.new()
	shape.name = "GroundFootprint"
	var circle := CircleShape2D.new()
	circle.radius = float(item.get("trunk_radius", 2.2))
	shape.shape = circle
	collision_body.add_child(shape)
	add_child(collision_body)
	set_meta("layer_contract", "independent_rgba_crown_trunk_shadow")
	for sprite in [canopy,trunk]:
		if sprite.texture != null:alpha_images[sprite]=sprite.texture.get_image()

func _sprite(node_name: String, path: String, region: Array = [], world_rect: Array = [], is_shadow := false) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.centered = false
	sprite.texture = load(path)
	if sprite.texture != null:
		# Each generated pass may have a different actual pixel resolution.
		# Registration is tied to its complete artwork frame, not an assumed 4x.
		sprite.scale = canvas_world_size / sprite.texture.get_size()
	var canvas_origin := Vector2.ZERO
	if region.size() == 4:
		var atlas := AtlasTexture.new()
		atlas.atlas = sprite.texture
		atlas.region = Rect2(region[0],region[1],region[2],region[3])
		atlas.filter_clip = true
		sprite.texture = atlas
		canvas_origin = atlas.region.position
	sprite.set_meta("canvas_origin_pixels",canvas_origin)
	var world_origin:=canvas_origin*sprite.scale
	if world_rect.size()==4 and sprite.texture!=null:
		world_origin=Vector2(world_rect[0],world_rect[1])
		sprite.scale=Vector2(world_rect[2],world_rect[3])/sprite.texture.get_size()
	sprite.set_meta("canvas_origin_world",world_origin)
	# True PNG alpha stays authoritative. This removes only generated near-zero
	# fringe noise at render time; it does not create a fake transparency mask.
	var shader:=Shader.new()
	shader.code="shader_type canvas_item; uniform float alpha_cutoff = 0.04; uniform bool preserve_translucency = false; void fragment(){ vec4 c=texture(TEXTURE,UV); if(c.a<alpha_cutoff){discard;} if(!preserve_translucency && c.a>0.95){c.a=1.0;} COLOR=c; }"
	var material:=ShaderMaterial.new()
	material.shader=shader
	material.set_shader_parameter("preserve_translucency",is_shadow)
	sprite.material=material
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return sprite

func _process(delta: float) -> void:
	phase += delta
	if is_instance_valid(ground_shadow):
		# Keep a moved tree's shadow registered without parenting it above actors.
		ground_shadow.global_transform = global_transform * Transform2D(0.0, shadow_pixel_scale, 0.0, shadow_canvas_origin-source_anchor)
	if is_instance_valid(canopy_pivot):
		canopy_pivot.rotation = manual_crown_angle + (maximum_sway_radians * sin(phase * 1.35 + phase_offset) if wind_enabled else 0.0)

func hit_test_world(point: Vector2) -> bool:
	if not is_visible_in_tree():return false
	for sprite in [canopy,trunk]:
		if not sprite.is_visible_in_tree():continue
		var image: Image = alpha_images.get(sprite)
		if image == null:continue
		var local: Vector2 = sprite.to_local(point)
		var pixel := Vector2i(floori(local.x),floori(local.y))
		if Rect2i(Vector2i.ZERO,image.get_size()).has_point(pixel) and image.get_pixelv(pixel).a > 0.12:return true
	return false

func set_selected(value: bool) -> void:
	selected=value
	queue_redraw()

func nudge_crown(angle: float) -> void:
	manual_crown_angle=clampf(manual_crown_angle+angle,-0.18,0.18)
	_process(0.0)

func reset_pose() -> void:
	manual_crown_angle=0.0
	phase=0.0
	wind_enabled=false
	position=source_anchor
	rotation=0.0
	scale=Vector2.ONE
	_process(0.0)

func _draw() -> void:
	if selected:
		draw_set_transform(Vector2.ZERO,0.0,Vector2(1.0,0.55))
		draw_arc(Vector2.ZERO,6.2,0.0,TAU,40,Color(0.15,0.58,0.53,0.9),0.55,true)

func set_object_visible(value: bool) -> void:
	visible = value
	if not value:set_selected(false)
	if is_instance_valid(ground_shadow): ground_shadow.visible = value
	if is_instance_valid(collision_body):
		collision_body.get_node("GroundFootprint").set_deferred("disabled", not value)

func _exit_tree() -> void:
	# Shadow belongs to a ground plane, so explicit lifetime ownership matters.
	if is_instance_valid(ground_shadow): ground_shadow.queue_free()
