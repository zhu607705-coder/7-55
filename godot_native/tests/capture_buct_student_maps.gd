extends SceneTree
## Real full-campus scene and original physics input. Segmented verification, not a tour.
var app: Node2D
var frames_written:=0
var capture_dir: String
var failures: Array[String]=[]
var title: Label
func _init() -> void:call_deferred("run")
func tick(count: int) -> void:
	for i in range(count):
		await physics_frame
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			if not capture_dir.is_empty():root.get_texture().get_image().save_jpg(capture_dir.path_join("%05d.jpg"%frames_written),0.94)
		frames_written+=1
func expect(value: bool,label: String) -> void:
	print("PASS " if value else "FAIL ",label)
	if not value:failures.append(label)
func run() -> void:
	capture_dir=OS.get_environment("BUCT_STUDENT_CAPTURE_DIR")
	if not capture_dir.is_empty():DirAccess.make_dir_recursive_absolute(capture_dir)
	root.size=Vector2i(1280,800)
	var campus:=OS.get_environment("BUCT_STUDENT_CAPTURE_CAMPUS")
	if campus not in ["buct","buct_haidian"]:campus="buct_haidian"
	var campus_label:="朝阳" if campus=="buct" else "海淀"
	app=load("res://campuses/"+campus+"/scenes/playable.tscn").instantiate();root.add_child(app)
	await physics_frame;await physics_frame
	if not is_instance_valid(app.visitor) or app.visitor.get_node_or_null("StudentVisual")==null:push_error("Actual student not attached");quit(1);return
	var overlay:=CanvasLayer.new();overlay.layer=20;root.add_child(overlay)
	title=Label.new();title.position=Vector2(20,70);title.add_theme_font_override("font",app.font);title.add_theme_font_size_override("font_size",22);title.add_theme_color_override("font_shadow_color",Color.BLACK);title.add_theme_constant_override("shadow_offset_x",2);title.add_theme_constant_override("shadow_offset_y",2);overlay.add_child(title)
	var visual=app.visitor.character_visual
	var segments: Array=[["right",Vector2(746,391),Vector2(806,413),"向右"],["left",Vector2(806,413),Vector2(746,391),"向左"],["up",Vector2(854,423),Vector2(912,337),"向上"],["down",Vector2(912,337),Vector2(854,423),"向下"]]
	if campus=="buct":segments=[["right",Vector2(717,815),Vector2(785,815),"向右"],["left",Vector2(785,815),Vector2(717,815),"向左"],["up",Vector2(744,945),Vector2(751,887),"向上"],["down",Vector2(751,887),Vector2(744,945),"向下"]]
	for item in segments:
		app.visitor.position=item[1];app.current_path.clear();app.guide_active=false;app.guide_pause=0;app.close_info()
		app.camera.position=app._walking_camera_position();app.camera.reset_smoothing();app.camera.force_update_scroll()
		title.text=campus_label+"正式全图 · 原生分段寻路 · "+str(item[3])+" / 停步"
		expect(app.is_walkable(item[1]) and app.is_walkable(item[2]),"Original walkable segment endpoints "+str(item[0]))
		await tick(10)
		expect(app.path_to(item[2]),"Original AStar route "+str(item[0]))
		var observed: Dictionary={};var poses: Dictionary={}
		for i in range(110):
			await tick(1)
			if visual.walking:observed[visual.frame_index]=true;poses[visual.facing]=true
		app.current_path.clear();await tick(2)
		var displacement: Vector2=app.visitor.position-item[1]
		expect(displacement.length()>20.0,"Actual displacement "+str(item[0])+" "+str(displacement))
		expect(observed.size()>1 and poses.has(item[0]),"Registered walking frames / primary facing "+str(item[0])+" frames="+str(observed.keys())+" poses="+str(poses.keys()))
		expect(not visual.walking,"Stopped actual controller renders idle "+str(item[0]))
		expect(app.is_walkable(app.visitor.position),"Rendered feet remain on original paving "+str(item[0]))
		await tick(28)
	print("BUCT_STUDENT_CAPTURE frames=",frames_written," actual_scene=",app.scene_file_path," artwork=",visual.sprite.texture!=null," errors=",failures)
	quit(0 if failures.is_empty() else 1)
