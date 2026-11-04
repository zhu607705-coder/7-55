extends AbstractModel
## The sole native snapshot. State.d is a compatibility property over this value.
var snapshot: Dictionary = {}

func get_model_name() -> String: return "Progression"
func init() -> void: pass

func read_snapshot() -> Dictionary:
	return snapshot.duplicate(true)
