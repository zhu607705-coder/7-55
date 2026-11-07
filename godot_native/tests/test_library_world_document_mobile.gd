extends "res://tests/test_library_rule_touch_scroll.gd"
## Synthetic native touch, not physical-device or browser release acceptance.
func run()->void:
	var old_mouse:bool=Input.emulate_mouse_from_touch
	var old_touch:bool=Input.emulate_touch_from_mouse
	Input.emulate_mouse_from_touch=true;Input.emulate_touch_from_mouse=true
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	before_shelf=earned_shelf()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames();shell.set_process(false)
	state.action_completed.connect(func(id,_before,_after,result):events.append({"id":id,"result":result.duplicate(true)}))
	for dimensions:Vector2i in [Vector2i(360,640),Vector2i(390,844),Vector2i(844,390),Vector2i(1440,900)]:
		case_name=str(dimensions);root.size=dimensions;shell.size=Vector2(dimensions);await frames();await fixture()
		var reader:Control=shell.modal
		var scroll:ScrollContainer=reader.scroll
		var action:Button=reader.close
		var items:Dictionary=state.d.items.duplicate(true)
		check(action.disabled and not reader.end_seen,"cover cannot acknowledge the rule")
		check(reader.body.text==RULE_BODY,"complete authored rule wording is unchanged")
		check(reader.body.get_line_count()==reader.body.get_visible_line_count(),"reflow contains every body line")
		var scale_y:float=reader.body.get_global_transform_with_canvas().get_scale().y
		check(reader.body.get_theme_font_size("font_size")*scale_y>=18,"physical body type is at least 18px")
		check(screen_rect(action).size.y>=44,"physical close target is at least 44px")
		check(screen_rect(reader).encloses(screen_rect(scroll)),"paper scroll stays inside the available viewport")
		if dimensions.x==1440:
			check(scroll.position==Vector2(376,32) and scroll.size==Vector2(536,476),"desktop spread geometry remains unchanged")
		# Resize before any gesture: layout changes cannot unlock the read gate.
		reader.layout_panel(Vector2(1440,900) if dimensions.x<1000 else Vector2(360,640));await frames(6)
		reader.layout_panel(Vector2(dimensions));await frames(6)
		check(not reader.end_seen and action.disabled,"resize does not acknowledge an unread document")
		# Partial scrollbar setup isolates resize behavior from the touch path below.
		scroll.scroll_vertical=10;await frames()
		reader.layout_panel(Vector2(dimensions)-Vector2(0,20));await frames(6)
		check(scroll.scroll_vertical>0 and not reader.end_seen,"height change preserves partial progress without unlocking")
		reader.layout_panel(Vector2(dimensions));await frames(6)
		var area:=screen_rect(scroll)
		for attempt:int in 15:
			if not action.disabled:break
			await swipe(area.position+area.size*Vector2(.75,.85),area.position+area.size*Vector2(.75,.15))
		check(scroll.scroll_vertical>0 and reader.end_seen and not action.disabled,"ordinary touch swipes reach the end and enable closing")
		check(state.d.items==items and not state.d.ui.libraryFinalsPuzzle.archivedRuleRead,"scrolling alone does not grant evidence")
		check(area.grow(1).encloses(screen_rect(action)),"enabled close target is fully visible at scroll end")
		# Dragging out of the close button cancels activation, then a tap closes.
		var point:=screen_rect(action).get_center()
		await touch(point,true)
		var drag:=InputEventScreenDrag.new();drag.index=0;drag.position=Vector2(2,2);drag.relative=Vector2(2,2)-point
		Input.parse_input_event(drag);Input.flush_buffered_events();await frames(2)
		await touch(Vector2(2,2),false)
		check(is_instance_valid(shell.modal) and not state.d.ui.libraryFinalsPuzzle.archivedRuleRead,"drag-out cancels closing")
		# The cancel gesture can scroll; restore the end through actual swipes.
		for attempt:int in 15:
			if area.grow(1).encloses(screen_rect(action)):break
			await swipe(area.position+area.size*Vector2(.75,.85),area.position+area.size*Vector2(.75,.15))
		var count:int=events.size()
		point=screen_rect(action).get_center();await touch(point,true);await touch(point,false);await frames()
		check(state.d.native.page=="library_app" and state.d.ui.libraryFinalsPuzzle.archivedRuleRead,"tap closes and submits existing read intent")
		check(events.slice(count).filter(func(row):return row.id=="lib_read_rule").size()==1,"reading commits exactly once")
		check(state.d.items==items,"closing preserves source inventory")
		# The record uses this same component, with its original explicit-confirm gate.
		state.story_reset.emit();state.d=before_shelf.duplicate(true)
		state.d.ui.libraryFinalsPuzzle.entranceRecordRead=false
		state.d.ui.libraryFinalsPhase="library_entered"
		state.d.native.page="library_record";shell.world_page_origin_scene="library_interior";shell.mobile_world=true
		await refresh();reader=shell.modal
		check(is_instance_valid(reader) and reader.page=="library_record","related record uses the same responsive volume")
		if not is_instance_valid(reader):continue
		scroll=reader.scroll;action=reader.close;area=screen_rect(scroll)
		items=state.d.items.duplicate(true)
		check(not action.disabled and screen_rect(action).size.y>=44,"record retains confirmation and a 44px close target")
		check(reader.body.get_line_count()==reader.body.get_visible_line_count(),"record text reflows without clipping")
		for attempt:int in 15:
			if area.grow(1).encloses(screen_rect(action)):break
			await swipe(area.position+area.size*Vector2(.75,.85),area.position+area.size*Vector2(.75,.15))
		check(not state.d.ui.libraryFinalsPuzzle.entranceRecordRead and state.d.items==items,"viewing the record does not confirm it")
		count=events.size();point=screen_rect(action).get_center();await touch(point,true);await touch(point,false);await frames()
		check(state.d.ui.libraryFinalsPuzzle.entranceRecordRead,"record tap submits its existing action")
		check(events.slice(count).filter(func(row):return row.id=="lib_record").size()==1,"record confirmation commits exactly once")
	await shell.shutdown();shell.queue_free();await frames()
	Input.emulate_mouse_from_touch=old_mouse;Input.emulate_touch_from_mouse=old_touch
	print("LIBRARY_WORLD_DOCUMENT_MOBILE: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
