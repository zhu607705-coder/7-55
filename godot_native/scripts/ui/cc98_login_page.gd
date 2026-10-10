extends RefCounted
## Native rendering of UnifiedIdentityLogin.tsx and p02-cc98.css.
## Form drafts are local; identity, hint count, attempts and lockout stay controller-owned.
const HINTS = [
	["校名缩写", "取浙江大学英文名的三个大写字母。", "ZJU"],
	["校史年份", "接上求是书院创办的四位年份。", "1897"],
	["结尾标点", "保留认证公告最后的感叹号。", "!"]
]
var student_id = ""
var password = ""
var password_visible = false
var feedback = "先从随身校园卡确认账号，再拆开密码提示。"
var scroll_position = 0
var card_pending = false
var hint_pending = false
var login_pending = false
var attempt_before = 0
var submitted_id = ""
var submitted_password = ""

func reset() -> void:
	student_id=""; password=""; password_visible=false; scroll_position=0
	feedback="先从随身校园卡确认账号，再拆开密码提示。"
	card_pending=false; hint_pending=false; login_pending=false

func remaining_ms(login: Dictionary) -> int:
	return maxi(0,int(login.lockUntilMs)-int(Time.get_unix_time_from_system()*1000.0)) if login.lockUntilMs!=null else 0

func build(b) -> Control:
	var login: Dictionary=b.s.actOne.cc98Login
	if card_pending:
		card_pending=false
		if login.studentIdDiscovered and b.s.items.campusCard and b.s.actOne.inventoryRecovered: student_id="3250100755"; feedback="校园卡已读取：林星宇，学号已填入。"
		else: feedback="随身物品里没有校园卡，当前无法确认 10 位学号。"
	if hint_pending:
		hint_pending=false
		var count=int(login.revealedHintCount)
		feedback="提示 %s/3 已展开：%s" % [count,HINTS[count-1][1]] if count>0 else feedback
	if login_pending:
		login_pending=false
		if not login.studentIdDiscovered: feedback="先读取校园卡上的学号，再提交认证。"
		elif int(login.failureCount)>attempt_before:
			password=""
			var mismatch="学号与校园卡不一致。" if submitted_password=="ZJU1897!" else "密码片段、顺序或大小写不正确。" if submitted_id=="3250100755" else "学号和密码均未通过核验。"
			feedback=mismatch+(" 已累计 %s 次失败，等待 %ss 后可重试。" % [int(login.failureCount),int(ceil(remaining_ms(login)/1000.0))] if remaining_ms(login)>0 else " 还可立即尝试 %s 次。" % maxi(0,3-int(login.failureCount)))
		elif remaining_ms(login)>0: feedback="尝试暂时锁定，还需等待 %ss。" % int(ceil(remaining_ms(login)/1000.0))
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
	var seal=Polygon2D.new(); seal.polygon=PackedVector2Array([Vector2(36,9),Vector2(55,18),Vector2(52,45),Vector2(36,58),Vector2(20,45),Vector2(17,18)]); seal.color=Color("f0a43a"); root.add_child(seal)
	b._label(root,"Z",Rect2(23,18,26,29),23,Color("fff4d1"),HORIZONTAL_ALIGNMENT_CENTER)
	b._label(root,"浙江大学统一身份认证",Rect2(66,20,300,24),17,Color("42484f"))
	b._label(root,"UNIFIED IDENTITY AUTHENTICATION",Rect2(66,44,300,13),8,Color("555b62"))
	var scroll=ScrollContainer.new(); scroll.name="Cc98LoginScroll"; scroll.position=Vector2(0,69.5); scroll.size=Vector2(378,b.APP_HEIGHT-69.5); scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; root.add_child(scroll)
	var content=Control.new(); content.custom_minimum_size=Vector2(372,860); scroll.add_child(content)
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
	var password_field: LineEdit=b._line_edit(content,"按提示组合密码",Rect2(73,159,220,39),password); password_field.name="Cc98LoginPassword"; password_field.max_length=24; password_field.secret=not password_visible
	for field in [id_field,password_field]:
		field.add_theme_stylebox_override("normal",b._style(Color.TRANSPARENT)); field.add_theme_stylebox_override("focus",b._style(Color.TRANSPARENT)); field.add_theme_color_override("font_color",light); field.add_theme_color_override("font_placeholder_color",Color("b8c3cf")); field.add_theme_font_size_override("font_size",15)
	for y in [150,202]: b._panel(content,Rect2(30,y,313,2),Color("eaf4ff"))
	var visibility: Button=b._button(content,"隐藏" if password_visible else "显示",Rect2(300,161,43,34),func(): password_visible=not password_visible; password_field.secret=not password_visible,Color.TRANSPARENT,light,0,Color.TRANSPARENT)
	visibility.name="Cc98PasswordVisibility"
	visibility.pressed.connect(func(): visibility.text="隐藏" if password_visible else "显示")
	b._label(content,"失败记录 %d" % int(login.failureCount),Rect2(30,211,120,22),11,Color("c5d1dd"))
	var attempts: Label=b._label(content,"",Rect2(155,211,188,22),11,Color("f4bd5b"),HORIZONTAL_ALIGNMENT_RIGHT); attempts.name="Cc98LoginAttempts"
	var submit: Button=b._button(content,"登 录",Rect2(30,239,313,43),func():
		submitted_id=student_id; submitted_password=password; attempt_before=int(login.failureCount); login_pending=true
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
	b._panel(content,Rect2(30,294,313,40),Color("282b2e"))
	b._panel(content,Rect2(30,294,4,40),amber)
	var feedback_label: Label=b._label(content,feedback,Rect2(42,299,291,31),11,Color("eef6ff")); feedback_label.name="Cc98LoginFeedback"
	b._panel(content,Rect2(20,367,345,371),Color(.17,.18,.2,.35))
	b._panel(content,Rect2(14,361,345,371),charcoal,Color("bfc1c4"),0,2)
	b._label(content,"本地找回",Rect2(28,372,235,14),9,amber)
	b._label(content,"认证线索",Rect2(28,387,235,27),18,light)
	b._panel(content,Rect2(308,378,36,29),Color("53565a"),amber,0,1)
	b._label(content,"%d/3" % int(login.revealedHintCount),Rect2(308,378,36,29),12,light,HORIZONTAL_ALIGNMENT_CENTER)
	b._panel(content,Rect2(28,421,316,2),Color("bec1c6"))
	var reader: Button=b._button(content,"",Rect2(28,432,316,66),func(): card_pending=true; b.action_requested.emit("c2_card_identity",null),Color("4f5155"),light,0,Color("db9e3b")); reader.name="Cc98ReadCampusCard"
	b._panel(reader,Rect2(8,11,57,42),Color("153a72"),Color("0d274c"),0,2)
	b._label(reader,"ZJU\n07:55",Rect2(14,15,44,34),10,Color.WHITE)
	b._label(reader,"校园卡身份已读取" if login.studentIdDiscovered else "查看随身校园卡",Rect2(75,10,195,23),12,light)
	b._label(reader,"林星宇 · 3250100755" if login.studentIdDiscovered else "卡面记录了持卡人的 10 位学号",Rect2(75,32,189,25),9,Color("d9dde1"))
	b._label(reader,"填入" if login.studentIdDiscovered else "读取",Rect2(277,19,35,28),10,amber,HORIZONTAL_ALIGNMENT_CENTER)
	for i in range(3):
		var revealed=i<int(login.revealedHintCount); var y=509+i*58
		b._panel(content,Rect2(28,y,316,52),Color("575a5e") if revealed else Color("4a4d51"),Color("dca03d") if revealed else Color("777b80"),0,2)
		b._panel(content,Rect2(35,y+13,24,24),Color.TRANSPARENT,light if revealed else Color("aeb3b8"),0,2)
		b._label(content,str(i+1),Rect2(35,y+13,24,24),13,light,HORIZONTAL_ALIGNMENT_CENTER)
		b._label(content,HINTS[i][0] if revealed else "待解锁片段",Rect2(67,y+6,222,20),12,light if revealed else Color("aeb3b8"))
		b._label(content,HINTS[i][1] if revealed else "展开上一条提示后显示",Rect2(67,y+26,216,20),9,light if revealed else Color("aeb3b8"))
		b._label(content,HINTS[i][2] if revealed else "•••",Rect2(287,y+9,49,34),13,amber,HORIZONTAL_ALIGNMENT_CENTER).name="Cc98HintFragment_"+str(i)
	var hint: Button=b._button(content,"提示已全部展开" if int(login.revealedHintCount)>=3 else "展开提示 %s" % (int(login.revealedHintCount)+1),Rect2(28,690,316,32),func(): hint_pending=true; b.action_requested.emit("c2_login_hint",null),Color("4a4d51"),Color.WHITE,0,Color("d4d6d8")); hint.name="Cc98RevealHint"; hint.disabled=int(login.revealedHintCount)>=3; hint.add_theme_font_size_override("font_size",12)
	b._panel(content,Rect2(108,747,160,27),Color("3c3f43"))
	b._label(content,"浙江大学统一身份认证",Rect2(108,747,160,27),9,Color("dce8f2"),HORIZONTAL_ALIGNMENT_CENTER)
	var exit_button: Button=b._button(root,"退出认证",Rect2(14,b.APP_HEIGHT-50,100,38),func(): b.page_requested.emit("phone_home"),Color("414448"),Color.WHITE,0,Color("dfeeff")); exit_button.add_theme_font_size_override("font_size",12); exit_button.name="Cc98LoginExit"
	scroll.scroll_vertical=scroll_position
	scroll.get_v_scroll_bar().value_changed.connect(func(value): scroll_position=int(value))
	root.ready.connect(func(): scroll.scroll_vertical=scroll_position)
	for action in ["c2_login","c2_login_hint","c2_card_identity"]:
		if not b.handled.has(action): b.handled.append(action)
	return root
