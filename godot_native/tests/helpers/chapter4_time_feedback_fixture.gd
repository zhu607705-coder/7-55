extends RefCounted
## Explicit isolated QA checkpoints. Never imported by production code.
const Room=preload("res://scripts/games/chapter4_room204_model.gd")
static func prepare(state: Node,kind: String) -> void:
	state.begin_checkpoint("c4-755-classrooms-1850" if kind=="comparison" else ("c4-755-room204-1850" if kind=="restoration" else "c4-755-checkin"))
	var c: Dictionary=state.d.chapter4
	c.prologueSeen=true;c.factIds.erase("a1_time_route_compared" if kind=="comparison" else ("room204_projection_completed" if kind=="restoration" else "final_minute_installed"))
	state.d.native.settings.volume=0
	state.d.native.scene="duan_yongping_temporal_maze";state.d.rpgScene=state.d.native.scene
	if kind=="comparison":
		c.phase="room204_restore";c.floor="A1";c.mode="dark";state.d.native.mode="dark"
		c.factIds.erase("elevator_history_observed")
		for fact in ["classroom_104_chalk_residual_observed","classroom_105_terminal_replay_checked","elevator_history_calibrated"]:
			if fact not in c.factIds:c.factIds.append(fact)
		state.d.native.player={"x":778,"y":220}
	elif kind=="restoration":
		c.phase="room204_restore";c.floor="A2";c.mode="light";state.d.native.mode="light"
		for fact in ["a1_time_route_compared","a1_duty_board_reconstructed","a3_reference_observed","a3_identity_context_observed","misaligned_stair_solved","room204_residual_observed","room204_restored"]:
			if fact not in c.factIds:c.factIds.append(fact)
		c.room204Placements=[]
		for group: Dictionary in Room.data().groups:
			for mapping: Dictionary in group.mappings:c.room204Placements.append({"pieceId":mapping.pieceId,"slotId":mapping.slotId,"orientation":"up"})
		state.d.native.player={"x":1325,"y":430}
	else:
		c.phase="return_to_clock";c.floor="A1";c.mode="light";c.guardMode="absent";state.d.native.mode="light"
		c.timeState="0754_blackout";c.worldTimeSeconds=28440;c.buildingTimeSeconds=28440;c.phoneStatusTimeSeconds=28440;c.phoneStatusTimeTrusted=true
		c.checkinCardAccepted=false;c.checkinPaperAccepted=false
		for fact in ["checkin_card_accepted","checkin_paper_accepted","checkin_identity_verified"]:c.factIds.erase(fact)
		for fact in ["final_minute_recovered","attendance_record_recovered","a3_identity_context_observed"]:
			if fact not in c.factIds:c.factIds.append(fact)
		state.d.items.finalMinute=true;state.d.items.attendanceRecordPaper=true;state.d.items.campusCard=true
		state.d.chapterThreeInterlude.completed=true;state.d.chapterThreeInterlude.phase="complete"
		state.d.native.player={"x":996,"y":230}
	state.d.runtimeMode="rpg"
	# Native world restoration reads the scene/floor/time/phase position map,
	# not the compatibility player field alone. Seed the real source pose.
	var key: String=state.d.native.scene+":"+c.floor+":"+c.timeState+":"+c.phase
	state.d.native.positions={key:state.d.native.player.duplicate()}
	state.changed.emit()

static func action(kind: String) -> String:
	return "c4_history" if kind=="comparison" else ("c4_projection" if kind=="restoration" else "c4_install_minute")
