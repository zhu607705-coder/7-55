extends SceneTree
class TouchDeliveryClock extends Node:
	var release_ms: Array[int]=[]
	func _input(event: InputEvent) -> void:
		if event is InputEventScreenTouch and event.index==0 and not event.pressed:
			release_ms.append(Time.get_ticks_msec())
var touch_delivery_clock: TouchDeliveryClock
var shell: Control
var state: Node
var checks:=0
var failures:=0
var messages: Array=[]
var actions: Array=[]
func _initialize() -> void: run.call_deferred()
func frames(n:=3) -> void:
	for i in n: await process_frame
func check(ok: bool, why: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(why)
func named(id: String) -> Control: return shell.find_child(id,true,false)
func emit_mouse(point: Vector2, pressed: bool, native_double_click:=false) -> void:
	var event:=InputEventMouseButton.new(); event.position=point; event.global_position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=pressed; event.double_click=native_double_click
	Input.parse_input_event(event); await process_frame
func tap(control: Control, touch:=false, native_double_click:=false) -> void:
	var point:=control.get_global_rect().get_center()
	if touch:
		for pressed in [true,false]:
			var e:=InputEventScreenTouch.new();e.index=0;e.position=point;e.pressed=pressed;Input.parse_input_event(e);await process_frame
	else:
		var move:=InputEventMouseMotion.new();move.position=point;move.global_position=point;Input.parse_input_event(move)
		await emit_mouse(point,true,native_double_click); await emit_mouse(point,false)
	await frames(2)
func bounded_touch_double_tap(control: Control) -> void:
	# Input.parse_input_event buffers until flush. Frame waits between taps can
	# exceed the real380ms contract under load; deliver this fast pair explicitly.
	var point:=control.get_global_rect().get_center()
	var inspected: Array=[]
	var observe_inspect:=func(entry: Dictionary): inspected.append(str(entry.id))
	shell.phone_chrome.inspect_requested.connect(observe_inspect)
	touch_delivery_clock.release_ms.clear()
	for tap_index in 2:
		for pressed in [true,false]:
			var event:=InputEventScreenTouch.new();event.index=0;event.position=point;event.pressed=pressed
			Input.parse_input_event(event);Input.flush_buffered_events()
		if tap_index==0: check(not is_instance_valid(shell.modal),"Touch tap selects without inspection")
	var releases: Array=touch_delivery_clock.release_ms
	var gap:=int(releases[1])-int(releases[0]) if releases.size()==2 else -1
	print("TOUCH_PAIR_DELIVERY ",JSON.stringify({"dimensions":str(root.size),"release_gap_ms":gap}))
	check(gap>=0 and gap<=380,"Fixture delivered two touch releases inside380ms")
	await frames(2)
	check(is_instance_valid(shell.modal) and shell.inspected_item_id=="headphone" and inspected==["headphone"],"Touch double tap inspects once")
	shell.phone_chrome.inspect_requested.disconnect(observe_inspect)
func art_point(source: Vector2) -> Vector2:
	var plant: TextureRect=named("BonsaiPlant").hit_texture
	var factor:=maxf(plant.size.x/plant.texture.get_width(),plant.size.y/plant.texture.get_height())
	return plant.get_global_transform_with_canvas()*((plant.size-plant.texture.get_size()*factor)/2+source*factor)
func drag(item: String,end: Vector2,touch:=false,cancel:=false) -> void:
	var source=named("Item_"+item);var start:Vector2=source.get_global_rect().get_center()
	if touch:
		var down:=InputEventScreenTouch.new();down.index=0;down.position=start;down.pressed=true;Input.parse_input_event(down);await process_frame
	else: await emit_mouse(start,true)
	var last:=start
	for i in range(1,10):
		var point:=start.lerp(end,i/9.0)
		if touch:
			var motion:=InputEventScreenDrag.new();motion.index=0;motion.position=point;motion.relative=point-last;Input.parse_input_event(motion)
		else:
			var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;motion.relative=point-last;motion.button_mask=MOUSE_BUTTON_MASK_LEFT;Input.parse_input_event(motion)
		last=point;await process_frame
	check(root.gui_is_dragging(),"Drag starts after displacement, %s"%['touch' if touch else 'mouse'])
	if touch:
		var up:=InputEventScreenTouch.new();up.index=0;up.position=end;up.canceled=cancel;Input.parse_input_event(up)
	elif cancel:
		var esc:=InputEventKey.new();esc.keycode=KEY_ESCAPE;esc.pressed=true;Input.parse_input_event(esc)
		await emit_mouse(end,false)
	else: await emit_mouse(end,false)
	await frames(5)
	check(not root.gui_is_dragging(),"Release/cancel clears drag")
func reset(dimensions: Vector2i) -> void:
	root.size=dimensions;shell.size=Vector2(dimensions)
	state.d=state.initial();state.d.native.page="bonsai";state.d.flags.codeScattered=true;state.d.ui.brightness=35
	for id in ["headphone","wateredHeadphone","fertilizer","reverseGear","occupancyNote"]:state.d.items[id]=true
	if dimensions.x>=1100: state.d.native.scene="dorm_hub"
	state.d.ui.inventoryOpen=true;shell.phone_chrome.inventory_gestures.reset();shell.inventory_gestures.reset();shell._refresh();await frames(5)
func run() -> void:
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	touch_delivery_clock=TouchDeliveryClock.new();root.add_child(touch_delivery_clock)
	state.feedback.connect(func(text):messages.append(text));state.action_completed.connect(func(id,_a,_b,_c):actions.append(id))
	for dimensions in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		await reset(dimensions)
		await tap(named("Item_headphone"));check(not is_instance_valid(shell.modal),"Single click only selects");check(state.d.native.selected_item=="headphone","Single click selection")
		await tap(named("Item_headphone"),false,true);check(is_instance_valid(shell.modal) and shell.inspected_item_id=="headphone","Double click inspects")
		check(named("InventoryObservation").text==state.content("items.config.json")[1].desc,"Inspection reuses exact canonical prose")
		shell._close_modal();await frames();check(not is_instance_valid(shell.modal),"Close returns to scene")
		await tap(named("Item_headphone"));check(not is_instance_valid(shell.modal),"After close first tap does not re-open")
		shell.phone_chrome.inventory_gestures.reset()
		shell.phone_chrome.inventory_scroll.ensure_control_visible(named("Item_occupancyNote"));await frames()
		await tap(named("Item_occupancyNote"));check(not is_instance_valid(shell.modal),"Paper single click selects")
		await tap(named("Item_occupancyNote"),false,true);check(is_instance_valid(shell.modal) and shell.inspected_item_id=="occupancyNote","Paper double click opens source evidence")
		shell._close_modal();shell.phone_chrome.inventory_scroll.scroll_vertical=0;await frames()
		if dimensions.x==1440:
			shell._show_world_mobile();shell.compact_inventory_open=true;shell._layout();await frames()
			var dock:Control=shell.inventory_buttons.get_child(0)
			await tap(dock);check(not is_instance_valid(shell.modal),"World dock single click selects")
			dock=shell.inventory_buttons.get_child(0);await tap(dock,false,true);check(is_instance_valid(shell.modal),"World dock double click inspects")
			shell._close_modal();shell.mobile_world=false;shell._layout();await frames()
		var target=named("BonsaiPlant");var center:=art_point(Vector2(470,1080));var outside:=art_point(Vector2(740,1030))
		check(target._has_point(target.get_global_transform_with_canvas().affine_inverse()*center),"Pot surface hit follows actual scaled/cropped image")
		check(not target._has_point(target.get_global_transform_with_canvas().affine_inverse()*outside),"Background beside pot is not a target")
		for sample in [[Vector2(292,1000),true],[Vector2(288,1000),false],[Vector2(470,720),true]]:
			check(target._has_point(target.get_global_transform_with_canvas().affine_inverse()*art_point(sample[0]))==sample[1],"Measured visible edge/bud matches source pixels")
		var before:=actions.count("c1_plant");await drag("wateredHeadphone",outside)
		check(actions.count("c1_plant")==before and state.d.items.wateredHeadphone,"Miss does not dispatch or consume")
		check(messages.back().begins_with("没有落在"),"Miss gives a neutral visible result")
		await drag("reverseGear",center);check(state.d.items.reverseGear and not state.d.flags.plantWatered,"Wrong item retained")
		await drag("wateredHeadphone",center,false,true);check(state.d.items.wateredHeadphone and not state.d.flags.plantWatered,"Escape cancel cannot use item")
		await drag("wateredHeadphone",center);check(state.d.flags.plantWatered and not state.d.items.wateredHeadphone,"Actual precise drop consumed only by accepting controller")
		await frames(12);center=art_point(Vector2(470,1080));target=named("BonsaiPlant")
		check(target._has_point(target.get_global_transform_with_canvas().affine_inverse()*center),"Hit follows grown art pivot/scale")
		await drag("fertilizer",Vector2(-30,-30));check(state.d.items.fertilizer,"Release outside viewport keeps item")
		await reset(dimensions)
		await bounded_touch_double_tap(named("Item_headphone"))
		shell._close_modal();await frames();await create_timer(.3).timeout
		center=art_point(Vector2(470,1080));await drag("wateredHeadphone",center,true,true)
		check(state.d.items.wateredHeadphone and not state.d.flags.plantWatered,"Touch cancel keeps item")
		await create_timer(.3).timeout;await drag("wateredHeadphone",center,true)
		check(state.d.flags.plantWatered and not state.d.items.wateredHeadphone,"Touch uses same controller-accepted drop")
	await shell.shutdown();shell.queue_free();await frames()
	print("INVENTORY_PRECISION: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
