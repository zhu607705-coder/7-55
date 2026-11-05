extends RefCounted
## The actual Control Center shell: one 378px authoring canvas and the same
## existing phone-page factories. Task pages use it without changing its chrome.
static func create(b, title: String, dismiss: Callable, panel_height: float, prefix: String) -> Dictionary:
	var height: float=854.0/b.PHONE_SCALE
	var root: Control=b._base(Color(20/255.0,18/255.0,14/255.0,.45),height)
	root.set_meta("source_overlay",true)
	var backdrop: Button=b._button(root,"",Rect2(0,0,378,height),dismiss,Color.TRANSPARENT,b.INK,0,Color.TRANSPARENT)
	backdrop.set_meta("tactile_exempt",true);backdrop.name=prefix+"Backdrop"
	for mode: String in ["normal","hover","pressed","focus"]:backdrop.add_theme_stylebox_override(mode,b._style(Color.TRANSPARENT))
	var panel: Panel=b._panel(root,Rect2(0,0,378,panel_height),Color("e9e5da"),b.INK,0,2)
	panel.mouse_filter=Control.MOUSE_FILTER_STOP;panel.name=prefix+"Panel"
	var heading: Label=b._label(panel,title,Rect2(14,13,260,27),16)
	heading.name="PhoneOverlayTitle"
	var close: Button=b._nav(panel,"close","收起控制中心" if prefix=="ControlCenter" else "返回游戏",dismiss,Rect2(337,12,27,27),b.PAPER)
	close.add_theme_font_size_override("font_size",16)
	return {"root":root,"panel":panel,"title":heading,"close":close,"backdrop":backdrop}

static func wrap(b, root: Control) -> Control:
	var outer:=Control.new()
	var factor: float=b.PHONE_SCALE
	outer.custom_minimum_size=Vector2(424,root.custom_minimum_size.y*factor)
	outer.size=outer.custom_minimum_size
	root.scale=Vector2.ONE*factor
	outer.add_child(root)
	outer.set_meta("handled_action_ids",b.handled.duplicate())
	outer.set_meta("handles_app_grid",root.get_meta("handles_app_grid",false))
	outer.set_meta("source_page",true);outer.set_meta("bare",false)
	outer.set_meta("source_overlay",true)
	outer.set_meta("handles_all_actions",root.get_meta("handles_all_actions",false))
	outer.clip_contents=true
	return outer

static func label(b, text: String, pixels: int=13, ink: Color=Color("222322")) -> Label:
	var holder:=Control.new()
	var result: Label=b._label(holder,text,Rect2(0,0,330,pixels+8),pixels,ink)
	holder.remove_child(result);holder.free()
	result.custom_minimum_size=Vector2(0,pixels+8)
	result.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return result

static func action(b, text: String, callback: Callable, fill: Color=Color("fff4d8")) -> Button:
	var holder:=Control.new()
	var result: Button=b._button(holder,text,Rect2(0,0,330,36),callback,fill,b.INK)
	holder.remove_child(result);holder.free()
	result.custom_minimum_size=Vector2(0,36)
	result.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return result

static func card(b, fill: Color=Color("fff6df")) -> Dictionary:
	var holder:=Control.new()
	var panel: Panel=b._panel(holder,Rect2(0,0,350,20),fill,b.INK,0,2)
	holder.remove_child(panel);holder.free()
	panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var content:=VBoxContainer.new();content.position=Vector2(10,8);content.size.x=330
	content.add_theme_constant_override("separation",8);panel.add_child(content)
	panel.resized.connect(func():content.size.x=maxf(1,panel.size.x-20))
	content.minimum_size_changed.connect(func():panel.custom_minimum_size.y=content.get_combined_minimum_size().y+16)
	return {"panel":panel,"content":content}
