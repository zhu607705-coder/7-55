extends Node
## Logical UI units with the original HiDPI backing buffer. No game state.
var _window: Window
var _web_active := false
var _windows_active := false
var _windows_poll_left := 0.0
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
	_windows_active = OS.get_name()=="Windows" and DisplayServer.get_name()!="headless"
	if not (_web_active or _windows_active): return
	_window = get_tree().root
	# Browser zoom and Windows display scaling can both be fractional.
	if _window.content_scale_stretch != Window.CONTENT_SCALE_STRETCH_FRACTIONAL:
		_window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	if _web_active: _window.size_changed.connect(_sync_scale)
	_sync_scale()

func _ready() -> void:
	# Script callback registration can enable processing after _enter_tree.
	set_process(_web_active or _windows_active)
	_sync_scale()

func _sync_scale() -> void:
	if _syncing or not is_instance_valid(_window): return
	_syncing = true
	var density := DisplayServer.screen_get_scale() if _web_active else float(DisplayServer.screen_get_dpi(_window.current_screen))/96.0
	apply_to_window(_window,density)
	_syncing = false

func _process(delta: float) -> void:
	# Windows has no Window.dpi_changed signal. Check the current monitor at
	# intervals so a move to another display does not depend on a resize.
	if _windows_active:
		_windows_poll_left-=delta
		if _windows_poll_left>0.0: return
		_windows_poll_left=.5
	_sync_scale()

func _exit_tree() -> void:
	if is_instance_valid(_window) and _window.size_changed.is_connected(_sync_scale):
		_window.size_changed.disconnect(_sync_scale)
