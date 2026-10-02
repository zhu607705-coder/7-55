extends VBoxContainer
## Live presentation reads the transient audition capability, never state writes.
var session: RefCounted
var recording: Dictionary
var bar: ProgressBar
var caption: Label

func setup(value: RefCounted, source: Dictionary) -> void:
	session = value
	recording = source
	bar = ProgressBar.new()
	bar.custom_minimum_size.y = 8
	bar.show_percentage = false
	bar.max_value = session.duration_ms
	add_child(bar)
	caption = Label.new()
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_size_override("font_size", 12)
	add_child(caption)

func _process(_delta: float) -> void:
	if session == null or bar == null: return
	bar.value = session.position_ms
	var text: String = "%.1f / %.1f 秒" % [session.position_ms / 1000.0, session.duration_ms / 1000.0]
	if session.fallback:
		text = "音频暂不可用 · 声音记录\n" + text
		for part: Dictionary in recording.get("soundEvents", []):
			if session.position_ms >= float(part.startMs) and session.position_ms <= float(part.endMs): text += "\n" + str(part.labelZh)
	caption.text = text
