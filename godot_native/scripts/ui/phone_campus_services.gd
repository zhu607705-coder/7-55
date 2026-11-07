extends RefCounted
const Notice=preload("res://scripts/ui/native_phone_notice.gd")
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const Type=preload("res://scripts/ui/native_typography.gd")
const Account=preload("res://scripts/chapters/campus_network_account.gd")
var copy: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/campus-services-copy.json"))
var language_copy: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/language-examples.json"))
var network_reason=""
var network_feedback=""
var network_feedback_pending=false
var scale=1.0

class Classroom extends Control:
	var time=0.0
	var reduced=false
	func _ready() -> void: mouse_filter=MOUSE_FILTER_IGNORE
	func _process(delta: float) -> void:
		if not reduced:time+=delta;queue_redraw()
	func _draw() -> void:
		var fit=minf(size.x/320,size.y/182)
		draw_set_transform((size-Vector2(320,182)*fit)/2,0,Vector2.ONE*fit)
		draw_rect(Rect2(0,0,320,182),Color("e8e5db"))
		draw_rect(Rect2(32,12,256,70),Color("455c51"));draw_rect(Rect2(32,12,256,70),Color("bcab87"),false,4)
		var font=Type.body_font()
		draw_string(font,Vector2(50,38),"f(x) = x²e²ˣ + ln(1+x³)",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("f3f1dc"))
		draw_string(font,Vector2(50,63),"f⁽⁶⁾(0) = ?",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("f3f1dc"))
		draw_line(Vector2(212,68),Vector2(212,25),Color("d2dccd"),1,true);draw_line(Vector2(195,63),Vector2(264,63),Color("d2dccd"),1,true)
		var curve=PackedVector2Array()
		for x in range(-17,37):curve.append(Vector2(212+x,62-x*x*.025))
		draw_polyline(curve,Color("f1df9d"),1.5,true)
		for y in [111,155]:
			for x in [35,106,177,248]:
				draw_rect(Rect2(x,y,39,18),Color("aa8e6a"));draw_rect(Rect2(x+4,y+3,31,11),Color("e7d8b7"))
				draw_circle(Vector2(x+19,y+23),7,Color("4d626f"))
		var teacher=Vector2(174+sin(time*.6)*7,88)
		draw_rect(Rect2(teacher+Vector2(-8,3),Vector2(16,23)),Color("64717a"));draw_circle(teacher,7,Color("c6a98b"))
		draw_line(teacher+Vector2(6,9),Vector2(200,57+sin(time)*4),Color("c6a98b"),4,true)

class Radar extends Control:
	var elapsed=0.0
	var active=false
	var reduced=false
	var finished: Callable
	func _init() -> void:mouse_filter=MOUSE_FILTER_IGNORE
	func begin(callback: Callable) -> void:elapsed=0;active=true;finished=callback;queue_redraw()
	func _process(delta: float) -> void:
		if not active:return
		elapsed+=minf(delta,.1);queue_redraw()
		if elapsed>=2:
			active=false;finished.call();queue_redraw()
	func _draw() -> void:
		var c=size/2
		for r in [20.0,40.0,60.0]:draw_arc(c,r,0,TAU,48,Color("b8d7e2"),1.2,true)
		draw_circle(c,5,Color("277bb5"))
		draw_circle(c+Vector2(78,-15),6,Color("bf7b54"))
		if active:
			var ray=Vector2.from_angle(-PI/2 if reduced else elapsed*TAU)*60
			draw_line(c,c+ray,Color("268d9a"),2,true)
		else:draw_line(c,c+Vector2(58,-11),Color("aabcc5"),1,true)

func flow(body: Control) -> VBoxContainer:
	var list=VBoxContainer.new();list.position=Vector2(13,12);list.size.x=352;list.add_theme_constant_override("separation",12);body.add_child(list)
	list.minimum_size_changed.connect(func():body.custom_minimum_size.y=maxf(560,list.get_combined_minimum_size().y+24);body.size.y=body.custom_minimum_size.y)
	return list

func card(parent: Control,color: Color=Color.WHITE) -> VBoxContainer:
	var panel=PanelContainer.new();panel.mouse_filter=Control.MOUSE_FILTER_PASS;panel.add_theme_stylebox_override("panel",Ui.box(color,Color("dbe3ed"),1,10));parent.add_child(panel)
	var margin=MarginContainer.new();panel.add_child(margin)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,14)
	var column=VBoxContainer.new();column.add_theme_constant_override("separation",9);margin.add_child(column)
	return column

func label(parent: Control,text: String,font_size: int=15,color: Color=Color("263d56")) -> Label:
	var node=Label.new();Type.apply_body(node);node.text=text;node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_size_override("font_size",roundi(font_size*scale));node.add_theme_color_override("font_color",color);parent.add_child(node);return node

func button(parent: Control,text: String,name: String,callback: Callable) -> Button:
	var node=Button.new();node.name=name;node.text=text;node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;Type.apply_body(node)
	node.mouse_filter=Control.MOUSE_FILTER_PASS
	Ui.apply_button(node,Color("edf3fb"),Color("1754a0"),Color("c4d5eb"),7,1,roundi(15*scale),Vector2(12,10))
	node.custom_minimum_size.y=44;parent.add_child(node);node.pressed.connect(callback);return node

func reveal_result(result: Control) -> void:
	# Nested containers need their layout pass before the scroll range is final.
	var tree=result.get_tree()
	for frame in range(2):
		await tree.process_frame
		if not is_instance_valid(result):return
	var scroll=result.find_parent("ZjudingScroll")
	if scroll:scroll.ensure_control_visible(result)

func build(b,body: Control,page: String) -> void:
	scale=clampf(float(b.s.native.get("settings",{}).get("text_scale",1)),.85,1.35)
	var list=flow(body)
	match page:
		"smart_classroom": classroom(b,list)
		"network_account": network(b,list)
		"language_cards": language(b,list)
		"campus_map":
			var column=card(list)
			label(column,copy.ding_map.current_location_label,12)
			label(column,copy.ding_map.current_location_val,24)
			label(column,copy.ding_map.status_desc)
			button(column,copy.ding_map.btn_refresh,"ZjudingMapRefresh",func():b._zju_open("campus_map"))
			button(column,"返回浙大钉","ZjudingMapBack",b._zju_back)

func language(b,list: Control) -> void:
	# Optional reading only: no evidence, reward, or chapter-state writes.
	label(list,language_copy.ui.title,23)
	label(list,language_copy.ui.subtitle,13,Color("60728a"))
	var search=LineEdit.new();search.name="LanguageSearch";search.placeholder_text=language_copy.ui.search_placeholder
	search.clear_button_enabled=true;search.custom_minimum_size.y=44
	Type.apply_body(search)
	Ui.apply_input(search,Color.WHITE,Color("344349"),Color("e3e9eb"),20,14,Vector2(12,7));search.max_length=64;Type.apply_body(search)
	Ui.apply_input(search,Color.WHITE,Color("263d56"),Color("c4d5eb"),7,roundi(15*scale),Vector2(12,10))
	list.add_child(search)
	var empty=label(list,language_copy.ui.no_results,15,Color("60728a"));empty.name="LanguageNoResults";empty.visible=false
	var cards: Dictionary={}
	var translations: Dictionary={}
	var toggles: Dictionary={}
	for entry: Dictionary in language_copy.entries:
		var id: String=entry.id
		var section=card(list)
		section.name="LanguageCard_"+id
		cards[id]=section.get_parent().get_parent()
		label(section,entry.word,24)
		label(section,entry.meaning,13,Color("60728a"))
		label(section,entry.example_en,17).name="LanguageExample_"+id
		var translation=label(section,entry.example_zh,16)
		translation.name="LanguageTranslation_"+id
		translation.visible=b.zjuding_detail==id
		translations[id]=translation
		var toggle=button(section,language_copy.ui.hide_translation if translation.visible else language_copy.ui.show_translation,"ZjudingWord_"+id,func():
			b.zjuding_detail="" if b.zjuding_detail==id else id
			for key: String in translations:
				translations[key].visible=b.zjuding_detail==key
				toggles[key].text=language_copy.ui.hide_translation if translations[key].visible else language_copy.ui.show_translation
			if translation.visible:reveal_result(translation))
		toggles[id]=toggle
	search.text_changed.connect(func(value: String):
		var query=value.strip_edges().to_lower()
		var found=false
		for entry: Dictionary in language_copy.entries:
			var matches=query.is_empty() or (str(entry.word)+" "+str(entry.meaning)).to_lower().contains(query)
			cards[entry.id].visible=matches
			found=found or matches
		empty.visible=not found)

const CLASSROOM_ACCENT := Color("087f90")
const CLASSROOM_DAY := 1793923200 # 2026-11-06 00:00 UTC, in-game calendar reference.

# day, course, teacher, room, start minutes, end minutes, periods, status
const LESSONS := [
	[0,"微积分（甲）","苏老师","紫金港西1-201",480,575,"第1–2节","可回放"],
	[1,"大学英语四","莫老师","紫金港东1-105",600,695,"第3–4节","已结束"],
	[1,"工程图学","严老师","紫金港西2-308",810,1015,"第6–9节","已结束"],
	[2,"线性代数","庄老师","紫金港东2-203",480,575,"第1–2节","已结束"],
	[3,"中国近代史纲要","鲁老师","紫金港西2-101",810,905,"第6–7节","已结束"],
	[4,"微积分（甲）","苏老师","紫金港西1-201",480,575,"第1–2节","上课中"],
]
const SLIDES := [
	["00:01:15","高阶导数与泰勒展开","乘积与复合函数的高阶求导\n莱布尼茨公式与泰勒级数法\n随堂求解：指定点处的六阶导数"],
	["00:09:30","莱布尼茨与展开公式","(uv)⁽ⁿ⁾ = Σ C(n,k) u⁽ᵏ⁾ v⁽ⁿ⁻ᵏ⁾\nf⁽ⁿ⁾(0) = n! · aₙ\nln(1+u) = u − u²/2 + u³/3 + O(u⁴)"],
	["00:21:10","随堂求解六阶导数值","设 f(x) = x²e²ˣ + ln(1+x³)，求 f⁽⁶⁾(0)。\n乘积项：15 × 2 × 2⁴ = 480。\n对数项：6! × (−1/2) = −360。\n两项相加，得到多少？"],
	["00:38:45","高阶求导方法小结","多项式乘积：用莱布尼茨公式截断零项。\n高次复合：从麦克劳林展开提取系数。\n下节：微分中值定理与洛必达法则。"],
]
const TRANSCRIPT := [
	["00:01:15","同学们好，今天用高阶导数与泰勒公式解决复杂求值问题。"],
	["00:09:30","直接连求六次计算量很大。遇到乘积用莱布尼茨公式，遇到复合可以试试泰勒展开。"],
	["00:15:40","零点的 n 阶导数，等于麦克劳林展开中 x 的 n 次方项的系数乘以 n 的阶乘。"],
	["00:21:10","来看随堂题，计算这个函数在零点的六阶导数。"],
	["00:26:50","第一项在零点只剩 k 等于 2 的一项，算出来是 480。"],
	["00:32:15","把 x 三次方代入对数展开，六次方项系数是负二分之一，乘上六的阶乘得到负 360。"],
	["00:38:45","两部分相加，480 减去 360 等于 120，这就是随堂题的答案。"],
	["00:43:20","课后请再推导一遍两种方法。下节课进入微分中值定理。"],
]
var classroom_lesson: int = 0

func _lesson_time(minutes: int) -> String:
	return "%02d:%02d" % [minutes / 60, minutes % 60]

func _open_lesson(b, index: int, origin: String) -> void:
	classroom_lesson=index
	classroom_origin=origin
	classroom_slide=0
	_classroom_refresh(b,"class_ppt" if LESSONS[index][7]=="可回放" else "class_info")

func _classroom_refresh(b, detail: String) -> void:
	b.zjuding_detail=detail
	b.action_requested.emit("phone_refresh",{})

func _classroom_tabs(parent: Control, titles: Array, selected: int, choose: Callable) -> void:
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation",0)
	parent.add_child(tabs)
	for index in titles.size():
		var tab := button(tabs,titles[index],"SmartClassroomTab_%d" % index,choose.bind(index))
		tab.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		Ui.apply_button(tab,Color.WHITE,CLASSROOM_ACCENT if selected==index else Color("242b30"),Color.TRANSPARENT,0,0,roundi(14*scale),Vector2(5,8))
		tab.toggle_mode=true
		tab.set_pressed_no_signal(selected==index)
		if selected==index:
			var indicator:=ColorRect.new()
			indicator.color=Color("06aabd")
			indicator.mouse_filter=Control.MOUSE_FILTER_IGNORE
			tab.add_child(indicator)
			indicator.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
			indicator.offset_left=-11;indicator.offset_right=11;indicator.offset_top=-3

func classroom(b,list: Control) -> void:
	if b.zjuding_detail in ["class_info","class_speech","class_ppt","record","board"]:
		_classroom_detail(b,list)
		return
	list.position=Vector2.ZERO
	list.size.x=378
	list.add_theme_constant_override("separation",0)
	var hero:=Control.new()
	hero.custom_minimum_size.y=108
	list.add_child(hero)
	b._panel(hero,Rect2(0,0,378,108),Color("00a8bd"))
	var wave:=Polygon2D.new()
	wave.color=Color("09b5c7")
	wave.polygon=PackedVector2Array([Vector2(155,108),Vector2(286,49),Vector2(335,40),Vector2(378,49),Vector2(378,108)])
	hero.add_child(wave)
	b._label(hero,"智云课堂",Rect2(18,18,207,42),27,Color.WHITE)
	b._label(hero,"课程直播与随堂回放",Rect2(18,65,318,26),14,Color.WHITE)
	var all_courses: bool=b.zjuding_detail=="class_all"
	for index in 3:
		var shortcut: Button=b._button(hero,["⌕","▦","●"][index],Rect2(231+index*43,23,38,36),func():
			match index:
				0: _classroom_refresh(b,"class_all")
				1: _classroom_refresh(b,"")
				2: b._zju_open("profile")
		,Color("00a8bd"),Color.WHITE,0,Color.TRANSPARENT)
		shortcut.tooltip_text=["查找课程","我的课程","校园身份"][index]
	_classroom_tabs(list,["全部课程","我的课程"],0 if all_courses else 1,func(index: int):
		_classroom_refresh(b,"class_all" if index==0 else ""))
	if all_courses: _classroom_catalog(b,list)
	else: _classroom_schedule(b,list)

var classroom_week: int = 0
var classroom_day: int = 0
var classroom_origin: String = ""

func _classroom_date(unix_time: int) -> String:
	var d:=Time.get_datetime_dict_from_unix_time(unix_time)
	return "%02d/%02d" % [d.month,d.day]

func _classroom_calendar(b,list: Control,weekly: bool) -> void:
	var bar:=HBoxContainer.new()
	list.add_child(bar)
	var day_offset:=classroom_week*7-4 if weekly else classroom_day
	var start:=CLASSROOM_DAY+day_offset*86400
	var date_text:=_classroom_date(start)+"–"+_classroom_date(start+6*86400) if weekly else Time.get_date_string_from_unix_time(start)
	var back:=button(bar,"上一周" if weekly else "前一天","SmartClassroomPrevious",func():
		if weekly: classroom_week-=1
		else: classroom_day-=1
		_classroom_refresh(b,"" if weekly else "class_all"))
	var date:=label(bar,date_text,16,CLASSROOM_ACCENT)
	date.autowrap_mode=TextServer.AUTOWRAP_OFF
	date.size_flags_horizontal=Control.SIZE_EXPAND_FILL;date.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var forward:=button(bar,"下一周" if weekly else "后一天","SmartClassroomNext",func():
		if weekly: classroom_week+=1
		else: classroom_day+=1
		_classroom_refresh(b,"" if weekly else "class_all"))
	for control in [back,forward]:
		control.custom_minimum_size.x=70
		Ui.apply_button(control,Color("f6f7f8"),Color("41474a"),Color.TRANSPARENT,0,0,14,Vector2(9,6))

func _classroom_schedule(b,list: Control) -> void:
	_classroom_calendar(b,list,true)
	var horizontal:=ScrollContainer.new()
	horizontal.custom_minimum_size.y=1002
	horizontal.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	horizontal.name="SmartClassroomWeekGrid"
	list.add_child(horizontal)
	var grid:=Control.new()
	grid.custom_minimum_size=Vector2(44+7*82,990)
	grid.mouse_filter=Control.MOUSE_FILTER_PASS
	horizontal.add_child(grid)
	b._panel(grid,Rect2(Vector2.ZERO,grid.custom_minimum_size),Color.WHITE).mouse_filter=Control.MOUSE_FILTER_IGNORE
	var monday:=CLASSROOM_DAY+(classroom_week*7-4)*86400
	b._label(grid,"%d月" % Time.get_datetime_dict_from_unix_time(monday).month,Rect2(4,0,40,46),13)
	for index in 7:
		var date:=Time.get_datetime_dict_from_unix_time(monday+index*86400)
		b._label(grid,"周%s %02d" % [["一","二","三","四","五","六","日"][index],date.day],Rect2(44+index*82,0,82,46),13,Color("252b30"),HORIZONTAL_ALIGNMENT_CENTER)
	for hour in range(7,18):
		var y:=48+(hour-7)*93
		b._label(grid,"%02d:00" % hour,Rect2(3,y-10,41,22),12)
		b._panel(grid,Rect2(44,y,7*82,1),Color("e8eaec")).mouse_filter=Control.MOUSE_FILTER_IGNORE
	if classroom_week==0:
		for index in LESSONS.size():
			var lesson: Array=LESSONS[index]
			var x: int=46+lesson[0]*82
			var y: float=48+(lesson[4]-420)*93.0/60.0
			var height: float=(lesson[5]-lesson[4])*93.0/60.0
			var fill:=Color("e1f2f8") if lesson[4]<720 else Color("eeebfa")
			b._panel(grid,Rect2(x,y,78,height),fill,Color.TRANSPARENT,5)
			b._label(grid,"%s\n%s\n%s–%s" % [lesson[1],lesson[2],_lesson_time(lesson[4]),_lesson_time(lesson[5])],Rect2(x+5,y+5,68,84),12,Color("243945"))
			var replay: Button=b._button(grid,"查看回放" if lesson[7]=="可回放" else lesson[7],Rect2(x+4,y+height-37,70,32),_open_lesson.bind(b,index,""),fill,CLASSROOM_ACCENT,4,CLASSROOM_ACCENT)
			replay.name="SmartClassroomReplay_%d" % index
			replay.add_theme_font_size_override("font_size",12)
	else:
		b._label(grid,"本周暂无课程",Rect2(54,90,260,32),15,Color("59656c"))

func _classroom_catalog(b,list: Control) -> void:
	var toolbar:=HBoxContainer.new()
	list.add_child(toolbar)
	var search:=LineEdit.new()
	search.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	search.placeholder_text="搜索课程名、教师或教室"
	search.custom_minimum_size.y=44
	Type.apply_body(search)
	Ui.apply_input(search,Color.WHITE,Color("344349"),Color("e3e9eb"),20,14,Vector2(12,7))
	search.name="SmartClassroomSearch"
	toolbar.add_child(search)
	var filter:=OptionButton.new()
	filter.name="SmartClassroomFilter"
	filter.add_item("全部状态")
	filter.add_item("正在上课")
	filter.add_item("包含回放")
	filter.add_item("尚未开始")
	filter.select(0)
	Type.apply_body(filter)
	Ui.apply_button(filter,Color("f5f6f7"),Color("33474b"),Color("e3e9eb"),7,1,14,Vector2(8,6))
	toolbar.add_child(filter)
	_classroom_calendar(b,list,false)
	var groups:=VBoxContainer.new()
	groups.add_theme_constant_override("separation",5)
	list.add_child(groups)
	var rows: Dictionary={}
	for period in 3:
		var section:=card(groups)
		var title:=label(section,["第一时段","第二时段","第三时段"][period],17,[Color("237b9c"),Color("257c64"),Color("a3484e")][period])
		title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		for index in LESSONS.size():
			var lesson: Array=LESSONS[index]
			var slot: int=0 if lesson[4]<600 else 1 if lesson[4]<720 else 2
			if lesson[0]!=classroom_day+4 or slot!=period: continue
			rows[index]=button(section,"%s · %s\n%s · %s · %s" % [lesson[1],lesson[7],lesson[2],lesson[3],lesson[6]],"SmartClassroomCourse" if rows.is_empty() else "SmartClassroomCourse_%d" % index,_open_lesson.bind(b,index,"class_all"))
	var empty:=label(groups,"今日暂无课程安排。",14,Color("59656c"))
	var update:=func(value: String):
		var query:=value.strip_edges().to_lower()
		var status: String=["","上课中","可回放","未开始"][filter.selected]
		var found:=false
		for index in rows:
			var lesson: Array=LESSONS[index]
			var matches: bool=(status.is_empty() or lesson[7]==status) and (query.is_empty() or (lesson[1]+lesson[2]+lesson[3]).to_lower().contains(query))
			rows[index].visible=matches
			found=found or matches
		empty.visible=not found
		empty.text="今日暂无课程安排。" if rows.is_empty() else "未找到匹配的课程。"
	search.text_changed.connect(update)
	filter.item_selected.connect(func(_index: int):update.call(search.text))
	update.call("")

var classroom_slide: int = 0

func _classroom_detail(b,list: Control) -> void:
	var lesson: Array=LESSONS[classroom_lesson]
	button(list,"‹  "+str(lesson[1]),"SmartClassroomCourseBack",func():_classroom_refresh(b,classroom_origin))
	var video:=Classroom.new()
	video.name="SmartClassroomScene"
	video.custom_minimum_size.y=166
	video.reduced=true
	list.add_child(video)
	var keys:=["class_info","class_speech","class_ppt"]
	var tab:=maxi(0,keys.find(b.zjuding_detail))
	_classroom_tabs(list,["课程信息","语音识别","PPT识别"],tab,func(index: int):_classroom_refresh(b,keys[index]))
	var has_replay: bool=lesson[7]=="可回放"
	match tab:
		0:
			label(list,"%s · %s · %s" % [lesson[2],lesson[3],lesson[6]],14)
			if lesson[1]=="微积分（甲）":
				label(list,"本节讲解一元函数高阶导数与泰勒公式，结合莱布尼茨公式和麦克劳林展开，求指定点的高阶导数值。",15)
			if lesson[7]=="上课中": _classroom_attendance(b,list)
		1:
			if not has_replay: label(card(list),"本节课暂无可用的语音识别字幕。",15)
			else:
				for cue in TRANSCRIPT:
					var row:=card(list)
					label(row,cue[0],12,CLASSROOM_ACCENT)
					label(row,cue[1],15)
		2:
			if not has_replay:
				label(card(list),"课堂回放生成中，请课后查看。",15)
				return
			var strip:=HBoxContainer.new()
			list.add_child(strip)
			for index in SLIDES.size():
				var tile:=button(strip,"第 %d 页" % (index+1),"SmartClassroomSlide_%d" % index,func():
					classroom_slide=index
					_classroom_refresh(b,"class_ppt"))
				tile.size_flags_horizontal=Control.SIZE_EXPAND_FILL
				if index==classroom_slide: Ui.apply_button(tile,Color("dff5f7"),CLASSROOM_ACCENT,CLASSROOM_ACCENT,4,1,14,Vector2(6,8))
			var slide:=card(list,Color("eef8fa"))
			label(slide,SLIDES[classroom_slide][0],12,CLASSROOM_ACCENT)
			label(slide,SLIDES[classroom_slide][1],19)
			label(slide,SLIDES[classroom_slide][2],16)

func _classroom_attendance(b,list: Control) -> void:
	var c: Dictionary=copy.classroom
	var current: bool=b.s.actOne.phase=="prologue"
	var signed:=bool(b.s.flags.checkinDone)
	var attendance=card(list)
	label(attendance,c.tab_activities,18)
	label(attendance,"已签到" if signed else "未签到" if current else "签到已关闭",15).name="SmartClassroomAttendance"
	if current and not signed: label(attendance,"教师已发起随堂签到，请选择签到方式。",13)
	button(attendance,c.method_code_btn,"SmartClassroomCode",func():
		if current and not signed:b.checkin_return="smart_classroom";b.page_requested.emit("checkin")
		else:b.zjuding_detail="record";b.action_requested.emit("phone_refresh",{}))
	var radar=Radar.new();radar.name="SmartClassroomRadar";radar.custom_minimum_size.y=140;radar.reduced=b.s.native.get("settings",{}).get("reduced_motion",false)
	var trigger=button(attendance,c.method_radar_btn,"SmartClassroomScan",func():pass)
	attendance.add_child(radar);radar.visible=false
	trigger.pressed.connect(func():
		if not current or signed:
			b.action_requested.emit("smart_classroom_notice","签到成功，已记录本次随堂出勤。" if signed else "当前课程已下课，随堂签到通道已关闭。")
			return
		radar.visible=true
		trigger.disabled=true
		b.action_requested.emit("smart_classroom_notice","正在获取当前位置并检测签到雷达……")
		radar.begin(func():
			b.action_requested.emit("smart_classroom_notice","当前位于寝室区域，超出教室签到有效范围。")
			trigger.disabled=false))
	if b.zjuding_detail=="record":label(attendance,c.status_signed if signed else c.status_finished,15)
	button(attendance,"返回学在浙大","SmartClassroomLearn",func():b._zju_open("learn"))

func network(b,list: Control) -> void:
	var c: Dictionary=copy.network_billing
	var state=Account.account(b.s)
	var top=card(list,Color("eef5ff"))
	label(top,c.current_balance_label,12)
	label(top,"¥0.00" if state.resolved else c.current_balance_val,25)
	label(top,c.notice_success if state.resolved else c.title,14)
	for doc in ["bill","receipt"]:
		var selected=b.zjuding_detail==doc
		var section=card(list)
		button(section,c.bill_detail_title if doc=="bill" else c.receipt_detail_title,"NetworkDocument_"+doc,func():
			b.zjuding_detail="" if selected else doc
			if not selected:b.action_requested.emit("phone_network_document",doc)
			else:b.action_requested.emit("phone_refresh",{}))
		if selected:
			label(section,c.bill_cycle_label+" · "+c.bill_cycle_val,14)
			label(section,c.bill_amount_label+" · "+c.bill_amount_val,20)
			label(section,c.bill_trans_id if doc=="bill" else c.receipt_trans_id,12)
			label(section,c.notice_success if doc=="bill" and state.resolved else c.bill_detail_title if doc=="bill" else c.receipt_detail_title,13)
	var review=card(list)
	label(review,c.appeal_entry_btn,18)
	label(review,c.appeal_reason_prompt,13)
	for reason in c.reason_options:
		var choice=button(review,reason.label,"NetworkReason_"+reason.id,func():network_reason=reason.id;b.action_requested.emit("phone_refresh",{}))
		choice.toggle_mode=true;choice.button_pressed=network_reason==reason.id
	button(review,c.appeal_submit_btn,"NetworkReviewSubmit",func():
		network_feedback_pending=true
		var before=Account.account(b.s)
		network_feedback=c.notice_already_processed if before.resolved else c.notice_unviewed if not before.bill_seen or not before.receipt_seen else c.notice_wrong_reason if network_reason!="duplicate_billing" else c.notice_success
		b.action_requested.emit("phone_network_review",network_reason))
	if not network_feedback.is_empty():
		var result:=label(review,network_feedback,14);result.name="NetworkReviewResult"
		Notice.style_inline(result,"success" if network_feedback in [c.notice_success,c.notice_already_processed] else "warning",roundi(14*scale))
		if network_feedback_pending:
			network_feedback_pending=false
			result.ready.connect(func():reveal_result(result))
	button(list,"打开控制中心切换网络","ZjudingNetworkControls",func():b.page_requested.emit("control_center"))
