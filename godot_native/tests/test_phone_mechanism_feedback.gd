extends SceneTree
## Focused regression for object-only gear motion, transparent tower input, and
## compact available-app layouts. Mouse/key/drag events enter the real Main
## viewport; these are desktop event emulations, not physical-device testing.
## Persistence is refused unless HOME/XDG data is isolated beneath /tmp.
const Pages = preload("res://scripts/ui/phone_pages.gd")
const Utilities = preload("res://scripts/chapters/phone_utilities.gd")
const Chapter = preload("res://scripts/chapters/chapter1_2.gd")
const Ui = preload("res://scripts/ui/native_ui_theme.gd")
const GEAR_NODE := "HomeGearObject"
const PICKUP_NODE := "HomeGearNine"
var state: Node
var shell: Control
var checks := 0
var failures := 0
var actions: Array = []
var receipts: Array = []
var cues: Array = []

func _initialize() -> void: run.call_deferred()
func frames(count := 3) -> void:
	for index in count: await process_frame
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PHONE MECHANISM: " + message)
func named(id: String) -> Control: return shell.page_body.find_child(id, true, false)
func canvas_rect(control: Control) -> Rect2:
	var transform := control.get_global_transform_with_canvas()
	return Rect2(transform.origin, control.size * transform.get_scale())
func emit_mouse(point: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point; event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down
	root.push_input(event, true)
	await process_frame
func click(control: Control) -> void:
	check(is_instance_valid(control), "real pointer target exists")
	if not is_instance_valid(control): return
	var point := canvas_rect(control).get_center()
	var motion := InputEventMouseMotion.new(); motion.position = point; motion.global_position = point
	root.push_input(motion, true)
	await emit_mouse(point, true); await emit_mouse(point, false)
	await frames()
func key(code: Key) -> void:
	for down in [true, false]:
		var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = down
		root.push_input(event, true)
		await process_frame
	await frames()
func drag_inventory(item: String, target: Control) -> void:
	var source: Control = shell.find_child("Item_" + item, true, false)
	check(is_instance_valid(source) and is_instance_valid(target), "real inventory drag endpoints exist")
	if not is_instance_valid(source) or not is_instance_valid(target): return
	var start := canvas_rect(source).get_center(); var end := canvas_rect(target).get_center()
	var previous := start
	var motion := InputEventMouseMotion.new(); motion.position = start; motion.global_position = start
	Input.parse_input_event(motion); Input.flush_buffered_events()
	var down := InputEventMouseButton.new(); down.position = start; down.global_position = start; down.button_index = MOUSE_BUTTON_LEFT; down.pressed = true
	Input.parse_input_event(down); Input.flush_buffered_events(); await process_frame
	for index in range(1, 10):
		var point := start.lerp(end, index / 9.0)
		motion = InputEventMouseMotion.new(); motion.position = point; motion.global_position = point
		motion.relative = point - previous; motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(motion); Input.flush_buffered_events(); previous = point
		await process_frame
	check(root.gui_is_dragging(), "emulated desktop drag enters native GUI drag ownership")
	var up := InputEventMouseButton.new(); up.position = end; up.global_position = end; up.button_index = MOUSE_BUTTON_LEFT; up.pressed = false
	Input.parse_input_event(up); Input.flush_buffered_events()
	await frames()
	check(not root.gui_is_dragging(), "native inventory release clears drag ownership")
func fresh() -> Dictionary:
	var value: Dictionary = state.initial()
	value.native.page = "phone_home"; value.runtimeMode = "phone"
	value.native.settings.music = false; value.native.settings.effects = false
	return value
func fixture(dimensions: Vector2i, value: Dictionary = {}) -> void:
	root.size = dimensions; shell.size = Vector2(dimensions)
	state.d = fresh() if value.is_empty() else value
	state.developer_mode = true
	shell.phone_builder.home_editing = false; shell.phone_builder.home_focus_id = ""
	shell.phone_chrome.inventory_gestures.reset(); shell.inventory_gestures.reset()
	shell._refresh(); shell._layout()
	await frames(5)
	actions.clear(); receipts.clear(); cues.clear()
func transparent_states(button: Button, label: String) -> void:
	for mode in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		check(button.has_theme_stylebox_override(mode), label + " has explicit " + mode + " style")
		var style: StyleBox = button.get_theme_stylebox(mode)
		check(style is StyleBoxFlat and style.bg_color.a == 0 and (style.border_color.a == 0 or (style.border_width_left == 0 and style.border_width_right == 0 and style.border_width_top == 0 and style.border_width_bottom == 0)), label + " paints no panel in " + mode)

## Deliberately independent eligibility oracle: a renderer cannot make an app
## available by changing the same utility that a tautological test would call.
func source_available(value: Dictionary, id: String) -> bool:
	if id in ["wechat", "tiyi", "zjuding", "settings", "control_center"]: return true
	if id == "cc98": return value.actOne.phase != "prologue"
	var interlude: bool = value.qizhenLake.phase == "complete" and not value.chapterThreeInterlude.completed
	if id in ["timeline_recovery", "voice_memos"]: return interlude
	if id == "photos":
		var phases := ["library_route_unlocked", "library_entered", "occupied_seat_found", "evidence_gathering", "bd_briefing", "top_ten_rising", "top_ten_reached", "recovery_application", "pass_ready", "backpack_removed", "seat_recovered", "friend_contacted"]
		return interlude or ((value.actOne.phase == "complete" or value.ui.libraryFinalsPhase in phases) and value.ui.libraryFinalsPuzzle.backpackInspected and value.ui.libraryFinalsPuzzle.investigationOpened)
	return false
func expected_apps(value: Dictionary) -> Array:
	var result: Array = []
	for id in Utilities.normalized_order(value.ui.homeAppOrder):
		var removable: bool = id == "tiyi" and value.actOne.exerciseStarted and value.ui.libraryFinalsPuzzle.presenceProofCollected
		if source_available(value, id) and not (removable and id in value.ui.hiddenHomeAppIds): result.append(id)
	return result
func check_grid(body: Control, value: Dictionary, label: String) -> void:
	var expected := expected_apps(value)
	var actual: Array = []
	for button in body.find_children("HomeApp_*", "Button", true, false): actual.append(str(button.name).trim_prefix("HomeApp_"))
	check(actual == expected, label + " renders exactly the available apps in saved order")
	var home: Control = body.find_child("HomeApp_settings", true, false).get_parent()
	check(home.get_meta("home_visible_app_ids", []) == expected, label + " publishes the actual compact order")
	check(body.find_children("Locked_*", "", true, false).is_empty(), label + " omits unavailable slots entirely")
	for text in body.find_children("*", "Label", true, false):
		check(text.text != "xxx", label + " has no unavailable-app placeholder")
	for id in Utilities.APP_IDS:
		check(Utilities.app_available(value, id) == source_available(value, id), label + " retains source eligibility for " + id)
	for index in expected.size():
		var button: Control = body.find_child("HomeApp_" + expected[index], true, false)
		if not is_instance_valid(button): continue
		var expected_position := Vector2(20 + (index % 4) * 72, 252 + int(index / 4) * 96) / Pages.PHONE_SCALE
		check(button.position.is_equal_approx(expected_position), label + " compact slot " + str(index))
		check(button.size.is_equal_approx(Vector2(48, 48)), label + " preserves app frame dimensions")

func check_all_checkpoints() -> void:
	var corpus: Array = state.developer_checkpoints()
	check(corpus.size() == 117, "all 117 authored checkpoint states are included")
	var original := JSON.stringify(corpus)
	corpus = corpus.duplicate(true)
	corpus.push_front({"id": "fresh-prologue", "state": fresh()})
	for checkpoint in corpus:
		var value: Dictionary = state.merge_defaults(state.initial(), checkpoint.state)
		value.native.page = "phone_home"
		var before := JSON.stringify(value)
		var pages := Pages.new(); pages.s = value
		# Off-tree construction intentionally does not run any presentation timer.
		var body: Control = pages._home()
		check_grid(body, value, str(checkpoint.id))
		check(JSON.stringify(value) == before, str(checkpoint.id) + " layout cannot alter source facts")
		body.free()
	check(JSON.stringify(state.developer_checkpoints()) == original, "checkpoint construction leaves the cached source corpus untouched")
	# A saved custom order may interleave unavailable IDs. Only visible geometry
	# is compacted; the saved permutation and its future IDs must remain intact.
	var custom := fresh(); custom.actOne.phase = "movement_required"
	custom.ui.homeAppOrder = ["clock", "settings", "photos", "cc98", "voice_memos", "wechat", "control_center", "timeline_recovery", "tiyi", "zjuding"]
	custom.ui.hiddenHomeAppIds = ["settings", "tiyi"]
	for removable in [false, true]:
		custom.actOne.exerciseStarted = removable; custom.ui.libraryFinalsPuzzle.presenceProofCollected = removable
		var before := JSON.stringify(custom)
		var pages := Pages.new(); pages.s = custom
		var body: Control = pages._home()
		check_grid(body, custom, "custom-order removable=" + str(removable))
		check(body.find_child("HomeApp_settings", true, false) != null, "stale hidden settings flag cannot remove the mechanism anchor")
		check(JSON.stringify(custom) == before, "projection preserves custom order and hidden flags")
		body.free()

func check_controller_guards() -> void:
	var chapter := Chapter.new(); var value := fresh()
	chapter.dispatch(value, "c1_collect_gear", null)
	check(not value.flags.gearNineTaken and not value.items.reverseGear, "unfallen gear cannot award digit or item")
	chapter.dispatch(value, "c1_gear_rotated", {"elapsedMs": 1500})
	check(not value.flags.gearFallen, "rotation completion requires auto-rotate authority")
	value.ui.autoRotate = true
	chapter.dispatch(value, "c1_gear_rotated", {"elapsedMs": 1499})
	check(not value.flags.gearFallen, "source 1500ms gear proof rejects early completion")
	chapter.dispatch(value, "c1_gear_rotated", {"elapsedMs": 1500})
	check(value.flags.gearFallen and not value.ui.autoRotate and not value.flags.gearNineTaken, "rotation commits fall only and disables auto-rotate")
	chapter.dispatch(value, "c1_collect_gear", null)
	check(value.flags.gearNineTaken and value.items.reverseGear and value.digits.d3 == "9", "pickup retains original digit and reverse-gear item authority")
	var collected := JSON.stringify(value)
	chapter.dispatch(value, "c1_collect_gear", null); chapter.dispatch(value, "c1_gear_rotated", {"elapsedMs": 9999})
	check(JSON.stringify(value) == collected, "duplicate gear completion and pickup cannot award again")
	value = fresh()
	chapter.dispatch(value, "c1_tower", "towerKey")
	check(not value.native.get("tower_key_pending", false), "unowned key cannot start insertion")
	value.items.towerKey = true
	chapter.dispatch(value, "c1_tower", "reverseGear")
	chapter.dispatch(value, "c1_tower_complete", {"elapsedMs": 1700})
	check(not value.flags.towerOpened and value.items.towerKey, "wrong item and missing pending proof cannot open tower")
	chapter.dispatch(value, "c1_tower", "towerKey")
	chapter.dispatch(value, "c1_tower_complete", {"elapsedMs": 1699})
	check(value.native.tower_key_pending and not value.flags.towerOpened and value.items.towerKey and not value.items.fertilizer, "source 1700ms tower proof rejects early reward")
	chapter.dispatch(value, "c1_tower_complete", {"elapsedMs": 1700})
	check(value.flags.towerOpened and not value.items.towerKey and value.items.fertilizer and not value.native.tower_key_pending, "exact source proof performs key-to-fertilizer transformation")
	var completed := JSON.stringify(value)
	chapter.dispatch(value, "c1_tower", "towerKey"); chapter.dispatch(value, "c1_tower_complete", {"elapsedMs": 9999})
	check(JSON.stringify(value) == completed, "duplicate tower use/completion cannot award again")

func check_custom_gear_landing() -> void:
	var value := fresh(); value.ui.autoRotate = true
	value.ui.homeAppOrder = ["clock", "control_center", "photos", "settings", "voice_memos", "wechat", "cc98", "timeline_recovery", "tiyi", "zjuding"]
	value.ui.hiddenHomeAppIds = ["settings"]
	var pages := Pages.new(); pages.s = value
	var body: Control = pages._home()
	body.theme = Ui.make_theme(load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"))
	var frame: Control = body.find_child("HomeApp_settings", true, false)
	var gear: Control = body.find_child(GEAR_NODE, true, false)
	check(frame != null and gear != null, "custom saved order retains separate gear and settings frame")
	if frame == null or gear == null: body.free(); return
	var rest := frame.position
	check(gear.position == rest and gear.get_parent() == body, "gear starts over its reordered frame and owns independent root-space motion")
	var completed: Array = []
	pages.action_requested.connect(func(id, result):
		if id == "c1_gear_rotated": completed.append({"id": id, "proof": result, "center": gear.position + gear.size / 2, "frame": frame.position, "rotation": frame.rotation}))
	root.add_child(body)
	await frames(3)
	check((gear.position + gear.size / 2).is_equal_approx(frame.position + frame.size / 2), "themed glyph starts centered on the fixed settings frame after font layout")
	await create_timer(1.65).timeout
	check(completed.size() == 1, "actual custom-order gear tween publishes one completion")
	if completed.size() == 1:
		check(completed[0].proof.elapsedMs >= 1500, "gear preserves the full1500ms source animation")
		check(completed[0].center.is_equal_approx(Pages.HOME_GEAR_PICKUP_RECT.get_center()), "fall ends at exactly the later pickup center despite custom source position")
		check(completed[0].frame == rest and completed[0].rotation == 0, "custom-order frame never inherits gear movement")
	check(not value.flags.gearFallen, "standalone presentation emits proof without mutating shared state itself")
	body.free(); await frames()

func check_main_gear(dimensions: Vector2i) -> void:
	await fixture(dimensions)
	check_grid(shell.page_body, state.d, "Main " + str(dimensions))
	check(shell.phone.size == Vector2(430, 860), "responsive Main preserves canonical 430x860 phone")
	var frame: Button = named("HomeApp_settings")
	var start := frame.position
	await click(frame)
	check(not state.d.flags.gearFallen and not state.d.flags.gearNineTaken, "real settings pointer cannot bypass auto-rotate")
	state.d.ui.autoRotate = true; shell._refresh(); await frames(2)
	frame = named("HomeApp_settings")
	var gear: Control = named(GEAR_NODE)
	check(is_instance_valid(gear) and gear != frame, "moving gear is an independent visual object")
	if not is_instance_valid(gear): return
	check(gear.mouse_filter == Control.MOUSE_FILTER_IGNORE, "gear visual leaves app and later pickup input ownership explicit")
	await create_timer(.28).timeout
	check(frame.rotation == 0 and frame.position.is_equal_approx(start) and frame.scale == Vector2.ONE, "settings square stays fixed while its gear rotates")
	check(absf(gear.rotation) > .1, "only the gear visual receives actual rotation")
	check(not state.d.flags.gearFallen and not state.d.flags.gearNineTaken, "intermediate animation has no early puzzle reward")
	var deadline := Time.get_ticks_msec() + 2500
	while not state.d.flags.gearFallen and Time.get_ticks_msec() < deadline: await process_frame
	await frames(3)
	check(state.d.flags.gearFallen and not state.d.flags.gearNineTaken, "actual source-duration animation reaches an uncollected fall")
	check(actions.count("c1_gear_rotated") == 1, "Main receives exactly one fall completion intent")
	frame = named("HomeApp_settings")
	check(frame.rotation == 0 and frame.position.is_equal_approx(start), "rebuilt empty settings frame preserves its original transform")
	var pickup: Button = named(PICKUP_NODE)
	var digit: Button = pickup
	check(is_instance_valid(pickup) and is_instance_valid(digit), "fallen digit has a named visual and matching real hit target")
	if not is_instance_valid(pickup) or not is_instance_valid(digit): return
	transparent_states(pickup, "fallen digit pickup")
	check(pickup.text == "9" and pickup.get_child_count() == 0, "pickup renders only one complete nine, with no extra star or badge")
	check(pickup.get_theme_color("font_color") == Pages.INK and pickup.get_theme_constant("outline_size") == 0, "fallen nine keeps the reviewed dark pixel glyph without a double outline")
	check(pickup.get_theme_font_size("font_size") == 56 and pickup.size.is_equal_approx(Pages.HOME_GEAR_PICKUP_RECT.size), "fallen nine keeps its large56px digit and shared authored hit area")
	check(pickup.get_combined_minimum_size().x <= pickup.size.x and pickup.get_combined_minimum_size().y <= pickup.size.y, "font metrics fit the complete nine inside its actual target")
	check(pickup.get_rect().is_equal_approx(Pages.HOME_GEAR_PICKUP_RECT), "rendered digit and actual hotspot share the landing rectangle")
	check(canvas_rect(pickup).encloses(canvas_rect(digit)), "complete large nine stays inside its own hit target")
	check(canvas_rect(shell.phone).encloses(canvas_rect(pickup)), "landed digit remains inside every scaled phone")
	check(digit.rotation == 0 and digit.scale == Vector2.ONE, "landed nine is upright and undistorted")
	if dimensions.x == 430:
		pickup.grab_focus(); await key(KEY_ENTER)
	else:
		await click(pickup)
	check(state.d.flags.gearNineTaken and state.d.items.reverseGear and state.d.digits.d3 == "9", "real fallen-nine mouse/Enter uses existing pickup authority")
	check(named(PICKUP_NODE) == null, "collected digit disappears without leaving a stale hit target")
	check(actions.count("c1_collect_gear") == 1, "one native click dispatches one pickup")

func check_main_tower(dimensions: Vector2i, use_drag: bool) -> void:
	var value := fresh(); value.items.towerKey = true; value.items.reverseGear = true; value.ui.inventoryOpen = true
	await fixture(dimensions, value)
	var tower: Button = named("TowerDropTarget")
	transparent_states(tower, "tower idle")
	var artwork: Control = named("SourceHomeArtwork")
	check(artwork.get_script().resource_path == "res://scripts/ui/phone_home_art.gd" and not artwork.tower_open, "original closed tower artwork remains the renderer")
	state.d.native.selected_item = "reverseGear"
	await click(tower)
	check(not state.d.native.get("tower_key_pending", false) and state.d.items.towerKey and not state.d.flags.towerOpened, "real wrong-item click cannot begin insertion")
	if use_drag:
		await drag_inventory("towerKey", named("TowerDropTarget"))
	else:
		state.d.native.selected_item = "towerKey"
		await click(named("TowerDropTarget"))
	check(state.d.native.get("tower_key_pending", false) and state.d.items.towerKey and not state.d.items.fertilizer, "actual click/drop begins pending insertion without consuming key")
	tower = named("TowerDropTarget")
	check(tower.disabled, "pending tower disables duplicate pointer submissions")
	transparent_states(tower, "tower during live insertion")
	var count := actions.count("c1_tower")
	await click(tower)
	# Explicit callback probe is supplemental to the genuine drag above.
	tower = named("TowerDropTarget")
	check(not tower._can_drop_data(tower.size / 2, {"kind": "inventory_item", "item": "towerKey"}), "disabled target rejects an emulated second drop")
	tower._drop_data(tower.size / 2, {"kind": "inventory_item", "item": "towerKey"})
	check(actions.count("c1_tower") == count, "disabled click and callback cannot duplicate insertion")
	await create_timer(.3).timeout
	check(not state.d.flags.towerOpened and state.d.items.towerKey, "tower remains closed during the actual insertion segment")
	var deadline := Time.get_ticks_msec() + 2600
	while not state.d.flags.towerOpened and Time.get_ticks_msec() < deadline: await process_frame
	await frames(3)
	check(state.d.flags.towerOpened and not state.d.items.towerKey and state.d.items.fertilizer, "actual 1700ms Main timeline produces fertilizer")
	check(actions.count("c1_tower_complete") == 1 and receipts.size() == 1, "one terminal proof produces exactly one successful receipt")
	check(cues.count("tower_key_insert") == 1 and cues.count("tower_key_rotate") == 1, "insertion and rotation cues each occur once")
	check(named("SourceHomeArtwork").tower_open, "original tower artwork reads controller-opened fact")
	await click(named("TowerDropTarget"))
	check(receipts.size() == 1 and state.d.items.fertilizer, "repeated opened-tower click cannot duplicate reward receipt")

func check_reorder_input() -> void:
	var value := fresh(); value.actOne.phase = "movement_required"
	await fixture(Vector2i(430, 860), value)
	var original: Array = state.d.ui.homeAppOrder.duplicate()
	named("HomeApp_settings").grab_focus(); await key(KEY_F2)
	check(shell.phone_builder.home_editing, "real F2 enters desktop editing")
	await key(KEY_RIGHT)
	check(state.d.ui.homeAppOrder[3] == "cc98" and state.d.ui.homeAppOrder[7] == "settings", "keyboard Right crosses omitted slots to the next displayed app")
	for index in [4, 5, 6, 9]: check(state.d.ui.homeAppOrder[index] == original[index], "keyboard reorder retains unavailable saved slot " + str(index))
	check(root.gui_get_focus_owner() == named("HomeApp_settings"), "compact keyboard move retains focus on settings")
	await key(KEY_ESCAPE)
	check(not shell.phone_builder.home_editing, "real Escape exits desktop editing")
	check_grid(shell.page_body, state.d, "reordered Main")
	state.d.actOne.exerciseStarted = true; state.d.ui.libraryFinalsPuzzle.presenceProofCollected = true
	state.act("phone_app_remove", "tiyi"); await frames()
	check_grid(shell.page_body, state.d, "hidden optional app Main")
	check(named("HomeApp_tiyi") == null, "authorized optional app removal closes its rendered slot")
	state.act("phone_app_restore", "tiyi"); await frames()
	check_grid(shell.page_body, state.d, "restored optional app Main")
	check(named("HomeApp_tiyi") != null, "optional app restoration restores its saved relative order")

func check_save_reload() -> void:
	state.developer_mode = false
	var saved_order: Array = state.d.ui.homeAppOrder.duplicate()
	check(state.save_game(), "custom compact layout writes through the real save path")
	state.d = state.initial(); check(state.load_game(), "custom compact layout reloads from disk")
	check(state.d.ui.homeAppOrder == saved_order, "save/reload retains the full user permutation")
	shell._refresh(); await frames()
	check_grid(shell.page_body, state.d, "reloaded compact layout")
	state.d = fresh(); state.d.flags.gearFallen = true; state.d.ui.autoRotate = false
	check(state.save_game(), "uncollected fallen digit saves")
	state.d = state.initial(); check(state.load_game(), "uncollected fallen digit reloads")
	shell._refresh(); await frames()
	check(named(PICKUP_NODE) != null and not state.d.flags.gearNineTaken, "reload recreates the uncollected nine without an early grant")
	await click(named(PICKUP_NODE))
	check(state.save_game(), "collected gear saves through the existing schema")
	state.d = state.initial(); check(state.load_game(), "collected gear reloads")
	shell._refresh(); await frames()
	check(named(PICKUP_NODE) == null and state.d.items.reverseGear and state.d.digits.d3 == "9", "reload preserves collected gear and does not respawn the digit")
	state.d = fresh(); state.d.items.towerKey = true; state.d.native.tower_key_pending = true
	check(state.save_game(), "pending tower saves without manufacturing fertilizer")
	state.d = state.initial(); check(state.load_game(), "pending tower reloads")
	shell._refresh(); await frames()
	actions.clear(); receipts.clear()
	check(state.d.items.towerKey and not state.d.flags.towerOpened and not state.d.items.fertilizer, "pending reload retains original item and requires fresh timeline completion")
	transparent_states(named("TowerDropTarget"), "reloaded pending tower")
	var deadline := Time.get_ticks_msec() + 2600
	while not state.d.flags.towerOpened and Time.get_ticks_msec() < deadline: await process_frame
	await frames()
	check(state.d.flags.towerOpened and state.d.items.fertilizer and not state.d.items.towerKey and receipts.size() == 1, "reloaded pending tower completes once through the real controller")
	check(state.save_game(), "completed tower saves")
	state.d = state.initial(); check(state.load_game(), "completed tower reloads")
	shell._refresh(); await frames()
	check(named("SourceHomeArtwork").tower_open and state.d.items.fertilizer and not state.d.native.tower_key_pending, "completed tower reload preserves reward and opened original art")
	state.developer_mode = true

func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):
		push_error("Refusing phone mechanism save tests outside isolated /tmp HOME/XDG_DATA_HOME")
		quit(2); return
	create_timer(90).timeout.connect(func(): push_error("Phone mechanism watchdog"); quit(2))
	state = root.get_node("State"); state.developer_mode = true; state.d = fresh()
	check_controller_guards(); check_all_checkpoints()
	await check_custom_gear_landing()
	shell = load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(5)
	state.action_completed.connect(func(id, before, after, _result):
		actions.append(id)
		if id == "c1_tower_complete" and not before.flags.towerOpened and after.flags.towerOpened: receipts.append(id))
	shell.phone_builder.presentation_requested.connect(func(id): cues.append(id))
	for dimensions in [Vector2i(390, 844), Vector2i(430, 860), Vector2i(1180, 812)]:
		await check_main_gear(dimensions)
		await check_main_tower(dimensions, dimensions.x != 430)
	await check_reorder_input()
	await check_save_reload()
	await shell.shutdown(); shell.queue_free(); await frames()
	print("PHONE_MECHANISM_FEEDBACK: ", checks, " checks; ", failures, " failures; 117 source checkpoints; desktop mouse/key/drag emulation only")
	quit(1 if failures else 0)
