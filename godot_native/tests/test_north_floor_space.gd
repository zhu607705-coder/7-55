extends SceneTree
const Space=preload("res://scripts/space/north_floor_space.gd")
const Metrics=preload("res://scripts/player_metrics.gd")
const Phases=preload("res://scripts/ui/chapter4_phase_layers.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("NORTH_SPACE: "+label)

func run()->void:
	create_timer(20).timeout.connect(func():push_error("NORTH_SPACE: watchdog");quit(2))
	var space:RefCounted=Space.new()
	for floor_id:String in ["A1","A2","A3"]:
		space.configure(floor_id)
		check(space.active and space.source_size==Vector2(1672,941),floor_id+" keeps exact source dimensions")
		for region:Rect2 in space.regions:
			check(Rect2(Vector2.ZERO,space.source_size).encloses(region),floor_id+" ground region stays inside source")
		for x in range(0,1672,8):
			check(not space.allows_foot(Rect2(x,-1,1,1)),floor_id+" north fence is continuous")
			check(not space.allows_foot(Rect2(x,941,1,1)),floor_id+" south fence is continuous")
		for y in range(0,941,8):
			check(not space.allows_foot(Rect2(-1,y,1,1)),floor_id+" west fence is continuous")
			check(not space.allows_foot(Rect2(1672,y,1,1)),floor_id+" east fence is continuous")
		check(not space.allows_foot(Metrics.foot_rect(Vector2(787,80))),floor_id+" lift roof/wall is not ground")
		if floor_id!="A1":check(not space.allows_foot(Metrics.foot_rect(Vector2(280,80))),floor_id+" north room wall face is not ground")
		check(space.allows_foot(Metrics.foot_rect(Vector2(787,204))),floor_id+" elevator landing remains ground")
		if floor_id=="A3":
			check(space.solid_faces.size()==1 and space.solid_faces[0].sourceObjectId=="a3_class303_lectern","NPC and player use one registered source lectern face")
			check(Space.depth_in_front(float(space.solid_faces[0].baselineY),598),"teacher's authored feet remain behind the lectern face")
		for gap:Rect2 in space.voids:
			check(not space.allows_foot(Rect2(gap.get_center()-Vector2(.05,.05),Vector2(.1,.1))),floor_id+" navigation voids match ground coverage")
	# Exact area coverage: no corner/centre-only test may bridge an interior slit.
	space.active=true;space.regions.assign([Rect2(0,0,4,10),Rect2(6,0,4,10)])
	check(not space.allows_foot(Rect2(1,1,8,8)),"whole footprint cannot span a two-pixel ground hole")
	space.regions.assign([Rect2(0,0,5,10),Rect2(5,0,5,10)])
	check(space.allows_foot(Rect2(1,1,8,8)),"adjacent ground regions form one seamless floor")
	check(Space.foot_y(Vector2(400,200))==239,"depth uses shared physical foot bottom")
	check(Space.in_front(264,Vector2(400,200)),"wall covers actor while feet are behind baseline")
	check(Space.in_front(264,Vector2(400,225)),"exact foot contact retains source behind-wall ordering")
	check(not Space.in_front(264,Vector2(400,250)),"feet in front of wall cannot be hidden by body-centre sorting")
	var wall:Dictionary={"baselineY":264,"playerRevealAlpha":.22}
	check(Space.npc_cover_alpha(wall,230,Vector2(400,200))==0,"rear NPC uses the later wall pass once")
	check(is_equal_approx(Space.npc_cover_alpha(wall,250,Vector2(400,200)),.78),"front NPC keeps the same 22 percent wall reveal")
	check(is_equal_approx(Space.npc_cover_alpha(wall,250,Vector2(400,250)),.78),"wall can cover rear NPC while leaving front player unchanged")
	check(Space.npc_cover_alpha(wall,270,Vector2(400,200))==0,"NPC in front of a wall is never hidden by it")
	var phases:RefCounted=Phases.new()
	check(not phases._depth({"player":Vector2(400,250)},264,true),"NPC/prop depth consumes the same foot coordinate")

	var state:Node=root.get_node("State");state.developer_mode=true
	state.begin_checkpoint("c4-755-room204-1850")
	var world:Control=load("res://scripts/world.gd").new();world.size=Vector2(960,540);root.add_child(world);world.set_process(false)
	for floor_id:String in ["A1","A2","A3"]:
		state.d.chapter4.floor=floor_id;world.refresh_world()
		check(is_same(world._render_context().actor_occluders,world.foreground),floor_id+" NPC and player share the exact same occlusion records")
		var floor_spec:Dictionary={}
		for candidate:Dictionary in world.spec.layout.floors:
			if candidate.storyFloor==floor_id:floor_spec=candidate
		check(not floor_spec.is_empty(),floor_id+" formal floor is registered")
		var arrival:Dictionary=floor_spec.elevator.arrivalPosition
		var start:=Vector2(arrival.x,arrival.y)
		check(world.can_stand(start),floor_id+" authored elevator arrival remains safe")
		var before:Dictionary=state.d.chapter4.duplicate(true)
		var stopped:Vector2=world._c4_axis_destination(start,Vector2(0,-1000))
		check(stopped.y<start.y and world.can_stand(stopped),floor_id+" actual movement reaches a legal contact")
		check(world.north_space.allows_foot(Metrics.foot_rect(stopped)),floor_id+" complete feet remain on ground at contact")
		check(stopped.y>float(floor_spec.elevator.visibleBounds.y),floor_id+" actual player cannot walk onto lift top")
		check(not world.can_stand(Vector2(arrival.x,80)),floor_id+" direct placement on lift wall is rejected")
		var obstacles:Array=world._floor_obstacles()
		check(obstacles.any(func(rect:Rect2):return rect.has_point(Vector2(arrival.x,80))),floor_id+" touch routing sees the same wall")
		for passage:Dictionary in floor_spec.walkableRegions:
			var center:=Vector2(passage.x+passage.width*.5,passage.y+passage.height*.5)
			check(world.north_space.allows_foot(Rect2(center-Vector2(.5,.5),Vector2.ONE)),floor_id+" authored passage is not reclassified as exterior: "+str(passage.id))
		check(state.d.chapter4==before,floor_id+" geometry cannot change progression")
		# An ordinary re-entry from a stale saved wall pose uses existing safe
		# recovery before input resumes, with the new ground contract included.
		world.player=Vector2(arrival.x,80);world._sync_player()
		world.scene_id="";world.world_key="";world.refresh_world()
		check(world.can_stand(world.player) and world.north_space.allows_foot(Metrics.foot_rect(world.player)),floor_id+" stale saved wall pose recovers onto ground")
	world.queue_free();await process_frame
	print("NORTH_SPACE: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
