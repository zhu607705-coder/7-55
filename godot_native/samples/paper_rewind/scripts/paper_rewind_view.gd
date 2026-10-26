extends Control

const Model = preload("res://scripts/paper_rewind_model.gd")
const Stage = preload("res://scripts/paper_rewind_stage.gd")
const FONT = preload("res://assets/MorningNote-Regular.ttf")

var model := Model.new()
var stage: Control
var content: VBoxContainer
var clock_label: Label
var slider: HSlider
var actions: GridContainer
var play_button: Button
var rewind_button: Button
var retry_button: Button
var reset_button: Button
var skip_button: Button
var reduced: CheckButton
var sound_toggle: CheckButton
var broadcast_player: AudioStreamPlayer
var help_label: Label
var options_button: Button
var secondary: VBoxContainer
var touch_sessions: Dictionary = {}
var _suppressed_touch_releases: Dictionary = {}
var _last_layout_size := Vector2.ZERO
var _touch_controls: Array[Control] = []
var presentation_time := 0.0
var _focus_suspended := false
var _paper_press_point := Vector2.ZERO
var _paper_drag_started := false
var _paper_press_landed := false

func _ready() -> void:
	_build_ui()
	resized.connect(_layout)
	_layout()
	# Enter a living scene: the first sheet really flies, without a Start prompt.
	# Preserve the approved entry point: it has already passed the closed folder.
	# Auto-flight must not introduce an early-tap bypass of the rewind experiment.
	model.time = Model.ENTRY_TIME
	model.start()
	_refresh()
	stage.paper_grip.grab_focus()

func _build_ui() -> void:
	# Match the project's bundled typography without relying on ignored imports.
	var font: FontFile = FONT.duplicate()
	font.allow_system_fallback = false
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.multichannel_signed_distance_field = false
	var theme_resource := Theme.new()
	theme_resource.default_font = font
	theme_resource.default_font_size = 20
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("2a4149") if state != "pressed" else Color("526a6b")
		style.border_color = Color("a9c8c4") if state == "focus" else Color("5f7d80")
		style.set_border_width_all(2 if state == "focus" else 1)
		style.set_corner_radius_all(4)
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		theme_resource.set_stylebox(state, "Button", style)
	theme_resource.set_color("font_color", "Button", Color("ede5d3"))
	theme_resource.set_color("font_disabled_color", "Button", Color("8b9b9a"))
	theme = theme_resource
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 0)
	scroll.add_child(margin)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 0)
	margin.add_child(content)
	stage = Stage.new()
	stage.name = "Desk"
	stage.model = model
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(stage)
	stage.folder_button.pressed.connect(_open_folder)
	stage.paper_grip.pressed_at.connect(_paper_pressed)
	stage.paper_grip.dragged_to.connect(_paper_dragged)
	stage.paper_grip.released.connect(_paper_released)
	stage.paper_grip.nudged.connect(_paper_nudged)
	stage.paper_grip.activated.connect(_play_or_pause)
	_touch_controls.append(stage.folder_button)
	_touch_controls.append(stage.paper_grip)
	_touch_controls.append(stage.history_window)
	options_button = Button.new()
	options_button.name = "Options"
	options_button.text = "···"
	options_button.accessibility_name = "设置和操作帮助"
	options_button.custom_minimum_size = Vector2(48, 44)
	options_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	options_button.pressed.connect(_toggle_options)
	add_child(options_button)
	_touch_controls.append(options_button)
	secondary = VBoxContainer.new()
	secondary.name = "SecondaryOptions"
	secondary.visible = false
	secondary.add_theme_constant_override("separation", 8)
	content.add_child(secondary)
	var settings_title := _label("设置 / 独立样例（不写入正式进度）", 20)
	settings_title.custom_minimum_size.y = 58
	secondary.add_child(settings_title)
	clock_label = _label("", 18)
	clock_label.name = "TimePreview"
	secondary.add_child(clock_label)
	slider = HSlider.new()
	slider.name = "PaperTimeline"
	slider.min_value = 0.0
	slider.max_value = Model.DURATION
	slider.step = 0.01
	slider.custom_minimum_size.y = 44
	slider.accessibility_name = "纸张时间预览，左右方向键调整；调整后暂停"
	slider.value_changed.connect(_seek)
	slider.drag_started.connect(func() -> void: model.pause(); _refresh())
	secondary.add_child(slider)
	_touch_controls.append(slider)
	actions = GridContainer.new()
	actions.name = "Actions"
	actions.columns = 3
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	secondary.add_child(actions)
	play_button = _button("开始试验", _play_or_pause)
	play_button.name = "PlayPause"
	rewind_button = _button("倒带", _rewind)
	rewind_button.name = "Rewind"
	rewind_button.visible = false
	retry_button = _button("重试纸张", _retry)
	retry_button.name = "RetryPaper"
	reset_button = _button("重置全部", _reset)
	reset_button.name = "ResetAll"
	skip_button = _button("跳过 / 离开", _cancel)
	skip_button.name = "Skip"
	_button("操作帮助", _toggle_help).name = "Help"
	reduced = CheckButton.new()
	reduced.name = "ReducedMotion"
	reduced.text = "减少动态"
	reduced.custom_minimum_size.y = 44
	reduced.toggled.connect(func(value: bool) -> void: stage.reduced_motion = value; stage.refresh())
	secondary.add_child(reduced)
	_touch_controls.append(reduced)
	sound_toggle = CheckButton.new()
	sound_toggle.name = "BroadcastSound"
	sound_toggle.text = "广播声音（可选）"
	sound_toggle.custom_minimum_size.y = 44
	sound_toggle.toggled.connect(_sound_changed)
	secondary.add_child(sound_toggle)
	_touch_controls.append(sound_toggle)
	broadcast_player = AudioStreamPlayer.new()
	broadcast_player.name = "PrototypeBroadcastTone"
	broadcast_player.stream = _broadcast_tone()
	broadcast_player.volume_db = -36.0
	add_child(broadcast_player)
	help_label = _label("直接操作画面：拖动蓝色观察窗；按住纸张或纸影，沿轨迹往回拖。一只手留住纸，另一只手翻开文件夹；松开抓纸的手才继续。落稳后点击纸张收起。\n单指 / 鼠标也可以先布置桌面，再拖回纸张。键盘后备：Tab 选择物件，Enter / 空格操作；观察窗用方向键移动；纸张用左右键倒带，Enter 继续或收取。P 暂停，R 倒带，F 文件夹，Esc 离开。\n蓝窗只显示旧记录，不会拿出过去的物件。只有当前这张纸能局部倒带。广播停顿与声音、指示条同步，但不限制操作，不会停止世界。\n重试纸张保留桌面布置；重置全部还原样例。减少动态移除转动和残影，并将旧记录定格；当前纸张的必要运动保留。广播音为原型提示音，不是正式台词。", 18)
	help_label.name = "HelpText"
	help_label.visible = false
	secondary.add_child(help_label)

func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("e8e2d4"))
	return label

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y = 48
	button.pressed.connect(callback)
	actions.add_child(button)
	_touch_controls.append(button)
	return button

func _layout() -> void:
	if not stage:
		return
	if size != _last_layout_size and not touch_sessions.is_empty():
		_cancel_touch()
		model.pause()
	_last_layout_size = size
	var width := maxf(280.0, size.x)
	stage.custom_minimum_size.y = size.y
	options_button.position = Vector2(size.x - 60, 12)
	actions.columns = 2 if width < 600.0 else 3

func _toggle_options() -> void:
	_cancel_touch()
	model.pause()
	secondary.visible = not secondary.visible
	stage.visible = not secondary.visible
	get_node("Scroll").scroll_vertical = 0

func _process(delta: float) -> void:
	model.advance(delta)
	if not _focus_suspended and model.mode not in ["cancelled", "solved"]:
		presentation_time += delta
	stage.history_time = 4.8 if stage.reduced_motion else 3.8 + fmod(presentation_time, 1.4)
	stage.environment_time = presentation_time
	stage.broadcast_quiet = fmod(presentation_time, 8.0) >= 3.5
	stage.animate(delta)
	_refresh()

func _refresh() -> void:
	if not stage:
		return
	stage.refresh()
	var direction := "倒带" if model.mode == "rewind" else ("播放" if model.mode == "forward" else "静止")
	clock_label.text = "当前纸张 %.1f / %.1f 秒 · %s   |   文件夹：%s" % [model.time, Model.DURATION, direction, "撑开" if model.folder_open else "合上"]
	_update_sound()
	slider.set_value_no_signal(model.time)
	slider.editable = model.mode not in ["intro", "solved", "cancelled"]
	play_button.text = "暂停纸张" if model.mode in ["forward", "rewind"] else "继续纸张"
	play_button.disabled = model.mode in ["intro", "landed", "failed", "solved", "cancelled"] or (model.mode == "paused" and model.time >= Model.DURATION)
	rewind_button.disabled = model.mode in ["intro", "solved", "cancelled"] or model.time <= 0.0
	retry_button.disabled = model.mode in ["intro", "cancelled"]
	skip_button.disabled = model.mode == "cancelled"

func _play_or_pause() -> void:
	_focus_suspended = false
	if model.mode == "intro":
		model.start()
	elif model.mode == "landed":
		model.collect()
	elif model.mode in ["forward", "rewind"]:
		model.pause()
	else:
		model.play()
	_refresh()

func _rewind() -> void:
	_focus_suspended = false
	model.rewind()
	_refresh()

func _open_folder() -> void:
	if model.mode == "intro":
		model.start()
		model.pause()
	model.open_folder()
	_refresh()

func _seek(value: float) -> void:
	model.seek(value)
	_refresh()

func _retry() -> void:
	model.retry_paper()
	_refresh()

func _reset() -> void:
	_cancel_touch()
	model.reset()
	presentation_time = 0.0
	_focus_suspended = false
	stage.reset_history()
	secondary.visible = false
	stage.visible = true
	_refresh()
	stage.paper_grip.grab_focus()

func _cancel() -> void:
	_cancel_touch()
	model.cancel()
	_refresh()

func _toggle_help() -> void:
	help_label.visible = not help_label.visible

func _collect() -> void:
	model.collect()
	_refresh()

func _paper_pressed(point: Vector2) -> void:
	if model.mode in ["solved", "cancelled"]:
		return
	_focus_suspended = false
	_paper_press_point = point
	_paper_drag_started = false
	_paper_press_landed = model.mode == "landed"
	if model.mode == "intro":
		model.start()
	if model.mode == "failed":
		model.seek(7.8)
	else:
		model.pause()
	_refresh()

func _paper_dragged(point: Vector2) -> void:
	if model.mode in ["solved", "cancelled"] or point.distance_to(_paper_press_point) < 6.0 and not _paper_drag_started:
		return
	_paper_drag_started = true
	model.seek(stage.project_paper_time(point))
	_refresh()

func _paper_released(cancelled: bool) -> void:
	if model.mode in ["solved", "cancelled"]:
		return
	if not cancelled:
		if _paper_press_landed and not _paper_drag_started:
			model.collect()
		else:
			model.play()
	_refresh()

func _paper_nudged(seconds: float) -> void:
	if model.mode == "intro":
		model.start()
	model.seek(model.time + seconds)
	_refresh()

func _sound_changed(_enabled: bool) -> void:
	_update_sound()

func _update_sound() -> void:
	if not broadcast_player:
		return
	var audible := sound_toggle.button_pressed and not _focus_suspended and model.mode not in ["intro", "cancelled", "solved"]
	if audible and not broadcast_player.playing:
		broadcast_player.play()
	elif not audible:
		broadcast_player.stop()
	broadcast_player.volume_db = -80.0 if stage.broadcast_quiet else -36.0

func _broadcast_tone() -> AudioStreamWAV:
	# Deliberately quiet, original non-voice placeholder; no external audio source.
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = 4410
	var bytes := PackedByteArray()
	bytes.resize(8820)
	for index: int in range(4410):
		var sample := int(12000.0 * sin(TAU * 220.0 * index / 22050.0))
		bytes.encode_s16(index * 2, sample)
	stream.data = bytes
	return stream

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		_cancel_touch()
		_focus_suspended = true
		model.pause()
		if stage:
			_refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_P: _play_or_pause()
		KEY_R: _rewind()
		KEY_F: _open_folder()
		KEY_ESCAPE: _cancel()
		_: return
	get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	# Scene objects own independent fingers. Only secondary menu controls share
	# a mouse bridge. Global touch-to-mouse emulation is disabled in this project.
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device == -1:
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_suppressed_touch_releases.erase(event.index)
			if touch_sessions.has(event.index):
				get_viewport().set_input_as_handled()
				return
			var target := _touch_target(event.position)
			if target.is_empty() and touch_sessions.is_empty():
				return # Ordinary scrolling outside scene controls stays available.
			if target.is_empty() or _target_owned(target):
				target = "blocked"
			touch_sessions[event.index] = {"target": target, "last": event.position}
			match target:
				"paper": stage.paper_grip.begin_touch(event.position)
				"folder": stage.folder_drag_preview = 0.12
				"history": stage.history_window.grab_focus()
				"ui": _touch_mouse(event.position, true)
			get_viewport().set_input_as_handled()
		elif _suppressed_touch_releases.has(event.index):
			_suppressed_touch_releases.erase(event.index)
			get_viewport().set_input_as_handled()
		elif touch_sessions.has(event.index):
			var session: Dictionary = touch_sessions[event.index]
			touch_sessions.erase(event.index) # Callbacks may cancel/reset other owners.
			_end_touch(session, event.position, event.canceled)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and touch_sessions.has(event.index):
		var session: Dictionary = touch_sessions[event.index]
		var delta: Vector2 = event.position - session.last
		session.last = event.position
		match session.target:
			"paper": stage.paper_grip.move_touch(event.position)
			"folder": stage.folder_drag_preview = clampf(stage.folder_drag_preview - delta.y / 90.0, 0.12, 0.95)
			"history": stage.move_history(delta)
			"ui":
				var motion := InputEventMouseMotion.new()
				motion.position = event.position
				motion.global_position = event.position
				motion.relative = delta
				motion.button_mask = MOUSE_BUTTON_MASK_LEFT
				get_viewport().push_input(motion, true)
		get_viewport().set_input_as_handled()

func _target_owned(target: String) -> bool:
	for session: Dictionary in touch_sessions.values():
		if session.target == target:
			return true
	return false

func _touch_target(point: Vector2) -> String:
	if not get_node("Scroll").get_global_rect().has_point(point):
		return ""
	# Same front-to-back priority as rendering; a blue recorded page is never
	# mistaken for the physical paper under its read-only window.
	if stage.history_window.is_visible_in_tree() and stage.history_window.get_global_rect().has_point(point):
		return "history"
	if stage.paper_grip.is_visible_in_tree() and stage.paper_grip.get_global_rect().has_point(point):
		return "paper"
	if not stage.folder_button.disabled and stage.folder_button.get_global_rect().has_point(point):
		return "folder"
	for control: Control in _touch_controls:
		if control in [stage.history_window, stage.paper_grip, stage.folder_button]:
			continue
		if control.is_visible_in_tree() and control.get_global_rect().has_point(point):
			return "ui"
	return ""

func _end_touch(session: Dictionary, point: Vector2, cancelled: bool) -> void:
	match session.target:
		"paper": stage.paper_grip.end_touch(cancelled or not get_viewport_rect().has_point(point))
		"folder":
			stage.folder_drag_preview = 0.0
			if not cancelled and stage.folder_button.get_global_rect().has_point(point):
				_open_folder()
		"history": stage.history_window.cancel_drag()
		"ui": _touch_mouse(Vector2(-1000, -1000) if cancelled else point, false)

func _touch_mouse(point: Vector2, down: bool) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	get_viewport().push_input(motion, true)
	var button := InputEventMouseButton.new()
	button.position = point
	button.global_position = point
	button.button_index = MOUSE_BUTTON_LEFT
	button.pressed = down
	get_viewport().push_input(button, true)

func _cancel_touch() -> void:
	var sessions := touch_sessions.duplicate(true)
	touch_sessions.clear()
	for id: int in sessions:
		_suppressed_touch_releases[id] = true
		_end_touch(sessions[id], Vector2(-1000, -1000), true)
	if stage and stage.history_window:
		stage.history_window.cancel_drag()
		stage.paper_grip.cancel_grip()

func _exit_tree() -> void:
	model.cancel()
