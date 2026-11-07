extends SceneTree
## Broad phase must return exactly the original full polygon intersection result.
const Layered = preload("res://scripts/presentation/campus_layered_map.gd")
var checks := 0
var failures := 0
func _initialize() -> void:
	run.call_deferred()
func check(value: bool,label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("Solid broad phase: "+label)
func box(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
func original(art: RefCounted,feet: Rect2) -> int:
	if not art.ready: return -1
	for region: Dictionary in art.water_regions:
		if not feet.intersects(region.bounds): continue
		for water: Rect2 in region.rects:
			if feet.intersects(water): return 0
	var shape := box(feet)
	for polygon: PackedVector2Array in art.solid_polygons:
		if not Geometry2D.intersect_polygons(shape,polygon).is_empty(): return 0
	return -1
func same(art: RefCounted,feet: Rect2,label: String) -> void:
	check(art.navigation_decision(feet,Callable(),true)==original(art,feet),label)
func run() -> void:
	var art := Layered.new()
	art.ready = true
	var a := box(Rect2(100,100,20,20))
	var concave := PackedVector2Array([Vector2(150,100),Vector2(180,100),Vector2(180,110),Vector2(160,110),Vector2(160,130),Vector2(150,130)])
	art.solid_polygons = [a,concave]
	for feet: Rect2 in [Rect2(80.5,101,19.5,14.625),Rect2(80.501,101,19.5,14.625),Rect2(120,101,19.5,14.625),Rect2(119.999,101,19.5,14.625),Rect2(101,85.375,19.5,14.625),Rect2(101,85.376,19.5,14.625),Rect2(161,111,10,10),Rect2(149.999,111,10,10),Rect2(100,100,0.001,0.001)]:
		same(art,feet,"edge contact, tiny overlap or concave cutout")
	# Fill then invalidate an existing cache through every supported mutation.
	same(art,Rect2(100,100,10,10),"warm cache")
	art.solid_polygons = [box(Rect2(210,210,10,10)),concave]
	same(art,Rect2(210,210,10,10),"same-size array replacement invalidates cached bounds")
	art.solid_polygons[0] = box(Rect2(30,30,10,10))
	same(art,Rect2(30,30,10,10),"same-array same-length polygon replacement invalidates cache")
	art.solid_polygons[0][0] = Vector2(5,5)
	same(art,Rect2(5,5,5,5),"in-place vertex change invalidates cache")
	art.solid_polygons.append(box(Rect2(50,50,10,10)))
	same(art,Rect2(50,50,10,10),"append invalidates cache")
	art.solid_polygons.remove_at(0)
	same(art,Rect2(5,5,5,5),"remove invalidates cache")
	var random := RandomNumberGenerator.new()
	random.seed = 755163
	for i in range(800):
		var feet := Rect2(random.randf_range(0,230),random.randf_range(0,230),random.randf_range(0.001,40),random.randf_range(0.001,30))
		same(art,feet,"random exact geometry differential "+str(i))
	var water := Rect2(20,20,1,1)
	art.water_regions = [{"bounds":water,"rects":[water]}]
	same(art,Rect2(15,15,10,10),"water priority unchanged")
	art.release()
	check(art._solid_polygons_snapshot.is_empty() and art._solid_bounds_cache.is_empty(),"release clears geometry cache")
	art.ready = true
	art.solid_polygons = [box(Rect2(200,200,2,2))]
	same(art,Rect2(200,200,1,1),"new geometry after release still blocks")
	print("Solid broad phase: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
