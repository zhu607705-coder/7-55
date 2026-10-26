extends "res://tests/test_chapter4_device_main.gd"
const Motion=preload("res://scripts/presentation/chapter4_time_feedback_model.gd")
const Fixture=preload("res://tests/helpers/chapter4_time_feedback_fixture.gd")
var action_count:=0

func mount(kind: String,view:=Vector2i(1280,720),phone_only:=false,reduced:=false) -> void:
	if is_instance_valid(shell): await shell.shutdown();shell.queue_free();await frames(3)
	Fixture.prepare(state_node,kind);state_node.d.native.settings.reduced_motion=reduced
	root.size=view;shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell)
	shell._refresh();await frames(5)
	if phone_only: shell._show_phone_surface()
	else: shell._show_world_mobile()
	await frames(3)
	check(shell.chapter4_time_feedback.cue.is_empty(),"loading a checkpoint does not play a feedback effect")

func earn(kind: String) -> void:
	state_node.act(Fixture.action(kind));await frames(2)
	if kind=="restoration":
		var original: Control=shell.world_effect
		check(is_instance_valid(original) and original.kind=="projection","original projection owns the existing proof")
		if is_instance_valid(original):
			original.set_process(false);original.elapsed_ms=0
			for i in 17:original._process(.05)
			check("room204_projection_completed" not in state_node.d.chapter4.factIds,"850ms cannot earn projection")
			shell.chapter4_time_feedback.cancel()
			check("room204_projection_completed" not in state_node.d.chapter4.factIds,"new visual skip cannot acknowledge the old proof")
			original._process(.05)
	await frames(3)
	var feedback: Control=shell.chapter4_time_feedback
	check(feedback.cue==kind,"real accepted controller action starts "+kind)
	if is_instance_valid(feedback.motion): feedback.motion.pause()
	feedback.set_process(false)

func run() -> void:
	state_node=root.get_node("State");state_node.developer_mode=true
	state_node.action_completed.connect(func(_a,_b,_c,_d):action_count+=1)
	state_node.d=state_node.initial();root.size=Vector2i(390,844)
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(5)
	check(shell.chapter4_time_feedback==null,"C1 Main does not eagerly load a Chapter4 presentation host or layout")
	check(Motion.RECORD_SECONDS-Motion.REPLAY_SECONDS==475,"replay is older by7m55, not the six-second elevator travel")
	for kind: String in Motion.FACTS:
		for i in 121:
			var pose:=Motion.sample(kind,i/100.0)
			check(is_finite(pose.minute_angle) and pose.alpha>=0 and pose.alpha<=1 and pose.settle>=0 and pose.settle<=1,"bounded finite timeline "+kind+str(i))
		var still:=Motion.sample(kind,0,true)
		for t in [.1,.4,.9]:
			var later:=Motion.sample(kind,t,true)
			check(still.offset==later.offset and still.minute_angle==later.minute_angle and still.alpha==later.alpha and later.phone_alpha==1,"reduced-motion static result "+kind)
	for view: Vector2i in [Vector2i(1280,720),Vector2i(390,844),Vector2i(844,390)]:
		await mount("comparison",view,true)
		await earn("comparison")
		var feedback: Control=shell.chapter4_time_feedback
		shell._sync_story_hosts();shell._sync_story_hosts()
		check(shell.chapter4_time_feedback==feedback and state_node.action_completed.get_connections().filter(func(link):return link.callable.get_object()==feedback).size()==1,"C4 host is unique and subscribes exactly once")
		check(not feedback.baseline_world_visible,"comparison remains on the already-visible phone")
		check(not shell.mobile_world,"comparison never forces world navigation")
		var geometry: Dictionary=feedback.comparison_layout()
		check(feedback.surface_rect().encloses(Rect2(geometry.origin,Vector2(geometry.width,geometry.height))),"two strips fit actual phone surface "+str(view))
		check(feedback.font.get_string_size("07:47:05",HORIZONTAL_ALIGNMENT_LEFT,-1,21).x<float(geometry.strip_width)-8,"full timestamp fits real narrow strip without clipping "+str(view))
		check(Rect2(Vector2.ZERO,Vector2(view)).encloses(feedback.skip_button.get_global_rect()),"skip target fits actual Window "+str(view))
		check(feedback.mouse_filter==Control.MOUSE_FILTER_IGNORE and feedback.clip_contents,"no input shield and no paint outside owning surface")
		check(not feedback.skip_button.has_focus(),"feedback never steals keyboard focus")
		var before:=JSON.stringify(state_node.d);var accepted:=action_count
		await mouse_click(feedback.skip_button)
		check(feedback.cue.is_empty() and JSON.stringify(state_node.d)==before and action_count==accepted,"mouse skip is presentation-only")
		state_node.act("c4_history");await frames(2)
		check(feedback.cue.is_empty(),"repeated accepted observation does not replay feedback")
	await mount("restoration")
	await earn("restoration")
	var feedback: Control=shell.chapter4_time_feedback
	var before:=JSON.stringify(state_node.d);var accepted:=action_count
	feedback.skip_button.grab_focus();await press_key(KEY_ENTER)
	check(feedback.cue.is_empty() and JSON.stringify(state_node.d)==before and action_count==accepted,"focused keyboard skip never submits another action")
	check(shell.world.has_focus(),"keyboard skip restores the original world focus")
	var future_keys: Array=[]
	shell.world.gui_input.connect(func(event):
		if event is InputEventKey and event.pressed and event.keycode==KEY_SPACE:future_keys.append(event.keycode))
	shell.world.nearby={};await press_key(KEY_SPACE)
	check(future_keys.size()==1,"actual next Space still reaches world after keyboard skip")
	await mount("minute",Vector2i(390,844))
	await earn("minute")
	feedback=shell.chapter4_time_feedback
	check(state_node.d.chapter4.phoneStatusTimeSeconds==28500 and state_node.d.chapter4.phoneStatusTimeTrusted,"controller already committed trusted07:55; visual does not roll it back")
	check(not state_node.d.chapter4.checkinCardAccepted and not state_node.d.chapter4.checkinPaperAccepted,"install effect does not submit either independent proof")
	check(Motion.sample("minute",0).phone_alpha==0 and Motion.sample("minute",.8).phone_alpha>0,"clock settles before phone confirmation appears")
	var registration: Dictionary=feedback.source.finalClockRuntime.visualRegistration
	var p:=Vector2(registration.axis.x,registration.axis.y)
	var world_point: Vector2=(p-shell.world.camera)*shell.world.zoom+shell.world.size/2
	var expected: Vector2=shell.world_view.get_global_transform_with_canvas()*(world_point*shell.world_view.size/Vector2(shell.world_viewport.size))
	var actual: Vector2=feedback.get_global_transform_with_canvas()*(feedback._world_transform()*p)
	check(actual.distance_to(expected)<.01,"feedback uses actual SubViewport-to-display mapping, not unrelated root coordinates")
	for dimensions in [Vector2i(1280,720),Vector2i(844,390),Vector2i(390,844)]:
		root.size=dimensions;await frames(3);feedback._layout_feedback()
		var at: Vector2=feedback._world_transform()*p
		check(feedback.surface_rect().has_point(at),"actual source clock remains in frame at "+str(dimensions))
	before=JSON.stringify(state_node.d);accepted=action_count
	var touch:=InputEventScreenTouch.new();touch.position=feedback.skip_button.get_global_rect().get_center();touch.index=0
	touch.pressed=true;root.push_input(touch,true);await frames(1)
	touch.pressed=false;root.push_input(touch,true);await frames(2)
	check(feedback.cue.is_empty() and action_count==accepted and JSON.stringify(state_node.d)==before,"touch skip leaves earned state and future card/paper input alone")
	state_node.act("c4_checkin_card");await frames(1)
	check(state_node.d.chapter4.checkinCardAccepted and not state_node.d.chapter4.checkinPaperAccepted and state_node.d.chapter4.phase=="morning_checkin","card remains independently required after minute feedback")
	# Do not launch the existing exterior closure in this lifecycle test.
	await mount("minute",Vector2i(1280,720),false,true);await earn("minute")
	feedback=shell.chapter4_time_feedback
	check(feedback.reduced and feedback.presentation_sample().phone_alpha==1,"reduced mode shows settled clock/phone immediately")
	var owned: Dictionary=state_node.d;state_node.d=state_node.d.duplicate(true)
	feedback._process(.01)
	check(feedback.cue.is_empty(),"same-content state replacement/reload cancels stale owner")
	state_node.d=owned
	await mount("comparison");await earn("comparison");feedback=shell.chapter4_time_feedback
	state_node.d.chapter4.floor="A3";feedback._process(.01)
	check(feedback.cue.is_empty(),"floor exit cancels effect without replay")
	await mount("comparison");await earn("comparison");feedback=shell.chapter4_time_feedback
	shell.active_game=Control.new();shell.add_child(shell.active_game);feedback._process(.01)
	check(feedback.cue.is_empty(),"new minigame gets all future input; old feedback retires")
	shell.active_game.queue_free();shell.active_game=null
	await mount("comparison");await earn("comparison");feedback=shell.chapter4_time_feedback
	state_node.story_reset.emit();check(feedback.cue.is_empty() and feedback.seen.is_empty(),"story reset cancels and clears session-only dedupe")
	await mount("comparison",Vector2i(390,844),true)
	state_node.act("c4_history");state_node.d.native.page="wechat";await frames(3)
	check(shell.chapter4_time_feedback.cue.is_empty(),"same-frame page change invalidates a deferred earned-fact cue")
	await mount("comparison",Vector2i(390,844),true)
	state_node.act("c4_history");shell.active_game=Control.new();shell.add_child(shell.active_game);await frames(3)
	check(shell.chapter4_time_feedback.cue.is_empty(),"a game mounted before deferred start cannot be covered by feedback")
	shell.active_game.queue_free();shell.active_game=null
	await mount("comparison",Vector2i(390,844),true);await earn("comparison")
	feedback=shell.chapter4_time_feedback;state_node.d.native.page="wechat";feedback._process(.01)
	check(feedback.cue.is_empty(),"active phone feedback cancels when leaving its source page")
	var zero:=Control.new();shell.add_child(zero);feedback.phone=zero
	feedback._begin("comparison",feedback.serial,state_node.d,feedback._key(state_node.d),false)
	check(feedback.cue.is_empty() and feedback.motion==null,"zero-area surface refuses start without duration lookup or orphan tween")
	zero.queue_free();feedback.phone=shell.phone;shell.phone.hide()
	feedback._begin("comparison",feedback.serial,state_node.d,feedback._key(state_node.d),false)
	check(feedback.cue.is_empty() and feedback.motion==null,"invisible phone refuses start cleanly")
	await shell.shutdown();shell.queue_free();await frames(3)
	print("C4_TIME_FEEDBACK ",checks," checks; ",failures," failures; headless geometry/behavior only, not visual acceptance")
	quit(1 if failures else 0)
