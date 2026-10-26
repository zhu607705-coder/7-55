extends SceneTree

const Registry := preload("../registry.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func frames(count: int = 3) -> void:
	for index in count:
		await process_frame

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await frames()
	event = InputEventKey.new()
	event.keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await frames()

func pointer_click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event)
		await frames()

func text_has_glyphs(text: String, font: Font) -> bool:
	for character in text:
		if character.unicode_at(0) > 32 and not font.has_char(character.unicode_at(0)):
			return false
	return true

func run() -> void:
	var model := Registry.new()
	check(model.errors.is_empty(), "Registry loads")
	check(model.buildings().size() == 4, "Four independent buildings")
	var count := 0
	for building: Dictionary in model.buildings():
		check(building.currentTotalFloorCount == null, "No invented current total")
		var expected := 4 if building.id in ["north1", "north2"] else 5
		check(building.floors.size() == expected, "Historical sheet coverage")
		for floor_data: Dictionary in building.floors:
			count += 1
			check(not model.navigation_available(building.id, floor_data.number), "Preview never enables navigation")
			check(floor_data.geometry.status == "not_extracted", "Missing geometry stays explicit")
			for field in ["walkablePolygons", "solidPolygons", "rooms", "portals"]:
				check(floor_data.geometry[field].is_empty(), "No inferred or label-box geometry")
			check(floor_data.objectLayer.instances.is_empty(), "No invented real furnishings")
			if floor_data.number > 1:
				check(model.plate_path(building.id, floor_data.number).is_empty(), "Upper floors never reuse 1F art")
		var floor_one := model.floor_record(building.id, 1)
		var image := Image.load_from_file(model.plate_path(building.id, 1))
		check(image != null and image.get_format() == Image.FORMAT_RGBA8, "True RGBA source")
		if image != null:
			check(image.get_width() == int(floor_one.art.dimensions[0]) and image.get_height() == int(floor_one.art.dimensions[1]), "Approved source dimensions")
			var bytes := image.get_data()
			var transparent := 0
			var opaque := 0
			var other := 0
			for offset in range(3, bytes.size(), 4):
				if bytes[offset] == 0: transparent += 1
				elif bytes[offset] == 255: opaque += 1
				else: other += 1
			check(transparent > 0 and opaque > 0 and other == 0, "Approved binary exterior alpha retained")
	check(count == 18, "18 documented sheets, not 18 implemented levels")
	var detached := model.building("north1")
	detached.floors.clear()
	check(model.building("north1").floors.size() == 4, "Registry callers cannot mutate source data")
	check(model.floor_record("unknown", 1).is_empty() and model.floor_record("north1", 99).is_empty(), "Unknown IDs fail closed")
	var view: Control = load("res://preview.tscn").instantiate()
	root.add_child(view)
	await frames()
	check(root.get_node_or_null("State") == null, "No formal State autoload")
	check(view.building_picker.has_focus(), "Keyboard focus starts on building selection")
	for building: Dictionary in model.buildings():
		check(view.select_building(building.id), "Select building")
		await frames()
		check(view.plate.texture != null, "First-floor texture loads")
		check(view.floor_picker.item_count == building.floors.size(), "Floor selector follows source coverage")
		var initial_texture: Texture2D = view.plate.texture
		check(text_has_glyphs(view.detail_text.text, view.theme.default_font), "Source copy has bundled font coverage")
		for number in range(2, building.floors.size() + 1):
			check(view.select_floor(number), "Each historical floor can be inspected")
			check(view.plate.texture == null and view.empty_notice.visible, "Unavailable floor clears stale artwork")
			check(view.zoom_in.disabled and view.fit_button.disabled, "No image controls for empty floor")
		check(not view.select_floor(99) and view.floor_number == building.floors.size(), "Invalid selection does not change state")
		view.select_floor(1)
		check(view.plate.texture == initial_texture, "Returning restores correct building art")
	check(not view.select_building("bad") and view.building_id == "north4", "Unknown building does not alter selection")
	for dimension in [Vector2i(1280, 820), Vector2i(390, 844), Vector2i(844, 540), Vector2i(360, 640)]:
		root.size = dimension
		await frames(5)
		for control: Control in [view.building_picker, view.floor_picker, view.source_button, view.status, view.drawing_panel]:
			check(Rect2(Vector2.ZERO, dimension).encloses(control.get_global_rect()), "Visible control inside viewport " + str(dimension))
		check(view.drawing_panel.size.y >= 120, "Image remains inspectable at each viewport")
		var rect: Rect2 = view.plate.image_rect()
		check(is_equal_approx(rect.size.x / rect.size.y, 1448.0 / 1086.0), "Uniform source aspect ratio")
		view.plate.set_zoom(9)
		check(view.plate.zoom == 4, "Zoom upper bound")
		view.plate.pan = Vector2(1e6, -1e6)
		view.plate.set_zoom(4)
		check(view.plate.image_rect().has_point(view.plate.size / 2), "Panning cannot lose the plate")
		view.plate.reset_view()
		check(view.plate.zoom == 1 and view.plate.pan == Vector2.ZERO, "Fit resets only presentation")
		view.source_button.grab_focus()
		await key(KEY_ENTER)
		check(view.detail_panel.visible and not view.drawing_panel.visible, "Real keyboard Enter opens source view")
		await key(KEY_ESCAPE)
		check(not view.detail_panel.visible and view.drawing_panel.visible, "Esc dismisses source view without changing floor")
		check(view.source_button.has_focus(), "Back restores keyboard focus")
		await pointer_click(view.source_button)
		check(view.detail_panel.visible, "Actual routed pointer click opens sources")
		check(Rect2(Vector2.ZERO, dimension).encloses(view.detail_panel.get_global_rect()), "Source scroll fits viewport")
		await pointer_click(view.source_button)
		check(view.drawing_panel.visible and not view.detail_panel.visible, "Pointer return restores image")
		for repetition in 3:
			view.toggle_sources()
			view.toggle_sources()
		check(view.floor_number == 1 and view.building_id == "north4", "Repeated source open/close preserves selection")
		await capture(view, "north4-%dx%d" % [dimension.x, dimension.y])
	view.plate.set_zoom(2)
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	view.plate._gui_input(touch)
	check(view.plate.touch_index == 0, "Primary touch owns pan")
	var drag := InputEventScreenDrag.new()
	drag.index = 1
	drag.relative = Vector2(12, 12)
	view.plate._gui_input(drag)
	check(view.plate.pan == Vector2.ZERO, "Second finger does not steal primary pan")
	drag.index = 0
	view.plate._gui_input(drag)
	check(view.plate.pan != Vector2.ZERO, "Primary touch changes display transform")
	view.plate.notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(view.plate.touch_index == -1 and not view.plate.dragging, "Interrupted input cancels drag ownership")
	view.plate.reset_view()
	root.size = Vector2i(1280, 820)
	await frames(5)
	for id in ["north1", "north2", "north3", "north4"]:
		view.select_building(id)
		await frames(5)
		await capture(view, id + "-desktop")
	view.select_floor(5)
	await frames()
	await capture(view, "north4-floor5-unavailable")
	view.toggle_sources()
	await frames()
	await capture(view, "north4-floor5-source")
	view.queue_free()
	await frames()
	print("North real-plan preview: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func capture(_view: Control, name: String) -> void:
	var directory := OS.get_environment("NORTH_PREVIEW_CAPTURE_DIR")
	if directory.is_empty():
		return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image != null and not image.is_empty(), "Actual rendered image " + name)
	if image != null:
		check(image.save_png(directory.path_join(name + ".png")) == OK, "Capture write " + name)
