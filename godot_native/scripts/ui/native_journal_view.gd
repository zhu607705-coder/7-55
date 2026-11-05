extends VBoxContainer
## Read-only task presentation. Authored objectives, earned logs and all return
## actions stay controller-owned; opening or folding this view grants nothing.
signal resume_requested
signal comparison_requested
const PhoneOverlay=preload("res://scripts/ui/phone_overlay_shell.gd")
var phone_builder: RefCounted
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const Typography=preload("res://scripts/ui/native_typography.gd")
const INK:=Ui.INK
const MUTED:=Color("625b50")
const BACKGROUND:=Color("e9e5da") # Existing phone_pages._controls panel.
const SURFACE:=Color("fff4d8") # Existing phone_pages.PAPER controls.
const LINE:=Color("b6ad98")
const ACCENT:=INK
var context_texture: Texture2D
var objective: String
var detail: String
var entries: Array=[]
var comparison_available:=false
var digit_slots: Array[String]=[]
var return_label: String="返回游戏"
var resume_button: Button
var history: VBoxContainer
var history_toggle: Button

func _init() -> void:
	# This is shared phone/task chrome even when opened over the world. The
	# presentation registry must not reapply its retired raised key material.
	set_meta("phone_ui_scope",true)

func configure(title: String, next_step: String, log: Array, can_compare: bool, in_world: bool) -> void:
	objective=title;detail=next_step;entries=log.duplicate(true);comparison_available=can_compare
	return_label="返回现场" if in_world else "返回游戏"

func configure_digits(snapshot: Dictionary) -> void:
	# Copy only already-earned values, in source order. Unknown slots are masked;
	# no derivation, unlock or save mutation belongs to this presentation.
	digit_slots.clear()
	if int(snapshot.get("native",{}).get("chapter",1))!=1 or snapshot.get("actOne",{}).get("phase","")!="prologue":return
	var digits: Dictionary=snapshot.get("digits",{})
	var any_known:=false
	for key: String in ["d1","d2","d3","d4"]:
		var value: Variant=digits.get(key)
		var known: bool=value!=null and not str(value).is_empty()
		any_known=any_known or known
		digit_slots.append(str(value) if known else "?")
	if not bool(snapshot.get("flags",{}).get("codeScattered",false)) and not any_known:digit_slots.clear()

static func style_modal(panel: PanelContainer, title: Label, close: Button, scroll: ScrollContainer) -> void:
	panel.set_meta("phone_ui_scope",true)
	panel.set_meta("flat_task_surface",true)
	panel.add_theme_stylebox_override("panel",paper_box(BACKGROUND,INK,2,Vector2(14,14)))
	style_label(title,18,INK,true)
	style_button(close,false)
	close.size_flags_horizontal=Control.SIZE_SHRINK_END
	var divider:=HSeparator.new();divider.name="JournalPageRule"
	divider.mouse_filter=Control.MOUSE_FILTER_IGNORE
	divider.add_theme_constant_override("separation",2)
	divider.add_theme_stylebox_override("separator",paper_box(INK,Color.TRANSPARENT,0,Vector2(0,1)))
	var column:=scroll.get_parent()
	column.add_child(divider);column.move_child(divider,scroll.get_index())
	scroll.name="JournalScroll"
	scroll.follow_focus=true
	scroll.scroll_deadzone=8
	var rail:=scroll.get_v_scroll_bar()
	rail.custom_minimum_size.x=8
	rail.add_theme_stylebox_override("scroll",paper_box(Color.TRANSPARENT,Color.TRANSPARENT,0,Vector2(4,0)))
	for state: String in ["grabber","grabber_highlight","grabber_pressed"]:
		rail.add_theme_stylebox_override(state,paper_box(MUTED if state=="grabber" else INK,Color.TRANSPARENT,0,Vector2(4,0)))

static func paper_box(fill: Color, border: Color=INK, width: int=2, padding: Vector2=Vector2.ZERO) -> StyleBoxFlat:
	# Match the existing phone controls and notices: shared four-pixel corners,
	# two-step pixel contour and no extra elevation. Do not invent a square theme.
	return Ui.box(fill,border,width,0,padding)

static func style_label(control: Control, px: int=14, ink: Color=INK, heading:=false) -> void:
	control.add_theme_font_override("font",Typography.display_font() if heading else Typography.body_font())
	control.add_theme_font_size_override("font_size",px)
	control.add_theme_color_override("font_color",ink)
	control.add_theme_color_override("font_shadow_color",Color.TRANSPARENT)
	control.add_theme_constant_override("outline_size",0)
	control.add_theme_constant_override("shadow_outline_size",0)
	control.add_theme_constant_override("shadow_offset_x",0)
	control.add_theme_constant_override("shadow_offset_y",0)
	control.add_theme_constant_override("line_spacing",4)
	Ui.enable_scale_aware_text(control)

static func style_button(button: Button, primary:=false) -> void:
	if not button.has_meta("phone_button_role"):button.set_meta("phone_button_role","action")
	Ui.apply_button(button,Ui.PAPER_ALT if primary else SURFACE,INK,INK,0,2,14,Vector2(12,10),INK)
	for mode: String in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
		var face:=button.get_theme_stylebox(mode) as StyleBoxFlat
		if mode=="focus":
			# A black outline alone would disappear on the normal black edge.
			# Keep keyboard focus visible as a heavier ink underline, without
			# introducing a mismatched blue ring or changing the hit rectangle.
			face.set_border_width_all(0);face.border_width_bottom=4
	style_label(button,14,INK)
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND

func _ready() -> void:
	name="NativeJournal"
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",12)
	if phone_builder!=null:
		_build_phone_sections()
		return
	var current:=_label("当前任务","JournalCurrentHeading","tip")
	current.add_theme_color_override("font_color",ACCENT)
	add_child(current)
	add_child(_label(objective,"JournalObjective","heading"))
	if not detail.is_empty() or not digit_slots.is_empty():
		add_child(_label("当前进度","JournalProgressHeading","tip"))
		if not detail.is_empty():add_child(_label(detail,"JournalNextStep","body"))
		if not digit_slots.is_empty():
			add_child(_label("签到码","JournalDigitsHeading","tip"))
			var slots:=HBoxContainer.new();slots.name="JournalDigitProgress"
			slots.add_theme_constant_override("separation",8)
			for index in digit_slots.size():
				var digit:=_label(digit_slots[index],"JournalDigitSlot%d"%index,"heading")
				digit.custom_minimum_size=Vector2(44,44)
				digit.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
				digit.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
				digit.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
				var known: bool=digit_slots[index]!="?"
				digit.add_theme_color_override("font_color",ACCENT if known else MUTED)
				var slot_style:=paper_box(Ui.PAPER_ALT if known else SURFACE,INK,2)
				slot_style.border_width_bottom=3 if known else 2
				digit.add_theme_stylebox_override("normal",slot_style)
				slots.add_child(digit)
			add_child(slots)
	resume_button=_button(return_label,"JournalResume",func(): resume_requested.emit(),true)
	add_child(resume_button)
	if comparison_available:
		add_child(_rule("JournalComparisonRule"))
		add_child(_label("可选 · 整理已见线索","JournalComparisonHeading","tip"))
		add_child(_button("打开线索对照","JournalObservationCompare",func(): comparison_requested.emit()))
	add_child(_rule("JournalHistoryRule"))
	history_toggle=_button("展开历史记录（%d）"%entries.size(),"JournalHistoryToggle",_toggle_history)
	history_toggle.toggle_mode=true
	add_child(history_toggle)
	history=VBoxContainer.new();history.name="JournalHistory";history.add_theme_constant_override("separation",0)
	add_child(history);history.hide()

func _build_phone_sections() -> void:
	add_theme_constant_override("separation",10)
	var task: Dictionary=PhoneOverlay.card(phone_builder)
	task.panel.name="JournalCurrentCard";add_child(task.panel)
	var body: VBoxContainer=task.content
	body.add_child(_label("当前任务","JournalCurrentHeading","tip"))
	body.add_child(_label(objective,"JournalObjective","heading"))
	if not detail.is_empty():
		body.add_child(_label("当前进度","JournalProgressHeading","tip"))
		body.add_child(_label(detail,"JournalNextStep","body"))
	if not digit_slots.is_empty():
		body.add_child(_label("签到码","JournalDigitsHeading","tip"))
		var slots:=HBoxContainer.new();slots.name="JournalDigitProgress";slots.add_theme_constant_override("separation",8)
		for index in digit_slots.size():
			var digit:=_label(digit_slots[index],"JournalDigitSlot%d"%index,"heading")
			digit.custom_minimum_size=Vector2(42,42);digit.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			digit.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;digit.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
			digit.add_theme_font_size_override("font_size",20)
			digit.add_theme_stylebox_override("normal",phone_builder._style(phone_builder.PAPER,phone_builder.INK,0,2))
			slots.add_child(digit)
		body.add_child(slots)
	if comparison_available:
		var clues: Dictionary=PhoneOverlay.card(phone_builder)
		clues.panel.name="JournalCluesCard";add_child(clues.panel)
		clues.content.add_child(_label("可选 · 整理已见线索","JournalComparisonHeading","tip"))
		clues.content.add_child(_button("打开线索对照","JournalObservationCompare",func(): comparison_requested.emit()))
	var records: Dictionary=PhoneOverlay.card(phone_builder)
	records.panel.name="JournalHistoryCard";add_child(records.panel)
	history_toggle=_button("展开历史记录（%d）"%entries.size(),"JournalHistoryToggle",_toggle_history)
	history_toggle.toggle_mode=true;records.content.add_child(history_toggle)
	history=VBoxContainer.new();history.name="JournalHistory";history.add_theme_constant_override("separation",0)
	records.content.add_child(history);history.hide()

func _label(text: String, id: String, role: String="body") -> Label:
	if phone_builder!=null:
		var phone_label:=PhoneOverlay.label(phone_builder,text,16 if role=="heading" else 13,Color("637080") if role=="tip" else INK)
		phone_label.name=id
		return phone_label
	var label:=Label.new();label.name=id;label.text=text
	style_label(label,18 if role=="heading" else 12 if role=="tip" else 14,MUTED if role=="tip" else INK,role=="heading")
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return label

func _rule(id: String) -> HSeparator:
	var line:=HSeparator.new();line.name=id
	line.mouse_filter=Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override("separation",5)
	line.add_theme_stylebox_override("separator",paper_box(LINE,Color.TRANSPARENT,0,Vector2(0,1)))
	return line

func _button(text: String, id: String, action: Callable, primary:=false) -> Button:
	if phone_builder!=null:
		var phone_button:=PhoneOverlay.action(phone_builder,text,action)
		phone_button.name=id
		return phone_button
	var button:=Button.new();button.name=id;button.text=text
	style_button(button,primary)
	button.autowrap_mode=TextServer.AUTOWRAP_OFF
	button.custom_minimum_size=Vector2(0,44)
	button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	button.alignment=HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(action)
	return button

func _toggle_history() -> void:
	history.visible=history_toggle.button_pressed
	history_toggle.text=("收起历史记录（%d）" if history.visible else "展开历史记录（%d）")%entries.size()
	if history.visible and history.get_child_count()==0:
		if entries.is_empty(): history.add_child(_label("还没有历史记录。","JournalHistoryEmpty"))
		for index in range(entries.size()-1,-1,-1):
			var row:=_label(str(entries[index].get("text","")),"JournalHistoryRow"+str(index))
			var row_style:=paper_box(Color.TRANSPARENT,LINE,0,Vector2(0,12))
			row_style.border_width_bottom=1 if index>0 else 0
			row.add_theme_stylebox_override("normal",row_style)
			history.add_child(row)
	if not history.visible: focus_control.call_deferred("JournalHistoryToggle")

func focus_control(id: String) -> void:
	var target: Control=resume_button if id=="JournalResume" else find_child(id,true,false)
	if not target is Control or not target.is_visible_in_tree():return
	var ancestor: Node=target.get_parent()
	while ancestor!=null:
		if ancestor is ScrollContainer:
			target.grab_focus();ancestor.ensure_control_visible(target);return
		ancestor=ancestor.get_parent()
	target.grab_focus()
