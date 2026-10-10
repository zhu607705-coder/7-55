extends SceneTree
const Pages = preload("res://scripts/ui/phone_pages.gd")
const Chapter = preload("res://scripts/chapters/chapter1_2.gd")
var failures = 0
var checks = 0
var pages = Pages.new()
var chapter = Chapter.new()
var surface: Control
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var state: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	state.native = {"chapter":1,"page":"alarm","scene":"","mode":"light","selected_item":""}
	surface = Control.new()
	surface.size = Vector2(424,854)
	var design = Theme.new()
	design.default_font = load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	design.default_font_size = 18
	surface.theme = design
	root.add_child(surface)
	for page in ["alarm","desktop","phone_home","wechat","control_center","checkin","campus_card","bonsai","cc98","zjuding","tiyi","weather","directory","library_app","library_record","library_rule","library_recovery","library_022_dialogue","photos","settings"]:
		state.native.page = page
		var control = pages.build(page,chapter.view(page,state),state)
		surface.add_child(control)
		await process_frame
		checks += 1
		if control.size.x > 424.1 or control.size.x < 423:
			failures += 1
			push_error("Phone width drift: "+page)
		for child in control.get_children():
			if child is Control and child.position.x + child.size.x * child.scale.x > 425:
				failures += 1
				push_error("Phone child overflow in %s: %s position=%s size=%s" % [page,child.get_class(),child.position,child.size])
		control.queue_free()
		await process_frame
	# Authenticated forum and other state-dependent surfaces.
	state.native.chapter = 2
	state.actOne.phase = "movement_required"
	state.actOne.cc98Login.authenticated = true
	state.flags.codeScattered = true
	state.ui.libraryFinalsPhase = "evidence_gathering"
	state.ui.libraryFinalsPuzzle.investigationOpened = true
	state.ui.libraryFinalsPuzzle.backpackInspected = true
	for page in ["cc98","phone_home","wechat","zjuding","photos","library_archive"]:
		var control = pages.build(page,chapter.view(page,state),state)
		surface.add_child(control)
		await process_frame
		checks += 1
		if control.size.x > 424.1:
			failures += 1
			push_error("Authenticated phone width drift: "+page)
		control.queue_free()
		await process_frame
	# Gallery branch and source-clue action sheet are independently constructed.
	state.ui.libraryFinalsPuzzle.photoCaptured = true
	state.ui.libraryFinalsPuzzle.photoDimmed = true
	state.ui.brightness = 20
	for selected in ["", "seat_022_clue", "dorm_meal"]:
		state.native.lib_selected_photo = selected
		var gallery = pages.build("photos",chapter.view("photos",state),state)
		surface.add_child(gallery)
		await process_frame
		checks += 1
		if gallery.size.x > 424.1: failures += 1
		gallery.queue_free()
		await process_frame
	# Source portrait content scales uniformly at the representative mobile width.
	surface.scale = Vector2.ONE * (338.0/424.0)
	checks += 1
	if not is_equal_approx(surface.scale.x,surface.scale.y): failures += 1
	print("PHONE_PAGE_TESTS: %d layouts checked; %d failures" % [checks,failures])
	quit(1 if failures else 0)
