extends SceneTree
## Actual Main/World, source dorm targets and root-dispatched events. Fixtures
## isolate pointer ownership; they are not earned gameplay or physical-device QA.
var shell: Control
var state: Node
var checks := 0
var failures := 0
var actions: Array = []
var observations: Array = []
var emulation_before := false
const NEAR := Vector2(560,440)
const FAR := Vector2(450,440)
const TARGET_ID := "desk_03"

func _initialize() -> void: run.call_deferred()
func frames(count := 4) -> void:
	for unused in count: await process_frame
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("MOBILE DIRECT TOUCH: " + label)
func send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func touch(point: Vector2, down: bool, index := 0, canceled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.position = point; event.index = index; event.pressed = down; event.canceled = canceled
	send(event)
func drag(point: Vector2, delta: Vector2, index := 0) -> void:
	var event := InputEventScreenDrag.new()
	event.position = point; event.relative = delta; event.index = index
	send(event)
func mouse(point: Vector2, down: bool, device := 0, double_click := false) -> void:
	var event := InputEventMouseButton.new()
	event.position = point; event.global_position = point; event.pressed = down
	event.button_index = MOUSE_BUTTON_LEFT; event.device = device; event.double_click = double_click
	send(event)
func motion(point: Vector2, delta: Vector2, device := 0) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point; event.global_position = point; event.relative = delta
	event.button_mask = MOUSE_BUTTON_MASK_LEFT; event.device = device
	send(event)
func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code; event.physical_keycode = code; event.pressed = down
	send(event)
func world_screen(local: Vector2) -> Vector2:
	return shell.world_view.get_global_transform_with_canvas() * (local * shell.world_view.size / Vector2(shell.world_viewport.size))
func source_screen(point: Vector2) -> Vector2:
	return world_screen((point-shell.world.camera)*shell.world.zoom+shell.world.size/2)
func target(id := TARGET_ID) -> Dictionary:
	for candidate: Dictionary in shell.world.targets:
		if str(candidate.id) == id: return candidate
	return {}
func action_count() -> int: return actions.count("c2_dorm_prop")
func lamp() -> bool: return bool(state.d.native.get("dorm_props",{}).get("lamp_03_on",false))
func visible_pick(id := TARGET_ID) -> Vector2:
	var definition := target(id)
	if definition.is_empty(): return Vector2.INF
	var bounds: Array = definition.bounds
	var rect := Rect2(Vector2(bounds[0],bounds[1])*.5+Vector2(245,0),Vector2(bounds[2],bounds[3])*.5)
	var best := Vector2.INF
	var distance := INF
	for y in range(int(rect.position.y),int(rect.end.y),3):
		for x in range(int(rect.position.x),int(rect.end.x),3):
			var point := Vector2(x,y)
			if shell.world._pick_target(point).get("id","") != id: continue
			var next: float = point.distance_to(rect.get_center())
			if next < distance: best=source_screen(point); distance=next
	return best
func fixture(dimensions := Vector2i(390,844), insets := Vector4.ZERO, bag := false) -> void:
	if is_instance_valid(shell):
		await shell.shutdown(); shell.queue_free(); await frames(2)
	check(state.begin_checkpoint("c2-dorm-exit"),"source dorm checkpoint is available")
	state.d.native.settings.volume = 0
	state.d.native.mode = "light"
	state.d.items.campusCard = true
	state.d.native.dorm_props = {"cabinet_open":false,"lamp_01_on":false,"lamp_03_on":false}
	root.size = dimensions
	shell = load("res://tests/fixtures/mobile_safe_area_shell.gd").new(); shell.test_safe_insets = insets
	shell.size = Vector2(dimensions)
	root.add_child(shell); shell.mobile_world = true; shell.compact_inventory_open = bag
	shell._refresh(); shell._layout(); await frames(8)
	shell.world.set_process(false); shell.world.native_dorm.set_process(false)
	shell.world.player = NEAR; shell.world.pan_offset = Vector2.ZERO
	shell.world._sync_player(); shell.world._process(0)
	shell.world.subtitle = ""; shell.world.transition_alpha = 0
	shell.world.cancel_exploration_gestures(); shell.world.queue_redraw(); await frames(4)
	check(shell.world.scene_id == "dorm_hub" and shell.world.is_visible_in_tree(),"production dorm is visible")
	check(shell.world.can_stand(NEAR),"near fixture stands legally outside original furniture")
	check(not target().is_empty() and shell.world._distance(target()) <= float(target().radius)*.5,"real lamp target is in its original range")
	check(visible_pick().is_finite(),"real painted source object has a visible pick")
func held_clear(label: String) -> void:
	check(shell.world.touch_axis == Vector2.ZERO and shell.world.mobile_touch_roles.is_empty() and not shell.world.mobile_mouse_control,label+" clears movement and pointer owners")
	check(shell.world._floor_route.is_empty(),label+" does not leave a floor route")
func stick_point() -> Vector2: return world_screen(shell.world.mobile_control_metrics().stick+Vector2(30,0))
func assert_layout(insets: Vector4) -> void:
	var safe := Rect2(insets.x,insets.y,shell.size.x-insets.x-insets.z,shell.size.y-insets.y-insets.w)
	var metrics: Dictionary = shell.world.mobile_control_metrics()
	check(shell.world.mobile_exploration,"compact exploration owns viewport")
	check(not metrics.interact.has_area(),"no separate interaction confirmation button remains")
	check(metrics.stick_rect.size.x >= 100 and metrics.stick_rect.size.y >= 100,"movement hit area retains 100px floor")
	check(Rect2(Vector2.ZERO,shell.world.size).encloses(metrics.stick_rect),"entire joystick overlays rendered game viewport")
	check(shell.world.exploration_safe_rect(true) == shell.world.exploration_safe_rect(),"joystick does not reserve a full-width bottom scene strip")
	check(safe.encloses(shell.world_frame.get_global_rect()),"world frame fits platform safe area")
	for control: Control in [shell.mobile_back,shell.world_tasks,shell.inventory_handle,shell.inventory_dock]:
		if control.visible: check(safe.encloses(control.get_global_rect()),control.name+" fits platform safe area")
	check(not shell.inventory_dock.visible or not shell.inventory_dock.get_global_rect().intersects(shell.world_frame.get_global_rect()),"existing inventory remains outside game viewport")
	check(shell.world.size == Vector2(shell.world_viewport.size),"world pixels match SubViewport exactly")
	observations.append({"size":str(shell.size),"safe":str(safe),"world":str(shell.world_frame.get_global_rect()),"stick":str(metrics.stick_rect),"inventory_open":shell.compact_inventory_open})
func test_direct_tap() -> void:
	await fixture()
	var point := visible_pick(); var count := action_count()
	check(not shell.world.selected_overlay.plaque.visible,"nearby alone does not expose object title")
	touch(point,true); await frames(2)
	check(action_count()==count and not lamp(),"touch press alone cannot activate object")
	touch(point,false); await frames()
	check(action_count()==count+1 and lamp(),"one released tap directly toggles existing lamp exactly once")
	check(shell.world.touch_axis==Vector2.ZERO,"direct object tap never drives movement")
	check(shell.world.selected_overlay.plaque.visible,"confirmed target uses existing locked interaction plaque")
	# Duplicate release, emulated mouse and mouse motion cannot re-dispatch it.
	touch(point,false); mouse(point,true,InputEvent.DEVICE_ID_EMULATION); mouse(point,false,InputEvent.DEVICE_ID_EMULATION)
	motion(point,Vector2.ZERO,InputEvent.DEVICE_ID_EMULATION); await frames()
	check(action_count()==count+1 and lamp(),"duplicate release and platform mouse emulation do not activate twice")
	# A second independent deliberate tap remains possible.
	touch(point,true); touch(point,false); await frames()
	check(action_count()==count+2 and not lamp(),"next deliberate tap works without a stale pointer")
	# Desktop-class pointer double-click flags describe a distinct completed
	# gesture; do not suppress it as if it were a duplicate emulated event.
	mouse(point,true,0,true); mouse(point,false); await frames()
	check(action_count()==count+3 and lamp(),"genuine double-click-marked mouse gesture remains one deliberate tap")
	# Leaving the same source range clears the confirmed plaque.
	shell.world.player=FAR; shell.world._sync_player(); shell.world._process(0); await frames()
	check(not shell.world.selected_overlay.plaque.visible,"range exit clears confirmed title")
func test_no_remote_or_arrival() -> void:
	await fixture()
	shell.world.player=FAR; shell.world.pan_offset=Vector2(110,0)
	shell.world._sync_player(); shell.world._process(0); shell.world.queue_redraw(); await frames()
	check(shell.world._distance(target()) > float(target().radius)*.5,"far fixture is outside unchanged range")
	var point := visible_pick(); check(point.is_finite(),"far object remains actually visible for tap")
	var count:=action_count(); touch(point,true); touch(point,false); await frames()
	check(action_count()==count and not lamp(),"visible far object cannot activate remotely")
	# Move through the existing source movement model, not an interaction callback.
	shell.world.pan_offset=Vector2.ZERO
	for unused in 16:
		shell.world.touch_axis=Vector2.RIGHT; shell.world._process(.05)
	shell.world.touch_axis=Vector2.ZERO; shell.world._process(0); await frames()
	check(shell.world._distance(target()) <= float(target().radius)*.5,"ordinary movement arrives within source range")
	check(action_count()==count and not lamp(),"arrival after a rejected far tap never auto-opens or activates")
	check(not shell.world.selected_overlay.plaque.visible,"arrival alone still has no confirmed title")
func test_drag_and_cancel() -> void:
	for pointer in ["touch","mouse"]:
		await fixture(); var point:=visible_pick(); var count:=action_count()
		if pointer=="touch":
			touch(point,true); drag(point+Vector2(25,0),Vector2(25,0)); drag(point,Vector2(-25,0)); touch(point,false)
		else:
			mouse(point,true); motion(point+Vector2(25,0),Vector2(25,0)); motion(point,Vector2(-25,0)); mouse(point,false)
		await frames()
		check(action_count()==count and not lamp(),pointer+" drag out-and-back is not a tap")
		check(shell.world._floor_route.is_empty(),pointer+" drag end cannot create a floor route")
	await fixture(); var point:=visible_pick(); var count:=action_count()
	touch(point,true); touch(point,false,0,true); touch(point,false); await frames()
	check(action_count()==count and not lamp(),"canceled touch then late release cannot activate")
	held_clear("canceled object tap")
func test_joystick_ownership() -> void:
	await fixture(); var point:=stick_point(); var count:=action_count(); var before:Vector2=shell.world.player
	touch(point,true,3); await frames(2)
	check(shell.world.touch_axis.x>.5,"root joystick press acquires movement")
	shell.world._process(.05)
	check(shell.world.player.x>before.x and action_count()==count,"joystick moves through unchanged model without confirming nearby object")
	touch(world_screen(shell.world.mobile_control_metrics().stick+Vector2(-30,0)),true,4); await frames()
	check(shell.world.touch_axis.x>.5,"second finger cannot replace joystick owner")
	touch(Vector2(1,1),false,4); await frames()
	check(shell.world.touch_axis.x>.5,"unowned finger release cannot stop owned joystick")
	drag(Vector2(-40,-40),Vector2(-200,-200),3); touch(Vector2(-40,-40),false,3); await frames()
	held_clear("release outside viewport")
	check(action_count()==count,"outside release never becomes object confirmation")
	# Release outside also covers a genuine mouse-owned stick on hybrid devices.
	mouse(stick_point(),true); await frames(); check(shell.world.touch_axis.x>.5,"genuine mouse can acquire joystick")
	motion(Vector2(-40,-40),Vector2(-200,-200)); mouse(Vector2(-40,-40),false); await frames()
	held_clear("mouse outside release")
	# Duplicate down is still the same held pointer, not a new ignored owner.
	mouse(stick_point(),true); mouse(stick_point(),true); mouse(stick_point(),false); await frames()
	held_clear("duplicate mouse down then release")
	check(action_count()==count,"duplicate joystick down cannot confirm an object")
	# A tap can coexist with a movement finger without releasing that owner.
	point=visible_pick(); count=action_count(); touch(stick_point(),true,7); touch(point,true,8); touch(point,false,8); await frames()
	check(action_count()==count+1,"independent nearby object finger confirms once")
	touch(stick_point(),false,7); await frames(); held_clear("multitouch completion")
func test_interrupted_ownership() -> void:
	for boundary in ["focus","resize","modal","phone","inventory"]:
		await fixture(); var point:=stick_point(); var count:=action_count()
		touch(point,true,5); await frames(); check(shell.world.touch_axis.length()>.5,boundary+" starts from held movement")
		match boundary:
			"focus": shell.world.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
			"resize": root.size=Vector2i(844,390); shell.size=Vector2(844,390); shell._layout()
			"modal": shell._show_journal()
			"phone": shell._show_phone_surface()
			"inventory": shell._toggle_world_inventory()
		await frames(); held_clear(boundary)
		touch(point,false,5); await frames()
		check(action_count()==count,boundary+" late release cannot confirm object")
		if boundary=="modal": shell._close_modal()
		if boundary=="phone": shell._show_world_mobile()
		await frames(); held_clear(boundary+" restored")
		if shell.world_frame.visible:
			touch(stick_point(),true,6); await frames(); check(shell.world.touch_axis.length()>.5,boundary+" accepts a fresh gesture")
			touch(stick_point(),false,6); await frames(); held_clear(boundary+" fresh release")
	# Closing a modal while an object finger was down cannot revive that tap.
	await fixture(); var point:=visible_pick(); var count:=action_count()
	touch(point,true); shell._show_journal(); await frames(); shell._close_modal(); await frames(); touch(point,false); await frames()
	check(action_count()==count and not lamp(),"modal open/close retires old object press")
	# Inventory begins/ends its own gesture, even when released over an object.
	await fixture(Vector2i(390,844),Vector4.ZERO,true)
	var item:Control=shell.inventory_buttons.get_node_or_null("WorldItem_campusCard")
	check(item!=null,"existing inventory item is available")
	if item!=null:
		shell.inventory_scroll.ensure_control_visible(item); await frames()
		var start:=item.get_global_rect().get_center(); point=visible_pick(); count=action_count()
		touch(start,true); drag(start+Vector2(0,-20),Vector2(0,-20)); await frames(); drag(point,point-start); touch(point,false); await frames()
		check(action_count()==count and not lamp(),"inventory drag release cannot bleed into direct object tap")
		check(state.d.items.campusCard,"existing wrong inventory item remains owned")
		held_clear("inventory drag")
func test_world_replacement() -> void:
	for boundary in ["teleport","scene"]:
		await fixture(); var point:=stick_point(); var count:=action_count()
		touch(point,true,9); await frames(); check(shell.world.touch_axis.length()>.5,boundary+" starts with a held world pointer")
		if boundary=="teleport":
			state.world_teleport.emit([630,880])
		else:
			check(state.begin_checkpoint("c2-library-gate"),"replacement uses an existing authored scene checkpoint")
			shell.mobile_world=true; shell._refresh()
		await frames(); held_clear(boundary+" replacement")
		touch(point,false,9); await frames(); held_clear(boundary+" stale release")
		check(action_count()==count,"world replacement cannot commit an abandoned object action")
		check(not shell.world.selected_overlay.plaque.visible,"world replacement clears old object label")

func test_inventory_first_and_focus() -> void:
	await fixture(Vector2i(390,844),Vector4.ZERO,true)
	var item:Control=shell.inventory_buttons.get_node_or_null("WorldItem_campusCard")
	check(item!=null,"multitouch fixture has original campus-card item")
	if item==null:return
	shell.inventory_scroll.ensure_control_visible(item); await frames()
	var count:=action_count(); var point:=stick_point()
	shell.world.set_process(true)
	touch(point,true,0); await frames(); check(shell.world.touch_axis.length()>.5,"stick acquires before inventory finger")
	touch(item.get_global_rect().get_center(),true,1)
	var position_on_inventory_press:Vector2=shell.world.player
	await frames()
	check(shell.world.player==position_on_inventory_press,"inventory ownership cancels held stick before another movement tick")
	touch(point,false,0); await frames()
	check(shell.world.touch_axis==Vector2.ZERO,"inventory-owned second finger cannot swallow stick release into stuck movement")
	touch(item.get_global_rect().get_center(),false,1); await frames()
	shell.world.set_process(false)
	held_clear("stick-first inventory multitouch")
	check(action_count()==count and not lamp(),"stick-first inventory sequence cannot confirm nearby object")
	await fixture()
	shell.inventory_handle.grab_focus(); key(KEY_SPACE,true); key(KEY_SPACE,false); await frames()
	check(shell.compact_inventory_open and shell.inventory_dock.visible,"focused inventory handle opens through keyboard")
	check(root.gui_get_focus_owner()==shell.inventory_handle,"keyboard inventory toggle retains handle focus")
	key(KEY_SPACE,true); key(KEY_SPACE,false); await frames()
	check(not shell.compact_inventory_open and root.gui_get_focus_owner()==null and shell.world_viewport.gui_get_focus_owner()==shell.world,"same focused key closes inventory and returns Space to world by original contract")

func test_keyboard() -> void:
	await fixture(Vector2i(1440,900))
	check(not shell.world.mobile_exploration and shell.world.size==Vector2(960,540),"desktop keeps canonical world")
	shell.world.grab_focus(); var count:=action_count(); key(KEY_SPACE,true); key(KEY_SPACE,false); await frames()
	check(action_count()==count+1 and lamp(),"desktop Space retains existing nearby interaction")
	var before:Vector2=shell.world.player; key(KEY_A,true); shell.world._process(.05); key(KEY_A,false); await frames()
	check(shell.world.player.x<before.x,"desktop direction key still moves")
func run() -> void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"test uses an isolated save profile")
	if failures: quit(1); return
	create_timer(180).timeout.connect(func(): push_error("MOBILE DIRECT TOUCH deadline"); quit(2))
	state=root.get_node("State"); state.developer_mode=true; state.d=state.initial()
	state.action_completed.connect(func(id,_before,_after,_result): actions.append(id))
	emulation_before=Input.emulate_mouse_from_touch
	for row: Array in [[Vector2i(390,844),Vector4.ZERO],[Vector2i(430,860),Vector4(0,44,0,34)],[Vector2i(844,390),Vector4(44,0,44,21)],[Vector2i(568,320),Vector4.ZERO]]:
		for bag in [false,true]:
			await fixture(row[0],row[1],bag); assert_layout(row[1])
	await test_direct_tap()
	await test_no_remote_or_arrival()
	await test_drag_and_cancel()
	await test_joystick_ownership()
	await test_interrupted_ownership()
	await test_world_replacement()
	await test_inventory_first_and_focus()
	await test_keyboard()
	check(Input.emulate_mouse_from_touch==emulation_before,"test and runtime preserve platform touch-emulation setting")
	if is_instance_valid(shell): await shell.shutdown(); shell.queue_free(); await frames()
	var output:=OS.get_environment("MOBILE_TOUCH_REPORT")
	if not output.is_empty():
		var file:=FileAccess.open(output,FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"root_routed_events":true,"physical_device":false,"safe_area":"simulated platform seam","observations":observations},"\t")); file.close()
	print("MOBILE_DIRECT_TOUCH: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
