extends SceneTree
## PR160 adapted to the existing local no-fixed-controls scheme.
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
	check(shell.world.touch_axis==Vector2.ZERO and not shell.world.direct_gestures.has_active(),label+" clears movement and pointer owners")
	check(shell.world._floor_route.is_empty(),label+" does not leave a floor route")

func held_point() -> Vector2:return visible_pick()

func assert_layout(insets: Vector4) -> void:
	var safe:=Rect2(insets.x,insets.y,shell.size.x-insets.x-insets.z,shell.size.y-insets.y-insets.w)
	var metrics:Dictionary=shell.world.mobile_control_metrics()
	check(shell.world.mobile_exploration,"compact exploration owns viewport")
	check(metrics.scheme=="direct_world" and not metrics.has("stick") and not metrics.has("interact"),"local scene gestures keep fixed joystick and confirmation button removed")
	check(metrics.gestureArea==shell.world.exploration_safe_rect(),"gesture area is actual visible scene, with no control strip")
	check(safe.encloses(shell.world_frame.get_global_rect()),"world frame fits platform safe area")
	for control:Control in [shell.mobile_back,shell.world_tasks,shell.world_mode,shell.inventory_dock]:
		if control.visible:check(safe.encloses(control.get_global_rect()),control.name+" fits platform safe area")
	check(not shell.inventory_handle.visible,"local bag toggle remains removed")
	check(not shell.inventory_dock.visible or shell.world_view.get_global_rect().encloses(shell.inventory_dock.get_global_rect()),"existing inline inventory remains inside game viewport")
	var map:Rect2=shell.world_view.get_global_rect()
	var back:Rect2=shell.mobile_back.get_global_rect()
	check(absf(back.end.x-(map.end.x-8))<.01 and absf(back.end.y-(map.end.y-8))<.01 and back.size.x>=44 and back.size.y>=44,"phone icon retains a physical44px target in the map's bottom right")
	check(shell.world.size==Vector2(shell.world_viewport.size),"world pixels match SubViewport exactly")
	observations.append({"size":str(shell.size),"safe":str(safe),"world":str(shell.world_frame.get_global_rect()),"gestureArea":str(metrics.gestureArea)})

func plaque_character_rects() -> Array[Rect2]:
	var result:Array[Rect2]=[]
	var overlay:Control=shell.world.selected_overlay
	for line:Label in [overlay.object_heading,overlay.object_body,overlay.object_hint]:
		if not line.is_visible_in_tree():continue
		for index:int in line.get_total_character_count():
			if line.text.substr(index,1).strip_edges().is_empty():continue
			var glyph:Rect2=line.get_character_bounds(index)
			if not glyph.has_area():continue
			var ink:Rect2=glyph.grow(line.get_theme_constant("outline_size"))
			var shadow:=Rect2(glyph.position+Vector2(line.get_theme_constant("shadow_offset_x"),line.get_theme_constant("shadow_offset_y")),glyph.size).grow(line.get_theme_constant("shadow_outline_size"))
			result.append(line.get_global_transform_with_canvas()*ink.merge(shadow))
	return result
func assert_mobile_plaque_at_bottom(label: String) -> void:
	var overlay:Control=shell.world.selected_overlay
	var plaque:Rect2=overlay.plaque.get_global_rect()
	var region:Rect2=shell.world_view.get_global_rect()
	var insets:Vector4=shell.test_safe_insets
	var safe:=Rect2(insets.x,insets.y,shell.size.x-insets.x-insets.z,shell.size.y-insets.y-insets.w)
	var metrics:Dictionary=shell.world.mobile_control_metrics()
	check(metrics.scheme=="direct_world" and not metrics.has("stick"),label+" retains direct scene gestures")
	check(shell.world.mobile_exploration and overlay.plaque.is_visible_in_tree(),label+" has a confirmed mobile plaque")
	check(region.encloses(plaque) and safe.encloses(plaque),label+" stays entirely in the game viewport and simulated safe area")
	check(absf(plaque.get_center().x-region.get_center().x)<=1,label+" remains horizontally centered")
	check(plaque.end.y>=region.position.y+region.size.y*.6,label+" uses the lower playfield above the inline tools")
	# The local version keeps its tools and items inside the game viewport.
	# Check actual character/shadow envelopes against those visible controls.
	var characters:=plaque_character_rects()
	var visible_overlap:=false;var characters_contained:=true
	for character:Rect2 in characters:
		for control:Control in [shell.world_tasks,shell.world_mode,shell.mobile_back,shell.inventory_dock]:
			if control.is_visible_in_tree() and character.intersects(control.get_global_rect()):visible_overlap=true
		if not region.encloses(character) or not safe.encloses(character):characters_contained=false
	check(not characters.is_empty(),label+" checks actual nonblank character bounds")
	check(not visible_overlap,label+" text and its shadow do not overlap visible tools or items")
	check(characters_contained,label+" complete characters and shadows remain inside world and safe area")
	for control:Control in [shell.inventory_handle,shell.inventory_dock]:
		if control.is_visible_in_tree():check(not plaque.intersects(control.get_global_rect()),label+" remains above existing inventory chrome")
	check(overlay.mouse_filter==Control.MOUSE_FILTER_IGNORE and overlay.plaque.mouse_filter==Control.MOUSE_FILTER_IGNORE,label+" remains passive text, not an extra interaction button")
	observations.append({"size":str(shell.size),"world":str(region),"plaque":str(plaque),"plaque_bottom_gap":region.end.y-plaque.end.y,"inventory_open":shell.compact_inventory_open})
func confirm_and_check_bottom_plaque() -> void:
	var point:=visible_pick();var count:=action_count();var was_on:=lamp()
	check(not shell.world.selected_overlay.plaque.visible,"layout fixture arrival still has no automatic plaque")
	touch(point,true);touch(point,false);await frames(8)
	check(action_count()==count+1 and lamp()!=was_on,"layout probe confirms the actual nearby source object through root touch")
	assert_mobile_plaque_at_bottom("confirmed layout")
	var before:Rect2=shell.world.selected_overlay.plaque.get_global_rect()
	await frames(8)
	check(shell.world.selected_overlay.plaque.get_global_rect().is_equal_approx(before),"container settlement cannot move the confirmed bottom plaque back to the center")
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
	assert_mobile_plaque_at_bottom("direct tap")
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
	shell.world.player=FAR;shell.world.pan_offset=Vector2(110,0)
	shell.world._sync_player();shell.world._process(0);shell.world.queue_redraw();await frames()
	check(shell.world._distance(target())>float(target().radius)*.5,"far fixture is outside unchanged source range")
	var point:=visible_pick();var count:=action_count()
	check(point.is_finite(),"far target remains physically visible")
	touch(point,true);touch(point,false);await frames()
	check(action_count()==count and not lamp(),"far tap cannot activate remotely; any local approach must physically reach original range")
	# Preserve the local physical approach, covered by test_direct_world_input.
	# Cancel it before a different movement intent; it must never resume later.
	shell.world.cancel_exploration_gestures();shell.world.pan_offset=Vector2.ZERO
	for unused in 16:
		shell.world.touch_axis=Vector2.RIGHT;shell.world._process(.05)
	shell.world.touch_axis=Vector2.ZERO;shell.world._process(0);await frames()
	check(shell.world._distance(target())<=float(target().radius)*.5,"ordinary movement reaches source range")
	check(action_count()==count and not lamp(),"arrival cannot revive a canceled far approach")
	check(not shell.world.selected_overlay.plaque.visible,"arrival alone exposes no confirmed object title")

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
func test_root_capture() -> void:
	for pointer in ["touch","mouse"]:
		await fixture();var point:=visible_pick();var count:=action_count()
		if pointer=="touch":
			touch(point,true,3);touch(point,true,3)
		else:mouse(point,true);mouse(point,true)
		check(shell.world.direct_gestures.has_active(),pointer+" acquires one real scene pointer")
		if pointer=="touch":
			drag(Vector2(-40,-40),Vector2(-200,-200),3);touch(Vector2(-40,-40),false,3)
		else:
			motion(Vector2(-40,-40),Vector2(-200,-200));mouse(Vector2(-40,-40),false)
		await frames();held_clear(pointer+" release outside viewport")
		check(action_count()==count and not lamp(),pointer+" outside release never confirms object")
	# Two map fingers retain the local shared pinch/pan owner.
	await fixture();var count:=action_count();var zoom:float=shell.world.zoom
	var a:=world_screen(Vector2(140,200));var b:=world_screen(Vector2(250,200))
	touch(a,true,3);touch(b,true,4);drag(b+Vector2(30,0),Vector2(30,0),4);await frames()
	check(shell.world.zoom>zoom and action_count()==count,"root-routed pinch changes camera without interacting")
	touch(Vector2(-40,-40),false,3);touch(b+Vector2(30,0),false,4);await frames();held_clear("pinch release")

func test_interrupted_ownership() -> void:
	for boundary in ["focus","resize","modal","phone","inventory"]:
		await fixture();var point:=visible_pick();var count:=action_count()
		touch(point,true,5);await frames();check(shell.world.direct_gestures.has_active(),boundary+" begins with an owned scene pointer")
		var item:Control=shell.inventory_buttons.get_node_or_null("WorldItem_campusCard")
		match boundary:
			"focus":shell.world.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
			"resize":root.size=Vector2i(844,390);shell.size=Vector2(844,390);shell._layout()
			"modal":shell._show_journal()
			"phone":shell._show_phone_surface()
			"inventory":
				shell.inventory_scroll.ensure_control_visible(item);await frames()
				touch(item.get_global_rect().get_center(),true,6);shell.world._process(0)
		await frames();held_clear(boundary)
		touch(point,false,5)
		if boundary=="inventory":touch(item.get_global_rect().get_center(),false,6)
		await frames();check(action_count()==count,boundary+" late release cannot confirm object")
		if boundary=="modal":shell._close_modal()
		if boundary=="phone":shell._show_world_mobile()
		await frames();held_clear(boundary+" restored")
	await fixture();var point:=visible_pick();var count:=action_count()
	touch(point,true);shell._show_journal();await frames();shell._close_modal();await frames();touch(point,false);await frames()
	check(action_count()==count and not lamp(),"modal open/close cannot revive an old object press")

func test_world_replacement() -> void:
	for boundary in ["teleport","scene"]:
		await fixture(); var point:=held_point(); var count:=action_count()
		touch(point,true,9); await frames(); check(shell.world.direct_gestures.has_active(),boundary+" starts with a held world pointer")
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
	check(item!=null,"multitouch fixture retains original inventory item")
	if item==null:return
	shell.inventory_scroll.ensure_control_visible(item);await frames()
	var count:=action_count();var point:=visible_pick()
	touch(point,true,0);touch(item.get_global_rect().get_center(),true,1)
	shell.world._process(0);await frames();held_clear("world-first inventory acquisition")
	touch(point,false,0);touch(item.get_global_rect().get_center(),false,1);await frames()
	held_clear("inventory multitouch release")
	check(action_count()==count and not lamp() and state.d.items.campusCard,"inventory sequence cannot confirm object or consume wrong item")
	check(not shell.inventory_handle.visible and shell.inventory_dock.visible,"local inline inventory stays exposed without bag toggle")

func test_keyboard() -> void:
	await fixture(Vector2i(1440,900))
	check(not shell.world.mobile_exploration and shell.world.size==Vector2(960,540),"desktop keeps canonical world")
	shell.world.grab_focus(); var count:=action_count(); key(KEY_SPACE,true); key(KEY_SPACE,false); await frames()
	check(action_count()==count+1 and lamp(),"desktop Space retains existing nearby interaction")
	var overlay:Control=shell.world.selected_overlay
	var plaque_height:float=overlay.plaque.get_combined_minimum_size().y
	var bottom_y:float=maxf(8,overlay._plaque_bottom_limit-plaque_height-8)
	check(overlay.plaque.visible and absf(overlay.plaque.position.y-bottom_y)<=1,"desktop interaction plaque retains the chosen bottom-safe layout")
	check(absf(overlay.plaque.get_global_rect().get_center().x-shell.world_view.get_global_rect().get_center().x)<=1,"desktop plaque keeps its original horizontal center")
	var before:Vector2=shell.world.player; key(KEY_A,true); shell.world._process(.05); key(KEY_A,false); await frames()
	check(shell.world.player.x<before.x,"desktop direction key still moves")
func test_browser_cancel_boundary() -> void:
	await fixture()
	var point:=visible_pick();var count:=action_count()
	touch(point,true,0);await frames(2)
	check(shell.world.direct_gestures.pointers.has(0),"browser cancellation starts with an owned real scene touch")
	var platform=load("res://scripts/platform/web_platform.gd").new()
	platform._on_browser_touch_cancel(["[0]"]);await frames()
	check(not shell.world.direct_gestures.has_active() and action_count()==count and not lamp(),"browser cancelled release clears ownership without accepting an object")
	touch(point,false,0);await frames()
	check(action_count()==count and not lamp(),"pinned engine's following ordinary release cannot revive cancelled touch")
	platform.free()
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
			await confirm_and_check_bottom_plaque()
	await test_direct_tap()
	await test_no_remote_or_arrival()
	await test_drag_and_cancel()
	await test_root_capture()
	await test_interrupted_ownership()
	await test_world_replacement()
	await test_inventory_first_and_focus()
	await test_keyboard()
	await test_browser_cancel_boundary()
	check(Input.emulate_mouse_from_touch==emulation_before,"test and runtime preserve platform touch-emulation setting")
	if is_instance_valid(shell): await shell.shutdown(); shell.queue_free(); await frames()
	var output:=OS.get_environment("MOBILE_TOUCH_REPORT")
	if not output.is_empty():
		var file:=FileAccess.open(output,FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"root_routed_events":true,"physical_device":false,"safe_area":"simulated platform seam","observations":observations},"\t")); file.close()
	print("MOBILE_DIRECT_TOUCH: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
