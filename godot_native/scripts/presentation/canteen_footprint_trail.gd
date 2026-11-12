extends RefCounted
## Dark observation on the north-up campus. The route comes from world collision.
const SPACING := 42.0
const SCATTER_START := 0.82
var marks: Array[Dictionary] = []
var _sole := PackedVector2Array([
	Vector2(-2,-9), Vector2(2,-9), Vector2(4,-7), Vector2(4,-2),
	Vector2(2,0), Vector2(-2,0), Vector2(-4,-2), Vector2(-4,-7)
])
var _heel := PackedVector2Array([
	Vector2(-2,3), Vector2(2,3), Vector2(3,4), Vector2(3,7),
	Vector2(2,9), Vector2(-2,9), Vector2(-3,7), Vector2(-3,4)
])

static func tracking(scene: String, state: Dictionary) -> bool:
	var hunt: Dictionary = state.canteenHunt
	return scene == "campus_bootstrap" and bool(hunt.active) and str(hunt.phase) in ["tracking", "canteen_reached"]

func visible(scene: String, state: Dictionary) -> bool:
	return not marks.is_empty() and tracking(scene,state) and str(state.native.mode) == "dark"

func configure(path: Array[Vector2], can_place: Callable) -> void:
	marks.clear()
	var length := 0.0
	for i in range(1,path.size()):
		length += path[i-1].distance_to(path[i])
	var traveled := 0.0
	var next_mark := 0.0
	var step := 0
	for i in range(1,path.size()):
		var start := path[i-1]
		var direction := start.direction_to(path[i])
		var distance := start.distance_to(path[i])
		while next_mark < traveled + distance:
			var center := start + direction * (next_mark - traveled)
			var scattered := next_mark >= length * SCATTER_START
			var side := 1.0 if step % 2 == 0 else -1.0
			var lateral := 7.0 + (5.0 * sin(float(step) * 1.7) if scattered else 0.0)
			var point := center + direction.orthogonal() * side * lateral
			if not can_place.call(point): point = center
			var yaw := sin(float(step) * 2.3) * 0.55 if scattered else side * 0.12
			marks.append({"point": point, "heading": direction.angle() + yaw, "alpha": 0.50 if scattered else 0.85})
			step += 1
			next_mark += SPACING
		traveled += distance
	if marks.is_empty(): return
	var finish := {"point":path[-1], "heading":path[-2].direction_to(path[-1]).angle(), "alpha":0.50}
	if marks[-1].point.distance_to(path[-1]) < SPACING / 2.0:
		marks[-1] = finish
	else:
		marks.append(finish)

func draw(canvas: CanvasItem, context: Dictionary, viewport: Vector2, state: Dictionary) -> void:
	if not visible(str(context.scene_id),state): return
	var origin: Vector2 = context.origin
	var zoom: float = context.zoom
	var view := Rect2(Vector2.ZERO,viewport).grow(16.0 * zoom)
	for mark: Dictionary in marks:
		var at: Vector2 = origin + mark.point * zoom
		if not view.has_point(at): continue
		var alpha: float = mark.alpha
		canvas.draw_set_transform(at,float(mark.heading) + PI / 2.0,Vector2.ONE * zoom)
		canvas.draw_colored_polygon(_sole,Color("b6efff",alpha))
		canvas.draw_colored_polygon(_heel,Color("b6efff",alpha))
		canvas.draw_rect(Rect2(-2,-6,4,3),Color("e4f9ff",alpha))
	canvas.draw_set_transform(Vector2.ZERO)
