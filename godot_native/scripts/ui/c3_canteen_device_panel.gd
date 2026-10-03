extends Control
## Canteen devices use the existing chapter controller. Draft selection and
## layout are local; inventory, payment and progression remain authoritative.
signal closed(reason: String)
const Chapter=preload("res://scripts/chapters/chapter3.gd")
const DRINKS={"sparklingWater":{"name":"气泡水（蓝色）","color":Color("43bce9"),"accent":Color("e9fbff")},"lemonTea":{"name":"柠檬茶（白色）","color":Color("f2f0dc"),"accent":Color("d0a636")},"blackCoffee":{"name":"黑咖啡（黑色）","color":Color("1b1d20"),"accent":Color("8b6846")}}
var kind: String=""
var target_id: String=""
var item_id: String=""
var read_state: Callable
var dispatch: Callable
var feedback: Callable
var toggle_mode: Callable
var bound_state: Dictionary={}
var active:=false
var compact_layout:=false
var board:=Rect2()
var controls: Dictionary={}
var labels: Dictionary={}
var selection:=0
var feedback_label: Label
var content: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter3-canteen.content.json"))
var chapter=Chapter.new()
var initial_order_count:=0
var last_dark:=false
var illustration:=Rect2()
var painted_dark: Variant=null

func setup(device: String,reader: Callable,sink: Callable,feedback_sink: Callable=Callable(),mode_sink: Callable=Callable()) -> bool:
	kind="drink" if device.begins_with("drink:") else device
	if kind not in ["drink","menu","bike"] or not reader.is_valid(): return false
	target_id=device.trim_prefix("drink:") if kind=="drink" else "ordering_kiosk" if kind=="menu" else "bike"
	read_state=reader;dispatch=sink;feedback=feedback_sink;toggle_mode=mode_sink;bound_state=reader.call()
	var scene: String="campus_bootstrap" if kind=="bike" else "canteen_interior"
	var entry: Dictionary=chapter.get_definition(scene,target_id,bound_state)
	if entry.is_empty() or not chapter.near_source(bound_state,scene,entry): return false
	if kind=="drink":
		item_id=str(entry.get("value",""))
		if not DRINKS.has(item_id): return false
	active=true;last_dark=bound_state.native.mode=="dark";initial_order_count=int(bound_state.canteenHunt.orderAttemptCount)
	mouse_filter=Control.MOUSE_FILTER_STOP
	_build();configure_layout(Vector2(960,540),false);refresh();_opened.call_deferred();return active

func _opened() -> void:
	if not active: return
	if kind=="bike": dispatch.call("c3_bike_inspect",null)
	elif kind=="menu" and last_dark: dispatch.call("c3_menu_observe",null)
	# Keep Main's overlay focus until the opening key has been released.
	# Focusing a button here lets Godot activate it on that same Space release.

func _build() -> void:
	_label("title",20)
	_label("body",17)
	_label("hint",14)
	feedback_label=_label("feedback",14);feedback_label.hide()
	if kind=="drink":
		_button("take",str(content.drinks.takeOption),func(): _take())
		_button("cancel",str(content.drinks.cancelOption),func(): dismiss())
	elif kind=="menu":
		for option in content.menu.options:
			var id: String=option.id
			_button(id,"",func(): _order(id))
		_button("mode","",_toggle_mode)
		_button("close","关闭",dismiss)
	else:
		_button("inspect","查看车锁",func(): dispatch.call("c3_bike_inspect",null))
		_button("clean","用油渍纸巾擦拭",func(): dispatch.call("c3_bike_clean",null);refresh())
		_button("pay","用餐盘回收费支付 ¥2.00",func(): dispatch.call("c3_bike_pay",null);refresh())
		_button("ride","开始骑行",func():
			var sink: Callable=dispatch
			dismiss("ride")
			sink.call_deferred("c3_chase",null))
		_button("mode","",_toggle_mode)
		_button("close","关闭",dismiss)

func _label(id: String,font_size: int) -> Label:
	var label:=Label.new();label.name="Canteen_"+id;label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size",font_size)
	add_child(label);labels[id]=label;return label
func _button(id: String,text: String,callback: Callable) -> Button:
	var button:=Button.new();button.name="Canteen_"+id;button.text=text
	button.add_theme_font_size_override("font_size",17);button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	for state in ["font_color","font_hover_color","font_focus_color","font_pressed_color","font_hover_pressed_color"]: button.add_theme_color_override(state,Color("f4fbff"))
	button.add_theme_color_override("font_disabled_color",Color("afc0ca"))
	for state in ["normal","hover","pressed","focus","disabled"]:
		var style:=StyleBoxFlat.new();style.bg_color=Color("123c54") if state in ["hover","pressed"] else Color("20313e")
		style.border_color=Color("75e4ff") if state=="focus" else Color("82919b");style.set_border_width_all(2)
		button.add_theme_stylebox_override(state,style)
	button.pressed.connect(func():
		if active: callback.call())
	add_child(button);controls[id]=button;return button
func _place(control: Control,rect: Rect2) -> void:
	control.position=rect.position;control.size=rect.size
func configure_layout(viewport: Vector2,compact: bool) -> void:
	compact_layout=compact;custom_minimum_size=Vector2.ZERO;size=viewport if compact else Vector2(960,540)
	var portrait: bool=compact and viewport.y>viewport.x
	var extent: Vector2
	if not compact: extent=Vector2(470,278) if kind=="drink" else Vector2(570,376)
	elif kind=="drink": extent=Vector2(minf(viewport.x-24,560),minf(viewport.y-24,380))
	elif kind=="menu": extent=Vector2(minf(viewport.x-24,680),minf(viewport.y-24,660 if portrait else 366))
	else: extent=Vector2(minf(viewport.x-24,680),minf(viewport.y-24,640 if portrait else 366))
	board=Rect2((size-extent)/2,extent)
	var p: Vector2=board.position;var w: float=extent.x;var h: float=extent.y
	var text_color:=Color("f4fbff")
	for label in labels.values(): label.add_theme_color_override("font_color",text_color)
	if kind=="drink":
		_place(labels.title,Rect2(p+Vector2(16,8),Vector2(w-32,38)))
		illustration=Rect2(p+Vector2(36,66),Vector2(68,110))
		_place(labels.body,Rect2(p+Vector2(118,64),Vector2(w-138,104)))
		var by: float=h-124 if compact else 197
		var bw: float=(w-48)/2
		_place(controls.take,Rect2(p+Vector2(16,by),Vector2(bw,48)))
		_place(controls.cancel,Rect2(p+Vector2(32+bw,by),Vector2(bw,48)))
		_place(labels.hint,Rect2(p+Vector2(12,by+52),Vector2(w-24,48 if compact else 28)))
		if not compact:
			_place(controls.take,Rect2(303,328,164,48));_place(controls.cancel,Rect2(493,328,164,48))
			_place(labels.hint,Rect2(245,378,470,28))
			illustration=Rect2(343,188,68,110)
			_place(labels.body,Rect2(420,185,220,104))
	elif kind=="menu":
		labels.title.add_theme_font_size_override("font_size",17 if compact else 20)
		_place(labels.title,Rect2(p+Vector2(16,8),Vector2(w-32,64 if portrait else 52)))
		labels.body.hide()
		if portrait:
			for i in range(content.menu.options.size()): _place(controls[str(content.menu.options[i].id)],Rect2(p+Vector2(16,84+i*58),Vector2(w-32,50)))
			_place(labels.hint,Rect2(p+Vector2(16,382),Vector2(w-32,54)))
			_place(controls.mode,Rect2(p+Vector2(16,448),Vector2(w-112,48)))
			_place(controls.close,Rect2(p+Vector2(w-88,448),Vector2(72,48)))
		elif compact:
			var cw: float=(w-48)/2
			for i in range(content.menu.options.size()): _place(controls[str(content.menu.options[i].id)],Rect2(p+Vector2(16+(i%2)*(cw+16),68+floori(i/2.0)*52),Vector2(cw,48)))
			_place(labels.hint,Rect2(p+Vector2(16,224),Vector2(w-32,38)))
			_place(controls.mode,Rect2(p+Vector2(16,268),Vector2(w-112,48)))
			_place(controls.close,Rect2(p+Vector2(w-88,268),Vector2(72,48)))
		else:
			for i in range(content.menu.options.size()): _place(controls[str(content.menu.options[i].id)],Rect2(265,155+i*55,430,42))
			_place(labels.hint,Rect2(211,422,430,28))
			# Source board and option geometry stay intact; accessible mode/close
			# actions occupy the spare space below that board.
			_place(controls.mode,Rect2(210,468,260,44))
			_place(controls.close,Rect2(672,468,76,44))
			_place(labels.title,Rect2(211,94,538,54))
	else:
		_place(labels.title,Rect2(p+Vector2(16,10),Vector2(w-32,36)))
		if portrait:
			illustration=Rect2(p+Vector2(w/2-48,64),Vector2(96,92))
			_place(labels.body,Rect2(p+Vector2(16,168),Vector2(w-32,80)))
			_place(controls.inspect,Rect2(p+Vector2(16,262),Vector2(w-32,48)))
			_place(controls.clean,Rect2(p+Vector2(16,318),Vector2(w-32,48)))
			_place(controls.pay,Rect2(p+Vector2(16,374),Vector2(w-32,48)))
			_place(controls.ride,Rect2(p+Vector2(16,374),Vector2(w-32,48)))
			_place(controls.mode,Rect2(p+Vector2(16,446),Vector2(w-112,48)))
			_place(controls.close,Rect2(p+Vector2(w-88,446),Vector2(72,48)))
			_place(labels.hint,Rect2(p+Vector2(16,500),Vector2(w-32,54)))
		else:
			illustration=Rect2(p+Vector2(24,65),Vector2(96,92))
			_place(labels.body,Rect2(p+Vector2(132,52),Vector2(w-148,96)))
			var bw: float=(w-48)/2
			_place(controls.inspect,Rect2(p+Vector2(16,146),Vector2(bw,48)))
			_place(controls.clean,Rect2(p+Vector2(32+bw,146),Vector2(bw,48)))
			_place(controls.pay,Rect2(p+Vector2(16,202),Vector2(w-128,48)))
			_place(controls.ride,Rect2(p+Vector2(16,202),Vector2(w-128,48)))
			_place(controls.close,Rect2(p+Vector2(w-96,202),Vector2(80,48)))
			_place(controls.mode,Rect2(p+Vector2(16,258),Vector2(210,48)))
			_place(labels.hint,Rect2(p+Vector2(238,258),Vector2(w-254,48)))
	var feedback_y: float=h-68 if portrait else h-46
	_place(feedback_label,Rect2(p+Vector2(16,feedback_y),Vector2(w-32,60 if portrait else 40)))
	if not compact and kind=="menu": _place(feedback_label,Rect2(20,514,920,24))
	# Drink hints already fill their footer; action feedback displays after close.
	feedback_label.visible=kind!="drink" and not feedback_label.text.is_empty()
	painted_dark=null
	if active: _palette(bool(read_state.call().native.mode=="dark"))
	queue_redraw()
func set_feedback(message: String) -> void:
	feedback_label.text=message;feedback_label.visible=kind!="drink" and not message.is_empty()
func _toggle_mode() -> void:
	if not toggle_mode.is_valid(): return
	toggle_mode.call();refresh()
func _take() -> void:
	if not active: return
	var sink: Callable=dispatch;var target: String=target_id
	dismiss("take")
	sink.call("c3_drink_take:"+target,null)
func _order(id: String) -> void:
	if not active: return
	dispatch.call("c3_order",id);refresh()
func _select(index: int) -> void:
	selection=index
	if kind=="drink":
		if selection==0: controls.take.grab_focus()
		else: controls.cancel.grab_focus()
func refresh() -> void:
	if not active: return
	var s: Dictionary=read_state.call();var c: Dictionary=s.canteenHunt
	var expected_scene: String="campus_bootstrap" if kind=="bike" else "canteen_interior"
	if not is_same(s,bound_state) or str(s.native.scene)!=expected_scene: dismiss("context_changed");return
	var dark: bool=s.native.mode=="dark"
	if kind=="drink":
		if dark or not chapter.side_active(c) or c.promoDrinkPlaced or c.queueGapOpened: dismiss("context_changed");return
		labels.title.text=DRINKS[item_id].name
		labels.body.text=str(content.drinks.alreadyOwned if s.items.get(item_id,false) else content.drinks.machinePrompt)
		labels.hint.text="← / → 选择 · 空格 / 回车确认\nEsc 退出" if compact_layout else "← / → 选择 · 空格 / 回车确认 · Esc 退出"
	elif kind=="menu":
		if c.phase not in ["menu_order","pickup_search"] or int(c.orderAttemptCount)>initial_order_count: dismiss("order_complete");return
		labels.title.text=str(content.menu.darkIntro if dark else content.menu.lightIntro)
		for option in content.menu.options: controls[str(option.id)].text=str(option.id)+"  "+str(option.dark if dark else option.light)
		labels.hint.text="观察模式 · 菜名留下了另一层字" if dark else str(content.menu.alreadyActive) if c.phase=="pickup_search" else "选择一份餐品 · 取餐前不能重复下单"
		if dark and not last_dark: dispatch.call("c3_menu_observe",null)
	else:
		if c.phase!="chase_ready": dismiss("context_changed");return
		labels.title.text="共享单车 · 车锁"
		var status: String=str(content.bike.codeVisible if dark else content.bike.lockCleaned if c.bikeLockCleaned else content.bike.glareFailed)
		labels.body.text=str(content.bike.scan)+"\n"+str(content.bike.balance).replace("{amount}","%.2f"%(float(s.wallet.cashCents)/100.0))+"\n"+("已支付 · 车锁已开" if c.bikePaid else status)
		controls.clean.visible=not c.bikePaid;controls.clean.disabled=not bool(s.items.get("greaseTissue",false))
		controls.pay.visible=not c.bikePaid;controls.ride.visible=c.bikePaid
		labels.hint.text="Esc 关闭 · 纸巾使用后保留" if s.items.get("greaseTissue",false) else "Esc 关闭"
	if kind!="drink": controls.mode.text="切换到浅色操作" if dark else "切换到深色观察"
	_palette(dark)
	last_dark=dark;queue_redraw()
func _palette(dark: bool) -> void:
	if kind!="menu" or painted_dark==dark: return
	painted_dark=dark
	for label in labels.values(): label.add_theme_color_override("font_color",Color("e8f7ff") if dark or (label==feedback_label and not compact_layout) else Color("241f19"))
	for button in controls.values():
		for font_state in ["font_color","font_hover_color","font_focus_color","font_pressed_color","font_hover_pressed_color"]: button.add_theme_color_override(font_state,Color("86dcff") if dark else Color("201d19"))
		for state in ["normal","hover","pressed","focus","disabled"]:
			var style: StyleBoxFlat=button.get_theme_stylebox(state)
			style.bg_color=(Color("26343e") if state in ["hover","pressed"] else Color("1b2126")) if dark else (Color("e9ddc5") if state in ["hover","pressed"] else Color("ffffff"))
			style.border_color=Color("75e4ff") if dark else Color("5a4932")
func _process(_delta: float) -> void: refresh()
func dismiss(reason: String="dismissed") -> void:
	if not active: return
	active=false;hide();_finish_close.call_deferred(reason)
func _finish_close(reason: String) -> void:
	if is_inside_tree(): closed.emit(reason)
func _input(event: InputEvent) -> void:
	if not active or not event is InputEventKey: return
	if kind=="drink" and not event.pressed and event.keycode in [KEY_SPACE,KEY_ENTER,KEY_KP_ENTER]:
		get_viewport().set_input_as_handled();return
	if not event.pressed: return
	if event.keycode==KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if not event.echo: dismiss()
		return
	if kind!="drink": return
	if event.keycode not in [KEY_LEFT,KEY_A,KEY_RIGHT,KEY_D,KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]: return
	get_viewport().set_input_as_handled()
	if event.keycode in [KEY_LEFT,KEY_A]: _select(0)
	elif event.keycode in [KEY_RIGHT,KEY_D]: _select(1)
	elif not event.echo:
		var focused: Control=get_viewport().gui_get_focus_owner()
		if focused==controls.cancel: selection=1
		elif focused==controls.take: selection=0
		if selection==0: _take()
		else: dismiss()
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag: accept_event()
func _draw() -> void:
	if not active: return
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.01,0.025,0.04,.82))
	var light_menu: bool=kind=="menu" and read_state.call().native.mode=="light"
	draw_rect(board,Color("f7f4ea") if light_menu else Color("07131d"));draw_rect(board,Color("5a4932") if light_menu else Color("63d4ef"),false,3)
	if kind=="drink":
		var p: Vector2=illustration.position
		draw_rect(Rect2(p+Vector2(9,16),Vector2(50,92)),DRINKS[item_id].accent)
		draw_rect(Rect2(p+Vector2(17,32),Vector2(34,66)),DRINKS[item_id].color)
		draw_rect(Rect2(p+Vector2(25,4),Vector2(18,12)),Color("f0cb59"))
		draw_rect(Rect2(p+Vector2(9,16),Vector2(50,92)),Color("142c3b"),false,4)
	elif kind=="bike":
		var c: Dictionary=read_state.call().canteenHunt;var dark: bool=read_state.call().native.mode=="dark"
		var p: Vector2=illustration.position
		draw_arc(p+Vector2(48,30),25,PI,TAU,24,Color("9db1ba"),8)
		draw_rect(Rect2(p+Vector2(12,30),Vector2(72,58)),Color("3a515c"));draw_rect(Rect2(p+Vector2(12,30),Vector2(72,58)),Color("80bfd3"),false,3)
		# Abstract code-edge impression from source, never an invented code answer.
		draw_rect(Rect2(p+Vector2(32,40),Vector2(32,32)),Color("d8e8df"),false,4)
		if dark: draw_rect(Rect2(p+Vector2(28,36),Vector2(40,40)),Color("4bc9ff"),false,3)
		elif not c.bikeLockCleaned: draw_line(p+Vector2(27,43),p+Vector2(72,63),Color("ffffff"),14)
		if c.bikePaid: draw_line(p+Vector2(36,58),p+Vector2(45,68),Color("8de9ad"),4);draw_line(p+Vector2(45,68),p+Vector2(63,46),Color("8de9ad"),4)
