extends SceneTree
## Retired charging entry points retain real Main world, inventory and phone navigation.
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
func run() -> void:
	state = root.get_node("State"); state.developer_mode = true
	create_timer(40).timeout.connect(func(): push_error("Charging main watchdog"); quit(2))
	for dimensions: Vector2i in [Vector2i(390, 844), Vector2i(844, 390), Vector2i(1180, 812)]:
		await close_shell(); root.size = dimensions; fixture()
		shell = load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(6)
		shell._show_world_mobile(); await frames()
		shell.world.player = Vector2(665, 790); shell.world._sync_player(); shell.world._update_camera()
		check(shell.world_frame.visible and not shell.phone.visible, "charging fixture begins on live world")
		state.act("c3_target:theater_charging_station"); await frames()
		check(not is_instance_valid(shell.world_effect), "retired station cannot open a charging component")
		check(state.d.phoneBattery.keys() == ["percent"] and state.d.phoneBattery.percent == 7, "retired station preserves consumption-only battery")
		check(not shell._authored_world_contract() and shell.world.mobile_exploration == (dimensions.x < 1100), "retired station does not force the960x540 cinematic contract")
		check(shell.world_frame.visible and not shell.phone.visible, "retired station does not open a modal or phone shell")
		var original: Vector2 = shell.world.player
		var story: Dictionary = state.d.theaterHunt.duplicate(true)
		shell.compact_inventory_open = true; shell._layout(); await frames()
		check(shell.inventory_dock.visible and not is_instance_valid(shell.world_effect), "inventory opens without any charging effect")
		root.size = Vector2i(430, 860); shell.size = Vector2(430, 860); shell._layout(); await frames()
		check(shell.world.player == original and state.d.theaterHunt == story, "rotation preserves player and story")
		check(shell.world.size.x > 350 and shell.world.mobile_exploration, "portrait resize retains real exploration pixels")
		for percent in [7, 1, 0]:
			state.d.phoneBattery.percent = percent
			await press(KEY_P)
			check(shell.phone.visible and not shell.world_frame.visible, "P opens the real phone at battery " + str(percent))
			check(not is_instance_valid(shell.world_effect) and state.d.phoneBattery.percent == percent, "phone entry cannot create charging or power")
			await press(KEY_ESCAPE)
			check(shell.world_frame.visible and shell.world.has_focus(), "phone return restores original world focus at battery " + str(percent))
			state.d.native.page = "c3_theater"; state.act("c3_target:theater_charging_station"); await frames()
			check(not is_instance_valid(shell.world_effect), "repeated retired station action stays inert")
			shell._show_settings(); await frames()
			check(is_instance_valid(shell.modal) and state.d.phoneBattery.percent == percent, "settings remain available without charging or battery gain")
			shell._close_modal(); await frames()
			check(not is_instance_valid(shell.modal) and shell.world_frame.visible, "settings close restores the live world")
			state.act("c3_charge_result", {"elapsed_ms": 2200, "success": true}); await frames()
			check(state.d.phoneBattery.keys() == ["percent"] and state.d.phoneBattery.percent == percent and state.d.theaterHunt == story, "stale completion cannot recharge or alter story")
	await close_shell()
	print("CHARGING_MAIN ", checks, " checks; ", failures, " failures")
	quit(1 if failures else 0)
