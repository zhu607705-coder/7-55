extends "res://campuses/future_learning_center/scripts/miniature_bench.gd"
## Presentation-only adapter for the ORIGINAL Formula energy-budget model.
## All input anchors stay in formula_view's logical plane; visible_p projects
## each grip back onto that plane under the inherited 45-degree camera.
func track_shape(v:Control,lane:int,width:float,height:float)->Mesh:
 var key:="formula_track_%d_%s_%s"%[lane,width,height]
 if meshes.has(key):return meshes[key]
 var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_smooth_group(-1)
 for i:int in 96:
  var a:=p(v.race_point(float(i)/96*20,lane))/U
  var b:=p(v.race_point(float(i+1)/96*20,lane))/U
  var side:=Vector3(-(b-a).z,0,(b-a).x).normalized()*width/2
  var up:=Vector3(0,height,0)
  tri(st,a-side+up,b+side+up,b-side+up);tri(st,a-side+up,a+side+up,b+side+up)
  tri(st,a-side,b-side,b-side+up);tri(st,a-side,b-side+up,a-side+up)
  tri(st,a+side,b+side+up,b+side);tri(st,a+side,a+side+up,b+side+up)
 st.generate_normals();meshes[key]=st.commit();return meshes[key]
func car(id:String,at:Vector2,config:Array,angle:float,scale_value:float,phase:float,identity:int,exposure:float,heading:=0.0,support_height:=6.0)->void:
 var base:=visible_p(at,12*scale_value+support_height)
 box(id+"body",base,Vector3(76,12,46)*scale_value,(TEAL if identity==0 else IVORY)*exposure)
 box(id+"nose",base+Vector3(-.42,.03,0)*scale_value,Vector3(13,9,34)*scale_value,METAL*exposure)
 for x:float in [-27,27]:
  tube(id+"axle"+str(x),base+Vector3(x,-2,-30)*U*scale_value,base+Vector3(x,-2,30)*U*scale_value,2*scale_value,METAL,.6)
  for z:float in [-26,26]:
   var tag:=id+str([x,z]);var hub:=base+Vector3(x,-2,z)*U*scale_value
   cylinder(tag,hub,10*scale_value,8*scale_value,RUBBER,Basis(Vector3.RIGHT,PI/2))
   cylinder(tag+"hub",hub+Vector3(0,0,signf(z)*.045)*scale_value,5*scale_value,1*scale_value,METAL,Basis(Vector3.RIGHT,PI/2),.6)
   tube(tag+"spoke",hub+Vector3(cos(phase)*5,sin(phase)*5,signf(z)*5)*U*scale_value,hub+Vector3(-cos(phase)*5,-sin(phase)*5,signf(z)*5)*U*scale_value,scale_value,ORANGE)
 if config[0]>=0:
  var height:=25*scale_value+support_height
  panel(id+"panel",at+Vector2(0,height*Q),float(62 if config[0]==0 else 94)*scale_value,30*scale_value,deg_to_rad(angle),height,10*scale_value+support_height,exposure)
 if config[2]>=0:gear(id+"gear",at+Vector2(31,8)*scale_value,(8+config[2]*2)*scale_value,phase,ORANGE,19*scale_value+support_height)
 if absf(heading)>.00001:
  var turn:=Basis(Vector3.UP,heading)
  for key:String in touched:
   if key.begins_with(id):
    var node:MeshInstance3D=pool[key]
    node.position=base+turn*(node.position-base);node.basis=turn*node.basis
func heading_at(v:Control,distance:float,lane:int)->float:
 var tangent:=p(v.race_point(distance+.01,lane))-p(v.race_point(distance,lane))
 return atan2(tangent.z,-tangent.x)
func present(v:Control,_mode:String="formula")->void:
 touched.clear();rendered_mode="formula"
 box("table",p(Vector2(480,275),-12),Vector3(938,24,650),IVORY)
 box("assembly",visible_p(Vector2(435,375),1),Vector3(760,9,155),IVORY)
 for lane:int in 2:
  mesh("lane_rim%d"%lane,track_shape(v,lane,22,3),Vector3.ZERO,METAL)
  mesh("lane%d"%lane,track_shape(v,lane,17,5),Vector3.ZERO,RUBBER)
  mesh("lane_line%d"%lane,track_shape(v,lane,1.3,5.3),Vector3.ZERO,IVORY)
  for n:int in 20:
   var mark:Vector2=v.race_point(n,lane)
   line("tick%s"%[Vector2i(lane,n)],mark-Vector2(0,4),mark+Vector2(0,4),.65,METAL,5.5)
 var intensity:float=v.model.irradiance(v.model.time())
 var exposure:=.65+.35*intensity
 lamp.rotation_degrees=Vector3(-30 if v.model.scenario==0 else -60,-65,0);lamp.light_energy=.5*intensity
 # One real shared light controls both lanes. The shutter follows the SAME clock.
 var source:Vector2=v.LAMP
 pad("lamp_foot",source+Vector2(0,20),Vector2(54,35),TEAL,3)
 tube("lamp_arm",p(source+Vector2(0,20),4),visible_p(source,45),4,METAL,.6)
 box("lamp",visible_p(source,45),Vector3(48,22,28),TEAL,Basis(Vector3.RIGHT,-.3))
 box("lamp_lens",visible_p(source+Vector2(0,10),44),Vector3(39,4,18),Color("fff0bd")*exposure)
 if intensity<.3:box("cloud_shutter",visible_p(source+Vector2(-10,14),52),Vector3(50,4,25),DARK)
 for id:int in 2:
  if id==0 and not v.model.on_track:continue
  var at:Vector2=v.held_position() if id==0 and v.action=="car" else v.race_point(v.model.cars[id].distance,id)
  var config:Array=v.model.configuration() if id==0 else v.model.baseline()
  car("runner%d"%id,at,config,v.panel_tilt() if id==0 else float(v.Model.TILTS[config[1]]),.35,v.model.cars[id].distance*10,id,exposure,0.0 if id==0 and v.action=="car" else heading_at(v,v.model.cars[id].distance,id))
 var start:Vector2=v.race_point(0,0)
 line("start_a",start-Vector2(19,11),start+Vector2(19,11),1.5,ORANGE,6)
 line("start_b",start-Vector2(19,-11),start+Vector2(19,-11),1.5,ORANGE,6)
 # The readouts lie on an instrument plate, not floating over the track.
 pad("meter",Vector2(517,177),Vector2(408,77),IVORY,2)
 for i:int in 2:
  var tray:Vector2=v.PANEL_TRAYS[i]
  pad("panelwell%d"%i,tray,Vector2(107,56),DARK,7)
  if v.model.panel!=i:
   var at:Vector2=v.held_position() if v.action=="panel" and v.part==i else tray
   panel("loose_panel%d"%i,at+Vector2(0,12*Q),float(62 if i==0 else 94),30,0,12,7)
 if v.model.on_track:
  pad("sample_paper",v.BENCH_CAR,Vector2(145,54),Color("f6edd7"),8)
  car("sample",v.BENCH_CAR,v.model.configuration(),v.panel_tilt(),.65,0,0,1,0,11)
 else:car("assembly_car",v.held_position() if v.action=="car" else v.BENCH_CAR,v.model.configuration(),v.panel_tilt(),1,0,0,1)
 pad("reference_plinth",Vector2(735,370),Vector2(112,55),METAL,6)
 car("reference",Vector2(735,370),v.model.baseline(),float(v.Model.TILTS[v.model.baseline()[1]]),.65,0,1,1,0,9)
 for i:int in 3:
  var tray:Vector2=v.GEAR_TRAYS[i]
  cylinder("gearwell%d"%i,visible_p(tray,3),27,5,DARK)
  if v.model.gear!=i:gear("loose_gear%d"%i,v.held_position() if v.action=="gear" and v.part==i else tray,15+i*4,0,ORANGE,9)
 knob("tilt",v.TILT_KNOB,deg_to_rad(v.panel_tilt()-90),22)
 var gate:Vector2=v.GATE
 pad("gatebase",gate+Vector2(0,12),Vector2(47,40),TEAL,4)
 var grip:=visible_p(gate+Vector2(0,-22 if v.model.running else -7),30)
 tube("gateshaft",visible_p(gate+Vector2(0,13),8),grip,4,METAL,.6)
 cylinder("gategrip",grip,10,16,ORANGE)
 pad("notebook",Vector2(117,478),Vector2(145,60),TEAL,3)
 pad("notebook_pages",Vector2(117,475),Vector2(132,51),Color("f6edd7"),8)
 for id:String in pool:pool[id].visible=touched.has(id)
