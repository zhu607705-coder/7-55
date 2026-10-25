extends RefCounted
## Native learning dashboard. Only the original check-in route changes pages;
## course and notice readers are local presentation, with no story writes.
const Typography=preload("res://scripts/ui/native_typography.gd")
const ART="res://assets/ui/zjuding_home.png"
const INK=Color("203944")
const MUTED=Color("586f7b")
const TEAL=Color("147b91")
const SURFACE=Color("f6f9fb")
const ICON_SURFACE=Color("e5f1f5")
const EDGE=Color("b9ccd5")
const COURSES=[
	["高等数学","快快老师 · 08:00","高等数学（早八特供版）\n快快老师\n紫金港西1-201 · 08:00",Rect2(52,820,350,176)],
	["化学工程基础","周一 · 08:00","化学工程基础\n周一 08:00 · 北教学区 A-204\n课程资料已缓存在本机。",Rect2(446,820,344,176)]
]

class PixelIcon extends Control:
	var kind: String="book"
	func _draw() -> void:
		draw_set_transform(Vector2.ZERO,0,size/Vector2(64,64))
		draw_rect(Rect2(0,0,64,64),Color("e5f1f5"))
		var ink:=Color("246479")
		var paper:=Color("fff9e9")
		if kind=="calendar":
			draw_rect(Rect2(12,14,40,40),ink)
			draw_rect(Rect2(15,24,34,27),paper)
			draw_rect(Rect2(19,9,5,13),ink);draw_rect(Rect2(40,9,5,13),ink)
			for rect in [Rect2(21,31,8,4),Rect2(35,31,8,4),Rect2(21,41,8,4),Rect2(35,41,8,4)]:draw_rect(rect,ink)
		elif kind=="bell":
			draw_rect(Rect2(28,10,8,5),ink);draw_rect(Rect2(22,15,20,6),ink)
			draw_rect(Rect2(17,21,30,22),ink);draw_rect(Rect2(13,43,38,5),ink)
			draw_rect(Rect2(22,22,20,20),paper);draw_rect(Rect2(28,52,8,4),ink)
		elif kind=="person":
			draw_rect(Rect2(23,10,18,19),ink);draw_rect(Rect2(27,14,10,11),paper)
			draw_rect(Rect2(18,35,28,7),ink);draw_rect(Rect2(13,42,38,13),ink)
			draw_rect(Rect2(18,45,28,6),paper)
		else:
			# A bound attendance register and an ink stamp, never a success badge.
			draw_rect(Rect2(10,11,38,43),ink);draw_rect(Rect2(14,14,31,36),paper)
			draw_rect(Rect2(18,14,3,36),Color("b1c5cb"))
			for y in [22,29,36]:draw_rect(Rect2(25,y,14,2),Color("78949e"))
			draw_rect(Rect2(37,44,19,9),Color("a24d4c"));draw_rect(Rect2(41,33,11,13),Color("c76c62"))
			draw_rect(Rect2(39,31,15,5),Color("a24d4c"));draw_rect(Rect2(37,55,19,3),Color("c76c62"))

func _icon(parent: Control,kind: String,rect: Rect2) -> void:
	var icon:=PixelIcon.new();icon.name="LearnIcon_"+kind;icon.kind=kind
	icon.position=rect.position;icon.size=rect.size;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)

func _art(parent: Control,region: Rect2,rect: Rect2,name: String) -> void:
	var atlas:=AtlasTexture.new();atlas.atlas=load(ART);atlas.region=region;atlas.filter_clip=true
	var image:=TextureRect.new();image.name=name
	# Disable texture-derived minimum size before assigning the atlas. Setting
	# size first lets the original region enlarge the Control until another fit.
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;image.clip_contents=true
	image.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;image.texture=atlas
	image.position=rect.position;image.size=rect.size
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(image)

func _reader(b,root: Control,title: String,body: String,course: bool=false) -> void:
	if root.get_node_or_null("LearnReader")!=null:return
	var cover:=Control.new();cover.name="LearnReader";cover.position=Vector2.ZERO;cover.size=root.size
	cover.mouse_filter=Control.MOUSE_FILTER_STOP;cover.z_index=20;root.add_child(cover)
	b._panel(cover,Rect2(Vector2.ZERO,root.size),Color("203944",.28))
	b._panel(cover,Rect2(18,132,342,386),SURFACE,EDGE,0,2)
	var close: Button=b._nav(cover,"back","返回学在浙大",func():cover.queue_free(),Rect2(25,140,40,44),SURFACE,INK)
	close.name="LearnReaderBack";close.set_meta("phone_nav_kind","close")
	b._label(cover,title,Rect2(71,141,263,42),19,INK).name="LearnReaderTitle"
	b._panel(cover,Rect2(37,192,304,2),EDGE)
	var text: Label=b._label(cover,body,Rect2(37,207,304,115),16,INK)
	text.name="LearnReaderBody"
	text.vertical_alignment=VERTICAL_ALIGNMENT_TOP
	var done: Button=b._button(cover,"返回课程",Rect2(37,461,304,40),func():cover.queue_free(),ICON_SURFACE,TEAL,0,EDGE)
	done.name="LearnReaderDone";done.add_theme_font_size_override("font_size",14)
	if course:
		var record: Button=b._button(cover,"点名记录",Rect2(37,335,304,44),func():
			var c: Dictionary=b.campus_services.copy.classroom
			text.text=c.status_signed if b.s.flags.checkinDone else c.status_not_signed if b.s.actOne.phase=="prologue" else c.status_finished
			if b.s.flags.checkinDone:text.text+="\n"+c.method_code_btn,Color.WHITE,TEAL,0,EDGE)
		record.name="LearnAttendanceRecord"
		var live: Button=b._button(cover,"课堂直录播",Rect2(37,391,304,44),func():b._zju_open("smart_classroom"),ICON_SURFACE,TEAL,0,EDGE)
		live.name="LearnClassroomReplay"
	close.grab_focus.call_deferred()

func _shortcut(b,root: Control,title: String,detail: String,kind: String,rect: Rect2,callback: Callable=Callable()) -> Control:
	var card: Control
	if callback.is_valid():
		card=b._button(root,"",rect,callback,ICON_SURFACE,TEAL,0,EDGE)
		card.tooltip_text=title
		card.accessibility_name=title
	else:card=b._panel(root,rect,ICON_SURFACE,EDGE,0,2)
	_icon(card,kind,Rect2(10,14,58,58))
	b._label(card,title,Rect2(76,19,rect.size.x-84,29),18,INK)
	b._label(card,detail,Rect2(76,52,rect.size.x-84,39),13,MUTED)
	return card

func build(b) -> Control:
	var root: Control=b._base(SURFACE,b.APP_HEIGHT);root.name="ZjudingLearnPage"
	root.set_meta("handles_all_actions",true)
	b._nav(root,"back","返回浙大钉",b._zju_back,Rect2(9,7,40,44),SURFACE,INK)
	b._label(root,"学在浙大",Rect2(58,9,244,38),22,INK).name="ZjudingLearnTitle"
	b._label(root,"浙江大学",Rect2(278,15,85,28),13,MUTED,HORIZONTAL_ALIGNMENT_RIGHT)
	# Only the campus and course illustrations are cropped from the old art.
	# No photographed text, icons, navigation or transparent hotspots survive.
	b._panel(root,Rect2(14,61,350,76),Color("e9f1f6"),EDGE,0,1)
	_art(root,Rect2(181,58,470,167),Rect2(196,63,165,72),"LearnCampusIllustration")
	b._label(root,"早上好，同学",Rect2(28,73,186,27),19,INK)
	b._label(root,"从这一节课开始。",Rect2(28,106,183,21),13,MUTED)
	b._panel(root,Rect2(14,151,350,43),Color.WHITE,EDGE,0,1)
	b._panel(root,Rect2(14,151,4,43),TEAL)
	b._label(root,"08:00",Rect2(27,157,62,28),18,TEAL)
	b._label(root,"高等数学 · 快快老师",Rect2(100,157,250,28),15,INK)
	var schedule: Control=_shortcut(b,root,"课表","查看课程\n与上课地点","calendar",Rect2(14,209,169,112),func():_reader(b,root,"今日课程",COURSES[0][2]))
	schedule.name="LearnSchedule"
	var callback: Callable=func():b.checkin_return="learn";b.page_requested.emit("checkin")
	if b.s.actOne.phase!="prologue":callback=func():_reader(b,root,"点名记录",b.campus_services.copy.classroom.status_signed if b.s.flags.checkinDone else b.campus_services.copy.classroom.status_finished,true)
	var checkin: Control=_shortcut(b,root,"签到","课堂签到\n填写签到码","book",Rect2(195,209,169,112),callback)
	checkin.name="ZjudingCheckin"
	b._label(root,"我的课程",Rect2(14,339,240,26),19,INK).name="LearnCoursesTitle"
	b._label(root,"课程一览",Rect2(278,342,86,23),13,MUTED,HORIZONTAL_ALIGNMENT_RIGHT)
	for i in range(COURSES.size()):
		var course: Array=COURSES[i]
		var card: Button=b._button(root,"",Rect2(14,376+i*94,350,86),func():_reader(b,root,course[0],course[2],i==0),Color.WHITE,INK,0,EDGE)
		card.name="LearnCourse_"+str(i);card.tooltip_text=course[0];card.accessibility_name=course[0]
		_art(card,course[3],Rect2(10,12,112,60),"LearnCourseIllustration_"+str(i))
		b._label(card,course[0],Rect2(136,12,202,27),18,INK)
		b._label(card,course[1],Rect2(136,46,202,27),13,MUTED)
	b._label(root,"课程通知",Rect2(14,570,300,27),19,INK).name="LearnNoticeTitle"
	var notice: Button=b._button(root,"",Rect2(14,604,350,60),func():_reader(b,root,"课堂提醒",COURSES[0][2]+"\n"+(b.campus_services.copy.classroom.status_not_signed if b.s.actOne.phase=="prologue" and not b.s.flags.checkinDone else b.campus_services.copy.classroom.status_signed if b.s.flags.checkinDone else b.campus_services.copy.classroom.status_finished)),Color.WHITE,INK,0,EDGE)
	notice.name="LearnNotice";notice.tooltip_text="课堂提醒";notice.accessibility_name="课堂提醒"
	b._panel(notice,Rect2(10,7,44,44),ICON_SURFACE,EDGE,0,1);_icon(notice,"bell",Rect2(12,9,40,40))
	b._label(notice,"课堂提醒",Rect2(68,7,270,24),16,INK)
	b._label(notice,b.campus_services.copy.classroom.status_not_signed if b.s.actOne.phase=="prologue" and not b.s.flags.checkinDone else b.campus_services.copy.classroom.status_signed if b.s.flags.checkinDone else b.campus_services.copy.classroom.status_finished,Rect2(68,32,270,21),13,MUTED)
	b._panel(root,Rect2(0,b.APP_HEIGHT-60,378,60),Color.WHITE,EDGE,0,1)
	_icon(root,"book",Rect2(83,b.APP_HEIGHT-55,29,29))
	b._label(root,"学在浙大",Rect2(41,b.APP_HEIGHT-27,114,21),13,TEAL,HORIZONTAL_ALIGNMENT_CENTER)
	b._panel(root,Rect2(77,b.APP_HEIGHT-5,44,3),TEAL)
	_icon(root,"person",Rect2(266,b.APP_HEIGHT-55,29,29))
	b._label(root,"我的",Rect2(226,b.APP_HEIGHT-27,110,21),13,MUTED,HORIZONTAL_ALIGNMENT_CENTER).name="LearnProfileDisplay"
	return root
