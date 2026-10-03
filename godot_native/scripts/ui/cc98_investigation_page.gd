extends RefCounted
## CC98's existing investigation and four source evidence slots. Layout and local
## navigation only: every accepted upload remains an ordinary controller intent.
const FONT=preload("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
const DropButton=preload("res://scripts/ui/phone_drop_button.gd")
const Library=preload("res://scripts/chapters/library022.gd")
const SOURCE="res://data/source/library-finals.content.json"
const LEFT=48.0
const WIDTH=315.0
const BLUE=Color("337e9b")
const MUTED=Color("637080")
const BD_PHASES=["top_ten_rising","top_ten_reached","recovery_application","pass_ready","backpack_removed","seat_recovered","friend_contacted"]
const BD_POSTS={24:"bd-notice-tens",25:"bd-rule-count",26:"bd-rank-first",27:"bd-identity-zero",28:"bd-call-number-tail",29:"bd-seat-tail",30:"bd-reply-count",31:"bd-arrival-minutes"}
var feedback_text=""

func reset() -> void:
	feedback_text=""

func height(text: String,width: float,font_size: int) -> float:
	# Match Label's word-smart wrap with the actual native font, including newlines.
	return ceil(FONT.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,width,font_size,-1,TextServer.BREAK_MANDATORY|TextServer.BREAK_WORD_BOUND|TextServer.BREAK_ADAPTIVE).y)+4

func label(b,root: Control,text: String,y: float,font_size: int=17,color: Color=Color("222322"),width: float=WIDTH,x: float=LEFT) -> Label:
	var node: Label=b._label(root,text,Rect2(x,y,width,height(text,width,font_size)),font_size,color)
	node.vertical_alignment=VERTICAL_ALIGNMENT_TOP
	node.add_theme_font_override("font",FONT)
	return node

func floor_title(row: Dictionary) -> String:
	var title=str(row.get("title",""))
	var separator=title.find(" · ")
	return "%d楼 · %s" % [int(title.get_slice(" ",0)),title.substr(separator+3)] if separator>=0 else title

func scroll_to(target: Control) -> void:
	var ancestor: Node=target.get_parent()
	while ancestor!=null:
		if ancestor is ScrollContainer:
			var scale_y=ancestor.get_global_transform_with_canvas().get_scale().y
			ancestor.scroll_vertical+=ceili((target.get_global_rect().position.y-ancestor.get_global_rect().position.y)/scale_y)
			return
		ancestor=ancestor.get_parent()

func bd_order(selected: Array) -> String:
	# Show only the player's saved choices. No answer order or digit is inferred.
	var floors: PackedStringArray=[]
	for id in selected:
		for number in BD_POSTS:
			if BD_POSTS[number]==id: floors.append(str(number))
	while floors.size()<4: floors.append("—")
	return "已选顺序（楼）："+" → ".join(floors)

func build(b,view: Dictionary) -> Control:
	var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SOURCE)).cc98
	var puzzle: Dictionary=b.s.ui.libraryFinalsPuzzle
	var uploaded: Array=puzzle.cc98UploadedEvidenceIds
	var show_bd=uploaded.size()==4 and b.s.ui.libraryFinalsPhase in BD_PHASES
	var root: Control=b._base(Color("f2f3f5"),b.APP_HEIGHT)
	root.name="Cc98Investigation"
	b._panel(root,Rect2(0,0,378,57),Color("297b9b"))
	b._label(root,"CC98",Rect2(17,4,154,48),33,Color.WHITE)
	b._label(root,"热门话题　　校园生活　　二手市场",Rect2(13,67,352,36),15,Color("457d94"),HORIZONTAL_ALIGNMENT_CENTER)
	b._panel(root,Rect2(0,111,378,3),Color("50a0b5"))
	var title=label(b,root,str(view.get("title","")),128,21)
	title.name="Cc98InvestigationTitle"
	var y=title.position.y+title.size.y+16
	var summary=str(view.get("body","")) if show_bd else str(view.get("post",source.post).get("body",""))+"\n已上传 %d / 4 项" % uploaded.size()
	var summary_height=height(summary,WIDTH,17)+24
	b._panel(root,Rect2(LEFT-8,y,WIDTH+16,summary_height),Color.WHITE,Color("d1d6dc"),0,1)
	label(b,root,summary,y+12).name="Cc98InvestigationSummary"
	y+=summary_height+12
	var upload_jump: Button=b._button(root,"楼主证据上传区 ↓",Rect2(LEFT,y,WIDTH,44),func():
		var target=root.get_node_or_null("Cc98EvidenceUploader")
		if target: scroll_to(target),Color("e7eef1"),BLUE)
	upload_jump.name="Cc98EvidenceJump"
	y+=60
	var selected: Array=puzzle.bdSelectedPostIds
	var order_height=maxf(height(bd_order([]),WIDTH,13),height(bd_order(BD_POSTS.values().slice(0,4)),WIDTH,13))
	if b.s.ui.libraryFinalsPhase=="top_ten_rising":
		var review=label(b,root,bd_order(selected),y,13,BLUE)
		review.name="Cc98BdReview"
		y+=review.size.y+10
		var undo: Button=b._act(root,"撤回最后一次 bd",Rect2(LEFT,y,151,44),"lib_bd_undo",null,Color("e7eef1"))
		undo.name="Cc98BdUndo"; undo.disabled=selected.is_empty()
		b._act(root,"核验热度口令",Rect2(LEFT+161,y,154,44),"lib_bd_submit",null,Color("cee2e8")).name="Cc98BdSubmit"
		y+=54
		b._button(root,"阅读数字回复 ↓",Rect2(LEFT,y,WIDTH,44),func():
			var target=root.get_node_or_null("Cc98ReplyPanel_24")
			if target: scroll_to(target),Color("e7eef1"),BLUE).name="Cc98BdRepliesJump"
		y+=60
	var bd=BD_POSTS
	for row: Dictionary in view.get("rows",[]):
		var floor_number=int(str(row.get("title","")).get_slice(" ",0))
		if bd.has(floor_number) and not show_bd: continue
		var hidden_bd=not show_bd and str(row.get("body","")).to_lower().contains("bd")
		var has_catalog_title=not b.earned_catalog_title.title_for_reply(b.s,row).is_empty()
		var heading=floor_title(row)
		if hidden_bd: heading="%d楼 · xxx" % floor_number
		var body="xxx" if hidden_bd else str(row.get("body","")).strip_edges()
		var heading_height=height(heading,WIDTH,16)
		var body_height=height(body,WIDTH,17)
		var selectable_bd=bd.has(floor_number) and b.s.ui.libraryFinalsPhase=="top_ten_rising"
		var row_height=12+heading_height+14+body_height+18+(68+order_height if selectable_bd else 60 if has_catalog_title else 0)
		var panel: Panel=b._panel(root,Rect2(LEFT-8,y,WIDTH+16,row_height),Color.WHITE,Color("dce1e5"),0,1)
		panel.name="Cc98ReplyPanel_%d" % floor_number
		label(b,root,heading,y+12,16,BLUE).name="Cc98ReplyTitle_%d" % floor_number
		label(b,root,body,y+12+heading_height+14).name="Cc98ReplyBody_%d" % floor_number
		var action_y=y+row_height-64
		if has_catalog_title:
			var feedback=label(b,root,"可在馆藏检索中手动粘贴",action_y,13,MUTED,WIDTH-104,LEFT+104)
			feedback.name="Cc98CatalogTitleFeedback"
			var copy: Button=b._button(root,"复制题名",Rect2(LEFT,action_y,92,48),func():
				feedback.text=b.earned_catalog_title.copy_reply_title(b.s,row),Color("e8f0f4"),Color("367d99"),2,Color("86b1c4"))
			copy.name="Cc98CopyCatalogTitle"; copy.tooltip_text="将本楼题名复制到剪贴板"
		if selectable_bd:
			label(b,root,bd_order(selected),action_y-order_height-8,13,MUTED).name="Cc98BdOrder_%d" % floor_number
			var order=selected.find(bd[floor_number])
			var select: Button=b._act(root,"已选第%d项" % (order+1) if order>=0 else "bd",Rect2(LEFT,action_y,99,44),"lib_bd_select",bd[floor_number],Color("cee2e8") if order>=0 else Color("e8f0f4"),BLUE,2,Color("86b1c4"))
			select.name="Cc98BdSelect_%d" % floor_number; select.disabled=order>=0
			if order>=0: select.add_theme_color_override("font_disabled_color",Color("245568"))
			var undo: Button=b._act(root,"撤回末项",Rect2(LEFT+107,action_y,99,44),"lib_bd_undo",null,Color("e7eef1"),BLUE)
			undo.name="Cc98BdUndo_%d" % floor_number; undo.disabled=selected.is_empty()
			b._button(root,"复核所选 ↑",Rect2(LEFT+214,action_y,101,44),func():
				var target=root.get_node_or_null("Cc98BdReview")
				if target: scroll_to(target),Color("e7eef1"),BLUE).name="Cc98BdReview_%d" % floor_number
		y+=row_height+8
	y+=8
	var uploader=Control.new(); uploader.name="Cc98EvidenceUploader"; uploader.position=Vector2(LEFT,y); uploader.size=Vector2(WIDTH,44); uploader.mouse_filter=Control.MOUSE_FILTER_IGNORE; root.add_child(uploader)
	label(b,root,"楼主编辑：上传证据",y,19,BLUE).name="Cc98EvidenceHeading"
	y+=height("楼主编辑：上传证据",WIDTH,19)+8
	label(b,root,"证据完整度：%d/4" % uploaded.size(),y,14,MUTED).name="Cc98EvidenceCount"
	y+=height("证据完整度：0/4",WIDTH,14)+12
	var feedback=label(b,root,feedback_text,y+source.evidenceSlots.size()*112+8,14,Color("963f36"))
	feedback.name="Cc98EvidenceFeedback"; feedback.size.y=height("这个槽位需要对应名称的纸质材料。",WIDTH,14)
	# Suppress only the generic upload dropdown. Other fold/briefing actions keep
	# their original consumers and controller gates.
	if not b.handled.has("lib_upload"): b.handled.append("lib_upload")
	for evidence: Dictionary in source.evidenceSlots:
		var id=str(evidence.id); var item=str(Library.EVIDENCE[id])
		var done=uploaded.has(id); var owned=bool(b.s.items.get(item,false))
		var slot=DropButton.new(); slot.name="Cc98EvidenceSlot_"+id; slot.position=Vector2(LEFT,y); slot.size=Vector2(WIDTH,104); slot.focus_mode=Control.FOCUS_NONE
		for mode in ["normal","hover","pressed","disabled"]: slot.add_theme_stylebox_override(mode,b._style(Color("edf4ec") if done else Color.WHITE,Color("bfcbd0"),0,1))
		root.add_child(slot)
		slot.item_dropped.connect(func(dropped):
			if dropped!=item:
				feedback_text="这个槽位需要对应名称的纸质材料。"; feedback.text=feedback_text
			else:
				feedback_text=""; feedback.text=""; b.action_requested.emit("lib_upload",id))
		b._source_icon(slot,item,Rect2(12,32,32,32))
		# The source's leading material icon can sit behind the expanded drawer;
		# the material name, provenance and upload action stay to its right.
		label(b,slot,str(evidence.label),12,16,BLUE,WIDTH-146,62).name="EvidenceLabel"
		label(b,slot,str(evidence.source),48,14,MUTED,WIDTH-146,62).name="EvidenceSource"
		var upload: Button=b._button(slot,"已上传" if done else "上传" if owned else "未获得",Rect2(WIDTH-80,30,68,44),func(): feedback_text=""; b.action_requested.emit("lib_upload",id),Color("e7eef1"),BLUE)
		upload.name="Cc98EvidenceUpload_"+id
		upload.disabled=done or not owned or b.s.ui.libraryFinalsPhase!="evidence_gathering"
		# The entire named material row remains a drop surface, including the
		# ordinary button area; click/keyboard activation still uses that button.
		upload.mouse_filter=Control.MOUSE_FILTER_PASS
		y+=112
	y+=feedback.size.y+24
	root.custom_minimum_size.y=maxf(b.APP_HEIGHT,y); root.size.y=root.custom_minimum_size.y
	return root
