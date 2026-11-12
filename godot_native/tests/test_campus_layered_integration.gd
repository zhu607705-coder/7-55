extends SceneTree
const Overlay = preload("res://scripts/ui/world_overlay_layout.gd")

var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func frames() -> void:
	for _i in range(5): await process_frame

func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():
		push_error("Campus integration needs an isolated save directory")
		quit(1)
		return
	var state: Node = root.get_node("State")
	state.developer_mode = false
	state.SAVE_PATH = "user://layered-campus-test.json"
	state.BACKUP_PATH = "user://layered-campus-test.previous.json"
	state.d = state.initial()
	state.d.native.chapter = 2
	state.d.native.page = "zjuding"
	state.d.currentScene = "zjuding"
	state.d.actOne.dormHubUnlocked = true
	state.d.actOne.phase = "movement_ready"
	state.d.actOne.movementEnabled = true
	state.d.actOne.canLeaveDorm = true
	state.d.actOne.manualControlTested = true
	root.size = Vector2i(1280,720)
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	check(str(state.act("c2_enter_dorm").get("message", "")).begins_with("紫云五舍\n"), "ordinary dorm entry names Ziyun 5")
	await frames()
	check(main.world.scene_id == "dorm_hub" and not main.world_mode.visible, "dorm uses the regular scene and hides the locked switch")
	state.act("c2_dorm_exit")
	await frames()
	var world: Control = main.world
	check(world.scene_id == "campus_bootstrap" and main.world_frame.visible, "ordinary dorm exit opens the formal campus scene")
	var layers: RefCounted = world.campus_layers
	check(layers.ready and world.background == null, "formal scene uses the complete layered campus")
	if not layers.ready: quit(1); return
	check(world.get_viewport() == main.world_viewport, "map, actors, labels and feedback share the world render target")
	check(main.world_viewport.canvas_item_default_texture_filter == Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST, "world SubViewport defaults all child canvases to nearest")
	check(main.world_view.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "the composed world target also uses nearest when displayed")
	check(world.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "campus sprites use nearest sampling inside the world render target")
	if ClassDB.class_has_integer_constant(&"CanvasItem",&"OVERSAMPLING_WITH_SCALE_ENABLED"):
		check(int(world.get("oversampling_with_scale"))==ClassDB.class_get_integer_constant(&"CanvasItem",&"OVERSAMPLING_WITH_SCALE_ENABLED"),"world drawing uses scale-aware glyphs")
	check(world.world_size == Vector2(4516,3420) and world.zoom == 1.1, "map preserves authored bounds and exploration scale")
	var manifest: Dictionary = world.spec.manifest
	var library_anchor := Vector2(manifest.libraryGate.x,manifest.libraryGate.y)
	var library_stand: Vector2 = world._find_safe(library_anchor)
	check(world.can_stand(library_stand) and library_stand.distance_to(library_anchor) < float(manifest.libraryGate.radius), "original library gate has a safe approach in reach")
	check(world.mask == Marshalls.base64_to_raw(manifest.walkability.bitsBase64), "source walkability remains byte-identical")
	var before: String = JSON.stringify(state.d)
	state.toggle_mode()
	check(JSON.stringify(state.d) == before and not main.world_mode.visible, "Chapter 2 rejects the mode command without changing progress")
	check(not world.hud_mode_rect().has_area(), "the locked switch leaves no invisible hit area")
	check(main.world_tasks.position.x + 52 == main.mobile_back.position.x, "locked switch leaves no gap between tasks and phone")
	state.d.items.headphone = true
	state.d.items.waterDrop = true
	main._show_world_journal()
	await frames()
	check(main.find_child("JournalObjective",true,false) != null and main.find_child("JournalObservationCompare",true,false) == null, "map journal shows the task without an optional comparison entry")
	main._close_modal()
	world.player = library_stand
	world._sync_player()
	state.d.native.mode = "dark"
	state.d.themeMode = "dark"
	check(state.save_game() and state.load_game(), "legacy pre-unlock dark save can be continued")
	state.changed.emit()
	await frames()
	check(state.d.native.mode == "light" and state.d.themeMode == "normal", "early dark save resumes in light mode")
	# A fresh world key forces the ordinary resume path to validate this pose.
	world.world_key = ""
	world.refresh_world()
	check(world.player.distance_to(library_stand) < .1, "latest map reopens the saved library approach")
	world.player = library_stand
	world._sync_player()
	for target: Dictionary in world.targets:
		if target.id == "library_gate":
			world._try_interact(target)
			break
	await frames()
	check(world.scene_id == "library_interior" and not layers.ready and layers.textures.is_empty(), "library gate enters the existing interior and retires campus drawing")

	# Mount the existing final 022 session from its earned seating checkpoint.
	state.d = state.d.duplicate(true)
	state.d.ui.libraryFinalsPhase = "seat_recovered"
	state.d.ui.libraryFinalsPuzzle.playerSeated = true
	state.d.ui.libraryFinalsPuzzle.nextQuestId = null
	state.changed.emit()
	await frames()
	var opening_host: Control = main.c3_scene_host
	opening_host.tick(0,true)
	var opening: RefCounted = opening_host.current
	check(opening != null and opening.kind == "opening" and not state.mode_switch_unlocked(), "the 022 conversation itself keeps mode switching locked")
	if opening == null: quit(1); return
	var opening_view: Control = opening_host.opening
	var opening_projection: Dictionary = opening_view._library_projection()
	check(opening_view.is_visible_in_tree() and not opening_projection.is_empty(), "the 022 opening projects the active layered library")
	if not opening_projection.is_empty():
		var library_bottom: float = opening_projection.origin.y + world.world_size.y * opening_projection.zoom
		check(library_bottom < opening_view.subtitle_panel.position.y, "the narration card leaves the library entrance visible")
	check(not main.phone.is_visible_in_tree() and not main.world_frame.is_visible_in_tree(), "the 022 opening has exclusive ownership of the scene")
	opening.skip_to_arrival(state.d,opening_host)
	opening.advance_current(state.d,opening_host)
	opening_host.tick(0,true)
	await frames()
	check(world.scene_id == "campus_bootstrap" and state.mode_switch_unlocked() and main.world_mode.visible, "accepted 022 handoff opens the layered campus with the switch")
	check(state.d.native.log.filter(func(row): return row.text == "022：深色模式也打开了。").size() == 1, "the unlock appears once as 022 dialogue")
	var player_before_resize: Vector2 = world.player
	for display: Array in [[Vector2i(1280,720),1.0],[Vector2i(1280,720),2.0],[Vector2i(1280,800),1.25],[Vector2i(844,390),3.0],[Vector2i(390,844),1.0]]:
		var dimensions: Vector2i = display[0]
		var density: float = display[1]
		root.size = Vector2i(Vector2(dimensions)*density)
		root.content_scale_factor = density
		await frames()
		var map_rect: Rect2 = main.world_view.get_global_rect()
		var physical: Rect2 = root.get_final_transform()*map_rect
		var backing: Vector2 = Vector2(main.world_viewport.size)
		var canvas_scale: Vector2=world.get_global_transform_with_canvas().get_scale()
		check((world.size*canvas_scale).distance_to(backing)<.01,"all campus passes use the same source-to-pixel scale")
		var label := "%s at %sx" % [dimensions,density]
		print("CAMPUS_RENDER ",label," -> ",main.world_viewport.size)
		var caption: Dictionary=world.hud_metrics("基础图书馆入口已开放。")
		var caption_scale:float=world.hud_display_scale()
		check(caption.body_font==ceili(18*Overlay.ui_units(world.size,caption_scale)), "campus caption uses the current fitted UI scale at " + label)
		check(main.size.is_equal_approx(Vector2(dimensions)) and world.size == Vector2(960,540) and world.zoom == 1.1, "logical viewport and camera zoom survive " + label)
		check(physical.size.distance_to(backing) < .01 and physical.position.distance_to(physical.position.round()) < .01, "campus render texture covers the painted physical pixels 1:1 at " + label)
		check(is_equal_approx(backing.aspect(),16.0/9.0) and (backing.x > 960) == (dimensions.x*density > 1000), "exact 16:9 backing follows physical size at " + label)
		var point := Vector2(210,310)
		var container_point: Vector2 = world.get_global_transform_with_canvas()*point
		check(main.world_view.source_position(container_point).distance_to(point) < .001 and world.player == player_before_resize, "pixel scaling preserves picking and player coordinates at " + label)
		var tasks_rect: Rect2 = main.world_tasks.get_global_rect()
		var switch_rect: Rect2 = main.world_mode.get_global_rect()
		var phone_rect: Rect2 = main.mobile_back.get_global_rect()
		check(map_rect.encloses(tasks_rect) and map_rect.encloses(switch_rect) and map_rect.encloses(phone_rect), "right controls fit " + label)
		check(tasks_rect.end.x < switch_rect.position.x and switch_rect.end.x < phone_rect.position.x, "tasks, switch and phone stay adjacent without overlap " + label)
	check(main.world_mode.tooltip_text == "浅色模式", "unlocked switch uses the light mode name alone")
	main.world_mode.pressed.emit()
	await frames()
	check(state.d.native.mode == "dark" and main.world_mode.tooltip_text == "深色模式", "ordinary switch toggles and uses the dark mode name alone")
	main.mobile_surface_managed = true
	root.size = Vector2i(390,844)
	await frames()
	main._layout()
	var rotated_surface := Rect2(Vector2.ZERO, main.size)
	check(main.mobile_surface_rotation == 1 and rotated_surface.encloses(main.world_view.get_global_rect()), "portrait browser keeps the oriented map inside the landscape surface")
	check(main.world_view.get_global_rect().encloses(main.mobile_back.get_global_rect()), "phone button stays inside the rotated map")
	main.queue_free()
	await frames()
	print("Layered campus integration: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
