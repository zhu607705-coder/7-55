extends SceneTree
var shell:Control
var state:Node
var checks:=0
var failures:=0
var inspections:=0
var clock_events:Array=[]
func _initialize() -> void:run.call_deferred()
func frames(n:=3) -> void:
	for i in n:await process_frame
func check(ok:bool,why:String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(why)
func item(id:String) -> Control:return shell.find_child("Item_"+id,true,false)
func mouse(p:Vector2,pressed:bool,double_click:=false) -> void:
	var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=p;e.global_position=p;e.pressed=pressed;e.double_click=double_click
	clock_events.append({"type":"mouse","pressed":pressed,"double_click":double_click,"ms":Time.get_ticks_msec()})
	Input.parse_input_event(e);await process_frame
func click_slot(id:String,double_click:=false) -> void:
	var p:=item(id).get_global_rect().get_center()
	await mouse(p,true,double_click);await mouse(p,false);await frames()
func move(p:Vector2,delta:Vector2) -> void:
	var e:=InputEventMouseMotion.new();e.position=p;e.global_position=p;e.relative=delta;e.button_mask=MOUSE_BUTTON_MASK_LEFT;Input.parse_input_event(e);await process_frame
func drag(source:Vector2,target:Vector2,double_click:=false) -> void:
	await mouse(source,true,double_click)
	for i in range(1,10):await move(source.lerp(target,i/9.0),(target-source)/9.0)
	await mouse(target,false);await frames(5)
func close() -> void:
	shell._close_modal();await frames();shell.phone_chrome.inventory_gestures.reset()
func run() -> void:
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	shell.phone_chrome.inspect_requested.connect(func(_entry):inspections+=1;clock_events.append({"type":"inspect","ms":Time.get_ticks_msec()}))
	for dimensions in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		root.size=dimensions;shell.size=Vector2(dimensions)
		state.d=state.initial();state.d.chapter=2;state.d.flags.checkinDone=true;state.d.actOne.inventoryRecovered=true;state.d.actOne.phase="movement_required"
		state.d.native.page="wechat";state.d.currentScene="wechat";state.d.native.scene="dorm_hub";state.d.runtimeMode="rpg";state.d.ui.inventoryOpen=true
		for id in ["campusCard","pushTriangle","mentorLine"]:state.d.items[id]=true
		shell._refresh();shell.phone_chrome.set_inventory_top(240);await frames(6)
		var handle:Control=shell.phone_chrome.inventory_handle;var hp:=handle.get_global_rect().get_center();var old_top:float=shell.phone_chrome.inventory_top
		await drag(hp,hp-Vector2(0,95))
		check(shell.phone_chrome.inventory_open and shell.phone_chrome.inventory_top<old_top,"Actual handle drag moves drawer upward without closing")
		await drag(item("pushTriangle").get_global_rect().get_center(),item("mentorLine").get_global_rect().get_center())
		check(state.d.items.rightArrow and not state.d.items.pushTriangle and not state.d.items.mentorLine,"Actual inventory combination creates rightArrow")
		check(not is_instance_valid(shell.modal),"Combination does not inspect")
		await click_slot("rightArrow");check(state.d.native.selected_item=="rightArrow" and not is_instance_valid(shell.modal),"New arrow single click selects only")
		await click_slot("rightArrow",true);check(is_instance_valid(shell.modal) and shell.inspected_item_id=="rightArrow","Fast native double click inspects newly assembled arrow")
		await close()
		await click_slot("rightArrow");await create_timer(.44).timeout;await click_slot("rightArrow")
		check(not is_instance_valid(shell.modal),"Two slow ordinary clicks remain selection only")
		shell.phone_chrome.inventory_gestures.reset()
		await click_slot("rightArrow");await create_timer(.44).timeout;await click_slot("rightArrow",true)
		check(is_instance_valid(shell.modal) and shell.inspected_item_id=="rightArrow","Native double-click flag survives delayed main-thread delivery")
		check(state.d.native.selected_item=="rightArrow" and state.d.items.rightArrow,"Inspection retains selection and ownership")
		await close()
		var count:=inspections
		await click_slot("rightArrow");var p:=item("rightArrow").get_global_rect().get_center()
		await drag(p,p+Vector2(170,100),true)
		check(not is_instance_valid(shell.modal) and inspections==count,"Native flagged press that becomes drag does not inspect")
		check(state.d.items.rightArrow,"Invalid drop retains assembled arrow")
		await close()
		await click_slot("campusCard");await click_slot("rightArrow",true)
		check(not is_instance_valid(shell.modal),"Native flag does not merge clicks on different items")
		await close()
		var slot:=item("rightArrow");var rect:=slot.get_global_rect();var left:=rect.position+Vector2(3,rect.size.y/2);var right:=rect.position+Vector2(rect.size.x-3,rect.size.y/2)
		await mouse(left,true);await mouse(left,false);await frames()
		await mouse(right,true,true);await mouse(right,false);await frames()
		check(not is_instance_valid(shell.modal),"Native flag retains same-position tolerance")
		await close();await click_slot("rightArrow")
		shell.phone_chrome.inventory.hide();await frames();shell.phone_chrome.inventory.show();await frames()
		await click_slot("rightArrow",true);check(not is_instance_valid(shell.modal),"Hide invalidates pending click history")
		await close();await click_slot("rightArrow")
		state.d.items.rightArrow=false;state.d.items.gamepad=true;shell._refresh();await frames(6)
		await click_slot("gamepad",true);check(not is_instance_valid(shell.modal),"Different rebuilt slot cannot inherit old item's click")
		state.d.items.gamepad=false;state.d.items.rightArrow=true;shell._refresh();await frames(6);shell.phone_chrome.inventory_gestures.reset()
		var touch_point:=item("rightArrow").get_global_rect().get_center()
		for index in 2:
			for pressed in [true,false]:
				var touch:=InputEventScreenTouch.new();touch.index=0;touch.position=touch_point;touch.pressed=pressed;touch.double_tap=index==1;Input.parse_input_event(touch);await process_frame
			await frames()
			if index==0:await create_timer(.44).timeout
		check(not is_instance_valid(shell.modal),"Touch retains380ms arbitration even when mouse native recognition is extended")

	await shell.shutdown();shell.queue_free();await frames()
	print("NATIVE_DOUBLE_CLICK_CLOCKS ",JSON.stringify(clock_events))
	print("INVENTORY_NATIVE_DOUBLE_CLICK: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
