extends RefCounted
## Keep the recorded Room201/302 fixture bytes immutable. Tests that use their
## state as current live data must cross the production versioned save boundary.
static func read(owner:Node,source_path:String,check:Callable)->Dictionary:
	var isolated:=preload("res://tests/native_test_isolation.gd").is_isolated_save()
	check.call(isolated,"Historical room fixture migration uses isolated native save storage")
	if not isolated:return {}
	var source:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source_path))
	var original:Dictionary=source.state
	var envelope:Dictionary=source.duplicate(true)
	var read_path:=source_path
	var wrapped_path:="user://room201-v35-fixture-envelope.json"
	if source_path=="res://tests/fixtures/room201_projection_entry.json":
		# This pre-v36 fixture records state plus provenance, not a native envelope.
		# The explicit test-only v35 wrapper is new; do not claim it was recorded.
		envelope={"format":"7-55-godot-native","version":1,"sourceVersion":35,"state":original}
		var wrapped:=FileAccess.open(wrapped_path,FileAccess.WRITE)
		check.call(wrapped!=null,"Historical state-only fixture can be wrapped explicitly as v35")
		if wrapped==null:return {}
		wrapped.store_string(JSON.stringify(envelope));wrapped.close();read_path=wrapped_path
	else:
		check.call(source_path=="res://tests/fixtures/room302_earned_film_entry.json" and source.get("sourceVersion")==35,"Recorded Room302 envelope keeps its actual v35 version")
		if source_path!="res://tests/fixtures/room302_earned_film_entry.json" or source.get("sourceVersion")!=35:return {}
	check.call(not original.actOne.has("tiyiUpdateStage") and not original.ui.has("homeDeskReturnScene"),"Historical room fixture retains its original absent v36 fields")
	check.call(not owner.validate_snapshot(original),"Unmigrated historical state is not a valid live v36 snapshot")
	var loaded:Dictionary=owner._read_native_save(read_path)
	if read_path==wrapped_path:DirAccess.remove_absolute(ProjectSettings.globalize_path(wrapped_path))
	check.call(not loaded.is_empty(),"Production v35 native reader migrates the historical room fixture")
	if loaded.is_empty():return {}
	var upgraded:Dictionary=loaded.state
	check.call(owner.validate_snapshot(upgraded),"Migrated room fixture passes strict current-version validation")
	var preserved:Dictionary=upgraded.duplicate(true)
	for pair:Array in [["actOne","tiyiUpdateStage"],["ui","homeDeskReturnScene"],["qizhenLake","legacyNetMaterialsConsumed"]]:
		if not original[pair[0]].has(pair[1]):preserved[pair[0]].erase(pair[1])
	check.call(preserved==original,"Version migration preserves every recorded story fact, item, proof and object checkpoint")
	var expected_stage:="legacy_ready" if original.actOne.exerciseStarted or original.actOne.weatherWaterTaken else "not_started"
	check.call(upgraded.actOne.tiyiUpdateStage==expected_stage and upgraded.ui.homeDeskReturnScene==null,"Legacy access follows earned evidence and does not create a desktop return")
	check.call(not upgraded.native.has("c4_plate_press") and not upgraded.native.has("c4_media_studio"),"Migration invents no press or studio checkpoint")
	# The same missing fields must remain invalid when labelled current v36.
	# Exercise both real read/import boundaries, not only the shape validator.
	var invalid_path:="user://room-fixture-invalid-v36.json"
	envelope=envelope.duplicate(true);envelope.sourceVersion=36
	var invalid:=FileAccess.open(invalid_path,FileAccess.WRITE)
	check.call(invalid!=null,"Missing-field current-version negative fixture can be written")
	if invalid==null:return {}
	invalid.store_string(JSON.stringify(envelope));invalid.close()
	check.call(owner._read_native_save(invalid_path).is_empty(),"Native reader rejects v36 room state with missing required fields")
	var live:Dictionary=owner.d.duplicate(true)
	var response:Dictionary=owner.import_save(invalid_path)
	check.call(not response.get("ok",false) and owner.d==live,"Invalid v36 import cannot replace current progress")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(invalid_path))
	return upgraded
