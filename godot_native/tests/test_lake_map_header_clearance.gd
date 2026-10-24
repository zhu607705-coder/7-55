extends SceneTree
## Layout fixtures and actual GUI input, not earned campaign proof.
var checks:=0
var failures:=0
var saw_two_rows:=false
const CLUES=["bridge","reflection","lake"]
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func frames()->void:
	for unused in 6:await process_frame
func painted_bag(shell: Control)->Rect2:
	var bag: Rect2=shell.phone_chrome.inventory_handle.get_global_rect()
	var paint: StyleBoxFlat=shell.phone_chrome.inventory_handle.get_theme_stylebox("normal")
	var factor:float=absf(shell.phone_chrome.inventory_handle.get_global_transform_with_canvas().get_scale().x)
	var shadow:=bag.grow(paint.shadow_size*factor);shadow.position+=paint.shadow_offset*factor
	return bag.merge(shadow).merge(shell.phone_chrome.inventory_count.get_global_rect())
func click(target: Control)->void:
	var point:=target.get_global_rect().get_center()
	for pressed:bool in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
		Input.parse_input_event(event);await process_frame
func run()->void:
	var state:=root.get_node("State");state.developer_mode=true
	for state_case:int in 5:
		state.begin_checkpoint("c3-qizhen-location")
		state.d.native.scene="";state.d.native.page="zjuding"
		state.d.qizhenLake.active=true;state.d.qizhenLake.phase="lake_unlocked" if state_case==4 else "location_search"
		var count_value:int=mini(state_case,3);state.d.qizhenLake.mapClueIds=CLUES.slice(0,count_value)
		for item:String in ["bridgeKeyword","reflectionKeyword","lakeKeyword"]:state.d.items[item]=true
		root.size=Vector2i(390,844)
		var shell:Control=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
		shell.mobile_world=false;shell._refresh();shell._process(2);await frames()
		shell.phone_builder.zjuding_page="campus_map";shell._refresh();await frames()
		var drop:Control=shell.page_body.find_child("QizhenMapDrop",true,false)
		# Resize the SAME mounted page, including return to portrait. The extra
		# short window exercises two-row fallback without changing fonts or DPR.
		for dimensions:Vector2i in [Vector2i(390,844),Vector2i(844,390),Vector2i(1440,900),Vector2i(844,260),Vector2i(390,844)]:
			root.size=dimensions;await frames()
			check(drop==shell.page_body.find_child("QizhenMapDrop",true,false),"resize retains the same map and action objects")
			var count:Label=drop.get_node("QizhenMapCount")
			var status:Label=drop.get_node("QizhenMapStatus")
			var header:Control=drop.get_node("QizhenMapHeader")
			var context:=str(dimensions)+" state="+str(state_case)
			check(not count.get_global_rect().intersects(painted_bag(shell)),"painted44px bag and badge clear map count "+context)
			check(not count.get_global_rect().intersects(status.get_global_rect()),"count and right status do not overlap "+context)
			check(count.text=="已接入  %d / 3"%count_value,"header retains authored progress "+context)
			check(status.text==("入口已标记" if state_case==4 else "待核对" if count_value==3 else "收集中"),"header retains complete authored status "+context)
			check(count.get_theme_font_size("font_size")==22 and status.get_theme_font_size("font_size")==14,"original header font sizes remain unchanged")
			for text:Label in [count,status]:
				check(text.get_theme_font("font").get_string_size(text.text,HORIZONTAL_ALIGNMENT_LEFT,-1,text.get_theme_font_size("font_size")).x<=text.size.x,"full text fits its own header column "+context)
				check(header.get_global_rect().encloses(text.get_global_rect()),"header encloses both original text labels "+context)
			var delta:float=header.size.y-55;saw_two_rows=saw_two_rows or delta>0
			check(delta in [0.0,25.0] and drop.size.y==392+delta,"header changes only the necessary local height")
			for child:Node in drop.get_children():
				if child is Control and child.has_meta("map_row_y"):
					check(is_equal_approx(child.position.y,float(child.get_meta("map_row_y"))+delta),"every original row/target follows header without accumulated shift")
			var inner:Control=drop.get_parent()
			check(is_equal_approx(inner.custom_minimum_size.y,float(drop.get_meta("map_inner_height"))+delta),"scroll extent follows the full original content")
			for child:Node in inner.get_children():
				if child is Control and child.has_meta("map_after_y"):
					check(is_equal_approx(child.position.y,float(child.get_meta("map_after_y"))+delta) and child.position.y+child.size.y<=inner.custom_minimum_size.y,"last feedback/confirmation remains in scrollable content")
			var scroll:ScrollContainer=inner.get_parent();scroll.scroll_vertical=100000;await frames()
			check(scroll.scroll_vertical>0 and scroll.get_v_scroll_bar().max_value>=inner.custom_minimum_size.y,"the full last map row stays scroll-reachable")
			scroll.scroll_vertical=0;await frames()
			var stable_count:Rect2=count.get_rect();var stable_extent:float=inner.custom_minimum_size.y
			shell._layout();shell._layout();await frames()
			check(count.get_rect()==stable_count and inner.custom_minimum_size.y==stable_extent,"repeated layout never accumulates row offsets")
		if count_value<3:
			var button:Button=drop.get_node("QizhenMapImport_"+CLUES[count_value])
			var scroll:ScrollContainer=drop.get_parent().get_parent();scroll.scroll_vertical=int(drop.position.y+button.position.y-60);await frames()
			check(button.get_global_rect().intersects(scroll.get_global_rect()) and button.get_global_rect().has_point(button.get_global_rect().get_center()),"ordinary import target remains reachable after resize/scroll")
			await click(button);await frames()
			check(state.d.qizhenLake.mapClueIds.size()==count_value+1 and state.d.qizhenLake.mapClueIds.has(CLUES[count_value]),"one actual GUI click still invokes the original map import exactly once")
		await shell.shutdown();shell.queue_free();await frames()
	check(saw_two_rows,"very short window exercises the local two-row fallback")
	print("Lake map header clearance: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
