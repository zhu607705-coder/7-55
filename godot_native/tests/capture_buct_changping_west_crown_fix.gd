extends SceneTree
var campus:Node2D
var out:=""
var checks:=0
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func frame()->void:await process_frame;await process_frame;await RenderingServer.frame_post_draw
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func changed(a:Image,b:Image)->int:
	a.convert(Image.FORMAT_RGBA8);b.convert(Image.FORMAT_RGBA8);var aa=a.get_data();var bb=b.get_data();var result:=0
	for i in range(0,aa.size(),4):
		var d:=0
		for c in range(4):d=maxi(d,absi(int(aa[i+c])-int(bb[i+c])))
		if d>1:result+=1
	return result
func run()->void:
	out=OS.get_environment("BUCT_WEST_QA_DIR").path_join("crown_fix_gpu");DirAccess.make_dir_recursive_absolute(out);root.size=Vector2i(1280,720)
	campus=load("res://campuses/buct_changping/scenes/playable.tscn").instantiate();campus.enable_west_hd_regions=true;root.add_child(campus);await frame()
	campus.set_process(false);campus.visitor.set_physics_process(false);campus.ui.hide();campus.pin_layer.hide();campus.canopy_locator.hide();campus.camera.position_smoothing_enabled=false
	campus.lake_surface.set_process(false);campus.lake_surface.set_animation_enabled(false)
	if is_instance_valid(campus.south_bridge_surface):campus.south_bridge_surface.set_process(false)
	var leaf=campus.objects.get_node("west_library_approach_crown_01");var counts:Array=[];var feet=[Vector2(563,823),Vector2(562,827)]
	for i in range(2):
		var foot:Vector2=feet[i];check(campus.is_walkable(foot),"Corrected pose is on unchanged legal paving: %s"%str(foot));campus.visitor.position=foot;campus.camera.position=foot+Vector2(0,-9);campus.camera.zoom=Vector2.ONE*4.8;campus.camera.reset_smoothing();leaf.hide();await frame();var old=root.get_texture().get_image();old.save_png(out.path_join("first-crown-%s-without.png"%("behind" if i==0 else "front")));leaf.show();await frame();var new=root.get_texture().get_image();new.save_png(out.path_join("first-crown-%s.png"%("behind" if i==0 else "front")));counts.append(changed(old,new))
	check(counts[0]>0 and counts[1]==0,"First crown occludes at legal rear foot and reveals front foot")
	var f=FileAccess.open(out.path_join("west-crown-corrected-result.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"replaces_only_invalid_first_pose_from_full_group_batch":true,"feet":feet,"behind_changed_pixels":counts[0],"front_changed_pixels":counts[1]},"  "));f.close();campus.queue_free();await process_frame;await process_frame;print("BUCT_WEST_CROWN_FIX checks=%d failures=%d"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
