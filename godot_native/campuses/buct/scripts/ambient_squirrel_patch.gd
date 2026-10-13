extends RefCounted
## Fail-closed optional artwork. This installer does not edit navigation or story state.
const SQUIRREL = preload("res://campuses/buct/scripts/ambient_squirrel.gd")
const PROFILE := "res://campuses/buct/data/ambient-squirrel-profile.json"

static func install(host: Node2D, objects: Node2D) -> Node2D:
	if objects.has_node("AmbientSquirrel"): return objects.get_node("AmbientSquirrel")
	var data = JSON.parse_string(FileAccess.get_file_as_string(PROFILE))
	if not data is Dictionary:
		push_warning("Ambient squirrel profile missing; campus navigation is unchanged")
		return null
	var actor := SQUIRREL.new()
	actor.name = "AmbientSquirrel"
	if not actor.configure(data, load(str(data.get("atlas", ""))), Callable(host, "is_walkable")):
		actor.free()
		push_warning("Ambient squirrel failed registration or route validation; campus navigation is unchanged")
		return null
	objects.add_child(actor)
	return actor
