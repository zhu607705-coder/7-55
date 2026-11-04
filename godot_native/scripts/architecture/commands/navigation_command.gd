extends AbstractCommand
var _operation: String
var _value: String

func _init(operation: String, value: String = "") -> void:
	_operation = operation
	_value = value

func execute() -> void:
	get_system("Chapters").navigate(_operation, _value)
