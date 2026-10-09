extends SceneTree
const Chapter=preload("res://scripts/chapters/chapter3.gd")
const Session=preload("res://scripts/presentation/c3_narrative_session.gd")
const Model=preload("res://scripts/games/canteen_defense_model.gd")
const View=preload("res://scripts/presentation/c3_narrative_world_view.gd")
var checks:=0
var failures:=0

class MockWorld extends Control:
	var scene_id: String="canteen_interior"
	var camera:=Vector2(1040,660)
	var zoom: float=.56525

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)

func initial(reduced: bool=false) -> Dictionary:
	var state: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	state.native={"chapter":3,"scene":"canteen_interior","page":"c3_canteen","mode":"light","settings":{"reduced_motion":reduced},"player":{"x":908,"y":628}}
	state.runtimeMode="rpg";state.rpgScene="canteen_interior"
	state.canteenHunt.active=true;state.canteenHunt.phase="exit_blocking"
	return state

func advance(session: RefCounted,state: Dictionary,owner: Node,at: float) -> void:
	while session.elapsed_ms<at:
		session.frame(state,minf(10,at-session.elapsed_ms),owner)

func _initialize() -> void:call_deferred("run")

func run() -> void:
	var owner:=Node.new();root.add_child(owner)
	var oracle: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/canteen_victory_source.json"))
	var draw_session: RefCounted
	for entry: Dictionary in oracle.cases:
		var state: Dictionary=initial(entry.reduced)
		state.canteenHunt.phase="chase_ready"
		var start: Dictionary=entry.initial
		var authored: Array=[]
		for line: Dictionary in entry.lines:authored.append(line.text)
		var session:=Session.new(state,{"id":"canteen_escape","scene":"canteen_interior","paperStart":start.point,"paperFrame":start.frame,"paperFlip":start.flip,"paperAngle":start.angle,"lines":authored,"delayMs":entry.hideAtMs,"stepMs":1200,"tailMs":166 if entry.reduced else 475})
		check(session.attach(state,owner),"source fixture attaches to its real narrative owner")
		var saved: String=JSON.stringify(state)
		for index: int in range(3):
			check(session.lines[index].text==entry.lines[index].text and session.lines[index].atMs==entry.lines[index].atMs and session.lines[index].durationMs==entry.lines[index].durationMs,"three source dialogue lines retain order/onset/duration")
		for sample: Dictionary in entry.samples:
			advance(session,state,owner,float(sample.atMs))
			var pose: Dictionary=session.paper_pose()
			var label: String="reduced=%s frame=%s at=%s" % [entry.reduced,start.frame,sample.atMs]
			check(pose.point.is_equal_approx(Vector2(sample.point[0],sample.point[1])),"source position "+label)
			check(is_equal_approx(float(pose.scale),1.0) and pose.scaleXY.is_equal_approx(Vector2(sample.scale[0],sample.scale[1])),"source nonuniform scales "+label)
			check(is_equal_approx(float(pose.angle),float(sample.angle)),"source quadratic angle from terminal angle "+label)
			check(pose.frame==sample.frame and pose.flip==sample.flip,"frozen run texture/mirror, then idle reset "+label)
			check(is_equal_approx(float(pose.alpha),float(sample.alpha)) and not pose.wet,"full hold and hide-before-dialogue "+label)
			check(session.paper_pose()==pose,"repainting never advances victory "+label)
		check(JSON.stringify(state)==saved,"entire source pose sequence cannot mutate facts/items/proof")
		session.elapsed_ms=entry.durationMs/2
		var frozen: Dictionary=session.paper_pose()
		session.frame(state,100,owner,false)
		check(session.paper_pose()==frozen,"blur freezes all paper channels together")
		if entry.reduced and int(start.frame)==3:draw_session=session

	# The only production pose issuer is the already-validated replay. Malicious
	# extra fields, including terminal coordinates, have no presentation authority.
	var proof: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/canteen_defense.json"))
	var replay:=Model.new();replay.configure(str(proof.seed))
	for attempt: Array in proof.get("attempts",[]):
		check(Model.replay_inputs(replay,attempt),"recorded retry replays")
		replay.restart_attempt(false)
	check(Model.replay_inputs(replay,proof.inputs) and replay.status=="won","original sixty-second proof reaches genuine terminal model")
	for reduced: bool in [false,true]:
		var state: Dictionary=initial(reduced)
		var chapter:=Chapter.new()
		var admission: Dictionary=chapter.dispatch(state,"c3_defense")
		var submitted: Dictionary=proof.duplicate(true)
		submitted.session_id=admission.game.session_id
		submitted.paper=[-900,9000];submitted.player=[-900,9000]
		submitted.paperStart=[-900,9000];submitted.playerStart=[-900,9000]
		submitted.paperFrame=(replay.paper_frame+1)%4;submitted.paperFlip=not replay.paper_flip;submitted.paperAngle=700
		var expected: Dictionary=state.duplicate(true)
		expected.canteenHunt.blockHits=3;expected.canteenHunt.phase="chase_ready"
		var accepted: Dictionary=chapter.dispatch(state,"c3_defense_result",submitted)
		check(accepted.get("narrative_owned",false),"valid proof still enters the authored victory")
		var session: RefCounted=chapter.narrative_session(state)
		check(session!=null and session.sequence_id=="canteen_escape","accepted replay owns escape session")
		if session==null:continue
		check(session.origin.is_equal_approx(replay.paper) and session.spec.playerStart==[replay.player.x,replay.player.y],"caller positions cannot replace validated physical endpoints")
		check(session.spec.paperFrame==replay.paper_frame and session.spec.paperFlip==replay.paper_flip and is_equal_approx(float(session.spec.paperAngle),replay.paper_angle),"caller frame/flip/angle cannot replace frozen replay pose")
		var pose: Dictionary=session.paper_pose()
		check(pose.frame==replay.paper_frame and pose.flip==replay.paper_flip and is_equal_approx(float(pose.angle),replay.paper_angle) and pose.scaleXY==Vector2(1.16,1.16),"victory begins without texture/orientation/scale pop")
		check(JSON.stringify(state)==JSON.stringify(expected),"only existing phase/blockHits facts change; reward/save/proof authority unchanged")
		submitted.paperFrame=99;submitted.paperStart[0]=-9999
		check(session.paper_pose()==pose,"later caller mutation cannot change issued presentation")
		session.cancel()
		var reopened: RefCounted=chapter.narrative_session(state)
		check(reopened!=session and reopened.paper_pose()==pose,"cancel/reopen retains the verified terminal art")

	var invalid_state: Dictionary=initial()
	var invalid_chapter:=Chapter.new()
	var admission: Dictionary=invalid_chapter.dispatch(invalid_state,"c3_defense")
	var invalid: Dictionary=proof.duplicate(true)
	invalid.session_id=admission.game.session_id;invalid.inputs=[];invalid.paperFrame=3;invalid.paperFlip=true;invalid.paperAngle=86
	var before: String=JSON.stringify(invalid_state)
	invalid_chapter.dispatch(invalid_state,"c3_defense_result",invalid)
	check(JSON.stringify(invalid_state)==before and invalid_chapter.narrative_session(invalid_state)==null,"forged pose/terminal summary cannot substitute for trace validation")

	# Exercise the actual narrative draw call with a flipped, angled, nonuniform
	# run frame. Pixel/GUI acceptance remains an additional integration check.
	var world:=MockWorld.new();root.add_child(world);world.size=Vector2(960,540)
	var view:=View.new();world.add_child(view);view.world=world;view.session=draw_session
	await process_frame
	await process_frame
	check(view.is_visible_in_tree(),"real narrative world view accepts independent scales and frozen frame/flip")
	world.free();owner.free()
	print("CANTEEN_VICTORY_POSE ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
