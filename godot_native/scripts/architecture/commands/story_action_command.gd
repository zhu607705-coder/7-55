extends AbstractCommand
## One invocation's input only; no retained result, session or progression state.
var _action: String
var _value: Variant

func _init(action: String, value: Variant = null) -> void:
	_action = action
	_value = value

func execute() -> Dictionary:
	return get_system("Chapters").dispatch(_action, _value)
