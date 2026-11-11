extends VBoxContainer
## Playback and waveform stay local. The chapter controller owns the reviewed cue.
signal broadcast_reviewed

const Palette = preload("res://scripts/ui/chapter35_palette.gd")
const Recording = preload("res://assets/native/chapter35_recovery_20261023/late_hall_recording.ogg")
const CUES := [
	[0.0,"脚步和门声","急促的脚步停住。随后是推拉玻璃门缓慢回弹的声音。"],
	[2.0,"手机提示音","短促的接入提示音，接着传来一声杂音。"],
	[3.0,"广播开头","广播报时：二十二点四十五分。开始清楼。"],
]
const LEVELS := [0.264,0.151,0.288,0.350,0.159,0.138,0.134,0.689,0.566,0.201,0.119,0.068,0.458,0.241,0.199,0.104,0.571,0.567,0.363,0.162,0.121,1.000,0.430,0.000,0.005,0.294,0.350,0.197,0.213,0.062,0.000,0.000,0.000,0.139,0.048,0.075,0.791,0.386,0.710,0.562,0.570,0.168,0.468,0.382,0.611,0.363,0.516,0.351,0.000,0.104,0.684,0.320,0.380,0.499,0.646,0.574,0.103,0.000,0.000,0.000]

var player: AudioStreamPlayer
var waveform: Button
var seek: HSlider
var toggle: Button
var caption: Label
var position_label: Label
var reviewed := false
var furthest := 0.0

func build(pages, already_reviewed: bool, volume: float) -> void:
	reviewed=already_reviewed
	add_theme_constant_override("separation",9)
	player=AudioStreamPlayer.new()
	player.stream=Recording
	player.volume_db=linear_to_db(maxf(.001,clampf(volume,0.0,1.0)))
	add_child(player)
	player.finished.connect(_finished)
	var row := HBoxContainer.new()
	add_child(row)
	toggle=pages.button(row,"播放录音",_toggle)
	toggle.name="C35PlayHallRecording"
	toggle.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	position_label=pages.label("00:00 / 00:05",15,Palette.SECONDARY)
	position_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	row.add_child(position_label)
	waveform=Button.new()
	waveform.name="C35HallWaveform"
	waveform.focus_mode=Control.FOCUS_NONE
	waveform.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	for style: String in ["normal","hover","pressed","focus","disabled"]:
		waveform.add_theme_stylebox_override(style,StyleBoxEmpty.new())
	waveform.pressed.connect(_wave_pressed)
	waveform.custom_minimum_size.y=52
	waveform.draw.connect(_draw_wave)
	add_child(waveform)
	seek=HSlider.new()
	seek.name="C35RecordingSeek"
	seek.accessibility_name="现场录音进度"
	seek.min_value=0
	seek.max_value=Recording.get_length()
	seek.step=.025
	seek.custom_minimum_size.y=34
	seek.value_changed.connect(_seek)
	add_child(seek)
	var markers := HBoxContainer.new()
	markers.add_theme_constant_override("separation",5)
	add_child(markers)
	for i: int in CUES.size():
		var cue := pages.button(markers,CUES[i][1],_play_cue.bind(i)) as Button
		cue.name="C35RecordingCue"+str(i)
		cue.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	caption=pages.label("",15,Palette.SECONDARY)
	caption.custom_minimum_size.y=38
	add_child(caption)
	_render()

func _wave_pressed() -> void:
	var at: float=clampf(waveform.get_local_mouse_position().x/maxf(1,waveform.size.x)*Recording.get_length(),0,Recording.get_length())
	for i: int in CUES.size():
		if absf(at-float(CUES[i][0]))<=.24:
			_play_cue(i)
			return
	seek.value=at

func _draw_wave() -> void:
	waveform.draw_rect(Rect2(Vector2.ZERO,waveform.size),Palette.NIGHT)
	var unit := waveform.size.x/LEVELS.size()
	for i: int in LEVELS.size():
		var x := (i+.5)*unit
		var height: float=4.0+LEVELS[i]*38.0
		var ink := Palette.PENDING if i*5.0/LEVELS.size()<=seek.value else Palette.PALE
		waveform.draw_rect(Rect2(x-unit*.24,(waveform.size.y-height)*.5,unit*.48,height),ink)
	for cue: Array in CUES:
		var x: float=clampf(float(cue[0])/5.0*waveform.size.x,1,waveform.size.x-1)
		waveform.draw_line(Vector2(x,0),Vector2(x,8),Palette.PENDING,2)

func _toggle() -> void:
	if player.playing:
		player.stop()
	else:
		player.play(0.0 if seek.value>=Recording.get_length()-.1 else seek.value)
	_render()

func _seek(at: float) -> void:
	if player.playing: player.seek(minf(at,Recording.get_length()-.03))
	_render()

func _play_cue(index: int) -> void:
	var at: float=CUES[index][0]
	seek.set_value_no_signal(at)
	player.play(at)
	_render()

func _process(_delta: float) -> void:
	if not is_instance_valid(player) or not player.playing: return
	var at := player.get_playback_position()
	seek.set_value_no_signal(at)
	furthest=maxf(at,furthest)
	_render()

func _finished() -> void:
	if not is_instance_valid(seek): return
	seek.set_value_no_signal(Recording.get_length())
	if furthest>=4.3 and not reviewed:
		reviewed=true
		broadcast_reviewed.emit()
	_render()

func _render() -> void:
	if not is_instance_valid(caption): return
	toggle.text="暂停" if player.playing else "播放录音"
	position_label.text="00:%02d / 00:05" % floori(seek.value)
	var cue := 0 if seek.value<2.0 else (1 if seek.value<3.0 else 2)
	caption.text=CUES[cue][2] if cue<2 or reviewed else "听清广播开头的报时。"
	waveform.queue_redraw()
