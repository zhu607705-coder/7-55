extends SceneTree
const Policy=preload("res://scripts/ui/phone_brightness_policy.gd")
var state: Node
var checks:=0
var failures:=0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("BRIGHTNESS_START: "+message)
func legacy(value: float=100.0) -> Dictionary:
	var snapshot: Dictionary=state.initial()
	snapshot.ui.brightness=value
	for key: String in ["brightnessRevision","brightnessUserAdjusted","brightnessLegacy100Repaired"]: snapshot.ui.erase(key)
	return snapshot
func write_save(snapshot: Dictionary, path: String="user://save.json") -> void:
	var file:=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"format":"7-55-godot-native","version":1,"sourceVersion":36,"state":snapshot}));file.close()
func run() -> void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	state=root.get_node("State");state.developer_mode=false
	var fresh: Dictionary=state.initial()
	check(fresh.ui.brightness==65 and fresh.ui.brightnessRevision==1 and not fresh.ui.brightnessUserAdjusted,"fresh65 has explicit default provenance")
	check(not fresh.flags.plantLit and not fresh.flags.flowerBloomed,"initialization grants no plant fact")
	check(Policy.display_brightness(65,"alarm")==65 and is_zero_approx(Policy.veil_alpha(65,"alarm")) and is_zero_approx(Policy.grade_strength(65)),"opening retains raw65 while its calibrated display is neutral")
	for page: String in ["alarm","desktop","phone_home","bonsai"]:
		var old:=legacy();old.native.page=page;old.currentScene=page
		var flags: Dictionary=old.flags.duplicate(true)
		write_save(old)
		check(state.load_game() and state.d.ui.brightness==65,"actual Continue repairs raw unmarked100 before default merge: "+page)
		check(state.d.ui.brightnessRevision==1 and state.d.ui.brightnessLegacy100Repaired and not state.d.ui.brightnessUserAdjusted,"repair has durable one-time receipt")
		check(state.d.flags==flags,"repair never invents or erases puzzle facts")
		check(state.save_game() and state.load_game() and state.d.ui.brightness==65,"repair survives ordinary save and reload")
	var old:=legacy();write_save(old,"user://brightness-import.json")
	check(state.import_save("user://brightness-import.json").get("ok",false) and state.d.ui.brightness==65,"native import also repairs before default merge")
	var browser_file:=FileAccess.open("user://brightness-browser.json",FileAccess.WRITE)
	browser_file.store_string(JSON.stringify({"version":36,"state":legacy()}));browser_file.close()
	check(state.import_save("user://brightness-browser.json").get("ok",false) and state.d.ui.brightness==65 and state.d.ui.brightnessLegacy100Repaired,"generated source VM repairs actual browser import100")
	var browser_manual: Dictionary=state.initial();browser_manual.ui.brightness=100;browser_manual.ui.brightnessUserAdjusted=true
	browser_file=FileAccess.open("user://brightness-browser.json",FileAccess.WRITE)
	browser_file.store_string(JSON.stringify({"version":36,"state":browser_manual}));browser_file.close()
	check(state.import_save("user://brightness-browser.json").get("ok",false) and state.d.ui.brightness==100 and state.d.ui.brightnessUserAdjusted,"generated source VM preserves browser manual100 provenance")
	for value: float in [0,20,33,45,50,65,79,80,99]:
		write_save(legacy(value))
		check(state.load_game() and state.d.ui.brightness==value and not state.d.ui.brightnessLegacy100Repaired,"arbitrary old brightness remains untouched: "+str(value))
	for flag: String in ["plantLit","plantWatered","plantFertilized","flowerBloomed","flowerEightTaken","checkinDone"]:
		old=legacy();old.flags[flag]=true;write_save(old)
		var read: Dictionary=state._read_native_save(state.SAVE_PATH)
		check(not read.is_empty() and read.state.ui.brightness==100 and not read.state.ui.brightnessLegacy100Repaired,"earned "+flag+" excludes default repair")
	for field: String in ["photoCaptured","photoDimmed","itemReportGenerated"]:
		old=legacy();old.ui.libraryFinalsPuzzle[field]=true
		Policy.upgrade_legacy(old)
		check(old.ui.brightness==100 and not old.ui.brightnessLegacy100Repaired,"photo fact excludes repair: "+field)
	old=legacy();old.native.chapter=2;old.actOne.phase="complete"
	Policy.upgrade_legacy(old)
	check(old.ui.brightness==100 and not old.ui.brightnessLegacy100Repaired,"later chapter never receives opening correction")
	old=legacy();old.native.log.append({"text":"屏幕亮度已调整。","time":"2026-11-04T00:00:00"});write_save(old)
	check(state.load_game() and state.d.ui.brightness==100 and state.d.ui.brightnessUserAdjusted,"positive historical manual evidence preserves100")
	for action: String in ["c1_brightness","phone_settings_brightness"]:
		state.d=state.initial();state.d.native.page="phone_home";state.d.currentScene="phone_home"
		state.act(action,100)
		check(state.d.ui.brightness==100 and state.d.ui.brightnessUserAdjusted,"manual handler records intentional100: "+action)
		check(state.save_game() and state.load_game() and state.d.ui.brightness==100 and state.d.ui.brightnessUserAdjusted,"manual100 persists through actual Continue: "+action)
		state.act(action,65)
		check(state.d.ui.brightnessUserAdjusted,"manual selection equal to new default still records intent")
	old=legacy();write_save(old);state.load_game();state.act("phone_settings_brightness",100)
	check(state.save_game() and state.load_game() and state.d.ui.brightness==100 and state.d.ui.brightnessLegacy100Repaired,"manual100 after repaired save is never reset again, receipt retained")
	for patch: Dictionary in [{"brightnessRevision":2},{"brightnessUserAdjusted":"true"},{"brightnessLegacy100Repaired":0}]:
		var invalid: Dictionary=state.initial();invalid.ui.merge(patch,true)
		check(not state.validate_snapshot(invalid),"malformed preference marker rejects")
	old=legacy();old.ui.brightnessRevision=1
	check(not state.validate_snapshot(old),"partial marker cannot bypass default-repair boundary")
	state.new_game()
	check(state.d.ui.brightness==65 and not state.d.ui.brightnessUserAdjusted and not state.d.ui.brightnessLegacy100Repaired,"new game resets only to corrected65 default")
	print("BRIGHTNESS_START_MIGRATION: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
