extends "res://scripts/presentation/qizhen_large_world.gd"
## Presentation adapter. Fixed-step boat model, original stroke/input/camera stay live.
## Ground-plane projection is numerically the same as original 2D world coordinates.
const WORLD_UNIT: float=40.0
const WORLD_ORIGIN:=Vector2(6000,2850)
const TILT: float=30.0*PI/180.0
const COS_TILT: float=cos(TILT)
const DOCK_RECT:=Rect2(5984,2712,224,84)
var sample_route: bool=true
var lake_viewport: SubViewport
var lake_camera: Camera3D
var world_3d: Node3D
var boat_3d: Node3D
var viewport_layer: CanvasLayer
var viewport_rect: TextureRect
var water_material: ShaderMaterial
var mooring_line: Node2D
var environment_glb: Node3D
var alignment_data: Array[Dictionary]=[]
var actor_viewport: SubViewport
var actor_canvas: Node2D
var actor_sprite: Sprite3D
func sample_goals() -> Array[Dictionary]:
 return [
  {"point":Vector2(5480,3140),"radius":105.0,"type":"gate","title":"01  划离教学浮码头","hint":"W / 空格划桨 · A / D 转向 · 沿近岸水面绕回"},
  {"point":Vector2(5810,3655),"radius":62.0,"type":"collect","title":"02  靠近岸边防水袋","hint":"提前按 S 减速 · 靠近黄色防水袋后按住 E 取回"},
  {"point":Vector2(6000,2840),"radius":62.0,"type":"dock","title":"03  带回教学浮码头","hint":"船头朝北 · 缓慢贴近蓝色平台 · 按住 E 系泊"}
 ]
func _ready() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg=="--full-route":
   set_process(false);get_tree().call_deferred("change_scene_to_file","res://scenes/qizhen_large_world.tscn");return
 super._ready()
 if sample_route:game.route_goals=sample_goals()
 game.navigation_check=_platform_clear
 game.interaction_check=_contact_allowed
 game.feedback="近岸美术样段：取回防水袋后返航。全湖路线仍保留。"
 _create_3d()
 rig.hull.visible=false
 mooring_line=Node2D.new();add_child(mooring_line);mooring_line.draw.connect(_draw_contact_line)
 _sync(0,true)
func _platform_clear(point: Vector2,heading: float=0) -> bool:
 # Presentation sample adds a hull-shaped solid check; thrust, drag and steering stay unchanged.
 # Existing 31 px circular clearance alone is shorter than the 79 px rigid hull.
 var direction:=Vector2.from_angle(heading)
 for tip in [point+direction*39.0,point-direction*39.0]:
  if not Geo.water(tip,2.0):return false
 for along: float in [-29.0,0.0,29.0]:
  var sample: Vector2=point+direction*along
  if sample.distance_to(sample.clamp(DOCK_RECT.position,DOCK_RECT.end))<12.0:return false
 return true
func _contact_allowed(model: RefCounted,goal: Dictionary) -> bool:
 if goal.type!="dock":return true
 var bow: Vector2=model.position+Vector2.from_angle(model.heading)*39.0
 return bow.distance_to(bow.clamp(DOCK_RECT.position,DOCK_RECT.end))<=7.0
func _create_3d() -> void:
 lake_viewport=SubViewport.new();lake_viewport.name="LiveBlenderWorld";lake_viewport.own_world_3d=true;lake_viewport.transparent_bg=false;lake_viewport.msaa_3d=Viewport.MSAA_2X;lake_viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(lake_viewport)
 world_3d=Node3D.new();world_3d.name="WorldProjectionCompensation";world_3d.scale.x=1.0/COS_TILT;lake_viewport.add_child(world_3d)
 environment_glb=load("res://assets/blender/qizhen_north_bank.glb").instantiate();environment_glb.name="ActualBlenderGLBEnvironment";world_3d.add_child(environment_glb)
 boat_3d=load("res://assets/blender/qizhen_kayak.glb").instantiate();boat_3d.name="ActualBlenderGLBKayak";world_3d.add_child(boat_3d)
 var env_node:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("293d39");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("d3dfd4");env.ambient_light_energy=.48;env.tonemap_mode=Environment.TONE_MAPPER_LINEAR;env_node.environment=env;lake_viewport.add_child(env_node)
 var light:=DirectionalLight3D.new();light.name="SoftAfternoonKey";light.rotation_degrees=Vector3(-53,-28,-10);light.light_color=Color("fff3d4");light.light_energy=.50;light.shadow_enabled=true;light.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL;light.directional_shadow_max_distance=140;light.shadow_bias=.04;lake_viewport.add_child(light)
 lake_camera=Camera3D.new();lake_camera.projection=Camera3D.PROJECTION_ORTHOGONAL;lake_camera.keep_aspect=Camera3D.KEEP_HEIGHT;lake_camera.near=.1;lake_camera.far=200;lake_viewport.add_child(lake_camera);lake_camera.current=true
 _create_water_mesh()
 # The live 2D character/paddle is a depth-tested ground-oriented Sprite3D.
 # This preserves the approved size and stroke rig while banks/trees can occlude it.
 actor_viewport=SubViewport.new();actor_viewport.name="LivePixelRigTexture";actor_viewport.size=Vector2i(256,256);actor_viewport.transparent_bg=true;actor_viewport.disable_3d=true;actor_viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(actor_viewport)
 actor_canvas=Node2D.new();actor_viewport.add_child(actor_canvas)
 rig.get_parent().remove_child(rig);actor_canvas.add_child(rig)
 actor_sprite=Sprite3D.new();actor_sprite.name="DepthTestedPixelPaddler";actor_sprite.texture=actor_viewport.get_texture();actor_sprite.pixel_size=1.0/WORLD_UNIT;actor_sprite.rotation.x=-PI/2;actor_sprite.shaded=false;actor_sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD;actor_sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST;actor_sprite.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;world_3d.add_child(actor_sprite)
 viewport_layer=CanvasLayer.new();viewport_layer.name="BlenderBackgroundLayer";viewport_layer.layer=-1;add_child(viewport_layer)
 viewport_rect=TextureRect.new();viewport_rect.texture=lake_viewport.get_texture();viewport_rect.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;viewport_rect.mouse_filter=Control.MOUSE_FILTER_IGNORE;viewport_layer.add_child(viewport_rect)
 get_node("CachedTerrain").visible=false;water_fx.visible=false
func _create_water_mesh() -> void:
 var array: Array=[];array.resize(Mesh.ARRAY_MAX)
 var vertices:=PackedVector3Array();var uv:=PackedVector2Array()
 for p in Geo.lake():
  var local: Vector2=(p-WORLD_ORIGIN)/WORLD_UNIT
  vertices.append(Vector3(local.x,-.015,local.y));uv.append(local)
 var tri: PackedInt32Array=Geometry2D.triangulate_polygon(Geo.lake())
 array[Mesh.ARRAY_VERTEX]=vertices;array[Mesh.ARRAY_TEX_UV]=uv;array[Mesh.ARRAY_INDEX]=tri
 var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,array)
 var water:=MeshInstance3D.new();water.name="IndependentAnimatedLakeSurface";water.mesh=mesh;water.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 water_material=ShaderMaterial.new();water_material.shader=load("res://scripts/presentation/lake_water.gdshader");water_material.set_shader_parameter("shoreline_distance",load("res://assets/blender/shore_distance.png"));water.material_override=water_material;world_3d.add_child(water)
func _sync(dt: float,snap: bool=false) -> void:
 super._sync(dt,snap)
 if lake_camera==null:return
 viewport_layer.visible=not overview;get_node("CachedTerrain").visible=overview;water_fx.visible=overview
 rig.hull.visible=overview
 if overview and rig.get_parent()!=self:
  rig.get_parent().remove_child(rig);add_child(rig)
 elif not overview and rig.get_parent()!=actor_canvas:
  rig.get_parent().remove_child(rig);actor_canvas.add_child(rig)
 actor_canvas.position=Vector2(128,128)-game.position
 actor_sprite.visible=not overview
 lake_viewport.size=Vector2i(view_size);viewport_rect.size=view_size
 lake_camera.size=view_size.y/(cam.zoom.y*WORLD_UNIT)
 var center: Vector2=(cam.position-WORLD_ORIGIN)/WORLD_UNIT
 var ground:=Vector3(center.x/COS_TILT,0,center.y)
 lake_camera.position=ground+Vector3(-70*tan(TILT),70,0);lake_camera.look_at(ground,Vector3(0,0,-1))
 var local: Vector2=(game.position-WORLD_ORIGIN)/WORLD_UNIT
 boat_3d.position=Vector3(local.x,.0,local.y);boat_3d.rotation.y=-game.heading-PI/2
 actor_sprite.position=Vector3(local.x,.12,local.y)
 water_material.set_shader_parameter("water_clock",clock)
 water_material.set_shader_parameter("boat_position",local)
 water_material.set_shader_parameter("boat_direction",Vector2.from_angle(game.heading))
 water_material.set_shader_parameter("boat_speed",game.speed)
 if mooring_line!=null:mooring_line.queue_redraw()
func ground_to_screen_3d(point: Vector2) -> Vector2:
 var local: Vector2=(point-WORLD_ORIGIN)/WORLD_UNIT
 return lake_camera.unproject_position(Vector3(local.x/COS_TILT,0,local.y))
func _unhandled_key_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F and (title_open or overview):
  get_tree().change_scene_to_file("res://scenes/qizhen_large_world.tscn")
  return
 super._unhandled_key_input(event)
func _draw_contact_line() -> void:
 if overview or game.status!="won":return
 var bow: Vector2=game.position+Vector2.from_angle(game.heading)*34
 var bow_local: Vector2=(bow-WORLD_ORIGIN)/WORLD_UNIT
 var cleat_local: Vector2=(Vector2(5996,2787)-WORLD_ORIGIN)/WORLD_UNIT
 var inverse: Transform2D=get_viewport().get_canvas_transform().affine_inverse()
 var start: Vector2=inverse*lake_camera.unproject_position(Vector3(bow_local.x/COS_TILT,.08,bow_local.y))
 var end: Vector2=inverse*lake_camera.unproject_position(Vector3(cleat_local.x/COS_TILT,.42,cleat_local.y))
 mooring_line.draw_line(start,end,Color("d5c694"),1.5,true)
func _draw_markers() -> void:
 if not sample_route or overview:super._draw_markers();return
 for i in range(game.route_goals.size()):
  var goal: Dictionary=game.route_goals[i];var p: Vector2=goal.point
  if i<game.progress:continue
  if goal.type=="collect":
   markers.draw_circle(p+Vector2(2,6),12,Color(.02,.10,.10,.4))
   markers.draw_style_box(_style(Color("d5b55d")),Rect2(p-Vector2(10,13),Vector2(20,26)))
   markers.draw_line(p+Vector2(-7,-9),p+Vector2(7,-9),Color("f0d98b"),3)
   markers.draw_arc(p+Vector2(0,-14),5,PI,TAU,8,Color("634f34"),2)
  if i==game.progress:
   markers.draw_arc(p,float(goal.radius),0,TAU,48,Color(.87,.76,.43,.19),1.3)
func _draw_hud() -> void:
 if not sample_route:super._draw_hud();return
 var w: float=hud_size.x;var h: float=hud_size.y
 if overview:
  _panel(Rect2(14,14,w-138,68),Color(.05,.12,.12,.80));_text("全湖地形 · 近岸样段" if w<550 else "启真湖 · 全湖地形 / 当前近岸样段",Vector2(28,42),17 if w<550 else 20,Color("f0d58a"))
  _text("N ↑ · 点按返回 · F 原路线" if w<550 else "N ↑ 北 · M / 点按返回 · F 进入原全湖路线",Vector2(28,68),13 if w<550 else 15)
  _panel(map_button,Color(.05,.12,.12,.8));_text("返",map_button.position+Vector2(15,29),20)
  _panel(Rect2(14,h-146 if w<550 else h-90,w-28,132 if w<550 else 76),Color(.05,.12,.12,.82))
  _draw_lines("当前样段：教学浮码头 → 近岸取回防水袋 → 低速接触护舷并系泊",Vector2(28,h-119 if w<550 else h-62),w-56,15 if w<550 else 16)
  _draw_lines("保留原湖形；码头与岸边细节为艺术化改编，非测绘还原",Vector2(28,h-62 if w<550 else h-28),w-56,13 if w<550 else 14,Color("a8b9a8"))
  return
 var goal: Dictionary=game.route_goals[game.progress]
 var hint: String=goal.hint
 if touch_mode:
  if goal.type=="gate":hint="左侧拖方向 · 右侧按住划桨 · 松开收桨"
  elif goal.type=="collect":hint="靠近黄色防水袋 · 点按目标自动减速取回"
  else:hint="船头朝北 · 靠近护舷后点按平台系泊"
 var hint_width: float=maxf(160,minf(w-170,684))
 var top_height: float=64+maxi(0,_wrapped(hint,hint_width,15).size()-1)*22
 _panel(Rect2(14,14,minf(w-138,720),top_height),Color(.05,.12,.12,.78))
 _text(goal.title,Vector2(28,43),17 if w<550 else 21,Color("efda9c"));_draw_lines(hint,Vector2(28,69),hint_width,15)
 _panel(map_button,Color(.05,.12,.12,.78));_text("图",map_button.position+Vector2(15,29),20)
 _panel(pause_button,Color(.05,.12,.12,.78));_text("Ⅱ",pause_button.position+Vector2(12,28),20)
 _text("启真湖 · 北岸教学浮码头样段",Vector2(20,h-45),16,Color("e6e2c5"))
 _text("%02d:%02d   速度 %03d"%[int(game.elapsed)/60,int(game.elapsed)%60,game.speed],Vector2(20,h-20),15,Color("bdcbbb"))
 if w>1000:
  _panel(Rect2(w-374,h-40,360,30),Color(.05,.12,.12,.62))
  _text("自动输入回放 · 实际玩法 1×" if capture_mode else ("左侧转向 · 右侧划桨 · 点按目标" if touch_mode else "W 划桨   A/D 转向   S 刹停   E 取物/系泊"),Vector2(w-360,h-20),14,Color("bdcbbb"))
 elif capture_mode:_text("自动输入回放 1×",Vector2(20,h-67),13,Color("bdcbbb"))
 _edge_hint(goal.point,"目标",Color("edda9c"))
 if game.action_hold>0:
  _panel(Rect2(w*.5-150,h-126,300,50),Color(.05,.12,.12,.82));_text("正在取回" if goal.type=="collect" else "正在系泊",Vector2(w*.5-130,h-101),17)
  hud.draw_rect(Rect2(w*.5-130,h-90,260*game.action_hold/1.25,5),Color("d6be70"))
 elif goal.type!="gate" and game.position.distance_to(goal.point)<float(goal.radius)+80:
  _text("靠近后点按目标" if touch_mode else "靠近后按住 E / 点按目标",Vector2(w*.5-120,h-91),16,Color("eed799"))
 if touch_left!=-1:
  hud.draw_arc(touch_origin/hud_scale,44,0,TAU,40,Color(.8,.85,.7,.38),2);hud.draw_circle((touch_origin+touch_vector)/hud_scale,13,Color(.9,.85,.6,.52))
 if game.status=="won" and not title_open:
  _panel(Rect2(maxf(14,w*.5-180),h-132,minf(360,w-28),60),Color(.05,.12,.12,.88))
  _text("防水袋已带回 · 系泊完成",Vector2(maxf(28,w*.5-160),h-106),18,Color("efda9c"))
  _text("R 重试 · M 地图",Vector2(maxf(28,w*.5-160),h-83),15)
 if title_open or game.paused or game.status=="lost":
  _panel(Rect2(Vector2.ZERO,hud_size),Color(.025,.06,.07,.46))
  var modal_height: float=320 if w<550 else 290
  var b:=Rect2(maxf(20,(w-650)*.5),maxf(20,(h-modal_height)*.5),minf(650,w-40),modal_height);_panel(b,Color(.07,.14,.14,.94));var at: Vector2=b.position+Vector2(25,44)
  _text("启真湖 · Blender 近岸样段",at,21 if w<550 else 25,Color("efda9c"))
  if title_open:
   _draw_lines("沿近岸划行、减速取回防水袋，再回蓝色平台系泊",at+Vector2(0,48),b.size.x-50,18)
   _draw_lines("W / 空格划桨 · A / D 转向 · S 刹停 · E 操作",at+Vector2(0,107 if w<550 else 95),b.size.x-50,17)
   _draw_lines("触屏：左侧转向，右侧划桨；靠近后点按目标",at+Vector2(0,165 if w<550 else 133),b.size.x-50,17)
   _text("Enter 近岸样段 / F 原全湖路线",at+Vector2(0,239 if w<550 else 208),20,Color("ebce7e"))
  elif game.status=="won":
   _text("防水袋已带回 · 系泊完成",at+Vector2(0,65),23)
   _text("%.1f 秒 · %d 次划桨 · %d 次擦碰"%[game.elapsed,game.strokes,game.collisions],at+Vector2(0,112),18)
   _text("R 重试 · M 查看全湖地形",at+Vector2(0,202),20)
  elif game.paused:_text("已暂停 · P / 点按继续",at+Vector2(0,110),22)
