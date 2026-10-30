extends RefCounted
## One square ground grid under the shared 45-degree apparatus projection.
const Plane45=preload("res://campuses/future_learning_center/scripts/bench_projection.gd")
const CELL:=Vector2(114,114*Plane45.DEPTH)
## Physical miniature footprint: the front sensor reaches 41.5 ground units.
## The room atlas is artwork only and no longer controls apparatus braking.
const ROBOT_FRONT:=41.5
const STOP_MARGIN:=2.0
static func front_distance(direction:int)->float:
	return ROBOT_FRONT*(1.0 if direction%2==0 else Plane45.DEPTH)
static func stop_fraction(direction:int)->float:
	var cell_length:float=CELL.x if direction%2==0 else CELL.y
	return maxf(0,.5-(front_distance(direction)+STOP_MARGIN)/cell_length)
