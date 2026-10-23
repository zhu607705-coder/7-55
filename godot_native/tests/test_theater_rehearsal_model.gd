extends SceneTree
const Model=preload("res://scripts/games/theater_shadow_rehearsal_model.gd")
const Proof=preload("res://tests/helpers/theater_rehearsal_proof.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("THEATER_REHEARSAL_MODEL: "+label)
func run() -> void:
	var model=Model.new()
	check(model.proof().is_empty(),"unplayed state has no completion proof")
	check(not model.apply({"kind":"continue"}),"cannot skip an unsolved stage")
	var before: Dictionary=model.snapshot();var copy: Dictionary=model.snapshot();copy.objects[0].x=900
	check(model.snapshot()==before,"read snapshot cannot mutate physical state")
	check(not model.apply({"kind":"move","id":"left_fan","x":-0.9,"depth":5.0}),"single action cannot teleport a prop")
	check(not model.apply({"kind":"move","id":"left_fan","x":-2.0,"depth":5.1}),"first stage isolates horizontal movement")
	for bad: Variant in [null,{},"win",{"kind":"move","id":"left_fan","x":NAN,"depth":5.0},{"kind":"move","id":"left_fan","x":INF,"depth":5.0},{"kind":"try","solved":true},{"kind":"move","id":"missing","x":0,"depth":5}]:check(not model.apply(bad),"invalid input rejected: "+str(bad))
	check(model.snapshot()==before,"rejected inputs leave model unchanged")
	check(model.apply({"kind":"try"}) and model.snapshot().failure=="shadow_position","first failure reports physical position mismatch")
	check(model.snapshot().objects==before.objects and model.snapshot().completedRounds==0,"miss preserves prop positions and earned stages")
	var projected: Dictionary=Model.project({"id":"a","kind":"fan","side":-1,"x":-1.0,"depth":5.0})
	check(is_equal_approx(projected.center,-2.0) and is_equal_approx(projected.radius,0.9),"shadow derives from lamp to gauze projection")
	model.apply({"kind":"move","id":"left_fan","x":-1.8,"depth":5.0});var moved: Dictionary=model.snapshot()
	model.apply({"kind":"restart"});model.apply({"kind":"undo"})
	check(model.snapshot().objects==moved.objects,"restart may be undone without erasing observations")
	model.apply({"kind":"undo"});check(model.snapshot().objects==before.objects,"undo restores actual previous pose")
	for stage in 3:
		check(Proof.solve_round(model),"stage %d solved through legal physical movements"%stage)
		check(model.snapshot().completedRounds==stage+1,"stage count derives from observed physical alignment")
		if stage<2:
			check(model.apply({"kind":"continue"}),"successful curtain allows next authored scene")
			check(not model.apply({"kind":"undo"}),"undo cannot take earned scenes away")
	var proof: Dictionary=model.proof({"nonce":"test"})
	check(not proof.is_empty() and not Model.replay(proof).is_empty(),"full input trace replays all three physical scenes")
	check(not model.apply({"kind":"restart"}),"finished stage does not accept late input")
	for fault: String in ["empty","partial","digest","puzzle","oversize","unknown","boolean"]:
		var bad: Dictionary=proof.duplicate(true)
		match fault:
			"empty":bad.actions=[]
			"partial":bad.actions.pop_back()
			"digest":bad.layoutDigest="wrong"
			"puzzle":bad.puzzleId="another"
			"oversize":bad.actions.resize(Model.MAX_ACTIONS+1)
			"unknown":bad.actions=[{"kind":"finish"}]
			"boolean":bad.actions=[];bad.completed=true
		check(Model.replay(bad).is_empty(),"replay rejects "+fault)
	model=Model.new();Proof.solve_round(model);model.apply({"kind":"continue"})
	check(model.apply({"kind":"try"}) and model.snapshot().failure=="shadow_size","second scene adds only depth-to-size discovery")
	Proof.solve_round(model);model.apply({"kind":"continue"})
	Proof.move(model,"left_fan",Vector2(0,4));Proof.move(model,"right_fan",Vector2(0,6));model.apply({"kind":"try"})
	check(model.snapshot().failure=="blocked_light" and model.snapshot().screen=="playing","two aligned fans cannot bypass the intervening opaque screen")
	Proof.move(model,"side_screen",Vector2(4.4,8));model.apply({"kind":"try"})
	check(model.snapshot().screen=="complete","moving the same physical screen out of the light path completes the combination")
	print("THEATER_REHEARSAL_MODEL: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
