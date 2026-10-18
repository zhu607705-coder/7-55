extends "res://scripts/main.gd"
## Headless test seam for the OS window-focus bit only. Keep Main's actual deep
## snapshot, visibility, scene, scale and modal contracts, and its presenter wiring.
var test_focused: bool=true
func _read_runtime_state() -> Dictionary:
	var snapshot: Dictionary=super._read_runtime_state()
	snapshot.native.host.focused=test_focused
	return snapshot
