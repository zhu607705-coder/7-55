extends SceneTree
## Eleven-second automated native route proof, unchanged student and walking speed.
var records: Array = []
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var campus=load("res://campuses/buct_changping/scenes/playable.tscn").instantiate()
	root.add_child(campus);await process_frame;await physics_frame;await process_frame
	if not is_instance_valid(campus.wenli_hd_region):quit(1);return
	campus.set_process(false);campus.pin_layer.hide();campus.canopy_locator.hide()
	campus.camera.position_smoothing_enabled=false;campus.camera.position=Vector2(750,750)
	campus.camera.zoom=Vector2.ONE*2.1;campus.camera.reset_smoothing()
	campus.visitor.position=Vector2(733,683)
	var target:=Vector2(760,877);campus.path_to(target)
	var banner:=Label.new();banner.text="文理楼周边 · 默认 2.1× · 原有步道与学生"
	banner.add_theme_font_override("font",campus.font);banner.add_theme_font_size_override("font_size",21)
	banner.position=Vector2(20,84);campus.ui.add_child(banner)
	var off_route:=0;var traveled:=0.0;var previous:Vector2=campus.visitor.position
	for index in range(220):
		if campus.visitor.position.distance_to(target)<6:
			target=Vector2(733,683) if target.y>800 else Vector2(760,877)
			campus.path_to(target)
		if index==180:
			campus.camera.zoom=Vector2.ONE*4.8
			banner.text="近景 4.8× · 同一真实场景"
		if index>=180:campus.camera.position=campus.visitor.position+Vector2(-35,-4)
		campus.wenli_layer.update_actor_foot(campus.visitor.position.y)
		var walkable:bool=campus.is_walkable(campus.visitor.position)
		if not walkable:off_route+=1
		traveled+=campus.visitor.position.distance_to(previous);previous=campus.visitor.position
		if index%5==0:records.append({"frame":index,"feet":[previous.x,previous.y],"walkable":walkable,"zoom":campus.camera.zoom.x,"speed":campus.visitor.speed,"height":campus.visitor.display_height})
		await process_frame
	var out:=OS.get_environment("BUCT_HD_QA_DIR").path_join("gpu")
	var file:=FileAccess.open(out.path_join("preview-native-trace.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"status":"automated_native_continuous_walk","fixed_fps":20,"planned_frames":220,"off_route_frames":off_route,"traveled_source_px":traveled,"samples":records},"\t"));file.close()
	print("BUCT_HD_WALK off_route=%d traveled=%.2f speed=%.1f"%[off_route,traveled,campus.visitor.speed])
	campus.queue_free();await process_frame;quit(0 if off_route==0 and traveled>500 else 1)
