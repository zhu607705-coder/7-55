extends Control
## Source PhoneBatteryPrank presentation. Never mutates battery or navigation.
var deadline: int = -1
var used: bool = false
var read_state: Callable
var notice: Label
var panel: PanelContainer
var audio: AudioStreamPlayer
var retiring_playbacks: Array[WeakRef]=[]

func setup(state_reader: Callable) -> void:
	read_state = state_reader
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 105
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = PanelContainer.new()
	panel.name = "BatteryPrankCard"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("101923")
	style.border_color = Color("a5dcd6")
	style.set_border_width_all(2)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel",style)
	add_child(panel)
	notice = Label.new()
	notice.name = "BatteryPrankText"
	notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.add_theme_font_size_override("font_size",16)
	notice.add_theme_color_override("font_color",Color("d4f7e6"))
	panel.add_child(notice)
	resized.connect(_layout_notice)
	_layout_notice()
	visible = false

func _layout_notice() -> void:
	if not is_instance_valid(panel): return
	# Main supplies the logical phone/world size and one uniform scale.
	# Keep the status bar and app navigation clear in portrait phone mode.
	var phone_surface := size.y > size.x
	var width := minf(390 if phone_surface else 360, maxf(1, size.x-40))
	panel.position = Vector2((size.x-width)/2.0 if phone_surface else 20,112 if phone_surface else 20)
	panel.custom_minimum_size = Vector2(width,0)
	panel.size = Vector2(width,0)

func consume_reserve(percent: int) -> void:
	if percent != 1 or used: return
	used = true
	deadline = Time.get_ticks_msec()+10000
	visible = true
	# Exact source notification asset, if present; missing sound is harmless.
	var path: String = "res://assets/audio/sfx/07_p14_chat_message_notification_ping.mp3"
	if ResourceLoader.exists(path):
		audio = AudioStreamPlayer.new()
		audio.stream = load(path) as AudioStream
		audio.volume_db = linear_to_db(0.8)
		add_child(audio)
		audio.play()
		if audio.has_stream_playback(): retiring_playbacks.append(weakref(audio.get_stream_playback()))
		audio.finished.connect(_stop_audio)

func reset() -> void:
	deadline = -1
	used = false
	visible = false
	_stop_audio()

func view(now: int) -> Dictionary:
	if deadline < 0 or now >= deadline+3500: return {}
	if now >= deadline: return {"kind":"joke","text":"吓吓你的","seconds":0}
	return {"kind":"warning","text":"请在 10秒之内充电，不然手机就会自动关机。","seconds":int(ceil(float(deadline-now)/1000))}

func _process(_delta: float) -> void:
	if deadline < 0: return
	if read_state.is_valid() and int(read_state.call().get("phoneBattery",{}).get("percent",100)) > 1: reset(); return
	var current: Dictionary = view(Time.get_ticks_msec())
	visible = not current.is_empty()
	if notice!=null and visible: notice.text = "手机系统\n"+str(current.text)+("\n剩余 %d 秒" % int(current.seconds) if current.kind=="warning" else "")

func _stop_audio() -> void:
	if is_instance_valid(audio):
		if audio.has_stream_playback(): retiring_playbacks.append(weakref(audio.get_stream_playback()))
		audio.stop(); audio.stream=null; audio.queue_free()
	audio=null

func shutdown() -> bool:
	# The ping is a separate AudioServer playback from the memo host. Retire all
	# reset/rearmed pings too; waiting only for memo playbacks misses this owner.
	reset(); set_process(false); read_state=Callable()
	var timeout: int=Time.get_ticks_msec()+5000
	while true:
		retiring_playbacks=retiring_playbacks.filter(func(ref: WeakRef) -> bool:return ref.get_ref()!=null)
		if retiring_playbacks.is_empty(): return true
		if Time.get_ticks_msec()>=timeout:
			push_error("Battery notification playback did not retire within five seconds.")
			return false
		await get_tree().process_frame
	return false

func _exit_tree() -> void:
	_stop_audio()
