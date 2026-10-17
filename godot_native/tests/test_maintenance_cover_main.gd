extends "res://tests/test_compact_world_inventory.gd"
## Source-browser maintenance checkpoint, imported through the ordinary importer.
## Real Main inventory events and real /tmp files; no earned campaign claim.
const Cover=preload("res://scripts/presentation/maintenance_cover_motion.gd")
func cover_fixture(dimensions:Vector2i)->void:
	if is_instance_valid(shell):await shell.shutdown();shell.queue_free();await frames()
	var source:Dictionary={}
	for entry in state.developer_checkpoints():
		if entry.id=="c4-755-maintenance-2245":source=entry.state.duplicate(true)
	check(not source.is_empty(),"Original maintenance checkpoint exists")
	var f:=FileAccess.open("user://cover-source-import.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"version":35,"state":source}));f.close()
	var imported:Dictionary=state.import_save("user://cover-source-import.json")
	check(imported.get("ok",false),"Original browser checkpoint enters the unchanged save importer")
	state.developer_mode=true;state.d.runtimeMode="rpg";state.d.native.page="c4_notes"
	var p:=Vector2(1082,720);state.d.native.player={"x":p.x,"y":p.y,"scene":"duan_yongping_temporal_maze"}
	root.size=dimensions;shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(5)
	shell.mobile_world=true;shell.compact_inventory_open=true;shell._refresh();await frames(6)
	shell.world.player=p;shell.world._sync_player();shell.world._update_camera();shell.world.queue_redraw();await frames()
	for i in range(180):
		if shell.world.transition_alpha<=0:break
		await process_frame
	check(shell.world.transition_alpha<=0,"Scene fade completes before input and art checks")
func wheel_screen(id:String)->Vector2:
	for y in [703,705,701,707,699]:
		for x in [1132,1130,1134,1128,1136]:
			var point:=Vector2(x,y)
			if shell.world.object_picker.pick(point,shell.world.targets,true).get("id","")==id:
				return world_screen((point-shell.world.camera)*shell.world.zoom+shell.world.size/2)
	return Vector2.INF
func diagnose()->void:
	state.act("c4_diagnose",{"wheel_sound":"latch","clock_jam":"gear_offset","oil_trace":"oil_shortage"});await frames()
func run()->void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):
		push_error("Refusing maintenance persistence fixture outside isolated /tmp profile");quit(2);return
	state=root.get_node("State")
	state.feedback.connect(func(t:String):print("COVER_FEEDBACK ",t))
	state.action_completed.connect(func(a:String,_b:Dictionary,_c:Dictionary,r:Dictionary):print("COVER_ACT ",a," ",r))
	var emulate:=Input.emulate_mouse_from_touch;Input.emulate_mouse_from_touch=false
	for dim in [Vector2i(1280,720),Vector2i(390,844)]:
		await cover_fixture(dim)
		state.act("c4_diagnose",{"wheel_sound":"wrong","clock_jam":"gear_offset","oil_trace":"oil_shortage"})
		check(not state.d.items.shortPryBar and not Cover.FACT in state.d.chapter4.factIds,"Wrong original diagnosis grants neither tool nor cover fact")
		await diagnose()
		check(state.d.items.shortPryBar,"Original correct diagnosis grants the source pry bar")
		var end:=wheel_screen("a1_cleaning_cart_wheel_cover")
		check(end.is_finite(),"Original rendered wheel-cover target is pickable")
		if not end.is_finite():continue
		var using_touch:bool=dim.x<1100
		await drag_item("campusCard",end,using_touch)
		check(not Cover.FACT in state.d.chapter4.factIds and state.d.items.campusCard,"Wrong item drop preserves card and closed cover")
		await drag_item("shortPryBar",end,using_touch,true)
		check(not Cover.FACT in state.d.chapter4.factIds and state.d.items.shortPryBar,"Cancelled native pry-bar drag keeps original state")
		state.developer_mode=false;check(state.save_game(),"Cancelled input saves normally")
		check(state.load_game(),"Cancelled input ordinary file reload succeeds");state.developer_mode=true;shell._refresh();await frames(4)
		check(not Cover.FACT in state.d.chapter4.factIds and state.d.items.shortPryBar,"Reload never persists an unfinished input or grants cover")
		end=wheel_screen("a1_cleaning_cart_wheel_cover");await drag_item("shortPryBar",end,using_touch)
		check(Cover.FACT in state.d.chapter4.factIds and not state.d.items.shortPryBar and state.d.items.universalLubricatingOil,"Actual native world drop consumes one pry bar and grants only original cover/oil result")
		state.developer_mode=false;check(state.save_game(),"Accepted cover saves through ordinary State")
		check(state.load_game(),"Accepted cover ordinary reload succeeds");state.developer_mode=true;shell._refresh();await frames(4)
		var pose:Dictionary=shell.world.chapter4_layers.phases.cover_motion.sample(state.d)
		check(pose.angle_degrees==-42 and not pose.moving,"Ordinary owner replacement restores open terminal hinge without replay")
		check(not state.d.items.shortPryBar and state.d.items.universalLubricatingOil,"Cover reload cannot restore consumed pry bar or consume oil")
		end=wheel_screen("a1_cleaning_cart_wheel");check(end.is_finite(),"Original exposed wheel remains pickable")
		if end.is_finite():await drag_item("universalLubricatingOil",end,using_touch)
		check("cart_wheel_repaired" in state.d.chapter4.factIds and "clock_gear_repaired" in state.d.chapter4.factIds and not state.d.items.universalLubricatingOil,"Actual native oil drop retains both source repair facts and single consumption")
		state.developer_mode=false;check(state.save_game(),"Repaired cart saves normally");check(state.load_game(),"Repaired cart ordinary reload succeeds")
		state.developer_mode=true;shell._refresh();await frames(4)
		check(not shell.world.chapter4_layers.phases.cover_motion.sample(state.d).visible,"Repaired reload hides cover overlay without replay")
		check(shell.world.chapter4_layers.phases.maintenance_sample(state.d).cart==Vector2(1049,716),"Repaired reload preserves existing source final cart position")
	Input.emulate_mouse_from_touch=emulate
	if is_instance_valid(shell):await shell.shutdown();shell.queue_free();await frames()
	print("MAINTENANCE_COVER_MAIN: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
