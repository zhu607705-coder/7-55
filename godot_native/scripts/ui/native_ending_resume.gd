extends RefCounted
## Illustrated continuation surface only. The controller owns eligibility,
## save facts and the same six-contact interception; art never supplies proof.
const Flow = preload("res://scripts/games/prologue_character_flow.gd")
const HERO_PATH = "res://assets/native/ending_resume/terminal_signal_20261022.png"

func build(b) -> Control:
	var root: Control = b._base(Flow.BACKGROUND,854.0/b.PHONE_SCALE)
	root.name = "EndingResumePage"
	var eligible: bool = b.s.get("flags",{}).get("checkinDone",false) and b.s.get("actOne",{}).get("phase","")=="prologue"
	root.set_meta("handles_all_actions",true)
	# A single portrait composition. Text remains native and legible at phone
	# scale; the generated illustration contains no interface labels/hit areas.
	b._panel(root,Rect2(26,29,3,14),Flow.ACCENT if eligible else Flow.MUTED)
	b._label(root,"未完成的拦截" if eligible else "没有待继续的拦截",Rect2(39,23,266,26),14,Flow.MUTED).name="EndingResumeCaption"
	b._label(root,"07:55",Rect2(291,23,61,26),14,Flow.MUTED,HORIZONTAL_ALIGNMENT_RIGHT)
	b._panel(root,Rect2(26,65,326,1),Flow.RULE)
	b._label(root,"经度与纬度\n不存在",Rect2(26,96,326,100),32,Flow.INK).name="EndingResumeTitle"
	b._label(root,"签到码已提交" if eligible else "当前没有待继续的拦截",Rect2(27,207,324,28),15,Flow.ACCENT if eligible else Flow.MUTED).name="EndingResumeStatus"
	var art := TextureRect.new()
	art.name="EndingResumeArt"
	art.position=Vector2(0,245);art.size=Vector2(378,252)
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	art.texture=load(HERO_PATH)
	if not eligible:art.modulate=Color(1,1,1,.4)
	root.add_child(art)
	b._panel(root,Rect2(26,519,326,1),Flow.RULE)
	b._label(root,"这段交涉尚未完成" if eligible else "信号暂未接续",Rect2(26,536,326,32),19,Flow.INK).name="EndingResumeContext"
	b._label(root,"已找回的签到码会保留。\n继续后重启本轮拦截。" if eligible else "完成课堂签到后，再从这里继续。",Rect2(26,577,326,49),14,Flow.MUTED).name="EndingResumeSaveNote"
	# Instructions replace the vignette only when explicitly requested. No
	# shifted phone frame or persistent solution on entry.
	var instructions: Control = b._panel(root,Rect2(26,265,326,210),Flow.PANEL,Flow.RULE,0,1)
	instructions.name="EndingResumeInstructions";instructions.visible=false
	b._label(instructions,"操作方式",Rect2(20,20,286,28),17,Flow.INK)
	b._panel(instructions,Rect2(20,62,286,1),Flow.RULE)
	b._label(instructions,"拖动错误窗口\n或使用 A/D、←/→ 移动\n\n挡住旁白的离场路径",Rect2(20,77,286,113),16,Flow.INK)
	var continuing := [false]
	var next: Button = b._button(root,"继续拦住旁白",Rect2(26,646,326,54),func():
		if continuing[0]:return
		continuing[0]=true
		b.action_requested.emit("c1_resume_ending",null),Flow.ACCENT,Flow.BACKGROUND,0,Flow.ACCENT)
	next.name="EndingResumeContinue";next.disabled=not eligible
	next.add_theme_font_size_override("font_size",18)
	next.tooltip_text="继续本轮拦截"
	var explanation: Button=b._button(root,"操作方式",Rect2(26,707,326,36),func():
		instructions.visible=not instructions.visible
		art.visible=not instructions.visible,Color.TRANSPARENT,Flow.MUTED,0,Color.TRANSPARENT)
	explanation.name="EndingResumeReview"
	explanation.add_theme_font_size_override("font_size",14)
	explanation.tooltip_text="查看或收起操作方式"
	next.focus_neighbor_bottom=next.get_path_to(explanation)
	explanation.focus_neighbor_top=explanation.get_path_to(next)
	b.handled.append("c1_resume_ending")
	return root
