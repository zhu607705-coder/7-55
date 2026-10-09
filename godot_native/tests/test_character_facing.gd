extends SceneTree
const Facing=preload("res://scripts/character_facing.gd")
const Metrics=preload("res://scripts/player_metrics.gd")
const Phases=preload("res://scripts/ui/chapter4_phase_layers.gd")
const Layers=preload("res://scripts/ui/chapter4_world_layers.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("CHARACTER_FACING: "+label)
func run()->void:
	var state:Node=root.get_node("State")
	state.developer_mode=true;state.d=state.initial()
	state.d.native.scene="library_interior";state.d.actOne.controlsInstalled=true;state.d.actOne.movementEnabled=true
	var world=load("res://scripts/world.gd").new();world.size=Vector2(960,540);root.add_child(world);world.set_process(false)
	world.chapter3_layers=null;world.library_layers=null;world.chapter4_layers=null
	world.collisions=[];world.mask=PackedByteArray();world.targets=[];world.player=Vector2(500,500)
	var rows:Array=[{"axis":Vector2.LEFT,"facing":"side","flip":true,"path":"player_side"},{"axis":Vector2.RIGHT,"facing":"side","flip":false,"path":"player_side"},{"axis":Vector2.UP,"facing":"up","flip":false,"path":"player_up"},{"axis":Vector2.DOWN,"facing":"down","flip":false,"path":"player_down"}]
	for row:Dictionary in rows:
		var old:Vector2=world.player
		world.touch_axis=row.axis;world._process(.05)
		check(world.player.distance_to(old+row.axis*165*.05)<.001,"actual movement follows "+str(row.axis))
		check(world.facing==row.facing,"actual movement selects "+row.facing)
		for tick in 4:world._process(.05)
		var visual:Dictionary=world.player_visual()
		check(visual.texture.resource_path.contains(row.path),"movement uses actual direction pixels "+row.path)
		check(visual.flip_h==row.flip,"only real side art is mirrored for left")
		for i in 18:world._process(.05)
		check(world.walk_clock>0,"walk cycle runs while moving")
		world.touch_axis=Vector2.ZERO;world._process(.05)
		check(world.facing==row.facing and world.walk_clock==0,"stop retains facing with idle frame")
		check(world.player_visual().flip_h==row.flip,"stop retains side handedness")
		var stopped:Vector2=world.player;var rect:Rect2=Metrics.foot_rect(stopped)
		var texture:Texture2D=world.player_visual().texture
		world.zoom=.45;world.pan_offset=Vector2(120,-30);world._update_camera()
		world.zoom=1.6;world.pan_offset=Vector2(-80,40);world._update_camera()
		check(world.player==stopped and Metrics.foot_rect(world.player)==rect and world.player_visual().texture==texture,"2D pan/zoom keeps heading and physical feet")
	# Actual axis collision code: x blocked, y moves. Face the resulting slide.
	world.player=Vector2(500,500);world.facing="side";world.player_flip=false
	world.collisions=[{"x":510,"y":350,"width":50,"height":400}]
	world.touch_axis=Vector2(1,-.4);world._process(.05)
	check(world.player.x==500 and world.player.y<500,"actual wall rejects horizontal component and slides vertically")
	check(world.facing=="up","slide uses actual up displacement rather than stronger right intent")
	world.touch_axis=Vector2.RIGHT;var blocked:Vector2=world.player;world._process(.05)
	check(world.player==blocked and world.facing=="side" and not world.player_flip,"wall contact turns in place toward intent")
	for tick in 4:world._process(.05)
	check(world.walk_clock==0 and world.player_visual().texture==world.player_side_idle,"blocked player stops the walk cycle")
	world.touch_axis=Vector2.ZERO;world._process(.05)
	check(world.facing=="side" and not world.player_flip,"release after wall contact holds heading")
	check(Facing.pose(Vector2.ZERO,Vector2.ZERO,"side",true)=={"facing":"side","flip":true},"idle preserves full heading")
	check(Facing.pose(Vector2.ZERO,Vector2(INF,0),"up",true).facing=="up","invalid input cannot change heading")
	check(Facing.pose(Vector2(1,-1),Vector2.ZERO,"side",false).facing=="side","exact diagonal retains horizontal axis")
	check(Facing.pose(Vector2(1,-1),Vector2.ZERO,"up",false).facing=="up","exact diagonal retains vertical axis")
	# Source turning uses complete original poses, with the same timings.
	for from:String in ["up","down","side"]:
		for to:String in ["up","down","side"]:
			if from==to:continue
			var duration:float=Facing.turn_duration(from,false,to,true)
			var turn:Dictionary={"from_facing":from,"from_flip":false,"to_facing":to,"to_flip":true,"elapsed_ms":0.0,"duration_ms":duration}
			check(Facing.turn_pose(turn).facing==from,"turn begins on original whole pose")
			turn.elapsed_ms=duration*.4
			check(Facing.turn_pose(turn).facing=="side" and absf(Facing.turn_pose(turn).angle)==6,"turn has source side transition and 6 degree tilt")
			turn.elapsed_ms=duration*.8
			check(Facing.turn_pose(turn).facing==to,"turn settles on target whole pose")
	check(Facing.turn_duration("side",false,"side",true)==150 and Facing.turn_duration("up",false,"down",false)==170 and Facing.turn_duration("up",false,"side",false)==132,"source 150/170/132 ms durations retained")
	var reversal:Dictionary={"from_facing":"side","from_flip":false,"to_facing":"side","to_flip":true,"elapsed_ms":75.0,"duration_ms":150.0}
	check(Facing.turn_pose(reversal).facing=="down","side reversal has original front transition")
	world.player_turn.clear();world.facing="up";world.player_flip=false
	world._apply_player_motion(Vector2.LEFT,Vector2.LEFT,.01);world._apply_player_motion(Vector2.ZERO,Vector2.ZERO,.06)
	check(world.facing=="side" and world.player_visual().direction=="side" and world.player_visual().angle==-6,"release during turn keeps its intermediate source pose")
	var original_foot:Rect2=Metrics.foot_rect(world.player)
	var geometry:Dictionary=world.player_geometry()
	check(geometry.transform*world.player==world.player and Metrics.foot_rect(world.player)==original_foot,"visual tilt pivots around anchor without moving foot collision")
	world._apply_player_motion(Vector2.ZERO,Vector2.ZERO,.1)
	check(world.player_turn.is_empty() and world.player_visual().flip_h and world.player_visual().angle==0,"released turn finishes on target left idle")
	# Auto-exercise uses the same real displacement and never changes manual gates.
	world.scene_id="dorm_hub";state.d.native.scene="dorm_hub";state.d.actOne.controlsInstalled=false;state.d.actOne.exerciseStarted=true
	world.collisions=[];world.player=Vector2(620,400);world._process(.05)
	check(world.facing=="side" and world.player_flip,"dorm automatic pacing faces left")
	world.player=Vector2(390,400);world._process(.05)
	check(world.facing=="side" and not world.player_flip,"dorm automatic pacing faces right")
	check(not state.d.actOne.manualControlTested,"automatic pacing never grants manual movement proof")
	# No partial left cycle may silently replace one or more directional frames.
	world.player_turn.clear();world.facing="side";world.player_flip=true;world.walk_clock=.12
	world.player_frames.left=[world.player_frames.up[0]]
	check(world.player_visual().direction=="side" and world.player_visual().flip_h,"incomplete left assets retain complete side fallback")
	world.player_frames.left=world.player_frames.up.duplicate();world.player_left_idle=world.player_frames.up[0]
	check(world.player_visual().direction=="left" and not world.player_visual().flip_h,"complete authored left cycle is selected without mirroring")
	world.walk_clock=0;check(world.player_visual().texture==world.player_left_idle,"authored left idle shares renderer selection")
	world.player_frames.left=[];world.player_left_idle=null
	# Guard rendering uses its real directional sheets and freezes when stopped.
	for row:Dictionary in rows:
		world._apply_guard_motion(row.axis,row.axis,.12)
		var pose:Dictionary=world.guard_visual()
		check(pose.direction==row.facing and pose.flip_h==row.flip,"guard motion selects heading "+str(row.axis))
		check(pose.texture==world.guard_sheets[row.facing],"guard chooses authored directional sheet")
		world._apply_guard_motion(Vector2.ZERO,Vector2.ZERO,.12)
		check(world.guard_visual().direction==row.facing and world.guard_walk_clock==0,"stationary guard retains heading without marching")
	# Nearby A2 guard turns toward the visitor with matching picker pixels.
	var phases:RefCounted=Phases.new();var guard:Dictionary=phases.source.supportNpcRuntimes[0]
	for row:Dictionary in rows:
		var p:Vector2=Vector2(guard.position.x,guard.position.y)+row.axis*50-Metrics.FOOT_CENTER_OFFSET
		var pose:Dictionary=phases.support_pose(guard,{"player":p,"nearby_id":guard.interactionAnchorId})
		check(pose.animation==("guard_walk" if row.facing=="side" else "guard_walk_"+row.facing) and pose.flip==row.flip and pose.time_ms==0,"conversing guard faces visitor "+str(row.axis))
	check(phases.support_pose(guard,{"player":Vector2.ZERO,"nearby_id":""}).animation==guard.animation,"distant guard retains authored watch action")
	# Bakery routes use actual left-facing student art, stop at endpoints, reverse.
	var layers:RefCounted=Layers.new();var route:Dictionary=layers.source.bakeryRuntime.crowd.routes[0]
	var duration:float=roundf(Vector2(route.from.x,route.from.y).distance_to(Vector2(route.to.x,route.to.y))/float(route.speed)*1000)
	layers.bakery_ms=duration*.5;var outward:Dictionary=layers._crowd_sample(route,0)
	layers.bakery_ms=duration+float(route.endpointPauseMs)-10;var resting:Dictionary=layers._crowd_sample(route,0)
	layers.bakery_ms=duration+float(route.endpointPauseMs)+duration*.5;var returning:Dictionary=layers._crowd_sample(route,0)
	check(outward.flip and not returning.flip,"true left-facing student art mirrors only for rightward leg")
	check(resting.animation=="student_idle" and resting.frame==0,"bakery endpoint pause no longer walks in place")
	# Original theater inspector front/back/left/right poses are all consumed.
	var c3:RefCounted=load("res://scripts/ui/chapter3_world_layers.gd").new()
	var inspector:=Vector2(753,665)
	for row:Dictionary in rows:
		var point:=inspector+Vector2(0,48)+Vector2(row.axis)*80-Metrics.FOOT_CENTER_OFFSET
		state.d.native.player={"x":point.x,"y":point.y,"world_x":point.x,"world_y":point.y}
		var file:String=c3.ticket_inspector_asset(state.d,inspector,false)
		var direction:String=("left" if row.flip else "right") if row.facing=="side" else "back" if row.facing=="up" else "front"
		check(file.ends_with("idle_"+direction+".png") and ResourceLoader.exists(file),"theater inspector uses original "+direction+" drawing")
		check(c3.ticket_inspector_asset(state.d,inspector,true)==c3.asset("ticketInspectorScanUrl"),"scanning action is preserved")
	# Canteen's separate renderer consumes the exact same selected texture/flip.
	state.d=state.initial();state.d.native.scene="canteen_interior";world.scene_id="";world.refresh_world()
	for row:Dictionary in rows:
		world._apply_player_motion(row.axis,row.axis,.1)
		world.native_canteen.configure_view(Vector2.ZERO,.85,world.player)
		var pose:Dictionary=world.player_visual()
		check(world.native_canteen.player_sprite.texture==pose.texture and world.native_canteen.player_sprite.flip_h==pose.flip_h,"native canteen matches shared direction "+str(row.axis))
	world.queue_free();await process_frame
	print("Character facing: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
