extends VBoxContainer
## Current task stays above optional tools and lazily expanded history.
## Entries are presentation copies. This view never changes the saved log.
signal resume_requested
signal comparison_requested
const Selected=preload("res://scripts/ui/selected_ui_theme.gd")
var context_texture: Texture2D
var objective: String
var detail: String
var entries: Array=[]
var comparison_available:=false
var return_label: String="返回游戏"
var history: VBoxContainer
var history_toggle: Button

func configure(title: String, next_step: String, log: Array, can_compare: bool, in_world: bool) -> void:
	objective=title;detail=next_step;entries=log.duplicate(true);comparison_available=can_compare
	return_label="返回现场" if in_world else "返回游戏"

func _ready() -> void:
	name="NativeJournal"
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",8)
	# JOURNAL-3: one reading column over the retained world, no folder shell,
	# duplicate scene thumbnail, decorative tabs or invented diary copy.
	add_child(_label("当前任务","JournalCurrentHeading","tip"))
	add_child(_label(objective,"JournalObjective","heading"))
	if not detail.is_empty():
		add_child(_label("当前进度","JournalProgressHeading","tip"))
		add_child(_label(detail,"JournalNextStep","body"))
	add_child(_button(return_label,"JournalResume",func(): resume_requested.emit()))
	if comparison_available:
		add_child(_label("可选 · 整理已见线索","JournalComparisonHeading","tip"))
		add_child(_button("打开线索对照","JournalObservationCompare",func(): comparison_requested.emit()))
	history_toggle=_button("展开历史记录（%d）"%entries.size(),"JournalHistoryToggle",_toggle_history)
	history_toggle.toggle_mode=true
	add_child(history_toggle)
	history=VBoxContainer.new();history.name="JournalHistory";history.add_theme_constant_override("separation",10)
	add_child(history);history.hide()

func _label(text: String, id: String, role: String="body") -> Label:
	var label:=Label.new();label.name=id;label.text=text
	Selected.apply_label(label,"journal",role)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return label

func _button(text: String, id: String, action: Callable) -> Button:
	var button:=Button.new();button.name=id;button.text=text
	Selected.apply_button(button,"journal")
	# Short action captions use the material's natural minimum width. The
	# previous hand-measured width assumed 8px insets and wrapped after restyling.
	button.autowrap_mode=TextServer.AUTOWRAP_OFF
	button.custom_minimum_size=Vector2(maxf(44,ceilf(Selected.font("journal","button").get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,Selected.size("journal","button")).x)+16),44)
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
			history.add_child(_label(str(entries[index].get("text","")),"JournalHistoryRow"+str(index)))
	if not history.visible: focus_control.call_deferred("JournalHistoryToggle")

func focus_control(id: String) -> void:
	var target:=find_child(id,true,false)
	if target is Control and target.is_visible_in_tree():
		target.grab_focus()
		var ancestor: Node=get_parent()
		while ancestor!=null:
			if ancestor is ScrollContainer: ancestor.ensure_control_visible(target); break
			ancestor=ancestor.get_parent()
