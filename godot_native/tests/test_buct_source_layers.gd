extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("BUCT LAYERS: "+message)
func run() -> void:
	var adapter_source:=FileAccess.get_file_as_string("res://campuses/buct/scripts/chaoyang_library.gd")
	check(adapter_source.contains("var configured_ok := configure(") and adapter_source.contains("if not configured_ok:"),"Release-safe initialization executes configure outside removable assertions")
	for script_name in ["chaoyang_library","layered_building","library_ground"]:
		var source:=FileAccess.get_file_as_string("res://campuses/buct/scripts/%s.gd"%script_name)
		check(not source.contains("assert("),"New production script has no assert-only side effects: "+script_name)
	var scene: Node2D=load("res://campuses/buct/scenes/registered_layers.tscn").instantiate()
	root.add_child(scene);await process_frame;await physics_frame
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://campuses/buct/data/layers.json"))
	var objects: Node2D=scene.get_node("IndependentRegisteredObjects")
	check(data.objects.size()==44 and objects.get_child_count()==44,"44 native groups remain: one genuine-alpha building and 43 legacy UV groups")
	check(scene.get_node("StaticUnseparatedCampus").texture.get_size()==Vector2(1448,1086),"Approved source dimensions remain unchanged")
	check(scene.get_node("GroundRepairTiles/SourcePaving16px") is TileMapLayer,"Repair ground remains native TileMapLayer")
	check(scene.get_node("GroundRepairTiles/SourcePaving16px").get_used_cells().size()==6188,"All 6188 repair cells are preserved")
	check(scene.get_node("GroundRepairTiles").render_target_update_mode==SubViewport.UPDATE_ALWAYS,"Independent debug scene retains live repair viewport")
	var coverage:=FileAccess.get_file_as_bytes("res://campuses/buct/data/library-ground-coverage.bin")
	check(coverage.size()==251*169,"Ground coverage ships as export-included binary geometry data")
	var coverage_data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://campuses/buct/data/library-ground-coverage.json"))
	var protected_count:=0;var unprotected_count:=0
	for polygon_data in coverage_data.protected_source_polygons:
		var polygon:=PackedVector2Array()
		for point in polygon_data:polygon.append(Vector2(point[0],point[1]))
		for y in range(169):
			for x in range(251):
				if Geometry2D.is_point_in_polygon(Vector2(620+x+0.5,410+y+0.5),polygon):
					protected_count+=1
					if coverage[y*251+x]!=255:unprotected_count+=1
	check(protected_count>33000 and unprotected_count==0,"All source body and old-shadow pixel centers have fully opaque replacement ground")
	check(coverage.count(0)>4000,"Peripheral source trees/paths remain visible through geometry-limited ground coverage")
	var bodies:=0
	var genuine_count:=0
	var legacy_count:=0
	for item: Dictionary in data.objects:
		var object: Node2D=objects.get_node(item.id)
		check(object.position==Vector2(item.anchor[0],item.anchor[1]),"Object source position: "+item.id)
		if item.id=="library":
			genuine_count+=1
			check(not object.has_node("SourcePixelSilhouette") and not object.has_node("SourceBakedCastShadow"),"Old library UV body and baked-shadow nodes retired")
			check(object.body_image.get_size()==Vector2i(1570,1001),"Library uses its own complete true-RGBA image")
			check(object.collision_shapes.size()==6 and object.physics_body is StaticBody2D,"Library has one native body with six inferred source-footprint polygons")
			check(object.depth_columns.size()>0 and object.y_sort_enabled,"Genuine RGBA columns use native facade-foot Y-sort")
			check(object.depth_columns.all(func(column):return column is Polygon2D and column.z_index==0),"Library columns share the old objects/tree/player z layer")
			check(object.hit_test_alpha(Vector2(750,500)) and not object.hit_test_alpha(Vector2(620,420)),"Library selection uses true alpha")
			var ground: Sprite2D=scene.get_node("LibraryContinuousGround")
			var transform_before: Transform2D=ground.transform
			var physics_before: Vector2=object.physics_body.global_position
			object.position+=Vector2(23,-19)
			check(object.physics_body.global_position==physics_before+Vector2(23,-19),"Genuine library physics follows movement")
			check(ground.transform==transform_before and ground.position==Vector2(620,410),"Continuous library ground remains fixed at extended source rect")
			object.hide();check(object.physics_body.collision_layer==0 and not object.hit_test_alpha(Vector2(750,500)),"Native library hide disables physics and alpha selection")
			object.show();object.reset_building()
			check(object.physics_body.collision_layer==1 and object.position==Vector2(749,570),"Genuine library reset restores source anchor and physics")
			check(not scene.has_node("CleanUnderlay_library") and not scene.has_node("CleanShadowUnderlay_library"),"Old library placeholder underlays retired")
			bodies+=1
			continue
		legacy_count+=1
		var silhouette: Polygon2D=object.get_node("SourcePixelSilhouette")
		var pixels_match:=true
		for i in range(silhouette.polygon.size()):pixels_match=pixels_match and silhouette.polygon[i]+object.position==silhouette.uv[i]
		check(pixels_match,"Unscaled exact source UVs: "+item.id)
		var footprints: Array[Node]=[]
		for child in object.get_children():
			if child is StaticBody2D:footprints.append(child);bodies+=1
		check(footprints.size()==item.footprints.size(),"Authored building physics preserved: "+item.id)
		var previous: Vector2=footprints[0].global_position
		object.position+=Vector2(23,-19)
		check(footprints[0].global_position==previous+Vector2(23,-19),"Independent collider follows object move: "+item.id)
		object.hide()
		check(footprints.all(func(body: Node):return body.collision_layer==0),"Hidden object disables only its own physics: "+item.id)
		object.position=Vector2(item.anchor[0],item.anchor[1]);object.show()
		check(footprints.all(func(body: Node):return body.collision_layer==1),"Restored object recovers its physics: "+item.id)
	check(bodies==88,"87 legacy collision bodies plus one six-polygon genuine library body")
	check(genuine_count==1 and legacy_count==43,"No claim that remaining 43 source-UV groups are rebuilt")
	scene.queue_free();await process_frame
	print("BUCT_SOURCE_LAYERS: %d checks; %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
