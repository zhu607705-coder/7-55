extends SceneTree
## Exact byte-run shortcut must equal a simple per-pixel reference. No textures.
const Layered = preload("res://scripts/presentation/campus_layered_map.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("Single-support fast path: " + label)

func filled_support(origin: Vector2, width: int, height: int) -> Dictionary:
	var bits := PackedByteArray()
	bits.resize(ceili(float(width * height) / 8.0))
	bits.fill(255)
	return {"id":"synthetic","origin":origin,"width":width,"height":height,"bits":bits,"bounds":Rect2(origin,Vector2(width,height))}

func without_pixel(support: Dictionary, x: int, y: int) -> Dictionary:
	var row := support.duplicate(true)
	var bits: PackedByteArray = row.bits
	var index: int = y * int(row.width) + x
	bits[index / 8] &= ~(1 << (index % 8))
	row.bits = bits
	return row

func brute_single(row: Dictionary, feet: Rect2) -> bool:
	if not row.bounds.encloses(feet): return false
	var origin: Vector2 = row.origin
	var low := Vector2i(floori(feet.position.x-origin.x),floori(feet.position.y-origin.y))
	var high := Vector2i(ceili(feet.end.x-origin.x),ceili(feet.end.y-origin.y))
	for y in range(low.y,high.y):
		for x in range(low.x,high.x):
			if x<0 or y<0 or x>=int(row.width) or y>=int(row.height): return false
			var index: int = y * int(row.width) + x
			if (row.bits[index / 8] & (1 << (index % 8))) == 0: return false
	return true

func run() -> void:
	var art := Layered.new()
	art.ready = true
	var random := RandomNumberGenerator.new()
	random.seed = 7551104
	# Include row widths that do not align to bytes. Row gaps must never leak
	# into the required mask, and an unoccupied neighboring bit must not reject.
	for width: int in [1,7,8,9,19,20,31,33,58]:
		for sample in range(40):
			var origin := Vector2(2153,3050) if sample%2 else Vector2(10,20)
			var row := filled_support(origin,width,20)
			if sample%3:
				for hole in range(width): row = without_pixel(row,random.randi_range(0,width-1),random.randi_range(0,19))
			art.walk_supports = [row]
			var x := random.randf_range(0,maxf(0,float(width)-0.1))
			var y := random.randf_range(0,18)
			var sx := random.randf_range(0.01,maxf(0.01,float(width)-x))
			var sy := random.randf_range(0.01,20-y)
			var feet := Rect2(origin+Vector2(x,y),Vector2(sx,sy))
			check(art._single_reviewed_support_covers(feet)==brute_single(row,feet),"byte mask equals per-pixel oracle width="+str(width)+" sample="+str(sample))

	var full := filled_support(Vector2(80,80),58,30)
	art.walk_supports = [full]
	var source := PackedByteArray()
	source.resize(512)
	source.fill(255)
	var definition := {"cellSize":4,"gridWidth":64,"gridHeight":64}
	art.source_floor_overrides = [Rect2(70,70,80,60)]
	var exact := Rect2(118.5,90.2,19.5,14.625)
	check(art._single_reviewed_support_covers(exact),"exact whole-foot road boundary is supported")
	check(not art._single_reviewed_support_covers(Rect2(118.501,90.2,19.5,14.625)),"0.001px unsupported east strip is not rounded away")
	check(not art.reviewed_support_covers(Rect2(118.501,90.2,19.5,14.625),source,definition),"override prevents old source from filling tiny outside strip")
	check(not art._single_reviewed_support_covers(Rect2(79.999,90.2,19.5,14.625)),"0.001px unsupported west strip is not rounded away")
	check(not art._single_reviewed_support_covers(Rect2(90.2,79.999,19.5,14.625)),"0.001px unsupported north strip is not rounded away")
	check(not art._single_reviewed_support_covers(Rect2(90.2,95.376,19.5,14.625)),"0.001px unsupported south strip is not rounded away")
	var feet := Rect2(90.25,90.2,19.5,14.625)
	art.walk_supports = [without_pixel(full,20,20)]
	check(not art._single_reviewed_support_covers(feet),"interior one-pixel hole blocks fast proof")
	check(not art.reviewed_support_covers(feet,source,definition),"override source cannot fill interior hole")
	art.walk_supports = [full]
	check(art.reviewed_support_covers(feet,source,definition),"full reviewed replacement passes despite source override")
	var water := Rect2(100,100,0.1,0.1)
	art.water_regions = [{"bounds":water,"rects":[water]}]
	check(not art.reviewed_support_covers(feet,source,definition),"water rejects before byte-run shortcut")
	art.water_regions = []
	art.solid_polygons = [PackedVector2Array([water.position,Vector2(water.end.x,water.position.y),water.end,Vector2(water.position.x,water.end.y)])]
	check(not art.reviewed_support_covers(feet,source,definition),"solid rejects before byte-run shortcut")
	art.solid_polygons = []
	art.source_floor_overrides = [Rect2(8,8,32,32)]
	var left := filled_support(Vector2(10,10),10,20)
	var right := filled_support(Vector2(20,10),14,20)
	art.walk_supports = [left,right]
	feet = Rect2(12.25,11.2,19.5,14.625)
	check(not art._single_reviewed_support_covers(feet),"no single support claims joint coverage")
	check(art.reviewed_support_covers(feet,source,definition),"fallback retains exact multi-support union across seam")
	art.walk_supports = [without_pixel(left,9,8),right]
	check(not art.reviewed_support_covers(feet,source,definition),"one-pixel hole at a support seam remains blocked")
	art.walk_supports.append(filled_support(Vector2(19,10),2,20))
	check(art.reviewed_support_covers(feet,source,definition),"independent overlapping support can legitimately fill seam hole")
	check(art.textures.is_empty(),"tests did not load textures")
	art.release()
	print("Single-support fast path: ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
