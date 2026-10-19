extends SceneTree
## Self-contained: also run this external script against a source-less PCK.
## --require-production is an assertion, never an override of product policy.
var checks:=0
var failures:=0
var state:Node
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("DEVELOPER_ACCESS: "+label)
func frames(count:int=3)->void:
	for i in count:await process_frame
func isolated()->bool:
	var actual:=OS.get_user_data_dir().simplify_path().trim_suffix("/")
	if OS.get_name()!="macOS":return actual.begins_with("/tmp/")
	var expected:=OS.get_environment("GODOT_TEST_USER_DATA_DIR").simplify_path().trim_suffix("/")
	if not expected.is_absolute_path() or expected!=actual:return false
	var sandbox:=expected.get_base_dir().get_base_dir()
	if not sandbox.get_file().begins_with("755-native-check-") or expected!=sandbox.path_join("data/SevenFiftyFiveNative"):return false
	if sandbox.get_base_dir()!=OS.get_environment("HOME").path_join("Library/Application Support").simplify_path():return false
	if ProjectSettings.get_setting("application/config/custom_user_dir_name","")!=sandbox.get_file()+"/data/SevenFiftyFiveNative":return false
	var nonce:=OS.get_environment("GODOT_NATIVE_TEST_NONCE")
	var receipt_path:=sandbox.path_join(".native-test-fixture.json")
	if nonce.length()<16 or not FileAccess.file_exists(receipt_path):return false
	var receipt=JSON.parse_string(FileAccess.get_file_as_string(receipt_path))
	return receipt is Dictionary and receipt.get("schema")=="native-macos-test-v1" and receipt.get("nonce")==nonce and receipt.get("user_data_dir")==actual
func click(button:Button)->void:
	var point:=button.get_global_transform_with_canvas()*(button.size/2)
	for down:bool in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down
		root.push_input(event,true);await frames(1)
	await frames()
func shortcut(code:Key)->void:
	for down:bool in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.ctrl_pressed=true;event.shift_pressed=true;event.pressed=down
		root.push_input(event,true);await frames(1)
	await frames()
func has_button(node:Node,text:String)->bool:
	for button:Node in node.find_children("*","Button",true,false):
		if button is Button and button.text==text:return true
	return false
func finish()->void:
	print("DEVELOPER_TOOLS_ACCESS ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
func run()->void:
	if not isolated():push_error("Refusing developer access tests outside an isolated receipt profile");quit(2);return
	create_timer(35).timeout.connect(func():push_error("Developer access watchdog");quit(2))
	state=root.get_node("State")
	var args:=OS.get_cmdline_user_args()
	var production:=OS.has_feature("755_production")
	if args.has("--require-production"):
		check(production,"Real exported pack declares755_production; an editor source run cannot substitute")
		if not production:finish();return
	check(state.has_method("developer_tools_available"),"State exposes the shared read-only developer policy")
	if not state.has_method("developer_tools_available"):finish();return
	var allowed:bool=state.developer_tools_available()
	check(allowed==(OS.is_debug_build() and not production),"Actual binary and exported feature determine developer access")
	print("DEVELOPER_ACCESS_RUNTIME ",JSON.stringify({"productionFeature":production,"debugBinary":OS.is_debug_build(),"editorBinary":OS.has_feature("editor"),"available":allowed,"args":Array(args)}))
	# A settings-only import is a persisted boot fixture, never story progress.
	if args.has("--seed-formal-volume"):
		var seed:Dictionary=state.initial();seed.native.settings.volume=.37
		var file:=FileAccess.open("user://developer-access-seed.json",FileAccess.WRITE)
		file.store_string(JSON.stringify({"format":"7-55-godot-native","version":1,"sourceVersion":35,"state":seed}));file.close()
		check(state.import_save("user://developer-access-seed.json").get("ok",false),"Settings-only seed imports through the real formal save transaction")
		check(is_equal_approx(float(state.d.native.settings.volume),.37),"Settings-only seed is active")
		finish();return
	if args.has("--check-boot-volume"):
		var expected:=.37 if production or not OS.is_debug_build() else .6
		check(is_equal_approx(float(state.d.native.settings.volume),expected),"Production ignores --fresh and resumes saved settings; source QA may start fresh")
		finish();return
	root.size=Vector2i(1440,900)
	var initial:Dictionary=state.d.duplicate(true)
	check(change_scene_to_file("res://scenes/entry.tscn")==OK,"Real chooser loads")
	await frames(5)
	var entry:Control=current_scene
	check(entry.scene_file_path=="res://scenes/entry.tscn","QA-only startup parameters cannot bypass a production chooser")
	if entry.scene_file_path!="res://scenes/entry.tscn":finish();return
	check(is_instance_valid(entry.preview_button)==allowed,"Prototype menu exists only in an allowed development runtime")
	check(has_button(entry,"动画与原型预览")==allowed,"Production does not merely hide a still-created preview button")
	if allowed:
		await click(entry.preview_button)
		check(entry.previews_open and entry.preview_menu.visible,"Source QA opens its real preview catalogue")
		entry.close_previews();await frames()
	else:
		entry.open_previews();entry._build_preview_menu();entry._open_preview("res://scenes/chapter4_endless_stair_preview.tscn")
		check(not entry.previews_open and not is_instance_valid(entry.preview_instance) and not is_instance_valid(entry.preview_menu),"Direct preview entry methods also deny production access")
	check(state.d==initial,"Preview admission cannot change formal state")
	await click(entry.story_button);await frames(5)
	var shell:Control=current_scene
	check(shell.scene_file_path=="res://scenes/main.tscn","Real Continue remains available without a developer jump")
	if shell.scene_file_path!="res://scenes/main.tscn":finish();return
	check(state.d.native.chapter==initial.native.chapter and state.d.native.page==initial.native.page and state.d.native.scene==initial.native.scene,"Main ignores production checkpoint/preview/page startup overrides")
	shell._show_settings();await frames()
	check(has_button(shell.modal,"DEV · 独立场景检查")==allowed,"Normal settings expose no production chapter-skip button")
	check(has_button(shell.modal,"保存进度") and has_button(shell.modal,"导出存档") and has_button(shell.modal,"导入存档"),"Formal save management remains available")
	shell._close_modal();await frames()
	await shortcut(KEY_D)
	check(is_instance_valid(shell.modal)==allowed,"Actual root CtrlShiftD respects the shared policy")
	if is_instance_valid(shell.modal):shell._close_modal();await frames()
	if not allowed:
		await shortcut(KEY_G)
		shell._show_developer();shell._run_visual_gallery();await frames()
		check(not is_instance_valid(shell.modal),"Direct developer/gallery methods and root CtrlShiftG remain closed")
	var before:Dictionary=state.d.duplicate(true)
	var formal:Dictionary=state.formal_snapshot.duplicate(true)
	var counts:Dictionary={"changed":0,"reset":0}
	state.changed.connect(func():counts.changed+=1)
	state.story_reset.connect(func():counts.reset+=1)
	var accepted:bool=state.begin_checkpoint("c4-755-elevator-history")
	if allowed:
		check(accepted and state.developer_mode and state.d.native.chapter==4,"Source QA retains the real complete checkpoint entry")
		state.restore_formal()
		check(state.d==before and not state.developer_mode,"Source QA checkpoint restores its formal snapshot")
		state.begin_preview(3,"qizhen_lake")
		check(state.developer_mode and state.d.native.chapter==3 and state.d.native.scene=="qizhen_lake","Source QA retains isolated scene preview")
		state.restore_formal()
		check(state.d==before,"Source QA preview restores the unchanged formal snapshot")
	else:
		state.begin_preview(4,"duan_yongping_temporal_maze")
		check(not accepted and state.developer_checkpoints().is_empty(),"State checkpoint catalogue and admission deny production")
		check(state.d==before and state.formal_snapshot==formal and not state.developer_mode,"Rejected calls cannot mutate state or capture a formal snapshot")
		check(counts.changed==0 and counts.reset==0,"Rejected calls emit no state-reset or changed signals")
	await shell.shutdown();shell.queue_free();await frames(3)
	finish()
