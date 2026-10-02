extends SceneTree
## Actual Main pointer/drop regression. Fixtures are isolated; not manual evidence.
var shell: Control
var state: Node
var checks:=0
var failures:=0
var actions: Array=[]
func _initialize() -> void: run.call_deferred()
func frames(count:=4) -> void:
	for i in range(count): await process_frame
func check(ok: bool, why: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(why)
func named(id: String) -> Control: return shell.find_child(id,true,false)
func click(control: Control) -> void:
	check(control!=null,"Visible pointer target exists")
	if not control:return
	var point=control.get_global_rect().get_center()
	var motion=InputEventMouseMotion.new();motion.position=point;root.push_input(motion,true)
	for pressed in [true,false]:
		var event=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;root.push_input(event,true);await process_frame
	await frames()
func drag(item: String) -> void:
	if not shell.phone_chrome.inventory_open:await click(named("InventoryHandle"))
	var source=named("Item_"+item)
	var target=named("BonsaiPlant")
	check(source!=null and target!=null,"Source and full plant drop target exist")
	if not source or not target:return
	var start=source.get_global_rect().get_center();var end=target.get_global_rect().get_center()
	var down=InputEventMouseButton.new();down.button_index=MOUSE_BUTTON_LEFT;down.position=start;down.global_position=start;down.pressed=true;root.push_input(down,true);await process_frame
	var last=start
	for i in range(1,13):
		var point=start.lerp(end,i/12.0);var motion=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;motion.relative=point-last;motion.button_mask=MOUSE_BUTTON_MASK_LEFT;root.push_input(motion,true);last=point;await process_frame
	var payload=root.gui_get_drag_data();check(payload is Dictionary and payload.get("item")==item,"Real inventory drag started")
	var up=InputEventMouseButton.new();up.button_index=MOUSE_BUTTON_LEFT;up.position=end;up.global_position=end;root.push_input(up,true);await frames()
func run() -> void:
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	state.action_completed.connect(func(id,_before,_after,_result):actions.append(id))
	for dimensions in [Vector2i(390,844),Vector2i(430,860),Vector2i(1280,720)]:
		root.size=dimensions;shell.size=Vector2(dimensions)
		state.d=state.initial();state.d.native.page="bonsai";state.d.flags.codeScattered=true
		state.d.items.wateredHeadphone=true;state.d.items.fertilizer=true;state.d.items.reverseGear=true
		state.d.ui.brightness=35;shell._refresh();await frames()
		check(not state.d.flags.plantLit,"Low brightness does not grant light")
		check(named("BonsaiStatus").text=="它绝对不会开花","Exact source initial caption")
		check(shell.page_body.get_child_count()==1,"Source page has no hidden fallback action buttons")
		await drag("reverseGear")
		check(state.d.items.reverseGear and not state.d.flags.plantWatered,"Wrong item retained without growth")
		await drag("wateredHeadphone")
		check(state.d.flags.plantWatered and not state.d.items.wateredHeadphone,"Real water drop consumes only correct item")
		check(not state.d.flags.flowerBloomed and named("BonsaiStatus").text=="好像有点想开花","Partial source stage caption; no premature bloom")
		await drag("fertilizer")
		check(state.d.flags.plantFertilized and not state.d.items.fertilizer,"Real fertilizer drop consumed correctly")
		check(not state.d.flags.flowerBloomed,"Two conditions do not bloom")
		shell._on_phone_page("control_center");await frames()
		var slider:Control=named("ControlBrightness")
		check(slider!=null,"Actual Control Center brightness is reachable")
		if slider:
			var point=slider.get_global_rect().position+Vector2(slider.get_global_rect().size.x*.5,3)
			for pressed in [true,false]:
				var e=InputEventMouseButton.new();e.position=point;e.global_position=point;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;root.push_input(e,true);await process_frame
		await frames(8)
		check(float(state.d.ui.brightness)>=80,"Pointer raises the real brightness value")
		check(state.d.flags.plantLit and state.d.flags.flowerBloomed,"Mounted source light effect triggers automatically behind overlay")
		var count=actions.count("c1_plant_light");shell._refresh();await frames()
		check(actions.count("c1_plant_light")==count,"Rebuild does not replay light or its sound")
		shell._on_phone_action("native_control_center_close",null);await frames()
		await click(named("BonsaiPlant"))
		check(state.d.native.get("flower_eight_visible",false),"Actual flower click reveals source8")
		state.open_page("phone_home");await frames();state.open_page("bonsai");await frames()
		check(not state.d.native.get("flower_eight_visible",false),"Leaving resets local flower reveal")
		await click(named("BonsaiPlant"))
		var eight:Control=named("BonsaiEight");await click(eight)
		check(state.d.flags.flowerEightTaken and state.d.digits.d4=="8","Actual8 control collects once")
		await click(named("BonsaiPlant"));check(not state.d.native.get("flower_eight_visible",false),"Collected flower cannot reveal duplicate8")
	await shell.shutdown();shell.queue_free();await frames()
	print("BONSAI_NATIVE_INPUTS: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
