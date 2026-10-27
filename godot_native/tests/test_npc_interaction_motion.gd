extends SceneTree
const Motion=preload("res://scripts/presentation/npc_interaction_motion.gd")
const Phases=preload("res://scripts/ui/chapter4_phase_layers.gd")
const Picker=preload("res://scripts/world_object_picker.gd")
const Metrics=preload("res://scripts/player_metrics.gd")
var checks:=0
var failures:=0

func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("NPC_INTERACTION: "+label)

func run()->void:
	create_timer(20).timeout.connect(func():push_error("NPC_INTERACTION: watchdog");quit(2))
	var motion:RefCounted=Motion.new()
	check(motion.sample("teacher",0,false,false).phase=="idle","distant actor is idle")
	check(motion.sample("teacher",100,true,false).phase=="attention","approaching actor acknowledges visitor")
	check(absf(motion.sample("teacher",270,true,false).angle_degrees)>1,"approach has a bounded greeting gesture")
	motion.respond("teacher",300,3000)
	check(motion.sample("teacher",480,true,false).phase=="speaking","accepted interaction starts response")
	check(absf(motion.sample("teacher",480,true,false).angle_degrees)<=2,"response stays within a two-degree fixed-foot gesture")
	check(motion.sample("teacher",3050,true,false).phase=="settling","response settles before ending")
	check(motion.sample("teacher",3300,false,false).phase=="idle" and motion.responses.is_empty(),"response expires and returns to idle")
	motion.respond("teacher",3400,3000)
	var reduced:Dictionary=motion.sample("teacher",3580,true,true)
	check(reduced.phase=="speaking" and reduced.angle_degrees==0 and reduced.frame==0,"reduced motion keeps interaction without animation")
	motion.reset()
	check(motion.responses.is_empty() and motion.attention.is_empty(),"scene retirement clears all transient state")

	var state:Node=root.get_node("State");state.developer_mode=true
	state.begin_checkpoint("c4-755-room204-1850")
	var phases:RefCounted=Phases.new();phases.tick(0,state.d)
	var teacher:Dictionary=phases.support_people(state.d)[0]
	var snapshot:Dictionary=state.d.duplicate(true)
	check(not phases.support_interacted(state.d,teacher.npcId,"c4_reference_teacher",{}),"unhandled action cannot animate a response")
	check(not phases.support_interacted(state.d,teacher.npcId,"c4_reference",{"handled":true,"message":"test"}),"observation cannot impersonate an NPC reply")
	check(not phases.support_interacted(state.d,"a1_front_desk_attendant","c4_front_desk",{"handled":true,"message":"test"}),"absent NPC cannot respond")
	check(phases.support_interacted(state.d,teacher.npcId,"c4_reference_teacher",{"handled":true,"message":"test"}),"active original teacher accepts presentation feedback")
	phases.tick(.05,state.d)
	var pose:Dictionary=phases.support_pose(teacher,{"nearby_id":teacher.npcId})
	check(pose.phase=="speaking" and pose.animation==teacher.animation,"response uses original staff artwork")
	check(state.d==snapshot,"presentation never writes saved state or progression")
	var texture:Texture2D=load("res://assets/rpg/npcs/library/front_desk_staff_2frame.png")
	var geometry:Dictionary=phases.support_geometry(teacher,pose,texture)
	var pivot:=Vector2(teacher.position.x,teacher.position.y)
	check(geometry.transform*Vector2.ZERO==pivot,"render and picker retain authored foot pivot")
	check(is_equal_approx(geometry.transform.x.length(),float(teacher.uniformScale)) and is_equal_approx(geometry.transform.y.length(),float(teacher.uniformScale)),"gesture keeps original uniform proportions")
	var picker:RefCounted=Picker.new();var source:Rect2=geometry.source
	var pixels:Image=texture.get_image()
	if pixels.is_compressed():pixels.decompress()
	var hit:=false
	for y in range(12,116,4):
		for x in range(12,84,4):
			if pixels.get_pixel(int(source.position.x)+x,int(source.position.y)+y).a>.1:
				var point:Vector2=geometry.transform*(geometry.rect.position+Vector2(x+.5,y+.5))
				hit=picker.contains(geometry,point);break
		if hit:break
	check(hit,"pixel picking follows actual rotating sprite")
	check(not picker.contains(geometry,geometry.transform*(geometry.rect.position+Vector2(.5,.5))),"transparent sprite corners do not steal clicks")
	state.d.native.settings.reduced_motion=true;phases.tick(.05,state.d)
	pose=phases.support_pose(teacher,{"nearby_id":teacher.npcId})
	check(pose.angle_degrees==0 and pose.frame==0,"formal settings disable NPC motion")
	state.d=state.d.duplicate(true);phases.tick(0,state.d)
	check(phases.npc_interaction_motion.responses.is_empty(),"ordinary load retires prior response")

	# Exercise the real world/controller path, including distance rejection.
	state.begin_checkpoint("c4-755-room204-1850")
	var world:Control=load("res://scripts/world.gd").new();world.size=Vector2(960,540);root.add_child(world);world.set_process(false)
	world.chapter4_layers.phases.tick(0,state.d)
	var teacher_targets:Array=world.targets.filter(func(target):return str(target.id)=="a3_reference_teacher")
	check(teacher_targets.size()==1,"formal scene owns one actual teacher interaction")
	if teacher_targets.size()==1:
		var target:Dictionary=teacher_targets[0]
		var point:=Vector2(target.position[0],target.position[1])
		world.player=Vector2(200,700);world._try_interact(target)
		check(world.chapter4_layers.phases.npc_interaction_motion.responses.is_empty(),"too-far attempt cannot start conversation animation")
		world.player=point-Metrics.FOOT_CENTER_OFFSET+Vector2(0,35)
		var chapter_before:Dictionary=state.d.chapter4.duplicate(true)
		world._try_interact(target)
		check(world.chapter4_layers.phases.npc_interaction_motion.responses.has("a3_reference_teacher"),"actual successful NPC action reaches animation")
		check(state.d.chapter4==chapter_before,"teacher reply cannot award observation or bypass stairs")
		var phases_before:RefCounted=world.chapter4_layers.phases
		state.d.chapter4.floor="A2";phases_before.tick(0,state.d)
		check(phases_before.npc_interaction_motion.responses.is_empty(),"floor handoff clears retired NPC response")
	world.queue_free();await process_frame
	print("NPC_INTERACTION: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
