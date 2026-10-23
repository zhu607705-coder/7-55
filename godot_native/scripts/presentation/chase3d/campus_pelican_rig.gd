extends "res://scripts/presentation/chase3d/campus_human_rig.gd"
## Original avian mesh. Reuses only the analytic, pelvis-led contact solver.
## No Rodin mesh, demo artwork, timer, collision body or progression authority.
const AVIAN_SHADER=preload("res://scripts/presentation/chase3d/pelican_feather.gdshader")
const WEB_PROFILE: Array[Vector3]=[Vector3(-.145,-.05,-.25),Vector3(.145,-.05,-.25),Vector3(0,-.05,.09),Vector3(-.145,-.10,-.25),Vector3(.145,-.10,-.25),Vector3(0,-.10,.09)]

func _ready() -> void:
	swing_middle_flex=1.1 # Tuck the bird's leg before crossing the rear wheel.
	walk_asset=JSON.parse_string(FileAccess.get_file_as_string("res://assets/native_755/ride/student_walk_cc0.json"))
	skeleton=Skeleton3D.new();skeleton.name="PelicanSkeleton";add_child(skeleton)
	_bone("Hips","",Vector3(0,1.6,.15))
	_bone("Torso","Hips",Vector3(0,1.96,.11))
	_bone("Neck","Torso",Vector3(0,2.24,-.15))
	_bone("Head","Neck",Vector3(0,2.79,-.32))
	_bone("Tail","Hips",Vector3(0,1.83,.67))
	for side: int in [-1,1]:
		var suffix: String="L" if side<0 else "R"
		_bone("Shoulder"+suffix,"Torso",Vector3(side*.39,2.08,.14))
		_bone("Elbow"+suffix,"Shoulder"+suffix,Vector3(side*.51,1.69,-.29))
		_bone("Wrist"+suffix,"Elbow"+suffix,Vector3(side*.60,1.25,-.72))
		_bone("Hip"+suffix,"Hips",Vector3(side*.23,1.60,.15))
		_bone("Knee"+suffix,"Hip"+suffix,Vector3(side*.23,.89,.15))
		_bone("Foot"+suffix,"Knee"+suffix,Vector3(side*.23,.15,.15))
	for key: String in bone_ids:bind_bases[key]=Basis.IDENTITY
	skin=Skin.new()
	for key: String in bone_ids:skin.add_bind(bone_ids[key],Transform3D(Basis.IDENTITY,rests[key]).affine_inverse())
	_geometry()
	for color: String in surfaces:
		var tool: SurfaceTool=surfaces[color]
		var mat:=ShaderMaterial.new();mat.shader=AVIAN_SHADER
		mat.set_shader_parameter("base_color",Color(color))
		var mesh:=MeshInstance3D.new();mesh.name="Pelican_"+color
		tool.set_material(mat);mesh.mesh=tool.commit();mesh.skin=skin
		mesh.skeleton=NodePath("../PelicanSkeleton");add_child(mesh)

func _geometry() -> void:
	# A pear-shaped feathered body, distinct shoulder mantle and long throat.
	_ellipsoid("E8E0C8",Vector3(0,1.84,.27),Vector3(.49,.43,.62),"Hips","Torso",.35)
	_ellipsoid("F4EAD5",Vector3(0,2.04,-.03),Vector3(.38,.39,.39),"Torso")
	_feather_strip("F4EAD5",Vector3(0,2.08,-.14),Vector3(0,2.47,-.37),.17,"Torso","Neck",.55)
	_feather_strip("F4EAD5",Vector3(0,2.43,-.35),Vector3(0,2.79,-.32),.145,"Neck","Head",.5)
	_ellipsoid("F4EAD5",rests.Head+Vector3(0,.035,-.03),Vector3(.225,.245,.29),"Head")
	# Pelican pouch is below a long, flat bill; no duck's short conical beak.
	_ellipsoid("D3A451",rests.Head+Vector3(0,-.115,-.57),Vector3(.18,.17,.57),"Head")
	_wedge("F4CD77",Vector3(-.19,2.82,-.48),Vector3(.19,2.82,-.48),Vector3(0,2.79,-1.54),.065,"Head")
	_wedge("A1744E",Vector3(-.18,2.747,-.50),Vector3(.18,2.747,-.50),Vector3(0,2.735,-1.51),.012,"Head")
	for side: int in [-1,1]:
		var suffix: String="L" if side<0 else "R"
		_ellipsoid("D8C7A0",rests.Head+Vector3(side*.207,.065,-.09),Vector3(.027,.066,.064),"Head")
		_ellipsoid("202B35",rests.Head+Vector3(side*.226,.067,-.103),Vector3(.015,.036,.035),"Head")
		_ellipsoid("F4EAD5",rests.Head+Vector3(side*.236,.080,-.115),Vector3(.008,.009,.009),"Head")
		# Broad wing roots overlap the body. Joint feathers share both bones.
		_ellipsoid("C5C1A9",rests["Shoulder"+suffix]+Vector3(side*.03,-.06,.12),Vector3(.16,.24,.31),"Torso","Shoulder"+suffix,.6)
		_feather_strip("E8E0C8",rests["Shoulder"+suffix],rests["Elbow"+suffix],.16,"Shoulder"+suffix,"Elbow"+suffix,.20)
		_ellipsoid("E8E0C8",rests["Elbow"+suffix],Vector3(.14,.14,.14),"Shoulder"+suffix,"Elbow"+suffix,.5)
		_feather_strip("C5C1A9",rests["Elbow"+suffix],rests["Wrist"+suffix],.12,"Elbow"+suffix,"Wrist"+suffix,.2)
		for feather: int in range(4):
			var start: Vector3=rests["Elbow"+suffix].lerp(rests["Wrist"+suffix],.24+feather*.16)
			var end: Vector3=start+Vector3(side*(.14+.025*feather),-.17,.16)
			_feather_strip("526B7A" if feather%2==0 else "344452",start,end,.048,"Elbow"+suffix,"Wrist"+suffix,.28)
		_ellipsoid("344452",rests["Wrist"+suffix],Vector3(.09,.10,.11),"Wrist"+suffix)
		# Upper legs emerge from flank feathers; orange shanks end in wide webs.
		_feather_strip("E8E0C8",rests["Hip"+suffix],rests["Knee"+suffix],.105,"Hip"+suffix,"Knee"+suffix,.12)
		_ellipsoid("D3A451",rests["Knee"+suffix],Vector3(.074,.08,.075),"Hip"+suffix,"Knee"+suffix,.5)
		_feather_strip("D3A451",rests["Knee"+suffix],rests["Foot"+suffix],.052,"Knee"+suffix)
		var f: Vector3=rests["Foot"+suffix]
		_wedge("D3A451",f+Vector3(-.145,-.05,-.25),f+Vector3(.145,-.05,-.25),f+Vector3(0,-.05,.09),.05,"Foot"+suffix)
		for toe: int in [-1,0,1]:
			_feather_strip("F4CD77",f+Vector3(0,-.045,.025),f+Vector3(toe*.12,-.055,-.24+abs(toe)*.04),.024,"Foot"+suffix)
	for feather: int in range(5):
		var x: float=(feather-2)*.085
		_wedge("526B7A" if feather%2==0 else "C5C1A9",Vector3(x-.055,1.84,.58),Vector3(x+.055,1.84,.58),Vector3(x*1.25,1.89,1.04-absf(x)*.5),.025,"Tail")

func _wedge(color: String,a: Vector3,b: Vector3,tip: Vector3,depth: float,bone: String) -> void:
	var tool: SurfaceTool=_tool(color)
	var pts: Array[Vector3]=[a,b,tip,a-Vector3.UP*depth,b-Vector3.UP*depth,tip-Vector3.UP*depth]
	for indices: Array in [[0,2,1],[3,4,5],[0,1,4],[0,4,3],[1,2,5],[1,5,4],[2,0,3],[2,3,5]]:
		var n: Vector3=(pts[indices[1]]-pts[indices[0]]).cross(pts[indices[2]]-pts[indices[0]]).normalized()
		for i: int in indices:_vertex(tool,pts[i],n,bone)

# Tapered, two-joint feather strips, rather than disconnected rigid capsules.
func _feather_strip(color: String,start: Vector3,end: Vector3,width: float,bone: String,other: String="",blend: float=0) -> void:
	var direction: Vector3=(end-start).normalized();var basis:=Basis(Quaternion(Vector3.UP,direction))
	var tool: SurfaceTool=_tool(color)
	for ring: int in range(6):
		for side: int in range(12):
			var points: Array[Vector3]=[];var normals: Array[Vector3]=[];var weights: Array[float]=[]
			for cell: Vector2i in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
				var t: float=(ring+cell.y)/6.0;var angle: float=TAU*(side+cell.x)/12
				var n: Vector3=basis*Vector3(cos(angle),0,sin(angle))
				points.append(start.lerp(end,t)+n*width*(.76+.24*sin(PI*t)));normals.append(n);weights.append(t*blend)
			for i: int in [0,2,1,0,3,2]:_vertex(tool,points[i],normals[i],bone,other,weights[i])

func _pose_girdle(torso: Vector3,hips: Vector3,torso_basis: Basis) -> void:
	super._pose_girdle(torso,hips,torso_basis)
	var facing:=Basis(Vector3.UP,torso_basis.get_euler().y)
	_pose("Tail",hips+facing*(rests.Tail-rests.Hips),facing)

func apply_ride(contacts: Dictionary,phase: float,steer: float,reduced: bool=false) -> void:
	super.apply_ride(contacts,phase,steer,reduced)
	# Keep the neck long and the gaze forward instead of folding it into the chest.
	var torso: Vector3=joint_point("Torso")
	var yaw:=Basis(Vector3.UP,-steer*.22)
	_pose("Neck",torso+Vector3(0,.34,-.14),yaw)
	_pose("Head",torso+Vector3(0,.80,-.26),yaw*Basis(Vector3.RIGHT,0 if reduced else sin(phase*2)*.012))

func apply_transition(joints: Dictionary) -> void:
	var calibrated: Dictionary=joints.duplicate(false)
	# Shorter avian leg chain carries a lower walking pelvis. This is a fixed
	# gait calibration, never a reverse solve from a requested foot position.
	calibrated.neutral_pelvis_offset=-.12
	super.apply_transition(calibrated)
	var torso: Vector3=joint_point("Torso")
	var facing:=Basis(Vector3.UP,float(joints.get("body_yaw",0)))
	_pose("Neck",torso+facing*Vector3(0,.34,-.14),facing)
	_pose("Head",torso+facing*Vector3(0,.80,-.26),facing)

func _hip_driven_swing(suffix: String,hip: Vector3,pelvis: Basis,swing: Dictionary,foot_basis: Basis,sole_offset: Vector3) -> void:
	super._hip_driven_swing(suffix,hip,pelvis,swing,foot_basis,sole_offset)
	var clearance: float=.02*sin(PI*float(swing.progress))
	if lowest_web_height(suffix)>=clearance:return
	# Toe-off is knee flexion, never a translated ankle or a lifted pelvis.
	var knee: Vector3=joint_point("Knee"+suffix)
	var upper_basis: Basis=desired["Hip"+suffix].basis
	var upper_dir: Vector3=(knee-hip).normalized()
	var lower_dir: Vector3=(joint_point("Foot"+suffix)-knee).normalized()
	var flex: float=acos(clampf(upper_dir.dot(lower_dir),-1,1))
	var ankle: Vector3=joint_point("Foot"+suffix)
	for step: int in range(1,121):
		var folded: float=lerpf(flex,2.5,step/120.0)
		lower_dir=upper_basis*Basis(Vector3.RIGHT,-folded)*Vector3.DOWN
		ankle=knee+lower_dir*chain_lengths("leg",suffix).y
		if _web_bottom(ankle,foot_basis)>=clearance:break
	_pose("Knee"+suffix,knee,Basis(Quaternion((rests["Foot"+suffix]-rests["Knee"+suffix]).normalized(),lower_dir)))
	_pose("Foot"+suffix,ankle,foot_basis)

func _web_bottom(ankle: Vector3,basis: Basis) -> float:
	var bottom: float=INF
	for vertex: Vector3 in WEB_PROFILE:bottom=minf(bottom,(ankle+basis*vertex).y)
	return bottom

func lowest_web_height(suffix: String) -> float:
	var pose: Transform3D=global_transform.affine_inverse()*skeleton.global_transform*skeleton.get_bone_global_pose(bone_ids["Foot"+suffix])
	return _web_bottom(pose.origin,pose.basis)
