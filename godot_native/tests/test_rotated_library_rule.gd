extends "res://tests/test_library_rule_action.gd"
## Controller-earned native fixture and real root touch events. This does not
## replace browser IndexedDB reload or physical-device acceptance.
func screen_rect(control: Control) -> Rect2:
	return root.get_final_transform() * control.get_global_transform_with_canvas() * Rect2(Vector2.ZERO,control.size)
func finger(point:Vector2,down:bool)->void:
	var event:=InputEventScreenTouch.new()
	event.index=0;event.position=point;event.pressed=down
	root.push_input(event,false)
	await frames(2)
func manage_mobile()->void:
	shell.mobile_surface_managed=true
	shell.set_anchors_preset(Control.PRESET_TOP_LEFT)
	shell._layout()
func run()->void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	before_shelf=earned_shelf()
	state.action_completed.connect(func(id,_before,_after,result):events.append({"id":id,"result":result.duplicate(true)}))
	for density:float in [1.0,3.0]:
		case_name="portrait DPR "+str(density)
		root.content_scale_factor=density;root.size=Vector2i(Vector2(390,844)*density)
		shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
		manage_mobile();shell.set_process(false)
		await fixture()
		var reader:Control=shell.modal
		var scroll:ScrollContainer=reader.find_child("LibraryWorldDocumentScroll",true,false)
		var action:Button=reader.find_child("LibraryWorldDocumentClose",true,false)
		var inventory:Dictionary=state.d.items.duplicate(true)
		check(shell.mobile_surface_rotation==1,"rule uses real portrait-held landscape rotation")
		check(action.disabled and not state.d.ui.libraryFinalsPuzzle.archivedRuleRead,"unread rule is gated")
		check(Rect2(Vector2.ZERO,Vector2(root.size)).grow(1).encloses(screen_rect(shell.world_view)),"actual Library remains onscreen behind reader")
		# Headless DisplayServer cannot advertise touch scrolling. Scope this
		# regression to rotated close input and persistence, not swipe acceptance.
		scroll.scroll_vertical=100000;await frames()
		check(not action.disabled and reader.end_seen,"actual scroll end enables the close gate")
		check(not state.d.ui.libraryFinalsPuzzle.archivedRuleRead and state.d.items==inventory,"scrolling preserves unread evidence and inventory")
		var count:int=events.size()
		var point:=screen_rect(action).get_center()
		await finger(point,true);await finger(point,false);await frames()
		check(state.d.ui.libraryFinalsPuzzle.archivedRuleRead,"rotated close touch submits the original read action")
		check(events.slice(count).filter(func(row):return row.id=="lib_read_rule").size()==1,"close commits reading exactly once")
		check(not is_instance_valid(shell.modal) and shell.world_frame.visible,"close removes reader and retains world")
		check(state.d.items==inventory,"closing preserves inventory")
		state.developer_mode=false
		check(state.save_game(),"ordinary native save writes the read result")
		var scene:String=state.d.native.scene
		await shell.shutdown();shell.queue_free();await frames()
		state.d=state.initial();check(state.load_game(),"fresh host reload reads the primary save")
		shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
		manage_mobile();await frames()
		check(state.d.ui.libraryFinalsPuzzle.archivedRuleRead and state.d.items==inventory and state.d.native.scene==scene,"reload retains read result, scene and all items")
		check(Rect2(Vector2.ZERO,Vector2(root.size)).grow(1).encloses(screen_rect(shell.world_view)),"reloaded portrait world stays onscreen")
		await shell.shutdown();shell.queue_free();await frames()
		state.developer_mode=true
	print("ROTATED_LIBRARY_RULE: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
