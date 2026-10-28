extends RefCounted
## Fixed approved oblique view. No puzzle state, camera tween or history offset.
## Derived from raking_light/configure_camera; callers choose framing only.
const ELEVATION := deg_to_rad(50.0)
const YAW := deg_to_rad(8.0)
const DISTANCE := 22.0

static func configure(camera: Camera3D, viewport_size: Vector2, focus: Vector3, width_span: float, min_height: float = 0.0) -> Basis:
	var right := Vector3(cos(YAW), 0, -sin(YAW))
	var up := Vector3(-sin(ELEVATION) * sin(YAW), cos(ELEVATION), -sin(ELEVATION) * cos(YAW))
	var back := right.cross(up)
	var camera_basis := Basis(right, up, back)
	assert(camera != null, "A scene-owned Camera3D is required")
	assert(viewport_size.is_finite() and focus.is_finite(), "Camera input must be finite")
	assert(is_finite(width_span) and width_span > 0.0, "Width span must be positive")
	assert(is_finite(min_height) and min_height >= 0.0, "Minimum height must be nonnegative")
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.near = 0.05
	camera.far = 60.0
	camera.transform = Transform3D(camera_basis, focus + back * DISTANCE)
	camera.size = maxf(0.01, maxf(min_height, width_span * maxf(viewport_size.y, 1.0) / maxf(viewport_size.x, 1.0)))
	return camera_basis
