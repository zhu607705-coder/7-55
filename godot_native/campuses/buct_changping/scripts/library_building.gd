extends Node2D
## Two real visual faces, one original RGBA and at most eight Y-sort intervals.
## Source preparation only; requires separate native validation.
const BODY_SHADER = preload("res://campuses/buct_changping/shaders/library_depth.gdshader")
const MAX_PASSES := 8
var profile: Dictionary
var body_texture: Texture2D
var depth_texture: ImageTexture
var surface_texture: ImageTexture
var surface_count := 2
var body_passes: Array[Sprite2D] = []
var static_depth_boundaries: Array[float] = []
var actor_foot_y := 10000.0
var source_anchor := Vector2.ZERO
var body_local_origin := Vector2.ZERO
var image_scale := 1.0
var raw_size := Vector2i.ZERO
var alpha_bytes := PackedByteArray()
var column_depths := PackedFloat32Array()
var selected := false
var _active_passes := 0
var _configured := false
var _last_translation := Vector2(INF, INF)
var _raw_min_depth := 0.0
var _raw_max_depth := 0.0

func configure(data: Dictionary, texture: Texture2D) -> bool:
	if _configured or texture == null or not data.has("body_image_to_world"):
		push_error("Compact building requires a fresh node, texture and explicit registration")
		return false
	profile = data.duplicate(true)
	surface_count = int(profile.get("surface_count", 2))
	if surface_count != 2:
		push_error("Library requires the two verified visual face fields")
		return false
	var transform: Dictionary = profile.body_image_to_world
	image_scale = float(transform.scale)
	raw_size = Vector2i(int(transform.raw_size[0]), int(transform.raw_size[1]))
	if image_scale <= 0.0 or texture.get_size() != Vector2(raw_size):
		push_error("Compact building raw texture dimensions differ from registration")
		return false
	source_anchor = Vector2(profile.source_anchor[0], profile.source_anchor[1])
	position = source_anchor
	body_local_origin = Vector2(transform.origin[0], transform.origin[1]) - source_anchor
	body_texture = texture
	var cpu_image: Image = texture.get_image()
	if cpu_image.is_compressed() and cpu_image.decompress() != OK:
		push_error("Cannot read alpha for compact building")
		return false
	cpu_image.convert(Image.FORMAT_RGBA8)
	var rgba: PackedByteArray = cpu_image.get_data()
	alpha_bytes.resize(raw_size.x * raw_size.y)
	for i in range(alpha_bytes.size()): alpha_bytes[i] = rgba[i * 4 + 3]
	# CPU RGB pixels are not retained. Picking keeps alpha only (one byte per raw texel).
	cpu_image = null
	rgba.clear()
	var surface_ids := FileAccess.get_file_as_bytes(str(profile.surface_id_path))
	if surface_ids.size() != raw_size.x * raw_size.y:
		push_error("Library surface field size mismatch")
		return false
	for i in range(alpha_bytes.size()):
		if alpha_bytes[i] > 0 and (surface_ids[i] < 1 or surface_ids[i] > surface_count):
			push_error("Nonzero body alpha is missing a unique visual face")
			return false
	var surface_image := Image.create_from_data(raw_size.x, raw_size.y, false, Image.FORMAT_R8, surface_ids)
	surface_texture = ImageTexture.create_from_image(surface_image)
	surface_image = null
	surface_ids.clear()
	var rows: Array = profile.depth_rows_raw_y
	if rows.size() != surface_count:
		push_error("Library requires two independent raw foot rows")
		return false
	column_depths.resize(raw_size.x * surface_count)
	for row in range(surface_count):
		if rows[row].size() != raw_size.x:
			push_error("Library raw foot row width mismatch")
			return false
		for x in range(raw_size.x):
			var depth := float(rows[row][x])
			if not is_finite(depth):
				push_error("Library foot values must be finite")
				return false
			column_depths[row * raw_size.x + x] = depth
	_raw_min_depth = column_depths[0]
	_raw_max_depth = column_depths[0]
	for value in column_depths:
		_raw_min_depth = minf(_raw_min_depth, value)
		_raw_max_depth = maxf(_raw_max_depth, value)
	var depth_image := Image.create_from_data(raw_size.x, surface_count, false, Image.FORMAT_RF, column_depths.to_byte_array())
	depth_texture = ImageTexture.create_from_image(depth_image)
	y_sort_enabled = true
	# Static overlap boundaries are explicit scene data, never all-campus objects.
	for value in profile.get("static_overlap_foot_y", []): static_depth_boundaries.append(float(value))
	if static_depth_boundaries.size() + 2 > MAX_PASSES:
		push_error("Compact building exceeds its explicit depth-pass budget")
		return false
	for i in range(static_depth_boundaries.size() + 2):
		var sprite := Sprite2D.new()
		sprite.name = "ExactFootInterval%d" % i
		sprite.centered = false
		sprite.texture = body_texture
		sprite.scale = Vector2.ONE * image_scale
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var material := ShaderMaterial.new()
		material.shader = BODY_SHADER
		material.set_shader_parameter("foot_depth", depth_texture)
		material.set_shader_parameter("surface_ids", surface_texture)
		material.set_shader_parameter("raw_size", Vector2(raw_size))
		material.set_shader_parameter("surface_count", surface_count)
		material.set_shader_parameter("world_scale", image_scale)
		material.set_shader_parameter("alpha_cutoff", float(profile.get("alpha_cutoff", 0.05)))
		material.set_shader_parameter("solid_threshold", float(profile.get("solid_alpha_threshold", 0.95)))
		sprite.material = material
		add_child(sprite)
		body_passes.append(sprite)
	# The two original #126 StaticBody2D children remain in their existing node.
	_configured = true
	update_actor_foot(actor_foot_y, true)
	return true

func update_actor_foot(world_y: float, force := false) -> void:
	if not _configured: return
	var translation := global_position - source_anchor
	if not force and is_equal_approx(actor_foot_y, world_y) and translation == _last_translation: return
	actor_foot_y = world_y
	_last_translation = translation
	var boundaries: Array[float] = static_depth_boundaries.duplicate()
	boundaries.append(world_y)
	boundaries.sort()
	var unique: Array[float] = []
	for value in boundaries:
		if unique.is_empty() or absf(value - unique[-1]) > 0.00001: unique.append(value)
	var world_origin_y := global_position.y + body_local_origin.y
	var min_depth := _raw_min_depth * image_scale + world_origin_y
	var max_depth := _raw_max_depth * image_scale + world_origin_y
	var cuts: Array[float] = [min_depth - 1.0]
	for value in unique:
		if value >= min_depth and value < max_depth: cuts.append(value)
	cuts.append(max_depth + 1.0)
	_active_passes = cuts.size() - 1
	for i in range(body_passes.size()):
		var sprite := body_passes[i]
		sprite.visible = i < _active_passes
		if not sprite.visible: continue
		var low := cuts[i]
		var high := cuts[i + 1]
		var anchor_y := (low + high) * 0.5
		sprite.position = Vector2(0.0, anchor_y - global_position.y)
		sprite.offset = Vector2(body_local_origin.x / image_scale, (world_origin_y - anchor_y) / image_scale)
		var material: ShaderMaterial = sprite.material
		material.set_shader_parameter("world_origin_y", world_origin_y)
		material.set_shader_parameter("depth_lower", low)
		material.set_shader_parameter("depth_upper", high)

func hit_test_alpha(world_point: Vector2) -> bool:
	if not _configured or not is_visible_in_tree(): return false
	var p := (to_local(world_point) - body_local_origin) / image_scale
	if p.x < 0.0 or p.y < 0.0 or p.x >= raw_size.x or p.y >= raw_size.y: return false
	# Reproduce LINEAR LOD0 alpha sampling, without retaining full RGB Image.
	p -= Vector2(0.5, 0.5)
	var cell := Vector2i(floori(p.x), floori(p.y))
	var f := p - Vector2(cell)
	var a0 := lerpf(_alpha_at(cell.x, cell.y), _alpha_at(cell.x + 1, cell.y), f.x)
	var a1 := lerpf(_alpha_at(cell.x, cell.y + 1), _alpha_at(cell.x + 1, cell.y + 1), f.x)
	return lerpf(a0, a1, f.y) >= float(profile.get("alpha_cutoff", 0.05))

func _alpha_at(x: int, y: int) -> float:
	return float(alpha_bytes[clampi(y, 0, raw_size.y - 1) * raw_size.x + clampi(x, 0, raw_size.x - 1)]) / 255.0

func set_selected(value: bool) -> void:
	selected = value
	for sprite in body_passes: sprite.material.set_shader_parameter("selected", value)

func get_diagnostics() -> Dictionary:
	return {"body_passes_allocated": body_passes.size(), "body_passes_active": _active_passes,
		"cpu_alpha_bytes": alpha_bytes.size(), "depth_texture_bytes": raw_size.x * surface_count * 4,
		"surface_texture_bytes": raw_size.x * raw_size.y, "surface_count": surface_count,
		"production_has_mipmaps": body_texture.get_image().has_mipmaps(),
		"raw_texture_size": raw_size, "uniform_scale": image_scale,
		"player_hide_move_enabled": false, "status": "two_face_candidate_pending_native_proof"}
