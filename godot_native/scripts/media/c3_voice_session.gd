extends RefCounted
## Runtime capability. Only this exact object, retained by the chapter controller,
## may acknowledge an audition. It is never serialized in GameState.
var clip_id: String
var path: String
var duration_ms: float
var start_ms: float
var end_ms: float
var marks_heard: bool
var phase: String = "issued"
var position_ms: float = 0.0
var verified_ms: float = 0.0
var reviewed_ms: float = 0.0
var heard_ready: bool = false
var reviewed_ready: bool = false
var fallback: bool = false
var error: String = ""
var player: AudioStreamPlayer
var last_clock: int = 0
var last_position: float = 0.0

func _init(clip: String = "", file: String = "", duration: float = 5200.0, start: float = 0.0, end: float = -1.0, full: bool = true) -> void:
	clip_id = clip
	path = file
	duration_ms = duration
	end_ms = duration if end < 0 else minf(duration, maxf(120.0, end))
	start_ms = clampf(start, 0.0, end_ms - 120.0)
	position_ms = start_ms
	marks_heard = full

func begin(actual_player: AudioStreamPlayer) -> bool:
	if phase != "issued" or not is_instance_valid(actual_player) or actual_player.stream == null: return false
	player = actual_player
	if player.stream.get_length() <= 0.0: return false
	player.play(position_ms / 1000.0)
	last_clock = Time.get_ticks_msec()
	last_position = position_ms
	phase = "playing"
	return true

func begin_fallback(message: String) -> bool:
	if phase != "issued": return false
	fallback = true
	error = message
	last_clock = Time.get_ticks_msec()
	phase = "playing"
	return true

func sample() -> bool:
	if phase != "playing": return false
	var now: int = Time.get_ticks_msec()
	var elapsed: float = maxf(0.0, now - last_clock)
	last_clock = now
	var previous_heard: bool = heard_ready
	var previous_reviewed: bool = reviewed_ready
	if fallback:
		# A timed readable rendition of the authored sound-event captions is an
		# accessibility review, never a claim that missing audio was heard.
		position_ms = minf(end_ms, position_ms + elapsed)
		reviewed_ms += elapsed
		if marks_heard and position_ms >= duration_ms * 0.8: reviewed_ready = true
	else:
		if not is_instance_valid(player) or player.stream == null or player.stream_paused: return false
		if player.playing:
			var measured: float = player.get_playback_position() * 1000.0
			var advance: float = measured - last_position
			# Reject discontinuous seeks submitted as a full-clip audition.
			if advance > elapsed + 180.0 or advance < -180.0:
				marks_heard = false
				error = "播放位置发生跳转，请重新试听完整录音。"
			verified_ms += maxf(0.0, minf(advance, elapsed + 180.0))
			position_ms = minf(end_ms, maxf(position_ms, measured))
			last_position = measured
		if marks_heard and position_ms >= duration_ms * 0.8 and verified_ms + 180.0 >= position_ms - start_ms:
			heard_ready = true
	return previous_heard != heard_ready or previous_reviewed != reviewed_ready

func pause() -> void:
	if phase != "playing": return
	sample()
	if is_instance_valid(player): player.stream_paused = true
	phase = "paused"

func resume() -> void:
	if phase != "paused": return
	if is_instance_valid(player): player.stream_paused = false
	last_clock = Time.get_ticks_msec()
	last_position = position_ms
	phase = "playing"

func stop() -> void:
	if phase == "playing": sample()
	if is_instance_valid(player): player.stop()
	phase = "stopped"

func finish() -> void:
	if phase != "playing": return
	sample()
	# Completion cannot add unobserved playback or set an evidence flag.
	if is_instance_valid(player): player.stop()
	# The mixer can finish between UI frames. Show the completed endpoint,
	# but leave verified_ms/heard_ready untouched: display is not a receipt.
	position_ms = end_ms
	phase = "finished"

func snapshot() -> Dictionary:
	return {"clip_id":clip_id,"phase":phase,"position_ms":position_ms,"end_ms":end_ms,"duration_ms":duration_ms,"fallback":fallback,"error":error}
