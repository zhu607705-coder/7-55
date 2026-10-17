extends SceneTree
## Native-node contract, articulation, painter order and world lifecycle regression.
const Rig=preload("res://scenes/objects/kayak_rig.tscn")
const Pose=preload("res://scripts/ui/kayak_visual.gd")
const Kayak=preload("res://scripts/games/kayak_model.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("KAYAK NATIVE RIG: "+label)
func near(a: Vector2,b: Vector2) -> bool:return a.distance_to(b)<.0002
func run() -> void:
	var state: Node=root.get_node("State");state.developer_mode=true
	var rig: Node2D=Rig.instantiate();root.add_child(rig)
	var body: Node2D=rig.get_node("BodyRoll")
	check(rig.scene_file_path=="res://scenes/objects/kayak_rig.tscn","rig is an editor-openable packed scene")
	check(body.get_node("Hull") is Sprite2D and body.get_node("SeatedPlayer") is Sprite2D,"source hull and seated player are independent sprites")
	check(body.get_node("Hull").texture.get_size()==Vector2(128,160) and body.get_node("SeatedPlayer").texture.get_size()==Vector2(128,160),"source sprite dimensions retained")
	check(body.get_node("Hull").get_index()<body.get_node("SeatedPlayer").get_index(),"seated player occludes hull")
	var count: int=rig.find_children("*","",true,false).size()
	for side: String in ["left","right"]:
		var title: String=side.capitalize()
		var paddle: Node2D=body.get_node(title+"Paddle")
		var arm: Node2D=body.get_node(title+"Arm")
		check(not paddle.scene_file_path.is_empty() and not arm.scene_file_path.is_empty(),"paddle and arm are independent reusable scenes")
		check(paddle.get_node("Grip") is Marker2D and paddle.get_node("BladePivot") is Node2D,"grip and blade are addressable pivots")
		check(arm.get_node("ShoulderPivot/ElbowPivot") is Node2D,"shoulder and elbow are addressable pivots")
		check(arm.get_index()>paddle.get_index(),"hand paints above its paddle")
		check(near(rig.hand_grip(side).global_position,rig.paddle_grip(side).global_position),"authored editor rest pose grips its paddle")
	for reverse: bool in [false,true]:
		for roll: float in [-.8,0,.8]:
			for age: float in [0,30,120,240,370,430,495,590,679,700]:
				var pose: Dictionary={"heading":.73,"roll":roll,"speed":-100 if reverse else 160,"tick":age*.12,"strokeEvents":[{"side":"left","tick":0,"direction":"reverse" if reverse else "forward"},{"side":"right","tick":0,"direction":"reverse" if reverse else "forward"}]}
				rig.configure_view(Vector2(310,180),1.3,pose)
				check(near(rig.scale,Vector2.ONE*.52*1.3),"one uniform source-to-world scale")
				for side: String in ["left","right"]:
					var title: String=side.capitalize()
					var sample:=Pose.stroke_pose(side,age,reverse,roll)
					var paddle: Node2D=body.get_node(title+"Paddle")
					var arm: Node2D=body.get_node(title+"Arm")
					check(near(rig.hand_grip(side).global_position,rig.paddle_grip(side).global_position),"transformed hand stays exactly on grip")
					check(near(paddle.get_node("BladePivot").global_position,body.to_global(sample.tip)),"blade follows unchanged stroke trajectory")
					check(near(arm.get_node("ShoulderPivot/ElbowPivot").global_position,body.to_global(sample.elbow)),"native elbow follows sampled articulation")
					var shaft: Line2D=paddle.get_node("Shaft")
					check(near(paddle.to_global(shaft.points[1]),body.to_global(sample.shaft_mid)),"native shaft retains original willow flex / sign rigidity")
					check(paddle.get_node("WaterContact/Ripple").visible==(float(sample.wet)>.01),"water contact belongs to the moving blade")
	check(rig.find_children("*","",true,false).size()==count,"pose updates reuse nodes rather than spawning per frame")
	var model:=Kayak.new();model.configure({"phase":"world","bounded":false});model.stroke("left");model.update(.2);model.stroke("right",true)
	var before: String=JSON.stringify(model.result())
	rig.configure_view(Vector2.ZERO,1,{"strokeEvents":model.inputs,"tick":model.tick,"roll":model.roll})
	check(body.get_node("LeftPaddle").phase=="pull" and body.get_node("RightPaddle").phase=="entry","opposite input cannot rewind the active paddle")
	check(not body.get_node("LeftPaddle").reverse and body.get_node("RightPaddle").reverse,"directions remain independent")
	check(JSON.stringify(model.result())==before,"rig never mutates authoritative physics")
	var right_transform: Transform2D=body.get_node("RightPaddle").transform
	body.get_node("LeftPaddle").hide()
	check(body.get_node("RightPaddle").visible and body.get_node("RightPaddle").transform==right_transform,"one paddle can be independently hidden without changing the other")
	body.get_node("LeftPaddle").show()
	for speed: float in [0,360,-230]:
		rig.apply_pose({"speed":speed})
		check((rig.get_node("Wake/SternOuter").modulate.a>0)==(speed>0),"original stern wake uses forward speed")
		check((rig.get_node("Wake/BowOuter").modulate.a>0)==(speed<0),"original bow wake uses reverse speed")
	check(rig.get_node("Wake").get_index()<body.get_index(),"wake remains behind the hull")
	rig.configure_view(Vector2(20,40),.8,{"bodyAngle":-82,"bodyY":-22,"bodyScale":Vector2(.76,.68),"bodyAlpha":.14,"alpha":.8})
	check(is_equal_approx(body.rotation,deg_to_rad(-82)) and body.position==Vector2(0,-22) and body.scale==Vector2(.76,.68),"rain capsize transforms stay on the body pivot")
	check(is_equal_approx(body.modulate.a,.14) and is_equal_approx(rig.modulate.a,.8),"body alpha and overall alpha remain independent")
	check(near(rig.hand_grip("left").global_position,rig.paddle_grip("left").global_position),"grip survives the rain capsize transform")
	rig.free()
	state.d=state.initial()
	state.d.native.merge({"chapter":3,"scene":"qizhen_lake","page":"c3_lake","mode":"light","positions":{}},true)
	state.d.runtimeMode="rpg";state.d.rpgScene="qizhen_lake"
	state.d.qizhenLake.merge({"active":true,"phase":"tool_chain","zone":"open_water","vehicle":"kayak","boardingTutorialCompleted":true,"rainSafetyCleared":true,"kayakEquipped":true,"leftPaddleEquipped":true,"rightPaddleEquipped":true},true)
	var world: Control=load("res://scripts/world.gd").new();world.size=Vector2(960,540);root.add_child(world);world.set_process(false)
	var adapter: Node2D=world.kayak_visual
	adapter.sync();adapter.configure_view(Vector2(50,60),.7)
	check(adapter.active and is_instance_valid(adapter.rig),"world owns a live native kayak instance")
	check(adapter.before_pass.get_index()<adapter.rig.get_index() and adapter.rig.get_index()<adapter.after_pass.get_index(),"world front targets and HUD render after the whole rig")
	check(adapter.rig.find_children("*","CanvasItem",true,false).all(func(n):return n.z_index==0),"no child z-index escapes the ordered actor pass")
	check(near(adapter.rig.position,Vector2(50,60)+world.player*.7),"world camera transform reaches native root once")
	world.presentation_actor_hidden=true;adapter.sync()
	check(not adapter.rig.visible and adapter.visible,"rain presenter hides boat without losing world layers")
	world.presentation_actor_hidden=false;adapter.sync()
	check(adapter.rig.visible,"interrupted presentation restores native world boat")
	var retired: Node2D=adapter.rig
	world.scene_id="dorm_hub";adapter.sync()
	check(not adapter.active and adapter.rig==null and retired.is_queued_for_deletion(),"scene exit retires the native rig lifecycle")
	await process_frame
	check(not is_instance_valid(retired),"retired kayak and all owned objects are freed")
	world.scene_id="qizhen_lake";adapter.sync();adapter.configure_view(Vector2.ZERO,1)
	check(is_instance_valid(adapter.rig),"lake reentry creates a fresh native instance")
	world.kayak=null;adapter.sync()
	check(not adapter.active and adapter.rig==null,"disembarking removes the boat actor")
	world.free()
	print("KAYAK_NATIVE_RIG: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
