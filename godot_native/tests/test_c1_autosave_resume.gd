extends SceneTree
## Real Main C1 input/autosave in a disposable profile, then independent Continue.
var state: Node
var shell: Control
var checks: Array=[]
var writes: Array=[]
var failures:=0
var before_source: Dictionary={}
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> bool:
	checks.append({"ok":ok,"label":label})
	if not ok:failures+=1;push_error("C1_AUTOSAVE: "+label)
	return ok
func frames(n: int=5) -> void:
	for i in n:await process_frame
func button(label: String) -> Button:
	for node in shell.find_children("*","Button",true,false):
		if node.text==label and node.is_visible_in_tree():return node
	return null
func click(control: Control,label: String) -> void:
	if not check(control!=null and control.is_visible_in_tree(),"real control visible: "+label):return
	var point: Vector2=control.get_global_transform_with_canvas()*(control.size/2)
	for down in [true,false]:
		var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;Input.parse_input_event(motion)
		var event:=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down
		Input.parse_input_event(event);Input.flush_buffered_events();await process_frame
	await frames()
func verify_write(label: String) -> void:
	var valid: bool=state.validate_snapshot(state.d)
	var disk: Variant=JSON.parse_string(FileAccess.get_file_as_string(state.SAVE_PATH)) if FileAccess.file_exists(state.SAVE_PATH) else null
	var matches: bool=disk is Dictionary and disk.get("state",{}).get("native",{}).get("page","")==state.d.native.page
	if disk is Dictionary:matches=matches and disk.state.phoneBattery.percent==state.d.phoneBattery.percent
	check(valid,label+" current snapshot passes shape/domain validation")
	check(matches,label+" autosave already wrote current page and battery before any explicit save")
	check(state.save_game(),label+" ordinary explicit save succeeds")
	writes.append({"operation":label,"page":state.d.native.page,"battery":state.d.phoneBattery.percent,"valid":valid,"automaticWritebackMatched":matches,"savedBytes":FileAccess.get_file_as_bytes(state.SAVE_PATH).size()})
func run() -> void:
	state=root.get_node("State")
	if not check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated profile, formal player save remains untouched"):finish();return
	check(not state.developer_mode,"ordinary non-DEV persistence path")
	var copied:=FileAccess.file_exists(state.SAVE_PATH)
	if copied:
		before_source=JSON.parse_string(FileAccess.get_file_as_string(state.SAVE_PATH)).state
		check(state.load_game(),"current loader accepts copied native save")
		check(state.d.qizhenLake.has("legacyNetMaterialsConsumed"),"old native save receives narrow receipt default in memory")
	var legacy_path:=OS.get_environment("C1_LEGACY_VALIDATOR")
	if not legacy_path.is_empty():
		var legacy: Node=load(legacy_path).new()
		var old_accepts: bool=legacy.validate_snapshot(before_source)
		var current_accepts: bool=state.validate_snapshot(before_source)
		check(not old_accepts and current_accepts,"old cached validator rejects missing new field; current narrow migration accepts same unchanged save")
		writes.append({"operation":"cached-validator-vs-current","oldAcceptsOriginalSave":old_accepts,"currentAcceptsOriginalSave":current_accepts,"originalReceiptPresent":before_source.qizhenLake.has("legacyNetMaterialsConsumed")})
		legacy.free()
	root.size=Vector2i(1440,900)
	if OS.get_environment("C1_RELOAD_ONLY")=="1":
		check(state.d.native.page=="wechat" and int(state.d.phoneBattery.percent)==15,"independent process reload retains WeChat and15-percent battery")
		root.set_meta("entry_arguments_consumed",true);change_scene_to_file("res://scenes/entry.tscn");await frames()
		await click(current_scene.story_button,"entry Continue")
		shell=current_scene
		check(shell.get_script().resource_path=="res://scripts/main.gd" and state.d.native.page=="wechat" and int(state.d.phoneBattery.percent)==15,"entry Continue keeps the saved WeChat page instead of initial alarm")
		verify_write("post-Continue");await finish();return
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	check(state.validate_snapshot(state.d),"fresh/current loaded Main starts with a valid snapshot")
	if not state.d.native.get("alarm_ringing",false):await click(button("开始游戏"),"start alarm");verify_write("c1_start_alarm")
	else:check(state.save_game(),"copied ringing alarm can be rewritten by current runtime")
	await click(button("关闭"),"dismiss alarm");verify_write("c1_dismiss_alarm")
	await click(button("……再睡5分钟……"),"wake");verify_write("c1_wake")
	await click(button("进入手机主界面"),"enter Home");verify_write("c1_enter_home")
	await click(shell.page_body.find_child("HomeApp_wechat",true,false),"Home WeChat");verify_write("open_wechat")
	await click(shell.page_body.find_child("WechatRow_1",true,false),"friend conversation");verify_write("c1_friend")
	check(state.d.native.page=="wechat" and int(state.d.phoneBattery.percent)==15,"fresh real input reaches the expected WeChat15-percent state")
	await finish()
func finish() -> void:
	var out:=OS.get_environment("C1_SAVE_REPORT")
	if not out.is_empty():var file:=FileAccess.open(out,FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"writes":writes,"process":OS.get_process_id(),"formalMode":true,"notManualPlaythrough":true},"\t"));file.close()
	if is_instance_valid(shell) and shell.has_method("shutdown"):await shell.shutdown();shell.queue_free();await frames()
	print("C1_AUTOSAVE_RESUME checks=",checks.size()," failures=",failures)
	quit(1 if failures else 0)
