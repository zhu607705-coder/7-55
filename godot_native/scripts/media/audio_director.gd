extends Node
## Read-only presentation consumer. No autoload, controller, save or progression writes.
## The JSON is generated from the unchanged TypeScript catalogs at build time.
signal subtitle(text: String, surface: String)
signal subtitle_timed(text: String, surface: String, duration_ms: float, tone: String)
signal visual_requested(definition: Dictionary)
signal inspect_requested(item_id: String)
signal cue_published(id: String, payload: Dictionary)
signal playback_started(channel: String, asset: String)
const SOURCE := "res://data/native/audio-director-source.json"
var read_state: Callable
var last_subtitle: Dictionary = {}
var _tiyi_taunt_waiting:=false
var _explicit_ids_current: Dictionary = {}
var _mapping_previous: Dictionary = {}
var _mapping_next: Dictionary = {}
var _narrative_owned_current := false
var source: Dictionary = {}
var external_cue_prefixes: Array = []
var music: AudioStreamPlayer
var voice: AudioStreamPlayer
var chiptune: AudioStreamPlayer
var _chiptune_stream: AudioStreamWAV
var _application_focused: bool = true
var ambients: Dictionary = {}
var effects: Array = []
var scheduled: Array = []
var played_once: Dictionary = {}
var emitted_this_turn: Dictionary = {}
var music_asset: String = ""
var voice_asset: String = ""
var music_target_volume: float = 0.2
var voice_deadline: int = -1
var voice_duck: float = -1.0
var _sequence: int = 0
var _stream_cache: Dictionary = {}
var _music_allowed: bool = true
var _effects_allowed: bool = true
var _master_volume: float = 1.0
var _ready_to_play: bool = false
var _observed_page: String = ""
var _observed_runtime: Dictionary = {}
var _paused_prefixes: Dictionary = {}
var _retiring_playbacks: Array = []

func setup(reader: Callable) -> void:
	read_state = reader
	if source.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE)) if FileAccess.file_exists(SOURCE) else {}
		source = parsed if parsed is Dictionary else {}
	_ready_to_play = true
	_refresh_settings()
	if reader.is_valid():
		var state: Variant = reader.call()
		if state is Dictionary:
			for entry in _scene_entry(state): cue(entry.cueId, entry.get("payload", {}))

func _process(_delta: float) -> void:
	if not _ready_to_play: return
	_refresh_settings()
	if _retiring_playbacks.size() > 64: _retiring_playbacks = _retiring_playbacks.filter(func(ref: WeakRef) -> bool: return ref.get_ref() != null)
	var now: int = Time.get_ticks_msec()
	var ready: Array = []
	var waiting: Array = []
	for pending in scheduled:
		if int(pending.at) <= now and not _id_paused(str(pending.id)): ready.append(pending)
		else: waiting.append(pending)
	scheduled = waiting
	for pending in ready:
		if pending.has("story"):
			var line: Dictionary=pending.story
			var tone: String="player" if str(line.text).begins_with("玩家：") else "system" if str(line.text).begins_with("系统：") or str(line.text).begins_with("手机系统：") else "task" if str(line.text).begins_with("任务：") else "narrator"
			subtitle_timed.emit(str(line.text),"toast",float(line.durationMs),tone)
			feedback(str(line.text))
		elif pending.has("inspect"): inspect_requested.emit(str(pending.inspect))
		elif pending.has("trigger"): cue(str(pending.id),pending.trigger)
		else: _play_cue(pending.cue, str(pending.id))
	if is_instance_valid(voice) and voice_deadline >= 0 and now >= voice_deadline and not voice.stream_paused: stop_voice()
	for entry in effects.duplicate():
		if not is_instance_valid(entry.player) or (int(entry.deadline) >= 0 and now >= int(entry.deadline) and not entry.player.stream_paused):
			_remove_effect(entry)

func _refresh_settings() -> void:
	var state: Dictionary = {}
	if read_state.is_valid():
		var value: Variant = read_state.call()
		if value is Dictionary: state = value
	var page: String = str(state.get("native", {}).get("page", ""))
	if _observed_page == "wechat" and page != "wechat":
		cancel_scheduled("xy_")
		if voice_asset in ["vo_legacy_xy_attack", "vo_legacy_xy_laugh"]: stop_voice()
	if page=="wechat" and state.get("native",{}).has("friend_scatter_pending") and not state.native.friend_scatter_pending:
		# A same-page load replaces the mount without changing the observed page.
		cancel_scheduled("xy_")
		if voice_asset in ["vo_legacy_xy_attack","vo_legacy_xy_laugh"]: stop_voice()
	if _observed_page == "desktop" and page != "desktop": cancel_scheduled("wake_narration")
	if _observed_page == "alarm" and page != "alarm":
		cancel_scheduled("phone_alarm_")
		_stop_ambient("phone_alarm"); _stop_ambient("phone_alarm_tone")
	_observed_page = page
	_observe_runtime(state)
	var settings: Dictionary = state.get("native", {}).get("settings", {})
	_music_allowed = bool(settings.get("music", true)) and not bool(state.get("ui", {}).get("musicMuted", false))
	_effects_allowed = bool(settings.get("effects", true))
	_master_volume = clampf(float(settings.get("volume", 1.0)), 0.0, 1.0)
	_update_chiptune(state)
	_apply_music_volume()
	if is_instance_valid(voice): _set_volume(voice, float(voice.get_meta("gain", 1.0)))
	for entry in ambients.values():
		if is_instance_valid(entry.player): _set_volume(entry.player, float(entry.gain) if _effects_allowed else 0.0)
	for entry in effects:
		if is_instance_valid(entry.player): _set_volume(entry.player, float(entry.gain) if _effects_allowed else 0.0)

func _observe_runtime(state: Dictionary) -> void:
	# State.open_scene/toggle_mode are not actions; read-only observation reaches
	# the same scene creation/mode events emitted by the source Phaser owners.
	var scene: String = str(state.get("rpgScene", "")) if state.get("runtimeMode") == "rpg" else ""
	var now: Dictionary = {"scene":scene,"mode":str(state.get("native",{}).get("mode","light"))}
	if str(_observed_runtime.get("scene", "")) != scene:
		if _observed_runtime.get("scene") == "theater_interior": cancel_scheduled("native_theater_dialogue_")
		if _observed_runtime.get("scene") == "canteen_interior": cancel_scheduled("canteen_tray_")
		var entry: Dictionary = {"dorm_hub":"rpg_dorm_room_opened","library_interior":"rpg_library_room_opened","canteen_interior":"canteen_interior_opened","theater_interior":"theater_interior_opened"}
		if entry.has(scene): cue(str(entry[scene]))
		if scene == "qizhen_lake":
			var interlude: Dictionary = state.get("chapterThreeInterlude", {})
			if not (interlude.get("phase") == "replay_ready" and interlude.get("replayUnlocked",false) and not state.get("chapter4",{}).get("prologueSeen",false)):
				var lake: Dictionary = state.get("qizhenLake", {})
				cue("qizhen_lake_opened", {"phase":lake.get("phase",""),"zone":lake.get("zone","dock"),"vehicle":lake.get("vehicle","on_foot")})
	if _observed_runtime.get("scene") == scene and _observed_runtime.get("mode", now.mode) != now.mode:
		if scene in ["canteen_interior", "theater_interior"]:
			cue(("canteen_" if scene == "canteen_interior" else "theater_") + ("dark_mode_enabled" if now.mode == "dark" else "light_mode_enabled"))
	_observed_runtime = now

func _make_chiptune() -> AudioStreamWAV:
	# Exact source square oscillator notes, exponential envelope and260ms clock.
	# PCM is generated locally; no speech, browser, external renderer or runtime JS.
	var config: Dictionary = source.get("chiptune", {})
	var melody: Array = config.get("melody", [])
	if melody.is_empty(): return null
	var rate: int = 48000
	var step_frames: int = int(round(float(config.stepMs) * rate / 1000.0))
	var active_frames: int = int(round(float(config.noteSeconds) * rate))
	var ramp_frames: int = int(round(float(config.rampSeconds) * rate))
	var total: int = step_frames * melody.size()
	var bytes := PackedByteArray(); bytes.resize(total * 2)
	for index in range(total):
		var local: int = index % step_frames
		var sample: int = 0
		if local < active_frames:
			var frequency: float = float(melody[index / step_frames])
			var envelope: float = float(config.gain) * pow(float(config.endGain) / float(config.gain), minf(1.0, float(local) / ramp_frames))
			var square: float = 1.0 if fmod(frequency * float(local) / rate, 1.0) < .5 else -1.0
			sample = int(round(square * envelope * 32767.0))
		bytes.encode_s16(index * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS; stream.mix_rate = rate; stream.stereo = false
	stream.data = bytes; stream.loop_mode = AudioStreamWAV.LOOP_FORWARD; stream.loop_begin = 0; stream.loop_end = total
	return stream

func _update_chiptune(state: Dictionary) -> void:
	var enabled: bool = bool(state.get("ui", {}).get("musicPlaying", false)) and not bool(state.get("ui", {}).get("musicMuted", false))
	if not enabled:
		stop_chiptune(); return
	if not is_instance_valid(chiptune):
		if _chiptune_stream == null: _chiptune_stream = _make_chiptune()
		if _chiptune_stream == null: return
		chiptune = _player("chiptune", "procedural_chiptune", _chiptune_stream, {})
		_set_volume(chiptune, 1.0); _start(chiptune, "chiptune", "procedural_chiptune", {})
	_set_volume(chiptune, 1.0)
	chiptune.stream_paused = not _application_focused or not bool(state.get("native", {}).get("host", {}).get("focused", true))

func stop_chiptune() -> void:
	if is_instance_valid(chiptune): _retire_player(chiptune)
	chiptune = null

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_application_focused = false
		if is_instance_valid(chiptune): chiptune.stream_paused = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_application_focused = true

func _set_volume(player: AudioStreamPlayer, gain: float) -> void:
	player.volume_db = linear_to_db(maxf(0.00001, clampf(gain, 0.0, 1.0) * _master_volume))

func _apply_music_volume() -> void:
	if is_instance_valid(music): _set_volume(music, (voice_duck if voice_duck >= 0 else music_target_volume) if _music_allowed else 0.0)

func _token(id: String, payload: Dictionary) -> String:
	var keys: Array = payload.keys(); keys.sort()
	var ordered: Dictionary = {}
	for key in keys: ordered[key] = payload[key]
	return id + ":" + JSON.stringify(ordered)

func cue(id: String, payload: Dictionary = {}) -> void:
	if not _ready_to_play: return
	id = str(source.get("aliases", {}).get(id, id))
	for prefix in external_cue_prefixes:
		if id.begins_with(str(prefix)): return
	var token: String = _token(id, payload)
	if emitted_this_turn.has(token): return
	emitted_this_turn[token] = true
	call_deferred("_release_token", token)
	if id=="native_tiyi_crash_taunt":
		_tiyi_taunt_waiting=true
		cue("sys_net_try")
		return
	if id == "native_story_subtitle":
		subtitle_timed.emit(str(payload.get("text","")),"toast",float(payload.get("durationMs",2400)),str(payload.get("tone","system")))
		feedback(str(payload.get("text",""))); return
	if id in ["native_activity_paused","native_activity_resumed","native_activity_closed"]:
		for prefix in payload.get("prefixes",[]):
			if id == "native_activity_paused": pause_prefix(str(prefix))
			elif id == "native_activity_resumed": resume_prefix(str(prefix))
			else: stop_prefix(str(prefix))
		return
	if id == "act2_system_dialogue_closed":
		var dialogue_ids: Array = ["act2_system_found_intro","act2_system_inventory_demand","act2_system_inventory_missing","act2_system_just_find_it","act2_system_departure","act2_system_confession","act2_system_friend","act2_system_library","act2_system_move_now"]
		cancel_scheduled_ids(dialogue_ids)
		if is_instance_valid(voice) and dialogue_ids.has(str(voice.get_meta("cue_id", ""))): stop_voice()
		for effect in effects.duplicate():
			if dialogue_ids.has(effect.id): _remove_effect(effect)
		return
	if id == "prologue_playback_paused": pause_prefix("prologue_"); return
	if id == "prologue_playback_resumed": resume_prefix("prologue_"); return
	if id == "prologue_scene_closed": stop_prefix("prologue_"); return
	# These cancellation events exist even when their manifest has no playable beat.
	if id == "chapter4_prologue_skip":
		cancel_scheduled("chapter4_prologue_")
		if is_instance_valid(voice) and str(voice.get_meta("cue_id","")).begins_with("chapter4_prologue_"): stop_voice()
	if id in ["chapter4_prologue_finished", "chapter4_prologue_closed"]:
		stop_prefix("chapter4_prologue_")
	if id == "chapter4_755_scene_closed":
		cancel_scheduled_ids(source.get("chapter4CueIds", [])); stop_voice(); stop_ambients("chapter4_")
	if id == "chapter35_voice_audition_stop":
		cancel_scheduled("chapter35_voice_audition_"); stop_voice(); return
	if id == "qizhen_lake_left":
		cancel_scheduled("qizhen_swan_chase_"); cancel_scheduled("rpg_qizhen_chase_"); stop_voice()
	if id == "theater_program_order_wrong" and not _narrative_owned_current: _queue_theater_dialogue("wrong_order")
	if id == "theater_reversal_completed" and not _narrative_owned_current: _queue_theater_dialogue("reversal_before",true)
	if id == "theater_decoy_inspect_closed":
		if not _narrative_owned_current: _queue_theater_dialogue("reversal_after")
		return
	var definition: Dictionary = source.get("presentation", {}).get(id, {})
	if not definition.is_empty() and definition.get("visual", true):
		var visual: Dictionary = definition.duplicate(true); visual.id = id
		visual_requested.emit(visual)
	cue_published.emit(id, payload.duplicate(true))
	var beat: Dictionary = _procedural_beat(id,payload)
	if beat.is_empty(): beat = source.get("events", {}).get(id, source.get("legacy", {}).get(id, {}))
	# P00 useAlarmTone is a second source-authored layer, owned with the vibration.
	if id in ["phone_alarm_started", "phone_alarm_stopped"]:
		beat = beat.duplicate(true)
		var alarm_cues: Array = beat.get("cues", []).duplicate(true)
		alarm_cues.append({"channel":"ambient","owner":"phone_alarm_tone","asset":"procedural_phone_alarm","volume":1.0,"loop":true,"action":"play" if id == "phone_alarm_started" else "stop"})
		beat.cues = alarm_cues
	for original in beat.get("cues", []):
		# The owner-specific close above has already stopped this music. Do not
		# let a deferred closed event stop a newer scene's score.
		if id in ["chapter4_prologue_finished","chapter4_prologue_closed"] and original.get("channel")=="music" and original.get("action")=="stop": continue
		var item: Dictionary = original.duplicate(true)
		if payload.get("subtitleKey") is String: item.subtitleKey = payload.subtitleKey
		var line: Dictionary = source.get("storyLines", {}).get(str(item.get("subtitleKey", "")), {})
		if not item.has("asset") and item.get("channel") == "voice" and line.has("voiceAsset"): item.asset = line.voiceAsset
		if id.begins_with("chapter35_voice_audition_") and payload.get("previewKind") == "event":
			if _finite_number(payload.get("startMs")): item.startMs = maxf(0, float(payload.startMs))
			if _finite_number(payload.get("durationMs")): item.durationMs = clampf(float(payload.durationMs), 120, 10000)
		if item.get("panFromEvent", false): item.pan = clampf(float(payload.get("pan", 0)), -1, 1) if _finite_number(payload.get("pan")) else 0.0
		var once_key: String = str(item.get("asset", id + ":" + str(item.get("subtitleKey", item.get("channel", "")))))
		if item.get("once", false):
			if played_once.has(once_key): continue
			played_once[once_key] = true
		_sequence += 1
		scheduled.append({"id":id,"cue":item,"at":Time.get_ticks_msec() + maxi(0, int(item.get("offsetMs", 0))),"sequence":_sequence})

func schedule_cue(id: String, payload: Dictionary, delay_ms: float) -> void:
	_sequence+=1
	scheduled.append({"id":id,"trigger":payload.duplicate(true),"at":Time.get_ticks_msec()+maxi(0,int(delay_ms)),"sequence":_sequence})

func _release_token(token: String) -> void:
	emitted_this_turn.erase(token)

func feedback(text: String) -> void:
	# Exact source chapterThreeStoryLineKeyForSubtitle algorithm, no substring
	# splitting, translated matches or guessed roles.
	var whitespace:=RegEx.new(); whitespace.compile("\\s+")
	var normalized: String=whitespace.sub(text.strip_edges()," ",true)
	var key: String=str(source.get("chapter3KeysBySubtitle",{}).get(normalized,""))
	if not key.is_empty(): cue("chapter3_story_line",{"subtitleKey":key})

func _queue_theater_dialogue(id: String, inspect_after: bool=false) -> void:
	var lines: Array=source.get("theaterDialogue",{}).get(id,[])
	for line in lines:
		_sequence+=1
		scheduled.append({"id":"native_theater_dialogue_"+id,"story":line.duplicate(true),"at":Time.get_ticks_msec()+int(line.offsetMs),"sequence":_sequence})
	if inspect_after and not lines.is_empty():
		var last: Dictionary=lines[-1]
		scheduled.append({"id":"native_theater_dialogue_inspect","inspect":"decoyPaper","at":Time.get_ticks_msec()+int(last.offsetMs)+int(last.durationMs)+120,"sequence":_sequence})

func _finite_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func cancel_scheduled(prefix: String) -> void:
	scheduled = scheduled.filter(func(entry: Dictionary) -> bool: return not str(entry.id).begins_with(prefix))

func cancel_scheduled_ids(ids: Array) -> void:
	scheduled = scheduled.filter(func(entry: Dictionary) -> bool: return not ids.has(entry.id))

func _play_cue(item: Dictionary, id: String) -> void:
	item["_cueId"] = id
	match str(item.get("channel", "")):
		"music": _update_music(item)
		"ambient": _update_ambient(item)
		"text": _play_text(item)
		"voice":
			var key: String = str(item.get("subtitleKey", ""))
			var line: Dictionary = source.get("storyLines", {}).get(key, {})
			# Exact source policy: only catalog dialogue with explicit voiceRole is voiced.
			# Authored direct recordings without a subtitleKey are already source audio,
			# not a license to synthesize a player, 022, task or taunt line.
			if not key.is_empty() and not (line.is_empty() and _authored_direct_voice(item,id)) and (line.get("kind") != "dialogue" or not line.has("voiceRole")):
				_play_text(item)
			else: _play_voice(item)
		"sfx": _play_effect(item, id)

func _authored_direct_voice(item: Dictionary,id: String) -> bool:
	# H3/direct cinematic recordings have explicit approved assets and their own
	# subtitles outside storyLines. Match the exact authored event entry; an
	# arbitrary voice item must not grant a voice role to text-only dialogue.
	var asset: String=str(item.get("asset",""))
	if asset.is_empty() or not source.get("assets",{}).has(asset): return false
	for authored: Dictionary in source.get("events",{}).get(id,{}).get("cues",[]):
		if authored.get("channel")=="voice" and authored.get("asset")==asset and authored.get("subtitleKey","")==item.get("subtitleKey",""): return true
	return false

func _play_text(item: Dictionary, duration_override: float = -1) -> void:
	var line: Dictionary = source.get("storyLines", {}).get(str(item.get("subtitleKey", "")), {})
	if line.is_empty() or item.get("subtitleSurface", "toast") == "scene": return
	var text: String = str(line.get("subtitleZh", ""))
	var duration: float = duration_override if duration_override >= 0 else float(source.get("textDurationMsByKey", {}).get(str(item.get("subtitleKey", "")), 3600))
	var tone: String = "task" if line.get("kind") == "task" else "system" if line.get("speaker") == "narrator" else "xiaoying"
	last_subtitle = {"text":text,"surface":"toast","durationMs":duration,"tone":tone}
	subtitle_timed.emit(text, "toast", duration, tone)
	subtitle.emit(text, "toast")
	if _tiyi_taunt_waiting and str(item.get("subtitleKey",""))=="sys_net_try":
		_tiyi_taunt_waiting=false
		# Anchor the second authored text beat to actual first display, including
		# any pending audio queue delay. sys_net_try's source text duration is3040ms.
		schedule_cue("sys_no_money",{},3040)

func _stream(asset: String, loop: bool = false) -> AudioStream:
	var path: String = str(source.get("assets", {}).get(asset, {}).get("path", ""))
	if path.is_empty(): return null
	if not _stream_cache.has(path):
		if not ResourceLoader.exists(path): return null
		var loaded: Resource = load(path)
		if not loaded is AudioStream: return null
		_stream_cache[path] = loaded
	var result: AudioStream = _stream_cache[path].duplicate()
	if result is AudioStreamMP3 or result is AudioStreamOggVorbis: result.loop = loop
	return result

func _player(channel: String, asset: String, stream: AudioStream, item: Dictionary) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = channel.capitalize() + "_" + str(_sequence)
	player.stream = stream
	player.pitch_scale = clampf(float(item.get("playbackRate", 1.0)), 0.01, 4.0)
	player.set_meta("asset", asset); player.set_meta("channel", channel); player.set_meta("cue_id", str(item.get("_cueId", "")))
	add_child(player)
	return player

func _start(player: AudioStreamPlayer, channel: String, asset: String, item: Dictionary) -> void:
	var at: float = maxf(0, float(item.get("startMs", 0))) / 1000.0
	player.play(at)
	playback_started.emit(channel, asset)

func _procedural_beat(id: String, payload: Dictionary) -> Dictionary:
	if id == "headphone_drop_started":
		return {"cues":[{"channel":"sfx","asset":"15_p05_control_center_earphone_icon_drop","volume":.9}]}
	if id=="native_wechat_message_arrived": return {"cues":[{"channel":"sfx","asset":"07_p14_chat_message_notification_ping","volume":.9}]}
	if id=="native_tiyi_crash": return {"cues":[{"channel":"sfx","asset":"12_p06_tiyi_loading_app_crash_pop","volume":.9}]}
	var tones: Array = []; var bank: Dictionary = source.get("procedural", {})
	if id == "native_chase_tone": tones = bank.get("chase", {}).get(str(payload.get("kind","")), [])
	elif id == "native_fishing_judgment": tones = bank.get("judgments", {}).get(str(payload.get("judgment","")), [])
	elif id == "native_fishing_beat":
		var beats: Array = bank.get("beats", [])
		if beats.size() == 4: tones = beats[posmod(int(payload.get("beat",0)),4)]
	else: return {}
	var cues: Array = []
	for original in tones:
		var tone: Dictionary = original.duplicate(true)
		var start: float = float(tone.start)
		var at: float = float(payload.get("offsetMs",0)) + (float(tone.beatFraction)*float(payload.get("beatDurationSec",.6))*1000 if tone.has("beatFraction") else start*1000)
		for key in ["frequency","gain"]:
			for point in tone[key]: point.at = float(point.at)-start
		tone.stop = float(tone.stop)-start; tone.start=0
		cues.append({"channel":"sfx","asset":id+":"+str(payload.get("kind",payload.get("judgment",payload.get("beat",0)))),"tone":tone,"offsetMs":maxf(0,at),"volume":1.0})
	return {"cues":cues}

func _curve_value(points: Array, at: float) -> float:
	var previous: Dictionary = points[0]
	for index in range(1,points.size()):
		var next: Dictionary = points[index]
		if at <= float(next.at):
			var ratio: float = clampf((at-float(previous.at))/maxf(.000001,float(next.at)-float(previous.at)),0,1)
			return float(previous.value)*pow(float(next.value)/float(previous.value),ratio) if next.curve == "exponential" else float(previous.value)
		previous=next
	return float(previous.value)

func _tone_stream(tone: Dictionary) -> AudioStreamWAV:
	var key: String = "tone:"+JSON.stringify(tone)
	if _stream_cache.has(key): return _stream_cache[key]
	var rate: int = 48000; var total: int = int(ceil(float(tone.stop)*rate))
	var bytes:=PackedByteArray(); bytes.resize(total*2)
	var phase: float=0
	for index in range(total):
		var at: float=float(index)/rate
		var sample: float=sin(phase)
		if tone.waveform == "triangle": sample=asin(sin(phase))*2/PI
		elif tone.waveform == "square": sample=1 if fmod(phase,TAU)<PI else -1
		bytes.encode_s16(index*2,int(round(clampf(sample*_curve_value(tone.gain,at),-1,1)*32767)))
		phase += TAU*_curve_value(tone.frequency,at)/rate
	var stream:=AudioStreamWAV.new(); stream.format=AudioStreamWAV.FORMAT_16_BITS; stream.mix_rate=rate; stream.data=bytes
	_stream_cache[key]=stream
	return stream

func _update_music(item: Dictionary) -> void:
	if item.get("action", "play") == "stop": stop_music(); return
	music_target_volume = clampf(float(item.get("volume", music_target_volume)), 0, 1)
	var asset: String = str(item.get("asset", music_asset))
	if not is_instance_valid(music) or music_asset != asset:
		var stream: AudioStream = _stream(asset, bool(item.get("loop", false)))
		if stream == null: return
		stop_music()
		music = _player("music", asset, stream, item); music_asset = asset
		_apply_music_volume(); _start(music, "music", asset, item)
	else:
		if item.has("loop") and (music.stream is AudioStreamMP3 or music.stream is AudioStreamOggVorbis): music.stream.loop = bool(item.loop)
		if item.has("playbackRate"): music.pitch_scale = clampf(float(item.playbackRate), 0.01, 4)
		_apply_music_volume()
		if not music.playing: _start(music, "music", asset, item)

func stop_music() -> void:
	if is_instance_valid(music): _retire_player(music)
	music = null; music_asset = ""

func _alarm_tone_stream() -> AudioStreamWAV:
	# Source P00: square 880/660 Hz, 0.035 gain, switching every 260 ms.
	# Five 520 ms pairs contain exactly 2002 cycles, so the loop keeps phase.
	var key: String = "procedural_phone_alarm"
	if _stream_cache.has(key): return _stream_cache[key]
	var rate: int = 48000; var step_frames: int = 12480; var total: int = step_frames * 10
	var bytes := PackedByteArray(); bytes.resize(total * 2)
	var phase_units: int = 0; var amplitude: int = int(round(.035 * 32767))
	for index in range(total):
		bytes.encode_s16(index * 2, amplitude if phase_units < rate / 2 else -amplitude)
		var frequency: int = 880 if (index / step_frames) % 2 == 0 else 660
		phase_units = (phase_units + frequency) % rate
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS; stream.mix_rate = rate; stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD; stream.loop_begin = 0; stream.loop_end = total
	_stream_cache[key] = stream
	return stream

func _update_ambient(item: Dictionary) -> void:
	var owner: String = str(item.get("owner", item.get("asset", "ambient_default")))
	if item.get("action", "play") == "stop": _stop_ambient(owner); return
	var asset: String = str(item.get("asset", ""))
	if asset.is_empty(): return
	var entry: Dictionary = ambients.get(owner, {})
	if entry.is_empty() or entry.asset != asset or not is_instance_valid(entry.player):
		var stream: AudioStream = _alarm_tone_stream() if asset == "procedural_phone_alarm" and owner == "phone_alarm_tone" else _stream(asset, bool(item.get("loop", true)))
		if stream == null: return
		_stop_ambient(owner)
		entry = {"asset":asset,"player":_player("ambient", asset, stream, item),"gain":float(item.get("volume", .18))}
		ambients[owner] = entry
	else:
		entry.gain = float(item.get("volume", .18))
		entry.player.pitch_scale = clampf(float(item.get("playbackRate", 1)), .01, 4)
		if entry.player.stream is AudioStreamMP3 or entry.player.stream is AudioStreamOggVorbis: entry.player.stream.loop = bool(item.get("loop", true))
	_set_volume(entry.player, entry.gain if _effects_allowed else 0)
	if not entry.player.playing: _start(entry.player, "ambient", asset, item)

func _stop_ambient(owner: String) -> void:
	var entry: Dictionary = ambients.get(owner, {})
	if is_instance_valid(entry.get("player")): _retire_player(entry.player)
	ambients.erase(owner)

func stop_ambients(prefix: String = "") -> void:
	for owner in ambients.keys():
		if prefix.is_empty() or str(owner).begins_with(prefix): _stop_ambient(str(owner))

func _play_voice(item: Dictionary) -> void:
	var asset: String = str(item.get("asset", ""))
	if asset.is_empty(): return
	var duration: float = float(item.get("durationMs", source.get("assets", {}).get(asset, {}).get("durationMs", 3600)))
	_play_text(item, duration + 450)
	var stream: AudioStream = _stream(asset)
	if stream == null: return
	stop_voice()
	voice = _player("voice", asset, stream, item); voice_asset = asset
	var gain: float = float(item.get("volume", 1)); voice.set_meta("gain", gain); _set_volume(voice, gain)
	# Whole files finish on the audio clock; only explicit excerpts have a cutoff.
	voice_deadline = Time.get_ticks_msec() + maxi(1, int(duration)) if item.has("durationMs") else -1
	voice_duck = clampf(float(item.duckMusicTo), 0, 1) if item.has("duckMusicTo") else -1.0
	_apply_music_volume()
	voice.finished.connect(stop_voice)
	_start(voice, "voice", asset, item)

func stop_voice() -> void:
	if is_instance_valid(voice): _retire_player(voice)
	voice = null; voice_asset = ""; voice_deadline = -1; voice_duck = -1
	_apply_music_volume()

func _play_effect(item: Dictionary, id: String) -> void:
	if not _effects_allowed: return
	var asset: String = str(item.get("asset", ""))
	var stream: AudioStream = _tone_stream(item.tone) if item.get("tone") is Dictionary else _stream(asset, bool(item.get("loop", false)))
	if stream == null: return
	var player: AudioStreamPlayer = _player("sfx", asset, stream, item)
	var entry: Dictionary = {"player":player,"asset":asset,"id":id,"gain":float(item.get("volume", .8)),"deadline":Time.get_ticks_msec()+maxi(1,int(item.durationMs)) if item.has("durationMs") else -1,"bus":""}
	if item.has("pan"):
		var bus_name: String = "NativeCue_" + str(get_instance_id()) + "_" + str(player.get_instance_id())
		AudioServer.add_bus(); var index: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		var panner := AudioEffectPanner.new(); panner.pan = clampf(float(item.pan), -1, 1)
		AudioServer.add_bus_effect(index, panner); player.bus = bus_name; entry.bus = bus_name
	effects.append(entry); _set_volume(player, float(entry.gain))
	player.finished.connect(func() -> void: _remove_effect(entry))
	_start(player, "sfx", asset, item)

func _remove_effect(entry: Dictionary) -> void:
	if is_instance_valid(entry.get("player")): _retire_player(entry.player)
	var bus: String = str(entry.get("bus", ""))
	if not bus.is_empty():
		var index: int = AudioServer.get_bus_index(bus)
		if index > 0: AudioServer.remove_bus(index)
	effects.erase(entry)

func _id_paused(id: String) -> bool:
	for prefix in _paused_prefixes:
		if id.begins_with(str(prefix)): return true
	return false

func _owned_players(prefix: String) -> Array:
	var result: Array = []
	for child in get_children():
		if child is AudioStreamPlayer and str(child.get_meta("cue_id", "")).begins_with(prefix): result.append(child)
	return result

func pause_prefix(prefix: String) -> void:
	if _paused_prefixes.has(prefix): return
	_paused_prefixes[prefix] = Time.get_ticks_msec()
	for player in _owned_players(prefix): player.stream_paused = true

func resume_prefix(prefix: String) -> void:
	if not _paused_prefixes.has(prefix): return
	var duration: int = Time.get_ticks_msec() - int(_paused_prefixes[prefix])
	_paused_prefixes.erase(prefix)
	for pending in scheduled:
		if str(pending.id).begins_with(prefix): pending.at += duration
	if is_instance_valid(voice) and str(voice.get_meta("cue_id", "")).begins_with(prefix) and voice_deadline >= 0: voice_deadline += duration
	for entry in effects:
		if str(entry.id).begins_with(prefix) and int(entry.deadline) >= 0: entry.deadline += duration
	for player in _owned_players(prefix): player.stream_paused = false

func stop_prefix(prefix: String) -> void:
	cancel_scheduled(prefix); _paused_prefixes.erase(prefix)
	if is_instance_valid(music) and str(music.get_meta("cue_id", "")).begins_with(prefix): stop_music()
	if is_instance_valid(voice) and str(voice.get_meta("cue_id", "")).begins_with(prefix): stop_voice()
	for owner in ambients.keys():
		if str(ambients[owner].player.get_meta("cue_id", "")).begins_with(prefix): _stop_ambient(str(owner))
	for entry in effects.duplicate():
		if str(entry.id).begins_with(prefix): _remove_effect(entry)

func _retire_player(player: AudioStreamPlayer) -> void:
	if player.playing:
		var playback: AudioStreamPlayback = player.get_stream_playback()
		if playback != null: _retiring_playbacks.append(weakref(playback))
	player.stop(); player.stream = null; player.queue_free()

func shutdown() -> bool:
	# Await actual audio-thread release, not a guessed sleep, before test/process exit.
	_ready_to_play = false
	reset(); _stream_cache.clear(); _chiptune_stream = null
	var deadline: int = Time.get_ticks_msec() + 3000
	while true:
		_retiring_playbacks = _retiring_playbacks.filter(func(ref: WeakRef) -> bool: return ref.get_ref() != null)
		if _retiring_playbacks.is_empty(): return true
		if Time.get_ticks_msec() >= deadline: return false
		await get_tree().process_frame
	return false

func reset() -> void:
	_tiyi_taunt_waiting=false
	scheduled.clear(); played_once.clear(); emitted_this_turn.clear(); _paused_prefixes.clear()
	stop_voice(); stop_music(); stop_ambients(); stop_chiptune()
	for entry in effects.duplicate(): _remove_effect(entry)

func _exit_tree() -> void:
	reset()

func debug_state() -> Dictionary:
	return {"chiptunePlaying":is_instance_valid(chiptune) and chiptune.playing,"musicAsset":music_asset,"musicPlaying":is_instance_valid(music) and music.playing,"musicVolume":db_to_linear(music.volume_db) if is_instance_valid(music) else 0,"musicPlaybackRate":music.pitch_scale if is_instance_valid(music) else 1,"musicLoop":bool(music.stream.loop) if is_instance_valid(music) and (music.stream is AudioStreamMP3 or music.stream is AudioStreamOggVorbis) else false,"voiceAsset":voice_asset,"voicePlaying":is_instance_valid(voice) and voice.playing,"scheduledCueIds":scheduled.map(func(entry: Dictionary) -> String: return str(entry.id)),"ambientOwners":ambients.keys(),"effectsCount":effects.size()}

# PresentationDirector.ts: exact state derivation. Scene entry is not inferred from prose.
func _is_chapter4(state: Dictionary) -> bool:
	return state.get("runtimeMode") == "rpg" and state.get("rpgScene") == "duan_yongping_temporal_maze"

func _scene_entry(state: Dictionary) -> Array:
	if not _is_chapter4(state): return []
	var chapter: Dictionary = state.get("chapter4", {})
	if chapter.get("phase") == "maintenance_repair": return [{"cueId":"clock_stable_started" if chapter.get("factIds", []).has("clock_gear_repaired") else "clock_stutter_started"}]
	if chapter.get("phase") == "final_chase": return [{"cueId":"final_chase_started"}]
	return []

func derive_state_cues(previous: Dictionary, next: Dictionary) -> Array:
	var out: Array = []
	if previous.get("currentScene") != next.get("currentScene"): out.append_array(_scene_entry(next))
	var was: bool = _is_chapter4(previous); var now: bool = _is_chapter4(next)
	var before: Dictionary = previous.get("chapter4", {}); var after: Dictionary = next.get("chapter4", {})
	if was and not now: out.append({"cueId":"chapter4_755_scene_closed"})
	if now and (not was or before.get("phase") != "final_chase") and after.get("phase") == "final_chase": out.append({"cueId":"final_chase_started"})
	if now and after.get("phase") == "maintenance_repair" and (not was or before.get("phase") != "maintenance_repair"):
		out.append({"cueId":"clock_stable_started" if after.get("factIds", []).has("clock_gear_repaired") else "clock_stutter_started"})
	if was and now and not before.get("factIds", []).has("clock_gear_repaired") and after.get("factIds", []).has("clock_gear_repaired"): out.append({"cueId":"clock_stable_started"})
	if was and now and before.get("phase") == "final_chase" and after.get("phase") == "final_chase" and int(after.get("chaseAttempt", 0)) > int(before.get("chaseAttempt", 0)):
		out.append({"cueId":"final_chase_failed"}); out.append({"cueId":"final_chase_started"})
	if was and before.get("phase") == "final_chase" and after.get("phase") == "final_minute_recovery": out.append({"cueId":"final_chase_succeeded"})
	return out

func update_state(action: String, previous: Dictionary, next: Dictionary, result: Dictionary) -> void:
	_narrative_owned_current=bool(result.get("narrative_owned",false))
	_mapping_previous=previous
	_mapping_next=next
	_refresh_settings()
	for entry in derive_state_cues(previous, next): cue(str(entry.cueId), entry.get("payload", {}))
	# Controller-owned explicit events preserve payloads and survive action renaming.
	_explicit_ids_current.clear()
	var explicit: Variant = result.get("presentation", [])
	if explicit is String:
		_explicit_ids_current[explicit] = true; cue(explicit)
	elif explicit is Dictionary: _explicit_cue(explicit)
	elif explicit is Array:
		for entry in explicit:
			if entry is String:
				_explicit_ids_current[entry] = true; cue(entry)
			elif entry is Dictionary: _explicit_cue(entry)
	if action == "c1_friend_cancel":
		cancel_scheduled("xy_")
		if voice_asset in ["vo_legacy_xy_attack", "vo_legacy_xy_laugh"]: stop_voice()
	feedback(str(result.get("message","")))
	_map_native_actions(action, previous, next)
	_map_chapter3(action, previous, next, result)
	_map_chapter4(action, previous, next, result)
	_explicit_ids_current.clear()
	_mapping_previous={}; _mapping_next={}
	_narrative_owned_current=false

func _explicit_cue(entry: Dictionary) -> void:
	var id: String = str(entry.get("cueId", entry.get("id", "")))
	if id.is_empty(): return
	_explicit_ids_current[id] = true
	var payload: Dictionary = entry.get("payload", {}).duplicate(true)
	for key in entry:
		if key not in ["cueId", "id", "payload"]: payload[key] = entry[key]
	cue(id, payload)

func _value_at(state: Dictionary, path: String, fallback: Variant = null) -> Variant:
	var value: Variant = state
	for key in path.split("."):
		if not value is Dictionary or not value.has(key): return fallback
		value = value[key]
	return value

func _rose(previous: Dictionary, next: Dictionary, path: String) -> bool:
	return not bool(_value_at(previous, path, false)) and bool(_value_at(next, path, false))

func _native_effect(asset: String, gain: float = .8) -> void:
	# Exact Sfx callsites exported by identifier, never arbitrary filename guessing.
	_sequence += 1
	scheduled.append({"id":"legacy_sfx_"+asset,"cue":{"channel":"sfx","asset":asset,"volume":gain},"at":Time.get_ticks_msec(),"sequence":_sequence})

func _mapped_cue(id: String, payload: Dictionary = {}) -> void:
	# An explicit controller event supersedes this compatibility adapter, even if
	# the explicit event carries a richer source payload than the fallback knows.
	if not _explicit_ids_current.has(id): cue(id, _source_payload(id) if payload.is_empty() else payload)

func _source_payload(id: String) -> Dictionary:
	# Original controller event payloads, using only already-observed values.
	var next: Dictionary=_mapping_next; var previous: Dictionary=_mapping_previous
	var puzzle: Dictionary=_value_at(next,"ui.libraryFinalsPuzzle",{})
	var old_puzzle: Dictionary=_value_at(previous,"ui.libraryFinalsPuzzle",{})
	var fixed: Dictionary={
		"act2_entry_unlocked":{"entry":"phone_home"},"act2_inventory_recovered":{"itemId":"campusCard"},
		"act2_movement_quest_started":{"destination":"library"},"act2_character_named":{"name":"林星宇","studentId":"3250100755"},
		"act2_right_arrow_assembled":{"result":"rightArrow"},"act2_balance_shifted":{"from":"0.06","to":"6.00"},
		"act2_gamepad_purchased":{"price":"6.00","balance":"0.00"},"act2_gamepad_connected":{"movementEnabled":true},
		"act2_exit_ready":{"destination":"foundation_library","seat":"022"},"act2_movement_quest_completed":{"destination":"library"},
		"library_route_unlocked":{"destination":"foundation_library"},"library_entered":{"seat":"022","firstEntry":true},
		"library_entrance_record_read":{"arrivalMinutes":7},"library_occupied_seat_found":{"seat":"022"},"library_occupancy_note_collected":{"seat":"022"},
		"cc98_occupation_post_opened":{"floors":23,"optionalAc01":5},"library_catalog_results_shown":{"resultCount":5},
		"library_catalog_match_found":{"callNumber":"I247.55 / 755"},"library_archived_rule_opened":{"itemId":"archivedLeaveRule"},"library_archived_rule_recovered":{"proofCount":3},
		"photo_bag_report_generated":{"file":"IMG_0755.JPG"},"library_seat_receipt_recovered":{"seat":"022"},
		"library_recovery_application_opened":{"seat":"022"},"library_seat_release_pass_issued":{"seat":"022"},"library_seat_release_pass_applied":{"seat":"022"},
		"library_backpack_evicted":{"destination":"lost_found"},"library_seat_recovered":{"seat":"022"}}
	if fixed.has(id): return fixed[id]
	if id == "photo_bag_label_revealed": return {"brightness":_value_at(next,"ui.brightness",0)}
	if id == "cc98_top_ten_reached": return {"bdCount":3,"selectedPostIds":puzzle.get("bdSelectedPostIds",[]).duplicate(),"rank":"01"}
	var arrays: Dictionary={"cc98_optional_ac01_read":["optionalAc01Floors","floor","count"],"cc98_evidence_uploaded":["cc98UploadedEvidenceIds","evidenceId","uploadedCount"],"cc98_bd_post_selected":["bdSelectedPostIds","postId","selectedCount"],"library_recovery_evidence_uploaded":["recoverySubmittedEvidenceIds","evidenceId","submittedCount"]}
	if arrays.has(id):
		var fields: Array=arrays[id]; var values: Array=puzzle.get(fields[0],[])
		for value in values:
			if not old_puzzle.get(fields[0],[]).has(value): return {fields[1]:value,fields[2]:values.size()}
	return {}

func _map_native_actions(action: String, previous: Dictionary, next: Dictionary) -> void:
	# Chapter-one phone callsites: P00/P01/P03/P05/P07/P08/P09/P10/P11/P14.
	if action == "c1_start_alarm" and _rose(previous, next, "native.alarm_ringing"): _mapped_cue("phone_alarm_started")
	if action == "c1_dismiss_alarm" and _value_at(previous, "native.page") != _value_at(next, "native.page") and _value_at(next, "native.page") == "desktop":
		_mapped_cue("phone_alarm_stopped"); _native_effect("01_global_ui_button_tap_confirm", .9); _mapped_cue("wake_narration")
	if action == "c1_wake" and _rose(previous, next, "native.wake_warned"): _mapped_cue("wake_flash")
	if action == "c1_enter_home" and _value_at(previous, "native.page") == "desktop" and _value_at(next, "native.page") == "phone_home":
		_native_effect("01_global_ui_button_tap_confirm", .9)
	var legacy_flags: Dictionary = {"gearFallen":"17_p08_settings_gear_drop_flip","slashHalfDropped":"19_p03_avatar_slash_metal_drop","waterDropTaken":"18_p07_weather_water_drop_collect","plantWatered":"22_p10_plant_water_growth_step","plantLit":"23_p10_plant_light_growth_step","plantFertilized":"24_p10_plant_fertilizer_growth_step","checkinDone":"27_p11_checkin_submit_button_press"}
	for key in legacy_flags:
		if _rose(previous, next, "flags."+str(key)):
			_native_effect(str(legacy_flags[key]), .9 if key in ["plantWatered","plantLit","plantFertilized"] else .8)
	# Direct P10 BonsaiScene Sfx calls. Existing growth flag mappings above remain
	# the single source of successful water/light/fertilizer audio.
	if action == "c1_plant" and _value_at(previous,"native.page") == "bonsai" and not _rose(previous,next,"flags.plantWatered") and not _rose(previous,next,"flags.plantFertilized"):
		_native_effect("04_global_ui_invalid_drag_reject", .5)
	if action == "c1_flower" and bool(_value_at(next,"flags.flowerBloomed",false)) and not bool(_value_at(next,"flags.flowerEightTaken",false)) and bool(_value_at(next,"native.flower_eight_visible",false)):
		# Source plays a soft tap on each valid flower click, including a repeat.
		_native_effect("02_global_ui_button_tap_soft", .9)
	if action == "c1_collect_flower" and _rose(previous,next,"flags.flowerEightTaken"):
		_native_effect("10_global_digit_collect_fly_to_slot", .9)
	if _value_at(previous,"networkMode") != _value_at(next,"networkMode"): _native_effect("13_p05_control_center_network_toggle_switch")
	if _rose(previous,next,"items.towerKey"): _native_effect("20_p09_item_combine_key_forge_click_lock")
	# ActOneBootstrapController + native chapter1_2.gd. Facts gate successful events.
	var act_rules: Array = [
		["c2_recover_card","inventoryRecovered","act2_inventory_recovered"],
		["c2_identify","characterNamed","act2_character_named"],
		["c2_exercise_result","exerciseStarted","act2_exercise_started"],
		["c2_triangle","pushTriangleTaken","act2_push_triangle_collected"],
		["c2_weather_drop","weatherWaterTaken","act2_weather_water_collected"],
		["c2_mentor","mentorLineReleased","act2_mentor_line_released"],
		["c1_combine","rightArrowAssembled","act2_right_arrow_assembled"],
		["c2_balance","balanceShifted","act2_balance_shifted"],
		["c2_purchase_gamepad","gamepadPurchased","act2_gamepad_purchased"],
		["c2_use_gamepad","controlsInstalled","act2_gamepad_connected"],
		["c2_reserve","canLeaveDorm","act2_exit_ready"]]
	for rule in act_rules:
		if action == rule[0] and _rose(previous,next,"actOne."+str(rule[1])): _mapped_cue(str(rule[2]))
	var old_phase: String = str(_value_at(previous,"actOne.phase", "")); var new_phase: String = str(_value_at(next,"actOne.phase", ""))
	if action == "c1_intervention_result" and old_phase == "prologue" and new_phase == "friend_message_required": _mapped_cue("act2_entry_unlocked")
	if action == "c2_friend_exchange" and old_phase == "friend_message_required" and new_phase == "system_required": _mapped_cue("act2_friend_exchange_completed")
	if action == "c2_confront_system" and old_phase == "system_required" and new_phase == "inventory_required": _mapped_cue("act2_system_inventory_requested")
	if action == "c2_movement_quest" and old_phase == "system_return_required" and new_phase == "movement_required": _mapped_cue("act2_movement_quest_started")
	if action == "c2_inspect_character" and _rose(previous,next,"actOne.characterPromptSeen") and not bool(_value_at(next,"actOne.characterNamed", false)): _mapped_cue("act2_character_cannot_hear")
	if old_phase != new_phase and new_phase == "complete" and action.begins_with("c2_"): _mapped_cue("act2_movement_quest_completed")
	if _value_at(previous,"rpgScene") != _value_at(next,"rpgScene"):
		var scene: String = str(_value_at(next,"rpgScene", ""))
		if scene == "dorm_hub": _mapped_cue("rpg_dorm_room_opened")
		if scene == "library_interior": _mapped_cue("rpg_library_room_opened")
	_map_library(action,previous,next)

func _map_library(action: String, previous: Dictionary, next: Dictionary) -> void:
	# LibraryFinalsController.ts events and library022.gd share these persisted fields.
	var path: String = "ui.libraryFinalsPuzzle."
	var rules: Array = [
		["lib_record","entranceRecordRead","library_entrance_record_read"],
		["lib_backpack","backpackInspected","library_occupied_seat_found"],
		["lib_note","occupancyNoteCollected","library_occupancy_note_collected"],
		["lib_investigate","investigationOpened","cc98_occupation_post_opened"],
		["lib_catalog_search","catalogSearchCompleted","library_catalog_results_shown"],
		["lib_catalog_select","callNumberCollected","library_catalog_match_found"],
		["lib_shelf","archivedRuleCollected","library_archived_rule_opened"],
		["lib_read_rule","archivedRuleRead","library_archived_rule_recovered"],
		["lib_dim_photo","photoDimmed","photo_bag_label_revealed"],
		["lib_item_report","itemReportGenerated","photo_bag_report_generated"],
		["lib_scan_result","nonPersonProofStamped","library_bag_nonperson_proof_issued"],
		["lib_receipt","seatReceiptCollected","library_seat_receipt_recovered"],
		["lib_audit","presenceProofCollected","tiyi_presence_proof_issued"],
		["lib_generate_pass","evictionPassGenerated","library_seat_release_pass_issued"],
		["lib_apply_pass","backpackEvicted","library_seat_release_pass_applied"],
		["lib_apply_pass","backpackEvicted","library_backpack_evicted"],
		["lib_sit","playerSeated","library_seat_recovered"]]
	for rule in rules:
		if action == rule[0] and _rose(previous,next,path+str(rule[1])): _mapped_cue(str(rule[2]))
	var arrays: Array = [["lib_optional_ac01","optionalAc01Floors","cc98_optional_ac01_read"],["lib_upload","cc98UploadedEvidenceIds","cc98_evidence_uploaded"],["lib_bd_select","bdSelectedPostIds","cc98_bd_post_selected"],["lib_recovery_upload","recoverySubmittedEvidenceIds","library_recovery_evidence_uploaded"]]
	for rule in arrays:
		if action == rule[0] and _value_at(next,path+str(rule[1]),[]).size() > _value_at(previous,path+str(rule[1]),[]).size(): _mapped_cue(str(rule[2]))
	var old_phase: String = str(_value_at(previous,"ui.libraryFinalsPhase", "")); var new_phase: String = str(_value_at(next,"ui.libraryFinalsPhase", ""))
	if old_phase != new_phase:
		var phases: Dictionary = {"library_route_unlocked":"library_route_unlocked","library_entered":"library_entered","bd_briefing":"cc98_evidence_set_completed","top_ten_reached":"cc98_top_ten_reached","recovery_application":"library_recovery_application_opened"}
		if phases.has(new_phase): _mapped_cue(str(phases[new_phase]))
	if action == "lib_audit" and int(_value_at(next,path+"auditAttemptCount",0)) > int(_value_at(previous,path+"auditAttemptCount",0)) and not bool(_value_at(next,path+"presenceProofCollected",false)): _mapped_cue("tiyi_presence_audit_rejected")
	if action == "lib_dialogue_next" and _value_at(previous,"native.lib_dialogue_index") != _value_at(next,"native.lib_dialogue_index"):
		_mapped_cue("library_story_line", {"subtitleKey":"library_story_library_friend_contacted_%02d" % (int(_value_at(next,"native.lib_dialogue_index",0))+1)})

func _increased(previous: Dictionary, next: Dictionary, path: String) -> bool:
	return int(_value_at(next,path,0)) > int(_value_at(previous,path,0))

func _fact_added(previous: Dictionary, next: Dictionary, id: String) -> bool:
	return not _value_at(previous,"chapter4.factIds",[]).has(id) and _value_at(next,"chapter4.factIds",[]).has(id)

func _map_chapter3(action: String, previous: Dictionary, next: Dictionary, result: Dictionary) -> void:
	if not action.begins_with("c3_") and not action.begins_with("c35_"): return
	var c: Dictionary = next.get("canteenHunt", {}); var old_c: Dictionary = previous.get("canteenHunt", {})
	var t: Dictionary = next.get("theaterHunt", {}); var old_t: Dictionary = previous.get("theaterHunt", {})
	var q: Dictionary = next.get("qizhenLake", {})
	if action.begins_with("c3_target:"):
		for tray_id in c.get("carriedTrayIds",[]):
			if not old_c.get("carriedTrayIds",[]).has(tray_id):
				_mapped_cue("canteen_tray_slide_started",{"trayId":tray_id})
				schedule_cue("canteen_tray_slide_completed",{"trayId":tray_id},100 if bool(_value_at(next,"native.settings.reduced_motion",false)) else 360)
	if action == "c3_order" and _increased(previous,next,"canteenHunt.orderAttemptCount"):
		_mapped_cue("canteen_order_solved" if c.get("orderedMenuOption") == "D" else "canteen_order_wrong", {"optionId":c.get("orderedMenuOption")})
	if action.begins_with("c3_target:") and _increased(previous,next,"canteenHunt.pickupAttemptCount") and old_c.get("orderedMenuOption") in ["A","B","C","E"]:
		var option: String = str(old_c.orderedMenuOption)
		_mapped_cue("canteen_wrong_meal_collected", {"optionId":option,"itemId":{"A":"canteenRealBun","B":"canteenCluelessSoyMilk","C":"canteenEdgeEgg","E":"canteenUselessCongee"}[option],"windowId":{"A":"1","B":"2","C":"4","E":"5"}[option]})
	if action.begins_with("c3_target:") and previous.get("rpgScene") == "canteen_interior" and next.get("rpgScene") == "campus_bootstrap": _mapped_cue("canteen_returned_to_campus")
	if action == "c3_bike_inspect" and _rose(previous,next,"canteenHunt.bikeCodeRead"): _mapped_cue("canteen_bike_code_read")
	if action == "c3_bike_clean" and _rose(previous,next,"canteenHunt.bikeLockCleaned"): _mapped_cue("canteen_bike_lock_cleaned")
	if action == "c3_chase" and result.get("game",{}).get("type") == "chase": _mapped_cue("canteen_chase_started")
	if action == "c3_chase_result" and _rose(previous,next,"canteenHunt.chaseCompleted"):
		_mapped_cue("canteen_chase_completed", {"collisions":c.get("chaseCollisions",0),"distance":755,"lives":c.get("chaseBestLives",0)})
	var theater_flags: Dictionary = {"posterCleaned":"theater_poster_cleaned","admitted":"theater_ticket_admitted","propBoxOpened":"theater_prop_box_opened","paperDusted":"theater_paper_dusted","decoyRevealed":"theater_reversal_completed"}
	for flag in theater_flags:
		if _rose(previous,next,"theaterHunt."+str(flag)): _mapped_cue(str(theater_flags[flag]))
	if action == "c3_ticket_claim" and old_t.get("cc98TicketCommissionPhase") != t.get("cc98TicketCommissionPhase"):
		if t.get("cc98TicketCommissionPhase") == "first_wave_failed": _mapped_cue("theater_ticket_first_wave_slow", {"releaseWave":1,"surface":"phone"})
		elif t.get("cc98TicketCommissionPhase") == "delivered":
			var wave: int = int(t.get("cc98TicketClaimedWave",1))
			_mapped_cue("theater_ticket_first_wave_cellular_success" if wave == 1 else "theater_ticket_second_wave_success", {"releaseWave":wave,"surface":"phone"})
	if action == "c3_ticket_code" and _rose(previous,next,"items.theaterTicketHalfB"): _mapped_cue("theater_ticket_printed", {"code":"0832"})
	if action == "c3_ticket_combine" and _rose(previous,next,"items.temporaryTheaterTicket"): _mapped_cue("theater_ticket_combined")
	for id in t.get("collectedProgramIds", []):
		if not old_t.get("collectedProgramIds", []).has(id): _mapped_cue("theater_program_collected", {"programId":id})
	if action == "c3_program_submit":
		if _increased(previous,next,"theaterHunt.programWrongAttempts"): _mapped_cue("theater_program_order_wrong")
		elif old_t.get("phase") == "program_search" and t.get("phase") == "prop_setup": _mapped_cue("theater_program_order_solved")
	if old_t.get("phase") == "spotlight_ready" and t.get("phase") == "spotlight_hunt": _mapped_cue("theater_spotlight_started")
	for clue in ["bridge","reflection"]:
		if action == "c3_clue:"+clue and _rose(previous,next,"qizhenLake."+clue+"ClueFound"): _mapped_cue("qizhen_"+clue+"_clue_found", {"clueId":clue})
	if action == "c3_map_confirm" and _value_at(previous,"qizhenLake.phase") == "location_search" and q.get("phase") == "lake_unlocked":
		_mapped_cue("qizhen_location_solved", {"locationId":"qizhen_lake","clueIds":q.get("mapClueIds",[]).duplicate()})
	if action.begins_with("c3_lake_target:") and previous.get("rpgScene") == "qizhen_lake" and next.get("rpgScene") == "campus_qizhen_loop": _mapped_cue("qizhen_lake_left")
	if action == "c35_begin" and _rose(previous,next,"chapterThreeInterlude.recoveryOpened"): _mapped_cue("chapter35_recovery_opened")

func _map_chapter4(action: String, previous: Dictionary, next: Dictionary, result: Dictionary) -> void:
	if not action.begins_with("c4_"): return
	var before: Dictionary = previous.get("chapter4", {}); var after: Dictionary = next.get("chapter4", {})
	if action == "c4_clock_set" and before.get("timeState") != after.get("timeState"):
		_mapped_cue("chapter4_time_swap_committed", {"previousPhase":before.get("phase"),"phase":after.get("phase"),"previousTimeState":before.get("timeState"),"timeState":after.get("timeState")})
	if action == "c4_lamp_switch" and result.get("world_effect",{}).get("kind") == "bakery_stop":
		var bounds: Dictionary=source.get("chapter4Audio",{}).get("bakeryConveyor",{})
		var player: Dictionary=result.world_effect.get("player",{})
		if not bounds.is_empty() and player.has("x") and player.has("y"):
			var x: float=float(player.x); var y: float=float(player.y)
			var dx: float=maxf(maxf(float(bounds.x)-x,0),x-float(bounds.x)-float(bounds.width))
			var dy: float=maxf(maxf(float(bounds.y)-y,0),y-float(bounds.y)-float(bounds.height))
			_mapped_cue("chapter4_bakery_conveyor_stop",{"sourceWorldX":float(bounds.x)+float(bounds.width)/2,"playerWorldX":x,"distance":sqrt(dx*dx+dy*dy),"phase":"lamp_accepted"})
	if action == "c4_plate" and _fact_added(previous,next,"positioning_plate_collected"):
		_mapped_cue("room204_drawer_opened", {"phase":before.get("phase"),"targetId":"a2_room204_podium_drawer"})
	if action == "c4_cart_oil" and _fact_added(previous,next,"cart_wheel_repaired"):
		_mapped_cue("maintenance_cart_wheel_repaired", {"phase":before.get("phase"),"targetId":"a1_cleaning_cart_wheel","clockGearAligned":true})
		_mapped_cue("clock_gear_repaired", {"phase":before.get("phase"),"targetId":"a1_cleaning_cart_wheel","linkedAction":true})
		_mapped_cue("maintenance_cart_roll_started",{"phase":"maintenance_repair","durationMs":int(source.get("chapter4Audio",{}).get("maintenancePushDurationMs",900))})
	if action == "c4_minute_stolen" and before.get("phase") != "blackout_light_grid" and after.get("phase") == "blackout_light_grid":
		_mapped_cue("blackout_committed", {"previousPhase":before.get("phase"),"phase":"blackout_light_grid","timeState":"0754_blackout","mask":after.get("lightGrid",{}).get("mask")})
	if action.begins_with("c4_toggle_") and before.get("lightGrid",{}).get("mask") != after.get("lightGrid",{}).get("mask"):
		_mapped_cue("power_zone_toggled", {"zoneId":action.trim_prefix("c4_toggle_"),"previousMask":before.get("lightGrid",{}).get("mask"),"mask":after.get("lightGrid",{}).get("mask")})
	if action == "c4_lock_power" and _fact_added(previous,next,"light_grid_locked"):
		_mapped_cue("power_grid_locked", {"mask":after.get("lightGrid",{}).get("mask"),"phase":"final_chase","canruoStarLampPrimed":true})
	if action == "c4_install_minute" and _fact_added(previous,next,"final_minute_installed"):
		_mapped_cue("final_minute_installed", {"previousPhase":before.get("phase"),"phase":"morning_checkin","timeState":"0755_morning","worldTimeSeconds":28500,"phoneStatusTimeSeconds":28500,"phoneStatusTimeTrusted":true})
	var completed: bool = after.get("phase") == "exterior_closure"
	if action == "c4_checkin_card" and _rose(previous,next,"chapter4.checkinCardAccepted"): _mapped_cue("morning_checkin_card_accepted", {"complete":completed})
	if action == "c4_checkin_paper" and _rose(previous,next,"chapter4.checkinPaperAccepted"): _mapped_cue("morning_checkin_paper_accepted", {"complete":completed})
	if before.get("phase") == "morning_checkin" and completed:
		_mapped_cue("morning_checkin_completed", {"timeState":"0755_morning","worldTimeSeconds":28500,"phoneStatusTimeSeconds":28500,"phoneStatusTimeTrusted":true,"message":"外面亮了一下。"})
