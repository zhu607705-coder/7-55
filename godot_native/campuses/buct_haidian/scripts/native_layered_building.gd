extends "res://campuses/buct_haidian/scripts/layered_building.gd"
## Full-campus adapter: one genuine RGBA building, native column-foot Y-sort.
## It deliberately avoids a globally foreground z pass over existing trees.
## Quads use the same complete texture and shared exact UV boundaries; no PNG slicing.
var depth_columns: Array[Node2D] = []
var column_material: ShaderMaterial
var rendered_source_columns:=0
var skipped_transparent_columns:=0

func configure_native(data: Dictionary, body_texture: Texture2D, shadow_texture: Texture2D = null) -> bool:
	if not configure(data,body_texture,shadow_texture):return false
	_build_native_columns()
	if is_instance_valid(shadow_sprite):shadow_sprite.z_index=-10
	visibility_changed.connect(_sync_native_visibility)
	_sync_native_visibility()
	return true

func _build_native_columns() -> void:
	y_sort_enabled = true
	back_sprite.hide(); front_sprite.hide()
	column_material = ShaderMaterial.new()
	column_material.shader = preload("res://campuses/buct_haidian/shaders/registered_alpha.gdshader")
	column_material.set_shader_parameter("alpha_cutoff",profile.get("alpha_cutoff",0.04))
	column_material.set_shader_parameter("solid_threshold",profile.get("solid_alpha_threshold",0.95))
	column_material.set_shader_parameter("alpha_lod0",rgb_mipmaps_alpha0)
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
	rendered_source_columns=0;skipped_transparent_columns=0
	var eligible: Array=profile.get("render_nontransparent_columns",[])
	var x := 0
	while x < baseline.size():
		if float(baseline[x]) <= 0 or (eligible.size()==baseline.size() and not bool(eligible[x])):
			skipped_transparent_columns+=1
			x += 1
			continue
		var end_x := x+1
		# Merge only exactly equal adjacent foot depths; do not approximate the facade.
		while end_x < baseline.size() and float(baseline[end_x]) == float(baseline[x]) and (eligible.size()!=baseline.size() or bool(eligible[end_x])): end_x += 1
		var depth: Node2D
		var left := float(x)/body_image_scale
		var right := float(end_x)/body_image_scale
		if str(profile.get("render_backend","polygon"))=="sprite_regions":
			var sprite:=Sprite2D.new();sprite.centered=false;sprite.region_enabled=true
			sprite.region_filter_clip_enabled=false;sprite.region_rect=Rect2(left,0,right-left,texture.get_height())
			sprite.position=body_rect.position+Vector2(x,float(baseline[x]));sprite.scale=Vector2.ONE*body_image_scale
			sprite.offset=Vector2(0,-float(baseline[x])/sprite.scale.y);sprite.texture=texture;depth=sprite
		else:
			var polygon:=Polygon2D.new()
			polygon.position = body_rect.position + Vector2(float(x+end_x)*0.5,float(baseline[x]))
			var half_width := float(end_x-x)*0.5
			var top := -float(baseline[x]); var bottom := body_rect.size.y-float(baseline[x])
			polygon.polygon = PackedVector2Array([Vector2(-half_width,top),Vector2(half_width,top),Vector2(half_width,bottom),Vector2(-half_width,bottom)])
			polygon.uv = PackedVector2Array([Vector2(left,0),Vector2(right,0),Vector2(right,texture.get_height()),Vector2(left,texture.get_height())])
			polygon.texture=texture;depth=polygon
		depth.name = "FacadeDepthStrip%03d" % x;depth.texture_filter = body_texture_filter
		depth.material=column_material;depth.set_meta("source_width",end_x-x)
		add_child(depth);depth_columns.append(depth);rendered_source_columns+=end_x-x
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

func set_render_backend(backend: String) -> void:
	if backend not in ["polygon","sprite_regions"]:return
	for column in depth_columns:
		remove_child(column);column.queue_free()
	depth_columns.clear();profile.render_backend=backend;_build_native_columns();set_body_visible(body_enabled);set_selected(selected)
