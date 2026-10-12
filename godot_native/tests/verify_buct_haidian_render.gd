extends SceneTree
var failures: Array[String]=[]
var results: Dictionary={}
var review_backend: String="sprite_regions"
var evidence_root: String=""
func _init() -> void:call_deferred("run")
func set_backend(building: Node2D, backend: String) -> void:
	building.set_render_backend(backend)
func set_filter(building: Node2D,filter: int) -> void:
	building.back_sprite.texture_filter=filter;building.front_sprite.texture_filter=filter
	for strip in building.depth_columns:strip.texture_filter=filter
func alpha_difference(a: Image,b: Image) -> Dictionary:
	var changed:=0;var support:=0;var cutoff:=0;var maximum:=0
	for y in range(a.get_height()):
		for x in range(a.get_width()):
			var first: int=a.get_pixel(x,y).a8;var second: int=b.get_pixel(x,y).a8
			if first!=second:changed+=1
			if (first>0)!=(second>0):support+=1
			if (first>=13)!=(second>=13):cutoff+=1
			maximum=maxi(maximum,absi(first-second))
	return {"alpha_value_changed_pixels":changed,"nonzero_support_difference":support,"threshold13_support_difference":cutoff,"maximum_alpha_delta":maximum}
func frames(n: int=2) -> void:
	for i in range(n):await process_frame;await RenderingServer.frame_post_draw
func compare(a: Image,b: Image,outside:=Rect2i()) -> int:
	var changed:=0
	for y in range(a.get_height()):
		for x in range(a.get_width()):
			if outside.has_area() and outside.has_point(Vector2i(x,y)):continue
			if a.get_pixel(x,y)!=b.get_pixel(x,y):changed+=1
	return changed
func protected_difference(actual: Image,source: Image,mask: Image) -> int:
	var changed:=0
	for y in range(mask.get_height()):
		for x in range(mask.get_width()):
			if mask.get_pixel(x,y).r>0.5 and actual.get_pixel(x+400,y+144)!=source.get_pixel(x+400,y+144):changed+=1
	return changed
func rect_difference(actual: Image,source: Image,rect: Array) -> int:
	return compare(actual.get_region(Rect2i(rect[0],rect[1],rect[2],rect[3])),source.get_region(Rect2i(rect[0],rect[1],rect[2],rect[3])))
func expect(value: bool,message: String) -> void:
	print("PASS " if value else "FAIL ",message)
	if not value:failures.append(message)
func save_crop(image: Image,feet: Vector2,path: String) -> void:
	image.get_region(Rect2i(int(feet.x)-30,int(feet.y)-45,60,65)).save_png(evidence_root+path+".png")
func run() -> void:
	evidence_root=OS.get_environment("BUCT_HAIDIAN_PROOF_DIR")
	var reference_root: String=OS.get_environment("BUCT_HAIDIAN_REFERENCE_DIR")
	if not evidence_root.is_absolute_path() or not reference_root.is_absolute_path():
		push_error("BUCT_HAIDIAN_PROOF_DIR and BUCT_HAIDIAN_REFERENCE_DIR must be explicit absolute test directories");quit(2);return
	evidence_root=evidence_root.path_join("")+"/"
	DirAccess.make_dir_recursive_absolute(evidence_root)
	var app=load("res://campuses/buct_haidian/scenes/playable.tscn").instantiate();root.add_child(app);await process_frame
	if app.real_buildings.size()!=1:print("REQUIRED_REAL_ASSETS_MISSING");app.queue_free();await process_frame;quit(1);return
	set_backend(app.real_buildings.main_building,review_backend);results.render_backend=review_backend
	results.texture_filter=str(app.real_buildings.main_building.profile.get("body_filter","linear"))
	results.alpha_filter="fixed LOD0" if app.real_buildings.main_building.rgb_mipmaps_alpha0 else "same as RGB"
	results.registration_contract=app.real_manifest.get("registration_contract","legacy axis scales")
	app.set_process(false);app.ui.hide();app.pin_layer.hide();app.canopy_locator.hide();app.camera.enabled=false
	var view:=SubViewport.new();view.size=Vector2i(1448,1086);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var campus=app.world;app.remove_child(campus);view.add_child(campus)
	var actor=app.visitor;actor.set_physics_process(false);actor.hide()
	await frames();var baseline:=view.get_texture().get_image();baseline.save_png(evidence_root+"genuine-campus-registered.png")
	var source: Image=app.SOURCE.get_image();var outside_diff:=compare(baseline,source,Rect2i(398,144,482,368))
	results.outside_shared_region_changed_pixels=outside_diff
	expect(outside_diff==0,"Outside shared generated region, full original-campus source pixels are unchanged")
	for id in ["main_building"]:app.real_buildings[id].set_body_visible(false)
	await frames();var hidden:=view.get_texture().get_image();hidden.save_png(evidence_root+"genuine-campus-hidden-ground.png")
	expect(hidden.get_pixel(650,290)!=baseline.get_pixel(650,290),"Hiding whole teaching body reveals independent generated ground; library stays legacy")
	for pair in [["genuine-campus-registered.png",baseline],["genuine-campus-hidden-ground.png",hidden]]:
		var approved:=Image.load_from_file(reference_root.path_join(pair[0]))
		var approved_diff: int=compare(pair[1],approved) if approved!=null and approved.get_size()==pair[1].get_size() else -1
		results["source_reference_"+pair[0]]=approved_diff
		expect(approved_diff==0,"Integrated campus matches accepted source "+pair[0])
	var protected_mask: Image=load("res://campuses/buct_haidian/"+str(app.real_manifest.preserved_foliage_mask)).get_image()
	var protection: Array=[]
	for state in [["normal",baseline],["hidden",hidden]]:
		var tree_diff:=protected_difference(state[1],source,protected_mask)
		var row: Dictionary={"state":state[0],"original_foliage_changed_pixels":tree_diff,"original_static_regions":[]}
		expect(tree_diff==0,"Exact original foliage source pixels retained "+str(state[0]))
		for rect in app.real_manifest.preserved_source_rects:
			var changed:=rect_difference(state[1],source,rect);row.original_static_regions.append({"rect":rect,"changed_pixels":changed})
			expect(changed==0,"Original court/apron source pixels retained, not cached paving "+str(state[0])+str(rect))
		protection.append(row)
	results.original_source_protection=protection
	for id in ["main_building"]:app.real_buildings[id].reset_building()
	app.real_buildings.main_building.position+=Vector2(35,-20);await frames();view.get_texture().get_image().save_png(evidence_root+"genuine-campus-main-moved.png")
	app.real_buildings.main_building.reset_building();await frames();var restored:=view.get_texture().get_image();restored.save_png(evidence_root+"genuine-campus-restored.png");var restore_diff:=compare(restored,baseline)
	results.reset_changed_pixels=restore_diff;expect(restore_diff==0,"Genuine-body reset restores exact composed pixels")
	# Compare native strips against the same complete PNG, alone, without actor/trees.
	var strip_checks: Array=[]
	for name in ["main_building"]:
		var b=app.real_buildings[name];var original_parent=b.get_parent();original_parent.remove_child(b);view.add_child(b);campus.hide();view.transparent_bg=true;b.shadow_sprite.hide();await frames()
		var strips:=view.get_texture().get_image();strips.save_png(evidence_root+"body-alone-"+review_backend+".png")
		for strip in b.depth_columns:strip.hide()
		b.back_sprite.show();b.set_actor_foot(Vector2(0,10000));await frames();var whole:=view.get_texture().get_image();whole.save_png(evidence_root+"body-alone-whole.png");var difference:=compare(strips,whole)
		var maximum_delta:=0;var over_one:=0;var alpha_support_zero:=0;var alpha_support_cutoff:=0
		for yy in range(strips.get_height()):
			for xx in range(strips.get_width()):
				var a:=strips.get_pixel(xx,yy);var c:=whole.get_pixel(xx,yy)
				var delta:=maxi(maxi(abs(a.r8-c.r8),abs(a.g8-c.g8)),maxi(abs(a.b8-c.b8),abs(a.a8-c.a8)))
				maximum_delta=maxi(maximum_delta,delta)
				if (a.a8>0)!=(c.a8>0):alpha_support_zero+=1
				if (a.a8>=13)!=(c.a8>=13):alpha_support_cutoff+=1
				if delta>1:over_one+=1
		var row: Dictionary={"building":name,"changed_pixels":difference,"maximum_channel_delta":maximum_delta,"pixels_above1lsb":over_one,"strips":b.depth_columns.size(),"source_columns":b.profile.body_world_rect[2],"alpha_support_nonzero_difference":alpha_support_zero,"alpha_support_13_difference":alpha_support_cutoff}
		set_backend(b,"sprite_regions");b.shadow_sprite.hide();await frames();var sprite_frame:=view.get_texture().get_image();sprite_frame.save_png(evidence_root+"body-alone-sprite.png")
		row.render_backend=review_backend;row.sprite_changed_pixels=compare(sprite_frame,whole);row.exact_pixel_equality=(difference==0);row.coverage_within_1_lsb=(maximum_delta<=1 and over_one==0);set_backend(b,review_backend);strip_checks.append(row)
		expect(maximum_delta<=1 and over_one==0,"Native depth strips preserve coverage within explicit1LSB raster tolerance "+name)
		expect(alpha_support_zero==0 and alpha_support_cutoff==0,"Native depth strips preserve exact nonzero and threshold alpha support "+name)
		b.back_sprite.hide();for strip in b.depth_columns:strip.show()
		view.remove_child(b);original_parent.add_child(b);view.transparent_bg=false;b.shadow_sprite.show();campus.show()
	results.full_texture_strip_equivalence=strip_checks
	await frames();baseline=view.get_texture().get_image();actor.show()
	var canopy_checks: Array=[]
	for pose in app.data.qa.canopy_poses:
		var feet:=Vector2(pose.feet[0],pose.feet[1]);actor.position=feet;await frames();var frame:=view.get_texture().get_image();var sample:=Vector2i(feet+Vector2(0,-13))
		var preserved: bool=frame.get_pixelv(sample)==baseline.get_pixelv(sample)
		var passed: bool=preserved==bool(pose.hidden)
		canopy_checks.append({"name":pose.name,"feet":pose.feet,"head_hidden":preserved,"expected_hidden":pose.hidden,"walkable":app.is_walkable(feet),"pass":passed})
		expect(passed,"Original roadside canopy Y-sort remains correct "+str(pose.name));save_crop(frame,feet,"genuine-canopy-"+str(pose.name))
	results.canopies=canopy_checks
	var facade_checks: Array=[]
	for feet in [Vector2(610,344),Vector2(630,353),Vector2(746,391)]:
		actor.position=feet;await frames();var frame:=view.get_texture().get_image();var sample:=Vector2i(feet+Vector2(0,-13));var visible: bool=frame.get_pixelv(sample)!=baseline.get_pixelv(sample)
		facade_checks.append({"feet":[feet.x,feet.y],"visible":visible,"walkable":app.is_walkable(feet)})
		expect(visible,"Actual front-facade route head remains visible "+str(feet));save_crop(frame,feet,"genuine-facade-%d-%d"%[int(feet.x),int(feet.y)])
	results.facades=facade_checks
	var probes: Array=[]
	for pair in [["main_building",650.0]]:
		var b=app.real_buildings[pair[0]];var x: float=pair[1];var y: float=b.depth_y_at_world_x(x)
		for front in [false,true]:
			var feet:=Vector2(x,y+4 if front else y-30);actor.position=feet;await frames();var frame:=view.get_texture().get_image();var sample:=Vector2i(feet+Vector2(0,-13));var hidden_head: bool=frame.get_pixelv(sample)==baseline.get_pixelv(sample)
			var passed: bool=hidden_head!=front
			probes.append({"building":pair[0],"feet":[feet.x,feet.y],"front":front,"head_hidden":hidden_head,"walkable":app.is_walkable(feet),"qualification":"Stationary renderer depth probe, not a newly opened walking path","pass":passed})
			expect(passed,"Real building native front/back depth "+str(pair[0])+str(front));save_crop(frame,feet,"genuine-body-"+str(pair[0])+str(front))
	results.building_depth_probes=probes
	actor.hide();await frames()
	if app.real_buildings.main_building.rgb_mipmaps_alpha0:
		var zoom_checks: Array=[];var b=app.real_buildings.main_building
		var zoom_camera:=Camera2D.new();view.add_child(zoom_camera);zoom_camera.make_current();view.size=Vector2i(1280,800)
		for zoom in [.69,2.1]:
			var tag: String="overview" if zoom<1 else "close"
			zoom_camera.zoom=Vector2.ONE*zoom;zoom_camera.position=Vector2(724,543) if zoom<1 else Vector2(640,330)
			set_filter(b,CanvasItem.TEXTURE_FILTER_LINEAR);await frames();view.get_texture().get_image().save_png(evidence_root+tag+"-linear.png")
			set_filter(b,CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS);await frames();view.get_texture().get_image().save_png(evidence_root+tag+"-rgb-mipmap-alpha0.png")
			var parent=b.get_parent();parent.remove_child(b);view.add_child(b);campus.hide();b.shadow_sprite.hide();view.transparent_bg=true
			set_filter(b,CanvasItem.TEXTURE_FILTER_LINEAR);await frames();var linear_alpha:=view.get_texture().get_image()
			set_filter(b,CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS);await frames();var candidate_alpha:=view.get_texture().get_image()
			var check: Dictionary=alpha_difference(linear_alpha,candidate_alpha);check.zoom=zoom;check.target=[1280,800];zoom_checks.append(check)
			expect(check.alpha_value_changed_pixels==0,"RGB mipmap retains exact LINEAR alpha values/support at zoom"+str(zoom))
			view.remove_child(b);parent.add_child(b);campus.show();b.shadow_sprite.show();view.transparent_bg=false
		results.zoom_alpha_compared_with_linear=zoom_checks;zoom_camera.queue_free();view.size=Vector2i(1448,1086);await frames()
	campus.queue_free();app.queue_free();await process_frame;view.queue_free();await process_frame
	var mobile_checks: Array=[]
	for size in [Vector2i(392,844),Vector2i(667,375)]:
		var mobile:=SubViewport.new();mobile.size=size;mobile.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(mobile)
		var entry=load("res://scenes/entry.tscn").instantiate();mobile.add_child(entry);await frames(3)
		entry.size=Vector2(size);entry._layout();await frames(3)
		var bounds:=Rect2(Vector2.ZERO,Vector2(size));var chooser_fit: bool=bounds.encloses(entry.card.get_global_rect())
		expect(chooser_fit,"Actual rendered three-entry chooser fits "+str(size))
		mobile.get_texture().get_image().save_png(evidence_root+"ui-%dx%d-entry.png"%[size.x,size.y]);entry.queue_free();await frames()
		var campus_ui=load("res://campuses/buct_haidian/scenes/playable.tscn").instantiate();mobile.add_child(campus_ui);await frames(4)
		campus_ui.visitor.set_physics_process(false);campus_ui.camera.position_smoothing_enabled=false;campus_ui._layout_ui();await frames(3)
		mobile.get_texture().get_image().save_png(evidence_root+"ui-%dx%d-map.png"%[size.x,size.y])
		campus_ui.show_landmark("main_building");await frames(3)
		mobile.get_texture().get_image().save_png(evidence_root+"ui-%dx%d-info.png"%[size.x,size.y])
		campus_ui.close_info();campus_ui.open_debug();await frames(3)
		mobile.get_texture().get_image().save_png(evidence_root+"ui-%dx%d-building.png"%[size.x,size.y])
		var panel_fit: bool=bounds.encloses(campus_ui.building_panel.get_global_rect())
		expect(panel_fit,"Actual rendered building inspector fits "+str(size))
		campus_ui.open_debug();campus_ui.toggle_overview();await frames(3)
		mobile.get_texture().get_image().save_png(evidence_root+"ui-%dx%d-overview.png"%[size.x,size.y])
		mobile_checks.append({"size":[size.x,size.y],"actual_texture_size":[mobile.get_texture().get_width(),mobile.get_texture().get_height()],"chooser_fit":chooser_fit,"inspector_fit":panel_fit,"qualification":"Actual fixed SubViewport rendering; scripted poses, not manual touch testing"})
		campus_ui.queue_free();await frames();mobile.queue_free();await process_frame
	results.mobile_rendering=mobile_checks
	results.status="PASS" if failures.is_empty() else "FAIL";results.errors=failures
	results.root_actual_texture_size=[root.get_texture().get_image().get_width(),root.get_texture().get_image().get_height()]
	results.fixed_proof_target=[1448,1086]
	results.qualification="One independently generated connected teaching building; library stays legacy. Exact-pixel protection/reset and integrated-vs-accepted-source comparisons are separate from the explicit1LSB whole-PNG/strip interpolation tolerance. Mobile snapshots use fixed actual SubViewports."
	var out:=FileAccess.open(evidence_root+"genuine-render-proof.json",FileAccess.WRITE);out.store_string(JSON.stringify(results,"\t"));out.close()
	print("BUCT_HAIDIAN_RENDER ",results.status," failures=",failures);quit(0 if failures.is_empty() else 1)
