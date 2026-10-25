extends RefCounted
## Native sport-app composition. Only navigation lives here; accepted entry,
## digit pickup, exercise and saved facts remain controller-owned.
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const Typography=preload("res://scripts/ui/native_typography.gd")
const Seven=preload("res://scripts/ui/tiyi_seven_art.gd")
# Darker sport colors keep white labels readable after hover/press tinting.
const BLUE=Color("1a63ad")
const GREEN=Color("256b43")
const INK=Color("23344b")
const MUTED=Color("596b7d")
const BACKGROUND=Color("f2f5f8")
const LINE=Color("dbe3ec")
const TITLES={"settings":"锻炼设置","standards":"考核标准","records":"锻炼记录","history":"历年考核数据"}
var detail=""
var owner: Dictionary={}
var copy: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/tiyi-interface-copy.json"))

class Runner extends Control:
	## One bounded silhouette in an 80-unit drawing, with a uniform transform.
	## No independently rotated children can escape the 48px launcher frame.
	var ink=Color.WHITE
	const LIMBS=[
		[Vector2(42,28),Vector2(51,32),Vector2(45,49),Vector2(34,44)],
		[Vector2(43,30),Vector2(32,27),Vector2(22,38),Vector2(27,43),Vector2(35,34),Vector2(41,37)],
		[Vector2(49,32),Vector2(56,39),Vector2(67,38),Vector2(68,44),Vector2(53,47),Vector2(44,39)],
		[Vector2(37,43),Vector2(45,49),Vector2(34,59),Vector2(22,64),Vector2(19,58),Vector2(30,53)],
		[Vector2(44,45),Vector2(51,51),Vector2(53,62),Vector2(65,65),Vector2(63,71),Vector2(47,67),Vector2(42,55),Vector2(36,52)]
	]
	func _init() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var factor=minf(size.x,size.y)/80.0
		var origin=(size-Vector2(80,80)*factor)/2
		draw_set_transform(origin,0,Vector2.ONE*factor)
		draw_circle(Vector2(50,18),6,ink)
		for polygon in LIMBS: draw_colored_polygon(PackedVector2Array(polygon),ink)

class MenuMark extends Control:
	var kind=""
	func _init() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var color=Color("1a63ad")
		match kind:
			"chevron":draw_polyline(PackedVector2Array([Vector2(8,6),Vector2(14,12),Vector2(8,18)]),Color("596b7d"),2)
			"settings":
				for row in range(3):
					draw_line(Vector2(2,5+row*7),Vector2(22,5+row*7),color,2)
					draw_rect(Rect2(6 if row%2==0 else 14,2+row*7,4,6),color)
			"standards":
				draw_rect(Rect2(4,3,16,20),color,false,2)
				draw_rect(Rect2(9,1,6,4),color)
				for y in [10,15,20]: draw_line(Vector2(8,y),Vector2(16,y),color,2)
			"records":
				draw_arc(Vector2(12,12),10,0,TAU,32,color,2)
				draw_polyline(PackedVector2Array([Vector2(12,5),Vector2(12,12),Vector2(18,15)]),color,2)
			"history":
				draw_polyline(PackedVector2Array([Vector2(3,2),Vector2(3,22),Vector2(23,22)]),color,2)
				for i in range(3): draw_rect(Rect2(7+i*6,15-i*5,3,6+i*5),color)

static func add_runner(parent: Control, rect: Rect2) -> Control:
	var icon=Runner.new();icon.name="TiyiRunner";icon.position=rect.position;icon.size=rect.size
	parent.add_child(icon)
	return icon

func route(state: Dictionary,page: String) -> void:
	if not is_same(owner,state): owner=state;detail=""
	if page not in ["tiyi","control_center"]: detail=""

func _font(b, value: int) -> int:
	return roundi(value*clampf(float(b.s.get("native",{}).get("settings",{}).get("text_scale",1.0)),.85,1.35))

func _text(b,parent: Control,text: String,size: int=17,color: Color=INK) -> Label:
	var label=Label.new();Typography.apply_body(label);label.text=text
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size",_font(b,size));label.add_theme_color_override("font_color",color)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(label)
	return label

func _card(parent: Control) -> VBoxContainer:
	var frame=PanelContainer.new();frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var style=StyleBoxFlat.new();style.bg_color=Color.WHITE;style.border_color=LINE;style.set_border_width_all(1);style.set_corner_radius_all(8)
	style.content_margin_left=18;style.content_margin_right=18;style.content_margin_top=18;style.content_margin_bottom=18
	frame.add_theme_stylebox_override("panel",style);parent.add_child(frame)
	var column=VBoxContainer.new();column.add_theme_constant_override("separation",12);frame.add_child(column)
	return column

func _column(b,root: Control) -> VBoxContainer:
	var scroll=ScrollContainer.new();scroll.name="TiyiScroll";scroll.position=Vector2(0,54);scroll.size=Vector2(378,b.APP_HEIGHT-54)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;root.add_child(scroll)
	var margin=MarginContainer.new();margin.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(margin)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,18)
	var column=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",18);margin.add_child(column)
	return column

func _button(b,parent: Control,text: String,id: String,callback: Callable,primary: bool=false) -> Button:
	var button=Button.new();Typography.apply_body(button);button.name=id;button.text=text
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;button.custom_minimum_size.y=52;button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	Ui.apply_button(button,BLUE if primary else Color.WHITE,Color.WHITE if primary else INK,BLUE if primary else LINE,7,1,_font(b,17),Vector2(16,14))
	button.pressed.connect(callback);parent.add_child(button)
	return button

func _refresh(b) -> void: b.action_requested.emit("phone_refresh",null)

func build(b) -> Control:
	var root: Control=b._base(BACKGROUND,b.APP_HEIGHT);root.name="TiyiDashboard"
	var in_detail=not detail.is_empty()
	b._header(root,str(TITLES[detail]) if in_detail else "浙大体艺",Color.WHITE,INK,func():
		if in_detail: detail="";_refresh(b)
		else:b.page_requested.emit("phone_home"),"back" if in_detail else "exit","返回浙大体艺" if in_detail else "退出浙大体艺，返回手机主页")
	var column=_column(b,root)
	if in_detail:
		_build_detail(b,column)
		return root
	var hero=HBoxContainer.new();hero.add_theme_constant_override("separation",14);column.add_child(hero)
	var tile=Panel.new();tile.custom_minimum_size=Vector2(52,52);tile.size_flags_vertical=Control.SIZE_SHRINK_CENTER;tile.add_theme_stylebox_override("panel",b._style(BLUE,Color.TRANSPARENT,8));hero.add_child(tile)
	add_runner(tile,Rect2(2,2,48,48))
	var title_column=VBoxContainer.new();title_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title_column.size_flags_vertical=Control.SIZE_SHRINK_CENTER;hero.add_child(title_column)
	_text(b,title_column,"课外锻炼",23)
	_text(b,title_column,"本学期",14,MUTED)
	var stats=_card(column);stats.name="TiyiStats"
	_text(b,stats,"本学期纳入考核的数据",16,MUTED)
	var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);stats.add_child(row)
	var count=Control.new();count.name="TiyiCountObject";count.custom_minimum_size=Vector2(94,60);row.add_child(count)
	var plate=TextureRect.new();plate.name="TiyiSourcePlate";plate.texture=Seven.count_texture();plate.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	plate.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;plate.size=Vector2(94,60);plate.mouse_filter=Control.MOUSE_FILTER_IGNORE;count.add_child(plate)
	Seven.style_count(plate,bool(b.s.flags.tiyiCountTaken))
	if b.s.actOne.phase=="prologue":
		if not b.s.flags.tiyiCountTaken:Seven.bind_source(count,plate)
		var target: Button=b._act(count,"",Rect2(0,0,94,60),"c1_tiyi_digit",null,Color.TRANSPARENT,INK,0,Color.TRANSPARENT)
		target.name="TiyiCount47";target.tooltip_text="原记录47次，数字7已记下" if b.s.flags.tiyiCountTaken else "运动打卡次数 47"
		for mode in ["normal","hover","pressed"]:target.add_theme_stylebox_override(mode,b._style(Color.TRANSPARENT))
	var unit=_text(b,row,"次",18,MUTED);unit.size_flags_vertical=Control.SIZE_SHRINK_END
	_text(b,stats,"评分次数",15,INK)
	var menu=VBoxContainer.new();menu.name="TiyiMenu";menu.add_theme_constant_override("separation",0);column.add_child(menu)
	for id in TITLES:
		var selected: String=id
		var button=_button(b,menu,TITLES[id],"TiyiMenu_"+id,func():detail=selected;_refresh(b))
		button.alignment=HORIZONTAL_ALIGNMENT_LEFT
		for mode in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
			var style: StyleBoxFlat=button.get_theme_stylebox(mode).duplicate();style.content_margin_left=54;style.content_margin_right=32;style.set_corner_radius_all(0)
			button.add_theme_stylebox_override(mode,style)
		var mark=MenuMark.new();mark.kind=id;mark.position=Vector2(15,15);mark.size=Vector2(24,24);button.add_child(mark)
		var chevron=MenuMark.new();chevron.kind="chevron";chevron.size=Vector2(24,24);button.add_child(chevron)
		button.resized.connect(func():mark.position.y=(button.size.y-24)/2;chevron.position=Vector2(button.size.x-30,(button.size.y-24)/2))
	if b.s.actOne.phase in ["movement_required","reservation_briefing_required","reservation_required","movement_ready"] and b.s.ui.libraryFinalsPhase=="idle":
		var exercise=_button(b,column,"","TiyiExercise",func():b.action_requested.emit("c2_exercise",null),true)
		b.handled.append("c2_exercise");exercise.disabled=b.s.actOne.exerciseStarted;style_exercise(exercise,b.s.actOne.exerciseStarted)
		var margin=MarginContainer.new();margin.mouse_filter=Control.MOUSE_FILTER_IGNORE;exercise.add_child(margin)
		for side in ["left","right"]:margin.add_theme_constant_override("margin_"+side,16)
		for side in ["top","bottom"]:margin.add_theme_constant_override("margin_"+side,14)
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var labels=VBoxContainer.new();labels.mouse_filter=Control.MOUSE_FILTER_IGNORE;labels.add_theme_constant_override("separation",8);margin.add_child(labels)
		_text(b,labels,"课外锻炼进行中" if b.s.actOne.exerciseStarted else "开始虚拟定位",18,Color.WHITE).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		if not b.s.actOne.exerciseStarted:_text(b,labels,"10 分钟跑完 3 km · 点击生成轨迹" if b.s.actOne.characterNamed else "请先在部门黄页确认参加者",14,Color.WHITE).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var fit=func():exercise.custom_minimum_size.y=maxf(56,margin.get_combined_minimum_size().y)
		labels.minimum_size_changed.connect(fit);margin.resized.connect(fit);root.ready.connect(fit)
	return root

func _build_detail(b,parent: Control) -> void:
	var card=_card(parent)
	match detail:
		"settings":
			_text(b,card,"网络",14,MUTED)
			_text(b,card,{"cellular":"移动数据","campus_wifi":"校园网","offline":"离线"}.get(b.s.networkMode,"离线"),22)
			_text(b,card,"参加者",14,MUTED)
			_text(b,card,"林星宇" if b.s.actOne.characterNamed else "请先在部门黄页确认参加者",17)
			_text(b,card,copy.settings_note,16,MUTED)
			_button(b,parent,"控制中心","TiyiOpenControlCenter",func():b.page_requested.emit("control_center"))
		"standards":
			_text(b,card,"本学期纳入考核的数据",18)
			var movement=b.s.actOne.phase in ["movement_required","reservation_briefing_required","reservation_required","movement_ready"]
			_text(b,card,"10 分钟跑完 3 km · 点击生成轨迹" if movement else copy.standards_empty,17,MUTED)
		"records":
			_text(b,card,"评分次数",16,MUTED);_text(b,card,"47 次",30)
			_text(b,card,copy.records_note,17,MUTED)
			if b.s.actOne.exerciseStarted:_text(b,card,"课外锻炼进行中",17,GREEN)
		"history":_text(b,card,copy.history_empty,17,MUTED)

static func loading(b,root: Control) -> void:
	var y: float=b.APP_HEIGHT*.32
	var tile: Control=b._panel(root,Rect2(141,y,96,96),BLUE,Color.TRANSPARENT,16)
	add_runner(tile,Rect2(8,8,80,80))
	b._label(root,"浙大体艺",Rect2(39,y+118,300,42),25,INK,HORIZONTAL_ALIGNMENT_CENTER).name="TiyiLoadingTitle"
	b._label(root,"课外锻炼",Rect2(39,y+164,300,30),16,MUTED,HORIZONTAL_ALIGNMENT_CENTER)

static func style_exit(button: Button) -> void:
	Ui.apply_button(button,Color("f4f8ff"),Color("23599d"),Color("a9c9ef"),8,1,30,Vector2.ZERO,Color("174d9d"))
static func style_exercise(button: Button,started: bool) -> void:
	Ui.apply_button(button,GREEN if started else BLUE,Color.WHITE,Color("287448") if started else Color("194f8d"),8,1,18,Vector2.ZERO,Color("174d9d"))
	# The disabled running card is status, so its authored white labels retain
	# contrast. All child labels already explicitly own that same ink color.
	button.add_theme_color_override("font_disabled_color",Color.WHITE)
