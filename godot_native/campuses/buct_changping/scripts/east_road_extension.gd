extends Node2D
## One additive paved road. Source-leaf foreground has no physics or trunk.
var profile: Dictionary
var original_nearby: Array[PackedVector2Array] = []
var exposed_edges: Array[PackedVector2Array] = []
var guard_rect := Rect2()
var leaf_nodes: Array[Node2D] = []

static func install(campus: Node2D) -> Node2D:
	var extension = load("res://campuses/buct_changping/scripts/east_road_extension.gd").new()
	extension.name = "EastRoadOriginalLeafForeground"
	extension.profile = JSON.parse_string(FileAccess.get_file_as_string("res://campuses/buct_changping/data/east_road_extension.json"))
	extension.y_sort_enabled = true
	campus.objects.add_child(extension)
	campus.walk_polys.append(campus.pts(extension.profile.polygon_source_xy))
	for poly in extension.profile.original_nearby_polygons:extension.original_nearby.append(campus.pts(poly))
	for edge in extension.profile.exposed_union_boundary_segments:extension.exposed_edges.append(campus.pts(edge))
	var r: Array = extension.profile.new_feet_guard_rect
	extension.guard_rect = Rect2(r[0],r[1],r[2],r[3])
	extension._add_source_leaves(campus.SOURCE.get_image())
	return extension

func was_original_paving(p: Vector2) -> bool:
	for offset in [Vector2.ZERO,Vector2(3,0),Vector2(-3,0),Vector2(0,3),Vector2(0,-3)]:
		var inside := false
		for poly in original_nearby:
			if Geometry2D.is_point_in_polygon(p+offset,poly):inside=true;break
		if not inside:return false
	return true

func allows_feet(p: Vector2) -> bool:
	if not guard_rect.has_point(p) or was_original_paving(p):return true
	# Only new feet permissions receive the full circle check. Old permissions
	# are preserved. Edges are from the UNION, so overlaps create no air walls.
	for edge in exposed_edges:
		if p.distance_squared_to(Geometry2D.get_closest_point_to_segment(p,edge[0],edge[1])) < 9.0-0.0001:return false
	return true

func _add_source_leaves(source: Image) -> void:
	for item in profile.foliage:
		var spans: Array = item.source_spans_y_x0_x1_exclusive
		var left := 950;var right := 0
		for span in spans:left=mini(left,int(span[1]));right=maxi(right,int(span[2]))
		var top := int(spans[0][0]);var bottom := int(spans[-1][0])+1
		var crop := Image.create(right-left,bottom-top,false,Image.FORMAT_RGBA8)
		crop.fill(Color.TRANSPARENT)
		for span in spans:
			for x in range(int(span[1]),int(span[2])):crop.set_pixel(x-left,int(span[0])-top,source.get_pixel(x,int(span[0])))
		var layer := Node2D.new();layer.name=str(item.id);layer.position=Vector2(0,float(item.baseline_y))
		var sprite := Sprite2D.new();sprite.name="ExactOriginalLeafPixels";sprite.centered=false
		sprite.texture=ImageTexture.create_from_image(crop);sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position=Vector2(left,top)-layer.position
		layer.add_child(sprite);add_child(layer);leaf_nodes.append(layer)
