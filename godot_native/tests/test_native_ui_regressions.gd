extends SceneTree
## Read-only UI metrics plus real headless input/resize probes. No save writes.
var shell: Control
var state: Node
var report := {"kind":"headless-layout-and-input", "graphical_acceptance":false,"screens":[],"checks":[],"failures":[]}
var action_hits := 0
const SIZES := [Vector2i(390,844),Vector2i(430,860),Vector2i(1280,720),Vector2i(1440,900)]
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, id: String, detail: Variant=null) -> void:
	var item={"id":id,"passed":ok,"detail":detail}
	report.checks.append(item)
	if not ok: report.failures.append(item)
func frame(count: int=3) -> void:
	for i in count: await process_frame
func resize_to(screen: Vector2i) -> void:
	root.size=screen
	shell.size=Vector2(screen)
	shell._layout()
	await frame()
func key(code: Key, shifted: bool=false) -> void:
	var event=InputEventKey.new(); event.keycode=code; event.physical_keycode=code; event.shift_pressed=shifted; event.pressed=true
	root.push_input(event,true); await frame(1)
	event=InputEventKey.new(); event.keycode=code; event.physical_keycode=code; event.shift_pressed=shifted; event.pressed=false
	root.push_input(event,true); await frame(1)
func popup_key(popup: PopupMenu, code: Key) -> void:
	for down in [true,false]:
		var event=InputEventKey.new(); event.keycode=code; event.physical_keycode=code; event.pressed=down
		event.window_id=popup.get_window_id(); Input.parse_input_event(event); await frame(1)
func type_text(text: String) -> void:
	for index in text.length():
		for down in [true,false]:
			var event=InputEventKey.new(); event.unicode=text.unicode_at(index); event.pressed=down
			root.push_input(event,true); await frame(1)
func click(point: Vector2) -> void:
	var motion=InputEventMouseMotion.new(); motion.position=point; motion.global_position=point; root.push_input(motion,true)
	for down in [true,false]:
		var event=InputEventMouseButton.new(); event.position=point; event.global_position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=down
		root.push_input(event,true); await frame(1)
func controls(node: Node, output: Array) -> void:
	if node is Control and node.is_visible_in_tree(): output.append(node)
	for child in node.get_children(): controls(child,output)
func rect_data(rect: Rect2) -> Array:
	return [rect.position.x,rect.position.y,rect.size.x,rect.size.y]
func style_data(control: Control, mode: String) -> Dictionary:
	var style=control.get_theme_stylebox(mode)
	if style is StyleBoxFlat:
		return {"background":style.bg_color.to_html(),"border":style.border_color.to_html(),"border_width":style.border_width_left,"corner_radius":style.corner_radius_top_left,"margins":[style.content_margin_left,style.content_margin_right,style.content_margin_top,style.content_margin_bottom]}
	return {"type":style.get_class()}
func metrics(page: String) -> Dictionary:
	var all: Array=[]; controls(shell.page_body,all)
	var texts=[]; var targets=[]
	for node in all:
		if node is Label or node is Button or node is LineEdit or node is TextEdit:
			var text: String=node.text
			if text.is_empty() and node is LineEdit: text=node.placeholder_text
			var font: Font=node.get_theme_font("font")
			var fs: int=node.get_theme_font_size("font_size")
			var scale=node.get_global_transform().get_scale()
			var missing=[]
			for i in text.length():
				var code=text.unicode_at(i)
				if code>32 and not font.has_char(code) and not missing.has(code): missing.append(code)
			var entry={"path":str(shell.get_path_to(node)),"type":node.get_class(),"text":text.left(160),"rect":rect_data(node.get_global_rect()),"local_size":[node.size.x,node.size.y],"minimum_size":[node.get_minimum_size().x,node.get_minimum_size().y],"font_size":fs,"display_font_px":fs*scale.y,"font_height_px":font.get_height(fs)*scale.y,"scale":scale.y,"font_resource":font.resource_path,"missing_codepoints":missing}
			if node is Label:
				entry["line_height_px"]=node.get_line_height()*scale.y
				entry["line_count"]=node.get_line_count()
				entry["clip_text"]=node.clip_text
			if node is Button:
				entry["disabled"]=node.disabled
				entry["states"]={}
				entry["colors"]={}
				for color_name in ["font_color","font_hover_color","font_pressed_color","font_disabled_color","font_focus_color"]: entry.colors[color_name]=node.get_theme_color(color_name).to_html()
				for mode in ["normal","hover","pressed","disabled","focus"]: entry.states[mode]=style_data(node,mode)
			texts.append(entry)
		if node is BaseButton or node is LineEdit or node is Slider:
			targets.append({"path":str(shell.get_path_to(node)),"rect":rect_data(node.get_global_rect()),"local_size":[node.size.x,node.size.y],"focus_mode":node.focus_mode})
	return {"page":page,"texts":texts,"targets":targets,"phone_rect":rect_data(shell.phone.get_global_rect()),"phone_logical_size":[shell.phone.size.x,shell.phone.size.y]}
func _run() -> void:
	state=root.get_node("State"); state.developer_mode=true; state.d=state.initial()
	state.d.native.page="phone_home"
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frame(5)
	for size in SIZES:
		await resize_to(size)
		var item={"viewport":[size.x,size.y],"pages":[]}
		for page in ["phone_home","wechat","system_chat","library_app","weather","c35_recovery","c35_voice","c3_mixer"]:
			state.d.native.page=page
			if page=="c3_mixer":
				state.d.native.chapter=3
				for id in ["blackCoffee","sparklingWater","lemonTea"]: state.d.items[id]=true
			shell._refresh(); await frame()
			item.pages.append(metrics(page))
			check(shell.phone.size==Vector2(430,860),"phone-logical-size/%s/%s" % [size,page],[shell.phone.size.x,shell.phone.size.y])
			check(is_equal_approx(shell.phone.scale.x,shell.phone.scale.y),"phone-uniform-scale/%s/%s" % [size,page])
			check(Rect2(Vector2.ZERO,Vector2(size)).encloses(shell.phone.get_global_rect()),"phone-within-window/%s/%s" % [size,page])
		report.screens.append(item)
	# Focus must move into modal. Key Enter must not trigger the focused background button.
	await resize_to(Vector2i(1440,900))
	var background=Button.new(); background.text="QA background target"; background.position=Vector2(0,0); background.size=Vector2(250,44); background.pressed.connect(func(): action_hits+=1); shell.add_child(background)
	background.grab_focus(); await frame()
	shell._modal_base("字体与输入测试")
	await frame()
	var focused=root.gui_get_focus_owner()
	check(focused!=null and (focused==shell.modal or shell.modal.is_ancestor_of(focused)),"modal-captures-keyboard-focus",str(focused.get_path()) if focused else "none")
	await key(KEY_ENTER)
	check(action_hits==0,"modal-blocks-background-keyboard",{"background_activations":action_hits})
	action_hits=0
	await click(background.get_global_rect().get_center())
	check(action_hits==0,"modal-blocks-background-pointer",{"background_activations":action_hits})
	# Repeated Tab navigation must remain within the modal.
	var escaped_focus=false
	for i in 8:
		await key(KEY_TAB)
		focused=root.gui_get_focus_owner()
		if focused!=null and focused!=shell.modal and not shell.modal.is_ancestor_of(focused): escaped_focus=true
	check(not escaped_focus,"modal-traps-tab-focus")
	escaped_focus=false
	for i in 8:
		await key(KEY_TAB,true)
		focused=root.gui_get_focus_owner()
		if focused!=null and focused!=shell.modal and not shell.modal.is_ancestor_of(focused): escaped_focus=true
	check(not escaped_focus,"modal-traps-shift-tab-focus")
	# Resize after modal creation, including desktop-to-phone, must preserve containment.
	await resize_to(Vector2i(390,844))
	var panel: Control=shell.modal.get_child(0)
	check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(panel.get_global_rect()),"open-modal-reflows-on-resize",rect_data(panel.get_global_rect()))
	await key(KEY_ESCAPE); await frame()
	check(not is_instance_valid(shell.modal),"escape-closes-generic-modal")
	check(root.gui_get_focus_owner()==background,"modal-restores-opener-focus")
	# Exact generic form controls and focus/styles remain reachable at compact size.
	shell._show_form({"id":"qa_no_submission","label":"访客信息（仅测试）","inputs":[{"id":"name","label":"姓名","type":"text","placeholder":"请输入姓名"},{"id":"choice","label":"分类","type":"choice","options":["普通选项","较长的中文选项"]}]})
	await frame()
	var form_nodes=[]; controls(shell.modal,form_nodes)
	var form=[]
	var input: LineEdit
	var dropdown: OptionButton
	for node in form_nodes:
		if node is LineEdit: input=node
		if node is OptionButton: dropdown=node
		if node is LineEdit or node is OptionButton:
			form.append({"type":node.get_class(),"rect":rect_data(node.get_global_rect()),"font_size":node.get_theme_font_size("font_size"),"font":node.get_theme_font("font").resource_path,"normal":style_data(node,"normal"),"focus":style_data(node,"focus")})
	check(form.size()==2,"generic-form-builds-text-and-choice",form)
	input.grab_focus(); await frame(); await type_text("浙A1")
	check(input.text=="浙A1","modal-line-edit-accepts-text",input.text)
	dropdown.grab_focus(); await key(KEY_SPACE)
	var popup: PopupMenu=dropdown.get_popup()
	check(popup.visible,"modal-option-popup-opens-from-keyboard")
	if popup.visible:
		popup.set_focused_item(0); await popup_key(popup,KEY_DOWN)
		check(popup.get_focused_item()==1,"modal-popup-arrow-navigation",popup.get_focused_item())
		await popup_key(popup,KEY_ESCAPE)
		check(not popup.visible and is_instance_valid(shell.modal),"escape-closes-popup-preserves-modal")
		dropdown.grab_focus(); await key(KEY_SPACE)
		popup.set_focused_item(0); await popup_key(popup,KEY_DOWN); await popup_key(popup,KEY_ENTER)
		check(dropdown.selected==1 and not popup.visible,"modal-popup-keyboard-selection",dropdown.selected)
	await key(KEY_ESCAPE); await frame()
	check(not is_instance_valid(shell.modal),"second-escape-closes-form-modal")
	check(root.gui_get_focus_owner()==background,"form-modal-restores-opener-after-popup")
	background.queue_free(); await frame()
	await shell.shutdown(); shell.queue_free(); await frame()
	var path=OS.get_environment("UI_QA_REPORT")
	if path.is_empty(): path="user://native-ui-regressions.json"
	var file=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")); file.close()
	print("NATIVE_UI_QA: %s checks; %s failures; %s" % [report.checks.size(),report.failures.size(),path])
	for failure in report.failures: print("UI_QA_FAIL: ",JSON.stringify(failure))
	quit(1 if report.failures.size()>0 else 0)
