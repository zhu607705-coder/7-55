extends RefCounted
## Source CheckinScene form draft and CSS. Controller still owns every story result.
var code=""
var error=false
var submission_pending=false
func reset() -> void: code=""; error=false; submission_pending=false
func build(b) -> Control:
	if submission_pending:
		submission_pending=false
		if not b.s.flags.checkinDone and b.s.networkMode=="campus_wifi": error=true; code=""
	var root: Control=b._base(Color("eef2f7"),b.APP_HEIGHT); root.set_meta("handles_all_actions",true)
	for x in range(0,424,12): b._panel(root,b._home_rect(x,40,2,814),Color(.09,.58,.72,.04))
	for y in range(40,854,12): b._panel(root,b._home_rect(0,y,424,2),Color(.09,.58,.72,.05))
	b._nav(root,"back","返回学在浙大",func(): b._return_zjuding("learn"),b._home_rect(18,52,44,44),Color.TRANSPARENT)
	b._label(root,"学在浙大 · 课堂签到",b._home_rect(62,52,300,44),16,b.INK,HORIZONTAL_ALIGNMENT_CENTER)
	b._panel(root,b._home_rect(18,110,388,141),Color("fff8e2"),b.INK,0,2)
	b._label(root,"高等数学（早八特供版）",b._home_rect(34,125,335,24),16)
	var live: Panel=b._panel(root,b._home_rect(378,130,12,12),Color("c85454"),Color("7c2929"),6,2)
	b._label(root,"快快老师 · 紫金港西1-201 · 08:00",b._home_rect(34,155,356,18),12,Color("5b6472"))
	b._label(root,"正在点名中……",b._home_rect(34,179,356,18),12,Color("c85454"))
	b._panel(root,b._home_rect(34,207,356,32),Color("e7edf3"),Color("84909d"),0,2)
	b._label(root,"本周缺勤",b._home_rect(274,213,64,22),10,Color("596572"))
	if b.s.flags.codeScattered and not b.s.flags.cardZeroTaken:
		var zero: Button=b._act(root,"0",b._home_rect(338,211,25,25),"c1_absence",null,Color("f0d54e"),Color("241f11"),0,Color("7d6611")); zero.name="CheckinAbsenceZero"; zero.add_theme_font_size_override("font_size",16)
	else:
		b._panel(root,b._home_rect(338,211,25,25),Color("d9e1e8") if b.s.flags.cardZeroTaken else Color("f0d54e"),Color("81909d") if b.s.flags.cardZeroTaken else Color("7d6611"),0,2)
		b._label(root,"0",b._home_rect(338,211,25,25),16,Color("64717d") if b.s.flags.cardZeroTaken else Color("241f11"),HORIZONTAL_ALIGNMENT_CENTER)
	b._label(root,"次",b._home_rect(370,213,14,22),10,Color("596572"))
	var frames: Array=[]; var labels: Array=[]
	for i in range(4):
		var frame: Panel=b._panel(root,b._home_rect(90+i*64,271,52,62),Color.WHITE,b.INK,0,3); frame.name="CheckinSlotFrame_"+str(i); frames.append(frame)
		var label: Label=b._label(root,"",b._home_rect(90+i*64,271,52,62),21,b.INK,HORIZONTAL_ALIGNMENT_CENTER); label.name="CheckinSlot_"+str(i); labels.append(label)
	var ready_frame: Panel=b._panel(root,b._home_rect(84,258,256,82),Color.TRANSPARENT,Color("1793b8"),0,3); ready_frame.name="CheckinReadyFrame"
	var error_label: Label=b._label(root,"签到码错误，请重新输入",b._home_rect(18,348,388,25),12,Color("c85454"),HORIZONTAL_ALIGNMENT_CENTER); error_label.name="CheckinError"
	var submit_holder: Array=[]
	var update_form=func():
		for i in range(4):
			labels[i].text=code.substr(i,1) if i<code.length() else ""
			labels[i].add_theme_color_override("font_color",Color("c85454") if error else b.INK)
			frames[i].add_theme_stylebox_override("panel",b._style(Color("fff9e2") if i<code.length() else Color.WHITE,Color("c85454") if error else b.INK,0,3))
		ready_frame.visible=code.length()==4; error_label.visible=error
		if not submit_holder.is_empty(): submit_holder[0].disabled=code.length()<4
	var keys=["1","2","3","4","5","6","7","8","9","⌫","0","签到"]
	for i in range(keys.size()):
		var key=str(keys[i]); var fill=Color("1793b8") if key=="签到" else Color("f3e2e2") if key=="⌫" else Color.WHITE
		var activate=func():
			if key=="签到":
				if code.length()<4: return
				submission_pending=true; b.action_requested.emit("c1_checkin",code); return
			if key=="⌫": code=code.left(maxi(0,code.length()-1)); error=false
			else:
				var index=mini(3,code.length()); error=false
				if code.length()<4: code+=key
				entry_pulse(b,root,key,index)
			update_form.call()
		var button: Button=b._button(root,key,b._home_rect(18+(i%3)*(398.0/3.0),577+int(i/3)*66.8,368.0/3.0,56.8),activate,fill,Color.WHITE if key=="签到" else b.INK,0,Color("0d6076") if key=="签到" else b.INK)
		button.name="CheckinSubmit" if key=="签到" else "CheckinKey_delete" if key=="⌫" else "CheckinKey_"+key
		button.add_theme_font_size_override("font_size",12 if key=="签到" else 21)
		if key=="签到": submit_holder.append(button)
	update_form.call()
	root.ready.connect(func():
		var pulse=live.create_tween().set_loops(); pulse.tween_property(live,"modulate:a",.35,.35); pulse.tween_property(live,"modulate:a",1.0,.35)
		if error:
			var shake=root.create_tween()
			for offset in [-3,3,-2,2,0]: shake.tween_property(root,"position:x",float(offset),.045))
	for id in ["c1_absence","c1_checkin"]:
		if not b.handled.has(id): b.handled.append(id)
	return root
func entry_pulse(b, root: Control, digit: String, index: int) -> void:
	var previous=root.get_node_or_null("CheckinEntryPulse")
	if previous: previous.free()
	var target=b._home_rect(90+index*64,282,30,34).position
	var pulse: Panel=b._panel(root,Rect2(target+Vector2(0,36),Vector2(30,34)/b.PHONE_SCALE),Color("1793b8"),Color("0d6076"),0,2)
	pulse.name="CheckinEntryPulse"; pulse.z_index=4; b._label(pulse,digit,Rect2(Vector2.ZERO,pulse.size),16,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER)
	for i in range(3): b._panel(pulse,Rect2(4+i*9,35+(i%2)*5,4,4),Color("f0d54e"))
	var tween=pulse.create_tween(); tween.tween_property(pulse,"position",target,.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT); tween.tween_property(pulse,"modulate:a",0.0,.18); tween.tween_callback(pulse.queue_free)
