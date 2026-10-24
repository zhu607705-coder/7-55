extends SceneTree
const Chapter=preload("res://scripts/chapters/chapter4.gd")
const Driver=preload("res://tests/helpers/clock_panel_driver.gd")
var checks:=0
var failures:=0
var shell:Control
var panel:Control
var store:Node
var touch:=false
var target_id:="1225_bakery"
var capture_prefix:="desktop"
var capture_dir:=""
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func frames(count:int=5)->void:
	for i in count:await process_frame
func entry()->Dictionary:
	var s:Dictionary=store.initial()
	s.native.chapter=4;s.native.scene=Chapter.SCENE;s.native.page="c4_notes";s.native.mode="light";s.runtimeMode="rpg";s.rpgScene=Chapter.SCENE
	var index:int=preload("res://scripts/games/chapter4_clock_chain.gd").IDS.find(target_id)
	s.chapter4.prologueSeen=true;s.chapter4.phase=["hall_clock_inspection","room204_restore","maintenance_repair"][index];s.chapter4.timeState=["2245_opening","1225_bakery","1850_evening"][index];s.chapter4.factIds=[["external_time_rejected","hall_clock_inspected"],["hour_hand_installed"],["positioning_plate_installed"]][index];s.chapter4.floor="A1";s.chapter4.mode="light"
	Chapter.new()._time(s.chapter4,s.chapter4.timeState)
	s.native.settings.reduced_motion=target_id=="1850_evening"
	return s
func click(control:Control)->void:
	var ancestor:Node=control.get_parent()
	while ancestor!=null:
		if ancestor is ScrollContainer:ancestor.ensure_control_visible(control)
		ancestor=ancestor.get_parent()
	await frames()
	var area:Rect2=control.get_global_rect()
	check(control.is_visible_in_tree() and Rect2(Vector2.ZERO,Vector2(root.size)).encloses(area),"rendered control reachable %s %s stage=%d"%[control.get("text"),area,int(panel.checkpoint.step)])
	check(area.size.y>=28,"scaled hit area remains usable")
	if touch:
		var event=InputEventScreenTouch.new();event.index=0;event.position=area.get_center();event.pressed=true;root.push_input(event,true);await frames(1)
		event=InputEventScreenTouch.new();event.index=0;event.position=area.get_center();event.pressed=false;root.push_input(event,true)
	else:
		var motion=InputEventMouseMotion.new();motion.position=area.get_center();motion.global_position=motion.position;root.push_input(motion,true);await frames(2)
		var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=area.get_center();event.global_position=event.position;event.pressed=true;root.push_input(event,true);await frames(1)
		event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=area.get_center();event.global_position=event.position;event.pressed=false;root.push_input(event,true)
	await frames()
func drag_gear(axis:String,direction:int)->void:
	var view:Control=panel.face
	var ancestor:Node=view.get_parent()
	while ancestor!=null:
		if ancestor is ScrollContainer:ancestor.ensure_control_visible(view)
		ancestor=ancestor.get_parent()
	await frames()
	var origin:Vector2=view.get_global_transform_with_canvas()*view.gear_point(axis)
	var start:Vector2=origin+Vector2(0,-20)
	var finish:Vector2=origin+Vector2.from_angle(-PI/2+direction*PI/4)*20
	var before:int=int(panel.checkpoint[axis])
	if touch:
		var down=InputEventScreenTouch.new();down.index=2;down.position=start;down.pressed=true;root.push_input(down,true);await frames(1)
		var move=InputEventScreenDrag.new();move.index=2;move.position=finish;move.relative=finish-start;root.push_input(move,true);await frames(2)
		var up=InputEventScreenTouch.new();up.index=2;up.position=finish;up.pressed=false;root.push_input(up,true)
	else:
		var hover=InputEventMouseMotion.new();hover.position=start;hover.global_position=start;root.push_input(hover,true);await frames(1)
		var down=InputEventMouseButton.new();down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;down.position=start;down.global_position=start;root.push_input(down,true);await frames(1)
		var move=InputEventMouseMotion.new();move.button_mask=MOUSE_BUTTON_MASK_LEFT;move.position=finish;move.global_position=finish;move.relative=finish-start;root.push_input(move,true);await frames(2)
		var up=InputEventMouseButton.new();up.button_index=MOUSE_BUTTON_LEFT;up.position=finish;up.global_position=finish;up.pressed=false;root.push_input(up,true)
	await frames()
	check(panel.checkpoint[axis]==posmod(before+direction*(5 if axis=="minute" else 1),60 if axis=="minute" else 24),"actual gear drag drives controller "+axis)
	check(view.dragging_axis.is_empty(),"release clears object gesture")
func capture(stage:int)->void:
	if stage==4:
		await drag_gear("hour",1);await drag_gear("hour",-1)
		await drag_gear("minute",1);await drag_gear("minute",-1)
		check(not panel.controls.has("hour_plus") and not panel.controls.has("minute_minus") and panel.controls.hour_lock.get_parent()==panel.face,"mechanical actions live on their physical parts")
		if not touch:
			panel.face.grab_focus();panel.face.keyboard_axis="hour";await frames()
			for axis in ["hour","minute"]:
				var before:int=int(panel.checkpoint[axis])
				for code in [KEY_RIGHT,KEY_LEFT]:
					var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=true;root.push_input(e,true);await frames()
					check(panel.checkpoint[axis]==(posmod(before+(1 if axis=="hour" else 5),24 if axis=="hour" else 60) if code==KEY_RIGHT else before),"focused mechanism accepts keyboard rotation "+axis)
				var switch:=InputEventKey.new();switch.keycode=KEY_DOWN;switch.pressed=true;root.push_input(switch,true);await frames()
	check(panel.checkpoint.step==stage,"controller-backed UI stage "+str(stage))
	check(panel.phone.size==Vector2(430,860) and is_equal_approx(panel.phone.scale.x,panel.phone.scale.y),"canonical phone size and uniform scale")
	if capture_dir.is_empty() or DisplayServer.get_name()=="headless":return
	await frames(8);RenderingServer.force_draw()
	root.get_texture().get_image().save_png(capture_dir+"/"+capture_prefix+"-step-"+str(stage+1)+".png")
func run()->void:
	store=root.get_node("State");store.developer_mode=false
	var args:PackedStringArray=OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--capture-dir="):capture_dir=arg.trim_prefix("--capture-dir=");DirAccess.make_dir_recursive_absolute(capture_dir)
	var views:Array=[Vector2i(1180,812),Vector2i(390,844),Vector2i(430,860),Vector2i(1280,720)]
	if "--manual" in args or "--desktop-only" in args:views=[Vector2i(1180,812)]
	for view in views:
		root.size=view;touch=view.x<660
		target_id="1850_evening" if view.x==430 else "2245_maintenance" if view.x==1280 else "1225_bakery"
		capture_prefix="phone430" if view.x==430 else "wide720" if view.x==1280 else "mobile" if touch else "desktop"
		store.d=entry()
		var original_time:String=store.d.chapter4.timeState
		shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
		store.act("c4_clock");await frames();panel=shell.modal
		if DisplayServer.get_name()!="headless":
			if root.has_method("grab_focus"):root.call("grab_focus")
			await frames(30)
		check(is_instance_valid(panel),"ordinary world action opens connected clock and terminal")
		if not is_instance_valid(panel):break
		if "--manual" in args:
			if "--manual-stage=4" in args:
				for event in preload("res://tests/helpers/clock_chain_driver.gd").events(target_id):
					if int(panel.checkpoint.step)>=4:break
					store.act("c4_clock_event",{"session":panel.session,"event":event});await frames(2)
			root.title="7:55 · 北教校时推理链 · isolated QA";print("CLOCK_CHAIN_MANUAL_READY");return
		var first_token:Dictionary=panel.session.duplicate(true)
		await click(panel.controls.source_phone)
		check(panel.checkpoint.step==0 and store.d.chapter4.timeState==original_time,"frozen phone rejected without world changes")
		# Escape owns cancellation, preserves progress, and retires the old capability.
		var escape=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true;root.push_input(escape,true);await frames()
		check(not is_instance_valid(shell.modal),"keyboard closes clock")
		check(not store.act("c4_clock_event",{"session":first_token,"event":{"kind":"source","id":"hall"}}).get("accepted",false),"closed UI cannot submit late input")
		store.act("c4_clock");await frames();panel=shell.modal
		check(await Driver.play(panel,click,capture),"all seven stages reachable by "+("touch" if touch else "mouse"))
		check(store.d.chapter4.timeState==target_id,"verified crown returns to source story")
		check(not is_instance_valid(shell.modal) and shell.world_frame.visible,"successful clock returns to world")
		await shell.shutdown();shell.queue_free();await frames()
	print("CLOCK_CHAIN_PANEL ",checks," checks; ",failures," failures");quit(1 if failures else 0)
