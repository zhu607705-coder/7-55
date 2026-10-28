extends RefCounted
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const Type=preload("res://scripts/ui/native_typography.gd")
const Account=preload("res://scripts/chapters/campus_network_account.gd")
var copy: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/campus-services-copy.json"))
var language_copy: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/language-examples.json"))
var network_reason=""
var network_feedback=""
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
		draw_string(font,Vector2(50,38),"f(x) = x²",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("f3f1dc"))
		draw_string(font,Vector2(50,63),"f′(x) = 2x",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("f3f1dc"))
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
	search.clear_button_enabled=true;search.custom_minimum_size.y=44;search.max_length=64;Type.apply_body(search)
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

func classroom(b,list: Control) -> void:
	var c: Dictionary=copy.classroom
	var current=b.s.actOne.phase=="prologue"
	var signed=bool(b.s.flags.checkinDone)
	var column=card(list)
	label(column,c.course_name,21)
	label(column,c.teacher+" · "+c.time_and_venue,13)
	var image=Classroom.new();image.name="SmartClassroomScene";image.custom_minimum_size.y=182;image.reduced=b.s.native.get("settings",{}).get("reduced_motion",false);column.add_child(image)
	label(column,c.board_content_current if current else c.board_content_replay,13).name="SmartClassroomStatus"
	button(column,c.tab_board,"SmartClassroomBoard",func():
		b.zjuding_detail="" if b.zjuding_detail=="board" else "board";b.action_requested.emit("phone_refresh",{}))
	if b.zjuding_detail=="board":
		label(column,"f(x) = x²\nf′(x) = 2x",27,Color("3c6752"))
	var attendance=card(list)
	label(attendance,c.tab_activities,18)
	label(attendance,c.status_signed if signed else c.status_not_signed if current else c.status_finished,15).name="SmartClassroomAttendance"
	button(attendance,c.method_code_btn,"SmartClassroomCode",func():
		if current and not signed:b.checkin_return="smart_classroom";b.page_requested.emit("checkin")
		else:b.zjuding_detail="record";b.action_requested.emit("phone_refresh",{}))
	var radar=Radar.new();radar.name="SmartClassroomRadar";radar.custom_minimum_size.y=140;radar.reduced=b.s.native.get("settings",{}).get("reduced_motion",false)
	var trigger=button(attendance,c.method_radar_btn,"SmartClassroomScan",func():pass)
	attendance.add_child(radar);radar.visible=false
	var result=label(attendance,c.status_signed if signed else c.status_finished if not current else c.status_not_signed,14)
	result.name="SmartClassroomRadarResult";result.visible=false
	trigger.pressed.connect(func():
		radar.visible=true;result.visible=true
		reveal_result(result)
		if not current or signed:result.text=c.status_signed if signed else c.status_finished;return
		trigger.disabled=true;result.text=c.radar_scanning
		radar.begin(func():result.text=c.radar_failed_reason;trigger.disabled=false;reveal_result(result)))
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
		var before=Account.account(b.s)
		network_feedback=c.notice_already_processed if before.resolved else c.notice_unviewed if not before.bill_seen or not before.receipt_seen else c.notice_wrong_reason if network_reason!="duplicate_billing" else c.notice_success
		b.action_requested.emit("phone_network_review",network_reason))
	if not network_feedback.is_empty():label(review,network_feedback,14).name="NetworkReviewResult"
	button(list,"打开控制中心切换网络","ZjudingNetworkControls",func():b.page_requested.emit("control_center"))
