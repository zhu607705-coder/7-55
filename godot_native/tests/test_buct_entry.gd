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
var initial_input: Dictionary
var initial_scale_factor: float
var initial_scale_aspect: int
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
	check(root.content_scale_factor==initial_scale_factor and root.content_scale_aspect==initial_scale_aspect,"BUCT preserves global scale factor and aspect")
func input_snapshot() -> Dictionary:
	var result: Dictionary={}
	for action in InputMap.get_actions():
		var events: Array=[]
		for event: InputEvent in InputMap.action_get_events(action):
			var fields: Dictionary={"class":event.get_class()}
			for property in event.get_property_list():
				if (int(property.usage)&PROPERTY_USAGE_STORAGE)!=0:
					fields[str(property.name)]=event.get(str(property.name))
			events.append(fields)
		result[str(action)]={"deadzone":InputMap.action_get_deadzone(action),"events":events}
	return result
func input_preserved() -> void:
	check(InputMap.get_actions()==initial_actions,"Chooser restores the exact original action list")
	check(input_snapshot()==initial_input,"Chooser preserves all original input events and deadzones")
func collect_refs(node: Node,refs: Array[WeakRef]) -> void:
	refs.append(weakref(node))
	for child in node.get_children():collect_refs(child,refs)
func check_released(refs: Array[WeakRef],label: String) -> void:
	var released:=true
	for reference in refs:released=released and reference.get_ref()==null
	check(released,label)
func check_chooser(viewport: Vector2i) -> void:
	var bounds:=Rect2(Vector2.ZERO,Vector2(viewport))
	check(current_scene.has_method("open_campus") and current_scene.has_method("open_haidian") and current_scene.has_method("open_changping"),"The same chooser provides all three independent campuses")
	check(bounds.encloses(current_scene.card.get_global_rect()),"Four-entry chooser fits "+str(viewport))
	for button: Button in [current_scene.story_button,current_scene.campus_button,current_scene.haidian_button,current_scene.changping_button]:
		check(bounds.encloses(button.get_global_rect()),"Chooser button fits: "+str(button.name))
		check(button.size.y>=44,"Chooser button retains 44px minimum target: "+str(button.name))
	check(current_scene.campus_button.name=="OpenBuctCampus" and current_scene.haidian_button.name=="OpenBuctHaidian","Original and new campus entry identities remain distinct")
func haidian_round_trip(viewport: Vector2i,cycle: int) -> void:
	root.size=viewport;await frames(4)
	check_chooser(viewport)
	var bounds:=Rect2(Vector2.ZERO,Vector2(viewport))
	await click(current_scene.haidian_button)
	var campus=current_scene
	check(campus.scene_file_path=="res://campuses/buct_haidian/scenes/playable.tscn","Actual Haidian entry button reaches its independent scene")
	if campus.scene_file_path!="res://campuses/buct_haidian/scenes/playable.tscn":return
	check(root.size==viewport,"Haidian entry preserves requested window dimensions")
	check(campus.initialized,"Haidian initializes approved registered assets")
	if not campus.initialized:
		await click(campus.return_button)
		return
	check(campus.real_buildings.size()==1 and campus.real_buildings.has("main_building"),"Haidian teaching-only inspector remains isolated")
	check(is_instance_valid(campus.library_component) and not campus.landmark_hit_polys.has("library") and campus.library_component.hit_test_alpha(Vector2(520,400)),"Haidian Rongmao true-RGBA body replaces legacy click proxy")
	check(campus.WORLD==Vector2(1448,1086) and campus.visitor.position==Vector2(963,297),"Original Haidian canvas and north entrance retained")
	check(campus.pin_layer is CanvasLayer,"Haidian pins use screen-space controls")
	campus.camera.force_update_scroll()
	check(campus.map_area.has_point(campus.visitor.get_global_transform_with_canvas().origin),"Haidian spawn remains visible between bars: "+str(viewport))
	for key in ["back","guide","reset","overview","nearby","zoom_out","zoom_in","building_debug"]:
		var control: Control=campus.ui_controls[key]
		check(bounds.encloses(control.get_global_rect()),"Haidian control fits "+key+" "+str(viewport))
		check(control.size.y>=40,"Haidian control remains touch-sized: "+key)
	await click(campus.ui_controls.nearby)
	check(campus.info_id=="north_gate","Haidian nearby button opens north entrance")
	check(bounds.encloses(campus.info_panel.get_global_rect()),"Haidian information panel fits "+str(viewport))
	check(campus.info_scroll is ScrollContainer,"Haidian long information remains scrollable")
	await click(campus.ui_controls.close)
	check(campus.info_id.is_empty(),"Haidian information close returns to map")
	campus.show_landmark("main_building");await frames(2)
	check(bounds.encloses(campus.info_panel.get_global_rect()),"Teaching information fits both mobile orientations")
	var escape:=InputEventKey.new();escape.physical_keycode=KEY_ESCAPE;escape.pressed=true
	campus._unhandled_input(escape)
	check(campus.info_id.is_empty() and not campus.leaving,"Haidian Escape closes information before exiting")
	await click(campus.ui_controls.building_debug)
	check(campus.building_panel.visible,"Haidian building inspection opens")
	check(bounds.encloses(campus.building_panel.get_global_rect()),"Haidian building inspection fits "+str(viewport))
	check(campus.movement_paused(),"Haidian building inspection pauses walking")
	campus._unhandled_input(escape)
	check(not campus.building_panel.visible and not campus.leaving,"Haidian Escape closes building inspection first")
	await frames(2)
	campus.camera.force_update_scroll()
	var waypoint: Array=campus.data.route_waypoints[1]
	var destination:=Vector2(waypoint[0],waypoint[1])
	var touch:=InputEventScreenTouch.new();touch.index=0;touch.pressed=true;touch.position=campus.get_canvas_transform()*destination
	check(campus.map_area.has_point(touch.position),"Haidian touch destination lies inside the playable screen area")
	root.push_input(touch)
	check(not campus.current_path.is_empty(),"Haidian actual touch creates a walkable route")
	var start: Vector2=campus.visitor.position
	for i in range(12):await physics_frame
	check(campus.visitor.position.distance_to(start)>2,"Haidian touch moves the real visitor")
	touch.pressed=false;root.push_input(touch)
	await click(campus.ui_controls.overview)
	check(campus.overview and campus.movement_paused(),"Haidian overview pauses walking")
	campus.camera.force_update_scroll()
	var transform: Transform2D=campus.world.get_global_transform_with_canvas()
	check(campus.map_area.grow(1).has_point(transform*Vector2.ZERO) and campus.map_area.grow(1).has_point(transform*campus.WORLD),"Haidian overview fits the complete original canvas")
	for pin: Control in campus.pins:
		check(pin.size.y>=40 and pin.scale==Vector2.ONE,"Haidian overview pins keep readable screen-space targets")
	campus._unhandled_input(escape)
	check(not campus.overview and not campus.leaving,"Haidian Escape closes overview before exiting")
	await click(campus.ui_controls.reset)
	check(campus.visitor.position==Vector2(963,297) and campus.current_path.is_empty(),"Haidian reset returns to north entrance without leaving campus")
	await click(campus.ui_controls.guide)
	check(campus.guide_active,"Haidian guide button starts the original route")
	Input.action_press("buct_haidian_walk_down")
	campus._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not Input.is_action_pressed("buct_haidian_walk_down"),"Haidian focus loss releases owned held action")
	check(not campus.guide_active and campus.current_path.is_empty() and campus.visitor.velocity==Vector2.ZERO,"Haidian focus loss clears guide, path and visitor motion")
	preserved()
	var refs: Array[WeakRef]=[];collect_refs(campus,refs)
	var held_action: String="buct_haidian_walk_right"
	Input.action_press(held_action)
	if cycle==0:
		await click(campus.return_button)
	else:
		campus.return_to_entry();campus.return_to_entry();await frames(5)
	check_released(refs,"Haidian exit frees all descendants, registered strips, shadows and repair viewport")
	check(root.size==viewport,"Haidian exit preserves requested window dimensions")
	check(not InputMap.has_action(held_action) or not Input.is_action_pressed(held_action),"Haidian held movement does not survive exit")
	check_chooser(viewport)
	input_preserved();preserved()
func changping_round_trip(viewport: Vector2i, cycle: int) -> void:
	root.size=viewport;await frames(4)
	check_chooser(viewport)
	await click(current_scene.changping_button)
	var campus=current_scene
	check(campus.scene_file_path=="res://campuses/buct_changping/scenes/playable.tscn","Actual Changping chooser button opens original full map")
	if campus.scene_file_path!="res://campuses/buct_changping/scenes/playable.tscn":return
	check(campus.initialized and campus.WORLD==Vector2(950,1656),"Changping retains portrait 950x1656 source coordinate system")
	check(campus.visitor.position==Vector2(515,1510) and campus.data.route_waypoints.size()==41,"Original south entrance and 41 authored route points retained")
	check(campus.objects.get_child_count()>=54,"Full registered source groups are present, not only a tree pilot")
	var visual=campus.visitor.get_node("StudentVisual")
	check(visual.ready_to_show and visual.target_height==18 and visual.current_foot_global().distance_to(campus.visitor.global_position)<0.001,"Changping actual four-direction student is foot-registered")
	var bounds:=Rect2(Vector2.ZERO,Vector2(viewport))
	for key in ["back","guide","reset","overview","nearby","zoom_out","zoom_in"]:
		var control: Control=campus.ui_controls[key]
		check(bounds.encloses(control.get_global_rect()) and control.size.y>=40,"Changping responsive control fits: "+key+" "+str(viewport))
	check(not campus.ui_controls.has("left") and not campus.ui_controls.has("down"),"No on-screen direction buttons are added to desktop")
	campus.camera.force_update_scroll()
	check(campus.map_area.has_point(campus.visitor.get_global_transform_with_canvas().origin),"Changping feet remain visible between adaptive bars")
	await click(campus.ui_controls.nearby)
	check(campus.info_id=="south_gate" and campus.movement_paused(),"Nearby button opens south gate information and pauses")
	check(bounds.encloses(campus.info_panel.get_global_rect()) and campus.info_scroll is ScrollContainer,"Changping readable information fits and scrolls")
	await click(campus.ui_controls.close)
	check(campus.info_id.is_empty(),"Changping information closes to the same map")
	campus.show_landmark("main_building")
	var escape:=InputEventKey.new();escape.physical_keycode=KEY_ESCAPE;escape.pressed=true
	campus._unhandled_input(escape)
	check(campus.info_id.is_empty() and not campus.leaving,"Escape closes information before leaving Changping")
	campus.camera.force_update_scroll()
	var waypoint: Array=campus.data.route_waypoints[1]
	var destination:=Vector2(waypoint[0],waypoint[1])
	var touch:=InputEventScreenTouch.new();touch.index=0;touch.pressed=true;touch.position=campus.get_canvas_transform()*destination
	check(campus.map_area.has_point(touch.position),"Authored Changping touch destination is visible")
	root.push_input(touch)
	check(not campus.current_path.is_empty(),"Actual touch creates Changping navigation path")
	var before: Vector2=campus.visitor.position
	for i in range(12):await physics_frame
	check(campus.visitor.position.distance_to(before)>2,"Actual Changping visitor physically follows touch")
	touch.pressed=false;root.push_input(touch)
	await click(campus.ui_controls.overview)
	check(campus.overview and campus.movement_paused(),"Changping overview pauses navigation")
	campus.camera.force_update_scroll()
	var transform: Transform2D=campus.world.get_global_transform_with_canvas()
	check(campus.map_area.grow(1).has_point(transform*Vector2.ZERO) and campus.map_area.grow(1).has_point(transform*campus.WORLD),"Full 950x1656 map fits without crop or stretch")
	check(is_equal_approx(campus.camera.zoom.x,campus.camera.zoom.y),"Changping camera scale remains uniform")
	for pin: Control in campus.pins:check(bounds.encloses(pin.get_global_rect()) and pin.size.y>=40 and pin.scale==Vector2.ONE,"Changping overview landmark is screen-space and in bounds")
	campus._unhandled_input(escape)
	check(not campus.overview and not campus.leaving,"Escape unwinds Changping overview")
	await click(campus.ui_controls.reset)
	check(campus.visitor.position==Vector2(515,1510) and campus.current_path.is_empty(),"Changping reset restores original gate and clears motion")
	await click(campus.ui_controls.guide)
	check(campus.guide_active,"Changping original guide starts from actual button")
	Input.action_press("buct_changping_walk_down")
	campus._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not Input.is_action_pressed("buct_changping_walk_down") and not campus.guide_active and campus.current_path.is_empty(),"Changping focus loss releases input and guide")
	preserved()
	var refs: Array[WeakRef]=[];collect_refs(campus,refs)
	Input.action_press("buct_changping_walk_right")
	if cycle==0:await click(campus.return_button)
	else:campus.return_to_entry();campus.return_to_entry();await frames(5)
	check_released(refs,"Changping exit frees all source groups, unique shadows, masks, student frames and repair viewport")
	check(not InputMap.has_action("buct_changping_walk_right"),"Changping held movement cannot survive return")
	check_chooser(viewport);input_preserved();preserved()

func changping_borrowed_input() -> void:
	var action: StringName="buct_changping_walk_left"
	InputMap.add_action(action,0.37)
	var event:=InputEventKey.new();event.physical_keycode=KEY_J;InputMap.action_add_event(action,event)
	var borrowed:=input_snapshot()
	await click(current_scene.changping_button)
	check(input_snapshot()[str(action)]==borrowed[str(action)] and not current_scene.owned_actions.has(str(action)),"Changping borrows pre-existing actions without mutating events or deadzone")
	current_scene.return_to_entry();await frames(5)
	check(input_snapshot()==borrowed,"Changping return preserves borrowed actions exactly")
	InputMap.erase_action(action);input_preserved();preserved()

func haidian_borrowed_input() -> void:
	var action: StringName="buct_haidian_walk_left"
	var created:=not InputMap.has_action(action)
	if created:
		InputMap.add_action(action,0.37)
		var event:=InputEventKey.new();event.physical_keycode=KEY_J;InputMap.action_add_event(action,event)
	var borrowed_snapshot:=input_snapshot()
	await click(current_scene.haidian_button)
	var campus=current_scene
	check(input_snapshot()[str(action)]==borrowed_snapshot[str(action)],"Haidian does not mutate a pre-existing action's events or deadzone")
	check(not campus.owned_actions.has(str(action)),"Haidian does not claim ownership of a borrowed action")
	campus.return_to_entry();await frames(5)
	check(input_snapshot()==borrowed_snapshot,"Haidian exit preserves a pre-existing input action exactly")
	if created:InputMap.erase_action(action)
	input_preserved();preserved()
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
	initial_actions=InputMap.get_actions();initial_input=input_snapshot()
	initial_scale_factor=root.content_scale_factor;initial_scale_aspect=root.content_scale_aspect
	root.set_meta("entry_arguments_consumed",true)
	check(ProjectSettings.get_setting("application/run/main_scene")=="res://scenes/entry.tscn","Default launch points at separate campus chooser")
	check(change_scene_to_file("res://scenes/entry.tscn")==OK,"Chooser loads")
	await frames(5)
	for viewport: Vector2i in [Vector2i(1440,900),Vector2i(390,844),Vector2i(392,844),Vector2i(844,390),Vector2i(667,375),Vector2i(1280,720)]:
		root.size=viewport;await frames(4)
		var entry=current_scene
		check(entry.has_method("open_campus"),"Return reaches chooser")
		var bounds:=Rect2(Vector2.ZERO,Vector2(viewport))
		check(bounds.encloses(entry.card.get_global_rect()),"Chooser fits "+str(viewport))
		check_chooser(viewport)
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
		campus.show_landmark("library")
		check(bounds.encloses(campus.info_panel.get_global_rect()),"Library card fits "+str(viewport))
		for tool in ["library_toggle","library_reset"]:
			check(bounds.encloses(campus.ui_controls[tool].get_global_rect()),"Library control fits "+tool+" "+str(viewport))
			check(campus.ui_controls[tool].size.y>=40,"Library control retains 40px touch target")
		await click(campus.ui_controls.library_toggle)
		check(not campus.library.body_enabled and campus.library.physics_body.collision_layer==0,"Actual hide control disables library body and collider")
		check(campus.landmark_at(Vector2(750,500)).is_empty(),"Hidden library rejects alpha selection")
		await click(campus.ui_controls.library_reset)
		check(campus.library.body_enabled and campus.library.position==Vector2(749,570),"Actual library reset restores registered body")
		await click(campus.ui_controls.close)
		check(campus.info_id.is_empty(),"Library return button restores map")
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
		input_preserved()
		preserved()
	# Each requested mobile orientation exercises two complete native Haidian returns.
	for viewport: Vector2i in [Vector2i(392,844),Vector2i(667,375)]:
		for cycle in range(2):await haidian_round_trip(viewport,cycle)
	await haidian_borrowed_input()
	for viewport: Vector2i in [Vector2i(1280,720),Vector2i(390,844),Vector2i(667,375)]:
		for cycle in range(2):await changping_round_trip(viewport,cycle)
	await changping_borrowed_input()
	# Cross-campus recovery: Haidian -> chooser -> original Chaoyang -> chooser.
	await click(current_scene.haidian_button)
	current_scene.return_to_entry();await frames(5)
	input_preserved();preserved()
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
	preserved();input_preserved()
	# Resume story immediately after a further Haidian visit, with no story reset.
	await click(current_scene.haidian_button)
	current_scene.return_to_entry();await frames(5)
	preserved();input_preserved()
	if OS.get_environment("BUCT_ENTRY_CAMPUS_ONLY")=="1":
		print("BUCT_STORY_RESUME_NOT_RUN: focused campus-only stage; full story resume remains a separate CI gate")
		current_scene.queue_free();await frames(8)
	else:
		await click(current_scene.story_button)
		check(current_scene.scene_file_path=="res://scenes/main.tscn","Continue retains existing story scene identity")
		check(state.d.native.page=="phone_home","Continue resumes fixture page without a story reset")
		if current_scene.has_method("shutdown"):await current_scene.shutdown()
		current_scene.queue_free();await frames(8)
	print("BUCT_ENTRY: %d checks; %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
