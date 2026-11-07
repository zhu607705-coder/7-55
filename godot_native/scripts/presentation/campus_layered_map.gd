extends RefCounted
## The north-up campus only. Artwork never owns story state or checkpoint gates.
## Each layer retains its own textures and calibrated uniform world transform.
const MANIFEST := "res://data/native/campus_layered_map.json"
const WORLD_SIZE := Vector2(4516, 3420)
var manifest: Dictionary = {}
var textures: Dictionary = {}
var ready := false
var errors: Array[String] = []
var category_visibility: Dictionary = {}
var solid_polygons: Array[PackedVector2Array] = []
var _solid_polygons_snapshot: Array[PackedVector2Array] = []
var _solid_bounds_cache: Array[Rect2] = []
var floor_polygons: Array[PackedVector2Array] = []
var water_regions: Array[Dictionary] = []
var walk_supports: Array[Dictionary] = []
var source_floor_overrides: Array[Rect2] = []
var max_texture_dimension := 0
var _raised_order_cache: Array[Dictionary] = []
var _raised_order_layers: Array = []
var _raised_order_layer_count := -1

func configure() -> bool:
	if ready: return true
	errors.clear()
	if not FileAccess.file_exists(MANIFEST):
		errors.append("Missing campus layer manifest")
		return false
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not value is Dictionary or value.get("format", "") != "755-campus-layered-map-v1":
		errors.append("Invalid campus layer manifest")
		return false
	errors.append_array(validate_semantics(value))
	if not errors.is_empty(): return false
	var pending: Dictionary = {}
	for row: Dictionary in value.get("layers", []):
		if float(row.get("scale", 0)) <= 0:
			errors.append("Invalid uniform scale: " + str(row.id))
		for tile: Dictionary in row.get("tiles", []):
			var path := str(tile.path)
			if not ResourceLoader.exists(path):
				errors.append("Missing campus layer: " + path)
				continue
			var texture := load(path) as Texture2D
			if texture == null or maxf(texture.get_width(), texture.get_height()) > 2048:
				errors.append("Invalid campus tile: " + path)
			else: pending[path] = texture
	# Only pre-masked world tiles may animate; never tile water under all land.
	if value.get("waterTiles", []).is_empty(): errors.append("Missing true-water tiles")
	for tile: Dictionary in value.get("waterTiles", []):
		var bounds: Array = tile.get("rect", [])
		var frames: Array = tile.get("frames", [])
		if bounds.size() != 4 or frames.size() != 3:
			errors.append("Invalid masked water tile")
			continue
		for path_value: Variant in frames:
			var path := str(path_value)
			if not ResourceLoader.exists(path):
				errors.append("Missing masked water frame: " + path)
				continue
			var water := load(path) as Texture2D
			if water == null or water.get_size() != Vector2(bounds[2], bounds[3]) or maxf(water.get_width(), water.get_height()) > 2048:
				errors.append("Invalid masked water frame: " + path)
			else: pending[path] = water
	if not errors.is_empty(): return false
	manifest = value
	invalidate_render_order()
	_ordered_raised_rows()
	water_regions.clear()
	for row: Dictionary in value.get("waterRegions", []):
		var base := Vector2(row.origin[0], row.origin[1])
		var factor := float(row.scale)
		var b: Array = row.nativeBounds
		var rectangles: Array[Rect2] = []
		for r: Array in row.rectsNative:
			rectangles.append(Rect2(base + Vector2(r[0], r[1]) * factor, Vector2(r[2], r[3]) * factor))
		water_regions.append({"id":row.id, "bounds":Rect2(base + Vector2(b[0], b[1]) * factor, Vector2(b[2], b[3]) * factor), "rects":rectangles})
	walk_supports.clear()
	source_floor_overrides.clear()
	for row: Dictionary in value.get("walkSupports", []):
		if row.has("sourceFloorOverrideRect"):
			var replacement: Array = row.sourceFloorOverrideRect
			if replacement.size() != 4 or float(replacement[2]) <= 0 or float(replacement[3]) <= 0:
				errors.append("Invalid source-floor replacement: " + str(row.id))
				continue
			var integer_edges := true
			for coordinate: Variant in replacement:
				if not (coordinate is int or coordinate is float) or not is_finite(float(coordinate)) or float(coordinate) != floorf(float(coordinate)): integer_edges = false
			if not integer_edges:
				errors.append("Source-floor replacement must use integer pixel edges: " + str(row.id))
				continue
			source_floor_overrides.append(Rect2(replacement[0], replacement[1], replacement[2], replacement[3]))
		var dimensions: Array = row.nativeSize
		var bits := Marshalls.base64_to_raw(str(row.bitsBase64))
		var width := int(dimensions[0])
		var height := int(dimensions[1])
		if width <= 0 or height <= 0 or bits.size() != ceili(float(width * height) / 8.0):
			errors.append("Invalid reviewed walk-support bitset: " + str(row.id))
			continue
		var origin := Vector2(row.origin[0], row.origin[1])
		var b: Array = row.nativeBounds
		var candidates := PackedVector2Array()
		var candidate_rows: Variant = row.get("routeCandidateFootCenters", [])
		if not candidate_rows is Array or candidate_rows.size() > 192:
			errors.append("Invalid reviewed route candidates: " + str(row.id))
			continue
		for raw: Variant in candidate_rows:
			if not raw is Array or raw.size() != 2 or not (raw[0] is int or raw[0] is float) or not (raw[1] is int or raw[1] is float):
				errors.append("Invalid reviewed route candidate point: " + str(row.id))
				continue
			var point := Vector2(float(raw[0]), float(raw[1]))
			if not point.is_finite() or point.x < 0 or point.y < 0 or point.x > WORLD_SIZE.x or point.y > WORLD_SIZE.y:
				errors.append("Reviewed route candidate outside world: " + str(row.id))
				continue
			if not candidates.has(point): candidates.append(point)
		walk_supports.append({"id":row.id,"origin":origin,"width":width,"height":height,"bits":bits,"bounds":Rect2(origin+Vector2(b[0],b[1]),Vector2(b[2],b[3])),"routeCandidateFootCenters":candidates})
	if not errors.is_empty(): return false
	textures = pending
	solid_polygons.clear()
	floor_polygons.clear()
	for row: Dictionary in manifest.get("navigation", {}).get("footprints", []): solid_polygons.append(_polygon(row.polygon))
	_ensure_solid_bounds()
	for raw: Array in manifest.get("navigation", {}).get("walkablePolygons", []): floor_polygons.append(_polygon(raw))
	for texture: Texture2D in textures.values(): max_texture_dimension = maxi(max_texture_dimension, maxi(texture.get_width(), texture.get_height()))
	ready = not textures.is_empty()
	return ready

func release() -> void:
	# Do not carry the campus GPU textures through every later chapter.
	textures.clear()
	invalidate_render_order()
	manifest.clear()
	solid_polygons.clear()
	_solid_polygons_snapshot.clear()
	_solid_bounds_cache.clear()
	floor_polygons.clear()
	max_texture_dimension = 0
	water_regions.clear()
	walk_supports.clear()
	source_floor_overrides.clear()
	ready = false

func set_category_visible(category: String, enabled: bool) -> void:
	category_visibility[category] = enabled

func _visible(row: Dictionary) -> bool:
	return bool(category_visibility.get(str(row.get("category", "buildings")), true))

func _draw_layer(canvas: CanvasItem, row: Dictionary, origin: Vector2, zoom: float, view: Rect2, tint: Color, source_y_min: float = -INF, source_y_max: float = INF) -> void:
	var position := Vector2(float(row.origin[0]), float(row.origin[1]))
	var factor := float(row.scale)
	for tile: Dictionary in row.tiles:
		var source := Rect2(float(tile.rect[0]), float(tile.rect[1]), float(tile.rect[2]), float(tile.rect[3]))
		var top := maxf(source.position.y, source_y_min)
		var bottom := minf(source.end.y, source_y_max)
		if bottom <= top: continue
		var clipped := Rect2(source.position.x, top, source.size.x, bottom - top)
		var world := Rect2(position + clipped.position * factor, clipped.size * factor)
		if not world.intersects(view): continue
		canvas.draw_texture_rect_region(textures[str(tile.path)], Rect2(origin + world.position * zoom, world.size * zoom), Rect2(clipped.position - source.position, clipped.size), tint)

static func validate_semantics(value: Dictionary) -> Array[String]:
	var problems: Array[String] = []
	if int(value.get("semanticLayerVersion", 0)) != 2:
		problems.append("Campus resources require explicit ground/raised semantic version 2")
	for row: Dictionary in value.get("layers", []):
		var stage := str(row.get("renderPass", ""))
		var label := str(row.get("id", "unnamed"))
		if stage not in ["land", "ground", "roads", "raised"]:
			problems.append("Unknown semantic render pass: " + label)
		if stage == "raised":
			if not row.has("baseline") or not is_finite(float(row.get("baseline", INF))):
				problems.append("Raised object requires a measured world foot baseline: " + label)
			if row.get("depthMode", "baseline") == "projected_y":
				if row.has("depthOriginalOriginY"):
					if not is_finite(float(row.get("depthOriginalOriginY", INF))) or not is_finite(float(row.get("depthOriginalProjection", INF))) or float(row.get("depthOriginalScale", 0)) <= 0:
						problems.append("Invalid original projected depth transform: " + label)
				elif not row.has("projectionNative") or not is_finite(float(row.get("projectionNative", INF))):
					problems.append("Missing projected source depth: " + label)
			if str(row.get("depthMode", "baseline")) not in ["baseline", "projected_y"]:
				problems.append("Unknown raised depth mode: " + label)
		elif row.get("pass", "ground") in ["foreground", "depth_object"]:
			problems.append("Legacy depth content must be explicitly split into raised: " + label)
	return problems

func _render_pass(row: Dictionary) -> String:
	return str(row.get("renderPass", ""))

func _depth_split(row: Dictionary, foot_y: float) -> float:
	if row.has("depthOriginalOriginY"):
		var old_origin := float(row.depthOriginalOriginY)
		var old_scale := float(row.depthOriginalScale)
		var split_world := old_origin + floorf((foot_y - old_origin) / old_scale - float(row.depthOriginalProjection)) * old_scale
		return (split_world - float(row.origin[1])) / float(row.scale)
	return floorf((foot_y - float(row.origin[1])) / float(row.scale) - float(row.projectionNative))

func _draw_water(canvas: CanvasItem, origin: Vector2, zoom: float, view: Rect2, elapsed_ms: float) -> void:
	if not bool(category_visibility.get("water", true)): return
	for tile: Dictionary in manifest.get("waterTiles", []):
		var r: Array = tile.rect
		var bounds := Rect2(r[0], r[1], r[2], r[3])
		if not bounds.intersects(view): continue
		var frames: Array = tile.frames
		var index := int(elapsed_ms / 500.0) % frames.size()
		canvas.draw_texture_rect(textures[str(frames[index])], Rect2(origin + bounds.position * zoom, bounds.size * zoom), false)

func invalidate_render_order() -> void:
	# Configure/release own production invalidation. Tests or authoring tools
	# editing a row's baseline in place must call this explicitly.
	_raised_order_cache = []
	_raised_order_layers = []
	_raised_order_layer_count = -1

func _ordered_raised_rows() -> Array[Dictionary]:
	var layers: Array = manifest.get("layers", [])
	# Frozen manifests require no per-frame sorting or hash scan. Reference
	# replacement and append/remove are enough for direct-manifest test setup.
	if is_same(layers, _raised_order_layers) and layers.size() == _raised_order_layer_count:
		return _raised_order_cache
	var ordered: Array[Dictionary] = []
	var source_order := 0
	for row: Dictionary in layers:
		if _render_pass(row) == "raised": ordered.append({"row":row, "sourceOrder":source_order})
		source_order += 1
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var first := float(a.row.baseline)
		var second := float(b.row.baseline)
		return int(a.sourceOrder) < int(b.sourceOrder) if first == second else first < second)
	var rows: Array[Dictionary] = []
	for entry: Dictionary in ordered: rows.append(entry.row)
	_raised_order_cache = rows
	_raised_order_layers = layers
	_raised_order_layer_count = layers.size()
	return _raised_order_cache

func render_plan(foot_y: float, foreground: bool = false) -> Array[Dictionary]:
	# This plan is consumed by actual drawing and exposed for focused tests.
	# Ground never follows the actor. Raised pixels always follow roads and are
	# drawn exactly once, split around the actor only at an authored foot plane.
	var plan: Array[Dictionary] = []
	var stages: Array = ["raised"] if foreground else ["land", "water", "ground", "roads", "raised"]
	for stage: String in stages:
		if stage == "water":
			plan.append({"kind":"water"})
			continue
		var rows: Array = _ordered_raised_rows() if stage == "raised" else manifest.get("layers", [])
		for row: Dictionary in rows:
			if _render_pass(row) != stage or not _visible(row): continue
			var minimum := -INF
			var maximum := INF
			if stage == "raised":
				var actor_behind := foot_y < float(row.baseline)
				if not actor_behind:
					if foreground: continue
				elif row.get("depthMode", "baseline") == "projected_y":
					var split := _depth_split(row, foot_y)
					if foreground: minimum = split
					else: maximum = split
				elif not foreground: continue
			plan.append({"kind":"layer", "row":row, "sourceYMin":minimum, "sourceYMax":maximum})
	return plan

func _draw_plan(canvas: CanvasItem, origin: Vector2, zoom: float, viewport_size: Vector2, elapsed_ms: float, foot_y: float, foreground: bool, tint: Color) -> void:
	if not ready: return
	var view := Rect2(-origin / zoom, viewport_size / zoom)
	for item: Dictionary in render_plan(foot_y, foreground):
		if item.kind == "water": _draw_water(canvas, origin, zoom, view, elapsed_ms)
		else: _draw_layer(canvas, item.row, origin, zoom, view, tint, float(item.sourceYMin), float(item.sourceYMax))

func draw_background(canvas: CanvasItem, origin: Vector2, zoom: float, viewport_size: Vector2, elapsed_ms: float, foot_y: float = INF) -> void:
	_draw_plan(canvas, origin, zoom, viewport_size, elapsed_ms, foot_y, false, Color.WHITE)

func draw_foreground(canvas: CanvasItem, origin: Vector2, zoom: float, viewport_size: Vector2, foot_y: float, dark_mix: float) -> void:
	var tint := Color.WHITE.lerp(Color(.03, .15, .26), clampf(dark_mix, 0, 1) * .3)
	_draw_plan(canvas, origin, zoom, viewport_size, 0.0, foot_y, true, tint)

func snapshot() -> Dictionary:
	var unsegmented_count := 0
	for row: Dictionary in manifest.get("layers", []):
		if row.get("semanticCoverage", "") == "unsegmented_compound": unsegmented_count += 1
	return {"layered": true, "semanticLayerVersion": manifest.get("semanticLayerVersion", 0), "unsegmentedCompoundCount": unsegmented_count, "ready": ready, "source": MANIFEST, "sourceSize": WORLD_SIZE,
		"reviewStatus": manifest.get("reviewStatus", "review_candidate"), "layerCount": manifest.get("layers", []).size(), "tileCount": textures.size(), "maxTextureDimension": max_texture_dimension,
		"waterTileCount": manifest.get("waterTiles", []).size(), "waterFrame": "masked-only, 500ms", "walkSupportCount": walk_supports.size(), "waterRegionCount": water_regions.size(), "errors": errors.duplicate(), "navigation": "source floor plus explicit reviewed bridge/path support; water/solids/gates retain priority"}

func _polygon(raw: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	for p: Array in raw: points.append(Vector2(float(p[0]), float(p[1])))
	return points

func _ensure_solid_bounds() -> void:
	# Exact value comparison, not only count/array identity: synthetic callers
	# and live replacements may replace or mutate a polygon without resizing.
	if solid_polygons == _solid_polygons_snapshot: return
	_solid_polygons_snapshot = solid_polygons.duplicate(true)
	_solid_bounds_cache.clear()
	for polygon: PackedVector2Array in solid_polygons:
		var bounds := Rect2()
		if not polygon.is_empty():
			bounds = Rect2(polygon[0], Vector2.ZERO)
			for vertex: Vector2 in polygon: bounds = bounds.expand(vertex)
		_solid_bounds_cache.append(bounds)

func navigation_decision(feet: Rect2, source_support: Callable = Callable(), hazards_only: bool = false) -> int:
	# -1 delegates to unchanged source mask; 0 rejects a measured new solid;
	# 1 admits only a whole foot box covered by explicit reviewed floor regions.
	if not ready: return -1
	for region: Dictionary in water_regions:
		if not feet.intersects(region.bounds): continue
		for water: Rect2 in region.rects:
			if feet.intersects(water): return 0
	var box := PackedVector2Array([feet.position, Vector2(feet.end.x, feet.position.y), feet.end, Vector2(feet.position.x, feet.end.y)])
	_ensure_solid_bounds()
	for index in solid_polygons.size():
		# Reject only strict AABB separation. Edge contact still reaches the
		# original polygon algorithm, preserving its exact boundary semantics.
		if not feet.intersects(_solid_bounds_cache[index], true): continue
		if not Geometry2D.intersect_polygons(box, solid_polygons[index]).is_empty(): return 0
	if hazards_only or floor_polygons.is_empty(): return -1
	var overlaps_floor := false
	for polygon: PackedVector2Array in floor_polygons:
		if not Geometry2D.intersect_polygons(box, polygon).is_empty():
			overlaps_floor = true
			break
	if not overlaps_floor: return -1
	# Grid plus every edge, at <=2 world units, avoids the old five-point
	# false acceptance of thin slivers and planting beds between the corners.
	var columns := maxi(1, int(ceil(feet.size.x / 2.0)))
	var rows := maxi(1, int(ceil(feet.size.y / 2.0)))
	for y in range(rows + 1):
		for x in range(columns + 1):
			var point := feet.position + feet.size * Vector2(float(x) / columns, float(y) / rows)
			var supported := false
			for polygon: PackedVector2Array in floor_polygons:
				if Geometry2D.is_point_in_polygon(point, polygon):
					supported = true
					break
			# A foot crossing the seam may be supported partly by reviewed
			# new floor and partly by the unchanged original walk mask.
			if not supported and source_support.is_valid(): supported = bool(source_support.call(point))
			if not supported: return 0
	return 1

func source_floor_override_intersects(bounds: Rect2) -> bool:
	if not ready: return false
	for replacement: Rect2 in source_floor_overrides:
		if bounds.intersects(replacement): return true
	return false

func _source_floor_at(point: Vector2, bits: PackedByteArray, definition: Dictionary) -> bool:
	# Retired wide-road floor is not a solid. In this exact local rectangle,
	# only measured reviewed ground supports apply; all outside floor stays.
	for replacement: Rect2 in source_floor_overrides:
		if replacement.has_point(point): return false
	var cell := float(definition.get("cellSize", 0))
	var width := int(definition.get("gridWidth", 0))
	var height := int(definition.get("gridHeight", 0))
	if cell <= 0 or width <= 0 or height <= 0 or bits.size() * 8 < width * height: return false
	var x := floori(point.x / cell)
	var y := floori(point.y / cell)
	if x < 0 or y < 0 or x >= width or y >= height: return false
	var index := y * width + x
	return (bits[index / 8] & (1 << (index % 8))) != 0

func _reviewed_support_at(point: Vector2) -> bool:
	for support: Dictionary in walk_supports:
		if not support.bounds.has_point(point): continue
		var local: Vector2 = point - Vector2(support.origin)
		var x := floori(local.x)
		var y := floori(local.y)
		if x < 0 or y < 0 or x >= int(support.width) or y >= int(support.height): continue
		var index := y * int(support.width) + x
		var bits: PackedByteArray = support.bits
		if (bits[index / 8] & (1 << (index % 8))) != 0: return true
	return false

func _single_reviewed_support_covers(feet: Rect2) -> bool:
	# A positive result is an exact proof, not sampled coverage. Integer-origin
	# support pixels touched by any positive foot area must ALL be present.
	# Byte runs avoid repeating source/union lookups for every 1px cell.
	for support: Dictionary in walk_supports:
		if not support.bounds.encloses(feet): continue
		var low_corner := feet.position - Vector2(support.origin)
		var high_corner := feet.end - Vector2(support.origin)
		var x0 := floori(low_corner.x)
		var y0 := floori(low_corner.y)
		var x1 := ceili(high_corner.x) - 1
		var y1 := ceili(high_corner.y) - 1
		var width := int(support.width)
		if x0 < 0 or y0 < 0 or x1 >= width or y1 >= int(support.height): continue
		var bits: PackedByteArray = support.bits
		var covered := true
		for y in range(y0, y1 + 1):
			var first := y * width + x0
			var last := y * width + x1
			for byte_index in range(first / 8, last / 8 + 1):
				var low := first % 8 if byte_index == first / 8 else 0
				var high := last % 8 if byte_index == last / 8 else 7
				var required := ((1 << (high - low + 1)) - 1) << low
				if (bits[byte_index] & required) != required:
					covered = false
					break
			if not covered: break
		if covered: return true
	return false

func reviewed_support_covers(feet: Rect2, source_bits: PackedByteArray, source_definition: Dictionary) -> bool:
	if not ready or walk_supports.is_empty() or feet.size.x <= 0 or feet.size.y <= 0: return false
	# Reject physical hazards before considering any support exception.
	if navigation_decision(feet, Callable(), true) == 0: return false
	if _single_reviewed_support_covers(feet): return true
	var nearby := source_floor_override_intersects(feet)
	for support: Dictionary in walk_supports:
		if feet.intersects(support.bounds): nearby = true; break
	if not nearby: return false
	# Exact coverage union: split the whole foot at every support-pixel and
	# source-cell edge. A midpoint represents a constant-valued region, not a
	# five-point approximation; even a fractional unsupported strip rejects.
	var axes: Array = []
	var cell := float(source_definition.get("cellSize", 0))
	for axis in range(2):
		var first: float = feet.position[axis]
		var last: float = feet.end[axis]
		var cuts: Array[float] = [first, last]
		for edge in range(floori(first) + 1, ceili(last)):
			cuts.append(float(edge))
		if cell > 0:
			for edge in range(floori(first / cell) + 1, ceili(last / cell)):
				var boundary := float(edge) * cell
				if boundary > first and boundary < last and boundary not in cuts: cuts.append(boundary)
		cuts.sort()
		axes.append(cuts)
	var xs: Array = axes[0]
	var ys: Array = axes[1]
	for y in range(1, ys.size()):
		for x in range(1, xs.size()):
			var point := Vector2((float(xs[x-1])+float(xs[x]))*.5,(float(ys[y-1])+float(ys[y]))*.5)
			if not _source_floor_at(point, source_bits, source_definition) and not _reviewed_support_at(point): return false
	return true

func walk_support_intersects(bounds: Rect2) -> bool:
	if not ready: return false
	if source_floor_override_intersects(bounds): return true
	for support: Dictionary in walk_supports:
		if bounds.intersects(support.bounds): return true
	return false
