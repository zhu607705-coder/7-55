extends RefCounted
## One pointer per object, one object per pointer. Deliberately no puzzle rules.
## Views filter emulated events and route GUI first; models decide valid objects.
var owners: Dictionary = {}

func start(id: int, object: String) -> bool:
	if id < -1 or object.is_empty() or owners.has(id) or has_owner(object):
		return false
	owners[id] = object
	return true

func release(id: int) -> void:
	owners.erase(id)

func clear() -> void:
	owners.clear()

func has_owner(object: String) -> bool:
	return owners.values().has(object)
