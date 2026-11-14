extends SceneTree
var checks=[]
func _initialize() -> void: _run.call_deferred()
func frame(count: int=4) -> void:
	for i in count:await process_frame
func check(ok: bool,id: String,detail: Variant=null) -> void:checks.append({"passed":ok,"id":id,"detail":detail})
func rect(c: Control) -> Array:
	var r=c.get_global_rect();return [r.position.x,r.position.y,r.size.x,r.size.y]
func key(code: Key) -> void:
	for down in [true,false]:
		var e=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=down;root.push_input(e,true);await frame(1)
func options(node: Node,out: Array) -> void:
	if node is OptionButton:out.append(node)
	for child in node.get_children():options(child,out)
func _run() -> void:
	var state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	var longest={"length":0,"label":"","checkpoint":"","page":"","action":{}}
	var action_count=0
	for checkpoint in state.developer_checkpoints():
		state.begin_checkpoint(checkpoint.id)
		var pages=["c35_recovery","c35_network","c35_photos","c35_voice","c3_menu","library_catalog","cc98","library_recovery"]
		for page in state.get_pages():
			if not pages.has(page.id):pages.append(page.id)
		for page in pages:
			for action in state.get_actions(page):
				action_count+=1
				var fields=action.get("inputs",[{"options":action.get("options",[])}])
				for field in fields:
					for option in field.get("options",[]):
						var label=str(option.get("label",option.get("id",""))) if option is Dictionary else str(option)
						if label.length()>longest.length:longest={"length":label.length(),"label":label,"checkpoint":checkpoint.id,"page":page,"action":action.duplicate(true),"value":option.get("id",option.get("value")) if option is Dictionary else option}
	state.begin_checkpoint(longest.checkpoint)
	root.size=Vector2i(390,844)
	var main=load("res://scenes/main.tscn").instantiate();root.add_child(main);await frame(5)
	var submitted:Array=[]
	state.action_completed.connect(func(action_id,_before,_after,outcome):
		if action_id==longest.action.id:submitted.append(outcome))
	for extent:Vector2i in [Vector2i(390,844),Vector2i(667,320)]:
		state.begin_checkpoint(longest.checkpoint)
		root.size=extent;main.size=Vector2(extent)
		main._show_form(longest.action);await frame()
		var panel:Control=main.modal.get_child(0)
		var bounds:=Rect2(Vector2.ZERO,Vector2(extent))
		check(bounds.encloses(panel.get_global_rect()),"longest-controller-choice-form-contained",{"extent":str(extent),"label":longest.label,"checkpoint":longest.checkpoint,"page":longest.page,"action":longest.action.id,"panel":rect(panel),"actions_scanned":action_count})
		var row:Button
		for option:Button in main.modal.find_children("FormChoice*","Button",true,false):
			if option.text==longest.label:row=option
		check(is_instance_valid(row),"controller-choice-retains-entire-authored-wording",longest.label)
		if not is_instance_valid(row):
			main._close_modal();continue
		var font:Font=row.get_theme_font("font")
		var font_size:int=row.get_theme_font_size("font_size")
		var inset:Vector2=row.get_theme_stylebox("normal").get_minimum_size()
		var width:=maxf(1,row.size.x-inset.x)
		var measured:=font.get_multiline_string_size(row.text,HORIZONTAL_ALIGNMENT_LEFT,width,font_size)
		check(measured.x<=width+.5 and measured.y+inset.y<=row.size.y+.5,"controller-choice-wrap-fits-row",{"extent":str(extent),"measured":str(measured),"row":rect(row)})
		var focus_hops:=0
		while root.gui_get_focus_owner()!=row and focus_hops<16:
			await key(KEY_TAB);focus_hops+=1
		var scroll:ScrollContainer=row.get_parent().get_parent()
		check(root.gui_get_focus_owner()==row and scroll.follow_focus and scroll.get_global_rect().intersects(row.get_global_rect()),"controller-choice-keyboard-focus-scrolls-into-view",str(extent))
		await key(KEY_SPACE)
		check(row.button_pressed and row.button_group.get_pressed_button()==row,"controller-choice-keyboard-selects-exact-row",str(extent))
		var confirm:Button=row.get_parent().get_child(-1)
		confirm.grab_focus();await key(KEY_ENTER);await frame()
		check(not is_instance_valid(main.modal),"confirmed-controller-choice-closes-form",str(extent))
	check(submitted.size()==2,"choice-submits-existing-controller-action-once",submitted.size())
	var panel:Control
	var dropdowns:Array=[]
	main._show_developer();await frame();panel=main.modal.get_child(0);dropdowns.clear();options(main.modal,dropdowns)
	check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(panel.get_global_rect()),"developer-modal-contained",rect(panel))
	for node in dropdowns:check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(node.get_global_rect()),"developer-dropdown-contained",rect(node))
	main._close_modal();await main.shutdown();main.queue_free();await frame()
	print("LONG_FORMS_QA: ",checks.size()," checks")
	for item in checks:print(JSON.stringify(item))
	var out=OS.get_environment("UI_QA_REPORT");if out.is_empty():out="user://native-long-form-layout.json"
	var f=FileAccess.open(out,FileAccess.WRITE);f.store_string(JSON.stringify(checks,"\t"));f.close()
	quit(1 if checks.any(func(x):return not x.passed) else 0)
