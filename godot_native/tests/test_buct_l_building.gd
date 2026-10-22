extends SceneTree
const L_BUILDING = preload("res://campuses/buct/scripts/chaoyang_l_building.gd")
var checks := 0
var failures: Array[String] = []
var report: Array[Dictionary] = []
func _initialize() -> void:run.call_deferred()
func check(value: bool, label: String) -> void:
	checks += 1
	report.append({"pass":value,"label":label})
	if not value:failures.append(label);push_error(label)
func run() -> void:
	for cycle in range(3):
		var stage := Node2D.new();stage.y_sort_enabled=true;root.add_child(stage)
		var building = L_BUILDING.new();stage.add_child(building);await process_frame
		check(building.body_passes.size()==2,"Two complementary whole-PNG passes, cycle %d"%cycle)
		check(building.collision_shapes.size()==3,"Three facade ground contacts, cycle %d"%cycle)
		check(building.foliage_nodes.size()==4,"Four exact-source leaf fragments, cycle %d"%cycle)
		check(building.ground_patch!=null,"Only necessary masked ground patch installed")
		check(building.alpha_bytes.size()==1558*1010,"CPU caches alpha only")
		check(building.body_texture.get_image().has_mipmaps(),"Production imported L texture retains mipmaps")
		for probe in [[520,640,true],[450,655,true],[580,650,true],[580,690,true],[520,610,false],[520,690,false],[430,600,false],[560,689,false]]:
			check(building.hit_test_alpha(Vector2(probe[0],probe[1]))==probe[2],"Actual-alpha pick %s"%str(probe))
		for foot in [660.0,675.0,677.0,678.0,680.0,689.0,697.0,698.0,711.0]:
			building.update_actor_foot(foot,true)
			var partition:=true;var order:=true
			for raw_depth in building.column_depths:
				var depth: float=building.global_position.y+building.body_local_origin.y+raw_depth*building.image_scale
				var owners:=0
				for sprite in building.body_passes:
					if not sprite.visible:continue
					var material: ShaderMaterial=sprite.material
					if depth>float(material.get_shader_parameter("depth_lower")) and depth<=float(material.get_shader_parameter("depth_upper")):
						owners+=1;order=order and ((depth>foot)==(sprite.global_position.y>foot))
				partition=partition and owners==1
			check(partition,"Exact complementary coverage at foot %.2f"%foot)
			check(order,"Per-column foot order at %.2f"%foot)
		if cycle==0:
			var actor:=CharacterBody2D.new();actor.collision_layer=0;actor.collision_mask=1
			var shape:=CollisionShape2D.new();var circle:=CircleShape2D.new();circle.radius=3.0;shape.shape=circle;actor.add_child(shape);stage.add_child(actor)
			for x in [455.0,520.0,580.0]:
				var front: float=building.depth_y_at_world_x(x);actor.position=Vector2(x,front+12.0);await physics_frame
				var encountered:=false
				for i in range(20):
					await physics_frame
					var collision:=actor.move_and_collide(Vector2(0,-1.0));encountered=encountered or collision!=null
				check(encountered and actor.position.y>=front+2.8,"Radius-3 student stops at facade x%.1f"%x)
			actor.position=Vector2(550,688);await physics_frame
			var recess_clear:=true
			for i in range(30):
				await physics_frame
				recess_clear=recess_clear and actor.move_and_collide(Vector2(-1,0))==null
			check(recess_clear and actor.position.distance_to(Vector2(520,688))<0.01,"South recess no longer filled by old y692 rectangle")
			actor.position=Vector2(553,689);await physics_frame
			var east_contact:=false
			for i in range(18):
				await physics_frame
				east_contact=east_contact or actor.move_and_collide(Vector2(1,0))!=null
			check(east_contact and actor.position.x<564,"Concave inner east return blocks at its actual west-side contact")
		var weak: WeakRef=weakref(building);stage.queue_free();await process_frame;await process_frame
		check(weak.get_ref()==null,"Release all L nodes cycle %d"%cycle)
	var app=load("res://campuses/buct/scenes/playable.tscn").instantiate();root.add_child(app);await process_frame
	check(app.landmark_at(Vector2(520,640))=="west_inner_l_block","Full-map genuine alpha routes to L info")
	check(app.landmark_at(Vector2(520,690))=="","Transparent exterior has no polygon fallback")
	var story_before: String=JSON.stringify(root.get_node("State").d)
	var visited_before: Array=app.visited.duplicate()
	var progress_before: String=app.progress.text
	app.show_landmark("west_inner_l_block")
	check(app.info_id=="west_inner_l_block" and app.info_panel.visible and app.l_building.selected,"L info and selected cue shown")
	check(not app.ui_controls.library_toggle.visible and not app.ui_controls.library_reset.visible,"No unsupported L hide/move control")
	app.close_info();check(not app.info_panel.visible and not app.l_building.selected,"Close restores unselected map")
	check(app.visited==visited_before and app.progress.text==progress_before,"L inspection does not change three-landmark visit count")
	app.show_landmark("library");check(app.info_id=="library" and app.ui_controls.library_toggle.visible,"Existing library card still works")
	app.close_info();app.show_landmark("main_building");check(app.info_id=="main_building" and not app.ui_controls.library_toggle.visible,"Existing main-building card still works")
	app.close_info()
	check(JSON.stringify(root.get_node("State").d)==story_before,"L and existing map cards preserve original story state")
	check(app.data.route_waypoints.size()==29,"Original guide waypoint count remains 29")
	check(app.visitor.character_visual.target_height==18.0,"Accepted student height remains 18 source pixels")
	app.queue_free();await process_frame
	var out:=OS.get_environment("BUCT_L_EVIDENCE_DIR")
	if not out.is_empty():
		DirAccess.make_dir_recursive_absolute(out)
		var file:=FileAccess.open(out.path_join("headless-results.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"results":report},"  "))
	print("BUCT_L_BUILDING: ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
