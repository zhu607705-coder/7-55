extends PanelContainer
const Sketch=preload("res://scripts/games/library_geometry/sketch.gd")
const TITLES=["线框球","斜视角薄板","圆锥螺旋"]
const CAPTIONS=["静止时重合，转动时分开。","错开，再滑回对齐。","从底部收掉，再从底部重新长上来。"]
var kind:=0
var allow_hover:=true
const INK=Color("393c38")
const SECONDARY_INK=Color("62665e")
const FOCUS_INK=Color("49614e")
var sketch:Control
var touch_owner:=-1
var touch_start:=Vector2.ZERO
var touch_moved:=false

func _ready()->void:
	custom_minimum_size=Vector2(0,360);mouse_filter=Control.MOUSE_FILTER_PASS
	focus_mode=Control.FOCUS_ALL;accessibility_name=TITLES[kind]
	var paper=StyleBoxFlat.new();paper.bg_color=Color("fdfdfb")
	paper.border_color=Color(.216,.231,.192,.065);paper.set_border_width_all(1)
	paper.set_corner_radius_all(20);paper.set_content_margin_all(28)
	add_theme_stylebox_override("panel",paper)
	var column=VBoxContainer.new();column.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(column)
	var center=Control.new();center.custom_minimum_size.y=202;center.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(center)
	sketch=Sketch.new();sketch.kind=kind;sketch.intro_delay=kind*.14;center.add_child(sketch)
	center.resized.connect(func():sketch.position=Vector2((center.size.x-202)/2,0))
	var spacer=Control.new();spacer.mouse_filter=Control.MOUSE_FILTER_IGNORE;spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(spacer)
	var title=Label.new();title.text=TITLES[kind];title.add_theme_font_size_override("font_size",17)
	title.add_theme_color_override("font_color",INK);column.add_child(title)
	var caption=Label.new();caption.text=CAPTIONS[kind];caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	caption.custom_minimum_size.y=44
	caption.add_theme_font_size_override("font_size",15);caption.add_theme_color_override("font_color",SECONDARY_INK);column.add_child(caption)
	mouse_exited.connect(func():sketch.hovered=false;sketch.release())
	focus_entered.connect(queue_redraw)
	focus_exited.connect(func():sketch.release();queue_redraw())

func _draw()->void:
	if not has_focus():return
	var ring=StyleBoxFlat.new();ring.bg_color=Color.TRANSPARENT
	ring.border_color=FOCUS_INK;ring.set_border_width_all(2);ring.set_corner_radius_all(16)
	draw_style_box(ring,Rect2(Vector2(4,4),size-Vector2(8,8)))

func _gui_input(event:InputEvent)->void:
	if allow_hover and event is InputEventMouseMotion and event.device!=InputEvent.DEVICE_ID_EMULATION:
		sketch.hovered=true
		if sketch.ready_for_input() and not sketch.active:sketch.activate()
	elif event is InputEventScreenTouch:
		if event.pressed and touch_owner<0:
			touch_owner=event.index;touch_start=event.position;touch_moved=false
		elif event.index==touch_owner:
			if not event.canceled and not touch_moved:sketch.activate(true)
			touch_owner=-1
	elif event is InputEventScreenDrag and event.index==touch_owner:
		touch_moved=touch_moved or event.position.distance_to(touch_start)>10
	elif event is InputEventKey and event.pressed and not event.echo:
		var code=event.physical_keycode if event.physical_keycode else event.keycode
		if code in [KEY_SPACE,KEY_ENTER]:sketch.activate(true);accept_event()

func tick(delta:float)->void:sketch.tick(delta)
func quiet()->void:
	touch_owner=-1;touch_moved=false;sketch.quiet()
