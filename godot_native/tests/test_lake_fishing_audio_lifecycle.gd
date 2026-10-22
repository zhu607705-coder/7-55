extends SceneTree
## Automated playback-owner fixture, not subjective hearing or earned catch evidence.
const Director=preload("res://scripts/media/audio_director.gd")
const Host=preload("res://scripts/ui/minigame_host.gd")
const Solver=preload("res://tests/campaign_fishing_solver.gd")
const Fishing=preload("res://scripts/games/rhythm_fishing_model.gd")
var checks:=0
var failures:=0
var audio: Node
var game: Control
var state: Dictionary
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error("FISHING AUDIO: "+label)
func frames(count: int=3) -> void:
	for i in range(count):await process_frame
func fresh_game() -> void:
	game=Host.new();root.add_child(game);game.set_process(false)
	game.presentation_requested.connect(audio.cue)
	game.setup({"type":"rhythm","spotId":"locker_key","chartId":"locker_key","session_id":77,"title":"锈蚀钥匙"})
	await frames()
func run() -> void:
	var store: Node=root.get_node("State");store.developer_mode=true;state=store.initial()
	state.native.chapter=3;state.native.scene="qizhen_lake";state.rpgScene="qizhen_lake";state.runtimeMode="rpg"
	state.native.settings={"music":true,"effects":true,"volume":1}
	audio=Director.new();root.add_child(audio);audio.setup(func():return state)
	await fresh_game()
	for cycle in range(2):
		game.begin();await frames()
		game.presentation_requested.emit("native_fishing_beat",{"beat":0,"offsetMs":500,"beatDurationSec":.5})
		game.presentation_requested.emit("qizhen_fishing_warning",{"sessionId":"77","kind":"tension_high"})
		await frames()
		game.toggle_pause();await frames()
		check(audio._paused_prefixes.has("native_fishing_") and audio._paused_prefixes.has("qizhen_fishing_"),"Pause owns both source and native fishing clocks")
		game.restart();await frames()
		check(not audio._paused_prefixes.has("native_fishing_") and not audio._paused_prefixes.has("qizhen_fishing_"),"Retry retires both pause keys")
		check(not audio.scheduled.any(func(e):return str(e.id).begins_with("native_fishing_") or str(e.id).begins_with("qizhen_fishing_")),"Retry leaves no old scheduled fishing cue")
		check(not audio.effects.any(func(e):return str(e.id).begins_with("native_fishing_") or str(e.id).begins_with("qizhen_fishing_")),"Retry retires old warning and beat effects")
		game.begin();await frames();game.toggle_pause();await frames()
		game.cancel_game();game.queue_free();await frames()
		var deadline:=Time.get_ticks_msec()+1500
		while Time.get_ticks_msec()<deadline and audio.music_asset!="music_qizhen_lakeside":await process_frame
		check(not audio._paused_prefixes.has("native_fishing_") and not audio._paused_prefixes.has("qizhen_fishing_"),"paused Exit releases both pause keys")
		check(audio.music_asset=="music_qizhen_lakeside" and is_instance_valid(audio.music) and audio.music.playing and not audio.music.stream_paused,"source lakeside score actually starts after paused Exit and host deletion")
		check(not audio.scheduled.any(func(e):return str(e.id).begins_with("qizhen_fishing_")),"Exit callback is not blocked in the old paused queue")
		await fresh_game()
		check(audio.music_asset=="music_qizhen_lakeside","Ready admission preserves returned lakeside score until Start")
	game.begin();await frames()
	check(audio.music_asset.is_empty(),"source Start stops score for rhythm audibility")
	game.queue_free();await frames()
	check(not audio._paused_prefixes.has("qizhen_fishing_"),"direct destruction leaves no paused source owner")
	await fresh_game();game.begin();await frames()
	var solved: RefCounted=Solver.new().solve_fishing("locker_key")
	check(Fishing.validate_result(solved.final_result,"locker_key"),"completion fixture has a genuine replay-validated input proof")
	game.model=solved;game._check_terminal()
	var delivered: Array=[]
	game.finished.connect(func(result: Dictionary):
		delivered.append(result.duplicate(true))
		audio.cue("qizhen_fishing_catch_completed",{"spotId":"locker_key"})
		game.queue_free()
	)
	game._process(.89)
	check(delivered.is_empty(),"original result hold remains before completion")
	game._process(.02);await frames()
	var completion_deadline:=Time.get_ticks_msec()+1500
	while Time.get_ticks_msec()<completion_deadline and audio.music_asset!="music_qizhen_lakeside":await process_frame
	check(delivered.size()==1 and Fishing.validate_result(delivered[0],"locker_key"),"completion emits the unchanged proof once")
	check(audio.music_asset=="music_qizhen_lakeside" and audio.music.playing and not audio.music.stream_paused,"host deletion cannot cancel the accepted catch return music")
	check(await audio.shutdown(),"audio resources retire before fixture exit")
	audio.queue_free();await frames()
	print("LAKE_FISHING_AUDIO_LIFECYCLE: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
