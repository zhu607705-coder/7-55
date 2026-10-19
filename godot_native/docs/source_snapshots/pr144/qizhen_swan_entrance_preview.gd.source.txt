extends Control
## Isolated entrance preview on the authored Qizhen cove. Never writes State/saves.
const Entrance = preload("res://scripts/games/qizhen_swan_entrance.gd")
const Motion = preload("res://scripts/games/qizhen_swan_motion.gd")
const Kayak = preload("res://scripts/games/kayak_model.gd")
const KayakArt = preload("res://scripts/ui/kayak_visual.gd")
const SPRITE_REGIONS: Array[Rect2] = [
	Rect2(40,180,385,214), Rect2(452,70,365,325), Rect2(871,180,440,220), Rect2(1345,100,400,300),
	Rect2(40,451,405,380), Rect2(447,548,420,285), Rect2(910,600,440,225), Rect2(1430,570,310,242)]
const SPRITE_ANCHORS: Array[Vector2] = [Vector2(201,185),Vector2(197,293),Vector2(261,183),Vector2(195,263),Vector2(201,344),Vector2(209,247),Vector2(244,175),Vector2(160,209)]
var timeline: RefCounted = Entrance.new()
var swan: RefCounted = Motion.new()
var kayak: RefCounted = Kayak.new()
var kayak_art: RefCounted = KayakArt.new()
var lake_plate: Texture2D
var gate_cleanplate: Texture2D
var swan_atlas: Texture2D
var font: Font
var zone: Dictionary
var obstacles: Array = []
var stage: String = "intro"
var camera: Vector2 = Vector2(925,440)
var world_zoom: float = 1
var clock: float = 0
var play_time: float = 0
var attempts: int = 0
var failure_time: float = 0
var paused: bool = false
var capture_demo: bool = false
var capture_input_count: int = 0
var capture_next_stroke: float = 0.1
var handed_back: int = 0
var status: String = ""
var trail: Array = []
var trail_tick: float = 0
var controls: Dictionary = {}
var touch_starts: Dictionary = {}
var current_pose: Dictionary = {}
var sound_players: Array[AudioStreamPlayer] = []
var sounded: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	lake_plate = load("res://assets/rpg/interiors/qizhen_lake_swan_cove.png")
	swan_atlas = load("res://assets/native/chapter3/black_swan_entrance_atlas.png")
	gate_cleanplate = load("res://assets/native/chapter3/swan_cove_gate_cleanplate.png")
	font = load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	zone = JSON.parse_string(FileAccess.get_file_as_string("res://data/worlds.json")).worlds.qizhen_lake.zones.swan_cove
	obstacles = zone.kayakCollisions.duplicate(true)
	# Open only the illustrated west gate; retain the other source fence solids.
	for obstacle: Dictionary in obstacles:
		if obstacle.id == "swan_fence_west_upper": obstacle.bottom = 263
	# Conservative source-pixel banks close the authored dataset's southwest
	# void and retain a hull-sized south passage. No source world data is changed.
	obstacles.append_array([
		{"id":"preview_sw_bank_1","left":0,"top":600,"right":100,"bottom":941},
		{"id":"preview_sw_bank_2","left":0,"top":665,"right":170,"bottom":941},
		{"id":"preview_sw_bank_3","left":0,"top":710,"right":240,"bottom":941},
		{"id":"preview_south_left_approach","left":0,"top":730,"right":270,"bottom":941},
		{"id":"preview_south_right_approach","left":450,"top":730,"right":500,"bottom":941},
		{"id":"preview_south_left","left":0,"top":760,"right":292,"bottom":941},
		{"id":"preview_south_right","left":425,"top":760,"right":500,"bottom":941}])
	for filename: String in ["res://assets/audio/chapter3-qizhen/sfx/fx_qizhen_paper_release.mp3", "res://assets/audio/chapter3-qizhen/sfx/fx_qizhen_mist_spray.mp3"]:
		if ResourceLoader.exists(filename):
			var audio := AudioStreamPlayer.new()
			audio.stream = load(filename)
			audio.volume_db = -10
			add_child(audio)
			sound_players.append(audio)
	restart()

func restart() -> void:
	timeline.reset()
	stage = "intro"
	paused = false
	clock = 0
	play_time = 0
	failure_time = 0
	handed_back = 0
	capture_input_count = 0
	capture_next_stroke = 0.1
	trail.clear()
	sounded.clear()
	touch_starts.clear()
	for audio: AudioStreamPlayer in sound_players: audio.stop()
	kayak = Kayak.new()
	kayak.configure({"phase":"world", "bounded":false})
	kayak.position = Entrance.BOAT_START
	kayak.heading = 2.55
	swan.reset(Entrance.SWAN_HANDOFF, 2.8, obstacles, Rect2(28,160,1422,753))
	current_pose = timeline.pose()
	camera = current_pose.camera
	world_zoom = current_pose.zoom
	status = ""
	queue_redraw()

func handoff() -> void:
	if stage != "intro": return
	stage = "play"
	handed_back += 1
	play_time = 0
	swan.reset(Entrance.SWAN_HANDOFF, 2.8, obstacles, Rect2(28,160,1422,753))
	# The camera and actors use the same last cinematic pose. No scene swap.
	kayak.speed = 0
	kayak.roll = 0
	status = "交替划桨，朝左下方的南口离开"
	touch_starts.clear()

func skip_intro() -> void:
	if stage != "intro": return
	timeline.skip()
	current_pose = timeline.pose()
	camera = current_pose.camera
	world_zoom = current_pose.zoom
	for audio: AudioStreamPlayer in sound_players: audio.stop()
	handoff()

func _process(delta: float) -> void:
	if paused: return
	var dt: float = minf(maxf(delta,0),0.05)
	clock += dt
	if stage == "intro":
		var done: bool = timeline.advance(dt)
		current_pose = timeline.pose()
		camera = current_pose.camera
		world_zoom = current_pose.zoom
		if timeline.elapsed > 0.5: _sound_once("gate",0)
		if timeline.elapsed > 4.88: _sound_once("splash",1)
		if done: handoff()
	elif stage == "play":
		play_time += dt
		if capture_demo and play_time >= capture_next_stroke:
			var target: Vector2=Vector2(340,620) if kayak.position.x>460 else Vector2(357,850)
			var turn: float=angle_difference(kayak.heading,(target-kayak.position).angle())
			var side: String="left" if capture_input_count%2==0 else "right"
			var reverse: bool=false
			if absf(turn)>0.18:
				side="left" if turn>0 else "right"
				if kayak.last_side==side and kayak.same_side_streak>=2:
					side="right" if side=="left" else "left"
					reverse=true
			stroke(side,reverse)
			capture_input_count += 1
			capture_next_stroke += 0.18
		var previous: Vector2 = kayak.position
		var remaining: float = dt
		while remaining > 0.000001:
			var step_dt: float = minf(remaining,1.0/120.0)
			var safe: Vector2 = kayak.position
			kayak.update(step_dt)
			if not boat_valid(kayak.position,kayak.heading):
				kayak.position = safe
				kayak.speed = 0
				status = "岸边挡住了船：按住 S 配合左右桨反划退出"
			remaining -= step_dt
		var event: Dictionary = swan.step(dt,kayak.position,(kayak.position-previous)/maxf(dt,0.001))
		if reached_exit():
			stage = "escaped"
			status = "已经驶出围栏。出场验证完成，R 可重新体验"
		elif kayak.status == "lost": begin_failure("同侧连划导致失衡。R 重播或稍候自动重试")
		elif event.get("caught",false): begin_failure("天鹅追上了船。R 重播或稍候自动重试")
		else:
			if swan.phase == "charge_warning": status = "它正在瞄准：侧划转向，避开即将冲来的直线"
			elif swan.phase == "recovery": status = "冲空了，现在交替划桨拉开距离"
		var midpoint: Vector2 = kayak.position.lerp(swan.position,0.23)
		camera = camera.lerp(midpoint,1-exp(-2.2*dt))
		world_zoom = lerpf(world_zoom,0.98,1-exp(-2.2*dt))
	elif stage == "caught":
		failure_time += dt
		if failure_time >= 1.5: restart()
	elif stage == "escaped":
		swan.step(dt,kayak.position,Vector2.ZERO,false)
		kayak.speed = move_toward(kayak.speed,0,140*dt)
	trail_tick += dt
	if trail_tick > 0.08:
		trail_tick = 0
		var point: Vector2 = current_pose.position if stage == "intro" else swan.position
		trail.append({"point":point,"born":clock,"power":1.0 if stage=="intro" and timeline.elapsed>4.75 else 0.4})
	while not trail.is_empty() and clock-float(trail[0].born)>1.6: trail.pop_front()
	queue_redraw()

func _sound_once(key: String,index: int) -> void:
	if sounded.has(key): return
	sounded[key] = true
	if index < sound_players.size(): sound_players[index].play()

func begin_failure(message: String) -> void:
	stage = "caught"
	attempts += 1
	failure_time = 0
	kayak.speed = 0
	status = message
	touch_starts.clear()

func boat_valid(point: Vector2,heading: float) -> bool:
	var dims := Vector2(83*absf(cos(heading))+67*absf(sin(heading)),83*absf(sin(heading))+67*absf(cos(heading)))
	var box := Rect2(point-dims/2,dims)
	if not Rect2(28,160,1422,753).encloses(box): return false
	for obstacle: Dictionary in obstacles:
		var rect := Rect2(float(obstacle.left),float(obstacle.top),float(obstacle.right)-float(obstacle.left),float(obstacle.bottom)-float(obstacle.top))
		if box.intersects(rect): return false
	return true

func reached_exit() -> bool:
	# Only the authored south water passage, never the black area left of it.
	return kayak.position.y > 810 and kayak.position.x >= 315 and kayak.position.x <= 410 and boat_valid(kayak.position,kayak.heading)

func stroke(side: String,reverse: bool=false) -> void:
	if stage != "play" or paused: return
	var old: float = kayak.heading
	kayak.stroke(side,reverse)
	if not boat_valid(kayak.position,kayak.heading): kayak.heading = old

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not capture_demo:
		paused = true
		touch_starts.clear()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode == KEY_R: restart()
	elif event.keycode in [KEY_ESCAPE,KEY_P]: paused = not paused; touch_starts.clear(); queue_redraw()
	elif event.keycode in [KEY_SPACE,KEY_ENTER] and stage == "intro": skip_intro()
	elif event.keycode in [KEY_A,KEY_LEFT]: stroke("left",Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
	elif event.keycode in [KEY_D,KEY_RIGHT]: stroke("right",Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
	get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		# Godot can also synthesize a mouse event for the first touch. The
		# native touch is authoritative here; never paddle or toggle twice.
		if event.device == -1: return
		_pointer(event.position,event.pressed,-1)
	elif event is InputEventScreenTouch:
		_pointer(event.position,event.pressed,event.index)

func _pointer(point: Vector2,pressed: bool,id: int) -> void:
	if pressed:
		for action: String in controls:
			if controls[action].has_point(point):
				if action=="skip": skip_intro()
				elif action=="replay": restart()
				elif action=="pause": paused=not paused;touch_starts.clear()
				else: touch_starts[id]={"side":action,"start":point}
				accept_event();queue_redraw();return
	elif touch_starts.has(id):
		var intent: Dictionary=touch_starts[id]
		touch_starts.erase(id)
		stroke(intent.side,point.y-float(intent.start.y)>22)
		accept_event()

func _screen(point: Vector2) -> Vector2:
	return size/2+(point-camera)*scale_factor()

func scale_factor() -> float:
	return world_zoom*maxf(0.55,minf(size.x/1280.0,size.y/720.0))

func _ellipse(point: Vector2,radii: Vector2,color: Color,width: float=1.5) -> void:
	var points:=PackedVector2Array()
	for i: int in range(33): points.append(point+Vector2(cos(TAU*i/32),sin(TAU*i/32))*radii)
	draw_polyline(points,color,width,true)

func _sprite(frame: int,point: Vector2,heading: float,alpha: float=1.0) -> void:
	var index: int=clampi(frame,0,7)
	var z: float=scale_factor()*0.27
	var tilt: float=clampf(wrapf(heading-PI,-PI,PI),-0.65,0.65)
	draw_set_transform(_screen(point),tilt,Vector2.ONE*z)
	draw_texture_rect_region(swan_atlas,Rect2(-SPRITE_ANCHORS[index],SPRITE_REGIONS[index].size),SPRITE_REGIONS[index],Color(1,1,1,alpha))
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	if lake_plate == null: return
	var z: float=scale_factor()
	var origin: Vector2=size/2-camera*z
	draw_rect(Rect2(Vector2.ZERO,size),Color("0b1b24"))
	draw_texture_rect(lake_plate,Rect2(origin,Vector2(1672,941)*z),false)
	# Source-derived clean water is restricted to the opening. The gate itself is
	# a separate, simplified native wood/rope object at that fence.
	var patch:=Rect2(915,264,58,119)
	draw_texture_rect_region(gate_cleanplate,Rect2(origin+patch.position*z,patch.size*z),patch)
	# Feather only the outer join back into the unchanged authored background.
	for edge: int in range(7):
		var blend: float=1.0-float(edge+1)/8.0
		for strip: Rect2 in [Rect2(patch.position+Vector2(edge,0),Vector2(1,patch.size.y)),Rect2(patch.position+Vector2(patch.size.x-1-edge,0),Vector2(1,patch.size.y)),Rect2(patch.position+Vector2(0,edge),Vector2(patch.size.x,1)),Rect2(patch.position+Vector2(0,patch.size.y-1-edge),Vector2(patch.size.x,1))]:
			draw_texture_rect_region(lake_plate,Rect2(origin+strip.position*z,strip.size*z),strip,Color(1,1,1,blend))
	var gate_angle: float=-1.15*(float(current_pose.get("gate",1)) if stage=="intro" else 1.0)
	draw_set_transform(_screen(Vector2(938,264)),gate_angle,Vector2.ONE*z)
	# The hinged leaf is a transparent native rope/wood object. It carries no
	# rectangular water pixels when it rotates away from the opening.
	draw_line(Vector2(0,0),Vector2(0,117),Color("263125"),8)
	draw_line(Vector2(-1,0),Vector2(-1,117),Color("9b7b43"),4)
	draw_line(Vector2(5,4),Vector2(5,114),Color("51462d"),3)
	for rung: int in range(8,113,16):
		draw_line(Vector2(-4,rung),Vector2(9,rung+4),Color("6e613a"),3)
	draw_circle(Vector2.ZERO,5,Color("b39762"))
	draw_circle(Vector2(0,117),4,Color("8f744c"))
	draw_set_transform(Vector2.ZERO)
	for wake: Dictionary in trail:
		var age: float=clock-float(wake.born)
		var opacity: float=(1-age/1.6)*0.33
		_ellipse(_screen(wake.point),Vector2(18+age*30,5+age*9)*z,Color(.75,.94,1,opacity),1.3*z)
	var p: Vector2=current_pose.position if stage=="intro" else swan.position
	var heading: float=float(current_pose.heading) if stage=="intro" else swan.heading
	var frame: int=int(current_pose.frame) if stage=="intro" else (1 if swan.phase=="charge_warning" else 6 if swan.phase=="charge" else 0)
	var alpha: float=float(current_pose.reveal) if stage=="intro" else 1.0
	_ellipse(_screen(p+Vector2(0,2)),Vector2(42,12)*z,Color(.02,.12,.16,.35*alpha),3*z)
	if stage=="intro":
		var blend: float=float(current_pose.blend)
		# Pixel animation uses complete opaque poses, not double-exposed birds.
		_sprite(frame if blend<0.5 else int(current_pose.next_frame),p,heading,alpha)
	else: _sprite(frame,p,heading)
	if stage=="intro" and timeline.elapsed>4.75 and timeline.elapsed<6.5:
		var t: float=timeline.elapsed-4.75
		for side: int in [-1,1]:
			for n: int in range(9):
				var age: float=fmod(t+float(n)*0.073,0.65)
				var dx: float=side*(20+age*65+float(n)*1.8)
				var dy: float=-sin(age/0.65*PI)*(15+float(n)*2.3)+age*10
				draw_circle(_screen(p+Vector2(dx,dy)),(1.5+(n%3))*z,Color(.82,.97,1,(1-age/0.65)*.85))
	kayak_art.draw(self,_screen(kayak.position),z,{"heading":kayak.heading,"roll":kayak.roll,"speed":kayak.speed,"side":kayak.last_side,"strokeAgeMs":(kayak.elapsed-kayak.last_stroke)*1000},clock*1000)
	# The captured paper stays attached to the actual boat throughout the shot.
	var paper: Vector2=_screen(kayak.position+Vector2(-9,-17))
	draw_set_transform(paper,sin(clock*3)*.08,Vector2.ONE*z)
	draw_colored_polygon(PackedVector2Array([Vector2(-7,-8),Vector2(8,-7),Vector2(7,8),Vector2(-8,7)]),Color("eee5c5"))
	draw_line(Vector2(-4,-3),Vector2(4,-3),Color("827c67"),1)
	draw_line(Vector2(-4,1),Vector2(2,1),Color("827c67"),1)
	draw_set_transform(Vector2.ZERO)
	var bars: float=48*(float(current_pose.get("letterbox",0)) if stage=="intro" else 0)
	if bars>0:
		draw_rect(Rect2(0,0,size.x,bars),Color("081219"))
		draw_rect(Rect2(0,size.y-bars,size.x,bars),Color("081219"))
	_draw_hud()

func _button(label: String,rect: Rect2,action: String) -> void:
	controls[action]=rect
	draw_style_box(_panel(Color(.03,.10,.14,.90)),rect)
	draw_string(font,rect.position+Vector2(12,rect.size.y/2+6),label,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x-24,18,Color("e1eeee"))

func _panel(color: Color) -> StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=color
	style.set_corner_radius_all(5)
	style.border_color=Color(.51,.69,.71,.55)
	style.set_border_width_all(1)
	return style

func _draw_hud() -> void:
	controls.clear()
	var compact: bool=size.x<750
	var label: String="启真湖 · 黑天鹅出场" if stage=="intro" else "启真湖 · 已交还划桨"
	if compact: label="启真湖 · 黑天鹅"
	draw_string(font,Vector2(18,32),label,HORIZONTAL_ALIGNMENT_LEFT,-1,18 if compact else 22,Color("e6eee6"))
	if not capture_demo:
		_button("重播" if compact else "重播 R",Rect2(size.x-(142 if compact else 210),14,62 if compact else 94,34),"replay")
		_button(("继续" if paused else "暂停") if compact else ("继续 P" if paused else "暂停 P"),Rect2(size.x-(72 if compact else 108),14,62 if compact else 94,34),"pause")
	if stage=="intro":
		if not capture_demo: _button("跳过",Rect2(size.x-110,size.y-48,96,34),"skip")
		return
	var safe: float=maxf(0,3.5-play_time)
	var hint: String="A / D 左右交替划桨 · S + 划桨反划制动"
	if compact: hint="上划前进 · 下划反划 · 左右交替"
	if safe>0: hint=("操作已恢复 · 保护 %.1fs" if compact else "已恢复操作 · 安全缓冲 %.1f 秒") % safe
	if paused: hint="已暂停 · 点右上角继续" if compact else "已暂停，按 P 继续"
	if stage in ["caught","escaped"]: hint=("被追上了，正在重试" if stage=="caught" else "已驶出围栏 · R 重播") if compact else status
	draw_style_box(_panel(Color(.025,.09,.12,.9)),Rect2(14,size.y-60,size.x-28,46))
	draw_string(font,Vector2(28,size.y-31),hint,HORIZONTAL_ALIGNMENT_CENTER,size.x-56,16 if compact else 20,Color("e7efe4"))
	if not capture_demo:
		_button("左桨 A",Rect2(18,size.y-145,128,66),"left")
		_button("右桨 D",Rect2(size.x-146,size.y-145,128,66),"right")
		if compact: draw_string(font,Vector2(24,size.y-156),"上划前进，下划后退",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("e4efe6"))
