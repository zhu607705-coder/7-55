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
						if label.length()>longest.length:longest={"length":label.length(),"label":label,"checkpoint":checkpoint.id,"page":page,"action":action.duplicate(true)}
	state.begin_checkpoint(longest.checkpoint)
	root.size=Vector2i(390,844)
	var main=load("res://scenes/main.tscn").instantiate();root.add_child(main);await frame(5)
	main._show_form(longest.action);await frame()
	var panel=main.modal.get_child(0);var dropdowns=[];options(main.modal,dropdowns)
	check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(panel.get_global_rect()),"longest-controller-choice-form-contained",{"label":longest.label,"length":longest.length,"checkpoint":longest.checkpoint,"page":longest.page,"action":longest.action.id,"panel":rect(panel),"actions_scanned":action_count})
	for node in dropdowns:check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(node.get_global_rect()),"controller-dropdown-contained",rect(node))
	if not dropdowns.is_empty():
		dropdowns[0].grab_focus();await key(KEY_SPACE);await frame()
		var popup: PopupMenu=dropdowns[0].get_popup()
		check(popup.visible and Rect2(Vector2.ZERO,Vector2(root.size)).encloses(Rect2(Vector2(popup.position),Vector2(popup.size))),"controller-option-popup-contained",[popup.position.x,popup.position.y,popup.size.x,popup.size.y])
		if popup.has_method("get_theme_font"):
			var popup_font: Font=popup.get_theme_font("font")
			var font_size: int=popup.get_theme_font_size("font_size")
			var style: StyleBox=popup.get_theme_stylebox("panel")
			var width: float=popup_font.get_string_size(longest.label,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
			var margins: float=style.get_content_margin(SIDE_LEFT)+style.get_content_margin(SIDE_RIGHT)+popup.get_theme_constant("h_separation")*2
			check(width+margins<=popup.size.x,"controller-popup-longest-wording-fits",{"font":popup_font.resource_path,"font_size":font_size,"text_width":width,"horizontal_insets":margins,"popup_width":popup.size.x,"label":longest.label})
		popup.hide();await frame()
	main._show_developer();await frame();panel=main.modal.get_child(0);dropdowns.clear();options(main.modal,dropdowns)
	check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(panel.get_global_rect()),"developer-modal-contained",rect(panel))
	for node in dropdowns:check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(node.get_global_rect()),"developer-dropdown-contained",rect(node))
	main._close_modal();await main.shutdown();main.queue_free();await frame()
	print("LONG_FORMS_QA: ",checks.size()," checks")
	for item in checks:print(JSON.stringify(item))
	var out=OS.get_environment("UI_QA_REPORT");if out.is_empty():out="user://native-long-form-layout.json"
	var f=FileAccess.open(out,FileAccess.WRITE);f.store_string(JSON.stringify(checks,"\t"));f.close()
	quit(1 if checks.any(func(x):return not x.passed) else 0)
