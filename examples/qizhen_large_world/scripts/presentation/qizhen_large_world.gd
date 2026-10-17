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
func _process(dt: float) -> void:
	var d: float=minf(dt,.05)
	if not game.paused:
		clock+=d;goal_flash=maxf(0,goal_flash-d)
	if not title_open and not overview:
		if not auto_control:
			game.input(keys.has(KEY_SPACE) or keys.has(KEY_W) or keys.has(KEY_UP),float(keys.has(KEY_D) or keys.has(KEY_RIGHT))-float(keys.has(KEY_A) or keys.has(KEY_LEFT)),keys.has(KEY_S) or keys.has(KEY_DOWN),keys.has(KEY_E))
		else:game.input(test_thrust,test_turn,test_brake,test_use)
		game.step(d)
	if game.progress!=last_progress:goal_flash=3.5;last_progress=game.progress
	while event_cursor<game.events.size():
		var event: Dictionary=game.events[event_cursor];event_cursor+=1
		if event.kind=="stroke":rig.request_stroke(event.side)
	_sync(d)
	if trace!=null and Engine.get_process_frames()%15==0:trace.store_line(JSON.stringify(game.result()));trace.flush()
func _sync(dt: float,snap: bool=false) -> void:
	if overview:
		cam.position=Vector2(5400,8050);cam.zoom=Vector2.ONE*.047
	else:
		var look: Vector2=Vector2.from_angle(game.heading)*120
		var target: Vector2=game.position+look
		cam.position=target if snap else cam.position.lerp(target,1-exp(-4*dt))
		var target_zoom: Vector2=Vector2.ONE*lerpf(.84,.64,clampf(game.speed/285,0,1))
		cam.zoom=target_zoom if snap else cam.zoom.lerp(target_zoom,1-exp(-2.0*dt))
	rig.sync_pose(game.position,game.heading,game.speed,game.steering*.12,1,dt,snap,game.position);rig.set_paused(game.paused);rig.advance(dt)
	if not game.paused:swim.update(dt,game.swan,game.swan_heading,"accelerate" if game.swan_phase=="charge" else "swim")
	water_fx.queue_redraw();markers.queue_redraw();swan_node.queue_redraw();hud.queue_redraw()
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or event.echo:return
	if event.pressed:
		if event.keycode in [KEY_ENTER,KEY_SPACE] and title_open:
			title_open=false
			if event.keycode==KEY_SPACE:keys[KEY_SPACE]=true
		elif event.keycode==KEY_M:overview=not overview
		elif event.keycode in [KEY_P,KEY_ESCAPE]:game.paused=not game.paused;keys.clear()
		elif event.keycode==KEY_R:game.reset();rig.reset();event_cursor=0;keys.clear();title_open=false;overview=false;last_progress=0;goal_flash=0
		else:keys[event.keycode]=true
	else:keys.erase(event.keycode)
func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and rig!=null and not auto_control:game.paused=true;keys.clear()
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
	var origin: Vector2=cam.position-Vector2(760,480)/cam.zoom
	var end: Vector2=cam.position+Vector2(760,480)/cam.zoom
	var spacing: int=90 if not overview else 180
	for x in range(int(origin.x/spacing)*spacing,int(end.x),spacing):
		for y in range(int(origin.y/spacing)*spacing,int(end.y),spacing):
			var p:=Vector2(x+sin(y*.03)*30,y+sin(x*.01)*20)
			if not Geo.water(p,35):continue
			var wave: float=sin(clock*.8+x*.03+y*.013)
			water_fx.draw_line(p+Vector2(wave*6,0),p+Vector2(12+wave*6,0),Color(.56,.71,.61,.10+.06*wave),1.3)
			if (x+y)%360==0:water_fx.draw_line(p+Vector2(-8,6),p+Vector2(9,6),Color(.54,.69,.63,.10),1)
func _draw_markers() -> void:
	var goals: Array[Dictionary]=Geo.goals()
	for i in range(goals.size()):
		var goal: Dictionary=goals[i];var p: Vector2=goal.point
		var current: bool=i==game.progress
		var done: bool=i<game.progress
		if overview:
			if i>0:markers.draw_line(goals[i-1].point,p,Color(.84,.73,.37,.5),13)
			markers.draw_circle(p,65,Color("edca68") if current else Color("b9bda4"))
			continue
		if p.distance_to(cam.position)>1100:continue
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
			markers.draw_string(font,p+Vector2(-32,-55),"目标 "+str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("f3dfa0"))
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
func _draw_hud() -> void:
	var viewport_size: Vector2=get_viewport_rect().size
	if capture_mode:_text("自动输入回放 · 1×",Vector2(1065,630),14,Color("d7d4b0"))
	if overview:
		_panel(Rect2(25,28,360,158),Color(.09,.16,.15,.87));_text("启真湖 · 南北大地图",Vector2(44,63),28)
		_text("航拍关系 + 校园图轮廓",Vector2(44,95),18,Color("b8c6b1"))
		_text("功能原型 / 全湖重构待继续精修",Vector2(44,125),16)
		_text("按 M 返回跟随镜头",Vector2(44,163),17,Color("e6c778"))
		_panel(Rect2(920,28,336,470),Color(.09,.16,.15,.87));_text("一次完整的湖上往返",Vector2(940,65),23)
		var labels=["1  离开北侧教学浮码头","2  检查中央水面信号","3  绕岛，取回南端防水袋","4  沿东侧窄水道返航","5  减速、对齐、靠泊"]
		for i in range(labels.size()):_text(labels[i],Vector2(940,114+i*57),18,Color("e4d397"))
		_text("导航点是路标，不增加主线剧情",Vector2(940,421),15,Color("a8b9a8"))
		_text("N  ↑ 北",Vector2(811,47),20,Color("e7d9a7"))
		_text("南北长形、不对称中央湖面",Vector2(434,669),18)
		_text("岛东水道已为游戏加宽；实地通航未核实",Vector2(434,696),15,Color("d9bd7e"))
		return
	var goal: Dictionary=Geo.goals()[game.progress]
	var phase: int=[0,1,2,2,3,3,3,3,4][game.progress]
	var labels=["离开教学浮码头","检查湖面信号","绕岛取回防水袋","沿东侧水道返航","低速对齐靠泊"]
	_panel(Rect2(20,18,720,65),Color(.05,.12,.12,.70))
	_text("%d / 5   %s"%[phase+1,labels[phase]],Vector2(38,45),22,Color("f0d58a"))
	_text(goal.hint,Vector2(38,70),16)
	_panel(Rect2(1110,18,150,58),Color(.05,.12,.12,.66));_text("%02d:%02d"%[int(game.elapsed)/60,int(game.elapsed)%60],Vector2(1130,52),26)
	_draw_minimap()
	_panel(Rect2(20,654,1065,47),Color(.05,.12,.12,.64))
	_text("W / 空格 划桨    A / D 转向    S 刹停    E 操作    M 全图    P 暂停    R 重试",Vector2(37,684),17)
	_text("速度 %03d"%game.speed,Vector2(1120,685),17,Color("dedcba"))
	var distance: float=game.position.distance_to(goal.point)
	if distance>310:
		var angle: float=(goal.point-game.position).angle()
		var center:=Vector2(640,360);var edge:=center+Vector2.from_angle(angle)*Vector2(380,210)
		var dir:=Vector2.from_angle(angle);var across:=dir.orthogonal()
		hud.draw_colored_polygon(PackedVector2Array([edge+dir*16,edge-dir*9+across*9,edge-dir*9-across*9]),Color("ebce80"))
		_text("目标",edge+Vector2(18,4),16,Color("edda9c"))
	if game.action_hold>0:
		_panel(Rect2(490,480,300,57),Color(.05,.12,.12,.72));_text("正在操作，请保持低速",Vector2(511,506),18)
		hud.draw_rect(Rect2(510,520,260,7),Color("384d49"));hud.draw_rect(Rect2(510,520,260*game.action_hold/1.25,7),Color("d6be70"))
	if game.feedback_age<4.5 and not title_open:
		_text(game.feedback,Vector2(245,620),17,Color("ece2bd"))
	if game.paused or title_open or game.status!="running":
		_panel(Rect2(0,0,viewport_size.x,viewport_size.y),Color(.025,.06,.07,.58))
		_panel(Rect2(310,188,660,350),Color(.07,.14,.14,.94));_text("启真湖 · 从北岸到南岛",Vector2(350,238),30,Color("f1d89b"))
		if title_open:
			_text("从教学浮码头出发，寻找信号、绕岛取物并安全返航",Vector2(350,285),18)
			_text("按住 W / 空格划桨，A / D 转向；S 刹停，E 操作",Vector2(350,322),18)
			_text("小艇在真实扩大的空间移动，镜头随行；按 M 看全湖",Vector2(350,359),18)
			_text("航拍关系与校园图为地形基础；任务与通行属于游戏改编",Vector2(350,412),16,Color("aec0af"))
			_text("按 Enter 或空格出发",Vector2(350,488),24,Color("e9ce7b"))
		elif game.paused:_text("已暂停 · 按 P 继续",Vector2(350,340),26)
		elif game.status=="won":
			_text("已带回防水袋，完成靠泊",Vector2(350,301),25)
			_text("用时 %.1f 秒 · 实际划行 %.0f 像素 · %d 次划桨"%[game.elapsed,game.travel,game.strokes],Vector2(350,349),18)
			_text("M 检查整张地图 · R 重新开始",Vector2(350,464),21)
		else:_text("失去平衡 · 按 R 重新开始",Vector2(350,340),25)
func _draw_minimap() -> void:
	_panel(minimap_rect,Color(.05,.12,.12,.62))
	var origin: Vector2=minimap_rect.position+Vector2(10,10)
	var z: float=.018
	var offset: Vector2=Vector2(2100,1200)
	var poly:=PackedVector2Array();for p in lake_poly:poly.append(origin+(p-offset)*z)
	hud.draw_colored_polygon(poly,Color("4b7c77"));poly.clear()
	for p in island_poly:poly.append(origin+(p-offset)*z)
	hud.draw_colored_polygon(poly,Color("82905d"))
	var gs: Array[Dictionary]=Geo.goals()
	for i in range(gs.size()):
		var at: Vector2=origin+(gs[i].point-offset)*z
		if i>0:hud.draw_line(origin+(gs[i-1].point-offset)*z,at,Color(.8,.75,.43,.3),1)
		hud.draw_circle(at,3,Color("f1d679") if i==game.progress else Color("9baa90"))
	var at: Vector2=origin+(game.position-offset)*z;var dir:=Vector2.from_angle(game.heading)
	hud.draw_circle(at,4,Color("f7f0d2"));hud.draw_line(at,at+dir*10,Color("f7f0d2"),2)
	_text("N ↑   M 全图",minimap_rect.position+Vector2(14,287),14,Color("cbd6ba"))
