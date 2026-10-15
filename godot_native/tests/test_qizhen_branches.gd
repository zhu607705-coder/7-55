extends SceneTree
## Differential regression against the active original controller, including real
## fishing-v4 replay and native disk save/load between all six material orders.
const Lake=preload("res://scripts/chapters/c3_lake.gd")
var lake: RefCounted=Lake.new()
var state: Node
var source: Dictionary
var checks: int=0
var failures: int=0
var saves: int=0
func check(value: bool, label: String) -> void:
	checks+=1
	if not value:
		failures+=1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func setup(projected: Dictionary) -> void:
	state.d=state.initial()
	var s: Dictionary=state.d
	s.native.chapter=3
	s.native.scene="qizhen_lake"
	s.native.page="c3_lake"
	s.native.mode=projected.qizhenLake.mode
	s.native.player={"x":836,"y":470}
	s.rpgScene="qizhen_lake"
	s.runtimeMode="rpg"
	s.qizhenLake.boardingTutorialCompleted=true
	for id: String in projected.items: s.items[id]=projected.items[id]
	for key: String in projected.qizhenLake: s.qizhenLake[key]=projected.qizhenLake[key]
	s.ui.selectedItem=projected.selectedItem
	s.native.selected_item="" if projected.selectedItem==null else str(projected.selectedItem)
	lake=Lake.new()
func project() -> Dictionary:
	var result: Dictionary={"items":{},"qizhenLake":{},"selectedItem":state.d.ui.selectedItem}
	for id: String in source.itemIds: result.items[id]=state.d.items[id]
	for key: String in source.qKeys: result.qizhenLake[key]=state.d.qizhenLake[key]
	return result
func compare(expected: Dictionary,label: String) -> void:
	var actual: Dictionary=project()
	check(actual==expected,label+" matches active source"+("\nexpected="+JSON.stringify(expected)+"\nactual="+JSON.stringify(actual) if actual!=expected else ""))
func physical(id: String) -> Dictionary:
	for entry: Dictionary in lake.definitions():
		if entry.id!=id: continue
		var stand: Dictionary=entry.get("stand",{"x":entry.x,"y":entry.y})
		state.d.native.player={"x":stand.x,"y":stand.y}
		return lake.dispatch(state.d,"c3_lake_target:"+id)
	check(false,"physical target exists "+id)
	return {}
func cast(spot: String) -> void:
	var target_id: String={"locker_key":"qizhen_fishing_item_1","net_frame":"qizhen_fishing_item_3","fish":"qizhen_fishing_fish","paper":"qizhen_final_paper_cast"}[spot]
	var request: Dictionary=physical(target_id)
	check(request.has("game"),"source-authorized "+spot+" opens fishing-v4")
	if not request.has("game"): return
	var result: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/rhythm_"+spot+".json"))
	result.session_id=request.game.session_id
	lake.dispatch(state.d,"c3_fishing_result",result)
func reload_disk(label: String) -> void:
	check(state.validate_snapshot(state.d),label+" is valid before disk save")
	check(state.save_game(),label+" native save succeeds")
	check(FileAccess.file_exists("user://save.json"),label+" save bytes exist")
	state.d=state.initial()
	check(state.load_game(),label+" actual native disk reload succeeds")
	saves+=1
func run_steps(steps: Array,label: String) -> void:
	for index: int in range(steps.size()):
		var step: Dictionary=steps[index]
		var before: Dictionary=state.d.duplicate(true)
		match step.op:
			"move":
				state.d.qizhenLake.zone=step.args[0]
				state.d.qizhenLake.vehicle=step.args[1]
			"castAt": cast(step.args[0])
			"useItemAt":
				if step.args[0]=="qizhen_use_item_5": lake.dispatch(state.d,"c3_tin_open")
				else: physical("qizhen_feed_tin" if step.args[0]=="qizhen_use_item_4" else step.args[0])
			"completeSwanBranch", "feedSwan": physical("qizhen_black_swan")
			"combineItems":
				var result: Dictionary=lake.dispatch(state.d,"c3_lake_combine",step.args[0])
				check(result.get("status")==step.result,label+" combination returns source status")
				if step.result!="accepted": check(state.d==before,label+" rejected assembly is zero-write")
			"reload": reload_disk(label+" step "+str(index))
		compare(step.expected,label+" "+str(index)+" "+step.op)
func isolated_save_fixture() -> bool:
	# The launcher declares a fresh mkdtemp profile. Its actual location must match;
	# neither a /tmp prefix nor a general workspace path is permission to write saves.
	var declared:=OS.get_environment("GODOT_TEST_USER_DATA_DIR").replace("\\", "/")
	if declared.is_empty() or not declared.is_absolute_path():return false
	declared=declared.simplify_path().trim_suffix("/")
	var sandbox:=declared.get_base_dir().get_base_dir()
	var name:=sandbox.get_file()
	if not (name.begins_with("755-lake-source-parity-") or name.begins_with("755-native-check-")):return false
	var temporary_root:=OS.get_environment("TMPDIR").replace("\\", "/")
	if temporary_root.is_empty():temporary_root="/tmp"
	if not temporary_root.is_absolute_path():return false
	if sandbox.get_base_dir()!=temporary_root.simplify_path().trim_suffix("/"):return false
	if declared!=sandbox.path_join("data/SevenFiftyFiveNative"):return false
	if OS.get_user_data_dir().replace("\\", "/").simplify_path().trim_suffix("/")!=declared:return false
	if ProjectSettings.globalize_path("user://").replace("\\", "/").simplify_path().trim_suffix("/")!=declared:return false
	if not DirAccess.dir_exists_absolute(sandbox):return false
	# The dedicated lake launcher supplies a one-use creation receipt as well.
	# The standard aggregate runner retains its existing declared-fresh contract.
	if name.begins_with("755-lake-source-parity-"):
		var nonce:=OS.get_environment("GODOT_LAKE_TEST_NONCE")
		if nonce.length()<16:return false
		var receipt_path:=sandbox.path_join(".lake-test-fixture.json")
		if not FileAccess.file_exists(receipt_path):return false
		var receipt=JSON.parse_string(FileAccess.get_file_as_string(receipt_path))
		if not receipt is Dictionary:return false
		if receipt.get("schema")!="lake-test-fixture-v1" or receipt.get("nonce")!=nonce:return false
		if str(receipt.get("user_data_dir", "")).replace("\\", "/").simplify_path().trim_suffix("/")!=declared:return false
	for file in ["save.json","save.previous.json","save.json.tmp"]:
		if FileAccess.file_exists(declared.path_join(file)) or DirAccess.dir_exists_absolute(declared.path_join(file)):return false
	return true

func run() -> void:
	if not isolated_save_fixture():
		printerr("LAKE_TEST_ISOLATION_REQUIRED: use the isolated native runner; refusing writes outside a fresh declared test profile")
		quit(2)
		return
	state=root.get_node("State")
	state.developer_mode=false
	source=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/qizhen_branch_source.json"))
	for order: Dictionary in source.orders:
		setup(order.initial)
		run_steps(order.steps," → ".join(order.order))
	for entry: Dictionary in source.combinations:
		setup(entry.initial)
		var before: Dictionary=state.d.duplicate(true)
		var result: Dictionary=lake.combine_items(state.d,entry.requested)
		check(result.get("status")==entry.result,entry.label+" original return status")
		compare(entry.expected,entry.label)
		if entry.result!="accepted": check(state.d==before,entry.label+" is atomically zero-write")
		else:
			check(state.d.native.selected_item==("" if entry.expected.selectedItem==null else str(entry.expected.selectedItem)),entry.label+" clears only consumed native selection")
	for entry: Dictionary in source.swan:
		setup(entry.initial)
		var before: Dictionary=state.d.duplicate(true)
		var result: Dictionary=lake.complete_swan_branch(state.d)
		check(result.get("status")==entry.result,entry.label+" swan original return status")
		compare(entry.expected,entry.label+" swan")
		if entry.result!="accepted": check(state.d==before,entry.label+" swan rejection is zero-write")
	setup(source.legacy.initial)
	run_steps(source.legacy.steps,"legacy net/tin/fish save")
	check(state.d.items.fishingRod and state.d.items.swanMagnet and not state.d.items.magneticFishingRod,"legacy feeding grants an independent magnet and preserves rod")
	test_ui_and_physical_guards()
	print("Qizhen source branch parity: ",checks," checks, ",saves," native disk saves, ",failures," failures")
	quit(1 if failures else 0)
func test_ui_and_physical_guards() -> void:
	setup(source.orders[0].initial)
	state.d.qizhenLake.zone="swan_cove"
	var swan_target: Dictionary={}
	for entry: Dictionary in lake.targets("qizhen_lake",state.d):
		if entry.id=="qizhen_black_swan": swan_target=entry
	check(not swan_target.is_empty() and not swan_target.has("item"),"independent swan control is usable without legacy carp")
	state.d.native.player={"x":0,"y":0}
	var before: Dictionary=state.d.duplicate(true)
	lake.dispatch(state.d,"c3_lake_target:qizhen_black_swan")
	check(state.d==before,"remote swan interaction cannot mint magnet")
	state.d.native.mode="dark"
	before=state.d.duplicate(true)
	physical("qizhen_black_swan")
	# Moving to the target is a fixture setup, not a story side effect.
	before.native.player=state.d.native.player
	check(state.d==before,"dark physical swan interaction is zero-write")
	state.d.native.mode="light"
	state.d.qizhenLake.zone="open_water"
	before=state.d.duplicate(true)
	physical("qizhen_black_swan")
	before.native.player=state.d.native.player
	check(state.d==before,"wrong-zone physical swan interaction is zero-write")
	for id: String in source.parts: state.d.items[id]=true
	var ids: Array=lake.actions("c3_lake",state.d).map(func(a: Dictionary) -> String: return a.id)
	check(ids.has("c3_lake_combine") and not ids.has("c3_net_combine") and not ids.has("c3_magnet_combine"),"lake controls expose one four-part assembly")
	for missing: String in source.parts:
		state.d.items[missing]=false
		check(not lake.actions("c3_lake",state.d).any(func(a: Dictionary) -> bool: return a.id=="c3_lake_combine"),"assembly control waits for "+missing)
		before=state.d.duplicate(true)
		lake.dispatch(state.d,"c3_magnet_combine")
		check(state.d==before,"legacy assembly intent cannot consume partial materials: "+missing)
		state.d.items[missing]=true
	before=state.d.duplicate(true)
	lake.dispatch(state.d,"c3_net_combine")
	check(state.d==before,"legacy pairwise net intent cannot consume independent materials")
	physical("qizhen_open_workbench")
	check(state.d.items.magneticFishingRod and state.d.qizhenLake.phase=="paper_capture","physical source workbench performs atomic final assembly")
	for id: String in source.parts: check(not state.d.items[id],"workbench consumed "+id)
	check(not state.d.qizhenLake.swanFed,"assembly does not fabricate independent branch flags")
