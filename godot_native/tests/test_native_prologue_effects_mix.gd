extends SceneTree
const Director = preload("res://scripts/media/audio_director.gd")
const Cases = preload("res://tests/test_native_prologue_effects.gd")
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var state := {"native":{"page":"ending","settings":{"music":false,"effects":true,"volume":.6}},"ui":{}}
	var audio := Director.new(); root.add_child(audio); audio.setup(func() -> Dictionary:return state)
	var prefix := OS.get_environment("NATIVE_PROLOGUE_EFFECTS_MIX")
	if prefix.is_empty(): prefix="user://prologue-sfx-mix"
	var recording := AudioEffectRecord.new(); recording.format=AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0,recording)
	for pair in Cases.PAIRS:
		recording.set_recording_active(true);await create_timer(.2).timeout
		audio._play_effect({"asset":pair[1],"volume":pair[2],"playbackRate":pair[3],"_cueId":pair[0]},pair[0])
		await create_timer(.6).timeout
		recording.set_recording_active(false)
		var wave:=recording.get_recording()
		if wave.save_to_wav(prefix+"-"+pair[0]+".wav")!=OK: quit(1);return
		audio.stop_prefix("prologue_")
	AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	var retired:=await audio.shutdown();audio.queue_free();await process_frame
	print("NATIVE_PROLOGUE_EFFECTS_MIX six source-gain/rate fixtures saved; resources retired=",retired)
	quit(0 if retired else 1)
