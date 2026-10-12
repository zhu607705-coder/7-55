extends SceneTree
## Real scene transitions and pointer/touch paths, with isolated test-save receipts.
var checks:=0
var failures:=0
var state: Node
var snapshot: Dictionary
var saved_bytes:=PackedByteArray()
var backup_bytes:=PackedByteArray()
var initial_scale_size: Vector2i
var initial_scale_mode: int
var initial_actions: Array[StringName]
func _initialize() -> void:run.call_deferred()
func frames(count:=3) -> void:
	for i in range(count):await process_frame
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("BUCT ENTRY: "+message)
func click(control: Control) -> void:
	var point:=control.get_global_transform_with_canvas()*(control.size/2)
	for down in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;root.push_input(event)
	await frames(4)
func preserved() -> void:
	check(state.d==snapshot,"BUCT leaves all Zhejiang story/session fields unchanged")
	check(FileAccess.get_file_as_bytes(state.SAVE_PATH)==saved_bytes,"BUCT never rewrites primary save bytes")
	check(FileAccess.get_file_as_bytes(state.BACKUP_PATH)==backup_bytes,"BUCT never rewrites backup save bytes")
	check(root.content_scale_size==initial_scale_size and root.content_scale_mode==initial_scale_mode,"BUCT does not change global window scaling")
func isolated_save_fixture() -> bool:
	# A direct --script launch must never overwrite a player's native saves.
	# XDG alone is insufficient: verify the directory Godot actually resolved.
	var declared:=OS.get_environment("GODOT_TEST_USER_DATA_DIR").replace("\\", "/")
	if declared.is_empty() or not declared.is_absolute_path():return false
	declared=declared.simplify_path().trim_suffix("/")
	var sandbox:=declared.get_base_dir().get_base_dir()
	if not sandbox.get_file().begins_with("755-native-check-"):return false
	if declared!=sandbox.path_join("data/SevenFiftyFiveNative"):return false
	if OS.get_user_data_dir().replace("\\", "/").simplify_path().trim_suffix("/")!=declared:return false
	if ProjectSettings.globalize_path("user://").replace("\\", "/").simplify_path().trim_suffix("/")!=declared:return false
	for file in ["save.json","save.previous.json","save.json.tmp"]:
		if FileAccess.file_exists(declared.path_join(file)) or DirAccess.dir_exists_absolute(declared.path_join(file)):return false
	return true
func run() -> void:
	if not isolated_save_fixture():
		printerr("BUCT_TEST_ISOLATION_REQUIRED: use node godot_native/tools/test_buct.mjs; refusing save-fixture writes outside a fresh declared sandbox")
		quit(2)
		return
	state=root.get_node("State")
	state.d=state.initial();state.d.native.page="phone_home";state.d.currentScene="phone_home"
	check(state.save_game(),"Fixture creates valid primary save")
	check(state.save_game(),"Fixture creates valid previous save")
	snapshot=state.d.duplicate(true)
	saved_bytes=FileAccess.get_file_as_bytes(state.SAVE_PATH)
	backup_bytes=FileAccess.get_file_as_bytes(state.BACKUP_PATH)
	initial_scale_size=root.content_scale_size;initial_scale_mode=root.content_scale_mode
	initial_actions=InputMap.get_actions()
	root.set_meta("entry_arguments_consumed",true)
	check(ProjectSettings.get_setting("application/run/main_scene")=="res://scenes/entry.tscn","Default launch points at separate campus chooser")
	check(change_scene_to_file("res://scenes/entry.tscn")==OK,"Chooser loads")
	await frames(5)
	for viewport: Vector2i in [Vector2i(1440,900),Vector2i(390,844),Vector2i(844,390),Vector2i(667,375),Vector2i(1280,720)]:
		root.size=viewport;await frames(4)
		var entry=current_scene
		check(entry.has_method("open_campus"),"Return reaches chooser")
		var bounds:=Rect2(Vector2.ZERO,Vector2(viewport))
		check(bounds.encloses(entry.card.get_global_rect()),"Chooser fits "+str(viewport))
		await click(entry.campus_button)
		var campus=current_scene
		check(campus.scene_file_path=="res://campuses/buct/scenes/playable.tscn","Real campus button reaches independent native map")
		check(campus.objects.get_node("main_building") is Node2D,"Original native source-layer objects remain loaded")
		campus.camera.force_update_scroll()
		check(campus.map_area.has_point(campus.visitor.get_global_transform_with_canvas().origin),"Spawn remains visible between bars after resize")
		for key in ["back","guide","reset","overview","nearby","zoom_out","zoom_in"]:
			var control: Control=campus.ui_controls[key]
			check(bounds.encloses(control.get_global_rect()),"Campus control fits "+key+" "+str(viewport))
			check(control.size.y>=40,"Campus controls retain touch target height")
		await click(campus.ui_controls.nearby)
		check(campus.info_id=="south_gate","Nearby control opens south gate without keyboard")
		check(bounds.encloses(campus.info_panel.get_global_rect()),"Landmark card fits viewport")
		await click(campus.ui_controls.close)
		check(campus.info_id.is_empty(),"Real close button returns to map")
		var destination:=Vector2(746,973)
		campus.camera.force_update_scroll()
		var touch:=InputEventScreenTouch.new();touch.index=0;touch.pressed=true;touch.position=campus.get_canvas_transform()*destination
		root.push_input(touch)
		check(not campus.current_path.is_empty(),"Touch path command reaches walkable destination")
		var start: Vector2=campus.visitor.position
		for i in range(12):await physics_frame
		check(campus.visitor.position.distance_to(start)>2,"Touch path moves real CharacterBody2D")
		touch=InputEventScreenTouch.new();touch.index=0;touch.pressed=false;root.push_input(touch)
		await click(campus.ui_controls.overview)
		check(campus.overview and campus.movement_paused(),"Overview control pauses walking")
		for pin: Control in campus.pins:
			check(pin.size.y>=40 and pin.scale==Vector2.ONE,"Overview landmark has readable screen-space touch control")
		campus.camera.force_update_scroll()
		var transform: Transform2D=campus.world.get_global_transform_with_canvas()
		check(campus.map_area.grow(1).has_point(transform*Vector2.ZERO) and campus.map_area.grow(1).has_point(transform*Vector2(1448,1086)),"Full source canvas fits available map area")
		await click(campus.ui_controls.reset)
		check(not campus.overview and campus.current_path.is_empty(),"Reset recovers overview/path state")
		await click(campus.ui_controls.guide)
		check(campus.guide_active,"Real guide button starts navigation")
		preserved()
		var shadow_refs: Array[WeakRef]=[]
		for shadow: Node in campus.world.get_node("StaticSourceGroundShadows").get_children():
			shadow_refs.append(weakref(shadow))
		var weak: WeakRef=weakref(campus)
		# Repeated exit requests during active route must schedule only one scene change.
		campus.return_to_entry();campus.return_to_entry();await frames(5)
		check(weak.get_ref()==null,"Leaving frees the entire old campus instance")
		for i in range(shadow_refs.size()):
			check(shadow_refs[i].get_ref()==null,"Every reparented ground shadow is freed: %d"%i)
		check(current_scene.has_method("open_campus"),"Active route returns cleanly to chooser")
		check(InputMap.get_actions()==initial_actions,"Leaving removes only BUCT-installed actions")
		preserved()
	# Escape unwinds child overlays first; final Escape returns to entry.
	await click(current_scene.campus_button)
	var campus=current_scene
	campus.show_landmark("main_building")
	var escape:=InputEventKey.new();escape.physical_keycode=KEY_ESCAPE;escape.pressed=true
	campus._unhandled_input(escape)
	check(campus.info_id.is_empty() and not campus.leaving,"Escape closes landmark first")
	campus.toggle_overview();campus._unhandled_input(escape)
	check(not campus.overview and not campus.leaving,"Escape exits overview first")
	campus._unhandled_input(escape);await frames(4)
	preserved()
	await click(current_scene.story_button)
	check(current_scene.scene_file_path=="res://scenes/main.tscn","Continue retains existing story scene identity")
	check(state.d.native.page=="phone_home","Continue resumes fixture page without a story reset")
	if current_scene.has_method("shutdown"):await current_scene.shutdown()
	current_scene.queue_free();await frames(8)
	print("BUCT_ENTRY: %d checks; %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
