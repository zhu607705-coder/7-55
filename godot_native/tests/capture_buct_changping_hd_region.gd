extends SceneTree
## GPU proof of the actual default scene, shared foliage RGB and exact outer ownership.
const HD = preload("res://campuses/buct_changping/scripts/wenli_hd_region.gd")
var checks := 0
var failures: Array[String] = []
var records: Array = []
var out := ""
var campus: Node2D
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label);push_error(label)
func frame() -> void:
	await process_frame;await process_frame
	if is_instance_valid(campus) and is_instance_valid(campus.wenli_layer): campus.wenli_layer.update_actor_foot(campus.visitor.position.y,true)
	await RenderingServer.frame_post_draw
func shot(name: String) -> Image:
	var img := root.get_texture().get_image();img.convert(Image.FORMAT_RGBA8)
	if not name.is_empty(): img.save_png(out.path_join(name+".png"))
	return img
func freeze(node: Node) -> void:
	node.set_process(false)
	for child in node.get_children(): freeze(child)
func compare(a: Image,b: Image) -> Dictionary:
	var aa := a.get_data();var bb := b.get_data();var count := 0;var max_delta := 0
	for i in range(0,aa.size(),4):
		var delta := 0
		for c in range(3): delta=maxi(delta,absi(int(aa[i+c])-int(bb[i+c])))
		if delta > 0: count += 1
		max_delta=maxi(delta,max_delta)
	return {"changed_pixels":count,"max_rgb_delta":max_delta}
func _run() -> void:
	out=OS.get_environment("BUCT_HD_QA_DIR").path_join("gpu");DirAccess.make_dir_recursive_absolute(out)
	campus = load("res://campuses/buct_changping/scenes/playable.tscn").instantiate()
	root.add_child(campus);await frame()
	check(is_instance_valid(campus.wenli_hd_region),"Actual default scene installs enhanced region")
	if not is_instance_valid(campus.wenli_hd_region): finish();return
	freeze(campus);campus.visitor.set_physics_process(false)
	campus.pin_layer.hide();campus.canopy_locator.hide()
	campus.camera.position_smoothing_enabled=false
	campus.camera.position=Vector2(750,750);campus.camera.zoom=Vector2.ONE*2.1;campus.camera.reset_smoothing()
	campus.visitor.position=Vector2(758,756);campus.wenli_layer.update_actor_foot(756,true)
	await frame();shot("01-default-2.1-context-four-boundaries");record_lod(2.1)
	campus.camera.position=Vector2(710,788);campus.camera.zoom=Vector2.ONE*4.8
	await frame();shot("02-default-4.8-building-ground");record_lod(4.8)
	campus.wenli_layer.hide();campus.wenli_hd_region._process(0);await frame();shot("03-hidden-body-no-old-body-or-shadow")
	campus.wenli_layer.show();campus.wenli_hd_region._process(0)
	campus.ui.hide();campus.visitor.hide()
	var sprites: Array[Sprite2D] = []
	for row in campus.wenli_hd_region.leaf_restore: sprites.append(row.sprite)
	campus.camera.position=Vector2(750,750);campus.camera.zoom=Vector2.ONE*2.1
	await frame();var physical_with_leaves:=shot("fullscene-noactor-with-leaves")
	for sprite in sprites:sprite.hide()
	await frame();var physical_without_leaves:=shot("fullscene-noactor-without-leaves")
	records.append({"fixture":"full_scene_inherited_filter_sampling_diagnostic","comparison":compare(physical_with_leaves,physical_without_leaves)})
	for sprite in sprites:sprite.show()
	# Independent whole-ROI render proves RGB identity without confusing correct
	# leaf-over-building occlusion with a texture mismatch. Both zooms include all9.
	var vp:=SubViewport.new();vp.size=Vector2i(1240,1240);vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(vp)
	var owner:=Node2D.new();vp.add_child(owner)
	var source:=Sprite2D.new();source.centered=false;source.texture=campus.SOURCE;source.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;owner.add_child(source)
	var ground:Sprite2D=campus.wenli_hd_region.ground_sprite.duplicate();owner.add_child(ground)
	var copies:Array[Sprite2D]=[]
	for sprite in sprites:
		var copy:Sprite2D=sprite.duplicate();copy.position=sprite.global_position;owner.add_child(copy);copies.append(copy)
	var camera:=Camera2D.new();camera.position=Vector2(750,737);owner.add_child(camera)
	for zoom in [2.1,4.8]:
		camera.zoom=Vector2.ONE*zoom
		await frame();var with_leaves:Image=vp.get_texture().get_image();with_leaves.convert(Image.FORMAT_RGBA8)
		with_leaves.save_png(out.path_join("leaf-shared-rgb-%.1f.png"%zoom))
		for copy in copies:copy.hide()
		await frame();var without_leaves:Image=vp.get_texture().get_image();without_leaves.convert(Image.FORMAT_RGBA8)
		without_leaves.save_png(out.path_join("leaf-underlying-only-%.1f.png"%zoom))
		var comparison:=compare(with_leaves,without_leaves)
		records.append({"fixture":"all9_isolated_same_final_texels_leaf_overlay","zoom":zoom,"comparison":comparison,"includes17_original_pixels_outside_roi":true})
		check(comparison.max_rgb_delta<=1,"All9 isolated no-actor leaf overlays equal final ground within1LSB at zoom"+str(zoom))
		for copy in copies:copy.show()
	owner.queue_free();vp.queue_free();await frame()
	campus.camera.position=Vector2(750,750);campus.camera.zoom=Vector2.ONE*2.1
	await frame();var enhanced:=shot("04-enhanced-no-actor")
	campus.wenli_hd_region.uninstall();campus.wenli_hd_region=null
	await frame();var legacy:=shot("05-legacy-same-camera")
	var transform: Transform2D = campus.get_canvas_transform().affine_inverse()
	var outside_changed:=0;var inside_changed:=0
	for y in range(enhanced.get_height()):
		for x in range(enhanced.get_width()):
			if enhanced.get_pixel(x,y)!=legacy.get_pixel(x,y):
				if HD.REGION.has_point(transform*Vector2(x+0.5,y+0.5)):inside_changed+=1
				else:outside_changed+=1
	check(outside_changed==0,"Entire default scene changes zero RGB pixels outside240-source-pixel ROI")
	check(inside_changed>50000,"Actual default region replaces substantial original art")
	records.append({"fixture":"default_region_exact_outer_ownership","outside_changed":outside_changed,"inside_changed":inside_changed,"body_lod_at2_1":campus.wenli_layer.get_diagnostics().rgb_lod})
	campus.wenli_hd_region=HD.install(campus)
	for spec in campus.wenli_hd_region.profile.foreground:
		var leaf=campus.east_road_extension.get_node(str(spec.id))
		var sprite: Sprite2D=leaf.get_node("ExactOriginalLeafPixels")
		var x:float=float(spec.bbox_xywh[0])+float(spec.bbox_xywh[2])*0.5
		var base:float=float(spec.baseline_y)
		campus.camera.position=Vector2(x,base-6);campus.camera.zoom=Vector2.ONE*4.8
		var occluded: Array[int]=[]
		for offset in [-1.0,1.0]:
			campus.visitor.position=Vector2(x,base+offset);campus.wenli_layer.update_actor_foot(base+offset,true)
			campus.visitor.show();sprite.hide();await frame();var no_leaf:=shot("")
			sprite.show();await frame();var with_leaf:=shot("student_%s_%s"%[spec.id,"behind" if offset<0 else "front"])
			occluded.append(int(compare(no_leaf,with_leaf).changed_pixels))
		records.append({"fixture":"actual_student_original_leaf_footline","id":spec.id,"baseline_y":base,"behind_leaf_changed":occluded[0],"front_leaf_changed":occluded[1],"off_route_fixture":true})
		check(occluded[0]>occluded[1],"Original leaf depth reveals approved student in front: "+str(spec.id))
	campus.queue_free();await frame();finish()
func finish() -> void:
	var file:=FileAccess.open(out.path_join("render-result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"records":records,"status":"automated_native_GPU_not_manual_play"},"\t"));file.close()
	print("BUCT_HD_REGION_GPU checks=%d failures=%d"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func record_lod(zoom: float) -> void:
	var scale:float=campus.wenli_layer.get_canvas_transform().get_scale().x
	var lod:float=campus.wenli_layer.get_diagnostics().rgb_lod
	var expected:float=maxf(0.0,log(1.0/(scale*campus.wenli_layer.image_scale))/log(2.0))
	check(absf(lod-expected)<0.00001,"Actual building LOD matches settled canvas at zoom"+str(zoom))
	records.append({"fixture":"settled_actual_canvas_body_lod","requested_zoom":zoom,"actual_canvas_scale":scale,"rgb_lod":lod,"expected_lod":expected})
