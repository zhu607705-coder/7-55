extends SceneTree
## Source-phase fixture, real Main/CC98 controls and root-viewport events.
## This is portable automated coverage, not an earned manual campaign run.
const Gesture=preload("res://scripts/ui/inventory_gesture.gd")
var shell: Control
var state: Node
var checks:=0
var failures:=0
var actions: Array=[]
var feedback: Array=[]
func _initialize() -> void: run.call_deferred()
func frames(n:=4) -> void:
	for i in n: await process_frame
func check(ok: bool,why: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("COMPACT INVENTORY: "+why)
func event(e: InputEvent) -> void:
	Input.parse_input_event(e); Input.flush_buffered_events()
func mouse(point: Vector2,down: bool,double_click:=false) -> void:
	var e:=InputEventMouseButton.new();e.position=point;e.global_position=point;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.double_click=double_click;event(e)
func motion(point: Vector2,delta:=Vector2.ZERO,mask:=0) -> void:
	var e:=InputEventMouseMotion.new();e.position=point;e.global_position=point;e.relative=delta;e.button_mask=mask;event(e)
func touch(point: Vector2,down: bool,canceled:=false) -> void:
	var e:=InputEventScreenTouch.new();e.index=0;e.position=point;e.pressed=down;e.canceled=canceled;event(e)
func finger(point: Vector2,delta: Vector2) -> void:
	var e:=InputEventScreenDrag.new();e.index=0;e.position=point;e.relative=delta;event(e)
func click(control: Control,double_click:=false) -> void:
	check(control!=null and control.is_visible_in_tree(),"routed click has a visible control")
	if control==null: return
	var point:=control.get_global_rect().get_center();motion(point);mouse(point,true,double_click);mouse(point,false);await frames()
func slot(id: String) -> Control: return shell.inventory_buttons.get_node_or_null("WorldItem_"+id)
func reveal(id: String) -> Control:
	var item:=slot(id);shell.inventory_scroll.ensure_control_visible(item);await frames();return item
func world_screen(local: Vector2) -> Vector2:
	return shell.world_view.get_global_transform_with_canvas()*(local*shell.world_view.size/Vector2(shell.world_viewport.size))
func floor_touch_point(direction:=Vector2.RIGHT,distance:=64.0,allow_turn:=true) -> Vector2:
	# Read authoritative geometry only to locate visible clear floor. The real
	# root release still owns picking, path planning, collisions and movement.
	var world:Control=shell.world
	world._update_camera()
	var angles:Array=[0.0]
	if allow_turn:
		for degrees:int in range(15,360,15):angles.append(deg_to_rad(float(degrees)))
	for angle:float in angles:
		for factor:float in [1.0,0.75,0.5,0.375,0.25,1.25,1.5,2.0]:
			var anchor:Vector2=world.player+direction.normalized().rotated(angle)*distance*factor
			var foot:Vector2=world.PlayerMetrics.foot_rect(anchor).get_center()
			var local:Vector2=(foot-world.camera)*world.zoom+world.size/2
			if world.can_stand(anchor) and world.exploration_safe_rect(true).has_point(local) and world._floor_empty_destination(foot) and world._floor_segment_clear(world.player,anchor,world._floor_obstacles(),true):return world_screen(local)
	return Vector2.INF
func tap_floor(point: Vector2) -> void:
	check(point.is_finite(),"fixture locates visible collision-valid empty floor")
	if not point.is_finite():return
	motion(point);touch(point,true);touch(point,false);await frames(2)
	if shell.world._floor_route.is_empty():
		var start_boxes:Array=[]
		for box:Rect2 in shell.world._floor_obstacles():
			if box.has_point(shell.world.player):start_boxes.append(box)
		var open_steps:Array=[]
		for axis:Vector2 in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
			if shell.world.can_stand(shell.world.player+axis*8.25):open_steps.append(axis)
		var local:Vector2=shell.world_view.source_position(shell.world_view.get_global_transform_with_canvas().affine_inverse()*point)
		print("DIRECT_TAP_DIAGNOSTIC ",JSON.stringify({"root":point,"local":local,"rootSize":root.size,"rootVisible":root.get_visible_rect(),"hover":str(root.gui_get_hovered_control()),"disabled":shell.world_viewport.gui_disable_input,"startStand":shell.world.can_stand(shell.world.player),"enclosingObstacles":start_boxes,"openSteps":open_steps,"bounds":shell.world._floor_bounds,"goal":shell.world._floor_goal,"world":shell.world.size,"view":shell.world_view.get_global_rect(),"player":shell.world.player,"role":shell.world._direct_touch_role(local),"status":shell.world._floor_status,"sceneBlocks":shell.world._scene_presentation_blocks(),"shellBlocks":shell.world._shell_input_blocked(),"pointers":shell.world.direct_gestures.pointers,"safe":shell.world.exploration_safe_rect(true)}))
func cancel_floor_touch(point: Vector2) -> void:
	# A new press cancels the route; a cancelled release never creates a new one.
	touch(point,true);touch(point,false,true);await frames(2)
func actor_screen() -> Vector2:
	# Resolve opaque pixels of the rendered actor through its real object picker.
	for y in range(-30,31,2):
		for x in range(-20,21,2):
			var point: Vector2=shell.world.player+Vector2(x,y)
			if shell.world.object_picker.pick(point,shell.world.targets,true).get("id","")=="dorm_gamepad":
				return world_screen((point-shell.world.camera)*shell.world.zoom+shell.world.size/2)
	return Vector2.INF
func begin_drag(item: Control,using_touch: bool) -> Vector2:
	var start:=item.get_global_rect().get_center()
	if using_touch:
		touch(start,true);finger(start-Vector2(0,18),Vector2(0,-18))
	else:
		motion(start);mouse(start,true);motion(start-Vector2(0,18),Vector2(0,-18),MOUSE_BUTTON_MASK_LEFT)
	await frames(2)
	check(root.gui_is_dragging(),"upward item movement owns the native drag")
	return start-Vector2(0,18)
func drag_item(id: String,end: Vector2,using_touch:=false,cancel:=false) -> void:
	var item: Control=await reveal(id);var from: Vector2=await begin_drag(item,using_touch)
	for i in range(1,5):
		var point:=from.lerp(end,i/4.0)
		if using_touch: finger(point,(end-from)/4)
		else: motion(point,(end-from)/4,MOUSE_BUTTON_MASK_LEFT)
		await process_frame
	if using_touch: touch(end,false,cancel)
	elif cancel:
		var e:=InputEventKey.new();e.keycode=KEY_ESCAPE;e.pressed=true;event(e);mouse(end,false)
	else: mouse(end,false)
	await frames()
	check(not root.gui_is_dragging(),"release clears native drag")
func fixture(dimensions: Vector2i) -> void:
	shell._close_modal();state.d=state.initial();state.developer_mode=true
	state.d.native.chapter=2;state.d.native.page="cc98";state.d.actOne.phase="movement_required"
	state.d.flags.checkinDone=true;state.d.actOne.dormHubUnlocked=true;state.d.actOne.inventoryRecovered=true
	state.d.actOne.cc98Login.authenticated=true;state.d.actOne.cc98Login.studentIdDiscovered=true
	state.d.actOne.characterNamed=true;state.d.actOne.exerciseStarted=true;state.d.actOne.balanceShifted=true
	state.d.wallet.campusCardCents=600;state.d.networkMode="campus_wifi"
	for id in ["waterDrop","headphone","wateredHeadphone","reverseGear","slashLine","towerKey","fertilizer","campusCard","pushTriangle","weatherWater","mentorLine","rightArrow","occupancyNote"]:state.d.items[id]=true
	root.size=dimensions;shell.size=Vector2(dimensions);shell.mobile_world=false;shell.compact_inventory_open=false
	shell.phone_builder.cc98_post="act-two-gamepad-market";shell._refresh();await frames()
	await click(shell.find_child("Cc98GamepadPurchase",true,false))
	check(state.d.items.gamepad and state.d.wallet.campusCardCents==0,"real purchase creates exactly one gamepad")
	await click(shell.find_child("Cc98GamepadReturn",true,false));await frames(6)
	shell.world.set_process(false)
	check(state.d.native.scene=="dorm_hub" and shell.world_frame.visible,"actual return opens dorm world")
	check(not shell.inventory_handle.visible and shell.inventory_dock.visible,"items are directly available without a bag toggle")
	check(shell.world_view.get_global_rect().encloses(shell.inventory_dock.get_global_rect()),"inline items stay inside the actual game image")
	check(shell.inventory_dock.visible and not slot("gamepad").disabled,"world owns a visible enabled item source")
	# Compact exploration fills its physical frame; desktop retains 960x540.
	var expected_viewport:Vector2i=Vector2i(shell.world_frame.size-Vector2(4,4)) if dimensions.x<1100 else Vector2i(960,540)
	check(shell.world_viewport.size==expected_viewport and is_equal_approx(shell.world_frame.scale.x,shell.world_frame.scale.y),"active exploration viewport and uniform scale retained")
	check(shell.world_view.get_global_rect().encloses(shell.inventory_dock.get_global_rect()),"inventory overlays the actual map without resizing it")
	check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(shell.inventory_dock.get_global_rect()),"bag fits physical screen")
	check(slot("gamepad").get_global_rect().size.y>=44,"item retains44px physical height")
	check(actor_screen().is_finite(),"rendered actor exposes actual gamepad target")
func run() -> void:
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	state.action_completed.connect(func(id,_a,_b,_c):actions.append(id));state.feedback.connect(func(text):feedback.append(text))
	var baseline:=Input.emulate_mouse_from_touch
	for dimensions in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		await fixture(dimensions)
		var item:Control=await reveal("gamepad");var identity:=item.get_instance_id();var position:=item.get_global_rect();var scroll:int=shell.inventory_scroll.scroll_horizontal
		item.grab_focus();await click(item)
		check(state.d.native.selected_item=="gamepad" and not is_instance_valid(shell.modal),"one click selects without inspection")
		check(slot("gamepad").get_instance_id()==identity and slot("gamepad").get_global_rect()==position and shell.inventory_scroll.scroll_horizontal==scroll,"selection preserves node position and scroll")
		check(root.gui_get_focus_owner()==item,"selection refresh retains focus")
		await click(item,true)
		check(is_instance_valid(shell.modal) and shell.inspected_item_id=="gamepad","native double click opens item details")
		check(item.disabled and shell.inventory_handle.disabled,"inspection blocks background inventory")
		shell._close_modal();await frames();await create_timer(.26).timeout
		shell.inventory_gestures.reset();var point:=item.get_global_rect().get_center()
		for i in 2: touch(point,true);touch(point,false)
		await frames();check(is_instance_valid(shell.modal) and shell.inspected_item_id=="gamepad","touch pair within380ms opens same details")
		shell._close_modal();await frames();await create_timer(.26).timeout
		item=await reveal("gamepad");point=item.get_global_rect().get_center();scroll=shell.inventory_scroll.scroll_horizontal
		touch(point,true);finger(point+Vector2(55,0),Vector2(55,0));touch(point+Vector2(55,0),false);await frames()
		check((shell.inventory_scroll.scroll_horizontal<scroll or (scroll==0 and shell.inventory_scroll.scroll_horizontal==0)) and not root.gui_is_dragging(),"fast horizontal finger scrolls or stays at the leading edge without item drag")
		check(not is_instance_valid(shell.modal),"swipe does not inspect")
		item=await reveal("gamepad");point=item.get_global_rect().get_center()
		touch(point,true)
		check(item._touch_index==0,"hold fixture owns a genuinely delivered touch")
		var touch_started_ms:int=item._touch_time
		# Hold recognition uses monotonic delivery time, not SceneTree frame delta.
		while Time.get_ticks_msec()-touch_started_ms<221: await process_frame
		finger(point+Vector2(-18,0),Vector2(-18,0));await frames()
		check(root.gui_is_dragging(),"220ms hold allows deliberate horizontal item drag")
		touch(point,false,true);await frames();check(Input.emulate_mouse_from_touch==baseline,"cancel restores exact touch emulation setting")
		await drag_item("campusCard",actor_screen())
		check(state.d.items.campusCard and state.d.items.gamepad and not state.d.actOne.controlsInstalled,"wrong item on real actor is retained")
		await drag_item("gamepad",world_screen(Vector2(shell.world.size.x-32,70)))
		check(state.d.items.gamepad and not state.d.actOne.controlsInstalled,"miss within world retains gamepad")
		await drag_item("gamepad",actor_screen(),true,true)
		check(state.d.items.gamepad and not state.d.actOne.controlsInstalled,"canceled touch drop retains gamepad")
		item=await reveal("gamepad");await begin_drag(item,true);shell.inventory_dock.hide();await frames()
		check(not root.gui_is_dragging() and Gesture.touch_owner()==null and Input.emulate_mouse_from_touch==baseline,"hiding dock cancels drag and restores touch owner")
		touch(Vector2.ZERO,false,true);shell._layout();await frames()
		item=await reveal("gamepad");await begin_drag(item,true)
		shell.size+=Vector2(2,0);shell._layout();await frames()
		check(not root.gui_is_dragging() and Gesture.touch_owner()==null and state.d.items.gamepad,"resize cancels item gesture without using it")
		touch(Vector2.ZERO,false,true);shell.size=Vector2(dimensions);shell._layout();await frames()
		# A real game host hides both bag surfaces, then restores prior open state.
		shell._open_game({"script":"res://scripts/games/virtual_run.gd","viewport":[430,860]});await frames()
		check(not shell.inventory_dock.visible and not shell.inventory_handle.visible and item.disabled,"active game hides and disables background bag")
		if is_instance_valid(shell.active_game): shell.active_game.cancelled.emit()
		await frames();check(shell.inventory_dock.visible and not item.disabled,"game cancellation restores bag")
		# Real document and narrative guards prevent focus-owned activation too.
		shell._open_phone_document({"item_id":"occupancyNote"});await frames()
		check(item.disabled and shell.inventory_handle.disabled,"phone document blocks compact inventory")
		shell._close_phone_document();await frames()
		state.begin_checkpoint("c2-seat-dialogue");shell._refresh();await frames()
		check(slot("gamepad")==null or slot("gamepad").disabled,"authored opening narrative blocks inventory")
		state.d=state.initial();state.d.native.chapter=3;state.d.native.scene="canteen_interior";state.d.native.page="c3_canteen"
		state.d.canteenHunt.active=true;state.d.canteenHunt.phase="tray_search";state.d.canteenHunt.entryPaperEscaped=true
		state.d.items.campusCard=true;state.d.runtimeMode="rpg";shell.mobile_world=true;shell.compact_inventory_open=true;shell._refresh();await frames()
		shell.world.player=Vector2(1466,608);shell.world._sync_player()
		state.act("c3_target:auntie");await frames();var story:RefCounted=state.get_c3_narrative_session()
		check(story!=null and not story.blocks_movement() and state.story_input_locked(),"ordinary authored C3 dialogue locks interaction while permitting movement")
		item=await reveal("campusCard");point=item.get_global_rect().get_center()
		mouse(point,true);mouse(point,false);mouse(point,true,true);mouse(point,false)
		for i in 2: touch(point,true);touch(point,false)
		await frames();check(item.disabled and not is_instance_valid(shell.modal),"timed C3 dialogue rejects dock mouse and touch double-inspection")
		state.d=state.initial();state.d.native.chapter=2;state.d.native.scene="campus_bootstrap";state.d.native.page="phone_home"
		state.d.actOne.phase="complete";state.d.actOne.inventoryRecovered=true;state.d.ui.libraryFinalsPhase="library_route_unlocked";state.d.items.rightArrow=true
		state.act("lib_enter");shell._refresh();await frames()
		check(state.get_library_story_session()!=null and slot("rightArrow").disabled,"authored library entry owns input over bag")
		# New explicit fixture restores the same authorized movement phase.
		await fixture(dimensions)
		var action_count:=actions.count("c2_use_gamepad")
		await drag_item("gamepad",actor_screen(),dimensions.x<1100)
		check(state.d.actOne.controlsInstalled and not state.d.items.gamepad and actions.count("c2_use_gamepad")==action_count+1,"routed root drag reaches actual actor once through SubViewport")
		check(not state.d.actOne.manualControlTested,"installing does not synthesize manual movement")
		var before:Vector2=shell.world.player;shell.world.set_process(true)
		var key:=InputEventKey.new();key.keycode=KEY_D;key.physical_keycode=KEY_D;key.pressed=true;event(key)
		await create_timer(.14).timeout;key.pressed=false;event(key);await frames();shell.world.set_process(false)
		check(shell.world.player.distance_to(before)>0 and state.d.actOne.manualControlTested and actions.has("c2_manual_input"),"actual D key moves player and records manual-input proof")
		if shell.world.mobile_exploration:
			var floor_point:=floor_touch_point(Vector2.LEFT);before=shell.world.player
			await tap_floor(floor_point)
			check(not shell.world._floor_route.is_empty() and Gesture.touch_owner()==null and not root.gui_is_dragging(),"real floor tap owns a collision route while bag remains open")
			shell.world.set_process(true);await create_timer(.1).timeout;shell.world.set_process(false)
			await cancel_floor_touch(floor_point)
			check(shell.world.player.distance_to(before)>0 and shell.world._floor_route.is_empty() and not shell.world.direct_gestures.has_active(),"floor movement advances and cancellation retires route without inventory drag")
		else:
			before=shell.world.player;key=InputEventKey.new();key.keycode=KEY_A;key.physical_keycode=KEY_A;key.pressed=true;event(key)
			shell.world.set_process(true);await create_timer(.1).timeout;key.pressed=false;event(key);await frames();shell.world.set_process(false)
			check(shell.world.player.distance_to(before)>0 and Gesture.touch_owner()==null and not root.gui_is_dragging(),"desktop keyboard remains independent of inventory drag")
		if dimensions.x<1100:
			var before_rect:Rect2=shell.world_view.get_global_rect()
			shell._toggle_world_inventory();await frames()
			check(shell.inventory_dock.visible and not shell.inventory_handle.visible and shell.world_view.get_global_rect()==before_rect,"legacy bag request cannot resize or hide inline items")
			root.size=Vector2i(844,390);shell.size=Vector2(844,390);shell._layout();await frames()
			check(shell.inventory_dock.visible and shell.world_view.get_global_rect().encloses(shell.inventory_dock.get_global_rect()),"inline items remain within the landscape map")
			root.size=dimensions;shell.size=Vector2(dimensions);shell._layout();await frames()
			check(shell.inventory_dock.visible,"inline items survive return to portrait")
	Input.emulate_mouse_from_touch=baseline
	await shell.shutdown();shell.queue_free();await frames()
	print("COMPACT_WORLD_INVENTORY: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
