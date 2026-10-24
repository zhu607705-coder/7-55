extends SceneTree
## Real players and the existing presentation boundaries, never story progress.
const Platform = preload("res://scripts/platform/web_platform.gd")
const Director = preload("res://scripts/media/audio_director.gd")
var checks := 0
var failures := 0
var state: Node
var shell: Control
var bridge: Node

func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("WEB VISIBILITY: " + message)
func wave() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 8000
	var bytes := PackedByteArray()
	bytes.resize(8000 * 2 * 4)
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = 8000 * 4
	return stream
func player(parent: Node, cue: String = "") -> AudioStreamPlayer:
	var result := AudioStreamPlayer.new()
	result.stream = wave()
	result.set_meta("cue_id", cue)
	parent.add_child(result)
	result.play()
	return result
func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():
		push_error("WEB_VISIBILITY_TEST_ISOLATION_REQUIRED"); quit(2); return
	state = root.get_node("State")
	state.developer_mode = false; state.d = state.initial()
	check(state.save_game(), "isolated formal save exists")
	var before: Dictionary = state.d.duplicate(true)
	var primary := FileAccess.get_file_as_bytes(state.SAVE_PATH)
	shell = load("res://scenes/main.tscn").instantiate(); root.add_child(shell)
	await process_frame
	# Shell mounting and ordinary phone-entry ticking are separate from this
	# synchronous platform boundary. Freeze them after the real shell is ready.
	shell.set_process(false)
	before = state.d.duplicate(true)
	primary = FileAccess.get_file_as_bytes(state.SAVE_PATH)
	bridge = Platform.new(); shell.add_child(bridge); bridge.setup(shell, state)
	var ordinary := player(shell)
	var manual := player(shell); manual.stream_paused = true
	var replaced := player(shell)
	var owned := player(shell.audio_director, "web_visibility_owner")
	shell.audio_director.pause_prefix("web_visibility_")
	check(is_equal_approx(ordinary.stream.get_length(), 4.0) and ordinary.has_stream_playback(), "pause probe uses an actual four-second AudioServer playback")
	await create_timer(.08).timeout
	var position := ordinary.get_playback_position()
	check(position > .015, "real playhead first advances while foreground playback is active")
	bridge._apply_visibility(true)
	check(not paused, "platform leaves the previously running SceneTree running")
	check(ordinary.stream_paused and manual.stream_paused and owned.stream_paused, "hidden boundary immediately pauses actual live audio")
	check(not shell.audio_director.pause_for_platform(), "repeated platform pause does not acquire another clock lease")
	var frozen: int = shell.audio_director.presentation_clock()
	await create_timer(.14).timeout
	check(shell.audio_director.presentation_clock() == frozen, "director clock excludes actual hidden wall time")
	check(absf(ordinary.get_playback_position() - position) < .06, "actual player playhead does not advance during the hidden interval")
	# A legitimate owner resume while hidden cannot override the platform pause.
	shell.audio_director.resume_prefix("web_visibility_")
	check(owned.stream_paused, "prefix resume during hiding cannot restart audio")
	# This newer playback is not the capability captured by the hidden boundary.
	replaced.stream = wave(); replaced.play(); replaced.stream_paused = true
	bridge._apply_visibility(false)
	check(not ordinary.stream_paused and manual.stream_paused, "return resumes only playback that was not manually paused")
	check(not owned.stream_paused, "a prefix released during hiding is not restored as a stale manual pause")
	check(replaced.stream_paused, "return cannot resume a replacement stream")
	var once: int = shell.audio_director.presentation_clock()
	shell.audio_director.resume_from_platform()
	check(absi(shell.audio_director.presentation_clock() - once) < 20, "repeated platform resume is idempotent")
	# An owner that remains paused stays authoritative after the page returns.
	shell.audio_director.pause_prefix("web_visibility_")
	bridge._apply_visibility(true); bridge._apply_visibility(false)
	check(owned.stream_paused, "remaining controller-owned presentation pause is retained")
	shell.audio_director.resume_prefix("web_visibility_")
	bridge._apply_visibility(true)
	shell.audio_director.pause_prefix("web_visibility_")
	bridge._apply_visibility(false)
	check(owned.stream_paused, "a new owner pause established while hidden remains authoritative on return")
	shell.audio_director.resume_prefix("web_visibility_")
	paused = true; bridge._apply_visibility(true); bridge._apply_visibility(false)
	check(paused, "an already paused SceneTree is never unpaused by page visibility")
	paused = false
	# A required chapter and browser visibility share one captured playback.
	# Releasing either owner alone cannot restart the still-paused content.
	manual.stream_paused = true
	shell.web_platform = bridge
	shell._on_content_blocking(true)
	check(paused and not bridge._document_hidden and ordinary.stream_paused, "content loading pauses the tree and live audio without pretending the document is hidden")
	var content_clock: int = shell.audio_director.presentation_clock()
	bridge._apply_visibility(true)
	await create_timer(.10).timeout
	shell._on_content_blocking(false)
	check(not paused and ordinary.stream_paused and bridge._document_hidden, "finishing content restores its tree lease but retains real browser hiding")
	check(shell.audio_director.presentation_clock() == content_clock, "overlapping content and hiding exclude wall time only once")
	bridge._apply_visibility(false)
	check(not ordinary.stream_paused and manual.stream_paused, "last pause owner restores the original manual audio ownership")
	paused = true
	shell._on_content_blocking(true); shell._on_content_blocking(false)
	check(paused, "content loading never resumes a tree paused by another owner")
	paused = false; shell.web_platform = null
	# C3's actual fallback host must stop at focus loss, before hidden wall time.
	var voice_host: Node = load("res://scripts/media/c3_media_host.gd").new()
	shell.add_child(voice_host)
	voice_host.setup(func() -> Dictionary: return {"native": {"page": "c35_voice", "host": {"focused": true}}})
	var voice_session: RefCounted = load("res://scripts/media/c3_voice_session.gd").new("web-visibility", "", 1000.0)
	voice_session.begin_fallback("readable fallback")
	voice_host.current = voice_session
	bridge._apply_visibility(true)
	var reviewed: float = voice_session.reviewed_ms
	check(voice_host.current == null and voice_session.phase == "stopped", "existing C3 focus lifecycle stops the fallback at the hidden boundary")
	await create_timer(.14).timeout
	bridge._apply_visibility(false)
	check(voice_session.reviewed_ms == reviewed and not voice_session.reviewed_ready and not voice_session.heard_ready, "background wall time cannot earn C3 hearing or review evidence")
	# C1 GUI-local holding is separate from Input's pressed-key registry.
	var game: Control = load("res://scripts/games/prologue_interception.gd").new()
	shell.add_child(game); game.set_process(false); game.phase = "lock"; game.holding = true; game.hold_ms = 600
	shell.active_game = game
	bridge._apply_visibility(true)
	check(game.paused and not game.holding and game.hold_ms == 0 and game.phase == "lock", "existing C1 pause retires a partial local hold without completing the lock")
	bridge._apply_visibility(false)
	check(game.paused and game.phase == "lock", "return does not silently resume or complete C1")
	shell.active_game = null; game.queue_free()
	check(state.d == before and FileAccess.get_file_as_bytes(state.SAVE_PATH) == primary, "all lifecycle probes preserve State and formal save bytes")
	for item in [ordinary, manual, replaced, owned]: item.stop(); item.stream = null; item.queue_free()
	test_deadline_shift_contract()
	await test_director_clock()
	await voice_host.shutdown(); voice_host.queue_free()
	await shell.audio_director.shutdown()
	if is_instance_valid(shell.media_host): await shell.media_host.shutdown()
	shell.queue_free(); await process_frame
	print("WEB_VISIBILITY: ", checks, " checks; ", failures, " failures")
	quit(1 if failures else 0)

func deadline_shifts_match(voice_shift: int, effect_shift: int, pending_shift: int, earliest: int, latest: int) -> bool:
	return earliest <= latest and voice_shift == effect_shift and effect_shift == pending_shift and voice_shift >= earliest and voice_shift <= latest

func test_deadline_shift_contract() -> void:
	# Each initial deadline can be created on a different millisecond. Compare
	# its own increment, not three final values against the first initial value.
	check(deadline_shifts_match(1560 - 1500, 1561 - 1501, 1562 - 1502, 60, 60), "independent initial deadline milliseconds retain one exact shift")
	# The live clock can advance between the pre-call read and resume_prefix's
	# read. The observed bracket replaces no clock with a guessed tolerance.
	check(deadline_shifts_match(61, 61, 61, 60, 61), "a resume clock crossing one millisecond stays inside the observed bracket")
	for index in range(3):
		for difference in [-1, 1]:
			var shifts: Array[int] = [60, 60, 60]
			shifts[index] += difference
			check(not deadline_shifts_match(shifts[0], shifts[1], shifts[2], 60, 61), "deadline %s rejects a nonuniform %s millisecond shift" % [index, difference])
	for shift in [59, 62, 200]:
		check(not deadline_shifts_match(shift, shift, shift, 60, 61), "equal shift %s outside the active-clock bracket is rejected, including hidden wall time" % shift)
	check(not deadline_shifts_match(60, 60, 60, 61, 60), "an inverted clock bracket cannot acknowledge a deadline shift")

func test_director_clock() -> void:
	var director: Node = Director.new(); root.add_child(director)
	director.setup(func() -> Dictionary: return state.d)
	director.set_process(false)
	var voice := player(director, "chapter4_prologue_test")
	var effect := player(director, "chapter4_prologue_test")
	director.voice = voice; director.voice_deadline = director.presentation_clock() + 500
	director.effects.append({"player": effect, "id": "chapter4_prologue_test", "deadline": director.presentation_clock() + 500, "bus": ""})
	director.scheduled.append({"id": "chapter4_prologue_test", "at": director.presentation_clock() + 500, "cue": {}, "sequence": 1})
	var initial_voice_deadline: int = director.voice_deadline
	var initial_effect_deadline: int = director.effects[0].deadline
	var initial_pending_at: int = director.scheduled[0].at
	director.pause_prefix("chapter4_prologue_")
	await create_timer(.03).timeout
	check(director.pause_for_platform(), "first application pause acquires a single clock lease")
	var clock: int = director.presentation_clock()
	var entries: Array = director.scheduled.duplicate(true)
	await create_timer(.14).timeout
	director._process(0)
	check(director.presentation_clock() == clock and director.scheduled == entries, "hidden process cannot spend pending cue offsets")
	check(director.voice == voice and director.effects.size() == 1, "hidden process cannot spend voice/effect deadlines")
	director.schedule_cue("during_hidden", {}, 400)
	check(director.scheduled[-1].at == clock + 400, "cues scheduled while hidden use the same frozen presentation clock")
	director.resume_from_platform()
	await create_timer(.03).timeout
	var prefix_pause_at: int = director._paused_prefixes["chapter4_prologue_"]
	var before_resume: int = director.presentation_clock()
	var elapsed: int = before_resume - prefix_pause_at
	director.resume_prefix("chapter4_prologue_")
	var after_resume: int = director.presentation_clock()
	var voice_shift: int = director.voice_deadline - initial_voice_deadline
	var effect_shift: int = director.effects[0].deadline - initial_effect_deadline
	var pending_shift: int = director.scheduled[0].at - initial_pending_at
	var clock_evidence := str({"initial": [initial_voice_deadline, initial_effect_deadline, initial_pending_at], "current": [director.voice_deadline, director.effects[0].deadline, director.scheduled[0].at], "shifts": [voice_shift, effect_shift, pending_shift], "prefix_pause_at": prefix_pause_at, "before_resume": before_resume, "after_resume": after_resume})
	check(elapsed >= 30 and elapsed < 130, "overlapping prefix excludes hidden wall time exactly once")
	check(deadline_shifts_match(voice_shift, effect_shift, pending_shift, elapsed, after_resume - prefix_pause_at), "voice, effect and pending deadlines all use the same active-time domain: " + clock_evidence)
	var remaining: int = director.voice_deadline - director.presentation_clock()
	check(remaining >= 460 and remaining <= 520, "overlap retains the authored remaining cutoff rather than adding background duration twice")
	await director.shutdown(); director.queue_free(); await process_frame
