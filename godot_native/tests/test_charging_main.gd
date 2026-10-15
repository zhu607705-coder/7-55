extends SceneTree
## Real Main ownership, responsive geometry, inventory and phone interruptions.
const Effect = preload("res://scripts/media/c3_charging.gd")
var checks := 0
var failures := 0
var state: Node
var shell: Control
func _initialize() -> void: run.call_deferred()
func frames(count := 4) -> void:
	for i in count: await process_frame
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func press(code: Key) -> void:
	for down in [true, false]:
		var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = down
		root.push_input(event, true); await frames(1)
	await frames()
func fixture() -> void:
	state.d = state.initial(); state.developer_mode = true
	state.d.native.chapter = 3; state.d.native.page = "c3_theater"; state.d.native.scene = "theater_interior"; state.d.native.mode = "light"
	state.d.native.player = {"x": 665.0, "y": 790.0, "scene": "theater_interior"}
	state.d.native.settings.music = false; state.d.native.settings.effects = false
	state.d.runtimeMode = "rpg"; state.d.rpgScene = "theater_interior"; state.d.theaterHunt.active = true
	state.d.theaterHunt.phase = "program_search"; state.d.phoneBattery.percent = 7
	state.d.actOne.phase = "complete"; state.d.actOne.movementEnabled = true
	state.d.items.campusCard = true; state.d.ui.inventoryRecovered = true
func close_shell() -> void:
	if is_instance_valid(shell): await shell.shutdown(); shell.queue_free(); await frames()
var capture_stages: Dictionary = {}
func manual_capture() -> void:
	if not is_instance_valid(shell) or not is_instance_valid(shell.world_effect): return
	var owner: Control = shell.world_effect
	if not is_instance_valid(owner) or not owner is Effect: return
	var stage := ""
	if owner.terminal == "success": stage = "success"
	elif owner.terminal == "cancelled": stage = "cancelled"
	elif owner.session.elapsed_ms > 700 and owner.session.elapsed_ms < 1900: stage = "current"
	if stage.is_empty() or capture_stages.has(stage): return
	capture_stages[stage] = true
	await RenderingServer.frame_post_draw
	var path := "user://charging-" + stage + ".png"
	root.get_texture().get_image().save_png(path)
	print("CHARGING_VISIBLE_FRAME ", stage, " battery=", state.d.phoneBattery.percent, " receipt=", owner.session.phase if is_instance_valid(owner) else "retired", " file=", ProjectSettings.globalize_path(path))
func manual_fixture() -> void:
	fixture()
	root.size = Vector2i(390, 844) if OS.get_cmdline_user_args().has("--portrait") else Vector2i(1180, 812)
	root.title = "7:55 Charging feedback - isolated QA"
	shell = load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(6)
	shell._show_world_mobile(); await frames()
	shell.world.player = Vector2(665, 790); shell.world._sync_player(); shell.world._update_camera(); shell.world.grab_focus()
	process_frame.connect(manual_capture)
	root.window_input.connect(_manual_input)
	print("CHARGING_MANUAL_READY battery=7; Space uses the real station; P opens phone; F8 resets this isolated battery fixture")
func _manual_input(event: InputEvent) -> void:
	if OS.get_cmdline_user_args().has("--manual") and event is InputEventKey and event.pressed and event.keycode == KEY_F8:
		shell._cancel_world_effect(); capture_stages.clear(); state.d.phoneBattery.percent = 7; state.d.phoneBattery.rechargeCount = 0
		shell.world.player = Vector2(665, 790); shell.world._sync_player(); shell.world._update_camera(); state.changed.emit()
func run() -> void:
	state = root.get_node("State"); state.developer_mode = true
	if OS.get_cmdline_user_args().has("--manual"): await manual_fixture(); return
	create_timer(40).timeout.connect(func(): push_error("Charging main watchdog"); quit(2))
	for dimensions: Vector2i in [Vector2i(390, 844), Vector2i(844, 390), Vector2i(1180, 812)]:
		await close_shell(); root.size = dimensions; fixture()
		shell = load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(6)
		shell._show_world_mobile(); await frames()
		shell.world.player = Vector2(665, 790); shell.world._sync_player(); shell.world._update_camera()
		check(shell.world_frame.visible and not shell.phone.visible, "charging fixture begins on live world")
		state.act("c3_target:theater_charging_station"); await frames()
		var effect: Control = shell.world_effect
		check(is_instance_valid(effect) and effect is Effect, "real source controller opens the charging component")
		if not is_instance_valid(effect): continue
		check(effect.get_parent() == shell.world and not effect.get_meta("blocks_input", false), "one world-local effect leaves movement enabled")
		check(not shell._authored_world_contract() and shell.world.mobile_exploration == (dimensions.x < 1100), "charging does not force the960x540 cinematic contract")
		check(effect.mouse_filter == Control.MOUSE_FILTER_IGNORE and shell.world_frame.visible and not shell.phone.visible, "charging has no modal or global phone shell")
		check(Rect2(Vector2.ZERO, shell.world.size).encloses(effect.view.panel_rect), "readable phone inset stays inside current world")
		var original: Vector2 = shell.world.player
		shell.compact_inventory_open = true; shell._layout(); await frames()
		check(shell.inventory_dock.visible and is_instance_valid(effect) and effect.session.phase == "charging", "inventory opens without replacing or cancelling the station")
		check(Rect2(Vector2.ZERO, shell.world.size).encloses(effect.view.panel_rect), "inventory-reserved layout contains charging inset")
		root.size = Vector2i(430, 860); shell.size = Vector2(430, 860); shell._layout(); await frames()
		check(effect.session.phase == "charging" and shell.world.player == original, "rotation preserves live session and player")
		check(shell.world.size.x > 350 and shell.world.mobile_exploration, "portrait resize retains real exploration pixels")
		check(Rect2(Vector2.ZERO, shell.world.size).encloses(effect.view.panel_rect), "rotated inset remains contained")
		await press(KEY_P)
		check(shell.phone.visible and not shell.world_frame.visible, "P can open the real phone during nonmodal charging")
		check(not is_instance_valid(effect) and state.d.phoneBattery.percent == 7 and state.d.phoneBattery.rechargeCount == 0, "opening phone cancels and removes all charging feedback")
		await press(KEY_ESCAPE)
		check(shell.world_frame.visible and shell.world.has_focus(), "phone return restores original world focus")
		state.d.native.page = "c3_theater"; state.act("c3_target:theater_charging_station"); await frames()
		effect = shell.world_effect
		check(is_instance_valid(effect), "station can start a clean new session after cancellation")
		if is_instance_valid(effect):
			shell._show_settings(); await frames()
			check(not is_instance_valid(effect) and state.d.phoneBattery.percent == 7, "opening a real settings modal retires the cable without gain")
			shell._close_modal(); await frames()
	# One real Main completion checks the synchronous State callback and its tail.
	state.act("c3_target:theater_charging_station"); await frames()
	var completed_effect: Control = shell.world_effect
	check(is_instance_valid(completed_effect), "real Main can start the final accepted transaction")
	var completion_deadline := Time.get_ticks_msec() + 3500
	while is_instance_valid(completed_effect) and not completed_effect.reported and Time.get_ticks_msec() < completion_deadline:
		await process_frame
	check(is_instance_valid(completed_effect) and completed_effect.terminal == "success", "real Main acknowledges controller success before showing its terminal tail")
	check(state.d.phoneBattery.percent == 45 and state.d.phoneBattery.rechargeCount == 1, "real Main completion restores 45 exactly once")
	await press(KEY_P)
	check(shell.phone.visible and not is_instance_valid(completed_effect), "opening the real phone also retires an already successful cable tail")
	check(state.d.phoneBattery.percent == 45 and state.d.phoneBattery.rechargeCount == 1, "terminal-tail retirement preserves the already accepted recharge")
	await close_shell()
	print("CHARGING_MAIN ", checks, " checks; ", failures, " failures")
	quit(1 if failures else 0)
