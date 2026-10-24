extends SceneTree
const Rig=preload("res://scripts/presentation/liangzhu_actor_rig.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("LIANGZHU_ACTOR_RIG: "+label)
func near(a:Vector2,b:Vector2)->bool:return a.distance_to(b)<.0001
func run()->void:
	var stage:=Node2D.new();stage.position=Vector2(33,17);stage.scale=Vector2(5,5);stage.rotation=.12;root.add_child(stage)
	var rig:=Rig.new();stage.add_child(rig)
	await process_frame
	check(rig.skeleton is Skeleton2D and rig.skeleton.get_bone_count()==15,"actual Skeleton2D registers fifteen articulated bones")
	check(rig.bones.RightWrist is Bone2D and rig.bones.RightWrist.get_parent()==rig.bones.RightElbow and rig.bones.RightElbow.get_parent()==rig.bones.RightShoulder,"fan wrist belongs to the shoulder/elbow bone chain")
	check(rig.sockets.FanSocket.get_parent()==rig.bones.RightWrist,"fan is attached to the actual right wrist")
	check(rig.bones.Head.get_parent()==rig.bones.Torso and rig.bones.LeftFoot.get_parent()==rig.bones.LeftKnee,"torso/head and hip/knee/foot hierarchy remains addressable")
	var count:int=rig.find_children("*","",true,false).size()
	var atlas:=Image.new();atlas.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/native/liangzhu_performance_20261021/actors.png"))
	check(not atlas.is_empty() and atlas.get_size()==Vector2i(480,320),"source atlas is the accepted four-by-two complete-cel image")
	var left_palm:Vector2=Rig.authored_joints(2,1).LeftWrist
	check(left_palm==Vector2(33,67) and atlas.get_pixel(240+33,160+67)==Color("D89C6A"),"new final-act left fan socket is on the visible raised palm, not the lower white sleeve")
	for row:int in 2:
		for frame:int in 4:
			var joints:Dictionary=Rig.authored_joints(frame,row)
			var wrist:Vector2=joints.RightWrist
			var sample:Color=atlas.get_pixel(frame*120+int(wrist.x),row*160+int(wrist.y))
			check(sample.a==1.0,"authored held-fan wrist lies on the actual visible cel %s/%s"%[row,frame])
			for flip:bool in [false,true]:
				var foot:=Vector2(106,102)
				check(rig.configure_pose(frame,row,foot,flip,370.0),"authored pose is accepted")
				var expected:Vector2=(wrist-Rig.NATIVE_FOOT)/Rig.PIXELS_PER_UNIT
				if flip:expected.x=-expected.x
				expected+=foot
				check(near(rig.attachment_local().origin,expected),"live wrist follows its authored pose and reflection about the foot")
				check(near(stage.to_local(rig.attachment_global_transform().origin),expected),"actual global transform includes parent scale and rotation exactly once")
				check(near(Rig.sample_socket(frame,row,foot,flip),expected),"historical FK sample and live bone chain agree")
				check(near(rig.attachment_local("FootAnchor").origin,foot),"all eight cels keep the same source foot anchor")
				for bone:Bone2D in rig.bones.values():
					check(absf(bone.rest.determinant())>.99 and near(bone.scale,Vector2.ONE),"invertible rest pose and no cel-stretch scale on any joint")
	check(rig.find_children("*","",true,false).size()==count,"per-frame posing reuses the persistent skeleton")
	rig.configure_pose(2,0,Vector2(72,106),false)
	var before:Vector2=rig.attachment_global_transform().origin
	var elbow:Bone2D=rig.bones.RightElbow
	elbow.rotation=.2
	check(before.distance_to(rig.attachment_global_transform().origin)>1.0,"a real ancestor rotation moves the held-fan socket")
	check(near(rig.attachment_global_transform().origin,rig.sockets.FanSocket.global_position),"public attachment reads the actual live node")
	check(near(stage.to_local(rig.attachment_global_transform().origin),rig.attachment_local().origin),"local attachment preserves a live ancestor change, not only the authored table")
	var fan:=Node2D.new();rig.sockets.FanSocket.add_child(fan)
	rig.configure_pose(2,1,Vector2(168,102),true,500)
	check(near(fan.global_position,rig.attachment_global_transform().origin),"a real held object follows pose, foot translation and flip")
	var grip:Vector2=rig.attachment_local().origin
	rig.set_secondary_sleeve_angle(90)
	check(is_equal_approx(rig.secondary_degrees,6.0) and is_equal_approx(rig.bones.LeftSleeveSecondary.rotation,deg_to_rad(6.0)),"secondary sleeve endpoint has an explicit six-degree local limit")
	check(near(grip,rig.attachment_local().origin),"sleeve secondary cannot pull the grip off its cel")
	rig.configure_pose(2,1,Vector2(168,102),true,1234,true)
	check(rig.secondary_degrees==0.0,"reduced motion disables secondary articulation")
	var unchanged:Dictionary=rig.geometry_snapshot()
	check(not rig.configure_pose(4,1,Vector2.ZERO,false) and not rig.configure_pose(0,2,Vector2.ZERO,false) and not rig.configure_pose(0,0,Vector2(NAN,0),false) and not rig.configure_pose(0,0,Vector2.ZERO,false,INF),"invalid pose data cannot enter the skeleton")
	check(rig.geometry_snapshot()==unchanged,"rejected poses preserve the previous valid articulation")
	check(not unchanged.weightedMesh and unchanged.kind=="cel+rig-hybrid","diagnostics state the actual cel/rig scope")
	stage.free()
	print("LIANGZHU_ACTOR_RIG: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
