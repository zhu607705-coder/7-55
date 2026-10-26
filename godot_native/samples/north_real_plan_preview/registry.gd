extends RefCounted
## Source records and preview selection are not a second gameplay authority.

const DATA_PATH := "res://data/north_plan_registry.json"
var data: Dictionary = {}
var errors: PackedStringArray = []

func _init(path: String = DATA_PATH) -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		errors.append("资料登记表无法读取")
		return
	data = parsed
	if data.get("schemaVersion") != 1 or not data.get("buildings") is Array:
		errors.append("资料登记表版本不受支持")
		data = {}

func buildings() -> Array:
	return data.get("buildings", []).duplicate(true)

func building(building_id: String) -> Dictionary:
	for entry: Dictionary in data.get("buildings", []):
		if entry.get("id") == building_id:
			return entry.duplicate(true)
	return {}

func floor_record(building_id: String, floor_number: int) -> Dictionary:
	for entry: Dictionary in building(building_id).get("floors", []):
		if entry.get("number") == floor_number:
			return entry.duplicate(true)
	return {}

func source(source_id: String) -> Dictionary:
	return data.get("sources", {}).get(source_id, {}).duplicate(true)

func plate_path(building_id: String, floor_number: int) -> String:
	var floor_data := floor_record(building_id, floor_number)
	if floor_data.get("artStatus") != "approximate_candidate":
		return ""
	return str(floor_data.get("art", {}).get("path", ""))

func navigation_available(_building_id: String, _floor_number: int) -> bool:
	# v1 is a read-only preview. No future data field silently activates navigation.
	return false
