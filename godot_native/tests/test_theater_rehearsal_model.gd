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
	check(model.apply({"kind":"try"}) and model.snapshot().failure=="light_axis","fixed witness reveals the shared lamp offset")
	var light_before:Dictionary=model.snapshot();Proof.lamp(model,.6)
	var light_after:Dictionary=model.snapshot()
	check(light_before.objects==light_after.objects and light_before.projections[0].center!=light_after.projections[0].center and light_before.projections[1].center!=light_after.projections[1].center,"moving the light alters both wings without moving either fan")
	Proof.move(model,"left_fan",Vector2(.36,4));Proof.move(model,"right_fan",Vector2(.24,6));Proof.spread(model,"left_fan",1.0);Proof.spread(model,"right_fan",.7);model.apply({"kind":"try"})
	check(model.snapshot().failure=="blocked_light" and model.snapshot().screen=="playing","two aligned fans cannot bypass the intervening opaque screen")
	Proof.move(model,"side_screen",Vector2(4.4,8));model.apply({"kind":"try"})
	check(model.snapshot().screen=="complete","moving the same physical screen out of the light path completes the combination")
	model=Model.new();Proof.move(model,"left_fan",Vector2(0,5));model.apply({"kind":"try"})
	check(model.snapshot().failure=="fan_opening","position alone cannot solve a folded fan")
	var folded:Dictionary=model.snapshot()
	check(not model.apply({"kind":"lamp","x":.1}),"legacy lamp action without a depth is rejected")
	for invalid:Variant in [NAN,INF,.1,1.1,true,"1"]:check(not model.apply({"kind":"spread","id":"left_fan","value":invalid}),"invalid fan opening is rejected: "+str(invalid))
	check(not model.apply({"kind":"spread","id":"left_fan","value":1.0}),"a forged single-step fold cannot teleport the mechanism")
	check(model.snapshot()==folded,"invalid opening leaves history and action proof untouched")
	model.apply({"kind":"spread","id":"left_fan","value":.5});model.apply({"kind":"undo"})
	check(model.snapshot().objects==folded.objects,"undo restores the real fan opening")
	Proof.solve_round(model);model.apply({"kind":"continue"});Proof.move(model,"left_fan",Vector2(0,6));model.apply({"kind":"try"})
	check(model.snapshot().failure=="fan_opening","correct projected height still requires the narrower wing")
	Proof.solve_round(model);model.apply({"kind":"continue"});var initial:Dictionary=model.snapshot()
	model.apply({"kind":"lamp","x":-.5,"depth":1.2});model.apply({"kind":"undo"})
	check(model.snapshot().lampX==initial.lampX and model.snapshot().lampDepth==initial.lampDepth and model.snapshot().projections==initial.projections,"undo restores shared light and all affected shadows together")
	Proof.lamp(model,.6);var adjusted:Dictionary=model.snapshot();model.apply({"kind":"restart"});model.apply({"kind":"undo"})
	check(model.snapshot().lampX==adjusted.lampX and model.snapshot().lampDepth==adjusted.lampDepth and model.snapshot().objects==adjusted.objects,"restart undo restores both coupled controls")
	model=Model.new();before=model.snapshot()
	check(Proof.lamp(model,.4,.5),"the first scene accepts direct two-axis light movement")
	var nearer:Dictionary=model.snapshot()
	check(nearer.objects==before.objects and nearer.projections[0].radius>before.projections[0].radius,"moving the source toward an unmoved fan enlarges its projection")
	check(Proof.lamp(model,.4,-.5) and model.snapshot().projections[0].radius<before.projections[0].radius,"moving the source away shrinks the same projection")
	model.apply({"kind":"restart"});check(model.snapshot().lampX==0.0 and model.snapshot().lampDepth==0.0,"restart restores both source axes")
	before=model.snapshot()
	for invalid:Variant in [{"kind":"lamp","x":0,"depth":NAN},{"kind":"lamp","x":INF,"depth":0},{"kind":"lamp","x":0,"depth":true},{"kind":"lamp","x":0,"depth":-.6},{"kind":"lamp","x":0,"depth":1.6},{"kind":"lamp","x":1.3,"depth":0},{"kind":"lamp","x":.4,"depth":.4},{"kind":"lamp","x":0,"depth":0},{"kind":"lamp","x":.1,"depth":0,"solved":true}]:
		check(not model.apply(invalid),"illegal light input rejected without movement: "+str(invalid))
	check(model.snapshot()==before,"invalid light gestures leave projections and history unchanged")
	for x:float in [-1.25,1.25]:
		for depth:float in [Model.LAMP_DEPTH_MIN,Model.LAMP_DEPTH_MAX]:
			check(Proof.lamp(model,x,depth),"bounded lamp travel can reach each corner")
			for projection:Dictionary in model.snapshot().projections:check(is_finite(projection.radius) and projection.radius>0 and is_finite(projection.center),"light never crosses a prop plane or produces a degenerate projection")
	model=Model.new();Proof.solve_round(model);model.apply({"kind":"continue"});Proof.solve_round(model);model.apply({"kind":"continue"})
	var scale:float=Model.project(Model.WITNESS,0.0,1.2).magnification
	var misleading_x:float=(3.4-2.0*scale)/(1.0-scale)
	Proof.lamp(model,misleading_x,1.2);model.apply({"kind":"try"})
	check(absf(model.snapshot().witness.center-3.4)<.001 and model.snapshot().failure=="light_axis","aligning only the pin center cannot bypass its visibly incorrect shadow height")
	Proof.lamp(model,.6,0.0);check(is_equal_approx(model.snapshot().witness.magnification,2.0),"restored source distance matches both ends of the fixed calibration pin")
	check(Proof.solve_round(model) and not Model.replay(model.proof()).is_empty(),"a proof including depth adjustment replays through the original completion boundary")
	print("THEATER_REHEARSAL_MODEL: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
