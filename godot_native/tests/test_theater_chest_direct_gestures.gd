extends "res://tests/test_theater_chest_focus.gd"
## Real Main input, existing scanner and controller, disposable save profile.

func part_point(id: String) -> Vector2:
	var panel: Control=shell.c3_device_panel
	var control: Control=panel.controls[id]
	var best:=Vector2.INF;var distance:=INF
	for x: int in range(1,20):
		for y: int in range(1,20):
			var point:=control.position+Vector2(control.size.x*x/20.0,control.size.y*y/20.0)
			if panel.pick_part(point)!=id:continue
			var candidate: float=point.distance_squared_to(panel._part_bounds(id).get_center())
			if candidate<distance:distance=candidate;best=point
	check(best.is_finite(),"visible silhouette can be grabbed: "+id)
	return best if best.is_finite() else control.position+control.size*.5

func pointer(point: Vector2, pressed: bool, touch: bool, canceled:=false) -> void:
	var global: Vector2=shell.c3_device_panel.get_global_transform_with_canvas()*point
	if touch:
		var event:=InputEventScreenTouch.new();event.index=0;event.position=global;event.pressed=pressed;event.canceled=canceled
		Input.parse_input_event(event)
	else:
		var event:=InputEventMouseButton.new();event.position=global;event.global_position=global;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
		Input.parse_input_event(event)
	Input.flush_buffered_events()

func move_pointer(point: Vector2, touch: bool) -> void:
	var global: Vector2=shell.c3_device_panel.get_global_transform_with_canvas()*point
	if touch:
		var event:=InputEventScreenDrag.new();event.index=0;event.position=global
		Input.parse_input_event(event)
	else:
		var event:=InputEventMouseMotion.new();event.position=global;event.global_position=global;event.button_mask=MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(event)
	Input.flush_buffered_events();await frames(1)

func slide(from: Vector2, to: Vector2, touch: bool) -> void:
	for index: int in range(1,9):await move_pointer(from.lerp(to,index/8.0),touch)

func drag_piece(id: String, destination: Vector2, touch: bool) -> void:
	var point:=part_point(id);pointer(point,true,touch)
	await slide(point,destination,touch);pointer(destination,false,touch)
	await settle_parts()

func turn_handle(degrees: float, touch: bool, release:=true) -> Vector2:
	var panel: Control=shell.c3_device_panel
	var volume: Node3D=panel.contents.volume
	var source: Vector2=volume.camera.unproject_position(volume.crank.to_global(Vector3(125,60,52)))
	var start: Vector2=panel.art_origin+source*panel.art_scale
	check(panel.pick_part(start)=="axle","the fitted handle itself owns rotation input")
	var center: Vector2=panel.art_origin+Vector2(620,700)*panel.art_scale
	pointer(start,true,touch)
	var end:=start
	for index: int in range(1,13):
		end=center+(start-center).rotated(deg_to_rad(degrees)*index/12.0)
		await move_pointer(end,touch)
	if release:pointer(end,false,touch);await settle_parts()
	return end

func exercise_gestures(dim: Vector2i) -> void:
	await fixture(dim)
	var touch:=dim.x<1000;var label:="touch" if touch else "mouse"
	if not await scan() or not await inside():return
	var panel: Control=shell.c3_device_panel
	var checkpoint: Dictionary=state.d.native.theater_chest.duplicate(true)
	# A locked hatch moves against its stop, never revealing an actionable item.
	var start:=part_point("drawer");var end: Vector2=start+Vector2(0,95)*panel.art_scale
	pointer(start,true,touch);await slide(start,end,touch)
	check(panel.contents.drawer_amount<=.0351 and not state.d.items.fluorescentBrush,"locked hatch resists the pull")
	check(state.d.native.theater_chest==checkpoint,"a held locked hatch has no persistent effect")
	pointer(end,false,touch);await settle_parts()
	check(state.d.native.theater_chest==checkpoint and panel.contents.drawer_amount==0,"failed pull returns to its physical stop")
	# Do not let an expanded touch target lift a still-covered piece.
	start=part_point("fan");end=start+Vector2(-80,15)*panel.art_scale
	pointer(start,true,touch);await slide(start,end,touch)
	check(panel.contents.held_offset.length()<=8.01 and panel.contents.held_lift==0,"buried copper tile has bounded resistance")
	pointer(end,false,touch);await settle_parts()
	check(state.d.native.theater_chest.cleared.is_empty(),"dragging the wrong layer cannot bypass the pile order")
	# Escape, cancellation, resize and focus loss all restore the accepted pose.
	for interruption: String in ["escape","focus","resize","outside","cancel"]:
		start=part_point("butterfly");end=start+Vector2(90,20)*panel.art_scale
		var original: Vector2=panel.contents.part_anchor("butterfly")
		pointer(start,true,touch);await slide(start,end,touch)
		check(panel.contents.part_anchor("butterfly").distance_to(original+Vector2(90,20))<.2,"tile follows the pointer in source coordinates")
		check(state.d.native.theater_chest==checkpoint,"moving a held tile does not persist a clear")
		match interruption:
			"escape":key(KEY_ESCAPE,true);key(KEY_ESCAPE,false)
			"focus":panel._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT);panel._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
			"resize":panel.configure_layout(panel.size,panel.compact_layout)
			"outside":pointer(Vector2(-20,-20),false,touch)
			"cancel":
				if touch:pointer(end,false,true,true)
				else:panel.gestures.cancel()
		check(panel.gestures.capture.is_empty() and panel.contents.held_piece.is_empty(),"interruption releases the gesture: "+interruption)
		check(state.d.native.theater_chest==checkpoint and panel.contents.part_anchor("butterfly").distance_to(original)<.2,"interruption restores the object without a save change: "+interruption)
		pointer(end,false,touch);await frames(1)
	# Pull the top tile away, preserve tap-to-move, then uncover the drawing.
	start=part_point("butterfly");end=panel.art_origin+Vector2(580,453)*panel.art_scale
	pointer(start,true,touch);await slide(start,end,touch)
	await capture(label+"-tile-in-hand")
	pointer(end,false,touch);await settle_parts()
	check(state.d.native.theater_chest.cleared==["butterfly"],"releasing the moved top tile reveals the next layer")
	await tap(panel.controls.fan,touch);await settle_parts()
	check(state.d.native.theater_chest.cleared==["butterfly","fan"],"the original single-tap interaction remains usable")
	await drag_piece("lamp",panel.art_origin+Vector2(830,455)*panel.art_scale,touch)
	check(panel.controls.note.visible and state.d.native.theater_chest.cleared.size()==3,"removing the last layer exposes the existing diagram")
	checkpoint=state.d.native.theater_chest.duplicate(true)
	await drag_piece("butterfly",panel.get_part_rect("slot1").get_center(),touch)
	check(state.d.native.theater_chest==checkpoint and panel.contents.held_piece.is_empty(),"wrong notch shape rejects the drop and returns the tile")
	for index: int in range(3):
		var id: String=["butterfly","lamp","fan"][index]
		start=part_point(id);end=panel.get_part_rect("slot%d"%index).get_center()
		pointer(start,true,touch);await slide(start,end,touch)
		check(state.d.native.theater_chest.slots[index]=="","hovering over a socket does not commit placement")
		pointer(end,false,touch);await settle_parts()
		check(state.d.native.theater_chest.slots[index]==id,"release seats the matching copper tile")
	await drag_piece("crank",panel.get_part_rect("axle").get_center(),touch)
	check(state.d.native.theater_chest.crank_installed and not state.d.native.theater_chest.latch_released,"fitting the handle does not bypass its turn")
	await capture(label+"-assembled")
	await turn_handle(65,touch)
	check(state.d.native.theater_chest.turns==0 and is_zero_approx(panel.contents.turn_angle),"an incomplete turn returns without releasing the latch")
	await turn_handle(-130,touch)
	check(state.d.native.theater_chest.turns==0,"turning against the engraved arrow does not unlock")
	end=await turn_handle(124,touch,false)
	check(state.d.native.theater_chest.turns==0 and panel.contents.volume.latch.position.x<-49,"the rod follows the held handle while progress is still uncommitted")
	if touch:
		var second_point: Vector2=panel.get_global_transform_with_canvas()*panel.get_part_rect("drawer").get_center()
		for down: bool in [true,false]:
			var second:=InputEventScreenTouch.new();second.index=1;second.position=second_point;second.pressed=down
			Input.parse_input_event(second);Input.flush_buffered_events()
		check(int(panel.gestures.capture.get("pointer",-1))==0 and not state.d.native.theater_chest.drawer_open,"a second finger cannot operate the uncommitted latch preview")
	await capture(label+"-handle-turned")
	pointer(end,false,touch);await settle_parts()
	check(state.d.native.theater_chest.turns==1 and state.d.native.theater_chest.latch_released,"release completes the existing one-turn transaction exactly once")
	start=part_point("drawer");end=start+Vector2(0,44)*panel.art_scale
	pointer(start,true,touch);await slide(start,end,touch)
	check(is_equal_approx(panel.contents.drawer_amount,.4) and not state.d.native.theater_chest.drawer_open,"the hatch follows a partial pull without committing")
	pointer(end,false,touch);await settle_parts()
	check(not state.d.native.theater_chest.drawer_open and panel.contents.drawer_amount==0,"a short pull returns the board")
	start=part_point("drawer");end=start+Vector2(0,94)*panel.art_scale
	pointer(start,true,touch);await slide(start,end,touch)
	await capture(label+"-hatch-in-hand")
	check(not state.d.items.fluorescentBrush and not state.d.native.theater_chest.drawer_open,"a held-open preview grants no item")
	pointer(end,false,touch);await settle_parts()
	check(state.d.native.theater_chest.drawer_open and panel.controls.brush.visible,"a full pull opens the existing compartment")
	await capture(label+"-compartment")
	await tap(panel.controls.brush,touch);await settle_parts()
	check(state.d.items.fluorescentBrush and not panel.controls.brush.visible,"the brush is still granted only by its own pickup")
	await tap(panel.controls.close,touch);await closed()
	if await open_box():
		check(shell.c3_device_panel.mechanism.drawer_open and shell.c3_device_panel.mechanism.brush_taken,"reentry restores the accepted mechanism and pickup")
	await teardown()

func reduced_and_replaced_context() -> void:
	await fixture(Vector2i(844,390),true)
	if not await scan() or not await inside():return
	var panel: Control=shell.c3_device_panel
	await drag_piece("butterfly",panel.art_origin+Vector2(580,453)*panel.art_scale,true)
	check(state.d.native.theater_chest.cleared==["butterfly"] and not panel.busy and panel.contents.held_piece.is_empty(),"reduced motion keeps direct dragging and settles immediately")
	var checkpoint: Dictionary=state.d.native.theater_chest.duplicate(true)
	var start:=part_point("fan");pointer(start,true,true)
	await slide(start,start+Vector2(60,40)*panel.art_scale,true)
	state.d=state.d.duplicate(true);panel.refresh()
	check(not panel.active and panel.gestures.capture.is_empty(),"replacing the owning state retires a live gesture")
	check(state.d.native.theater_chest==checkpoint,"state replacement cannot commit the held tile")
	await teardown()

func run() -> void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"gesture checks use disposable storage")
	if failures:quit(1);return
	state=root.get_node("State");state.action_completed.connect(action_seen)
	create_timer(95).timeout.connect(func():push_error("CHEST GESTURE watchdog");quit(2))
	var dimensions: Array[Vector2i]=[Vector2i(1440,900),Vector2i(390,844)]
	if OS.get_cmdline_user_args().has("--desktop-only"):dimensions=[Vector2i(1440,900)]
	if OS.get_cmdline_user_args().has("--portrait-only"):dimensions=[Vector2i(390,844)]
	for dim: Vector2i in dimensions:await exercise_gestures(dim)
	if dimensions.size()>1:await reduced_and_replaced_context()
	print("THEATER_CHEST_DIRECT_GESTURES ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
