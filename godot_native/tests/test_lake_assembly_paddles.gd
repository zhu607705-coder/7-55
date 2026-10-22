extends SceneTree
const Motion=preload("res://scripts/presentation/lake_rod_assembly.gd")
const Visual=preload("res://scripts/ui/kayak_visual.gd")
const AssemblyView=preload("res://scripts/ui/lake_rod_assembly_view.gd")
const Kayak=preload("res://scripts/games/kayak_model.gd")
const Lake=preload("res://scripts/chapters/c3_lake.gd")
var checks:=0
var failures:=0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("LAKE ANIMATION: "+label)
func run() -> void:
	var state: Node=root.get_node("State");state.developer_mode=true
	var lake:=Lake.new()
	var s: Dictionary=state.initial()
	s.native.mode="light";s.qizhenLake.active=true;s.qizhenLake.phase="tool_chain"
	for id: String in lake.FINAL_PARTS:s.items[id]=true
	var before:=JSON.stringify(s)
	check(not lake.combine_items(s,["nylonCord","brokenNetFrame"]).has("world_effect"),"incomplete recipe cannot animate")
	check(JSON.stringify(s)==before,"refusal leaves state intact")
	var result:=lake.combine_items(s,lake.FINAL_PARTS)
	check(result.get("world_effect",{}).get("kind")=="lake_rod_assembly","only accepted controller requests assembly")
	check(s.items.magneticFishingRod and s.qizhenLake.magneticRodCombined,"result exists before animation starts")
	check(lake.FINAL_PARTS.all(func(id):return not s.items[id]),"four parts consumed exactly once")
	check(not s.items.get("improvisedDipNet",false) and not s.items.get("sealedFeedTin",false) and not s.items.get("smallCarp",false),"no retired prerequisites introduced")
	before=JSON.stringify(s)
	check(not lake.combine_items(s,lake.FINAL_PARTS).has("world_effect") and JSON.stringify(s)==before,"duplicate transaction cannot reanimate or reward")
	var loaded: Dictionary=JSON.parse_string(before)
	check(loaded.items.magneticFishingRod and not lake.can_assemble(loaded),"reload settles to committed rod")
	for ms: float in [0,250,1900,2000,2500,3300,3700,4380,4730,5280,6100,6600,7200]:
		var p:=Motion.sample(ms)
		if ms>=2000:check(Vector3(p.frame_socket).is_equal_approx(p.rod_tip),"frame socket meets rod tip "+str(ms))
		if ms>=4850:check(Vector3(p.clasp).is_equal_approx(Vector3(p.frame)+Motion.CLASP_LOCAL),"clasp stops at frame rim "+str(ms))
		check(float(p.wrap)>=0 and float(p.wrap)<=1,"bounded rope wrap")
	check(Motion.sample(2600).wrap>0 and Motion.sample(2600).wrap<1,"rope actually winds before tightening")
	check(Motion.sample(5520).tug!=0 and Motion.sample(6350).tug==0,"tug deflects then settles")
	check(Motion.sample(6800).stow>0 and Motion.sample(7200).done,"stow reaches terminal presentation")
	var view:=AssemblyView.new();root.add_child(view);view.setup({"read_state":func():return s});view.set_process(false)
	var events: Array=[];view.event.connect(func(a,_v):events.append(a))
	view.cancel();await process_frame
	check(events.is_empty() and JSON.stringify(s)==before,"cancel emits no controller action and preserves committed result")
	view=AssemblyView.new();root.add_child(view);view.setup({"read_state":func():return s});view.set_process(false);view.elapsed_ms=Motion.DURATION_MS;view._process(.01);await process_frame
	check(JSON.stringify(s)==before,"completion does not write state")
	for side: String in ["left","right"]:
		for reverse: bool in [false,true]:
			for sample: Array in [[30.0,"entry"],[240.0,"pull"],[430.0,"exit"],[590.0,"recovery"],[700.0,"rest"]]:
				var p:=Visual.stroke_pose(side,sample[0],reverse)
				check(p.phase==sample[1],"independent stroke key phase")
				check(Vector2(p.grip).distance_to(p.tip)>50,"paddle length and contact retained")
			var early:=Visual.stroke_pose(side,140,reverse);var late:=Visual.stroke_pose(side,370,reverse)
			check(absf(float(late.tip.y)-float(early.tip.y))>70,"real fore/aft sweep, not texture stretching")
			check((late.tip.y>early.tip.y)!=reverse,"reverse sweep direction")
	check(Visual.stroke_pose("left",240).bend>3 and Visual.stroke_pose("right",240).bend==0,"willow flexes while sign remains rigid")
	var a:=Kayak.new();a.configure({"phase":"world","bounded":false});a.stroke("left");a.update(.2);a.stroke("right",true)
	var model_before:=JSON.stringify(a.result());var speed:=a.speed;var roll:=a.roll;var heading:=a.heading
	var p:=Visual.paddle_poses({"strokeEvents":a.inputs,"tick":a.tick,"roll":a.roll})
	check(p.left.phase=="pull" and p.right.phase=="entry","new opposite input does not reset the other paddle")
	check(not p.left.reverse and p.right.reverse,"each side keeps its own travel direction")
	check(JSON.stringify(a.result())==model_before and a.speed==speed and a.roll==roll and a.heading==heading,"render samples cannot change model physics")
	var idle:=Visual.paddle_poses({"strokeEvents":[],"tick":0})
	check(idle.left.phase=="rest" and idle.right.phase=="rest","new/reloaded session has no ghost strokes")
	check(Visual.stroke_pose("left",240,false,.8).elbow!=Visual.stroke_pose("left",240,false,0).elbow,"imbalance has a local arm reaction")
	var hull: Texture2D=load("res://assets/native/kayak/hull.svg");var player: Texture2D=load("res://assets/native/kayak/seated_player.svg");check(hull.get_width()==128 and player.get_height()==160,"original uniform source bounds retained")
	print("LAKE_ASSEMBLY_PADDLES: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
