extends RefCounted
## Native phone view. Renders only authentic captured PNGs, never substitutes maps
## or recovery/evidence photographs for a missing journal capture.
signal action_requested(id: String, value: Variant)
signal page_requested(page: String)
const NativeUi=preload("res://scripts/ui/native_ui_theme.gd")
const Journal=preload("res://scripts/chapters/c3_journal.gd")
var module: RefCounted=Journal.new()
var state: Dictionary={}
const INK=Color("182631")
const MUTED=Color("667b87")
const BLUE=Color("30759d")

func build(page: String, view: Dictionary, s: Dictionary) -> Control:
	if page not in ["c3_journal","c3_journal_camera"]: return null
	state=s
	var outer: PanelContainer=PanelContainer.new()
	outer.set_meta("handles_all_actions",true)
	outer.set_meta("source_page",true)
	outer.set_meta("journal_page",page)
	outer.custom_minimum_size.x=0
	outer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var style: StyleBoxFlat=StyleBoxFlat.new()
	style.bg_color=Color("eff3f5")
	style.content_margin_left=14
	style.content_margin_right=14
	style.content_margin_top=10
	style.content_margin_bottom=22
	outer.add_theme_stylebox_override("panel",style)
	var root: VBoxContainer=VBoxContainer.new()
	root.add_theme_constant_override("separation",12)
	root.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	outer.add_child(root)
	var header: HBoxContainer=HBoxContainer.new()
	root.add_child(header)
	button(header,"‹",func() -> void:
		if page=="c3_journal_camera": action_requested.emit("c3_journal_close",null)
		else: page_requested.emit("phone_home")
	)
	var heading: VBoxContainer=VBoxContainer.new()
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	label(heading,"相机" if page=="c3_journal_camera" else "CC98 · 校园生活",12,MUTED)
	label(heading,str(module.journal_copy().camera.title) if page=="c3_journal_camera" else "启真湖划船记录",21)
	if page=="c3_journal_camera": camera(root)
	else: thread(root,view)
	return outer

func label(parent: Control, text: String, size_value: int=17, color: Color=INK) -> Label:
	var node: Label=Label.new()
	node.text=text
	node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	node.add_theme_font_size_override("font_size",size_value)
	node.add_theme_color_override("font_color",color)
	parent.add_child(node)
	return node

func button(parent: Control, text: String, callback: Callable) -> Button:
	var node: Button=Button.new()
	node.text=text
	node.custom_minimum_size.y=44
	node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	NativeUi.apply_button(node,Color("fffaf0"),INK,Color("718792"),0,1,16,Vector2(12,8),BLUE)
	node.pressed.connect(callback)
	parent.add_child(node)
	return node

func action(parent: Control, text: String, id: String, value: Variant=null) -> Button:
	return button(parent,text,func() -> void: action_requested.emit(id,value))

func card(parent: Control) -> VBoxContainer:
	var panel: PanelContainer=PanelContainer.new()
	var style: StyleBoxFlat=StyleBoxFlat.new()
	style.bg_color=Color.WHITE
	style.border_color=Color("d4dfe4")
	style.set_border_width_all(1)
	style.content_margin_left=12
	style.content_margin_right=12
	style.content_margin_top=12
	style.content_margin_bottom=12
	panel.add_theme_stylebox_override("panel",style)
	parent.add_child(panel)
	var box: VBoxContainer=VBoxContainer.new()
	box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",9)
	panel.add_child(box)
	return box

func photo(parent: Control, record: Variant, height_value: float=190) -> void:
	if not record is Dictionary: return
	var captured: Image=module.image_for(record)
	if captured==null:
		if module.validate_photo_record(record):
			var frame: Control=load("res://scripts/ui/qizhen_recipe_frame.gd").new()
			frame.custom_minimum_size=Vector2(320,height_value); frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			frame.set_meta("source_recipe_photo",record.id)
			parent.add_child(frame); frame.configure(record.recipe,height_value<160)
			if record.has("nativeImagePath"): label(parent,"原始截图缺失，已按保存的取景信息重建。",12,MUTED)
		else: label(parent,"这张照片的取景信息未能读取。",14,MUTED)
		return
	var node: TextureRect=TextureRect.new()
	node.texture=ImageTexture.create_from_image(captured)
	node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.custom_minimum_size.y=height_value
	node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	node.set_meta("actual_journal_photo",record.id)
	parent.add_child(node)

func selector(parent: Control, heading: String, entries: Array, selected_id: Variant) -> OptionButton:
	label(parent,heading,15,MUTED)
	var select: OptionButton=OptionButton.new()
	select.custom_minimum_size.y=42
	select.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	select.clip_text=true
	select.add_theme_font_size_override("font_size",15)
	select.add_item("请选择")
	select.set_item_metadata(0,null)
	for entry: Dictionary in entries:
		select.add_item(str(entry.text))
		select.set_item_metadata(select.item_count-1,entry.id)
		if entry.id==selected_id: select.select(select.item_count-1)
	parent.add_child(select)
	return select

func camera(root: Control) -> void:
	var j: Dictionary=state.qizhenLake.journal
	var copy: Dictionary=module.journal_copy()
	if j.status=="archived":
		label(root,copy.thread.archivedNotice)
		return
	if state.qizhenLake.phase=="swan_chase":
		label(root,"黑天鹅正追着船尾,顾不上拍照。")
		return
	var draft: Variant=j.get("pendingDraft")
	if draft is Dictionary:
		var review: VBoxContainer=card(root)
		label(review,str(copy.spotNames.get(draft.photo.spotId,"")),15,BLUE)
		photo(review,draft.photo,205)
		var tags: Array=[]
		for tag: String in draft.photo.tags: tags.append(str(copy.tagLabels.get(tag,tag)))
		label(review," · ".join(tags),14,MUTED)
		var form: VBoxContainer=card(root)
		if draft.kind=="main":
			var title: OptionButton=selector(form,copy.camera.draftMainTitle,copy.titles,draft.titleId)
			var status: OptionButton=selector(form,copy.camera.draftMainStatus,copy.statuses,draft.statusId)
			var save: Button=button(form,copy.camera.saveDraft,func() -> void: action_requested.emit("c3_journal_draft",{"titleId":title.get_item_metadata(title.selected),"statusId":status.get_item_metadata(status.selected)}))
			save.disabled=title.selected==0 or status.selected==0
			title.item_selected.connect(func(_index: int) -> void: save.disabled=title.selected==0 or status.selected==0)
			status.item_selected.connect(func(_index: int) -> void: save.disabled=title.selected==0 or status.selected==0)
		elif copy.spotCaptions.has(draft.photo.spotId):
			var caption: OptionButton=selector(form,copy.camera.draftSpotCaption,copy.spotCaptions[draft.photo.spotId],draft.captionId)
			var save: Button=button(form,copy.camera.saveDraft,func() -> void: action_requested.emit("c3_journal_draft",{"captionId":caption.get_item_metadata(caption.selected)}))
			save.disabled=caption.selected==0
			caption.item_selected.connect(func(_index: int) -> void: save.disabled=caption.selected==0)
		action(root,copy.camera.retake,"c3_journal_retake")
	else:
		label(root,copy.camera.hint,16,MUTED)
		var p: Vector2=module.player_point(state)
		var spot: String=module.resolve_spot(str(state.qizhenLake.zone),p)
		label(root,str(copy.spotNames.get(spot,"当前还不在拍摄位置")),19)
		action(root,copy.camera.shutter,"c3_photo")
	action(root,copy.camera.close,"c3_journal_close")
	action(root,copy.thread.returnToLake,"c3_journal_return")

func thread(root: Control, view: Dictionary) -> void:
	var copy: Dictionary=module.journal_copy()
	var projected: Dictionary=view.get("thread",module.project_thread(state.qizhenLake.journal,state.qizhenLake))
	if projected.archived: label(root,copy.thread.archivedNotice,15,MUTED)
	label(root,projected.title,22)
	var main: VBoxContainer=card(root)
	label(main,"楼主 · 1 楼",14,BLUE)
	photo(main,projected.mainPhoto)
	label(main,projected.mainCaption)
	label(main,projected.statusText,14,MUTED)
	var owner_only: bool=bool(view.get("ownerOnly",false))
	action(root,copy.thread.showAll if owner_only else copy.thread.ownerOnly,"c3_journal_filter")
	for reply: Dictionary in projected.replies:
		if owner_only and reply.kind!="owner": continue
		var box: VBoxContainer=card(root)
		label(box,"%s · %d 楼" % [module.persona_name(reply.personaId),int(reply.floor)],14,BLUE)
		photo(box,reply.photo,155)
		label(box,reply.text)
		label(box,"♡ "+str(reply.likes),12,MUTED)
	for command: Dictionary in module.actions("c3_journal",state):
		if command.id=="c3_journal_filter" or command.id=="c3_journal_return": continue
		action(root,command.label,command.id)
	if not projected.archived:
		button(root,"打开相机",func() -> void: page_requested.emit("c3_journal_camera"))
	action(root,copy.thread.returnToLake,"c3_journal_return")
