extends Control
## Clean native presentation. The interactive fixture and production UI are unchanged.
## All movement uses the real renderer/model; optional capture records actual timing.
@export var capture_directory: String = ""
const Stairs = preload("res://scripts/games/chapter4_stairs.gd")
var game: Control
var recording := false
var samples: Array = []
var actions: Array = []
var last_sample := 0
var observed_root := 0

func _ready() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("121b29")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	game = Stairs.new(); game.level_index = 1; add_child(game)
	game.setup({"session":"stair-b-clean-presentation"}); game.visible = false
	var display := TextureRect.new()
	display.texture = game.view3d.get_texture()
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(display)
	RenderingServer.frame_pre_draw.connect(_prepare_visible_frame)
	_run.call_deferred()

func _process(_delta: float) -> void:
	_prepare_visible_frame()

func _prepare_visible_frame() -> void:
	# A level can be rebuilt by a tween after _process, immediately before draw.
	if is_instance_valid(game) and is_instance_valid(game.root3d) and game.root3d.get_instance_id() != observed_root:
		observed_root = game.root3d.get_instance_id()
		_hide_markers(game.root3d)

func _hide_markers(node: Node) -> void:
	# Only the source navigation dots; foliage uses a different source radius.
	if node is MeshInstance3D and node.mesh is SphereMesh and is_equal_approx(node.mesh.radius, 0.1): node.visible = false
	for child in node.get_children(): _hide_markers(child)

func _settle() -> void:
	while game.busy: await get_tree().process_frame

func _capture() -> void:
	while recording:
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_msec()
		if now - last_sample >= 65:
			last_sample = now
			var filename := "%05d.png" % samples.size()
			game.view3d.get_texture().get_image().save_png(capture_directory.path_join(filename))
			samples.append({"file":filename,"ticks_ms":now})

func _action(value: Dictionary) -> void:
	actions.append({"ticks_ms":Time.get_ticks_msec(),"action":value})
	if value.type == "step": game._step(value.id,value.delta)
	elif value.type == "view": game._change_view(value.value)
	else: game._walk(value.node)
	await _settle()
	await get_tree().create_timer(0.35).timeout

func _run() -> void:
	await _settle()
	await get_tree().create_timer(0.5).timeout
	if not capture_directory.is_empty():
		DirAccess.make_dir_recursive_absolute(capture_directory)
		recording = true; _capture()
	# The failed initial move demonstrates that visual presentation adds no route.
	game._walk("B_MID_LIFT_LOW")
	assert(game.state.node == "B_START")
	await get_tree().create_timer(1.2).timeout
	var route: Array = [
		{"type":"step","id":"b_lower_stair","delta":-1},
		{"type":"step","id":"b_lower_stair","delta":-1},
		{"type":"view","value":"south_west"},
		{"type":"walk","node":"B_MID_LIFT_LOW"},
		{"type":"view","value":"south_east"},
		{"type":"view","value":"south_west"},
		{"type":"step","id":"b_mid_lift","delta":1},
		{"type":"step","id":"b_mid_lift","delta":1},
		{"type":"walk","node":"B_UPPER_HIGH"},
		{"type":"step","id":"b_upper_stair","delta":1},
		{"type":"view","value":"top_oblique"},
		{"type":"walk","node":"B_HIGH_ISLAND"},
		{"type":"step","id":"b_exit_slide","delta":1},
		{"type":"step","id":"b_exit_slide","delta":1},
		{"type":"walk","node":"B_EXIT"},
	]
	for action in route: await _action(action)
	# Keep the authored dismantle/reveal transition and its timings untouched.
	assert(game.level.id == "stair_c" and game.campaign.size() == 1)
	await get_tree().create_timer(1.0).timeout
	recording = false
	if not capture_directory.is_empty():
		var file := FileAccess.open(capture_directory.path_join("capture.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"method":"actual Godot renderer; automated actions; native timings; no text UI","samples":samples,"actions":actions,"result_level":game.level.id,"campaign":game.campaign},"  "))
		file.close()
	print("CLEAN_STAIR_PRESENTATION_COMPLETE ",samples.size()," frames; actual target=",game.level.id)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): get_tree().quit()
