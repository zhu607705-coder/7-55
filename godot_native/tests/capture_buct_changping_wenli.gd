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
	out = OS.get_environment("BUCT_WENLI_PROOF_DIR")
	if out.is_empty():out = ProjectSettings.globalize_path("user://changping-wenli-proof")
	DirAccess.make_dir_recursive_absolute(out)
	var campus = load("res://campuses/buct_changping/scenes/playable.tscn").instantiate()
	campus.enable_wenli_hd_region = false;campus.enable_north_hd_region = false # Isolated #138 object contract remains unchanged.
	root.add_child(campus)
	await frame()
	var body = campus.wenli_layer
	check(is_instance_valid(body), "Formal full-map installation succeeded")
	if not is_instance_valid(body):quit(1);return
	campus.set_process(false)
	check(body.get_diagnostics().production_has_mipmaps, "Production body Texture has actual mip chain")
	campus.visitor.set_physics_process(false)
	campus.pin_layer.hide()
	campus.visitor.position = Vector2(769,842)
	campus.camera.position_smoothing_enabled = false
	campus.camera.position = Vector2(710,788)
	campus.camera.reset_smoothing()
	campus.camera.zoom = Vector2.ONE*4.8
	body.update_actor_foot(842,true)
	await frame()
	root.get_texture().get_image().save_png(out.path_join("01-formal-wenli-normal.png"))
	body.hide();await frame()
	root.get_texture().get_image().save_png(out.path_join("01b-hidden-source-body-cleared.png"))
	body.show();await frame()
	campus.show_landmark("wenli_building");await frame()
	root.get_texture().get_image().save_png(out.path_join("02-wenli-alpha-selected.png"))
	campus.close_info();campus.set_process(false)
	campus.ui.hide();campus.pin_layer.hide();campus.canopy_locator.hide()
	# A small independent rendering surface shares the actual imported body texture.
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640,480);viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world := Node2D.new();world.y_sort_enabled = true;viewport.add_child(world)
	var isolated = Node2D.new()
	isolated.set_script(load("res://campuses/buct_changping/scripts/wenli_building.gd"))
	check(isolated.configure(body.profile,body.body_texture), "Five-field body can independently configure")
	world.add_child(isolated)
	var camera := Camera2D.new();camera.position = Vector2(709,788);camera.zoom=Vector2.ONE*3.5;world.add_child(camera)
	var reference := Sprite2D.new();reference.centered = false;reference.texture = body.body_texture
	reference.position = Vector2(body.profile.body_image_to_world.origin[0],body.profile.body_image_to_world.origin[1])
	reference.scale = Vector2.ONE*body.image_scale
	reference.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; render_mode unshaded, skip_vertex_transform; uniform vec2 source_world_origin; uniform vec2 raw_size; uniform float world_scale; uniform float rgb_lod=0.0; void vertex(){VERTEX=source_world_origin+UV*raw_size*world_scale;} void fragment(){vec4 c=textureLod(TEXTURE,UV,rgb_lod); c.a=textureLod(TEXTURE,UV,0.0).a; if(c.a<0.04){discard;} if(c.a>=0.97){c.a=1.0;} COLOR=c;}"
	var mat := ShaderMaterial.new();mat.shader=shader;reference.material=mat;world.add_child(reference)
	isolated.hide();await frame()
	isolated.update_actor_foot(810,true)
	mat.set_shader_parameter("source_world_origin",reference.position)
	mat.set_shader_parameter("raw_size",body.body_texture.get_size())
	mat.set_shader_parameter("world_scale",body.image_scale)
	mat.set_shader_parameter("rgb_lod",float(isolated.get_diagnostics().rgb_lod))
	var implicit_shader := Shader.new()
	# Hold the source-space sampling lattice fixed while varying RGB filtering.
	# Mixing the engine's transformed sprite with skip_vertex_transform changes
	# edge interpolation on Mesa, independently of mip selection or body passes.
	implicit_shader.code = shader.code.replace("vec4 c=textureLod(TEXTURE,UV,rgb_lod);","vec4 c=texture(TEXTURE,UV);")
	var explicit_shader: Shader = mat.shader
	mat.shader = implicit_shader;await frame()
	var implicit_reference: Image = viewport.get_texture().get_image();implicit_reference.convert(Image.FORMAT_RGBA8)
	implicit_reference.save_png(out.path_join("03a-original-linear-mip-reference.png"))
	mat.shader = explicit_shader
	mat.set_shader_parameter("source_world_origin",reference.position)
	mat.set_shader_parameter("raw_size",body.body_texture.get_size())
	mat.set_shader_parameter("world_scale",body.image_scale)
	isolated.update_actor_foot(810,true)
	mat.set_shader_parameter("rgb_lod",float(isolated.get_diagnostics().rgb_lod))
	await frame()
	var standard_shader := Shader.new()
	standard_shader.code = "shader_type canvas_item;render_mode unshaded;uniform float rgb_lod=0.0;void fragment(){vec4 c=textureLod(TEXTURE,UV,rgb_lod);c.a=textureLod(TEXTURE,UV,0.0).a;if(c.a<0.04){discard;}if(c.a>=0.97){c.a=1.0;}COLOR=c;}"
	mat.shader = standard_shader;await frame()
	var standard_reference: Image = viewport.get_texture().get_image();standard_reference.convert(Image.FORMAT_RGBA8)
	standard_reference.save_png(out.path_join("03b-standard-sprite-explicit-lod-reference.png"))
	mat.shader = explicit_shader
	mat.set_shader_parameter("source_world_origin",reference.position)
	mat.set_shader_parameter("raw_size",body.body_texture.get_size())
	mat.set_shader_parameter("world_scale",body.image_scale)
	await frame()
	var target: Image = viewport.get_texture().get_image();target.convert(Image.FORMAT_RGBA8)
	target.save_png(out.path_join("03-whole-png-reference.png"))
	records.append({"fixture":"standard_sprite_vs_canonical_quad_same_lod","comparison":compare_images(standard_reference,target)})
	var filter_comparison := compare_images(implicit_reference,target)
	records.append({"fixture":"implicit_linear_vs_explicit_common_lod","comparison":filter_comparison,"common_lod":isolated.get_diagnostics().rgb_lod})
	check(filter_comparison.alpha_support_difference == 0,"Explicit common RGB LOD preserves original LOD0 alpha support")
	reference.hide();isolated.show()
	for foot in [770.0,790.0,810.0,830.0,845.0]:
		isolated.update_actor_foot(foot,true);await frame()
		var current: Image = viewport.get_texture().get_image();current.convert(Image.FORMAT_RGBA8)
		current.save_png(out.path_join("whole-png-foot-%d.png" % int(foot)))
		var comparison := compare_images(target,current)
		records.append({"fixture":"whole_png_vs_multiface","actor_foot_y":foot,"passes_active":isolated.get_diagnostics().body_passes_active,"rgb_lod":isolated.get_diagnostics().rgb_lod,"comparison":comparison})
		check(comparison.max_channel_delta <= 1, "Whole PNG equals all complementary face passes within1LSB")
		check(comparison.alpha_support_difference == 0, "No new alpha holes or duplicated edge support")
		if foot == 810:current.save_png(out.path_join("04-two-face-middle-depth.png"))
	await diagnose_opaque_composition(viewport,world,isolated,reference,campus.SOURCE,explicit_shader,body)
	await check_stationary_zoom(viewport,camera,isolated,reference,mat)
	await check_west_surface(viewport, world, isolated, campus.visitor, body.profile)
	viewport.queue_free();await frame()
	await check_source_ownership(campus,body)
	# Actual approved student at controlled fixture feet; these are NOT new routes.
	for probe in body.profile.semantic_depth_probes:
		var baseline: float = float(probe.world_foot_y)
		var counts: Array[int] = []
		for offset in [-1.0,1.0]:
			campus.visitor.position = Vector2(probe.world_x,baseline+offset)
			body.update_actor_foot(baseline+offset,true)
			campus.visitor.hide();await frame()
			var no_actor: Image = root.get_texture().get_image()
			campus.visitor.show();await frame()
			var with_actor: Image = root.get_texture().get_image()
			var feet: Vector2 = campus.get_canvas_transform()*campus.visitor.position
			var rect := Rect2i(Vector2i(feet-Vector2(24,46)),Vector2i(48,52))
			var diff := compare_images(no_actor.get_region(rect),with_actor.get_region(rect))
			counts.append(int(diff.changed_pixels))
			with_actor.save_png(out.path_join("student_%s_%s.png" % [str(probe.name),"back" if offset<0 else "front"]))
		records.append({"fixture":"actual_student_depth_no_route_change","name":probe.name,"surface_id":probe.surface_id,"back_visible_pixels":counts[0],"front_visible_pixels":counts[1]})
		if str(probe.name) == "west":
			# Full-scene visibility can remain hidden behind south wing. Preserve the real
			# counts above; exact west-face transition is tested separately, not presumed.
			pass
		else:
			check(counts[1]>counts[0], "Actual student is more visible in front of the correct wenli face: " + str(probe.name))
	campus.visitor.position=Vector2(769,842);body.update_actor_foot(842,true)
	campus.camera.position = Vector2(710,788)
	campus.camera.reset_smoothing()
	campus.ui.show();await frame()
	root.get_texture().get_image().save_png(out.path_join("05-final-normal-map.png"))
	var report := {"status":"automated_native_GPU_only","checks":checks,"failures":failures,"records":records,"offroute_fixtures_do_not_enable_navigation":true}
	var file := FileAccess.open(out.path_join("render-result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"));file=null
	campus.queue_free();await process_frame;await process_frame
	print("CHANGPING_WENLI_GPU checks=%d failures=%d"%[checks,failures.size()])
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

func check_source_ownership(campus: Node, body: Node) -> void:
	var vp := SubViewport.new();vp.size = Vector2i(109,110);vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS;root.add_child(vp)
	var owner := Node2D.new();owner.position = Vector2(-657,-735);vp.add_child(owner)
	var source := Sprite2D.new();source.centered = false;source.texture = campus.SOURCE
	source.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST;owner.add_child(source)
	var ground: Sprite2D = campus.world.get_node("WenliInferredGroundWithinOriginalBodyOnly").duplicate()
	owner.add_child(ground);ground.hide();await frame()
	var original: Image = vp.get_texture().get_image();original.convert(Image.FORMAT_RGBA8)
	ground.show();await frame()
	var repaired: Image = vp.get_texture().get_image();repaired.convert(Image.FORMAT_RGBA8)
	repaired.save_png(out.path_join("06-source-owned-ground-only.png"))
	var mask := FileAccess.get_file_as_bytes(str(body.profile.source_removal.path))
	var a := original.get_data();var b := repaired.get_data();var outside_changed := 0;var inside_changed := 0
	for i in range(mask.size()):
		var changed := false
		for k in range(3):
			if a[i*4+k] != b[i*4+k]:changed = true
		if changed:
			if mask[i] == 0:outside_changed += 1
			else:inside_changed += 1
	check(outside_changed == 0,"GPU ground changes zero original pixels outside exact source-body ownership")
	check(inside_changed > 7000,"GPU ground clears original body including central low roof")
	records.append({"fixture":"source_mask_ground_only","outside_owned_mask_changed":outside_changed,"owned_pixels_changed":inside_changed,"inferred_not_surveyed":true})
	vp.queue_free();await frame()

func check_west_surface(vp: SubViewport, world: Node2D, isolated: Node2D, visitor: CharacterBody2D, profile: Dictionary) -> void:
	# Exact production body and approved student; isolate one semantic face only
	# to avoid the correctly foreground south wing hiding this inner-wall fixture.
	var shader := Shader.new()
	shader.code = FileAccess.get_file_as_string("res://campuses/buct_changping/shaders/wenli_depth.gdshader").replace("if (face < 1 || face > surface_count)", "if (face != 2 || face < 1 || face > surface_count)")
	for sprite in isolated.body_passes:
		sprite.material.shader = shader
	var original_parent := visitor.get_parent()
	var original_position := visitor.position
	visitor.reparent(world,false)
	var probe: Dictionary = profile.semantic_depth_probes[1]
	var counts: Array[int] = []
	for offset in [-1.0,1.0]:
		visitor.position = Vector2(probe.world_x,float(probe.world_foot_y)+offset)
		isolated.update_actor_foot(visitor.position.y,true)
		visitor.hide();await frame()
		var without: Image = vp.get_texture().get_image()
		visitor.show();await frame()
		var with_student: Image = vp.get_texture().get_image()
		counts.append(int(compare_images(without,with_student).changed_pixels))
		with_student.save_png(out.path_join("west_isolated_%s.png" % ("back" if offset<0 else "front")))
	check(counts[1] > counts[0],"Isolated actual west-wing face reveals more of the same approved student in front")
	records.append({"fixture":"same_student_west_face_isolation","back_visible_pixels":counts[0],"front_visible_pixels":counts[1],"other_faces_removed_for_test_only":true})
	visitor.reparent(original_parent,false);visitor.position = original_position

func check_stationary_zoom(vp: SubViewport, camera: Camera2D, isolated: Node2D, reference: Sprite2D, mat: ShaderMaterial) -> void:
	var previous_lod: float = -1.0
	for zoom in [2.1,4.8]:
		camera.zoom = Vector2.ONE * zoom;await frame()
		isolated.update_actor_foot(810,false)
		var lod: float = isolated.get_diagnostics().rgb_lod
		check(absf(lod-previous_lod)>0.01,"Stationary-actor zoom change updates common RGB LOD")
		previous_lod = lod
		mat.set_shader_parameter("rgb_lod",lod)
		isolated.hide();reference.show();await frame()
		var expected: Image = vp.get_texture().get_image()
		reference.hide();isolated.show();await frame()
		var actual: Image = vp.get_texture().get_image()
		var comparison := compare_images(expected,actual)
		expected.save_png(out.path_join("stationary_zoom_%.1f_reference.png" % zoom))
		actual.save_png(out.path_join("stationary_zoom_%.1f_actual.png" % zoom))
		check(comparison.max_channel_delta<=1 and comparison.alpha_support_difference==0,"Whole-PNG equality at stationary zoom " + str(zoom))
		records.append({"fixture":"stationary_zoom","zoom":zoom,"rgb_lod":lod,"comparison":comparison})
	camera.zoom = Vector2.ONE*3.5;await frame()
	isolated.update_actor_foot(810,false)

func diagnose_opaque_composition(vp: SubViewport, world: Node2D, isolated: Node2D, reference: Sprite2D, source_texture: Texture2D, canonical_shader: Shader, body: Node2D) -> void:
	vp.transparent_bg = false
	var mat: ShaderMaterial = reference.material
	# The independent whole-PNG reference and production face passes use the
	# same canonical quad. Standard-sprite differences stay in the record above.
	mat.shader = canonical_shader
	var backdrop := Sprite2D.new();backdrop.centered = false;backdrop.texture = source_texture
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST;backdrop.z_index = -4096
	world.add_child(backdrop)
	for source_background in [false,true]:
		backdrop.visible = source_background
		for foot in [770.0,845.0]:
			isolated.update_actor_foot(foot,true)
			isolated.hide();reference.show();await frame()
			var expected: Image = vp.get_texture().get_image()
			reference.hide();isolated.show();await frame()
			var actual: Image = vp.get_texture().get_image()
			var comparison := compare_images(expected,actual)
			var kind := "map" if source_background else "opaque"
			expected.save_png(out.path_join("composite_%s_%d_reference.png"%[kind,int(foot)]))
			actual.save_png(out.path_join("composite_%s_%d_actual.png"%[kind,int(foot)]))
			records.append({"fixture":"native_opaque_composite","background":kind,"actor_foot_y":foot,"comparison":comparison})
			check(comparison.max_channel_delta <= 1,"Whole PNG versus body passes on actual opaque " + kind + " background")
	backdrop.queue_free();vp.transparent_bg = true
	mat.shader = canonical_shader
	mat.set_shader_parameter("source_world_origin",reference.position)
	mat.set_shader_parameter("raw_size",body.body_texture.get_size())
	mat.set_shader_parameter("world_scale",body.image_scale)
	await frame()
