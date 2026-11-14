extends RefCounted
## Two physical lanes. Swipe, direction, sensors and wing motion stay local.
## The chapter controller records the first actual inward passage.
const Metrics = preload("res://scripts/player_metrics.gd")
const Rules = preload("res://scripts/space/spatial_rules.gd")
const Picker = preload("res://scripts/world_object_picker.gd")
const LAYOUT_PATH := "res://data/native/library-entrance-geometry.json"
const SCENE_ID := "library_interior"
const READER_IDS := ["entrance_record", "entrance_record_east"]
const READER_CABINETS := [0, 2]
const INWARD := -1
const OUTWARD := 1
const SCAN_SECONDS := .28
const PASS_SECONDS := 5.0
const WING_TOP := 32.0
const WING_BOTTOM := 8.0
const WING_THICKNESS := 2.0
const SWING_DEPTH := .78
const RAIL_HALF_DEPTH := 3.0

enum Phase { CLOSED, SCANNING, OPENING, OPEN, CLOSING }

class Passage:
	var phase := Phase.CLOSED
	var direction := INWARD
	var progress := 0.0
	var remaining := 0.0
	var occupied := false
	var used := false

var cabinets: Array[Rect2] = []
var guardrails: Array[Rect2] = []
var lanes: Array[Passage] = [Passage.new(), Passage.new()]
var aperture_x: Vector2
var axis_y: float
var former_door_y: float
var active := false
var arrival_recorded := false
var reduced := false
var bound_state: Dictionary = {}
var last_foot := Vector2.INF

func _init() -> void:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT_PATH))
	var aperture: Array = layout.clearCentralApertureX
	aperture_x = Vector2(float(aperture[0]), float(aperture[1]))
	former_door_y = float(layout.formerDoorBaseY)
	for bounds: Array in layout.cabinetBounds:
		var box := Rules.rect(bounds)
		# Fallback uses the same floor position as the cabinet tiles.
		cabinets.append(Rect2(roundf(box.get_center().x - 9.5), box.position.y, 19, box.size.y))
	_fit_gate_row()

func bind_cabinets(objects: RefCounted) -> void:
	if not objects.ready: return
	for index in cabinets.size():
		cabinets[index] = objects.geometry("entrance_turnstile_%d" % index).rect
	_fit_gate_row()

func _fit_gate_row() -> void:
	# Lift the drawn leaves from the floor axis so their hinges land halfway
	# along the painted cabinets.
	axis_y = cabinets[1].get_center().y + (WING_TOP + WING_BOTTOM) / 2.0
	var west_end := cabinets[0].position.x
	var east_start := cabinets[-1].end.x
	guardrails = [
		Rect2(aperture_x.x, axis_y - RAIL_HALF_DEPTH, west_end - aperture_x.x, 2 * RAIL_HALF_DEPTH),
		Rect2(east_start, axis_y - RAIL_HALF_DEPTH, aperture_x.y - east_start, 2 * RAIL_HALF_DEPTH)
	]

func sync(state: Dictionary, scene_changed := false) -> void:
	var here := str(state.get("native", {}).get("scene", "")) == SCENE_ID
	if scene_changed or here != active or not is_same(state, bound_state):
		lanes = [Passage.new(), Passage.new()]
		last_foot = Vector2.INF
	active = here
	bound_state = state
	if not active:
		arrival_recorded = false
		return
	var native: Dictionary = state.get("native", {})
	reduced = bool(native.get("settings", {}).get("reduced_motion", false))
	arrival_recorded = bool(native.get("lib_admission_recorded",false)) or bool(state.get("ui", {}).get("libraryFinalsPuzzle", {}).get("entranceRecordRead", false))

func reader_rect(lane: int) -> Rect2:
	return _panel_rect(cabinets[READER_CABINETS[lane]])

func _panel_rect(cabinet: Rect2) -> Rect2:
	return Rect2(cabinet.position + Vector2(2, 35), Vector2(cabinet.size.x - 4, 23))

func _lane_span(index: int) -> Vector2:
	return Vector2(cabinets[index].end.x, cabinets[index + 1].position.x)

func align_targets(targets: Array) -> void:
	for target: Dictionary in targets.duplicate():
		if target.id != READER_IDS[0]: continue
		targets.erase(target)
		for index in lanes.size():
			var span := _lane_span(index)
			var stand := Metrics.anchor_from_foot_center(Vector2((span.x + span.y) / 2, axis_y + 24))
			var reader := target.duplicate(true)
			reader.id = READER_IDS[index]
			reader.position = [stand.x, stand.y]
			reader.stand = [stand.x, stand.y]
			reader.erase("bounds")
			reader.radius = 52.0
			reader.turnstileLane = index
			targets.append(reader)
		return

func use_reader(index: int, anchor: Vector2) -> void:
	if not active or index < 0 or index >= lanes.size(): return
	var lane := lanes[index]
	if lane.phase != Phase.CLOSED: return
	var entering := Metrics.foot_center(anchor).y >= axis_y
	_begin(lane, INWARD if entering else OUTWARD, entering)

func crossed_inward(before: Vector2, after: Vector2) -> bool:
	if not active or arrival_recorded: return false
	var feet := Metrics.foot_rect(after,SCENE_ID)
	var inner_edge := axis_y - WING_THICKNESS
	if Metrics.foot_rect(before,SCENE_ID).end.y < inner_edge or feet.end.y >= inner_edge: return false
	for index in lanes.size():
		var lane := lanes[index]
		if lane.direction != INWARD or lane.phase not in [Phase.OPENING, Phase.OPEN]: continue
		var span := _lane_span(index)
		if Rules.fits_horizontal_opening(feet, span.x, span.y): return true
	return false

func _begin(lane: Passage, direction: int, scan: bool) -> void:
	lane.phase = Phase.SCANNING if scan else Phase.OPENING
	lane.direction = direction
	lane.progress = 0.0
	lane.remaining = SCAN_SECONDS
	lane.occupied = false
	lane.used = false

func tick(delta: float, state: Dictionary, anchor: Vector2) -> void:
	sync(state)
	if not active: return
	var dt := clampf(delta, 0.0, .1)
	var feet := Metrics.foot_rect(anchor,SCENE_ID)
	var foot := feet.get_center()
	var leaving := last_foot.is_finite() and foot.y > last_foot.y
	last_foot = foot
	for index in lanes.size():
		var lane := lanes[index]
		var span := _lane_span(index)
		var width := span.y - span.x
		if lane.phase == Phase.CLOSED and leaving and Rect2(span.x, axis_y - 52, width, 48).has_point(foot):
			_begin(lane, OUTWARD, false)
		var sweep := width * .5 * SWING_DEPTH
		var sweep_start := minf(axis_y, axis_y + sweep * lane.direction)
		var safety := Rect2(span.x, sweep_start - WING_THICKNESS, width, sweep + 2 * WING_THICKNESS)
		lane.occupied = safety.intersects(feet)
		match lane.phase:
			Phase.SCANNING:
				lane.remaining -= dt
				if lane.remaining <= 0.0: lane.phase = Phase.OPENING
			Phase.OPENING:
				lane.used = lane.used or lane.occupied
				lane.progress = move_toward(lane.progress, 1.0, dt / (.10 if reduced else .36))
				if lane.progress >= 1.0:
					lane.phase = Phase.OPEN
					lane.remaining = PASS_SECONDS
			Phase.OPEN:
				lane.used = lane.used or lane.occupied
				lane.remaining -= dt
				if not lane.occupied and (lane.used or lane.remaining <= 0.0):
					lane.phase = Phase.CLOSING
			Phase.CLOSING:
				if lane.occupied:
					lane.phase = Phase.OPENING
				else:
					lane.progress = move_toward(lane.progress, 0.0, dt / (.10 if reduced else .32))
					if lane.progress <= 0.0: lane.phase = Phase.CLOSED

func restore_anchor(anchor: Vector2, entrance: Vector2) -> Vector2:
	var feet := Metrics.foot_rect(anchor,SCENE_ID)
	# Older saves could stop between the old sliding leaves and this gate row.
	var former_entrance := Rect2(aperture_x.x, former_door_y, aperture_x.y - aperture_x.x, axis_y + WING_THICKNESS - former_door_y)
	if not arrival_recorded and former_entrance.intersects(feet):
		return entrance
	for rail in guardrails:
		if feet.intersects(rail):
			return _clear_axis(anchor, RAIL_HALF_DEPTH)
	for index in lanes.size():
		var span := _lane_span(index)
		if not feet.intersects(Rect2(span.x, axis_y - WING_THICKNESS, span.y - span.x, WING_THICKNESS * 2)): continue
		return _clear_axis(anchor, WING_THICKNESS)
	return anchor

func _clear_axis(anchor: Vector2, half_depth: float) -> Vector2:
	var feet := Metrics.foot_rect(anchor,SCENE_ID)
	var side := INWARD if feet.get_center().y < axis_y else OUTWARD
	return Metrics.anchor_from_foot_center(Vector2(anchor.x, axis_y + side * (feet.size.y / 2 + half_depth + 1)))

func outside(anchor: Vector2) -> bool:
	return Metrics.foot_rect(anchor,SCENE_ID).position.y > axis_y + WING_THICKNESS

func _wing(index: int, side: int) -> PackedVector2Array:
	var lane := lanes[index]
	var span := _lane_span(index)
	var pivot := Vector2(span.x if side == 0 else span.y, axis_y)
	var angle := smoothstep(0.0, 1.0, lane.progress) * PI / 2
	var length := (span.y - span.x) / 2
	var tip := pivot + Vector2(length * cos(angle) * (1 if side == 0 else -1), length * sin(angle) * SWING_DEPTH * lane.direction)
	return PackedVector2Array([pivot, tip])

func collision_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	if not active: return out
	out.append_array(guardrails)
	for index in lanes.size():
		for side in 2:
			var wing := _wing(index, side)
			out.append(Rect2(wing[0], Vector2.ZERO).expand(wing[1]).grow(WING_THICKNESS))
	return out

func snapshot() -> Dictionary:
	var leaves: Array[Rect2] = []
	var states: Array = []
	var progress := 0.0
	var sensor_open := false
	for index in lanes.size():
		var lane := lanes[index]
		progress = maxf(progress, lane.progress)
		sensor_open = sensor_open or lane.phase in [Phase.OPEN, Phase.OPENING]
		states.append({"phase": Phase.keys()[lane.phase].to_lower(), "direction": lane.direction, "progress": lane.progress, "occupied": lane.occupied})
		for side in 2:
			var wing := _wing(index, side)
			var projection := Rect2(wing[0], Vector2.ZERO).expand(wing[1]).grow_individual(WING_THICKNESS, WING_TOP, WING_THICKNESS, -WING_BOTTOM)
			leaves.append(projection)
	return {"opening": Rect2(cabinets[0].position.x, axis_y - WING_TOP, cabinets[-1].end.x - cabinets[0].position.x, WING_TOP), "progress": progress, "visualProgress": progress, "sensorOpen": sensor_open, "arrivalRecorded": arrival_recorded, "leafRects": leaves, "collisionRects": collision_rects(), "lanes": states}

func draw(canvas: CanvasItem, context: Dictionary, front: bool) -> void:
	if not active: return
	var ground: float = context.player_ground_y
	var zoom: float = context.zoom
	canvas.draw_set_transform(context.origin, 0, Vector2.ONE * zoom)
	if Rules.depth_in_front(axis_y, ground) == front:
		for rail in guardrails:
			_draw_guardrail(canvas, rail)
	for index in lanes.size():
		for side in 2:
			var wing := _wing(index, side)
			if Rules.depth_in_front((wing[0].y + wing[1].y) / 2, ground) == front:
				_draw_wing(canvas, wing)
		if Rules.depth_in_front(cabinets[READER_CABINETS[index]].end.y, ground) == front:
			_draw_reader(canvas, index)
	if Rules.depth_in_front(cabinets[1].end.y, ground) == front:
		var sensor := _panel_rect(cabinets[1])
		canvas.draw_rect(sensor, Color("253b4b"))
		canvas.draw_rect(sensor.grow(-3), Color("344e5e"))
	canvas.draw_set_transform(Vector2.ZERO)

func _draw_guardrail(canvas: CanvasItem, rail: Rect2) -> void:
	var left := roundf(rail.position.x)
	var right := roundf(rail.end.x)
	var y := roundf(rail.get_center().y)
	var ink := Color("253b4b")
	var steel := Color("557480")
	for x: float in [left + 3, roundf((left + right) / 2), right - 3]:
		canvas.draw_rect(Rect2(x - 4, y - 2, 8, 4), ink)
		canvas.draw_rect(Rect2(x - 3, y - 25, 6, 26), ink)
		canvas.draw_rect(Rect2(x - 1, y - 24, 2, 23), steel)
	canvas.draw_rect(Rect2(left, y - 26, right - left, 7), ink)
	canvas.draw_rect(Rect2(left, y - 25, right - left, 3), steel)
	canvas.draw_rect(Rect2(left, y - 25, right - left, 1), Color("8ca6ab"))

func _draw_wing(canvas: CanvasItem, wing: PackedVector2Array) -> void:
	var left: Vector2 = wing[0].round()
	var right: Vector2 = wing[1].round()
	var pane := PackedVector2Array([left - Vector2(0, WING_TOP), right - Vector2(0, WING_TOP), right - Vector2(0, WING_BOTTOM), left - Vector2(0, WING_BOTTOM)])
	var ink := Color("253b4b")
	if absf(left.x - right.x) < 1.0:
		var axis := Rect2(pane[0], Vector2.ZERO)
		for point in pane: axis = axis.expand(point)
		canvas.draw_line(axis.position, axis.end, ink, 4)
		canvas.draw_line(axis.position, axis.end, Color("79aeb9"), 2)
	else:
		canvas.draw_colored_polygon(pane, Color("98c9cf", .72))
		canvas.draw_polyline(PackedVector2Array([pane[0], pane[1], pane[2], pane[3], pane[0]]), ink, 2)
		canvas.draw_line(pane[0] + Vector2(0, 4), pane[1] + Vector2(0, 4), Color("d4e4da", .8), 2)
	canvas.draw_rect(Rect2(left - Vector2(2, WING_TOP - 2), Vector2(4, WING_TOP - WING_BOTTOM - 4)), ink)

func _draw_reader(canvas: CanvasItem, index: int) -> void:
	var pad := reader_rect(index)
	var lane := lanes[index]
	var color := Color("ca6559")
	match lane.phase:
		Phase.SCANNING: color = Color("e5be71")
		Phase.OPENING, Phase.OPEN: color = Color("82bf93")
	var window := pad.grow(-2)
	canvas.draw_rect(pad, Color("253b4b"))
	canvas.draw_rect(window, Color("344e5e"))
	canvas.draw_rect(Rect2(window.position + Vector2(2, 2), Vector2(window.size.x - 4, 4)), color)
	canvas.draw_line(window.get_center() - Vector2(2, -4), window.get_center() + Vector2(2, 4), Color("8ca6ab"), 2)
	Picker.record(canvas, [READER_IDS[index]], pad.grow(4))
	if lane.phase == Phase.SCANNING and not reduced:
		var approach := sin(PI * clampf(lane.remaining / SCAN_SECONDS, 0.0, 1.0))
		var card := Rect2((pad.get_center() + Vector2(7 * (1.0 - approach), 14 * (1.0 - approach))).round() - Vector2(5, 3), Vector2(10, 6))
		canvas.draw_rect(card.grow(1), Color("253b4b"))
		canvas.draw_rect(card, Color("e6d5ac"))
		canvas.draw_line(card.position + Vector2(2, 3), card.position + Vector2(6, 3), Color("668ba1"), 1)
