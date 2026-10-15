extends SceneTree
## Exercise the real Main window-close callback with live mixer-owned streams.
var shell: Control
var playback_refs: Array[WeakRef] = []
var stream_refs: Array[WeakRef] = []
var checks := 0
var failures := 0
var exit_observed := false
var requested_at := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func run() -> void:
	var state := root.get_node("State")
	state.developer_mode = true
	state.d = state.initial()
	state.d.native.page = "phone_home"
	state.d.currentScene = "phone_home"
	state.d.ui.musicPlaying = true
	shell = load("res://scenes/main.tscn").instantiate()
	root.add_child(shell)
	shell.audio_director.cue("rpg_library_room_opened")
	for i in range(5): await process_frame
	check(shell.audio_director.chiptune is AudioStreamPlayer and shell.audio_director.chiptune.playing,"procedural WAV is actively playing")
	check(shell.audio_director.music is AudioStreamPlayer and shell.audio_director.music.playing,"library MP3 is actively playing")
	for player: Node in shell.audio_director.get_children():
		if player is AudioStreamPlayer and player.has_stream_playback():
			playback_refs.append(weakref(player.get_stream_playback()))
			stream_refs.append(weakref(player.stream))
	check(playback_refs.size() == 2,"close fixture owns exactly two live playbacks")
	check(not auto_accept_quit,"window close waits for Main instead of immediately quitting")
	shell.tree_exiting.connect(verify_exit)
	requested_at = Time.get_ticks_msec()
	root.close_requested.emit()
	root.close_requested.emit()
	check(shell._quit_requested,"repeated window close is claimed by the same Main")

func _process(_delta: float) -> bool:
	if requested_at > 0 and Time.get_ticks_msec()-requested_at > 6000:
		check(false,"window close finishes within the audio owner's bounded retirement wait")
		quit(1)
	return false

func verify_exit() -> void:
	exit_observed = true
	check(playback_refs.all(func(ref: WeakRef) -> bool: return ref.get_ref() == null),"both actual playback instances retire before tree exit")
	check(stream_refs.all(func(ref: WeakRef) -> bool: return ref.get_ref() == null),"both playback-owned streams release before tree exit")
	check(not shell.audio_director._ready_to_play,"audio schedules no new cues after shutdown")

func _finalize() -> void:
	check(exit_observed,"native close reached tree exit")
	print("NATIVE_WINDOW_CLOSE: %d checks; %d failures" % [checks,failures])
