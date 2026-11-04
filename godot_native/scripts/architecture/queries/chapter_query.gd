extends AbstractQuery
var _kind: String
var _key: String

func _init(kind: String, key: String = "") -> void:
	_kind = kind
	_key = key

func do() -> Variant:
	return get_system("Chapters").query(_kind, _key)
