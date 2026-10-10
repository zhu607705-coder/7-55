extends SceneTree
const Motion=preload("res://scripts/presentation/library_stamp_motion.gd")
const Layer=preload("res://scripts/ui/library_world_layers.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	for reduced: bool in [false,true]:
		var duration: int=int(Motion.REDUCED_MS if reduced else Motion.TOTAL_MS)
		var prior: Dictionary=Motion.sample(0,-1,reduced)
		for ms: int in range(duration+1):
			var pose: Dictionary=Motion.sample(ms,-1,reduced)
			var t: float=ms*Motion.TOTAL_MS/duration
			check(Vector2(pose.stampRect.size).is_equal_approx(Vector2(64,88)*pose.stampScale),"uniform original texture scale")
			check((Vector2(pose.stampRect.position)+Vector2(32,Motion.STAMP_SOURCE_CONTACT_Y)*pose.stampScale).is_equal_approx(pose.stampBottom),"original alpha foot registered to contact socket")
			check(pose.paperSize==Vector2(46,28),"sheet extent retained")
			check(is_equal_approx(pose.paper.y,24),"paper remains inside horizontal guides")
			check(pose.pressure>=0 and pose.pressure<=1 and pose.ink>=0 and pose.ink<=1 and pose.alpha>=0 and pose.alpha<=1,"finite bounded feedback")
			if t<Motion.CONTACT_MS: check(pose.ink==0 and pose.pressure==0,"no ink or load before physical contact")
			if t>=Motion.CONTACT_MS and t<=Motion.RELEASE_MS:
				check(Vector2(pose.stampBottom).distance_to(Vector2(pose.contact))<.001,"stamp foot shares loaded paper contact")
			if t<Motion.RETURN_MS: check(pose.paper==Motion.PAPER_REST,"paper held still until stamp clears")
			if t>=Motion.RETURN_MS:
				check(pose.stampBottom.y==Motion.STAMP_REST_Y and pose.pressure==0,"return starts only after foot clears sheet")
				check(pose.paper.x<=prior.paper.x+.001,"one-way return without overshoot")
			if t<Motion.RETURN_END_MS: check(pose.alpha==1,"paper never disappears before rail exit")
			check(Vector2(pose.paper).distance_to(Vector2(prior.paper))<1,"continuous sheet at every millisecond")
			check(Vector2(pose.stampBottom).distance_to(Vector2(prior.stampBottom))<1,"continuous rigid stamp at every millisecond")
			check(absf(pose.alpha-prior.alpha)<.06,"continuous final handoff opacity")
			var mark_local: Vector2=Vector2(pose.mark)-Vector2(pose.paper)
			check(mark_local.is_equal_approx(Vector2(Motion.STAMP_X-Motion.PAPER_REST.x,Motion.CONTACT_Y-Motion.PAPER_REST.y)),"ink remains attached to same sheet")
			var loaded: Vector2=Motion.paper_point(mark_local,pose)
			check(loaded.is_equal_approx(Vector2(pose.mark)+Vector2(0,pose.pressure*.8)),"sheet flex and mark share contact surface")
			check(absf(Motion.paper_point(Vector2(23,14),pose).y-(pose.paper.y+14))<.01,"far sheet corner does not globally squash")
			prior=pose
		check(prior.alpha==0 and prior.paper==Motion.PAPER_RETURN,"same paper retires only at completed handoff")
		var scan_previous:=Motion.PAPER_RETURN
		for ms: int in range(401):
			var pose: Dictionary=Motion.sample(-1,ms,reduced)
			check(pose.visible and pose.ink==0,"received report is not already stamped")
			check(pose.paper.x>=scan_previous.x and pose.paper.x<=Motion.PAPER_REST.x,"report enters same guide without overshoot")
			check(Vector2(pose.paper).distance_to(scan_previous)<1,"continuous report feed")
			scan_previous=pose.paper
	var state: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	state.native={"chapter":2,"scene":"library_interior","settings":{"reduced_motion":false}}
	state.ui.libraryFinalsPuzzle.lostFoundStage="ready"
	var layer:=Layer.new(); layer.sync(state)
	state.ui.libraryFinalsPuzzle.lostFoundStage="scanning"; layer.sync(state)
	var facts: String=JSON.stringify(state)
	for i in range(80):layer.tick(.01,state)
	check(JSON.stringify(state)==facts,"scanning presentation cannot award proof")
	state.ui.libraryFinalsPuzzle.lostFoundStage="stamped";state.ui.libraryFinalsPuzzle.nonPersonProofStamped=true;layer.sync(state)
	facts=JSON.stringify(state)
	for i in range(81):layer.tick(.01,state)
	check(JSON.stringify(state)==facts and layer.stamp_ms==-1,"810ms presentation never changes committed controller state")
	check(not layer.stamp_pose().visible,"no duplicate paper after handoff")
	layer.sync(state.duplicate(true));check(layer.stamp_ms==-1,"state replacement cannot replay earned proof")
	state.native.scene="campus_bootstrap";layer.sync(state);state.native.scene="library_interior";layer.sync(state)
	check(layer.stamp_ms==-1,"scene reentry cannot repeat stamp")
	for interruption_ms: int in [180,550]:
		for replace_state: bool in [false,true]:
			state.ui.libraryFinalsPuzzle.nonPersonProofStamped=false;state.ui.libraryFinalsPuzzle.lostFoundStage="scanning";layer.sync(state,true)
			state.ui.libraryFinalsPuzzle.nonPersonProofStamped=true;state.ui.libraryFinalsPuzzle.lostFoundStage="stamped";layer.sync(state)
			for i in range(interruption_ms/10):layer.tick(.01,state)
			check(layer.stamp_ms==interruption_ms,"interrupt tested inside active service phase")
			facts=JSON.stringify(state)
			if replace_state:state=state.duplicate(true);layer.sync(state)
			else:state.native.scene="campus_bootstrap";layer.sync(state);state.native.scene="library_interior";layer.sync(state)
			check(layer.stamp_ms==-1 and not layer.stamp_pose().visible,"interrupted proof does not replay on scene/state reentry")
			check(JSON.stringify(state)==facts,"interruption never duplicates or erases controller evidence")
	print("LIBRARY_STAMP_MOTION: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
