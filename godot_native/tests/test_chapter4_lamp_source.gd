extends SceneTree
const Activity=preload("res://scripts/games/chapter4_activity.gd")
const Sequence=preload("res://scripts/presentation/chapter4_lamp_sequence.gd")
var checks:=0
var failures:=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func tick(view:Control,ms:float)->void:
	while ms>0:
		var step:=minf(ms,100);view.advance(step);ms-=step
func request(owner:Node,reduced:bool=false)->Dictionary:
	check(owner.begin_checkpoint("c4-755-closure"),"Real controller closure fixture loads")
	owner.d.native.settings.reduced_motion=reduced
	for module in owner.modules:
		if str(module.get_script().resource_path)=="res://scripts/chapters/chapter4.gd":return module.dispatch(owner.d,"c4_lamp_start")
	return {}
func drain()->void:await process_frame;await process_frame
func run()->void:
	var owner:=root.get_node("State")
	for reduced in [false,true]:
		var issued:=request(owner,reduced)
		check(issued.has("game"),"Actual controller issues closure owner")
		if not issued.has("game"):continue
		var activity:=Activity.new();root.add_child(activity);activity.setup(issued.game);activity.set_process(false)
		activity.completed.connect(func(proof):owner.act("c4_closure_done",proof))
		var view:Control=activity.lamp_view
		check(activity.uses_activity_layout(),"Finale owns full available activity area")
		check(view.stars.size()==6320 and view.lamp.size()==5,"All original lamp layers and seeded 3D stars remain")
		for dimensions in [Vector2(390,844),Vector2(430,860),Vector2(844,390),Vector2(1180,812)]:
			activity.configure_activity_layout(dimensions,true);await drain()
			check(activity.scale==Vector2.ONE and activity.size==dimensions and view.size==dimensions,"No whole-panel shrink at "+str(dimensions))
			check(Rect2(Vector2.ZERO,dimensions).encloses(Rect2(view.panel.position,view.panel.size)),"Question panel is within activity")
			for button in view.buttons:
				check(button.size.y>=44 and button.get_theme_font_size("font_size")>=18,"Readable original choice and physical target")
		check(view.phase=="entering","First source question enters before becoming interactive")
		view.choose("purpose","seek_truth");check(view.answers.get("purpose")==null,"Input during entry cannot select answer")
		var paused_clock:float=view.stage_ms;view.advance(100,false);check(view.stage_ms==paused_clock,"Focus loss freezes source clock")
		tick(view,120 if reduced else 1150);check(view.phase=="ready","First source entry duration honored")
		view.choose("person","responsible");check(view.answers.get("person")==null,"Cannot answer different question")
		view.choose("purpose","seek_truth");view.choose("purpose","serve_public");check(view.answers.purpose=="seek_truth","Double input during dissolve cannot overwrite choice")
		tick(view,159 if reduced else 979);check(view.question_index==0,"First dissolve must finish before second question")
		tick(view,1);check(view.question_index==1 and view.phase=="entering","Second question follows source dissolve")
		check(not owner.d.chapter4.factIds.has("zhu_two_questions_answered"),"First answer does not persist story completion")
		tick(view,120 if reduced else 1150);view.choose("person","clear_minded");tick(view,160 if reduced else 980)
		check(view.stage=="saved" and owner.d.chapter4.factIds.has("zhu_two_questions_answered"),"Both choices validate and save before playback")
		view.acknowledge();check(not owner.d.chapter4.completed,"No early final acknowledgement")
		tick(view,239 if reduced else 1099);check(view.stage=="saved","Source saved confirmation is visible for authored duration")
		tick(view,1);check(view.stage=="playback" and view.playback_ms==0,"Only saved-confirmation clock starts playback")
		var duration:=3600.0 if reduced else 5800.0
		var proof:Dictionary={"session":issued.game.session,"consumer":"ChapterFourStarLampClosure","answers":view.answers,"playbackMs":duration-1,"acknowledged":true}
		owner.act("c4_closure_done",proof);check(not owner.d.chapter4.completed,"Controller rejects shortened duration even with real nonce")
		tick(view,duration-1);check(view.stage=="playback","Playback cannot finish early")
		tick(view,1);await drain();check(view.stage=="final" and not owner.d.chapter4.completed,"Final message waits for explicit acknowledgement")
		check(view.buttons.size()==1 and view.buttons[0].text=="继续","Original final acknowledgement label restored")
		var text:=""
		for child in view.column.get_children():
			if child is Label:text+=child.text
		check(text.contains("求学所向") and text.contains("成人所守") and text.contains(view.FINAL_MESSAGE),"Original final message and selected-answer summaries are present")
		for dimensions in [Vector2(390,844),Vector2(844,390)]:
			activity.configure_activity_layout(dimensions,true);await drain();check(Rect2(Vector2.ZERO,dimensions).encloses(Rect2(view.panel.position,view.panel.size)),"Final readable panel remains contained after resize")
		view.acknowledge();check(owner.d.chapter4.completed,"Actual issued nonce, saved choices and source duration complete only after acknowledgement")
		var snapshot:Dictionary=owner.d.duplicate(true);view.acknowledge();view.advance(100);check(owner.d==snapshot,"Repeated acknowledgement/tick does not create second completion")
		activity.queue_free();await drain()
	var issued:=request(owner);var activity:=Activity.new();root.add_child(activity);activity.setup(issued.game);activity.set_process(false);var view:Control=activity.lamp_view
	tick(view,1150);view.choose("purpose","seek_truth");tick(view,980);tick(view,1150)
	# Force only a stale owner, not a successful state mutation, to check rejection UI.
	request(owner);view.choose("person","responsible");tick(view,980)
	check(view.stage=="questions" and view.question_index==1 and view.phase=="entering" and not view.feedback.is_empty(),"Rejected stale session stays at second question with visible failure")
	check(not owner.d.chapter4.factIds.has("zhu_two_questions_answered"),"Rejected callback grants no answer fact")
	view.dispose();var t:float=view.stage_ms;tick(view,10000);check(view.stage_ms==t,"Disposed activity has no timer or late transition")
	activity.queue_free();await drain()
	for reduced in [false,true]:
		var f:=Sequence.frame(0,reduced);check(f.led==0 and f.core==0 and f.glow==0,"Lamp starts dark")
		check(f.rise==(1.0 if reduced else 0.0),"Reduced motion stays at final camera pose")
		var end:=Sequence.frame(3600 if reduced else 5800,reduced);check(is_equal_approx(end.led,.7) and is_equal_approx(end.core,.62) and is_equal_approx(end.glow,.26),"Original final playback light levels retained")
	print("CHAPTER4_LAMP_SOURCE_TESTS ",checks," checks; ",failures," failures");quit(1 if failures else 0)
