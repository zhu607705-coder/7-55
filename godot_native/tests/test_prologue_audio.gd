extends SceneTree
const Game = preload("res://scripts/games/prologue_interception.gd")
const Director = preload("res://scripts/media/audio_director.gd")
var checks: int = 0
var errors: int = 0
var events: Array = []
var results: Array = []
var game: Control
var audio: Node
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: errors += 1; push_error(message)
func tick(seconds: float) -> void:
	for index in range(int(round(seconds/.01))): game._process(.01)
func count(id: String) -> int:
	return events.filter(func(entry: Dictionary) -> bool: return entry.id==id).size()
func _initialize() -> void: call_deferred("run")
func voice_reached(asset: String) -> bool:
	var deadline: int=Time.get_ticks_msec()+3000
	while (audio.voice_asset!=asset or audio.scheduled.any(func(p: Dictionary) -> bool:return p.get("cue",{}).get("channel")=="voice" and p.get("cue",{}).get("asset")==asset)) and Time.get_ticks_msec()<deadline:
		await process_frame
	return audio.voice_asset==asset

func run() -> void:
	var state: Dictionary = {"native":{"page":"ending","settings":{"music":true,"effects":true,"volume":1}},"ui":{}}
	var initial: String=JSON.stringify(state)
	audio=Director.new(); root.add_child(audio); audio.setup(func() -> Dictionary: return state)
	game=Game.new(); game.size=Vector2(430,820); root.add_child(game); game.set_process(false)
	game.presentation_requested.connect(func(id: String,payload: Dictionary) -> void: events.append({"id":id,"payload":payload.duplicate(true)}); audio.cue(id,payload))
	game.finished.connect(func(result: Dictionary) -> void: results.append(result))
	game.start({"resume":true})
	await process_frame; await process_frame
	check(events[0]=={"id":"prologue_blackout_started","payload":{"durationMs":7000}},"source blackout starts with exact payload")
	check(audio.music_asset=="music_prologue_blackout" and audio.music.playing,"blackout has real source music")
	tick(6.99)
	check(count("prologue_narrator_intro")==0,"intro does not play before seven seconds")
	tick(.03); await create_timer(.15).timeout
	check(count("prologue_narrator_intro")==1 and audio.voice_asset=="vo_prologue_narrator_intro","seven-second transition plays exact narrated intro after120ms")
	check(game.intro_segments==["噗，哦抱歉，我没别的意思，只是……这看起来不像成功了对吧。","我想你只好乖乖起来滚去上课了。","祝你好运，孩子！我要走了！"],"narrator subtitle segments preserved from source")
	game._pause(); var frozen: float=game.elapsed; var playback: float=audio.voice.get_playback_position()
	tick(.5); await create_timer(.22).timeout
	check(game.elapsed==frozen and audio.voice.stream_paused,"pause freezes game and native narrator")
	check(absf(audio.voice.get_playback_position()-playback)<.04,"paused voice offset cannot drift")
	game._resume(); await process_frame
	check(not audio.voice.stream_paused and count("prologue_playback_resumed")==1,"resume continues same clip")
	# Source misses and retry emit exact events without waiting for narration callbacks.
	game._switch("intercept")
	for index in range(3):
		game.paddle=79
		while game.phase=="intercept": tick(.01)
		tick(.66)
	check(game.phase=="failed" and count("prologue_error_intercept_missed")==3 and count("prologue_error_round_failed")==1,"all misses/failure events follow actual collision results")
	check(events.filter(func(e: Dictionary) -> bool: return e.id=="prologue_error_intercept_missed")[2].payload=={"misses":3,"maxMisses":3},"third miss payload source parity")
	game._retry(); tick(1.51)
	check(await voice_reached("vo_prologue_narrator_intro"),"retry intro scheduled120ms has actually started before fast simulated catch")
	check(count("prologue_narrator_intro")==2,"retry replays source intro without blackout")
	for end_x in [24,78,50]:
		game.paddle=end_x
		while game.phase=="intercept": tick(.01)
		tick(.36)
	check(game.phase=="lock" and count("prologue_error_intercepted")==3 and count("prologue_error_lock_ready")==1,"three blocks emit source lock ready")
	game.holding=true; tick(1.41)
	await voice_reached("vo_prologue_narrator_caught")
	check(game.phase=="caught" and audio.voice_asset=="vo_prologue_narrator_caught","1400ms hold plays only narrator caught voice")
	var caught_count: int=events.size()
	tick(3.05); check(game.dialogue_index==1 and events.size()==caught_count,"first player response remains text-only")
	tick(1.1); check(game.dialogue_index==2 and events.size()==caught_count,"second player response remains text-only")
	tick(1.1); await process_frame; await process_frame
	check(count("prologue_narrator_bargain")==1 and audio.voice_asset=="vo_prologue_narrator_bargain","5200ms emits source bargain once")
	tick(3.7); await process_frame; await process_frame
	check(game.phase=="burst" and count("prologue_white_burst")==1,"8900ms emits source burst once")
	check(audio.scheduled.size()>=3,"burst preserves300/620/760ms scheduled effects/musicstop")
	game._pause(); var pending: int=audio.scheduled.size(); await create_timer(.85).timeout
	check(audio.scheduled.size()==pending,"pause freezes delayed burst cue offsets")
	game._resume(); await create_timer(.8).timeout
	check(audio.music==null,"resumed760ms burst stop occurs")
	tick(1.7)
	check(results.size()==1 and results[0].dialogueCount==4 and results[0].whiteoutCompleted,"audio never grants or blocks game proof")
	audio.cue("act2_entry_unlocked"); await process_frame; await process_frame
	game.queue_free(); await process_frame; await process_frame
	check(count("prologue_scene_closed")==1,"game destruction emits audio lifecycle close")
	check(audio.voice==null and audio.music_asset=="music_act2_search","closing old game stops narrator without stopping newchapter music")
	check(JSON.stringify(state)==initial,"audio and prologue presentation never write progression state")
	check(await audio.shutdown(),"all real audio playback resources released")
	audio.queue_free(); await process_frame; await process_frame
	print("NATIVE_PROLOGUE_AUDIO checks=",checks," errors=",errors)
	quit(1 if errors else 0)
