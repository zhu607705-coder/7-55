extends SceneTree
## External native-GDScript verification. Never supplies runtime overrides.
var checks: Array=[]
var packed_files: Array[String]=[]
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks.append({"ok":ok,"label":label})
	if not ok: push_error("NATIVE_ONLY: "+label)
func inventory(path: String) -> void:
	var directory=DirAccess.open(path)
	if directory==null: return
	directory.include_hidden=true; directory.list_dir_begin()
	while true:
		var name=directory.get_next()
		if name.is_empty(): break
		if name in [".",".."]: continue
		var child=path.path_join(name)
		if directory.current_is_dir(): inventory(child)
		else: packed_files.append(child)
	directory.list_dir_end()
func run() -> void:
	var out: String=OS.get_environment("NATIVE_ONLY_REPORT")
	check(not out.is_empty(),"external report destination supplied")
	check(OS.get_environment("PATH")==OS.get_environment("NATIVE_EMPTY_PATH"),"only empty executable search directory in PATH")
	check(DirAccess.get_files_at(OS.get_environment("NATIVE_EMPTY_PATH")).is_empty(),"Node and other helper executables unavailable through PATH")
	inventory("res://")
	var browser_files=packed_files.filter(func(path: String):return path.get_extension().to_lower() in ["js","mjs","cjs","ts","tsx","jsx","html","htm","wasm"])
	check(browser_files.is_empty(),"packed project has no browser runtime code")
	check(not FileAccess.file_exists("res://package.json") and not DirAccess.dir_exists_absolute("res://node_modules"),"no npm project or dependency directory packed")
	check(not FileAccess.file_exists("res://src/App.tsx"),"original browser source absent from packed project")
	check(ResourceLoader.exists("res://scenes/main.tscn"),"packed native scene exists")
	check(ResourceLoader.exists("res://scripts/ui/native_ui_theme.gd"),"updated native UI theme is packed")
	check(ResourceLoader.exists("res://scripts/ui/compact_overlay_layout.gd"),"updated compact native layout is packed")
	check(ResourceLoader.exists("res://scripts/chapters/phone_entry_session.gd"),"native phone entry lifecycle is packed")
	check(ResourceLoader.exists("res://scripts/ui/native_zjuding_loading_art.gd"),"native cropped loading presentation is packed")
	check(ResourceLoader.exists("res://scripts/ui/native_weather_icon.gd"),"native weather icon renderer is packed")
	check(ResourceLoader.exists("res://scripts/ui/native_tiyi_identity.gd"),"native sports-app visual adapter is packed")
	check(ResourceLoader.exists("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"),"bundled original font is packed")
	var state=root.get_node("State")
	check(state.get_script() is GDScript,"state controller is native GDScript")
	var reload_mode=OS.get_cmdline_user_args().has("--reload")
	var expected_path="user://native-only-expected.json"
	if reload_mode:
		var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(expected_path))
		check(state.d==expected.state,"second native process restored exact saved state")
		check(FileAccess.get_sha256(state.SAVE_PATH)==expected.saveSha256,"reopening did not rewrite the verified save")
	else:
		check(state.d.native.page=="alarm","fresh native process opens authored alarm")
	var shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell)
	for i in 8: await process_frame
	check(shell is Control and shell.world is Control,"native Control scene and native world instantiated")
	check(shell.world.get_script() is GDScript,"world renderer is native GDScript")
	check(shell.world_viewport is SubViewport,"world uses Godot SubViewport")
	if not reload_mode:
		for action in ["c1_start_alarm","c1_dismiss_alarm","c1_wake","c1_enter_home"]:
			check(state.act(action).get("handled",false),"native controller handled "+action)
		check(state.d.native.page=="phone_home","native source actions reached home")
		check(state.save_game(),"native save writer succeeded")
		var file=FileAccess.open(expected_path,FileAccess.WRITE)
		file.store_string(JSON.stringify({"state":state.d,"saveSha256":FileAccess.get_sha256(state.SAVE_PATH)})); file.close()
	else: check(state.d.native.page=="phone_home","reloaded native UI retains home")
	await shell.shutdown(); shell.queue_free(); await process_frame
	# The original3D view loads packed native scenes and raw pose data. These
	# checks catch export filters which silently omit the non-resource .bin files.
	var before_3d: Dictionary=state.d.duplicate(true)
	var poses=FileAccess.get_file_as_bytes("res://assets/native_755/ride/rider_bone_poses.bin")
	check(poses.size()==8082816,"original rider pose binary is present in the exported pack")
	var road=load("res://scripts/presentation/chase3d/source_chase_3d.gd").new()
	road.configure({"asset_directory":"res://assets/native_755/ride/","render_width":960,"live_shadows":true})
	root.add_child(road);await process_frame
	check(road.ready3d and road.hero.bones.size()>0,"packed original rider and campus3D scenes instantiate without source tools")
	var model=load("res://scripts/games/chase_stunt_model.gd").new()
	road.update_view(model,0,false,false)
	check(model.tick==0 and state.d==before_3d,"exported renderer does not advance simulation or saved state")
	road.dispose();road.queue_free();await process_frame
	var film=load("res://scripts/presentation/chase_transition_3d_presenter.gd").new()
	film.manual_clock=true;root.add_child(film);film.play("finish")
	check(film.ready3d and film.source_bones.size()>0,"packed original arrival scene and pose table instantiate")
	film.advance(.125)
	check(film.frame==3 and state.d==before_3d,"exported film follows its source clock without a story callback")
	film.dispose();film.queue_free();await process_frame
	var failures=checks.filter(func(row):return not row.ok)
	var file=FileAccess.open(out,FileAccess.WRITE)
	file.store_string(JSON.stringify({"kind":"exported-native-only-runtime","reload":reload_mode,"checks":checks,"failures":failures.size(),"packedFiles":packed_files,"browserRuntimeFiles":browser_files,"sourceTreeUsed":false,"externalHarnessOnly":true},"\t")); file.close()
	print("NATIVE_ONLY_ACCEPTANCE: ",checks.size()," checks; ",failures.size()," failures; packed resources=",packed_files.size())
	quit(1 if not failures.is_empty() else 0)
