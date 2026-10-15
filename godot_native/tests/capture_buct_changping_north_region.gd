extends SceneTree
## Automated native static-frame proof. Controlled image fixtures are not manual play.
const REGION=preload("res://campuses/buct_changping/scripts/registered_hd_region.gd")
const ROAD=preload("res://campuses/buct_changping/scripts/north_road_extension.gd")
const WENLI=preload("res://campuses/buct_changping/scripts/wenli_hd_region.gd")
const BODY=preload("res://campuses/buct_changping/scripts/registered_hd_building.gd")
const PROFILE="res://campuses/buct_changping/data/north_hd_region.json"
var campus:Node2D
var out:=""
var checks:=0
var failures:Array[String]=[]
var records:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func frame()->void:
	await process_frame;await process_frame
	if is_instance_valid(campus):
		if is_instance_valid(campus.north_hd_region):
			campus.north_hd_region._process(0)
			campus.north_hd_region.update_actor_foot(campus.visitor.position.y)
		if is_instance_valid(campus.wenli_layer):campus.wenli_layer.update_actor_foot(campus.visitor.position.y,true)
	await RenderingServer.frame_post_draw
func shot(name:String)->Image:
	var image:=root.get_texture().get_image();image.convert(Image.FORMAT_RGBA8)
	if not name.is_empty():image.save_png(out.path_join(name+".png"))
	return image
func compare(a:Image,b:Image,tolerance:=0)->Dictionary:
	a.convert(Image.FORMAT_RGBA8);b.convert(Image.FORMAT_RGBA8)
	var aa:=a.get_data();var bb:=b.get_data();var changed:=0;var maximum:=0;var alpha_support:=0
	if aa.size()!=bb.size():return {"changed_pixels":-1,"max_channel_delta":255,"alpha_support_difference":-1}
	for i in range(0,aa.size(),4):
		var delta:=0
		for c in range(4):delta=maxi(delta,absi(int(aa[i+c])-int(bb[i+c])))
		if delta>tolerance:changed+=1
		maximum=maxi(maximum,delta)
		if (aa[i+3]>=10)!=(bb[i+3]>=10):alpha_support+=1
	return {"changed_pixels":changed,"max_channel_delta":maximum,"alpha_support_difference":alpha_support}
func camera_at(point:Vector2,zoom:float)->void:
	campus.camera.position=point;campus.camera.zoom=Vector2.ONE*zoom;campus.camera.reset_smoothing()
func reinstall_north()->void:
	campus.north_hd_region=REGION.install(campus,PROFILE)
	campus.north_road_extension=ROAD.install(campus)
	campus.walk_cells.clear();campus._build_grid()
func run()->void:
	out=OS.get_environment("BUCT_NORTH_QA_DIR").path_join("gpu")
	DirAccess.make_dir_recursive_absolute(out)
	root.size=Vector2i(1280,720)
	campus=load("res://campuses/buct_changping/scenes/playable.tscn").instantiate();root.add_child(campus);await frame()
	check(is_instance_valid(campus.north_hd_region),"Actual default scene installs north HD region")
	if not is_instance_valid(campus.north_hd_region):finish();return
	campus.set_process(false);campus.visitor.set_physics_process(false)
	campus.pin_layer.hide();campus.canopy_locator.hide();campus.camera.position_smoothing_enabled=false
	campus.visitor.position=Vector2(666,548)
	camera_at(Vector2(727,525),2.1);await frame();shot("01-default-north-2.1-context")
	camera_at(Vector2(681,489),4.8);await frame();shot("02-default-building-4.8")
	campus.show_landmark("north_sports_hall");await frame();shot("03-neutral-exterior-card");campus.close_info()
	campus.ui.hide();campus.visitor.hide()
	var body:Node2D=campus.north_hd_region.bodies.north_sports_hall
	body.hide();await frame();shot("04-hidden-body-source-removal-west-rim");body.show()
	camera_at(Vector2(750,626),4.8);await frame();var normal_seam:=shot("05-two-region-shared-seam")
	campus.wenli_hd_region.uninstall();campus.wenli_hd_region=null;await frame();shot("06-north-alone-fallback")
	campus.wenli_hd_region=WENLI.install(campus);await frame();var reordered:=shot("07-neighbor-reinstalled-seam")
	var order_delta:=compare(normal_seam,reordered)
	records.append({"fixture":"reversed_neighbor_install_order","comparison":order_delta})
	check(order_delta.max_channel_delta<=1,"Reversed neighbor installation has stable identical shared composite")
	camera_at(Vector2(475,828),.36);await frame();shot("08-whole-campus-partial-HD-context")
	camera_at(Vector2(725,525),2.1);await frame();var new_scene:=shot("09-default-no-actor")
	var north=campus.north_hd_region
	var leaves:Array= north.foliage_nodes.duplicate()
	for leaf in leaves:leaf.hide()
	await frame();var no_leaves:=shot("10-default-no-actor-without-new-foreground")
	var foreground_rgb:=compare(new_scene,no_leaves)
	records.append({"fixture":"all3_same_HD_RGB_no_actor","comparison":foreground_rgb})
	check(foreground_rgb.max_channel_delta<=1,"Three new canopy layers preserve default no-actor RGB within1LSB")
	for leaf in leaves:leaf.show()
	await frame()
	var transform:Transform2D=campus.get_canvas_transform().affine_inverse()
	north.uninstall();north=null;campus.north_hd_region=null;body=null;leaves.clear();await frame();var old_scene:=shot("11-legacy-identical-camera")
	var changed_outside:=0;var changed_inside:=0
	for y in range(new_scene.get_height()):
		for x in range(new_scene.get_width()):
			if new_scene.get_pixel(x,y)!=old_scene.get_pixel(x,y):
				if Rect2(630,399,240,240).has_point(transform*Vector2(x+.5,y+.5)):changed_inside+=1
				else:changed_outside+=1
	records.append({"fixture":"new_region_source_ownership","changed_inside":changed_inside,"changed_outside":changed_outside})
	check(changed_outside==0,"North enhancement changes no pixel outside its source ROI")
	check(changed_inside>50000,"Default region replaces substantial original region artwork")
	reinstall_north();await frame();north=campus.north_hd_region;body=north.bodies.north_sports_hall
	await prove_body(body)
	await prove_shared_source_independence(north)
	var probes=[{"id":"north_road_crown_01","behind":Vector2(679,568),"front":Vector2(681,572)},
		{"id":"north_road_crown_02","behind":Vector2(689,584),"front":Vector2(691,588)},
		{"id":"north_road_crown_03","behind":Vector2(701,609),"front":Vector2(703,613)}]
	for probe in probes:
		var leaf:Node2D=campus.objects.get_node(probe.id)
		var counts:Array[int]=[]
		for side in ["behind","front"]:
			var feet:Vector2=probe[side]
			check(campus.is_walkable(feet),"Canopy proof uses an actually legal foot position: "+probe.id+" "+side)
			campus.visitor.position=feet;campus.visitor.show();camera_at(feet+Vector2(0,-9),4.8)
			leaf.hide();await frame();var without:=shot("")
			leaf.show();await frame();var with:=shot("leaf_"+probe.id+"_"+side)
			counts.append(int(compare(without,with,1).changed_pixels))
		records.append({"fixture":"legal_road_foot_canopy_depth","id":probe.id,"behind_changed":counts[0],"front_changed":counts[1],"controlled_legal_pose_not_manual_walk":true})
		check(counts[0]>0 and counts[0]>counts[1],"Real student is occluded behind and revealed in front: "+probe.id)
	campus.visitor.position=Vector2(666,548);campus.ui.show();camera_at(Vector2(727,525),2.1);await frame();shot("16-final-default-normal-view")
	campus.queue_free();await process_frame;await process_frame;campus=null;finish()
func prove_body(body:Node2D)->void:
	var vp:=SubViewport.new();vp.size=Vector2i(960,540);vp.transparent_bg=true;vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(vp)
	var world:=Node2D.new();world.y_sort_enabled=true;vp.add_child(world)
	var source:=Sprite2D.new();source.centered=false;source.texture=campus.SOURCE;source.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;source.z_index=-1;world.add_child(source);source.hide()
	var camera:=Camera2D.new();camera.position=Vector2(680,488);camera.zoom=Vector2.ONE*4.8;world.add_child(camera)
	var isolated:=Node2D.new();isolated.set_script(BODY);world.add_child(isolated)
	check(isolated.configure(body.profile,body.body_texture),"Independent immutable body configures for whole-RGBA comparison")
	var reference:=Sprite2D.new();reference.centered=false;reference.texture=body.body_texture;reference.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var shader:=Shader.new();shader.code="shader_type canvas_item;render_mode unshaded,skip_vertex_transform;uniform vec2 origin;uniform vec2 raw_size;uniform float scale_value;uniform float rgb_lod;void vertex(){VERTEX=origin+UV*raw_size*scale_value;}void fragment(){vec4 c=textureLod(TEXTURE,UV,rgb_lod);c.a=textureLod(TEXTURE,UV,0.0).a;if(c.a<0.04){discard;}if(c.a>=0.97){c.a=1.0;}COLOR=c;}"
	var mat:=ShaderMaterial.new();mat.shader=shader;reference.material=mat
	mat.set_shader_parameter("origin",Vector2(body.profile.body_image_to_world.origin[0],body.profile.body_image_to_world.origin[1]))
	mat.set_shader_parameter("raw_size",Vector2(body.raw_size));mat.set_shader_parameter("scale_value",body.image_scale);world.add_child(reference)
	await frame();isolated.update_actor_foot(505,true);mat.set_shader_parameter("rgb_lod",isolated.get_diagnostics().rgb_lod)
	for opaque in [false,true]:
		source.visible=opaque;vp.transparent_bg=not opaque;reference.show();isolated.hide();await frame()
		var original:Image=vp.get_texture().get_image();original.convert(Image.FORMAT_RGBA8)
		original.save_png(out.path_join("12-whole-original-rgba-%s.png"%("opaque-source" if opaque else "true-alpha")))
		reference.hide();isolated.show()
		for foot in [450.,480.,505.,530.,548.]:
			isolated.update_actor_foot(foot,true);await frame()
			var actual:Image=vp.get_texture().get_image();actual.convert(Image.FORMAT_RGBA8)
			var comparison:=compare(original,actual)
			records.append({"fixture":"entire_rgba_common_quad_vs_original","opaque_original_background":opaque,"actor_foot_y":foot,"comparison":comparison,"active_passes":isolated.get_diagnostics().body_passes_active,"body_allocation":isolated.get_diagnostics()})
			check(comparison.max_channel_delta<=1 and comparison.alpha_support_difference==0,"Full original RGBA matches complementary passes at foot%.1f opaque=%s"%[foot,opaque])
			if foot==505:actual.save_png(out.path_join("13-two-pass-body-%s.png"%("opaque-source" if opaque else "true-alpha")))
	vp.queue_free();await frame()
func prove_shared_source_independence(north:Node2D)->void:
	var vp:=SubViewport.new();vp.size=Vector2i(1080,120);vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(vp)
	var owner:=Node2D.new();vp.add_child(owner)
	var copy:Sprite2D=north.ground_sprite.duplicate();copy.material=copy.material.duplicate();owner.add_child(copy)
	copy.material.set_shader_parameter("shared_neighbor_active",true)
	var camera:=Camera2D.new();camera.position=Vector2(750,627);camera.zoom=Vector2.ONE*5;owner.add_child(camera)
	await frame();var original:Image=vp.get_texture().get_image();original.convert(Image.FORMAT_RGBA8)
	original.save_png(out.path_join("14-shared-band-coordinated-HD-only.png"))
	var poison:=Image.create(1,1,false,Image.FORMAT_RGBA8);poison.fill(Color(1,0,1,1))
	copy.material.set_shader_parameter("original_source",ImageTexture.create_from_image(poison))
	await frame();var poisoned:Image=vp.get_texture().get_image();poisoned.convert(Image.FORMAT_RGBA8)
	poisoned.save_png(out.path_join("15-shared-band-magenta-source-probe.png"))
	var difference:=compare(original,poisoned)
	records.append({"fixture":"shared_core_no_low_resolution_residue","comparison":difference,"source_probe":"replace source sampler with opaque magenta"})
	check(difference.changed_pixels==0,"Entire216x24 shared core is independent of low-resolution source sampler")
	vp.queue_free();await frame()
func finish()->void:
	var file:=FileAccess.open(out.path_join("north-render-result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"records":records,"status":"automated_native_GPU_static_frames_only_not_manual_play","main_capture_size":[1280,720]},"  "));file.close()
	print("BUCT_NORTH_GPU checks=%d failures=%d"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
