extends SceneTree
const Chapter=preload("res://scripts/chapters/chapter3.gd")
const Model=preload("res://scripts/games/theater_shadow_rehearsal_model.gd")
const Proof=preload("res://tests/helpers/theater_rehearsal_proof.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("THEATER_REHEARSAL_CONTROLLER: "+label)
func initial() -> Dictionary:
	var s: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	s.native={"chapter":3,"scene":"theater_interior","page":"c3_theater","mode":"light","player":{"scene":"theater_interior","x":560,"y":206},"settings":{},"log":[],"completed":[]}
	s.runtimeMode="rpg";s.rpgScene="theater_interior";s.rpgCheckpoint="theater_auditorium"
	s.theaterHunt.merge({"active":true,"admitted":true,"phase":"program_search","mode":"light"},true)
	return s
func issue(c: RefCounted,s: Dictionary) -> Dictionary:
	var result: Dictionary=c.dispatch(s,"c3_rehearsal_begin")
	check(result.get("ephemeral",false) and result.has("game"),"ordinary physical entry issues ephemeral rehearsal")
	return result.get("game",{})
func run() -> void:
	for phase: String in Chapter.REHEARSAL_PHASES:
		var c=Chapter.new();var s: Dictionary=initial();s.theaterHunt.phase=phase
		var before: String=JSON.stringify(s);var config: Dictionary=issue(c,s)
		check(JSON.stringify(s)==before,"begin preserves entire original "+phase+" save")
		var result: Dictionary=c.dispatch(s,"c3_rehearsal_result",Proof.proof(config))
		check(result.get("rehearsalAccepted",false) and result.get("ephemeral",false) and JSON.stringify(s)==before,"legal three-scene replay has no original mainline/reward/save writes in "+phase)
		check(not c.dispatch(s,"c3_rehearsal_result",Proof.proof(config)).get("rehearsalAccepted",false),"one-shot finish cannot be reused")
	var c=Chapter.new();var s: Dictionary=initial();var target: Dictionary={}
	for entry: Dictionary in c.targets("theater_interior",s):
		if entry.id==Model.PUZZLE_ID:target=entry
	check(not target.is_empty() and target.action=="c3_rehearsal_begin" and target.position==[560,156],"visible side-wing prop routes through shared exact physical entry")
	for gate: String in ["distance","dark","unadmitted","phase","runtime","scene","rpg_scene"]:
		s=initial()
		match gate:
			"distance":s.native.player.x=1100;s.native.player.y=700
			"dark":s.native.mode="dark";s.theaterHunt.mode="dark"
			"unadmitted":s.theaterHunt.admitted=false
			"phase":s.theaterHunt.phase="spotlight_hunt"
			"runtime":s.runtimeMode="phone"
			"scene":s.native.scene="qizhen_lake"
			"rpg_scene":s.rpgScene="qizhen_lake"
		var before: String=JSON.stringify(s)
		check(not c.dispatch(s,"c3_rehearsal_begin").has("game") and JSON.stringify(s)==before,"entry rejects "+gate+" without mutation")
	for fault: String in ["empty","partial","nonce","digest","puzzle","owner","checkpoint","mode","phase","distance"]:
		s=initial();var config: Dictionary=issue(c,s);var value: Dictionary=Proof.proof(config)
		match fault:
			"empty":value.actions=[]
			"partial":value.actions.pop_back()
			"nonce":value.session.nonce="forged"
			"digest":value.layoutDigest="forged"
			"puzzle":value.puzzleId="forged"
			"owner":s=s.duplicate(true)
			"checkpoint":s.rpgCheckpoint="theater_stage"
			"mode":s.native.mode="dark"
			"phase":s.theaterHunt.phase="spotlight_hunt"
			"distance":s.native.player.x=1500
		var before: String=JSON.stringify(s);var result: Dictionary=c.dispatch(s,"c3_rehearsal_result",value)
		check(not result.get("rehearsalAccepted",false) and JSON.stringify(s)==before,"bad/stale "+fault+" proof preserves source state")
	s=initial();var first: Dictionary=issue(c,s);var second: Dictionary=issue(c,s)
	check(not c.cancel_rehearsal_session(first.session) and c.rehearsal_session.token==second.session,"old exact cancel cannot retire newer rehearsal")
	check(not c.dispatch(s,"c3_rehearsal_result",Proof.proof(first)).get("rehearsalAccepted",false) and c.rehearsal_session.token==second.session,"old result cannot consume new rehearsal")
	var before: String=JSON.stringify(s)
	check(c.cancel_rehearsal_session(second.session) and JSON.stringify(s)==before,"exact cancellation has no source-state mutation")
	check(not c.dispatch(s,"c3_rehearsal_result",Proof.proof(second)).get("rehearsalAccepted",false),"cancelled proof cannot finish")
	var config: Dictionary=issue(c,s);c.invalidate_rehearsal_session();s.native.mode="dark";s.native.mode="light"
	check(not c.dispatch(s,"c3_rehearsal_result",Proof.proof(config)).get("rehearsalAccepted",false),"mode invalidation prevents capability revival")
	config=issue(c,s);var fresh=Chapter.new()
	check(not fresh.dispatch(s,"c3_rehearsal_result",Proof.proof(config)).get("rehearsalAccepted",false),"reloaded controller does not restore runtime-only session")
	print("THEATER_REHEARSAL_CONTROLLER: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
