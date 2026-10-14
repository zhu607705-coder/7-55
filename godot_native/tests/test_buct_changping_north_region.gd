extends SceneTree
const REGION=preload("res://campuses/buct_changping/scripts/registered_hd_region.gd")
const ROAD=preload("res://campuses/buct_changping/scripts/north_road_extension.gd")
const WENLI=preload("res://campuses/buct_changping/scripts/wenli_hd_region.gd")
const PROFILE="res://campuses/buct_changping/data/north_hd_region.json"
var checks:=0
var failures:Array[String]=[]
var output:=""
var invariant_comparison:Dictionary={}
var snapshot_index:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func settle()->void:await process_frame;await physics_frame;await process_frame
func run()->void:
	output=OS.get_environment("BUCT_NORTH_QA_DIR")
	if output.is_empty():output=ProjectSettings.globalize_path("user://north-hd-test")
	DirAccess.make_dir_recursive_absolute(output)
	var scene:PackedScene=load("res://campuses/buct_changping/scenes/playable.tscn")
	var baseline=scene.instantiate();baseline.enable_north_hd_region=false;baseline.enable_north_road_extension=false;root.add_child(baseline);await settle()
	var original_snapshot:=snapshot(baseline)
	baseline.queue_free();baseline=null;await settle()
	var campus=scene.instantiate();root.add_child(campus);await settle()
	var candidate_snapshot:=snapshot(campus)
	for key in original_snapshot:
		check(original_snapshot[key]==candidate_snapshot[key],"Frozen production field group unchanged: "+str(key))
	invariant_comparison={"baseline":original_snapshot,"candidate":candidate_snapshot,"additive_road_polygons":1,"new_body_visual_owners":1,"new_leaf_visual_owners":3}
	check(campus.initialized,"Default production scene initializes")
	var north=campus.north_hd_region
	check(is_instance_valid(north) and north.get_diagnostics().active,"Default installs complete north region")
	if not is_instance_valid(north):campus.queue_free();await settle();finish({});return
	campus.visitor.set_physics_process(false)
	var diagnostics:Dictionary=north.get_diagnostics()
	check(diagnostics.independent_bodies==1 and diagnostics.new_foreground_owners==3,"Independent solid building and three new leaf owners")
	check(diagnostics.shared_hd_owner_active,"Default shared HD strip is coordinated with accepted neighbor")
	check(diagnostics.region_ground_foreground_seam_ownership_gpu_bytes<12000000,"Exact region-layer mip allocation remains below12MB")
	check(diagnostics.independent_body_gpu_bytes>9000000,"Independent body GPU bytes are separately reported, not omitted")
	check(diagnostics.total_new_gpu_texture_bytes==diagnostics.region_ground_foreground_seam_ownership_gpu_bytes+diagnostics.independent_body_gpu_bytes,"Total new GPU allocation includes region and independent body")
	check(campus.walk_polys.size()==83 and campus.is_walkable(Vector2(731,670)),"Default road connects north through removed cap")
	check(north.bodies.north_sports_hall.body_passes.size()==2,"Solid north body allocates only two shared quads")
	check(north.find_children("*","CollisionObject2D",true,false).is_empty(),"HD region itself owns no physics")
	var legacy:CanvasItem=campus.objects.get_node("north_sports_hall/SourcePixelSilhouette")
	var underlay:CanvasItem=campus.world.get_node("CleanUnderlay_north_sports_hall")
	check(not legacy.visible and not underlay.visible,"Atomic successful install hides exact old visual owners")
	var body:Node2D=north.bodies.north_sports_hall
	check(campus.landmark_at(Vector2(681,485))=="north_sports_hall","Solid roof alpha selects neutral exterior")
	campus.show_landmark("wenli_building")
	check(campus.wenli_layer.selected and not body.selected,"Existing Wenli selection is exclusive before north card")
	campus.show_landmark("north_sports_hall")
	check(body.selected and not campus.wenli_layer.selected,"Wenli to north card clears old highlight")
	campus.show_landmark("wenli_building")
	check(campus.wenli_layer.selected and not body.selected,"North to Wenli card clears new highlight")
	campus.show_landmark("north_sports_hall")
	check(campus.info_id=="north_sports_hall" and campus.visited.is_empty(),"Neutral card creates no tour/history progress")
	campus.close_info();check(not body.selected,"Closing card clears selected state")
	var again=REGION.install(campus,PROFILE)
	check(again==north,"Second install returns the exact existing region")
	var wenli=campus.wenli_hd_region
	var old_wenli_ground:Texture2D=wenli.ground_texture
	var old_leaf_material:Material=wenli.leaf_restore[0].sprite.material
	wenli.uninstall();campus.wenli_hd_region=null;wenli=null;await settle()
	check(north.get_diagnostics().active and not north.get_diagnostics().shared_hd_owner_active,"Removing old neighbor leaves north active with its own edge fallback")
	wenli=WENLI.install(campus);campus.wenli_hd_region=wenli;await settle()
	check(is_instance_valid(wenli) and north.get_diagnostics().shared_hd_owner_active,"Legacy neighbor reinstall reconnects shared HD ownership")
	check(north.get_index()>wenli.get_index() and north.get_index()<campus.objects.get_index(),"Reversed installation order yields deterministic ground below objects")
	var new_wenli_leaf:Material=wenli.leaf_restore[0].sprite.material
	var new_wenli_ground:Texture2D=wenli.ground_texture
	var body_ref:WeakRef=weakref(body);var texture_ref:WeakRef=weakref(north.ground_texture)
	north.uninstall();campus.north_hd_region=null;body=null;again=null;north=null;await settle()
	check(legacy.visible and underlay.visible,"North uninstall restores its own old source owners")
	check(wenli.leaf_restore[0].sprite.material==new_wenli_leaf and wenli.ground_texture==new_wenli_ground,"North uninstall never clears another region's materials or ground")
	check(campus.walk_polys.size()==83 and campus.is_walkable(Vector2(731,670)),"North visual uninstall preserves independently owned logical road and navgrid")
	check(campus.path_to(Vector2(566,816)),"North visual uninstall preserves continuous library approach")
	# Malformed logical-road admission is deliberately tested after explicit road
	# removal, not by treating a visual uninstall as navigation authority.
	campus.north_road_extension.uninstall();campus.north_road_extension=null;await settle()
	check(campus.walk_polys.size()==82 and not campus.is_walkable(Vector2(731,670)),"Explicit logical-road uninstall restores east-road cap")
	check(body_ref.get_ref()==null and texture_ref.get_ref()==null,"Detached body and new ground release after uninstall")
	var road_golden:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ROAD.PROFILE))
	var road_cases:Array[Dictionary]=[]
	var bad_road=road_golden.duplicate(true);bad_road.erase("polygon_source_xy");road_cases.append({"id":"missing_polygon","data":bad_road})
	bad_road=road_golden.duplicate(true);bad_road.new_feet_guard_rect=[659,525,124];road_cases.append({"id":"short_rect","data":bad_road})
	bad_road=road_golden.duplicate(true);bad_road.exposed_joined_union_boundary_segments[0]=[[1,2]];road_cases.append({"id":"short_edge","data":bad_road})
	bad_road=road_golden.duplicate(true);bad_road.polygon_source_xy[0][0]=NAN;road_cases.append({"id":"nonfinite_polygon","data":bad_road})
	bad_road=road_golden.duplicate(true);bad_road.new_feet_guard_rect[3]=INF;road_cases.append({"id":"nonfinite_rect","data":bad_road})
	var old_road_snapshot:=var_to_bytes([campus.walk_polys,campus.east_road_extension.exposed_edges,campus.east_road_extension.guard_rect])
	var old_boundary_owner:Variant=campus.east_road_extension.get_meta("joined_boundary_owner") if campus.east_road_extension.has_meta("joined_boundary_owner") else null
	for item in road_cases:
		check(ROAD._install_profile(campus,item.data)==null,"Malformed road rejects before commit: "+item.id)
		check(var_to_bytes([campus.walk_polys,campus.east_road_extension.exposed_edges,campus.east_road_extension.guard_rect])==old_road_snapshot and not campus.objects.has_node("NorthOriginalRoadExtension"),"Malformed road leaves old walk/guards/nodes exact: "+item.id)
		var boundary_owner:Variant=campus.east_road_extension.get_meta("joined_boundary_owner") if campus.east_road_extension.has_meta("joined_boundary_owner") else null
		check(boundary_owner==old_boundary_owner,"Malformed road preserves old boundary owner: "+item.id)
	campus.north_road_extension=ROAD.install(campus);campus.walk_cells.clear();campus._build_grid()
	check(campus.walk_polys.size()==83 and campus.path_to(Vector2(666,548)),"Explicit logical road reinstalls independently of HD")
	var golden:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(PROFILE))
	var cases:Array[Dictionary]=[]
	var bad=golden.duplicate(true);bad.ground_rgba_sha256="wrong";cases.append({"id":"ground_hash","data":bad})
	bad=golden.duplicate(true);bad.ground_asset="res://campuses/buct_changping/scenes/playable.tscn";cases.append({"id":"wrong_resource","data":bad})
	bad=golden.duplicate(true);bad.source_body_ownership.size=null;cases.append({"id":"ownership_size_null","data":bad})
	bad=golden.duplicate(true);bad.foreground[2].alpha_sha256="wrong";cases.append({"id":"late_leaf_failure_after_detached_body","data":bad})
	bad=golden.duplicate(true);bad.foreground[0].rect=[0,0,20,20];cases.append({"id":"leaf_outside_owner","data":bad})
	bad=golden.duplicate(true);bad.shared_overlap.rgba_sha256="wrong";cases.append({"id":"seam_hash","data":bad})
	bad=golden.duplicate(true);bad.quality_approved="true";cases.append({"id":"approval_string","data":bad})
	bad=golden.duplicate(true);bad.independent_buildings[0].id="wenli_building";cases.append({"id":"foreign_body_owner","data":bad})
	var orphans_before:=Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	for item in cases:
		var path:String=output.path_join("invalid-north-"+item.id+".json")
		var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(item.data,"",true,true));file.close()
		var rejected=REGION.install(campus,path)
		check(rejected==null,"Malformed region rejected: "+item.id)
		await settle()
		check(legacy.visible and underlay.visible and not campus.world.has_node("RegisteredHDRegion_north_adjacent"),"Failure leaves no partial source mutation: "+item.id)
		check(wenli.leaf_restore[0].sprite.material==new_wenli_leaf,"Failure preserves neighboring leaf owner: "+item.id)
	check(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)<=orphans_before,"All failed-prepare detached nodes release")
	# Synthetic admission metadata exercises the real production loader's bounds;
	# these fixtures do not allocate fake textures or claim whole-engine memory.
	var budget_script:=GDScript.new()
	budget_script.source_code="extends Node2D\nvar allocation=1000\nfunc get_diagnostics():return {\"active\":true,\"new_gpu_texture_bytes\":allocation}\n"
	check(budget_script.reload()==OK,"Residency admission fixture compiles")
	var budget_nodes:Array[Node2D]=[]
	for i in range(5):
		var marker:=Node2D.new();marker.set_script(budget_script);marker.name="BudgetFixture%d"%i;campus.world.add_child(marker);budget_nodes.append(marker)
	check(REGION.install(campus,PROFILE)==null,"Seventh region is rejected before acquiring new textures")
	for marker in budget_nodes:marker.free()
	budget_nodes.clear()
	var heavy:=Node2D.new();heavy.set_script(budget_script);heavy.allocation=50000000;campus.world.add_child(heavy)
	check(REGION.install(campus,PROFILE)==null,"Projected region-layer bytes beyond57.6MB are rejected before allocation")
	heavy.free()
	# Existing source visibility changed by another owner while HD was active.
	underlay.hide();north=REGION.install(campus,PROFILE);await settle();underlay.show()
	north.uninstall();north=null;await settle()
	check(underlay.visible,"Uninstall does not overwrite a later foreign visibility owner")
	north=REGION.install(campus,PROFILE);campus.north_hd_region=north;await settle()
	check(is_instance_valid(north),"Valid reinstall succeeds after every failure")
	root.remove_child(campus)
	check(not north.get_diagnostics().active and legacy.visible and underlay.visible,"Cached scene detach retires HD safely to exact source fallback")
	root.add_child(campus);await settle()
	check(not north.get_diagnostics().active,"Re-added retired scene does not revive mixed stale state")
	var retired:WeakRef=weakref(north);north=REGION.install(campus,PROFILE);campus.north_hd_region=north;await settle()
	check(is_instance_valid(north) and retired.get_ref()==null,"Explicit reinstall replaces the retired component")
	var final_body:WeakRef=weakref(north.bodies.north_sports_hall)
	campus.queue_free();campus=null;north=null;wenli=null;await settle()
	check(final_body.get_ref()==null,"Final campus exit releases independent body")
	finish(diagnostics)
func finish(diagnostics:Dictionary)->void:
	if not output.is_empty():
		var file:=FileAccess.open(output.path_join("north-region-headless-result.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"allocation":diagnostics,"production_invariant_comparison":invariant_comparison,"scope":"Default component/ownership/lifecycle validation; no GPU visual claim"},"  "));file.close()
	print("BUCT_NORTH_REGION checks=%d failures=%d"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)

func snapshot(map:Node2D)->Dictionary:
	var physics:Array=[]
	_collect_physics(map,map,physics)
	if not output.is_empty():
		var snapshot_file:=FileAccess.open(output.path_join("physics-runtime-snapshot-%d.json"%snapshot_index),FileAccess.WRITE)
		snapshot_file.store_string(JSON.stringify(physics,"  "));snapshot_file.close();snapshot_index+=1
	var source_nodes:Array=[]
	var layer_data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://campuses/buct_changping/data/layers.json"))
	for item in layer_data.objects:
		var owner:Node2D=map.objects.get_node(str(item.id))
		source_nodes.append([str(item.id),owner.get_class(),owner.position,owner.global_transform,owner.z_index,owner.y_sort_enabled])
	var original_roads:Array=[]
	for i in range(82):original_roads.append(map.walk_polys[i])
	return {"collision_layers_masks_shapes_global_transforms_sha256":REGION._sha(var_to_bytes(physics)),
		"collision_record_count":physics.size(),"original_registered_ids_anchors_transforms_zsort_sha256":REGION._sha(var_to_bytes(source_nodes)),
		"registered_source_owner_count":source_nodes.size(),"original82_paving_sha256":REGION._sha(var_to_bytes(original_roads)),
		"poi_spawn_guide_sha256":REGION._sha(var_to_bytes([map.data.landmarks,map.data.spawn,map.data.route_waypoints])),
		"shared_student_feet_sha256":REGION._sha(var_to_bytes([map.visitor.position,map.visitor.global_transform,map.visitor.speed,map.visitor.display_height,map.visitor.get_node("FeetCollision").position,map.visitor.get_node("FeetCollision").shape.radius])),
		"source_layers_file_sha256":FileAccess.get_sha256("res://campuses/buct_changping/data/layers.json"),
		"source_route_file_sha256":FileAccess.get_sha256("res://campuses/buct_changping/data/playable_route.json")}
func _collect_physics(map:Node2D,node:Node,records:Array)->void:
	if node is CollisionObject2D:
		records.append([_stable_path(map,node),node.get_class(),node.collision_layer,node.collision_mask,node.global_transform])
	if node is CollisionPolygon2D:
		records.append([_stable_path(map,node),node.get_class(),node.polygon,node.global_transform,node.disabled])
	if node is CollisionShape2D:
		var shape_data:Variant=null
		if node.shape is CircleShape2D:shape_data=node.shape.radius
		elif node.shape is RectangleShape2D:shape_data=node.shape.size
		elif node.shape is CapsuleShape2D:shape_data=[node.shape.radius,node.shape.height]
		records.append([_stable_path(map,node),node.get_class(),node.shape.get_class(),shape_data,node.global_transform,node.disabled])
	for child in node.get_children():_collect_physics(map,child,records)

func _stable_path(map:Node,node:Node)->String:
	var pieces:Array[String]=[]
	var cursor:Node=node
	while cursor!=map:
		var label:=str(cursor.name)
		# Engine-generated anonymous suffixes change between scene instances;
		# original named IDs, hierarchy and child index remain compared exactly.
		if label.begins_with("@"):label=cursor.get_class()+"[%d]"%cursor.get_index()
		pieces.push_front(label);cursor=cursor.get_parent()
	return "/".join(pieces)
