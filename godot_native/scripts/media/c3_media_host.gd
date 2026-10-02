extends Node
## Main owns one host; setup(read_state), apply(result.media), event -> State.act.
signal event(action: String, value: Variant)
const Session = preload("res://scripts/media/c3_voice_session.gd")
var current: RefCounted
var player: AudioStreamPlayer
var callback: String = ""
var read_state: Callable
var retiring_playbacks: Array[WeakRef] = []

func setup(state_reader: Callable) -> void:
	read_state = state_reader

func apply(config: Dictionary) -> void:
	var requested: Variant = config.get("session")
	if not requested is Session: return
	var command: String = str(config.get("command", "play"))
	if command != "play":
		if current != requested: return
		if command == "pause": current.pause()
		elif command == "resume": current.resume()
		elif command == "stop": current.stop()
		else: return
		event.emit(callback, current)
		return
	if requested.phase != "issued": return
	_stop_current()
	current = requested
	callback = str(config.get("on_event", "c35_media_event"))
	player = AudioStreamPlayer.new()
	add_child(player)
	var stream: AudioStream = null
	if ResourceLoader.exists(current.path): stream = load(current.path) as AudioStream
	player.stream = stream
	if stream == null or not current.begin(player):
		current.begin_fallback("音频暂不可用，正在按原时序显示声音记录。")
	elif player.has_stream_playback():
		retiring_playbacks.append(weakref(player.get_stream_playback()))
	event.emit(callback, current)

func _process(_delta: float) -> void:
	if current == null: return
	if read_state.is_valid():
		var s: Dictionary = read_state.call()
		if s.get("native", {}).get("page", "") != "c35_voice" or not s.get("native",{}).get("host",{}).get("focused",true):
			_stop_current()
			return
	if current.phase != "playing": return
	var changed: bool = current.sample()
	if current.position_ms >= current.end_ms or (not current.fallback and is_instance_valid(player) and not player.playing):
		current.finish()
		changed = true
	if changed: event.emit(callback, current)

func _stop_current() -> void:
	if current != null:
		current.stop()
		event.emit(callback, current)
		current = null
	if is_instance_valid(player):
		player.stream = null
		player.queue_free()
	player = null
	retiring_playbacks = retiring_playbacks.filter(func(playback: WeakRef) -> bool: return playback.get_ref() != null)

func shutdown() -> bool:
	## AudioServer releases stopped MP3 playbacks on its mixer thread. Two fast
	## process frames are not a guarantee that this has happened. Tests/owners
	## that immediately quit await actual weak-reference retirement instead.
	_stop_current()
	set_process(false)
	read_state = Callable()
	var deadline: int = Time.get_ticks_msec() + 5000
	while not retiring_playbacks.is_empty():
		retiring_playbacks = retiring_playbacks.filter(func(playback: WeakRef) -> bool: return playback.get_ref() != null)
		if retiring_playbacks.is_empty(): break
		if Time.get_ticks_msec() >= deadline:
			push_error("Stopped voice playback did not retire from AudioServer within five seconds.")
			return false
		await get_tree().process_frame
	return true

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: _stop_current()

func _exit_tree() -> void:
	_stop_current()
