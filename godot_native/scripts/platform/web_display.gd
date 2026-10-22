extends Node
## CSS layout units with the original HiDPI backing buffer. No game state.
var _window: Window
var _web_active := false
var _syncing := false

static func normalized_scale(value: float) -> float:
	return value if is_finite(value) and value > 0.0 else 1.0

static func apply_to_window(window: Window, density: float) -> bool:
	if not is_instance_valid(window): return false
	var target := normalized_scale(density)
	if is_equal_approx(window.content_scale_factor,target): return false
	window.content_scale_factor = target
	return true

func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_web_active = OS.has_feature("web")
	set_process(_web_active)
	if not _web_active: return
	_window = get_tree().root
	# Browser density/zoom can be fractional, including values below one.
	if _window.content_scale_stretch != Window.CONTENT_SCALE_STRETCH_FRACTIONAL:
		_window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	_window.size_changed.connect(_sync_scale)
	_sync_scale()

func _ready() -> void:
	# Script callback registration can enable processing after _enter_tree.
	set_process(_web_active)
	if _web_active: _sync_scale()

func _sync_scale() -> void:
	if not _web_active or _syncing or not is_instance_valid(_window): return
	_syncing = true
	# Same effective ratio as Web's canvas, including the engine HiDPI setting.
	apply_to_window(_window,DisplayServer.screen_get_scale())
	_syncing = false

func _process(_delta: float) -> void:
	# Monitor/zoom changes need not alter CSS dimensions. Equal values never write.
	_sync_scale()

func _exit_tree() -> void:
	if is_instance_valid(_window) and _window.size_changed.is_connected(_sync_scale):
		_window.size_changed.disconnect(_sync_scale)
