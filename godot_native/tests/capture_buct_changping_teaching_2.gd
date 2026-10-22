extends SceneTree
## Isolated native whole-RGBA reconstruction proof, not manual gameplay.
const BODY = preload("res://campuses/buct_changping/scripts/registered_hd_building.gd")
const PROFILE = "res://campuses/buct_changping/data/teaching_2_registration.json"
var checks := 0
var failures: Array[String] = []
var records: Array = []
var output := ""
func _initialize() -> void: run.call_deferred()
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)
		push_error(label)
func frame() -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
func compare(a: Image, b: Image) -> Dictionary:
	a.convert(Image.FORMAT_RGBA8)
	b.convert(Image.FORMAT_RGBA8)
	var aa := a.get_data()
	var bb := b.get_data()
	var changed := 0
	var maximum := 0
	var alpha_support := 0
	for i in range(0, aa.size(), 4):
		var delta := 0
		for c in range(4): delta = maxi(delta, absi(int(aa[i+c])-int(bb[i+c])))
		if delta > 0: changed += 1
		maximum = maxi(maximum, delta)
		if (aa[i+3]>=10) != (bb[i+3]>=10): alpha_support += 1
	return {"changed_pixels":changed,"max_channel_delta":maximum,"alpha_support_difference":alpha_support}
func run() -> void:
	output = OS.get_environment("BUCT_WEST_QA_DIR").path_join("body_gpu")
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280,720)
	var profile: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PROFILE))
	var texture: Texture2D = load(str(profile.body_asset))
	check(texture != null and texture.get_image().has_mipmaps(), "Original teaching body imports with mipmaps")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280,720)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world := Node2D.new()
	world.y_sort_enabled = true
	viewport.add_child(world)
	var source := Sprite2D.new()
	source.centered = false
	source.texture = load("res://campuses/buct_changping/assets/approved-changping.png")
	source.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	source.z_index = -1
	world.add_child(source)
	var camera := Camera2D.new()
	camera.position = Vector2(468,660)
	camera.zoom = Vector2.ONE * 4.8
	world.add_child(camera)
	var body := Node2D.new()
	body.set_script(BODY)
	world.add_child(body)
	if not body.configure(profile, texture):
		check(false,"Whole teaching body configures")
		finish()
		return
	check(true,"Whole teaching body configures with five semantic surfaces")
	check(body.surface_count==5 and body.source_anchor==Vector2(468,720),"Five surfaces and original anchor are retained")
	for point in profile.transparent_probes_source_xy:
		check(not body.hit_test_alpha(Vector2(point[0],point[1])),"Courtyard/exterior remains transparent at %s"%str(point))
	for point in profile.opaque_probes_source_xy:
		check(body.hit_test_alpha(Vector2(point[0],point[1])),"Roof, facade or connector remains solid at %s"%str(point))
	var reference := Sprite2D.new()
	reference.centered = false
	reference.texture = texture
	reference.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;render_mode unshaded,skip_vertex_transform;uniform vec2 origin;uniform vec2 raw_size;uniform float scale_value;uniform float rgb_lod;void vertex(){VERTEX=origin+UV*raw_size*scale_value;}void fragment(){vec4 c=textureLod(TEXTURE,UV,rgb_lod);c.a=textureLod(TEXTURE,UV,0.0).a;if(c.a<0.04){discard;}if(c.a>=0.97){c.a=1.0;}COLOR=c;}"
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("origin",Vector2(profile.body_image_to_world.origin[0],profile.body_image_to_world.origin[1]))
	material.set_shader_parameter("raw_size",Vector2(body.raw_size))
	material.set_shader_parameter("scale_value",body.image_scale)
	reference.material = material
	world.add_child(reference)
	await frame()
	body.update_actor_foot(680,true)
	material.set_shader_parameter("rgb_lod",body.get_diagnostics().rgb_lod)
	for opaque in [false,true]:
		source.visible = opaque
		viewport.transparent_bg = not opaque
		reference.show()
		body.hide()
		await frame()
		var original: Image = viewport.get_texture().get_image()
		original.save_png(output.path_join("whole-original-%s.png"%str(opaque)))
		reference.hide()
		body.show()
		for foot in [610.0,640.0,660.0,680.0,700.0,725.0]:
			body.update_actor_foot(foot,true)
			await frame()
			var actual: Image = viewport.get_texture().get_image()
			var difference := compare(original,actual)
			records.append({"fixture":"whole_teaching_RGBA_vs_complementary_common_quads","opaque_source_background":opaque,"foot_y":foot,"comparison":difference,"diagnostics":body.get_diagnostics()})
			check(difference.max_channel_delta<=1 and difference.alpha_support_difference==0,"Whole RGBA reconstructs at foot%.1f background=%s"%[foot,opaque])
			if foot==680.0: actual.save_png(output.path_join("five-surfaces-%s.png"%str(opaque)))
	viewport.queue_free()
	await process_frame
	await process_frame
	finish()
func finish() -> void:
	var file := FileAccess.open(output.path_join("teaching-2-native-gpu-result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"records":records,"status":"isolated_native_GPU_proof_not_manual_gameplay"},"  "))
	file.close()
	print("BUCT_TEACHING_2_GPU checks=%d failures=%d"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
