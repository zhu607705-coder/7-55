extends SceneTree
## Actual-renderer controlled fixtures, separate from subsequent manual walking QA.
const REGION=preload("res://campuses/buct_changping/scripts/registered_hd_region.gd")
const ROAD=preload("res://campuses/buct_changping/scripts/north_road_extension.gd")
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
		for r in campus.west_hd_regions:
			if is_instance_valid(r):r._process(0);r.update_actor_foot(campus.visitor.position.y)
	await RenderingServer.frame_post_draw
func shot(name:String)->Image:
	var image=root.get_texture().get_image();image.convert(Image.FORMAT_RGBA8)
	if not name.is_empty():image.save_png(out.path_join(name+".png"))
	return image
func compare(a:Image,b:Image,tolerance:=0)->Dictionary:
	a.convert(Image.FORMAT_RGBA8);b.convert(Image.FORMAT_RGBA8)
	var aa=a.get_data();var bb=b.get_data();var changed:=0;var maximum:=0
	if aa.size()!=bb.size():return {"changed_pixels":-1,"max_channel_delta":255}
	for i in range(0,aa.size(),4):
		var delta:=0
		for c in range(4):delta=maxi(delta,absi(int(aa[i+c])-int(bb[i+c])))
		if delta>tolerance:changed+=1
		maximum=maxi(maximum,delta)
	return {"changed_pixels":changed,"max_channel_delta":maximum}
func camera_at(point:Vector2,zoom:float)->void:
	campus.camera.position=point;campus.camera.zoom=Vector2.ONE*zoom;campus.camera.reset_smoothing()
func run()->void:
	out=OS.get_environment("BUCT_WEST_QA_DIR").path_join("group_gpu");DirAccess.make_dir_recursive_absolute(out);root.size=Vector2i(1280,720)
	campus=load("res://campuses/buct_changping/scenes/playable.tscn").instantiate();campus.enable_west_hd_regions=true;root.add_child(campus);await frame()
	check(campus.west_hd_regions.size()==2,"Production scene installs both complete western regions")
	if campus.west_hd_regions.size()!=2:finish();return
	campus.set_process(false);campus.visitor.set_physics_process(false);campus.pin_layer.hide();campus.canopy_locator.hide();campus.camera.position_smoothing_enabled=false
	campus.lake_surface.set_process(false);campus.lake_surface.set_animation_enabled(false)
	var nw=campus.west_hd_regions[0];var sw=campus.west_hd_regions[1];var body=nw.bodies.teaching_2
	campus.visitor.hide();campus.ui.hide()
	for zoom in [2.1,4.8]:
		camera_at(Vector2(526,630),zoom);await frame();shot("01-four-region-teaching-context-%.1f"%zoom)
		camera_at(Vector2(639,627),zoom);await frame();shot("02-four-way-corner-%.1f"%zoom)
		camera_at(Vector2(560,641),zoom);await frame();shot("02b-north-path-1.21px-review-exception-%.1f"%zoom)
		camera_at(Vector2(507,792),zoom);await frame();shot("03-library-lake-static-%.1f"%zoom)
	camera_at(Vector2(468,658),4.8);await frame();shot("04-whole-teaching-two-open-courtyards")
	body.hide();campus.library_layer.hide();await frame();shot("05-hidden-bodies-HD-only-ground")
	# Independent legacy owners are individually poisoned, not only source-ground.
	var changed_materials:Array=[]
	for name in ["CleanUnderlay_library","CleanUnderlay_teaching_2","StaticSourceGroundShadows/library_GroundShadow_1","StaticSourceGroundShadows/teaching_2_GroundShadow_1"]:
		var item=campus.world.get_node(name);changed_materials.append([item,item.color,item.texture]);item.texture=null;item.color=Color.MAGENTA
	camera_at(Vector2(565,758),4.8);await frame();var poisoned_old=shot("06-old-library-owners-poisoned")
	for row in changed_materials:row[0].color=row[1];row[0].texture=row[2]
	await frame();var restored_old=shot("07-old-library-owners-restored")
	var olddelta=compare(poisoned_old,restored_old);records.append({"fixture":"independent_legacy_library_ground_owner_poison","comparison":olddelta});check(olddelta.changed_pixels==0,"Old library/teaching underlays and source-RGB shadows contribute no pixels")
	body.show();campus.library_layer.show();await frame()
	camera_at(Vector2(639,627),4.8);await frame();var ordered=shot("08-corner-normal-order")
	campus.north_hd_region.uninstall();campus.north_hd_region=null;await frame();shot("09-NE-missing-NW-court-remains")
	camera_at(Vector2(641,416),4.8);await frame();shot("10-protected-court-NE-missing")
	await prove_core(nw,sw,"NE-absent")
	campus.north_hd_region=REGION.install(campus,"res://campuses/buct_changping/data/north_hd_region.json");campus.north_road_extension=ROAD.install(campus)
	await frame();camera_at(Vector2(639,627),4.8);await frame();var reverse=shot("11-corner-NE-reinstalled-after-pair")
	var orderdelta=compare(ordered,reverse);records.append({"fixture":"reversed_NE_install","comparison":orderdelta});check(orderdelta.max_channel_delta<=1,"Reverse neighbor installation preserves four-way composite")
	await prove_core(nw,sw,"all-neighbors")
	# Same-HD canopy restorations must not change unoccupied terrain appearance.
	camera_at(Vector2(563,830),4.8);await frame();var withleaf=shot("12-road-crowns-without-actor")
	for leaf in sw.foliage_nodes:leaf.hide()
	await frame();var noleaf=shot("");var leafdelta=compare(withleaf,noleaf);records.append({"fixture":"no_actor_three_leaf_RGB","comparison":leafdelta});check(leafdelta.max_channel_delta<=1,"New crowns preserve same-HD RGB without actor")
	for leaf in sw.foliage_nodes:leaf.show()
	var probes=[{"id":"west_library_approach_crown_01","behind":Vector2(560,823),"front":Vector2(562,827)},{"id":"west_library_approach_crown_02","behind":Vector2(562,836),"front":Vector2(563,840)},{"id":"west_library_approach_crown_03","behind":Vector2(566,832),"front":Vector2(566,836)}]
	for probe in probes:
		var leaf=campus.objects.get_node(probe.id);var counts:Array=[]
		for side in ["behind","front"]:
			var foot:Vector2=probe[side];check(campus.is_walkable(foot),"Canopy pose lies on existing legal paving: "+probe.id+" "+side)
			campus.visitor.position=foot;campus.visitor.show();camera_at(foot+Vector2(0,-9),4.8);leaf.hide();await frame();var absent=shot("");leaf.show();await frame();var present=shot("canopy-"+probe.id+"-"+side);counts.append(compare(absent,present,1).changed_pixels)
		records.append({"fixture":"legal_crown_depth","id":probe.id,"behind":counts[0],"front":counts[1]});check(counts[0]>0 and counts[0]>counts[1],"Crown covers only student behind baseline: "+probe.id)
	campus.visitor.hide();camera_at(Vector2(430,794),4.8)
	campus.lake_surface.set_animation_enabled(false);await frame();var still=shot("13-lake-HD-static")
	campus.lake_surface.set_animation_enabled(true);campus.lake_surface.wave_time=4.0;campus.lake_surface._process(0);await frame();var moving=shot("14-lake-HD-wave-phase")
	var waterdelta=compare(still,moving);records.append({"fixture":"water_static_dynamic","comparison":waterdelta,"diagnostics":campus.lake_surface.get_hd_rgb_diagnostics()});check(waterdelta.changed_pixels>0,"Original water clock modulates actual HD water RGB")
	var outside_water_changes:=0
	var inverse:Transform2D=campus.get_canvas_transform().affine_inverse()
	for y in range(still.get_height()):
		for x in range(still.get_width()):
			if still.get_pixel(x,y)==moving.get_pixel(x,y):continue
			var source:Vector2=inverse*Vector2(x+.5,y+.5)-campus.lake_surface.source_origin
			var px:=Vector2i(floori(source.x),floori(source.y))
			if px.x<0 or px.y<0 or px.x>=163 or px.y>=108 or campus.lake_surface.alpha_image.get_pixelv(px).a<.5:outside_water_changes+=1
	records.append({"fixture":"water_clock_outside_original_alpha","changed_pixels":outside_water_changes});check(outside_water_changes==0,"Original shore/tree/bridge alpha exclusion is static under HD waves")
	campus.lake_surface.set_animation_enabled(false);campus.visitor.position=Vector2(566,836);campus.visitor.show();campus.ui.show();camera_at(Vector2(539,744),2.1);await frame();shot("15-final-normal-view")
	campus.queue_free();await process_frame;await process_frame;campus=null;finish()
func prove_core(nw:Node2D,sw:Node2D,label:String)->void:
	var vp=SubViewport.new();vp.size=Vector2i(1080,1080);vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(vp)
	var owner=Node2D.new();vp.add_child(owner)
	var lake:Sprite2D=campus.lake_surface.water_sprite.duplicate();lake.material=lake.material.duplicate();lake.position=campus.lake_surface.source_origin;owner.add_child(lake)
	var south:Sprite2D=sw.ground_sprite.duplicate();south.material=south.material.duplicate();owner.add_child(south)
	var north:Sprite2D=nw.ground_sprite.duplicate();north.material=north.material.duplicate();owner.add_child(north)
	var camera=Camera2D.new();camera.zoom=Vector2.ONE*5;owner.add_child(camera)
	var poison=Image.create(1,1,false,Image.FORMAT_RGBA8);poison.fill(Color.MAGENTA);var poison_texture=ImageTexture.create_from_image(poison)
	var water_original=lake.texture;var water_poison=water_original.get_image();water_poison.convert(Image.FORMAT_RGBA8)
	for y in range(water_poison.get_height()):
		for x in range(water_poison.get_width()):var c=water_poison.get_pixel(x,y);water_poison.set_pixel(x,y,Color(1,0,1,c.a))
	for id in ["NW","SW"]:
		camera.position=Vector2(534,519 if id=="NW" else 735);await frame();var original:Image=vp.get_texture().get_image();original.save_png(out.path_join("core-"+id+"-"+label+".png"))
		north.material.set_shader_parameter("original_source",poison_texture);south.material.set_shader_parameter("original_source",poison_texture);lake.texture=ImageTexture.create_from_image(water_poison);await frame();var poisoned:Image=vp.get_texture().get_image();var delta=compare(original,poisoned);records.append({"fixture":"entire216x216_core_source_poison","id":id,"neighbors":label,"comparison":delta});check(delta.changed_pixels==0,"Entire core has zero old RGB contribution: "+id+" "+label)
		north.material.set_shader_parameter("original_source",campus.SOURCE);south.material.set_shader_parameter("original_source",campus.SOURCE);lake.texture=water_original
	vp.queue_free();await frame()
func finish()->void:
	var f=FileAccess.open(out.path_join("west-render-result.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"records":records,"status":"actual_native_GPU_controlled_fixtures_manual_walk_pending"},"  "));f.close();print("BUCT_WEST_GPU checks=%d failures=%d"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
