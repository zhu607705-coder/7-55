extends "res://campuses/buct/scripts/layered_building.gd"
## Full-campus adapter: one genuine RGBA building, native column-foot Y-sort.
## It deliberately avoids a globally foreground z pass over existing trees.
## Quads use the same complete texture and shared exact UV boundaries; no PNG slicing.
var depth_columns: Array[Node2D] = []
var column_material: ShaderMaterial

func _ready() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://campuses/buct/data/library-profile.json"))
	var configured_ok := configure(data, preload("res://campuses/buct/assets/library/library-body.png"), preload("res://campuses/buct/assets/library/library-shadow.png"))
	if not configured_ok:
		push_error("Chaoyang library configuration failed")
		hide()
		return
	_build_native_columns()
	shadow_sprite.z_index = -10
	visibility_changed.connect(_sync_native_visibility)
	_sync_native_visibility()

func _build_native_columns() -> void:
	y_sort_enabled = true
	back_sprite.hide(); front_sprite.hide()
	column_material = ShaderMaterial.new()
	column_material.shader = preload("res://campuses/buct/shaders/library_alpha.gdshader")
	column_material.set_shader_parameter("alpha_cutoff",profile.get("alpha_cutoff",0.04))
	column_material.set_shader_parameter("solid_threshold",profile.get("solid_alpha_threshold",0.95))
	var texture: Texture2D = back_sprite.texture
	var baseline: Array = profile.depth_baseline_crop_y.duplicate()
	# Transparent/soft-edge-only columns inherit the nearest solid edge depth.
	# Keep their actual alpha pixels; dropping them would truncate antialiasing.
	for i in range(baseline.size()):
		if float(baseline[i]) > 0:continue
		for distance in range(1,baseline.size()):
			if i-distance>=0 and float(profile.depth_baseline_crop_y[i-distance])>0:
				baseline[i]=profile.depth_baseline_crop_y[i-distance];break
			if i+distance<baseline.size() and float(profile.depth_baseline_crop_y[i+distance])>0:
				baseline[i]=profile.depth_baseline_crop_y[i+distance];break
	var x := 0
	while x < baseline.size():
		if float(baseline[x]) <= 0:
			x += 1
			continue
		var end_x := x+1
		# Merge only exactly equal adjacent foot depths; do not approximate the facade.
		while end_x < baseline.size() and float(baseline[end_x]) == float(baseline[x]): end_x += 1
		var depth := Polygon2D.new(); depth.name = "FacadeDepthStrip%03d" % x
		depth.position = body_rect.position + Vector2(float(x+end_x)*0.5,float(baseline[x]))
		var half_width := float(end_x-x)*0.5
		var top := -float(baseline[x]); var bottom := body_rect.size.y-float(baseline[x])
		depth.polygon = PackedVector2Array([Vector2(-half_width,top),Vector2(half_width,top),Vector2(half_width,bottom),Vector2(-half_width,bottom)])
		var left := float(x)/body_rect.size.x*texture.get_width()
		var right := float(end_x)/body_rect.size.x*texture.get_width()
		depth.uv = PackedVector2Array([Vector2(left,0),Vector2(right,0),Vector2(right,texture.get_height()),Vector2(left,texture.get_height())])
		depth.texture = texture; depth.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		depth.material = column_material
		add_child(depth);depth_columns.append(depth)
		x = end_x

func _sync_native_visibility() -> void:
	if is_instance_valid(physics_body): physics_body.collision_layer = 1 if body_enabled and is_visible_in_tree() else 0

func hit_test_alpha(world_point: Vector2) -> bool:
	return is_visible_in_tree() and super.hit_test_alpha(world_point)

func set_body_visible(value: bool) -> void:
	super.set_body_visible(value)
	back_sprite.hide();front_sprite.hide()
	for column in depth_columns:column.visible=value
	_sync_native_visibility()

func set_selected(value: bool) -> void:
	super.set_selected(value)
	if is_instance_valid(column_material):column_material.set_shader_parameter("selected",value)
