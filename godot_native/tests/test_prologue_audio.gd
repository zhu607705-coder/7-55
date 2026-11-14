extends SceneTree
const Game = preload("res://scripts/games/prologue_interception.gd")
const WordDriver=preload("res://tests/prologue_word_driver.gd")
const Director = preload("res://scripts/media/audio_director.gd")
var checks: int = 0
var errors: int = 0
var events: Array = []
var results: Array = []
var playbacks: Array = []
var game: Control
var audio: Node
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: errors += 1; push_error(message)
func tick(seconds: float) -> void:
	for index in range(int(round(seconds/.01))): game._process(.01)
func retry_round() -> void:
	game._process(0)
	var button: Button=game.retry_button
	check(button.is_visible_in_tree() and not button.disabled,"failed round offers an actually visible enabled retry control")
	var missed_before: int=game.misses
	var point: Vector2=button.get_global_rect().get_center()
	for down: bool in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down
		var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;root.push_input(motion,true)
		root.push_input(event,true);game._process(.01);await process_frame
	check(game.session.phase=="clue" and game.phase=="deploy" and game.misses==missed_before and results.is_empty(),"actual pointer retry restarts only the failed round without replaying or granting completion")
func count(id: String) -> int:
	return events.filter(func(entry: Dictionary) -> bool: return entry.id==id).size()
func _initialize() -> void: call_deferred("run")
func pending_voice(asset: String) -> Array:
	return audio.scheduled.filter(func(p: Dictionary) -> bool: return p.get("cue",{}).get("channel")=="voice" and p.get("cue",{}).get("asset")==asset)
func voice_ready(asset: String) -> bool:
	return audio.voice_asset==asset and is_instance_valid(audio.voice) and audio.voice.playing and pending_voice(asset).is_empty()
func voice_reached(asset: String) -> bool:
	# The director owns monotonic deadlines. SceneTreeTimer consumes frame delta,
	# including time from before it was created during an already-long frame.
	var deadline: int=Time.get_ticks_msec()+3000
	while not voice_ready(asset) and Time.get_ticks_msec()<deadline:
		await process_frame
	return voice_ready(asset)
func wait_msec(duration: int) -> void:
	var deadline: int=Time.get_ticks_msec()+duration
	while Time.get_ticks_msec()<deadline: await process_frame
func finish() -> void:
	if is_instance_valid(game):
		game.queue_free(); await process_frame; await process_frame
	check(await audio.shutdown(),"all real audio playback resources released")
	audio.queue_free(); await process_frame; await process_frame
	print("NATIVE_PROLOGUE_AUDIO checks=",checks," errors=",errors)
	quit(1 if errors else 0)

func run() -> void:
	root.size=Vector2i(430,820)
	var state: Dictionary = {"native":{"page":"ending","settings":{"music":true,"effects":true,"volume":1}},"ui":{}}
	var initial: String=JSON.stringify(state)
	audio=Director.new(); root.add_child(audio); audio.setup(func() -> Dictionary: return state)
	audio.playback_started.connect(func(channel: String,asset: String) -> void: playbacks.append({"channel":channel,"asset":asset,"at":Time.get_ticks_msec()}))
	game=Game.new(); game.size=Vector2(430,820); root.add_child(game); game.set_process(false)
	game.presentation_requested.connect(func(id: String,payload: Dictionary) -> void: events.append({"id":id,"payload":payload.duplicate(true)}); audio.cue(id,payload))
	game.finished.connect(func(result: Dictionary) -> void: results.append(result))
	game.start({"resume":true})
	await process_frame; await process_frame
	check(not events.is_empty() and events[0]=={"id":"prologue_blackout_started","payload":{"durationMs":7000}},"source blackout starts with exact payload")
	check(audio.music_asset=="music_prologue_blackout" and is_instance_valid(audio.music) and audio.music.playing,"blackout has real source music")
	if not is_instance_valid(audio.music): await finish(); return
	tick(6.99)
	check(count("prologue_narrator_intro")==0,"intro does not play before seven seconds")
	# Reproduce CI's long previous frame without a local first-font-render stall
	# accidentally waiting out the cue. Rendering is covered by other fixtures.
	game.hide()
	audio._stream("music_narrator_chase",true); audio._stream("vo_prologue_narrator_intro")
	OS.delay_msec(240); await process_frame
	var intro_requested_at: int=Time.get_ticks_msec()
	tick(.03)
	var intro_pending: Array=pending_voice("vo_prologue_narrator_intro")
	check(count("prologue_narrator_intro")==1 and intro_pending.size()==1,"seven-second transition queues exact narrator once")
	if intro_pending.size()!=1: await finish(); return
	var intro_deadline: int=int(intro_pending[0].at)
	check(int(intro_pending[0].cue.get("offsetMs",0))==120 and intro_deadline>=intro_requested_at+120 and intro_deadline<=Time.get_ticks_msec()+120,"intro retains authored120ms monotonic delay")
	var intro_started: bool=await voice_reached("vo_prologue_narrator_intro")
	check(intro_started,"seven-second transition plays exact narrated intro after120ms")
	# A failed playback assertion must exit with a report, never dereference Nil
	# and strand this coroutine until the external five-minute process timeout.
	if not intro_started: await finish(); return
	var intro_starts: Array=playbacks.filter(func(p: Dictionary) -> bool: return p.channel=="voice" and p.asset=="vo_prologue_narrator_intro")
	check(intro_starts.size()==1 and int(intro_starts[0].at)>=intro_deadline,"intro playback cannot start before its scheduled owner deadline")
	var narration: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/source/act-one-bootstrap.content.json")).audioNarration.prologue_narrator_intro
	var expected_segments: Array = narration.subtitleSegmentsZh
	check(expected_segments.size() == 3 and expected_segments.all(func(line: String) -> bool: return not line.strip_edges().is_empty()), "source supplies three readable narrator segments")
	check(game.intro_segments==expected_segments,"narrator preserves three source segments with approved Chinese text")
	game._pause(); var frozen: float=game.elapsed; var playback: float=audio.voice.get_playback_position()
	tick(.5); await wait_msec(220)
	check(game.elapsed==frozen and audio.voice.stream_paused,"pause freezes game and native narrator")
	check(absf(audio.voice.get_playback_position()-playback)<.04,"paused voice offset cannot drift")
	game._resume(); await process_frame
	check(not audio.voice.stream_paused and count("prologue_playback_resumed")==1,"resume continues same clip")
	# Each failed round waits for real explicit retry; narration remains single-owner.
	game.show();game.grab_focus()
	for tick_index in range(6000):
		if game.misses>=3:break
		if game.session.phase=="hint" and game.retry_wait>=.35:await retry_round()
		tick(.01)
	var missed: Array=events.filter(func(e: Dictionary) -> bool:return e.id=="prologue_error_intercept_missed")
	check(game.phase=="intercept" and game.session.phase=="hint" and missed.size()==3 and count("prologue_error_round_failed")==3,"three actual failed rounds require explicit retries and retain all miss and round-failed cues")
	if missed.size()!=3:await finish();return
	check(missed[2].payload=={"misses":3,"retryCurrentRound":true},"third miss reports the current explicit-retry presentation payload")
	check(count("prologue_narrator_intro")==1 and pending_voice("vo_prologue_narrator_intro").is_empty(),"explicit retries never replay the original narration")
	tick(.4);await retry_round()
	check(WordDriver.until(game,"lock"),"actual word selection and board collisions earn the lock")
	check(game.phase=="lock" and count("prologue_error_intercepted")==3 and count("prologue_error_lock_ready")==1,"three completed semantic stages emit the original lock cue once")
	game.holding=true; tick(1.41)
	await voice_reached("vo_prologue_narrator_caught")
	check(game.phase=="caught" and audio.voice_asset=="vo_prologue_narrator_caught","1400ms hold plays only narrator caught voice")
	var caught_count: int=events.size()
	tick(3.05); check(game.dialogue_index==1 and events.size()==caught_count,"first player response remains text-only")
	tick(1.1); check(game.dialogue_index==2 and events.size()==caught_count,"second player response remains text-only")
	tick(1.1); await voice_reached("vo_prologue_narrator_bargain")
	check(count("prologue_narrator_bargain")==1 and audio.voice_asset=="vo_prologue_narrator_bargain","5200ms emits source bargain once")
	tick(3.7)
	check(game.phase=="burst" and count("prologue_white_burst")==1,"8900ms emits source burst once")
	var burst: Array=audio.scheduled.filter(func(p: Dictionary) -> bool: return p.id=="prologue_white_burst")
	check(burst.map(func(p: Dictionary) -> int: return int(p.cue.get("offsetMs",0)))==[0,300,620,760],"burst preserves exact0/300/620/760ms scheduled effects/musicstop")
	if burst.size()!=4: await finish(); return
	var stop_deadline: int=int(burst[3].at)
	game._pause();check(not game.paused,"non-interactive burst has no player pause latch")
	game.set_platform_suspended(true); var pending: int=audio.scheduled.size(); await wait_msec(850)
	check(audio.scheduled.size()==pending and audio.music!=null,"background lifecycle freezes delayed burst cue offsets and music stop")
	game.set_platform_suspended(false)
	check(int(burst[3].at)>=stop_deadline+850,"resume shifts the760ms stop deadline by the actual pause duration")
	stop_deadline=int(burst[3].at)
	var wait_deadline: int=Time.get_ticks_msec()+3000
	while audio.music!=null and Time.get_ticks_msec()<wait_deadline: await process_frame
	check(audio.music==null and Time.get_ticks_msec()>=stop_deadline,"resumed760ms burst stop occurs only at its scheduled owner deadline")
	tick(1.7)
	check(results.size()==1 and results[0].dialogueCount==4 and results[0].whiteoutCompleted,"audio never grants or blocks game proof")
	audio.cue("act2_entry_unlocked"); await process_frame; await process_frame
	game.queue_free(); await process_frame; await process_frame
	check(count("prologue_scene_closed")==1,"game destruction emits audio lifecycle close")
	check(audio.voice==null and audio.music_asset=="music_act2_search","closing old game stops narrator without stopping newchapter music")
	check(JSON.stringify(state)==initial,"audio and prologue presentation never write progression state")
	await finish()
