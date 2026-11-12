extends RefCounted
## Shared picture geometry for the playable ride and its two 3D transitions.
const AUTHORED_SIZE := Vector2(960, 540)
const CAMERA_FOV := 54.0
const CAMERA_OFFSET := Vector3(0, 3.2, 7.2)
const CAMERA_LOOK_OFFSET := Vector3(0, 1.22, -14.0)
const MAX_DENSITY := 1.8
const DESKTOP_PIXEL_BUDGET := 1800000.0
const COMPACT_PIXEL_BUDGET := 1000000.0

static func picture_rect(available: Vector2) -> Rect2:
	if available.x >= available.y:
		return Rect2(Vector2.ZERO, available)
	var fitted := AUTHORED_SIZE * minf(available.x / AUTHORED_SIZE.x, available.y / AUTHORED_SIZE.y)
	return Rect2((available - fitted) * 0.5, fitted)

static func render_size(picture: Vector2, density: float, compact: bool, quality_scale: float = 1.0) -> Vector2i:
	var area := maxf(picture.x * picture.y, 1.0)
	var budget := COMPACT_PIXEL_BUDGET if compact else DESKTOP_PIXEL_BUDGET
	var scale := minf(minf(density, MAX_DENSITY), sqrt(budget / area)) * quality_scale
	return Vector2i(maxi(2, roundi(picture.x * scale)), maxi(2, roundi(picture.y * scale)))

static func vertical_fov(authored_fov: float, picture: Vector2) -> float:
	var aspect := picture.x / maxf(picture.y, 1.0)
	if aspect >= AUTHORED_SIZE.aspect():
		return authored_fov
	return rad_to_deg(2.0 * atan(tan(deg_to_rad(authored_fov) * 0.5) * AUTHORED_SIZE.aspect() / maxf(aspect, 0.1)))
