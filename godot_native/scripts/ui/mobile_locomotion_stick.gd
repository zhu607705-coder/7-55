extends Control
## Presentation only; world owns pointer capture and collision-resolved movement.
var world: Control

func _ready() -> void:
	z_index=80
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _draw() -> void:
	if not is_instance_valid(world) or not world._mobile_stick_available():return
	var rect:Rect2=world.mobile_stick_rect()
	var center:=rect.get_center()
	var radius:=rect.size.x/2
	var line:float=2.0/world.hud_display_scale()
	draw_circle(center,radius,Color("25343dd9"))
	draw_arc(center,radius-line,0,TAU,64,Color("e4e7df"),line,true)
	for direction:Vector2 in [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]:
		draw_line(center+direction*radius*.73,center+direction*radius*.85,Color("e4e7df"),line,true)
	var knob:Vector2=center+world.touch_axis*radius*.64
	draw_circle(knob,radius*.31,Color("e4e7df"))
	draw_arc(knob,radius*.31,0,TAU,48,Color("101c24"),line,true)
