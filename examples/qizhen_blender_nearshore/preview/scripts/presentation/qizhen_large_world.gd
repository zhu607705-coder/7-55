extends Node2D
## Independent larger-world prototype. It has no State/save/story writes.
const Geo=preload("res://scripts/games/lake_geometry.gd")
const Model=preload("res://scripts/games/large_world_model.gd")
const Rig=preload("res://scripts/presentation/kayak_rig.gd")
const Swim=preload("res://scripts/presentation/qizhen_swan_swim_visual.gd")
var game: RefCounted=Model.new()
var rig: Node2D
var cam: Camera2D
var terrain: Node2D
var water_fx: Node2D
var markers: Node2D
var hud: Node2D
var swan_node: Node2D
var swim: RefCounted=Swim.new()
var font: Font
var overview: bool=false
var title_open: bool=true
var keys: Dictionary={}
var clock: float=0
var event_cursor: int=0
var last_progress: int=0
var goal_flash: float=0
var auto_control: bool=false
var capture_mode: bool=false
var test_turn: float=0
var test_thrust: bool=false
var test_brake: bool=false
var test_use: bool=false
var camera_extent: Rect2
var minimap_rect=Rect2(1084,106,174,300)
# Pointer zones are invisible until used. Targets always receive pointer priority.
var touch_left: int=-1
var touch_right: int=-1
var touch_origin:=Vector2.ZERO
var touch_vector:=Vector2.ZERO
var touch_right_position:=Vector2.ZERO
var was_thrust: bool=false
var touch_mode: bool=false
var touch_use: bool=false
var touch_use_goal: int=-1
var map_return_time: float=0
var map_return_from:=Vector2.ZERO
var map_return_zoom:=Vector2.ONE
var view_size:=Vector2(1280,720)
var hud_scale: float=1
var hud_size:=Vector2(1280,720)
var map_button:=Rect2()
var pause_button:=Rect2()
var play_rect:=Rect2()
var feedback_lines: Array[String]=[]
var data: Dictionary={}
var trees: Array[Dictionary]=[]
var buildings: Array[Dictionary]=[]
var reeds: Array[Vector2]=[]
var lake_poly: PackedVector2Array
var island_poly: PackedVector2Array
var trace: FileAccess
func _ready() -> void:
	font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	lake_poly=Geo.lake();island_poly=Geo.island()
	# Static geography is rendered once at a deliberate 4x pixel-art scale.
	# Actors, paddle contact, water motion and objectives stay live at viewport resolution.
	var terrain_cache:=SubViewport.new();terrain_cache.name="StaticTerrainCache"
	terrain_cache.size=Vector2i(2250,4000);terrain_cache.disable_3d=true;terrain_cache.transparent_bg=true
	terrain_cache.render_target_update_mode=SubViewport.UPDATE_ONCE;add_child(terrain_cache)
	terrain=Node2D.new();terrain.scale=Vector2.ONE*.25;terrain_cache.add_child(terrain);terrain.draw.connect(_draw_terrain)
	var terrain_sprite:=Sprite2D.new();terrain_sprite.name="CachedTerrain";terrain_sprite.texture=terrain_cache.get_texture();terrain_sprite.centered=false;terrain_sprite.scale=Vector2.ONE*4;terrain_sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;add_child(terrain_sprite)
	water_fx=Node2D.new();add_child(water_fx);water_fx.draw.connect(_draw_water)
	markers=Node2D.new();add_child(markers);markers.draw.connect(_draw_markers)
	swan_node=Node2D.new();add_child(swan_node);swan_node.draw.connect(_draw_swan);swim.reset(game.swan)
	rig=Rig.new();rig.name="ExistingLayeredPaddlingRig";add_child(rig)
	cam=Camera2D.new();add_child(cam);cam.position=game.position;cam.zoom=Vector2.ONE*.9;cam.make_current()
	var layer:=CanvasLayer.new();add_child(layer);hud=Node2D.new();layer.add_child(hud);hud.draw.connect(_draw_hud)
	get_viewport().size_changed.connect(_on_viewport_changed)
	_update_layout()
	_generate_terrain();terrain.queue_redraw()
	for arg in OS.get_cmdline_user_args():
		if arg=="--overview":overview=true;title_open=false
		if arg=="--no-title":title_open=false
		if arg.begins_with("--trace="):trace=FileAccess.open(arg.trim_prefix("--trace="),FileAccess.WRITE)
	_sync(0,true)
func _generate_terrain() -> void:
	var rng:=RandomNumberGenerator.new();rng.seed=7552026
	# A restrained campus backdrop. Building footprint details are game adaptation.
	for i in range(4000):
		var pos:=Vector2(rng.randf_range(2200,8500),rng.randf_range(1200,15000))
		if Geo.water(pos):continue
		var shoreline: bool=false
		for dir in [Vector2(160,0),Vector2(-160,0),Vector2(0,160),Vector2(0,-160)]:
			if Geo.water(pos+dir):shoreline=true
		if shoreline or Geometry2D.is_point_in_polygon(pos,island_poly):trees.append({"p":pos,"size":rng.randf_range(27,62),"tone":rng.randi_range(0,4)})
	for i in range(16):
		var y: float=3500+i*570
		buildings.append({"rect":Rect2(2600+(i%2)*60,y,560,190),"tone":i%3})
		if i<14:buildings.append({"rect":Rect2(7950,y+100,620,220),"tone":(i+1)%3})
	for poly in [lake_poly,island_poly]:
		for i in range(poly.size()):
			var a: Vector2=poly[i];var b: Vector2=poly[(i+1)%poly.size()]
			var count: int=maxi(1,int(a.distance_to(b)/34))
			for j in range(count):
				var p: Vector2=a.lerp(b,float(j)/count)
				if rng.randf()<.57:reeds.append(p)
func _blocked() -> bool:
	return title_open or overview or game.paused or game.status!="running"
func _process(dt: float) -> void:
	var d: float=minf(dt,.05)
	# Resume the presentation before accepting this frame's stroke events.
	rig.set_paused(_blocked())
	if not _blocked():
		clock+=d;goal_flash=maxf(0,goal_flash-d)
		if not auto_control:
			var turn: float=float(keys.has(KEY_D) or keys.has(KEY_RIGHT))-float(keys.has(KEY_A) or keys.has(KEY_LEFT))
			if touch_left!=-1 and touch_vector.length()>12:
				turn=clampf(angle_difference(game.heading,touch_vector.angle())/.65,-1,1)
			var thrust: bool=keys.has(KEY_SPACE) or keys.has(KEY_W) or keys.has(KEY_UP) or touch_right!=-1
			var stop: bool=keys.has(KEY_S) or keys.has(KEY_DOWN)
			if thrust or absf(turn)>.1 or game.progress!=touch_use_goal:touch_use=false
			if touch_use and game.position.distance_to(game.route_goals[game.progress].point)>=float(game.route_goals[game.progress].radius):touch_use=false
			game.input(thrust,turn,stop or touch_use,keys.has(KEY_E) or touch_use)
		else:game.input(test_thrust,test_turn,test_brake,test_use)
		if was_thrust and not game.throttle:rig.motion.pending.clear()
		was_thrust=game.throttle
		game.step(d)
	if game.progress!=last_progress:goal_flash=3.5;last_progress=game.progress;touch_use=false
	while event_cursor<game.events.size():
		var event: Dictionary=game.events[event_cursor];event_cursor+=1
		if event.kind=="stroke":rig.request_stroke(event.side)
	_sync(d)
	if trace!=null and Engine.get_process_frames()%15==0:trace.store_line(JSON.stringify(game.result()));trace.flush()
func _follow_target() -> Vector2:
	var goal: Dictionary=game.route_goals[game.progress]
	var interacting: bool=game.interact or game.action_hold>0
	var lead: float=0 if interacting else 155*pow(clampf(game.speed/285,0,1),1.35)
	var target: Vector2=game.position+Vector2.from_angle(game.heading)*lead
	# A nearby usable object shares the central clear area with the boat.
	if goal.type!="gate" and game.position.distance_to(goal.point)<float(goal.radius)+160:
		target=game.position.lerp(goal.point,.24)
	return target
func _fit_camera_target(point: Vector2,zoom_value: Vector2) -> Vector2:
	# Keep the complete boat clear of the fixed top HUD and bottom captions.
	# The lead shortens in a shallow landscape viewport instead of hiding it.
	var boat_at: Vector2=view_size*.5+(game.position-point)*zoom_value
	var safe:=Rect2(Vector2(48,146)*hud_scale,view_size-Vector2(96,270)*hud_scale)
	boat_at=boat_at.clamp(safe.position,safe.end)
	return game.position+(view_size*.5-boat_at)/zoom_value
func _sync(dt: float,snap: bool=false) -> void:
	cam.rotation=0 # North-up, including turns, map transitions and touch input.
	if overview:
		cam.position=Vector2(5400,8050)
		cam.zoom=Vector2.ONE*minf((view_size.x-40)/6800,(view_size.y-170*hud_scale)/15000)
	else:
		var target: Vector2=_follow_target()
		var base_zoom: float=lerpf(.84,.64,clampf(game.speed/285,0,1))
		var target_zoom: Vector2=Vector2.ONE*base_zoom*clampf(minf(view_size.x/1000,view_size.y/720),.62,1.2)
		target=_fit_camera_target(target,target_zoom)
		if snap:cam.position=target;cam.zoom=target_zoom;map_return_time=0
		elif map_return_time>0 and not _blocked():
			map_return_time=maxf(0,map_return_time-dt)
			var t: float=smoothstep(0,1,1-map_return_time/.24)
			cam.position=map_return_from.lerp(target,t);cam.zoom=map_return_zoom.lerp(target_zoom,t)
		elif not _blocked():
			cam.position=cam.position.lerp(target,1-exp(-9*dt))
			cam.zoom=cam.zoom.lerp(target_zoom,1-exp(-5*dt))
	if not overview and map_return_time<=0:cam.position=_fit_camera_target(cam.position,cam.zoom)
	cam.force_update_scroll()
	rig.sync_pose(game.position,game.heading,game.speed,game.steering*.12,1,dt,snap,game.position)
	rig.set_paused(_blocked());rig.advance(dt)
	if not _blocked():swim.update(dt,game.swan,game.swan_heading,"accelerate" if game.swan_phase=="charge" else "swim")
	water_fx.queue_redraw();markers.queue_redraw();swan_node.queue_redraw();hud.queue_redraw()
func _clear_input() -> void:
	keys.clear();was_thrust=false;touch_left=-1;touch_right=-1;touch_vector=Vector2.ZERO;touch_use=false;touch_use_goal=-1
	game.input(false,0,false,false)
	if rig!=null:rig.motion.pending.clear()
func _set_overview(value: bool) -> void:
	if overview==value:return
	_clear_input()
	overview=value
	if not value:
		map_return_time=.24;map_return_from=cam.position;map_return_zoom=cam.zoom
	rig.set_paused(_blocked())
func _restart() -> void:
	game.reset();rig.reset();event_cursor=0;_clear_input();title_open=false;overview=false;last_progress=0;goal_flash=0;map_return_time=0
	_sync(0,true)
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or event.echo:return
	if not event.pressed:keys.erase(event.keycode);return
	if event.keycode in [KEY_ENTER,KEY_SPACE] and title_open:
		title_open=false;_clear_input()
		if event.keycode==KEY_SPACE:keys[KEY_SPACE]=true
	elif event.keycode==KEY_M:_set_overview(not overview)
	elif event.keycode in [KEY_P,KEY_ESCAPE]:
		game.paused=not game.paused;_clear_input();rig.set_paused(_blocked())
	elif event.keycode==KEY_R:_restart()
	elif not _blocked():keys[event.keycode]=true
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		touch_mode=true
		if event.pressed and not event.canceled:_pointer_down(event.index,event.position)
		else:_pointer_up(event.index)
	elif event is InputEventScreenDrag:
		_pointer_move(event.index,event.position)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.device!=InputEvent.DEVICE_ID_EMULATION:
		if event.pressed:_pointer_down(-2,event.position)
		else:_pointer_up(-2)
	elif event is InputEventMouseMotion and event.device!=InputEvent.DEVICE_ID_EMULATION:
		_pointer_move(-2,event.position)
func _pointer_down(id: int,at: Vector2) -> void:
	var ui: Vector2=at/hud_scale
	if title_open:title_open=false;_clear_input();return
	if map_button.has_point(ui):_set_overview(not overview);return
	if pause_button.has_point(ui):
		game.paused=not game.paused;_clear_input();rig.set_paused(_blocked());return
	if overview:_set_overview(false);return
	if game.paused:game.paused=false;_clear_input();return
	if game.status!="running":_restart();return
	var goal: Dictionary=game.route_goals[game.progress]
	var target: Vector2=world_to_screen(goal.point)
	# Object hit-testing happens BEFORE thumb zones, at every screen position.
	if goal.type!="gate" and at.distance_to(target)<58*hud_scale:
		if game.position.distance_to(goal.point)<float(goal.radius):
			_clear_input()
			touch_use=true;touch_use_goal=game.progress
		else:game.feedback="再靠近目标后点按，减速后自动完成操作。";game.feedback_age=0
		return
	if not play_rect.has_point(ui):return
	if at.x<view_size.x*.5 and touch_left==-1:
		touch_left=id;touch_origin=at;touch_vector=Vector2.ZERO;touch_use=false
	elif at.x>=view_size.x*.5 and touch_right==-1:
		touch_right=id;touch_right_position=at;touch_use=false
func _pointer_move(id: int,at: Vector2) -> void:
	if id==touch_left:touch_vector=(at-touch_origin).limit_length(90*hud_scale)
	if id==touch_right:touch_right_position=at
func _pointer_up(id: int) -> void:
	if id==touch_left:touch_left=-1;touch_vector=Vector2.ZERO
	if id==touch_right:
		touch_right=-1
		# Let the current recovery finish, but never play a buffered extra stroke.
		rig.motion.pending.clear()
func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and rig!=null and not auto_control:
		game.paused=true;_clear_input();rig.set_paused(true)
func _on_viewport_changed() -> void:
	_clear_input();_update_layout()
	# Rotation cannot preserve stale finger coordinates or a distant map camera.
	if cam!=null:_sync(0,true)
func _update_layout() -> void:
	view_size=get_viewport_rect().size.max(Vector2(320,280))
	hud_scale=clampf(minf(view_size.x/720,view_size.y/720),1,1.4)
	hud_size=view_size/hud_scale
	if hud!=null:hud.scale=Vector2.ONE*hud_scale
	map_button=Rect2(hud_size.x-112,14,52,44)
	pause_button=Rect2(hud_size.x-56,14,44,44)
	play_rect=Rect2(12,106,hud_size.x-24,hud_size.y-194)
	minimap_rect=Rect2(hud_size.x-130,74,118,196) if hud_size.x>1050 else Rect2()
func world_to_screen(point: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform()*point
func _poly_closed(poly: PackedVector2Array) -> PackedVector2Array:
	var copy:=PackedVector2Array(poly);copy.append(poly[0]);return copy
func _draw_terrain() -> void:
	terrain.draw_rect(Rect2(Vector2.ZERO,Geo.SIZE),Color("59694b"))
	var rng:=RandomNumberGenerator.new();rng.seed=755
	for x in range(1500,8900,120):
		for y in range(500,15600,120):
			var shade: float=rng.randf_range(-.018,.018)
			terrain.draw_rect(Rect2(x,y,120,120),Color(.35+shade,.42+shade,.28+shade))
	# Campus paths, broadly placed from bank relationships, not survey footprints.
	for x: float in [3500,7780]:
		terrain.draw_line(Vector2(x,1500),Vector2(x,15000),Color("849078"),90)
		terrain.draw_line(Vector2(x,1500),Vector2(x,15000),Color("b1ad8e"),57)
	for b in buildings:_draw_building(b.rect,b.tone)
	_draw_crescent()
	terrain.draw_colored_polygon(lake_poly,Color("2b5a58"))
	terrain.draw_polyline(_poly_closed(lake_poly),Color("3d4433"),44,true)
	terrain.draw_polyline(_poly_closed(lake_poly),Color("b3ad82"),21,true)
	terrain.draw_polyline(_poly_closed(lake_poly),Color("799284"),8,true)
	# Inset shallow-water contour, dark center and bright edge make the shoreline legible.
	var shore_offsets: Array[PackedVector2Array]=Geometry2D.offset_polygon(lake_poly,-53)
	for poly in shore_offsets:terrain.draw_colored_polygon(poly,Color("255351"))
	for poly in Geometry2D.offset_polygon(lake_poly,-145):terrain.draw_colored_polygon(poly,Color("244e4d"))
	terrain.draw_colored_polygon(island_poly,Color("69784d"))
	terrain.draw_polyline(_poly_closed(island_poly),Color("333e2d"),40,true)
	terrain.draw_polyline(_poly_closed(island_poly),Color("a8a47b"),18,true)
	terrain.draw_polyline(_poly_closed(island_poly),Color("728c7e"),6,true)
	for reed in reeds:
		for j in range(4):
			terrain.draw_line(reed+Vector2(j*4,5),reed+Vector2(j*3-5,-13-j*3),Color("9a9e62"),3)
	# Northern library-side campus landmarks. Forms are stylized, positions approximate.
	_draw_library()
	terrain.draw_line(Geo.p(778,328),Geo.p(816,320),Color("413f39"),140)
	terrain.draw_line(Geo.p(778,328),Geo.p(816,320),Color("b6b29a"),98)
	terrain.draw_line(Geo.p(778,328),Geo.p(816,320),Color("ded3aa"),8)
	for tree in trees:_draw_tree(tree.p,tree.size,tree.tone)
	_draw_dock()
func _draw_building(rect: Rect2,tone: int) -> void:
	terrain.draw_rect(Rect2(rect.position+Vector2(22,34),rect.size),Color(0.08,.14,.12,.25))
	terrain.draw_rect(rect,Color("785f4e"))
	terrain.draw_rect(Rect2(rect.position,rect.size-Vector2(0,20)),[Color("b39e7e"),Color("b6afa0"),Color("96705a")][tone])
	terrain.draw_rect(Rect2(rect.position+Vector2(12,12),rect.size-Vector2(24,44)),[Color("898975"),Color("ded5b9"),Color("a17f64")][tone])
	for x in range(int(rect.position.x+24),int(rect.end.x-14),42):
		terrain.draw_rect(Rect2(x,rect.end.y-27,25,12),Color("3e5654"))
		terrain.draw_line(Vector2(x,rect.position.y+18),Vector2(x,rect.end.y-52),Color(.2,.3,.26,.14),3)
func _draw_tree(p: Vector2,r: float,tone: int) -> void:
	var palette=[Color("365a40"),Color("4a6846"),Color("66814a"),Color("829050"),Color("4f7452")]
	terrain.draw_circle(p+Vector2(12,14),r*.88,Color(.10,.19,.14,.3))
	terrain.draw_rect(Rect2(p+Vector2(-5,0),Vector2(10,r*.9)),Color("64543b"))
	terrain.draw_circle(p,r,palette[tone].darkened(.18))
	terrain.draw_circle(p+Vector2(-r*.26,-r*.24),r*.72,palette[tone])
	terrain.draw_circle(p+Vector2(r*.21,-r*.28),r*.53,palette[tone].lightened(.1))
	terrain.draw_circle(p+Vector2(-r*.34,-r*.50),r*.27,palette[tone].lightened(.18))
	for n in range(24):
		var a: float=n*2.39996+p.x*.01
		var rad: float=sqrt(float(n)/24)*r*.86
		var leaf: Vector2=p+Vector2(cos(a),sin(a))*rad
		var q: float=4+fmod(absf(p.x+n*7),5)
		terrain.draw_rect(Rect2(leaf,Vector2(q,q*.68)),palette[tone].lightened(.09+fmod(float(n),3)*.04))

func _draw_crescent() -> void:
	var center: Vector2=Geo.p(750,343)
	var outer:=PackedVector2Array();var inner:=PackedVector2Array()
	for i in range(49):
		var a: float=lerpf(-PI*.65,PI*.65,float(i)/48)
		outer.append(center+Vector2(cos(a)*980,sin(a)*1200))
		inner.append(center+Vector2(cos(a)*800,sin(a)*1020))
	var shape:=PackedVector2Array(outer)
	for i in range(inner.size()-1,-1,-1):shape.append(inner[i])
	var shadow:=PackedVector2Array();for p in shape:shadow.append(p+Vector2(30,58))
	terrain.draw_colored_polygon(shadow,Color(.10,.16,.13,.30))
	terrain.draw_colored_polygon(shape,Color("ded6ba"))
	terrain.draw_polyline(outer,Color("f0e8cc"),18,true)
	terrain.draw_polyline(inner,Color("afad9a"),22,true)
	for i in range(1,48):
		var a: Vector2=inner[i].lerp(outer[i],.25);var b: Vector2=inner[i].lerp(outer[i],.75)
		terrain.draw_line(a,b,Color("8c9b97"),13)
	terrain.draw_circle(center+Vector2(720,180),135,Color("b1ad97"))
	terrain.draw_circle(center+Vector2(710,164),124,Color("e4ddc5"))
	terrain.draw_arc(center+Vector2(710,164),83,0,TAU,32,Color("c6c5b1"),8)
	for at in [Vector2(490,-880),Vector2(450,890)]:_draw_building(Rect2(center+at,Vector2(160,360)),1)
func _draw_library() -> void:
	var p: Vector2=Geo.p(819,342)
	_draw_building(Rect2(p+Vector2(100,280),Vector2(1020,500)),1)
	_draw_building(Rect2(p+Vector2(710,60),Vector2(350,760)),1)
	terrain.draw_rect(Rect2(p+Vector2(-20,10),Vector2(300,520)),Color(.06,.12,.12,.32))
	_draw_building(Rect2(p+Vector2(-65,-70),Vector2(240,490)),1)
	terrain.draw_rect(Rect2(p+Vector2(-50,-55),Vector2(208,455)),Color("91a6a1"))
	for x in range(7):terrain.draw_line(p+Vector2(-39+x*27,-46),p+Vector2(-39+x*27,389),Color("d0d4bd"),6)
	for y in range(13):terrain.draw_line(p+Vector2(-48,-38+y*33),p+Vector2(152,-38+y*33),Color("becab6"),3)
func _draw_dock() -> void:
	var p: Vector2=Geo.dock()+Vector2(100,-80)
	terrain.draw_rect(Rect2(p+Vector2(6,9),Vector2(190,102)),Color(.05,.12,.15,.45))
	for x in range(7):
		for y in range(4):
			var a: Vector2=p+Vector2(x*27,y*25)
			terrain.draw_rect(Rect2(a,Vector2(26,24)),Color("287fa8"))
			terrain.draw_rect(Rect2(a+Vector2(2,2),Vector2(22,19)),Color("439dc2"))
			terrain.draw_line(a+Vector2(4,5),a+Vector2(21,5),Color("73b4ca"),2)
	terrain.draw_line(p+Vector2(95,-6),p+Vector2(95,-80),Color("aca385"),33)
	for q in [Vector2(5,6),Vector2(180,6),Vector2(5,95),Vector2(180,95)]:
		terrain.draw_circle(p+q,5,Color("263d42"));terrain.draw_circle(p+q-Vector2(1,2),3,Color("c2c1a3"))
func _draw_water() -> void:
	var half: Vector2=view_size*.5/cam.zoom+Vector2(70,70)
	var origin: Vector2=cam.position-half
	var end: Vector2=cam.position+half
	var spacing: int=90 if not overview else 180
	for x in range(int(origin.x/spacing)*spacing,int(end.x),spacing):
		for y in range(int(origin.y/spacing)*spacing,int(end.y),spacing):
			var p:=Vector2(x+sin(y*.03)*30,y+sin(x*.01)*20)
			if not Geo.water(p,35):continue
			var wave: float=sin(clock*.8+x*.03+y*.013)
			water_fx.draw_line(p+Vector2(wave*6,0),p+Vector2(12+wave*6,0),Color(.56,.71,.61,.10+.06*wave),1.3)
			if (x+y)%360==0:water_fx.draw_line(p+Vector2(-8,6),p+Vector2(9,6),Color(.54,.69,.63,.10),1)
func _draw_markers() -> void:
	var goals: Array[Dictionary]=game.route_goals
	for i in range(goals.size()):
		var goal: Dictionary=goals[i];var p: Vector2=goal.point
		var current: bool=i==game.progress
		var done: bool=i<game.progress
		if overview:
			if i>0:markers.draw_line(goals[i-1].point,p,Color(.84,.73,.37,.5),13)
			markers.draw_circle(p,65,Color("edca68") if current else Color("b9bda4"))
			continue
		if not Rect2(Vector2.ZERO,view_size).grow(200).has_point(world_to_screen(p)):continue
		if goal.type in ["inspect","collect"]:
			markers.draw_circle(p+Vector2(2,8),16,Color(.01,.12,.14,.4))
			markers.draw_colored_polygon(PackedVector2Array([p+Vector2(0,-16),p+Vector2(12,8),p+Vector2(-12,8)]),Color("ddba62"))
			markers.draw_line(p+Vector2(0,-16),p+Vector2(0,-35),Color("ebcc79"),3)
		else:
			var gate_dir:=Vector2(1,0)
			if i in [2,4,5]:gate_dir=Vector2(1,.2)
			for side: float in [-1,1]:
				var at: Vector2=p+gate_dir*float(goal.radius)*side
				markers.draw_circle(at,9,Color("b9be8f") if done else Color("d4ae59"))
				markers.draw_circle(at-Vector2(0,3),6,Color("f1da8d"))
		if current:
			markers.draw_arc(p,float(goal.radius),0,TAU,48,Color(.93,.81,.44,.18+sin(clock*2)*.06),2)
	if game.swan_phase in ["warning","charge"]:
		var dir:=Vector2.from_angle(game.swan_heading)
		for j in range(16):
			var at: Vector2=game.swan_lock+dir*(j*31)
			markers.draw_line(at,at+dir*18,Color(1,.56,.21,.7),4)
func _draw_swan() -> void:
	swim.draw(swan_node,game.swan,Vector2.ZERO,1)
func _text(t: String,p: Vector2,sz: int=20,c: Color=Color("e7e4ca")) -> void:
	hud.draw_string(font,p,t,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,c)
func _panel(rect: Rect2,color: Color=Color(.035,.09,.105,.92)) -> void:
	hud.draw_style_box(_style(color),rect)
func _style(color: Color) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=color;s.corner_radius_top_left=7;s.corner_radius_top_right=7;s.corner_radius_bottom_left=7;s.corner_radius_bottom_right=7;return s
func _wrapped(t: String, width: float, sz: int) -> Array[String]:
	var lines: Array[String]=[];var line: String=""
	for ch in t:
		if font.get_string_size(line+ch,HORIZONTAL_ALIGNMENT_LEFT,-1,sz).x>width and not line.is_empty():lines.append(line);line=""
		line+=ch
	if not line.is_empty():lines.append(line)
	return lines
func _draw_lines(t: String,at: Vector2,width: float,sz: int=17,c: Color=Color("e7e4ca")) -> void:
	var lines: Array[String]=_wrapped(t,width,sz)
	for i in range(lines.size()):_text(lines[i],at+Vector2(0,i*(sz+7)),sz,c)
func _edge_hint(point: Vector2,label: String,color: Color) -> void:
	var at: Vector2=world_to_screen(point)/hud_scale
	var safe:=Rect2(46,128,hud_size.x-92,hud_size.y-260)
	if minimap_rect.has_area():safe.size.x-=125
	if safe.has_point(at):return
	var center: Vector2=world_to_screen(game.position)/hud_scale
	var direction: Vector2=(at-center).normalized()
	var edge: Vector2=center+direction*minf(safe.size.x,safe.size.y)
	edge=edge.clamp(safe.position,safe.end)
	var across: Vector2=direction.orthogonal()
	hud.draw_colored_polygon(PackedVector2Array([edge+direction*12,edge-direction*8+across*8,edge-direction*8-across*8]),color)
	_text(label,edge+Vector2(-22,27),15,color)
func _target_label_position(at: Vector2) -> Vector2:
	var boat_at: Vector2=world_to_screen(game.position)/hud_scale
	var candidates: Array[Vector2]=[at+Vector2(36,6),at+Vector2(-102,6),at+Vector2(-34,-38),at+Vector2(-34,50)]
	for pos in candidates:
		var bounds:=Rect2(pos-Vector2(0,18),Vector2(72,24))
		if play_rect.encloses(bounds) and not bounds.grow(30).has_point(boat_at):return pos
	return at+Vector2(36,6)
func _warning_rect() -> Rect2:
	var width: float=minf(320,hud_size.x-28)
	var x: float=(hud_size.x-width)*.5
	var boat_at: Vector2=world_to_screen(game.position)/hud_scale
	var goal_at: Vector2=world_to_screen(game.route_goals[game.progress].point)/hud_scale
	var candidates: Array[Rect2]=[Rect2(x,104,width,36),Rect2(x,hud_size.y-170,width,36)]
	for box in candidates:
		if not box.grow(30).has_point(boat_at) and not box.grow(28).has_point(goal_at):return box
	for box in candidates:
		if not box.grow(30).has_point(boat_at):return box
	return candidates[0]
func _feedback_text() -> String:
	if not touch_mode:return game.feedback
	return game.feedback.replace("按 M 查看全湖路线","点右上角「图」查看全湖路线").replace("按 S 收桨","松开右侧收桨")
func _draw_hud() -> void:
	var w: float=hud_size.x;var h: float=hud_size.y
	_panel(map_button,Color(.05,.12,.12,.74));_text("返" if overview else "图",map_button.position+Vector2(15,29),20)
	_panel(pause_button,Color(.05,.12,.12,.74));_text("Ⅱ",pause_button.position+Vector2(12,28),20)
	if overview:
		_panel(Rect2(14,14,w-138,68),Color(.05,.12,.12,.80));_text("启真湖 · 全湖路线",Vector2(28,42),23,Color("f0d58a"))
		_text("N ↑ 北 · 点按返回" if w<550 else "N ↑ 北 · 点按地图或按 M 返回",Vector2(28,68),16)
		var route_text: String="教学浮码头 → 湖面信号 → 岛南防水袋 → 东侧返航 → 对齐靠泊"
		var route_height: float=_wrapped(route_text,w-56,17).size()*24+40
		_panel(Rect2(14,h-route_height-14,w-28,route_height),Color(.05,.12,.12,.80))
		_draw_lines(route_text,Vector2(28,h-route_height+12),w-56,17)
		_text("游戏改编地形，实地通航未核实",Vector2(28,h-22),14,Color("a8b9a8"))
		return
	var goal: Dictionary=game.route_goals[game.progress]
	var phase: int=[0,1,2,2,3,3,3,3,4][game.progress]
	var labels=["离开教学浮码头","检查湖面信号","绕岛取回防水袋","沿东侧水道返航","低速对齐靠泊"]
	var hint: String=goal.hint
	if touch_mode and goal.type!="gate":hint="船头朝北，点按码头系泊" if goal.type=="dock" else "靠近后点按目标，自动减速"
	var hint_lines: int=_wrapped(hint,minf(w-170,684),16).size()
	_panel(Rect2(14,14,minf(w-138,720),64+maxi(0,hint_lines-1)*23),Color(.05,.12,.12,.70))
	_text("%d / 5  %s"%[phase+1,labels[phase]],Vector2(28,43),18 if w<550 else 22,Color("f0d58a"))
	_draw_lines(hint,Vector2(28,69),minf(w-170,684),16)
	if minimap_rect.has_area():_draw_minimap()
	_text("%02d:%02d   速度 %03d"%[int(game.elapsed)/60,int(game.elapsed)%60,game.speed],Vector2(20,h-20),16,Color("dedcba"))
	if capture_mode:_text("自动输入回放 · 1×",Vector2(maxf(20,w-180),h-20),14,Color("d7d4b0"))
	elif not touch_mode and w>1000:_text("W/空格 划桨  A/D 转向  S 刹停  E 操作  M 全图  P 暂停",Vector2(w-604,h-20),15,Color("aebca9"))
	_edge_hint(goal.point,"目标",Color("edda9c"))
	if game.swan_phase in ["warning","charge"]:
		_edge_hint(game.swan,"危险",Color("ffad57"))
		var warning: Rect2=_warning_rect()
		_panel(warning,Color(.22,.10,.04,.86))
		_text("黑天鹅即将冲刺 · 向侧面转向",warning.position+Vector2(15,25),17,Color("ffd48b"))
	if goal.type!="gate" and game.position.distance_to(goal.point)<float(goal.radius)+160:
		var at: Vector2=world_to_screen(goal.point)/hud_scale
		if play_rect.grow(-30).has_point(at):
			hud.draw_arc(at,28,0,TAU,40,Color(.93,.81,.44,.8),2)
			_text("点按 / E",_target_label_position(at),16,Color("f1db93"))
	if game.action_hold>0 or touch_use:
		var y: float=h-126
		_panel(Rect2(w*.5-150,y,300,52),Color(.05,.12,.12,.80));_text("保持低速，正在操作",Vector2(w*.5-128,y+24),17)
		hud.draw_rect(Rect2(w*.5-130,y+37,260,7),Color("384d49"));hud.draw_rect(Rect2(w*.5-130,y+37,260*game.action_hold/1.25,7),Color("d6be70"))
	elif game.feedback_age<4.5 and not title_open:
		var lines: Array[String]=_wrapped(_feedback_text(),w-56,17)
		var height: float=lines.size()*24+14
		_panel(Rect2(14,h-44-height,w-28,height),Color(.05,.12,.12,.72))
		_draw_lines(_feedback_text(),Vector2(28,h-44-height+24),w-56,17,Color("ece2bd"))
	if touch_left!=-1:
		var origin: Vector2=touch_origin/hud_scale
		hud.draw_arc(origin,44,0,TAU,40,Color(.8,.85,.7,.38),2)
		hud.draw_circle(origin+touch_vector/hud_scale,13,Color(.9,.85,.6,.52))
	if touch_right!=-1:
		var at: Vector2=touch_right_position/hud_scale
		hud.draw_arc(at,30,0,TAU,36,Color(.9,.82,.55,.5),2)
		_text("划",at+Vector2(-8,7),17,Color("e9d8a0"))
	if game.paused or title_open or game.status!="running":
		_panel(Rect2(Vector2.ZERO,hud_size),Color(.025,.06,.07,.58))
		var box:=Rect2(maxf(20,(w-650)*.5),maxf(14,(h-340)*.5),minf(650,w-40),340)
		_panel(box,Color(.07,.14,.14,.94));var at: Vector2=box.position+Vector2(26,45)
		_text("启真湖 · 从北岸到南岛",at,22 if w<550 else 27,Color("f1d89b"))
		if title_open:
			_draw_lines("从教学浮码头出发，寻找信号、绕岛取物并安全返航",at+Vector2(0,48),box.size.x-52,18)
			_draw_lines("键盘：W / 空格划桨，A / D 转向，S 刹停，E 操作",at+Vector2(0,103),box.size.x-52,17)
			_draw_lines("触屏：左侧拖方向，右侧按住划桨、松开收桨；直接点按目标",at+Vector2(0,151),box.size.x-52,17)
			_text("点按出发 / Enter",at+Vector2(0,251),23,Color("e9ce7b"))
		elif game.paused:
			_text("已暂停",at+Vector2(0,99),27)
			_text("点按继续 / P",at+Vector2(0,210),21)
		elif game.status=="won":
			_text("已带回防水袋，完成靠泊",at+Vector2(0,83),24)
			_draw_lines("用时 %.1f 秒 · 实际划行 %.0f 像素 · %d 次划桨"%[game.elapsed,game.travel,game.strokes],at+Vector2(0,129),box.size.x-52,17)
			_text("点按重试 / R · M 查看地图",at+Vector2(0,240),20)
		else:_text("失去平衡 · 点按重试 / R",at+Vector2(0,150),23)
func _draw_minimap() -> void:
	_panel(minimap_rect,Color(.05,.12,.12,.62))
	var origin: Vector2=minimap_rect.position+Vector2(7,7)
	var z: float=.0111
	var offset: Vector2=Vector2(2100,1200)
	var poly:=PackedVector2Array();for p in lake_poly:poly.append(origin+(p-offset)*z)
	hud.draw_colored_polygon(poly,Color("4b7c77"));poly.clear()
	for p in island_poly:poly.append(origin+(p-offset)*z)
	hud.draw_colored_polygon(poly,Color("82905d"))
	var gs: Array[Dictionary]=game.route_goals
	for i in range(gs.size()):
		var at: Vector2=origin+(gs[i].point-offset)*z
		if i>0:hud.draw_line(origin+(gs[i-1].point-offset)*z,at,Color(.8,.75,.43,.3),1)
		hud.draw_circle(at,2,Color("f1d679") if i==game.progress else Color("9baa90"))
	var at: Vector2=origin+(game.position-offset)*z;var dir:=Vector2.from_angle(game.heading)
	hud.draw_circle(at,3,Color("f7f0d2"));hud.draw_line(at,at+dir*7,Color("f7f0d2"),2)
	_text("N ↑",minimap_rect.position+Vector2(9,185),12,Color("cbd6ba"))
