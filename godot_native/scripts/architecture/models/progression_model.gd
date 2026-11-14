extends AbstractModel
## The sole native snapshot. State.d is a compatibility property over this value.
var snapshot: Dictionary = {}

func get_model_name() -> String: return "Progression"
func init() -> void: pass

func record_world_position(scene: String, key: String, anchor: Vector2, source: Vector2) -> void:
	# Ignore callbacks from a surface that has already been replaced.
	var native: Dictionary = snapshot.get("native", {})
	if scene.is_empty() or scene != native.get("scene") or not key.begins_with(scene + ":"): return
	if not anchor.is_finite() or not source.is_finite(): return
	native.player = {"x": source.x, "y": source.y, "scene": scene, "world_x": anchor.x, "world_y": anchor.y}
	if not native.has("positions"): native.positions = {}
	native.positions[key] = {"x": anchor.x, "y": anchor.y}

func read_snapshot() -> Dictionary:
	return snapshot.duplicate(true)
