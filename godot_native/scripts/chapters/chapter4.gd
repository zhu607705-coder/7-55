extends RefCounted
const PlayerMetrics=preload("res://scripts/player_metrics.gd")
const Room204 = preload("res://scripts/games/chapter4_room204_model.gd")
const StairModel = preload("res://scripts/games/chapter4_stair_model.gd")
const ChaseStair=preload("res://scripts/games/chapter4_chase_stair_model.gd")
const ChaseGuard=preload("res://scripts/games/chapter4_guard_model.gd")
const SCENE = "duan_yongping_temporal_maze"
var content: Dictionary = {}
var layout: Dictionary = {}
var extra: Dictionary = {}
var context_source: Dictionary = {}
var timeline: Dictionary = {}
var pending: Dictionary = {}
var serial: int = 0
func _init() -> void:
	content=_json("chapter4-755.content.json"); layout=_json("chapter4-three-floor-maze.layout.json"); extra=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/chapter4-native-source.json")); timeline=_json("chapter4-temporal-maze.content.json").elevator.timeline
	context_source=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/chapter4-context-source.json"))
func _json(name: String) -> Dictionary:
	var result: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/"+name))
	return result if result is Dictionary else {}
func _active(s: Dictionary) -> bool:
	return int(s.get("native",{}).get("chapter",1))==4 or bool(s.get("chapter4",{}).get("prologueSeen",false)) or (s.get("chapterThreeInterlude",{}).get("phase","")=="replay_ready" and s.get("qizhenLake",{}).get("phase","")=="complete")
func _has(c: Dictionary,id: String) -> bool: return id in c.factIds
func _all(c: Dictionary,ids: Array) -> bool:
	for id in ids:
		if not _has(c,id): return false
	return true
func _fact(c: Dictionary,id: String) -> void:
	if not _has(c,id): c.factIds.append(id)
func _facts(c: Dictionary,ids: Array) -> void:
	for id in ids: _fact(c,id)
	if _all(c,["classroom_104_chalk_residual_observed","classroom_105_terminal_replay_checked","elevator_history_observed","elevator_history_calibrated"]): _fact(c,"a1_time_route_compared")
	if _placements_complete(c) and _all(c,["a3_reference_observed","room204_residual_observed"]): _fact(c,"room204_restored")
	if _all(c,["room204_restored","room204_projection_completed","a1_time_route_compared","a3_reference_observed","a3_identity_context_observed","room204_residual_observed"]): _facts_raw(c,["room204_projection_composite_completed","room202_endpoint_inferred","maintenance_incident_linked"])
	if _all(c,["light_grid_locked","room204_projection_composite_completed","room202_endpoint_inferred"]): _fact(c,"powered_route_confirmed")
func _facts_raw(c: Dictionary,ids: Array) -> void:
	for id in ids: _fact(c,id)
func _placements_complete(c: Dictionary) -> bool:
	if c.room204Placements.size()!=content.room204.pieceIds.size(): return false
	var pieces: Array=[]; var slots: Array=[]
	for p in c.room204Placements:
		if p.pieceId not in content.room204.pieceIds or p.slotId not in content.room204.slotIds or p.orientation!="up" or p.pieceId in pieces or p.slotId in slots: return false
		pieces.append(p.pieceId); slots.append(p.slotId)
	return true
func _phase(c: Dictionary,id: String,keep_time: bool=false) -> void:
	c.phase=id
	for contract in content.phaseContracts:
		if contract.id==id:
			c.timeAuthority=contract.timeAuthority; c.guardMode=contract.guardMode
			if not keep_time: _time(c,contract.timeState)
func _time(c: Dictionary,id: String) -> void:
	for entry in content.time.states:
		if entry.id==id:
			c.timeState=id; c.worldTimeSeconds=entry.worldTimeSeconds; c.buildingTimeSeconds=entry.worldTimeSeconds; c.phoneStatusTimeSeconds=entry.phoneStatusTimeSeconds; c.phoneStatusTimeTrusted=entry.phoneStatusTimeTrusted
func _required_time(c: Dictionary) -> String:
	if c.phase=="hall_clock_inspection" and _has(c,"hall_clock_inspected") and c.timeState=="2245_opening": return "1225_bakery"
	if c.phase=="room204_restore" and _has(c,"hour_hand_installed") and c.timeState!="1850_evening": return "1850_evening"
	if c.phase=="maintenance_repair" and _has(c,"positioning_plate_installed") and c.timeState!="2245_maintenance": return "2245_maintenance"
	return ""
func _aligned(c: Dictionary) -> bool:
	for p in content.phaseContracts:
		if p.id==c.phase: return p.timeState==c.timeState
	return false
func _go(s: Dictionary,floor: String,room: String="") -> void:
	s.chapter4.floor=floor
	s.chapter4.roomId=room if not room.is_empty() else {"A1":"a1_lobby","A2":"a2_corridor","A3":"a3_wayfinding"}[floor]
	s.native.chapter=4; s.native.scene=SCENE; s.native.page="c4_notes"; s.runtimeMode="rpg"; s.rpgScene=SCENE
	s.rpgCheckpoint={"A1":"c4_a1_lobby","A2":"c4_a2_corridor","A3":"c4_a3_wayfinding"}[floor]
	s.native.erase("c4_context")
func _ok(message: String="",append: Dictionary={}) -> Dictionary:
	var result: Dictionary={"handled":true,"message":message}; result.merge(append); return result
func _locked(code: String="current_phase_mismatch") -> Dictionary:
	return _ok(str(content.intentFeedback.details.get(code,{}).get("reason","当前条件尚未齐全。")))
func _mode(c: Dictionary,required: String) -> bool: return c.mode==required
func _dialogue(id: String) -> String:
	var lines: Array=[]
	for line in content.dialogues.get(id,[]): lines.append(line.text)
	return "\n".join(lines)
func _game(s: Dictionary,kind: String,action: String,options: Dictionary={}) -> Dictionary:
	serial+=1; var token: String="c4-%d-%d"%[Time.get_ticks_msec(),serial]
	pending={"kind":kind,"token":token,"action":action,"phase":s.chapter4.phase,"floor":s.chapter4.floor,"attempt":s.chapter4.chaseAttempt}
	var config: Dictionary={"script":"res://scripts/games/chapter4_activity.gd","kind":kind,"session":token,"on_success":action,"title":content.title,"settings":s.native.get("settings",{})}
	config.merge(options,true)
	return _ok("",{"game":config})

func _chase_activity(s:Dictionary,lead:float=650.0)->Dictionary:
	var landing:int=clampi(int(s.chapter4.chaseStairwellLanding),0,2)
	var entry:Dictionary=ChaseStair.guard_entry(landing,lead)
	var result:Dictionary=_game(s,"chase_stairwell","c4_chase_done",{"expectedAttempt":s.chapter4.chaseAttempt,"startLanding":landing,"guardLeadDistance":entry.leadDistance,"on_progress":"c4_chase_landing","on_failure":"c4_chase_failed","title":"楼梯间","body":_dialogue("chase.started")})
	pending.startLanding=landing;pending.guardDelayMs=entry.delayMs;pending.acceptedPath=[]
	return result

func _chase_session(s:Dictionary,value:Variant)->bool:
	if not _proof(s,"c4_chase_done",value):return false
	var attempt:Variant=value.get("expectedAttempt")
	if typeof(attempt) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(attempt)) or float(attempt)!=int(attempt):return false
	if typeof(value.get("elapsedMs")) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value.elapsedMs)):return false
	return s.chapter4.phase=="final_chase" and s.chapter4.floor=="A1" and s.chapter4.chaseStairwellStage=="inside" and int(attempt)==int(s.chapter4.chaseAttempt) and int(pending.get("attempt",-2))==int(s.chapter4.chaseAttempt)

func _commit_chase_pose(s:Dictionary,point:Vector2):
	# SaveStore must see the source restart/arrival pose before State emits its
	# later world_teleport signal; stale per-world positions cannot override it.
	if not s.native.has("positions"):s.native.positions={}
	var key:=SCENE+":"+str(s.chapter4.floor)+":"+str(s.chapter4.timeState)+":"+str(s.chapter4.phase)
	s.native.positions[key]={"x":point.x,"y":point.y}
	s.native.player={"scene":SCENE,"x":point.x,"y":point.y,"world_x":point.x,"world_y":point.y}
func _presentation(s: Dictionary,kind: String,action: String,options: Dictionary={}) -> Dictionary:
	var request: Dictionary=_game(s,kind,action,options)
	var config: Dictionary=request.game
	config.script="res://scripts/ui/chapter4_world_handoff.gd"; config.blocks_input=true
	config.fromFloor=s.chapter4.floor; config.phase=s.chapter4.phase
	config.player=s.native.get("player",{}).duplicate()
	if not config.player.has("x") or config.player.get("scene",SCENE)!=SCENE: config.player=layout.floors[int(str(s.chapter4.floor).trim_prefix("A"))-1].safeSpawn.duplicate()
	pending.durationMs=float(config.get("durationMs",0)); pending.destination=config.get("destination","")
	return _ok("",{"world_effect":config})
func _projection_ready(c: Dictionary) -> bool:
	return c.phase=="room204_restore" and c.floor=="A2" and not _has(c,"room204_projection_completed") and _all(c,["a1_time_route_compared","a1_duty_board_reconstructed","a3_reference_observed","a3_identity_context_observed","room204_residual_observed","room204_restored"]) and _placements_complete(c)
func _projection_issue(c: Dictionary) -> String:
	# Source getChapterFourIntentUnavailableReason preserves causal feedback;
	# the original readiness predicate above remains the acceptance authority.
	if c.phase!="room204_restore" or c.floor!="A2": return "current_phase_mismatch"
	if _has(c,"room204_projection_completed"): return "already_complete"
	if not _has(c,"a1_time_route_compared"): return "a1_comparison_required"
	if not _has(c,"a1_duty_board_reconstructed"): return "duty_board_required"
	if not _all(c,["a3_reference_observed","room204_residual_observed"]): return "room204_observations_required"
	return "room204_layout_incomplete"
func _room204_task(c: Dictionary) -> String:
	# Exact ordered selection from source QuestModel; labels remain in the
	# original content. This function observes facts and cannot complete them.
	if not _aligned(c): return "tune_clock_to_1850"
	if not _all(c,["classroom_104_chalk_residual_observed","classroom_105_terminal_replay_checked","elevator_history_observed","elevator_history_calibrated"]): return "resolve_a1_investigation"
	if not _has(c,"a3_reference_observed"): return "resolve_a3_archive_chain"
	if not _has(c,"misaligned_stair_solved"): return "solve_misaligned_stair"
	if not _all(c,["a2_positioning_plate_calibrated","a2_power_topology_recovered","a2_evacuation_route_confirmed"]): return "resolve_a2_inserted_puzzles"
	if not _has(c,"elevator_stop_chain_reconstructed"): return "resolve_elevator_stop_chain"
	if not _has(c,"a1_duty_board_reconstructed"): return "resolve_a1_investigation"
	if not _all(c,["room204_residual_observed","room204_restored"]): return "restore_room204"
	if not _has(c,"room204_projection_completed"): return "watch_room204_projection"
	if not _has(c,"positioning_plate_collected"): return "collect_positioning_plate"
	return "install_positioning_plate"
func _post_stair_floor_allowed(c: Dictionary,destination: String) -> bool:
	if c.phase!="room204_restore" or c.floor not in ["A1","A2","A3"] or destination not in ["A1","A2","A3"] or destination==c.floor or not _has(c,"misaligned_stair_solved"): return false
	if destination!="A1" and not _all(c,["classroom_104_chalk_residual_observed","classroom_105_terminal_replay_checked"]): return false
	if destination=="A3" and not _has(c,"elevator_history_calibrated"): return false
	return true
func _floor_selection(s: Dictionary) -> Dictionary:
	var destinations: Array=[]
	for destination: String in ["A1","A2","A3"]:
		if _post_stair_floor_allowed(s.chapter4,destination): destinations.append(destination)
	if destinations.is_empty(): return _locked("classroom_checks_required")
	var issued: Dictionary=_game(s,"elevator_selection","c4_floor_select")
	var config: Dictionary=issued.game
	config.fromFloor=s.chapter4.floor;config.phase=s.chapter4.phase
	config.destinations=destinations;config.records=_records(s.chapter4)
	return _ok("",{"open_c4_floor_selection":config})
func _floor_arrival(s: Dictionary,destination: String,landing: Dictionary) -> Dictionary:
	pending={}
	_go(s,destination)
	# State saves the accepted result before emitting teleport. Persist this
	# same original landing first so an immediate reload cannot restore an old
	# room position from another visit.
	if not s.native.has("positions"): s.native.positions={}
	var key: String=SCENE+":"+destination+":"+s.chapter4.timeState+":"+s.chapter4.phase
	s.native.positions[key]={"x":landing.x,"y":landing.y}
	s.native.player={"scene":SCENE,"x":landing.x,"y":landing.y,"world_x":landing.x,"world_y":landing.y}
	return _ok("",{"scene":SCENE,"teleport":[landing.x,landing.y]})
func _elevator_duration(from: String,to: String) -> float:
	return 2720.0+abs(int(from.trim_prefix("A"))-int(to.trim_prefix("A")))*620.0
func _proof(s: Dictionary,action: String,value: Variant) -> bool:
	return value is Dictionary and pending.get("action","")==action and value.get("session","")==pending.get("token","missing") and s.chapter4.phase==pending.get("phase","") and s.chapter4.floor==pending.get("floor","")
func pages(s: Dictionary) -> Array:
	if not _active(s): return []
	var out: Array=[{"id":"c4_notes","label":"第四章 · 7:55"}]
	if s.native.has("c4_context"): out.append({"id":"c4_device","label":"现场装置"})
	if s.native.has("c4_bio"): out.append({"id":"c4_bio","label":"校史人物"})
	if s.chapter4.phase=="exterior_closure": out.append({"id":"c4_lamp","label":"灿若星辰灯"})
	return out
func view(page: String,s: Dictionary) -> Dictionary:
	if not _active(s): return {}
	var c: Dictionary=s.chapter4
	if page=="c4_notes":
		var phase_copy: Dictionary=content.presentation.phaseCopy.get(c.phase,{})
		return {"title":content.title,"body":str(phase_copy.get("currentDifference",""))+"\n"+str(s.native.get("c4_last_dialogue",""))}
	if page=="c4_bio":
		for person in extra.alumni:
			if person.id==s.native.get("c4_bio",""): return {"title":person.name+" · "+person.role,"body":"\n".join(person.biography)+"\n"+person.sourceLabel+"\n"+person.sourceUrl,"art":person.portraitUrl}
	if page=="c4_lamp": return {"title":"灿若星辰灯","body":"第一问：到浙大来做什么？\n第二问：将来毕业后要做什么样的人？","art":"res://assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_dark.png"}
	if page=="c4_device":
		var id: String=s.native.get("c4_context","")
		if extra.puzzles.has(id):
			var puzzle: Dictionary=extra.puzzles[id]; return {"title":puzzle.title,"body":puzzle.darkPrompt if c.mode=="dark" else puzzle.lightPrompt}
		match id:
			"clock": return {"title":"大厅旧钟","body":_dialogue("hall_clock.first_inspection")}
			"elevator": return {"title":"电梯乘客残影","body":"一楼门体持续开放八秒，完整覆盖六秒进入窗口。\n门体闭合后，轿厢指示立即由 1F 转为上行。"}
			"deduction": return {"title":"电梯停站记录","body":_records(c)}
			"maintenance": return {"title":"维修诊断","body":"推车起步时轮罩先响，车轮随后才停。\n秒轮到同一齿位会回弹，拨动后仍重复。\n轮轴边只有干涸油圈，地面没有新鲜滴落。"}
			"power":
				var statuses: Array=[]
				for zone in content.lightGrid.zones: statuses.append(zone.label+"："+("亮" if int(c.lightGrid.mask)&(1<<int(zone.bit)) else "暗"))
				return {"title":"五区配电面板","body":"\n".join(statuses)+"\n"+_dialogue("light_grid.evidence")}
	return {}
func _action(id: String,label: String,inputs: Array=[]) -> Dictionary:
	var out: Dictionary={"id":id,"label":label}
	if not inputs.is_empty(): out.inputs=inputs
	return out
func _field(id: String,label: String,options: Array) -> Dictionary: return {"id":id,"label":label,"type":"choice","options":options}
func _opt(value: String,label: String) -> Dictionary: return {"value":value,"label":label}
func actions(page: String,s: Dictionary) -> Array:
	if not _active(s): return []
	var c: Dictionary=s.chapter4
	if page=="c4_notes":
		if not c.prologueSeen: return [_action("c4_prologue","播放恢复回放")]
		return [_action("c4_enter","返回教学楼")]
	if page=="c4_lamp" and c.phase=="exterior_closure": return [_action("c4_lamp_start","走近未亮的灯")]
	if page!="c4_device" or not _aligned(c) and _required_time(c).is_empty(): return []
	var id: String=s.native.get("c4_context","")
	match id:
		"clock":
			if not _required_time(c).is_empty(): return [_action("c4_clock_set","确认钟面刻度",[_field("time","刻度",[_opt("1225_bakery","12:25"),_opt("1850_evening","18:50"),_opt("2245_maintenance","22:45")])])]
		"elevator":
			var out: Array=[]
			if c.mode=="dark": out.append(_action("c4_history","观察门体与乘客轨迹"))
			else:
				if not _has(c,"elevator_history_calibrated"): out.append(_action("c4_elevator_align","调节回放起点"))
				elif _all(c,["classroom_104_chalk_residual_observed","classroom_105_terminal_replay_checked"]): out.append(_action("c4_elevator_ride","走入电梯"))
			return out
		"deduction": return [_action("c4_deduce","提交停站判断",[_field("arrival","实际到站层",[_opt("A2","二楼"),_opt("A3","三楼")]),_field("unserved","未服务外呼层",[_opt("A2","二楼"),_opt("A3","三楼")])])]
		"maintenance":
			var choices: Array=[_opt("oil_shortage","缺油"),_opt("foreign_object","异物堵塞"),_opt("latch","卡扣"),_opt("power_loss","供电中断"),_opt("gear_offset","齿轮偏位")]
			return [_action("c4_diagnose","核对故障",[_field("wheel_sound","轮子声",choices),_field("clock_jam","钟壳卡顿",choices),_field("oil_trace","油迹",choices)])]
		"power":
			var out: Array=[]
			for zone in content.lightGrid.zones: out.append(_action("c4_toggle_"+zone.id,zone.label))
			out.append(_action("c4_lock_power","锁定供电")); return out
	if extra.puzzles.has(id) and c.mode=="light" and not _has(c,extra.puzzles[id].factId): return [_action("c4_solve_"+id,"确认装置设置",_puzzle_fields(id))]
	return []
func _puzzle_fields(id: String) -> Array:
	match id:
		"duty_board":
			var opts: Array=[_opt("main_elevator","主电梯"),_opt("classroom_105","105"),_opt("classroom_104","104")]
			return [_field("a","第一张",opts),_field("b","第二张",opts),_field("c","第三张",opts)]
		"archive_index": return [_field("yearBand","年份",[_opt("1977_1984","1977—1984"),_opt("1985_1990","1985—1990"),_opt("1991_1998","1991—1998")]),_field("floor","楼层",[_opt("A1","A1"),_opt("A2","A2"),_opt("A3","A3")]),_field("purpose","用途",[_opt("attendance","考勤"),_opt("wayfinding","入口导视"),_opt("maintenance","维修")])]
		"media_alignment": return [{"id":"xOffset","label":"横向","type":"number"},{"id":"yOffset","label":"纵向","type":"number"},{"id":"rotationQuarterTurns","label":"四分之一圈","type":"number"}]
		"positioning_calibration": return [{"id":"horizontal","label":"横向","type":"number"},{"id":"vertical","label":"纵向","type":"number"},{"id":"pressure","label":"压力","type":"number"}]
		"power_topology":
			var fields: Array=[]
			for edge in ["hall__west_corridor","hall__east_corridor","west_corridor__bakery_back_area","east_corridor__classroom_zone","bakery_back_area__classroom_zone","west_corridor__east_corridor","hall__classroom_zone"]:
				var words: Array=edge.split("__"); var labels: Dictionary={"hall":"大厅","west_corridor":"西走廊","east_corridor":"东走廊","classroom_zone":"教室区","bakery_back_area":"后场"}
				fields.append(_field(edge,labels[words[0]]+" ↔ "+labels[words[1]],[_opt("off","断开"),_opt("on","连接")]))
			return fields
		"evacuation_route":
			var opts: Array=[_opt("main_stair_down","主楼梯下行口"),_opt("transport_core","交通核心"),_opt("east_corridor","东走廊"),_opt("lecture_202_door","202 门口")]
			return [_field("a","第一块",opts),_field("b","第二块",opts),_field("c","第三块",opts),_field("d","第四块",opts)]
	return []
func dispatch(s: Dictionary,action: String,value: Variant=null) -> Dictionary:
	if not action.begins_with("c4_"): return {}
	if not _active(s): return _locked("prologue_requirements_unmet")
	var c: Dictionary=s.chapter4
	if action=="c4_prologue":
		if c.prologueSeen or s.qizhenLake.phase!="complete" or s.chapterThreeInterlude.phase!="replay_ready" or not s.chapterThreeInterlude.replayUnlocked: return _locked("prologue_requirements_unmet")
		return _game(s,"prologue","c4_prologue_end",{"durationMs":43834,"video":"res://assets/rpg/cinematics/chapter4-prologue/chapter35_to_chapter4_h3_transition.ogv"})
	if action=="c4_prologue_end":
		if not _proof(s,action,value) or float(value.get("elapsedMs",0))<43834 or not value.get("acknowledged",false): return _locked("prologue_requirements_unmet")
		c.prologueSeen=true; s.chapterThreeInterlude.phase="complete"; s.chapterThreeInterlude.completed=true; _phase(c,"opening_handoff"); _go(s,"A1"); pending={}
		return _presentation(s,"paper_flight","c4_paper_settled",{"durationMs":1900,"body":_dialogue("opening.paper_flight")})
	if not c.prologueSeen: return _locked("prologue_requirements_unmet")
	if action=="c4_enter":
		s.native.scene=SCENE; s.native.chapter=4; s.runtimeMode="rpg"; s.rpgScene=SCENE
		if c.phase=="opening_handoff" and not _has(c,"opening_paper_at_noticeboard"): return _presentation(s,"paper_flight","c4_paper_settled",{"durationMs":1900,"body":_dialogue("opening.paper_flight")})
		if c.phase=="opening_paper_caught" and not _has(c,"external_time_rejected"): return _presentation(s,"paper_pickup","c4_external_time",{"durationMs":7000})
		if c.phase=="hall_clock_inspection" and not _has(c,"hall_clock_inspected"): return _presentation(s,"hall_clock_inspection","c4_clock_inspected",{"durationMs":4700,"body":_dialogue("hall_clock.first_inspection")})
		return _ok("",{"scene":SCENE})
	if action=="c4_mode":
		c.mode="dark" if c.mode=="light" else "light"; s.native.mode=c.mode; return _ok("深色观察" if c.mode=="dark" else "浅色操作")
	if action=="c4_cancel_floor_selection":
		if value is Dictionary and pending.get("action","")=="c4_floor_select" and value.get("session","")==pending.get("token","missing"): pending={}
		return _ok()
	if action=="c4_cancel_presentation":
		if value is Dictionary and value.get("session","")==pending.get("token","missing"): pending={}
		return _ok()
	if c.completed: return _ok("第四章已完成。")
	if action=="c4_clock_set":
		if not value is Dictionary or c.floor!="A1" or c.mode!="light" or _required_time(c).is_empty(): return _locked("clock_adjustment_required")
		if value.get("time","")!=_required_time(c): return _ok("这个刻度没有停住。")
		_time(c,value.time); c.timeAuthority="hall_clock"
		if c.phase=="hall_clock_inspection": _phase(c,"bakery_hour_hand")
		s.native.erase("c4_context"); return _ok(_dialogue("hall_clock.first_pull"),{"scene":SCENE})
	# The source scene opens its clock panel locally before submitting the
	# time-change intent. Native admission must also reach that control while
	# a new phase still holds the preceding time; no other action is unlocked.
	var opening_required_clock: bool=action=="c4_clock" and c.floor=="A1" and c.mode=="light" and not _required_time(c).is_empty()
	if not _aligned(c) and not opening_required_clock: return _locked("clock_adjustment_required")
	if action.begins_with("c4_context_"):
		for entry in context_source.contexts:
			if action!="c4_context_"+entry.targetId: continue
			if c.phase not in entry.activePhases or c.floor!=entry.floor or c.roomId not in entry.roomAliases: return _locked()
			return _ok(str(entry.textByTimeState[c.timeState][c.mode]))
		return _locked()
	if action=="c4_paper_settled":
		if not _proof(s,action,value) or float(value.get("elapsedMs",0))<1900: return _locked()
		_fact(c,"opening_paper_at_noticeboard"); pending={}; return _ok(_dialogue("opening.paper_flight"),{"scene":SCENE})
	if action=="c4_catch_paper":
		if c.phase!="opening_handoff" or c.floor!="A1" or not _has(c,"opening_paper_at_noticeboard") or c.mode!="light": return _locked()
		_fact(c,"opening_paper_caught"); s.items.attendanceRecordPaper=true; _phase(c,"opening_paper_caught")
		return _presentation(s,"paper_pickup","c4_external_time",{"durationMs":7000})
	if action=="c4_external_time":
		if not _proof(s,action,value) or float(value.get("elapsedMs",0))<7000: return _locked()
		_fact(c,"external_time_rejected"); pending={}; return _ok("",{"scene":SCENE})
	if action=="c4_clock":
		if c.floor!="A1" or c.mode!="light": return _locked()
		if c.phase=="opening_paper_caught" and _has(c,"external_time_rejected"):
			_phase(c,"hall_clock_inspection"); return _presentation(s,"hall_clock_inspection","c4_clock_inspected",{"body":_dialogue("hall_clock.first_inspection"),"durationMs":4700})
		if not _required_time(c).is_empty(): s.native.c4_context="clock"; return _ok("",{"page":"c4_device"})
		return _locked()
	if action=="c4_clock_inspected":
		if not _proof(s,action,value) or not value.get("acknowledged",false) or float(value.get("elapsedMs",0))<4700: return _locked()
		_fact(c,"hall_clock_inspected"); s.native.c4_context="clock"; pending={}; return _ok("",{"page":"c4_device"})
	if action=="c4_lamp_switch":
		if c.phase!="bakery_hour_hand" or c.floor!="A1" or c.mode!="light" or _has(c,"bakery_hour_hand_exposed"): return _locked()
		_fact(c,"bakery_conveyor_lamp_inspected")
		return _presentation(s,"bakery_stop","c4_bakery_stopped",{"durationMs":700,"body":"传送带正在执行停机过程。"})
	if action=="c4_bakery_stopped":
		if not _proof(s,action,value) or float(value.get("elapsedMs",0))<700: return _locked()
		_facts(c,["bakery_conveyor_direction_observed","bakery_tool_location_observed","bakery_hour_hand_exposed"]); pending={}; return _ok("",{"scene":SCENE})
	if action=="c4_hour_hand":
		if c.phase!="bakery_hour_hand" or c.floor!="A1" or c.mode!="light" or not _has(c,"bakery_hour_hand_exposed") or s.items.oldClockHourHand: return _locked("hour_hand_required")
		_fact(c,"bakery_hour_hand_collected"); s.items.oldClockHourHand=true; return _ok(_dialogue("bakery.hour_hand_collected"))
	if action=="c4_install_hour":
		if c.phase!="bakery_hour_hand" or c.floor!="A1" or c.mode!="light" or not s.items.oldClockHourHand or not _all(c,["bakery_conveyor_lamp_inspected","bakery_hour_hand_exposed","bakery_hour_hand_collected"]): return _locked("hour_hand_required")
		s.items.oldClockHourHand=false; _fact(c,"hour_hand_installed"); _phase(c,"room204_restore",true); return _ok("金属时针装回后，钟面出现了一处新的稳定刻度。")
	if action in ["c4_class104","c4_class105"]:
		if c.phase!="room204_restore" or c.floor!="A1" or c.mode!=("dark" if action=="c4_class104" else "light"): return _locked()
		_facts(c,["classroom_104_chalk_residual_observed" if action=="c4_class104" else "classroom_105_terminal_replay_checked"])
		return _ok(_dialogue("classroom104.chalk_residual" if action=="c4_class104" else "classroom105.terminal_replay"))
	if action=="c4_floor_select":
		if not _proof(s,action,value) or not _post_stair_floor_allowed(c,str(value.get("destination",""))): return _locked("misaligned_stair_required")
		var destination: String=value.destination
		return _presentation(s,"elevator_ride","c4_floor_arrived",{"durationMs":_elevator_duration(c.floor,destination),"destination":destination,"body":"电梯正在运行。"})
	if action=="c4_floor_arrived":
		if not _proof(s,action,value) or float(value.get("elapsedMs",0))<float(pending.get("durationMs",INF)) or not value.get("boarded",false) or not value.get("arrived",false) or value.get("fromFloor","")!=c.floor or value.get("destination","")!=pending.get("destination","missing") or not _post_stair_floor_allowed(c,str(value.get("destination",""))): return _locked("elevator_calibration_required")
		var destination: String=value.destination
		if destination=="A3": s.native.c4_elevator_transport=true;s.native.c4_native_elevator_completed=true
		pending={}
		return _floor_arrival(s,destination,layout.floors[int(destination.trim_prefix("A"))-1].elevator.arrivalPosition)
	if action=="c4_elevator":
		if c.phase!="room204_restore": return _locked()
		if _has(c,"misaligned_stair_solved"): return _floor_selection(s)
		if c.floor=="A1": s.native.c4_context="elevator"; return _ok("",{"page":"c4_device"})
		if not _has(c,"misaligned_stair_solved"): return _locked("misaligned_stair_required")
		return _presentation(s,"elevator_ride","c4_return_elevator",{"durationMs":_elevator_duration(c.floor,"A1"),"destination":"A1","body":"电梯正在运行。"})
	if action=="c4_history":
		if c.phase!="room204_restore" or c.floor!="A1" or c.mode!="dark": return _locked("elevator_history_required")
		_facts(c,["elevator_history_observed"]); return _ok(_records(c))
	if action=="c4_elevator_align":
		if c.phase!="room204_restore" or c.floor!="A1" or c.mode!="light": return _locked("elevator_calibration_required")
		return _game(s,"elevator_alignment","c4_elevator_aligned",{"timeline":timeline})
	if action=="c4_elevator_aligned":
		if not _proof(s,action,value) or c.mode!="light" or int(value.get("startSeconds",-1))!=int(timeline.correctReplayStartSeconds) or float(value.get("elapsedMs",0))<6000 or not value.get("boarded",false): return _locked("elevator_calibration_required")
		c.elevatorSelectedStartSeconds=int(value.startSeconds); c.elevatorTrackAligned=true; c.elevatorPlayerBoarded=true; c.elevatorReplayAttempts+=1; _facts(c,["elevator_history_calibrated"]); pending={}; return _ok("乘客轨迹已对齐。",{"scene":SCENE})
	if action=="c4_elevator_ride":
		if c.phase!="room204_restore" or c.floor!="A1" or c.mode!="light" or not _all(c,["classroom_104_chalk_residual_observed","classroom_105_terminal_replay_checked","elevator_history_calibrated"]): return _locked("classroom_checks_required")
		return _presentation(s,"elevator_ride","c4_arrive_a3",{"durationMs":_elevator_duration(c.floor,"A3"),"destination":"A3","body":"电梯正在运行。"})
	if action in ["c4_arrive_a3","c4_return_elevator"]:
		if not _proof(s,action,value) or float(value.get("elapsedMs",0))<float(pending.get("durationMs",INF)) or not value.get("boarded",false) or not value.get("arrived",false) or value.get("fromFloor","")!=c.floor or value.get("destination","")!=pending.get("destination","missing"): return _locked("elevator_calibration_required")
		if action=="c4_arrive_a3":
			if not _has(c,"elevator_history_calibrated"): return _locked("elevator_calibration_required")
			s.native.c4_elevator_transport=true; s.native.c4_native_elevator_completed=true; _go(s,"A3")
		else:
			if not _has(c,"misaligned_stair_solved"): return _locked("misaligned_stair_required")
			_go(s,"A1")
		pending={}; return _ok("",{"scene":SCENE,"teleport":[787.5,204] if action=="c4_arrive_a3" else [772.5,204]})
	if action=="c4_reference":
		if c.phase!="room204_restore" or c.floor!="A3" or c.mode!="dark" or not bool(s.native.get("c4_elevator_transport",false)): return _locked("room204_observations_required")
		_facts(c,["a3_reference_observed","a3_identity_context_observed"]); return _ok(_dialogue("room204.a3_reference_recorded"))
	if action=="c4_front_desk":
		if c.floor!="A1" or c.phase not in layout.frontDeskRuntime.activePhases: return _locked()
		return _ok(_dialogue(_front_desk_dialogue(c)))
	if action=="c4_reference_teacher":
		if c.floor!="A3" or c.phase!="room204_restore": return _locked()
		return _ok(_dialogue("supportNpc.a3_recorded" if _has(c,"a3_reference_observed") else "supportNpc.a3_reference"))
	if action.begins_with("c4_bio_"):
		for person in extra.alumni:
			if person.id==action.trim_prefix("c4_bio_") and c.floor=="A"+str(int(person.floor)):
				s.native.c4_bio=person.id; return _ok("",{"page":"c4_bio"})
		return _locked()
	if action=="c4_stairs":
		if c.phase!="room204_restore" or c.floor!="A3" or not bool(s.native.get("c4_elevator_transport",false)) or not _has(c,"a3_reference_observed"): return _locked("room204_observations_required")
		if _has(c,"misaligned_stair_solved"):
			if not _post_stair_floor_allowed(c,"A2"): return _locked("classroom_checks_required")
			for landing in layout.floors[1].stairLandings:
				if landing.targetStoryFloor=="A3": return _floor_arrival(s,"A2",landing.arrivalPosition)
			return _locked("return_route_incomplete")
		var request: Dictionary=_game(s,"chapter4_stair_campaign","c4_stairs_complete",{"script":"res://scripts/games/chapter4_stairs.gd"})
		return request
	if action=="c4_stairs_complete":
		if not _proof(s,action,value) or not StairModel.validate_result(value): return _locked("misaligned_stair_required")
		_fact(c,"misaligned_stair_solved"); c.stairAlignmentSolved=true; s.native.c4_stair_proof=value.duplicate(true); pending={}; _go(s,"A2"); return _ok("",{"scene":SCENE})
	if action=="c4_residual":
		if c.phase!="room204_restore" or c.floor!="A2" or c.mode!="dark" or not _has(c,"misaligned_stair_solved"): return _locked("misaligned_stair_required")
		_facts(c,["room204_residual_observed"])
		if _projection_ready(c): return _presentation(s,"projection","c4_projection_done",{"durationMs":900})
		return _ok(_dialogue("room204.residual_recorded"))
	if action.begins_with("c4_group_"):
		if not Room204.group_available(s): return _locked("room204_observations_required")
		var id: String=action.trim_prefix("c4_group_"); var target: Dictionary={}
		for group in content.room204.groups:
			if group.id==id: target=group
		if target.is_empty(): return _locked("room204_unknown_group")
		var player: Dictionary=s.native.get("player",{})
		if not player.has("x") or not player.has("y") or Room204.distance(PlayerMetrics.foot_rect(Vector2(float(player.x),float(player.y))).get_center(),Room204.rect(target.targetBounds))>64: return _locked("too_far")
		var target_id: String=id; var orientation: String="up"
		if value!=null:
			if not value is Dictionary or value.get("groupId","")!=id: return _locked("room204_wrong_group")
			target_id=str(value.get("targetGroupId","")); orientation=str(value.get("orientation",""))
			var drop: Variant=value.get("drop")
			if not drop is Array or drop.size()!=2 or not Room204.rect(target.targetBounds).has_point(Vector2(float(drop[0]),float(drop[1]))): return _locked("room204_wrong_group")
		var result: Dictionary=Room204.group_result(c.room204Placements,id,target_id,orientation)
		if not result.accepted: return _locked(result.issue)
		c.room204Placements=result.placements; _facts(c,[])
		if _projection_ready(c): return _presentation(s,"projection","c4_projection_done",{"durationMs":900})
		return _ok(result.rationale,{"accepted":true})
	if action=="c4_projection":
		if not _projection_ready(c): return _locked(_projection_issue(c))
		return _presentation(s,"projection","c4_projection_done",{"durationMs":900,"body":_dialogue("room204.restored")})
	if action=="c4_projection_done":
		if not _proof(s,action,value) or float(value.get("elapsedMs",0))<900: return _locked()
		_facts(c,["room204_projection_completed"]); pending={}; return _ok("门框局部 / 楼层差 1",{"scene":SCENE})
	if action=="c4_plate":
		if c.phase!="room204_restore" or c.floor!="A2" or c.mode!="light" or not _has(c,"room204_projection_completed") or s.items.clockPositioningPlate: return _locked("room204_projection_required")
		_fact(c,"positioning_plate_collected"); s.items.clockPositioningPlate=true; return _ok("讲台抽屉已打开。")
	if action=="c4_record":
		if c.phase!="room204_restore" or c.mode!="dark": return _locked("elevator_floor_records_required")
		if c.floor=="A2" and _has(c,"misaligned_stair_solved"): _fact(c,"elevator_a2_call_record_observed")
		elif c.floor=="A3" and bool(s.native.get("c4_elevator_transport",false)): _fact(c,"elevator_a3_arrival_record_observed")
		else: return _locked("elevator_floor_records_required")
		return _ok(_records(c))
	if action=="c4_deduction":
		if c.phase!="room204_restore" or c.floor!="A2": return _locked()
		s.native.c4_context="deduction"
		var dialogue_key: String="supportNpc.a2_checks_required" if not _all(c,["classroom_104_chalk_residual_observed","classroom_105_terminal_replay_checked"]) else ("supportNpc.a2_reference_required" if not _has(c,"a3_reference_observed") else "supportNpc.a2_room204")
		return _ok(_dialogue(dialogue_key),{"page":"c4_device"})
	if action=="c4_deduce":
		if c.phase!="room204_restore" or c.mode!="light" or not _all(c,["elevator_history_observed","elevator_a2_call_record_observed","elevator_a3_arrival_record_observed"]): return _locked("elevator_floor_records_required")
		if not value is Dictionary or value.get("arrival","")!="A3" or value.get("unserved","")!="A2": return _ok("停站判断与门机记录不符。")
		_fact(c,"elevator_stop_chain_reconstructed"); return _ok("停站记录已核对。")
	if action.begins_with("c4_device_"):
		var id: String=action.trim_prefix("c4_device_")
		if not extra.puzzles.has(id) or c.phase!="room204_restore" or c.floor!=_puzzle_floor(id): return _locked()
		# The source opens the scanner to explain the missing film; submission stays gated.
		s.native.c4_context=id; return _ok("",{"page":"c4_device"})
	if action.begins_with("c4_solve_"):
		var id: String=action.trim_prefix("c4_solve_")
		if not extra.puzzles.has(id) or c.phase!="room204_restore" or c.floor!=_puzzle_floor(id) or c.mode!="light" or s.native.get("c4_context","")!=id: return _locked()
		if id=="media_alignment" and not _has(c,"a3_archive_film_retrieved"): return _locked("archive_film_required")
		if not _puzzle_correct(id,value): return _ok("设置与现场留下的痕迹不符。")
		_fact(c,extra.puzzles[id].factId); return _ok(extra.puzzles[id].successText)
	if action=="c4_install_plate":
		if c.phase!="room204_restore" or c.floor!="A1" or c.mode!="light" or not s.items.clockPositioningPlate or not _all(c,["room204_projection_composite_completed","positioning_plate_collected","a2_positioning_plate_calibrated","a2_power_topology_recovered","a2_evacuation_route_confirmed","elevator_stop_chain_reconstructed"]): return _locked("positioning_plate_required")
		s.items.clockPositioningPlate=false; _fact(c,"positioning_plate_installed"); _phase(c,"maintenance_repair",true); return _ok("定位片归位后，钟面又有一处刻度不再回弹。")
	if action=="c4_maintenance":
		if c.phase!="maintenance_repair" or c.floor!="A1" or _has(c,"cart_wheel_inspected") or not _has(c,"maintenance_incident_linked"): return _locked("maintenance_incident_required")
		s.native.c4_context="maintenance"; return _ok(_dialogue("maintenance.cleaner"),{"page":"c4_device"})
	if action=="c4_diagnose":
		if c.phase!="maintenance_repair" or c.floor!="A1" or c.guardMode!="patrol" or _has(c,"cart_wheel_inspected") or not value is Dictionary: return _locked()
		if value.get("wheel_sound","")!="latch" or value.get("clock_jam","")!="gear_offset" or value.get("oil_trace","")!="oil_shortage": return _ok("故障与痕迹还没有对应上。")
		_fact(c,"cart_wheel_inspected"); s.items.shortPryBar=true; return _ok("维修工具已备好。")
	if action=="c4_cart_cover":
		if c.phase!="maintenance_repair" or c.floor!="A1" or c.mode!="light" or _has(c,"cart_wheel_cover_opened") or not _has(c,"cart_wheel_inspected") or not s.items.shortPryBar: return _locked("cart_wheel_inspection_required")
		_fact(c,"cart_wheel_cover_opened"); s.items.shortPryBar=false; s.items.universalLubricatingOil=true; return _ok("轮罩已打开。")
	if action=="c4_cart_oil":
		if c.phase!="maintenance_repair" or c.floor!="A1" or c.mode!="light" or _has(c,"cart_wheel_repaired") or not _has(c,"cart_wheel_cover_opened") or not s.items.universalLubricatingOil: return _locked("cart_wheel_cover_required")
		_facts(c,["cart_wheel_repaired","clock_gear_repaired"]); s.items.universalLubricatingOil=false; return _ok("轮轴恢复转动，联动齿轮归位。")
	if action=="c4_final_drag":
		if c.phase!="maintenance_repair" or c.floor!="A1" or c.mode!="light" or not _has(c,"clock_gear_repaired") or not s.items.attendanceRecordPaper: return _locked("clock_gear_repair_required")
		return _presentation(s,"clock_drag","c4_minute_stolen",{"durationMs":1040,"body":"把旧钟拨向 07:55"})
	if action=="c4_minute_stolen":
		if not _proof(s,action,value) or not value.get("dragged",false) or float(value.get("elapsedMs",0))<1040: return _locked("final_clock_drag_not_armed")
		_fact(c,"paper_temporarily_out_of_inventory"); s.items.attendanceRecordPaper=false; c.lightGrid={"mask":6,"locked":false}; _phase(c,"blackout_light_grid"); pending={}; _go(s,"A1"); return _ok(_dialogue("blackout.minute_stolen"),{"scene":SCENE})
	if action=="c4_power":
		if c.phase!="blackout_light_grid" or c.mode!="light" or not _has(c,"paper_temporarily_out_of_inventory") or c.lightGrid.locked: return _locked("blackout_not_started")
		s.native.c4_context="power"; return _ok("",{"page":"c4_device"})
	if action.begins_with("c4_toggle_"):
		if c.phase!="blackout_light_grid" or c.mode!="light" or not _has(c,"paper_temporarily_out_of_inventory") or c.lightGrid.locked: return _locked("blackout_not_started")
		for zone in content.lightGrid.zones:
			if zone.id==action.trim_prefix("c4_toggle_"): c.lightGrid.mask=int(c.lightGrid.mask)^int(zone.toggleMask); return _ok()
		return _locked()
	if action=="c4_lock_power":
		if c.phase!="blackout_light_grid" or c.mode!="light" or not _has(c,"paper_temporarily_out_of_inventory") or c.lightGrid.locked or int(c.lightGrid.mask)!=13: return _ok("亮起的区域还没有连成需要的通路。")
		if not _all(c,["room204_projection_composite_completed","room202_endpoint_inferred","a2_power_topology_recovered","a2_evacuation_route_confirmed"]): return _locked("powered_route_required")
		_facts(c,["light_grid_locked","canruo_star_lamp_primed"]); c.lightGrid.locked=true; _phase(c,"final_chase"); _go(s,"A1"); c.chaseRestartCheckpoint="c4_a1_lobby"; return _ok(_dialogue("chase.started"),{"scene":SCENE,"teleport":[590,612]})
	if action=="c4_recover_patrol":
		if c.phase!="maintenance_repair" or c.guardMode!="patrol": return _locked()
		_go(s,"A1"); s.native.player={"x":836.0,"y":716.0}; return _ok("已回到大厅安全点。维修进度和道具均已保留。",{"scene":SCENE,"accepted":true,"teleport":[836,716]})
	if action=="c4_fail_chase":
		if c.phase!="final_chase" or not value is Dictionary or int(value.get("expectedAttempt",-1))!=int(c.chaseAttempt) or value.get("failureFloor",c.floor)!=c.floor: return _locked("chase_attempt_stale")
		var upstairs: bool=c.floor=="A2"
		c.chaseAttempt+=1; c.chaseStairwellStage="complete" if upstairs else "pending"; c.chaseStairwellLanding=0; c.chaseRestartCheckpoint="c4_a2_corridor" if upstairs else "c4_a1_lobby"
		_go(s,"A2" if upstairs else "A1");_commit_chase_pose(s,Vector2(966,214) if upstairs else Vector2(590,612));pending={}
		return _ok(_dialogue("chase.failed")+"\n"+_dialogue("chase.retry"),{"scene":SCENE,"accepted":true,"teleport":[966,214] if upstairs else [590,612]})
	if action=="c4_chase":
		if c.phase!="final_chase" or c.floor!="A1" or not _has(c,"powered_route_confirmed"): return _locked("powered_route_required")
		if c.chaseStairwellStage=="inside":return _locked("already_complete")
		var lead:=650.0
		if value is Dictionary:
			if int(value.get("expectedAttempt",-1))!=int(c.chaseAttempt):return _locked("chase_attempt_stale")
			if typeof(value.get("leadDistance",650)) not in [TYPE_INT,TYPE_FLOAT]:return _locked("chase_attempt_stale")
			lead=float(value.get("leadDistance",650))
			if not is_finite(lead):return _locked("chase_attempt_stale")
		c.chaseStairwellStage="inside"; c.chaseStairwellLanding=0
		return _chase_activity(s,lead)
	if action=="c4_chase_resume":
		if c.phase!="final_chase" or c.floor!="A1" or c.chaseStairwellStage!="inside" or not _has(c,"powered_route_confirmed"):return _locked("powered_route_required")
		return _chase_activity(s)
	if action=="c4_chase_landing":
		if not _chase_session(s,value):return _locked("chase_attempt_stale")
		if value.get("landing",-1) not in [1,2]:return _locked("stair_route_not_available")
		var next:int=int(value.get("landing",-1))
		if next!=int(c.chaseStairwellLanding)+1 or next not in [1,2]:return _locked("stair_route_not_available")
		if not ChaseStair.valid_trace(value.get("path"),int(pending.startLanding),next,false,float(value.get("elapsedMs",-1)),pending.acceptedPath):return _locked("stair_route_not_available")
		c.chaseStairwellLanding=next;pending.acceptedPath=value.path.duplicate(true)
		return _ok("",{"accepted":true,"landing":next})
	if action=="c4_chase_failed":
		if not _chase_session(s,value):return _locked("chase_attempt_stale")
		if typeof(value.get("captureMs")) not in [TYPE_INT,TYPE_FLOAT]:return _locked("stair_route_not_available")
		var capture_ms:=float(value.get("captureMs",0))
		if value.get("captured",false)!=true or not is_finite(capture_ms) or capture_ms<5200 or float(value.get("elapsedMs",0))<float(pending.guardDelayMs):return _locked("stair_route_not_available")
		if not ChaseStair.valid_trace(value.get("path"),int(pending.startLanding),-1,false,float(value.get("elapsedMs",-1)),pending.acceptedPath):return _locked("stair_route_not_available")
		var point:Vector2=ChaseStair.point(value.path.back());var guard_data:Variant=value.get("guard")
		if not guard_data is Dictionary:return _locked("stair_route_not_available")
		if typeof(guard_data.get("x")) not in [TYPE_INT,TYPE_FLOAT] or typeof(guard_data.get("y")) not in [TYPE_INT,TYPE_FLOAT]:return _locked("stair_route_not_available")
		var guard:Vector2=Vector2(float(guard_data.get("x",INF)),float(guard_data.get("y",INF)))
		if not ChaseStair.body_open(guard,Vector2(20,14)) or not ChaseGuard.chase_contact(guard,Rect2(point-PlayerMetrics.FOOT_SIZE/2,PlayerMetrics.FOOT_SIZE)):return _locked("stair_route_not_available")
		return dispatch(s,"c4_fail_chase",{"expectedAttempt":c.chaseAttempt,"failureFloor":c.floor})
	if action=="c4_chase_done":
		if not _chase_session(s,value):return _locked("chase_attempt_stale")
		if c.chaseStairwellLanding!=2 or int(value.get("failures",0))!=0:return _locked("stair_route_not_available")
		if not _chase_proof(value): return _locked("stair_route_not_available")
		c.chaseStairwellStage="complete";pending={};_go(s,"A2");_commit_chase_pose(s,Vector2(966,214))
		return _ok(_dialogue("chase.floor_changed"),{"accepted":true,"scene":SCENE,"teleport":[966,214]})
	if action=="c4_reach202":
		if c.phase!="final_chase" or c.floor!="A2" or c.chaseStairwellStage!="complete" or not _all(c,["light_grid_locked","powered_route_confirmed","room202_endpoint_inferred"]): return _locked("powered_route_required")
		_fact(c,"room202_route_reached"); _phase(c,"final_minute_recovery"); c.roomId="a2_room_202"
		s.rpgCheckpoint="c4_a2_room202"
		var spawn: Dictionary=layout.finalMinuteRuntime.recoveryPlayerSpawn
		return _ok(_dialogue("chase.arrived"),{"teleport":[spawn.x,spawn.y]})
	if action=="c4_final_minute":
		if c.phase!="final_minute_recovery" or c.floor!="A2" or c.roomId!="a2_room_202" or c.mode!="light" or _has(c,"final_minute_recovered") or s.items.finalMinute or not _all(c,["paper_temporarily_out_of_inventory","powered_route_confirmed","room202_endpoint_inferred","room202_route_reached"]): return _locked("final_minute_not_recovered")
		s.items.finalMinute=true; s.items.attendanceRecordPaper=true; _facts(c,["final_minute_recovered","attendance_record_recovered"]); _phase(c,"return_to_clock"); return _ok(_dialogue("lecture.final_minute_recovered")+"\n"+_dialogue("lecture.recovered_result"))
	if action=="c4_return_stair":
		if c.phase!="return_to_clock" or c.floor!="A2": return _locked("return_route_incomplete")
		_go(s,"A1"); return _ok("",{"scene":SCENE})
	if action=="c4_install_minute":
		if c.phase!="return_to_clock" or c.floor!="A1" or c.mode!="light" or c.guardMode!="absent" or not s.items.finalMinute or not s.items.attendanceRecordPaper or not s.items.campusCard or not _has(c,"final_minute_recovered") or not s.chapterThreeInterlude.completed or s.chapterThreeInterlude.phase!="complete": return _locked("final_minute_not_recovered")
		s.items.finalMinute=false; _fact(c,"final_minute_installed"); _phase(c,"morning_checkin"); c.roomId="a1_checkin"; return _ok(_dialogue("morning.entry"))
	if action in ["c4_checkin_card","c4_checkin_paper"]:
		if c.phase!="morning_checkin" or c.floor!="A1" or c.mode!="light" or not _all(c,["final_minute_installed","a3_identity_context_observed","attendance_record_recovered"]) or not s.chapterThreeInterlude.completed: return _locked("checkin_requirements_incomplete")
		if action=="c4_checkin_card":
			if not s.items.campusCard: return _locked()
			c.checkinCardAccepted=true; _fact(c,"checkin_card_accepted")
		else:
			if not s.items.attendanceRecordPaper: return _locked()
			c.checkinPaperAccepted=true; _fact(c,"checkin_paper_accepted")
		if c.checkinCardAccepted and c.checkinPaperAccepted:
			_fact(c,"checkin_identity_verified"); _phase(c,"exterior_closure"); c.roomId="a1_exterior"; return _ok("外面亮了一下。",{"page":"c4_lamp"})
		return _ok("记录已接受。")
	if action=="c4_lamp_start":
		if not _closure_ready(s): return _locked("closure_prerequisites_incomplete")
		var duration_ms:int=3600 if s.native.get("settings",{}).get("reduced_motion",false) else 5800
		var result:=_game(s,"star_lamp_closure","c4_closure_done",{"questions":extra.questions,"durationMs":duration_ms,"answersSaved":_has(c,"zhu_two_questions_answered"),"selectedAnswers":c.zhuQuestionAnswers})
		# Bind the authored accessibility duration to this issued session, never to client proof.
		pending.durationMs=duration_ms
		return result
	if action=="c4_lamp_answers":
		if not _closure_ready(s) or _has(c,"zhu_two_questions_answered") or not value is Dictionary or pending.get("action","")!="c4_closure_done" or value.get("session","")!=pending.get("token","missing"): return _locked("closure_session_unverified")
		var choices: Variant=value.get("answers",{})
		if not choices is Dictionary or choices.get("purpose","") not in ["seek_truth","solve_real_problems","serve_public"] or choices.get("person","") not in ["responsible","clear_minded","public_service"]: return _locked("zhu_two_questions_required")
		c.zhuQuestionAnswers=choices.duplicate(); _fact(c,"zhu_two_questions_answered"); return _ok("",{"accepted":true})
	if action=="c4_closure_done":
		if not _closure_ready(s) or not _has(c,"zhu_two_questions_answered") or not _proof(s,action,value) or not value.get("acknowledged",false) or value.get("consumer","")!="ChapterFourStarLampClosure": return _locked("closure_session_unverified")
		var playback:Variant=value.get("playbackMs")
		if not (playback is int or playback is float) or not is_finite(float(playback)) or float(playback)<float(pending.get("durationMs",5800)):return _locked("closure_session_unverified")
		var answers: Variant=value.get("answers",{})
		if not answers is Dictionary or answers.get("purpose","") not in ["seek_truth","solve_real_problems","serve_public"] or answers.get("person","") not in ["responsible","clear_minded","public_service"]: return _locked("zhu_two_questions_required")
		if c.zhuQuestionAnswers!=answers: return _locked("zhu_two_questions_required")
		_facts(c,["exterior_closure_acknowledged"]); c.exteriorClosureAcknowledged=true; c.completed=true; _phase(c,"complete"); s.native.c4_closure_proof=value.duplicate(true)
		# Persist the session's checked mode, never an untrusted client marker.
		s.native.c4_closure_proof.playbackMode="reduced_motion" if int(pending.get("durationMs",5800))==3600 else "normal"
		s.native.scene=""; s.native.page="phone_home"; s.runtimeMode="phone"; s.currentScene="phone_home"; pending={}
		return _ok(_dialogue("exterior.closure"),{"page":"phone_home"})
	return _locked()
func _puzzle_floor(id: String) -> String:
	return "A1" if id=="duty_board" else ("A3" if id in ["archive_index","media_alignment"] else "A2")
func _puzzle_correct(id: String,value: Variant) -> bool:
	if not value is Dictionary: return false
	match id:
		"duty_board": return [value.get("a"),value.get("b"),value.get("c")]==["classroom_104","classroom_105","main_elevator"]
		"archive_index": return value.get("yearBand")=="1991_1998" and value.get("floor")=="A3" and value.get("purpose")=="wayfinding"
		"media_alignment": return str(value.get("xOffset","")) in ["2","2.0"] and str(value.get("yOffset","")) in ["-1","-1.0"] and str(value.get("rotationQuarterTurns","")) in ["1","1.0"]
		"positioning_calibration": return str(value.get("horizontal","")) in ["-2","-2.0"] and str(value.get("vertical","")) in ["1","1.0"] and str(value.get("pressure","")) in ["3","3.0"]
		"power_topology":
			for edge in ["hall__west_corridor","hall__east_corridor","west_corridor__bakery_back_area","east_corridor__classroom_zone","bakery_back_area__classroom_zone"]:
				if value.get(edge,"off")!="on": return false
			return value.get("west_corridor__east_corridor","off")=="off" and value.get("hall__classroom_zone","off")=="off"
		"evacuation_route": return [value.get("a"),value.get("b"),value.get("c"),value.get("d")]==["lecture_202_door","east_corridor","transport_core","main_stair_down"]
	return false
func _records(c: Dictionary) -> String:
	var lines: Array=[]
	if _has(c,"elevator_history_observed"): lines.append("一楼门体持续开放八秒，完整覆盖六秒进入窗口。\n门体闭合后，轿厢指示立即由 1F 转为上行。")
	if _has(c,"elevator_a2_call_record_observed"): lines.append("二楼下行外呼在 18:50:04 被按下，按钮持续亮到 18:50:12。\n同一时间段没有二楼门机开启记录，层显由 1F 直接跳到 3F。")
	if _has(c,"elevator_a3_arrival_record_observed"): lines.append("三楼到站铃在 18:50:12 响起，随后门机完整开启。\n轿厢内没有第二次起步记录，这里是离开一楼后的实际到站层。")
	return "\n\n".join(lines)
func _closure_ready(s: Dictionary) -> bool:
	var c: Dictionary=s.chapter4
	return c.phase=="exterior_closure" and c.floor=="A1" and c.roomId=="a1_exterior" and c.guardMode=="absent" and c.checkinCardAccepted and c.checkinPaperAccepted and _all(c,["checkin_card_accepted","checkin_paper_accepted","checkin_identity_verified","final_minute_installed","canruo_star_lamp_primed"]) and c.lightGrid.locked and c.timeState=="0755_morning" and int(c.worldTimeSeconds)==28500 and int(c.phoneStatusTimeSeconds)==28500 and c.phoneStatusTimeTrusted
func _inside(point: Vector2,r: Dictionary) -> bool: return point.x>=float(r.x) and point.x<=float(r.x)+float(r.width) and point.y>=float(r.y) and point.y<=float(r.y)+float(r.height)
func _chase_proof(result: Dictionary) -> bool:
	return result.get("escaped",false)==true and ChaseStair.valid_trace(result.get("path"),int(pending.get("startLanding",0)),2,true,float(result.get("elapsedMs",-1)),pending.get("acceptedPath",[]))
func _target(id: String,label: String,action: String,c: Dictionary,mode: String="",item: String="") -> Dictionary:
	var bounds: Dictionary={}; var radius: float=100.0
	for floor in layout.floors:
		if floor.storyFloor!=c.floor: continue
		for a in floor.anchors:
			if a.id==id: bounds=a.bounds
	for key in ["bakeryRuntime","maintenanceRuntime","morningCheckinRuntime"]:
		for entity in layout[key].get("targetEntities",[]):
			if entity.targetId==id: bounds=entity.installationBounds; radius=float(entity.proximity)
	if id=="a2_room204_residual_group": bounds=layout.room204Runtime.residualGroupBounds; radius=76
	if id=="a2_room204_podium_drawer": bounds=layout.room204Runtime.podium.drawerBounds; radius=60
	if id=="a1_hall_clock_minute_endpoint": bounds=layout.finalClockRuntime.endpoint.installationBounds; radius=float(layout.finalClockRuntime.endpoint.proximity)
	if id=="a1_power_panel": bounds=layout.lightGridRuntime.panel.installationBounds; radius=float(layout.lightGridRuntime.panel.proximity)
	if id=="a2_202_projection": bounds=layout.finalMinuteRuntime.installationBounds; radius=float(layout.finalMinuteRuntime.proximity)
	if bounds.is_empty(): return {}
	if id.begins_with("a1_hall_clock"): radius=maxf(radius,148)
	if id=="a1_front_desk_attendant": radius=104
	if id in ["a2_elevator_attendant","a3_reference_teacher"]: radius=92
	var result: Dictionary={"id":id,"label":label,"action":action,"position":[float(bounds.x)+float(bounds.width)*0.5,float(bounds.y)+float(bounds.height)*0.5],"bounds":[bounds.x,bounds.y,bounds.width,bounds.height],"radius":radius}
	if not mode.is_empty(): result.mode=mode
	if not item.is_empty(): result.item=item
	return result
func targets(scene: String,s: Dictionary) -> Array:
	if scene!=SCENE or not _active(s) or not s.chapter4.prologueSeen: return []
	var c: Dictionary=s.chapter4; var out: Array=[]
	if not _required_time(c).is_empty(): return [_target("a1_hall_clock","大厅旧钟","c4_clock",c,"light")]
	if not _aligned(c): return []
	if c.floor=="A1":
		match c.phase:
			"opening_handoff":
				if _has(c,"opening_paper_at_noticeboard"): out.append(_target("a1_noticeboard_paper","签到记录纸条","c4_catch_paper",c,"light"))
			"opening_paper_caught","hall_clock_inspection": out.append(_target("a1_hall_clock","大厅旧钟","c4_clock",c,"light"))
			"bakery_hour_hand":
				if not _has(c,"bakery_hour_hand_exposed"): out.append(_target("a1_bakery_inspection_lamp","检修灯开关","c4_lamp_switch",c,"light"))
				elif not _has(c,"bakery_hour_hand_collected"): out.append(_target("a1_bakery_hour_hand_pickup","旧时针","c4_hour_hand",c,"light"))
				if s.items.oldClockHourHand: out.append(_target("a1_hall_clock_hour_hand_socket","旧钟时针插槽","c4_install_hour",c,"light","oldClockHourHand"))
			"room204_restore":
				out.append(_target("a1_classroom_104_blackboard_residual","104 黑板擦痕残留","c4_class104",c,"dark"))
				out.append(_target("a1_classroom_105_lectern_terminal","105 讲台回放终端","c4_class105",c,"light"))
				out.append(_target("a1_front_desk_duty_board","前台值班签到板","c4_device_duty_board",c))
				if s.items.clockPositioningPlate: out.append(_target("a1_hall_clock_positioning_plate_slot","旧钟定位盘插槽","c4_install_plate",c,"light","clockPositioningPlate"))
			"maintenance_repair":
				if not _has(c,"cart_wheel_inspected"): out.append(_target("a1_cleaning_cart_wheel_inspection","清洁车轮轴","c4_maintenance",c))
				elif s.items.shortPryBar: out.append(_target("a1_cleaning_cart_wheel_cover","清洁车轮罩","c4_cart_cover",c,"light","shortPryBar"))
				elif s.items.universalLubricatingOil: out.append(_target("a1_cleaning_cart_wheel","清洁车轮轴","c4_cart_oil",c,"light","universalLubricatingOil"))
				if _has(c,"clock_gear_repaired"): out.append(_target("a1_hall_clock_minute_endpoint","大厅旧钟表盘","c4_final_drag",c,"light"))
			"blackout_light_grid": out.append(_target("a1_power_panel","一楼配电面板","c4_power",c,"light"))
			"return_to_clock": out.append(_target("a1_hall_clock_minute_endpoint","大厅旧钟表盘","c4_install_minute",c,"light","finalMinute"))
			"morning_checkin":
				if not c.checkinCardAccepted: out.append(_target("a1_campus_card_reader","校园卡读卡器","c4_checkin_card",c,"light","campusCard"))
				if not c.checkinPaperAccepted: out.append(_target("a1_attendance_paper_slot","签到记录纸槽","c4_checkin_paper",c,"light","attendanceRecordPaper"))
			"exterior_closure": out.append({"id":"exterior_lamp","label":"灿若星辰灯","position":[838,865],"radius":150,"action":"c4_lamp_start"})
	if c.floor=="A2":
		if c.phase=="room204_restore" and _has(c,"misaligned_stair_solved"):
			if not _has(c,"room204_residual_observed"): out.append(_target("a2_room204_residual_group","204 教室残影组","c4_residual",c,"dark"))
			for group in content.room204.groups:
				if not Room204.group_available(s): continue
				var complete: bool=true
				for mapping in group.mappings:
					var found: bool=false
					for p in c.room204Placements:
						if p.pieceId==mapping.pieceId: found=true
					if not found: complete=false
				if complete: continue
				var b: Dictionary=group.targetBounds
				out.append({"id":"a2_room204_group_"+group.id,"label":group.label,"position":[float(b.x)+16,float(b.y)+16],"bounds":[b.x,b.y,b.width,b.height],"radius":64,"action":"c4_group_"+group.id,"mode":"light"})
			if _has(c,"room204_restored") and not _has(c,"room204_projection_completed"): out.append(_target("a2_room204_podium_drawer","讲台投影","c4_projection",c))
			elif _has(c,"room204_projection_completed") and not _has(c,"positioning_plate_collected"): out.append(_target("a2_room204_podium_drawer","讲台抽屉","c4_plate",c,"light"))
			out.append(_target("a2_201_calibration_bench","定位板校准夹具","c4_device_positioning_calibration",c))
			out.append(_target("a2_203_circuit_terminal","五区拓扑终端","c4_device_power_topology",c))
			out.append(_target("a2_open_study_evacuation","夜间疏散路线板","c4_device_evacuation_route",c))
			out.append(_target("a2_elevator_attendant","停站记录核对","c4_deduction",c,"light"))
		if c.phase=="final_chase": out.append(_target("a2_202_threshold","进入 202 并关门","c4_reach202",c,"light"))
		if c.phase=="final_minute_recovery": out.append(_target("a2_202_projection","黄铜分针组件","c4_final_minute",c,"light"))
	if c.floor=="A3" and c.phase=="room204_restore" and bool(s.native.get("c4_elevator_transport",false)):
		out.append(_target("a3_reference_classroom_layout","晨间教室布置参照","c4_reference",c,"dark"))
		out.append(_target("a3_301_archive_index","胶片索引抽屉","c4_device_archive_index",c))
		out.append(_target("a3_302_alignment_scanner","新旧影像对齐扫描台","c4_device_media_alignment",c))
	if c.floor=="A1" and c.phase in layout.frontDeskRuntime.activePhases: out.append(_target("a1_front_desk_attendant","前台值班助理","c4_front_desk",c))
	if c.floor=="A3" and c.phase=="room204_restore": out.append(_target("a3_reference_teacher","参照教室教师","c4_reference_teacher",c))
	for person in extra.alumni:
		if c.floor!="A"+str(int(person.floor)): continue
		var b: Dictionary=person.frameBounds
		out.append({"id":person.targetId,"label":person.name,"position":[float(b.x)+float(b.width)/2,float(b.y)+float(b.height)/2],"bounds":[b.x,b.y,b.width,b.height],"radius":72,"action":"c4_bio_"+person.id})
	if c.phase=="room204_restore":
		for floor in layout.floors:
			if floor.storyFloor!=c.floor: continue
			var e: Dictionary=floor.elevator
			var b: Dictionary=e.get("visibleBounds",{})
			if not b.is_empty():
				out.append({"id":"main_elevator","label":"主电梯","position":[float(b.x)+float(b.width)/2,float(b.y)+float(b.height)+35],"radius":120,"action":"c4_elevator"})
				if c.floor!="A1": out.append({"id":"elevator_record","label":"电梯门机记录","position":[float(b.x)+float(b.width)+60,float(b.y)+float(b.height)+35],"radius":100,"action":"c4_record","mode":"dark"})
	if (c.floor=="A3" and c.phase=="room204_restore") or (c.floor=="A1" and c.phase=="final_chase") or (c.floor=="A2" and c.phase=="return_to_clock"):
		out.append({"id":"main_stair","label":"主楼梯","position":[1090,274] if c.floor=="A3" else ([966,214] if c.floor=="A2" else [1001,214]),"radius":105,"action":"c4_stairs" if c.floor=="A3" else (("c4_chase_resume" if c.chaseStairwellStage=="inside" else "c4_chase") if c.phase=="final_chase" else "c4_return_stair")})
	for entry in context_source.contexts:
		if c.phase not in entry.activePhases or c.floor!=entry.floor or c.roomId not in entry.roomAliases: continue
		var target: Dictionary=_target(entry.anchorId,entry.label,"c4_context_"+entry.targetId,c)
		if not target.is_empty():
			target.id=entry.targetId; target.radius=float(entry.get("proximity",52)); out.append(target)
	return out.filter(func(t): return not t.is_empty())
func objective(s: Dictionary) -> String:
	if not _active(s): return ""
	var c: Dictionary=s.chapter4
	if c.completed: return "签到完成 · 7:55"
	if not c.prologueSeen: return "播放恢复回放"
	if not _required_time(c).is_empty(): return content.tasks["pull_hall_clock" if c.phase=="hall_clock_inspection" else ("tune_clock_to_1850" if c.phase=="room204_restore" else "tune_clock_to_2245")].label
	if c.phase=="bakery_hour_hand":
		# Source QuestModel selects the next existing task from the same earned
		# item/facts. Keep the phase's first task only before the conveyor stops.
		var task_key: String="install_hour_hand" if s.items.oldClockHourHand or _has(c,"bakery_hour_hand_collected") or _has(c,"hour_hand_installed") else ("collect_hour_hand" if _has(c,"bakery_hour_hand_exposed") else "explore_bakery")
		return str(content.tasks[task_key].label)
	if c.phase=="room204_restore": return str(content.tasks[_room204_task(c)].label)
	if c.phase=="exterior_closure":
		return str(content.tasks["acknowledge_exterior_closure" if _has(c,"zhu_two_questions_answered") else "answer_zhu_two_questions"].label)
	if c.phase=="morning_checkin":
		var card:bool=c.checkinCardAccepted and _has(c,"checkin_card_accepted")
		var paper:bool=c.checkinPaperAccepted and _has(c,"checkin_paper_accepted")
		return str(content.tasks["submit_attendance_paper" if card and not paper else ("read_campus_card" if paper and not card else "complete_checkin")].label)
	if c.phase=="return_to_clock":
		# Original QuestModel advances the existing task once the player has
		# actually returned to A1; querying guidance must not change progress.
		return str(content.tasks["install_final_minute" if c.floor=="A1" else "return_via_main_stair"].label)
	if c.phase=="maintenance_repair":
		if not _has(c,"cart_wheel_inspected"): return "检查清洁车与旧钟的故障"
		if not _has(c,"cart_wheel_cover_opened"): return "用短撬杆打开清洁车轮罩"
		if not _has(c,"clock_gear_repaired"): return "将润滑油用于清洁车轮轴"
		return "把旧钟拨向 07:55"
	for contract in content.phaseContracts:
		if contract.id==c.phase and not contract.taskKeys.is_empty(): return str(content.tasks.get(contract.taskKeys[0],{}).get("label",content.title))
	return content.title

func _front_desk_dialogue(c: Dictionary) -> String:
	if c.phase=="bakery_hour_hand": return "frontDesk.bakery"
	if c.phase=="morning_checkin": return "frontDesk.morning_checkin"
	if c.phase=="exterior_closure": return "frontDesk.exterior_closure"
	if _all(c,["classroom_104_chalk_residual_observed","classroom_105_terminal_replay_checked"]): return "frontDesk.classrooms_done"
	if _has(c,"classroom_104_chalk_residual_observed"): return "frontDesk.classroom_104_done"
	if _has(c,"classroom_105_terminal_replay_checked"): return "frontDesk.classroom_105_done"
	return "frontDesk.classrooms_none"
