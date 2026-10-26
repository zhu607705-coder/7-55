extends SceneTree
## Auto-discovered by validate_native.mjs. No preview scene or navigation is mounted.
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var base: String = get_script().resource_path.get_base_dir().path_join("../samples/north_real_plan_preview/").simplify_path() + "/"
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(base + "data/north_plan_registry.json"))
	if not data is Dictionary:
		push_error("Missing North real-plan source registry")
		quit(1)
		return
	check(data.schemaVersion == 1 and data.navigationEnabled == false, "Preview is not gameplay authority")
	check(data.buildings.size() == 4, "Four separately identified buildings")
	var hashes := {}
	var count := 0
	for building: Dictionary in data.buildings:
		check(building.currentTotalFloorCount == null, "Historical sheets do not prove current total")
		for floor_data: Dictionary in building.floors:
			count += 1
			check(floor_data.id == "%s:f%d" % [building.id, floor_data.number], "Stable floor ID")
			check(floor_data.geometry.status == "not_extracted", "Geometry remains unverified")
			check(floor_data.geometry.walkablePolygons.is_empty() and floor_data.geometry.rooms.is_empty() and floor_data.geometry.portals.is_empty(), "No fabricated geometry")
			check(floor_data.objectLayer.instances.is_empty(), "Independent props not baked into floor data")
			if floor_data.number == 1:
				var art_path := base + str(floor_data.art.path).trim_prefix("res://")
				var actual := FileAccess.get_sha256(art_path)
				check(actual == floor_data.art.sha256, "Approved original PNG bytes preserved")
				hashes[actual] = true
			else:
				check(floor_data.art == null, "No duplicated upper-floor plate")
	check(count == 18 and hashes.size() == 4, "18 sheet records and four independent first-floor images")
	var config := FileAccess.get_file_as_string(base + "project.godot")
	check(not config.contains("[autoload]"), "Standalone preview has no story/save autoload")
	check(FileAccess.file_exists(base + ".gdignore"), "Parent import boundary")
	print("North real-plan registry: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
