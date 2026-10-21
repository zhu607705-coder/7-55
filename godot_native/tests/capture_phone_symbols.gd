extends "res://tests/capture_ui_redesign.gd"
## Supplementary real-GPU snapshots for the font-independent icon regression.
## DEV checkpoint + active music fixture; never an earned campaign replay.
func run() -> void:
	if DisplayServer.get_name()=="headless" and not validate_only: quit(2); return
	if not load("res://tests/native_test_isolation.gd").is_isolated_save(): quit(2); return
	create_timer(90).timeout.connect(func(): push_error("Symbol capture deadline exceeded"); quit(2))
	output=OS.get_environment("UI_CAPTURE_DIR")
	if output.is_empty(): quit(2); return
	DirAccess.make_dir_recursive_absolute(output)
	state=root.get_node("State"); state.developer_mode=true
	for dimensions: Vector2i in [Vector2i(1440,900),Vector2i(390,844)]:
		DisplayServer.window_set_size(dimensions); root.size=dimensions
		for page: String in ["phone_home","zjuding","library_app","control_center"]:
			if not fixture_checkpoint("c2-dorm-exit"): quit(1); return
			state.d.native.scene=""; state.d.native.page=page
			state.d.ui.musicPlaying=true; state.d.native.settings.volume=0
			await fresh_shell(dimensions)
			shell.mobile_world=false; shell._refresh(); shell._process(2); await frames(); shell._layout()
			fixture_note="DEV c2-dorm-exit + musicPlaying; actual source icons; not earned completion"
			await capture("%dx%d-symbols-%s" % [dimensions.x,dimensions.y,page])
		# Explicit source-checkpoint DEV states: actual phone map, not the world map.
		for scene_id: String in ["lake-map","weather-complete"]:
			if not fixture_checkpoint("c3-qizhen-location"): quit(1); return
			state.d.native.scene=""; state.d.native.page="zjuding" if scene_id=="lake-map" else "weather"
			state.d.networkMode="campus_wifi"; state.d.native.settings.volume=0
			state.d.qizhenLake.active=true
			state.d.qizhenLake.phase="location_search" if scene_id=="lake-map" else "rain_recovery"
			if scene_id=="weather-complete":
				state.d.qizhenLake.rainRescueCompleted=true
				state.d.qizhenLake.weatherAdjustmentRequested=true
				state.d.qizhenLake.rainSafetyCleared=true
				state.d.items.hairDryer=true
			await fresh_shell(dimensions)
			shell.mobile_world=false; shell._refresh(); shell._process(2); await frames()
			if scene_id=="lake-map":
				shell.phone_builder.zjuding_page="campus_map"
				shell._refresh(); await frames()
			shell._layout()
			var target_name: String="QizhenMapDrop" if scene_id=="lake-map" else "WeatherConnectedDevice" if FileAccess.file_exists("res://scripts/ui/native_symbol_icon.gd") else "QizhenWeatherDevice"
			if not require_fixture(shell.page_body.find_child(target_name,true,false)!=null,"actual phone surface mounts: "+scene_id): continue
			fixture_note="DEV c3-qizhen-location + qizhenLake.active=true/phase=location_search + zjuding_page=campus_map; not earned completion" if scene_id=="lake-map" else "DEV c3-qizhen-location + phase=rain_recovery/rainRescueCompleted/weatherAdjustmentRequested/rainSafetyCleared/items.hairDryer=true; not earned completion"
			await capture("%dx%d-symbols-%s" % [dimensions.x,dimensions.y,scene_id])
	var file:=FileAccess.open(output.path_join("symbol-captures.json"),FileAccess.WRITE)
	if file==null: quit(2); return
	file.store_string(JSON.stringify(report,"\t")); file.close()
	await shell.shutdown(); shell.queue_free(); await frames()
	print("SYMBOL_FIXTURE_VALIDATION_COMPLETE " if validate_only else "SYMBOL_CAPTURE_COMPLETE ",report.size())
	quit(1 if capture_failed else 0)
