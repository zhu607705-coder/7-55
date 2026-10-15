extends RefCounted
## Source RouteAuditPanel fields and evidence. All saved facts stay controller-owned.
const FIELDS=[
	{"id":"arrival","key":"auditArrivalMinutes","label":"到座耗时","unit":"分钟","min":0,"max":12,"default":5,"hint":"入口小屏 · 计算时间差"},
	{"id":"notice","key":"auditPublicNoticeFloor","label":"公示编号","unit":"号","min":1,"max":63,"default":45,"hint":"CC98 楼主编辑 · 读取编号"},
	{"id":"proofs","key":"auditProofCount","label":"证明数量","unit":"项","min":1,"max":5,"default":1,"hint":"旧版规则 · 统计类别"}
]
const LOCATIONS={"entrance":"图书馆入口","seat_022":"022","front_desk":"前台","lost_found":"失物招领","catalog_terminal":"馆藏检索","printer":"打印机","shelf_755":"书架背面"}
const INK=Color("23344b")
const MUTED=Color("4d6076")
const BLUE=Color("2467ac")
var draft: Dictionary={}
var observed: Dictionary={}
var bound_puzzle: Dictionary={}
var restore_name=""
var restore_caret=0

func reset() -> void:
	draft.clear(); observed.clear(); bound_puzzle={}; restore_name=""; restore_caret=0

func _sync(p: Dictionary) -> void:
	if not is_same(bound_puzzle,p):
		bound_puzzle=p; draft.clear(); observed.clear(); restore_name=""
	for field in FIELDS:
		var saved=int(p.get(field.key,0))
		if not observed.has(field.id) or int(observed[field.id])!=saved:
			# This mirrors the source's `saved || default` fallback. A fresh mount
			# cannot distinguish explicit arrival 0 from the original unset 0.
			draft[field.id]=str(saved if saved!=0 else field.default)
		observed[field.id]=saved

func _valid(text: String,field: Dictionary) -> bool:
	return text.is_valid_int() and int(text)>=field.min and int(text)<=field.max

func _edit(b,field: Dictionary,text: String,control: LineEdit) -> void:
	draft[field.id]=text
	if not _valid(text,field): return
	var number=int(text)
	if int(b.s.ui.libraryFinalsPuzzle[field.key])==number: return
	restore_name=control.name; restore_caret=control.caret_column
	observed[field.id]=number
	b.action_requested.emit("lib_audit_value",{"field":field.id,"value":number})

func _step(b,field: Dictionary,delta: int,focus_name: String) -> void:
	var current=int(draft[field.id]) if _valid(str(draft[field.id]),field) else int(field.default)
	var number=clampi(current+delta,field.min,field.max)
	if number==current: return
	draft[field.id]=str(number); observed[field.id]=number
	restore_name=focus_name; restore_caret=0
	b.action_requested.emit("lib_audit_value",{"field":field.id,"value":number})

func _restore(root: Control) -> void:
	if restore_name.is_empty(): return
	var control=root.find_child(restore_name,true,false)
	restore_name=""
	if not is_instance_valid(control) or control.is_queued_for_deletion() or not control.is_inside_tree(): return
	control.grab_focus()
	if control is LineEdit: control.caret_column=mini(restore_caret,control.text.length())

func _text(b,root: Control,text: String,rect: Rect2,size: int=14,color: Color=INK) -> Label:
	return b._label(root,text,rect,size,color)

func build(b) -> Control:
	var p: Dictionary=b.s.ui.libraryFinalsPuzzle
	_sync(p)
	var passed=bool(p.presenceProofCollected)
	var root: Control=b._base(Color("edf2f7"),1084)
	root.name="TiyiPresenceForm"
	if not b.handled.has("lib_audit"): b.handled.append("lib_audit")
	b._header(root,"浙大体艺",Color("3b79e9"),Color.WHITE,func(): b.page_requested.emit("phone_home"),"exit","退出浙大体艺，返回手机主页")
	b._panel(root,Rect2(38,67,326,125),Color.WHITE,Color("b8c9db"),8,1)
	_text(b,root,"补录成功" if passed else "本人来过证明补录单",Rect2(50,80,302,30),20,BLUE).name="TiyiPresenceTitle"
	_text(b,root,"系统已承认你确实来过图书馆" if passed else "待补录 · 先核对三项调查材料",Rect2(50,114,302,24),14,MUTED)
	_text(b,root,"已认证" if passed else "表单 022",Rect2(50,148,302,24),14,BLUE)
	var route: Array=["寝室"]
	for point in p.get("libraryVisitedPoints",[]):
		if LOCATIONS.has(point): route.append(LOCATIONS[point])
	b._panel(root,Rect2(38,203,326,77),Color("e3edf8"),Color("b8c9db"),8,1)
	_text(b,root,"检测到室内异常锻炼路线",Rect2(50,211,302,24),14,BLUE)
	_text(b,root," → ".join(route),Rect2(50,237,302,36),13,MUTED).name="TiyiRecordedRoute"
	var source_ready=bool(p.entranceRecordRead and p.investigationOpened and p.archivedRuleRead)
	var editable=str(b.s.ui.libraryFinalsPhase)=="evidence_gathering"
	if passed:
		_result(b,root,p)
	else:
		var controls: Array=[]
		for i in range(FIELDS.size()):
			var field: Dictionary=FIELDS[i]
			var y=292+i*83
			b._panel(root,Rect2(38,y,326,75),Color.WHITE,Color("b8c9db"),8,1)
			_text(b,root,field.label,Rect2(50,y+7,121,25),16)
			_text(b,root,"来源 %02d · %s" % [i+1,field.hint],Rect2(50,y+39,302,25),12,MUTED)
			var minus_name="TiyiMinus_"+field.id
			var minus: Button=b._button(root,"−",Rect2(181,y+7,39,32),func(): _step(b,field,-1,minus_name),Color("e7eff9"),BLUE,4,Color("87a4c6"))
			minus.name=minus_name; minus.tooltip_text=field.label+"减一"
			minus.disabled=not editable or (_valid(str(draft[field.id]),field) and int(draft[field.id])<=field.min)
			var input=LineEdit.new(); input.name="TiyiField_"+field.id; input.position=Vector2(226,y+7); input.size=Vector2(76,32)
			input.text=str(draft[field.id]); input.alignment=HORIZONTAL_ALIGNMENT_CENTER; input.virtual_keyboard_type=LineEdit.KEYBOARD_TYPE_NUMBER; input.editable=editable
			input.tooltip_text=field.label+"（"+field.unit+"）"; input.select_all_on_focus=false
			input.add_theme_font_size_override("font_size",16); input.add_theme_color_override("font_color",INK)
			input.add_theme_stylebox_override("normal",b._style(Color("f7faff"),Color("7994b4"),4,1))
			input.add_theme_stylebox_override("focus",b._style(Color.WHITE,BLUE,4,2))
			root.add_child(input); controls.append(input)
			input.text_changed.connect(func(text: String): _edit(b,field,text,input))
			var plus_name="TiyiPlus_"+field.id
			var plus: Button=b._button(root,"+",Rect2(308,y+7,39,32),func(): _step(b,field,1,plus_name),Color("e7eff9"),BLUE,4,Color("87a4c6"))
			plus.name=plus_name; plus.tooltip_text=field.label+"加一"
			plus.disabled=not editable or (_valid(str(draft[field.id]),field) and int(draft[field.id])>=field.max)
		var submit: Button=b._button(root,"提交补录",Rect2(14,549,350,44),func(): b.action_requested.emit("lib_audit",draft.duplicate()),BLUE,Color.WHITE,6,Color("194f86"))
		submit.name="TiyiPresenceSubmit"; submit.disabled=not source_ready or not editable
		controls.append(submit)
		for i in range(controls.size()):
			controls[i].focus_next=controls[i].get_path_to(controls[(i+1)%controls.size()])
			controls[i].focus_previous=controls[i].get_path_to(controls[posmod(i-1,controls.size())])
			if controls[i] is LineEdit:
				var next: Control=controls[i+1]
				controls[i].text_submitted.connect(func(_value): next.grab_focus())
		var attempts=int(p.auditAttemptCount)
		var hint="三项字段分别对应三份已保存的证据。" if source_ready else "先取得门禁记录、论坛公示与旧版规则。"
		if attempts>0:
			hint="补录参数与原始记录不一致。" if attempts==1 else "三项分别对应到座耗时、公示编号和旧规的证明数量。" if attempts==2 else "仍有字段与来源不一致。请重新核对三份原件。"
		_text(b,root,hint,Rect2(50,601,308,48),13,Color("8b352e") if attempts>0 else MUTED).name="TiyiPresenceFeedback"
	_sources(b,root,p)
	root.ready.connect(func(): _restore.call_deferred(root))
	return root

func _result(b,root: Control,p: Dictionary) -> void:
	b._panel(root,Rect2(38,294,326,344),Color("f4fbf5"),Color("55986a"),8,2)
	_text(b,root,"本人来过证明",Rect2(50,312,300,32),21,Color("236239")).name="TiyiPresenceResult"
	_text(b,root,"一张证明你来过的证明。它没有证明你为什么要来。",Rect2(50,355,300,56),14)
	for i in range(FIELDS.size()):
		var field: Dictionary=FIELDS[i]
		_text(b,root,"%s：%s %s" % [field.label,int(p[field.key]),field.unit],Rect2(50,426+i*37,300,30),16).name="TiyiReceipt_"+field.id
	b._button(root,"返回手机主页",Rect2(28,563,322,44),func(): b.page_requested.emit("phone_home"),BLUE,Color.WHITE,6,Color("194f86")).name="TiyiPresenceReturn"

func _sources(b,root: Control,p: Dictionary) -> void:
	_text(b,root,"三项材料从哪里取得",Rect2(50,668,308,28),17,BLUE)
	var entries=[
		["01 图书馆入口小屏 · 填写到座耗时","07:55 基础馆入口 → 08:02 一层书库 022\n填写两次记录的分钟差" if p.entranceRecordRead else "未取得 · 回到基础图书馆入口，查看门禁记录小屏"],
		["02 CC98 调查帖楼主编辑 · 填写公示编号","楼主编辑原文：旧申请统一挂在公示编号 %s\n23 是回复楼层；填写原文中的公示编号" % _notice_number() if p.investigationOpened else "未取得 · 在 022 座位拿到占座纸条，用它打开 CC98 调查帖"],
		["03 旧版规则 · 填写证明数量","本人确实到馆；目标座位与凭据一致；当前占用物不具备本人身份。\n填写规则列出的证明类别数量" if p.archivedRuleRead else "未取得 · 在一层书库 755 书架使用“索书号 755”，取得并阅读规则"]
	]
	for i in range(entries.size()):
		var y=706+i*117
		b._panel(root,Rect2(38,y,326,105),Color.WHITE,Color("b8c9db"),8,1)
		_text(b,root,entries[i][0],Rect2(50,y+8,302,30),14,BLUE)
		_text(b,root,entries[i][1],Rect2(50,y+40,302,58),13,MUTED).name="TiyiEvidence_"+str(i)

func _notice_number() -> String:
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/library-finals.content.json"))
	return str(int(data.get("cc98",{}).get("post",{}).get("publicNoticeFloor",0))) if data is Dictionary else ""
