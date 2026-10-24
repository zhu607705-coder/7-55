extends Node3D
## Original human, native weighted skin and analytic two-bone contact chains.
## No independent clock, movement, collision, or progression state.
const DOWN:=Vector3.DOWN
var skeleton: Skeleton3D
var skin: Skin
var bone_ids: Dictionary={}
var rests: Dictionary={}
var surfaces: Dictionary={}
var desired: Dictionary={}
var contact_error: Dictionary={}
const GENERATED_ASSET_PATH: String="res://assets/native_755/ride/rodin/campus_student_rigged.glb"
var generated_asset_path: String=GENERATED_ASSET_PATH
var bind_bases: Dictionary={}
var generated_visual: Node3D
var generated_asset: bool=false
var walk_asset: Dictionary={}
var rig_scale: float=1
var swing_middle_flex: float=.16
const GENERATED_RIDER_SCALE: float=1.18
const BackPrint=preload("res://scripts/presentation/chase3d/campus_student_back_print.gd")

func _ready() -> void:
	walk_asset=JSON.parse_string(FileAccess.get_file_as_string("res://assets/native_755/ride/student_walk_cc0.json"))
	if ResourceLoader.exists(generated_asset_path):
		generated_visual=load(generated_asset_path).instantiate()
		rig_scale=GENERATED_RIDER_SCALE;generated_visual.scale=Vector3.ONE*rig_scale
		add_child(generated_visual)
		var skeletons: Array[Node]=generated_visual.find_children("*","Skeleton3D",true,false)
		assert(skeletons.size()==1,"Generated student requires one calibrated contact skeleton")
		skeleton=skeletons[0]
		for index: int in range(skeleton.get_bone_count()):
			var name: String=skeleton.get_bone_name(index);bone_ids[name]=index
			var rest: Transform3D=global_transform.affine_inverse()*skeleton.global_transform*skeleton.get_bone_global_rest(index)
			rests[name]=rest.origin;bind_bases[name]=rest.basis
		BackPrint.attach(generated_visual,skeleton)
		generated_asset=true;return
	skeleton=Skeleton3D.new();skeleton.name="CampusHumanSkeleton";add_child(skeleton)
	_bone("Hips","",Vector3(0,1.6,.15))
	_bone("Torso","Hips",Vector3(0,2.02,.15))
	_bone("Head","Torso",Vector3(0,2.57,.15))
	for side: int in [-1,1]:
		var suffix: String="L" if side<0 else "R"
		_bone("Shoulder"+suffix,"Torso",Vector3(side*.29,2.17,.15))
		_bone("Elbow"+suffix,"Shoulder"+suffix,Vector3(side*.29,1.7,.15))
		_bone("Wrist"+suffix,"Elbow"+suffix,Vector3(side*.29,1.25,.15))
		_bone("Hip"+suffix,"Hips",Vector3(side*.19,1.6,.15))
		_bone("Knee"+suffix,"Hip"+suffix,Vector3(side*.19,.87,.15))
		_bone("Foot"+suffix,"Knee"+suffix,Vector3(side*.19,.15,.15))
	skin=Skin.new()
	for name: String in bone_ids:skin.add_bind(bone_ids[name],Transform3D(Basis.IDENTITY,rests[name]).affine_inverse())
	_geometry()
	for color: String in surfaces:
		var tool: SurfaceTool=surfaces[color]
		var material:=StandardMaterial3D.new();material.albedo_color=Color(color);material.roughness=.86
		tool.set_material(material)
		var mesh:=MeshInstance3D.new();mesh.name="Human_"+color;mesh.mesh=tool.commit();mesh.skin=skin
		mesh.skeleton=NodePath("../CampusHumanSkeleton");add_child(mesh)

func _bone(name: String,parent: String,point: Vector3) -> void:
	var index: int=skeleton.get_bone_count();skeleton.add_bone(name);bone_ids[name]=index;rests[name]=point
	if not parent.is_empty():skeleton.set_bone_parent(index,bone_ids[parent])
	skeleton.set_bone_rest(index,Transform3D(Basis.IDENTITY,point-(rests[parent] if not parent.is_empty() else Vector3.ZERO)))

func _tool(color: String) -> SurfaceTool:
	if not surfaces.has(color):
		var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);surfaces[color]=tool
	return surfaces[color]

func _vertex(tool: SurfaceTool,point: Vector3,normal: Vector3,bone: String,other: String="",blend: float=0) -> void:
	tool.set_bones(PackedInt32Array([bone_ids[bone],bone_ids.get(other,bone_ids[bone]),0,0]))
	tool.set_weights(PackedFloat32Array([1-blend,blend,0,0]));tool.set_normal(normal);tool.add_vertex(point)

func _ellipsoid(color: String,center: Vector3,radius: Vector3,bone: String,other: String="",blend: float=0) -> void:
	var tool: SurfaceTool=_tool(color)
	for latitude: int in range(10):
		for longitude: int in range(16):
			var points: Array[Vector3]=[];var normals: Array[Vector3]=[]
			for cell: Vector2i in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
				var u: float=TAU*(longitude+cell.x)/16;var v: float=-PI*.5+PI*(latitude+cell.y)/10
				var n:=Vector3(cos(u)*cos(v),sin(v),sin(u)*cos(v))
				points.append(center+n*radius);normals.append((n/radius).normalized())
			for index: int in [0,2,1,0,3,2]:_vertex(tool,points[index],normals[index],bone,other,blend)

func _limb(color: String,start: Vector3,end: Vector3,width: float,bone: String) -> void:
	var direction: Vector3=(end-start).normalized()
	var basis:=Basis(Quaternion(Vector3.UP,direction))
	var tool: SurfaceTool=_tool(color)
	for ring: int in range(6):
		for side: int in range(12):
			var points: Array[Vector3]=[];var normals: Array[Vector3]=[]
			for cell: Vector2i in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
				var t: float=(ring+cell.y)/6.0;var angle: float=TAU*(side+cell.x)/12
				var radius: float=width*(.72+.28*sin(PI*t))
				var normal: Vector3=basis*Vector3(cos(angle),0,sin(angle))
				points.append(start.lerp(end,t)+normal*radius);normals.append(normal)
			for index: int in [0,2,1,0,3,2]:_vertex(tool,points[index],normals[index],bone)

func _geometry() -> void:
	# Cloth silhouettes have shoulder, waist and knee volume instead of long boxes.
	_ellipsoid("385B79",Vector3(0,1.97,.15),Vector3(.35,.38,.205),"Torso")
	_ellipsoid("344452",Vector3(0,1.59,.15),Vector3(.25,.16,.18),"Hips")
	_ellipsoid("E8E0C8",Vector3(0,2.17,-.027),Vector3(.15,.20,.025),"Torso")
	_ellipsoid("243F5A",Vector3(0,1.96,.34),Vector3(.27,.30,.12),"Torso")
	# Compact backpack, straps and jacket collar remain attached to the torso bone.
	_ellipsoid("70503B",Vector3(0,1.98,.43),Vector3(.25,.31,.115),"Torso")
	for side: int in [-1,1]:
		var suffix: String="L" if side<0 else "R"
		_limb("C79B62",Vector3(side*.21,2.19,-.025),Vector3(side*.23,1.82,-.04),.032,"Torso")
		_ellipsoid("385B79",rests["Shoulder"+suffix],Vector3(.135,.15,.14),"Shoulder"+suffix)
		_limb("385B79",rests["Shoulder"+suffix],rests["Elbow"+suffix],.115,"Shoulder"+suffix)
		_ellipsoid("385B79",rests["Elbow"+suffix],Vector3(.09,.10,.09),"Shoulder"+suffix,"Elbow"+suffix,.5)
		_limb("547F9D",rests["Elbow"+suffix],rests["Wrist"+suffix],.086,"Elbow"+suffix)
		_ellipsoid("D89C6A",rests["Wrist"+suffix]+Vector3(0,-.015,0),Vector3(.065,.085,.065),"Wrist"+suffix)
		_limb("344452",rests["Hip"+suffix],rests["Knee"+suffix],.137,"Hip"+suffix)
		_ellipsoid("344452",rests["Knee"+suffix],Vector3(.1,.11,.105),"Hip"+suffix,"Knee"+suffix,.5)
		_limb("526B7A",rests["Knee"+suffix],rests["Foot"+suffix],.098,"Knee"+suffix)
		_ellipsoid("E8E0C8",rests["Foot"+suffix]+Vector3(0,-.035,-.08),Vector3(.10,.075,.20),"Foot"+suffix)
		_ellipsoid("A39B87",rests["Foot"+suffix]+Vector3(0,-.085,-.08),Vector3(.102,.018,.202),"Foot"+suffix)
	# Original compact human face and short hair, with an upright readable head.
	_ellipsoid("D89C6A",Vector3(0,2.35,.15),Vector3(.10,.15,.10),"Torso")
	_ellipsoid("D89C6A",Vector3(0,2.57,.13),Vector3(.18,.235,.17),"Head")
	_ellipsoid("202B35",Vector3(0,2.70,.16),Vector3(.189,.13,.179),"Head")
	_ellipsoid("202B35",Vector3(0,2.62,.25),Vector3(.175,.13,.085),"Head")
	_ellipsoid("D89C6A",Vector3(0,2.55,-.046),Vector3(.04,.045,.046),"Head")
	for side: int in [-1,1]:
		_ellipsoid("A76A4C",Vector3(side*.17,2.56,.12),Vector3(.037,.06,.033),"Head")
		_ellipsoid("202B35",Vector3(side*.068,2.60,-.03),Vector3(.015,.021,.012),"Head")

## The pole is a stable anatomical bend direction, projected off the target axis.
## This is the law-of-cosines two-bone method; no reference implementation copied.
static func solve_joint(start: Vector3,target: Vector3,upper: float,lower: float,pole: Vector3) -> Vector3:
	var offset: Vector3=target-start;var distance: float=clampf(offset.length(),.0001,upper+lower-.0001)
	var direction: Vector3=offset.normalized()
	var across: Vector3=pole-direction*pole.dot(direction)
	if across.length_squared()<.00001:across=direction.cross(Vector3.RIGHT)
	across=across.normalized()
	var along: float=(upper*upper-lower*lower+distance*distance)/(2*distance)
	return start+direction*along+across*sqrt(maxf(0,upper*upper-along*along))

func _pose(name: String,point: Vector3,basis: Basis=Basis.IDENTITY) -> void:
	var transform:=Transform3D(basis*bind_bases.get(name,Basis.IDENTITY),point);desired[name]=transform
	skeleton.set_bone_global_pose(bone_ids[name],skeleton.global_transform.affine_inverse()*global_transform*transform)

func joint_point(name: String) -> Vector3:
	return to_local(skeleton.to_global(skeleton.get_bone_global_pose(bone_ids[name]).origin))

func surface_contact(kind: String,suffix: String) -> Vector3:
	if kind=="seat":
		var hips_pose: Transform3D=global_transform.affine_inverse()*skeleton.global_transform*skeleton.get_bone_global_pose(bone_ids.Hips)
		return hips_pose.origin+hips_pose.basis*bind_bases.get("Hips",Basis.IDENTITY).inverse()*(Vector3(0,-.10,.10)*rig_scale)
	var name: String=("Wrist" if kind=="hand" else "Foot")+suffix
	var pose: Transform3D=global_transform.affine_inverse()*skeleton.global_transform*skeleton.get_bone_global_pose(bone_ids[name])
	var offset: Vector3=Vector3.ZERO
	if kind=="foot":offset=Vector3(0,-.13,-.10) if generated_asset else Vector3(0,-.10,0)
	elif generated_asset:offset=Vector3(-.03 if suffix=="L" else .03,-.11,0)
	return pose.origin+pose.basis*bind_bases.get(name,Basis.IDENTITY).inverse()*(offset*rig_scale)

func _arm_contact(suffix: String,start: Vector3,palm: Vector3,pole: Vector3) -> void:
	var lengths: Vector2=chain_lengths("arm",suffix)
	var wrist: Vector3=palm
	for attempt: int in range(7):
		_chain("arm",suffix,start,wrist,lengths.x,lengths.y,pole)
		wrist+=palm-surface_contact("hand",suffix)
	# A real wrist can flex independently of the forearm. Near maximum reach,
	# orient the palm contact instead of extending or translating either arm bone.
	var error: float=surface_contact("hand",suffix).distance_to(palm)
	var palm_offset: Vector3=(Vector3(-.03 if suffix=="L" else .03,-.11,0) if generated_asset else Vector3.ZERO)*rig_scale
	var reach: float=lengths.x+lengths.y+palm_offset.length()
	if error>.0005 and palm_offset.length()>.001 and start.distance_to(palm)<reach-.001:
		var direction: Vector3=(palm-start).normalized()
		wrist=palm-direction*palm_offset.length()
		_chain("arm",suffix,start,wrist,lengths.x,lengths.y,pole)
		_pose("Wrist"+suffix,joint_point("Wrist"+suffix),Basis(Quaternion(palm_offset.normalized(),direction)))

func _chain(prefix: String,suffix: String,start: Vector3,target: Vector3,upper: float,lower: float,pole: Vector3,terminal_basis: Basis=Basis.IDENTITY) -> void:
	# Never translate the terminal beyond anatomical reach. Contact tests still
	# reject an unreachable grip; free hanging hands may use their natural reach.
	var offset: Vector3=target-start
	var length: float=clampf(offset.length(),absf(upper-lower)+.0001,upper+lower-.0001)
	target=start+offset.normalized()*length
	var mid: Vector3=solve_joint(start,target,upper,lower,pole)
	var first: String=("Shoulder" if prefix=="arm" else "Hip")+suffix
	var second: String=("Elbow" if prefix=="arm" else "Knee")+suffix
	var last: String=("Wrist" if prefix=="arm" else "Foot")+suffix
	var upper_basis:=Basis(Quaternion((rests[second]-rests[first]).normalized(),(mid-start).normalized()))
	var lower_basis:=Basis(Quaternion((rests[last]-rests[second]).normalized(),(target-mid).normalized()))
	_pose(first,start,upper_basis)
	_pose(second,mid,lower_basis)
	_pose(last,target,lower_basis if prefix=="arm" else terminal_basis)

func chain_lengths(prefix: String,suffix: String) -> Vector2:
	var first: String=("Shoulder" if prefix=="arm" else "Hip")+suffix
	var second: String=("Elbow" if prefix=="arm" else "Knee")+suffix
	var last: String=("Wrist" if prefix=="arm" else "Foot")+suffix
	return Vector2(rests[first].distance_to(rests[second]),rests[second].distance_to(rests[last]))

func _pose_girdle(torso: Vector3,hips: Vector3,torso_basis: Basis) -> void:
	# Optional humanoid-profile body bones preserve shoulder-blade cloth volume.
	# All positions derive from this mesh's measured rest pose, not chest constants.
	if bone_ids.has("Spine"):
		var fraction: float=(rests.Spine-rests.Hips).length()/(rests.Torso-rests.Hips).length()
		_pose("Spine",hips.lerp(torso,fraction),Basis.IDENTITY.slerp(torso_basis,fraction))
	_pose("Torso",torso,torso_basis)
	if bone_ids.has("Neck"):_pose("Neck",torso+torso_basis*(rests.Neck-rests.Torso),torso_basis)
	for suffix: String in ["L","R"]:
		var name: String="Clavicle"+suffix
		if bone_ids.has(name):_pose(name,torso+torso_basis*(rests[name]-rests.Torso),torso_basis)

func apply_ride(contacts: Dictionary,phase: float,steer: float,reduced: bool=false) -> void:
	var bob: float=0 if reduced else -absf(sin(phase))*.012
	var sway: float=0 if reduced else sin(phase)*.012
	var hips:=Vector3(sway,1.64+bob,.24)
	if contacts.has("seat"):hips=contacts.seat-Vector3(0,-.10,.10)*rig_scale+Vector3(sway,bob,0)
	var torso_basis:=Basis(Vector3.RIGHT,-.62)
	# Preserve the imported hip-to-chest length while leaning toward the bars.
	var body_length: float=(rests.Torso-rests.Hips).length()
	var body_rise: float=minf(.30*rig_scale,body_length*.75)
	var torso:=hips+Vector3(-steer*.04,body_rise,-sqrt(maxf(0,body_length*body_length-body_rise*body_rise)))
	_pose("Hips",hips,Basis(Vector3.FORWARD,sway*.7))
	_pose_girdle(torso,hips,torso_basis)
	_pose("Head",torso+torso_basis*(rests.Head-rests.Torso),Basis(Vector3.UP,-steer*.22))
	for side: int in [-1,1]:
		var suffix: String="L" if side<0 else "R"
		# The imported shoulder girdle is part of this mesh's anatomy. Lowering
		# every shoulder to a generic chest offset collapses the upper-back skin.
		var shoulder: Vector3=torso+torso_basis*(rests["Shoulder"+suffix]-rests.Torso)
		var hip: Vector3=hips+(rests["Hip"+suffix]-rests.Hips)
		var hand: Vector3=contacts["leftGrip" if side<0 else "rightGrip"]
		var pedal: Vector3=contacts["leftPedal" if side<0 else "rightPedal"]
		var legs: Vector2=chain_lengths("leg",suffix)
		_arm_contact(suffix,shoulder,hand,Vector3(side*.55,-.3,.4))
		var sole_offset: Vector3=(Vector3(0,-.13,-.10) if generated_asset else Vector3(0,-.10,0))*rig_scale
		_chain("leg",suffix,hip,pedal-sole_offset,legs.x,legs.y,Vector3(side*.14,.15,-1))
		# Inspect the actual Skeleton3D pose, not a copy of requested targets.
		contact_error["hand"+suffix]=surface_contact("hand",suffix).distance_to(hand)
		contact_error["foot"+suffix]=surface_contact("foot",suffix).distance_to(pedal)

func _walk_sample(phase: float) -> Dictionary:
	var at: float=fposmod(phase,1)*float(walk_asset.frames)
	var i: int=int(at);var n: int=mini(i+1,int(walk_asset.frames));var weight: float=at-i
	var sample: Dictionary={}
	for name: String in walk_asset.mapping:
		var a: Dictionary=walk_asset.samples[i][name];var b: Dictionary=walk_asset.samples[n][name]
		var rest: Dictionary=walk_asset.rest[name]
		sample[name]=Vector3(a.p[0],a.p[1],a.p[2]).lerp(Vector3(b.p[0],b.p[1],b.p[2]),weight)
		var qa:=Quaternion(a.q[0],a.q[1],a.q[2],a.q[3]);var qb:=Quaternion(b.q[0],b.q[1],b.q[2],b.q[3]);var qr:=Quaternion(rest.q[0],rest.q[1],rest.q[2],rest.q[3])
		sample[name+"Basis"]=Basis(qa.slerp(qb,weight)*qr.inverse())
	return sample

func _hip_driven_swing(suffix: String,hip: Vector3,pelvis: Basis,swing: Dictionary,foot_basis: Basis,sole_offset: Vector3) -> void:
	var lengths: Vector2=chain_lengths("leg",suffix)
	var phase: float=swing.progress
	# Contacts define only the two ends. The middle is hip extension/abduction
	# with positive knee flexion; the ankle follows the FK chain, never pulls it.
	var from_ankle: Vector3=swing.from-foot_basis*sole_offset
	var to_ankle: Vector3=swing.to-foot_basis*sole_offset
	var pole: Vector3=pelvis*Vector3(.35,.02,-1)
	var first_knee: Vector3=solve_joint(hip,from_ankle,lengths.x,lengths.y,pole)
	var last_knee: Vector3=solve_joint(hip,to_ankle,lengths.x,lengths.y,pole)
	var first_dir: Vector3=(first_knee-hip).normalized()
	var last_dir: Vector3=(last_knee-hip).normalized()
	var first_flex: float=acos(clampf(first_dir.dot((from_ankle-first_knee).normalized()),-1,1))
	var last_flex: float=acos(clampf(last_dir.dot((to_ankle-last_knee).normalized()),-1,1))
	var first_lower: Vector3=(from_ankle-first_knee).normalized()
	var last_lower: Vector3=(to_ankle-last_knee).normalized()
	var first_hinge: Vector3=-first_dir.cross(first_lower).normalized()
	var last_hinge: Vector3=-last_dir.cross(last_lower).normalized()
	var first_basis:=Basis(first_hinge,-first_dir,first_hinge.cross(-first_dir)).orthonormalized()
	var last_basis:=Basis(last_hinge,-last_dir,last_hinge.cross(-last_dir)).orthonormalized()
	var middle_basis: Basis=pelvis*Basis(Vector3.BACK,.22)*Basis(Vector3.RIGHT,-1.46)
	var half: float=phase*2 if phase<.5 else (phase-.5)*2
	var upper_basis: Basis=first_basis.slerp(middle_basis,half) if phase<.5 else middle_basis.slerp(last_basis,half)
	var flex: float=lerpf(first_flex,swing_middle_flex,half) if phase<.5 else lerpf(swing_middle_flex,last_flex,half)
	var upper_dir: Vector3=upper_basis*Vector3.DOWN
	var lower_dir: Vector3=upper_basis*Basis(Vector3.RIGHT,-flex)*Vector3.DOWN
	var knee: Vector3=hip+upper_dir*lengths.x
	var ankle: Vector3=knee+lower_dir*lengths.y
	_pose("Hip"+suffix,hip,Basis(Quaternion((rests["Knee"+suffix]-rests["Hip"+suffix]).normalized(),upper_dir)))
	_pose("Knee"+suffix,knee,Basis(Quaternion((rests["Foot"+suffix]-rests["Knee"+suffix]).normalized(),lower_dir)))
	_pose("Foot"+suffix,ankle,foot_basis)

func apply_transition(joints: Dictionary) -> void:
	var hips: Vector3=joints.Hips
	var yaw: float=float(joints.get("body_yaw",0))
	var facing:=Basis(Vector3.UP,yaw)
	var walk: Dictionary=_walk_sample(float(joints.walk_phase)) if joints.has("walk_phase") else {}
	var walk_weight: float=float(joints.get("walk_weight",0))
	var sole_offset: Vector3=(Vector3(0,-.13,-.10) if generated_asset else Vector3(0,-.10,0))*rig_scale
	var blend: float=float(joints.get("ride_blend",0))
	var seat_hips: Vector3=joints.get("seat",hips)-Vector3(0,-.10,.10)*rig_scale
	hips.x=lerpf(hips.x,seat_hips.x,blend);hips.z=lerpf(hips.z,seat_hips.z,blend)
	# Pelvis is the motion master. Never solve its height backwards from feet.
	var neutral_height: float=rests.Hips.y-rests.FootL.y-sole_offset.y-.045+float(joints.get("neutral_pelvis_offset",0))
	var seating: float=float(joints.get("pelvis_seat_blend",blend))
	hips.y=lerpf(neutral_height,seat_hips.y,seating)
	var body_blend: float=float(joints.get("body_blend",blend))
	if not walk.is_empty():
		var source_leg: float=walk.HipL.distance_to(walk.KneeL)+walk.KneeL.distance_to(walk.FootL)
		var lengths: Vector2=chain_lengths("leg","L")
		var hip_bob: float=(walk.Hips.y-float(walk_asset.hipMeanY))*(lengths.x+lengths.y)/source_leg*.5
		hips.y=lerpf(hips.y,neutral_height-.102+hip_bob,walk_weight)
	var body_length: float=(rests.Torso-rests.Hips).length()
	var body_rise: float=minf(.30*rig_scale,body_length*.75)
	var ride_axis:=Vector3(float(joints.get("body_side_lean",0)),body_rise,-sqrt(maxf(0,body_length*body_length-body_rise*body_rise))).normalized()
	var authored_axis: Vector3=(joints.Torso-joints.Hips).normalized()
	if not walk.is_empty():
		var rt: Array=walk_asset.rest.Torso.p;var rh: Array=walk_asset.rest.Hips.p
		var source_axis: Vector3=(Vector3(rt[0],rt[1],rt[2])-Vector3(rh[0],rh[1],rh[2])).normalized()
		var walk_axis: Vector3=(Vector3.UP+(walk.Torso-walk.Hips).normalized()-source_axis+Vector3(0,0,-.07)).normalized()
		authored_axis=authored_axis.lerp(facing*walk_axis,walk_weight).normalized()
	var torso: Vector3=hips+authored_axis.lerp(ride_axis,body_blend).normalized()*body_length
	var torso_basis: Basis=facing*Basis(Vector3.RIGHT,-.62*body_blend)
	var pelvis_basis: Basis=facing*Basis(Vector3.UP,float(joints.get("pelvis_turn",0)))
	if not walk.is_empty():
		torso_basis=torso_basis.slerp(facing*Basis(Vector3.RIGHT,-.07)*walk.TorsoBasis,walk_weight)
		pelvis_basis=pelvis_basis*Basis.IDENTITY.slerp(walk.HipsBasis,walk_weight)
	_pose("Hips",hips,pelvis_basis)
	_pose_girdle(torso,hips,torso_basis)
	_pose("Head",torso+torso_basis*(rests.Head-rests.Torso),facing)
	for side: int in [-1,1]:
		var suffix: String="L" if side<0 else "R"
		var shoulder: Vector3=torso+torso_basis*(rests["Shoulder"+suffix]-rests.Torso)
		var legs: Vector2=chain_lengths("leg",suffix)
		var arm_pole: Vector3=facing*Vector3(side*.55,-.3,.4)
		var hand: Vector3=joints["hand"+suffix]
		if joints.has("free_arm"+suffix):
			var arm: Vector2=chain_lengths("arm",suffix)
			hand=shoulder+facing*Vector3(side*.10,-(arm.x+arm.y)*.91,0)
			if not walk.is_empty():
				var upper: Vector3=(walk["Elbow"+suffix]-walk["Shoulder"+suffix]).normalized()
				var lower: Vector3=(walk["Wrist"+suffix]-walk["Elbow"+suffix]).normalized()
				var wrist: Vector3=shoulder+facing*(upper*arm.x+lower*arm.y)
				var palm_offset:=Vector3(-.03 if side<0 else .03,-.11,0)*rig_scale
				hand=hand.lerp(wrist+facing*walk["Wrist"+suffix+"Basis"]*palm_offset,walk_weight)
				arm_pole=facing*(upper*.7+Vector3(side*.1,0,0))
			if joints.has("arm_reach"):hand=hand.lerp(joints["hand"+suffix],float(joints.arm_reach))
			if joints.has("hand_blend"+suffix):hand=hand.lerp(joints["hand"+suffix],float(joints["hand_blend"+suffix]))
		if joints.get("hand_constraints",{}).has(suffix):hand=joints.hand_constraints[suffix]
		_arm_contact(suffix,shoulder,hand,arm_pole)
		var foot_basis: Basis=Basis(Vector3.UP,float(joints.get("foot_yaw"+suffix,0)))*Basis(Vector3.RIGHT,float(joints.get("foot_pitch"+suffix,0)))
		var hip_joint: Vector3=hips+pelvis_basis*(rests["Hip"+suffix]-rests.Hips)
		if joints.has("leg_swing"+suffix) and joints["leg_swing"+suffix].progress>0 and joints["leg_swing"+suffix].progress<1:
			_hip_driven_swing(suffix,hip_joint,pelvis_basis,joints["leg_swing"+suffix],foot_basis,sole_offset)
		else:_chain("leg",suffix,hip_joint,joints["foot"+suffix]-foot_basis*sole_offset,legs.x,legs.y,facing*joints.get("leg_pole"+suffix,Vector3(side*.14,.15,-1)),foot_basis)
