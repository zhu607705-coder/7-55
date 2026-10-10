extends SceneTree
const Director = preload("res://scripts/media/audio_director.gd")
const ASSET = "vo_prologue_narrator_caught"
var audio: Node
var state: Dictionary
var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(ok: bool, name: String, detail: Variant = null) -> void:
	var result := {"name":name,"pass":ok,"detail":detail}; checks.append(result)
	if not ok: failures.append(result); push_error(name)
func frames(n: int = 3) -> void:
	for i in n: await process_frame
func item(extra: Dictionary = {}) -> Dictionary:
	var cue := {"asset":ASSET,"subtitleKey":"prologue_narrator_caught","volume":1.0}
	cue.merge(extra, true); return cue
func wait_finished(seconds: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while is_instance_valid(audio.voice) and Time.get_ticks_msec() < deadline: await process_frame
	return not is_instance_valid(audio.voice)
func run() -> void:
	state = {"native":{"page":"ending","settings":{"music":false,"effects":true,"volume":.6}},"ui":{}}
	var state_before := JSON.stringify(state)
	audio = Director.new(); root.add_child(audio); audio.setup(func() -> Dictionary: return state)
	var catalog_before := JSON.stringify(audio.source)
	var original_duration: Variant = audio.source.assets[ASSET].durationMs
	# A deliberately shorter nominal metadata duration isolates clock ownership.
	# The actual source stream remains intact, with no explicit excerpt request.
	audio.source.assets[ASSET].durationMs = 120
	var recording := AudioEffectRecord.new(); recording.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0, recording)
	recording.set_recording_active(true); await create_timer(.2).timeout
	audio._play_voice(item())
	check(is_instance_valid(audio.voice) and audio.voice.playing, "whole source file starts an actual voice player")
	check(audio.voice_deadline == -1, "nominal asset metadata does not become an audio stop deadline")
	check(audio.last_subtitle.durationMs == 570, "nominal subtitle duration remains independently authored")
	await create_timer(.3).timeout
	check(is_instance_valid(audio.voice) and audio.voice.playing, "whole file remains active after its nominal duration")
	check(await wait_finished(5), "whole file retires on its natural audio completion")
	await create_timer(.2).timeout
	recording.set_recording_active(false)
	var wave := recording.get_recording()
	var output := OS.get_environment("VOICE_COMPLETION_REPORT")
	if output.is_empty(): output = "user://voice-completion.json"
	check(wave.save_to_wav(output.get_basename()+".wav") == OK, "actual mixed source PCM saved for tail comparison")
	AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0)-1)
	audio.source.assets[ASSET].durationMs = original_duration
	check(JSON.stringify(audio.source) == catalog_before, "temporary fixture metadata restored exactly")
	# Explicit excerpts keep their existing cutoff and seek behavior.
	audio._play_voice(item({"durationMs":180,"startMs":100}))
	check(audio.voice_deadline > Time.get_ticks_msec(), "explicit excerpt retains its requested cutoff")
	await create_timer(.3).timeout
	check(not is_instance_valid(audio.voice), "explicit excerpt stops at its authored duration")
	# Full-file pause/resume, cancellation, and preemption still own playback.
	audio._play_voice(item()); audio.voice.set_meta("cue_id","prologue_narrator_caught")
	await create_timer(.18).timeout
	var player: AudioStreamPlayer = audio.voice
	audio.pause_prefix("prologue_"); var position: float = player.get_playback_position()
	await create_timer(.25).timeout
	check(audio.voice == player and player.stream_paused, "pause retains the same full-file owner")
	check(absf(player.get_playback_position()-position) < .04, "paused full-file sample position remains frozen")
	audio.resume_prefix("prologue_"); await create_timer(.13).timeout
	check(audio.voice == player and not player.stream_paused and audio.voice_deadline == -1, "resume continues the same full-file player without adding a deadline")
	audio.stop_prefix("prologue_")
	check(not is_instance_valid(audio.voice), "scene cancellation immediately retires the full file")
	audio._play_voice(item()); var prior: AudioStreamPlayer = audio.voice
	audio._play_voice({"asset":"vo_prologue_narrator_bargain","subtitleKey":"prologue_narrator_bargain"})
	check(audio.voice_asset == "vo_prologue_narrator_bargain" and audio.voice != prior and not prior.playing, "new voiced line preempts the old owner")
	check(audio.get_children().filter(func(node: Node) -> bool: return node is AudioStreamPlayer and node.playing and str(node.get_meta("channel","")) == "voice").size() <= 1, "preemption cannot leave two live voice players")
	audio.reset()
	check(not is_instance_valid(audio.voice), "reset cancels full-file playback")
	check(JSON.stringify(state) == state_before, "audio completion does not change story or settings")
	check(await audio.shutdown(), "all audio playback resources retire cleanly")
	audio.queue_free(); await frames()
	FileAccess.open(output, FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"recorded_source":ASSET,"real_cua":false,"audible_acceptance":false},"  "))
	print("VOICE_COMPLETION ",checks.size()," checks; ",failures.size()," failures")
	quit(1 if not failures.is_empty() else 0)
