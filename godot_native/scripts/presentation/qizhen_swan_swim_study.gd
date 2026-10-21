extends Control
## An isolated visual review loop on the authored cove; no story or save writes.
const SwimVisual=preload("res://scripts/presentation/qizhen_swan_swim_visual.gd")
const DURATION: float=12.0
var visual: RefCounted=SwimVisual.new()
var lake: Texture2D
var font: Font
var elapsed: float=0
var point:=Vector2(880,370)
var heading: float=PI
var speed: float=28
var turn_rate: float=0
var camera:=Vector2(880,340)
var state: String="swim"
var label: String="折翅平游"
var paused: bool=false
var capture_mode: bool=false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lake=load("res://assets/rpg/interiors/qizhen_lake_swan_cove.png")
	font=preload("res://scripts/ui/native_typography.gd").body_font()
	restart()

func restart() -> void:
	elapsed=0;point=Vector2(880,370);heading=PI;speed=28;turn_rate=0
	camera=point+Vector2(0,-26)
	state="swim";label="折翅平游";paused=false
	visual.reset(point)

func _process(delta: float) -> void:
	if paused:return
	var dt: float=minf(delta,.05)
	elapsed+=dt
	if elapsed>=DURATION:restart();return
	var desired: float=PI
	var target_speed: float=28
	state="swim";label="折翅平游"
	if elapsed>=3 and elapsed<6.8:
		state="turn";label="水上转弯"
		desired=lerpf(PI,PI*5/8,smoothstep(3,6.8,elapsed));target_speed=32
	elif elapsed>=6.8 and elapsed<9.6:
		state="accelerate";label="加速划水 · 仍然折翅"
		desired=PI*5/8;target_speed=lerpf(32,85,smoothstep(6.8,9.6,elapsed))
	elif elapsed>=9.6:
		state="coast";label="收力滑行"
		desired=PI*5/8;target_speed=lerpf(85,15,smoothstep(9.6,11.4,elapsed))
	var desired_rate: float=clampf(angle_difference(heading,desired)*3,-.52,.52)
	turn_rate=move_toward(turn_rate,desired_rate,1.8*dt)
	heading+=turn_rate*dt
	speed=move_toward(speed,target_speed,45*dt)
	point+=Vector2.from_angle(heading)*speed*dt
	visual.update(dt,point,heading,state)
	camera=camera.lerp(point+Vector2(0,-26),1-exp(-2.8*dt))
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_R:restart()
		elif event.keycode in [KEY_SPACE,KEY_P]:paused=not paused
		queue_redraw()

func _draw() -> void:
	if lake==null:return
	var zoom: float=2.7*minf(size.x/1280,size.y/720)
	var origin: Vector2=size/2-camera*zoom
	draw_rect(Rect2(Vector2.ZERO,size),Color("10252a"))
	draw_texture_rect(lake,Rect2(origin,Vector2(1672,941)*zoom),false)
	visual.draw(self,point,origin,zoom)
	var fade: float=smoothstep(11.5,12,elapsed)
	if fade>0:draw_rect(Rect2(Vector2.ZERO,size),Color(.035,.09,.11,fade))
	draw_rect(Rect2(0,0,size.x,58),Color(.035,.09,.11,.94))
	draw_string(font,Vector2(24,37),"启真湖 · 黑天鹅游泳动作审看",HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("e2eee7"))
	draw_string(font,Vector2(size.x-350,37),label,HORIZONTAL_ALIGNMENT_RIGHT,325,21,Color("b4d9d4"))
	draw_rect(Rect2(0,size.y-44,size.x,44),Color(.035,.09,.11,.94))
	draw_string(font,Vector2(24,size.y-15),"原生近景循环 · 折翅 / 水线 / 速度尾迹 · 视觉待确认",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("c6d8d6"))
	if not capture_mode:draw_string(font,Vector2(size.x-235,size.y-15),"R 重播 · 空格暂停",HORIZONTAL_ALIGNMENT_RIGHT,210,17,Color("c6d8d6"))
