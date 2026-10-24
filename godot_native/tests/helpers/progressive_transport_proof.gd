extends RefCounted
## Test-only legal input routes. No runtime script imports this fixture or helper.
const Model=preload("res://scripts/games/progressive_transport_model.gd")
const FIXTURE="res://tests/fixtures/progressive-transport-solutions.json"

static func proof(config: Dictionary) -> Dictionary:
	var fixture: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not fixture is Dictionary: return {}
	var id: String=str(config.get("puzzleId",""))
	var actions: Variant=fixture.get("puzzles",{}).get(id,{}).get("actions")
	if not actions is Array: return {}
	var model: RefCounted=Model.new(id)
	for action: Variant in actions:
		if not action is String: return {}
		var changed: Dictionary=model.apply(action)
		if not changed.get("accepted",false): return {}
	var result: Dictionary=model.proof()
	result.session=config.get("session",{}).duplicate(true)
	return result
