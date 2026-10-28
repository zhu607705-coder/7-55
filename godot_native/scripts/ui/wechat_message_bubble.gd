extends MarginContainer
## A message owns its text, padding and avatar. Containers determine its height.
const Typography=preload("res://scripts/ui/native_typography.gd")
const Palette=preload("res://scripts/ui/phone_palette.gd")
var bubble: PanelContainer
var content: VBoxContainer
var text_label: Label
var avatar: PanelContainer

func configure(copy: String, outgoing: bool=false, font_size: int=18) -> void:
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("margin_left",12)
	add_theme_constant_override("margin_right",12)
	mouse_filter=Control.MOUSE_FILTER_PASS
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	add_child(row)
	avatar=PanelContainer.new();avatar.name="MessageAvatar"
	avatar.custom_minimum_size=Vector2(40,40)
	avatar.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	avatar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var avatar_style:=StyleBoxFlat.new()
	avatar_style.bg_color=Color("83a7b6") if outgoing else Color("d5ba8b")
	avatar_style.set_corner_radius_all(4)
	avatar.add_theme_stylebox_override("panel",avatar_style)
	var initial:=Label.new();Typography.apply_body(initial)
	initial.text="我" if outgoing else "/"
	initial.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	initial.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	initial.add_theme_font_size_override("font_size",18)
	initial.add_theme_color_override("font_color",Palette.INK)
	avatar.add_child(initial)
	bubble=PanelContainer.new();bubble.name="MessageBubble"
	bubble.set_meta("wechat_bubble",true)
	bubble.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	bubble.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	bubble.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var skin:=StyleBoxFlat.new()
	skin.bg_color=Palette.SELF_BUBBLE if outgoing else Color.WHITE
	skin.set_corner_radius_all(4)
	skin.content_margin_left=12;skin.content_margin_right=12
	skin.content_margin_top=10;skin.content_margin_bottom=10
	bubble.add_theme_stylebox_override("panel",skin)
	content=VBoxContainer.new();content.add_theme_constant_override("separation",8)
	bubble.add_child(content)
	text_label=Label.new();text_label.name="MessageText"
	Typography.apply_body(text_label)
	text_label.text=copy
	text_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	text_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	text_label.add_theme_font_size_override("font_size",font_size)
	text_label.add_theme_color_override("font_color",Palette.INK)
	text_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content.add_child(text_label)
	if outgoing:row.add_child(bubble);row.add_child(avatar)
	else:row.add_child(avatar);row.add_child(bubble)
