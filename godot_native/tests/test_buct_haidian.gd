extends SceneTree
var errors: Array[String]=[]
var checks:=0
var review_backend: String=""
func _init() -> void:call_deferred("run")
func expect(value: bool,message: String) -> void:
	checks+=1;print("PASS " if value else "FAIL ",message)
	if not value:errors.append(message)
func frames(n: int=2) -> void:
	for i in range(n):await physics_frame
func collect(node: Node,refs: Array[WeakRef]) -> void:
	refs.append(weakref(node))
	for child in node.get_children():collect(child,refs)
func occupied(app: Node2D,p: Vector2) -> bool:
	var q:=PhysicsPointQueryParameters2D.new();q.position=p;q.collision_mask=1
	return not app.get_world_2d().direct_space_state.intersect_point(q).is_empty()
func run() -> void:
	var state_node: Node=root.get_node("State")
	var state_before: Dictionary=state_node.d.duplicate(true)
	var scene=load("res://campuses/buct_haidian/scenes/playable.tscn");var app=scene.instantiate();root.add_child(app);await frames(3)
	expect(app.real_buildings.size()==1,"Teaching inspector remains isolated from fixed Rongmao object")
	if app.real_buildings.size()!=1:app.queue_free();await frames();quit(1);return
	review_backend=OS.get_environment("BUCT_REVIEW_BACKEND")
	if review_backend=="sprite_regions":app.real_buildings.main_building.set_render_backend(review_backend)
	print("REVIEW_RENDER_BACKEND ",app.real_buildings.main_building.profile.get("render_backend","polygon"))
	var registered=app.real_buildings.main_building
	var lib=app.library_component
	expect(is_instance_valid(lib) and lib.body_passes.size()==3,"Rongmao real RGBA installed with three compact native passes")
	expect(lib.source_anchor==Vector2(517,473) and lib.image_scale==196.0/1115.0,"Rongmao single raw-pixel affine registration preserved")
	expect(lib.hit_test_alpha(Vector2(520,400)) and not lib.hit_test_alpha(Vector2(410,480)),"Rongmao opaque hit and transparent-frame miss")
	expect(lib.contact_shadow.scale.x==lib.contact_shadow.scale.y,"Rongmao shadow uses same scalar transform, no anisotropic correction")
	expect(app.generated_repair.has_node("Rongmao141PixelGroundRepair"),"Only bounded 141-pixel true-ground repair added")
	var library_freed:=true
	for ref in app.library_retired_refs:library_freed=library_freed and ref.get_ref()==null
	expect(library_freed,"Old library body, collider, wide copied shadow and shadow underlay released")
	var wrong_shadows:=false
	for child in app.world.get_node("StaticSourceGroundShadows").get_children():wrong_shadows=wrong_shadows or str(child.name).begins_with("library_GroundShadow_")
	expect(not wrong_shadows,"Old blue-court shadow proxy no longer draws")
	app.show_landmark("library")
	expect(lib.selected and app.info_id=="library" and app.info_text.text.contains("独立透明"),"Existing library landmark card and true-alpha selection use same identity")
	app.close_info()
	expect(not lib.selected and app.info_id.is_empty(),"Library card close clears selection")
	var expected_rects: Dictionary={"WestCompleteCleanGround":[424,160,226,180],"EastCompleteCleanGround":[754,250,106,162],"LongFacadeCleanGround":[588,247,185,141]}
	for layer in app.real_manifest.ground_layers:
		expect(expected_rects.has(layer.id) and Vector4(layer.world_rect[0],layer.world_rect[1],layer.world_rect[2],layer.world_rect[3])==Vector4(expected_rects[layer.id][0],expected_rects[layer.id][1],expected_rects[layer.id][2],expected_rects[layer.id][3]) and layer.image_to_world.clip_world_rect==layer.world_rect,"Exact accepted ground ROI retained "+str(layer.id))
	expect(registered.back_sprite.scale.x==registered.back_sprite.scale.y and registered.shadow_sprite.scale.x==registered.shadow_sprite.scale.y,"Body and contact shadow use exactly equal x/y uniform scales")
	var all_uniform:=true
	for strip in registered.depth_columns:
		if strip is Sprite2D:all_uniform=all_uniform and strip.scale.x==strip.scale.y
	for ground in app.generated_repair.get_children():all_uniform=all_uniform and ground.scale.x==ground.scale.y
	expect(all_uniform,"Every Sprite depth region and ground patch uses one scalar image-to-world scale")
	var png_point:=Vector2(900,577);var registered_point: Vector2=registered.to_global(registered.body_rect.position+png_point*registered.body_image_scale)
	expect(registered.hit_test_alpha(registered_point) and ((registered.to_local(registered_point)-registered.body_rect.position)/registered.body_image_scale).distance_to(png_point)<0.001,"Uniform raw-PNG UV and alpha-picking inverse agree at an opaque eave pixel")
	var baseline_value: float=registered.profile.depth_baseline_crop_y[242]
	expect(absf(registered.depth_y_at_world_x(650)-(144+baseline_value))<.001,"Native foot-depth baseline uses the same uniform registered coordinate frame")
	expect(app.WORLD==Vector2(1448,1086) and app.visitor.position==Vector2(963,297),"Original full-source canvas and north entrance retained")
	expect(app.visitor.speed==88 and app.tour_speed==106 and app.visitor.get_node("FeetCollision").shape.radius==3,"Original campus movement contract preserved")
	var old_freed:=true
	for ref in app.retired_legacy_refs:old_freed=old_freed and ref.get_ref()==null
	expect(old_freed,"Retired UV bodies, native repair patches, old shadows and colliders released")
	expect(not app.landmark_hit_polys.has("main_building") and not app.landmark_hit_polys.has("library"),"Both teaching and library legacy polygon click proxies retired")
	expect(app.landmark_at(Vector2(650,310))=="main_building" and app.landmark_at(Vector2(520,400))=="library","Genuine alpha body hit opens original landmark identity")
	expect(app.landmark_at(Vector2(408,145)).is_empty(),"Blank alpha rectangle never selects building")
	expect(app.world.get_node_or_null("CleanUnderlay_main_building")==null and app.world.get_node_or_null("CleanShadowUnderlay_main_building")==null,"Both retired teaching underlays removed from scene")
	expect(app.world.get_node_or_null("CleanUnderlay_library")!=null and app.world.get_node_or_null("CleanShadowUnderlay_library")==null,"Only exact masked hidden core retained; wrong broad library shadow underlay retired")
	var mask: Image=load("res://campuses/buct_haidian/"+str(app.real_manifest.repair_mask)).get_image()
	expect(mask.get_pixel(80,123).r>0.5 and mask.get_pixel(250,109).r>0.5,"Revised mask includes omitted west last-floor facade and long back parapet")
	expect(mask.get_pixel(45,227).r==0 and mask.get_pixel(23,117).r==0,"Original blue court and west apron excluded from generated repair")
	var safe:=Vector2.ZERO
	for cell in app.walk_cells:
		var candidate: Vector2=Vector2(cell)*app.CELL+Vector2.ONE*app.CELL*.5;var valid:=true
		for delta in [Vector2(-10,0),Vector2(10,0),Vector2(0,-10),Vector2(0,10)]:valid=valid and app.is_walkable(candidate+delta)
		if valid and not occupied(app,candidate):safe=candidate;break
	expect(safe!=Vector2.ZERO,"Physical-key test found an unchanged open paved interior")
	var focus_button: Button=app.ui.find_children("*","Button",true,false)[0]
	for focused in [false,true]:
		for test in [[KEY_A,Vector2.LEFT,true],[KEY_D,Vector2.RIGHT,true],[KEY_W,Vector2.UP,true],[KEY_S,Vector2.DOWN,true],[KEY_LEFT,Vector2.LEFT,false],[KEY_RIGHT,Vector2.RIGHT,false],[KEY_UP,Vector2.UP,false],[KEY_DOWN,Vector2.DOWN,false]]:
			app.visitor.position=safe;app.close_info();app.guide_active=false;app.guide_pause=0;app.overview=false
			if focused:focus_button.grab_focus()
			else:root.gui_release_focus()
			var event:=InputEventKey.new();event.pressed=true
			if test[2]:event.physical_keycode=test[0]
			else:event.keycode=test[0]
			Input.parse_input_event(event);await frames(8);var moved: Vector2=app.visitor.position-safe
			event.pressed=false;Input.parse_input_event(event);await frames(2)
			expect(moved.dot(test[1])>2.0,"Real InputEventKey movement code%d focused%s"%[test[0],focused])
	root.gui_release_focus();app.return_to_gate()
	app.overview=true;app._fit_overview_camera();app.camera.force_update_scroll();await frames(2)
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.position=app.get_canvas_transform()*Vector2(650,310)
	root.push_input(click,true);await frames(2);click.pressed=false;root.push_input(click,true);await frames()
	expect(app.info_id=="main_building" and app.real_buildings.main_building.selected,"Actual overview mouse event selects opaque teaching roof and opens card")
	app.close_info();click.pressed=true;click.position=app.get_canvas_transform()*Vector2(408,145);root.push_input(click,true);await frames(2);click.pressed=false;root.push_input(click,true);await frames()
	expect(app.info_id.is_empty() and not app.real_buildings.main_building.selected,"Actual overview transparent-alpha click does not select building")
	app.close_info();click.pressed=true;click.position=app.get_canvas_transform()*Vector2(520,360);root.push_input(click,true);await frames(2);click.pressed=false;root.push_input(click,true);await frames()
	expect(app.info_id=="library" and lib.selected,"Actual overview roof mouse event opens Rongmao card")
	app.close_info();click.pressed=true;click.position=app.get_canvas_transform()*Vector2(587,480);root.push_input(click,true);await frames(2);click.pressed=false;root.push_input(click,true);await frames()
	expect(app.info_id.is_empty() and not lib.selected,"Actual transparent library-frame click does not select")
	app.return_to_gate()
	app.show_landmark("main_building");expect(app.info_id=="main_building" and app.visited.has("main_building"),"Existing landmark information and visited state used")
	app.close_info();expect(app.info_id.is_empty(),"Information return clears current selection")
	app.start_guide();var ticks:=0;var illegal:=0
	while app.guide_active and ticks<2500:
		await physics_frame;ticks+=1
		if not app.is_walkable(app.visitor.position):illegal+=1
	expect(not app.guide_active and app.guide_index>=app.data.route_waypoints.size() and app.visitor.position.distance_to(Vector2(551,481))<9,"Actual full north entrance→teaching→library route finishes at original speed")
	expect(illegal==0 and app.visited.size()==3,"Actual legal feet and all three original landmarks retained")
	var b=app.real_buildings.main_building;var ground_pose: Transform2D=app.generated_repair.transform;var library_pose: Transform2D=app.objects.get_node("library").transform
	app.active_building="main_building";app.toggle_real_visible();await frames()
	expect(not b.body_enabled and b.physics_body.collision_layer==0 and not b.shadow_sprite.visible,"Building hide removes own body, ground shadow and collision")
	expect(not occupied(app,Vector2(650,320)),"Hidden teaching foundation leaves no stale native collider")
	app.reset_real_buildings();app.toggle_real_moved();await frames()
	expect(b.position==b.source_anchor+Vector2(35,-20) and app.generated_repair.transform==ground_pose and app.objects.get_node("library").transform==library_pose,"Move affects selected genuine building only, not ground/neighbor")
	expect(not occupied(app,Vector2(650,320)),"Moved teaching leaves no stale collider at old foundation")
	expect(app.landmark_at(Vector2(685,290))=="main_building","Alpha selection follows moved whole PNG")
	for i in range(30):app.toggle_real_visible();app.toggle_real_moved();app.reset_real_buildings()
	expect(b.transform==b.rest_transform,"Thirty reset operations restore exact transform")
	app.return_to_gate();expect(app.visitor.position==Vector2(963,297),"Original R/return-to-entrance coordinate restored")
	var shadow_refs: Array[WeakRef]=[]
	for building in app.real_buildings.values():shadow_refs.append(weakref(building.shadow_sprite))
	var refs: Array[WeakRef]=[];collect(app,refs);app.queue_free();app=null;b=null;registered=null;lib=null;await frames(3)
	var freed:=true
	for ref in refs:freed=freed and ref.get_ref()==null
	expect(freed,"Whole-campus return releases all RGBA strips, old/new shadows and visitor")
	for i in range(shadow_refs.size()):expect(shadow_refs[i].get_ref()==null,"Independent named shadow WeakRef released %d"%i)
	for cycle in range(6):
		app=scene.instantiate();root.add_child(app);await frames(3)
		if review_backend=="sprite_regions":app.real_buildings.main_building.set_render_backend(review_backend)
		refs.clear();collect(app,refs);app.show_landmark("library");app.close_info();app.queue_free();app=null;await frames(3);freed=true
		for ref in refs:freed=freed and ref.get_ref()==null
		expect(freed,"Whole-campus repeated entry/return releases every descendant cycle%d"%(cycle+1))
	var rejected_script:=GDScript.new()
	rejected_script.source_code='extends "res://campuses/buct_haidian/scripts/playable_campus.gd"\nfunc _load_real_profiles() -> bool:\n\treturn false\n'
	var script_ready: int=rejected_script.reload()
	expect(script_ready==OK,"Missing-asset fixture compiles independently")
	if script_ready==OK:
		var failed_app: Node2D=rejected_script.new();root.add_child(failed_app);current_scene=failed_app;await frames()
		expect(not failed_app.initialized and is_instance_valid(failed_app.return_button) and failed_app.return_button.is_visible_in_tree(),"Missing required art leaves a visible return control")
		var failure_refs: Array[WeakRef]=[];collect(failed_app,failure_refs)
		root.set_meta("entry_arguments_consumed",true)
		failed_app.return_button.pressed.emit()
		for wait_frame in range(30):
			await process_frame
			if is_instance_valid(current_scene) and current_scene!=failed_app:break
		expect(is_instance_valid(current_scene) and current_scene.scene_file_path=="res://scenes/entry.tscn","Missing-art return uses the real scene transition")
		var failure_freed:=true
		for ref in failure_refs:failure_freed=failure_freed and ref.get_ref()==null
		expect(failure_freed,"Missing-art failure scene releases fully")
		if is_instance_valid(current_scene):current_scene.queue_free()
		await frames(2)
	expect(state_node.d==state_before,"Map replacement and entry/return leave original story state unchanged")
	var out: String=OS.get_environment("BUCT_RONGMAO_QA")
	if not out.is_empty():
		DirAccess.make_dir_recursive_absolute(out)
		var report_file:=FileAccess.open(out.path_join("fullmap-headless.json"),FileAccess.WRITE)
		report_file.store_string(JSON.stringify({"checks":checks,"errors":errors,"route_ticks":ticks,"illegal_feet":illegal,"scope":"Full original campus with compact Rongmao, original movement, actual keys/clicks and repeated cleanup"},"  "));report_file.close()
	print("HAIDIAN_GENUINE_CAMPUS ","PASS" if errors.is_empty() else "FAIL"," checks=",checks," ticks=",ticks," illegal=",illegal," errors=",errors)
	quit(0 if errors.is_empty() else 1)
