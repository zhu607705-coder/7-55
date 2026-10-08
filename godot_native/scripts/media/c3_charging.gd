extends Control
## Nonmodal station transaction. The view cannot recharge, consume, or navigate.
signal event(action: String, value: Variant)
const Session = preload("res://scripts/media/c3_charging_session.gd")
const ChargingView = preload("res://scripts/media/c3_charging_view.gd")
var session: RefCounted
var read_state: Callable
var project_position: Callable
var callback: String = "c3_charge_result"
var reported: bool = false
var view: Control
var entry_recharge_count: int = 0
var terminal: String = ""
var terminal_ms: float = 0.0

func setup(config: Dictionary) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	session = config.get("session")
	read_state = config.get("read_state", Callable())
	project_position = config.get("project_position", Callable())
	callback = str(config.get("on_event", callback))
	if not session is Session or not read_state.is_valid(): queue_free(); return
	var state: Dictionary = read_state.call()
	entry_recharge_count = int(state.get("phoneBattery", {}).get("rechargeCount", 0))
	view = ChargingView.new()
	add_child(view)
	if not session.begin(state): session.cancel()
	_present(state)

func uses_responsive_exploration() -> bool:
	# This small screen-space close-up does not take the cinematic camera contract.
	return true

func _process(delta: float) -> void:
	if session == null or not read_state.is_valid(): return
	var state: Dictionary = read_state.call()
	if reported:
		# A terminal tail can remain only on its original live world surface.
		# Never leave a cable over a phone, modal, new scene, or new charging view.
		if not _surface_live(state): hide(); queue_free(); return
		terminal_ms += minf(maxf(delta, 0.0), 0.1) * 1000.0
		if terminal_ms >= ChargingView.tail_duration(terminal): queue_free(); return
	else:
		session.sample(state)
		if session.phase in ["complete", "cancelled"]:
			_report()
			state = read_state.call()
		if not _surface_live(state): hide(); queue_free(); return
	_present(state)

func _report() -> void:
	if reported: return
	reported = true
	event.emit(callback, session)
	# The synchronous controller owns receipt consumption AND the battery write.
	# Elapsed time or a consumed receipt alone is not a successful recharge.
	var battery: Dictionary = read_state.call().get("phoneBattery", {})
	terminal = "success" if session.phase == "consumed" and int(battery.get("rechargeCount", 0)) == entry_recharge_count + 1 and int(battery.get("percent", 0)) == 45 else "cancelled"
	terminal_ms = 0.0

func _surface_live(state: Dictionary) -> bool:
	var native: Dictionary = state.get("native", {})
	var host: Dictionary = native.get("host", {})
	return state.get("runtimeMode") == "rpg" and state.get("rpgScene") == "theater_interior" and native.get("scene") == "theater_interior" and native.get("page") == session.entry_page and host.get("world_visible", true) and host.get("focused", true) and not host.get("phone_modal_open", false) and not host.get("minigame_open", false) and not state.get("ui", {}).get("controlCenterOpen", false)

func _present(state: Dictionary) -> void:
	if not is_instance_valid(view): return
	var anchor: Vector2 = project_position.call(Vector2(595, 773)) if project_position.is_valid() else size / 2
	var reduced: bool = bool(state.get("native", {}).get("settings", {}).get("reduced_motion", false))
	view.present(size, anchor, float(session.elapsed_ms), terminal, terminal_ms, int(state.get("phoneBattery", {}).get("percent", 0)), reduced)

func cancel() -> void:
	# Host-requested cancellation means a replacement surface is coming. Retire
	# immediately; proximity cancellation in _process gets the short withdrawal.
	if session != null and not reported:
		session.cancel()
		_report()
	hide()
	queue_free()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT]: cancel()

func _exit_tree() -> void:
	if session != null and not reported:
		session.cancel()
		_report()
