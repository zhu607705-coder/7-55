extends RefCounted
## Pure, seekable presentation timeline. It has no gameplay state or callbacks.

const DURATION := 10.2
const PHONE_FOOT := Vector3(0.0, 0.255, 2.3)
const LANDING := Vector3(0.0, 0.08, -0.95)
const ARRIVAL := Vector3(0.0, 0.08, -4.6)
const PHASE_ENDS := [1.3, 2.5, 3.0, 4.0, 4.6, 8.8, DURATION]
const PHASE_NAMES := ["01  屏幕中的图标", "02  撑起身体", "03  起跳蓄力", "04  跳出平面", "05  落地回弹", "06  走进微缩校园", "07  镜头停留"]

static func smooth_fraction(value: float) -> float:
	var u := clampf(value, 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)

static func segment(t: float, a: float, b: float) -> float:
	return clampf((t - a) / (b - a), 0.0, 1.0)

static func sample(seconds: float, reduced_motion := false) -> Dictionary:
	var t := clampf(seconds, 0.0, DURATION)
	if reduced_motion:
		t = DURATION
	var phase := PHASE_ENDS.size() - 1
	for i in range(PHASE_ENDS.size()):
		if t < PHASE_ENDS[i]:
			phase = i
			break
	var rise := smooth_fraction(segment(t, 1.3, 2.5))
	var position := PHONE_FOOT
	var scale := Vector3(1.0, 1.0, lerpf(0.018, 1.0, rise))
	var rotation := Vector3(lerpf(-PI / 2.0, 0.0, rise), 0.0, 0.0)
	var stride := 0.0
	var arms := lerpf(-0.22, 0.05, rise)
	if t >= 2.5 and t < 3.0:
		var squash := sin(segment(t, 2.5, 3.0) * PI)
		scale = Vector3(1.0 + 0.12 * squash, 1.0 - 0.25 * squash, 1.0 + 0.12 * squash)
		arms = 0.05 - 0.55 * squash
	elif t >= 3.0 and t < 4.0:
		var u := segment(t, 3.0, 4.0)
		position = PHONE_FOOT.lerp(LANDING, smooth_fraction(u))
		position.y += 1.45 * sin(PI * u)
		rotation.y = PI * smooth_fraction(u)
		arms = 0.05 + 1.0 * sin(PI * u)
	elif t >= 4.0:
		position = LANDING
		rotation.y = PI
		if t < 4.6:
			var u := segment(t, 4.0, 4.6)
			var bounce_u := clampf((u - 0.25) / 0.75, 0.0, 1.0)
			var bounce := absf(sin(2.0 * PI * bounce_u)) * (1.0 - bounce_u)
			position.y += 0.16 * bounce
			var squash := sin(PI * clampf(u * 4.0, 0.0, 1.0)) * (1.0 - u)
			scale = Vector3(1.0 + 0.15 * squash, 1.0 - 0.30 * squash, 1.0 + 0.15 * squash)
		elif t < 8.8:
			var u := segment(t, 4.6, 8.8)
			position = LANDING.lerp(ARRIVAL, smooth_fraction(u))
			var envelope := sin(PI * u)
			stride = sin(u * TAU * 5.0) * 0.55 * envelope
			position.y += absf(stride) * 0.08
		else:
			position = ARRIVAL
	# A single cubic curve plus a continuous look target: no camera cuts, or per-frame lerp.
	var camera_u := smooth_fraction(segment(t, 0.6, 9.2))
	var camera_position := Vector3(0.65, 7.6, 7.8).bezier_interpolate(
		Vector3(4.3, 5.4, 6.6), Vector3(3.3, 1.45, 1.6), Vector3(2.9, 2.0, -1.65), camera_u)
	var target := Vector3(0.0, 0.15, 1.55).lerp(Vector3(0.0, 0.65, -4.8), smooth_fraction(segment(t, 1.2, 9.2)))
	return {"time": t, "phase": phase, "phase_name": PHASE_NAMES[phase],
		"position": position, "scale": scale, "rotation": rotation,
		"stride": stride, "arms": arms, "flat": rise < 0.01,
		"camera_position": camera_position, "camera_target": target}
