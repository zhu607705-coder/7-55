extends RefCounted
## Navigation only. No identity credentials, story facts or save writes cross this bridge.

static func available() -> bool:
	return OS.has_feature("web") and JavaScriptBridge.get_interface("__GODOT_755_ACCOUNT__") != null

static func open_community() -> void:
	if not available(): return
	JavaScriptBridge.get_interface("__GODOT_755_ACCOUNT__").openCommunity()

static func open_account() -> void:
	if not available(): return
	JavaScriptBridge.get_interface("__GODOT_755_ACCOUNT__").showAccount()
