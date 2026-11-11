extends RefCounted
## Advance the controller-owned phone clock in native fixtures.
const PhoneEntry = preload("res://scripts/chapters/phone_entry_session.gd")

static func advance(controller: RefCounted, state: Dictionary, milliseconds: float) -> void:
	var session: RefCounted = controller.phone_entry_session(state)
	for event: Dictionary in session.advance(milliseconds):
		if event.get("action") == "c2_tiyi_download_finished":
			controller.dispatch(state, event.action)

static func install(controller: RefCounted, state: Dictionary) -> void:
	controller.dispatch(state, "c2_tiyi_discover")
	controller.dispatch(state, "c2_tiyi_acquire")
	advance(controller, state, PhoneEntry.TIYI_DOWNLOAD_MS)
	controller.dispatch(state, "c2_tiyi_install")
