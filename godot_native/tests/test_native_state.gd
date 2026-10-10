extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("_run")
func check(condition: bool,message: String) -> void:
	if not condition:
		failures+=1
		push_error("TEST FAILED: "+message)
func _run() -> void:
	var state = root.get_node("State")
	var fresh: Dictionary = state.initial()
	check(state.validate_snapshot(fresh),"initial state validates")
	check(fresh.native.chapter==1,"new game starts chapter one")
	check(fresh.flags.checkinDone==false,"new game cannot inherit check-in")
	check(fresh.chapter4.factIds.is_empty(),"new game does not invent chapter4 proof")
	check(not state.validate_snapshot({}),"empty snapshot rejected")
	var corrupted := fresh.duplicate(true)
	corrupted.items.campusCard = "true"
	check(not state.validate_snapshot(corrupted),"non-boolean item flag rejected")
	for mutation in ["chapter4","phoneBattery","native_log","native_settings","native_player","chapter","mode","battery_range","unknown_scene"]:
		var invalid := fresh.duplicate(true)
		match mutation:
			"chapter4": invalid.chapter4 = 7
			"phoneBattery": invalid.phoneBattery = "17"
			"native_log": invalid.native.log = {}
			"native_settings": invalid.native.settings = []
			"native_player": invalid.native.player = {"x":"left","y":3}
			"chapter": invalid.native.chapter = 1.5
			"mode": invalid.native.mode = "unsupported"
			"battery_range": invalid.phoneBattery.percent = 105
			"unknown_scene": invalid.native.scene = "missing_scene"
		check(not state.validate_snapshot(invalid),"invalid import rejected: "+mutation)
	var malformed_array := fresh.duplicate(true)
	malformed_array.chapter4.room204Placements = [7]
	check(not state.validate_snapshot(malformed_array),"room placement records require object schema")
	var positions_bad := fresh.duplicate(true)
	positions_bad.native.positions = {"dorm_hub":9}
	check(not state.validate_snapshot(positions_bad),"saved positions require numeric x/y")
	var transport_bad := fresh.duplicate(true)
	transport_bad.native.chapter = 4
	transport_bad.chapter4.floor = "A3"
	check(not state.validate_snapshot(transport_bad),"floor alone cannot imply calibrated elevator travel")
	transport_bad.chapter4.floor = "A2"
	check(not state.validate_snapshot(transport_bad),"floor alone cannot imply stair completion")
	check(state.developer_checkpoints().size() == 117,"all117 exact source developer checkpoints available")
	var checkpoint_before: Dictionary = state.d.duplicate(true)
	check(state.begin_checkpoint("c3-canteen-entry"),"named source checkpoint loads")
	check(state.developer_mode and state.d.native.chapter==3,"source checkpoint remains isolated")
	check(not state.save_game(),"source checkpoint never writes formal save")
	state.restore_formal()
	check(state.d==checkpoint_before,"formal state survives named checkpoint")
	var merged: Dictionary = state.merge_defaults(fresh,{"phoneBattery":{"percent":9}})
	check(merged.phoneBattery.percent==9 and merged.phoneBattery.has("lowPowerMode"),"nested default merge retains sibling fields")
	var before: Dictionary = state.d.duplicate(true)
	state.begin_preview(3,"canteen_interior")
	check(state.developer_mode,"preview isolated")
	check(not state.save_game(),"preview cannot overwrite formal save")
	state.restore_formal()
	check(state.d==before,"formal state restored after preview")
	var worlds = JSON.parse_string(FileAccess.get_file_as_string("res://data/worlds.json"))
	check(worlds.worlds.size()==8,"all eight authored worlds retained")
	check(worlds.worlds.dorm_hub.collisions.size()==22,"all dorm collider records retained")
	check(worlds.worlds.library_interior.collisions.size()==53,"all library collider records retained")
	check(worlds.worlds.campus_bootstrap.manifest.walkability.bitOrder=="little","campus bitmask order retained")
	print("Native state/source tests: ","PASS" if failures==0 else "FAIL", " (",failures," failures)")
	quit(0 if failures==0 else 1)
