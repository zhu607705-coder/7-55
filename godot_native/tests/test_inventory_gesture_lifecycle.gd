extends SceneTree
const Item=preload("res://scripts/ui/inventory_item.gd")
const Gesture=preload("res://scripts/ui/inventory_gesture.gd")
var checks:=0
var failures:=0
var selected:=0
var inspected:=0
var scroll:ScrollContainer
var host:Control
var slot:Button
func _initialize() -> void:run.call_deferred()
func check(ok:bool,why:String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(why)
func frames(n:=3) -> void:
	for i in n:await process_frame
func touch(point:Vector2,down:bool,canceled:=false) -> void:
	var e:=InputEventScreenTouch.new();e.index=0;e.position=point;e.pressed=down;e.canceled=canceled;Input.parse_input_event(e);await process_frame
func move_touch(point:Vector2,delta:Vector2) -> void:
	var e:=InputEventScreenDrag.new();e.index=0;e.position=point;e.relative=delta;Input.parse_input_event(e);await process_frame
func run() -> void:
	root.get_node("State").developer_mode=true
	var gesture:=Gesture.new()
	check(not gesture.tap("a",Vector2.ZERO,100),"First tap selects")
	check(gesture.tap("a",Vector2(1,2),250),"Second nearby tap inspects")
	check(not gesture.tap("a",Vector2.ZERO,300),"Third tap starts fresh")
	check(not gesture.tap("a",Vector2(90,90),320),"Spatially distant tap cannot count as double")
	gesture.reset();check(not gesture.tap("a",Vector2.ZERO,400),"Reset invalidates prior tap")
	check(not gesture.tap("b",Vector2.ZERO,410),"Different item cannot double")
	gesture.reset()
	check(not gesture.tap("a",Vector2.ZERO,1000),"Touch boundary fixture starts with selection")
	check(gesture.tap("a",Vector2.ZERO,1380),"Exactly380ms remains a valid touch double tap")
	gesture.reset()
	check(not gesture.tap("a",Vector2.ZERO,1000),"Expired touch fixture starts with selection")
	check(not gesture.tap("a",Vector2.ZERO,1381),"381ms remains two separate touch taps")
	for dimensions in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		root.size=dimensions;host=Control.new();host.position=Vector2(30,100);host.scale=Vector2.ONE*.82;root.add_child(host)
		scroll=ScrollContainer.new();scroll.size=Vector2(80,180);host.add_child(scroll)
		var list:=VBoxContainer.new();list.add_theme_constant_override("separation",8);scroll.add_child(list)
		for i in 10:
			var item:=Item.new();item.item_id="item_"+str(i);item.text=str(i);item.custom_minimum_size=Vector2(52,52);list.add_child(item)
			item.selection_requested.connect(func(_id):selected+=1);item.inspection_requested.connect(func(_id):inspected+=1)
		slot=list.get_child(1);await frames()
		check(slot.get_global_rect().size.x>=28,"390-scaled item remains above repository minimum hit size")
		var start:=slot.get_global_rect().get_center();var before:=selected
		await touch(start,true);await move_touch(start-Vector2(0,45),Vector2(0,-45));await touch(start-Vector2(0,45),false);await frames()
		check(scroll.scroll_vertical>0 and not root.gui_is_dragging(),"Fast vertical touch scrolls inventory instead of dragging")
		check(selected==before and inspected==0,"Scroll never selects or inspects")
		scroll.scroll_vertical=0;await frames();start=slot.get_global_rect().get_center()
		await touch(start,true);await create_timer(.23).timeout;await move_touch(start+Vector2(0,25),Vector2(0,25))
		check(root.gui_is_dragging(),"Held touch can drag vertically after arbitration")
		slot.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT);await frames()
		check(not root.gui_is_dragging() and Input.emulate_mouse_from_touch,"Focus loss cancels and restores touch emulation")
		await touch(start+Vector2(0,25),false,true);await frames()
		await touch(start,true);await move_touch(start+Vector2(45,0),Vector2(45,0));check(root.gui_is_dragging(),"Repeated horizontal drag works after cancel")
		host.hide();await frames();check(not root.gui_is_dragging() and Input.emulate_mouse_from_touch,"Hidden inventory clears drag and touch capture")
		await touch(start+Vector2(45,0),false,true);host.show();await frames();await create_timer(.3).timeout
		slot.grab_focus()
		var key:=InputEventKey.new();key.keycode=KEY_ENTER;key.pressed=true;Input.parse_input_event(key);await frames()
		check(inspected==1,"Enter opens details once")
		key.pressed=false;Input.parse_input_event(key);await frames();check(inspected==1,"Key release does not inspect twice")
		inspected=0;host.queue_free();await frames()
	print("INVENTORY_GESTURE_LIFECYCLE: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
