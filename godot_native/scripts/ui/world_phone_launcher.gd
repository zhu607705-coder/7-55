extends Button
## Compact phone silhouette. Existing shell owns the action and P shortcut.
## The 20x30 drawing is independent from its 44x44 touch/focus target.
func _has_point(point:Vector2)->bool:
	return Rect2(Vector2.ZERO,size).has_point(point)

# Establish the hit geometry before tree entry. Initialising only in _ready
# could ignore the first raw press in a fresh viewport until MouseMotion.
func _init() -> void:
	text=""
	tooltip_text="打开手机 · P"
	custom_minimum_size=Vector2(44,44)
	size=Vector2(44,44)
	mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	for state in ["normal","hover","pressed","hover_pressed","disabled"]:
		add_theme_stylebox_override(state,StyleBoxEmpty.new())
	var focus:=StyleBoxFlat.new()
	focus.bg_color=Color.TRANSPARENT
	focus.border_color=Color("f0d895")
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(3)
	add_theme_stylebox_override("focus",focus)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)

func _draw() -> void:
	var glyph:=Rect2((size-Vector2(20,30))/2,Vector2(20,30))
	if is_pressed(): glyph.position.y+=1
	var ink:=Color("fffce7") if is_hovered() else Color("eeeeda")
	if disabled: ink.a=0.45
	var face:=StyleBoxFlat.new()
	face.bg_color=Color("52704c88") if is_hovered() else Color("22392e44")
	face.border_color=ink
	face.set_border_width_all(1)
	face.set_corner_radius_all(3)
	face.corner_detail=2
	face.anti_aliasing=false
	face.shadow_color=Color("12251c80")
	face.shadow_size=2
	face.shadow_offset=Vector2(0,1)
	draw_style_box(face,glyph)
	draw_rect(Rect2(glyph.position+Vector2(7,4),Vector2(6,1)),ink)
	draw_rect(Rect2(glyph.position+Vector2(9,25),Vector2(2,2)),ink,false,1)
