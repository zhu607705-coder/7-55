extends Control
## An original-art drag ghost. No input, collision, campaign state or timers.
var visual: Node2D
var art: Sprite2D
var elapsed:=0.0
var tilt:=0.0
var reduced:=false
var last_pointer:=Vector2.INF
var source_angle:=0.0
func configure(source: Sprite2D,angle: float,zoom: float,reduce: bool) -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	reduced=reduce;source_angle=angle
	visual=Node2D.new();add_child(visual)
	art=Sprite2D.new();visual.add_child(art)
	art.texture=source.texture;art.region_enabled=source.region_enabled
	art.region_rect=source.region_rect;art.region_filter_clip_enabled=true
	art.centered=true;art.scale=source.scale*zoom
	visual.rotation=source_angle
	var hint:=Label.new();hint.name="OriginalDragLabel";hint.text="桌椅组 ↑"
	hint.position=Vector2(-64,source.region_rect.size.x*source.scale.x*zoom/2+6)
	hint.size=Vector2(128,28);hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hint.add_theme_font_override("font",load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"))
	hint.add_theme_font_size_override("font_size",18)
	hint.add_theme_color_override("font_color",Color("b8edf4"))
	hint.add_theme_color_override("font_shadow_color",Color("102029"))
	hint.add_theme_constant_override("shadow_offset_x",1);hint.add_theme_constant_override("shadow_offset_y",1)
	add_child(hint)
	_apply()
func _process(delta: float) -> void:
	advance_feedback(delta,get_global_mouse_position())
func advance_feedback(delta: float,pointer: Vector2) -> void:
	var dt:=clampf(delta,0,.05)
	elapsed+=dt
	var target:=0.0
	if not reduced and last_pointer.is_finite() and dt>0:
		target=clampf((pointer.x-last_pointer.x)/dt*.00008,-.065,.065)
	last_pointer=pointer
	tilt=move_toward(tilt,target,dt*.6) if not reduced else 0.0
	_apply()
func _apply() -> void:
	if not is_instance_valid(visual): return
	var t:=clampf(elapsed/.16,0,1)
	var lift:=1-pow(1-t,3) if not reduced else 0.0
	visual.scale=Vector2.ONE*(1+lift*.055)
	visual.position=Vector2(0,-lift*9)
	visual.rotation=source_angle+tilt
func retire() -> void:
	hide();set_process(false)
	elapsed=0;tilt=0;last_pointer=Vector2.INF
