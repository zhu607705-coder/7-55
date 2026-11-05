extends SceneTree
## Isolated inventory fixtures in the actual Main scene; optional real rendering.
## Explicitly inserted owned items are not an earned campaign completion claim.
const Flat=preload("res://scripts/ui/phone_flat_button_material.gd")
var shell:Control
var state:Node
var checks:=0
var failures:=0
var output:=OS.get_environment("INVENTORY_CAPTURE_DIR")
var audit:=OS.get_environment("INVENTORY_AUDIT_ONLY")=="1"
var removed:=OS.get_environment("INVENTORY_EXPECT_NO_SHORTCUT")!="0"
var materials:Array=[]
func _initialize()->void:run.call_deferred()
func frames(count:int=5)->void:
	for unused in count:await process_frame
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("INVENTORY FLAT: "+message)
func button(text:String)->Button:
	for node:Button in shell.modal.find_children("*","Button",true,false):
		if node.text==text:return node
	return null
func click(node:Control)->void:
	check(node!=null and node.is_visible_in_tree(),"pointer target exists")
	if node==null:return
	var point:=node.get_global_transform_with_canvas()*(node.size/2)
	var motion:=InputEventMouseMotion.new();motion.position=point;root.push_input(motion,true)
	for down:bool in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;root.push_input(event,true)
	await frames()
func key(code:Key)->void:
	for down:bool in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down;root.push_input(event,true)
	await frames()
func inspect()->void:
	shell._inspect_item({"id":"towerKey","name":"钟楼钥匙","desc":"形状奇怪的钥匙。"});await frames()
func styles(node:Button,label:String)->void:
	check(node!=null,label+" exists")
	if node==null:return
	var rect:=node.get_rect()
	for mode:String in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
		var style:=node.get_theme_stylebox(mode)
		materials.append({"label":label,"mode":mode,"style":style.get_script().resource_path if style.get_script()!=null else style.get_class()})
		if audit:continue
		check(style is Flat,label+" "+mode+" uses shared flat material")
		if style is Flat:check(style.shadow_size==0 and style.shadow_offset==Vector2.ZERO and style.corner_radius_top_left<=4,label+" "+mode+" has no raised effect")
	node.disabled=true;await frames();node.disabled=false;await frames()
	check(node.get_rect()==rect,label+" state changes preserve hit rectangle")
func shot(id:String)->void:
	if output.is_empty() or DisplayServer.get_name()=="headless":return
	DirAccess.make_dir_recursive_absolute(output);await frames();await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output.path_join(id+".png"))==OK,"real rendered capture "+id)
func capture_states(node:Button,prefix:String)->void:
	if output.is_empty() or DisplayServer.get_name()=="headless":return
	root.gui_release_focus()
	var motion:=InputEventMouseMotion.new();motion.position=Vector2(1,1);root.push_input(motion,true)
	await shot(prefix+"-normal")
	var point:=node.get_global_transform_with_canvas()*(node.size/2)
	motion=InputEventMouseMotion.new();motion.position=point;root.push_input(motion,true)
	await shot(prefix+"-hover")
	var down:=InputEventMouseButton.new();down.position=point;down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;root.push_input(down,true)
	await shot(prefix+"-pressed")
	motion=InputEventMouseMotion.new();motion.position=Vector2(1,1);root.push_input(motion,true)
	var up:=InputEventMouseButton.new();up.position=Vector2(1,1);up.button_index=MOUSE_BUTTON_LEFT;root.push_input(up,true)
	await frames();node.disabled=true;await shot(prefix+"-disabled");node.disabled=false
	node.grab_focus();await shot(prefix+"-focus")
func full_drag_to_tower(touch:bool)->void:
	state.d.native.tower_key_pending=false;state.select_item("");shell._refresh();await frames()
	if not shell.phone_chrome.inventory_open:shell.phone_chrome._toggle_inventory();await frames()
	var source:Control=shell.phone_chrome.inventory_slots.get_node("Item_towerKey")
	shell.phone_chrome.inventory_scroll.ensure_control_visible(source);await frames()
	var target:Control=shell.phone.find_child("TowerDropTarget",true,false)
	var start:=source.get_global_transform_with_canvas()*(source.size/2)
	var end:=target.get_global_transform_with_canvas()*(target.size/2)
	if touch:
		var down:=InputEventScreenTouch.new();down.index=0;down.position=start;down.pressed=true;Input.parse_input_event(down)
	else:
		var down:=InputEventMouseButton.new();down.position=start;down.global_position=start;down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;Input.parse_input_event(down)
	await frames(1)
	var last:=start
	for i:int in range(1,10):
		var point:=start.lerp(end,i/9.0)
		if touch:
			var motion:=InputEventScreenDrag.new();motion.index=0;motion.position=point;motion.relative=point-last;Input.parse_input_event(motion)
		else:
			var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;motion.relative=point-last;motion.button_mask=MOUSE_BUTTON_MASK_LEFT;Input.parse_input_event(motion)
		last=point;await frames(1)
	check(root.gui_is_dragging(),"full tower drag starts: "+str(touch))
	if touch:
		var up:=InputEventScreenTouch.new();up.index=0;up.position=end;Input.parse_input_event(up)
	else:
		var up:=InputEventMouseButton.new();up.position=end;up.global_position=end;up.button_index=MOUSE_BUTTON_LEFT;Input.parse_input_event(up)
	await frames()
	check(not root.gui_is_dragging(),"full tower drag releases: "+str(touch))
	check(state.d.native.get("tower_key_pending",false),"full tower drag reaches controller: "+str(touch))
	print("FULL_TOWER_DRAG ",touch," start=",start," end=",end," pending=",state.d.native.get("tower_key_pending",false))
func run()->void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	create_timer(180).timeout.connect(func():push_error("Inventory fixture timeout");quit(2))
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	state.d.native.page="phone_home";state.d.currentScene="phone_home";state.d.flags.codeScattered=true
	state.d.items.towerKey=true;state.d.items.headphone=true;state.d.items.waterDrop=true
	state.d.native.settings.music=false;state.d.native.settings.effects=false;state.d.native.settings.reduced_motion=true
	shell=load("res://scenes/main.tscn").instantiate()
	var override:=OS.get_environment("INVENTORY_MAIN_OVERRIDE")
	if not override.is_empty():shell.set_script(load(override))
	root.add_child(shell);await frames(12);shell.set_process(false)
	if is_instance_valid(shell.audio_director):shell.audio_director.reset();shell.audio_director.set_process(false)
	for extent:Vector2i in [Vector2i(390,844),Vector2i(1440,900)]:
		root.size=extent;shell.size=Vector2(extent)
		if DisplayServer.get_name()!="headless":DisplayServer.window_set_size(extent)
		shell._layout();await frames();await inspect()
		await styles(button("关闭"),"item detail Close");await frames()
		check((button("选择使用")==null)==removed,"shortcut presence matches requested variant")
		if not removed:await styles(button("选择使用"),"item detail Select");await frames()
		var close:=button("关闭");await capture_states(close,"%dx%d-item-close"%[extent.x,extent.y])
		await click(close);check(not is_instance_valid(shell.modal),"Close dismisses without selecting")
		check(str(state.d.native.selected_item)=="" and state.d.items.towerKey,"closing never selects or consumes item")
		shell._show_inventory();await frames();await styles(button("关闭"),"inventory Close")
		if button("组合物品")!=null:await styles(button("组合物品"),"inventory Combine")
		await shot("%dx%d-inventory"%[extent.x,extent.y]);shell._close_modal();await frames()
	if not removed:
		await inspect();var use:=button("选择使用");use.disabled=true;await click(use)
		check(str(state.d.native.selected_item)=="","disabled Select cannot select")
		use.disabled=false;use.grab_focus();await key(KEY_ENTER)
		check(str(state.d.native.selected_item)=="towerKey" and str(state.d.ui.selectedItem)=="towerKey","Select sets existing shared selection")
		check(state.d.items.towerKey and not state.d.flags.towerOpened,"Select alone never consumes or opens tower")
		check(not is_instance_valid(shell.modal),"Select dismisses details")
		state.select_item("");await frames()
	# Shared alternative: normal inventory space selects; Enter only inspects.
	if not shell.phone_chrome.inventory_open:shell.phone_chrome._toggle_inventory();await frames()
	var slot:Button=shell.phone_chrome.inventory_slots.get_node("Item_towerKey")
	shell.phone_chrome.inventory_scroll.ensure_control_visible(slot);await frames();slot.grab_focus();await key(KEY_SPACE)
	check(str(state.d.native.selected_item)=="towerKey","keyboard Space selects without detail shortcut")
	# Actual Enter-inspect followed by Escape preserves the selection.
	slot=shell.phone_chrome.inventory_slots.get_node("Item_towerKey");slot.grab_focus();await key(KEY_ENTER)
	check(is_instance_valid(shell.modal),"keyboard Enter opens item detail")
	await key(KEY_ESCAPE);check(not is_instance_valid(shell.modal) and str(state.d.native.selected_item)=="towerKey","Escape from detail preserves keyboard selection")
	# Native touch tap uses the same pre-existing selection path.
	state.select_item("");await frames();shell.phone_chrome.inventory_gestures.reset()
	slot=shell.phone_chrome.inventory_slots.get_node("Item_towerKey")
	shell.phone_chrome.inventory_scroll.ensure_control_visible(slot);await frames()
	var touch_point:=slot.get_global_transform_with_canvas()*(slot.size/2)
	for down:bool in [true,false]:
		var touch:=InputEventScreenTouch.new();touch.index=0;touch.position=touch_point;touch.pressed=down;root.push_input(touch,true);await frames(1)
	await frames();check(str(state.d.native.selected_item)=="towerKey","touch tap selects without detail shortcut")
	var target:Button=shell.phone.find_child("TowerDropTarget",true,false)
	check(target!=null,"real tower target exists")
	if target!=null:
		# Native target input, not a controller-only direct call.
		target.grab_focus();await key(KEY_ENTER)
		check(state.d.native.get("tower_key_pending",false),"selected item reaches actual tower target through keyboard")
	state.d.native.tower_key_pending=false;state.select_item("");shell._refresh();await frames()
	# Same target supports native drop dispatch without preselection.
	target=shell.phone.find_child("TowerDropTarget",true,false)
	if target!=null:
		var payload:Dictionary={"kind":"inventory_item","item":"towerKey"}
		check(target._can_drop_data(target.size/2,payload),"tower accepts original key drop without selection")
		target._drop_data(target.size/2,payload);await frames()
		check(state.d.native.get("tower_key_pending",false),"native drop signal still reaches tower controller")
	await full_drag_to_tower(false);await full_drag_to_tower(true)
	print("INVENTORY_MATERIALS ",JSON.stringify(materials))
	await shell.shutdown();shell.queue_free();await frames()
	print("INVENTORY_FLAT_ACTIONS: ",checks," checks; ",failures," failures; removed=",removed,"; audit=",audit);quit(1 if failures else 0)
