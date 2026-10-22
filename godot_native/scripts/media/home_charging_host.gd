extends Node
## One persistent timer owner; rebuilding the phone page cannot restart it.
var read_state: Callable
var read_owner: Callable
var read_session: Callable
var dispatch: Callable
var reported: RefCounted

func setup(state_reader: Callable, owner_reader: Callable, session_reader: Callable, action: Callable) -> void:
	read_state = state_reader; read_owner = owner_reader; read_session = session_reader; dispatch = action

func _process(_delta: float) -> void:
	if not read_session.is_valid(): return
	var session: RefCounted = read_session.call()
	if session == null or session == reported: return
	var state: Dictionary = read_state.call()
	var owner: Dictionary = read_owner.call()
	if session.phase == "issued" and not session.begin(state, owner): session.cancel()
	session.sample(state, owner)
	if session.phase in ["complete", "cancelled"]:
		reported = session
		dispatch.call("c1_desk_charge_result", session)

func cancel() -> void:
	if not read_session.is_valid(): return
	var session: RefCounted = read_session.call()
	if session != null: session.cancel()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT]: cancel()

func _exit_tree() -> void: cancel()
