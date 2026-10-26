extends Node3D
## Presentation only. This scene must never import State or call a story router.

signal ended(reason: String)

const Timeline = preload("res://timeline.gd")
@export var autoplay := true
var playhead := 0.0
var running := false
var paused := false
var reduced_motion := false
var _completion_sent := false
var _tween: Tween
var _generation := 0
var _camera: Camera3D
var _actor: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _shadow: MeshInstance3D
var _actor_materials: Array[StandardMaterial3D] = []
var _phase: Label
var _pause_button: Button
var _progress: ProgressBar
var _font: Font

func _ready() -> void:
	_font = load("res://generated/MorningNote-Regular.ttf") if ResourceLoader.exists("res://generated/MorningNote-Regular.ttf") else ThemeDB.fallback_font
	_build_world()
	_build_phone()
	_build_actor()
	_build_overlay()
	set_time(0.0)
	if autoplay:
		play()

func play() -> void:
	_stop_tween()
	_completion_sent = false
	paused = false
	running = true
	if reduced_motion:
		_finish("reduced_motion")
		return
	set_time(0.0)
	_tween = create_tween()
	_tween.tween_method(set_time, 0.0, Timeline.DURATION, Timeline.DURATION)
	var generation := _generation
	_tween.finished.connect(func():
		if generation == _generation:
			_finish("completed")
	)
	_refresh_controls()

func skip() -> void:
	if not _completion_sent:
		_finish("skipped")

func cancel() -> void:
	var was_active := running
	_stop_tween()
	running = false
	paused = false
	_refresh_controls()
	if was_active and not _completion_sent:
		_completion_sent = true
		ended.emit("cancelled")

func set_paused(value: bool) -> void:
	if not running or not is_instance_valid(_tween):
		return
	paused = value
	if value:
		_tween.pause()
	else:
		_tween.play()
	_refresh_controls()

func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	if value:
		if running:
			_finish("reduced_motion")
		else:
			set_time(Timeline.DURATION)
	else:
		# Keep the settled frame. Only Replay starts a fresh motion sequence.
		set_time(playhead)
	_refresh_controls()

func set_time(value: float) -> void:
	playhead = clampf(value, 0.0, Timeline.DURATION)
	var pose := Timeline.sample(playhead, reduced_motion)
	_actor.position = pose.position
	_actor.rotation = pose.rotation
	_actor.scale = pose.scale
	_left_leg.rotation.x = pose.stride
	_right_leg.rotation.x = -pose.stride
	_left_arm.rotation = Vector3(-pose.stride * 0.7, 0.0, pose.arms)
	_right_arm.rotation = Vector3(pose.stride * 0.7, 0.0, -pose.arms)
	for material in _actor_materials:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if pose.flat else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	_camera.position = pose.camera_position
	_camera.look_at(pose.camera_target, Vector3.UP)
	_shadow.position = Vector3(pose.position.x, 0.081, pose.position.z)
	_shadow.visible = playhead >= 3.6 or reduced_motion
	var spread := 1.0 + maxf(0.0, pose.position.y - 0.08) * 0.45
	_shadow.scale = Vector3(spread, 1.0, spread)
	_phase.text = pose.phase_name
	_progress.value = pose.time

func _finish(reason: String) -> void:
	_stop_tween()
	running = false
	paused = false
	set_time(Timeline.DURATION)
	_refresh_controls()
	if not _completion_sent:
		_completion_sent = true
		ended.emit(reason)

func _stop_tween() -> void:
	_generation += 1
	if is_instance_valid(_tween):
		_tween.kill()
	_tween = null

func _exit_tree() -> void:
	_stop_tween()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		set_paused(true)

func _input(event: InputEvent) -> void:
	# Handle explicit preview shortcuts before focused Buttons consume Space as ui_accept.
	# Enter remains the normal keyboard activation key for focused controls.
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_R: play()
		KEY_SPACE: set_paused(not paused)
		KEY_ESCAPE: skip()
		_: return
	get_viewport().set_input_as_handled()

func _refresh_controls() -> void:
	if not is_instance_valid(_pause_button):
		return
	_pause_button.disabled = not running
	_pause_button.text = "继续 / Space" if paused else "暂停 / Space"

func _material(color: Color, roughness := 0.72) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _mesh(parent: Node, shape: Mesh, position: Vector3, material: Material, label: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = shape
	instance.material_override = material
	instance.position = position
	parent.add_child(instance)
	return instance

func _box(parent: Node, size: Vector3, position: Vector3, material: Material, label: String) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(parent, mesh, position, material, label)

func _sphere(parent: Node, radius: float, position: Vector3, material: Material, label: String) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 24
	mesh.rings = 12
	return _mesh(parent, mesh, position, material, label)

func _capsule(parent: Node, radius: float, height: float, position: Vector3, material: Material, label: String) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 8
	return _mesh(parent, mesh, position, material, label)

func _build_world() -> void:
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("d8dbd0")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("b8cad2")
	environment.environment.ambient_light_energy = 0.65
	add_child(environment)
	# Compatibility-safe lighting: no DOF, motion blur, SDFGI, SSAO, or compositor.
	var key := DirectionalLight3D.new()
	key.name = "LowWarmKey"
	key.rotation_degrees = Vector3(-32.0, -42.0, 0.0)
	key.light_color = Color("fff0d1")
	key.light_energy = 1.25
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 30.0
	add_child(key)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-3.0, 4.0, 2.0)
	fill.light_color = Color("d6e9f3")
	fill.light_energy = 0.8
	fill.omni_range = 15.0
	add_child(fill)
	_camera = Camera3D.new()
	_camera.name = "ContinuousCamera"
	_camera.fov = 42.0
	_camera.near = 0.05
	_camera.far = 60.0
	add_child(_camera)
	_camera.make_current()
	_box(self, Vector3(24.0, 0.12, 24.0), Vector3(0.0, -0.06, -2.0), _material(Color("d3c7ab")), "Desk")
	_box(self, Vector3(7.1, 0.12, 6.2), Vector3(0.0, 0.0, -4.7), _material(Color("abbc9b")), "ModelCampusPlinth")
	_box(self, Vector3(1.45, 0.016, 6.8), Vector3(0.0, 0.07, -3.2), _material(Color("e8ddbc")), "MiniaturePath")
	var wall := _material(Color("edddbb"))
	var roof := _material(Color("a36355"))
	var glass := _material(Color("597878"), 0.4)
	for side in [-1.0, 1.0]:
		var x: float = side * 2.15
		_box(self, Vector3(1.8, 1.8, 2.1), Vector3(x, 0.96, -5.2), wall, "AbstractCampusBuilding")
		_box(self, Vector3(2.0, 0.16, 2.3), Vector3(x, 1.92, -5.2), roof, "Roof")
		for row in [0.0, 1.0]:
			for col in [-1.0, 0.0, 1.0]:
				_box(self, Vector3(0.29, 0.4, 0.03), Vector3(x + col * 0.5, 0.62 + row * 0.7, -4.135), glass, "Window")
	_box(self, Vector3(0.22, 1.4, 0.22), Vector3(-0.95, 0.76, -4.6), wall, "GateLeft")
	_box(self, Vector3(0.22, 1.4, 0.22), Vector3(0.95, 0.76, -4.6), wall, "GateRight")
	_box(self, Vector3(2.2, 0.22, 0.35), Vector3(0.0, 1.51, -4.6), roof, "GateLintel")
	for item in [Vector3(-2.1, 0.0, -2.6), Vector3(2.5, 0.0, -2.7), Vector3(-3.0, 0.0, -6.7), Vector3(2.5, 0.0, -7.0)]:
		_capsule(self, 0.09, 0.65, item + Vector3(0.0, 0.37, 0.0), _material(Color("886c50")), "TreeTrunk")
		_sphere(self, 0.47, item + Vector3(0.0, 0.97, 0.0), _material(Color("7d9977")), "ToyTree")
	# Broad translucent contact gradient works on Compatibility without post-processing.
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0.16, 0.20, 0.17, 0.24), Color(0.16, 0.20, 0.17, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 64
	texture.height = 64
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var shadow_mat := _material(Color.WHITE)
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_mat.albedo_texture = texture
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.9, 0.65)
	_shadow = _mesh(self, plane, Vector3.ZERO, shadow_mat, "SoftContactShadow")
	_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _build_phone() -> void:
	_box(self, Vector3(2.35, 0.24, 4.55), Vector3(0.0, 0.12, 1.6), _material(Color("283e43"), 0.4), "PhoneBody")
	var viewport := SubViewport.new()
	viewport.name = "PhoneUI430x860"
	viewport.size = Vector2i(430, 860)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.disable_3d = true
	add_child(viewport)
	var paper := ColorRect.new()
	paper.color = Color("eff1df")
	paper.size = Vector2(430, 860)
	viewport.add_child(paper)
	_phone_label(paper, "7:55", Vector2(30, 32), Vector2(370, 60), 38)
	_phone_label(paper, "浙大钉  /  校园地图", Vector2(30, 124), Vector2(370, 40), 25)
	_phone_label(paper, "转场构图试验 · 非实际应用页面", Vector2(30, 174), Vector2(370, 35), 17)
	var card := Panel.new()
	card.position = Vector2(30, 248)
	card.size = Vector2(370, 370)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("d9e2d2")
	style.set_corner_radius_all(24)
	card.add_theme_stylebox_override("panel", style)
	paper.add_child(card)
	_phone_label(paper, "屏幕里的你", Vector2(30, 640), Vector2(370, 40), 24)
	_phone_label(paper, "从平面出发", Vector2(30, 704), Vector2(370, 36), 18)
	var bar := ColorRect.new()
	bar.color = Color("314d50")
	bar.position = Vector2(155, 822)
	bar.size = Vector2(120, 6)
	paper.add_child(bar)
	var material := _material(Color.WHITE)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = viewport.get_texture()
	var screen := PlaneMesh.new()
	screen.size = Vector2(2.15, 4.3)
	_mesh(self, screen, Vector3(0.0, 0.245, 1.6), material, "PhoneScreen")

func _phone_label(parent: Node, text: String, position: Vector2, size: Vector2, font_size: int) -> void:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = size
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("294248"))
	parent.add_child(label)

func _build_actor() -> void:
	_actor = Node3D.new()
	_actor.name = "PlaceholderToyStudent"
	add_child(_actor)
	var skin := _material(Color("eac9a1"), 0.55)
	var shirt := _material(Color("a95144"), 0.68)
	var trousers := _material(Color("344f60"), 0.72)
	var dark := _material(Color("293b3d"), 0.55)
	var pack := _material(Color("e4b658"), 0.78)
	_actor_materials.assign([skin, shirt, trousers, dark, pack])
	_capsule(_actor, 0.22, 0.48, Vector3(0.0, 0.64, 0.0), shirt, "Torso")
	_sphere(_actor, 0.235, Vector3(0.0, 1.02, 0.0), skin, "Head")
	var hair := _sphere(_actor, 0.242, Vector3(0.0, 1.10, -0.018), dark, "Hair")
	hair.scale = Vector3(1.0, 0.56, 1.0)
	for x in [-0.075, 0.075]:
		_sphere(_actor, 0.025, Vector3(x, 1.035, 0.215), dark, "Eye")
	_box(_actor, Vector3(0.31, 0.35, 0.15), Vector3(0.0, 0.65, -0.24), pack, "Backpack")
	_left_arm = _limb(Vector3(-0.255, 0.79, 0.0), 0.075, 0.30, shirt, skin, "LeftArm")
	_right_arm = _limb(Vector3(0.255, 0.79, 0.0), 0.075, 0.30, shirt, skin, "RightArm")
	_left_leg = _limb(Vector3(-0.105, 0.40, 0.0), 0.085, 0.31, trousers, dark, "LeftLeg")
	_right_leg = _limb(Vector3(0.105, 0.40, 0.0), 0.085, 0.31, trousers, dark, "RightLeg")

func _limb(position: Vector3, radius: float, length: float, material: Material, end_material: Material, label: String) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = label
	pivot.position = position
	_actor.add_child(pivot)
	_capsule(pivot, radius, length, Vector3(0.0, -length * 0.5, 0.0), material, "Segment")
	_sphere(pivot, radius * 1.05, Vector3(0.0, -length, 0.025), end_material, "End")
	return pivot

func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "ReadableControlsOutside3D"
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var theme := Theme.new()
	theme.default_font = _font
	theme.default_font_size = 20
	root.theme = theme
	var top := PanelContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 20
	top.offset_right = -20
	top.offset_top = 20
	root.add_child(top)
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.12, 0.20, 0.22, 0.94)
	top_style.content_margin_left = 16
	top_style.content_margin_right = 16
	top_style.content_margin_top = 12
	top_style.content_margin_bottom = 12
	top_style.set_corner_radius_all(12)
	top.add_theme_stylebox_override("panel", top_style)
	var column := VBoxContainer.new()
	top.add_child(column)
	var title := Label.new()
	title.text = "7:55  /  手机走进校园"
	column.add_child(title)
	var note := Label.new()
	note.text = "概念试镜：小人与校园均为占位模型，不代表真实校貌。"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 16)
	column.add_child(note)
	var bottom := PanelContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 20
	bottom.offset_right = -20
	bottom.offset_top = -164
	bottom.offset_bottom = -20
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom.add_theme_stylebox_override("panel", top_style)
	root.add_child(bottom)
	var controls := VBoxContainer.new()
	bottom.add_child(controls)
	_phase = Label.new()
	controls.add_child(_phase)
	_progress = ProgressBar.new()
	_progress.max_value = Timeline.DURATION
	_progress.show_percentage = false
	_progress.custom_minimum_size.y = 7
	controls.add_child(_progress)
	var buttons := HFlowContainer.new()
	buttons.add_theme_constant_override("h_separation", 10)
	controls.add_child(buttons)
	_button(buttons, "重播 / R", play)
	_pause_button = _button(buttons, "暂停 / Space", func(): set_paused(not paused))
	_button(buttons, "跳过 / Esc", skip)
	var reduced := CheckButton.new()
	reduced.text = "减弱动态"
	reduced.custom_minimum_size = Vector2(146, 44)
	reduced.toggled.connect(set_reduced_motion)
	buttons.add_child(reduced)

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(140, 44)
	button.pressed.connect(action)
	parent.add_child(button)
	return button
