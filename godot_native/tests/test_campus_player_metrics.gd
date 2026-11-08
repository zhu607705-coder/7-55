extends SceneTree
## Isolated geometry/physics regression, not graphical or manual-play evidence.
const Metrics = preload("res://scripts/player_metrics.gd")
const Layered = preload("res://scripts/presentation/campus_layered_map.gd")
const Spatial = preload("res://scripts/space/spatial_rules.gd")
const CAMPUS := "campus_bootstrap"
const SOURCE := {"cellSize":4,"gridWidth":64,"gridHeight":64}
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool,label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("Campus player metrics: "+label)

func filled_bits(width: int,height: int) -> PackedByteArray:
	var bits := PackedByteArray()
	bits.resize(ceili(float(width*height)/8.0))
	bits.fill(255)
	return bits

func anchor(center: Vector2) -> Vector2:
	return Metrics.anchor_from_foot_center(center,CAMPUS)

func anchor_for_rect(top_left: Vector2) -> Vector2:
	return top_left-Metrics.foot_rect(Vector2.ZERO,CAMPUS).position

func polygon(area: Rect2) -> PackedVector2Array:
	return PackedVector2Array([area.position,Vector2(area.end.x,area.position.y),area.end,Vector2(area.position.x,area.end.y)])

func run() -> void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated save")
	if failures:
		quit(1)
		return
	var state = root.get_node("State")
	state.developer_mode = true
	state.d = state.initial()
	var before: Dictionary = state.d.duplicate(true)
	var sample := Vector2(800.25,500.75)
	var approved := Rect2(sample+Vector2(-8,31.5625),Vector2(16,10))
	check(Metrics.foot_rect(sample)==approved,"default walking geometry is the approved 16 x 10 box")
	for scene: String in [CAMPUS,"dorm_hub","library_interior","canteen_interior","theater_interior","qizhen_lake","campus_qizhen_loop","duan_yongping_temporal_maze",""]:
		var expected:=Rect2(sample+Vector2(-18,31.5625),Vector2(36,10)) if scene=="library_interior" else approved
		check(Metrics.foot_rect(sample,scene)==expected and Metrics.foot_size(scene)==expected.size,"shared depth and scene walking width: "+scene)
		check(Metrics.anchor_from_foot_center(Metrics.foot_center(sample,scene),scene)==sample,"exact tap/anchor inverse: "+scene)
	check(Metrics.depth_y(sample)==sample.y+31.6875,"campus depth stays at the pre-change reference")
	check(Metrics.ground_depth_y(sample)==sample.y+39.0,"interior depth stays at the pre-change reference")
	check(Metrics.depth_y(sample)!=Metrics.foot_center(sample,CAMPUS).y,"physical and rendering anchors are independent")
	var visual := Metrics.visual_rect(sample,Metrics.scale_at(CAMPUS,sample.y))
	check(visual.position.is_equal_approx(sample-Vector2(15.6,0)) and visual.size.is_equal_approx(Vector2(31.2,41.6)),"campus sprite position and .325 scale are unchanged")
	for direction: String in ["down","side","up"]:
		for index: int in range(8):
			var texture: Texture2D = load("res://assets/rpg/player/player_%s_%d.png" % [direction,index])
			var image := texture.get_image()
			var bottom := float(image.get_used_rect().end.y)*.325
			check(image.get_size()==Vector2i(96,128) and is_equal_approx(bottom,40.95),"original shoe endpoint: "+direction+str(index))
			check(bottom>31.5625 and bottom<41.5625,"shoe lies inside lower collision band: "+direction+str(index))

	var art := Layered.new()
	art.ready = true
	var road := {"id":"reviewed_test_road","origin":Vector2(90,80),"width":58,"height":80,"bits":filled_bits(58,80),"bounds":Rect2(90,80,58,80),"routeCandidateFootCenters":PackedVector2Array([Vector2(110,100),Vector2(110,140)])}
	art.walk_supports = [road]
	art.source_floor_overrides = [Rect2(80,80,80,80)]
	var world = load("res://scripts/world.gd").new()
	world.scene_id = CAMPUS
	world.world_size = Vector2(256,256)
	world._floor_bounds = Rect2(0,0,256,256)
	world.mask = filled_bits(64,64)
	world.mask_meta = SOURCE.duplicate()
	world.campus_layers = art
	var source_before: PackedByteArray = world.mask.duplicate()
	check(world._floor_anchor_bounds(Rect2(0,0,256,256))==Rect2(8,-31.5625,240,246),"visible route bounds use the whole shared foot box")
	for x: float in [90,132]:
		check(world.can_stand(anchor_for_rect(Vector2(x,100))),"exact road width permits campus feet at "+str(x))
	for x: float in [89.99,132.01]:
		check(not world.can_stand(anchor_for_rect(Vector2(x,100))),"fractional unsupported strip still rejects at "+str(x))
	var point := anchor(Vector2(110,100))
	world.player = point
	var candidates: Array[Vector2] = world._floor_campus_detour_nodes(anchor(Vector2(110,140)))
	check(candidates.has(anchor(Vector2(110,100))) and candidates.has(anchor(Vector2(110,140))),"reviewed route centers convert using campus offset")
	var box := Rect2(100,120,10,10)
	world.collisions = [{"x":100,"y":120,"width":10,"height":10}]
	check(world._floor_obstacles()==[Rect2(92,78.4375,26,20)],"route Minkowski obstacles use exact 16 x 10 lower feet")
	world.collisions = []
	var path_start := anchor(Vector2(110,90))
	var path_end := anchor(Vector2(110,150))
	check(world._floor_segment_clear(path_start,path_end) and world._floor_segment_clear(path_end,path_start),"supported campus segment works both ways")
	var hazard := Rect2(110,120,.25,.25)
	art.water_regions = [{"bounds":hazard,"rects":[hazard]}]
	check(not world.can_stand(anchor(Vector2(110,120))),"full campus foot still rejects true water")
	check(not world._floor_segment_clear(path_start,path_end),"swept water still blocks supported fast path")
	art.water_regions = []
	art.solid_polygons = [polygon(hazard)]
	check(not world.can_stand(anchor(Vector2(110,120))),"full campus foot still rejects measured solids")
	check(not world._floor_segment_clear(path_start,path_end),"swept solids still block supported fast path")
	art.solid_polygons = []
	world.collisions = [{"x":110,"y":120,"width":.25,"height":.25}]
	check(not world._floor_segment_clear(path_start,path_end),"story obstacles still block supported fast path")
	world.collisions = []
	# At both endpoints the new 16px foot misses the hole. Its northeast
	# corner only overlaps for t in (.0625,.065), so sampling cannot suffice.
	var start := anchor_for_rect(Vector2(93.75,100.74))
	var finish := start+Vector2(4,4)
	var bits: PackedByteArray = road.bits.duplicate()
	var hole: int = (100-80)*58+(110-90)
	bits[hole/8] &= ~(1<<(hole%8))
	art.walk_supports[0] = road.duplicate(true)
	art.walk_supports[0].bits = bits
	check(world.can_stand(start) and world.can_stand(finish),"new-foot tiny-hole endpoints are legal")
	check(not world.can_stand(start.lerp(finish,.06375)),"new-foot tiny-hole interior is genuinely blocked")
	check(not world._floor_segment_clear(start,finish) and not world._floor_segment_clear(finish,start),"exact 1px support sweep catches tiny overlap both ways")
	check(not world._floor_segment_clear(start,finish,[],true),"validated-node fast path cannot skip new-foot hole")
	art.walk_supports = [road]
	check(world._floor_segment_clear(start,finish),"restored support reopens same exact segment")
	for scene: String in ["campus_bootstrap","library_interior","canteen_interior","campus_qizhen_loop","duan_yongping_temporal_maze","campus_bootstrap"]:
		world.scene_id = scene
		world.collisions = [{"x":100,"y":120,"width":10,"height":10}]
		var local_foot := Metrics.foot_rect(Vector2.ZERO,scene)
		check(world._floor_obstacles().has(Rect2(box.position-local_foot.end,box.size+local_foot.size)),"routing uses the active footprint after changing scenes: "+scene)
	world.collisions = []
	check(world.mask==source_before and art.walk_supports==[road] and state.d==before,"metrics/physics checks do not alter source floor, obstacles or story state")
	check(not world.is_inside_tree() and art.textures.is_empty(),"isolated physics fixture does not load scene artwork")
	var code := FileAccess.get_file_as_string("res://scripts/world.gd")
	check(code.count("PlayerMetrics.depth_y(player)")==2,"both campus render passes use preserved depth")
	check(not code.contains("PlayerMetrics.FOOT_CENTER_OFFSET"),"world collision/tap paths cannot read unscoped default offset")
	world.free()
	print("Campus player metrics: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
