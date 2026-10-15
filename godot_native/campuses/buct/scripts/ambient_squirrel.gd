extends Node2D
## One visual-only, feet-anchored ambient actor. Navigation is queried, never changed.
## Run poses follow actual displacement. Idle poses never advance a run cycle.

const MAX_DELTA := 0.1
const SAMPLE_STEP := 0.5
const MAX_ROUTE_LENGTH := 48.0
const PHASES := ["idle", "peek", "idle", "tail", "idle", "run"]
const SHADOW_OFFSET := Vector2(0, 0.10)
# Transform radii and alpha. Godot's radius-one antialias fringe is also scaled,
# so these nominal 2x0.5px ellipses produce a measured <=4x1px visible footprint.
const SHADOW_LAYERS := [Vector3(1.0, 0.25, 0.035), Vector3(0.7, 0.175, 0.045), Vector3(0.4, 0.10, 0.055)]
const SHADOW_MAX_VISIBLE_SOURCE_SIZE := Vector2(4.0, 1.0)

var sprite: Sprite2D
var visibility_notifier: VisibleOnScreenNotifier2D
var profile: Dictionary = {}
var route := PackedVector2Array()
var registered: Array[Dictionary] = []
var legal_point: Callable
var configured := false
var on_screen := false
var app_focused := true
var phase_index := 0
var phase_elapsed := 0.0
var distance_phase := 0.0
var distance_travelled := 0.0
var target_index := 1
var facing_left := false
var current_frame := -1
var run_count := 0
var blocked := false
var contact_shadow_enabled := true

func configure(data: Dictionary, atlas: Texture2D, validator: Callable) -> bool:
	# Reconfiguration is deliberately forbidden: scene re-entry creates one new node.
	if configured or atlas == null or not validator.is_valid(): return false
	if not _valid_profile(data, atlas.get_size()): return false
	var candidate_route := PackedVector2Array()
	for point in data.route_source_xy: candidate_route.append(Vector2(point[0], point[1]))
	if candidate_route.size() != 2: return false
	if not is_equal_approx(candidate_route[0].y, candidate_route[1].y): return false
	var length := candidate_route[0].distance_to(candidate_route[1])
	if length < 4.0 or length > MAX_ROUTE_LENGTH: return false
	for i in range(ceili(length / SAMPLE_STEP) + 1):
		if not validator.call(candidate_route[0].lerp(candidate_route[1], minf(1.0, i * SAMPLE_STEP / length))): return false
	profile = data.duplicate(true)
	route = candidate_route
	legal_point = validator
	var uniform_scale := float(profile.display_height_source_px) / float(profile.reference_height_pixels)
	for frame in profile.frames:
		var region := Rect2(frame.region[0], frame.region[1], frame.region[2], frame.region[3])
		var texture := AtlasTexture.new()
		texture.atlas = atlas
		texture.region = region
		texture.filter_clip = true
		registered.append({"texture": texture, "foot": Vector2(frame.foot[0], frame.foot[1]), "width": region.size.x})
	sprite = Sprite2D.new()
	sprite.name = "RegisteredSquirrelArtwork"
	sprite.centered = false
	sprite.scale = Vector2.ONE * uniform_scale
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){vec4 c=texture(TEXTURE,UV); if(c.a<0.04){discard;} COLOR=c;}"
	var material := ShaderMaterial.new()
	material.shader = shader
	sprite.material = material
	add_child(sprite)
	visibility_notifier = VisibleOnScreenNotifier2D.new()
	visibility_notifier.name = "BoundedVisibility"
	visibility_notifier.rect = Rect2(-12, -12, 24, 16)
	visibility_notifier.screen_entered.connect(set_on_screen.bind(true))
	visibility_notifier.screen_exited.connect(set_on_screen.bind(false))
	add_child(visibility_notifier)
	# The parent is the existing y-sorted object container. This node's Y is its feet.
	z_index = 0
	position = route[0]
	facing_left = route[1].x < route[0].x
	configured = true
	queue_redraw()
	_apply_frame(int(profile.poses.idle[0]))
	_refresh_processing()
	return true

func _valid_profile(data: Dictionary, atlas_size: Vector2) -> bool:
	if int(data.get("version", 0)) != 1: return false
	if float(data.get("display_height_source_px", 0)) <= 0 or float(data.get("display_height_source_px", 99)) > 10.0: return false
	if float(data.get("reference_height_pixels", 0)) <= 0: return false
	if float(data.get("speed_source_px_per_second", 0)) <= 0 or float(data.get("speed_source_px_per_second", 99)) > 32.0: return false
	if float(data.get("stride_source_px", 0)) <= 0: return false
	if data.get("route_source_xy", []).size() != 2 or data.get("phase_seconds", []).size() != PHASES.size() - 1: return false
	for point in data.route_source_xy:
		if point.size() != 2: return false
	for duration in data.phase_seconds:
		if float(duration) <= 0: return false
	if data.get("rest_seconds_by_visit", []).is_empty(): return false
	for duration in data.rest_seconds_by_visit:
		if float(duration) < 8.0: return false
	var frames: Array = data.get("frames", [])
	if frames.size() != 8: return false
	for frame in frames:
		var r: Array = frame.get("region", [])
		var f: Array = frame.get("foot", [])
		if r.size() != 4 or f.size() != 2: return false
		var region := Rect2(r[0], r[1], r[2], r[3])
		if region.size.x <= 0 or region.size.y <= 0 or not Rect2(Vector2.ZERO, atlas_size).encloses(region): return false
		if f[0] < 0 or f[0] > region.size.x or f[1] < 0 or f[1] > region.size.y: return false
	var poses: Dictionary = data.get("poses", {})
	for pose in ["idle", "peek", "tail", "run"]:
		if poses.get(pose, []).is_empty(): return false
		for index in poses[pose]:
			if int(index) < 0 or int(index) >= frames.size(): return false
	if poses.run.size() != 4 or poses.tail.size() < 2: return false
	# This contract prevents an accidental duplicated-index cycle. Art distinctness
	# is a separate, source-image review and must never be inferred from this check.
	var unique: Dictionary = {}
	for index in poses.run: unique[int(index)] = true
	return unique.size() == 4

func _ready() -> void:
	_refresh_processing()

func _draw() -> void:
	# These CanvasItem draw commands are cached. Movement only changes the parent
	# transform; the shadow has no node, texture, collision or per-frame geometry.
	if not configured or not contact_shadow_enabled: return
	for layer in SHADOW_LAYERS:
		draw_set_transform(SHADOW_OFFSET, 0.0, Vector2(layer.x, layer.y))
		draw_circle(Vector2.ZERO, 1.0, Color(0.25, 0.22, 0.18, layer.z), true, -1.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func set_contact_shadow_enabled(value: bool) -> void:
	# Diagnostic-only comparison switch; production has no interaction for it.
	if contact_shadow_enabled == value: return
	contact_shadow_enabled = value
	queue_redraw()

func set_on_screen(value: bool) -> void:
	on_screen = value
	if not value and configured: _apply_frame(int(profile.poses.idle[0]))
	_refresh_processing()

func set_app_focused(value: bool) -> void:
	app_focused = value
	if not value and configured: _apply_frame(int(profile.poses.idle[0]))
	_refresh_processing()

func _refresh_processing() -> void:
	set_process(configured and on_screen and app_focused and not blocked)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		set_app_focused(false)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		set_app_focused(true)

func _process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	# No catch-up after a hidden window, camera departure, or a long frame.
	if not configured or not on_screen or not app_focused or blocked or delta <= 0.0: return
	var remaining := minf(delta, MAX_DELTA)
	var boundaries := 0
	while remaining > 0.000001 and boundaries < 8:
		if PHASES[phase_index] == "run":
			var to_target := position.distance_to(route[target_index])
			var distance := minf(to_target, float(profile.speed_source_px_per_second) * remaining)
			var candidate := position.move_toward(route[target_index], distance)
			if not _segment_is_legal(position, candidate):
				blocked = true
				_apply_frame(int(profile.poses.idle[0]))
				_refresh_processing()
				return
			var actual := position.distance_to(candidate)
			position = candidate
			distance_travelled += actual
			distance_phase = fposmod(distance_phase + actual / float(profile.stride_source_px), 1.0)
			remaining -= actual / float(profile.speed_source_px_per_second)
			_apply_pose("run", distance_phase)
			if position.distance_to(route[target_index]) < 0.00001:
				position = route[target_index]
				target_index = 1 - target_index
				run_count += 1
				phase_index = 0
				phase_elapsed = 0.0
				distance_phase = 0.0
				_apply_frame(int(profile.poses.idle[0]))
				boundaries += 1
			else:
				return
		else:
			var duration := _phase_duration()
			var used := minf(remaining, duration - phase_elapsed)
			phase_elapsed += used
			remaining -= used
			_apply_pose(str(PHASES[phase_index]), phase_elapsed / duration)
			if phase_elapsed >= duration - 0.000001:
				phase_index += 1
				phase_elapsed = 0.0
				boundaries += 1
				if PHASES[phase_index] == "run":
					facing_left = route[target_index].x < position.x
					distance_phase = 0.0
				_apply_pose(str(PHASES[phase_index]), 0.0)
			else:
				return

func _segment_is_legal(from: Vector2, to: Vector2) -> bool:
	if not legal_point.is_valid(): return false
	var length := from.distance_to(to)
	var steps := maxi(1, ceili(length / SAMPLE_STEP))
	for i in range(steps + 1):
		if not legal_point.call(from.lerp(to, float(i) / steps)): return false
	return true

func _phase_duration() -> float:
	if phase_index == 0:
		var rests: Array = profile.rest_seconds_by_visit
		return float(rests[run_count % rests.size()])
	return float(profile.phase_seconds[phase_index])

func _apply_pose(pose: String, fraction: float) -> void:
	var indices: Array = profile.poses[pose]
	_apply_frame(int(indices[mini(indices.size() - 1, floori(clampf(fraction, 0.0, 0.999999) * indices.size()))]))

func _apply_frame(index: int) -> void:
	current_frame = index
	var frame: Dictionary = registered[index]
	sprite.texture = frame.texture
	sprite.flip_h = facing_left
	var foot: Vector2 = frame.foot
	if facing_left: foot.x = float(frame.width) - foot.x
	sprite.position = -foot * sprite.scale.x

func current_foot_global() -> Vector2:
	if not configured: return global_position
	var frame: Dictionary = registered[current_frame]
	var foot: Vector2 = frame.foot
	if facing_left: foot.x = float(frame.width) - foot.x
	return sprite.to_global(foot)

func snapshot() -> Dictionary:
	return {"position": position, "phase": PHASES[phase_index], "phase_elapsed": phase_elapsed, "frame": current_frame, "distance_phase": distance_phase, "distance_travelled": distance_travelled, "facing_left": facing_left, "run_count": run_count, "blocked": blocked, "on_screen": on_screen, "focused": app_focused}

func _exit_tree() -> void:
	set_process(false)
	configured = false
	legal_point = Callable()
	registered.clear()
	profile.clear()
