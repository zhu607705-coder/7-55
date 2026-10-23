extends SceneTree
## Presentation-only dialogue, exercised through real controls and the original controller.
const Pages = preload("res://scripts/ui/phone_pages.gd")
const Chapter = preload("res://scripts/chapters/chapter1_2.gd")
var pages = Pages.new()
var controller = Chapter.new()
var state: Dictionary
var surface: Control
var view: Control
var checks = 0
var failures = 0
var actions: Array = []
var routes: Array = []

func _initialize() -> void:
	call_deferred("run")

func expect(ok: bool, why: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(why)

func fresh() -> Dictionary:
	var value: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	value.native = {"chapter":2,"page":"cc98","scene":"dorm_hub","mode":"light","selected_item":""}
	value.actOne.phase = "movement_required"
	value.actOne.inventoryRecovered = true
	value.items.campusCard = true
	value.networkMode = "campus_wifi"
	value.flags.codeScattered = true
	value.flags.checkinDone = true
	return value

func show() -> void:
	if is_instance_valid(view): view.free()
	view = pages.build("cc98",controller.view("cc98",state),state)
	surface.add_child(view)
	await process_frame
	await process_frame

func node(id: String) -> Node:
	return view.find_child(id,true,false)

func click(id: String) -> void:
	var target: Control = node(id)
	expect(target!=null and target.is_visible_in_tree(),"Visible control: " + id)
	if not target: return
	var point = target.get_global_rect().get_center()
	var move = InputEventMouseMotion.new()
	move.position = point
	move.global_position = point
	root.push_input(move,true)
	await create_timer(0.06).timeout
	for pressed in [true,false]:
		var event = InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event,true)
		await create_timer(0.06).timeout

func scroll_to_bottom() -> void:
	node("Cc98LoginScroll").scroll_vertical = 1000
	await process_frame
	await process_frame

func enter_password(value: String) -> void:
	var input: LineEdit = node("Cc98LoginPassword")
	input.text = value
	input.text_changed.emit(value)

func check_readable() -> void:
	var label: Label = node("Cc98AttendantRemark")
	expect(label.get_line_count()*label.get_line_height()<=label.size.y,"Complete spoken clue fits without clipping")
	expect(label.get_theme_font_size("font_size")>=15,"Spoken clues retain readable body size")
	expect(node("Cc98HintFragment_0")==null,"No exposed answer-fragment cards")

func capture(name: String) -> void:
	var output = OS.get_environment("CC98_DIALOGUE_CAPTURE_DIR")
	if output.is_empty() or DisplayServer.get_name()=="headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(output)
	root.get_texture().get_image().save_png(output.path_join(name+".png"))

func run() -> void:
	root.size = Vector2i(430,860)
	surface = Control.new()
	surface.position = Vector2(3,40)
	surface.size = Vector2(424,814)
	root.add_child(surface)
	pages.action_requested.connect(func(id,value):
		actions.append([id,value])
		controller.dispatch(state,id,value))
	pages.page_requested.connect(func(page): routes.append(page))
	state = fresh()
	await show()
	expect(not node("Cc98AskClearly").visible,"Assistance is not shown before an unsuccessful attempt")
	expect(node("Cc98PreviousRemark").disabled and node("Cc98NextRemark").disabled,"Unheard remarks cannot be browsed")
	expect(node("Cc98LoginExit").position.y<60,"Authentication returns through the fixed top-left action")
	check_readable()
	await capture("desktop-initial")
	await scroll_to_bottom()
	await click("Cc98ReadCampusCard")
	await show()
	expect(state.actOne.cc98Login.studentIdDiscovered and node("Cc98LoginStudentId").text=="3250100755","Existing identity intent reads and fills the campus card")
	for expected in ["ZheJiang University","1897","气势来!"]:
		var before = int(state.actOne.cc98Login.revealedHintCount)
		await click("Cc98RevealHint")
		await show()
		expect(int(state.actOne.cc98Login.revealedHintCount)==before+1,"Each reply delegates one existing hint fact")
		expect(node("Cc98AttendantRemark").text.contains(expected),"Reply embeds the authored clue")
		check_readable()
		expect(not state.actOne.cc98Login.authenticated,"Dialogue alone never authenticates")
	await capture("desktop-last-remark")
	var snapshot = JSON.stringify(state)
	var action_count = actions.size()
	await click("Cc98PreviousRemark")
	expect(node("Cc98AttendantRemark").text.contains("1897"),"Earlier spoken clues can be re-read")
	await click("Cc98PreviousRemark")
	expect(node("Cc98AttendantRemark").text.contains("ZheJiang University"),"School-name clue remains recoverable")
	await click("Cc98NextRemark")
	expect(actions.size()==action_count and JSON.stringify(state)==snapshot,"Re-reading does not emit or mutate progression")
	await click("Cc98ReturnToForm")
	expect(node("Cc98LoginScroll").scroll_vertical==0 and node("Cc98LoginPassword").has_focus(),"Return to form scrolls and focuses the password")
	for attempt in range(2):
		enter_password("wrong")
		await click("Cc98LoginSubmit")
		await show()
		expect(state.actOne.cc98Login.failureCount==attempt+1,"Original failure counter remains authoritative")
		expect(node("Cc98AskClearly").visible==(attempt==1),"Optional assistance appears after the second failure")
	await scroll_to_bottom()
	snapshot = JSON.stringify(state)
	await click("Cc98AskClearly")
	expect(node("Cc98AttendantRemark").text.contains("大写字母") and not node("Cc98AttendantRemark").text.contains("ZJU1897!"),"Requested assistance explains extraction without printing the answer")
	expect(JSON.stringify(state)==snapshot,"Assistance does not grant facts or bypass authentication")
	check_readable()
	await capture("desktop-assistance")
	# A scaled phone preserves the same geometry and all stored remarks after re-entry.
	root.size = Vector2i(390,844)
	surface.scale = Vector2.ONE*(378.0/424.0)
	surface.position = Vector2(6,40)
	pages.cc98_login.reset()
	await show()
	await scroll_to_bottom()
	expect(node("Cc98AttendantRemark").text.ends_with("!"),"Saved hint count restores the latest spoken remark")
	check_readable()
	await click("Cc98PreviousRemark")
	expect(node("Cc98AttendantRemark").text.contains("1897"),"Scaled mobile can re-read prior clues")
	await capture("mobile-year-remark")
	routes.clear()
	await click("Cc98LoginExit")
	expect(routes==["phone_home"],"Fixed exit remains reachable while conversation is scrolled")
	# The answer still works without revealing any remarks; a missing card still blocks it.
	state = fresh()
	state.items.campusCard = false
	state.actOne.inventoryRecovered = false
	pages.cc98_login.reset()
	await show()
	await scroll_to_bottom()
	await click("Cc98ReadCampusCard")
	await show()
	expect(not state.actOne.cc98Login.studentIdDiscovered and node("Cc98LoginStudentId").text.is_empty(),"Presentation never fabricates a missing identity card")
	state = fresh()
	pages.cc98_login.reset()
	await show()
	await scroll_to_bottom()
	await click("Cc98ReadCampusCard")
	await show()
	node("Cc98LoginScroll").scroll_vertical = 0
	await process_frame
	enter_password("ZJU1897!")
	await click("Cc98LoginSubmit")
	expect(state.actOne.cc98Login.authenticated and state.actOne.cc98Login.revealedHintCount==0,"Correct original credentials remain sufficient without a new dialogue gate")
	view.free()
	print("CC98_AUTH_DIALOGUE_TESTS: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
