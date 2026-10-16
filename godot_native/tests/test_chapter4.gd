extends SceneTree
const Chapter = preload("res://scripts/chapters/chapter4.gd")
const Model = preload("res://scripts/games/chapter4_stair_model.gd")
const Activity = preload("res://scripts/games/chapter4_activity.gd")
const Stairs = preload("res://scripts/games/chapter4_stairs.gd")
var failures: int=0
var checks: int=0
func check(value: bool,message: String) -> void:
	checks+=1
	if not value: failures+=1; push_error(message)
func initial() -> Dictionary:
	var s: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json")); s.native={"chapter":4,"page":"c4_notes","scene":"","mode":"light","player":{},"settings":{},"log":[],"completed":[]}; return s
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var chapter=Chapter.new(); var s: Dictionary=initial()
	var result: Dictionary=chapter.dispatch(s,"c4_prologue")
	check(not result.has("game"),"Prologue cannot bypass lake/interlude")
	s.qizhenLake.phase="complete"; s.chapterThreeInterlude.phase="replay_ready"; s.chapterThreeInterlude.replayUnlocked=true
	result=chapter.dispatch(s,"c4_prologue"); check(result.has("game"),"Verified interlude opens authored prologue")
	chapter.dispatch(s,"c4_prologue_end",{"session":result.game.session,"elapsedMs":43834,"acknowledged":true})
	check(s.chapter4.prologueSeen and s.chapterThreeInterlude.completed,"Prologue handoff preserves prior state")
	check(not s.chapter4.factIds.has("opening_paper_at_noticeboard"),"Video completion does not catch paper")
	chapter.dispatch(s,"c4_arrive_a3",{"elapsedMs":2000}); check(s.chapter4.floor=="A1","No forged elevator transport")
	chapter.dispatch(s,"c4_stairs_complete",{"kind":"chapter4_stair_campaign","doorTraversed":true,"levels":[]}); check(not s.chapter4.factIds.has("misaligned_stair_solved"),"No fabricated stair completion")
	var source: Dictionary=Model.data(); var records: Array=[]
	for level in source.levels:
		var state: Dictionary=Model.initial(level); var camera: Dictionary=source.cameras[level.id]
		check(Model.path(level,state,camera,level.exitNodeId).is_empty(),level.id+" initial exit inaccessible")
		var steps: Array=[]
		if level.id=="stair_a":
			set_value(level,state,camera,"a_slide",1,steps); set_value(level,state,camera,"a_stair",0,steps); set_value(level,state,camera,"a_lift",1,steps); act(level,state,camera,{"type":"view","value":"south_west"},steps); act(level,state,camera,{"type":"walk","node":"A_EXIT"},steps)
		elif level.id=="stair_b":
			set_value(level,state,camera,"b_lower_stair",3,steps); set_value(level,state,camera,"b_mid_lift",0,steps); set_value(level,state,camera,"b_upper_stair",1,steps); set_value(level,state,camera,"b_exit_slide",2,steps); act(level,state,camera,{"type":"view","value":"south_west"},steps)
			act(level,state,camera,{"type":"walk","node":"B_MID_LIFT_LOW"},steps); set_value(level,state,camera,"b_mid_lift",2,steps); act(level,state,camera,{"type":"view","value":"top_oblique"},steps); act(level,state,camera,{"type":"walk","node":"B_EXIT"},steps)
		else:
			for index in range(level.ascentViewSequence.size()):
				var prefix: String=level.id+"_"+str(index+1)
				set_value(level,state,camera,prefix+"_rotate",0,steps); set_value(level,state,camera,prefix+"_transfer",0,steps); act(level,state,camera,{"type":"view","value":level.ascentViewSequence[index]},steps); act(level,state,camera,{"type":"walk","node":prefix+"_car"},steps); set_value(level,state,camera,prefix+"_transfer",2,steps)
				act(level,state,camera,{"type":"walk","node":level.exitNodeId if index==level.ascentViewSequence.size()-1 else prefix+"_transfer_exit"},steps)
		check(state.node==level.exitNodeId,level.id+" authored route playable")
		records.append({"id":level.id,"actions":steps})
	check(Model.validate_result({"kind":"chapter4_stair_campaign","levels":records,"doorTraversed":true}),"Complete four-level replay proof accepted")
	var truncated: Array=records.duplicate(true); truncated[3].actions.pop_back(); check(not Model.validate_result({"kind":"chapter4_stair_campaign","levels":truncated,"doorTraversed":true}),"Missing final door route rejected")
	s=initial(); s.chapter4.prologueSeen=true; s.chapter4.phase="room204_restore"; s.chapter4.timeState="1850_evening"; s.chapter4.factIds=["hour_hand_installed"]
	chapter.dispatch(s,"c4_elevator_ride"); check(s.chapter4.floor=="A1","Classrooms cannot be skipped")
	s.chapter4.mode="light"; result=chapter.dispatch(s,"c4_elevator_align"); check(result.has("game"),"Calibration independent from dark history")
	chapter.dispatch(s,"c4_elevator_aligned",{"session":result.game.session,"startSeconds":81811,"elapsedMs":6000,"boarded":true}); check(s.chapter4.factIds.has("elevator_history_calibrated"),"Exact trace accepted")
	s.chapter4.mode="dark"; chapter.dispatch(s,"c4_history"); check(s.chapter4.factIds.has("elevator_history_observed"),"History may follow calibration")
	s.chapter4.floor="A2"; chapter.dispatch(s,"c4_residual"); check(not s.chapter4.factIds.has("room204_residual_observed"),"A2 phase alone never grants stair proof")
	s.chapter4.phase="exterior_closure"; s.chapter4.floor="A1"; chapter.dispatch(s,"c4_closure_done",{"acknowledged":true,"playbackMs":5800}); check(not s.chapter4.completed,"Closure rejects missing prerequisites/session")
	full_chain(records)
	print("CHAPTER4_TESTS ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
func set_value(level: Dictionary,state: Dictionary,camera: Dictionary,id: String,target: int,steps: Array) -> void:
	var safety: int=0
	while int(state.values[id])!=target and safety<4:
		act(level,state,camera,{"type":"step","id":id,"delta":1},steps); safety+=1
func act(level: Dictionary,state: Dictionary,camera: Dictionary,action: Dictionary,steps: Array) -> void:
	check(Model.apply(level,state,camera,action),level.id+" action "+str(action)); steps.append(action)
func complete_game(chapter: RefCounted,s: Dictionary,request: Dictionary,proof: Dictionary={}) -> Dictionary:
	check(request.has("game") or request.has("world_effect"),"Expected game or in-world presentation request")
	if not request.has("game") and not request.has("world_effect"): return {}
	var config: Dictionary=request.get("game",request.get("world_effect",{}))
	var value: Dictionary={"session":config.session,"kind":config.kind,"elapsedMs":maxf(6000,float(config.get("durationMs",0))),"acknowledged":true,"boarded":true,"arrived":true,"fromFloor":s.chapter4.floor,"destination":config.get("destination","")}
	value.merge(proof,true)
	return chapter.dispatch(s,config.on_success,value)
func full_chain(records: Array) -> void:
	var chapter=Chapter.new(); var s: Dictionary=initial(); s.qizhenLake.phase="complete"; s.chapterThreeInterlude.phase="replay_ready"; s.chapterThreeInterlude.replayUnlocked=true; s.items.campusCard=true
	var request: Dictionary=chapter.dispatch(s,"c4_prologue"); request=complete_game(chapter,s,request,{"elapsedMs":43834}); complete_game(chapter,s,request)
	request=chapter.dispatch(s,"c4_catch_paper"); complete_game(chapter,s,request)
	request=chapter.dispatch(s,"c4_clock"); complete_game(chapter,s,request)
	chapter.dispatch(s,"c4_clock_set",{"time":"1225_bakery"}); check(s.chapter4.phase=="bakery_hour_hand","Clock gates bakery")
	complete_game(chapter,s,chapter.dispatch(s,"c4_lamp_switch")); chapter.dispatch(s,"c4_hour_hand"); chapter.dispatch(s,"c4_install_hour"); check(s.chapter4.timeState=="1225_bakery","Installing hour hand never silently changes time")
	chapter.dispatch(s,"c4_clock_set",{"time":"1850_evening"})
	s.chapter4.mode="dark"; chapter.dispatch(s,"c4_class104"); chapter.dispatch(s,"c4_history")
	s.chapter4.mode="light"; chapter.dispatch(s,"c4_class105"); chapter.dispatch(s,"c4_device_duty_board"); chapter.dispatch(s,"c4_solve_duty_board",{"a":"classroom_104","b":"classroom_105","c":"main_elevator"})
	complete_game(chapter,s,chapter.dispatch(s,"c4_elevator_align"),{"startSeconds":81811,"boarded":true}); complete_game(chapter,s,chapter.dispatch(s,"c4_elevator_ride")); check(s.chapter4.floor=="A3" and s.native.get("c4_elevator_transport",false),"Actual elevator transport required")
	s.chapter4.mode="dark"; chapter.dispatch(s,"c4_reference"); chapter.dispatch(s,"c4_record")
	complete_game(chapter,s,chapter.dispatch(s,"c4_stairs"),{"kind":"chapter4_stair_campaign","levels":records,"doorTraversed":true}); check(s.chapter4.floor=="A2","Campaign transports player to A2")
	# Active RpgInteractionContract requires both observations before grouped placement.
	s.chapter4.mode="light"
	for group in chapter.content.room204.groups: chapter.dispatch(s,"c4_group_"+group.id)
	check(s.chapter4.room204Placements.is_empty(),"Source active group targets reject missing residual observation")
	s.chapter4.mode="dark"; chapter.dispatch(s,"c4_residual"); chapter.dispatch(s,"c4_record")
	s.chapter4.mode="light"
	for group in chapter.content.room204.groups:
		s.native.player={"x":group.targetBounds.x+16,"y":group.targetBounds.y+40}
		chapter.dispatch(s,"c4_group_"+group.id)
	check(s.chapter4.factIds.has("room204_restored"),"Four physical groups plus observed source evidence complete restoration")
	s.chapter4.mode="light"; complete_game(chapter,s,chapter.dispatch(s,"c4_projection")); chapter.dispatch(s,"c4_plate")
	s.native.mode="light"
	chapter.dispatch(s,"c4_device_positioning_calibration")
	for event: Dictionary in [{"kind":"insert"},{"kind":"step","axis":"horizontal","delta":-1},{"kind":"step","axis":"horizontal","delta":-1},{"kind":"step","axis":"vertical","delta":1},{"kind":"step","axis":"pressure","delta":1},{"kind":"step","axis":"pressure","delta":1},{"kind":"step","axis":"pressure","delta":1}]:
		chapter.dispatch(s,"c4_plate_press_event",event)
	chapter.dispatch(s,"c4_solve_positioning_calibration",{"horizontal":-2,"vertical":1,"pressure":3})
	chapter.dispatch(s,"c4_device_power_topology"); var edges: Dictionary={}
	for edge in ["hall__west_corridor","hall__east_corridor","west_corridor__bakery_back_area","east_corridor__classroom_zone","bakery_back_area__classroom_zone"]: edges[edge]="on"
	chapter.dispatch(s,"c4_solve_power_topology",edges); chapter.dispatch(s,"c4_device_evacuation_route"); chapter.dispatch(s,"c4_solve_evacuation_route",{"a":"lecture_202_door","b":"east_corridor","c":"transport_core","d":"main_stair_down"})
	chapter.dispatch(s,"c4_deduce",{"arrival":"A3","unserved":"A2"})
	var floor_choice: Dictionary=chapter.dispatch(s,"c4_elevator")
	check(floor_choice.has("open_c4_floor_selection"),"Solved-state return offers original floor choice")
	if not floor_choice.has("open_c4_floor_selection"):return
	complete_game(chapter,s,chapter.dispatch(s,"c4_floor_select",{"session":floor_choice.open_c4_floor_selection.session,"destination":"A1"}));check(s.chapter4.floor=="A1","Selected original return elevator")
	chapter.dispatch(s,"c4_install_plate"); check(s.chapter4.phase=="maintenance_repair" and s.chapter4.timeState=="1850_evening","Positioning plate holds previous time pending clock")
	chapter.dispatch(s,"c4_clock_set",{"time":"2245_maintenance"}); chapter.dispatch(s,"c4_diagnose",{"wheel_sound":"latch","clock_jam":"gear_offset","oil_trace":"oil_shortage"}); chapter.dispatch(s,"c4_cart_cover"); chapter.dispatch(s,"c4_cart_oil")
	check(s.chapter4.factIds.has("clock_gear_repaired") and not s.items.universalLubricatingOil and not s.items.shortPryBar,"Maintenance linkage consumes both final-use tools")
	complete_game(chapter,s,chapter.dispatch(s,"c4_final_drag"),{"dragged":true}); check(s.chapter4.phase=="blackout_light_grid" and not s.items.attendanceRecordPaper,"Minute theft holds paper outside inventory")
	for zone in ["east_corridor","classroom_zone","bakery_back_area"]: chapter.dispatch(s,"c4_toggle_"+zone)
	chapter.dispatch(s,"c4_lock_power"); check(s.chapter4.phase=="final_chase" and s.chapter4.factIds.has("canruo_star_lamp_primed"),"Light-grid handoff only primes lamp")
	request=chapter.dispatch(s,"c4_chase")
	var chase_geometry:RefCounted=chapter._chase_geometry()
	var trace: Array=[]; var at: Vector2=chase_geometry.vec(chase_geometry.layout.landings[0].spawn); var time: float=0;var committed_landing:=0
	for target in chase_geometry.route.slice(1):
		while at.distance_to(target)>0.01:
			at=at.move_toward(target,20.8); time+=100; trace.append({"x":at.x,"y":at.y,"t":time})
			if committed_landing<2 and chase_geometry.gates[committed_landing].has_point(at):
				committed_landing+=1
				var progress:Dictionary=chapter.dispatch(s,"c4_chase_landing",{"session":request.game.session,"geometryVersion":request.game.geometryVersion,"expectedAttempt":s.chapter4.chaseAttempt,"landing":committed_landing,"path":trace.duplicate(true),"elapsedMs":time})
				check(progress.get("accepted",false),"Original stair platform committed in order")
	complete_game(chapter,s,request,{"geometryVersion":request.game.geometryVersion,"expectedAttempt":s.chapter4.chaseAttempt,"path":trace,"escaped":true,"elapsedMs":time}); check(s.chapter4.floor=="A2" and s.chapter4.chaseStairwellStage=="complete","Physical stair trace validates both landings and exit")
	chapter.dispatch(s,"c4_reach202"); chapter.dispatch(s,"c4_final_minute"); check(s.items.finalMinute and s.items.attendanceRecordPaper,"Minute and attendance paper recovered together")
	chapter.dispatch(s,"c4_return_stair"); chapter.dispatch(s,"c4_install_minute"); check(s.chapter4.phase=="morning_checkin" and int(s.chapter4.worldTimeSeconds)==28500,"Recovered minute restores exact 07:55")
	chapter.dispatch(s,"c4_checkin_paper"); check(not s.chapter4.completed,"One check-in input cannot complete chapter")
	chapter.dispatch(s,"c4_checkin_card"); check(s.chapter4.phase=="exterior_closure" and not s.chapter4.completed,"Both check-in inputs still require explicit closure")
	request=chapter.dispatch(s,"c4_lamp_start"); check(request.has("game"),"Unlit two questions opens only after check-in")
	chapter.dispatch(s,"c4_lamp_answers",{"session":request.game.session,"answers":{"purpose":"seek_truth","person":"clear_minded"}})
	check(s.chapter4.factIds.has("zhu_two_questions_answered") and not s.chapter4.completed,"Questions persist before playback without ending chapter")
	complete_game(chapter,s,request,{"consumer":"ChapterFourStarLampClosure","answers":{"purpose":"seek_truth","person":"clear_minded"},"playbackMs":5800,"acknowledged":true})
	check(s.chapter4.completed and s.chapter4.exteriorClosureAcknowledged and s.items.campusCard and s.items.attendanceRecordPaper,"Explicit questions/playback/ack completes without resetting items")
	check(s.native.page=="phone_home" and s.runtimeMode=="phone","Completion returns existing phone home")
