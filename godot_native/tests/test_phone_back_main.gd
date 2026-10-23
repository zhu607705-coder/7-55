extends SceneTree
## Exercise Main's real unhandled-key path, not direct back-navigation calls.
## validate_native.mjs supplies an isolated project/user:// for all saves.
var shell: Control
var state: Node
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func frames(count: int = 4) -> void:
	for index in range(count): await process_frame

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PHONE MAIN BACK: " + message)

func escape() -> void:
	# Preserve the current GUI focus: focused app controls must still allow the
	# ordinary unhandled-key route. Never invoke Main's handler directly.
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = KEY_ESCAPE
		event.physical_keycode = KEY_ESCAPE
		event.pressed = down
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await frames(1)
	await frames()

func fixture(page: String, network: String = "campus_wifi", ready: bool = true) -> void:
	shell.audio_director.reset()
	state.d = state.initial()
	state.developer_mode = true
	state.d.native.chapter = 2
	state.d.native.scene = "dorm_hub"
	state.d.native.page = page
	state.d.runtimeMode = "phone"
	state.d.rpgScene = "dorm_hub"
	state.d.networkMode = network
	state.d.actOne.phase = "movement_required"
	state.d.actOne.inventoryRecovered = true
	# Later-chapter Tiyi requires the already-installed client; this fixture
	# checks navigation after that gate, not installation or network bypass.
	if page == "tiyi": state.d.actOne.tiyiUpdateStage = "installed"
	state.d.items.campusCard = true
	shell.mobile_world = false
	shell._refresh()
	await frames()
	if ready:
		shell._process(1.6)
		await frames()
	shell.world.set_process(false)
	shell.world.set_physics_process(false)
	check(shell.phone.is_visible_in_tree() and not shell.mobile_world, "fixture shows phone: " + page)

func expect_phone(page: String, label: String) -> void:
	check(str(state.d.native.page) == page, label + " reaches " + page)
	check(state.d.runtimeMode == "phone" and not shell.mobile_world, label + " stays on the phone")
	check(str(state.d.native.scene) == "dorm_hub", label + " retains the existing world scene")

func focus_named(name_value: String) -> void:
	var control: Control = shell.page_body.find_child(name_value, true, false)
	check(is_instance_valid(control), "rendered navigation exists: " + name_value)
	if is_instance_valid(control): control.grab_focus()

func run() -> void:
	state = root.get_node("State")
	state.developer_mode = true
	state.d = state.initial()
	shell = load("res://scenes/main.tscn").instantiate()
	root.add_child(shell)
	await frames(5)
	shell.set_process(false)
	for viewport: Vector2i in [Vector2i(1440,900), Vector2i(390,844)]:
		root.size = viewport
		shell.size = Vector2(viewport)
		await frames()
		# Distinct pages and internal subviews all use their visible back action.
		await fixture("library_record")
		await escape()
		expect_phone("library_app", "library child Escape")
		await escape()
		expect_phone("zjuding", "library root Escape")
		await escape()
		expect_phone("phone_home", "Zjuding root Escape")
		await escape()
		check(shell.mobile_world and state.d.runtimeMode == "rpg" and shell.world_frame.is_visible_in_tree(), "only homepage Escape returns to the retained map")
		check(str(state.d.native.scene) == "dorm_hub" and state.d.items.campusCard, "map return preserves scene and inventory")

		await fixture("settings")
		shell.phone_builder.settings_page = "about"
		shell._refresh()
		await frames()
		focus_named("SettingsBack")
		await escape()
		expect_phone("settings", "settings child Escape")
		check(shell.phone_builder.settings_page == "root", "settings Escape closes only the selected section")
		await escape()
		expect_phone("phone_home", "settings root Escape")

		await fixture("zjuding")
		shell.phone_builder.zjuding_panel = "contacts"
		shell._refresh()
		await frames()
		await escape()
		expect_phone("zjuding", "Zjuding internal panel Escape")
		check(shell.phone_builder.zjuding_panel.is_empty(), "Zjuding child returns to its hub")

		for page: String in ["wechat", "weather", "photos", "bonsai"]:
			await fixture(page)
			await escape()
			expect_phone("phone_home", page + " root Escape")
		# Sports running state never changes the app's navigation contract.
		for started: bool in [false, true]:
			for ready: bool in [false, true]:
				await fixture("tiyi", "cellular", ready)
				state.d.actOne.exerciseStarted = started
				focus_named("PhoneNav_exit" if ready else "TiyiLoadingExit")
				await escape()
				expect_phone("phone_home", "Tiyi loading/ready Escape")
				check(state.d.actOne.exerciseStarted == started, "Tiyi Escape preserves running state")

		await fixture("settings")
		shell._on_phone_page("control_center")
		await frames()
		check(state.d.ui.controlCenterOpen and is_instance_valid(shell.control_center), "Control Center is an actual foreground sibling")
		await escape()
		check(not state.d.ui.controlCenterOpen and not is_instance_valid(shell.control_center), "first Escape closes Control Center")
		expect_phone("settings", "Control Center Escape")
		await escape()
		expect_phone("phone_home", "second Escape leaves underlying app")

		# A host-owned activity without its own Escape handler must not be
		# replaced by app navigation; individual games keep their own handlers.
		await fixture("settings")
		var activity := Control.new()
		activity.name = "PhoneBackActivityGuard"
		shell.add_child(activity)
		shell.active_game = activity
		await escape()
		check(is_instance_valid(activity) and shell.active_game == activity, "Main does not dismiss active_game on Escape")
		expect_phone("settings", "active-game Escape")
		shell.active_game = null
		activity.queue_free()
		await frames()

		# Later phone builders participate through their rendered button meta.
		await fixture("c35_recovery")
		focus_named("C35IntroBack")
		await escape()
		expect_phone("phone_home", "recovery introduction Escape")
		await fixture("c35_photos")
		focus_named("PhoneAppBack")
		await escape()
		expect_phone("c35_recovery", "recovery photos Escape")
		await fixture("c3_journal_camera")
		focus_named("JournalBack")
		await escape()
		expect_phone("c3_journal", "journal camera Escape")
		focus_named("JournalBack")
		await escape()
		expect_phone("phone_home", "journal root Escape")

		await fixture("phone_home")
		state.d.native.scene = ""
		shell._refresh()
		await frames()
		await escape()
		check(state.d.native.page == "phone_home" and not shell.mobile_world and state.d.runtimeMode == "phone", "homepage without a saved world does not invent a map")
		check(shell.phone.size == Vector2(430,860), "navigation retains canonical phone dimensions")
	await shell.shutdown()
	shell.queue_free()
	await frames(3)
	print("Phone Main Escape navigation: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
