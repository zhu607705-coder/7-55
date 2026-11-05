extends SceneTree
## Consumption-only replacement for the retired charging regression. This checks
## real save/import boundaries and controllers, not full later-chapter play.
const Chapter = preload("res://scripts/chapters/chapter1_2.gd")
const LaterChapter = preload("res://scripts/chapters/chapter3.gd")
var checks := 0
var failures := 0
var state: Node
var controller := Chapter.new()
var later := LaterChapter.new()

func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func fixture(percent := 17) -> Dictionary:
	var value: Dictionary=state.initial()
	value.phoneBattery.percent=percent
	value.native.page="phone_home"; value.currentScene="phone_home"
	return value
func import_native(value: Dictionary) -> Dictionary:
	var file := FileAccess.open("user://legacy-phone.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"format":"7-55-godot-native","version":1,"sourceVersion":36,"state":value})); file.close()
	return state.import_save("user://legacy-phone.json")
func run() -> void:
	state=root.get_node("State")
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():
		push_error("Refusing persistence tests outside isolated /tmp profile"); quit(2); return
	state.developer_mode=true
	var fresh: Dictionary=state.initial()
	check(fresh.phoneBattery.keys()==["percent"],"new battery contains consumption only")
	check(fresh.ui.brightness==65 and not fresh.ui.has("homeDeskReturnScene"),"new game leaves room for the original light puzzle and has no charging return state")
	for percent in [0,1,2,17,100]:
		var s:=fixture(percent)
		for mode in ["cellular","campus_wifi","offline","cellular"]:
			var before: int=s.phoneBattery.percent
			controller.dispatch(s,"c1_network",mode)
			check(s.phoneBattery.percent==maxi(0,before-1),"network consumes to zero without a synthetic reserve")
			var same: int=s.phoneBattery.percent
			controller.dispatch(s,"c1_network",mode)
			check(s.phoneBattery.percent==same,"selecting the current network never drains")
		state.d=s
		var remaining: int=s.phoneBattery.percent
		for page in ["wechat","phone_home","bonsai","settings","control_center","phone_home"]:
			state.open_page(page)
			check(state.d.phoneBattery.percent==remaining,"ordinary phone navigation neither drains nor restores")
		controller.dispatch(s,"phone_settings_brightness",100)
		check(s.ui.brightness==100,"manual Settings brightness has no low-battery cap")
		controller.dispatch(s,"c1_brightness",0)
		check(s.ui.brightness==0,"manual dimming remains supported")
		controller.dispatch(s,"c1_brightness",100)
		controller.dispatch(s,"c1_music",null)
		check(s.ui.musicPlaying,"zero battery cannot lock the headphone puzzle")
		controller.dispatch(s,"c1_headphone",null)
		check(s.items.headphone,"headphone can be acquired without charging")
		controller.dispatch(s,"c1_plant_light",null)
		check(s.flags.plantLit,"normal screen light remains available to the plant at any battery")
		var before_retired: Dictionary=s.duplicate(true)
		for action in ["c1_desk_charge","c1_desk_charge_result","c1_desk_putdown","phone_low_power"]:
			controller.dispatch(s,action,{"elapsed_ms":2200,"success":true})
		check(s==before_retired,"retired charging and low-power intents cannot mutate state")
	# Later chapters are exercised as isolated controller fixtures only.
	for percent in [0,1,17]:
		var s:=fixture(percent); s.native.chapter=3; s.native.scene=""; s.native.page="c3_theater"
		s.native.player={"x":665,"y":790}; s.runtimeMode="rpg"; s.rpgScene="theater_interior"; s.theaterHunt.active=true
		later.dispatch(s,"c3_network","cellular")
		check(s.phoneBattery.percent==maxi(0,percent-1),"C3 uses the same zero-floor consumption")
		s.native.scene="theater_interior"
		var before: int=s.phoneBattery.percent
		for action in ["c3_charge_result","c3_target:theater_charging_station"]:
			var result: Dictionary=later.dispatch(s,action,{"success":true,"elapsed_ms":2200})
			check(not result.has("world_effect") and s.phoneBattery.percent==before,"retired theater contact never recharges")
		for phase in ["entry_ticket","program_search","prop_setup","spotlight_ready","complete"]:
			s.theaterHunt.phase=phase
			var charger_found:=false
			for target: Dictionary in later.targets("theater_interior",s):
				if target.get("id")=="theater_charging_station": charger_found=true
			check(not charger_found,"no theater charging target in "+phase)
	for percent in [0,1,87]:
		for brightness in [0,32,100]:
			var old:=fixture(percent)
			old.phoneBattery.lowPowerMode=true; old.phoneBattery.rechargeCount=4; old.ui.brightness=brightness
			old.flags.plantWatered=true; old.items.waterDrop=true
			check(import_native(old).get("ok",false),"legacy phone snapshot imports through ordinary validator")
			check(state.d.phoneBattery.keys()==["percent"] and int(state.d.phoneBattery.percent)==percent and state.d.ui.brightness==brightness,"legacy charging state is discarded without manufacturing power or changing manual brightness")
			check(state.d.flags==old.flags and state.d.items==old.items,"legacy phone migration preserves puzzle facts and items")
			check(state.export_save("user://new-phone.json")==OK,"consumption-only snapshot exports")
			var exported: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://new-phone.json"))
			check(exported.state.phoneBattery.keys()==["percent"] and not exported.state.ui.has("homeDeskReturnScene"),"new exports carry no charging state")
	for previous_page in ["phone_home","bonsai"]:
		var old:=fixture(0); old.currentScene="desktop"; old.native.page="desktop"; old.ui.homeDeskReturnScene=previous_page
		check(import_native(old).get("ok",false),"legacy physical desk imports")
		check(state.d.native.page==previous_page and state.d.currentScene==previous_page and not state.d.ui.has("homeDeskReturnScene"),"legacy desk resumes its phone page without a removed pickup control")
	for field in ["lowPowerMode","rechargeCount"]:
		for invalid in ["wrong",[],{},-1]:
			var old:=fixture(); old.phoneBattery[field]=invalid
			check(not import_native(old).get("ok",false),"malformed legacy "+field+" rejects before migration")
	var old:=fixture(0); old.phoneBattery.lowPowerMode=true; old.phoneBattery.rechargeCount=2; old.ui.brightness=23
	var file:=FileAccess.open(state.SAVE_PATH,FileAccess.WRITE)
	file.store_string(JSON.stringify({"format":"7-55-godot-native","version":1,"sourceVersion":36,"state":old})); file.close()
	check(state.load_game() and state.d.phoneBattery.keys()==["percent"] and int(state.d.phoneBattery.percent)==0 and state.d.ui.brightness==23,"ordinary Continue migrates legacy zero-percent save")
	state.developer_mode=false
	check(state.save_game() and state.load_game() and state.d.phoneBattery.keys()==["percent"] and int(state.d.phoneBattery.percent)==0,"zero-percent save remains playable after ordinary persistence round trip")
	# Legacy browser-imported C4 native saves retain the same source proof. The
	# full current normalizer verifies it before the exact predecessor stamp moves.
	var migration:=preload("res://scripts/save_migration.gd").new()
	var decoded: Dictionary=migration.decode({"version":24,"state":{"chapter4":{"completed":true,"phase":"complete"}}},fresh)
	check(decoded.get("ok",false),"legacy completed browser fixture normalizes")
	if decoded.get("ok",false):
		var legacy: Dictionary=decoded.state
		legacy.chapter4.floor="A2"
		var old_hash: String=migration.PHONE_CHARGING_PREDECESSOR_SHA
		legacy.native.save_import.normalizer_sha256=old_hash
		for field in ["c4_stair_proof","c4_closure_proof"]:
			if legacy.native.get(field) is Dictionary: legacy.native[field].normalizer_sha256=old_hash
		check(state.validate_snapshot(legacy),"exact predecessor import proof still validates every C4 fact")
		var legacy_file:=FileAccess.open("user://legacy-import-proof.json",FileAccess.WRITE)
		legacy_file.store_string(JSON.stringify({"format":"7-55-godot-native","version":1,"sourceVersion":36,"state":legacy})); legacy_file.close()
		var read_proof: Dictionary=state._read_native_save("user://legacy-import-proof.json")
		var program_hash: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(migration.PROGRAM_PATH))
		check(not read_proof.is_empty() and read_proof.state.native.save_import.normalizer_sha256==program_hash.sourceHashes["src/core/SaveStore.ts"] and state.validate_snapshot(read_proof.state),"ordinary native reader revalidates and upgrades exact predecessor import proof")
		migration.upgrade_phone_predecessor_provenance(legacy)
		var expected_hash: String=decoded.state.native.save_import.normalizer_sha256
		var program: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(migration.PROGRAM_PATH))
		check(expected_hash==program.sourceHashes["src/core/SaveStore.ts"] and state.validate_snapshot(legacy),"verified predecessor import provenance rebases to current normalizer")
		var brightness_legacy: Dictionary=legacy.duplicate(true)
		brightness_legacy.native.save_import.normalizer_sha256=migration.PHONE_BRIGHTNESS_PREDECESSOR_SHA
		for field: String in ["c4_stair_proof","c4_closure_proof"]:
			if brightness_legacy.native.get(field) is Dictionary: brightness_legacy.native[field].normalizer_sha256=migration.PHONE_BRIGHTNESS_PREDECESSOR_SHA
		check(state.validate_snapshot(brightness_legacy),"exact pre-brightness normalizer proof replays C4 facts")
		migration.upgrade_phone_predecessor_provenance(brightness_legacy)
		check(brightness_legacy.native.save_import.normalizer_sha256==expected_hash and state.validate_snapshot(brightness_legacy),"pre-brightness provenance rebase preserves validated C4 facts")
		var invalid: Dictionary=legacy.duplicate(true)
		invalid.native.save_import.normalizer_sha256="unknown-predecessor"
		check(not state.validate_snapshot(invalid),"arbitrary old provenance hash remains rejected")
		invalid=legacy.duplicate(true)
		invalid.native.save_import.normalizer_sha256=old_hash
		invalid.native.c4_stair_proof.normalizer_sha256=old_hash
		invalid.native.c4_stair_proof.fact="invented_completion"
		check(not state.validate_snapshot(invalid),"exact predecessor stamp cannot launder a malformed proof")
	print("PHONE_CONSUMPTION_ONLY ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
