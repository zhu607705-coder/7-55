extends Node
## Presentation only. One fixed orthographic camera renders physical miniatures.
## Input and results remain in the existing bench view and puzzle models.
const Q:=0.7071067811865476
const U:=0.01
const IVORY:=Color("e2e2d5")
const METAL:=Color("a5b4b1")
const TEAL:=Color("36777b")
const DARK:=Color("263f47")
const RUBBER:=Color("202d32")
const ORANGE:=Color("db8248")
const BLUE:=Color("244967")
const Props=preload("res://campuses/future_learning_center/scripts/motion_prop_metrics.gd")
const Pantry=preload("res://campuses/future_learning_center/scripts/pantry_miniature.gd")
var viewport:SubViewport
var scene:Node3D
var camera:Camera3D
var lamp:DirectionalLight3D
var pool:Dictionary={}
var meshes:Dictionary={}
var materials:Dictionary={}
var touched:Dictionary={}
var rendered_mode:=""
var light_wash:ShaderMaterial

func _ready()->void:
 viewport=SubViewport.new();viewport.size=Vector2i(1440,810)
 viewport.own_world_3d=true;viewport.transparent_bg=false
 viewport.msaa_3d=Viewport.MSAA_2X
 viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
 add_child(viewport);scene=Node3D.new();viewport.add_child(scene)
 camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.size=5.4;camera.position=Vector3(0,12,12);camera.near=.1;camera.far=60
 scene.add_child(camera);camera.look_at(Vector3.ZERO);camera.current=true
 var env:=WorldEnvironment.new();var resource:=Environment.new()
 resource.background_mode=Environment.BG_COLOR;resource.background_color=Color("c7ccc8")
 resource.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 resource.ambient_light_color=Color("e3e9e5");resource.ambient_light_energy=.48
 resource.tonemap_mode=Environment.TONE_MAPPER_LINEAR;env.environment=resource;scene.add_child(env)
 var key:=DirectionalLight3D.new();key.rotation_degrees=Vector3(-48,-28,0)
 key.light_color=Color("fff1db");key.light_energy=.8;key.shadow_enabled=true
 key.directional_shadow_max_distance=35;key.shadow_bias=.12;key.shadow_normal_bias=1.3
 scene.add_child(key)
 lamp=DirectionalLight3D.new();lamp.light_color=Color("fff1bd");lamp.light_energy=.45
 scene.add_child(lamp)
 var shader:=Shader.new()
 shader.code="""shader_type spatial;
render_mode unshaded, cull_disabled;
uniform float sunlight = 1.0;
uniform float side = 0.0;
varying vec3 ground;
void vertex() { ground = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
 vec2 at = vec2((ground.x + 1.5) / 2.8, (ground.z + .04) / 1.48);
 at.x += at.y * side * .16;
 float pool = 1.0 - smoothstep(.68, 1.0, max(abs(at.x), abs(at.y)));
 ALBEDO = vec3(1.0, .77, .37);
 ALPHA = pool * sunlight * .42;
}"""
 light_wash=ShaderMaterial.new();light_wash.shader=shader

func texture()->Texture2D:return viewport.get_texture()
func set_active(active:bool)->void:
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
func p(at:Vector2,height:=0.0)->Vector3:
 return Vector3((at.x-480)*U,height*U,(at.y-270)*U/Q)
func visible_p(at:Vector2,height:=0.0)->Vector3:
 return p(at+Vector2(0,height*Q),height)
func screen(point:Vector3)->Vector2:
 return Vector2(480+point.x/U,270+(point.z-point.y)*Q/U)
func material(color:Color,metal:=0.0,emission:=false)->StandardMaterial3D:
 var key:=str([color,metal,emission])
 if not materials.has(key):
  var m:=StandardMaterial3D.new();m.albedo_color=color;m.metallic=metal;m.roughness=.52
  if emission:m.emission_enabled=true;m.emission=color;m.emission_energy_multiplier=.4
  materials[key]=m
 return materials[key]
func mesh(id:String,shape:Mesh,at:Vector3,color:Color,basis:=Basis.IDENTITY,metal:=0.0,glow:=false)->MeshInstance3D:
 if not pool.has(id):
  var node:=MeshInstance3D.new();node.name=id;scene.add_child(node);pool[id]=node
 var node:MeshInstance3D=pool[id]
 node.mesh=shape;node.position=at;node.basis=basis;node.material_override=material(color,metal,glow)
 node.visible=true;touched[id]=true;return node
func tri(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3)->void:
 st.add_vertex(a*U);st.add_vertex(c*U);st.add_vertex(b*U)
func bevel(extent:Vector3)->Mesh:
 var key:="box"+str(extent)
 if meshes.has(key):return meshes[key]
 var half:=extent/2;var cut:=minf(3.0,minf(extent.x,extent.z)*.09)
 var rise:=minf(2,extent.y*.24)
 var footprint:Array[Vector2]=[Vector2(-half.x+cut,-half.z),Vector2(half.x-cut,-half.z),Vector2(half.x,-half.z+cut),Vector2(half.x,half.z-cut),Vector2(half.x-cut,half.z),Vector2(-half.x+cut,half.z),Vector2(-half.x,half.z-cut),Vector2(-half.x,-half.z+cut)]
 var rings:Array=[]
 for n:int in 4:
  var ring:Array[Vector3]=[];var y:float=[-half.y,-half.y+rise,half.y-rise,half.y][n]
  for point:Vector2 in footprint:
   var inset:float=rise if n in [0,3] else 0
   ring.append(Vector3(point.x-signf(point.x)*inset,y,point.y-signf(point.y)*inset))
  rings.append(ring)
 var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_smooth_group(-1)
 for n:int in 3:
  for i:int in 8:
   var j:=(i+1)%8
   tri(st,rings[n][i],rings[n+1][j],rings[n][j]);tri(st,rings[n][i],rings[n+1][i],rings[n+1][j])
 for i:int in 8:
  var j:=(i+1)%8
  tri(st,Vector3(0,half.y,0),rings[3][j],rings[3][i])
  tri(st,Vector3(0,-half.y,0),rings[0][i],rings[0][j])
 st.generate_normals();meshes[key]=st.commit();return meshes[key]
func box(id:String,at:Vector3,size_value:Vector3,color:Color,basis:=Basis.IDENTITY,metal:=0.0)->void:
 mesh(id,bevel(size_value),at,color,basis,metal)
func cylinder(id:String,at:Vector3,radius:float,height:float,color:Color,basis:=Basis.IDENTITY,metal:=0.0)->void:
 if not meshes.has("cylinder"):
  var shape:=CylinderMesh.new();shape.top_radius=1;shape.bottom_radius=1;shape.height=1;shape.radial_segments=32;meshes.cylinder=shape
 mesh(id,meshes.cylinder,at,color,basis.scaled_local(Vector3(radius*U,height*U,radius*U)),metal)
func tube(id:String,from:Vector3,to:Vector3,radius:float,color:Color,metal:=0.0)->void:
 var delta:=to-from
 if delta.length()<.00001:return
 var basis:=Basis(Quaternion(Vector3.UP,delta.normalized()))
 cylinder(id,(from+to)/2,radius,delta.length()/U,color,basis,metal)
func line(id:String,from:Vector2,to:Vector2,radius:float,color:Color,height:=3.0)->void:
 tube(id,visible_p(from,height),visible_p(to,height),radius,color)
func ring(id:String,at:Vector2,radius:float,color:Color,height:=6.0,rotation:=0.0)->void:
 for i:int in 32:
  var a:=TAU*i/32+rotation;var b:=TAU*(i+1)/32+rotation
  tube(id+str(i),visible_p(at,height)+Vector3(cos(a)*radius,0,sin(a)*radius)*U,visible_p(at,height)+Vector3(cos(b)*radius,0,sin(b)*radius)*U,2.3,color)
func pad(id:String,at:Vector2,size_value:Vector2,color:=DARK,height:=3.0)->void:
 box(id,visible_p(at,height),Vector3(size_value.x,6,size_value.y/Q),color)
func knob(id:String,at:Vector2,angle:float,radius:=25.0)->void:
 cylinder(id+"base",visible_p(at,4),radius,8,METAL)
 cylinder(id+"rim",visible_p(at,9),radius-4,5,DARK)
 var center:=visible_p(at,13);var end:=center+Vector3(cos(angle),0,sin(angle))*radius*.7*U
 tube(id+"bar",center,end,3,IVORY);cylinder(id+"grip",end,7,13,ORANGE)
func common(v:Control)->void:
 # Top surface is exactly the common apparatus plane; the bevel defines thickness.
 box("table",p(Vector2(480,269),-12),Vector3(938,24,541),Color("abb5ab") if v.bench_mode=="solar" else IVORY)
 for x:float in [31,929]:
  for y:float in [92,439]:cylinder("screw"+str([x,y]),visible_p(Vector2(x,y),.8),2.8,1.6,METAL, Basis.IDENTITY,.7)
 var base:Vector2=v.LEVER_BASE
 box("lever_base",p(base+Vector2(0,15),8),Vector3(76,16,75),TEAL)
 pad("lever_slot",base+Vector2(0,-22),Vector2(14,60),RUBBER,18)
 var root:=p(base,16);var grip:=visible_p(v.lever_grip(),52)
 tube("lever_shaft",root,grip,4,METAL,.7)
 tube("lever_grip",grip-Vector3(.28,0,0),grip+Vector3(.28,0,0),9,ORANGE)
 ring("undo",v.CRANK,24,METAL,9)
 var end:Vector2=v.CRANK+Vector2(-16,-16)
 if v.gesture=="crank" and v.pointer.distance_to(v.CRANK)>8:end=v.CRANK+(v.pointer-v.CRANK).normalized()*23
 line("undo_spoke",v.CRANK,end,3.2,TEAL,11);cylinder("undo_grip",visible_p(end,18),7,19,ORANGE)
 if not v.book_open:
  pad("bookcover",Vector2(884,105),Vector2(94,49),TEAL)
  box("pages_left",visible_p(Vector2(861,102),9),Vector3(43,8,61),Color("f6edd7"))
  box("pages_right",visible_p(Vector2(907,102),9),Vector3(43,8,61),Color("f6edd7"))
  for i:int in 4:line("bookline"+str(i),Vector2(846,92+i*6),Vector2(872,92+i*6),.45,METAL,14)
func present(v:Control,mode:String)->void:
 touched.clear();rendered_mode=mode
 if mode!="pantry":common(v)
 lamp.light_energy=0
 if mode=="pantry":Pantry.draw(self,v)
 elif mode=="solar":solar(v)
 elif mode=="robotics":robotics(v)
 elif mode=="signal":signal_scene(v)
 else:mechanical(v)
 for id:String in pool:pool[id].visible=touched.has(id)

func gear(id:String,at:Vector2,radius:float,phase:float,color:Color,height:=8.0)->void:
 var key:="gear"+str(radius)
 if not meshes.has(key):
  var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_smooth_group(-1)
  for i:int in 80:
   var j:=(i+1)%80;var a:=TAU*i/80;var b:=TAU*j/80
   var ra:float=radius*(1.0 if i%4 in [0,1] else .84);var rb:float=radius*(1.0 if j%4 in [0,1] else .84)
   var p0:=Vector3(cos(a)*ra,4,sin(a)*ra);var p1:=Vector3(cos(b)*rb,4,sin(b)*rb)
   tri(st,Vector3(0,4,0),p1,p0);tri(st,p0,p1,p1-Vector3(0,8,0));tri(st,p0,p1-Vector3(0,8,0),p0-Vector3(0,8,0))
  st.generate_normals();meshes[key]=st.commit()
 var center:=visible_p(at,height);var rotation:=Basis(Vector3.UP,-phase)
 mesh(id,meshes[key],center,color,rotation,.4)
 cylinder(id+"hub",center+Vector3(0,.04,0),radius*.31,5,METAL,Basis.IDENTITY,.6)
 cylinder(id+"hole",center+Vector3(0,.071,0),4,1,RUBBER)
 var end:=center+Vector3(cos(phase)*radius*.68,6,sin(phase)*radius*.68)*U
 tube(id+"spoke",center+Vector3(0,.06,0),end,1.7,IVORY)
func panel(id:String,at:Vector2,width:float,depth:float,angle:float,height:float,foot_height:=8.0,exposure:=1.0)->void:
 var pivot:=p(at,height);var rotate:=Basis(Vector3.RIGHT,angle)
 var center:=pivot+Vector3(0,0,depth/2)*U+rotate*Vector3(0,0,-depth/2)*U
 box(id+"frame",center,Vector3(width,3,depth),METAL*exposure,rotate,.65)
 box(id+"silicon",center+rotate*Vector3(0,.02,0),Vector3(width-5,1,depth-4),BLUE*exposure,rotate,.18)
 for i:int in 5:
  var x:float=-width/2+width*(i+1)/6
  tube(id+"cell"+str(i),center+rotate*Vector3(x,3,-depth/2+3)*U,center+rotate*Vector3(x,3,depth/2-3)*U,.45,Color("8ebcce"))
 tube(id+"bus",center+rotate*Vector3(-width/2+3,3,0)*U,center+rotate*Vector3(width/2-3,3,0)*U,.5,Color("8ebcce"))
 for side:float in [-1,1]:
  var end:=pivot+Vector3(side*(width/2-5),0,depth/2)*U+rotate*Vector3(0,0,-depth)*U
  var foot:=Vector3(end.x,foot_height*U,end.z)
  tube(id+"brace"+str(side),foot,end,2.0,TEAL,.6)
func solar_car(id:String,at:Vector2,parts:Dictionary,angle:float,phase:float,color:Color,exposure:float)->void:
 var center:=p(at,11)
 box(id+"chassis",center+Vector3(0,.19,0),Vector3(104,12,47),color*exposure)
 box(id+"nose",center+Vector3(.43,.23,0),Vector3(23,9,40),METAL*exposure,Basis.IDENTITY,.5)
 for x:float in [-34,34]:
  tube(id+"axle"+str(x),center+Vector3(x,12,-32)*U,center+Vector3(x,12,32)*U,2.5,METAL,.6)
  for z:float in [-27,27]:
   var key:=id+str([x,z]);var wheel:=center+Vector3(x,12,z)*U
   cylinder(key,wheel,13,10,RUBBER,Basis(Vector3.RIGHT,PI/2))
   cylinder(key+"hub",wheel+Vector3(0,0,signf(z)*.056),6,1,METAL,Basis(Vector3.RIGHT,PI/2),.6)
   tube(key+"spin",wheel+Vector3(cos(phase)*5,sin(phase)*5,signf(z)*6)*U,wheel+Vector3(-cos(phase)*5,-sin(phase)*5,signf(z)*6)*U,1.2,TEAL)
 panel(id+"panel",at,76 if parts.panel==1 else 56,26,deg_to_rad(angle),51,36,exposure)
func sun_pool(id:String,at:Vector2,size_value:Vector2,height:float)->void:
 var key:="lightplane"+str(size_value)
 if not meshes.has(key):
  var plane:=PlaneMesh.new();plane.size=Vector2(size_value.x,size_value.y/Q)*U;meshes[key]=plane
 var surface:=mesh(id,meshes[key],p(at,height),Color.WHITE)
 surface.material_override=light_wash;surface.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func solar(v:Control)->void:
 var sky:int=v.drag_value if v.gesture=="light" else v.solar.sky
 var intensity:float=(0 if sky==2 else 1) if v.gesture=="light" else v.solar.intensity_at(v.solar.elapsed())
 lamp.rotation_degrees=Vector3(-30 if sky==0 else -60,-65,0);lamp.light_energy=.32*intensity
 light_wash.set_shader_parameter("sunlight",intensity);light_wash.set_shader_parameter("side",float(sky==1))
 sun_pool("shared_light",Vector2(330,270),Vector2(572,240),.25)
 for lane:int in 2:
  var y:=226.0+lane*111
  pad("trackbase"+str(lane),Vector2(328,y-11),Vector2(564,83),TEAL)
  pad("track"+str(lane),Vector2(328,y-13),Vector2(541,65),Color("233a41").lerp(Color("64776d"),intensity),7)
  sun_pool("belt_light"+str(lane),Vector2(328,y-13+7*Q),Vector2(541,65),10.25)
  for n:int in 12:
   var distance:float=v.solar.cars[lane].distance
   var x:=63+fposmod(n*45-distance*6.4,532)
   line("beltmark"+str([lane,n]),Vector2(x,y-38),Vector2(x,y+10),1.2,METAL,12)
  for sign_value:int in [-1,1]:line("rail"+str([lane,sign_value]),Vector2(53,y-13+sign_value*40),Vector2(606,y-13+sign_value*40),2.2,METAL,9)
  var setup:Dictionary=v.solar.setup if lane==0 else v.Solar.BASELINE
  solar_car("car"+str(lane),v._car_at(lane),setup,v.panel_angle if lane==0 else 0,v.solar.cars[lane].distance*2,TEAL if lane==0 else METAL,.42+.58*intensity)
 # A gantry-shaped sun simulator replaces the unrelated desk lamp. The orange
 # carriage is the shared light-condition control; its shutter is a real plate.
 for x:float in [75,587]:
  var ground:=p(Vector2(x,172),0);tube("sunpost"+str(x),ground,ground+Vector3(0,.67,0),3,METAL,.6)
 line("sunbeam",Vector2(75,125),Vector2(822,125),4,METAL,67)
 box("lightbar",visible_p(Vector2(331,133),67),Vector3(518,10,19),TEAL)
 box("lightstrip",visible_p(Vector2(331,139),62),Vector3(506,5,11),Color("f3ce79").lerp(DARK,1-intensity))
 if sky==2:box("barshutter",visible_p(Vector2(331,139),64),Vector3(514,6,19),DARK)
 var grip:Vector2=v.lamp_grip()+v.lamp_drag_offset()
 box("sunhousing",visible_p(grip,82),Vector3(63,12,37),TEAL)
 box("sundiffuser",visible_p(grip+Vector2(0,6),75),Vector3(49,3,25),Color("f1c774") if intensity>.3 else DARK)
 cylinder("sunhandle",visible_p(grip,91),8,12,ORANGE)
 if sky==2:box("sunshutter",visible_p(grip+Vector2(0,13),68),Vector3(69,3,47),DARK)
 # Distance is read only here; belt seams communicate movement, not a second ruler.
 pad("meter",Vector2(722,246),Vector2(182,164),DARK)
 pad("parts",Vector2(373,391),Vector2(550,78),TEAL)
 for i:int in 2:
  var at:Vector2=v.part_at("panel%d"%i,Vector2(181+i*113,398))
  pad("panelwell"+str(i),Vector2(181+i*113,393),Vector2(108,52),DARK,7)
  if v.gesture=="panel" and v.drag_value==i:continue
  panel("spare"+str(i),at,72 if i==0 else 106,40,0,13,10)
 for i:int in 3:
  var at:Vector2=v.part_at("gear%d"%i,Vector2(418+i*88,391))
  cylinder("gearwell"+str(i),visible_p(Vector2(418+i*88,391),7),36,2,DARK)
  if v.gesture=="gear" and v.drag_value==i:continue
  gear("sparegear"+str(i),at,18+i*8,0,ORANGE if v.solar.setup.gear==i else METAL)
 if v.gesture=="panel":panel("heldpanel",v.pointer-Vector2(0,18),72 if v.drag_value==0 else 106,40,0,12)
 if v.gesture=="gear":gear("heldgear",v.pointer-Vector2(0,22),18+v.drag_value*8,0,ORANGE,20)

func module(id:String,at:Vector2,kind:String,rotation:float,focus:bool,station:=false,width:=102.0)->void:
 var center:=visible_p(at,5);var basis:=Basis(Vector3.UP,-rotation)
 box(id,center,Vector3(width,10,width),IVORY,basis)
 var ports:Array=[0,1,2,3] if station else [0,1 if kind=="corner" else 2]
 for port:int in ports:
  var direction:Vector3=[Vector3.RIGHT,Vector3.BACK,Vector3.LEFT,Vector3.FORWARD][port]
  tube(id+"track"+str(port),center+Vector3(0,.055,0),center+Vector3(0,.055,0)+basis*direction*width/2*U,6,DARK)
  tube(id+"line"+str(port),center+Vector3(0,.12,0),center+Vector3(0,.12,0)+basis*direction*width/2*U,.7,METAL)
 if kind=="oneway" and not station:
  var target:=center+Vector3(0,.13,0);var end:=target+basis*Vector3(.14,0,0)
  tube(id+"arrow",target-basis*Vector3(.14,0,0),end,2,ORANGE)
  for z:float in [-8,8]:tube(id+"head"+str(z),end,end+basis*Vector3(-9,0,z)*U,2,ORANGE)
 if focus:
  var arm:=basis*Vector3(.31,.1,.31)
  tube(id+"arm",center+Vector3(0,.1,0),center+arm,2,METAL)
  cylinder(id+"handle",center+arm,7,8,ORANGE)
func robot_car(id:String,at:Vector2,direction:int,phase:float)->void:
 var base:=p(at,11);var basis:=Basis(Vector3.UP,-direction*PI/2)
 box(id+"body",base+Vector3(0,.16,0),Vector3(72,24,48),TEAL,basis)
 box(id+"tray",base+Vector3(0,.3,0),Vector3(53,6,42),IVORY,basis)
 for x:float in [-23,23]:
  for z:float in [-27,27]:
   var center:=base+basis*Vector3(x,10,z)*U;var wheel_basis:=basis*Basis(Vector3.RIGHT,PI/2)
   cylinder(id+str([x,z]),center,10,8,RUBBER,wheel_basis)
   cylinder(id+"hub"+str([x,z]),center+basis*Vector3(0,0,signf(z)*.045),4,2,METAL,wheel_basis)
 box(id+"sensor",base+basis*Vector3(.38,.22,0),Vector3(4,8,20),RUBBER,basis)
 for z:float in [-7,7]:cylinder(id+"eye"+str(z),base+basis*Vector3(Props.ROBOT_FRONT-.5,22,z)*U,2.5,1,ORANGE,basis*Basis(Vector3.FORWARD,PI/2))
func crate(id:String,at:Vector2)->void:
 box(id,visible_p(at-Vector2(0,8),20),Vector3(27,24,22),ORANGE)
 box(id+"strap",visible_p(at-Vector2(0,17),33),Vector3(5,1,23),IVORY)
func robotics(v:Control)->void:
 pad("gridbase",Vector2(330,226),Vector2(584,266),TEAL)
 for y:int in 3:
  for x:int in 5:
   var point:=Vector2i(x,y);var tile:Dictionary=v.robot.tiles[point]
   var held:bool=v.gesture=="rotate" and point==v.source_tile
   var angle:float=v.rotation_angle if held else int(tile.rotation)*PI/2
   module("tile"+str(point),v._tile_at(point)-Vector2(0,7 if held and not v.reduced_motion else 0),tile.kind,angle,point==v.selected,point in [v.Robot.BASE,v.Robot.DESTINATION])
 var at:Vector2=v._tile_at(v.robot.position)
 robot_car("robot",at,v.robot.direction,v.robot.moved*12)
 var carry:=at+Vector2(0,-31);var base:Vector2=v._tile_at(v.Robot.BASE)+Vector2(60,-8);var dest:Vector2=v._tile_at(v.Robot.DESTINATION)+Vector2(60,-8)
 if v.robot.phase=="loading":crate("cargo",base.lerp(carry,v.robot.progress)-Vector2(0,sin(v.robot.progress*PI)*18))
 elif v.robot.phase=="unloading":crate("cargo",carry.lerp(dest,v.robot.progress)-Vector2(0,sin(v.robot.progress*PI)*18))
 else:crate("cargo",base if v.robot.cargo=="base" else (carry if v.robot.cargo=="robot" else dest))
 var direction:int=v.preview_outlet if v.gesture=="guide" else v.robot.outlet
 knob("guide",v.GUIDE,direction*PI/2,27)
 pad("moduletray",Vector2(342,398),Vector2(561,66),TEAL)
 for i:int in 3:
  if v.gesture=="module" and v.drag_value==i:continue
  module("sparemodule"+str(i),v.part_at("module%d"%i,Vector2(138+i*178,398)),["straight","corner","oneway"][i],0,false,false,84)
 if v.gesture in ["module","tile"] and v.pointer.distance_to(v.press_at)>10:
  var tile:Dictionary={"kind":["straight","corner","oneway"][v.drag_value],"rotation":0} if v.gesture=="module" else v.robot.tiles[v.source_tile]
  module("heldmodule",v.pointer-Vector2(0,20),tile.kind,tile.rotation*PI/2,true,false,95)

func mechanical(v:Control)->void:
 box("motorbody",p(v.MOTOR+Vector2(-38,0),11),Vector3(70,22,64),TEAL)
 for i:int in 5:line("cooling"+str(i),v.MOTOR+Vector2(-55+i*6,-18),v.MOTOR+Vector2(-55+i*6,17),1.5,METAL,28)
 gear("motor",v.MOTOR,44,v.model.motor_phase,ORANGE,26)
 cylinder("axlebase",visible_p(v.AXLE,4),23,8,TEAL)
 cylinder("axle",visible_p(v.AXLE,9),5,18,METAL,Basis.IDENTITY,.6)
 if v.model.gear>=0:gear("drive",v.AXLE-Vector2(0,v.lift_at(v.AXLE)),v.Model.RADII[v.model.gear],v.model.gear_phase,METAL,26)
 gear("output",v.OUTPUT,36,v.model.output_phase,TEAL,26)
 if v.model.belt>0:
  for row:int in 2:
   var sign_value:float=-1 if row==0 else 1
   var a:Vector2=v.AXLE+Vector2(8,sign_value*15);var b:Vector2=v.OUTPUT+Vector2(0,sign_value*15*(-1 if v.model.belt==2 else 1))
   var mid:Vector2=(a+b)/2+Vector2(0,12 if v.model.tension==0 else 0)
   line("belt_a"+str(row),a,mid,3.3,RUBBER,28);line("belt_b"+str(row),mid,b,3.3,RUBBER,28)
   for n:int in 6:
    var t:float=fposmod(n/6.0+v.model.gear_phase*.11,1)
    var pos:Vector2=a.lerp(mid,t*2) if t<.5 else mid.lerp(b,(t-.5)*2)
    line("seam"+str([row,n]),pos-Vector2(0,2),pos+Vector2(0,2),.7,METAL,32)
 pad("feed",Vector2(710,268),Vector2(216,30),DARK)
 line("railfeed",Vector2(612,268),Vector2(816,268),2,METAL,8)
 line("target",Vector2(796,248),Vector2(796,289),1.6,IVORY,10)
 crate("workpiece",Vector2(624+v.model.travel*190,270))
 pad("geartray",Vector2(247,388),Vector2(318,88),TEAL)
 for i:int in 3:
  cylinder("well"+str(i),visible_p(Vector2(142+96*i,387),7),40,2,DARK)
  if v.gesture=="gear" and v.drag==i:continue
  gear("spare"+str(i),v.part_at("gear%d"%i,Vector2(142+96*i,387)),v.Model.RADII[i]*.6,0,METAL)
 for i:int in 2:
  if v.gesture=="belt" and v.drag==i+1:continue
  var at:Vector2=v.part_at("belt%d"%(i+1),Vector2(705+i*55,331))
  for n:int in 32:
   var a:=TAU*n/32;var b:=TAU*(n+1)/32
   var from:=visible_p(at,5)+Vector3(cos(a)*21,0,sin(a)*27*(1 if i==0 else cos(a)))*U
   var to:=visible_p(at,5)+Vector3(cos(b)*21,0,sin(b)*27*(1 if i==0 else cos(b)))*U
   tube("loosebelt"+str([i,n]),from,to,3,RUBBER)
 var level:int=v.preview_tension if v.gesture=="tension" else v.model.tension
 knob("tension",v.TENSION,[-2.4,-1.57,-.7][level],28)
 if v.gesture=="gear":gear("heldgear",v.pointer-Vector2(0,20),v.Model.RADII[v.drag],0,ORANGE,24)
 if v.gesture=="belt":ring("heldbelt",v.pointer-Vector2(0,20),26,RUBBER,25)

func monitor(id:String,at:Vector2,value:int)->void:
 var base:=at+Vector2(92,96)
 box(id+"foot",visible_p(base,4),Vector3(66,8,23),TEAL)
 tube(id+"stem",visible_p(base-Vector2(0,3),9),visible_p(base-Vector2(0,44),67),4.5,METAL,.65)
 # Upright glass rectangle: surface and pattern tiles all share the same plane.
 var center:=visible_p(at+Vector2(92,42),95)
 box(id+"frame",center,Vector3(184,104,9),TEAL)
 box(id+"glass",center+Vector3(0,0,.055),Vector3(171,91,1),DARK)
 if value>=0:
  var marks:Array=[[0,1,4,7],[0,3,4,5],[1,2,4,7]][value]
  for n:int in 9:
   var local:=Vector3(-53+(n%3)*23,27-floorf(n/3.0)*23,6)*U
   box(id+"pixel"+str(n),center+local,Vector3(18,18,1),[ORANGE,Color("68b2c3"),Color("a7c78e")][value] if n in marks else Color("36545c"))
 for i:int in 3:box(id+"status"+str(i),center+Vector3(38,25-i*12,6)*U,Vector3(30-i*5,2,1),METAL)
func cable(id:String,from:Vector2,to:Vector2,lit:bool,progress:float)->void:
 var a:=from+Vector2(30,24);var b:=to+Vector2(-30,24)
 var points:Array[Vector2]=[]
 for n:int in 19:
  var t:=n/18.0;var u:=1-t;points.append(from*u*u*u+a*3*u*u*t+b*3*u*t*t+to*t*t*t)
 for n:int in 18:line(id+str(n),points[n],points[n+1],3,RUBBER,5)
 if lit:
  var f:=clampf(progress,0,.999)*18;var at:Vector2=points[int(f)].lerp(points[int(f)+1],f-int(f))
  cylinder(id+"packet",visible_p(at,10),4,5,ORANGE)
func card(id:String,at:Vector2,value:int)->void:
 pad(id,at+Vector2(29,22),Vector2(67,53),IVORY,9)
 var marks:Array=[[0,1,4,7],[0,3,4,5],[1,2,4,7]][value]
 for n:int in 9:
  box(id+str(n),visible_p(at+Vector2((n%3)*16+7,floorf(n/3.0)*12+6),14),Vector3(12,1,12),[ORANGE,Color("68b2c3"),Color("a7c78e")][value] if n in marks else METAL)
func signal_scene(v:Control)->void:
 for target:String in v.Model.INPUTS:
  if not v.model.wires.has(target):continue
  var source:String=v.model.wires[target];var start:float=v.Model.HOP_SECONDS if source.begins_with("split_") else 0
  var live:bool=source=="live" or (source.begins_with("split_") and v.model.source_for("split").kind=="live")
  var end:Vector2=v.pointer if v.gesture=="wire" and v.drag_input==target and v.pointer.distance_to(v.press_at)>10 else v._port_position(target)
  cable("wire"+target,v._port_position(source),end,v.model.running and live and v.model.elapsed>=start and v.model.elapsed<=start+v.Model.HOP_SECONDS,(v.model.elapsed-start)/v.Model.HOP_SECONDS)
 monitor("source",Vector2(42,112),v.model.source_pattern);monitor("cache",Vector2(42,252),v.model.cached_pattern)
 for id:String in ["left","right"]:monitor(id,v.receiver_at(id),v.model.displayed[id])
 box("splitter",visible_p(Vector2(429,276),12),Vector3(132,24,136),TEAL)
 for i:int in 6:line("vent"+str(i),Vector2(388+i*14,240),Vector2(388+i*14,255),1.5,DARK,28)
 for id:String in v.PORT_ORDER:
  var at:Vector2=v._port_position(id)
  cylinder("port"+id,visible_p(at,7),18,14,DARK)
  cylinder("socket"+id,visible_p(at,15),12,3,ORANGE if v.selected==id else METAL)
  box("slot"+id,visible_p(at,17),Vector3(15,2,9),RUBBER)
 pad("cardtray",Vector2(219,399),Vector2(302,68),TEAL)
 for i:int in 3:
  if v.gesture=="card" and v.card==i:continue
  card("card"+str(i),v.part_at("card%d"%i,Vector2(91+i*93,374)),i)
 if v.gesture=="wire" and v.drag_input.is_empty() and not v.drag_output.is_empty() and v.pointer.distance_to(v.press_at)>10:cable("heldwire",v._port_position(v.drag_output),v.pointer,false,0)
 if v.gesture=="card":card("heldcard",v.pointer-Vector2(25,50),v.card)
