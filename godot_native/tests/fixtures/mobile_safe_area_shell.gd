extends "res://scripts/main.gd"
## OS safe-area seam only. Main owns the production layout and event routing.
## A simulated notch is not evidence from a physical mobile device.
var test_safe_insets := Vector4.ZERO
func _world_safe_insets() -> Vector4:
	return test_safe_insets
