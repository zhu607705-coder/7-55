extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("BUCT LAYERS: "+message)
func run() -> void:
	var scene: Node2D=load("res://campuses/buct/scenes/registered_layers.tscn").instantiate()
	root.add_child(scene);await process_frame;await physics_frame
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://campuses/buct/data/layers.json"))
	var objects: Node2D=scene.get_node("IndependentRegisteredObjects")
	check(data.objects.size()==44 and objects.get_child_count()==44,"All 44 independent source objects remain native")
	check(scene.get_node("StaticUnseparatedCampus").texture.get_size()==Vector2(1448,1086),"Approved source dimensions remain unchanged")
	check(scene.get_node("GroundRepairTiles/SourcePaving16px") is TileMapLayer,"Repair ground remains native TileMapLayer")
	check(scene.get_node("GroundRepairTiles/SourcePaving16px").get_used_cells().size()==6188,"All 6188 repair cells are preserved")
	var bodies:=0
	for item: Dictionary in data.objects:
		var object: Node2D=objects.get_node(item.id)
		check(object.position==Vector2(item.anchor[0],item.anchor[1]),"Object source position: "+item.id)
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
	check(bodies==91,"All 91 source building collision outlines preserved")
	scene.queue_free();await process_frame
	print("BUCT_SOURCE_LAYERS: %d checks; %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
