extends SceneTree
## Full-map GPU proof: compare only the actual student's sprite against itself hidden.
## These fixed depth probes verify rendering, not new walkable paths behind buildings.
var failures: Array[String]=[]
var results: Array=[]
var output: String
func _init() -> void:call_deferred("run")
func frames(count:=2) -> void:
	for i in range(count):await process_frame;await RenderingServer.frame_post_draw
func difference(a: Image,b: Image,rect: Rect2i) -> int:
	var changed:=0
	for y in range(rect.position.y,rect.end.y):
		for x in range(rect.position.x,rect.end.x):
			if a.get_pixel(x,y)!=b.get_pixel(x,y):changed+=1
	return changed
func run() -> void:
	output=OS.get_environment("BUCT_STUDENT_OCCLUSION_DIR")
	if DisplayServer.get_name()=="headless" or not output.is_absolute_path():
		push_error("A real renderer and explicit BUCT_STUDENT_OCCLUSION_DIR are required");quit(2);return
	DirAccess.make_dir_recursive_absolute(output)
	for campus in ["buct_haidian","buct"]:
		var app=load("res://campuses/"+campus+"/scenes/playable.tscn").instantiate();root.add_child(app);await process_frame
		app.set_process(false);app.ui.hide();app.pin_layer.hide();app.camera.enabled=false
		if campus=="buct_haidian":app.canopy_locator.hide()
		var actor=app.visitor;actor.set_physics_process(false)
		var visual=actor.character_visual;visual.advance_motion(Vector2.ZERO,0)
		var view:=SubViewport.new();view.size=Vector2i(1448,1086);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
		var world=app.world;app.remove_child(world);view.add_child(world)
		var building=app.real_buildings.main_building if campus=="buct_haidian" else app.library
		var x:=650.0 if campus=="buct_haidian" else 750.0
		var depth: float=building.depth_y_at_world_x(x)
		for front in [false,true]:
			var feet:=Vector2(x,depth+5 if front else depth-30);actor.position=feet
			var tag: String=campus+"-building-"+("front" if front else "behind")
			visual.sprite.hide();await frames();var baseline:=view.get_texture().get_image()
			visual.sprite.show();await frames();var actual:=view.get_texture().get_image()
			var body_rect:=Rect2i(Vector2i(feet)+Vector2i(-14,-24),Vector2i(28,26))
			var changed:=difference(actual,baseline,body_rect)
			var passed:=changed>15 if front else changed==0
			var row: Dictionary={"campus":campus,"front":front,"feet":[feet.x,feet.y],"student_sprite_changed_pixels":changed,"student_height":visual.target_height,"foot_error":visual.current_foot_global().distance_to(actor.global_position),"walkable":app.is_walkable(feet),"qualification":"Fixed renderer-depth probe; no new walking path or collision change","pass":passed}
			results.append(row);print("PASS " if passed else "FAIL ",tag," student-pixels=",changed)
			if not passed:failures.append(tag)
			actual.save_png(output.path_join(tag+".png"))
			baseline.save_png(output.path_join(tag+"-sprite-hidden.png"))
			actual.get_region(Rect2i(Vector2i(feet)+Vector2i(-90,-110),Vector2i(180,145))).save_png(output.path_join(tag+"-detail.png"))
		world.queue_free();app.queue_free();await process_frame;view.queue_free();await process_frame
	var file:=FileAccess.open(output.path_join("student-occlusion-results.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"results":results,"failures":failures},"  ")+"\n");file.close()
	print("BUCT_STUDENT_OCCLUSION ","PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
