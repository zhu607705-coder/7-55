extends Button
## Native mouse/focus fallback shares the same projected polygon as touch.
var hit_test: Callable
func _has_point(point: Vector2) -> bool:
	return hit_test.call(point+position) if hit_test.is_valid() else false
