extends "res://tests/test_library_reveal_handoff.gd"
## Reuse the source-earned shelf fixture and real root-viewport input helpers.

func finger(point:Vector2,pressed:bool,canceled:=false)->void:
	var input:=InputEventScreenTouch.new()
	input.index=2;input.position=point;input.pressed=pressed;input.canceled=canceled
	event(input)

func begin_pull(touch:bool)->Vector2:
	var book:Rect2=shell.world.library_layers.book.geometry(shell.world.library_layers.objects).rect
	var point:=world_screen(book.get_center())
	if touch:finger(point,true)
	else:motion(point);mouse(point,true)
	await frames()
	return book.get_center()

func move_pull(at:Vector2,touch:bool)->void:
	var point:=world_screen(at)
	if touch:
		var input:=InputEventScreenDrag.new();input.index=2;input.position=point;event(input)
	else:motion(point,Vector2(0,20),MOUSE_BUTTON_MASK_LEFT)
	await frames()

func end_pull(at:Vector2,touch:bool,canceled:=false)->void:
	if touch:finger(world_screen(at),false,canceled)
	else:mouse(world_screen(at),false)
	await frames()

func rejected_pull(dimensions:Vector2i,kind:String)->void:
	case_name=str(dimensions)+"/"+kind
	await fixture(dimensions)
	var touch:bool=kind=="touch cancel"
	var start:=await begin_pull(touch)
	check(shell.world.library_layers.book.pulling,"earned book captures its own physical pointer")
	var items:Dictionary=state.d.items.duplicate(true)
	var end:=start+Vector2(0,26)
	if kind=="short":end=start+Vector2(0,8)
	elif kind=="sideways":end=start+Vector2(45,26)
	await move_pull(end,touch)
	check(state.d.items==items and not state.d.ui.libraryFinalsPuzzle.archivedRuleCollected,"dragging alone cannot grant evidence")
	if kind=="hidden":shell.world.hide();await frames();shell.world.show()
	elif kind=="focus":shell.world._notification(Control.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	elif kind=="mode":state.toggle_mode()
	elif kind=="state":state.d=state.d.duplicate(true);shell.world.refresh_world()
	await end_pull(end,touch,kind=="touch cancel")
	check(not shell.world.library_layers.book.pulling and shell.world.library_layers.book.offset==0,"incomplete or canceled book returns to its slot")
	check(state.d.items==items and action_count("lib_shelf")==0,"canceled physical action preserves the earned clue")

func successful_pull(dimensions:Vector2i,touch:bool)->void:
	case_name=str(dimensions)+("/touch" if touch else "/mouse")
	await fixture(dimensions)
	var start:=await begin_pull(touch)
	check(shell.world.library_layers.book.pulling,"physical book press is acquired")
	await move_pull(start+Vector2(0,26),touch)
	check(shell.world.library_layers.book.offset>=18 and state.d.items.callNumber755,"visible book follows the pointer before release")
	await end_pull(start+Vector2(0,26),touch)
	check(action_count("lib_shelf")==1 and state.d.items.archivedLeaveRule and not state.d.items.callNumber755,"completed extraction invokes the original controller once")
	advance(3000);await frames()
	check(state.d.native.page=="library_rule" and grant_count()==1,"extraction retains the existing shelf, paper and reader handoff")

func run()->void:
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated native save")
	if failures:quit(1);return
	before_shelf=earned_shelf()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	shell.set_process(false);shell.world.set_process(false)
	state.action_completed.connect(record_action);shell.child_entered_tree.connect(record_reader)
	var original_emulation:=Input.emulate_mouse_from_touch
	Input.emulate_mouse_from_touch=false
	for dimensions:Vector2i in [Vector2i(1280,720),Vector2i(844,390)]:
		for kind:String in ["short","sideways","touch cancel","hidden","focus","mode","state"]:await rejected_pull(dimensions,kind)
		await successful_pull(dimensions,false)
		await successful_pull(dimensions,true)
		case_name=str(dimensions)+"/far selected clue"
		await fixture(dimensions)
		state.select_item("callNumber755")
		shell.world.player=Vector2(625,355);shell.world._sync_player();shell.world._update_camera();shell.world.queue_redraw();await frames()
		var start:=await begin_pull(false)
		check(not shell.world.library_layers.book.pulling and shell.world._floor_pending_interaction.is_empty(),"far press approaches the book without queuing extraction")
		await end_pull(start,false)
		advance(3200)
		check(action_count("lib_shelf")==0 and state.d.items.callNumber755 and not state.d.ui.libraryFinalsPuzzle.archivedRuleCollected,"arriving with a selected clue still requires the physical pull")
	Input.emulate_mouse_from_touch=original_emulation
	print("LIBRARY_BOOK_PULL ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
