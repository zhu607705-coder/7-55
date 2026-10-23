extends RefCounted
## Native authentication: the attendant's remarks carry the existing password clues.
## Form drafts are local; identity, hint count, attempts and lockout stay controller-owned.
const REMARKS = [
	"校园卡都没拿稳，就想混进论坛？报名字没用，我只认卡面上的那串数字。",
	"连我是谁都没看？门楣上写着 ZheJiang University。大写的站得这么直，你倒一个也没记住。",
	"嫌我摆老资格？求是书院1897年就开门了。你来得晚，排在名字后面不委屈吧。",
	"还等我替你敲键盘？我说完了，你也该拿出点气势来!"
]
const REPLIES = ["那你叫什么？", "你管了多久？", "话说完了？"]
const HELP_REPLY = "行，少绕两句。校名里站直的大写字母在前，书院开门的年份跟上，我最后那句话的收尾也别落下。中间别塞空格。"
var student_id = ""
var password = ""
var password_visible = false
var feedback = "想进去？证件拿出来，下面再慢慢聊。"
var scroll_position = 0
var dialogue_index = -1
var help_visible = false
var card_pending = false
var hint_pending = false
var login_pending = false
var attempt_before = 0
var submitted_id = ""

func reset() -> void:
	student_id=""; password=""; password_visible=false; scroll_position=0
	feedback="想进去？证件拿出来，下面再慢慢聊。"
	dialogue_index=-1; help_visible=false
	card_pending=false; hint_pending=false; login_pending=false

func remaining_ms(login: Dictionary) -> int:
	return maxi(0,int(login.lockUntilMs)-int(Time.get_unix_time_from_system()*1000.0)) if login.lockUntilMs!=null else 0

func build(b) -> Control:
	var login: Dictionary=b.s.actOne.cc98Login
	var revealed_count=clampi(int(login.revealedHintCount),0,3)
	if dialogue_index<0: dialogue_index=revealed_count
	dialogue_index=clampi(dialogue_index,0,revealed_count)
	if card_pending:
		card_pending=false
		if login.studentIdDiscovered and b.s.items.campusCard and b.s.actOne.inventoryRecovered: student_id="3250100755"; feedback="林星宇，是你啊。学号填好了，剩下的可别蒙。"
		else: feedback="口袋都没翻就来敲门？先把校园卡找回来。"
	if hint_pending:
		hint_pending=false
		dialogue_index=revealed_count; help_visible=false
		feedback="我说过的话都留着。别光顾着顶嘴。"
	if login_pending:
		login_pending=false
		if not login.studentIdDiscovered: feedback="先让我看看校园卡。光报一串数字可不算认识。"
		elif int(login.failureCount)>attempt_before:
			password=""
			if submitted_id!="3250100755": feedback="连自己的学号也认错？再看一眼校园卡。"
			elif int(login.failureCount)==1: feedback="手比眼睛快。我说的那几句话，你真看进去了？"
			else: feedback="还没对上？你肯问，我就说清楚一点。"
			if remaining_ms(login)>0: feedback="先歇口气，倒计时走完再试。我的话还在下面。"
		elif remaining_ms(login)>0: feedback="门还没开。等倒计时走完再来敲。"
	var root: Control=b._base(Color("9bc8f3"),b.APP_HEIGHT)
	root.set_meta("handles_all_actions",true)
	var backdrop: TextureRect=b._image(root,"ui/photo-evidence/campus-life/campus_qizhen_dock_morning.webp",Rect2(-10,-10,398,b.APP_HEIGHT+20))
	backdrop.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	# Source CSS blur(5px) saturate(.72) brightness(1.14), applied only to backdrop.
	var shader=Shader.new(); shader.code="""shader_type canvas_item;
void fragment() {
 vec2 dx=dFdx(UV)*5.0; vec2 dy=dFdy(UV)*5.0;
 vec4 c=texture(TEXTURE,UV)*0.20;
 c+=(texture(TEXTURE,UV+dx)+texture(TEXTURE,UV-dx)+texture(TEXTURE,UV+dy)+texture(TEXTURE,UV-dy))*0.12;
 c+=(texture(TEXTURE,UV+dx+dy)+texture(TEXTURE,UV+dx-dy)+texture(TEXTURE,UV-dx+dy)+texture(TEXTURE,UV-dx-dy))*0.08;
 float luminance=dot(c.rgb,vec3(0.2126,0.7152,0.0722));
 COLOR=vec4(mix(vec3(luminance),c.rgb,0.72)*1.14,c.a);
}"""
	var material=ShaderMaterial.new(); material.shader=shader; backdrop.material=material
	b._panel(root,Rect2(0,0,378,b.APP_HEIGHT),Color(.59,.78,.95,.36))
	b._panel(root,Rect2(0,0,378,69.5),Color(.65,.81,.96,.85))
	b._panel(root,Rect2(0,68,378,2),Color("596572"))
	var exit_button: Button=b._button(root,"返回",Rect2(10,13,44,44),func(): b.page_requested.emit("phone_home"),Color.TRANSPARENT,Color("263b52"),0,Color.TRANSPARENT)
	exit_button.name="Cc98LoginExit"; exit_button.add_theme_font_size_override("font_size",13)
	b._label(root,"浙江大学统一身份认证",Rect2(67,18,299,28),17,Color("42484f"))
	b._label(root,"UNIFIED IDENTITY AUTHENTICATION",Rect2(67,46,299,13),8,Color("555b62"))
	var scroll=ScrollContainer.new(); scroll.name="Cc98LoginScroll"; scroll.position=Vector2(0,69.5); scroll.size=Vector2(378,b.APP_HEIGHT-69.5); scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; root.add_child(scroll)
	# Godot's touch-to-mouse drag must bubble through the authored canvas to
	# its sole scroll owner. STOP here swallows the swipe while wheels pass.
	var content=Control.new(); content.mouse_filter=Control.MOUSE_FILTER_PASS; content.custom_minimum_size=Vector2(372,800); scroll.add_child(content)
	var charcoal=Color("3f4246"); var light=Color("f7fbff"); var amber=Color("f0ad42")
	b._panel(content,Rect2(20,22,345,329),Color(.17,.18,.2,.35))
	b._panel(content,Rect2(14,16,345,329),charcoal,Color("bfc1c4"),0,2)
	b._label(content,"首次进入 CC98",Rect2(30,29,260,19),11,amber)
	b._label(content,"浙大通行证",Rect2(30,47,270,34),24,light)
	b._panel(content,Rect2(315,31,30,30),Color.WHITE)
	for square in [Rect2(322,38,7,7),Rect2(331,38,7,7),Rect2(322,47,16,7)]: b._panel(content,square,Color("253345"))
	for x in range(30,344,9): b._panel(content,Rect2(x,90,5,2),Color("aab4bd"))
	b._label(content,"ID",Rect2(30,106,37,43),11,amber)
	var id_field: LineEdit=b._line_edit(content,"10 位学号",Rect2(73,107,270,39),student_id); id_field.name="Cc98LoginStudentId"; id_field.max_length=10
	b._label(content,"KEY",Rect2(30,158,37,43),11,amber)
	var password_field: LineEdit=b._line_edit(content,"通行口令",Rect2(73,159,220,39),password); password_field.name="Cc98LoginPassword"; password_field.max_length=24; password_field.secret=not password_visible
	for field in [id_field,password_field]:
		field.add_theme_stylebox_override("normal",b._style(Color.TRANSPARENT)); field.add_theme_stylebox_override("focus",b._style(Color.TRANSPARENT)); field.add_theme_color_override("font_color",light); field.add_theme_color_override("font_placeholder_color",Color("b8c3cf")); field.add_theme_font_size_override("font_size",15)
	for y in [150,202]: b._panel(content,Rect2(30,y,313,2),Color("eaf4ff"))
	var visibility: Button=b._button(content,"隐藏" if password_visible else "显示",Rect2(300,161,43,34),func(): password_visible=not password_visible; password_field.secret=not password_visible,Color.TRANSPARENT,light,0,Color.TRANSPARENT)
	visibility.name="Cc98PasswordVisibility"
	visibility.pressed.connect(func(): visibility.text="隐藏" if password_visible else "显示")
	b._label(content,"失败记录 %d" % int(login.failureCount),Rect2(30,211,120,22),11,Color("c5d1dd"))
	var attempts: Label=b._label(content,"",Rect2(155,211,188,22),11,Color("f4bd5b"),HORIZONTAL_ALIGNMENT_RIGHT); attempts.name="Cc98LoginAttempts"
	var submit: Button=b._button(content,"登 录",Rect2(30,239,313,43),func():
		submitted_id=student_id; attempt_before=int(login.failureCount); login_pending=true
		b.action_requested.emit("c2_login",{"student_id":student_id,"password":password}),Color("4285ee"),Color.WHITE,0,Color("78aaf3"))
	submit.name="Cc98LoginSubmit"; submit.add_theme_stylebox_override("disabled",b._style(Color("58616b"),Color("7b8794"),0,2)); submit.add_theme_color_override("font_disabled_color",Color("c6cbd1"))
	var update_inputs=func():
		var remaining=remaining_ms(login); var seconds=int(ceil(remaining/1000.0)); var left=maxi(0,3-int(login.failureCount))
		attempts.text="锁定 %ss" % seconds if remaining>0 else "立即机会 %s/3" % left if left>0 else "下次失败等待 %ss" % maxi(30,(int(login.failureCount)-1)*30)
		submit.text="等待 %ss" % seconds if remaining>0 else "登 录"
		submit.disabled=remaining>0 or student_id.is_empty() or password.is_empty()
	id_field.text_changed.connect(func(text):
		var digits=""
		for ch in text:
			if ch>="0" and ch<="9": digits+=ch
		student_id=digits.left(10)
		if id_field.text!=student_id: id_field.text=student_id; id_field.caret_column=student_id.length()
		update_inputs.call())
	password_field.text_changed.connect(func(text): password=text.left(24); update_inputs.call())
	password_field.text_submitted.connect(func(_text):
		if not submit.disabled: submit.pressed.emit())
	update_inputs.call()
	var timer=Timer.new(); timer.wait_time=.25; timer.autostart=true; timer.timeout.connect(update_inputs); root.add_child(timer)
	b._panel(content,Rect2(30,294,313,47),Color("282b2e"))
	b._panel(content,Rect2(30,294,4,47),amber)
	var feedback_label: Label=b._label(content,feedback,Rect2(42,298,291,39),13,Color("eef6ff")); feedback_label.name="Cc98LoginFeedback"
	b._panel(content,Rect2(20,367,345,403),Color(.17,.18,.2,.35))
	b._panel(content,Rect2(14,361,345,403),charcoal,Color("bfc1c4"),0,2)
	var reader: Button=b._button(content,"",Rect2(28,375,316,62),func(): card_pending=true; b.action_requested.emit("c2_card_identity",null),Color("4f5155"),light,0,Color("db9e3b")); reader.name="Cc98ReadCampusCard"
	b._panel(reader,Rect2(8,10,57,42),Color("153a72"),Color("0d274c"),0,2)
	b._label(reader,"ZJU\n07:55",Rect2(14,14,44,34),10,Color.WHITE)
	b._label(reader,"校园卡身份已读取" if login.studentIdDiscovered else "出示校园卡",Rect2(75,7,195,23),13,light)
	b._label(reader,"林星宇 · 3250100755" if login.studentIdDiscovered else "翻看随身物品里的卡面",Rect2(75,29,194,25),11,Color("d9dde1"))
	b._label(reader,"填入" if login.studentIdDiscovered else "读取",Rect2(277,17,35,28),11,amber,HORIZONTAL_ALIGNMENT_CENTER)
	b._label(content,"认证值班员",Rect2(28,447,280,22),13,amber)
	var remark: Label=b._label(content,"",Rect2(28,477,316,112),15,light)
	remark.name="Cc98AttendantRemark"; remark.vertical_alignment=VERTICAL_ALIGNMENT_TOP
	var reply: Button=b._button(content,"",Rect2(28,600,316,44),func(): hint_pending=true; b.action_requested.emit("c2_login_hint",null),Color("4a4d51"),Color.WHITE,0,Color("d4d6d8"))
	reply.name="Cc98RevealHint"; reply.add_theme_font_size_override("font_size",14)
	var previous: Button=b._button(content,"上一句",Rect2(28,652,151,40),func(): pass,Color.TRANSPARENT,light,0,Color("747f8d"))
	previous.name="Cc98PreviousRemark"; previous.add_theme_font_size_override("font_size",13)
	var following: Button=b._button(content,"下一句",Rect2(193,652,151,40),func(): pass,Color.TRANSPARENT,light,0,Color("747f8d"))
	following.name="Cc98NextRemark"; following.add_theme_font_size_override("font_size",13)
	var help: Button=b._button(content,"说清楚一点",Rect2(28,704,316,44),func(): pass,Color.TRANSPARENT,light,0,Color("747f8d"))
	help.name="Cc98AskClearly"; help.add_theme_font_size_override("font_size",13)
	help.visible=int(login.failureCount)>=2
	var return_to_form: Button=b._button(content,"回去填写",Rect2(28,600,316,44),func():
		scroll.scroll_vertical=0; password_field.grab_focus(),Color("4a4d51"),light,0,Color("d4d6d8"))
	return_to_form.name="Cc98ReturnToForm"; return_to_form.add_theme_font_size_override("font_size",14)
	# Re-reading is local presentation. Only the next spoken reply emits the
	# existing controller hint intent; no dialogue writes identity or progress.
	var update_dialogue=func():
		remark.text=HELP_REPLY if help_visible else REMARKS[dialogue_index]
		previous.disabled=dialogue_index<=0 and not help_visible
		following.disabled=dialogue_index>=revealed_count and not help_visible
		help.text="回到刚才的话" if help_visible else "说清楚一点"
		reply.visible=revealed_count<3
		reply.disabled=revealed_count>=3
		reply.text=REPLIES[revealed_count] if revealed_count<3 else ""
		return_to_form.visible=revealed_count>=3
	previous.pressed.connect(func():
		if not help_visible: dialogue_index=maxi(0,dialogue_index-1)
		help_visible=false; update_dialogue.call())
	following.pressed.connect(func():
		if not help_visible: dialogue_index=mini(revealed_count,dialogue_index+1)
		help_visible=false; update_dialogue.call())
	help.pressed.connect(func(): help_visible=not help_visible; update_dialogue.call())
	update_dialogue.call()
	# Taps still reach their original controls; a swipe that starts over a
	# control can reach ScrollContainer and cancel the pressed button normally.
	for control: Control in content.find_children("*","Control",true,false):
		if control is BaseButton or control is LineEdit: control.mouse_filter=Control.MOUSE_FILTER_PASS
	scroll.scroll_vertical=scroll_position
	scroll.get_v_scroll_bar().value_changed.connect(func(value): scroll_position=int(value))
	root.ready.connect(func(): scroll.scroll_vertical=scroll_position)
	for action in ["c2_login","c2_login_hint","c2_card_identity"]:
		if not b.handled.has(action): b.handled.append(action)
	return root
