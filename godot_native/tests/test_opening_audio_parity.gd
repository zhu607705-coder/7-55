extends SceneTree
const Director=preload("res://scripts/media/audio_director.gd")
var checks: Array=[]
var failures: Array=[]
var state: Dictionary
var director: Node
var played: Array=[]
var OUT: String=OS.get_environment("OPENING_AUDIO_QA_OUTPUT")
func _initialize() -> void: run.call_deferred()
func check(ok: bool,id: String,detail: Variant=null) -> void:
	var value={"id":id,"passed":ok,"detail":detail}; checks.append(value)
	if not ok: failures.append(value); push_error(id)
func drain() -> void:
	await process_frame; await process_frame; await process_frame
func cue_count(asset: String) -> int:
	return played.filter(func(entry: Array): return entry[1]==asset).size()
func active_alarm_players() -> int:
	return director.get_children().filter(func(node: Node): return node is AudioStreamPlayer and node.playing and str(node.get_meta("cue_id","")).begins_with("phone_alarm_")).size()
func run() -> void:
	if OUT.is_empty(): OUT="user://opening-audio-qa"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	state=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	state.native={"page":"alarm","scene":"","settings":{"music":true,"effects":true,"volume":.6}}
	state.ui.musicPlaying=false
	var before=JSON.stringify(state)
	director=Director.new(); root.add_child(director); director.setup(func() -> Dictionary: return state)
	director.playback_started.connect(func(channel: String,asset: String): played.append([channel,asset]))
	var catalog_before=JSON.stringify(director.source)
	var tone: AudioStreamWAV=director._alarm_tone_stream()
	check(tone.mix_rate==48000 and tone.format==AudioStreamWAV.FORMAT_16_BITS,"square-48k-16bit")
	check(tone.loop_mode==AudioStreamWAV.LOOP_FORWARD and tone.loop_begin==0 and tone.loop_end==124800,"phase-continuous-2600ms-loop")
	check(absf(tone.get_length()-2.6)<.0001,"oscillator-period-2point6-seconds")
	check(tone.data.size()==249600,"complete-ten-frequency-steps")
	for step in range(10):
		var begin: int=step*12480+480; var end: int=(step+1)*12480-480
		var changes: int=0; var max_value: int=0
		for i in range(begin,end):
			var current: int=tone.data.decode_s16(i*2); var previous: int=tone.data.decode_s16((i-1)*2)
			if sign(current)!=sign(previous): changes+=1
			max_value=maxi(max_value,abs(current))
		var measured: float=changes*.5*48000.0/(end-begin)
		check(absf(measured-(880 if step%2==0 else 660))<3,"frequency-step-"+str(step),measured)
		check(max_value==1147,"source-0035-gain-step-"+str(step),float(max_value)/32767)
	check(tone.data.decode_s16(0)==1147 and tone.data.decode_s16(124799*2)==-1147,"loop-boundary-is-ordinary-square-edge")
	check(director._alarm_tone_stream()==tone,"oscillator-resource-cached")
	tone.save_to_wav(OUT+"/authored-square.wav")
	director.cue("phone_alarm_started"); director.cue("phone_alarm_started"); await drain()
	check(director.ambients.size()==2 and active_alarm_players()==2,"one-owner-with-two-authored-layers")
	check(cue_count("05_p00_alarm_phone_vibrate_loop")==1 and cue_count("procedural_phone_alarm")==1,"same-turn-start-deduplicates-both-layers")
	var vibration=director.ambients.phone_alarm.player; var oscillator=director.ambients.phone_alarm_tone.player
	check(absf(db_to_linear(vibration.volume_db)-.48)<.0001,"vibration-08-times-master-preserved")
	check(absf(db_to_linear(oscillator.volume_db)-.6)<.0001,"tone-stream0035-times-master-only")
	director.cue("phone_alarm_started"); await drain()
	check(director.ambients.phone_alarm.player==vibration and director.ambients.phone_alarm_tone.player==oscillator,"later-start-reuses-both-players")
	check(active_alarm_players()==2,"later-start-no-extra-player")
	director.pause_prefix("phone_alarm_"); await drain()
	check(vibration.stream_paused and oscillator.stream_paused,"owner-pause-covers-both-layers")
	director.resume_prefix("phone_alarm_"); await drain()
	check(not vibration.stream_paused and not oscillator.stream_paused,"owner-resume-covers-both-layers")
	state.native.settings.effects=false; await drain()
	check(vibration.volume_db < -80 and oscillator.volume_db < -80,"effects-setting-applies-to-both-layers")
	state.native.settings.effects=true; await drain()
	# Isolate the source oscillator only in this automated fixture, for PCM frequency checks.
	director._stop_ambient("phone_alarm")
	var rec=AudioEffectRecord.new(); rec.format=AudioStreamWAV.FORMAT_16_BITS
	var initial_effects: int=AudioServer.get_bus_effect_count(0); var initial_volume: float=AudioServer.get_bus_volume_db(0)
	AudioServer.add_bus_effect(0,rec); rec.set_recording_active(true)
	var record_start: int=Time.get_ticks_msec()
	await create_timer(1.3).timeout
	var stop_time: int=Time.get_ticks_msec()-record_start
	director.cue("phone_alarm_stopped"); await drain()
	check(director.ambients.is_empty() and active_alarm_players()==0,"stop-cue-clears-both-layers")
	await create_timer(.35).timeout
	rec.set_recording_active(false)
	var wav: AudioStreamWAV=rec.get_recording(); wav.save_to_wav(OUT+"/rendered-square.wav")
	AudioServer.remove_bus_effect(0,initial_effects)
	var record_meta={"real_cua":false,"audible_acceptance":false,"recording_wall_ms":Time.get_ticks_msec()-record_start,"recorder_removed":AudioServer.get_bus_effect_count(0)==initial_effects,"master_state_unchanged":AudioServer.get_bus_volume_db(0)==initial_volume,"events":[{"kind":"source_alarm_stop","elapsed_ms":stop_time}],"fixture_note":"vibration removed only inside this test, to measure the independent source oscillator"}
	FileAccess.open(OUT+"/rendered-square.json",FileAccess.WRITE).store_string(JSON.stringify(record_meta,"  "))
	check(record_meta.recorder_removed and record_meta.master_state_unchanged,"recorder-passive-and-cleaned")
	await drain()
	director.cue("phone_alarm_started"); director.cue("phone_alarm_stopped"); await drain()
	check(director.ambients.is_empty() and active_alarm_players()==0,"same-frame-start-stop-no-leak")
	director.cue("phone_alarm_started"); await drain(); director.stop_prefix("phone_alarm_"); await drain()
	check(director.ambients.is_empty() and active_alarm_players()==0,"prefix-close-clears-both-layers")
	director.cue("phone_alarm_started"); await drain(); state.native.page="desktop"; await drain()
	check(director.ambients.is_empty() and active_alarm_players()==0,"normal-page-exit-clears-alarm-owner")
	state.native.page="alarm"; await drain(); director.cue("phone_alarm_started"); director.reset(); await drain()
	check(director.ambients.is_empty() and director.scheduled.is_empty(),"reset-cancels-start-before-playback")
	var old=state.duplicate(true); old.native.alarm_ringing=true
	var next=old.duplicate(true); next.native.page="desktop"
	var count=cue_count("01_global_ui_button_tap_confirm")
	director.update_state("c1_dismiss_alarm",old,next,{"handled":true,"page":"desktop"}); await drain()
	check(cue_count("01_global_ui_button_tap_confirm")==count+1,"successful-close-exactly-one-source-tap")
	var taps=director.effects.filter(func(entry: Dictionary): return entry.asset=="01_global_ui_button_tap_confirm")
	check(taps.size()==1 and absf(taps[0].gain-.9)<.001 and absf(db_to_linear(taps[0].player.volume_db)-.54)<.001,"close-tap-source09-gain")
	director.reset(); await drain(); count=cue_count("01_global_ui_button_tap_confirm")
	director.update_state("c1_dismiss_alarm",next,next,{"handled":true}); await drain()
	check(cue_count("01_global_ui_button_tap_confirm")==count,"repeated-close-no-tap")
	old=next.duplicate(true); old.native.wake_warned=true; next=old.duplicate(true); next.native.page="phone_home"
	count=cue_count("01_global_ui_button_tap_confirm")
	director.update_state("c1_enter_home",old,next,{"handled":true,"page":"phone_home"}); await drain()
	check(cue_count("01_global_ui_button_tap_confirm")==count+1,"successful-home-exactly-one-source-tap")
	taps=director.effects.filter(func(entry: Dictionary): return entry.asset=="01_global_ui_button_tap_confirm")
	check(taps.size()==1 and absf(taps[0].gain-.9)<.001,"home-tap-source09-gain")
	director.reset(); await drain(); count=cue_count("01_global_ui_button_tap_confirm")
	director.update_state("c1_enter_home",old,old,{"handled":true,"message":"not ready"}); await drain()
	director.update_state("c1_enter_home",next,next,{"handled":true}); await drain()
	check(cue_count("01_global_ui_button_tap_confirm")==count,"rejected-or-repeated-home-no-tap")
	check(JSON.stringify(director.source)==catalog_before,"source-catalog-unchanged")
	check(JSON.stringify(state)==before,"reader-story-state-unchanged-by-audio")
	check(await director.shutdown(),"audio-thread-clean-shutdown")
	director.queue_free(); await drain()
	FileAccess.open(OUT+"/test-opening-audio.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"real_cua":false,"audible_acceptance":false},"  "))
	print("OPENING_AUDIO_PARITY ",checks.size()," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
