extends SceneTree
## Actual source-sized renderer comparison for only the two added roadside crowns.
## Fixed poses establish pixel depth, not movement; use the continuous-walk fixture for movement.
var output := ""
var failures: Array[String]=[]
var results: Array=[]
func _init() -> void:call_deferred("run")
func settle() -> void:
	for i in range(2):await process_frame;await RenderingServer.frame_post_draw
func difference(a: Image,b: Image,rect: Rect2i) -> int:
	var count:=0
	for y in range(rect.position.y,rect.end.y):
		for x in range(rect.position.x,rect.end.x):
			if a.get_pixel(x,y)!=b.get_pixel(x,y):count+=1
	return count
func run() -> void:
	output=OS.get_environment("BUCT_ROAD_DEPTH_DIR")
	if DisplayServer.get_name()=="headless" or not output.is_absolute_path():
		push_error("A real renderer and explicit BUCT_ROAD_DEPTH_DIR are required");quit(2);return
	DirAccess.make_dir_recursive_absolute(output)
	var app=load("res://campuses/buct/scenes/playable.tscn").instantiate();root.add_child(app);await process_frame
	app.set_process(false);app.ui.hide();app.pin_layer.hide();app.camera.enabled=false
	var actor=app.visitor;actor.set_physics_process(false);actor.get_node("CanopyFootLocator").hide()
	actor.character_visual.advance_motion(Vector2.ZERO,0)
	var view:=SubViewport.new();view.size=Vector2i(1448,1086);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;view.world_2d=World2D.new();root.add_child(view)
	app.world.reparent(view,true)
	for probe in [{"id":"west_lane_yellow_curb_canopy","behind":Vector2(417,618),"front":Vector2(419,624)}, {"id":"library_west_avenue_west_canopy","behind":Vector2(606,505),"front":Vector2(608,524)}]:
		var crown=app.objects.get_node(probe.id)
		for mode in ["behind","front"]:
			var feet: Vector2=probe[mode];actor.position=feet
			var rect:=Rect2i(Vector2i(feet)+Vector2i(-14,-24),Vector2i(28,26))
			actor.hide();crown.show();await settle();var baseline:=view.get_texture().get_image()
			crown.hide();await settle();var without_overlay:=view.get_texture().get_image()
			var unchanged:=difference(baseline,without_overlay,Rect2i(0,0,1448,1086))==0
			actor.show();await settle();var unoccluded:=view.get_texture().get_image()
			crown.show();await settle();var actual:=view.get_texture().get_image()
			var occluded_pixels:=difference(actual,unoccluded,rect)
			var visible_pixels:=difference(actual,baseline,rect)
			var passed: bool=unchanged and app.is_walkable(feet) and (occluded_pixels>0 if mode=="behind" else occluded_pixels==0 and visible_pixels>0)
			var tag: String=str(probe.id)+"-"+mode
			var row: Dictionary={"id":probe.id,"mode":mode,"feet":[feet.x,feet.y],"walkable":app.is_walkable(feet),"overlay_changes_background":not unchanged,"source_overlay_occluded_student_pixels":occluded_pixels,"visible_actor_pixels":visible_pixels,"pass":passed}
			results.append(row);print("PASS " if passed else "FAIL ",tag," ",JSON.stringify(row))
			if not passed:failures.append(tag)
			actual.save_png(output.path_join(tag+".png"))
			unoccluded.save_png(output.path_join(tag+"-crown-hidden.png"))
			actual.get_region(Rect2i(Vector2i(feet)+Vector2i(-45,-65),Vector2i(90,95))).save_png(output.path_join(tag+"-detail.png"))
	var file:=FileAccess.open(output.path_join("road-depth.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema":"buct-chaoyang-road-depth-v1","engine":Engine.get_version_info().string,"adapter":RenderingServer.get_video_adapter_name(),"results":results,"failures":failures,"limit":"Fixed walkable renderer probes. Continuous movement is established separately; source crowns retain their explicitly inferred depth anchors."},"\t")+"\n")
	app.queue_free();view.queue_free();await process_frame
	print("BUCT_CHAOYANG_ROAD_DEPTH ","PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
