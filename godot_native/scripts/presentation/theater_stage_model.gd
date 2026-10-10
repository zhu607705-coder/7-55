extends Node3D
## A bounded stage model, not a replacement world or a progression authority.
## Source logical coordinates are projected onto the floor, then the shared
## lens warps the rendered viewport and inversely maps pointer input.
var camera:Camera3D
var lamp:Node3D
var lamp_head:Node3D
var key_light:SpotLight3D
var echo_light:OmniLight3D
var beam:MeshInstance3D
var chairs:Array[Node3D]=[]
var materials:Dictionary={}
var floor_atlas:Texture2D=preload("res://assets/rpg/interiors/theater_interior.png")
var source_rules=preload("res://scripts/games/c3_spotlight_model.gd").new()
var static_surfaces:Dictionary={}
var beam_material:StandardMaterial3D
var target_world:=Vector3.ZERO
var last_aim:=Vector3.ZERO
func matte(hex:String,unlit:bool=false)->StandardMaterial3D:
	var id:String=hex+str(unlit)
	if materials.has(id):return materials[id]
	var m:=StandardMaterial3D.new();m.albedo_color=Color(hex);m.roughness=.94;m.cull_mode=BaseMaterial3D.CULL_DISABLED
	if unlit:m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	materials[id]=m;return m
func mesh_node(mesh:Mesh,mat:Material,parent:Node3D=self)->MeshInstance3D:
	var n:=MeshInstance3D.new();n.mesh=mesh;n.material_override=mat;parent.add_child(n);return n
func box(at:Vector3,extent:Vector3,hex:String,parent:Node3D=self)->MeshInstance3D:
	var m:=BoxMesh.new();m.size=extent;var n:=mesh_node(m,matte(hex),parent);n.position=at;return n
func cylinder(at:Vector3,radius:float,height:float,hex:String,parent:Node3D=self)->MeshInstance3D:
	var m:=CylinderMesh.new();m.top_radius=radius;m.bottom_radius=radius;m.height=height;m.radial_segments=24
	var n:=mesh_node(m,matte(hex),parent);n.position=at;return n
func rod(a:Vector3,b:Vector3,radius:float,hex:String,parent:Node3D=self)->MeshInstance3D:
	var n:MeshInstance3D=cylinder((a+b)*.5,radius,a.distance_to(b),hex,parent)
	var up:Vector3=(b-a).normalized();var right:Vector3=Vector3.FORWARD.cross(up).normalized()
	if right.length_squared()<.01:right=Vector3.RIGHT
	n.basis=Basis(right,up,right.cross(up)).orthonormalized();return n
func world_point(p:Vector2,height:float=0)->Vector3:
	var origin:Vector3=camera.project_ray_origin(p);var ray:Vector3=camera.project_ray_normal(p)
	return origin+ray*((height-origin.y)/ray.y)
func polygon(points:PackedVector3Array,hex:String)->void:
	if not static_surfaces.has(hex):
		var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES);static_surfaces[hex]=surface
	var st:SurfaceTool=static_surfaces[hex]
	var source0:Vector2=camera.unproject_position(points[0])
	var source2:Vector2=camera.unproject_position(points[2])
	for i in range(1,points.size()-1):
		for p:Vector3 in [points[0],points[i+1],points[i]]:
			var screen:Vector2=camera.unproject_position(p)
			var u:float=clampf((screen.x-source0.x)/maxf(.1,source2.x-source0.x),0,1)
			var v:float=clampf((screen.y-source0.y)/maxf(.1,source2.y-source0.y),0,1)
			st.set_uv(Vector2((916+u*64)/1672.0,(227+v*24)/941.0))
			st.add_vertex(p)
func _finish_static_surfaces()->void:
	for hex:String in static_surfaces:
		var st:SurfaceTool=static_surfaces[hex];st.generate_normals()
		var material:StandardMaterial3D=matte(hex)
		if hex in ["493239","553738","624039","593b37","6c473b","533939"]:
			material=material.duplicate();material.albedo_texture=floor_atlas;material.albedo_color=Color("9397bd").lightened(float(["493239","553738","624039","593b37","6c473b","533939"].find(hex))*.018);material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mesh_node(st.commit(),material)
	static_surfaces.clear()
func _merge_static_geometry()->void:
	# Batch static scenery by material. Only the two chairs and lamp are articulated.
	var batches:Dictionary={}
	for child:Node in get_children():
		if not child is MeshInstance3D:continue
		var material:Material=child.material_override
		if not batches.has(material):
			var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES);batches[material]=surface
		batches[material].append_from(child.mesh,0,child.transform)
		remove_child(child);child.free()
	for material:Material in batches:
		mesh_node(batches[material].commit(),material)
func _ready()->void:
	camera=Camera3D.new();add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=10.0
	camera.position=Vector3(0,12,14);camera.look_at(Vector3.ZERO);camera.current=true
	var environment:=WorldEnvironment.new();environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("070810")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color("8680a7");environment.environment.ambient_light_energy=.65
	environment.environment.tonemap_mode=Environment.TONE_MAPPER_LINEAR;add_child(environment)
	var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-56,-32,0);fill.light_color=Color("f2cda3");fill.light_energy=.68;fill.shadow_enabled=false;add_child(fill)
	_build_stage();_finish_static_surfaces();_merge_static_geometry();_build_lamp()
	echo_light=OmniLight3D.new();echo_light.name="DelayedEchoLight";echo_light.light_color=Color("78eeed");echo_light.light_energy=.55;echo_light.omni_range=1.8;echo_light.shadow_enabled=false;echo_light.visible=false;add_child(echo_light)
	for i in 2:
		var chair:=_build_chair();chairs.append(chair)
	update_pose(preload("res://scripts/games/c3_spotlight_model.gd").new().create(0),0)
func _build_stage()->void:
	# The floor remains flat for exact ray picking. Its visible border has thickness,
	# staggered boards, grain strips and a crooked rear seam, unlike a flat plate.
	var floor_color:Array[String]=["493239","553738","624039","593b37","6c473b","533939"]
	for row in 19:
		var y0:float=137+row*14.6;var y1:float=y0+14.35
		for col in 8:
			var x0:float=-22+col*137+(68 if row%2 else 0);var x1:float=x0+135
			var bend0:float=3*sin(x0*.007)+row*.12;var bend1:float=3*sin(x1*.007)+row*.12
			var pts:=PackedVector3Array([world_point(Vector2(x0,y0+bend0)),world_point(Vector2(x1,y0+bend1)),world_point(Vector2(x1,y1+bend1)),world_point(Vector2(x0,y1+bend0))])
			polygon(pts,floor_color[(row*3+col*7)%floor_color.size()])
			for grain in 1:
				var gy:float=y0+3.0+grain*3.3;var gx:float=x0+14+fmod(row*17+grain*23,34)
				polygon(PackedVector3Array([world_point(Vector2(gx,gy),.002),world_point(Vector2(minf(x1-12,gx+63+col*3),gy+.35),.002),world_point(Vector2(minf(x1-12,gx+63+col*3),gy+.9),.002),world_point(Vector2(gx,gy+.6),.002)]),"3e3035")
	# Dark exposed apron face, three thin brass strips, physical footlights.
	for i in 24:
		var x0:float=i*40;var x1:float=(i+1)*40
		var y0:float=418+sin(i*.14)*3;var y1:float=418+sin((i+1)*.14)*3
		polygon(PackedVector3Array([world_point(Vector2(x0,y0)),world_point(Vector2(x1,y1)),world_point(Vector2(x1,y1+23),-.4),world_point(Vector2(x0,y0+23),-.4)]),"251b26")
		for edge in [0,4,18]:rod(world_point(Vector2(x0,y0+edge),-.01*edge),world_point(Vector2(x1,y1+edge),-.01*edge),.014,"846349")
		if i%2==0:
			var p:Vector3=world_point(Vector2(x0+20,y0-3),.08)
			var bulb:=SphereMesh.new();bulb.radial_segments=8;bulb.rings=4;bulb.radius=.035;bulb.height=.07;mesh_node(bulb,matte("efbd77",true)).position=p
	# Pleated legs and several rear wings. Geometry narrows toward the stage.
	for side in [-1,1]:
		for layer in 3:_curtain(side,layer)
	# Scalloped valance: small facets create dense folds at the top of the frame.
	for segment in 36:
		var x0:float=-20+segment*28;var x1:float=x0+27.8
		var drop:float=98+9*sin(segment*.55)+3*sin(segment*1.7)
		polygon(PackedVector3Array([world_point(Vector2(x0,28),3.4),world_point(Vector2(x1,28),3.4),world_point(Vector2(x1,drop),2.2),world_point(Vector2(x0,drop+3),2.2)]),["5e203b","78283e","8e3245","632139"][segment%4])
		rod(world_point(Vector2(x0,drop+3),2.21),world_point(Vector2(x1,drop),2.21),.028,"b48b55")
	# Suspended rigging remains part of the scene, so the lens bends it too.
	for y in [111,120]:rod(world_point(Vector2(88,y),2.2),world_point(Vector2(880,y+8),2.2),.025,"3a414b")
	for x in [210,420,640,850]:rod(world_point(Vector2(x,109),2.2),world_point(Vector2(x+4,135),2.2),.018,"55545b")
func _curtain(side:int,layer:int)->void:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows:int=16;var cols:int=20
	for y in rows:
		for x in cols:
			var vertices:Array[Vector3]=[]
			for corner:Vector2 in [Vector2(x,y),Vector2(x+1,y),Vector2(x+1,y+1),Vector2(x,y+1)]:
				var u:float=corner.x/cols;var v:float=corner.y/rows
				var width:float=80-31*sin(v*PI)-25*v+layer*5
				var sx:float=u*width-layer*21+sin(v*3+layer)*8
				if side==1:sx=960-sx
				var sy:float=72+v*(351-layer*27)+sin(u*7)*5*v
				vertices.append(world_point(Vector2(sx,sy),2.8*(1-v)+.08*sin(u*TAU*5)+layer*.12))
			for index in [0,2,1,0,3,2]:
				var value:float=.58+.32*sin(float(x)/cols*TAU*5)
				st.set_color(Color("a83b51")*Color(value,value,value,1));st.add_vertex(vertices[index])
	st.generate_normals();var material:=matte("ffffff").duplicate();material.vertex_color_use_as_albedo=true
	mesh_node(st.commit(),material)
func _build_lamp()->void:
	lamp=Node3D.new();lamp.name="IndependentFollowspot";add_child(lamp)
	lamp.position=world_point(Vector2(192,130),2.45)
	# Suspension, swiveling yoke, tilt pivot, steel shell, fin rings, lens, barn doors.
	rod(Vector3(0,.8,0),Vector3(0,.32,0),.035,"6e6966",lamp)
	box(Vector3(0,.24,0),Vector3(.64,.07,.1),"b19366",lamp)
	for signum in [-1,1]:
		box(Vector3(signum*.30,.02,0),Vector3(.065,.5,.13),"7b7770",lamp)
		var pin:MeshInstance3D=cylinder(Vector3(signum*.31,-.17,0),.08,.10,"c7a975",lamp);pin.rotation_degrees.z=90
	lamp_head=Node3D.new();lamp_head.name="TiltPivot";lamp.add_child(lamp_head);lamp_head.position.y=-.17
	var body:MeshInstance3D=cylinder(Vector3(0,0,.06),.235,.66,"414650",lamp_head);body.rotation_degrees.x=90
	for index in 7:
		var fin:MeshInstance3D=cylinder(Vector3(0,0,.22-index*.055),.25,.016,"202630",lamp_head);fin.rotation_degrees.x=90
	var rim:MeshInstance3D=cylinder(Vector3(0,0,-.31),.25,.08,"b39364",lamp_head);rim.rotation_degrees.x=90
	var glass:MeshInstance3D=cylinder(Vector3(0,0,-.356),.197,.012,"f5d8a0",lamp_head);glass.rotation_degrees.x=90;glass.material_override=matte("f5d8a0",true)
	for side in [-1,1]:
		var door:MeshInstance3D=box(Vector3(side*.23,0,-.45),Vector3(.028,.43,.23),"242b36",lamp_head);door.rotation_degrees.y=side*24
		var door2:MeshInstance3D=box(Vector3(0,side*.23,-.45),Vector3(.43,.026,.23),"303844",lamp_head);door2.rotation_degrees.x=side*-23
	key_light=SpotLight3D.new();lamp_head.add_child(key_light);key_light.position.z=-.39;key_light.light_color=Color("ffda98");key_light.light_energy=4.0;key_light.spot_range=18;key_light.spot_angle=14;key_light.spot_attenuation=.55;key_light.shadow_enabled=true
	beam_material=StandardMaterial3D.new();beam_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;beam_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;beam_material.albedo_color=Color(1,.82,.52,.075);beam_material.cull_mode=BaseMaterial3D.CULL_DISABLED;beam_material.disable_receive_shadows=true
	beam=MeshInstance3D.new();beam.name="DustBeam";add_child(beam);beam.material_override=beam_material;beam.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func _build_chair()->Node3D:
	var n:=Node3D.new();n.name="WalkingUpholsteredChair";add_child(n)
	box(Vector3(0,.23,0),Vector3(.62,.08,.42),"c39775",n)
	box(Vector3(0,.28,0),Vector3(.5,.045,.32),"84344c",n)
	box(Vector3(0,.57,-.16),Vector3(.54,.52,.09),"c39775",n)
	box(Vector3(0,.57,-.101),Vector3(.43,.39,.035),"733148",n)
	for x in [-.22,.22]:
		for z in [-.15,.15]:rod(Vector3(x,.24,z),Vector3(x*1.25,0,z*1.25),.026,"aa8460",n)
	for x in [-.12,.12]:
		box(Vector3(x,.61,-.075),Vector3(.07,.095,.025),"ffe5b6",n);box(Vector3(x,.60,-.054),Vector3(.025,.043,.013),"171c2b",n)
	return n
func update_pose(s:Dictionary,t:float)->void:
	if not is_instance_valid(lamp_head):return
	var delayed:Dictionary=source_rules.echo(s)
	echo_light.visible=not delayed.is_empty()
	if echo_light.visible:echo_light.position=world_point(delayed.position,.35)
	target_world=world_point(s.head,.01)
	var direction:Vector3=target_world-lamp.global_position
	lamp.rotation.y=atan2(-direction.x,-direction.z)
	lamp_head.look_at(target_world,Vector3.UP)
	var start:Vector3=lamp_head.to_global(Vector3(0,0,-.39))
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 32:
		var a:float=i*TAU/32;var b:float=(i+1)*TAU/32
		st.add_vertex(start);st.add_vertex(target_world+Vector3(cos(a)*.62,.016,sin(a)*.62));st.add_vertex(target_world+Vector3(cos(b)*.62,.016,sin(b)*.62))
	beam.mesh=st.commit()
	var hazards:Array=source_rules.hazards(s)
	for index in chairs.size():
		chairs[index].position=world_point(hazards[index].position+Vector2(0,18))-Vector3(0,.05,0)
		chairs[index].rotation=Vector3(0,.10*sin(t*3+index),.04*sin(t*6+index))
