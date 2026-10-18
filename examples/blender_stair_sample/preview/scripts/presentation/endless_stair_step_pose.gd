extends RefCounted
## Read-only, distance-driven stair contact pose. World y denotes the shoe sole.
## No clock, state, input, collision shape, or model mutation belongs here.

const TREAD := 0.60
const RISER := 0.165
const BODY_LEAD := 0.25
const CONTACT_INSET := 0.105
const SOLE_HALF_LENGTH := 0.10
const FOOT_HALF_SPACING := 0.115
const SWING_CLEARANCE := 0.24
const MAX_BODY_OFFSET := 0.18
const EPS := 0.00001

static func sample(model, progress: float, physical_y: float, grounded: bool, local_floors: Array = []) -> Dictionary:
	# Invalid presentation input must not contaminate a mesh transform.
	var floors: Array = model.geometry.floors if local_floors.is_empty() else local_floors
	var p := progress if is_finite(progress) else 0.0
	var y := physical_y if is_finite(physical_y) else 0.0
	var section: Dictionary = model.route_section(p)
	var heading: Vector3 = model.route_heading(p)
	var side := Vector3(-heading.z, 0.0, heading.x) * FOOT_HALF_SPACING
	var base: Vector3 = model.route_position(p, y)
	var feet: Array[Vector3] = [base - side, base + side]
	var result := {"active": false, "step_index": -1, "phase": 0.0,
		"pose_frame": 0, "body_y": y, "feet": feet, "support_foot": 0,
		"contact_token": "", "lift": 0.0, "heading": heading}
	if not grounded or not is_finite(progress) or not is_finite(physical_y):
		return result

	var flight := section
	# The collision body meets the first riser 0.25 m before its centre enters
	# a flight. That actual first-tread contact also starts the stair gait.
	if str(section.kind) != "flight":
		flight = {}
		for candidate: Dictionary in model.geometry.routes:
			if str(candidate.kind) == "flight" and p >= float(candidate.start) - BODY_LEAD \
			and p < float(candidate.start):
				flight = candidate
				break
		if flight.is_empty():
			return result

	var count := roundi(float(flight.length) / TREAD)
	var distance := (p - float(flight.start) + BODY_LEAD) / TREAD
	var index := clampi(floori(distance + EPS), 0, count - 1)
	var phase := clampf(distance - float(index), 0.0, 1.0)
	var contact_x := float(flight.start) + float(index) * TREAD + CONTACT_INSET
	var floor_now := _anchor_floor(floors, contact_x)
	if not is_finite(floor_now) or absf(floor_now - y) > EPS * 4.0 \
	or not _body_supported(floors, p, y):
		return result

	var previous_x := contact_x - TREAD
	var next_x := contact_x + TREAD
	var floor_before := _anchor_floor(floors, previous_x)
	var floor_after := _anchor_floor(floors, next_x)
	# Only a real neighbouring floor may define the rise. A missing tread
	# never creates an invisible ramp or a fictional planted foot.
	if is_finite(floor_before) and floor_now - floor_before >= -EPS \
	and floor_now - floor_before <= MAX_BODY_OFFSET + EPS:
		result.body_y = clampf(lerpf(floor_before, floor_now, phase),
			y - MAX_BODY_OFFSET, y + MAX_BODY_OFFSET)
	# Keep both feet in this flight's lateral frame at its entry and exit.
	heading = (Vector3(float(flight.toXZ[0]), 0.0, float(flight.toXZ[1])) - Vector3(float(flight.fromXZ[0]), 0.0, float(flight.fromXZ[1]))).normalized()
	# At a broken-flight boundary, retain the real planted foot and collect
	# the other foot onto that same surviving tread. Never promise a landing
	# on the missing next tread, or invent a takeoff on a missing prior one.
	# Once the body has no actual support, the early guard disables the pose.
	if not is_finite(floor_before):
		previous_x = contact_x
		floor_before = floor_now
	if not is_finite(floor_after):
		next_x = contact_x
		floor_after = floor_now
	if floor_now - floor_before < -EPS or floor_now - floor_before > MAX_BODY_OFFSET + EPS \
	or floor_after - floor_now < -EPS or floor_after - floor_now > MAX_BODY_OFFSET + EPS:
		return result

	var support := index % 2
	var swing := 1 - support
	var travel := phase * phase * (3.0 - 2.0 * phase)
	var lift := SWING_CLEARANCE * pow(sin(PI * phase), 2.0)
	var swing_x := lerpf(previous_x, next_x, travel)
	var swing_y := lerpf(floor_before, floor_after, travel) + lift
	# Check the complete shoe, including the toe and heel, against authored
	# floor tops. The analytic arc already clears ordinary 0.165 m risers.
	# This bound also protects the final flight-to-platform corner.
	var clearance := _sole_clearance(floors, swing_x)
	if is_finite(clearance):
		swing_y = maxf(swing_y, clearance)
	feet[support] = _foot_world(model, contact_x, floor_now, support, heading)
	feet[swing] = _foot_world(model, swing_x, swing_y, swing, heading)
	result.active = true
	result.heading = heading
	result.step_index = index
	result.phase = phase
	result.pose_frame = support * 8 + mini(7, floori(phase * 8.0))
	result.feet = feet
	result.support_foot = support
	result.contact_token = "%s:%02d:%d" % [str(flight.id), index, support]
	result.lift = lift
	return result

static func cache_floors(floors: Array) -> Dictionary:
	# Static conservative 1.2 m route buckets, expanded by 1.2 m both ways.
	# Every possible support, previous and next shoe span lies inside this range.
	# The raw immutable floor entries stay in original order; query results match
	# the uncached path exactly. Cache rebuild belongs to geometry setup only.
	var buckets := {}
	for raw: Dictionary in floors:
		var r := _rect(raw)
		var first := floori((r.position.x - 1.2) / 1.2) - 1
		var last := floori((r.end.x + 1.2) / 1.2) + 1
		for key in range(first, last + 1):
			if not buckets.has(key): buckets[key] = []
			buckets[key].append(raw)
	return buckets

static func _rect(raw: Dictionary) -> Rect2:
	if raw.has("rect"):
		var r: Array = raw.rect
		return Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
	return Rect2(float(raw.x), float(raw.y), float(raw.width), float(raw.height))

static func _anchor_floor(floors: Array, x: float) -> float:
	var top := -INF
	for raw: Dictionary in floors:
		var rect := _rect(raw)
		if x - SOLE_HALF_LENGTH >= rect.position.x - EPS \
		and x + SOLE_HALF_LENGTH <= rect.end.x + EPS:
			top = maxf(top, rect.end.y)
	return top

static func _sole_clearance(floors: Array, x: float) -> float:
	var top := -INF
	for raw: Dictionary in floors:
		var rect := _rect(raw)
		if x + SOLE_HALF_LENGTH > rect.position.x + EPS \
		and x - SOLE_HALF_LENGTH < rect.end.x - EPS:
			top = maxf(top, rect.end.y)
	return top

static func _body_supported(floors: Array, x: float, y: float) -> bool:
	for raw: Dictionary in floors:
		var rect := _rect(raw)
		if absf(rect.end.y - y) <= EPS * 4.0 and x + BODY_LEAD > rect.position.x + EPS \
		and x - BODY_LEAD < rect.end.x - EPS:
			return true
	return false

static func _foot_world(model, progress: float, y: float, foot: int, heading: Vector3) -> Vector3:
	var side := Vector3(-heading.z, 0.0, heading.x)
	return model.route_position(progress, y) + side * FOOT_HALF_SPACING * (-1.0 if foot == 0 else 1.0)
