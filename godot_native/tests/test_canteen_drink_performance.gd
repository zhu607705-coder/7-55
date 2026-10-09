extends SceneTree
const DrinkMotion = preload("res://scripts/objects/canteen_drink_performance.gd")
class SignalState extends Node:
	signal action_completed(action: String, before: Dictionary, next: Dictionary, result: Dictionary)
	var d: Dictionary = {}
class WorldStub extends Control:
	var host_node: Control
	var blocked := false
	func _shell_input_blocked() -> bool: return blocked or (is_instance_valid(host_node) and is_instance_valid(host_node.modal))
class HostStub extends Control:
	var world_frame: Control
	var modal: Control
	var c3_device_panel: Control
	var active_game: Control
	var phone_document: Control
class DrinkPanelStub extends Control:
	signal closed(reason: String)
	var active := true
	var kind := "drink"
	var target_id := ""
	var item_id := ""
	var bound_state: Dictionary = {}
	var dispatch: Callable
	func _take() -> void:
		if not active: return
		active = false
		hide()
		_finish_close.call_deferred("take")
		dispatch.call()
	func _finish_close(reason: String) -> void:
		if is_inside_tree(): closed.emit(reason)
var checks := 0
var errors := 0
var source := SignalState.new()
var world := WorldStub.new()
var host := HostStub.new()
var performance: Node2D

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		errors += 1
		push_error(label)

func initial() -> Dictionary:
	return {"native":{"scene":"canteen_interior", "mode":"light", "settings":{"reduced_motion":false}},
		"items":{"sparklingWater":false, "lemonTea":false, "blackCoffee":false}}

func accepted(item: String) -> Dictionary:
	return {"handled":true, "presentation":[{"cueId":"canteen_drink_collected", "payload":{"itemId":item}}]}

func replace_state(s: Dictionary) -> void:
	source.d = s
	performance.sync(s, true)

func emit_grant(spec: Dictionary, result: Dictionary = {}) -> void:
	var before: Dictionary = source.d.duplicate(true)
	source.d.items[spec.item] = true
	performance.sync(source.d, true)
	source.action_completed.emit("c3_drink_take:" + str(spec.target), before, source.d.duplicate(true), accepted(spec.item) if result.is_empty() else result)

func playing_count() -> int:
	var total := 0
	for slot: Dictionary in performance.slots.values(): total += int(slot.playing)
	return total

func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.add_child(source)
	root.add_child(host)
	host.world_frame = Control.new()
	host.add_child(host.world_frame)
	root.add_child(world)
	world.host_node = host
	performance = DrinkMotion.new()
	world.add_child(performance)
	performance.setup(world)
	performance._bind_state(source)
	performance.set_process(false)
	_test_art()
	_test_fact_gate()
	_test_timeline()
	_test_lifetime()
	_test_visible_panel_ownership()
	await _test_modal_handoff()
	if not OS.get_cmdline_user_args().has("--isolated"):
		await _test_controller()
	else:
		print("Isolated fixture: controller integration omitted by explicit --isolated flag")
	var count: int = source.action_completed.get_connections().size()
	performance.free()
	check(source.action_completed.get_connections().size() == count - 1, "lifetime teardown disconnects action_completed")
	world.free()
	host.free()
	source.free()
	if not OS.get_cmdline_user_args().has("--isolated"):
		await _test_full_shell()
	print("Canteen accepted drink frames: ", checks, " checks, ", errors, " failures")
	quit(1 if errors else 0)

func _test_fact_gate() -> void:
	for spec: Dictionary in DrinkMotion.MACHINES:
		var before := initial()
		var next := before.duplicate(true)
		next.items[spec.item] = true
		var original_before := before.duplicate(true)
		var original_next := next.duplicate(true)
		var action := "c3_drink_take:" + str(spec.target)
		check(DrinkMotion.accepted_item(action, before, next, accepted(spec.item)) == spec.item, "correct source action/cue plus exact false-to-true inventory grant")
		check(DrinkMotion.accepted_item(action, next, next, accepted(spec.item)).is_empty(), "already-owned item cannot animate")
		check(DrinkMotion.accepted_item(action, before, before, accepted(spec.item)).is_empty(), "cue without inventory grant cannot animate")
		check(DrinkMotion.accepted_item(action, before, next, {"handled":true}).is_empty(), "handled locked result cannot animate")
		check(DrinkMotion.accepted_item(action, before, next, {"handled":false,"presentation":accepted(spec.item).presentation}).is_empty(), "unhandled result cannot animate")
		check(DrinkMotion.accepted_item(action, before, next, accepted("badDrink")).is_empty(), "mismatched accepted cue cannot animate")
		check(DrinkMotion.accepted_item("c3_target:"+str(spec.target), before, next, accepted(spec.item)).is_empty(), "opening a machine cannot animate")
		check(DrinkMotion.accepted_item("c3_drink_take:drink-machine-spare", before, next, accepted(spec.item)).is_empty(), "unregistered target cannot animate")
		for bad_context: String in ["scene", "mode"]:
			var changed_before := before.duplicate(true)
			changed_before.native[bad_context] = "campus_bootstrap" if bad_context == "scene" else "dark"
			check(DrinkMotion.accepted_item(action, changed_before, next, accepted(spec.item)).is_empty(), "before snapshot scene/light required")
			var changed_next := next.duplicate(true)
			changed_next.native[bad_context] = "campus_bootstrap" if bad_context == "scene" else "dark"
			check(DrinkMotion.accepted_item(action, before, changed_next, accepted(spec.item)).is_empty(), "after snapshot scene/light required")
		check(before == original_before and next == original_next, "fact gate never mutates either controller snapshot")

func _test_timeline() -> void:
	var visited: Array = []
	for i in range(8):
		visited.append(DrinkMotion.frame_at(i * 80.0 + 40.0))
		check(DrinkMotion.frame_region(i) == Rect2(Vector2(i % 4, floori(i / 4.0)) * 128, Vector2(128,128)), "atlas frame uses the exact 4x2 cell contract")
	check(visited == [0,1,2,3,4,5,6,7], "normal playback visits all eight genuinely authored frames")
	check(DrinkMotion.frame_at(-1) == 0 and DrinkMotion.frame_at(10000) == 7, "frame indices bounded on invalid or late samples")
	for ms: float in [0.0,40.0,80.0,120.0,159.0]:
		check(DrinkMotion.frame_at(ms, true) == 7, "reduced motion remains in one stable full-bottle pose")
	check(DrinkMotion.duration_ms(false) == 640 and DrinkMotion.duration_ms(true) == 160, "normal and reduced sequence durations")
	check(performance.atlas != null and performance.atlas.get_size() == Vector2(512,256), "runtime imported atlas is loaded")
	check(performance.get_child_count() == 3, "only three passive sprite children, no input or collision surfaces")
	for spec: Dictionary in DrinkMotion.MACHINES:
		var sprite: Sprite2D = performance.sprites[spec.item]
		var bounds := Rect2(sprite.position - Vector2(spec.point), DrinkMotion.CELL * sprite.scale)
		check(DrinkMotion.DRAW_RECT.encloses(bounds) and is_equal_approx(sprite.scale.x, sprite.scale.y), "each fixed nozzle overlay fits its own machine without distortion")
	check(performance.z_index < 50 and performance.get_meta("source_depth") == 197.0, "world-only depth remains below shell modal layers")

func _test_lifetime() -> void:
	replace_state(initial())
	check(playing_count() == 0, "initial snapshot never animates")
	var first: Dictionary = DrinkMotion.MACHINES[0]
	emit_grant(first)
	check(playing_count() == 1 and source.d.items[first.item], "item granted immediately before independent motion begins")
	check(performance.sprites[first.item].visible and performance.sprites[first.item].texture != null, "accepted dispense paints an actual loaded frame")
	var after_grant := source.d.duplicate(true)
	performance.advance(0.08)
	check(performance.slots[first.item].elapsed_ms == 80.0, "normal slot advances independently")
	emit_grant(DrinkMotion.MACHINES[1])
	emit_grant(DrinkMotion.MACHINES[2])
	check(playing_count() == 3 and performance.slots[first.item].elapsed_ms == 80.0, "three drink actions do not restart each other")
	var before_repeated: int = performance.observed_accepts
	emit_grant(first)
	check(performance.observed_accepts == before_repeated and performance.slots[first.item].elapsed_ms == 80.0, "repeated owned action cannot restart active frame sequence")
	var once_before := initial()
	source.action_completed.emit("c3_drink_take:"+str(first.target), once_before, source.d.duplicate(true), accepted(first.item))
	check(performance.observed_accepts == before_repeated, "replayed accepted signal lacks a fresh live grant edge")
	performance.advance(-1)
	check(performance.slots[first.item].elapsed_ms == 80.0, "negative delta cannot rewind")
	var saved := source.d.duplicate(true)
	performance.advance(10)
	check(playing_count() == 0 and source.d == saved, "all sequences expire without changing progression")
	check(after_grant.items[first.item], "immediate reward is retained through elapsed timeline")
	# A consumed ingredient can be collected again through a new real edge.
	source.d.items[first.item] = false
	performance.sync(source.d, true)
	emit_grant(first)
	check(performance.observed_accepts == before_repeated + 1 and playing_count() == 1, "recollection after real consumption starts one new sequence")
	replace_state(source.d.duplicate(true))
	check(playing_count() == 0, "save replacement cancels instead of reconstructing transient motion")
	source.action_completed.emit("c3_drink_take:"+str(first.target), once_before, source.d.duplicate(true), accepted(first.item))
	check(playing_count() == 0, "loaded owned item cannot replay an old grant signal")
	for cancellation: String in ["scene", "inactive", "world_hidden", "phone_hidden", "modal", "node_hidden", "unsynced_reload"]:
		replace_state(initial())
		emit_grant(first)
		check(playing_count() == 1, "valid action starts before "+cancellation)
		match cancellation:
			"scene": source.d.native.scene = "campus_bootstrap"; performance.sync(source.d, true)
			"inactive": performance.sync(source.d, false)
			"world_hidden": world.hide(); performance._process(0)
			"phone_hidden": host.world_frame.hide(); performance._process(0)
			"modal": world.blocked = true; performance._process(0)
			"node_hidden": performance.hide()
			"unsynced_reload": source.d = source.d.duplicate(true); performance._process(0)
		check(playing_count() == 0, cancellation+" cancels pending/playing dispense")
		world.show(); host.world_frame.show(); performance.show(); world.blocked = false
		performance.sync(source.d, true)
		performance._process(0)
		check(playing_count() == 0, "resuming after "+cancellation+" never replays motion")
	# Actions taken while a phone or modal owns the screen are never queued.
	for blocked_by: String in ["phone", "modal"]:
		replace_state(initial())
		if blocked_by == "phone": host.world_frame.hide()
		else: world.blocked = true
		emit_grant(first)
		check(playing_count() == 0, "accepted controller action while "+blocked_by+" hidden does not show overlay")
		host.world_frame.show(); world.blocked = false
		performance._process(0)
		check(playing_count() == 0, "hidden-time grant is never deferred into a visible fake dispense")
	var reduced := initial()
	reduced.native.settings.reduced_motion = true
	replace_state(reduced)
	emit_grant(first)
	var sprite: Sprite2D = performance.sprites[first.item]
	var fixed: Vector2 = sprite.position
	check(performance.slots[first.item].reduced and sprite.region_rect == DrinkMotion.frame_region(7), "reduced live action starts in the stable final pose")
	performance.advance(0.159)
	check(playing_count() == 1 and sprite.position == fixed and sprite.rotation == 0, "reduced motion contains no shake, travel, or rotation")
	performance.advance(0.0011)
	check(playing_count() == 0, "reduced pose retires after 160 ms")
	# Production State.changed schedules Main._refresh instead of refreshing
	# the observer synchronously. A controller cue can precede the next sync.
	replace_state(initial())
	var before_deferred := source.d.duplicate(true)
	source.d.items[first.item] = true
	source.action_completed.emit("c3_drink_take:"+str(first.target), before_deferred, source.d.duplicate(true), accepted(first.item))
	check(playing_count() == 1 and performance.sprites[first.item].visible, "action_completed before deferred changed refresh still observes the live grant")
	performance.sync(source.d, true)
	check(playing_count() == 1, "subsequent deferred sync preserves the already accepted animation")
	performance.cancel()

func _test_visible_panel_ownership() -> void:
	var first: Dictionary = DrinkMotion.MACHINES[0]
	replace_state(initial())
	host.modal = Control.new()
	host.add_child(host.modal)
	var panel := DrinkPanelStub.new()
	panel.target_id = str(first.target)
	panel.item_id = str(first.item)
	panel.bound_state = source.d
	host.modal.add_child(panel)
	host.c3_device_panel = panel
	var count: int = performance.observed_accepts
	var before := source.d.duplicate(true)
	source.d.items[first.item] = true
	source.action_completed.emit("c3_drink_take:"+str(first.target), before, source.d.duplicate(true), accepted(first.item))
	check(source.d.items[first.item] and performance.observed_accepts == count, "visible drink panel owns immediate accepted grant without a second world dispense")
	check(not performance.slots[first.item].waiting and not performance.sprites[first.item].visible, "active panel playback is never queued as a world handoff")
	panel.active = false
	panel.hide()
	performance.sync(source.d, true)
	performance._process(0)
	check(playing_count() == 0 and not performance.slots[first.item].waiting, "panel completion does not revive an already-owned grant")
	host.modal.free()
	host.modal = null
	host.c3_device_panel = null
	performance._process(0)
	check(playing_count() == 0 and not performance.sprites[first.item].visible, "closing accepted closeup does not replay a world dispense")

func _test_modal_handoff() -> void:
	var first: Dictionary = DrinkMotion.MACHINES[0]
	for scenario: String in ["accepted", "replaced", "phone_hidden", "other_modal", "same_target_modal", "wrong_panel"]:
		replace_state(initial())
		host.modal = Control.new()
		host.add_child(host.modal)
		var panel := DrinkPanelStub.new()
		panel.target_id = str(first.target)
		panel.item_id = str(first.item)
		panel.bound_state = source.d
		panel.dispatch = func(): emit_grant(first)
		host.modal.add_child(panel)
		host.c3_device_panel = panel
		var original_modal: Control = host.modal
		panel.closed.connect(func(_reason: String):
			if host.modal == original_modal:
				host.c3_device_panel = null
				host.modal = null
			if is_instance_valid(original_modal): original_modal.queue_free())
		if scenario == "wrong_panel":
			panel.target_id = str(DrinkMotion.MACHINES[1].target)
			panel.item_id = str(DrinkMotion.MACHINES[1].item)
		# Retain the compatibility hide/inactive-before-dispatch handoff. The
		# production panel now keeps its accepted closeup visible instead.
		panel._take()
		check(source.d.items[first.item] and is_instance_valid(host.modal), "deferred-dismiss handoff preserves immediate grant")
		check(playing_count() == 0 and not performance.sprites[first.item].visible, "accepted handoff renders no sprite while modal exists")
		check(bool(performance.slots[first.item].waiting) == (scenario != "wrong_panel"), "only the matching hidden inactive panel may queue a real accepted grant")
		match scenario:
			"replaced": replace_state(source.d.duplicate(true))
			"phone_hidden": host.world_frame.hide(); performance._process(0)
			"other_modal", "same_target_modal":
				host.modal = Control.new()
				host.add_child(host.modal)
				host.c3_device_panel = null
				if scenario == "same_target_modal":
					var replacement := DrinkPanelStub.new()
					replacement.active = false
					replacement.kind = "drink"
					replacement.item_id = str(first.item)
					replacement.target_id = str(first.target)
					replacement.bound_state = source.d
					replacement.hide()
					host.modal.add_child(replacement)
					host.c3_device_panel = replacement
				performance._process(0)
		await process_frame
		performance._process(0)
		check(playing_count() == (1 if scenario == "accepted" else 0), "deferred modal close starts only still-valid accepted grant: "+scenario)
		if scenario == "accepted":
			check(performance.slots[first.item].elapsed_ms == 0.0, "world dispense starts its full timeline after deferred modal teardown")
		if is_instance_valid(host.modal): host.modal.free()
		host.modal = null
		host.c3_device_panel = null
		host.world_frame.show()
		performance.cancel()

func _test_controller() -> void:
	var chapter: RefCounted = load("res://scripts/chapters/chapter3.gd").new()
	for spec: Dictionary in DrinkMotion.MACHINES:
		for scenario: String in ["accepted", "owned", "dark", "distant", "inactive", "promo", "queue_gap", "entry_pending", "wrong_scene"]:
			var s: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
			s.native = {"chapter":3, "page":"c3_canteen", "scene":"canteen_interior", "mode":"light", "settings":{}, "player":{}}
			s.canteenHunt.active = true
			s.canteenHunt.phase = "tray_search"
			s.canteenHunt.entryPaperEscaped = true
			s.runtimeMode = "rpg"
			s.rpgScene = "canteen_interior"
			var definition: Dictionary = chapter.get_definition("canteen_interior", spec.target, s)
			var point: Dictionary = definition.get("stand", {"x":definition.x,"y":definition.y})
			s.native.player = {"x":point.x, "y":point.y}
			match scenario:
				"owned": s.items[spec.item] = true
				"dark": s.native.mode = "dark"
				"distant": s.native.player = {"x":10,"y":10}
				"inactive": s.canteenHunt.active = false
				"promo": s.canteenHunt.promoDrinkPlaced = true
				"queue_gap": s.canteenHunt.queueGapOpened = true
				"entry_pending": s.canteenHunt.entryPaperEscaped = false
				"wrong_scene": s.native.scene = "campus_bootstrap"
			replace_state(s)
			var before := s.duplicate(true)
			var action := "c3_drink_take:" + str(spec.target)
			var result: Dictionary = chapter.dispatch(s, action)
			performance.sync(s, true)
			source.action_completed.emit(action, before, s.duplicate(true), result)
			check(playing_count() == (1 if scenario == "accepted" else 0), "untouched native controller "+scenario+" gates "+str(spec.item))
			var after_controller := s.duplicate(true)
			performance.advance(10)
			check(s == after_controller, "presentation leaves source-controller "+scenario+" facts unchanged")
		await _test_real_panel(chapter, spec)

func _test_real_panel(chapter: RefCounted, spec: Dictionary) -> void:
	var s: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	s.native = {"chapter":3, "page":"c3_canteen", "scene":"canteen_interior", "mode":"light", "settings":{}, "player":{}}
	s.canteenHunt.active = true
	s.canteenHunt.phase = "tray_search"
	s.canteenHunt.entryPaperEscaped = true
	s.runtimeMode = "rpg"
	s.rpgScene = "canteen_interior"
	var definition: Dictionary = chapter.get_definition("canteen_interior", spec.target, s)
	var point: Dictionary = definition.get("stand", {"x":definition.x,"y":definition.y})
	s.native.player = {"x":point.x, "y":point.y}
	for reduced: bool in [false, true]:
		for finish: String in ["complete", "owned", "escape", "close", "replaced"]:
			var already_owned := finish == "owned"
			s.items[spec.item] = already_owned
			s.native.settings.reduced_motion = reduced
			replace_state(s.duplicate(true))
			host.modal = Control.new()
			host.add_child(host.modal)
			var panel: Control = load("res://scripts/ui/c3_canteen_device_panel.gd").new()
			host.modal.add_child(panel)
			host.c3_device_panel = panel
			var original_modal: Control = host.modal
			panel.closed.connect(func(_reason: String):
				host.c3_device_panel = null
				host.modal = null
				if is_instance_valid(original_modal): original_modal.queue_free())
			var calls := {"count":0}
			var dispatch := func(action: String, value: Variant):
				calls.count += 1
				var before: Dictionary = source.d.duplicate(true)
				var result: Dictionary = chapter.dispatch(source.d, action, value)
				performance.sync(source.d, true)
				source.action_completed.emit(action, before, source.d.duplicate(true), result)
				return result
			check(panel.setup("drink:"+str(spec.target), func(): return source.d, dispatch), "real native drink panel opens at its authored source position")
			panel.set_process(false)
			for viewport:Vector2 in [Vector2(1280,720),Vector2(960,540),Vector2(390,844),Vector2(430,860),Vector2(844,390)]:
				panel.configure_layout(viewport,viewport.x<1100)
				var bay:=Rect2(panel._dispense_center()+Vector2(-78,-68),Vector2(156,151))
				check(panel.board.encloses(bay), "fixed dispenser bay stays fully inside each source device board")
				check(panel.dispense_view.position+panel.dispense_view.size/2==panel._dispense_center(), "bottle and fixed source spout share one closeup anchor")
			panel.configure_layout(Vector2(960,540),false)
			panel._take()
			check(source.d.items[spec.item] and playing_count() == 0, "real panel grants immediately while suppressing the world overlay")
			check(panel.dispensing == not already_owned and not performance.slots[spec.item].waiting, "only a returned accepted controller result starts panel-owned frames")
			panel._take(); panel.controls.take.pressed.emit()
			check(calls.count == 1, "repeat Take input cannot redispatch during accepted frames or dismissed panel")
			if not already_owned:
				check(panel.active and panel.visible and panel.dispense_view.visible and panel.controls.take.disabled, "accepted closeup is visible and locks only repeat Take")
				check(panel.dispenser_texture!=null and panel.dispenser_texture.get_size()==Vector2(1254,1254), "closeup retains original dispenser source texture")
				check(panel.dispense_reduced == reduced and panel.dispense_region.region == DrinkMotion.frame_region(7 if reduced else 0), "real panel selects normal first frame or reduced stable pose")
				var granted := source.d.duplicate(true)
				panel._process(.08)
				check(panel.dispense_region.region == DrinkMotion.frame_region(7 if reduced else 1), "panel advances authored frames without moving its sprite")
				match finish:
					"complete":
						if not reduced:
							for frame in range(2, 8):
								panel._process(.08)
								check(panel.active and panel.dispense_region.region == DrinkMotion.frame_region(frame), "normal closeup visits each actual atlas cell")
								var shader_material:ShaderMaterial=panel.dispense_view.material
								check(shader_material.get_shader_parameter("atlas_cell")==Vector2(frame%4,floori(frame/4.0)), "liquid color mask follows each actual atlas cell")
								check(float(shader_material.get_shader_parameter("fill_top"))==float([112,112,98,88,79,70,67,67][frame]), "liquid tint tracks the authored fill height without changing pose geometry")
								check(shader_material.get_shader_parameter("liquid_color")==panel.DRINKS[spec.item].color, "each bottle uses its original controller drink color")
						panel._process(.079)
						check(panel.active and panel.dispensing, "accepted tail stays visible until its exact 640/160 ms end")
						panel._process(.002)
					"escape":
						var event := InputEventKey.new(); event.keycode = KEY_ESCAPE; event.pressed = true
						panel._input(event)
					"close": panel.controls.cancel.pressed.emit()
					"replaced": source.d = source.d.duplicate(true); panel._process(0)
				check(not panel.active and not panel.dispensing and not panel.dispense_view.visible, "completion, Escape, Close, or state replacement cancels only the optional tail")
				check(source.d == granted and calls.count == 1, "closeup never mutates controller facts or dispatches a completion reward")
			await process_frame
			performance.sync(source.d, true)
			performance._process(0)
			check(not is_instance_valid(host.modal) and playing_count() == 0 and not performance.slots[spec.item].waiting, "real panel removal cannot replay a second world dispense")
			performance.cancel()

func _test_art() -> void:
	var art := Image.new()
	var load_error := art.load_png_from_buffer(FileAccess.get_file_as_bytes(DrinkMotion.ATLAS_PATH))
	check(load_error == OK and not art.is_empty(), "registered dispense art exists")
	if load_error != OK or art.is_empty(): return
	check(art.get_size() == Vector2i(512,256), "exact eight-cell atlas size")
	check(art.get_format() == Image.FORMAT_RGBA8, "genuine RGBA8 rather than a painted transparency grid")
	var unique: Dictionary = {}
	for i in range(8):
		var cell := art.get_region(Rect2i(DrinkMotion.frame_region(i)))
		unique[cell.get_data().hex_encode().sha256_text()] = true
		check(cell.get_used_rect().has_area(), "frame has visible bottle or liquid")
		check(Rect2i(1,1,126,126).encloses(cell.get_used_rect()), "registered cell leaves clear pixel gutters")
		for xy: Vector2i in [Vector2i(0,0),Vector2i(127,0),Vector2i(0,127),Vector2i(127,127)]:
			check(cell.get_pixelv(xy).a == 0, "each cell has transparent corners")
	check(unique.size() == 8, "all eight fill stages are independently rastered")

func _test_full_shell() -> void:
	# This is intentionally the production autoload, scene and State.act path.
	# It catches ordering differences hidden by the custom-dispatch fixtures.
	check(ProjectSettings.globalize_path("user://").begins_with("/tmp/"), "full-shell regression isolates native persistence")
	if not ProjectSettings.globalize_path("user://").begins_with("/tmp/"): return
	var native_state: Node = root.get_node("State")
	native_state.developer_mode = true
	var chapter: RefCounted = load("res://scripts/chapters/chapter3.gd").new()
	root.size = Vector2i(1280,720)
	var shell: Control
	var drink_events: Array = []
	var record_action := func(action: String, _before: Dictionary, _next: Dictionary, _result: Dictionary):
		if action.begins_with("c3_drink_take:"): drink_events.append(action)
	native_state.action_completed.connect(record_action)
	for reduced: bool in [false, true]:
		for spec: Dictionary in DrinkMotion.MACHINES:
			native_state.d = native_state.initial()
			var s: Dictionary = native_state.d
			s.native.chapter = 3
			s.native.scene = "canteen_interior"
			s.native.page = "c3_canteen"
			s.native.mode = "light"
			s.native.settings.reduced_motion = reduced
			s.native.settings.music = false
			s.native.settings.effects = false
			s.canteenHunt.active = true
			s.canteenHunt.phase = "tray_search"
			s.canteenHunt.entryPaperEscaped = true
			s.actOne.movementEnabled = true
			s.actOne.phase = "complete"
			s.runtimeMode = "rpg"
			s.rpgScene = "canteen_interior"
			var definition: Dictionary = chapter.get_definition("canteen_interior", spec.target, s)
			var point: Dictionary = definition.get("stand", {"x":definition.x,"y":definition.y})
			s.native.player = {"x":point.x,"y":point.y,"scene":"canteen_interior"}
			if not is_instance_valid(shell):
				shell = load("res://scenes/main.tscn").instantiate()
				root.add_child(shell)
			else:
				native_state.changed.emit()
			await process_frame
			await process_frame
			shell._show_world_mobile()
			shell.world.player = Vector2(point.x,point.y)
			shell.world._sync_player()
			shell.world._update_camera()
			var observer: Node2D = shell.world.native_canteen.drink_performance
			observer.set_process(false)
			check(is_same(observer.bound_state, s) and observer._context_available(), "real Main binds a visible live canteen observer")
			for finish: String in ["complete", "owned", "escape", "owned", "close", "owned"]:
				var already_owned := finish == "owned"
				if not already_owned:
					s.items[spec.item] = false
					native_state.changed.emit()
					await process_frame
				var count: int = observer.observed_accepts
				var opened: Dictionary = native_state.act("c3_target:"+str(spec.target))
				check(opened.get("open_canteen_device", "") == "drink:"+str(spec.target) and is_instance_valid(shell.c3_device_panel), "real State.act opens its native drink modal")
				if not is_instance_valid(shell.c3_device_panel): continue
				await process_frame
				var panel: Control = shell.c3_device_panel
				panel.set_process(false)
				var events_before: int = drink_events.size()
				# This real Button calls panel._take, whose dispatch is State.act.
				# Do not sync the observer or replace that production callback.
				panel.controls.take.pressed.emit()
				check(s.items[spec.item], "real State.act grants item before deferred Main refresh")
				check(shell.rebuild_pending and is_instance_valid(shell.modal), "real accepted action leaves Main refresh deferred while modal owns presentation")
				check(panel.dispensing == not already_owned and observer.observed_accepts == count, "accepted real panel owns playback while world observer discards its grant")
				check(not observer.slots[spec.item].waiting and not observer.sprites[spec.item].visible, "full shell never queues a duplicate world pour")
				panel._take(); panel.controls.take.pressed.emit()
				check(drink_events.size() == events_before + 1, "real repeated clicks invoke State.act exactly once")
				if not already_owned:
					check(panel.active and panel.dispense_view.is_visible_in_tree() and panel.controls.take.disabled, "real closeup remains visible after immediate inventory grant")
					await process_frame
					observer._process(0)
					check(is_instance_valid(shell.modal) and panel.dispensing and not observer.sprites[spec.item].visible, "deferred Main refresh preserves panel closeup and keeps world overlay suppressed")
					panel._process(.08)
					check(panel.dispense_region.region == DrinkMotion.frame_region(7 if reduced else 1), "real shell displays authored frames or the stable reduced pose")
					var inventory: Dictionary = s.items.duplicate(true)
					match finish:
						"complete": panel._process(.6)
						"escape":
							var event := InputEventKey.new(); event.keycode = KEY_ESCAPE; event.pressed = true
							panel._input(event)
						"close": panel.controls.cancel.pressed.emit()
					check(not panel.active and not panel.dispensing and s.items == inventory, "real completion or user dismissal preserves the immediate inventory result")
				await process_frame
				await process_frame
				observer._process(0)
				check(not is_instance_valid(shell.modal) and not is_instance_valid(shell.c3_device_panel), "real deferred close removes the Main modal after tail or dismissal")
				check(not observer.slots[spec.item].playing and not observer.slots[spec.item].waiting and not observer.sprites[spec.item].is_visible_in_tree(), "closing or reopening an owned drink never replays its accepted world grant")
				check(s.items[spec.item] and drink_events.size() == events_before + 1, "tail completion and dismissal dispatch no additional inventory action")

	native_state.action_completed.disconnect(record_action)
	if is_instance_valid(shell):
		await shell.shutdown()
		shell.queue_free()
		await process_frame
