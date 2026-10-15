extends SceneTree
const Director=preload("res://scripts/media/audio_director.gd")
const Activity=preload("res://scripts/games/chapter4_activity.gd")
var checks: int=0
var errors: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: errors+=1; push_error(message)
func _initialize() -> void: call_deferred("run")
func drain() -> void: await process_frame; await process_frame
func run() -> void:
	var state: Dictionary={"native":{"page":"c4_notes","settings":{"music":true,"effects":false,"volume":1.0}},"ui":{"musicMuted":false}}
	var original: String=JSON.stringify(state)
	var director: Node=Director.new(); root.add_child(director); director.setup(func() -> Dictionary:return state)
	var activity: Control=Activity.new(); root.add_child(activity); activity.set_process(false)
	activity.presentation_requested.connect(director.cue)
	activity.setup({"kind":"prologue","settings":state.native.settings,"video":"res://missing-test-video.ogv"})
	activity._cue("chapter4_prologue_started"); await drain()
	check(director.music is AudioStreamPlayer and director.music_asset=="music_ch4_prologue_h3_44s","Activity routes source music to global player")
	check(activity.get_children().filter(func(n: Node) -> bool:return n is AudioStreamPlayer).is_empty(),"host-connected Activity creates zero duplicate local players")
	activity._cue("chapter4_prologue_line_recoil")
	var voice_deadline: int=Time.get_ticks_msec()+2000
	while not is_instance_valid(director.voice) and Time.get_ticks_msec()<voice_deadline: await process_frame
	check(director.voice_asset=="vo_ch4_prologue_player_01" and is_instance_valid(director.voice) and director.voice.playing,"explicit authored player clip survives effects=false")
	check(director.effects.is_empty(),"same cue SFX obey effects=false")
	if not is_instance_valid(director.voice): await director.shutdown(); quit(1); return
	activity.presentation_requested.emit("native_activity_paused",{"prefixes":["chapter4_prologue_"]})
	var position: float=director.voice.get_playback_position()
	await create_timer(.12).timeout
	check(director.voice.stream_paused and director.music.stream_paused and absf(director.voice.get_playback_position()-position)<.04,"focus pause freezes unified prologue channels")
	activity.presentation_requested.emit("native_activity_resumed",{"prefixes":["chapter4_prologue_"]}); await drain()
	check(not director.voice.stream_paused and not director.music.stream_paused,"focus resume preserves unified players")
	activity._cue("chapter4_prologue_glass_door")
	activity._cue("chapter4_prologue_finished"); await drain()
	check(director.voice==null and director.music==null and not director.scheduled.any(func(e: Dictionary) -> bool:return str(e.id).begins_with("chapter4_prologue_")),"finished cancels only owned pending cues and music/voice")
	director.cue("clock_stable_started"); director.cue("final_chase_started")
	await create_timer(.23).timeout
	check(director.music_asset=="music_ch4_prologue_night_pursuit" and director.voice_asset=="vo_pursuit_chapter4_guard_start","new final chase owns actual score and voice")
	activity.queue_free(); await drain()
	check(director.music_asset=="music_ch4_prologue_night_pursuit" and director.voice_asset=="vo_pursuit_chapter4_guard_start","late Activity exit cannot stop newer chase channels")
	check(not director.ambients.is_empty(),"late Activity exit leaves clock ambience intact")
	check(JSON.stringify(state)==original,"unified presentation leaves snapshot unchanged")
	check(await director.shutdown(),"all actual playbacks retired deterministically")
	director.queue_free(); await drain()
	print("CHAPTER4_AUDIO_OWNERSHIP checks=",checks," errors=",errors)
	quit(1 if errors else 0)
