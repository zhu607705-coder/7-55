extends RefCounted
## Phone-sized WeChat chrome; no copied contacts, device status or unread counts.
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const Typography=preload("res://scripts/ui/native_typography.gd")
const INK=Color("191919")
const MUTED=Color("999999")
const GREEN=Color("07b75a")

class Mark extends Control:
	var kind="chats"
	var ink=Color("191919")
	func _init() -> void: mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var fit=minf(size.x,size.y)/32.0
		draw_set_transform((size-Vector2.ONE*32*fit)/2,0,Vector2.ONE*fit)
		match kind:
			"search":
				draw_arc(Vector2(13,13),9,0,TAU,32,ink,2,true);draw_line(Vector2(20,20),Vector2(28,28),ink,2,true)
			"plus":
				draw_arc(Vector2(16,16),13,0,TAU,40,ink,2,true)
				draw_line(Vector2(16,8),Vector2(16,24),ink,2,true);draw_line(Vector2(8,16),Vector2(24,16),ink,2,true)
			"chats":
				draw_circle(Vector2(12,13),10,ink);draw_circle(Vector2(23,21),8,ink)
				draw_colored_polygon(PackedVector2Array([Vector2(4,18),Vector2(3,26),Vector2(12,21)]),ink)
				draw_circle(Vector2(9,11),1.2,Color.WHITE);draw_circle(Vector2(16,11),1.2,Color.WHITE)
			"contacts","me":
				draw_arc(Vector2(13 if kind=="contacts" else 16,10),6,0,TAU,28,ink,2,true)
				draw_polyline(PackedVector2Array([Vector2(7,17),Vector2(3,24),Vector2(3,27),Vector2(25,27),Vector2(25,24),Vector2(20,17)]),ink,2,true)
				if kind=="contacts":
					for y in [10,16,22]:draw_line(Vector2(24,y),Vector2(31,y),ink,2,true)
			"discover":
				draw_arc(Vector2(16,16),13,0,TAU,40,ink,2,true)
				draw_colored_polygon(PackedVector2Array([Vector2(22,8),Vector2(12,13),Vector2(9,24),Vector2(19,19)]),ink)
			"officials":
				draw_colored_polygon(PackedVector2Array([Vector2(4,7),Vector2(12,10),Vector2(15,17),Vector2(15,28),Vector2(7,23),Vector2(4,17)]),ink)
				draw_colored_polygon(PackedVector2Array([Vector2(28,7),Vector2(20,10),Vector2(17,17),Vector2(17,28),Vector2(25,23),Vector2(28,17)]),ink)

static func icon(parent: Control,kind: String,rect: Rect2,color: Color=INK) -> Control:
	var mark=Mark.new();mark.kind=kind;mark.ink=color;mark.position=rect.position;mark.size=rect.size;parent.add_child(mark)
	return mark

static func label(parent: Control,text: String,font_size: int,color: Color=INK) -> Label:
	var value=Label.new();Typography.apply_body(value);value.text=text;value.mouse_filter=Control.MOUSE_FILTER_IGNORE
	value.add_theme_font_size_override("font_size",font_size);value.add_theme_color_override("font_color",color)
	value.autowrap_mode=TextServer.AUTOWRAP_OFF;value.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;value.clip_text=true
	parent.add_child(value);return value

static func conversation(parent: Control,title: String,preview: String,time: String,font_scale: float,pinned: bool=false) -> Button:
	var button=Button.new();button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.custom_minimum_size.y=maxf(72,58*font_scale)
	Ui.apply_button(button,Color("ededed") if pinned else Color.WHITE,INK,Color.TRANSPARENT,0,0,16,Vector2.ZERO)
	parent.add_child(button)
	var margin=MarginContainer.new();margin.mouse_filter=Control.MOUSE_FILTER_IGNORE;button.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right"]:margin.add_theme_constant_override("margin_"+side,12)
	for side in ["top","bottom"]:margin.add_theme_constant_override("margin_"+side,11)
	var row=HBoxContainer.new();row.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_theme_constant_override("separation",12);margin.add_child(row)
	var avatar=Control.new();avatar.name="AvatarSlot";avatar.mouse_filter=Control.MOUSE_FILTER_IGNORE;avatar.custom_minimum_size=Vector2(48,48);avatar.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(avatar)
	var column=VBoxContainer.new();column.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.size_flags_vertical=Control.SIZE_SHRINK_CENTER;column.add_theme_constant_override("separation",4);row.add_child(column)
	var top=HBoxContainer.new();top.mouse_filter=Control.MOUSE_FILTER_IGNORE;top.add_theme_constant_override("separation",8);column.add_child(top)
	var name_label=label(top,title,roundi(18*font_scale));name_label.name="ConversationTitle";name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var time_label=label(top,time,roundi(11*font_scale),MUTED);time_label.name="ConversationTime";time_label.custom_minimum_size.x=42;time_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	var summary=label(column,preview,roundi(14*font_scale),MUTED);summary.name="ConversationPreview";summary.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var line=ColorRect.new();line.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.color=Color("e7e7e7");button.add_child(line)
	button.resized.connect(func():line.position=Vector2(72,button.size.y-1);line.size=Vector2(button.size.x-72,1))
	margin.minimum_size_changed.connect(func():button.custom_minimum_size.y=maxf(72,margin.get_combined_minimum_size().y))
	return button
