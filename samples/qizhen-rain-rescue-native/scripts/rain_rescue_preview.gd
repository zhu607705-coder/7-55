extends Control
## All visible action is drawn by Godot objects; no video is loaded.
## Local preview callbacks are explicitly separate from c3_rain_rescue_result.
signal preview_finished(run_id: int,reason: String)
const Timeline=preload("res://scripts/rescue_timeline.gd")
const Geometry=preload("res://scripts/rescue_pose_geometry.gd")
const LOGICAL:=Vector2(960,540)
const ZOOM: float=1.90
const ORIGIN:=Vector2(480,278)-Vector2(790,568)*ZOOM
const BUTTONS: Array[Rect2]=[Rect2(580,484,108,40),Rect2(697,484,108,40),Rect2(814,484,122,40)]
var timeline: RefCounted=Timeline.new()
var font: Font
var lake: Texture2D
var hull: Texture2D
var underside: Texture2D
var player_down: Texture2D
var player_side: Texture2D
var officer: Texture2D
var atlas: Texture2D
var officer_contact: Texture2D
var atlas_v2: Texture2D
var atlas_v2_regions: Array=[]
var atlas_regions: Array=[]
var capture_mode: bool=false
var callback_count: int=0
var last_callback_run: int=-1
var wet_time: float=0.0
var idle_offset:=Vector2.ZERO
var footprints: Array[Dictionary]=[]
var previous_foot:=Vector2.ZERO
var footprint_side: int=1
var moving: bool=false
var reduced_motion: bool=false

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	officer_contact=load("res://assets/generated/officer_reach_up_right_v03.png")
	font=load("res://assets/font.ttf")
	lake=load("res://assets/lake_rain.png")
	hull=load("res://assets/kayak_hull.svg")
	underside=load("res://assets/kayak_upturned.svg")
	player_down=load("res://assets/player_down.png")
	player_side=load("res://assets/player_side.png")
	officer=load("res://assets/officer.png")
	if FileAccess.file_exists("res://assets/generated/rescue_pose_atlas_v01.png"):
		atlas=load("res://assets/generated/rescue_pose_atlas_v01.png")
		if FileAccess.file_exists("res://assets/generated/atlas_regions.json"):
			atlas_regions=JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/atlas_regions.json"))
	if FileAccess.file_exists("res://assets/generated/rescue_pose_atlas_v02.png"):
		atlas_v2=load("res://assets/generated/rescue_pose_atlas_v02.png")
		atlas_v2_regions=JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/rescue_pose_atlas_v02.json")).frames
	previous_foot=Timeline.point_at(0)+Vector2(0,30)

func _process(dt: float) -> void:
	var step: float=minf(dt,.05)
	if timeline.advance(step):_report_preview()
	if not timeline.paused:
		wet_time+=step
		if timeline.finished and not capture_mode:
			var direction:=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
			moving=direction.length_squared()>0
			var candidate: Vector2=Timeline.point_at(Timeline.DURATION)+idle_offset+direction.normalized()*step*36
			candidate.x=clampf(candidate.x,671,733);candidate.y=clampf(candidate.y,488,585)
			idle_offset=candidate-Timeline.point_at(Timeline.DURATION)
		else:moving=timeline.elapsed>=Timeline.WALK and not timeline.finished
		_update_footprints()
	queue_redraw()

func _report_preview() -> void:
	if last_callback_run==timeline.run_id:return
	last_callback_run=timeline.run_id;callback_count+=1
	preview_finished.emit(timeline.run_id,timeline.outcome)

func replay() -> void:
	timeline.reset();idle_offset=Vector2.ZERO;footprints.clear();wet_time=0;moving=false;footprint_side=1
	previous_foot=Timeline.point_at(0)+Vector2(0,30)
	queue_redraw()

func skip() -> void:
	if timeline.skip():_report_preview()
	previous_foot=Timeline.point_at(Timeline.DURATION)+Vector2(0,30)
	queue_redraw()

func _update_footprints() -> void:
	for item: Dictionary in footprints:item.age+=get_process_delta_time()
	footprints=footprints.filter(func(item: Dictionary) -> bool:return item.age<.98)
	if timeline.elapsed<Timeline.WALK:return
	var foot: Vector2=_player_point()+Vector2(0,30)
	if previous_foot.distance_to(foot)>=8 and moving:
		footprints.append({"position":foot+Vector2(footprint_side*5,0),"age":0.0,"side":footprint_side})
		footprint_side*=-1;previous_foot=foot
		while footprints.size()>6:footprints.pop_front()

func _logical_point(point: Vector2) -> Vector2:
	var factor: float=minf(size.x/LOGICAL.x,size.y/LOGICAL.y)
	return point

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.device==InputEvent.DEVICE_ID_EMULATION:return
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		var point: Vector2=_logical_point(event.position)
		if BUTTONS[0].has_point(point):timeline.paused=not timeline.paused
		elif BUTTONS[1].has_point(point):replay()
		elif BUTTONS[2].has_point(point):skip()
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		var point: Vector2=_logical_point(event.position)
		if BUTTONS[0].has_point(point):timeline.paused=not timeline.paused
		elif BUTTONS[1].has_point(point):replay()
		elif BUTTONS[2].has_point(point):skip()
		accept_event()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:replay()
			KEY_SPACE,KEY_P:timeline.paused=not timeline.paused
			KEY_ESCAPE:skip()
			KEY_M:reduced_motion=not reduced_motion
		accept_event()

func _player_point() -> Vector2:return Timeline.point_at(timeline.elapsed)+idle_offset
func _screen(point: Vector2) -> Vector2:return ORIGIN+point*ZOOM

func _ellipse(p: Vector2,r: Vector2,color: Color,width: float=1.0,filled: bool=false) -> void:
	var points:=PackedVector2Array()
	for i: int in range(33):points.append(p+Vector2(cos(TAU*i/32),sin(TAU*i/32))*r)
	if filled:draw_colored_polygon(points,color)
	else:draw_polyline(points,color,width,false)

func _world_ellipse(p: Vector2,r: Vector2,color: Color,width: float=1.0,filled: bool=false) -> void:
	_ellipse(_screen(p),r*ZOOM,color,width*ZOOM,filled)

func _rope(a: Vector2,b: Vector2,sag: float) -> void:
	var points:=PackedVector2Array()
	for i: int in range(25):
		var u: float=i/24.0
		points.append(_screen(a.lerp(b,u)+Vector2(0,sin(u*PI)*sag)))
	draw_polyline(points,Color("172631"),3.2*ZOOM,false)
	draw_polyline(points,Color("e6c998"),1.5*ZOOM,false)

func _ring(point: Vector2,front_only: bool=false) -> void:
	var start: float=0 if front_only else PI
	var finish: float=PI if front_only else TAU
	for i: int in range(12):
		var a: float=lerpf(start,finish,i/12.0)
		var b: float=lerpf(start,finish,(i+1)/12.0)
		var color:=Color("df732f") if i%6<3 else Color("efebd6")
		var p1: Vector2=_screen(point+Vector2(cos(a)*28,sin(a)*9))
		var p2: Vector2=_screen(point+Vector2(cos(b)*28,sin(b)*9))
		draw_line(p1,p2,Color("25353d"),7*ZOOM,false)
		draw_line(p1,p2,color,4.7*ZOOM,false)

func _shadow(point: Vector2,r: Vector2=Vector2(18,5)) -> void:
	_world_ellipse(point,r,Color(.03,.08,.11,.25),1,true)

func _boat(point: Vector2,t: float) -> void:
	var capsize: float=Timeline.blend(t,Timeline.FALL,Timeline.SPLASH)
	var angle: float=lerpf(-.30,.98,capsize)+sin(t*5)*.07*(1-capsize)
	var tex: Texture2D=underside if capsize>.58 else hull
	_shadow(point+Vector2(0,10),Vector2(35,12))
	draw_set_transform(_screen(point),angle,Vector2.ONE*.64*ZOOM)
	draw_texture_rect(tex,Rect2(-64,-80,128,160),false,Color(.84,.91,.95))
	draw_set_transform(Vector2.ZERO)
	if t<Timeline.FALL:
		# Detachable branch and triangular-sign paddles remain independent of hull.
		var left: Vector2=point+Vector2(-33,-8+sin(t*7)*6)
		var right: Vector2=point+Vector2(35,6-sin(t*7)*6)
		draw_line(_screen(point+Vector2(-8,-5)),_screen(left),Color("b58d61"),4*ZOOM,false)
		draw_line(_screen(left),_screen(left+Vector2(-10,-8)),Color("926d45"),7*ZOOM,false)
		draw_line(_screen(point+Vector2(9,-5)),_screen(right),Color("d5dcd5"),3*ZOOM,false)
		draw_colored_polygon(PackedVector2Array([_screen(right+Vector2(-4,5)),_screen(right+Vector2(9,5)),_screen(right+Vector2(2,-7))]),Color("e6c65b"))

func _actor(kind: String,point: Vector2,slot: int,water_y: float=INF,wet: bool=false,rotation: float=0.0) -> void:
	var tex: Texture2D=player_down if kind=="player" else officer
	var source:=Rect2(0,0,96,128)
	var pivot:=Vector2(48,78)
	var scale_value: float=.57
	if atlas!=null and slot<12 and atlas_regions.size()>slot:
		var r: Array=atlas_regions[slot]
		tex=atlas;source=Rect2(r[0],r[1],r[2],r[3])
		scale_value=.215
		pivot=[Vector2(135,160),Vector2(194,139),Vector2(178,139),Vector2(129,175),Vector2(118,172),Vector2(112,181),Vector2(165,180),Vector2(160,180),Vector2(165,184),Vector2(165,176)][slot]
	if slot>=12 and slot<20 and atlas_v2!=null:
		var frame: Dictionary=atlas_v2_regions[slot-12]
		var r: Array=frame.region_xywh
		tex=atlas_v2;source=Rect2(r[0],r[1],r[2],r[3]);scale_value=.19
		pivot=[Vector2(115,225),Vector2(126,220),Vector2(115,223),Vector2(157,208),Vector2(114,211),Vector2(114,211),Vector2(199,199),Vector2(98,197)][slot-12]
	if slot==20:
		tex=officer_contact;source=Geometry.OFFICER_REGION;pivot=Geometry.OFFICER_PIVOT;scale_value=Geometry.OFFICER_SCALE
	var tint:=Color(.72,.83,.89) if wet else Color(.90,.94,.97)
	if kind=="teacher":tint=Color(.91,.89,.80)
	var flip: float=-1.0 if slot in [7,8,9,16,19] else 1.0
	# Clip only the portion below the current water line, before drawing waves.
	if water_y<INF:
		var cut: float=(water_y-point.y)/scale_value+pivot.y
		source.size.y=clampf(cut,0,source.size.y)
	if source.size.y<=0:return
	draw_set_transform(_screen(point),rotation,Vector2(flip,1)*scale_value*ZOOM)
	draw_texture_rect_region(tex,Rect2(-pivot,source.size),source,tint)
	draw_set_transform(Vector2.ZERO)
	if wet and water_y==INF:
		# Darkened lower folds and small cool highlights; no uniform blue glow.
		for x: float in [-9.0,8.0]:
			draw_rect(Rect2(_screen(point+Vector2(x,9)),Vector2(2,10)*ZOOM),Color(.11,.26,.33,.42))
			draw_rect(Rect2(_screen(point+Vector2(x,17)),Vector2(1.3,4)*ZOOM),Color(.62,.82,.86,.65))

func _arm(from: Vector2,to: Vector2,color: Color) -> void:
	var elbow: Vector2=from.lerp(to,.50)+Vector2(-2,3)
	draw_polyline(PackedVector2Array([_screen(from),_screen(elbow),_screen(to)]),Color("192d38"),8.5*ZOOM,false)
	draw_polyline(PackedVector2Array([_screen(from),_screen(elbow),_screen(to)]),color,5.5*ZOOM,false)
	draw_rect(Rect2(_screen(to)-Vector2(3,2.6)*ZOOM,Vector2(6,5.2)*ZOOM),Color("cfa67f"))

func _splash(age: float,point: Vector2,power: float=1.0) -> void:
	if age<0 or age>1.30:return
	for n: int in range(8 if reduced_motion else 26):
		var v:=Vector2((-1 if n%2==0 else 1)*(19+(n%7)*8),-24-(n%6)*10)*power
		var pos: Vector2=point+v*age+Vector2(0,64*age*age)
		draw_rect(Rect2(_screen(pos),Vector2(1.4+(n%3)*.6,2.4)*ZOOM),Color(.74,.88,.90,maxf(0,1-age/1.3)*.9))
	for n: int in range(3):_world_ellipse(point,Vector2(15+age*40+n*7,4+age*12+n*2),Color(.66,.84,.86,(1-age/1.3)*.5),.8)

func _wet_effect(point: Vector2) -> void:
	if timeline.elapsed<Timeline.LANDED:return
	var foot: Vector2=point+Vector2(0,30)
	_world_ellipse(foot,Vector2(17,5),Color(.11,.26,.29,.32),1,true)
	for n: int in range(3 if reduced_motion else 8):
		var cycle: float=fmod(wet_time*(.8+(n%3)*.17)+n*.137,1.0)
		var start:=Vector2(-12+(n%4)*8,4+(n/4)*11)
		var p: Vector2=point+start+Vector2(0,cycle*cycle*(27-start.y))
		draw_rect(Rect2(_screen(p),Vector2(1.1,2.2+cycle*2)*ZOOM),Color(.69,.88,.91,(1-cycle)*.85))
		if cycle>.80:_world_ellipse(foot+Vector2(start.x,0),Vector2((cycle-.8)*16,1.1),Color(.68,.86,.88,(1-cycle)*1.9),.6)

func _towel(point: Vector2,amount: float) -> void:
	if amount<=0:return
	var y: float=lerpf(-30,-7,amount)
	var pts:=PackedVector2Array([_screen(point+Vector2(-17,y)),_screen(point+Vector2(-10,y-5)),_screen(point+Vector2(12,y-5)),_screen(point+Vector2(19,y+3)),_screen(point+Vector2(15,y+23)),_screen(point+Vector2(7,y+20)),_screen(point+Vector2(9,y+1)),_screen(point+Vector2(-6,y+2)),_screen(point+Vector2(-10,y+25)),_screen(point+Vector2(-19,y+21))])
	draw_colored_polygon(pts,Color("c8cdbf"))
	draw_polyline(PackedVector2Array([pts[0],pts[1],pts[2],pts[3]]),Color("f2eee0"),2*ZOOM,false)
	for x: float in [-14.0,12.0]:draw_line(_screen(point+Vector2(x,y+5)),_screen(point+Vector2(x-1,y+19)),Color("929e98"),1.4*ZOOM,false)

func _rain(t: float) -> void:
	for n: int in range(26 if reduced_motion else 84):
		var x: float=fposmod(n*73.13+t*41,1000)-20
		var y: float=fposmod(n*41.71+t*190,430)+40
		draw_line(Vector2(x,y),Vector2(x-5,y+13),Color(.67,.81,.86,.12+(n%3)*.04),1,false)

func _caption(t: float) -> String:
	if t<Timeline.FALL:return "值班老师：雨还没停，先回来！"
	if t<Timeline.THROW:return "扶住船沿，头露出水面。"
	if t<Timeline.CATCH:return "值班老师：抓住救生圈！我们拉你回来。"
	if t<Timeline.DOCK:return "圈绳始终绷紧，安全员守住码头边。"
	if t<Timeline.LANDED:return "老师扶住手臂，安全员稳住救生圈。"
	if t<Timeline.TOWEL:return "先坐稳。人没事，衣服也没放过一滴水。"
	if t<Timeline.WALK:return "披上毛巾，衣摆和裤脚还在滴水。"
	return "人是上岸了，袖口和裤脚还在滴水。"

func _draw() -> void:
	if lake==null:return
	draw_rect(Rect2(Vector2.ZERO,size),Color("080f16"))
	draw_set_transform(Vector2.ZERO)
	draw_texture_rect(lake,Rect2(ORIGIN,Vector2(1672,941)*ZOOM),false)
	var t: float=timeline.elapsed
	var pp: Vector2=_player_point()
	var tp: Vector2=Timeline.teacher_at(t)
	var op: Vector2=Timeline.officer_at(t)
	var rp: Vector2=Timeline.ring_at(t)
	# Water effects and wet foot marks are under all opaque actors.
	for item: Dictionary in footprints:
		_world_ellipse(item.position,Vector2(3,5),Color(.06,.20,.24,(1-item.age/.98)*.60),1,true)
	if t>=Timeline.SPLASH and t<Timeline.LIFT:_world_ellipse(pp+Vector2(0,2),Vector2(32+sin(t*3)*2,8),Color(.47,.71,.75,.48),1)
	_boat(Timeline.boat_at(t),t)
	_shadow(tp+Vector2(0,30));_shadow(op+Vector2(0,30))
	var teacher_slot: int=6 if t<Timeline.CATCH or t>=Timeline.DOCK else 7
	if t>=Timeline.LANDED:teacher_slot=12
	if t>=Timeline.TOWEL and t<12.05:teacher_slot=13
	_actor("teacher",tp,teacher_slot)
	_actor("officer",op,14 if t>=Timeline.LANDED else (20 if t>=7.0 else 8))
	if t>=Timeline.THROW:
		var rope_origin: Vector2=(tp+Vector2(20,-5)).lerp(Vector2(748,563),Timeline.blend(t,Timeline.LANDED,Timeline.TOWEL))
		_world_ellipse(rp+Vector2(0,2),Vector2(30,9),Color(.06,.17,.21,.34),1,true)
		_world_ellipse(rp+Vector2(0,2),Vector2(33+sin(wet_time*2),10),Color(.49,.68,.72,.42),.65)
		_rope(rope_origin,rp+Vector2(-28,0),14 if t<Timeline.CATCH or t>=Timeline.LANDED else 2.0)
		_ring(rp,false)
	var slot: int=0
	if t>=Timeline.FALL:slot=1
	if t>=Timeline.SPLASH:slot=18
	if t>=Timeline.DOCK:slot=3
	if t>=Timeline.LANDED:slot=4
	if t>=Timeline.WALK:slot=(16 if int(wet_time*3.8)%2==0 else 17) if moving else 5
	var water_y: float=INF
	if t>=Timeline.SPLASH and t<Timeline.LIFT:water_y=pp.y+2
	elif t>=Timeline.LIFT and t<Timeline.LANDED:water_y=lerpf(pp.y+2,pp.y+80,Timeline.blend(t,Timeline.LIFT,Timeline.LANDED))
	if t>=Timeline.LANDED:_shadow(pp+Vector2(0,30))
	_actor("player",pp,slot,water_y,t>=Timeline.SPLASH,(-.34*sin(Timeline.blend(t,Timeline.FALL,Timeline.SPLASH)*PI)) if t>=Timeline.FALL and t<Timeline.SPLASH else 0.0)
	if t>=Timeline.THROW:_ring(rp,true)
	if t>=Timeline.DOCK and t<Timeline.LANDED:
		# The full drawn poses share anatomical contact points; never long bar arms.
		# Teacher grips both forward wrists, safety officer supports the lower body.
		var wrist: Vector2=pp+Vector2(-22,-1)
		draw_rect(Rect2(_screen(wrist)-Vector2(2,1.5)*ZOOM,Vector2(4,3)*ZOOM),Color("ceab86"))
	if t>=Timeline.SPLASH and t<Timeline.LIFT:
		_world_ellipse(pp+Vector2(0,2),Vector2(23,4),Color(.65,.83,.85,.68),1)
	_splash(t-Timeline.SPLASH,Timeline.point_at(Timeline.SPLASH)+Vector2(0,12))
	_splash(t-Timeline.CATCH,Timeline.ring_at(Timeline.CATCH),.35)
	_wet_effect(pp)
	if t>=12.05 and t<Timeline.WALK:
		var towel_progress: float=Timeline.blend(t,12.05,Timeline.WALK)
		var towel_point: Vector2=(tp+Vector2(35,-5)).lerp(pp+Vector2(0,-6),towel_progress)
		_towel(towel_point,1.0)
	_rain(wet_time)
	# Constant, opaque HUD bands and bounded labels remain clear at narrow widths.
	draw_rect(Rect2(0,0,960,54),Color("101e29"))
	draw_string(font,Vector2(24,33),"7:55  /  启真湖 · 雨天救援",HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("e5eee9"))
	draw_string(font,Vector2(678,32),"独立演出样例 · Godot 原生",HORIZONTAL_ALIGNMENT_RIGHT,258,17,Color("a6c1c8"))
	draw_rect(Rect2(0,424,960,116),Color("101e29"))
	draw_string(font,Vector2(24,455),_caption(t),HORIZONTAL_ALIGNMENT_LEFT,912,20,Color("e0e9e6"))
	var phases: Array[float]=[0,Timeline.FALL,Timeline.THROW,Timeline.CATCH,Timeline.DOCK,Timeline.LANDED,Timeline.TOWEL,Timeline.DURATION]
	for i: int in range(phases.size()-1):
		var active: bool=t>=phases[i]
		draw_rect(Rect2(24+i*65,477,58,3),Color("80b9bd") if active else Color("344653"))
	var status: String="空格 暂停 · R 重播 · Esc 跳过"
	if timeline.finished:status="WASD / 方向键：走两步，看湿脚印"
	if timeline.paused:status="已暂停 · 接触点、水线、圈绳同步冻结"
	draw_string(font,Vector2(24,511),status,HORIZONTAL_ALIGNMENT_LEFT,540,16,Color("b4c6cc"))
	var labels: Array[String]=["继续" if timeline.paused else "暂停","重播","跳到上岸"]
	for i: int in range(3):
		draw_style_box(_button_style(),BUTTONS[i])
		draw_string(font,BUTTONS[i].position+Vector2(0,26),labels[i],HORIZONTAL_ALIGNMENT_CENTER,BUTTONS[i].size.x,18,Color("d6e6e5"))

func _button_style() -> StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("203642");style.border_color=Color("49626c")
	style.set_border_width_all(1);style.set_corner_radius_all(4)
	return style
