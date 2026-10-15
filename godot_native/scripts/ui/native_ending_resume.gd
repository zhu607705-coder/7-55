extends RefCounted
## Restores context after an ordinary reload; the existing controller still starts
## the source blackout/interception and validates every catch, hold and dialogue.
func build(b) -> Control:
	var root: Control = b._base(Color("18222e"),854.0/b.PHONE_SCALE)
	root.name = "EndingResumePage"
	var eligible: bool = b.s.get("flags",{}).get("checkinDone",false) and b.s.get("actOne",{}).get("phase","")=="prologue"
	root.set_meta("handles_all_actions",true)
	b._label(root,"未完成的拦截" if eligible else "没有待继续的拦截",Rect2(24,28,330,32),18,Color("d2dfe9"),HORIZONTAL_ALIGNMENT_CENTER)
	b._panel(root,Rect2(24,90,330,186),Color("f4e9dc"),Color("bf5861"),0,3)
	b._label(root,"经度与纬度不存在",Rect2(38,108,302,38),23,Color("663039"),HORIZONTAL_ALIGNMENT_CENTER)
	b._label(root,"签到码已提交\n这段交涉尚未完成" if eligible else "当前没有待继续的拦截",Rect2(46,166,286,68),18,b.INK,HORIZONTAL_ALIGNMENT_CENTER)
	b._label(root,"拦住旁白，与他交涉",Rect2(30,315,318,40),22,Color("fff3cc"),HORIZONTAL_ALIGNMENT_CENTER)
	b._label(root,"已找回的签到码会保留。\n继续后重启本轮拦截。",Rect2(34,369,310,66),16,Color("cad8e3"),HORIZONTAL_ALIGNMENT_CENTER)
	var instructions: Control = b._panel(root,Rect2(28,496,322,104),Color("253343"),Color("617588"),0,2)
	instructions.name = "EndingResumeInstructions"; instructions.visible=false
	b._label(instructions,"拖动错误窗口，或 A/D、←/→\n挡住旁白的离场路径",Rect2(16,14,290,76),16,Color("edf3f5"),HORIZONTAL_ALIGNMENT_CENTER)
	var explanation: Button = b._button(root,"重看操作",Rect2(99,444,180,44),func(): instructions.visible=not instructions.visible,Color("253343"),Color("edf3f5"),0,Color("879aa9"))
	explanation.name = "EndingResumeReview"
	var continuing := [false]
	var next: Button = b._button(root,"继续拦住旁白",Rect2(45,625,288,58),func():
		if continuing[0]: return
		continuing[0] = true
		b.action_requested.emit("c1_resume_ending",null),Color("b64e5b"),Color.WHITE,0,Color("e7a8b0"))
	next.name = "EndingResumeContinue"
	next.disabled = not eligible
	next.add_theme_font_size_override("font_size",18)
	b.handled.append("c1_resume_ending")
	return root
