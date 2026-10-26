extends RefCounted
## One orthographic camera for every physical surface. World x = across desk,
## y = depth towards the viewer, z = height. The same plane inverse drives input.
const ELEVATION := deg_to_rad(50.0)
const YAW := deg_to_rad(8.0)
var scale := 1.0
var origin := Vector2.ZERO

func configure(viewport: Vector2) -> void:
	scale = minf(viewport.x / 860.0, viewport.y / 1500.0)
	var center := axes(Vector3(480,650,0))
	origin = Vector2(viewport.x*0.5,viewport.y*0.60) - center*scale

func axes(point: Vector3) -> Vector2:
	return Vector2(cos(YAW)*point.x-sin(YAW)*point.y,
		sin(ELEVATION)*(sin(YAW)*point.x+cos(YAW)*point.y)-cos(ELEVATION)*point.z)

func project(point: Vector3) -> Vector2:
	return origin + axes(point)*scale

func unproject_plane(point: Vector2, height: float = 0.0) -> Vector3:
	var q := (point-origin)/scale
	var depth := (q.y+cos(ELEVATION)*height)/sin(ELEVATION)
	return Vector3(cos(YAW)*q.x+sin(YAW)*depth,-sin(YAW)*q.x+cos(YAW)*depth,height)
