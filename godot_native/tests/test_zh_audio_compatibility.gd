extends SceneTree
## Exercises the existing cue path without playing or generating audio.
const Director = preload("res://scripts/media/audio_director.gd")
const Session = preload("res://scripts/presentation/c3_narrative_session.gd")
const Library = preload("res://scripts/presentation/library_story_session.gd")
const Opening = preload("res://scripts/presentation/c3_scene_session.gd")
const DisplayFixture = preload("res://tests/zh_text_fixture.gd")
var checks: int = 0
var errors: int = 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		errors += 1
		push_error(label)

func read_json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var audio: Dictionary = read_json("res://data/native/audio-director-source.json")
	var baseline: Dictionary = read_json("res://tests/fixtures/zh_audio_contract.json")
	var revisions: Array = []
	if FileAccess.file_exists("res://data/zh_text_revisions.json"):
		var document: Dictionary = read_json("res://data/zh_text_revisions.json")
		revisions = document.revisions + document.get("nativeRevisions", [])
	var director := Director.new()
	root.add_child(director)
	director.set_process(false)
	director.source = audio.duplicate(true)
	director._ready_to_play = true
	var owner := Node.new()
	root.add_child(owner)
	var state: Dictionary = {"native":{"chapter":3,"scene":"theater_interior","settings":{}}}
	var state_before: String = JSON.stringify(state)
	for text: String in baseline.chapter3KeysBySubtitle:
		director.feedback(text)
		check(director.scheduled.size() == 1, "legacy Chinese schedules one existing cue")
		if not director.scheduled.is_empty():
			check(director.scheduled[0].cue.subtitleKey == baseline.chapter3KeysBySubtitle[text], "legacy Chinese keeps stable key")
		director.scheduled.clear()
		director.emitted_this_turn.clear()
	for revision: Dictionary in revisions:
		var old_text: String = revision.oldText
		var new_text: String = revision.newText
		var key: String = str(baseline.chapter3KeysBySubtitle.get(Session._normalize(old_text), ""))
		if not key.is_empty():
			director.feedback(old_text)
			var original_cue: Dictionary = director.scheduled[0].cue.duplicate(true)
			director.scheduled.clear()
			director.emitted_this_turn.clear()
			director.feedback(" \n" + new_text + "\t ")
			check(director.scheduled.size() == 1, "revised Chinese schedules one existing cue")
			if not director.scheduled.is_empty():
				check(director.scheduled[0].cue == original_cue, "old/new Chinese preserve clip, key and all cue properties")
				director.feedback(old_text)
				check(director.scheduled.size() == 1, "old/new aliases share existing same-turn deduplication")
			director.scheduled.clear()
			director.emitted_this_turn.clear()
			var story := Session.new(state, {"id":"text_revision_test","scene":"theater_interior","lines":[old_text,new_text]})
			check(story.attach(state, owner), "revised C3 queue attaches through existing owner")
			while story.status == "playing":
				story.frame(state, 100, owner)
			var cues: Array = story.take_cues()
			check(cues == [{"id":"chapter3_story_line","payload":{"subtitleKey":key}},{"id":"chapter3_story_line","payload":{"subtitleKey":key}}], "old/new queue lines each emit exactly one identical voice key")
		if revision.sourceFile == "chapter3-theater.content.json" and old_text != new_text:
			var before := Session.new(state, {"id":"text_revision_clock","scene":"theater_interior","lines":[old_text,old_text]})
			var after := Session.new(state, {"id":"text_revision_clock","scene":"theater_interior","lines":[new_text,new_text]})
			check(before.duration_ms == after.duration_ms, "theater copy changes preserve total queue time")
			for index in range(before.lines.size()):
				check(before.lines[index].atMs == after.lines[index].atMs and before.lines[index].durationMs == after.lines[index].durationMs, "theater copy changes preserve line duration and onset")
	# Library retains the stable source minimum and can extend unvoiced reading
	# time. Its catalog key, cue count and explicit advance behavior stay the same.
	for key: String in audio.storyLines:
		if not key.begins_with("library_story_"):
			continue
		var sequence_id: String = key.trim_prefix("library_story_").rsplit("_", true, 1)[0]
		var index: int = int(key.rsplit("_", true, 1)[1]) - 1
		var authored: Array = []
		for n in range(index + 1):
			var line_key: String = "library_story_%s_%02d" % [sequence_id,n + 1]
			authored.append({"speaker":audio.storyLines[line_key].speaker,"text":audio.storyLines[line_key].subtitleZh})
		var library := Library.new({}, sequence_id, authored)
		check(library.durations_ms[index] == maxi(int(audio.textDurationMsByKey[key]),DisplayFixture.reading_ms(audio.storyLines[key].subtitleZh)), "unvoiced library text retains source minimum plus approved reading time")
		check(not audio.storyLines[key].has("voiceRole"), "library text remains unvoiced")
		library.line_index = index
		library._line_cue()
		check(library.take_cues() == [{"id":"library_story_line","payload":{"subtitleKey":key}}], "library retains exact original key and cue count")
	var opening := Opening.new({}, "opening")
	for beat: Dictionary in opening.beats:
		if beat.lineIndex == null: continue
		var key: String = "library_story_library_friend_contacted_%02d" % [int(beat.lineIndex)+1]
		var original_text: String = baseline.storyLineSubtitles[key]
		var expected_ms: int = clampi(760 + original_text.to_utf16_buffer().size()/2 * 48, 1200, 1900)
		if opening.opening_durations.has(key): expected_ms = maxi(expected_ms,DisplayFixture.reading_ms(opening.lines[int(beat.lineIndex)].text))
		check(beat.durationMs == expected_ms, "022 unvoiced reading extension keeps source minimum and unchanged line order")
	check(JSON.stringify(state) == state_before, "subtitle compatibility cannot change saved or progression state")
	director._ready_to_play = false
	director.queue_free()
	owner.queue_free()
	await process_frame
	print("NATIVE_ZH_AUDIO_COMPATIBILITY checks=", checks, " errors=", errors)
	quit(1 if errors else 0)
