extends SceneTree
const Director = preload("res://scripts/media/audio_director.gd")
const Bank = preload("res://scripts/media/native_prologue_effects.gd")
const PAIRS = [
	["prologue_narrator_intro","fx_narrator_circle_appear",.62,1.0],
	["prologue_error_intercept_missed","fx_act1_controls_install",.34,.78],
	["prologue_error_round_failed","fx_act1_controls_install",.42,.64],
	["prologue_error_lock_ready","fx_act1_movement_unlock",.48,1.0],
	["prologue_narrator_caught","fx_narrator_grab",.72,1.0],
	["prologue_white_burst","fx_narrator_white_burst",.72,1.0]
]
var audio: Node
var state := {"native":{"page":"ending","settings":{"music":false,"effects":true,"volume":.6}},"ui":{}}
var checks: Array = []
var failures: Array = []
var waves: Array = []
var started: Array = []
func _initialize() -> void: run.call_deferred()
func check(ok: bool, name: String) -> void:
	checks.append({"name":name,"pass":ok})
	if not ok: failures.append(name); push_error(name)
func frames(n: int = 3) -> void:
	for i in n: await process_frame
func run() -> void:
	audio = Director.new(); root.add_child(audio); audio.setup(func() -> Dictionary: return state)
	audio.playback_started.connect(func(channel: String,asset: String) -> void: started.append({"channel":channel,"asset":asset,"at_ms":Time.get_ticks_msec()}))
	var original := JSON.stringify(audio.source)
	var out := OS.get_environment("NATIVE_PROLOGUE_EFFECTS_REPORT")
	if out.is_empty(): out = "user://native-prologue-effects.json"
	for pair in PAIRS:
		var tone: Dictionary = Bank.tone(pair[0],pair[1])
		check(not tone.is_empty(), pair[0]+" has one scoped procedural waveform")
		var started_us := Time.get_ticks_usec()
		var stream: AudioStreamWAV = audio._tone_stream(tone)
		var synthesis_us := Time.get_ticks_usec()-started_us
		var peak := 0; var nonzero := 0
		for i in stream.data.size()/2:
			var value := stream.data.decode_s16(i*2)
			peak = maxi(peak,absi(value)); nonzero += int(value != 0)
		check(nonzero > 100 and peak > 100, pair[0]+" contains a real nonzero waveform")
		check(peak <= 6000 and stream.data.decode_s16(0) == 0 and absi(stream.data.decode_s16(stream.data.size()-2)) <= 1, pair[0]+" has conservative peak and faded edges")
		check(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED and stream.get_length() <= .3, pair[0]+" is a short finite one-shot")
		check(audio._tone_stream(tone) == stream, pair[0]+" uses the existing immutable stream cache")
		check(Bank.stream(pair[0],pair[1]).data == stream.data, pair[0]+" prebuilt resource exactly matches reproducible synthesis")
		stream.save_to_wav(out.get_basename()+"-"+pair[0]+".wav")
		ResourceSaver.save(stream,out.get_basename()+"-"+pair[0]+".res")
		waves.append({"cue":pair[0],"frames":stream.data.size()/2,"rate":stream.mix_rate,"peak":peak,"nonzero_samples":nonzero,"synthesis_us":synthesis_us})
		var cue := {"asset":pair[1],"volume":pair[2],"playbackRate":pair[3],"_cueId":pair[0]}
		var dispatch_started := Time.get_ticks_usec()
		audio._play_effect(cue,pair[0])
		waves[-1].dispatch_us = Time.get_ticks_usec()-dispatch_started
		check(audio.effects.size() == 1, pair[0]+" creates exactly one source-owned effect")
		var effect: Dictionary = audio.effects[0]
		check(effect.player.stream is AudioStreamWAV and effect.player.stream == Bank.stream(pair[0],pair[1]), pair[0]+" uses the proposed cached waveform")
		check(is_equal_approx(effect.gain,pair[2]) and is_equal_approx(effect.player.pitch_scale,pair[3]) and absf(db_to_linear(effect.player.volume_db)-pair[2]*.6)<.0001, pair[0]+" preserves source rate, gain and master volume")
		audio.stop_prefix("prologue_"); await frames()
		check(audio.effects.is_empty(), pair[0]+" remains cancellable by scene prefix")
	for pair in PAIRS:
		check(Bank.tone("act1_controls_installed",pair[1]).is_empty(), "unrelated event cannot receive "+pair[1])
		check(Bank.stream("act1_controls_installed",pair[1]) == null, "runtime unrelated event keeps original "+pair[1])
		check(Bank.tone(pair[0],"fx_act1_login_stamp").is_empty(), "existing audible interception asset stays unchanged")
	# Actual source burst scheduling still owns its three hits.
	started.clear(); var before := Time.get_ticks_msec(); audio.cue("prologue_white_burst")
	var due: Array = audio.scheduled.filter(func(p: Dictionary) -> bool:return p.cue.get("channel")=="sfx").map(func(p: Dictionary) -> int:return p.at-before)
	check(due.size()==3 and absi(due[0])<=2 and absi(due[1]-300)<=2 and absi(due[2]-620)<=2, "source three-hit offsets remain 0, 300 and 620ms")
	await frames(); audio.pause_prefix("prologue_"); var pending: int=audio.scheduled.size()
	await create_timer(.4).timeout
	check(audio.scheduled.size()==pending and audio.effects[0].player.stream_paused, "pause freezes active and delayed burst owners")
	audio.resume_prefix("prologue_"); await create_timer(.8).timeout
	check(started.filter(func(p: Dictionary)->bool:return p.channel=="sfx").size()==3, "resume produces exactly the three authored burst hits")
	audio.stop_prefix("prologue_"); check(audio.effects.is_empty() and audio.scheduled.is_empty(), "scene close retires active and scheduled adapted effects")
	state.native.settings.effects=false; await frames()
	audio._play_effect({"asset":"fx_narrator_grab","volume":.72},"prologue_narrator_caught")
	check(audio.effects.is_empty(), "effects mute prevents replacement playback")
	state.native.settings.effects=true;state.native.settings.volume=0;await frames()
	audio._play_effect({"asset":"fx_narrator_grab","volume":.72},"prologue_narrator_caught")
	check(audio.effects.size()==1 and audio.effects[0].player.volume_db < -80, "zero master volume also mutes the replacement")
	check(JSON.stringify(audio.source)==original, "adaptation leaves source catalog and scheduling unchanged")
	check(await audio.shutdown(), "audio resources release cleanly")
	audio.queue_free();await frames()
	FileAccess.open(out,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"waveforms":waves,"audible_acceptance":false,"real_cua":false,"status":"creative replacement proposal, not source-restored audio"},"  "))
	print("NATIVE_PROLOGUE_EFFECTS ",checks.size()," checks; ",failures.size()," failures")
	quit(1 if not failures.is_empty() else 0)
