extends RefCounted
## Native check-in composition. Drafts are local; the controller owns every result.
const PAPER=Color("f7f8f3")
const INK=Color("173f3b")
const MUTED=Color("5e736f")
const ACCENT=Color("236a5c")
const LINE=Color("dce6df")
const ERROR=Color("a64d43")
const UI_FONT=preload("res://assets/native/checkin/checkin_ui_font_v1.ttf")
var code=""
var error=false
var submission_pending=false
func reset() -> void: code=""; error=false; submission_pending=false
func owns_feedback(message: String) -> bool:
	# The submitted form will render this rejection inline on its next rebuild.
	return submission_pending and message=="签到码错误。"
func build(b) -> Control:
	if submission_pending:
		submission_pending=false
		if not b.s.flags.checkinDone and b.s.networkMode=="campus_wifi": error=true; code=""
	var reduced: bool=bool(b.s.native.get("settings",{}).get("reduced_motion",false))
	var root: Control=b._base(PAPER,b.APP_HEIGHT); root.set_meta("handles_all_actions",true)
	root.name="NativeCheckinPage"
	root.theme=Theme.new();root.theme.default_font=UI_FONT
	b._nav(root,"back","返回学在浙大",func(): b._return_zjuding("learn"),b._home_rect(18,52,44,44),Color.TRANSPARENT)
	b._label(root,"课堂签到",b._home_rect(72,52,280,44),16,INK,HORIZONTAL_ALIGNMENT_CENTER)
	b._panel(root,b._home_rect(24,101,376,1),LINE)
	# Course details stay readable above the form. The zero keeps its authored
	# source position so the original collectible still leaves from this record.
	b._panel(root,b._home_rect(20,116,384,140),Color.WHITE,LINE,14,1).name="CheckinCourseCard"
	b._label(root,"高等数学（早八特供版）",b._home_rect(34,128,335,28),17,INK)
	b._label(root,"快快老师 · 紫金港西1-201 · 08:00",b._home_rect(34,163,356,20),12,MUTED)
	var live: Panel=b._panel(root,b._home_rect(35,192,6,6),ACCENT,Color.TRANSPARENT,3)
	b._label(root,"正在点名中……",b._home_rect(49,184,232,22),11,ACCENT)
	b._panel(root,b._home_rect(34,207,356,1),LINE)
	b._label(root,"学在浙大",b._home_rect(34,213,180,22),11,MUTED)
	b._label(root,"本周缺勤",b._home_rect(274,213,64,22),10,MUTED)
	if b.s.flags.codeScattered and not b.s.flags.cardZeroTaken:
		var zero: Button=b._act(root,"0",b._home_rect(338,211,25,25),"c1_absence",null,Color("f5edcf"),INK,6,Color.TRANSPARENT); zero.name="CheckinAbsenceZero"; zero.add_theme_font_size_override("font_size",16)
	else:
		b._panel(root,b._home_rect(338,211,25,25),Color("eef2ee") if b.s.flags.cardZeroTaken else Color("f5edcf"),Color.TRANSPARENT,6)
		b._label(root,"0",b._home_rect(338,211,25,25),16,Color("8b9891") if b.s.flags.cardZeroTaken else INK,HORIZONTAL_ALIGNMENT_CENTER)
		if b.s.flags.cardZeroTaken:
			b._panel(root,b._home_rect(343,233,15,2),Color("d4ddd5")).name="CheckinAbsenceImprint"
	b._label(root,"次",b._home_rect(370,213,14,22),10,MUTED)
	b._label(root,"输入课堂签到码",b._home_rect(24,287,376,28),18,INK,HORIZONTAL_ALIGNMENT_CENTER)
	b._label(root,"请填写老师提供的四位数字",b._home_rect(24,322,376,22),12,MUTED,HORIZONTAL_ALIGNMENT_CENTER)
	var frames: Array=[]; var labels: Array=[]; var markers: Array=[]
	var ready_frame: Panel=b._panel(root,b._home_rect(59,354,306,86),Color.TRANSPARENT,ACCENT,14,1); ready_frame.name="CheckinReadyFrame"
	for i in range(4):
		var frame: Panel=b._panel(root,b._home_rect(66+i*77,361,63,72),Color.WHITE,LINE,10,1); frame.name="CheckinSlotFrame_"+str(i); frames.append(frame)
		var label: Label=b._label(root,"",b._home_rect(66+i*77,361,63,72),26,INK,HORIZONTAL_ALIGNMENT_CENTER); label.name="CheckinSlot_"+str(i); labels.append(label)
		var marker: Panel=b._panel(root,b._home_rect(96+i*77,389,2,18),ACCENT,Color.TRANSPARENT,1); marker.name="CheckinSlotMarker_"+str(i); markers.append(marker)
	b._label(root,"输入完成后，点击「签到」",b._home_rect(24,453,376,22),11,MUTED,HORIZONTAL_ALIGNMENT_CENTER)
	var error_label: Label=b._label(root,"签到码错误，请重新输入",b._home_rect(24,482,376,25),12,ERROR,HORIZONTAL_ALIGNMENT_CENTER); error_label.name="CheckinError"
	# One quiet keyboard surface, with the validated submit as the only dark key.
	b._panel(root,b._home_rect(0,545,424,309),Color("eef2eb"),Color.TRANSPARENT,18)
	b._label(root,"数字键盘",b._home_rect(24,548,376,22),10,MUTED)
	var submit_holder: Array=[]
	var update_form=func():
		for i in range(4):
			labels[i].text=code.substr(i,1) if i<code.length() else ""
			labels[i].add_theme_color_override("font_color",ERROR if error else INK)
			frames[i].add_theme_stylebox_override("panel",b._style(Color("edf5ee") if i<code.length() else Color.WHITE,ERROR if error else ACCENT if i==code.length() else LINE,10,1))
			markers[i].visible=i==code.length() and not error
		ready_frame.visible=code.length()==4; error_label.visible=error
		if not submit_holder.is_empty(): submit_holder[0].disabled=code.length()<4
	var keys=["1","2","3","4","5","6","7","8","9","⌫","0","签到"]
	for i in range(keys.size()):
		var key=str(keys[i]); var fill=ACCENT if key=="签到" else Color("e3eae2") if key=="⌫" else Color.WHITE
		var activate=func():
			if key=="签到":
				if code.length()<4: return
				submission_pending=true; b.action_requested.emit("c1_checkin",code); return
			if key=="⌫": code=code.left(maxi(0,code.length()-1)); error=false
			else:
				var index=mini(3,code.length()); error=false
				if code.length()<4:
					code+=key
					if not reduced: entry_pulse(b,root,key,index)
			update_form.call()
		var button: Button=b._button(root,key,b._home_rect(20+(i%3)*130,577+int(i/3)*66.8,124,56.8),activate,fill,Color.WHITE if key=="签到" else INK,10,Color.TRANSPARENT)
		button.name="CheckinSubmit" if key=="签到" else "CheckinKey_delete" if key=="⌫" else "CheckinKey_"+key
		button.add_theme_font_size_override("font_size",14 if key=="签到" else 23)
		if key=="签到":
			button.add_theme_stylebox_override("disabled",b._style(Color("dce5dc"),Color.TRANSPARENT,10))
			button.add_theme_color_override("font_disabled_color",Color("718677"))
			submit_holder.append(button)
	update_form.call()
	root.ready.connect(func():
		if not reduced:
			var pulse=live.create_tween().set_loops(); pulse.tween_property(live,"modulate:a",.45,.8); pulse.tween_property(live,"modulate:a",1.0,.8)
			if error:
				var shake=root.create_tween()
				for offset in [-3,3,-2,2,0]: shake.tween_property(root,"position:x",float(offset),.045))
	for id in ["c1_absence","c1_checkin"]:
		if not b.handled.has(id): b.handled.append(id)
	return root
func entry_pulse(b, root: Control, digit: String, index: int) -> void:
	var previous=root.get_node_or_null("CheckinEntryPulse")
	if previous: previous.free()
	var bounds: Rect2=b._home_rect(75+index*77,371,45,52)
	var pulse: Panel=b._panel(root,Rect2(bounds.position+Vector2(0,12)/b.PHONE_SCALE,bounds.size),ACCENT,Color.TRANSPARENT,8)
	pulse.name="CheckinEntryPulse"; pulse.z_index=4; b._label(pulse,digit,Rect2(Vector2.ZERO,pulse.size),24,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER)
	var tween=pulse.create_tween(); tween.tween_property(pulse,"position",bounds.position,.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT); tween.tween_property(pulse,"modulate:a",0.0,.16); tween.tween_callback(pulse.queue_free)
