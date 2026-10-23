extends SceneTree
## Real Main UI and controller receipts; fixtures do not claim a campaign run.
const Session = preload("res://scripts/media/c3_charging_session.gd")
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
func fixture(page := "phone_home", percent := 0, low := true) -> void:
	state.d = state.initial(); state.developer_mode = true
	state.d.native.page = page; state.d.currentScene = page
	state.d.native.wake_warned = true
	state.d.native.settings.music = false; state.d.native.settings.effects = false
	state.d.phoneBattery.percent = percent; state.d.phoneBattery.lowPowerMode = low; state.d.ui.brightness = 32
	state.changed.emit()
func click(id: String) -> void:
	var button := shell.find_child(id, true, false) as Control
	check(button != null and button.is_visible_in_tree(), "real UI contact exists: " + id)
	if button == null: return
	var point := button.get_global_transform_with_canvas() * (button.size / 2)
	var motion := InputEventMouseMotion.new(); motion.position = point; motion.global_position = point; root.push_input(motion)
	for down in [true, false]:
		var event := InputEventMouseButton.new(); event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down; event.position = point
		event.global_position = point; root.push_input(event); await frames(1)
	await frames()
func wait_charge() -> void:
	var deadline := Time.get_ticks_msec() + 4000
	while state.d.phoneBattery.rechargeCount == 0 and Time.get_ticks_msec() < deadline: await process_frame
	await frames()

func run() -> void:
	state = root.get_node("State"); state.developer_mode = true
	create_timer(55).timeout.connect(func(): push_error("early charge watchdog"); quit(2))
	var reserves: Array = []
	state.battery_reserve_used.connect(func(percent): reserves.append(percent))
	for percent in [0, 1, 17]:
		for low in [false, true]:
			fixture("phone_home", percent, low)
			for page in ["wechat", "phone_home", "bonsai", "phone_home", "settings", "phone_home"]:
				state.open_page(page)
				check(state.d.phoneBattery.percent == percent, "app navigation preserves %d%% / low=%s" % [percent, low])
	check(reserves.is_empty(), "free app navigation never pretends to spend reserve")
	for percent in [0, 1, 2, 17]:
		fixture("phone_home", percent, false); state.act("c1_network", "cellular")
		check(state.d.phoneBattery.percent == mini(percent, maxi(1, percent - 1)), "network still spends1 without manufacturing0 reserve")
		if percent <= 1: check(reserves.back() == percent, "reserve observation carries actual0/1, never a fake1-percent prank")
	# Portable saves use the ordinary disk envelope, not dictionary assignment.
	for percent in [0, 1]:
		fixture("bonsai", percent, true)
		var before: Dictionary = state.d.duplicate(true)
		var path := "user://low-battery-portable.json"
		check(state.export_save(path) == OK, "0/1 snapshot exports through real validator")
		state.d = state.initial()
		check(state.import_save(path).get("ok", false), "0/1 portable import accepted")
		check(int(state.d.phoneBattery.percent) == int(before.phoneBattery.percent) and state.d.phoneBattery.lowPowerMode == before.phoneBattery.lowPowerMode and int(state.d.phoneBattery.rechargeCount) == int(before.phoneBattery.rechargeCount) and JSON.stringify(state.d.flags) == JSON.stringify(before.flags) and JSON.stringify(state.d.items) == JSON.stringify(before.items) and state.d.ui.brightness == 32, "portable import preserves battery, mode, brightness and story")
		state.developer_mode = true
	root.size = Vector2i(390, 844); fixture()
	shell = load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(8)
	for page in ["phone_home", "bonsai"]:
		fixture(page); await frames(8)
		var before: Dictionary = state.d.duplicate(true)
		await click("PutPhoneOnDesk")
		check(state.d.native.page == "desktop" and shell.find_child("WakeNarration", true, false) == null, "putdown opens physical desk without replaying wake: " + str(state.d.native.page) + " / " + str(state.last_result))
		if state.d.native.page != "desktop": quit(1); return
		check(state.d.flags == before.flags and state.d.items == before.items, "putdown preserves puzzle progress")
		var dock := shell.find_child("DockBody", true, false) as TextureRect
		check(dock != null and dock.texture.get_image().get_size() == Vector2i(256, 256), "clean import uses256px object texture, not1254px mother")
		if dock == null: continue
		check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(dock.get_global_rect()), "small dock art stays in portrait viewport")
		await click("DeskDockContact")
		var session: RefCounted = state.get_home_charging_session()
		check(session != null and session.phase == "charging", "physical dock starts original2200ms timer")
		state.act("c1_desk_charge")
		check(state.get_home_charging_session() == session, "duplicate start cannot stack or restart receipt")
		state.act("c1_desk_charge_result", {"elapsed_ms": 2200})
		state.act("c1_desk_charge_result", session)
		check(state.d.phoneBattery.percent == 0, "forged and premature receipts cannot recharge")
		await wait_charge()
		check(state.d.phoneBattery.percent == 45 and state.d.phoneBattery.rechargeCount == 1 and not state.d.phoneBattery.lowPowerMode, "real Main charge restores45 and exits low power once")
		check(state.d.ui.brightness == 32 and state.d.flags == before.flags and state.d.items == before.items, "charge preserves brightness and every puzzle/item fact")
		state.act("c1_desk_charge_result", session)
		check(state.d.phoneBattery.rechargeCount == 1, "completed receipt cannot replay")
		# The injected duplicate receipt schedules the existing full page refresh.
		# Settle it before beginning the next real physical-button gesture.
		await frames()
		await click("DeskPhonePickup")
		check(state.d.native.page == page, "pickup resumes previous phone page: expected=" + page + " actual=" + str(state.d.native.page) + " result=" + str(state.last_result))
		state.act("c1_plant_light")
		check(not state.d.flags.plantLit and not state.d.flags.flowerBloomed, "charge alone never provides80 brightness or grows flower")
	for reason in ["cancel", "pickup", "page", "focus", "modal", "save"]:
		fixture("phone_home", 1); await frames(5); await click("PutPhoneOnDesk"); await click("DeskDockContact")
		var receipt: RefCounted = state.get_home_charging_session()
		check(receipt != null and receipt.phase == "charging", "interruption has a live receipt: " + reason)
		match reason:
			"cancel": await click("DeskUnplug")
			"pickup": await click("DeskPhonePickup")
			"page": state.open_page("phone_home")
			"focus": shell.home_charging_host._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
			"modal": shell._show_settings()
			"save":
				check(state.export_save("user://replace-desk.json") == OK, "same-page replacement fixture saves")
				check(state.import_save("user://replace-desk.json").get("ok", false), "same-page ordinary import replaces authority")
		await frames(8)
		check(receipt.phase == "cancelled" and state.d.phoneBattery.percent == 1 and state.d.phoneBattery.rechargeCount == 0, "interruption cancels without gain: " + reason)
		if reason == "save":
			check(shell.find_child("WakeNarration", true, false) == null and shell.find_child("DeskPhonePickup", true, false).is_visible_in_tree(), "reloaded physical desk never replays wake and still has pickup")
			await click("DeskPhonePickup")
			check(state.d.native.page == "phone_home", "save/import preserves bounded return page without carrying live receipt")
		state.act("c1_desk_charge_result", receipt)
		check(state.d.phoneBattery.percent == 1 and state.d.phoneBattery.rechargeCount == 0, "stale receipt rejected after " + reason)
		if reason == "modal": shell._close_modal()
	# Contexts are not interchangeable, even at a sufficient battery.
	fixture("phone_home"); state.act("c1_desk_charge")
	check(state.get_home_charging_session() == null, "phone page cannot remotely charge")
	state.d.actOne.phase = "movement_required"; state.act("c1_desk_putdown")
	check(state.d.native.page == "phone_home", "C2 cannot jump back to C1 desk")
	fixture("desktop", 87, true); await frames(5)
	await click("DeskDockContact"); await wait_charge()
	check(state.d.phoneBattery.percent == 87 and not state.d.phoneBattery.lowPowerMode and state.d.ui.brightness == 32, "sufficient battery recovery exits cap without lowering charge/altering brightness")
	await shell.shutdown(); shell.queue_free(); await frames()
	print("EARLY_CHARGING ", checks, " checks; ", failures, " failures")
	quit(1 if failures else 0)
