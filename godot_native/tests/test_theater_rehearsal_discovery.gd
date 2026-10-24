extends SceneTree
const View=preload("res://scripts/games/theater_shadow_rehearsal.gd")
const Model=preload("res://scripts/games/theater_shadow_rehearsal_model.gd")
const Study=preload("res://scripts/presentation/theater_rehearsal_study.gd")
const Proof=preload("res://tests/helpers/theater_rehearsal_proof.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("REHEARSAL DISCOVERY: "+label)
func frames()->void:
	for i:int in range(4):await process_frame
func key(code:Key)->void:
	for pressed:bool in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.pressed=pressed;root.push_input(event,true);await frames()
func trial(model:RefCounted,study:RefCounted)->void:
	model.apply({"kind":"try"});study.record(model.snapshot())
func pointer(at:Vector2,pressed:bool,touch:bool=false)->void:
	if touch:
		var event:=InputEventScreenTouch.new();event.index=3;event.position=at;event.pressed=pressed;root.push_input(event,true)
	else:
		var event:=InputEventMouseButton.new();event.position=at;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;root.push_input(event,true)
	await frames()
func drag(view:Control,touch:bool,close_to:Vector2=Vector2.ZERO,cancel:bool=false)->void:
	var trace:Control=view.notebook.tracing
	var start:Vector2=trace.global_position+trace.origin()+(trace.sheet+trace.EXTENT/2)*trace.fit()
	var end:Vector2=trace.global_position+trace.origin()+(trace.TARGET+trace.EXTENT/2+close_to)*trace.fit()
	await pointer(start,true,touch)
	for i:int in range(1,9):
		var at:Vector2=start.lerp(end,float(i)/8)
		if touch:
			var event:=InputEventScreenDrag.new();event.index=3;event.position=at;root.push_input(event,true)
		else:
			var event:=InputEventMouseMotion.new();event.position=at;event.button_mask=MOUSE_BUTTON_MASK_LEFT;root.push_input(event,true)
		await frames()
	if cancel:view._focus_out()
	await pointer(end,false,touch)
func run()->void:
	var model=Model.new();var study=Study.new()
	for i:int in 20:trial(model,study)
	check(not study.snapshot(0).ready and not study.seal(0),"repeated trials cannot invent a changed condition")
	Proof.move(model,"left_fan",Vector2(-1.4,5));Proof.spread(model,"left_fan",.8);trial(model,study)
	check(not study.snapshot(0).ready,"two changed factors do not establish the missing relationship")
	Proof.spread(model,"left_fan",.45);trial(model,study)
	check(study.snapshot(0).ready and not study.snapshot(0).sealed,"a controlled fan comparison supplies paper but does not solve the page")
	var copy:Dictionary=study.snapshot(0);copy.pairs.spread.before.objects[0].x=99
	check(study.snapshot(0).pairs.spread.before.objects[0].x!=99,"rendering cannot modify stored experimental evidence")
	check(study.seal(0) and not study.seal(0),"paper alignment can reveal one optional volume once")
	check(model.snapshot().completedRounds==0 and model.proof().is_empty(),"revealing a volume grants no puzzle completion")
	check(Proof.solve_round(model),"original first-round physical solution remains legal");model.apply({"kind":"continue"})
	trial(model,study);Proof.move(model,"left_fan",Vector2(0,4));trial(model,study)
	check(study.snapshot(1).ready and not study.snapshot(1).sealed,"distance needs its own actual paired experiment")
	check(Proof.solve_round(model),"original second-round solution remains legal");model.apply({"kind":"continue"})
	trial(model,study);Proof.lamp(model,0,1.2);trial(model,study)
	check(not study.snapshot(2).ready and study.snapshot(2).pairs.has("lamp_x"),"one lamp axis cannot reveal both common-light relationships")
	Proof.lamp(model,0,.5);trial(model,study)
	check(study.snapshot(2).ready,"independent depth evidence completes the shared-light comparison")
	check(Proof.solve_round(model) and not Model.replay(model.proof()).is_empty(),"physical solution and replay remain authoritative without reading the volumes")
	var shared:Node=root.get_node("State");var before:Dictionary=shared.d.duplicate(true)
	for extent:Vector2i in [Vector2i(1280,720),Vector2i(1440,900),Vector2i(844,390),Vector2i(390,844)]:
		var view=View.new();view.setup({"session":{"nonce":"discovery"},"settings":{"reducedMotion":true}});root.size=extent;root.add_child(view);view.configure_activity_layout(Vector2(extent),false);await frames()
		view._close_help();if view.menu_open:view._close_menu()
		view._help();await frames()
		for i:int in 12:view._next_hint();view._previous_hint()
		check(not view.study.snapshot(0).ready and not view.help_body.text.contains("扇亦可展"),"cycling pages does not expose the original explicit rule "+str(extent))
		var p:Control=view.notebook.tracing
		var target:Vector2=p.global_position+p.origin()+(p.TARGET+p.EXTENT/2)*p.fit()
		for i:int in 6:await pointer(target,true);await pointer(target,false)
		check(not view.study.snapshot(0).sealed,"clicking the old印 has no answer-unlock side effect "+str(extent))
		view._close_help();view._try_stage();view._spread_prop("left_fan",.7)
		check(not view.study.snapshot(0).ready,"live manipulation alone is not a recorded trial")
		view._try_stage();view._help();await frames()
		check(view.study.snapshot(0).ready and p.evidence_ready,"two accepted actual trials provide the interactive tracing")
		check(p.EXTENT.y*p.fit()>=44 and view.notebook.get_global_rect().encloses(p.get_global_rect()),"paper drag stays visible and touch-sized "+str(extent))
		await drag(view,extent.x<1000,Vector2(28,0))
		check(not view.study.snapshot(0).sealed,"a visibly misregistered tracing does not auto-snap to an answer")
		if extent.x==1440:
			p.grab_focus()
			for i:int in 7:await key(KEY_LEFT)
			await key(KEY_SPACE)
		else:
			await drag(view,extent.x<1000,Vector2.ZERO,true)
			check(not view.study.snapshot(0).sealed and p.pointer_owner==-99,"focus loss cancels the paper gesture without revealing the rule")
			view._close_help();view._close_menu();view._help();await frames()
			await drag(view,extent.x<1000)
		check(view.study.snapshot(0).sealed and view.help_body.text.contains("扇亦可展") and not p.visible,"real paper alignment reveals the relation after evidence "+str(extent))
		check(view.state.completedRounds==0 and view.state.objects[0].x==-2 and view.state.attempts==2,"paper puzzle does not move props or award the actual stage")
		view._close_help();view._help();await frames()
		check(view.study.snapshot(0).sealed,"closing and reopening keeps this session's decoded paper")
		view.dispose_presentation();view.queue_free();await frames()
	check(shared.d==before,"optional discovery never becomes shared story state")
	print("THEATER_REHEARSAL_DISCOVERY: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
