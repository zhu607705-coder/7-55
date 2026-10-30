extends RefCounted
## Uses the incumbent miniature camera, projection, materials and mesh pool.
static func draw(r: Node, v: Control) -> void:
	r.box("room_floor",r.p(Vector2(480,280),-30),Vector3(950,16,640),Color("c7ccc8")*.68)
	# Room context: a sofa, coffee table and the charcoal communal table from photos.
	r.box("sofa_base",r.p(Vector2(430,145),-5),Vector3(610,26,114),r.TEAL)
	r.box("sofa_back",r.p(Vector2(430,101),24),Vector3(610,74,20),r.TEAL)
	for x: float in [133,727]: r.box("sofa_arm"+str(x),r.p(Vector2(x,141),20),Vector3(22,62,115),r.TEAL)
	for i: int in 3:
		r.box("sofa_seat"+str(i),r.p(Vector2(240+i*190,151),10),Vector3(182,26,80),Color("769692"))
	for x: float in [190,670]:
		r.tube("coffee_leg"+str(x),r.p(Vector2(x,202),-28),r.p(Vector2(x,202),-2),5,r.DARK)
	r.box("coffee_table",r.p(v.DESTINATION,-8),Vector3(570,16,178),r.METAL*.7)
	# Quiet outline names the landing surface without a detached confirmation button.
	for x: float in [-255,255]:
		r.line("destination_corner"+str(x),v.DESTINATION+Vector2(x,-34),v.DESTINATION+Vector2(x,35),1.2,r.METAL,.8)
	# Keep a visible floor gap: the two coplanar table tops must never intersect.
	r.box("communal_table",r.p(Vector2(430,383),-13),Vector3(770,26,264),r.DARK)
	for x: float in [90,770]: r.box("table_leg"+str(x),r.p(Vector2(x,441),-25),Vector3(18,35,18),r.RUBBER)
	# Shared notebook is a loose object on the side shelf.
	r.box("notes_shelf",r.p(Vector2(877,126),-6),Vector3(138,12,120),r.METAL*.7)
	if not v.book_open:
		r.pad("bookcover",Vector2(884,105),Vector2(94,49),r.TEAL)
		for x: float in [861,907]: r.box("notepages"+str(x),r.visible_p(Vector2(x,102),9),Vector3(43,8,61),Color("f6edd7"))
	# The whole tray, glass bases, and bail handle rotate about the actual support.
	var basis := Basis(Vector3.FORWARD,v.tray_angle)
	r.box("tray",v.local_point(0,0,5),Vector3(522,10,142),r.TEAL,basis)
	for z: float in [-69,69]: r.box("tray_rim"+str(z),v.local_point(0,z,12),Vector3(522,18,6),r.METAL,basis)
	for x: float in [-258,258]: r.box("tray_end"+str(x),v.local_point(x,0,12),Vector3(6,18,140),r.METAL,basis)
	for i: int in 4:
		var x: float = v.Model.ARMS[i]*v.SPACING
		r.cylinder("coaster"+str(i),v.local_point(x,0,12),33,3,r.IVORY,basis)
		var at: Vector3 = v.dock_base() if v.model.dock_slot == i else v.local_point(x,0,13)
		var cup_basis: Basis = Basis.IDENTITY if v.model.dock_slot == i else basis
		var offset: Vector2 = v.part_at("cup"+str(v.model.cups[i]),v.cup_at(i))-v.cup_at(i)
		at += Vector3(offset.x,0,offset.y/r.Q)*r.U
		if v.gesture == "cup" and v.selected_slot == i:
			at += Vector3(v.cup_delta.x,18,v.cup_delta.y/r.Q)*r.U
			if v.model.draining:
				cup_basis = Basis(Vector3.FORWARD,-.65)
				# Seat the pouring mouth over the basin while retaining bounded hand
				# movement. The stream shares this exact glass transform and rim.
				var hand: Vector2 = v.pointer-v.DRAIN
				var landing: Vector2 = v.DRAIN+Vector2(-30+clampf(hand.x,-14,14),clampf(hand.y,-10,10))
				var lip: Vector3 = r.p(landing,58)
				at = lip-cup_basis*Vector3(-26,72,0)*r.U
				if v.model.water[v.model.cups[i]] > 0:
					r.tube("drain_stream",at+cup_basis*Vector3(-26,72,0)*r.U,r.p(landing,7),1.8,Color("9bcdd8"))
		var cup: int = v.model.cups[i]
		glass(r,"cup"+str(cup),at,cup_basis,v.model.water[cup],v.Model.TARGETS[cup],v.motion_time,not v.reduced_motion and (v.model.flowing() or v.model.phase in ["lifting","tilted","delivering"]))
	var support: float = v.model.support*v.SPACING
	for z: float in [-58,58]:
		r.tube("handlepost"+str(z),v.local_point(support,z,13),v.local_point(support,z,100),4,r.METAL,.6)
	r.tube("bail",v.local_point(support,-58,100),v.local_point(support,58,100),5,r.METAL,.6)
	r.tube("grip",v.local_point(support,-23,100),v.local_point(support,23,100),9,r.ORANGE)
	if v.model.earned:
		r.tube("support_rail",v.local_point(-22.5,77,12),v.local_point(22.5,77,12),2.5,r.METAL)
		for x: float in [-22.5,0,22.5]: r.cylinder("support_notch"+str(x),v.local_point(x,77,14),3,3,r.RUBBER,basis)
		r.box("support_grip",v.local_point(support,77,16),Vector3(26,13,20),r.ORANGE,basis)
	# A level reference hangs below the grip. No numeric torque meter is needed.
	r.tube("plumb",v.local_point(support,56,95),v.local_point(support,56,95)+Vector3(0,-.55,0),.8,r.DARK)
	r.cylinder("plumb_tip",v.local_point(support,56,95)+Vector3(0,-.55,0),4,7,r.ORANGE)
	station(r,v)

static func station(r: Node, v: Control) -> void:
	var base: Vector3 = v.dock_base()
	r.box("water_station",r.p(Vector2(870,384),-6),Vector3(144,18,250),r.TEAL)
	r.box("water_body",base+Vector3(0,.47,-.67),Vector3(70,100,44),r.METAL)
	r.box("water_face",base+Vector3(0,.49,-.44),Vector3(61,85,5),r.DARK)
	var nozzle := base+Vector3(0,1.04,0)
	r.tube("water_neck",base+Vector3(0,.9,-.67),base+Vector3(0,1.04,-.67),6,r.METAL,.6)
	r.tube("water_spout",base+Vector3(0,1.04,-.67),nozzle,6,r.METAL,.6)
	r.tube("water_lip",nozzle,nozzle-Vector3(0,.08,0),5,r.DARK)
	var valve_root := base+Vector3(.42,.6,-.25)
	r.cylinder("water_valve_pivot",valve_root,12,13,r.METAL,Basis(Vector3.RIGHT,PI/2),.6)
	var grip: Vector3 = r.visible_p(v.valve_at(),90)
	r.tube("water_valve_stem",valve_root,grip,3,r.METAL,.6)
	r.cylinder("water_valve_grip",grip,9,17,r.ORANGE)
	r.cylinder("water_dock",base-Vector3(0,.10,0),34,5,r.DARK)
	r.pad("drain_basin",v.DRAIN,Vector2(115,46),r.DARK,1)
	for i: int in 6:
		r.line("drain_grate"+str(i),v.DRAIN+Vector2(-42+i*17,-16),v.DRAIN+Vector2(-42+i*17,16),1,r.METAL,7)
	if v.model.flowing():
		var cup: int = v.model.cups[v.model.dock_slot]
		var surface: float = 3+v.model.water[cup]/v.Model.CAPACITY*62
		r.tube("water_stream",nozzle-Vector3(0,.09,0),base+Vector3(0,surface*r.U,0),1.4,Color("9bcdd8"))
		if not v.reduced_motion:
			var droplet := fposmod(v.motion_time*1.6,.5)
			r.cylinder("water_drop",nozzle-Vector3(0,.2+droplet,0),2.4,4,r.IVORY)

static func glass(r: Node, id: String, at: Vector3, basis: Basis, volume: float, target: float, clock: float, moving: bool) -> void:
	# Clear cylindrical wall, visible tea level and a solid rim; equal-size glasses.
	var wall: MeshInstance3D = r.mesh(id+"glass",r.meshes.get("glass",glass_mesh(r)),at+basis*Vector3(0,.36,0),Color("d5e8e3"),basis)
	if not r.materials.has("pantry_glass"):
		var clear_glass: StandardMaterial3D = r.material(Color("d5e8e3")).duplicate()
		clear_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		clear_glass.albedo_color.a = .20; clear_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
		r.materials.pantry_glass = clear_glass
	var material: StandardMaterial3D = r.materials.pantry_glass
	wall.material_override = material; wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var fill: float = 3+snappedf(volume/180.0*62,.5)
	var slope: float = snappedf(-basis.x.y/basis.y.y,.01)
	# Tea is contained by the tilted glass; its exposed surface stays horizontal.
	# Cache only quantized poses, never unbounded frame-time geometry.
	var liquid_key := "tea"+str([fill,slope])
	if not r.meshes.has(liquid_key):
		var side := SurfaceTool.new();side.begin(Mesh.PRIMITIVE_TRIANGLES)
		var top := SurfaceTool.new();top.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i:int in 32:
			var a:float=TAU*i/32;var b:float=TAU*(i+1)/32
			var pa:=Vector3(cos(a)*23,clampf(fill+cos(a)*23*slope,0,71),sin(a)*23)
			var pb:=Vector3(cos(b)*23,clampf(fill+cos(b)*23*slope,0,71),sin(b)*23)
			var ba:=Vector3(pa.x,0,pa.z);var bb:=Vector3(pb.x,0,pb.z)
			r.tri(side,ba,pa,pb);r.tri(side,ba,pb,bb)
			# Surface stays horizontal even when its edge meets the tilted glass base.
			var ra := minf(23,fill/maxf(.0001,-cos(a)*slope)) if fill+cos(a)*23*slope<0 else 23.0
			var rb := minf(23,fill/maxf(.0001,-cos(b)*slope)) if fill+cos(b)*23*slope<0 else 23.0
			r.tri(top,Vector3(0,fill,0),Vector3(cos(b)*rb,fill+cos(b)*rb*slope,sin(b)*rb),Vector3(cos(a)*ra,fill+cos(a)*ra*slope,sin(a)*ra))
		side.generate_normals();top.generate_normals()
		r.meshes[liquid_key]=side.commit();r.meshes[liquid_key+"top"]=top.commit()
	if volume > .01:
		r.mesh(id+"tea",r.meshes[liquid_key],at,Color("5b9aaf"),basis)
		r.mesh(id+"water",r.meshes[liquid_key+"top"],at,Color("9bcdd8"),basis)
	if moving and volume > .01:
		var ripple:float=sin(clock*8)*2
		r.tube(id+"ripple",at+basis*Vector3(-10,fill+.8-10*slope,ripple)*r.U,at+basis*Vector3(10,fill+.8+10*slope,ripple)*r.U,.7,r.IVORY)
	for level: float in [0,72]:
		for i: int in 24:
			var a: float = TAU*i/24; var b: float = TAU*(i+1)/24
			r.tube(id+"rim"+str([level,i]),at+basis*Vector3(cos(a)*26,level,sin(a)*26)*r.U,at+basis*Vector3(cos(b)*26,level,sin(b)*26)*r.U,1.4,r.IVORY)
	# Exterior vertical marks make the different fill heights legible without color.
	r.tube(id+"measure",at+basis*Vector3(0,5,26)*r.U,at+basis*Vector3(0,45,26)*r.U,1,r.IVORY)
	for ml: float in [target-8,target+8]:
		var h: float = 3+ml/180*62
		# Two copper arcs describe the requested band on the glass itself.
		for i: int in 12:
			var a: float = PI*.15+PI*.7*i/12; var b: float = PI*.15+PI*.7*(i+1)/12
			r.tube(id+"target"+str([ml,i]),at+basis*Vector3(cos(a)*26,h,sin(a)*26)*r.U,at+basis*Vector3(cos(b)*26,h,sin(b)*26)*r.U,1.2,r.ORANGE)

static func glass_mesh(r: Node) -> Mesh:
	if not r.meshes.has("glass"):
		var shape := CylinderMesh.new(); shape.top_radius = .26; shape.bottom_radius = .26
		shape.height = .72; shape.radial_segments = 32; shape.cap_top = false; shape.cap_bottom = false
		r.meshes.glass = shape
	return r.meshes.glass
