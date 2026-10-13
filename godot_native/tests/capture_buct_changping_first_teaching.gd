extends SceneTree
## Automated native proof, never a claim of manual play or new courtyard access.
var failures: Array[String] = []
var checks := 0
var records: Array = []
var out := ""
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label);push_error(label)
func frame() -> void:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
func _run() -> void:
	out = OS.get_environment("BUCT_CHANGPING_PROOF_DIR")
	if out.is_empty():out = ProjectSettings.globalize_path("user://first-teaching-proof")
	DirAccess.make_dir_recursive_absolute(out)
	var campus = load("res://campuses/buct_changping/scenes/playable.tscn").instantiate()
	root.add_child(campus)
	await frame()
	var body = campus.first_teaching_layer
	check(is_instance_valid(body), "Formal full-map installation succeeded")
	if not is_instance_valid(body):quit(1);return
	check(body.get_diagnostics().production_has_mipmaps, "Production body Texture has actual mip chain")
	campus.visitor.set_physics_process(false)
	campus.visitor.position = Vector2(517,1210)
	campus.camera.position_smoothing_enabled = false
	campus.camera.position = campus._walking_camera_position()
	campus.camera.reset_smoothing()
	campus.camera.zoom = Vector2.ONE*campus._walking_zoom()
	body.update_actor_foot(1210,true)
	await frame()
	root.get_texture().get_image().save_png(out.path_join("01-formal-first-teaching-normal.png"))
	campus.show_landmark("main_building");await frame()
	root.get_texture().get_image().save_png(out.path_join("02-first-teaching-alpha-selected.png"))
	campus.close_info();campus.set_process(false)
	campus.ui.hide();campus.pin_layer.hide();campus.canopy_locator.hide()
	# A small independent rendering surface shares the actual imported body texture.
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640,480);viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world := Node2D.new();world.y_sort_enabled = true;viewport.add_child(world)
	var isolated = Node2D.new()
	isolated.set_script(load("res://campuses/buct_changping/scripts/first_teaching_building.gd"))
	check(isolated.configure(body.profile,body.body_texture), "Three-field body can independently configure")
	world.add_child(isolated)
	var camera := Camera2D.new();camera.position = Vector2(520,1150);camera.zoom=Vector2.ONE*2.1;world.add_child(camera)
	var reference := Sprite2D.new();reference.centered = false;reference.texture = body.body_texture
	reference.position = Vector2(body.profile.body_image_to_world.origin[0],body.profile.body_image_to_world.origin[1])
	reference.scale = Vector2.ONE*body.image_scale
	reference.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; render_mode unshaded; void fragment(){vec4 c=texture(TEXTURE,UV); c.a=textureLod(TEXTURE,UV,0.0).a; if(c.a<0.04){discard;} if(c.a>=0.97){c.a=1.0;} COLOR=c;}"
	var mat := ShaderMaterial.new();mat.shader=shader;reference.material=mat;world.add_child(reference)
	isolated.hide();await frame()
	var target: Image = viewport.get_texture().get_image();target.convert(Image.FORMAT_RGBA8)
	target.save_png(out.path_join("03-whole-png-reference.png"));reference.hide();isolated.show()
	for foot in [1130.0,1160.0,1205.0]:
		isolated.update_actor_foot(foot,true);await frame()
		var current: Image = viewport.get_texture().get_image();current.convert(Image.FORMAT_RGBA8)
		var comparison := compare_images(target,current)
		records.append({"fixture":"whole_png_vs_multiface","actor_foot_y":foot,"comparison":comparison})
		check(comparison.max_channel_delta <= 1, "Whole PNG equals all complementary face passes within1LSB")
		check(comparison.alpha_support_difference == 0, "No new alpha holes or duplicated edge support")
		if foot == 1160:current.save_png(out.path_join("04-three-face-middle-depth.png"))
	viewport.queue_free();await frame()
	# Actual approved student at controlled fixture feet; these are NOT new routes.
	for pair in body.profile.semantic_probe_pairs:
		for mass in ["rear","front"]:
			var baseline: float = pair.rear_world_foot if mass == "rear" else pair.front_world_foot
			var counts: Array[int] = []
			for offset in [-1.0,1.0]:
				campus.visitor.position = Vector2(pair.world_x,baseline+offset)
				body.update_actor_foot(baseline+offset,true)
				campus.visitor.hide();await frame()
				var no_actor: Image = root.get_texture().get_image()
				campus.visitor.show();await frame()
				var with_actor: Image = root.get_texture().get_image()
				var feet: Vector2 = campus.get_canvas_transform()*campus.visitor.position
				var rect := Rect2i(Vector2i(feet-Vector2(24,46)),Vector2i(48,52))
				var diff := compare_images(no_actor.get_region(rect),with_actor.get_region(rect))
				counts.append(int(diff.changed_pixels))
				with_actor.save_png(out.path_join("student_%s_x%d_%s.png" % [mass,int(pair.raw_x),"back" if offset<0 else "front"]))
			records.append({"fixture":"actual_student_depth_no_route_change","raw_x":pair.raw_x,"mass":mass,"back_visible_pixels":counts[0],"front_visible_pixels":counts[1]})
			check(counts[1]>counts[0], "Actual student is more visible in front of the correct face")
	campus.visitor.position=Vector2(517,1210);body.update_actor_foot(1210,true)
	campus.camera.position = campus._walking_camera_position()
	campus.camera.reset_smoothing()
	campus.set_process(true)
	campus.ui.show();campus.pin_layer.show();await frame()
	root.get_texture().get_image().save_png(out.path_join("05-final-normal-map.png"))
	var report := {"status":"automated_native_GPU_only","checks":checks,"failures":failures,"records":records,"courtyard_fixtures_do_not_enable_navigation":true}
	var file := FileAccess.open(out.path_join("render-result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"));file=null
	campus.queue_free();await process_frame;await process_frame
	print("CHANGPING_FIRST_TEACHING_GPU checks=%d failures=%d"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
func compare_images(a: Image,b: Image) -> Dictionary:
	a.convert(Image.FORMAT_RGBA8);b.convert(Image.FORMAT_RGBA8)
	var aa := a.get_data();var bb := b.get_data();var changed:=0;var max_delta:=0;var alpha_support:=0
	if aa.size()!=bb.size():return {"changed_pixels":-1,"max_channel_delta":255,"alpha_support_difference":-1}
	for i in range(0,aa.size(),4):
		var delta:=0
		for c in range(4):delta=maxi(delta,absi(int(aa[i+c])-int(bb[i+c])))
		if delta>0:changed+=1
		max_delta=maxi(max_delta,delta)
		if (aa[i+3]>=10)!=(bb[i+3]>=10):alpha_support+=1
	return {"changed_pixels":changed,"max_channel_delta":max_delta,"alpha_support_difference":alpha_support}
