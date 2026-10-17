extends SceneTree
const Scanner=preload("res://scripts/games/identity_stamp.gd")
var checks: int=0
var failures: int=0
var state: Node
var world: Control
var requests: Array=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize() -> void:run.call_deferred()
func reset() -> void:
	state.d=state.initial();state.d.native.chapter=2;state.d.native.scene="library_interior";state.d.native.mode="light"
	state.d.actOne.phase="complete";state.d.ui.libraryFinalsPhase="evidence_gathering"
	state.d.ui.libraryFinalsPuzzle.itemReportGenerated=true;state.d.ui.libraryFinalsPuzzle.lostFoundStage="ready"
	state.d.items.itemRecognitionReport=true;state.d.native.selected_item="itemRecognitionReport"
	world.world_key="";world.refresh_world();world.set_process(false)
	world.player=Vector2(334,694);world.facing="down";world.walk_clock=.2;world.player_flip=true;requests.clear()
func run() -> void:
	state=root.get_node("State");state.developer_mode=true
	state.game_requested.connect(func(request: Dictionary):requests.append(request))
	root.size=Vector2i(960,540);world=load("res://scripts/world.gd").new();world.size=Vector2(960,540);root.add_child(world)
	await process_frame;world.set_process(false);reset()
	var target: Dictionary={"id":"identity_machine","position":[334,594],"bounds":[174,519,320,150],"radius":64,"mode":"light","item":"itemRecognitionReport","action":"lib_scan"}
	world.player=Vector2(334,800);world._try_interact(target)
	check(world.facing=="down" and requests.is_empty(),"too far does not rotate or open scanner")
	reset();state.d.native.mode="dark";world._try_interact(target)
	check(world.facing=="down" and requests.is_empty(),"wrong mode does not rotate")
	reset();state.d.native.selected_item="rightArrow";world._try_interact(target)
	check(world.facing=="down" and requests.is_empty(),"wrong selected item does not rotate")
	reset();state.d.items.itemRecognitionReport=false;world._try_interact(target)
	check(world.facing=="down" and requests.is_empty(),"controller refusal does not rotate")
	reset();world.move_target=Vector2(334,750);world._try_interact(target)
	check(requests.size()==1 and requests[0].script=="res://scripts/games/identity_stamp.gd","ordinary accepted interaction opens same scanner")
	check(world.facing=="up" and not world.player_flip and world.walk_clock==0,"one successful interaction selects real back sprite")
	check(world.move_target==Vector2.INF,"old point route cannot turn actor away during service")
	check(world.player_frames.up[0].resource_path.ends_with("player_up_0.png"),"back pose uses original up artwork rather than mirrored front")
	check(state.d.items.itemRecognitionReport and not state.d.items.bagNonPersonProof,"facing change cannot grant proof")
	var scan:=Scanner.new();root.add_child(scan);scan.set_process(false)
	var results: Array=[];scan.finished.connect(func(result: Dictionary):results.append(result))
	scan._stamp();check(results.is_empty(),"original scanner refuses premature stamp")
	for i in range(8):scan._process(.1)
	scan._stamp();scan._stamp()
	check(results.size()==1,"original scanner issues exactly once")
	state.act("lib_scan_result",results[0]);world.library_layers.sync(state.d)
	check(state.d.items.bagNonPersonProof and not state.d.items.itemRecognitionReport,"same controller consumes report and grants proof")
	check(world.library_layers.stamp_ms==0,"accepted proof starts world choreography")
	# Ordinary movement is not hard-locked to the desk; use an open library floor.
	var free:=Vector2.INF
	for y: int in range(280,760,40):
		for x: int in range(200,1320,40):
			var point:=Vector2(x,y)
			if world.can_stand(point) and world.can_stand(point+Vector2(5,0)):free=point;break
		if free!=Vector2.INF:break
	check(free!=Vector2.INF,"real library collision model supplies an open walking location")
	world.player=free;world.touch_axis=Vector2.RIGHT;world._process(.016)
	check(world.facing=="side","subsequent movement resumes normal facing")
	scan.queue_free();world.queue_free();await process_frame
	print("LIBRARY_STAMP_FACING: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
