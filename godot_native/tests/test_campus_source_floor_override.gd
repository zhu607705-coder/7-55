extends SceneTree
## Synthetic contract for replacing a local source-floor area, without textures.
## Run with the real godot_native project and an isolated user-data directory.
## Deliberately never attaches World to the tree or calls configure/refresh_world.
const Layered = preload("res://scripts/presentation/campus_layered_map.gd")
const Metrics = preload("res://scripts/player_metrics.gd")
const Spatial = preload("res://scripts/space/spatial_rules.gd")
const SOURCE_DEFINITION := {"cellSize":4,"gridWidth":64,"gridHeight":64}
const OVERRIDE := Rect2(80,80,80,80)
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("Source-floor override: " + label)

func filled_bits(width: int, height: int) -> PackedByteArray:
	var bits := PackedByteArray()
	bits.resize(ceili(float(width * height) / 8.0))
	bits.fill(255)
	return bits

func support(id: String, area: Rect2i) -> Dictionary:
	return {"id":id,"origin":Vector2(area.position),"width":area.size.x,"height":area.size.y,
		"bits":filled_bits(area.size.x,area.size.y),"bounds":Rect2(area)}

func anchor_for_rect(top_left: Vector2) -> Vector2:
	return top_left - Metrics.foot_rect(Vector2.ZERO,"campus_bootstrap").position

func polygon(area: Rect2) -> PackedVector2Array:
	return PackedVector2Array([area.position,Vector2(area.end.x,area.position.y),area.end,Vector2(area.position.x,area.end.y)])

func remove_pixel(row: Dictionary, pixel: Vector2i) -> Dictionary:
	var result := row.duplicate(true)
	var local := pixel - Vector2i(result.origin)
	var index: int = local.y * int(result.width) + local.x
	var bits: PackedByteArray = result.bits
	bits[index / 8] &= ~(1 << (index % 8))
	result.bits = bits
	return result

func run() -> void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated save")
	if failures:
		quit(1)
		return
	var state = root.get_node("State")
	state.developer_mode = true
	state.d = state.initial()
	var art := Layered.new()
	art.ready = true
	art.source_floor_overrides = [OVERRIDE]
	var road := support("new_58px_road",Rect2i(90,80,58,80))
	art.walk_supports = [road]
	var source := filled_bits(64,64)
	var source_before := source.duplicate()
	var world = load("res://scripts/world.gd").new()
	world.scene_id = "campus_bootstrap"
	world.world_size = Vector2(256,256)
	world._floor_bounds = Rect2(0,0,256,256)
	world.mask = source
	world.mask_meta = SOURCE_DEFINITION.duplicate()
	world.campus_layers = art
	check(not world.is_inside_tree() and art.textures.is_empty(),"synthetic world loads no map textures or scene lifecycle")
	check(Metrics.foot_rect(Vector2.ZERO,"campus_bootstrap").size == Vector2(16,10),"approved campus full 16 x 10 foot")
	check(Metrics.foot_center_offset("campus_bootstrap") == Vector2(0,36.5625),"approved campus foot anchor offset")

	var inside := Rect2(100.25,100.2,16,10)
	var old_shoulder := Rect2(79.75,100.2,16,10)
	check(Spatial.mask_allows_rect(old_shoulder,source,SOURCE_DEFINITION),"fixture old broad source floor would admit shoulder")
	check(art.source_floor_override_intersects(old_shoulder),"partial-foot override intersection is detected")
	check(art._source_floor_at(Vector2(79.999,100),source,SOURCE_DEFINITION),"source floor immediately west of override stays")
	check(not art._source_floor_at(Vector2(80,100),source,SOURCE_DEFINITION),"override inclusive west edge retires source floor")
	check(not art._source_floor_at(Vector2(159.999,100),source,SOURCE_DEFINITION),"source floor inside override is retired")
	check(art._source_floor_at(Vector2(160,100),source,SOURCE_DEFINITION),"override exclusive east edge keeps source floor")
	check(art.navigation_decision(old_shoulder,Callable(),true) == -1,"replacement domain is unsupported floor, never a solid wall")
	check(art.reviewed_support_covers(inside,source,SOURCE_DEFINITION),"new road replaces old source floor")
	check(world.can_stand(anchor_for_rect(inside.position)),"world accepts full foot on reviewed new road")
	check(not art.reviewed_support_covers(old_shoulder,source,SOURCE_DEFINITION),"old source floor cannot fill retired shoulder")
	check(not world.can_stand(anchor_for_rect(old_shoulder.position)),"world forces override check even when old source mask accepts")
	check(world.can_stand(anchor_for_rect(Vector2(60.25,100.2))),"world preserves original floor wholly outside override")
	check(world.can_stand(anchor_for_rect(Vector2(100.25,75.2))),"full foot crosses north seam using source plus new road")
	check(world.can_stand(anchor_for_rect(Vector2(100.25,150.2))),"full foot crosses south seam using source plus new road")
	check(not art.source_floor_override_intersects(Rect2(64,100,16,10)),"touching replacement edge alone is not an intersection")
	check(world.can_stand(anchor_for_rect(Vector2(64,100))),"touching override edge does not create a wall")

	for x: float in [90.0,132.0]:
		check(world.can_stand(anchor_for_rect(Vector2(x,100.2))),"exact road edge supports whole foot at x="+str(x))
	for x: float in [89.999,132.001]:
		check(not world.can_stand(anchor_for_rect(Vector2(x,100.2))),"fractional unsupported foot strip rejects at x="+str(x))
	art.walk_supports.append(support("independent_reviewed_junction",Rect2i(80,80,10,80)))
	check(art.reviewed_support_covers(old_shoulder,source,SOURCE_DEFINITION),"other explicit support unions with road and outside source")
	check(world.can_stand(anchor_for_rect(old_shoulder.position)),"override does not block another reviewed support")
	art.walk_supports = [road]
	art.walk_supports[0] = remove_pixel(road,Vector2i(110,108))
	check(not world.can_stand(anchor_for_rect(inside.position)),"one unsupported pixel inside full foot cannot be filled by old source")
	art.walk_supports = [road]

	var hazard := Rect2(110.2,108.2,0.25,0.25)
	art.water_regions = [{"bounds":hazard,"rects":[hazard]}]
	check(not world.can_stand(anchor_for_rect(inside.position)),"true water overrides supported new road")
	art.water_regions = []
	art.solid_polygons = [polygon(hazard)]
	check(not world.can_stand(anchor_for_rect(inside.position)),"measured solid overrides supported new road")
	art.solid_polygons = []
	world.collisions = [{"x":hazard.position.x,"y":hazard.position.y,"width":hazard.size.x,"height":hazard.size.y}]
	check(not world.can_stand(anchor_for_rect(inside.position)),"existing collision/story gate retains priority after support")
	world.collisions = []
	check(world.can_stand(anchor_for_rect(inside.position)),"clearing unrelated hazard restores road without changing floor")

	# A diagonal foot corner only clips this one-pixel hole for ~0.01 world
	# units of travel. Source-cell cuts alone miss it; 1px edge refinement must
	# catch the interval, forward and backward, without shrinking the foot.
	var start := anchor_for_rect(Vector2(93.75,100.74))
	var finish := start + Vector2(4,4)
	check(world._floor_segment_clear(start,finish),"clear diagonal segment works within override")
	art.walk_supports[0] = remove_pixel(road,Vector2i(110,100))
	check(world.can_stand(start) and world.can_stand(finish),"diagonal-hole fixture endpoints are both legal")
	check(not world.can_stand(start.lerp(finish,0.06375)),"fixture really clips tiny hole between old source samples")
	check(not world._floor_segment_clear(start,finish),"forward segment catches subpixel-time one-pixel hole")
	check(not world._floor_segment_clear(finish,start),"reverse segment catches subpixel-time one-pixel hole")
	check(not world._floor_segment_clear(start,finish,[],true),"validated route nodes cannot bypass intermediate hole")
	art.walk_supports = [road]
	check(world._floor_segment_clear(start,finish),"restored support reopens same segment")

	var west := anchor_for_rect(Vector2(55,100))
	var east := anchor_for_rect(Vector2(165,100))
	check(world.can_stand(west) and world.can_stand(east),"unsupported-domain crossing starts and ends on unchanged source")
	check(not world._floor_segment_clear(west,east),"path cannot jump across unsupported old shoulders")
	var seam_start := anchor_for_rect(Vector2(105,60))
	var seam_end := anchor_for_rect(Vector2(105,165))
	check(world._floor_segment_clear(seam_start,seam_end),"segment crosses both domain seams along new road")
	check(world._floor_segment_clear(seam_end,seam_start),"seam-crossing segment works in reverse")
	var path_hazard := Rect2(110,130,0.25,0.25)
	art.water_regions = [{"bounds":path_hazard,"rects":[path_hazard]}]
	check(not world._floor_segment_clear(seam_start,seam_end),"swept water blocks otherwise fully supported envelope")
	art.water_regions = []
	art.solid_polygons = [polygon(path_hazard)]
	check(not world._floor_segment_clear(seam_start,seam_end),"swept solid blocks otherwise fully supported envelope")
	art.solid_polygons = []
	world.collisions = [{"x":110,"y":130,"width":0.25,"height":0.25}]
	check(not world._floor_segment_clear(seam_start,seam_end),"story collision blocks supported fast-path segment")
	world.collisions = []

	art.walk_supports = []
	check(art.walk_support_intersects(inside),"override still enables path refinement with no support bounds")
	check(not world.can_stand(anchor_for_rect(inside.position)),"missing reviewed replacement fails closed inside override")
	check(world.can_stand(anchor_for_rect(Vector2(60.25,100.2))),"missing replacement does not erase outside source")
	check(world.mask == source_before and source == source_before,"source bitset itself remains byte-for-byte unchanged")
	art.ready = false
	check(not world.can_stand(anchor_for_rect(inside.position)),"campus still fails closed when layered renderer is not ready")
	art.ready = true
	art.walk_supports = [road]
	art.release()
	check(art.source_floor_overrides.is_empty() and art.walk_supports.is_empty(),"release clears replacement and support state")
	check(not art.ready and art.textures.is_empty(),"release retains no ready flag or map textures")
	world.free()
	print("Campus source-floor override: ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
