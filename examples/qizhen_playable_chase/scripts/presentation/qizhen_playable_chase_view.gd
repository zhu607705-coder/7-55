extends Control
## Isolated playable acceptance level. No State/saves/main-line completion authority.
const Model=preload("res://scripts/games/qizhen_playable_chase.gd")
const Rig=preload("res://scripts/presentation/kayak_rig.gd")
const SwanActor=preload("res://scripts/presentation/qizhen_chase_swan_actor.gd")
const HOLD_CADENCE: float=.46
var game: RefCounted=Model.new()
var rig: Node2D
var bird: Node2D
var hud: Node2D
var lake: Texture2D
var font: Font
var controls: Dictionary={}
var fingers: Dictionary={}
var keys: Dictionary={}
var held_age: float=0
var next_side: String="left"
var intro_clock: float=0
var intro_seen: bool=false
var total_attempts: int=0
var telemetry: FileAccess
var trace_clock: float=0
var previous_outcome: String="running"
var screenshot_requested: bool=false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	lake=load("res://assets/rpg/interiors/qizhen_lake_channel.png")
	font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	bird=SwanActor.new();bird.name="BlackSwan";add_child(bird)
	rig=Rig.new();rig.name="LayeredKayak";rig.z_index=2;add_child(rig)
	hud=Node2D.new();hud.name="PlayableHUD";hud.z_index=10;add_child(hud);hud.draw.connect(_draw_hud)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--trace="):telemetry=FileAccess.open(arg.trim_prefix("--trace="),FileAccess.WRITE)
	restart(false)

func restart(skip_intro: bool=true) -> void:
	total_attempts+=1;game.reset();rig.reset();fingers.clear();keys.clear()
	intro_clock=0;held_age=0;trace_clock=0;next_side="left";previous_outcome="running"
	bird.reset(game.swan_position)
	if skip_intro:begin_play()
	_sync_visuals(0,true);_trace("restart");queue_redraw()

func begin_play() -> void:
	if not game.intro or game.paused:return
	game.begin();intro_seen=true;fingers.clear();keys.clear();held_age=0;rig.reset()
	_trace("begin");queue_redraw()

func set_paused(value: bool) -> void:
	if game.outcome!="running":return
	game.set_paused(value);keys.clear();fingers.clear();held_age=0;rig.set_paused(value)
	_trace("pause" if value else "resume");queue_redraw()

func stroke(side: String, reverse: bool=false) -> bool:
	if not game.stroke(side,reverse):return false
	rig.request_stroke(side,reverse);next_side="right" if side=="left" else "left"
	_trace("stroke",{"side":side,"reverse":reverse});return true

func _process(delta: float) -> void:
	var dt: float=minf(maxf(delta,0),.05)
	if not game.paused:
		if game.intro:
			intro_clock+=dt
			if intro_clock>=4.55:begin_play()
		elif game.outcome=="running":
			_process_hold(dt);game.step(dt)
			if game.outcome!=previous_outcome:
				keys.clear();fingers.clear();held_age=0;rig.reset();_trace("outcome",game.result());previous_outcome=game.outcome
		_sync_visuals(dt)
		rig.advance(dt)
		trace_clock+=dt
		if trace_clock>=.25:_trace("frame");trace_clock=0
	queue_redraw()

func _process_hold(dt: float) -> void:
	var left: bool=keys.has("left")
	var right: bool=keys.has("right")
	var cruise: bool=keys.has("cruise")
	var reverse: bool=keys.has("reverse")
	for press: Dictionary in fingers.values():
		press.age=float(press.age)+dt
		if (not bool(press.sent) and float(press.age)>=.18) or bool(press.get("pending_reverse",false)):
			if stroke(next_side if press.action=="cruise" else press.action,bool(press.reverse)):
				press.sent=true;press.pending_reverse=false;held_age=0
		if not bool(press.sent):continue
		left=left or press.action=="left"
		right=right or press.action=="right"
		cruise=cruise or press.action=="cruise"
		reverse=reverse or bool(press.get("reverse",false))
	if not(left or right or cruise):held_age=0;return
	held_age+=dt
	if held_age<HOLD_CADENCE:return
	held_age-=HOLD_CADENCE
	var side: String=("left" if left else "right") if left!=right else next_side
	stroke(side,reverse)

func _sync_visuals(dt: float,snap: bool=false) -> void:
	var z: float=world_scale()
	rig.sync_pose(screen(game.position),game.heading,game.speed,game.roll,z,dt,snap,game.position)
	bird.zoom=z;bird.origin=world_origin()
	var swan_point: Vector2=game.swan_position
	if game.intro:swan_point+=Vector2(45,-10)*(1-smoothstep(2.4,3.6,intro_clock))
	bird.advance(dt,swan_point,game.swan_heading,game.swan_phase,intro_clock if game.intro else -1.0)

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and rig!=null:set_paused(true)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or event.echo:return
	var action: String=""
	if event.keycode in [KEY_A,KEY_LEFT]:action="left"
	elif event.keycode in [KEY_D,KEY_RIGHT]:action="right"
	elif event.keycode in [KEY_S,KEY_DOWN]:action="reverse"
	elif event.keycode==KEY_SPACE:action="cruise"
	if not action.is_empty():
		if event.pressed:
			if game.intro and not game.paused and action=="cruise":
				begin_play();keys["cruise"]=true;stroke(next_side)
			elif not game.paused and game.outcome=="running":
				keys[action]=true
				if action in ["left","right"]:stroke(action,keys.has("reverse"))
				elif action=="cruise":stroke(next_side,keys.has("reverse"))
		else:keys.erase(action)
	elif event.pressed:
		if event.keycode==KEY_R:restart(true)
		elif event.keycode in [KEY_P,KEY_ESCAPE]:set_paused(not game.paused)
		elif event.keycode==KEY_ENTER and game.intro:begin_play()
	get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.device==-1:return
		pointer(event.position,event.pressed,-1)
	elif event is InputEventScreenTouch:pointer(event.position,event.pressed,event.index)
	elif event is InputEventScreenDrag:pointer_drag(event.position,event.index)
	elif event is InputEventMouseMotion and fingers.has(-1):pointer_drag(event.position,-1)

func pointer(at: Vector2,pressed: bool,id: int) -> void:
	if not pressed:
		if fingers.has(id) and not bool(fingers[id].sent):
			var intent: Dictionary=fingers[id]
			stroke(next_side if intent.action=="cruise" else intent.action,bool(intent.reverse))
		fingers.erase(id);return
	if fingers.has(id):return
	for action: String in controls:
		if not controls[action].has_point(at):continue
		if action=="pause":set_paused(not game.paused)
		elif action=="retry":restart(true)
		elif action=="begin":begin_play()
		elif not game.paused and not game.intro and game.outcome=="running":
			fingers[id]={"action":action,"start":at,"reverse":false,"age":0.0,"sent":false}
		accept_event();return

func pointer_drag(at: Vector2,id: int) -> void:
	if not fingers.has(id):return
	var intent: Dictionary=fingers[id]
	var reverse: bool=at.y-float(intent.start.y)>24
	if reverse and not bool(intent.reverse):
		intent.reverse=true
		if stroke(next_side if intent.action=="cruise" else intent.action,true):
			intent.sent=true;held_age=0
		else:intent.pending_reverse=true
	else:intent.reverse=reverse
	accept_event()

func world_scale() -> float:
	return minf(size.x/1672.0,size.y/941.0)

func world_origin() -> Vector2:
	return (size-Vector2(1672,941)*world_scale())/2

func screen(point: Vector2) -> Vector2:
	return world_origin()+point*world_scale()

func _trace(kind: String,extra: Dictionary={}) -> void:
	if telemetry==null:return
	var line: Dictionary={"event":kind,"wall_usec":Time.get_ticks_usec(),"attempt":total_attempts,"elapsed":game.elapsed,"intro":game.intro,"paused":game.paused,"outcome":game.outcome,"position":[game.position.x,game.position.y],"heading":game.heading,"speed":game.speed,"swan":[game.swan_position.x,game.swan_position.y],"swan_phase":game.swan_phase,"strokes":game.accepted_inputs.size(),"collisions":game.collisions}
	line.merge(extra,true);telemetry.store_line(JSON.stringify(line));telemetry.flush()

func _draw() -> void:
	if lake==null:return
	var z: float=world_scale()
	draw_rect(Rect2(Vector2.ZERO,size),Color("091c22"))
	draw_texture_rect(lake,Rect2(world_origin(),Vector2(1672,941)*z),false)
	# Local, visible rope boom. Its rectangles are the exact collision solids.
	for block: Dictionary in game.gate_obstacles:
		var a: Vector2=screen(Vector2(block.left,block.top))
		var b: Vector2=screen(Vector2(block.right,block.bottom))
		draw_rect(Rect2(a,b-a),Color(.05,.12,.12,.20))
		for x: float in [float(block.left)+4,float(block.right)-4]:
			draw_line(screen(Vector2(x,block.top)),screen(Vector2(x,block.bottom)),Color("433d2b"),4*z)
			draw_line(screen(Vector2(x-1,block.top)),screen(Vector2(x-1,block.bottom)),Color("a89155"),2*z)
		for y: float in range(int(block.top+5),int(block.bottom),38):
			draw_rect(Rect2(screen(Vector2(block.left-2,y)),Vector2(24,10)*z),Color("60482e"))
			draw_rect(Rect2(screen(Vector2(block.left-1,y)),Vector2(22,3)*z),Color("bc9157"))
			draw_line(screen(Vector2(block.left+3,y+12)),screen(Vector2(block.right-3,minf(y+36,block.bottom))),Color("6d6541"),2*z)
	var berth: Rect2=Model.BERTH
	draw_rect(Rect2(screen(berth.position),berth.size*z),Color(.3,.85,.63,.18))
	draw_rect(Rect2(screen(berth.position),berth.size*z),Color(.7,.96,.72,.85),2)
	# The berth bumper is visual only outside its playable water rectangle.
	draw_line(screen(Vector2(100,446)),screen(Vector2(100,550)),Color("785c3c"),8*z)
	var arrow_color:=Color(.86,.91,.71,.7)
	for p: Vector2 in [Vector2(920,300),Vector2(680,285),Vector2(680,650),Vector2(390,500)]:
		var s: Vector2=screen(p)
		draw_polyline(PackedVector2Array([s+Vector2(12,-7)*z,s,s+Vector2(12,7)*z]),arrow_color,2*z,false)
	# Telegraph remains fixed after aim-lock. It is a danger lane, not a target.
	if not game.intro and game.swan_phase in ["charge_warning","charge"]:
		var direction: Vector2=Vector2.from_angle(game.swan_attack_heading)
		var a: Vector2=screen(game.swan_lock_origin)
		var b: Vector2=screen(game.swan_lock_origin+direction*540)
		var across: Vector2=direction.orthogonal()*28*z
		var col:=Color(1,.58,.25,.13 if game.swan_phase=="charge_warning" else .23)
		draw_colored_polygon(PackedVector2Array([a+across,b+across,b-across,a-across]),col)
		draw_dashed_line(a,b,Color(1,.76,.40,.85),2,9*z)
	hud.queue_redraw()

func _text(text: String,at: Vector2,font_size: int=18,color: Color=Color("e1eadd"),width: float=-1,align: HorizontalAlignment=HORIZONTAL_ALIGNMENT_LEFT) -> void:
	hud.draw_string(font,at,text,align,width,font_size,color)

func _button(label: String,rect: Rect2,action: String,active: bool=false) -> void:
	controls[action]=rect
	hud.draw_rect(rect,Color(.17,.35,.35,.96) if active else Color(.035,.12,.16,.94))
	hud.draw_rect(rect,Color("93b7aa"),false,1)
	_text(label,rect.position+Vector2(8,rect.size.y/2+6),16 if size.x<750 else 19,Color("edf0df"),rect.size.x-16,HORIZONTAL_ALIGNMENT_CENTER)

func _draw_hud() -> void:
	controls.clear()
	var compact: bool=size.x<750
	var top: float=54 if compact else 66
	hud.draw_rect(Rect2(0,0,size.x,top),Color(.025,.08,.11,.96))
	_text("启真湖 · 返航" if compact else "7:55  启真湖 · 带着纸条返航",Vector2(16,26),16 if compact else 22)
	var sub: String="绕浮排 · 对开口 · 慢靠岸" if compact else "浮排上下都能走 · 浮绳内减速靠岸"
	if game.intro:sub="天鹅出场后，船只由你的划桨推进"
	_text(sub,Vector2(16,46 if compact else 52),12 if compact else 16,Color("afcbbd"))
	_button("继续" if game.paused else "暂停",Rect2(size.x-142,10,62,32),"pause")
	_button("重试",Rect2(size.x-74,10,62,32),"retry")
	var y: float=size.y-(100 if compact else 123)
	hud.draw_rect(Rect2(0,y,size.x,size.y-y),Color(.025,.08,.11,.96))
	var hint: String=game.hint
	if game.intro:hint="纸条刚收起，身后响起了拍水声"
	elif game.paused:hint="已暂停 · 松开按键后继续"
	_text(hint,Vector2(16,y+23),14 if compact else 20,Color("f0ddb1"),size.x-32,HORIZONTAL_ALIGNMENT_CENTER)
	if game.intro:
		_button("开始划行 / 空格",Rect2(size.x/2-130,y+36,260,43),"begin")
	elif game.outcome=="running":
		var w: float=minf(105,(size.x-200)/2) if compact else 160
		var middle: float=160 if compact else 310
		_button("左桨" if compact else "左桨 A",Rect2(size.x/2-middle/2-w-10,y+36,w,42),"left",keys.has("left"))
		_button("按住划行" if compact else "按住交替划行 / 空格",Rect2(size.x/2-middle/2,y+36,middle,42),"cruise",keys.has("cruise") or not fingers.is_empty())
		_button("右桨" if compact else "右桨 D",Rect2(size.x/2+middle/2+10,y+36,w,42),"right",keys.has("right"))
		_text("松手收桨 · 下拖反划制动" if compact else "点按左右桨转向 · 松手收桨 · S + 划桨 / 按住后下拖：反划制动",Vector2(12,size.y-8),12 if compact else 16,Color("afcbbd"),size.x-24,HORIZONTAL_ALIGNMENT_CENTER)
	else:
		_button("再试一趟 / R",Rect2(size.x/2-130,y+36,260,43),"retry")
	# Context at the actual feature, not a stack of unrelated tutorial panels.
	if not game.intro and game.outcome=="running":
		_world_label("上方水路",Vector2(560,248),compact)
		_world_label("下方水路",Vector2(560,709),compact)
		_world_label("对准开口",Vector2(270,478),compact)
		_world_label("安全泊位",Vector2(105,438),compact)
		var speed_label: String="船速 %.0f  ·  碰撞 %d  ·  %.1f s" % [absf(game.speed),game.collisions,game.elapsed]
		_text(speed_label,Vector2(16,top+25),12 if compact else 16,Color("f0e4c7"))
	if game.paused or game.outcome!="running":
		var panel_h: float=maxf(150,size.y*.30)
		var panel_y: float=minf(size.y*.29,y-panel_h-10)
		var rect:=Rect2(size.x*(.04 if compact else .18),panel_y,size.x*(.92 if compact else .64),panel_h)
		hud.draw_rect(rect,Color(.025,.08,.11,.96));hud.draw_rect(rect,Color("8aafa4"),false,1)
		var title: String="暂停" if game.paused else ("靠岸了" if game.outcome=="won" else "这次没能甩开它")
		_text(title,rect.position+Vector2(18,40),22 if compact else 30,Color("ebead1"),rect.size.x-36,HORIZONTAL_ALIGNMENT_CENTER)
		var detail: String="P / 右上角继续" if game.paused else ("磁性扣脱落，纸条再次逃离。" if game.outcome=="won" else game.hint)
		_text(detail,rect.position+Vector2(18,78),14 if compact else 20,Color("c1d9ca"),rect.size.x-36,HORIZONTAL_ALIGNMENT_CENTER)
		if game.outcome=="won":_text("下一段：3.5 未同步记录",rect.position+Vector2(18,112),14 if compact else 21,Color("f0dca6"),rect.size.x-36,HORIZONTAL_ALIGNMENT_CENTER)
		elif not game.paused:_text("R / 下方重试，直接回到划桨",rect.position+Vector2(18,112),14 if compact else 18,Color("f0dca6"),rect.size.x-36,HORIZONTAL_ALIGNMENT_CENTER)

func _world_label(label: String,point: Vector2,compact: bool) -> void:
	var p: Vector2=screen(point)
	var fs: int=12 if compact else 17
	p.y=clampf(p.y,(54 if compact else 66)+fs+6,size.y-(100 if compact else 123)-9)
	var width: float=font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
	hud.draw_rect(Rect2(p+Vector2(-5,-fs),Vector2(width+10,fs+6)),Color(.025,.08,.11,.78))
	_text(label,p,fs,Color("e5e8c6"))
