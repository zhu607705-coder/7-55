extends SceneTree
## Focused controller/component acceptance. This is not a campaign traversal.
const Chapter = preload("res://scripts/chapters/chapter3.gd")
const Session = preload("res://scripts/media/c3_charging_session.gd")
const Effect = preload("res://scripts/media/c3_charging.gd")
const View = preload("res://scripts/media/c3_charging_view.gd")
var checks := 0
var failures := 0
var state: Dictionary
var controller: RefCounted
var effect: Control
var event_count := 0
func _initialize() -> void: run.call_deferred()
func frames(count := 3) -> void:
	for i in count: await process_frame
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func fixture(reduced := false) -> void:
	state = root.get_node("State").initial()
	state.native.chapter = 3; state.native.page = "c3_theater"; state.native.scene = "theater_interior"; state.native.mode = "light"
	state.native.player = {"x": 665.0, "y": 790.0}
	state.native.settings.reduced_motion = reduced
	state.native.host = {"phone_modal_open": false, "minigame_open": false, "focused": true, "world_visible": true}
	state.rpgScene = "theater_interior"; state.runtimeMode = "rpg"; state.theaterHunt.active = true
	state.theaterHunt.phase = "program_search"
	state.phoneBattery.percent = 7; state.phoneBattery.rechargeCount = 0
	controller = Chapter.new(); event_count = 0
func mount(with_controller := true, receipt_handler: Callable = Callable()) -> void:
	var request: Dictionary = controller.dispatch(state, "c3_target:theater_charging_station")
	check(request.has("world_effect"), "unchanged controller grants a physical station session")
	if not request.has("world_effect"): return
	effect = Effect.new(); effect.size = Vector2(390, 660); root.add_child(effect)
	effect.event.connect(func(action: String, value: Variant):
		event_count += 1
		if receipt_handler.is_valid(): receipt_handler.call(value)
		elif with_controller: controller.dispatch(state, action, value)
	)
	var config: Dictionary = request.world_effect.duplicate()
	config.read_state = func() -> Dictionary: return state
	config.project_position = func(_point: Vector2) -> Vector2: return Vector2(195, 355)
	effect.setup(config)
func clean() -> void:
	if is_instance_valid(effect): effect.cancel()
	await frames()
func wait_report(ms := 3500) -> bool:
	var deadline := Time.get_ticks_msec() + ms
	while is_instance_valid(effect) and not effect.reported and Time.get_ticks_msec() < deadline: await process_frame
	return is_instance_valid(effect) and effect.reported
func run() -> void:
	root.get_node("State").developer_mode = true
	create_timer(45).timeout.connect(func(): push_error("Charging feedback watchdog"); quit(2))
	fixture()
	for point: Vector2 in [Vector2(679.5, 773), Vector2(510.5, 773), Vector2(595, 865.5), Vector2(595, 680.5), Vector2(666, 852)]:
		state.native.player = {"x": point.x, "y": point.y}
		check(Session.rejection(state).is_empty(), "station uses the full 77x93 rectangle plus 46px reach: %s" % point)
	for point: Vector2 in [Vector2(679.6, 773), Vector2(510.4, 773), Vector2(595, 865.6), Vector2(595, 680.4), Vector2(666.1, 852.1)]:
		state.native.player = {"x": point.x, "y": point.y}
		check(Session.rejection(state) == "too_far", "station rejects points outside its rounded rectangle reach: %s" % point)
	for elapsed in [0.0, 90.0, 180.0, 1100.0, 2199.0, 2200.0]:
		var pose: Dictionary = View.pose(elapsed, "", 0, 7, false)
		check(pose.battery == 7, "elapsed time never invents battery at %s" % elapsed)
		check(pose.progress == int(elapsed / 22.0), "connection has a separate progress percentage")
		check(pose.flow == (elapsed >= 180), "current begins only after connector insertion")
	check(View.pose(90, "", 0, 7, false).insert > 0 and View.pose(90, "", 0, 7, false).insert < 1, "connector has a real intermediate alignment pose")
	for interrupted_ms in [0.0, 90.0, 179.0]:
		var inserted: float = View.pose(interrupted_ms, "", 0, 7, false).insert
		check(is_equal_approx(View.pose(interrupted_ms, "cancelled", 0, 7, false).insert, inserted), "early cancellation begins at the current connector pose")
		check(View.pose(interrupted_ms, "cancelled", 120, 7, false).insert <= inserted, "early cancellation withdraws without first inserting farther")
	check(View.pose(2200, "success", 640, 45, false).insert < 1, "success withdraws after the actual result hold")
	check(not View.pose(100, "cancelled", 120, 7, false).flow, "cancellation stops all current particles")
	check(View.pose(1100, "", 0, 7, true).flow_step == View.pose(2000, "", 0, 7, true).flow_step, "reduced motion does not animate current particles")
	for extent: Vector2 in [Vector2(390, 660), Vector2(844, 286), Vector2(960, 540)]:
		var view := View.new(); root.add_child(view)
		for anchor: Vector2 in [Vector2(0, 0), extent / 2, extent]:
			view.present(extent, anchor, 1000, "", 0, 7, false)
			check(Rect2(Vector2.ZERO, extent).encloses(view.panel_rect), "close-up stays contained at edges for %s" % extent)
			check(is_equal_approx(view.panel_rect.size.x, View.PANEL_SIZE.x), "target viewports do not shrink the readable close-up")
		check(view.mouse_filter == Control.MOUSE_FILTER_IGNORE and view.focus_mode == Control.FOCUS_NONE, "view has no input or focus owner")
		view.queue_free()
	await frames()
	for reduced in [false, true]:
		fixture(reduced)
		controller.dispatch(state, "c3_charge_result", {"elapsed_ms": 2200, "success": true})
		check(state.phoneBattery.percent == 7, "forged completion cannot recharge")
		mount()
		check(effect.uses_responsive_exploration(), "station opts into existing responsive exploration")
		var session: RefCounted = effect.session
		await create_timer(0.35).timeout
		check(state.phoneBattery.percent == 7 and effect.view.presentation.battery == 7 and effect.view.presentation.progress > 0, "running progress remains distinct from actual battery")
		check(await wait_report(), "real source clock reaches its terminal receipt")
		check(session.phase == "consumed" and state.phoneBattery.percent == 45 and state.phoneBattery.rechargeCount == 1, "real controller consumes receipt and writes45 once")
		check(effect.terminal == "success" and effect.view.presentation.battery == 45, "success appears only after the actual write")
		controller.dispatch(state, "c3_charge_result", session)
		check(state.phoneBattery.rechargeCount == 1 and event_count == 1, "repeat callbacks cannot award or report twice")
		await create_timer(0.85).timeout
		check(not is_instance_valid(effect), "successful cable leaves no residual view")
	for reason in ["distance", "mode", "scene", "page", "focus", "phone", "minigame", "hidden", "control_center"]:
		fixture(); mount(); var session: RefCounted = effect.session
		await create_timer(0.06).timeout
		match reason:
			"distance": state.native.player.x = 740.0
			"mode": state.native.mode = "dark"
			"scene": state.native.scene = "campus_bootstrap"
			"page": state.native.page = "phone_home"
			"focus": state.native.host.focused = false
			"phone": state.native.host.phone_modal_open = true
			"minigame": state.native.host.minigame_open = true
			"hidden": state.native.host.world_visible = false
			"control_center": state.ui.controlCenterOpen = true
		await frames()
		check(session.phase == "cancelled" and state.phoneBattery.percent == 7 and state.phoneBattery.rechargeCount == 0, "source guard cancels without gain: " + reason)
		check(event_count == 1, "cancellation reports exactly once: " + reason)
		if is_instance_valid(effect): check(effect.terminal == "cancelled" and not effect.view.presentation.flow, "only withdrawal remains after cancellation")
		await create_timer(0.3).timeout
		check(not is_instance_valid(effect), "interruption leaves no view: " + reason)
	fixture(); mount(false)
	check(await wait_report(), "unaccepted complete receipt reaches presentation handoff")
	check(effect.terminal == "cancelled" and state.phoneBattery.percent == 7, "elapsed completion without controller acceptance never shows success")
	await clean()
	# Deliberately incomplete receiver transactions isolate every presentation guard.
	# These tests consume a real elapsed receipt but never use the real controller.
	for mutation in ["receipt_only", "missing_count", "wrong_battery", "extra_count"]:
		fixture()
		mount(false, func(receipt: RefCounted):
			check(receipt.consume(state), "guard fixture consumes a genuine complete receipt")
			match mutation:
				"missing_count": state.phoneBattery.percent = 45
				"wrong_battery": state.phoneBattery.percent = 44; state.phoneBattery.rechargeCount = 1
				"extra_count": state.phoneBattery.percent = 45; state.phoneBattery.rechargeCount = 2
		)
		check(await wait_report(), "incomplete transaction reaches its terminal report: " + mutation)
		check(effect.session.phase == "consumed" and effect.terminal == "cancelled", "receipt alone cannot replace the exact count and actual 45 percent: " + mutation)
		check(effect.view.presentation.battery == state.phoneBattery.percent and not effect.view.presentation.flow, "rejected success still displays only actual battery: " + mutation)
		await clean()
	fixture(); mount(); var disposed_session: RefCounted = effect.session
	effect.queue_free(); await frames()
	check(disposed_session.phase == "cancelled" and event_count == 1, "tree disposal cancels and reports once")
	for focus_notification in [Control.NOTIFICATION_APPLICATION_FOCUS_OUT, Control.NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
		fixture(); mount(); var focus_session: RefCounted = effect.session
		effect.notification(focus_notification); await frames()
		check(focus_session.phase == "cancelled" and state.phoneBattery.percent == 7 and not is_instance_valid(effect), "actual application or window focus notification cancels immediately")
	fixture(); mount(); await create_timer(0.15).timeout
	var before_pause: float = effect.session.elapsed_ms
	paused = true; await create_timer(0.2, true).timeout
	check(effect.session.elapsed_ms == before_pause and state.phoneBattery.percent == 7, "tree pause freezes sampling and never completes in background")
	paused = false; await frames()
	check(effect.session.elapsed_ms - before_pause <= 140 and effect.terminal.is_empty(), "resume retains the source clock cap without inventing a terminal result")
	await clean()
	print("CHARGING_FEEDBACK ", checks, " checks; ", failures, " failures")
	quit(1 if failures else 0)
