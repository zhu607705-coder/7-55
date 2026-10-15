extends Control
## A visible, cancellable admission frame before loading the original 3D scene.
## It owns input only; it never changes the ride model or saved story state.
signal cancelled
var heading: Label
var leave: Button
var touch_id := -1
func _ready() -> void:
	name="ChaseLoading"
	mouse_filter=Control.MOUSE_FILTER_STOP
	focus_mode=Control.FOCUS_ALL
	var font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	heading=Label.new();heading.text="正在准备骑行画面…"
	heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_font_override("font",font)
	heading.add_theme_font_size_override("font_size",20)
	heading.add_theme_color_override("font_color",Color("eff4e8"))
	add_child(heading)
	leave=Button.new();leave.text="返回现场";leave.add_theme_font_override("font",font)
	leave.add_theme_font_size_override("font_size",18)
	leave.pressed.connect(func():cancelled.emit());add_child(leave)
	grab_focus()
func uses_activity_layout() -> bool:return true
func configure_activity_layout(available: Vector2,_compact: bool) -> void:
	position=Vector2.ZERO;scale=Vector2.ONE;size=available;touch_id=-1
	heading.position=Vector2(16,maxf(16,size.y*.45-36));heading.size=Vector2(maxf(1,size.x-32),64)
	leave.position=Vector2((size.x-176)/2,heading.position.y+80);leave.size=Vector2(176,48)
	queue_redraw()
func _draw() -> void:draw_rect(Rect2(Vector2.ZERO,size),Color("102631"))
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
		get_viewport().set_input_as_handled();cancelled.emit()
	elif event is InputEventScreenTouch:
		if event.pressed and leave.get_global_rect().has_point(event.position):touch_id=event.index;get_viewport().set_input_as_handled()
		elif not event.pressed and event.index==touch_id:
			touch_id=-1;get_viewport().set_input_as_handled()
			if not event.canceled and leave.get_global_rect().has_point(event.position):cancelled.emit()
