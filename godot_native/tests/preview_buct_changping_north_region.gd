extends SceneTree
## Native frames of one continuous physical trip from the real spawn.
## The unrecorded approach and recorded route both use production navigation.
var campus:Node2D
var out:=""
var trace:Array=[]
var checks:=0
var failures:Array[String]=[]
var illegal_ticks:=0
var physics_ticks:=0
var maximum_speed:=0.0
var recording:=false
var path_targets:Dictionary={}
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func monitor_physics()->void:
	if not is_instance_valid(campus) or not campus.initialized:return
	physics_ticks+=1
	if not campus.is_walkable(campus.visitor.position):illegal_ticks+=1
	maximum_speed=maxf(maximum_speed,campus.visitor.last_motion.length()*Engine.physics_ticks_per_second)
func render()->void:
	await process_frame
	campus.north_hd_region.update_actor_foot(campus.visitor.position.y)
	campus.wenli_layer.update_actor_foot(campus.visitor.position.y)
	await RenderingServer.frame_post_draw
func aim(point:Vector2,zoom:float)->void:
	campus.camera.position=point;campus.camera.zoom=Vector2.ONE*zoom;campus.camera.reset_smoothing();campus.camera.force_update_scroll()
func run()->void:
	out=OS.get_environment("BUCT_NORTH_QA_DIR").path_join("preview")
	DirAccess.make_dir_recursive_absolute(out.path_join("frames-jpeg"))
	root.size=Vector2i(1280,720)
	campus=load("res://campuses/buct_changping/scenes/playable.tscn").instantiate();root.add_child(campus)
	await process_frame;await physics_frame;await process_frame
	check(is_instance_valid(campus.north_hd_region),"Full default region is installed")
	if not is_instance_valid(campus.north_hd_region):finish();return
	physics_frame.connect(monitor_physics)
	var start:Vector2=campus.grid.get_point_position(campus.nearest_cell(Vector2(731,676)))
	path_targets["requested_start"]=[731,676];path_targets["actual_start_grid"]=[start.x,start.y]
	check(campus.path_to(start),"Production route connects real south spawn to preview start")
	var approach_frames:=0
	while campus.visitor.position.distance_to(start)>3.1 and approach_frames<1000:
		await process_frame;approach_frames+=1
	check(campus.visitor.position.distance_to(start)<=3.1,"Physical unrecorded approach arrives without position writes")
	if not failures.is_empty():finish();return
	campus.current_path.clear();campus.set_process(false)
	campus.camera.position_smoothing_enabled=false;campus.pin_layer.hide();campus.canopy_locator.hide()
	var banner:=Label.new();banner.add_theme_font_override("font",campus.font);banner.add_theme_font_size_override("font_size",20)
	banner.position=Vector2(20,82);campus.ui.add_child(banner)
	banner.text="两块连续高清区域 · 原生路线与学生 · 2.1×"
	aim(Vector2(727,600),2.1)
	var target:Vector2=campus.grid.get_point_position(campus.nearest_cell(Vector2(666,548)))
	path_targets["requested_north_junction"]=[666,548];path_targets["actual_north_grid"]=[target.x,target.y]
	check(campus.path_to(target),"Recorded northbound route exists")
	var arrived_frame:=-1
	var returned_frame:=-1
	var north_crossed:=false
	var south_crossed:=false
	var last_y:float=campus.visitor.position.y
	recording=true
	for index in range(240):
		var feet:Vector2=campus.visitor.position
		if last_y>=627 and feet.y<627:north_crossed=true
		if north_crossed and last_y<627 and feet.y>=627:south_crossed=true
		last_y=feet.y
		if arrived_frame<0 and feet.distance_to(target)<=3.1:
			arrived_frame=index;campus.current_path.clear()
			aim(Vector2(685,500),4.1);banner.text="北侧长灰楼 · 同一连续场景 · 4.1×"
		if arrived_frame>=0 and index==arrived_frame+55:
			aim(Vector2(727,600),2.1);banner.text="沿同一铺装路返回 · 共享带 y=627"
			check(campus.path_to(start),"Recorded physical return route exists")
		if arrived_frame>=0 and index>arrived_frame+55 and returned_frame<0 and feet.distance_to(start)<=3.1:
			returned_frame=index;campus.current_path.clear()
			banner.text="已连续往返 · 导览进度保持 0/3"
		await render()
		var screen:Vector2=campus.visitor.get_global_transform_with_canvas().origin
		check(screen.y>=88 and screen.y<=610,"Student feet remain outside HUD on frame %d"%index)
		root.get_texture().get_image().save_jpg(out.path_join("frames-jpeg/frame-%04d.jpg"%index),.92)
		trace.append({"frame":index,"feet":[campus.visitor.position.x,campus.visitor.position.y],"screen_feet":[screen.x,screen.y],"zoom":campus.camera.zoom.x,"walkable":campus.is_walkable(campus.visitor.position)})
	check(arrived_frame>=0 and returned_frame>=0,"Recorded actual outward and return arrivals both occur")
	check(north_crossed and south_crossed,"Actual feet cross shared y627 in both directions")
	check(illegal_ticks==0 and maximum_speed<=88.05,"All physical ticks stay paved and preserve speed88")
	check(campus.visited.is_empty(),"Preview creates no tour progress")
	campus.current_path.clear();campus.visitor.hide();campus.ui.hide();campus.pin_layer.hide();campus.route_visual.hide()
	# Shared World2D renders the actual production map into its exact native extent.
	var full:=SubViewport.new();full.size=Vector2i(950,1656);full.world_2d=campus.get_world_2d()
	full.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(full)
	var camera:=Camera2D.new();camera.position=Vector2(475,828);camera.zoom=Vector2.ONE;full.add_child(camera)
	await render();await render()
	var full_image:Image=full.get_texture().get_image()
	check(full_image.get_size()==Vector2i(950,1656),"Pure native full-map render uses source950x1656 extent")
	full_image.save_png(out.path_join("changping-full-map-native-950x1656.png"))
	full.queue_free();await process_frame
	finish()
func finish()->void:
	var f:=FileAccess.open(out.path_join("preview-native-result.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"production_path_targets":path_targets,"recorded_frames":trace.size(),"fixed_fps":20,"duration_seconds":12,"frame_format":"Godot Image.save_jpg quality0.92; pixel proofs and full map remain PNG","physical_ticks":physics_ticks,"illegal_ticks":illegal_ticks,"maximum_speed":maximum_speed,"position_writes_after_initial_spawn":0,"scope":"Automated continuous production navigation; manual entry is separately verified. Only two contiguous HD regions, remainder original artwork.","trace":trace},"  "));f.close()
	if is_instance_valid(campus):campus.queue_free()
	await process_frame;await process_frame
	print("BUCT_NORTH_PREVIEW checks=%d failures=%d"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
