extends RefCounted
## Native-input campaign segment. Receives the continuous runner's existing State.
## No initial state, source checkpoints, chapter flags, or fabricated proof writes.
## Device choices use controller intents; activities produce their own terminal proof.
const Handoff = preload("res://scripts/ui/chapter4_world_handoff.gd")
var effects: Array = []
var effect_listener: Callable

func run(r) -> void:
	if not r.check(r.state.d.qizhenLake.phase=="complete" and r.state.d.chapterThreeInterlude.phase=="replay_ready", "C4 inherits completed lake and unlocked interlude"): return
	effect_listener = func(config: Dictionary): effects.append(config.duplicate(true))
	r.state.world_effect_requested.connect(effect_listener)
	await campaign(r)
	if r.state.world_effect_requested.is_connected(effect_listener): r.state.world_effect_requested.disconnect(effect_listener)
	effect_listener=Callable()
	if is_instance_valid(r.game): r.game.free(); r.game=null
	if r.check(r.state.d.chapter4.completed, "C4 continuous native-input chapter completes"):
		r.completed_chapters.append(4)
		await r.boundary("chapter4")

func campaign(r) -> void:
	r.game=r.make_game(await act(r,"c4_prologue"))
	if r.game==null: return
	trace_cues(r,r.game)
	# Source's supported skip opens the task card; it cannot finish the chapter.
	if not press(r,r.game.controls,"跳过恢复回放"): return
	r.check(r.game.stage=="card" and r.game_results.is_empty(),"prologue skip still requires task-card acknowledgement")
	if not press(r,r.game.controls,"收下任务，进入第四章"): return
	r.check(r.game_results.size()==1 and r.state.d.chapter4.prologueSeen,"real prologue acknowledgement emits owned completion")
	free_game(r)
	await drain_effects(r)
	await mode(r,"light")
	await act(r,"c4_catch_paper")
	await act(r,"c4_clock")
	await act(r,"c4_clock_set",{"time":"1225_bakery"})
	await act(r,"c4_lamp_switch")
	await act(r,"c4_hour_hand")
	await act(r,"c4_install_hour")
	await act(r,"c4_clock_set",{"time":"1850_evening"})
	if not r.check(r.state.d.chapter4.phase=="room204_restore","native bakery stop and hour-hand chain"): return
	await mode(r,"dark")
	await act(r,"c4_class104")
	await act(r,"c4_history")
	await mode(r,"light")
	await act(r,"c4_class105")
	await puzzle(r,"duty_board",{"a":"classroom_104","b":"classroom_105","c":"main_elevator"})
	r.game=r.make_game(await act(r,"c4_elevator_align"))
	if r.game==null: return
	var elevator:Control=r.game.elevator_panel
	# The source panel adjusts one second per visible arrow; no HSlider remains.
	var shifts:int=int(r.game.config.timeline.correctReplayStartSeconds)-int(r.game.selection)
	for i in absi(shifts):
		if not press(r,elevator.controls,"延后 1 秒" if shifts>0 else "提前 1 秒"):return
	if not press(r,elevator.controls,"重放并校验"): return
	if not press(r,elevator.controls,"走入电梯"): return
	for i in range(120): r.game._process(.05)
	if not r.check(r.game_results.size()==1 and r.state.d.chapter4.elevatorTrackAligned,"actual one-second controls, replay, boarding and six-second calibration"): return
	r.trace.append({"nativeActivity":"elevator_alignment","result":r.game_results[0].duplicate(true)})
	free_game(r)
	await act(r,"c4_elevator_ride")
	if not r.check(r.state.d.chapter4.floor=="A3","world elevator callback arrives A3"): return
	await mode(r,"dark")
	await act(r,"c4_reference")
	await act(r,"c4_record")
	await mode(r,"light")
	await puzzle(r,"archive_index",{"yearBand":"1991_1998","floor":"A3","purpose":"wayfinding"})
	await puzzle(r,"media_alignment",{"xOffset":2,"yOffset":-1,"rotationQuarterTurns":1})
	r.game=r.make_game(await act(r,"c4_stairs"))
	if r.game==null: return
	await solve_stairs(r)
	if not r.check(r.game_results.size()==1 and r.state.d.chapter4.floor=="A2","all four actual stairs and door tweens submit validated route"): return
	r.trace.append({"nativeActivity":"chapter4_stair_campaign","result":r.game_results[0].duplicate(true)})
	free_game(r)
	await mode(r,"dark")
	await act(r,"c4_residual")
	await act(r,"c4_record")
	await mode(r,"light")
	for group in r.chapter4.content.room204.groups:
		# Explicit spatial test setup, not a claim that a human walked here.
		var at: Vector2=Vector2(float(group.targetBounds.x)+16,float(group.targetBounds.y)+40)
		r.state.d.native.player={"x":at.x,"y":at.y,"scene":"duan_yongping_temporal_maze"}
		r.trace.append({"spatialSetup":"Room204 group proximity","position":[at.x,at.y],"notManualNavigation":true})
		await act(r,"c4_group_"+group.id)
	if not r.check("room204_projection_completed" in r.state.d.chapter4.factIds,"last placement runs actual projection handoff"): return
	await act(r,"c4_plate")
	await puzzle(r,"positioning_calibration",{"horizontal":-2,"vertical":1,"pressure":3})
	var edges: Dictionary={}
	for edge in ["hall__west_corridor","hall__east_corridor","west_corridor__bakery_back_area","east_corridor__classroom_zone","bakery_back_area__classroom_zone"]: edges[edge]="on"
	await puzzle(r,"power_topology",edges)
	await puzzle(r,"evacuation_route",{"a":"lecture_202_door","b":"east_corridor","c":"transport_core","d":"main_stair_down"})
	await act(r,"c4_deduction")
	await act(r,"c4_deduce",{"arrival":"A3","unserved":"A2"})
	if not await return_to_hall(r):return
	await act(r,"c4_install_plate")
	await act(r,"c4_clock_set",{"time":"2245_maintenance"})
	await act(r,"c4_maintenance")
	await act(r,"c4_diagnose",{"wheel_sound":"latch","clock_jam":"gear_offset","oil_trace":"oil_shortage"})
	await act(r,"c4_cart_cover")
	await act(r,"c4_cart_oil")
	await act(r,"c4_final_drag")
	if not r.check(r.state.d.chapter4.phase=="blackout_light_grid" and not r.state.d.items.attendanceRecordPaper,"actual clock pointer gesture completes theft"): return
	await act(r,"c4_power")
	for zone in ["east_corridor","classroom_zone","bakery_back_area"]: await act(r,"c4_toggle_"+zone)
	await act(r,"c4_lock_power")
	r.game=r.make_game(await act(r,"c4_chase"))
	if r.game==null: return
	await solve_chase(r)
	if not r.check(r.game_results.size()==1 and r.state.d.chapter4.chaseStairwellStage=="complete","actual chase movement crosses both landings and emits escape proof"): return
	r.trace.append({"nativeActivity":"chase_stairwell","result":r.game_results[0].duplicate(true)})
	free_game(r)
	await act(r,"c4_reach202")
	await act(r,"c4_final_minute")
	await act(r,"c4_return_stair")
	await act(r,"c4_install_minute")
	await act(r,"c4_checkin_paper")
	r.check(not r.state.d.chapter4.completed,"paper check-in alone never completes chapter")
	await act(r,"c4_checkin_card")
	r.game=r.make_game(await act(r,"c4_lamp_start"))
	if r.game==null: return
	var lamp:Control=r.game.lamp_view
	# Source question entry/dissolve and saved-answer confirmation are part of
	# this integration route, before the unchanged 5.8-second normal playback.
	for i in range(23):r.game._process(.05)
	if not press(r,lamp.choices_grid,str(r.game.config.questions[0].options[0].label)):return
	for i in range(20):r.game._process(.05)
	for i in range(23):r.game._process(.05)
	if not press(r,lamp.choices_grid,str(r.game.config.questions[1].options[0].label)):return
	for i in range(20):r.game._process(.05)
	if not r.check(lamp.stage=="saved" and "zhu_two_questions_answered" in r.state.d.chapter4.factIds,"two actual native answer controls persist choices before playback"):return
	for i in range(22):r.game._process(.05)
	if not r.check(r.game.stage=="playback","source saved-answer confirmation precedes playback"):return
	for i in range(115): r.game._process(.05)
	r.check(r.game.stage=="playback" and not r.state.d.chapter4.completed,"closure remains pending before5800ms")
	r.game._process(.05)
	if not press(r,lamp.column,"继续"): return
	r.check(r.game_results.size()==1 and r.state.d.chapter4.exteriorClosureAcknowledged,"actual final button emits closure acknowledgement")
	r.trace.append({"nativeActivity":"star_lamp_closure","result":r.game_results[0].duplicate(true) if not r.game_results.is_empty() else {}})
	r.check(r.state.last_result.get("message","")==r.chapter4._dialogue("exterior.closure"),"original exterior closure sequence preserved")
	free_game(r)

func return_to_hall(r)->bool:
	var request:Dictionary=await act(r,"c4_elevator")
	if not r.check(request.has("open_c4_floor_selection"),"solved stairs offer the original floor selection"):return false
	var selector:Control=load("res://scripts/ui/chapter4_floor_panel.gd").new()
	var configured:bool=selector.configure(request.open_c4_floor_selection,func():return r.state.d,load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"))
	if not r.check(configured,"controller-issued floor selector configures"):selector.free();return false
	selector.selected_destination.connect(func(value:Dictionary):r.state.act("c4_floor_select",value))
	r.root.add_child(selector);selector.size=Vector2(430,820);await r.process_frame
	var picked:bool=press(r,selector.buttons.A1.get_parent(),str(selector.buttons.A1.text))
	if picked:picked=press(r,selector.primary.get_parent(),str(selector.primary.text))
	selector.free()
	if not picked:return false
	await drain_effects(r)
	return r.check(r.state.d.chapter4.floor=="A1","selected A1 return completes the original owned elevator travel")

func act(r,id: String,value: Variant=null) -> Dictionary:
	var result: Dictionary=await r.step(id,value)
	await drain_effects(r)
	return result

func mode(r,wanted: String) -> void:
	if r.state.d.chapter4.mode!=wanted: await act(r,"c4_mode")
	r.check(r.state.d.chapter4.mode==wanted,"C4 mode intent " + wanted)

func puzzle(r,id: String,value: Dictionary) -> void:
	await act(r,"c4_device_"+id)
	await act(r,"c4_solve_"+id,value)
	r.check(r.chapter4.extra.puzzles[id].factId in r.state.d.chapter4.factIds,"authored device solution " + id)

func press(r,container: Node,label: String) -> bool:
	for child in container.get_children():
		if child is Button and not child.is_queued_for_deletion() and child.text==label:
			if not r.check(child.is_visible_in_tree() and not child.disabled,"native button actionable: "+label):return false
			r.trace.append({"nativeButton":label})
			child.pressed.emit()
			return true
	r.check(false,"native button exists: " + label)
	return false

func free_game(r) -> void:
	if is_instance_valid(r.game): r.game.free()
	r.game=null

func trace_cues(r,activity: Control) -> void:
	if activity.has_signal("presentation_requested"):
		activity.presentation_requested.connect(func(id,payload): r.trace.append({"presentationCue":id,"payload":payload}))

func drain_effects(r) -> void:
	while not effects.is_empty():
		var config: Dictionary=effects.pop_front()
		var effect: Control=Handoff.new()
		r.root.add_child(effect)
		effect.set_process(false)
		config.read_state=func(): return r.state.d
		config.project_position=func(p): return Vector2(480,160)+(p-Vector2(996,63))*.85
		var delivered: Array=[]
		effect.event.connect(func(id,value):
			delivered.append({"action":id,"proof":value.duplicate(true)})
			r.state.act(id,value))
		effect.setup(config)
		if config.kind=="clock_drag":
			for i in range(5): effect._process(.05)
			r.check(effect.elapsed_ms==0 and r.state.d.items.attendanceRecordPaper,"clock waits for genuine gesture")
			var down:=InputEventMouseButton.new()
			down.button_index=MOUSE_BUTTON_LEFT; down.pressed=true
			down.position=effect.project_position.call(effect._clock_endpoint(effect.clock_angle))
			effect._gui_input(down)
			var motion:=InputEventMouseMotion.new()
			motion.position=effect.project_position.call(effect._clock_endpoint(240))
			effect._gui_input(motion)
			r.check(effect.clock_started,"actual endpoint grab and motion arms clock")
		for frame in range(1000):
			if effect.reported: break
			effect._process(.05)
		r.check(delivered.size()==1 and delivered[0].action==config.on_success,"actual world presentation " + config.kind)
		r.trace.append({"nativeWorldEffect":config.kind,"terminal":delivered,"controlledDeltaMs":50,"notManualPlaythrough":true})
		if not effect.reported: effect.cancel()
		await r.process_frame

func settle_stair(r) -> bool:
	var deadline: int=Time.get_ticks_msec()+30000
	while r.game.busy and Time.get_ticks_msec()<deadline: await r.process_frame
	return r.check(not r.game.busy,"native stair tween settled")

func mechanism(r,id: String,value: int) -> void:
	for turn in range(4):
		if int(r.game.state.values[id])==value: break
		await r.game._step(id,1)
	r.check(int(r.game.state.values[id])==value,"native stair mechanism " + id)

func solve_stairs(r) -> void:
	for index in range(4):
		if not await settle_stair(r): return
		var level: Dictionary=r.game.level.duplicate(true)
		r.check(r.game.level_index==index,"native stairs preserve sequential level index")
		if level.id=="stair_a":
			await mechanism(r,"a_slide",1)
			await mechanism(r,"a_stair",0)
			await mechanism(r,"a_lift",1)
			await r.game._change_view("south_west")
			await r.game._walk("A_EXIT")
		elif level.id=="stair_b":
			await mechanism(r,"b_lower_stair",3)
			await mechanism(r,"b_mid_lift",0)
			await mechanism(r,"b_upper_stair",1)
			await mechanism(r,"b_exit_slide",2)
			await r.game._change_view("south_west")
			await r.game._walk("B_MID_LIFT_LOW")
			await mechanism(r,"b_mid_lift",2)
			await r.game._change_view("top_oblique")
			await r.game._walk("B_EXIT")
		else:
			for stage_index in range(level.ascentViewSequence.size()):
				var prefix: String=level.id+"_"+str(stage_index+1)
				await mechanism(r,prefix+"_rotate",0)
				await mechanism(r,prefix+"_transfer",0)
				await r.game._change_view(level.ascentViewSequence[stage_index])
				await r.game._walk(prefix+"_car")
				await mechanism(r,prefix+"_transfer",2)
				await r.game._walk(level.exitNodeId if stage_index==level.ascentViewSequence.size()-1 else prefix+"_transfer_exit")
		r.trace.append({"nativeStairTraversed":level.id,"actualCampaignRecords":r.game.campaign.size()})

func solve_chase(r) -> void:
	var owned:Control=r.game
	# Main's native host owns this same nonce-checked progress/resolve seam.
	# The standalone campaign has no Main, so connect the controller callbacks.
	owned.progress_requested.connect(func(proof:Dictionary):
		if not is_instance_valid(owned) or r.game!=owned:return
		if proof.get("session","")!=owned.config.get("session","missing"):return
		var response:Dictionary=r.state.act(str(owned.config.on_progress),proof)
		r.trace.append({"nativeChaseLanding":proof.landing,"accepted":response.get("accepted",false)})
		owned.resolve_progress(response)
	)
	owned.attempt_failed.connect(func(proof:Dictionary):
		if not is_instance_valid(owned) or r.game!=owned:return
		if proof.get("session","")!=owned.config.get("session","missing"):return
		r.state.act(str(owned.config.on_failure),proof)
		r.check(false,"continuous source route was captured")
	)
	for target in [Vector2(989,826),Vector2(989,426),Vector2(784,426),Vector2(784,207),Vector2(715,207),Vector2(715,57)]:
		# Pointer positions come from the current visible camera, not the retired
		# full-plate miniature. Held pointer moves track the same world target.
		var view:Control=owned.chase_view
		var down:=InputEventMouseButton.new();down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true
		down.position=chase_pointer(view,target);owned._input(down)
		for frame in range(1000):
			if owned.done or owned.stage!="chase" or owned.player.distance_to(target)<8:break
			var motion:=InputEventMouseMotion.new();motion.position=chase_pointer(view,target);motion.button_mask=MOUSE_BUTTON_MASK_LEFT
			owned._input(motion);owned._process(.02)
		var up:=InputEventMouseButton.new();up.button_index=MOUSE_BUTTON_LEFT;up.pressed=false;up.position=chase_pointer(view,target);owned._input(up)
		r.trace.append({"nativeChasePointerTarget":[target.x,target.y],"actualPlayer":[owned.player.x,owned.player.y],"landings":owned.landing,"elapsedMs":owned.elapsed})
		if owned.done:break
		if not r.check(owned.stage=="chase" and owned.player.distance_to(target)<8,"native chase pointer reaches source waypoint"):return

func chase_pointer(view:Control,target:Vector2)->Vector2:
	var local:Vector2=view.world_root.position+target*view.factor
	var field:Rect2=view.field.grow(-2)
	return view.position+Vector2(clampf(local.x,field.position.x,field.end.x),clampf(local.y,field.position.y,field.end.y))
