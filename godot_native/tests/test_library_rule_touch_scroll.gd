extends "res://tests/test_library_rule_action.gd"
## Real raw-touch input on the retained phone reader, outside the Library world.
## Touch emulation is a test capability, not physical-device acceptance.
func touch(point:Vector2,down:bool)->void:
	var event:=InputEventScreenTouch.new();event.index=0;event.position=point;event.pressed=down
	Input.parse_input_event(event);Input.flush_buffered_events();await frames(2)
func swipe(start:Vector2,end:Vector2)->void:
	await touch(start,true)
	for i:int in range(1,11):
		var event:=InputEventScreenDrag.new();event.index=0;event.position=start.lerp(end,i/10.0);event.relative=(end-start)/10.0
		Input.parse_input_event(event);Input.flush_buffered_events();await frames(2)
	await touch(end,false);await create_timer(.35).timeout;await frames()
func run()->void:
	var old_mouse:bool=Input.emulate_mouse_from_touch
	var old_touch:bool=Input.emulate_touch_from_mouse
	Input.emulate_mouse_from_touch=true;Input.emulate_touch_from_mouse=true
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	before_shelf=earned_shelf()
	var controller=Chapter.new()
	controller.dispatch(before_shelf,"lib_shelf")
	controller.dispatch(before_shelf,"lib_exit")
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames();shell.set_process(false)
	state.action_completed.connect(func(id,_before,_after,result):events.append({"id":id,"result":result.duplicate(true)}))
	for dimensions:Vector2i in [Vector2i(390,844),Vector2i(360,640)]:
		case_name=str(dimensions);state.story_reset.emit();state.d=before_shelf.duplicate(true)
		state.d.native.page="library_rule";state.d.runtimeMode="phone"
		root.size=dimensions;shell.size=Vector2(dimensions);shell.mobile_world=false
		await refresh()
		var scroll:ScrollContainer=shell.page_body.find_child("LibraryRuleScroll",true,false)
		var action:Button=shell.page_body.find_child("LibraryRuleAction",true,false)
		check(scroll!=null and action!=null and shell.phone.is_visible_in_tree(),"unread acquired rule opens the actual phone reader outside the Library")
		if scroll==null or action==null:continue
		var area:=screen_rect(scroll)
		var inventory:Dictionary=state.d.items.duplicate(true)
		check(action.disabled and not state.d.ui.libraryFinalsPuzzle.archivedRuleRead,"initial cover does not acknowledge reading")
		await swipe(area.position+area.size*Vector2(.75,.8),area.position+area.size*Vector2(.75,.25))
		check(scroll.scroll_vertical>0,"raw finger swipe scrolls the printed book")
		# Bound retries distinguish input coverage from direct scrollbar assignment.
		for attempt:int in 5:
			if not action.disabled:break
			await swipe(area.position+area.size*Vector2(.75,.8),area.position+area.size*Vector2(.75,.25))
		check(not action.disabled,"ordinary swipes reach the end and enable closing")
		check(state.d.items==inventory and not state.d.ui.libraryFinalsPuzzle.archivedRuleRead,"scrolling alone does not grant evidence or change items")
		# Isolate close ordering even on the old broken scroll implementation.
		if action.disabled:scroll.scroll_vertical=100000;await frames()
		var count:int=events.size()
		var point:=screen_rect(action).get_center();await touch(point,true);await touch(point,false);await frames()
		check(state.d.native.page=="library_app","closing returns to the Library app before narration locks navigation")
		check(state.d.ui.libraryFinalsPuzzle.archivedRuleRead,"stationary touch submits the original reading action")
		check(events.slice(count).filter(func(row):return row.id=="lib_read_rule").size()==1,"close submits reading exactly once")
		check(state.d.items==inventory,"closing preserves evidence inventory")
	await shell.shutdown();shell.queue_free();await frames()
	Input.emulate_mouse_from_touch=old_mouse;Input.emulate_touch_from_mouse=old_touch
	print("LIBRARY_RULE_TOUCH_SCROLL: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
