extends SceneTree
const Item=preload("res://scripts/ui/inventory_item.gd")
var checks:=0
var failures:=0
var selected: Array=[]
var inspected: Array=[]
var host:Control
var a:Button
var b:Button
func _initialize() -> void:run.call_deferred()
func check(ok:bool,why:String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(why)
func frames(n:=3) -> void:
	for i in n:await process_frame
func touch(point:Vector2,index:int,down:bool,canceled:=false) -> void:
	var e:=InputEventScreenTouch.new();e.index=index;e.position=point;e.pressed=down;e.canceled=canceled;Input.parse_input_event(e)
func drag(point:Vector2,index:int,delta:Vector2) -> void:
	var e:=InputEventScreenDrag.new();e.index=index;e.position=point;e.relative=delta;Input.parse_input_event(e)
func make_slots() -> void:
	host=Control.new();host.position=Vector2(25,40);root.add_child(host)
	for id in ["a","b"]:
		var item:=Item.new();item.item_id=id;item.text=id;item.size=Vector2(52,52);item.position=Vector2(0 if id=="a" else 75,0);host.add_child(item)
		item.selection_requested.connect(func(item_id):selected.append(item_id));item.inspection_requested.connect(func(item_id):inspected.append(item_id))
		if id=="a":a=item
		else:b=item
	await frames()
func cleanup() -> void:
	host.queue_free();await frames();selected.clear();inspected.clear()
func run() -> void:
	root.get_node("State").developer_mode=true;root.size=Vector2i(390,844)
	var original:=Input.emulate_mouse_from_touch
	for baseline in [true,false]:
		for secondary_first in [true,false]:
			Input.emulate_mouse_from_touch=baseline;await make_slots()
			var ap:=a.get_global_rect().get_center();var bp:=b.get_global_rect().get_center()
			touch(ap,0,true);await process_frame;touch(bp,1,true);await process_frame
			check(a._touch_index==0 and b._touch_index==-1,"Only first slot owns simultaneous two-index touch")
			check(not Input.emulate_mouse_from_touch,"Emulation disabled under first owner")
			if secondary_first:
				touch(bp,1,false,true);await frames()
				check(not Input.emulate_mouse_from_touch and a._touch_index==0,"Canceled secondary release cannot restore or cancel primary")
				touch(ap,0,false,true);await frames()
			else:
				touch(ap,0,false,true);await frames()
				check(Input.emulate_mouse_from_touch==baseline,"Primary release restores original setting with secondary still down")
				touch(bp,1,false,true);await frames()
			check(Input.emulate_mouse_from_touch==baseline,"Either release order restores exact original setting")
			check(selected.is_empty() and inspected.is_empty() and not root.gui_is_dragging(),"Canceled two-pointer gesture emits no activation")
			await cleanup()
		# Release and reacquire in the same event turn: stale deferred restoration
		# must not re-enable emulation while the replacement owner is active.
		Input.emulate_mouse_from_touch=baseline;await make_slots()
		var ap:=a.get_global_rect().get_center();var bp:=b.get_global_rect().get_center()
		touch(ap,0,true);await process_frame
		touch(ap,0,false,true);touch(bp,1,true);await frames()
		check(b._touch_index==1 and not Input.emulate_mouse_from_touch,"Same-turn handoff keeps emulation disabled")
		drag(bp+Vector2(50,20),1,Vector2(50,20));await frames();check(root.gui_is_dragging(),"Replacement owner can start native drag")
		touch(ap,0,false,true);await frames();check(root.gui_is_dragging(),"Late old-index release cannot cancel current drag")
		touch(bp+Vector2(50,20),1,false,true);await frames()
		check(Input.emulate_mouse_from_touch==baseline and not root.gui_is_dragging(),"Replacement cancel restores original setting and clears drag")
		await cleanup()
		for replacement in ["hide","free"]:
			Input.emulate_mouse_from_touch=baseline;await make_slots()
			ap=a.get_global_rect().get_center();bp=b.get_global_rect().get_center()
			touch(ap,0,true);await process_frame;drag(ap+Vector2(35,45),0,Vector2(35,45));await frames()
			check(root.gui_is_dragging(),"Original native drag exists before replacement "+replacement)
			if replacement=="hide":a.hide()
			else:a.free()
			touch(bp,1,true);drag(bp+Vector2(45,35),1,Vector2(45,35));await frames()
			check(b._touch_index==1 and root.gui_is_dragging() and root.gui_get_drag_data().item=="b","Old deferred teardown cannot cancel replacement drag")
			check(not Input.emulate_mouse_from_touch,"Old deferred restore cannot affect replacement owner")
			touch(bp+Vector2(45,35),1,false,true);touch(ap+Vector2(35,45),0,false,true);await frames()
			check(Input.emulate_mouse_from_touch==baseline and not root.gui_is_dragging(),"Replacement teardown returns exact original setting")
			await cleanup()
		for teardown in ["hide","free","focus"]:
			Input.emulate_mouse_from_touch=baseline;await make_slots()
			ap=a.get_global_rect().get_center();bp=b.get_global_rect().get_center()
			touch(ap,0,true);await process_frame;touch(bp,1,true);await process_frame
			drag(ap+Vector2(40,60),0,Vector2(40,60));await frames();check(root.gui_is_dragging(),"Owner drag starts before "+teardown)
			if teardown=="hide":a.hide()
			elif teardown=="free":a.queue_free()
			else:a.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
			await frames();check(Input.emulate_mouse_from_touch==baseline and not root.gui_is_dragging(),"Teardown restores exact setting and cancels drag: "+teardown)
			touch(ap+Vector2(40,60),0,false,true);touch(bp,1,false,true);await frames()
			check(Input.emulate_mouse_from_touch==baseline and selected.is_empty(),"Late releases after teardown stay harmless")
			await cleanup()
	Input.emulate_mouse_from_touch=original
	print("INVENTORY_TOUCH_OWNERSHIP: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
